variable "cloudfront_distribution_id" {
  description = "cloudfront_distribution_id"
  type        = string
}

variable "iam_policy_arn" {
  description = "IAM Policy to be attached to role"
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/AmazonEventBridgeReadOnlyAccess","arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}