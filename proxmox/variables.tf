variable "instance_type" {
  description = "VM size"
  type        = string
  default     = "t1"
}

variable "hostname" {
  description = "hostname to connect to"
  type        = string
  sensitive   = false
}

variable "proxmox_api_url" {
  type        = string
  description = "Proxmox API url"
  sensitive   = true
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Proxmox API Token ID"
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Proxmox API Token Secret"
  sensitive   = true
}