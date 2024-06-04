include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  service   = read_terragrunt_config(find_in_parent_folders("service.hcl")).locals
  component = read_terragrunt_config(find_in_parent_folders("component.hcl")).locals
}

terraform {
  source = "tfr:///terraform-aws-modules/iam/aws//modules/iam-policy?version=5.39.1"
}

inputs = {
  name        = "${local.service.name}-${local.component.name}"
  path        = "/"
  description = "Policy for ${local.service.name} ${local.component.name} to reach aws resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListDeadLetterSourceQueues",
          "sqs:ListQueues"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${local.service.name}-${local.component.name}-irsa"
  }
}





