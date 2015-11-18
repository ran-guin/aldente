#!/usr/local/bin/perl
#
# This provides a user interface for installing a core LampLite and/or LIMS system.
# It:
#  * prompts users for context specific setup information
#  * creates necessary config files
#  * creates core database on specified server
#  * creates data directory structure within filesystem based on user-supplied path specification
#  * confirms initial settings
#  * 
#
#  Requirements prior to running:
#  * svn checked out version of code is up to date
#  * database (mysql) is setup on an accessible server
#  * user should have mysql username / password with permission to create & build database and to edit mysql database tables
#
#
########################################
## Standard Initialization of Module ###
########################################

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../custom/";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use SDB::CustomSettings;
use LampLite::User;
use LampLite::Config;
########################
## Local Core modules ##
########################

my $root_user = 'root';
my $installer = 'patch_installer';
##########################
## Local custom modules ##
##########################

use RGTools::RGIO;

### Modules used for Web Interface only ###
use LampLite::Bootstrap;

use LampLite::DB;         ## use to connect to database
use LampLite::Session;

use LampLite::DB_Access;    ## use to retrieve login access passwords

use LampLite::Build;
use SDB::HTML;

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

$| = 1;

####################################################################################################
###  Configuration Loading - use this block (and section above) for both bin and cgi-bin files   ###
####################################################################################################

my $root = $FindBin::RealBin . '/..';
my $Config = LampLite::Config->new( -initialize => "$root/conf/custom.cfg", -root => $root, -bootstrap => 1);
my $Setup = $Config->{config};

my $config_dir = "$root/conf/";

my $custom_config = "$config_dir/custom.cfg";
my $password_file = "$config_dir/mysql.login";
my $filesystem_file = "$config_dir/directories.yml";

my %setup_map = (
        SQL_HOST => 'Server hosting mySQL',
        DATABASE => 'Name of database to be created',
        custom_version => 'Name of customized installation',
        version_name => 'alpha',
        login_type => "enum('Employee','User')",
        admin_email => 'admin@yourDomain.com',
        web_root => '/opt/alDente',
        data_root => '/opt/alDente/data',
        url_dir => 'url directory for local version (eg SDB_alpha)',
        url_root => 'relative url root (eg SDB_alpha)'
);
my %system_map = (
);
 
print LampLite::HTML::initialize_page(-path=>$Setup->{url_root}, -css_files=>$Setup->{css_files}, -js_files=>$Setup->{js_files});    ## generate Content-type , body tags, load css & js files ... ##   
#print LampLite::HTML::initialize_page(-path => "./..", -js_files=>$js_files, -css_files=>$css_files);

print $BS->header(-centre=>'LIMS / LampLite Setup', -style=>"margin:0px; background-color:white; border-color:white;", -flex=>['',1,'']);

print $BS->open(-width=>'90%');
print section_heading("Checking Installation");

my $validated = 1;


## Check Input ##
my $set_file = $q->param('File');
my $set_host = $q->param('Host');
my $set_user = $q->param('User');
my $set_pwd  = $q->param('Pwd');
my $set_confirm = $q->param('Confirm Pwd');

my @sections = $q->param('Core_Sections');
my $overwrite = $q->param('On_Duplicate');
my @include;
if (@sections) { 
    foreach my $section (@sections) {
        if ( $q->param("Include.$section") eq 'Yes' ) {
            push @include, $section;
        }
    }
}

##########################################
## Check for user input options first   ##
##########################################

##############################
## Perform Validation Tests ##
##############################

#####################################
### Check for Apache Installation ###
#####################################
# presumably you won't even see the web page if apache is not installed but this is included for consistency #

my @apache = split "\n", `/usr/sbin/httpd -V`;
if (grep /Server version/i, @apache) { 
    print $BS->modal(
        -label=> $BS->icon('check') . ' Apache Installed',
        -body => "<B>/usr/sbin/httpd -V</B>:<P>" . Cast_List(-list=>\@apache, -to=>"UL"),
        -launch_type => 'button',
        -class => 'Std',
    );
}
else {
    $validated = 0;
    print $BS->modal(
        -label=> $BS->icon('times') . ' Apache not Installed',
        -body => "You need to install Apache on this server before continuing",
        -launch_type => 'button',
        -class => 'Action',
        -tooltip=>'',
    );
}

