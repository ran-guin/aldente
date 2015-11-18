#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';
my $pwd    = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("RGTools::FTP");

if ( !$method || $method =~ /\brun_rsync\b/ ) {
    can_ok("RGTools::FTP", 'run_rsync');
    {
        ## <insert tests for run_rsync method here> ##
    }
}

if ( !$method || $method =~ /\bget_rsync_file_status\b/ ) {
    can_ok("RGTools::FTP", 'get_rsync_file_status');
    {
        ## <insert tests for get_rsync_file_status method here> ##
		my $output = "./
Employee/105/general/Jacquie BC_ summary.yml is uptodate
Employee/134/gelrun/data/gel_summ.log is uptodate
Employee/134/gelrun/data/gel_summ.yml is uptodate
Employee/134/solexa_run/data/Anthony.yml is uptodate
Employee/134/solexa_run/data/MORGEN.yml is uptodate
total: matches=0  tag_hits=0  false_alarms=0 data=0 
		";
        my $result = RGTools::FTP::get_rsync_file_status( -output => $output);
        print Dumper $result;
    }
}

if ( !$method || $method =~ /\b_ftp_connect\b/ ) {
    can_ok("RGTools::FTP", '_ftp_connect');
    {
        ## <insert tests for _ftp_connect method here> ##
    }
}

if ( !$method || $method =~ /\b_ftp_upload\b/ ) {
    can_ok("RGTools::FTP", '_ftp_upload');
    {
        ## <insert tests for _ftp_upload method here> ##
    }
}

if ( !$method || $method =~ /\b_ascp_upload\b/ ) {
    can_ok("RGTools::FTP", '_ascp_upload');
    {
        ## <insert tests for _ascp_upload method here> ##
    }
}

if ( !$method || $method =~ /\bupload\b/ ) {
    can_ok("RGTools::FTP", 'upload');
    {
        ## <insert tests for upload method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed FTP test');

exit;
