#!/usr/local/bin/perl

use strict;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../lib/perl/custom";
use Data::Dumper;
use RGTools::RGIO;
use RGTools::Conversion;
use SDB::CustomSettings;
use RGTools::Process_Monitor;
use vars qw($opt_help $opt_quiet $opt_host $opt_dbase $opt_user $opt_password $opt_reanalysis $opt_start_reanalysis $opt_run $opt_ignore %Configs $opt_implicit);

use Getopt::Long;
use alDente::Run;
use alDente::Run_Analysis;
use URI::Escape;

&GetOptions(
    'help'               => \$opt_help,
    'quiet'              => \$opt_quiet,
    'host=s'             => \$opt_host,
    'dbase=s'            => \$opt_dbase,
    'user=s'             => \$opt_user,
    'password=s'         => \$opt_password,
    'reanalysis=s'       => \$opt_reanalysis,
    'start_reanalysis=s' => \$opt_start_reanalysis,
    'run'                => \$opt_run,
    'ignore=s'           => \$opt_ignore,
    'implicit=s'         => \$opt_implicit,
);

my $help             = $opt_help;
my $quiet            = $opt_quiet;
my $host             = $opt_host || $Configs{PRODUCTION_HOST};
my $dbase            = $opt_dbase || $Configs{PRODUCTION_DATABASE};
my $user             = $opt_user;
my $pass             = $opt_password;
my $reanalysis       = $opt_reanalysis;
my $start_reanalysis = $opt_start_reanalysis;
my $run              = $opt_run;
my $ignore           = $opt_ignore;
require SDB::DBIO;
my $dbc = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pass,
    -connect  => 1,
);
## find the data acquired runs and start analysis
my $current_processes = try_system_command("ps axwww | grep 'run_analysis_Rhabdoid.pl' | grep -v 'xemacs' | grep -v ' 0:00 ' | grep -v ' 0:01 ' | grep -v ' 0:02 '  | grep -v ' 0:03 '");

if ($current_processes) {
    print Dumper $current_processes;
    Message("Already in progress");
    exit;
}

my %analysis_type;

$analysis_type{'SolexaRun'} = ['BWA'];
$analysis_type{'SOLIDRun'}  = ['SOLID'];
my %analysis_pipeline;
$analysis_pipeline{'SOLIDRun'}{'Single'}      = 228;
$analysis_pipeline{'SOLIDRun'}{'Paired'}      = 229;
$analysis_pipeline{'SOLIDRun'}{'Mate Paired'} = 219;
$analysis_pipeline{'SolexaRun'}{'Single'}     = 301;
$analysis_pipeline{'SolexaRun'}{'Paired'}     = 301;
my @run_id;
my $implicit_concurrent_start = $opt_implicit;
my $implicit_concurrent_count = 0;
my %implicit_start_reanalysis;

