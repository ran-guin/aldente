#!/usr/local/bin/perl

use strict;
use warnings;

use DBI;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
use RGTools::Conversion;
use SDB::DBIO;
use SDB::CustomSettings;
use Sequencing::Solexa_Analysis;
use Sequencing::SolexaRun;

use alDente::Run;
use alDente::SDB_Defaults;
use alDente::Notification;

use Data::Dumper;
use Getopt::Long;
use RGTools::Process_Monitor;
use XML::Simple;

use vars qw($opt_help $opt_quiet $opt_password $opt_dbase $opt_user $opt_host);

&GetOptions(
    'help'       => \$opt_help,
    'quiet'      => \$opt_quiet,
    'dbase=s'    => \$opt_dbase,
    'user=s'     => \$opt_user,
    'host=s'     => \$opt_host,
    'password=s' => \$opt_password
);

my $host  = $opt_host  || $Configs{TEST_HOST};
my $dbase = $opt_dbase || $Configs{TEST_DATABASE};
my $user = 'super_cron';
my $pwd  = $opt_password;

my $Report = Process_Monitor->new();
my $dbc    = new SDB::DBIO(
    -host    => $host,
    -dbase   => $dbase,
    -user    => $user,
    -connect => 1,
);

my $in_process_runs = Sequencing::SolexaRun::get_in_process_runs( -dbc => $dbc );
my $j               = 0;
my $DELAY_THRESHOLD = 4;
my %flowcell_time_check;
foreach my $run_id ( @{ $in_process_runs->{'Run_ID'} } ) {
    my $flowcell            = $in_process_runs->{'Flowcell_Code'}[$j];
    my $solexa_analysis_obj = Sequencing::Solexa_Analysis->new( -dbc => $dbc, -flowcell => $flowcell );
    my @flowcell_path       = $solexa_analysis_obj->get_flowcell_directory();
    my $run_dir             = $in_process_runs->{'Run_Directory'}[$j];
    my $lane                = $in_process_runs->{'Lane'}[$j];
    my $lane_images         = "L00$lane";
    my $cycles              = $in_process_runs->{'Cycles'}[$j];

    my $solexarun_type  = $in_process_runs->{'SolexaRun_Type'}[$j];
    my $expected_cycles = $cycles;

    my @first_last_cycles = ();

    my $read_info = $solexa_analysis_obj->parse_run_info_file( -flowcell_directory => $flowcell_path[0] );

    my @reads = ();
    if ( $read_info->{Run}{Reads}{Read} ) {
        if ( ref( $read_info->{Run}{Reads}{Read} ) =~ /HASH/ ) {
            push @reads, $read_info->{Run}{Reads}{Read};
        }
        elsif ( ref( $read_info->{Run}{Reads}{Read} ) =~ /ARRAY/ ) {
            @reads = @{ $read_info->{Run}{Reads}{Read} };
        }
        else {
            ## no reads;
        }
    }

    foreach my $read (@reads) {
        my $first_cycle = $read->{FirstCycle};
        my $last_cycle  = $read->{LastCycle};
        if ( $first_cycle && $last_cycle ) {
            push @first_last_cycles, ( $first_cycle, $last_cycle );
        }
        elsif ( $read->{NumCycles} ) {
            my $cycle_index = int(@first_last_cycles);
            if ( $first_last_cycles[ $cycle_index - 1 ] ) {
                push @first_last_cycles, ( $first_last_cycles[ $cycle_index - 1 ] + 1, $first_last_cycles[ $cycle_index - 1 ] + $read->{NumCycles} );
            }
            else {
                push @first_last_cycles, ( 1, $read->{NumCycles} );
            }
        }
    }
    my $run_completed = 0;
    my $cycles_found  = 0;
    foreach my $flowcell_path (@flowcell_path) {
        my $run_completed_file_found = 0;

        ## CHECK Run.completed
        $flowcell_path =~ /.*\/(.*$flowcell)\/*$/;
        my $flowcell_run = $1;
        $flowcell_run =~ /\d{6}_(.*)_\d{4}_$flowcell/i;
        my ($machine) = $dbc->Table_find( 'Run,RunBatch,Equipment', 'Equipment_Name', "WHERE FK_RunBatch__ID = RunBatch_ID and FK_Equipment__ID = Equipment_ID and Run_ID = $run_id" );
        print "Run $run_id Flowcell PATH $flowcell_path MACHINE $machine\n";
        my $check_images_cmd = "";
        my $thumbnail_path   = "$flowcell_path/Thumbnail_Images/";

        if ( -e "$thumbnail_path" ) {
            my $current_datetime = convert_date( &date_time(), 'SQL' );
            my $min_difference   = 0;
            my $affected_cycle   = "";
            my $cycle_number;
            for ( my $i = 1; $i <= 8; $i++ ) {

                my @cycles = split '\n', try_system_command("ls -ltrd $thumbnail_path/L00$i/C*");

                #print Dumper \@cycles;
                my $number_cycles = int @cycles;
                my $latest_cycle  = $cycles[ $number_cycles - 1 ];
                $latest_cycle =~ /.*($thumbnail_path.*)$/;

                my ($latest_cycle_time) = try_system_command("stat -c '%y' $1");
                $latest_cycle_time = substr( $latest_cycle_time, 0, 16 );
                my $modified_cycle = convert_date( $latest_cycle_time, 'SQL' );
                my %data = $dbc->Table_retrieve( -fields => ["TIME_FORMAT(TIMEDIFF('$current_datetime','$modified_cycle'),'%H') as Diff"] );
                $latest_cycle =~ /C(\d+)\.1/;
                $cycle_number = $1;
                my $difference = int( $data{Diff}[0] );
                if ( ( $difference < $min_difference ) || !$min_difference ) {
                    $min_difference = $difference;
                    $affected_cycle = "$latest_cycle";
                }
            }
            if ( grep /^$cycle_number$/, @first_last_cycles ) {
                print "Skipping Cycle $cycle_number Diff $min_difference\n";
            }
            else {
                print "Min DIFF $min_difference Affected: $affected_cycle\n";
                if ( $min_difference > $DELAY_THRESHOLD ) {
                    $flowcell_time_check{$flowcell}{Message} = "Run ($flowcell) on Machine ($machine) has been stalled for $min_difference hours on cycle $cycle_number";
                    $flowcell_time_check{$flowcell}{Machine} = $machine;
                }
            }
        }
    }
    $j++;
}
if (%flowcell_time_check) {
    my $from_address      = 'aldente@bcgsc.ca';
    my $table             = HTML_Table->new( -title => 'Check SLX Machine Status' );
    my @machines_affected = ();
    foreach my $flowcell ( keys %flowcell_time_check ) {
        $table->Set_Row( [ $flowcell_time_check{$flowcell}{Message} ] );
        $Report->set_Message( $flowcell_time_check{$flowcell}{Message} );
        push @machines_affected, $flowcell_time_check{$flowcell}{Machine};
    }
    my $machines_affected = Cast_List( -list => \@machines_affected, -to => 'String' );
    my $to_address = 'echuah@bcgsc.ca,rmoore@bcgsc.ca,mmayo@bcgsc.ca,tzeng@bcgsc.ca';
    $Report->set_Message( "List of recipients: " . $to_address );

    #my $to_address = 'echuah@bcgsc.ca';
    my $ok = alDente::Subscription::send_notification(
        -dbc          => $dbc,
        -name         => "Check SLX Machine Status",
        -to           => $to_address,
        -from         => $from_address,
        -subject      => "Check SLX Machine Status ($machines_affected)",
        -body         => $table->Printout(0),
        -content_type => 'html',
        -bypass       => 1
    );
    unless ($ok) {
        $Report->set_Warning("Warning: Problem with delivering mail ! (subject : Check SLX Machine Status ($machines_affected))");
    }
}
$Report->completed();
$Report->DESTROY();
exit;
