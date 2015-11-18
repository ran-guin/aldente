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
use alDente::Shipment;
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




use_ok("alDente::Shipment");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Shipment", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bnew_Shipment_trigger\b/ ) {
    can_ok("alDente::Shipment", 'new_Shipment_trigger');
    {
        ## <insert tests for new_Shipment_trigger method here> ##
    }
}

if ( !$method || $method =~ /\bdefine_Shipment\b/ ) {
    can_ok("alDente::Shipment", 'define_Shipment');
    {
        ## <insert tests for define_Shipment method here> ##
    }
}

if ( !$method || $method =~ /\breceive_Shipment\b/ ) {
    can_ok("alDente::Shipment", 'receive_Shipment');
    {
        ## <insert tests for receive_Shipment method here> ##
    }
}

if ( !$method || $method =~ /\bShipment_details\b/ ) {
    can_ok("alDente::Shipment", 'Shipment_details');
    {
        ## <insert tests for Shipment_details method here> ##
    }
}

if ( !$method || $method =~ /\binitialize_Shipment\b/ ) {
    can_ok("alDente::Shipment", 'initialize_Shipment');
    {
        ## <insert tests for initialize_Shipment method here> ##
    }
}

if ( !$method || $method =~ /\bship_Object\b/ ) {
    can_ok("alDente::Shipment", 'ship_Object');
    {
        ## <insert tests for ship_Object method here> ##
    }
}

if ( !$method || $method =~ /\bmanifest_file\b/ ) {
    can_ok("alDente::Shipment", 'manifest_file');
    {
        ## <insert tests for manifest_file method here> ##
    }
}

if ( !$method || $method =~ /\bviewGet_shipment_Info\b/ ) {
    can_ok("alDente::Shipment", 'viewGet_shipment_Info');
    {
	
	my $self = new alDente::Shipment(-dbc => $dbc);
	my @src_ids = (9115);
	my $shipment_ids = $self->viewGet_shipment_Info( -dbc => $dbc, -source=> @src_ids, -debug => 1);
		
	is(@$shipment, 0);	
	
        ## <insert tests for manifest_file method here> ##
    }
}


## END of TEST ##

ok( 1 ,'Completed Shipment test');

exit;
