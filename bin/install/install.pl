#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################
#

##########################################################
#       Standard modules and System Variables
##########################################################
use strict;
use FindBin;
use lib $FindBin::RealBin . "/../../lib/perl";
use lib $FindBin::RealBin . "/../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../lib/perl/Departments";
use Data::Dumper;
use Getopt::Std;

use alDente::Validation;
use RGTools::RGIO;
use SDB::DBIO;
use SDB::Installation;
use RGTools::Process_Monitor;

use LampLite::Config;

use vars qw($opt_patch $opt_user $opt_pass $opt_dbase $opt_host $opt_debug $opt_help $opt_test $opt_confirmed  $opt_search $opt_create_core $opt_create_links $opt_code_version
    $opt_schema $opt_data $opt_bin $opt_final $opt_append $opt_integrity $opt_app $opt_model $opt_skip_SVN_check $opt_parent $opt_location $opt_package_version
    $opt_package $opt_upgrade_DB $opt_build $opt_create_patches $opt_uninstall $opt_category $opt_type $opt_add_ons $opt_crontab $opt_scope $opt_db_version $opt_generate $opt_prompt $opt_nonlocal);
use Getopt::Long;

##########################################################
#       Input
##########################################################
&GetOptions(
    'test'              => \$opt_test,
    'debug'             => \$opt_debug,
    'confirmed'         => \$opt_confirmed,
    'help'              => \$opt_help,
    'user=s'            => \$opt_user,
    'pass=s'            => \$opt_pass,
    'dbase=s'           => \$opt_dbase,
    'host=s'            => \$opt_host,    'patch=s'           => \$opt_patch,
    'package=s'         => \$opt_package,
    'package_version=s' => \$opt_package_version,
    'upgrade_DB=s'      => \$opt_upgrade_DB,
    'build=s'           => \$opt_build,
    'create_patches=s'  => \$opt_create_patches,
    'uninstall=s'       => \$opt_uninstall,
    'search=s'          => \$opt_search,
    'category=s'        => \$opt_category,
    'type=s'            => \$opt_type,
    'add_ons=s'         => \$opt_add_ons,
    'create_core'       => \$opt_create_core,
    'create_links=s'    => \$opt_create_links,
    'crontab=s'         => \$opt_crontab,
    'code_version=s'    => \$opt_code_version,
    'scope=s'           => \$opt_scope,
    'db_version=s'      => \$opt_db_version,
    'generate=s'        => \$opt_generate,
    'integrity=s'       => \$opt_integrity,
    'App=s'             => \$opt_app,
    'model=s'           => \$opt_model,
    'append'            => \$opt_append,
    'prompt'            => \$opt_prompt,
    'skip_svn'          => \$opt_skip_SVN_check,
    'parent=s'          => \$opt_parent,
    'location=s'        => \$opt_location,
    'nonlocal=s'        => \$opt_nonlocal,
    'schema=s'          => \$opt_schema,
    'data=s'            => \$opt_data,
    'bin=s'             => \$opt_bin,
    'final=s'           => \$opt_final,
);

if ($opt_help) {
    help($opt_help);
}

my $dbase = $opt_dbase;
my $host  = $opt_host ;
my $user  = $opt_user;
my $pwd   = $opt_pass;
my $debug = $opt_debug;
my $test  = $opt_test;
my $confirmed       = $opt_confirmed;
my $patches         = $opt_patch;
my $package         = $opt_package;
my $package_version = $opt_package_version;
my $upgrade_DB      = $opt_upgrade_DB;
my $build           = $opt_build;
my $create_patches  = $opt_create_patches;
my $uninstall       = $opt_uninstall;
my $search          = $opt_search;
my $create_core     = $opt_create_core;
my $create_links    = $opt_create_links;
my $crontab         = $opt_crontab;
my $code_version    = $opt_code_version;
my $scope           = $opt_scope;
my $db_version      = $opt_db_version;
my $generate        = $opt_generate;
my $integrity       = $opt_integrity;
my $app             = $opt_app;
my $model           = $opt_model;
my $location        = $opt_location;
my $prompt_mode     = $opt_prompt;
my $nonlocal        = $opt_nonlocal;          #this flag is being used for removing the local keyword while loading data into database and it has to be " " empty string

my $Setup = LampLite::Config->new( -initialize=>$FindBin::RealBin . '/../../conf/custom.cfg');
my $Config = $Setup->{config};

$dbase ||= $Config->{DEV_DATABASE};
$host ||= $Config->{DEV_HOST};

##########################################################
#      Install script can only be run from
##########################################################
unless ( _check_SVN() || $opt_skip_SVN_check ) {
    Message 'This script can only be run from svn trunk that is leading edge of development.  It cannot be run from test/production branch';
    print "SVN: " . _check_SVN();
    exit;
}

##########################################################
#       Actions that Dont require dbc or install object
##########################################################

