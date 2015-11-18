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
use SRA::ArchiveIO;

use vars qw(%Configs $opt_help $opt_archive $opt_host $opt_dbase $opt_tx_host);

&GetOptions(
    'help|h|?'  => \$opt_help,
    'archive=s' => \$opt_archive,
    'host|h=s'  => \$opt_host,
    'dbase|d=s' => \$opt_dbase,
    'tx_host=s' => \$opt_tx_host,
);

my $help     = $opt_help;
my @archives = Cast_List( -to => 'array', -list => $opt_archive );
my $host     = $opt_host || 'lims05';
my $dbase    = $opt_dbase || 'sequence';
my $tx_host  = $opt_tx_host || 'gtorrent03';

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

### Don't try to calculate md5 of files when they still are being created
### (Relevant for tar bundles and EGA encryption)

my $MODIFY_TIME_DELAY_SEC = 60;
my $lock_file = File::Spec->catfile( $WORKSPACE_DIR, ".calculate_bam_checksum.lock" );

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

my $Data_Submission = new SRA::Data_Submission( -dbc => $dbc );

###
### Analysis_Files where checksum hasn't been calculated yet
###

my $Analysis_data = $Data_Submission->get_Analysis_Submission_data(
    -fields    => [ 'Analysis_File.Analysis_File_ID', 'Analysis_File.Analysis_File_Path', 'Organization.Organization_Name'],
    -condition => "WHERE Analysis_File.Checksum is null",
    -group_by  => "Analysis_File.Analysis_File_ID",
);

my $num_items = scalar( @{ $Analysis_data->{'Analysis_File.Analysis_File_ID'} } );

foreach my $i ( 0 .. $num_items - 1 ) {
    my $analysis_file_id   = $Analysis_data->{'Analysis_File.Analysis_File_ID'}->[$i];
    my $analysis_file_path = $Analysis_data->{'Analysis_File.Analysis_File_Path'}->[$i];

    if ( -e $analysis_file_path ) {

        print "Calculating MD5 checksum for $analysis_file_path...\n";

        #my $checksum = RGTools::RGIO::get_MD5( -file => $analysis_file_path );

        my $checksum = SRA::ArchiveIO::md5_remote( -file => $analysis_file_path, -host => $tx_host );
        print "$analysis_file_path has checksum $checksum\n";

        my $quoted_checksum = RGTools::RGIO::autoquote_string($checksum);

        my $num_update = $dbc->Table_update(
            -table     => 'Analysis_File',
            -fields    => 'Checksum',
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

###
### Calcuting checksums for bundled items
###

if ( !@archives ) {
    @archives = qw/cgHub EDACC EGA GEO SRA/;
}

foreach my $archive (@archives) {

    my $archive_workspace_dir = File::Spec->catdir( $WORKSPACE_DIR, $archive );
    my $checksum_file_rule = File::Find::Rule->new->file->name('*.md5');

    my @checksum_files = $checksum_file_rule->in($archive_workspace_dir);

    my @files = File::Find::Rule->file->not( File::Find::Rule->new->symlink )->not($checksum_file_rule)->in($archive_workspace_dir);

    my @files_with_checksum = List::MoreUtils::apply {s/\.md5$//} @checksum_files;

    my ( $files_completed, $files_awaiting_checksum, $deleted_files ) = RGmath::intersection( \@files, \@files_with_checksum );

    foreach my $file ( @{$files_awaiting_checksum} ) {
        my @stat_vals         = stat($file);
        my $file_mtime        = $stat_vals[9];
        my $time_since_modify = time() - $file_mtime;

        if ( $time_since_modify > $MODIFY_TIME_DELAY_SEC ) {

            print "Calculating MD5 checksum for $file...\n";
            my $checksum = RGTools::RGIO::get_MD5( -file => $file );
            print "$file has checksum $checksum\n";

            my $filename = File::Basename::fileparse($file);

            my $ok = RGTools::RGIO::create_file(
                -name    => $filename . ".md5",
                -content => $checksum,
                -path    => $archive_workspace_dir,
                -chgrp   => 'lims',
                -chmod   => 'g+w',
            );
        }
    }

    foreach my $file ( @{$deleted_files} ) {
        my $checksum_file = $file . ".md5";
        print "Deleting checksum file $checksum_file\n";
        unlink($checksum_file);
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
calculate_bam_checksum.pl - This script calculates the MD5 checksum for TCGA bam files.

Arguments:
=====
-- optional arguments --
-help, -h, -?		: displays this help. (optional)
--archive		: Archive for which the pending submission checksums are calculated (Corresponds to folder in "data_submission_workspace_dir" directory) 
--host=s		: Database host
--dbase=s		: Database name

Example
=======
calculate_bam_checksum.pl --archive cgHub

HELP

}
