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
use alDente::Container_Set;
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




use_ok("alDente::Container_Set");

my $self = new alDente::Container_Set(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Container_Set", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bset_number\b/ ) {
    can_ok("alDente::Container_Set", 'set_number');
    {
        ## <insert tests for set_number method here> ##
    }
}

if ( !$method || $method=~/\breset_set_number\b/ ) {
    can_ok("alDente::Container_Set", 'reset_set_number');
    {
        ## <insert tests for reset_set_number method here> ##
    }
}

if ( !$method || $method=~/\bids\b/ ) {
    can_ok("alDente::Container_Set", 'ids');
    {
        ## <insert tests for ids method here> ##
    }
}

if ( !$method || $method=~/\bSet_home_info\b/ ) {
    can_ok("alDente::Container_Set", 'Set_home_info');
    {
        ## <insert tests for Set_home_info method here> ##
    }
}

if ( !$method || $method=~/\blabel\b/ ) {
    can_ok("alDente::Container_Set", 'label');
    {
        ## <insert tests for label method here> ##
    }
}

if ( !$method || $method=~/\bload_Info\b/ ) {
    can_ok("alDente::Container_Set", 'load_Info');
    {
        ## <insert tests for load_Info method here> ##
    }
}

if ( !$method || $method=~/\bsave_Set\b/ ) {
    can_ok("alDente::Container_Set", 'save_Set');
    {
        ## <insert tests for save_Set method here> ##
    }
}

if ( !$method || $method=~/\btransfer\b/ ) {
    can_ok("alDente::Container_Set", 'transfer');
    {
        ## <insert tests for transfer method here> ##
    }
}

if ( !$method || $method=~/\bplate_transfer_to_tube\b/ ) {
    can_ok("alDente::Container_Set", 'plate_transfer_to_tube');
    {
        ## <insert tests for plate_transfer_to_tube method here> ##
    }
}

if ( !$method || $method=~/\bcreate_tube_from_plate\b/ ) {
    can_ok("alDente::Container_Set", 'create_tube_from_plate');
    {
        ## <insert tests for create_tube_from_plate method here> ##
    }
}

if ( !$method || $method=~/\bconfirm_tube_to_plate_transfer\b/ ) {
    can_ok("alDente::Container_Set", 'confirm_tube_to_plate_transfer');
    {
        ## <insert tests for confirm_tube_to_plate_transfer method here> ##
    }
}

if ( !$method || $method=~/\btube_transfer_to_plate\b/ ) {
    can_ok("alDente::Container_Set", 'tube_transfer_to_plate');
    {
        ## <insert tests for tube_transfer_to_plate method here> ##
    }
}

if ( !$method || $method=~/\btube_transfer_to_flowcell\b/ ) {
    can_ok("alDente::Container_Set", 'tube_transfer_to_flowcell');
    {
        ## <insert tests for tube_transfer_to_flowcell method here> ##
    }
}

if ( !$method || $method=~/\bcreate_plate_from_tube\b/ ) {
    can_ok("alDente::Container_Set", 'create_plate_from_tube');
    {
        ## <insert tests for create_plate_from_tube method here> ##
    }
}

if ( !$method || $method=~/\bconfirm_create_plate_from_tube\b/ ) {
    can_ok("alDente::Container_Set", 'confirm_create_plate_from_tube');
    {
        ## <insert tests for confirm_create_plate_from_tube method here> ##
    }
}

if ( !$method || $method=~/\bpool\b/ ) {
    can_ok("alDente::Container_Set", 'pool');
    {
        ## <insert tests for pool method here> ##
    }
}

if ( !$method || $method=~/\bview_Set_ancestry\b/ ) {
    can_ok("alDente::Container_Set", 'view_Set_ancestry');
    {
        ## <insert tests for view_Set_ancestry method here> ##
    }
}

if ( !$method || $method=~/\bget_parent_sets\b/ ) {
    can_ok("alDente::Container_Set", 'get_parent_sets');
    {
        ## <insert tests for get_parent_sets method here> ##
    }
}

