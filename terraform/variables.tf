variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of dev, test or prod."
  }
}

variable "database_name" {
  description = "Snowflake database name"
  type        = string
  default     = "ENTERPRISE_DWH"
}

variable "warehouse_auto_suspend_seconds" {
  description = "Default auto-suspend timeout for cost control"
  type        = number
  default     = 60

  validation {
    condition     = var.warehouse_auto_suspend_seconds >= 30 && var.warehouse_auto_suspend_seconds <= 600
    error_message = "warehouse_auto_suspend_seconds must be between 30 and 600."
  }
}

variable "analyst_countries" {
  description = "Country codes visible to the regional analyst role through row access policies"
  type        = list(string)
  default     = ["CH", "DE", "FR", "IT", "AT"]
}


variable "enable_prod_safeguards" {
  description = "Require explicit acknowledgement for production deployments."
  type        = bool
  default     = false
}
