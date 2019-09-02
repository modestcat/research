#!/bin/bash

passwd root

#Update the exist Sources
#mv /etc/apt/sources.list /etc/apt/sources.list.backup
#mv sources.list /etc/apt/sources.list
apt-get update && apt-get upgrade -y
echo -e "\033[41;33m Sources Update Sucessfully! \033[0m\n\n\n"

#Configure the security policy
#userdel -r -f lp
#userdel -r -f sync
#userdel -r -f news
#userdel -r -f uucp
#userdel -r -f games
#groupdel adm
#groupdel lp
#groupdel news
#groupdel uucp
#groupdel games
#groupdel dip
echo -e "\033[41;33m Security Policy Configured 1 Sucessfully! \033[0m\n\n\n"
#cat /etc/security/limits.conf
#cat /etc/pam.d/login
#echo "* hard core 0" >> /etc/security/limits.conf
#echo　"* hard rss 5000" >> /etc/security/limits.conf
#echo　"* hard nproc 20" >> /etc/security/limits.conf
echo -e "\033[41;33m Security Policy Configured 2 Sucessfully!--Againist DDoS Attacking. \033[0m\n\n\n"

#Permissions configuration
#chattr +i /etc/passwd
#chattr +i /etc/shadow
#chattr +i /etc/group
#chattr +i /etc/gshadow
#passwd -l irc
#passwd -l whoopise
#passwd -l sh1
#passwd -l sh2
echo -e "\033[46;37m Permissions configured 1 Sucessfully! \033[0m\n\n\n"

#sed -i 's/Port 22/Port 6666/g' /etc/ssh/sshd_config
wget https://raw.githubusercontent.com/FunctionClub/Fail2ban/master/fail2ban.sh && bash fail2ban.sh 2>&1 | tee fail2ban.log
echo -e "\033[46;37m Permissions configured 2 Sucessfully! \033[0m\n\n\n"

#echo "auth sufficient /lib/security/pam_rootok.so debug" >> /etc/pam.d/su
#echo "auth required /lib/security/pam_wheel.so group=xxx" >> /etc/pam.d/su
#echo -e "\033[46;37m Permissions configured 3 Sucessfully! \033[0m\n\n\n"

#Configure the firewall policy
#ufw logging low
#ufw allow ssh
#ufw allow 53
#ufw allow 66
#ufw allow 67
#ufw allow 68
#ufw allow 80
#ufw allow 443
#ufw allow 1194
#ufw allow 6666
#ufw allow 8443
#ufw reject 445
#ufw reject 3389

echo "1" > /proc/sys/net/ipv4/ip_forward
cat /proc/sys/net/ipv4/ip_forward
sed -i '#net.ipv4.ip_forward=1/net.ipv4.ip_forward/g' /etc/sysctl.conf
sysctl -p

read -p "SSH Port: " -e sshport
iptables -A INPUT -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp --dport 8443 -j ACCEPT
iptables -A INPUT -p tcp --dport $sshport -j ACCEPT
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
apt-get install postgresql -y
echo -e "\033[41;33m Metasploit Situation Installed Sucessfully! \033[0m\n\n\n"

#Install security software
apt-get install unhide -y
apt-get install chkrootkit -y
echo -e "\033[41;33m Security Software Configured Sucessfully! \033[0m\n\n\n"

#Install Metasploit & other app
apt-get install rinetd -y
apt-get install iptables-persistent -y
#curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
#wget -O https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
#chmod 755 msfinstall
#./msfinstall -y
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && chmod 755 msfinstall && ./msfinstall
echo -e "\033[41;33m Metasploit Downloaded And Installede Sucessful,Then Need You To Config Something Needed. \033[0m\n\n\n"

#Finally
echo -e "\033[41;33m All Of This Script Execute Sucessfully! \033[0m\n\n\n"
echo -e "\033[41;33m NOW PLEASE ENTER 'sudo service ssh restart' to login your New Ubuntu From PORT 6666 \033[0m"

#Check Again? & ssh Rebuid
#cat /etc/ssh/sshd_config
/etc/init.d/ssh restart
/etc/init.d/ssh status
