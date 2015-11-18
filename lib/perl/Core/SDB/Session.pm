###############################################################################################################
# Session.pm
#
# Stores user session
#
# $Id: Session.pm,v 1.38 2004/11/30 01:43:50 rguin Exp $
##############################################################################################################
package SDB::Session;

use base LampLite::Session;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Session.pm - Stores user session

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
Stores user session<BR>

=cut

##############################
# superclasses               #
##############################
### Inheritance

push @ISA, qw(Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
### Reference to standard Perl modules
use strict;

# use CGI qw(:standard);
use DBI;
use Data::Dumper;
use Storable;
use MIME::Base32;

#use AutoLoader;
use Carp;

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use SDB::CustomSettings;
use SDB::DBIO;

use RGTools::RGIO;
use RGTools::Views;
use RGTools::Object;

use LampLite::Bootstrap;

use alDente::Form;
##############################
# global_vars                #
##############################
my $BS = new Bootstrap();
my $q  = new CGI;

### Global variables
use vars qw(%Configs $session_id $session_dir $login_name $login_pass $trace_level $User_Home %Defaults %User_Setting $testing %Login);

my $SESSION_FILE_LAST_LINE;    # to hold the last parsed line in the session file

#__END__;
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

# Assume:
#
# DEFINED User Table (at minimum):
#
# CREATE TABLE User (User_ID INT NOT NULL Auto_increment primary key, User_Name varchar(63) not null, Email_Address varchar(255) NOT NULL, User_Status ENUM ('Active','Inactive','Old') Default 'Active' NOT NULL, Password varchar(255) NOT NULL);
#
#

###########################
# Constructor of the object
###########################
sub new_old {
##########
    my $this = shift;
    my $class = ref($this) || $this;

    my %args    = @_;
    my $frozen  = $args{-frozen};       # The frozen object
    my $encoded = $args{-encoded};      # Whether the frozen object is encoded or not
    my $load    = $args{-load} || 0;    # Whether to load the session from the .login file

    ## database connection or connection information required
    my $dbc = $args{-dbc};              # Database handle

    my $user    = $args{-user};         # User name
    my $user_id = $args{-user_id};      # User ID
    my $host    = $args{-host};         # Database host
    my $dbase   = $args{-dbase};        # Database

    my $mode         = $args{-mode};
    my $dept         = $args{-dept};
    my $projects     = $args{-projects};        # Projects
    my $release      = $args{-release};         # Release number
    my $URL_dir      = $args{-URL_dir};         # URL directory
    my $scanner_mode = $args{-scanner_mode};    # Whether we are in scanner mode or not
    my $banner       = $args{-banner};          # Whether we display banner
    my $nav          = $args{-nav};             # Whether we display navigation icons
    my $session_id   = $args{-session_id};      # Session ID
    my $session_dir  = $args{-session_dir};     # Directory that stores the session files

    my $generate_id
        = defined $args{-generate_id}
        ? $args{-generate_id}
        : 1;

    # Whether to generate a new session ID
    my $PID = $$;                               ## store process id.

    my $self = new LampLite::Session( 'id:md5', $q );

    if ($frozen) {
        if ( $dbc->ping() ) {
            $self->{dbc} = $dbc;
        }
        else {
            $self->error("must supply valid dbc");
        }
        $self->{messages} = [];

        #	$self->clear_messages();  ## clear messages from previous pids.
        bless $self, $class;
        $self->param( 'PID', $PID );
        return $self;
    }

    $self->{session_id}      = $session_id;             # Session ID
    $self->{session_dir}     = $session_dir;            # Directory that stores the session files
    $self->{dbc}             = $dbc;                    # Database handle
    $self->{user}            = $user;                   # User name
    $self->{user_id}         = $user_id;                # User ID
    $self->{host}            = $host;                   # Database host
    $self->{dbase}           = $dbase;                  # Database
    $self->{mode}            = $mode;                   # Database Mode
    $self->{dept}            = $dept;                   # Department
    $self->{projects}        = $projects;               # Projects
    $self->{release}         = $release;                # Release number
    $self->{URL_dir}         = $URL_dir;                # URL directory
    $self->{scanner_mode}    = $scanner_mode;           # Whether we are in scanner mode or not
    $self->{banner}          = $banner;                 # Whether we display banner
    $self->{nav}             = $nav;                    # Whether we display navigation icons
    $self->{printers}        = {};                      # Allow specification of prin
    $self->{printer_status}  = 1;
    $self->{IP_Address}      = $ENV{REMOTE_ADDR};
    $self->{HTTP_USER_AGENT} = $ENV{HTTP_USER_AGENT};

    $self->{curr_page} = {};                            # Various information regarding the current web page
    $self->{prev_page} = {};                            # Various information regarding the previous web page

    bless $self, $class;                                ## re-bless
    $self->param( 'PID', $PID );

    #    $self = $self->_initialize( -load => $load, -generate_id => $generate_id, -dbase => $dbase );

    return $self;
}

##############################
# public_methods             #
##############################

#
# Replace previous initialization and constructor with necessary logic as required
# (called from dbc)
#
#
###########
sub init {
###########
    my $self = shift;
    my $dbc  = shift;

    $self->{dbc}            = $dbc;
    $self->{printer_status} = 1;
    return;
}

###########
# Gets the session ID
###############
sub session_id {
###############
    my $self = shift;
    my %args = @_;

    my $padded = $args{-padded} || 0;    # Whether want to return the padded session ID

    my $ret = $self->{session_id};

    if ($padded) {
        my $ret = $self->{session_id};
        $ret =~ s/\s/+/g;
    }

    return $ret;
}

###############################
# Gets or Sets the user name
###############################
sub user {
##########
    my $self  = shift;
    my $value = shift;    # User name to be set

    if ($value) { $self->{user} = $value }

    return $self->{user};
}

###############################
# Gets or Sets the user ID
###############################
sub user_id {
############
    my $self  = shift;
    my $value = shift;    # User ID to be set

    if ($value) { $self->{user_id} = $value }

    return $self->{user_id};
}

# CUSTOM #
########################################################
# return hash of parameters to be sent to session forms
#
#
##############
sub parameters {
##############
    my $self    = shift;
    my $type    = shift;
    my $include = shift;

    my %P;
    ## Add included parameters ##
    if ($include) {
        foreach my $key ( keys %{$include} ) {
            $P{$key} = $include->{$key};
        }
    }

    ## exclude initial parameters if start type
    if ( $type =~ /\b(empty)\b/ ) {
        return \%P;
    }

    #    $P{Session} =  $Std_Parameters{'session_id'};
    #    $P{User}    =  $Std_Parameters{'user'};
    #    $P{Database} = $Std_Parameters{'dbase'};
    #    $P{Project} =  $Std_Parameters{'project'};

    $P{Session}       = $self->{'session_id'};
    $P{User}          = $self->{'user'};
    $P{Database_Mode} = $self->{'mode'};
    $P{Project}       = $self->{'project'};
    $P{Homepage}      = $self->{'homepage'};

    return \%P;
}

###############################
# Gets or Sets the database
###############################
sub dbase {
##########
    my $self  = shift;
    my $value = shift;    # Database to be set

    if ($value) { $self->{dbase} = $value }

    return $self->{dbase};
}

###############################
# Gets or Sets the database
###############################
sub url {
##########
    my $self  = shift;
    my $value = shift;    # Database to be set

    if ($value) { $self->{url} = $value }

    return $self->{url};
}

###############################
# Gets or Sets the database
###############################
sub mode {
##########
    my $self  = shift;
    my $value = shift;    # Database to be set

    if ($value) { $self->{mode} = $value }

    return $self->{mode};
}

###############################
# Gets or Sets the database
###############################
sub dept {
##########
    my $self  = shift;
    my $value = shift;    # Database to be set

    if ($value) { $self->{dept} = $value }

    return $self->{dept};
}

# CUSTOM #
#####################
sub reset_homepage {
#####################
    my $self   = shift;
    my $values = shift;
    my $debug  = shift;
    ## <Customize> - may set Standard Home Pages
    my @std_home_pages = (
        'Stock', 'Box',         'Solution',  'Container', 'Tube',    'Library_Plate', 'Array', 'Source',   'Original_Source', 'Sample', 'Extraction_Sample', 'GelRun',
        'Issue', 'WorkPackage', 'Inventory', 'Plate',     'Funding', 'Equipment',     'Rack',  'Shipment', 'Process_Deviation'
    );
    ## </Customize> ##

    my ( $table, $id ) = ( '', '' );
    if ( ref $values eq 'HASH' ) {
        my %hash = %$values;
        foreach my $key ( keys %hash ) {
            ($table) = split '\.', $key;
            $id = $hash{$key};
            last;
        }
    }
    elsif ( ref $values eq 'ARRAY' ) {
        my @array = @$values;
    }
    elsif ( $values =~ /\=/ ) {
        ( $table, $id ) = split /\s*=\s*/, $values;
    }
    elsif ( $values eq '' ) {
        $self->{homepage} = '';
    }
    else {
        Message( "Undefined session homepage: $values; ref:" . ref $values );
    }

    if ( grep /^$table$/, @std_home_pages ) {
        $self->{homepage} = "$table=$id" if ( $table && $id );
    }
    else {
        if ($debug) { Message("Homepages not set for $table pages") }
    }

    return $self->{homepage};
}

###############################
# Gets or Sets the projects
###############################
sub projects {
###############
    my $self  = shift;
    my $value = shift;    # Projects to be set

    if ($value) { $self->{projects} = $value }

    return $self->{projects};
}

###############################
# Gets or Sets the URL dir
###############################
sub URL_dir {
#############
    my $self  = shift;
    my $value = shift;    # URL directory name to be set

    if ($value) { $self->{URL_dir} = $value }

    return $self->{URL_dir};
}

###############################
# Gets or Sets the release
###############################
sub release {
#############
    my $self  = shift;
    my $value = shift;    # Releaes number to be set

    if ($value) { $self->{release} = $value }

    return $self->{release};
}

###############################
# Gets or Sets the banner
###############################
sub banner {
#############
    my $self  = shift;
    my $value = shift;    # Toggle whether we want to display banner

    if ($value) { $self->{banner} = $value }

    return $self->{banner};
}

###################################
# Gets or Sets the navigation icons
###################################
sub nav {
#############
    my $self  = shift;
    my $value = shift;    # Toggle whether we want to display navigation icons

    if ($value) { $self->{nav} = $value }

    return $self->{nav};
}

###############################
# Gets or Sets the scanner mode
###############################
sub scanner_mode {
#############
    my $self  = shift;
    my $value = shift;    # Toggle whether we are in scanner mode

    if ($value) { $self->{scanner_mode} = $value }

    return $self->{scanner_mode};
}

#
#
#
# Return: 1 if printer_status changed
######################
sub toggle_printers {
######################
    my $self  = shift;
    my $value = shift;

    my $status = $self->{printer_status};

    if   ( $value =~ /^(off|0)/ ) { $value = 0 }
    else                          { $value = 1 }

    if ( $value == $status ) { return 0 }
    else {
        $self->{printer_status} = $value;
        return 1;
    }
}


###############################################
# Get the target of the current page
###############################################
sub curr_page_target {
#############
    my $self = shift;

    return $self->{curr_page}->{target};
}

###############################################
# Get the params of the current page
###############################################
sub curr_page_params {
#######################
    my $self = shift;

    my $params_ref = Storable::thaw( MIME::Base32::decode( $self->{curr_page}->{params} ) );

    return $params_ref;
}

###############################################
# Get the warnings of the current page
###############################################
sub curr_page_warnings {
    my $self = shift;

    return $self->{curr_page}->{warnings};
}

###############################################
# Get the errors of the current page
###############################################
sub curr_page_errors {
    my $self = shift;

    return $self->{curr_page}->{errors};
}

###############################################
# Get the warnings of the current page
###############################################
sub curr_page_debug_messages {
    my $self = shift;

    return $self->{curr_page}->{debug_messages};
}

###############################################
# Get the target of the previous page
###############################################
sub prev_page_target {
    my $self = shift;

    return $self->{prev_page}->{target};
}

###############################################
# Get the params of the previous page
###############################################
sub prev_page_params {
    my $self = shift;

    my $params_ref = Storable::thaw( MIME::Base32::decode( $self->{prev_page}->{params} ) );

    return $params_ref;
}

###############################################
# Get the warnings of the previous page
###############################################
sub prev_page_warnings {
    my $self = shift;

    return $self->{prev_page}->{warnings};
}

###############################################
# Get the errors of the previous page
###############################################
sub prev_page_errors {
    my $self = shift;

    return $self->{prev_page}->{errors};
}

###############################################
# Get the errors of the previous page
###############################################
sub prev_page_debug_messages {
    my $self = shift;

    return $self->{prev_page}->{debug_messages};
}

#
# CUSTOM  - change to repeat ALL current input (not customized)... with extra 'Confirmation' parameter AFTER confirmation
########################################
# Displays a confirmation dialog to user
########################################
sub confirm {
############
    my $self = shift;
    my %args = @_;

    my $prompt   = $args{-prompt};                            # A prompt to the user
    my $continue = $args{'-continue'} || 'Yes - Continue';    # Label of the 'Continue' button - Ignore warnings and proceed
    my $back     = $args{-back} || 'Back';                    # Label of the 'Back' button     - Go back to the previous page
    my $abort    = $args{-abort} || 'Abort';                  # Label of the 'Abort' button    - Abort the process and go to home page

    my $dbc = $self->{dbc};

    unless ( $q->param('Confirmed') ) {
        print "<P>";

        if ($prompt) { print "<B>$prompt</B><P>" }

        ### Continue button.....
        my %parameters = %{ LampLite::Login::reload_Input() };
        $parameters{Confirmed} = 1;
        ## <CONSTRUCTION> - use variable list for clear list below ... ##
        my $continue_form;
        $continue_form .= &alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Confirmation_Continue', -parameters => \%parameters, -clear => 1, -debug => 1 );
        $continue_form .= $q->submit( -name => 'Continue', -value => $continue, -class => "Action" );
        $continue_form .= "</FORM>";

        ### Back button.....

        my %parameters = %{ $self->session_page_input() };    ## loads input from previous page by default

        my $back_form;
        $back_form .= &alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Confirmation_Back', -parameters => \%parameters, -clear => 1 );
        $back_form .= $q->submit( -name => 'Back', -value => $back, -class => "Std" );
        $back_form .= "</FORM>";

        ### Abort button.....
        %parameters = %{ $self->reset_parameters() };

        #$parameters{Department} = $User_Home;

        my $abort_form;
        $abort_form .= &alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Confirmation_Abort', -parameters => \%parameters );
        $abort_form .= $q->submit( -name => 'Abort', -value => $abort, -class => "Std" );
        $abort_form .= "</FORM>";

        &Views::Table_Print(
            content => [ [ $continue_form, $back_form, $abort_form ] ],
            width => '10%'
        );

        &main::leave();
    }
}


###################################################
# Overrides the warning function of the superclass
# Also display confirmation box to user if warning
###################################################
sub debug_message {
####################
    my %args    = &filter_input( \@_, -args => 'self,value', -self => 'SDB::Session' );
    my $session = $args{-session};
    my $self    = $args{-self} || $session;
    my $text    = $args{-value};                                                          # Value to be set [String
    my $print   = defined $args{ -print } ? $args{ -print } : 1;                          # Whether to display and confirm the warning now
    my $now     = $args{-now} || 0;                                                       # Whether to display and confirm the warning now
    my $quiet   = $args{-quiet};

    my $PID = $$;

    if ( defined $self->param('PID') ) {
        ## session exists ##
        $self->PID_message( -PID => $PID, -message => $text, -type => 'debug_message', -print => $print, -now => $now );
    }
    else {
        ## no current Session - print to STDOUT ##
        if ( !$quiet ) { print "$text\n" }
    }
    return;
}

#
# Clear all current session messages, warnings, errors
#
############################
sub clear_all_messages {
    my $self = shift;
    my $include = shift || 'messages, warnings, errors, debug';    ## allow explicit clearing of only one or more message type ##

    if ( $include =~ /message/i ) {
        $self->{messages} = [];
    }
    if ( $include =~ /warning/i ) {
        $self->{warnings} = [];
    }
    if ( $include =~ /error/i ) {
        $self->{errors} = [];
    }
    if ( $include =~ /debug/i ) {
        $self->{debug_messages} = [];
    }

    return 1;
}

#################################################
# generate the session id
#################################################
sub generate_session_ids {
###########################
    my $self = shift;

    # do not generate the session if cannot determine user id
    unless ( $self->{user_id} ) {
        return 0;
    }

    # Generate session ID if doesn't have one yet
    unless ( $self->{session_id} ) {
        $self->{session_id} = "$self->{user_id}:" . localtime();
        $self->{session_id} =~ s/\s/_/g;
    }

    unless ( $self->{session_name} ) {
        $self->{session_name} = "$self->{user_id}:" . localtime();
        $self->{session_name} =~ s/\s/_/g;
    }

    return ( $self->{session_id}, $self->{session_name} );
}

##################
sub session_dir {
##################
    my $self = shift;

    my $dbase = $self->{dbc}->{dbase} || $Configs{DATABASE};

    my $path   = $self->{dbc}->{sessions_web_dir};
    my $subdir = $self->{dbc}->{version_name} . "/$dbase";

    if ( !$self->{session_dir} || !( -e $self->{session_dir} ) ) {

        my $dir = &create_dir( -path => $path, -subdirectory => $subdir );

        $self->{session_dir} = "$path/$subdir";
    }

    $self->{session_dir} = "$path/$subdir";

    # }

    return $self->{session_dir};
}

##########################

# CUSTOM - should only need to configure session path
##########################
# Retrieve the session info
#
# 	Description:
#		- This allows administrator to go directly to a page used by a past user,
#  			with parameters set as they were during the previous visit).
#	Input:
#		- In from of hash, parameters identifing the session
#	Output:
#		- An array of references to hashes with the list of session ids, user name associated and size
# <snip>
# Usage Example:
#	@sessions = $Sess->get_sessions(user=>$sessionUser,day=>$sessionDay,searchmode => 'regular'
#											margin=>$margin,keyword=>$string)
#
# </snip>
##########################
sub get_sessions {
##########################
    use warnings;
    my $self         = shift;
    my %args         = &filter_input( \@_ );
    my $user         = $args{ -user } || "*";                                           # User to search for
    my $day_full     = $args{-day} || "*";                                              # Day of the week
    my $string       = $args{-keyword};                                                 # Search string
    my $margin       = $args{-margin} || 1;                                             # Margin in which to display line
    my $year         = $args{-year};
    my $month        = $args{-month};
    my $date         = $args{-date};                                                    # date of the month
    my $contact      = $args{-contact};                                                 # date of the month
    my $search_mode  = $args{-searchmode} || 'regular';
    my $dbc          = $args{-dbc} || $self->{dbc};
    my $dir          = $args{-dir} || $self->{session_dir} || $dbc->config('sessions_web_dir');    # Session directory
    my $public       = $args{-public};
    my $extensive    = $args{-extensive};
    my $code_version = $args{-code_version} || $Configs{version_name};
    my $dbase_choice = $args{-dbase_choice} || $dbc->{dbase};
    my $host_choice  = $args{-host_choice} || $dbc->{host};

    my $type = 'Local';
    if ($public) { $type = 'Public ' }

    if ( $dbase_choice eq uc($dbase_choice) )           { $dbase_choice = $Configs{"${dbase_choice}_DATABASE"} }    ## using dbase_mode ...
    if ( $host_choice  eq $Configs{'PRODUCTION_HOST'} ) { $host_choice  = 'limsmaster' }

    my $extra_find_args;
    my @sessions_output;
    my $day = substr( $day_full, 0, 3 );                                                                            # we only need the first 3 chars
    my $searchcommand;
    my @month_list = qw (Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my $month_char = $month_list[$month];

    my $contact_name;
    if ($contact) {
        my $contact_id = $dbc->get_FK_ID( 'FK_Contact__ID', $contact );
        ($contact_name) = $dbc->Table_find( 'Contact', 'Canonical_Name', "WHERE Contact_ID = $contact_id" );
    }

    if ( $search_mode eq 'today' ) {
        $searchcommand = "find $dir/ -name '*:*$month_char*$date*_*:*:*$year*.sess' -printf " . '"%p\t%k\n"';       # finding the matching sessions
    }
    elsif ( $search_mode eq 'regular' ) {
        my $id_search;
        if   ($public) { $id_search = $contact_name }
        else           { $id_search = $user }

        $extra_find_args = "-maxdepth 3";
        $searchcommand   = "find $dir/ -name '$id_search:$day*.sess' $extra_find_args -printf " . '"%p\t%k\n"';     # finding the matching sessions
    }
    if ( $search_mode eq 'archive' ) {
        $dir = $Configs{session_archive};
        if ($public) {
            my $expression;
            if   ($contact_name) { $expression = $contact_name . ":*" }
            else                 { $expression = '*:*' }
            if ($month) { $expression .= $month . '*' }
            if ($date)  { $expression .= sprintf "%02d*", $date }
            if ($year)  { $expression .= $year }
            $expression .= '*sess';
            my @final;
            $searchcommand = "find $dir -name '$expression' -maxdepth 2 -printf " . '"%p\t%k\n"';
        }
        else {
            $dir .= "/$host_choice/$code_version/$dbase_choice/archive/";
            my $depth = 4;
            if ($year) {
                $dir .= "$year/";
                $depth--;
                if ($month) {
                    $depth--;
                    $dir .= "$month/";
                    if ($date) {
                        $depth--;
                        $dir .= sprintf "%02d/", $date;
                    }
                }
            }
            $searchcommand = "find $dir -name '$user:*.sess' -maxdepth $depth -mindepth $depth -printf " . '"%p\t%k\n"';
            $searchcommand =~ s/\*+/\*/g;

            #Message $searchcommand;
        }
    }

    $dbc->message("Session Search Command: $searchcommand");
    my @all_sessions = split "\n", try_system_command($searchcommand);
    my @sessions;
    $dbc->message( 'Found ' . int(@all_sessions) . ' Sessions...' );

    for my $curr_sess (@all_sessions) {
        if ($public) {
            if ( $curr_sess =~ /\/[a-zA-Z]+\:/ ) { push @sessions, $curr_sess }
        }
        else {
            if ( $curr_sess =~ /\/\d+\:/ ) { push @sessions, $curr_sess }
        }
    }

    my $found = int(@sessions);

    if ( $found > 0 ) {
        my $Progress = new SDB::Progress( 'Loading applicable Session information', -target => $found );
        ### sessions found matching criteria ###
        my $count = 0;
        foreach my $ThisSession (@sessions) {
            $count++;
            unless ($ThisSession) {
                next;
            }
            my $session_info = $self->get_sess_details(
                -session => $ThisSession,
                -keyword => $string,
                -margin  => $margin,
                -dbc     => $dbc,
                -dir     => $dir
            );
            push @sessions_output, $session_info;

            my $temp = $session_info->{ -user };
            $Progress->update($count);
        }
        if ( $count < $found ) { $Progress->update($found) }
    }
    elsif ( $found < 1 ) {
        ### No matches... ###
        $dbc->message("No $type Sessions Found");
        $dbc->message("Tried: $searchcommand");
        return;
    }

    return @sessions_output;
}

# CUSTOM
##########################
sub get_sess_details {
##########################
    my $self        = shift;
    my %args        = &filter_input( \@_ );
    my $ThisSession = $args{-session};
    my $string      = $args{-keyword};        # Search string
    my $margin      = $args{-margin} || 1;    # Margin in which to display line
    my $dbc         = $args{-dbc};
    my $dir         = $args{-dir};
    my %session_info;
    my $path;
    my $thisuser_id;
    my $timestamp;
    my $size;
    my $thisuser;
    my $full_path;
    my $filename;

    if ( $ThisSession =~ /$dir(.*)\/(\d+)[:](.*)\.sess\s+(\d+)/ ) {
        $path        = $1;
        $thisuser_id = $2;
        $timestamp   = $3;
        $size        = $4;
        $thisuser    = $dbc->display_value($self->{login_table}, $thisuser_id );
        $full_path   = $dir . $path;
        $filename    = $thisuser_id . ":" . $timestamp;
    }
    elsif ( $ThisSession =~ /$dir(.*)\/(\w+)[:](.*)\.sess\s+(\d+)/ ) {
        $path      = $1;
        $timestamp = $3;
        $size      = $4;
        $thisuser  = $2;
        $full_path = $dir . $path;
        $filename  = $thisuser . ":" . $timestamp;

    }
    elsif ( $ThisSession =~ /$dir(.+)\/(\w+)\:(.*)\.sess\s+(\d+)/ ) {
        $path      = $1;
        $thisuser  = $2;
        $timestamp = $3;
        $size      = $4;
        $full_path = $dir . '/' . $path;
        $filename  = $2 . ':' . $3;
    }
    elsif ( $ThisSession =~ /$dir(\w+)\:(.*)\.sess\s+(\d+)/ ) {
        $timestamp = $2;
        $size      = $3;
        $thisuser  = $1;
        $full_path = $dir;
        $filename  = $1 . ':' . $2;
    }
    else {
        return;
    }

    #   We search for ke words
    if ($string) {
        my $command = "grep -n$margin '$string'  $dir/$path/$filename.sess";

        #print "command: $command<br>";
        #print "ThisSession: $ThisSession<br>";
        my @text = split "\n", try_system_command($command);
        unless (@text) { next; }

        %session_info = (
            -user      => $thisuser,
            -timestamp => $timestamp,
            -size      => $size,
            -text      => \@text,
            -user_id   => $thisuser_id,
            -directory => $full_path,
            -sfile     => $filename
        );
    }
    else {
        %session_info = (
            -user      => $thisuser,
            -timestamp => $timestamp,
            -size      => $size,
            -user_id   => $thisuser_id,
            -directory => $full_path,
            -sfile     => $filename
        );
    }

    return \%session_info;
}

#
# Change this to update to use only persistent parameters as defined ##
#
# CUSTOM #
##########################
sub reset_parameters {
##########################
    my $self = shift;
    my %args = @_;

    my $dbc         = $args{-dbc} || $self->{dbc};
    my $parameters  = $args{ -parameters };
    my $no_database = $args{-no_database};
    my $no_mode     = $args{-no_mode};

    my %parameters;
    if ($parameters) { %parameters = %$parameters }

    my $persistent = $dbc->config('url_parameters');

    foreach my $param (@$persistent) {
        my $v = $self->param($param) || $dbc->config($param);
        if ($v) { $parameters{$param} = $v }
    }

    return \%parameters;
}

#
# Phased out... replaced with reset_parameters above...
#
# Change this to update to use only persistent parameters as defined ##
#
# CUSTOM #
##########################
sub set_parameters {
##########################
    my $self = shift;
    my %args = @_;

    my $no_database = $args{-no_database};
    my $no_mode     = $args{-no_mode};

    my %parameters;
    if   ( $self->scanner_mode() ) { $parameters{Method} = 'POST'; }
    else                           { $parameters{Method} = 'POST'; }

    if ( $self->session_id ) { $parameters{Session} = $self->session_id() }
    if ( $self->user() )     { $parameters{User}    = $self->user() }
    if ( $self->projects() ) { $parameters{Project} = $self->projects() }
    if ( $self->mode() && !$no_mode ) { $parameters{Database_Mode} = $self->mode() }
    if ( $self->dept() ) { $parameters{Department} = $self->dept() }
    if ( $self->url() )  { $parameters{url}        = $self->url() }

    return %parameters;
}

##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################

##################
sub get_session_login {
##################
    my $self    = shift;
    my %args    = filter_input( \@_, -args => 'session,highlight,PID', -mandatory => 'session' );
    my $session = $args{-session};                                                                  ### session to open
    my $Sstring = $args{-highlight};                                                                ### search string (optional) to highlight
    my $PID     = $args{ -PID };
    my %login_info;

    unless ( -e "$session.login" ) {
        Call_Stack();
        Message("File $session.login NOT Found (checking archive...)");
        ## check for archived log file ##
        my %decode_session = $self->_decode_Session( -name => $session );
        $session = "$decode_session{archived_path}/$decode_session{name}";
        unless ( -e "$session.login" ) {
            Message("File $session.login NOT Found in archive");
            return;
        }
    }

    my $oldSession       = &Storable::retrieve("$session.login");
    my $olduser          = $oldSession->{User} || $oldSession->{user};
    my $olduser_id       = $oldSession->{UserID} || $oldSession->{user_id};
    my $olddbase         = $oldSession->{Database} || $oldSession->{dbase};
    my $oldmode          = $oldSession->{Database_Mode} || $oldSession->{mode};
    my $olddept          = $oldSession->{Department} || $oldSession->{dept};
    my $old_release      = $oldSession->{Release} || $oldSession->{release};
    my $old_URL_dir      = $oldSession->{URL_dir} || $oldSession->{URL_dir};
    my $old_scanner_mode = $oldSession->{Scanner_Mode} || $oldSession->{scanner_mode};
    unless ($old_scanner_mode) { $old_scanner_mode = 0 }

    %login_info = (
        -user         => $olduser,
        -database     => $olddbase,
        -login        => $login_name,
        -string       => $Sstring,
        -release      => $old_release,
        -URL_dir      => $old_URL_dir,
        -scanner_mode => $old_scanner_mode
    );
    return %login_info;
}

##################
sub _decode_Session {
##################
    my $self    = shift;
    my %args    = &filter_input( \@_, -args => 'name' );
    my $session = $args{-name};

    my %decoded;
    if ( $session =~ /(.+)\/(.*)/ ) {
        $decoded{dir}  = $1;
        $decoded{name} = $2;
    }
    if ( $session =~ /(\d+):([a-zA-Z]{3})_([a-zA-Z]{3})_(\d+)_([\d\:]+)_(\d\d\d\d)/ ) {
        $decoded{user_id}    = $1;
        $decoded{day_name}   = $2;
        $decoded{month_name} = $3;
        $decoded{day}        = $4;
        $decoded{time}       = $5;
        $decoded{year}       = $6;
    }
    else {
        Message("Unrecognized session format: $session ?");
        return %decoded;
    }

    if ( $decoded{time} =~ /^(\d+):/ ) { $decoded{hour} = $1 }

    $decoded{archived_path} = $self->{session_dir} . "/" . $decoded{month_name} . "_" . $decoded{year} . "/" . $decoded{day_name} . "_" . $decoded{day};

##	$decoded{month_name} . "_" . $decoded{day} .  "_" . $decoded{year} . "/" .
    #	    $decoded{day_name} . "_" . $decoded{hour} ;

    print "Archived Path: $decoded{archived_path}<BR>";
    return %decoded;
}

##########################
sub session_page_input {
##########################
    my $self = shift;

    my %args = filter_input( \@_ );
    my $page = $args{-page} || -1;

    my $dbc = $self->{dbc};

    my @Pages = $self->load_session_pages();

    my $pages = @Pages;

    if ( $page < 0 ) { $page = $pages + $page }    ## normalize to page number
    if ( $page < 0 ) { $page = 0 }                 ## cannot access back more pages than available
    $page ||= $pages - 1;

    return $Pages[$page]->{Input};
}

##########################
sub load_session_pages {
##########################
    my $self = shift;

    my $dbc = $self->{dbc};

    my $session_file = $self->param('session_name') . '.sess';
    my $path         = $self->param('session_dir');

    open my $SF, '<', "$path/$session_file" or $dbc->error("Cannot access session file: $path/$session_file");

    my @Pages;
    my ( $started, $key, $pages ) = ( 0, 0, 0 );
    while (<$SF>) {
        my $line = $_;
        if (/^Start:(.*)/) {
            $Pages[$pages]->{Start} = $1;
            $Pages[$pages]->{Input} = {};
            $Pages[$pages]->{Page}  = $pages;
            $started++;
        }
        elsif (/^Finish:(.*)/) {
            $Pages[ $pages++ ]->{End} = $1;
            $started = 0;
        }
        elsif (/^Parameters:(.*)/) {
            ##
        }
        elsif ($started) {
            if (/^(.*?)=$/) {
                $key = $1;
            }
            elsif ($key) {
                $line =~ s/^\s+|\s+$//g;
                push @{ $Pages[$pages]->{Input}{$key} }, $line;
            }
        }

        #        print "$line<BR>";
    }

    return @Pages;
}

##############################
# Initialize
##############################
sub _initialize {
###################
    my $self = shift;
    my %args = @_;
    my $dbc  = $self->{dbc};
    my $load = $args{-load} || 0;    # Whether to load the session from file or not

    my $generate_id
        = defined $args{-generate_id}
        ? $args{-generate_id}
        : 1;                         # Whether to generate new session ID or not

    my $dbase = $args{ -dbase } || $self->{dbase};

    # Generate session ID if doesn't have one yet
    if ( !$self->{session_id} && $generate_id ) {
        $self->{session_id} = "$self->{user_id}:" . localtime();
        $self->{session_id} =~ s/\s/_/g;
    }

    # Get the session dir if doesn't have one yet
    unless ( $self->{session_dir} ) {
        $dbc->message("Defined Session Directory");
        #$self->{session_dir} = $Configs{session_dir};
        $self->{session_dir} = $dbc->config('sessions_web_dir') . '/' . $dbc->config('version_name') . "/$dbase";
    }

    if ($load) {    # Load from the session file
        my $session_file = "$self->{session_dir}/$self->{session_id}.login";
        unless ( -f $session_file ) {
            my $search_archive = "find $self->{session_dir}/ -name '$self->{session_id}.login'";
            my $found          = `$search_archive`;
            unless ( !$found || $found =~ /not found/i ) { chomp( $session_file = $found ) }
        }
        if ( -f $session_file ) {

            # preserve handle
            my $temp_dbc = $self->{dbc};
            $self = &Storable::retrieve($session_file);
            $self->{dbc} = $temp_dbc;
            unless ( $self->{dbc} ) {
                $self->{dbc} = SDB::DBIO->new(
                    -dbase       => $self->{dbase},
                    -host        => $self->{host},
                    -user        => $login_name,
                    -password    => $login_pass,
                    -trace_level => $trace_level
                );
            }
            $self->{prev_page} = &Storable::dclone( $self->{curr_page} );

            $self->clear_all_messages();

            #	    $self->{messages} = [];   ## <CONSTRUCTION> ok ?...
            #	    $self->SUPER::clear_messages();  ## clear messages from previous pids.
        }
        else {
            print "Content-type: text/html\n\n";
            Message("Session file $session_file not found.");
        }
    }

    # Reset the warnings/errors of the current page
    undef( $self->{curr_page}->{warnings} );
    undef( $self->{curr_page}->{errors} );
    undef( $self->{curr_page}->{debug_messages} );

    # Store the current page.
    my $request = $ENV{REQUEST_URI} || '';
    $self->{curr_page}->{target} = $Configs{URL_domain} . $request;

    my %params;
    foreach my $param ( $q->param() ) {
        my @values = $q->param($param);
        if ( $values[0] eq $values[1] && int(@values) == 2 && !ref $values[0] ) {
            ## remove duplication
            SDB::Errors::log_deprecated_usage('duplicate input parameters');
            $params{$param} = $values[0];
        }
        else {
            my $value = join ",", $q->param($param);
            $params{$param} = $value;
        }
    }
    $self->{curr_page}->{params} = MIME::Base32::encode( Storable::freeze( \%params ), "" );

    return $self;
}

###########################
#	Parse the session file
#	Usage:	SDB::Session::parse_session_file( -file => $file, -conditions => \%conditions );
#	Return:	Array ref of the matched session blocks
###########################
sub parse_session_file {
###########################
    my %args       = filter_input( \@_, -args => 'file, conditions' );
    my $file       = $args{-file};
    my $conditions = $args{-conditions};

    open( my $IN, "$file" ) || die "Couldn't open $file: $!\n";
    print "parsing session file $file ...\n";
    my @matches;
    my %session;

    ## get a session block
    my $block = get_session_block( -file_handle => $IN );
    while ($block) {

        #print "$block\n";

        ## parse the session block
        my $hash = parse_session_block( -block_text => $block, -file => $file );

        #print Dumper $hash;

        ## check if this block matches the search criteria
        my $found = search_block( -block => $hash, -conditions => $conditions );

        #print "found=$found\n";
        if ($found) {
            push @matches, $hash;

            #print Dumper $hash;
        }

        $block = get_session_block( -file_handle => $IN );
    }
    close($IN);

    #print Dumper \@matches;
    return \@matches;
}

###########################
#	Get all the session files for a given date
#	Usage:	SDB::Session::get_session_files( -date => $date );
#	Return:	Array ref of session file names
###########################
sub get_session_files {
###########################
    my $self = shift;
    my %args    = filter_input( \@_, -args => 'date,webhost,code_version,dbase' );
    my $date    = $args{-date};
    my $webhost = $args{-webhost};
    my $version = $args{-code_version};
    my $dbase   = $args{ -dbase };

    my $dbc = $self->{dbc};
    
    my $webhost_alias = $webhost;
    if ( $version eq 'production' ) {
        $webhost_alias = 'limsmaster';
    }

    my $archived = is_archived( -date => $date );
    ## determine the location of the session files
    my @months = ( 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' );
    my $year   = '';
    my $month  = '';
    my $day    = '';
    if ( $date =~ /(\d{4})-(\d{2})-(\d{2})/ ) {
        $year  = $1;
        $month = $2;
        $day   = $3;
    }

    my $dir;
    my @files;
    if ($archived) {
        $dir = $Configs{session_archive} . "/$webhost_alias/$version/$dbase/archive/$year/$months[$month-1]/$day";
        $dir =~ s|//|/|g;
        print "Retrieving session files from $dir ...\n";
        @files = glob "$dir/*.sess";
    }
    else {
        $dir = $dbc->config('sessions_web_dir') . "/$version/$dbase";
        $dir =~ s|//|/|g;
        if ( $day =~ /0(\d)/ ) { $day = "_" . $1 }
        my $pattern   = "$dir/*$months[$month-1]\_$day*.sess";
        my $localhost = `hostname`;
        if ( $localhost =~ /^(\w)\..*/ ) { $localhost = $1 }
        if ( $localhost ne $webhost ) {
            my $cmd    = "ssh $webhost \"find $dir -regex .*$months[$month-1]\_$day.*\.sess -printf '%f\n'\"";
            my $stdout = `$cmd`;
            my @remote_files;
            if ($stdout) {
                @remote_files = split '\n', $stdout;
            }

            ## copy the session files over to a temp dir for easy access
            my $temp_dir = $Configs{temp_dir};
            print "Copying session files from $webhost:$dir to $temp_dir ...\n";
            foreach my $file (@remote_files) {
                my $cmd    = "ssh $webhost \"cp '$dir/$file' '$temp_dir/$file'\"";
                my $stdout = `$cmd`;
                push @files, "$temp_dir/$file";
            }
        }
        else {
            print "Retrieving session files from $dir ...\n";
            @files = glob "$pattern";
        }
    }

    #print Dumper \@files;
    return \@files;
}

###########################
#	Determine if the sessions for the given date has been archived
#	Usage:	SDB::Session::is_archived( -date => $date );
#	Return:	1 if archived; 0 if not archived
###########################
sub is_archived {
###########################
    my %args = filter_input( \@_, -args => 'date' );
    my $date = $args{-date};

    ## figure out the last day of the current week
    my $datetime = date_time('-7d');
    my $last_date_current_week;
    if ( $datetime =~ /^(\d{4}-\d{2}-\d{2})/ ) {
        $last_date_current_week = $1;
    }

    my $archived = $date lt $last_date_current_week ? 1 : 0;
    return $archived;
}

###########################
#	Retrieve a session block from a session file
#	Usage:	SDB::Session::get_session_block( -file_handle => $fh );
#	Return:	SCALAR, the session block text
###########################
sub get_session_block {
###########################
    my %args = filter_input( \@_, -args => 'file_handle' );
    my $fh = $args{-file_handle};

    my $block;
    if ( block_start( -file_handle => $fh ) ) {    ## it's the start of the block
        while ( !block_end( -file_handle => $fh ) ) {
            $block .= $SESSION_FILE_LAST_LINE;
        }
    }
    return $block;
}

###########################
#	Look for the session block start
#	Usage:	SDB::Session::block_start( -file_handle => $fh );
#	Return:	1 if found the session block start; 0 if not
###########################
sub block_start {
###########################
    my %args = filter_input( \@_, -args => 'file_handle' );
    my $fh = $args{-file_handle};

    while ( $SESSION_FILE_LAST_LINE !~ /^\*{48}$/ && !eof $fh ) {
        $SESSION_FILE_LAST_LINE = <$fh>;
    }

    if ( $SESSION_FILE_LAST_LINE =~ /^\*{48}$/ ) {
        return 1;
    }
    else {
        return 0;
    }
}

###########################
#	Look for the session block end
#	Usage:	SDB::Session::block_end( -file_handle => $fh );
#	Return:	1 if found the session block end; 0 if not
###########################
sub block_end {
###########################
    my %args = filter_input( \@_, -args => 'file_handle' );
    my $fh = $args{-file_handle};

    my $current_line = <$fh>;
    $SESSION_FILE_LAST_LINE = $current_line;
    if ( $current_line =~ /^\*{48}$/ ) {    # start of the next block, signals the end of the last block
        return 1;
    }
    elsif ( !$current_line ) {
        return 1;
    }
    else {
        return 0;
    }
}

###########################
#	Parse the session block
#	Usage:	SDB::Session::parse_session_block( -block_text => $text, -file => $file );
#	Return:	Hash ref
###########################
sub parse_session_block {
###########################
    my %args = filter_input( \@_, -args => 'block_text,file' );
    my $text = $args{-block_text};
    my $file = $args{-file};

    my %block;
    my @lines = split '\n', $text;
    my @messages;
    my $i = 0;
    while ( $i <= $#lines ) {
        if ( $lines[$i] =~ /^(\w+(\s*\w+)*):(.*)$/ ) {    # should match 'Time' and 'Start'
            my $param = $1;
            my $value = $3;
            if ($value) { $block{$param} = $value }
            $i++;
        }
        elsif ( $lines[$i] =~ /^(\w+(\s*\w+)*)=$/ ) {
            my $param = $1;
            my @values;
            $i++;
            while ( defined $lines[$i] && $lines[$i] =~ /^\t(.*)/ ) {
                my $value = $1;
                push @values, $value if ($value);
                $i++;
            }
            if ( @values == 1 ) {
                $block{$param} = $values[0];
            }
            elsif ( @values > 1 ) {
                $block{$param} = \@values;
            }
        }
        else {    ## messages
            push @messages, $lines[$i];
            $i++;
        }
    }
    $block{messages}     = \@messages;
    $block{session_file} = $file;
    $block{block_text}   = $text;
    return \%block;
}

###########################
#	Given the search criteria, search the session block
#	Usage:	SDB::Session::search_block( -block => $block_hash, -conditions => $conditions );
#	Return:	1 if the criteria matched; 0 if not match
###########################
sub search_block {
###########################
    my %args       = filter_input( \@_, -args => 'block,conditions' );
    my $block      = $args{-block};
    my $conditions = $args{-conditions};

    foreach my $key ( keys %$conditions ) {

        #print "key=$key\n";
        my $condition = $conditions->{$key};
        $condition =~ s/\*/\.\*/g;

        $key =~ s/\*/\.\*/g;
        my @keys = grep /\b$key\b/, keys %$block;
        my $match = 0;
        foreach my $bkey (@keys) {
            if ( defined $block->{$bkey} ) {
                if ( ref $block->{$bkey} eq 'ARRAY' ) {
                    if ( grep /\b$condition\b/, @{ $block->{$bkey} } ) {
                        $match = 1;
                        last;    # match, go to the next criteria
                    }
                }
                elsif ( !ref $block->{$bkey} && $block->{$bkey} =~ /\b$condition\b/ ) {    #
                    $match = 1;
                    last;                                                                  # match, go to the next criteria
                }
                else {

                    #print "***\n[$block->{$bkey}]\n....!=...\n[$condition]\n***\n";
                    next;                                                                  #return 0;
                }
            }
            else {
                next;                                                                      #return 0;
            }
        }
        if ( !$match ) {
            return 0;
        }
    }
    return 1;
}

###########################
#	Format output of the session blocks
#	Usage:	SDB::Session::format_sessions( -sessions => $sessions, -return => $return );
###########################
sub format_sessions {
###########################
    my %args     = filter_input( \@_, -args => 'sessions,return' );
    my $sessions = $args{-sessions};
    my $return   = $args{ -return };

    my @keys = Cast_List( -list => $return, -to => 'array' );
    print join "\t", @keys;
    print "\n";

    foreach my $session (@$sessions) {
        if ( !$return ) {
            @keys = keys %$session;
            print join "\t", @keys;
            print "\n";
        }

        my @row;
        foreach my $key (@keys) {
            my $val = $session->{$key};
            if ( ref $val eq 'ARRAY' ) { $val = join ',', @{$val} }
            push @row, $val;
        }
        print join "\t", @row;
        print "\n";
    }
    return;
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

1;

