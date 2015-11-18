#!/usr/bin/perl

use strict;
use CGI qw/:standard/;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Core/";
use lib $FindBin::RealBin . "/../lib/perl/Imported/";

use Data::Dumper;
use Cwd 'abs_path';

use SDB::CustomSettings qw($config_dir $Sys_config_file);
use alDente::SDB_Defaults;
use RGTools::RGIO;

use XML::Dumper;
my $debug = 0; # prints out all params and their values

##########Global variables############
my %_Configs;
my %_Dir_Configs; 
my %_Db_Configs;
my %_Web_Configs;
my %_Tracking_Configs;
my %_Custom_Configs;
my %_Subdirs;
my %_Perm0777;
my %_Perm0774;
my %_Perm0770;
my $_Current_Dir;
######################################

##########Main body###################
#Get current directory of the install.pl
if (-l $0) {
    #if the file name is indeed a symlink then need to dereference.
    my $realfile = readlink $0;
    $realfile =~ /^(.*)\//;
    $_Current_Dir = $1;
}
elsif ($0 =~ /^(.*)\//) {
    $_Current_Dir = $1;
}
else {
    $_Current_Dir = cwd();
}
$config_dir = abs_path("$_Current_Dir/../conf");
$_Current_Dir = abs_path ($_Current_Dir);

_main();
######################################

#######################
sub _main {
#######################
#
#The main menu of the script.
#
    
    ###Load the configurations###
    unless (-f $Sys_config_file) {
        #If not found, then create one with default configurations.
	_set_configs('default');
    }
    %_Configs = %{xml2pl("$Sys_config_file")};
    
    #Initialize the settings
    _init_settings();
    
    print header;
    print start_html("alDente installation");
    if ($debug){ 
        print "PARAMS:<FONT size='-2'>",br;
        foreach my $name (param()) {
            my $value = param($name);
            my $values = join ',', param($name);
            print "$name = $values",br;
        }
        print "</FONT>",br;
    }

    print hr;
    print h1("Please choose an option");
    print start_form;	
    my %labels = (
            install => 'Install with current system configurations',
            display => 'Display current system configurations',
            edit => 'Change system configurations',
            restore => 'Restore default system configurations',
            exit => 'Exit installation',
        );
    print radio_group (-name=>'main_menu',-values=>['install','display','edit','restore','exit'],
                       -labels=>\%labels,-default=>'display',-linebreak=>'true');

    print submit(-label=>"Proceed");
    print hr;
    
    if (param('main_menu') =~ /install/i) {
        _prompt_user();
        _install();
            
    } elsif (param('main_menu') =~ /display/i) {
        _display_configs();
    } elsif (param('main_menu') =~ /edit/i) {
        _change_configs();
        
        if (param('action') =~ /save/i){
            _write_changes();
        } 
    } elsif (param('main_menu') =~ /restore/i) {
        print "Do you really want to restore the default system configuration?";
        print radio_group(-name=>'restore_confirm',
                   -values=>['yes','no'],
                   -default=>'no')."&nbsp&nbsp";
        print submit(-label=>"OK");
        if (param('restore_confirm') =~ /yes/i) {
            _set_configs('default');
            print br,"Default system configurations restored.",hr;
        }
    } elsif (param('main_menu') =~ /exit/i) {
        exit 1;
    }

    print end_form; 
}