print "<P></P>";

#####################################
### Check for mySQL Installation ###
#####################################sapac
# presumably you won't even see the web page if apache is not installed but this is included for consistency #

my @mysql = split "\n", `mysql -V`;
if (grep /mysql/i, @mysql) { 
    print $BS->modal(
        -label=> $BS->icon('check') . ' mySQL Installed',
        -body => "<B>mysql -V</B>:<P>" . Cast_List(-list=>\@mysql, -to=>"UL"),
        -launch_type => 'button',
        -class => 'Std',
    );
}
else {
    $validated = 0;
    
    my @mysql_install = (
        'sudo yum mysql-server mysql',
        'sudo cp /opt/alDente/versions/alpha/conf/my.cnf /etc/my.cnf',
        '/etc/init.d/mysqld start',
        '/etc/init.d/mysqld stop',
        '/etc/init.d/mysqld restart',
        'mysqladmin -u root password NEWPASSWORD',
    );
        
    print $BS->modal(
        -label=> $BS->icon('times') . ' mySQL not Installed',
        -body => "You need to install mySQL on this server before continuing<P>" . Cast_List(-list=>@mysql_install),
        -launch_type => 'button',
        -class => 'Action',
        -tooltip=>'',
    );
}

print "<P></P>";

##################
### Test Setup ###
##################
my $Build = new LampLite::Build();

if ($q->param('Create initial configuration file')) {
    $Build->create_config_file(-map=>\%setup_map, -file=>$custom_config);
}

if (-e $custom_config) { 
    $Config->load_std_yaml_files([$custom_config]); 
    print $BS->modal(
        -label=> $BS->icon('check') . ' Setup Config File Found',
        -body => $Build->View->setup_config(-map=>\%setup_map, -Config=>$Config),
        -launch_type => 'button',
        -class => 'Std',
    );
}
else {
    $validated = 0;
    print $BS->modal(
        -label=> $BS->icon('times') . " Setup Config File Missing ($custom_config ?)",
        -body => $Build->View->setup_config(-map=>\%setup_map, -update=>'update'),
        -launch_type => 'button',
        -class => 'Action',
        -tooltip=>'yok',
    );
}

print "<P></P>";
##########################################
## Check for system configuration file ##
##########################################

=cut
if (-e $system_config) { 
    print $BS->modal(
        -label=> $BS->icon('check') . ' System Config File Found',
        -body => $Build->View->system_config(-map=>\%system_map, -Config=>$Config),
        -launch_type => 'button',
        -class => 'Std',
    );
   $Config->load_std_yaml_files(-system=>$system_config);
}
else {
    $validated = 0;
    print $BS->modal(
        -label=> $BS->icon('times') . ' System Config File Missing',
        -body => $Build->View->system_config(-map=>\%system_map, -update=>'update', -Config=>$Config),
        -launch_type => 'button',
        -class => 'Action',
    );
}

print "<P></P>";
=cut

##########################################
## Check for password file ##
##########################################
my $host = $Config->{config}{SQL_HOST} || $set_host;
my $dbase = $Config->{config}{DATABASE};
my $dbuser = $installer;
my $password;
my @users;

if ($q->param('Update Password file')) {
    $Build->save_password_file(-file=>$set_file, -host=>$set_host, -user=>$set_user, -pwd=>$set_pwd, -confirm=>$set_confirm);
}

try_system_command("chmod 660 $password_file");  ## confirm this file is globally NOT readable

my $message;
if (-e $password_file) { 
    $message .= "Password File found.";
    $password = `grep "^$host:$dbuser" $password_file`;
    $password =~s/^$host:$dbuser:(\S+).*$/$1/xms;
}
else {
    $message .= "Password File NOT found."
}

if ( ! $password ) { 
    $dbuser = $root_user;
    
    $password = `grep "^$host:$dbuser" $password_file`;
    $password =~s/^$host:$dbuser:(\S+).*$/$1/xms;
}

