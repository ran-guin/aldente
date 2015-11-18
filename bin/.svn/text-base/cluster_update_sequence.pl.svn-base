#!/usr/local/bin/perl

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use alDente::SDB_Defaults;
use Data::Dumper;
use SDB::CustomSettings;
use RGTools::RGIO;
use Getopt::Std;

our ($opt_A);

&getopts("A:");

my $phred_dir = "/home/pubseq/BioSw/phred/020425/phred";

my $jobstr = &try_system_command("qstat");
if ($jobstr =~ /LIMSphred/i) {
    print "Update_sequence is already running on the cluster...";
    exit;
}

`qsub cluster_update_sequence.sh '$opt_A -P $phred_dir'`;  



