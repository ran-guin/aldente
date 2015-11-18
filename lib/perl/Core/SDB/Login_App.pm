###################################################################################################################################
# SDB::Login_App.pm
#
# Interface generating methods for the Session MVC  (associated with Session.pm, Session_App.pm)
#
###################################################################################################################################
package SDB::Login_App;

use base LampLite::Login_App;

use strict;

use Time::localtime;

## Local modules ##
use SDB::Login;
use SDB::Login_Views;
use SDB::HTML;

use RGTools::RGIO;

use LampLite::Bootstrap;

##############################
# global_vars                #
##############################
my $BS = new Bootstrap();    ## Login errors do not need to be session logged, so can be called directly ##

############
sub setup {
############
    my $self = shift;

    $self->start_mode('');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   
            'Contact Profile'         => 'contact_Profile',
            'Apply for Account'   => 'apply_for_Account',
            'Reset Password'   => 'forgot_Password',
            'Email Username'   => 'forgot_Password',
            'Apply for Contact Account' => 'apply_for_Contact_Account',
        }
    );

    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

######################
sub contact_Profile {
######################
    my $self = shift;
    my $q = $self->query();
    my $dbc = $self->param('dbc');
    
    my $contact_id = $q->param('Contact_ID') || $dbc->config('contact_id');
    
    my $View = $self->View(-class=>'alDente::Contact', -id => $contact_id);
    my $Model = $self->Model(-class=>'alDente::Contact', -id => $contact_id);
    
    my $collabs = $View->collaborations( -contact_id => $contact_id );
    my $record =  $Model->display_Record( -view_only => 1 );
    
    return $BS->row(-row=>[$collabs,$record], -span=>[8,4]);
}

#
#################################
sub apply_for_Contact_Account {
#################################
    my $self = shift;
    
    my $dbc = $self->dbc;
    my $q = $self->query();
    
    my $org           = $q->param('FK_Organization__ID');
    my $admin_contact = $q->param('FKAdmin_Contact__ID');
    
    my (%grey, %preset, %list, %omit);

    my ($guest_id) = $dbc->Table_find( 'Employee', 'Employee_ID', "WHERE Employee_Name = 'Guest'" );
    $omit{'contact_status'}      = 'Active';
    $omit{'Contact_Fax'}         = '';
    $omit{'Contact_Type'}        = 'Collaborator';
    $omit{'Canonical_Name'}      = '';
    $omit{'Collaboration_Type'}  = 'Standard';
    $grey{'FK_Organization__ID'} = $dbc->get_FK_info( 'Organization', $org );

    my $Form = new SDB::DB_Form(
        -dbc    => $dbc,
        -target => 'Submission',
        -table  => 'Contact',
        );

    my $admin_id = $dbc->get_FK_info( 'FK_Contact__ID', $admin_contact );

    $Form->configure( -grey => \%grey, -omit => \%omit, -preset => \%preset, -list => \%list );
    $Form->define_Submission(
        -grey => {
            'Submission_Source'   => 'External',
            'Submission_Comments' => 'New Collaborator Account',
            'FKAdmin_Contact__ID' => $admin_id,
            },
        -omit => {
                'Reference_Code'           => 'GSC-0001',
                'FKSubmitted_Employee__ID' => $dbc->get_FK_info( 'FK_Employee__ID', $guest_id ),
                'FKTo_Grp__ID'             => 'Public',
                'FKFrom_Grp__ID'           => 'External',
            }

        );
        
    return $Form->generate( -title => 'Employee Info', -navigator_on => 1, -return_html => 1 );    # -fields=>['Employee_Name','Employee_FullName']);
}

