###################################################################################################################################
# Cap_Seq::Statistics_View.pm
#
#
#
#
###################################################################################################################################
package Cap_Seq::Statistics_View;

use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;
## alDente modules
use alDente::View;
use alDente::Form;
use alDente::Plate_Prep;
use vars qw( $Connection $user_id %Configs );

my $DEFAULT_DATE = '2008-01-01';
our @ISA = qw(alDente::View);


###########################
sub display_daily_planner {
###########################
    my $self = shift;
    my $dbc = $self->{dbc};

    my $daily_planner_output;

    $daily_planner_output .= alDente::Form::start_alDente_form(-dbc=>$dbc, -name => 'daily_planner');



    ## Add run mode parameter
    $daily_planner_output .= hidden(-name => 'rm', -value => 'display_daily_totals');

    ## Add cgi_application parameter
    $daily_planner_output .= hidden(-name =>'cgi_application',-value=>'Cap_Seq::Statistics_App');

    $self->home_page();



    $daily_planner_output .= end_form();

    return $daily_planner_output;
}


##############################
sub set_general_options {
##############################
    
  my $self = shift;
  my %args = filter_input(\@_);

  $self->SUPER::set_general_options;

 
  $self->{config}{API_path   }  = 'alDente';
  $self->{config}{API_scope  }  = 'plate';   # use get_solexa_run_xxx
  $self->{config}{API_type   }  = 'data';         # use get_xxx_data
  $self->{config}{key_field  }  = "concat(library_name,'-',plate_number) as library_plate_number";
  $self->{config}{view_tables}  = 'Plate';  
  $self->{config}{record_limit} = 500;
  $self->{config}{actions} = [
        'alDente::Container::plate_archive_btn(-dbc=>$self->{dbc});'
      ];
  $self->{config}{catch_actions} = [
        'alDente::Container::catch_plate_archive_btn(-dbc=>$self->{dbc});'
    ];
  $self->{config}{show_io_options} = 0; 

  ## CUSTOMIZED Condition ##
  $self->{API_args}{-condition}{value} = " (Vector_Based_Library.Vector_Based_Library_ID IS NULL OR Vector_Based_Library.Vector_Based_Library_Type <> 'Mapping') and Library_Type IN ('Vector_Based','PCR_Product') AND Project_Name NOT LIKE '%ASP_%' and Plate.Plate_Status = 'Active'";
  $self->{API_args}{-condition}{value} .= " AND CASE WHEN Project_Completed IS NULL THEN 1 WHEN Project_Completed = '0000-00-00' THEN 1 ELSE Project_Completed > DATE_SUB( CURDATE(), INTERVAL 7 DAY) END AND Project_Status IN ('Active','Completed')";
  ## END of Customization

  $self->{API_args}{-condition}{preset} = 1;
  $self->{API_args}{-order}{value} = "Library_Name,Plate_Number";
  $self->{API_args}{-order}{preset} = 1;
  my @cached_links = (
                      'SEQ - Overnight Protocols Completed',
                      'SEQ - PCR Setup Completed',
                      'SEQ - Preps Completed',
                      'SEQ - Reactions Completed',
                      'SEQ - Rxns Completed by Library',
                      'SEQ - Precipitations Completed',
                      'SEQ - Resuspensions Completed',
		      'SEQ - Daily Planner ASP',
                      );
  $self->set_custom_cached_links(-cached_links=>\@cached_links);
 

  return;

}

################################
sub set_input_options {
################################
    my $self = shift;
    my %args = filter_input(\@_);

    $self->SUPER::set_input_options;
    my $default_to = &now();
    $self->{config}{input_options} = {
        'Library.FK_Project__ID' => { argument => '-project_id',     value => '' },
        'Plate.FK_Library__Name' => { argument => '-library',        value => '' },
        'Plate.Plate_Number'     => { argument => '-plate_number',   value => '' },
        'Plate.Plate_Created' => {argument => '-since', value =>"$DEFAULT_DATE<=>$default_to",type =>'date'},
    };

    $self->{config}{input_order} = [
        'Library.FK_Project__ID',
        'Plate.FK_Library__Name',
        'Plate.Plate_Number',
        'Plate.Plate_Created',
    ];

    return;

}

#################################
sub set_output_options {
#################################
    my $self = shift;
    my %args = filter_input(\@_);

    $self->SUPER::set_input_options;

    $self->{config}{output_options} = {
        #'library_plate_number' => {picked => 1},
        'project'     => { picked => 1 },
        'library'          => { picked => 1 },
        'plate_number'     => { picked => 1 },
        'scheduled_pipelines'         => { picked => 1 },
        'history' => { picked => 1 },
	'work_request' => { picked => 1 },
  
    };

    $self->{config}{output_order} = [
        'library_plate_number',
#        'library',
#        'plate_number',
        'scheduled_pipelines',
        'project',
	'work_request',
        'history'
    ];
    $self->{config}{group_by} = {
        'library_plate_number' => {picked=>1}
    };
    $self->{config}{output_link} = {
        'library'     => "&HomePage=Library&ID=<value>",
    };
    $self->{config}{output_function} = {
	'library_plate_number' => 'get_original_plate_for_library_plate_number',
        'history' => "get_sequencing_plate_history",
        'scheduled_pipelines' =>"get_plate_schedules",
	'work_request' => "get_plate_work_requests"
    };
    return;


}

