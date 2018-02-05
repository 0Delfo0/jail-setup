#!/bin/sh

###
# Setup iocage jail for musicbrainz server
# Heavily influenced by http://bit.ly/2s9rcDU and http://bit.ly/2nFhvYY
###

###
#   Copyright (C) Philip Walsh 2018
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
###


##
# Check for root
##

uid=$(/usr/bin/id -u) && [ "$uid" = "0" ] ||
{ echo "must be root"; exit 1; }

##
# Define Directories, script name, etc
##

# Apps Directory
BASEDIR="/path/to/app/dataset"
# Script Name
APP_NAME="musicbrainz"
# IP Address
IP_ADDR="0.0.0.0"
# Gateway IP address
IP_ROUTER="0.0.0.0"

SCRIPT_DIR="${BASEDIR}/${APP_NAME}"

########
# DO NOT EDIT BELOW HERE
########


########
# Setup Jail Paramaters first
########


# Setup iocage jail
iocage create -n "$APP_NAME" -p ${SCRIPT_DIR}/pkg.json -r 11.1-RELEASE ip4_addr="vnet0|$IP_ADDR/24" defaultrouter="$IP_ROUTER" vnet="on" allow_raw_sockets="1" boot="on"

# Mount config dir
iocage fstab -a $APP_NAME $SCRIPT_DIR /config nullfs rw 0 0

########
# Setup musicbrainz_server
########

# Clone from git
iocage exec $APP_NAME git clone --recursive git://github.com/metabrainz/musicbrainz-server.git /usr/local/share/musicbrainz-server

# Copy in configuration files
iocage exec $APP_NAME cp /config/musicbrainz_server/DBDefs.pm /usr/local/share/musicbrainz-server/lib/DBDefs.pm
iocage exec $APP_NAME cp /config/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf
iocage exec $APP_NAME cp /config/musicbrainz_server/supervisord.conf /usr/local/etc/supervisord.conf

# Sort out logging directories
iocage exec $APP_NAME mkdir /usr/local/etc/nginx/logs

# Install Perl dependencies
iocage exec $APP_NAME cpanm --installdeps --notest /usr/local/share/musicbrainz-server
# FastCGI not installed by the above
iocage exec $APP_NAME cpanm FCGI
iocage exec $APP_NAME cpanm FCGI::ProcManager

#Dirty fix for #!/bin/bash in install files
iocage exec $APP_NAME ln -s /usr/local/bin/bash /bin/bash

# Compile and install PostgreSQL Extensions
iocage exec $APP_NAME gmake -C /usr/local/share/musicbrainz-server/postgresql-musicbrainz-unaccent install
iocage exec $APP_NAME gmake -C /usr/local/share/musicbrainz-server/postgresql-musicbrainz-collate install

# Copy in postgres ident config file
iocage exec $APP_NAME cp /config/musicbrainz_server/pg_ident.conf /usr/local/share/postgresql/pg_ident.conf

# Initilaise pgsql
iocage exec $APP_NAME /usr/local/etc/rc.d/postgresql oneinitdb

# Autostart services
iocage exec $APP_NAME sysrc postgresql_enable=YES
iocage exec $APP_NAME sysrc redis_enable=YES
iocage exec $APP_NAME sysrc memcached_enable=YES
iocage exec $APP_NAME sysrc nginx_enable=YES
iocage exec $APP_NAME sysrc supervisord_enable=YES

# Start services
iocage exec $APP_NAME service postgresql start
iocage exec $APP_NAME service redis start
iocage exec $APP_NAME service memcached start
iocage exec $APP_NAME service nginx start


# Get latest mb dump ID
MB_DUMPID=$(curl -L http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/LATEST)
iocage exec $APP_NAME mkdir -p /tmp/mbdump
iocage exec $APP_NAME curl http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/$MB_DUMPID/mbdump-cdstubs.tar.bz2 -o /tmp/mbdump/mbdump-cdstubs.tar.bz2
iocage exec $APP_NAME curl http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/$MB_DUMPID/mbdump-cover-art-archive.tar.bz2 -o /tmp/mbdump/mbdump-cover-art-archive.tar.bz2
iocage exec $APP_NAME curl http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/$MB_DUMPID/mbdump-derived.tar.bz2 -o /tmp/mbdump/mbdump-derived.tar.bz2
iocage exec $APP_NAME curl http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/$MB_DUMPID/mbdump-edit.tar.bz2 -o /tmp/mbdump/mbdump-edit.tar.bz2
iocage exec $APP_NAME curl http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/$MB_DUMPID/mbdump-editor.tar.bz2 -o /tmp/mbdump/mbdump-editor.tar.bz2
iocage exec $APP_NAME curl http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/$MB_DUMPID/mbdump-stats.tar.bz2 -o /tmp/mbdump/mbdump-stats.tar.bz2
iocage exec $APP_NAME curl http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/$MB_DUMPID/mbdump.tar.bz2 -o /tmp/mbdump/mbdump.tar.bz2


# Script waits here for user to run mb_server_setup.sh inside iocage console
# This runs the npm install so the server displays properly and imports the 
# musicbrainz server dump. It takes HOURS to complete.

clear
echo "
###########################################################################
# Unfortunately, some of the required setup must be run                   #
# from inside an interactive shell.                                       #
#                                                                         #
# I don't know why, but these commands don't work when                    #
# run from outside the jail with iocage exec                              #
#                                                                         #
# Please open a new console session and run                               #
#     sudo iocage console $APP_NAME                                     #
#                                                                         #
# If you are running this over ssh you might consider running             #
# the following command inside tmux or screen. It takes a while.          #
#                                                                         #
# Then inside the jail, run                                               #
#     sh /config/mb_server_setup.sh                                       #
#                                                                         #
# You can close the iocage console once the script has finished.          #
#                                                                         #
#                                                                         #
# This script will remain paused until you press the                      #
# enter key                                                               #
#                                                                         #
###########################################################################"

read -p "Press enter key to continue" junkvar

echo "

###########################################################################
#                                                                         #
#    Running initial musicbrainz replication.                             #
#    This might take some time                                            #
#                                                                         #
###########################################################################"

# Initial musicbrainz replication run
iocage exec $APP_NAME /usr/local/share/musicbrainz-server/admin/cron/slave.sh


echo "

###########################################################################
#                                                                         #
#    Musicbrainz replication complete                                     #
#                                                                         #
#    You'll want to add the following command to your FreeNAS crontab     #
#                                                                         #
###########################################################################

iocage exec $APP_NAME /usr/local/share/musicbrainz-server/admin/cron/slave.sh     

"

# Start musicbrainz via supervisord

iocage exec $APP_NAME service supervisord start

clear
echo "
 At this stage your musicbrainz mirror should be up at                   
 http://$IP_ADDR:5000


 Don't forget to add the replication command to your freenas crontab:
 iocage exec $APP_NAME /usr/local/share/musicbrainz-server/admin/cron/slave.sh"

exit 0
