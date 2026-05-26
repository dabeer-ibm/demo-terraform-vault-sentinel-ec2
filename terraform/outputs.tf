output "ami_id" {
  description = "AMI ID resolved from the Canonical Ubuntu 22.04 lookup"
  value       = data.aws_ami.ubuntu.id
}

output "instance_id" {
  value = aws_instance.demo.id
}

output "public_ip" {
  value = aws_instance.demo.public_ip
}

output "ssh_command" {
  description = "Pull the private key from Vault, then SSH"
  value       = "vault kv get -field=private_key kv/demo/ssh > /tmp/demo.pem && chmod 600 /tmp/demo.pem && ssh -i /tmp/demo.pem ubuntu@${aws_instance.demo.public_ip}"
}
