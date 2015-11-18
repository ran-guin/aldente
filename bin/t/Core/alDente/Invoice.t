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
use alDente::Invoice;
############################

############################################


use_ok("alDente::Invoice");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Invoice", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_invoiceable_work_invoiced\b/ ) {
    can_ok("alDente::Invoice", 'check_invoiceable_work_invoiced');
    {
        ## <insert tests for check_invoiceable_work_invoiced here> ##
    }
}

if ( !$method || $method =~ /\bupdate_invoiceable_work_invoice\b/ ) {
    can_ok("alDente::Invoice", 'update_invoiceable_work_invoice');
    {
        ## <insert tests for update_invoiceable_work_invoice here> ##
    }
}

if ( !$method || $method =~ /\bsave_invoice_info\b/ ) {
    can_ok("alDente::Invoice", 'save_invoice_info');
    {
        ## <insert tests for save_invoice_info here> ##
    }
}

if ( !$method || $method =~ /\bsummary_of_work_details\b/ ) {
    can_ok("alDente::Invoice", 'summary_of_work_details');
    {
        ## <insert tests for summary_of_work_details here> ##
    }
}

if ( !$method || $method =~ /\bget_prep_summary\b/ ) {
    can_ok("alDente::Invoice", 'get_prep_summary');
    {
    ## Commented out tests for commit since summaries may not be the same as date test was made (e.g. if additional work for lib is added to invoice, runs no longer pending, etc.)
=cut
        ## <insert tests for get_prep_summary here> ##
        my $invoice = new alDente::Invoice(-dbc => $dbc);	
        my $summary;

        ## Get prep summary given two invoices and any number of libraries
        my @invoice1 = (3055, 2097);
        my @library1 = ('A45620', 'A14969');
        $summary = $invoice->get_prep_summary(-dbc => $dbc, -invoice => \@invoice1, -library => \@library1);
        my @expected_result1 = ("Please select one invoice at a time to see summary of works done on each library.", "Please select one invoice at a time to see summary of works done on each library.");
        is(@$summary, @expected_result1, "Prep Summary returns message 'Please select one invoice at a time to see summary of works done on each library' when 2 invoices are specified. Test 1 expected behaviour.");

        ## Get prep summary given one invoice and any number of libraries
        my @invoice2 = (3055);
        my @library2 = ('A45620', 'A45621');
        $summary = $invoice->get_run_summary(-dbc => $dbc, -invoice => \@invoice2, -library => \@library2);
        my @expected_result2 = ('RD Template Generation,RD Shearing,RD Amplicon Generation,Plate Based Library Construction', 'RD Template Generation,RD Shearing,RD Amplicon Generation,Plate Based Library Construction');
        is(@$summary, @expected_result2, "Run Summary is 'RD Template Generation,RD Shearing,RD Amplicon Generation,Plate Based Library Construction' for 2 specified libraries on invoice 3055. Test 2 expected behaviour.");
=cut
    }
}

