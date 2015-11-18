#!/usr/local/bin/perl

################################################################################
#
# check_templates.pl
#
# This tests upload process for test template excel files.
#
################################################################################

use strict;
use DBI;
use Data::Dumper;

use CGI;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Departments";

use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::Process_Monitor;
use alDente::SDB_Defaults;
use alDente::Notification;

##############################

use vars qw($opt_h $opt_p $opt_v $opt_t $opt_l);

my $q = new CGI;

require "getopts.pl";
&Getopts('hp:t:l');

if ($opt_h) {
    &print_help_info();
    exit;
}

my $help     = $opt_h;
my $password = $opt_p;
my $version  = $opt_v;
my $template = $opt_t;
my $list     = $opt_l;

my $Dump_dir = $Configs{Dump_dir};
#########

my $host  = 'limsdev04';
my $dbase = 'seqdev';
my $user  = 'super_cron';

my $datetime = &date_time();

my $error;

my $path = "/home/aldente/private/Upload_Template/$host/$dbase/Test";
if ( !$template ) { print_help_info(); exit; }

if ( $template =~ /^all$/i ) { $template = '' }    ## runs for all template files found

my @test_files = split "\n", try_system_command("ls $path/$template* | grep -v \'.val$\'");    ## exclude validation files

if ( $test_files[0] =~ /no such file/i ) { print "No test files in $path\n"; exit; }
if ($list) {
    print "Files to test:\n";
    print join "\n", @test_files;
    print "\n\n";
    exit;
}

# Connect to the master database
my $dbc = SDB::DBIO->new();
$dbc->connect( -host => $host, -dbase => $dbase, -user => $user );

if ( !$dbc->{connected} ) { print "Failed to connect to db - aborting...\n"; exit; }

$dbc->set_local( 'user_id',          141 );
$dbc->set_local( 'user_name',        'Admin' );
$dbc->set_local( 'printer_group_id', 13 );
$dbc->session->{printer_group} = 'Disabled';

my $Report = Process_Monitor->new( -variation => $version );

my $failed = 0;
my $passed = 0;
foreach my $test_file (@test_files) {
    my $ok = test_template($test_file);
    if ($ok) {
        $passed++;
        print "++ PASSED\t$test_file\n\n";
    }
    else {
        $failed++;
        print "** FAILED\t$test_file\n\n";
    }
}

print "done\n";
$dbc->disconnect();
print "disconnected\n";
if ($failed) {

    # $Report->set_Error("failed $failed template(s)");
}
else {

    # $Report->completed();
}

$Report->DESTROY();
print "report closed\n";

my ($year, $month, $day) = split /[\:\s]/ &date_time;

print "see /home/aldente/private/logs/cron_logs/Process_Monitor/$year/$month/$day/check_templates.log\n\n";

exit;

####################
sub test_template {
####################
    my $test_file = shift;

    Message("TESTING $test_file...");

    my ( $added, $newids ) = run_upload_app($test_file);

    my @errors = @{ $dbc->{errors} };

    my $error_list;
    if (@errors) {
        $error_list = "$test_file Errors\n";
        $error_list .= join "\n* ", @errors;
        $error_list .= "\nDetails:\n";

        my @warnings = map {
            my $warning = $_;
            $warning =~ s/<\/?UL>//ig;
            $warning =~ s/<LI>/\n\- /gi;
            $warning =~ s/<\/LI>//g;
            $warning;
        } @{ $dbc->{warnings} };

        $error_list .= join "\n- ", @warnings;

        #  $Report->set_Error($error_list);

        $dbc->clear_warnings;
        $dbc->clear_errors;
    }

    return !$error_list;
}

