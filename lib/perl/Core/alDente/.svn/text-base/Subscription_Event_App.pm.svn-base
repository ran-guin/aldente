##################
# Subscription_Event_App.pm #
##################
#
# This module is App moudule for the Subscription objects.
# Remember not to add use CGI qw(:standard);

package alDente::Subscription_Event_App;

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
use Data::Dumper;
use Carp;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::DBIO;
use SDB::HTML;
use RGTools::Views;
use alDente::Form;
use SDB::CustomSettings;
use RGTools::Object;
use alDente::Subscription;
use SDB::DB_Form_Viewer;
use SDB::DB_Form;
##############################
# global_vars                #
##############################
use vars qw(%Configs);
use vars qw($Connection);    # new do we need this

############
sub setup {
############
    my $self = shift;
    $self->start_mode('Default Page');

    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Default Page'                        => 'home_page',
        'Show Subscription Events'            => 'show_Subscription_events',
        'Show Subscriptions'                  => 'show_Subscriptions',
        'Show Subscribers'                    => 'show_Subscribers',
        'Edit Subscription'                   => 'edit_Subscription',
        'Search Subscriptions'                => 'search_Subscription',
        'Search Subscriptions by Subscribers' => 'search_by_Subscribers',
        'Add Subscribers'                     => 'add_Subscribers',
        'Add Subscription'                    => 'add_Subscription',
        'Add Subscription Event'              => 'add_Subscription_Event',
        'Remove Subscription'                 => 'remove_Subscription',
        'Remove Subscribers'                  => 'remove_Subscribers',
        'Delete Subscribers'                  => 'delete_Subscribers',
    );

    # set the following to 1 if we don't want to display the value return by the run mode methods
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc') || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $subscription = new alDente::Subscription( -dbc => $dbc );
    $self->param( 'Subscription_Model' => $subscription );

    #    return $self;
    return 0;
}

#####################
sub home_page {
#####################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $q    = $self->query;

    my $GS = $dbc->Table_retrieve_display(
        "Subscription_Event,Subscription Left Join Subscriber ON Subscriber.FK_Subscription__ID=Subscription_ID LEFT JOIN Grp ON Subscriber.FK_Grp__ID=Grp_ID",
        [   'FK_Subscription_Event__ID', 'Subscription_Name', 'Subscription_Event_Details', 'FK_Project__ID', 'FK_Equipment__ID', 'FK_Library__Name',
            'Subscription.FK_Grp__ID as Owner',
            "CASE WHEN Grp_ID IS NULL THEN 'Unsubscribed' ELSE Grp_Name END as Grp"
        ],
        "WHERE FK_Subscription_Event__ID=Subscription_Event_ID",
        -layer       => 'Grp',
        -return_html => 1,
        -order       => 'Grp, Subscription_Event_Name',
        -title       => 'Current Subscription List'
    );

    $GS .= "<HR>" . &Link_To( $dbc->config('homelink'), "Create New Subscription_Event", "&New+Entry=New Subscription_Event" );

    return $GS;
}

#####################
#   This new method in the Subscription returns all the fields of the Subscriptions w/ the matching subscription_event (Subscription_Name, Filters)
#
# Notes: Preliminary version have been implemented by Ash on 7/11/08.  This version shows all the Subscription events.  User can click on the link to see the subscriptions of a subscription event and the subscribers of a selected subscription.
# He probably can put the code inside a new method in the Subscription classl the Subscription::get_SubscriptionDetails($subscription_event_name,$group_filter,$library_filter,$project_filter).  Then the show_Subscription_event
#####################
sub show_Subscription_events {
#####################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $q    = $self->query;
    my $form = "Select a Subscription from the list.";

    $form .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Show Subscription Event' );

    #	$form .= Views::sub_Heading ("Subscription Events", -1);
    &Table_retrieve_display(
        $dbc, 'Subscription_Event',
        [ 'Subscription_Event_ID',
            'Subscription_Event_Name as Event', 'Subscription_Event_Type' ],
        "  Order by Subscription_Event_Type,Subscription_Event_Name",

        #      -selectable_field=>'FK_Subscription_Event__ID',
        -toggle_on_column => 'Subscription_Event_Type',
        -title            => 'Subscription Options',
        -return_html      => 1
    );

    $form .= &Table_retrieve_display(
        $dbc, 'Subscription_Event LEFT JOIN Subscription on FK_Subscription_Event__ID=Subscription_Event_ID LEFT JOIN Subscriber on FK_Subscription__ID=Subscription_ID',
        [ 'FK_Subscription_Event__ID as Event', 'Subscription_Event_Type as Type', 'Subscription_Event_Details', 'Count(distinct Subscription_ID) as Subscriptions', 'Count(distinct Subscriber_ID) as Subscribers' ],
        " Group by Subscription_Event_ID Order by Subscription_Event_Type,Subscription_Event_Name",
        -toggle_on_column => 'Subscription_Event_Type',
        -title            => 'Subscription Options',
        -return_html      => 1
    );
    $form .= $self->add_Event_button();
    return $form;
}

