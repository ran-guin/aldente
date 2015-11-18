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
use alDente::Login_Views;
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




use_ok("alDente::Login_Views");

if ( !$method || $method =~ /\bheader\b/ ) {
    can_ok("alDente::Login_Views", 'header');
    {
        ## <insert tests for header method here> ##
    }
}

if ( !$method || $method =~ /\blogin_page_header\b/ ) {
    can_ok("alDente::Login_Views", 'login_page_header');
    {
        ## <insert tests for login_page_header method here> ##
    }
}

if ( !$method || $method =~ /\balDente_header_bar\b/ ) {
    can_ok("alDente::Login_Views", 'alDente_header_bar');
    {
        ## <insert tests for alDente_header_bar method here> ##
    }
}

if ( !$method || $method =~ /\bscan_button\b/ ) {
    can_ok("alDente::Login_Views", 'scan_button');
    {
        ## <insert tests for scan_button method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_button\b/ ) {
    can_ok("alDente::Login_Views", 'search_button');
    {
        ## <insert tests for search_button method here> ##
    }
}

if ( !$method || $method =~ /\berror_button\b/ ) {
    can_ok("alDente::Login_Views", 'error_button');
    {
        ## <insert tests for error_button method here> ##
    }
}

if ( !$method || $method =~ /\bplate_set_button\b/ ) {
    can_ok("alDente::Login_Views", 'plate_set_button');
    {
        ## <insert tests for plate_set_button method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Login_page\b/ ) {
    can_ok("alDente::Login_Views", 'display_Login_page');
    {
        ## <insert tests for display_Login_page method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_Header\b/ ) {
    can_ok("alDente::Login_Views", 'generate_Header');
    {
        ## <insert tests for generate_Header method here> ##
    }
}

if ( !$method || $method =~ /\bprinters_popup\b/ ) {
    can_ok("alDente::Login_Views", 'printers_popup');
    {
        ## <insert tests for printers_popup method here> ##
    }
}

if ( !$method || $method =~ /\bfooter\b/ ) {
    can_ok("alDente::Login_Views", 'footer');
    {
        ## <insert tests for footer method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Login_Views", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bcontact_info\b/ ) {
    can_ok("alDente::Login_Views", 'contact_info');
    {
        ## <insert tests for contact_info method here> ##
    }
}

if ( !$method || $method =~ /\bLIMS_contact_info\b/ ) {
    can_ok("alDente::Login_Views", 'LIMS_contact_info');
    {
        ## <insert tests for LIMS_contact_info method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Login_Views test');

exit;
