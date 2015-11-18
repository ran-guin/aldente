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

use MIME::Base32;
use YAML;
use JSON;
use Getopt::Long;
use File::Path;

### LIMS Modules
use RGTools::RGIO qw( filter_input compare_data timestamp Call_Stack today date_time Safe_Freeze try_system_command);
use SDB::CustomSettings;
use SDB::HTML qw( create_tree HTML_Dump );
use RGTools::HTML_Table;
use RGTools::Process_Monitor;

use Test::Simple qw(no_plan);
use Test::More;
use Test::Differences;
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
use vars qw($Report);
use vars qw(%Configs);        ## replace with $dbc->config() ... need to also expand config list as done in SDB/Custom_Settings currently...
use vars qw($homelink);       ## replace with $dbc->homelink()
use vars qw(%Search_Item);    ## replace with $dbc->homelink()
use vars qw($Connection);
use vars qw(%Field_Info);
use vars qw($scanner_mode);
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

### API test file connection setting
my $LIMS_user_default     = "Guest";
my $LIMS_password_default = "pwd";
my $DB_user_default       = "viewer";
my $DB_password_default   = "viewer";
my $debug_default         = 0;

#### Specifying global Maximums ####
my $MAX_TESTS_PER_CASE = 5;
my $MAX_TEST_CASES     = 5000;
my $MAX_DAYS_LOOKUP    = 30 * 6;               ## 6 months

my @TEST_MODULE_FILES = qw(
    alDente/alDente_API.pm
    Lib_Construction/Microarray_API.pm
    Mapping/Mapping_API.pm
    Sequencing/Sequencing_API.pm
    Illumina/Solexa_API.pm
    Vectorology/Vectorology_API.pm
);

#Submission/Template_API.pm

my @TEST_MODULES;
foreach my $module (@TEST_MODULE_FILES) {
    my $mod = $module;
    if ( $mod =~ /alDente/ ) {
        $mod =~ s/\//::/;
    }
    else {
        $mod =~ s/.*\///;
    }
    $mod =~ s/\.pm$//;
    push @TEST_MODULES, $mod;
}

### library paths
#my $prod_lib_path          = "/home/sequence/alDente/WebVersions/Production/lib/perl/";
#my $beta_lib_path          = "/home/sequence/alDente/WebVersions/Beta/lib/perl/";
my $prod_lib_path = "/home/aldente/WebVersions/production/bin";
my $beta_lib_path = $FindBin::RealBin;                            #"/home/sequence/alDente/WebVersions/Beta/bin";

# File directories - Constants
my $TEST_CASE_DIR = $Configs{Home_public} . '/API_test_cases';
my $LOG_DIR       = $Configs{Home_public} . '/logs/API_logs';

# Default command line argument values
my $date                = '';
my $date_offset         = '';
my $all_methods         = "";
my @methods             = undef;
my $date_test           = '';
my @test_numbers        = undef;
my $generate_test_cases = "";
my $run_test_cases      = "";
my $help_requested      = "";
my $test_type           = "";
my $variation;
my $max_days;

# option         # variable               # shortcut
GetOptions(
    'date|d=s'      => \$date,                   # d
    'offset|o=s'    => \$date_offset,            # o
    'all|a'         => \$all_methods,            # a
    'methods|m=s'   => \@methods,                # m
    'numbers|n=s'   => \@test_numbers,           # n
    'generate|g'    => \$generate_test_cases,    # g
    'run|r'         => \$run_test_cases,         # r
    'help|h|?'      => \$help_requested,         # h,?
    'type|t=s'      => \$test_type,              # t
    'variation|v=s' => \$variation,
    'max_days|x=s'  => \$max_days,

);

if ($max_days) { $MAX_DAYS_LOOKUP = $max_days; }

@methods      = split q{,}, $methods[1];         # list of comma separated methods is stored in second array position.
@test_numbers = split q{,}, $test_numbers[1];    # list of comma separated methods is stored in second array position.
if ($date) { $date_test = $date; }

## Display help
if ($help_requested) {

    display_help();

    exit;
}

# Set up Process Monitor
$Report = Process_Monitor->new( -offset => '-0h', -configs => $Config );

if ( $date and $date_offset ) {
    my $error = "You can only specify either 'date' or 'offset' at one time";
    $Report->set_Error($error);
    $Report->DESTROY();
    die $error;
}
elsif ($date_offset) {
    $date = &today("-$date_offset");
}
elsif ( !$date ) {
    $date = &today();
}

