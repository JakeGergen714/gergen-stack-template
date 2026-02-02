module "stack" {
  source = "../../modules/gergen-stack"

  environment            = "test"
  project_name           = "gergen-stack"
  project_slug           = "gergen-stack"
  
  # Test Defaults (from blueprint)
  db_instance_class      = "db.t3.small"
  db_multi_az            = false
  db_backup_retention    = 7
  db_deletion_protection = true
}

output "outputs" {
  value = module.stack
}
