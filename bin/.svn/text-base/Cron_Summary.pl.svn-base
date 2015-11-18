#!/usr/local/bin/perl
########################################
## Standard Initialization of Module ###
########################################
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/LampLite";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

########################
## Local Core modules ##
########################
use CGI;
use Data::Dumper;
use Benchmark;

use strict;
##########################
## Local custom modules ##
##########################
use RGTools::RGIO;
use LampLite::Bootstrap;

use SDB::DBIO;         ## use to connect to database
use SDB::DB_Access;    ## use to retrieve login access passwords
use SDB::HTML;         ## use for web interface output (only needed for cgi-bin files)

use alDente::Config;   ## use to initialize configuration settings

### Modules used for Web Interface only ###
use alDente::Session;
use LampLite::MVC;

use DBI;
use RGTools::Views;
use RGTools::Process_Monitor::Manager;
use SDB::CustomSettings;
##############################
# global_vars                #
##############################
my $q               = new CGI;
my $BS              = new Bootstrap();
my $start_benchmark = new Benchmark();

$| = 1;
##############################################################
## Temporary - phase out globals gradually as defined below ##
##############################################################
use vars qw(%Configs);        ## replace with $dbc->config() ... need to also expand config list as done in SDB/Custom_Settings currently...
use vars qw($homelink);       ## replace with $dbc->homelink()
use vars qw(%Search_Item);    ## replace with $dbc->homelink()
use vars qw($Connection);
use vars qw(%Field_Info);
use vars qw($scanner_mode);
use vars qw($opt_help $opt_quiet $opt_script $opt_sort $opt_offset $opt_debug $opt_version $opt_variation $opt_out_file $opt_copy_dir);
###############################################################

####################################################################################################
###  Configuration Loading - use this block (and section above) for both bin and cgi-bin files   ###
####################################################################################################
my $Config = new alDente::Config( -initialize => 1, -root => $FindBin::RealBin . '/..' );

my ( $home, $version, $domain, $custom, $path, $dbase, $host, $login_type, $session_dir, $init_errors, $url_params, $session_params, $brand_image, $screen_mode, $configs, $custom_login, $css_files, $js_files, $init_errors ) = (
    $Config->{home},       $Config->{version},      $Config->{domain},      $Config->{custom},     $Config->{path},           $Config->{dbase}, $Config->{host},
    $Config->{login_type}, $Config->{session_dir},  $Config->{init_errors}, $Config->{url_params}, $Config->{session_params}, $Config->{icon},  $Config->{screen_mode},
    $Config->{configs},    $Config->{custom_login}, $Config->{css_files},   $Config->{js_files},   $Config->{init_errors}
);

%Configs = $configs;
SDB::CustomSettings::load_config($configs);    ## temporary ...

use Getopt::Long;
&GetOptions(
    'help'        => \$opt_help,
    'quiet'       => \$opt_quiet,
    'script=s'    => \$opt_script,
    'sort'        => \$opt_sort,
    'offset=s'    => \$opt_offset,
    'debug'       => \$opt_debug,
    'version=s'   => \$opt_version,            # indicate the version
    'variation=s' => \$opt_variation,
    'out_file=s'  => \$opt_out_file,
    'copy_dir=s'  => \$opt_copy_dir,
);

my $help      = $opt_help;
my $quiet     = $opt_quiet;
my $script    = $opt_script;                         ## just run it for one (or more) indicated scripts...
my $sort      = defined $opt_sort ? $opt_sort : 1;
my $debug     = $opt_debug;
my $offset    = $opt_offset || '-1d';                ## default by looking at yesterday
my $version   = $opt_version;
my $variation = $opt_variation;
my $out_file  = $opt_out_file;
my $copy_dir  = $opt_copy_dir;

my $master_host = $Configs{PRODUCTION_HOST};
my $slave_host  = $Configs{BACKUP_HOST};
my $dev_host    = $Configs{DEV_HOST};
my $master_db   = $Configs{PRODUCTION_DATABASE};
my $slave_db    = $Configs{BACKUP_DATABASE};
my $dev_db      = $Configs{DEV_DATABASE};

my %scripts;
my %schedule;

