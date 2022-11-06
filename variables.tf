variable "region" {
  default = "eu-central-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "project_name" {
   description = "Prefix used for all resources names"
   default = "tProject"
}

variable "public_prefix" {
   type = map
   default = {
      sub-1 = {
         az = "eu-central-1a"
         cidr = "10.0.1.0/24"
      }
      sub-2 = {
         az = "eu-central-1b"
         cidr = "10.0.2.0/24"
      }
      sub-3 = {
         az = "eu-central-1c"
         cidr = "10.0.3.0/24"
      }
   }
}

variable "private_prefix" {
   type = map
   default = {
      sub-1 = {
         az = "eu-central-1a"
         cidr = "10.0.4.0/24"
      }
      sub-2 = {
         az = "eu-central-1b"
         cidr = "10.0.5.0/24"
      }
      sub-3 = {
         az = "eu-central-1c"
         cidr = "10.0.6.0/24"
      }
   }
}

variable "ssh_key_name" {}

variable "private_key_path" {}