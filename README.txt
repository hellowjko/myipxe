下载地址：https://github.com/hellowjko/myipxe/releases

说明：
1.执行脚本sh 1-install.sh pxe-all.tar.gz安装PXE服务
2.上传系统镜像iso文件然后执行sh 2-upload.sh脚本
3.上传ks或user-data文件到/var/www/html/kickstart/目录下
4.修改macinfo.csv文件并上传当前目录
5.执行sh 3-template.sh
6.开始安装系统
7.装完系统后探测主机IP
nmap -sP 192.168.1.0/24 > report.txt
nmap -sP 192.168.21.1-10|grep "report"|awk '{print $NF}'|sed -e 's/^(//g' -e 's/)//g'

delete.sh可以删除上传的镜像，也可手动删除
ipmitool目录为ipmitool常用命令
ansible目录为获取服务器dhcp ip地址与服务器序列号对应关系

macinfo.csv填写说明：
第1列[ipmi]：IPMI带外地址（格式：10.17.122.1）
第2列[serial]：序列号（避免序列号都为数字显示科学计数，规范格式为：sn-abcd12345）
第3列[mac]：MAC地址（格式：bc:16:95:36:fe:52，虚拟机测试用mac，一般物理服务器只需用sn安装即可）
第4列[role]：服务器角色/服务器名称（格式：标准文件存储管理服务器）
第5列[hostname]：主机名（格式：FJFZSNL-20F-HH0711-SEV-ZX5300-02U13）
第6列[system]：安装系统（格式：centos｜ctyunos|ubuntu）
第7列[architecture]：系统架构（x86_64｜aarch64）
第8列[version]：系统版本（7.6｜62｜64|24.04）
第9列[ks_name]：安装KS文件名称或者ubuntu的user-data文件（自定义名称，格式：centos.ks）

只能同时安装一个版本的ubuntu系统,centos系列可同时安装多个版本
