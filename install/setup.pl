#!/usr/local/bin/perl

use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Core/";
use lib $FindBin::RealBin . "/../lib/perl/Plugins/";
use lib $FindBin::RealBin . "/../lib/perl/Imported/";
use Data::Dumper;
use Cwd qw(abs_path cwd);
use RGTools::RGIO;
use SDB::CustomSettings;
use SDB::Installation;
use XML::Simple;
use File::Find;

my @directories;
my %links;
my %directory_permissions;
my %core_settings;
my @Errors;
my @main_fields = ( 'DATABASE', 'SQL_HOST', 'URL_domain', 'custom', 'version_name');
my $personalize_file = $FindBin::RealBin . "/../conf/personalize.conf";

my $continue = 'y';

create_conf_file();
SDB::CustomSettings::_load_custom_config();
SDB::CustomSettings::_load_non_custom_config
%Configs= %{SDB::CustomSettings::_combine_configs()};
my $network_dir = $Configs{Home_dir};
my $data_dir = $Configs{Data_home_dir};
prompt_install();
Message "goodbye!";
exit;

#######################
sub create_conf_file {
#######################
    my $conf_file = get_personalize_file();
    my $file_content = get_file_content(-hash => $conf_file);
    write_conf_file (-content => $file_content, -file => $personalize_file);
    return;
}

####################
sub write_conf_file {
####################
    my %args    = filter_input( \@_ );
    my $content = $args{-content};
    my $file    = $args{-file};

    open my $TEMP, '>', $file or die "CANNOT OPEN $file";

    my $command  = "echo '$content' >> $file ";
    my $response = try_system_command($command);
    Message $response if $response;

    close $TEMP;
    return;
}

####################
sub get_file_content {
####################
    my %args    = filter_input( \@_ );
    my $content = $args{-hash};
    my @types  = ('database','database','web','web','web','web' );
    my %content = %$content if $content;
    my $index;

    my $file = "<configs>\n";
    for my $item (@main_fields) {
        my $type= $content{$item}{type} || $types[$index];
        $file .= "  <" . $item . ' default="' . $content{$item}{default} . '" type="' .$type . '" value="' . $content{$item}{value} . '" />' . "\n";
        $index ++;
    }
    $file .= "</configs>";
    return $file;
}

#######################
sub get_personalize_file {
#######################
    my %personalize_configs;
    if (-e $personalize_file){
        Message "found it";
        my $data = XML::Simple::XMLin("$personalize_file");
        %personalize_configs = %{$data};
    }
    
    for my $entry (@main_fields){
        my $value = $personalize_configs{$entry}{value};
        my $result;
        if ($value){
            $result = Prompt_Input( -prompt => "$entry is set to $value (Press ENTER if correct or new value)" );
        }
        else {
            my $cont=1;
            while ($cont){
                $result = Prompt_Input( -prompt => "Please enter value for $entry [MANDATORY]" );
                if ($result){$cont =0}
            }
        }
        if ($result){
            $personalize_configs{$entry}{value} = $result;
        }        
    }
    return \%personalize_configs;
}

#######################
sub create_network_directories {
#######################
    my $test ;
    my @dirs = get_network_directories(-path => );
    for my $dir (@dirs){
        my $command = "mkdir $dir";
        my $result = try_system_command($command) unless $test;
        push @Errors, $result if $result;
        print "."; 
    }
    Message "\nNetwork directories installed."
}

#######################
sub get_network_directories {
#######################
    my @dirs =  (
        "$Configs{Web_home_dir}",
        "$Configs{Home_dir}/software",
        "$Configs{Web_home_dir}/SDB",
        "$Configs{Web_home_dir}/SDB/cgi-bin",
        "$Configs{URL_dir}",
        "$Configs{URL_dir}/test",
        "$Configs{session_dir}",
        "$Configs{Web_log_dir}",
        "$Configs{uploads_dir}",
        "$Configs{pending_sequences}",
        "$Configs{URL_temp_dir}",
        "$Configs{URL_cache}",
        "$Configs{URL_cache}/Q20_Distributions" ,
        "$Configs{URL_cache}/Q20_Distributions/Projects", 
        "$Configs{URL_cache}/backups" ,
        "$Configs{URL_cache}/backups/All_Statistics", 
        "$Configs{URL_cache}/backups/ChemistryInfo",
        "$Configs{URL_cache}/backups/Last24Hours_Statistics",
        "$Configs{URL_cache}/backups/Params" ,
        "$Configs{URL_cache}/backups/Project_Stats" ,
        "$Configs{URL_cache}/backups/Run_Statistics", 
        "$Configs{URL_cache}/backups/Statistics" ,
        "$Configs{URL_cache}/backups/Total_Statistics"  ,
        "$Configs{URL_cache}/Project_Stats" ,
        "$Configs{URL_cache}/Project_Stats/All" ,
        "$Configs{URL_cache}/Project_Stats/Production",
        "$Configs{URL_cache}/Project_Stats/Test" ,
        "$Configs{Home_dir}/versions/alpha",
        "$Configs{Home_dir}/versions/beta",
        "$Configs{Home_dir}/versions/test",
        "$Configs{Home_dir}/versions/last",
        "$Configs{Home_dir}/versions/lims_2_6"        
        );

    return @dirs;
}