##################################
sub add_Event_button {
##################################
    my $self = shift;

    my $form;
    my $dbc = $self->param('dbc');

    $form .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Add Subscription Event Button' );
    $form .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Subscription_Event_App' ) . $q->submit( -name => "rm", -value => "Add Subscription Event", -class => 'Std' ) . $q->end_form();
    return $form;
}

##################################
sub add_Subscription_Event {
##################################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $q    = $self->query;
    my $form = new SDB::DB_Form(
        -dbc   => $dbc,
        -table => 'Subscription_Event',
    );
    return $form->generate( -title => 'Subscription Event', -navigator_on => 1, -return_html => 1 );
}

##################################
# Display the results hash from search_Subscription in an HTML table
#
# Input: The array reference of the Subscriptions which the user would like to find the subscribers for
#
# Return: $html_string on the html page??
#
####################################
sub show_Subscriptions {
##########################
    my $self = shift;

    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $args{-dbc} || $self->param('dbc');

    #    my $subscription_event_id = $q->param('Subscription_Event_ID') ; # || $self->param('Subscription_Event_ID');
    my $subscription_event_id = $args{-subscription_event_id} || $q->param('ID') || $q->param('Mark') || $q->param('Subscription_Event');
    my $subscription_event_name = $args{-subscription_event_name};    #|| $self->query->param('Library_Name');

    if ($subscription_event_id) {
        if ( $subscription_event_id =~ /,/ ) {
            $subscription_event_name = "IDs: $subscription_event_id";
        }
        else {
            ($subscription_event_name) = &Table_find( $dbc, 'Subscription_Event', 'Subscription_Event_Name', "where subscription_event_id IN ('$subscription_event_id')" );
        }
    }
    elsif ($subscription_event_name) {
        ($subscription_event_id) = &Table_find( $dbc, 'Subscription_Event', 'Subscription_Event_ID', "where Subscription_Event_Name = $subscription_event_name" );
    }
    else {

        #        Message("Select a subscription event from the result list");
        return $self->show_Subscription_events;
    }

    #    my $subscription_event = $q->param('Subscription_Event');
    my $emp_id = $q->param('Employee_ID');
    my $grp    = $q->param('Grp_ID');
    my $all    = $q->param('All');

    if ( !$all ) {
        $emp_id ||= $dbc->get_local('user_id')    || 0;
        $grp    ||= $dbc->get_local('group_list') || 0;
    }

    my $condition = "WHERE FK_Subscription_Event__ID=Subscription_Event_ID AND FK_Subscription_Event__ID IN ($subscription_event_id)";
    my @subscriptions = $dbc->Table_find( 'Subscription,Subscription_Event', 'Subscription_ID', $condition );

    my $form;

    $form .= $dbc->Table_retrieve_display(
        'Subscription_Event,Subscription', [ 'Subscription_ID', 'Subscription_Name', 'FK_Grp__ID', 'FK_Equipment__ID', 'FK_Project__ID', 'FK_Library__Name' ],
        -condition   => $condition,
        -return_html => 1,
        -title       => "Subscription: $subscription_event_name"
    );

    $form .= '<HR>';

    $condition .= ' AND FK_Subscription__ID=Subscription_ID';    ## add link to Subscriber table ...

    my @subscription_fields = ( 'FK_Subscription__ID', 'Subscriber_ID' );

    $form .= $dbc->Table_retrieve_display(
        'Subscription_Event,Subscription,Subscriber', [ @subscription_fields, 'Subscriber.FK_Grp__ID' ],
        "$condition AND Subscriber_Type ='Grp' ",                # AND Subscriber.FK_Grp__ID IN ($grp)
        -return_html     => 1,
        -title           => "Group Subscribers to $subscription_event_name",
        -link_parameters => { 'Subscription_ID' => "rm=Edit Subscription&ID=<VALUE>&cgi_application=alDente::Subscription_Event_App" },
        -alt_message     => 'No Group Subscribers found'
    );
    $form .= vspace(5);

    $form .= $dbc->Table_retrieve_display(
        'Subscription_Event,Subscription,Subscriber', [ @subscription_fields, 'Subscriber.FK_Employee__ID' ],
        "$condition AND Subscriber_Type ='Employee' ",           # AND Subscriber.FK_Employee__ID IN ($emp_id)
        -return_html => 1,
        -title       => "Personal Subscribers to $subscription_event_name",
        -alt_message => "No Personal Subscribers found"
    );
    $form .= vspace(5);
    $form .= $dbc->Table_retrieve_display(
        'Subscription_Event,Subscription,Subscriber', [ @subscription_fields, 'Subscriber.FK_Contact__ID' ],
        "$condition AND Subscriber_Type ='Contact' ",
        -return_html => 1,
        -title       => "Contact Subscribers to $subscription_event_name",
        -alt_message => "No Contact Subscribers found"
    );
    $form .= vspace(5);
    $form .= $dbc->Table_retrieve_display(
        'Subscription_Event,Subscription,Subscriber', [ @subscription_fields, 'Subscriber.External_Email' ],
        "$condition AND Subscriber_Type ='ExternalEmail' ",
        -return_html => 1,
        -title       => "External Email Subscribers to $subscription_event_name",
        -alt_message => "No External Email Subscribers found"
    );
    $form .= vspace(5);
    $form .= $self->delete_button($subscription_event_id);

    if ( int(@subscriptions) >= 1 ) {
        foreach my $subscription (@subscriptions) {
            $form .= vspace(5);
            $form .= $self->subscribe_button($subscription);
        }
    }
    $form .= $self->new_subscription_button($subscription_event_id);
    return $form;

}

