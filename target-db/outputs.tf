output "redis_database_host" {
  value = split(":", rediscloud_essentials_database.target_database.public_endpoint)[0]
}

output "redis_database_port" {
  value = split(":", rediscloud_essentials_database.target_database.public_endpoint)[1]
}
