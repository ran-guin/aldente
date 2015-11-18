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
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 
my $dbc;                                 ## only used for modules enabling database connections

############################
use alDente::Invoice_Views;
############################

############################################


use_ok("alDente::Invoice_Views");

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Invoice_Views", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bshow_invoiceable_work\b/ ) {
    can_ok("alDente::Invoice_Views", 'show_invoiceable_work');
    {
        ## <insert tests for show_invoiceable_work method here> ##
    }
}

if ( !$method || $method =~ /\bconfirmation_page\b/ ) {
    can_ok("alDente::Invoice_Views", 'confirmation_page');
    {
        ## <insert tests for confirmation_page method here> ##
    }
}

if ( !$method || $method =~ /\binvoice_page\b/ ) {
    can_ok("alDente::Invoice_Views", 'invoice_page');
    {
        ## <insert tests for invoice_page method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_invoice_btn\b/ ) {
    can_ok("alDente::Invoice_Views", 'generate_invoice_btn');
    {
        ## <insert tests for generate_invoice_btn method here> ##
    }
}

if ( !$method || $method =~ /\bsummary_of_work_table\b/ ) {
    can_ok("alDente::Invoice_Views", 'summary_of_work_table');
    {
        ## <insert tests for summary_of_work_table method here> ##
    }
}

if ( !$method || $method =~ /\btotal_summary_count_table\b/ ) {
    can_ok("alDente::Invoice_Views", 'total_summary_count_table');
    {
        ## <insert tests for total_summary_count_table method here> ##
    }
}

if ( !$method || $method =~ /\bchange_protocol_status_btn\b/ ) {
    can_ok("alDente::Invoice_Views", 'change_protocol_status_btn');
    {
        ## <insert tests for change_protocol_status_btn method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_protocol_btn\b/ ) {
    can_ok("alDente::Invoice_Views", 'create_protocol_btn');
    {
        ## <insert tests for create_protocol_btn method here> ##
    }
}

if ( !$method || $method =~ /\bchange_pipeline_status_btn\b/ ) {
    can_ok("alDente::Invoice_Views", 'change_pipeline_status_btn');
    {
        ## <insert tests for change_pipeline_status_btn method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_pipeline_btn\b/ ) {
    can_ok("alDente::Invoice_Views", 'create_pipeline_btn');
    {
        ## <insert tests for create_pipeline_btn method here> ##
    }
}

if ( !$method || $method =~ /\badd_to_invoice_btn\b/ ) {
    can_ok("alDente::Invoice_Views", 'add_to_invoice_btn');
    {
        ## <insert tests for add_to_invoice_btn method here> ##
    }
}

if ( !$method || $method =~ /\bconfirm_add_to_invoice_btn\b/ ) {
    can_ok("alDente::Invoice_Views", 'confirm_add_to_invoice_btn');
    {
        ## <insert tests for confirm_add_to_invoice_btn method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_into_invoice_btn\b/ ) {
    can_ok("alDente::Invoice_Views", 'create_into_invoice_btn');
    {
        ## <insert tests for create_into_invoice_btn method here> ##
    }
}

if ( !$method || $method =~ /\bremove_from_invoice_btn\b/ ) {
    can_ok("alDente::Invoice_Views", 'remove_from_invoice_btn');
    {
        ## <insert tests for remove_from_invoice_btn method here> ##
    }
}

if ( !$method || $method =~ /\bremove_invoice_btn\b/ ) {
    can_ok("alDente::Invoice_Views", 'remove_invoice_btn');
    {
        ## <insert tests for remove_invoice_btn method here> ##
    }
}

if ( !$method || $method =~ /\bget_confirmation_summary\b/ ) {
    can_ok("alDente::Invoice_Views", 'get_confirmation_summary');
    {
        ## <insert tests for get_confirmation_summary method here> ##
    }
}

if ( !$method || $method =~ /\bget_invoiceable_work_summary\b/ ) {
    can_ok("alDente::Invoice_Views", 'get_invoiceable_work_summary');
    {
        ## <insert tests for get_invoiceable_work_summary method here> ##
    }
}

if ( !$method || $method =~ /\bredirect_to_LC_invoiceable_work_view_btn\b/ ) {
    can_ok("alDente::Invoice_Views", 'redirect_to_LC_invoiceable_work_view_btn');
    {
        ## <insert tests for redirect_to_LC_invoiceable_work_view_btn method here> ##
    }
}

if ( !$method || $method =~ /\bcredit_invoice_btn\b/ ) {
    can_ok("alDente::Invoice_Views", 'credit_invoice_btn');
    {
        ## <insert tests for credit_invoice_btn method here> ##
    }
}

if ( !$method || $method =~ /\bappend_iw_comment_from_invoice_btn\b/ ) {
    can_ok("alDente::Invoice_Views", 'append_iw_comment_from_invoice_btn');
    {
        ## <insert tests for append_iw_comment_from_invoice_btn method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Invoice_Views test');

exit;
