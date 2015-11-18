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
use alDente::Employee;
############################

############################################


use_ok("alDente::Employee");

my $self = new alDente::Employee(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Employee", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bdefine_User\b/ ) {
    can_ok("alDente::Employee", 'define_User');
    {
        ## <insert tests for define_User method here> ##
    }
}

if ( !$method || $method=~/\bEmployee_home\b/ ) {
    can_ok("alDente::Employee", 'Employee_home');
    {
        ## <insert tests for Employee_home method here> ##
    }
}

if ( !$method || $method=~/\bhome_info\b/ ) {
    can_ok("alDente::Employee", 'home_info');
    {
        ## <insert tests for home_info method here> ##
    }
}

if ( !$method || $method=~/\bget_email_list\b/ ) {
    can_ok("alDente::Employee", 'get_email_list');
    {
        ## <insert tests for get_email_list method here> ##
    }
}

if ( !$method || $method =~ /\bget_Employee_ID\b/ ) {
    can_ok("alDente::Employee", 'get_Employee_ID');
    {
        ## <insert tests for get_Employee_ID method here> ##
    }
}

if ( !$method || $method =~ /\bnew_Employee_trigger\b/ ) {
    can_ok("alDente::Employee", 'new_Employee_trigger');
    {
        ## <insert tests for new_Employee_trigger method here> ##
    }
}

if ( !$method || $method =~ /\bnew_GrpEmployee_trigger\b/ ) {
    can_ok("alDente::Employee", 'new_GrpEmployee_trigger');
    {
        ## <insert tests for new_GrpEmployee_trigger method here> ##
    }
}

if ( !$method || $method =~ /\bleave_Grp\b/ ) {
    can_ok("alDente::Employee", 'leave_Grp');
    {
        ## <insert tests for leave_Grp method here> ##
    }
}

if ( !$method || $method =~ /\bjoin_Grp\b/ ) {
    can_ok("alDente::Employee", 'join_Grp');
    {
        ## <insert tests for join_Grp method here> ##
    }
}

if ( !$method || $method =~ /\bgroups\b/ ) {
    can_ok("alDente::Employee", 'groups');
    {
        ## <insert tests for groups method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Employee", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bget_employee_Groups\b/ ) {
    can_ok("alDente::Employee", 'get_employee_Groups');
    {
        ## <insert tests for get_employee_Groups method here> ##
    }
}

if ( !$method || $method =~ /\bget_Settings\b/ ) {
    can_ok("alDente::Employee", 'get_Settings');
    {
        ## <insert tests for get_Settings method here> ##
        my $Emp = new alDente::Employee(-id=>141, -dbc=>$dbc);
        my $setting = $Emp->get_Settings(-scope=>'emp', -setting=>'printer_group');
        is($setting,'','undef setting for emp');

        $setting = $Emp->get_Settings(-scope=>'dept', -setting=>'printer_group');
        is($setting,'Printing Disabled','get group setting');
    
        
        $setting = $Emp->get_Settings(-setting=>'printer_group');
        is($setting,'Printing Disabled','get_Settings without scope');
        
        $Emp->save_Setting(-scope=>'Dept', -value=>'7th Floor CRC', -setting=>'printer_group');
        $setting = $Emp->get_Settings(-setting=>'printer_group');
        is($setting,'7th Floor CRC','re-write Dept Setting');
        $Emp->save_Setting(-scope=>'Dept', -value=>'Printing Disabled', -setting=>'printer_group');
        
        $Emp->save_Setting(-scope=>'Employee', -value=>'Receiving Printers', -setting=>'printer_group');
        $setting = $Emp->get_Settings(-setting=>'printer_group');
        is($setting,'Receiving Printers','save new Employee Setting');
        $Emp->clear_Setting(-scope=>'Employee', -setting=>'printer_group');
    }
}

if ( !$method || $method =~ /\bsave_Setting\b/ ) {
    can_ok("alDente::Employee", 'save_Setting');
    {
        ## <insert tests for save_Setting method here> ##
    }
}

if ( !$method || $method =~ /\bis_admin\b/ ) {
    can_ok("alDente::Employee", 'is_admin');
    {
        ## <insert tests for is_admin method here> ##
        ok( $self->is_admin(-employee=>'Richard') , 'Richard is admin');
        ok( $self->is_admin(-employee=>'Richard', -dept=>'Cap_Seq') , 'Richard is Cap_Seq admin');
        ok( $self->is_admin(-employee=>'Richard', -dept_id=>2) , 'Richard is Cap_Seq admin');
        ok ( !$self->is_admin(-employee=>'Richard', -dept=>'Mapping'), 'not mapping admin');
    }
}

if ( !$method || $method =~ /\bclear_Setting\b/ ) {
    can_ok("alDente::Employee", 'clear_Setting');
    {
        ## <insert tests for clear_Setting method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Employee test');

exit;
