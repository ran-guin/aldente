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
use alDente::Plate_Schedule;
############################

############################################


use_ok("alDente::Plate_Schedule");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Plate_Schedule", 'new');
    {
        ## <insert tests for new method here> ##
        $self = alDente::Plate_Schedule->new(-dbc=>$dbc);  
    }
}
if ( !$method || $method=~/\badd_plate_schedule\b/ ) {
    can_ok("alDente::Plate_Schedule", 'add_plate_schedule');
    {
        my $schedule = $self->add_plate_schedule(-plate_id=>176413,-pipeline_id=>[25,26]);
        print Dumper $schedule;
    }
}
if ( !$method || $method=~/\bget_plate_schedule\b/ ) {
    can_ok("alDente::Plate_Schedule", 'get_plate_schedule');
    {   
        $dbc->Table_append_array('Plate_Schedule',['FK_Plate__ID','FK_Pipeline__ID','Plate_Schedule_Priority'],[5000,1,1]); 
        $dbc->Table_append_array('Plate_Schedule',['FK_Plate__ID','FK_Pipeline__ID','Plate_Schedule_Priority'],[5000,2,2]);
        my $schedule = $self->get_plate_schedule(-plate_id=>5000);
    }
}

if ( !$method || $method =~ /\bupdate_plate_schedule\b/ ) {
    can_ok("alDente::Plate_Schedule", 'update_plate_schedule');
    {
        ## <insert tests for update_plate_schedule method here> ##
    }
}

if ( !$method || $method =~ /\bdelete_plate_schedule\b/ ) {
    can_ok("alDente::Plate_Schedule", 'delete_plate_schedule');
    {
        ## <insert tests for delete_plate_schedule method here> ##
    }
}
if ( !$method || $method =~ /\b_update_plate_schedule_priority\b/ ) {
    can_ok("alDente::Plate_Schedule", '_update_plate_schedule_priority');
    {
        $self->_update_plate_schedule_priority(1,176413);
    }
}

## END of TEST ##

ok( 1 ,'Completed Plate_Schedule test');

exit;
