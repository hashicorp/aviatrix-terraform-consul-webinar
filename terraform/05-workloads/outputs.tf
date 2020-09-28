output "jaeger_ui" {
  value = "http://${aws_instance.monitoring.public_ip}:16686"
}
