package alDente::Plate_Schedule;

use RGTools::RGIO;
use Data::Dumper;
use SDB::HTML;
use SDB::DB_Object;
use strict;
use CGI qw(:standard);
use base qw(SDB::DB_Object);

#########
sub new {
#########
    my $class             = shift;
    my %args              = filter_input( \@_, -args => 'dbc' );
    my $dbc               = $args{-dbc};
    my $plate_schedule_id = $args{-plate_schedule_id} || $args{-id};
    $class = ref $class if ref $class;
    my $self = SDB::DB_Object->new( -dbc => $dbc, -tables => 'Plate_Schedule' );

    $self->{dbc} = $args{-dbc};
    $self->{id}  = $plate_schedule_id;

    if ( $self->{id} ) {
        $self->primary_value( -table => 'Plate_Schedule', -value => $self->{id} );
        $self->load_Object();
    }
    bless $self, $class;
}

# Get the plate schedules for the parent plate and record them for the child plate
#
# Return: number of records added
############################
sub inherit_plate_schedule {
##############################
    my $self          = shift;
    my %args          = filter_input( \@_, -args => 'plate_id' );
    my $plate_id      = $args{-plate_id};
    my $records_added = 0;
    ## Find the parent plate
    my ($parent_plate) = $self->{dbc}->Table_find( 'Plate', 'FKParent_Plate__ID', "WHERE Plate_ID = $plate_id" );
    if ($parent_plate) {
        ## Get the plate_schedule records from the parent plate
        my $plate_schedule = $self->get_plate_schedule( -plate_id => $parent_plate );

        my $pipelines = $plate_schedule->{FK_Pipeline__ID};
        if ($pipelines) {
            ## Add the plate_schedule records for the plate
            $records_added = $self->add_plate_schedule( -plate_id => $plate_id, -pipeline_id => $pipelines );
        }
    }

    return $records_added;
}

# Add plate schedule records
#
# Usage:  $self->add_plate_schedule(-plate_id=>$plate_id,-pipeline_id=>[1,2,3]);
#
# Return: number of records added
########################
sub add_plate_schedule {
########################
    my $self        = shift;
    my %args        = filter_input( \@_, -args => 'plate_id,pipeline_id', -mandatory => 'plate_id,pipeline_id' );
    my $plate_id    = $args{-plate_id};                                                                             ## Scalar plate id
    my $pipeline_id = $args{-pipeline_id};                                                                          ## Arrayref of pipelines ids
    my $priority    = $args{-priority};                                                                             ## optional priority value (use if adding pipeline that is NOT the last scheduled pipeline)

    my @plate_ids = Cast_List( -list => $plate_id, -to => 'Array' );

    my @pipeline_ids = Cast_List( -list => $pipeline_id, -to => "Array" );
    my %values;
    my $index           = 1;
    my $pipeline_number = 0;
    foreach my $plate_id (@plate_ids) {
        $pipeline_number = 0;
        foreach my $pipeline (@pipeline_ids) {
            push @{ $values{$index} }, $plate_id;
            push @{ $values{$index} }, $pipeline;
            if ($priority) {
                push @{ $values{$index} }, $priority + $pipeline_number;
            }

            $pipeline_number++;
            $index++;
        }
    }

    my @fields = qw(FK_Plate__ID FK_Pipeline__ID);

    if ($priority) {
        ## bump up current priority values to make space for new priority values (if applicable) ##
        my $plate_list = join ',', @plate_ids;
        $self->{dbc}->Table_update_array( 'Plate_Schedule', ['Plate_Schedule_Priority'], ["Plate_Schedule_Priority + $pipeline_number"], "WHERE Plate_Schedule_Priority >= $priority AND FK_Plate__ID IN ($plate_list)", -degug => 1 );
        push @fields, 'Plate_Schedule_Priority';
    }

    my $records_added = $self->{dbc}->smart_append( 'Plate_Schedule', \@fields, \%values );
    return $records_added;
}

