module "mysql_sg" {
    source = "git::https://github.com/ParthuReddy31/terraform-aws-security-group.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "mysql"
    sg_description = "Created for MySQL instances in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

module "backend_sg" {
    source = "git::https://github.com/ParthuReddy31/terraform-aws-security-group.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "backend"
    sg_description = "Created for backend instances in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

module "frontend_sg" {
    source = "git::https://github.com/ParthuReddy31/terraform-aws-security-group.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "frontend"
    sg_description = "Created for frontend instances in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

module "bastion_sg" {
    source = "git::https://github.com/ParthuReddy31/terraform-aws-security-group.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "bastion"
    sg_description = "Created for bastion instances in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

# ports should be open for vpn ssh-22, https-443, internal administration-ports-1194, 943
module "vpn_sg" {
    source = "git::https://github.com/ParthuReddy31/terraform-aws-security-group.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "vpn"
    sg_description = "Created for VPN instances in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

module "app_alb_sg" {
    source = "git::https://github.com/ParthuReddy31/terraform-aws-security-group.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "app-alb"
    sg_description = "Created for ALB instances in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

module "web_alb_sg" {
    source = "git::https://github.com/ParthuReddy31/terraform-aws-security-group.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "web-alb"
    sg_description = "Created for frontend ALB in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

resource "aws_security_group_rule" "app_alb_bastion" {
    type              = "ingress"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    source_security_group_id = module.bastion_sg.sg_id
    security_group_id = module.app_alb_sg.sg_id
}

resource "aws_security_group_rule" "bastion_public" {
    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = module.bastion_sg.sg_id
}
# ports should be open for vpn ssh-22, https-443, internal administration-ports-1194, 943
resource "aws_security_group_rule" "vpn_ssh" {
    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = module.vpn_sg.sg_id
}

resource "aws_security_group_rule" "vpn_443" {
    type              = "ingress"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = module.vpn_sg.sg_id
}

resource "aws_security_group_rule" "vpn_943" {
    type              = "ingress"
    from_port         = 943
    to_port           = 943
    protocol          = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = module.vpn_sg.sg_id
}

resource "aws_security_group_rule" "vpn_1194" {
    type              = "ingress"
    from_port         = 1194
    to_port           = 1194
    protocol          = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = module.vpn_sg.sg_id
}

resource "aws_security_group_rule" "app_alb_vpn" {
    type              = "ingress"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    source_security_group_id = module.vpn_sg.sg_id
    security_group_id = module.app_alb_sg.sg_id
}

resource "aws_security_group_rule" "mysql_bastion" {
    type              = "ingress"
    from_port         = 3306
    to_port           = 3306
    protocol          = "tcp"
    source_security_group_id = module.bastion_sg.sg_id
    security_group_id = module.mysql_sg.sg_id
}

resource "aws_security_group_rule" "mysql_vpn" {
    type              = "ingress"
    from_port         = 3306
    to_port           = 3306
    protocol          = "tcp"
    source_security_group_id = module.vpn_sg.sg_id
    security_group_id = module.mysql_sg.sg_id
}

resource "aws_security_group_rule" "backend_vpn" {
    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    source_security_group_id = module.vpn_sg.sg_id
    security_group_id = module.backend_sg.sg_id
}

resource "aws_security_group_rule" "backend_vpn_http" {
    type              = "ingress"
    from_port         = 8080
    to_port           = 8080
    protocol          = "tcp"
    source_security_group_id = module.vpn_sg.sg_id
    security_group_id = module.backend_sg.sg_id
}

resource "aws_security_group_rule" "backend_app_alb" {
    type              = "ingress"
    from_port         = 8080
    to_port           = 8080
    protocol          = "tcp"
    source_security_group_id = module.app_alb_sg.sg_id
    security_group_id = module.backend_sg.sg_id
}

resource "aws_security_group_rule" "mysql_backend" {
    type              = "ingress"
    from_port         = 3306
    to_port           = 3306
    protocol          = "tcp"
    source_security_group_id = module.backend_sg.sg_id
    security_group_id = module.mysql_sg.sg_id
}

resource "aws_security_group_rule" "web_alb_https" {
    type              = "ingress"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = module.web_alb_sg.sg_id
}

resource "aws_security_group_rule" "app_alb_frontend" {
    type              = "ingress"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    source_security_group_id = module.frontend_sg.sg_id
    security_group_id = module.app_alb_sg.sg_id
}

resource "aws_security_group_rule" "frontend_web_alb" {
    type              = "ingress"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    source_security_group_id = module.web_alb_sg.sg_id
    security_group_id = module.frontend_sg.sg_id
}
# usually you should configure frontend with private ip from VPN only
resource "aws_security_group_rule" "frontend_private" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.frontend_sg.sg_id
}