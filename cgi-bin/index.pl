#!/usr/local/bin/perl
#
# This is a minimalist script that includes (optional) session tracking and login capabilities
#  and the framework for enabling MVC run modes using parameters: cgi_app + rm 
#
# The MVC framework enables this simple script to be scalable to support a large sophisticated web application
#
# It assumes the following configuration setup files:
# * RGTools::RGIO
# * LampLite modules
# 
# * optional requirements
# - database connection (requires system.cfg : DATABASE HOST LOGIN_FILE)
# - session tracking (requires system.cfg : SESSION_DIR )
# - login_required (requires system.cfg : LOGIN_FILE )
#
########################################
## Standard Initialization of Module ###
########################################
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../custom/";

use LampLite::User;
use LampLite::Config;
########################
## Local Core modules ##
########################
use Benchmark;

##########################
## Local custom modules ##
##########################

use RGTools::RGIO;

### Modules used for Web Interface only ###
use LampLite::Bootstrap;
use LampLite::DB;         ## use to connect to database
use LampLite::Session;
use LampLite::MVC;
use LampLite::HTML;
use LampLite::Login_Views;

use LampLite::DB_Access;    ## use to retrieve login access passwords

## Globals ##
my $q               = new CGI;
my $BS              = new Bootstrap();

######################################
######## Setup Options ###############
######################################
#
    my $track_sessions      = 1;        ## track user sessions (requires writing session log files)
    my $database_connection = 1;   ## connects to backend database 
    my $login_required      = 1;   ## Login required to access site (even if just logging in as guest)
#
################################
### Required input variables ###
################################
    my $login_file = "/opt/alDente/versions/ll/conf/mysql.login";
    my $path = "./../";


#    my $login_class = 'alDente::' . $login_type;
    my $login_class = 'LampLite::User';
    eval "require $login_class";

$| = 1;


####################################################################################################
###  Configuration Loading - use this block (and section above) for both bin and cgi-bin files   ###
####################################################################################################
my $custom_login = "LampLite::Login_Views";

###################################################
## END OF Standard Module Initialization Section ##
###################################################
my $Config = new LampLite::Config( -initialize => 1, -root => $FindBin::RealBin . '/..', -bootstrap => 1, -custom_file=>'./../conf/personalize.cfg');

#############################################
### Load Configuration variables required ###
#############################################

my $session_dir = "$Config->{config}{Web_home_dir}/dynamic/sessions";
my $host = $Config->{config}{SQL_HOST} || 'hblims05';
my $dbase = $Config->{config}{DATABASE} || 'bcg_dev';
my $version = $Config->{config}{custom_version} || 'Healthbank';
my $login_type = $Config->{config}{login_type};

##########################################################

### Load Input parameters ###
my $dept            = $q->param('Target_Department');
my $project         = $q->param('Target_Project');
my $opentab         = $q->param('OpenTab');                ## optional tracking of open tab layer
my $rm              = $q->param('rm');
my $username        = $q->param('User');
my $auto            = $q->param('Auto_Report');            ## used for direct connection (bypassing login) to read-only access page via link


##########################################################

my $init_errors;
if ( $init_errors && @$init_errors ) {
    my $errors = Cast_List( -list => $init_errors, -to => 'UL' );
    print LampLite::Session::abort_session( "Initialization Errors", $errors );
    exit;
}

print LampLite::HTML::initialize_page(-path=>$path, -css_files=>$Config->{css_files}, -js_files=>$Config->{js_files});    ## generate Content-type , body tags, load css & js files ... ##
print $BS->open();

my ($session, $sid);


if ($track_sessions) {

    ## Define and Load Interface Session ##
    ########################################
    my $ok = try_system_command("chmod 770 $session_dir/$version/$dbase");                                                                     ###
    create_dir( "$session_dir/", "$version/$dbase", 770 );
    $session = new LampLite::Session( 'id:md5', $q, { Directory => "$session_dir/$version/$dbase" } );
    $session->param( 'PID', $$ );

    my $user = $session->param('user');

    $sid = $session->validate_session();                                                                                                    ## check for expired session ##
    `CHMOD 660 $session_dir/$version/$dbase/cgisess_$sid`;
    
    $logged_in = $session->logged_in();
}

#print $custom_login->session_details();

my ($dbc, $output, $MVC);
my ($User, $logged_in);
if ($database_connection) {

my $url_params = $Config->{url_params};
my $session_params = $Config->{session_params};

#    ( my $output, my $db_user, my $pwd, my $MVC );
#    
#    if ($auto) {                                                                                                                               ## use backup host/dbase for read-only auto connects ##
#        ( $host, $dbase, $user_id, $db_user, $pwd ) = $session->setup_auto_session( $configs->{BACKUP_HOST}, $configs->{BACKUP_DATABASE} );
#    }
#    ########################################

    $dbc = new LampLite::DB(
        -dbase              => $dbase,
        -host               => $host,
        -password           => $pwd,
        -session            => $session,
        -config             => $configs,
        -session_parameters => $session_params,
        -url_parameters     => $url_params,
        -login_table        => $login_type,
        -connect            => 0,
        -defer_messages     => 1,
        -sessionless => !$track_sessions,
        -login_file => $login_file,
        );
}

