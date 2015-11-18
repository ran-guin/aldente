##############################################################################################
# alDente::Pipeline_Views.pm
#
# Interface generating methods for the Pipeline MVC  (assoc with Pipeline.pm, Pipeline_App.pm)
#
##############################################################################################
package alDente::Pipeline_Views;
use base alDente::Object_Views;
use strict;

## Standard modules ##
use CGI qw(:standard);

## Local modules ##
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

use RGTools::RGIO;
use RGTools::Views;

use alDente::Form;
use alDente::Pipeline;
use alDente::Tools;

## globals ##
use vars qw( %Configs );

my $q = new CGI;

#
###################################
sub home_page {
###################################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $dbc       = $args{-dbc};
    my $Pipeline  = $args{-Pipeline};
    my $id        = $args{-id} || $Pipeline->{id};
    my $condition = $args{-condition} || 1;
    my $admin     = $args{-admin};

    ## $admin should be set in Pipeline_App setup(), but in some cases this method is called directly by other methods so setting $admin is still needed here.
    if ( !$admin ) {    # check the user access in case no Admin param passed in
        my $access = $dbc->get_local('Access');
        if ( ( grep {/Admin/xmsi} @{ $access->{ $dbc->config('Target_Department') } } ) || $access->{'LIMS Admin'} ) {
            $admin = '1';
        }
    }

    my @object_classes = ( 'Lab_Protocol', 'Analysis_Software' );
    if ($id) {
        $condition .= " AND Pipeline_ID IN ($id)";
        @object_classes = $dbc->Table_find( -table => 'Pipeline_Step,Object_Class', -fields => 'Object_Class', -condition => "WHERE FK_Object_Class__ID = Object_Class_ID and FK_Pipeline__ID IN ($id)", -distinct => 1 );

        if ( scalar(@object_classes) > 1 ) {
            my $class_str = Cast_List( -list => \@object_classes, -to => 'string' );
            Message("The pipeline contains different types of steps: $class_str");
            @object_classes = ();
        }
    }

    my $output;

    if ($id) { $output .= "Pipeline: " . alDente::Tools::alDente_ref( 'Pipeline', $id, -dbc => $dbc ) . '<P>' }
    else     { $output .= "<h2>Defined Pipelines:</h2>" }

    if ( scalar(@object_classes) == 0 ) {
        my @pipeline_type = $dbc->Table_find( -table => 'Pipeline', -fields => 'distinct Pipeline_Type', -condition => "WHERE Pipeline_ID IN ($id)", -distinct => 1 );

        if ( scalar(@pipeline_type) == 1 ) {
            if   ( @pipeline_type[0] eq 'Lab_Protocol' ) { @object_classes = ('Lab_Protocol'); }
            else                                         { @object_classes = ('Analysis_Software'); }
        }
        else { @object_classes = ( 'Lab_Protocol', 'Analysis_Software' ); }
    }

    foreach my $class (@object_classes) {
        # Retrieve pipeline steps
        my %result = $dbc->Table_retrieve(
            "Pipeline LEFT JOIN Plate_Format ON Pipeline.FKApplicable_Plate_Format__ID=Plate_Format_ID LEFT JOIN Pipeline_Step ON FK_Pipeline__ID=Pipeline_ID LEFT JOIN Object_Class ON FK_Object_Class__ID=Object_Class_ID LEFT JOIN $class ON Object_ID = ${class}_ID",
            [ 'Pipeline.Pipeline_Name AS Pipeline', 'Plate_Format_Type as Format', "${class}_Name as $class", "${class}_ID", 'Pipeline_Step_Order', 'Pipeline_Step_ID' ],
            "WHERE $condition AND Object_Class = \"$class\" ORDER BY Pipeline_Name, Pipeline_Step_Order",
        );

        # Create HTML table
        my $ptable = HTML_Table->new();
        $ptable->Set_Title("$class Pipeline(s)");
        $ptable->Set_Headers( [ "Pipeline", "Format", "$class", "Pipeline Step Order", "Delete" ] );
        $ptable->Toggle_Colour_on_Column(1);
        # Get the first array from the hash
        my $pipelines;
        $pipelines = $result{Pipeline};

        # Get record count
        my $count = 0;
        if ($pipelines) {
            $count = int(@$pipelines);
        }

        # Check record count
        if ( $count > 0 ) {
            my $format_ids;
            my $classes;
            my $class_ids;
            my $step_orders;
            my $step_ids;
            $format_ids  = $result{Format};
            $classes     = $result{$class};
            $step_orders = $result{Pipeline_Step_Order};
            $step_ids    = $result{Pipeline_Step_ID};
            $class_ids   = $result{ $class . '_ID' };

            # Generate rows
            my $index = 0;
            while ( $index < $count ) {
                $ptable->Set_Row(
                    [   $pipelines->[$index], $format_ids->[$index], $classes->[$index],
                        $step_orders->[$index],
                        Link_To( $dbc->config('homelink'), 'Delete', "&cgi_application=alDente::Pipeline_App&rm=Delete Pipeline Step&Pipeline_ID=$id&Object_ID=$class_ids->[$index]&Pipeline_Step_ID=$step_ids->[$index]" )
                    ]
                );
                $index++;
            }
        }
#        else { $dbc->message("There are currently no $class pipeline steps associated with this pipeline") }

        if ($id) {
            $output .= $ptable->Printout(0) . '<hr>';
            $output
                .= alDente::Form::start_alDente_form( $dbc, 'pipeline_step' )
                . $q->hidden( -name => 'cgi_application', -value => 'alDente::Pipeline_App', -force => 1 )
                . $q->hidden( -name => 'Pipeline_Class',  -value => $class,                  -force => 1 )
                . $q->hidden( -name => 'Pipeline_ID',     -value => $id,                     -force => 1 )
                . $q->submit( -name => 'rm', -value => 'Add Pipeline Step', -force => 1, -class => 'Action', -onClick => 'return validateForm(this.form)' ) . ' #'
                . Show_Tool_Tip( $q->textfield( -name => 'Pipeline_Step_Number', -size => 4 ), 'Indicate step number within pipeline' )
                . alDente::Tools::search_list( -name => 'FK_Lab_Protocol__ID', -tip => 'Pick Protocol to add to this Pipeline' );

            $output .= set_validator( -name => 'FK_Lab_Protocol__ID', -mandatory => 1, -prompt => 'You must first choose a protocol to add to this pipeline' );
            $output .= end_form();
            $output .= Link_To( $dbc->config('homelink'), 'Re-Order Pipeline', "&cgi_application=alDente::Pipeline_App&rm=Re-Order Pipeline&Pipeline_ID=$id" );
        }
        elsif ($count) { $output .= create_tree( -tree => { "$class Pipelines" => $ptable->Printout(0) } ) }
    }

    my $record;
    my $image;

    if ($id) {
        my ($parent_pipeline) = $dbc->Table_find( 'Pipeline', 'FKParent_Pipeline__ID', "WHERE Pipeline_ID = $id" );
        my @daughter_pipelines = $dbc->Table_find( 'Pipeline', 'Pipeline_ID', "WHERE FKParent_Pipeline__ID = $id" );

        $output .= '<HR>';
        if ($parent_pipeline) { $output .= 'Parent Pipeline: ' . alDente::Tools::alDente_ref( 'Pipeline', $parent_pipeline, -dbc => $dbc ) . '<P>' }
        if (@daughter_pipelines) {
            $output .= 'Daughter Pipeline(s):<UL>';
            foreach my $daughter (@daughter_pipelines) {
                $output .= '<LI>' . alDente::Tools::alDente_ref( 'Pipeline', $daughter, -dbc => $dbc );
            }
            $output .= '</UL><P>';
        }

        ## show pipeline diagram ##
        my $pipeline_obj = alDente::Pipeline->new( -id => $id, -dbc => $dbc );
        $image = &Link_To( $dbc->config('homelink'), 'View all pipeline steps', "&Pipeline+Summary=1&View_Pipeline_Steps=1&Pipeline_ID=$id" ) . lbr();
        $image .= $pipeline_obj->display_pipeline();

        $pipeline_obj->load_Object();
        $record = $pipeline_obj->display_Record( -tables => ['Pipeline'] );

        #
        ## show group visibility
        #
        ## only users in Pipeline.FK_Grp__ID group, or with 'Admin' Grp_Access privilege on the pipeline, can edit the pipeline group visibility
        my $user_groups  = $dbc->get_local('group_list');
        my $pipeline_obj = new alDente::Pipeline( -dbc => $dbc, -id => $id );
        my $grp_access   = $pipeline_obj->get_grp_access( -grp_ids => $user_groups );
        my $allow_edit   = 0;
        if ( grep /Admin/, values %$grp_access ) {
            $allow_edit = 1;
        }
        
        ## use standardized interface for managing join tables ##
        my $filter = "Access IN ('Lab') AND Grp_Status = 'Active'";
        my $Object = new alDente::Object( -dbc => $dbc );
        $record .= '<HR>'
            . $Object->View->join_records(
            -dbc        => $dbc,
            -defined    => "FK_Pipeline__ID",
            -id         => $id,
            -join       => 'FK_Grp__ID',
            -join_table => "GrpPipeline",
            -filter     => $filter,
            -title      => 'Group Visibility for this Pipeline',
            -extra      => 'Grp_Access',
            -editable   => $admin & $allow_edit,
            -edit       => $allow_edit,
            );
    }

    return &Views::Table_Print( content => [ [ $output, $record ], [$image] ], -return_html => 1 );
}