if ($reanalysis) {
    open( TMP, "$reanalysis" ) or die "Cannot open $reanalysis";
    while (<TMP>) {
        my $line = chomp_edge_whitespace($_);
        print "Line $line\n";
        $line =~ /(.*)\_(\d)$/;
        my $flowcell = $1;
        my $lane     = $2;
        print "$flowcell $lane \n";
        my ($run)
            = $dbc->Table_find( 'Run,SolexaRun,Flowcell', 'Run_ID', "WHERE SolexaRun.FK_Run__ID = Run_ID and (Run_Status <> 'Failed' AND Run_Validation <> 'Rejected') and FK_Flowcell__ID = Flowcell_ID and Flowcell_Code = '$flowcell' and Lane = $lane" );

	#implicit start with max of $implicit_concurrent_start
	if (!$start_reanalysis && $implicit_concurrent_start && $run) {
	    my ($run_type) = $dbc->Table_find( "Run", "Run_Type", "WHERE Run_ID = $run" );
	    my $field    = "$run_type" . "_Type";
	    my ($sub_run_type) = $dbc->Table_find( $run_type, $field, "WHERE FK_Run__ID = $run" );
	    my $analysis_pipeline = &get_analysis_pipeline( -run_type => $run_type, -run_id => $run, -sub_run_type => $sub_run_type );

	    #Don't do more any more 
	    if ($implicit_concurrent_count >= $implicit_concurrent_start) {
		print "HERE max\n";
		last;
	    }
	    my ($analysis_status) = $dbc->Table_find("Run_Analysis","Run_Analysis_Status","WHERE FK_Run__ID = $run AND FKAnalysis_Pipeline__ID = $analysis_pipeline ORDER BY Run_Analysis_ID DESC");
	    
	    #Already analyed, do nothing
	    if ($analysis_status eq 'Analyzed') {
		print "HERE analyzed\n";
		next;
	    }

	    #Still analyzing, need to check analysis progress
	    if ($analysis_status eq 'Analyzing') {
		print "HERE analyzing\n";
		push @run_id, $run;
		$implicit_concurrent_count++;
	    }

	    #Doesn't have one, need to start analysis, the analyzing ones won't be restarted, because start analysis check for analyzing analysis
	    if (!$analysis_status) {
		print "HERE start analysis\n";
		push @run_id, $run;
		$implicit_concurrent_count++;
		$implicit_start_reanalysis{$run} = 1;
	    }
	    
	}
	else {
	    push @run_id, $run;
	}
    }
}

my @failed_analysis = $dbc->Table_find(
    'Run_Analysis,Run',
    'distinct Run_ID,Run_Analysis_Started',
    "WHERE Run_Analysis_Status = 'Failed' and Run_Analysis.FK_Run__ID = Run_ID and Run_Analysis_Finished > Date_Sub(curdate(), INTERVAL 1 day) AND Date(Run_Analysis_Started) != DATE(curdate()) and Run_Status <> 'Analyzing' AND Current_Analysis = 'Yes'"
) if !$reanalysis;
if (@failed_analysis) {
    foreach my $failed_run (@failed_analysis) {
        my ( $run, $failed_run_started ) = split ',', $failed_run;
        $failed_run_started = convert_date( $failed_run_started, 'SQL' );
        my @newer_analysis = $dbc->Table_find(
            'Run_Analysis,Run',
            'distinct Run_Analysis_ID',
            "WHERE Run_Analysis.FK_Run__ID = Run_ID and Run_ID = $run and Run_Analysis_Started > '$failed_run_started' and Run_Analysis_Status <> 'Failed' and Run_Analysis_Type = 'Secondary'"
        );
        my @analyzed_analysis = $dbc->Table_find( 'Run_Analysis', 'distinct Run_Analysis_ID', "WHERE FK_Run__ID = $run and Run_Analysis_Status = 'Analyzed' and Current_Analysis = 'Yes' and Run_Analysis_Type = 'Secondary'" );
        my ($num_fail_analysis) = $dbc->Table_find( 'Run_Analysis', 'Count(distinct Run_Analysis_ID)', "WHERE FK_Run__ID = $run and Run_Analysis_Status = 'Failed' and Run_Analysis_Type = 'Secondary'" );
        if (@newer_analysis) {

            ## newer run analysis found
        }
        elsif (@analyzed_analysis) {
            ## old analysis that was done ok (maybe manually change to ok)
        }
        elsif ( $num_fail_analysis >= 2 ) {
            ## Analysis for this run already failed 3 times, notifying users
            my $data_path = &alDente::Run::get_data_path( -dbc => $dbc, -run_id => $run );
            if ( !-e "$data_path/failed_analysis_check_sent" ) {
                require alDente::Subscription;
                alDente::Subscription::send_notification(
                    -dbc          => $dbc,
                    -name         => 'Re-analysis of failed analysis check',
                    -from         => 'Fail Analysis Check <aldente@bcgsc.bc.ca>',
                    -subject      => "Automated re-analysis of failed analysis keeps failing for run $run",
                    -body         => "Analysis for run $run keeps failing. Please investigate.",
                    -content_type => 'html'
                );
                try_system_command("touch $data_path/failed_analysis_check_sent");
                $dbc->Table_update( "Run", "Run_Status", "Expired", "WHERE Run_ID = $run", -autoquote => 1 );
            }
        }
        else {
            push @run_id, $run;
        }
    }
    if (@run_id) {
        $reanalysis       = 1;
        $start_reanalysis = 1;
    }
}

