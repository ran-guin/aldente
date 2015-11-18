#!/usr/local/bin/perl

use strict;
use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Departments";

use Getopt::Long;

use SDB::DBIO;
use SDB::CustomSettings;
use RGTools::RGIO;

### modules for different runs
use alDente::SpectRun;
use alDente::BioanalyzerRun;
use Lib_Construction::GCOS_Report_Parser;

### Global variables
use vars qw($Connection $aldente_upload_dir);
###################################

# if script itself is running elsewhere, quit
my $command           = "ps axw | grep 'update_run.pl' | grep  -v ' 0:00 ' | grep -v ' 0:01 ' | grep -v 'emacs'";
my $current_processes = `$command`;
if ($current_processes) {
    print "** already in process **\n";
    print "-> $current_processes\n";
    exit;
}

my ( $opt_user, $opt_dbase, $opt_host, $opt_password, $opt_run );

&GetOptions(
    'user=s'     => \$opt_user,
    'dbase=s'    => \$opt_dbase,
    'host=s'     => \$opt_host,
    'password=s' => \$opt_password
);

&help_menu() if ( !( $opt_dbase && $opt_user && $opt_password && $opt_host ) );

my $condition = "where Run_Status = 'In Process' and Run_Type in ('GenechipRun')";

my $dbc = SDB::DBIO->new(
    -dbase    => $opt_dbase,
    -user     => $opt_user,
    -password => $opt_password,
    -host     => $opt_host
);
$dbc->connect();

# search all pending runs
my %runs = $dbc->Table_retrieve(
    -table     => "Run",
    -fields    => [ 'Run_ID', 'Run_Type', 'Run_Directory' ],
    -condition => "$condition",
    -key       => "Run_ID"
);

my $upload_dir = "$aldente_upload_dir/GenechipRun";

#my $upload_dir = "/home/sequence/Trash/gcostest";
my $hostname  = "gcos01.bcgsc.ca";
my $sharename = "gclims";
foreach my $run_id ( sort { $a <=> $b } keys %runs ) {
    my $run_type      = $runs{$run_id}->{'Run_Type'};
    my $run_directory = $runs{$run_id}->{'Run_Directory'};

    my $rpt_command = qq{rsync -v --include="$run_directory*" --exclude="*" "$hostname\:\:$sharename/Data/*RPT" $upload_dir};
    my $jpg_command = qq{rsync -v --include="$run_directory*" --exclude="*" "$hostname\:\:$sharename/Data/*JPG" $upload_dir};

    &try_system_command($rpt_command);
    &try_system_command($jpg_command);
}

exit(0);

sub help_menu {
    print "Run script like this:\n\n";
    print "$0\n";
    print "  \t-dbase (e.g. sequence)\n";
    print "  \t-user  (e.g. viewer)\n";
    print "  \t-password\n";
    print "  \t-host  (e.g. lims02)\n";
    exit(0);
}
