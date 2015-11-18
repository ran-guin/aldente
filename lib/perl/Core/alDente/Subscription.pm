##################################################################################################################################
# Subscription.pm
#
# <concise_description>
#
# Event is something that happens and requires user to be notified by email when it happens.
# A Subscription records who needs to be notified (Subscribers) when an event occurs.  It also contains different categories fields which allows filtering specific notifications.  (i.e.  Expiring Reagents/Solutions/Boxes in all Groups VS Expiring Reagents/Solutions/Boxes in the Sequencing Lab)
#
# This module handles subscription related operations.  Namely, Adding/Removing Subscribers to an # existing event,  find all the subscribers subscribed to an event, find all the events a particular subscriber has subscribed to.
#
###################################################################################################################################
package alDente::Subscription;

##############################
# perldoc_header             #
##############################

=head1 SYNOPSIS <UPLINK>
 Usage: 
 
 Send out a Notification for the Submission Event (for the Sequencing Base Group only)
 
 send_notification(-name=>"Submission",-from=>'aldente@bcgsc.bc.ca',-subject=>'Put the Subject of the email here',-body=>"Body of the email goes here",-content_type=>'html',-group=>2);

Note:  First 

 Find all the people whom needed to be notified for a Subscription Event with the Name "Stock Supply Low".  The result will be an array of all the email addresses.
   @subscribers_list = get_Subscriber("Stock Supply Low");

 Usage: 
 Find all the people whom needed to be notified for a Subscription Event with the Name "Stock Supply Low" for the Sequencing Group.  The result will be an array of all the email addresses.
   @subscribers_list = get_Subscriber("Stock Supply Low",-group=>'Sequencing');

 Usage: 
 Find All the subscriptions of John Smith. The second parameter specifies the SubscriberType which can be 'User', 'Grp', 'Contact', or 'ExternalEmail'.  The result will be an array of Events in string format.
   @subscription_event_list = find_Subscription(-user=>'John Smith');

 Usage: 
 Find All the Subscription with the event name "Stock Supply Low"

   @subscription_list = find_Subscription(-event=>'Stock Supply Low');

 Usage: 
 Find All the Subscription with the event name "Stock Supply Low" under the Sequencing group

   $new_subscriber_id = find_Subscription(-event=>'Stock Supply Low',-group=>'Sequencing');


=head1 NAME <UPLINK>
Subscription.pm -  A Subscription records who needs to be notified (Subscribers) when an event occurs. Event is something that happens and requires user to be notified by email when it happens.
This module handles subscription related operations.  
Adding/Removing Subscribers to an  existing event,  find all the subscribers subscribed to an event, find all the events a particular subscriber has subscribed to.

=head1 DESCRIPTION <UPLINK>

Event is something that happens and requires user to be notified by email when it happens.



This module handles subscription related operations.  Namely, Adding/Removing Subscribers to an existing event,  find all the subscribers subscribed to an event, find all the events a particular subscriber has subscribed to.

Database Tables involved: 

1) SubscriptionEvent: It stores the events available for monitoring.  Each event has a EventType(e.g. Error, Warning, Submission, Approval).  EventDetails provides additional information about the event we are monitoring (e.g. Stock Low).  

2) Subscription:
- A Subscription records who needs to be notified (Subscribers) when an event occurs.   It has differet categories fields: Project, Equipment, Library, Group.  This allows filtering specific notifications.  (i.e.  Expiring Reagents/Solutions/Boxes in all Groups VS Expiring Reagents/Solutions/Boxes in the Sequencing Lab).  Each Subscription has a Moderator (employee) who can make changes to the subscription
No duplicated Subscription entries permitted.  All fields values combinations must be unique.
Name of the Subscription is determined with the SubscriptionEventName (from the SubscriptionEvent_ID) combined with the other fields (e.g. Low Volume for the Sequencing Group)

3) Subscriber:
- A person/group who is under a Subscription.  The SubscriberType field is a enum field which can be an employee (emp), a group (grp), a contact (contact) or an external email (email).

 Table Relationships:
  A SubscriptionEvent has 0 or more Subscription.  1 Subscription has 0 or more Subscribers.  A Subscription must be associated with 1 and only 1 SubscriptionEvent.  Each Subscriber is associated with 1 and only 1 Subscription. 

E.g John Smith (as an employee) subscribes to the "Supply Level Low" Event for the Sequencing Lab Group
The following database records are created:

------------------
|Subscription_Event|
-------------------
Subscription_Event_ID: 1
EventName: Supply Level Low
Event Type: Warning
Event Details: (0 < 2 for Sequencing Base)


--------------
|Subscription|
--------------
Subscription_ID: 1
Subscription_Event_ID: 1
Group: Sequencing Lab
Equipment:
Project:
Library:

