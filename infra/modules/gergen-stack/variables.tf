variable "project_name" {
  description = "Project name"
  type        = string
  default     = "gergen-stack"
}

variable "project_slug" {
  description = "Project slug for naming resources"
  type        = string
  default     = "gergen-stack"
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

# Database
variable "db_instance_class" {
  description = "RDS Instance Class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_backup_retention" {
  description = "RDS Backup retention period in days"
  type        = number
  default     = 1
}

variable "db_multi_az" {
  description = "RDS Multi-AZ"
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "RDS Deletion Protection"
  type        = bool
  default     = false
}

variable "db_password" {
  description = "Initial DB Password (randomly generated if not provided, managed by Secrets Manager)"
  type        = string
  sensitive   = true
  default     = null
}

variable "auth_issuer_uri" {
    description = "Keycloak/OIDC Issuer URI"
    type = string
    default = "https://auth.gergen-stack.com/realms/gergen-realm"
}
