#!/usr/local/bin/perl

use strict;
use DBI;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use Data::Dumper;
use RGTools::RGIO;
use RGTools::Process_Monitor;

use vars qw($opt_help $opt_quiet $opt_host $opt_dbase $opt_user $opt_password $opt_flowcell $opt_genome $opt_analysis_type $opt_lanes $opt_cycles $opt_use_bases);

use Getopt::Long;
use Sequencing::SolexaRun;
use Sequencing::Solexa_Analysis;
use alDente::Run;
&GetOptions(
	    'help'                      => \$opt_help,
	    'quiet'                     => \$opt_quiet,
            'host=s'                    => \$opt_host,
            'dbase=s'                   => \$opt_dbase,
            'user=s'                    => \$opt_user,
            'password=s'                => \$opt_password,
            'flowcell=s'                => \$opt_flowcell,
            'genome=s'                  => \$opt_genome,
            'analysis_type=s'           => \$opt_analysis_type,
            'lanes=s'                   => \$opt_lanes,
            'cycles=s'                  => \$opt_cycles,
            'use_bases=s'               => \$opt_use_bases,
	    );

my $help  = $opt_help;
my $quiet = $opt_quiet;

#my $dbase = 'alDente_unit_test_DB';
my $host  = $opt_host || 'lims02';
my $dbase = $opt_dbase || 'sequence';
my $analyse_flowcell = $opt_flowcell;
my $genome = $opt_genome;
my $use_bases = $opt_use_bases;
my $cycles = $opt_cycles;
my $user  = $opt_user;
my $pwd   = $opt_password;
my $GENOME_PATH = "/home/aldente/public/reference/genomes/";

unless ($user && $pwd) {
    Message("Error: Must specify user and password");
    exit;
}
require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


my $Report = Process_Monitor->new();

