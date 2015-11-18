#!/usr/local/bin/perl

use strict;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";
use Data::Dumper;
use RGTools::RGIO;
use SDB::CustomSettings;
use RGTools::Process_Monitor;
use vars qw($opt_help $opt_quiet $opt_host $opt_dbase $opt_user $opt_password %Configs);

use Getopt::Long;
use alDente::Run;
use alDente::Run_Analysis;
use URI::Escape;

&GetOptions(
    'help'       => \$opt_help,
    'quiet'      => \$opt_quiet,
    'host=s'     => \$opt_host,
    'dbase=s'    => \$opt_dbase,
    'user=s'     => \$opt_user,
    'password=s' => \$opt_password,
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
print Dumper $dbc;
## find the data acquired runs and start analysis
my $current_processes = try_system_command("ps axwww | grep 'run_post_analysis.pl' | grep -v 'xemacs' | grep -v ' 0:00 ' | grep -v ' 0:01 ' | grep -v ' 0:02 '  | grep -v ' 0:03 '");

if ($current_processes) {
    print Dumper $current_processes;
    Message("Already in progress");
    exit;
}

my %analysis_type;
$analysis_type{'SolexaRun'} = ['Illumina'];

#my $analyzed = alDente::Run::get_analyzed_runs(-dbc=>$dbc,-extra_condition=>" AND Run_Type <> 'GelRun' and Run_Directory NOT LIKE 'PHI%' and Run_DateTime > '2010-04-01' and Run_ID = 121039");
my %runs = $dbc->Table_retrieve(
    "Equipment, RunBatch, Run LEFT JOIN Run_Analysis ON FK_Run__ID = Run_ID AND Run_Analysis_Type = 'Post'",
    [ 'Run_ID', 'Run_Type' ],

    "WHERE FK_RunBatch__ID = RunBatch_ID AND FK_Equipment__ID = Equipment_ID AND (Run_Status = 'Analyzed' OR (Run_Status = 'Data Acquired' AND Run_Directory LIKE 'PHI%') OR ((Run_Status = 'Expired' OR Run_Status = 'In Process') AND Run_Validation = 'Rejected')) and Run_DateTime > '2011-04-01' " . "AND (Run_Analysis_ID IS NULL OR Run_Analysis_Status = 'Analyzing') AND Run_Type = 'SolexaRun'"

        #<CONSTRUCTION> limiting to SolexaRun because that's the only run type suppported right now, need to remove this if updating get_analysis_pipeline to support other run type
        #"WHERE Run_Status = 'Data Acquired' and Run_DateTime > '2010-04-01' and Run_ID = 124126 " . "AND (Run_Analysis_ID IS NULL OR Run_Analysis_Status = 'Analyzing')"
);
my $analyzed = \%runs;
my $index    = 0;
print Dumper $analyzed;
while ( $analyzed->{Run_ID}[$index] ) {
    my $run_id = $analyzed->{Run_ID}[$index];

    #double check the run has a secondary analysis that is current and analyzed
    my ($secondary_run_analysis) = $dbc->Table_find( "Run_Analysis", "Run_Analysis_ID", "WHERE Run_Analysis_Type = 'Secondary' AND Run_Analysis_Status = 'Analyzed' AND Current_Analysis = 'Yes' AND FK_Run__ID = $run_id" );
    if ( !$secondary_run_analysis ) {
        my ($control) = $dbc->Table_find( "Run", "Run_ID", "WHERE Run_Directory LIKE 'PHI%' AND Run_ID = $run_id" );
        if ( !$control ) {

	    my ($project) = $dbc->Table_find( "Run,Plate,Library,Project", "Run_ID", "WHERE FK_Plate__ID = Plate_ID AND FK_Library__Name = Library_Name AND FK_Project__ID = Project_ID AND Project_Name IN ('CCG','CCG_Dev') AND Run_ID = $run_id" );
	    if (!$project) {
		my ($rejected) = $dbc->Table_find( "Run", "Run_ID", "WHERE Run_ID = $run_id AND Run_Validation = 'Rejected'" );
		if ($rejected) {
		    my ($in_process) = $dbc->Table_find( "Run,SolexaRun","Run_ID","WHERE FK_Run__ID = Run_ID AND Run_ID = $run_id AND Run_Status = 'In Process' AND Run_Validation = 'Rejected' AND SolexaRun_Finished < Date_Sub(curdate(), INTERVAL 1 month)", -debug => 0); #Rejected in process run that hasn't been data acquired means it can't be processed and can be deleted

		    my ($no_more_secondary)
			= $dbc->Table_find( "Run_Analysis", "Run_Analysis_ID", "WHERE FK_Run__ID = $run_id and Run_Analysis_Type = 'Secondary' Group By FK_Run__ID Having MAX(Run_Analysis_Started) < Date_Sub(curdate(), INTERVAL 1 month)", -debug => 0 );

		    if ( !$no_more_secondary && !$in_process ) {
			$index++;
			next;
		    }
		}
		else {
		    $index++;
		    next;
		}
	    }
        }
    }

    my $run_type = $analyzed->{Run_Type}[$index];
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

            #print "analysis pipeline: " . $analysis_pipeline . "\n";
            #next;

            #check if already a run analysis is running
            my ($run_analysis_id) = $dbc->Table_find( 'Run_Analysis', "Run_Analysis_ID", "WHERE FK_Run__ID = $run_id and Run_Analysis_Status = 'Analyzing' and FKAnalysis_Pipeline__ID = $analysis_pipeline " );
            if ($run_analysis_id) {
                my $run_analysis_obj = $analysis_obj->new( -dbc => $dbc, -id => $run_analysis_id, -base_directory => "/projects/sbs_pipeline03/" );
                my $run_analyzed = $run_analysis_obj->check_analysis_step_progress( -run_analysis_id => $run_analysis_id );
            }
            else {

                #Make sure not keep re-running
                my ($run_analysis_id) = $dbc->Table_find( 'Run_Analysis', "Run_Analysis_ID", "WHERE FK_Run__ID = $run_id and Run_Analysis_Status = 'Analyzed' and FKAnalysis_Pipeline__ID = $analysis_pipeline" );
                if ( !$run_analysis_id ) {
                    my ($old_run) = $dbc->Table_find( "Run", "Run_ID", "WHERE Run_ID = $run_id AND Run_DateTime <= '2011-12-01'" );
                    if ($old_run) {next}
                    my $run_analysis_obj = $analysis_obj->new( -dbc => $dbc );
                    my $run_analysis_id = $run_analysis_obj->start_run_analysis( -run_id => $run_id, -analysis_pipeline_id => $analysis_pipeline, -run_analysis_type => 'Post' );
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

    my $analysis_pipeline_id = 288;

    #check old pipeline
    my ($old_analysis_pipeline_id) = $dbc->Table_find( 'Run_Analysis', "FKAnalysis_Pipeline__ID", "WHERE FK_Run__ID = $run_id AND Run_Analysis_Type = 'Post'" );
    $analysis_pipeline_id = $old_analysis_pipeline_id if $old_analysis_pipeline_id;

    #overwrite if new one is running
    my ($analyzing_pipeline_id) = $dbc->Table_find( 'Run_Analysis', "FKAnalysis_Pipeline__ID", "WHERE FK_Run__ID = $run_id AND Run_Analysis_Type = 'Post' AND Run_Analysis_Status = 'Analyzing'" );
    $analysis_pipeline_id = $analyzing_pipeline_id if $analyzing_pipeline_id;

    my %analysis_pipeline;
    $analysis_pipeline{'SolexaRun'}{'Single'} = $analysis_pipeline_id;
    $analysis_pipeline{'SolexaRun'}{'Paired'} = $analysis_pipeline_id;

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
