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
