#!/usr/local/bin/perl

use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/custom";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Sequencing";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";
use lib $FindBin::RealBin . "/../lib/perl/Imported/LDAP";

# use alDente tools

# use external tools

# use LDAP

use CGI qw(:standard);
use CGI::Carp('fatalsToBrowser');
use Digest::MD5;
use Data::Dumper;
use Net::LDAP;
use XML::Dumper;
use Benchmark;

### alDente modules
use RGTools::RGIO;
use SDB::DBIO;
use SDB::HTML;
use alDente::Session;
use SDB::CustomSettings;
use alDente::Web;

### Submission modules
use Submission::Globals;
use Submission::Public;
use Submission::Redirect;
use alDente::View_App;
use alDente::View;

#use vars qw($homelink $Connection);
use vars qw($Sess $homelink $Connection $submission_dir $URL_version $dbc %Benchmark %Configs);    # from production
my $SCRIPT = '/cgi-bin/alDente_public.pl';

my $under_construction = 0;                                                                        ## set to 1 if in the process of upgrading the release

if ($under_construction) {
    abort_session();
    exit;
}

my @errors;
my $config_dir = "$Configs{templates_dir}/..";

if ( !-f "$config_dir/personalize.conf" ) {
    push @errors, "Custom config file ($config_dir/personalize.conf) missing";
}

if (@errors) {
    my $msg = "Errors Noted - please contact LIMS Administrators:";
    foreach my $error (@errors) {
        $msg .= '<P>' . $error;
    }
    abort_session($msg);
    exit;
}

$Benchmark{Start} = new Benchmark();
## load config file

# Set useful global variables from config
my $LDAP          = $Configs{'LDAP_Server'};
my $JS_DIR        = $Configs{'JAVASCRIPT'};
my $CSS_DIR       = $Configs{'CSS'};
my $image_dir     = $Configs{'IMAGE_DIR'} || '/opt/';
my $project_path  = $Configs{'PUBLIC_PROJECT_DIR'};
my $SESS_DIR      = $Configs{'collab_sessions_dir'};
my $dbase         = param('Database') || $Configs{"DATABASE"};
my $host          = $Configs{"HOST"};
my $homelink      = get_homelink();
my $base_ext_path = get_base_ext_path();
$Configs{'HOMELINK'}      = $homelink;
$Configs{'BASE_EXT_PATH'} = $base_ext_path;

my $logged_in = 0;

# initialize js
#my $js = &Submission::Public::gen_javascript(-js_dir=>$JS_DIR,-js_files=>"SDB.js,alDente.js,DHTML.js,Prototype.js,FormNav.js,json.js,alttxt.js");
my $js = &Submission::Public::gen_javascript(
    -js_dir   => "/$URL_dir_name/js",
    -js_files => "SDB.js,alDente.js,DHTML.js,Prototype.js,FormNav.js,json.js,alttxt.js,calendar.js,jquery.js"
);

my $js_str = '';
foreach my $elem ( @{$js} ) {
    $js_str .= $elem;
}

# initialize css and pragmas
my $css = &Submission::Public::gen_css(
    -css_dir   => "/$URL_dir_name/css",
    -css_files => "colour.css,links.css,style.css,common.css,FormNav.css,calendar.css"
);    # from production

my $css_str = '';

# <CONSTRUCTION> Pragmas. Move into conf file
$css_str .= "\n<META HTTP-EQUIV='Pragma' CONTENT='no-cache'>\n";
$css_str .= "\n<META HTTP-EQUIV='Expires' CONTENT='-1'>\n";
foreach my $elem ( @{$css} ) {
    $css_str .= $elem;
}

my $cookie_ref = undef;
my $login_messages;

# grab all assigned cookies
my %cookie_values = %{ &Submission::Public::retrieve_cookies( -name => "alDente_collab:user,alDente_collab:name,alDente_collab:email,alDente_collab:session_id433" ) };

#print header();
# initialize the connection object
$dbc = SDB::DBIO->new(
    -host    => $host,
    -dbase   => $dbase,
    -user    => "collab",
    -connect => 1
);
$dbc->connect_if_necessary();
$Sess = new alDente::Session( -dbc => $dbc );

# start header and html
my $topbar = &alDente::Web::show_topbar(
    -include      => 'null',
    -include      => 'Contact,HostInfo',
    -image_dir    => "$image_dir",
    -about_link   => "http://www.bcgsc.ca",
    -contact_link => "http://www.bcgsc.ca",
    -center_link  => 'http://www.bcgsc.ca',
    -dbc          => $dbc,
);