if ($password) {
    $message .= " [user: $dbuser]";
    my @passwords = split "\n", `grep ^$host: $password_file`;
    foreach my $pwd (@passwords) { 
        if ($pwd =~/^$host\:(\w+)\:/) { push @users, $1 }
    }

    my $list = "User list for $host (in $password_file):<P>" . Cast_List(-list=>\@users, -to=>'OL');
    print $BS->modal(
        -label=> $BS->icon('check') . $message,
        -body => $list,
        -launch_type => 'button',
        -class => 'Std',
    );
}
else {
    $validated = 0;
    print $BS->modal(
        -label=> $BS->icon('times') . $message . " (failed to find $installer or $root_user on $host in $password_file)",
        -body => $Build->View->update_password_file(-file=>$password_file, -host=>$host, -user=>$dbuser),
        -launch_type => 'button',
        -class => 'Action',
    );        
}

print "<P></P>";
##########################################
## Check database connection ##
##########################################

my $dbc;

print $BS->message("Connection: Host = $host; Dbase = $dbase; User = $dbuser");

if (!$host || !$dbase || !$dbuser) {
    $validated = 0;
    print $BS->modal(
        -label=> $BS->icon('times') . ' Database Connection Test Failed',
        -body => "<P>Missing Information:<P>Host: $host<P>Database: $dbase<P>User: $dbuser<P>Users Defined in Password File: " . int(@users),
        -launch_type => 'button',
        -class => 'Action',
    ); 
}
else {    
    $dbc = new LampLite::DB(
        -dbase              => $dbase,
        -host               => $host,
        -connect            => 0,
        -defer_messages     => 1,
        -config => $Config->{config},
    );
    
    $dbc->connect( -user => $dbuser, -login_file=>$password_file);
    
    if ($dbc->{connected}) {
        print $BS->modal(
            -label=> $BS->icon('check') . " Database Connection Test OK - Logged in as $dbuser",
            -body => "<P>Host: $host<P>Database: $dbase<P>Connected: " . $dbc->{connected},
            -launch_type => 'button',
            -class => 'Std',
        );
    }
    else {
        $validated = 0;
        print $BS->modal(
            -label=> $BS->icon('times') . ' Database Connection Test Failed',
            -body => "<P>Could not connect<P>Host: $host<P>Database: $dbase<P>User: $dbuser<P><P>(Also verify password in $password_file for this host/user)",
            -launch_type => 'button',
            -class => 'Action',
        );        
    }
}   

if ($q->param('Update Password file')) {
    $Build->update_access_settings(-dbc=>$dbc, -password_file=>$password_file, -users=>[$installer], -grant=>'ALL', -dbase=>'%');
}

try_system_command("chmod 660 $password_file");  ## confirm this file is globally NOT readable
$Build->dbc($dbc);

print "<P></P>";
################################
## Check database Core Status ##
################################
my $path = $FindBin::RealBin . "/../install/data";
$path =~s/\s//g;

if ($q->param('Rebuild Core')) {
    
    my $on_duplicate = $q->param('On_Duplicate');
    my ($skip, $overwrite);
    if ($on_duplicate =~/Overwrite/) { $overwrite = 1 }
    else { $skip = 1 }

    my $schema = $q->param('Schema');
    my $data = $q->param('Data');
    
    if ($schema) { $Build->rebuild_core(-dbc=>$dbc, -user=>$dbuser, -host=>$host, -password=>$password, -dbase=>$dbase, -sections=>\@sections, -path=>$path, -include=>'sql', -skip=>$skip, -overwrite=>$overwrite) }
    if ($data) { $Build->rebuild_core(-dbc=>$dbc, -user=>$dbuser, -host=>$host, -password=>$password, -dbase=>$dbase, -sections=>\@sections, -path=>$path, -include=>'txt', -skip=>$skip, -overwrite=>$overwrite) }
}

my @tables;
if ($dbc->{connected}) {
    ## Update Core Schema if DBC is established ##
    @tables = $dbc->dbh->tables;
}
   