------------
|Subscriber|
------------
Subscriber_ID: 1
Subscription_ID: 1
SubscriberType: User
FK_User__ID: 1
FK_Grp__ID: 
FK_Contact__ID: 1
ExternalEmail:

 GUI Interface
    Navigation: Bread crumbs links to reach the following pages
      Add/Update/Delete Subscribers.  

     - DBForms module  will be used to generate the form.

      Display Subscription information on the screen.  It will list 
      Search for Subscription Event and Subcribers.  

 Scenario:
 1) Find all the subscribers for a subscription event.  
     In the look up page, User selects the subscription event which they would like to find the subscribers and press a button.  The results will be listed on the screen in a tabular format.  If the user is the administrator, s/he is given a link to add a new subscriber to the event or remove a particular by clicking on the link on the row in the table that contains the name of the person s/he would like to remove

 2) Find all the subscription events a user or group subscribes to.  
     In the look up page, User enters the information of the subscriber which they would like to find all the subscription event the subscriber subscribes to and press a button.  The results will be listed on the screen in a tabular format.  If the user is the administrator, s/he is given a link to add a new subscriber to the event or remove a particular by clicking on the link on the row in the table that contains the name of the person s/he would like to remove

    Add/Update/Delete Subscription Event will be performed by SQL scripts since we do not need to make changes to the Subscription Event often.  It will be maintained by LIMS administrators

=cut

######################
#standard_modules_ref#
######################
use strict;
use Data::Dumper;
use SDB::HTML;
use RGTools::RGIO;
use RGTools::Conversion;
use SDB::DB_Object;
use SDB::DBIO;

#use SDB::CustomSettings qw($Connection);
use SDB::CustomSettings;
use alDente::Grp;
use alDente::Notification;
use Time::localtime;
use alDente::SDB_Defaults;

use vars qw(%Configs);

my $debug_flag = 0;
my $show_log   = 0;

################################################################
sub new {
################################################################
    my $this = shift;
    my $class = ref($this) || $this;

    my %args = &filter_input( \@_ );
    if ( $args{ERRORS} ) { Message("Input error: $args{ERRORS}"); return; }

    my $dbc = $args{-dbc};
    unless ($dbc) {
        my $host  = $Defaults{mySQL_HOST};
        my $dbase = $Defaults{DATABASE};
        my $user  = "viewer";

        my $password = "viewer";
        $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $user, -password => $password, -connect => 1 );

    }
    my $self = {};

    bless $self, $class;

    $self->{dbc} = $dbc;    # DB Handle
    $self->{LOG};
    return $self;

}

#############
sub home_page {
#############
    my $self = shift;

    my %args        = filter_input( \@_, -args => '', -mandatory => '' );
    my $employee_id = $args{-employee_id};
    my $grp_id      = $args{-grp_id};
    my $event       = $args{-event};

    my $dbc = $self->{dbc};

#    my @fields = ('FK_Subscription_Event__ID','Subscription_ID','Subscription.FK_Grp__ID as Grp','Subscription.FK_Equipment__ID as Equip','Subscription.FK_Project__ID as project','Subscription.FK_Library__Name as lib','Subscriber_ID','Subscriber_Type','Subscriber.FK_Employee__ID as Subscriber','Subscriber.FK_Grp__ID as Subscriber_Grp_ID','FK_Contact__ID','External_Email');
    my @fields = (
        'FK_Subscription_Event__ID',
        'Subscription_Name as Subscription',
        'Subscription.FK_Grp__ID as Grp',
        'Subscription.FK_Equipment__ID as Equip',
        'Subscription.FK_Project__ID as project',
        'Subscription.FK_Library__Name as lib',
        'Subscriber_Type',
        'Subscriber.FK_Employee__ID as Subscriber',
        'Subscriber.FK_Grp__ID as Subscriber_Grp_ID',
        'FK_Contact__ID',
        'External_Email'
    );

    # only show the subscriptions/subscriber for the group which the user belongs to
    my $grps            = $dbc->get_local('group_list');
    my $extra_condition = " AND Subscriber.FK_Grp__ID IN ($grps)";

    my $subscriptions = $dbc->Table_retrieve_display(
        'Subscription,Subscriber,Subscription_Event', \@fields,
        -return_html      => 1,
        -title            => "Subscriptions",
        -condition        => "WHERE FK_Subscription_Event__ID=Subscription_Event_ID AND FK_Subscription__ID=Subscription_ID $extra_condition GROUP BY Subscription_ID",
        -distinct         => 1,
        -toggle_on_column => 1
    );

    # create a text link above the table for adding new Subscription

    print Link_To( $dbc->config('homelink'), 'Add Subscription', "&New+Entry=New+Subscription" );

    print "\t\t" . Link_To( $dbc->config('homelink'), 'Add Subscriber', "&New+Entry=New+Subscriber" );

    # delete Subscriber (admin only
    print "\t\t" . Link_To( $dbc->config('homelink'), 'Delete Subscriber', "&Delete+Entry=Subscriber" );

    print $subscriptions;
    Message("HELLO");
    return 1;
}

################
sub set_debug_flag {
################
    my $self = shift;

    my %args = filter_input( \@_, -args => 'value', -mandatory => 'value' );

    $debug_flag = $args{-value};
}

################
sub set_show_log_flag {
################
    my $self = shift;

    my %args = filter_input( \@_, -args => 'value', -mandatory => 'value' );

    $show_log = $args{-value};
}

########################
sub DESTROY {
########################
    my $self = shift;
    $self->SUPER::DESTROY;
    my $dbc = $self->dbc();
    $dbc->disconnect();

    # close log file
    if ( $self->{log} ) { close $self->{log} }

}

## Subscription Event#################################################
################################################################

