variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "res_nameprefix" {}
variable "env" {
    default = "prod"
}
variable "region" {
    default = "us-east-1"
}
variable "number_of_azs" {
    default = "3"
}
variable "vpc_namesuffix" {
    default = "-vpc"
}
variable "vpc_netmask" {
    default = "16"
}
variable "vpc_netnumber" {
    default = "0.0"
}
variable "vpc_netprefix" {
    default = "10.231"
}
variable "vpc_igw_namesuffix" {
    default = "-vpc-gw"
}
variable "vpc_def_rt_namesuffix" {
    default = "-vpc-def-rt"
}
variable "pub_sn_namesuffix" {
    default = "-vpc-pub-sn"
}
variable "pub_sn_netnumber" {
    default = "23"
}
variable "pub_sn_netmask" {
    default = "24"
}
variable "priv_sn_namesuffix" {
  default = "-vpc-priv-sn"
}
variable "priv_sn_netnumber" {}
variable "priv_sn_netmask" {}