if ( $variation =~ /\*/ ) {

    #find all scripts that have the variation
    my $manager = new Process_Monitor::Manager( -offset => $offset, -cron_list => \%scripts, -configs => $Config );
    my @logs = glob("$manager->{cron_dir}/$variation.log");
    for my $log (@logs) {
        my $file;
        if ( $log =~ /.*\/(.*).log/ ) { $file = $1 }
        my ( $script, $variation ) = split( /\./, $file );
        push @{ $scripts{$script} }, $variation;
    }
}
elsif ($script) {
    ## override default list if specified..
    my @specified_scripts    = &Cast_List( -list => $script,    -to => 'array' );
    my @specified_variations = &Cast_List( -list => $variation, -to => 'array' );
    for ( my $i = 0; $i <= $#specified_scripts; $i++ ) {
        my $value = 1;
        if ($variation) { $value = $specified_variations[$i] }
        $scripts{ $specified_scripts[$i] } = $value;
    }
}
elsif ( $version =~ /bcg/ ) {
    %scripts = (
        DB_backup_restore => [ 'bcg_test', 'bcg_dev', 'bcg_beta' ],
        #compare_DB        => 1,
        backup_RDB        => 1,
        check_replication => 1,
        #sys_monitor => [ 'main', 'dir', ],
        DBIntegrity         => 1,
        Restore_DB          => 1,
        DB_monitor          => 1,
        cleanup_DB          => ['date'],
        cleanup             => ['hblims05'],
        cleanup_web         => 1,
        performance_monitor => 1,
        upgrade_DB          => [ 'hblims05:bcg_beta' ],  ## 'hblims04:bcg_dev', 
        DBIntegrity         => 1,    #check why logs are missing
        update_from_SVN     => 0, ## ['hblims01:beta']
    );
}
elsif ( $version =~ /validation/ ) {
    %scripts = ( run_unit_tests => [ 'beta_no_selenium', 'beta_selenium_only', 'production_no_selenium', 'production_selenium_only' ] );
}
else {
    %scripts = (
        DB_backup_restore => [ 'seqtest', 'dev_test', 'beta_test' ],

        #compare_DB        => [ 'seqdev_GSC_beta', 'seqtest_GSC' ],
        update_sequence      => 1,
        import_gel_images    => 1,
        backup_RDB           => [ 'hourly_backup', 'clone_sequence_backup' ],
        check_replication    => [ 'regular_check', 'full_check' ],
        cleanup_DB           => [ 'throwaway', 'expire' ],
        cleanup_web          => 1,
        cleanup_redundancies => 1,
        DB_monitor           => [ 'space', 'records' ],
        sys_monitor          => [ 'main' ],
        update_Stats         => 1,
        DBIntegrity          => 1,
        cat_vectors          => 1,
        Notification         => 1,
        cleanup_mirror       => 1,
        Restore_DB           => 1,
        cleanup              => [ $master_host, $slave_host ],
         set_Library_Status   => [ 'basic', 'full' ],
        performance_monitor  => 1,
        import_ncbi_taxonomy => 1,

        #update_library_list     => 1,
        check_sequenced_wells   => 1,
        bulk_email_notification => 1,
        upgrade_DB              => [
            'limsdev04:seqdev',
            'lims07:seqbeta',

            #            'limsdev02:Core',
            #            'limsdev02:GSC_beta',
            #            'limsdev02:GSC'
        ],
        install => [
            'Integrity_lims05:seqtest',
            'Integrity_limsdev04:seqdev',
            'Integrity_lims07:seqbeta',

            #            'Integrity_limsdev02:Core_beta',
            #            'Integrity_limsdev02:Core',
            #            'Integrity_limsdev02:GSC_beta',
            #            'Integrity_limsdev02:GSC'
        ],
        API_unit_test  => [ 'case_generation',  'alDente_API',        'Sequencing_API',         'Mapping_API', 'Solexa_API', ],
        run_unit_tests => [ 'beta_no_selenium', 'beta_selenium_only', 'production_no_selenium', 'production_selenium_only' ],
        DBIntegrity => [ '', 'enum_check', 'index_check', 'qty_units_check', 'fk_check', 'custom_error_check', 'attribute_check', 'object_attribute_check' ],    #check why logs are missing
        update_slx_run_status => 1,

        #        solexa_analysis_automation  => 1, # deactivated on Apr 28, 2010
        copy_QC_template            => 1,
        microarray_batch_submission => 1,
        update_genechiprun          => 1,

        #    check_slx_machine_status => 1,  #inactive right now
        Report_generator      => 1,
        solexa_post_analysis  => ['solexa_cleanup_integrity'],                                                                                                   ##'solexa_cleanup',
        seqmirror             => 1,
        schedule_cluster_jobs => 1,
    );
    %schedule = (
        'import_ncbi_taxonomy'             => ['6'],
        'check_replication.full_check'     => ['7'],
        'install.Integrity_lims05:seqtest' => [ '1', '2', '3', '4', '5', '6' ],
        'install.Integrity_lims07:seqbeta' => ['1'],
        'install.Integrity_limsdev04:seqdev' => [ '2', '3', '4', '5', '6' ],
        'upgrade_DB.lims07:seqbeta'          => ['1'],
        'upgrade_DB.limsdev04:seqdev'        => [ '2', '3', '4', '5', '6' ],
        'DB_backup_restore.seqtest'   => [ '1', '2', '3', '4', '5', '6' ],
        'DB_backup_restore.dev_test'  => [ '2', '3', '4', '5', '6' ],
        'DB_backup_restore.beta_test' => ['1'],
        'cleanup_DB.throwaway' => [ '1', '2', '3', '4', '5' ],
        'cleanup_DB.expire'    => [ '1', '2', '3', '4', '5' ],
    );

}

my $self = new Process_Monitor::Manager(
    -cron_list => \%scripts,
    -schedule  => \%schedule,
    -notify    => ['aldente@bcgsc.ca'],
    -include   => 1,
    -offset    => $offset,
    -configs   => $Config,
);

$self->generate_reports($debug);

my $file = "$Configs{URL_temp_dir}/Cron_Summary." . timestamp() . ".html";
if ($out_file) { $file = $out_file }
$self->send_summary( $file, $copy_dir ) unless ( $debug || $quiet );

print "Done..\n";
exit;

#############
sub help {
#############

    print <<HELP;

Usage:
*********

    <script> [options]

Mandatory Input:
**************************

Options:
**************************     


Examples:
***********

HELP

}
