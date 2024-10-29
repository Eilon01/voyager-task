# VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Voyager-VPC"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1a"

  tags = {
    Name = "Voyager-Public-Subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Voyager-Internet-Gateway"
  }
}

# Route Table
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Voyager-Public-Route-Table"
  }
}

# Associate the Route Table with the public subnet
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.route_table.id
}

# Security group for SSH access
resource "aws_security_group" "ssh_access" {
  name_prefix = "allow_ssh"
  vpc_id      = aws_vpc.vpc.id 

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for HTTP and HTTPS access
resource "aws_security_group" "web_access" {
  name_prefix = "allow_http_https"
  vpc_id      = aws_vpc.vpc.id 

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for Kubernetes API (port 6443)
resource "aws_security_group" "k8s_api_access" {
  name_prefix = "allow_k8s_api"
  vpc_id      = aws_vpc.vpc.id 

  ingress {
    description = "Allow Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Generate SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the private key to a local file
resource "local_file" "private_key" {
  filename = "${path.module}/../keys/voyager-key.pem"
  content  = tls_private_key.ssh_key.private_key_pem
  file_permission = "0600" 
}

# Save the public key to a local file
resource "local_file" "public_key" {
  filename = "${path.module}/../keys/voyager-key.pub"
  content  = tls_private_key.ssh_key.public_key_openssh
  file_permission = "0644" 

}

# Create an EC2 Key Pair
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "voyager-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Create EC2 instances
resource "aws_instance" "centos_instance" {
  count           = 2
  ami             = "ami-0f43e505404dec19c" # CentOS Stream 8
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.ec2_key_pair.key_name
  security_groups = [
    aws_security_group.ssh_access.name,
    aws_security_group.web_access.name,
    aws_security_group.k8s_api_access.name
  ]

  root_block_device {
    volume_size = 8
  }

  tags = {
    Name = "CentOS-ec2-${count.index + 1}"
  }

  # Attach EBS volumes
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = 1
  }

  ebs_block_device {
    device_name = "/dev/sdc"
    volume_size = 1
  }

  # Create user and allow SSH
  user_data = <<-EOF
              #!/bin/bash
              # Create the dev user
              useradd -m -s /bin/bash dev
              mkdir -p /home/dev/.ssh
              chown dev:dev /home/dev/.ssh
              chmod 700 /home/dev/.ssh
              echo "${tls_private_key.ssh_key.public_key_openssh}" > /home/dev/.ssh/authorized_keys
              chown dev:dev /home/dev/.ssh/authorized_keys
              chmod 600 /home/dev/.ssh/authorized_keys

              # Format and mount the additional disks
              mkfs -t ext4 /dev/xvdb
              mkfs -t ext4 /dev/xvdc
              mkdir -p /data
              mkdir -p /data1
              echo "/dev/xvdb /data ext4 defaults 0 0" >> /etc/fstab
              echo "/dev/xvdc /data1 ext4 defaults 0 0" >> /etc/fstab
              mount -a
            EOF
}

# Allocate Elastic IPs and associate them with instances
resource "aws_eip" "elastic_ip" {
  count      = 2
  instance   = aws_instance.centos_instance[count.index].id
  domain    = "vpc"
  depends_on = [aws_instance.centos_instance]
}

output "instance_public_ips" {
  value = { for instance in aws_instance.centos_instance : instance.id => instance.public_ip }
}