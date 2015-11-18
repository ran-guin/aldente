#!/usr/local/bin/perl

use strict;

#use warnings;

#use DBI;
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
use SRA::ArchiveIO;

use File::Basename;
use File::Path;
use LWP::UserAgent;
use XML::Simple;
use File::Find::Rule;
use UUID::Tiny ':std';
use Sys::Hostname;
use IPC::Run3;
use Benchmark;

our ( $opt_help, $opt_tx_host, $opt_archive, $opt_path, $opt_disease_abbr );

&GetOptions(
    'help|h|?'       => \$opt_help,
    'tx_host=s'      => \$opt_tx_host,
    'path=s'         => \$opt_path,
    'disease_abbr=s' => \$opt_disease_abbr,
);

my $help = $opt_help;
my $path = $opt_path || "/projects/tcga_dart";

my $tx_host = $opt_tx_host || "gtorrent01";
my @disease_abbrs = Cast_List( -list => $opt_disease_abbr, -to => 'array' );

if ($help) {
    &display_help();
    exit;
}

$| = 1;    ### Autoflush

### You don't want to calculate a file's md5 while it could still
### be downloading, so check to make sure it's been on the file system
### for at least these many seconds without changes:

my $MODIFY_TIME_DELAY_SEC = 300;

### The TCGA structure assumes that metadata files are located
### in the subdirectory $path/<disease_code>/<patient_ID>
### (ex. /projects/tcga_dart/STAD/TCGA-BR-4188)

if ( scalar(@disease_abbrs) == 0 ) {

    my $disease_list_XML = SRA::ArchiveIO::download_TCGA_DCCWS_metadata( -object => "Disease", );

    my $disease_list_hash = XMLin( $disease_list_XML, KeyAttr => { class => "recordNumber", field => "name" } );

    my $disease_records = $disease_list_hash->{queryResponse}->{class};

    foreach my $recordNumber ( sort keys %{$disease_records} ) {
        my $record = $disease_records->{$recordNumber};
        push @disease_abbrs, $record->{field}->{abbreviation}->{content};
    }
}

foreach my $disease_code (@disease_abbrs) {
    my $disease_dir = File::Spec->catdir( $path, $disease_code );
    print "Processing disease $disease_code\n\n";

    my @patient_dirs = File::Find::Rule->directory->maxdepth(1)->name(qr/^TCGA-\w\w-\w\w\w\w/)->in($disease_dir);
    foreach my $patient_dir (@patient_dirs) {
        print "Processing patient directory $patient_dir\n";
        print "-" x 66, "\n";
        my @analysis_dirs = File::Find::Rule->directory->maxdepth(1)->mindepth(1)->exec( sub { UUID::Tiny::is_uuid_string($_) } )->in($patient_dir);

        if ( scalar(@analysis_dirs) == 0 ) {
            print "No data is being stored for patient $patient_dir, delete directory\n";
            File::Path::remove_tree( $patient_dir, { verbose => 1 } );
            next;
        }

        foreach my $analysis_dir (@analysis_dirs) {

            my ( $analysis_id, $parent_dir ) = File::Basename::fileparse($analysis_dir);

            my $metadata_file = File::Spec->catfile( $patient_dir, "metadata.${analysis_id}.xml" );

            print "Downloading metadata for $analysis_id\n";

            my $success = SRA::ArchiveIO::download_cgHub_metadata( -analysis_id => $analysis_id, -file => $metadata_file );
            next if ( !$success );

            print "Loading XML from $metadata_file\n";
            my $analysis_metadata = XMLin( $metadata_file, ForceArray => [ 'Result', 'EXPERIMENT', 'ANALYSIS', 'RUN', 'file' ] );
            $analysis_metadata = $analysis_metadata->{Result}->{1};

            my $state = $analysis_metadata->{state};

            if ( $state eq 'live' ) {

                my @file_array = Cast_List( -to => 'array', -list => $analysis_metadata->{files}->{file} );

                foreach my $file_detail (@file_array) {
                    my $metadata_checksum = $file_detail->{checksum}->{content};
                    my $filename          = $file_detail->{filename};

                    my $file          = File::Spec->catfile( $analysis_dir, $filename );
                    my $checksum_file = File::Spec->catfile( $analysis_dir, ".$filename.checksum" );
                    my @symlinks = File::Find::Rule->symlink->maxdepth(1)->exec( sub { File::Spec->rel2abs( readlink($_) ) eq "$file" } )->in($patient_dir);

                    if ( !-e $file ) {
                        print "File $filename missing for $analysis_id\n";
                        next;
                    }

                    my @stat_vals         = stat($file);
                    my $file_mtime        = $stat_vals[9];
                    my $time_since_modify = time() - $file_mtime;

                    @stat_vals = stat($checksum_file);
                    my $checksum_time_diff;

                    if ( scalar(@stat_vals) > 0 ) {
                        my $checksum_mtime = $stat_vals[9];
                        $checksum_time_diff = $checksum_mtime - $file_mtime;
                    }
                    else {
                        $checksum_time_diff = 0;
                    }

                    if ( $time_since_modify > $MODIFY_TIME_DELAY_SEC ) {
                        my $local_checksum;

                        if ( -e $checksum_file and $checksum_time_diff > 0 ) {
                            open( my $CHECKSUM, $checksum_file );
                            $local_checksum = <$CHECKSUM>;
                        }
                        else {
                            $local_checksum = _create_checksum_file( -file => $file, -host => $tx_host );
                        }

                        while ( $local_checksum ne $metadata_checksum ) {

                            print "Checksum calculated for $file ($local_checksum) didn't match metadata checksum ($metadata_checksum)\n";
                            print "Deleting $file\n";
                            unlink($file);

                            print "Retrying download...\n";
                            my $status = SRA::ArchiveIO::download_cgHub_file( -analysis_id => $analysis_id, -host => $tx_host, -path => $patient_dir );

                            $local_checksum = _create_checksum_file( -file => $file, -host => $tx_host );
                        }

                        _create_symlink( -file => $file, -metadata => $analysis_metadata );

                    }    ### END if ($time_since_modify > $MODIFY_TIME_DELAY_SEC)

                }    ### END foreach my $file_detail (@file_array)

            }    ### END if ($state eq 'live')

            else {

                print "Removing access for $analysis_id: state $state\n";

                my @file_array = Cast_List( -to => 'array', -list => $analysis_metadata->{files}->{file} );

                foreach my $file_detail (@file_array) {
                    my $filename = $file_detail->{filename};
                    my $file = File::Spec->catfile( $analysis_dir, $filename );

                    my @symlinks = File::Find::Rule->symlink->maxdepth(1)->exec( sub { File::Spec->rel2abs( readlink($_) ) eq "$file" } )->in($patient_dir);

                    if ( scalar(@symlinks) > 0 ) {
                        print "Deleting symlinks:\n";
                        print join( "\n", @symlinks ) . "\n";
                    }
                    unlink(@symlinks);
                }

                print "Removing read permission on uuid folder $analysis_dir\n";
                my $mode = 0700;
                chmod $mode, $analysis_dir;

                my @related_files = File::Find::Rule->file->maxdepth(1)->name("*$analysis_id*")->in($patient_dir);

                ###
                ### Keep metadata XML file as well, just in case
                ###
                @related_files = grep { $_ !~ /\.xml$/ } @related_files;

                print "Deleting supplemental files to $analysis_id\n";

                unlink(@related_files);
            }
            print "-" x 10, "\n";
        }    ### END foreach my $analysis_dir (@analysis_dirs)

    }    ### END foreach my $patient_dir (@patient_dirs)

    print "Finished disease $disease_code\n";
}

