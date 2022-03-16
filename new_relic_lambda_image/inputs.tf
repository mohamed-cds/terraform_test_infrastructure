variable "product_name" {
  description = "(Required) The name of the product you are deploying."
  type        = string
}

variable "billing_code" {
  description = "The billing code to tag our resources with"
  type        = string
}

variable "region" {
  description = "The current AWS region"
  type        = string
}

variable "new_relic_account" {
  type = string
}

variable "new_relic_license_key" {
  type      = string
  sensitive = true
}
