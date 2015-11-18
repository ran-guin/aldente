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
use XML::Simple;
use RGTools::RGIO;
use RGTools::Conversion;
use SDB::CustomSettings;
use RGTools::Process_Monitor;
use vars qw($opt_help $opt_quiet $opt_host $opt_dbase $opt_user $opt_password $opt_reanalysis $opt_start_reanalysis $opt_run $opt_ignore $opt_config);
use BWA::Run_Analysis_External;
use Getopt::Long;
use alDente::Run_Analysis_External;

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
    'config=s'           => \$opt_config
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
my $new_config       = $opt_config;

if ($help) { help(); exit; }

require SDB::DBIO;
my $dbc = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pass,
    -connect  => 1,
);
## find the data acquired runs and start analysis
my $current_processes = try_system_command("ps axwww | grep 'run_analysis_external.pl' | grep -v 'xemacs' | grep -v ' 0:00 ' | grep -v ' 0:01 ' | grep -v ' 0:02 '  | grep -v ' 0:03 '");

if ($current_processes) {
    print Dumper $current_processes;
    Message("Already in progress");
    exit;
}

my %analysis_pipeline;
$analysis_pipeline{'SolexaRun'}{'Single'} = 303;
$analysis_pipeline{'SolexaRun'}{'Paired'} = 303;

my $extra_condition;

if ($new_config) {

    my $config = $new_config;
    ## || "/home/jachan/workspace/project2/config.xml";
    my $xo = new XML::Simple();
    my $xml_input;

    #print "please work0\n";
    $xml_input = $xo->XMLin( "$config", forcearray => ['set'] );

    print "Dumping xml input\n";
    print Dumper $xml_input;

    my %xml;
    my $xml_output = \%xml;

    my $temp_index = 0;
    foreach my $index ( @{ $xml_input->{set} } ) {

        my $run_analysis_obj = alDente::Run_Analysis_External->new( -dbc => $dbc );

        unless ( $run_analysis_obj->pre_start_checks( -config_hash => $index ) ) {
            print "Pre check FAILED for $index->{read1} \n";
            next;
        }

        my $id = $dbc->Table_append_array(
            'External_Run_Analysis',
            [ 'Status',        'Input_Directory',           'Output_Directory',           'External_Analysis_Type',           'Sub_Run_Type',           'FK_Genome__ID',       'FK_Library_Strategy__ID',       'Read_Length' ],
            [ "Data Acquired", "$index->{input_directory}", "$index->{output_directory}", "$index->{external_analysis_type}", "$index->{sub_run_type}", "$index->{genome_id}", "$index->{library_strategy_id}", "$index->{read_length}" ],
            -autoquote => 1
        );

        $index->{id} = $id;

        push @{ $xml_output->{ $index->{input_directory} }{set} }, $index;
        print "ERA #: $temp_index\n";
        $temp_index++;
    }

    foreach my $input_directory ( keys %xml ) {

        my $target = "$input_directory" . "/config.xml";
        XMLout( $xml_output->{$input_directory}, OutputFile => $target );
    }

    #my $config = "/projects/prod_scratch/lims/jachan/config.xml";
    #$xml_input = $xo->XMLin("$config");

}

#################################################################
##																#
## Begin initialization steps for each External_Run_Analysis	#
##																#
#################################################################

my $data_acquired = get_data_acquired_runs( -dbc => $dbc );    # obtain list of External_Run_Analyis IDs with status = Data Acquired

