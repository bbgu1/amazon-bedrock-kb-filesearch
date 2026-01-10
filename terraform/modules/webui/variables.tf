# Variables for WebUI module

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100" # Use only North America and Europe
}

# Optional: For custom domain with SSL certificate
# variable "acm_certificate_arn" {
#   description = "ARN of ACM certificate for custom domain"
#   type        = string
#   default     = ""
# }
