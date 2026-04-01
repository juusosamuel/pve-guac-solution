locals {
  vm_profiles = {
    t1 = { cpu = 4, memory = 4096 }
  }
  selected_profile = local.vm_profiles[var.instance_type]

  # Luodaan lista tageista. compact() poistaa tyhjät merkkijonot ("").
  # 'base-research' lisätään aina oletuksena kaikille koneille.
  tag_list = compact([
    "base-research",
    var.install_rstudio ? "app-rstudio" : "",
    var.install_python ? "app-python" : ""
  ])

  # Yhdistetään lista yhdeksi pilkulla erotetuksi stringiksi Landscapea varten
  landscape_tags = join(",", local.tag_list)
}

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.vm_name
  node_name = "tfepve"
  started   = true

  agent { enabled = true }

  clone {
    vm_id = 100
  }

  cpu {
    cores = local.selected_profile.cpu
    type  = "host"
  }

  memory {
    dedicated = local.selected_profile.memory
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 70
    file_format  = "raw"
    discard      = "on"
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    ip_config {
      ipv4 { address = "dhcp" }
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }
}

resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "tfepve"

  source_raw {
    data = templatefile("${path.module}/cloud-init.tftpl", {
      hostname       = var.vm_name
      landscape_tags = local.landscape_tags
    })
    file_name = "cloud-config-${var.vm_name}.yaml"
  }
}

resource "guacamole_connection_group" "labra" {
  name              = "Labra-${var.vm_name}"
  parent_identifier = "ROOT"
  type              = "ORGANIZATIONAL"
}

resource "guacamole_connection_rdp" "rdp_yhteys" {
  name              = "RDP-${var.vm_name}"
  parent_identifier = guacamole_connection_group.labra.identifier

  parameters {
    hostname        = proxmox_virtual_environment_vm.this.ipv4_addresses[1][0]
    port            = "3389"
    username        = "ubuntu"
    password        = "Ubuntu"
    
    security_mode   = "any"
    ignore_cert     = true
    resize_method   = "display-update"
    color_depth     = "24"
  }
}
