variable "application_prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "subscription_name" {
  description = "Name of the Redis subscription"
  type        = string
}

variable "database_name" {
  description = "Name of the Redis database"
  type        = string
}

variable "payment_card_type" {
  description = "Type of the payment card"
  type        = string
}

variable "payment_card_last_four" {
  description = "Last four digits of the payment card"
  type        = string
}

variable "essentials_plan_cloud_provider" {
  description = "Cloud provider for the essentials plan"
  type        = string
}

variable "essentials_plan_cloud_region" {
  description = "Cloud region for the essentials plan"
  type        = string
}

variable "rdi_database_password" {
  description = "Password for the RDI database"
  type        = string
}
