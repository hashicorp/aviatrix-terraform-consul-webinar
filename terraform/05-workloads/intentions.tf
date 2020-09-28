provider "consul" {
  address    = "${data.terraform_remote_state.consul.outputs.aws_consul_public_ip}:8500"
  datacenter = "aws-us-east-1"
}

resource "consul_intention" "deny" {
  source_name      = "*"
  destination_name = "*"
  action           = "deny"
}

resource "consul_intention" "web" {
  source_name      = "web"
  destination_name = "api"
  action           = "allow"
}

resource "consul_intention" "cache" {
  source_name      = "api"
  destination_name = "cache"
  action           = "allow"
}

resource "consul_intention" "currency" {
  source_name      = "api"
  destination_name = "currency"
  action           = "allow"
}
