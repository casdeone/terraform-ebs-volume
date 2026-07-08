variable "account_name" {
  description = "Account tag value applied to every EBS volume."
  type        = string
}

variable "environment" {
  description = "Environment tag value applied to every EBS volume."
  type        = string

  validation {
    condition     = contains(["test", "dev", "stage", "prod"], var.environment)
    error_message = "environment must be one of: test, dev, stage, prod."
  }
}

variable "repo_name" {
  description = "Repository tag value applied to every EBS volume."
  type        = string
  default     = "terraform-ebs-volume"
}

variable "sql_cluster_name" {
  description = "Optional SQL cluster name tag value."
  type        = string
  default     = null
}

variable "sql_instance_name" {
  description = "Optional SQL instance name tag value."
  type        = string
  default     = null
}

variable "sql_vnn" {
  description = "Optional SQL virtual network name tag value."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags applied to every EBS volume."
  type        = map(string)
  default     = {}
}

variable "ebs_name" {
  description = "Name for a single EBS volume when not using ebs_volumes."
  type        = string
  default     = null
}

variable "ebs_type" {
  description = "EBS volume type for a single EBS volume."
  type        = string
  default     = "gp3"
}

variable "ebs_iops" {
  description = "Provisioned IOPS for a single EBS volume."
  type        = number
  default     = 3000
}

variable "ebs_size" {
  description = "Size in GiB for a single EBS volume."
  type        = number
  default     = 200
}

variable "ebs_drive_letter" {
  description = "Windows drive letter for a single EBS volume."
  type        = string
  default     = null
}

variable "ebs_windows_description" {
  description = "Windows description such as drive letter or mount point for a single EBS volume."
  type        = string
  default     = null
}

variable "ebs_availability_zone" {
  description = "Availability zone for a single EBS volume."
  type        = string
  default     = null
}

variable "ebs_shared" {
  description = "Whether a single EBS volume is shared between EC2 hosts."
  type        = bool
  default     = false
}

variable "ebs_volumes" {
  description = "List of EBS volumes to create. When provided, this takes precedence over the single-volume inputs."
  type = list(object({
    name                = string
    availability_zone   = string
    drive_letter        = string
    windows_description = string
    shared              = optional(bool, false)
    type                = optional(string, "gp3")
    iops                = optional(number, 3000)
    size                = optional(number, 200)
    tags                = optional(map(string), {})
  }))
  default = []
}
