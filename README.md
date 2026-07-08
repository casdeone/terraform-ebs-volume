# terraform-ebs-volume

Terraform module to create one or more AWS EBS volumes for Windows EC2 instances, including optional multi-attach support for failover cluster scenarios.

## Features

- Create a single EBS volume with simple top-level inputs
- Create multiple EBS volumes with `ebs_volumes`
- Optionally attach each volume to one or more EC2 instances
- Apply default `account`, `environment`, and `repo` tags to every volume
- Add optional SQL-related tags: `sql_cluster_name`, `sql_instance_name`, and `sql_vnn`
- Tag each volume with `drive_letter` and `windows_description`

## Usage

### Single volume

```hcl
module "ebs_volume" {
  source = "github.com/casdeone/terraform-ebs-volume"

  account_name            = "shared-services"
  environment             = "prod"
  repo_name               = "terraform-ebs-volume"
  ebs_name                = "sql-data"
  ebs_availability_zone   = "us-east-1a"
  ebs_drive_letter        = "F"
  ebs_windows_description = "SQLDATA"
  ebs_device_name         = "/dev/sdf"
  ebs_instance_id         = "i-0123456789abcdef0"
}
```

### Multiple volumes

```hcl
module "ebs_volumes" {
  source = "github.com/casdeone/terraform-ebs-volume"

  account_name = "shared-services"
  environment  = "prod"

  sql_cluster_name  = "sql-cluster-01"
  sql_instance_name = "mssqlserver"
  sql_vnn           = "sql-vnn-01"

  ebs_volumes = [
    {
      name                = "sql-data"
      availability_zone   = "us-east-1a"
      drive_letter        = "F"
      windows_description = "SQLDATA"
      device_name         = "/dev/sdf"
      size                = 500
    },
    {
      name                = "sql-quorum"
      availability_zone   = "us-east-1a"
      drive_letter        = "Q"
      windows_description = "QUORUM"
      device_name         = "/dev/sdg"
      instance_ids        = ["i-0123456789abcdef0", "i-0fedcba9876543210"]
      type                = "io2"
      iops                = 4000
      shared              = true
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default |
| --- | --- | --- | --- |
| `account_name` | Account tag value applied to every EBS volume. | `string` | n/a |
| `environment` | Environment tag value applied to every EBS volume. Allowed values: `test`, `dev`, `stage`, `prod`. | `string` | n/a |
| `repo_name` | Repository tag value applied to every EBS volume. | `string` | `"terraform-ebs-volume"` |
| `sql_cluster_name` | Optional SQL cluster name tag value. | `string` | `null` |
| `sql_instance_name` | Optional SQL instance name tag value. | `string` | `null` |
| `sql_vnn` | Optional SQL virtual network name tag value. | `string` | `null` |
| `tags` | Additional tags applied to every EBS volume. | `map(string)` | `{}` |
| `ebs_name` | Name for a single EBS volume when not using `ebs_volumes`. | `string` | `null` |
| `ebs_type` | EBS volume type for a single EBS volume. | `string` | `"gp3"` |
| `ebs_iops` | Provisioned IOPS for a single EBS volume. | `number` | `3000` |
| `ebs_size` | Size in GiB for a single EBS volume. | `number` | `200` |
| `ebs_drive_letter` | Windows drive letter for a single EBS volume. | `string` | `null` |
| `ebs_windows_description` | Windows description such as drive letter or mount point for a single EBS volume. | `string` | `null` |
| `ebs_availability_zone` | Availability zone for a single EBS volume. | `string` | `null` |
| `ebs_device_name` | EC2 device name to use when attaching a single EBS volume. Required when setting `ebs_instance_id` or `ebs_instance_ids`. | `string` | `null` |
| `ebs_instance_id` | EC2 instance ID to attach a single EBS volume to. | `string` | `null` |
| `ebs_instance_ids` | EC2 instance IDs to attach a single EBS volume to. Set `ebs_shared = true` when attaching to multiple instances. | `list(string)` | `[]` |
| `ebs_shared` | Whether a single EBS volume is shared between EC2 hosts. Shared volumes must use `io1` or `io2`. | `bool` | `false` |
| `ebs_volumes` | List of EBS volumes to create. Each object can also include optional `device_name`, `instance_id`, and `instance_ids` attachment settings. When provided, this takes precedence over the single-volume inputs. | `list(object(...))` | `[]` |

## Outputs

| Name | Description |
| --- | --- |
| `attachment_ids` | Map of volume attachments keyed by volume name and instance ID. |
| `attachments` | Details for the EBS volume attachments created by this module. |
| `volume_ids` | Map of EBS volume names to volume IDs. |
| `volume_arns` | Map of EBS volume names to volume ARNs. |
| `volumes` | Details for the EBS volumes created by this module. |