if ( !$method || $method =~ /\bget_run_summary\b/ ) {
    can_ok("alDente::Invoice", 'get_run_summary');
    {   
    ## Commented out tests for commit since summaries may not be the same as date test was made (e.g. if additional work for lib is added to invoice, runs no longer pending, etc.)
=cut
        ## <insert tests for get_run_summary here> ##
        my $invoice = new alDente::Invoice(-dbc => $dbc);	
        my $summary;

        ## Case 1: multiple invoices
        my @invoice1 = (3055, 2097);
        my @library1 = ('A45620', 'A14969');
        $summary = $invoice->get_run_summary(-dbc => $dbc, -invoice => \@invoice1, -library => \@library1);
        my @expected_result1;
        is(@$summary, @expected_result1, "Empty array returned when 2 invoices are specified. Case 1 expected behaviour.");

        ## Case 2: one read length, one machine
        my @invoice2 = (2097);
        my @library2 = ('A14969', 'A14972');
        $summary = $invoice->get_run_summary(-dbc => $dbc, -invoice => \@invoice2, -library => \@library2);
        my @expected_result2 = ('1 x 75 bp PET Lane HiSeq', '1 x 75 bp PET Lane HiSeq');
        is(@$summary, @expected_result2, "Run summaries match expected result. Case 2 expected behaviour.");

        ## Case 3: one read length, multiple machines
        my @invoice3 = (1381);
        my @library3 = ('A01975');
        $summary = $invoice->get_run_summary(-dbc => $dbc, -invoice => \@invoice3, -library => \@library3);
        my @expected_result3 = ('1 x 75 bp PET GA-10, 1 x 75 bp PET Lane HiSeq');
        is (@$summary, @expected_result3, "Run Summary matches expected result. Case 3 expected behaviour.");

        ## Case 4: multiple read lengths, one machine
        my @invoice4 = (1381);
        my @library4 = ('A05131');
        $summary = $invoice->get_run_summary(-dbc => $dbc, -invoice => \@invoice4, -library => \@library4);
        my @expected_result4 = ('1 x 50 bp PET Lane HiSeq, 1 x 100 bp PET Lane HiSeq');
        is (@$summary, @expected_result4, "Run summary matches expected result. Case 4 expected behaviour.");

        ## Case 5: multiple read lengths, multiple machines
        my @invoice5 = (1087);
        my @library5 = ('HS0583');
        $summary = $invoice->get_run_summary(-dbc => $dbc, -invoice => \@invoice5, -library => \@library5);
        my @expected_result5 = ('7 x 42 bp PET GA-5, 2 x 42 bp PET GA-8, 7 x 36 bp PET GA-3, 7 x 50 bp PET GA-2');
        is (@$summary, @expected_result5, "Run summary matches expected result. Case 5 expected behaviour.");
        
        ## Case 6: runs pending (only invoiceable run item on invoice)
        my @invoice6 = (1560);
        my @library6 = ('MX0419');
        $summary = $invoice->get_run_summary(-dbc => $dbc, -invoice => \@invoice6, -library => \@library6);
        my @expected_result6 = ('1 x Run(s) Pending');
        is (@$summary, @expected_result6, "Run summary matches expected result. Case 6 expected behaviour.");

        ## Case 7: runs pending (with other invoiceable run items on invoice)
        my @invoice7 = (1074);
        my @library7 = ('HS0583');
        $summary = $invoice->get_run_summary(-dbc => $dbc, -invoice => \@invoice7, -library => \@library7);
        my @expected_result7 = ('1 x 42 bp PET GA-7, 7 x Run(s) Pending');
        is (@$summary, @expected_result7, "Run summary matches expected result. Case 7 expected behaviour.");
=cut
    }
}

if ( !$method || $method =~ /\bget_analysis_summary\b/ ) {
    can_ok("alDente::Invoice", 'get_analysis_summary');
    {
        ## <insert tests for get_analysis_summary here> ##
    }
}

if ( !$method || $method =~ /\badd_invoice_check\b/ ) {
    can_ok("alDente::Invoice", 'add_invoice_check');
    {
        ## <insert tests for add_invoice_check here> ##
    }
}

if ( !$method || $method =~ /\binvoice_protocol_email\b/ ) {
    can_ok("alDente::Invoice", 'invoice_protocol_email');
    {
        ## <insert tests for invoice_protocol_email here> ##
    }
}
if ( !$method || $method =~ /\bis_invoiceable\b/ ) {
    can_ok("alDente::Invoice", 'is_invoiceable');
    {
        ## <insert tests for is_invoiceable method here> ##
    	my $invoiceable = alDente::Invoice::is_invoiceable( -dbc => $dbc, -type => 'protocol', -value => 194 );
    	ok( $invoiceable, 'is_invoiceable');
    }
}

if ( !$method || $method =~ /\bget_total_work_count\b/ ) {
    can_ok("alDente::Invoice", 'get_total_work_count');
    {
        ## <insert tests for get_total_work_count method here> ##
    }
}

if ( !$method || $method =~ /\bget_repeated_protocols\b/ ) {
    can_ok("alDente::Invoice", 'get_repeated_protocols');
    {
        ## <insert tests for get_repeated_protocols method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Invoice test');

exit;
