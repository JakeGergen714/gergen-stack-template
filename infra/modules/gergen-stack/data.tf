data "aws_elastic_beanstalk_solution_stack" "java_21" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux 2023.*Corretto 21$"
}
