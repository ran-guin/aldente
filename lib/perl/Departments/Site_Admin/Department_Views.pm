package Site_Admin::Department_Views;

use base Main::Department_Views;

use strict;
use warnings;

use Data::Dumper;

use Site_Admin::Department;

use RGTools::RGIO;
use LampLite::HTML;
use SDB::HTML;
use LampLite::Bootstrap;
use LampLite::CGI;

my $q = new LampLite::CGI;
my $BS = new Bootstrap;

## Specify the icons that you want to appear in the top bar

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self = shift;
    my %args = filter_input( \@_);
    my $dbc = $args{-dbc} || $self->dbc;
    
    my $homelink = $dbc->homelink();

    ### Permissions ###
    my $access = $dbc->get_local('Access');
    my %Access = %{ $access } if $access;
    #This user does not have any permissions for this dept
    if ( $access && !$Access{'Site Admin'} ) {
        return;
    }

    my $page;

#     $self->set_links($dbc);

    my $Access = new LampLite::DB_Access(-dbc=>$dbc);

    #<CONSTRUCTION> fix up this page at some point, looks ugly!
    $page .= page_heading("Site Administration Home Page");

    my $access = $Access->View->display_DB_Access(); ## why doesn't this work !!  <CONSTRUCTION>
    
    my @layers;
    push @layers, { label=>'Database', content=> $self->manage_Database() };

    push @layers, { label=> 'Groups', content => $self->manage_Grps() . '<hr>' . $access };

    push @layers, { label=> 'Code Upgrade Releases', content => $self->code_Releases() };

    push @layers, { label=> 'Use Cases', content => $self->use_Cases() };
   
    push @layers, { label=> 'Encryption', content => $self->encryption() };

    push @layers, { label=> 'Email', content => $self->email() };

    $page .= $BS->layer( -layers => \@layers, -default => 'Database', -format => 'tab', -tab_width => 100 );

    return $page;
}

#######################
sub manage_Database {
#######################
    my $self = shift;
    my $dbc = $self->dbc();

    my %labels = ( '-' => '--Select--' );
    $labels{'Edit+Table'} = 'Edit';
    $labels{'Search+for'} = 'Search';

    my $Form = new LampLite::Form(-dbc=>$dbc);

    my $include = $q->hidden(-name=>'cgi_app', -value=>'LampLite::DB_App', -force=>1);
    
    $Form->append( 
       'Records: ',
        $BS->dropdown( -name => 'Table', -values => [ '-- Select --', $dbc->tables() ], -force => 1, -placeholder=>'Pick Table' ),    
    );

    $Form->append('', $q->submit( -name => 'rm', -value => 'Add Record', -class => "Std" ) . ' x ' . $q->textfield(-name=>'Records', -class=>'narrow-txt', -default=>1) );
    $Form->append('', $q->submit( -name => 'rm', -value => 'Edit Record', -class => "Std" ) );
    $Form->append('', $q->submit( -name => 'rm', -value => 'Search Records', -class => "Std" ) );
    $Form->append('', $q->submit( -name => 'rm', -value => 'List Records', -class => "Std" ) );
    
    my $lims_column = section_heading("Site Maintenance");
    $lims_column .= $Form->generate(-wrap=>1, -include=>$include);
    
    $lims_column .= subsection_heading( "Process Management");
    $lims_column .= "PID:" 
        . hspace(1) 
        . $q->textfield( -name => "PID" ) 
        . hspace(1) 
        . $q->submit( -name => 'Kill Process', -class => "Action" );
    
    $lims_column .= subsection_heading( "Generate Query View");
    $lims_column .= $q->submit( -name => "Generate View", -value => 'Generate View', -class => 'Std' );

    my $block = LampLite::Form->start_Form($dbc) . $lims_column . $q->end_form(); ## alDente::Form::start_alDente_form(-dbc=>$dbc, -name =>'database') . $lims_column . end_form();

    return $block;
}

###################
sub manage_Grps {
###################
    my $self = shift;
    my $dbc = $self->dbc();
    
    my $lims_column = section_heading( "Set Employee Group Membership");
    
#    my $User = $dbc->config('User');
    my ($grp_jt, $ref) = LampLite::User->group_join_table(-table => $dbc->config('login_type') );
    
    my $Form = new LampLite::Form(-dbc=>$dbc);
    my ($prompt, $element) = $Form->View->prompt(-dbc=>$dbc, -table=>$grp_jt, -field => $ref, -name=>'ID');
    
    $lims_column .=  $element
        . $q->hidden(-name=>'HomePage', -value=>'Employee', -force=>1)
        . $q->submit( -name => 'Go to Employee Home Page', -class => "Std" );

    my $block = LampLite::Form->start_Form($dbc) . $lims_column . $q->end_form(); ## alDente::Form::start_alDente_form(-dbc=>$dbc, -name =>'database') . $lims_column . end_form();
    return $block;
}

