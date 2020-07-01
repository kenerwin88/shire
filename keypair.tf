resource "aws_key_pair" "deployKey" {
  key_name   = "${var.name}-deployKey"
  public_key = var.sshPublicKey
}