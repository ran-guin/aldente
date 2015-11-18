#!/usr/local/bin/perl

use strict;
use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use Getopt::Long;

use SDB::DBIO;
use SDB::CustomSettings;
use RGTools::RGIO;

#### This script creates a virtual original plate for each specified original plate. This allows the user to keep the same samples and plate numbers.

### Global variables
use vars qw($Connection);
###################################

# if script itself is running elsewhere, quit
my $command           = "ps axw | grep 'create_virtual_original.pl' | grep  -v ' 0:00 ' | grep -v ' 0:01 ' | grep -v 'emacs'";
my $current_processes = `$command`;
if ($current_processes) {
    print "** already in process **\n";
    print "-> $current_processes\n";
    exit;
}

my ( $opt_user, $opt_dbase, $opt_host, $opt_password, $opt_run, $opt_plates );

&GetOptions(
    'user=s'     => \$opt_user,
    'dbase=s'    => \$opt_dbase,
    'host=s'     => \$opt_host,
    'password=s' => \$opt_password,
    'plates=s'   => \$opt_plates
);

&help_menu() if ( !( $opt_dbase && $opt_user && $opt_password && $opt_host && $opt_plates ) );

my $dbc = SDB::DBIO->new(
    -dbase    => $opt_dbase,
    -user     => $opt_user,
    -password => $opt_password,
    -host     => $opt_host
);
$dbc->connect();

my $VIRTUAL_96_FORMAT_ID  = 16;
my $VIRTUAL_384_FORMAT_ID = 18;

my $plate_str = &resolve_range($opt_plates);
my @plate_ids = split( ',', $plate_str );

foreach my $plate_id (@plate_ids) {

    my ($orig_plate) = $dbc->Table_find( "Plate", "FKOriginal_Plate__ID", "WHERE Plate_ID = $plate_id" );
    if ( $orig_plate != $plate_id ) {
        print "ERROR: Invalid argument: Plate $plate_id is not an original plate. Skipping...\n";
        next;
    }
    my ($plate_size) = $dbc->Table_find( "Plate", "Plate_Size", "WHERE Plate_ID = $plate_id" );
    my $virtual_plate_format;
    if ( $plate_size =~ /96/ ) {
        ## if plate_size is 96, assume that the
        $virtual_plate_format = $VIRTUAL_96_FORMAT_ID;
    }
    else {

        # if the plate size is not 96, assume that it is 384-well
        $virtual_plate_format = $VIRTUAL_384_FORMAT_ID;
    }
    my ( $newid, $copy_time ) = $dbc->Table_copy( 'Plate', "WHERE Plate_ID in ($plate_id)", [ 'Plate_ID', 'FK_Plate_Format__ID' ], '', [ undef, $virtual_plate_format ] );
    $dbc->Table_copy( 'Library_Plate', "WHERE FK_Plate__ID in ($plate_id)", [ 'Library_Plate_ID', 'FK_Plate__ID' ], '', [ undef, $newid ] );
    $dbc->Table_update_array( "Plate",        ['FKOriginal_Plate__ID'], [$newid], "WHERE FKOriginal_Plate__ID=$plate_id" );
    $dbc->Table_update_array( "Plate",        ['FKParent_Plate__ID'],   [$newid], "WHERE Plate_ID=$plate_id" );
    $dbc->Table_update_array( "Clone_Sample", ['FKOriginal_Plate__ID'], [$newid], "WHERE FKOriginal_Plate__ID=$plate_id" );
    $dbc->Table_update_array( "Plate_Sample", ['FKOriginal_Plate__ID'], [$newid], "WHERE FKOriginal_Plate__ID=$plate_id" );
    my ($emp) = $dbc->Table_find( "Plate", "FK_Employee__ID", "WHERE Plate_ID = $plate_id" );
    my ($create_time) = $dbc->Table_find( "Plate", "Plate_Created", "WHERE Plate_ID = $plate_id", -date_format => 'SQL' );
    my $prep_id = $dbc->Table_append_array( "Prep", [ 'Prep_Name', "FK_Employee__ID", 'Prep_DateTime', 'FK_Lab_Protocol__ID' ], [ "Transfer", $emp, $create_time, 7 ], -autoquote => 1 );
    $dbc->Table_append_array( "Plate_Prep", [ 'FK_Plate__ID', 'FK_Prep__ID' ], [ $newid, $prep_id ] );
    print "New original id for $plate_id: $newid\n";
}

exit(0);

sub help_menu {
    print "Run script like this:\n\n";
    print "$0\n";
    print "  \t-dbase (e.g. sequence)\n";
    print "  \t-user  (e.g. viewer)\n";
    print "  \t-password\n";
    print "  \t-host  (e.g. lims02)\n";
    print "  \t-plates  (e.g. 2000,2001)\n";
    exit(0);
}
