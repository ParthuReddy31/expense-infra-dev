resource "aws_instance" "bastion" {
    ami                    = data.aws_ami.joindevops.id
    instance_type          = "t3.micro"
    subnet_id = local.public_subnet_ids
    vpc_security_group_ids = local.bastion_sg_ids
    tags =merge(var.common_tags,
        {
        Name    = local.instance_name
        }
    )
}