## Error checking
if ( $generate_test_cases && $run_test_cases ) {
    my $error = "Error: Can't generate and run test cases at same time\n";
    $Report->set_Error($error);
    $Report->DESTROY();
    die $error;
}

if ( $generate_test_cases && ( $all_methods || @methods || $test_type ) ) {
    my $error = "Error: Can't specify methods or types when generating test cases\n";
    $Report->set_Error($error);
    $Report->DESTROY();
    die $error;
}

## Assumptions
if ( !$generate_test_cases && !$run_test_cases ) { $run_test_cases = 1; }
if ( !@methods             && !$all_methods )    { $all_methods    = 1; }

## Error checking (dependant on changes made in assumptions section above)
if ( !$test_type && $run_test_cases ) {
    my $error = "Error: Please specify test type [" . join( ', ', @TEST_MODULES ) . "]\n";
    $Report->set_Error($error);
    $Report->DESTROY();
    die $error;
}

## Perform main action
if ($generate_test_cases) {
    $variation ||= 'case_generation';
    $Report->set_variation($variation);
    $Report->set_Message("Generating test cases based on $date logs");
    my $cases = generate_test_cases( -date => $date );
    $Report->completed();
    $Report->DESTROY();

    $cases ||= 0;

    if ($cases) {
        ### This forces an exit value of SUCCESS
        ok( 1, "Generated $cases test cases" );
    }
    else {
        ### else the script exits with a value of FAIL
    }
}
elsif ($run_test_cases) {

    $Report->set_Message("Running test cases");

    # select appropriate test case directory
    my $test_case_subdir = $test_type;

    if ( !grep( /$test_type$/, @TEST_MODULES ) ) {
        my $error = "Error: type '$test_type' is an invalid type.\n";
        $Report->set_Error($error);
        $Report->DESTROY();
        die $error;
    }

    # get available methods for each type of test case
    my $TEST_CASE_TYPES;
    opendir $TEST_CASE_TYPES, "$TEST_CASE_DIR/$test_case_subdir" or die( "$!\n", $Report->set_Error("Cannot open directory $TEST_CASE_DIR/$test_case_subdir"), $Report->DESTROY() );

    # read all but '.' and '..'
    my @test_case_types = grep /[^.]/, readdir $TEST_CASE_TYPES;    ## Assumption: contains only directories.

    closedir $TEST_CASE_TYPES or die( "$!\n", $Report->set_Error("Cannot close directory $TEST_CASE_DIR/$test_case_subdir"), $Report->DESTROY() );

    if ($all_methods) {
        @methods = @test_case_types;
    }

    $variation ||= $test_type;
    $Report->set_variation($variation);

    run_test_cases( -type_subdir => $test_case_subdir, -methods => \@methods );
    $Report->completed();
    $Report->DESTROY();
}
else {
    my $error = "Error: neither run nor generate were selected.  This should never happen!\n";
    $Report->set_Error($error);
    $Report->DESTROY();
    die $error;
}

exit;

# --------------------------------------------------------------------
# Function:     display_help
#
# Description:  Display help text
# --------------------------------------------------------------------
sub display_help {

    print <<HELP;

Syntax
======
API_unit_test.pl [ -rgah -d 2007-01-11 -t alDente_API -m get_run_data ]

Flags
=====
-date, -d      : specify date for test cases in yyyy-mm-dd format
-all, -a       : run all methods
-methods, -m   : run selected methods (ie: -m get_Plate_data,get_run_data)
-generate, -g  : generate tests
-run, -r       : run tests.  Requires -t
-help, -h, -?  : displays this help
-type, -t      : type of tests to run (ie: -t aldente)
                 Example: 'alDente_API' or 'Sequencing_API'.  Required for -r

Default Behaviours
==================

If the no date is provided, the current date will be used.

If no methods are specified, all methods will be run

If neither -r or -g are selected, -r is the default.

Example
=======
API_unit_test.pl -t Sequencing_API -v Sequencing_API -m get_primer_data,get_Run_data :
This runs the Sequencing_API test, with process monitor variation Sequencing_API
and only test get_primer_data and get_Run_data

API_unit_test.pl -t Sequencing_API -v Sequencing_API -m get_primer_data -d 2009-02-24 -n 1,2 :
This runs test case number 1,2 of get_primer_data in 2009-02-24.case for Sequencing_API
Note that the case should be generated with the new format

API_unit_test.pl -t aldente  : this will run all methods for the current
                               date in the aldente test cases

API_unit_test.pl -g -d 2006-12-22 : this will generate test cases from the
                                    API logs for Dec. 22nd, 2006


Generating Test Cases
=====================

Test cases will be generated for all methods on the date specified.  If no
date is specified, the script will use the current date.  No other flags can
be used.

Running Test Cases
==================

There are several options when running test cases.

You may select the date, the type (aldente, sequencing or mapping), and all or a
selection of methods.

Only type is required.  If you do not provide a date, the current date will
be used.  If you do not provide a method, all methods will be used.

HELP

}

