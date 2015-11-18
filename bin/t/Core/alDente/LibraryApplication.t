#!/usr/local/bin/perl
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
use alDente::LibraryApplication;
############################

############################################


use_ok("alDente::LibraryApplication");

my $self = new alDente::LibraryApplication(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::LibraryApplication", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::LibraryApplication", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\bvalidate_application\b/ ) {
    can_ok("alDente::LibraryApplication", 'validate_application');
    {
        my $result = $self->validate_application(-library=>'HGL01',-object_class=>'Primer',-value=>'-21 M13 Forward');
        is($result,1,"-21 M13 Fwd is a valid primer for HGL01");

        my $result = $self->validate_application(-library=>'HGL01',-object_class=>'Primer',-value=>'T7');
        is($result,0,"T7 is NOT a valid primer for HGL01");

        my $result = $self->validate_application(-library=>'HGL01',-object_class=>'Primer',-value=>['-21 M13 Forward','-21M13Forward 100uM']);
        is($result,1,"'-21 M13 Fwd' and '-21M13Forward 100uM' are valid primers for HGL01");

        my $result = $self->validate_application(-library=>'HGL01',-object_class=>'Primer',-value=>['-21 M13 Forward','T7']);
        is($result,0,"'-21 M13 Fwd' and 'T7' are NOT valid primers for HGL01");

        my $result = $self->validate_application(-library=>'HMa01',-object_class=>'Enzyme',-value=>['EcoRV']);
        is($result,0,"'EcoRV' is NOT valid primer for HMa01");

        my $result = $self->validate_application(-library=>'HMa01',-object_class=>'Enzyme',-value=>['EcoRI']);
        is($result,1,"'EcoRI' is a valid primer for HMa01");

        my $result = $self->validate_application(-library=>'HMa01',-object_class=>'Enzyme',-value=>'EcoRI,BstXI');
        is($result,0,"'EcoRI,BstXI' are NOT valid primers for HMa01");

    }
}

if ( !$method || $method=~/\bview_application\b/ ) {
    can_ok("alDente::LibraryApplication", 'view_application');
    {
        ## <insert tests for view_application method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed LibraryApplication test');

exit;
