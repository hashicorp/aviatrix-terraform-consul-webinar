# Copyright IBM Corp. 2020, 2023
# SPDX-License-Identifier: MPL-2.0

output "jaeger_ui" {
  value = "http://${aws_instance.monitoring.public_ip}:16686"
}
