# Org-level Terraform
#
# Provisions shared, account-wide resources that node deployments
# depend on (e.g. networking, base accounts, shared state).
#
# terraform {
#   required_providers {
#     <provider> = {
#       source  = "<source>"
#       version = "<version>"
#     }
#   }
# }
#
# provider "<provider>" {
#   # <config>
# }
#
# resource "<type>" "<name>" {
#   # <config>
# }
