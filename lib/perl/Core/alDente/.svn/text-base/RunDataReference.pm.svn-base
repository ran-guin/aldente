package alDente::RunDataReference;

=head1 NAME <UPLINK>

alDente::RunDataReference.pm 

=head1 SYNOPSIS <UPLINK>

my $ok = $obj->save_annotations(
                       -reference => ['50:A01','51:A01'],
                       -annot_type  => 'Sulston Score',
                       -annot_value => '5.32e-10'
                       );

my %result = $obj->get_annotation_sets(
                      -run_id           => 5000,
                      -well             => 'A01',
                      -annot_type       => 'Sulston Score'
                      );

my %result = $obj->get_annotation_value(
                      -reference=>['50:A01','50:A01'],
                      -annot_type       => 'Sulston Score'
                      );


=head1 DESCRIPTION <UPLINK>

Package that enables storing and retrieval of annotations set
for a group of one or more analyzed wells on Runs.           
    
=cut

use strict;
use Data::Dumper;

use RGTools::RGIO;
use SDB::DBIO;

###########################
# Constructor of the object
###########################
sub new {
#########
    my $this  = shift;
    my %args  = &filter_input( \@_, -args => 'dbc' );
    my $class = ref($this) || $this;

    my $self;
    $self->{dbc} = $args{-dbc};    # DB Handle

    bless $self, $class;
    return $self;
}

##############################
#
# Arguments:    'reference'              #  Data References
#               'annot_type'       #  RunDataAnnotation_Type_ID or RunDataAnnotation_Type_Name
#               'annot_value'      #  The value we are setting it to
#               'comments'         #  Optional comments
#               'quiet'            #  Supress the output
# Returns:      1 on success, 0 on failure
#
# <snip>
#      my $ok = $obj->save_annotations(
#                             -reference => ['50:A01','51:A01'],
#                             -annot_type  => 'Sulston Score',
#                             -annot_value => '5.32e-10'
#                             );
# </snip>
#
##############################
sub save_annotations {
##############################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'reference,annot_type,annot_value', -mandatory => 'reference,annot_type,annot_value' );

    my $reference   = $args{-reference};      #  Data References
    my $annot_type  = $args{-annot_type};     #  RunDataAnnotation_Type_ID or RunDataAnnotation_Type_Name
    my $annot_value = $args{-annot_value};    #  The value we are setting it to
    my $comments    = $args{-comments};       #  Optional comments
    my $quiet       = $args{-quiet};

    my $dbc = $self->{dbc};

    if ( $annot_type =~ /\D/ ) {
        ($annot_type) = $dbc->Table_find( 'RunDataAnnotation_Type', 'RunDataAnnotation_Type_ID', "WHERE RunDataAnnotation_Type_Name='$annot_type'" );
    }

    unless ($annot_type) {
        Message("Error: Invalid annotation type $args{-annot_type}") unless ($quiet);
        return 0;
    }

    unless ( ref($reference) =~ /array/i ) {
        Message("Error: 'reference' parameter must be an array reference") unless ($quiet);
        return 0;
    }

    my $emp_id       = $dbc->get_local('user_id');
    my @annot_fields = qw(FK_RunDataAnnotation_Type__ID Value FK_Employee__ID);
    my @annot_values = ( $annot_type, $annot_value, $emp_id );

    if ($comments) {
        push( @annot_fields, 'Comments' );
        push( @annot_values, $comments );
    }

    $dbc->start_trans('save_annotations');

    my $annot_entry_id = $dbc->Table_append_array( 'RunDataAnnotation', \@annot_fields, \@annot_values, -autoquote => 1 );

    my @ref_fields = qw(FK_Run__ID Well FK_RunDataAnnotation__ID);
    my %ref_values;

    my $index = 0;
    foreach my $run_info ( sort { $a <=> $b } @{$reference} ) {    ##Sorting not necessary...
        my ( $run_id, $well ) = split( ':', $run_info );
        $ref_values{ ++$index } = [ $run_id, $well, $annot_entry_id ];
    }

    $dbc->smart_append( 'RunDataReference', -fields => \@ref_fields, -values => \%ref_values, -autoquote => 1, -quiet => $quiet );

    $dbc->finish_trans('save_annotations');

    return 1;
}

