locals {
    public_subnet_ids = split(",",data.aws_ssm_parameter.public_subnet_ids.value)[0]

    instance_name = "${var.project_name}-${var.environment}-bastion"

    bastion_sg_ids = [data.aws_ssm_parameter.bastion_sg_id.value]
}