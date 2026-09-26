# Comunica el frontend con el backend
resource "docker_network" "red_frontend" {
  name = "red-frontend-${terraform.workspace}"
}

# Comunica el backend con la base de datos
resource "docker_network" "red_backend" {
  name = "red-backend-${terraform.workspace}"
}

output "red_frontend" {
  value = docker_network.red_frontend.name
}

output "red_backend" {
  value = docker_network.red_backend.name
}
