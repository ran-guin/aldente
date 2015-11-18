##############################################################################################
# alDente::Employee_Views.pm
#
# Interface generating methods for the Contact MVC  (assoc with Contact.pm, Contact_App.pm)
#
##############################################################################################
package alDente::Contact_Views;
use base alDente::Object_Views;
use strict;

## Standard modules ##
use CGI qw(:standard);

## Local modules ##
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

use RGTools::RGIO;
use RGTools::Views;

use alDente::Form;

#use alDente::Contact;

## globals ##
use vars qw( %Configs );

my $q = new CGI;

####################
sub object_label {
####################
    my $self = shift;
    my $dbc = $self->{dbc};
    
    my $Object = $self->Model();

    my $label = "<B>" . $Object->value('Contact.Contact_Name') . "</B>";

    return $label;
}

####################
sub home_page {
####################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $Contact   = $self->{'Contact'};
    my $id        = $Contact->{id};
    my $dbc       = $Contact->{dbc};
    my $timestamp = timestamp();

    $Contact->primary_value( -table => 'Contact', -value => $id );
    my $details = $Contact->load_Object();

    my $info  = "<h1>" . $Contact->value('Contact_Name') . "</h1>";
    my $phone = $Contact->value('Contact_Phone');

    if ($phone) { $info .= 'Phone: ' . $Contact->value('Contact_Phone') }

    ## show collaborations ##

    $info .= '<hr>';
    my $Object = new alDente::Object( -dbc => $dbc );
    $info .= $Object->View->join_records( -dbc => $dbc, -defined => "FK_Contact__ID", -id => $id, -join => 'FK_Project__ID', -join_table => "Collaboration", -filter => "Project_Status = 'Active'", -title => 'Collaborations' );
    $info .= $self->LDAP_box();
    $info .= '<hr>';

    return &Views::Table_Print( content => [ [ $info, $Contact->display_Record( -filename => "$URL_temp_dir/Contact.$timestamp.html" ) ] ],, print => 0 );
}

###################################
#
###################################
sub LDAP_box {
###################################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $Contact = $self->{'Contact'};
    my $id      = $Contact->{id};
    my $dbc     = $Contact->{dbc};

    my $page
        .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => "" )
        . $q->hidden( -name => "Contact_ID", -value => $id )
        . "User Name: "
        . $q->textfield( -name => 'user_name', -size => 15 ) . "<BR>"
        . $q->submit( -name => 'rm', -label => 'Create LDAP Account', -class => "Action", -force => 1 )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Contact_App', -force => 1 )
        . br()
        . $q->end_form();
    return $page;
}

