locals {
  base_tags = {
    account     = var.account_name
    environment = var.environment
    repo        = var.repo_name
  }

  sql_tags = {
    sql_cluster_name  = var.sql_cluster_name
    sql_instance_name = var.sql_instance_name
    sql_vnn           = var.sql_vnn
  }

  default_tags = merge(
    local.base_tags,
    { for key, value in local.sql_tags : key => value if value != null },
    var.tags,
  )

  single_volume = var.ebs_name == null ? [] : [
    {
      name                = var.ebs_name
      availability_zone   = var.ebs_availability_zone
      drive_letter        = var.ebs_drive_letter
      windows_description = var.ebs_windows_description
      shared              = var.ebs_shared
      type                = var.ebs_type
      iops                = var.ebs_iops
      size                = var.ebs_size
      tags                = {}
    }
  ]

  requested_volumes = length(var.ebs_volumes) > 0 ? var.ebs_volumes : local.single_volume

  volumes = {
    for volume in local.requested_volumes : volume.name => {
      name                = volume.name
      availability_zone   = volume.availability_zone
      drive_letter        = upper(volume.drive_letter)
      windows_description = volume.windows_description
      shared              = try(volume.shared, false)
      type                = lower(try(volume.type, "gp3"))
      iops                = try(volume.iops, 3000)
      size                = try(volume.size, 200)
      tags                = try(volume.tags, {})
    }
  }
}

resource "aws_ebs_volume" "this" {
  for_each = local.volumes

  availability_zone = each.value.availability_zone
  size              = each.value.size
  type              = each.value.type
  iops              = contains(["gp3", "io1", "io2"], each.value.type) ? each.value.iops : null

  multi_attach_enabled = each.value.shared

  lifecycle {
    precondition {
      condition     = can(regex("^[A-Z]$", each.value.drive_letter))
      error_message = "drive_letter must be a single alphabetic character."
    }

    precondition {
      condition     = each.value.windows_description != null && trimspace(each.value.windows_description) != ""
      error_message = "windows_description must not be empty."
    }

    precondition {
      condition     = each.value.availability_zone != null && trimspace(each.value.availability_zone) != ""
      error_message = "availability_zone must not be empty."
    }

    precondition {
      condition     = each.value.size > 0
      error_message = "size must be greater than zero."
    }

    precondition {
      condition     = each.value.iops > 0
      error_message = "iops must be greater than zero."
    }

    precondition {
      condition     = !each.value.shared || contains(["io1", "io2"], each.value.type)
      error_message = "Shared EBS volumes must use the io1 or io2 volume type."
    }
  }

  tags = merge(
    local.default_tags,
    each.value.tags,
    {
      Name                = each.value.name
      drive_letter        = each.value.drive_letter
      windows_description = each.value.windows_description
    },
  )
}
