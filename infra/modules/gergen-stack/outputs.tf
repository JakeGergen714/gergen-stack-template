output "environment_names" {
  value = var.environment
}

output "aws_region" {
  value = var.aws_region
}

output "ssm_prefix_base" {
  value = "/gergen-stack/${var.environment}"
}

output "secrets_manager_db_secret_name" {
  value = aws_secretsmanager_secret.db_creds.name
}

output "secrets_manager_db_secret_arn" {
  value = aws_secretsmanager_secret.db_creds.arn
}

output "networking_vpc_id" {
  value = module.vpc.vpc_id
}

output "db_endpoint_address" {
  value = aws_db_instance.postgres.address
}

output "db_port" {
  value = aws_db_instance.postgres.port
}

output "db_name" {
    value = aws_db_instance.postgres.db_name
}

output "api_beanstalk_cname" {
  value = aws_elastic_beanstalk_environment.env.cname
}

output "api_beanstalk_app_name" {
    value = aws_elastic_beanstalk_application.app.name
}

output "api_beanstalk_env_name" {
    value = aws_elastic_beanstalk_environment.env.name
}

output "web_cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.web_cf.id
}

output "web_cloudfront_domain_name" {
  value = aws_cloudfront_distribution.web_cf.domain_name
}

output "web_s3_bucket_name" {
  value = aws_s3_bucket.web_bucket.id
}

output "artifact_bucket_name" {
    value = aws_s3_bucket.beanstalk_app_versions.id
}

output "api_base_url" {
  value = "http://${aws_elastic_beanstalk_environment.env.cname}/api"
}

output "api_deploy_target_identifier" {
  value = "${aws_elastic_beanstalk_application.app.name}/${aws_elastic_beanstalk_environment.env.name}"
}
