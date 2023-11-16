provider "aws" {
  region = "us-west-2"
}

module "aws_org_configuration" {
  source = "../../"

  lacework_account       = "account"
  lacework_subaccount    = "sub-account"
  lacework_access_key_id = "accesskey"
  lacework_secret_key    = "_secretkey"
  organization_id        = "o-organizationid"
  organization_unit      = ["org-unit"]
  cf_resource_prefix     = "prefix"
}
