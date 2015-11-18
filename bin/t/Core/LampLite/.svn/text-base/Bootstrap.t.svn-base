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
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 
my $dbc;                                 ## only used for modules enabling database connections

############################
use LampLite::Bootstrap;
############################

############################################


use_ok("LampLite::Bootstrap");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("Bootstrap", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bload_css\b/ ) {
    can_ok("Bootstrap", 'load_css');
    {
        ## <insert tests for load_css method here> ##
    }
}

if ( !$method || $method =~ /\bload_js\b/ ) {
    can_ok("Bootstrap", 'load_js');
    {
        ## <insert tests for load_js method here> ##
    }
}

if ( !$method || $method =~ /\b_bootstrap_js\b/ ) {
    can_ok("Bootstrap", '_bootstrap_js');
    {
        ## <insert tests for _bootstrap_js method here> ##
    }
}

if ( !$method || $method =~ /\bload_tooltip_js\b/ ) {
    can_ok("Bootstrap", 'load_tooltip_js');
    {
        ## <insert tests for load_tooltip_js method here> ##
    }
}

if ( !$method || $method =~ /\bopen\b/ ) {
    can_ok("Bootstrap", 'open');
    {
        ## <insert tests for open method here> ##
    }
}

if ( !$method || $method =~ /\bclose\b/ ) {
    can_ok("Bootstrap", 'close');
    {
        ## <insert tests for close method here> ##
    }
}

if ( !$method || $method =~ /\bbutton\b/ ) {
    can_ok("Bootstrap", 'button');
    {
        ## <insert tests for button method here> ##
    }
}

if ( !$method || $method =~ /\bmodal\b/ ) {
    can_ok("Bootstrap", 'modal');
    {
        ## <insert tests for modal method here> ##
    }
}

if ( !$method || $method =~ /\bcalendar\b/ ) {
    can_ok("Bootstrap", 'calendar');
    {
        ## <insert tests for calendar method here> ##
    }
}

if ( !$method || $method =~ /\brow\b/ ) {
    can_ok("Bootstrap", 'row');
    {
        ## <insert tests for row method here> ##
    }
}

if ( !$method || $method =~ /\bmenu\b/ ) {
    can_ok("Bootstrap", 'menu');
    {
        ## <insert tests for menu method here> ##
    }
}

if ( !$method || $method =~ /\bsplit_a_tag\b/ ) {
    can_ok("Bootstrap", 'split_a_tag');
    {
        ## <insert tests for split_a_tag method here> ##
    }
}

if ( !$method || $method =~ /\blayer\b/ ) {
    can_ok("Bootstrap", 'layer');
    {
        ## <insert tests for layer method here> ##
    }
}

if ( !$method || $method =~ /\baccordion\b/ ) {
    can_ok("Bootstrap", 'accordion');
    {
        ## <insert tests for accordion method here> ##
    }
}

if ( !$method || $method =~ /\berror\b/ ) {
    can_ok("Bootstrap", 'error');
    {
        ## <insert tests for error method here> ##
    }
}

if ( !$method || $method =~ /\bicon\b/ ) {
    can_ok("Bootstrap", 'icon');
    {
        ## <insert tests for icon method here> ##
    }
}

if ( !$method || $method =~ /\block_unlock_header\b/ ) {
    can_ok("Bootstrap", 'lock_unlock_header');
    {
        ## <insert tests for lock_unlock_header method here> ##
    }
}

if ( !$method || $method =~ /\block_header\b/ ) {
    can_ok("Bootstrap", 'lock_header');
    {
        ## <insert tests for lock_header method here> ##
    }
}

if ( !$method || $method =~ /\bunlock_header\b/ ) {
    can_ok("Bootstrap", 'unlock_header');
    {
        ## <insert tests for unlock_header method here> ##
    }
}

if ( !$method || $method =~ /\bshow_header\b/ ) {
    can_ok("Bootstrap", 'show_header');
    {
        ## <insert tests for show_header method here> ##
    }
}

if ( !$method || $method =~ /\bhide_header\b/ ) {
    can_ok("Bootstrap", 'hide_header');
    {
        ## <insert tests for hide_header method here> ##
    }
}

if ( !$method || $method =~ /\b_header\b/ ) {
    can_ok("Bootstrap", '_header');
    {
        ## <insert tests for _header method here> ##
    }
}

if ( !$method || $method =~ /\bpath\b/ ) {
    can_ok("Bootstrap", 'path');
    {
        ## <insert tests for path method here> ##
    }
}

if ( !$method || $method =~ /\bcontext\b/ ) {
    can_ok("Bootstrap", 'context');
    {
        ## <insert tests for context method here> ##
    }
}

if ( !$method || $method =~ /\balert\b/ ) {
    can_ok("Bootstrap", 'alert');
    {
        ## <insert tests for alert method here> ##
    }
}

if ( !$method || $method =~ /\btext\b/ ) {
    can_ok("Bootstrap", 'text');
    {
        ## <insert tests for text method here> ##
    }
}

if ( !$method || $method =~ /\bmessage\b/ ) {
    can_ok("Bootstrap", 'message');
    {
        ## <insert tests for message method here> ##
    }
}

if ( !$method || $method =~ /\bwarning\b/ ) {
    can_ok("Bootstrap", 'warning');
    {
        ## <insert tests for warning method here> ##
    }
}

if ( !$method || $method =~ /\berror\b/ ) {
    can_ok("Bootstrap", 'error');
    {
        ## <insert tests for error method here> ##
    }
}

if ( !$method || $method =~ /\binfo\b/ ) {
    can_ok("Bootstrap", 'info');
    {
        ## <insert tests for info method here> ##
    }
}

if ( !$method || $method =~ /\bsuccess\b/ ) {
    can_ok("Bootstrap", 'success');
    {
        ## <insert tests for success method here> ##
    }
}

if ( !$method || $method =~ /\btooltip\b/ ) {
    can_ok("Bootstrap", 'tooltip');
    {
        ## <insert tests for tooltip method here> ##
    }
}

if ( !$method || $method =~ /\bin_Progress\b/ ) {
    can_ok("Bootstrap", 'in_Progress');
    {
        ## <insert tests for in_Progress method here> ##
    }
}

if ( !$method || $method =~ /\bstart_Progress\b/ ) {
    can_ok("Bootstrap", 'start_Progress');
    {
        ## <insert tests for start_Progress method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_Progress\b/ ) {
    can_ok("Bootstrap", 'update_Progress');
    {
        ## <insert tests for update_Progress method here> ##
    }
}

if ( !$method || $method =~ /\bsearch\b/ ) {
    can_ok("Bootstrap", 'search');
    {
        ## <insert tests for search method here> ##
    }
}

if ( !$method || $method =~ /\blogin\b/ ) {
    can_ok("Bootstrap", 'login');
    {
        ## <insert tests for login method here> ##
    }
}

if ( !$method || $method =~ /\btest_page\b/ ) {
    can_ok("Bootstrap", 'test_page');
    {
        ## <insert tests for test_page method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Bootstrap test');

exit;
