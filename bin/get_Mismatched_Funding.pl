#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

################################################################################
#
# check_Mismatched_Funding.pl
#
# This program checks invoiceable work items created since a given date (or within
# the same day if not specified and makes sure that the applicable funding for the
# work matches the funding from the associated work request.
#
################################################################################

#######################################################################################
## Standard Template for building cron jobs or scripts that connect to the database ###
#######################################################################################
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../lib/perl/LampLite";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";

########################
## Local Core modules ##
########################
use CGI;
use Data::Dumper;
use Benchmark;

##########################
## Local custom modules ##
##########################
use RGTools::RGIO;
use RGTools::Process_Monitor;
use LampLite::Bootstrap;

use SDB::DBIO;    ## use to connect to database

use alDente::Config;    ## use to initialize configuration settings

## Globals ##
my $q               = new CGI;
my $BS              = new Bootstrap();
my $start_benchmark = new Benchmark();

$| = 1;
##############################################################
## Temporary - phase out globals gradually as defined below ##
##############################################################
use vars qw(%Configs);    ### phase out global, but leave in for now .... replace with $dbc->config() ... need to also expand config list as done in SDB/Custom_Settings currently...
###############################################################

####################################################################################################
###  Configuration Loading - use this block (and section above) for both bin and cgi-bin files   ###
####################################################################################################
my $Setup = new alDente::Config( -initialize => 1, -root => $FindBin::RealBin . '/..' );

my $configs = $Setup->{configs};

%Configs = $configs;      ## phase out global, but leave in for now ....
###################################################
## END OF Standard Module Initialization Section ##
###################################################

## Load input parameter options ##
#
## (replace section below with required input parameters as required) ##
#
use vars qw($opt_help $opt_host $opt_quiet $opt_dbase $opt_since %Configs);

use Getopt::Long;
&GetOptions(
    'help'    => \$opt_help,
    'quiet'   => \$opt_quiet,
    'dbase=s' => \$opt_dbase,
    'host=s'  => \$opt_host,
    'since=s' => \$opt_since,    ## if not specified, defaults to invoiceable work items created today.
);

my $dbase = $opt_dbase || $configs->{PRODUCTION_DATABASE};
my $host  = $opt_host  || $configs->{PRODUCTION_HOST};
my $test  = $opt_debug;
my $db_user = 'super_cron_user';                                           ## use super_cron_user if requiring write access (or repl_client to run database restoration scripts)
my $date = $opt_since || ( substr( date_time(), 0, 10 ) . ' 00:00:00' );

my $help  = $opt_help;
my $quiet = $opt_quiet;

my $Report = Process_Monitor->new();
if ( !$Report->write_lock() ) {
    $Report->set_Message("This script is locked.");
    $Report->DESTROY();
    exit;
}

my $dbc = new SDB::DBIO(
    -host    => $host,
    -dbase   => $dbase,
    -user    => $db_user,
    -connect => 1,
);

## Find all invoiceable work items created since a specified date
my @invoiceable_works = $dbc->Table_find_array( 'Invoiceable_Work', ['Invoiceable_Work_ID'], "WHERE Invoiceable_Work_DateTime >= '$date'" );

print "*" x 50 . "\n";
print int(@invoiceable_works) . " total Invoiceable Work items created on or after $date\n";

my @mismatched_funding;       ## items whose applicable funding <> funding from work request (neither are null)
my @no_work_request;          ## items with no work request, but have applicable funding
my @no_applicable_funding;    ## items with a work request, but no applicable funding
my @no_funding;               ## items that have neither applicable funding nor associated work request
foreach my $iw (@invoiceable_works) {
    my ($funding_from_wr)    = $dbc->Table_find( 'Work_Request, Plate, Invoiceable_Work', 'FK_Funding__ID',           "WHERE Plate.FK_Work_Request__ID = Work_Request_ID AND Invoiceable_Work.FK_Plate__ID = Plate_ID AND Invoiceable_Work_ID = $iw" );
    my ($applicable_funding) = $dbc->Table_find( 'Invoiceable_Work_Reference',            'FKApplicable_Funding__ID', "WHERE FKReferenced_Invoiceable_Work__ID = $iw" );
    if ( !$funding_from_wr && !$applicable_funding ) {
        push @no_funding, $iw;
    }
    elsif ( !$funding_from_wr ) {
        push @no_work_request, $iw;
    }
    elsif ( !$applicable_funding ) {
        push @no_applicable_funding, $iw;
    }
    elsif ( $funding_from_wr ne $applicable_funding ) {
        push @mismatched_funding, $iw;
    }
}
if ( @mismatched_funding || @no_funding || @no_applicable_funding ) {
    if (@mismatched_funding) {
        my $mismatch_string = Cast_List( -list => \@mismatched_funding, -to => 'string' );

        my @mismatched_libs = $dbc->Table_find_array( 'Invoiceable_Work, Plate', ['FK_Library__Name'], "WHERE FK_Plate__ID = Plate_ID AND Invoiceable_Work_ID IN ($mismatch_string)", -distinct => 1 );

        $Report->set_Message("The following libraries have work items with mismatched funding: @mismatched_libs");
    }
    if (@no_funding) {
        my $no_funding_string = Cast_List( -list => \@no_funding, -to => 'string' );

        my @no_funding_libs = $dbc->Table_find_array( 'Invoiceable_Work, Plate', ['FK_Library__Name'], "WHERE FK_Plate__ID = Plate_ID AND Invoiceable_Work_ID IN ($no_funding_string)", -distinct => 1 );

        $Report->set_Message("The following libraries have work items with no work request and no applicable funding: @no_funding_libs");
    }
    if (@no_applicable_funding) {
        my $no_app_funding_string = Cast_List( -list => \@no_applicable_funding, -to => 'string' );

        my @no_app_funding_libs = $dbc->Table_find_array( 'Invoiceable_Work, Plate', ['FK_Library__Name'], "WHERE FK_Plate__ID = Plate_ID AND Invoiceable_Work_ID IN ($no_app_funding_string)", -distinct => 1 );

        $Report->set_Message("The following libraries have work items with work requests but no applicable funding: @no_app_funding_libs");
    }
}
else {
    ## All invoiceable items checked have matching applicable funding and funding from their work requests
    $Report->set_Message("No mismatched fundings were found.");
}

$Report->succeeded();
$Report->completed();
$Report->DESTROY();

exit;

