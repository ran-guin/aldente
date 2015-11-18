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
use alDente::Protocol_App;
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




use_ok("alDente::Protocol_App");

########################
## Add Run Mode Tests ##
########################
my $page;    ## output from respective run mode (Use RGTools::Unit_Test methods to check for output tables etc)

=begin
### Change Status ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Change Status', -Params=> {Protocol_ID=>459, Protocol=>'WGA', State=>'Active', Unit_Test=>1});

### Save Step ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Save Step', -Params=> {});

### Edit Protocol Name ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Edit Protocol Name', -Params=> {});

### Back to Home ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Back to Home', -Params=> {});

### Delete Protocol ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Delete Protocol', -Params=> {});

### Confirm Save As New Protocol ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Confirm Save As New Protocol', -Params=> {});

### Save As New Protocol ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Save As New Protocol', -Params=> {});

### Home Page ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Home Page', -Params=> {});

### Edit Protocol Visibility ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Edit Protocol Visibility', -Params=> {});

### Previous Step ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Previous Step', -Params=> {});

### Save Changes ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Save Changes', -Params=> {});

### Next Step ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Next Step', -Params=> {});

### Update Access ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Update Access', -Params=> {});

### View Step ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'View Step', -Params=> {});

### Update Protocol ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Update Protocol', -Params=> {});

### default ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'default', -Params=> {});

### Create New Protocol ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Create New Protocol', -Params=> {});

### Save New Protocol ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Save New Protocol', -Params=> {});

### Delete Step ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Delete Step', -Params=> {});

### Back to Protocol Admin Page ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Back to Protocol Admin Page', -Params=> {});

### View Protocol ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'View Protocol', -Params=> {});

### Add Step ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Add Step', -Params=> {});

### Set Groups ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Set Groups', -Params=> {});

### Refresh Protocol List ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Refresh Protocol List', -Params=> {});

### Accept TechD Protocol ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Protocol_App',-rm=>'Accept TechD Protocol', -Params=> {});

## END of TEST ##
=cut
ok( 1 ,'Completed Protocol_App test');

exit;
