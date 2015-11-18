##################
# Pipeline_App.pm #
##################
#
# This is a template for the use of various MVC App modules (using the CGI Application module)
#
package alDente::Pipeline_App;

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
use SDB::HTML;
use alDente::Pipeline_Views;
use alDente::SDB_Defaults qw(&get_cascade_tables);

##############################
# global_vars                #
##############################
use vars qw(%Configs);

################
# Dependencies #
################
#
# (document list methods accessed from external models)
#

############
sub setup {
############
    my $self = shift;

    $self->start_mode('home_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'home_page'                => 'home_page',
            'Home Page' => 'home_page',
            'summary_page'             => 'summary_page',
            'reset_pipeline'           => 'reset_Pipeline',
            'Add Pipeline Step'        => 'add_Step',
            'Delete Pipeline Step'     => 'delete_pipeline_step',
            'Re-Order Pipeline'        => 'reorder_Pipeline',
            'Save Re-Ordered Pipeline' => 'save_reordered_Pipeline',
        }
    );
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    my $dbc   = $self->param('dbc');
    my $q     = $self->query();
    my $admin = $q->param("Admin");
    if ( !$admin ) {    # check the user access in case no Admin param passed in
        my $access = $dbc->get_local('Access');
        if ( ( grep {/Admin/xmsi} @{ $access->{ $dbc->config('Target_Department') } } ) || $access->{'LIMS Admin'} ) {
            $admin = '1';
        }
    }
    my $Pipeline = new alDente::Pipeline( -dbc => $dbc );
    $self->param(
        'Pipeline_Model' => $Pipeline,

        #        'Object2_Model' => $object2,
    );
    $self->param( 'Admin' => $admin );

    return $self;
}

#####################
#
# home_page (default)
#
# Return: display (table)
#####################
sub home_page {
#####################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();
    my $id   = $args{-id} || $q->param('Pipeline_ID') || $q->param('ID');

    #    my $Pipeline = $args{-Pipeline} || new alDente::Pipeline(-dbc=>$dbc, -id=>$id);

    my $output = alDente::Pipeline_Views->home_page( -dbc => $dbc, -id => $id );

    return $output;
}

############################
# Concise summary view of data
# (useful for inclusion on library home page for example)
#
# Return: display (table) - smaller than for show_Progress
############################
sub summary_page {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->param('dbc');

    my $output;
    return $output;
}

###################
sub add_Step {
###################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query();

    my $pipeline_class = $q->param('Pipeline_Class');
    my $pipeline_id    = $q->param('Pipeline_ID');
    my $step           = $q->param('Pipeline_Step_Number');
    my $added_step     = $q->param("FK_${pipeline_class}__ID");

    my ($class_id) = $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE Object_Class = '$pipeline_class'" );

    my $pipeline_class_id = $dbc->get_FK_ID( "FK_${pipeline_class}__ID", $added_step );

    if ( $pipeline_id && $pipeline_class_id && $class_id ) {
        my ($max_step) = $dbc->Table_find( 'Pipeline_Step', 'Max(Pipeline_Step_Order)', "WHERE FK_Pipeline__ID =  $pipeline_id" );
        $max_step ||= 0;
        $step     ||= $max_step + 1;

        my $ok = $dbc->Table_append_array( 'Pipeline_Step', [ 'FK_Object_Class__ID', 'Object_ID', 'FK_Pipeline__ID', 'Pipeline_Step_Order' ], [ $class_id, $pipeline_class_id, $pipeline_id, $step ] );
        Message("Added Step $step to Pipeline : $added_step");
    }
    else {
        $dbc->error("Problem with Pipeline ($pipeline_id) OR Class ($pipeline_class=$pipeline_class_id : $class_id)");
    }

    my $output = alDente::Pipeline_Views->home_page( -dbc => $dbc, -id => $pipeline_id );

    return $output;
}

