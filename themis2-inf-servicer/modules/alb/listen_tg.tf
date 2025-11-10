locals {
  api_port            = 3000
  keycloak_port       = 8080
  listener_port       = 443
  kong_port           = 8000
  grafana_port        = 3000
  transformation_port = 3000
}

data "aws_acm_certificate" "acm_certificate" {
  domain      = var.domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.themis2_alb.arn
  port              = local.listener_port
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.acm_certificate.arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}
### サービサー①
## keycloak2 listen & target
resource "aws_lb_target_group" "keycloak2_tg" {
  name        = "${var.sys_name}-${var.env}-${var.keycloak2_cf}-tg"
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
}

resource "aws_lb_listener_rule" "keycloak2" {
  listener_arn = aws_lb_listener.this.arn
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.keycloak2_tg.arn
      }
      stickiness {
        enabled  = true
        duration = 600
      }
    }
  }
  condition {
    host_header {
      values = [var.api_domains.keycloak2]
    }
  }
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.keycloak2_tg
    ]
  }
}

## sample_analyzer listen & target
resource "aws_lb_target_group" "sample_analyzer_tg" {
  name        = "${var.sys_name}-${var.env}-${var.sample_analyzer_cf}-tg"
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

resource "aws_lb_listener_rule" "sample_analyzer" {
  listener_arn = aws_lb_listener.this.arn
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.sample_analyzer_tg.arn
      }
    }
  }
  condition {
    host_header {
      values = [var.api_domains.analyzer]
    }
  }
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.sample_analyzer_tg
    ]
  }
}

## sample_tracker listen & target
resource "aws_lb_target_group" "sample_tracker_tg" {
  name        = "${var.sys_name}-${var.env}-${var.sample_tracker_cf}-tg"
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
    matcher  = "200"

    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener_rule" "sample_tracker" {
  listener_arn = aws_lb_listener.this.arn
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.sample_tracker_tg.arn
      }
    }
  }
  condition {
    host_header {
      values = [var.api_domains.tracker]
    }
  }
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.sample_tracker_tg
    ]
  }
}

## grafana listen & target		
resource "aws_lb_target_group" "grafana_tg" {
  name        = "${var.sys_name}-${var.env}-${var.grafana_cf}-tg"
  port        = local.grafana_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  deregistration_delay   = "10"
  connection_termination = false

  health_check {
    enabled  = true
    path     = "/robots.txt"
    protocol = "HTTP"
    port     = "traffic-port"
    matcher  = "200"

    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener_rule" "grafana" {
  listener_arn = aws_lb_listener.this.arn
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.grafana_tg.arn
      }
      stickiness {
        enabled  = true
        duration = 600
      }
    }
  }
  condition {
    host_header {
      values = [var.api_domains.grafana]
    }
  }
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.grafana_tg
    ]
  }
}

### サービサー②
## keycloak3 listen & target
resource "aws_lb_target_group" "keycloak3_tg" {
  name        = "${var.sys_name}-${var.env}-${var.keycloak3_cf}-tg"
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
}

resource "aws_lb_listener_rule" "keycloak3" {
  listener_arn = aws_lb_listener.this.arn
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.keycloak3_tg.arn
      }
      stickiness {
        enabled  = true
        duration = 600
      }
    }
  }
  condition {
    host_header {
      values = [var.api_domains.keycloak3]
    }
  }
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.keycloak3_tg
    ]
  }
}

## sample_analyzer2 listen & target
resource "aws_lb_target_group" "sample_analyzer2_tg" {
  name        = "${var.sys_name}-${var.env}-${var.sample_analyzer2_cf}-tg"
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

resource "aws_lb_listener_rule" "sample_analyzer2" {
  listener_arn = aws_lb_listener.this.arn
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.sample_analyzer2_tg.arn
      }
    }
  }
  condition {
    host_header {
      values = [var.api_domains.analyzer2]
    }
  }
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.sample_analyzer2_tg
    ]
  }
}

## sample_tracker2 listen & target
resource "aws_lb_target_group" "sample_tracker2_tg" {
  name        = "${var.sys_name}-${var.env}-${var.sample_tracker2_cf}-tg"
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
    matcher  = "200"

    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener_rule" "sample_tracker2" {
  listener_arn = aws_lb_listener.this.arn
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.sample_tracker2_tg.arn
      }
    }
  }
  condition {
    host_header {
      values = [var.api_domains.tracker2]
    }
  }
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.sample_tracker2_tg
    ]
  }
}


## grafana2 listen & target		
resource "aws_lb_target_group" "grafana2_tg" {
  name        = "${var.sys_name}-${var.env}-${var.grafana2_cf}-tg"
  port        = local.grafana_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  deregistration_delay   = "10"
  connection_termination = false

  health_check {
    enabled  = true
    path     = "/robots.txt"
    protocol = "HTTP"
    port     = "traffic-port"
    matcher  = "200"

    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener_rule" "grafana2" {
  listener_arn = aws_lb_listener.this.arn
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.grafana2_tg.arn
      }
      stickiness {
        enabled  = true
        duration = 600
      }
    }
  }
  condition {
    host_header {
      values = [var.api_domains.grafana2]
    }
  }
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.grafana2_tg
    ]
  }
}
###


###################################################################################################
## transformation listen & target		
resource "aws_lb_target_group" "transformation_tg" {
  name        = "${var.sys_name}-${var.env}-${var.transformation_cf}-tg"
  port        = local.transformation_port
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

resource "aws_lb_listener_rule" "transformation" {
  listener_arn = aws_lb_listener.this.arn
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.transformation_tg.arn
      }
    }
  }
  condition {
    host_header {
      values = [var.api_domains.transformation]
    }
  }
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.transformation_tg
    ]
  }
}

## transformation listen2 & target		
resource "aws_lb_target_group" "transformation2_tg" {
  name        = "${var.sys_name}-${var.env}-${var.transformation2_cf}-tg"
  port        = local.transformation_port
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

resource "aws_lb_listener_rule" "transformation2" {
  listener_arn = aws_lb_listener.this.arn
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.transformation2_tg.arn
      }
    }
  }
  condition {
    host_header {
      values = [var.api_domains.transformation2]
    }
  }
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.transformation2_tg
    ]
  }
}

## servicer_console listen & target
resource "aws_lb_target_group" "servicer_console_tg" {
  name        = "${var.sys_name}-${var.env}-${var.servicer_console_cf}-tg"
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

resource "aws_lb_listener_rule" "servicer_console" {
  listener_arn = aws_lb_listener.this.arn
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.servicer_console_tg.arn
      }
    }
  }
  condition {
    host_header {
      values = [var.api_domains.servicer]
    }
  }
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.servicer_console_tg
    ]
  }
}

## servicer2_console listen & target
resource "aws_lb_target_group" "servicer2_console_tg" {
  name        = "${var.sys_name}-${var.env}-${var.servicer2_console_cf}-tg"
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

resource "aws_lb_listener_rule" "servicer2_console" {
  listener_arn = aws_lb_listener.this.arn
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.servicer2_console_tg.arn
      }
    }
  }
  condition {
    host_header {
      values = [var.api_domains.servicer2]
    }
  }
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.servicer2_console_tg
    ]
  }
}
