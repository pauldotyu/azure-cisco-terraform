terraform {
  cloud {
    organization = "contosouniversity"

    workspaces {
      name = "azure-cisco-terraform"
    }
  }
}