#!/bin/bash
system="$1"
arch="$2"
version="$3"
iso="$4"

system_repo_path="/var/www/html/repos/$arch"

if [[ -z "$system" || "$system" == "-h" || -z "$version" ]];then
    echo "Usage:        sh delete.sh system arch version"
    echo "system:       centos|ctyunos|UOS"
    echo "arch:         x86_64|aarch64"
    echo "version:      7.6|0062"
    echo "############example###############"
    echo "sh delete.sh centos x86_64 7.6"
    exit 1
else
    rm -rf $system_repo_path/$system-$version
    echo "$system-$arch-$version is deleted!"
fi
exit
