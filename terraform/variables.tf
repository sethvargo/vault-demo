variable "access_key" {
  description = "The AWS access key."
}

variable "secret_key" {
  description = "The AWS secret key."
}

variable "region" {
  description = "The region to create resources."
  default     = "us-east-1"
}

variable "namespace" {
  description = "In case running multiple demos."
}

variable "cidr_block" {
  default = "10.1.0.0/16"
}

variable "amis" {
  default = {
    ap-northeast-1 = "ami-bb32ddda"
    ap-southeast-1 = "ami-c4ae7ea7"
    eu-central-1   = "ami-74ee001b"
    eu-west-1      = "ami-8328bbf0"
    sa-east-1      = "ami-0c51da60"
    us-east-1      = "ami-db24d8b6"
    us-west-1      = "ami-31106a51"
    cn-north-1     = "ami-0679b06b"
    us-gov-west-1  = "ami-b410afd5"
    ap-southeast-2 = "ami-d5cae4b6"
    us-west-2      = "ami-6635cd06"
  }
}

variable "dnsimple_email" {
  description = "Email to use for DNS"
}

variable "dnsimple_token" {
  description = "Token to connect to DNSimple"
}