print &alDente::Web::Initialize_page(
    -topbar            => $topbar,
    -cookie_ref        => $cookie_ref,
    -css_pragma_header => $css_str,
    -java_header       => $js_str
);

my $session_id = undef;
if ( $URL_version !~ /production/i ) {
    $submission_dir .= '/test';
    $SESS_DIR       .= '/test';

}

$logged_in = &login();

unless ($logged_in) {

    # ask user to log in
    &Submission::Public::show_login_form(
        -login_messages => $login_messages,
        -title          => "<B>Public Access page to GSC for Collaborators</B>"
    );
    my $botbar = &alDente::Web::show_botbar(
        -image_dir   => "$image_dir",
        -center_link => 'http://www.bcgsc.ca'
    );
    print &alDente::Web::unInitialize_page( -botbar => $botbar );
    print end_html();
    $dbc->disconnect();
    exit;
}

# check if session is already stored
$session_id ||= $cookie_values{"alDente_collab:session_id"};

if ($session_id) {
    $Sess = new alDente::Session(
        -dbc        => $dbc,
        -session_id => $session_id,
        -user       => $user_name,
        -user_id    => $user_name,
        -load       => 1,
        -dbase      => $dbc->{dbase},

    );
}
else {

    # define new session
    $Sess = new alDente::Session(
        -dbc     => $dbc,
        -user    => $user_name,
        -user_id => $user_name,
        -dbase   => $dbc->{dbase},

        -generate_id => 1
    );
######## from production
    if ($user_name) {
        $session_id = $Sess->session_id();
        my $cookie_sess = &alDente::Web::gen_cookies(
            -names   => 'alDente_collab:session_id',
            -values  => "$session_id",
            -expires => '+1d'
        );
        push( @{$cookie_ref}, @{$cookie_sess} );
    }

######## from production ends
}

$dbc->set_local( 'user', $user_name );
## get lims admins some other way, but hardcoded temporarily ##
if ( $user_name =~ /^(rguin|echuah|ashafiei|tzang|adeng|dcheng)$/ ) {
    $dbc->{admin_mode} = 1;
    $dbc->{admin}      = 1;

}

if ( $dbc->{admin} ) { print create_tree( { 'Input' => show_parameters() } ) . '<P>' }

$dbc->{session} = $Sess;

$dbc->{session}{session_id} = $session_id;

if ( ( !defined "alDente_collab:session_id" ) && $user_name ) {
    $session_id = $Sess->session_id();
    my $cookie_sess = &alDente::Web::gen_cookies(
        -names   => 'alDente_collab:session_id',
        -values  => "$session_id",
        -expires => '+1d'
    );
    push( @{$cookie_ref}, @{$cookie_sess} );
}

$homelink .= "?User=$user_name&Session=$session_id&Database=$dbase";
$dbc->{homelink} = $homelink;

my $group_contact = $dbc->get_local('group_contact');

## generate title bar for top of page.. ##
my $title_bar = &Views::Heading("$collab_name ($user_name)");

my $project_id = param('Project_ID');
my $project    = param('Project');

if ($project) {
    ($project_id) = $dbc->Table_find( 'Project', 'Project_ID', "WHERE Project_Name = '$project'" );
}

my $finished = 0;

if ( $group_contact && !param('rm') ) {
    ## only need to intercept this at login time (can adjust logic as required, but used 'rm' for now since it was easy) ##
    print alDente::Submission_Views::display_Group_Login( -dbc => $dbc, -contact_id => $group_contact );
    $Sess->store_Session();

    exit;
}
if ( param('cgi_application') ) {
    my $cgi_application = param('cgi_application');
    eval "require $cgi_application";
    my $webapp = $cgi_application->new( PARAMS => { dbc => $dbc } );
    $ENV{CGI_APP_RETURN_ONLY} = 1;    ## returns output rather than printing it ##
    my $page = $webapp->run();
    print $page;
    if ($page) { $finished = 1 }
    else       { print '<hr>'; }      ## print separator since full page will load below
}

