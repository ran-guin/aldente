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
use alDente::Container;
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




use_ok("alDente::Container");

my $self = new alDente::Container(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Container", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bnew_container_trigger\b/ ) {
    can_ok("alDente::Container", 'new_container_trigger');
    {
        ## <insert tests for new_container_trigger method here> ##
        #my @plates_ids = ('531389');
        #my @plate_ids = ('531389','531390','531391','531392','531393','531394','531395','531396','531397','531398','531399','531400','531401','531402','531403','531404','531405','531406','531407','531408','531409','531410','531411','531412','531413','531414','531415','531416','531417','531418','531419','531420','531421','531422','531423','531424','531425','531426','531427','531428','531429','531430','531431','531432','531433','531434','531435','531436','531437','531438','531439','531440','531441','531442','531443','531444','531445','531446','531447','531448','531449','531450','531451','531452','531453','531454','531455','531456','531457','531458','531459','531460','531461','531462','531463','531464','531465','531466','531467','531468','531469','531470','531471','531472','531473','531474','531475','531476','531477','531478','531479','531480');
        my @plate_ids = ('531389','531390','531391');
		$Benchmark{"start new_container_trigger"} = new Benchmark();
        foreach my $id ( @plate_ids ) {
        	my $obj = new alDente::Container(-dbc=>$dbc,-id=>$id,-quick_load=>1);
        	$obj->new_container_trigger();
        }
		$Benchmark{"end new_container_trigger"} = new Benchmark();
    }
}

if ( !$method || $method=~/\bprompt_for_content_details\b/ ) {
    can_ok("alDente::Container", 'prompt_for_content_details');
    {
        ## <insert tests for prompt_for_content_details method here> ##
    }
}

if ( !$method || $method=~/\bload_Object\b/ ) {
    can_ok("alDente::Container", 'load_Object');
    {
        ## <insert tests for load_Object method here> ##
    }
}

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::Container", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\bDisplay_Input\b/ ) {
    can_ok("alDente::Container", 'Display_Input');
    {
        ## <insert tests for Display_Input method here> ##
    }
}

if ( !$method || $method=~/\b_init_table\b/ ) {
    can_ok("alDente::Container", '_init_table');
    {
        ## <insert tests for _init_table method here> ##
    }
}





if ( !$method || $method=~/\bget_prev_gen\b/ ) {
    can_ok("alDente::Container", 'get_prev_gen');
    {
        ## <insert tests for get_prev_gen method here> ##
    }
}

if ( !$method || $method=~/\bget_next_gen\b/ ) {
    can_ok("alDente::Container", 'get_next_gen');
    {
        ## <insert tests for get_next_gen method here> ##
    }
}

if ( !$method || $method=~/\bplate_icon\b/ ) {
    can_ok("alDente::Container", 'plate_icon');
    {
        ## <insert tests for plate_icon method here> ##
    }
}

if ( !$method || $method=~/\binherit_attributes\b/ ) {
    can_ok("alDente::Container", 'inherit_attributes');
    {
        ## <insert tests for inherit_attributes method here> ##
    }
}

if ( !$method || $method=~/\bupdate_plate_info\b/ ) {
    can_ok("alDente::Container", 'update_plate_info');
    {
        ## <insert tests for update_plate_info method here> ##
    }
}









if ( !$method || $method=~/\bget_source\b/ ) {
    can_ok("alDente::Container", 'get_source');
    {
        ## <insert tests for get_source method here> ##
    }
}

if ( !$method || $method=~/\bobsolete_add_Record\b/ ) {
    can_ok("alDente::Container", 'obsolete_add_Record');
    {
        ## <insert tests for obsolete_add_Record method here> ##
    }
}

if ( !$method || $method=~/\blink_source_details\b/ ) {
    can_ok("alDente::Container", 'link_source_details');
    {
        ## <insert tests for link_source_details method here> ##
    }
}



if ( !$method || $method=~/\bget_Solutions\b/ ) {
    can_ok("alDente::Container", 'get_Solutions');
    {
        ## <insert tests for get_Solutions method here> ##
    }
}

if ( !$method || $method=~/\bget_Applications\b/ ) {
    can_ok("alDente::Container", 'get_Applications');
    {
        ## <insert tests for get_Applications method here> ##
    }
}



