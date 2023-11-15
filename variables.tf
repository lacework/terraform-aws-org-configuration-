variable "lacework_account" {
  type        = string
  description = "Lacework account name.  Do not include the '.lacework.net' at the end."
}

variable "lacework_subaccount" {
  type        = string
  default     = ""
  description = "If Lacework Organizations is enabled, enter the sub-account.  Leave blank if Lacework Organizations is not enabled."
  validation {
    condition     = can(regex("^$|^[a-zA-Z0-9.]+(?:-[a-zA-Z0-9.]+)*$", var.lacework_subaccount))
    error_message = "Invalid Lacework account name entered. The account name may contain alphanumeric characters and dashes only."
  }
}

variable "lacework_access_key_id" {
  type      = string
  sensitive = true
  validation {
    condition     = can(regex("^[-a-zA-Z0-9_]+$", var.lacework_access_key_id))
    error_message = "Enter the Lacework API Secret Key ID. See https://support.lacework.com/hc/en-us/articles/360011403853-Generate-API-Access-Keys-and-Tokens."
  }
}

variable "lacework_secret_key" {
  type      = string
  sensitive = true
  validation {
    condition     = can(regex("^[a-zA-Z0-9_]+$", var.lacework_secret_key))
    error_message = "Enter the Lacework API Secret Key. See https://support.lacework.com/hc/en-us/articles/360011403853-Generate-API-Access-Keys-and-Tokens."
  }
}

variable "organization_id" {
  type        = string
  description = "AWS Organization ID where these resources are being deployed into"
  validation {
    condition     = can(regex("^o-[a-z0-9]{10,32}$", var.organization_id))
    error_message = "Invalid AWS Organization ID"
  }
}

variable "organization_unit" {
  type        = list(string)
  description = "Organizational Unit ID that the stackset will be deployed into"
}

variable "cf_stack_name" {
  type        = string
  default     = "lacework-aws-org-configuration"
  description = "The stackset name"
}

variable "cf_resource_prefix" {
  type        = string
  description = "Prefix for resources created by Lacework stackset"
  validation {
    condition     = can(regex("^[a-zA-Z0-9]+(?:-[a-zA-Z0-9]+)*$", var.cf_resource_prefix))
    error_message = "Invalid resource name prefix.  Must match pattern ^[a-zA-Z0-9]+(?:-[a-zA-Z0-9]+)*$"
  }
}

variable "cf_s3_bucket" {
  type        = string
  default     = "lacework-alliances"
  description = "Enter the S3 bucket for Lacework Cloudformation assets. Use this if you want to customize your deployment."
}

variable "cf_s3_prefix" {
  type        = string
  default     = "lacework-organization-cfn"
  description = "Enter the S3 key prefix for Lacework Cloudformation assets directory. Use this if you want to customize your deployment."
}

variable "kms_key_arn" {
  type        = string
  default     = ""
  description = "The ARN of an existing KMS encryption key to be used for SNS and Secrets"
}

variable "kms_key_rotation" {
  type        = bool
  default     = false
  description = "Enable KMS automatic key rotation"
}

variable "kms_key_deletion_days" {
  type        = number
  default     = 30
  description = "The waiting period, specified in number of days"
}

variable "kms_key_multi_region" {
  type        = bool
  default     = true
  description = "Whether the KMS key is a multi-region or regional key"
}
