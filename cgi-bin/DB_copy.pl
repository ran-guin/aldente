#!/usr/local/bin/perl

use strict;
use CGI qw(:standard);
use DBI;
use Benchmark;
use Carp;
use CGI::Carp qw(fatalsToBrowser);
use Date::Calc qw(Day_of_Week);
use Storable;

############## Local Modules ################
use lib "/home/martink/export/prod/modules/gscweb";
use gscweb;
use local::Barcode;

 
use RGTools::RGIO;
use alDente::Plate;
use alDente::SDB_Defaults;

use vars qw($testing);
use vars qw($opt_X $opt_D $opt_T $opt_C $opt_t); 

require "getopts.pl";
&Getopts('X:D:T:t:C:');

########### General variables ... ##############

my $dbase = $opt_D;
my $table = $opt_T;
my $exclusions = $opt_X;
my $timeField = $opt_t;
my $condition = $opt_C;

unless ($condition && $table && $dbase) {
    print "\n\nYou MUST include the Database (-D DatabaseName), Table (-T TableName), and Condition (-C 'Condition')\n*******************************************************************************************************\n\n";
    print "and optionally: \n\n";
    print "-t (datefield) - this will replace this field with the current date/time\n";
    print "-X (excluded fields) - these fields will not be copied over (Generally need to include Primary keys)\n\n";

   exit;
}

my $dbc = DB_Connect(dbase=>$dbase);

my @exclusion_list = split ',', $exclusions;
(my $ok,my $copy_time) = &Table_copy($dbc,$table,$condition,\@exclusion_list,$timeField);

print "$ok records copied ($copy_time)\n\n";

$dbc->disconnect();
exit;
