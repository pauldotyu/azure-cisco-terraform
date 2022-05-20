# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/features-block
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "random_pet" "p" {
  length    = 2
  separator = ""
}

locals {
  project_name   = format("%s%s", "", random_pet.p.id)
  location       = "westus3"
  admin_username = "azadmin"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.project_name}"
  location = local.location

  tags = {
    repo        = "pauldotyu/azure-cisco-terraform"
    environment = "demo"
  }
}

resource "azurerm_virtual_network" "vn" {
  name                = "vn-${local.project_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet_cidr]
}

resource "azurerm_subnet" "out" {
  name                 = "sn-${local.project_name}-out"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = [var.subnet_out_cidr]
}

resource "azurerm_subnet" "in" {
  name                 = "sn-${local.project_name}-in"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = [var.subnet_in_cidr]
}

resource "azurerm_subnet" "vm" {
  name                 = "sn-${local.project_name}-vm"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = [var.subnet_vm_cidr]
}

resource "azurerm_subnet" "bh" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = [var.subnet_bh_cidr]
}

resource "azurerm_network_security_group" "bh" {
  name                = "nsg-sn-${local.project_name}-bh"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowGatewayManager"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "GatewayManager"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "443"
  }

  security_rule {
    name                       = "AllowHttpsInBound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "443"
  }

  security_rule {
    name                       = "AllowSshRdpOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges    = ["22", "3389"]
  }

  security_rule {
    name                       = "AllowAzureCloudOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "AzureCloud"
    destination_port_range     = "443"
  }
}

resource "azurerm_subnet_network_security_group_association" "bh" {
  subnet_id                 = azurerm_subnet.bh.id
  network_security_group_id = azurerm_network_security_group.bh.id
}

resource "azurerm_public_ip" "bh" {
  name                = "bh-${local.project_name}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bh" {
  name                = "bh-${local.project_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bh.id
    public_ip_address_id = azurerm_public_ip.bh.id
  }
}

# Public IP for the CSR outside interface
resource "azurerm_public_ip" "out" {
  name                    = "vm${local.project_name}csr-pip"
  resource_group_name     = azurerm_resource_group.rg.name
  location                = azurerm_resource_group.rg.location
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}

# Outside interface
resource "azurerm_network_interface" "out" {
  name                 = "vm${local.project_name}csr-nic-out"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.out.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.55.0.4"
    public_ip_address_id          = azurerm_public_ip.out.id
  }
}

# Inside interface
resource "azurerm_network_interface" "in" {
  name                 = "vm${local.project_name}csr-nic-in"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.in.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.55.0.68"
  }
}

# Cisco CSR
resource "azurerm_linux_virtual_machine" "csr" {
  name                            = "vm${local.project_name}csr"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_D2_v2"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  # admin_ssh_key {
  #   username   = local.admin_username
  #   public_key = file("~/.ssh/id_rsa.pub")
  # }

  network_interface_ids = [
    azurerm_network_interface.out.id,
    azurerm_network_interface.in.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "cisco"
    offer     = "cisco-csr-1000v"
    sku       = "16_10-BYOL"
    version   = "16.10.220190622"
  }

  plan {
    publisher = "cisco"
    product   = "cisco-csr-1000v"
    name      = "16_10-byol"
  }
}

# Create a nic for the VM
resource "azurerm_network_interface" "vm" {
  name                = "vm${local.project_name}test-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.55.0.132"
  }
}

# Create the test VM
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "vm${local.project_name}test"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_B1s"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  # admin_ssh_key {
  #   username   = local.admin_username
  #   public_key = file("~/.ssh/id_rsa.pub")
  # }

  network_interface_ids = [
    azurerm_network_interface.vm.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Create a route table with routes to 10.44.0.0/16 network to pass through the NVA
resource "azurerm_route_table" "rt" {
  name                = "rt-${local.project_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name                   = "To-10-44"
    address_prefix         = "10.44.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.55.0.4"
  }
}

# Associate the route table with the compnet subnet
resource "azurerm_subnet_route_table_association" "rta" {
  subnet_id      = azurerm_subnet.vm.id
  route_table_id = azurerm_route_table.rt.id
}

resource "local_file" "csr_vwan" {
  filename = "csr-vwan.config"
  content = templatefile("csr-vwan.config.tmpl",
    {
      SUBNET_OUT            = split("/", var.subnet_out_cidr)[0],
      SUBNET_OUT_CIDR       = var.subnet_out_cidr,
      SUBNET_IN             = split("/", var.subnet_in_cidr)[0],
      SUBNET_IN_CIDR        = var.subnet_in_cidr,
      SUBNET_VM             = split("/", var.subnet_vm_cidr)[0],
      SUBNET_VM_CIDR        = var.subnet_vm_cidr,
      SUBNET_MASK           = var.subnet_mask,
      INSTANCE_0_PUBLIC_IP  = var.instance_0_public_ip,
      INSTANCE_1_PUBLIC_IP  = var.instance_1_public_ip,
      PRE_SHARED_KEY        = var.pre_shared_key,
      ROUTE_OUT_SUBNET      = var.route_out_subnet,
      ROUTE_OUT_SUBNET_MASK = var.route_out_subnet_mask,
      ROUTE_OUT_GATEWAY_IP  = var.route_out_gateway_ip,
    }
  )
}