my $run_string = Cast_List( -list => \@run_id, -to => 'String', -autoquote => 1 );

if ( $reanalysis && ($start_reanalysis || $implicit_concurrent_start) ) {

    ## update the current run analysis to NO
    print "Re-Analyzing $run_string\n";
    ## start a new run analysis
    foreach my $run (@run_id) {
	if ($implicit_concurrent_start && !$implicit_start_reanalysis{$run}) { 
	    print "NOT START\n";
	    next;
	}

        my ($run_type)     = $dbc->Table_find( 'Run',     'Run_Type', "WHERE Run_ID = $run" );
        my $field          = "$run_type" . "_Type";
        my ($sub_run_type) = $dbc->Table_find( $run_type, $field,     "WHERE FK_Run__ID = $run" );
        print "Run_ID $run Run_Type $run_type Sub_Run_Type $sub_run_type\n";

        my $analysis_pipeline_id;

        my @analysis_types = ();

        my ($library_strategy) = $dbc->Table_find( "Run,Plate_Attribute,Attribute,Library_Strategy",
            "Library_Strategy_Name", "WHERE Run.FK_Plate__ID = Plate_Attribute.FK_Plate__ID AND FK_Attribute__ID = Attribute_ID AND Attribute_Name = 'Library_Strategy' and Attribute_Value = Library_Strategy_ID AND Run_ID = $run" );
	my ($project) = $dbc->Table_find( "Run,Plate,Library,Project","Project_Name","WHERE Run.FK_Plate__ID = Plate.Plate_ID AND Plate.FK_Library__Name = Library.Library_Name AND Library.FK_Project__ID = Project.Project_ID AND Run.Run_ID = $run" );
        if ( $library_strategy eq 'Bisulfite-Seq' ) {
	    if ($project eq 'REMC' || $project eq 'NCI SAIC Rhabdoid Tumor' || $project eq 'CEMT' || 1) {
		$analysis_type{'SolexaRun'} = ['Novoalign'];
	    }
	    else {
		$analysis_type{'SolexaRun'} = ['Bismark'];
	    }
        }
        else {
            $analysis_type{'SolexaRun'} = ['BWA'];
        }

        if ( $analysis_type{$run_type} ) {
            @analysis_types = @{ $analysis_type{$run_type} };
            foreach my $analysis_type (@analysis_types) {
                my $analysis_obj = "$analysis_type" . "::Run_Analysis";
                eval("require $analysis_obj");

                ## determine what type of analysis pipeline is to be run
                my $run_analysis_obj = $analysis_obj->new( -dbc => $dbc );

                #my ($analysis_pipeline) = $dbc->Table_find('Pipeline',"Pipeline_ID", "WHERE Pipeline_Type = '$analysis_type'");
                my $analysis_pipeline = &get_analysis_pipeline( -run_type => $run_type, -run_id => $run, -sub_run_type => $sub_run_type );
                if ( !$analysis_pipeline ) { print "No analysis pipeline\n"; next; }
                my $run_analysis_id = $run_analysis_obj->start_run_analysis( -run_id => $run, -analysis_pipeline_id => $analysis_pipeline, -force => 1 );
                if ( $run_analysis_id && $run_type eq 'SolexaRun' ) {
                    my ($sample_id) = $dbc->Table_find( 'Run_Analysis', 'FK_Sample__ID', "WHERE FK_Run__ID = $run group by FK_Run__ID" );

                    my $added_solexa_run_analysis = $run_analysis_obj->create_solexa_run_analysis( -run_analysis_id => $run_analysis_id, -sample_id => $sample_id );

                    $run_analysis_obj->create_multiplex_run_analysis( -run_analysis_id => $run_analysis_id );
                }

            }
        }
        else {
            print "Analysis not supported yet\n";
        }
    }
    #exit;
}

