#  creating an frontend instance for frontend configuration
resource "aws_instance" "frontend" {
  ami                    = data.aws_ami.joindevops.id  #golden AMI
  instance_type          = "t3.micro"
  subnet_id              = local.public_subnet_id
  vpc_security_group_ids = [data.aws_ssm_parameter.frontend_sg_id.value]
  tags = merge(var.common_tags,
    {
      Name = local.resource_name
    }
  )
}

# here we creating null resource to just run some commands in remote server
resource "null_resource" "frontend" {
  # Changes to any instance of the instance requires re-provisioning
  triggers = {
    instance_id = aws_instance.frontend.id
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = aws_instance.frontend.public_ip
    type = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
  }

  provisioner "file" {
    source      = "frontend.sh"
    destination = "/tmp/frontend.sh"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with public_ip of each node in the cluster
    inline = [
      "chmod +x /tmp/frontend.sh",
      "sudo sh /tmp/frontend.sh ${var.environment}"
    ]
  }
}
# after setting up the environment in instance we are stopping instance for capturing AMI 
resource "aws_ec2_instance_state" "frontend_stop" {
  instance_id = aws_instance.frontend.id
  state       = "stopped"
  depends_on  = [null_resource.frontend]
}

# here, after stopping the instance we will capture the AMI  
resource "aws_ami_from_instance" "frontend" {
  name               = local.resource_name
  source_instance_id = aws_instance.frontend.id
  depends_on         = [aws_ec2_instance_state.frontend_stop]
}

# At-last we will delete the isntance after AMI capturing
# resource "null_resource" "frontend_delete" {

#     triggers = {
#     instance_id = aws_instance.frontend.id
#     }

#   provisioner "local-exec" {
#     command = "aws ec2 terminate-instances --instance-ids ${aws_instance.frontend.id}"
#   }
#   depends_on = [aws_ami_from_instance.frontend]
# }
# creating target group
resource "aws_lb_target_group" "frontend" {
  name     = local.resource_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  deregistration_delay = 60

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    protocol = "HTTP"
    port = 80
    path = "/"
    matcher = "200-299"
    interval = 10
  }
}

resource "aws_launch_template" "frontend" {
  name = local.resource_name
  image_id = aws_ami_from_instance.frontend.id
  instance_initiated_shutdown_behavior = "terminate"
  
  update_default_version = true
 
  instance_type = "t3.micro"

  vpc_security_group_ids = [local.frontend_sg_id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = local.resource_name
    }
  }
}

resource "aws_autoscaling_group" "frontend" {
  name                      = local.resource_name
  max_size                  = 10
  min_size                  = 1
  health_check_grace_period = 180   # 3-min, for instance to initiate
  health_check_type         = "ELB"
  desired_capacity          = 1
  target_group_arns = [aws_lb_target_group.frontend.arn]

  launch_template {
    id = aws_launch_template.frontend.id
    version =  "$Latest"
  }

  vpc_zone_identifier       = local.public_subnet_ids
    instance_refresh {
        strategy = "Rolling"
        preferences {
          min_healthy_percentage = 50
        }
        triggers = ["launch_template"]
    }
  tag {
    key                 = "Name"
    value               = local.resource_name
    propagate_at_launch = true
  }

  timeouts {
    delete = "10m"
  }

tag {
    key                 = "Project"
    value               = "expense"
    propagate_at_launch = false
  }

  tag {
    key                 = "Environment"
    value               = "dev"
    propagate_at_launch = false
  }

}

resource "aws_autoscaling_policy" "frontend" {
  name                   = "${local.resource_name}-frontend"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.frontend.name
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 70.0
  }
}

resource "aws_alb_listener_rule" "frontend" {
    listener_arn = data.aws_ssm_parameter.web_alb_listener_arn.value
    priority = 10
    action {
      type =  "forward"
      target_group_arn = aws_lb_target_group.frontend.arn
    }
    condition {
      host_header {
        values = ["${var.project_name}-${var.environment}.${var.domain_name}"]
      }
    }
}