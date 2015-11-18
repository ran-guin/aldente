#!/usr/bin/perl

#
# About
# -------
# This script was written to fix plates referenced in JIRA ticket LIMS-1095
#

use strict;
use Getopt::Long;
use Data::Dumper;
use DBI;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Core/";
use lib $FindBin::RealBin . "/../lib/perl/Imported/";
use SDB::CustomSettings;
use SDB::DBIO;
use RGTools::RGIO;
use alDente::SDB_Defaults;
use alDente::Barcoding;
use alDente::Library_Plate_Set;

use vars qw($opt_db $opt_user $opt_password $opt_trays $opt_help);

# process command line options
&GetOptions(
    'help'                  => $opt_help,
    'db=s'                  => $opt_db,
    'user=s'                => $opt_user,
    'password=s'            => $opt_password,
    'trays=s'               => $opt_trays,
);

my $dbase    = $opt_db;
my $user     = $opt_user;
my $password = $opt_password;
my $trays    = $opt_trays;     # comma separated list of tray ids
my $help     = $opt_help;

if ($help) {
    help();
    exit;
}

unless ($dbase && $user && $password && $trays) {
    print "Missing parameters.\n";
    help();
    exit;
}

# unless (try_system_command("whoami") =~ /sequence/) {
#     print "You must log in as 'sequence' user to run this script.\n";
#     help();
#     exit;
# }

# connect to the database
my $dbc = SDB::DBIO->new(-dbase=>$dbase,-host=>'lims02',-user=>$user,-password=>$password,-connect=>0);
$dbc->connect();

# repair each tray

my @tray_ids = split ",", $trays;

foreach my $tray_id (@tray_ids) {

    # get records from Plate_Tray table
    my @rows = $dbc->Table_find('Plate_Tray', 'FK_Plate__ID', "WHERE FK_Tray__ID = $tray_id");

    # check that there is only a single record
    if (int(@rows) > 1) {
        print "Error: Tray $tray_id has more than one plate...Skipping\n";
        next;
    }

    # get the parent plate for the single plate in the tray
    my $tray_plate_id   = $rows[0];

    print "Found $tray_plate_id\n";

    my $result = join ",", $dbc->Table_find( 'Plate',
                                   'FKParent_Plate__ID, FK_Employee__ID, FK_Plate_Format__ID, FK_Rack__ID, FK_Pipeline__ID',
                                   "WHERE Plate_ID = $tray_plate_id");

    my ( $parent_plate_id, $employee_id, $plate_format_id, $rack_id, $pipeline_id )
        = split ',', $result;

    print "Parent: $parent_plate_id\n";
    print "Employee: $employee_id\n";
    print "Format: $plate_format_id\n";
    print "Rack: $rack_id\n";
    print "Pipeline: $pipeline_id\n";

    # aliquot the parent plate into a plate that matches the tray's plate
    # Library_Plate_Set transfer() as called from Prep::_transfer()
    my $set          = alDente::Library_Plate_Set->new( -dbc=>$dbc, -ids=>$parent_plate_id );

    my $new_plate_id = $set->transfer( -type        => 'aliquot',
                                       -ids         => $parent_plate_id,
                                       -format      => $plate_format_id,
                                       -rack        => $rack_id,
                                       -pipeline_id => $pipeline_id );
    
    # update the new plate's stats to match the tray's plate
    my @fields     = ( 'FK_Employee__ID' );
    my @values     = ( $employee_id );
    my $updated_ok = $dbc->Table_update_array( -table     => 'Plate',
                                               -fields    => \@fields,
                                               -values    => \@values,
                                               -condition => "WHERE Plate_ID = $new_plate_id" );

    if   (!$updated_ok) { print "Error updating plate $new_plate_id\n"; }
    else                { print "Plate $new_plate_id updated\n";        }

    # add new record to Plate_Tray table in quadrant 'b'
    my $ok = $dbc->Table_append_array( -table     => 'Plate_Tray',
                                       -fields    => [ 'FK_Plate__ID', 'FK_Tray__ID', 'Plate_Position' ],
                                       -values    => [  $new_plate_id,  $tray_id,     'b'              ],
                                       -autoquote => 1 );

}

print "Fini!\n";

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
