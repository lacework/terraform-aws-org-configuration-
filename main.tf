locals {
  kms_key_arn = length(var.kms_key_arn) > 0 ? var.kms_key_arn : aws_kms_key.lacework_kms_key[0].arn
}

data "aws_caller_identity" "current" {}

#tfsec:ignore:aws-s3-enable-bucket-encryption
#tfsec:ignore:aws-s3-enable-bucket-logging
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket" "lacework_org_lambda" {
  bucket_prefix = "lacework-org-lambda-"
  force_destroy = true
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

  environment {
    variables = {
      src_bucket = var.cf_s3_bucket
      dst_bucket = aws_s3_bucket.lacework_org_lambda.id
      prefix     = var.cf_s3_prefix
      object     = "/lambda/LaceworkIntegrationSetup1.1.2.zip"
    }
  }
}

data "archive_file" "lambda_zip_file" {
  excludes    = ["__init__.py", "*.pyc"]
  output_path = "${path.module}/lambda.zip"
  source_dir  = "${path.module}/python"
  type        = "zip"
}

resource "aws_iam_role" "lacework_copy_zip_files_role" {
  assume_role_policy = data.aws_iam_policy_document.lacework_copy_zip_files_assume_role.json

  inline_policy {
    name   = "zip-role"
    policy = data.aws_iam_policy_document.lacework_copy_zip_files_role.json
  }

  managed_policy_arns = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
  name                = "lacework_copy_zip_files_role"
  path                = "/"
}

data "aws_iam_policy_document" "lacework_copy_zip_files_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lacework_copy_zip_files_role" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging",
    ]
    effect = "Allow"
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.cf_s3_bucket}/${var.cf_s3_prefix}/*"
    ]
  }

  statement {
    actions = [
      "s3:*",
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.lacework_org_lambda.arn,
      "${aws_s3_bucket.lacework_org_lambda.arn}/*",
    ]
  }

  version = "2012-10-17"
}

resource "aws_lambda_invocation" "lacework_copy_zip_files" {
  function_name = aws_lambda_function.lacework_copy_zip_files.arn

  input = jsonencode({})

  depends_on = [aws_lambda_function.lacework_copy_zip_files]
}

resource "aws_lambda_function" "lacework_setup_function" {
  environment {
    variables = {
      LW_ACCOUNT    = var.lacework_account
      LW_INT_PREFIX = "AWS"
      LW_SUBACCOUNT = var.lacework_subaccount
    }
  }

  function_name = "lacework_setup_function"
  handler       = "lw_integration_lambda_function.handler"
  role          = aws_iam_role.lacework_setup_function_role.arn
  runtime       = "python3.11"
  s3_bucket     = aws_s3_bucket.lacework_org_lambda.bucket
  s3_key        = "${var.cf_s3_prefix}/lambda/LaceworkIntegrationSetup1.1.2.zip"
  timeout       = 900

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_lambda_invocation.lacework_copy_zip_files,
    aws_sns_topic.lacework_sns_topic,
    aws_secretsmanager_secret.lacework_api_credentials
  ]
}

resource "aws_iam_role" "lacework_setup_function_role" {
  assume_role_policy = data.aws_iam_policy_document.lacework_setup_function_assume_role.json

  inline_policy {
    name   = "lacework_setup_function_policy"
    policy = data.aws_iam_policy_document.lacework_setup_function_role.json
  }

  managed_policy_arns = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
  name                = "lacework_setup_function_role"
  path                = "/"
}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "lacework_setup_function_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lacework_setup_function_role" {
  statement {
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "secretsmanager:GetSecretValue",
      "secretsmanager:UpdateSecret"
    ]
    effect = "Allow"
    resources = [
      aws_secretsmanager_secret.lacework_api_credentials.arn,
      local.kms_key_arn,
    ]
  }

  version = "2012-10-17"
}

resource "aws_lambda_permission" "lacework_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lacework_setup_function.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.lacework_sns_topic.arn
}

resource "aws_secretsmanager_secret" "lacework_api_credentials" {
  description             = "Lacework API Access Keys"
  kms_key_id              = local.kms_key_arn
  name                    = "LaceworkApiCredentials"
  recovery_window_in_days = 0
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
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    sid    = "Enable Org member accounts to use key"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [var.organization_id]
    }

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]

    resources = ["*"]
  }
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.lacework_sns_topic.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "lwSNStopicpolicy"

  statement {
    actions = [
      "sns:Publish",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [var.organization_id]
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
  capabilities = ["CAPABILITY_NAMED_IAM"]
  name         = var.cf_stack_name
  parameters = {
    LaceworkAccount    = var.lacework_account
    MainAccountSNS     = aws_sns_topic.lacework_sns_topic.arn
    ResourceNamePrefix = var.cf_resource_prefix
  }
  template_url       = "https://s3.amazonaws.com/${var.cf_s3_bucket}/${var.cf_s3_prefix}/templates/lacework-aws-cfg-member.template.yml"
  timeout_in_minutes = 30

  depends_on = [ // depending on all this ensures the stack can be torn down
    aws_s3_bucket.lacework_org_lambda,
    aws_sns_topic.lacework_sns_topic,
    aws_sns_topic_subscription.lacework_sns_subscription,
    aws_sns_topic_policy.default,
    aws_lambda_permission.lacework_lambda_permission,
    aws_secretsmanager_secret.lacework_api_credentials,
    aws_lambda_function.lacework_setup_function
  ]
}

resource "aws_cloudformation_stack_set" "lacework_stackset" {
  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  capabilities = ["CAPABILITY_NAMED_IAM"]
  name         = var.cf_stack_name

  operation_preferences {
    failure_tolerance_count   = 20
    max_concurrent_percentage = 100
  }

  parameters = {
    LaceworkAccount    = var.lacework_account
    MainAccountSNS     = aws_sns_topic.lacework_sns_topic.arn
    ResourceNamePrefix = var.cf_resource_prefix
  }

  permission_model = "SERVICE_MANAGED"
  template_url     = "https://s3.amazonaws.com/${var.cf_s3_bucket}/${var.cf_s3_prefix}/templates/lacework-aws-cfg-member.template.yml"


  depends_on = [ // depending on all this ensures the stackinstances can be torn down
    aws_s3_bucket.lacework_org_lambda,
    aws_sns_topic.lacework_sns_topic,
    aws_sns_topic_subscription.lacework_sns_subscription,
    aws_sns_topic_policy.default,
    aws_lambda_permission.lacework_lambda_permission,
    aws_secretsmanager_secret.lacework_api_credentials,
    aws_lambda_function.lacework_setup_function
  ]
}


data "aws_region" "current" {}
resource "aws_cloudformation_stack_set_instance" "lacework_stackset_instances" {
  deployment_targets {
    organizational_unit_ids = [var.organization_unit]
  }

  region         = data.aws_region.current.name
  stack_set_name = aws_cloudformation_stack_set.lacework_stackset.name
}