my $extra_condition = "and Run_DateTime > '2011-05-01'";
if ($run_string) {
    $extra_condition = "and Run_ID in ($run_string)";
}

my $data_acquired = alDente::Run::get_data_acquired_runs( -dbc => $dbc, -extra_condition => " AND Run_Type <> 'GelRun' and Run_Directory NOT LIKE 'PHI%' and Run_DateTime > '2010-04-01'" ) if !$reanalysis;
my $index = 0;
while ( $data_acquired->{Run_ID}[$index] ) {
    my $run_id   = $data_acquired->{Run_ID}[$index];
    my $run_type = $data_acquired->{Run_Type}[$index];
    my $field    = "$run_type" . "_Type";
    my ($sub_run_type) = $dbc->Table_find( $run_type, $field, "WHERE FK_Run__ID = $run_id" );
    print "Run_ID $run_id Run_Type $run_type Sub_Run_Type $sub_run_type\n";
    #$index++; next;
    my $analysis_pipeline_id;
    my ($clinical_run) = $dbc->Table_find( 'Run,Plate,Library,Project', 'Run_ID', "WHERE Run_ID = $run_id and Run.FK_Plate__ID = Plate_ID and Library_Name = Plate.FK_Library__Name and Project_ID = FK_Project__ID and Project_Name IN ('CCG','CCG_Dev')" );
    if ($clinical_run) {
        $index++;
        next;
    }

    my @analysis_types = ();

    my ($library_strategy) = $dbc->Table_find( "Run,Plate_Attribute,Attribute,Library_Strategy",
        "Library_Strategy_Name", "WHERE Run.FK_Plate__ID = Plate_Attribute.FK_Plate__ID AND FK_Attribute__ID = Attribute_ID AND Attribute_Name = 'Library_Strategy' and Attribute_Value = Library_Strategy_ID AND Run_ID = $run_id" );
    my ($project) = $dbc->Table_find( "Run,Plate,Library,Project","Project_Name","WHERE Run.FK_Plate__ID = Plate.Plate_ID AND Plate.FK_Library__Name = Library.Library_Name AND Library.FK_Project__ID = Project.Project_ID AND Run.Run_ID = $run_id" );
    if ( $library_strategy eq 'Bisulfite-Seq' ) {
	if ($project eq 'REMC' || $project eq 'NCI SAIC Rhabdoid Tumor' || $project eq 'CEMT' || 1) {
	    $analysis_type{'SolexaRun'} = ['Novoalign'];
	}
	else {
	    $analysis_type{'SolexaRun'} = ['Bismark'];
	}
    }
    else {
        $analysis_type{'SolexaRun'} = ['BWA'];
    }

    if ( $analysis_type{$run_type} ) {
        @analysis_types = @{ $analysis_type{$run_type} };
        foreach my $analysis_type (@analysis_types) {
            my $analysis_obj = "$analysis_type" . "::Run_Analysis";
            eval("require $analysis_obj");

            ## determine what type of analysis pipeline is to be run
            my $run_analysis_obj = $analysis_obj->new( -dbc => $dbc );

            ## determine what type of analysis pipeline is to be run

            #my ($analysis_pipeline) = $dbc->Table_find('Pipeline',"Pipeline_ID", "WHERE Pipeline_Type = '$analysis_type'");
            my $analysis_pipeline = &get_analysis_pipeline( -run_type => $run_type, -sub_run_type => $sub_run_type, -run_id => $run_id );
            if ( !$analysis_pipeline ) { print "No analysis pipeline\n"; next; }
            my $run_analysis_id = $run_analysis_obj->start_run_analysis( -run_id => $run_id, -analysis_pipeline_id => $analysis_pipeline );
            if ( $run_analysis_id && $run_type eq 'SolexaRun' ) {
                $run_analysis_obj->create_multiplex_run_analysis( -run_analysis_id => $run_analysis_id );
                my ($sample_id) = $dbc->Table_find( 'Run_Analysis', 'FK_Sample__ID', "WHERE FK_Run__ID = $run_id group by FK_Run__ID" );

                my $added_solexa_run_analysis = $run_analysis_obj->create_solexa_run_analysis( -run_analysis_id => $run_analysis_id, -sample_id => $sample_id );
            }

            ## set the run status to analyzing
            my $run_obj = alDente::Run->new( -dbc => $dbc, -id => $run_id );
            $run_obj->update( -fields => ['Run_Status'], -values => ['Analyzing'] );
        }
    }
    else {
        print "Analysis not supported yet\n";
    }

    $index++;
}
## find any running analyses and check if they are done, if so, begin the next analysis step