sub delete_Subscribers {
    my $self                  = shift;
    my $dbc                   = $self->param('dbc');
    my $subscription_event_id = $q->param('Subscription_Event_ID');
    my $confirmed             = $q->param('confirmed');
    if ($confirmed) {
        my @records = $q->param('Mark');
        my $list = join ',', @records;
        $self->param('Subscription_Model')->delete_subscriber_record( -records => $list, -dbc => $dbc );
        return $self->show_Subscription_events();
    }
    else {
        my $dbc = $self->param('dbc');
        my $subscription_event_name = $dbc->get_FK_info( 'FK_Subscription_Event__ID', $subscription_event_id );
        my $form .= alDente::Form::start_alDente_form( $dbc, 'subscribe' );

        $form .= $dbc->Table_retrieve_display(
            'Subscription_Event RIGHT JOIN Subscription on FK_Subscription_Event__ID=Subscription_Event_ID RIGHT JOIN Subscriber on FK_Subscription__ID=Subscription_ID',
            [ 'Subscriber_ID', 'Subscription_Name as Subscription', 'FK_Subscription_Event__ID as Event', 'Subscriber_Type', 'Subscriber.FK_Grp__ID', 'Subscriber.FK_Employee__ID', 'Subscriber.FK_Contact__ID', 'External_Email' ],
            " WHERE FK_Subscription_Event__ID = $subscription_event_id Order by Subscriber_Type",
            -selectable_field => 'Subscriber_ID',
            -toggle_on_column => 'Subscription_Event_Type',
            -title            => 'Subscription Options',
            -return_html      => 1
        );

        $form
            .= $q->hidden( -name => 'cgi_application',       -value => 'alDente::Subscription_Event' )
            . $q->hidden( -name  => 'Subscription_Event_ID', -value => $subscription_event_id )
            . $q->submit( -name => "rm", -value => "Delete Subscribers", -class => 'action' )
            . $q->hidden( -name => 'confirmed', -value => 'confirmed' )
            . $q->end_form();

        return $form;
    }

}

