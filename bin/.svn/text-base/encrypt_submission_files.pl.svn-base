#!/usr/local/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Benchmark;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Departments";

use SDB::DBIO;
use RGTools::RGIO;
use SDB::CustomSettings;
use File::Basename;
use File::Find::Rule;
use List::MoreUtils;
use SRA::Data_Submission;

use vars qw(%Configs $opt_help $opt_archive $opt_host $opt_dbase);

&GetOptions(
    'help|h|?'  => \$opt_help,
    'archive=s' => \$opt_archive,
    'host=s'    => \$opt_host,
    'dbase|d=s' => \$opt_dbase,
);

my $help  = $opt_help;
my $host  = $opt_host || 'lims05';
my $dbase = $opt_dbase || 'sequence';

if ($help) {
    &display_help();
    exit;
}

my $dbc = SDB::DBIO->new(
    -dbase   => $dbase,
    -host    => $host,
    -user    => 'aldente_admin',
    -connect => 1,
);

my $WORKSPACE_DIR = $Configs{data_submission_workspace_dir};

### Delete encrypted files after 2 weeks

my $MAX_ENCRYPTED_FILE_AGE_SEC = 1209600;
my $lock_file = File::Spec->catfile( $WORKSPACE_DIR, ".encrypt_submission_files.lock" );

# exit if locked
if ( -e $lock_file ) {
    print "The script is locked.\n";
    exit;
}
else {
    my $lock_filename = File::Basename::fileparse($lock_file);

    my $ok = RGTools::RGIO::create_file(
        -name    => $lock_filename,
        -content => '',
        -path    => $WORKSPACE_DIR,
        -chgrp   => 'lims',
        -chmod   => 'g+w',
    );
}

### Clean up old encrypted files

my $EGA_workspace_dir = File::Spec->catdir( $WORKSPACE_DIR, 'EGA' );
my @encrypted_files = File::Find::Rule->file->name('*.gpg')->in($EGA_workspace_dir);

foreach my $file (@encrypted_files) {
    my @stat_vals         = stat($file);
    my $file_mtime        = $stat_vals[9];
    my $time_since_modify = time() - $file_mtime;

    if ( $time_since_modify > $MAX_ENCRYPTED_FILE_AGE_SEC ) {
        print "$file older than $MAX_ENCRYPTED_FILE_AGE_SEC seconds, deleting\n";
        unlink($file);
    }
}

my $Data_Submission = new SRA::Data_Submission( -dbc => $dbc );

###
### Analysis_Files where checksum hasn't been calculated yet
###

my $Analysis_data = $Data_Submission->get_Analysis_Submission_data(
    -fields          => [ 'Analysis_File.Analysis_File_ID', 'Analysis_File.Analysis_File_Path', 'Flowcell.Flowcell_Code', 'SolexaRun.Lane', 'Multiplex_Run_Analysis.Adapter_Index', 'Analysis_File.Encrypted_Checksum' ],
    -required_tables => 'Organization',
    -condition => "WHERE Analysis_File.Encrypted_Checksum is null and Organization.Organization_Name in ('EGA')"
);

my $num_items = scalar( @{ $Analysis_data->{'Analysis_File.Analysis_File_ID'} } );

foreach my $i ( 0 .. $num_items - 1 ) {
    my $analysis_file_id   = $Analysis_data->{'Analysis_File.Analysis_File_ID'}->[$i];
    my $analysis_file_path = $Analysis_data->{'Analysis_File.Analysis_File_Path'}->[$i];
    my $encrypted_checksum = $Analysis_data->{'Analysis_File.Encrypted_Checksum'}->[$i];
    my $flowcell           = $Analysis_data->{'Flowcell.Flowcell_Code'}->[$i];
    my $lane               = $Analysis_data->{'SolexaRun.Lane'}->[$i];
    my $index              = $Analysis_data->{'Multiplex_Run_Analysis.Adapter_Index'}->[$i];

    if ( -e $analysis_file_path ) {
        my ( $analysis_filename, $analysis_file_dir ) = File::Basename::fileparse($analysis_file_path);
        my @analysis_dirs = File::Spec->splitdir($analysis_file_dir);

        my $output_filename;

        ### If the analysis file mentioned is directly from the basecall directory
        ### it needs to be renamed
        ###
        ### Ex: /home/aldente/private/Projects/TCGA/MX1043/AnalyzedData/MX1043-1./Solexa/Data/current/BaseCalls/BWA_2013-10-30/s_1_GGTTTC_single.dup.sorted.bam

        if ( $analysis_filename =~ /^s_\d.*bam$/ and $analysis_dirs[-1] =~ /^BWA_\d\d\d\d-\d\d-\d\d$/ ) {

            if ($index) {
                $output_filename = $flowcell . "_" . $lane . "_" . $index . ".bam.gpg";
            }
            else {
                $output_filename = $flowcell . "_" . $lane . ".bam.gpg";
            }
        }
        else {
            $output_filename = $analysis_filename . ".gpg";
        }

        my $output_file_path = File::Spec->catdir( $WORKSPACE_DIR, 'EGA', $output_filename );

        if ( -e $output_file_path ) {
            print "$output_file_path already exists, skipping encryption\n";
        }

        else {
            my $cmd = "gpg --always-trust -r EGA_Public_key -o $output_file_path -e $analysis_file_path";
            print "Encrypting $analysis_file_path to $output_file_path\n";
            print "Command: $cmd\n";

            my ( $stdout, $stderr );
            IPC::Run3::run3( $cmd, \undef, \$stdout, \$stderr );

            if ( $stdout or $stderr ) {

                print "Error with gpg encryption\n";
                print "stdout: $stdout\n";
                print "stderr: $stderr\n";

                unlink($output_file_path) if ( -e $output_file_path );

                next;
            }
        }

        print "Calculating MD5 checksum for $output_file_path...\n";
        my $checksum = RGTools::RGIO::get_MD5( -file => $output_file_path );
        print "$output_file_path has checksum $checksum\n";

        my $quoted_checksum = RGTools::RGIO::autoquote_string($checksum);

        my $num_update = $dbc->Table_update(
            -table     => 'Analysis_File',
            -fields    => 'Encrypted_Checksum',
            -values    => $quoted_checksum,
            -condition => "WHERE Analysis_File_ID = $analysis_file_id",
        );

        if ($num_update) {
            print "Updated $num_update record(s) in Analysis_File\n";

        }
        else {
            print "Failed to update Analysis_File\n";
        }
    }

    else {
        print "$analysis_file_path doesn't exist, can't calculate checksum\n";
    }
}

# remove lock file
unlink($lock_file);
exit;

##################
sub display_help {
##################

    print <<HELP;

Syntax
======
encrypt_submission_files.pl - This script calculates the MD5 checksum for TCGA bam files.

Arguments:
=====
-- optional arguments --
-help, -h, -?		: displays this help. (optional)
--host=s		: Database host
--dbase=s		: Database name

Example
=======
encrypt_submission_files.pl [--host lims05 --dbase sequence]

HELP

}
