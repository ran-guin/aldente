#!/usr/local/bin/perl

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
use alDente::Invoice;

use vars qw($opt_help $opt_host $opt_dbase $opt_user $opt_pwd $opt_work $opt_prep);

&GetOptions(
    'help'    => \$opt_help,
    'dbase=s' => \$opt_dbase,
    'host=s'  => \$opt_host,
    'user=s'  => \$opt_user,
    'pwd=s'   => \$opt_pwd,
);

my $help  = $opt_help;
my $host  = $opt_host || 'limsdev04';
my $dbase = $opt_dbase || 'seqdev';
my $user  = $opt_user || 'unit_tester';
my $pwd   = $opt_pwd || 'unit_tester';


require SDB::DBIO;
my $dbc = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pwd,
    -connect  => 1,
);

my @dup_run;

################################
# Handling the duplicate run record second
################################
@dup_run = $dbc->Table_find_array(
    "Invoiceable_Work, Invoiceable_Run, Invoiceable_Work_Reference",
    [ 'Invoiceable_Run.FK_Run__ID', 'MIN(Invoiceable_Work.Invoiceable_Work_ID)', 'COUNT(DISTINCT Invoiceable_Work.Invoiceable_Work_ID)', 'MAX(Invoiceable_Work_Reference.FK_Invoice__ID)', 'MAX(Invoiceable_Work_Reference.Billable)' ],
    "WHERE Invoiceable_Run.FK_Invoiceable_Work__ID = Invoiceable_Work.Invoiceable_Work_ID
    AND Invoiceable_Work.Invoiceable_Work_ID = Invoiceable_Work_Reference.FKReferenced_Invoiceable_Work__ID
    GROUP BY Invoiceable_Run.FK_Run__ID
    HAVING COUNT(DISTINCT Invoiceable_Work.Invoiceable_Work_ID) > 1"
);

foreach my $run_info (@dup_run) {
    my ( $run_id, $iw_id, $indexed, $invoice_id, $billable ) = split ',', $run_info;

    # Find all the Parent Invoiceable_Work_Reference ids
    my @iwr_id = $dbc->Table_find_array(
        "Invoiceable_Work, Invoiceable_Work_Reference, Invoiceable_Run",
        ['Invoiceable_Work_Reference.Invoiceable_Work_Reference_ID'],
        "WHERE Invoiceable_Run.FK_Invoiceable_Work__ID = Invoiceable_Work.Invoiceable_Work_ID
        AND Invoiceable_Work.Invoiceable_Work_ID = Invoiceable_Work_Reference.FKReferenced_Invoiceable_Work__ID
        AND Invoiceable_Run.FK_Run__ID = $run_id"
    );

    my $invoiced = 'No';
    if ($invoice_id) { $invoiced = 'Yes'; }

    my ($iwr_id) = $dbc->Table_append_array(
        'Invoiceable_Work_Reference',
        [ 'Invoiceable_Work_Reference_ID', 'FK_Source__ID', 'Indexed', 'FKReferenced_Invoiceable_Work__ID', 'FK_Invoice__ID', 'Billable', 'FKParent_Invoiceable_Work_Reference__ID', 'Invoiceable_Work_Reference_Invoiced' ],
        [ undef,                           undef,           undef,     $iw_id,                              undef,            $billable,  undef,                                     $invoiced ],
        -autoquote => 1
    );

    print Message("Run ID: $run_id, Primary IW: $iw_id, New Parent IWR: $iwr_id");

    # Reassigning IWR Parents, IW Reference, and Indexes
    my $reassigned_ids = '';
    my $reassigned_counter = 0;
    foreach my $iwr_info (@iwr_id) {
        my ($updated) = $dbc->Table_update_array(
            'Invoiceable_Work_Reference',
            [ 'FKParent_Invoiceable_Work_Reference__ID', 'FKReferenced_Invoiceable_Work__ID', 'Indexed' ],
            [ $iwr_id,                                   $iw_id,                              $indexed ],
            "WHERE Invoiceable_Work_Reference_ID = $iwr_info",
            -autoquote => 1
        );
        $reassigned_counter += $updated;
        $reassigned_ids .= "$iwr_info,";
    }
    print Message("Reassigned IDs: $reassigned_ids");
    print Message("$reassigned_counter items reassigned.");

    # Deleting duplicate IW and Invoiceable_Run records
    my @deleted_iw = $dbc->Table_find_array(
        "Invoiceable_Work, Invoiceable_Run",
        [ 'Invoiceable_Work_ID', 'Invoiceable_Run_ID', 'FK_Run__ID' ],
        "WHERE Invoiceable_Work_ID = FK_Invoiceable_Work__ID
        AND Invoiceable_Work_ID <> $iw_id
        AND FK_Run__ID = $run_id"
    );

    foreach my $deleted_iw_info (@deleted_iw) {
        my ( $deleted_iw_id, $deleted_iw_run_id, $assoc_run_ID ) = split ',', $deleted_iw_info;
	
        $dbc->delete_record( -table => 'Invoiceable_Run',  -field => 'Invoiceable_Run_ID',  -value => "$deleted_iw_run_id" );
        $dbc->delete_record( -table => 'Invoiceable_Work', -field => 'Invoiceable_Work_ID', -value => "$deleted_iw_id" );

        print Message("deleted_iw: $deleted_iw_id deleted iw_run: $deleted_iw_run_id Associated Run: $assoc_run_ID");
    }
}

print Message("Clean up Complete");
exit;

##########################
sub help {
##########################

    print <<HELP;

Usage:
*********

    Remove duplicate Invoiceable_Work

    This is a script used to clean up duplicate work items which were caused by the problem outlined in LIMS-11652

    
Options:
**************************     
    -host
    -base
    -user
    -pwd

Examples:
***********
 
HELP

}
