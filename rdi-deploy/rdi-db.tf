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

data "rediscloud_payment_method" "payment_card" {
  card_type         = var.payment_card_type
  last_four_numbers = var.payment_card_last_four
}

data "rediscloud_essentials_plan" "essentials_plan" {
  cloud_provider           = var.essentials_plan_cloud_provider
  region                   = var.essentials_plan_cloud_region
  size                     = 250
  size_measurement_unit    = "MB"
  support_data_persistence = true
  availability             = "No replication"
}

resource "rediscloud_essentials_subscription" "essentials_subscription" {
  name              = "${var.application_prefix}-${var.subscription_name}"
  plan_id           = data.rediscloud_essentials_plan.essentials_plan.id
  payment_method_id = data.rediscloud_payment_method.payment_card.id
}

resource "rediscloud_essentials_database" "rdi_database" {
  subscription_id     = rediscloud_essentials_subscription.essentials_subscription.id
  name                = "${var.application_prefix}-${var.database_name}"
  password            = var.rdi_database_password
  enable_default_user = true
  replication         = false
  data_persistence    = "aof-every-1-second"
  data_eviction       = "noeviction"
}
