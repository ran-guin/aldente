#!/usr/bin/perl
###################################################################################################################################
# QC_Batch.pm
#
###################################################################################################################################
package alDente::QC_Batch;

##############################
# perldoc_header             #
##############################

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(SDB::DB_Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);
use Data::Dumper;

#use Benchmark;

##############################
# custom_modules_ref         #
##############################
use SDB::CustomSettings;
use SDB::HTML;
use SDB::DBIO;
use alDente::Validation;
use SDB::DB_Object;

use SDB::DB_Form_Viewer;
use SDB::DB_Form;
use SDB::Session;
use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;
use RGTools::RGmath;

use alDente::QC_Batch_Views;
##############################
# global_vars                #
##############################
use vars qw( $user $table);
use vars qw($MenuSearch $scanner_mode %Settings $Connection);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
##############################
# constructor                #
##############################

### Global variables

### Modular variables

###########################
# Constructor of the object
###########################

##############################
# public_methods             #
##############################

#
# Constructor of the object
#
###########
sub new {
###########
    my $this = shift;
    my $class = ref($this) || $this;

    my %args        = filter_input( \@_ );
    my $ids         = $args{-ids};
    my $dbc         = $args{-dbc};                      # Database handle
    my $batch_id    = $args{-batch_id} || $args{-id};
    my $untracked   = $args{-untracked};
    my $batch_class = $args{-class};
    my $name        = $args{-name};                     # QC Batch Type Name
    my $comments    = $args{-comments};
    my $catalog_id  = $args{-catalog_id};
    my $solution_id = $args{-solution_id};              ## for untracked items (eg agarose solution applied to Agar plates)
    my $count       = $args{-count};                    ## number of items (only needed if untracked ids used)

    my $qc_batch_type_id = $dbc->get_FK_ID( -field => 'FK_QC_Batch_Type__ID', -value => $name );

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => 'QC_Batch' );

    bless $self, $class;

    if ($batch_id) {
        $self->{batch_id} = $batch_id;
        $self->{id}       = $batch_id;
    }
    elsif ( $ids && $batch_class ) {
        $self->{batch_id} = $self->define_Batch( $dbc, -class => $batch_class, -ids => $ids, -qc_batch_type_id => $qc_batch_type_id, -comments => $comments, -catalog_id => $catalog_id );
        $self->{id} = $self->{batch_id};
    }
    elsif ($untracked) {
        $self->{batch_id} = $self->define_Batch( $dbc, -class => 'Untracked', -solution_id => $solution_id, -ids => '0', -qc_batch_type_id => $qc_batch_type_id, -comments => $comments, -count => $count );
        $self->{id} = $self->{batch_id};
    }

    if ( $self->{id} ) {
        $self->primary_value( -table => 'QC_Batch', -value => $self->{id} );
    }

    $self->{dbc}     = $dbc;
    $self->{records} = 0;      ## number of records currently loaded

    return $self;
}

##############################
sub new_QC_Batch_trigger {
##############################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $dbc             = $self->{dbc};
    my $starting_number = $args{-number};
    my $debug           = $args{-debug} || 0;

    $self->load_Object( -force => 1, -quick_load => 1 );

    my $qc_batch_type_id = 0;
    my $name             = $args{-name};
    if ($name) {
        $qc_batch_type_id = $dbc->get_FK_ID( -field => 'FK_QC_Batch_Type__ID', -value => $name );
    }
    else {
        $qc_batch_type_id = $self->value('QC_Batch.FK_QC_Batch_Type__ID');
    }

    my $id = $self->{batch_id} || $self->value('QC_Batch.QC_Batch_ID');

    if ( !$starting_number ) {
        ($starting_number) = $dbc->Table_find( 'QC_Batch', 'Max(QC_Batch_Number)', "WHERE FK_QC_Batch_Type__ID = $qc_batch_type_id", -debug => $debug );
        $starting_number ||= 0;
        $starting_number++;
    }

    my $ok;
    $ok = $dbc->Table_update( 'QC_Batch', 'QC_Batch_Number', $starting_number, "WHERE QC_Batch_ID = $id", -debug => $debug );

    return $ok;
}

##################
sub home_page {
##################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my $id   = $self->{id};

    print alDente::QC_Batch_Views::Batch_home( $dbc, $id );
    return 1;
}

