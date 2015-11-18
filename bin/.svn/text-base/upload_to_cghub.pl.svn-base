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
use File::Basename;
use LWP::UserAgent;
use XML::Simple;
use SRA::Data_Submission;
use SRA::ArchiveIO;

our ( $opt_help, $opt_force, $opt_volume_name, $opt_volume_id, $opt_check, $opt_host, $opt_path, $opt_dbase, $opt_tx_host );

&GetOptions(
    'help|h|?'      => \$opt_help,
    'force|f'       => \$opt_force,
    'volume_name=s' => \$opt_volume_name,
    'volume_id=s'   => \$opt_volume_id,
    'check|c'       => \$opt_check,
    'host=s'        => \$opt_host,
    'dbase=s'       => \$opt_dbase,
    'path=s'        => \$opt_path,
    'tx_host=s'     => \$opt_tx_host,
);

my $help        = $opt_help;
my $volume_name = $opt_volume_name;
my $volume_id   = $opt_volume_id;
my $force       = $opt_force;
my $check       = $opt_check;
my $tx_host     = $opt_tx_host || "gtorrent01";
my $path        = $opt_path;
my $host        = $opt_host || 'lims05';
my $dbase       = $opt_dbase || 'sequence';

if ($help) {
    &display_help();
    exit;
}

my $login_name = 'aldente_admin';
my $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $login_name, -connect => 1 );

my $Submission_Volume = SRA::Data_Submission->new( -dbc => $dbc );
$path = File::Spec->catdir( $Submission_Volume->{submission_dir}, 'cgHub' ) if !$path;

if ($volume_id) {
    $Submission_Volume->set_pk_value( -value => $volume_id );
}
elsif ($volume_name) {
    $Submission_Volume->set_field_value( -values => { Volume_Name => $volume_name } );
}
else {
    print "Error: Need to supply submission volume ID or name\n";
    return;
}

my $DB_data = $Submission_Volume->get_Volume_metadata_objects(
    -fields        => [ 'Metadata_Object.Metadata_Object_ID', 'Metadata_Object.Unique_Identifier' ],
    -metadata_type => 'Analysis',
    -status   => [ 'Created', 'Requested', 'Approved by Admin' ],
    -distinct => 1,
);

my @MO_ids_to_submit       = Cast_List( -to => 'array', -list => $DB_data->{'Metadata_Object.Metadata_Object_ID'} );
my @analysis_ids_to_submit = Cast_List( -to => 'array', -list => $DB_data->{'Metadata_Object.Unique_Identifier'} );

