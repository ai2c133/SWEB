#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

#Check OS
if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ];then
    OS=CentOS
    [ -n "$(grep ' 7\.' /etc/redhat-release)" ] && CentOS_RHEL_version=7
    [ -n "$(grep ' 6\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && CentOS_RHEL_version=6
    [ -n "$(grep ' 5\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release5' /etc/issue)" ] && CentOS_RHEL_version=5
elif [ -n "$(grep 'Amazon Linux AMI release' /etc/issue)" -o -e /etc/system-release ];then
    OS=CentOS
    CentOS_RHEL_version=6
elif [ -n "$(grep bian /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Debian' ];then
    OS=Debian
    [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
    Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Deepin /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Deepin' ];then
    OS=Debian
    [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
    Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Ubuntu /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Ubuntu' -o -n "$(grep 'Linux Mint' /etc/issue)" ];then
    OS=Ubuntu
    [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
    Ubuntu_version=$(lsb_release -sr | awk -F. '{print $1}')
    [ -n "$(grep 'Linux Mint 18' /etc/issue)" ] && Ubuntu_version=16
else
    echo "Does not support this OS, Please contact the author! "
    kill -9 $$
fi

echo "Let's Setup the Username and Password for your webpanel'"

read -p "Please input your web username：" webuser
read -p "Please input your web password：" webpasswd
read -p "Please input your web port：" webport

#Install SSR (Powered By Teddysun : https://shadowsocks.be/9.html)
wget -N --no-check-certificate https://raw.githubusercontent.com/iisure/shadowsocks_install/master/shadowsocksR.sh
chmod +x shadowsocksR.sh
bash shadowsocksR.sh
rm -rf shadowsocksR.sh

#Install Basic Tools
if [[ ${OS} == Ubuntu ]];then
	apt-get update
	apt-get install python zip unzip -y
	apt-get install python-pip -y
	apt-get install git -y
	apt-get install language-pack-zh-hans -y
    apt-get install screen curl -y
fi
if [[ ${OS} == CentOS ]];then
	yum install python screen curl zip unzip -y
	yum install python-setuptools -y && easy_install pip -y
	yum install git -y
    yum groupinstall "Development Tools" -y
fi
if [[ ${OS} == Debian ]];then
	apt-get update
	apt-get install python screen curl zip unzip -y
	apt-get install python-pip -y
	apt-get install git -y
    apt-get install -y
fi

#Install Caddy (Powered By Toyo : https://doub.io/shell-jc1/)
wget -N --no-check-certificate https://raw.githubusercontent.com/ai2c133/SWEB/master/caddy/caddy_install.sh
chmod +x caddy_install.sh && bash caddy_install.sh
rm -rf caddy_install.sh

#Install SWEB
cd /usr/local/
git clone https://github.com/iisure/SWEB
chmod +x /usr/local/SWEB/cgi-bin

#Configure Caddy Proxy
echo ":$webport {
 basicauth / $webuser $webpasswd
 proxy / http://127.0.0.1:8000
}" > /usr/local/caddy/Caddyfile
service caddy restart

#Download SWEB Manager
wget -N --no-check-certificate -O /usr/local/bin/sweb https://raw.githubusercontent.com/ai2c133/SWEB/master/sweb
chmod +x /usr/local/bin/sweb

#Start SWEB in Screen
cd /usr/local/SWEB
screen -dmS SWEB python CGIHTTPServer.py

#Setup iptables rules
iptables -I INPUT -p tcp --dport 8000 -j DROP
iptables -I INPUT -s 127.0.0.1 -p tcp --dport 8000 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $webport -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 32000 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 32000 -j ACCEPT

#Setup V2ray
bash <(curl -L -s https://install.direct/go.sh)
cp /usr/local/SWEB/myv2ray.json /etc/v2ray/
rm -rf /etc/v2ray/config.json && cp /usr/local/SWEB/config.json /etc/v2ray/config.json
service v2ray restart
VER="$(curl -s https://api.github.com/repos/v2ray/v2ray-core/releases/latest | grep 'tag_name' | cut -d\" -f4)"
wget -N --no-check-certificate https://github.com/v2ray/v2ray-core/releases/download/${VER}/v2ray-windows-32.zip
unzip v2ray-windows-32.zip && rm -rf v2ray-windows-32.zip
cd v2ray-${VER}-windows-32 && mv v2ray.exe /usr/local/SWEB/v2ray-client/ && mv wv2ray.exe /usr/local/SWEB/v2ray-client/
cd .. && rm -rf v2ray-${VER}-windows-32
rm -rf /usr/local/SWEB/v2ray-client/client.zip && cd /usr/local/SWEB/ && zip -r /usr/local/SWEB/client.zip v2ray-client/ && mv /usr/local/SWEB/client.zip /usr/local/SWEB/v2ray-client/

#Start when boot
if [[ ${OS} == Ubuntu || ${OS} == Debian ]];then
    cat >/etc/init.d/bootsweb <<EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:          SWEB
# Required-Start: $local_fs $remote_fs
# Required-Stop: $local_fs $remote_fs
# Should-Start: $network
# Should-Stop: $network
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description: SWEB
# Description: SWEB
### END INIT INFO
iptables -I INPUT -p tcp --dport 8000 -j DROP
iptables -I INPUT -s 127.0.0.1 -p tcp --dport 8000 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
cd /usr/local/SWEB && screen -dmS SWEB python CGIHTTPServer.py
service v2ray start
service caddy start
EOF
    chmod 755 /etc/init.d/bootsweb
    chmod +x /etc/init.d/bootsweb
    cd /etc/init.d
    update-rc.d bootsweb defaults 95
fi

if [[ ${OS} == CentOS ]];then
    echo "
iptables -I INPUT -p tcp --dport 8000 -j DROP
iptables -I INPUT -s 127.0.0.1 -p tcp --dport 8000 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $webport -j ACCEPT
cd /usr/local/SWEB && screen -dmS SWEB python CGIHTTPServer.py
service v2ray start
service caddy start
" > /etc/rc.d/init.d/bootsweb
    chmod +x  /etc/rc.d/init.d/bootsweb
    echo "/etc/rc.d/init.d/bootsweb" >> /etc/rc.d/rc.local
    chmod +x /etc/rc.d/rc.local
fi

#Install OK
echo "Install Finished!"
echo ''
echo 'Visit http://your ip + port to Enjoy!'
