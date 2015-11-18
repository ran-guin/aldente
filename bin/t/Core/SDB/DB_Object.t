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
use SDB::DB_Object;
############################
my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("SDB::DB_Object");

if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("SDB::DB_Object", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bAUTOLOADxx\b/ ) {
    can_ok("SDB::DB_Object", 'AUTOLOADxx');
    {
        ## <insert tests for AUTOLOADxx method here> ##
    }
}

if ( !$method || $method=~/\bdbh\b/ ) {
    can_ok("SDB::DB_Object", 'dbh');
    {
        ## <insert tests for dbh method here> ##
    }
}

if ( !$method || $method=~/\bget\b/ ) {
    can_ok("SDB::DB_Object", 'get');
    {
        ## <insert tests for get method here> ##
    }
}

if ( !$method || $method=~/\bset\b/ ) {
    can_ok("SDB::DB_Object", 'set');
    {
        ## <insert tests for set method here> ##
    }
}

if ( !$method || $method=~/\bload_object_from_form\b/ ) {
    can_ok("SDB::DB_Object", 'load_object_from_form');
    {
        ## <insert tests for load_object_from_form method here> ##
    }
}

if ( !$method || $method=~/\bload_object_from_XML\b/ ) {
    can_ok("SDB::DB_Object", 'load_object_from_XML');
    {
        ## <insert tests for load_object_from_XML method here> ##
    }
}

if ( !$method || $method=~/\bdump_to_XML\b/ ) {
    can_ok("SDB::DB_Object", 'dump_to_XML');
    {
        ## <insert tests for dump_to_XML method here> ##
    }
}

if ( !$method || $method=~/\bget_data\b/ ) {
    can_ok("SDB::DB_Object", 'get_data');
    {
        ## <insert tests for get_data method here> ##
    }
}

if ( !$method || $method=~/\bget_list\b/ ) {
    can_ok("SDB::DB_Object", 'get_list');
    {
        ## <insert tests for get_list method here> ##
    }
}

if ( !$method || $method=~/\bget_record\b/ ) {
    can_ok("SDB::DB_Object", 'get_record');
    {
        ## <insert tests for get_record method here> ##
    }
}

if ( !$method || $method=~/\bload_attributes\b/ ) {
    can_ok("SDB::DB_Object", 'load_attributes');
    {
        ## <insert tests for load_attributes method here> ##
    }
}

if ( !$method || $method=~/\bget_attribute_record\b/ ) {
    can_ok("SDB::DB_Object", 'get_attribute_record');
    {
        ## <insert tests for get_attribute_record method here> ##
    }
}

if ( !$method || $method=~/\bnext_record\b/ ) {
    can_ok("SDB::DB_Object", 'next_record');
    {
        ## <insert tests for next_record method here> ##
    }
}

if ( !$method || $method=~/\bget_next\b/ ) {
    can_ok("SDB::DB_Object", 'get_next');
    {
        ## <insert tests for get_next method here> ##
    }
}

if ( !$method || $method=~/\bload_Object\b/ ) {
    can_ok("SDB::DB_Object", 'load_Object');
    {
        ## <insert tests for load_Object method here> ##
    }
}

if ( !$method || $method=~/\binsert\b/ ) {
    can_ok("SDB::DB_Object", 'insert');
    {
        ## <insert tests for insert method here> ##
    }
}

if ( !$method || $method=~/\bupdate\b/ ) {
    can_ok("SDB::DB_Object", 'update');
    {
        ## <insert tests for update method here> ##
    }
}

if ( !$method || $method=~/\bdelete\b/ ) {
    can_ok("SDB::DB_Object", 'delete');
    {
        ## <insert tests for delete method here> ##
    }
}

if ( !$method || $method=~/\bdb_table\b/ ) {
    can_ok("SDB::DB_Object", 'db_table');
    {
        ## <insert tests for db_table method here> ##
    }
}

if ( !$method || $method=~/\bprimary_fields\b/ ) {
    can_ok("SDB::DB_Object", 'primary_fields');
    {
        ## <insert tests for primary_fields method here> ##
    }
}

