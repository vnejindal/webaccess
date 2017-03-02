# !/usr/bin/bash 


log_file=install.log
cur_time=`date`
echo 'Installation started'

{
set -x
echo "cli params: "
echo "$0 $@"
echo "Hostname: `hostname`"
echo "ip list: `ip addr`"
echo ""
command=`uname -a;echo; lsb_release -a`
echo "------------------------------------------"
echo "Installation started $cur_time"
echo "------------------------------------------"
echo $command 

os_ver=`uname -a | awk {'print $2'}`
config_file=install.config
#Config file for tty.js module
tty_configjson=ttyconfig.json
ip_token='ip_address'
port_token='port'

if [ $os_ver != 'ubuntu' ] && [ $os_ver != 'Ubuntu' ]; then
  echo 'OS version: $os_ver not supported. Exiting.'
  exit 1
fi 
if [ `whoami` != 'root' ]; then 
  echo 'User is not root. Exiting'
  exit 1
fi 
if [ ! -f $config_file ]; then 
  echo 'Config file: $config_file does not exist. Incomplete installation. Exiting'
  exit 1
fi 
if [ ! -f $tty_configjson ]; then 
  echo "$tty_configjson does not exist. Incomplete installation. Exiting"
  exit 1
fi 

ipaddr=`cat $config_file | grep $ip_token | awk {'print $3'}`
port=`cat $config_file | grep $port_token | awk {'print $3'}`
ttyport=`expr $port + 1`
novncport=`expr $ttyport + 1`
vncport=`expr $novncport + 1`

dfile='.install'
dipaddr='127.0.0.1'
dport=8000
dttyport=`expr $dport + 1`
dnovncport=`expr $dttyport + 1`
validate_network_params()
{
ip addr | grep $ipaddr
if [ $? -eq 0 ]; then
echo "ip address: $ipaddr exists"
else
echo "ip address: $ipaddr not present in system. Invalid config"
exit 1
fi
netstat -anp | grep $port
if [ $? -eq 0 ]; then
echo "Web Server port number: $port already in use. Exiting."
exit 1
fi
netstat -anp | grep $ttyport
if [ $? -eq 0 ]; then
echo "TTY port number: $ttyport already in use. Exiting."
exit 1
fi
netstat -anp | grep $vncport
if [ $? -eq 0 ]; then
echo "VNC port number: $vncport already in use. Exiting."
exit 1
fi
netstat -anp | grep $novncport
if [ $? -eq 0 ]; then
echo "No VNC port number: $novncport already in use. Exiting."
exit 1
fi
}

get_config_bkup()
{
if [ -f $dfile ]; then
dipaddr=`cat $dfile | cut -d':' -f1` 
dport=`cat $dfile | cut -d':' -f2` 
dttyport=`cat $dfile | cut -d':' -f3` 
dnovncport=`cat $dfile | cut -d':' -f4` 
fi
echo "dconfig details"
echo $dipaddr $dport $dttyport $dnovncport
}
dump_config_bkup()
{
if [ ! -f $dfile ]; then
echo "first time installation" 
else
echo "installation already done"
fi 
echo $ipaddr:$port:$ttyport:$novncport > $dfile 
}
install_nodejs_modules()
{
pkg_state=`dpkg --get-selections | grep nodejs | awk {'print $2'}`
if [ $pkg_state = 'install' ]; then 
  echo 'nodejs already installed'
else
   curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
   apt-get install -y nodejs 
   echo 'nodejs installed'
fi
echo "Node Js: `node-v`"
echo "NPM : `npm -v`"
echo 'installing required nodejs modules'
node_mods='tty.js bluebird'
npm install $node_mods
}
params_replace()
{
js_file='app.js'
html_file='index.html'
get_config_bkup
sed -i -e 's/'"$dipaddr"'/'"$ipaddr"'/g' $js_file
sed -i -e 's/'"$dport"'/'"$port"'/g' $js_file

#set -x
sed -i -e 's/'"$dipaddr"'/'"$ipaddr"'/g' $html_file
sed -i -e 's/'"$dttyport"'/'"$ttyport"'/g' $html_file
sed -i -e 's/'"$dnovncport"'/'"$novncport"'/g' $html_file
#set +x
sed -i -e 's/'"$dttyport"'/'"$ttyport"'/g' $tty_configjson
dump_config_bkup
}


###### x11vnc installation ########
install_x11vnc()
{
pkg_state=`dpkg --get-selections | grep x11vnc | awk {'print $2'} | head -1`
if [ $pkg_state = 'install' ]; then 
  echo 'x11vnc already installed'
else
  apt-get install x11vnc
fi 
echo "x11vnc version: `x11vnc --version`" 
}

install_novnc()
{
if [ -d "noVNC" ]; then
echo "noVNC already present"
else
git clone git://github.com/kanaka/noVNC
fi
}

final_print()
{
echo "-----------------------------------------------------------"
echo "Webserver running at: http://$ipaddr:$port"
echo "Web Console Access running at: http://$ipaddr:$ttyport"
echo "NoVNC Desktop Access URL: "
echo "http://$ipaddr:$novncport/vnc.html"
echo "-----------------------------------------------------------"
}

start_nodejs_server()
{
echo "Starting nodejs application"
node app.js &
}
start_vnc_server()
{
echo "starting x11vnc server"
#/usr/bin/x11vnc -xkb -auth /var/run/lightdm/root/:0 -noxrecord -noxfixes -noxdamage -rfbauth /etc/x11vnc.pass -forever -bg -rfbport $vncport -o /var/log/x11vnc.log
#without password
/usr/bin/x11vnc -xkb -auth /var/run/lightdm/root/:0 -noxrecord -noxfixes -noxdamage -forever -bg -rfbport $vncport -o /var/log/x11vnc.log
}
start_novnc_server()
{
echo "starting novnc"
./noVNC/utils/launch.sh --vnc localhost:$vncport --listen $novncport &
}
stop_services()
{
kill -9 `ps -ef | grep app.js | grep -v grep | awk {'print $2'}`
kill -9 `ps -ef | grep x11vnc | grep -v grep | awk {'print $2'}`
kill -9 `ps -ef | grep launch.sh | grep -v grep | awk {'print $2'}`
kill -9 `ps -ef | grep websockify | awk {'print $2'}`

}
start_services()
{
  stop_services
  start_vnc_server
  start_novnc_server
  start_nodejs_server
}

if [ $1 = "stop" ]; then
stop_services
echo "Services Stopped"
exit 1
fi
#Functions calling starts here
validate_network_params
install_nodejs_modules
params_replace
install_x11vnc
install_novnc
final_print
start_services
echo "Installation complete"
echo "Please check $log_file file for details."

} >> $log_file 2>&1


echo "-----------------------------------------------------------"
echo "Webserver running at: http://$ipaddr:$port"
echo "-----------------------------------------------------------"


#vne::tbds
#pwd authentication in novnc
#https support in webserver, tty and novnc
#wireshark functionality 

#check if sshd service running or not
#cleanup function 
#service and configuration persistence

