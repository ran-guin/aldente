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
use alDente::Primer;
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




use_ok("alDente::Primer");

my $self = new alDente::Primer(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Primer", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bview_primer_plate\b/ ) {
    can_ok("alDente::Primer", 'view_primer_plate');
    {
        ## <insert tests for view_primer_plate method here> ##
    }
}

if ( !$method || $method=~/\bview_primer_plates\b/ ) {
    can_ok("alDente::Primer", 'view_primer_plates');
    {
        ## <insert tests for view_primer_plates method here> ##
    }
}

if ( !$method || $method=~/\bmark_plates_as_ordered\b/ ) {
    can_ok("alDente::Primer", 'mark_plates_as_ordered');
    {
        ## <insert tests for mark_plates_as_ordered method here> ##
    }
}

if ( !$method || $method=~/\bcopy_primer_plate\b/ ) {
    can_ok("alDente::Primer", 'copy_primer_plate');
    {
        ## <insert tests for copy_primer_plate method here> ##
    }
}

if ( !$method || $method=~/\bremap_primer_plate\b/ ) {
    can_ok("alDente::Primer", 'remap_primer_plate');
    {
        ## <insert tests for remap_primer_plate method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_solution_id\b/ ) {
    can_ok("alDente::Primer", 'generate_solution_id');
    {
        ## <insert tests for generate_solution_id method here> ##
    }
}

if ( !$method || $method=~/\bcreate_primer_plate\b/ ) {
    can_ok("alDente::Primer", 'create_primer_plate');
    {
        ## <insert tests for create_primer_plate method here> ##
    }
}

if ( !$method || $method=~/\bset_new_primers\b/ ) {
    can_ok("alDente::Primer", 'set_new_primers');
    {
        ## <insert tests for set_new_primers method here> ##
    }
}

if ( !$method || $method=~/\bset_notes\b/ ) {
    can_ok("alDente::Primer", 'set_notes');
    {
        ## <insert tests for set_notes method here> ##
    }
}

if ( !$method || $method=~/\blist_Primers\b/ ) {
    can_ok("alDente::Primer", 'list_Primers');
    {
        ## <insert tests for list_Primers method here> ##
    }
}

if ( !$method || $method=~/\bsuggest_Primer\b/ ) {
    can_ok("alDente::Primer", 'suggest_Primer');
    {
        ## <insert tests for suggest_Primer method here> ##
    }
}

if ( !$method || $method=~/\bvalidate_Primer\b/ ) {
    can_ok("alDente::Primer", 'validate_Primer');
    {
        ## <insert tests for validate_Primer method here> ##
    }
}

if ( !$method || $method=~/\bnew_Chem_Code\b/ ) {
    can_ok("alDente::Primer", 'new_Chem_Code');
    {
        ## <insert tests for new_Chem_Code method here> ##
    }
}

if ( !$method || $method=~/\b_calc_temp_MGC_Standard\b/ ) {
    can_ok("alDente::Primer", '_calc_temp_MGC_Standard');
    {
        ## <insert tests for _calc_temp_MGC_Standard method here> ##
    }
}

if ( !$method || $method=~/\b_set_new_primer\b/ ) {
    can_ok("alDente::Primer", '_set_new_primer');
    {
        ## <insert tests for _set_new_primer method here> ##
    }
}

if ( !$method || $method=~/\breceive_primer_plate_as_tubes\b/ ) {
    can_ok("alDente::Primer", 'receive_primer_plate_as_tubes');
    {
        ## <insert tests for receive_primer_plate_as_tubes method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Primer test');

exit;
