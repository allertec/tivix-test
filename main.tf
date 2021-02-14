provider "aws" {
  region  = "us-west-1"
}

# Setup VPC
resource "aws_vpc" "main_vpc" {
    cidr_block           = "172.16.0.0/22"
    enable_dns_hostnames = true
    enable_dns_support   = true
    instance_tenancy     = "default"

    tags = {
      env = "candidate011"
      Name = "recruitment@candidate011"
      provisioner = "terraform"
      project = "recruitment"
    }
}

# Setup subnets
resource "aws_subnet" "subnet-recruitment-candidate011" {
    vpc_id                  = aws_vpc.main_vpc.id
    cidr_block              = "172.16.0.0/24"
    availability_zone       = "us-west-1b"

    tags = {
      Name = "recruitment@candidate011"
      provisioner = "terraform"
      env = "candidate011"
      project = "recruitment"
    }
}

resource "aws_subnet" "subnet-andrzejs-subnet2" {
    vpc_id                  = aws_vpc.main_vpc.id
    cidr_block              = "172.16.1.0/24"
    availability_zone       = "us-west-1a"

    tags = {
      Name = "andrzejs-subnet2"
      provisioner = "terraform"
      env = "candidate011"
      project = "recruitment"
    }
}

# Setup Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = aws_vpc.main_vpc.id

    tags = {
      project = "recruitment"
      env = "candidate011"
      Name = "recruitment@candidate011"
      provisioner = "terraform"
    }
}

# Setup Route Tables and RT associations
resource "aws_route_table" "route_table" {
    vpc_id     = aws_vpc.main_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.internet_gateway.id
    }

    tags = {
      project = "recruitment"
      Name = "recruitment@candidate011"
      provisioner = "terraform"
      env = "candidate011"
    }
}

resource "aws_route_table_association" "rta_recruitment_candidate011" {
    route_table_id = aws_route_table.route_table.id
    subnet_id = aws_subnet.subnet-recruitment-candidate011.id
}

resource "aws_route_table_association" "rta_andrzej_subnet" {
    route_table_id = aws_route_table.route_table.id
    subnet_id = aws_subnet.subnet-andrzejs-subnet2.id
}

# Setup Security Group
resource "aws_security_group" "recruitment-candidate011" {
    name        = "recruitment@candidate011"
    description = "Managed by Terraform"
    vpc_id      = aws_vpc.main_vpc.id


    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["127.0.0.1/32"]
    }

    tags = {
      env = "candidate011"
      project = "recruitment"
      Name = "recruitment@candidate011"
      provisioner = "terraform"
    }
}

resource "aws_security_group_rule" "recruitment-candidate011-http-ingress" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.recruitment-candidate011.id
  source_security_group_id = aws_security_group.alb-sec-group.id
}

resource "aws_security_group" "alb-sec-group" {
    name        = "alb-sec-group"
    description = "alb-sec-group"
    vpc_id      = aws_vpc.main_vpc.id

    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
        ipv6_cidr_blocks     = ["::/0"]
    }

    tags = {
      Name = "alb-sec-group"
    }
}

resource "aws_security_group_rule" "alb-http-egress" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb-sec-group.id
  source_security_group_id = aws_security_group.recruitment-candidate011.id
}

# ALB setup
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sec-group.id]
  subnets            = [
    aws_subnet.subnet-recruitment-candidate011.id,
    aws_subnet.subnet-andrzejs-subnet2.id
  ]
  enable_deletion_protection = true

  tags = {
    Name = "alb"
  }
}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.alb_tg.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "alb_tg" {
  name         = "alb-target-group"
  port         = 80
  protocol     = "HTTP"
  vpc_id       = aws_vpc.main_vpc.id
  health_check {
    interval = "60"
    port     = 80
    path     = "/elb-status"
  }
}

# Setup EC2 instances
resource "aws_instance" "recngx01" {
    ami                         = var.image_id
    availability_zone           = "us-west-1b"
    ebs_optimized               = true
    instance_type               = "t3.small"
    monitoring                  = false
    subnet_id                   = aws_subnet.subnet-recruitment-candidate011.id
    vpc_security_group_ids      = [aws_security_group.recruitment-candidate011.id]
    associate_public_ip_address = true

    root_block_device {
        volume_type           = "gp2"
        volume_size           = 8
        delete_on_termination = true
    }

    tags = {
      project = "recruitment"
      env = "candidate011"
      Name = "recngx01"
      provisioner = "terraform"
    }
}

resource "aws_lb_target_group_attachment" "recngx01" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.recngx01.id
  port             = 80
  depends_on       = [
    aws_instance.recngx01
  ]
}

resource "aws_instance" "recngx02" {
    ami                         = var.image_id
    availability_zone           = "us-west-1a"
    ebs_optimized               = true
    instance_type               = "t3.small"
    monitoring                  = false
    subnet_id                   = aws_subnet.subnet-andrzejs-subnet2.id
    vpc_security_group_ids      = [aws_security_group.recruitment-candidate011.id]
    associate_public_ip_address = true

    root_block_device {
        volume_type           = "gp2"
        volume_size           = 8
        delete_on_termination = true
    }

    tags = {
      project = "recruitment"
      env = "candidate011"
      Name = "recngx02"
      provisioner = "terraform"
    }
}

resource "aws_lb_target_group_attachment" "recngx02" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.recngx02.id
  port             = 80
  depends_on       = [
    aws_instance.recngx02
  ]
}

# Setup Cloudwatch Alarm
resource "aws_sns_topic" "my-topic" {
  name_prefix = "ec2-alerts"
}
# EMail is not supported, but maybe we could use some HTTP to send it to some Instant messaging solution like Slack, Teams
#resource "aws_sns_topic_subscription" "email" {
#  protocol  = "email"
#  topic_arn = aws_sns_topic.my-topic.arn
#  endpoint  = "weird_tests@protonmail.com"
#}

resource "aws_cloudwatch_metric_alarm" "my_alarm" {
    alarm_name          = "my_alarm"
    comparison_operator = "LessThanThreshold"
    evaluation_periods  = "1"
    metric_name         = "HealthyHostCount"
    namespace           = "AWS/ApplicationELB"
    period              = "60"
    statistic           = "Average"
    threshold           = "2.0"
    alarm_description   = ""
    alarm_actions       = [aws_sns_topic.my-topic.arn]
    dimensions = {
        TargetGroup  = aws_lb_target_group.alb_tg.arn_suffix
        LoadBalancer = aws_lb.alb.arn_suffix
    }
    depends_on = [
      aws_lb_target_group.alb_tg
    ]
}