sub delete_button {
    my $self                  = shift;
    my $subscription_event_id = shift;

    my $dbc = $self->param('dbc');
    my $subscription_event_name = $dbc->get_FK_info( 'FK_Subscription_Event__ID', $subscription_event_id );
    my $form
        .= alDente::Form::start_alDente_form( $dbc, 'subscribe' )
        . $q->hidden( -name => 'cgi_application',       -value => 'alDente::Subscription_Event' )
        . $q->hidden( -name => 'Subscription_Event_ID', -value => $subscription_event_id )
        . $q->submit( -name => "rm", -value => "Delete Subscribers", -class => 'action' )
        . $q->end_form();

    return $form;
}

sub subscribe_button {
    my $self         = shift;
    my $subscription = shift;

    my $dbc = $self->param('dbc');
    my $subscription_name = $dbc->get_FK_info( 'FK_Subscription__ID', $subscription );

    my $grps = $dbc->get_local('group_list');

    my $form
        .= alDente::Form::start_alDente_form( $dbc, 'subscribe' )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Subscription_Event' )
        . $q->hidden( -name => 'Subscription_ID', -value => $subscription )
        . $q->hidden( -name => 'rm',              -value => 'Add Subscribers' )
        . $q->submit( -name => "Subscribe Group", -value => "Subscribe Group to: $subscription_name", -class => 'Std' )
        . alDente::Tools::search_list( -dbc => $dbc, -name => 'Grp.Grp_Name', -mode => 'popup', -condition => "Grp_ID IN ($grps)" )
        . vspace()
        . $q->submit( -name => "Personally Subscribe", -value => "Subscribe Person to: $subscription_name", -class => 'Std' )
        . vspace()

        #  . alDente::Tools::search_list(-dbc => $dbc, -name => 'Employee.Employee_Name')
        . $q->submit( -name => "Subscribe Contact", -value => "Subscribe Contact to: $subscription_name", -class => 'Std' ) . vspace() . $q->submit( -name => "Subscribe External", -value => "Subscribe External Email", -class => 'Std' ) . $q->end_form();

    return $form;
}

sub new_subscription_button {
    my $self                  = shift;
    my $subscription_event_id = shift;

    my $dbc = $self->param('dbc');
    my $subscription_event_name = $dbc->get_FK_info( 'FK_Subscription_Event__ID', $subscription_event_id );
    my $form
        .= alDente::Form::start_alDente_form( $dbc, 'subscribe' )
        . $q->hidden( -name => 'cgi_application',       -value => 'alDente::Subscription_Event' )
        . $q->hidden( -name => 'Subscription_Event_ID', -value => $subscription_event_id )
        . $q->hidden( -name => 'rm',                    -value => 'Add Subscription' )
        . $q->submit( -name => "Define new Subscription to: $subscription_event_name", -class => 'Std' )
        . $q->end_form();

    return $form;
}