if ( !$method || $method=~/\bget_Preps\b/ ) {
    can_ok("alDente::Container", 'get_Preps');
    {
        ## <insert tests for get_Preps method here> ##
    }
}

if ( !$method || $method=~/\bget_Sample\b/ ) {
    can_ok("alDente::Container", 'get_Sample');
    {
        ## <insert tests for get_Sample method here> ##
    }
}

if ( !$method || $method=~/\bget_protocol_history\b/ ) {
    can_ok("alDente::Container", 'get_protocol_history');
    {
        ## <insert tests for get_protocol_history method here> ##
    }
}




if ( !$method || $method=~/\bsave_Container\b/ ) {
    can_ok("alDente::Container", 'save_Container');
    {
        ## <insert tests for save_Container method here> ##
    }
}



if ( !$method || $method=~/\bget_recent_ids\b/ ) {
    can_ok("alDente::Container", 'get_recent_ids');
    {
        ## <insert tests for get_recent_ids method here> ##
    }
}

if ( !$method || $method=~/\bget_Prep_mates\b/ ) {
    can_ok("alDente::Container", 'get_Prep_mates');
    {
        ## <insert tests for get_Prep_mates method here> ##
    }
}

if ( !$method || $method=~/\bget_Sets\b/ ) {
    can_ok("alDente::Container", 'get_Sets');
    {
        ## <insert tests for get_Sets method here> ##
    }
}

if ( !$method || $method=~/\bget_Parents\b/ ) {
    can_ok("alDente::Container", 'get_Parents');
    {
        ## <insert tests for get_Parents method here> ##
    }
}

if ( !$method || $method=~/\bget_Siblings\b/ ) {
    can_ok("alDente::Container", 'get_Siblings');
    {
        ## <insert tests for get_Siblings method here> ##
    }
}

if ( !$method || $method=~/\bget_Children\b/ ) {
    can_ok("alDente::Container", 'get_Children');
    {
        ## <insert tests for get_Children method here> ##
    }
}

if ( !$method || $method=~/\bget_Notes\b/ ) {
    can_ok("alDente::Container", 'get_Notes');
    {
        ## <insert tests for get_Notes method here> ##
    }
}

if ( !$method || $method=~/\bget_Reagents\b/ ) {
    can_ok("alDente::Container", 'get_Reagents');
    {
        ## <insert tests for get_Reagents method here> ##
    }
}

if ( !$method || $method=~/\bwithdraw_sample\b/ ) {
    can_ok("alDente::Container", 'withdraw_sample');
    {
        ## <insert tests for withdraw_sample method here> ##
    }
}

if ( !$method || $method=~/\bget_remaining_quantity\b/ ) {
    can_ok("alDente::Container", 'get_remaining_quantity');
    {
        ## <insert tests for get_remaining_quantity method here> ##
    }
}

if ( !$method || $method=~/\bget_Plate_notes\b/ ) {
    can_ok("alDente::Container", 'get_Plate_notes');
    {
        ## <insert tests for get_Plate_notes method here> ##
    }
}

if ( !$method || $method=~/\bDelete_Container\b/ ) {
    can_ok("alDente::Container", 'Delete_Container');
    {
        ## <insert tests for Delete_Container method here> ##
    }
}

if ( !$method || $method=~/\b_delete\b/ ) {
    can_ok("alDente::Container", '_delete');
    {
        ## <insert tests for _delete method here> ##
    }
}

if ( !$method || $method=~/\badd_Note\b/ ) {
    can_ok("alDente::Container", 'add_Note');
    {
        ## <insert tests for add_Note method here> ##
    }
}

if ( !$method || $method=~/\bfail_container\b/ ) {
    can_ok("alDente::Container", 'fail_container');
    {
        ## <insert tests for fail_container method here> ##
    }
}

if ( !$method || $method=~/\bconfirm_fail\b/ ) {
    can_ok("alDente::Container", 'confirm_fail');
    {
        ## <insert tests for confirm_fail method here> ##
    }
}



if ( !$method || $method=~/\bmove\b/ ) {
    can_ok("alDente::Container", 'move');
    {
        ## <insert tests for move method here> ##
    }
}

if ( !$method || $method=~/\bhome\b/ ) {
    can_ok("alDente::Container", 'home');
    {
        ## <insert tests for home method here> ##
    }
}

