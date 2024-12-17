variable "instance_name" {
  description = "Name of the instance"
  default     = "goryunov_infra_tf"
}

variable "key_name" {
  description = "Name of the ssh key"
  default     = "goryunov"
}

variable "image" {
  description = "Image to use"
  default     = "ubuntu-20.04"
}

variable "flavor" {
  description = "Flavor of the instance"
  default     = "m1.small"
}

variable "network_name" {
  description = "Network to attach"
  default     = "sutdents-net"
}

variable "subnet_name" {
  description = "Subnet to attach"
  default     = "students-subnet"
}

variable "security_group" {
  description = "Security group to use"
  default     = "default"
}