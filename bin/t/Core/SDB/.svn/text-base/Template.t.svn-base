#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../lib/perl";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host   = $Configs{UNIT_TEST_HOST};
my $dbase  = $Configs{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';
my $pwd    = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );

############################################################
use_ok("SDB::Template");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("SDB::Template", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bconfig\b/ ) {
    can_ok("SDB::Template", 'config');
    {
        ## <insert tests for config method here> ##
    }
}

if ( !$method || $method =~ /\bfield_config\b/ ) {
    can_ok("SDB::Template", 'field_config');
    {
        ## <insert tests for field_config method here> ##
    }
}

if ( !$method || $method =~ /\bget_config_fields\b/ ) {
    can_ok("SDB::Template", 'get_config_fields');
    {
        ## <insert tests for get_config_fields method here> ##
    }
}

if ( !$method || $method =~ /\bget_field_config_fields\b/ ) {
    can_ok("SDB::Template", 'get_field_config_fields');
    {
        ## <insert tests for get_field_config_fields method here> ##
    }
}

if ( !$method || $method =~ /\bget_key_headers\b/ ) {
    can_ok("SDB::Template", 'get_key_headers');
    {
        ## <insert tests for get_key_headers method here> ##
    }
}

if ( !$method || $method =~ /\bpath\b/ ) {
    can_ok("SDB::Template", 'path');
    {
        ## <insert tests for path method here> ##
    }
}

if ( !$method || $method =~ /\bconfigure\b/ ) {
    can_ok("SDB::Template", 'configure');
    {
        ## <insert tests for configure method here> ##
    }
}

if ( !$method || $method =~ /\binherit_config\b/ ) {
    can_ok("SDB::Template", 'inherit_config');
    {
        ## <insert tests for inherit_config method here> ##
    }
}

if ( !$method || $method =~ /\bsave\b/ ) {
    can_ok("SDB::Template", 'save');
    {
        ## <insert tests for save method here> ##
    }
}

if ( !$method || $method =~ /\bvalidate\b/ ) {
    can_ok("SDB::Template", 'validate');
    {
        ## <insert tests for validate method here> ##
    }
}

if ( !$method || $method =~ /\bsave_Custom_Template\b/ ) {
    can_ok("SDB::Template", 'save_Custom_Template');
    {
        ## <insert tests for save_Custom_Template method here> ##
    }
}

if ( !$method || $method =~ /\bget_Path\b/ ) {
    can_ok("SDB::Template", 'get_Path');
    {
        ## <insert tests for get_Path method here> ##
    }
}

if ( !$method || $method =~ /\bget_List\b/ ) {
    can_ok("SDB::Template", 'get_List');
    {
        ## <insert tests for get_List method here> ##
    }
}

if ( !$method || $method =~ /\bapprove_Template\b/ ) {
    can_ok("SDB::Template", 'approve_Template');
    {
        ## <insert tests for approve_Template method here> ##
    }
}

if ( !$method || $method =~ /\blink_Template_to_Project\b/ ) {
    can_ok("SDB::Template", 'link_Template_to_Project');
    {
        ## <insert tests for link_Template_to_Project method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Template test');

exit;
