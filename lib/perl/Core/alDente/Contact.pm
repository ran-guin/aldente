###################################################################################################################################
# Contact.pm
#
# Class module that encapsulates a DB_Object that represents a single Contact
#
# $Id: Contact.pm,v 1.5 2004/09/08 23:31:48 rguin Exp $
###################################################################################################################################
package alDente::Contact;

use base SDB::User;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Contact.pm - Class module that encapsulates a DB_Object that represents a single Contact

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
Class module that encapsulates a DB_Object that represents a single Contact<BR>

=cut

##############################
# superclasses               #
##############################
### Inheritance

#@ISA = qw(SDB::DB_Object);
push @ISA, 'SDB::DB_Object';
##############################
# system_variables           #
##############################
require Exporter;
@EXPORT    = qw();
@EXPORT_OK = qw();

##############################
# standard_modules_ref       #
##############################

use CGI;

my $q = new CGI;
##############################
# custom_modules_ref         #
##############################

### Reference to alDente modules
use alDente::Collaboration;
use alDente::Submission;
use RGTools::RGIO;
use SDB::DB_Object;
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use alDente::Contact_Views;
use strict;

##############################
# global_vars                #
##############################
use vars qw($Connection);
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

############################################################
# Constructor: Takes a database handle and a Contact ID and constructs a contact object. Includes Organization as a foreign key table
# RETURN: Reference to a Contact object
############################################################
sub new {
###########
    my $this = shift;
    my $class = ref($this) || $this;
    
    my %args = filter_input( \@_ );

    my $dbc        = $args{-dbc}        || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle
    my $contact_id = $args{-contact_id} || $args{-id};                                                        # Contact ID
    my $initialize = $args{-initialize};
    my $frozen     = $args{-frozen}     || 0;                                                                 # flag to determine if the object was frozen
    my $encoded = $args{-encoded};                                                                            # flag to determine if the frozen object was encoded

    my $self;
    if ($frozen) {
        $self = $this->Object::new(%args);
    }
    else {
        $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => "Contact" );
        $self->add_tables( 'Organization', 'Contact.FK_Organization__ID = Organization_ID');
    }

    bless $self, $class;

    $self->{id}      = $contact_id;
    $self->{user_id} = $contact_id;
    $self->{dbc}     = $dbc;
    $self->{records} = 0;          ## number of records currently loaded

    if ($contact_id) {
        $self->primary_value( -table => [ 'Contact' ], -value => $contact_id );
        $self->SDB::DB_Object::load_Object();
        if ($initialize) { $self->define_User() }
    }

    return $self;
}

##############################
# public_methods             #
##############################

##
# Wrapper - only used when Contact user connects to database (eg via external page)
#
#
###################
sub define_User {
###################
    my $self = shift;  
    my $id   = $self->{id};
    my $dbc  = $self->{dbc};

    unless ($id) { Message("No User ID supplied"); Call_Stack(); return 0; }

    $self->primary_value( -table => 'Contact', -value => $id );
    $self->SUPER::load_Object;
    my $name = $self->get_data('Contact_Name');

    ## Establish connection attributes for user ##
    $dbc->set_local( 'user_id',       $id );
    $dbc->set_local( 'user_name',     $name);
    $dbc->set_local( 'user_email',    $self->get_data('Contact_Email') );
    $dbc->set_local( 'home_dept',     'External');

    my %access;
    $access{External} = ['Guest'];
    
    $dbc->set_local('projects', [ $dbc->Table_find('Collaboration,Project','Project_Name',"WHERE FK_Contact__ID=$id AND FK_Project__ID=Project_ID", -distinct=>1) ] );
    
    if ($dbc->table_loaded('Employee')) {
        ## determine LIMS_Admin access from Employee account with matching email address ##
        my ($admin) = $dbc->Table_find('Employee,Contact,Department','Employee_Name',"WHERE Length(Employee.Email_Address) > 2 AND Contact_Name = '$name' AND Employee.Email_Address=Contact.Contact_Email AND Employee.FK_Department__ID = Department_ID AND Department_Name = 'LIMS Admin' AND Employee_Status = 'Active'");
        if ($admin) { $access{'LIMS Admin'} = ['Admin']; }
    }
    $dbc->set_local( 'Access', \%access);
       
    ## Define Security settings ##
#    my $Security = alDente::Security->new( -dbc => $dbc, -user_id => $id );
#    $dbc->config('Security', $Security);
    
    if ( !$q->param('Session') ) {
        ## temporary - define Session as soon as User defined ##
        $dbc->session->{user_id} = $id;
        
        my ($session_id, $session_name) = $dbc->session->generate_session_id();
        $dbc->config('session_id', $session_id);
        $dbc->config('session_name', $session_name);
    }
        
    return 1;
}

############################################################
# Function: Returns contact information in a hash reference (fieldname=>info)
# RETURN: Reference to a hash containing contact information
############################################################
sub get_contact_info {
    my $self = shift;
    my %info;
    foreach my $field ( @{ $self->fields() } ) {
        $info{$field} = $self->value($field);
    }
    return \%info;
}

############################################################
# Function: Returns a reference to a Collaboration object representing all Collaborations this Contact has (for retrieving project information)
# RETURN: Collaboration object reference
############################################################
sub get_Collaboration {
    my $self = shift;
    my $dbc  = $self->{dbc};

    # grab all Collaborations in one object
    my $collaborations = Collaboration->new( -dbc => $dbc, -contact_id => $self->primary_value() );
    return $collaborations;
}

############################################################
# Function: Returns a reference to a Submissions object representing all Submissions this Contact has
# RETURN: Submission object reference
############################################################
sub get_Submission {
    my $self = shift;
    my $dbc  = $self->{dbc};

    # grab all Submissions in one object
    my $submissions = Submission->new( -dbc => $dbc, -contact_id => $self->primary_value() );
    return $submissions;
}

############################################################
sub find_LDAP_account {
############################################################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $name = $args{-name};

    return 1;
}

##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Contact.pm,v 1.5 2004/09/08 23:31:48 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