sub _create_checksum_file {

    my %args = &filter_input( \@_ );
    my $file = $args{-file};
    my $host = $args{-host};

    my ( $filename, $file_dir ) = File::Basename::fileparse($file);
    my $checksum_file = File::Spec->catfile( $file_dir, ".$filename.checksum" );

    print "Calculating checksum for $file\n";
    my $checksum = SRA::ArchiveIO::md5_remote( -file => $file, -host => $host );
    print "Calculated MD5 $checksum for $file\n";

    open( my $CHECKSUM, ">", $checksum_file );
    print $CHECKSUM $checksum;
    close($CHECKSUM);
    print "Added checksum file $checksum_file\n";

    return $checksum;
}

sub _create_symlink {
    my %args     = &filter_input( \@_ );
    my $file     = $args{-file};
    my $metadata = $args{-metadata};

    ### Parsing metadata for symlink alias
    my $sample_type = $metadata->{sample_type};

    my $disease_status;

    if ( $sample_type =~ /^0/ ) { $disease_status = 'diseased'; }
    if ( $sample_type =~ /^1/ ) { $disease_status = 'normal'; }

    my $tcga_barcode       = $metadata->{legacy_sample_id};
    my $reference_assembly = $metadata->{refassem_short_name};

    my $library_strategy = $metadata->{library_strategy};
    my $analysis_id      = $metadata->{analysis_id};

    ### Extract file suffix from expected file types in cgHub
    my ( $name, $path, $suffix ) = File::Basename::fileparse( $file, qw(bam bam.bai tar.gz) );
    my $patient_dir = File::Basename::dirname($path);

    my $alias = $tcga_barcode . "_" . $disease_status . "_" . $reference_assembly . "_" . $library_strategy . "." . $analysis_id . "." . $suffix;

    my $link_path = File::Spec->catfile( $patient_dir, $alias );

    my $success = RGTools::RGIO::create_link(
        -link_path     => $link_path,
        -file          => $file,
        -relative_link => 1
    );

    if ( !$success ) {
        print "Creation of symlink $link_path to file $file failed\n";
    }
}

##################
sub display_help {
##################
    print <<HELP;

Syntax
======
validate_tcga_download.pl - This script compares the MD5 checksum between downloaded and archive files (TCGA-specific) and creates a systematic symlink to the files for easier searching

Arguments:
=====
-- optional arguments --

--help, -h, -?	: Displays this help.
--disease_abbr	: Disease folders to traverse (default is to traverse all diseases)
--tx_host		: Transfer host used to run GeneTorrent (for re-downloads)
--path       : Mount path where the data is stored

Example
=======
validate_tcga_download.pl --disease_abbr THCA --path /projects/tcga_dart


HELP

}