#my $analyzing = alDente::Run::get_analyzing_runs(-dbc=>$dbc,-extra_condition=>" and Run_DateTime > '2010-06-03'");
my $ignore_condition;
if ($ignore) {
    open( FILE, "$ignore" ) or die "Cannot open $ignore";
    my @ignore_list = ();
    while (<FILE>) {
        my $line = chomp_edge_whitespace($_);
        print "Line $line\n";
        $line =~ /(.*)\_(\d)$/;
        my $flowcell = $1;
        my $lane     = $2;
        print "$flowcell $lane \n";
        my ($run)
            = $dbc->Table_find( 'Run,SolexaRun,Flowcell', 'Run_ID', "WHERE SolexaRun.FK_Run__ID = Run_ID and (Run_Status <> 'Failed' AND Run_Validation <> 'Rejected') and FK_Flowcell__ID = Flowcell_ID and Flowcell_Code = '$flowcell' and Lane = $lane" );
        if ($run) {
            push @ignore_list, $run;
        }

    }
    if (@ignore_list) {
        my $ignore_string = Cast_List( -list => \@ignore_list, -to => 'String' );
        $ignore_condition = " AND Run_ID NOT IN ($ignore_string) ";
        $extra_condition .= $ignore_condition;
    }
}
my $analyzing = alDente::Run::get_analyzing_runs( -dbc => $dbc, -extra_condition => " and Run_Directory NOT LIKE 'PHI%' $extra_condition " );
my $analyzing_index = 0;

