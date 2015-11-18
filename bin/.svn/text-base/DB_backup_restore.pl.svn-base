#!/usr/local/bin/perl
#
#  Wrapper to organize ordered cron jobs run on a daily basis
#

use strict;
use DBI;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Departments";

use SDB::CustomSettings;
use SDB::DBIO;
use SDB::Installation;
use RGTools::RGIO;
use RGTools::Process_Monitor;
use RGTools::Conversion;
use Data::Dumper;

use LampLite::Config;

use vars qw($opt_help $opt_quiet $opt_user $opt_password $opt_from $opt_X $opt_time $opt_restore $opt_T $opt_rm $opt_logs $opt_errs $opt_debug $opt_update $opt_force $opt_slave
    $opt_backup $opt_upgrade $opt_rebuild $opt_custom $opt_v $opt_packages  $opt_no_test_data   $opt_drop_obs $opt_local $opt_lock_master $opt_no_record $opt_routine);

use Getopt::Long;
&GetOptions(
    'help'            => \$opt_help,
    'quiet'           => \$opt_quiet,
    'user=s'          => \$opt_user,
    'password=s'      => \$opt_password,
    'from=s'          => \$opt_from,
    'X=s'             => \$opt_X,
    'T|tables=s'      => \$opt_T,
    'time=s'          => \$opt_time,
    'restore=s'       => \$opt_restore,
    'rm=s'            => \$opt_rm,
    'err|errs'        => \$opt_errs,
    'log|logs'        => \$opt_logs,
    'debug'           => \$opt_debug,
    'rebuild'         => \$opt_rebuild,
    'force'           => \$opt_force,
    'slave=s'         => \$opt_slave,
    'backup'          => \$opt_backup,
    'upgrade=s'       => \$opt_upgrade,
    'version|v=s'     => \$opt_v,
    'packages=s'      => \$opt_packages,
    'custom=s'        => \$opt_custom,
    'update=s'        => \$opt_update,
    'no_test_data'    => \$opt_no_test_data,
    'drop_obsolete=s' => \$opt_drop_obs,
    'local'           => \$opt_local,
    'lock_master'     => \$opt_lock_master,
    'no_record=s'     => \$opt_no_record,
    'routine'         => \$opt_routine
);

my $Config = LampLite::Config->new( -initialize=>$FindBin::RealBin . '/../conf/custom.cfg');

### STATIC Variables ###
my $prod_host  = $Config->{config}{PRODUCTION_HOST};
my $prod_dbase = $Config->{config}{PRODUCTION_DATABASE};
my $dev_host   = $Config->{config}{DEV_HOST};
my $log_dir = $Config->{config}{logs_data_dir};

#my $table_exclusions = 'Clone_Sequence,Cross_Match,Contaminant';
my $restore_test_data = {
    Clone_Sequence => [ "Run,Plate", "Group_Concat(Run_ID)",  "WHERE FK_Plate__ID = Plate_ID AND FK_Library__Name = 'HB001'", 'FK_Run__ID' ],
    Cross_Match    => [ "Run,Plate", "Group_Concat(Run_ID)",  "WHERE FK_Plate__ID = Plate_ID AND FK_Library__Name = 'HB001'", 'FK_Run__ID' ],
    Contaminant    => [ "Run,Plate", "Group_Concat(Run_ID)",  "WHERE FK_Plate__ID = Plate_ID AND FK_Library__Name = 'HB001'", 'FK_Run__ID' ],
    Band           => [ "Band",      "Group_Concat(Band_ID)", "WHERE Band_ID Between 1 and 1000",                             'Band_ID' ]
};

my $table_exclusions = join( ",", keys %$restore_test_data );
my $default_time = '23:00';
### Options ###
my $slave         = $opt_slave;                   ## use slave if possible (indicate host)
my $backup        = $opt_backup;                  ## flag to run backup of source database first
my $upgrade       = $opt_upgrade;
my $update        = $opt_update;
my $packages      = $opt_packages;
my $help          = $opt_help;
my $quiet         = $opt_quiet;
my $debug         = $opt_debug || !$opt_force;    ## runs in debug mode if force flag not set
my $rebuild       = $opt_rebuild;                 ## rebuilds restored databases
my $drop_obsolete = $opt_drop_obs;
my $custom_opt    = $opt_custom;
my $local         = $opt_local;                   ## IF the -local parameter is passed, it should be passed onto the restore call
my $version       = $opt_v;
my $lock_master   = $opt_lock_master;
my $routine       = $opt_routine;                 ##dumping stored procedures

