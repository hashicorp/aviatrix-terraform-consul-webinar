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

resource "aws_security_group" "monitoring" {
  name        = "monitoring"
  description = "monitoring"
  vpc_id      = data.terraform_remote_state.infra.outputs.aws_shared_svcs_vpc

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 16686
    to_port     = 16686
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9411
    to_port     = 9411
    protocol    = "tcp"
    cidr_blocks = ["10.3.0.0/16", "10.6.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "monitoring" {
  instance_type               = "t3.small"
  ami                         = data.aws_ami.ubuntu.id
  key_name                    = data.terraform_remote_state.infra.outputs.aws_ssh_key_name
  vpc_security_group_ids      = ["${aws_security_group.monitoring.id}"]
  subnet_id                   = data.terraform_remote_state.infra.outputs.aws_shared_svcs_public_subnets[0]
  associate_public_ip_address = true
  user_data                   = data.template_file.monitoring.rendered
  iam_instance_profile        = aws_iam_instance_profile.consul.name
  tags = {
    Name = "monitoring"
  }
}

data "template_file" "monitoring" {
  template = "${file("${path.module}/scripts/monitoring.sh")}"
  vars = {
    env = data.terraform_remote_state.infra.outputs.env
  }
}

resource "aws_iam_instance_profile" "consul" {
  name = "consul-${data.terraform_remote_state.infra.outputs.env}"
  role = aws_iam_role.consul.name
}

resource "aws_iam_role" "consul" {
  name = "consul-${data.terraform_remote_state.infra.outputs.env}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "consul" {
  name = "consul-${data.terraform_remote_state.infra.outputs.env}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:DescribeInstances",
      "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "consul" {
  role       = aws_iam_role.consul.name
  policy_arn = aws_iam_policy.consul.arn
}
