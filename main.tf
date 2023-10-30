locals {
    account_id  = data.aws_caller_identity.current.account_id
    external_id = "lweid:aws:v2:${var.lacework_account}:${local.account_id}:${random_id.uniq.id}"
    kms_key_arn = (length(var.kms_key_arn) > 0 ? var.kms_key_arn : aws_kms_key.lacework_kms_key[0].arn)
    stack_name  = "lacework-aws-org-configuration"
}

data "aws_caller_identity" "current" {}

resource "random_id" "uniq" {
  byte_length = 10
}

#tfsec:ignore:aws-s3-enable-bucket-encryption
#tfsec:ignore:aws-s3-enable-bucket-logging
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket" "lacework_org_lambda" {
  bucket = "lacework_org_lambda"
}

resource "aws_s3_bucket_versioning" "lacework_org_lambda" {
  bucket = aws_s3_bucket.lacework_org_lambda.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "lacework_org_lambda" {
  bucket = aws_s3_bucket.lacework_org_lambda.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_public_access_block" "lacework_org_lambda" {
  bucket                  = aws_s3_bucket.lacework_org_lambda.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
 }

resource "aws_lambda_function" "lacework_copy_zip_files" {
  description      = "Copies object from the Lacework S3 bucket to a new location"
  filename         = data.archive_file.lambda_zip_file.output_path
  function_name    = "lacework_copy_zip_files"
  handler          = "index.handler"
  role             = aws_iam_role.lacework_copy_zip_files_role.arn
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_zip_file.output_base64sha256
  timeout          = 240

  tracing_config {
    mode = "Active"
  }
}

data "archive_file" "lambda_zip_file" {
  output_path = "${path.module}/lambda.zip"
  source_dir  = "${path.module}/python"
  excludes    = ["__init__.py", "*.pyc"]
  type        = "zip"
}

resource "aws_iam_role" "lacework_copy_zip_files_role" {
  assume_role_policy  = data.aws_iam_policy_document.lacework_setup_function_role.json
  managed_policy_arns = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
  name                = "lacework_copy_zip_files_role"
  path                = "/"
}

data "aws_iam_policy_document" "lacework_copy_zip_files_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }

  statement {
    actions   = [
      "s3:GetObject",
      "s3:GetObjectTagging",
    ]
    effect    = "Allow"
    resources = ["aws:${data.aws_partition.current.partition}:s3:::${var.s3_bucket}/${var.s3_prefix}*"]
  }

  statement {
    actions   = [
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]
    effect    = "Allow"
    resources = [aws_s3_bucket.lacework_org_lambda.arn]
  }

  version = "2012-10-17"
}

data "aws_lambda_invocation" "lacework_copy_zip_files" {
  function_name = aws_lambda_function.lacework_copy_zip_files.id

  input = <<JSON
{
  "RequestType": "Copy",
  "ResourceProperties": {
    "SourceBucket": ${var.s3_bucket},
    "DestBucket": aws_s3_bucket.lacework_org_lambda.id,
    "Prefix": ${var.s3_prefix},
    "Objects": ["/lambda/LaceworkIntegrationSetup1.1.2.zip"]
  }
}
JSON
}

resource "aws_lambda_function" "lacework_setup_function" {
  environment {
    variables = {
      LW_ACCOUNT     = var.lacework_account
      LW_INT_PREFIX  = "AWS"
      LW_SUB_ACCOUNT = var.lacework_sub_account
    }
  }

  function_name = "lacework_setup_function"
  handler       = "lw_integration_lambda_function.handler"
  role          = aws_iam_role.lacework_setup_function_role.arn
  runtime       = "python3.11"
  s3_bucket     = aws_s3_bucket.lacework_org_lambda.arn
  s3_key        = "${var.s3_prefix}/lambda/LaceworkIntegrationSetup1.1.2.zip"
  timeout       = 900

  tracing_config {
    mode = "Active"
  }
}

