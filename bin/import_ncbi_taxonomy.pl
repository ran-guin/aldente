#!/usr/local/bin/perl

use strict;
use DBI;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use Data::Dumper;
use Net::FTP;
use Getopt::Long;

use RGTools::Process_Monitor;
use RGTools::RGIO;
use SDB::CustomSettings qw(%Configs);
use SDB::HTML;
use SDB::DBIO;

##  The path and the file:
## ftp://ftp.ncbi.nih.gov/pub/taxonomy/
## taxdump.tar.gz

use vars qw($opt_help $opt_quiet $opt_host $opt_dbase $opt_user $opt_password);

&GetOptions(
    'help=s'  => \$opt_help,
    'quiet'   => \$opt_quiet,
    'host=s'  => \$opt_host,
    'dbase=s' => \$opt_dbase,
    'pass=s'  => \$opt_password,
    'user=s'  => \$opt_user,
);

my $help  = $opt_help;
my $quiet = $opt_quiet;

my $host  = $opt_host  || $Configs{DEV_HOST};
my $dbase = $opt_dbase || $Configs{DEV_DATABASE};
my $user  = $opt_user  || 'aldente_admin';
my $pwd        = $opt_password;
my $unzip_path = $Configs{URL_temp_dir} . '/taxonomy';
my $ftp;

#password should be read from file e.g. login.mysql

=begin
unless ($pwd) {
    help();
    exit;
}
=cut

my $Report = Process_Monitor->new();

my $dbc = new SDB::DBIO(
    -host    => $host,
    -dbase   => $dbase,
    -user    => $user,
    -connect => 1,
);

## import the taxonomy dump file by ftp

$ftp = ftp_open( -site => "ftp.ncbi.nih.gov", -directory => '/pub/taxonomy' );
my $file = "taxdump.tar.gz";
my $downloaded = $ftp->get($file) or die "Failed to get file $file";

$Report->set_Message("--- File Downloaded ---");

if ( -e $file ) {
    my $qualified_file = "$unzip_path/$file";
    ## Create temp directory if not already exists
    create_dir( -path => $unzip_path, -mode => 775 );

    ## Remove temp files in case there exist any temp files from last failed run
    try_system_command( -command => "rm -f $unzip_path/*", -verbose => 1, -report => $Report );

    try_system_command( -command => "mv $file $unzip_path", -report => $Report );

    ## gunzip it
    ## Include -f option; without it the command hangs if the corresponding tar file
    ## still exists
    try_system_command( -command => "gunzip -f $qualified_file", -verbose => 1, -report => $Report );

    ## uncompress
    $qualified_file = "$unzip_path/taxdump.tar";
    try_system_command( -command => "cd $unzip_path;  tar -xvf $qualified_file; cd  $FindBin::RealBin ", -verbose => 1, -report => $Report );

}
else {
    $Report->set_Error("Failed to find file $file");
}
$Report->set_Message("--- Unzip Done ---");

my %table_map;
$table_map{'Genetic_Code'}      = "gencode.dmp";
$table_map{'Taxonomy_Name'}     = "names.dmp";
$table_map{'Taxonomy_Node'}     = "nodes.dmp";
$table_map{'Taxonomy_Division'} = "division.dmp";

## import the list of tables into the dev database
$dbc->start_trans('Reimport_ncbi_tables');

foreach my $table ( keys %table_map ) {
    ## drop and recreate the table
    my $cmd = "TRUNCATE TABLE $table";
    $Report->set_Detail("*** CMD $cmd\n");

    my ( $arg1, $arg2, $arg3 ) = $dbc->execute_command( -command => $cmd );
    ## import the data file
    my $data_file = $unzip_path . '/' . $table_map{$table};
    my $load_cmd  = "LOAD DATA LOCAL INFILE '$data_file' INTO TABLE $table FIELDS TERMINATED BY '|' ENCLOSED BY '\t';";
    $Report->set_Detail("*** CMD $load_cmd\n");
    my ( $arg1, $arg2, $arg3 ) = $dbc->execute_command( -command => $load_cmd );

}
$dbc->finish_trans( 'Reimport_ncbi_tables', -error => $@ );
$Report->set_Message("--- Upload Done ---");

