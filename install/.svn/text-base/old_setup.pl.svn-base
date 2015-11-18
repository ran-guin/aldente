#!/usr/local/bin/perl

use strict;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Core/";
use lib $FindBin::RealBin . "/../lib/perl/Imported/";

use Data::Dumper;
use Cwd qw(abs_path cwd);

use SDB::CustomSettings qw($config_dir $Sys_config_file %Configs_Custom $Configs_Non_Custom &_load_custom_config &_load_non_custom_config &_combine_configs &load_lims01); ## should be phased out
use SDB::Installation;
use alDente::SDB_Defaults;
use RGTools::RGIO;

use XML::Simple;
use File::Find;

use vars qw ( $opt_dbase $opt_host $opt_user $opt_pass $opt_addons $opt_installation $opt_type);
use Getopt::Long;
&GetOptions(
	    'dbase=s' => \$opt_dbase,
	    'host=s'  => \$opt_host,
	    'user=s'  => \$opt_user,
	    'password=s' => \$opt_pass,
	    'addons=s' => \$opt_addons,
	    'type=s'   => \$opt_type,
	    'installation=s' => \$opt_installation,
	    );

##########Global variables############
my %_Configs;
my %_Dir_Configs; 
my %_Db_Configs;
my %_Web_Configs;
my %_Tracking_Configs;
my %_Custom_Configs;
my %_Subdirs;
my (%_Perm0777, %_Perm0777_sub);
my (%_Perm0771, %_Perm0771_sub);
my (%_Perm0770, %_Perm0770_sub);
my (%_Perm0775, %_Perm0775_sub);

my $_Current_Dir;
my $config_dir;      ## determine this here instead of getting it from CustomSetting
my $Sys_config_file; ## determine this here instead of getting it from CustomSetting

my $count_0771 = 0; ## permission count
my $count_0770 = 0; ## permission count
my $count_0777 = 0; ## permission count
my $count_0775 = 0; ## permission count

#### Directories listed here (not included in the configs) will be created.
#### {xxx} indicates the key in %Conifgs to represent its parent directory
#### all directories will be created with the default permission
my @subdirectories = qw ({URL_cache}/Q20_Distributions {URL_cache}/Q20_Distributions/Projects {URL_cache}/backups {URL_cache}/backups/All_Statistics {URL_cache}/backups/ChemistryInfo
                        {URL_cache}/backups/Last24Hours_Statistics {URL_cache}/backups/Params {URL_cache}/backups/Project_Stats {URL_cache}/backups/Run_Statistics {URL_cache}/backups/Statistics 
                        {URL_cache}/backups/Total_Statistics  {URL_cache}/Project_Stats {URL_cache}/Project_Stats/All {URL_cache}/Project_Stats/Production {URL_cache}/Project_Stats/Test 
                        {Data_home_dir}/Trash {Data_home_dir}/Trash/GCOS_test {Data_home_dir}/Trash/GCOS_test/SampleSheets {Data_home_dir}/Trash/GCOS_test/Templates {Data_home_dir}/Trash/GCOS_test/Reports 
                        {Home_private}/Test_files {data_log_dir}/updates {public_log_dir}/API_logs {Home_public}/API_test_cases {Home_public}/reference {uploads_dir}/aborted {uploads_dir}/archive {request_dir}/rsync
			{Data_log_dir}/uploads {Data_log_dir}/shipments {Home_private}/Upload_Template {cron_log_dir}/Process_Monitor/stats);

#### specify permissions for your directories if not default
#### key: what is in @subdirectories. e.g., {URL_cache}/backups
#### value: permission. e.g., 0777
my %subdirectories_permission = (
				 '{Data_home_dir}/Trash' => '0777',
				 '{Data_home_dir}/Trash/GCOS_test' => '0777',
				 '{Data_home_dir}/Trash/GCOS_test/SampleSheets' => '0777',
				 '{Data_home_dir}/Trash/GCOS_test/Templates' => '0777',
				 '{Data_home_dir}/Trash/GCOS_test/Reports' => '0777',
				 '{Home_private}/Test_files' => '0777',
				 '{data_log_dir}/updates' => '0775',
				 '{public_log_dir}/API_logs' => '0777',
				 '{Home_public}/API_test_cases' => '0777',
				 '{uploads_dir}/aborted' => '0777',
				 '{uploads_dir}/archive' => '0777',
				 '{request_dir}/rsync' => '0766',
);

my %subdirectories_lims01      = (

);


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
$Sys_config_file = $config_dir."/system.conf"; ## figure out the system.conf path instead of getting from CustomSetting
$_Current_Dir = abs_path ($_Current_Dir);      ## this is the install directory


_main();
######################################

#######################
sub _main {
#######################
#
#The main menu of the script.
#

    print "\n========================================\n";
    print "alDente installation\n";
    print "========================================\n";

    # check if alDente has been installed before
    my $install_log = $_Current_Dir. "/\.installed"; 
    my $installed = _check_installed(-filename=>$install_log);

    if ( !$installed ) {     
        ##copy config file, then set host and db settings
        if (!(-f "$config_dir/system.conf")) {
            my $command = "cp $_Current_Dir/../template/template_system.conf $config_dir/system.conf";
            print "***System command: $command\n";
            my $feedback = try_system_command "$command";
            print "FB: $feedback\n" if $feedback;
        }
        _host_and_db_settings(-first=>1,-filename=>$install_log);
    }

    # check if any required configs are missing
    my $exclude = "Custom,Options,Plugins"; ## Determined later on in installation
    my $missing = _check_required(-exclude=>$exclude);

    while ($missing){
        print "The following required configurations are missing. Please fill in the values:\n";
        _fill_required($missing);
        $missing = _check_required(-exclude=>$exclude);
    }
    &_save_settings();

    print "All required configurations have been filled. Proceed with installation ...\n";
    &_load_custom_config();
    %_Configs = %{&_combine_configs()};


    my $choice;
    do {

        #Initialize the settings
        &_init_settings();
        &_init_subdir();

        print "-----------------------------------------\n";
        print "Please choose an option\n";	
        print "1)Install with current system configurations.\n";
        print "2)Install addons.\n";
        print "3)Display current system configurations.\n";
        print "4)Change system configurations.\n";
        print "5)Restore default system configurations.\n";
        print "6)Apply available patches.\n";
        print "7)Sync code with requirements for given database\n";
        print "8)Exit installation.\n";
        print "-----------------------------------------\n";

        $choice = Prompt_Input(-type=>'char');

        if ($choice == 1) {
            _install();
        }
        elsif ($choice ==2) {
            _add_packages();
        }
        elsif ($choice == 3) {
            _display_configs();
        }
        elsif ($choice == 4) {
            _change_configs();
        }	
        elsif ($choice == 5) {
            print "Proceed restoring default system configurations? (y/n)\n";
            my $ans = Prompt_Input(-type=>'char');
            if ($ans eq 'y') {
                _set_default_configs();
                print "Default system configurations restored.\n";
            }
        }
        elsif ($choice == 6) {
            Message "Please use install.pl as the front-end for patching the database";
        }
        elsif ($choice == 7) {
           Message "This is under construction ...";
           # _sync_modules();
        }
    } until (($choice =~ /^\d$/) && ($choice == 8))
}

######################
sub _check_installed {
######################
#
#check if alDente has been installed before
#
#e.g. my $installed = _check_installed(-filename=>'.installed');
#
    my %args = @_;
    my $filename = $args{-filename};

    if ( -e "$filename" ) { return 1; }
    else { print "No configuration log, $filename, found\n"; return 0; }

}

#######################
sub _check_required {
#######################
#
# check if any required keys are missing
#
  my %args = @_;
  my $exclude = $args{-exclude};
  my %missing_required;
  foreach my $key (keys %Configs_Custom){
      unless ($exclude =~ /\b$key\b/){
	  my $type = $Configs_Custom{$key}{type};
	  my $value = $Configs_Custom{$key}{value};
	  my $default = $Configs_Custom{$key}{default};
	  if ($value eq ''){
	      $missing_required{$key} = '';
	  }
      }
  }
  if (scalar %missing_required > 0){
    return \%missing_required;
  }else{
    return 0;
  }
}

#######################
sub _fill_required {
#######################
#
# fill requried required keys are missing
#
  my %missing_required;
  my $missing_required_ref = shift;
  if ($missing_required_ref && ref $missing_required_ref eq 'HASH'){
    %missing_required = %$missing_required_ref;
  }
  foreach my $key (keys %missing_required){
    print "\nPlease enter configuration for ($key):\n";
    my $ans = Prompt_Input();
    $Configs_Custom{$key}{value} = $ans;
  }

}

######################
sub _change_grp {
######################
#
# Change group to lims01
#

  my $type = shift; # local or net

  # load non_custom lims01 group
  my %non_custom_lims01 = %{&load_lims01()};
  my %lims01 = (%non_custom_lims01, %subdirectories_lims01);

  foreach my $dir (keys %lims01){
    my $dir_value;
    my $do;
    if ($dir =~ /{(.*)}(.*)/){

      $dir_value = $_Configs{$1}.$2;

    } elsif (exists $_Configs{$dir}) {

      $dir_value = $_Configs{$dir};

    } else{
      $dir_value = $dir;
    }

    if ($type =~ /local/i){
      if ($dir_value =~ /^\/opt/){
	$do = 1;
      }
    }elsif ($type =~ /net/i){
      if ($dir_value !~ /^\/opt/){
	$do = 1;
      }
    }

    my $command = "chgrp -R lims $dir_value";
    if ($do){
	"do command: $command\n";
      try_system_command($command);
      print "Group for $dir_value changed to lims\n";
    }
  }


}

