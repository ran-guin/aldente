#!/usr/bin/perl
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
use alDente::Shipment_App;
############################

############################################


use_ok("alDente::Shipment_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Shipment_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Shipment_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\blist_Shipments\b/ ) {
    can_ok("alDente::Shipment_App", 'list_Shipments');
    {
        ## <insert tests for list_Shipments method here> ##
    }
}

if ( !$method || $method =~ /\blink_Sources\b/ ) {
    can_ok("alDente::Shipment_App", 'link_Sources');
    {
        ## <insert tests for link_Sources method here> ##
    }
}

if ( !$method || $method =~ /\bupload_Template\b/ ) {
    can_ok("alDente::Shipment_App", 'upload_Template');
    {
        ## <insert tests for upload_Template method here> ##
    }
}

if ( !$method || $method =~ /\bship_Samples\b/ ) {
    can_ok("alDente::Shipment_App", 'ship_Samples');
    {
        ## <insert tests for ship_Samples method here> ##
    }
}

if ( !$method || $method =~ /\breceive_Shipment\b/ ) {
    can_ok("alDente::Shipment_App", 'receive_Shipment');
    {
        ## <insert tests for receive_Shipment method here> ##
    }
}

if ( !$method || $method =~ /\breceive_Samples\b/ ) {
    can_ok("alDente::Shipment_App", 'receive_Samples');
    {
        ## <insert tests for receive_Samples method here> ##
    }
}

if ( !$method || $method =~ /\breceive_Equipment\b/ ) {
    can_ok("alDente::Shipment_App", 'receive_Equipment');
    {
        ## <insert tests for receive_Equipment method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Shipment_App test');

exit;
