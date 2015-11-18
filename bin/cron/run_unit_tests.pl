#!/usr/local/bin/perl

use strict;
use DBI;

use FindBin;
my $location;

BEGIN {
    $location = $FindBin::RealBin;
    # must be assigned inside a BEGIN block so that the variable has a value before "use lib" is called
    # see: http://www.visionwebhosting.net/web-hosting-perl/WebHostingPerl-CPAN0045.htm for details
}

use lib $location . "/../lib/perl/";                     # add the local directory to the lib search path
use lib $location . "/../lib/perl/Core/";
use lib $location . "/../lib/perl/Imported/";

use RGTools::RGIO;
use RGTools::Process_Monitor;
use Test::TAP::Model;
use Getopt::Long;

use vars qw($opt_variation $opt_test);
GetOptions ( 
    'variation|v=s'    => \$opt_variation,                  # d
    'test=s'           => \$opt_test,
);

my $variation = $opt_variation;
my $test      = $opt_test;

print "$variation variation.\n";
# Set up Process Monitor
 my $Report = Process_Monitor->new( -title   => 'run_unit_tests.pl Script',
                                          -quiet   => 0,
                                          -verbose => 0,
                                        -variation => $variation,
              );
 

# Set the version of perl to use for the tests
$ENV{HARNESS_PERL} = "/usr/local/bin/perl";

print "running tests...\n";

$test ||= '*';
my @t_files = glob("$location/t/*/$test.t");

my $model = Test::TAP::Model->new_with_tests( @t_files );
print "get test files...\n";
my @test_files = $model->test_files();

my $num_failed_suites = 0;
my $num_died_suites   = 0;

foreach my $test_file (@test_files) {
    my $name           = $test_file->name();
    print "** $name **\n";
    unless ($name =~ /Collab/) { next }
    print "continue..";
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
        if ( @nok_tests ) {
            foreach my $nok_test ( @nok_tests ) {
                my $test_num = $nok_test->num();
                my $line_num = $nok_test->line();

                my $error = "$name - test #$test_num, line $line_num failed";
                $Report->set_Error( $error );
            }
        }
        else {
            my $error = "$name failed (died!)";
            $Report->set_Error( $error );
            $num_died_suites++;
        }

        $num_failed_suites++;
    }

    # log passed tests as succeeded
    my @passed_tests = $test_file->ok_tests();

    foreach my $passed_test ( @passed_tests ) {
        $Report->succeeded();
    }

    if ( $todo_failed ) {
        # tests in todo blocks failed, log a warning
        my $warning = "$name : $todo_failed TODO tests failed";
        $Report->set_Message($warning);
    }

    if ( $num_unexpected ) {
        # tests in todo blocks passed unexpectedly - these should be taken out of TODO block if done.
        my $warning = "$name : $num_unexpected TODO tests passed unexpectedly (remove from TODO block)";
        $Report->set_Warning($warning);
    }    

    my $file_summary = "$name - $passed - $num_ok ok, $num_nok not ok, "
                     . "$num_todo TODO, $num_skipped skipped, $num_unexpected unexpectedly passed, $todo_failed TODOs failed, "
                     . "$percentage\n";

    $Report->set_Detail( $file_summary );

}

my $total_suites                 = scalar @test_files;
my $total_passed                 = $model->total_passed();
my $total_failed                 = $model->total_failed();
my $total_percentage             = $model->total_percentage();
my $total_skipped                = $model->total_skipped();
my $total_todo                   = $model->total_todo();
my $total_unexpectedly_succeeded = $model->total_unexpectedly_succeeded();

my $run_summary =  "Summary\n========\n"
    . "$num_failed_suites out of $total_suites test suites failed ($num_died_suites out of $num_failed_suites failed test suites died).\n"
    . "\n$total_passed tests passed.  ($total_failed failed; $total_skipped skipped)\n"
    . "\n$total_todo TODO: $total_unexpectedly_succeeded unexpectedly succeeded\n"
    . "\n** $total_percentage **\n\n";

 $Report->set_Message( $run_summary );

print "Finished!\n";

 $Report->completed();

exit;