my $index = 0;
while ( $data_acquired->{External_Run_Analysis_ID}[$index] ) {

    my $external_run_analysis_id = $data_acquired->{External_Run_Analysis_ID}[$index];

    my ($data) = $dbc->Table_find( "External_Run_Analysis, Library_Strategy", "Sub_Run_Type, External_Analysis_Type, Library_Strategy_Name", "WHERE External_Run_Analysis_ID = $external_run_analysis_id and FK_Library_Strategy__ID = Library_Strategy_ID" );
    my ( $sub_run_type, $external_analysis_type, $library_strategy ) = split( ',', $data );

    print "External_Run_Analysis_ID $external_run_analysis_id Sub_Run_Type $sub_run_type Library_Strategy $library_strategy\n";

    my $analysis_obj = "BWA" . "::Run_Analysis_External";
    eval("require $analysis_obj");
    my $run_analysis_obj = $analysis_obj->new( -dbc => $dbc );

    print "DEBUG: object created, begin pipeline search";

    my $analysis_pipeline = &get_analysis_pipeline( -dbc => $dbc, -external_analysis_type => $external_analysis_type, -sub_run_type => $sub_run_type, -external_run_analysis_id => $external_run_analysis_id );
    if ( !$analysis_pipeline ) { print "No analysis pipeline\n"; next; }

    print "DEBUG: Pipeline: $analysis_pipeline\n";

    my $run_analysis_id = $run_analysis_obj->start_run_analysis( -external_run_analysis_id => $external_run_analysis_id, -analysis_pipeline_id => $analysis_pipeline );

    my ($basecall_dir) = $dbc->Table_find( "External_Run_Analysis", "Output_Directory", "WHERE External_Run_Analysis_ID = $external_run_analysis_id" );
    my $run_analysis_path = $run_analysis_obj->get_run_analysis_path( -base_name => 'BWA' );
    my $output_path = "$basecall_dir/$run_analysis_path";
    $run_analysis_obj->set_analysis_scratch_space( -analysis_scratch_space => '/projects/prod_scratch/lims/external_analysis/scratch' );

    my ($project) = $dbc->Table_find( "External_Run_Analysis", "Input_Directory", "WHERE External_Run_Analysis_ID = $external_run_analysis_id" );
    $project =~ /(.*)\/(.*)/;
    $project = $2;

    # print "DEBUG: project: $project\n";
    # print "DEBUG: output path BWA: $output_path\n";

    try_system_command("mkdir -p $output_path");
    my $analysis_scratch_space = $run_analysis_obj->get_analysis_scratch_space();
    if ( -e "$analysis_scratch_space" ) {
        my $scratch = "$analysis_scratch_space" . "/" . "$project" . "/SCRATCH_$run_analysis_path";

        try_system_command("mkdir -p $scratch");
        try_system_command("ln -s $scratch $output_path/SCRATCH_$run_analysis_path");
        print "Create symlink to scratch space $scratch\n";

    }

    if ($run_analysis_id) {

        $run_analysis_obj->create_multiplex_run_analysis();
    }

    my ($genome_id) = $dbc->Table_find( 'External_Run_Analysis', 'FK_Genome__ID', "Where External_Run_Analysis.FK_Run_Analysis__ID = $run_analysis_id", -autoquote => 1 );
    my $now = &date_time();
    my $debug_msg = $dbc->Table_append_array( 'Run_Analysis_Attribute', [ 'FK_Run_Analysis__ID', 'FK_Attribute__ID', 'Attribute_Value', 'FK_Employee__ID', 'Set_DateTime' ], [ "$run_analysis_id", '323', "$genome_id", '141', "$now" ], -autoquote => 1 );

    $index++;
}

# print "DEBUG: END Of start loop Starting Analyzing LOOP!\n ";
my $analyzing = get_analyzing( -dbc => $dbc, -extra_condition => "$extra_condition " );
my $analyzing_index = 0;

while ( $analyzing->{External_Run_Analysis_ID}[$analyzing_index] ) {

    my $external_run_analysis_id = $analyzing->{External_Run_Analysis_ID}[$analyzing_index];
    my ($data) = $dbc->Table_find( "External_Run_Analysis", "Sub_Run_Type, External_Analysis_Type", "WHERE External_Run_Analysis_ID = $external_run_analysis_id" );
    my ( $sub_run_type, $external_analysis_type ) = split( ',', $data );

    # print "External_Run_Analysis_ID $external_run_analysis_id External_Analysis_Type $external_analysis_type Sub_Run_Type $sub_run_type\n";

    my $analysis_obj = "BWA" . "::Run_Analysis_External";
    eval("require $analysis_obj");

    my @analysis_pipeline = $dbc->Table_find(
        "Pipeline, Pipeline_Step, Analysis_Step, External_Run_Analysis",
        "Pipeline_ID",
        "WHERE Analysis_Step.FK_Run_Analysis__ID = External_Run_Analysis.FK_Run_Analysis__ID AND FK_Pipeline_Step__ID = Pipeline_Step_ID AND FK_Pipeline__ID = Pipeline_ID AND External_Run_Analysis_ID = $external_run_analysis_id LIMIT 1",
        -debug => 0
    );
    $analysis_pipeline = $analysis_pipeline[0];

    # print "DEBUG: pipeline obtained!\n";
    if ( !$analysis_pipeline ) { print "No analysis pipeline\n"; next; }
    ## get the run analysis id

    my ($run_analysis_id) = $dbc->Table_find(
        'Run_Analysis, External_Run_Analysis',
        "Run_Analysis_ID",
        "WHERE Run_Analysis_ID = FK_Run_Analysis__ID and Run_Analysis_Status = 'Analyzing' and FKAnalysis_Pipeline__ID = $analysis_pipeline and External_Run_Analysis_ID = $external_run_analysis_id",
        -debug => 0
    );

    print "Run Analysis ID: $run_analysis_id\n";
    unless ($run_analysis_id) {
        $analyzing_index++;
        next;
    }

    # print "DEBUG: creating analysis object!\n";
    my $run_analysis_obj = $analysis_obj->new( -dbc => $dbc, -id => $run_analysis_id );

    # print "DEBUG: setting scratch space\n";
    $run_analysis_obj->set_analysis_scratch_space( -analysis_scratch_space => '/projects/prod_scratch/lims/jachan' );    #temporary

    # print "DEBUG: checking progress\n";                                                                                                                             ## print Dumper $run_analysis_obj;
    ##HELP HELP HELP HELP##
    my $run_analyzed = $run_analysis_obj->check_analysis_step_progress( -run_analysis_id => $run_analysis_id );

    # print "DEBUG: Run Analyzed: $run_analyzed \n";
    if ($run_analyzed) {

        # print "DEBUG HERE!\n";
        #my $run_obj = alDente::Run->new( -dbc => $dbc, -id => $run_id );
        #$run_obj->update( -fields => ['Run_Status'], -values => ['Analyzed'] );
        my $status = 'Analyzed';
        $dbc->Table_update_array( 'External_Run_Analysis', ['Status'], [$status], "WHERE External_Run_Analysis_ID = $external_run_analysis_id", -autoquote => 1 );
    }
    else {
        $run_analysis_obj->check_expiring_analysis( -run_analysis_id => $run_analysis_id );
    }

    $analyzing_index++;
}

