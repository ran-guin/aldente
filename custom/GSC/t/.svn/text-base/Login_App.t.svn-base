#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../lib/perl";
use lib $FindBin::RealBin . "/../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../../../lib/perl/custom";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use SDB::CustomSettings qw(%Configs);
use RGTools::Unit_Test;

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


sub self {
    my %override_args = @_;
    my %args;

    # Set default values
    $args{-dbc} = defined $override_args{-dbc} ? $override_args{-dbc} : $dbc;

    return new GSC::Login_App(%args);

}

############################################################
use_ok("GSC::Login_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("GSC::Login_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\blocal_login\b/ ) {
    can_ok("GSC::Login_App", 'local_login');
    {
        ## <insert tests for local_login method here> ##
    }
}

if ( !$method || $method =~ /\b_record_cookie\b/ ) {
    can_ok("GSC::Login_App", '_record_cookie');
    {
        ## <insert tests for _record_cookie method here> ##
    }
}

if ( !$method || $method =~ /\b_authenticate_user_LDAP\b/ ) {
    can_ok("GSC::Login_App", '_authenticate_user_LDAP');
    {
        ## <insert tests for _authenticate_user_LDAP method here> ##
    }
}

if ( !$method || $method =~ /\berror_notification\b/ ) {
    can_ok("GSC::Login_App", 'error_notification');
    {
        ## <insert tests for error_notification method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_Database\b/ ) {
    can_ok("GSC::Login_App", 'search_Database');
    {
        ## <insert tests for search_Database method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Login_App test');

exit;