while ( $analyzing->{Run_ID}[$analyzing_index] ) {
    my $run_id   = $analyzing->{Run_ID}[$analyzing_index];
    my $run_type = $analyzing->{Run_Type}[$analyzing_index];
    my $field    = "$run_type" . "_Type";
    my ($sub_run_type) = $dbc->Table_find( $run_type, $field, "WHERE FK_Run__ID = $run_id" );
    print "Run_ID $run_id Run_Type $run_type Sub_Run_Type $sub_run_type a\n";
    #$analyzing_index++; next;
    my $analysis_pipeline_id;

    my @analysis_types = ();

    my ($library_strategy) = $dbc->Table_find( "Run,Plate_Attribute,Attribute,Library_Strategy",
        "Library_Strategy_Name", "WHERE Run.FK_Plate__ID = Plate_Attribute.FK_Plate__ID AND FK_Attribute__ID = Attribute_ID AND Attribute_Name = 'Library_Strategy' and Attribute_Value = Library_Strategy_ID AND Run_ID = $run_id" );
    my ($project) = $dbc->Table_find( "Run,Plate,Library,Project","Project_Name","WHERE Run.FK_Plate__ID = Plate.Plate_ID AND Plate.FK_Library__Name = Library.Library_Name AND Library.FK_Project__ID = Project.Project_ID AND Run.Run_ID = $run_id" );
    if ( $library_strategy eq 'Bisulfite-Seq' ) {
	if ($project eq 'REMC' || $project eq 'NCI SAIC Rhabdoid Tumor' || $project eq 'CEMT' || 1) {
	    $analysis_type{'SolexaRun'} = ['Novoalign'];
	}
	else {
	    $analysis_type{'SolexaRun'} = ['Bismark'];
	}
    }
    else {
        $analysis_type{'SolexaRun'} = ['BWA'];
    }

    if ( $analysis_type{$run_type} ) {
        @analysis_types = @{ $analysis_type{$run_type} };
        foreach my $analysis_type (@analysis_types) {
            my $analysis_obj = "$analysis_type" . "::Run_Analysis";
            eval("require $analysis_obj");

            #my ($analysis_pipeline) = $dbc->Table_find('Pipeline',"Pipeline_ID", "WHERE Pipeline_Type = '$analysis_type'");
            my $analysis_pipeline = &get_analysis_pipeline( -run_type => $run_type, -sub_run_type => $sub_run_type, -run_id => $run_id );
            if ( !$analysis_pipeline ) { print "No analysis pipeline\n"; next; }
            ## get the run analysis id

            my ($run_analysis_id) = $dbc->Table_find( 'Run_Analysis', "Run_Analysis_ID", "WHERE FK_Run__ID = $run_id and Run_Analysis_Status = 'Analyzing' and FKAnalysis_Pipeline__ID = $analysis_pipeline " );
            print "Run A ID: $run_analysis_id\n";
            unless ($run_analysis_id) {
                next;
            }
            my $run_analysis_obj = $analysis_obj->new( -dbc => $dbc, -id => $run_analysis_id, -base_directory => "" );
            $run_analysis_obj->set_analysis_scratch_space( -analysis_scratch_space => '/projects/prod_scratch1/lims/' );    #temporary
                                                                                                                           #print Dumper $run_analysis_obj;

            my $run_analyzed = $run_analysis_obj->check_analysis_step_progress( -run_analysis_id => $run_analysis_id );
            if ($run_analyzed) {
                my $run_obj = alDente::Run->new( -dbc => $dbc, -id => $run_id );
                $run_obj->update( -fields => ['Run_Status'], -values => ['Analyzed'] );
            }
            else {
                $run_analysis_obj->check_expiring_analysis( -run_analysis_id => $run_analysis_id );
            }

        }
    }
    else {
        print "Analysis not supported yet\n";
    }

    $analyzing_index++;
}

exit;

sub get_analysis_pipeline {
    my %args         = &filter_input( \@_, -mandatory => 'run_type,sub_run_type,run_id' );
    my $run_type     = $args{-run_type};
    my $sub_run_type = $args{-sub_run_type};
    my $run_id       = $args{-run_id};

    my ($library_strategy) = $dbc->Table_find( "Run,Plate_Attribute,Attribute,Library_Strategy",
        "Library_Strategy_Name", "WHERE Run.FK_Plate__ID = Plate_Attribute.FK_Plate__ID AND FK_Attribute__ID = Attribute_ID AND Attribute_Name = 'Library_Strategy' and Attribute_Value = Library_Strategy_ID AND Run_ID = $run_id" );
    my ($project) = $dbc->Table_find( "Run,Plate,Library,Project","Project_Name","WHERE Run.FK_Plate__ID = Plate.Plate_ID AND Plate.FK_Library__Name = Library.Library_Name AND Library.FK_Project__ID = Project.Project_ID AND Run.Run_ID = $run_id" );
    if ( $library_strategy eq 'miRNA_Seq' && $run_type eq 'SOLIDRun' && $sub_run_type eq 'Single' ) {
        return 242;
    }
    my ($pipeline) = $dbc->Table_find( "Run,Plate,Pipeline", "Pipeline_Name", "WHERE FK_Plate__ID = Plate_ID and FK_Pipeline__ID = Pipeline_ID and Run_ID = $run_id" );
    if ( $pipeline eq 'SOLID Paired Index' ) { return 247 }

    if ( $library_strategy eq 'Bisulfite-Seq' && $run_type eq 'SolexaRun' ) {
	if ($project eq 'REMC' || $project eq 'NCI SAIC Rhabdoid Tumor' || $project eq 'CEMT' || 1) {
	    return 308;
	}
        return 302;
    }
    
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
