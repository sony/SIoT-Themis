variable "sys_name" {
  type        = string
  description = "Specify system name"
}

variable "env" {
  type        = string
  description = "Specify environment name"
}

variable "region" {
  type        = string
  description = "Specify the region to use"
}

variable "availability_zones" {
  type        = list(string)
  description = "Specify availability zones"
}

variable "vpc_id" {
  type        = string
  description = "Specify VPC ID"
}

variable "ami_id" {
  type        = string
  description = "Specify AWS AMI ID"
}

variable "instance_type" {
  type        = string
  description = "Specify instance type"
}

variable "subnet_id" {
  type        = string
  description = "Specify a subnet ID to be associated with EC2"
}

variable "allow_cidr_blocks" {
  type        = list(string)
  description = "Specify the CIDR range to be allowed in the security group"
}

variable "ssh_port_number" {
  type        = number
  description = "Specify SSH port number of IaC deployment server"
}

variable "volume_size" {
  type        = number
  description = "Specify volume size of IaC deployment server"
}

variable "volume_type" {
  type        = string
  description = "Specify the volume type of the IaC deployment server"
}

variable "volume_iops" {
  type        = string
  description = "Specify the IOPS of the IaC deployment server volume"
}

variable "volume_throughput" {
  type        = string
  description = "Specify the throughput of the volume for the IaC deployment server"
}

variable "public_key_content" {
  type        = string
  description = "Specify the content of the IaC deployment server public key"
}

variable "github_owner" {
  type        = string
  description = "GitHub repository owner/organization name"
}

variable "github_repos" {
  type        = string
  description = "A space-separated list of GitHub repository names to register the runner with"
}

variable "github_pat" {
  type        = string
  description = "GitHub Personal Access Token with runner registration permissions"
  sensitive   = true
}

variable "runner_tag_name" {
  type        = string
  description = "Tag name for GitHub self-hosted runners"
  default     = "ec2-iac-servicer"
}
