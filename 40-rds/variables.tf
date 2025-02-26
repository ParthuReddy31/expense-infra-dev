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

variable "db_tags" {
    default = {}
}

variable "zone_id" {
    default = "Z050580338HWTHU4MUZ8C"
}

variable "domain_name" {
    default = "parthudevops.space"
}