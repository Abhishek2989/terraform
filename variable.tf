##variables.tf 

variable "region" {
      default = "us-east-1"
 }


variable "cidr" {
   default = "10.0.0.0/16"
}

variable "subnet_dev" {
    default = "10.0.1.0/24"

}

variable "subnet_prod" {
    default = "10.0.2.0/24"

}

variable "zone1" {
    description = "availability zone1"
    default = "us-east-1a"
}
variable "zone2" {
    description = "availability zone2"
    default = "us-east-1b"
}

variable "keyname" {
    description = "key name"
    default = "web-key"
}
variable "ami_id1" {
    description = "ami id for amazon web server"
    default = "ami-0c007898ce5ad0542"

}
variable "ami_id2" {
    description = "ami id for amazon web server"
    default = "ami-01b2f3429fe549410"

}

variable "instance_type" {
    description = "choose instance type"
    default = "t2.medium"
}



