module "stack" {
  source = "../../modules/gergen-stack"

  environment            = "prod"
  project_name           = "gergen-stack"
  project_slug           = "gergen-stack"
  
  # Prod Defaults (from blueprint)
  db_instance_class      = "db.t3.medium"
  db_multi_az            = true
  db_backup_retention    = 30
  db_deletion_protection = true
}

output "outputs" {
  value = module.stack
}
