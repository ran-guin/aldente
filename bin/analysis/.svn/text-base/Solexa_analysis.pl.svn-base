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
use Sequencing::SolexaRun;
use alDente::Run;

use alDente::SDB_Defaults;
use alDente::Notification;

use Data::Dumper;
use Getopt::Long;
use vars qw( %Configs );

use vars
    qw($opt_help $opt_quiet $opt_run_id $opt_lane $opt_fc $opt_version $opt_cycles $opt_gerald $opt_single $opt_fc_dir $opt_pwd $opt_volume $opt_matrix $opt_phasing $opt_prephasing $opt_genome $opt_analysis_type $opt_kc $opt_paired $opt_use_bases $opt_analyze_tiles $opt_testing);

&GetOptions(
    'help'            => \$opt_help,
    'quiet'           => \$opt_quiet,
    'run_id=s'        => \$opt_run_id,
    'lane=s'          => \$opt_lane,
    'fc=s'            => \$opt_fc,
    'fc_dir=s'        => \$opt_fc_dir,
    'volume=s'        => \$opt_volume,
    'version=s'       => \$opt_version,
    'cycles=s'        => \$opt_cycles,
    'paired'          => \$opt_paired,
    'gerald'          => \$opt_gerald,
    'kc'              => \$opt_kc,
    'single'          => \$opt_single,
    'pwd=s'           => \$opt_pwd,
    'matrix=s'        => \$opt_matrix,
    'phasing=s'       => \$opt_phasing,
    'prephasing=s'    => \$opt_prephasing,
    'analysis_type=s' => \$opt_analysis_type,
    'genome=s'        => \$opt_genome,
    'use_bases=s'     => \$opt_use_bases,
    'analyze_tiles=s' => \$opt_analyze_tiles,
    'testing'         => \$opt_testing
);

my $help     = $opt_help;
my $quiet    = $opt_quiet;
my $run_id   = $opt_run_id;
my $lane     = $opt_lane;
my $flowcell = $opt_fc or die "Flowcell code must be provided.";

#my $flowcell_dir = $opt_fc_dir or die "Flowcell dir must be provided.";

my @flowcell_dir = Sequencing::Solexa_analysis::find_flowcell_dir($flowcell);

my $flowcell_dir = $flowcell_dir[0];

my $version = $opt_version || 'current';
my $cycles  = $opt_cycles  || 'auto';
my $paired  = $opt_paired;
my $gerald  = $opt_gerald;
my $single  = $opt_single;
my $pwd     = $opt_pwd;
my $kc      = $opt_kc;
my $matrix  = $opt_matrix;
my $phasing = $opt_phasing;
my $prephasing    = $opt_prephasing;
my $genome        = $opt_genome;
my $analysis_type = $opt_analysis_type;
my $testing       = $opt_testing;
my $use_bases     = $opt_use_bases;
my $analyze_tiles = $opt_analyze_tiles;

my $host  = $Configs{PRODUCTION_HOST};
my $dbase = $Configs{PRODUCTION_DATABASE};
my $user  = 'super_cron';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pwd,
    -connect  => 1,
);

if ( -e "$flowcell_dir/Run.completed" ) {

    #MAKE NEW SOLEXA ANALYSIS OBJECT HERE
    my ( $slash, $home, $sequence, $archive, $slx, $one, $volume, $dir ) = split '/', $flowcell_dir;

    ## Check what type of solexa run it is

    my $solexarun_type = Sequencing::SolexaRun::get_solexarun_type( -flowcell => $flowcell, -lane => $lane, -dbc => $dbc );
    if ( $opt_single && $solexarun_type eq 'Paired' ) {
        Message("Performing analysis on a paired read");
    }
    my $current_analysis_id;
    my $pet1_analysis_id;
    my @solexa_analysis_args = (
        -lane          => $lane,
        -flowcell      => $flowcell,
        -volume        => $volume,
        -version       => $version,
        -cycles        => $cycles,
        -paired        => $paired,
        -gerald        => $gerald,
        -matrix        => $matrix,
        -phasing       => $phasing,
        -prephasing    => $prephasing,
        -genome        => $genome,
        -analysis_type => $analysis_type,
        -testing       => $testing,
    );

    my $current_analysis_obj;

    if ( $solexarun_type eq 'Single' ) {
        $current_analysis_obj = new Sequencing::Solexa_analysis(
            -dbc => $dbc,
            @solexa_analysis_args,
            -end_read_type => 'Single',
            -analyze_tiles => $analyze_tiles,
            -kc            => $kc,
            -use_bases     => $use_bases,
        );

        ## create an analysis record for each end read
        my $analysis_id = $current_analysis_obj->prepare_analysis();
        $current_analysis_id = $analysis_id;
        $current_analysis_obj->run_goat();
    }
    elsif ( $solexarun_type eq 'Paired' ) {
        $current_analysis_obj = new Sequencing::Solexa_analysis(
            -dbc => $dbc,
            @solexa_analysis_args,
            -analyze_tiles => $analyze_tiles,
            -kc            => 0,
            -paired        => 1,
            -use_bases     => $use_bases,
        );

        my $pet_analysis_id = $current_analysis_obj->prepare_analysis();
        my $pet_gerald_path = $current_analysis_obj->get_gerald_path();
        $current_analysis_id = $pet_analysis_id;

        $current_analysis_obj->run_goat();
    }
    else {

        Message("Undefined solexa run type");
        exit;
    }

    $current_analysis_obj->run_analysis( -analysis_id => $current_analysis_id );

}

else { print "Analysis already started or Run not completed"; }

exit;

