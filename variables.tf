variable "region" {
  description = "The AWS region to use for this demo."
  type        = string
  default     = "us-west-2"
}

variable "azs" {
  description = "Availability zones to deploy VCS subnets."
  type        = list(string)
  default     = ["a", "b"]
}

variable "cidr" {
  type        = string
  description = "CIDR block to associate with the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  type        = list(string)
  description = "Define only if the subnet cannot be autocalculated or if the number of subnets needed is different from the number of azs"
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "sg_ingress_ports" {
  type        = list(string)
  description = "List of allowed ingress ports to access the public-facing instance"
  default     = ["22", "80", "443", "8080", "8084"]
}