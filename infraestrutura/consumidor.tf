# --- VM CONSUMIDOR R ---

resource "libvirt_volume" "os_image_consumidor" {
  name   = "vm-consumidor-r-disk"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
  format = "qcow2"
}

# Recurso para redimensionar o disco automaticamente no host logo após a criação
resource "null_resource" "resize_disk_consumidor" {
  depends_on = [libvirt_volume.os_image_consumidor]

  provisioner "local-exec" {
    command = "sudo qemu-img resize /var/lib/libvirt/images/vm-consumidor-r-disk +18G"
  }
}

resource "libvirt_domain" "vm_consumidor" {
  name   = "vm-consumidor-r"
  memory = var.memory_mb
  vcpu   = var.vcpu

  # Garante que a VM só inicia após o disco estar redimensionado no host
  depends_on = [null_resource.resize_disk_consumidor]

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.os_image_consumidor.id
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

output "vm_consumidor_ip" {
  value       = libvirt_domain.vm_consumidor.network_interface[0].addresses[0]
  description = "Endereço IP atribuído à VM Consumidor R"
}