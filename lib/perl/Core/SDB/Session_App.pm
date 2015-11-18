###############################################################################################################
# 				Session_App.pm
###############################################################################################################
#
#	This module is used to monitor Session objects.
#
#	It allows user to access different sessions and view them
#
#	Written by: 	Ash Shafiei
#	Date:			June 2008
###############################################################################################################
package SDB::Session_App;

use base LampLite::Session_App;

use strict;
##############################
# standard_modules_ref       #
##############################
use DBI;
use Data::Dumper;
use Storable;
use MIME::Base32;
use Carp;
use Time::localtime;

############################
## Local modules required ##
############################

use RGTools::RGIO;
use RGTools::Views;
use RGTools::Object;

use SDB::DBIO;
use SDB::HTML;

use SDB::CustomSettings;
use SDB::Session;
use SDB::Session_Views;

use alDente::Web;

##############################
# global_vars                #
##############################
use vars qw(%Configs $Sess);    #

##############################
# Dependent on methods:
#
# Session::get_sessions  (retrieve list of sessions given user, date, string)
# Session::open_session
##############################
sub setup {
##############################
    my $self = shift;

    $self->start_mode('search_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'                 => 'search_page',
            'search_page'             => 'search_page',
            'display_Session_details' => 'display_Session_details',
            'display_Sessions_List'   => 'display_Sessions_List',
            'Search'                  => 'display_Sessions_List',
            'Show Printers'           => 'show_Printers',
            'Enable Tooltips'         => 'set_Tooltips',
            'Disable Tooltips'        => 'set_Tooltips',
        }
    );

    my $dbc = $self->param('dbc');
    my $q   = $self->query();
    $self->{dbc} = $dbc;

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

sub save_new_password {
    my $self = shift;

    return $self->SUPER::save_new_password();
}

##############################
sub search_page {
############################
    #	Decription:
    # 		- This subroutine is where the user will search for Sessions
    #		- The view for this will show up under Site Adminstrative home page
    #	Input:
    #		- None
    #		- Note:  Input will be prompted from the user with buttons and ...
    #	output:
    #		- Layer: it's a layer of a page (Named 'Users') that will be used in Site_Admin_Department.pm
    # <snip>
    # Usage Example:
    #     my $form = search_page();
    # </snip>
############################
    my $self = shift;
    my $dbc  = $self->dbc();    # || SDB::Errors::log_deprecated_usage("Connection",$Connection);
    my $page;
    my %layers;

    $layers{'alDente'} = $self->View->search_page( -dbc => $dbc );
    $layers{'Public'} = $self->View->search_page( -dbc => $dbc, -public => 1 );
    $page .= &define_Layers(
        -layers    => \%layers,
        -format    => 'tab',
        -tab_width => 100,
        -default   => 'alDente'
    );

    return $page;
}

##############################
sub display_Session_details {
##############################
    #	Description:
    #		- This function is used to display thge details of a session
    #	Input:
    #		- Typically nothing, but can take arguments if called from outside
    #	Output:
    #		- Page: it's a form to be printed in the main program
    # <snip>
    # Usage Example:
    #		no usage get called from run mode
    # </snip>
##############################

    my $form;
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $q      = $self->query();
    my $sid    = $q->param('Session_ID') || $q->param('Session ID');
    my $s_file = $q->param('Session_File_Name');
    my $search = $q->param('Keyword');                                 ### search string (optional) to highlight
    my $PID    = $q->param('PID');
    my $dir    = $q->param('directory') || $q->param('file path');

    my $file_path    = $q->param('file path') . '/';
    my $full_session = $q->param('Full_Session');

    my $source_path = $q->param('source') || 'direct';                 ### to know which function calls this to better analyze the filename

    return $self->View->display_Session_details( -Session => $self->Model, -session_id => $sid, -session_file => $s_file, -search => $search, -PID => $PID, -dir => $dir, -path => $file_path, -full_session => $full_session, -source => $source_path );
}