if ( !$method || $method=~/\bprimary_field\b/ ) {
    can_ok("SDB::DB_Object", 'primary_field');
    {
        ## <insert tests for primary_field method here> ##
    }
}

if ( !$method || $method=~/\bprimary_values\b/ ) {
    can_ok("SDB::DB_Object", 'primary_values');
    {
        ## <insert tests for primary_values method here> ##
    }
}

if ( !$method || $method=~/\bprimary_value\b/ ) {
    can_ok("SDB::DB_Object", 'primary_value');
    {
        ## <insert tests for primary_value method here> ##
    }
}

if ( !$method || $method=~/\badd_tables\b/ ) {
    can_ok("SDB::DB_Object", 'add_tables');
    {
        ## <insert tests for add_tables method here> ##
    }
}

if ( !$method || $method=~/\bleft_join\b/ ) {
    can_ok("SDB::DB_Object", 'left_join');
    {
        ## <insert tests for left_join method here> ##
    }
}

if ( !$method || $method=~/\bfields\b/ ) {
    can_ok("SDB::DB_Object", 'fields');
    {
        ## <insert tests for fields method here> ##
    }
}

if ( !$method || $method=~/\bfields_info\b/ ) {
    can_ok("SDB::DB_Object", 'fields_info');
    {
        ## <insert tests for fields_info method here> ##
    }
}

if ( !$method || $method=~/\bvalue\b/ ) {
    can_ok("SDB::DB_Object", 'value');
    {
        ## <insert tests for value method here> ##
    }
}

if ( !$method || $method=~/\bvalues\b/ ) {
    can_ok("SDB::DB_Object", 'values');
    {
        ## <insert tests for values method here> ##
    }
}

if ( !$method || $method=~/\bset_multi_values\b/ ) {
    can_ok("SDB::DB_Object", 'set_multi_values');
    {
        ## <insert tests for set_multi_values method here> ##
    }
}

if ( !$method || $method=~/\bexist\b/ ) {
    can_ok("SDB::DB_Object", 'exist');
    {
        ## <insert tests for exist method here> ##
    }
}

if ( !$method || $method=~/\bclone\b/ ) {
    can_ok("SDB::DB_Object", 'clone');
    {
        ## <insert tests for clone method here> ##
    }
}

if ( !$method || $method=~/\bsort_object\b/ ) {
    can_ok("SDB::DB_Object", 'sort_object');
    {
        ## <insert tests for sort_object method here> ##
    }
}

