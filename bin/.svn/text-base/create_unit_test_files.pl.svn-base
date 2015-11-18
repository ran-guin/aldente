#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################
#
# convert_stock.pl
#
# This script convert all the entries in the Stock table into the new Stock table and back fills the Stock_Catalog table.  
##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
################################################################################

use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use Data::Dumper;
use Getopt::Std;

use RGTools::RGIO;
use SDB::DBIO;
use vars qw(%Defaults);  ## std defaults (eg SOC_MEDIA_QTY)


use vars qw($opt_v $opt_c);

use Getopt::Long;
&GetOptions(
	    'v=s'      => \$opt_v,
        'c' =>\$opt_c
);

my @modules;
my @tests;
my @missing_test;
my $path = $FindBin::RealBin . "/../";
my $lib_path = $path . "lib/perl/";
my $test_path = $path . "bin/t/";
my @files = split "\n", try_system_command("ls $lib_path"."*/*.pm");

for my $file (@files){
    if ($file =~ /^$lib_path(.+)\.pm/){
        push @tests, $1;
    }
}
for my $test_file (@tests){
    my $found = try_system_command("ls $test_path"."$test_file" .".t");
    if ($found =~ /No such file/ ){
        my $temp = $test_file;
        $temp =~ s/\//\:\:/g;
        push @missing_test, $temp;
    }
}

for my $module (@missing_test){
    my $command = "setup_test.pl -module $module -path $path";
    my $result = try_system_command("$command");
    if ($result){
        Message "**CMD:  " .$command;
        Message $result;
    }
}






exit;