######################
sub show_DBaccess {
######################
    my $self = shift;
    my %args = filter_input(\@_);
    my $user = $args{-db_user};
    
    my $dbc = $self->dbc();
    
    my $overview = section_heading( "Manage Database Access");
    
    my $left_joins = "LEFT JOIN Access_Inclusion ON Access_Inclusion.FK_DB_Access__ID=DB_Access_ID LEFT JOIN Access_Exclusion ON Access_Exclusion.FK_DB_Access__ID=DB_Access_ID";
    $left_joins .= " LEFT JOIN DBTable as Include_Tables ON Include_Tables.DBTable_ID=Access_Inclusion.FK_DBTable__ID AND Access_Inclusion.FK_DBField__ID IS NULL";
    $left_joins .= " LEFT JOIN DBField as Include_Fields ON Include_Fields.DBField_ID=Access_Inclusion.FK_DBField__ID";
    $left_joins .= " LEFT JOIN DBTable as Exclude_Tables ON Exclude_Tables.DBTable_ID=Access_Exclusion.FK_DBTable__ID AND Access_Exclusion.FK_DBField__ID IS NULL";
    $left_joins .= " LEFT JOIN DBField as Exclude_Fields ON Exclude_Fields.DBField_ID=Access_Exclusion.FK_DBField__ID";

    my @add_fields = ("Group_Concat(Distinct Include_Tables.DBTable_Name) AS Include_Tables", "Group_Concat(Distinct Exclude_Tables.DBTable_Name) AS Exclude_Tables");
    push @add_fields, ("Group_Concat(Distinct Include_Fields.Field_Name) AS Include_Fields", "Group_Concat(Distinct Exclude_Fields.Field_Name) AS Exclude_Fields");
    
    my $condition = "WHERE FKProduction_DB_Access__ID=DB_Access_ID";
    if ($user) { $condition .= " AND DB_User = '$user'" }
    
    $overview .= $dbc->Table_retrieve_display(
        "DB_Access, DB_Login LEFT JOIN Grp ON Grp.FK_DB_Login__ID=DB_Login_ID $left_joins", 
        ['DB_User', 'DB_Access_Title', "Group_Concat(Distinct Grp_Name) as Grps", "Read_Access", 'Write_Access','Delete_Access', @add_fields],
        $condition,
        -group=>'DB_Login_ID',
        -order=>'DB_Access_ID,Grp_Name',
        -highlight_cell => { 'N' => 'lightredbw', 'Y' => 'lightgreenbw', 'R' => 'lightorangebw' },
        -toggle_on_column => 'DB_Access_Title',
        -link_parameters => {"DB_User" => "&cgi_app=Site_Admin::Department_App&rm=Edit Access&DB_User=<DB_User>"},
        -debug=>0,
        -return_html=>1,
    );

    return $overview;
}

#####################
sub edit_DBaccess {
#####################
    my $self = shift;

    my $form = new LampLite::Form();
    
    $form->append('Specify Inclusions:', $q->textfield(-name=>'Inclusions', -class=>'form-control'));
    $form->append('Specify Exclusions:', $q->textfield(-name=>'Inclusions', -class=>'form-control'));
    
    $form->append('', $q->submit(-name=>'Update Access', -class=>'Action') );
    my $hidden = $q->hidden(-name=>'cgi_app', -value=>'Site_Admin::Department_App', -force=>1) . $q->hidden(-name=>'rm', -value=>'Update Access', -force=>1);
    
    return $form->generate(-wrap=>1, -include=>$hidden );    
}

#####################
sub update_DBaccess {
#####################
    my $self = shift;
    
    return 'update as required.... ';
}

#######################
sub code_Releases {
#######################
    my $self = shift;
    my $dbc = $self->dbc();
    
    my $block = LampLite::Form->start_Form($dbc) ## alDente::Form::start_alDente_form(-dbc=>$dbc, -name=>'code') 
        . $q->hidden( -name => 'cgi_application', -value => 'SDB::SVN_App', -force => 1 ) 
        . $q->submit( -name => 'rm', -value => 'Show Tags', -class => 'Search', -force => 1 ) 
        . $q->end_form();
    
    return $block;
}

