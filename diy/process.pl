#!/usr/bin/env perl

use strict;
use warnings;

# Perl script to return a list of altitudes ODN from NGRs.

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

#### Start of copied code from Geo::Coordinates::OSGB ####

# The subroutines parse_grid and _parse_grid, and associated hashes
# BIG_OFF and SMALL_OFF, and constants BIG_SQUARE and SQUARE, and the
# NGR regex patterns are copied and modified from the CPAN package
# Geo::Coordinates::OSGB (copyright (C) 2002-2013 Toby Thurston), in
# accordance with the licence condition for that package.

my %BIG_OFF = ( # copyright (C) 2002-2013 Toby Thurston
              G => { E => -1, N => 2 },
              H => { E =>  0, N => 2 },
              J => { E =>  1, N => 2 },
              M => { E => -1, N => 1 },
              N => { E =>  0, N => 1 },
              O => { E =>  1, N => 1 },
              R => { E => -1, N => 0 },
              S => { E =>  0, N => 0 },
              T => { E =>  1, N => 0 },
           );

my %SMALL_OFF = ( # copyright (C) 2002-2013 Toby Thurston
                 A => { E =>  0, N => 4 },
                 B => { E =>  1, N => 4 },
                 C => { E =>  2, N => 4 },
                 D => { E =>  3, N => 4 },
                 E => { E =>  4, N => 4 },

                 F => { E =>  0, N => 3 },
                 G => { E =>  1, N => 3 },
                 H => { E =>  2, N => 3 },
                 J => { E =>  3, N => 3 },
                 K => { E =>  4, N => 3 },

                 L => { E =>  0, N => 2 },
                 M => { E =>  1, N => 2 },
                 N => { E =>  2, N => 2 },
                 O => { E =>  3, N => 2 },
                 P => { E =>  4, N => 2 },

                 Q => { E =>  0, N => 1 },
                 R => { E =>  1, N => 1 },
                 S => { E =>  2, N => 1 },
                 T => { E =>  3, N => 1 },
                 U => { E =>  4, N => 1 },

                 V => { E =>  0, N => 0 },
                 W => { E =>  1, N => 0 },
                 X => { E =>  2, N => 0 },
                 Y => { E =>  3, N => 0 },
                 Z => { E =>  4, N => 0 },
           );

# copyright (C) 2002-2013 Toby Thurston
use constant BIG_SQUARE => 500_000; 
use constant SQUARE     => 100_000; 

# modified from original copyright (C) 2002-2013 Toby Thurston
my $NGR_6_FIG = qr{ \A ([GHJMNORST][A-Z]) \s? (\d{3}) \D? (\d{3}) \Z }smiox;
my $NGR_8_FIG = qr{ \A ([GHJMNORST][A-Z]) \s? (\d{4}) \D? (\d{4}) \Z }smiox;
my $NGR_10_FIG  = qr{ \A ([GHJMNORST][A-Z]) \s? (\d{5}) \D? (\d{5}) \Z }smiox;

sub parse_grid { # modified from original copyright (C) 2002-2013 Toby Thurston
    my $s = "@_";
    if ( $s =~ $NGR_6_FIG ) {
        return _parse_grid($1, $2*100, $3*100)
    }
    if ( $s =~ $NGR_8_FIG ) {
        return _parse_grid($1, $2*10, $3*10)
    }
    if ( $s =~ $NGR_10_FIG ) {
        return _parse_grid($1, $2, $3)
    }
    return (0, 0);
}

sub _parse_grid { # copyright (C) 2002-2013 Toby Thurston
    my ($letters, $e, $n) = @_;

    return if !defined wantarray;

    $letters = uc $letters;

    my $c = substr $letters,0,1;
    $e += $BIG_OFF{$c}->{E}*BIG_SQUARE;
    $n += $BIG_OFF{$c}->{N}*BIG_SQUARE;

    my $d = substr $letters,1,1;
    $e += $SMALL_OFF{$d}->{E}*SQUARE;
    $n += $SMALL_OFF{$d}->{N}*SQUARE;

    return ($e, $n);
}

