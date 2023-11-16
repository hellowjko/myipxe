#!/bin/bash
#
upload(){
umount /tmp_iso 2> /dev/null
mount $iso /tmp_iso
mkdir -p /var/www/html/repos/$arch/$system-$version > /dev/null
/bin/cp -af /tmp_iso/. /var/www/html/repos/$arch/$system-$version/
}

iso_exists(){
if [ -f $iso ];then
    echo "$iso exists" > /dev/null
else
    echo "$iso file is not exists,please upload $iso file!"
    exit 1
fi
}
########begin configure########
mkdir /tmp_iso 2> /dev/null
system="$1"
arch="$2"
version="$3"
iso="$4"
if [[ -z "$system" || "$system" == "-h" || -z "$iso" ]];then
    echo "Usage:        sh 2-upload.sh system arch version iso_file"
    echo "system:       centos|ctyunos|UOS..."
    echo "arch:         x86_64|aarch64"
    echo "version:      7.6|62|64..."
    echo "iso_file:     iso file name"
    echo "############example###############"
    echo "sh 2-upload.sh centos x86_64 7.6 CentOS-7-x86_64-Minimal-1810.iso"
    exit 1
else
    iso_exists
    upload
fi
chmod +rx /var/www/html/repos/* -R
umount /tmp_iso 2> /dev/null
echo "$iso is uploaded!"


#sh template.sh
