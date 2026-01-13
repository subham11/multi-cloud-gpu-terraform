# AWS GPU Compute Instance

resource "aws_instance" "gpu" {
  count                  = 1
  ami                    = local.selected_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_a[0].id
  vpc_security_group_ids = [aws_security_group.instance[0].id]
  user_data              = var.user_data_script

  tags = {
    Name = var.vm_name
  }
}
