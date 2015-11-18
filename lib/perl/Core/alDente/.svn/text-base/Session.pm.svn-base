###################################################################################################################################
# alDente::Session.pm
#
# Model in the MVC structure
#
# Contains the business logic and data of the application
#
###################################################################################################################################
package alDente::Session;

use base SDB::Session;    ## remove this line if object is NOT a DB_Object

use strict;

## Standard modules ##
#use CGI qw(:standard);

## Local modules ##
use LampLite::Bootstrap;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules

use vars qw( %Configs );
my $BS = new Bootstrap;
#######################
# Checks the validity of the session
#
###############################
sub validate_alDente_session {
###############################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $session_name = $self->param('session_name');
    if ( $session_name =~ /(\d+:[a-zA-Z0-9:\_]+)/ ) {
        ## check to see if the session has expired - (monitor time since last access)  ##

        my $session_lifetime = 60 * 60;                                                                                           ## lifetime of session in minutes
        my $session_dir      = $self->param('paths');
        my $alive            = `find $session_dir/ -name \"$session_name.login\" -type f -maxdepth 1 -cmin -$session_lifetime`;

        if ( !$alive || ( $self->{IP_Address} ne $ENV{REMOTE_ADDR} ) ) {
            print $BS->warning("No session file found");
            return 0;
        }
    }
    else {
        print $BS->warning("No session_name defined");
        return 0;
    }

    return $self->validate_session;
}

#
# Wrapper to initiate temporary session with read only access for auto-generating reports
#
# Return: resets session parameters.
##########################
sub setup_auto_session {
##########################
    my $self  = shift;
    my %args  = filter_input( \@_, -args => 'host,dbase' );
    my $host  = $args{-host};
    my $dbase = $args{-dbase};

    my ( $guest_id, $db_user, $db_pwd ) = ( 134, 'viewer', 'viewer' );

    $self->param( 'user_id', $guest_id );
    $self->param( 'db_user', $db_user );
    $self->param( 'db_pwd',  $db_pwd );
    $self->param( 'host',    $host );
    $self->param( 'dbase',   $dbase );

    return ( $host, $dbase, $guest_id, $db_user, $db_pwd );
}

#
# Convert session to different user
# (used when retrieving individual user from group login)
#
#####################
sub reset_session_user {
#####################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $employee = $args{-employee};
    my $contact  = $args{-contact};
    my $new      = $args{-user} || $contact || $employee;
    my $dbc      = $args{-dbc};
    my $type     = $args{-type};                            ## normally track users via Employee table - except for external pages, which use contacts ##

    if    ($contact)  { $type = 'Contact' }
    elsif ($employee) { $type = 'Employee' }
    elsif ( !$type ) { $dbc->warning('Need to specify user type to reset session'); return 0 }

    my $new_id = $dbc->get_FK_ID( "FK_${type}__ID", $new );
    if ( !$new_id ) { $dbc->warning("No user found"); return 0; }

    my $old_id = $self->{user_id};
    my $dbase  = $self->{dbase};

    my $name_field = $type . '_Name';
    my $id_field   = $type . '_ID';

    if ( my $user = alDente::Session::validate_reset( $self, -user_id => $new_id, -type => $type, -dbc => $dbc ) ) {
        ## reset user ##
        $self->{user}    = $user;
        $self->{user_id} = $new_id;

        ## update local variables ##
        $dbc->{user} = $new_id;
        
        require alDente::Employee;
        my $Employee = new alDente::Employee( -dbc => $dbc, -id => $new_id );
        $Employee->define_User();

        delete $self->{session_id};

        $self->_initialize( -dbase => $dbase );
        $self->{session_reference} = $type;

        Message("Tracking separate session as $user");
        print "<P>";

        return $self;
    }
    else {
        $dbc->error("Failed to Reset User to $new_id");
        return 0;
    }
}

#
# Simple wrapper to ensure reset user request is allowed
#
#####################
sub validate_reset {
#####################
    my $self     = shift;
    my %args     = filter_input( \@_, -mandatory => 'user_id,type' );
    my $new_id   = $args{-user_id};
    my $dbc      = $args{-dbc};
    my $type     = $args{-type};                                        ## normally track users via Employee table - except for external pages, which use contacts ##
    my $password = $args{-password};

    my $old_id = $self->{user_id};
    my $dbase  = $self->{dbase};

    my $user;
    if ( $type eq 'Contact' ) {
        ## only valid for picking contact from list of group_contacts ..
#        ($user) = $dbc->Table_find_array('Contact, Group_Contact, Contact as CGroup',['Contact.Contact_Name'], "WHERE Group_Contact.FKMember_Contact__ID=Contact_ID AND Group_Contact.FKGroup_Contact__ID=CGroup.Contact_ID AND Contact.Contact_ID=$new_id AND CGroup.Contact_ID=$old_id", -debug=>1);
        ($user) = $dbc->Table_find( 'Contact', 'Contact_Name', "WHERE Contact_ID = $new_id" );    ## temporary for testing unti the groups are set up...

        if ( !$user ) { $dbc->error("Failed to change Session User - Please contact GSC LIMS for help"); return 0; }
        else          { return $user }
    }
    elsif ( $type eq 'Employee' ) {
        ## only works if user is LIMS Admin ##
        my ($found) = $dbc->Table_find( 'Employee', 'Employee_Name', "WHERE Employee_ID = $new_id" );
        if   ( $dbc->admin_access() ) { return $found }
        else                          { $dbc->warning("Only Admins can reset current user dynamically"); return 0 }
    }
    else {
        $dbc->error("Failed to specify user type (eg Employee or contact)");
        return 0;
    }
}

1;
