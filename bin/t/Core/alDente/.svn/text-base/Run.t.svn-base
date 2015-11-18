#!/usr/local/bin/perl
## ./template/unit_test_template.txt ##
#####################################
#
# Standard Template for unit testing
#
#####################################

### Template 4.1 ###

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use Test::Differences;
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 
my $dbc;                                 ## only used for modules enabling database connections

############################
use alDente::Run;
############################

############################################


## ./template/unit_test_dbc.txt ##
use alDente::Config;
my $Setup = new alDente::Config(-initialize=>1, -root => $FindBin::RealBin . '/../../../../');
my $configs = $Setup->{configs};

my $host   = $configs->{UNIT_TEST_HOST};
my $dbase  = $configs->{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';

print "CONNECT TO $host:$dbase as $user...\n";

require SDB::DBIO;
$dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -connect  => 1,
                        -configs  => $configs,
                        );




use_ok("alDente::Run");

my $self = new alDente::Run(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Run", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bcreate_runbatch\b/ ) {
    can_ok("alDente::Run", 'create_runbatch');
    {
        ## <insert tests for create_runbatch method here> ##
    }
}

if ( !$method || $method=~/\bcreate_runbatch_attribute\b/ ) {
    can_ok("alDente::Run", 'create_runbatch_attribute');
    {
        ## <insert tests for create_runbatch_attribute method here> ##
    }
}

if ( !$method || $method=~/\bretrieve_by_Library\b/ ) {
    can_ok("alDente::Run", 'retrieve_by_Library');
    {
        ## <insert tests for retrieve_by_Library method here> ##
    }
}

if ( !$method || $method=~/\bre_run\b/ ) {
    can_ok("alDente::Run", 're_run');
    {
        ## <insert tests for re_run method here> ##
    }
}

if ( !$method || $method=~/\bget_data_path\b/ ) {
    can_ok("alDente::Run", 'get_data_path');
    {
        ## <insert tests for get_data_path method here> ##
        my $path = alDente::Run::get_data_path(-dbc=>$dbc,-run_id=>1);
        is($path,"/home/aldente/private/Projects/Chlorarachnion/CC001/AnalyzedData/CC001-1.E7","Correct run path found");
    }
}

if ( !$method || $method=~/\bget_run_data\b/ ) {
    can_ok("alDente::Run", 'get_run_data');
    {
        ## <insert tests for get_run_data method here> ##
    }
}

if ( !$method || $method=~/\bget_run_list\b/ ) {
    can_ok("alDente::Run", 'get_run_list');
    {
        ## <insert tests for get_run_list method here> ##
    }
}

if ( !$method || $method=~/\bannotate_runs\b/ ) {
    can_ok("alDente::Run", 'annotate_runs');
    {
        ## <insert tests for annotate_runs method here> ##
    }
}

if ( !$method || $method=~/\bset_validation_status\b/ ) {
    can_ok("alDente::Run", 'set_validation_status');
    {
        ## <insert tests for set_validation_status method here> ##
	$comment = 'Unit test';
        my $status = 'Approved';
	my $ok = alDente::Run::set_validation_status( -dbc=>$dbc,-run_id=> [1], -status=>$status, -comment=> $comment);
        #my $ok = $dbc->Table_update_array('Run',['Run_Validation'],[$status],"WHERE Run_ID in (1,2,3)",-autoquote=>1,-comment=>$comment);
        my $count1 = $dbc->Table_find('Change_History,DBField',"New_Value","WHERE FK_DBField__ID=DBField_ID and Field_Name = 'Run_Validation' AND LEFT(Modified_Date,10) = CURDATE()");
        #print "\n ++ $count1 ++ \n";
	#$status = 'Analyzed';
        #$dbc->Table_update_array('Run',['Run_Validation'],[$status],"WHERE Run_ID IN (1,2,3)",-autoquote=>1,-comment=>$comment);
        #my $count2 = $dbc->Table_find('Change_History,DBField',"New_Value","WHERE FK_DBField__ID=DBField_ID and Field_Name = 'Run_Validation' AND LEFT(Modified_Date,10) = CURDATE()");
        my ($validation) = $dbc->Table_find('Run','Run_Validation',"WHERE Run_ID IN (1,2,3)");
        is ($status,$validation,"found new change history record added"); 
    }
}

if ( !$method || $method=~/\brun_view_options\b/ ) {
    can_ok("alDente::Run", 'run_view_options');
    {
        ## <insert tests for run_view_options method here> ##
    }
}

if ( !$method || $method=~/\b_nextname\b/ ) {
    can_ok("alDente::Run", '_nextname');
    {
        ## <insert tests for _nextname method here> ##
    }
}

if ( !$method || $method=~/\b_copy_batch\b/ ) {
    can_ok("alDente::Run", '_copy_batch');
    {
        ## <insert tests for _copy_batch method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Run test');

exit;