###############################################################
# Get SubscriptionID from the Event Name with
#
# Usage:
#   $Subscription_ID = get_SubscriptionID("Stock Supply Low");
#   add_Subscriber($Subscription_ID,"Employee",5);
# Return:  ID of subscription
###############################################################
sub get_subscription_id {
################################################################
    my $self = shift;

    my %args = filter_input( \@_, -args => 'name,library,group,equipment,project', -mandatory => 'name' );

    my $name        = $args{-name};         # name of event (eg. Stock Supply Low)
    my $library     = $args{-library};      # Library which the supscription belongs to (optional)
    my $group_array = $args{-group};        # Group which the supscription belongs to (optional)
    my $equipment   = $args{-equipment};    # Equipment which the supscription belongs to (optional)

    my $project = $args{-project};          # Project which the supscription belongs to (optional)

    my $dbc = $self->{dbc};                 # || SDB::Errors::log_deprecated_usage("Connection", $Connection);
    my $inclusive = $args{-inclusive} || 1; #if set to 0, only return subscriptions of the event with the filter flag set

    my $condition = "Subscription_Event_Name = '$name'";

    my @condition;
    if ( $args{ERRORS} ) { Message("Input error: $args{ERRORS}"); return; }

    $equipment = Cast_List( -list => $equipment, -to => 'string', -delimiter => ',' );

    #my $group          = Cast_List(-list=>$group_array,-to=>'string',-delimiter=>',');
    my @group = Cast_List( -list => $group_array, -to => 'array', -delimiter => ',' );

    $library = Cast_List( -list => $library, -to => 'string', -delimiter => ',', -autoquote => 1 );
    $project = Cast_List( -list => $project, -to => 'string', -delimiter => ',' );

    if ($name) {
        push @condition, "Subscription_Event_Name = '$name'";
    }

    if ($library) {
        push( @condition, "CASE WHEN FK_Library__Name IS NOT NULL THEN FK_Library__Name in ($library) ELSE $inclusive END" );

    }

    #    if ($group) {
    if (@group) {
        my $grp_list = '';

        #        for my $grp ( @{$group_array} ) {
        for my $grp (@group) {
            my $child_grp_list = alDente::Grp->get_child_groups( -group_id => $grp, -dbc => $dbc );
            if   ( $grp_list eq '' ) { $grp_list = $child_grp_list; }
            else                     { $grp_list = $grp_list . "," . $child_grp_list; }
        }
        if ( !$grp_list ) {
            print "********\nError: Invalid group list\nPrinting dump of the given group argument:\n";
            print Dumper @group;
            print "********\n";
        }
        push( @condition, "CASE WHEN FK_Grp__ID IS NOT NULL THEN FK_Grp__ID in ($grp_list) ELSE $inclusive  END" );

    }

    if ($equipment) {
        push( @condition, "CASE WHEN FK_Equipment__ID IS NOT NULL THEN FK_Equipment__ID in ($equipment) ELSE $inclusive  END" );

    }

    if ($project) {

        # library is subset of project
        push( @condition, "CASE WHEN FK_Project__ID IS NOT NULL THEN FK_Project__ID in ($project) ELSE $inclusive END" );

    }

    if (@condition) {
        if ($condition) {
            $condition .= ' AND ' . join( ' AND ', @condition );
        }
        else {
            $condition = join( ' AND ', @condition );
        }
    }

    my @subscription_ids = $dbc->Table_find( "Subscription_Event,Subscription", "Subscription_ID", "WHERE FK_Subscription_Event__ID =Subscription_Event_ID AND $condition", -debug => $debug_flag );
    return \@subscription_ids;

}

## Subscription#################################################

###############################################################
# Create a new Subscription
# Add a new record to the Subscription table and return the SubscriptionID of the new reocrd.
# <snip>
# Usage:
#   $Subscription_Event_ID = add_Subscription_event("Stock Supply Low");
#   add_Subscription($Subscription_Event_ID,"Sequcing");
# </snip>
# Return:  ID of new subscription event
###############################################################
sub add_Subscription {
################################################################
    my %args = &filter_input( \@_, -args => 'subscription_event_id,employee_id,equipment,project,library,group', -mandatory => 'subscription_event_id,employee_id' );
    if ( $args{ERRORS} ) { Message("Input error: $args{ERRORS}"); return; }

    my $subscription_event_id = $args{-subscription_event_id};    # SubscriptionEventID of the event which we would like to add a subscription for
    my $emp_id                = $args{-employee_id};              # employeeid of the moderator
    my $equipment             = $args{-equipment};                # filter by Equipment
    my $project               = $args{-project};                  # filter by Project
    my $library               = $args{-library};                  # filter by Library
    my $group                 = $args{-group};                    # filter by Group
    my $subscription_id       = 0;
    return $subscription_id;
}

###############################################################################
# Return the information of all the Subscriptions for the chosen subscription event
# return all the subscription field values as a HTML table
###############################################################################
sub get_Subscription {
################################################################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'subscription_event_id', -mandatory => 'subscription_event_id' );
    if ( $args{ERRORS} ) { Message("Input error: $args{ERRORS}"); return; }
    my $dbc                   = $self->{dbc};
    my $subscription_event_id = $args{-subscription_event_id};
    my $table_name            = 'Subscription';                  #,Grp,Equipment,Project';

    #    my @fields = ('Subscription_Name','Grp_Name','Equipment_Name','Project_Name','fk_Library__Name');
    my @fields = ( 'Subscription_Name', 'fk_grp__id', 'fk_equipment__id', 'fk_project__id', 'fk_library__name' );

    #    my $condition = "where fk_subscription_event__id = $subscription_id and Grp_ID = fk_grp__id and equipment_id = fk_equipment__id and ";
    my $condition = "where fk_subscription_event__id = $subscription_event_id ";

    my $html_table = $dbc->Table_retrieve_display( $table_name, \@fields, $condition );

    return $html_table;
}

