terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.52.0"
    }

    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }

  required_version = "1.3.7"
}

provider "aws" {
  region = var.region
}
