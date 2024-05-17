下载地址：https://github.com/hellowjko/myipxe/releases

说明：
1.执行脚本sh 1-install.sh pxe-all.tar.gz安装PXE服务
2.上传系统镜像iso文件然后执行sh 2-upload.sh脚本
3.上传ks文件到/var/www/html/kickstart/目录下
4.修改macinfo.csv文件并上传当前目录
5.执行sh 3-template.sh
6.开始安装系统
7.装完系统后探测主机IP
nmap -sP 192.168.1.0/24 > report.txt
nmap -sP 192.168.21.1-10|grep "report"|awk '{print $NF}'|sed -e 's/^(//g' -e 's/)//g'

delete.sh删除上传的镜像
如果需要装机后配置IP地址，将http://本机ip/other/init_ip.sh|bash 添加到ks文件中
ipmitool目录为ipmitool常用命令

macinfo.csv填写说明：
第1列[ipmi]：IPMI带外地址（格式：10.17.122.1）
第2列[serial]：序列号（避免序列号都为数字显示科学计数，规范格式为：sn-abcd12345，普通物理服务器装机使用）
第3列[mac]：MAC地址（格式：bc:16:95:36:fe:52，只在虚拟机测试时使用）
第4列[role]：服务器角色/服务器名称（格式：标准文件存储管理服务器）
第5列[hostname]：主机名（格式：FJFZSNL-20F-HH0711-SEV-ZX5300-02U13）
第6列[system]：安装系统（格式：centos｜ctyunos）
第7列[architecture]：系统架构（x86_64｜aarch64）
第8列[version]：系统版本（7.6｜62｜64）
第9列[ks_name]：安装KS文件名称（自定义名称，格式：centos-7.6.ks）





