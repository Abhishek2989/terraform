# Create VPC #

resource "aws_vpc" "test-vpc" {
  cidr_block = var.cidr

  tags = {
    Name = "test-vpc"
  }
}
# Create Internet Gateway
resource "aws_internet_gateway" "test-igw" {
  vpc_id = aws_vpc.test-vpc.id

  tags = {
    Name = "Test IGW"
	product = "demo-IGW"
  }
}



## Created 2 subnet subnet_dev and subnet_prod 

# Create Dev Public Subnet
resource "aws_subnet" "subnet_dev" {
  vpc_id                  = aws_vpc.test-vpc.id
  cidr_block              = var.subnet_dev
  availability_zone       = var.zone1
  map_public_ip_on_launch = true

  tags = {
    product = "demo-subnet-dev"
	Name = "subnet-dev"
  }
}

# Create Prod Public Subnet
resource "aws_subnet" "subnet_prod" {
  vpc_id                  = aws_vpc.test-vpc.id
  cidr_block              = var.subnet_prod
  availability_zone       = var.zone2
  map_public_ip_on_launch = true

  tags = {
    product = "demo-subnet-prod"
	Name = "subnet-prod"
  }
}

# Route Table Routes #

resource "aws_route_table" "route_table_test" {
 vpc_id = aws_vpc.test-vpc.id
  tags = {
      Name = "Public-RT"
  }
}
resource "aws_route" "public_test" {
  route_table_id = aws_route_table.route_table_test.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.test-igw.id
}
resource "aws_route_table_association" "public_test" {
  subnet_id = aws_subnet.subnet_dev.id
  route_table_id = aws_route_table.route_table_test.id
}

# Create Security Group for Public ALB Security Group 

resource "aws_security_group" "ELB_Security_Group" {
  name        = "ELB_Security_Group"
  description = "Allow inbound 80,443"
  vpc_id      = aws_vpc.test-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
#   ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ELBSecurityGroup"
	produt = "demo-security-group-elb"
  }
}

# Create Security Group for Instances 

resource "aws_security_group" "Allow_Web_Traffic" {
  name        = "EC2SecurityGroup"
  description = "Allow inbound 22,80,443"
  vpc_id      = aws_vpc.test-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
#	security_groups = [aws_security_group.ELB_Security_Group.id]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
#   security_groups = [aws_security_group.ELB_Security_Group.id]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
#   ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "EC2SecurityGroup"
	product = "demo-security-group-ec2"
  }
}


#web-key 
resource "tls_private_key" web_p_key  {
  algorithm = "RSA"
}

resource "aws_key_pair" "web-key" {
  key_name    = "web-key"
  public_key = tls_private_key.web_p_key.public_key_openssh
  }

resource "local_file" "private_key_web" {
  depends_on = [
    tls_private_key.web_p_key,
  ]
  content  = tls_private_key.web_p_key.private_key_pem
  filename = "web_key.pem"
}
output "private_key_webus" { 
  description = "ssh key generated by terraform" 
  value = tls_private_key.web_p_key.private_key_pem
  sensitive = true
}

#Creation of EC2 instance
resource "aws_instance" "AnsibleServer" {
  ami = var.ami_id1
  instance_type = var.instance_type
  key_name = var.keyname
  security_groups = [aws_security_group.Allow_Web_Traffic.id]
  subnet_id = aws_subnet.subnet_dev.id

  tags = {
    product = "demo-ec2"
	Name = "AnsibleServer"
  }
}

#Creation of ansible EC2 instance
resource "aws_instance" "ApplicationServer" {
  ami = var.ami_id2
  instance_type = var.instance_type
  key_name = var.keyname
  security_groups = [aws_security_group.Allow_Web_Traffic.id]
  subnet_id = aws_subnet.subnet_dev.id

  tags = {
    product = "demo-ec2"
	Name = "ApplicationServer"
  }
}



# Create ALB #

resource "aws_lb" "Web_ALB" {
  name               = "Web-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ELB_Security_Group.id]
  subnets            = [aws_subnet.subnet_dev.id, aws_subnet.subnet_prod.id]         # aws_subnet.public.*.id

  enable_deletion_protection = false

  tags = {
    Name = "Web-ALB"
	product = "demoELB"
  }
}

# Create Target Group #

resource "aws_lb_target_group" "ELB_Target_Group" {
  name     = "ELB-Target-Group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.test-vpc.id
  

 # Alter the destination of the health check to be the login page.
  
  health_check {
    path = "/"
    port = 80
    healthy_threshold   = 3
    unhealthy_threshold = 5
    timeout             = 10
#    target              = "HTTP:80/"
    interval            = 30
    protocol            = "HTTP"

  }

}

# Create Listeners HTTP/HTTPS#

resource "aws_lb_listener" "WEB_ELB_Listener_HTTP" {
  load_balancer_arn = aws_lb.Web_ALB.arn
  port              = "80"
  protocol          = "HTTP"
  
    default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}