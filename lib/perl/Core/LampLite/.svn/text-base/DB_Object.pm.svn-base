###############################################################
# DB_Object.pm
#
#
####################################################################################################
# $Id: DB_Object.pm,v 1.112 2004/11/30 23:05:38 mariol Exp $
####################################################################################################
package LampLite::DB_Object;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

DB_Object.pm -

=head1 SYNOPSIS <UPLINK>

=cut

##############################
# superclasses               #
##############################


##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use Data::Dumper;
use Carp;

#use AutoLoader;
##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;

##############################
# global_vars                #
##############################
### Global variables

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
##################

##############################
# constructor                #
##############################

##############################
# my $set_fields;
# my $set_condition;
# my $set_id;
# my $set_add_table;
##############################

##################
sub new {
##################
    #
    # Constructor of the object
    #
    my $this = shift;
    my $class = ref($this) || $this;

    my %args = &filter_input( \@_, -args => 'dbc' );
    my $frozen = $args{-frozen} || 0;                                                                # Reference to frozen object if there is any. [Object]
    my $dbc    = $args{-dbc};
    my $table  = $args{-table}  || $args{-tables};
    my $fields = $args{-fields} || [];
    my $id     = $args{-id};
    my $load   = $args{-load};
    my $debug = $args{-debug};

    # allow no initialization for loading from XML
    my $initialize = 1;
    if ( ( defined $args{-initialize} ) && ( $args{-initialize} == 0 ) ) {
        $initialize = 0;
    }

    my $self = $this->Object::new(%args);
    bless $self, $class;
    
    $self->{debug} = $debug;
    $self->{dbc}   = $dbc;

    if ($frozen) { return $self }    # If frozen then return now with the new dbc handle.

    $self->{multi} = $args{-multi} || 0;    # Temporary flag to indicate using multipe version or not
    $self->{include_fields} = Cast_List( -list => $args{-include_fields}, -to => 'arrayref' );    # Explicitly specify the list of fields to include
    $self->{exclude_fields} = Cast_List( -list => $args{-exclude_fields}, -to => 'arrayref' );    # Explicitly specify the list of fields to exclude
    $self->{fields_list}    = $fields;                                                                 # A list of fields
    $self->{fields}         = {};                                                                 # Hash of all the fields of the object
    $self->{record_count}   = 0;                                                                  # Number of records currently in the object
    $self->{primary_fields} = {};                                                                 # A hash that contains the primary field for each table
    $self->{record_index}   = {};                                                                 # An index hash for faster retrieval of records
    $self->{newids}         = {};                                                                 # New primary values from the previous INSERT operation
    $self->{no_joins}       = [];                                                                 # Specify an arrayref of tables not to be joined

    # A list of tables that the object will spend (defaulted to current class)
    my $table_ref = Cast_List( -list => $table || $class, -to => 'arrayref' );
    if ( $table_ref->[0] =~ /DB_Object/i ) {
        $self->{tables} = [];
    }
    else {
        $self->{tables} = $table_ref;
    }


    $self->{DB_table} = $table;
    $self->{id}       = $id;

    if ($load && $self->{loaded}{$table} ne $id) {
        $self->load_Object();
    }
    
    return $self;
}

#
# Quick accessor to View module
#
#
###########
sub Model {
###########
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $id    = $args{-id};
    my $class = $args{-class} || ref $self;
 
    my %pass_args  = @_;

    my $dbc = $self->dbc();

    if ( !$class || $class =~ /::$/ ) { $class = 'Model' }

    $class =~s/(.+):://;  ## truncate scope to enable dynamic loading
    
    $class = $dbc->dynamic_require($class);

    my $Model = $class->new( -dbc => $dbc, -id => $id, %pass_args );

    $Model->{dbc} = $dbc;
    return $Model;
}

