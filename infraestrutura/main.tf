terraform {
  required_version = ">= 1.6.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

#configuracao do cloud init 
resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  user_data = file("${path.module}/cloud_init.cfg")
}

#volume do SO (Ubuntu 22.04 / 26.04 Cloud Image)
resource "libvirt_volume" "os_image" {
  name   = "${var.vm_name}-disk"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
  format = "qcow2"				
}

#definindo a vm
resource "libvirt_domain" "vm_gerador" {
  name   = var.vm_name
  memory = var.memory_mb
  vcpu   = var.vcpu

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.os_image.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

output "vm_gerador_ip" {
  value       = try(libvirt_domain.vm_gerador.network_interface[0].addresses[0], "VM desligada ou sem IP atribuído")
  description = "Endereço IP atribuído à VM Gerador"
}
