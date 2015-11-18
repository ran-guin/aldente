#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

fix_plates.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>system_variables           #<BR>standard_modules_ref       #<BR>

=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use DBI;
use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../../lib/perl/";             # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../../lib/perl/Core/";        # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../../lib/perl/Imported/";    # add the local directory to the lib search path
use Getopt::Long;

use RGTools::RGIO;
use SDB::DBIO;
use SDB::HTML;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($opt_D $opt_u $opt_p $opt_P $opt_L $opt_N $opt_C);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my $dbase = 'seqdev';
my $host  = 'limsdev04';
my $user  = 'aldente_admin';

my $dbc = new SDB::DBIO(
    -host  => $host,
    -dbase => $dbase,
    -user  => $user,

    #    -password => $pwd,
    -connect => 1,
);

### Step 1

my @results = $dbc->Table_find( 'ReArray', 'COUNT(*)', " WHERE FK_Sample__ID = -1" );
Message "Number of records with -1 as FK_Sample__ID for ReArray: " . $results[0];
my $ok = $dbc->Table_update_array( 'Plate_Sample,ReArray,ReArray_Request,Sample',
 ['ReArray.FK_Sample__ID'], 
 ['Sample.FKParent_Sample__ID'], 
"where ReArray_Request.FKTarget_Plate__ID = Plate_Sample.FKOriginal_Plate__ID and ReArray_Request_ID = FK_ReArray_Request__ID and ReArray.FK_Sample__ID = -1 
and Sample_ID = Plate_Sample.FK_Sample__ID and Sample.FKParent_Sample__ID > 0 and ReArray_Type = 'Extraction ReArray' and Target_Well = Plate_Sample.Well");
Message "Updated $ok records";

### Step 2

my @results = $dbc->Table_find( 'ReArray', 'COUNT(*)', " WHERE FK_Sample__ID = -1" );
Message "Number of records with -1 as FK_Sample__ID for ReArray: " . $results[0];
my $ok = $dbc->Table_update_array( 'Plate_Sample,ReArray', ['ReArray.FK_Sample__ID'], ['Plate_Sample.FK_Sample__ID'], "WHERE FKOriginal_Plate__ID = FKSource_Plate__ID and   ReArray.FK_Sample__ID = -1 AND Source_Well = 'N/A'" );
Message "Updated $ok records";

### Step 3

my @results = $dbc->Table_find( 'ReArray', 'COUNT(*)', " WHERE FK_Sample__ID = -1" );
Message "Number of records with -1 as FK_Sample__ID for ReArray: " . $results[0];
my $ok = $dbc->Table_update_array( 'Plate_Sample,ReArray', ['ReArray.FK_Sample__ID'], ['Plate_Sample.FK_Sample__ID'], "WHERE FKOriginal_Plate__ID = FKSource_Plate__ID and   ReArray.FK_Sample__ID = -1 AND Source_Well <> 'N/A' AND Source_Well = Well" );
Message "Updated $ok records";

### Step 4

my @results = $dbc->Table_find( 'ReArray', 'COUNT(*)', " WHERE FK_Sample__ID = -1" );
Message "Number of records with -1 as FK_Sample__ID for ReArray: " . $results[0];
my $ok = $dbc->Table_update_array(
    'ReArray , Plate, Plate_Sample',
    ['ReArray.FK_Sample__ID'],
    ['Plate_Sample.FK_Sample__ID'],
    "WHERE  ReArray.FK_Sample__ID = -1 AND  FKSource_Plate__ID = Plate_ID AND Plate.FKOriginal_Plate__ID = Plate_Sample.FKOriginal_Plate__ID AND Source_Well = 'N/A' AND Source_Well = Well"
);
Message "Updated $ok records";


### Step 5

my @results = $dbc->Table_find( 'ReArray', 'COUNT(*)', " WHERE FK_Sample__ID = -1" );
Message "Number of records with -1 as FK_Sample__ID for ReArray: " . $results[0];
my $ok = $dbc->Table_update_array(
    'ReArray , Plate, Plate_Sample',
    ['ReArray.FK_Sample__ID'],
    ['Plate_Sample.FK_Sample__ID'],
    "WHERE  ReArray.FK_Sample__ID = -1 AND  FKSource_Plate__ID = Plate_ID AND Plate.FKOriginal_Plate__ID = Plate_Sample.FKOriginal_Plate__ID AND Source_Well <> 'N/A' AND Source_Well = Well"
);
Message "Updated $ok records";
my @results = $dbc->Table_find( 'ReArray', 'COUNT(*)', " WHERE FK_Sample__ID = -1" );
Message "Number of records with -1 as FK_Sample__ID for ReArray: " . $results[0];

exit;

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: fix_plates.pl,v 1.5 2004/06/03 18:12:15 achan Exp $ (Release: $Name:  $)

=cut

