#!/usr/local/bin/perl

#
# This program fixes ALL fields that are set to the string value 'NULL' (as opposed to NULL or undef) and sets it to '' instead.
#

use strict;
use DBI;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";         # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../lib/perl/Core/";         # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../lib/perl/Imported/";         # add the local directory to the lib search path

use RGTools::RGIO;
use vars qw($opt_help $opt_quiet);

use Getopt::Long;
&GetOptions(
	    'help'                  => \$opt_help,
	    'quiet'                 => \$opt_quiet,
	    ## 'parameter_with_value=s' => \$opt_p1,
	    ## 'parameter_as_flag'      => \$opt_p2,
	    );

my $help  = $opt_help;
my $quiet = $opt_quiet;

my $host = 'lims02';
#my $dbase = 'alDente_unit_test_DB';
my $dbase = 'vctr_test';
my $user = 'rguin';
my $pwd;

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );

my @fields = $dbc->Table_find_array('DBTable,DBField',['DBTable_Name','Field_Name'],"where FK_DBTable__ID=DBTable_ID");

my $path = "/home/aldente/private/dumps/limsdev01/vctr/2007-02-26/16:10";

my $corrected = 0;
my $fields_fixed = 0;
my $correct_first_record = 0;
my %Corrected;

foreach my $field (@fields) {
    my ($table,$f) = split ',', $field;

    if ($correct_first_record && !$Corrected{$table}) {
	$Corrected{$table} = 1;
	open (my $FILE, "$path/$table.txt") or print "ERROR CANNOT FIND $path/$table.txt\n";
	my $header = <$FILE>;  ## skip header;
	chomp $header;
	
	my @fields = split '\t', $header;
	
	my $line = <$FILE>;
	chomp $line;
	
	if ($line) { 
#	print "entry found..\n";
	}
	else { 
#	print "(no entries in $table)\n";
	    next; 
	}
	
	my @values = split '\t', $line;
	my $totals = 0;
	
	my ($first_record) = $dbc->Table_find_array($table,\@fields,"LIMIT 1");
	my @first_values = split ',', $first_record;
	
	my $index = 0;
	map {
	    my $val = $_;
	    if (($val=~/[1-9a-zA-Z]/) && ($val !~ /$fields[$index]/) && ($val ne '1' && $fields[$index] ne '$table'.'_ID') ) { 
#	    print "** ($index) $val <> $fields[$index] **\n"; 
		$totals++; 
	    } 
	    $index++; 
	} @first_values;
	
	my %Delete;
	$Delete{Plate}{1} = 1;
	$Delete{Clone_Sample}{1} = 1;
	
	if ($fields[0] eq $table . '_ID') { 
	    my ($field2) = $dbc->Table_find($table,$fields[1],"WHERE $fields[0] = $first_values[0]");
	    if ($field2 eq $fields[1]) { 
		print "Correct header entry in $table where $fields[0] = $first_values[0] **\n";
		correct($table,\@fields,\@values,"$fields[0] = $first_values[0]");
	    } 
	    elsif ($Delete{$table}{1}) {
		print "correct where $table id = $fields[0]";
		correct($table,\@fields,\@values,"$fields[0] = 1");
	    }
	    elsif ($totals > 1) {
		print "*** Skipping $table entry: $field2 <> $fields[1] ** ($totals)\n";
	    }
	    elsif ($first_values[0]==1) {
		print "Fix where $table" . "_ID = 1\n";
		correct($table,\@fields,\@values,"$fields[0] = 1");
	    }
	    else {
		print "*** ID <> 1 in $table ?\n";
	    }
	} 
	elsif ($fields[0] eq $first_values[0]) {
	    print "Correct where $fields[0] eq $first_values[0]\n";
	    correct($table,\@fields,\@values,"$fields[0] = '$first_values[0]'");
	} 
	else {
	    if ($first_values[0] eq $fields[0]) { 
		## Correct
		print "Correct repeat in $table record where $fields[0] = $first_values[0] **\n";
		correct($table,\@fields,\@values,"$fields[0] = '$first_values[0]'");
	    } 
	    elsif ($totals > 1) {
		print "*** Strange $table entry for $table ** ($totals)\n";
	    }	
	    else {
		# Correct ... 
		print "*** NEED to delete in $table where $fields[0] = $first_values[0]\n";
		
	    }
	}
	
	close $FILE;
    }

    ## replace null string values with blank.
    my ($nulls) = $dbc->Table_find($table,'count(*)',"WHERE $f = 'NULL'");
    next unless $nulls;

    print "Null found in $table . $f\n";
    
    my $these_corrected = $dbc->Table_update_array($table,[$f],[''],-condition=>"WHERE $f = 'NULL'",-autoquote=>1);
    if ($these_corrected) {
	print "Fixed $table.$f\n";
	$fields_fixed++;
	$corrected += $these_corrected;
    }
} 

print "corrected $fields_fixed fields ($corrected records)\n";

exit;

#
# Correct given table fields with values shown where condition....
#
################
sub correct {
################
    my $table = shift;
    my $field_ref = shift;
    my $value_ref = shift;
    my $condition = shift;

    unless ($table && $field_ref && $value_ref && $condition) { print "Error: requires all paramaters (table, fields, values, condition)\n"; return; }

    my @fields = @$field_ref;
    my @values = @$value_ref;

    my @delete = $dbc->Table_find_array($table,\@fields,"WHERE $condition");
    
    print "*********************************************\n";
    print "DELETE $table record:\n";

    while (@values < @fields) { push @values, ''; }
    
    print "-"x20 . "\n";
    print join ",", @fields;
    print "\n";
    print "-"x80 . "\n-\t";
    print join "\n+\t", @delete;
    print "\n+\t";
    print join ",", @values;
    print "\n";
    print "-"x80 . "\n";
    

    print "WHERE $condition\n";
    print "\n***********\n";

    
    my $ok = Prompt_Input(-prompt=>'Yes / No / Abort ? (y/n/a) ',-type=>'char');
    
    if ($ok =~ /^y/i) {
	print "**** FIX ****\n";
	if ($table eq 'Stock' && $fields[5] eq 'Stock_Size') { $values[5] = 1; $values[6] = 'pcs';$values[12]=1; $values[16] =2; }
	elsif ($table eq 'Library' && $fields[1] eq 'Library_Type') { $values[1] = '';  }
	my $these_corrected = $dbc->Table_update_array($table,\@fields,\@values,-condition=>"WHERE $condition",-autoquote=>1);
	print "fixed $these_corrected records...\n";
    }
    elsif ($ok =~ /^a/)  {
	print "**** ABORT ****\n";
	exit;
    }
    else {
	print "****  SKIP ****\n";
    }

#    print "UPDATE $table SET @fields = @values WHERE $condition\n";

    return;
}

#############
sub help {
#############

    print <<HELP;

Usage:
*********

    <script> [options]

Mandatory Input:
**************************

Options:
**************************     


Examples:
***********

HELP

}
