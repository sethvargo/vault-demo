# Configure the provider
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block           = "${var.cidr_block}"
  enable_dns_hostnames = true

  tags {
    "Name" = "${var.namespace}"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    "Name" = "${var.namespace}"
  }
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${var.cidr_block}"
  map_public_ip_on_launch = true

  tags {
    "Name" = "${var.namespace}"
  }
}

# A security group that makes the instances accessible
resource "aws_security_group" "default" {
  name_prefix = "${var.namespace}-"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the provisioning script.
data "template_file" "vault" {
  template = "${file("${path.module}/templates/vault.sh.tpl")}"
  vars {
    hostname = "${var.namespace}-vault"
  }
}

# Just in case...
resource "aws_key_pair" "default" {
  key_name   = "${var.namespace}-key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

# Create the Vault server
resource "aws_instance" "vault" {
  ami           = "${lookup(var.amis, var.region)}"
  instance_type = "t2.micro"

  key_name = "${aws_key_pair.default.key_name}"

  subnet_id              = "${aws_subnet.default.id}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]

  tags {
    Name = "${var.namespace}-vault"
  }

  user_data = "${data.template_file.vault.rendered}"
}

output "vault" {
  value = "${aws_instance.vault.public_ip}"
}
