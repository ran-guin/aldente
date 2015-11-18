#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################################################
use_ok("RGTools::Web_Form");

if ( !$method || $method =~ /\bPopup_Menu\b/ ) {
    can_ok("RGTools::Web_Form", 'Popup_Menu');
    {
        ## <insert tests for Popup_Menu method here> ##
    }
}

if ( !$method || $method =~ /\bSubmit_Button\b/ ) {
    can_ok("RGTools::Web_Form", 'Submit_Button');
    {
        ## <insert tests for Submit_Button method here> ##
    }
}

if ( !$method || $method =~ /\bImage_Submit\b/ ) {
    can_ok("RGTools::Web_Form", 'Image_Submit');
    {
        ## <insert tests for Image_Submit method here> ##
    }
}

if ( !$method || $method =~ /\bSubmit_Image\b/ ) {
    can_ok("RGTools::Web_Form", 'Submit_Image');
    {
        ## <insert tests for Submit_Image method here> ##
    }
}

if ( !$method || $method =~ /\bButton_Image\b/ ) {
    can_ok("RGTools::Web_Form", 'Button_Image');
    {
        ## <insert tests for Button_Image method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Web_Form test');

exit;
