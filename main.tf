provider "aws" {
    region     = "${var.region}"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}

resource "aws_vpc" "vpc" {
    cidr_block       = "${var.vpc_netprefix}.${var.vpc_netnumber}/${var.vpc_netmask}"

    tags {
        Name = "${var.res_nameprefix}${var.env}${var.vpc_namesuffix}"
    }
}

resource "aws_internet_gateway" "vpc_igw" {
    vpc_id     = "${aws_vpc.vpc.id}"
    depends_on = ["aws_vpc.vpc"]

    tags {
        Name = "${var.res_nameprefix}${var.env}${var.vpc_igw_namesuffix}"
    }
}

resource "aws_default_route_table" "vpc_def_rt" {
    default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.vpc_igw.id}"
    }
    depends_on             = ["aws_vpc.vpc","aws_internet_gateway.vpc_igw"]

    tags {
        Name = "${var.res_nameprefix}${var.env}${var.vpc_def_rt_namesuffix}"
    }
}

data "aws_availability_zones" "az_available" {}

resource "aws_subnet" "pub_sn" {
    count             = "${var.number_of_azs}"
    vpc_id            = "${aws_vpc.vpc.id}"
    depends_on        = ["aws_vpc.vpc"]
    availability_zone = "${data.aws_availability_zones.az_available.names[count.index]}"
    cidr_block        = "${var.vpc_netprefix}.${var.pub_sn_netnumber}${count.index}.0/${var.pub_sn_netmask}"

    tags {
        Name = "${var.res_nameprefix}${var.env}${var.pub_sn_namesuffix}${count.index}"
    }
}

resource "aws_subnet" "priv_sn" {
    count             = "${length(aws_subnet.pub_sn.*.id)}"
    vpc_id            = "${aws_vpc.vpc.id}"
    availability_zone = "${element(aws_subnet.pub_sn.*.availability_zone, count.index)}"
    cidr_block        = "${var.vpc_netprefix}.${var.priv_sn_netnumber}${count.index}.0/${var.priv_sn_netmask}"
    depends_on        = ["aws_subnet.pub_sn"]
    tags {
        Name = "${var.res_nameprefix}${var.env}${var.priv_sn_namesuffix}${count.index}"
    }
}