if ($build) {
    build_package();
    exit;
}
elsif ($model) {
    build_model();
    exit;
}
elsif ($app) {
    build_app();
    exit;
}
elsif ($create_links) {
    create_Links( -package => $package, -link_version => $create_links );
    exit;
}
elsif ($crontab) {
    install_Cronab( -package => $crontab );
    exit;
}
elsif ($search) {
    Message search_results( -search => $search, -version => $db_version, -scope => $scope );
    exit;
}
elsif ($generate) {
    generate_patch();
    exit;
}
elsif ($integrity) {
    integrity_monitor( -dbase => $integrity );
    exit;
}
elsif ( !$patches && !$package && !$upgrade_DB && !$create_patches && !$uninstall && !$package_version ) {
    help($opt_help);
}
##########################################################
#       Initialization
##########################################################
if ( $create_patches && !$user ) { $user = 'viewer' }

unless ($user) {
    $user = Prompt_Input( -prompt => 'MySQL User' );
}

my $login_file = $FindBin::RealBin . "/../../conf/mysql.login";

my $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $user, -login_file=>$login_file, -connect => 1, -config=>$Config, -no_triggers=>1);
unless ($dbc) {
    Message "No database connection established. Exiting ... ";
    exit;
}
my $connect = "mysql -h $host -u $user -p" . "$pwd $dbase";

my $install = new SDB::Installation( -dbc => $dbc, -simple => 1, -prompt => $prompt_mode );
if ( $dbase =~ /sequence/ ) {
    print "Are you sure you want to apply changes to the '$dbase' database on '$host'? (y/n)";
    my $ans = Prompt_Input( -type => 'char' );
    unless ( $ans =~ /y|Y/ ) {
        exit;
    }
}

##########################################################
#       LOGIC
##########################################################

if ($patches) {
    install_patches();
    exit;
}
elsif ($package) {
    install_package( -link_version => $code_version, -confirmed => $confirmed, -package => $package, -db_version => $db_version );
    exit;
}
elsif ($package_version) {
    install_package_version( -package => $package_version, -db_version => $db_version );
    exit;
}
elsif ($upgrade_DB) {
    upgrade_DB();
    exit;
}
elsif ($create_patches) {
    create_Package_Patches();
    exit;
}
elsif ($uninstall) {
    uninstall_package();
    exit;
}
else {
    help($opt_help);
}
print "\n";
exit;

##########################################################
#       Primary Run-modes
##########################################################
#############################
sub integrity_monitor {
#############################
    my %args  = filter_input( \@_ );
    my $dbase = $args{-dbase};

    alDente::Validation::check_installation_integrity( -dbase => $dbase, -debug => $debug, -user=>$user, -login_file=>$login_file, -config=>$Config);
    exit;

}

#############################
sub build_package {
#############################
    my $category = $opt_category;
    my $type     = $opt_type;
    my $choice;
    unless ($category) {
        $category = Prompt_Input( -prompt => "Please enter category (Plugins,Options,custom): " );
    }

    while ( !$type && !$choice ) {
        print "1. Run \n" . "2. Department \n" . "3. MVC files only\n" . "4. Simple\n";
        $choice = Prompt_Input( -prompt => "Please enter your select for type of Package: ", -type => 'char' );
        if ( $choice < 1 || $choice > 4 ) {
            Message "Invalid Option!";
            $choice = '';
        }
    }

    if    ( $choice == 1 ) { $type = 'Run' }
    elsif ( $choice == 2 ) { $type = 'Department' }
    elsif ( $choice == 3 ) {
        build_app( -name => $build );
        return;
    }
    elsif ( $choice == 4 ) { $type = '' }

    SDB::Installation::create_Package( -package => $build, -category => $category, -type => $type, -add_on => $opt_add_ons, -debug => $debug );
    return;
}

#############################
sub build_app {
#############################
    my %args = filter_input( \@_ );
    my $name = $args{-name} || $app;
    if ( !$location ) {
        my @subs = get_sub_directories();
        while ( !$location ) {
            my $counter;
            Message "Choose one of these directories as your target for MVC files to be copied:";
            for my $sub (@subs) {
                $counter++;
                Message $counter . '.' . $sub;
            }
            my $choice = Prompt_Input( -prompt => "Enter selection: " );
            unless ( $choice < 1 || $choice > $counter ) {
                $location = $subs[ $choice - 1 ];
            }
        }
    }
    Message "installing on $location";
    SDB::Installation::create_Template_Files( -name => $app, -debug => $debug, -location => $location );
    return;
}

#############################
sub create_Links {
#############################
    my %args         = filter_input( \@_ );
    my $package      = $args{ -package };
    my $link_version = $args{-link_version};

    my ($category) = $dbc->Table_find( 'Package', 'Package_Scope', "WHERE Package_Name = '$package' " ) if $dbc;
    unless ($category) {
        $category = Prompt_Input( -prompt => "Please enter category (Plugins,Options,custom): " );
    }
    unless ($link_version) {
        $link_version = Prompt_Input( -prompt => "Please enter version you wish to install the links on: (beta, test ...): " );
    }
    SDB::Installation::install_Package_links( -package => $package, -category => $category, -version => $link_version, -debug => $debug );
    return;
}

