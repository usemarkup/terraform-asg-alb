provider "tls" {}

provider "aws" {
  region = "${var.region}"
}

data "aws_vpc" "vpc" {
  id = "${var.vpc_id}"
}

locals {
  alb_sg_tags = {
    MarkupTerraformReference = "${var.project}-alb-sg"
    Name                     = "${var.project}-alb-sg"
  }

  alb_tags = {
    MarkupTerraformReference = "${var.project}-alb"
    Name                     = "${var.project}-alb"
  }

  asg_tags = {
    MarkupTerraformReference = "${var.project}-asg"
    Name                     = "${var.project}-asg"
  }
}

resource "tls_private_key" "self" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "self" {
  key_algorithm         = "RSA"
  private_key_pem       = "${tls_private_key.self.private_key_pem}"
  validity_period_hours = 86400

  early_renewal_hours = 1

  subject {
    common_name         = "${var.self_signed_common_name}"
    organization        = "Markup"
    organizational_unit = "Markup Devops"
  }

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "self" {
  private_key      = "${tls_private_key.self.private_key_pem}"
  certificate_body = "${tls_self_signed_cert.self.cert_pem}"
}

data "aws_acm_certificate" "cert" {
  domain     = "${var.aws_acm_certificate_domain}"
  depends_on = ["aws_acm_certificate.self"]
}

resource "aws_security_group" "alb_sg" {
  name = "${var.project}-alb-sg"

  # Allow everything in on port 443
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = "${merge(local.alb_sg_tags, var.custom_tags)}"

  vpc_id = "${var.vpc_id}"

  lifecycle {
    create_before_destroy = true
  }
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  # WE CANNOT USE v4 UNTIL TF 0.12
  version = "~> 3.0"

  security_groups = [
    "${aws_security_group.alb_sg.id}",
  ]

  subnets = "${var.public_subnet_ids}"
  vpc_id  = "${var.vpc_id}"

  # Optional Values
  logging_enabled          = "false"
  http_tcp_listeners_count = 0
  https_listeners_count    = 1

  https_listeners = [
    {
      certificate_arn = "${data.aws_acm_certificate.cert.arn}"
      port            = 443
    },
  ]

  enable_cross_zone_load_balancing = true

  load_balancer_is_internal = "false"
  load_balancer_name        = "${var.project}-alb-lb"

  target_groups = [
    {
      backend_port     = "80"
      backend_protocol = "HTTP"
      name             = "${var.project}-asg-tg"
    },
  ]

  tags = "${merge(local.alb_tags, var.custom_tags)}"

  target_groups_count = 1

  target_groups_defaults = {
    cookie_duration                  = 86400
    deregistration_delay             = 45
    health_check_interval            = 10
    health_check_healthy_threshold   = 3
    health_check_path                = "/"
    health_check_port                = "traffic-port"
    health_check_timeout             = 5
    health_check_unhealthy_threshold = 3
    health_check_matcher             = "${var.health_check_matcher}"
    stickiness_enabled               = false
    target_type                      = "instance"
    slow_start                       = 30
  }
}

resource "aws_autoscaling_group" "asg" {
  desired_capacity    = "${var.asg_desired_capacity}"
  max_size            = "${var.asg_max_size}"
  min_size            = "${var.asg_min_size}"
  default_cooldown    = "${var.asg_default_cooldown}"
  vpc_zone_identifier = ["${var.private_subnet_ids}"]
  name                = "${var.project}-asg"

  termination_policies = [
    "OldestLaunchTemplate",
    "OldestInstance",
  ]

  health_check_grace_period = "${var.asg_health_check_grace_period}"

  target_group_arns = ["${module.alb.target_group_arns}"]

  launch_template {
    id      = "${var.launch_template_id_for_asg}"
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }
}
