############################
# alDente::Employee_App.pm #
############################
#
# This module is used to monitor Goals for Library and Project objects.
#
package alDente::Employee_App;
use base alDente::CGI_App;
use strict;

## Local modules required ##

use RGTools::RGIO;
use RGTools::RGmath;

use SDB::DBIO;
use SDB::HTML;

use alDente::Employee;
use alDente::Employee_Views;
use alDente::Tools;

## global_vars ##
use vars qw(%Configs);

my $q;
my $dbc;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'             => 'entry_page',
            'Home'                => 'home_page',
            'List'                => 'list_page',
            'Main'                => 'main_page',
            'Establish Groups'    => 'establish_Groups',
            'Set Employee Groups' => 'set_Employee_Groups',
            'Generate Login Barcode' => 'generate_Login_Barcode',
            'Login Under Another Username' => 'reset_Session',
        }
    );

    $dbc = $self->param('dbc');
    $q   = $self->query();

    my $id            = $q->param("Employee_ID");                                               ### Load Object by default if standard _ID field supplied.
    my $Employee      = new alDente::Employee( -dbc => $dbc, -id => $id );
    my $Employee_View = new alDente::Employee_Views( -model => { 'Employee' => $Employee } );

    $self->param( 'Employee'      => $Employee );
    $self->param( 'Employee_View' => $Employee_View );
    $self->param( 'dbc'           => $dbc );

    my $return_only = $q->param('CGI_APP_RETURN_ONLY');
    if ( !defined $return_only ) { $return_only = 0 }

    $ENV{CGI_APP_RETURN_ONLY} = $return_only;
    return $self;
}

##############################
sub generate_Login_Barcode {
##############################
    my $self = shift;
    
    return 'build barcode for auto loggin in =  alt-up ...tab ... username ... tab ... pwd ... enter';
}

###########################
sub entry_page {
###########################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $id   = $q->param('ID');

    unless ($id) { return $self->main_Page( -dbc => $dbc ) }
    if ( $id =~ /,/ ) { return $self->list_page( -dbc => $dbc, -list => $id ) }
    else              { return $self->home_page( -dbc => $dbc, -id => $id ) }
    return 'Error: Inform LIMS';
}

###########################
sub home_page {
###########################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $id   = $q->param('id') || $args{-id};
    return $self->param('Employee')->home_page( -dbc => $dbc, -user_id => $id );
}

###########################
sub list_page {
###########################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $list = $q->param('list') || $args{-list};
    my $view = $dbc->Table_retrieve_display(
        -table       => "Employee",
        -fields      => [ 'Employee_ID', 'Employee_Name', 'Initials', 'Email_Address', 'Employee_Status', 'FK_Department__ID' ],
        -condition   => "WHERE Employee_ID IN ($list)",
        -return_html => 1,
    );
    return $view;
}

###############
sub main_Page {
###############
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $page = $self->param('Employee_View')->display_employee_requests( -dbc => $dbc );
    $page .= $self->param('Employee_View')->set_Employee_Groups( -dbc => $dbc );

    $page .= '<hr>';
    if ( $dbc->admin_access() ) {
        $page .= alDente::Form::start_alDente_form( $dbc, 'reset_session' );
        $page .= alDente::Tools::search_list( -dbc => $dbc, -field=>'FK_Employee__ID', -element_name=>'User', -search => 1, -filter => 1 );
        $page .= $q->submit( -name => 'rm', -value => 'Login Under Another Username', -class => 'Action', -force=>1);
        $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Employee_App', -class => 'Action', -force=>1);
    }

    return $page;
}

#####################
sub reset_Session {
#####################
    my $self = shift;
    my $dbc = $self->dbc;
    
    my $default_user =  $q->param('User') || $q->param('User Choice');  
    
    if ($default_user) { 
        my $default_user_id = $dbc->get_FK_ID('FK_Employee__ID',  $default_user);
        ($default_user) = $dbc->Table_find('Employee', 'Employee_Name', "WHERE Employee_ID = $default_user_id");
    }
     
    return main::_relogin($dbc, -user=>$default_user); 
}

###############
sub establish_Groups {
###############
    my $self     = shift;
    my $dbc      = $self->param('dbc');

    my $employee = $q->param('Employee_Name') || $dbc->get_Table_Param(-table=>'Employee', -field=>'FK_Employee__ID');
    my $page     = $self->param('Employee_View')->display_Group_Selection( -dbc => $dbc, -employee => $employee );
    return $page;
}

###############
sub set_Employee_Groups {
###############
    my $self          = shift;
    my $dbc           = $self->param('dbc');
    my $emp_id        = $q->param('Employee_ID');
    my @grp_array     = $q->param('Add_Group_List');
    my @curent_groups = $self->param('Employee')->groups( -dbc => $dbc, -employee => $emp_id );
    my @access_groups = split ',', $q->param('access_groups');
    my @select_groups;

    foreach my $id (@grp_array) {
        push( @select_groups, get_FK_ID( $dbc, "FK_Grp__ID", $id ) );
    }
    ## ADD = SELECT - CURRENT
    my @add_groups = RGmath::minus( \@select_groups, \@curent_groups );
    my $add = join ',', @add_groups;

    ## DELETE = COMMON (CURRENT , (ACCESS  - SELECTED))
    my @temp = RGmath::minus( \@access_groups, \@select_groups );
    my ($delete_groups) = RGmath::intersection( \@curent_groups, \@temp );
    my @delete_groups = @$delete_groups if $delete_groups;
    my $delete = join ',', @delete_groups;

    $self->param('Employee')->join_Grp( -grp => $add, -dbc => $dbc, -employee => $emp_id,, -no_triggers => 1 ) if $add;
    $self->param('Employee')->leave_Grp( -grp => $delete, -dbc => $dbc, -employee => $emp_id ) if $delete;

    return;

}

return 1;
