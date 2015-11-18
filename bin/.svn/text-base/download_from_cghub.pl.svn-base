#!/usr/local/bin/perl-5.18.2/bin/perl

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
use lib $FindBin::RealBin . "/../custom/GSC/modules";

use RGTools::RGIO;
use RGTools::RGmath;

use SDB::DBIO;

use SRA::ArchiveIO;

use File::Basename;
use File::Spec;
use File::Path;
use File::Find::Rule;
use LWP::UserAgent;
use XML::Simple;
use Cwd;

my @CGHUB_DATA_PATHS = ( '/projects/tcga_dart', '/projects/tcga_dart1', '/projects/tcga_dart2', '/projects/tcga_dart3', '/projects/tcga_dart4' );

our ( $opt_help, $opt_group_by, $opt_path, $opt_tx_host );

### cgquery arguments
our (
    $opt_analysis_id,      $opt_state,            $opt_last_modified, $opt_analysis_accession, $opt_study,    $opt_disease_abbr,        $opt_participant_id, $opt_sample_id,
    $opt_analyte_code,     $opt_sample_type,      $opt_tss_id,        $opt_alias,              $opt_title,    $opt_analysis_type,       $opt_filename,       $opt_aliquot_id,
    $opt_sample_accession, $opt_library_strategy, $opt_platform,      $opt_xml_text,           $opt_filesize, $opt_refassem_short_name, $opt_center_name,    $opt_legacy_sample_id
);

### Custom cgquery arguments
our ( $opt_patient_barcode, $opt_diseased, $opt_normal );

&GetOptions(
    'help|h|?'   => \$opt_help,
    'group_by=s' => \$opt_group_by,
    'path=s'     => \$opt_path,
    'tx_host=s'     => \$opt_tx_host,

    'analysis_id=s'         => \$opt_analysis_id,
    'state=s'               => \$opt_state,
    'last_modified=s'       => \$opt_last_modified,
    'analysis_accession=s'  => \$opt_analysis_accession,
    'study=s'               => \$opt_study,
    'disease_abbr=s'        => \$opt_disease_abbr,
    'participant_id=s'      => \$opt_participant_id,
    'sample_id=s'           => \$opt_sample_id,
    'analyte_code=s'        => \$opt_analyte_code,
    'sample_type=s'         => \$opt_sample_type,
    'tss_id=s'              => \$opt_tss_id,
    'alias=s'               => \$opt_alias,
    'title=s'               => \$opt_title,
    'analysis_type=s'       => \$opt_analysis_type,
    'filename=s'            => \$opt_filename,
    'aliquot_id=s'          => \$opt_aliquot_id,
    'sample_accession=s'    => \$opt_sample_accession,
    'library_strategy=s'    => \$opt_library_strategy,
    'platform=s'            => \$opt_platform,
    'xml_text=s'            => \$opt_xml_text,
    'filesize=s'            => \$opt_filesize,
    'refassem_short_name=s' => \$opt_refassem_short_name,
    'center_name=s'         => \$opt_center_name,
    'legacy_sample_id=s'    => \$opt_legacy_sample_id,

    'patient_barcode=s' => \$opt_patient_barcode,
    'diseased'          => \$opt_diseased,
    'normal'            => \$opt_normal,

);

my $help = $opt_help;
if ($help) {
    &display_help();
    exit;
}


chomp( my $pwd = `pwd` );
my $path = $opt_path || $pwd;
my $tx_host = $opt_tx_host || "gtorrent01";
my @group_by = Cast_List( -list => $opt_group_by, -to => 'array' );

my %cgHub_args;