#############################
sub create_Package_Patches {
#############################
    my $package_id = get_Package_ID( -package => $create_patches, -dbc => $dbc );
    unless ($package_id) {
        Message "Package $create_patches does not exist in database ... exiting";
        exit;
    }
    my $version = get_database_version();
    my $tables  = get_tables( -package => $create_patches, -dbc => $dbc );
    my $fields  = get_fields( -package => $create_patches, -dbc => $dbc, -table => $tables, -package_id => $package_id );

    my $table_text = get_table_text( -package => $create_patches, -dbc => $dbc, -table => $tables );

    my $field_text = get_field_text( -package => $create_patches, -dbc => $dbc, -field => $fields );

    my $dbm_text = get_DBM_text( -package => $create_patches, -dbc => $dbc, -table => $tables, -field => $fields, -package_id => $package_id );

    my $file = get_file( -package => $create_patches, -dbc => $dbc, -version => $version );
    my $description = get_description( -package => $create_patches, -file => $file );

    my $success = write_to_file(
        -package => $create_patches,
        -dbc     => $dbc,
        -file    => $file,
        -f_text  => $field_text,
        -t_text  => $table_text,
        -desc    => $description,
        -d_text  => $dbm_text
    );
    return;
}

#############################
sub generate_patch {
#############################
    my $new_file    = $generate;
    my $schema_path = $opt_schema || Prompt_Input( -prompt => 'Enter the path for the schema-changing sql file' );
    my $data_path   = $opt_data || Prompt_Input( -prompt => 'Enter the path for the data-changing sql file' );
    my $bin_path    = $opt_bin || Prompt_Input( -prompt => 'Enter the path for the bin-file' );
    my $final_path  = $opt_final || Prompt_Input( -prompt => 'Enter the path for the finalization sql file (changing dbfield and dbtable records)' );

    my $patch_info = {};
    $patch_info->{schema}{tag} = 'SCHEMA';
    $patch_info->{data}{tag}   = 'DATA';
    $patch_info->{bin}{tag}    = 'CODE_BLOCK';
    $patch_info->{final}{tag}  = 'FINAL';

    $patch_info->{schema}{file} = $schema_path;
    $patch_info->{data}{file}   = $data_path;
    $patch_info->{bin}{file}    = $bin_path;
    $patch_info->{final}{file}  = $final_path;

    open( PATCH, ">$new_file" ) or die "Unable to open new patch file for write";
    Message "Generating new patch file: $new_file";

    foreach my $key ( 'schema', 'data', 'bin', 'final' ) {
        if ( -f "$patch_info->{$key}{file}" ) {
            Message "Writing lines to new patch file from: $patch_info->{$key}{file}";
            my $FILE;
            open( $FILE, "<$patch_info->{$key}{file}" );
            print PATCH '<', "$patch_info->{$key}{tag}", ">\n";
            foreach my $line (<$FILE>) {
                print PATCH "$line";
            }
            close $FILE;
            print PATCH "\n</" . "$patch_info->{$key}{tag}" . ">\n";
            Message "Wrote $key block of new patch file";
        }
    }
}

#######################################
sub install_Cronab {
#######################################
    my %args    = filter_input( \@_ );
    my $package = $args{ -package };
    SDB::Installation::install_All_Crontabs( -packages => $package, -test => $test, -append => $opt_append );
    return;
}

#############################
sub install_patches {
#############################
    my @files = split ',', $patches;
    my $previous_install_success = 1;
    my $patch_version;

    for my $file (@files) {
        if ($previous_install_success) {
            my $patch_info = $install->get_patch_info( -file => $file );

            if ($patch_info) {
                my %info         = %$patch_info if $patch_info;
                my $patch_name   = $info{PATCH};
                my $package_name = $info{PACKAGE};
                my $category     = $info{CATEGORY};
                my $version      = $info{VERSION};

                my $prompt;
                if ( !$package_name ) { Message "No Package found fo patch $file" }
                if ( !$category )     { Message "No Category found fo patch $file" }
                if ( !$version )      { Message "No Version found fo patch $file" }
                if ( $package_name && $category && $version ) {
                    Message "$patch_name - $version -  $package_name [ $category ] ";
                    my $message = "Do you wish to install this patch? (Y/N)";
                    $prompt = Prompt_Input( -prompt => $message ) unless $confirmed;
                }
                else {
                    exit;
                }
                if ( $prompt =~ /^y$/i || $confirmed ) {
                    $patch_version = $install->install_Patch(
                        -patch          => $patch_name,
                        -package        => $package_name,
                        -category       => $category,
                        -version        => $version,
                        -debug          => $debug,
                        -test           => $test,
                        -parent_package => $opt_parent,
                        -group_version  => $patch_version,
                        -nonlocal       => $nonlocal
                    );
                    $previous_install_success = 0 unless $patch_version;
                }
                else {
                    Message "You have chosen to exit";
                    exit;
                }
            }
            else {
                Message "Could not complete the installation of $file";
                exit;
            }
        }
    }

}

