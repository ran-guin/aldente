###################################################################################################################################
# alDente::Priority_Object.pm
#
#
#
###################################################################################################################################
package alDente::Priority_Object;
use strict;
use Data::Dumper;

## SDB modules
use SDB::DBIO;
## RG Tools
use RGTools::RGIO;
## alDente modules

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $self;
    $self->{dbc} = $dbc;

    my ($class) = ref($this) || $this;
    bless $self, $class;

    return $self;
}

##################
sub set_priority {
##################
    my $self           = shift;
    my %args           = filter_input( \@_, -args => 'priority,priority_date,object_class,object_id,description', -mandatory => 'priority,object_class,object_id' );
    my $priority       = $args{-priority};                                                                                                                             # either priority_value or priority_label
    my $priority_date  = $args{-priority_date};                                                                                                                        # either priority_value or priority_label
    my $object_class   = $args{-object_class};
    my $object_id      = $args{-object_id};
    my $description    = $args{-description} || '';
    my $dbc            = $self->{dbc};
    my @valid_priority = $dbc->get_enum_list( 'Priority_Object', 'Priority_Value' );

    my $ok;
    my $dbc = $self->{dbc};

    if ( $object_id && $object_class ) {
        my ($object_class_id) = $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE Object_Class = '$object_class'" );
        if ( grep /^$priority$/, @valid_priority ) {
            my @fields = ( 'FK_Object_Class__ID', 'Object_ID', 'Priority_Value', 'Priority_Description' );
            my @values = ( $object_class_id, $object_id, $priority, $description );
            if ($priority_date) {
                push @fields, 'Priority_Date';
                push @values, $priority_date;
            }
            $ok = $dbc->Table_append_array( 'Priority_Object', \@fields, \@values, -autoquote => 1 );
        }
        else {
            $dbc->error("Invalid Priority value ($priority)");
        }
    }

    return $ok;
}

#####################
sub update_priority {
#####################
    my $self          = shift;
    my %args          = filter_input( \@_, -args => 'priority,priority_date,object_class,object_id,override,description,quiet', -mandatory => 'priority,object_class,object_id' );
    my $priority      = $args{-priority};                                                                                                                                            # either priority_value or priority_label
    my $priority_date = $args{-priority_date};                                                                                                                                       # either priority_value or priority_label
    my $object_class  = $args{-object_class};
    my $object_id     = $args{-object_id};
    my $override      = $args{-override};
    my $description   = $args{-description} || '';
    my $quiet         = $args{-quiet};
    my $dbc           = $self->{dbc};
    my $ok            = 0;

    ## check if the priority has already been set

    my ($object_class_id) = $dbc->Table_find( 'Object_Class',    'Object_Class_ID',    "WHERE Object_Class = '$object_class'" );
    my ($priority_exists) = $dbc->Table_find( 'Priority_Object', 'Priority_Object_ID', "WHERE Object_ID = '$object_id' and FK_Object_Class__ID = $object_class_id" );
    my @valid_priority = $dbc->get_enum_list( 'Priority_Object', 'Priority_Value' );

    ## if existing
    if ( $priority_exists && $override ) {
        if ( grep /^$priority$/, @valid_priority ) {
            my @fields = ( 'Priority_Value', 'Priority_Description', 'Priority_Date' );
            my @values = ( $priority, $description, $priority_date );

            #if( $priority_date ) {
            #	push @fields, 'Priority_Date';
            #	push @values, $priority_date;
            #}
            $ok = $dbc->Table_update_array( 'Priority_Object', \@fields, \@values, "WHERE FK_Object_Class__ID = $object_class_id and Object_ID = '$object_id'", -autoquote => 1 );
        }
        else {
            Message("Invalid Priority value ($priority)") if ( !$quiet );
        }
    }
    elsif ( !$priority_exists ) {
        Message("$object_class $object_id no priority set up yet") if ( !$quiet );
    }
    else {
        Message("Must provide override flag to update priority") if ( !$quiet );
    }

    return $ok;
}
##################
sub get_priority {
##################
    my $self         = shift;
    my %args         = filter_input( \@_, -args => 'object_class,object_id', -mandatory => 'object_class,object_id' );
    my $object_id    = $args{-object_id};
    my $object_class = $args{-object_class};
    my $dbc          = $self->{dbc};
    my $priority;
    ($priority) = $dbc->Table_find( 'Priority_Object,Object_Class', 'Priority_Value', "WHERE Object_ID = '$object_id' and Object_Class = '$object_class' and Object_Class_ID = FK_Object_Class__ID" );

    return $priority;
}

#################################
#
# Get all the supported priority values
#
#################################
sub get_valid_priorities {
#################################
    my $self           = shift;
    my $dbc            = $self->{dbc};
    my @valid_priority = $dbc->get_enum_list( 'Priority_Object', 'Priority_Value' );
    return @valid_priority;
}

1;
