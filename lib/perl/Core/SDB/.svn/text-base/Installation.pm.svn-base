###################################################################################################################################
# SDB::Installation.pm
#
# Contains the business logic and data of the application
#
###################################################################################################################################
package SDB::Installation;

use strict;
use FindBin;
## Imported
use CGI qw(:standard);
use Data::Dumper;
use FindBin;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use SDB::SVN;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::RGmath;
use RGTools::Process_Monitor;

use vars qw( $homelink %Configs );

my $root = $FindBin::RealBin;
if ($root =~/(.*)\/bin\/(.*)/) { $root = $1 }
elsif ($root =~ /(.*)\/install/) { $root = $1 }

########################################################################
######################          Constructor               ##############
########################################################################

####################################
sub new {
#####################
    my $this    = shift;
    my %args    = &filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $report  = $args{-report};
    my $simple  = $args{-simple};
    my $version = $args{-version};
    my $prompt  = $args{-prompt};         ## run in prompt mode
    my $self    = {};

    $self->{dbc} = $dbc;
    $self->{version};
    $self->{packages} = {
        marked_for_install => [],
        newly_installed    => [],
        installed          => [],
        active             => [],
        available          => [],
    };

    $self->{patches} = {
        marked_for_install => [],
        newly_installed    => [],
        installed          => [],
        available          => {
            'core'   => {},
            'addons' => {},
        }
    };
    $self->{report}      = $report;
    $self->{prompt_mode} = $prompt;

    if ($simple) {
        my ($class) = ref($this) || $this;
        bless $self, $class;
        $self->{version} = $version || $self->get_db_version();
        return $self;
    }

    my @installed_packages;
    my @active_packages;
    my @marked_for_install_packages;

    if ( $dbc->table_loaded('Package') ) {
        @installed_packages          = $dbc->Table_find( 'Package', "Package_Name", "WHERE Package_Install_Status = 'Installed'" );
        @active_packages             = $dbc->Table_find( 'Package', "Package_Name", "WHERE Package_Active = 'y'" );
        @marked_for_install_packages = $dbc->Table_find( 'Package', "Package_Name", "WHERE Package_Install_Status = 'Marked for Install'" );
    }

    my @marked_for_install_patches;
    my @installed_patches;
    if ( $dbc->table_loaded('Patch') ) {
        @marked_for_install_patches = $dbc->Table_find( 'Patch', "Patch_ID", "WHERE Install_Status = 'Marked for Install'" );
        @installed_patches          = $dbc->Table_find( 'Patch', "Patch_ID", "WHERE Install_Status = 'Installed'" );
    }
    
    $self->{packages}{marked_for_install} = \@marked_for_install_packages;
    $self->{packages}{installed}          = \@installed_packages;
    $self->{packages}{active}             = \@active_packages;
    $self->{patches}{marked_for_install}  = \@marked_for_install_patches;
    $self->{patches}{installed}           = \@installed_patches;

    my ($class) = ref($this) || $this;
    bless $self, $class;
    $self->{version} = $self->get_db_version();

    $self->{root} = $root;

    return $self;
}
########################################################################
######################          Main Methods              ##############
########################################################################

#######################
sub get_hot_fix_dir {
#######################
    my $self         = shift;
    my %args         = filter_input( \@_ );
    my $revision     = $args{-revision};
    my $type         = $args{-type} || 'test';      ## enum test, production
    my $root         = $Configs{Code_Update_dir};
    my $code_version = get_current_version();

    my $path      = $root . '/' . $code_version;
    my $dir       = &create_dir( -path => $path, -subdirectory => 'rev_' . $revision );
    my $final_dir = &create_dir( -path => $dir, -subdirectory => $type );
    return $final_dir;
}

####################################
sub get_root_tag_directory {
####################################
    my %args    = filter_input( \@_, -mandatory => 'root' );
    my $root    = $args{-root};                                # bin directory of the code version running
    my $version = get_current_version();
    my $path    = "$root/install/tags/" . $version;
    return $path;
}

####################################
sub get_tag_file_name {
####################################
    my %args         = filter_input( \@_ );
    my $debug        = $args{-debug};                                              # debug flag
    my $svn_revision = $args{-svn_revision} || $args{-revision};                   # list of files space seperated
    my $ticket       = $args{-ticket};
    my $root         = $args{-root};                                               # bin directory of the code version running
    my $type         = $args{-type} || 'txt';
    my $path         = $args{-path} || get_root_tag_directory( -root => $root );

    my $time_tag = timestamp();
    my $dir;
    if ($ticket) {
        $dir = &create_dir( -path => $path, -subdirectory => $ticket );
    }
    else {
        $dir = $path;
    }

    my $file = $dir . '/' . $time_tag;
    if ($svn_revision) {
        $file .= '__rev_' . $svn_revision;
    }
    $file .= ".$type";

    return $file;
}

####################################
sub tag {
####################################
    my %args     = filter_input( \@_ );
    my $debug    = $args{-debug};                              # debug flag
    my $type     = $args{-type} || 'tag';
    my $dir      = $args{-dir};
    my $revision = $args{-svn_revision} || $args{-revision};

    my $tag_file = get_tag_file_name( -path => $dir, -revision => $revision, -type => $type );

    if ( $type =~ /tag/i || $type =~ /failed/i ) {
        my $start_file = get_tag_file_name( -path => $dir, -revision => $revision, -type => 'start' );
        $start_file =~ s/\d{14}/\*/;

        my $command  = "rm $start_file ";
        my $response = try_system_command($command);
        Message $response if $response;
    }

    open my $TEMP, '>', $tag_file or die "CANNOT OPEN $tag_file";
    my $command  = "echo 'TEST TEXT' >> $tag_file ";
    my $response = try_system_command($command);
    Message $response if $response;
    close $TEMP;

    return;
}

####################################
sub record_commit {
####################################
    my %args   = filter_input( \@_, -mandatory => 'ticket,files,root' );
    my $debug  = $args{-debug};                                            # debug flag
    my $files  = $args{-files};                                            # list of files space seperated
    my $ticket = $args{-ticket};
    my $root   = $args{-root};                                             # bin directory of the code version running
    my $tag    = $args{ -tag };                                            # bin directory of the code version running

    SDB::SVN::update( -file =>  "$root/install/tags/" );

    my @files = split /\s/, $files;
    my $svn_revision = SDB::SVN::get_revision( -file => $files[0] );

    my $commit_file = get_tag_file_name( -root => $root, -ticket => $ticket, -svn_revision => $svn_revision );
    my $tag_file = get_tag_file_name( -root => $root, -ticket => $ticket, -svn_revision => $svn_revision, -type => 'tag' );

    open my $TEMP, '>', $commit_file or die "CANNOT OPEN $commit_file";

    for my $file (@files) {
        my $command  = "echo '$file' >> $commit_file ";
        my $response = try_system_command($command);
        Message $response if $response;
    }
    close $TEMP;

    my $path = get_root_tag_directory( -root => $root ) . '/' . $ticket;

    ##  GOTTA make sure directory is under version conrol
    my $rev = SDB::SVN::get_revision( -file => $path );
    if ($rev) {
        SDB::SVN::add( -file => $commit_file );
        SDB::SVN::commit( -file => $commit_file, -message => "Recording the commit of file", -debug => $debug );
    }
    else {
        SDB::SVN::add( -file => $path );
        SDB::SVN::commit( -file => $path, -message => "Recording the commit of directory", -debug => $debug );
    }

    if ($tag) {

        open my $TEMP, '>', $tag_file or die "CANNOT OPEN $tag_file";
        my $command  = "echo 'TEST TEXT' >> $tag_file ";
        my $response = try_system_command($command);
        Message $response if $response;
        close $TEMP;

        SDB::SVN::add( -file => $tag_file, -debug => $debug );
        SDB::SVN::commit( -file => $tag_file, -message => "Tagging Code", -debug => $debug );

    }

    return 1;

}

####################################
sub get_current_version {
####################################
    return $Configs{CODE_VERSION};
}

####################################
sub graph_directory_size {
####################################
    my %args  = filter_input( \@_ );
    my $debug = $args{-debug};          # debug flag
    my $dir   = $args{-dir};
    my $host  = $args{-host};
    my $range = $args{-range} || 30;    # in days
    my @sizes;
    my $count;
    for ( $count = $range; $count >= 0; $count-- ) {
        my ( $year, $month, $date ) = split '-', &today("-$count");
        my $file    = $Configs{Sys_monitor_dir} . '/' . $host . '/' . $year . '/' . $month . '/' . $date . '/' . 'size.stats';
        my $command = "cat $file ";
        my $results = try_system_command($command);
        if ( $results =~ /$dir\s+(.+)/ ) {
            push @sizes, $1;
        }
        Message $command if $debug;

    }
    print Dumper \@sizes;

}

####################################
sub initialize_mysql_db {
####################################
    # Description:
    #   - This function adds user and db info to mysql database
    # Input:
    #   - login:    database login info such as user,password,host and database
    # Output:
    #   -
    # Exapmle:
    # <snip>
    # </snip>
####################################
    my %args        = filter_input( \@_ );
    my $version     = $args{-version};
    my $debug       = $args{-debug};                   # debug flag
    my $mysql_login = $args{-login};
    my %mysql_login = %$mysql_login if $mysql_login;
    my $host        = $mysql_login{host};
    my $dbase       = $mysql_login{database};
    my $username    = $mysql_login{user};
    my $passwd      = $mysql_login{password};
    my $file .= "$root/conf/lims_users_core.pat";
    my %sections = get_lines_between_tags( -filepath => "$file" );

    if ( $mysql_login{database} ne 'mysql' ) {
        Message "Incorrect database name entered( $mysql_login{database} )  should be mysql";
        return;
    }

    my $dbc = new SDB::DBIO(
        -host     => $mysql_login{host},
        -dbase    => $mysql_login{database},
        -user     => $mysql_login{user},
        -password => $mysql_login{password},
        -connect  => 1
    );
    unless ($dbc) {
        Message 'No database connection stablished';
        return;
    }

    $dbc->run_sql_array( -array => $sections{'DATA'}, -debug => $debug ) if $sections{'DATA'};
    return 1;

}

####################################
sub build_core_db {
####################################
    # Description:
    #   - This Fucntion build a new database same as the release version of Core
    # Input:
    #   - mysql login:  A hash reference containing host,database,user and password for mysql
    #   - version:      The version being installed
    # Exapmle:
    # <snip>
    #       SDB::Installation::build_core_db (-version => '2.6',-login => \%mysql_login );
    # </snip>
####################################
    my %args        = filter_input( \@_ );
    my $version     = $args{-version};
    my $debug       = $args{-debug};                   # debug flag
    my $mysql_login = $args{-login};
    my %mysql_login = %$mysql_login if $mysql_login;
    my $host        = $mysql_login{host};
    my $dbase       = $mysql_login{database};
    my $username    = $mysql_login{user};
    my $passwd      = $mysql_login{password};
    my $feedback;

    my $core_init_dir  = "$root/install/init/release/$version/";
    my $connect        = qq{ mysql -u $mysql_login{user} --password=$mysql_login{password} -h $mysql_login{host}};
    my $create_command = qq{ $connect -e 'CREATE DATABASE /*!32312 IF NOT EXISTS*/ $mysql_login{database};'};
    $feedback = try_system_command($create_command);
    if ($debug) {
        $create_command =~ s/$passwd/\*\*\*\*\*\*\*/g;
        Message $create_command ;
        Message $feedback;

        #  $Report->set_Message("Command: $create_command");
    }

    my $build_command
        = "$root/bin/restore_DB.pl -rebuild -local LOCAL -host $mysql_login{host} -dbase $mysql_login{database} -directory $core_init_dir -force -user $mysql_login{user} -password $mysql_login{password} -from limsdev02:Core";
    $feedback = try_system_command($build_command);
    if ($debug) {
        $build_command =~ s/$passwd/\*\*\*\*\*\*\*/g;
        Message $build_command ;
        Message $feedback;

        #   $Report->set_Message("Command: $build_command");
    }
    return;
}

####################################
sub install_Package {
####################################
    # Description:
    #   - This function installs a package
    # Input:
    #   - package (mandatory) name of the package being installed
    #   - verison   veriosn of package (2.6,2.7,3.0 ....)
    # Output:
    #   - 1 on success 0 on failure
    # Exapmle:
    # <snip>
    #   $install -> install_Package (-package => $package,-version=>$version);
    # </snip>
####################################
    my $self           = shift;
    my %args           = filter_input( \@_, -mandatory => 'package,version' );
    my $package        = $args{ -package };
    my $version        = $args{-version};
    my $debug          = $args{-debug};                                          # debug flag
    my $test           = $args{-test};
    my $dbc            = $args{-dbc} || $self->{dbc};
    my $parent_package = $args{-parent_package};
    my $Report         = $args{-report} || $self->{report};
    my $append         = $args{-append};

    my $status = $self->get_Package_Status( -package => $package );
    if ( $status eq 'Installed' ) {
        Message "Package $package is $status ";
        return;
    }
    my $result;

    $version =~ s/\./_/;
    my $patch = 'install_' . $package . '_' . $version . '.pat';
    my $patch_info = $self->get_patch_info( -file => $patch, -debug => $debug );
    if ($patch_info) {
        my %info = %$patch_info if $patch_info;
        if ( !$info{PACKAGE} )  { Message "No Package found fo patch $patch" }
        if ( !$info{CATEGORY} ) { Message "No Category found fo patch $patch" }
        if ( !$info{VERSION} )  { Message "No Version found fo patch $patch" }
        if ( $info{CATEGORY} eq 'custom' ) {
            ( my $other_custom ) = $dbc->Table_find( 'Package', 'Package_Name', " WHERE Package_Scope = 'custom' and Package_Install_Status = 'Installed' " );
            if ($other_custom) {
                Message " You can only install one custom package. Custom pakcage $other_custom already installed ! ";
                return;
            }
        }

        if ( $info{PACKAGE} && $info{CATEGORY} && $info{VERSION} && $info{PATCH} ) {
            Message "Installing  $info{PATCH} - $info{VERSION}  -  $info{PACKAGE}  [  $info{CATEGORY} ]  ... ";
            my $patch_version = $self->install_Patch(
                -patch    => $info{PATCH},
                -package  => $info{PACKAGE},
                -category => $info{CATEGORY},
                -version  => $info{VERSION},
                -append   => $append,
                -debug    => $debug,

                #  -parent_package => $parent_package ,
                -test => $test
            );
            $result = $dbc->Table_update_array( -table => 'Package', -fields => [ 'Package_Install_Status', 'Package_Active' ], -values => [ 'Installed', 'y' ], -condition => "WHERE Package_Name = '$package'", -autoquote => 1, -no_triggers => 1 );

        }
        else {
            Message "Could complete the installation of $patch";
            exit;
        }

    }
    return $result;

}

####################################
sub install_Package_patches {
####################################
    # Description:
    #   - This function installs a package and all the patches associated with it
    # Input:
    #   - package (mandatory) name of the package being installed
    #   - verison veriosn of package (e.g. 2.6)
    # Output:
    #   - 1 on success 0 on failure
    # Exapmle:
    # <snip>
    #   $install -> install_Package_patches (-package => $package,-version=>$version);
    # </snip>
####################################
    my $self           = shift;
    my %args           = filter_input( \@_, -mandatory => 'package,version' );
    my $package        = $args{ -package };
    my $version        = $args{-version};
    my $debug          = $args{-debug};                                          # debug flag
    my $test           = $args{-test};
    my $dbc            = $args{-dbc} || $self->{dbc};
    my $parent_package = $args{-parent_package};
    my $Report         = $args{-report} || $self->{report};
    my $append         = $args{-append};

    my $vt_files = $self->get_Version_Tracker_Files( -debug => $debug );
    my $patches = $self->get_Package_Pacthes_from_version_tracker( -file => $vt_files, -package => $package, -version => $version, -debug => $debug );
    my @patches = @$patches if $patches;
    if ($debug) {
        Message "Patches found for Package $package - version $version ";
        print Dumper \@patches;
    }

    my $result = 0;
    for my $patch (@patches) {
        my $patch_info = $self->get_patch_info( -file => $patch, -debug => $debug );
        if ($patch_info) {
            my %info = %$patch_info if $patch_info;
            if ( !$info{PACKAGE} )  { Message "No Package found fo patch $patch" }
            if ( !$info{CATEGORY} ) { Message "No Category found fo patch $patch" }
            if ( !$info{VERSION} )  { Message "No Version found fo patch $patch" }
            if ( $info{CATEGORY} eq 'custom' ) {
                ( my $other_custom ) = $dbc->Table_find( 'Package', 'Package_Name', " WHERE Package_Scope = 'custom' and Package_Install_Status = 'Installed' " );
                if ($other_custom) {
                    Message " You can only install one custom package. Custom pakcage $other_custom already installed ! ";
                    return;
                }
            }

            if ( $info{PACKAGE} && $info{CATEGORY} && $info{VERSION} && $info{PATCH} ) {
                Message "Installing  $info{PATCH} - $info{VERSION}  -  $info{PACKAGE}  [  $info{CATEGORY} ]  ... ";
                my $patch_version = $self->install_Patch(
                    -patch    => $info{PATCH},
                    -package  => $info{PACKAGE},
                    -category => $info{CATEGORY},
                    -version  => $info{VERSION},
                    -append   => $append,
                    -debug    => $debug,
                    -test     => $test
                );
            }
            else {
                Message "Could complete the installation of $patch";
                exit;
            }
        }
    }

    $result = $dbc->Table_update_array( -table => 'Package', -fields => [ 'Package_Install_Status', 'Package_Active' ], -values => [ 'Installed', 'y' ], -condition => "WHERE Package_Name = '$package'", -autoquote => 1, -no_triggers => 1 );
    return $result;
}

