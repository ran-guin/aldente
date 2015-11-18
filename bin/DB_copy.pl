#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

DB_copy.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>system_variables           #<BR>standard_modules_ref       #<BR>

=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);
use DBI;
use Benchmark;
use Carp;
use CGI::Carp qw(fatalsToBrowser);
use Date::Calc qw(Day_of_Week);
use Storable;
############## Local Modules ################
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use SDB::DBIO;
use alDente::Plate;
use alDente::SDB_Defaults;
use RGTools::RGIO;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($testing);
use vars qw($opt_X $opt_D $opt_T $opt_C $opt_t); 
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
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

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: DB_copy.pl,v 1.2 2003/11/27 19:37:34 achan Exp $ (Release: $Name:  $)

=cut

