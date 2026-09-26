resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true
}

# Solo en la red del frontend: nunca alcanza la base de datos
resource "docker_container" "web" {
  count = var.frontend_replicas[terraform.workspace]
  name  = "web-${terraform.workspace}-${count.index + 1}"
  image = docker_image.nginx.image_id

  upload {
    file    = "/usr/share/nginx/html/index.html"
    content = file("${path.module}/../app/frontend/index.html")
  }

  ports {
    internal = 80
    external = var.frontend_port[terraform.workspace] + count.index * 10
  }

  networks_advanced {
    name = docker_network.red_frontend.name
  }
}

output "web_containers" {
  value = docker_container.web[*].name
}
