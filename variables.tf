variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"

}

variable "environment" {
  type        = string
  description = "Environment"
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.0.0.0/16"
}

variable "name" {
  type        = string
  description = "Name"
  default     = "myapp"

}