if ( !$method || $method=~/\bthrow_away\b/ ) {
    can_ok("alDente::Container", 'throw_away');
    {
        ## <insert tests for throw_away method here> ##
        my $plate_ids = "524032";
        #my $plate_ids = "'524032','524033','524034','524035','524036','524037','524038','524039','524040','524041','524042','524043','524044','524045','524046','524047','524048','524049','524050','524051','524052','524053','524054','524055','524056','524057','524058','524059','524060','524061','524062','524063','524064','524065','524066','524067','524068','524069','524070','524071','524072','524073','524074','524075','524076','524077','524078','524079','524080','524081','524082','524083','524084','524085','524086','524087','524088','524089','524090','524091','524092','524093','524094','524095','524096','524097','524098','524099','524100','524101','524102','524103','524104','524105','524106','524107','524108','524109','524110','524111','524112','524113','524114','524115','524116','524117','524118','524119','524120','524121','524122','524123'";
		$Benchmark{"start new_container_trigger"} = new Benchmark();
        alDente::Container::throw_away( -dbc => $dbc, -ids =>$plate_ids, -confirmed =>1 );	
		$Benchmark{"end new_container_trigger"} = new Benchmark();
    }
}

if ( !$method || $method=~/\bexport_Plate\b/ ) {
    can_ok("alDente::Container", 'export_Plate');
    {
        ## <insert tests for export_Plate method here> ##
    }
}

if ( !$method || $method=~/\bactivate_Plate\b/ ) {
    can_ok("alDente::Container", 'activate_Plate');
    {
        ## <insert tests for activate_Plate method here> ##
    }
}

if ( !$method || $method=~/\bthaw_Plate\b/ ) {
    can_ok("alDente::Container", 'thaw_Plate');
    {
        ## <insert tests for thaw_Plate method here> ##
    }
}





if ( !$method || $method=~/\bCheck_Library_Plates\b/ ) {
    can_ok("alDente::Container", 'Check_Library_Plates');
    {
        ## <insert tests for Check_Library_Plates method here> ##
    }
}

if ( !$method || $method=~/\bstore\b/ ) {
    can_ok("alDente::Container", 'store');
    {
        ## <insert tests for store method here> ##
    }
}

if ( !$method || $method=~/\bget_plate_name\b/ ) {
    can_ok("alDente::Container", 'get_plate_name');
    {
        ## <insert tests for get_plate_name method here> ##
    }
}

if ( !$method || $method=~/\bclear_plate_set\b/ ) {
    can_ok("alDente::Container", 'clear_plate_set');
    {
        ## <insert tests for clear_plate_set method here> ##
    }
}

if ( !$method || $method=~/\bget_birth_protocol\b/ ) {
    can_ok("alDente::Container", 'get_birth_protocol');
    {
        ## <insert tests for get_birth_protocol method here> ##
    }
}

if ( !$method || $method=~/\blabel\b/ ) {
    can_ok("alDente::Container", 'label');
    {
        ## <insert tests for label method here> ##
    }
}



if ( !$method || $method=~/\b_get_parent_sample\b/ ) {
    can_ok("alDente::Container", '_get_parent_sample');
    {
        ## <insert tests for _get_parent_sample method here> ##
    }
}

if ( !$method || $method=~/\bSB_trigger\b/ ) {
    can_ok("alDente::Container", 'SB_trigger');
    {
        ## <insert tests for SB_trigger method here> ##
    }
}

if ( !$method || $method=~/\b_update_rna_plate\b/ ) {
    can_ok("alDente::Container", '_update_rna_plate');
    {
        ## <insert tests for _update_rna_plate method here> ##
    }
}

if ( !$method || $method=~/\b_update_seq_plate\b/ ) {
    can_ok("alDente::Container", '_update_seq_plate');
    {
        ## <insert tests for _update_seq_plate method here> ##
    }
}

if ( !$method || $method=~/\b_update_tube\b/ ) {
    can_ok("alDente::Container", '_update_tube');
    {
        ## <insert tests for _update_tube method here> ##
    }
}

if ( !$method || $method=~/\b_update_clone_source\b/ ) {
    can_ok("alDente::Container", '_update_clone_source');
    {
        ## <insert tests for _update_clone_source method here> ##
    }
}