##############################
#
# Arguments:    'run_id'                #  Run_ID of interest [mandatory]
#               'well'                  #  Specific field on the given Run [optional]
#               'annot_type'            #  RunDataAnnotation_Type_ID or RunDataAnnotation_Type_Name
#               'quiet'                 #  Supress the output
#
# Returns:      'annotations hash' on success, 'undef' on failure
#
# <snip>
#       my $score = $obj->get_annotation_sets(
#                             -run_id           => 5000,
#                             -well             => 'A01',
#                             -annot_type       => 'Sulston Score'
#                             );
#
#       print Dumper $score; ##
#    $VAR1 = [
#              {
#                'annotation_id' => '3',
#                'employee' => '141',
#                'value' => '80',
#                'runs' => [
#                            '5000',
#                            '5002'
#                          ],
#                'type' => 'Sulston Score',
#                'comments' => undef,
#                'datetime' => 'Sep-10-2007 14:57:34',
#                'wells' => [
#                             'A01',
#                             'A01'
#                           ]
#              },
#              ...
#              ];
# </snip>
##############################
sub get_annotation_sets {
##############################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'run_id,well', -mandatory => 'run_id' );

    my $run_id     = $args{-run_id};        #  Run_ID of interest
    my $well       = $args{-well};          #  Specific field on the given Run [optional]
    my $annot_type = $args{-annot_type};    #  RunDataAnnotation_Type_ID or RunDataAnnotation_Type_Name
    my $quiet      = $args{-quiet};

    my $dbc = $self->{dbc};

    if ( $annot_type =~ /\D/ ) {
        ($annot_type) = $dbc->Table_find( 'RunDataAnnotation_Type', 'RunDataAnnotation_Type_ID', "WHERE RunDataAnnotation_Type_Name='$annot_type'" );
        $args{-annot_type} = $annot_type;
    }

    unless ($annot_type) {
        Message("Invalid annotation type") unless ($quiet);
        return undef;
    }

    my @annotation_ids = @{ $self->_get_annotation_id_set(%args) };

    if (@annotation_ids) {
        return $self->_get_formated_annotations( -ids => \@annotation_ids );
    }
    else {
        return undef;
    }
}

##########################
# Arguments:    'reference'              #  Run_ID of interest [mandatory]
#               'annot_type'            #  RunDataAnnotation_Type_ID or RunDataAnnotation_Type_Name
#
# Returns:      'annotations hash' on success, 'undef' on failure
#
# <snip>
#       my $score = $obj->get_annotation_value(
#                             -reference=>['50:A01','50:A01'],
#                             -annot_type       => 'Sulston Score'
#                             );
#
#       print Dumper $score; ##
#       $VAR1 = [
#                 {
#                   'annotation_id' => '3',
#                   'employee' => '141',
#                   'value' => '80',
#                   'runs' => [
#                               '5000',
#                               '5002'
#                             ],
#                   'type' => 'Sulston Score',
#                   'comments' => undef,
#                   'datetime' => 'Sep-10-2007 14:57:34',
#                   'wells' => [
#                                'A01',
#                                'A01'
#                              ]
#                 },
#                 ...
#                 ];
##########################
sub get_annotation_value {
##########################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'reference,annot_type', -mandatory => 'reference,annot_type' );

    my $reference  = $args{-reference};     #  Run_ID of interest [mandatory]
    my $annot_type = $args{-annot_type};    #  RunDataAnnotation_Type_ID or RunDataAnnotation_Type_Name

    my $dbc = $self->{dbc};

    my $annotation_id = $self->_get_annotation_id(%args);

    if ($annotation_id) {
        return $self->_get_formated_annotations($annotation_id);
    }
    else {
        return undef;
    }

}

