#!/bin/bash
#
echo "-------------------------start configure-------------------------"
echo "1.Description: pxe install script"
echo "2.Version: v2.0"
echo "3.目前支持在centos7系统上安装。"
echo -e "4.目前支持安装的系统: \n  centos-x86_64\n  centos-aarch64\n  ctyunos-x86_64\n  ctyunos-aarch64"
echo
##########function definition##########
tftp_cfg(){
cat > /etc/xinetd.d/tftp << EOF
# default: off
# description: The tftp server serves files using the trivial file transfer \
#       protocol.  The tftp protocol is often used to boot diskless \
#       workstations, download configuration files to network-aware printers, \
#       and to start the installation process for some operating systems.
service tftp
{
        socket_type             = dgram
        protocol                = udp
        wait                    = no
        user                    = root
        server                  = /usr/sbin/in.tftpd
        server_args             = -s /var/lib/tftpboot
        disable                 = no
        per_source              = 11
        cps                     = 100 2
        flags                   = IPv4
}
EOF
}
#dhcpd.conf
dhcp_cfg(){
cat > /etc/dhcp/dhcpd.conf << EOF
# dhcpd.conf
option architecture-type code 93 = unsigned integer 16;

subnet 192.168.0.0 netmask 255.255.252.0 {
  option routers 192.168.3.254;
  range 192.168.0.1 192.168.3.253;
  next-server 192.168.3.254;

# Huawei Kunpeng 920 ARM64 aarch64 EFI BIOS
  class "HW-client" {
      match if substring (option vendor-class-identifier, 0, 9) = "HW-Client";
      if exists user-class and option user-class = "iPXE" {
        filename "ipxe/boot.ipxe";
      } elsif option architecture-type = 00:0b {
        filename "arm64-ipxe.efi";
      }
    }
  class "pxeclients" {
      match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
      if exists user-class and option user-class = "iPXE" {
        filename "ipxe/boot.ipxe";
      } elsif option architecture-type = 00:07 or option architecture-type = 00:09 {
        filename "ipxe.efi";
      } elsif  option architecture-type = 00:0b {
        filename "arm64-ipxe.efi";
      } else {
        filename "undionly.kpxe";
      }
  }
}
EOF
}
dhcp_netcard(){
cat > /etc/sysconfig/network-scripts/ifcfg-$LOCAL_IP << EOF
TYPE=Ethernet
BOOTPROTO=none
NAME=$LOCAL_IP
DEVICE=$LOCAL_IP
ONBOOT=yes
IPADDR=192.168.3.254
PREFIX=22
EOF
}
############begin install##############
USE_IP=192.168.3.254
if [ "$1" == "pxe-all.tar.gz" ]
then
  break
else
  echo "Usage: sh 1-install.sh pxe-all.tar.gz"
  echo
  exit 1
fi
echo "开始安装..."
echo "开始配置DHCP服务..."
ip ad | grep -E "^[0-9]:" | grep -v lo | awk -F" " '{print $2}' | sed 's/://g'
read -p "输入提供dhcp服务的网卡名称: " LOCAL_IP
if [ -n "$LOCAL_IP" ]
then
  cp /etc/sysconfig/network-scripts/ifcfg-$LOCAL_IP /etc/sysconfig/network-scripts/ifcfg-$LOCAL_IP.bak
  dhcp_netcard
else
  echo "输入正确的网卡名称"
  exit 1
fi