$cgHub_args{-analysis_id}        = $opt_analysis_id;
$cgHub_args{-state}              = $opt_state || "live";
$cgHub_args{-last_modified}      = $opt_last_modified;
$cgHub_args{-analysis_accession} = $opt_analysis_accession;
$cgHub_args{ -study } = $opt_study || "phs000178";
$cgHub_args{-disease_abbr}        = $opt_disease_abbr;
$cgHub_args{-participant_id}      = $opt_participant_id;
$cgHub_args{-sample_id}           = $opt_sample_id;
$cgHub_args{-analyte_code}        = $opt_analyte_code;
$cgHub_args{-sample_type}         = $opt_sample_type;
$cgHub_args{-tss_id}              = $opt_tss_id;
$cgHub_args{-alias}               = $opt_alias;
$cgHub_args{-title}               = $opt_title;
$cgHub_args{-analysis_type}       = $opt_analysis_type;
$cgHub_args{-filename}            = $opt_filename;
$cgHub_args{-aliquot_id}          = $opt_aliquot_id;
$cgHub_args{-sample_accession}    = $opt_sample_accession;
$cgHub_args{-library_strategy}    = $opt_library_strategy;
$cgHub_args{-platform}            = $opt_platform;
$cgHub_args{-xml_text}            = $opt_xml_text;
$cgHub_args{-filesize}            = $opt_filesize;
$cgHub_args{-refassem_short_name} = $opt_refassem_short_name;
$cgHub_args{-center_name}         = $opt_center_name || "!BCCAGSC";
$cgHub_args{-legacy_sample_id}    = $opt_legacy_sample_id;

my $patient_barcode = $opt_patient_barcode;
my $diseased        = $opt_diseased;
my $normal          = $opt_normal;

if ($patient_barcode) {
    my @patient_barcodes = Cast_List( -list => $patient_barcode, -to => 'array' );
    my @participant_ids = Cast_List( -list => $cgHub_args{-participant_id}, -to => 'array' );

    if ( scalar(@patient_barcodes) > 0 ) {
        my @converted_participant_ids = SRA::ArchiveIO::TCGA_barcode_uuid_conversion( -barcode => \@patient_barcodes );
        push @participant_ids, @converted_participant_ids;
    }

    $cgHub_args{-participant_id} = Cast_List( -list => \@participant_ids, -to => 'string' );
}

if ($diseased) {
    my @sample_types = Cast_List( -list => $cgHub_args{-sample_type}, -to => 'array' );
    push @sample_types, "0*";
    $cgHub_args{-sample_type} = Cast_List( -list => \@sample_types, -to => 'string' );
}

if ($normal) {
    my @sample_types = Cast_List( -list => $cgHub_args{-sample_type}, -to => 'array' );
    push @sample_types, "1*";
    $cgHub_args{-sample_type} = Cast_List( -list => \@sample_types, -to => 'string' );
}

my $ua = LWP::UserAgent->new;
$ua->timeout(30);

### Only retrieving short cgquery summary
### This is because once the total number of items gets past the hundreds
### the script slows to a crawl

my $cgHub_summary_XML = SRA::ArchiveIO::download_cgHub_metadata( %cgHub_args, -summary => 1, -debug => 1 );

print "Finished query\n";

my $cgHub_summary_hash = XMLin( $cgHub_summary_XML, ForceArray => [ 'Result', 'EXPERIMENT', 'ANALYSIS', 'RUN' ] );

my %results = %{ $cgHub_summary_hash->{Result} } if ( $cgHub_summary_hash->{Result} );

print "Loaded summary results\n";

my @sorted_nums = sort { $a <=> $b } keys %results;
print scalar(@sorted_nums) . " hits found\n";

