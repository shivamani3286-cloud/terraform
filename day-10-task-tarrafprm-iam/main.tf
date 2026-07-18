#creation of iam role, group, and policies using Terraform and validate access permissions
resource "aws_iam_role" "shiva-1" {
   description = "neww"
   name        = "shiva-1"
   assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Principal": {
            "Service": "ec2.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
      }
   ]
}
EOF
}

#creation of iam_group
resource "aws_iam_group" "shiva-iam-group" {
    name = "shiva-iam-group"
    path = "/"
}

#attachment of iam-user to group
resource "aws_iam_user_group_membership" "shiva" {
   user = aws_iam_user.shiva.name

   groups = [
      aws_iam_group.shiva-iam-group.name
   ]
}

# IAM user for membership
resource "aws_iam_user" "shiva" {
   name = "shiva-terraform"
   path = "/"
}