## Subscriber#################################################
# Who is subscribed to which list? (Subscribers)
# Different types of people can be subscribers (User, Group, Contact, or External Email)
# Having Group level subscriber allows us to keep the Subscriber unchanged when members of the
# group changes
##############################################################

###############################################################
# Add a subscriber to an existing Subscription Only the Moderator who owned the subscription can do this
# Add a new record to the Subscriber table and return the SubscriberID of the new reocrd.
###############################################################
sub add_Subscriber {
################################################################
    my %args = &filter_input( \@_, -args => 'subscriber_ID,type,employee_id,group_id,contactid,external_email', -mandatory => 'subscriber_ID,name,type' );
    if ( $args{ERRORS} ) { Message("Input error: $args{ERRORS}"); return; }

    my $subscription_id = $args{-subscription_ID};
    my $type            = $args{-type};                # enum value contact, employee, group, or external_email
    my $contact_id      = $args{-contact_id};          # contact_id has a value if type is set to contact
    my $emp_id          = $args{-employee_id};         # employee_id has a value if type is set to employee
    my $grp_id          = $args{-moderator_grp_id};    # moderator_grp_id has a value if type is set to group
    my $external_email  = $args{-external_email};      # external_email has a value if type is set to externa_lemail
    my $subscriber_id   = 0;

    return $subscriber_id;
}

###############################################################
# Update an existing Subscriber.  Only the Moderator who owned the subscription can update a subscriber from an existing Subscription
# Return 0 if the update is successful.  1 if unsuccessful
###############################################################
sub update_Subscriber {
################################################################
    my %args = &filter_input( \@_, -args => 'subscriber_id,type,employee_id,group_id,contact_id,external_email', -mandatory => 'subscriber_ID,type' );
    if ( $args{ERRORS} ) { Message("Input error: $args{ERRORS}"); return; }

    my $subscriber_id = $args{-subscriber_id};    # subscriber_id is set to the subscriber_id of the subscriber record we want to update
    my $type          = $args{-type};             # enum('contact', 'emp','grp','email')
    my $contact_id    = $args{-contact_id};       # contact_id has a value if type is set to contact

    my $emp_id         = $args{-employee_id};         # employee_id has a value if type is set to employee
    my $grp_id         = $args{-moderator_grp_id};    # moderator_grp_id has a value if type is set to group
    my $external_email = $args{-external_email};      # external_email has a value if type is set to external_email
    return 0;
}