######################
sub _prompt_user{
######################
#
#Install alDente onto the system.
#

    print "<TABLE>";
    print "<TR>";
    print "<TD>Create directories?</TD>";
    print "<TD>".radio_group(-name=>'create_dirs',
                   -values=>['yes','no'],
                   -default=>'no')."</TD>";
    print "</TR>";
    print "<TR>";
    print "<TD>Create symbolic links?</TD>";
    print "<TD>".radio_group(-name=>'create_links',
                   -values=>['yes','no'],
                   -default=>'no')."</TD>";
    print "</TR>";
    print "<TD>Change directory permissions?</TD>";
    print "<TD>".radio_group(-name=>'change_permisions',
                   -values=>['yes','no'],
                   -default=>'no')."</TD>";
    print "</TR>";
    print "<TR>";
    print "<TD>Create production database: $_Configs{DATABASE} on $_Configs{SQL_HOST}?</TD>";
    print "<TD>".radio_group(-name=>'create_db',
                   -values=>['yes','no'],
                   -default=>'no')."</TD>";
    print "</TR>";

    #Generating any necessary color maps and the RunStats data...
    print "<TR>";
    print "<TD>Generate colour maps and update the RunStats table?</TD>";
    print "<TD>".radio_group(-name=>'generate_maps',
                   -values=>['yes','no'],
                   -default=>'no')."</TD>";
    print "</TR>";

    #Generating files in cache folder...
    print "<TR>";
    print "<TD>Generate files in the cache folder?</TD>";
    print "<TD>".radio_group(-name=>'generate_files',
                   -values=>['yes','no'],
                   -default=>'no')."</TD>";
    print "</TR>";
    #Other instructions...
    #print "------------------------------------------------------------------------------------\n";
    #print "The following will have to be done manually before alDente is ready to be used:\n";
    #print "------------------------------------------------------------------------------------\n";
    #print "1)Create the production database on the database server if you haven't created.\n";
    #print "2)Configure the web server and set up the necessary aliases.\n";
    #print "3)Setup crontab.\n";
    print "</TABLE>";
    print submit(-name=>"Install");
}
######################
sub _install {
######################
#
#Install alDente onto the system.
#
    if (param("create_dirs") =~ /yes/i){
        #Create the directories...
        print hr,"Creating directories...",hr;
        foreach my $dir_config (sort { $a <=> $b } keys %_Dir_Configs) {
            my $dir = $_Dir_Configs{$dir_config};
            _create_dir($_Configs{$dir});
        }
        foreach my $subdir (sort { $a <=> $b } keys %_Subdirs) {
            _create_dir($_Subdirs{$subdir});
        }
    }
    if (param("create_links") =~ /yes/i){
        #Create the symlinks...
        print hr,"Creating symbolic links...",hr;
        _create_symlink("$_Current_Dir/../cgi-bin/",$_Configs{Web_home_dir} . "/cgi-bin");
        _create_symlink("$_Current_Dir/../www/",$_Configs{Web_home_dir} . "/htdocs");
        _create_symlink($_Configs{Data_home_dir},$_Configs{URL_dir} . "/data_home"); 
        _create_symlink($_Configs{project_dir},$_Configs{Home_public} . "/Projects"); 
    }
    if (param("change_permisions") eq 'yes'){
        #Change permissions...
        print hr,"Changing permissions to 0777...",hr;
        foreach my $perm (sort { $a <=> $b } keys %_Perm0777) {
            my $target = $_Perm0777{$perm};
            _change_permission(0777,$_Configs{$target});
        }
        print hr,"Changing permissions to 0774...",hr;
        foreach my $perm (sort { $a <=> $b } keys %_Perm0774) {
            my $target = $_Perm0774{$perm};
            _change_permission(0774,$_Configs{$target});
        }
        print hr,"Changing permissions to 0770...",hr;
        foreach my $perm (sort { $a <=> $b } keys %_Perm0770) {
            my $target = $_Perm0770{$perm};
            _change_permission(0770,$_Configs{$target});
        }
    }
    #Create a skeleton sequence database...
    if (param("create_db") eq 'yes'){
        print "DATABASE CREATION:",br;
        _create_database();
    }

    #Generating any necessary color maps and the RunStats data...
    if (param("generate_maps") eq 'yes'){
        my $command = "$_Current_Dir/../bin/update_sequence.pl -A colour,stats > " . $_Configs{Web_log_dir} . "/update_sequence.log";
        print hr,"Generating colour maps and updating the RunStats table...",br;
        print "Executing command: $command...",hr
        try_system_command($command);
        print "Finished generating colour maps and updating the RunStats table.";
    }

    #Generating files in cache folder...
    if (param("generate_files") eq 'yes'){
        my $command = "$_Current_Dir/../bin/update_Stats.pl -A -Q > " . $_Configs{Web_log_dir} . "/update_Stats.log";
        print hr,"Generating files in the cache folder...",br;
        print "Executing command: $command...",hr;
        try_system_command($command);
        print "Finished generating files in the cache folder.";
    }

    #Other instructions...
    #print "------------------------------------------------------------------------------------\n";
    #print "The following will have to be done manually before alDente is ready to be used:\n";
    #print "------------------------------------------------------------------------------------\n";
    #print "1)Create the production database on the database server if you haven't created.\n";
    #print "2)Configure the web server and set up the necessary aliases.\n";
    #print "3)Setup crontab.\n";
    return;
}

