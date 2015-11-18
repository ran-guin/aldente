#!/usr/local/bin/perl

use strict;
use Data::Dumper;
use CGI qw(:standard -debug);
use CGI::Carp('fatalsToBrowser');

use FindBin;
use lib $FindBin::RealBin . "/../../lib/perl";
use lib $FindBin::RealBin . "/../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../lib/perl/Imported";
use JSON;

use SDB::DBIO;
use SDB::CustomSettings;
use SDB::HTML;
use SDB::DB_Form;
use RGTools::RGIO;

my $q = CGI->new();

my $table       = param('Table');
my $field       = param('Field');
my $value       = param('Value');
my $host        = param('Database_host');
my $dbase       = param('Database');

use vars qw($session_id);
$session_id     = param('Session');

print $q->header(-type=>'text/plain');

my $dbc = SDB::DBIO->new(-host=>$host,-dbase=>$dbase,-user=>'viewer',-password=>'viewer',-connect=>1);

my @tables =  $dbc->DB_tables();
if (!grep(/^$table$/,@tables)) { print -1; exit;}

my @fields = $dbc->get_field_list(-table=>$table);
if (!grep(/^$field$/,@fields)) { print -1; exit; }

if(!$value) { print -1; exit; }

my ($existing) = $dbc->Table_find($table,$field,"WHERE $field='$value'");

print $existing ? 1 : 0;

$dbc->disconnect();
exit;