if ( !$method || $method=~/\bget_attributes\b/ ) {
    can_ok("SDB::DB_Object", 'get_attributes');
    {
        ## <insert tests for get_attributes method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_Record\b/ ) {
    can_ok("SDB::DB_Object", 'display_Record');
    {
        ## <insert tests for display_Record method here> ##
    }
}

if ( !$method || $method=~/\brecord_count\b/ ) {
    can_ok("SDB::DB_Object", 'record_count');
    {
        ## <insert tests for record_count method here> ##
    }
}

if ( !$method || $method=~/\bnewids\b/ ) {
    can_ok("SDB::DB_Object", 'newids');
    {
        ## <insert tests for newids method here> ##
    }
}

if ( !$method || $method=~/\bno_joins\b/ ) {
    can_ok("SDB::DB_Object", 'no_joins');
    {
        ## <insert tests for no_joins method here> ##
    }
}

if ( !$method || $method=~/\bfield_alias\b/ ) {
    can_ok("SDB::DB_Object", 'field_alias');
    {
        ## <insert tests for field_alias method here> ##
    }
}

if ( !$method || $method=~/\binherit_Attribute\b/ ) {
    can_ok("SDB::DB_Object", 'inherit_Attribute');
    {
        ## <insert tests for inherit_Attribute method here> ##
    }
}

if ( !$method || $method=~/\bget_join_conditions\b/ ) {
    can_ok("SDB::DB_Object", 'get_join_conditions');
    {
        ## <insert tests for get_join_conditions method here> ##
    }
}

if ( !$method || $method=~/\b_initialize\b/ ) {
    can_ok("SDB::DB_Object", '_initialize');
    {
        ## <insert tests for _initialize method here> ##
    }
}

if ( !$method || $method=~/\b_resolve_field\b/ ) {
    can_ok("SDB::DB_Object", '_resolve_field');
    {
        ## <insert tests for _resolve_field method here> ##
    }
}

if ( !$method || $method=~/\b_set_defaults\b/ ) {
    can_ok("SDB::DB_Object", '_set_defaults');
    {
        ## <insert tests for _set_defaults method here> ##
    }
}

if ( !$method || $method=~/\b_get_indices\b/ ) {
    can_ok("SDB::DB_Object", '_get_indices');
    {
        ## <insert tests for _get_indices method here> ##
    }
}

if ( !$method || $method=~/\b_update_record_count\b/ ) {
    can_ok("SDB::DB_Object", '_update_record_count');
    {
        ## <insert tests for _update_record_count method here> ##
    }
}

if ( !$method || $method=~/\b_check_inclusion\b/ ) {
    can_ok("SDB::DB_Object", '_check_inclusion');
    {
        ## <insert tests for _check_inclusion method here> ##
    }
}

if ( !$method || $method=~/\b_get_DBfields\b/ ) {
    can_ok("SDB::DB_Object", '_get_DBfields');
    {
        ## <insert tests for _get_DBfields method here> ##
    }
}

if ( !$method || $method=~/\b_get_FK_tables\b/ ) {
    can_ok("SDB::DB_Object", '_get_FK_tables');
    {
        ## <insert tests for _get_FK_tables method here> ##
    }
}
if ( !$method || $method=~/\binherit_Attribute\b/ ) {
    can_ok("SDB::DB_Object", 'inherit_Attribute');
    {
        my $db_obj =  SDB::DB_Object->new( -dbc => $dbc,-tables=>'Source'); 
        my ($source_info) = $dbc->Table_find('Source','Source_ID,FKParent_Source__ID',"WHERE FKParent_Source__ID > 0",-limit=>1);
        my ($child_source,$parent_source) = split ',', $source_info;
        my $source_attribute = $dbc->Table_append_array('Source_Attribute',['FK_Source__ID','FK_Attribute__ID','Attribute_Value','FK_Employee__ID','Set_DateTime'],[$parent_source,388,2,141,'2011-03-31'],-autoquote=>1); 
        $db_obj -> inherit_Attribute(-child_ids => $child_source , -parent_ids=>$parent_source , -tables => 'Source',-conflict=> 'ignore'); 
        
        $db_obj -> inherit_Attribute(-child_ids => $child_source , -parent_ids=>$parent_source , -tables => 'Source',-conflict=> 'ignore');
        my $case_deleted = $dbc->delete_records( -table => 'Source_Attribute', -dfield => 'Source_Attribute_ID', -id_list => $source_attribute );
    }
}

if ( !$method || $method =~ /\bdbc\b/ ) {
    can_ok("SDB::DB_Object", 'dbc');
    {
        ## <insert tests for dbc method here> ##
    }
}

if ( !$method || $method =~ /\bno_join\b/ ) {
    can_ok("SDB::DB_Object", 'no_join');
    {
        ## <insert tests for no_join method here> ##
    }
}

if ( !$method || $method =~ /\bpropogate_field\b/ ) {
    can_ok("SDB::DB_Object", 'propogate_field');
    {
        ## <insert tests for propogate_field method here> ##
    }
}

if ( !$method || $method =~ /\binherit_attributes_between_objects\b/ ) {
    can_ok("SDB::DB_Object", 'inherit_attributes_between_objects');
    {
        ## <insert tests for inherit_attributes_between_objects method here> ##
        my @shared = sort (grep /^WGA/, @{SDB::DB_Object::inherit_attributes_between_objects(-dbc=>$dbc, -source=>'Source',-target=>'Plate')} );
        is_deeply(\@shared,['WGA_Concentration','WGA_Concentration_Measured_by','WGA_Concentration_Units'],'Found similar WGA fields between S, Pla');
    }
}

## END of TEST ##

ok( 1 ,'Completed DB_Object test');

exit;
