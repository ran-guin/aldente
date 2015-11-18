#!/usr/local/bin/perl

### External Modules
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/"; # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../lib/perl/Core/";
use lib $FindBin::RealBin . "/../lib/perl/Imported/";
use strict;
use Data::Dumper;
use YAML qw( Load );
use JSON;
use Getopt::Long;
use File::Path;
use Benchmark;

### LIMS Modules
use RGTools::RGIO qw( compare_data timestamp Call_Stack today date_time);
use SDB::CustomSettings;
use SDB::HTML qw( create_tree HTML_Dump );
use RGTools::HTML_Table;
use RGTools::Process_Monitor;

use Test::Simple qw(no_plan);
use Test::More;
use Test::Differences;

### API test file connection setting
my $dbase_default         = "sequence";
my $host_default          = "lims01";
my $LIMS_user_default     = "Guest";
my $LIMS_password_default = "pwd";
my $DB_user_default       = "viewer";
my $DB_password_default   = "viewer";
my $debug_default         = 0;

#### Specifying global Maximums ####
my $MAX_TESTS_PER_CASE    = 5;
my $MAX_TEST_CASES        = 5000;
my $MAX_DAYS_LOOKUP       = 30*6; ## 6 months

my @TEST_MODULE_FILES = qw( 
        alDente/alDente_API.pm
        Lib_Construction/Microarray_API.pm
        Mapping/Mapping_API.pm
        Sequencing/Sequencing_API.pm
        Sequencing/Solexa_API.pm
        Vectorology/Vectorology_API.pm
    );
        #Submission/Template_API.pm

my @TEST_MODULES;
foreach my $module (@TEST_MODULE_FILES) {
    my $mod = $module;
#    if ($mod =~ /alDente/) {
#        $mod =~ s/\//::/; 
#    } else {
#        $mod =~ s/.*\///;
#    }
    $mod =~ s/\.pm$//;
    push @TEST_MODULES, $mod;
}

### library paths
my $prod_lib_path          = "/home/sequence/alDente/WebVersions/Production/lib/perl/";
my $beta_lib_path          = "/home/sequence/alDente/WebVersions/Beta/lib/perl/";

# File directories - Constants
my $TEST_CASE_DIR  = $Configs{Home_public} . '/API_test_cases';
my $LOG_DIR        = $Configs{Home_public} . '/logs/API_logs';

# Default command line argument values
my $date                = '';
my $date_offset         = '';
my $all_methods         = "";
my @methods             = undef;
my $generate_test_cases = "";
my $run_test_cases      = "";
my $help_requested      = "";
my $test_type           = "";

             # option         # variable               # shortcut
GetOptions ( 'date|d=s'    => \$date,                  # d
             'offset|o=s'  => \$date_offset,           # o
             'all|a'       => \$all_methods,           # a
             'methods|m=s' => \@methods,               # m
             'generate|g'  => \$generate_test_cases,   # g
             'run|r'       => \$run_test_cases,        # r
             'help|h|?'    => \$help_requested,        # h,?
             'type|t=s'    => \$test_type,             # t

         );

@methods = split q{,}, $methods[1];  # list of comma separated methods is stored in second array position.

## Display help
if ( $help_requested ) {

    display_help();

    exit;
}

# Set up Process Monitor
my $Report = Process_Monitor->new( -title => 'API_unit_test.pl Script');

if ($date and $date_offset) {
    my $error = "You can only specify either 'date' or 'offset' at one time";
    $Report->set_Error( $error );
    $Report->DESTROY();
    die $error;
}
elsif ($date_offset) {
    $date = &today("-$date_offset");
} 
elsif (!$date) {
    $date = &today();
}

## Error checking
if ( $generate_test_cases && $run_test_cases ) {
    my $error = "Error: Can't generate and run test cases at same time\n";
    $Report->set_Error( $error );
    $Report->DESTROY();
    die $error;
}

if ( $generate_test_cases && ( $all_methods || @methods || $test_type ) ) {
    my $error = "Error: Can't specify methods or types when generating test cases\n";
    $Report->set_Error( $error );
    $Report->DESTROY();
    die $error;
}

