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

  default_attachment_instance_ids = distinct(compact(concat(
    var.ebs_instance_ids,
    var.ebs_instance_id == null ? [] : [var.ebs_instance_id],
  )))

  single_volume = var.ebs_name == null ? [] : [
    {
      name                = var.ebs_name
      availability_zone   = var.ebs_availability_zone
      drive_letter        = var.ebs_drive_letter
      windows_description = var.ebs_windows_description
      device_name         = var.ebs_device_name
      instance_id         = var.ebs_instance_id
      instance_ids        = local.default_attachment_instance_ids
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
      device_name         = try(volume.device_name, null)
      instance_ids = distinct(compact(concat(
        length(try(volume.instance_ids, [])) > 0 ? try(volume.instance_ids, []) : local.default_attachment_instance_ids,
        try(volume.instance_id, null) == null ? [] : [try(volume.instance_id, null)],
      )))
      shared = try(volume.shared, false)
      type   = lower(try(volume.type, "gp3"))
      iops   = try(volume.iops, 3000)
      size   = try(volume.size, 200)
      tags   = try(volume.tags, {})
    }
  }

  attachment_entries = flatten([
    for volume_name, volume in local.volumes : [
      for instance_id in volume.instance_ids : {
        key         = "${volume_name}:${instance_id}"
        volume_name = volume_name
        device_name = volume.device_name
        instance_id = instance_id
      }
    ]
  ])

  attachments = {
    for entry in local.attachment_entries : entry.key => entry
    if entry.device_name != null && trimspace(entry.device_name) != ""
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
      condition     = length(each.value.instance_ids) == 0 || (each.value.device_name != null && trimspace(each.value.device_name) != "")
      error_message = "device_name must be provided when attaching a volume to one or more instances."
    }

    precondition {
      condition     = alltrue([for instance_id in each.value.instance_ids : trimspace(instance_id) != ""])
      error_message = "instance_ids must not contain empty values."
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

    precondition {
      condition     = length(each.value.instance_ids) <= 1 || each.value.shared
      error_message = "Volumes attached to multiple instances must set shared = true."
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

resource "aws_volume_attachment" "this" {
  for_each = local.attachments

  device_name = each.value.device_name
  instance_id = each.value.instance_id
  volume_id   = aws_ebs_volume.this[each.value.volume_name].id
}
