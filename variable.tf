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
variable "ami_id" {
    description = "ami id for amazon web server"
    default = "ami-0e472ba40eb589f49"

}


variable "Sonarqube_Nexus" {
    description = "choose instance type"
    default = "t3a.medium"
}
variable "Application" {
    description = "choose instance type"
    default = "t2.micro"
}



