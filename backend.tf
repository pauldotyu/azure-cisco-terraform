terraform {
  cloud {
    organization = "pauldotyu"

    workspaces {
      name = "azure-cisco-terraform"
    }
  }
}