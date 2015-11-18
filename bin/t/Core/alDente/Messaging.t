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
use alDente::Messaging;
############################

############################################


use_ok("alDente::Messaging");

my $self = new alDente::Messaging(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Messaging", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\badd_message\b/ ) {
    can_ok("alDente::Messaging", 'add_message');
    {
        ## <insert tests for add_message method here> ##
    }
}

if ( !$method || $method=~/\bremove_message\b/ ) {
    can_ok("alDente::Messaging", 'remove_message');
    {
        ## <insert tests for remove_message method here> ##
    }
}

if ( !$method || $method=~/\bget_messages\b/ ) {
    can_ok("alDente::Messaging", 'get_messages');
    {
        ## <insert tests for get_messages method here> ##
    }
}

if ( !$method || $method=~/\bshow_removal_window\b/ ) {
    can_ok("alDente::Messaging", 'show_removal_window');
    {
        ## <insert tests for show_removal_window method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Messaging test');

exit;
