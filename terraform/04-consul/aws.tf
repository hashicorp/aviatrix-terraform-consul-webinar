data "aws_ami" "ubuntu" {
  owners = ["099720109477"]

  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "consul" {
  name        = "consul"
  description = "consul"
  vpc_id      = data.terraform_remote_state.infra.outputs.aws_shared_svcs_vpc

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = ["10.2.0.0/16", "10.3.0.0/16", "10.5.0.0/16"]
  }

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = ["10.2.0.0/16", "10.3.0.0/16"]
  }

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "udp"
    cidr_blocks = ["10.2.0.0/16", "10.3.0.0/16"]
  }

  ingress {
    from_port   = 8302
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = ["10.5.0.0/16"]
  }

  ingress {
    from_port   = 8302
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = ["10.5.0.0/16"]
  }

  ingress {
    from_port   = 8500
    to_port     = 8500
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

resource "aws_instance" "consul" {
  instance_type               = "t3.small"
  ami                         = data.aws_ami.ubuntu.id
  key_name                    = data.terraform_remote_state.infra.outputs.aws_ssh_key_name
  vpc_security_group_ids      = ["${aws_security_group.consul.id}"]
  subnet_id                   = data.terraform_remote_state.infra.outputs.aws_shared_svcs_public_subnets[0]
  associate_public_ip_address = true
  user_data                   = data.template_file.init.rendered
  tags = {
    Name = "consul"
    Env  = "consul-${data.terraform_remote_state.infra.outputs.env}"
  }
}

data "template_file" "init" {
  template = "${file("${path.module}/scripts/aws_consul.sh")}"
  vars = {
    consul_wan_ip = azurerm_network_interface.consul.private_ip_address
  }
}

resource "helm_release" "aws-consul" {
  provider = helm.aws

  name       = "hashicorp"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"

  values = [<<EOF
global:
  image: consul:1.8.0
  domain: consul
  datacenter: aws-us-east-1
  tls:
    enabled: false
  acls:
    manageSystemACLs: false
server:
  enabled: false
client:
  enabled: true
  join: ["provider=aws tag_key=Env tag_value=consul-${data.terraform_remote_state.infra.outputs.env}"]
connectInject:
  enabled: true
  default: true
  centralConfig:
    enabled: true
  k8sAllowNamespaces: ["default"]
syncCatalog:
  enabled: true
  default: false
  toConsul: true
  toK8S: false
EOF
  ]
}
