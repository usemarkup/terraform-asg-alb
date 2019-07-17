# Terraform ASG ALB

Simple & opinionated module to create an ALB with an ASG for Varnish,Nginx,HAProxy

- Creates Application Load Balancer with TLS Cert listening on 443
- Creates Security Group to handle public internet traffic and allow communication with the Auto Scaling Instances

## Prerequisites

- VPC
- Public/Private Subnet
- Launch Template

## Example

```
resource "aws_security_group" "varnish_sg" {
  name = "varnish-sg"

  # Allow Varnish EC2 to speak to the Internet
  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  vpc_id = "${data.aws_vpc.default.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "varnish_template" {
  name_prefix   = "my-launch-template"
  image_id      = "my-ami"
  instance_type = "my-instance-type"

  lifecycle {
    create_before_destroy = true

    ignore_changes = [
      "image_id",
    ]
  }
}

module "my_asg_and_alb" {
  source = "github.com/usemarkup/terraform-asg-alb/"

  launch_template_id_for_asg = "${aws_launch_template.varnish_template.id}"
  private_subnet_ids = []
  public_subnet_ids = []

  custom_tags = {}

  project = "awesome-dev-thing"

  vpc_id = "1234"
  region = "${var.region}"
}

resource "aws_security_group_rule" "varnish_sg_in_from_alb" {
  from_port = 80
  protocol = "tcp"
  security_group_id = "${aws_security_group.varnish_sg.id}"
  source_security_group_id = "${module.varnish.alb_sg_id}"
  to_port = 80
  type = "ingress"
}

resource "aws_security_group_rule" "alb_out_to_varnish_sg" {
  from_port = 80
  protocol = "tcp"
  security_group_id = "${module.varnish.alb_sg_id}"
  source_security_group_id = "${aws_security_group.varnish_sg.id}"
  to_port = 80
  type = "egress"
}
```

### Note

Public, Not Open Source. No support comes with this Module.