# Get the schedule of pipelines for a given plate
#
# Usage:  my $schedule = $self->get_plate_schedule(-plate_id=>5000);
#
# Return: Plate schedule Hashref
########################
sub get_plate_schedule {
########################
    my $self     = shift;
    my %args     = filter_input( \@_, -args => 'plate_id' );
    my $plate_id = $args{-plate_id};
    $plate_id = Cast_List( -list => $plate_id, -to => 'String' );

    my %plate_schedule = $self->{dbc}->Table_retrieve( 'Plate_Schedule', [ 'Plate_Schedule_ID', 'Plate_Schedule_Priority', 'FK_Pipeline__ID' ], "WHERE FK_Plate__ID IN  ($plate_id) ORDER BY Plate_Schedule_Priority" );

    return \%plate_schedule;
}

# Get the schedule of pipelines for a given plate
#
# Usage:  my $schedule = $self->get_plate_schedule(-plate_id=>5000);
#
# Return: Plate schedule Hashref
########################
sub get_plate_schedule_codes {
########################
    my $self         = shift;
    my %args         = filter_input( \@_, -args => 'plate_number,library', );
    my $library      = $args{-library};
    my $plate_number = $args{-plate_number};
    my $format       = $args{'-format'} || 'Arrayref';

    my @plate_schedule_codes = $self->{dbc}->Table_find(
        'Plate_Schedule,Pipeline,Plate',
        'Pipeline_Code',
        "WHERE FK_Plate__ID = Plate_ID and Plate_Number = $plate_number and FK_Library__Name = '$library' and Plate_Schedule.FK_Pipeline__ID = Pipeline_ID ORDER BY Plate_Schedule_Priority",
        -distinct => 1
    );

    if ( $format eq 'String' ) {
        return Cast_List( -list => \@plate_schedule_codes, -to => 'String' );
    }
    return \@plate_schedule_codes;
}

############################
sub plate_schedule_trigger {
############################
    my $self               = shift;
    my $dbc                = shift || $self->{dbc};
    my $id                 = $self->value('Plate_Schedule.Plate_Schedule_ID');
    my $plate_id           = $self->value('Plate_Schedule.FK_Plate__ID');
    my $priority           = $self->value('Plate_Schedule.Plate_Schedule_Priority');
    my $scheduled_pipeline = $self->value('FK_Pipeline__ID');

    my ($default_pipeline) = $dbc->Table_find( 'Plate', 'FK_Pipeline__ID', "WHERE Plate_ID = $plate_id" );
    if ($default_pipeline) {
        ## place default pipeline as the first scheduled pipeline (unless the default pipeline is already included) ##
        ## (this is necessary to: simplify form entry, and simultaneously allow for no scheduling option ##
        my ($included) = $dbc->Table_find( 'Plate_Schedule', "count(*)", "WHERE FK_Plate__ID=$plate_id AND FK_Pipeline__ID=$default_pipeline" );
        if ( !$included ) { $self->add_plate_schedule( -plate_id => $plate_id, -pipeline_id => $default_pipeline, -priority => 1 ) }
    }

    ## Update the Plate_Schedule_Priority (if not specified) - set to max(priority) + 1
    if ( !$priority ) {
        $self->_update_plate_schedule_priority( $id, $plate_id );
    }
    return 1;
}

###############################################
# Update the plate schedule for a given plate
#
# Usage: my $updated = $self->update_plate_schedule(-plate_id=>5000,-pipeline_id=>[1,2]);
# Return: number of records updated
###########################
sub update_plate_schedule {
###########################
    my $self        = shift;
    my %args        = filter_input( \@_, -args => 'plate_id,pipeline_id', -mandatory => 'plate_id' );
    my $plate_id    = $args{-plate_id};                                                                 # scalar plate_id
    my $pipeline_id = $args{-pipeline_id};                                                              # Arrayref of pipeline ids

    my @pipeline_ids = Cast_List( -list => $pipeline_id, -to => "Array" );

    ## Delete the plate schedule records for the plate
    $self->delete_plate_schedule( -plate_id => $plate_id );

    ## Add the new plate schedules for the plate
    if (@pipeline_ids) {
        my $updated = $self->add_plate_schedule( -plate_id => $plate_id, -pipeline_id => \@pipeline_ids );
        return $updated;
    }
    return 0;
}