#############################
sub install_package {
#############################
    my %args         = filter_input( \@_ );
    my $package      = $args{ -package };
    my $link_version = $args{-link_version};
    my $confirmed    = $args{-confirmed};
    my $version      = $args{-db_version};

    if ($version) {
        $install->install_Package( -package => $package, -version => $version );
    }
    else {
        if ( !$link_version && !$confirmed ) {
            Message "Which version of code do you wish to install the links on? (eg beta, test ,...)";
            $link_version = Prompt_Input();
        }

        initiate_installation(
            -package => $package,
            -debug   => $debug,
            -dbc     => $dbc,
            -parent  => $opt_parent,
            -install => $install
        );

        if ($confirmed) {
            create_Links( -package => $package, -link_version => $link_version, -debug => $debug ) if $link_version;
            install_Cronab( -package => $package ) if $link_version;
            install_package_patches( -package => $package );

        }
        else {
            print "Are you sure you want to create links for package $package on ./versions/$link_version/ ? (y/n)";
            my $ans = Prompt_Input( -type => 'char' );
            if ( $ans =~ /y|Y/ ) {
                create_Links( -package => $package, -link_version => $link_version, -debug => $debug );
            }

            print "Are you sure you want to install crontabs for package $package ? (y/n)";
            my $ans = Prompt_Input( -type => 'char' );
            if ( $ans =~ /y|Y/ ) {
                install_Cronab( -package => $package );
            }

            print "Are you sure you want to install patches for package $package ? (y/n)";
            my $ans = Prompt_Input( -type => 'char' );
            if ( $ans =~ /y|Y/ ) {
                install_package_patches( -package => $package );
            }
        }
    }
    return;
}

##################################
sub search_results {
##################################
    my %args    = filter_input( \@_, -args => 'search' );
    my $search  = $args{-search};
    my $version = $args{-version} || '*';
    my $scope   = $args{-scope};

    my $patch_dir;
    my $base_dir = $FindBin::RealBin . "/..";
    if ( $scope =~ /core/i ) {
        $patch_dir = "$base_dir/install/patches/Core/$version/*.pat";
    }
    elsif ($scope) {
        $patch_dir = "$base_dir/$scope/*/install/patches/$version/*.pat";
    }
    else {
        ## allow for both options ##
        $patch_dir = "$base_dir/install/patches/Core/$version/*.pat";
        $patch_dir .= ' ' . "$base_dir/*/*/install/patches/$version/*.pat";
    }
    my $command = "grep -nri '$search' $patch_dir";
    my @output = split "\n", try_system_command($command);
    my $output;

    foreach my $found (@output) {
        if ( $found =~ /\/(.*\.pat)(.*)/ ) {
            $output .= "** $1 **\n$2\n\n";

        }
    }
    return $output;
}

#############################
sub uninstall_package {
#############################
    my $package = $uninstall;
    my ($pack_info) = $dbc->Table_find( 'Package', 'Package_ID,Package_Install_Status', "WHERE Package_Name = '$package' " );
    my ( $package_id, $package_status ) = split ',', $pack_info;

    if ($create_core) {
        my @all_packages = $dbc->Table_find( 'Package', 'Package_ID', "WHERE Package_Install_Status ='Installed' and Package_Name NOT IN ('Core','Lab') " );
        if ($debug) {
            Message "all package ids:";
            print Dumper @all_packages;
        }
        $package_id = join ',', @all_packages;
        unless ($package_id) {
            Message "No extra packages installed !!";
            return;
        }
        $package_status = 'Installed';
    }

    unless ($package_id) {
        Message "$package is not a valid package name";
        return;
    }
    unless ( $package_status eq 'Installed' ) {
        Message "Package $package is $package_status so cannot continue";
        return;
    }
    ##############################################
    ##  getting daughter packages       ##########
    ##############################################
    unless ($create_core) {
        my @daughter_packages = get_daughter_packages($package_id);
        if ($debug) {
            Message "Daughter package ids:";
            print Dumper @daughter_packages;
        }
        ##skip for all
        for my $d_pack (@daughter_packages) {
            my ($dp_info) = $dbc->Table_find( 'Package', 'Package_Name,Package_Install_Status', "WHERE Package_ID =$d_pack " );
            my ( $dp_name, $dp_status ) = split ',', $dp_info;
            if ( $dp_status eq 'Installed' ) {
                Message "Daughter Package $dp_name is $dp_status so cannot continue";
                return;
            }
        }
    }
    ##############################################
    ### Getting the tables and fields   ##########
    ##############################################
    my @tables      = $dbc->Table_find( 'DBTable', 'DBTable_ID', "WHERE FK_Package__ID IN ($package_id)" );
    my @temp_tables = $dbc->Table_find( 'DBTable', 'DBTable_ID', "WHERE FK_Package__ID IS NULL OR FK_Package__ID = 0" );
    if ($create_core) {
        push @tables, @temp_tables;
    }

    my $tables_list = join ',', @tables;
    my @fields;
    if ($tables_list) {
        @fields = $dbc->Table_find( 'DBField', 'DBField_ID', " WHERE FK_Package__ID IN ($package_id) and FK_DBTable__ID NOT IN ($tables_list)" );
    }
    else {
        @fields = $dbc->Table_find( 'DBField', 'DBField_ID', " WHERE FK_Package__ID IN ($package_id) " );
    }

    print "\n Fields: ------------\n";
    for my $temp (@fields) {
        print "- $temp \n";

    }

    my @temp_fields = $dbc->Table_find( 'DBField', 'DBField_ID', "WHERE FK_Package__ID IS NULL OR FK_Package__ID = 0" );
    if ($create_core) {
        push @fields, @temp_fields;
    }

    ##############################################
    ### droping the tables and fields   ##########
    ##############################################
    for my $p_table (@tables) {
        my ($t_name) = $dbc->Table_find( 'DBTable', 'DBTable_Name', "WHERE DBTable_ID = $p_table" );
        my $command = " drop TABLE $t_name ";
        my $ok = try_system_command("$connect -e  \'$command\'");
        Message "Dropping table: $t_name";
    }
    for my $p_field (@fields) {
        my ($total_inf) = $dbc->Table_find( 'DBField', 'Field_Name,Field_Table', "WHERE DBField_ID = $p_field" );
        my ( $f_name, $t_name ) = split ',', $total_inf;
        my $command = " alter table $t_name drop COLUMN $f_name " if ( $f_name && $t_name );
        print "\n++ command: $command ++\n";
        my $ok = try_system_command("$connect -e  \'$command\'") if $command;
        print "\n++ $ok ++\n";
        Message "Dropping Field $f_name from $t_name";
    }
    ##############################################
    ### Database management information   ########
    ##############################################
    record_uninstallation( -package => $package_id, -dbc => $dbc );
    run_dbfield_set( -dbc => $dbc );
    Message "Package $package has been uninstalled";
    return;
}

