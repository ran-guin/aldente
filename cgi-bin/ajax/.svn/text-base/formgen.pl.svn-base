#!/usr/local/bin/perl

use strict;
use Data::Dumper;
use CGI qw(:standard -debug);
use CGI::Carp('fatalsToBrowser');

use FindBin;
use lib $FindBin::RealBin . "/../../lib/perl";
use lib $FindBin::RealBin . "/../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../lib/perl/Plugins";
use JSON;

use SDB::DBIO;
use SDB::CustomSettings;
use SDB::HTML;
use SDB::DB_Form;
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
my $class_name  = param('Class');
my $ref         = param('Ancestors');
my $external    = param('External');

my $omit        = param('Omit');
my $grey        = param('Grey');
my $list        = param('List');

my $host        = param('Database_host');
my $dbase       = param('Database');

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
my $db_user = $session->param('db_user') || 'internal';

if(!$formname) {
    print "Error: No form name specified";
    exit;
} 
#    Message("Generating form '$formname' with class '$class_name', references: '$ref'");

    my $dbc = SDB::DBIO->new(-host=>$host, -dbase=>$dbase,-user=>$db_user, -connect=>1, -config=>$configs);
    $dbh = $dbc->connect();

    my %omit_list;
    my %grey_list;
    my %hidden_list;
    my %preset_list;


    my @form_fields = $dbc->get_fields(-table=>$formname);
    my @ref_fields;
    if($ref) {
        my @ancestors = split(',',$ref);
        foreach my $reftable (@ancestors) {
            foreach my $field (@form_fields) {
                if($field =~ /FK_$reftable\w+/) { ### Direct FK_, not any FKParent or any other links
                    push(@ref_fields,$field);
                }
                elsif ($class_name && $class_name eq $reftable && $field =~ /Object_ID/) {
                    push(@ref_fields,$field);
                }
            }
        }
        foreach my $field (@ref_fields) {
            my ($refTable,$refField) = $dbc->foreign_key_check($field);
            if($refTable && $refField) {
                if(grep(/^$refTable$/,@ancestors)) {
                    #Message("Warning: adding $field to grey");
                    $field =~ /^\w+\.(\w+) AS .*$/i;
                    $omit_list{$1} = '<' . $refTable .'.'. $refField . '>';
                }
            }
            elsif ($class_name && $field =~ /Object_ID/) {
                my ($primary_field) = $dbc->get_field_info($class_name,undef,'Primary');
                $omit_list{$field} = '<' . $class_name .'.'. $primary_field . '>';
            }
        }
    }

    foreach my $field (@form_fields) {
        $field =~ /\w+\.(\w+) AS \w+/;
        if(param($1)) {
            $preset_list{$1} = param($1);
        }
    }

    foreach(split(',',$omit)) {
        my $value = '';
        if($preset_list{$_}) {
            $value = $preset_list{$_};
            delete $preset_list{$_};
        }
        $omit_list{$_} = $value;
    }

    foreach(split(',',$grey)) {
        my $value = '';
        if($preset_list{$_}) {
            $value = $preset_list{$_};
            delete $preset_list{$_};
        }
        $grey_list{$_} = $value;
    }

    my $List = '';
    if($list) {
        $List = jsonToObj($list);
    }
    if ($formname =~ /Submission/i && ($grey_list{File_Required} =~ /yes/i || $preset_list{File_Required} =~ /yes/i) ) {
       my @instructions = ('Complete Form','Save Draft', 'Attach File', 'Complete Submission');
       Message "Note: This submission requires a file attachment";
       print Cast_List(-list=>\@instructions, -to=>'ol');
    }

    my $form = SDB::DB_Form->new(-dbc=>$dbc,-table=>$formname,-wrap=>0,-quiet=>1,-remove_table_args=>1,-external_form=>$external);
    $form->configure(-omit=>\%omit_list,-grey=>\%grey_list,-preset=>\%preset_list,-list=>$List);
    print $form->generate(-return_html=>1,-submit=>0,-navigator_on=>0);

    $dbc->disconnect();

exit;