#
#
# Simple view to reorder steps within a pipeline.
#
# Note - this should ONLY work with pipelines that DO NOT contain branches
#
#
###############################
sub reorder_Pipeline_page {
###############################
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $pipeline_id = $args{-pipeline_id};
    my $dbc         = $args{-dbc};

    ## for now assume that these are Lab Protocols, but this may be adapted for other Pipelines as required ##
    my $class     = 'Lab_Protocol';
    my $tables    = "Pipeline_Step,Pipeline,Object_Class,$class";
    my $condition = "WHERE FK_Pipeline__ID=Pipeline_ID AND FK_Object_Class__ID=Object_Class_ID AND Object_Class='$class' AND Object_ID=${class}_ID AND Pipeline_ID=$pipeline_id ORDER BY Pipeline_Step_Order";

    my @options = $dbc->Table_find( $tables, "${class}_Name", $condition );

    my $current = alDente::Tools::alDente_ref( 'Pipeline', $pipeline_id, -dbc => $dbc );
    $current .= $dbc->Table_retrieve_display( $tables, [ "${class}_ID as $class", 'Pipeline_Step_Order', 'FK_Object_Class__ID' ], $condition, -return_html => 1, -title => 'Current Pipeline' );

    my $form = alDente::Form::start_alDente_form( $dbc, 'reorder' );
    $form .= "<H2>Note: Do not use this interface if your Protocol contains Branches</H2>";

    my $option_selector = SDB::HTML::option_selector(
        -form          => $form,
        -avail_list    => \@options,
        -avail_labels  => '',
        -picked_list   => \@options,
        -picked_labels => '',
        -title         => "Adjust order of Protocols as Required",
        -avail_header  => 'Drop from List',
        -picked_header => 'Ordered List of Protocols',
        -sort          => 1,
        -rm            => 'Save Re-Ordered Pipeline',
    );
    $form .= $option_selector->Printout(0);
    $form .= hidden( -name => 'Class', -value => $class, -force => 1 );
    $form .= hidden( -name => 'Pipeline_ID', -value => $pipeline_id, -force => 1 );
    $form .= hidden( -name => 'cgi_application', -value => 'alDente::Pipeline_App', -force => 1 );
    $form .= end_form();

    return $current . '<hr>' . $form;
}

return 1;
