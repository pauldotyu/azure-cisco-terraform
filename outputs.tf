output "public_ip" {
  value = azurerm_public_ip.out.ip_address
}

output "csr_config" {
  value = local_file.csr_vwan.content
  sensitive = true
}