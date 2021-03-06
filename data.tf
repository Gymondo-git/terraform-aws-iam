data "aws_iam_policy_document" "base_user_policy" {
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
      "iam:ListGroups",
      "iam:ListUsers"
    ]
    resources = [
      format("arn:aws:iam::%s:group/*", var.account_id),
      format("arn:aws:iam::%s:user/*", var.account_id),
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:DeactivateMFADevice",
      "iam:ListGroups",
      "iam:ListUsers",
      "iam:ListVirtualMFADevices",
      "iam:ListMFADevices",
      "iam:EnableMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:CreateAccessKey",
      "iam:DeleteAccessKey",
      "iam:ListAccessKeys",
      "iam:UploadSSHPublicKey",
      "iam:UpdateSSHPublicKey",
      "iam:ChangePassword"
    ]
    resources = [
      format("arn:aws:iam::%s:user/$${aws:username}", var.account_id),
      format("arn:aws:iam::%s:mfa/", var.account_id),
      format("arn:aws:iam::%s:mfa/$${aws:username}", var.account_id),
    ]
  }
}

data "aws_iam_policy_document" "assume_role_global_administrators" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = formatlist("arn:aws:iam::%s:role/%s", values(local.associated_accounts), "AccountAdministrator")
  }
}

data "aws_iam_policy_document" "assume_role" {
  for_each = local.assume_role_policies

  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      format("arn:aws:iam::%s:role/%s", each.value["account_id"], each.value["role"])
    ]
  }
}

data "aws_iam_policy_document" "user_role_policy" {
  for_each = local.user_role_policy_statements

  dynamic "statement" {
    for_each = each.value
    content {
      actions   = lookup(statement.value, "actions", [])
      effect    = lookup(statement.value, "effect", "Allow")
      resources = lookup(statement.value, "resources", ["*"])
      dynamic "condition" {
        for_each = lookup(statement.value, "conditions", [])
        content {
          test     = lookup(condition.value, "test")
          values   = lookup(condition.value, "values")
          variable = lookup(condition.value, "variable")
        }
      }
    }
  }
}
