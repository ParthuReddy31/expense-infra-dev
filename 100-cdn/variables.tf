variable "project_name" {
    default = "expense"
}
variable "environment" {
    default = "dev"
}
variable "common_tags" {
    default = {
        Project = "expense"
        Environment = "dev"
        Terraform = true
    }
}

variable "domain_name" {
    default = "parthudevops.space" 
}

variable "zone_id" {
    default = "Z050580338HWTHU4MUZ8C"
}