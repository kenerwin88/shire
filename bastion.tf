# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# Bastion Security Groups
resource "aws_security_group" "bastion" {
  name        = "Bastion host for ${var.name}"
  description = "Allow SSH access to bastion host and outbound internet access"
  vpc_id      = module.vpc.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Project = var.name
  }
}

resource "aws_security_group_rule" "ssh" {
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "internet" {
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "intranet" {
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  type              = "egress"
  cidr_blocks       = module.vpc.private_subnets_cidr_blocks
  security_group_id = aws_security_group.bastion.id
}

# Instance Profile
resource "aws_iam_instance_profile" "eks_admin_profile" {
  name = "eks_admin_profile"
  role = aws_iam_role.eks_service_role.id
}

# Create EC2 Instance
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = "t3.small"
  key_name                    = aws_key_pair.deployKey.id
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.eks_admin_profile.name

  root_block_device {
    volume_size           = 10
    delete_on_termination = true
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name    = "bastion"
    Project = var.name
  }

  user_data = <<-EOF
    #!/bin/bash

    # KubeCTL
    curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
    chmod +x kubectl
    mv kubectl /usr/bin/kubectl

    # AWS IAM Authenticator
    curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/amd64/aws-iam-authenticator
    chmod +x aws-iam-authenticator
    mv aws-iam-authenticator /usr/bin/aws-iam-authenticator

    # Updated
    yum update -y

    # Pretty Colors
    echo 'export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "' > /etc/profile.d/bettercolor.sh
    echo 'export CLICOLOR=1' >> /etc/profile.d/bettercolor.sh
    echo 'export LSCOLORS=ExFxBxDxCxegedabagacad' >> /etc/profile.d/bettercolor.sh
    echo 'alias ls="ls -GFh" >> /etc/profile.d/bettercolor.sh
  EOF
}


output "bastion_ip_address" {
  value       = aws_instance.bastion.public_ip
  description = "IP address to SSH to for Bastion"
}