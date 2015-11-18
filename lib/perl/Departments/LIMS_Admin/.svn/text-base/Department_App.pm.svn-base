##################
# Department_App.pm #
##################
#
# This module is a template App for a specific Department, one will want to customize it according to the needs of the department
#
package LIMS_Admin::Department_App;

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

use base Main::Department_App;

use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;

use SDB::HTML;    ##  qw(hspace vspace get_Table_param HTML_Dump display_date_field set_validator);
use SDB::DBIO;
use SDB::CustomSettings;

use alDente::Form;
use alDente::Container;
use alDente::Rack;
use alDente::Validation;
use alDente::Tools;
use alDente::Source;

#use LIMS_Admin::Department;
#use LIMS_Admin::Department_Views;

use LIMS_Admin::Department;
use LIMS_Admin::Department_Views;

##############################
# global_vars                #
##############################
use vars qw(%Configs  $URL_temp_dir $html_header $debug);    # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

my $q;
my $dbc;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Home Page' => 'home_page',
        'Help'      => 'help',
        'Summary'   => 'summary',
        'Database'  => 'display_Database',
        'Decode Base 32' => 'decode_base32',
        'Encode Base 32' => 'encode_base32',
        'Set User Groups' => 'set_Groups',
        'Edit Access' => 'edit_Access',
        'Update Access' => 'update_Access',

    );

    $dbc = $self->param('dbc');
    $q   = $self->query();

    $self->update_session_info();
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

###############
sub summary {
###############
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $since     = $q->param('from_date_range');
    my $until     = $q->param('to_date_range');
    my $debug     = $q->param('Debug');
    my $condition = $q->param('Condition') || 1;

    my $page = "summary";
    return $page;
}

# Also, displays some basic statistics relevant to each of the run modes
##################
sub home_page {
##################
    my $self = shift;
    print "GOHOME";
    return $self->View->home_page( -dbc => $dbc );
}

##################
sub display_Database {
##################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    ### Permissions ###
    my %Access = %{ $dbc->get_local('Access') };

    my ( $search_ref, $creates_ref, $conversion_ref, $custom ) = alDente::Department::get_searches_and_creates( -access => \%Access );
    my @searches    = @$search_ref;
    my @creates     = @$creates_ref;
    my @conversions = @$conversion_ref;

    my $search_create_box = alDente::Department::search_create_box( $dbc, -search => \@searches, -create => \@creates, -convert => \@conversions, -custom_search => $custom );
}

####################
sub decode_base32 {
####################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $string = $q->param('String');
    my $thaw   = $q->param('Thaw');
    
    my $decoded = $self->Model->decode_base32($string, -thaw=>$thaw);
    
    $dbc->message("Decoded: $string\n\n$decoded");
    return;
}

####################
sub encode_base32 {
####################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $string = $q->param('String');
    my $freeze   = $q->param('Freeze');
    my $encoded = $self->Model->encode_base32($string, -freeze=>$freeze);
    
    $dbc->message("Encoded: $string\n\n$encoded");

    return;
}

###########
sub help {
############
    my $page;

    return $page;
}

##################
sub set_Groups {
##################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $user_id = $q->param('Employee_ID') || $q->param('User_ID');;
  
    eval "require alDente::DB_Object_Views";
    my $User = new LampLite::User(-dbc=>$dbc);
    
    my ($grp_jt, $ref) = $User->group_join_table();
    
    my $DB = new LampLite::DB_Views(-dbc=>$dbc);
    return $DB->join_records( -defined => $ref, -id => $user_id, -join => 'FK_Grp__ID', -join_table => $grp_jt, -filter => "Grp_Status = 'Active'", -title => 'Group Membership' ) 
}

##################
sub edit_Access {
##################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();
    
    my $user = $q->param('DB_User');
    my $page = $self->View->show_DBaccess(-db_user=>$user);
    
    if ($user) {
        $page .= '<HR>';
        $page .= $self->View->edit_DBaccess();
    }
    
    return $page;
}

#################
sub update_Access {
##################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    return 'updated...';
}

return 1;
