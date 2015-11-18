#!/usr/local/bin/perl

use strict;

#use warnings;

use DBI;
use Data::Dumper;
use Getopt::Long;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../custom/GSC/modules";

use RGTools::RGIO;
use RGTools::RGmath;
use SDB::CustomSettings;
use SDB::DBIO;
use File::Basename;
use LWP::UserAgent;
use XML::Simple;
use Date::Calc;
use JSON;

use vars qw(%Configs $opt_help $opt_patient $opt_analysis $opt_barcode $opt_path $opt_filename $opt_descfile $opt_disease_abbr $opt_volume_name $opt_all $opt_bam_file $opt_host);

&GetOptions(
    'help|h|?'        => \$opt_help,
    'filename|name=s' => \$opt_filename,
    'disease_abbr=s'  => \$opt_disease_abbr,
    'volume_name=s'   => \$opt_volume_name,
    'host=s'          => \$opt_host,
    'all'             => \$opt_all,
    'bam_file=s'      => \$opt_bam_file,
);

my $help = $opt_help;

my $filename     = $opt_filename;
my $path         = $opt_path || "./";
my $disease_abbr = $opt_disease_abbr;
my $volume_name  = Cast_List( -to => 'string', -list => $opt_volume_name, -autoquote => 1 );
my $bam_file     = $opt_bam_file;
my $host         = $opt_host;
my $all          = $opt_all;

if ($help) {
    &display_help();
    exit;
}

my $CGHUB_REST_SUMMARY_URL = "https://cghub.ucsc.edu/cghub/metadata/analysisObject";
my $CGHUB_REST_FULL_URL    = "https://cghub.ucsc.edu/cghub/metadata/analysisAttributes";

my $dbc = SDB::DBIO->new(
    -dbase   => 'sequence',
    -host    => 'lims05',
    -user    => 'super_cron',
    -connect => 1
);

my @libs;

my $ua = LWP::UserAgent->new;
$ua->timeout(30);

my $query;
my @query_conditions;

my @analysis_uuids;
my @analysis_files;

if ($bam_file) {

    print "File used: $bam_file\n";

    my ( $filename, $dir ) = File::Basename::fileparse($bam_file);

    $filename =~ /s_(\d)_([a-zA-Z]{6})/;
    my $prefix  = $&;
    my $lane    = $1;
    my $index   = $2;
    my @reports = glob("$dir/Lane_${lane}_Indexed_Samples/s_${lane}*${index}*adapter_trimmed.report");

    if ( scalar(@reports) == 1 ) {

        my $report = $reports[0];
        print("Report found: $report\n");
        my @report_output = `tail -n +16 $report`;
        my $report_string = join( "", @report_output );

        print("Report statistics:\n");
        print( join( "", @report_output ) );

        print("Running adapter test\n");
        if ($host) {
            `ssh $host /home/pplettner/scripts/mirna_test.sh $bam_file`;
        }
        else {
            `/home/pplettner/scripts/mirna_test.sh $bam_file`;
        }
        open( FILE, "/home/pplettner/scripts/readlengths.$filename.txt" );
        my @test_result = <FILE>;
        print("Bam statistics:\n");
        print( join( "", @test_result ) );

        my $test_string = join( "", @test_result );
        close(FILE);

        if ( $test_string eq $report_string ) {
            print("Passed adapter test\n");
        }
        else {
            print("FAILED adapter test\n");
        }
        print("----------------------\n");
        `rm /home/pplettner/scripts/readlengths.$filename.txt`;
    }

    else {
        print("Couldn't find unique adapter report\n");
    }
}

elsif ($disease_abbr) {
    my @disease_abbrs = Cast_List( -list => $disease_abbr, -to => 'array' );
    push @query_conditions, "disease_abbr=(" . join( ' OR ', @disease_abbrs ) . ")";

    push @query_conditions, "study=phs000178";
    push @query_conditions, "state=live";
    push @query_conditions, "center_name=BCCAGSC";
    push @query_conditions, "filename=*mirna.bam";

    my $query = join( '&', @query_conditions );

    print "MAIN QUERY: $query\n";

    my $cgHub_summary_xml;
    my $response = $ua->get("$CGHUB_REST_SUMMARY_URL?$query");

    if ( $response->is_success ) {
        $cgHub_summary_xml = $response->decoded_content;    # or whatever
    }
    else {
        print "ERROR: Can't retrieve cgHub data for query $query\n";
        print $response->status_line . "\n";
        next;
    }

    print "Finished query\n";

    my $cgHub_summary_hash = XMLin( $cgHub_summary_xml, ForceArray => [ 'Result', 'EXPERIMENT', 'ANALYSIS', 'RUN' ] );

    my %results = %{ $cgHub_summary_hash->{Result} } if ( $cgHub_summary_hash->{Result} );
    print "Loaded summary results\n";
    while ( my ( $num, $bam_summary_hash ) = each(%results) ) {
        push @analysis_uuids, $bam_summary_hash->{analysis_id};
    }
}

