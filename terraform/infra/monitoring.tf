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
  vpc_id      = module.vpc-shared-svcs.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
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
  key_name                    = aws_key_pair.demo.key_name
  vpc_security_group_ids      = ["${aws_security_group.monitoring.id}"]
  subnet_id                   = module.vpc-shared-svcs.public_subnets[0]
  associate_public_ip_address = true
  tags = {
    Name = "monitoring"
  }
}