if ( scalar(@MO_ids_to_submit) > 0 and scalar(@analysis_ids_to_submit) > 0 ) {

    my $iterator = List::MoreUtils::each_array( @MO_ids_to_submit, @analysis_ids_to_submit );

    while ( my ( $MO_id, $analysis_id ) = $iterator->() ) {

        my $analysis_XML = SRA::ArchiveIO::download_cgHub_metadata( -analysis_id => $analysis_id );
        my $analysis_metadata = XMLin( $analysis_XML, ForceArray => [ 'EXPERIMENT', 'ANALYSIS', 'RUN', 'file' ] );
        my $analysis_dir = File::Spec->catdir( $path, $analysis_id );

        if ( $analysis_metadata->{Hits} == 0 ) {
            print "No analysis entry found for $analysis_id\n";

            if ($check) {
                next;
            }

            my ( $validate_code, $error ) = SRA::ArchiveIO::validate_cgHub_metadata( -path => $analysis_dir );

            if ( $validate_code == -1 ) {
                print "ERROR: Connection problems\n";
                print $error;
            }

            elsif ( $validate_code == 1 ) {
                print "Validation succeeded\n";
                my ( $submit_code, $error ) = SRA::ArchiveIO::submit_cgHub_metadata( -path => $analysis_dir );

                if ( $submit_code == 1 ) {
                    print "Metadata submission succeeded\n";
                    my $upload_code = SRA::ArchiveIO::upload_cgHub_file( -path => $analysis_dir, -host => $tx_host );
                    print "Return code: $upload_code\n";
                }
                elsif ( $submit_code == 0 ) {
                    print "ERROR: Metadata submission failed\n";
                    print "$error\n";
                }
            }

            elsif ( $validate_code == 0 ) {
                my $cgHub_error = XMLin( $error, ForceArray => ['error'] );

                print "ERROR: $cgHub_error->{usermsg}\n";
                print "Remediation: $cgHub_error->{remediation}\n";

                my @hashes_to_output;

                my $reference_errors = $cgHub_error->{submission_set}->{references};
                my $file_errors      = $cgHub_error->{submission_set}->{files};

                push @hashes_to_output, $reference_errors if ( $reference_errors->{status} =~ /^ERROR$/ );
                push @hashes_to_output, $file_errors      if ( $file_errors->{status}      =~ /^ERROR$/ );

                foreach my $validation_hash (@hashes_to_output) {

                    my %validation_hash_detail = %{ $validation_hash->{details} };

                    while ( my ( $validation_item, $detail_hash ) = each(%validation_hash_detail) ) {

                        if ( $detail_hash->{status} =~ /^ERROR$/i ) {

                            my @error_list = @{ $detail_hash->{errors}->{error} };

                            foreach my $error (@error_list) {
                                print "-" x 20 . "\n";
                                if ( ref($error) eq 'SCALAR' ) {
                                    print "$error\n";
                                }
                                elsif ( ref($error) eq 'HASH' ) {
                                    my @sorted_keys = sort keys %{$error};
                                    print "$_: $error->{$_}\n" for (@sorted_keys);
                                }
                            }

                        }
                    }
                }
            }    ### end elsif ($code == 2)

            print "\n";
        }
        elsif ( $analysis_metadata->{Hits} == 1 ) {

            $analysis_metadata = $analysis_metadata->{Result};

            my $state          = $analysis_metadata->{state};
            my $analysis_alias = $analysis_metadata->{analysis_xml}->{ANALYSIS_SET}->{ANALYSIS}->[0]->{alias};

            my ( $filesize, $checksum );

            foreach my $file_hash ( @{ $analysis_metadata->{files}->{file} } ) {

                my $filename = $file_hash->{filename};
                my ( $name, $path, $ext ) = File::Basename::fileparse( $filename, qw(bam bam.bai tar) );

                if ( $ext eq 'bam' or $ext eq 'tar' ) {
                    $filesize = $file_hash->{filesize};
                    $checksum = $file_hash->{checksum}->{content};
                }
            }

            print "$analysis_alias ($analysis_id) is $state\n";

            if ( $state eq 'suppressed' or $state eq 'redacted' ) {

                my $reason = $analysis_metadata->{reason};
                print "Reason: $reason\n";
                ### Change DB status to rejected
            }
            elsif ( $force and !$check and ( ( $state eq 'submitted' ) or ( $state eq 'uploading' and $filesize == 0 ) ) ) {
                print "$analysis_alias ($analysis_id) upload interrupted, retrying\n";
                my $upload_code = SRA::ArchiveIO::upload_cgHub_file( -path => $analysis_dir, -host => $tx_host );
                print "Return code: $upload_code\n";
            }
            else {
                ## Change DB status to Uploaded
            }

            print "\n";
        }
    }
}
else {
    print "No valid items to upload\n";
}

##################
sub display_help {
##################
    print <<HELP;

upload_to_cghub.pl - This script uploads all TCGA bams associated with a LIMS submission volume.

Arguments:
=====
--volume_name=s		: LIMS Submission_Volume name
--volume_id=s		: LIMS Submission_Volume ID

-- optional arguments --
--help, -h, -?		: Displays this help. (optional)
--force, -f		: If you want to force a restart of the GeneTorrent upload for uuids with state 'uploading' 
--tx_host=s		: Sets transfer host
--path=s		: Path of uuid folders
--host=s		: Database host
--dbase=s		: Database name

Example
=======
./upload_to_cghub.pl --volume_name TCGA_1 --tx_host gtorrent02


HELP

}
