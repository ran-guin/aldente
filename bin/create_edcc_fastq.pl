#!/usr/local/bin/perl

use strict;

#use warnings;

use Data::Dumper;
use Getopt::Long;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../custom/GSC/modules";

use RGTools::RGIO;
use RGTools::RGmath;
use SDB::CustomSettings;
use SDB::DBIO;
use SRA::Data_Submission;
use Illumina::Run_Analysis;

our ( $opt_help, $opt_library, $opt_link_path, $opt_host, $opt_dbase );

&GetOptions(
    'help|h|?'      => \$opt_help,
    'lib|library=s' => \$opt_library,
    'link_path=s'   => \$opt_link_path,
    'host=s'        => \$opt_host,
    'dbase=s'       => \$opt_dbase,
);

my $help      = $opt_help;
my @libraries = Cast_List( -to => 'array', -list => $opt_library );
my $link_path = $opt_link_path || '/projects/edcc/data/CEMT/fastq';
my $host      = $opt_host || 'limsdev04';
my $dbase     = $opt_dbase || 'seqdev';

if ($help) {
    &display_help();
    exit;
}

my $login_name = 'aldente_admin';
my $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $login_name, -connect => 1 );

my $Data_Submission = new SRA::Data_Submission( -dbc => $dbc );

foreach my $library (@libraries) {

    my @fields = (
        "Project.Project_Name as Project",                     "Library.Library_Name",
        "Multiplex_Library.Library_Name as Multiplex_Library", "Multiplex_Run_Analysis.Adapter_Index as Adapter",
        "Sample.Sample_Name as Sample",                        "Multiplex_Sample.Sample_Name as Multiplex_Sample",
        "Run.Run_ID",                                          "Flowcell.Flowcell_Code as Flowcell",
        "SolexaRun.Lane",                                      "SolexaRun.SolexaRun_Type",
        "Run.QC_Status",                                       "Run.Run_Validation",
        "Run.Billable",                                        "CASE WHEN (Multiplex_Run_Analysis.Adapter_Index is not NULL) THEN concat(Run.Run_ID,'_',Multiplex_Sample.Sample_ID) ELSE concat(Run.Run_ID,'_',Sample.Sample_ID) END as Trace_ID",
        "Library_Strategy.Library_Strategy_Name",
    );

    my $condition = "WHERE Run_Test_Status = 'Production' AND Run.Run_Validation = 'Approved' AND Run_Status = 'Analyzed' and Run.QC_Status = 'Passed'";

    ### get_Run_data orders by Run_ID,Sample_ID,Multiplex_Sample_ID by default

    my $Run_data = $Data_Submission->get_Run_data(
        -fields    => \@fields,
        -library   => $library,
        -condition => $condition,
        -order     => 'Run.Run_ID',
        -distinct  => 1,
    );

    my @trace_tuples;

    foreach my $tuple ( @{ $Run_data->{Trace_ID} } ) {
        my ( $run_id, $sample_id ) = split /_/, $tuple;

        push @trace_tuples, [ $run_id, $sample_id ];
    }

    @fields = (
        "Run.Run_ID",                         "Run_Analysis.Run_Analysis_ID",     "Multiplex_Run_Analysis.Adapter_Index", "Run_Analysis.Run_Analysis_Started",
        "Run_Analysis.Run_Analysis_Finished", "Run_Analysis.Run_Analysis_Status", "Multiplex_Run_Analysis.Multiplex_Run_QC_Status",
    );

    $condition = "WHERE Run_Analysis.Run_Analysis_Status = 'Analyzed' AND Run_Analysis.Run_Analysis_Test_Mode = 'Production' AND Run_Analysis.Current_Analysis = 'Yes' AND Run_Analysis.Run_Analysis_Type = 'Secondary'";

    my $Run_Analysis_data = $Data_Submission->get_Run_Analysis_data(
        -fields       => \@fields,
        -trace_tuples => \@trace_tuples,
        -condition    => $condition,
        -order        => 'Run.Run_ID',
        -distinct     => 1,
    );

    my @RAs;
    for my $key (keys %{$Run_Analysis_data}) {
        for my $key2 (keys %{$Run_Analysis_data->{$key}}) {
            push @RAs, @{$Run_Analysis_data->{$key}{$key2}{'Run_Analysis.Run_Analysis_ID'}};
        }
    }

    my $num_Run_items = scalar( @{ $Run_data->{'Run.Run_ID'} } );
    my $num_RA_items  = scalar( @RAs );

    if ( $num_Run_items != $num_RA_items ) {
        print "Library $library has run analysis/run mismatch\n";
    }

    foreach my $i ( 0 .. $num_Run_items - 1 ) {

        my $library_strategy = $Run_data->{'Library_Strategy.Library_Strategy_Name'}->[$i];
        my $lib              = $Run_data->{'Library.Library_Name'}->[$i];
        my $indexed_lib      = $Run_data->{Multiplex_Library}->[$i];
        my $adapter          = $Run_data->{Adapter}->[$i];
        my $run_id           = $Run_data->{'Run.Run_ID'}->[$i];
        my $flowcell         = $Run_data->{Flowcell}->[$i];
        my $lane             = $Run_data->{'SolexaRun.Lane'}->[$i];
        my $read_type        = lc( $Run_data->{'SolexaRun.SolexaRun_Type'}->[$i] );
	my $trace            = $Run_data->{Trace_ID}->[$i];
	my ( $tmp, $sample_id ) = split /_/, $trace;	

        my $new_name;

        my $Solexa_Analysis = Illumina::Solexa_Analysis->new( -dbc => $dbc, -flowcell => $flowcell );

        my $bustard_dir;
        my @bustard_dirs = $Solexa_Analysis->get_bustard_directory( -lane => $lane );

        if ( scalar(@bustard_dirs) == 1 ) {
            $bustard_dir = $bustard_dirs[0];
        }
        else {
            print "Did not find unique bustard directory for flowcell $flowcell, lane $lane\n";
            next;
        }

        my $concat_fastq_dir = File::Spec->catdir( $bustard_dir, 'concat_fastq' );

        if ($indexed_lib) {
            $new_name = "$library_strategy.$lib-$indexed_lib-$adapter.$run_id.$flowcell.$lane";
        }
        else {
            $new_name = "$library_strategy.$lib.$run_id.$flowcell.$lane";
        }

        ### Assuming that there are ever only single and paired end reads

        my $read1_link_path = File::Spec->catfile( $link_path, "$new_name.1.fastq.gz" );
        my $read2_link_path = File::Spec->catfile( $link_path, "$new_name.2.fastq.gz" );

        my ( $fastq1_filename, $fastq2_filename );

        if ($adapter) {
            $fastq1_filename = 's_' . $lane . '_1_' . $adapter . '_concat.fastq.gz';
            $fastq2_filename = 's_' . $lane . '_2_' . $adapter . '_concat.fastq.gz';
        }
        else {
            $fastq1_filename = 's_' . $lane . '_1_concat.fastq.gz';
            $fastq2_filename = 's_' . $lane . '_2_concat.fastq.gz';
        }

        my $fastq1_path = File::Spec->catfile( $concat_fastq_dir, $fastq1_filename );
        my $fastq2_path = File::Spec->catfile( $concat_fastq_dir, $fastq2_filename );

        if ( $read_type eq 'single' ) {

            unless ( -f $fastq1_path ) {
                my $RA_id = $Run_Analysis_data->{$run_id}{$sample_id}{Run_Analysis_ID}->[$i];
                print "Creating fastq for run analysis $RA_id\n";
                my $RA     = new Illumina::Run_Analysis( -dbc           => $dbc );
                my $output = $RA->create_concat_fastq( -run_analysis_id => $RA_id );
            }

            my $success = RGTools::RGIO::create_link(
                -link_path => $read1_link_path,
                -file      => $fastq1_path,
            );
        }

        elsif ( $read_type eq 'paired' ) {

            unless ( -f $fastq1_path and -f $fastq2_path ) {
                my $RA_id = $Run_Analysis_data->{$run_id}{$sample_id}{Run_Analysis_ID}->[$i];
                print "Creating fastq for run analysis $RA_id\n";
                my $RA     = new Illumina::Run_Analysis( -dbc           => $dbc );
                my $output = $RA->create_concat_fastq( -run_analysis_id => $RA_id );
            }

            my $success = RGTools::RGIO::create_link(
                -link_path => $read1_link_path,
                -file      => $fastq1_path,
            );
            $success = RGTools::RGIO::create_link(
                -link_path => $read2_link_path,
                -file      => $fastq2_path,
            );
        }
    }

}

##################
sub display_help {
##################
    print <<HELP;

create_edcc_fastq.pl - This is meant to create fastq's for the CEMT/EDCC project and symlink them into a folder with a set nomenclature:

Indexed lanes:
library_strategy.run_library-sublibrary-index.run.flowcell.lane.fastq.gz

Non-indexed lanees:
library_strategy.library.run.flowcell.lane.fastq.gz

Arguments:
=====
--library | --lib	: Library names of fastq's that should be symlinked and created (if necessary)

-- optional arguments --
--link_path		: Folder where these fastq's should be symlinked from
--help, -h, -?		: Displays this help. (optional)
--host=s		: Database host
--dbase=s		: Database name

Example
=======
./create_edcc_fastq.pl --lib A26700,A26701


HELP

}