####################################
sub create_Template_Files {
####################################
    # Description:
    #   -
    # Input:
    #   -
    #   -
    # Output:
    #   -
    # Exapmle:
    # <snip>
    #
    # </snip>
####################################
    my %args     = filter_input( \@_ );
    my $location = $args{-location};
    my $debug    = $args{-debug};
    my $name     = $args{-name};
    my $version  = $args{-version};

    my $source_dir = "$root/template/Package_Options/Standard_App/modules";
    my $target_dir = "$root/lib/perl/$location";
    Message "Creating files in $target_dir";

    ########  GENERATE the files and modify them
    my $copy_command = "cp $source_dir/*.*  " . "$source_dir/tmp/";
    Message $copy_command;
    Prompt_Input( -prompt => "test: " );
    _execute_command( -command => $copy_command, -debug => $debug );

    my $rename_command = "$FindBin::RealBin/rename.pl -s Template -r $name -d $source_dir/tmp/ -R >  /dev/null";
    _execute_command( -command => $rename_command, -debug => $debug );
    Message $rename_command;
    Prompt_Input( -prompt => "test: " );

    my $deletion_command = "rm $source_dir/tmp/Template* ";
    Message $deletion_command;
    Prompt_Input( -prompt => "test: " );
    _execute_command( -command => $deletion_command, -debug => $debug );

    ######## Check to see if files exist
    my $find_command = "find  $source_dir/tmp/ -name $name" . "*.pm ";
    my @results = split "\n", try_system_command($find_command);
    for my $line (@results) {
        if ( $line =~ /\/($name.+)$/ ) {
            ## Now check target location to find file
            my $find_command = "find  $target_dir -name $1";
            my $result       = try_system_command($find_command);
            if ($result) {
                chomp $result;
                Message "The file $1 already exist in target directory, skipping ... ";
                my $deletion_command = "rm $source_dir/tmp/$1 ";
                _execute_command( -command => $deletion_command, -debug => $debug );
            }
        }
    }
    ######## Copy them to target
    my $copy_command = "cp $source_dir/tmp/*.pm  " . "$target_dir/";
    Message $copy_command;
    _execute_command( -command => $copy_command, -debug => $debug );
    my $deletion_command = "rm $source_dir/tmp/* ";
    _execute_command( -command => $deletion_command, -debug => $debug );

    Message "Done!";
    return 1;
}

####################################
sub create_Package {
####################################
    # Description:
    #   - creates the directory structure and files necessary for this custom/plugin
    #   - independent from version of code
    # Input:
    #   - package name (mandatory), this will be the name of directory as well it will be included in file names
    #   - path (the directory where everything will be created) uses current directory if not supplied
    #   - add_on : a comma seperated list of extra packages that will be installed with this custom/plugin
    #   - type: if the package is a standard one u can select the type (look at get_Package_Type_hash to get or add different types)
    # Output:
    #   - path on success 0 on failure
    # Exapmle:
    # <snip>
    #   create_Package (-package => 'SOLID' , -type =>'Department');
    # </snip>
####################################
    #my $self = shift; ## doesnt really need to be a method at this point
    my %args         = filter_input( \@_, -mandatory => 'package,category|path' );
    my $package_name = $args{ -package };
    my $type         = $args{-type} || 'Standard_App';                               # package type
    my $path         = $args{-path};                                                 # target path
    my $category     = $args{-category};                                             # Plugin || custom
    my $debug        = $args{-debug} || 1;                                           # debug flag
    my $add_on       = $args{-add_on};                                               # the add on files needed to be added such as run files (comma seperated)
    my @add_ons      = split ',', $add_on;

    unless ($package_name) {return}
    unless ( ( !$category ) || ( $category eq 'Plugins' ) || ( $category eq 'custom' ) || ( $category eq 'Options' ) ) {
        Message "Invalid Category ($category) to create package";
        return;
    }
    my $source_dir = "$root/template/Package";
    my $target_dir;
    if    ($path)     { $target_dir = $path . "/$package_name" }
    elsif ($category) { $target_dir = "$root/$category/$package_name" }
    else              {return}

    ###### Copying Main branch
    my $copy_command = "cp -r $source_dir   $target_dir";
    _execute_command( -command => $copy_command, -debug => $debug );

    ######  Adding add on directories based on type
    if ($type) {
        my $type_ref     = get_Package_Type_hash();
        my %type_hash    = %$type_ref;
        my @type_add_ons = split ',', $type_hash{$type};
        push @add_ons, @type_add_ons;
    }

    for my $add_on_dir (@add_ons) {
        my $copy_command = "cp $source_dir" . "_Options/$add_on_dir/modules/*.* $target_dir/modules";
        _execute_command( -command => $copy_command, -debug => $debug );

        my $find_command = 'find /' . $source_dir . "_Options/$add_on_dir/patches/ -maxdepth 1 -mindepth 1 -type d    ";
        my @results = split "\n", try_system_command($find_command);
        Message $find_command if $debug;
        for my $line (@results) {
            if ( ( $line =~ /.+\/(.+)$/ ) && !( $line =~ /no such file/i ) ) {
                my $ver_dir      = $1;
                my $copy_command = "cp  $source_dir" . "_Options/$add_on_dir/patches/$ver_dir/*.* $target_dir/install/patches/$ver_dir/";
                _execute_command( -command => $copy_command, -debug => $debug );
            }
        }
    }

    # renaming them from Template* to <package_name>*
    my $rename_command = $FindBin::RealBin . "/rename.pl -s Template -r $package_name -d $target_dir/modules -R  > /dev/null ";
    _execute_command( -command => $rename_command, -debug => $debug );

    my $find_command = 'find ' . "$root/$category/$package_name/install/patches -maxdepth 1 -mindepth 1 -type d    ";
    my @results = split "\n", try_system_command($find_command);
    Message $find_command if $debug;

    for my $line (@results) {
        if ( ( $line =~ /.+\/(.+)$/ ) && !( $line =~ /no such file/i ) ) {
            my $ver_dir        = $1;
            my $rename_command = "rename.pl -s Template -r $package_name -d $target_dir/install/patches/$ver_dir -R > /dev/null ";
            _execute_command( -command => $rename_command, -debug => $debug );

            my $deletion_command = "rm $target_dir/install/patches/$ver_dir/*Template* ";
            _execute_command( -command => $deletion_command, -debug => $debug );

        }
    }

    # deleting repetitions
    my $deletion_command = "rm $target_dir/modules/Template* ";
    _execute_command( -command => $deletion_command, -debug => $debug );

    # changing permission of files
    my $permission_command = "chmod 777 $target_dir/modules/* ";
    _execute_command( -command => $permission_command, -debug => $debug );

    # Remove .svn directors;
    my $cleanup_command = "find $target_dir -name '.svn' -type d | xargs -t rm -rf {} ";
    _execute_command( -command => $cleanup_command, -debug => $debug );

    return 1;
}

####################################
sub install_Package_links {
####################################
    # Description:
    #   - creates the necessary links for the custom/plugin package to be useable in version of code
    # Input:
    #   - package name (mandatory)
    #   - version of code (mandatory)
    #   - category : plugin or custom (mandatory)
    # Output:
    #   - bolean 1 on success 0 on failure
    # Exapmle:
    # <snip>
    #       install_Package (-package => 'SOLID' , -category => 'plugin', -version => 'beta')
    # </snip>
####################################
    #my $self = shift; ## doesnt really need to be a method at this point
    my %args         = filter_input( \@_, -mandatory => 'package,version,category' );
    my $package_name = $args{ -package };
    my $version      = $args{-version};
    my $category     = $args{-category};
    my $debug        = $args{-debug};                                                   # debug flag
    Message 'Initializing instalation';
    my $ok;
    unless ($package_name) {return}

    unless ( ( $category eq 'Plugins' ) || ( $category eq 'custom' ) || ( $category eq 'Options' ) ) {
        print Call_Stack();

        Message "Invalid Category ($category)";
        return;
    }

    ####### Installing the Code to library
    my $source_dir = "$root/$category/$package_name/modules/";                  ## good
                                                                                                #my $target_dir = $root .$version.'/lib/perl/'. $category.'/'.$package_name ;
    my $target_dir = "$root/$version/lib/perl/$package_name";

    my $link_command = "ln -s $source_dir  $target_dir";
    $ok = try_system_command($link_command);
    Message $link_command if $debug;
    Message $ok;

    ####### Installing the patches to install
    my $source_dir = "$root/$category/$package_name/install/patches/";                                ## good
    my $target_dir = "$root/$version/install/patches/$category/$package_name";

    my $link_command = "ln -s $source_dir  $target_dir";
    $ok = try_system_command($link_command);
    Message $link_command if $debug;
    Message $ok;

    ####### Installing the crontab links
    my $source_dir = "$root/$category/$package_name/cron/";                                ## good
    my $target_dir = "$root/install/crontab/";      
    
    my $link_command = "ln -s $source_dir  $target_dir";
    $ok = try_system_command($link_command);
    Message $link_command if $debug;
    Message $ok;

    ####### Installing the bin links
    my $source_dir = "$root/$category/$package_name/scripts/";                                ## good
    my $source_dir = "$root/$category/$package_name/scripts/";                ## good

    my $target_dir = "$root/$version/bin/$package_name";

    my $link_command = "ln -s $source_dir  $target_dir";
    $ok = try_system_command($link_command);
    Message $link_command if $debug;
    Message $ok;

    return;
}

####################################
sub install_Patch {
####################################
    # Description:
    #   This method installs one patch
    #   It makes sure it is not already installed
    #   If the patch doesnt exist in Patch table it adds it both to the table and the version_Tracker.txt file
    #   Installs it
    #   Reports the installation success
    # Input:
    #   -patch:     The name of the patch you are installing, MUST be the same as the file name and entry in 'Patch' table if it exists in there
    #   -category:  enum ( Core,  Plugins, custom, or Options)   only necesary when package is not in Package table.  If the package is in table is not reuired
    #               in fact if the category entered doesnt match package_scope cannot proceed
    #   -package:   The name of the package to which the patch belongs
    #   -version:   The version of code   (eg 2.5, 2.6 3.0) [it is also used to figure out if this is a hotfix or for development]
    #   -force:     The force flag, turns off the transaction so changes ( applicable to patch CONTENT only) get commited even if there are errors
    #   -parent_package:
    #               The name of the parent package (only required if the package doesnt already exist in database)
    #   -group_version:
    #               Group version indicates if the patch belongs to a certain group of patches so stheir version can be paired together
    #   -test       Avoids updating and commiting version_tracker file to svn
    # Output:
    #   0 on failure to add patch_version on sucess
    # Exapmle:
    # <snip>
    #       $self -> install_Patch (-dbc => $dbc , -patch => 'SOLID', -package => 'SOLID' , -category => 'Plugins' , version => '2.6' );
    # </snip>
####################################
    my $self           = shift;
    my %args           = filter_input( \@_, -mandatory => 'patch,package,version' );
    my $patch_name     = $args{-patch};
    my $package_name   = $args{ -package };                                            # This is necesary for times where the record doesnt exist in the patch table
    my $parent_package = $args{-parent_package};
    my $version        = $args{-version};
    my $category       = $args{-category};                                             # only one of ( Core,  Plugins, custom, or Options)
    my $debug          = $args{-debug};                                                # debug flag
    my $force          = $args{-force};                                                # force flag to continue with pressence of errors
    my $dbc            = $args{-dbc} || $self->{dbc};
    my $path           = $args{-path};
    my $patch_type     = $args{-patch_type} || 'installation';
    my $group_version  = $args{-group_version};
    my $test           = $args{-test};
    my $Report         = $args{-report} || $self->{report};
    my $prompt         = $self->{prompt_mode};                                         ## flag to allow for manual prompt for each patch
    my $nonlocal       = $args{-nonlocal};
    my $append         = $args{-append};

    if ($debug) {
        print Dumper \%args;
        Message "^ args going into install_patch";
    }
    $Report->start_sub_Section("Installing Patch: $patch_name ") if $Report;

    my $patch_status = $self->get_Patch_Status( -name => $patch_name, -version => $version, -dbc => $dbc, -debug => $debug );
    $Report->set_Message("Patch status is $patch_status") if $Report;

    if ( $patch_status =~ /^Installed/i ) {
        Message("Patch already $patch_status");
        return;
    }
    elsif ( $patch_status eq 'not found' ) {
        my $patch_added = $self->add_Patch_to_Version_tracker(
            -patch          => $patch_name,
            -debug          => $debug,
            -patch_type     => $patch_type,
            -category       => $category,
            -version        => $version,
            -package        => $package_name,
            -group_version  => $group_version,
            -test           => $test,
            -parent_package => $parent_package
        );
        if ( !$patch_added ) {
            Message 'Failed to add patch to version tracker';
            $Report->set_Message('Failed to add patch to version tracker') if $Report;
            return;
        }
        else {

            $Report->set_Message("Added patch $patch_name to version_tracker : $patch_added") if $Report;
        }
    }
    else {
        if ($debug) { Message "Patch in not installed nor not found it is [$patch_status]" }
    }

    my $up_to_date = $self->is_Installation_up_to_date( -patch => $patch_name, -dbc => $dbc, -version => $version, -debug => $debug, -package => $package_name );
    if ($debug) { Message "Installation is up to date" if $up_to_date }
    $Report->set_Message("Installation is up to date") if ( $up_to_date && $Report );

    if ( !$up_to_date ) {
        Message '======================== WARNING WARNING ===============================';
        Message 'Installation is not up to date';
        Message '========================================================================';
        $Report->set_Message("Installation is NOT up to date") if $Report;

        #$self -> log_Patch_installation (-status => 'Installation aborted',  -name => $patch_name);
        #return;
    }
    $self->set_Patch_Status( -name => $patch_name, -status => 'Installing' );

    if ($prompt) {
        my ($last_patch) = $dbc->Table_find( 'Patch', "Concat(Patch_Name, ': ', Install_Status)", "WHERE Patch_Name != '$patch_name' ORDER BY Patch_ID DESC LIMIT 1" );
        Message("Last Patch installed: $last_patch");
        my $continue = Prompt_Input( -prompt => "Install $patch_name ? (y/n/q)", -type => 'char' );
        if ( $continue =~ /q/i ) {exit}
        if ( $continue !~ /y/i ) { return 0; }
        Message("Continuing...");
    }

    my $installation_status = $self->run_Patch_file( -name => $patch_name, -dbc => $dbc, -path => $path, -force => $force, -debug => $debug, -nonlocal => $nonlocal, -append => $append );
    $Report->set_Message("$installation_status ") if $Report;
    $self->update_Package_fks( -package => $package_name );
    $self->log_Patch_installation( -status => $installation_status, -name => $patch_name );

    my $patch_status = $self->get_Patch_Status( -name => $patch_name, -dbc => $dbc, -debug => $debug );
    Message "Patch applied and $patch_status";
    $Report->end_sub_Section('Get Patch List') if $Report;

    if ( $patch_status =~ /^Installed/i ) {
        my ($code) = $dbc->Table_find( 'Patch', 'Patch_Version', "WHERE Patch_Name = '$patch_name' " );
        if ($debug) { Message "Patch $patch_name $patch_status and has patch_version of $code" }
        $Report->set_Message("Patch $patch_name $patch_status and has patch_version of $code") if $Report;
        return $code;
    }
    return 0;
}

