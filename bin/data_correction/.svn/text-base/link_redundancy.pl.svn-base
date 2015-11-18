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

use vars qw($opt_help $opt_quiet $opt_host $opt_dbase $opt_user $opt_pwd $opt_table $opt_field $opt_join $opt_map);

&GetOptions(
    'help'    => \$opt_help,
    'quiet'   => \$opt_quiet,
    'dbase=s' => \$opt_dbase,
    'host=s'  => \$opt_host,
    'user=s'  => \$opt_user,
    'pwd=s'   => \$opt_pwd,
    'table=s' => \$opt_table,
    'field=s' => \$opt_field,
    'join=s'  => \$opt_join,
    'map=s'   => \$opt_map,
);

my $help  = $opt_help;
my $quiet = $opt_quiet;
my $host  = $opt_host || 'lims05';
my $dbase = $opt_dbase || 'seqtest';
my $user  = $opt_user || 'unit_tester';
my $pwd   = $opt_pwd || 'unit_tester';
my $table = $opt_table;
my $field = $opt_field;
my $join  = $opt_join;
my $map   = $opt_map;

my $debug;

if ( !$table || !$field || !$join || $help ) { help(); exit; }

require SDB::DBIO;
my $dbc = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pwd,
    -connect  => 1,
);

my $mapping;
if ($map) { $mapping = eval $map; }

# parse tables, it should have at least two tables separately by comma, the first one is primary
# e.g. Original_Source,Patient
my @tables = Cast_List( -list => $table, -to => 'array' );

# parse fields, order corresponds to that for tables
# e.g. Sex,Patient_Sex
my @fields = Cast_List( -list => $field, -to => 'array' );

my $same_field;
if ( @fields[0] eq @fields[1] ) { $same_field = 'true'; }

# parse link (join field), order corresponds to that for tables
# e.g. FK_Patient__ID,Patient_ID
my @joins = Cast_List( -list => $join, -to => 'array' );

# get primary field for each table
my ($primary0) = $dbc->get_field_info( @tables[0], undef, 'Primary' );
my ($primary1) = $dbc->get_field_info( @tables[1], undef, 'Primary' );

# get records from db where sharing the join field but having different values in fields
my %info;
my %info1;

if ($same_field) {
    %info  = &Table_retrieve( $dbc, $table, [ "$primary0", "$primary1", "@tables[0].@fields[0]" ], "where @joins[0] = @joins[1] and @tables[0].@fields[0] != @tables[1].@fields[1]" );
    %info1 = &Table_retrieve( $dbc, $table, [ "$primary0", "$primary1", "@tables[1].@fields[1]" ], "where @joins[0] = @joins[1] and @tables[0].@fields[0] != @tables[1].@fields[1]" );
}
else { %info = &Table_retrieve( $dbc, $table, [ "$primary0", "$primary1", "@tables[0].@fields[0]", "@tables[1].@fields[1]" ], "where @joins[0] = @joins[1] and @tables[0].@fields[0] != @tables[1].@fields[1]" ); }

# for each conflict, upload value from primary table to secondary if primary value exists
# else upload secondary value (if exists) to primary table
if ( exists $info{$primary0}[0] ) {
    my @primary_id0 = @{ $info{$primary0} };
    my @primary_id1 = @{ $info{$primary1} };
    my @value0      = @{ $info{ @fields[0] } };
    my @value1;
    if   ($same_field) { @value1 = @{ $info1{ @fields[1] } }; }
    else               { @value1 = @{ $info{ @fields[1] } }; }
    my $t;
    my $f;
    my $v;
    my $condition;

    for ( my $i = 0; $i < scalar(@primary_id0); $i++ ) {
        if ( @value0[$i] ) {
            $v = '';
            if ($map) {
                if ( @value0[$i] ne @value1[$i] ) {
                    if ( $mapping->{ @value0[$i] } ) {
                        if ( $mapping->{ @value0[$i] } ne @value1[$i] ) {
                            $v = $mapping->{ @value0[$i] };
                        }
                    }
                    else {
                        print "\n@value0[$i] not in the map provided\n";
                    }
                }
            }
            else { $v = @value0[$i]; }

            #upload primary value to secondary table
            $t         = @tables[1];
            $f         = @fields[1];
            $condition = "$primary1 = @primary_id1[$i]";
        }
        elsif ( @value1[$i] ) {

            #upload secondary value to primary table
            $t         = @tables[0];
            $f         = @fields[0];
            $v         = @value1[$i];
            $condition = "$primary0 = @primary_id0[$i]";
        }
        if ($v) {
            print "\nUpdating table $t in $f field with the value $v and condition $condition\n";
            my $result = $dbc->Table_update_array( -table => $t, -fields => [$f], -values => [$v], -condition => "WHERE $condition", -autoquote => 1 );
        }
    }
}

##########################
sub help {
##########################

    print <<HELP;

Usage:
*********

    link_redundancy.pl -table <table> -field <field> -join <join> [options]
    
    To link fields where mapping is required e.g. Sex vs Patient_Sex, -map IS required (see example).


Mandatory Input:
**************************
    -table  
    -field (fields to be linked)
    -join (primary keys)
    
Options:
**************************     
    -host
    -base
    -user
    -pwd
    

Examples:
***********

    link_redundancy.pl -table 'Original_Source,Patient' -field 'Sex,Patient_Sex' -join 'FK_Patient__ID,Patient_ID' -map "{'Male'=>'M','Female'=>'F','M'=>'M','F'=>'F'}"

    link_redundancy.pl -host lims05 -dbase seqtest -user aldente_admin -pwd ****** -table 'Original_Source,Patient' -field 'Sex,Patient_Sex' -join 'FK_Patient__ID,Patient_ID' -map "{'Male'=>'M','Female'=>'F','M'=>'M','F'=>'F'}"
    
HELP

}