######################
sub _init_subdir {
######################
#
# init %_Subdirs
#
  my $i = 0;
  foreach my $dir (@subdirectories){
    my $dir_value;
    if ($dir =~ /{(.*)}(.*)/){
      $dir_value = $_Configs{$1}.$2;
    }else {
      $dir_value = $dir;
    }

    $_Subdirs{$i++} = $dir_value;
    if (exists $subdirectories_permission{$dir}){
      my $permission = $subdirectories_permission{$dir};


      # Directories/files that require change of permission to 0775.
      # read write execute for owner and group
      # no permission for others
      if ($permission eq '0775'){
	$_Perm0775_sub{++$count_0775} = $dir_value;
      }

      # Directories/files that require change of permission to 0770.
      # read write execute for owner and group
      # no permission for others
      if ($permission eq '0770'){
	$_Perm0770_sub{++$count_0770} = $dir_value;
      }

      #Directories/files that require change of permission to 0771.
      # read write execute for owner and group
      # read for others
      elsif ($permission eq '0771'){
	$_Perm0771_sub{++$count_0771} = $dir_value;
      }

      # Directories/files that require change of permission to 0777.
      # Full permissions for all
      elsif ($permission eq '0777'){
	$_Perm0777_sub{++$count_0777} = $dir_value;
      }
    }

  }
}

######################  
sub _add_packages {
######################
    my %args = @_;
    my $login_ref = $args {-login};
    my $version   = $args {-version};
    my %mysql_login = %$login_ref if $login_ref;
    %mysql_login = _get_mysql_login() unless %mysql_login;
  
    my $host    = $mysql_login{host};
    my $dbase   = $mysql_login{database};
    my $user    = $mysql_login{user};
    my $pwd     = $mysql_login{password}; 
    
    my $dbc = new SDB::DBIO(-host       => $host,       -dbase      => $dbase,
                            -user       => $user,       -password   => $pwd,        -connect    => 1        );
    
    my $install = new SDB::Installation(-dbc=>$dbc, -simple =>1);
    $version   ||= $install -> get_Current_Database_Version ();
    
    my $option;
    do {
        my @packages = $install -> display_available_Package_List(-dbc=>$dbc);
        Message "Type 'q' to exit. ";
        Message "==============================================";
        $option = Prompt_Input(-prompt=>"Please enter package number to be installed ");
        my $package = $packages[$option - 1] if ($option =~ /^\d+$/);
        Message ">>>>>>> $package";
        my $parent_packages_ids_ref = SDB::Installation::get_Parent_Packages (-dbc => $dbc, -package =>$package) if $package;
        my $parent_packages_ids = join ',',@$parent_packages_ids_ref if $parent_packages_ids_ref;
        my @uninstalled = $dbc -> Table_find ('Package','Package_Name'," WHERE Package_ID IN ($parent_packages_ids) and Package_Install_Status <> 'Installed' and Package_Name <> '$package'") if $parent_packages_ids;
        if (int @uninstalled) {
            Message " The following packages need to be installed first before you can install package $package";
            for my $unistalled_package (@uninstalled) { 
                Message "- $unistalled_package " ;
            }
        }
        elsif ($package){
            Message "Installing $package ";
            $install -> install_Package (-package => $package,-version=>$version);
        }
        else {
            Message "Invalid Entry ($option)" unless ($option =~ /^q$/i );
        }

    } until ($option =~ /^q$/i );
    _upgrade_database(-version => $version,-login => \%mysql_login);
    
}

