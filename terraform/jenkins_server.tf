# AMI lookup for this jenkins server
data "aws_ami" "jenkins_server" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["amazon-linux-for-jenkins"]
  }
}

resource "aws_key_pair" "jenkins_server" {
  key_name   = "jenkins_server"
  public_key = file("jenkins_server.pub")
}

# lookup the security group of the jenkins server
data "aws_security_group" "jenkins_server" {
  filter {
    name   = "group-name"
    values = ["jenkinis_server"]
  }
}

# userdata for jenkins server
data "template_file" "jenkinis_server" {
  template = file("scripts/jenkins_server.sh")

  vars = {
    env                    = "dev"
    jenkins_admin_password = "mysuperpassword"
  }
}

# jenkins server itself
resource "aws_instance" "jenkinis_server" {
  ami                    = data.aws_ami.jenkins_server.image_id
  instance_type          = "t3.medium"
  key_name               = aws_key_pair.jenkins_server.key_name
  subnet_id              = data.aws_subnet_ids.default_public.ids[0]
  vpc_security_group_ids = ["${data.aws_security_group.jenkins_server.id}"]
  iam_instance_profile   = "dev_jenkins_server"
  user_data              = data.template_file.jenkinis_server.rendered

  tags = {
    "Name" = "jenkins-server"
  }

  root_block_device {
    delete_on_termination = true
  }
}

output "jenkinis_server_ami_name" {
  value = data.aws_ami.jenkins_server.name
}

output "jenkinis_server_ami_id" {
  value = data.aws_ami.jenkins_server.id
}

output "jenkinis_server_public_ip" {
  value = aws_instance.jenkins_server.public_ip
}

output "jenkinis_server_private_ip" {
  value = aws_instance.jenkinis_server.private_ip
}
