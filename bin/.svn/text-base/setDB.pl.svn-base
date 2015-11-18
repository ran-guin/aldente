#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

setDB.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>system_variables           #<BR>standard_modules_ref       #<BR>This program sets up a Table documenting Field parameters for a database.<BR>It facilitates flexible editing of Field settings including <BR>definition of prompts and foreign key references which may be used by the SDB module<BR>

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
##############################
# setDB.pl
#
# This program sets up a Table documenting Field parameters for a database.
#
# It facilitates flexible editing of Field settings including 
# definition of prompts and foreign key references which may be used by the SDB module
#
###############################
use strict;
use CGI qw(:standard);
use DBI;
use Getopt::Std;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use SDB::DBIO; 
use SDB::CustomSettings;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw(%Prompts %Fields %Primary_fields %Mandatory_fields $testing);
use vars qw($opt_T $opt_D);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
getopts('T:D:');
print "Begin " . localtime() . "\n";
my $dbase = $opt_D;
unless ($dbase) {
    print<<USAGE;
Usage: setDB.pl -D dbase
USAGE
    exit;
}
my $user = 'super_cron';
my $password = SDB::DBIO::get_password_from_file(-host=>$host, -user=>$user);

my $dbc = SDB::DBIO->new(-host=>$host,-dbase=>$dbase,-user=>$user,-password=>$password);
unless ($dbc && $dbc->ping) { print "Cannot connect to $dbase\n"; exit; }
my @Prompt_keys = keys %Prompts;            #### Temporary
my @Tables = $dbc->DB_tables();
if ($opt_T) { @Tables = split ',', $opt_T; }
my %Field_Info = initialize_field_info($dbc);
foreach my $table (@Tables) {
    print "Table: $table...\n**************\n";
    my @Fields_found = &get_field_info($dbc,$table);
    print int(@Fields_found) . " fields. ";
    my $field_list = %Fields->{$table} || 0;
    my @Showfields;
    if ($field_list) {@Showfields = @{ $field_list };}
    my @Field_list;
    my ($table_id) = &Table_find($dbc,'DBTable','DBTable_ID',"where DBTable_Name = '$table'");
    unless ($table_id=~/[1-9]/) {
	$table_id = &Table_append_array($dbc,'DBTable',['DBTable_Name'],[$table],-autoquote=>1);
    }
    my $order = 1;
    my %Hide;
    next;
    if (@Showfields) {
	@Field_list = @Showfields;
	foreach my $field (@Fields_found) {
	    unless (grep /^$field$/, @Showfields) {
		push(@Field_list,$field);
		%Hide->{$field} = 'Hidden';
	    }
	}
    } else { @Field_list = @Fields_found; }
    my ($id_field) = get_field_info($dbc,$table,undef,'Pri');
    print "(ID: $id_field)\n";
    my $added = 0;
    my $updated = 0;
    foreach my $field (@Field_list) {
	my $alias = $field;
	print $field;
	$alias=~s/^FK//;
	$alias=~s/^_//;
	$alias=~s/^$table[_]//;
	my $prompt = %Prompts->{$table}[$order-1] || $alias;  ### Temporary
	my ($options) = &Table_find($dbc,'DBField','Field_Options',"where Field_Name like '$field' and FK_DBTable__ID=$table_id");
	if (%Hide->{$field}) {$options .= ",Hidden"; }
	if (%Mandatory_fields->{$field}) { $options .= ",Mandatory"; }
	if ($field eq $id_field) {$options .= ",Primary"; }
	my $ref = %FK_View->{$field} || '';   ### Temporary... 
	unless ($ref) {
	    if ($field=~/^FK(.*?)\_(.*)[_]{2}(.*)$/) {
		$ref = "$2_$3";
	    } 
	}
	my $type = %Field_Info->{$table}->{$field}->{Type};
	my $null_ok = %Field_Info->{$table}->{$field}->{Null} || 'NO';
	my $default = %Field_Info->{$table}->{$field}->{Default};
	my $fk='';
	if ((my ($Ftable,$Ffield) =  foreign_key_check($field))) {
	    $fk = "$Ftable.$Ffield";
	}
	my ($found) = &Table_find($dbc,'DBField','DBField_ID',"where Field_Name like '$field' and FK_DBTable__ID=$table_id");
	my ($current_options) = join ',', &Table_find($dbc,'DBField','Field_Options',"where Field_Name like '$field' and FK_DBTable__ID=$table_id");
	$options = "$current_options,$options";
	my @fields = ('Field_Name','FK_DBTable__ID','Prompt','Field_Alias','Field_Options','Field_Reference','Field_Order','Field_Type','NULL_ok','Foreign_Key');
	my @values = ($field,$table_id,$prompt,$alias,$options,$ref,$order,$type,$null_ok,$fk);
	if ($default) { 
	    push(@fields,'Field_Default');
	    push(@values,$default);
	}
	print " ** $prompt ** (D:$default; NULL:$null_ok; T:$type; O:$options)\n";
	if ($found=~/\d/) {
	    my $ok = &Table_update_array($dbc,'DBField',\@fields,\@values,"where DBField_ID = $found",-autoquote=>1);
	    if ($ok) {$updated++;}
	} else { 
	    my $ok = &Table_append_array($dbc,'DBField',['Field_Name','FK_DBTable__ID','Prompt','Field_Alias','Field_Options','Field_Reference','Field_Order','Field_Type','NULL_ok','Foreign_Key'],[$field,$table_id,$prompt,$alias,$options,$ref,$order,$type,$null_ok,$fk],-autoquote=>1);
	    if ($ok) {$added++;}
	}
	$order++;
    }
    print "$order:  $added added.  $updated edited.\n\n";
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

$Id: setDB.pl,v 1.11 2004/06/03 18:11:52 achan Exp $ (Release: $Name:  $)

=cut