#################################################
# Delete the plate schedules for a given plate
#
# Usage:  my $records_deleted = $self->delete_plate_schedule(-plate_id=>5000);
# Return: number of records deleted
###########################
sub delete_plate_schedule {
###########################
    my $self     = shift;
    my %args     = filter_input( \@_, -args => 'plate_id', -mandatory => 'plate_id' );
    my $plate_id = $args{-plate_id};

    ## get the schedule ids
    my $plate_schedule = $self->get_plate_schedule( -plate_id => $plate_id );
    my $ids = $plate_schedule->{Plate_Schedule_ID};
    $ids = Cast_List( -list => $ids, -to => "String" );
    if ($ids) {
        my $records_deleted = $self->{dbc}->delete_records(
            -dbc     => $self->{dbc},
            -table   => 'Plate_Schedule',
            -dfield  => 'Plate_Schedule_ID',
            -id_list => $ids,
            -quiet   => 1
        );
        return $records_deleted;
    }
    else {
        return 0;
    }
}

# Update the plate_schedule priority for a given plate
#
#
#####################################
sub _update_plate_schedule_priority {
#####################################
    my $self        = shift;
    my %args        = filter_input( \@_, -args => 'schedule_id,plate_id' );
    my $schedule_id = $args{-schedule_id};                                    # Plate Schedule ID
    my $plate_id    = $args{-plate_id};                                       # ID of the scheduled plate

    ## find the next priority number for the plate
    my ($priority) = $self->{dbc}->Table_find( 'Plate_Schedule', 'MAX(Plate_Schedule_Priority)', "WHERE FK_Plate__ID = $plate_id" );

    my $ok = $self->{dbc}->Table_update_array( 'Plate_Schedule', ["Plate_Schedule_Priority"], [ ++$priority ], "WHERE Plate_Schedule_ID = $schedule_id" );

    return 1;
}

sub update_plate_schedule_btn {
    my $self = shift;
    return submit( -name => 'Update_Plate_Schedule', -value => "Update Plate Schedule", -class => 'Action' );
}

sub catch_update_plate_schedule_btn {
    my $self      = shift;
    my @plates    = param('Plate_ID');
    my $pipelines = get_Table_Params( -field => 'FK_Pipeline__ID', -dbc => $self->{dbc} );
    $pipelines = $self->{dbc}->get_FK_ID( 'FK_Pipeline__ID', $pipelines );

    foreach my $plate (@plates) {
        my $updated = $self->update_plate_schedule( -plate_id => $plate, -pipeline_id => $pipelines );
    }
    Message("Updated schedule for plates");
}
return 1;

=head1 NAME <UPLINK>

alDente::Plate_Schedule.pm 

=head1 SYNOPSIS <UPLINK>

    require alDente::Plate_Schedule;
    my $plate_schedule = alDente::Plate_Schedule->new(-dbc=>$self->{dbc});
    my $num_records = $plate_schedule->inherit_plate_schedule(-plate_id=>$id);

    my $added = $plate_schedule->add_plate_schedule(-plate_id=>$plate_id,-pipeline_id=>[1,2,3]);

    my $schedule = $plate_schedule->get_plate_schedule(-plate_id=>5000);
    
    my $ok = $plate_schedule->_update_plate_schedule_priority(-schedule_id=>1,-plate_id=>5000);
    
    my $updated = $self->update_plate_schedule(-plate_id=>5000,-pipeline_id=>[1,2]);
    
=head1 DESCRIPTION <UPLINK>

Package that allows plates to be scheduled into a set of pipelines. The schedule of a plate is passed on to its daughters.  The schedule for a plate can be updated.          
    
=cut

