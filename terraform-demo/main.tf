resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name    = "ExampleAppServerInstance",
    version = "1.2.0"
    env = "test"
  }
}
