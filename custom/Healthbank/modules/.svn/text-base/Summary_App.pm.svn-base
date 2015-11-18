##################
# Department_App.pm #
##################
#
# This module is a template App for a specific Department, one will want to customize it according to the needs of the department
#
package Healthbank::Summary_App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##

use base alDente::CGI_App;

use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::HTML;    ##  qw(hspace vspace get_Table_param HTML_Dump display_date_field set_validator);
use SDB::DBIO;
use SDB::CustomSettings;

use alDente::Form;
use alDente::Container;
use alDente::Rack;
use alDente::Validation;
use alDente::Tools;
use alDente::Source;

use Healthbank::Model;
use Healthbank::Views;
use LampLite::Bootstrap;

use Healthbank::Summary_Views;
##############################
# global_vars                #
##############################
use vars qw(%Configs  $URL_temp_dir $html_header $debug);    # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

my $dbc;
my $BS = new Bootstrap();

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Summary');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Summary' => 'summary',
        'Re-Generate Summary' => 'summary',
        'Generate Summary' => 'summary',
        'List Containers'  => 'list_Containers',
        );

    $dbc = $self->param('dbc');
    $q   = $self->query();

    $self->update_session_info();
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

##############
sub summary {
##############
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $since            = $q->param('from_date_range');
    my $until            = $q->param('to_date_range');
    my $first_subject    = $q->param('from_subject');
    my $last_subject     = $q->param('to_subject');
    my $exclude_subjects = $q->param('exclude_subjects');
    my $min_freeze_time  = $q->param('min_freeze_time');
    my $max_freeze_time  = $q->param('max_freeze_time');
    my $layer            = $q->param('Layer');
    my $group            = $q->param('Group');
    
    my $include_times      = $q->param('Include Times');
    my $include_test       = $q->param('Include Test Samples');
    my $include_production = $q->param('Include Production Samples');
    my $prefix             = $q->param('Prefix');
    my $debug = $q->param('Debug');
 
    my $include_breakdown = $q->param('include_breakdown');
   
    my $page;
    
    my $dept = $q->param('Target_Department');
    if ($dept eq 'BC_Generations' && !$prefix) { $prefix = 'BC' }
    elsif ($dept eq 'GENIC' && !$prefix) { $prefix = 'SHE' }
    elsif ($dept eq 'MMyeloma' && !$prefix) { $prefix = 'MM' }

    my $condition = $q->param('Condition') || 1;
    my $encoded_condition = $q->param('Encoded_Condition');
    if ($encoded_condition) { $condition = url_decode($condition) }

    my ( $plate_condition, $source_condition ) = ( 1, 1 );
    if   ($include_times) { $plate_condition  = $condition }
    else                  { $source_condition = $condition }

    if ($prefix) {
        $source_condition .= " AND Patient_Identifier LIKE '$prefix%'";
        $plate_condition  .= " AND Plate.Plate_Label LIKE '$prefix%'";
    }

    if ($since)         { 
        $source_condition .= " AND Received_Date >= '$since'";
        $plate_condition .= " AND Plate.Plate_Created >= '$since'";
    }
    if ($until)         { 
        $source_condition .= " AND Received_Date <= '$until 23:59:59'";
        $plate_condition .= " AND Plate.Plate_Created <= '$until 23:59:59'"; 
    }
    if ($first_subject) { 
        $source_condition .= " AND Right(Patient_Identifier,6) >= $first_subject";
        $plate_condition .= " AND MID(Plate.Plate_Label,3,6) >= $first_subject";
    }
    if ($last_subject)  { 
        $source_condition .= " AND Right(Patient_Identifier,6) <= $last_subject";
        $plate_condition .= " AND MID(Plate.Plate_Label,3,6) <= $last_subject";
    }
    if ($exclude_subjects) {
        $exclude_subjects =~ s /(BC|SHE|MM)//g;
        $source_condition .= " AND Right(Patient_Identifier,6) != $exclude_subjects";
        $plate_condition .= " AND MID(Plate.Plate_Label,3,6) != $exclude_subjects";
    }

    if ( $min_freeze_time =~ /\S/ ) { $plate_condition .= " AND FreezeTime.Attribute_Value >= $min_freeze_time" }
    if ( $max_freeze_time =~ /\S/ ) { $plate_condition .= " AND FreezeTime.Attribute_Value <= $max_freeze_time" }

    if ( !$include_test && $include_production)       { $plate_condition .= " AND Plate.Plate_Test_Status != 'Test'" }
    if ( !$include_production && $include_test) { $plate_condition .= " AND Plate.Plate_Test_Status != 'Production'" }

    if ($include_breakdown || $include_times) {
        $page .= $self->View->healthbank_summary( $dbc, -prefix => $prefix, -include_times => $include_times, -source_condition => $source_condition, -plate_condition => $plate_condition );
    }

    $page .= $self->View->prompt_for_summary( -dbc=>$dbc, -prefix=>$prefix, -layer=>$layer);

    $page .= '<hr>' . $self->sample_list( -layer => $layer, -group => $group, -prefix => $prefix, -condition => "$condition AND $plate_condition" );  ## sample query includes Plates (but not sources)


    return $page;
}