#######################
sub _create_dir {
#######################
#
#Create directory.
#
    my $dir = shift;
    print "<FONT size='-2'>";

    if (-d $dir) {
	print "Directory: $dir already existed.",br;
    }
    else {
	my $ok = mkdir($dir);
	if ($ok) {
	    print "<FONT color=green>Created directory: $dir.</FONT>",br;
	}
	else {
	    print "<FONT color=red>Failed to create directory: $dir. ($!)</FONT>",br;
	}
    }
    print "</FONT>";
}

#######################
sub _create_symlink {
#######################
#
#Create symbolic link.
#
    my $target = shift;
    my $link = shift;
    print "<FONT size='-2'>";

    if (-l $link) {
	print "Symbolic link: $link already existed (cannot link to $target).",br;
    } else {
	my $ok = symlink($target,$link);
	if ($ok) {
	    print "<FONT color=green>Created symbolic link: $link -> $target.</FONT>",br;
	} else {
	    print "<FONT color=red>Failed to create symbolic link: $link -> $target.</FONT>",br;
	}
    }
    print "</FONT>";
}

#######################
sub _change_permission {
#######################
#
#Change permissions.
#
    my $mode = shift;
    my $target = shift;
    print "<FONT size='-2'>";

    if (-e $target) {
	my $ok = chmod($mode,$target);
	if ($ok) {
	    print "<FONT color=green>Changed permission of $target.</FONT>",br;
	}
	else {
	    print "<FONT color=red>Failed to change permission of $target.</FONT>",br;
	}
    }
    else {
	print "<FONT color=red>$target does not exist: Cannot change permission.</FONT>",br;
    }
    print "</FONT>";
}

########################
sub _create_database {
########################
#
#Creates a sequence database.
#
    my $table_def_file = "$_Current_Dir/sequence_table_def.sql"; #Location of the SQL file containing the table definitions.
    #my $preset_data_file = "$_Current_Dir/sequence_preset_data.sql"; #Location of the SQL file containing the table definitions.

    my $username = Prompt_Input(-prompt=>"MySQL username: ");
    my $passwd = Prompt_Input(-prompt=>"MySQL password: ",-type=>'passwd');  

    print "-------------------------------\n";
    print "Creating $_Configs{DATABASE} database on $_Configs{SQL_HOST}...\n";
    print "-------------------------------\n";
    print "Table definition file used: $table_def_file\n";

    #if ((-f $table_def_file) && (-f $preset_data_file)) {
    if ((-f $table_def_file)) {
	my $mysql_command = qq{$_Configs{mysql_dir}/mysql -u $username --password=$passwd -h $_Configs{SQL_HOST}};

	#First create the database.
	my $command = qq{$mysql_command -e 'CREATE DATABASE /*!32312 IF NOT EXISTS*/ $_Configs{DATABASE};'};
	my $feedback = try_system_command(qq{$command});
	if ($feedback) {
	    print "Error creating database: $feedback\n";
	    return;
	}
	else {
	    print "Database created.\n";
	}

	#Now create the tables.
	$command = qq{$mysql_command $_Configs{DATABASE} < $table_def_file};
	$feedback = try_system_command(qq{$command});
	if ($feedback) {
	    print "Error creating tables: $feedback\n";
	    return;
	}
	else {
	    print "Tables created.\n";
	}

	#Finally populate the tables with preset data.
	#$command = qq{$mysql_command $_Configs{DATABASE} < $preset_data_file};
        ## run upgrade_DB to populate the DBField and DBTable
	$command = "../bin/dbfield_set.pl -host $_Configs{SQL_HOST} -dbase $_Configs{DATABASE} -u $username -p $passwd";
        print "Populating DBField and DBTAble ($command)\n";
	$feedback = try_system_command(qq{$command});
	if ($feedback) {
	    print "Error inserting preset data: $feedback\n";
	    return;
	}
	else {
	    print "Preset data inserted.\n";
	}
    }
}

