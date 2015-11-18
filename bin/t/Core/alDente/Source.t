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
use alDente::Source;
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




use_ok("alDente::Source");

my $self = new alDente::Source(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Source", 'new');
    {
        ## <insert tests for new method here> ##
        my $Source = new alDente::Source( -dbc => $dbc, -id => '68281');
        my $id = $Source->value( -field => 'Source_ID' );
        is( $id, '68281', 'new');
    }
}

if ( !$method || $method=~/\bsource_name\b/ ) {
    can_ok("alDente::Source", 'source_name');
    {
        ## <insert tests for source_name method here> ##
    }
}

if ( !$method || $method=~/\bthrow_away_source\b/ ) {
    can_ok("alDente::Source", 'throw_away_source');
    {
        ## <insert tests for throw_away_source method here> ##
    }
}

if ( !$method || $method=~/\bnew_source_trigger\b/ ) {
    can_ok("alDente::Source", 'new_source_trigger');
    {
        my $Source = new alDente::Source( -dbc => $dbc, -id => '39680');
        $Source->new_source_trigger();
        ## <insert tests for new_source_trigger method here> ##
    }
}

if ( !$method || $method=~/\b_update_source_number\b/ ) {
    can_ok("alDente::Source", '_update_source_number');
    {
        ## <insert tests for _update_source_number method here> ##
        my $Source = new alDente::Source( -dbc => $dbc, -id => '39680');
        my $number = $Source->_update_source_number();
        print "maxnum=$number\n";
    }
}

if ( !$method || $method=~/\bload_Object\b/ ) {
    can_ok("alDente::Source", 'load_Object');
    {
        ## <insert tests for load_Object method here> ##
    }
}

if ( !$method || $method=~/\bmake_into_source\b/ ) {
    can_ok("alDente::Source", 'make_into_source');
    {
        ## <insert tests for make_into_source method here> ##
    }
}

if ( !$method || $method=~/\bPool\b/ ) {
    can_ok("alDente::Source", 'Pool');
    {
        ## <insert tests for Pool method here> ##
	    #my $source_obj = alDente::Source->new( -dbc => $dbc );
		#my %info;
        #$info{src_ids}         = '68281,71720';
        #$info{68281}{amnt} = 1;
        #$info{68281}{unit} = 'ul';
        #$info{71720}{amnt} = 1;
        #$info{71720}{unit} = 'ul';
        #my $new_source_id = $source_obj->Pool( -dbc => $dbc, -info => \%info, -no_html => 1, -debug => 0 );
        #ok( $new_source_id );
    }
}

if ( !$method || $method=~/\breceive_source\b/ ) {
    can_ok("alDente::Source", 'receive_source');
    {
        ## <insert tests for receive_source method here> ##
    }
}

if ( !$method || $method=~/\bget_downstream_sources\b/ ) {
    can_ok("alDente::Source", 'get_downstream_sources');
    {
        ## <insert tests for get_downstream_sources method here> ##
    }
}

if ( !$method || $method=~/\bget_libraries\b/ ) {
    can_ok("alDente::Source", 'get_libraries');
    {
        ## <insert tests for get_libraries method here> ##
    }
}

if ( !$method || $method=~/\bget_main_Sample_Type\b/ ) {
    can_ok("alDente::Source", 'get_main_Sample_Type');
    {

        ##test case 1 Xformedcells with find table flag and without 
	my $id = "1192";
	my $sub_dir = $self->get_main_Sample_Type(-id => $id, -dbc => $dbc );
	is($sub_dir,'Cells','Parent of Xformedcells is Cells');
	my $sub_dir = $self->get_main_Sample_Type(-id => $id, -dbc => $dbc, -find_table => 1);
	is($sub_dir,'Xformed_Cells','Output should be Xformedcelss');
        
	##test case for null
	
	my $id = "53";
	my $sub_dir = $self->get_main_Sample_Type(-id => $id, -dbc => $dbc, -find_table => 1);
	is($sub_dir,'','Output should be null');
	
		
	## <insert tests for get_libraries method here> ##
    }
}

if ( !$method || $method=~/\brelated_sources_HTML\b/ ) {
    can_ok("alDente::Source", 'related_sources_HTML');
    {
        ## <insert tests for related_sources_HTML method here> ##
    }
}

if ( !$method || $method=~/\bexport_sources\b/ ) {
    can_ok("alDente::Source", 'export_sources');
    {
        ## <insert tests for export_sources method here> ##
    }
}

