#!/bin/bash

# ####################################################################
# Script Name:	Static Route Updater
# Author: 	Guillaume Seigneuret
# Date: 	05/01/2016
# Version:	1.0
# 
# Usage:	Take a Domain Name file as parameter, check for all IP 
#			corresponding to that DN and set a specific gateway for it
# 
# Usage domain: Made to be inserted into cron script on Linux only
# 
# Parameters: 	Only variables into the script :
#				DNFILE : Full path to the text file containing DN list
#				GATEWAY : IP of the gateway used to contact corresponding
#						  servers.
# 
# Config file:	Not really a config file but DNFILE may be considered 
#				as one.
#
# Prerequisites : Need the dns util named dig and a redis-server
#
# ####################################################################
# GPL v3
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# ####################################################################

DNFILE=/root/domains.txt
GATEWAY=192.168.1.1

# Add relevent Plex IP and store them in Redis
for myip in $(dig -f $DNFILE +noall +answer +short)
do
        ip route add $myip/32 via $GATEWAY > /dev/null 2>&1
        redis-cli SADD myip.new $myip > /dev/null 2>&1
done


# Make a diff between old IP and new ones
# And delete old routes
for oldip in $(redis-cli SDIFF myip.old myip.new)
do
        ip route del $oldip/32 via $GATEWAY
done

# Copy new IP to old one for next comparision
redis-cli RENAME myip.new myip.old > /dev/null 2>&1