tar zxvf $PWD/pxe-all.tar.gz
tar zxvf $PWD/pxe-all/pxe-repo.tar.gz -C /tmp/
mkdir -p $PWD/reposbak
mv /etc/yum.repos.d/* $PWD/reposbak
cat > /etc/yum.repos.d/myrepo.repo << EOF
[myrepo]
name=pxe_repo
baseurl=file:///tmp/pxe-repo/packages/
gpgcheck=0
enabled=1
EOF
yum repolist
yum install -y tftp-server dhcp httpd xinetd wget ansible ipmitool net-snmp-utils createrepo

tftp_cfg
dhcp_cfg

mkdir -p /var/lib/tftpboot/ipxe
> /etc/nets
cp -rf $PWD/pxe-all/ipxe/{undionly.kpxe,ipxe.efi,arm64-ipxe.efi} /var/lib/tftpboot
cp -rf $PWD/pxe-all/ipxe/{example.ipxe,boot.ipxe} /var/lib/tftpboot/ipxe/
chmod +rx /var/lib/tftpboot/ -R

mkdir -p /var/www/html/{repos,kickstart,other}
mkdir -p /var/www/html/repos/{x86_64,aarch64}
sed -i 's/^#\(ServerName\)/\1/' /etc/httpd/conf/httpd.conf

#other
cp -rf $PWD/pxe-all/other/*  /var/www/html/other/
sed -i "s/\(^PXE_SERVER=\).*/\1$USE_IP/" /var/www/html/other/init_ip.sh

#kickstart
cp -rf $PWD/pxe-all/kickstart/* /var/www/html/kickstart/
sed -i "s/\(url=\).*/\1\"http:\/\/$USE_IP\/repos\/x86_64\/centos-7.6\"/" /var/www/html/kickstart/centos-7.6.ks
sed -i "s/\(url=\).*/\1\"http:\/\/$USE_IP\/repos\/x86_64\/ctyunos-62\"/" /var/www/html/kickstart/ctyunos-62.ks
sed -i "s/\(url=\).*/\1\"http:\/\/$USE_IP\/repos\/x86_64\/ctyunos-64\"/" /var/www/html/kickstart/ctyunos-64.ks
sed -i "s/\(curl \).*/\1http:\/\/$USE_IP\/other\/init_ip.sh | bash/" /var/www/html/kickstart/centos-7.6.ks
sed -i "s/\(curl \).*/\1http:\/\/$USE_IP\/other\/init_ip.sh | bash/" /var/www/html/kickstart/ctyunos-62.ks
sed -i "s/\(curl \).*/\1http:\/\/$USE_IP\/other\/init_ip.sh | bash/" /var/www/html/kickstart/ctyunos-64.ks
sed -i "s/\(--source=\).*/\1\"http:\/\/$USE_IP\/other\/dd.iso\"/" /var/www/html/kickstart/centos-7.6.ks
sed -i "s/\(--source=\).*/\1\"http:\/\/$USE_IP\/other\/dd.iso\"/" /var/www/html/kickstart/ctyunos-62.ks
sed -i "s/\(--source=\).*/\1\"http:\/\/$USE_IP\/other\/dd.iso\"/" /var/www/html/kickstart/ctyunos-64.ks

#services
setenforce 0
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
systemctl stop firewalld
systemctl disable firewalld
systemctl restart network
systemctl daemon-reload
systemctl enable xinetd tftp httpd dhcpd
systemctl restart xinetd tftp httpd
systemctl restart dhcpd
if [ $? -eq 0 ]; then
    echo "dhcp service is running" > /dev/null
else
    echo "please check dhcp service"
    rm -rf $PWD/pxe-all/
    rm -rf /etc/yum.repos.d/myrepo.repo
    cp -rf $PWD/reposbak/* /etc/yum.repos.d/
    rm -rf $PWD/reposbak
    rm -rf /tmp/pxe-repo
    exit 1
fi
#end install
echo "The installation is complete!"
echo "默认dhcp范围192.168.0.1-192.168.3.253,IP地址默认为192.168.3.254/22.如更改请自行更改dnsmasq配置文件与网卡"
echo "接下来按步骤操作:"
echo "1. Please upload system iso file"
echo "2. Please upload kickstart file to /var/www/html/kickstart/"
echo "3. Please sh 2-upload.sh"
echo "4. Please sh 3-template.sh"

#delete tmp file
rm -rf $PWD/pxe-all
rm -rf /etc/yum.repos.d/myrepo.repo
cp -rf $PWD/reposbak/* /etc/yum.repos.d/
rm -rf $PWD/reposbak
rm -rf /tmp/pxe-repo
echo "-----------------------configured successfully-------------------"
