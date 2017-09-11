provider "aws" {
    region     = "${var.region}"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}

resource "aws_vpc" "vpc" {
    cidr_block       = "${var.vpc_netprefix}.${var.vpc_netnumber}/${var.vpc_netmask}"
    enable_dns_hostnames = true
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
    count             = "${var.number_of_azs}"
    vpc_id            = "${aws_vpc.vpc.id}"
    availability_zone = "${element(aws_subnet.pub_sn.*.availability_zone, count.index)}"
    cidr_block        = "${var.vpc_netprefix}.${var.priv_sn_netnumber}${count.index}.0/${var.priv_sn_netmask}"
    depends_on        = ["aws_subnet.pub_sn"]
    tags {
        Name = "${var.res_nameprefix}${var.env}${var.priv_sn_namesuffix}${count.index}"
    }
}
#"------------------------------------------------------------------------------- NAT"
data "template_file" "userdata" {
  template = "${file("${path.module}/${var.path_to_file}")}"

  vars {
    dns_name = "puppet"
    env      = "${var.env}"
    puppet_ip   = "${var.vpc_netprefix}.${var.priv_sn_netnumber}0.${var.puppet_addr}"
  }
}

resource "aws_instance" "nat_instance" {
    count                       = "${var.number_of_azs}"
    ami                         = "${var.nat_instance_ami}"
    instance_type               = "${var.nat_instance_type}"
    key_name                    = "${var.instance_key_name}"
    availability_zone           = "${element(aws_subnet.pub_sn.*.availability_zone, count.index)}"
    subnet_id                   = "${element(aws_subnet.pub_sn.*.id, count.index)}"
    vpc_security_group_ids      = ["${element(aws_security_group.nat_inst_sg.*.id, count.index)}"]
    associate_public_ip_address = true
    private_ip                  = "${var.vpc_netprefix}.${var.pub_sn_netnumber}${count.index}.${var.nat_instance_addr}"
    vpc_security_group_ids      = ["${aws_security_group.nat_inst_sg.*.id[count.index]}"]
    user_data                   = "${data.template_file.userdata.rendered}"
    source_dest_check           = false
    depends_on                  = ["aws_security_group.nat_inst_sg"]
    tags {
        Name = "${var.res_nameprefix}${var.env}${var.nat_instance_namesuffix}${count.index}"
    }
}

resource "aws_route_table" "priv_sn_rt" {
    count  = "${var.number_of_azs}"
    vpc_id = "${aws_vpc.vpc.id}"
    depends_on = ["aws_instance.nat_instance"]
    route {
        cidr_block     = "0.0.0.0/0"
        instance_id = "${aws_instance.nat_instance.*.id[count.index]}"
    }

    tags {
        Name = "${var.res_nameprefix}${var.env}${var.priv_sn_rt_namesuffix}${count.index}"
    }
}

resource "aws_route_table_association" "rt_pub_sn_assoc" {
    count          = "${var.number_of_azs}"
    subnet_id      = "${aws_subnet.pub_sn.*.id[count.index]}"
    route_table_id = "${aws_vpc.vpc.default_route_table_id}"
    depends_on     = ["aws_default_route_table.vpc_def_rt"]
}

resource "aws_main_route_table_association" "main_rt" {
  vpc_id         = "${aws_vpc.vpc.id}"
  route_table_id = "${aws_route_table.priv_sn_rt.id}"
}

resource "aws_security_group" "nat_inst_sg" {
    count  = "${var.number_of_azs}"
    name   = "${var.res_nameprefix}${var.env}${var.nat_inst_sg_namesuffix}${count.index}"
    vpc_id = "${aws_vpc.vpc.id}"
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["${var.vpc_netprefix}.${var.priv_sn_netnumber}${count.index}.0/${var.priv_sn_netmask}"]
    }

    ingress {
      from_port    = 8140
      to_port      = 8140
      protocol     = "tcp"
      cidr_blocks   = ["${var.vpc_netprefix}.${var.priv_sn_netnumber}${count.index}.0/${var.priv_sn_netmask}"]
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["${var.vpc_netprefix}.${var.priv_sn_netnumber}${count.index}.0/${var.priv_sn_netmask}"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["${var.vpc_netprefix}.${var.priv_sn_netnumber}${count.index}.0/${var.priv_sn_netmask}"]
    }

    tags {
        Name = "${var.res_nameprefix}${var.env}${var.nat_inst_sg_namesuffix}${count.index}"
    }
}