if ( !$method || $method=~/\bget_pooled_sample_type\b/ ) {
    can_ok("alDente::Source", 'get_pooled_sample_type');
    {
        ## <insert tests for get_pooled_sample_type method here> ##
        my @src_tissues = $dbc->Table_find( 'Source,Sample_Type', 'Source_ID', "Where FK_Sample_Type__ID = Sample_Type_ID and Source_Status = 'Active' and Sample_Type = 'Tissue' order by Source_ID desc limit 2");
        my ( $src_nucleicAcid ) = $dbc->Table_find( 'Source,Sample_Type', 'Source_ID', "Where FK_Sample_Type__ID = Sample_Type_ID and Source_Status = 'Active' and Sample_Type = 'Nucleic_Acid' order by Source_ID desc limit 1");
        my ( $src_dna ) = $dbc->Table_find( 'Source,Sample_Type', 'Source_ID', "Where FK_Sample_Type__ID = Sample_Type_ID and Source_Status = 'Active' and Sample_Type = 'DNA' order by Source_ID desc limit 1");
        my ( $src_rna ) = $dbc->Table_find( 'Source,Sample_Type', 'Source_ID', "Where FK_Sample_Type__ID = Sample_Type_ID and Source_Status = 'Active' and Sample_Type = 'RNA' order by Source_ID desc limit 1");
        my @src_total_rna = $dbc->Table_find( 'Source,Sample_Type', 'Source_ID', "Where FK_Sample_Type__ID = Sample_Type_ID and Source_Status = 'Active' and Sample_Type = 'Total RNA' order by Source_ID desc limit 2");

        ## 'Tissue' + 'Tissue' -> Tissue
        my $result = $self->get_pooled_sample_type( -dbc => $dbc, -sources => \@src_tissues );
		is( $result,'Tissue','Tissue + Tissue => Tissue');

        ## 'Tissue' + 'Total RNA' -> 'Mixed'
        my $result = $self->get_pooled_sample_type( -dbc => $dbc, -sources => [$src_tissues[0],$src_total_rna[0] ] );
		is( $result,'Mixed','Tissue + Total RNA -> Mixed');
		
        ## 'Nucleic Acid' + 'Nucleic Acid - RNA' -> Nucleic Acid
        my $result = $self->get_pooled_sample_type( -dbc => $dbc, -sources => [$src_nucleicAcid,$src_rna ] );
		is( $result,'Nucleic_Acid','Nucleic_Acid + Nucleic_Acid - RNA -> Nucleic_Acid');
		
        ## 'Nucleic Acid - DNA' + 'Nucleic Acid - RNA' -> Nucleic Acid
        my $result = $self->get_pooled_sample_type( -dbc => $dbc, -sources => [$src_dna,$src_rna ] );
		is( $result,'Nucleic_Acid','Nucleic_Acid - DNA + Nucleic_Acid - RNA -> Nucleic_Acid');

		## 'Nucleic Acid - RNA - Total RNA' + 'Nucleic Acid - RNA' -> 'Nucleic Acid - RNA'
        my $result = $self->get_pooled_sample_type( -dbc => $dbc, -sources => [$src_total_rna[0],$src_rna ] );
		is( $result,'RNA','Nucleic Acid - RNA - Total RNA + Nucleic Acid - RNA -> Nucleic Acid - RNA');

		## 'Nucleic Acid - RNA - Total RNA' + 'Nucleic Acid - RNA - Total RNA' -> 'Nucleic Acid - RNA - Total RNA'
        my $result = $self->get_pooled_sample_type( -dbc => $dbc, -sources => [$src_total_rna[0],$src_total_rna[1] ] );
		is( $result,'Total RNA','Nucleic Acid - RNA - Total RNA + Nucleic Acid - RNA - Total RNA -> Nucleic Acid - RNA - Total RNA');
    }
}

if ( !$method || $method=~/\bget_parent_sample_types\b/ ) {
    can_ok("alDente::Source", 'get_parent_sample_types');
    {
        ## <insert tests for get_parent_sample_types method here> ##
        my @got = $self->get_parent_sample_types( -dbc => $dbc, -type => 'Total RNA' );
        my @expected = ( 'RNA', 'Nucleic_Acid' );
        is_deeply( \@got, \@expected, 'get_parent_sample_types' );
    }
}


if ( !$method || $method =~ /\badd_Source\b/ ) {
    can_ok("alDente::Source", 'add_Source');
    {
        ## <insert tests for add_Source method here> ##
    }
}

if ( !$method || $method =~ /\bsource_type\b/ ) {
    can_ok("alDente::Source", 'source_type');
    {
        ## <insert tests for source_type method here> ##
    }
}

if ( !$method || $method =~ /\binherit_Xenograft\b/ ) {
    can_ok("alDente::Source", 'inherit_Xenograft');
    {
        ## <insert tests for inherit_Xenograft method here> ##
    }
}

