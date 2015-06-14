#!/bin/bash

# Shell script to rebuild GDAL vrt file from OS Terrain 50 data.

# Copyright (C) 2015 Patrick B Warren unless stated otherwise.
# Email: patrickbwarren@gmail.com
# Paper mail: Dr Patrick B Warren, 11 Bryony Way, Birkenhead,
#   Merseyside, CH42 4LY, UK.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.

# This method of handling the OS Terrain 50 dataset is derived from:
# http://www.landscape-laboratory.org/2013/06/19/getting-started-with-os-terrain-50-elevation-data/

cd $OPENSHIFT_DATA_DIR

find data/ -name "*zip" -exec unzip -l {} \; \
    | gawk -v p=$OPENSHIFT_DATA_DIR '/Archive/ { printf "/vsizip/%s%s/", p, $NF }; /asc/ { printf "%s\n", $NF }' \
    | grep zip > GB.txt

echo "Created GB.txt"

touch GB.vrt && rm GB.vrt && gdalbuildvrt -input_file_list GB.txt GB.vrt

echo "Created GB.vrt"

sed s:$(pwd):DATADIR: GB.vrt > GB_template.vrt

echo "Created GB_template.vrt"

pwd > GB_version

echo "Created GB_version"
