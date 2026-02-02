module "stack" {
  source = "../../modules/gergen-stack"

  environment            = "dev"
  project_name           = "gergen-stack"
  project_slug           = "gergen-stack"
  
  db_instance_class      = "db.t3.micro"
  db_multi_az            = false
  db_backup_retention    = 1
  db_deletion_protection = false
}

output "outputs" {
  value = module.stack
}