#######################
sub get_network_links {
#######################
    my %links =  (
        "$Configs{URL_dir}/cron_stats"  => "$Configs{process_monitor_log_dir}/stats/",
        "$Configs{URL_dir}/data_home"   => "$data_dir",
        "$Configs{URL_dir}/project"     => "$Configs{project_dir}",
        "$Configs{run_maps_dir}"        => "/home/sequence/alDente/run_maps/",
        "$Configs{URL_dir}/share"       => "$Configs{share_dir}",
        "$Configs{upload_template_dir}" => "$Configs{Home_private}/Upload_Template",
        "$Configs{views_dir}"           => "$Configs{Home_public}/views",
        "$Configs{manifest_logs}"       => "$Configs{public_log_dir}/shipping_manifests/",
        "$Configs{shipment_logs}"       => "$Configs{Data_log_dir}/shipments/",
        "$Configs{tag_validation_dir}"  => "$Configs{Data_log_dir}/tag_validation/",
        "$Configs{Web_home_dir}/cgi-bin"  => "/opt/alDente/versions/alpha/install/../cgi-bin/",
        "$Configs{Web_home_dir}/htdocs"  => "/opt/alDente/versions/alpha/install/../www/",
        "$Configs{Home_dir}/versions/production"  => "$Configs{Home_dir}/versions/lims_2_6",
        "$Configs{Home_dir}/software/sequencing"  => "$Configs{Home_private}/sequencing_software/",
        
    );
    
    return %links;
}

#######################
sub create_network_links {
#######################
    my $test ;
    my %links = get_network_links( );
    for my $link (keys %links){
        my $command = "ln -s  $links{$link} $link";
        my $result = try_system_command($command) unless $test;
        push @Errors, $result if $result;
        print '.';
    }
    Message "\nNetwork links installed."
}

#######################
sub change_network_permissions {
#######################
    my $test ;
    my %perms = get_network_permissions( );
    for my $permission (keys %perms){
        my $command = "chmod  $perms{$permission} $permission";
        my $result = try_system_command($command) unless $test;
        push @Errors, $result if $result;
        print ".";
    }
    Message "\nNetwork permissions changed."
}

#######################
sub get_network_permissions {
#######################
    my %subdirectories_permission = (
         "$Configs{Web_home_dir}"               =>   775 ,
         "$Configs{Home_dir}/software"          =>   775 ,
         "$Configs{Home_dir}/www/SDB"           =>   777 ,
         "$Configs{Home_dir}/www/SDB/cgi-bin"   =>   777 ,
         "$Configs{URL_dir}"                    =>   777 ,
         "$Configs{URL_dir}/test"               =>   777 ,
         "$Configs{session_dir}"                =>   777 ,
         "$Configs{Web_log_dir}"                =>   777 ,
         "$Configs{uploads_dir}"                =>   777 ,
         "$Configs{pending_sequences}"          =>   777 ,
         "$Configs{URL_temp_dir}"               =>   777 ,
         "$Configs{URL_cache}"                  =>   777 ,
         );
}

#######################
sub initialize_mysql_users {
#######################
    my $password =  Prompt_Input(-prompt=>'MySQL Password for root user',-type=>'password');
    my $host = $Configs{SQL_HOST};
    my %mysql_login = ( host        => $host,
                        database    => 'mysql',
                        user        => 'root',
                        password    => $password );

	SDB::Installation::initialize_mysql_db (-login => \%mysql_login );
     
    return;
}


#######################
sub prompt_install {
#######################
    my $answer ;
    Message "=============================================";
    Message "1. A New LIMS Installation";
    Message "2. Server Installation";
    Message "=============================================";
    if ($answer =~ /1|2/i){
        Message "You have chosen to exit";
        exit;
    }
    
    $answer = Prompt_Input( -prompt => "Please select one" , -type => 'char');
    if ($answer =~ /1/i){
        $answer = Prompt_Input( -prompt => "Do you wish to create data home directory?" , -type => 'char');
        if ($answer =~ /y/i){
            Message "This part is under construction!!";
        }
    }
    
    Message "=============================================";
    Message "Confirm network directory: $network_dir";
    Message "Confirm data home directory: $data_dir";
    Message "=============================================";
    $answer = Prompt_Input( -prompt => "(Y/N)" , -type => 'char');
    if ($answer =~ /y/i){
        $answer = Prompt_Input( -prompt => "Create network directories? (Y/N)" , -type => 'char');
        if ($answer =~ /y/i){
            create_network_directories();
        }
        $answer = Prompt_Input( -prompt => "Create network links? (Y/N)" , -type => 'char');
        if ($answer =~ /y/i){
            create_network_links();
        }    
        $answer = Prompt_Input( -prompt => "Change network permissions? (Y/N)" , -type => 'char');
        if ($answer =~ /y/i){
            change_network_permissions();
        }   
    }

    $answer = Prompt_Input( -prompt => "Insert LIMS MySQL users? (Y/N)" , -type => 'char');
    if ($answer =~ /y/i){
        initialize_mysql_users();
    }

    return;



} 



