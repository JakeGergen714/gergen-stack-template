terraform {
  backend "s3" {
    bucket         = "gergen-stack-tf-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "gergen-stack-tf-lock"
    encrypt        = true
  }
}
