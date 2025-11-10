locals {
  api_port             = 3000
  keycloak_port        = 8080
  listener_port        = 443
  kong_port            = 8000
  grafana_port         = 3000
  transformation_port  = 3000
  iotagent_json_port   = 4041
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.themis2_alb.arn
  port              = local.listener_port
  protocol          = "HTTPS"
  certificate_arn   = var.https_crt_arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type            = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}

## iotagent listen & target
resource "aws_lb_target_group" "iotagent_tg" {
  name        = "${var.sys_name}-${var.env}-${var.iotagent_cf}-tg"
  port        = local.api_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  deregistration_delay   = "10"
  connection_termination = false

  health_check {
    enabled  = true
    path     = "/"
    protocol = "HTTP"
    port     = "traffic-port"
    matcher  = "200,307"

    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener_rule" "iotagent" {
  listener_arn = aws_lb_listener.this.arn

  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.iotagent_tg.arn
      }
    }
  }

  condition {
    host_header {
      values = [var.api_domains.iotagent]
    }
  }

  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.iotagent_tg
    ]
  }
}

## keycloak listen & target
resource "aws_lb_target_group" "keycloak_tg" {
  name        = "${var.sys_name}-${var.env}-${var.keycloak_cf}-tg"
  port        = local.keycloak_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  deregistration_delay   = "10"
  connection_termination = false

  health_check {
    enabled  = true
    path     = "/realms/master/.well-known/openid-configuration"
    protocol = "HTTP"
    port     = "traffic-port"
    matcher  = "200"

    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 600
  }
}

resource "aws_lb_listener_rule" "keycloak" {
  listener_arn = aws_lb_listener.this.arn
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.keycloak_tg.arn
      }
      stickiness {
        enabled = true
        duration = 600
      }
    }
  }
  condition {
    host_header {
      values = [var.api_domains.keycloak]
    }
  }
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.keycloak_tg
    ]
  }
}

## platform_console listen & target
resource "aws_lb_target_group" "platform_console_tg" {
  name        = "${var.sys_name}-${var.env}-${var.platform_console_cf}-tg"
  port        = local.api_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  deregistration_delay   = "10"
  connection_termination = false

  health_check {
    enabled  = true
    path     = "/"
    protocol = "HTTP"
    port     = "traffic-port"
    matcher  = "200-299,300-399,400-499"

    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener_rule" "platform_console" {
  listener_arn = aws_lb_listener.this.arn
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.platform_console_tg.arn
      }
    }
  }
  condition {
    host_header {
      values = [var.api_domains.platform]
    }
  }
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.platform_console_tg
    ]
  }
}

## konggateway listen & target
resource "aws_lb_target_group" "external_kong_tg" {
  name        = "${var.sys_name}-${var.env}-${var.external_kong_cf}-tg"
  port        = local.kong_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  deregistration_delay   = "10"
  connection_termination = false

  health_check {
    enabled  = true
    path     = "/"
    protocol = "HTTP"
    port     = "traffic-port"
    matcher  = "200,404"

    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener_rule" "external_kong" {
  listener_arn = aws_lb_listener.this.arn
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.external_kong_tg.arn
      }
      stickiness {
        enabled = true
        duration = 600
      }
    }
  }
  condition {
    host_header {
      values = [var.api_domains.kong]
    }
  }
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.external_kong_tg
    ]
  }
}

## iotagent_json listen & target
resource "aws_lb_target_group" "iotagent_json_tg" {
  name        = "${var.sys_name}-${var.env}-${var.iotagent_json_cf}-tg"
  port        = local.iotagent_json_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  deregistration_delay   = "10"
  connection_termination = false

  health_check {
    enabled  = true
    path     = "/iot/about"
    protocol = "HTTP"
    port     = "traffic-port"
    matcher  = "200"

    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener_rule" "iotagent_json" {
  listener_arn = aws_lb_listener.this.arn

  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.iotagent_json_tg.arn
      }
    }
  }

  condition {
    host_header {
      values = [var.api_domains.iotagent_json]
    }
  }

  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.iotagent_json_tg
    ]
  }
}
