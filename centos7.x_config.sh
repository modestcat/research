#!/bin/bash
passwd root

# 基本工具安装
yum update -y
yum install unzip -y
yum install wget -y
yum install vim -y 

# 备份ssh配置文件
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
# 备份yum源
cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
# 修改ssh配置文件
#sed -i 's/#Port 22/Port 55555/' /etc/ssh/sshd_config

#fail2ban
wget https://raw.githubusercontent.com/FunctionClub/Fail2ban/master/fail2ban.sh && bash fail2ban.sh 2>&1 | tee fail2ban.log
# 检测是否安装成功
fail2ban-client -h
# 查看版本
fail2ban-client --version
# 加入开机服务项
chkconfig --add fail2ban
# 开机启动
systemctl enable fail2ban
# 启动
systemctl start fail2ban

# 重新启动sshd服务，使新配置生效
systemctl restart sshd.service
#查看已启动的服务列表
systemctl list-unit-files|grep enabled
#查看启动失败的服务列表
systemctl --failed

# 开启端口转发
echo 1 >/proc/sys/net/ipv4/ip_forward
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g'
# rinetd
wget http://www.boutell.com/rinetd/http/rinetd.tar.gz
tar -xvf ~/rinetd.tar.gz
sed -i 's/65536/65535/g' ~/rinetd/rinetd.c
mkdir /usr/man/
cd ~/rinetd <<EOF
make && make install;
EOF

# fiewall配置
# 查看firewalld状态
systemctl status firewalld
# 显示firewalld服务的状态
systemctl status firewalld.service
# 启动firewalld
systemctl start firewalld
# 启动firewalld服务
systemctl start firewalld.service
# 查看版本
firewall-cmd --version
# 显示状态
firewall-cmd --state
# add rules
echo "please type sshport"
read port1
echo "please type openvpnport"
read port2
echo "please type ssport"
read port3
firewall-cmd --zone=public --add-port=53/tcp --permanent 
firewall-cmd --zone=public --add-port=80/tcp --permanent 
firewall-cmd --zone=public --add-port=443/tcp --permanent 
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --zone=public --add-port=8443/tcp --permanent
# ssh 
firewall-cmd --zone=public --add-port=$port1/tcp --permanent 
# openvpn(udp)
firewall-cmd --zone=public --add-port=$port2/udp --permanent 
# ssport
firewall-cmd --zone=public --add-port=$port3/tcp --permanent 
# 更新防火墙规则
firewall-cmd --reload
# 查看区域信息
firewall-cmd --get-active-zones
# 查看所有打开的端口
firewall-cmd --zone=public --list-ports
#查看区域信息
firewall-cmd --get-active-zones
# 重启firewalld
systemctl restart firewalld
# 重启firewalld服务
systemctl restart firewalld.service
# 查看firewalld服务是否开机启动
systemctl is-enabled firewalld.service
# 配置firewalld开机启动
systemctl enable firewalld.service
# 查看firewalld状态
systemctl status firewalld
# 显示firewalld服务的状态
systemctl status firewalld.service

# VPS性能测试
#(wget -qO- wget.racing/nench.sh | bash; wget -qO- wget.racing/nench.sh | bash) 2>&1 | tee nench.log
#rm nench.log -f
netstat -antup
echo "Please Config Your Rinetd If You Need -- vi /etc/rinetd.conf && rinetd -c /etc/rinetd.conf"