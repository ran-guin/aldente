#!/usr/local/bin/perl56

################################################################################
#
# header.pl
#
# This is only meant to be a header for running upgrade scripts

# an upgrade script will be appended as well as a following footer.pl file prior to execution.
#
################################################################################

use strict;
no strict "refs";
use Getopt::Std;
use Storable;
use Data::Dumper;
use DBI;

use FindBin;
use lib $FindBin::RealBin . "/../../../lib/perl/";
use lib $FindBin::RealBin . "/../../../lib/perl/Core";

use SDB::DBIO;
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::Conversion;
use SDB::DB_Object;
use alDente::SDB_Defaults;

getopts('D:u:p:PA:r:T:h:v:c:C:b:B:N:L:');
use vars qw($opt_D $opt_u $opt_p $opt_P $opt_A $opt_r $opt_T $opt_h $opt_c $opt_C $opt_v $opt_b $opt_B $opt_N $opt_L);

my $dbh;
my $Dbase = $opt_D;
my $user = $opt_u;
my $password = $opt_p;
my $host = $opt_h;
my @include_blocks; 
my @exclude_blocks;

if ($opt_b) {@include_blocks = split /,/, $opt_b}
if ($opt_B) {@exclude_blocks = split /,/, $opt_B}

my $Release;

use vars qw(%Primary_fields %Mandatory_fields %Field_Info $testing $upgrade_dir);

$upgrade_dir = "$install_dir/upgrade";

my $dbc = SDB::DBIO->new(-host=>$host,-dbase=>$Dbase,-user=>$user,-password=>$password,-connect=>1);
