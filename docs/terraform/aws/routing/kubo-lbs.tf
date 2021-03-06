variable "region" {
    type = "string"
}

variable "vpc_id" {
    type = "string"
}

variable "node_security_group_id" {
    type = "string"
}

variable "public_subnet_id" {
    type = "string"
}

variable "prefix" {
    type = "string"
}


variable "kubernetes_master_port" {
    type = "string"
    default = "8443"
}

provider "aws" {
    region = "${var.region}"
}

resource "aws_security_group" "api" {
    name        = "${var.prefix}-api-access"
    vpc_id = "${var.vpc_id}"

    ingress {
      from_port   = "${var.kubernetes_master_port}"
      to_port     = "${var.kubernetes_master_port}"
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
    }
}

resource "aws_elb" "api" {
    name               = "${var.prefix}-cfcr-api"
    subnets = ["${var.public_subnet_id}"]
    security_groups = ["${aws_security_group.api.id}"]

    listener {
      instance_port      = "${var.kubernetes_master_port}"
      instance_protocol  = "tcp"
      lb_port            = "${var.kubernetes_master_port}"
      lb_protocol        = "tcp"
    }

    health_check {
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 2
      target              = "TCP:${var.kubernetes_master_port}"
      interval            = 5
    }
}

output "cfcr_master_target_pool" {
   value = "${aws_elb.api.name}"
}

output "master_lb_ip_address" {
  value = "${aws_elb.api.dns_name}"
}

