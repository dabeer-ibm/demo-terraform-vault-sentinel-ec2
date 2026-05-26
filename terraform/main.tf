# =============================================================================
# Lookup: latest Canonical Ubuntu 22.04 AMI in the target region
# =============================================================================
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =============================================================================
# Lookup: SSH public key from Vault KV v2
# =============================================================================
data "vault_kv_secret_v2" "ssh" {
  mount = "kv"
  name  = "demo/ssh"
}

# =============================================================================
# Lookup: default VPC + default security group + first default subnet
#         (we do NOT create any networking resources)
# =============================================================================
data "aws_vpc" "default" {
  default = true
}

data "aws_ec2_instance_type_offerings" "supported" {
  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }
  location_type = "availability-zone"
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name   = "default"
}

# =============================================================================
# Import the SSH public key (from Vault) as an AWS key pair so EC2 can attach it
# =============================================================================
resource "aws_key_pair" "demo" {
  key_name_prefix = "${var.instance_name}-"
  public_key = data.vault_kv_secret_v2.ssh.data["public_key"]
}

# =============================================================================
# EC2 instance — default VPC, default SG, Ubuntu AMI, SSH key from Vault.
# Tags are mandatory: enforced by the Sentinel policy set in sentinel/.
# =============================================================================
resource "aws_instance" "demo" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.demo.key_name

  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [data.aws_security_group.default.id]

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
  }
}
