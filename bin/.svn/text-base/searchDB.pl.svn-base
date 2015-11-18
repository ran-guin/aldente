#!/usr/local/bin/perl
################################################################################
#
# searchDB.pl
#
# This program allows for a shell interface to the database.
#
################################################################################
################################################################################
# $Id: searchDB.pl,v 1.13 2004/09/08 23:45:36 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.13 $
#     CVS Date: $Date: 2004/09/08 23:45:36 $
################################################################################
use strict;
use CGI ':standard';
use DBI;
use Time::Local;
use Shell qw(ls);

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
 
use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;
##############################
# global_vars                #
##############################
use vars qw($style);
use vars qw($opt_D $opt_T $opt_F $opt_C $opt_L $opt_B $opt_S $opt_X $opt_t $opt_G $opt_O $opt_o $opt_s $opt_Q $opt_P $opt_H);
use vars qw(%Defaults);
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
&Getopts('D:T:F:C:L:BS:X:tG:O:o:s:Q:P:H:');
###############################
my $style = 'text';
my $dbase = $opt_D || 'sequence';
my $host = $opt_H || $Defaults{BACKUP_HOST};
my $user = 'guest_user';

use alDente::Session;
use SDB::HTML;
my $session = SDB::Session->new( 'id:md5', $q);
print HTML_Dump $session;

my $dbc = SDB::DBIO->new(-dbase=>$dbase,-host=>$host,-user=>$user,-connect=>1);

my $brief = $opt_B || 0;
my $limit = 96;
my $search = $opt_S;
my $table = $opt_T;
my $output = '';

if (!defined $opt_T && !$search && !$opt_Q)  { _usage();  print $output; exit; }

if (!defined $opt_Q && !defined $opt_T && !$search) {&cutoff();}  ### quit
#
# General Table Descriptions....
#
my %Description = (
		   Run => 'Records of Sequence Runs on Plates',
		   Clone_Sequence => 'Results of Sequence Runs on each Clone',
		   Plate => '96-well and 384-well Laboratory Plates',
		   Equipment => 'Laboratory Equipment (Machines, Freezers, etc.)',
		   Employee => 'Employee Information',
		   Maintenance => 'Tracking of Service/Repairs to Equipment',
		   Protocol => 'Detailed Protocols for Laboratory',
		   Preparation => 'Tracking of all Preparation done on Plates in Lab',
		   Vector => 'List of available/used Vectors associated with Libraries',
		   Library => 'List of Libraries consisting of multiple Plates',
		   Project => 'Specific Projects containing multiple Libraries',
		   );