## Overwritable defaults ###
my $user = $opt_user || 'repl_client';

#my $password  = $opt_password;
my $from      = $opt_from || "$prod_host:$prod_dbase";
my $restore   = $opt_restore;
my $time      = $opt_time || $default_time;
my $tables    = $opt_T || '';                            ## optional tables to rebuild
my $exclude   = $opt_X || $table_exclusions;             ## exclude both structure and data dump and restore
my $run_mode  = $opt_rm;                                 ## only run indicated run mode
my $errs      = $opt_errs;                               ## just display errs
my $logs      = $opt_logs;                               ## just display logs
my $no_record = $opt_no_record;                          ## gets only structure of table

if ($rebuild) { $rebuild = '-rebuild' }                  ## add rebuild flag if requested

my @restore_DBs;
my $no_log = ( $logs || $errs );                         ## do not log process if only looking at logs or errors

if ($restore) { @restore_DBs = split ',', $restore }
elsif ( !$logs && !$errs ) { help(); exit; }

my $this_dir = $FindBin::RealBin;
my $bin_dir  = $this_dir;


######## Run restore script ########
my $valid_users = 'aldente|rguin';
if ( !$logs && !$errs ) {
    my $username = `whoami`;
    if ( $username !~ /($valid_users)/ ) {
        print "Must run as 'aldente' user (not $username)\n";
        exit;
    }
}

my $time_arg = "-time $time";

my $exclude_tables;
my $exclude_provider;
if ($opt_X) {
    $exclude_provider = $exclude;
    $exclude_tables   = "-X $opt_X";
}
else { $exclude_tables = "-X $opt_X" }

my $include_tables;
if ($tables) { $include_tables = "-T $tables" }

###################### Backup and Restore beta/development versions #########################

my @blocks;
if ( $logs || $errs ) {
## get blocks from log file ##
    my @executed_blocks = split "\n", main::try_system_command("grep '^* <' $log_dir/DB_backup_restore.log | grep -v '</'");
    foreach my $executed (@executed_blocks) {
        Message($executed);
        if ( $executed =~ /<(.*)>/ ) {
            push @blocks, $1;
        }
    }
}

if ($backup) { push @blocks, "backup -> $from" }

foreach my $restore_DB (@restore_DBs) {
    push @blocks, "restore_structure -> $restore_DB";
    push @blocks, "restore_records -> $restore_DB";
}

if ($packages) {
    my @packages;
    if   ( $packages eq '1' ) { @packages = @restore_DBs }
    else                      { @packages = split ',', $packages; }
    foreach my $package_DB (@packages) {
        ## only perform these actions if upgrade flag is set ##
        push @blocks, "install_packages -> $package_DB";
    }
}

if ($update) {
    my @update_DBs;
    if   ( $update eq '1' ) { @update_DBs = @restore_DBs }
    else                    { @update_DBs = split ',', $update; }
    foreach my $update_DB (@update_DBs) {
        ## only perform these actions if upgrade flag is set ##
        push @blocks, "update -> $update_DB";
    }
}

if ($upgrade) {
    my @upgrade_DBs;
    if   ( $upgrade eq '1' ) { @upgrade_DBs = @restore_DBs }
    else                     { @upgrade_DBs = split ',', $upgrade; }
    foreach my $upgrade_DB (@upgrade_DBs) {
        ## only perform these actions if upgrade flag is set ##
        push @blocks, "upgrade -> $upgrade_DB";

        #  push @blocks, "compare_DB -> $upgrade_DB";
    }
}

if ($drop_obsolete) {
    my @drop_obsolete_DBs;
    if   ( $drop_obsolete eq '1' ) { @drop_obsolete_DBs = @restore_DBs }
    else                           { @drop_obsolete_DBs = split ',', $drop_obsolete; }
    foreach my $drop_obs_DB (@drop_obsolete_DBs) {
        push @blocks, "unistall_obsolete -> $drop_obs_DB";
    }
}