exit;

sub get_analysis_pipeline {
    my %args                     = &filter_input( \@_, -mandatory => 'sub_run_type' );
    my $external_run_analysis_id = $args{-external_run_analysis_id};
    my $run_type                 = $args{-run_type};
    my $sub_run_type             = $args{-sub_run_type};
    my $dbc                      = $args{-dbc};
    print "DEBUG in get_pipeline $external_run_analysis_id\n";

    my ($data) = $dbc->Table_find(
        "External_Run_Analysis, Library_Strategy", "Library_Strategy_Name, External_Analysis_Type", "WHERE FK_Library_Strategy__ID = Library_Strategy_ID and External_Run_Analysis_id = $external_run_analysis_id",
        -autoquote => 1,
        -debug     => 0
    );
    my ( $library_strategy, $external_analysis_type ) = split( ',', $data );

    print "DEBUG: $library_strategy	ext_ana_type: $external_analysis_type\n";

    if ( $external_analysis_type eq 'External Fq Alignment' ) {
        my ($pipeline_id) = $dbc->Table_find( "Pipeline", "Pipeline_ID", "Where Pipeline_Name = 'External Fq Alignment'" );
        return $pipeline_id;
    }
    elsif ( $external_analysis_type eq 'External miRNA Fq Alignment' ) {
        my ($pipeline_id) = $dbc->Table_find( "Pipeline", "Pipeline_ID", "Where Pipeline_Name = 'External miRNA Fq Alignment'" );
        return $pipeline_id;

    }
    elsif ( $external_analysis_type eq 'External Genesis Fq Alignment' ) {
        my ($pipeline_id) = $dbc->Table_find( "Pipeline", "Pipeline_ID", "Where Pipeline_Name = 'External Genesis Fq Alignment'" );
        return $pipeline_id;

    }

    print "DEBUG exiting get_pipeline\n";

    # print "DEBUG4\n";
    return $analysis_pipeline{$external_analysis_type}{$sub_run_type};

}

############################
sub get_data_acquired_runs {
############################
    my %args            = @_;
    my $dbc             = $args{-dbc};
    my $extra_condition = $args{-extra_condition};

    my %data_acquired_runs = $dbc->Table_retrieve( 'External_Run_Analysis', [ 'External_Run_Analysis_ID', 'External_Analysis_Type' ], "WHERE Status = 'Data Acquired' $extra_condition" );
    return \%data_acquired_runs;
}

############################
sub get_analyzing {
############################
    my %args            = @_;
    my $dbc             = $args{-dbc};
    my $extra_condition = $args{-extra_condition};

    my %analyzing_runs = $dbc->Table_retrieve( 'External_Run_Analysis', ['External_Run_Analysis_ID'], "WHERE Status = 'Analyzing' $extra_condition" );
    return \%analyzing_runs;
}

#############################
sub get_object {
#############################
    my %args                   = @_;
    my $external_analysis_type = $args{-external_analysis_type};
    my $sub_run_type           = $args{-sub_run_type};
    my $library_strategy       = $args{-library_strategy};

    ## uses run type, sub run type and library strat to determine the type of run_analysis_exteral object to create
    ## currently only supports BWA

    return 'BWA';

}

#############
sub help {
#############

    print <<HELP;

Usage:
*********

    -dbase <dbase> -host <host> -user <user> -config <config> to create external run analysis record

    -dbase <dbase> -host <host> -user <user> to run analysis

Mandatory Input:
**************************

Options:
**************************     


Examples:
***********

HELP

}