foreach my $num (@sorted_nums) {

    my $bam_summary_hash = $results{$num};
    ### Get the full cgHub metadata dump for this bam file and dump to a file
    ### for future reference

    my $analysis_id = $bam_summary_hash->{analysis_id};
    print "\nHit #$num Analysis $analysis_id\n";
    print "-" x 45, "\n";

    my $bam_detailed_XML = SRA::ArchiveIO::download_cgHub_metadata( -analysis_id => $analysis_id );

    my $bam_detailed_hash = XMLin( $bam_detailed_XML, ForceArray => [ 'Result', 'EXPERIMENT', 'ANALYSIS', 'RUN', 'file' ] );

    $bam_detailed_hash = $bam_detailed_hash->{Result}->{1};
    ### Now add the appropriate grouping folder for this sample

    my $subdirectory;

    foreach my $group_param (@group_by) {

        my $new_dir_name;

        if ( $group_param eq 'patient_barcode' ) {
            my ($barcode) = SRA::ArchiveIO::TCGA_barcode_uuid_conversion( -uuid => $bam_detailed_hash->{participant_id} );
            $new_dir_name = $barcode;
        }
        else {
            $new_dir_name = $bam_detailed_hash->{$group_param};
        }

        $subdirectory = File::Spec->catdir( $subdirectory, $new_dir_name );
    }

    my $download_path;

    my $abs_path = Cwd::abs_path( $path ) ;
    my @path_order_to_check = grep { $_ ne $abs_path } @CGHUB_DATA_PATHS;
    push @path_order_to_check, $abs_path;

    foreach my $path_to_check (@path_order_to_check) {

        my $download_path_to_check = File::Spec->catdir( $path_to_check, $subdirectory, $analysis_id );

        if ( -d $download_path_to_check ) {
	    ### If $download_path is already set, that means you found a duplicate
	    ### version of the uuid directory
	    ### 
	    ### In this case, delete the copy

            if ($download_path) {

		print "Found copy of $analysis_id in $download_path_to_check\n";

		my $parent_dir = File::Basename::dirname($download_path_to_check);
		my @associated_files = File::Find::Rule->name("*$analysis_id*")->in($parent_dir);
		foreach my $file (@associated_files) {
			print "Deleting $file\n";

			if (-d $file) {
# 				File::Path::remove_tree($file, {verbose => 1, safe => 1});
				File::Path::remove_tree($file, {verbose => 1});

			}
			else {
				unlink($file);
			}
		}
            }

	    else {
               $download_path = RGTools::RGIO::create_dir(
                   -path         => $path_to_check,
                   -subdirectory => $subdirectory,
                   -mode         => 775
               );
	    }
        }
    }

    if ( !$download_path ) {
        $download_path = RGTools::RGIO::create_dir(
            -path         => $path,
            -subdirectory => $subdirectory,
            -mode         => 775
        );
    }

    print "Download path: $download_path\n";

    my $metadata_filename = File::Spec->catfile( $download_path, "metadata.${analysis_id}.xml" );

    if ( -e $metadata_filename ) {
        print "XML metadata $metadata_filename already downloaded\n";
    }
    else {
        open( my $DOWNLOAD_XML, ">", $metadata_filename );
        binmode( $DOWNLOAD_XML, ":utf8" );

        print $DOWNLOAD_XML $bam_detailed_XML;
        print "Downloaded XML metadata to $metadata_filename\n";
    }

    my @file_array = Cast_List( -list => $bam_detailed_hash->{files}->{file}, -to => 'array' );

    foreach my $file_hash (@file_array) {
        my $filename = $file_hash->{filename};
        my $file_path = File::Spec->catfile( $download_path, $analysis_id, $filename );

        if ( -e $file_path ) {
            print "File $file_path already downloaded\n";
        }
        elsif ($filename !~ /bai$/) {
            my $success = SRA::ArchiveIO::download_cgHub_file( -analysis_id => $analysis_id, -host => $tx_host, -path => $download_path );
        }
    }

}

print "Finished download batch\n";

##################
sub display_help {
##################
    print <<HELP;

Syntax
======
download_from_cghub.pl - This script automates download of TCGA bam files from cgHub.

Arguments:
=====
-- optional arguments --
--help, -h, -?		: Displays this help.
--path			: Download path
--tx_host			: Transfer host used to run GeneTorrent

-- cgquery arguments --

--analysis_id
--state (default: live)
--last_modified
--analysis_accession
--study (default: phs000178 [Study name of TCGA inherited from NCBI])
--disease_abbr
--participant_id
--sample_id
--analyte_code
--sample_type
--tss_id
--alias
--title
--filename
--aliquot_id
--sample_accession
--library_strategy
--platform
--xml_text
--filesize
--refassem_short_name
--center_name (default: !BCCAGSC)
--legacy_sample_id

-- Custom cgquery arguments --

--patient_barcode	: Patient identifier as used in TCGA barcode (ex. TCGA-AA-3966)
--diseased		: Retrieves all samples that are marked as diseased in the barcode
			  (ex. TCGA-AA-3966-01A-01D-1109-02: 01 indicates sample type, leading zero indicates diseased)
--normal			: Retrieves all samples that are marked as normal in the barcode
			  (ex. TCGA-AA-3966-10A-01D-1109-02: 10 indicates sample type, leading one indicates normal)

--group_by		: Sorts bams into folders indicated by input to this flag.
			  Valid input choices: [all cgquery arguments + patient_barcode]
			  Example:
				Input: --group_by disease_abbr,patient_barcode
				Output: file destination is \$path/BLCA/TCGA-01-1111


Example
=======
download_from_cghub.pl --group_by disease_abbr,patient_barcode --library_strategy WXS --path /projects/tcga_dart --disease_abbr BLCA


HELP

}
