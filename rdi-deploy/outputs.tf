output "rdi_database_host" {
  value = split(":", rediscloud_essentials_database.rdi_database.public_endpoint)[0]
}

output "rdi_database_port" {
  value = split(":", rediscloud_essentials_database.rdi_database.public_endpoint)[1]
}
