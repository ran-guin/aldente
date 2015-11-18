#!/usr/local/bin/perl

use strict;
use Data::Dumper;
use CGI qw(:standard);
use CGI::Carp('fatalsToBrowser');

use FindBin;
use lib $FindBin::RealBin . "/../../lib/perl";
use lib $FindBin::RealBin . "/../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../lib/perl/Departments";

use SDB::DBIO;
use SDB::CustomSettings;

use RGTools::RGIO;
use LampLite::Config;
#use alDente::Config;

use Healthbank::Config;

## Globals ##
my $q               = new CGI;
my $BS              = new Bootstrap();
######################################
######## Setup Options ###############
######################################
my ($track_sessions, $database_connection, $login_required) = (1, 1, 1);        

$| = 1;
my $path = "./..";

####################################################################################################
###  Configuration Loading - use this block (and section above) for both bin and cgi-bin files   ###
####################################################################################################
my $file = param('Custom') || 'custom';
my $Config = LampLite::Config->new( -bootstrap => 1, -initialize=> $FindBin::RealBin . "/../../conf/$file.cfg");
my $configs = $Config->{config};  ## connection relevant configs ##

my $custom = $configs->{custom_version_name} || 'Core';
my $DB = $custom . '::DB';

eval "require $DB";

######################
## Generate Configs ##
######################


my $table           = param('Table');
my $field           = param('Field');
my $reference_field = param('Reference_Field');                    # || $field; # comment out defaulting to $field here, since Reference_Field need to be encoded
my $value           = param('Element_Value') || param('Filter');                      ## dynamically populated value of form element (set in SDB.js: dependentFilter) ##
my $host            = param('Host') || $configs->{'SQL_HOST'};
my $dbase           = param('Database') || $configs->{'DATABASE'};
my $condition       = param('Condition') || 1;
my $join_tables     = param('Join_Tables');
my $join_condition  = param('Join_Condition');
my $filter_type     = param('Filter_Type');
my $global_search   = param('Global_Search');                      ## look for string anywhere in target field (eg like '%value%')
my $left_search     = param('Left_Search');                        ## look for field starting with string (still fast) (eg like 'value%')
my $autocomplete    = param('Autocomplete');                       ## Autocomplete mode allows search for EITHER Name or ID
my $debug           = param('Debug');

my $F;
if ($debug) {
    open $F, ">>params.txt";
    print $F "x" x 30 . "\n";
    foreach ( param() ) {
        if ( $_ eq 'Condition' ) {
            print $F $_ . ":\t" . MIME::Base32::decode( param($_) ) . "\n";
        }
        else {
            print $F $_ . ":\t" . param($_) . "\n";
        }
    }
}

print $q->header( -type => 'text/html' );

my $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => 'internal', -connect => 1, -config=>$configs, -login_file=>$login_file);

my @table_info = SDB::DBIO::simple_resolve_field($field);
$table ||= $table_info[0];    ## default to Table if field supplied is unambiguous (eg Table.Field)

if ( $condition && $condition =~ /^WHERE (.+)$/i ) {
    $condition = $1;
}
else {
    $condition = MIME::Base32::decode($condition);
}

if ($join_condition) {
    $join_condition = MIME::Base32::decode($join_condition);
}

if ($reference_field) {
    $reference_field = MIME::Base32::decode($reference_field);
}
else {
    $reference_field = $field;
}

my $filter;

#if ( $value =~ /^[\w-]+(\s+[\w-]+)*$/ ) {
if ($global_search) {
    $filter = "*$value*";
}
elsif ($left_search) {
    ## much faster than global search, but not necessarily exact ##
    $filter = "$value*";
}
else {
    $filter = $value;
}

my @match;

$condition      ||= 1;
$join_condition ||= 1;

$filter =~ s/\*/\%/g;

my $filter_condition = "$reference_field LIKE '$filter'";
if ( $filter =~ /[\|\n]/ ) {
    my @options = split /[\|\n]/, $filter;
    my @filter_options;
    foreach my $option (@options) {
        push @filter_options, "$reference_field LIKE '$option'";
    }
    $filter_condition = join ' OR ', @filter_options;
    $filter_condition = "($filter_condition)";
}

if (!$field) { 
    print "No field in query ... aborting...\n"; 
    exit; 
}

if ( ( my $ref_table, my $ref_field ) = $dbc->foreign_key_check($field) ) {
    my $view_filter;    ## flag to allow searching by EITHER Name or ID (used for autocomplete)

    ### custom exception for Cell_Line samples (allow for ANY Tissue or Pathology in this case ###
    if ( ( $reference_field =~ /Anatomic_Site_Type/ ) && ( $filter eq 'Cell_Line' ) ) { }
    elsif ($autocomplete) { $view_filter = $filter }
    else                  { $condition .= " AND $filter_condition" }

    @match = $dbc->get_FK_info( $field, -list => 1, -view_filter => $view_filter, -condition => $condition, -join_tables => $join_tables, -join_condition => $join_condition );
}
else {
    if ($join_tables) { $table .= ',' . $join_tables }
    @match = $dbc->Table_find_array( $table, [$field], "WHERE $filter_condition AND $condition AND $join_condition", -distinct => 1, -debug => $debug );
}

print join ',', sort @match;

if ($debug) {
    print $F Dumper( \@match );
    close $F;
}

$dbc->disconnect();
exit;

