#!/usr/local/bin/perl

use strict;
use warnings;

# Add to the lib search path
use FindBin;
use lib $FindBin::RealBin . "/../../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Departments";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Imported";

use Test::More qw(no_plan);
use Test::Differences;       
use Test::Exception;         
use Test::MockModule;        

use DBD::Mock;               
use DBI;

# check that the module we're testing can be used
BEGIN {
    use_ok("UHTS::Genechip_Summary");
}
