#!/usr/local/bin/perl

use strict;
use Getopt::Std;
use Data::Dumper;
use DBI;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use SDB::CustomSettings;
use SDB::DBIO;
use RGTools::RGIO;
use alDente::SDB_Defaults;

use vars qw( $opt_host $opt_dbase $opt_user $opt_pass $opt_table $opt_name $opt_help );

use Getopt::Long;
&GetOptions(
    'help|h|?' => \$opt_help,
    'host=s'   => \$opt_host,
    'dbase=s'  => \$opt_dbase,
    'user|u=s' => \$opt_user,
    'pass|p=s' => \$opt_pass,
    'table=s'  => \$opt_table,
    'name=s'   => \$opt_name,
);

my $help       = $opt_help;
my $host       = $opt_host;
my $dbase      = $opt_dbase;
my $user       = $opt_user;
my $pass       = $opt_pass;
my $table      = $opt_table;
my $field_name = $opt_name;

if ( $help || !($dbase) || !($host) || !$pass ) {
    print_help();
    leave();
}

my $dbc = new SDB::DBIO( -dbase => $dbase, -host => $host, -user => $user, -password => $pass, -connect => 1 );

my $extra_condition;
if ($table) {
    $extra_condition = " AND Field_Table = '$table' ";
}
if ($field_name) {
    $extra_condition = " AND Field_Name = '$field_name' ";
}

my @time_stamps;
my $time = timestamp();
push @time_stamps, "Start\t- $time";

my %fields;
my %field_info = $dbc->Table_retrieve(
    'DBField',
    [ 'DBField_ID', 'Field_Name', 'Field_Table', 'Field_Type', 'Field_Default' ],
    "where field_type REGEXP '^(char|varchar|tinytext|text|mediumtext|longtext)' and NULL_ok = 'YES' and Field_Options NOT like '%Removed%' and Field_Index NOT like '%UNI%' $extra_condition order by Field_Table,Field_Name"
);
my $index = 0;
while ( defined $field_info{Field_Name}[$index] ) {
    my $table      = $field_info{Field_Table}[$index];
    my $field_name = $field_info{Field_Name}[$index];
    $fields{$table}{$field_name}{type}       = $field_info{Field_Type}[$index];
    $fields{$table}{$field_name}{default}    = $field_info{Field_Default}[$index] || '';
    $fields{$table}{$field_name}{dbfield_id} = $field_info{DBField_ID}[$index];
    $index++;
}

my @errors;
foreach my $table ( sort keys %fields ) {
    my $modify_spec;
    my @field_ids;
    foreach my $field_name ( keys %{ $fields{$table} } ) {
        my $field_type    = $fields{$table}{$field_name}{type};
        my $field_default = $fields{$table}{$field_name}{default};
        push @field_ids, $fields{$table}{$field_name}{dbfield_id};
        if ($modify_spec) {
            $modify_spec .= ', ';
        }
        if ( $field_type =~ /^TEXT|BLOB$/i ) {    # BLOB/TEXT column can't have a default value
            $modify_spec .= "MODIFY $field_name $field_type NOT NULL";
        }
        else {
            $modify_spec .= "MODIFY $field_name $field_type NOT NULL DEFAULT '$field_default'";
        }
    }
    my $command = "ALTER TABLE $table $modify_spec";
    Message("$command");
    my ( $results, $newid, $feedback ) = $dbc->execute_command($command);
    Message("\t$feedback");

    if ( $feedback !~ /successfully/ ) {
        push @errors, "$command $feedback";
    }
    else {
        ## update DBField table
        my $dbfield_ids = Cast_List( -list => \@field_ids, -to => 'String' );
        my $ok = $dbc->Table_update( "DBField", "NULL_ok", "'NO'", "WHERE DBField_ID in ($dbfield_ids)" );
    }

    $time = timestamp();
    push @time_stamps, "$table\t- $time";
}

if ( int(@errors) ) {
    print "Errors:\n";
    print Dumper \@errors;
}
print "Time stamps:\n";
print Dumper \@time_stamps;

##########
sub leave {
##########
    if ($dbc) { $dbc->disconnect() }
    exit;
}

######################
sub print_help {
######################
    print <<HELP;

Update the database schema to set the string type field to be NOT NULL.

Mandatory Options:
-host           : the host name of the machine that the database resides on.
-dbase          : the name of the database.
-user|u      : the username to use.
-pass|p      : the password of the user.

Optional Flags:
-help|h|?      : display this help page
-table			: table name whose NULL ok text fields need to be updated to NOT NULL
-name			: field name that need to be updated to NOT NULL

Usage example:
set_text_field_not_null.pl -host limsdev04 -dbase seqdev -u user -p pass
set_text_field_not_null.pl -host limsdev04 -dbase seqdev -u user -p pass -table Xformed_Cell
set_text_field_not_null.pl -host limsdev04 -dbase seqdev -u user -p pass -table Xformed_Cell -name Xform_Method


HELP
}

