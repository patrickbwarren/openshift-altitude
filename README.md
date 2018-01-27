## Altitudes from OS grid references

_no longer under development as OpenShift platform has moved on_

Code for calculating altitudes for Ordnance Survey (OS) National Grid
References (NGRs) from the [OS Terrain 50
dataset](http://www.ordnancesurvey.co.uk/business-and-government/products/terrain-50.html
"OS website link"), deployed as a [RedHat
OpenShift](https://www.openshift.com/ "OpenShift website") web
application.

It takes advantage of the fact that the Geospatial Data Abstraction
Library ([GDAL](http://gdal.osgeo.org/ "GDAL website")) utilities are
already installed in the OpenShift 'gear'.

To manage OpenShift apps, I recommend installing the `rhc` tool
package as described in the [OpenShift
documentation](https://developers.openshift.com/en/managing-client-tools.html
"Installing the OpenShift Client Tools").

### Installation

1. Create an OpenShift app and install the DIY cartridge.

2. Clone the app into a local directory with, eg, `rhc git-clone <app>`

3. Copy all the files from the `diy` and `.openshift/action-hooks`
directories in the present GitHub repository into the cloned app,
overwriting existing files where necessary.

4. Signal the new files that have been added with the appropriate `git
add` commands.

5. Optionally, remove `testrubyserver.rb` from the `diy` directory
(it is no longer needed), with a `git rm` command.

6. Push the changes : `git commit -a -m "my message" && git push`.
Note that with the way `rhc` sets things up it is not necessary to do
a `git push origin master`

If you navigate to the app home page (ie
`<app>-<yourname>.rhcloud.com`) you should now see the new index page.
However submitting NGRs will not yet work as the OS Terrain 50 dataset
has not been installed.  To install the OS Terrain 50 dataset you need
to get a download link from the Ordnance Survey.  This can be obtained
by following the instructions on the [OS web
site](https://www.ordnancesurvey.co.uk/opendatadownload/products.html
"OS OpenData download").  With this download link:

1. SSH into the app with, eg, `rhc ssh <app>`

2. Navigate to the app's data directory with `cd $OPENSHIFT_DATA_DIR`.

3. Now pull down the dataset with `wget -O terr50.zip
"<download-link>"`.  The use of double quotes around the download link
is practically essential to avoid the shell misinterpreting the
characters.  The use of the `-O` option helps keep the name of the
downloaded `.zip` file manageable (of course you can chose any name
you like here).

4. Unpack the download with `unzip terr50.zip`.

This produces a `data` subdirectory with a huge number of zipped data
files.  As described in this [blog
entry](http://www.landscape-laboratory.org/2013/06/19/getting-started-with-os-terrain-50-elevation-data/
"Landscape Laboratory blog"), these can be managed by building a GDAL
`.vrt` file using the `gdalbuildvrt` command.  The steps to do this
are coded into the `rebuild_vrt.sh` script.  The simplest way to get
this into the right place in the app is to download the file directly from the
GitHub repository straight into the OpenShift app data directory where
the OS Terrain 50 dataset has just been unpacked:  
`wget https://github.com/patrickbwarren/survex-tools/raw/master/altitude/rebuild_vrt.sh \
$OPENSHIFT_DATA_DIR`

Now run the script with `.\rebuild_vrt.sh`.  You should see a few
messages appearing, and output from the `gdalbuildvrt` command.  This
may complain about the 'heterogenous band characteristics' of
`NR33.asc` (in the 2014 dataset at least) but the entries are all 0
anyway (the complaint can be fixed by editing the `NR33.asc` file).
Anyway, after this the data directory should contain the files
`GB_template.vrt`, `GB.txt`, `GB_version`, and `GB.vrt`.

If you now navigate to the app home page, you should be able to process NGRs.

### Notes

As in the vanilla DIY cartridge, the app uses a lightweight Ruby
WEBrick server as middleware to run a perl script, `process.pl`, which
issues `gdallocationinfo` commands against the OS Terrain 50 dataset,
prepared in the `.vrt` format as described above.

The perl script contains a couple of subroutines to parse 6-, 8- and
10-fig NGRs into numeric 12-fig form suitable to pass onto
`gdallocationinfo`.  These routines and the associated data structures
have been copied and lightly modified from the CPAN package
[`Geo::Coordinates::OSGB`](https://metacpan.org/pod/Geo::Coordinates::OSGB
"metaCPAN link") (copyright &copy; 2002-2013 Toby Thurston).  The
decision to copy these into the perl script rather than install the
full perl package was made for purely pragmatic reasons: (1) only this
tiny part of the full functionality of `Geo::Coordinates::OSGB` is
required, and (2) some minor changes were necessary to parse 8- and
10-fig NGRs.

### Copying

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see
<http://www.gnu.org/licenses/>.

### Copyright

This program is copyright &copy; 2015 Patrick B Warren unless stated otherwise.