if ( !$method || $method=~/\bget_sister_sets\b/ ) {
    can_ok("alDente::Container_Set", 'get_sister_sets');
    {
        ## <insert tests for get_sister_sets method here> ##
    }
}

if ( !$method || $method=~/\bget_child_sets\b/ ) {
    can_ok("alDente::Container_Set", 'get_child_sets');
    {
        ## <insert tests for get_child_sets method here> ##
    }
}

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::Container_Set", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\b_recover_Set\b/ ) {
    can_ok("alDente::Container_Set", '_recover_Set');
    {
        ## <insert tests for _recover_Set method here> ##
    }
}

if ( !$method || $method=~/\b_choose_set\b/ ) {
    can_ok("alDente::Container_Set", '_choose_set');
    {
        ## <insert tests for _choose_set method here> ##
    }
}

if ( !$method || $method=~/\b_next_set\b/ ) {
    can_ok("alDente::Container_Set", '_next_set');
    {
        ## <insert tests for _next_set method here> ##
    }
}

if ( !$method || $method =~ /\b_pool_volumes\b/ ) {
    can_ok("alDente::Container_Set", '_pool_volumes');
    {
        ## <insert tests for _pool_volumes method here> ##
    }
}

if ( !$method || $method =~ /\bpool_identical_plates\b/ ) {
    can_ok("alDente::Container_Set", 'pool_identical_plates');
    {
        ## <insert tests for pool_identical_plates method here> ##
    }
}

if ( !$method || $method =~ /\brecursive_set\b/ ) {
    can_ok("alDente::Container_Set", 'recursive_set');
    {
        ## <insert tests for recursive_set method here> ##
	my $plate_ids = "246654,246655,246656,246657,246658,246659,247496,247497,247498,247499,247500,247501";
	my $recursive = 0;
	$recursive = &alDente::Container_Set::recursive_set(-dbc=>$dbc,-ids=>$plate_ids);
	ok($recursive, "recursive_set: Properly checking recursive list");

	my $plate_ids = "";
	$recursive = 1;
        $recursive = &alDente::Container_Set::recursive_set(-dbc=>$dbc,-ids=>$plate_ids);
        ok(!$recursive, "recursive_set: Empty ok");

        my $plate_ids = "246654";
	$recursive = 1;
        $recursive = &alDente::Container_Set::recursive_set(-dbc=>$dbc,-ids=>$plate_ids);
        ok(!$recursive, "recursive_set: one ok");

        my $plate_ids = "246654,246655,246656";
	$recursive = 1;
        $recursive = &alDente::Container_Set::recursive_set(-dbc=>$dbc,-ids=>$plate_ids);
        ok(!$recursive, "recursive_set: More than one ok");

        #my $plate_ids = "abc";
	#$recursive = 1;
        #$recursive = &alDente::Container_Set::recursive_set(-dbc=>$dbc,-ids=>$plate_ids);
        #ok(!$recursive, "recursive_set: Invalid plate ids ok");

        my $plate_ids = "246659,247501";
	$recursive = 0;
        $recursive = &alDente::Container_Set::recursive_set(-dbc=>$dbc,-ids=>$plate_ids);
        ok($recursive, "recursive_set: Properly checking recursive list one only");

	my $plate_ids = "246659,-5000";
	$recursive = 1;
        $recursive = &alDente::Container_Set::recursive_set(-dbc=>$dbc,-ids=>$plate_ids);
        ok(!$recursive, "recursive_set: Valid with invalid plate ids ok");

	my $plate_ids = "237846";
        $recursive = 1;
        $recursive = &alDente::Container_Set::recursive_set(-dbc=>$dbc,-ids=>$plate_ids);
        ok(!$recursive, "recursive_set: no parents rearray original plate ok");

	my $plate_ids = "173881,173882";
        $recursive = 1;
        $recursive = &alDente::Container_Set::recursive_set(-dbc=>$dbc,-ids=>$plate_ids);
        ok(!$recursive, "recursive_set: no parents original plates ok");
    }
}

## END of TEST ##

ok( 1 ,'Completed Container_Set test');

exit;