if ( !$method || $method =~ /\barray_into_box_btn\b/ ) {
    can_ok("alDente::Source", 'array_into_box_btn');
    {
        ## <insert tests for array_into_box_btn method here> ##
    }
}

if ( !$method || $method =~ /\bmove_to_box_btn\b/ ) {
    can_ok("alDente::Source", 'move_to_box_btn');
    {
        ## <insert tests for move_to_box_btn method here> ##
    }
}

if ( !$method || $method =~ /\bcatch_move_to_box_btn\b/ ) {
    can_ok("alDente::Source", 'catch_move_to_box_btn');
    {
        ## <insert tests for catch_move_to_box_btn method here> ##
    }
}

if ( !$method || $method =~ /\bmove_Rack_page\b/ ) {
    can_ok("alDente::Source", 'move_Rack_page');
    {
        ## <insert tests for move_Rack_page method here> ##
    }
}

if ( !$method || $method =~ /\bnew_library_source_trigger\b/ ) {
    can_ok("alDente::Source", 'new_library_source_trigger');
    {
        ## <insert tests for new_library_source_trigger method here> ##
    }
}

if ( !$method || $method =~ /\b_update_parent_source_volumes\b/ ) {
    can_ok("alDente::Source", '_update_parent_source_volumes');
    {
        ## <insert tests for _update_parent_source_volumes method here> ##
    }
}

if ( !$method || $method =~ /\b_subtract_source_volume\b/ ) {
    can_ok("alDente::Source", '_subtract_source_volume');
    {
        ## <insert tests for _subtract_source_volume method here> ##
    }
}

if ( !$method || $method =~ /\bpropogate_field\b/ ) {
    can_ok("alDente::Source", 'propogate_field');
    {
        ## <insert tests for propogate_field method here> ##
    }
}

if ( !$method || $method =~ /\bconfirm_Source_Libraries\b/ ) {
    can_ok("alDente::Source", 'confirm_Source_Libraries');
    {
        ## <insert tests for confirm_Source_Libraries method here> ##
    }
}

if ( !$method || $method =~ /\bget_source_plates\b/ ) {
    can_ok("alDente::Source", 'get_source_plates');
    {
        ## <insert tests for get_source_plates method here> ##
    }
}

if ( !$method || $method =~ /\b_simplfy_array\b/ ) {
    can_ok("alDente::Source", '_simplfy_array');
    {
        ## <insert tests for _simplfy_array method here> ##
    }
}

if ( !$method || $method =~ /\bsource_label\b/ ) {
    can_ok("alDente::Source", 'source_label');
    {
        ## <insert tests for source_label method here> ##
    }
}

if ( !$method || $method =~ /\bsource_ancestry\b/ ) {
    can_ok("alDente::Source", 'source_ancestry');
    {
        ## <insert tests for source_ancestry method here> ##
    }
}

if ( !$method || $method =~ /\bget_ancestry_tree\b/ ) {
    can_ok("alDente::Source", 'get_ancestry_tree');
    {
        ## <insert tests for get_ancestry_tree method here> ##
        my ($originals, $parents) = $self->get_ancestry_tree( -id => '60513', -no_pools => 0 );
        my $expected_originals = ['60234','60210','60202','60214','60208','60232','60206','60204','60236','60212'];
        my $expected_tree = {
          '60513' => {
                       '60512' => {
                                    '60498' => {
                                                 '60436' => {
                                                              '60210' => 0,
                                                              '60202' => 0,
                                                              '60214' => 0,
                                                              '60208' => 0,
                                                              '60206' => 0,
                                                              '60204' => 0,
                                                              '60212' => 0
                                                            },
                                                 '60442' => {
                                                              '60234' => 0,
                                                              '60232' => 0,
                                                              '60236' => 0
                                                            }
                                               }
                                  }
                     }
        };
        
        require RGTools::RGmath;
        my $xor = RGmath::xor_array( $originals, $expected_originals );
        ok( int(@$xor) == 0, "get_ancestry_tree originals" );
        is_deeply( $parents, $expected_tree, "get_ancestry_tree tree");
    }
}

