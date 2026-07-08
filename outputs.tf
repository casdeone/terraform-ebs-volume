output "volume_ids" {
  description = "Map of EBS volume names to volume IDs."
  value       = { for name, volume in aws_ebs_volume.this : name => volume.id }
}

output "volume_arns" {
  description = "Map of EBS volume names to volume ARNs."
  value       = { for name, volume in aws_ebs_volume.this : name => volume.arn }
}

output "volumes" {
  description = "Details for the EBS volumes created by this module."
  value = {
    for name, volume in aws_ebs_volume.this : name => {
      id                = volume.id
      arn               = volume.arn
      availability_zone = volume.availability_zone
      type              = volume.type
      size              = volume.size
      iops              = volume.iops
      tags              = volume.tags
    }
  }
}

output "attachment_ids" {
  description = "Map of volume attachments keyed by volume name and instance ID."
  value       = { for name, attachment in aws_volume_attachment.this : name => attachment.id }
}

output "attachments" {
  description = "Details for the EBS volume attachments created by this module."
  value = {
    for name, attachment in aws_volume_attachment.this : name => {
      id          = attachment.id
      device_name = attachment.device_name
      instance_id = attachment.instance_id
      volume_id   = attachment.volume_id
    }
  }
}