sub use_Cases {
#######################
    my $self = shift;
    my $dbc = $self->dbc();

    my $block;
    if ( $dbc->addons('Help') ) {
        my $db_column .= subsection_heading( "Use Cases");

        # get root use case names
        my @usecase_choices = $dbc->Table_find( 'UseCase', 'UseCase_Name', "WHERE FKParent_UseCase__ID IS NULL or FKParent_UseCase__ID =0" );
        unshift( @usecase_choices, '-' );

        # give user a list of use cases to select for editing
        $db_column .= "Available Use Cases: " 
        . $q->popup_menu( -name => 'UseCase Name', -values => \@usecase_choices, -force => 1 ) 
        . $q->submit( -name              => "View UseCase", -value => 'View Selected Use Case', -class => "Search" ) 
        . "<BR><BR>"
        . $q->submit( -name              => "UseCase Home", -value => 'View all Use Cases',     -class => "Search" )
        . &hspace(5) 
        . $q->submit( -name => "Add UseCase",  -value => 'Add New Use Case',       -class => "Std" ) 
        . &hspace(1);

        $block = LampLite::Form->start_Form($dbc, 'use_cases') . $db_column . $q->end_form();
    }
    return $block;
}

sub encryption {
#######################
    my $self = shift;
    my $dbc = $self->dbc();

    my $this_layer = subsection_heading( "Encryption");
    
    $this_layer .= 'Decode: '
    . $q->hidden(-name=>'cgi_app', -value=>'Site_Admin::Department_App', -force=>1)
    . $q->textfield( -name => 'String', -size => 140 )
    . $q->submit( -name => 'rm', -label => 'Decode Base 32', -class => "Std" )
    . $q->checkbox( -name => 'Thaw') . ' (YAML Thaw first)'
    . '<P></P>'
    . $q->submit( -name => 'rm', -label => 'Encode Base 32', -class => "Std" )
    . $q->checkbox( -name => 'Freeze') . ' (and YAML Freeze)'
    . "</p><p ></p>";

    return LampLite::Form->start_Form($dbc, 'encryption') . $this_layer . $q->end_form();
}

sub email {
#######################
    my $self = shift;
    my $dbc = $self->dbc();

    my $email_table = new HTML_Table( -title => 'Emailing System', -toggle => 0 );

    my @depts = $dbc->Table_find( 'Department', 'Department_Name' );
    my @access = $dbc->Table_find( 'Grp', 'Access', -distinct => 1 );

    $email_table->Set_Row(
        [   'To:',
        $q->scrolling_list( -name => 'email_depts', -values => \@depts, -size  => 4, -multiple => 1 ) 
        . $q->scrolling_list( -name => 'email_access', -values => \@access, -size => 4, -multiple => 1 ),

        $q->submit( -name         => 'SendEmail',   -label  => 'Send',  -class => 'Action' )
        ]
    );

    $email_table->Set_Row( [ "From:", $q->textfield( -name => 'email_from', -value => $dbc->get_local('user_name') ) ] );
    $email_table->Set_Row( [ "Cc  :", $q->textfield( -name => 'email_cc',   -value => 'aldente@bcgsc.ca' ) ] );
    $email_table->Set_Row( [ "Subject:", $q->textfield( -name => 'email_subject' ) ] );
    $email_table->Set_Row( [ "Body:", $q->textarea( -name => 'email_body', -rows => 10, -cols => 60 ) ] );

    my $block = LampLite::Form->start_Form($dbc, 'encryption'). $email_table->Printout(0) . $q->end_form();

    return $block;
}

sub conversion {
#######################
    my $self = shift;
    my $dbc = $self->dbc();
    
    my @deltrs = ( 'Tab', 'Comma' );
    my $deltr_btns = $q->radio_group( -name => 'Delimiter', -values => \@deltrs, -default => 'Tab', -force => 1 );
    
    my $upload_file = new HTML_Table( -title => 'Upload data', -toggle => 0, -width => '400' );
    $upload_file->Set_Row( [ "Delimited input file:", $q->filefield( -name => 'input_file_name', -size => 30, -maxlength => 200 ) ] );
    $upload_file->Set_Row( [ "Delimeter:", $deltr_btns ] );
    $upload_file->Set_Row( [ $q->submit( -name => 'rm', -label => 'Upload', -class => 'Std' ) . $q->hidden( -name => 'cgi_application', -value => 'SDB::Import_App' ) ] );

    my $block = LampLite::Form->start_Form($dbc, 'uploader') . $upload_file->Printout(0) . end_form();
    
    return $block;
}

return 1;
