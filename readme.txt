This utility enables web based tty and remote desktop to a Ubuntu Distribution. It has been tested with Ubuntu 14 distribution.

Usage:
=======
-- User should be root. 
-- untar this archive in a directory.
-- Open 'install.config' file to change the IPv4 address and Port numbers wrt to installation environment. 
-- For installation: 
./install.sh 
-- If installation is complete, following output will be shown.

Webserver running at: http://192.168.229.134:31000

-- This URL can be copied to a browser to get a home html page having two buttons: 
    1. Web SSH Console 
       Click on it, a new tab will open. Click to 'Open Terminal' to open as many tty session as you like! 
    2. Web Remote Desktop 
       Click on it, a new tab will open. Click on 'Connect' to view the remote desktop. 
-- For stopping all services: 
./install.sh stop 

=========================================================================
For any issues, please send install.log file to <vinay.jindal@83incs.com>
=========================================================================
