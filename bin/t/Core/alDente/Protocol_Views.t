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
use alDente::Protocol_Views;
############################

############################################


use_ok("alDente::Protocol_Views");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Protocol_Views", 'new');
    {
        ## <insert tests for new method here> ##
        my $self = new alDente::Protocol_Views( -dbc => $dbc );
        ok( $self, 'new');
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Protocol_Views", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\blist_page\b/ ) {
    can_ok("alDente::Protocol_Views", 'list_page');
    {
        ## <insert tests for list_page method here> ##
    }
}

if ( !$method || $method =~ /\bedit_Protocol_Visibility\b/ ) {
    can_ok("alDente::Protocol_Views", 'edit_Protocol_Visibility');
    {
        ## <insert tests for edit_Protocol_Visibility method here> ##
    }
}

if ( !$method || $method =~ /\bsave_New_Protocol_View\b/ ) {
    can_ok("alDente::Protocol_Views", 'save_New_Protocol_View');
    {
        ## <insert tests for save_New_Protocol_View method here> ##
    }
}

if ( !$method || $method =~ /\bnew_protocol_prompt\b/ ) {
    can_ok("alDente::Protocol_Views", 'new_protocol_prompt');
    {
        ## <insert tests for new_protocol_prompt method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Step_Page\b/ ) {
    can_ok("alDente::Protocol_Views", 'display_Step_Page');
    {
        ## <insert tests for display_Step_Page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Step_Top\b/ ) {
    can_ok("alDente::Protocol_Views", 'display_Step_Top');
    {
        ## <insert tests for display_Step_Top method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Step_Form\b/ ) {
    can_ok("alDente::Protocol_Views", 'display_Step_Form');
    {
        ## <insert tests for display_Step_Form method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Input_Form\b/ ) {
    can_ok("alDente::Protocol_Views", 'display_Input_Form');
    {
        ## <insert tests for display_Input_Form method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Validate\b/ ) {
    can_ok("alDente::Protocol_Views", 'display_Validate');
    {
        ## <insert tests for display_Validate method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_QC\b/ ) {
    can_ok("alDente::Protocol_Views", 'display_QC');
    {
        ## <insert tests for display_QC method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Step_Name\b/ ) {
    can_ok("alDente::Protocol_Views", 'display_Step_Name');
    {
        ## <insert tests for display_Step_Name method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Step_Buttons\b/ ) {
    can_ok("alDente::Protocol_Views", 'display_Step_Buttons');
    {
        ## <insert tests for display_Step_Buttons method here> ##
    }
}

if ( !$method || $method =~ /\bview_Protocol\b/ ) {
    can_ok("alDente::Protocol_Views", 'view_Protocol');
    {
        ## <insert tests for view_Protocol method here> ##
    }
}

if ( !$method || $method =~ /\bget_buttons\b/ ) {
    can_ok("alDente::Protocol_Views", 'get_buttons');
    {
        ## <insert tests for get_buttons method here> ##
    }
}

if ( !$method || $method =~ /\b_get_groups_info\b/ ) {
    can_ok("alDente::Protocol_Views", '_get_groups_info');
    {
        ## <insert tests for _get_groups_info method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Protocol_Views test');

exit;
