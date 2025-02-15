output "backend_url" {
  description = "URL of the backend Cloud Run service"
  value       = google_cloud_run_v2_service.backend.uri
}

output "frontend_url" {
  description = "URL of the frontend Cloud Run service"
  value       = google_cloud_run_v2_service.frontend.uri
}

output "database_instance" {
  description = "The generated database instance name"
  value       = google_sql_database_instance.instance.name
}

output "database_connection" {
  description = "Database connection details"
  sensitive   = true
  value = {
    host     = google_sql_database_instance.instance.private_ip_address
    name     = var.database_name
    user     = var.database_user
    password = var.database_password
  }
}