if ( !$method || $method=~/\bset_plate_status\b/ ) {
    can_ok("alDente::Container", 'set_plate_status');
    {
        ## <insert tests for set_plate_status method here> ##
        $dbc->Table_update_array('Plate',['Plate_Status'],['Active'],"WHERE Plate_ID = 185299",-autoquote=>1);
        alDente::Container::set_plate_status(-dbc=>$dbc,-plate_id=>185299,-status=>'On Hold');  
        my ($plate_status) = $dbc->Table_find('Plate','Plate_Status',"WHERE Plate_ID = 185299");
        is ($plate_status, 'On Hold', "Plate Status was set to On Hold");
        
        my $fail = alDente::Container::set_plate_status(-dbc=>$dbc,-plate_id=>185299,-status=>'Wrong status');
        is ($fail, 0, "Check invalid status");
 
    }
}
if ( !$method || $method=~/\bset_plate_archive_status\b/ ) {
    can_ok("alDente::Container", 'set_plate_archive_status');
    {
        ## <insert tests for set_plate_status method here> ##
        $dbc->Table_update_array('Plate',['Plate_Status'],['Active'],"WHERE Plate_ID = 185300",-autoquote=>1);
        alDente::Container::set_plate_archive_status(-dbc=>$dbc,-plate_id=>185300);
        my ($plate_status) = $dbc->Table_find('Plate','Plate_Status',"WHERE Plate_ID = 185300");
        is ($plate_status, 'Archived', "Plate Status was set to Archived");
        
        $dbc->Table_update_array('Plate',['Plate_Status','FK_Rack__ID'],['Active',2],"WHERE Plate_ID = 185301",-autoquote=>1);
        my $fail = alDente::Container::set_plate_archive_status(-dbc=>$dbc,-plate_id=>185301);
        is ($fail, 0, "Check invalid location");
    }
}

