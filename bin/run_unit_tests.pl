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
my $location;

BEGIN {
    $location = $FindBin::RealBin;

    # must be assigned inside a BEGIN block so that the variable has a value before "use lib" is called
    # see: http://www.visionwebhosting.net/web-hosting-perl/WebHostingPerl-CPAN0045.htm for details
}

use RGTools::RGIO;
use RGTools::Process_Monitor;
use Test::TAP::Model;
use Getopt::Long;
use SDB::CustomSettings;
use SDB::DBIO;
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
use vars qw($opt_variation $opt_test $opt_no_selenium $opt_no_email $opt_testing);
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

GetOptions(
    'variation|v=s' => \$opt_variation,        # d
    'test=s'        => \$opt_test,
    'no_selenium=s' => \$opt_no_selenium,
    'no_email'      => \$opt_no_email,
    'testing=s'     => \$opt_testing,

);

my $variation  = $opt_variation;
my $test       = $opt_test;
my $email_flag = $opt_no_email;

print "$variation variation.  $test test no_selenium = $opt_no_selenium\n";

# Set up Process Monitor
my $Report = Process_Monitor->new(
    -quiet     => 0,
    -verbose   => 0,
    -no_email  => $email_flag,
    -variation => $variation,
    -testing   => $opt_testing,
    -configs   => $Config,
);

# Set the version of perl to use for the tests
$ENV{HARNESS_PERL} = "/usr/local/bin/perl";

print "running tests...\n";

$test ||= '*';

my @t_files   = glob("$location/../bin/t/*/*/$test.t");
my @t_files_2 = glob("$location/../bin/t/*/$test.t");
@t_files = ( @t_files, @t_files_2 );

#my @t_files =  _get_test_files(-loc => $location, -test => $test); #glob("$location/../bin/t/*/$test.t");
print "$t_files[-1] \n";

# if selenium = 0, don't include selenium.  if selenium = 1, run selenium only
#===============================
if ( $opt_no_selenium == 1 ) {

    my $index = 0;
    for my $t_file (@t_files) {

        if ( $t_file =~ /OS_S_Library.t/ ) {
            $t_files[$index] = $t_files[-1];
            pop @t_files;
            last;
        }
        $index++;
    }
}

#===============================

my $model = Test::TAP::Model->new_with_tests(@t_files);
print "get test files...\n";
my @test_files = $model->test_files();

my $num_failed_suites = 0;
my $num_died_suites   = 0;

foreach my $test_file (@test_files) {
    my $name = $test_file->name();
    print "** $name **\n";
    my $passed         = $test_file->ok() ? "passed" : "failed";
    my $num_ok         = scalar $test_file->ok_tests();
    my $num_nok        = scalar $test_file->nok_tests();
    my $num_todo       = scalar $test_file->todo_tests();
    my $num_skipped    = scalar $test_file->skipped_tests();
    my $num_unexpected = scalar $test_file->unexpectedly_succeeded_tests();
    my $percentage     = $test_file->percentage();
    my $todo_failed    = $num_todo - $num_unexpected;

    # log failed tests as errors
    my @nok_tests = $test_file->nok_tests();

    if ( $passed eq "failed" ) {
        if (@nok_tests) {
            foreach my $nok_test (@nok_tests) {
                my $test_num = $nok_test->num();
                my $line_num = $nok_test->line();

                my $error = "$name - test #$test_num, line $line_num failed";
                $Report->set_Error($error);
            }
        }
        else {
            my $error = "$name failed (died!)";
            $Report->set_Error($error);
            $num_died_suites++;
        }

        $num_failed_suites++;
    }

    # log passed tests as succeeded
    my @passed_tests = $test_file->ok_tests();

    foreach my $passed_test (@passed_tests) {
        $Report->succeeded();
    }

    if ($todo_failed) {

        # tests in todo blocks failed, log a warning
        my $warning = "$name : $todo_failed TODO tests failed";
        $Report->set_Message($warning);
    }

    if ($num_unexpected) {

        # tests in todo blocks passed unexpectedly - these should be taken out of TODO block if done.
        my $warning = "$name : $num_unexpected TODO tests passed unexpectedly (remove from TODO block)";
        $Report->set_Warning($warning);
    }

    my $file_summary = "$name - $passed - $num_ok ok, $num_nok not ok, " . "$num_todo TODO, $num_skipped skipped, $num_unexpected unexpectedly passed, $todo_failed TODOs failed, " . "$percentage\n";

    $Report->set_Detail($file_summary);

}

my $total_suites                 = scalar @test_files;
my $total_passed                 = $model->total_passed();
my $total_failed                 = $model->total_failed();
my $total_percentage             = $model->total_percentage();
my $total_skipped                = $model->total_skipped();
my $total_todo                   = $model->total_todo();
my $total_unexpectedly_succeeded = $model->total_unexpectedly_succeeded();

my $run_summary
    = "Summary\n========\n"
    . "$num_failed_suites out of $total_suites test suites failed ($num_died_suites out of $num_failed_suites failed test suites died).\n"
    . "\n$total_passed tests passed.  ($total_failed failed; $total_skipped skipped)\n"
    . "\n$total_todo TODO: $total_unexpectedly_succeeded unexpectedly succeeded\n"
    . "\n** $total_percentage **\n\n";

$Report->set_Message($run_summary);

print "Finished!\n";

$Report->completed();

exit;

############################
sub _get_test_files {
############################
    my %args     = filter_input( \@_ );
    my $location = $args{-loc};
    my $test     = $args{-test};
    my @t_files;
    my $dbase    = $Configs{DATABASE};
    my $host     = $Configs{SQL_HOST};
    my $user     = 'viewer';
    my $dbc      = SDB::DBIO->new( -dbase => $dbase, -user => $user, -host => $host, -connect => 1 );
    my @packages = $dbc->Table_find( 'Package', 'Package_Name', " WHERE Package_Active = 'y'  and Package_Install_Status = 'Installed'" );
    my @dirs     = ( 'alDente', 'SDB', 'RGTools', 'LIMS_Admin', 'Selenium_Functional_Test', 'Mapping', 'Lib_Construction' );
    push @dirs, @packages;

    my @tests = &Cast_List( -list => $test, -to => 'array' );

    for my $dir (@dirs) {
        for my $unit_test (@tests) {
            my @files = glob("$location/../bin/t/$dir/$unit_test.t");
            for my $file (@files) {
                push @t_files, $file if -e $file;
            }
        }
    }

    return @t_files;
}

