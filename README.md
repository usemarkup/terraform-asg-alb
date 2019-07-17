# Terraform ASG ALB

Simple & opinionated module to create an ALB with an ASG for Varnish,Nginx,HAProxy

- Creates Application Load Balancer with TLS Cert listening on 443
- Creates Security Group to handle public internet traffic and allow communication with the Auto Scaling Instances

## Prerequisites

- Public/Private Subnet
- Launch Template
- Empty Security Group for use with the ASG


### Note

Public, Not Open Source. Do not use.
