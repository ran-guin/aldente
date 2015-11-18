#!/usr/local/bin/perl

use strict;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use SDB::DBIO;
use SDB::CustomSettings;
use Data::Dumper;
use Getopt::Long;
use RGTools::Process_Monitor;
use RGTools::RGIO;
use Storable;

use vars qw(%Configs);
use vars qw($opt_dbase $opt_host $opt_file $opt_table);
&GetOptions(
    'dbase=s' => \$opt_dbase,
    'host=s'  => \$opt_host,
    'file=s'  => \$opt_file,
    'table=s' => \$opt_table,
);
my $dbase = $opt_dbase || $Configs{DATABASE};
my $host  = $opt_host  || $Configs{SQL_HOST};
my $file  = $opt_file;
my $table = $opt_table;

my $dbc = SDB::DBIO->new( -dbase => $dbase, -host => $host, -user => 'viewer', -connect => 1 );

if ($table) {
    print Dumper $dbc->initialize_field_info( -table => $table );
    exit;
}

my $Report;
if ( !$opt_file ) {
    $Report = Process_Monitor->new();
    $Report->set_Message("Starting initializing parameters");
}

my $parameters_file = "Parameters.$host:$dbase";
$file ||= $Configs{URL_cache} . '/' . $parameters_file;

my %Std_Parameters;
my $details = &alDente::Tools::initialize_parameters( $dbc, $dbase );
if ($details) { %Std_Parameters = %{$details} }

Message "Writing to $file";

my $ok = &store( \%Std_Parameters, "$file" );

if ( !$opt_file ) {
    $Report->set_Message("Completed  initializing parameters");
    $Report->completed();
    $Report->DESTROY();
}

exit;