######################
sub _install {
######################
#
#Install alDente onto the system.
#
    my $ans;
    do {
        print "\nType 'p' to proceed with the installation.\n";
        print "Type 'h' for help.\n";
        print "Type 'q' to go back to the main menu.\n";
        $ans = Prompt_Input(-type=>'char');
        if ($ans eq 'p') {
            print "Create directories? (y/n)\n";
            $ans = Prompt_Input(-type=>'char');
            if ($ans eq 'y') {
                print "Create LOCAL directories? (y/n)\n";
                $ans = Prompt_Input(-type=>'char');
                if ($ans eq 'y') {
                    #Create LOCAL directories...
                    print "--------------------------\n";
                    print "Creating LOCAL directories...\n";
                    print "--------------------------\n";
                    foreach my $dir_config (sort { $a <=> $b } keys %_Dir_Configs) {
                        my $dir = $_Dir_Configs{$dir_config};			
                        _create_dir($_Configs{$dir}, 'local');
                    }
                    foreach my $subdir (sort { $a <=> $b } keys %_Subdirs) {
                        _create_dir($_Subdirs{$subdir}, 'local');
                    }

                    #Change group to lims01 if specified
                    _change_grp('local');
                }

                print "Create NETWORK directories? (y/n)\n";
                $ans = Prompt_Input(-type=>'char');
                if ($ans eq 'y') {
                    #Create NETWORK directories...
                    print "--------------------------\n";
                    print "Creating NETWORK directories...\n";
                    print "--------------------------\n";
                    foreach my $dir_config (sort { $a <=> $b } keys %_Dir_Configs) {
                        my $dir = $_Dir_Configs{$dir_config};
                        _create_dir($_Configs{$dir}, 'net');
                    }
                    foreach my $subdir (sort { $a <=> $b } keys %_Subdirs) {
                        _create_dir($_Subdirs{$subdir}, 'net');
                    }

                    #Change group to lims01 if specified
                    _change_grp('net');
                }

            }

            print "Create symbolic links? (y/n)\n";
            $ans = Prompt_Input(-type=>'char');
            if ($ans eq 'y') {
                #Create the symlinks...
                print "--------------------------\n";
                print "Creating symbolic links...\n";
                print "--------------------------\n";
                _create_symlink("$_Current_Dir/../cgi-bin/",$_Configs{Web_home_dir} . "/cgi-bin");
                _create_symlink("$_Current_Dir/../www/",$_Configs{Web_home_dir} . "/htdocs");
                _create_symlink($_Configs{share_dir}, $_Configs{URL_dir}."/share");
                _create_symlink($_Configs{Data_home_dir},$_Configs{URL_dir} . "/data_home"); 
		_create_symlink($_Configs{project_dir}, $_Configs{URL_dir} . "/project");
		_create_symlink($_Configs{Data_log_dir} . "/uploads/", $_Configs{URL_dir} . "/logs/uploads");
		_create_symlink($_Configs{cron_log_dir} . "/Process_Monitor/stats/", $_Configs{URL_dir} . "/cron_stats");
		_remove_dir($_Configs{URL_dir} . "/logs/shipments/");
		_create_symlink($_Configs{Data_log_dir} . "/shipments/", $_Configs{URL_dir} . "/logs/shipments");
		_remove_dir($_Configs{URL_dir} . "/Upload_Template/");
		_create_symlink($_Configs{Home_private} . "/Upload_Template/", $_Configs{URL_dir} . "/Upload_Template");		
            }

            print "Change directory permissions? (y/n)\n";
            $ans = Prompt_Input(-type=>'char');
            if ($ans eq 'y') {	

                print "Change LOCAL directory permissions? (y/n)\n";
                $ans = Prompt_Input(-type=>'char');
                if ($ans eq 'y') {
                    #Change permissions...
                    print "-------------------------------\n";
                    print "Changing LOCAL directory permissions to 0775...\n";
                    print "-------------------------------\n";

                    foreach my $perm (sort { $a <=> $b } keys %_Perm0775) {
                        my $target = $_Perm0775{$perm};
                        _change_permission(0775,$_Configs{$target},'local');
                    }
                    foreach my $perm (sort { $a <=> $b } keys %_Perm0775_sub) {
                        my $target = $_Perm0775_sub{$perm};
                        _change_permission(0775,$target,'local');
                    }
                    print "-------------------------------\n";
                    print "Changing LOCAL directory permissions to 0777...\n";
                    print "-------------------------------\n";

                    foreach my $perm (sort { $a <=> $b } keys %_Perm0777) {
                        my $target = $_Perm0777{$perm};
                        _change_permission(0777,$_Configs{$target},'local');
                    }
                    foreach my $perm (sort { $a <=> $b } keys %_Perm0777_sub) {
                        my $target = $_Perm0777_sub{$perm};
                        _change_permission(0777,$target,'local');
                    }
                    print "-------------------------------\n";
                    print "Changing LOCAL directory permissions to 0771...\n";
                    print "-------------------------------\n";
                    foreach my $perm (sort { $a <=> $b } keys %_Perm0771) {
                        my $target = $_Perm0771{$perm};
                        _change_permission(0771,$_Configs{$target},'local');

                    }
                    foreach my $perm (sort { $a <=> $b } keys %_Perm0771_sub) {
                        my $target = $_Perm0771_sub{$perm};
                        _change_permission(0771,$target,'local');

                    }
                    print "-------------------------------\n";
                    print "Changing LOCAL directory permissions to 0770...\n";
                    print "-------------------------------\n";
                    foreach my $perm (sort { $a <=> $b } keys %_Perm0770) {
                        my $target = $_Perm0770{$perm};
                        _change_permission(0770,$_Configs{$target},'local');
                    }
                    foreach my $perm (sort { $a <=> $b } keys %_Perm0770_sub) {
                        my $target = $_Perm0770_sub{$perm};
                        _change_permission(0770,$target,'local');
                    }
                }

                print "Change NETWORK directory permissions? (y/n)\n";
                $ans = Prompt_Input(-type=>'char');
                if ($ans eq 'y') {
                    #Change permissions...
                    print "-------------------------------\n";
                    print "Changing NETWORK directory permissions to 0775...\n";
                    print "-------------------------------\n";

                    foreach my $perm (sort { $a <=> $b } keys %_Perm0775) {
                        my $target = $_Perm0775{$perm};
                        _change_permission(0775,$_Configs{$target},'net');
                    }
                    foreach my $perm (sort { $a <=> $b } keys %_Perm0775_sub) {
                        my $target = $_Perm0775_sub{$perm};
                        _change_permission(0775,$target,'net');
                    }
                    print "-------------------------------\n";
                    print "Changing NETWORK directory permissions to 0777...\n";
                    print "-------------------------------\n";

                    foreach my $perm (sort { $a <=> $b } keys %_Perm0777) {
                        my $target = $_Perm0777{$perm};
                        _change_permission(0777,$_Configs{$target},'net');
                    }
                    foreach my $perm (sort { $a <=> $b } keys %_Perm0777_sub) {
                        my $target = $_Perm0777_sub{$perm};
                        _change_permission(0777,$target,'net');
                    }
                    print "-------------------------------\n";
                    print "Changing NETWORK directory permissions to 0771...\n";
                    print "-------------------------------\n";
                    foreach my $perm (sort { $a <=> $b } keys %_Perm0771) {
                        my $target = $_Perm0771{$perm};
                        _change_permission(0771,$_Configs{$target},'net');

                    }
                    foreach my $perm (sort { $a <=> $b } keys %_Perm0771_sub) {
                        my $target = $_Perm0771_sub{$perm};
                        _change_permission(0771,$target,'net');

                    }
                    print "-------------------------------\n";
                    print "Changing NETWORK directory permissions to 0770...\n";
                    print "-------------------------------\n";
                    foreach my $perm (sort { $a <=> $b } keys %_Perm0770) {
                        my $target = $_Perm0770{$perm};
                        _change_permission(0770,$_Configs{$target},'net');
                    }
                    foreach my $perm (sort { $a <=> $b } keys %_Perm0770_sub) {
                        my $target = $_Perm0770_sub{$perm};
                        _change_permission(0770,$target,'net');
                    }
                }
            }
            
            print "Setup mysql on $_Configs{SQL_HOST}? [say yes only if this is a new host] (y/n)\n";
            $ans = Prompt_Input(-type=>'char');
            if ($ans eq 'y') {	
                print "MYSQL INITIALIZATION:\n";
                _Initialize_mysql_users();
            }

            print "Create production or customized database: $_Configs{DATABASE} on $_Configs{SQL_HOST}? (y/n)\n";
            $ans = Prompt_Input(-type=>'char');
            if ($ans eq 'y') {	
                print "DATABASE CREATION:\n";
                _create_database();
            }

            print "Setup database replication? (y/n)\n";
            $ans = Prompt_Input(-type=>'char');
            if ($ans eq 'y') {	
                print "Setting up replication:\n";
                _setup_replication();
            }


            print "Install generic cronjobs? (rebuild backup, test, development database daily, updates code daily)\n";
            $ans = Prompt_Input(-type=>'char');
            if ($ans eq 'y') {
                print "------------------------\n";
                print "CRONTAB INSTALLATION\n";
                _generic_crontab_append();
                print "------------------------\n";
            }

            #Generating any necessary color maps and the RunStats data...
            print "Generate colour maps and update the RunStats table? (y/n)\n";
            $ans = Prompt_Input(-type=>'char');
            if ($ans eq 'y') {	
                my $command = "$_Current_Dir/../bin/update_sequence.pl -A colour,stats > " . $_Configs{Web_log_dir} . "/update_sequence.log";
                print "---------------------------------------\n";
                print "Generating colour maps and updating the RunStats table...\n";
                print "Executing command: $command...\n";
                print "---------------------------------------\n";
                try_system_command($command);
                print "Finished generating colour maps and updating the RunStats table.";
            }

            #Generating files in cache folder...
            print "Generate files in the cache folder? (y/n)\n";
            $ans = Prompt_Input(-type=>'char');
            if ($ans eq 'y') {	
                my $command = "$_Current_Dir/../bin/update_Stats.pl -A -Q > " . $_Configs{Web_log_dir} . "/update_Stats.log";
                print "---------------------------------------\n";
                print "Generating files in the cache folder...\n";
                print "Executing command: $command...\n";
                print "---------------------------------------\n";
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
            print "Completed installation procedure, go through again if you would like to change or reinstall something.\n";
            print "---------------------------------------------------------------\n";		
        }
        elsif ($ans eq 'h') {
            print "HELP!!!!!!!!!!!!!!\n";
        }
    } until ($ans eq 'q')
}

#######################
sub _Initialize_mysql_users {
#######################
    my $password =  Prompt_Input(-prompt=>'MySQL Password for root user',-type=>'password');
    my $host = $_Configs{SQL_HOST};
    my %mysql_login = ( host        => $host,
                        database    => 'mysql',
                        user        => 'aldente_admin',
                        password    => $password );

	SDB::Installation::initialize_mysql_db (-login => \%mysql_login );
     
    return;
}

#######################
sub _setup_replication {
#######################
    SDB::Installation::display_Replication_help(); 
    Message "Database to be replicated: $_Configs{BACKUP_DATABASE} ";
    Message "Master Host: $_Configs{PRODUCTION_HOST} ";
    Message "Primary Slave Host: $_Configs{BACKUP_HOST} ";
    if ($_Configs{SEC_BACKUP_HOST} ) {
        Message "Secondary Slave Host: $_Configs{SEC_BACKUP_HOST} " ;
    }
    else {
        Message "No secondary slave.  The system has two hosts only.";
    }
    my $ans = Prompt_Input(-prompt=>"Do you wish to install with these settigns?(y/n)",-type=>'char');
	if ($ans =~ /y/i) {
    	my $login_name = Prompt_Input(-prompt=>'MySQL Username');
    	my $login_pwd  = Prompt_Input(-prompt=>'MySQL Password',-type=>'password');
	    SDB::Installation::setup_DB_Replication (-user => $login_name, -password => $login_pwd, 
	                                            -test =>1,
	                                            -database => $_Configs{BACKUP_DATABASE},  -master =>  $_Configs{PRODUCTION_HOST} , -slave => $_Configs{BACKUP_HOST});
	    
	    SDB::Installation::setup_DB_Replication (-user => $login_name, -password => $login_pwd, 
                                                -database => $_Configs{BACKUP_DATABASE},  -master =>  $_Configs{PRODUCTION_HOST} , -slave => $_Configs{SEC_BACKUP_HOST}) if $_Configs{SEC_BACKUP_HOST} ;
        
	}
	else {
	    Message "You have aborted ...";
	}
}

#######################
sub _create_dir {
#######################
#
#Create directory.
#
    my $dir = shift;
    my $mode = shift;

    print "make dir: $dir, mode: $mode\n";
    my $do;
    if ($mode =~ /local/i){
      if ($dir =~ /^\/opt/){
	if (-d $dir) {
	  print "Directory: $dir already existed.\n";
	}else{
	  $do = 1;
	}
      }
    }
    elsif ($mode =~ /net/i){
      if ($dir !~ /^\/opt/){
	if (-d $dir) {
	  print "Directory: $dir already existed.\n";
	}else{
	  $do = 1;
	}
      }
    }
    
    if ($do){
      my $ok = mkdir($dir);
      if ($ok) {
	print "Created directory: $dir.\n";
      }
      else {
	print "Failed to create directory: $dir. ($!)\n";
      }
    }

}

#######################
sub _remove_dir {
#######################
#
# Remove a directory if it is empty
#
    my $dir = shift;

    if (-d $dir) {
	print "Directory: $dir exists.\n";
	my $ok = rmdir($dir);
	if ($ok) {
	    print "Removed directory: $dir.\n";
	}
	else {
	    print "Failed to remove directory: $dir. ($!)\n";
	}
    }
}

#######################
sub _create_symlink {
#######################
#
#Create symbolic link.
#
    my $target = shift;
    my $link = shift;    

    if (-l $link) {
	print "Symbolic link: $link already existed (cannot link to $target).\n";
    }
    else {
	my $ok = symlink($target,$link);
	if ($ok) {
	    print "Created symbolic link: $link -> $target.\n";
	} else {
	    print "Failed to create symbolic link: $link -> $target.\n";
	}
    }
}

#######################
sub _change_permission {
#######################
#
#Change permissions.
#
    my $mode = shift;
    my $target = shift;
    my $type = shift; # local or net


    my $do;
    if ($type =~ /local/i){
      if ($target =~ /^\/opt/){
	if (-e $target){
	  $do = 1;
	}else{
	  print "$target does not exist: Cannot change permission.\n";
	}
      }
    }elsif ($type =~ /net/i){
      if ($target !~ /^\/opt/){
	if (-e $target){
	  $do = 1;
	}else{
	  print "$target does not exist: Cannot change permission.\n";
	}
      }
    }
    if ($do){
      my $ok = chmod($mode,$target);
      if ($ok) {
	print "Changed permission of $target.\n";
      }
      else {
	print "Failed to change permission of $target.\n";
      }
    }


}

############################
sub _create_database {
############################
#
# Create a basic database
#
    my $current = _get_current_release_version();

    my %mysql_login = _get_mysql_login();
    my $host = $mysql_login{host};
    my $dbase = $mysql_login{database};
    my $username = $mysql_login{user};
    my $passwd = $mysql_login{password}; 

    my $aldente_core_init_dir = "$_Current_Dir/../install/init/release/$current/";
    my $aldente_core_init_file = $aldente_core_init_dir."/aldente_core_init.sql";

    my $build_choice;
    
    do {
	    print "===============================\n";
	    print "Database build options\n";
	    print "===== ==========================\n";
	    print "Please specify the type of database to build\n";
	    print "Choose from the following options:\n";
	    print "1) Core       (Generic laboratory data tracking)\n";
	    print "2) Add Plugins and options (Core database plus additional features)\n";
	    print "===============================\n";

	    $build_choice = Prompt_Input(-prompt=>"Enter the number corresponding to your choice\n");

    } until ( ($build_choice =~ /^\d$/) && ($build_choice <= 2) );

    if ($build_choice == 1) { ## Core-build
        print "========================\nCORE-DATABASE BUILD\n========================\n";
	    SDB::Installation::build_core_db (-version => $current,-login => \%mysql_login);

        print "========================\nUPGRADE\n========================\n";
	    _upgrade_database(-version => $current,-login => \%mysql_login);
    }
    elsif ($build_choice == 2) { ## Core-build plus interactive options
	    print "========================\nCORE-DATABASE BUILD\n========================\n";
	    SDB::Installation::build_core_db (-version => $current,-login => \%mysql_login);

        print "========================\nADD PACKAGES\n========================\n";
        _add_packages(-version => $current,-login => \%mysql_login);

	    print "========================\nUPGRADE\n========================\n";
	    _upgrade_database(-version => $current,-login => \%mysql_login);
    }
}

############################
sub _upgrade_database {
############################
    my %args = @_;
    my $login_ref = $args {-login};
    my $version   = $args {-version};
    my %mysql_login = %$login_ref if $login_ref;
        
    my $dbc = new SDB::DBIO(-host     => $mysql_login{host},
                            -dbase    => $mysql_login{database},
                            -user     => $mysql_login{user},
                            -password => $mysql_login{password},
                            -connect  => 1  );

    my $install = new SDB::Installation(-dbc=>$dbc , -simple =>1 );
    $install -> upgrade_DB (-version => $version);
    return;
    
}

##################  NEED TO INvestigate purpose and fucntionality further.
sub _sync_modules {
##################
    my %args = filter_input(\@_);
    print "Enter MySQL information about the database you wish to sync your code with\n";
    my %login = _get_mysql_login();
    my $Installation = _get_installation(-login=>\%login);
    my $dbc = $Installation->{dbc};
    my @packages = $Installation->get_installed_packages();
    Message "Packages: @packages\n";
    foreach my $package (@packages) {
	if ($dbc->table_loaded('Package')) {
	    my ($type) = $Installation->{dbc}->Table_find('Package','Package_Scope',"WHERE Package_Name = '$package'");
	    $type =~ s/Custom/custom/;
	    $type =~ s/Option/option/;
	    $type =~ s/Plugin/plugin/;
	    my %addon_info = ( name =>"$package",
			       type =>"$type",
			       );
	    _install_modules(-addon_info=>\%addon_info);
	}
    }
    
}

#####################                   MOST LIKELY SHOULD BE REMOVED
sub _get_associated_pkgs {
####################
# e.g. my ($pkg_mand_plugins_ref,$pkg_rec_plugins_ref,$pkg_mand_options_ref,$pkg_rec_options_ref) = _get_associated_pkgs(-addon=>$addon,-plugins_conf=>$plugins_conf_file,-options_conf=>$options_conf_file);

    my %args = @_;
    my $addon = $args{-addon};
    my $plugins_conf_file = $args{-plugins_conf};
    my $options_conf_file = $args{-options_conf};
    my @pkg_mandatory_plugins = ();
    my @pkg_mandatory_options = ();
    my @pkg_recommended_plugins = ();
    my @pkg_recommended_options = ();

    unless (!(-f $plugins_conf_file)) {
	@pkg_mandatory_plugins = _read_conf('mandatory','plugin',$plugins_conf_file);
	@pkg_recommended_plugins = _read_conf('recommended','plugin',$plugins_conf_file);
	unless (scalar(@pkg_mandatory_plugins) == 0) {
	    print "Mandatory plugins: ";
	    print join ",",@pkg_mandatory_plugins;
	    print "\n";
	}
	unless (scalar(@pkg_recommended_plugins) == 0){
	    print "Recommended plugins: ";
	    print join ",",@pkg_recommended_plugins;
	    print "\n";
	}
    }
    unless (!(-f $options_conf_file)) {
	push @pkg_mandatory_options, _read_conf('mandatory','option',$options_conf_file);
	unless (!@pkg_mandatory_options) {
	    print "Mandatory options: ";
	    print join(",",@pkg_mandatory_options);
	    print "\n";
	}
	push @pkg_recommended_options, _read_conf('recommended','option',$options_conf_file);
	unless (!@pkg_recommended_options) {
	    print "Recommended options: ",join/,/, @pkg_recommended_options;
	    print "\n";
	}
    }
    print "**Done packages associated with $addon\n";
    ##Configuration files has been read and parsed into appropriate arrays
    return (\@pkg_mandatory_plugins,\@pkg_recommended_plugins,\@pkg_mandatory_options,\@pkg_recommended_options);

}

####################                MOST LIKELY SHOULD BE REMOVED
sub _chk_pkg_installed {
###################

    my $pkg = shift;
    my %args = @_;
    my $Installation = $args{-installation};
 
    my $installed;

    my @installed_addons = $Installation->get_installed_packages();
    if (grep /^$pkg$/,@installed_addons) {
	$installed = 1;
    }
    else {
	$installed = 0;
    }
	
    return $installed;

}

#####################
sub _read_conf {
#e.g. my @recommended = _read_conf('recommended','plugin',$conf_file);
#also my @mandatory = _read_conf('mandatory','option',$conf_file);
 
    my $conf_type = shift; ## mandatory or recommended
    my $addon_type = shift;
    my $conf_file = shift; ## 
    my %package_standards = _get_package_standards();
    my @opt_list = ();
    if (!(-f $conf_file)) { print "Couldn't find file $conf_file\n"; return; }
    open(FILE,$conf_file);
    my $found_block;
    my $count = 0;

    do {
	my $line = <FILE> or warn "No block found for $conf_type";
	if ($line =~ /\<$conf_type\>/i) {
	    $found_block = 1;
	}
	$count++;
    } until ($found_block == 1 || $count == 30);
    my $end_block = 0;
    if ($found_block) {       
	do {
	    my $line = <FILE>;
	    chomp $line;
	    if ($line =~ /\/$conf_type\>/i) {
		$end_block = 1;
	    }
	    elsif ( $line =~ /^\s*(\w+)\s*$/ ){
		my $opt = $1;
		push @opt_list, $opt;		
	    }
	} until ($end_block == 1);
    }
    return @opt_list;

}

############################
sub _set_install_status {
##############################
# e.g. %packages = _get_install_status(\%packges);
    my %args = @_;
    my $packages_ref = $args{-packages};
    my %packages = %$packages_ref;
    my $force = $args{-force};
    my $login = $args{-login};
    my $Installation = $args{-installation} || _get_installation(-login=>$login);

    my %package_standards = _get_package_standards();
    
    my $root_dir = "$_Current_Dir/..";

    foreach my $package (keys %packages) {
        print "***";
        print "Add-on package: $package\n";
        my $type = $packages{$package}{type};
        $packages{$package}{tables_added} = 0 if ($force == 1);
        my $package_dir = "$root_dir/$package_standards{types}{$type}{base_folder}/$package";
        my $install_dir = "$package_dir/$package_standards{types}{$type}{install_folder}";
        if (-d $install_dir) { $packages{$package}{install_dir}=$install_dir; }
        my $install_file = "$install_dir/$package_standards{types}{$type}{install_file}";
        if (-f $install_file) {
            print "Found install file for $package:\n $install_file\n";
            $packages{$package}{install_file} = $install_file;
        } else {
            print "No install file found for $type $package";
            print "(looked for $install_file)\n";
            print "Will use default installation procedure instead ...\n";
        }
        if (!$force && _chk_pkg_installed($package,-installation=>$Installation)) {
            $packages{$package}{installed} = 1;
            print "$package is already installed according to the database";
        } else {
            $packages{$package}{installed} = 0;
        }
    }
    ## installed and install file entries have been updated
    return %packages;
}

##############################                MOST LIKELY SHOULD BE REMOVED
sub _make_patch_dir_softlink {
##############################
    my %args = filter_input(\@_,-mandatory=>'addon_info,installation');
    my $Installation = $args{-installation};
    my $addon_info = $args{-addon_info};
    
    my $addon_name = $addon_info->{name};

    my $base_dir = "$FindBin::RealBin/..";
    my $patches_folder = "install/patches";

    my $scope_dir = "Plugins" if ($addon_info->{type} =~ /plugin/i);
    $scope_dir = "custom" if ($addon_info->{type} =~ /custom/i);
    $scope_dir = "Options" if ($addon_info->{type} =~ /option/i);

    my $patches_base_dir = "$base_dir/$patches_folder";
    my $full_link_path = "$patches_base_dir/$scope_dir/$addon_name";

    my $relative_dir = "./../../..";
    my $full_target_dir = "$relative_dir/$scope_dir/$addon_name/$patches_folder";
    my $ans;

    return if (-l "$full_link_path");
    
    while ($ans !~ /^(y|n)$/) {
	$ans = Prompt_Input(-prompt=>"Do you wish to link $full_link_path to --> $full_target_dir?(y/n)\n");
	if ($ans eq 'y') {
	    _create_symlink("$full_target_dir","$full_link_path");
	}
    }
}

############################                MOST LIKELY SHOULD BE REMOVED
sub _update_package_record {
############################
    my %args = @_;
    my $login = $args{-login};
    my $addon_info = $args{-addon_info};
    my $check_only = $args{-check_only};

    my $Installation = $args{-installation};
    my $success;
    return 0 if (!($Installation->{dbc}->table_loaded('Package')));
    if (!($Installation->{dbc}->Table_find('Package',"Package_Name","WHERE Package_Name = '$addon_info->{name}'"))) {
	my ($newid) = $Installation->{dbc}->Table_append('Package',-fields=>"Package_Name,Package_Scope",-values=>"$addon_info->{name},$addon_info->{type}");
	$success = 1 if $newid;
    } else {
	$success = 1 if $check_only;
    }
    unless ($check_only) {
	my @update_fields = ('Package_Install_Status');
	my @update_values = ('Installed');
	my $updated = $Installation->{dbc}->Table_update(-table=>'Package',-fields=>"Package_Install_Status,Package_Active",-values=>"'Installed','y'",-condition=>"WHERE Package_Name = '$addon_info->{name}'");
	$success = 1 if $updated;
    }
    
    return $success;
}

########################                MOST LIKELY SHOULD BE REMOVED
sub _get_addon_tables {
#######################
    my %args = &filter_input(\@_,-args=>'addon_info');
    my $addon_info = $args{-addon_info};

    my @package_tables;

    my %package_standards = _get_package_standards();
    my $addon_root_folder = "$package_standards{types}{$addon_info->{type}}{base_folder}";	
    my $conf_folder = "conf";
    my $root_folder = "$_Current_Dir/..";
    my $addon_folder = "$root_folder/$addon_root_folder/$addon_info->{name}";
    my $addon_conf_folder = "$addon_folder/$conf_folder";
    my $tables_conf_file = "$package_standards{types}{$addon_info->{type}}{tables_conf}";
    my $tables_conf_full = "$addon_conf_folder/$tables_conf_file";

    print "Looking for table conf file: $tables_conf_full\n";
    open(TABLESCONF,"<$tables_conf_full") or warn "Unable to open tables config file for $addon_info->{name}\n" && return;
   foreach my $line (<TABLESCONF>) {
	next if ($line =~ /^[\s]*[\#]+/);
	chomp $line;	
	$line =~ s/^[\s]+//;
	$line =~ s/[\s]+$//;
	push @package_tables,$line;
    }

    ## tables with specified package_name have been found from master db
    return @package_tables;
}

########################                MOST LIKELY SHOULD BE REMOVED
sub _add_tables {
########################

    my %args = &filter_input(\@_,-mandatory=>'tables,to');
    my ($host,$dbase) = split ':',$args{-to};

    my $Installation = $args{-installation};

    my %package_standards = _get_package_standards();

    my @tables = @{$args{-tables}};

    my $bin_dir = "$_Current_Dir/../bin";
    my $mysql_dir = "/usr/bin";
    my $release_dir = "$_Current_Dir/../install/init/release";
    my $version = $Installation->get_db_version();
    my $full_release_dir = "$release_dir/$version";

    unless (!@tables) {
	my $sql_connect = "$mysql_dir/mysql -h $host -u super_cron -prepus $dbase";
	my $sql_connect_no_pass = "$mysql_dir/mysql -h $host -u super_cron -p<pass> $dbase";
	
	foreach my $table (@tables) {
	    my $loaded = 0;
	    if ($Installation->{dbc}->table_loaded($table)) {
		print "Table $table is already a part of the database\n";
		$loaded = 1;
	    }	    
	    next if ($loaded);
	    Message "*** Building table $table\nUsing structure from initialization folder\n";
	    my $structure_command = "$sql_connect < $full_release_dir/$table.sql";	
	    my $feedback;
	    print "STRUCTURE COMMAND: '$sql_connect_no_pass < $full_release_dir/$table.sql'\n";
	    $feedback = try_system_command("$structure_command");
	    my $data_command = "$sql_connect -e \"LOAD DATA LOCAL INFILE '$full_release_dir/$table.txt' INTO TABLE $table\"";
	    print "DATA COMMAND: $sql_connect_no_pass -e \"LOAD DATA LOCAL INFILE '$full_release_dir/$table.txt' INTO TABLE $table\"\n";
	    $feedback .= try_system_command($data_command);
	    Message "FB (from restore_DB.pl): $feedback";
	    if ($feedback !~ /Error/) {
		print "Table $table built successfully\n";
	    }
	    else { print "Error building $table\n"; }	    
	    print "-------------------------------\n";	    
	}	
    }

    return;
}

##########################                MOST LIKELY SHOULD BE REMOVED
sub _insert_patch_record {
##########################
    my %args = @_;
    my $file = $args{-file};
    my $login = $args{-login};
    my $success = $args{-success};
    my $not_hotfix = $args{-not_hotfix};
    my $Installation = $args{-installation};
    my $sqlfile = $file->{name};
    my $sql_folder = $file->{folder};
    my $version = $file->{version} || $Installation->get_db_version();  
  
    my $addon_info = $file->{addon_info};
    
    my ($date,$time) = split ' ',date_time();

    _update_package_record(-addon_info=>$addon_info,-login=>$login,-check_only=>1,-installation=>$Installation);

    my @insert_fields = ('Patch_Name','Version','Last_Attempted_Install_Date');
    my @insert_values = ("'$sqlfile'","'$version'","'$date'");

    if ($not_hotfix) {
	push @insert_fields, "Patch_Type";
	push @insert_values,"'release_time'";
    }
    if (defined $addon_info->{name}) {	
	push @insert_fields,"FK_Package__ID";
	push @insert_values,"(SELECT Package_ID FROM Package WHERE Package_Name = '$addon_info->{name}')"
    } else {      
	push @insert_fields,"FK_Package__ID";
	push @insert_values, "(SELECT Package_ID FROM Package WHERE Package_Name = 'Core')";	
    }
    if ($success) {
	push @insert_fields,"Install_Status";
	push @insert_values,"'Installed'";
    }
    
    my ($inserted) = $Installation->{dbc}->Table_append_array(-table=>'Patch',-fields=>\@insert_fields,-values=>\@insert_values);

    if (!$inserted) { print "Problem from inserting patch record:\n"; Call_Stack(); return 0;}
    else { return 1 }    

}

######################
sub _install_modules {
######################
    
    my %args = filter_input(\@_);
    my %addon_info = %{$args{-addon_info}};
    my $addon = $addon_info{name};
    my $type = $addon_info{type};
    my %package_standards = _get_package_standards();

    my %module_links;
    my $modules_conf_file = "$_Current_Dir/../$package_standards{types}{$type}{base_folder}/$addon/conf/$package_standards{types}{$type}{modules_conf}";
    unless (!(-e $modules_conf_file)) { %module_links = _get_modules_from_conf("$modules_conf_file"); }
    if (scalar(keys %module_links) == 0 ) { print "No modules found to install for $addon\n"; }
    my $conf_dir = "$_Current_Dir/../conf";
    my $modules_installed_file = "$conf_dir/.installed_modules";
    my @installed;
    if (-e "$modules_installed_file") {
        foreach my $module (keys %module_links) {
            my $feedback = try_system_command("grep '$module' $modules_installed_file");
            push @installed,$module && print "$module already installed\n" if $feedback;
        }
    }    
    foreach my $module (keys %module_links) {
	unless (-l $module_links{$module}) {
	    next if ( grep /^$module$/,@installed);
	    print "*** Creating link: $module <-- $module_links{$module}\n";
	    _create_symlink( $module, $module_links{$module});
	}
	if (-l $module_links{$module} ) {
	    open(MODINSTALLED, ">>$modules_installed_file");
	    print MODINSTALLED "$module\n" unless (try_system_command("grep '$module' $modules_installed_file"));
	    Message "Successfully made $module module softlink. Tracked in $modules_installed_file";
	    close MODINSTALLED;
	}
    }
       	
    ##soft links have been made, and tracked in $modules_installed_file    

    my $config = $package_standards{types}{$type}{config};
    my $newvalue;
    if ( (defined $_Configs{$config}) && $_Configs{$config} !~ /^\s*$/  ) {
	if (!($_Configs{$config} =~ /\b$addon\b/)) {
	    $newvalue = "$_Configs{$config},$addon";
	} else {
	    $newvalue = "$_Configs{$config}";
	}
    } else {
	$newvalue = $addon;
    }
    _change_config(-config=>$config,-value=>$newvalue) unless ($newvalue eq $_Configs{$config}); 
    &_save_settings;
    return 1;
}

##########################
sub _get_modules_from_conf {
##########################
# e.g. my %module_links = _get_modules_from_conf($conf_file);
# returns hash with module as key, 

    my $conf_file = shift;
    
    if (!(-f $conf_file)) { return && print "No module configuration file found for this package\n" }
    else { print "Module configuration file: $conf_file\n"; }
    my %module_links;    
    my $modules_folder = $conf_file;
    $modules_folder =~ s/\w+\/[\w\.]+\.conf$/modules/;
    print "Modules folder: $modules_folder\n";
    open(MODULESCONF,$conf_file);
    foreach my $line (<MODULESCONF>) {
	chomp $line;
	next if $line =~ /^\s*\#/;
	next if $line =~ /^\s*$/;
	if ($line =~ /^(\w+\.pm)\s+([\w\/\.]+\.pm)/) {
	    my $module = $1;
	    my $target = "$modules_folder/$module";
	    my $rel_dir = $2;
	    my $link = "$_Current_Dir/../$rel_dir";
	    $module_links{$target} = $link;	    
	}
    }
    unless (scalar(keys %module_links) == 0) {
	foreach my $key (keys %module_links) {
	    my $target_dir = $module_links{$key};
	    $target_dir =~ s/\/[\w\.]+$//;
	    if (!(-d $target_dir)) {
		print "Making directory w/ system command: 'mkdir $target_dir'\n";
		my $feedback;
		$feedback = try_system_command("mkdir $target_dir");
		print "System feedback: $feedback\n" if $feedback;
	    }
	}
    }
    ## module links defined as read from module config file 
    return %module_links;
}

# returns the version_name
########################
sub _get_current_release_version {
#######################
    
    my $old_release_dir = "$_Current_Dir/../conf/sql/release/"; ## deprecated, used for sequencing up until version 2.6
    my $release_dir = "$_Current_Dir/../install/init/release/";

    my %folders;
    find sub { $folders{$_} = 1 if -d}, $release_dir;

    my $current = 0;
    foreach my $key (keys %folders){
	if ($key =~ /^\d+\.\d+$/){
	    if ($key > $current){
		$current = $key;
	    }
	}
    }
    print "Current released alDente version is: $current\n";
    return $current;

}

##########################                 MOST LIKELY SHOULD BE REMOVED
sub _install_custom_patches {
##########################

    my %args = @_;
    my %addon_info = %{$args{-addon_info}};
    my $addon = $addon_info{name};
    my $type = $addon_info{type};
    my $login = $args{-login};
    my $version = $args{-version};
    my $installation = $args{-installation};

    my %package_standards = _get_package_standards();
    my $package_dir = "$_Current_Dir/../$package_standards{types}{$type}{base_folder}/$addon";
    my $package_install_dir = "$package_dir/$package_standards{types}{$type}{install_folder}";
    my $patches_dir = "$package_install_dir/patches";
    
    if (-d $patches_dir) {
	print "--------------------------\n";
	print "***Applying patches...\n";
	my $dir = "$patches_dir";
	my @patch_files = split("\n", try_system_command("ls $dir"));
	@patch_files = grep /(pat)$/,@patch_files;
	print "Found patch files: @patch_files\n";
	foreach my $patch_file (@patch_files) {
	    next if (!($patch_file =~ /(\.pat)$/));
	    my $full_path = "$dir/$patch_file";
	    if ($patch_file =~ /\.pat$/) {
		print "Look at the following file:\n";
		print "*** $full_path\n";
		print "The file contains information about line of code to change manually\n";
		my $ans = Prompt_Input(-prompt=>"Display contents of file now?(y/n)\n",-type=>'char');
		if ($ans eq 'y') {
		    my $command = "cat $full_path\n";
		    print "*System command: $command\n";	
		    my $readmefile = try_system_command($command);
		    print $readmefile;
		    print "\nEND OF FILE\n";
		    print "Follow those guidelines for manual changes\n";
		    my $moveon = Prompt_Input(-prompt=>"Hit any key when you have completed making appropriate changes\n");		    
		}
		else {
		    print "OK, but beware the system may not be fully functional until you read that file and make the changes\n";
		}
	    }
	}     
    }else {
	print "Looked unsuccessfully for patches directory: $patches_dir\n";
    }
    print "---------------------------\n";
    return 1;
    
}

############################# Need to check
sub _generic_crontab_append {
#############################

    print "WARNING: Only the system superuser (aldente) should add to the crontab!\n";
    if (my $ans = Prompt_Input(-prompt=>"Are you logged in as the superuser?(y/n)\n") eq 'y') {
	print "***\n";
	print "Generic cronjob files are filled in dynamically using your configuration settings\n";
	print "When used, they allow you greater options for testing functionality while maintaining backup data\n";
	my $moveon = Prompt_Input(-prompt=>'Hit any key to continue...',-type=>'char');
	print "***\n";
    SDB::Installation::install_All_Crontabs ( -packages => 'Core');
	return 1;

    }
}
=begin
#############################                                                                                                                                                                                                                                             
sub _generic_crontab_append {                                                                                                                                                                                                                                             
#############################                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                                          
    print "WARNING: Only the system superuser (aldente) should add to the crontab!\n";                                                                                                                                                                                    
    if (my $ans = Prompt_Input(-prompt=>"Are you logged in as the superuser?(y/n)\n") eq 'y') {                                                                                                                                                                           
        print "***\n";                                                                                                                                                                                                                                                    
        print "Generic cronjob files are filled in dynamically using your configuration settings\n";                                                                                                                                                                      
        print "When used, they allow you greater options for testing functionality while maintaining backup data\n";                                                                                                                                                      
        my $moveon = Prompt_Input(-prompt=>'Hit any key to continue...',-type=>'char');                                                                                                                                                                                   
        print "***\n";                                                                                                                                                                                                                                                    
        my $cron_dir = "$_Current_Dir/../cron/generic";                                                                                                                                                                                                                   
        my %cron_description; ## hash with file as key and description as value                                                                                                                                                                                           
        $cron_description{'generic_backup_dump.cron'} = 'Dumps structure and data, allows multiple branches of database to be generated';                                                                                                                                 
        $cron_description{'generic_backup_upgrade_dev.cron'} = 'Used for code development cycle';                                                                                                                                                                         
        if ($_Configs{TEST_DATABASE} && ($_Configs{TEST_DATABASE} ne $_Configs{PRODUCTION_DATABASE})) {                                                                                                                                                                   
            $cron_description{'generic_test_db.cron'}='Builds a test database for use with beta code';                                                                                                                                                                    
        }                                                                                                                                                                                                                                                                 
        if ($_Configs{BACKUP_DATABASE} && ($_Configs{BACKUP_DATABASE} ne $_Configs{PRODUCTION_DATABASE})) {                                                                                                                                                               
            $cron_description{'generic_backup_db.cron'} = 'Creates a usable backup database, whose data will always lag';                                                                                                                                                 
        }                                                                                                                                                                                                                                                                 
        my @cron_files = keys %cron_description;                                                                                                                                                                                                                          
        print "Generic cron files:\n",join "\n",@cron_files,"\n";                                                                                                                                                                                                         
        foreach my $file (keys %cron_description) {                                                                                                                                                                                                                       
            _install_crontab(-file=>"$cron_dir/$file",-description=>$cron_description{$file});                                                                                                                                                                            
        }                                                                                                                                                                                                                                                                 
    } else {                                                                                                                                                                                                                                                              
        print "OK, start script as superuser if you wish to change the crontab via this script\n";                                                                                                                                                                        
    }                                                                                                                                                                                                                                                                     
    return 1;                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                                          
}
=cut
#####################
sub _update_crontab {
#####################
# for add-on cronjobs
    my %args = @_;
    my %addon_info = %{$args{-addon_info}};
    my $addon = $addon_info{name};
    my $type = $addon_info{type};

    my %package_standards = _get_package_standards();
    my $cron_folder = "$_Current_Dir/../$package_standards{types}{$type}{base_folder}/$addon/cron";
    if (-d $cron_folder) {
        print "Cron folder: $cron_folder\n";
        my @cron_list = split ("\n",try_system_command("ls -l $cron_folder"));
        @cron_list = grep /[\w\.]+\.cron/,@cron_list;
        unless (!@cron_list) {
            print "*** appending *.cron files to crontab:\n";
            foreach my $cron (@cron_list) {
                $cron =~ /([\w\.]+\.cron)/;
                $cron = $1;
                my $cronjob = "$cron_folder/$cron";
                print "Cron file: $cronjob\n";
                my $appended = _install_crontab(-file=>$cronjob);
            }
        }
    } else {
        print "No cron folder found for $addon\n";
    }
    return 1;
}

#########################
sub _get_package_standards {
########################
    my %package_standards;

    my $install_script_format = 'install.pl';
    my $installed_file = '.installed';
    my $options_conf_file = 'options.conf';
    my $plugins_conf_file = 'plugins.conf';
    my $modules_conf_file = 'modules.conf';
    my $tables_conf_file = 'tables.conf';

    $package_standards{types} = {
	                         'plugin'=>{},
				 'option'=>{},
				 'custom'=>{}
			     };

    $package_standards{types}{plugin}{base_folder} = 'Plugins';
    $package_standards{types}{option}{base_folder} = 'Options';
    $package_standards{types}{custom}{base_folder} = 'custom';

    $package_standards{types}{plugin}{config} = 'Plugins';
    $package_standards{types}{option}{config} = 'Options';
    $package_standards{types}{custom}{config} = 'Custom';

    $package_standards{types}{plugin}{alias} = 'Plugin';
    $package_standards{types}{option}{alias} = 'Option';
    $package_standards{types}{custom}{alias} = 'Custom';

    foreach my $type (keys %{$package_standards{types}}) {
        $package_standards{types}{$type}{install_folder} = 'install';
        $package_standards{types}{$type}{install_file} = $install_script_format;
        $package_standards{types}{$type}{installed_log} = $installed_file;      
	$package_standards{types}{$type}{linked_plugins_conf} = $plugins_conf_file;
	$package_standards{types}{$type}{linked_options_conf} = $options_conf_file;
	$package_standards{types}{$type}{modules_conf} = $modules_conf_file;
	$package_standards{types}{$type}{tables_conf} = $tables_conf_file;
    }
    return %package_standards;
    
}

########################
sub _replace_tags_in_line {
########################
    my $line = shift;

    my @replacement_strings = qw( DATABASE SQL_HOST BACKUP_DATABASE BACKUP_HOST TEST_DATABASE version_name Home_dir Data_home_dir Plugins Custom Options);

    chomp $line;
    next if $line =~ /^\s*$/;
    foreach my $config (@replacement_strings) {
	$line =~ s/\<$config\>/$_Configs{$config}/g;
    }
    if ($line =~ /upgrade_DB/) { ## get rid of options for upgrade_DB that are not relevant to this deployment
	$line =~ s/\-o\s+([\-\d\>])/$1/g;
	$line =~ s/\-O\s+([\-\d\>])/$1/g;
	$line =~ s/\-g\s+([\-\d\>])/$1/g;
    }
    return "$line\n";

}

#########################
sub _display_configs {
#########################
#
#Display current system configurations
#
    ###Load the configurations###
    #%_Configs = %{xml2pl("$Sys_config_file")};

    #Initialize the settings
    #_init_settings();

    print "----------------------------------------------------------\n";
    print "Directory configurations:\n";
    print "----------------------------------------------------------\n";
    foreach my $dir_config (sort { $a <=> $b } keys %_Dir_Configs) {
	my $config = $_Dir_Configs{$dir_config};
        my $id = "$dir_config)$config";
        if (length ($id) >= 15){
            print "$id \t-> " . $_Configs{$config} . "\n";
        } else {
            print "$id \t\t-> " . $_Configs{$config} . "\n";
        }

    }

    print "----------------------------------------------------------\n";
    print "Database configurations:\n";
    print "----------------------------------------------------------\n";
    foreach my $db_config (sort { $a <=> $b } keys %_Db_Configs) {
	my $config = $_Db_Configs{$db_config};
        my $id = "$db_config)$config";
        if (length ($id) >= 15){
            print "$id \t-> " . $_Configs{$config} . "\n";
        } else {
            print "$id \t\t-> " . $_Configs{$config} . "\n";
        }
    }

    print "----------------------------------------------------------\n";
    print "Web configurations:\n";
    print "----------------------------------------------------------\n";
    foreach my $web_config (sort { $a <=> $b } keys %_Web_Configs) {
	my $config = $_Web_Configs{$web_config};
        my $id = "$web_config)$config";
        if (length ($id) >= 15 && length ($id) < 23){
            print "$id \t\t-> " . $_Configs{$config} . "\n";
        } elsif (length ($id) >= 23){
            print "$id \t-> " . $_Configs{$config} . "\n";
        } else {
            print "$id \t\t\t-> " . $_Configs{$config} . "\n";
        }

    }
    
    print "----------------------------------------------------------\n";
    print "Tracking configurations:\n";
    print "----------------------------------------------------------\n";
    foreach my $track_config (sort { $a <=> $b } keys %_Tracking_Configs) {
	my $config = $_Tracking_Configs{$track_config};
        my $id = "$track_config)$config";
        if (length ($id) >= 15 && length ($id) < 23){
            print "$id \t\t-> " . $_Configs{$config} . "\n";
        } elsif (length ($id) >= 23){
            print "$id \t-> " . $_Configs{$config} . "\n";
        } else {
            print "$id \t\t\t-> " . $_Configs{$config} . "\n";
        }

    }
}

##########################
sub _change_configs {
##########################
#
#Changing individual system configs.
#
    
    my %args = @_;
    ###Load the configurations###
    #%_Configs = %{xml2pl("$Sys_config_file")};

    #Initialize the settings
    #_init_settings();

    my $ans;
    my $quit = 0;
    do {
	print "----------------------------------------------------------\n";
	foreach my $setting (sort { $a <=> $b } keys %_Custom_Configs) {
	    my $config = $_Custom_Configs{$setting}->{config};
            my $id = "$setting)$config";
            if (length ($id) >= 15 && length ($id) < 23){
                print "$id \t\t-> " . $_Configs{$config};
            } elsif (length ($id) >= 23){
                print "$id \t-> " . $_Configs{$config};
            } else {
                print "$id \t\t\t-> " . $_Configs{$config};
            }
            if ((defined $_Custom_Configs{$setting}->{modified}) && ($_Custom_Configs{$setting}->{modified} == 1)) {
                print " **";
            }
	    print "\n";

	}
	print "\n----------------------------------------------------------\n";

	print "Type the configuration number to change the value of a configuration.\n";
	print "Type 's' to save the configuration changes.\n";
        print "Type 'd' to reconfigure host, database, and code-version\n";
	print "Type 'q' to go back to previous menu.\n";
	
	$ans = Prompt_Input();
	
	if ($ans =~ /^(\d+)$/) {
	    my $config = $_Custom_Configs{$ans}->{config};
	    print "\nPlease enter the value for $config.\n";
	    my $value = Prompt_Input();
	    if ($_Configs{$config} eq $value) {
		print "$config is already set to '" . $_Configs{$config} . "'. No changes made.\n";
	    }
	    else {
	        $Configs_Custom{$config}{value} = $value;
		$_Configs{$config} = $value;

		#Mark the custom config as modified and not saved yet.
		$_Custom_Configs{$ans}->{modified} = 1;
		print "$config is now set to '" . $_Configs{$config} . "'\n";
	    }
	}
	elsif ($ans eq "d") {
	    _host_and_db_settings();

	}
	elsif ($ans eq 's') {
	    _save_settings();
	    #Remove the 'modified' mark from the custom configs.
	    foreach my $i (sort { $a <=> $b } keys %_Custom_Configs) {
		if (defined $_Custom_Configs{$i}->{modified}) {
		    $_Custom_Configs{$i}->{modified} = 0;
		}
	    }
	    print "Configurations saved.\n";
	}
	elsif ($ans eq 'q') {
	    my $modified = 0;
	    #First check to see if there are modified configurations.
	    foreach my $i (sort { $a <=> $b } keys %_Custom_Configs) {
		if ((defined $_Custom_Configs{$i}->{modified}) && ($_Custom_Configs{$i}->{modified} == 1)) {
		    $modified = 1;
		    last;
		}
	    }
	    if ($modified) {
		print "\nYou have modified and unsaved configurations. Do you really want to go back to the main menu?(y/n)\n";
		my $ans = Prompt_Input(-type=>'char');
		if ($ans eq 'y') {$quit = 1;}
	    }
	    else {
		$quit = 1;
	    }
	}
    } until ($quit)
}

#############################
sub _set_default_configs {
#############################

  foreach my $key (keys %Configs_Custom){
    if ($Configs_Custom{$key}{default} ne ''){
      $Configs_Custom{$key}{value} = $Configs_Custom{$key}{default};
      $_Configs{$key} = $Configs_Custom{$key}{value};
    }
  }
  _save_settings();
  # reset %_Configs
  &_load_custom_config();
  %_Configs = %{&_combine_configs()};
}

##############################
sub _host_and_db_settings {
##############################
# 
#
# use to configure host, database, and code version configs
#

    my %args = @_;
    my $first = $args{-first} || 0;    
    my $filename = $args{-filename} || "$_Current_Dir/.installed";

    my ($production_host, $production_db);

    my ($date,$time) = split ' ',&date_time();

    my $log;

    if ($first) {

        $log .= "=================================\n";
        $log .= "Log file of initial configuration\n";
        $log .=  "=================================\n\n";

    } else {

	$log .= "New host and database configuration\n\n";
    }
    $log .= "Date of configuration: $date\n";
    $log .= "Time of configuration: $time\n\n";
    
    print "What is the name of the version of code you are using? (the folder into which code was checked out)\n";
    my $version_name = Prompt_Input();
    _change_config(-config=>'version_name',-value=>$version_name);
    print "-----------------------------------------\n";
    $log .= "Code version name: $_Configs{version_name}\n";
    
    ## PRODUCTION DATABASE
    while (!$production_db) {
	print "What is the name of the production database?\n";
	$production_db = Prompt_Input();
	if (!$production_db) {print "Database name is mandatory!\n" }
    }
    _change_config(-config=>'PRODUCTION_DATABASE',-value=>$production_db);
    print "-----------------------------------------\n";
    $log .= "Production database: $_Configs{PRODUCTION_DATABASE}\n";
    
    while (!$production_host) {
	print "What is the default host?\n";
	$production_host = Prompt_Input();
	if (!$production_host) {print "Host name is mandatory!\n" }
    }	
    _change_config(-config=>'SQL_HOST',-value=>$production_host);

    print "-----------------------------------------\n";       
    $log .= "Production database host: $_Configs{SQL_HOST}\n";

    my $url_domain;
    while (!$url_domain) {
	print "What server is your code on? (Default: http://$production_host.bcgsc.ca/)\n";
	$url_domain = Prompt_Input();
	if ($url_domain eq '' || $url_domain =~ /^(\\n|\\r)$/) { $url_domain = "http://$production_host.bcgsc.ca"; } 
        _change_config(-config=>'URL_domain',-value=>"$url_domain");       
    }
    $log .= "URL domain after login: $_Configs{URL_domain}\n";
    print "-----------------------------------------\n";
    
    # BACKUP_DATABASE
    print "What is the backup database? (Optional)\n";
    my $backup_db = Prompt_Input();
    _change_config(-config=>'BACKUP_DATABASE',-value=>$backup_db);
    print "-----------------------------------------\n";
    $log .= "Backup database: $_Configs{BACKUP_DATABASE}\n";
    # BACKUP_HOST
    my $backup_host = '';
    unless ($backup_db eq '' || $backup_db eq '\r') {
	print "What server holds the backup database?\n";
	$backup_host = Prompt_Input();
    }
    _change_config(-config=>'BACKUP_HOST',-value=>$backup_host);
    print "-----------------------------------------\n";
    $log .= "Backup host: $_Configs{BACKUP_HOST}\n";
    
    print "What is the name of the test database? (Optional)\n";
    my $test_db=Prompt_Input();
    _change_config(-config=>'TEST_DATABASE',-value=>$test_db);
    print "-----------------------------------------\n";
    $log .= "Test database: $_Configs{TEST_DATABASE}\n";
    
    print "What is the name of the beta database? (Optional)\n";
    my $beta_db = Prompt_Input();
    _change_config(-config=>'BETA_DATABASE',-value=>$beta_db);
    print "-----------------------------------------\n";
    $log .= "Beta database: $_Configs{BETA_DATABASE}\n";
    
    ## DEFAULT VERSION
    print "Which database is the default at login?\n";
    my $default = Prompt_Input();
    _change_config(-config=>'DATABASE',-value=>$default);       
    
    $log .= "Default login database: $_Configs{DATABASE}\n";       

    $log .= "END CONFIGURATION\n"."========================================\n";

    print "\n";
    _save_settings(); 
    print "Database configuration settings have been changed.\n"; 
    print "Writing to log file $filename\n ...\n";
    if ($first) {
        ## Print results of configuration to log file
        open LOG, ">$filename" or die "Install log $filename not created";
	print LOG "$log";
	close LOG;
    }
    else {
        open LOG, ">>$filename" or die "Can't open logfile $filename\n";
        print LOG "New host and database configuration\n\n";
	print LOG $log;
	close LOG;
    }

    return 1;
}

#######################
sub _save_settings {
#######################
#
# save %Configs_Custom to $Sys_config_file
#
  my $xml = XMLout(\%Configs_Custom, RootName=>'configs');
  open (my $FH, ">$Sys_config_file") or die ("cannot open $Sys_config_file: $!");
  print $FH $xml;
  close $FH;
  # reset %_Configs
  &_load_custom_config();
  %_Configs = %{&_combine_configs()};
}

#########################
sub _init_settings {
#########################
#
#Intitiaze settings required for the setup.
#
    my $i = 0;
    my $j = 0;
    my $m = 0;
    my $n = 0;
    my $x = 0;
    my $y = 0;

    foreach my $key (keys %Configs_Custom){
      my $type = $Configs_Custom{$key}{type};
      my $value = $Configs_Custom{$key}{value};

      #Directory configs.
      if ($type eq 'directory'){
	$_Dir_Configs{++$i} = $key;
	$_Perm0775{++$count_0775} = $key; ## all customizable directories are 0775 by default
      }

      #Database configs.
      elsif ($type eq 'database'){
	$_Db_Configs{++$j} = $key;
      }

      #Web configs.
      elsif ($type eq 'web'){
	$_Web_Configs{++$m} = $key;
      }


      #Tracking configs
      elsif ($type eq 'tracking'){
	$_Tracking_Configs{++$n} = $key;
      }

      #All configs in system.conf are customizable.
      $_Custom_Configs{++$y}->{config} = $key;

    }

    foreach my $item (@$Configs_Non_Custom){
      my @keys = keys %$item;
      my $key = $keys[0];
      if (exists $item->{$key}{permission}){
	$_Dir_Configs{++$i} = $key;	
	my $permission = $item->{$key}{permission};
	if ($permission){

	  # Directories/files that require change of permission to 0775.
	  # read write execute for owner and group
	  # no permission for others
	  if ($permission eq '0775'){
	    $_Perm0775{++$count_0775} = $key;
	  }

	  # Directories/files that require change of permission to 0770.
	  # read write execute for owner and group
	  # no permission for others
	  if ($permission eq '0770'){
	    $_Perm0770{++$count_0770} = $key;
	  }

	  #Directories/files that require change of permission to 0771.
	  # read write execute for owner and group
	  # read for others
	  elsif ($permission eq '0771'){
	    $_Perm0771{++$count_0771} = $key;
	  }

	  # Directories/files that require change of permission to 0777.
	  # Full permissions for all
	  elsif ($permission eq '0777'){
	    $_Perm0777{++$count_0777} = $key;
	  }

	}
      }

    }



}

####################
sub _change_config {
####################
#
# Example: _change_config(-config=>$config,-value=>$value);
# Use this to change one config option at a time

    my %args = @_;
    my $config = $args{-config};
    my $value = $args{-value};
    my $quiet = $args{-quiet};

    if ($_Configs{$config} eq $value) {
	print "$config is already set to '" . $_Configs{$config} . "'. No changes made.\n" unless $quiet;       
    }
    else {
	$Configs_Custom{$config}{value} = $value;
	$_Configs{$config} = $value;
	#Mark the custom config as modified and not saved yet.
	my $confignum = _get_config_num($config);
	
	$_Custom_Configs{$confignum}->{modified} = 1;
	print "$config is now set to '" . $_Configs{$config} . "'\n";
    }    
}

#####################
sub _get_config_num {
#####################
#
# e.g. my $confignum = _get_config_num('TEST_DATABASE');
# Returns the config number of a particular configuration option

    my $config = shift;
    my $num;

    foreach my $option (keys %_Custom_Configs) {
	if ( $_Custom_Configs{$option}->{config} eq $config ) {
	    $num = $option;	    
	    return $num;
	}
    }
    
}

####################
sub _get_mysql_login {
####################

    my %login;

    my $done = 0;
    do {
	$login{host} = Prompt_Input(-prompt=>"Database host (for default enter $_Configs{SQL_HOST})");
	$login{database} = Prompt_Input(-prompt=>"Database name (for default enter $_Configs{DATABASE})");
	$login{user} = Prompt_Input(-prompt=>'MySQL Username');
	$login{password} = Prompt_Input(-prompt=>'MySQL Password',-type=>'password');
		
	print "***\n";
	print "You entered:\n";
	foreach my $key (keys %login) {
	    if ($key !~ /password/) {
		print "$key: $login{$key}\n";
	    }
	    else {
		print "$key: <pass>\n";
	    }
	}
	my $ans = Prompt_Input(-prompt=>"Is this correct?(y/n)\n",-type=>'char');
	$done = 1 if ($ans eq 'y'); 
    } until ($done);
    return %login;

}

#########################
sub _get_installation {
#########################
    
    my %args = filter_input(\@_);
    my $login = $args{-login};
    require SDB::DBIO;
    my $dbc = new SDB::DBIO(
                            -host=>$login->{host},
                            -dbase=>$login->{database},
                            -user=>$login->{user},
                            -password=>$login->{password},
			    -connect=>1,
                            );
    my $Installation = new SDB::Installation(-dbc=>$dbc);
    return $Installation;
  
}

