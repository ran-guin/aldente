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
my $host        = param('Database_host');
my $dbase       = param('Database');
my $condition   = param('Condition') || 1;
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

my $dbc = SDB::DBIO->new(-host=>$host,-dbase=>$dbase,-user=>'viewer',-password=>'viewer',-connect=>1);

my @table_info= SDB::DBIO::simple_resolve_field($field);
$table ||= $table_info[0];

#my @tables =  $dbc->DB_tables();
#if (!grep(/^$table$/,@tables)) { print -1; exit;}
#
#my @fields = $dbc->get_field_list(-table=>$table);
#if (!grep(/^$field$/,@fields)) { print -1; exit; }

if ($condition) {
    $condition = MIME::Base32::decode($condition);
}

my @match;
if ((my $ref_table,my $ref_field) = &foreign_key_check($field)) {
    @match = $dbc->get_FK_info($field,-list=>1,-view_filter=>"*$value*",-condition=>$condition,-join_tables=>$join_tables,-join_condition=>$join_condition);
    #print $F "REF $ref_table, $ref_field, $field, val $value $condition\n";
    #print $F Call_Stack() ."\n";
}
else {
    @match = $dbc->Table_find($table,$field,"WHERE $field LIKE '%$value%' AND $condition");
}

print "<ul>";
foreach (sort @match) { print "<li>$_</li>"; } 

print "</ul>";

if ($debug) {
    print $F Dumper(\@match);
    close $F;
}

$dbc->disconnect();
exit;