if ( !$method || $method =~ /\bplate_QC_trigger\b/ ) {
    can_ok("alDente::Container", 'plate_QC_trigger');
    {
        ## <insert tests for plate_QC_trigger method here> ##
    }
}
if ( !$method || $method=~/\bget_sample_id\b/ ) {
    can_ok("alDente::Container", 'get_sample_id');
    {
 
    ## <insert tests for get_sample_id method here> ##

        ## rry10965 a origially 96 well plate track in quad A of a tray
	my @plates = qw (338683 338683 338683 338683 338683 338683 338683 338683);
	my @wells = qw (A01 A02 A03 A04 A05 A06 A07 A08);

	my %correct_samples;
	$correct_samples{338683}{A01} = 15577037;
	$correct_samples{338683}{A02} = 15577038;
	$correct_samples{338683}{A03} = 15577039;
	$correct_samples{338683}{A04} = 15577040;
	$correct_samples{338683}{A05} = 15577041;
	$correct_samples{338683}{A06} = 15577042;
	$correct_samples{338683}{A07} = 15577043;
	$correct_samples{338683}{A08} = 15577044;
	my $samples = alDente::Container::get_sample_id(-dbc=>$dbc,-plate_ids=>\@plates, -wells=>\@wells);
	is_deeply($samples,\%correct_samples,'an origially 96 well plate track in quad A of a tray');

	# a 96 well plate of quad A of a origial 384 plate
	@plates = qw (5000 5000 5000);
	@wells = qw (A01 A02 A03);
	%correct_samples = ();
	$correct_samples{5000}{A01} = 1955905;
	$correct_samples{5000}{A02} = 1955907;
	$correct_samples{5000}{A03} = 1955909;

	my $samples = alDente::Container::get_sample_id(-dbc=>$dbc,-plate_ids=>\@plates, -wells=>\@wells);
	is_deeply($samples,\%correct_samples,'a 96 well plate of quad A of a origial 384 plate');

	# two 96 well plates of quad b and c of a original 384 plate in a tray
	@plates = qw (213584 213585 213585);
	@wells = qw (B01 A01 D05);
	%correct_samples = ();
	$correct_samples{213584}{B01} = 12214129;
	$correct_samples{213585}{A01} = 12214082;
	$correct_samples{213585}{D05} = 12214242;

	my $samples = alDente::Container::get_sample_id(-dbc=>$dbc,-plate_ids=>\@plates, -wells=>\@wells);
	is_deeply($samples,\%correct_samples,'two 96 well plates of quad b and c of a original 384 plate in a tray');


	# a simple 384 well plate
	@plates = qw (183929 183929 183929);
	@wells = qw (C01 M01 H24);
	%correct_samples = ();
	$correct_samples{183929}{C01} = 12214128;
	$correct_samples{183929}{M01} = 12214368;
	$correct_samples{183929}{H24} = 12214271;

	my $samples = alDente::Container::get_sample_id(-dbc=>$dbc,-plate_ids=>\@plates, -wells=>\@wells);
	is_deeply($samples,\%correct_samples,'a simple 384 well plate');


	# a rearray of a rearray rry9068
	@plates = qw (297733 297733 297733);
	@wells = qw (A01 B11 C06);
	%correct_samples = ();
	$correct_samples{297733}{A01} = 14393347;
	$correct_samples{297733}{B11} = 14393369;
	$correct_samples{297733}{C06} = 14393376;

	my $samples = alDente::Container::get_sample_id(-dbc=>$dbc,-plate_ids=>\@plates, -wells=>\@wells);
	is_deeply($samples,\%correct_samples,'a rearray of a rearray rry9068');


	# tray of tubes
	@plates = qw (340929 341020 340941);
	@wells = qw (N/A N/A N/A);
	%correct_samples = ();
	$correct_samples{340929}{'N/A'} = 15581603;
	$correct_samples{341020}{'N/A'} = 15581694;
	$correct_samples{340941}{'N/A'} = 15581615;
	
        my $samples = alDente::Container::get_sample_id(-dbc=>$dbc,-plate_ids=>\@plates, -wells=>\@wells);
        is_deeply($samples,\%correct_samples,'tray of tubes using N/A pos');

	# tray of tubes using A01 for well position... 
	@plates = qw (340929 341020 340941);
	@wells = qw (A01 A01 A01);
	%correct_samples = ();
	$correct_samples{340929}{'A01'} = 15581603;
	$correct_samples{341020}{'A01'} = 15581694;
	$correct_samples{340941}{'A01'} = 15581615;

	my $samples = alDente::Container::get_sample_id(-dbc=>$dbc,-plate_ids=>\@plates, -wells=>\@wells);
        is_deeply($samples,\%correct_samples,'tray of tubes using A01');
        
        # using tray and tray pos tray of tubes
	my @tray_ids = qw (23972 23972 23972);
	my @tray_pos = qw (A01 E02 D12);
	%correct_samples = ();
	$correct_samples{23972}{A01} = 15581603;
	$correct_samples{23972}{E02} = 15581615;
	$correct_samples{23972}{D12} = 15581694;
	#$correct_samples{23972}{E02} = 15581694;
	#$correct_samples{23972}{D12} = 15581615;

	my $samples = alDente::Container::get_sample_id(-dbc=>$dbc,-tray_ids=>\@tray_ids, -wells=>\@tray_pos);
	is_deeply($samples,\%correct_samples,'using tray and tray pos tray of tubes');

	# using tray and tray pos two 96 well plates of quad b and c
	@tray_ids = qw (13121 13121 13121);
	@tray_pos = qw (C02 B01 H09);
	my %correct_samples;
	$correct_samples{13121}{C02} = 12214129;
	$correct_samples{13121}{B01} = 12214082;
	$correct_samples{13121}{H09} = 12214242;

	my $samples = alDente::Container::get_sample_id(-dbc=>$dbc,-tray_ids=>\@tray_ids, -wells=>\@tray_pos);
	is_deeply($samples,\%correct_samples,'using tray and tray pos two 96 well plates of quad b and c');


	# using tubes that are aliquot from a plate and parent well is set (rry12929)
	@plates = qw (414002 414003 414004 414005 414006 414007 414008 414009);
	@wells = qw (N/A N/A N/A N/A N/A N/A N/A N/A);
	%correct_samples = ();
	$correct_samples{414002}{'N/A'} = 15893876;
	$correct_samples{414003}{'N/A'} = 15893877;
	$correct_samples{414004}{'N/A'} = 15893878;
	$correct_samples{414005}{'N/A'} = 15893879;
	$correct_samples{414006}{'N/A'} = 15893880;
	$correct_samples{414007}{'N/A'} = 15893881;
	$correct_samples{414008}{'N/A'} = 15893882;
	$correct_samples{414009}{'N/A'} = 15893883;
	
        my $samples = alDente::Container::get_sample_id(-dbc=>$dbc,-plate_ids=>\@plates, -wells=>\@wells);
        is_deeply($samples,\%correct_samples,'tray of tubes using N/A pos');
    }
}

