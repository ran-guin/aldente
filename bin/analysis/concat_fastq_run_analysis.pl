#!/usr/local/bin/perl

use strict;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";
use lib $FindBin::RealBin . "/../lib/perl/Custom";

use Data::Dumper;
use RGTools::RGIO;
use SDB::CustomSettings;
use RGTools::Process_Monitor;
use vars qw($opt_help $opt_quiet $opt_host $opt_dbase $opt_user $opt_password %Configs $opt_run_ids);

use Getopt::Long;
use alDente::Run;
use alDente::Run_Analysis;

#use Illumina::Run_Analysis;
use URI::Escape;

&GetOptions(
    'help'       => \$opt_help,
    'quiet'      => \$opt_quiet,
    'host=s'     => \$opt_host,
    'dbase=s'    => \$opt_dbase,
    'user=s'     => \$opt_user,
    'password=s' => \$opt_password,
    'run_ids=s'  => \$opt_run_ids,
);

my $help  = $opt_help;
my $quiet = $opt_quiet;
my $host  = $opt_host || $Configs{PRODUCTION_HOST};
my $dbase = $opt_dbase || $Configs{PRODUCTION_DATABASE};
my $user  = $opt_user;
my $pass  = $opt_password;

require SDB::DBIO;
my $dbc = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pass,
    -connect  => 1,
);
## find the data acquired runs and start analysis

my %analysis_type;
$analysis_type{'SolexaRun'} = ['Illumina'];

#my $analyzed = alDente::Run::get_analyzed_runs(-dbc=>$dbc,-extra_condition=>" AND Run_Type <> 'GelRun' and Run_Directory NOT LIKE 'PHI%' and Run_DateTime > '2010-04-01' and Run_ID = 121039");
my %finished_runs;
my $extra_condition;
$extra_condition = "OR (Run_Analysis_ID IS NULL AND Run_ID IN ($opt_run_ids))" if $opt_run_ids;

if ($opt_run_ids) {    # if run ids are given, only retrieve specified primary Analyzing runs
    %finished_runs = $dbc->Table_retrieve(
        "(Run,SolexaRun) LEFT JOIN Run_Analysis ON Run_Analysis.FK_Run__ID = Run_ID AND FKAnalysis_Pipeline__ID= 307",
        [ 'Run_ID', 'Run_Type' ],
        "WHERE SolexaRun.FK_Run__ID = Run_ID AND ((Run_Analysis_Type = 'Primary' AND Run_Analysis_Status = 'Analyzing') AND Run_ID in ($opt_run_ids) $extra_condition )"
    );
}
else {                 # if run ids are not given, retrieve all Analyzing primary runs
    %finished_runs = $dbc->Table_retrieve(
        "(Run,SolexaRun) LEFT JOIN Run_Analysis ON Run_Analysis.FK_Run__ID = Run_ID AND FKAnalysis_Pipeline__ID= 307",
        [ 'Run_ID', 'Run_Type' ],
        "WHERE SolexaRun.FK_Run__ID = Run_ID AND ((Run_Analysis_Type = 'Primary' AND Run_Analysis_Status = 'Analyzing') )"
    );
}

my $finished_run = \%finished_runs;
print Dumper $finished_run;

#exit;
my $index = 0;
while ( $finished_run->{Run_ID}[$index] ) {
    my $run_id   = $finished_run->{Run_ID}[$index];
    my $run_type = $finished_run->{Run_Type}[$index];
    my $field    = "$run_type" . "_Type";
    my ($sub_run_type) = $dbc->Table_find( $run_type, $field, "WHERE FK_Run__ID = $run_id" );
    print "Run_ID $run_id Run_Type $run_type Sub_Run_Type $sub_run_type\n";
    my $analysis_pipeline_id;

    my @analysis_types = ();
    if ( $analysis_type{$run_type} ) {
        @analysis_types = @{ $analysis_type{$run_type} };
        foreach my $analysis_type (@analysis_types) {
            my $analysis_obj = "$analysis_type" . "::Run_Analysis";
            eval("require $analysis_obj");

            ## determine what type of analysis pipeline is to be run
            my $analysis_pipeline = &get_analysis_pipeline( -run_type => $run_type, -sub_run_type => $sub_run_type, -run_id => $run_id );
            if ( !$analysis_pipeline ) { print "No analysis pipeline\n"; next; }
            print Dumper $analysis_pipeline;

            #next;
            #check if already a run analysis is running
            my ($run_analysis_id) = $dbc->Table_find( 'Run_Analysis', "Run_Analysis_ID", "WHERE FK_Run__ID = $run_id and Run_Analysis_Status = 'Analyzing' and FKAnalysis_Pipeline__ID = $analysis_pipeline " );
            if ($run_analysis_id) {
                my $run_analysis_obj = $analysis_obj->new( -dbc => $dbc, -id => $run_analysis_id );
                my $run_analyzed = $run_analysis_obj->check_analysis_step_progress( -run_analysis_id => $run_analysis_id );    #check_analysis_step_progress will need to run_analysis
            }
            else {

                #Make sure not keep re-running
                my ($run_analysis_id) = $dbc->Table_find( 'Run_Analysis', "Run_Analysis_ID", "WHERE FK_Run__ID = $run_id and Run_Analysis_Status = 'Analyzed' and FKAnalysis_Pipeline__ID = $analysis_pipeline" );
                if ( !$run_analysis_id ) {
                    my $run_analysis_obj = $analysis_obj->new( -dbc => $dbc );
                    my $run_analysis_id = $run_analysis_obj->start_run_analysis( -run_id => $run_id, -analysis_pipeline_id => $analysis_pipeline, -run_analysis_type => 'Primary' );
                    $run_analysis_obj->create_multiplex_run_analysis( -run_analysis_id => $run_analysis_id );
                }
            }
        }
    }
    else {
        print "Analysis not supported yet\n";
    }

    $index++;
}

exit;

sub get_analysis_pipeline {
    my %args         = &filter_input( \@_, -mandatory => 'run_type,sub_run_type,run_id' );
    my $run_type     = $args{-run_type};
    my $sub_run_type = $args{-sub_run_type};
    my $run_id       = $args{-run_id};

    my %analysis_pipeline;
    $analysis_pipeline{'SolexaRun'}{'Single'} = 307;
    $analysis_pipeline{'SolexaRun'}{'Paired'} = 307;

    return $analysis_pipeline{$run_type}{$sub_run_type};
}

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
