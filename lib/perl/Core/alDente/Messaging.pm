###################################################################################################################################
# Message.pm
#
# Class module that encapsulates a DB_Object for Messages
#
###################################################################################################################################
package alDente::Messaging;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Messaging.pm - Message.pm

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
Message.pm<BR>Class module that encapsulates a DB_Object for Messages<BR>

=cut

##############################
# superclasses               #
##############################

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

##############################
# custom_modules_ref         #
##############################
use SDB::DB_Object;
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use SDB::HTML;

use RGTools::RGIO;

use alDente::SDB_Defaults;

##############################
# global_vars                #
##############################
use vars qw($Connection );

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
# Constructor: Takes a database handle and a Message ID and creates a Message object
# RETURN: Reference to a Message object
############################################################
sub new {
########
    my $this       = shift;
    my %args       = @_;
    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $message_id = $args{-message_id} || $args{-id};

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => "Message" );
    my $class = ref($this) || $this;
    bless $self, $class;

    if ( $dbc && $message_id ) {
        $self->primary_value( 'Message', $message_id );
        $self->load_Object();
    }
    elsif ($dbc) {

    }
    else {
        Message("No database connection supplied");

        #	return undef;
    }
    $self->{dbc} = $dbc;

    return $self;
}

##############################
# public_methods             #
##############################

##############################
# Function: Adds a message
# Return: Message_ID if successful, 0 otherwise
##############################
sub add_message {
    my $self     = shift;
    my %args     = @_;
    my $text     = $args{-text};                  # (Scalar) the text of the message
    my $link     = $args{ -link };                # (Scalar) A useful link that will be hyperlinked by the text of the message.
    my $user     = $args{-user};                  # (Scalar) the employee id of the user addressed by the message.
    my $status   = $args{-status} || 'Active';    # (Scalar) the status of the message. One of Urgent, Active, Old.
    my $type     = $args{-type};                  # (Scalar) the type of the message. One of Public,Private, Admin, or Group.
    my $grp_name = $args{-grp_name};              # (Scalar) the group of the message
    my $dbc      = $args{-dbc} || $self->{dbc};

    my $grp_id;
    ($grp_id) = $dbc->Table_find( "Grp", "Grp_ID", "WHERE Grp_Name = '$grp_name'" ) if ($grp_name);
    my $datetime = &date_time();

    my $id = $dbc->Table_append_array( "Message", [ "Message_Text", "Message_Date", "Message_Link", "Message_Status", "Message_Type", "FK_Employee__ID", "FK_Grp__ID" ], [ $text, $datetime, $link, $status, $type, $user, $grp_id ], -autoquote => 1 );

    return $id;
}

##############################
# Function: Removes a message by setting it to 'Old'.
# Return: none
##############################
sub remove_message {
    my $self = shift;
    my %args = @_;
    my $id   = $args{-id};
    $self->primary_value( "Message", $id );
    $self->update( -fields => ["Message_Status"], -values => ["Old"] );
}

