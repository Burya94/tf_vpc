output "vpc_id" {
    value = "${aws_vpc.vpc.id}"
}
output "vpc_igw_id" {
    value = "${aws_internet_gateway.vpc_igw.id}"
}
output "pub_sn_ids" {
    value = ["${aws_subnet.pub_sn.*.id}"]
}
output "priv_sn_ids" {
    value = ["${aws_subnet.priv_sn.*.id}"]
}
output "vpc_def_rt_id" {
    value = "${aws_default_route_table.vpc_def_rt.id}"
}
output "pub_sn_azs" {
    value = ["${aws_subnet.pub_sn.*.availability_zone}"]
}
output "res_nameprefix" {
    value = "${var.res_nameprefix}"
}
output "env" {
    value = "${var.env}"
}
output "region" {
    value = "${var.region}"
}
output "vpc_netmask" {
    value = "${var.vpc_netmask}"
}
output "vpc_netnumber" {
    value = "${var.vpc_netnumber}"
}
output "vpc_netprefix" {
    value = "${var.vpc_netprefix}"
}
output "pub_sn_netnumber" {
    value = "${var.pub_sn_netnumber}"
}
output "pub_sn_netmask" {
    value = "${var.pub_sn_netmask}"
}
output "priv_sn_azs" {
    value = ["${aws_subnet.priv_sn.*.availability_zone}"]
  }