resource "aws_iam_role" "lacework_setup_function_role" {
  assume_role_policy  = data.aws_iam_policy_document.lacework_setup_function_role.json
  managed_policy_arns = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
  name                = "lacework_setup_function_role"
  path                = "/"
}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "lacework_setup_function_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }

  statement {
    actions   = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:UpdateSecret"
    ]
    effect    = "Allow"
    resources = [aws_secretsmanager_secret.lacework_api_credentials.arn]
  }

  version = "2012-10-17"
}

resource "aws_lambda_permission" "lacework_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lacework_setup_function.arn
  principal     = "cloudformation.amazonaws.com"
  source_arn    = aws_sns_topic.lacework_sns_topic.arn 
}

resource "aws_secretsmanager_secret" "lacework_api_credentials" {
  description = "Lacework API Access Keys"
  name        = "LaceworkApiCredentials"
  kms_key_id  = local.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "lacework_api_credentials" {
  secret_id     = aws_secretsmanager_secret.lacework_api_credentials.id
  secret_string = "{\"AccessKeyID\": \"${var.lacework_access_key_id}\", \"SecretKey\": \"${var.lacework_secret_key}\", \"AccessToken\": \"0\", \"TokenExpiry\": 0}"
}

resource "aws_sns_topic" "lacework_sns_topic" {
  name              = "lacework_sns_topic"
  kms_master_key_id = local.kms_key_arn
}

#tfsec:ignore:aws-kms-auto-rotate-keys customer has option of enabling key rotation
resource "aws_kms_key" "lacework_kms_key" {
  count                   = length(var.kms_key_arn) > 0 ? 0 : 1
  description             = "A KMS key used to encrypt SNS topic messages and Secrets"
  deletion_window_in_days = var.kms_key_deletion_days
  multi_region            = var.kms_key_multi_region
  policy                  = data.aws_iam_policy_document.kms_key_policy.json
  enable_key_rotation     = var.kms_key_rotation
}

data "aws_iam_policy_document" "kms_key_policy" {
  version = "2012-10-17"

  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_sns_topic_policy" "default" {
  arn    = ""
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "lwSNStopicpolicy"

  statement {
    actions = ["sns:Publish"]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipleOrgID"
      values   = [ var.organization_id ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = ["*"]
    sid       = "AllowWithinOrg"
  }
}

resource "aws_sns_topic_subscription" "lacework_sns_subscription" {
  endpoint  = aws_lambda_function.lacework_setup_function.arn
  protocol  = "lambda"
  topic_arn = aws_sns_topic.lacework_sns_topic.arn
}

resource "aws_cloudformation_stack" "lacework_stack" {
  capabilities = [ "CAPABILITY_NAMED_IAM" ]
  name         = local.stack_name
  parameters   = {
    ExternalID         = local.external_id
    MainAccountSNS     = aws_sns_topic.lacework_sns_topic.arn
    ResourceNamePrefix = var.resource_prefix
  }
  template_url = "https://s3.amazonaws.com/${var.s3_bucket}/${var.s3_prefix}/templates/lacework-aws-cfg-member.template.yml" 
}

resource "aws_cloudformation_stack_set" "lacework_stackset" {
  auto_deployment {
    enabled = true
    retain_stacks_on_account_removal = false
  }

  capabilities = [ "CAPABILITY_NAMED_IAM" ]
  name         = local.stack_name

  operation_preferences {
    failure_tolerance_count   = 20
    max_concurrent_percentage = 100
  }

  parameters = {
    ExternalID         = local.external_id
    MainAccountSNS     = aws_sns_topic.lacework_sns_topic.arn
    ResourceNamePrefix = var.resource_prefix
  }

  permission_model = "SERVICE_MANAGED"
  template_url     = "https://s3.amazonaws.com/${var.s3_bucket}/${var.s3_prefix}/templates/lacework-aws-cfg-member.template.yml"
}
