#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

################################################################################
#
# set_Library_Status.pl
#
# This program regularly updates the library status.
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
use vars qw($opt_help $opt_host $opt_quiet $opt_library $opt_dbase $opt_set_peripheral_info %Configs);

use Getopt::Long;
&GetOptions(
    'help'                => \$opt_help,
    'quiet'               => \$opt_quiet,
    'library=s'           => \$opt_library,
    'dbase=s'             => \$opt_dbase,
    'host=s'              => \$opt_host,
    'set_peripheral_info' => \$opt_set_peripheral_info,
);

my $dbase = $opt_dbase || $configs->{PRODUCTION_DATABASE};
my $host  = $opt_host  || $configs->{PRODUCTION_HOST};
my $test  = $opt_debug;
my $db_user = 'super_cron_user';    ## use super_cron_user if requiring write access (or repl_client to run database restoration scripts)

my $help                = $opt_help;
my $quiet               = $opt_quiet;
my $library             = $opt_library;
my $set_peripheral_info = $opt_set_peripheral_info || 0;

my $variation = 'basic';
if ($set_peripheral_info) {
    $variation = 'full';
}

my $Report = Process_Monitor->new( -variation => $variation );
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

my @library_list = ();
if ($library) {
    @library_list = split ',', $library;
}
else {
    my @libraries = &Table_find( $dbc, 'Library', 'Library_Name' );
    push @library_list, @libraries;
}

print "*" x 50 . "\n";
print int(@library_list) . " Total Libraries\n";
my ( $closed, $opened, $messages ) = alDente::Library::reset_Status( $dbc, \@library_list, $set_peripheral_info );

# alDente::Goal::set_Library_Status(-dbc=>$dbc, -library=>\@library_list);
my @closed_list  = @$closed;
my @opened_list  = @$opened;
my @message_list = @$messages;

#
#my $mail = "Libraries Changed:<UL>\n";
#foreach my $mess (@message_list) {
#    if ($mess) { $Report->set_Message($mess) }
#    $mail .= "<LI>$mess</LI>\n";
#}
#$mail .= "</UL\n";
#
#if (@$message_list) {
#    alDente::Subscription::send_notification(-dbc=>$dbc,-name=>'Library_Status Updates',-from=>'set_Library_Status <aldente@bcgsc.bc.ca>',
#        -subject=>"Automated Library Status Updates",
#        -body=>"",-content_type=>'html');
#}
#

if (@closed_list) { $Report->set_Message("Closed: @closed_list") }
if (@opened_list) { $Report->set_Message("Opened: @opened_list") }
$Report->succeeded();
$Report->completed();
$Report->DESTROY();

exit;