#########################
sub _display_configs {
#########################
# Display current system configurations
#
    ###Load the configurations###
    #%_Configs = %{xml2pl("$Sys_config_file")};

    #Initialize the settings
    #_init_settings();

    print hr,"Directory configurations:",br;
    print "<TABLE cellspacing='0' cellpadding='3' border='1'>";
    foreach my $dir_config (sort { $a <=> $b } keys %_Dir_Configs) {
	my $config = $_Dir_Configs{$dir_config};
        my $id = "$dir_config)$config";
        print "<TR>";
        print "<TD>$id</TD><TD>" . $_Configs{$config}."</TD>";
        print "</TR>";
    }
    print "</TABLE>";

    print hr,"Database configurations:",br;
    print "<TABLE cellspacing='0' cellpadding='3' border='1'>";
    foreach my $db_config (sort { $a <=> $b } keys %_Db_Configs) {
	my $config = $_Db_Configs{$db_config};
        my $id = "$db_config)$config";
        print "<TR>";
        print "<TD>$id</TD><TD>" . $_Configs{$config}."</TD>";
        print "</TR>";
    }
    print "</TABLE>";

    print hr,"Web configurations:",br;
    print "<TABLE cellspacing='0' cellpadding='3' border='1'>";
    foreach my $web_config (sort { $a <=> $b } keys %_Web_Configs) {
	my $config = $_Web_Configs{$web_config};
        my $id = "$web_config)$config";
        print "<TR>";
        print "<TD>$id</TD><TD>" . $_Configs{$config}."</TD>";
        print "</TR>";
    }
    print "</TABLE>";
    
    print hr,"Tracking configurations:",br;
    print "<TABLE cellspacing='0' cellpadding='3' border='1'>";
    foreach my $track_config (sort { $a <=> $b } keys %_Tracking_Configs) {
	my $config = $_Tracking_Configs{$track_config};
        my $id = "$track_config)$config";
        my $status = "OFF";
        if ($_Configs{$config}) {$status = "ON";}
        print "<TR>";
        print "<TD>$id</TD><TD>$status</TD>";
        print "</TR>";
    }
    print "</TABLE>";
    return;
}

##########################
sub _change_configs {
##########################
#
#Changing individual system configs.
#
    ###Load the configurations###
    #%_Configs = %{xml2pl("$Sys_config_file")};

    #Initialize the settings
    #_init_settings();

    my $ans;
    my $quit = 0;
    print hr;
    print "<TABLE border='1' cellspacing='0' cellpadding='3'>";
    foreach my $setting (sort { $a <=> $b } keys %_Custom_Configs) {
        my $config =  $_Custom_Configs{$setting}->{config};
        my $id = "$setting)$config";
        my $value; 
        if (defined param($config)){
            $value = param($config);
        } else {
            $value = $_Configs{$config};
        }
        print "<TR>";
        print "<TD>$id</TD><TD>" . textfield(-name=>$config,-default=>$value,-override=>1,-size=>100,-force=>1);
        print "</TR>";

    }
    print "</TABLE>";
    print submit(-name=>'action',-label=>"save");
    print submit(-name=>'action',-label=>"exit");
    return;
}

##########################
sub _write_changes {
##########################
#
#write system configs.
#
    foreach my $setting (sort { $a <=> $b } keys %_Custom_Configs) {
        my $config = $_Custom_Configs{$setting}->{config};
        $_Configs{$config} = param($config);
        #_set_configs();
    }
    pl2xml(\%_Configs,"$Sys_config_file");
    print ,br."Configurations saved.",hr;
    return 1;
}

