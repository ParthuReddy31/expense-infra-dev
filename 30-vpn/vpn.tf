resource "aws_key_pair" "openvpnas" {
    key_name   = "openvpnas"
    public_key = file("/Users/parthureddy/Desktop/jdevops/openvpnas.pub")
}

resource "aws_instance" "openvpn" {
    ami                    = data.aws_ami.openvpn.id
    key_name               = aws_key_pair.openvpnas.key_name
    instance_type          = "t3.micro"
    subnet_id              = local.public_subnet_ids
    vpc_security_group_ids = local.vpn_sg_ids
    user_data              = file("user-data.sh")

    tags =merge(var.common_tags,
        {
        Name    = local.instance_name
        }
    )
}

output "vpn_ip" {
value = aws_instance.openvpn.public_ip
}