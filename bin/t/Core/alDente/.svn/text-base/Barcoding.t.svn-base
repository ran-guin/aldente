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
use alDente::Barcoding;
############################

############################################


use_ok("alDente::Barcoding");

if ( !$method || $method=~/\bBarcode_Home\b/ ) {
    can_ok("alDente::Barcoding", 'Barcode_Home');
    {
        ## <insert tests for Barcode_Home method here> ##
    }
}

if ( !$method || $method=~/\brequest_broker\b/ ) {
    can_ok("alDente::Barcoding", 'request_broker');
    {
        ## <insert tests for request_broker method here> ##
    }
}

if ( !$method || $method=~/\bbarcode_options\b/ ) {
    can_ok("alDente::Barcoding", 'barcode_options');
    {
        ## <insert tests for barcode_options method here> ##
    }
}

if ( !$method || $method=~/\bPrintBarcode\b/ ) {
    can_ok("alDente::Barcoding", 'PrintBarcode');
    {
        ## <insert tests for PrintBarcode method here> ##
    }
}

if ( !$method || $method=~/\bequipment_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'equipment_barcode');
    {
        ## <insert tests for equipment_barcode method here> ##
    }
}

if ( !$method || $method=~/\bbarcode_label_form\b/ ) {
    can_ok("alDente::Barcoding", 'barcode_label_form');
    {
        ## <insert tests for barcode_label_form method here> ##
    }
}

if ( !$method || $method=~/\bplate_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'plate_barcode');
    {
        ## <insert tests for plate_barcode method here> ##
    }
}

if ( !$method || $method=~/\btray_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'tray_barcode');
    {
        ## <insert tests for tray_barcode method here> ##
    }
}

if ( !$method || $method=~/\btube_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'tube_barcode');
    {
        ## <insert tests for tube_barcode method here> ##
    }
}

if ( !$method || $method=~/\bbox_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'box_barcode');
    {
        ## <insert tests for box_barcode method here> ##
    }
}

if ( !$method || $method=~/\brack_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'rack_barcode');
    {
        ## <insert tests for rack_barcode method here> ##
    }
}

if ( !$method || $method=~/\bemployee_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'employee_barcode');
    {
        ## <insert tests for employee_barcode method here> ##
    }
}

if ( !$method || $method=~/\bsolution_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'solution_barcode');
    {
        ## <insert tests for solution_barcode method here> ##
    }
}

if ( !$method || $method=~/\bprint_multiple_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'print_multiple_barcode');
    {
        ## <insert tests for print_multiple_barcode method here> ##
    }
}

if ( !$method || $method=~/\bprint_multiple_plate\b/ ) {
    can_ok("alDente::Barcoding", 'print_multiple_plate');
    {
        ## <insert tests for print_multiple_plate method here> ##
    }
}

if ( !$method || $method=~/\bsample_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'sample_barcode');
    {
        ## <insert tests for sample_barcode method here> ##
    }
}

if ( !$method || $method=~/\bsource_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'source_barcode');
    {
        ## <insert tests for source_barcode method here> ##
    }
}

if ( !$method || $method=~/\bbarcode_text\b/ ) {
    can_ok("alDente::Barcoding", 'barcode_text');
    {
        ## <insert tests for barcode_text method here> ##
    }
}

if ( !$method || $method=~/\bprint_slot_barcodes\b/ ) {
    can_ok("alDente::Barcoding", 'print_slot_barcodes');
    {
        ## <insert tests for print_slot_barcodes method here> ##
    }
}

if ( !$method || $method=~/\bprint_simple_large_label\b/ ) {
    can_ok("alDente::Barcoding", 'print_simple_large_label');
    {
        ## <insert tests for print_simple_large_label method here> ##
    }
}

if ( !$method || $method=~/\bprint_simple_small_label\b/ ) {
    can_ok("alDente::Barcoding", 'print_simple_small_label');
    {
        ## <insert tests for print_simple_small_label method here> ##
    }
}

if ( !$method || $method=~/\bprint_simple_tube_label\b/ ) {
    can_ok("alDente::Barcoding", 'print_simple_tube_label');
    {
        ## <insert tests for print_simple_tube_label method here> ##
    }
}

if ( !$method || $method=~/\brun_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'run_barcode');
    {
        ## <insert tests for run_barcode method here> ##
    }
}

if ( !$method || $method=~/\bgelrun_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'gelrun_barcode');
    {
        ## <insert tests for gelrun_barcode method here> ##
    }
}

if ( !$method || $method=~/\bmicroarray_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'microarray_barcode');
    {
        ## <insert tests for microarray_barcode method here> ##
    }
}

if ( !$method || $method=~/\bget_printer\b/ ) {
    can_ok("alDente::Barcoding", 'get_printer');
    {
        ## <insert tests for get_printer method here> ##
    }
}

if ( !$method || $method=~/\bget_printer_DPI\b/ ) {
    can_ok("alDente::Barcoding", 'get_printer_DPI');
    {
        ## <insert tests for get_printer_DPI method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_barcode_image\b/ ) {
    can_ok("alDente::Barcoding", 'generate_barcode_image');
    {
        ## <insert tests for generate_barcode_image method here> ##
    }
}

if ( !$method || $method=~/\bprint_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'print_barcode');
    {
        ## <insert tests for print_barcode method here> ##
    }
}

if ( !$method || $method=~/\b_print\b/ ) {
    can_ok("alDente::Barcoding", '_print');
    {
        ## <insert tests for _print method here> ##
    }
}

if ( !$method || $method=~/\breprint_option\b/ ) {
    can_ok("alDente::Barcoding", 'reprint_option');
    {
        ## <insert tests for reprint_option method here> ##
    }
}

if ( !$method || $method=~/\bbuild_custom_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'build_custom_barcode');
    {
        ## <insert tests for build_custom_barcode method here> ##
    }
}

if ( !$method || $method=~/\bpreview_custom_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'preview_custom_barcode');
    {
        ## <insert tests for preview_custom_barcode method here> ##
    }
}

if ( !$method || $method=~/\bprint_custom_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'print_custom_barcode');
    {
        ## <insert tests for print_custom_barcode method here> ##
    }
}

if ( !$method || $method=~/\bEgel_run_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'Egel_run_barcode');
    {
        ## <insert tests for Egel_run_barcode method here> ##
    }
}

if ( !$method || $method=~/\bAATI_run_batch_barcode\b/ ) {
    can_ok("alDente::Barcoding", 'AATI_run_batch_barcode');
    {
        ## <insert tests for AATI_run_batch_barcode method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Barcoding test');

exit;
