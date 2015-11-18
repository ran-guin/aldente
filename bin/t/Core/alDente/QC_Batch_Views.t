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
use alDente::QC_Batch_Views;
############################

############################################


use_ok("alDente::QC_Batch_Views");

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::QC_Batch_Views", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bnew_Batch_form\b/ ) {
    can_ok("alDente::QC_Batch_Views", 'new_Batch_form');
    {
        ## <insert tests for new_Batch_form method here> ##
    }
}

if ( !$method || $method =~ /\bBatch_home\b/ ) {
    can_ok("alDente::QC_Batch_Views", 'Batch_home');
    {
        ## <insert tests for Batch_home method here> ##
    }
}

if ( !$method || $method =~ /\bbatch_details\b/ ) {
    can_ok("alDente::QC_Batch_Views", 'batch_details');
    {
        ## <insert tests for batch_details method here> ##
    }
}

if ( !$method || $method =~ /\bconfirm_Batch\b/ ) {
    can_ok("alDente::QC_Batch_Views", 'confirm_Batch');
    {
        ## <insert tests for confirm_Batch method here> ##
    }
}

if ( !$method || $method =~ /\bview_History\b/ ) {
    can_ok("alDente::QC_Batch_Views", 'view_History');
    {
        ## <insert tests for view_History method here> ##
    }
}

if ( !$method || $method =~ /\bQC_button\b/ ) {
    can_ok("alDente::QC_Batch_Views", 'QC_button');
    {
        ## <insert tests for QC_button method here> ##
    }
}

if ( !$method || $method =~ /\bnew_Report\b/ ) {
    can_ok("alDente::QC_Batch_Views", 'new_Report');
    {
        ## <insert tests for new_Report method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Report\b/ ) {
    can_ok("alDente::QC_Batch_Views", 'display_Report');
    {
        ## <insert tests for display_Report method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed QC_Batch_Views test');

exit;
