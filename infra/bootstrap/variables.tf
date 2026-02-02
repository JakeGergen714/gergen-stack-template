variable "github_repository" {
  description = "GitHub repository in 'owner/repo' format (e.g., 'jakeg/gergen-stack') for OIDC trust."
  type        = string
}

variable "region" {
    description = "AWS Region"
    type = string
    default = "us-east-1"
}
