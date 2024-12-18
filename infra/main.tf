terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = "1.51.1"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
}

provider "openstack" {
  auth_url    = var.openstack_auth_url
  user_name   = var.openstack_username
  password    = var.openstack_password
  domain_name = var.openstack_domain_name
}

resource "openstack_compute_instance_v2" "goryunov_infra_tf" {
  name        = var.instance_name
  image_name  = var.image
  flavor_name = var.flavor
  key_pair    = var.key_name

  network {
    name = var.network_name
  }

  security_groups = [var.security_group]
}

output "instance_ip" { value = openstack_compute_instance_v2.goryunov_infra_tf.access_ip_v4 }