# Default AWS Org Configuration Assessment with Lacework

This scenario integrates an AWS Organzation with Lacework for cloud resource configuration assessment.

## Sample Code

```hcl
provider "aws" {
  region = "us-west-2"
}

module "aws_org_configuration" {
  source  = "lacework/org-configuration/aws"
  version = "~> 0.1"

  lacework_account       = "account"
  lacework_subaccount    = "sub-account"
  lacework_access_key_id = "accesskey"
  lacework_secret_key    = "_secretkey"
  organization_id        = "o-organizationid"
  organization_unit      = "org-unit"
  cf_resource_prefix     = "prefix"
}
```

For detailed information on integrating Lacework with AWS Organizations see [AWS Organizations and StackSets](https://docs.lacework.net/onboarding/aws-integration-with-cloudformation#aws-organizations-and-stacksets)
