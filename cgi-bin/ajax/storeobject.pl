#!/usr/local/bin/perl

use strict;
use Data::Dumper;
use CGI qw(:standard -debug);
use CGI::Carp('fatalsToBrowser');

use FindBin;
use lib $FindBin::RealBin . "/../../lib/perl";
use lib $FindBin::RealBin . "/../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../lib/perl/Imported";

use SDB::DBIO;
use SDB::CustomSettings;
use SDB::Session;
use RGTools::RGIO;

use alDente::Config;
######################
## Generate Configs ##
######################
use YAML;
my $conf_dir = $FindBin::RealBin . "/../../conf";
my $init_config = YAML::LoadFile("$conf_dir/personalize.cfg");

my $custom        = $init_config->{custom};

my $system_config = YAML::LoadFile("$conf_dir/system.cfg");
my $custom_config = YAML::LoadFile("$conf_dir/../custom/$custom/conf/system.cfg");
my $configs       = LampLite::DB::merge_configs( [ \%Configs, $init_config, $system_config, $custom_config] );
SDB::CustomSettings::load_config($configs);
alDente::Config->load_barcode_prefixes($custom_config);
#######################

my $q = CGI->new();
print $q->header(-type=>'text/html');

my $formname    = param('Form');
my $dbase       = param('Database') || $configs->{'DATABASE'};
my $host        = param('Database_host')  || $configs->{'SQL_HOST'};
my $user_id     = param('User_ID');  ## only for testing ... 
my $jsobj       = param('Data');
my $sess        = param('Session');


### Generate / Track Session ###
use alDente::Session;
my $session_dir = $configs->{session_dir}; ##  || '/opt/alDente/www/dynamic/sessions';
my $version     = $init_config->{version_name};

my $session = new alDente::Session( 'id:md5', $q, { Directory => "$session_dir/$version/$dbase" } );
$session->param( 'PID', $$ );

$dbase ||= $session->param('dbase');
$host ||= $session->param('host');

my $sid = $session->validate_session();                                                                                 ## check for expired session ##
`CHMOD 660 $session_dir/$version/$dbase/cgisess_$sid`;

#################################
my $user     = $session->param('user');
$user_id ||=  $session->param('user_id');

if (!$formname || ! $user_id) { print "Error in storeobject" }

my $dbc = SDB::DBIO->new(-host=>$host, -dbase=>$dbase, -user=>'internal', -config=>$configs, -connect=>1, -quiet=>1);

require alDente::Employee;
my $USER = alDente::Employee->new(-dbc=>$dbc,-id=>$user_id);
$USER->define_User();         ## update connection attributes with this specific user ##

if($dbc->check_permissions($user_id,$formname,'append')) {

    use JSON;
    #            print Dumper($jsobj);
    my $data = jsonToObj($jsobj);
    #            my %obj;
    #
    #            delete $jsobj->{DBForm};
    #            $obj{0}{form_name} = $formname;
    #            foreach (keys %{$jsobj}) {
        #                $obj{0}{fields}{$_} = $jsobj->{$_};
        #            }

    $data = &SDB::DB_Form::conv_FormNav_to_DBIO_format(-data=>$data);
    my $result = $dbc->Batch_Append(-data=>$data,-quiet=>1);

    my @new = %{$result};
    if (int(@new) == 2) {
        my $a = $dbc->get_FK_info($new[0],$new[1]);
        if($a =~ /\w+/) {
            print $a;
        } 
        else {
            print "Error: Problems storing the object!";
        }
    } 
    else {
        ### <CONSTRUCTION> submit issue automatically...
        print 'Error: ' . Dumper($result);
    }
} 
else {
    print "Error: Permission denied. Please contact a LIMS Administrator";
}
$dbc->disconnect();

exit;

