locals {
    public_subnet_ids = split(",",data.aws_ssm_parameter.public_subnet_ids.value)[0]

    instance_name = "${var.project_name}-${var.environment}-vpn"

    vpn_sg_ids = [data.aws_ssm_parameter.vpn_sg_id.value]
}