####################################
sub upgrade_DB {
####################################
    # Description:
    #   - This method is used to upgrade database to target version
    #   - It installs all previously uninstalled patches fro installed packages
    # Input:
    #   -version    (defaults to next version of dbase) 2.6,2.7,  2.8 ...
    #   -debug      Deatils for log
    #   -test       It disconnects from svn for commits and updates
    #   report      Process Monitor Object
    # Output:
    #   NO OUTPUT
    # Usage:
    # <snip>
    #   $install -> upgrade_DB (-test => $test ,-debug=>$debug , -report=>$Report );
    # </snip>
####################################
    my $self                     = shift;
    my %args                     = filter_input( \@_ );
    my $version                  = $args{-version} || $self->get_Next_Database_Version();
    my $debug                    = $args{-debug};
    my $force                    = $args{-force};
    my $match                    = $args{-match};
    my $test                     = $args{-test};
    my $dbc                      = $args{-dbc} || $self->{dbc};
    my $Report                   = $args{-report} || $self->{report};
    my $previous_install_success = 1;
    my $patch_version;
    my $patches;
    my @patches;

    if ($debug) { print Dumper \%args; Message "^ Arguments to upgrade_DB"; }

    $Report->start_Section("Upgrade");
    $Report->set_Message( "Starting upgrade action... (" . &date_time() . ")" );

    my $packages = $self->get_Active_Packages( -debug       => $debug );
    my $VT_files = $self->get_Version_Tracker_Files( -debug => $debug );    #Version Tracker Files
    my @versions = Cast_List( -list => $version, -to => 'array' );
    my $current_db_version = $self->get_Current_Database_Version();

    for my $ver (@versions) {
        if ($debug) { Message "================   Searching for pacthes for version $ver  ================" }
        my $the_greater = greater_version( $ver, $current_db_version );

        if ( $ver eq $the_greater ) {

            $Report->set_Message(" Version $ver, getting patch list ");

            if ($match) {
                $patches = $self->get_production_installed_patch_list( -version => $ver, -debug => $debug, -test => $test, -packages => $packages, -files => $VT_files );
            }
            else {
                $patches = $self->get_Patch_list( -version => $ver, -debug => $debug, -test => $test, -packages => $packages, -files => $VT_files );
            }

            my $sorted_patches_ref = $self->sort_Patches_array( -patches => $patches, -files => $VT_files, -debug => $debug );
            @patches = @$sorted_patches_ref if $sorted_patches_ref;

            for my $patch (@patches) {
                my $file = $patch . '.pat';
                my $patch_info = $self->get_patch_info( -file => $file, -debug => $debug );

                if ($patch_info) {
                    my %info = %$patch_info if $patch_info;
                    if ( !$info{PACKAGE} )  { Message "No Package found for patch $file" }
                    if ( !$info{CATEGORY} ) { Message "No Category found for patch $file" }
                    if ( !$info{VERSION} )  { Message "No Version found for patch $file" }
                    if ( $info{PACKAGE} && $info{CATEGORY} && $info{VERSION} ) {
                        Message "Installing $patch - $info{VERSION} -  $info{PACKAGE} [ $info{CATEGORY} ] ";
                        $Report->set_Message("Installing $patch - $info{VERSION} -  $info{PACKAGE} [ $info{CATEGORY} ] ");
                        if ( $patch =~ /^install/ ) {
                            $Report->set_Message("Skipping installation of $patch (installation_patch) for upgrading");
                            next;
                        }

                        $patch_version = $self->install_Patch(
                            -patch         => $patch,
                            -package       => $info{PACKAGE},
                            -category      => $info{CATEGORY},
                            -version       => $info{VERSION},
                            -debug         => $debug,
                            -test          => $test,
                            -report        => $Report,
                            -group_version => $patch_version
                        );
                        $previous_install_success = 0 unless $patch_version;
                        if ( !$force && !$previous_install_success ) {
                            Message "Quititng installation prematurely due to errors";
                            $Report->set_Message("Quititng installation prematurely due to errors");
                            return;
                        }
                        Message "Installed $file with patch_version $patch_version ";
                        $Report->set_Message("Installed $file with patch_version $patch_version ");
                    }
                    else {
                        Message "Failed to install patch: $file";
                        $Report->set_Message("Failed to install patch: $file");
                    }
                }
                else {
                    $Report->set_Message("Failed to find patch: $file");
                    Message "Failed to find patch: $file";
                }
            }

            my $current_version = $self->set_DB_Version( -version => $ver );
            $self->run_dbfield_set();
            $Report->set_Message("Database version is now : $current_version");
            Message "Database version is now : $current_version";
            $Report->end_Section("Upgrade");
        }
    }
    return;
}

####################################
sub add_Patch_to_Version_tracker {
####################################
    #   Description:
    #       This method updates teh Version_Tracker file from svn
    #       It adds a record to the version tracker file while getting the version of the patch
    #       It adds appropriate information to the Patch and PAckage table as required
    #   Input:
    #       - dbc
    #       - test
    #       - patch name
    #       - category
    #       - version
    #       - package name
    #       - parent_package:
    #               The name of the parent package (only required if the package doesnt already exist in database)
    #   Output:
    #       1 on success, 0 on failure
    # <snip>
    #   my $patch_added = $self -> add_Patch_to_Version_tracker (-pacth => $patch_name, -debug => $debug, -category => $category, -version => $version, -package => $package_name);
    # </snip>
####################################
    my $self           = shift;
    my %args           = filter_input( \@_, -mandatory => 'patch,version,package' );
    my $patch_name     = $args{-patch};
    my $debug          = $args{-debug};
    my $category       = $args{-category};
    my $version        = $args{-version};
    my $package        = $args{ -package };
    my $parent_package = $args{-parent_package};
    my $dbc            = $args{-dbc} || $self->{dbc};
    my $patch_type     = $args{-patch_type} || 'installation';
    my $group_version  = $args{-group_version};
    my $test           = $args{-test};

    my $version_tracker_file;

    my $dir = $FindBin::RealBin;
    if ( $dir =~ /^(.*)\/install\/(\w+)/ ) {
        $dir = "$1/bin";
    }

    if ( $category eq 'custom' ) {
        $version_tracker_file = "$root/install/patches/custom/$package/version_tracker.txt";
    }
    else {
        $version_tracker_file = "$self->{root}/install/patches/version_tracker.txt";
    }

    my $next_version;

    if ($debug) { Message "Adding patch to version tracker: $version_tracker_file " }

    ( my $last_version, my $found ) = $self->get_Latest_Version(
        -file          => $version_tracker_file,
        -version       => $version,
        -debug         => $debug,
        -patch         => $patch_name,
        -test          => $test,
        -group_version => $group_version
    );

    if ($found) {
        Message "found patch in version tracker file!   ... No need to add it";
        $next_version = $last_version;    ### Found pacth in version tracker no need to add it
    }
    else {
        $next_version = $self->get_Next_Version(
            -previous_version => $last_version,
            -category         => $category,
            -debug            => $debug,
            -package          => $package,
            -group_version    => $group_version
        );

        my $ok = $self->update_Version_Tracker(
            -file       => $version_tracker_file,
            -version    => $next_version,
            -patch_name => $patch_name,
            -package    => $package,
            -debug      => $debug,
            -test       => $test
        );
        unless ($ok) {return}
    }

    ### Making sure package Exists in database
    my ($package_id) = $dbc->Table_find( 'Package', 'Package_ID', "WHERE Package_Name = '$package'" );
    if ($package_id) {
        if ($debug) { Message "Found Pakcage with ID: $package_id " }
        ## make sure category matches
        my ($package_category) = $dbc->Table_find( 'Package', 'Package_Scope', " WHERE Package_ID = $package_id " );
        if ( $package_category ne $category && $package_category ) {
            Message " Category ($category) you have entered does not match the category ($package_category) for $package package ";
            return;
        }
    }
    else {
        my ($parent_id) = $dbc->Table_find( 'Package', 'Package_ID', " WHERE Package_Name = '$parent_package'" );
        unless ($parent_id) {
            Message " Parent package is required to continue. Please supply parent package name";
            return;
        }
        my $package_fields = [ 'Package_Name', 'Package_Scope', 'Package_active', 'Package_Install_Status', 'FKParent_Package__ID' ];
        my $package_values = [ $package, $category, 'y', 'Not installed', $parent_id ];
        $package_id = $dbc->Table_append_array( "Package", $package_fields, $package_values, -autoquote => 1 );
        if ($debug) {
            Message "Field: ";
            print Dumper $package_fields;
            Message "Values: ";
            print Dumper $package_values;
        }

    }

    ## add record to patch table
    my ($version_id) = $dbc->Table_find( 'Version', 'Version_ID', "WHERE Version_Name = '$version'" );
    my $date = &today();
    my $patch_fields = [ 'FK_Package__ID', 'Patch_Type', 'Patch_Name', 'Install_Status', 'Installation_Date', 'FKRelease_Version__ID', 'Patch_Version' ];
    my $patch_values = [ $package_id, $patch_type, $patch_name, 'Not installed', $date, $version_id, $next_version ];
    my $patch_id = $dbc->Table_append_array( "Patch", $patch_fields, $patch_values, -autoquote => 1, -no_triggers => 1 );
    if ($debug) {
        Message "new package id is $package_id";
        Message "new patch id is $patch_id";
        Message "Values: ";
        print Dumper $patch_values;
        Message "Field: ";
        print Dumper $patch_fields;
    }

    return 1;

}