#################################
sub get_sequencing_plate_history {
#################################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'key_field_value');
    my $library_plate_number = $args{-key_field_value};
    $library_plate_number =~ /(.+)\-(\d+)/i;
    my $library = $1;
    my $plate_number = $2;
    my @protocols = (
        
                    {'Overnights'        => ['BAC/Fosmid 384 well overnights','BAC 384 Well Overnights','Overnight setup 384','overnight setup 96 TN','Overnight setup 96','overnight setup 384 TN']},
                    {'Preps'            => ['BAC/Fosmid 384 well prep','BAC 384 Well Prep','BAC 384 Well Spindowns','384-Well Prep','Full Mech Prep - Abgene','PCR purification 384 well','PCR purification 96 well','Consolidation 96->384','PCR Setup 96 well','PCR - aliquot to SequalPrep']},   
                    {'Reactions'         => ['Rxns_1/256_FRDBrew_400nl','Rxns_BD384_1/24_4uLrxn_2uLDNA','Rxns_BD384_5uLrxn_3uLDNA','Rxns_Dilute_Aliquot_1/256','Rxns_BD384_1/48_4uLrxn_2uLDNA']},
                    {'Precipitations'    => ['Pptn_BD384_1/256_400nl','Pptn_BD96/384_EtOH/EDTA']},
                    {'Resuspensions'     => ['Resuspension of Sequencing Reaction Prod']},
		    {'Initiated Run'     => ['Initiated Run']}
                    );    
    return alDente::Plate_Prep::get_prep_summary_table(-protocol_info=>\@protocols,-library=>$library,-plate_number=>$plate_number,-dbc=>$self->{dbc});
    
}
#########################
sub get_plate_schedules {
#########################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'key_field_value');
    my $library_plate_number = $args{-key_field_value};
    $library_plate_number =~ /(.+)\-(\d+)/i;
    my $library = $1;
    my $plate_number = $2;

    require alDente::Plate_Schedule;
    my $plate_schedule_obj = alDente::Plate_Schedule->new(-dbc=>$self->{dbc});
    my $plate_schedules = $plate_schedule_obj->get_plate_schedule_codes(-plate_number=>$plate_number,-library=>$library,-format=>'String');

    return $plate_schedules;

}

#########################
sub get_plate_work_requests {
#########################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'key_field_value');
    my $library_plate_number = $args{-key_field_value};
    $library_plate_number =~ /(.+)\-(\d+)/i;
    my $library = $1;
    my $plate_number = $2;
    my $dbc = $self->{dbc};
    
    #my @work_requests = $dbc->Table_find('Plate','FK_Work_Request__ID',"WHERE FK_Library__Name = '$library' AND Plate_Number = $plate_number",-distinct=>1);
    my @work_requests = $dbc->Table_find('Work_Request','Work_Request_ID',"WHERE FK_Library__Name = '$library'",-distinct=>1);
    my $work_request_ids = join(",", @work_requests);
    my $condition = Cast_List(-list=>\@work_requests,-to=>'string'); 
	if( !$condition ) {
		return;
	}
	
    my @work_requests = $dbc->get_FK_info_list(-field=>'FK_Work_Request__ID',-condition=>"WHERE Work_Request_ID IN ($condition) ORDER BY Work_Request_ID");
    my $all = join ("; ", @work_requests);
    my $all_short = substr( $all, 0, 45 );

    $all =  &Show_Tool_Tip( Link_To($dbc->homelink(),$all_short , "&cgi_application=alDente::Work_Request_App&ID=$work_request_ids", $Settings{LINK_COLOUR} ), $all );
    return $all;

}

#########################
sub get_original_plate_for_library_plate_number {
#########################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'key_field_value');
    my $library_plate_number = $args{-key_field_value};
    $library_plate_number =~ /(.+)\-(\d+)/i;
    my $library = $1;
    my $plate_number = $2;
    my $dbc = $self->{dbc};

    my ($original_plate) = $dbc->Table_find('Plate', 'FKOriginal_Plate__ID',"WHERE FK_Library__Name = '$library' and Plate_Number = $plate_number",-distinct=>1);
    my $link_parameter = SDB::HTML::home_URL('Container',$original_plate);
    return &Link_To( $dbc->homelink(), $library_plate_number, $link_parameter, -colour => 'blue', -window => ['newwin'] )
}

1;
