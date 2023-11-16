#!/bin/bash
#
dhcp_fixed_ip(){
cat >> /tmp/dhcp.tmp << EOF 
host ${hostname} {
    hardware ethernet ${host_mac};
    fixed-address ${host_ip};
}
EOF
}
example_sn_ipxe(){
cat > /tmp/${serial_str}.ipxe << EOF
#!ipxe
kernel http://${local_ip}/repos/${arch}/${system}-${version}/images/pxeboot/vmlinuz repo=http://${local_ip}/repos/${arch}/${system}-${version} inst.ks=http://${local_ip}/kickstart/${ks_name} initrd=initrd.img
initrd http://${local_ip}/repos/${arch}/${system}-${version}/images/pxeboot/initrd.img 
boot
EOF
/bin/cp -rf /tmp/${serial_str}.ipxe /var/lib/tftpboot/ipxe/
rm -rf /tmp/${serial_str}.ipxe

sed -i 's/^#chain ${serial}.ipxe/chain ${serial}.ipxe/g' /var/lib/tftpboot/ipxe/boot.ipxe
sed -i 's/^chain ${net0\/mac:hexhyp}.ipxe/#chain ${net0\/mac:hexhyp}.ipxe/g' /var/lib/tftpboot/ipxe/boot.ipxe

echo -e "${ipmi}\t${serial_str:-none}\t${system}-${arch}-${version}\t${ks_name:-none}\t${host_ip:-none}"
}
example_mac_ipxe(){
cat > /tmp/${ipxe_mac}.ipxe << EOF
#!ipxe
kernel http://${local_ip}/repos/${arch}/${system}-${version}/images/pxeboot/vmlinuz inst.repo=http://${local_ip}/repos/${arch}/${system}-${version} inst.ks=http://${local_ip}/kickstart/${ks_name} initrd=initrd.img
initrd http://${local_ip}/repos/${arch}/${system}-${version}/images/pxeboot/initrd.img
boot
EOF
/bin/cp -rf /tmp/${ipxe_mac}.ipxe /var/lib/tftpboot/ipxe/
rm -rf /tmp/${ipxe_mac}.ipxe

sed -i 's/^chain ${serial}.ipxe/#chain ${serial}.ipxe/g' /var/lib/tftpboot/ipxe/boot.ipxe
sed -i 's/^#chain ${net0\/mac:hexhyp}.ipxe/chain ${net0\/mac:hexhyp}.ipxe/g' /var/lib/tftpboot/ipxe/boot.ipxe

echo -e "${ipmi}\t${ipxe_mac:-none}\t${system}-${arch}-${version}\t${ks_name:-none}\t${host_ip:-none}"
}

#########begin configure###########
file=${PWD}/macinfo.csv
if [ -f ${file} ]
then
  tr -d "\r" < ${file} > /tmp/tmp_macinfo.csv
  /bin/cp -f ${file} /var/www/html/other/
else
  echo "please upload macinfo.csv"
  exit 1
fi

echo "#############start configure#############"
ipxe_num=$(ls /var/lib/tftpboot/ipxe | grep -Ev "boot.ipxe|example.ipxe"|wc -l)
if [ ${ipxe_num} -eq 0 ]; then
    echo "file not exist" > /dev/null
else
    find /var/lib/tftpboot/ipxe -name "*.ipxe"|grep -wv "boot.ipxe"|grep -wv "example.ipxe"|xargs rm -rf
fi
read -p "input localhost dhcp ip address(default is 192.168.3.254): " local_ip
read -p "how  to create an ipxe file([sn/mac] default is [sn]): " way
if [ -z "${way}" ]; then
    way="sn"
elif [ "${way}" == "sn" ]; then
    echo "The ipxe file will be created using the sn!"
elif [ "${way}" == "mac" ]; then
    echo "The ipxe file will be created using the mac!"
else
    echo "Error,${way} is no support!"
    exit 1
fi
if [ -n "${local_ip}" ]
then
    echo "localhost ip address is ${local_ip}"
else
    local_ip=192.168.3.254
    echo "default ip address is ${local_ip}"
fi
ip add | grep "${local_ip}" > /dev/null
if [ $? = 0 ];then
    netcard=$(ip add|grep ${local_ip}|awk '{print $NF}')
    echo "${local_ip} on ${netcard}"
    echo
else
    echo
    echo "Error,${local_ip} is not exists,please check!"
    exit 1
fi
> /etc/nets
for LINE in $(cat /tmp/tmp_macinfo.csv | sed '1d'); do
    ipmi=$(echo "${LINE}" | awk -F, '{print $1}')
    serial=$(echo "${LINE}" | awk -F, '{print $2}')
    serial_str="${serial}"

    tmp_host_mac=`echo "${LINE}" | awk -F, '{print $3}'`
    host_mac=`echo ${tmp_host_mac,,}`
    ipxe_mac=$(echo "${host_mac}"|sed 's/:/-/g')

    hostname=$(echo "${LINE}" | awk -F, '{print $5}')
    system=$(echo "${LINE}" | awk -F, '{print $6}')
    arch=$(echo "${LINE}" | awk -F, '{print $7}')
    version=$(echo "${LINE}" | awk -F, '{print $8}')
    ks_name=$(echo "${LINE}" | awk -F, '{print $9}')
    host_ip=$(echo "${LINE}" | awk -F, '{print $10}')

    sys_repo_path="/var/www/html/repos/${arch}/${system}-${version}"
    ks_path="/var/www/html/kickstart/${ks_name}"
    if [ -d ${sys_repo_path} ] && [ -f ${ks_path} ]; then
        sed -i "s/\(url=\).*/\1\"http:\/\/${local_ip}\/repos\/${arch}\/${system}-${version}\"/" ${ks_path}
        sed -i "s/\(--source=\).*/\1\"http:\/\/${local_ip}\/other\/dd.iso\"/" ${ks_path}
        sed -i "s/\(curl \).*/\1http:\/\/${local_ip}\/other\/init_ip.sh | bash/" ${ks_path}
        dhcp_fixed_ip
        if [ "${way}" == "sn" ]; then
            if [ -z "${serial}" ]; then
                echo "Serial is empty" > /dev/null
                continue
            else
                example_sn_ipxe

            fi
        elif [ "${way}" == "mac" ]; then
            if [ -z "${host_mac}" ]; then
                echo "Mac address is empty" > /dev/null
                continue
            else
                example_mac_ipxe
                sed -i 's/^WAY=sn/WAY=mac/g' /var/www/html/other/init_ip.sh
            fi
        else
            echo "${way} no support!"
            exit 1
        fi
    elif [ -d ${sys_repo_path} ] || [ -f ${ks_path} ]; then
        echo "Error,${ks_path} or ${sys_repo_path} is not exists!"
        exit 1
    else
        echo "Error,${sys_repo_path} and ${ks_path} is not exists!"
        exit 1
    fi
done
sed -i '1,38!d' /etc/dhcp/dhcpd.conf
cat /tmp/dhcp.tmp >> /etc/dhcp/dhcpd.conf
rm -rf /tmp/dhcp.tmp

systemctl restart dhcpd

chmod +rx /var/www/html/* -R
chmod +rx /var/lib/tftpboot/* -R 
rm -rf /tmp/tmp_*.csv
echo
echo "############configure succeed############"
exit