if ( !$finished ) {
    my $redirected = &Submission::Redirect::redirect(
        -dbc     => $dbc,
        -config  => \%Configs,
        -cookies => \%cookie_values
    );
    if ( param('DBUpdate') && !$contact_id ) {
        ($contact_id) = &Table_find( $dbc, "Contact", "Contact_ID", "WHERE Canonical_Name='$user_name'" );
    }

    if ($contact_id) {

        # if not redirected, then show welcome page
        if ($redirected) {
            print &Submission::Public::title_bar(
                -home         => $homelink,
                -dbc          => $dbc,
                -user_name    => $collab_name,
                -account_name => $user_name,
                -contact_id   => $contact_id,
                -project_path => $project_path,
                -config       => \%Configs,
                -layer_key    => 'proj',
                -sub_tab      => $title_bar,
                -active       => $redirected,
                -img_dir      => $image_dir,
                -session      => $session_id,
                -project_id   => $project_id
            );
        }
        else {
            print &Submission::Public::title_bar(
                -home         => $homelink,
                -dbc          => $dbc,
                -user_name    => $collab_name,
                -account_name => $user_name,
                -contact_id   => $contact_id,
                -project_path => $project_path,
                -config       => \%Configs,
                -layer_key    => 'proj',
                -sub_tab      => $title_bar,
                -img_dir      => $image_dir,
                -session      => $session_id,
                -project_id   => $project_id
            );

            print $login_messages;

        }
    }
}

$Benchmark{stop} = new Benchmark();

if ( $dbc->{admin} ) {
    require RGTools::Unit_Test;
    my $benchmarks = "\n<U>Ordered list of identified Benchmarks:</U><BR>\n";
    $benchmarks .= Unit_Test::dump_Benchmarks( -benchmarks => \%Benchmark, -delimiter => '<BR>', -start => 'Start', -format => 'html', -mark => [ 0, 1, 3, 5, 10 ] );
    print create_tree( -tree => { 'Benchmarks' => $benchmarks }, -print => 0 );
}

print &vspace(10) . &logout_button();

my $botbar = &alDente::Web::show_botbar(
    -image_dir   => "$image_dir",
    -center_link => 'http://www.bcgsc.ca'
);
print &alDente::Web::unInitialize_page( -botbar => $botbar );

# end html
print end_html();

# store the session
$Sess->store_Session();

exit;

################################
sub get_homelink {
################################
    my $version  = $Configs{'version_name'};
    my $base_url = $Configs{'PUBLIC_URL_domain'};
    my $link;
    if ( $version eq 'production' ) {
        $link = $base_url . '/SDB' . $SCRIPT;
    }
    else {
        $link = $base_url . '/SDB_' . $version . $SCRIPT;
    }
    return $link;
}
################################
sub get_base_ext_path {
################################
    my $script_path = $0;
    if ( $script_path =~ /(.+)$SCRIPT/ ) {
        return $1 . '/www';
    }
    return;
}

################################
# returns an HTML string for a logout button
################################
sub logout_button {
################################
    my $homelink = shift;

    my $str = '';
    $str .= start_form( -name => "Logout Form", -method => 'POST' );

    #    $str .= br();
    $str .= Link_To( $dbc->{homelink}, "Submissions Home" ) . vspace();
    $str .= submit( -name => 'Log Out', -style => "background-color:red" ) . br();

    $str .= end_form();
    if ($homelink) {
        return &Link_To( $homelink, 'Log Out', '&Log Out=1' );
    }
    else { return $str }
}