##############################
# Function: returns an arrayref of outstanding messages for that specific user (defined by the Connection object)
# Return: none
##############################
sub get_messages {
    my $self         = shift;
    my %args         = @_;
    my $allow_delete = $args{-delete_window};
    my $exclude_list = $args{-exclude};
    my $dbc          = $args{-dbc} || $self->{dbc};
    my $homelink     = $args{-homelink} || $dbc->homelink();
    my $user_id      = $dbc->get_local('user_id');

    my %messages = $dbc->Table_retrieve(
        'Employee, Message',
        [ 'Message_ID', 'Message_Text', 'Message_Link', 'Message_Status', 'Message_Date', 'Message_Type', 'FK_Employee__ID as Sender', 'Employee_Name as Sender_Name', 'FK_Grp__ID as Group_ID' ],
        "where Message.FK_Employee__ID=Employee_ID AND Message_Status in ('Active','Urgent')"
    );

    my @Messages;
    my $index = 1;

    # check to see if user is admin
    my $access = $dbc->get_local('departments');

    unless ( $messages{Message_ID} ) {
        return undef;
    }

    foreach ( 1 .. scalar( @{ $messages{Message_ID} } ) ) {
        my $id               = $messages{Message_ID}[ $index - 1 ];
        my $text             = $messages{Message_Text}[ $index - 1 ];
        my $link             = $messages{Message_Link}[ $index - 1 ];
        my $type             = $messages{Message_Type}[ $index - 1 ];
        my $sender           = $messages{Sender}[ $index - 1 ];
        my $sender_name      = $messages{Sender_Name}[ $index - 1 ];
        my $status           = $messages{Message_Status}[ $index - 1 ];
        my $M_date           = $messages{Message_Date}[ $index - 1 ];
        my $message_group_id = $messages{Group_ID}[ $index - 1 ];
        $index++;

        my $group_name = $type;

        if ( $exclude_list && ( $exclude_list =~ /\b$id\b/ ) ) {
            next;
        }

        if ( $type eq 'Admin' ) {
            unless ( grep( /Admin/, @{$access} ) ) {
                next;
            }
        }
        elsif ( $type eq 'Group' ) {
            my @group_array = split( ',', $dbc->get_local('group_list') );
            if ( ( !( $message_group_id && grep( /^$message_group_id$/, @group_array ) ) ) && ( !( grep( /LIMS Admin/, @{$access} ) ) ) ) {
                next;
            }
            my ($grp_name) = $dbc->Table_find( "Grp", "Grp_Name", "WHERE Grp_ID=$message_group_id" );
            $group_name = "$grp_name";
        }

        if ( $type eq 'Private' ) {
            unless ( $user_id eq $sender ) { next; }    ### only display message for yourself if private
            $text .= " <span class=small>(private)</small>";
        }

        if ( $link =~ /^[\?\&]/ ) { $link = $homelink . $link; }

        if ( $status =~ /urgent/i ) {
            $text = "*** <Font color=red>$text</Font> ***";
        }
        if ( !$text ) { last; }

        my $checkbox;
        if ($allow_delete) {
            $checkbox = checkbox( -name => "Message", -value => $id, -label => "", -linebreak => 0, -force => 1 );
        }

        if   ($link) { push( @Messages, "<Nobr>$checkbox<A href = '$link'><Font color=black class ='small'><B>$text </B></Font><font class='small'>($group_name)</font></Nobr></A>" ); }
        else         { push( @Messages, "<Nobr>$checkbox<Font color=black class='small'><B>$text </B></Font><font class='small'>($group_name)</font></Nobr>" ); }

    }

    return ( \@Messages );
}

##############################
# Subroutine: Generates a simple message removal page
# Return: none
##############################
sub show_removal_window {
    my $self         = shift;
    my %args         = @_;
    my $security_obj = $args{-security_object};
    my $dbc          = $args{-dbc} || $self->{dbc};

    print alDente::Form::start_alDente_form( $dbc, "Remove_Message_Form", $dbc->homelink() );
    my ($msgref) = $self->get_messages( -security_object => $security_obj, -delete_window => 1 );

    unless ($msgref) {
        Message("No Messages to display");
        return;
    }

    my @Messages = @$msgref;
    if ( scalar(@Messages) ) {
        my $onclick = qq(
            var Messages = document.getElementsByName('Message');

            for (var i=0; i<Messages.length; i++) {
                var e = Messages[i];
                if (e.type=='checkbox') {
                    e.checked = !(e.checked);
                }
            } 

            return false;
        );

        my $toggle = qq(<button class='Std' onclick="$onclick">Toggle Selection</button>);
        print $toggle;
        print "<UL><LI>" . join '<LI>', @Messages;
        print "</UL>";
    }
    print submit( -name => "Remove Message", -class => 'Std' );
    print "</form>";
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

2004-06-28

=head1 REVISION <UPLINK>

$Id: Messaging.pm,v 1.16 2004/12/02 18:55:13 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