if ( !$method || $method =~ /\bhome_source\b/ ) {
    can_ok("alDente::Source", 'home_source');
    {
        ## <insert tests for home_source method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_source\b/ ) {
    can_ok("alDente::Source", 'create_source');
    {
        ## <insert tests for create_source method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_pool_source\b/ ) {
    can_ok("alDente::Source", 'create_pool_source');
    {
        ## <insert tests for create_pool_source method here> ##
    }
}

if ( !$method || $method =~ /\bdelete_source\b/ ) {
    can_ok("alDente::Source", 'delete_source');
    {
        ## <insert tests for delete_source method here> ##
    }
}

if ( !$method || $method =~ /\bget_Original_Sources\b/ ) {
    can_ok("alDente::Source", 'get_Original_Sources');
    {
        ## <insert tests for get_Original_Sources method here> ##
    }
}

if ( !$method || $method =~ /\bassociate_library\b/ ) {
    can_ok("alDente::Source", 'associate_library');
    {
        ## <insert tests for associate_library method here> ##
    }
}

if ( !$method || $method =~ /\bbatch_Aliquot\b/ ) {
    can_ok("alDente::Source", 'batch_Aliquot');
    {
        ## <insert tests for batch_Aliquot method here> ##
    }
}

if ( !$method || $method =~ /\bbrief_split_source\b/ ) {
    can_ok("alDente::Source", 'brief_split_source');
    {
        ## <insert tests for brief_split_source method here> ##
    }
}

if ( !$method || $method =~ /\bsplit_source\b/ ) {
    can_ok("alDente::Source", 'split_source');
    {
        ## <insert tests for split_source method here> ##
    }
}

if ( !$method || $method =~ /\bget_offspring\b/ ) {
    can_ok("alDente::Source", 'get_offspring');
    {
        ## <insert tests for get_offspring method here> ##
    }
}

if ( !$method || $method =~ /\bget_source_formats\b/ ) {
    can_ok("alDente::Source", 'get_source_formats');
    {
        ## <insert tests for get_source_formats method here> ##
    }
}

if ( !$method || $method =~ /\bget_offspring_details\b/ ) {
    can_ok("alDente::Source", 'get_offspring_details');
    {
        ## <insert tests for get_offspring_details method here> ##
    }
}

if ( !$method || $method =~ /\bget_siblings\b/ ) {
    can_ok("alDente::Source", 'get_siblings');
    {
        ## <insert tests for get_siblings method here> ##
    }
}

if ( !$method || $method =~ /\bget_associated_libs\b/ ) {
    can_ok("alDente::Source", 'get_associated_libs');
    {
        ## <insert tests for get_associated_libs method here> ##
    }
}

if ( !$method || $method =~ /\brequest_Replacement\b/ ) {
    can_ok("alDente::Source", 'request_Replacement');
    {
        ## <insert tests for request_Replacement method here> ##
    }
}

if ( !$method || $method =~ /\bis_Replacement\b/ ) {
    can_ok("alDente::Source", 'is_Replacement');
    {
        ## <insert tests for is_Replacement method here> ##
    }
}

if ( !$method || $method =~ /\bmerge_OS\b/ ) {
    can_ok("alDente::Source", 'merge_OS');
    {
        ## <insert tests for merge_OS method here> ##
       	my $on_conflict;
        my %unresolved;
        my $target_OS = alDente::Source::merge_OS( -dbc => $dbc, -source_id => [60184,60185], -unresolved => \%unresolved, -on_conflict => $on_conflict );
        
    }
}

if ( !$method || $method =~ /\bgetSource_IDs\b/ ) {
    can_ok("alDente::Source", 'getSource_IDs');
    {
        ## <insert tests for merge_OS method here> ##
	
	my $input = '71385';
	my $source = alDente::Source::getSource_IDs(-dbc => $dbc, -source => $input);
	print "\n input: $input \n Source: $source\n\n";
    }
}

if ( !$method || $method =~ /\bmerge_sources\b/ ) {
    can_ok("alDente::Source", 'merge_sources');
    {
        ## <insert tests for merge_sources method here> ##
        
        my %assign = ( 
        	'FK_Plate_Format__ID' => '44', 
        	'FK_Barcode_Label__ID' => '17',
        	'FKReceived_Employee__ID'	=> '276',
        	'FKCreated_Employee__ID'	=> '276'
        );
        my $new_id = alDente::Source::merge_sources( -dbc => $dbc, -from_sources => '81967,81968', -assign => \%assign );
        ok( $new_id, 'merge_sources' );
    }
}

if ( !$method || $method =~ /\binitialize_pool_config\b/ ) {
    can_ok("alDente::Source", 'initialize_pool_config');
    {
        ## <insert tests for initialize_pool_config method here> ##
        my $config = alDente::Source::initialize_pool_config( -dbc => $dbc );
        ok( defined $config->{assign} && defined $config->{input} && defined $config->{on_conflict}, 'initialize_pool_config' );
    }
}

if ( !$method || $method =~ /\bget_pool_config\b/ ) {
    can_ok("alDente::Source", 'get_pool_config');
    {
        ## <insert tests for get_pool_config method here> ##
        ( $assign, $input, $on_conflict ) = alDente::Source::get_pool_config( -dbc => $dbc );
        ok( $assign && defined $input && $on_conflict, 'initialize_pool_config' );
    }
}


## END of TEST ##

ok( 1 ,'Completed Source test');

exit;
