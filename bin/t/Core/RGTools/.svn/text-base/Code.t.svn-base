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
use RGTools::Code;
############################
############################################################
use_ok("RGTools::Code");

my $self = new Code();
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("Code", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bload_code\b/ ) {
    can_ok("Code", 'load_code');
    {
        ## <insert tests for load_code method here> ##
    }
}

if ( !$method || $method=~/\bdescription\b/ ) {
    can_ok("Code", 'description');
    {
        ## <insert tests for description method here> ##
    }
}

if ( !$method || $method=~/\bdefine_custom_modules\b/ ) {
    can_ok("Code", 'define_custom_modules');
    {
        ## <insert tests for define_custom_modules method here> ##
    }
}

if ( !$method || $method=~/\bparse_perldoc\b/ ) {
    can_ok("Code", 'parse_perldoc');
    {
        ## <insert tests for parse_perldoc method here> ##
    }
}

if ( !$method || $method=~/\bget_attributes\b/ ) {
    can_ok("Code", 'get_attributes');
    {
        ## <insert tests for get_attributes method here> ##
    }
}

if ( !$method || $method=~/\bget_methods\b/ ) {
    can_ok("Code", 'get_methods');
    {
        ## <insert tests for get_methods method here> ##
    }
}

if ( !$method || $method=~/\bget_blocks\b/ ) {
    can_ok("Code", 'get_blocks');
    {
        ## <insert tests for get_blocks method here> ##
    }
}

if ( !$method || $method=~/\bparse_blocks\b/ ) {
    can_ok("Code", 'parse_blocks');
    {
        ## <insert tests for parse_blocks method here> ##
    }
}

if ( !$method || $method=~/\bparse_sub\b/ ) {
    can_ok("Code", 'parse_sub');
    {
        ## <insert tests for parse_sub method here> ##
    }
}

if ( !$method || $method=~/\bget_sub_name\b/ ) {
    can_ok("Code", 'get_sub_name');
    {
        ## <insert tests for get_sub_name method here> ##
    }
}

if ( !$method || $method=~/\bget_sub_description_and_code_snip\b/ ) {
    can_ok("Code", 'get_sub_description_and_code_snip');
    {
        ## <insert tests for get_sub_description_and_code_snip method here> ##
    }
}

if ( !$method || $method=~/\bget_sub_type\b/ ) {
    can_ok("Code", 'get_sub_type');
    {
        ## <insert tests for get_sub_type method here> ##
    }
}

if ( !$method || $method=~/\bget_sub_arguments\b/ ) {
    can_ok("Code", 'get_sub_arguments');
    {
        ## <insert tests for get_sub_arguments method here> ##
    }
}

if ( !$method || $method=~/\bparse_non_sub\b/ ) {
    can_ok("Code", 'parse_non_sub');
    {
        ## <insert tests for parse_non_sub method here> ##
    }
}

if ( !$method || $method=~/\bget_perl_interpreter\b/ ) {
    can_ok("Code", 'get_perl_interpreter');
    {
        ## <insert tests for get_perl_interpreter method here> ##
    }
}

if ( !$method || $method=~/\bbuild_perldoc_header_and_footer\b/ ) {
    can_ok("Code", 'build_perldoc_header_and_footer');
    {
        ## <insert tests for build_perldoc_header_and_footer method here> ##
    }
}

if ( !$method || $method=~/\bget_package_definition\b/ ) {
    can_ok("Code", 'get_package_definition');
    {
        ## <insert tests for get_package_definition method here> ##
    }
}

if ( !$method || $method=~/\bget_system_variables\b/ ) {
    can_ok("Code", 'get_system_variables');
    {
        ## <insert tests for get_system_variables method here> ##
    }
}

if ( !$method || $method=~/\bget_superclasses\b/ ) {
    can_ok("Code", 'get_superclasses');
    {
        ## <insert tests for get_superclasses method here> ##
    }
}

if ( !$method || $method=~/\bget_modules_ref\b/ ) {
    can_ok("Code", 'get_modules_ref');
    {
        ## <insert tests for get_modules_ref method here> ##
    }
}

if ( !$method || $method=~/\bget_global_vars\b/ ) {
    can_ok("Code", 'get_global_vars');
    {
        ## <insert tests for get_global_vars method here> ##
    }
}

if ( !$method || $method=~/\bget_modular_vars_and_constants\b/ ) {
    can_ok("Code", 'get_modular_vars_and_constants');
    {
        ## <insert tests for get_modular_vars_and_constants method here> ##
    }
}

if ( !$method || $method=~/\bget_main\b/ ) {
    can_ok("Code", 'get_main');
    {
        ## <insert tests for get_main method here> ##
    }
}

if ( !$method || $method=~/\bget_comments\b/ ) {
    can_ok("Code", 'get_comments');
    {
        ## <insert tests for get_comments method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_code\b/ ) {
    can_ok("Code", 'generate_code');
    {
        ## <insert tests for generate_code method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_perldoc\b/ ) {
    can_ok("Code", 'generate_perldoc');
    {
        ## <insert tests for generate_perldoc method here> ##
    }
}

if ( !$method || $method=~/\bsave_code\b/ ) {
    can_ok("Code", 'save_code');
    {
        ## <insert tests for save_code method here> ##
    }
}

if ( !$method || $method=~/\b_get_attributes\b/ ) {
    can_ok("Code", '_get_attributes');
    {
        ## <insert tests for _get_attributes method here> ##
    }
}

if ( !$method || $method=~/\b_section_label\b/ ) {
    can_ok("Code", '_section_label');
    {
        ## <insert tests for _section_label method here> ##
    }
}

if ( !$method || $method =~ /\bget_run_modes\b/ ) {
    can_ok("Code", 'get_run_modes');
    {
        ## <insert tests for get_run_modes method here> ##
        my $file = $FindBin::RealBin . "/../../../../lib/perl/Core/SDB/Import_App.pm";
        my $Run_Modes = Code::get_run_modes($file);
        is($Run_Modes->{'Import'}, 'import_file', 'found basic Import App');
    
    }
}

## END of TEST ##

ok( 1 ,'Completed Code test');

exit;
