terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.70" 
    }
    guacamole = {
      source  = "techBeck03/guacamole"
      version = "~> 1.4.0"
    }
  }
}

provider "proxmox" {
  ssh {
    agent = true
  }
}

provider "guacamole" {
  url                      = var.guacamole_url
  username                 = var.guacamole_username
  password                 = var.guacamole_password
  disable_tls_verification = true
}