resource "docker_image" "postgres" {
  name         = "postgres:16-alpine"
  keep_locally = true
}

# Una sola instancia por ambiente, solo en la red del backend
resource "docker_container" "db" {
  name  = "bd-${terraform.workspace}"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_PASSWORD=${var.db_password[terraform.workspace]}",
    "POSTGRES_DB=app_${terraform.workspace}"
  ]

  ports {
    internal = 5432
    external = var.db_port[terraform.workspace]
  }

  networks_advanced {
    name = docker_network.red_backend.name
  }
}

output "db_container" {
  value = docker_container.db.name
}