my @sections = split "\n", `ls $path/`; 
if (int(@tables) && $dbc->table_loaded('DBField')) {
    print $BS->modal(
        -title=>'Database Schema',
        -label=> $BS->icon('check') . ' Database Schema Defined',
        -body => $Build->View->show_tables($dbc) . '<HR>' . $Build->View->update_schema_prompt(-host=>$host, -dbase=>$dbase, -sections=>\@sections),
        -launch_type => 'button',
        -class => 'Std',
    );
}
else {
    $validated = 0;
    my $fback = "Existing Tables:";
    if (int(@tables)) { $fback .= Cast_List(-list=>\@tables, -to=>'UL') }
    else { $fback .= ' [none]'}
    $fback .= "<P></P>\n";
          
    print $BS->modal(
        -title=>'Build Database Schema',
        -label=> $BS->icon('times') . ' Database Schema Incomplete',
        -body => $Build->View->show_tables($dbc) . '<HR>' . $Build->View->update_schema_prompt(-host=>$host, -dbase=>$dbase, -sections=>\@sections),
        -launch_type => 'button',
        -class => 'Action',
    );
    
}

print "<P></P>";
################################
## Check User Access Settings ##
################################
if ($q->param('Update Access Settings')) {
    my $password_file = $q->param('Password File');
    my @missing = $q->param('Missing');
    
    my $rebuild = $q->param('Regenerate Existing User Records');
    
    $Build->update_access_settings(-dbc=>$dbc, -password_file=>$password_file, -dbase=>$dbase, -users=>\@missing, -rebuild=>$rebuild);
}

my @tables;
if ($dbc && $dbc->{connected} && $dbc->table_loaded('DB_Login')) {

    my ($ok, $message, $missing) = $Build->confirm_access_settings(-dbc=>$dbc, -Config=>$Config, -password_file=>$password_file);
    
    if ($ok) {
        print $BS->modal(
            -label=> $BS->icon('check') . ' Access Permissions Updated',
            -body => $message,
            -launch_type => 'button',
            -class => 'Std',
        );
    }
    else {
        $validated = 0;
        print $BS->modal(
            -label=> $BS->icon('times') . ' Access Permissions Incomplete',
            -body => $Build->View->update_access(-file=>$password_file, -host=>$host, -users=>$missing),
            -launch_type => 'button',
            -class => 'Action',
        );    
    }
}

print "<P></P>";
##################################
## Filesystem Directories Setup ##
##################################
my ($message, $update);
if ($q->param('Update File System Directories')) {
    $setup = 1;    
}
my $web_root = $Config->{config}{web_root};
my $data_root  = $Config->{config}{data_root};

my ($fs_ok, $message) = $Build->filesystem_check(-dbc=>$dbc, -data_root=>$data_root, -web_root=>$web_root, -setup=>$setup, -file=>$filesystem_file);

my $root;
if ($Build->{root_directories}) {
    $root .= "<U>Root Directories Defined</U>:<P>";
    foreach my $dir (@{$Build->{root_directories}}) {
        $root .= "<font color='red'>$dir</font>: " . $dbc->config($dir) . '<BR>';
    }
}

my @tables;
if ( $fs_ok ) {
    $root .= "<P><i>(These should be defined in advance by root<BR>with permissions granted to web user to enable creation of subdirectories)</i><P>";
    
    print $BS->modal(
        -label=> $BS->icon('check') . ' Filesystem Directories Setup',
        -body => "$root <HR> $message",
        -launch_type => 'button',
        -class => 'Std',
    );
}
else {
    $validated = 0;
    $root .= "(These should be defined in advance by root with permissions granted to web user to enable creation of subdirectories)<P>";
    
    print $BS->modal(
        -label=> $BS->icon('times') . ' Filesystem Directories NOT Setup',
        -body => $Build->View->filesystem_update() . "$root <HR> $message",
        -launch_type => 'button',
        -class => 'Action',
    );    
}
 
print "<P></P>"; 
### Validation Status ###
if ($validated) {
    print $BS->success("Setup Validation Passed");
}
else {
    print $BS->error("Setup Incomplete");
}

print $Build->View->test('Re-Test');

print $BS->close();

print LampLite::HTML::uninitialize_page();

exit;




