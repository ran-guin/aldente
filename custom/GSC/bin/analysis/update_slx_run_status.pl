#!/usr/local/bin/perl

use strict;
use warnings;

use DBI;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";
use RGTools::RGIO;
use RGTools::Process_Monitor;
use SDB::DBIO;
use SDB::CustomSettings;
use Illumina::Solexa_Analysis;
use Sequencing::SolexaRun;

use alDente::Run;
use alDente::SDB_Defaults;
use alDente::Notification;

use Data::Dumper;
use Getopt::Long;

use vars qw($opt_help $opt_quiet $opt_host $opt_dbase $opt_user $config_dir $opt_flowcell %Configs);

####################################################################################################
###  Configuration Loading - use this block (and section above) for both bin and cgi-bin files   ###
####################################################################################################
my $Config = new alDente::Config( -initialize => 1, -root => $FindBin::RealBin . '/..' );

&GetOptions(
    'help'       => \$opt_help,
    'quiet'      => \$opt_quiet,
    'host=s'     => \$opt_host,
    'dbase=s'    => \$opt_dbase,
    'flowcell=s' => \$opt_flowcell,
    'user=s'     => \$opt_user
);

my $host  = $opt_host  || $Configs{PRODUCTION_HOST};
my $dbase = $opt_dbase || 'seqtest';
my $user  = $opt_user  || 'super_cron_user';
my $analyze_flowcell = $opt_flowcell;

my $dbc = new SDB::DBIO(
    -host    => $host,
    -dbase   => $dbase,
    -user    => $user,
    -connect => 1,
    -config  => $Config->{configs},
);

my $Report = Process_Monitor->new( -testing => $testing );

my $in_process_runs = Sequencing::SolexaRun::get_in_process_runs( -dbc => $dbc );
$Report->set_Detail( Dumper $in_process_runs);

my $j = 0;
my %copy_flowcell_run;

foreach my $run_id ( @{ $in_process_runs->{'Run_ID'} } ) {
    my $flowcell = $in_process_runs->{'Flowcell_Code'}[$j];

    $Report->set_Message("FLOWCELL ****** $flowcell");
    unless ( $flowcell =~ /$analyze_flowcell/ ) {
        $j++;
        next;
    }
    my $solexa_analysis_obj = Illumina::Solexa_Analysis->new( -dbc => $dbc, -flowcell => $flowcell );
    my @flowcell_path       = $solexa_analysis_obj->get_flowcell_directory();
    my $run_dir             = $in_process_runs->{'Run_Directory'}[$j];
    my $lane                = $in_process_runs->{'Lane'}[$j];
    my $lane_images         = "L00$lane";
    my $cycles              = $in_process_runs->{'Cycles'}[$j];

    my $solexarun_type  = $in_process_runs->{'SolexaRun_Type'}[$j];
    my $expected_cycles = $cycles;

    if ( $solexarun_type eq 'Paired' ) {
        $expected_cycles = $cycles * 2;
    }

    my $run_completed = 0;
    my $cycles_found  = 0;
    foreach my $flowcell_path (@flowcell_path) {
        my $run_completed_file_found = 0;
        $flowcell_path =~ /.*\/(.*$flowcell)\/*$/;
        my $flowcell_run = $1;
        $flowcell_run =~ /\d{6}_(.*)_\d{4}_$flowcell/i;
        my $machine = $1;

        $Report->set_Message("FC PATH $flowcell_path Run $run_id Flowcell PATH $flowcell_run MACHINE $machine");
        my $credential_file = "$config_dir/slx_credentials.txt";

        ## check for the Run.completed file

        if ( -e "$flowcell_path/Run.completed" ) {
            $run_completed_file_found = 1;
        }

        $cycles_found += Illumina::Solexa_Analysis::get_number_of_cycles( -flowcell_directory => $flowcell_path );
        my $finished_basecall_copy = $solexa_analysis_obj->check_for_rta_image_analysis_completed( -solexarun_type => $solexarun_type );

        #return reference to $log
        my ( $tiles_match_files, $log ) = $solexa_analysis_obj->tiles_match_files( -flowcell_dir => $flowcell_path, -flowcell => $flowcell, -lane => $lane, -lane_images => $lane_images );

        my $message;
        if ( $finished_basecall_copy && !$tiles_match_files ) {
            $message .= '<p> <span style="background-color:#000000; color:#ff0000;">ERROR:</span> <BR>';
            $message .= ${$log};
            $message .= "</p>";
            print "Sending notification\n";
            send_notification_message( -dbc => $dbc, -message => \$message, -subject => 'Flowcell: number of files do not match tiles' );
        }

        my ($finished_bustard) = glob("$flowcell_path/Data/*/B*/finished.txt");
        if ( ( $finished_basecall_copy && $tiles_match_files ) || -e "$finished_bustard" ) {
            $run_completed = 1;
        }
        else {
            $run_completed = 0;
        }

    }

    $Report->set_Message("RUN COMPLETE $run_completed");

    my ($SolexaRun_Finished) = $dbc->Table_find( "SolexaRun", "SolexaRun_Finished", "WHERE FK_Run__ID = $run_id" );

    if ( $run_completed && !$SolexaRun_Finished ) {

        #$dbc->Table_update_array (
        #          "Run",
        #          ['Run_Status'],
        #          ['Data Acquired'],
        #          "WHERE Run_ID = $run_id",
        #          -autoquote=>1
        #          );
        $dbc->Table_update_array( "SolexaRun", ['SolexaRun_Finished'], [ &date_time() ], "WHERE FK_Run__ID = $run_id", -autoquote => 1 );
        my $run_object           = new alDente::Run( -dbc           => $dbc, -run_id => $run_id ) or die("Cannot locate Run $run_id");
        my $project_analysis_dir = $run_object->get_data_path( -dbc => $dbc, -run_id => $run_id ) or die("Cannot locate information for run $run_id");

        my ( $slash, $home, $sequence, $archive, $slx, $one, $volume, $flowcell_run ) = split '/', $flowcell_path[0];
        my $solexa_params = $flowcell_path[0] . "/" . $flowcell_run . ".params";
        $solexa_analysis_obj->create_project_analysis_dir( -project_analysis_dir => $project_analysis_dir, -volume => $volume, -solexa_params => $solexa_params );
        $solexa_analysis_obj->set_current_firecrest_link();
        my $current_link = $solexa_analysis_obj->get_current_firecrest_link();
        my $command = $solexa_analysis_obj->prepare_analysis( -lane => $lane );

    }

    $j++;
}

