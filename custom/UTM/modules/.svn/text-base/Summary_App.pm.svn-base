##################
# Department_App.pm #
##################
#
# This module is a template App for a specific Department, one will want to customize it according to the needs of the department
#
package UTM::Summary_App;

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

use base RGTools::Base_App;

use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;

use UTM::Model;
use UTM::Views;
use LampLite::Bootstrap;

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

    $self->start_mode('Home Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Summary'                          => 'summary',
        'Generate Summary'                 => 'summary',
);

    $dbc = $self->param('dbc');
    $q   = $self->query();

    $self->update_session_info();
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

###############
sub summary {
###############
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

    my $debug              = $q->param('Debug');
    my $include_times      = $q->param('Include Times');
    my $include_test       = $q->param('Include Test Samples');
    my $include_production = $q->param('Include Production Samples');
    my $prefix             = $q->param('Prefix');

    my $dept = $q->param('Target_Department');
    if ($dept eq 'BC_Generations' && !$prefix) { $prefix = 'BC' }
    elsif ($dept eq 'GENIC' && !$prefix) { $prefix = 'SHE' }
    elsif ($dept eq 'MMyeloma' && !$prefix) { $prefix = 'MM' }
    
    my $condition = $q->param('Condition') || 1;

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

    if ( $include_times && $min_freeze_time =~ /\S/ ) { $plate_condition .= " AND PA.Attribute_Value >= $min_freeze_time" }
    if ( $include_times && $max_freeze_time =~ /\S/ ) { $plate_condition .= " AND PA.Attribute_Value <= $max_freeze_time" }

    if ( !$include_test )       { $plate_condition .= " AND Plate.Plate_Test_Status != 'Test'" }
    if ( !$include_production ) { $plate_condition .= " AND Plate.Plate_Test_Status != 'Production'" }

    ## automatically update dynamic attributes before generating summaries ##
    #     &UTM::auto_update_time_attributes($dbc);

    my $page;

    my $prompt = UTM::Views::prompt_for_summary( $dbc, -prefix=>$prefix, -layer=>$layer);

    #	    Link_To($homelink,'Regenerate Overview with Collection Times', "&cgi_application=UTM::App&rm=Summary&Include+Times=1");
    #    $page .= '<p ></p>' . Link_To($homelink,'Regenerate Overview without Collection Times', "&cgi_application=UTM::App&rm=Summary");
    #
    #

    if ( $q->param('rm') eq 'Generate Summary' ) {
        ## Regenerating summary show other overview information ##
        if ($prefix =~ /^BC/i ) {
            require BC_Generations::Department_Views;
            $page .= BC_Generations::Department_Views::overview( $dbc, -prefix => $prefix, -include_times => $include_times, -source_condition => $source_condition, -plate_condition => $plate_condition ) . '<HR>' . $prompt;
        }
        elsif ($prefix =~ /^(SHE|MM)/i ) {
            require GENIC::Department_Views;
            $page .= GENIC::Department_Views::overview( $dbc, -prefix => $prefix, -include_times => $include_times, -source_condition => $source_condition, -plate_condition => $plate_condition ) . '<HR>' . $prompt;
        }
        else {
            $page .= UTM::Views::overview( $dbc,  -include_times => $include_times, -source_condition => $source_condition, -plate_condition => $plate_condition, -debug => $debug );
        }
    }
    else {
        ## NOT regenerating summary ##
        $page .= UTM::Views::overview( $dbc, -prefix => $prefix ) . '<HR>' . $prompt;
    }

    $page .= '<hr>' . $self->sample_list( -layer => $layer, -group => $group, -prefix => $prefix, -condition => "$condition AND $plate_condition" );  ## sample query includes Plates (but not sources)

    return $page;
}

#################
sub get_list {
#################
    my $self      = shift;
    my $field     = shift;
    my $condition = shift || 1;

    my $dbc = $self->param('dbc');
    my @list = $dbc->Table_find_array( 'Source, Plate_Format', $field, "where FK_Plate_Format__ID=Plate_Format.Plate_Format_ID AND $condition" );

    return @list;
}

##################/.
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

    my $returnlink     = '&cgi_application=UTM::App&rm=Summary';
    my $location_link  = Link_To( $homelink, 'Layer by Location', "$returnlink&Layer=Loc&Prefix=$prefix" );
    my $equipment_link = Link_To( $homelink, 'Layer by Freezer', "$returnlink&Layer=Freezer&Prefix=$prefix" );
    my $type_link      = Link_To( $homelink, 'Layer by Sample_Type', "$returnlink&Layer=Sample_Type&Prefix=$prefix" );
    my $no_layer_link  = Link_To( $homelink, 'No Layers', "$returnlink&Layer=All+Records&Prefix=$prefix" );

    my $page = $location_link . hspace(20) . $equipment_link . hspace(20) . $type_link . hspace(20) . $no_layer_link . vspace(10);

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

    my $overview = $dbc->Table_retrieve_display(
        'Plate,Plate_Format,Rack,Sample_Type,Equipment,Location',
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
        -link_parameters  => { 'Format' => "$returnlink&Layer=$layer&Condition=Sample_Type='<Sample_Type>' AND (Equipment_Name='<Freezer>' OR Equipment_ID=1 AND Rack_Alias='<Freezer>') AND Plate_Format_Type='<Format>'&Group=Plate_ID" },
        -tips             => { 'Format' => 'view these containers' },
        -debug            => $debug,
        -border =>1
    );

    
    
    $page .= $overview;
    $page .= '<p ></p>' . create_tree(-tree=>{'Extra Conditions' => $extra_condition}) . '<p ></p>';
    
    return $page;
}

#
# home_page has submit buttons to lead to the other run modes
# Also, displays some basic statistics relevant to each of the run modes

return 1;
