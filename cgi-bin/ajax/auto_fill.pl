#!/usr/local/bin/perl

use strict;
use Data::Dumper;
use CGI qw(:standard);
use CGI::Carp('fatalsToBrowser');

use FindBin;
use lib $FindBin::RealBin . "/../../lib/perl";
use lib $FindBin::RealBin . "/../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../lib/perl/Imported";

use SDB::DBIO;
use SDB::CustomSettings;
use SDB::HTML;
use SDB::DB_Form;
use RGTools::RGIO;

my $q = CGI->new();

my $table       = param('Table');
my $field       = param('Field');
my $value       = param('value');
my $host        = param('Host');
my $dbase       = param('Database');
my $condition   = param('Condition');
my $join_tables = param('Join_Tables');
my $join_condition = param('Join_Condition');

my $debug = 0;
my $F;
if ($debug) {
    open $F, ">>params.txt";
    print $F "x"x30 . "\n";
    foreach (param()) {
        if ($_ eq 'Condition') {
            print $F $_ . ":\t" . MIME::Base32::decode(param($_)) . "\n";
        } else {
            print $F $_ . ":\t" . param($_) . "\n";
        }
    }
}

use vars qw($session_id);
$session_id     = param('Session');

print $q->header(-type=>'text/html');

my $dbc = SDB::DBIO->new(-host=>$host,-dbase=>$dbase,-user=>'viewer',-connect=>1);

my @table_info= SDB::DBIO::simple_resolve_field($field);
$table ||= $table_info[0];


if ($condition) {
    $condition = MIME::Base32::decode($condition);
}
else {
    $condition = '1';
}

if ($join_condition) {
    $join_condition = MIME::Base32::decode($join_condition);
}
else {
    $join_condition = '1';
}


my $filter;

if ( $value =~ /^[\w-]+(\s+[\w-]+)*$/ ) {
     $filter = "*$value*";
 }
else {
     $filter = $value;
}

my @match;
if ((my $ref_table,my $ref_field) = &foreign_key_check($field)) {
    @match = $dbc->get_FK_info($field, -list => 1, -view_filter=>$filter,-condition=>$condition,-join_tables=>$join_tables,-join_condition=>$join_condition);
}
else {
    $filter =~ s/\*/\%/g;
    @match = $dbc->Table_find($table.",".$join_tables,$field,"WHERE $field LIKE '$filter' AND $condition AND $join_condition", -distinct => 1);
}

print join ',', sort @match;

if ($debug) {
    print $F Dumper(\@match);
    close $F;
}


$dbc->disconnect();
exit;

