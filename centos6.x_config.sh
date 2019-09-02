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
chkconfig fail2ban on
# 启动
service fail2ban start
# 重新启动sshd服务，使新配置生效
service sshd restart

# 关闭不必要的端口
service postfix stop
chkconfig postfix off

# 开启端口转发
echo 1 >/proc/sys/net/ipv4/ip_forward
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g'
#  安装gcc
yum install gcc -y 
# rinetd
wget http://www.boutell.com/rinetd/http/rinetd.tar.gz
tar -xvf ~/rinetd.tar.gz
sed -i 's/65536/65535/g' ~/rinetd/rinetd.c
mkdir /usr/man/
cd ~/rinetd <<EOF
make && make install;
EOF

# iptables配置
echo "please type sshport"
read port1
echo "please type openvpnport"
read port2
echo "please type ssport"
read port3
iptables -A INPUT -p tcp --dport $port1 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT	
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp --dport 8443 -j ACCEPT
# openvpn
iptables -A INPUT -p udp --dport $port2 -j ACCEPT
# shadowsocks
iptables -A INPUT -p tcp --dport $port3 -j ACCEPT
# 关闭firewalld防火墙
servie firewalld.service stop
service firewalld.service disable
# 启用 iptables 和ip6tables:
service iptables on
#持久化iptables
service iptables save
service iptables restart
chkconfig --add iptables
chkconfig iptables on
iptables -L -n --line-number

# VPS性能测试
#(wget -qO- wget.racing/nench.sh | bash; wget -qO- wget.racing/nench.sh | bash) 2>&1 | tee nench.log
#rm nench.log -f
service sshd status
service iptables status
service fail2ban status
chkconfig --list
netstat -antup
echo "Please Config Your Rinetd If You Need -- vi /etc/rinetd.conf && rinetd -c /etc/rinetd.conf"