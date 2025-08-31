terraform {
  required_providers {
    rediscloud = {
      source = "RedisLabs/rediscloud"
    }
  }
  required_version = "~> 1.2"
}

provider "rediscloud" {
}

data "rediscloud_essentials_plan" "essentials_plan" {
  cloud_provider           = var.essentials_plan_cloud_provider
  region                   = var.essentials_plan_cloud_region
  size                     = 30
  size_measurement_unit    = "MB"
  support_data_persistence = false
  availability             = "No replication"
}

resource "rediscloud_essentials_subscription" "essentials_subscription" {
  name    = "${var.application_prefix}-${var.subscription_name}"
  plan_id = data.rediscloud_essentials_plan.essentials_plan.id
}

resource "rediscloud_essentials_database" "target_database" {
  subscription_id     = rediscloud_essentials_subscription.essentials_subscription.id
  name                = "${var.application_prefix}-${var.database_name}"
  enable_default_user = true
  password            = var.target_database_password
  data_persistence    = "none"
  replication         = false
}