#############################
sub upgrade_DB {
#############################
    my $db_version;
    if ( $upgrade_DB =~ /next/i ) {
        $db_version = $install->get_Next_Database_Version();
    }
    elsif ( $upgrade_DB =~ /current/i ) {
        $db_version = $install->get_Current_Database_Version();
    }
    else {
        Message "Invalid upgarde selection [$upgrade_DB]";
        exit;
    }
    my $variation = $host . ':' . $dbase;
    my $Report = Process_Monitor->new( -testing => $test, -variation => $variation, -configs=>$Config);
    $Report->set_Message("Report created: logged to $Report->{log_file}");
    $install->upgrade_DB( -test => $test, -debug => $debug, -version => $db_version, -report => $Report );
    $Report->completed();
    $Report->DESTROY();

}

#############################
sub help {
#############################
    my $help = shift;

    print <<END;

File:  install.pl
###################
To handle all installation matters. Including patches, packages, crontabs, ...
   
Extended Help:
	install.pl -help


Usage:
###################
-----   Building Options   	-----
		
	Creating an Original Package:
		install.pl -build Superb  						[-category Plugins -type Department -add_ons API]
	Creating a new App:
		install.pl -App Equipment 			 			[-location  alDente] 
	Creating Package Patch:  
		(Automatically from database info it creates a pacth containing tables of pre-installed package )   
		install.pl  -create_patches Tray				[-host limsdev02 -dbase seqdev]            (** default to development host/database**)
	Creating a new empty Patch:
		install.pl -generate '/path/to/new_file.pat' 	[-schema '/path/to/schema_file.sql' -data '/path/to/data_file.sql' -bin '/folder/to/bin/bin.pl' -final '/path/to/final_sql.sql' ]
		
----- Installing Options  	-----
	
	Installing Patches:
		install.pl -patch SOLID_patch_1.pat,SOLID_patch_2.pat 			-host lims02 -dbase seqtest [-user super_cron -pass *******]
	Installing a Package:
		install.pl -package SOLID						-host lims02 -dbase seqtest [-user super_cron -pass ******* -code_version beta ]
	Installing a Package: 
		(for a specific db version)
		install.pl -package SOLID -db_version 2.6  -host lims02 -dbase seqtest -user super_cron -pass ******* 
	Installing a Package: 
		(without any section by section prompts)
		install.pl -package SOLID_patch_1.pat,SOLID_patch_2.pat 		-host lims02 -dbase seqtest [-user super_cron -pass ******* -code_version beta  -confirmed]
        Install Crontab for  packages:
		install.pl -crontab SOLID,Sequencing   							[-test -append]
	Install Core Crontab:
		install.pl -crontab Core  										[-test -append]

----- Uninstalling Options 	-----
    	
	Uninstalling a Package:
		install.pl  -uninstall SOLID  -host limsdev02 -dbase seqdev 		[-user super_cron -pass ******* ]
	Uninstalling ALL Package:
		install.pl  -uninstall <Any text> -host limsdev02 -dbase seqdev 	[-user super_cron -pass *******] -create_core

----- Upgrading Databases 	-----
	   	
	install.pl -upgrade_DB next    -host lims02 -dbase seqtest      	[-variation <Variation> -user super_cron -pass *******]
		(updates to leading edge of current version)
	install.pl -upgrade_DB current      -host lims02 -dbase seqtest 	[-variation <Variation>  -user super_cron -pass *******]
		(upgrades to the leading edge of next version)

----- 		Other	 		-----
	    
	Finding String in a Patch:
		install.pl -search Queue [-db_version 2.6 -scope Core]
	Create Links (Not the whole package install)
		install.pl  -create_links beta  -package SOLID  
	Checking installation integrity:
		install.pl -integrity <HOST>:<DATABASE>
            
END
    if ($help) {
        print <<END;
            
    Options:
    ###################
    Actions:
        -patch  		    Comma seperated list of patch file names (eg install_SOLID_2_6.pat)
        -package            Package_Name (eg SOLID)
        -create_links       code version (beta,production,test,dcheng,rguin ...)
        -upgrade_DB         enum: next or current
        -build              Package Name to be built  (SOLID)
        -create_patches     Package Name: (Tray)
        -uninstall          Package Name: (Tray)
        -crontab            Package Names: (Tray,SOLID,Sequencing) 
        -search             Queue 
        -generate           full path of newly generated patch file ('/path/to/new_file.pat' )
        -integrity          host and database seperated by ':' eg limsdev02:seqdev
        -App
        
    Other:
        -db_version         database version (2.6,2.7,3.0) 
        -schema             full path to schema sql file
        -data               full path to data sql file
        -bin                full path binary file
        -final              full path to finalizing sql file (to be run after dbfield set)
        -scope              scope of pakcage for search option (Core)
        -variation          
        -type               Department
        -add_ons            API
        -category           enum: Plugins, Options,Core or custom
        -create_core        a flag
        -append             used for crontab appends crontab instead of a new one (skips file headers only doesnt delete existing cronjobs)
        -test               used for crontab doesnt install crontab just creates cron files 
        -test               used with patch doesnt change version tracker file

END
    }
    exit;
}

