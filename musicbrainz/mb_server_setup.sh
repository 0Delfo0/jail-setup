#!/bin/bash

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


cd /usr/local/share/musicbrainz-server
npm install

# Compile node.js resources
bash script/compile_resources.sh

# Import latest MB dump
/usr/local/share/musicbrainz-server/admin/InitDb.pl --createdb --import /tmp/mbdump/mbdump*.tar.bz2 --echo

echo "
###########################################################################
#                                                                         #
#                                                                         #
#             All done, please return to your setup console               #
#                                                                         #
#                                                                         #
###########################################################################"