##################################
# Display the results hash from search_Subscribers in an HTML table
#
# Input: The hash reference of the subscriber details of the Subscription which the user would like to find the subscribers for
#
# Return: $html_string on the html page??
#
# Q: show_Subscription_events retun a table with links to the Subscription records.  When the user click on a a Subscription in the next page, all the subscribers shows up.
###########################
sub show_Subscribers {
############################

    my $self                  = shift;
    my %args                  = &filter_input( \@_ );
    my $q                     = $self->query;
    my $dbc                   = $self->param('dbc') || $args{-dbc};
    my $subscription_id       = $args{-subscription_id} || $q->param('Mark');
    my $subscription_event_id = $q->param('subscription_event_id');

    if ( $subscription_id == 0 ) {
        Message("Select a subscription event first");
        $self->show_Subscriptions( -subscription_event_id => $subscription_event_id );
    }

    # call a method in Subscription.pm which get all the subscriber records.

    # display the results on a table
    my $form;

    $form .= alDente::Form::start_alDente_form( $dbc, -name => 'Show Subscribers of subscription' );
    $form .= Views::sub_Heading( "List of Subscribers for Subscription (ID = $subscription_id)", -1 );

    my %subscription_events = &Table_retrieve( $dbc, 'Subscriber', [ 'Subscriber_ID', 'Subscriber_Type', 'FK_Grp__ID', 'FK_Employee__ID', 'FK_Contact__ID', 'External_Email' ], "where FK_Subscription__ID = $subscription_id" );
    my $Grp_IDs = $subscription_events{'FK_Grp__ID'};

    my @grp_names;
    foreach my $grp_id (@$Grp_IDs) {
        my ($grp_name) = &get_FK_info( $dbc, 'FK_Grp__ID', $grp_id );
        push( @grp_names, $grp_name );
    }
    $subscription_events{'fk_frp__id'} = \@grp_names;

    my @keys   = qw(Subscriber_ID Subscriber_Type FK_Grp__ID FK_Employee__ID Contact_Name External_Email);
    my %labels = (
        'Subscriber_ID'     => 'ID',
        'Subscription_Type' => 'Type',
        'FK_Grp__ID'        => 'Group',
        'FK_Employee__ID'   => 'Employee',
        'FK_Contact__ID'    => 'Contact',
        'External_Email'    => 'Email',
    );

    my $table = $dbc->SDB::HTML::display_hash(
        -dbc              => $dbc,
        -keys             => \@keys,
        -hash             => \%subscription_events,
        -return_html      => 1,
        -selectable_field => 'Subscriber_ID',
        -labels           => \%labels,
    );
    $form .= $table;
    my $add_subscriber_button    = $q->submit( -name => 'rm', -value => 'Add Subscribers',    -class => "Std", -force => 1 ) . "<BR>";
    my $delete_subscriber_button = $q->submit( -name => 'rm', -value => 'Remove Subscribers', -class => "Std", -force => 1 );
    $form .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Subscription_Event_App', -force => 1 ) . $q->hidden( -name => 'Subscription_ID', -value => $subscription_id, -force => 1 ) . $add_subscriber_button . $delete_subscriber_button;
    $form .= $q->end_form();

    return $form;
}

#######################
# This method allows the user to add a new Subscriber for a Subscription
#
# Input: Subscription_ID (mandatory),
#        Subscriber_Type - will be 1 of 'Employee','Grp','Contact','ExternalEmail' (mandatory),
#        Group_ID, Contact_ID, Employee_ID,External_Email (depending on Subscriber_Type)
#
# Output: return 0 if add is sucessful.  1 otherwise
########################
sub add_Subscribers {
########################
    # To Do: add a Subscriber record to the database
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};

    #my $subscriber_id =  0 || $q->param('Mark');
    my $subscription_id = $q->param('Subscription_ID');
    my $table           = "Subscriber";
    my $configs;
    my %preset;
    my %grey;
    my %require;
    my %list;
    my %include;
    my %omit;
    my $append_html;

    my $personal = $q->param('Personally Subscribe');
    my $grp      = $q->param('Subscribe Group');
    my $contact  = $q->param('Subscribe Contact');
    my $external = $q->param('Subscribe External');
    if ($personal) {
        $grey{Subscriber_Type}     = 'Employee';
        $preset{FK_Employee__ID}   = $q->param('Employee.Employee_Name Choice') || $q->param('Employee.Employee_Name');
        $omit{FK_Grp__ID}          = '';
        $omit{FK_Contact__ID}      = '';
        $omit{External_Email}      = '';
        $grey{FK_Subscription__ID} = $dbc->get_FK_info( 'FK_Subscription__ID', $subscription_id );
    }
    elsif ($grp) {
        $grey{Subscriber_Type}     = 'Grp';
        $preset{FK_Grp__ID}        = $q->param('Grp.Grp_Name Choice') || $q->param('Grp.Grp_Name');
        $omit{FK_Employee__ID}     = '';
        $omit{FK_Contact__ID}      = '';
        $omit{External_Email}      = '';
        $grey{FK_Subscription__ID} = $dbc->get_FK_info( 'FK_Subscription__ID', $subscription_id );
    }
    elsif ($contact) {
        $grey{Subscriber_Type}     = 'Contact';
        $omit{FK_Employee__ID}     = '';
        $omit{FK_Grp__ID}          = '';
        $omit{External_Email}      = '';
        $grey{FK_Subscription__ID} = $dbc->get_FK_info( 'FK_Subscription__ID', $subscription_id );
    }
    elsif ($external) {
        $grey{Subscriber_Type}     = 'ExternalEmail';
        $omit{FK_Employee__ID}     = '';
        $omit{FK_Contact__ID}      = '';
        $omit{FK_Grp__ID}          = '';
        $grey{FK_Subscription__ID} = $dbc->get_FK_info( 'FK_Subscription__ID', $subscription_id );
    }

    my $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Subscriber', -target => 'Database', -append_html => $append_html );
    $form->configure( -preset => \%preset, -grey => \%grey, -require => \%require, -title => 'New Subscriber', -list => \%list, -include => \%include, -omit => \%omit );

    my $output = $form->generate( -return_html => 1 );
    return $output;
}

