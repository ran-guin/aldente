###################################################################################################################################
# alDente::Session_Views.pm
#
# Interface generating methods for the Session MVC  (associated with Session.pm, Session_App.pm)
#
###################################################################################################################################
package SDB::Session_Views;
use base LampLite::Session_Views;
use strict;

## Standard modules ##
use CGI qw(:standard);
use Time::localtime;

## Local modules ##

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules
use alDente::Form;
use alDente::Tools;
use alDente::SDB_Defaults;
use alDente::Barcode_Views;

use vars qw( %Configs );
my $q = new CGI;

############
sub Model {
############
    my $self = shift;
    my $dbc  = $self->{dbc};

    return $dbc->session();
}

##############################
sub display_Preferences {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $page;
    require alDente::Form;
    my $tooltip_block = alDente::Form::start_alDente_form( -dbc => $dbc, -form => 'NEW' );
    if ( $ENV{DISABLE_TOOLTIPS} ) {
        $tooltip_block .= $q->submit( -name => 'rm', -value => "Enable Tooltips", -class => "Std" );
    }
    else {
        $tooltip_block .= $q->submit( -name => 'rm', -value => "Disable Tooltips", -class => "Std" )

    }
    $tooltip_block .= $q->hidden( -name => 'cgi_application', -value => 'SDB::Session_App', -force => 1 ) . $q->end_form();
    my $block = alDente::Form::init_HTML_table( "Preferences", -margin => 'on' );
    $block->Set_Row( [ LampLite::Login_Views->icons( 'Preferences', -dbc => $dbc ), $tooltip_block ] );

    my $page = $block->Printout(0);
    return $page;
    return 'bam';

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
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $S_ID    = $args{-session_id};
    my $S_File  = $args{-session_file};
    my $Sstring = $args{-search};         ### search string (optional) to highlight
    my $PID     = $args{-PID};
    my $dir     = $args{-dir};

    my $file_path    = $args{-path};
    my $Sess_ID      = $S_ID;
    my $full_session = $args{-full_session};
    my $source_path  = $args{-source};         ### to know which function calls this to better analyze the filename
    my $sess_obj     = $args{-Session};

    my $dbc = $self->{dbc};

    my $session_file_name;

    # my $sess_obj = SDB::Session->new();
    my @session_file;

    if ($full_session) { $session_file_name = $full_session }
    elsif ( $source_path eq 'direct' ) {
        $S_File =~ s/\.sess//;
        $session_file_name = $S_File;
    }
    elsif ( $source_path eq 'list' ) {
        $session_file_name = $dir . '/' . $Sess_ID;
    }
    else { $session_file_name = $dir . '/' . $S_ID }

    my $form;

    # 	Creates the login header

    my %login_header = $sess_obj->get_session_login( -session => $session_file_name );
    if (%login_header) {
        $form
            .= section_heading( $login_header{-user} . "'s Session: [$session_file_name]" ) 
            . "User: "
            . $login_header{-user}
            . vspace(.5)
            . "Database: "
            . $login_header{-database} . " ("
            . $login_header{-login} . ")"
            . vspace(.5)
            . "Release: "
            . $login_header{-release} . " ("
            . $login_header{-URL_dir} . ")"
            . vspace(.5)
            . "Scanner mode: "
            . $login_header{-scanner_mode}
            . vspace(.5)
            . "</Font>";
        my $Sstring = $login_header{-string};
        if ($Sstring) { Message("(searching for $Sstring)") }

        #        $form .= $q->end_form();
    }
    else {
        $dbc->warning("Could not load Session: $session_file_name");
    }

    $form .= subsection_heading("Session Pages");
## creates the body of the session
    open( SESSION, "$session_file_name.sess" ) || $dbc->error("ERROR opening $session_file_name.sess");
    my $get_values = '';    ### parameter names...
    my $time;
    my $found_time = 0;
    my $i          = 0;

    my @ignore = ( 'Database_Mode', 'CGISESSID', 'Method', 'Name', 'Value' );
    my ( $messages, $warnings, $errors, $debug_messages );
    while (<SESSION>) {
        my $line = $_;

        ## highlight search word
        if ($Sstring) {
            $line =~ s/($Sstring)/<B><Font color=red>$1<\/Font><\/B>/ig;
        }
        elsif ( $line =~ /Error Notes/ ) { $line =~ s/Error\sNotes/<Font color=red>Error Notes<\/Font>/xms }

        ## generate HTML anchor at PID ##
        if ( $line =~ /^PID=/ ) {
            my $PID = <SESSION>;
            $PID =~ s/\s//g;
            $form .= "<A name=PID$PID></A>\n";
            $form .= "PID=$PID<BR>\n";
            next;
        }
        ##	Highlighting notes, errors and warnings
        if ( $line =~ /^(Messages:|\(no messages)/ ) {
            $messages++;
            $form .= "<Font color=blue>\n";
        }
        elsif ( $line =~ /^(Warnings:|\(no warnings)/ ) {
            $warnings++;
            $form .= "</Font>\n<Font color=orange>\n";
        }
        elsif ( $line =~ /^(Errors:|\(no errors)/ ) {
            $errors++;
            $form .= "</Font>\n<Font color=red>\n";
        }
        elsif ( $line =~ /^(Debug Messages:|\(no debug messages)/ ) {
            $debug_messages++;
            $form .= "</Font>\n<Font color=green>\n";
        }

        ##	Begining of each form with a timestamp button
        if ( $line =~ /^Time:(\d+)/ ) {
            if ( $errors || $warnings || $errors || $debug_messages ) {
                ( $messages, $warnings, $errors, $debug_messages ) = ( 0, 0, 0, 0 );
                $form .= "</Font>\n";
            }
            my $thistime = $1;
            my $real_time = &date_time( -time => $thistime );
            $form .= $q->hr();
            my $gohome = $SDB::CustomSettings::homefile;
            my %Parameters = $sess_obj->set_parameters( -no_database => 1 );
            shift @{ $Parameters{Name} };
            shift @{ $Parameters{Value} };

            $form .= alDente::Form::start_alDente_form( $dbc, "Sess$i", -clear => 1 );
            $form .= $q->hidden( -name => 'Retrieve Submission', -value => 1, -force => 1 );
            $form .= $q->submit(
                -name  => "$real_time",
                -style => "background-color:yellow",
                -force => 1
            ) . &hspace(20);
            $form .= $q->radio_group(
                -name   => 'Database_Mode',
                -values => [ 'PRODUCTION', 'TEST', 'DEV', 'BETA' ],
                -force  => 1
            );
            $form .= $q->br() . vspace();
            $i++;    ## Form $i
        }
        ##  End of each form realized by a line of '*' s
        if ( $line =~ /^\*{6}/ ) {
            $get_values = '';
            if ($i) { $form .= vspace() . $q->end_form() }
        }
        elsif ( $line =~ /^(.*?)=$/ ) {
            $get_values = $1;
        }
        ## get this from radio button..
        elsif ( grep /^$get_values$/, @ignore ) {
            $get_values = '';
        }
        ### special messages..
        elsif ( $line =~ /\*/ ) {
            $get_values = '';
            $form .= "$line<BR>\n";
        }
        elsif ( ($get_values) && ( $line =~ /\t(.*)/ ) ) {
            my $get_value = $1;

            #don't force session so can still use the current one
            $form .= $q->hidden( -name => $get_values, -value => $get_value, -force => 1 );

            if ($get_values) {
                $form .= "<span class=small><B>$get_values</B> = $get_value</span><BR>\n";
            }
        }
        elsif ($line) {
            $line =~ s/\n/<BR>/g;
            $form .= "<span class=small>$line</span>\n";
        }
    }
    close(SESSION);

    if ( $errors || $warnings || $errors || $debug_messages ) {
        ( $messages, $warnings, $errors, $debug_messages ) = ( 0, 0, 0, 0 );
        $form .= "</Font>\n";
    }

    return $form;
}

#############################################
#
# Standard view for single Session record
#
#
# Return: html page
###################
sub search_page {
###################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $public = $args{-public};

    my $page = $self->today_sessions( -dbc => $dbc, -public => $public );
    $page .= $self->week_sessions( -dbc => $dbc, -public => $public );
    $page .= $self->direct_session( -dbc => $dbc );
    $page .= $self->archive_sessions( -dbc => $dbc, -public => $public );

    return $page;
}

#############################################################
# Standard view for multiple Session records if applicable
#
#
# Return: html page
#################
sub list_page {
#################
    my $self = shift;
    my %args = filter_input( \@_, 'ids' );
    my $id   = $args{-id};

    my $Session = $self->param('Session');
    my $dbc     = $Session->param('dbc');

    my $page;

    return $page;
}

##############################
sub today_sessions {
############################
    #	Description:
    #		- This function creates a form, helping user select one of today's sessions
    #	Input:
    #		- No input
    #	Output:
    #		- Form
    # <snip>
    # Usage Example:
    #	my $page .= $self-> today_sessions ();
    # </snip>
############################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $dbc    = $args{-dbc} || $self->{dbc};
    my $public = $args{-public};

    my $form;
    my $date;
    my @todays_sessions;
    my @sessions = ();
    my %info;
    my $tm = localtime;
    my ( $day, $month, $year ) = ( $tm->mday, $tm->mon, $tm->year );    # note that month starts from 0 not 1
    $year += 1900;

    require SDB::Session;
    my $sess_obj = new SDB::Session( -dbc => $dbc );

    @todays_sessions = $sess_obj->get_sessions(
        -dbc        => $dbc,
        -year       => $year,
        -month      => $month,
        -date       => $day,
        -searchmode => 'today',
        -dir        => $Configs{session_dir},
        -public     => $public
    );

    foreach my $this_session (@todays_sessions) {
        %info = %{$this_session};
        my $user_id = $info{-user_id};
        push @sessions, $info{-directory} . '/' . $info{-sfile};    # . "  Size: " . $info { -size }. "k";
    }

    $form .= alDente::Form::start_alDente_form( $dbc, 'Today_Search' );
    $form .= section_heading("Today's Sessions");
    $form .= "Select a session from list: " . $q->popup_menu( -name => 'Full_Session', -value => [ '', @sessions ], -force => 1 ) . vspace();
    $form .= $q->hidden( -name => 'cgi_application', -value => 'SDB::Session_App',        -force => 1 );
    $form .= $q->hidden( -name => 'rm',              -value => "display_Session_details", -force => 1 );
    $form .= $q->hidden( -name => 'directory',       -value => $info{-directory},         -force => 1 );
    $form .= $q->hidden( -name => 'source',          -value => 'today',                   -force => 1 );
    $form .= $q->submit(
        -name  => 'Action',
        -value => "Display Session",
        -class => "Search",
        -force => 1
    );    ###paramateres should be fixed
    $form .= $q->end_form();

    return $form;
}

##############################
sub week_sessions {
############################
    #	Description:
    #		- This function creates a form, helping user select one of this weeks sessions
    #	Input:
    #		- No input
    #	Output:
    #		- Form
    # <snip>
    # Usage Example:
    #	my $page .= $self-> week_sessions ();
    # </snip>
###########################
    my $self = shift;
    my $form;
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $public = $args{-public};

    my @week_days = qw(Monday Tuesday Wednesday Thursday Friday Saturday Sunday);

    $form .= alDente::Form::start_alDente_form( $dbc, 'Week_Search' );
    $form .= section_heading("This Week's Sessions");
    if ($public) {
        $form .= "Contact: "
            . alDente::Tools::search_list(
            -name   => 'FK_Contact__ID',
            -dbc    => $dbc,
            -search => 1,
            -filter => 1
            ) . vspace();
        $form .= $q->hidden( -name => 'public', -value => '1', -force => 1 );
    }
    else {
        $form .= alDente::Tools::search_list(
            -name   => 'FK_Employee__ID',
            -dbc    => $dbc,
            -search => 1,
            -filter => 1
        ) . vspace();
    }

    $form .= "Day:  " . $q->popup_menu( -name => 'Week_Day', -value => [ '', @week_days ], -force => 1 ) . vspace();
    $form .= "Keyword: " . $q->textfield( -name => 'Keyword', -size => 20, -force => 1 ) . '  (showing ' . $q->textfield( -name => 'Line_Margin', -size => 3, -default => 3, -force => 1 ) . ' neighbouring lines)' . vspace();
    $form .= $q->hidden( -name => 'search mode',     -value => 'regular',               -force => 1 );
    $form .= $q->hidden( -name => 'cgi_application', -value => 'SDB::Session_App',      -force => 1 );
    $form .= $q->hidden( -name => 'rm',              -value => 'display_Sessions_List', -force => 1 );
    $form .= $q->submit( -name => 'Action', -value => 'Search', -class => "Search", -force => 1 );    ###paramateres should be fixed
    $form .= $q->end_form();

    return $form;
}
##############################
sub direct_session {
############################
    #	Description:
    #		- This function creates a form, helping user directly retrieve a session by inputing its name
    #	Input:
    #		- No input
    #	Output:
    #		- Form
    # <snip>
    # Usage Example:
    #	my $page .= $self-> direct_session ();
    # </snip>
############################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $form;

    $form .= alDente::Form::start_alDente_form( $dbc, 'direct_retrieve' );

    $form .= section_heading("Retrieve Direct Session");
    $form .= $q->textfield( -name => 'Session_File_Name', -size => 50, -force => 1 ) . vspace();
    $form .= $q->hidden( -name => 'cgi_application', -value => 'SDB::Session_App', -force => 1 );
    $form .= $q->hidden( -name => 'rm', -value => "display_Session_details", -force => 1 );
    $form .= $q->hidden( -name => 'source', -value => 'direct', -force => 1 );
    $form .= $q->submit(
        -name  => 'Action',
        -value => 'Display Session',
        -class => "Search",
        -force => 1
    );
    $form .= "<span class=small>" . vspace() . "note: The name of file has to be exact (including directory)" . "</span>";
    $form .= $q->end_form();

    return $form;
}
##############################
sub archive_sessions {
############################
    #	Description:
    #		- This function creates a form, helping user search archives for a specofic session
    #	Input:
    #		- No input
    #	Output:
    #		- Form
    # <snip>
    # Usage Example:
    #	my $page .= $self-> archive_sessions ();
    # </snip>
############################
    my $self = shift;
    my $form;
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $public = $args{-public};

    my @month_list = qw (Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my $tm         = localtime;
    my ( $day, $month, $year ) = ( $tm->mday, $tm->mon, $tm->year );
    $year += 1900;

    $form .= alDente::Form::start_alDente_form( $dbc, 'Week_Search' );

    $form .= section_heading("Archive Search");

    if ($public) {
        $form .= "Contact: "
            . alDente::Tools::search_list(
            -name   => 'FK_Contact__ID',
            -dbc    => $dbc,
            -search => 1,
            -filter => 1
            ) . vspace();
        $form .= $q->hidden( -name => 'public', -value => '1', -force => 1 );
    }
    else {
        $form .= alDente::Tools::search_list(
            -name   => 'FK_Employee__ID',
            -dbc    => $dbc,
            -search => 1,
            -filter => 1
        ) . vspace();
    }

    $form .= "Keyword: " . $q->textfield( -name => 'Keyword', -size => 20, -force => 1 ) . '  (showing ' . $q->textfield( -name => 'Line_Margin', -size => 3, -default => 3, -force => 1 ) . ' neighbouring lines)' . vspace();
    $form .= "Date: " 
        . $q->textfield( -name => 'date', -size => 2, -default => $day, -force => 1 ) 
        . hspace(5)
        . $q->popup_menu(
        -name    => 'month',
        -value   => [ '', @month_list ],
        -default => $month_list[$month]
        )
        . hspace(5)
        . $q->textfield( -name => 'year', -size => 4, -default => $year, -force => 1 )
        . vspace();
    $form .= $q->hidden( -name => 'cgi_application', -value => 'SDB::Session_App', -force => 1 );
    $form .= $q->hidden( -name => 'search mode',     -value => 'archive',          -force => 1 );
    $form .= "Code Version:"
        . $q->textfield(
        -name    => 'code_version',
        -size    => 20,
        -force   => 1,
        -default => $Configs{version_name}
        ) . vspace();

    #$form .= "Host " . $self->host_popup( -dbc => $dbc, -name => "host_choice" ) . vspace();

    eval "require SDB::Login_Views";
    my $login_view = new SDB::Login_Views( -dbc => $dbc );
    $form .= "Host " . $login_view->host_popup( -dbc => $dbc, -name => "host_choice" ) . vspace();
    $form .= "Database: " . $login_view->database_modes( -dbc => $dbc, -name => 'dbase_choice' ) . vspace();
    $form .= $q->submit( -name => 'rm', -value => 'Search', -force => 1, -class => "Search" );

    $form .= "<span class=small>" . vspace() . "note: for archive search, you need to fill in the date or have a keyword for search to be activated" . "</span>";
    $form .= $q->end_form();
    return $form;
}

##########################################################################################################################
#####  SMALL FUNCITONS
##########################################################################################################################
#############################################################

#############################################################
#
#
#
#############################################################
sub printers_popup {
#############################################################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc} || $self->param('dbc');
    my $mode    = $args{-mode} || $Configs{default_mode};
    my $default = $args{-default};

    my @printer_groups = $dbc->Table_find( 'Printer_Group', 'Printer_Group_Name', "WHERE Printer_Group_Status = 'Active' ORDER BY Printer_Group_Name" );
    my ($disabled) = $dbc->Table_find( 'Printer_Group', 'Printer_Group_Name', "WHERE Printer_Group_Name LIKE '%Disabled'" );

    ## set javascript to dynamically activate / deactivate Printers based upon Database mode selected (deactivate if non-production) ##
    $self->{activate_printers_js}   = "SetSelection(this.form, 'Printer_Group', '')";
    $self->{deactivate_printers_js} = "SetSelection(this.form, 'Printer_Group', '$disabled')";

    if   ( $mode eq 'PRODUCTION' ) { $default ||= '' }
    else                           { $default ||= $disabled }

    if ( int(@printer_groups) > 1 ) {
        unshift @printer_groups, '';
    }    ## if more than one option, the first option should be blank .. ##

    my $printer = $q->popup_menu(
        -name    => 'Printer_Group',
        -values  => \@printer_groups,
        -default => $default,
        -force   => 1,
    );

    my $block = Show_Tool_Tip( $printer, 'Specify group of printers (optional) - Details will appear following login, with option to change if desired.' );

    return $block;
}

#############################################################
#
#
#
#############################################################
sub department_popup {
#############################################################
    my $self               = shift;
    my %args               = filter_input( \@_ );
    my $dbc                = $args{-dbc} || $self->param('dbc');
    my $Default_Department = param('Target_Department');

    my @departments = $dbc->Table_find( 'Department', 'Department_Name', "WHERE Department_Status = 'Active' ORDER BY Department_Name" );
    unshift( @departments, '' );

    my $department_list = $q->popup_menu(
        -name    => 'Department',
        -values  => \@departments,
        -default => $Default_Department,
        -force   => 1
    );

    return Show_Tool_Tip( $department_list, 'choose Department section to load page on (optional)' );

}

#############################################################
#
#
#
#############################################################
sub aldente_versions {
#############################################################
    my $self           = shift;
    my %args           = filter_input( \@_ );
    my $dbc            = $args{-dbc} || $self->param('dbc');
    my $other_versions = '';

    my $this_version      = $Configs{URL_dir_name};
    my $version_directory = $Configs{URL_address};
    $version_directory =~ s/[_]?\/cgi-bin//;    ## strip cgi_bin from URL version directory

    my @versions = qw(Production Test Alpha Beta Development);
    foreach my $ver (@versions) {
        my $URL = $dbc->{session}{curr_page}{target};

        ##Erase all extra URL parameters
        $URL =~ s/\?(.*)//;
        my $ver_dir  = $version_directory;
        my $host_key = uc($ver) . '_HOST';
        my $host     = $Configs{$host_key} || $Configs{BETA_HOST};    ## default to BETA_HOST

        $URL =~ s/\/\/$Configs{SQL_HOST}/\/\/$host/;
        $ver_dir .= '_' . lc($ver);

        $URL =~ s /\/$Configs{URL_dir_name}\//\/$ver_dir\//;

        $other_versions .= "<li> <a href='$URL'>$ver version</a></li>\n";
    }
    return $other_versions;
}

#############################################################
#
#
#
#############################################################
sub user_list {
#############################################################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $dbc   = $args{-dbc} || $self->param('dbc');
    my $user  = $args{-user};
    my @users = $dbc->Table_find( 'Employee', "Employee_Name" );

    my $user_list = &RGTools::RGIO::Show_Tool_Tip( $q->textfield( -name => 'User List', -size => 20, -default => $user, -force => 1 ), "Use LIMS user name or LDAP name" );
    if ($scanner_mode) {
        $user_list = $q->popup_menu(
            -name    => 'User List',
            -value   => [@users],
            -default => $user,
            -force   => 1
        );
    }
    return $user_list;

}

    
1;
