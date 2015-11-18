#!/usr/local/bin/perl

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
use Test::More; use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use SDB::Session;
############################
my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("SDB::Session");

if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("SDB::Session", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bset\b/ ) {
    can_ok("SDB::Session", 'set');
    {
        ## <insert tests for set method here> ##
    }
}

if ( !$method || $method=~/\bsession_id\b/ ) {
    can_ok("SDB::Session", 'session_id');
    {
        ## <insert tests for session_id method here> ##
    }
}

if ( !$method || $method=~/\bsession_dir\b/ ) {
    can_ok("SDB::Session", 'session_dir');
    {
        ## <insert tests for session_dir method here> ##
    }
}

if ( !$method || $method=~/\buser\b/ ) {
    can_ok("SDB::Session", 'user');
    {
        ## <insert tests for user method here> ##
    }
}

if ( !$method || $method=~/\buser_id\b/ ) {
    can_ok("SDB::Session", 'user_id');
    {
        ## <insert tests for user_id method here> ##
    }
}

if ( !$method || $method=~/\bparameters\b/ ) {
    can_ok("SDB::Session", 'parameters');
    {
        ## <insert tests for parameters method here> ##
    }
}

if ( !$method || $method=~/\bdbase\b/ ) {
    can_ok("SDB::Session", 'dbase');
    {
        ## <insert tests for dbase method here> ##
    }
}

if ( !$method || $method=~/\bhomepage\b/ ) {
    can_ok("SDB::Session", 'homepage');
    {
        ## <insert tests for homepage method here> ##
    }
}

if ( !$method || $method=~/\breset_homepage\b/ ) {
    can_ok("SDB::Session", 'reset_homepage');
    {
        ## <insert tests for reset_homepage method here> ##
    }
}

if ( !$method || $method=~/\bprojects\b/ ) {
    can_ok("SDB::Session", 'projects');
    {
        ## <insert tests for projects method here> ##
    }
}

if ( !$method || $method=~/\bURL_dir\b/ ) {
    can_ok("SDB::Session", 'URL_dir');
    {
        ## <insert tests for URL_dir method here> ##
    }
}

if ( !$method || $method=~/\brelease\b/ ) {
    can_ok("SDB::Session", 'release');
    {
        ## <insert tests for release method here> ##
    }
}

if ( !$method || $method=~/\bbanner\b/ ) {
    can_ok("SDB::Session", 'banner');
    {
        ## <insert tests for banner method here> ##
    }
}

if ( !$method || $method=~/\bnav\b/ ) {
    can_ok("SDB::Session", 'nav');
    {
        ## <insert tests for nav method here> ##
    }
}

if ( !$method || $method=~/\bscanner_mode\b/ ) {
    can_ok("SDB::Session", 'scanner_mode');
    {
        ## <insert tests for scanner_mode method here> ##
    }
}

if ( !$method || $method=~/\bcurr_page_target\b/ ) {
    can_ok("SDB::Session", 'curr_page_target');
    {
        ## <insert tests for curr_page_target method here> ##
    }
}

if ( !$method || $method=~/\bcurr_page_params\b/ ) {
    can_ok("SDB::Session", 'curr_page_params');
    {
        ## <insert tests for curr_page_params method here> ##
    }
}

if ( !$method || $method=~/\bcurr_page_warnings\b/ ) {
    can_ok("SDB::Session", 'curr_page_warnings');
    {
        ## <insert tests for curr_page_warnings method here> ##
    }
}

if ( !$method || $method=~/\bcurr_page_errors\b/ ) {
    can_ok("SDB::Session", 'curr_page_errors');
    {
        ## <insert tests for curr_page_errors method here> ##
    }
}

if ( !$method || $method=~/\bprev_page_target\b/ ) {
    can_ok("SDB::Session", 'prev_page_target');
    {
        ## <insert tests for prev_page_target method here> ##
    }
}

if ( !$method || $method=~/\bprev_page_params\b/ ) {
    can_ok("SDB::Session", 'prev_page_params');
    {
        ## <insert tests for prev_page_params method here> ##
    }
}

if ( !$method || $method=~/\bprev_page_warnings\b/ ) {
    can_ok("SDB::Session", 'prev_page_warnings');
    {
        ## <insert tests for prev_page_warnings method here> ##
    }
}

if ( !$method || $method=~/\bprev_page_errors\b/ ) {
    can_ok("SDB::Session", 'prev_page_errors');
    {
        ## <insert tests for prev_page_errors method here> ##
    }
}

if ( !$method || $method=~/\bconfirm\b/ ) {
    can_ok("SDB::Session", 'confirm');
    {
        ## <insert tests for confirm method here> ##
    }
}

if ( !$method || $method=~/\bPID\b/ ) {
    can_ok("SDB::Session", 'PID');
    {
        ## <insert tests for PID method here> ##
    }
}

if ( !$method || $method=~/\bcurrent_messages\b/ ) {
    can_ok("SDB::Session", 'current_messages');
    {
        ## <insert tests for current_messages method here> ##
    }
}

if ( !$method || $method=~/\bmessage\b/ ) {
    can_ok("SDB::Session", 'message');
    {
        ## <insert tests for message method here> ##
    }
}

if ( !$method || $method=~/\bwarning\b/ ) {
    can_ok("SDB::Session", 'warning');
    {
        ## <insert tests for warning method here> ##
    }
}

if ( !$method || $method=~/\berror\b/ ) {
    can_ok("SDB::Session", 'error');
    {
        ## <insert tests for error method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_session_id\b/ ) {
    can_ok("SDB::Session", 'generate_session_id');
    {
        ## <insert tests for generate_session_id method here> ##
    }
}

if ( !$method || $method=~/\bstore_Session\b/ ) {
    can_ok("SDB::Session", 'store_Session');
    {
        ## <insert tests for store_Session method here> ##
    }
}

if ( !$method || $method=~/\bstore_Session_messages\b/ ) {
    can_ok("SDB::Session", 'store_Session_messages');
    {
        ## <insert tests for store_Session_messages method here> ##
    }
}

if ( !$method || $method=~/\bset_parameters\b/ ) {
    can_ok("SDB::Session", 'set_parameters');
    {
        ## <insert tests for set_parameters method here> ##
    }
}

if ( !$method || $method=~/\bvalidate_session\b/ ) {
    can_ok("SDB::Session", 'validate_session');
    {
        ## <insert tests for validate_session method here> ##
    }
}

if ( !$method || $method=~/\b_decode_Session\b/ ) {
    can_ok("SDB::Session", '_decode_Session');
    {
        ## <insert tests for _decode_Session method here> ##
    }
}

if ( !$method || $method=~/\b_initialize\b/ ) {
    can_ok("SDB::Session", '_initialize');
    {
        ## <insert tests for _initialize method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Session test');

exit;