elsif ($volume_name) {
    my $table
        = "Metadata_Submission JOIN Metadata_Object ON FK_Metadata_Object__ID = Metadata_Object_ID and Object_Type = 'Analysis' JOIN Analysis_Link ON FKAnalysis_Metadata_Object__ID = Metadata_Object_ID JOIN Analysis_File ON FK_Analysis_File__ID = Analysis_File_ID JOIN Status ON Metadata_Submission.FK_Status__ID = Status_ID and Status_Type='Submission' JOIN Submission_Volume ON Metadata_Submission.FK_Submission_Volume__ID = Submission_Volume_ID";

    my $fields    = "Analysis_File.Name,Unique_Identifier";
    my $condition = "where Volume_Name in ($volume_name)";

    unless ($all) {
        $condition .= " and Status_Name not in ('Rejected','Aborted')";
    }
    my $order = "Analysis_File_ID";

    my @uuid_entries = $dbc->Table_find(
        -table     => $table,
        -fields    => $fields,
        -condition => $condition,
        -order_by  => $order
    );

    foreach my $entry (@uuid_entries) {
        my ( $afile, $uuid ) = split /,/, $entry;
        push @analysis_uuids, $uuid;
        push @analysis_files, $afile;
    }

}

my $log_file_handle;

foreach my $i ( 0 .. $#analysis_uuids ) {

    my $analysis_id   = $analysis_uuids[$i];
    my $analysis_file = $analysis_files[$i];

    #`rm /home/sequence/Submissions/cgHub/$analysis_id/mirna_adapter_test.log`;
    if ( -e "/home/sequence/Submissions/cgHub/$analysis_id/mirna_adapter_test.log" ) {

        print "Analysis $analysis_id\n";
        print `tail -2 /home/sequence/Submissions/cgHub/$analysis_id/mirna_adapter_test.log`;

    }
    else {

        open( $log_file_handle, ">/home/sequence/Submissions/cgHub/$analysis_id/mirna_adapter_test.log" );

        print_log("\nAnalysis $analysis_id\n");
        print_log( "-" x 45, "\n" );

        if ($disease_abbr) {
            my $query = "analysis_id=$analysis_id";

            my $bam_detailed_xml;
            my $response = $ua->get("$CGHUB_REST_FULL_URL?$query");

            if ( $response->is_success ) {
                $bam_detailed_xml = $response->decoded_content;    # or whatever
            }
            else {
                print_log("ERROR: Can't retrieve cgHub data for query $query\n");
                print_log( $response->status_line . "\n" );
                next;
            }

            my $bam_detailed_hash = XMLin( $bam_detailed_xml, ForceArray => [ 'Result', 'EXPERIMENT', 'ANALYSIS', 'RUN' ] );

            my $metadata = $bam_detailed_hash->{Result}->{1};
            my $checksum;
            my $file_list = $metadata->{files}->{file};

            my @file_array;
            if ( ref($file_list) eq 'ARRAY' ) {
                @file_array = @$file_list;
            }
            else {
                @file_array = ($file_list);
            }
            foreach my $file_hash (@file_array) {
                my $filename = $file_hash->{filename};

                if ( $filename =~ /\.bam$/ ) {
                    $checksum = $file_hash->{checksum}->{content};
                }
            }
            my $run_labels = $metadata->{analysis_xml}->{ANALYSIS_SET}->{ANALYSIS}->[0]->{ANALYSIS_TYPE}->{REFERENCE_ALIGNMENT}->{RUN_LABELS}->{RUN};
            if ( scalar(@$run_labels) == 1 ) {
                my $run         = $run_labels->[0];
                my $run_id      = $run->{read_group_label};
                my $flowcell    = $run->{data_block_name};
                my $run_library = $run->{refname};

                my $indexed_lib;
                my $run_dir;
                if ( $run_library =~ /(.*)\/(.*)/ ) {
                    $run_dir     = $1;
                    $indexed_lib = $2;
                }
                else {
                    $run_dir = $run_library;
                }

                my @output = $dbc->Table_find(
                    -table =>
                        "Run JOIN Plate ON FK_Plate__ID = Plate_ID JOIN SolexaRun ON SolexaRun.FK_Run__ID = Run_ID JOIN Flowcell ON FK_Flowcell__ID = Flowcell_ID JOIN Run_Analysis on Run.Run_ID = Run_Analysis.FK_Run__ID LEFT JOIN Multiplex_Run_Analysis ON FK_Run_Analysis__ID = Run_Analysis_ID JOIN Sample AS Indexed_Sample ON Multiplex_Run_Analysis.FK_Sample__ID = Indexed_Sample.Sample_ID JOIN Solexa_Read ON Solexa_Read.FK_Run__ID = Run_ID JOIN Pipeline ON Solexa_Read.FKAnalysis_Pipeline__ID = Pipeline_ID",
                    -fields    => "Plate.FK_Library__Name,Run_Directory,Lane,Adapter_Index,Indexed_Sample.FK_Library__Name,Solexa_Read.FKAnalysis_Pipeline__ID,Pipeline_Name",
                    -condition => "WHERE Run_Analysis_Status = 'Analyzed' and Current_Analysis = 'Yes' and Run_Directory = '$run_dir' and Flowcell_Code = '$flowcell' and Run_ID = $run_id and Indexed_Sample.FK_Library__Name = '$indexed_lib'",
                    -distinct  => 1
                );
                if ( scalar(@output) == 1 ) {
                    my @cols          = split /,/, $output[0];
                    my $pooled_lib    = $cols[0];
                    my $lane          = $cols[2];
                    my $index         = $cols[3];
                    my $pipeline_id   = $cols[5];
                    my $pipeline_name = $cols[6];
                    my @bams          = glob( "/home/aldente/private/Projects/TCGA/$pooled_lib/AnalyzedData/$run_dir/Solexa/Data/current/BaseCalls/BWA_*/s_${lane}_${index}*bam" );
                    @bams = reverse sort @bams;

                    my $local_bam_file;
                    foreach my $bam (@bams) {
                        print_log("Calculating md5 for $bam\n");
                        my $curr_checksum = RGTools::RGIO::get_MD5( -file => $bam );

                        #print "Checksum $curr_checksum, should be $checksum\n";
                        if ( $curr_checksum eq $checksum ) {
                            $local_bam_file = $bam;
                            last;
                        }
                    }

                    print_log("Match: $local_bam_file\n");

                    if ($local_bam_file) {
                        print_log( "Pipeline used: $pipeline_name, ID: $pipeline_id\n" );
                        my ( $filename, $dir ) = File::Basename::fileparse($local_bam_file);
                        $filename =~ /(s_${lane}_\w+?)_/;
                        my $prefix  = $1;
                        my @reports = glob("$dir/Lane_${lane}_Indexed_Samples/s_${lane}*${index}*adapter_trimmed.report");

                        if ( scalar(@reports) == 1 ) {

                            my $report = $reports[0];
                            print_log("Report found: $report\n");
                            my @report_output = `tail -n +16 $report`;
                            my $report_string = join( "", @report_output );

                            print_log("Report statistics:\n");
                            print_log( join( "", @report_output ) );

                            print_log("Running adapter test\n");
                            if ($host) {
                                `ssh $host /home/pplettner/scripts/mirna_test.sh $local_bam_file`;
                            }
                            else {
                                `/home/pplettner/scripts/mirna_test.sh $local_bam_file`;
                            }
                            open( FILE, "/home/pplettner/scripts/readlengths.$filename.txt" );
                            my @test_result = <FILE>;
                            print_log("Bam statistics\n");
                            print_log( join( "", @test_result ) );

                            my $test_string = join( "", @test_result );
                            close(FILE);

                            if ( $test_string eq $report_string ) {
                                print_log("Passed adapter test\n");
                            }
                            else {
                                print_log("FAILED adapter test\n");
                            }
                            print_log("----------------------\n");
                        }

                        else {
                            print_log("Couldn't find unique adapter report\n");
                        }

                    }

                    else {
                        print_log("No matching bam file found\n");
                    }
                }

            }

            else {
                print_log("Merged bam found\n");
            }

        }

        elsif ($volume_name) {
            my ( $filename, $dir ) = File::Basename::fileparse($analysis_file);
            $filename =~ /^s_(\d)_(\w{6})_/;
            my $lane  = $1;
            my $index = $2;

            $dir =~ /\/home\/aldente\/private\/Projects\/TCGA\/(\w+?)\/AnalyzedData\/(.+?)\/Solexa/;

            my $pooled_lib = $1;
            my $run_dir    = $2;

            #print Dumper $pooled_lib,$run_dir,$lane,$index;

            my @reports = glob( "$dir/Lane_${lane}_Indexed_Samples/s_${lane}*${index}*adapter_trimmed.report" );

            if ( scalar(@reports) == 1 ) {

                my $report = $reports[0];
                print_log("Report found: $report\n");
                my @report_output = `tail -n +16 $report`;
                my $report_string = join( "", @report_output );

                print_log("Report statistics:\n");
                print_log( join( "", @report_output ) );

                print_log("Running adapter test\n");
                if ($host) {
                    `ssh $host /home/pplettner/scripts/mirna_test.sh $analysis_file`;
                }
                else {
                    `/home/pplettner/scripts/mirna_test.sh $analysis_file`;
                }
                open( FILE, "/home/pplettner/scripts/readlengths.$filename.txt" );
                my @test_result = <FILE>;
                print_log("Bam statistics\n");
                print_log( join( "", @test_result ) );

                my $test_string = join( "", @test_result );
                close(FILE);

                if ( $test_string eq $report_string ) {
                    print_log("Passed adapter test\n");
                }
                else {
                    print_log("FAILED adapter test\n");
                }
                print_log("----------------------\n");
            }

            else {
                print_log("Couldn't find unique adapter report\n");
            }
        }

        close(LOGFILE);

    }
}

sub print_log {
    print STDOUT @_;
    print {$log_file_handle} @_;
}

#print join(',',@libs)."\n";

##################
sub display_help {
##################
    print <<HELP;

Syntax
======
mirna_adapter_test.pl

Arguments:
=====
-- optional arguments --
-help, -h, -?       : displays this help. (optional)

Example
=======



HELP

}

