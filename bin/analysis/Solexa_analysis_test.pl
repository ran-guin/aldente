#!/usr/local/bin/perl

use strict;
use warnings;

use DBI;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
use SDB::CustomSettings;
use Sequencing::Solexa_Analysis;
use alDente::Run;

use alDente::SDB_Defaults;
use alDente::Notification;

use Data::Dumper;
use Getopt::Long;

use vars qw($opt_help $opt_quiet $opt_run_id $opt_lanes $opt_fc $opt_version $opt_cycles $opt_gerald $opt_single);

&GetOptions(
    'help'      => \$opt_help,
    'quiet'     => \$opt_quiet,
    'run_id=s'  => \$opt_run_id,
    'lanes=s'   => \$opt_lanes,
    'fc=s'      => \$opt_fc,
    'version=s' => \$opt_version,
    'cycles=s'  => \$opt_cycles,
    'gerald'    => \$opt_gerald,
    'single'    => \$opt_single
        ## 'parameter_with_value=s' => \$opt_p1,
        ## 'parameter_as_flag'      => \$opt_p2,
);

my $help       = $opt_help;
my $quiet      = $opt_quiet;
my $run_id     = $opt_run_id;
my $lanes_list = $opt_lanes;
my $flowcell   = $opt_fc or die "Flowcell code must be provided.";
my $version    = $opt_version || 'current';
my $cycles     = $opt_cycles || '1-27';
my $gerald     = $opt_gerald;
my $single     = $opt_single;

my $host  = $Configs{PRODUCTION_HOST};
my $dbase = $Configs{PRODUCTION_DATABASE};
my $user  = 'super_cron';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -connect  => 1,
);

#my $flowcell_dir = '/archive/solexa1_2/data2/070404_SOLEXA1_0030_FC4025';
#if (-e "$flowcell_dir/Run.completed" && (!(-e "$flowcell_dir/Analysis.started"))) {

#MAKE NEW SOLEXA ANALYSIS OBJECT HERE

my $self = new Sequencing::Solexa_analysis(
    -dbc      => $dbc,
    -lanes    => $lanes_list,
    -flowcell => $flowcell,
    -version  => $version,
    -cycles   => $cycles,
    -gerald   => $gerald,
    -single   => $single
);
$self->get_run_info();
$self->run_goat();
$self->run_analysis();

#open(START, ">$flowcell_dir/Analysis.started") || die "Can't open analysis.started\n";
#print START "Image analysis for $flowcell started";
#close START;
#}
#else {print "Analysis already started or Run not completed";}

exit;