#######################
# This method allows the user to add a new Subscription for a Subscription Event
#
# Input: Subscriber_Event_ID (mandatory),
#        Group_ID, Library_Name, Equipment_ID (optional)
#
# Output: return 0 if add is sucessful.  1 otherwise
########################
sub add_Subscription {
########################
    # To Do: add a Subscription record to the database
    my $self                  = shift;
    my %args                  = &filter_input( \@_ );
    my $q                     = $self->query;
    my $dbc                   = $self->param('dbc') || $args{-dbc};
    my $subscription_event_id = $q->param('Subscription_Event_ID');
    my $table                 = "Subscription";
    my $configs;
    my %preset;
    my %grey;
    my %require;
    my %list;
    my %include;
    my %omit;
    my $append_html;

    $preset{'Subscription_Event_ID'} = $subscription_event_id;
    my $form = SDB::DB_Form->new( -dbc => $dbc, -table => $table, -target => 'Database', -append_html => $append_html );
    $form->configure( -preset => \%preset, -grey => \%grey, -require => \%require, -title => 'New Subscription', -list => \%list, -include => \%include, -omit => \%omit );

    my $output = $form->generate( -return_html => 1 );
    return $output;
}

#######################
# This method allows the user to remove a Subscriber by its ID
#
# Input: Subscriber ID of the Subscriber which the user would like to remove
#
# Output: return 0 if delete is sucessful.  1 otherwise
########################
sub remove_Subscribers {
########################
    # To Do: remove the specified Subscriber record from the database
    my $self            = shift;
    my %args            = &filter_input( \@_ );
    my $q               = $self->query;
    my $dbc             = $self->param('dbc') || $args{-dbc};
    my $subscriber_id   = 0 || $q->param('Mark');
    my $subscription_id = $q->param('Subscription_ID');
    if ( $subscriber_id == 0 ) {
        Message("Press the Back button and select a subscriber from the result list");
        return $self->show_Subscribers( -subscription_id => $subscription_id );
    }

    if ( defined $Sess ) {
        $dbc->warning( "Are you sure you want to delete the selected subscriber ($subscriber_id) ?", -now => 1 );
    }

    my $ok = $dbc->delete_records( -table => 'Subscriber', -field => 'Subscriber_ID', -id_list => $subscriber_id, -quiet => 1 );

    Message("Removed Subscriber.");

    return $self->show_Subscribers( -subscription_id => $subscription_id );
}

#######################
# This method allows the user to remove a Subscription by its ID
#
# Input: Subscription ID of the Subscription which the user would like to remove
#
# Output: return 0 if delete is sucessful.  1 otherwise
########################
sub remove_Subscription {
########################
    # To Do: remove the specified Subscription record from the database
    return 'remove Subscription (under construction)';

}
#####################
#
# home_page (default)
#
# Return: display (table)
##########################
sub search_Subscriptions {
##########################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my $form;    # 'Subscription';
                 # Get CGI query object
    my $q = $self->query;

    $form .= alDente::Form::start_alDente_form( $dbc, -name => 'default page' );
    $form .= 'Enter the Subscription_Event_ID of the event you want to see the details for: ' . "<br>";
    $form .= $q->textfield( -name => 'subscription_event_id', -force => 1 );
    $form .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Subscription_Event_App', -force => 1 );

    $form .= $q->submit( -name => 'rm', -value => 'Search Subscriptions',                -class => "Search", -force => 1 ) . "<br>";
    $form .= $q->submit( -name => 'rm', -value => 'Show Subscription Events',            -class => "Search", -force => 1 ) . "<br>";
    $form .= $q->submit( -name => 'rm', -value => 'Search Subscriptions by Subscribers', -class => "Search", -force => 1 );

    $form .= $q->end_form();

    return $form;
}