my $data = Sequencing::SolexaRun::get_data_acquired_runs(-dbc=>$dbc,-flowcell=>$analyse_flowcell);
my $index = 0;
my @analyze_flowcells =();
while (defined $data->{Run_ID}[$index]) {
    my $run_id = $data->{Run_ID}[$index];
    my $flowcell_id = $data->{Flowcell_ID}[$index];
    my $flowcell = $data->{Flowcell_Code}[$index];
    my $machine = $data->{FK_Equipment__ID}[$index]; 
    my $solexarun_type = $data->{SolexaRun_Type}[$index];
    my ($analysis_pipeline) = $dbc->Table_find('Machine_Default,Analysis_Software', 'Analysis_Software_Path', "WHERE FKMachine_Analysis_Software__ID = Analysis_Software_ID and FK_Equipment__ID = $machine");
    print "Analyzing flowcell $flowcell";
    $Report->set_Message("Analyzing flowcell $flowcell"); 
    
    if (grep /^$flowcell$/, @analyze_flowcells) {
        $index++;
        next;
    } 
    else {
        print "Analysis Pipeline $analysis_pipeline\n";
        my $solexa_obj = Sequencing::Solexa_Analysis->new(-flowcell=>"$flowcell",-solexa_bin=>"$analysis_pipeline",-dbc=>$dbc);        
        # prepare the analysis
        #$solexa_obj->set_control_lane(-control_lane=>8);
        $solexa_obj->set_data_directory(); 
        my $ipar_analysis = $solexa_obj->check_for_ipar_analysis();
        if ($analysis_pipeline eq '/gsc/software/cluster/GAPipeline-1.4.0/bin' || $analysis_pipeline eq '/gsc/software/cluster/GAPipeline-1.5.0/bin') {
            $ipar_analysis = 0;
        }
        my $rta_analysis = $solexa_obj->check_for_rta_analysis();
        print "RTA $rta_analysis\n";
        if ($ipar_analysis) { 
            $solexa_obj->set_image_analysis_type(-image_analysis_type=>'IPAR');
            if ($solexa_obj->check_for_ipar_analysis_completed() ) {
                ## Update the runs to analyzing
                ## Do the analysis
                my $update_query = "UPDATE Flowcell,SolexaRun,Run SET Run_Status = 'Analyzing' WHERE FK_Run__ID = Run_ID and FK_Flowcell__ID = Flowcell_ID and Flowcell_Code = '$flowcell'";
                $Report->set_Detail("$update_query"); 
                $dbc->query(-query=>"$update_query");        
                $solexa_obj->run_goat();
                $solexa_obj->set_current_firecrest_link();
                my $command = $solexa_obj->prepare_analysis();
                my $current_link = $solexa_obj->get_current_firecrest_link();
                my ($directory)  = glob("$current_link/Bustard*"); 
                $directory =~/(Bustard.*)$/;
                my $bustard_dir = $1; 
                try_system_command("mkdir /projects/sbs_pipeline01/$flowcell; mv $current_link/$bustard_dir /projects/sbs_pipeline01/$flowcell/",-verbose=>1);
                try_system_command("ln -s /projects/sbs_pipeline01/$flowcell/$bustard_dir $current_link/$bustard_dir",-verbose=>1);
                $solexa_obj->run_qmake(-directory=>$directory);
                exit;
            } 
            else {
                ## wait for ipar robocopy to complete
                print "Waiting for ipar robocopy\n";
                $Report->set_Message("Waiting for ipar robocopy"); 
                $index++;
                next;
            }
        } elsif ($rta_analysis) {
             $solexa_obj->set_image_analysis_type(-image_analysis_type=>'RTA');
             if ($solexa_obj->check_for_rta_image_analysis_completed(-solexarun_type=>$solexarun_type) ) {
                ## Update the runs to analyzing
                ## Do the analysis      
                my $update_query = "UPDATE Flowcell,SolexaRun,Run SET Run_Status = 'Analyzing' WHERE FK_Run__ID = Run_ID and FK_Flowcell__ID = Flowcell_ID and Flowcell_Code = '$flowcell'";
                $dbc->query(-query=>"$update_query");
                $solexa_obj->run_goat();
                $solexa_obj->set_current_firecrest_link();
                my $command = $solexa_obj->prepare_analysis();
                my $current_link = $solexa_obj->get_current_firecrest_link();
                my ($directory)  = glob("$current_link/BaseCalls/GERALD*");
                 $directory =~/(GERALD.*)$/;
                my $gerald_dir = $1;
                try_system_command("mkdir /projects/sbs_pipeline01/$flowcell; mv $current_link/BaseCalls/$gerald_dir /projects/sbs_pipeline01/$flowcell/",-verbose=>1);
                try_system_command("ln -s /projects/sbs_pipeline01/$flowcell/$gerald_dir $current_link/BaseCalls/$gerald_dir",-verbose=>1);
                $solexa_obj->run_qmake(-directory=>$directory);
                exit;
                } else {
                ## wait for ipar robocopy to complete
                print "Waiting for ipar robocopy\n";
                $index++;
                next;
            }    
    
        }else {
            ## update the runs to analyzing
            if ($solexa_obj->check_for_image_copy_completed() ) {
                my $update_query = "UPDATE Flowcell,SolexaRun,Run SET Run_Status = 'Analyzing' WHERE FK_Run__ID = Run_ID and FK_Flowcell__ID = Flowcell_ID and Flowcell_Code = '$flowcell'";
                $dbc->query(-query=>"$update_query");
                $Report->set_Detail("$update_query"); 
                $solexa_obj->set_image_analysis_type(-image_analysis_type=>'Images');
                $solexa_obj->run_goat();
                $solexa_obj->set_current_firecrest_link(-images_override=>1);
                my $command = $solexa_obj->prepare_analysis();
                my $directory = $solexa_obj->get_current_firecrest_link();
                my @link = try_system_command(-command=>"stat -c %N $directory");
                my $linkstat = chomp_edge_whitespace($link[0]);
                if ($linkstat =~/^\`(.*)\' \-\> \`(.*)?\'$/) {
                    my $abs_path = $2; 
                    $abs_path =~/(C1-.*)$/;
                    my $firecrest_dir = $1;
                    try_system_command("mkdir /projects/sbs_pipeline01/$flowcell; mv $abs_path /projects/sbs_pipeline01/$flowcell/$firecrest_dir",-verbose=>1);
                    try_system_command("ln -s /projects/sbs_pipeline01/$flowcell/$firecrest_dir $abs_path",-verbose=>1);
                    $directory = $abs_path;
                }
                $solexa_obj->run_qmake(-directory=>$directory);
                exit;
            }
            else {
                print "Waiting for images\n";
                $index++;
                next;
            }
        }
        
    }
    push @analyze_flowcells, $flowcell;
    $index++;
}

$Report->completed();
$Report->DESTROY();

exit;

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
