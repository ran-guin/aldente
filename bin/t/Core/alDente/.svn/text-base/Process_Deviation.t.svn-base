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
use alDente::Process_Deviation;
############################

############################################


use_ok("alDente::Process_Deviation");

my $self = self();

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Process_Deviation", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\blink_deviation_to_objects\b/ ) {
    can_ok("alDente::Process_Deviation", 'link_deviation_to_objects');
    {
        ## <insert tests for link_deviation_to_objects method here> ##
        my $new_ids = $self->link_deviation_to_objects( -dbc => $dbc, -deviation_no => 'PD.476', -object_class => 'Plate', -object_ids => [ '1','2' ], -user_id => '276' );
        #print Dumper $new_ids;
        ok( $new_ids, 'link_deviation_to_objects');
        ## delete the inserted records
        if( $new_ids ) {
        	my $id_list = join ',', @{$new_ids->{Process_Deviation_Object}{newids}};
        	my $ok = $dbc->delete_records(
                -table     => 'Process_Deviation_Object', 
                -dfield    => 'Process_Deviation_Object_ID',
                -id_list   => $id_list,
                -confirm   => 1
            );
        }
    }
}

if ( !$method || $method =~ /\bget_valid_deviation_object_classes\b/ ) {
    can_ok("alDente::Process_Deviation", 'get_valid_deviation_object_classes');
    {
        ## <insert tests for get_valid_deviation_object_classes method here> ##
        my @got = $self->get_valid_deviation_object_classes();
        is_deeply( \@got, ['Source', 'Plate', 'Library', 'Run'], 'get_valid_deviation_object_classes' );
    }
}

if ( !$method || $method =~ /\bget_deviation\b/ ) {
    can_ok("alDente::Process_Deviation", 'get_deviation');
    {
        ## <insert tests for get_deviation method here> ##
        my $got = alDente::Process_Deviation::get_deviation( -dbc => $dbc, -deviation_no => 'PD.476' );
        my $expected = [ 1 ];
        is_deeply( $got, $expected, 'get_deviation' );
        
    }
}

## END of TEST ##

ok( 1 ,'Completed Process_Deviation test');

exit;