## Assumptions
if ( !$generate_test_cases && !$run_test_cases ) { $run_test_cases = 1; }
if ( !@methods && !$all_methods )                { $all_methods    = 1; }

## Error checking (dependant on changes made in assumptions section above)
if ( !$test_type && $run_test_cases ) {
    my $error = "Error: Please specify test type [" . join(', ', @TEST_MODULES). "]\n";
    $Report->set_Error( $error );
    $Report->DESTROY();
    die $error;
}

## Perform main action
if ( $generate_test_cases ) {

    $Report->set_variation('case_generation');
    $Report->set_Message("Generating test cases based on $date logs");
    my $cases = generate_test_cases(-date=>$date);
    $Report->completed();
    $Report->DESTROY();

    $cases ||= 0;

    if ($cases) {
        ### This forces an exit value of SUCCESS
        ok(1,"Generated $cases test cases");
    } else {
        ### else the script exits with a value of FAIL
    }
}
elsif ($run_test_cases) {

    $Report->set_Message( "Running test cases" );

    # select appropriate test case directory
    my $test_case_subdir = $test_type;

    if ( !grep(/$test_type$/,@TEST_MODULES) ) {
        my $error = "Error: type '$test_type' is an invalid type.\n";
        $Report->set_Error( $error );
        $Report->DESTROY();
        die $error;
    }


    # get available methods for each type of test case
    my $TEST_CASE_TYPES;
    opendir $TEST_CASE_TYPES, "$TEST_CASE_DIR/$test_case_subdir"
        or die ( "$!\n",
                 $Report->set_Error("Cannot open directory $TEST_CASE_DIR/$test_case_subdir"),
                 $Report->DESTROY() );

    # read all but '.' and '..'
    my @test_case_types = grep /[^.]/, readdir $TEST_CASE_TYPES;  ## Assumption: contains only directories.

    closedir $TEST_CASE_TYPES
        or die ( "$!\n",
                 $Report->set_Error("Cannot close directory $TEST_CASE_DIR/$test_case_subdir"),
                 $Report->DESTROY() );

    if ( $all_methods ) {
        @methods = @test_case_types;
    }

    $Report->set_variation($test_type);

    run_test_cases( -type_subdir => $test_case_subdir, -methods => \@methods);
    $Report->completed();
    $Report->DESTROY();
}
else {
    my $error = "Error: neither run nor generate were selected.  This should never happen!\n";
    $Report->set_Error( $error );
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
sub generate_test_cases {
    my %args                   = @_;
    my $max_tests_per_method   = $args{-max_tests_per_method};       # for future use
    my $date                   = $args{-date} || &today();

    $date =~ s/-/\//g;
    my $logfiles_directory = $LOG_DIR . '/' . $date;

    ## read in the test cases
    if ( !-e $logfiles_directory ) {
        $Report->set_Message( "$logfiles_directory does not exist" );
        return;  # no test cases to process
    }

    my $LOGFILES_DIR;
    opendir $LOGFILES_DIR, $logfiles_directory
        or die ( "can't open $logfiles_directory: $!",
                 $Report->set_Error( "Can't open $logfiles_directory" ),
                 $Report->DESTROY() );

    my @logged_cases = grep /[^.]/, readdir $LOGFILES_DIR;

    closedir $LOGFILES_DIR
        or die ( "can't close $logfiles_directory: $!\n",
                 $Report->set_Error( "Can't close $logfiles_directory" ),
                 $Report->DESTROY() );

    $Report->set_Detail("Files in $logfiles_directory");
    return &_build_test_case_files( -dir => $logfiles_directory, -files => \@logged_cases, -date=>$date);
}


# --------------------------------------------------------------------
# Function:     _parse_test_case
#
# Description:  Get the input arguments used in an API call based on
#               the test case file
# --------------------------------------------------------------------
sub _build_test_case_files {
    my %args        = @_;
    my $logfiles    = $args{-files};
    my $logfile_dir = $args{-dir };
    my $date        = $args{-date};

    my $recordCount    = 0;
    my @logRecords;

    foreach my $file (@{$logfiles}) {
        ### Read in the logfile
        open( LOGFILE, "$logfile_dir/$file" )
            or die ( "Cannot open file $file: $!\n",
                    $Report->set_Error( "Cannot open file $file" ),
                    $Report->DESTROY() );

        my $emptyLineCount = 0;

        while ( <LOGFILE> ) {
            my $currentLine = $_;

            # check if the current line is empty
            if ( $currentLine =~ /^$/ ) { $emptyLineCount++; }

            # check if there have been two empty rows in a row, if so, it's a new record, so increment the recordCount
            if ( $emptyLineCount > 1 or $currentLine =~ /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/ ) {
                $recordCount++;
                $emptyLineCount = 0;
            }

            $logRecords[ $recordCount ] .= $currentLine;
        }

        close LOGFILE
            or die ( "Can't close file: $!",
                    $Report->set_Error( "Can't close file $file" ),
                    $Report->DESTROY() );
    }


    my $count = 0;              ## Number of test cases
    my %new_cases;              ## JSON arguments list 
    my %unique_cases;           ## Hash with keys as the concat'ed list of arguments, and 
                                ##   values as the number of cases with those arguments
    
    
    ## Extract data from each record
    my $index = 0;
    foreach my $record ( @logRecords ) {
        # match method & modules
        my @methodStack;
        my @moduleStack;
        my $test_modules_regex = join('|',@TEST_MODULES); ### Sequencing|alDente|Mapping
        while ( $record =~ /^\d+ \=\> \'.*($test_modules_regex)::(\w+)\(\)\'.+$/gm ) {
            push @moduleStack, $1;
            push @methodStack, $2;
        }

        # get the last method and module from the stacks
        my $numMethods = scalar( @methodStack ) - 1;
        my $method     = $methodStack[ $numMethods ];
        my $module     = $moduleStack[ $numMethods ];

        ### Skip non-get methods
        if (
                $method !~ /^get_/ or
                $method =~ /\=\> bless\(\s\{/ 
            ) { next };
        
        # match json line
        my $json_line = '';
        my $output;

        if ($record =~ /MD5_Output:\t(\w+)/xms) {$output = $1};
        if ($record =~ /json: ({.+})/ixms) { $json_line = $1 }

        my $arguments;
        if (!$json_line && $record =~ /VAR1\s+=\s+{\s*(.*)};/xms) {
            $record =~ /VAR1\s+=\s+{\s*(.*)};/xms;
            my $match = $1;
            $arguments = eval 'my $var = {' . $match . '};';
        }
        else {
            ### No valuable arguments found in this record
            next;
        }

        if ($json_line && !$arguments) {
            $arguments = jsonToObj ($json_line);
        }
        #elsif (!$json_line && $arguments) {
        #    $json_line = objToJson ($arguments);
        #}
        delete $arguments->{-dbc};
        delete $arguments->{-log_call};
        delete $arguments->{-quiet};

        my %struct;
        $struct{args} = $arguments;
        $struct{MD5_output} = $output;

        $json_line = objToJson(\%struct);

        my $args = join(',',sort(keys %{$arguments}));

        if ($unique_cases{$module}{$method}{$args} < $MAX_TESTS_PER_CASE and $new_cases{$module}{$method} !~ /\Q$json_line\E/xms) {
            $unique_cases{$module}{$method}{$args}++;
            $new_cases{$module}{$method} .= "$json_line\n";
            $Report->succeeded();
            $count++;
        }
        
        if ($count == $MAX_TEST_CASES) {
            last;
        }
        $index++;
    }

    if ( %new_cases ) {
        foreach my $module (keys %new_cases) {
            $Report->set_Detail("For $module:\n");
            foreach my $method (keys %{$new_cases{$module}}) {
                my $variations = int keys %{$unique_cases{$module}{$method}};
                my $count;
                map { $count += $unique_cases{$module}{$method}{$_} } keys %{$unique_cases{$module}{$method}};
                $Report->set_Detail("\t$module::$method (Total: $count, Variations: $variations)\n");
                # open appropriate test suite file
                # naming scheme: /module/method/YYYY-MM-DD.case
                $date =~ s/\//-/gxms;
                my $test_case_dir  = "$TEST_CASE_DIR/$module/$method";
                my $test_case_file = "$date.case";

                # if the directory doesn't exist, create it
                if ( !-d $test_case_dir ) {
                    mkpath( $test_case_dir )
                        or die ( "Cannot create directory $test_case_dir: $!\n",
                                $Report->set_Error( "Cannot create directory $test_case_dir" ),
                                $Report->DESTROY() );
                    chmod 0777, $test_case_dir;
                }


                # open for appending
                my $TS;
                open( $TS, ">", "$test_case_dir/$test_case_file" )
                    or die ( "Cannot open $test_case_file: $!\n",
                                $Report->set_Error( "Cannot open $test_case_file" ),
                                $Report->DESTROY() );

                print $TS $new_cases{$module}{$method};

                close $TS
                    or die ( "Can't close $test_case_dir/$test_case_file: $!\n",
                                $Report->set_Error( "Can't close $test_case_dir/$test_case_file" ),
                                $Report->DESTROY() );

                $Report->set_Detail("wrote to $test_case_dir/$test_case_file");
            }
        }
    }

    return $count;
}

# --------------------------------------------------------------------
# Function:     run_test_cases
#
# Description:
# --------------------------------------------------------------------
sub run_test_cases {
    my %args    = @_;
    my $type    = $args{-type_subdir};
    my @methods = @{ $args{-methods} };

    # test: find library path
    my $ok = grep '/opt/alDente/versions/production/lib/perl', @INC;                    # TODO: remove all references to production
    ok( $ok, "Found the library path" );

    # test: use API
    my %connection;
    $connection{-DB_user } = $DB_user_default;
    $connection{-DB_password} = $DB_password_default;
    $connection{-dbase   } = $dbase_default;
    $connection{-host    } = $host_default;
    $connection{-connect } = 1;

    # test: use production library path
    my $prod_lib      = grep $prod_lib_path, @INC;

    ok( $prod_lib, "Using Production Library Path" );

    # test: switch to beta library path
    change_library_path( -library_path => "$beta_lib_path", -remove_path => "$prod_lib_path" );
    my $beta_lib = grep $beta_lib_path, @INC;
    ok( $beta_lib, "Switched to Beta Library Path" );
    ok( require_module( -module => \@TEST_MODULES ), "Required beta modules" );

    # test: require production modules
    change_library_path( -library_path => "$prod_lib_path", -remove_path => "$beta_lib_path" );
    ok( require_module( -module => \@TEST_MODULES ), "Required prod modules" );

    # test: compare production and beta results
    my $summary = "Test Summary\n" . "=" x 40 . "\n";
    foreach my $method ( @methods ) {
        my %unique_cases;
        my %unique_case_index;
        
        my $num_tests   = 0;
        my $failed      = 0;

        for my $days_ago (1..$MAX_DAYS_LOOKUP) {

            my $date = &today("-$days_ago");
            my $file       = "$TEST_CASE_DIR/$type/$method/$date.case";
            my @test_cases =  extract_test_cases( -file => $file );
            print "Looking at $file ($days_ago days ago)\n";

            foreach my $test_case ( @test_cases ) {

                if ($test_case->{args}) {
                    my $args = $test_case->{args};
                    my $variations = join(',',sort(keys %{$args}));
                    if (!$unique_cases{$variations}) {
                        $unique_case_index{$variations} = int(keys %unique_case_index);
                    }

                    my $passed_test = 0;
                    if ($unique_cases{$variations} < $MAX_TESTS_PER_CASE) {
                        $unique_cases{$variations}++;


                        $Benchmark{Start} = new Benchmark;           # initialize benchmark before loading modules 
                        my $beta_data = run_api( -api_type => $type, -method => $method, -api_version => 'beta',       -input => $args, -connection_info => \%connection );
                        my $prod_data = run_api( -api_type => $type, -method => $method, -api_version => 'production', -input => $args, -connection_info => \%connection );
                        $Benchmark{End} = new Benchmark;           # initialize benchmark before loading modules 
                        my $execution_time = timestr(timediff($Benchmark{End},$Benchmark{Start}));
                        $execution_time =~ /(\d+\.\d+) CPU/;
                        $execution_time = $1;
                        $passed_test = eq_or_diff( $prod_data, $beta_data, "Prod & Beta matched ($method $unique_case_index{$variations}-$unique_cases{$variations}\t[$execution_time Seconds] )" );

                        #my $md5_output = $test_case->{MD5_output};
                        #if (defined $md5_output) {
                        #    use Digest::MD5  qw(md5_hex);
                        #    my $beta_md5 = md5_hex(objToJson($beta_data));
                        #    print Dumper($beta_data,$beta_md5,$md5_output) if ($beta_md5 eq $md5_output);
                        #    #$passed_test = is($beta_md5, $test_case->{MD5_output}, "Production and MD5 matched");
                        #}

                        $num_tests++;
                        if ( $passed_test ) {
                            $Report->succeeded();
                        }
                        else {
                            $Report->set_Warning( "Test failed: $type/$method/$date.case" );
                            $failed++;
                        }

                    }
                }


                
            }
        }
        $summary .= "$type/$method: $num_tests tests run, $failed failed.\n";
        $Report->set_Message("$type/$method: $num_tests tests run, $failed failed.\n");
    }

    $Report->set_Detail($summary);

    return 'completed';
}


# --------------------------------------------------------------------
# Function:     extract_test_case
#
# Description:
# --------------------------------------------------------------------
sub extract_test_cases {
    my %args            = @_;	
    my $test_case_file  = $args{-file};

    # if there are no test cases
    if ( !-e $test_case_file ) {
        print"** $test_case_file does not exist **" ;
        return;
    }

    ## read the test case file
    my $TEST_CASE_FILE;
    open( $TEST_CASE_FILE, "<", $test_case_file )
        or die ( "can't open $test_case_file: $!\n",
                 $Report->set_Error( "Can't open $test_case_file" ),
                 $Report->DESTROY() );

    my @test_cases;
    local $JSON::UnMapping = 1;  # set JSON to properly handle undefs
    while ( <$TEST_CASE_FILE> ) {
        my $test_case = $_;

        # convert test_case to a JSON object
        my $jsonified_test_case = jsonToObj( $test_case );
        push @test_cases, $jsonified_test_case;
    }

    close $TEST_CASE_FILE
        or die ( "can't close $test_case_file: $!\n",
                 $Report->set_Error( "Can't close $test_case_file" ),
                 $Report->DESTROY() );

    return @test_cases;

}


# --------------------------------------------------------------------
# Function:    run_api
#
# Description: Run the API call based on the method,connection
#              information and API version (Beta or Production)
# --------------------------------------------------------------------
sub run_api {
    my %args            = @_;
    my $method          = $args{-method         };
    my $input           = $args{-input          };
    my $api_version     = $args{-api_version    };
    my $connection_info = $args{-connection_info};
    my $API             = $args{-api_type       };
    my %connection_info = ();
    %connection_info    = %{ $connection_info } if $connection_info;

    my $library_path;
    my $remove_path;

    if ( $api_version eq 'production' ) {
        $library_path = $prod_lib_path;
        $remove_path  = $beta_lib_path;
    }
    else {
        $library_path = $beta_lib_path;
        $remove_path  = $prod_lib_path;
    }

    ## change the library path
    change_library_path( -library_path => "$library_path", -remove_path => "$remove_path" );

    ## require the module 
    require_module( -module=> \@TEST_MODULE_FILES );

    my $API_obj     = $API->new( %connection_info );
    $input->{-log_call} = 0;
    $input->{-quiet} = 1;

    my $api_results = $API_obj->$method( %$input );

    return $api_results;

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
    my $remove_path  = $args{-remove_path };

    my $index = 0;
    foreach my $key ( @INC ) {
        if ( $key =~ /^$remove_path$/i ) {
            splice(@INC,$index,1);
        }
        $index++;
    }

    if ($library_path) {
        unshift @INC, $library_path;
    }

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
    my @module = @{ $module };

    foreach my $mod (@module) {
        $mod =~ s/\//::/;
        $mod =~ s/\.pm//;
        eval "require $mod;";
    }

    return 1;
}