#
# Define a new QC batch of records
#
#
#
#
######################
sub define_Batch {
######################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc,class,ids', -mandatory => 'dbc,class,ids' );

    my $dbc              = $args{-dbc};
    my $class            = $args{-class};
    my $qc_batch_type_id = $args{-qc_batch_type_id};
    my $ids              = $args{-ids};
    my $catalog_id       = $args{-catalog_id};
    my $solution_id      = $args{-solution_id};

    my $comments = $args{-comments} || '';
    my $debug = $args{-debug};

    my @id_list = split ',', $ids;
    my $count = $args{-count} || int(@id_list);

    $dbc->start_trans('new_batch');
    Message("Insert QC_Batch, QC_Batch_Member records ($class: $ids)");

    my @fields = ( 'FK_QC_Batch_Type__ID', 'QC_Batch_Initiated', 'FK_Employee__ID', 'QC_Batch_Status', 'QC_Batch_Notes', 'Batch_Count' );
    my @values = ( $qc_batch_type_id, date_time(), $dbc->get_local('user_id'), 'Pending', $comments, $count );

    if ($catalog_id) {
        push @fields, 'FK_Stock_Catalog__ID';
        push @values, $catalog_id;
    }

    if ($solution_id) {
        push @fields, 'FK_Solution__ID';
        push @values, $solution_id;
    }

    my $batch_id = $dbc->Table_append_array(
        'QC_Batch',
        \@fields,
        \@values,
        -autoquote => 1,
        -debug     => $debug
    );

    my ($class_id) = $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE Object_Class = '$class'" );

    if ( !$class_id ) { return $dbc->session->error("Unrecognized class: '$class'") }
    if ( !$ids && ( $class !~ /Untracked/i ) ) { return $dbc->session->error("No ids in batch") }

    ## set up QC_Batch_Member records as well (initially quarantined) ##

    my @fields = ( 'FK_QC_Batch__ID', 'FK_Object_Class__ID', 'Object_ID', 'QC_Member_Status', 'Batch_Count' );
    my %values;
    my $i = 0;
    foreach my $id (@id_list) {
        $i++;
        push @{ $values{$i} }, ( $batch_id, $class_id, $id, 'Quarantined' );
    }

    my $members = $dbc->simple_append( 'QC_Batch_Member', -fields => \@fields, -values => \%values, -autoquote => 1, -debug => $debug );

    if ( $ids && $self->local_QC_tracking($class) ) { $dbc->Table_update( $class, 'QC_Status', 'Pending', "WHERE ${class}_ID IN ($ids)", -autoquote => 1 ) }

    $dbc->finish_trans('new_batch');
    return $batch_id;
}

##################
sub set_Batch {
##################
    my $self = shift;

    my %args     = filter_input( \@_, -args => 'dbc,batch_id,status', -mandatory => 'dbc,batch_id,status' );
    my $dbc      = $args{-dbc};
    my $batch_id = $args{-batch_id};
    my $status   = $args{-status};
    my $comments = $args{-comments};

    Message("Set QC status of Batch to $status");
    my @fields = ('QC_Batch_Status');
    my @values = ("'$status'");

    if ($comments) {
        push @fields, 'QC_Batch_Notes';
        push @values, "CONCAT(QC_Batch_Notes,\"$comments\",'; ')";
    }

    my $ok = $dbc->Table_update_array( 'QC_Batch', \@fields, \@values, "WHERE QC_Batch_ID IN ($batch_id)", -autoquote => 0, -comment => $comments );

    my $count;
    if ( $status =~ /^(Re\-Test|Pending)/ ) {
        ## if Re-Testing, quarantine members of Batch ##
        $count = $self->set_Batch_Member( -dbc => $dbc, -batch_id => $batch_id, -status => 'Quarantined' );
    }
    elsif ( $status =~ /^(Release|Pass)/i ) {
        $count = $self->set_Batch_Member( -dbc => $dbc, -batch_id => $batch_id, -status => 'Released' );
    }
    elsif ( $status =~ /^(Reject|Fail)/i ) {
        $count = $self->set_Batch_Member( -dbc => $dbc, -batch_id => $batch_id, -status => 'Rejected' );
    }
    elsif ( $status =~ /^Expired/i ) {
        ## if Expired, leave the QC_Member_Status unchanged and set each individual object QC Status to Expired ##
        $count = $self->set_Batch_Member( -dbc => $dbc, -batch_id => $batch_id, -status => 'Expired' );
    }
    else {
        $dbc->error("Unrecognized Status: $status");
        return 0;
    }

    return $count;
}

