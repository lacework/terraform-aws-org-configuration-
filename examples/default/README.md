# Default AWS Org Configuration Assessment with Lacework

This scenario integrates an AWS Organzation with Lacework for cloud resource configuration assessment.

## Sample Code

```hcl
terraform {
  required_providers {
    lacework = {
      source = "lacework/lacework"
    }
  }
}

provider "lacework" {}

provider "aws" {}

module "aws_org_configuration" {
    source = "../../"

    lacework_account       = "account"
    lacework_sub_account   = "sub-account"
    lacework_access_key_id = "accesskey"
    lacework_secret_key    = "_secretkey"
    organization_id        = "o-organizationid"
    organization_unit      = "org-unit"
    resource_prefix        = "prefix"
}
```

For detailed information on integrating Lacework with AWS Organizations see [AWS Organizations and StackSets](https://docs.lacework.net/onboarding/aws-integration-with-cloudformation#aws-organizations-and-stacksets)