##########################
sub _get_annotation_id {
##########################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'reference,annot_type', -mandatory => 'reference,annot_type' );

    my @run_wells  = Cast_List( -list => $args{-reference}, -to => 'array' );
    my $annot_type = $args{-annot_type};                                        #  RunDataAnnotation_Type_ID or RunDataAnnotation_Type_Name
    my $quiet      = $args{-quiet};

    my $dbc = $self->{dbc};

    if ( $annot_type =~ /\D/ ) {
        ($annot_type) = $dbc->Table_find( 'RunDataAnnotation_Type', 'RunDataAnnotation_Type_ID', "WHERE RunDataAnnotation_Type_Name='$annot_type'" );
        $args{-annot_type} = $annot_type;
    }

    unless ($annot_type) {
        Message("Invalid annotation type") unless ($quiet);
        return undef;
    }

    my ( $first_run, $first_well ) = split( ':', $run_wells[0] );
    my $annotation_sets = $self->get_annotation_sets( -run_id => $first_run, -well => $first_well, -annot_type => $annot_type );

    my $run_wells_list = join ',', sort @run_wells;

    if ($annotation_sets) {
        my @sets = @{$annotation_sets};
        foreach my $set (@sets) {
            ### Create run/well list for this set, then compare it with the supplied @run_wells
            my @local_run_well;
            for ( my $i = 0; $i < int( @{ $set->{runs} } ); $i++ ) {
                push( @local_run_well, $set->{runs}->[$i] . ':' . $set->{wells}->[$i] );
            }
            my $local_run_wells_list = join ',', sort @local_run_well;

            my $a = join( ',', @local_run_well );
            if ( $a eq $run_wells_list ) {
                return $set->{annotation_id};
            }
        }
    }
    ### If nothing found... return undef
    return undef;

}

##########################
sub _get_annotation_id_set {
##########################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'run_id,well', -mandatory => 'run_id' );

    my $run_id     = $args{-run_id};        #  Run_ID of interest
    my $well       = $args{-well};          #  Specific field on the given Run [optional]
    my $annot_type = $args{-annot_type};    #  RunDataAnnotation_Type_ID or RunDataAnnotation_Type_Name
    my $quiet      = $args{-quiet};

    my $dbc = $self->{dbc};

    my $condition = "FK_RunDataAnnotation__ID=RunDataAnnotation_ID AND FK_RunDataAnnotation_Type__ID ='$annot_type' AND FK_Run__ID=$run_id";
    if ($well) {
        $condition .= " AND Well='$well'";
    }

    return [ $dbc->Table_find( 'RunDataReference,RunDataAnnotation', 'FK_RunDataAnnotation__ID', "WHERE $condition" ) ];
}

############################
#
#
#
############################
sub _get_formated_annotations {
############################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'ids' );

    my $ids = Cast_List( -list => $args{-ids}, -to => 'string' );

    my $dbc = $self->{dbc};

    my %results = $dbc->Table_retrieve(
        'RunDataReference,RunDataAnnotation,RunDataAnnotation_Type',
        [ 'FK_Run__ID', 'Well', 'Value', 'RunDataAnnotation_ID', 'RunDataAnnotation_Type_Name', 'FK_Employee__ID', 'Date_Time', 'Comments' ],
        "WHERE FK_RunDataAnnotation__ID=RunDataAnnotation_ID AND RunDataAnnotation_Type_ID=FK_RunDataAnnotation_Type__ID AND RunDataAnnotation_ID IN ($ids)"
    );

    %results = %{ rekey_hash( \%results, 'RunDataAnnotation_ID' ) };

    my @annotations;
    foreach my $annot_id ( sort { $a <=> $b } keys %results ) {
        push(
            @annotations,
            {   runs          => $results{$annot_id}{FK_Run__ID},
                wells         => $results{$annot_id}{Well},
                type          => $results{$annot_id}{RunDataAnnotation_Type_Name}->[0],
                value         => $results{$annot_id}{Value}->[0],
                employee      => $results{$annot_id}{FK_Employee__ID}->[0],
                datetime      => $results{$annot_id}{Date_Time}->[0],
                comments      => $results{$annot_id}{Comments}->[0],
                annotation_id => $annot_id
            }
        );
    }
    return \@annotations;
}

return 1;