if ( !$method || $method =~ /\bmap_tray_to_plates\b/ ) {
    can_ok("alDente::Container", 'map_tray_to_plates');
    {
        ## <insert tests for map_tray_to_plates method here> ##
        my @tray_ids = qw(23972 23972 23972);
        my @tray_pos = qw(A01 E02 D12);

        my ($plates, $wells) = alDente::Container::map_tray_to_plates(-dbc=>$dbc, -tray_ids=>\@tray_ids, -tray_pos=>\@tray_pos);
        is_deeply($plates,[340929,340941,341020],'found map_tray_to_plates for well');
        is_deeply($wells,['A01','A01','A01'],'found A01 position for tubes');
    
        my @tray_ids = qw(13121 13121);
        my @tray_pos = qw(A01 E02);
        
        my ($plates, $wells) = alDente::Container::map_tray_to_plates(-dbc=>$dbc, -tray_ids=>\@tray_ids, -tray_pos=>\@tray_pos);
        is_deeply($plates,[213583, 213584],'found map_tray_to_plates for 96-well plates');
        is_deeply($wells,['A01','C01'],'found quadrant positions for sub plates');
    }
    
}

## END of TEST ##

if ( !$method || $method =~ /\breset_current_plates\b/ ) {
    can_ok("alDente::Container", 'reset_current_plates');
    {
        ## <insert tests for reset_current_plates method here> ##
    }
}

if ( !$method || $method =~ /\badd_to_current_plates\b/ ) {
    can_ok("alDente::Container", 'add_to_current_plates');
    {
        ## <insert tests for add_to_current_plates method here> ##
    }
}

if ( !$method || $method =~ /\bprefix\b/ ) {
    can_ok("alDente::Container", 'prefix');
    {
        ## <insert tests for prefix method here> ##
    }
}

if ( !$method || $method =~ /\bplate_filter\b/ ) {
    can_ok("alDente::Container", 'plate_filter');
    {
        ## <insert tests for plate_filter method here> ##
    }
}

if ( !$method || $method =~ /\bparse_plate_filter\b/ ) {
    can_ok("alDente::Container", 'parse_plate_filter');
    {
        ## <insert tests for parse_plate_filter method here> ##
    }
}