#############################
sub _set_configs {
#############################
#
#Set system configurations.
#
    my @args = @_;
    my $default = grep /^default$/i, @args;

    ######################
    #Customizable configs
    ######################
    if ($default) {
	#Directory configs
	$_Configs{Home_dir}                     = "/opt/alDente"; #"/opt/alDente";
	$_Configs{Data_home_dir}                = "/home/aldente"; #"/home/sequence/alDente";
	$_Configs{Web_home_dir}                 = "/opt/alDente/www"; #/opt/alDente/www"; 
	$_Configs{mirror_dir}                   = "/home/aldente/public/mirror";
	$_Configs{java_bin_dir}                 = "/usr/local/java/j2sdk1.4.2_07/bin";
	$_Configs{archive_dir}                  = "/home/aldente/public/archive";
	$_Configs{submission_dir}               = "/home/aldente/public/submissions"; #External submission (for now let's allow user to customzie this)
	#$_Configs{protocols_dir}                = "/home/sequence/Protocols";

	#Database configs
	$_Configs{mysql_dir}                    = "/usr/bin";
	$_Configs{SQL_HOST}                     = 'limsdev01';
	$_Configs{BACKUP_HOST}                  = 'lims-dbm';
	$_Configs{DATABASE}                     = 'sequence';
	$_Configs{TEST_DATABASE}                = 'seqtest';
	$_Configs{BACKUP_DATABASE}              = 'seqlast';
	
	#Web configs
	$_Configs{jira_link}                    = "http://gin.bcgsc.ca/jira/browse/LIMS";
	$_Configs{issue_tracker}                = 'default';
	$_Configs{jira_wsdl}                    = 'http://gin.bcgsc.ca/jira/rpc/soap/jirasoapservice-v2?wsdl';
	$_Configs{URL_domain}                   = "http://limsdev01";
	$_Configs{URL_dir_name}                 = "SDB";

        #Tracking options
	$_Configs{user_tracking}                = 1;
	$_Configs{library_tracking}             = 1;
	$_Configs{department_tracking}          = 1;
	$_Configs{source_tracking}              = 1;
	$_Configs{protocol_tracking}            = 1;
	$_Configs{volume_tracking}              = 1;
	$_Configs{data_tracking}                = 1;
	$_Configs{plate_tracking}               = 1;
	$_Configs{plateContent_tracking}        = 0;
	$_Configs{QC_tracking}                  = 1;
	$_Configs{pipeline_tracking}            = 1;
    }

    #########################
    #Non-customizable configs
    #########################
    #Directory configs
    $_Configs{URL_home}                         = $_Configs{Web_home_dir};
    $_Configs{Home_private}                     = $_Configs{Data_home_dir}      ."/private";
    $_Configs{Home_public}                      = $_Configs{Data_home_dir}      ."/public";
    $_Configs{project_dir}                      = $_Configs{Home_private}       ."/Projects";
    $_Configs{Data_log_dir}                     = $_Configs{Home_private}       ."/logs";
    $_Configs{data_log_dir}                     = $_Configs{Data_log_dir};
    $_Configs{URL_dir}                          = $_Configs{Web_home_dir}       ."/dynamic";
    $_Configs{session_dir}                      = $_Configs{URL_dir}            ."/sessions";
    $_Configs{Web_log_dir}                      = $_Configs{URL_dir}            ."/logs";
    $_Configs{pending_sequences}                = $_Configs{URL_dir}            ."/logs/pending_sequences";
    $_Configs{URL_temp_dir}                     = $_Configs{URL_dir}            ."/tmp";
    $_Configs{URL_cache}                        = $_Configs{URL_dir}            ."/cache";
    $_Configs{Stats_dir}                        = $_Configs{URL_cache};
    $_Configs{Dump_dir}                         = $_Configs{Home_private}       ."/dumps";
    $_Configs{issues_dir}                       = $_Configs{Home_private}       ."/issues";
    $_Configs{work_package_dir}                 = $_Configs{Home_private}       ."/WorkPackages";
    $_Configs{inventory_dir}                    = $_Configs{Home_private}       ."/Inventory";
    $_Configs{inventory_test_dir}               = $_Configs{Home_private}       ."/Inventory/test";
    $_Configs{bulk_email_dir}                   = $_Configs{Home_private}       ."/bulk_email";
    $_Configs{sample_files_dir}                 = $_Configs{Home_private}       ."/sample_files";
    $_Configs{ttr_files_dir}                    = $_Configs{Home_private}       ."/TTR_files";
    $_Configs{temp_dir}                         = $_Configs{Home_private}       ."/temp";
    $_Configs{collab_sessions_dir}              = $_Configs{Home_private}       ."/collab_sessions_dir";
    $_Configs{run_maps_dir}                     = $_Configs{Home_private}       ."/run_maps";
    $_Configs{webver_dir}                       = $_Configs{Home_private}       ."/WebVersions";
    $_Configs{uploads_dir}                      = $_Configs{Home_public}        ."/uploads";
    $_Configs{fasta_dir}                        = $_Configs{Home_public}        ."/FASTA";
    $_Configs{vector_dir}                       = $_Configs{Home_public}        ."/VECTOR";
    $_Configs{qpix_dir}                         = $_Configs{Home_public}        ."/QPIX";
    $_Configs{multiprobe_dir}                   = $_Configs{Home_public}        ."/multiprobe";
    $_Configs{request_dir}                      = $_Configs{data_log_dir}       ."/File_Transfers";
    $_Configs{orders_log_dir}                   = $_Configs{data_log_dir}       ."/Orders";
    $_Configs{slow_pages_log_dir}               = $_Configs{data_log_dir}       ."/slow_pages";
    $_Configs{yield_reports_dir}                = $_Configs{data_log_dir}       ."/Orders/Yield_Reports";
    $_Configs{deletions_dir}                    = $_Configs{data_log_dir}       ."/deletions";
    $_Configs{affy_reports_dir}                 = $_Configs{uploads_dir}        ."/affy_reports";
    $_Configs{gel_run_upload_dir}               = $_Configs{uploads_dir}        ."/gel_run_data";
    $_Configs{qpix_log_dir}                     = $_Configs{data_log_dir}       ."/QPix_logs";
    $_Configs{cron_log_dir}                     = $_Configs{data_log_dir}       ."/cron_logs";
    $_Configs{templates_dir}                    = $config_dir                   ."/templates";
    #$_Configs{bioinf_dir}                      = $_Configs{Home_public}        ."/bioinformatics";

    #Database configs
    $_Configs{mySQL_HOST}                       = $_Configs{SQL_HOST};

    #Web configs
    $_Configs{URL_cgi_dir}                      = $_Configs{URL_home}           ."/" . $_Configs{URL_dir_name} . "/cgi-bin";
    $_Configs{URL_address}                      = $_Configs{URL_dir_name}       ."/cgi-bin";
    $_Configs{FOREIGN_KEY_POPUP_MAXLENGTH}      = 400; ### set to text field if > N
    $_Configs{RETRIEVE_LIST_LIMIT}              = 200; ### default limit on retrieved records (editing page)
    $_Configs{STD_BUTTON_COLOUR}                = 'lightgreen';
    $_Configs{EXECUTE_BUTTON_COLOUR}            = 'red';
    $_Configs{SEARCH_BUTTON_COLOUR}             = 'yellow';
    $_Configs{SCAN_BUTTON_COLOUR}               = 'violet';
    $_Configs{MESSAGE_COLOUR}                   = 'yellow';
    $_Configs{LINK_COLOUR}                      = 'blue';


    pl2xml(\%_Configs,"$Sys_config_file");
}