#
# Quick accessor to View module
#
#
###########
sub View {
###########
    my $self  = shift;
    my %args  = filter_input( \@_, -args => 'id,class' );
    my $id    = $args{-id} || $self->{id};
    my $class = $args{-class} || ref $self;
    my $dbc   = $args{-dbc} || $self->{dbc};

    if ( UNIVERSAL::isa( $self, "LampLite::DB" ) ) { $dbc = $self; }

    my $view_class = $class;
    $view_class .= '_Views';
    $args{-dbc} = $dbc;

    eval "require $view_class";
    my $View = $view_class->new(%args);
    $View->{Model} = $self;

    if ($id) { $View->{id} = $id; }
    return $View;
}

##############################
# public_methods             #
##############################

############
sub reset {
############
    my $self = shift;
    my $dbc  = shift;

    if ($dbc) { $self->{dbc} = $dbc }

}

##################
# dbc Accessor
#
# Return: database handle
#######
sub dbc {
########
    my $self = shift;
    my $value = shift;
    
    if ($value) { $self->{dbc} = $value }
    
    return $self->{dbc};
}

########
sub get {
########
    my $self  = shift;
    my $field = shift;

    if ( $field && defined $self->{$field} ) {
        ### Attribute retrieval subroutine ##
        return $self->{$field};
    }
    else {
        return undef;
    }
}

########
sub set {
########
    my $self  = shift;
    my $field = shift;
    my $value = shift;

    if ( $field && defined $value ) {
        ### Attribute retrieval subroutine ##
        return $self->{$field} = $value;
    }
    else {
        return 0;
    }
}

#
# Load generic object 
#
# Updates:
#   $self->{record_count}
#   $self->{fields}{$table}{$field}{values}
#   $self->{loaded}{$table}
#
# Return: updated keys in self
###################
sub load_Object {
###################
    my $self = shift;
    my %args = filter_input(\@_);
    my $id = $args{-id} || $self->{id};
    my $table = $args{-table} || $self->{DB_table};
    my $fields = $args{-fields} || '*';
    my $condition = $args{-condition} || 1;
    my $dbc = $args{-dbc} || $self->{dbc};
    my $debug = $args{-debug};
    
    my $multiple;

    my $primary = $dbc->primary_field($table) || "Employee_ID";
    if ($id) { 
        my $ids = Cast_List(-list=>$id, -to=>'string', -autoquote=>1);
        $condition .= " AND $primary IN ($ids)";
        
        if ($ids =~ /,/) { $multiple = 1 }   ### single record only ###
    }
    else { $multiple = 1 }
    
    my $sql = "SELECT $fields FROM $table WHERE $condition";
    my $hash = $dbc->hash(-sql=>$sql, -debug => $debug );

    $self->{record_count} = 0;
    my %ret;

    my %info = %{ $hash } if $hash;
    if (%info) {
        foreach my $field ( sort { $a <=> $b } keys %info ) {
            my @values = @{ $info{$field} };
            @{ $self->{fields}->{$table}->{$field}->{values} } = @values;

            $self->{record_count} = int( @{ $info{$field} } );

            #Set the record index if this is the primary field of the table
            if ( $field eq $primary ) {
                my $i = 0;
                map { $self->{record_index}->{$table}->{$_} = $i++ } @values;
            }
        }
        foreach my $field ( keys %info ) {
            if ($multiple) {    ## Return format:  $info{"Library.Library_Name"} = ['CN001']
                $ret{$field} = $info{$field};
            }
            else {              ## Return format:  $info{"Library.Library_Name"} = 'CN001'
                $ret{$field} = $info{$field}->[0];
            }
        }

        $self->{loaded}{$table} = $id;
        return \%ret;
    }
    else {
         return;
    }
}

##################
sub Object_data {
##################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'field');
    my $table = $args{-table} || $self->{DB_table};
    my $field = $args{-field};
    my $index = $args{-index} || 0;
   
    my $dbc = $args{-dbc} || $self->{dbc};
    if (! $dbc->table_loaded($table) ) {
        print "$table object not loaded - data not available<BR>";
        return;
    }
    
    my $val = $self->{fields}{$table}{$field}{values};
    if (defined $index) { return $val->[$index] }
    
    return $val;
}

1;
