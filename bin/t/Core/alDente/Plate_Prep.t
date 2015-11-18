#!/usr/local/bin/perl
## ./template/unit_test_template.txt ##
#####################################
#
# Standard Template for unit testing
#
#####################################

### Template 4.1 ###

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use Test::Differences;
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 
my $dbc;                                 ## only used for modules enabling database connections

############################
use alDente::Plate_Prep;
############################

############################################


## ./template/unit_test_dbc.txt ##
use alDente::Config;
my $Setup = new alDente::Config(-initialize=>1, -root => $FindBin::RealBin . '/../../../../');
my $configs = $Setup->{configs};

my $host   = $configs->{UNIT_TEST_HOST};
my $dbase  = $configs->{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';

print "CONNECT TO $host:$dbase as $user...\n";

require SDB::DBIO;
$dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -connect  => 1,
                        -configs  => $configs,
                        );




use_ok("alDente::Plate_Prep");

my $self = new alDente::Plate_Prep(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Plate_Prep", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bget_Prep_history\b/ ) {
    can_ok("alDente::Plate_Prep", 'get_Prep_history');
    {
        ## <insert tests for get_Prep_history method here> ##
    }
}

if ( !$method || $method=~/\bview_History\b/ ) {
    can_ok("alDente::Plate_Prep", 'view_History');
    {
        ## <insert tests for view_History method here> ##
    }
}

if ( !$method || $method=~/\bplate_prep_insert_trigger\b/ ) {
    can_ok("alDente::Plate_Prep", 'plate_prep_insert_trigger');
    {
        ## <insert tests for plate_prep_insert_trigger method here> ##
    }
}

if ( !$method || $method=~/\b_get_branch\b/ ) {
    can_ok("alDente::Plate_Prep", '_get_branch');
    {

        # Plates: 
        # +----------+-----------------+-----------------+
        # | Plate_ID | FK_Pipeline__ID | FK_Branch__Code |
        # +----------+-----------------+-----------------+
        # |        4 |               2 |                 |
        # |      481 |               2 | B21             |
        # |   133469 |               2 | CSQW            |
        # |   133734 |             109 | C21             |
        # |   138921 |             109 |                 |
        # |   138039 |             109 | hfpol           |
        # |   135594 |               0 |                 |
        # +----------+-----------------+-----------------+
        #
        # Primers/Enzymes: 
        # +-------------+---------------------------+-------------+-----------------------+-----------------+
        # | Solution_ID | Enzyme_Name               | Branch_Code | FKParent_Branch__Code | FK_Pipeline__ID |
        # +-------------+---------------------------+-------------+-----------------------+-----------------+
        # |        5690 | EcoRI                     | EcoRI       |                       |            NULL |
        # |       14654 | Phusion HF DNA Polymerase | hfpol       |                       |             109 |
        # |       29344 | iProof Polymerase         | ipol        |                       |             109 |
        # +-------------+---------------------------+-------------+-----------------------+-----------------+
        #    
        # +-------------+-------------------+-------------+-----------------------+-----------------+
        # | Solution_ID | Primer_Name       | Branch_Code | FKParent_Branch__Code | FK_Pipeline__ID |
        # +-------------+-------------------+-------------+-----------------------+-----------------+
        # |         193 | -21 M13 Forward   | B21         |                       |               0 |
        # |         727 | Poly T plus       | TB          |                       |               0 |
        # |       16355 | M13 Reverse 100uM | CR          |                       |               0 |
        # |       58683 | Seq W 100uM       | CSQW        | CSQW                  |            NULL |
        # +-------------+-------------------+-------------+-----------------------+-----------------+
        #

        ### Pipeline testings...
        
        my $branch = &alDente::Plate_Prep::_get_branch($dbc,135594,14654);
        is($branch,0,'2) Retrieved proper branch when plate had no pipeline and branch had pipeline'); 

        my $branch = &alDente::Plate_Prep::_get_branch($dbc,4,193);
        is($branch,'B21','3) Retrieved proper branch when plate had pipeline and branch had no pipeline'); 

        my $branch = &alDente::Plate_Prep::_get_branch($dbc,138921,14654);
        is($branch,'hfpol','4) Retrieved proper branch when plate had pipeline and branch had proper pipeline'); 

        my $branch = &alDente::Plate_Prep::_get_branch($dbc,4,14654);
        is($branch,0,'5) Retrieved proper branch when plate had pipeline and branch had improper pipeline'); 

        ### Branch hierarchy testings...
        my $branch = &alDente::Plate_Prep::_get_branch($dbc,481,727);
        is($branch,-1,'6) Failed when setting a branch on a plate which already had a branch set'); 

        my $branch = &alDente::Plate_Prep::_get_branch($dbc,481,193);
        is($branch,-1,'7) Failed when setting a branch on a plate which already had that branch set'); 

        my $branch = &alDente::Plate_Prep::_get_branch($dbc,4,58683);
        is($branch,-1,'10) Failed when setting a branch on a plate which required a parent branch but did not have'); 

        my $branch = &alDente::Plate_Prep::_get_branch($dbc,4,10053);
        is($branch,0,'11) No Branch is necessary for this solution'); 

        my $branch = &alDente::Plate_Prep::_get_branch($dbc,135594,65096);
        is($branch,0,'13) Worked!');

        my $branch = &alDente::Plate_Prep::_get_branch($dbc,4,68446);
        is($branch,'CNRC','2) Retrieved proper branch when plate had no pipeline and branch had pipeline'); 

#        my $branch = &alDente::Plate_Prep::_get_branch($dbc,160462,68446);
#        is($branch,'EIV','1) Retrieved proper double digest branch branch when plate had no pipeline and branch had no pipeline'); 
    }
}

## END of TEST ##

ok( 1 ,'Completed Plate_Prep test');

exit;