##########################################################
#       Internal Functions
##########################################################
#######################################
sub complete_package_installation {
#######################################
    my %args    = filter_input( \@_ );
    my $package = $args{ -package };
    my $debug   = $args{-debug};
    my $result  = $dbc->Table_update_array( -table => 'Package', -fields => [ 'Package_Install_Status', 'Package_Active' ], -values => [ 'Installed', 'y' ], -condition => "WHERE Package_Name = '$package'", -autoquote => 1 );

    run_dbfield_set( -dbc => $dbc );

    if ($result) { Message "Installation recorded" }
    return;
}

##################################
sub get_database_version {
##################################
    #   This function returns the current databaase version
##################################
    my %args = filter_input( \@_ );

    #    my $dbc     ||= $args{-dbc};
    my ($version) = $dbc->Table_find( 'Version', 'Version_Name', "WHERE Version_Status = 'In use'" );
    return $version;
}

##################################
sub get_daughter_packages {
##################################
    my $package_id = shift;
    my @parent_ids = ($package_id);
    my @all_packages;

    while ( int @parent_ids > 0 ) {
        my $list = join ',', @parent_ids;
        my @daughters = $dbc->Table_find( 'Package', 'Package_ID', "WHERE FKParent_Package__ID IN  ($list) " );
        push @all_packages, @daughters;
        @parent_ids = @daughters;
    }
    return @all_packages;
}

##################################
sub get_DBM_text {
##################################
    #   Return text related to DBField and DBTable
    #
##################################
    my %args        = filter_input( \@_ );
    my $dbc         = $args{-dbc};
    my $package     = $args{ -package };
    my $field_ref   = $args{-field};
    my $table_ref   = $args{-table};
    my @fields_info = @$field_ref if $field_ref;
    my @tables      = @$table_ref if $table_ref;
    my @dbfields    = ( 'Field_Description', 'Prompt', 'Field_Options', 'Field_Reference', 'Field_Order', 'Field_Format', 'Editable', 'Tracked' );
    my $text;

    #### DBTable
    for my $table (@tables) {
        $text .= " UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = '$table' AND Package.Package_Name = '$package' ;\n";
    }
    $text .= "\n";
    my $tables_list = join "','", @tables;
    my @t_fields = $dbc->Table_find( 'DBField', 'Field_Name,Field_Table,DBField_ID', "WHERE Field_Table IN ('$tables_list' )" );

    push @t_fields, @fields_info;

    for my $t_field_info (@t_fields) {
        my ( $f_name, $f_table, $f_id ) = split ',', $t_field_info;
        $text .= "UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = '$f_name' AND  Field_Table ='$f_table' AND Package.Package_Name = '$package' ;\n";
        for my $dbfield (@dbfields) {
            ( my $value ) = $dbc->Table_find( 'DBField', $dbfield, " WHERE DBField_ID = $f_id " );
            $value =~ s/\'/\"/g;
            $text .= qq[UPDATE DBField SET $dbfield = '$value' WHERE Field_Name = '$f_name' AND  Field_Table ='$f_table' ;\n];
        }
        $text .= "\n";
    }
    return $text;
}

##################################
sub get_description {
##################################
    #   This function returns the patch description
##################################
    my %args    = filter_input( \@_ );
    my $file    = $args{-file};
    my $package = $args{ -package };
    my $text    = " This patch is for package $package";
    return $text;
}

