#!/usr/local/bin/perl

use strict;
use DBI;
use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../../lib/perl/";             # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../../lib/perl/Core/";        # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../../lib/perl/Imported/";    # add the local directory to the lib search path
use Getopt::Long;

use RGTools::RGIO;
use SDB::DBIO;
use alDente::Invoiceable_Work;

use vars qw($opt_help $opt_host $opt_dbase $opt_user $opt_pwd $opt_work $opt_prep);

&GetOptions(
    'help'    => \$opt_help,
    'dbase=s' => \$opt_dbase,
    'host=s'  => \$opt_host,
    'user=s'  => \$opt_user,
    'pwd=s'   => \$opt_pwd,
    'work=s'  => \$opt_work,
    'prep=s'  => \$opt_prep,
);

my $help  = $opt_help;
my $host  = $opt_host || 'limsdev04';
my $dbase = $opt_dbase || 'seqdev';
my $user  = $opt_user || 'unit_tester';
my $pwd   = $opt_pwd || 'unit_tester';
my $prep  = $opt_prep;
my $work  = $opt_work;

if ( !$prep ) { help(); exit; }

require SDB::DBIO;
my $dbc = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pwd,
    -connect  => 1,
);

my $invoiceable_work = new alDente::Invoiceable_Work( -dbc => $dbc );

#$invoice->backfill_invoiceable_work(-prep => 'Upstream_Library_Construction', -work => 'Plate Based PCR Free Library Construction');
my $added = $invoiceable_work->backfill_invoiceable_work( -prep => $prep, -work => $work );

if ( $added > 0 ) {
    print Message("Backfill complete");
    exit;
}

print Message("Nothing found to backfill...");
exit;

##########################
sub help {
##########################

    print <<HELP;

Usage:
*********

    backfill_Invoiceable_Work_Data.pl -prep <prep> -work <work>

    This is used to backfill the Invoiceable_Work and Invoiceable_Work_Reference table with invoiceable_Work

Mandatory Input:
**************************
    -prep: The Invoice_Protocol_Type. This could be "Upstream_Library_Construction" or "Sample_QC"
    
Options:
**************************     
    -host
    -base
    -user
    -pwd
    -work: The Invoice_Protocol_Name in the database
    

Examples:
***********

    backfill_Invoiceable_Work_Data.pl -prep Sample_QC

    backfill_Invoiceable_Work_Data.pl -prep Sample_QC -work Agilent

    backfill_Invoiceable_Work_Data.pl -host lims05 -dbase seqtest -user aldente_admin -pwd ****** -prep Upstream_Library_Construction -work 'Plate based PCR free Library Construction'
    
HELP

}
