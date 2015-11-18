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
use alDente::Web;
############################

############################################


use_ok("alDente::Web");

if ( !$method || $method=~/\bGoHome\b/ ) {
    can_ok("alDente::Web", 'GoHome');
    {
        ## <insert tests for GoHome method here> ##
    }
}

if ( !$method || $method=~/\bget_dept_module\b/ ) {
    can_ok("alDente::Web", 'get_dept_module');
    {
        ## <insert tests for get_dept_module method here> ##
    }
}

if ( !$method || $method=~/\bpage_icons\b/ ) {
    can_ok("alDente::Web", 'page_icons');
    {
        ## <insert tests for page_icons method here> ##
    }
}

if ( !$method || $method=~/\bshow_current_messages\b/ ) {
    can_ok("alDente::Web", 'show_current_messages');
    {
        ## <insert tests for current_messages method here> ##
    }
}

if ( !$method || $method=~/\bTab_Bar\b/ ) {
    can_ok("alDente::Web", 'Tab_Bar');
    {
        ## <insert tests for Tab_Bar method here> ##
    }
}

if ( !$method || $method=~/\breload_parameters\b/ ) {
    can_ok("alDente::Web", 'reload_parameters');
    {
        ## <insert tests for reload_parameters method here> ##
    }
}

if ( !$method || $method=~/\binitialize_cookies\b/ ) {
    can_ok("alDente::Web", 'initialize_cookies');
    {
        ## <insert tests for initialize_cookies method here> ##
    }
}

if ( !$method || $method=~/\bInitialize_page\b/ ) {
    can_ok("alDente::Web", 'Initialize_page');
    {
        ## <insert tests for Initialize_page method here> ##
    }
}

if ( !$method || $method=~/\bunInitialize_page\b/ ) {
    can_ok("alDente::Web", 'unInitialize_page');
    {
        ## <insert tests for unInitialize_page method here> ##
    }
}

if ( !$method || $method=~/\bshow_topbar\b/ ) {
    can_ok("alDente::Web", 'show_topbar');
    {
        ## <insert tests for show_topbar method here> ##
    }
}

if ( !$method || $method=~/\bshow_botbar\b/ ) {
    can_ok("alDente::Web", 'show_botbar');
    {
        ## <insert tests for show_botbar method here> ##
    }
}

if ( !$method || $method=~/\blogin_password\b/ ) {
    can_ok("alDente::Web", 'login_password');
    {
        ## <insert tests for login_password method here> ##
    }
}

if ( !$method || $method =~ /\bicons\b/ ) {
    can_ok("alDente::Web", 'icons');
    {
        ## <insert tests for icons method here> ##
    }
}

if ( !$method || $method =~ /\bimage\b/ ) {
    can_ok("alDente::Web", 'image');
    {
        ## <insert tests for image method here> ##
    }
}

if ( !$method || $method =~ /\bthumbnail\b/ ) {
    can_ok("alDente::Web", 'thumbnail');
    {
        ## <insert tests for thumbnail method here> ##
    }
}

if ( !$method || $method =~ /\bload_standard_icons\b/ ) {
    can_ok("alDente::Web", 'load_standard_icons');
    {
        ## <insert tests for load_standard_icons method here> ##
    }
}

if ( !$method || $method =~ /\bheader_messages\b/ ) {
    can_ok("alDente::Web", 'header_messages');
    {
        ## <insert tests for header_messages method here> ##
    }
}

if ( !$method || $method =~ /\bvalidate_Printers\b/ ) {
    can_ok("alDente::Web", 'validate_Printers');
    {
        ## <insert tests for validate_Printers method here> ##
    }
}

if ( !$method || $method =~ /\bMenu\b/ ) {
    can_ok("alDente::Web", 'Menu');
    {
        ## <insert tests for Menu method here> ##
    }
}

if ( !$method || $method =~ /\bhide_element\b/ ) {
    can_ok("alDente::Web", 'hide_element');
    {
        ## <insert tests for hide_element method here> ##
    }
}

if ( !$method || $method =~ /\badd_sub_labels\b/ ) {
    can_ok("alDente::Web", 'add_sub_labels');
    {
        ## <insert tests for add_sub_labels method here> ##
    }
}

if ( !$method || $method =~ /\bload_user_views\b/ ) {
    can_ok("alDente::Web", 'load_user_views');
    {
        ## <insert tests for load_user_views method here> ##
    }
}

if ( !$method || $method =~ /\bgen_cookies\b/ ) {
    can_ok("alDente::Web", 'gen_cookies');
    {
        ## <insert tests for gen_cookies method here> ##
    }
}

if ( !$method || $method =~ /\buser_label\b/ ) {
    can_ok("alDente::Web", 'user_label');
    {
        ## <insert tests for user_label method here> ##
    }
}

if ( !$method || $method =~ /\breload_input\b/ ) {
    can_ok("alDente::Web", 'reload_input');
    {
        ## <insert tests for reload_input method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Web test');

exit;