##############################
sub display_Sessions_List {
##############################
    #	Description:
    # 		- This function will display the list of Sessions with name of their ID which is bases on
    #			their start time and a code assigned to their user. Sessions will be displayed as buttons. (With Minimal detail)
    #	Input:
    #		- A reference to An Array Containing the Session File Names (which itseld contains
    #				info such as path, user code, timestamp,size)
    #	Output:
    #		- Form: It's a form to be printed in he main program
    #
    # <snip>
    # Usage Example:
    #		no usage get called from run mode
    # </snip>
    #		my $sess_obj = SDB::Session->new();
    #		my @sessions = $sess_obj->get_sessions(user=>$sessionUser,day=>$sessionDay, keyword => 'appi', margin=> 3);
    #
##############################
    my $self = shift;
    my $q    = $self->query;
    my %args = &filter_input( \@_ );
    my $dbc  = $self->param('dbc') || $args{-dbc};

    my $user         = $args{-user}         || $q->param('FK_Employee__ID Choice') || $q->param('FK_Employee__ID');
    my $day          = $args{-day}          || $q->param('Week_Day');
    my $string       = $args{-keyword}      || $q->param('Keyword');
    my $margin       = $args{-margin}       || $q->param('Line_Margin');
    my $year         = $args{-year}         || $q->param('year');
    my $month        = $args{-month}        || $q->param('month');
    my $date         = $args{-date}         || $q->param('date');
    my $searchmode   = $args{-searchmode}   || $q->param('search mode') || 'regular';
    my $contact      = $args{-contact_id}   || $q->param('FK_Contact__ID Choice') || $q->param('FK_Contact__ID');
    my $code_version = $args{-code_version} || $q->param('code_version');
    my $dbase_choice = $args{-dbase_choice} || $q->param('dbase_choice');
    my $host_choice  = $args{-host_choice}  || $q->param('host_choice');
    my $public       = $args{-public}       || $q->param('public');

    #my $sess_obj = SDB::Session->new();
    my $sess_obj = $self->Model;
    my @sessions;
    my $user_id = $dbc->get_FK_ID( 'FK_Employee__ID', $user );

    my $message = 'Searching for sessions with specifications: <BR>';
    $message .= "* Contact: $contact <BR>" if $contact;
    $message .= "* User: $user_id  <BR>"   if $user_id;
    $message .= "* Day: $day  <BR>"        if $day;
    $message .= "* Keyword: $string  <BR>" if $string;

    $dbc->message($message);

    @sessions = $sess_obj->get_sessions(
        -dbc          => $dbc,
        -user         => $user_id,
        -keyword      => $string,
        -margin       => $margin,
        -day          => $day,
        -year         => $year,
        -month        => $month,
        -date         => $date,
        -public       => $public,
        -searchmode   => $searchmode,
        -contact      => $contact,
        -code_version => $code_version,
        -dbase_choice => $dbase_choice,
        -host_choice  => $host_choice,
    );

    my $number_of_sessions = @sessions;
    $dbc->message("Possible sessions matching all details: ($number_of_sessions)");

    my $form            = section_heading("Sessions");
    my $session_counter = 0;

    foreach my $this_session (@sessions) {

        unless ($this_session) {next}
        $session_counter++;

        $form .= alDente::Form::start_alDente_form( $dbc, "Matched Result $session_counter" );

        $form .= $q->hidden(
            -name  => 'cgi_application',
            -value => 'SDB::Session_App',
            -force => 1
        );

        $form .= $q->hidden( -name => 'rm', -value => 'display_Session_details', -force => 1 );
        $form .= $q->hidden( -name => 'source', -value => 'list', -force => 1 );

        my %info = %{$this_session};
        $form .= $q->hr();

        if ($string) {
            $form .= "Found '$string'" . vspace();
            $form .= "<span class=small>";
            my $found_text_ref = $info{-text};
            my @found_text     = @$found_text_ref;
            foreach my $line (@found_text) {
                if ( $line =~ /$string/ ) {
                    $line =~ s/$string/<Font color=red>$string<\/Font>/g;
                    $form .= $line . vspace(0.5);
                }
                else { $form .= $line . vspace(0.5) }
            }
            $form .= "</span>";
        }

        my $button_class;
        my $temp1         = $info{-timestamp};
        my $dir           = $info{-directory};
        my $filename      = $info{-sfile};
        my $error_command = "grep \"Error Notes=\" /$dir/$filename.sess";
        my $action        = try_system_command($error_command);
        if   ($action) { $button_class = 'Action' }
        else           { $button_class = 'Std' }

        $form .= $q->hidden( -name => 'file path', -value => "$dir", -force => 1 );
        $form .= $info{-user} 
            . hspace(5)
            . $q->submit(
            -name  => 'Session ID',
            -value => "$filename",
            -class => $button_class,
            -force => 1
            )
            . hspace(5)
            . $info{-size} . "k"
            . vspace()
            . vspace();
        $form .= $q->end_form();
    }

    $form .= '..ok.';
    return $form;

}

