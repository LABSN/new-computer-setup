#! /bin/bash

## This script should NOT be run as-is. It's a collection of advice and
## commands for you to pick-and-choose as they are relevant to your
## situation. 

## ## ## ##
## RAID  ##
## ## ## ##
sudo apt-get install mdadm

## This is an example only. Customize to match the actual drive numbers
## in your system that you want to build into a RAID.
raid_loc=/dev/md0
raid_one=/dev/sdc1
raid_two=/dev/sdd1
sudo mdadm --create $raid_loc -l 1 -n 2 $raid_one $raid_two
## This will create a RAID level=1 (mirror) at /dev/md0 comprising
## n=2 physical drives (sdc and sdd). If the RAID had already been built
## previously and you just want to restart it:
sudo mdadm --assemble $raid_loc $raid_one $raid_two
## To set the RAID to automount at startup (edit MOUNTPT as desired):
MOUNTPT="/media/raid"
sudo mkdir $MOUNTPT
UUID=$(sudo blkid $raid_loc | cut -d '"' -f2)
sudo echo "UUID=$UUID $MOUNTPT ext4 defaults 0 0" >> /etc/fstab