####################
sub run_upload_app {
####################
    my $filename = shift;

    my $cgi_application;
    my $webapp;

    $ENV{CGI_APP_RETURN_ONLY} = 1;    ## returns output rather than printing it ##

    $dbc->execute_command(" update Source, Rack Set FK_Rack__ID = 7 WHERE FK_Rack__ID=Rack_ID AND FKParent_Rack__ID = 320");    ## clear test target box

    $cgi_application = 'SDB::Import_App';                                                                                       ## param('cgi_application');
    eval "require $cgi_application";

    $webapp = $cgi_application->new( PARAMS => { dbc => $dbc, CGI_APP_RETURN_ONLY => 1 } );

    my $Validation;
    my ( $reference_field, $reference_ids );                                                                                    ## optional list of reference values to attach to upload (retrieved from .val file)

    if ( -e "$filename.val" ) {
        ### validation file ###
        require YAML;
        Message("validating $filename newids");
        $Validation = YAML::LoadFile("$filename.val");

        if ( $Validation->{reference} ) {
            $reference_field = $Validation->{reference};
            $reference_ids = Cast_List( -list => $Validation->{reference_ids}, -to => 'string' );
        }

    }

    my $rm;

    #    if ($filename =~/\.ref.(.*)\./) {
    #        my $ref = $1;
    #        $webapp->query->param('Reference_Field', "${ref}_ID");
    #        $webapp->query->param('Reference_IDs', '5000,5001,5002');
    #    }

    if ( $filename =~ /\.yml/ ) {
        $rm = 'Link Records to Template File';
        $webapp->query->param( 'template_file', $filename );

        ## change below to retrieve them from a validation file with the same name eg A.auto.yml + A.auto.validation ##
        #        $webapp->query->param('Reference_Field', 'Source ID');
        #        $webapp->query->param('Reference_IDs','5000,5001,5002');
        $webapp->query->param( 'Confirmed', 1 );
        $webapp->query->param( 'Test',      1 );
    }
    else {
        $cgi_application = 'SDB::Import_App';    ## param('cgi_application');

        eval "require $cgi_application";
        $webapp = $cgi_application->new( PARAMS => { dbc => $dbc, CGI_APP_RETURN_ONLY => 1 } );

        $rm = 'Confirm Upload';
        $webapp->query->param( 'input_file_name', $filename );

        $webapp->query->param( 'FK_Rack__ID', 320 );    ## specify target rack location if required..
    }
    
    if ($reference_field) {
        $webapp->query->param( 'Reference_Field', $reference_field );
        $webapp->query->param( 'Reference_IDs',   $reference_ids );
        Message("** Testing with $reference_field = $reference_ids **"); 
    }

    $webapp->start_mode($rm);
    $webapp->query->param( 'rm', $rm );

    print show_params($webapp);

    my $page = $webapp->run();

    my $transaction = $dbc->transaction();
    my $new_ids     = $transaction->{newids};           ## retrieve transaction new ids

    my $message = "New IDs from $filename:\n";
    $message .= Dumper $new_ids;
    $Report->set_Detail($message);

    my $added = 0;

    if ($Validation) {
        ## customized validation ##
        my ( $ok, $msg ) = validate( $new_ids, $Validation );
        if ($ok) {
            $Report->set_Message("upload PASSED Validation check:\n$msg");
            $Report->succeeded();
        }
        else {
            $Report->set_Error("$filename Validation FAILED\n$msg\n");
            $dbc->error("$filename FAILED validation");
           
            log_dbc_warnings($Report, $dbc, $filename);
        }
    }
    elsif ( $page =~ /uploaded (\d+) records/i ) {
        $added = $1;
        if ($added) {
            ## report success
            $Report->succeeded();
            $Report->set_Message("upload PASSED - $added records imported from $filename");
        }
        else {
            $Report->set_Error("0 records imported from $filename");
            $dbc->error("$filename imported 0 records (FAILED)");
            log_dbc_warnings($Report, $dbc, $filename);
        }
    }
    else {
        $Report->set_Error("Did not find records to import in $filename");
        $dbc->error("$filename FAILED to import records");
        log_dbc_warnings($Report, $dbc, $filename);
    }

    $dbc->start_trans( 'restarted', -restart => 1 );    ## clear transaction

    return ( $added, $new_ids );
}

