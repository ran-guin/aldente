#!/usr/local/bin/perl

use strict;
use DBI;

use FindBin;
use lib $FindBin::RealBin . "/../../lib/perl/";         # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../../lib/perl/Core/";         # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../../lib/perl/Imported/";         # add the local directory to the lib search path

use RGTools::RGIO;

use vars qw($opt_help $opt_quiet);

use Getopt::Long;
&GetOptions(
	    'help'                  => \$opt_help,
	    'quiet'                 => \$opt_quiet,
	    ## 'parameter_with_value=s' => \$opt_p1,
	    ## 'parameter_as_flag'      => \$opt_p2,
	    );

my $help  = $opt_help;
my $quiet = $opt_quiet;

my $host = 'lims02';
my $dbase = 'sequence';
my $user = 'rguin';
my $pwd;

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


my @new_plates = $dbc->Table_find('Plate','Plate_ID,Plate_Number',"WHERE FK_Employee__ID = 4 and Plate_Created like '2008-03-10%'");

my $count = 0;
foreach my $new_plate (@new_plates) {
    my ($id,$num) = split ',', $new_plate;
    print "i** Pla $id - FANC1 $num **\n";
    my $new_format = $dbc->Table_update('Plate','FK_Plate_Format__ID',16,"WHERE Plate_ID = $id");

    my ($old_id) = $dbc->Table_find('Plate','Plate_ID',"WHERE FK_Library__Name = 'FANC1' AND Plate_Number = $num AND FKOriginal_Plate__ID=Plate_ID");

    my $new_origPS =  $dbc->Table_update('Plate_Sample','FKOriginal_Plate__ID',$id,"WHERE FKOriginal_Plate__ID=$old_id");
    print "set new PS_orig: ($new_origPS); ";

    my $new_origCS = $dbc->Table_update('Clone_Sample','FKOriginal_Plate__ID',$id,"WHERE FKOriginal_Plate__ID=$old_id");
    print "new CS_orig: ($new_origCS); ";

    my $par1 = $dbc->Table_update_array('Plate',['FKParent_Plate__ID'],[$id],"WHERE Plate_ID=$old_id");
    my $par2 = $dbc->Table_update_array('Plate',['FKParent_Plate__ID'],[0],"WHERE Plate_ID=$id");
    print "swapped parents ($par1,$par2); "; 
    my $orig = $dbc->Table_update_array('Plate',['FKOriginal_Plate__ID'],[$id],"WHERE FKOriginal_Plate__ID=$old_id");
    print "new orig: ($orig); ";

    my $parents = $dbc->Table_update('Plate','FKParent_Plate__ID',$id,"WHERE FKParent_Plate__ID=$old_id AND FK_Plate_Format__ID=47");
    print "new parents for Greiner: ($parents)\n";
    $count++;
}

print "Fixed FANC1 1..$count\n";

exit;

#############
sub help {
#############

    print <<HELP;

Usage:
*********

    <script> [options]

Mandatory Input:
**************************

Options:
**************************     


Examples:
***********

HELP

}
