provider "aws"{
    region = "eu-west-3"
}

variable env {
    description="deployment env"
}

variable path-ssh-key {

}
variable private-ssh-key {

}



data "aws_vpc" "existing_vpc"{
default = true
}

resource "aws_security_group" "my-sg"{
  name = "my-sc"
  description = "my-sc"
  vpc_id = data.aws_vpc.existing_vpc.id

  // To Allow SSH Transport
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Port 80 Transport
  ingress {
    from_port = 8080
    protocol = "tcp"
    to_port = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

}


resource "aws_key_pair" "sshkey" {
    key_name = "key"
    public_key = "${file("${var.path-ssh-key}")}"
}

resource "aws_instance" "ec2-instance" {
    ami = "ami-02b01316e6e3496d9"
    instance_type = "t2.small"
    associate_public_ip_address = true

    vpc_security_group_ids = [
    aws_security_group.my-sg.id
  ]

    key_name = aws_key_pair.sshkey.key_name

      tags = {
      Name : "${var.env}_ec2_instance"
    }

provisioner "local-exec" {

    #working_dir = "/home/toufik/Desktop/ansible/ansible-docker" #change dir
    command = "ansible-playbook --inventory ${self.public_ip}, --private-key ${var.private-ssh-key} --user ec2-user Docker_app.yaml" 
    #we put comma after the ip so ansible will know we are puting an ip adress

}

}

output "ec2_public_ip"{
    value = aws_instance.ec2-instance.public_ip
}
