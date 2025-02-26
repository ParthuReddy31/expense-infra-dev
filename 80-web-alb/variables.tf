variable "project_name" {
    default = "expense"
}

variable "environment"{
    default = "dev"
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"
}

variable "common_tags" {
    default = {
        Project = "expense"
        Environment = "dev"
        Terraform = "true"
    }
}

variable "app_alb_sg_tags" {
    default = {}
}

variable "zone_id" {
    default = "Z050580338HWTHU4MUZ8C"
}

variable "domain_name" {
    default = "parthudevops.space"
}