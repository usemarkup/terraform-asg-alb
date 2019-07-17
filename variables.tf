variable "region" {
}

variable "vpc_id" {
  type = "string"
}

variable "public_subnet_ids" {
  type = "list"
}

variable "private_subnet_ids" {
  type = "list"
}

variable "custom_tags" {
  type = "map"
}

variable "project" {
  type    = "string"
  default = "name-prod"
}

variable "launch_template_id_for_asg" {
  type = "string"
}

variable "aws_acm_certificate_domain" {
  type    = "string"
  default = "self.usemarkup.com"
}

variable "self_signed_common_name" {
  type    = "string"
  default = "self.usemarkup.com"
}

variable "asg_default_cooldown" {
  default = 60
}

variable "asg_health_check_grace_period" {
  default = 60
}

variable "asg_max_size" {
  default = 4
}

variable "asg_desired_capacity" {
  default = 2
}