#######################
sub attempt_Login {
#######################
    my $self       = shift;
    my $q          = $self->query();
    my $dbc        = $self->param('dbc');
    my $username   = $q->param('Username') || $q->param('User List');
    my $dbase      = $q->param('Database');
    my $password   = $q->param('Pwd');
    my $department = $q->param('Department') || $q->param('Target_Department') || $Current_Department;

    ( my $sessionUser ) = $q->param('Session User');
    ( my $sessionDay )  = $q->param('Session Day');
    ( my $sessionID )   = $q->param('Session ID') || '';
    ( my $string )      = $q->param('Session String');
    ( my $margin )      = $q->param('Session Margin') || 1;

    my @cgi_apps = $q->param('cgi_application');
    my @rms      = $q->param('rm');

    my $archive       = $q->param('Session Archive');
    my $PID           = $q->param('PID');
    my $retrieve      = $q->param('Retrieve Session');
    my $expired_login = $q->param('Expired Login');

    if ($retrieve) {
        my $ok = $self->View->view_sessions( user => $sessionUser, day => $sessionDay, session => $sessionID, margin => $margin, string => $string, archive => $archive, PID => $PID );
        return $ok;
    }
    else {
        my $page;
        if ($expired_login) {
            eval "require alDente::Form";
            my $reload_button = alDente::Form::start_alDente_form( $dbc, 'reload' );
            $reload_button .= SDB::Session::reload_input_parameters( -clear => 'cgi_application=SDB::Session_App,rm=Log In' );
            $reload_button .= $q->submit( -name => 'Re-Submit Pre-Login Request', -class => 'Action' );
            $reload_button .= $q->end_form();
            $page .= $reload_button . '<HR>';
        }
        $page .= &alDente::Web::GoHome( -dbc => $dbc, -dept => $department, -quiet => 1 );    #-open_layer => $open_tab,
        return $page;
    }
}

######################
sub set_Tooltips {
######################
    my $self   = shift;
    my $q      = $self->query();
    my $dbc    = $self->param('dbc');
    my $action = $q->param('rm');
    my $Emp    = new alDente::Employee( -id => $dbc->get_local('user_id'), -dbc => $dbc );

    if ( $action =~ /enable/i ) {
        $dbc->message("Tooltips Enabled");
        $Emp->save_Setting( -setting => 'DISABLE_TOOLTIPS', -value => 'OFF', -scope => 'Employee' );
        $ENV{DISABLE_TOOLTIPS} = 0;
    }
    elsif ( $action =~ /Disable/i ) {
        $dbc->message("Tooltips Disabled");
        $Emp->save_Setting( -setting => 'DISABLE_TOOLTIPS', -value => 'ON', -scope => 'Employee' );
        $ENV{DISABLE_TOOLTIPS} = 1;
    }

    return $self->View->display_Preferences( -dbc => $dbc );
}

######################
sub display_Preferences {
######################
    my $self = shift;

    my $dbc = $self->param('dbc');

    return $self->View->display_Preferences( -dbc => $dbc );
}

######################
sub show_Printers {
######################
    my $self = shift;

    my $dbc = $self->param('dbc');

    use alDente::Barcoding;
    return alDente::Barcoding::show_printer_groups($dbc);
}

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

$Id: Session.pm,v 1.38 2004/11/30 01:43:50 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