####################
sub sample_list {
####################
    my $self            = shift;
    my %args            = filter_input( \@_ );
    my $dbc             = $self->param('dbc');
    my $q               = $self->query();
    
    my $layer           = $args{-layer} || 'Loc';
    my $group           = $args{-group} || 'Sample_Type,FK_Plate_Format__ID,Freezer';
    my $extra_condition = $args{-condition} || 1;
    my $prefix          = $args{-prefix};
    my $debug = $args{-debug};
    
    if ($prefix) { $extra_condition .= " AND Plate.Plate_Label like '$prefix%'" }

    my $tables = 'Plate,Plate_Format,Rack,Sample_Type,Equipment,Location';
    if ($extra_condition =~ /FreezeTime/) {
        my ($freeze_time) = $dbc->Table_find('Attribute', "Attribute_ID", "WHERE Attribute_Name = 'initial_time_to_freeze'");
        $tables .= " LEFT JOIN Plate_Attribute as FreezeTime ON FreezeTime.FK_Plate__ID=Plate.Plate_ID AND FK_Attribute__ID = $freeze_time";
    }
    

    my $listlink       = '&cgi_application=Healthbank::Summary_App&rm=List Containers';
    my $returnlink     = '&cgi_application=Healthbank::Summary_App&rm=Summary';
    my $reset_tip = 'Set search criteria and \'Generate Summary\' again after changing layering';
    my $location_link  = Link_To( $dbc->homelink, 'Location', "$returnlink&Layer=Loc&Prefix=$prefix", -tooltip=>$reset_tip );
    my $equipment_link = Link_To( $dbc->homelink, 'Freezer', "$returnlink&Layer=Freezer&Prefix=$prefix" , -tooltip=>$reset_tip);
    my $type_link      = Link_To( $dbc->homelink, 'Sample_Type', "$returnlink&Layer=Sample_Type&Prefix=$prefix" , -tooltip=>$reset_tip);
    my $no_layer_link  = Link_To( $dbc->homelink, '[No Layers]', "$returnlink&Layer=All+Records&Prefix=$prefix" , -tooltip=>$reset_tip);

    my $page = subsection_heading(" Reset Grouping of Results to Layer by: $location_link ". hspace(20) . $equipment_link . hspace(20) . $type_link . hspace(20) . $no_layer_link );

    my @fields = (
        'Plate_Format_Type as Format',
        'Sample_Type',
        'count(*) as Tubes',
        'Count(DISTINCT LEFT(Plate.Plate_Label,9)) as Subjects',
        'Sum(Current_Volume) as Total_Volume',
        'Group_Concat(Distinct Current_Volume_Units) as Units',
        'CASE WHEN Equipment_ID=1 THEN Rack_Alias ELSE Equipment_Name END as Freezer',
        'Location_Name AS Loc'
    );
    if ( $group eq 'Plate_ID' ) { unshift @fields, 'Plate_ID', 'Plate.Plate_Label', 'FK_Rack__ID as Rack' }


    my $encoded_condition = url_encode($extra_condition);
 
    my $overview = $dbc->Table_retrieve_display(
        $tables, 
        \@fields,
        -condition        => "WHERE FK_Rack__ID=Rack_ID AND FK_Location__ID=Location_ID AND FK_Equipment__ID=Equipment_ID AND FK_Sample_Type__ID=Sample_Type_ID AND FK_Plate_Format__ID=Plate_Format_ID AND Plate_Status = 'Active' AND $extra_condition",
        -group            => $group,
        -order            => 'Location_Name,Equipment_Name,FK_Plate_Format__ID,Sample_Type',
        -layer            => $layer,
        -toggle_on_column => 'Freezer',
        -return_html      => 1,
        -total_columns    => 'Tubes',
        -title            => 'Samples Collected and Stored (by Type / Format / Freezer)',
        -print_link       => 1,
        -excel_link       => 1,
        -link_parameters  => { 'Format' => "$listlink&Condition=Sample_Type='<Sample_Type>' AND (Equipment_Name='<Freezer>' OR Equipment_ID=1 AND Rack_Alias='<Freezer>') AND Plate_Format_Type='<Format>'&Encoded_Condition=$encoded_condition" },
        -tips             => { 'Format' => 'view these containers' },
        -debug            => $debug,
        -alt_message => 'No Search Criteria entered - or No Records found for this search criteria',
        -border =>1,
        -debug=>$debug,
    );


    
    $page .= $overview;
    my @conditions = split " AND ", $extra_condition;
    $page .= '<p ></p>' . create_tree(-tree=>{' Extra Conditions' => Cast_List(-list=>\@conditions, -to=>'UL', -exclude=>['1']) }) . '<p ></p>';
    
    return $page;
}

