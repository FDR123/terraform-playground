variable "postgres_username" {
  description = "Username for the PostgreSQL database"
}

variable "postgres_password" {
  description = "Password for the PostgreSQL database"
  sensitive   = true
}

variable "redshift_username" {
  description = "Username for the Redshift cluster"
}

variable "redshift_password" {
  description = "Password for the Redshift cluster"
  sensitive   = true
}
