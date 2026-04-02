locals {
  vm_profiles = {
    t1 = { cpu = 4, memory = 4096 }
  }
  selected_profile = local.vm_profiles[var.instance_type]

}

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.vm_name
  node_name = "pve"
  started   = true

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
    size         = "20G"
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
  node_name    = "pve"

  source_raw {
    data = templatefile("${path.module}/cloud-init.tftpl", {
      hostname       = var.vm_name
      landscape_tags = local.landscape_tags
    })
    file_name = "cloud-config-${var.vm_name}.yaml"
  }
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

resource "xenserver_vm" "this" {
  name_label       = "${var.vm_name}-${var.instance_type}"
  name_description = "Terraform provision VM"
  template_name    = local.selected_profile.base_image
  static_mem_max   = local.selected_profile.memory * 1024 * 1024 * 1024
  vcpus            = local.selected_profile.cpu
  cores_per_socket = local.selected_profile.cpu
  check_ip_timeout = 300
  boot_mode        = local.selected_profile.boot_mode
  cdrom = null 

  network_interface {
    network_uuid = data.xenserver_network.network.data_items[0].uuid
    device       = "0"
  }

  other_config = {
    "tf_created" = "true",
  }
}

