#!/usr/local/bin/perl

use strict;
use Data::Dumper;
use Getopt::Std;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use RGTools::RGIO;
use SDB::CustomSettings;
use alDente::SDB_Defaults;
use strict;

my $mod = 'alDente';
my @list = `ls /home/jsantos/svnsource/lib/perl/$mod/*.pm`;

foreach my $file (@list) {
    $file =~/(.*)\/(.+)/;
    my $name = $2;

    my $path = $1;
    my $diff = `diff $1/$2 /opt/alDente/versions/mariol/lib/perl/$mod/$name`;
 print "diff $1/$2 /opt/alDente/versions/mariol/lib/perl/$mod/$name\n";
    print "$name\n*******\n$diff\n" if $diff=~/\w/;
} 
print "found ".int(@list)."\n";