#####################
sub contact_main {
#####################
    #
    # Main Contacts page (with organizations/contacts/
    #
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $Contact = $self->{'Contact'};
    my $id      = $Contact->{id};
    my $dbc     = $Contact->{dbc};
    my $page;
    
    my @Ctypes        = $dbc->Table_find( 'Contact',              'Contact_Type',      "Order by Contact_Type",                                                                             'Distinct' );
    my @Otypes        = $dbc->Table_find( 'Organization,Contact', 'Organization_Type', "where Organization_ID = FK_Organization__ID Order by Organization_Type",                            'Distinct' );
    my @contacts      = $dbc->Table_find( 'Contact',              'Contact_Name',      "Order by Contact_Name",                                                                             'Distinct' );
    my @organizations = $dbc->Table_find( 'Organization,Contact', 'Organization_Name', "where Organization_ID = FK_Organization__ID Group by Organization_Name Order by Organization_Name", 'Distinct' );

    ## Contacts ##
    if ( $dbc->table_loaded('Contact') &&  $dbc->table_loaded('Organization') ) {
        my $add_contact_link = &Link_To( $dbc->config('homelink'), "<span class=small >[add new]</span>", "&New Entry=New Contact");
        my $search_contact_link = 'Search for: ' . &Link_To( $dbc->config('homelink'), 'Contact', '&Search+for=1&Table=Contact' );

        my $contact_table = alDente::Form::init_HTML_table( 'Contacts ' . $add_contact_link, -right=>$search_contact_link, -margin => 'on' );
        my $contact_icon = LampLite::Login_Views->icons( 'Contacts', -dbc => $dbc );

        my $form = new LampLite::Form(-dbc=>$dbc, -name=>'contact');

        $form->append('', "Find Contact by Name to view & update current Project collaborations");
        $form->append( $form->View->prompt(-field=>'Contact_ID', -table=>'Contact'));
        $form->append( $form->View->prompt(-field=>'Contact_Name',-table=>'Contact'));
        $form->append( $form->View->prompt(-field=>'FK_Organization__ID', -table=>'Contact') );

        $form->append( '', $q->submit( -name => 'List Contacts', -class => 'Search' ) );

        $contact_table->Set_Row([$contact_icon, $form->generate(-wrap=>1) ]);

        $page .= $contact_table->Printout(0);
    }

    ## Organizations ##    
    if ( $dbc->table_loaded('Organization') ) {
        my $add_organization_link = &Link_To( $dbc->config('homelink'), "<span class=small >[add new]</span>", "&New Entry=Organization");
        my $search_organization_link = 'Search for: ' . &Link_To( $dbc->config('homelink'), 'Contact', '&Search+for=1&Table=Organization' );

        my $org_table = alDente::Form::init_HTML_table( 'Organizations ' . $add_organization_link, -margin => 'on', -right=>$search_organization_link);
        my $org_icon = LampLite::Login_Views->icons( 'Organization', -dbc => $dbc );

        my $form = new LampLite::Form(-dbc=>$dbc, -name=>'org');
        $form->append( $form->View->prompt(-field=>'Organization_ID', -table=>'Organization'));
        $form->append( $form->View->prompt(-field=>'Organization_Name',-table=>'Organization'));
        $form->append( $form->View->prompt(-field=>'Organization_Type', -table=>'Organization') );

        $form->append( '', $q->submit( -name => 'List Organizations', -class => 'Search' ) );

        $org_table->Set_Row([$org_icon, $form->generate(-wrap=>1) ]);

        $page .= $org_table->Printout(0);
    }

    if ( $dbc->package_active('Funding_Tracking') ) {

        $page .= &alDente::Form::start_alDente_form( $dbc, "Funding Options", $dbc->homelink() );

        my $add_funding_link = &Link_To( $dbc->config('homelink'), "<span class=small >[add new]</span>", "&New Entry=New Funding");
        my $search_funding_link = 'Search for: ' . &Link_To( $dbc->config('homelink'), 'Contact', '&Search+for=1&Table=Funding' );

        my $funding_table = alDente::Form::init_HTML_table( 'Funding ' . $add_funding_link, -margin => 'on', -right=>$search_funding_link );
        my $funding_icon = LampLite::Login_Views->icons( 'Funding', -dbc => $dbc, -height => 50 );

        $funding_table->Set_Row(
            [   $funding_icon,
                submit( -name => 'List Funding Grants', -class => 'Search' ) . hidden( -name => 'Table', -value => 'Funding', -force => 1 )
            ]
        );

        $page .= $funding_table->Printout(0);
        $page .= end_form();
    }

    return $page;
}

#####################
sub collaborations {
#####################
    my $self       = shift;
    my %args       = &filter_input( \@_, -args => 'contact_id', mandatory => 'contact_id' );
    my $contact_id = $args{-contact_id};
    my $dbc        = $args{-dbc} || $self->{dbc};

    my $page;
    my $q = new CGI;

    my %collaborations = $dbc->Table_retrieve(
        'Collaboration, Project, Contact',
        [ 'Project_Name', 'Collaboration_Type', 'FK_Organization__ID', 'Project_ID' ],
        "WHERE FK_Contact__ID = Contact_ID AND Contact_ID = $contact_id AND FK_Project__ID = Project_ID ORDER BY Project_Name"
    );
    my $org      = $collaborations{FK_Organization__ID}[0];
    my @projects = $collaborations{Project_Name};
    my @types    = @{ $collaborations{Collaboration_Type} } if $collaborations{Collaboration_Type};

    $page
        .= alDente::Form::start_alDente_form( $dbc, -name => '' )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Submission_App', -force => 1 )
        . $q->hidden( -name => 'FK_Organization__ID', -value => $org, -force => 1 )
        . $q->submit( -name => 'rm', -value => 'Add New Contact', -class => "Action", -force => 1 ) . "<br>"
        . $q->hidden( -name => 'FK_Contact__ID', -value => $contact_id, -force => 1 )
        . $q->end_form();

    $page .= "<h3>Your Projects: ($contact_id)</H3>" . "<UL>";

    my $max = @types;
    for my $index ( 0 .. $max - 1 ) {
        $page .= "<LI> " . $collaborations{Project_Name}[$index];
        if ( $collaborations{Collaboration_Type}[$index] =~ /admin/i ) {
            $page .= " (Admin) " . vspace();
            my $prj_id = $collaborations{Project_ID}[$index];
            my @other_contact = $dbc->Table_find( 'Contact,Collaboration', 'Contact_Name', "WHERE FK_Contact__ID = contact_id and FK_Project__ID = $prj_id " );
            $page .= Cast_List( -list => \@other_contact, -to => 'ol' );
        }
        $page .= vspace();
    }

    $page .= "</UL>";
    if ( grep /Admin/i, @types ) {
        $page .= vspace(2) . Link_To( "new_account_request.pl?External=1&FK_Organization__ID=$org&FKAdmin_Contact__ID=$contact_id", "Apply for New Account", -window => ['newwin'] );
    }
    return $page;
}

return 1;