foreach my $restore_DB (@restore_DBs) {
    push @blocks, "integrity_check -> $restore_DB";
}

my $job = new Updater;

my $Report = Process_Monitor->new( -variation => $opt_v );

my $success = $job->run($run_mode);

if ($success) { $Report->succeeded() }

$job->show_fails();

if ( !$logs && !$errs ) {
    print "Success: $success.\n";
    $Report->completed();
}

if ( keys %$restore_test_data && !($opt_no_test_data) ) {

    #restore test data
    foreach my $exclude_table ( keys %$restore_test_data ) {
        foreach my $restore_DB (@restore_DBs) {
            restore_test_data( $restore_DB, $exclude_table, $restore_test_data->{$exclude_table} );
        }
    }
}

$Report->DESTROY();
exit;

#############
sub help {
    #############

    print <<HELP;
    Usage:  DB_backup_restore.pl -restore limsdev02:seqdev -upgrade 1
    *********
     
    (for cron mode use force flag to prevent shell command prompts)

    Mandatory Input:
    **************************#
     -restore <host>:<dbase>     ## eg -restore lims02:seqbeta,limsdev02:seqdev

    Options:
    **************************     
    -backup                      ## first perform backup of master Database
    -upgrade <host>:<dbase>  | 1 ## upgrade databases with patches (eg to upgrade production to development). Use '1' for upgrade on all restored databases
    -force                       ## autoconfirms shell prompts to user
    -debug                       ## shows commands being executed (defaults to on unless force flag is set.  ie debug =!force )
    -slave <slave_host>          ## tries to use slave host for backup to limit i/o use on production database
    -packages <host>:<dbase>     ## installs all available plugin and option packages
    -custom <custom name>        ## installs the custom package
    -update  <host>:<dbase>  | 1 ## updates databases with patches to leading edge of curent version. Use '1' for upgrade on all restored databases
    -no_test_data                ## does not add test data to big tables
    -remove_obsolete             ## remove all obsolete tables and fields
    -routine                     ## dump stored procedures
    
    Examples:
    ***********
    DB_backup_restore.pl -restore limsdev02:seqdev -slave lims01 -upgrade 1                                                 ## restore and upgrade DB
    DB_backup_restore.pl -restore limsdev02:seqdev,lims02:seqtest -slave lims01 -backup -upgrade limsdev02:seqdev -force    ## restore 2 DBs; only upgrade 1

    DB_backup_restore.pl -restore lims02:aldente_init_dev -from lims02:aldente_init_dev     ## restore specific database from specific backup

HELP
}

sub restore_test_data {
    my $DB            = shift;
    my $table         = shift;
    my $condition_ref = shift;
    my $ID_Table      = $condition_ref->[0];
    my $ID_Field      = $condition_ref->[1];
    my $ID_Cond       = $condition_ref->[2];
    my $Dump_Cond     = $condition_ref->[3];

    my ( $host,      $dbase )      = split( ":", $DB );
    my ( $host_from, $dbase_from ) = split( ":", $from );
    my $user       = 'repl_client';
    my $login_file = SDB::DBIO::_get_login_file();
    my $pwd1       = LampLite::Login::get_password( -host => $host, -user => $user, -file => $login_file, -method => 'grep' );
    my $pwd2       = LampLite::Login::get_password( -host => $host_from, -user => $user, -file => $login_file, -method => 'grep' );

    my $dbc = new SDB::DBIO( -host => $host_from, -dbase => $dbase_from, -user => $user, -connect => 1, -no_triggers => 1 );

    my ($IDs) = $dbc->Table_find( -table => $ID_Table, -fields => $ID_Field, -condition => $ID_Cond );
    my $command = "mysqldump -h $host_from -u $user -p$pwd2 $dbase_from $table -t \"-w$Dump_Cond IN ($IDs)\" | mysql -h $host -u $user -p$pwd1 -C $dbase";

    main::try_system_command($command);

}

##################### Define Package methods ######################

package Updater;
use SDB::CustomSettings;

