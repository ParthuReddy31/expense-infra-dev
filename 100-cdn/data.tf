data "aws_cloudfront_cache_policy" "noCache" {
    name = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "cacheEnable" {
    name = "Managed-CachingOptimized"
}

data "aws_ssm_parameter" "https_certificate_arn" {
#   name = "/expense/dev/web_alb_cerificate_arn"
    name = "/${var.project_name}/${var.environment}/web_alb_cerificate_arn"
    
}

# /expense/dev/web_alb_cerificate_arn


# data "aws_ssm_parameter" "https_certificate_arn" {
#   name = "/${var.project_name}/${var.environment}/web_alb_certificate_arn"
# }