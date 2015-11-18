:#!/usr/local/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../lib/perl";
use lib $FindBin::RealBin . "/../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../lib/perl/Sequencing";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More; 
use SDB::CustomSettings qw(%Configs);
use strict;

use Getopt::Long;
use vars qw($opt_method);

&GetOptions(
            'method=s'    => \$opt_method,
        );

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use Sequencing::Custom;
############################

require SDB::DBIO;

if ( !$method || $method=~/\btray_wells\b/ ) {
    can_ok("Sequencing::Custom", 'tray_wells');

	my @source;
	my @failed_source;
	my @input_test = ('c','','','d','b','','a','','','d','a','',
					'c','','','d','b','','a','','','d','a','',
					'c','','','d','b','','a','','','d','a','');
	my @type_test = ('Tray','384-well','96-well','Tray','Tray','96-well','Tray','384-well','96-well','Tray','Tray','96-well',
				'Tray','384-well','96-well','Tray','Tray','96-well','Tray','384-well','96-well','Tray','Tray','96-well',
				'Tray','384-well','96-well','Tray','Tray','96-well','Tray','384-well','96-well','Tray','Tray','96-well');
    
	my $source_size = 12 * (int @input_test);

# Proper input
	@source = Sequencing::Custom::tray_wells(\@input_test,\@type_test);
	
# checking size
	is(int @source, $source_size,'size');

# checking a few elements
	is($source[0],'B1','First Element');
	is($source[12],'B2','element 13');
	is($source[25],'C2','element 26');
	is($source[-1],'D12','Last element');

# out of range input
	my @fail_input_test  = ('f');
	my @fail_type_test = ('tray');
	@failed_source = &Sequencing::Custom::tray_wells (\@fail_input_test,\@fail_type_test);
	is($failed_source[0],undef,'F failes');

# size af arrays dont match
    @fail_input_test  = ('','c','');
    @fail_type_test = ('384','tray');
	@failed_source = &Sequencing::Custom::tray_wells (\@fail_input_test,\@fail_type_test);
	is($failed_source[0],undef,'F failes');

# type and quadrant dont match
    @fail_input_test  = ('a');
    @fail_type_test = ('384');
	@failed_source = &Sequencing::Custom::tray_wells (\@fail_input_test,\@fail_type_test);
	is($failed_source[0],undef,'F failes');

# type and quadrant dont match II
	    @fail_input_test  = ('d');
	    @fail_type_test = ('96');
		@failed_source = &Sequencing::Custom::tray_wells (\@fail_input_test,\@fail_type_test);
		is($failed_source[0],undef,'F failes');

# false type
    @fail_input_test  = ('');
    @fail_type_test = ('tray');
	@failed_source = &Sequencing::Custom::tray_wells (\@fail_input_test,\@fail_type_test);
	is($failed_source[0],undef,'F failes');



}

## END of TEST ##

ok( 1 ,'Completed test');

exit;
