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
use alDente::Sample;
############################

############################################


use_ok("alDente::Sample");

my $self = new alDente::Sample(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Sample", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bload_Object\b/ ) {
    can_ok("alDente::Sample", 'load_Object');
    {
        ## <insert tests for load_Object method here> ##
    }
}

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::Sample", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\bget_sample_id\b/ ) {
    can_ok("alDente::Sample", 'get_sample_id');
    {
        ## <insert tests for get_sample_id method here> ##
    }
}

if ( !$method || $method=~/\bget_sample_alias\b/ ) {
    can_ok("alDente::Sample", 'get_sample_alias');
    {
        ## <insert tests for get_sample_alias method here> ##
    }
}


if ( !$method || $method=~/\bid_by_Plate\b/ ) {
    can_ok("alDente::Sample", 'id_by_Plate');
    {
        ## <insert tests for id_by_Plate method here> ##
    }
}

if ( !$method || $method=~/\bid_by_Name\b/ ) {
    can_ok("alDente::Sample", 'id_by_Name');
    {
        ## <insert tests for id_by_Name method here> ##
    }
}

if ( !$method || $method=~/\bid_by_Run\b/ ) {
    can_ok("alDente::Sample", 'id_by_Run');
    {
        ## <insert tests for id_by_Run method here> ##
    }
}

if ( !$method || $method=~/\bquery_sample_block\b/ ) {
    can_ok("alDente::Sample", 'query_sample_block');
    {
        ## <insert tests for query_sample_block method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_samples\b/ ) {
    can_ok("alDente::Sample", 'create_samples');
    {
        ## <insert tests for create_samples method here> ##
    }
}

if ( !$method || $method =~ /\bget_Parent_Sample\b/ ) {
    can_ok("alDente::Sample", 'get_Parent_Sample');
    {
        ## <insert tests for get_Parent_Sample method here> ##
        
        is(alDente::Sample::get_Parent_Sample(-dbc=>$dbc,-source_id=>19866), 15629907, 'found proper parent sample');
        is(alDente::Sample::get_Parent_Sample(-dbc=>$dbc,-source_id=>19866,-well=>'N/A'), 15629907, 'found proper parent sample');
        is(alDente::Sample::get_Parent_Sample(-dbc=>$dbc,-source_id=>20641), undef, 'found nothing from pooled target sample');

    }
}

if ( !$method || $method =~ /\bcreate_samples2\b/ ) {
    can_ok("alDente::Sample", 'create_samples2');
    {
        ## <insert tests for create_samples2 method here> ##
    }
}

if ( !$method || $method =~ /\bshow_sample_data\b/ ) {
    can_ok("alDente::Sample", 'show_sample_data');
    {
        ## <insert tests for show_sample_data method here> ##
    }
}

if ( !$method || $method =~ /\bmix_Sample_types\b/ ) {
    can_ok("alDente::Sample", 'mix_Sample_types');
    {
        ## <insert tests for mix_Sample_types method here> ##
    }
}

if ( !$method || $method =~ /\bfind_common_Sample_Type_Parent\b/ ) {
    can_ok("alDente::Sample", 'find_common_Sample_Type_Parent');
    {
        ## Setting UP Values ##
        my $found = $dbc -> Table_find('Sample_Type','Sample_Type_ID',"WHERE Sample_Type = 'BB'");
        my $A;
	my $B;
	my $AA;
	my $AB;
	my $AAA;
	my $BB;
        if (!$found) {
            my @fields = ('Sample_Type','FKParent_Sample_Type__ID');
            $A   = $dbc->Table_append_array( "Sample_Type", \@fields,['A',0],    -autoquote => 1 );
            $B   = $dbc->Table_append_array( "Sample_Type", \@fields,['B',0],    -autoquote => 1 );
            $AA  = $dbc->Table_append_array( "Sample_Type", \@fields,['AA',$A],  -autoquote => 1 );
            $AB  = $dbc->Table_append_array( "Sample_Type", \@fields,['AB',$A],  -autoquote => 1 );
            $AAA = $dbc->Table_append_array( "Sample_Type", \@fields,['AAA',$AA],-autoquote => 1 );
            $BB  = $dbc->Table_append_array( "Sample_Type", \@fields,['BB',$B],  -autoquote => 1 );
        }
        
        my ($common_parent_id, $common_parent_name) = $self -> find_common_Sample_Type_Parent (-dbc => $dbc, -first => 'A-AA', -second => 'A-AA-AAA');
        is( $common_parent_name, 'AA', 'AA - AAA');
        my ($common_parent_id, $common_parent_name) = $self -> find_common_Sample_Type_Parent (-dbc => $dbc, -first => 'A-AB', -second => 'A-AA-AAA');
        is( $common_parent_name, 'A', ' AB - AAA');
        my ($common_parent_id, $common_parent_name) = $self -> find_common_Sample_Type_Parent (-dbc => $dbc, -first => 'A-AB', -second => 'B-BB');
        is( $common_parent_name, 'Mix', 'should not find');

        my $ok = $dbc->delete_records( -table => 'Sample_Type', -id_list=> $AAA, -field=> 'Sample_Type_ID');
        my $ok = $dbc->delete_records( -table => 'Sample_Type', -id_list=> $AA, -field=> 'Sample_Type_ID');
        my $ok = $dbc->delete_records( -table => 'Sample_Type', -id_list=> $AB, -field=> 'Sample_Type_ID');
        my $ok = $dbc->delete_records( -table => 'Sample_Type', -id_list=> $BB, -field=> 'Sample_Type_ID');
        my $ok = $dbc->delete_records( -table => 'Sample_Type', -id_list=> $A, -field=> 'Sample_Type_ID');
        my $ok = $dbc->delete_records( -table => 'Sample_Type', -id_list=> $B, -field=> 'Sample_Type_ID');

    }
}

if ( !$method || $method =~ /\bget_Ancestry_Array\b/ ) {
    can_ok("alDente::Sample", 'get_Ancestry_Array');
    {
        ## <insert tests for get_Ancestry_Array method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Sample test');

exit;
