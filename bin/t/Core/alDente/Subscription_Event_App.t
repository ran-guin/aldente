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
use alDente::Subscription_Event_App;
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




use_ok("alDente::Subscription_Event_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Subscription_Event_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Subscription_events\b/ ) {
    can_ok("alDente::Subscription_Event_App", 'show_Subscription_events');
    {
        ## <insert tests for show_Subscription_events method here> ##
    }
}

if ( !$method || $method =~ /\badd_Event_button\b/ ) {
    can_ok("alDente::Subscription_Event_App", 'add_Event_button');
    {
        ## <insert tests for add_Event_button method here> ##
    }
}

if ( !$method || $method =~ /\badd_Subscription_Event\b/ ) {
    can_ok("alDente::Subscription_Event_App", 'add_Subscription_Event');
    {
        ## <insert tests for add_Subscription_Event method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Subscriptions\b/ ) {
    can_ok("alDente::Subscription_Event_App", 'show_Subscriptions');
    {
        ## <insert tests for show_Subscriptions method here> ##
    }
}

if ( !$method || $method =~ /\bdelete_Subscribers\b/ ) {
    can_ok("alDente::Subscription_Event_App", 'delete_Subscribers');
    {
        ## <insert tests for delete_Subscribers method here> ##
    }
}

if ( !$method || $method =~ /\bdelete_button\b/ ) {
    can_ok("alDente::Subscription_Event_App", 'delete_button');
    {
        ## <insert tests for delete_button method here> ##
    }
}

if ( !$method || $method =~ /\bsubscribe_button\b/ ) {
    can_ok("alDente::Subscription_Event_App", 'subscribe_button');
    {
        ## <insert tests for subscribe_button method here> ##
    }
}

if ( !$method || $method =~ /\bnew_subscription_button\b/ ) {
    can_ok("alDente::Subscription_Event_App", 'new_subscription_button');
    {
        ## <insert tests for new_subscription_button method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Subscribers\b/ ) {
    can_ok("alDente::Subscription_Event_App", 'show_Subscribers');
    {
        ## <insert tests for show_Subscribers method here> ##
    }
}

if ( !$method || $method =~ /\badd_Subscribers\b/ ) {
    can_ok("alDente::Subscription_Event_App", 'add_Subscribers');
    {
        ## <insert tests for add_Subscribers method here> ##
    }
}

if ( !$method || $method =~ /\badd_Subscription\b/ ) {
    can_ok("alDente::Subscription_Event_App", 'add_Subscription');
    {
        ## <insert tests for add_Subscription method here> ##
    }
}

if ( !$method || $method =~ /\bremove_Subscribers\b/ ) {
    can_ok("alDente::Subscription_Event_App", 'remove_Subscribers');
    {
        ## <insert tests for remove_Subscribers method here> ##
    }
}

if ( !$method || $method =~ /\bremove_Subscription\b/ ) {
    can_ok("alDente::Subscription_Event_App", 'remove_Subscription');
    {
        ## <insert tests for remove_Subscription method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Subscription_Event_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bedit_Subscription\b/ ) {
    can_ok("alDente::Subscription_Event_App", 'edit_Subscription');
    {
        ## <insert tests for edit_Subscription method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_Subscription\b/ ) {
    can_ok("alDente::Subscription_Event_App", 'search_Subscription');
    {
        ## <insert tests for search_Subscription method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_by_Subscribers \b/ ) {
    can_ok("alDente::Subscription_Event_App", 'search_by_Subscribers');
    {
        ## <insert tests for search_by_Subscribers  method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Subscription_Event_App test');

exit;
