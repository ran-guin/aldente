#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

parse_table.pl - !/usr/local/bin/perl

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
#     CVS Date: $Date: 2004/07/06 18:34:05 $
################################################################################
use strict;
use CGI ':standard';
use DB_File;
use Data::Dumper;
use File::stat;
use Time::Local;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use RGTools::RGIO;
use RGTools::Conversion;
use SDB::DBIO;

use SDB::CustomSettings;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($LIB);
use vars qw($opt_T $opt_F $opt_f $opt_c $opt_D $opt_h $opt_s $opt_S $opt_V $opt_R $opt_d $opt_r $opt_u $opt_p $opt_q $opt_H $opt_t $opt_x $opt_P $opt_N);
use vars qw($testing);
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
&Getopts('T:F:f:c:h:D:s:S:V:R:d:r:u:p:qH:tx:P:N:');
my $table;
my @fields;
my @columns;
my $filename;
my $dbase;
my $header_lines;
if ($opt_T) { $table = $opt_T; }
else {
    print <<HELP;
File: parse_table.pl 
###########################
Usage:
#########
This routine takes a tab-delimited text file and writes columns into the database.
Options:
###########
Mandatory:
#############
    -D (database)  Specify the database to which you are writing 
    -T (table name)  Specify the table to which you are writing 
    -f (filename)    The name of the text file
    -H (host)        Optional host specification (for mysql server)
    -u (user)        User (name used for connection to database)
Optional:
#############
    -F (Field list)  List of fieldnames (in order) as they appear in the database table
	(if NOT chosen, the field names will be extracted from the first line read from the file)
    -c (columns)     A list of columns to include (optional - default = all columns)
    -h (headersize)   Specify the number of lines of header to be skipped 
    -t                Perform test first (Useful to provide check that the right data is being extracted).
    -x (string)      Exclude lines beginning with <string>
    -d (datefields)  Date fields (forces conversion to SQL format - YYYY-MM-DD)
    -P (field1=default1,field2=default2)    Preset defaults for specific fields
    -N (number)      Stop after importing N records 
##################################
### Example ###
eg. 'parse_table.pl -c 1,4  -u guest -f data.txt -h 3 -T Clone -F Clone_Source_ID,Clone_Source_Name -D sequence'
#
will extract columns 1 and 4 (-c 1,4)
from data.txt (-f data.txt)
(after skipping the first 3 lines in the file). (-h 3)
and place the results into the Clone table (-T Clone)
in fields Clone_Source_ID and Clone_Source_Name (-F Clone_Source_ID,Clone_Source_Name)
in the sequence database.  (-D sequence) 
###################################
HELP
    exit;
}

my $debug = $opt_d;
if ($opt_F) { @fields = split ',', $opt_F; }
if ($opt_f) { $filename = $opt_f; }
else        { print "You must specify a file to parse (-f (filename))\n"; exit; }
if ($opt_c) { @columns = split ',', $opt_c; print "Extracting columns @columns\n"; }
else        { @columns = split print "Extracting all columns\n"; }
if   ($opt_D) { $dbase = $opt_D; }
else          { $dbase = 'sequence'; }
if ($opt_h) { $header_lines = $opt_h; }
my $quote = 0;

#if ($opt_q) {$quote = 'autoquote'; }
$quote = 'autoquote';
my @static_fields;
my @static_values;
if ( $opt_S && $opt_V ) {
    @static_values = split ',', $opt_V;
    @static_fields = split ',', $opt_S;
    if (@fields) { push( @fields, @static_fields ); }
}
my $user     = $opt_u || 'guest';
my $password = $opt_p || '';
my $exclude  = $opt_x;
my $test     = $opt_t || 0;
my $date_fields     = $opt_d;
my $Preset_Defaults = $opt_P;
my $N               = $opt_N;

my %Field_Defaults;
if ($Preset_Defaults) {
    my @Def_list = split ',', $Preset_Defaults;
    foreach my $def (@Def_list) {
        if ( $def =~ /^\s*(\w+)\s*=(.*?)\s*$/ ) {
            $Field_Defaults{$1} = $2;
        }
        else {
            Message("Did not recognize default: $def\n");
        }
    }
}

my $sep = "\t";
if ($opt_s) {
    $sep = $opt_s;
}
print "using database $dbase\n";
print "Parsing file: $filename...\n";
open( TABLE, "$filename" ) or die "Error opening table: $filename";
my $host = $opt_H || $Defaults{mySQL_HOST};
if ( $user =~ /(.*?)\s*\((.*)\)/ ) {
    $user     = $1;
    $password = $2;
}
elsif ( !$user ) {
    $user = Prompt_Input( -prompt => 'Username: ' );
}
unless ($password) {
    $password = Prompt_Input( -prompt => 'Password: ', -type => 'password' );
}

my $dbc = new SDB::DBIO( -dbase => $dbase, -user => $user, -password => $password, -host => $host, -connect => 1 );

unless ( $dbc && $dbc->ping() && $password ) { print "\n\nConnection to database failed\n\n"; exit; }
my $added = 0;
my $tried = 0;
my @failed;
my $line_num = 0;
my $skipped  = 0;

