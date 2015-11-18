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
use alDente::Shipment_Views;
############################

############################################


use_ok("alDente::Shipment_Views");

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Shipment_Views", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Shipments\b/ ) {
    can_ok("alDente::Shipment_Views", 'display_Shipments');
    {
        ## <insert tests for display_Shipments method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_import_Shipments\b/ ) {
    can_ok("alDente::Shipment_Views", 'display_import_Shipments');
    {
        ## <insert tests for display_import_Shipments method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_export_Shipments\b/ ) {
    can_ok("alDente::Shipment_Views", 'display_export_Shipments');
    {
        ## <insert tests for display_export_Shipments method here> ##
    }
}

if ( !$method || $method =~ /\bimport_Shipment\b/ ) {
    can_ok("alDente::Shipment_Views", 'import_Shipment');
    {
        ## <insert tests for import_Shipment method here> ##
    }
}

if ( !$method || $method =~ /\breceive_Samples\b/ ) {
    can_ok("alDente::Shipment_Views", 'receive_Samples');
    {
        ## <insert tests for receive_Samples method here> ##
    }
}

if ( !$method || $method =~ /\bget_shipment_logs\b/ ) {
    can_ok("alDente::Shipment_Views", 'get_shipment_logs');
    {
        ## <insert tests for get_shipment_logs method here> ##
    }
}

if ( !$method || $method =~ /\blist_page\b/ ) {
    can_ok("alDente::Shipment_Views", 'list_page');
    {
        ## <insert tests for list_page method here> ##
    }
}

if ( !$method || $method =~ /\bupload_new_sources_view\b/ ) {
    can_ok("alDente::Shipment_Views", 'upload_new_sources_view');
    {
        ## <insert tests for upload_new_sources_view method here> ##
    }
}

if ( !$method || $method =~ /\bmove_Rack_page\b/ ) {
    can_ok("alDente::Shipment_Views", 'move_Rack_page');
    {
        ## <insert tests for move_Rack_page method here> ##
    }
}

if ( !$method || $method =~ /\bShipment_prompt\b/ ) {
    can_ok("alDente::Shipment_Views", 'Shipment_prompt');
    {
        ## <insert tests for Shipment_prompt method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Shipment_Views test');

exit;