##################################
sub get_field_text {
##################################
    my %args        = filter_input( \@_ );
    my $dbc         = $args{-dbc};
    my $package     = $args{ -package };
    my $field_ref   = $args{-field};
    my @fields_info = @$field_ref if $field_ref;

    my $text;
    my $temp;
    my @lines;

    for my $field_info (@fields_info) {

        ( my $field_name, my $table_name, my $db_id ) = split ',', $field_info;
        my $command         = "show  create table $table_name ";
        my $table_structure = try_system_command("$connect -e  \'$command\'");
        if ( $table_structure =~ /(CREATE TABLE .+)/ ) {
            $temp .= $1;
        }
        $temp =~ s/\\n/\n/g;
        my @table_struct = split "\n", $temp;

        for my $line (@table_struct) {
            $line =~ s/\,$//;
            if ( $line =~ /(.+\`$field_name\`.+)/ ) { push @lines, $line }
        }
        my $build_command = "Alter Table $table_name ADD COLUMN $lines[0] ;";
        my $index_command;
        if ( $lines[1] =~ /(.+)KEY.*(\`.*\`) \((\`.*\`)\)/ ) {
            $index_command = "CREATE $1 INDEX $2 ON $table_name ($3) ;";
        }

        $text .= $build_command . "\n" . $index_command . "\n";
    }

    return $text;

}

##################################
sub get_fields {
##################################
    #   Description:
    #       - This function gets the list of fields whose tables dont belong to this package but they do
    #
##################################
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $package    = $args{ -package };
    my $package_id = $args{-package_id};
    my $table_ref  = $args{-table};

    my $tables = join "','", @$table_ref if $table_ref;
    my @table_ids = $dbc->Table_find( 'DBTable', 'DBTable_id', "WHERE DBTable_Name IN ('$tables')" );
    my $table_id_list = join ',', @table_ids;
    my @fields_info = $dbc->Table_find( 'DBField', 'Field_Name,Field_Table,DBField_ID', "WHERE FK_Package__ID = $package_id and FK_DBTable__ID NOT IN ($table_id_list)" ) if $table_id_list;
    unless ($table_id_list) {
        @fields_info = $dbc->Table_find( 'DBField', 'Field_Name,Field_Table,DBField_ID', "WHERE FK_Package__ID = $package_id " );
    }
    return \@fields_info;

}

##################################
sub get_file {
##################################
    #   This function returns the target file and it's path
##################################
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $package = $args{ -package };
    my $version = $args{-version} || get_database_version( -dbc => $dbc );
    my $file;
    my $path;

    my ($category) = $dbc->Table_find( 'Package', 'Package_Scope', " WHERE Package_Name = '$package' " );
    if ( $category eq 'Core' ) {
        Message 'Cant do that to core';
        $path = $FindBin::RealBin . "../../install/patches/Core/$version/";
        $file = 'install_' . $package . '_' . $version . '.pat';
        exit;
    }
    elsif ($category) {
        $path = $FindBin::RealBin . "/../../$category/$package/install/patches/$version/";
        $version =~ s/\./\_/;
        $file = 'install_' . $package . '_' . $version . '.pat';
    }
    else {
        Message "Package $package does not exist in $dbase database";
        exit;
    }
    return $path . $file;
}

##################################
sub get_Package_ID {
##################################
    #   This function returns the package id
##################################
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $package = $args{ -package };
    my ($info) = $dbc->Table_find( 'Package', 'Package_ID,Package_Install_Status,Package_Active', "WHERE Package_Name = '$package' " );
    my ( $id, $install, $active ) = split ',', $info;
    unless ($id) {return}
    if ( $install ne 'Installed' ) { Message "WARNING: Package $package is $install" }
    if ( $active eq 'n' ) { Message "WARNING: Package $package is not active" }
    return $id;
}

##################################
sub get_table_text {
##################################
    my %args      = filter_input( \@_ );
    my $dbc       = $args{-dbc};
    my $package   = $args{ -package };
    my $table_ref = $args{-table};
    my @tables    = @$table_ref if $table_ref;
    my $text;
    for my $table (@tables) {
        my $command         = "show  create table $table ";
        my $table_structure = try_system_command("$connect -e  \'$command\'");

        if ( $table_structure =~ /(CREATE TABLE .+)/ ) {
            $text .= $1;
        }
        $text =~ s/\\n/\n/g;
        $text .= ";\n\n";
    }
    return $text;
}

##################################
sub get_tables {
##################################
    #   Description:
    #       - This function gets the list of tables belonging to package
    #
##################################
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $package = $args{ -package };

    my @tables = $dbc->Table_find( 'DBTable,Package', 'DBTable_Name', "WHERE FK_Package__ID = Package_ID and Package.Package_Name = '$package' " );
    return \@tables;

}

##################################
sub initiate_installation {
##################################
    my %args     = filter_input( \@_ );
    my $package  = $args{ -package };
    my $debug    = $args{-debug};
    my $install  = $args{-install};
    my $category = $args{-category};
    my $parent   = $args{-parent};
    my $package_id;

    my $install_status = $install->get_Package_Status( -package => $package, -debug => $debug );

    if ( $install_status eq 'Installed' ) {
        Message "Package $package is already $install_status";
        exit;
    }
    elsif ( !$install_status & !$confirmed ) {
        unless ($category) {
            $category = Prompt_Input( -prompt => "Please enter category (Plugins,Options,custom): " );
        }
        unless ($parent) {
            $parent = Prompt_Input( -prompt => "Please enter parent Package: " );
        }
        $package_id = $install->add_Package_record(
            -package        => $package,
            -category       => $category,
            -debug          => $debug,
            -parent_package => $parent
        );
        unless ($package_id) { exit; }
    }

    return 1;
}

##################################
sub install_package_version {
##################################
    my %args    = filter_input( \@_ );
    my $package = $args{ -package };
    my $version = $args{-db_version};

    $install->install_Package_patches( -package => $package, -version => $version );
}

##################################
sub install_package_patches {
##################################
    my %args    = filter_input( \@_ );
    my $package = $args{ -package };
    my $version = $install->get_Current_Database_Version();
    my @all_patches;
    my $vt_files = $install->get_Version_Tracker_Files( -debug => $debug );
    my $patches = $install->get_Package_Pacthes_from_version_tracker( -file => $vt_files, -package => $package, -version => $version, -debug => $debug );
    my @patches = @$patches if $patches;
    if ($debug) {
        Message "Patches found for Package $package - version $version ";
        print Dumper \@patches;
    }

    my $previous_install_success = 1;
    my $patch_version;

    for my $patch (@patches) {
        if ($previous_install_success) {
            my $patch_info = $install->get_patch_info( -file => $patch, -debug => $debug );
            if ($patch_info) {
                my %info = %$patch_info if $patch_info;
                if ( !$info{PACKAGE} )  { Message "No Package found fo patch $patch" }
                if ( !$info{CATEGORY} ) { Message "No Category found fo patch $patch" }
                if ( !$info{VERSION} )  { Message "No Version found fo patch $patch" }

                if ( $info{PACKAGE} && $info{CATEGORY} && $info{VERSION} && $info{PATCH} ) {
                    Message "Installing  $info{PATCH} - $info{VERSION}  -  $info{PACKAGE}  [  $info{CATEGORY} ]  ... ";
                    $patch_version = $install->install_Patch(
                        -patch         => $info{PATCH},
                        -package       => $info{PACKAGE},
                        -category      => $info{CATEGORY},
                        -version       => $info{VERSION},
                        -debug         => $debug,
                        -test          => $test,
                        -group_version => $patch_version
                    );
                    $previous_install_success = 0 unless $patch_version;
                }
                else {
                    exit;
                }
            }
            else {
                Message "Could complete the installation of $patch";
                exit;
            }
        }
    }

    if ($previous_install_success) {
        complete_package_installation(
            -dbc     => $dbc,
            -package => $package,
            -debug   => $debug,
            -install => $install
        );
    }
}

##################################
sub record_uninstallation {
##############################################
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $package_id = $args{ -package };

    $dbc->Table_update_array(
        -table     => 'Package',
        -fields    => [ 'Package_Install_Status', 'Package_Active' ],
        -values    => [ 'Not installed', 'n' ],
        -condition => "WHERE Package_ID IN ($package_id)",
        -autoquote => 1
    );

    $dbc->Table_update_array(
        -table     => 'Patch',
        -fields    => ['Install_Status'],
        -values    => ['Not installed'],
        -condition => "WHERE FK_Package__ID IN ($package_id)",
        -autoquote => 1
    );

    Message "patches have been uninstalled";
    return;

}

##################################
sub run_dbfield_set {
##############################################
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $install = new SDB::Installation( -dbc => $dbc, -simple => 1 );
    $install->run_dbfield_set();
    return;

}

##################################
sub write_to_file {
##################################
    my %args        = filter_input( \@_ );
    my $dbc         = $args{-dbc};
    my $package     = $args{ -package };
    my $field_text  = $args{-f_text};
    my $table_text  = $args{-t_text};
    my $dbm_text    = $args{-d_text};
    my $file        = $args{-file};
    my $description = $args{-desc};

    Message " opening and writing:  $file ";
    open( FILE, "> $file" ) or die "Unable to open temp file  (attempted to open $file for writing)";
    print FILE "<DESCRIPTION> \n";
    print FILE "$description \n";
    print FILE "</DESCRIPTION> \n";
    print FILE "<SCHEMA>  \n";
    print FILE "$table_text \n\n\n";
    print FILE " $field_text\n";
    print FILE "</SCHEMA>  \n";
    print FILE "<FINAL> \n";
    print FILE "$dbm_text \n";
    print FILE "</FINAL> \n";
    close FILE;
    Message " Writing finished";
    return 1;
}

##################################
sub _check_SVN {
##################################
    my $path;
    my $command = " svn info $FindBin::RealBin";
    my @results = split "\n", try_system_command($command);
    for my $line (@results) {
        if ( $line =~ /^URL\: (.+)/ ) { $path = $1 }
    }
    if ( $path =~ /trunk/ ) { return 1; }
    return;
}

##################################
sub get_sub_directories {
##################################
    my $target_dir        = $FindBin::RealBin . '/../../lib/perl/';
    my $find_dir_command  = "find  $target_dir -type d -maxdepth 1 -mindepth 1";
    my $find_link_command = "find  $target_dir -type l -maxdepth 1 -mindepth 1";
    my @temp_results;
    my @list;
    my @result = split "\n", try_system_command($find_dir_command);
    push @temp_results, @result;
    @result = split "\n", try_system_command($find_link_command);
    push @temp_results, @result;

    for my $temp (@temp_results) {
        if ( $temp =~ /\.svn/ ) {next}
        if ( $temp =~ /\/lib\/perl\/(.+)/ ) {
            push @list, $1;
        }
    }
    my @final = sort { $a cmp $b } @list;
    return @final;
}

1;