#
# generate array of tables..
#
my @tables = $dbc->DB_tables();  
if ($opt_Q) {
    if ($opt_P eq 'aldente') {
	$output .= "Querying...\n" unless $brief;
	$output .= "\n" unless $brief;
	$dbc->execute_command(-command=>$opt_Q,-feedback=>2);
	$dbc->disconnect();
	exit;
    } else {
	$output .= "Querying requires Password (check with administrator) to safeguard against query lockup" unless $brief;
	$dbc->disconnect();
	exit;
    }
}
if ($table && !($table=~/list/i)) {@tables = split ',', $table;}     ### only search in specified list if given...
#
# Allow user to search database for fields matching search condition...
# 
if ($search) {
    $search = "$search";
    $output .= "\nList of Fields like $search\n" unless $brief;
    $output .= "**************************************************\n" unless $brief; 
    foreach my $thistable (@tables) {
	foreach my $field (&get_field_info($dbc,$thistable,$search)) {
	    $output .= "$thistable . $field\n";
	}
    }
    cutoff();
}
#
# Generate list of Tables (with description) if no table specified...
#      
if ($table=~/^list$/i) {
    $output .= "List of Tables in $dbase Database\n" unless $brief;
    $output .= "****************************************\n" unless $brief;
    foreach my $thistable (@tables) {
	my $desc;
	if (defined %Description->{$thistable}) {$desc = %Description->{$thistable};}
	$output .= "$thistable - \t$desc\n";
    }
    cutoff();					
}
#
# Generate list of Fields if no Fields are specified
#
my %Index;  ### allow indexing of stored arrays if specified...
my $fields = $opt_F;
if ( ($fields=~/\?/) || !$fields || ($fields=~/^list/i) ) {
    $output .= "\nList of Fields in $table Table\n" unless $brief;
    $output .= "****************************************\n" unless $brief;
    foreach my $field (&get_fields($dbc,$table)) { ## (was get_defined_fields ) ##
	$output .= "$field\n";
    }
    cutoff();
} elsif ($fields=~/^all$/) {
    $fields = join ',',get_fields($dbc,$table); ## (was get_defined_fields ) ##
    $output .= "Fields: $fields\n" unless $brief;
} elsif ($fields=~/^\*$/) {
    $fields = join ',',get_fields($dbc,$table); ## (was get_defined_fields ) ##
    $output .= "Fields: $fields\n" unless $brief;
}
#    my $original_fields = $fields;
#    if ($fields=~/\(/) {
#	while ($fields=~s/^(.*?)([a-zA-Z0-9_]+)\((.*?)\)(.*)/$1$2$4/) {
#	    %Index->{$2} = $3;
#	    $output .= "\n(Extracting element -> $2 (". %Index->{$2} . ")\n";
#	}
#    }
while ($fields=~s/Phred\((\d+)\)/Phred_Histogram as Phred$1/) {}
while ($fields=~s/Score\((\d+)\)/Sequence_Scores as Score$1/) {}
my @field = split ',', $fields;
my $condition = $opt_C;
#    $condition =~s /\s//g;
my $Xcondition = $opt_X || 1;  ### optional extra condition...
#
# Generate table connections if required
#
my $found = 0;
my $C1; 
my $C2;
my $Ccondition;
if (scalar(@tables)==2) {          # if more than one table...
    my $index=0;
    foreach my $thistable (@tables) {
	my @all_fields = &get_fields($dbc,$thistable); ## (was get_defined_fields ) ##
	foreach my $thisfield (@all_fields) {
	    if ($thisfield=~/^FK[a-zA-Z]*_(\S+)__(\S+)/) {
		my $other_table = $1;
		my $other_field = $2;
		if ($tables[1-$index] eq $other_table) {
		    $found++;
		    $C1 = $thisfield;
		    $C2 = $other_table."_".$other_field;
		}
	    }
	}
	$index++;
    }
    if ($found==1) {$Ccondition = "$C1=$C2";}
}
if ($opt_L) {$limit = "limit $opt_L";}
else {$limit = "limit $limit";}
my $group;
if ($opt_G) {$group = "Group by $opt_G";}
my $order;
if ($opt_O) {$order = "Order by $opt_O";}
my $outfile;
if ($opt_o) {$outfile = $opt_o;}
$condition=~s/\|/ OR /g; 
$output .= "******* Condition:  $condition *************\n" unless $brief;
my @conditions = split ';',$condition;
my @final_conditions;
foreach my $cond (@conditions) {
    if ($cond=~/[\*\%]/) {
	while ($cond=~s/([\w\d\_\']+)\!=([\w\d\*\%\']+)/$1 NOT LIKE \'$2\'/g) {
#	    $cond = "$1 not like '$2'";
	    $cond =~s /\*/\%/g;
	}
	while ($cond=~s/([\w\d\_\']+)=([\w\d\*\%\']+)/$1 LIKE \'$2\'/g) {
	    $cond =~s /\*/\%/g;
	}
	while ($cond=~s/([\w\d\_]+)([<>])([\w\d\*\%\_]+)/$1 $2 $3/) {
	}
    }
    push(@final_conditions,$cond);
}
if ($Ccondition) {push(@final_conditions,$Ccondition);}
my $search_condition = join ' AND ',@final_conditions;
if ($search_condition) {$condition="where $search_condition ";}
else {$condition = "where 1";} 
$output .= "Select $fields from $table $condition and $Xcondition $group $order $limit\n\n" unless $brief;
(my $count) = &Table_find_array($dbc,$table,['count(*)'],"$condition and $Xcondition");
unless ($brief) {$output .= "$count Total records found (displaying up to $limit)\n\n";}
my %data = &Table_retrieve($dbc,$table,\@field,"$condition and $Xcondition $group $order $limit");
my @field_list = keys %data;
my $field_titles = join ',',@field_list;
my $records = 0;
my @all_output;
my $packed =0;
my %Average;
my %AverageOf;
while (defined %data->{$field_list[0]}[$records]) {
#	foreach my $thisdata (@data) {
    my $output;
    foreach my $thisfield (@field_list) {
	my $thisdata = %data->{$thisfield}[$records];
	my $thisoutput;
#	    if (($thisfield=~/Histogram\(?(\d*)/i) ||
#		($thisfield=~/Scores\(?(\d*)/i)) {
#		my $index;
#		if (defined %Index->{$thisfield}) {$index = %Index->{$thisfield};}
#		$fields=~s/$thisfield,/$thisfield($index),/g;
#		$fields=~s/$thisfield$/$thisfield($index)/g;
#		
#		$packed = 1;
#		my @list_values = unpackit($thisdata,2);
#		if (defined $index) {
#		    $thisoutput = $list_values[$index];
#		    %Average->{$thisfield} += $thisoutput;
#		    %AverageOf->{$thisfield}++;
#		}
#		else {$thisoutput = join ',', @list_values;}
#	    }
	if ($thisfield=~/Phred\(?(\d+)/) {
	    my $index = $1;
	    $packed = 1;
	    my @list_values = unpackit($thisdata,2);
	    if ($index>0) {
		$thisoutput = $list_values[$index];
		%Average->{$thisfield} += $thisoutput;
		%AverageOf->{$thisfield}++;
	    }
	    else {$thisoutput = join ',', @list_values;}
	}
	elsif ($thisfield=~/Score\(?(\d+)/) {
	    my $index = $1;
	    $packed = 1;
	    my @list_values = unpackit($thisdata,1);
	    if ($index>0) {
		$thisoutput = $list_values[$index];
		%Average->{$thisfield} += $thisoutput;
		%AverageOf->{$thisfield}++;
	    }
	    else {$thisoutput = join ',', @list_values;}
	}
	elsif ($thisdata=~/^[\-\d\.eE]+$/) {
	    $thisoutput = $thisdata;
	    %Average->{$thisfield} += $thisoutput;
	    %AverageOf->{$thisfield}++;
	} else { 
	    $thisoutput = $thisdata; 
	}
	$output .= $thisoutput;
	unless ($opt_s) { $output .= "\t" }
    }
    push(@all_output,$output);
    $records++;
}
my $splitter = $opt_s || "\n";
if (!$brief && $packed) {$splitter = "\n\n";}
######### $Output .= headers ##############
$field_titles=~s/,/\t/g; 
$output .= "$field_titles\n";
unless ($brief) {
    $field_titles=~s/[a-zA-Z0-9_]/*/g;
    $output .= "$field_titles\n";	
}
##### $Output .= results ########
$output .= join $splitter, @all_output;
############# $Output .= Averages ############
if ($brief) {$output .= "\n";}
else {
    $output .= "\n\nTotals:\n**************\n";
    foreach my $thisfield (@field) {
	if (defined %Average->{$thisfield} && %Average->{$thisfield}) {
	    $output .= "\n\nAverage $thisfield:\t". %Average->{$thisfield}/%AverageOf->{$thisfield};
	}
    }
    $output .= "\n\n($records/$count record(s) listed)\n\n";
}

print $output;

if ($outfile) {
    open(FILE,">$outfile") or die "Cannot open $outfile\n";
    print FILE $output;
}
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

#################
sub unpackit {
#################
    my $value = shift;
    my $bytes = shift;

    my @values;
    if ($bytes == 1) { @values = unpack "C*", $value;}
    elsif ($bytes == 2) { @values = unpack "S*", $value;}
    
    return @values;
}

################
sub cutoff {
################
    my $message = shift;
    $output .= "$message\n\n";
    $dbc->disconnect();
    exit;
}
#############
sub _usage {
#############
    $output .= <<END
Program: searchDB
#######################
  Usage:  searchDB -option 
    Options:
    -D database         (optional - may specify a particular database - defaults to sequence)
    -Q query            (optional - excludes need for specifications below)
    -T table            (mandatory - specify which tables you wish to search)
	                  eg. -T Clone_Sequence
    -F fields           (mandatory - specify field names you wish to display)
     	                  eg. -F Run_ID,Well
			      -F Phred(20),Well
    -C condition        (optional - specify search condition - do NOT use spaces or quotes)
	                  eg. -C "FK_Run__ID=2567;Well=A01;Quality_Length>500"
			      -C "FK_Run__ID=2567; (Well=A* | Well=B*)"   - wells A,B
			      -C "FK_Run__ID=2567; (Well!=A*,Well!=B*)"   - wells C - H
			    Note:  It is safest to use quotes around the whole string
    -L limit            (optional - limits output to (limit) records -defaults to 96
    -G group_list       (optional - groups output by field(s))
    -O order_list       (optional - orders output by field(s))
    -B                  (optional 'brief' mode - displays only data and no text)   
    -S search string    (allows user to search for a field matching a pattern)
			  eg. -S phred%  - Note that the '%' is used as a wildcard instead of '*'

    -s output delimiter
##########################
Getting Started:
   To list possible Tables type:
	      searchDB -T list
   To find possible Fields in a table type (for example):
	      searchDB -T Clone_Sequence
	      searchDB -Q 'desc Clone_Sequence'
   To find fields and Tables that match a certain pattern:
	      eg. - to find all the fields in the table that have the word 'well' in them:
	      searchDB -S %well%
   (Use proper field names to specify both -F, and -C conditions)
   This will later be made a bit more user friendly, but hopefully this will 
   provide fairly easy access to data in the database temporarily.
NOTE: The program automatically joins two tables if this can be done unambiguously.
##############################################################################################
	 this simplifies queries such as
         searchDB -T Clone_Sequence,Run -F "Quality_Length,Phred(20),Run_Directory" -C "Quality_Length>800;Run_Directory=LL*"
###################################################################################################################
	CHANGE NOTES:  
	###############
	Please use semicolon (;) to separate conditions.
	(This will allow commas to be used in formats such as 
	    'Plate_ID in (1,2,3)' 
	Also:  to get Phred values or Score values, a simpler format is available:
	    use -F 'Phred(20),Score(10)' - this will grab Phred 20 values (and scores for the 10th base pair).	 
END


} 