#########################
sub _init_settings {
#########################
#
#Intitiaze settings required for the setup.
#
    #Directory configs.
    my $i = 0;
    $_Dir_Configs{++$i} = "Home_dir";
    $_Dir_Configs{++$i} = "Data_home_dir";
    $_Dir_Configs{++$i} = "Home_private";
    $_Dir_Configs{++$i} = "Home_public";
    $_Dir_Configs{++$i} = "Web_home_dir";
    $_Dir_Configs{++$i} = "URL_home";
    $_Dir_Configs{++$i} = "URL_dir";
    $_Dir_Configs{++$i} = "URL_temp_dir";
    $_Dir_Configs{++$i} = "URL_cache";
    $_Dir_Configs{++$i} = "submission_dir";
    $_Dir_Configs{++$i} = "run_maps_dir";
    $_Dir_Configs{++$i} = "project_dir";
    $_Dir_Configs{++$i} = "mirror_dir";
    $_Dir_Configs{++$i} = "Dump_dir";
    $_Dir_Configs{++$i} = "session_dir";
    $_Dir_Configs{++$i} = "Stats_dir";
    $_Dir_Configs{++$i} = "vector_dir";
    $_Dir_Configs{++$i} = "fasta_dir";
    $_Dir_Configs{++$i} = "issues_dir";
    $_Dir_Configs{++$i} = "inventory_dir";
    $_Dir_Configs{++$i} = "inventory_test_dir";
    $_Dir_Configs{++$i} = "templates_dir";
    $_Dir_Configs{++$i} = "uploads_dir";
    $_Dir_Configs{++$i} = "webver_dir";
    $_Dir_Configs{++$i} = "multiprobe_dir";
    $_Dir_Configs{++$i} = "qpix_dir";
    $_Dir_Configs{++$i} = "Web_log_dir";
    $_Dir_Configs{++$i} = "Data_log_dir";
    $_Dir_Configs{++$i} = "qpix_log_dir";
    $_Dir_Configs{++$i} = "request_dir";
    $_Dir_Configs{++$i} = "pending_sequences";
    $_Dir_Configs{++$i} = "cron_log_dir";
    $_Dir_Configs{++$i} = "orders_log_dir";
    $_Dir_Configs{++$i} = "slow_pages_log_dir";
    $_Dir_Configs{++$i} = "deletions_dir";
    $_Dir_Configs{++$i} = "data_log_dir";
    $_Dir_Configs{++$i} = "sample_files_dir";
    $_Dir_Configs{++$i} = "ttr_files_dir";
    $_Dir_Configs{++$i} = "yield_reports_dir";
    $_Dir_Configs{++$i} = "affy_reports_dir";
    $_Dir_Configs{++$i} = "temp_dir";
    $_Dir_Configs{++$i} = "archive_dir";
    $_Dir_Configs{++$i} = "collab_sessions_dir";
    $_Dir_Configs{++$i} = "gel_run_upload_dir";
    #$_Dir_Configs{++$i} = "protocols_dir";
    #$_Dir_Configs{++$i} = "bioinf_dir";

    #Database configs.
    $i = 0;
    $_Db_Configs{++$i} = "mysql_dir";
    $_Db_Configs{++$i} = "DATABASE";
    $_Db_Configs{++$i} = "TEST_DATABASE";
    $_Db_Configs{++$i} = "BACKUP_DATABASE";
    $_Db_Configs{++$i} = "SQL_HOST";
    $_Db_Configs{++$i} = "mySQL_HOST";
    $_Db_Configs{++$i} = "BACKUP_HOST";

    #Web configs.
    $i = 0;
    $_Web_Configs{++$i} = "URL_domain";
    $_Web_Configs{++$i} = "URL_dir_name";
    $_Web_Configs{++$i} = "URL_cgi_dir";
    $_Web_Configs{++$i} = "URL_address";
    $_Web_Configs{++$i} = "FOREIGN_KEY_POPUP_MAXLENGTH";
    $_Web_Configs{++$i} = "RETRIEVE_LIST_LIMIT";
    $_Web_Configs{++$i} = "STD_BUTTON_COLOUR";
    $_Web_Configs{++$i} = "EXECUTE_BUTTON_COLOUR";
    $_Web_Configs{++$i} = "SEARCH_BUTTON_COLOUR";
    $_Web_Configs{++$i} = "SCAN_BUTTON_COLOUR";
    $_Web_Configs{++$i} = "MESSAGE_COLOUR";
    $_Web_Configs{++$i} = "LINK_COLOUR";

    #Tracking configs
    $i = 0;
    $_Tracking_Configs{++$i} = "user_tracking";
    $_Tracking_Configs{++$i} = "library_tracking";
    $_Tracking_Configs{++$i} = "department_tracking";
    $_Tracking_Configs{++$i} = "source_tracking";
    $_Tracking_Configs{++$i} = "protocol_tracking";
    $_Tracking_Configs{++$i} = "volume_tracking";
    $_Tracking_Configs{++$i} = "data_tracking";
    $_Tracking_Configs{++$i} = "plate_tracking";
    $_Tracking_Configs{++$i} = "plateContent_tracking";
    $_Tracking_Configs{++$i} = "QC_tracking";
    $_Tracking_Configs{++$i} = "pipeline_tracking";

    #Configs that are customizable.
    $i = 0;
    $_Custom_Configs{++$i}->{config} = "Home_dir";
    $_Custom_Configs{++$i}->{config} = "Data_home_dir";
    $_Custom_Configs{++$i}->{config} = "Web_home_dir";
    $_Custom_Configs{++$i}->{config} = "project_dir";
    $_Custom_Configs{++$i}->{config} = "mirror_dir";
    $_Custom_Configs{++$i}->{config} = "archive_dir";
    $_Custom_Configs{++$i}->{config} = "mysql_dir";
    $_Custom_Configs{++$i}->{config} = "java_bin_dir";
    $_Custom_Configs{++$i}->{config} = "SQL_HOST";
    $_Custom_Configs{++$i}->{config} = "BACKUP_HOST";
    $_Custom_Configs{++$i}->{config} = "DATABASE";
    $_Custom_Configs{++$i}->{config} = "TEST_DATABASE";
    $_Custom_Configs{++$i}->{config} = "BACKUP_DATABASE";
    $_Custom_Configs{++$i}->{config} = "URL_domain";
    $_Custom_Configs{++$i}->{config} = "URL_dir_name";
    #$_Custom_Configs{++$i}->{config} = "protocols_dir";
    $_Custom_Configs{++$i}->{config} = "submission_dir";
    $_Custom_Configs{++$i}->{config} = "jira_link";
    $_Custom_Configs{++$i}->{config} = "issue_tracker";
    $_Custom_Configs{++$i}->{config} = "jira_wsdl";
    $_Custom_Configs{++$i}->{config} = "user_tracking";
    $_Custom_Configs{++$i}->{config} = "library_tracking";
    $_Custom_Configs{++$i}->{config} = "department_tracking";
    $_Custom_Configs{++$i}->{config} = "source_tracking";
    $_Custom_Configs{++$i}->{config} = "protocol_tracking";
    $_Custom_Configs{++$i}->{config} = "volume_tracking";
    $_Custom_Configs{++$i}->{config} = "data_tracking";
    $_Custom_Configs{++$i}->{config} = "plate_tracking";
    $_Custom_Configs{++$i}->{config} = "plateContent_tracking";
    $_Custom_Configs{++$i}->{config} = "QC_tracking";
    $_Custom_Configs{++$i}->{config} = "pipeline_tracking";


    #Subdirectories that need to be created.
    $i = 0;
    $_Subdirs{++$i} = $_Configs{URL_cache} . "/backups";
    $_Subdirs{++$i} = $_Configs{URL_cache} . "/backups/All_Statistics";
    $_Subdirs{++$i} = $_Configs{URL_cache} . "/backups/ChemistryInfo";
    $_Subdirs{++$i} = $_Configs{URL_cache} . "/backups/Last24Hours_Statistics";
    $_Subdirs{++$i} = $_Configs{URL_cache} . "/backups/Params";
    $_Subdirs{++$i} = $_Configs{URL_cache} . "/backups/Project_Stats";
    $_Subdirs{++$i} = $_Configs{URL_cache} . "/backups/Run_Statistics";
    $_Subdirs{++$i} = $_Configs{URL_cache} . "/backups/Statistics";
    $_Subdirs{++$i} = $_Configs{URL_cache} . "/backups/Total_Statistics";
    $_Subdirs{++$i} = $_Configs{URL_cache} . "/Project_Stats";
    $_Subdirs{++$i} = $_Configs{URL_cache} . "/Project_Stats/All";
    $_Subdirs{++$i} = $_Configs{URL_cache} . "/Project_Stats/Production";
    $_Subdirs{++$i} = $_Configs{URL_cache} . "/Project_Stats/Test";
    
    # Directories/files that require change of permission to 0770.
    # read write execute for owner and group
    # no permission for others
    $i = 0;
    $_Perm0770{++$i} = "Dump_dir";
    $_Perm0770{++$i} = "issues_dir";
    $_Perm0770{++$i} = "inventory_dir";
    $_Perm0770{++$i} = "Data_log_dir";
    $_Perm0770{++$i} = "project_dir";
    $_Perm0770{++$i} = "collab_sessions_dir";

    #Directories/files that require change of permission to 0774.
    # read write execute for owner and group
    # read for others
    $i = 0;
    $_Perm0774{++$i} = "Home_private";

    # Directories/files that require change of permission to 0777.
    # Full permissions for all
    $i = 0;
    $_Perm0777{++$i} = "Web_log_dir";
    $_Perm0777{++$i} = "URL_temp_dir";
    $_Perm0777{++$i} = "URL_dir";
    $_Perm0777{++$i} = "URL_cache";
    $_Perm0777{++$i} = "run_maps_dir"; #world readable
    $_Perm0777{++$i} = "mirror_dir";
    $_Perm0777{++$i} = "session_dir";
    $_Perm0777{++$i} = "Stats_dir";
    $_Perm0777{++$i} = "vector_dir";
    $_Perm0777{++$i} = "request_dir";
    $_Perm0777{++$i} = "fasta_dir";
    $_Perm0777{++$i} = "pending_sequences";
    $_Perm0777{++$i} = "issues_dir"; 
    $_Perm0777{++$i} = "submission_dir";
    $_Perm0777{++$i} = "uploads_dir";
    $_Perm0777{++$i} = "multiprobe_dir";
    #$_Perm0777{++$i} = "protocols_dir";
    #$_Perm0777{++$i} = "bioinf_dir";
}

