# AWS Application Load Balancer and Target Groups

# Application Load Balancer
resource "aws_lb" "main" {
  count              = 1
  name               = "${var.vm_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = [aws_subnet.public_a[0].id, aws_subnet.public_b[0].id]

  tags = {
    Name = "${var.vm_name}-alb"
  }
}

# Target Group - Routes to Nginx on port 5000 (OAN UI Service)
resource "aws_lb_target_group" "main" {
  count             = 1
  name              = "${var.vm_name}-tg"
  port              = 5000
  protocol          = "HTTP"
  vpc_id            = aws_vpc.main[0].id
  target_type       = "instance"
  proxy_protocol_v2 = false

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "5000"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.vm_name}-tg"
  }
}

# Target Group Attachment
resource "aws_lb_target_group_attachment" "main" {
  count            = 1
  target_group_arn = aws_lb_target_group.main[0].arn
  target_id        = aws_instance.gpu[0].id
  port             = 5000
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  count             = 1
  load_balancer_arn = aws_lb.main[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }
}