#########################
sub delete_pipeline_step {
#########################
    # Description:
    #   Remove a pipeline step for a given pipeline
    # Input:
    #   None
    # output:
    #   returns the Pipeline view home page
    # <snip>
    #   &cgi_application=alDente::Pipeline_App&rm=Delete Pipeline Step&Pipeline_ID=$id&Object_ID=$protocol_ids->[$index]&Pipeline_Step_ID=$step_ids->[$index]"
    # </snip>
####################################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query();

    my $pipeline_id      = $q->param('Pipeline_ID');
    my $object_id        = $q->param('Object_ID');
    my $pipeline_step_id = $q->param('Pipeline_Step_ID');

    if ( $pipeline_id && $object_id && $pipeline_step_id ) {
        $dbc->delete_record( -table => 'Pipeline_Step', -field => 'FK_Pipeline__ID', -value => $pipeline_id, -condition => "Object_ID = $object_id" );
        $dbc->delete_record( -table => 'Pipeline_StepRelationship', -field => 'FKParent_Pipeline_Step__ID', -value => $pipeline_step_id );
        $dbc->delete_record( -table => 'Pipeline_StepRelationship', -field => 'FKChild_Pipeline_Step__ID',  -value => $pipeline_step_id );
    }
    else {
        $dbc->error("Problem with Pipeline ($pipeline_id) OR Object ($object_id) OR Pipeline Step ID ($pipeline_step_id)");
    }

    my $output = alDente::Pipeline_Views->home_page( -dbc => $dbc, -id => $pipeline_id );
    return $output;
}

##############################################
#
# Local version of display if not standardized externally
#
#######################
sub _display_data {
#######################
    my $self = shift;

    my %args  = &filter_input( \@_, -args => 'data', -mandatory => 'data' );
    my $data  = $args{-data};
    my $title = $args{-title};

    my $Goals = HTML_Table->new( -title => $title, -class => 'small', -padding => 10 );
    $Goals->Set_Alignment( 'center', 5 );
    $Goals->Set_Headers( [ 'FK_Project__ID', "Library", 'Goal', 'Target<BR>(Initial + Work Requests)', 'Completed', ' (%)' ] );

    foreach my $lib ( sort keys %$data ) {
        $lib++;

        ## build up output table display ....
    }

    return $Goals->Printout(0);

}

#
#
# Simple view to reorder steps within a pipeline.
#
#
##########################
sub reorder_Pipeline {
##########################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query();

    my $pipeline_id = $q->param('Pipeline_ID');

    return alDente::Pipeline_Views->reorder_Pipeline_page( -dbc => $dbc, -pipeline_id => $pipeline_id );
}

#
# Save reordered pipeline steps
#
#
####################################
sub save_reordered_Pipeline {
####################################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query();

    my $pipeline_id = $q->param('Pipeline_ID');

    my $class = $q->param('Class') || 'Lab_Protocol';
    my ($class_id) = $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE Object_Class = '$class'" );

    my @picked = $q->param('Picked_Options');
    Message("Saving reordered Pipeline steps");
    if ( $class_id && $pipeline_id ) {
        $dbc->delete_records( 'Pipeline_Step', 'FK_Pipeline__ID', $pipeline_id, -cascade => get_cascade_tables('Pipeline_Step'), -quiet => 1 );
        my $step_num = 0;
        foreach my $step (@picked) {
            $step_num++;
            my ($picked_id) = $dbc->Table_find( $class, "${class}_ID", "WHERE ${class}_Name = '$step'" );
            if ($picked_id) {
                $dbc->Table_append_array( 'Pipeline_Step', [ 'FK_Object_Class__ID', 'Object_ID', 'Pipeline_Step_Order', 'FK_Pipeline__ID' ], [ $class_id, $picked_id, $step_num, $pipeline_id ] );
            }
            else {
                $dbc->warning("Undefined information for $step");
            }
        }
    }

    return alDente::Pipeline_Views->reorder_Pipeline_page( -dbc => $dbc, -pipeline_id => $pipeline_id );
}

return 1;