####################################
sub get_Altered_Tables {
####################################
    my $self           = shift;
    my %args           = filter_input( \@_ );
    my $sections       = $args{-sections};
    my $dbc            = $args{-dbc} || $self->{dbc};
    my $debug          = $args{-debug};
    my @check_sections = ( 'DATA', 'SCHEMA' );
    my @tables;
    my %sections = %$sections if $sections;

    for my $sec (@check_sections) {
        my @lines = @{ $sections{$sec} } if $sections{$sec};

        for my $line (@lines) {
            $line =~ s/`//g;
            if ( $line =~ /ALTER\s+TABLE\s+(\w+)\s/i ) {
                push @tables, $1;
            }
            elsif ( $line =~ /CREATE\s+TABLE\s+(\w+)/i ) {
                push @tables, $1;
            }
        }
    }

    my @unique = @{ &unique_items( \@tables ) };
    return join ',', @unique;
}

####################################
sub run_Patch_file {
####################################
    #   Description:
    #       - This method runs a single patch
    #   Input:
    #       - dbc
    #       - name: patch name
    #       - path: over rides the standard path
    #       - force:
    #   Output:
    #       - status of installation
    # <snip>
    #   $self -> run_Patch_file ( -name => $patch_name, -dbc=>$dbc, -force => $force);
    # </snip>
####################################
    my $self            = shift;
    my %args            = filter_input( \@_, -mandatory => 'name' );
    my $patch_name      = $args{-name};
    my $path            = $args{-path};
    my $dbc             = $args{-dbc} || $self->{dbc};
    my $debug           = $args{-debug};
    my $nonlocal        = $args{-nonlocal};
    my $append          = $args{-append};
    my $new_tables_only = 1;
    my %patch_success;
    my $Report;

    # find and open file and dump it
    unless ($path) {
        $path = $self->find_patch_path( -patch_name => $patch_name );
    }
    ## download file and break into a hash of its sections
    my $file .= $path . $patch_name . '.pat';
    my %sections    = get_lines_between_tags( -filepath    => "$file" );               ## IN RGTools::RGIO
    my $tables      = $self->get_Altered_Tables( -sections => \%sections );
    my $import_file = $self->get_import_file( -file        => $sections{'IMPORT'} );

    #   $dbc -> start_trans('patch');
    Message $sections{DESCRIPTION} if $sections{DESCRIPTION};
    ## run each part
    $patch_success{schema} = $dbc->run_sql_array( -array => $sections{'SCHEMA'}, -debug => $debug, -report => $Report ) if $sections{'SCHEMA'};
    $patch_success{data}   = $dbc->run_sql_array( -array => $sections{'DATA'},   -debug => $debug, -report => $Report ) if $sections{'DATA'};
    ## put code into a temp file
    ## TODO: Find all the patches to be installed inside current patch's code block and
    ## append each of those patches' code block in the temp file with append as the condition to execute
    my $temp_code_file;
    if ($append) {
        $patch_success{code_block} = 1;
    }
    else {
        $temp_code_file = $self->create_temp_file( -section => $sections{'CODE_BLOCK'}, -debug => $debug );
        $patch_success{code_block} = $self->run_bin_file( -file => $temp_code_file, -debug => $debug ) if $sections{'CODE_BLOCK'};
    }

    #  db field set creates entries in appropriate forms for tables and fields to be fully functional
    if ($import_file) {
        $patch_success{import} = $self->run_import_files( -file => $import_file, -path => $path, -dbc => $dbc, -nonlocal => $nonlocal ) if $import_file;
    }
    else {
        $patch_success{import} = 'N/A';
    }

    if ($tables) {
        $patch_success{dbfield_set} = $self->run_dbfield_set( -tables => $tables );
    }
    else {
        $patch_success{dbfield_set} = 1;
    }

    $patch_success{final} = $dbc->run_sql_array( -array => $sections{'FINAL'}, -debug => $debug, -report => $Report ) if $sections{'FINAL'};

    #  Cleaning all the temp files created
    if ($append) {

        # No need to clean up temp files
        $patch_success{cleanup} = 1;
    }
    else {
        $patch_success{cleanup} = $self->cleanup_temp_files( -patches => 1, -force => 1 );
    }

    $patch_success{new_packages} = $self->run_install_package( -section => $sections{'NEW_PACKAGES'}, -debug => $debug );

    #  $dbc -> finish_trans('patch');

    ## Figure out output
    my $success
        = (    ( !$sections{'SCHEMA'} || $patch_success{schema} )
            && ( !$sections{'DATA'}       || $patch_success{data} )
            && ( !$sections{'CODE_BLOCK'} || $patch_success{code_block} )
            && ( !$sections{'IMPORT'}     || $patch_success{import} )
            && ( !$sections{'FINAL'}      || $patch_success{final} )
            && $patch_success{cleanup} );
    if ($success) { return 'Installed' }
    else {
        Message "$patch_name installed with errors: ";
        Message '%sections: ';
        print Dumper \%sections;
        Message '%patch_success: ';
        print Dumper \%patch_success;
    }
    return 'Installed with errors';
}

####################################
sub get_inner_code_blocks {
####################################
    ## TBD
}

####################################
sub get_patch_info {
####################################
    # Description:
    #   This Function will search thorugh the file system for a patch and returns information about it
    # Input:
    #   file : The patch file name (.pat)
    # Output:
    #   A hash reference of the directory info about the patch
    # <snip>
    # my $patch_info = $install -> get_patch_info (-file => $file);
    # </snip>
####################################
    my $self  = shift;
    my %args  = filter_input( \@_, -mandatory => 'file' );
    my $file  = $args{-file};
    my $debug = $args{-debug};

    my $dir = "$root/install/patches/";

    print "ROOT: $root\n";
    my $find_command = "find $dir -follow -name $file";
    if ($debug) {
        Message "---------------    Input to get_patch_info    ------------------";
        Message "File: $file";
        Message "Command: $find_command";
        Message "---------------------------------";
    }
    my $results = try_system_command($find_command);
    my @results = split "\n", $results;
    my @filtered_results;

    for my $line (@results) {
        if ( $line =~ /$file$/ ) {
            push @filtered_results, $line;
        }
    }

    if ( int @filtered_results > 1 ) {
        Message "Found more than one patch file with name $file";
        return;
    }
    elsif ( int @filtered_results == 1 ) {
        my $full_path = $filtered_results[0];
        $full_path =~ s/^$dir//;     ## removing path
        $full_path =~ s/$file$//;    ##removing file name
        my @options = split "/", $full_path;
        my %info;

        if ( ( $options[0] eq 'Core' ) && int @options == 2 ) {
            $info{PACKAGE}  = 'Core';
            $info{CATEGORY} = 'Core';
            $info{VERSION}  = $options[1];

        }
        elsif ( int @options == 3 ) {
            $info{CATEGORY} = $options[0];
            $info{PACKAGE}  = $options[1];
            $info{VERSION}  = $options[2];

        }
        else {
            Message "Incorrect directory structure $full_path";
            return;
        }
        unless ( $info{VERSION} =~ /\d+\.\d+/ ) {
            Message "Version ($info{VERSION}) doesn not match format";
            return;
        }

        if ( $file =~ /(.+)\.pat/ ) {
            $info{PATCH} = $1;
        }
        return \%info;
    }
    else {
        Message "Found no matches ($find_command)";
        return;
    }

    return;
}

####################################
sub install_All_Crontabs {
####################################
    #   Description:
    #       Will install all crontabs on different hosts
    #   Note:
    #       User Needs to be logged in as aldente for this to work
    #   Example:
    #   <snip>
    #          SDB::Installation::install_All_Crontabs ( -packages => 'Solexa');
    #   </snip>
####################################
    my %args      = filter_input( \@_ );
    my $packages  = $args{-packages};
    my $test      = $args{-test};
    my $confirmed = $args{-confirmed};     ## It skips the prompting line by line
    my $append    = $args{-append};        ## Slips file header

    my @host_types = ( 'master', 'slave', 'development' );
    my $conf = load_custom_config();
    for my $host_type (@host_types) {
        my $finalized_Crontab = get_Crontab( -packages => $packages, -host_type => $host_type, -confirmed => $confirmed, -append => $append );
        my $host = _get_Host( -config => $conf, -type => $host_type );
        install_finalized_Crontab( -cron => $finalized_Crontab, -type => $host_type, -host => $host, -test => $test );
    }
    return;
}

####################################
sub setup_DB_Replication {
####################################
    #   Description:
    #       Sets up Replication creating a slave on backup host for
    #   Note:
    #       Based on http://dev.mysql.com/doc/refman/5.0/en/replication-howto.html
    #       It is assumed that steps 1,2,3 are done which means that the my.conf file in /etc/
    #       are setup properly and user for replication is created
    #   Example:
    #   <snip>
    #          SDB::Installation::setup_DB_Replication (-user => $user, -password => $pwd, -database => 'Ash_Test' );
    #   </snip>
####################################
    my %args        = filter_input( \@_ );
    my $database    = $args{-database};
    my $password    = $args{-password};
    my $user        = $args{-user};
    my $test        = $args{-test};
    my $master_host = $args{-master} || $Configs{PRODUCTION_HOST};
    my $slave_host  = $args{-slave} || $Configs{BACKUP_HOST};

    my $master_connect = " mysql -u $user -p" . "$password -h $master_host ";
    my $slave_connect  = " mysql -u $user -p" . "$password -h $slave_host ";
    Message "Are you sure you wish to mirror database $database from host $master_host onto $slave_host? (y to continue)";
    my $choice = Prompt_Input( -type => 'char' );
    unless ( $choice =~ /y/i ) { return; }

    my ( $rep_user, $rep_pass ) = create_usr_for_Replication( -connect => $master_connect, -test => $test );    # step 1

    flush_tables_with_lock( -connect => $master_connect, -test => $test );                                      # step 4.1

    my ( $file, $position ) = get_Master_info( -connect => $master_connect, -test => $test );                   # step 4.2

    backup_Master_DB(
        -database => $database,
        -host     => $master_host,
        -test     => $test
    );                                                                                                          # step 5
    create_Slave_DB(
        -database    => $database,
        -master_host => $master_host,
        -test        => $test,
        -slave_host  => $slave_host
    );                                                                                                          #step 5
    set_master_conf_on_Slave(
        -connect         => $slave_connect,
        -test            => $test,
        -master_host     => $master_host,
        -master_user     => $rep_user,
        -master_password => $rep_pass,
        -master_log_file => $file,
        -master_log_pos  => $position
    );                                                                                                          # step 10
    start_Slave( -connect => $slave_connect, -test => $test );
    unlock_Tables( -connect => $master_connect, -test => $test );
    return 1;
}

########################################################################
######################          Helper Methods            ##############
########################################################################

####################################
sub set_master_conf_on_Slave {
####################################
    #   Description:
    #       sets up the master inforrmation on slave
####################################
    my %args            = filter_input( \@_ );
    my $connect         = $args{ -connect };
    my $master_host     = $args{-master_host};
    my $master_user     = $args{-master_user};
    my $master_password = $args{-master_password};
    my $master_log_file = $args{-master_log_file};
    my $master_log_pos  = $args{-master_log_pos};
    my $test            = $args{-test};

    my $mysql_command = qq( CHANGE MASTER TO
        MASTER_HOST="$master_host",
        MASTER_USER="$master_user",
        MASTER_PASSWORD="$master_password",
        MASTER_LOG_FILE="$master_log_file",
        MASTER_LOG_POS=$master_log_pos;);
    Message "Changing master host to $master_host.";
    my $command = qq($connect -e '$mysql_command');
    my $feedback = try_system_command($command) unless $test;
    Message $command if $test;
    return;
}

####################################
sub unlock_Tables {
####################################
    my %args          = filter_input( \@_ );
    my $connect       = $args{ -connect };
    my $test          = $args{-test};
    my $mysql_command = " UNLOCK TABLES; ";
    my $command       = qq($connect -e '$mysql_command');
    Message "Unlocking tables ...";
    my $feedback = try_system_command($command) unless $test;
    Message $command if $test;
    return;
}

####################################
sub start_Slave {
####################################
    #
####################################
    my %args     = filter_input( \@_ );
    my $database = $args{-database};
    my $connect  = $args{ -connect };
    my $test     = $args{-test};

    Message "Starting slave ...";
    my $mysql_command = " START SLAVE";
    my $command       = qq($connect -e '$mysql_command');
    my $feedback      = try_system_command($command) unless $test;
    Message $command if $test;
    return;
}

####################################
sub create_Slave_DB {
####################################
    #   Description:
    #
    #   Note:
    #
####################################
    my %args     = filter_input( \@_ );
    my $database = $args{-database};
    my $mtr_host = $args{-master_host};
    my $slv_host = $args{-slave_host};
    my $test     = $args{-test};
    my $home_dir = $Configs{Home_dir};
    my $data_dir = $Configs{Data_home_dir};
    my $database = $args{-database};

    ## drop and create

    ## Restoring structure
    Message "Restoring database $database structure on $slv_host from $mtr_host:$database ...";
    my $restore_structure_command
        = "$home_dir/versions/beta/bin/restore_DB.pl -user super_cron_user -host $slv_host -dbase $database -from $mtr_host:$database -force -time 23:00  -structure -rebuild "
        . "1> $data_dir/private/logs/slave_restore_structure.$slv_host:$database.log "
        . "2> $data_dir/private/logs/slave_restore_structure.$slv_host:$database.err ";
    Message $restore_structure_command if $test;
    my $feedback = try_system_command($restore_structure_command) unless $test;

    # Restoring Data
    Message "Restoring database $database data on $slv_host from $mtr_host:$database ...";
    my $restore_records_command
        = "$home_dir/versions/beta/bin/restore_DB.pl -user super_cron_user -host $slv_host -dbase $database -from $mtr_host:$database -force -time 23:00 -local local "
        . "1> $data_dir/private/logs/slave_restore_records.$slv_host:$database.log "
        . "2> $data_dir/private/logs/slave_restore_records.$slv_host:$database.err ";
    Message $restore_records_command if $test;
    my $feedback = try_system_command($restore_records_command) unless $test;

    return;
}

####################################
sub create_usr_for_Replication {
####################################
    #   Description:
    #       Creates a user to be used for replciation
    #   Input:
    #       Conenct:    a mysql connect line to master
    #       user:       user name to be used for replication (optional: defaults to 'replicant')
    #       pass:       password name to be used for replication (optional: defaults to 'aldente')
####################################
    my %args    = filter_input( \@_ );
    my $connect = $args{ -connect };
    my $user    = $args{-user} || "replicant";
    my $pass    = $args{-pass} || "aldente";
    my $test    = $args{-test};

    Message "Creating user [$user] for replication on master";
    my $mysql_command = qq(GRANT REPLICATION SLAVE ON *.* TO "$user"@"%" IDENTIFIED BY "aldente";);
    my $command       = qq($connect -e '$mysql_command');
    my $feedback      = try_system_command($command) unless $test;
    Message $command if $test;

    my $mysql_command2 = qq(GRANT FILE SLAVE ON *.* TO "$user"@"%" IDENTIFIED BY "aldente";);
    my $command2       = qq($connect -e '$mysql_command2');
    my $feedback       = try_system_command($command2) unless $test;
    Message $command2 if $test;

    my $final_Command = qq($connect -e 'FLUSH PRIVILAGES;');
    my $feedback = try_system_command($final_Command) unless $test;
    Message $final_Command if $test;

    return ( $user, $pass );
}

####################################
sub backup_Master_DB {
####################################
    #   Description:
    #       Backsup Master database
####################################
    my %args     = filter_input( \@_ );
    my $database = $args{-database};
    my $host     = $args{-host};
    my $test     = $args{-test};
    my $home_dir = $Configs{Home_dir};
    my $data_dir = $Configs{Data_home_dir};
    Message " Backing up master database ($host:$database)";
    my $command = "$home_dir/versions/beta/bin/backup_RDB.pl -dump -host $host -dbase $database -user super_cron -confirm -time 23:00 " .    #
        " 1> $data_dir/private/logs/master_backup.$host:$database.log " . " 2> $data_dir/private/logs/master_backup.$host:$database.err ";
    Message $command if $test;
    my $feedback = try_system_command($command) unless $test;
    return;
}

####################################
sub flush_tables_with_lock {
####################################
    #   Description:
    #       Locking tables
####################################
    my %args    = filter_input( \@_ );
    my $connect = $args{ -connect };
    my $test    = $args{-test};
    Message "Locking master tables ...";
    my $command = " $connect -e 'FLUSH TABLES WITH READ LOCK;'";
    my $feedback = try_system_command($command) unless $test;
    Message $command if $test;
    return;
}

####################################
sub get_Master_info {
####################################
    #   Description:
    #        Obtaining the Master Replication Information
    #   Output:
    #       master log file and its offset position
####################################
    my %args      = filter_input( \@_ );
    my $connect   = $args{ -connect };
    my $command   = " $connect -e 'show master status;'";
    my $feedback  = try_system_command($command);
    my @feedbacks = split "\n", $feedback;
    my ( $file, $position ) = split "\t", $feedbacks[1];
    return ( $file, $position );
}

####################################
sub display_Replication_help {
####################################
    print <<END;
         There are some steps you need to take before you can setup the replication process. These steps are necesary.
         
         On Master:
        - Setting the Replication Master Configuration 
            You will need to add the following options to the configuration file within the [mysqld] section. 
            If these options already exist, but are commented out, uncomment the options and alter them according to your needs. 
            For example, to enable binary logging, using a log file name prefix of mysql-bin, and setting a server ID of 1:
            /etc/my.cnf
                [mysqld]
                log-bin=mysql-bin
                server-id=31
                replicate-do-db = Test_database
            
            Restart mysql
            /etc/init.d/mysqld restart
            
            
        On slave:
        - Setting the Replication Slave Configuration
            Shut down your slave server, and edit the configuration to specify the server ID.
            If you are setting up multiple slaves, each one must have a unique server-id value that differs from that of the master and from each of the other slaves. 
            Think of server-id values as something similar to IP addresses: These IDs uniquely identify each server instance in the community of replication partners.
            /etc/my.cnf
                [mysqld]
                server-id=33
                replicate-do-db = Test_database
            
            Restart mysql
            /etc/init.d/mysqld restart


END
    return;
}

####################################  SHOULD BE MOVED DOWN
sub _execute_command {
####################################
    my %args    = filter_input( \@_, -mandatory => 'command' );
    my $command = $args{-command};
    my $debug   = $args{-debug};                                  # debug flag
    my $ok      = try_system_command($command);
    Message $command if $debug;
    Message $ok      if $debug;

    return;
}

####################################
sub get_Crontab {
####################################
    #   Description:
    #       This function will create an initial crontab
    #   Input:
    #       packages:   a list of packages to add customized cron jobs
    #       host_type:  the type of crontab (slave, master , development, data)
    #   Output:
    #       array reference of the lines of crontab on success , NULL on failure
    #   Example:
    # <snip>
    #      get_Crontab (-packages => $packages);
    # </snip>
####################################
    my %args      = filter_input( \@_ );
    my $packages  = $args{-packages};
    my $host_type = $args{-host_type};
    my $confirmed = $args{-confirmed};
    my $append    = $args{-append};
    my $no_slave;

    unless ($host_type) {
        Message 'Warning: host type not specified';
        return;
    }
    Message "*************************************";
    Message "**** Creating $host_type crontab ****";
    my $crontab = get_generic_Crontab( -type => $host_type, -packages => $packages );
    my $conf    = load_custom_config();
    my %conf    = %$conf if $conf;

    unless ( $conf{BACKUP_HOST}{value} ) { $no_slave = 1 }
    my $customized_crontab = customize_Crontab( -cron => $crontab, -config => $conf, -no_slave => $no_slave );
    my $finalized_Crontab = prompt_Crontab_Options( -cron => $customized_crontab, -confirmed => $confirmed, -append => $append, -no_slave => $no_slave );
    return $finalized_Crontab;
}

####################################
sub get_generic_Crontab {
####################################
    #   Description:
    #       This fucntion gets the generic crontab for Core or a Package
    #   Input:
    #       packages:   a list of packages to add customized cron jobs [defaults to Core]
    #       type:       The type of crontab (slave, master , development, data)
    #   Output:
    #       Array refrence of lines of the generic addon crontab
    #   Example:
    # <snip>
    #      my $addon_crontab   = get_generic_Crontab( -packages => $packages, -type => $host_type)
    # </snip>
####################################
    my %args      = filter_input( \@_ );
    my $host_type = $args{-type};
    my $packages  = $args{-packages} || 'Core';
    my @packages  = split ',', $packages;
    my @cron;
    my $path = "$root/install/crontab/";

    for my $package (@packages) {
        my $dir  = $path . "$package/";
        my $file = $dir . "cron_" . $host_type . '_' . $package . ".txt";
        open( IMPORT, "< $file " ) or Message "Could not open or find crontab file (for read) for package $package :  $file ";
        my @lines = <IMPORT>;
        close IMPORT;
        push @cron, @lines;
    }
    return \@cron;
}

####################################
sub customize_Crontab {
####################################
    #   Description:
    #       This function replaces all generic labels with
    #   Input:
    #       -Config:
    #       -Cron:
    #   Output:
    #       Array reference to liesn of the text of the new cron
    #   Example:
    # <snip>
    #      my $customized_crontab     = customize_Crontab(    -cron  => \@crontab,   -config => $conf)
    # </snip>
####################################
    my %args      = filter_input( \@_ );
    my $cron      = $args{-cron};
    my $config    = $args{-config};
    my $no_slave  = $args{-no_slave};
    my %conf      = %$config if $config;
    my @init_cron = @$cron if $cron;
    my @cron;

    my @customized_cron;
    if ($no_slave) {
        for my $line (@init_cron) {
            $line =~ s/\-slave\s+<BACKUP_HOST> //g;
            push @cron, $line;
        }
    }
    else {
        @cron = @init_cron;
    }

    for my $line (@cron) {
        for my $key_name ( keys %conf ) {
            my $value = $conf{$key_name}{value};
            if ( $value && !( $key_name eq "BACKUP_HOST" && $no_slave ) ) {
                $line =~ s/<$key_name>/$value/g;
            }
        }
        push @customized_cron, $line;
    }
    return \@customized_cron;
}

####################################
sub prompt_Crontab_Options {
####################################
    #   Description:
    #       This function goes through crontab and prompts user which parts to use as part of insallation
    #   Input:
    #       cron:   cron text as is up to this point [array ref]
    #   Output:
    #       cron    updated [array ref]
    #   Example:
    # <snip>
    #      my $finalized_Crontab   = prompt_Crontab_Options( -cron  => $customized_crontab)
    # </snip>
####################################
    my %args      = filter_input( \@_ );
    my $cron      = $args{-cron};
    my $confirmed = $args{-confirmed};
    my $append    = $args{-append};
    my $no_slave  = $args{-no_slave};

    my @cron = @$cron if $cron;

    my @finalized_cron;
    my $header;
    my $body;
    my $header_flag      = 0;
    my $file_header_flag = 0;
    my $section_name;
    my @current_section;

    for my $line (@cron) {
        if ( $line =~ /<HEADER>/ )        { $header_flag      = 1; next; }
        if ( $line =~ /<\/HEADER>/ )      { $header_flag      = 0; next; }
        if ( $line =~ /<FILE_HEADER>/ )   { $file_header_flag = 1; next; }
        if ( $line =~ /<\/FILE_HEADER>/ ) { $file_header_flag = 0; next; }

        if ($file_header_flag) {
            unless ($append) { push @finalized_cron, $line }
        }
        elsif ($header_flag) {
            push @finalized_cron, $line;
        }
        else {
            if ( $line =~ /<SECTION=(.+)>/ ) {
                @current_section = ();
                $section_name    = $1;
                push @current_section, "######" . $section_name . "\n";
            }
            elsif ( $line =~ /<\/SECTION>/ ) {
                my $undecided = 1;
                unless ($section_name) { $undecided = 0 }
                if ( $section_name =~ /<BACKUP_HOST>/ ) { $undecided = 0 }
                while ($undecided) {
                    Message '---------------------------------------------------------------------------------------------'                                        unless $confirmed;
                    Message "Do you wish to install $section_name ('y' to install ,'p' to print section , 'n' to skip section, 'l' to go through line by line) ? " unless $confirmed;
                    my $choice = Prompt_Input( -type => 'char' ) unless $confirmed;
                    $choice = 'y' if $confirmed;
                    if ( $choice =~ /y/i ) {
                        push @finalized_cron, @current_section;
                        $undecided = 0;
                    }
                    elsif ( $choice =~ /n/i ) {
                        $undecided = 0;
                    }
                    elsif ( $choice =~ /p/i ) {
                        for my $temp (@current_section) { print $temp }
                    }
                    elsif ( $choice =~ /l/i ) {
                        for my $cr_line (@current_section) {
                            if ( $cr_line eq $current_section[0] ) {
                                ## SKIP first line
                                push @finalized_cron, $cr_line;
                            }
                            elsif ( $cr_line =~ /^\n/ ) {
                                push @finalized_cron, $cr_line;
                            }
                            else {
                                Message "Do you wish to install the following cronjob? ('y' to install, anything else to skip) ?";
                                print $cr_line;
                                my $choice = Prompt_Input( -type => 'char' );
                                if ( $choice =~ /y/i ) {
                                    push @finalized_cron, $cr_line;
                                }
                            }
                        }
                        $undecided = 0;
                    }
                }
                @current_section = ();
                $section_name    = '';
            }
            else {
                push @current_section, $line;
            }
        }
    }

    return \@finalized_cron;
}

####################################
sub _get_Host {
####################################
    #   Description:
    #       Returns host based on conf file and host type
####################################
    my %args      = filter_input( \@_ );
    my $config    = $args{-config};
    my $host_type = $args{-type};
    my %conf      = %$config if $config;
    if ( $host_type eq 'slave' ) {
        return $conf{BACKUP_HOST}{value};
    }
    elsif ( $host_type eq 'master' ) {
        return $conf{PRODUCTION_HOST}{value};
    }
    elsif ( $host_type eq 'development' ) {
        return $conf{DEV_HOST}{value};
    }
    else {
        Message "Invalid host type: $host_type";
        return;
    }
}

####################################
sub install_finalized_Crontab {
####################################
    #   Description:
    #       Installs the crontab
    #   Input:
    #       - array refrence of the lines of crontab
    #   Output:
    #
    #   Example:
    # <snip>
    #     install_finalized_Crontab( -cron => $finalized_Crontab);
    # </snip>
####################################
    my %args      = filter_input( \@_ );
    my $cron      = $args{-cron};
    my $host_type = $args{-type};
    my $host      = $args{-host};
    my $test      = $args{-test};

    my @cron = @$cron if $cron;
    my $path = "$root/install/crontab/temp/";
    my $file = $path . $host_type . "_tempcronfile.txt";
    my $text;
    my @cron = @$cron if $cron;

    open( EXPORT, ">>$file " ) or die "Could not open temp file for write: $file ";
    for my $line (@cron) {
        print EXPORT "$line";
    }
    close EXPORT;

    Message "Host is set to $host do you wish to change this? (y to change anything else to continue)";
    my $host_choice = Prompt_Input( -type => 'char' );
    if ( $host_choice =~ /y/i ) {
        Message "Enter host ";
        $host = Prompt_Input();
    }

    my $command = "ssh $host 'crontab $file'";
    if ($test) {
        Message 'File created ... not changing crontab because this is a test';
        return;
    }

    Message "Are you certain you wish to install this cronjob on $host ? ('y' to install, anything else to exit) ?";
    my $choice = Prompt_Input( -type => 'char' );
    unless ( $choice =~ /y/i ) {
        Message 'Aborting ...';
        return;
    }

    my $feedback = try_system_command($command) unless $test;
    Message $feedback;
    return;
}

####################################
sub header_included {
####################################
    #   Description:
    #       -This fucntion checks to see if the dump file has header or not
    #   Input:
    #       -file:      fully qualified file
    #       -table:     table name
    #       -dbc
    #   Output:
    #       -bolean 1 if there is header and 0 if no header
    # <snip>
    #       my $result = $install ->  header_included (-dbc=>$dbc, -file =>$file,-table =>$table);
    # </snip>
####################################
    my $self         = shift;
    my %args         = filter_input( \@_ );
    my $file         = $args{-file};
    my $table        = $args{-table};
    my $dbc          = $args{-dbc};
    my @table_fields = $self->get_fields( -table => $table, -dbc => $dbc, -include_obsolete => 1 );
    my $test_field   = $table_fields[0];
    my $command      = "head $file";
    my @lines        = split "\n", try_system_command($command);

    if ( $lines[0] =~ /$test_field/ ) {
        return 1;
    }
    else {
        return 0;
    }

}

####################################
sub display_available_Package_List {
####################################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $category  = $args{-category};
    my $dbc       = $args{-dbc};
    my $condition = " WHERE Package_Install_Status <> 'Installed' ";
    $condition .= " AND Package_Scope = '$category'" if $category;
    my @package_info = $dbc->Table_find( 'Package', 'Package_Name,Package_Scope', $condition );
    my $count = 0;
    my @packages;
    Message "==============================================";
    Message "Number \tCategory\tName";
    Message "----------------------------------------------";

    for my $info (@package_info) {
        $count++;
        my ( $name, $scope ) = split ',', $info;
        Message "$count \t$scope\t\t$name";
        push @packages, $name;
    }
    Message "==============================================";
    return @packages;
}

####################################
sub get_import_file {
####################################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $files = $args{-file};
    my @qualified_files;
    my @files = @$files if $files;
    for my $temp (@files) {
        if ( $temp =~ /.+\.txt/ ) {
            my $qualified = $temp;
            push @qualified_files, $qualified;
        }
        else {
            Message "$temp does not match text file format";
        }
    }

    return \@qualified_files;
}

####################################
sub run_import_files {
####################################
    #   Description:
    #       - This fucntion takes in a name of an import file and adds its values to databse
    #   Input:
    #       -file: (unqulified file name)
    #           1. The file name must be the same as tbale name with .txt extension
    #           2. File can include header(first line) in which case the fields and values will be matched accrodingly
    #           3. File without header (same as a data dump of a table) will be added to database (the field order MUST be same as table description)
    #       - path: path of the file
####################################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $files    = $args{-file};
    my $path     = $args{-path};
    my $dbc      = $args{-dbc};
    my $nonlocal = $args{-nonlocal} || "LOCAL";
    my $debug    = $args{-debug} || 1;
    my @files    = @$files if $files;

    for my $file (@files) {
        my $q_file = $path . $file;
        if ($debug) {
            Message "=================== Loading from File: $file   ============================";
        }
        open( IMPORT, "< $q_file " ) or die "Could not open file for read:  $q_file ";
        my @lines = <IMPORT>;
        close IMPORT;

        my $table = $file;
        $table =~ s/\.txt//;
        my @fields;

        my @table_fields = $self->get_fields( -table => $table, -dbc => $dbc );
        my $test_field = $table_fields[0];
        if ( $lines[0] =~ /$test_field/ ) {
            ## Format of file includes the columns
            if ($debug) { Message "File includes headers " }
            @fields = split "\t", $lines[0];
            shift @lines;
            for my $data (@lines) {
                chomp $data;
                my @values = split "\t", $data;

                my $ok = $dbc->Table_append_array( $table, \@fields, \@values, -autoquote => 1, -no_triggers => 1 );
                if ($debug) {
                    Message "Fields ($table): ";
                    print Dumper @fields;
                    Message "Values : ";
                    print Dumper @values;
                    Message "===================================";
                }
                unless ($ok) {
                    Message "Problem adding to table $table";
                }
            }

        }
        else {
            ## Format of file does not includes the columsn
            if ($debug) { Message "File does not include headers " }
            $self->empty_table( -table => $table, -dbc => $dbc, -debug => $debug );
            #############
            my $user        = $dbc->{login_name};
            my $target_host = $dbc->{host};
            my $dbase       = $dbc->{dbase};
            my $pass        = $dbc->{login_pass};

            my $mysql_command = "mysql -h $target_host -u $user -p" . "$pass $dbase";
            my $command       = qq{-e "LOAD DATA $nonlocal INFILE '$q_file' INTO TABLE $table "};
            if ($debug) {
                Message "COMMAND: " . qq{$mysql_command $command};
            }
            my $feedback = try_system_command(qq{$mysql_command $command});
            if ($debug) {
                Message $feedback;
            }
            ##########

        }

    }
    return;
}

####################################
sub empty_table {
####################################
    # Description:
    #   It deletes all contents of a table
####################################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $table   = $args{-table};
    my $debug   = $args{-debug};
    my $dbc     = $args{-dbc};
    my $id_name = $table . '_ID';

    if ($debug) {
        Message "deleting records ";
    }

    #$dbc -> delete_records(-table=>$table,-dfield=>$id_name,-id_list=>$id_list, -quiet=>0);
    my $user        = $dbc->{login_name};
    my $target_host = $dbc->{host};
    my $dbase       = $dbc->{dbase};
    my $pass        = $dbc->{login_pass};

    my $mysql_command = "mysql -h $target_host -u $user -p" . "$pass $dbase";
    my $command       = qq{-e " delete from $table "};
    if ($debug) {
        Message "COMMAND: " . qq{$mysql_command $command};
    }
    my $feedback = try_system_command(qq{$mysql_command $command});
    if ($debug) {
        Message "resopnse: " . $feedback if $feedback;
    }

    return;

}

####################################
sub get_fields {
####################################
    #   Description:
    #       - Inputs table name and return UNQUALIFIED list of fields
    #   Output:
    #       - array of fields
####################################
    my $self             = shift;
    my %args             = filter_input( \@_ );
    my $table            = $args{-table};
    my $dbc              = $args{-dbc};
    my $include_obsolete = $args{-include_obsolete};

    my @final;
    my @field = $dbc->get_fields( -table => $table, -include_obsolete => $include_obsolete );
    for my $field (@field) {
        if ( $field =~ /\w+\.(\w+)/ ) {
            push @final, $1;
        }
    }
    return @final;

}

####################################
sub is_Installation_up_to_date {
####################################
    #   Description:
    #       This Method checks to see if all previous patches have been installed
    #       AND IF All the parent Packages have been installed
    #   Input:
    #       - dbc
    #       - patch: patch name
    #   Output:
    #       Returns 1 on success and 0 on failurre
    # <snip>
    #    $self -> is_Installation_up_to_date (-patch => $patch_name ,-package => $package_name,  -version => $version , -dbc=>$dbc);
    # </snip>
####################################
    my $self       = shift;
    my %args       = filter_input( \@_, -mandatory => 'patch||package,version' );
    my $patch_name = $args{-patch};
    my $version    = $args{-version};
    my $dbc        = $args{-dbc} || $self->{dbc};
    my $debug      = $args{-debug};
    my $package    = $args{ -package };

    my $installed_enums = "'Installed', 'Installed with errors','Installing'";
    unless ($package) {
        ($package) = $dbc->Table_find( 'Patch,Package', 'Package_Name', " WHERE FK_Package__ID = Package_ID and Patch_Name = '$patch_name'" );
    }

    my $parent_packages_ids = get_Parent_Packages( -dbc => $dbc, -package => $package, -debug => $debug );

    my $parent_list = join ',', @$parent_packages_ids if $parent_packages_ids;

    my ($uninstalled_parents) = $dbc->Table_find( 'Package', 'Package_ID', "WHERE Package_ID IN ($parent_list) AND Package_Install_status <> 'Installed' and Package_Name <> '$package' " ) if $parent_list;
    if ($uninstalled_parents) {
        Message "Parent Packages not installed: $uninstalled_parents";
        return;
    }

    my $previous_versions = get_current_and_previous_Version_ids( -version => $version, -dbc => $dbc );
    if ($debug) {
        Message "Parent Package IDS :$parent_list ";
        Message "Previous Version IDS : $previous_versions ";
    }
    unless ($parent_list) {
        Message "package: $package";
        Message " YOU HAVE ENCOUNTERED AN ERROR ";
        return;
    }

    my @unistalled_patch_list = $dbc->Table_find( 'Patch', 'Patch_Name', " WHERE FK_Package__ID IN ($parent_list) AND InStall_Status NOT IN ($installed_enums) and FKRelease_Version__ID IN ($previous_versions) AND Patch_Name <> '$patch_name'" );

    if ( int @unistalled_patch_list ) {
        my $list = join ',', @unistalled_patch_list;
        Message "These patches need to be installed before you can run your patch as your patch follows them: ($list)";
        return;
    }
    return 1;
}

####################################
sub update_Package_fks {
####################################
    my $self    = shift;
    my %args    = filter_input( \@_, -mandatory => 'package' );
    my $package = $args{ -package };
    my $debug   = $args{-debug};
    my $dbc     = $args{-dbc} || $self->{dbc};
    my ($package_ID) = $dbc->Table_find( 'Package', 'Package_ID', " WHERE Package_Name = '$package' " );
    my $num_records = $dbc->Table_update_array(
        -table       => 'DBTable',
        -fields      => ['FK_Package__ID'],
        -values      => [$package_ID],
        -condition   => "WHERE FK_Package__ID is NULL or FK_Package__ID = 0 ",
        -autoquote   => 1,
        -no_triggers => 1
    );

    my $num_records2 = $dbc->Table_update_array(
        -table       => 'DBField',
        -fields      => ['FK_Package__ID'],
        -values      => [$package_ID],
        -condition   => "WHERE FK_Package__ID is NULL or FK_Package__ID = 0 ",
        -autoquote   => 1,
        -no_triggers => 1
    );

    return;

}

####################################
sub log_Patch_installation {
####################################
    # Description:
    #   - This method chages the installation status in patch table and messages the result as well
    # Input:
    #   - name : patch name
    #   - status: enum (installed, installed with errors, Installation aborted)
    # Exapmle:
    # <snip>
    #       $self -> log_Patch_installation (-status => $installation_status,  -name => $patch_name);
    # </snip>
####################################
    my $self       = shift;
    my %args       = filter_input( \@_, -mandatory => 'name,status' );
    my $status     = $args{-status};
    my $patch_name = $args{-name};
    my $debug      = $args{-debug};
    my $dbc        = $args{-dbc} || $self->{dbc};

    if ( $status eq 'Installed' ) {
        $self->set_Patch_Status( -name => $patch_name, -status => 'Installed', -debug => $debug );
        Message '';
    }
    elsif ( $status eq 'Installed with errors' ) {
        $self->set_Patch_Status( -name => $patch_name, -status => 'Installed with errors', -debug => $debug );
        Message '';
    }
    elsif ( $status eq 'Installation aborted' ) {
        $self->set_Patch_Status( -name => $patch_name, -status => 'Installation aborted', -debug => $debug );
        Message '';
    }
    else {
        Message 'Running out of options here';
    }

    return;
}

####################################
sub find_patch_path {
####################################
    #   Description:
    #       - This method takes in a patch name and returns where it shold be located
####################################
    my $self       = shift;
    my %args       = filter_input( \@_, -mandatory => 'patch_name' );
    my $patch_name = $args{-patch_name};
    my $dbc        = $args{-dbc} || $self->{dbc};
    my ($info) = $dbc->Table_find( 'Patch,Package,Version', 'Package_Scope,Package_Name,Version_Name', " WHERE FKRelease_Version__ID = Version_ID and FK_Package__ID = Package_ID and Patch_Name = '$patch_name' " );
    ( my $scope, my $package, my $version ) = split ',', $info;

    my $dir = $FindBin::RealBin;
    if ( $dir =~ /^(.*)\/install\/(\w+)/ ) {
        $dir = "$1/bin";
    }

    my $path = "$root/install/patches/$scope/$package/$version/";

    if ( $scope eq 'Core' ) {
        $path = "$root/install/patches/$scope/$version/";
    }
    return $path;

}

####################################
sub get_Patches_from_Version_Tracker {
####################################
    #   Description:
    #       - This Method
    #       - It updates tracker file
    #       - Opens tracker file
    #       - Selects the patches according to the version and packages list
    #   Input:
    #       - file:     the full path and name of the file getting the info from
    #       - test:     flag if set no svn updating the file
    #       - version:  version of dbase so the patches matching this version will be selected
    #       - packages: list of packages which are installed on dbase to be selected from [array reference]
    #   output:
    #       - reference to a hash of patch names (keys) and as values their patch_version
    #   Usage:
    # <snip>
    #       my $patches = $self -> get_Patches_from_Version_Tracker (-debug=> $debug, -file => $file, -packages =>  $packages, -version=> $version  ,-test=> $test);
    # </snip>
####################################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $debug    = $args{-debug};
    my $file     = $args{-file};
    my $packages = $args{-packages};
    my $version  = $args{-version};
    my $test     = $args{-test};
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $Report   = $args{-report} || $self->{report};
    my $core_version;
    my @packages = @$packages if $packages;
    my %final_patches;

    my $ok = SDB::SVN::update( -file => $file, -debug => $debug );
    print $ok . "\n" if $debug;
    unless ($test) {
        $Report->set_Message("Updating and Opening $file") if $debug;
    }
    open( VERSION_CONTROL, "<$file " ) or die "Could not open version control file for read: $file ";
    my @lines = <VERSION_CONTROL>;
    close VERSION_CONTROL;

    if ( $version =~ /(^\d+\.\d+)\..+$/ ) {
        $core_version = $1;
    }
    else {
        $core_version = $version;
    }

    for my $line (@lines) {
        my @info = split "\t", $line;
        my $pack = $info[2];
        chomp $pack;
        my $patch     = $info[1];
        my $p_version = $info[0];
        if ( int @info == 3 && $p_version =~ /^$core_version/ ) {
            my ($result) = grep( /\b$pack\b/, @packages );
            if ($result) {
                if ( $core_version eq $version ) {
                    $final_patches{$patch} = $p_version;
                }
                else {
                    if ( greater_version( $version, $p_version ) eq $version ) {
                        $final_patches{$patch} = $p_version;
                    }
                }
            }
        }
    }

    return \%final_patches;

}

####################################
sub get_Unistalled_patches {
####################################
    #   Description:
    #       - takes in a list of patches and returns the sorted list of unistalled ones
    #       - Uses elimination so it goes through patches and eliminates the ones installed
    #       - Orders them by patch_version
    #   Input:
    #       -patches:   a has reference of patches and their patch_versions
    #   Output:
    #       - array reference of lis of sorted patches
####################################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $debug   = $args{-debug};
    my $patches = $args{-patches};
    my $dbc     = $args{-dbc} || $self->{dbc};
    my $Report  = $args{-report} || $self->{report};
    my %patches = %$patches if $patches;
    my %unistalled_pacthes;

    for my $patch_name ( keys %patches ) {
        ( my $patch_id ) = $dbc->Table_find( 'Patch', 'Patch_ID', " WHERE Patch_Name = '$patch_name' and Install_Status LIKE 'Installed%'" );
        unless ($patch_id) {
            $unistalled_pacthes{$patch_name} = $patches{$patch_name};
        }
    }
    my @sorted_patches = sort { $unistalled_pacthes{$a} cmp $unistalled_pacthes{$b} } keys %unistalled_pacthes;
    if ($debug) {
        Message "List of UNINSTALLED patches";
        print Dumper \@sorted_patches;
    }

    return \@sorted_patches;
}

####################################
sub get_production_installed_patch_list {
####################################
    # Description:
    #   - This method returns the patches that are installed on production database (from config file)
    #       and are not installed on current database
    # Input:
    #   - version:  the version of patches to retrieve, single version only [eg 2.5,2.6,2.7]
    #   - test:     avoids svn update to update the tracker files
    #   - packages  list of active packages
    # Output:
    #   - a sorted (by patch_version) list of uninstalled pacthes [array reference]
    # Usage:
    #
####################################
    my $self                  = shift;
    my %args                  = filter_input( \@_ );
    my $version               = $args{-version};
    my $dbc                   = $args{-dbc} || $self->{dbc};
    my $debug                 = $args{-debug};
    my $test                  = $args{-test};
    my $Report                = $args{-report} || $self->{report};
    my $packages              = $args{-packages} || $self->get_Active_Packages( -debug => $debug, -report => $Report );
    my $version_tracker_files = $args{-files} || $self->get_Version_Tracker_Files( -debug => $debug, -report => $Report );
    my $sec_dbase             = $Configs{PRODUCTION_DATABASE};
    my $sec_host              = $Configs{PRODUCTION_HOST};
    my $sec_user              = 'viewer';
    my $sec_pass              = 'viewer';
    my @uninstalled_patches;

    my $dbc2 = new SDB::DBIO(
        -host     => $sec_host,
        -dbase    => $sec_dbase,
        -user     => $sec_user,
        -password => $sec_pass,
        -connect  => 1
    );
    my @packages = @$packages if $packages;
    my $package_list = join "','", @packages;

    my ($prod_version) = $dbc2->Table_find( 'Version', 'Version_ID', " WHERE Version_Status = 'In use' " );
    my @prod_patches = $dbc2->Table_find( 'Patch,Package', 'Patch_Name', " WHERE Install_Status = 'Installed' and FKRelease_Version__ID = $prod_version and FK_Package__ID = Package_ID and Package_Name IN ('$package_list')" );

    for my $patch (@prod_patches) {
        my $found = $dbc->Table_find( 'Patch', 'Patch_Name', " WHERE Install_Status = 'Installed' and Patch_Name = '$patch'" );
        unless ($found) { push @uninstalled_patches, $patch }
    }

    $Report->set_Message( "All unistalled patches found in version tracker files:" . Dumper \@uninstalled_patches );
    $Report->end_sub_Section('get_production_installed_patch_list');
    return \@uninstalled_patches;
}

####################################
sub get_Patch_list {
####################################
    # Description:
    #   - This method returns the list of uninstalled packages
    #   - Checks version_tracker file and compares with database
    # Input:
    #   - version:  the version of patches to retrieve, single version only [eg 2.5,2.6,2.7]
    #   - test:     avoids svn update to update the tracker files
    #   - packages  list of active packages
    # Output:
    #   - a sorted (by patch_version) list of uninstalled pacthes [array reference]
    # Usage:
    #
####################################
    my $self                  = shift;
    my %args                  = filter_input( \@_ );
    my $version               = $args{-version};
    my $dbc                   = $args{-dbc} || $self->{dbc};
    my $debug                 = $args{-debug};
    my $test                  = $args{-test};
    my $Report                = $args{-report} || $self->{report};
    my $packages              = $args{-packages} || $self->get_Active_Packages( -debug => $debug, -report => $Report );
    my $version_tracker_files = $args{-files} || $self->get_Version_Tracker_Files( -debug => $debug, -report => $Report );
    my %all_patches;
    $Report->start_sub_Section('Get Patch List');

    for my $file (@$version_tracker_files) {
        my $patches = $self->get_Patches_from_Version_Tracker(
            -debug    => $debug,
            -file     => $file,
            -packages => $packages,
            -version  => $version,
            -test     => $test
        );

        my $all_patches_ref = RGmath::merge_Hash( $patches, \%all_patches );
        %all_patches = %$all_patches_ref if $all_patches_ref;
    }

    my $uninstalled_patches = $self->get_Unistalled_patches( -debug => $debug, -patches => \%all_patches );
    $Report->set_Message( "All unistalled patches found in version tracker files:" . Dumper $uninstalled_patches);
    $Report->end_sub_Section('Get Patch List');
    return $uninstalled_patches;
}

####################################
sub get_Untracked_Patch_List {
####################################
    #   Description:
    #       - This Method returns all the AVAILABLE patch names for a certain package
    #       - It checks the directory structure to find them not the patch table or version tracker file
    #   Input:
    #       - Package: Name of the packgae [Mandatory]
    #       - Version: limits to the patches to version and previous ones only
    #   Output:
    #       - list of all pacthes in the package directory (array reference)
    #   Usage:
    #   <snip>
    #       my $patches = $install -> get_Untracked_Patch_List ( -package => $package );
    #   </snip>
####################################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $package = $args{ -package };
    my $version = $args{-version};
    my $debug   = $args{-debug};
    my $dbc     = $args{-dbc} || $self->{dbc};
    my ($category) = $dbc->Table_find( 'Package', 'Package_Scope', "WHERE Package_Name = '$package'" );

    my $dir = "$root/$category/$package/install/patches/";
    $dir .= "$version/" if $version;
    my $find_command = "find $dir -follow -name *.pat";
    my $results      = try_system_command($find_command);
    my @results      = split "\n", $results;
    my @filtered_results;

    for my $line (@results) {
        if ( $line =~ /\/(\w+\.pat)/ ) {
            push @filtered_results, $1;
        }
    }
    if ($debug) {
        Message "List of patches for package $package";
        print Dumper @filtered_results;
    }

    return \@filtered_results;
}

####################################
sub set_Patch_Status {
####################################
    # Description : Sets the Patch_Status in Patch Table
    # Input:
    #   - Name:     Patch Name
    #   - status: enum (installed, installed with errors, Installation aborted, installing, mark for install , Not installed)
    # Example:
    # <snip>
    #       $self -> set_Patch_Status(-name => $patch_name ,  -status => 'Installing');
    # </snip>
####################################
    my $self        = shift;
    my %args        = filter_input( \@_, -mandatory => 'name,status' );
    my $status      = $args{-status};
    my $debug       = $args{-debug};
    my $patch_name  = $args{-name};
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $num_records = $dbc->Table_update_array( -table => 'Patch', -fields => ['Install_Status'], -values => [$status], -condition => "WHERE Patch_Name = '$patch_name' ", -autoquote => 1, -no_triggers => 1 );
    if ( $debug & $num_records ) { Message "Patch [$patch_name] status set to $status" }

    return $num_records;
}

####################################
sub get_Patch_Status {
####################################
    # Description : Checks and gets the Patch_Status
    # Input:
    #   - Name:     Patch Name
    # Output:
    #   - Patch_Status if found and 'not found' if record is not in databse
    # Example:
    # <snip>
    #   my $status= get_Patch_Status(-name => $package_name );
    # </snip>
####################################
    my $self       = shift;
    my %args       = filter_input( \@_, -mandatory => 'name' );
    my $patch_name = $args{-name};
    my $debug      = $args{-debug};
    my $dbc        = $args{-dbc} || $self->{dbc};
    my ($status) = $dbc->Table_find( 'Patch', 'Install_Status', "WHERE Patch_Name = '$patch_name' " );
    unless ($status) { $status = 'not found' }
    if ($debug) { Message "Patch status is $status" }

    return $status;
}

####################################
sub get_Package_Status {
####################################
    # Description : Checks and gets the Package_Status
    # Input:
    #   - package:     Package Name
    # Output:
    #   - Package_Status if found and null if record is not in databse
    # Example:
    # <snip>
    #   my $status= $self -> get_Package_Status(-package => $package_name );
    # </snip>
####################################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $package = $args{ -package };
    my $debug   = $args{-debug};
    my $dbc     = $args{-dbc} || $self->{dbc};

    my ($status) = $dbc->Table_find( 'Package', 'Package_Install_Status', "WHERE Package_Name = '$package' " );
    if ($debug) { Message "Package status is $status" }
    return $status;
}

####################################
sub get_Parent_Packages {
####################################
    #   Description:
    #       Returns the list of Parent of package and their parents recursively
    #   Output:
    #       List of package_ids (array reference)
    # <snip>
    #    my $parent_packages_ids = get_Parent_Packages (-dbc => $dbc, -package =>$package);
    # </snip>
####################################
    my %args    = filter_input( \@_, -mandatory => 'package' );
    my $dbc     = $args{-dbc};
    my $package = $args{ -package };
    my $debug   = $args{-debug};
    my @final_list;
    my ($parent_id) = $dbc->Table_find( 'Package', 'Package_ID', " WHERE Package_Name = '$package' " );

    if ($debug) {
        Message "Query: Select Package_ID from Package WHERE Package_Name = '$package'  ";
    }
    push @final_list, $parent_id if $parent_id;

    while ($parent_id) {
        ($parent_id) = $dbc->Table_find( 'Package', 'FKParent_Package__ID', " WHERE Package_ID = $parent_id " );
        if ($debug) {
            Message "Query: Select FKParent_Package__ID from Package WHERE Package_ID = $parent_id   ";
        }
        push @final_list, $parent_id if $parent_id;
    }
    return \@final_list;
}

####################################
sub add_Package_record {
####################################
    # This Method adds a record to package Table
####################################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $package  = $args{ -package };
    my $debug    = $args{-debug};
    my $category = $args{-category};
    my $parent   = $args{-parent_package};
    my $dbc      = $args{-dbc} || $self->{dbc};

    my ($parent_ID) = $dbc->Table_find( 'Package', 'Package_ID', "WHERE Package_Name = '$parent'" );
    unless ($parent_ID) {
        Message "Pakcage $parent does not exist in database and cannot continue";
        return;
    }

    my $fields = [ 'Package_Scope', 'Package_Active', 'Package_Name', 'Package_Install_Status', 'FKParent_Package__ID' ];
    my $values = [ $category, 'n', $package, 'Not installed', $parent_ID ];
    my $package_id = $dbc->Table_append_array( "Package", $fields, $values, -autoquote => 1, -no_triggers => 1 );
    return $package_id;
}

####################################
sub get_Latest_Version {
####################################
    # Description:
    #   - This method return the latest Patch_Version
    # Input:
    #   - file:     The fully qualified file where the versions are being stored
    #   - version:  The version of database (eg 2.5 ,2.6  , 2.7 ...)
    #   - patch:    Patch
    # Output:
    #   - two variables fist oen version second a bolean
    #   - patch version (2.7.3.1)
    #   - Will return 1  if patch is already in version_tracker file
    # <snip>
    #  my $last_version = $self -> get_Latest_Version (-file => '../install/patches/version_tracker.txt', -version => $version );
    # </snip>
#####################################
    my $self              = shift;
    my %args              = filter_input( \@_, -mandatory => 'file,version,patch' );
    my $version           = $args{-version};
    my $file              = $args{-file};
    my $debug             = $args{-debug};
    my $patch_name        = $args{-patch};
    my $group_version     = $args{-group_version};
    my $test              = $args{-test};
    my $final_sub_version = 0;

    if ($debug) {
        Message "=========================================";
        Message "Input to get_Latest_Version";
        print Dumper %args;
        Message "=========================================";
    }

    print "F: $file / $debug.\n";
    ## first step is to update the file from svn
    my $ok = SDB::SVN->update( -file => $file, -debug => $debug );
    Message $ok if $debug;

    ## open file and parse into an array
    open( VERSION_CONTROL, "<$file " ) or die "Could not open version control file for read: $file ";
    my @lines = <VERSION_CONTROL>;
    close VERSION_CONTROL;

    ## get the largest matching the version no matter the group version
    for my $line (@lines) {
        my @values = split "\t", $line;
        if ( $values[0] =~ /^$version\.(.+)/ ) {
            my $sub_ver = $1;
            if ( $sub_ver > $final_sub_version ) {
                $final_sub_version = $sub_ver;
            }

            if ( $values[1] =~ /\b$patch_name\b/i ) {
                if ($debug) { Message " Found patch [$patch_name] in file but not in tables" }
                return $values[0], 1;
            }
        }

    }
    if ( !$final_sub_version && defined $final_sub_version ) {
        $final_sub_version = '0.0';
    }
    if ($debug) {
        Message "Latest version is  $version.$final_sub_version";
        Message " $version -- ";
        Message " $final_sub_version -- ";

    }

    ## if there's group flag set need to get the latest patch from that group
    my $group_sub_version;
    my $total_sub_ver;

    ## if custom remove last section
    if ( $group_version =~ /(.+\..+\..+\..+)\..+\..+/ ) {
        $group_version = $1;
    }

    my $original_group_version = $group_version;
    if ($group_version) {

        $group_version =~ s/\.\d+$//;
        for my $line (@lines) {
            my @values = split "\t", $line;
            if ( $values[0] =~ /^$group_version\.(\d+)$/ ) {

                my $sub_ver = $1;
                if ( $sub_ver > $group_sub_version ) {
                    $group_sub_version = $sub_ver;
                }
            }
            elsif ( $values[0] =~ /^$group_version\.(.+)(\d+)$/ ) {
                my $first_part = $1;
                my $sub_ver    = $2;
                if ( $sub_ver > $group_sub_version ) {
                    $group_sub_version = $sub_ver;
                    $total_sub_ver     = $first_part . $sub_ver;
                }
            }
        }
        if ( !$total_sub_ver && !$group_sub_version ) {
            return;
        }

        unless ($group_sub_version) { $group_sub_version = 0 }
        my $grp_ver = $group_version . '.' . $group_sub_version;
        $grp_ver = $group_version . '.' . $total_sub_ver if $total_sub_ver;
        my $actual_ver = $version . '.' . $final_sub_version;
        unless ( $grp_ver eq $actual_ver ) {
            Message " There is at lease one version [$actual_ver] exist after the last version you are requesting [$grp_ver ]";
        }
        return $grp_ver, 0;
    }

    return $version . '.' . $final_sub_version, 0 if $final_sub_version;
    return;
}

####################################
sub get_Next_Version {
####################################
    # Description:
    #   This method gives you the next and latest available patch_version
    # Input:
    #   - previous version : last known patch version (eg 2.6.1.3 , 2.5.4.1 , 2.7.3.1.gsc.1)
    #   - category:          Core, custom, Plugins
    #   - group_version:    it means this patch is being installed as a group of patches
    #   - package:          the name of custom poackages must be there
    # Output:
    #   - next version
    # <snip>
    #  $next_version = $self -> get_Next_Version (-previous_version => $last_version , -category => $category, -version => $version );
    # </snip>
####################################
    my $self          = shift;
    my %args          = filter_input( \@_, -mandatory => 'previous_version,category' );
    my $last_version  = $args{-previous_version};
    my $debug         = $args{-debug};
    my $category      = $args{-category};
    my $group_version = $args{-group_version};
    my $package       = $args{ -package };

    if ($debug) {
        Message "=========================================";
        Message "Input to get_Next_Version";
        print Dumper %args;
        Message "=========================================";
    }

    my $sub_version;
    my $custom_part;
    my $final_custom_version;

    ## replace dots with undescores to allow seperation
    my $past_version = $last_version;
    $last_version =~ s/\./_/g;
    my @details              = split '_', $last_version;
    my $main_version         = $details[0] . '.' . $details[1];
    my $sub_version_part_one = $details[2];
    my $sub_version_part_two = $details[3];
    my $custom_name          = $details[4];
    my $custom_version       = $details[5];

    if ($group_version) {
        my $temp_g_ver = $group_version;
        $temp_g_ver =~ s/\./_/g;
        my @gr_details              = split '_', $temp_g_ver;
        my $gr_sub_version_part_one = $gr_details[2];
        my $gr_custom_version       = $gr_details[5];
        $final_custom_version = $custom_version + 1;
        $sub_version_part_one = $gr_sub_version_part_one;
        unless ( $category eq 'custom' ) {
            $sub_version_part_two++;
        }
    }
    else {
        $sub_version_part_one++;
        $sub_version_part_two = '0';
    }
    $sub_version = $sub_version_part_one . '.' . $sub_version_part_two;

    ## Handling the custom part
    if ( $category eq 'custom' ) {
        if ($final_custom_version) {
            if ( $custom_name eq $package ) { $custom_part .= '.' . $custom_name . '.' . $final_custom_version }
            elsif ( !$package ) { Message "Erroe: NO Package declared for version tracker" }
            else                { $custom_part .= '.' . $package . '.' . $final_custom_version }
        }
        else { $custom_part = '.' . $package . '.' . 1 }
    }

    my $final_result = $main_version . '.' . $sub_version . $custom_part;
    if ($debug) {
        Message "The new Version is $final_result";
    }
    return $final_result;

}

####################################
sub update_Version_Tracker {
####################################
    # Description:
    #   Updates and commits the version tracker file
    # Input:
    #   - version       to be written into file
    #   - package       to be written into file
    #   - patch         to be written into file
    #   -file           the full path of the file to be written into
    # output:
    #   returns 1 on success 0 on failure
    # <snip>
    # my $ok = $self -> update_Version_Tracker (-file => $version_tracker_file , -version => $next_version,-patch_name=>$patch_name,-package =>$package);
    # </snip>
####################################
    my $self       = shift;
    my %args       = filter_input( \@_, -mandatory => 'file,version,patch_name,package' );
    my $version    = $args{-version};
    my $file       = $args{-file};
    my $debug      = $args{-debug};
    my $patch_name = $args{-patch_name};
    my $package    = $args{ -package };
    my $test       = $args{-test};

    my $patch_file_name = $patch_name . '.pat';
    my $line            = "\n" . $version . "\t" . $patch_name . "\t" . $package;
    open( VERSION_CONTROL, ">>$file " ) or die "Could not open version control file for write: $file ";
    print VERSION_CONTROL "$line";
    close VERSION_CONTROL;

    #    my $ok = SDB::SVN::commit (-file => $file , -message => "updating the version_tracker file for package $package , patch $patch_name ", -debug => $debug);
    #    Message $ok if $debug;

    return 1;

}

####################################
sub get_current_and_previous_Version_ids {
####################################
    my %args    = filter_input( \@_, -mandatory => 'version,dbc' );
    my $version = $args{-version};
    my $dbc     = $args{-dbc};

    my @version = $dbc->Table_find( 'Version', 'Version_ID', " WHERE Version_NAme <= $version " );
    return join ',', @version;
}

####################################
sub create_temp_file {
####################################
    #   Description:
    #   - This Method creates a temp file and inserts the section given into it then returns the full path
####################################
    my $self    = shift;
    my %args    = filter_input( \@_, -mandatory => 'section' );
    my $section = $args{-section};
    my $debug   = $args{-debug};
    ## Create  a temp file and put the contents of section into it
    my $temp_dir = $self->get_patch_dir( -temp => 1 );
    my $file = "$temp_dir/Temp1";

    open( TEMP, ">$temp_dir/Temp1" ) or die "Unable to open temp file  (attempted to open $temp_dir/Temp1 for writing)";
    for my $line (@$section) {
        print TEMP "$line \n";
    }
    close TEMP;
    return $file;
}

####################################
sub run_install_package {
####################################
    #   Description:
    #   - This Method should be called to install a package using the install.pl
####################################
    my $self    = shift;
    my %args    = filter_input( \@_, -mandatory => 'section' );
    my $section = $args{-section};
    my $debug   = $args{-debug};
    my $dbc     = $self->{dbc};
    my $host    = $dbc->{host};
    my $dbase   = $dbc->{dbase};
    my $user    = $dbc->{login_name};
    my $pass    = $dbc->{login_pass};

    for my $command (@$section) {
        my $dir = $FindBin::RealBin;
        if ( $dir =~ /^(.*)\/install\/(\w+)/ ) {
            $dir = "$1/bin";
        }
        $command = "$dir/$command -user $user -pass $pass -host $host -dbase $dbase";
        if ($debug) {
            Message "install package command: $command";
        }
        try_system_command(qq{$command});
    }

    return 1;
}

####################################
sub get_Version_Tracker_Files {
####################################
    #   This method get a list of all aplicable version_tracker files (with full path)
    #   Both custom and Core
####################################
    my $self             = shift;
    my %args             = filter_input( \@_ );
    my $debug            = $args{-debug};
    my $dbc              = $args{-dbc} || $self->{dbc};
    my $Report           = $args{-report} || $self->{report};
    my $bin              = $args{-bin};
    my $customs_packages = $args{-custom} || $self->get_Active_Packages( -debug => $debug, -type => 'custom' );

    my @vt_files;
    my $core_vt = "$root/install/patches/version_tracker.txt";
    push @vt_files, $core_vt;

    if ($customs_packages) {
        for my $custom (@$customs_packages) {
            push @vt_files, "$root/install/patches/custom/$custom/version_tracker.txt";
        }
    }

    if ($debug) {
        Message "List of Version Tracker Files";
        print Dumper \@vt_files;
        $Report->set_Message( "List of Version Tracker Files:" . Dumper \@vt_files );
    }
    return \@vt_files;

}

####################################
sub get_Active_Packages {
####################################
    #   Description:
    #   - Returns a list of names of active packages
    #   Input:
    #   - Type (optional): enum (custom, Core, Plugins)
####################################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $debug     = $args{-debug};
    my $dbc       = $args{-dbc} || $self->{dbc};
    my $type      = $args{-type};
    my $Report    = $args{-report} || $self->{report};
    my $condition = "WHERE Package_Active ='y' and Package_install_status = 'Installed' ";

    if ($type) {
        $condition .= " AND Package_Scope = '$type'";
    }

    my @packages = $dbc->Table_find( 'Package', 'Package_Name', $condition );
    if ($debug) {
        Message "List of Active Packages: ";
        print Dumper \@packages;
        $Report->set_Message( "List of Active Packages : " . Dumper \@packages );
    }

    return \@packages;
}

####################################
sub get_Package_Type_hash {
####################################
    #   Used for building Package files
####################################
    my %hash = (
        'Department'   => 'Department',
        'Standard_App' => 'Standard_App',
        'Run'          => 'API,Statistics,Run,Analysis,Summary'
    );
    return \%hash;
}

####################################
sub set_DB_Version {
####################################
    my $self            = shift;
    my %args            = filter_input( \@_, -mandatory => 'version' );
    my $version         = $args{-version};
    my $dbc             = $args{-dbc} || $self->{dbc};
    my $fields          = [ 'Version_Status', 'Release_Date', 'Last_Modified_Date' ];
    my $values          = [ 'In use', &today(), &today() ];
    my $current_version = $self->get_Current_Database_Version();
    my $num_records     = $dbc->Table_update_array(
        -table       => 'Version',
        -fields      => ['Version_Status'],
        -values      => ['Not in use'],
        -condition   => "WHERE Version_Name =  $current_version",
        -autoquote   => 1,
        -no_triggers => 1
    );

    $num_records = $dbc->Table_update_array(
        -table       => 'Version',
        -fields      => $fields,
        -values      => $values,
        -condition   => "WHERE Version_Name =  $version",
        -autoquote   => 1,
        -no_triggers => 1
    ) if $num_records;

    return $version if $num_records;
}

####################################
sub get_Next_Database_Version {
####################################
    my $self = shift;
    my $dbc  = $self->{dbc};

    my ($version_id) = $dbc->Table_find( 'Version', 'MIN(Version_ID)', " WHERE Release_Date = '0000-00-00'" );
    my ($version)    = $dbc->Table_find( 'Version', 'Version_Name',    " WHERE Version_ID = $version_id" );
    unless ($version) {
        my $last = $self->get_Current_Database_Version();
        my ( $pre, $post ) = split /\./, $last;
        $post++;
        $version = $pre . '.' . $post;
        my $ok = $dbc->Table_append_array( "Version", [ 'Version_Name', 'Release_Date', 'Last_Modified_Date', 'Version_Status' ], [ "$version", '0000-00-00', '0000-00-00', 'Not in use' ], -autoquote => 1, -no_triggers => 1 );
    }

    return $version;
}

####################################
sub get_Current_Database_Version {
####################################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my ($version) = $dbc->Table_find( 'Version', 'Version_Name', " WHERE Version_Status = 'In use'" );
    return $version;
}

####################################
sub get_db_version {
####################################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc  = $self->{dbc} || $args{-dbc};
    
    my ($version) = $dbc->Table_find( 'Version', 'Version_Name', " WHERE Version_Status = 'In use'" );
    return $version;
}

####################################
sub get_Package_Pacthes_from_version_tracker {
####################################
    #   Description:
    #       _ Gets Patches for certain package from the version traker fil
    #   Output:
    #       - array referecne of pacth names
    #       - Output will be sorted by Patch_Version
####################################
    my $self    = shift;
    my %args    = filter_input( \@_, -mandatory => 'package,file,version' );
    my $debug   = $args{-debug};
    my $file    = $args{-file};                                                ## array ref of list of version tracker files
    my $package = $args{ -package };
    my $test    = $args{-test};
    my $ok;
    my $version = $args{-version};
    my @vt_files = @$file if $file;
    my @all_patches;
    my @matched;

    for my $vt_file (@vt_files) {
        ## first step is to update the file from svn
        $ok = SDB::SVN::update( -file => $vt_file, -debug => $debug ) unless $test;
        Message $ok if $debug;

        ## open file and parse into an array
        open( VERSION_CONTROL, "<$vt_file " ) or die "Could not open version control file for read: $vt_file ";
        my @lines = <VERSION_CONTROL>;

        close VERSION_CONTROL;

        for my $line (@lines) {
            chomp $line;
            my @data = split "\t", $line;
            if ( ( $data[2] eq $package ) && ( $data[0] =~ /^$version/ ) ) {
                push @matched, \@data;
            }
        }
    }

    my @final;
    ##### SORT THEM HERE PLEASE
    for my $match_ref (@matched) {
        my @match = @$match_ref if $match_ref;
        push @final, $match[1] . '.pat';
    }

    ###########################
    return \@final;
}

####################################
sub sort_Patches_array {
####################################
    #   Description:
    #       - This method takes in a list of patches and sorts them accoring to Patch_Version
    #       - It first uses version tracker files to get the pacth versions and then uses sort_Patches to sort them
    #   Input:
    #       -patches    an array reference containing Patch names
    #       -files      an array reference containg version tracker files
    #   Output:
    #       - A sorted list of Pathces (array reference)
####################################
    my $self     = shift;
    my %args     = filter_input( \@_, -madatory => 'patches' );
    my $debug    = $args{-debug};
    my $test     = $args{-test};
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $files    = $args{-files} || $self->get_Version_Tracker_Files( -debug => $debug );    #Version Tracker Files
    my $packages = $args{-packages} || $self->get_Active_Packages( -debug => $debug );
    my $patches  = $args{-patches};
    my @patches  = @$patches if $patches;

    my $to_version = $self->get_Next_Database_Version();
    my $versions   = $self->get_dbase_Versions( -debug => $debug, -to => $to_version );
    my @versions   = @$versions if $versions;
    my %all_patches;
    my @files = @$files if $files;

    ## Getting a full list of all pacthes and their versions
    for my $version (@versions) {
        for my $file (@files) {
            my $patches_version = $self->get_Patches_from_Version_Tracker( -debug => $debug, -file => $file, -packages => $packages, -version => $version, -test => $test );
            my $all_patches_ref = RGmath::merge_Hash( $patches_version, \%all_patches );
            %all_patches = %$all_patches_ref if $all_patches_ref;
        }
    }

    ## Selecting only those in our list (-patches)
    my %matched_pacthes;
    for my $all_patch ( keys %all_patches ) {
        if ( grep /^$all_patch$/, @patches ) {
            $matched_pacthes{$all_patch} = $all_patches{$all_patch};
        }
    }

    my $sorted = $self->sort_Patches( -patches => \%matched_pacthes, -debug => $debug );
    return $sorted;
}

####################################
sub sort_Patches {
####################################
    #   Description:
    #       - This method takes in a list of patches and sorts them accoring to Patch_Version
    #   Input:
    #       -patches    Hash reference with keys patch names and keys their patch_version
    #   Output:
    #       - A sorted list of Pathces (array reference)
####################################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $debug   = $args{-debug};
    my $patches = $args{-patches};
    my %patches = %$patches if $patches;
    my @sorted_patches;
    my $MAX_VALUE = 100;

    for my $patch ( keys %patches ) {
        my $value = $patches{$patch};
        $value =~ s/\./\_/g;
        my $calculated_value;

        my @numbers = split "_", $value;
        for my $counter ( 0 .. 5 ) {
            unless ( $numbers[$counter] ) { $numbers[$counter] = 0 }
            $calculated_value += ( $MAX_VALUE**( 5 - $counter ) ) * $numbers[$counter];
        }
        $patches{$patch} = $calculated_value;
    }

    for my $sorter ( sort { $patches{$a} cmp $patches{$b} } keys %patches ) {
        push @sorted_patches, $sorter;
    }
    if ($debug) {
        Message "-- Sorted pacthes by version tracker and found: --";
        print Dumper @sorted_patches;
    }
    return \@sorted_patches;
}

####################################
sub get_dbase_Versions {
####################################
    #   Returns list of all versions upto and including the verison entered
####################################
    my $self    = shift;
    my %args    = filter_input( \@_, -mandatory => 'to' );
    my $debug   = $args{-debug};
    my $from    = $args{-from};
    my $to      = $args{-to};
    my $dbc     = $args{-dbc} || $self->{dbc};
    my @version = $dbc->Table_find( 'Version', 'Version_Name', "WHERE  Version_Name <= $to  ORDER BY Version_Name " );
    return \@version;
}

####################################
sub run_bin_file {
####################################
    my $self           = shift;
    my %args           = filter_input( \@_, -mandatory => 'file' );
    my $file           = $args{-file};
    my $include_blocks = $args{-include_blocks} || 'all';             ## comma-delimited
    my $exclude_blocks = $args{-exclude_blocks};                      ## comma-delimited
    my $new_records    = $args{-new_records};
    my $libraries      = $args{-libraries};
    my $debug          = $args{-debug};
    my $Report         = $args{-report};

    my $dbc   = $self->{dbc};
    my $host  = $dbc->{host};
    my $dbase = $dbc->{dbase};
    my $user  = $dbc->{login_name};
    my $pass  = $dbc->{login_pass};

    my $fb;

    ## <taken from upgrade_db.pl>
    if ( -e "$file" ) {
        my $command;
        my $temp_dir       = $self->get_patch_dir( -temp => 1 );
        my $base_patch_dir = $self->get_patch_dir( -base => 1 );
        $command = "cat $base_patch_dir/header.pl $file $base_patch_dir/footer.pl > $temp_dir/temp.pl";
        my $feedback;
        Message "Generating temp.pl";
        if ($debug) {
            Message "cat CMD: $command";
        }
        $feedback = try_system_command("$command");

        $command = "chmod 755 $temp_dir/temp.pl";
        Message "Changing mode of temp.pl";
        if ($debug) {
            Message "Perm CMD: $command";
        }
        $feedback = try_system_command($command);

        $include_blocks = "-b $include_blocks" if ($include_blocks);
        $exclude_blocks = "-B $exclude_blocks" if ($exclude_blocks);
        $libraries      = "-L $libraries"      if ($libraries);
        $new_records    = "-N $new_records"    if ($new_records);

        $command = "$temp_dir/temp.pl -D $dbase -u $user -h $host $include_blocks $exclude_blocks $libraries $new_records";
        Message "Running temp.pl";
        Message "Command: $temp_dir/temp.pl -D $dbase -u $user -h $host $include_blocks $exclude_blocks $libraries $new_records";
        if ($debug) {
            Message "$command";
            Message "^ Command for running temp.pl";
        }
        $fb = try_system_command("$command");

    }
    my $success;
    if ( $fb =~ /error|forgot to load/i ) {
        if   ($Report) { $Report->set_Message( "Ran code blocks:\n" . $fb . "\n.\n" ) }
        else           { Message "FB:\n$fb" }
        $success = 0;
    }
    else {
        $success = 1;
    }
    return $success;
}

####################################
sub run_dbfield_set {
#####################
    #<snip>
    #e.g. $self->run_dbfield_set();
    #</snip>
#####################
    my $self            = shift;
    my %args            = filter_input( \@_ );
    my $reorder_fields  = $args{-reorder_fields};
    my $new_tables_only = $args{-new_tables_only};
    my $tables          = $args{-tables};
    my $debug           = $args{-debug} || 1;

    my $dbc   = $self->{dbc};
    my $host  = $dbc->{host};
    my $user  = $dbc->{login_name};
    my $dbase = $dbc->{dbase};

    my $more_arguments = '';

    $more_arguments .= " -reorder_fields $reorder_fields" if ($reorder_fields);
    $more_arguments .= " -new_tables"                     if ($new_tables_only);
    $more_arguments .= " -tables $tables"                 if ($tables);

    my $command = "$root/bin/dbfield_set.pl -host $host -dbase $dbase -u $user $more_arguments";
    Message "Running dbfield_set: $more_arguments";

    if ($debug) {
        Message "CMD: $command";
    }
    my $fb = try_system_command("$command");
    my $success;
    if ( $fb =~ /error/i ) {
        $success = 0;
    }
    else {
        $success = 1;
    }
    return $success;

}

####################################
sub load_custom_config {
####################################
    #   Description:
####################################
    my $version = shift;

    my $Sys_config_file;
    if ($version) {
        $Sys_config_file = "$root/custom/$version/conf/system.cfg";
    }
    else {
        $Sys_config_file = "$root/conf/system.cfg";
    }
Call_Stack();
    my %configs;
    if ( -f $Sys_config_file ) {
        eval "require XML::Simple";
        my $data = XML::Simple::XMLin("$Sys_config_file");
        %configs = %{$data};
    }
    else {
        die "no sys config file $Sys_config_file found during installation\n";
    }
    return \%configs;
}

########################################################################################################################################################################
####################
sub get_last_patch_version {
####################
    #   Gets the last patch at any given revision
    #       Looks at verison tracker file
    #
####################
    my $self     = shift;
    my %args     = filter_input( \@_, mandatory => 'revision' );
    my $revision = $args{-revision};
    my $root     = $args{-root};

    my $version  = $self->get_Current_Database_Version();
    my $vt_files = $self->get_Version_Tracker_Files( -bin => $root . "/bin" );
    my @vt       = @$vt_files if $vt_files;
    my @latest;
    my @versions;
    for my $version_tracker (@vt) {
        my @lines = split "\n", SDB::SVN::get_file_from_svn( -revision => $revision, -file => $version_tracker );
        for my $line (@lines) {
            if ( $line =~ /^$version\.(.+)\s+.+\s+.+/ ) {
                push @versions, $1;
            }
        }
    }
    return $version . '.' . greatest_version( \@versions );
}

####################
sub greatest_version {
####################
    my $array_ref = shift;
    my @array     = @$array_ref;
    my $greatest  = $array[0];

    for my $entry (@array) {
        $greatest = greater_version( $entry, $greatest );
    }

    return $greatest;
}

###################
sub version_sort {
###################
    my $array = shift;

    my @list = Cast_List( -list => $array, -to => 'array' );

    my @sorted;

    ## for test below, return 1 (if A > B) || -1 (if A != B) || 0 (A=B)

    # foreach my $i (sort { ( greater_version($a,$b) eq $a) || -1* } @list) {   ## not ideal since doesn't allow for 0 case - not clear on effect... better to be safe below :
    foreach my $i ( sort { ( $a ne $b && greater_version( $a, $b ) eq $a ) || -1 * ( $a ne $b ) } @list ) {
        push @sorted, $i;
    }
    return @sorted;
}

####################
sub greater_version {
####################
    my $one = shift;
    my $two = shift;

    my @ones = split /\./, $one;
    my @twos = split /\./, $two;
    my $index;

    while ( $ones[$index] || $twos[$index] ) {
        if ( $ones[$index] && !$twos[$index] ) {
            return $one;
        }
        elsif ( !$ones[$index] && $twos[$index] ) {
            return $two;
        }
        elsif ( $ones[$index] > $twos[$index] ) {
            return $one;
        }
        elsif ( $ones[$index] < $twos[$index] ) {
            return $two;
        }
        $index++;
    }

    return $one;
}

########################
sub cleanup_temp_files {
########################
    #
    #
    # Cleans up temporary files
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $patches = $args{-patches};
    my $force   = $args{-force};
    my $debug   = $args{-debug};

    my $temp_dir;
    my $success;
    my $cmd;

    my $temp_dir = $self->get_patch_dir( -temp => 1 );
    Message "Removing all files from temp dir: $temp_dir";

    if ($force) { $cmd = "rm $temp_dir/*" }

    my $check_fb = try_system_command("ls $temp_dir/*");
    unless ( $check_fb =~ /no such file or directory/i ) {
        my $fb = try_system_command("$cmd");
        if ($fb) {
            Message "FB: $fb";
            $success = 0;
        }
        else {
            $success = 1;
        }
    }

    #remove unique temp directory
    if ($success) {
        my $fb = try_system_command("rmdir $temp_dir");
        if ($fb) {
            Message "FB from rmdir command: $fb";
        }
    }
    return $success;
}

######################
sub get_package_tables {
########################
    # <snip>
    # e.g. my @pkgs_tables = $self->get_package_tables(-package_name=>"$pkg_name");
    # </snip>
######################
    my $self     = shift;
    my %args     = filter_input( \@_, -mandatory => 'package_name|package_id' );
    my $pkg_name = $args{-package_name};
    my $pkg_id   = $args{-pkg_id};

    my @pkg_tables;

    if ( $pkg_id && !$pkg_name ) {
        ($pkg_name) = $self->{dbc}->Table_find( 'Package', "Package_Name", "WHERE Package_ID = $pkg_id" );
    }
    my %pkg_info = $self->{dbc}->Table_retrieve( 'Package', [ "Package_Scope", "Package_Install_Status" ], "WHERE Package_Name = '$pkg_name'" );
    my $scope = $pkg_info{Package_Scope}[0] || 'core';
    if ( ( $pkg_info{Package_Install_Status} =~ /^installed$/i ) ) {
        @pkg_tables = $self->{dbc}->Table_find( "Package,DBTable", "DBTable_Name", "WHERE FK_Package__ID = Package_ID AND Package_Name = '$pkg_name'" );
    }
    else {
        @pkg_tables = $self->_find_pkg_tables( "$pkg_name", "$scope" );
    }
    return @pkg_tables;
}

######################
sub _find_pkg_tables {
######################
#### copied from dbfield_set.pl

    my $self          = shift;
    my $package_name  = shift;
    my $package_scope = shift;

    my $code_version = $self->{version};

    my @package_tables;

    my $dir = "$FindBin::RealBin/..";
    my $table_file;

    if ( $package_name =~ /(lab|core)/ ) {
        $dir .= "/install/init/release/$code_version";
        $table_file = "core_tables.conf" if ( $package_name =~ /core/i );
        $table_file = "lab_tables.conf"  if ( $package_name =~ /lab/i );
        my $full_path = "$dir/$table_file";
    }
    else {
        my $scope_folder = "custom" if ( $package_scope =~ /custom/i );
        $scope_folder = "Plugins" if ( $package_scope =~ /plugin/i );
        $scope_folder = "Options" if ( $package_scope =~ /option/i );
        $dir .= "/$scope_folder/$package_name/conf";
        $table_file = 'tables.conf';
    }
    if ( -f "$dir/$table_file" ) {
        open( TABLES, "<$dir/$table_file" );
        foreach my $line (<TABLES>) {
            chomp $line;
            $line =~ s/\s*$//;
            $line =~ s/^\s*//;
            next if ( $line =~ /^\#/ );
            unless ( !$line ) {
                push @package_tables, $line;
            }
        }
    }
    else {
        return ();
    }

    return @package_tables;
}

###################
sub get_patch_dir {
####################
    #<snip>
    #e.g. my $patch_dir = $self->get_patch_dir(-addon=>$patch_pkg);
    # my $patch_dir = $self->get_patch_dir(-temp=>1);
    #</snip>
####################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $scope     = $args{-scope};
    my $core      = $args{-core};
    my $addon     = $args{-addon};
    my $temp      = $args{-temp};
    my $base      = $args{-base};
    my $custom    = $args{-custom};
    my $tracker   = $args{-tracker};
    my $version   = $args{-version} || $self->{version} || $self->get_db_version();
    my $make_dirs = $args{ -mkdir } || 0;
    my $dbc       = $self->{dbc};
    my $patch_dir;
    my $directory;
    $scope = "core" if ( !( $scope || $addon || $temp ) || ($core) );

    if ($addon) {
        ($scope) = $dbc->Table_find( 'Package', "Package_Scope", "WHERE Package_Name = '$addon'" );

        $custom = $addon if ( $scope =~ /custom/i );
    }
    $addon = '' if ( $addon =~ /^core$/i );
    my $base_patches_dir = "$root/install/patches";
    if ($base) {
        $directory = $base_patches_dir;
    }
    elsif ($tracker) {
        $directory = $base_patches_dir;
        if ($custom) {
            $directory .= "/custom/$custom";
        }
    }
    elsif ($temp) {

        #$directory = "$base_patches_dir/temp";
        my $unique_temp = $dbc->{host} . '_' . $dbc->{dbase} . '_' . $self->{version};
        $directory = "$base_patches_dir/temp/" . $unique_temp;

        if ( !( -e "$directory" ) ) {
            my $fb = try_system_command("mkdir $directory");
            if ($fb) {
                Message "FB from mkdir command: $fb";
                return $directory;
            }
        }
    }
    elsif ($addon) {
        my ($scope) = $dbc->Table_find( 'Package', "Package_Scope", "WHERE Package_Name = '$addon'" );
        my $type_dir;
        $type_dir = 'custom'  if ( $scope =~ /custom/i );
        $type_dir = 'Plugins' if ( $scope =~ /plugin/i );
        $type_dir = 'Options' if ( $scope =~ /option/i );
        $patch_dir = "$base_patches_dir/$type_dir/$addon/$version";
        $directory = $patch_dir;
        unless ( !$make_dirs ) {

            if ( !( -d "$base_patches_dir/$type_dir/$addon/install/patches" ) ) {    ## make link for addon patches
                my $fb = try_system_command("mkdir $base_patches_dir/$type_dir/$addon/install/patches");
            }
            if ( !( -e "$patch_dir" ) ) {
                my $fb = try_system_command("mkdir $patch_dir");
                if ($fb) {
                    Message "FB from mkdir command: $fb";
                    return $directory;
                }
            }
        }
    }
    else {
        $patch_dir = "$base_patches_dir/Core/$version";
        $directory = $patch_dir;
    }
    return $directory;
}

#################
sub run_sql_file {
#################
    # <snip>
    # e.g. my $feedback = $self->run_sql_file(-file=>"$full_file_path");
    # </snip>
#################
    my $self   = shift;
    my %args   = filter_input( \@_, -mandatory => 'file' );
    my $file   = $args{-file};
    my $Report = $args{-report} || $self->{report};
    my $debug  = $args{-debug};

    if ( !$file ) {
        if ($debug) {
            warn "No file parameter passed to run_sql_file";
            Call_Stack();
        }
        return 0;
    }

    my $success;
    $Report->start_Section("Run $file");

    my ( $failed_statements, $successful_statements ) = $self->{dbc}->run_sql_file( -file => $file, -monitor => 1, -debug => $debug, -report => $Report );
    my $success_count = scalar(@$successful_statements);
    my $failure_count = scalar(@$failed_statements);

    ## document errors found ##
    foreach my $failure (@$failed_statements) {
        $Report->set_Error($failure);
    }

    $Report->end_Section("Run $file");

    $Report->set_Message("$success_count successful statements in file: $file");

    if ( ( defined $failed_statements ) && scalar( @{$failed_statements} ) > 0 ) {
        $success = 0;
        my $error_count = scalar(@$failed_statements);
        $Report->set_Error("$error_count failed statements in the file: $file");
        $Report->{quiet} = 1;
        foreach my $statement (@$failed_statements) {
            $Report->set_Error("SQL Statement: $statement");
        }
        $Report->{quiet} = 0;
    }
    else {
        $success = 1;
    }

    return $success;
}

#################################
sub get_installed_packages {
#################################
    #<snip>
    #e.g. my %packages = $self->get_installed_packages();
    #</snip>
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $dbc   = $self->{dbc};
    my $scope = $args{-scope};

    my @installed_packages;

    my $query_append;
    if ($scope) {
        $scope =~ s/Custom*/custom/;
        $scope =~ s/plugin*/Plugin/;
        $scope =~ s/option*/Option/;
        $query_append = "AND Package_Scope = '$scope'";
    }

    my $installed_cond = "WHERE Package_Install_Status = 'Installed'";
    @installed_packages = $dbc->Table_find( "Package", "Package_Name", "$installed_cond $query_append" ) if ( $dbc->table_loaded('Package') );

    return @installed_packages;
}

###################
sub package_active {
####################
    # <snip>
    # e.g. my $installed = $Installation->package_active(-name=>"$addon_name");
    # </snip>
    my $self = shift;
    my %args = filter_input( \@_ );
    my $name = $args{-name};
    my $dbc  = $self->{dbc};

    my $active;

    if ( grep /^$name$/, @{ $self->{packages}{active} } ) {
        $active = 1;
    }
    else {
        $active = 0;
    }

    return $active;
}

###########################
sub get_installed_patches {
###########################
    #<snip>
    #e.g. my @installed_patches = $self->get_installed_patches();
    #</snip>
## return patch ids of installed patches
###########################
    my $self         = shift;
    my %args         = filter_input( \@_ );
    my $scope        = $args{-scope};           ##(Package or Core)
    my $addon        = $args{-addon};           ##name of addon;
    my $return_field = $args{-return_field};    ##Patch_ID or Filename
    my $dbc          = $self->{dbc};
    $scope = 'core' if ( !$addon );

    my $version = $self->{version} || $self->get_db_version();
    my @installed_patches;
    my $installed_patch_cond = "WHERE 1 ";
    if ($addon) {
        $installed_patch_cond .= "AND Patch_ID IN (SELECT Patch_ID FROM Patch WHERE FK_Package__ID = (SELECT Package_ID FROM Package WHERE Package_Name = '$addon'))";
    }
    elsif ( $scope =~ /core/i ) {
        $installed_patch_cond .= "AND Patch_ID IN (SELECT Patch_ID FROM Patch WHERE FK_Package__ID IN (0,(SELECT Package_ID FROM Package WHERE Package_Name = 'Core')))";
    }
    $installed_patch_cond .= " AND Install_Status = 'Installed'";

    if ( $return_field =~ /id/i ) {
        $return_field = "Patch_ID" if ( $return_field =~ /id$/i );
    }
    else {
        $return_field = "Patch_Name";
    }
    my @installed_patches;

    @installed_patches = $dbc->Table_find( 'Patch', "$return_field", "$installed_patch_cond" ) if ( $dbc->table_loaded('Patch') );

    return @installed_patches;
}

#####################
sub install_package {
#####################
    my $self = shift;
    my %args = filter_input( \@_ );
    return $self->install_Package(%args);
}

#####################
sub update_patches {
#####################
    my $self    = shift;
    my %args    = filter_input( \@_, -mandatory => 'version' );
    my $version = $args{-version};
    my $quiet   = $args{-quiet};

    my $plugins  = $Configs{Plugins};
    my $home_dir = $Configs{Home_dir};
    my @response = split /,/, $plugins;

    #svn up Plugins/package_name/install
    for my $line (@response) {
        SDB::SVN::update( -file => "$home_dir/versions/$version/Plugins/$line/install", -quiet => $quiet );
    }

    #svn up install/
    SDB::SVN::update( -file => "$home_dir/versions/$version/install", -quiet => $quiet );

    #svn up custome/$custom/install
    my $custom = $Configs{custom};
    SDB::SVN::update( -file => "$home_dir/versions/$version/custom/$custom/install", -quiet => $quiet );

}

1