my @lines = split "\n", try_system_command('cat $filename');
foreach my $line (@lines) {

    # my $line = $_;
    print "Line " . length($line) . "\n";
    if ( $exclude && $line =~ /^$exclude/ ) { $skipped++; next; }
    if ($opt_r) { $line =~ s/$opt_r//g; }    ## replace character with blank.
    if ( $line =~ /(.*\S)/ ) { $line = $1; } ## clear NT linebreak (chomp doesn't seem to do it ??)
    if ($debug) { print "\nLine: ($line).\n"; }
    if ( !$sep && !( $line =~ /\t/ ) ) {
        if ( !( $line =~ /\S/ ) ) { next; }
        print "\nWarning:  Line list_contains no Tabs .. use '-s' switch to use (more than one space) to delimit lines\n\n";
        print "(press any key to exit or press C to Continue)\n";
        my $promptchar = getc;
        if ( !( $promptchar =~ /^c/i ) ) { close(TABLE); $dbc->disconnect(); exit; }

    }
    $line_num++;
    if ( $N && ( $line_num > $N ) ) {last}
    if ($opt_R) {
        if ( $opt_R =~ /^$line_num$|^$line_num[,]|[,]$line_num[,]|[,]$line_num$/ ) {
            print "\nValues ($line_num)\n*************\n";
            my @split_line = split "$sep", $line;
            my $record     = 1;
            my $field_num  = 0;
            foreach my $col (@split_line) {
                my $prompt = "$record:";
                if ( grep /^$record$/, @columns ) {
                    $prompt = "$fields[$field_num] ($record):";
                    $field_num++;
                }
                if ($col) { print "$prompt\t$col\n"; }
                $record++;
            }
            my @thesevalues = &get_data( $line, \@columns, 1, $sep );
            print "\nLINE: $line";
            print "\nExiting...\n\n";
            print "\nuse -D database to append to database\n\n";
            next;

            #	else {Message("Error: $DBI::errstr Line $line_num");}
        }
        else { next; }
    }
    else { next; }
}

my $line;
if ( $header_lines >= $line_num ) { print "skipping line $line_num (header)\n"; next; }
if ( !( $line =~ /\S/ ) ) { next; }
print "\nL: $line_num ($header_lines)\n";
my $append = 0;
my @values;
if ( int(@fields) < 1 ) {
    ####### Get fields from first row of data ########
    @fields = &get_data( $line, \@columns, 0, $sep );
    print "Extracting fields: ";
    print join ',', @fields;
    print "\n";
    print "+: " . join ',', @static_values;
    if (@static_fields) { push( @fields, @static_fields ); }
}
else {
    @values = &get_data( $line, \@columns, 1, $sep );    # add quotes if nec.
    $append = 1;
}
if ($test) {last}
if (@static_fields) { push( @values, @static_values ); }
if ($append) {
    $tried++;
    my $ok = Table_append_array( $dbc, $table, \@fields, \@values, -autoquote => $quote, -debug => $debug );
    if ($ok) {

        #	print "$ok: Line $line_num added to @fields.\n";
        $added++;

        #	else {Message("Error: $DBI::errstr Line $line_num");}
    }
    else {
        @values = &get_data( $line, \@columns, 1, $sep );    # add quotes if nec.
        $append = 1;
    }

    if (@static_fields) { push( @values, @static_values ); }

    if ( $append && !$test ) {
        $tried++;

        my $ok = Table_append_array( $dbc, $table, \@fields, \@values, -autoquote => $quote );
        if ($ok) {

            #	print "$ok: Line $line_num added to @fields.\n";
            $added++;

            #	else {Message("Error: $DBI::errstr Line $line_num");}
        }
        else {
            push( @failed, $tried );
            print "Error: $DBI::errstr Line $line_num";
        }
    }

}
$dbc->disconnect();
print "\nCompleted:  Added $added lines of $tried\n";
print "Skipped: $skipped lines\n";
if ($test)   { print "** Nothing changed (only test run) **\n" }
if (@failed) { print "\n (Failed: @failed)\n\n" }
print "\n\n";
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

#####################
sub get_data {
#####################
    my $line       = shift;
    my $columns    = shift;
    my $add_quotes = shift;
    my $delim      = shift || "\t";
    my $default    = shift || 'NULL';

    if ( $delim =~ /s/i ) { $line =~ s/\s{2,}/\t/g; }

    my @cols = @$columns if $columns;

    my @data_line = split $delim, $line;
    my $col_num   = 1;
    my $included  = 0;
    ####### Get data from line ###########
    my @field;

    unless (@columns) { @columns = 1 .. int(@data_line) }

    #    foreach my $col (@data_line) {
    foreach my $col_num (@columns) {
        my $col = $data_line[ $col_num - 1 ];
        unless ($col) { $col = $Field_Defaults{ $fields[$included] } || $default }

        if ( $fields[$included] && $date_fields =~ /\b$fields[$included]\b/ ) { $col = convert_date( $col, 'SQL' ) }
        if ($quote) {
            if ( $col =~ /^[\'\"](.*)[\'\"]$/ ) { $col = $1; }
        }
        push( @field, $col );
        if ( $fields[$included] ) { print "col $col_num : " . $fields[$included] . " = $col.\n" }    ## don't print first time through when pulling out field headings
        $included++;
    }
    print "*" x 20;
    print "\n";

    unless ( $included == $#fields + 1 ) {
        unless ($test) { print "** Warning: columns ($included) equal fields ($#fields + 1) ? **\n" }
    }

    if ( int(@fields) > $included ) {
        for ( $included .. $#fields ) {
            push( @field, $default );
            print "** Added " . int(@fields) - $included . " default fields\n";
        }
    }
    return @field;
}

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

2003-08-19

=head1 REVISION <UPLINK>

$Id: parse_table.pl,v 1.12 2004/07/06 18:34:05 rguin Exp $ (Release: $Name:  $)

=cut