##########
sub new {
##########
    my $self = {};
    bless $self, 'Updater';

    return $self;
}

##########
sub run {
##########
    my $self  = shift;
    my $block = shift;

    my @failed;
    my $success = 1;

    if ($block) {
        ## specific block requested ##
        @blocks = split ',', $block;
    }

    ## run all updates in order ##
    foreach my $block (@blocks) {

        #        print "\n";
        #        print "*"x50 . "\n";
        #        print "$block:  " . main::date_time() . "\n";
        #        print "*"x50 . "\n";

        $Report->start_Section($block);

        my $ok;

        my ( $method, $argument ) = split ' -> ', $block;
        if ($logs) {
            ## show block logs ##
            print "<Log>\n";
            print "cat '$log_dir/$method.$argument.log'\n";
            if   ( -f "$log_dir/$method.$argument.log" ) { print main::try_system_command("cat '$log_dir/$method.$argument.log'") }
            else                                         { print "No log file found for $method.$argument\n" }
            print "</Log>\n";
        }
        elsif ($errs) {
            ## show block errs (check .err log as well as error statements in standard log) ##
            my $err_string;
            if ( -f "$log_dir/$method.$argument.err" ) {
                $err_string .= main::try_system_command("cat '$log_dir/$method.$argument.err'");
            }
            if ( -f "$log_dir/$method.$argument.log" ) {
                $err_string .= main::try_system_command("grep '^!!' '$log_dir/$method.$argument.err'");
            }
            if ($err_string) { print "\n<Err>\n" . $err_string . "\n</Err>\n"; }
        }
        else {
            if ( -exists &$method ) {
                ## run block ##

                $ok = $self->$method($argument);
                if ( !$ok ) {
                    $Report->set_Error("*** Failed $block block ***");
                    push @failed, $block;
                    $success = 0;
                }
            }
            else {
                $Report->set_Warning("** Could not find $method($argument) block **... skipping...");
            }
        }
        $Report->end_Section($block);
    }
    $self->{failed} = \@failed;
    return $success;
}

################
sub show_fails {
################
    my $self = shift;

    my @failed = @{ $job->{failed} };
    if (@failed) {
        print "\n";
        print "****************\n";
        print "Failed Blocks:\n";
        print "****************\n";
        print join "\n", @failed;
        print "\n\n";
    }
    return;
}

#
# Generate the output direction suffix for the method in question
#
#
#############
sub output {
#############
    my $version = shift || '';
    my $level   = shift || 1;

    if ($version) { $version = ".$version" }

    my $method = main::Call_Stack( -level => $level, -quiet => 1 );
    $method =~ s/Updater:://;

    return "$log_dir/$method$version";
}

##############
sub _execute {
    ##############
    my $command  = shift;
    my $log_file = shift;

    print "$command\n\n";

    my $ok = 'y';
    if ($debug) {
        $ok = main::Prompt_Input( 'c', 'Continue ...?' );
    }

    my $success = 1;
    if ( $ok =~ /y/i ) {
        my $output = main::try_system_command($command);
        my $errors = main::try_system_command("grep '^!! ' $log_file.log");
        if ( $! || $errors ) {
            print ":\n$!\n";
            print "**********\n";
            print "$errors\n";
            print "**********\n";
            $success = 0;
        }
    }
    else {
        print " (skipped execution)..\n";
        $success = 1;
    }
    return $success;
}

##################################################
#
# Standard re-usable blocks:
#
#   restore - restores given dbase from production database
#   upgrade - upgrades restored dbase using patches
#   ------- compare_DB - ensure synchronization of upgraded database with next generation database ----OBSOLETE
#   update - upgardes to leading edge of current version
#   install_packages - installs all available plugins and options
#   unistall_obsolete - uninstalls the obsolete package
##################################################

##############
sub restore {
##############
    my $self       = shift;
    my $restore    = shift;
    my $parameters = shift;

    my ( $host, $dbase ) = split ':', $restore;

    if ($local) { $parameters .= " -local LOCAL" }

    my $output_file = output( $restore, 2 );
    my $output_params = "1> $output_file.log 2> $output_file.err";

    my $restore_script = "$bin_dir/restore_DB.pl -user $user -host $host -dbase $dbase -from $from -force $time_arg $include_tables";

    my $command = "$restore_script $parameters $output_params";
    _execute( $command, $output_file );
    return 1;
}