#################
sub validate {
#################
    my $new_ids    = shift;
    my $Validation = shift;

    my ( $success, $failed ) = ( 1, 0 );
    my $message = '';

    my %Primary;

    foreach my $key ( keys %$Validation ) {

        if ( ref $Validation->{$key} ne 'HASH' ) {next}

        my @list = keys %{ $Validation->{$key} };

        if ( $key eq 'count' ) {
            ### confirm record count ###
            foreach my $table (@list) {
                my $succeeded = 0;
                my $count     = $Validation->{$key}{$table};

                if ( $new_ids->{$table} && ( $count == int( @{ $new_ids->{$table} } ) ) ) { $succeeded++; $message .= "$count $table records - ok\n" }
                elsif ( $new_ids->{$table} ) { $failed++; $message .= int( @{ $new_ids->{$table} } ) . " != $count ($table) \n" }
                else                         { $failed++; $message .= "$table not in list of new ids...\n" }
                if ( $succeeded && !$failed ) { $message .= "Passed count check for $table" }
                $success *= $succeeded;
            }
        }

        if ( $key eq 'pattern' ) {
            ### confirm record count ###
            foreach my $table (@list) {
                my $succeeded = 0;
                my $pattern   = $Validation->{$key}{$table};
                my @new_ids   = @{ $new_ids->{$table} } if $new_ids;
                foreach my $id (@new_ids) {
                    if   ( $id =~ /^$pattern$/ ) { $succeeded++ }
                    else                         { $message .= "$id did not match pattern: $pattern\n"; $failed++; }
                }
                if ( $succeeded && !$failed ) { $message .= "Passed pattern check for $table" }
                $success *= $succeeded;
            }
        }

        if ( $key eq 'data' ) {
            ### confirm record count ###
            foreach my $table (@list) {
                my $count = $Validation->{$key}{$table};

                if ( !$new_ids || !$new_ids->{$table} ) {
                    $failed++;
                    $message .= "No new ids found for $table";
                    next;
                }

                my @ids  = @{ $new_ids->{$table} };
                my $data = $Validation->{$key}{$table};
                my ($primary) = $Primary{$table} || $dbc->get_field_info( $table, undef, 'Primary' );
                $Primary{$table} = $primary;

                my @fields = keys %$data;
                foreach my $field (@fields) {
                    my $succeeded = 0;
                    my @expected = Cast_List( -list => $data->{$field}, -to => 'array', -pad => int(@ids) );

                    $message .= "\nconfirming $field data:\n";
                    foreach my $i ( 0 .. $#ids ) {
                        my ($found) = $dbc->Table_find_array( $table, [$field], "WHERE $primary = '$ids[$i]'" );
                        if ( $found eq $expected[$i] ) { $message .= "$found; "; $succeeded++; }
                        else {
                            $failed++;
                            $message .= "\n** [Found] $found != $expected[$i] [Expected] **\n";
                        }
                    }
                    if ( $succeeded && !$failed ) { $message .= "\n** data verified **\n" }
                    $success *= $succeeded;
                }
            }
        }
    }

    $success *= !$failed;
    return ( $success, $message );
}

########################
sub log_dbc_warnings {
########################
    my $Report = shift;
    my $dbc    = shift;
    my $test   = shift;

    my $clear  = 1;

    my @warnings = @{$dbc->warnings};
    my @errors = @{$dbc->errors};
   
    if ($test && @warnings) { unshift @warnings, "*** $test WARNINGS: ***" }
    if ($test && @errors) { unshift @errors, "*** $test ERRORS: ***" }
    
    foreach my $warning (@warnings) { $Report->set_Warning($warning) }
    foreach my $error (@errors) { $Report->set_Error($error) }

    if ($clear) { 
        $dbc->clear_warnings();
        $dbc->clear_errors();
    }
    return;
}
    
##################
sub show_params {
##################
    my $webapp = shift;

    my $q = $webapp->query();

    my $params = show_parameters( -q => $q, -format => 'text' );

    return $params;
}

#####################
sub print_help_info {
#####################

    my $help = "\nRuns Automated testing of upload process for all test cases in $path\n";

    $help .= <<HELP;

        Mandatory:
        -t <template>     : the template name (it will run test for all test files like '<template>*' (both yml & xls)

        Optional:
        -l                : just show the test files to test and exit
        
        check_templates.pl -t Clinical 
        check_templates.pl -t all
        
        (or to just list applicable test files):
        
        check_templates.pl -t Clinical -l
        check_templates.pl -t all -l

    To check results see: /home/aldente/private/logs/cron_logs/Process_Monitor/YYYY/MM/DD/check_templates.log

HELP

    print $help;
}

############
sub leave {
############
    # intercept main::leave to enable continuation

    return;
}

1;
