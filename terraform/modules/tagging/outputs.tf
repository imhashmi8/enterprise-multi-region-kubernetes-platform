output "tags" {
  description = "Merged standard and additional tags to apply to all resources."
  value       = local.tags
}

output "name_prefix" {
  description = "Consistent name prefix: <project>-<environment>-<region>."
  value       = "${var.project}-${var.environment}-${var.region}"
}
