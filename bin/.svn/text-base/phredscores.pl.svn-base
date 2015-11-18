#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

phredscores.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>system_variables           #<BR>standard_modules_ref       #<BR>phreadscores.pl<BR>This program takes a given run ID and output the phred scores in a CSV output format<BR>

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
###############################
# phreadscores.pl
#######################################
#
# This program takes a given run ID and output the phred scores in a CSV output format
# 
#
#######################################
use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use SDB::CustomSettings;
use SDB::DBIO;
use RGTools::RGIO;
use alDente::SDB_Defaults;  ### get directories only...
use Sequencing::Sequence;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($opt_S $opt_D);
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
&Getopts('S:D:');
my $idlist = $opt_S if ($opt_S);
my $directory = $opt_D if ($opt_D);
if ($idlist) {
   # replace ranges. e.g. '1,3-6' becomes '1,3,4,5,6'
    while (($idlist=~/(\d+)[-](\d+)/) && ($2>$1)) {
	my $numlist = join ',',($1..$2);
	$idlist=~s/$1[-]$2/$numlist/;
    }
}
else {
    _print_help_info();
}
unless ($directory) {$directory = "."} #default to current directory

my $dbc = SDB::DBIO->new(-dbase=>'sequence',-user=>'labuser',-password=>'manybases',-host=>$Defaults{mySQL_HOST},-connect=>0);
$dbc->connect();
#Generate output one by one
foreach my $runid (split /,/, $idlist) {
    my $found;
    #Get the wells into an array.
    my %Info = &Table_retrieve($dbc,'Run,Clone_Sequence',['Well'],"where Run_ID = FK_Run__ID and Run_ID = $runid and Growth in ('OK','Slow Growth') order by Well");  
    my @wells;
    my $index=0;
    while (defined %Info->{'Well'}[$index]) {
	$found = 1;
	push(@wells, %Info->{'Well'}[$index]);
	$index++;
    }
    #Get the scores into an array.
    #my %Info = &Table_retrieve($dbc,'Run,SequenceAnalysis',['Q20array'],"where Run_ID = FK_Run__ID and Run_ID = $runid"); 
    #my @Q20;
    #my $index=0;
    #while (defined %Info->{'Q20array'}[$index]) {
	#my $packed = %Info->{'Q20array'}[$index];
	#push(@Q20, unpack "S*", $packed);
	#$index++;
    #}
    if ($found) {
	#redirect console output to CSV file.
	my $file = "$directory/$runid" . "_phredscores.csv";
	print "Generating $file...\n";
	my $stdout = select(OUTPUT); 
	open(OUTPUT,">$file") or die("Cannot write to the file: $file");
	#Put together the wells and scores into a CSV format.
	for (my $i=0; $i<=$#wells; $i++) {
	    my $Q20;
	    my @fields = ('Phred_Histogram');
	    (my $num) = &Table_find_array($dbc,'Clone_Sequence',\@fields,"where FK_Run__ID = $runid and Well = '$wells[$i]'");
	    my @unpacked_num = unpack "S*",$num;
	    $Q20 = $unpacked_num[20];
	    #print "$wells[$i],$Q20[$i]\n";
	    print "$wells[$i],$Q20\n";
	}
	select($stdout);
	close(OUTPUT); 
    }
    else {
	print "No data found for sequence ID $runid.\n";
    }
}exit;

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

##########################
sub _print_help_info {
##########################

#
#Prints the help info to the console if the -h switch is specified.
#
print<<HELP;

File:  phredscores.pl
####################
This program takes a given run ID and output the phred scores in a CSV output format.

Options:
##########

------------------------------
1) Database login information:
------------------------------
-S     run/sequence ID specification (required)
-D     directory where the output CSV file will be (optional). If not provided, then the default directory is the current directory.

Examples:
###########
To get the phred scores for run ID 15000 and output CSV file:                       phredscores -S 15000
To get the phred scores for run ID 15000 and output CSV file to /home/sequence:     phredscores -S 15000 -D /home/sequence
To get the phred scores for run ID 15000,16000:                                     phredscores -S 15000,16000
To get the phred scores for run ID 15000,16000,17000-17005,18000:                   phredscores -S 15000,16000,17000-17005,18000

HELP

    exit;
}

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

$Id: phredscores.pl,v 1.3 2003/11/27 19:37:36 achan Exp $ (Release: $Name:  $)

=cut

