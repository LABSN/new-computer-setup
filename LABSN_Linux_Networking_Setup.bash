#! /bin/bash

## This script should NOT be run as-is. It's a collection of advice and
## commands for you to pick-and-choose as they are relevant to your
## situation. 

## ## ## ## ##
## OPEN-SSH ##
## ## ## ## ##
## If you want to connect to your lab computer from elsewhere, you will
## need to configure it to receive SSH connections and set up a keypair.
sudo apt-get install openssh-server
## First make sure you're getting a static IP (check network settings
## for eth0). For added security, change port number to something other
## than the default port 22 in /etc/ssh/sshd_config. Then access via:
ssh -p 1234 <username>@<host>.ilabs.uw.edu
## where 1234 is the port you chose, <username> is your login name for
## that computer, and <host> is the name you assigned your computer at
## setup. To make it even more secure, set it so that it only accepts
## SSH connections that use pre-shared keys (not passwords) by editing
## the file /etc/ssh/ssh_config and commenting out the line that says:
## PasswordAuthentication yes
## (or just change the "yes" to "no"). If you don't know how to set up
## pre-shared keys, there are lots of internet tutorials on that.

## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## RUNNING FIREFOX THROUGH AN SSH TUNNEL  ##
## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## This sets up a pseudo-VPN for browser traffic only (useful if, e.g.,
## you're in a foreign country that blocks some websites). To avoid
## changing these settings back and forth all the time, first set up a
## new Firefox profile by running "firefox -P" on the command line.
## Create a new profile with a sensible name like "ssh" or "tunnel".
## Start Firefox with that profile, then go to:
## "Preferences > Advanced > Network > Settings" and choose "Manual
## Proxy Configuration". Set your SOCKS host to 127.0.0.1, port 8080,
## use SOCKS v5, and check the "Remote DNS" box. Now you can run:
ssh -C2qTnN -D 8080 <name>@<host>
## ...before you launch Firefox, and all your browser traffic will be
## routed through your <host> computer and encrypted. Don't forget
## to add the flag "-p 1234" to the ssh command if you've configured
## ssh to listen on a non-default port (as recommended above). Note that
## the Firefox profile editor allows you to select a default profile, so
## that can be an easy way to switch settings for the duration of your
## journey abroad, then switch back upon returning home. If you need to
## switch back and forth between tunnel and no tunnel on a regular
## basis, you can set your normal Firefox profile as the default, then
## use the following command to invoke the tunneled version (assuming
## the name of your proxied profile is "sshtunnel"):
ssh -C2qTnN -D 8080 <name>@<host> & tunnelpid=$! && sleep 3 && \
firefox -P sshtunnel && kill $tunnelpid
## this will capture the PID of the SSH tunnel instance, and kill it
## when Firefox closes normally (you'll need to kill it manually if
## Firefox crashes or is force-quit).

## ## ## ##
## XRDP  ##
## ## ## ##
## XRDP is a remote desktop server. Install it if you want to access
## your computer remotely through a GUI rather than a terminal (note
## that it is a LOT slower than terminal access, and kind of buggy).
sudo apt-get install xrdp

## ## ## ## ##
## FIREWALL ##
## ## ## ## ##
## You don't strictly NEED to set up a firewall, as *NIX is pretty
## careful about what it allows in. This is especially true if you set
## SSH to reject password-based connections and only use preshared keys.
## Nonetheless, if you want to set up a strong firewall, this is a good
## starting point:
## (port numbers should match what you set for SSH and VPN)
sudo iptables -A INPUT -p tcp --dport 1234 -j ACCEPT  # incoming SSH
sudo iptables -A INPUT -p tcp --sport 1234 -j ACCEPT  # outgoing SSH
sudo iptables -A INPUT -p udp -m udp --dport 2345 -j ACCEPT  # incoming VPN
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT  # incoming web traffic
## You will probably also need a line for the default HTTPS port (and
## possibly others). Google is your friend here. Finally, add a line to
## reject everything not explicitly allowed above. You will need to save
## changes (again, see Google for different ways to do this) otherwise
## the settings will only last for the current login session.
