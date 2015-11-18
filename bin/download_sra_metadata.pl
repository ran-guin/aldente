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
use RGTools::RGmath;
use SDB::CustomSettings;
use SDB::DBIO;
use LWP::UserAgent;
use Date::Calc;
use File::Listing;

use vars qw(%Configs $opt_help $opt_path $opt_ftp_url $opt_ftp_dir $opt_ftp_user);

&GetOptions(
    'help|h|?'   => \$opt_help,
    'ftp_url=s'  => \$opt_ftp_url,
    'ftp_user=s' => \$opt_ftp_user,
    'ftp_dir=s'  => \$opt_ftp_dir,
    'path=s'     => \$opt_path,
);

my $help     = $opt_help;
my $path     = $opt_path || "./";
my $FTP_URL  = $opt_ftp_url || "ftp-trace.ncbi.nlm.nih.gov";
my $FTP_dir  = $opt_ftp_dir || "sra/reports/Metadata";
my $FTP_user = $opt_ftp_user || "anonftp";

if ($help) {
    &display_help();
    exit;
}

my $ascp_path   = "/home/aldente/private/software/Aspera_Connect/current/bin/ascp";
my $private_key = "/home/aldente/private/software/Aspera_Connect/current/etc/asperaweb_id_dsa.putty";

my $ua = LWP::UserAgent->new;
$ua->timeout(30);

my $response = $ua->get("ftp://$FTP_URL/$FTP_dir");
my $query_output;
if ( $response->is_success ) {
    $query_output = $response->decoded_content;
}
else {
    print "Can't access SRA FTP directories, quitting...\n";
    die $response->status_line;

}

my @local_copy_date;

if ( open( DATE_FILE, "$path/.last_update" ) ) {

    my @date_lines = <DATE_FILE>;

    chomp( my $local_version = $date_lines[0] );
    $local_version =~ /Version:\s*(\d+)-(\d+)-(\d+)\s*/;

    @local_copy_date = ( $1, $2, $3 );
}
else {

    # Couldn't read version file, so local version date is unknown:
    # Since full XML dumps occur on (or near) the beginning of the month,
    # reset version date to 1st of the month to make sure a full dump
    # is included
    @local_copy_date = Date::Calc::Today();
    $local_copy_date[2] = 1;
}

my @xml_dumps;
my $full_xml_dump;

####
#### Using parse_dir in File::Listing
####
foreach my $listing_ref ( @{ parse_dir($query_output) } ) {
    my ( $filename, $filetype, $filesize, $filetime, $filemode ) = @$listing_ref;
    my @xml_dump_date = Date::Calc::Localtime($filetime);

    splice( @xml_dump_date, 3 );    ### Remove time component, leave only date of dump

    my $date_diff = Date::Calc::Delta_Days( @local_copy_date, @xml_dump_date );

    if ( $date_diff > 0 ) {

        if ( $filename =~ /Metadata_Full/ ) {

            ##### Always get the newest full dump if needed
            if ( $filename gt $full_xml_dump ) {
                $full_xml_dump = $filename;
            }
        }
        elsif ( $filename =~ /Metadata/ ) {
            push @xml_dumps, $filename;
        }
    }
}

if ($full_xml_dump) {

    #### Delete any normal dumps that precede or were released at the same time as the full dump
    $full_xml_dump =~ s/(NCBI_SRA_Metadata)(_Full)(_\d+\.tar\.gz)/\1\3/;
    @xml_dumps = grep { $_ gt $full_xml_dump } @xml_dumps;
    @xml_dumps = sort(@xml_dumps);

    unshift( @xml_dumps, $full_xml_dump );
}

foreach my $dump_file (@xml_dumps) {

    my $cmd = "$ascp_path -i $private_key -QT -l100M $FTP_user" . '@' . "${FTP_URL}:/$FTP_dir/$dump_file $path\n";

    print "Downloading $FTP_user" . '@' . "${FTP_URL}:/$FTP_dir/$dump_file to $path using $ascp_path...\n";

    ####################################
    # CONSTRUCTION: This block should use try_system_command, however the option that returns
    # stdout and stderr separately, i.e.
    # my ($output,$errors) = try_system_command(....)
    # produces this error:
    # sh: -c: line 1: syntax error near unexpected token `|'
    # sh: -c: line 1: ` | sed 's/^/STDOUT:/' 2>&1'
    # This is a temporary fix until that function works correctly
    ####################################
    $dump_file =~ /(\w+)\.tar\.gz/;
    my $error_file = "$path/$1.download.err.txt";

    my $output = `$cmd 2> $error_file`;
    print $output;
    if ( -s $error_file ) {
        print "ERROR: Download of $dump_file to $path failed\n";
        print "Check $path/$1.download.err.txt for download log\n";
        exit;
    }
    else {
        `rm $path/$1.download.err.txt`;
    }
    ####################################
    $cmd = "tar --overwrite --strip-components 1 -C $path -xzf $path/$dump_file\n";

    print "Unpacking $path/$dump_file...\n";

    ####################################
    # CONSTRUCTION: This block should use try_system_command, however the option that returns
    # stdout and stderr separately, i.e.
    # my ($output,$errors) = try_system_command(....)
    # produces this error:
    # sh: -c: line 1: syntax error near unexpected token `|'
    # sh: -c: line 1: ` | sed 's/^/STDOUT:/' 2>&1'
    # This is a temporary fix until that function works correctly
    ####################################
    $dump_file =~ /(\w+)\.tar\.gz/;
    my $error_file = "$path/$1.untar.err.txt";

    $output = `$cmd 2> $error_file`;
    print $output;
    if ( -s $error_file ) {
        print "ERROR: Unpacking of $dump_file failed\n";
        print "Check $path/$1.untar.err.txt for download log\n";
        exit;
    }
    else {
        `rm $path/$1.untar.err.txt`;
    }

}

# Only update .last_update versioning info if new XML was added

if ( scalar(@xml_dumps) > 0 ) {

    my $last_update_str;

    my $latest_dump_filename = $xml_dumps[-1];
    $latest_dump_filename =~ /NCBI_SRA_Metadata_(\d{4})(\d{2})(\d{2})\.tar\.gz/;
    my $version_date_str = "$1-$2-$3";
    $last_update_str .= "Version: $1-$2-$3\n";

    my @curr_date = Date::Calc::Today();
    my $curr_date_str = sprintf( "%d-%02d-%02d", @curr_date );    ### ISO 8601 format
    $last_update_str .= "Updated on: $curr_date_str\n";

    my $status_file_ok = RGTools::RGIO::create_file( -name => ".last_update", -content => $last_update_str, -path => $path, -chgrp => 'lims', -chmod => 'a+w', -overwrite => 1 );

    if ($status_file_ok) {
        print "Successfully updated to version $version_date_str on $curr_date_str\n";
        `rm $path/*.tar.gz`;
    }
    else {
        print "ERROR: Updating version info failed";
    }
}

##################
sub display_help {
##################
    print <<HELP;

download_sra_metadata.pl - This script downloads the latest metadata for SRA submissions

Arguments:
=====
-- optional arguments --
-help, -h, -?	: displays this help. (optional)
--ftp_url=s	: URL of FTP server containing SRA metadata
--ftp_user=s	: user name to access SRA metadata server (public) 
--ftp_dir=s	: directory where XML dumps are located on FTP server
--path=s	: local path to extract metadata structure

Example
=======
./download_sra_metadata.pl --path /projects/sbs_pipeline02/Metadata


HELP

}
