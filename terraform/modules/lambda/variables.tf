variable "common_tags" {
  type        = map(string)
  description = "A map of common tags to be applied to resources"
}
variable "region" {
  type        = string
  description = "The region in AWS"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the Lambda functions"
}

variable "security_group_id" {
  type        = string
  description = "Security group ID for the Lambda functions"
}
