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
use RGTools::Object;
############################
############################################################
use_ok("RGTools::Object");

my $self = new Object();
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("Object", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bAUTOLOADxx\b/ ) {
    can_ok("Object", 'AUTOLOADxx');
    {
        ## <insert tests for AUTOLOADxx method here> ##
    }
}

if ( !$method || $method=~/\bclone\b/ ) {
    can_ok("Object", 'clone');
    {
        ## <insert tests for clone method here> ##
    }
}

if ( !$method || $method=~/\bfreeze\b/ ) {
    can_ok("Object", 'freeze');
    {
        ## <insert tests for freeze method here> ##
    }
}

if ( !$method || $method=~/\berror\b/ ) {
    can_ok("Object", 'error');
    {
        ## <insert tests for error method here> ##
    }
}

if ( !$method || $method=~/\berrors\b/ ) {
    can_ok("Object", 'errors');
    {
        ## <insert tests for errors method here> ##
    }
}

if ( !$method || $method=~/\bwarning\b/ ) {
    can_ok("Object", 'warning');
    {
        ## <insert tests for warning method here> ##
    }
}

if ( !$method || $method=~/\bwarnings\b/ ) {
    can_ok("Object", 'warnings');
    {
        ## <insert tests for warnings method here> ##
    }
}

if ( !$method || $method=~/\bclear_messages\b/ ) {
    can_ok("Object", 'clear_messages');
    {
        ## <insert tests for clear_messages method here> ##
    }
}

if ( !$method || $method=~/\bmessages\b/ ) {
    can_ok("Object", 'messages');
    {
        ## <insert tests for messages method here> ##
    }
}

if ( !$method || $method=~/\bmessage\b/ ) {
    can_ok("Object", 'message');
    {
        ## <insert tests for message method here> ##
    }
}

if ( !$method || $method=~/\bsuccess\b/ ) {
    can_ok("Object", 'success');
    {
        ## <insert tests for success method here> ##
    }
}

if ( !$method || $method=~/\bset_message_priority\b/ ) {
    can_ok("Object", 'set_message_priority');
    {
        ## <insert tests for set_message_priority method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Object test');

exit;
