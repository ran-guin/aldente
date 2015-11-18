#!/usr/local/bin/perl

use strict;
use DBI;
use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../../lib/perl/"; # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../../lib/perl/Core/"; # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../../lib/perl/Imported/"; # add the local directory to the lib search path
use Getopt::Long;

use RGTools::RGIO;
use SDB::DBIO;

use vars
    qw($opt_help $opt_quiet $opt_host $opt_dbase $opt_user $opt_pwd $opt_table $opt_find $opt_replace $opt_copy);

&GetOptions(
    'help'      => \$opt_help,
    'quiet'     => \$opt_quiet,
    'dbase=s'   => \$opt_dbase,
    'host=s'    => \$opt_host,
    'user=s'    => \$opt_user,
    'pwd=s'     => \$opt_pwd,
    'table=s'   => \$opt_table,
    'find=s'    => \$opt_find,
    'replace=s' => \$opt_replace,
    'copy'      => \$opt_copy,
## 'parameter_with_value=s' => \$opt_p1,
    ## 'parameter_as_flag'      => \$opt_p2,
);

my $help  = $opt_help;
my $quiet = $opt_quiet;
my $host  = $opt_host  || 'limsdev02';
my $dbase = $opt_dbase || 'seqdev';
my $user  = $opt_user  || 'unit_tester';
my $pwd   = $opt_pwd   || 'unit_tester';
my $table   = $opt_table;
my $find    = $opt_find;
my $replace = $opt_replace;
my $copy    = $opt_copy;
my $debug ;

if ( !$table || !$find || $help ) { help(); exit; }

require SDB::DBIO;
my $dbc = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pwd,
    -connect  => 1,
);

my ($primary) = $dbc->get_field_info( $table, undef, 'Primary' );
if ($replace){
    Message("Replacing $table.$primary values: $find -> $replace.");
}
else {
    Message("Deleting $table.$primary values: $find ");
    
}


if ($copy) {
    $dbc->Table_copy(   -table     => $table,
                        -condition => "WHERE $primary = '$find'",
                        -except    => [$primary],
                        -replace   => [$replace],
                        -debug     => 1,
                        -autoquote => 1 );
}

my ($something, $details, $refs) = SDB::DBIO::get_references(
     $dbc, $table,
    -field    => $primary,
    -value    => $find,
    -indirect => 1,
    -exclude_self_reference => 1
);

my $delete_module = find_custom_deletion (-table => $table);
my $cascade = build_cascade (-refs => $refs, -table => $table);
#print Dumper $cascade;
my $confirm = print_refrences (-refs => $refs, -replace => $replace);

my $response;
if ( $confirm =~ /^y/i ) {
    if ( defined $delete_module && $response ) {
        ##########################
        ## <UNDER CONSTRUCTION> ##
        Message "Found Delete Method";
        eval "require $delete_module";
        my $object = new $delete_module( -dbc => $dbc, -id => $find );
        $object->$delete_module;
        ##########################
    }
    else {
        if ($replace){
            my $ok = $dbc->replace_records(
                -table     => $table, 
                -dfield    => $primary,
                -id_list   => $find,
                -replace   => $replace,
                -debug     => 0,
                -confirm   => 1,
                -autoquote => 1,
                -cascade   => $cascade );
            
        }
        else {
            my $ok = $dbc->delete_records(
                -table     => $table, 
                -dfield    => $primary,
                -id_list   => $find,
           #     -replace   => $replace,
                -debug     => 0,
                -confirm   => 1,
            #    -autoquote => 1,
                -cascade   => $cascade );
            
        }
    }
}
else {
    print "Aborted deletion.\n";
}

exit;


########################################################################################################
##                      Functions                                                                     ##
########################################################################################################
##########################
sub find_custom_deletion {
##########################
    my %args  = &filter_input( \@_ );
    my $table = $args{-table };
    my $module = $table;
  #  if ( $table =~ /Plate/ ) { $module = 'Container' }

    my $delete_module = 'alDente' . '::' . $module;
    my $delete_method = "Delete_$table";
    my $path = $FindBin::RealBin . "/../../lib/perl/alDente/*.pm";
    my $command  = "grep -nr 'sub Delete_$table' $path";
    Message "** CMND: $command **" if $debug;
    my $response = try_system_command("$command");
    print $response;

    return $delete_module;

}

##########################
sub build_cascade {
##########################
    my %args         = &filter_input( \@_ );
    my $refrences   = $args{-refs };
    my $table       = $args{-table };
    my @tables;
    for my $field (keys %$refrences){
        if ($field =~ /(.+)\..+/) {
            push @tables, $1;
        }
    }
    push @tables, $table;
    return \@tables;
}


##########################
sub print_refrences {
##########################
    my %args         = &filter_input( \@_ );
    my $refrences   = $args{-refs };
    my %records = %$refrences;
    
    print "\n\nReferences:\n" . "*" x 50 . "\n";
    foreach my $key ( keys %records ) {
        my $refs = int( @{ $records{$key} } );
        print "$key : $refs\n";
    }
    print "*" x 50 . "\n\n";
    my $confirm;
    
    if ($replace){
        $confirm = Prompt_Input(   -prompt => "Execute replacement ($host:$dbase) Y/N ? ",  -type   => 'char');
    }
    else {
        $confirm = Prompt_Input(   -prompt => "Execute deletion ($host:$dbase) Y/N ? ",  -type   => 'char');
    }
    return $confirm;
}

##########################
sub help {
##########################

    print <<HELP;

Usage:
*********

    delete_replace -table <table> -find <find> -replace <replace> [options]

    This may also be used to simply find references (user will be prompted to optionally abort deletion prior to exectution)

Mandatory Input:
**************************
    -table 
    -find  (primary key value)
    -replace (optional - replace previous value with this value)
    
Options:
**************************     
    -host
    -base
    -user
    -pwd
    

Examples:
***********

    delete_replace.pl -table Primer -find 110509

    delete_replace.pl -table Library -find Lib01 -replace Lib02

    delete_replace.pl -host lims05 -dbase seqtest -user aldente_admin -pwd ****** -table Library -find Lib01 -replace Lib02 
    
HELP

}