###############################################################################
# Delete an existing Subscriber.  Only the Moderator who owned the subscription can remove a subscriber from an existing Subscription
# Return 0 if the delete is successful.  1 if unsuccessful
###############################################################################
sub delete_Subscriber {

    my %args = &filter_input( \@_, -args => 'subscriber_id', -mandatory => 'subscriber_id' );
    if ( $args{ERRORS} ) { Message("Input error: $args{ERRORS}"); return; }

    my $subscriber_id = $args{-subscriber_id};    # subscriberid is set to the subscriberid of the subscriber record we want to delete
    return 0;
}
###############################################################################
# return all the people who needs to be notified for a Subscription Event with ID specified in subscription_id.  The result will be an array of email addresses
#
###############################################################################
sub get_Subscriber {
################################################################

    my $self = shift;
    my %args = &filter_input( \@_, -args => 'subscription_id,relevant_grp_id_list,relevant_library_id_list,log', -mandatory => 'subscription_id' );
    if ( $args{ERRORS} ) { Message("Input error: $args{ERRORS}"); return; }

    #    my @subscription_id = $args{-subscription_id}; # subscriber_id is set to the subscriber_id of the subscriber record we want to get information from
    my $subscription_id_list = Cast_List( -list => $args{-subscription_id}, -to => 'string' );    # subscriber_id is set to the subscriber_id of the subscriber record we want to get information from

    #   my @relevant_grp_id_list = $args{-relevant_grp_id_list};
    my $relevant_grp_ids = Cast_List( -list => $args{-relevant_grp_id_list}, -to => 'string' );

    my @relevant_library_id_list = $args{-relevant_library_id_list};
    my $relevant_library_ids = Cast_List( -list => \@relevant_library_id_list, -to => 'string' );

    my $event_name = $args{-event_name};
    my $dbc        = $self->{dbc};                                                                #hash ref is self

    if ( $args{ERRORS} ) { Message("Input error: $args{ERRORS}"); return; }

    my $log = $args{ -log } || 0;    #If the debug flag is set to 1, a log file containing information on the subscription and subscribers to the subscription will be created in /home/aldente/private/logs/subscription

    my %subscriber_list = &Table_retrieve( $dbc, 'Subscriber', [ 'Subscriber_ID', 'Subscriber_Type', 'FK_Employee__ID', 'FK_Grp__ID', 'FK_Contact__ID', 'External_Email' ], "WHERE FK_Subscription__ID in ($subscription_id_list)", -debug => $debug_flag );
    my $index           = 0;
    my @email_addr_list = ();
    my $count           = 0;
    my @email_address;
    my $tm = &date_time();           #localtime;
    if ( $log == 1 ) {

        $self->subscription_log("\n\nSubscription $subscription_id_list \n");
        $self->subscription_log("-----------------------------------------\n");
    }

    if ( $show_log == 1 ) {

        print "\n\nSubscription $subscription_id_list \n";    #   $tm for event $event_name\n";
        print "-----------------------------------------\n";
    }

    while ( defined $subscriber_list{Subscriber_ID}->[$index] ) {
        @email_address = ();
        my $subscriber_type = $subscriber_list{Subscriber_Type}->[$index];
        if ( $log == 1 ) {
            $self->subscription_log("Subscriber $subscriber_list{Subscriber_ID}->[$index]\n");
        }
        if ( $show_log == 1 ) {
            print "Subscriber $subscriber_list{Subscriber_ID}->[$index]\n";
        }
        if ( $subscriber_type eq 'Grp' ) {

            #retrieve all the Employees which has the same group and parent groups
            my $grp_list = alDente::Grp->get_parent_groups( -group_id => $subscriber_list{FK_Grp__ID}->[$index], -dbc => $dbc );

            #        if ($relevant_grp_ids)  {   $grp_list = $grp_list . "," . $relevant_grp_ids ;    }
            my $condition = "WHERE FK_Grp__ID in ($grp_list) and Employee_ID = FK_Employee__ID and Employee_Status = 'Active'";

            #        $condition = $condition." and FK_Grp__ID in ($relevant_grp_ids)"if ($relevant_grp_ids);
            #        my $condition = "WHERE FK_Grp__ID in ($relevant_grp_ids) and Employee_ID = FK_Employee__ID and Employee_Status = 'Active'";

            @email_address = $dbc->Table_find( "GrpEmployee,Employee", "Email_Address", $condition, -debug => $debug_flag, -distinct => 1 );
            push( @email_addr_list, @email_address ) if (@email_address);
            if ( $log == 1 ) {
                my @result = $dbc->Table_find( "Grp", "Grp_Name", "where Grp_ID = $subscriber_list{FK_Grp__ID}->[$index]", -debug => $debug_flag );

                $self->subscription_log("    Grp: @result \n");
                if ( $show_log == 1 ) {
                    print "    Grp: @result \n";

                }
            }
        }

        elsif ( $subscriber_type eq 'Employee' ) {

            #retrieve email address of the Employee record  with Employee__ID = FK_Employee__ID
            my $cond;
            if ($relevant_grp_ids) {
                $cond = " and FK_Grp__ID in ($relevant_grp_ids)";
            }

            @email_address = $dbc->Table_find( "GrpEmployee,Employee", "Email_Address", "WHERE Employee_ID =$subscriber_list{FK_Employee__ID}->[$index] and Employee_Status = 'Active' $cond", -debug => $debug_flag, -distinct => 1 );

            #print "\nContent of employee w/ id = $subscriber_list{FK_Employee__ID}->[$index]: ".Dumper(@email_address)."\n";

            push( @email_addr_list, @email_address ) if (@email_address);
            if ( $log == 1 ) {
                $self->subscription_log("    Employee $subscriber_list{FK_Employee__ID}->[$index]\n");
                $self->subscription_log( "    Email Target = " . Dumper(@email_addr_list) . "\n" );
            }
            if ( $show_log == 1 ) {
                print "    Employee $subscriber_list{FK_Employee__ID}->[$index]\n";
                print "    Email Target = " . Dumper(@email_addr_list) . "\n";
            }

        }

        elsif ( $subscriber_type eq 'ExternalEmail' ) {

            #use the email address specified in ExternalEmail field
            push( @email_addr_list, $subscriber_list{External_Email}->[$index] ) if ( $subscriber_list{External_Email}->[$index] ne '' );
            if ( $log == 1 ) {
                $self->subscription_log("    External Email = $subscriber_list{External_Email}->[$index]\n");
                $self->subscription_log( "    Email Target = " . Dumper(@email_addr_list) . "\n" );
            }
            if ( $show_log == 1 ) {
                print "    External Email = $subscriber_list{External_Email}->[$index]\n";
                print "    Email Target = " . Dumper(@email_addr_list) . "\n";
            }

        }

        elsif ( $subscriber_type eq 'Contact' ) {

            #retrieve email address of the contact record  with Contact__ID = FK_Contact__ID

            @email_address = $dbc->Table_find( "Contact", "Contact_Email", "WHERE Contact_ID =$subscriber_list{FK_Contact__ID}->[$index] and Contact_Status = 'Active'", -debug => $debug_flag );

            push( @email_addr_list, @email_address ) if (@email_address);

            if ( $log == 1 ) {

                $self->subscription_log("    Contact ID = $subscriber_list{FK_Contact__ID}->[$index]\n");
                $self->subscription_log( "    Email Target = " . Dumper(@email_addr_list) . "\n" );
            }
            if ( $show_log == 1 ) {

                print "    Contact ID = $subscriber_list{FK_Contact__ID}->[$index]\n";
                print "    Email Target = " . Dumper(@email_addr_list) . "\n";
            }

        }
        $index++;
    }

    # Remove any duplicate email addresses in the list, unique_items return an array of 1 element w/ the results separated by commas

    return RGTools::RGIO::unique_items( \@email_addr_list );
}

