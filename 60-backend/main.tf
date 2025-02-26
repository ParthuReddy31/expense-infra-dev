#  creating an backend instance for backend configuration
resource "aws_instance" "backend" {
  ami                    = data.aws_ami.joindevops.id
  instance_type          = "t3.micro"
  subnet_id              = local.private_subnet_id
  vpc_security_group_ids = [data.aws_ssm_parameter.backend_sg_id.value]
  tags = merge(var.common_tags,
    {
      Name = local.resource_name
    }
  )
}

# here we creating null resource to just run some commands in remote server
resource "null_resource" "backend" {

  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    instance_id = aws_instance.backend.id
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host     = aws_instance.backend.private_ip
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
  }
  # coping the file to the instances or server
  provisioner "file" {
    source      = "backend.sh"
    destination = "/tmp/backend.sh"
  }

  # to rum commands in remote server
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/backend.sh",
      "sudo sh /tmp/backend.sh ${var.environment}"
    ]
  }
}

# after setting up the environment in instance we are stopping instance for capturing AMI 
resource "aws_ec2_instance_state" "backend" {
  instance_id = aws_instance.backend.id
  state       = "stopped"
  depends_on  = [null_resource.backend]
}

# here, after stopping the instance we will capture the AMI  
resource "aws_ami_from_instance" "backend" {
  name               = local.resource_name
  source_instance_id = aws_instance.backend.id
  depends_on         = [aws_ec2_instance_state.backend]
}

# At-last we will delete the isntance after AMI capturing
# resource "null_resource" "backend_delete" {

#     triggers = {
#     instance_id = aws_instance.backend.id
#     }

#   provisioner "local-exec" {
#     command = "aws ec2 terminate-instances --instance-ids ${aws_instance.backend.id}"
#   }
#   depends_on = [aws_ami_from_instance.backend]
# }

# command = "echo 'Terminating instance: ${aws_instance.backend.id}' && sleep 30 && aws ec2 terminate-instances --instance-ids ${aws_instance.backend.id}"

resource "aws_lb_target_group" "backend" {
  name     = local.resource_name
  port     = 8080
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  deregistration_delay = 60

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    protocol = "HTTP"
    port = 8080
    path = "/health"
    matcher = "200-299"
    interval = 10
  }
}

resource "aws_launch_template" "backend" {
  name = local.resource_name
  image_id = aws_ami_from_instance.backend.id
  instance_initiated_shutdown_behavior = "terminate"
  
  update_default_version = true
 
  instance_type = "t3.micro"

  vpc_security_group_ids = [local.backend_sg_id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = local.resource_name
    }
  }
}

resource "aws_autoscaling_group" "backend" {
  name                      = local.resource_name
  max_size                  = 10
  min_size                  = 1
  health_check_grace_period = 180   # 3-min, for instance to initiate
  health_check_type         = "ELB"
  desired_capacity          = 1
  target_group_arns = [aws_lb_target_group.backend.arn]

  launch_template {
    id = aws_launch_template.backend.id
    version =  "$Latest"
  }

  vpc_zone_identifier       = local.private_subnet_ids
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

resource "aws_autoscaling_policy" "backend" {
  name                   = "${local.resource_name}-backend"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.backend.name
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 70.0
  }
}

resource "aws_alb_listener_rule" "backend" {
    listener_arn = data.aws_ssm_parameter.app_alb_listener_arn.value
    priority = 10
    action {
      type =  "forward"
      target_group_arn = aws_lb_target_group.backend.arn
    }
    condition {
      host_header {
        values = ["backend.app-${var.environment}.${var.domain_name}"]
      }
    }
}