################################
sub login {
################################
    # # check if user is trying to log out
    if ( param('Log Out') ) {

        # wipe out all cookie information
        #    $cookie_ref = &Submission::Public::gen_cookies

        $cookie_ref = &alDente::Web::gen_cookies(
            -names   => [ 'alDente_collab:user', 'alDente_collab:name', 'alDente_collab:email', 'alDente_collab:session_id', 'alDente_collab:current_contact' ],
            -values  => [ "",                    "",                    "",                     "",                          '' ],
            -expires => [ "-1d",                 "-1d",                 "-1d",                  "-1d",                       "-1d" ]
        );
        $logged_in = 0;
    }

    # check if user is trying to log in
    elsif ( param('Log In') ) {
        $user_name = param('User');
        my $password = param('Password');

        # do taint checking! <CONSTRUCTION>
        my $retval = &Submission::Public::authenticate_user_LDAP(
            -server   => $LDAP,
            -user     => $user_name,
            -password => $password
        );

        # if defined, then user can log in
        if ($retval) {
            ( $collab_name, $collab_email ) = @$retval;
            record_cookie($retval);
            $logged_in = 1;
        }
        else {
            $login_messages .= &Views::Heading( "<B>Authentication Failed for $user_name ! Invalid username or password.</B>", "bgcolor='#CC0000' align='center'" );
        }

    }
    else {
        ### already Logged in ###≠≠
        if ( param('Select User') ) {
            my $contact     = get_Table_Param( -field => 'FK_Contact__ID' );
            my $pass        = param('Password');                               ## to be implemented.. not yet in place in the contact table ...
            my $new_contact = param('FK_Contact__ID');

            $Sess ||= new alDente::Session( -dbc => $dbc );
            my $ok = $Sess->alDente::Session::reset_session_user( -dbc => $dbc, -contact => $new_contact, -type => 'Contact' );
            if ($ok) {
                $Sess->store_Session();
                ## update globals, though they should be phased out...
                $session_id = $Sess->{session_id};
                $user       = $Sess->{user};
                $user_name  = $Sess->{user};
                $user_id    = $Sess->{user_id};
                $dbase      = $Sess->{dbase};

                $collab_name = $Sess->{user};

                ($collab_email) = $dbc->Table_find( 'Contact', 'Contact_Email', "WHERE Contact_ID = $user_id" );
                if ( !$collab_email ) { $dbc->warning("No Email available") }
                record_cookie( [ $collab_name, $collab_email ] );

                $homelink =~ s/Session=([\w\:]+)\&/Session=$session_id\&/;
            }
            $logged_in = 1;
        }
        elsif ( $cookie_values{"alDente_collab:user"} ) {

            # get cookie value
            $user_name   = $cookie_values{"alDente_collab:user"};
            $collab_name = $cookie_values{"alDente_collab:name"};

            # check the password hash against the collaborator password <CONSTRUCTION>
            $logged_in = 1;
        }
        elsif ( param('User') && param('Session') ) {
            $user_name  = param('User');
            $session_id = param('Session');
            $logged_in  = 1;
        }

        # check if the user has a cookie
        else {
            ## If u r here it means you just called page for first time
        }
    }

    $dbc->set_local( 'user_id',   $user_id );
    $dbc->set_local( 'user_name', $user_name );
    $dbc->set_local( 'session',   $session_id );
    $dbc->set_local( 'dbase',     $dbase );

    if ( param('Set User') ) {

    }
    else {

    }

    my ($orig_group_id) = $dbc->Table_find( "Contact", "Contact_ID", " WHERE Canonical_Name = '$user_name' AND Group_Contact = 'Yes'" );
    ## check for canonical name first, but group could also be generated as a member of another group (with only a contact name ##
    my ($group_id) = $dbc->Table_find( "Contact", "Contact_ID", " WHERE Contact_Name = '$user_name' AND Group_Contact = 'Yes'" );
    $group_id ||= $orig_group_id;

    if ($group_id) { $dbc->set_local( 'group_contact', $group_id ) }

    return $logged_in;
}

####################
sub record_cookie {
####################
    my $retval = shift;

    # record cookie
    ( $collab_name, $collab_email ) = @$retval;
    param( -name => 'alDente_collab:user',  -value => $user_name );
    param( -name => 'alDente_collab:name',  -value => $collab_name );
    param( -name => 'alDente_collab:email', -value => $collab_email );

    $cookie_ref = &alDente::Web::gen_cookies(
        -names   => [ 'alDente_collab:user', 'alDente_collab:name', 'alDente_collab:email' ],
        -values  => [ "$user_name",          "$collab_name",        "$collab_email" ],
        -expires => [ "+1d",                 "+1d",                 "+1d" ]
    );
    return $cookie_ref;
}

#########################
sub abort_session {
#########################
    my $message = shift || "UNDER CONSTRUCTION<BR><BR> - We are currently upgrading our LIMS -<BR><BR> Please try again later -  Thanks";

    print content_type_header();
    print "<Center><H1><B>$message</B></H1>";
    if ( $message =~ /under construction/i ) {
        print "<img src='/$image_dir/construction.gif></Center>;";
    }
}

##########################
sub content_type_header {
##########################
    my $css = shift;

    my $output = "Content-type: text/html\n\n";
    if ($css) {
        $output .= $html_header;                                     ### imported from Default File (SDB_Defaults.pm)
        $output .= "\n<!------------ JavaScript ------------->\n";
        $output .= $java_header;                                     ### imported from Default File (SDB_Defaults.pm)
    }
    return $output;
}

