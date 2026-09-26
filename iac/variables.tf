variable "db_port" {
  type        = map(number)
  description = "Puerto externo de PostgreSQL por ambiente"
}

variable "db_password" {
  type        = map(string)
  description = "Contraseña de PostgreSQL por ambiente"
  sensitive   = true
}

variable "backend_port" {
  type        = map(number)
  description = "Puerto externo del backend por ambiente"
}

variable "backend_replicas" {
  type        = map(number)
  description = "Cantidad de réplicas del backend por ambiente"
}
