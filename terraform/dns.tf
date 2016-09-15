provider "dnsimple" {
  email = "${var.dnsimple_email}"
  token = "${var.dnsimple_token}"
}

# Setup DNS to the server
resource "dnsimple_record" "vault" {
  domain = "hashicorp.rocks"
  type   = "A"
  name   = "vault"
  value  = "${aws_instance.vault.public_ip}"
  ttl    = "30"
}
