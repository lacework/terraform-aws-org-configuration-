<a href="https://lacework.com"><img src="https://techally-content.s3-us-west-1.amazonaws.com/public-content/lacework_logo_full.png" width="600"></a>

# terraform-aws-org-configuration

[![GitHub release](https://img.shields.io/github/release/lacework/terraform-aws-org-configuration.svg)](https://github.com/lacework/terraform-aws-org-configuration/releases/)

Terraform module for configuring an integration with Lacework and AWS for cloud resource configuration assessment.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.35.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.35.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudformation_stack.lacework_stack](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack) | resource |
| [aws_cloudformation_stack_set.lacework_stackset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set) | resource |
| [aws_iam_role.lacework_copy_zip_files_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.lacework_setup_function_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_kms_key.lacework_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_lambda_function.lacework_copy_zip_files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.lacework_setup_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_invocation.lacework_copy_zip_files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_invocation) | resource |
| [aws_lambda_permission.lacework_lambda_permission](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_bucket.lacework_org_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_ownership_controls.lacework_org_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_public_access_block.lacework_org_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_versioning.lacework_org_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_secretsmanager_secret.lacework_api_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.lacework_api_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_sns_topic.lacework_sns_topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.lacework_sns_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [archive_file.lambda_zip_file](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.kms_key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lacework_copy_zip_files_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lacework_copy_zip_files_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lacework_setup_function_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lacework_setup_function_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sns_topic_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cf_resource_prefix"></a> [cf\_resource\_prefix](#input\_cf\_resource\_prefix) | Prefix for resources created by Lacework stackset | `string` | n/a | yes |
| <a name="input_cf_s3_bucket"></a> [cf\_s3\_bucket](#input\_cf\_s3\_bucket) | Enter the S3 bucket for Lacework Cloudformation assets. Use this if you want to customize your deployment. | `string` | `"lacework-alliances"` | no |
| <a name="input_cf_s3_prefix"></a> [cf\_s3\_prefix](#input\_cf\_s3\_prefix) | Enter the S3 key prefix for Lacework Cloudformation assets directory. Use this if you want to customize your deployment. | `string` | `"lacework-organization-cfn"` | no |
| <a name="input_cf_stack_name"></a> [cf\_stack\_name](#input\_cf\_stack\_name) | The stackset name | `string` | `"lacework-aws-org-configuration"` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | The ARN of an existing KMS encryption key to be used for SNS and Secrets | `string` | `""` | no |
| <a name="input_kms_key_deletion_days"></a> [kms\_key\_deletion\_days](#input\_kms\_key\_deletion\_days) | The waiting period, specified in number of days | `number` | `30` | no |
| <a name="input_kms_key_multi_region"></a> [kms\_key\_multi\_region](#input\_kms\_key\_multi\_region) | Whether the KMS key is a multi-region or regional key | `bool` | `true` | no |
| <a name="input_kms_key_rotation"></a> [kms\_key\_rotation](#input\_kms\_key\_rotation) | Enable KMS automatic key rotation | `bool` | `false` | no |
| <a name="input_lacework_access_key_id"></a> [lacework\_access\_key\_id](#input\_lacework\_access\_key\_id) | n/a | `string` | n/a | yes |
| <a name="input_lacework_access_secret_key"></a> [lacework\_access\_secret\_key](#input\_lacework\_access\_secret\_key) | n/a | `string` | n/a | yes |
| <a name="input_lacework_account"></a> [lacework\_account](#input\_lacework\_account) | Lacework account name.  Do not include the '.lacework.net' at the end. | `string` | n/a | yes |
| <a name="input_lacework_subaccount"></a> [lacework\_subaccount](#input\_lacework\_subaccount) | If Lacework Organizations is enabled, enter the sub-account.  Leave blank if Lacework Organizations is not enabled. | `string` | `""` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | AWS Organization ID where these resources are being deployed into | `string` | n/a | yes |
| <a name="input_organization_unit"></a> [organization\_unit](#input\_organization\_unit) | Organizational Unit ID that the stackset will be deployed into | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->