##########################
sub set_Batch_Member {
##########################
    my $self = shift;

    my %args     = filter_input( \@_, -args => 'dbc,batch_id,status', -mandatory => 'dbc,batch_id,status' );
    my $dbc      = $args{-dbc};
    my $batch_id = $args{-batch_id};
    my $status   = $args{-status};
    my $comments = $args{-comments};

    my $action = $status;
    if ( $status =~ /Expired/i ) {
        $action = 'Quarantined';
    }
    Message("$action Members of Batch $batch_id ($comments)");

    my @fields = ('QC_Member_Status');
    my @values = ($action);

    my $count = $dbc->Table_update_array( 'QC_Batch_Member', \@fields, \@values, "WHERE FK_QC_Batch__ID IN ($batch_id)", -autoquote => 1, -comment => $comments );

    my @M_fields;
    my @M_values;
    if ($comments) {
        push @M_fields, 'QC_Batch_Notes';
        push @M_values, "CONCAT(QC_Batch_Notes,\"$comments\",'; ')";
    }

    ## update object status as well
    my $new_status;
    if    ( $status =~ /Quarantined/ ) { $new_status = 'Pending' }
    elsif ( $status =~ /Released/ )    { $new_status = 'Passed' }
    elsif ( $status =~ /Fail|Reject/ ) { $new_status = 'Failed' }
    elsif ( $status =~ /Expired/i )    { $new_status = 'Expired' }
    else                               { $dbc->error("Unrecognized Batch Status: $status'"); return 0; }

    my %Objects = $dbc->Table_retrieve( 'QC_Batch_Member, Object_Class', [ 'Object_Class', 'Group_Concat(Distinct Object_ID) as IDs' ], "WHERE FK_Object_Class__ID=Object_Class_ID AND FK_QC_Batch__ID IN ($batch_id) GROUP BY Object_Class" );

    my $i = 0;
    while ( defined $Objects{IDs}[$i] ) {
        my $class = $Objects{Object_Class}[$i];
        my $ids   = $Objects{IDs}[$i];

        if ( $self->local_QC_tracking($class) ) {
            ## if this class has a QC_Status field ##
            $dbc->Table_update( $class, 'QC_Status', $new_status, "WHERE ${class}_ID IN ($ids)", -autoquote => 1 );
        }
        $i++;
    }

    if (@M_fields) { $dbc->Table_update_array( 'QC_Batch', \@M_fields, \@M_values, "WHERE QC_Batch_ID IN ($batch_id)", -autoquote => 0 ) }

    return $count;
}

# Return: 1 if this class has local QC_Tracking field
##########################
sub local_QC_tracking {
##########################
    my %args  = filter_input( \@_, -args => 'self,class', -self => 'alDente::QC_Batch' );
    my $self  = $args{-self};
    my $class = $args{-class};
    my $dbc   = $args{-dbc} || $self->{dbc};

    my ($qc_tracking) = $dbc->Table_find( 'DBField', 'count(*)', "WHERE Field_Table = '$class' AND Field_Name = 'QC_Status'" );

    return $qc_tracking;
}

#
#
#
##########################
sub check_Quarantine {
##########################
    my %args  = filter_input( \@_, -args => 'self,class', -self => 'alDente::QC_Batch' );
    my $self  = $args{-self};
    my $class = $args{-class};
    my $id    = $args{-id};
    my $dbc   = $args{-dbc} || $self->{dbc};

    my $quarantined = $dbc->Table_retrieve_display(
        'QC_Batch_Member,Object_Class,QC_Batch',
        [ 'FK_QC_Batch__ID', 'QC_Batch_Status', 'QC_Batch_Notes', "Object_ID AS $class", 'QC_Member_Status' ],
        "WHERE FK_QC_Batch__ID=QC_Batch_ID AND FK_Object_Class__ID=Object_Class_ID AND Object_Class='$class' AND Object_ID IN ($id) AND QC_Member_Status != 'Released'",
        -title       => 'QC Batch Pending Release',
        -distinct    => 1,
        -alt_message => '',
        -return_html => 1
    );

    return $quarantined;
}

#########################
# Add QC_Batch_Type record
#
# Usage:
#	my $new_id = $obj->new_QC_Batch_type( -dbc => $dbc, -name => $new_name );
#
# Return:
#	Scalar, the new QC_Batch_Type_ID
##########################
sub new_QC_Batch_type {
##########################	
    my $self = shift;
    my %args     = filter_input( \@_, -args => 'dbc,name', -mandatory => 'dbc,name' );
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $name = $args{-name};
	my $debug = $args{-debug};
	
	my ($exist ) = $dbc->Table_find( 'QC_Batch_Type', 'QC_Batch_Type_ID', "WHERE QC_Batch_Type_Name = '$name'" );
	if( $exist ) {
		$dbc->error( "Sorry, $name already exists!" );
		return;
	}	
    my $new_id = $dbc->Table_append_array( 'QC_Batch_Type', ['QC_Batch_Type_Name'], [$name], -autoquote => 1, -debug => $debug );
	return $new_id;
}

#########################
# Update QC_Batch_Type name
#
# Usage:
#	my $ok = $obj->update_QC_Batch_type( -dbc => $dbc, -old_name => $old, -new_name => $new );
#
# Return:
#	Scalar: 1 if success; 0 if fail
##########################
sub update_QC_Batch_type {
##########################	
    my $self = shift;
    my %args     = filter_input( \@_, -args => 'dbc,old_name,new_name', -mandatory => 'dbc,old_name,new_name' );
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $old_name = $args{-old_name};
    my $new_name = $args{-new_name};
	my $debug = $args{-debug};
    
	my ($exist ) = $dbc->Table_find( 'QC_Batch_Type', 'QC_Batch_Type_ID', "WHERE QC_Batch_Type_Name = '$new_name'" );
	if( $exist ) {
		$dbc->error( "Sorry, $new_name already exists! Update QC_Batch_Type failed." );
		return 0;
	}	
	
    my $ok = $dbc->Table_update_array( 'QC_Batch_Type', ['QC_Batch_Type_Name'], [$new_name], "WHERE QC_Batch_Type_Name = '$old_name'", -autoquote => 1, -debug => $debug );
	return $ok;
}