###############################################################################
# return all subscriptions for the Subscription Event with the name $name.  The result will be an array of subscription_id
#
###############################################################################
sub find_Subscription {
################################################################
    my $self = shift;

    my %args = &filter_input( \@_, -args => 'name,group,equipment,project,library,user,external_email,contact,subscriber_group' );
    if ( $args{ERRORS} ) { Message("Input error: $args{ERRORS}"); return; }

    my $name      = $args{-name};         # filter search for a specific Subscription Event Name (Optional)
    my $equipment = $args{-equipment};    # filter search for a specific equipment (Optional)
    my $project   = $args{-project};      # filter search for a specific project (Optional)
    my $library   = $args{-library};      # filter search for a specific library (Optional)
    my $group     = $args{-group};        # filter search for a specific group (Optional)

    my $username         = $args{-username};            # filter search by the Name of the Subscriber(Optional)
    my $email            = $args{-email};               # filter search by the external_email of the Subscriber(Optional)
    my $contact          = $args{-contact};             # filter search by the contact of the Subscriber (Optional)
    my $subscriber_group = $args{-subscriber_group};    # filter search by the group of the Subscriber (Optional)

    my $dbc = $self->{dbc};                             #hash ref is self

    my @subscription_id_list;
    my $arg_list;

    my @arg_list;
    if ($name) {

        @arg_list = ("-name $name");
    }

    push( @arg_list, "-project $project" ) if ($project);

    push( @arg_list, "-library $library" ) if ($library);

    push( @arg_list, "-group $group" ) if ($group);

    @subscription_id_list = get_subscription_id(@arg_list) if (@arg_list);

    $arg_list = "";
    if ($username) {
        my $emp_id = $dbc->Table_find( "Employee", "Employee_ID", "WHERE Employee_Name = '$username'", -debug => $debug_flag );

        $arg_list = "(Subscriber_Type = 'Employee' and FK_Employee__ID = $emp_id)" if ($emp_id);

    }

    if ($contact) {
        $arg_list = $arg_list . " or " if ( $arg_list ne '' );

        my $emp_id = $dbc->Table_find( "Contact", "Contact_ID", "WHERE Contact_Name = '$contact'", -debug => $debug_flag );

        $arg_list = "(Subscriber_Type = 'Contact' and FK_Contact__ID = $emp_id)" if ($emp_id);

    }

    if ($subscriber_group) {
        $arg_list = "(Subscriber_Type = 'Grp' and FK_Grp__ID = $subscriber_group)" if ($subscriber_group);

    }

    if ( $arg_list ne '' ) {
        my @result = $dbc->Table_find( "Subscriber", "FK_Subscription__ID", $arg_list, -debug => $debug_flag );
        push( @result, @subscription_id_list ) if (@result);

    }
    return RGTools::RGIO::unique_items( \@subscription_id_list );
}
############################################################
# Wrapper function for sending Notification
############################################################
#
# <snip>
# Example: We want to send the notifications for Submission Event for the Sequencing Base
#  send_notification(-dbc=>$dbc,-name=>'Submission',-from=>'aldente@bcgsc.bc.ca',-group=>2,-subject=>'Enter the subject of the email here',-body=>'Enter the body of the email here');
#
# </snip>
########################
sub send_notification {
########################
    my %args = &filter_input( \@_, -args => 'name', -mandatory => 'dbc|self|connect', -self => 'alDente::Subscription' );

    if ( $args{ERRORS} ) { Message("Input error: $args{ERRORS}"); return; }
    my $self = $args{-self};
    my $name      = $args{-name};         # filter search on Subscription for a specific Subscription Event Name (Optional)
    my $equipment = $args{-equipment};    # filter search on Subscription for a specific equipment.  Supply a string of Equipment_ID separated by commas (Optional)
    my $project   = $args{-project};      # filter search on Subscription for a specific project.  Supply a string of Project_ID separated by commas (Optional)
    my $library   = $args{-library};      # filter search on Subscription for a specific library.  Supply a string of Library_ID separated by commas (Optional)

    my $group           = $args{-group};              # filter search on Subscription for a specific group.  Supply a string of Grp_ID separated by commas (Optional)
    my $body            = $args{-body};               # body of the email
    my $to              = $args{-to};                 # additional recipients of the email besides the subscribers
    my $bypass          = $args{-bypass};             # flag to bypass Subscription and just sent the email to the addresses specified in the to parameter
    my $attachment_type = $args{-attachment_type};    # Set this arugment if there is an attachment to the email.  Valid values are text, excel
    my $verbose         = $args{-verbose};            # An argument which gets passed into the Notification module (Optional)
    my $testing         = $args{-testing};            #testing flag.  If set to 1, the email will NOT be sent to the recipients and send to aldente instead
    my $cc              = $args{-cc_address};

    $show_log = $args{-show_log} || 0;                # Display the content of the log for this execution (for debugging)
    $debug_flag = $args{-debug};                      # Display all the SQL statements used by the function (for debugging)

    my $connect = $args{ -connect };                  # If set to 1, the caller doesn't have to provide a $dbc connection object
    my $dbc     = $args{-dbc};

    unless ($dbc) {
        my $host  = $Defaults{mySQL_HOST};
        my $dbase = $Defaults{DATABASE};
        my $user  = "viewer";

        my $password = "viewer";
        $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $user, -password => $password, -connect => 1 );

    }

    my $self = $args{-self};

    $self ||= new alDente::Subscription( -dbc => $dbc );

    my $tm = &date_time();
    my $ok = 0;

    # CC to aldente only if it's not in to, cc and bcc.  otherwise we get duplicates
    my $admin_email = $dbc->config('admin_email');
    my @cc = Cast_List(-list=>$cc, -to=>'array');
    if ( ! grep /$admin_email/, @cc) { push @cc, $admin_email }
    $args{-cc_address} = join ',', @cc;
    
    my %args_msgs = %args;
    delete $args_msgs{-dbc};
    $self->subscription_log( "send_notification called on $tm with the following input:\n\n" . Dumper( \%args_msgs ) , -dbc=>$dbc);

    if ( $show_log == 1 ) {
        print "send_notification called on $tm with the following input:\n\n" . Dumper( \%args_msgs );
    }

    # We would like to have all the notification emails sent through this function including those which is sent to aldente only.  For those ones, we can just send them out w/o having to go through all the subscription records thus improving effiency

    if ( $bypass == 1 ) {
        undef $args{-name};         ## not applicable
        undef $args{-equipment};    ## not applicable
        undef $args{-project};      ## not applicable
        undef $args{-library};      ## not applicable
        undef $args{-group};        ## not applicable
        undef $args{-bypass};       ## not applicable
        $ok = &alDente::Notification::Email_Notification(%args);
        return $ok;
    }

    my @subscription_ID = @{ $self->get_subscription_id( $name, $library, $group, $equipment, $project ) };
    $self->subscription_log("List of Subscriptions for $name:\n");
    if ( $show_log == 1 ) {
        print "List of Subscriptions for $name:\n";

    }
    my ($group_name);
    my ($equipment_name);
    my ($project_name);

    foreach my $sid (@subscription_ID) {
        my %subscription_filters = $dbc->Table_retrieve( 'Subscription', [ 'FK_Library__Name', 'FK_Grp__ID', 'FK_Equipment__ID', 'FK_Project__ID' ], "WHERE Subscription_ID = $sid", -debug => $debug_flag );
        if ( defined( $subscription_filters{'FK_Grp__ID'}[0] ) ) {
            ($group_name) = &Table_find( $dbc, 'Grp', 'Grp_Name', " where Grp_ID = $subscription_filters{'FK_Grp__ID'}[0]" );
        }

        if ( defined( $subscription_filters{'FK_Equipment__ID'}[0] ) ) {

            ($equipment_name) = &Table_find( $dbc, 'Equipment', 'Equipment_Name', " where Equipment_ID = $subscription_filters{'FK_Equipment__ID'}[0]" );
        }

        if ( defined( $subscription_filters{'FK_Project__ID'}[0] ) ) {

            ($project_name) = &Table_find( $dbc, 'Project', 'Project_Name', " where Project_ID = $subscription_filters{'FK_Project__ID'}[0]" );
        }

        $self->subscription_log("    Subscription $sid - Library: $subscription_filters{'Library'}, Group: $group_name, Equipment: $equipment_name, Project: $project_name");

        if ( $show_log == 1 ) {
            print "    Subscription $sid - Library: $subscription_filters{'Library'}, Group: $group_name, Equipment: $equipment_name, Project: $project_name";

        }

    }

    my $relevant_grp_ids_list = alDente::Grp->relevant_grp( -dbc => $dbc, -equipment_ids => $equipment, -project_ids => $project, -group_ids => $group, -library => $library, -include_parent => 1 );

    $self->subscription_log("\n\nList of relevant groups for equipment $equipment, project $project, group $group, Library: $library (include parent = 1): ");
    if ( $show_log == 1 ) {
        print "\n\nList of relevant groups for equipment $equipment, project $project, group $group, Library: $library (include parent = 1): ";

    }

    #    my @relevant_grp_ids = split(/,/, $relevant_grp_ids_list);

    #    @relevant_grp_ids = @{RGTools::RGIO::unique_items(\@relevant_grp_ids)};
    my @relevant_grp_ids = @{ RGTools::RGIO::unique_items($relevant_grp_ids_list) };

    foreach my $rel_grp_id (@relevant_grp_ids) {
        my ($my_grp) = $dbc->Table_find( "Grp", "Grp_Name", "WHERE Grp_ID = $rel_grp_id", -debug => $debug_flag );
        $self->subscription_log("$my_grp ($rel_grp_id), ");
        if ( $show_log == 1 ) {
            print "$my_grp ($rel_grp_id), ";
        }

    }

    my $original_body = $args{-body};

    if (@subscription_ID) {
        my @email_array = @{ $self->get_Subscriber( -subscription_id => \@subscription_ID, -relevant_grp_id_list => \@relevant_grp_ids, -log => 1, -event_name => $name ) };

        if ( length($to) > 0 ) {
            push @email_array, $to;
        }

        $self->subscription_log("\n\nlist of address the notification will be sent to b4 filtering:\n@email_array\n\n");
        if ( $show_log == 1 ) {
            print "\n\nlist of address the notification will be sent to b4 filtering:\n@email_array\n\n";

        }
        @email_array = @{ RGTools::RGIO::unique_items( \@email_array ) };

        my $final_email_list = Cast_List( -list => \@email_array, -to => 'string', -delimiter => ', ' );

        $self->subscription_log("\n\nFinal list of address the notification will be sent to after filtering:\n$final_email_list\n\n");
        if ( $show_log == 1 ) {
            print "\n\nFinal list of address the notification will be sent to after filtering:\n$final_email_list\n\n";
        }

        undef $args{-name};         ## not applicable
        undef $args{-equipment};    ## not applicable
        undef $args{-project};      ## not applicable
        undef $args{-library};      ## not applicable
        undef $args{-group};        ## not applicable
        undef $args{-bypass};       ## not applicable
        $args{-to} = $final_email_list;
        $ok = &alDente::Notification::Email_Notification(%args);

    }
    else {
        ## generate message for alDente indicating that this name has recognized subscription event. ##
        $args{-to} = $admin_email;
        undef $args{-cc};
        $args{-message} .= "'$name' not currently tied to Subscription event";
        $ok = &alDente::Notification::Email_Notification(%args);

    }
    return $ok;

}