##############
sub unistall_obsolete {
##############
    my $self    = shift;
    my $restore = shift;

    my ( $host, $dbase ) = split ':', $restore;
    my $output_file    = output($restore);
    my $output_params  = "1> $output_file.log 2> $output_file.err";
    my $upgrade_script = "$bin_dir/install.pl  -uninstall Obsolete  -host $host -dbase $dbase -user $user -skip_svn ";

    my $command = "$upgrade_script  $output_params";
    _execute( $command, $output_file );

}

##############
sub upgrade {
    ##############
    my $self    = shift;
    my $restore = shift;

    my ( $host, $dbase ) = split ':', $restore;

    my $dbc = new SDB::DBIO(
        -host        => $host,
        -dbase       => $dbase,
        -user        => $user,
        -no_triggers => 1,
        -connect     => 1
    );

    my $output_file           = output($restore);
    my $output_params         = "1> $output_file.log 2> $output_file.err";
    my $database_version      = _get_DBase_Version( -dbc => $dbc );
    my $output_params_version = "1> $output_file.$database_version.log 2> $output_file.$database_version.err";
    my $upgrade_script        = "$bin_dir/upgrade_DB.pl -user $user -v $restore -dbase $dbase -host $host -version $database_version ";
    my $command               = "$upgrade_script  $output_params_version";
    _execute( $command, $output_file );

    # my $upgrade_script = "$bin_dir/upgrade_DB.pl -u $user -b all -A all -S -f -v $restore";
    my $upgrade_script = "$bin_dir/upgrade_DB.pl -user $user -v $restore -dbase $dbase -host $host  ";
    my $command        = "$upgrade_script  $output_params";
    _execute( $command, $output_file );

    return 1;
}

##############
sub update {
    ##############
    my $self    = shift;
    my $restore = shift;
    my ( $host, $dbase ) = split ':', $restore;

    my $dbc = new SDB::DBIO(
        -host        => $host,
        -dbase       => $dbase,
        -user        => $user,
        -no_triggers => 1,
        -connect     => 1
    );

    my $output_file      = output($restore);
    my $output_params    = "1> $output_file.log 2> $output_file.err";
    my $database_version = _get_DBase_Version( -dbc => $dbc );
    my $upgrade_script   = "$bin_dir/upgrade_DB.pl -user $user -v $restore -dbase $dbase -host $host -version $database_version";
    my $command          = "$upgrade_script  $output_params";
    _execute( $command, $output_file );
    return 1;
}

##############
sub install_packages {
##############
    my $self    = shift;
    my $restore = shift;

    my ( $host, $dbase ) = split ':', $restore;
    my $custom        = _get_custom();
    my $output_file   = output($restore);
    my $output_params = "1>> $output_file.log 2>> $output_file.err";

    my @all_patches;
    my @filtered_pacthes;
    my $dbc = new SDB::DBIO(
        -host        => $host,
        -dbase       => $dbase,
        -user        => $user,
        -no_triggers => 1,
        -connect     => 1
    );
    my $install = new SDB::Installation( -dbc => $dbc, -simple => 1 );
    my $file = $install->get_Version_Tracker_Files( -debug => $debug, -custom => [$custom] );    #Version Tracker Files
    my @packages = _get_package_list();

    for my $package (@packages) {
        my $patches = $install->get_Package_Pacthes_from_version_tracker( -version => '2.6', -test => 1, -file => $file, -package => $package );

        # print Dumper $patches;
        push @all_patches, @$patches if $patches;
    }
    for my $pat (@all_patches) {
        if ( $pat =~ /(install_.+)\.pat/ ) { push @filtered_pacthes, $1 }
    }

    my $sorted = $install->sort_Patches_array( -files => $file, -test => 1, -packages => \@packages, -patches => \@filtered_pacthes );
    my @sorted = @$sorted if $sorted;

    main::try_system_command("rm -f $output_file.log");
    main::try_system_command("rm -f $output_file.err");

    for my $patch_name (@sorted) {
        my $install_script = "$bin_dir/install.pl -patch $patch_name.pat -user $user -dbase $dbase -host $host  -confirmed  -skip_svn";
        my $command        = "$install_script $output_params";
        _execute( $command, $output_file );
        if ( $patch_name =~ /install_(.+)\_?/ ) {
            my ($installed_package_name) = $dbc->Table_find( 'Package,Patch', 'Package_Name', "WHERE FK_Package__ID = Package_ID and Patch_Name = '$patch_name' " );
            my $result = $dbc->Table_update_array( -table => 'Package', -fields => [ 'Package_Install_Status', 'Package_Active' ], -values => [ 'Installed', 'y' ], -condition => "WHERE Package_Name = '$installed_package_name'", -autoquote => 1 );

        }
    }

    #
    return 1;
}