#### End of copied code from Geo::Coordinates::OSGB ####

my $max_lines = 200;
my $openshift_data_dir = $ENV{'OPENSHIFT_DATA_DIR'};
my $vrt_template = $openshift_data_dir . "GB_template.vrt";
my $vrt_version = $openshift_data_dir . "GB_version";
my $gdal_file = $openshift_data_dir . "GB.vrt";
my $lock_file = $openshift_data_dir . "lock";
my $gdal_exe = "/usr/bin/gdallocationinfo";

my ($ngr, $e, $n, $alt);
my ($command, $ans);

# If there is a version mismatch or a missing file then we need to
# regenerate the GB.vrt file from the template.  This is because the
# vrt file contains absolute paths which may change if the instance is
# rebooted.  We tag the version by the openshift data directory path
# at the time of generation.  To do the test, we compare this tag with
# the current path.

my $current = `cd $openshift_data_dir; pwd`; chomp($current);

my $existing = ""; # Falls through if the files are missing

if (-e $vrt_version && -e $gdal_file) {
    $existing = `cat $vrt_version`; chomp($existing); 
}

# If there is a mismatch or a missing files then we regenerate.

if ($current ne $existing) {

    # Test for the presence of a lock, if present bail out.

    if (-e $lock_file) {
	print "<p><p><b>Lock detected whilst attempting to regenerate .vrt file.\n";
	print "&nbsp; Please try again in a few moments.</b></p>\n";
	exit(0);
    }

    # Check that the template is there.

    unless (-e $vrt_template) {
	print "<p><p><b>Missing template whilst attempting to regenerate .vrt file.</b></p>\n";
	print "<p><p><b>This is a catastrophic error and cannot be fixed without admin access to the app.\n";
	print "&nbsp; Please report this to the app owner.</b></p>\n";
	exit(0);
    }

    # Although regeneration should be a pretty fast operation, it
    # may still pay to create a lock file whilst we do it.

    system("touch $lock_file");

    # Regenerate the .vrt file from the template using sed.
    
    $command = "cd $openshift_data_dir; sed s:DATADIR:\$(pwd): $vrt_template > $gdal_file";
    system($command);

    # Update the version and remove the lock (as the final step).
    
    system("cd $openshift_data_dir; pwd > $vrt_version");
    system("rm -f $lock_file");

}

# Now we can get on with processing the list of NGRs.

# additional test data
# Ingleborough summit SD 74227454 = 723
# Growling            SD 71307747 = 390
# Braida Garth road   SD 69977748 = 267
# High Plains Pots    SD 68487685 = 408

print "<h2>Results</h2>\n";
print "<p>The results can be cut & paste\n";
print "into a spreadsheet, splitting on the space as field separator.\n";
print "The second and third columns are the numerical 6-figure\n";
print "Easting and Northing used in the calculation.\n";
print "The final column is the calculated OS Terrain 50 altitude in metres (ODN).\n";
print "</p>\n";
print "<pre>\n";

while ($ngr = <>) {
    last if $. > $max_lines;
    next if ($ngr =~ /^\s*$/);
    chomp($ngr);
    ($e, $n) = parse_grid($ngr);
    if ($e != 0 && $n != 0) {
	$command = "$gdal_exe -geoloc -valonly $gdal_file $e $n";
	$ans = `$command`; chomp($ans);
	$alt = sprintf "%0.0f", 0.0 + $ans;
    } else {
	$alt = "0";
    }
    # get rid of leading and trailing spaces in the NGR and collapse
    # the interword spaces each to a single underscore
    $ngr =~ s/^\s+//; $ngr =~ s/\s+$//; $ngr =~ s/\s+/_/g;
    print $ngr, " ", $e, " ", $n, " ", $alt, "\n";
}

print "</pre>\n";