############################################################
# method to create logs
#############################################################
sub subscription_log {
#############################################################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'message' );
    my $message   = $args{-message};  # message to be written to the log
    my $dbc = $args{-dbc} || $self->{dbc};                                                      
    my $file_path = $args{-file_path} || $self->_notification_log_directory(-dbc=>$dbc) . "/notification_log";    # (Optional)  The name with full path of the log file
    my $success   = 1;

    # open file if necessary
    if ( !$self->{LOG} ) {
        open my $FILE, '>>', $file_path or { $success = 0 };
        $self->{LOG} = $FILE;
    }

    # write message to log file
    if ($success) {
        my $FILE = $self->{LOG};
        print $FILE $message or { $success = 0 };
    }

    return $success;
}

##################################
sub _notification_log_directory {
##################################
    my $self = shift;
    my %args      = filter_input( \@_);
    my $dbc = $args{-dbc} || $self->{dbc};
    
    if ($self->{notification_log_directory}) { return $self->{notification_log_directory} }
    
    my $notification_log_directory = $dbc->config('data_log_dir') . '/subscriptions';
    $notification_log_directory = create_dir( $notification_log_directory, convert_date( &date_time(), 'YYYY/MM' ), '777' );
    
    $self->{notification_log_directory} = $notification_log_directory;
    return $notification_log_directory;   
}


