#!/bin/bash

#Check if user is root
[ $(id -u) != "0" ] && { echo -e "\033[31mError: You must be root to run this script\033[0m"; exit 1; } 
#passwd root

#Update the exist Sources
#mv /etc/apt/sources.list /etc/apt/sources.list.backup
#mv sources.list /etc/apt/sources.list
apt-get update && apt-get upgrade -y
echo -e "\033[41;33m Sources Update Sucessfully! \033[0m\n\n\n"

#Configure the security policy
wget https://raw.githubusercontent.com/FunctionClub/Fail2ban/master/fail2ban.sh && bash fail2ban.sh 2>&1 | tee fail2ban.log
echo -e "\033[46;37m Permissions configured 2 Sucessfully! \033[0m\n\n\n"

echo "1" > /proc/sys/net/ipv4/ip_forward
cat /proc/sys/net/ipv4/ip_forward
sed -i '#net.ipv4.ip_forward=1/net.ipv4.ip_forward/g' /etc/sysctl.conf
sysctl -p

read -p "SSH Port: " -e sshport
read -p "VPN Port: " -e vpnport
#iptables -A INPUT -p tcp --dport 53 -j ACCEPT
#iptables -A INPUT -p tcp --dport 80 -j ACCEPT
#iptables -A INPUT -p tcp --dport 443 -j ACCEPT
#iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
#iptables -A INPUT -p tcp --dport 8443 -j ACCEPT
iptables -A INPUT -p tcp --dport $sshport -j ACCEPT
iptables -A INPUT -p tcp --dport $vpnport -j ACCEPT
#iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
#iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
#iptables -A FORWARD -m state –state RELATED,ESTABLISHED -j ACCEPT
echo -e "\033[41;33m Firewall Policy Configured Sucessfully! \033[0m\n\n\n"

#Install prerequisite software
#apt-get install python -y
#apt-get install perl -y
#apt-get install gcc g++ -y
#apt-get install gcc-opt -y
#apt-get install g++-3.4 gcc-3.4 -y
echo -e "\033[41;33m Prerequisite Software Installed Sucessfully! \033[0m\n\n\n"

#apt-get install tcpdump -y
#apt-get install iptables-persistent
apt-get install ruby -y
apt-get install nmap -y
#apt-get install postgresql -y
echo -e "\033[41;33m Metasploit Situation Installed Sucessfully! \033[0m\n\n\n"

#Install Metasploit & other app
apt-get install rinetd -y
apt-get install iptables-persistent -y
#curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
#wget -O https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
#chmod 755 msfinstall
#./msfinstall -y
#curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && chmod 755 msfinstall && ./msfinstall
echo -e "\033[41;33m Metasploit Downloaded And Installede Sucessful,Then Need You To Config Something Needed. \033[0m\n\n\n"

#Finally
echo -e "\033[41;33m All Of This Script Execute Sucessfully! \033[0m\n\n\n"
echo -e "\033[41;33m NOW PLEASE ENTER 'sudo service ssh restart' to login your New Ubuntu From PORT 6666 \033[0m"

#Check Again? & ssh Rebuid
#cat /etc/ssh/sshd_config
/etc/init.d/ssh restart
/etc/init.d/ssh status
