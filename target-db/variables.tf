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

variable "essentials_plan_cloud_provider" {
  description = "Cloud provider for the essentials plan"
  type        = string
}

variable "essentials_plan_cloud_region" {
  description = "Cloud region for the essentials plan"
  type        = string
}

variable "target_database_password" {
  description = "Password for the target database"
  type        = string
}
