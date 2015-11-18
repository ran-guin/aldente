#!/usr/local/bin/perl
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Departments";

use strict;

print "Content-type: text/html\n\n";

print "GENERATE CONFIG:\n";

my $Config = LampLite::Config->new( -bootstrap => 1, -initialize=> $FindBin::RealBin . '/../conf/personalize.cfg', -debug=>1);

exit;