my ($login_view, $header_generated);
if ( $sid && $logged_in ) {
    ( $user_id, $db_user, $pwd, $host ) = ( $session->param('user_id'), $session->param('db_user'), $session->param('db_pwd'), $session->param('host') );
    $dbc->connect( -user => $db_user, -pwd => $pwd );

    $User = $login_class->new( -dbc => $dbc, -id => $logged_in, -initialize => 1 );    ## define current user settings
    &initialize_dbc_configs();                                                            ## define initial configuration settings for url_parameters & homelink (eg CGISESSID, Database_Mode, Target_Department)

    $MVC = new LampLite::MVC( -dbc => $dbc, -params => { dbc => $dbc }, -call => 1 );
    $output = $MVC->{output};
}
else {
    if   ( $login_type =~ /contact/i ) { $db_user = 'collab' }
    else                               { $db_user = 'login' }
        
    if ($dbc) { $dbc->connect( -user => $db_user, -pwd => $pwd ) }

    if ( $rm eq 'Log In' ) {
        if ( $login_type =~ /contact/i ) {
            ## Connecting as Contact through LDAP - no need to reconnect as new user ##
            &initialize_dbc_configs();    ## define initial configuration settings for url_parameters & homelink (eg CGISESSID, Database_Mode, Target_Department)
            $user_id = $dbc->get_db_value( "SELECT Contact_ID FROM Contact WHERE Canonical_Name = '$username'" );
        }
        elsif ( $username eq 'Guest' ) {
            $user_id = $dbc->get_db_value( "SELECT Employee_ID FROM Employee WHERE Employee_Name = 'Guest'" );
        }
        else {
            ## Once password is confirmed, reconnect to database as applicable db_user ##
            ($db_user) = LampLite::DB_Access::get_DB_user( -dbc => $dbc, -user => $username );    ## Reconnect to applicable database as new user ...
            if ($db_user) { $dbc->connect( -user => $db_user, -pwd => $pwd ) }
            else          { $custom_login->relogin( $dbc, 1 ) }
        }
        $MVC = new LampLite::MVC( -dbc => $dbc, -params => { dbc => $dbc }, -call => 1 );    ## Calls login run mode which should reset dbc & user
        $user_id ||= $dbc->config('user_id');

        $User = $login_class->new( -dbc => $dbc, -id => $user_id, -initialize => 1 );     ## define settings based upon logged in user ##

        &initialize_dbc_configs();                                                           ## define initial configuration settings for url_parameters & homelink (eg CGISESSID, Database_Mode, Target_Department)
        $output = $MVC->{output};
    }
    elsif ($login_required) {
        ## Not Logged in, and not logging in... go to login page again ... ##
        if ($mobile) { $dbc->{screen_mode} = 'mobile' }
        $custom_login->relogin( -dbc => $dbc );
    }
}

## print $login_view->session_details();
if ( !( $dbc && $dbc->{connected} ) && $database_connection) {
    ## Failed to establish initial database connection (with generic login user) ##
    print $BS->error("FAILED TO CONNECT $db_user TO $dbase DATABASE ON $host using login file: $login_file");
    $login_view->leave($dbc);
}

if ( $MVC && $MVC->{reload_cgi_app} && $MVC->{reload_rm} ) {
    ## (generates page from reloaded MVC parameters when user logs in again from expired session) ##
    $output = $MVC->_call_sub_MVC( -dbc => $dbc, -sub_cgi => $MVC->{reload_cgi_app}, -rm => $MVC->{reload_rm}, -display => 1 );
}

my $expiry;
if ( $dbc->mobile() ) { $expiry = "+1h" }
else { $expiry = "+8h" }

$session->expire($expiry);    ## set sessions to expire after 2 hours
$session->flush();

##############################
#### Generate Page Output ####
##############################
if ($output) {
    print "output";
    if ( $ENV{CGI_APP_RETURN_ONLY} ) { print $output }
}
elsif ( $MVC->{secondary_output} ) {
    ## Generates page from reloaded input parameters ... in this case, it needs to be printed out since it is not automatically generated from the app ##
    print $MVC->{secondary_output};
}
else {
    if ( $dbc->session->logged_in() ) {
        my $header;
        if (!$header_generated) { $header = $login_view->header( -dbc => $dbc ) }
     
        &home( 'main', -header => $header, -case => $case, -open_tab => $opentab );
    }
    else {
        ## optional home page for guest (if applicable)
        print $custom_login->guest_home_page();
    }
}