#########################
sub apply_for_Account {
#########################
    my $self = shift;
    
    my $dbc = $self->dbc;
    my $q = $self->query();

#    return $self->apply_for_Contact_Account();
    
    my $default_grp   = $q->param('FK_Grp__ID') || 'Public';
    my $confirmed     = $q->param('Confirmed'); 
    my $dept       = $q->param('FK_Department__ID');

    my $dept_id = $dept;
    if ($dept =~/^\d+/) { 
        $dept = $dbc->get_FK_info( 'FK_Department__ID', $dept );
    }
    elsif ($dept) {
        $dept_id = $dbc->get_FK_ID( 'FK_Department__ID', $dept );
    }

    my $page; 
    if ( $dept_id ) {
        $page .=  page_heading("Applying for new LIMS Account [under $dept]");
        ## preset or grey out most of the fields before loading form ##
        my %grey;
        my %preset;
        my %list;

        my @grp_list = $dbc->get_FK_info_list( 'FK_Grp__ID', "WHERE FK_Department__ID = $dept_id" );
        $list{FK_Grp__ID} = \@grp_list;
        
        my ($guest_id) = $dbc->Table_find( 'Employee', 'Employee_ID', "WHERE Employee_Name = 'Guest'" );
        $grey{FK_Employee__ID} = [ $dbc->get_FK_info('FK_Employee__ID', $guest_id) ];
        
        $preset{FK_Grp__ID} = $dbc->get_FK_info( 'FK_Grp__ID', $default_grp );
        ( $preset{FK_Employee__ID} ) = $guest_id;
        $grey{FK_Department__ID} = $dbc->get_FK_info( 'FK_Department__ID', $dept_id );
        $grey{Employee_Status} = 'Active';
        $grey{Machine_Name} = 'Active';
        
        my %omit;
        $omit{'Machine_Name'}    = '';

        ## load form
        my $Form = new SDB::DB_Form(
            -dbc    => $dbc,
            -target => 'Submission',
            -table  => 'Employee',
            # -fields=>['Employee.Employee_Name','Employee.Employee_FullName','Employee.Employee_Start_Date as Start_Date','Employee.Email_Address','Employee.Position','Employee.FK_Department__ID as Dept'],
            );

        $Form->configure( -grey => \%grey, -omit => \%omit, -preset => \%preset, -list => \%list );
        $Form->define_Submission(
            -grey => {
                'FKSubmitted_Employee__ID' => $dbc->get_FK_info( 'FK_Employee__ID', $guest_id ),
                'FKTo_Grp__ID'             => $dbc->get_FK_info( 'FK_Grp__ID',      $default_grp ),
                'FKFrom_Grp__ID'           => 'Public',
                'Submission_Comments'      => 'New Employee Account',
                'Table_Name' => 'Employee',
                'Key_Value' => 'TBD',
                'Approved_DateTime' => '',
                'Submission_DateTime' => date_time(),
                'FK_Contact__ID' => '',
                'Reference_Code' => 'GSC-0001',
                'FKApproved_Employee__ID' => '',
                },
            );

        $page .= $Form->generate( -title => 'Employee Info', -navigator_on => 1, -return_html => 1 );    # -fields=>['Employee_Name','Employee_FullName']);
    }
    else {
        $page .=  page_heading("Applying for new LIMS Account");
        ## Require users to choose department that they are applying to - this presets their groups and dictates who is sent the submission to approve ##
        $page .= "<h3>Choose primary department with which to be associated:</h3>(access to other departments may be added later)<p>";
        $page .= "<UL>";
        foreach my $dept ( $dbc->Table_find( 'Department', 'Department_Name,Department_ID', ' Order by Department_Name' ) ) {
            my ( $dept_name, $dept_id ) = split ',', $dept;
            my ($grp)
            = $dbc->Table_find( 'Department,Grp left join GrpEmployee on FK_Grp__ID=Grp_ID', 'Grp_ID,Count(*) as Num',
            "WHERE FK_Department__ID=Department_ID AND Department_ID=$dept_id GROUP BY Department_ID,Grp_ID ORDER BY Department_ID,Num desc LIMIT 1" );
            ($default_grp) = split ',', $grp;

            $page .= "\n<LI>" . Link_To( $dbc->homelink(), $dept_name, "?cgi_application=SDB::Login_App&rm=Apply for Account&FK_Department__ID=$dept_id&FK_Grp__ID=$default_grp" );
        }
        $page .= "</uL>\n";
    }
    
    return $page;
}

##################
sub local_login {
##################
    my $self = shift;
    my %args = filter_input( \@_ );
    
    my $q             = $self->query();
    my $user          = $q->param('User');
    my $password      = $q->param('Pwd') || 'pwd';    ## default to Guest user password so that no password works for Guest ;
    my $printer_group = $q->param('Printer_Group');
    my $dbc           = $self->dbc;

    my $login = $self->Model;
    my $view  = $self->View;

    ### Log in if necessary ##
    my $session = $dbc->{session};
    my ( $user_id, $user_name, $result ) = $login->log_in( -user => $user, -dbc => $dbc, -pwd => $password );
    $dbc->{session} = $session;

    my $page;
    if ( $result eq 'logged in' ) {
            my $mod = $dbc->dynamic_require($dbc->config('login_type'));
            my $User = $mod->new( -id => $user_id, -dbc => $dbc );   ## should probably be part of $dbc, but pass in for now to reduce potential legacy problems
            
            if ( $dbc->table_loaded('Printer') && $printer_group ) {
                require LampLite::Barcode;
                LampLite::Barcode->reset_Printer_Group( -dbc=>$dbc, -name => $printer_group, -quiet => 1, -User=>$User);
                 my ($site) = $dbc->Table_find_array( 'Printer_Group,Site', [ 'Site_ID', 'Site_Name' ], "WHERE FK_Site__ID=Site_ID AND Printer_Group_Name = '$printer_group'" );
                my ( $site_id, $site_name ) = split ',', $site;
                $dbc->config('site_id', $site_id);
                $dbc->config('site_name', $site_name);
            }
            ## cannot generate home page yet because user is not defined ... ##
    }
    elsif ( $result eq 'wrong password' ) {
        $self->{failed} = 1;

        print $BS->error("Invalid username and password combination");
        $page .= $view->display_Login_page( -dbc => $dbc );
    }
    elsif ( $result eq 'wrong user' ) {
        $self->{failed} = 1;
        print $BS->error("Invalid username and password combination");
        $page .= $view->display_Login_page( -dbc => $dbc );
    }
    elsif ( $result eq 'change password' ) {
        $page .= $BS->message( $view->validate_password_message() );
        $page .= $view->display_change_password_page( -dbc => $dbc, -user => $user );
    }
    elsif ( $result eq 'No printer group' ) {
        $page .= $BS->warning('No printer group selected!');

        $self->{failed} = 1;
        $page .= $view->display_Login_page( -dbc => $dbc );
    }
    else {
        $page .= $BS->warning("Unidentified login result ($result)");
        $page .= $view->display_Login_page( -dbc => $dbc );
    }
    return $page;
}

1;