# --------------------------------------------------------------------
# Function:     build_test_suite
#
# Description:  Create a list of test cases to be run
# --------------------------------------------------------------------
#
# Input options:
#
#    # of tests per method
#    date at which tests are extracted from log files
#
#############################
sub generate_test_cases {
#############################
    my %args                 = @_;
    my $max_tests_per_method = $args{-max_tests_per_method};    # for future use
    my $date                 = $args{-date} || &today();

    $date =~ s/-/\//g;
    my $logfiles_directory = $LOG_DIR . '/' . $date;

    ## read in the test cases
    if ( !-e $logfiles_directory ) {
        $Report->set_Warning("$logfiles_directory does not exist");
        return;                                                 # no test cases to process
    }

    $Report->set_Message("Extract test cases from $logfiles_directory");

    $date =~ s/\//-/gxms;
    my $output_file = "$date.case";

    my $found = &_build_test_case_files( -dir => $logfiles_directory, -output_file => $output_file );
    $Report->set_Message("Generated $found test cases");
}

# --------------------------------------------------------------------
# Function:     _parse_test_case
#
# Description:  Get the input arguments used in an API call based on
#               the test case file
# --------------------------------------------------------------------
##################################
sub _build_test_case_files {
##################################
    my %args         = filter_input( \@_, -args => 'dir', -mandatory => 'dir' );
    my $logfiles_dir = $args{-dir};                                                ## base directory (mandatory)
    my $log_files    = $args{-files};                                              ## optional - defaults to all subdirectories
    my $output_file  = $args{-output_file};                                        ## date of API call

    my $recordCount = 0;

    ## get logged case directories ##
    if ( !$log_files ) {
        my $LOGFILES_DIR;
        opendir $LOGFILES_DIR, $logfiles_dir or die( "can't open $logfiles_dir: $!", $Report->set_Error("Can't open $logfiles_dir"), $Report->DESTROY() );

        my @log_dirs = grep /[^.]/, readdir $LOGFILES_DIR;
        @{$log_files} = @log_dirs;                                                 ## all applicable directories

        closedir $LOGFILES_DIR or die( "can't close $logfiles_dir: $!\n", $Report->set_Error("Can't close $logfiles_dir"), $Report->DESTROY() );

    }

    ## Extract data from each record
    $Report->start_sub_Section("Parse logs");
    my ( $new, $unique ) = _parse_logs( $logfiles_dir, $log_files );
    $Report->end_sub_Section("Parse logs");

    my %new_cases    = %$new;                                                      ## JSON arguments list
    my %unique_cases = %$unique;                                                   ## Hash with keys as the concat'ed list of arguments, and values as the number of cases with those arguments

    my $count = 0;
    if (%new_cases) {
        foreach my $module ( keys %new_cases ) {
            $count += _write_test_case( $new_cases{$module}, $unique_cases{$module}, $module, $output_file );
        }
    }

    return $count;
}

#############################
sub _get_API_calls {
#############################
    my $logfile_dir = shift;
    my $file        = shift;

    $Report->start_Section("Get Test cases for $file");

    ### Read in the logfile
    open( LOGFILE, "$logfile_dir/$file" ) or die( "Cannot open file $file: $!\n", $Report->set_Error("Cannot open file $file"), $Report->DESTROY() );

    my $emptyLineCount = 0;

    my @logRecords;
    my $recordCount = 0;

    while (<LOGFILE>) {
        my $currentLine = $_;

        # check if the current line is empty
        if ( $currentLine =~ /^$/ ) { $emptyLineCount++; }

        # check if there have been two empty rows in a row, if so, it's a new record, so increment the recordCount
        if ( $emptyLineCount > 1 or $currentLine =~ /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/ ) {
            if ($recordCount) { $logRecords[ $recordCount - 1 ] .= "---FROM_LOG_FILE---$logfile_dir/$file"; }
            $recordCount++;
            $emptyLineCount = 0;
        }
        elsif ( !$recordCount ) {next}    ## have not found first record yet...

        $logRecords[ $recordCount - 1 ] .= $currentLine;
    }

    close LOGFILE or die( "Can't close file: $!", $Report->set_Error("Can't close file $file"), $Report->DESTROY() );

    $Report->set_Message("Found $recordCount tests in $file");
    $Report->end_Section("Get Test cases for $file");

    return @logRecords;
}

