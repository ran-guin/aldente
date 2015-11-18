#!/usr/local/bin/perl

use strict;
use DBI;
use Data::Dumper;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";         # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../lib/perl/Core/";         # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../lib/perl/Imported/";         # add the local directory to the lib search path
use RGTools::RGIO;
use RGTools::Views;
use RGTools::Process_Monitor::Manager;
use vars qw($opt_help $opt_quiet $opt_script $opt_sort $opt_offset $opt_debug);

use Getopt::Long;
&GetOptions(
	    'help'                  => \$opt_help,
	    'quiet'                 => \$opt_quiet,
	    'script=s'              => \$opt_script,
	    'sort'                  => \$opt_sort,        
	    'offset=s'              => \$opt_offset,
	    'debug'                 => \$opt_debug
	    );

my $help   = $opt_help;
my $quiet  = $opt_quiet;
my $script = $opt_script;                   ## just run it for one (or more) indicated scripts... 
my $sort   = defined $opt_sort ? $opt_sort : 1;
my $debug  = $opt_debug;
my $offset = $opt_offset || '-1d';           ## default by looking at yesterday

my %scripts = (
     restore_DB         => 1,
     upgrade_DB         => 1,
     update_sequence    => 1,
     import_gel_images  => 1,
     backup_RDB         => 1,
     check_replication  => 1,
     run_unit_tests     => 1,
     cleanup_DB         => 1,
     cleanup_web        => 1,
     DB_monitor         => 1,
     sys_monitor        => 1,
     update_Stats       => 1,
     DBIntegrity        => 1,
     cat_vectors        => 1,
     Notification       => 1,
     cleanup_mirror     => 1,
     cleanup            => 1,
     refresh_parameters => 1,
     set_Library_Status => 1,
     performance_monitor => 1,
     update_library_list => 1,
     check_sequenced_wells => 1,
     bulk_email_notification => 1,
     API_unit_test => [
                        'API_unit_test_alDente::alDente_API',
                        'API_unit_test_Sequencing_API',
                        'API_unit_test_Solexa_API',
                        'API_unit_test_case_generation'
                    ],
    run_unit_tests => [
        'run_unit_tests_beta',
        'run_unit_tests_production'
        ],
 );
#if ($script) { @scripts = split ',', $script; }        ## override default list if specified..
#if ($sort) { @scripts = sort @scripts; }

my $self = new Process_Monitor::Manager(-cron_list=>\%scripts,
                                        -notify=>['aldente@bcgsc.ca'],
                                        -include=>1,
                                        -offset=>$offset
                                        );

$self->generate_reports($debug);

#print $self->dump_results();

$self->send_summary() unless ($debug || $quiet);

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