######################
sub list_Containers {
######################
my $self            = shift;
my %args            = filter_input( \@_ );
my $dbc             = $self->param('dbc');
my $q               = $self->query();

my $group           = $q->param('Group') || 'Plate_ID';
my $condition       = $q->param('Condition') || 1;

my $encoded_condition = $q->param('Encoded_Condition');
if ($encoded_condition) { $condition .= " AND " . url_decode($encoded_condition) }

my @fields = (
        'Plate_ID as Tube',
     'Plate_Format_Type as Format',
     'Sample_Type',
     'count(*) as Tubes',
     'Plate.Plate_Label',
     'Count(DISTINCT LEFT(Plate.Plate_Label,9)) as Subjects',
     'Sum(Current_Volume) as Total_Volume',
     'Group_Concat(Distinct Current_Volume_Units) as Units',
     'CASE WHEN Equipment_ID=1 THEN Rack_Alias ELSE Equipment_Name END as Freezer',
     'Location_Name AS Location',
     'FK_Rack__ID as Rack',
 );

my $page = section_heading("Selected Container Records");

    $page .= $dbc->Table_retrieve_display(
    'Plate,Plate_Format,Rack,Sample_Type,Equipment,Location',
    \@fields,
    -condition        => "WHERE FK_Rack__ID=Rack_ID AND FK_Location__ID=Location_ID AND FK_Equipment__ID=Equipment_ID AND FK_Sample_Type__ID=Sample_Type_ID AND FK_Plate_Format__ID=Plate_Format_ID AND Plate_Status = 'Active' AND $condition",
    -group            => $group,
    -order            => 'Location_Name,Equipment_Name,FK_Plate_Format__ID,Sample_Type',
    -return_html      => 1,
    -total_columns    => 'Tubes',
    -title            => 'Selected Containers',
    -print_link       => 1,
    -excel_link       => 1,
    -border =>1
);

$page .= '<p ></p>' . create_tree(-tree=>{'Extra Conditions' => $condition}) . '<p ></p>';
    
}

#
# home_page has submit buttons to lead to the other run modes
# Also, displays some basic statistics relevant to each of the run modes

return 1;