##########################
sub _parse_logs {
##########################
    my $logfile_dir = shift;
    my $logfiles    = shift;

    my @logRecords;
    foreach my $file ( @{$logfiles} ) {
        if ( $file eq 'API_usage.viewer.aldente.log' ) {
            $Report->set_Message("Skipping $logfile_dir/$file");
            next;
        }
        push @logRecords, _get_API_calls( $logfile_dir, $file );
    }

    ## Extract data from each record
    my $count = 0;    ## Number of test cases
    my $index = 0;

    my %new_cases;
    my %unique_cases;
    foreach my $record (@logRecords) {
        my $logfile;
        ( $record, $logfile ) = split( "---FROM_LOG_FILE---", $record );

        # match method & modules
        my @methodStack;
        my @moduleStack;
        my $test_modules_regex = join( '|', @TEST_MODULES );    ### Sequencing|alDente|Mapping
        while ( $record =~ /^\d+ \=\> \'.*($test_modules_regex)::(\w+)\(\)\'.+$/gm ) {
            push @moduleStack, $1;
            push @methodStack, $2;
        }

        # get the last method and module from the stacks
        my $numMethods = scalar(@methodStack) - 1;
        my $method     = $methodStack[$numMethods];
        my $module     = $moduleStack[$numMethods];

        ### Skip non-get methods
        if ( $method !~ /^get_/ or $method =~ /\=\> bless\(\s\{/ ) {next}

        # match json line
        my $json_line = '';
        my $output;

        if ( $record =~ /MD5_Output:\t(\w+)/xms ) { $output    = $1 }
        if ( $record =~ /json: ({.+})/ixms )      { $json_line = $1 }

        my $arguments;
        if ( !$json_line && $record =~ /VAR1\s+=\s+{\s*(.*)};/xms ) {
            $record =~ /VAR1\s+=\s+{\s*(.*?)};/xms;
            my $match = $1;
            $arguments = eval 'my $var = {' . $match . '};';
        }
        else {
            ### No valuable arguments found in this record
            next;
        }

        if ( $json_line && !$arguments ) {
            $arguments = jsonToObj($json_line);
        }

        #elsif (!$json_line && $arguments) {
        #    $json_line = objToJson ($arguments);
        #}
        delete $arguments->{-dbc};
        delete $arguments->{-log_call};
        delete $arguments->{-quiet};

        my %struct;
        $struct{args}       = $arguments;
        $struct{MD5_output} = $output;

        $json_line = objToJson( \%struct );

        my $args = join( ',', sort( keys %{$arguments} ) );

        if ( $unique_cases{$module}{$method}{$args} < $MAX_TESTS_PER_CASE and $new_cases{$module}{$method} !~ /\Q$json_line\E/xms ) {
            $unique_cases{$module}{$method}{$args}++;
            my $test_number = split( /\n/, $new_cases{$module}{$method} ) + 1;
            $new_cases{$module}{$method} .= "$test_number\t$json_line\t$logfile\n";
            $Report->succeeded();
            $count++;
        }

        if ( $count == $MAX_TEST_CASES ) {
            last;
        }
        $index++;
    }
    $Report->set_Message("Parsed $count unique cases");
    return ( \%new_cases, \%unique_cases );
}

#########################
sub _write_test_case {
#########################
    my $new_case_ref    = shift;
    my $unique_case_ref = shift;
    my $module          = shift;
    my $test_case_file  = shift;

    my %new_case    = %$new_case_ref;       ## new case for this module
    my %unique_case = %$unique_case_ref;    ## new case for this module

    $Report->start_Section("New $module cases");
    my $count = 0;
    foreach my $method ( keys %new_case ) {
        my $variations = int keys %{ $unique_case{$method} };
        map { $count += $unique_case{$method}{$_} } keys %{ $unique_case{$method} };

        $Report->set_Detail("\t$module::$method (Total: $count, Variations: $variations)\n");

        # open appropriate test suite file
        # naming scheme: /module/method/YYYY-MM-DD.case
        my $test_case_dir = "$TEST_CASE_DIR/$module/$method";

        # if the directory doesn't exist, create it
        if ( !-d $test_case_dir ) {
            mkpath($test_case_dir) or die( "Cannot create directory $test_case_dir: $!\n", $Report->set_Error("Cannot create directory $test_case_dir"), $Report->DESTROY() );
            chmod 0777, $test_case_dir;
        }

        # open for appending
        my $TS;
        open( $TS, ">", "$test_case_dir/$test_case_file" ) or die( "Cannot open $test_case_file: $!\n", $Report->set_Error("Cannot open $test_case_file"), $Report->DESTROY() );

        print $TS $new_case{$method};

        #$count++;

        close $TS or die( "Can't close $test_case_dir/$test_case_file: $!\n", $Report->set_Error("Can't close $test_case_dir/$test_case_file"), $Report->DESTROY() );

        $Report->set_Detail("wrote to $test_case_dir/$test_case_file");
    }
    $Report->end_Section("New $module cases");

    return $count;
}

# --------------------------------------------------------------------
# Function:     run_test_cases
#
# Description:
# --------------------------------------------------------------------
########################
sub run_test_cases {
########################
    my %args    = @_;
    my $type    = $args{-type_subdir};
    my @methods = @{ $args{-methods} };

    ## test: find library path
    #my $ok = grep '/opt/alDente/versions/production/lib/perl', @INC;                    # TODO: remove all references to production
    #ok( $ok, "Found the library path" );

    # test: use API
    my %connection;
    $connection{-DB_user}     = $DB_user_default;
    $connection{-DB_password} = $DB_password_default;
    $connection{ -connect }   = 1;

    my %Production_connection = %connection;
    $Production_connection{-dbase} = $Configs{TEST_DATABASE};
    $Production_connection{-host}  = $Configs{TEST_HOST};

    my %Beta_connection = %connection;
    $Beta_connection{-dbase} = $Configs{TEST_DATABASE};
    $Beta_connection{-host}  = $Configs{TEST_HOST};

    ## test: use production library path
    #my $prod_lib      = grep $prod_lib_path, @INC;
    #
    #ok( $prod_lib, "Using Production Library Path" );
    #
    ## test: switch to beta library path
    #change_library_path( -library_path => "$beta_lib_path", -remove_path => "$prod_lib_path" );
    #my $beta_lib = grep $beta_lib_path, @INC;
    #ok( $beta_lib, "Switched to Beta Library Path" );
    #ok( require_module( -module => \@TEST_MODULES ), "Required beta modules" );
    #
    ## test: require production modules
    #change_library_path( -library_path => "$prod_lib_path", -remove_path => "$beta_lib_path" );
    #ok( require_module( -module => \@TEST_MODULES ), "Required prod modules" );

    # test: compare production and beta results
    my $summary = "Test Summary\n" . "=" x 40 . "\n";
    foreach my $method (@methods) {
        if ( &not_hotfix( -type => $type, -method => $method ) ) { $Report->set_Message("Skipping $type:$method because it hasn't been hotfix yet"); next; }
        my %unique_cases;
        my %unique_case_index;
        my $total_execution_time;
        my $pre_execution_time;

        my $num_tests = 0;
        my $failed    = 0;

        for my $days_ago ( 1 .. $MAX_DAYS_LOOKUP ) {
            my $date = &today("-$days_ago");

            #filter by input date for testing
            if ( $date_test && $date ne $date_test ) { next; }

            my $file = "$TEST_CASE_DIR/$type/$method/$date.case";

            #my @test_cases =  extract_test_cases( -file => $file );
            my %test_cases = extract_test_cases( -file => $file );
            if ( !$test_cases{test_case} ) { next; }
            if ( @{ $test_cases{test_case} } ) {
                print "Looking at $file ($days_ago days ago)\n";
            }
            my $index = -1;
            foreach my $test_case ( @{ $test_cases{test_case} } ) {
                $index++;

                #filter by input test number for testing
                if (@test_numbers) {
                    my %hash = map { $_ => 1; } grep {$_} @test_numbers;
                    if ( !$hash{ $test_cases{test_number}->[$index] } ) { next; }
                }

                if ( $test_case->{args} ) {
                    my $args = $test_case->{args};
                    my $variations = join( ',', sort( keys %{$args} ) );
                    if ( !$unique_cases{$variations} ) {
                        $unique_case_index{$variations} = int( keys %unique_case_index );
                    }

                    my $passed_test = 0;
                    if ( $unique_cases{$variations} < $MAX_TESTS_PER_CASE ) {
                        $unique_cases{$variations}++;

                        $Benchmark{Start} = new Benchmark;    # initialize benchmark before loading modules

                        my ( $beta_data, $beta_command, $beta_output ) = run_api( -api_type => $type, -method => $method, -api_version => 'beta',       -input => $args, -connection_info => \%Beta_connection );
                        my ( $prod_data, $prod_command, $prod_output ) = run_api( -api_type => $type, -method => $method, -api_version => 'production', -input => $args, -connection_info => \%Production_connection );
                        $Benchmark{End} = new Benchmark;      # initialize benchmark before loading modules
                        my $execution_time = timestr( timediff( $Benchmark{End}, $Benchmark{Start} ) );
                        $execution_time =~ /(\d+\.\d+) CPU/;
                        $execution_time = $1;
                        $total_execution_time += $execution_time;

                        #$passed_test = is_deeply( $prod_data, $beta_data, "Prod & Beta matched ($method $unique_case_index{$variations}-$unique_cases{$variations}\t[$execution_time Seconds] )" );
                        my @comments;
                        $passed_test = compare_data( 1 => $prod_data, 2 => $beta_data, -comment => \@comments, -no_sort => 1 );

                        my $dump_args = Dumper $args;

                        #my $md5_output = $test_case->{MD5_output};
                        #if (defined $md5_output) {
                        #    use Digest::MD5  qw(md5_hex);
                        #    my $beta_md5 = md5_hex(objToJson($beta_data));
                        #    print Dumper($beta_data,$beta_md5,$md5_output) if ($beta_md5 eq $md5_output);
                        #    #$passed_test = is($beta_md5, $test_case->{MD5_output}, "Production and MD5 matched");
                        #}

                        $num_tests++;
                        if ($passed_test) {
                            $Report->succeeded();
                        }
                        else {
                            $prod_command .= " -d";
                            $beta_command .= " -d";
                            my $limit        = 10;
                            my $count        = 1;
                            my $splice_index = 0;

                            if ( $comments[0]->[0] =~ /index (\d+):/ ) { $splice_index = $1; }
                            for ( my $i = 1; $i < @{ $comments[0] }; $i++ ) {
                                if ( ref $comments[0]->[$i] eq 'ARRAY' ) { splice( @{ $comments[0]->[$i] }, 0, $splice_index ); splice( @{ $comments[0]->[$i] }, $limit ); }
                            }
                            my $comment = Dumper @comments;

                            if ( ref $prod_data eq 'HASH' ) {
                                for my $key ( keys %{$prod_data} ) {
                                    if ( $count >= $limit ) { delete $prod_data->{$key} }
                                    else {
                                        if ( ref $prod_data->{$key} eq 'ARRAY' ) { splice( @{ $prod_data->{$key} }, 0, $splice_index ); splice( @{ $prod_data->{$key} }, $limit ); }
                                        $count++;
                                    }
                                }
                            }
                            $count = 1;
                            if ( ref $beta_data eq 'HASH' ) {
                                for my $key ( keys %{$beta_data} ) {
                                    if ( $count >= $limit ) { delete $beta_data->{$key} }
                                    else {
                                        if ( ref $beta_data->{$key} eq 'ARRAY' ) { splice( @{ $beta_data->{$key} }, 0, $splice_index ); splice( @{ $beta_data->{$key} }, $limit ); }
                                        $count++;
                                    }
                                }
                            }

#my $prod_size = keys %{$prod_data};
#my $beta_size = keys %{$beta_data};
#if (!$beta_size && $prod_size) {
#$Report->set_Error( "Test failed production ok, beta not ok: $type/$method/$date.case/$method $unique_case_index{$variations}-$unique_cases{$variations}\n");
#}
#else {
#}
#print "Production Command:\n$prod_command\nBeta Command:\n$beta_command\nProduction Result (limit to $limit if more than $limit):\n$prod_data\nBeta Result (limit to $limit if more than $limit):\n$beta_data\nAPI Argument:\n$dump_args\nProduction API stdout/stderr:\n$prod_output\nBeta API stdout/stderr:\n$beta_output\n\n";

                            $prod_data = Dumper $prod_data;
                            $beta_data = Dumper $beta_data;

                            #my @prods = split(/\n/, $prod_output);
                            #my @betas = split(/\n/, $beta_output);
                            #print Dumper @prods;
                            #print Dumper @betas;

                            #my $prod_error = join("\n", grep(/Unknown table|Unknown column/i && $_ !~ /at/, split(/\n/, $prod_output)));
                            #my $beta_error = join("\n", grep(/Unknown table|Unknown column/i && $_ !~ /at/, split(/\n/, $beta_output)));
                            my $prod_error = join( "\n", grep( /Error/, split( /\n/, $prod_output ) ) );
                            my $beta_error = join( "\n", grep( /Error/, split( /\n/, $beta_output ) ) );

                            #print "p: $prod_error\nb: $beta_error\n";

                            my $error_msg;
                            $error_msg .= "Production: $prod_error\n" if $prod_error;
                            $error_msg .= "Beta: $beta_error\n"       if $beta_error;
                            chomp $test_cases{source}->[$index];
                            $Report->set_Error(
                                "Test failed: $type/$method/$date.case (test $test_cases{test_number}->[$index], derived from $test_cases{source}->[$index]) $unique_case_index{$variations}-$unique_cases{$variations}\n$comments[0]->[0]\n$error_msg");
                            print
                                "This test is test_number $test_cases{test_number}->[$index] of $file and derived from $test_cases{source}->[$index]\n\nProduction Command:\n$prod_command\nBeta Command:\n$beta_command\nAPI Argument:\n$dump_args\nDifference (limit to $limit if more than $limit from $index):\n$comment\nProduction Result (limit to $limit if more than $limit from $index):\n$prod_data\nBeta Result (limit to $limit if more than $limit from $index):\n$beta_data\nProduction API stdout/stderr:\n$prod_output\nBeta API stdout/stderr:\n$beta_output\n\n";
                            $failed++;
                        }

                    }
                }

            }
            if ( @{ $test_cases{test_case} } ) {
                my $time = $total_execution_time - $pre_execution_time;
                $pre_execution_time = $total_execution_time;
                print "$file ($days_ago days ago) takes $time s to test.\n";
            }
        }
        $summary .= "$type/$method: $num_tests tests run, $failed failed.  Exec Time: $total_execution_time s\n";
        $Report->set_Message("$type/$method: $num_tests tests run, $failed failed. Exec Time: $total_execution_time s");
    }

    $Report->set_Detail($summary);

    return 'completed';
}

# --------------------------------------------------------------------
# Function:     extract_test_case
#
# Description:
# --------------------------------------------------------------------
############################
sub extract_test_cases {
############################
    my %args           = @_;
    my $test_case_file = $args{-file};

    # if there are no test cases
    if ( !-e $test_case_file ) {
        print "** $test_case_file does not exist **\n";
        return;
    }

    ## read the test case file
    my $TEST_CASE_FILE;
    open( $TEST_CASE_FILE, "<", $test_case_file ) or die( "can't open $test_case_file: $!\n", $Report->set_Error("Can't open $test_case_file"), $Report->DESTROY() );

    #my @test_cases;
    my %test_cases;
    $test_cases{test_case}   = [];
    $test_cases{source}      = [];
    $test_cases{test_number} = [];
    local $JSON::UnMapping = 1;    # set JSON to properly handle undefs
    while (<$TEST_CASE_FILE>) {
        my $test_case   = $_;
        my $source      = "Please grep to search";
        my $test_number = -1;
        my @data        = split( /\t/, $test_case );
        if ( @data > 1 ) {

            #This is the new format of the test case file
            #Where $data[0] is the test number, $data[1] is the JSON, $data[2] is the log file that had the json
            $test_number = $data[0];
            $test_case   = $data[1];
            $source      = $data[2];
        }

        # convert test_case to a JSON object
        #        my $jsonified_test_case = jsonToObj( $test_case );  done in lims07 so commiting maybe need to replace current line
        my $jsonified_test_case = from_json($test_case);

        #push @test_cases, $jsonified_test_case;
        push @{ $test_cases{test_case} },   $jsonified_test_case;
        push @{ $test_cases{source} },      $source;
        push @{ $test_cases{test_number} }, $test_number;
    }

    close $TEST_CASE_FILE or die( "can't close $test_case_file: $!\n", $Report->set_Error("Can't close $test_case_file"), $Report->DESTROY() );

    #return @test_cases;
    return %test_cases;

}

# --------------------------------------------------------------------
# Function:    run_api
#
# Description: Run the API call based on the method,connection
#              information and API version (Beta or Production)
# --------------------------------------------------------------------
sub run_api {
################
    my %args            = @_;
    my $method          = $args{-method};
    my $input           = $args{-input};
    my $api_version     = $args{-api_version};
    my $connection_info = $args{-connection_info};
    my $API             = $args{-api_type};
    my $debug           = 0;

    my %connection_info = ();
    %connection_info = %{$connection_info} if $connection_info;

    #my $library_path;
    #my $remove_path;
    #
    #if ( $api_version eq 'production' ) {
    #    $library_path = $prod_lib_path;
    #    $remove_path  = $beta_lib_path;
    #}
    #else {
    #    $library_path = $beta_lib_path;
    #    $remove_path  = $prod_lib_path;
    #}

    ### change the library path
    #change_library_path( -library_path => "$library_path", -remove_path => "$remove_path" );
    #
    ### require the module
    #require_module( -module=> \@TEST_MODULE_FILES );
    #
    #my $API_obj     = $API->new( %connection_info );
    #$input->{-log_call} = 0;
    #$input->{-quiet} = 1;
    #
    #my $api_results = $API_obj->$method( %$input );
    #
    #return $api_results;

    #print "\nRunning: $api_version\n";

    my $path;
    if   ( $api_version eq 'production' ) { $path = $prod_lib_path }
    else                                  { $path = $beta_lib_path }

    #print Dumper %connection_info;
    $connection_info{-log_call} = 0;
    my $connection_ref = Safe_Freeze( -value => \%connection_info, -format => 'array', -encode => 1 );
    my $connection_string = $connection_ref->[0];
    print Dumper $connection_ref if $debug;

    #$input->{-log_call} = 0;
    $input->{-quiet} = 1;

    print Dumper $input if $debug;

    my $input_ref = Safe_Freeze( -value => $input, -format => 'array', -encode => 1 );
    my $input_string = join( '', @{$input_ref} );
    print Dumper $input_ref if $debug;

    my ($require_module) = grep ( $_ =~ /$API/, @TEST_MODULE_FILES );
    $require_module = $API if !$require_module;

    my $command = "$path/Run_API.pl -c $connection_string -i $input_string -t $API -m $method -r $require_module";
    print "$command\n" if $debug;
    my $result     = try_system_command("$command");
    my @results    = split( /\n/, $result );
    my $api_result = pop @results;

    print Dumper @results if $debug;
    my $api_output = join( "\n", @results );
    if ( $api_output !~ /\w/ ) { $api_output = ""; }

    print Dumper $api_result if $debug;
    my $thaw_r;
    if ( !grep /Software error/, @results ) {
        my $decode_r = MIME::Base32::decode($api_result);
        $thaw_r = YAML::thaw($decode_r);
    }

    return ( $thaw_r, $command, $api_output );

}

# --------------------------------------------------------------------
# Function:     change_library_path
#
# Description:  Change the library_path dynamically, add/remove a path
#               from the @INC variable
# --------------------------------------------------------------------
sub change_library_path {

    my %args         = @_;
    my $library_path = $args{-library_path};
    my $remove_path  = $args{-remove_path};

    #my $index = 0;
    #foreach my $key ( @INC ) {
    #    if ( $key =~ /^$remove_path$/i ) {
    #        splice(@INC,$index,1);
    #    }
    #    $index++;
    #}
    #
    #if ($library_path) {
    #    unshift @INC, $library_path;
    #}
    #print $FindBin::RealBin;
    #print "Before @INC:\n" . Dumper @INC;
    for ( my $index = 0; $index <= $#INC; $index++ ) {
        $INC[$index] =~ s/\E$remove_path\Q/\E$library_path\Q/;
        $INC[$index] =~ s/\E$FindBin::RealBin\Q/\E$library_path\Q/;
    }

    #print "After @INC:\n" . Dumper @INC;
    return 1;
}

# --------------------------------------------------------------------
# Function:    require_module
#
# Description: Dynamically reload a module in memory
# --------------------------------------------------------------------
sub require_module {
    my %args   = @_;
    my $module = $args{-module};
    my @module = @{$module};

    foreach my $mod (@module) {
        $mod =~ s/\//::/;
        $mod =~ s/\.pm//;
        eval "require $mod;";
    }

    return 1;
}

# Function: not_hotfix
#
# Description: to skip unit test for method that haven't been hotfix yet
############################
sub not_hotfix {
############################
    my %args   = @_;
    my $type   = $args{-type};
    my $method = $args{-method};

    my %not_hotfix = ( 'Solexa_API:get_Atomic_data' => 1, );
    if   ( $not_hotfix{"$type:$method"} ) { return 1 }
    else                                  { return 0 }
}