#########################
# This function
#########################
sub get_Subscription_Event {
#########################
    my $self    = shift;
    my $dbc     = $self->{dbc};
    my %results = &Table_retrieve( $dbc, 'Subscription_Event', [ 'Subscription_Event_ID', 'Subscriber_Event_Name', 'Subscription_Event_Type', 'Subscription_Event_Details' ], -debug => $debug_flag );

    return %results;
}

#########################
# This returns a hash containing subscription entires of a subscriber given a group name or employee name
#########################
sub find_Subscription_by_subscriber {
#########################
    my $self     = shift;
    my %args     = &filter_input( \@_ );
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $group    = $args{-group};
    my $employee = $args{-employee};

    #This is a group search
    my ($group_ids) = $dbc->Table_find( 'Grp', 'Grp_ID', "WHERE Grp_Name='$group'", -debug => $debug_flag ) if $group;

    #This is an employee search, find out what group the employee belongs to and then add to group
    $group_ids = join( ",", $dbc->Table_find( 'GrpEmployee,Employee', 'FK_Grp__ID', "WHERE FK_Employee__ID = Employee_ID AND Employee_Name='$employee'", -debug => $debug_flag ) ) if $employee;

    my %results = $dbc->Table_retrieve(
        'Subscription,Subscriber',
        [ 'Subscription_ID', 'Subscription_Name', 'FK_Subscription_Event__ID', 'FK_Equipment__ID', 'FK_Library__Name', 'FK_Project__ID', 'Subscription.FK_Grp__ID' ],
        "WHERE Subscription_ID = FK_Subscription__ID AND Subscriber.FK_Grp__ID in ($group_ids)",
        -debug => $debug_flag
    );

    return %results;
}

##############################
sub new_Subscription_Event_trigger {
##############################
    my %args = @_;
    my $dbc  = $args{-dbc};
    my ($id) = $dbc->Table_find( 'Subscription_Event', 'Max(Subscription_Event_ID)' );
    my ($subscription_name) = $dbc->Table_find( 'Subscription_Event', 'Subscription_Event_Name', "WHERE Subscription_Event_ID = $id" );
    my $fields = [ 'FK_Subscription_Event__ID', 'Subscription_Name' ];
    my $values = [ "$id", "$subscription_name" ];
    my $s_id = $dbc->Table_append_array( "Subscription", $fields, $values, -autoquote => 1 );
    if ($s_id) {
        Message "Added Subscription Successfully";
        return 1;
    }
    else {
        Message "Problem with adding subscription";
        return;
    }

}

##############################
sub delete_subscriber_record {
##############################
    my $self    = shift;
    my %args    = @_;
    my $dbc     = $args{-dbc};
    my $records = $args{-records};
    my $ok      = $dbc->delete_records( -table => 'Subscriber', -field => 'Subscriber_ID', -id_list => $records );
    return;
}

##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

return 1;