sub edit_Subscription {

    return 2;
}

##################################################################
# Find the subscriptions of an Subscription Event
#
# Input: Name of the Subscription Event which the user would like to find the subscriptions
#
# Return: a hash that contains all the fields of the  Subscriptions for the subscription event specified by the input
##################################################################
sub search_Subscription {
#####################
# this method will call the Subscription::get_SubscriptionDetails($subscription_event_name,$group_filter,$library_filter,$project_filter).  This new method in the Subscription returns all the fields of the Subscriptions w/ the matching subscription_event (Subscription_Name, Filters)
    my $self = shift;
    my $q    = $self->query;
    my %args = $q->param();

    my $html_table;
    my %args = &filter_input( \@_ );

    my $subscription_event_id = $args{-input} || $q->param('subscription_event_id');    # args input is empty

    #    $string = "inside search_Subscription, we are doing a search on the subscriptions for the subscription event with id = $subscription_event_id.";
    $html_table = $self->param('Subscription_Model')->get_Subscription( -subscription_event_id => $subscription_event_id );

    return $html_table;
}
##################################
# Find all the subscriptions of a user/group/contact had signed up for
#
# Input: The Name of the user/group/contact which the user would like to find the subscriptions for
#
# Return: all the Subscriptions for the individual(s) specified by the input.
#
# Q: Are we showing the subscriber records (i.e. if the subscriber is a group, only the name of the group is shown)
# or to show all the email address?
#
############################
sub search_by_Subscribers {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $args{-dbc} || $self->param('dbc');

    my $form .= alDente::Form::start_alDente_form( $dbc, -name => 'Search_Page' );
    $form .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Subscription_Event_App', -force => 1 );
    $form .= $q->hidden( -name => 'rm', -value => 'Search Subscriptions by Subscribers', -force => 1 );
    $form .= alDente::Tools::search_list( -dbc => $dbc, -name => 'Grp.Grp_Name', -mode => 'popup' );
    $form .= $q->submit(
        -name    => 'Search By Group',
        -value   => "Search By Group",
        -class   => "Search",
        -force   => 1,
        -onClick => "unset_mandatory_validators(this.form); document.getElementById('Search_By_Group_validator').setAttribute('mandatory',1); return validateForm(this.form)"
        )
        . set_validator( -name => 'Grp.Grp_Name', -id => 'Search_By_Group_validator' )
        . &vspace();
    $form .= alDente::Tools::search_list( -dbc => $dbc, -name => 'Employee.Employee_Name', -mode => 'popup' );
    $form .= $q->submit(
        -name    => 'Search By Employee',
        -value   => "Search By Employee",
        -class   => "Search",
        -force   => 1,
        -onClick => "unset_mandatory_validators(this.form); document.getElementById('Search_By_Empolyee_validator').setAttribute('mandatory',1); return validateForm(this.form)"
        )
        . set_validator( -name => 'Employee.Employee_Name', -id => 'Search_By_Empolyee_validator' )
        . &vspace();
    $form .= $q->end_form();

    my $input = $q->param('Grp.Grp_Name Choice') || $q->param('Employee.Employee_Name Choice');
    if ($input) {
        $form .= Views::sub_Heading("Subscriptions by $input");
        my %subscription = $self->param('Subscription_Model')->find_Subscription_by_subscriber( -dbc => $dbc, -group => $q->param('Grp.Grp_Name Choice'), -employee => $q->param('Employee.Employee_Name Choice') );
        my @keys = qw(Subscription_ID Subscription_Name);
        $form .= SDB::HTML::display_hash( -dbc => $dbc, -hash => \%subscription, -keys => \@keys, -return_html => 1 );
    }

    return $form;
}

return 1;