#################
sub compare_DB {
    #################
    my $self    = shift;
    my $restore = shift;

    my ( $host, $dbase ) = split ':', $restore;

    my $output_file   = output($restore);
    my $output_params = "1> $output_file.log 2> $output_file.err";

    my $compare_script = "$bin_dir/compare_DB.pl -from_release -patched -upgraded -dumps -user $user";

    my $command = "$compare_script -target $host:$dbase $output_params";
    return _execute( $command, $output_file );
}

##############
sub integrity_check {
##############
    my $self    = shift;
    my $restore = shift;

    my ( $host, $dbase ) = split ':',;
    my $output_file    = output( $restore, 2 );
    my $output_params  = "1> $output_file.log 2> $output_file.err";
    my $restore_script = "$bin_dir/install.pl -integrity $restore -skip_svn ";

    my $command = "$restore_script  $output_params";
    _execute( $command, $output_file );
    return 1;
}
##################################################
#
# Explicit Run modes
#
##################################################

########################
sub backup {
########################
    my $self   = shift;
    my $backup = shift;

    my ( $host, $dbase ) = split ':', $backup;

    my $output_file   = output($backup);
    my $output_params = "1> $output_file.log 2> $output_file.err";

    my $parameters;
    if ($slave)            { $parameters .= "-slave $slave " }
    if ($version)          { $parameters .= "-v $version " }
    if ($lock_master)      { $parameters .= "-lock_master " }
    if ($exclude_provider) { $parameters .= "-X $exclude_provider " }
    if ($no_record)        { $parameters .= "-no_record $no_record " }
    if ($routine)          { $parameters .= "-routine $routine " }

    my $backup_success = _execute( "$bin_dir/backup_RDB.pl -dump -host $host -dbase $dbase -user $user $parameters -confirm -time $time $include_tables $output_params", $output_file );

    return $backup_success;
}

########################
sub restore_structure {
########################
    my $self    = shift;
    my $restore = shift;
    my $parameters;
    if ($routine) { $parameters .= "-routine $routine " }

    my ( $host, $dbase ) = split ':', $restore;
    return $self->restore( $restore, "-structure $rebuild $parameters" );
}

###########################
sub restore_records {
###########################
    my $self    = shift;
    my $restore = shift;

    my ( $host, $dbase ) = split ':', $restore;

    return $self->restore( $restore, "$exclude_tables " );
}

##################################################
#
# Internal funtions
#
##################################################
###########################
sub _get_custom {
###########################
    if ($custom_opt) {
        return $custom_opt;
    }
    else {
        return "GSC";
    }
}

###########################
sub _get_package_list {
###########################
    my $plugins_list = $Config->{config}{Plugins};
    my $options_list = $Config->{config}{Options};
    my $custom_list  = $Config->{config}{custom};
    my @plugins      = split ',', $plugins_list;
    my @options      = split ',', $options_list;
    my @custom       = split ',', $custom_list;
    my @all_packages;
    push @all_packages, @plugins;

    # push @all_packages, @options;
    push @all_packages, @custom;
    return @all_packages;
}

###########################
sub _get_DBase_Version {
###########################
    # This should be fixed immidiately it's only temporary
    my %args = RGTools::RGIO::filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my $version;

    ($version) = $dbc->Table_find( -table => 'Version', -fields => 'Version_Name', -condition => "Where Version_Status = 'In use'" );
    return $version;
}
return 1;
