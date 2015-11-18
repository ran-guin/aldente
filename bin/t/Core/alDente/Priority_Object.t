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
use alDente::Priority_Object;
############################

############################################


use_ok("alDente::Priority_Object");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Priority_Object", 'new');
    {
    	my $self = new alDente::Priority_Object( -dbc => $dbc );
    	ok( $self, 'New Priority_Object' );
    }
}

if ( !$method || $method =~ /\bset_priority\b/ ) {
    can_ok("alDente::Priority_Object", 'set_priority');
    {
    	my $self = new alDente::Priority_Object( -dbc => $dbc );
    	my ( $plate ) = $dbc->Table_find( 'Plate', 'Plate_ID', "where Plate_ID NOT in (select Object_ID from Priority_Object,Object_Class where FK_Object_Class__ID = Object_Class_ID and Object_Class = 'Plate') limit 1" );
    	my $result = $self->set_priority( -priority => '4 High', -object_class => 'Plate', -object_id => $plate );
    	ok( $result, 'set_priority' );
    }
}

if ( !$method || $method =~ /\bupdate_priority\b/ ) {
    can_ok("alDente::Priority_Object", 'update_priority');
    {
    	my $self = new alDente::Priority_Object( -dbc => $dbc );
    	my $plate;
    	my $result;

    	( $plate ) = $dbc->Table_find( 'Priority_Object,Object_Class', 'Object_ID', "where FK_Object_Class__ID = Object_Class_ID and Object_Class = 'Plate' limit 1" );
    	$result = $self->update_priority( -priority => '4 High', -object_class => 'Plate', -object_id => $plate, -override => 0 );
    	ok( !$result, 'update_priority with override flag off' );
    	
    	$result = $self->update_priority( -priority => '4 High', -object_class => 'Plate', -object_id => $plate, -override => 1 );
    	ok( $result, 'update_priority with override flag on' );
    	
    	( $plate ) = $dbc->Table_find( 'Plate', 'Plate_ID', "where Plate_Status = 'Active' and Plate_ID NOT in (select Object_ID from Priority_Object,Object_Class where FK_Object_Class__ID = Object_Class_ID and Object_Class = 'Plate') limit 1" );
    	$result = $self->update_priority( -priority => '4 High', -object_class => 'Plate', -object_id => $plate, -override => 1 );
    	ok( !$result, 'update_priority for non-existing Priority_Object record' );
    }
}

if ( !$method || $method =~ /\bget_priority\b/ ) {
    can_ok("alDente::Priority_Object", 'get_priority');
    {
    }
}

if ( !$method || $method =~ /\bget_valid_priorities\b/ ) {
    can_ok("alDente::Priority_Object", 'get_valid_priorities');
    {
    	my $self = new alDente::Priority_Object( -dbc => $dbc );
		my @result = $self->get_valid_priorities();
		my @expected = ( '5 Highest','4 High','3 Medium','2 Low','1 Lowest', '0 Off' );
		is_deeply( \@result, \@expected, 'get_valid_priorities');    	
    }
}



## END of TEST ##

ok( 1 ,'Completed Priority_Object test');

exit;
