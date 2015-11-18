#!/usr/local/bin/perl

################################
#
# Template for unit testing
#/
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More; use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use RGTools::RGmath;
############################
my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("RGTools::RGmath");

if ( !$method || $method=~/\binterpolate\b/ ) {
    can_ok("RGmath", 'interpolate');
    {
        ## <insert tests for interpolate method here> ##
    }
}

if ( !$method || $method=~/\bunion\b/ ) {
    can_ok("RGmath", 'union');
    {
        ## <insert tests for union method here> ##
    }
}

if ( !$method || $method=~/\bintersection\b/ ) {
    can_ok("RGmath", 'intersection');
    {
        ## <insert tests for intersection method here> ##
    }
}

if ( !$method || $method=~/\bget_sum\b/ ) {
    can_ok("RGmath", 'get_sum');
    {
        ## <insert tests for get_sum method here> ##
    }
}

if ( !$method || $method =~ /\bxor_array\b/ ) {
    can_ok("RGmath", 'xor_array');
    {
        ## <insert tests for xor_array method here> ##
    }
}

if ( !$method || $method =~ /\bsmart_sort\b/ ) {
    can_ok("RGmath", 'smart_sort');
    {
        ## <insert tests for smart_sort method here> ##
	my @array = qw(A1 A2 A10 A01 B1 B2 b3 B10 1 10 00001 2);
	my @newarray = RGmath::smart_sort(@array);
	my @truearray = qw(00001 1 2 10 A01 A1 A2 A10 B1 B2 B10 b3);
	is_deeply(\@newarray, \@truearray, "correct sort 1");

	my @array = ('111','222','ABC','BD','N3', 'N12', 'B03','B300','B030a','B03a','B3b','B3a3','B3a', 'B3ab','B3','B33','B4', '1N1', 'B100','B10','B21','B11', 'B1');
	my @newarray = RGmath::smart_sort(@array);
	my @truearray = qw(1N1 111 222 ABC B1 B03 B03a B3 B3a B3a3 B3ab B3b B4 B10 B11 B21 B030a B33 B100 B300 BD N3 N12);
	is_deeply(\@newarray, \@truearray, "correct sort 2");
    }
}

if ( !$method || $method =~ /\bsmart_cmp\b/ ) {
    can_ok("RGmath", 'smart_cmp');
    {
        ## <insert tests for smart_cmp method here> ##
	my $res = RGmath::smart_cmp("B10","B3");
	is($res, 1, "Ok greater than check");

	my @array = qw(A1 A2 A10 A01 B1 B2 b3 B10 1 10 00001 2);
	my @newarray = sort {RGmath::smart_cmp($a,$b,-case_insensitive=>1)} (@array);
        my @truearray = qw(00001 1 2 10 A01 A1 A2 A10 B1 B2 b3 B10);
	is_deeply(\@newarray, \@truearray, "correct case insensitive sort");
    }
}

if ( !$method || $method =~ /\bdistinct_list\b/ ) {
    can_ok("RGmath", 'distinct_list');
    {
        ## <insert tests for distinct_list method here> ##
        my $list = RGmath::distinct_list (['hello','apple','hello','sp ace',' hello'],0);
        my @test = ('hello','apple','sp ace',' hello');
        is_deeply(\@test,$list,"The output matches expected results without striping");
        
        my $list = RGmath::distinct_list (['hello'],1);
        my @test = ('hello');
        is_deeply(\@test,$list,"simple case passed");
 
 
        my $list = RGmath::distinct_list (['hello','apple','hello','','sp ace', '  ',' apple','apple '],1);
        my @test = ('hello','apple','sp ace');
        is_deeply($list,\@test,"The output matches expected results with striping");
        
        my $list = RGmath::distinct_list (('hello','apple','hello','','sp ace', '  ',' apple','apple '),1);
        my @test = ();
        is_deeply($list,\@test,"Entering Array instead of reference ");
        
        my $list = RGmath::distinct_list ("hello,apple,hello,sp ace,apple",1);
        my @test = ();
        is_deeply($list,\@test,"Entering string instead of reference with striping");
        
        my $list = RGmath::distinct_list ("hello,apple,hello,sp ace,apple",0);
        my @test = ();
        is_deeply($list,\@test,"Entering string instead of reference without striping");
        
 #        my $second_list = RGmath::distinct_list ([],1);
  #       my @second_output = @$second_list;
   #      my @second_test = ();
    #     is_deeply(\@second_test,\@second_output,"The empty test works too");
         
    }
}

## END of TEST ##

ok( 1 ,'Completed RGmath test');

exit;
