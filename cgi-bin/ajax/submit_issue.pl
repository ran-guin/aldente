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
use RGTools::RGIO;

#my $Connection = SDB::DBIO->new(-host=>'lims-dbm',-dbase=>'seqdev',-user=>'rsanaie',-password=>'rezapwd',-connect=>0);

#my $dbh = $Connection->connect();
#$dbh->disconnect();

my $notes       = param('Error_Notes');

my %originals;
my %params = ('Issue.Issue_ID' =>    'new',
           'Issue.Type'=>         'Reported',     ## default to reported so that we can classify later
           'Issue.Description'=>  $notes, 
           'Issue.Priority'=>     'High',
           'Issue.Severity'=>     'Major',
           'Issue.Status'=>       'Reported',
           'Issue.Found_Release'=>                 2,
           'Issue.Assigned_Release'=>              2,
           'Issue.FKSubmitted_Employee__ID'=>      5,
           'Issue.FKAssigned_Employee__ID'=>       141, #Default assigned to Admin
  );

my $q = CGI->new();
print $q->header(-type=>'text/plain');
print  <<EOF;
LIMS-253: [Notes: $notes]

EOF

exit;

