#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################
#
##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
################################################################################

use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use Data::Dumper;
use Getopt::Std;

use RGTools::RGIO;
use SDB::DBIO;
use SDB::HTML;
use alDente::Rack;

use vars qw(%Defaults);    ## std defaults (eg SOC_MEDIA_QTY)
use vars qw($opt_v $opt_c $opt_f);

use Getopt::Long;
&GetOptions(
    'v=s' => \$opt_v,
    'c'   => \$opt_c,
    'f'   => \$opt_f
);

my $host       = 'lims07';
my $dbase      = 'seqbeta';
my $login_name = 'super_cron';

my $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $login_name, -connect => 1 );
my @slots = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Type = 'Slot' ORDER BY Rack_ID DESC" );

my $Rack = alDente::Rack->new( -dbc => $dbc );
my $total;
my $changed;
for my $id (@slots) {
    $changed = $Rack->correct_Rack_Full( -rack => $id );
    if ($changed) { $total++ }
}

Message "Changed $total records";

exit;

1