## add any new records to the taxonomy table
my %taxonomy_data = $dbc->Table_retrieve( 'Taxonomy_Name LEFT JOIN Taxonomy ON Taxonomy_ID = FK_Taxonomy__ID', [ 'FK_Taxonomy__ID', 'NCBI_Taxonomy_Name', 'Taxonomy_Name_Class' ], "WHERE Taxonomy_ID is NULL " );

my %taxonomy_insert;
my $index = 0;
while ( defined $taxonomy_data{FK_Taxonomy__ID}[$index] ) {
    my $taxonomy_id    = $taxonomy_data{FK_Taxonomy__ID}[$index];
    my $taxonomy_class = $taxonomy_data{Taxonomy_Name_Class}[$index];
    my $taxonomy_name  = $taxonomy_data{NCBI_Taxonomy_Name}[$index];
    if ( $taxonomy_class eq 'scientific name' || $taxonomy_class =~ /common name/i ) {
        $taxonomy_insert{$taxonomy_id}{$taxonomy_class} = $taxonomy_name;
    }
    $index++;
    if ( $index > 20000 ) {
        Message("Adding the first 20000 records into Taxonomy");
        last;
    }
}

my %insert_data;
my $i = 1;

foreach my $tax_id ( keys %taxonomy_insert ) {
    my $tax_name    = $taxonomy_insert{$tax_id}{'scientific name'};
    my $common_name = $taxonomy_insert{$tax_id}{'common name'};

    ## The autoquoting behaviour doesn't work correctly on a tax_name
    ## like  'Azulnota' sp. 'punctana', so I explicitly add the quotes

    $tax_name =~ s/'/\\\'/g;
    $tax_name =~ s/^/'/;
    $tax_name =~ s/$/'/;

    $insert_data{$i} = [ $tax_id, $tax_name, $common_name ];

    $i++;
}
if ( defined %insert_data ) {
    my @fields = ( 'Taxonomy_ID', 'Taxonomy_Name', 'Common_Name' );
    $Report->set_Detail("Entering Data now");
    $dbc->smart_append( -tables => "Taxonomy", -fields => \@fields, -values => \%insert_data, -autoquote => 1, -debug => 1 );
}

####  Remove Temp Files in the Temp Directory
try_system_command( -command => "rm -f $unzip_path/*", -verbose => 1, -report => $Report );

$Report->completed();
$Report->succeeded();
$Report->DESTROY();

exit;

#############
sub ftp_open {
#############
    my %args = filter_input( \@_, -args => 'site', -mandatory => 'site' );
    my $site         = $args{-site}      || '';
    my $ftp_user     = $args{-user}      || 'anonymous';
    my $ftp_password = $args{-password}  || '';
    my $directory    = $args{-directory} || '';

    my $connected = 0;
    my $try       = 0;
    my $max       = 5;
    $Report->set_Detail("Trying to connect to $site  (will try $max times before aborting)\n");

    while ( $try < $max ) {
        $try++;
        $Report->set_Detail("$try..");
        sleep 3 if $try;

        $ftp->quit if $ftp;
        $ftp = Net::FTP->new( $site, Debug => 1 ) or next;

        $ftp->login( $ftp_user, $ftp_password ) or next;
        $ftp->binary();

        $ftp->cwd($directory) if $directory;
        $connected++;
        last;
    }
    unless ($connected) {
        $Report->set_Error("No connection enabled..\n\nAborting\n\n");
        $ftp->quit;
        return 0;
    }
    $Report->set_Detail("Connection established.\n\n");
    return $ftp;
}

#############
sub help {
#############

    print <<HELP;

Usage:
*********
    import_ncbi_taxonomy.pl -host lims05 -dbase sequence -user super_cron

Mandatory Input:
**************************

Options:
**************************     


Examples:
***********

HELP

}