if ($track_sessions) { store_Session($dbc) }
$dbc->Benchmark('close_page');
_close_page($dbc);    ## exits here
exit;

#############################
sub initialize_dbc_configs {
#############################
    $dbc->config( 'CGISESSID',     $sid );
    $dbc->config( 'Database_Mode', $mode );
    $dbc->config( 'url_root',      "/$path/" );
    $dbc->config( 'installation',  $custom );

    if ($mobile) { $dbc->{screen_mode} = 'mobile' }

    $dbc->config('screen_mode', $Config->{screen_mode});

    $homelink = $dbc->homelink($home);    ## establish homelink parameter and save as session attribute (this method automatically appends url_parameters to $home)
    $dbc->session->set_persistent_parameters(
        [ 'homelink', 'path',       'version', 'db_user',       'db_pwd',           'Active_Projects_Only', 'host', 'dbase', 'user',    'user_id' ],
        [ $homelink,  $session_dir, $version,  $dbc->{db_user}, $dbc->{login_pass}, $active_projects,       $host,  $dbase,  $username, $user_id ]
    );      
    $login_view = $custom_login->new( -dbc => $dbc );
    if ( ! $dbc->mobile() ) {
        my $tool_tip_disable = $User->get_Settings( -setting => 'DISABLE_TOOLTIPS', -scope => 'Employee' );
        if ( $tool_tip_disable =~ /on/i ) { $ENV{DISABLE_TOOLTIPS} = 1 }
    }

    my $user = $dbc->session->param('user_name');
    if ( $user && $user ne 'Guest' ) {
        print $login_view->generate_Header();    ## header needs to be generated after user is identified since user information is included in the header ##
        $header_generated++;
    }
    elsif ( $rm eq 'Log In' ) { }
    else                      { print $login_view->generate_Header() }

    $dbc->flush_messages();
    return 1;
}

#
# Close page - mirrors page initialization (_generate_Header)
#"
##################
sub _close_page {
##################
    my $dbc            = shift;
    my %args           = @_;
    my $include_footer = defined $args{-include_footer} ? $args{-include_footer} : 1;

    $login_view ||= $custom_login->new( -dbc => $dbc );

    print $BS->close();

    my $desktop_footer = "<a href='http://www.bcgsc.ca'><img src='/$path/images/png/aldente_footer.png' width=300></img></a>";

    if ($include_footer) {
        my $footer = qq(<center></center>$desktop_footer</div>\n) if !$dbc->mobile();
        print $login_view->footer( -footer => $footer );
    }

    my $Session = $dbc->session();
    if ( $Session && $Session->param('session_dir') && $Session->param('session_name') ) {
        my $dir  = $Session->param('session_dir');
        my $name = $Session->param('session_name') . '.sess';
        $Session->store_Session_messages("$dir/$name");
    }

    $login_view->leave($dbc);
}

############
sub leave {
############
    my $db = shift || $dbc;
    $login_view ||= $custom_login->new( -dbc => $db );
    $login_view->leave($db);
}

####################
sub store_Session {
####################
    my $dbc = shift;

    my $Session = $dbc->session();
    $track_sessions = 1;

    if ( $track_sessions && $Session->param('user') ) {
        $Session->store_Session( -dbc => $dbc );
        $dbc->Benchmark('stored_session');
    }
    return 1;
}

#
# Customized default home page
#
# Return: page output
################
sub home {
################
    my %args     = filter_input( \@_, -args => 'option,open_tab' );
    my $option   = $args{-option};
    my $open_tab = $args{-open_tab};
    my $header   = $args{-header};
    my $quiet    = $args{-quiet};
    my $exit     = $args{ -exit } || 1;
    my $case     = $args{ -case };

    my $quotes = 0;

    $login_view ||= $custom_login->new( -dbc => $dbc );

    my ( $table, $id );
    if ( $q->param('HomePage') ) {
        $table = $q->param('HomePage');
        $id    = $q->param('ID');
    }
    elsif ( $dbc && $dbc->session &&  $dbc->session->homepage() =~ /^(\w+)=([\w\,]+)$/ ) {
        $table = $1;
        $id    = $2;
    }

    if ( $table ) {
        ## Go to standard home page (deprecate non_MVC AND Button_Options HomePage functionality) ##
        my $scope = 'LampLite';
        my $class = $scope . '::' . $table;
        my $ok    = eval "require $class";
        
        my $Object = $class->new( -dbc => $dbc, -id => $id );

        my $page = $Object->View->std_home_page( -dbc => $dbc, -table => $table, -id => $id );    ## std_home_page generates default page, with customizations possible via local single/multiple/no _record_page method ##
        print $page;
    }
    else {
        ## Go to default home page ##
        print $login_view->home_page();
    }

    if ($exit) {
        $login_view->leave($dbc);
    }
    return;
}


1;