if ( !$method || $method =~ /\bget_plate_schedule_code\b/ ) {
    can_ok("alDente::Container", 'get_plate_schedule_code');
    {
        ## <insert tests for get_plate_schedule_code method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_Plate_volumes\b/ ) {
    can_ok("alDente::Container", 'update_Plate_volumes');
    {
        ## <insert tests for update_Plate_volumes method here> ##
    }
}

if ( !$method || $method =~ /\bget_original_locations\b/ ) {
    can_ok("alDente::Container", 'get_original_locations');
    {
        ## <insert tests for get_original_locations method here> ##
        my @plate_ids = (5000..5003,77360,77360,77360,25836);  ## a,b,c,d, B04, 384
        my @wells     = ('A02','A02','A02','A02','','A01','N/A','A02');
        my ($plate,$well) = alDente::Container::get_original_locations(-dbc=>$dbc, -plate_ids=>\@plate_ids, -wells=>\@wells);
        is_deeply($plate,[4813,4813,4813,4813,77211,77211,77211,14801]);
        is_deeply($well,['A03','A04','B03','B04','','A01','B04','A02']);
    }
}

if ( !$method || $method =~ /\binherit_Parent_fields\b/ ) {
    can_ok("alDente::Container", 'inherit_Parent_fields');
    {
        ## <insert tests for inherit_Parent_fields method here> ##
    }
}

if ( !$method || $method =~ /\bvalidate_pool\b/ ) {
    can_ok("alDente::Container", 'validate_pool');
    {
        ## <insert tests for validate_pool method here> ##
    }
}

if ( !$method || $method =~ /\bpool_tray\b/ ) {
    can_ok("alDente::Container", 'pool_tray');
    {
        ## <insert tests for pool_tray method here> ##
    }
}

if ( !$method || $method =~ /\bget_recent_prepped_ids\b/ ) {
    can_ok("alDente::Container", 'get_recent_prepped_ids');
    {
        ## <insert tests for get_recent_prepped_ids method here> ##
    }
}

if ( !$method || $method =~ /\bPlate_Attribute_trigger\b/ ) {
    can_ok("alDente::Container", 'Plate_Attribute_trigger');
    {
        ## <insert tests for Plate_Attribute_trigger method here> ##
        # Part 1
        alDente::Container::Plate_Attribute_trigger( -dbc=> $dbc, -id => 1153491 );
        # Part 2
        alDente::Container::Plate_Attribute_trigger( -dbc=> $dbc, -id => 1153492 );
        # Part 3
        #alDente::Container::Plate_Attribute_trigger( -dbc=> $dbc, -id => 1166481 );
    }
}

if ( !$method || $method =~ /\bset_pipeline_btn\b/ ) {
    can_ok("alDente::Container", 'set_pipeline_btn');
    {
        ## <insert tests for set_pipeline_btn method here> ##
    }
}

if ( !$method || $method =~ /\bcatch_pipeline_btn\b/ ) {
    can_ok("alDente::Container", 'catch_pipeline_btn');
    {
        ## <insert tests for catch_pipeline_btn method here> ##
    }
}

if ( !$method || $method =~ /\bset_pipeline\b/ ) {
    can_ok("alDente::Container", 'set_pipeline');
    {
        ## <insert tests for set_pipeline method here> ##
    }
}

if ( !$method || $method =~ /\bsave_plate_set_btn\b/ ) {
    can_ok("alDente::Container", 'save_plate_set_btn');
    {
        ## <insert tests for save_plate_set_btn method here> ##
    }
}

if ( !$method || $method =~ /\bonhold_plate_btn\b/ ) {
    can_ok("alDente::Container", 'onhold_plate_btn');
    {
        ## <insert tests for onhold_plate_btn method here> ##
    }
}

if ( !$method || $method =~ /\bcatch_onhold_plate_btn\b/ ) {
    can_ok("alDente::Container", 'catch_onhold_plate_btn');
    {
        ## <insert tests for catch_onhold_plate_btn method here> ##
    }
}

if ( !$method || $method =~ /\bplate_archive_btn\b/ ) {
    can_ok("alDente::Container", 'plate_archive_btn');
    {
        ## <insert tests for plate_archive_btn method here> ##
    }
}

if ( !$method || $method =~ /\bcatch_plate_archive_btn\b/ ) {
    can_ok("alDente::Container", 'catch_plate_archive_btn');
    {
        ## <insert tests for catch_plate_archive_btn method here> ##
    }
}

if ( !$method || $method =~ /\bget_plate_status_list\b/ ) {
    can_ok("alDente::Container", 'get_plate_status_list');
    {
        ## <insert tests for get_plate_status_list method here> ##
    }
}

if ( !$method || $method =~ /\badd_Plate\b/ ) {
    can_ok("alDente::Container", 'add_Plate');
    {
        ## <insert tests for add_Plate method here> ##
    }
}

if ( !$method || $method =~ /\bdefine_Plate_as_Source\b/ ) {
    can_ok("alDente::Container", 'define_Plate_as_Source');
    {
        ## <insert tests for define_Plate_as_Source method here> ##
    }
}

if ( !$method || $method =~ /\bmanually_generate_Plate_records\b/ ) {
    can_ok("alDente::Container", 'manually_generate_Plate_records');
    {
        ## <insert tests for manually_generate_Plate_records method here> ##
    }
}

if ( !$method || $method =~ /\b_home_barcode\b/ ) {
    can_ok("alDente::Container", '_home_barcode');
    {
        ## <insert tests for _home_barcode method here> ##
    }
}

if ( !$method || $method =~ /\bget_plates\b/ ) {
    can_ok("alDente::Container", 'get_plates');
    {
        ## <insert tests for get_plates method here> ##
    	my $container = new alDente::Container( -dbc => $dbc );
    	my $failed_plates = $container->get_plates( -failed => 'Yes', -library => 'HS0043' );
    	my $expected = [122390, 122522];
    	is_deeply( $failed_plates, $expected, 'get_plates' );
    }
}

## END of TEST ##

ok( 1 ,'Completed Container test');

			require RGTools::RGIO;
            require RGTools::Unit_Test;
            my $benchmarks = "\nOrdered list of identified Benchmarks:\n";
            $benchmarks .= Unit_Test::dump_Benchmarks( -benchmarks => \%Benchmark, -delimiter => "\n", -start => 'Start', -mark => [ 0, 1, 3, 5, 10 ] );
            print "$benchmarks";

exit;
