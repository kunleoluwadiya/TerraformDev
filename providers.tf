terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# AWS Provider
provider "aws" {
  region                   = "us-east-1"
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "vscode"
}

