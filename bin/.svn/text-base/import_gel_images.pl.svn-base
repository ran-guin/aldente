#!/usr/local/bin/perl

use strict;
use Data::Dumper;
use Getopt::Std;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use SDB::DBIO;
use SDB::CustomSettings;
use alDente::GelAnalysis;
use RGTools::Process_Monitor;

use vars qw($opt_u $opt_h $opt_d $opt_r);

getopts('u:h:d:r:');

#### Direct Connect
my $user        = $opt_u;
my $host        = $opt_h;
my $dbase       = $opt_d;

my $dbc = SDB::DBIO->new(-host=>$host,-dbase=>$dbase,-user=>$user,-connect=>0);
$dbc->connect();

my $Report = Process_Monitor->new();

$Report->set_Message("Using $user on $dbase:$host");

if($dbc) {
    my $runs = $opt_r;
    my $done = alDente::GelAnalysis::import_gel_image(-dbc=>$dbc,-make_thumbnail=>1,-run_ids=>$runs,-report=>$Report);
    $Report->set_Message("Gel Runs Imported:");

    my @done;
    @done = @{$done} if ($done);
    if(int(@done) > 0) {
        my $run_ids = join("\n\t",@{$done});
        $Report->set_Message("Parsing $run_ids");
    } else {
        $Report->set_Message("None!");
    }

    $dbc->disconnect();
    $Report->set_Message("Gel Image Import successfully finished!");
    
} else {
    
    $Report->set_Error("Can't Connect to the database");

}

$Report->completed();
$Report->DESTROY();

exit;

