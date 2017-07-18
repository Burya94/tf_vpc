#!/bin/bash
rpm -Uvh https://yum.puppetlabs.com/el/5Client/PC1/x86_64/puppet-agent-1.9.3-1.el5.x86_64.rpm
yum -y install puppet
cat >> /etc/puppetlabs/puppet/puppet.conf << EOF
[main]
server = ${dns_name}
environment = ${env}
EOF
cat >> /etc/hosts << EOF
${puppet_ip} ${dns_name}
EOF
service puppet start