my %analyzing_runs = $dbc->Table_retrieve( 'Run,SolexaRun,Flowcell', [ 'Run_ID', 'Lane', 'Flowcell_Code', 'SolexaRun_Type' ], "WHERE SolexaRun.FK_Run__ID = Run.Run_ID and Run.Run_Status = 'Analyzing' and FK_Flowcell__ID = Flowcell_ID" );
my $index = 0;
my %generated_temperature_graphs;
foreach my $run_id ( @{ $analyzing_runs{Run_ID} } ) {
    my $run_object = new alDente::Run( -dbc           => $dbc, -run_id => $run_id );
    my $data_path  = $run_object->get_data_path( -dbc => $dbc, -run_id => $run_id );
    my $lane       = $analyzing_runs{Lane}[$index];
    my $flowcell       = $analyzing_runs{Flowcell_Code}[$index];
    my $solexarun_type = $analyzing_runs{SolexaRun_Type}[$index];
    if ($analyze_flowcell) {
        unless ( $flowcell =~ /$analyze_flowcell/ ) {

            $index++;
            next;
        }
    }

    my $solexa_analysis_obj = Illumina::Solexa_Analysis->new( -dbc => $dbc, -flowcell => $flowcell );
    if ( $solexa_analysis_obj->check_finished_analysis() ) {

        my $analysis_pipeline_id = $solexa_analysis_obj->get_analysis_software_pipeline();
        $dbc->Table_update_array( 'Solexa_Read', ['FKAnalysis_Pipeline__ID'], [$analysis_pipeline_id], "WHERE FK_Run__ID = $run_id", -autoquote => 1 );
    }
    $index++;
}

$Report->completed();

#$Report->DESTROY();

exit;

##############################
### Internal Functions
##############################

#####################################
sub send_notification_message {
#####################################
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $url        = $args{-url};
    my $link       = $args{ -link };
    my $email_body = ${ $args{-message} };
    my $subject    = $args{-subject};
    my $testing    = defined $args{-testing} ? $args{-testing} : 0;

    if ($url) { $email_body .= "\n\n" . Link_To( $url, $link ) }

    my $ok = alDente::Subscription::send_notification(
        -dbc          => $dbc,
        -name         => 'RTA analysis check',
        -from         => 'Files check<aldente@bcgsc.bc.ca>',
        -subject      => "$subject",
        -body         => "$email_body",
        -content_type => 'html',
        -testing      => $testing
    );
    return;
}

