#!/usr/local/bin/perl

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
use Test::More; use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use RGTools::RGIO;
############################

############################################################
use_ok("RGTools::RGIO");

if ( !$method || $method=~/\berr\b/ ) {
    can_ok("RGTools::RGIO", 'err');
    {
        ## <insert tests for err method here> ##
    }
}

if ( !$method || $method=~/\blog_unit_test\b/ ) {
    can_ok("RGTools::RGIO", 'log_unit_test');
    {
        ## <insert tests for log_unit_test method here> ##
    }
}

if ( !$method || $method=~/\blog_usage\b/ ) {
    can_ok("RGTools::RGIO", 'log_usage');
    {
        ## <insert tests for log_usage method here> ##
    }
}

if ( !$method || $method=~/\bfilter_input\b/ ) {
    can_ok("RGTools::RGIO", 'filter_input');
    {
        ## <insert tests for filter_input method here> ##
        my ($a, $b, $c, $d) = (1,2,3);
        my ($e, $f, $g, $h);
        
        ($e, $f, $g, $h) = test($a,$b);
        is($e,$a,'pass normal args');
        
        ($e, $f, $g, $h) = test(-d=>$d, -a=>$a, -c=>$c);
        is($e,$a,'pass in explicitly a');
        is($f,undef,'excluded undef');
        is($g,$c,'pass in explicitly c');
        is($h,$d,'pass in explicitly undef');
        
        ($e, $f, $g, $h) = test('',$b);
        is($e,'','pass in blank');
        is($f,$b,'pass in after blank');
        
        ($e, $f, $g, $h) = test($d,$b);
        is($e,$d,'pass in undef');
        is($f,$b,'pass in after undef');
        is($g,$d,'undef');
        
        sub test {
            my %args = filter_input(\@_,-args=>'a,b', -debug=>1);

            my $a = $args{-a};
            my $b = $args{-b};
            my $c = $args{-c};
            my $d = $args{-d};
        
            return ($a,$b,$c,$d);
        }
    
    }
}

if ( !$method || $method=~/\bwildcard_match\b/ ) {
    can_ok("RGTools::RGIO", 'wildcard_match');
    {
        ## <insert tests for wildcard_match method here> ##
        is(wildcard_match(1,1),1,'1=1');
        is(wildcard_match(1,2),0,'1 != 2');
        is(wildcard_match('abc','abc'),1,'abc=abc');
        is(wildcard_match('abc','abcd'),0,'abc != abcd');
  
        is(wildcard_match('3',['1|2|3']),1,'1 in (1,2,3)');
        is(wildcard_match('1',['>2']),0,'1 !> 2');
        is(wildcard_match('3',['>2']),1,'3 > 2');
    
        is(wildcard_match('abcd','abc'),0, 'abcd != abc');
        is(wildcard_match('abcd','abc*'),1, 'abcd = abc*');
    
        is(wildcard_match('abcd',['bc*','abc']),0, 'abcd not in options');
        is(wildcard_match('abcd',['bc*', 'abc*']),1, 'abcd in options');
    }
}

if ( !$method || $method=~/\bsplit_arrays\b/ ) {
    can_ok("RGTools::RGIO", 'split_arrays');
    {
        ## <insert tests for split_arrays method here> ##
    }
}

if ( !$method || $method=~/\bautoquote_string\b/ ) {
    can_ok("RGTools::RGIO", 'autoquote_string');
    {
        ## <insert tests for autoquote_string method here> ##
    }
}

if ( !$method || $method=~/\bresolve_range\b/ ) {
    can_ok("RGTools::RGIO", 'resolve_range');
    {
        ## <insert tests for resolve_range method here> ##
    }
}

if ( !$method || $method=~/\bconvert_to_range\b/ ) {
    can_ok("RGTools::RGIO", 'convert_to_range');
    {
        ## <insert tests for convert_to_range method here> ##
    }
}

if ( !$method || $method=~/\bget_username\b/ ) {
    can_ok("RGTools::RGIO", 'get_username');
    {
        ## <insert tests for get_username method here> ##
    }
}

if ( !$method || $method=~/\bset_difference\b/ ) {
    can_ok("RGTools::RGIO", 'set_difference');
    {
        ## <insert tests for set_difference method here> ##
    }
}

if ( !$method || $method=~/\bset_operations\b/ ) {
    can_ok("RGTools::RGIO", 'set_operations');
    {
        ## <insert tests for set_operations method here> ##
    }
}

if ( !$method || $method=~/\bchomp_edge_whitespace\b/ ) {
    can_ok("RGTools::RGIO", 'chomp_edge_whitespace');
    {
        ## <insert tests for chomp_edge_whitespace method here> ##
    }
}

if ( !$method || $method=~/\bxchomp\b/ ) {
    can_ok("RGTools::RGIO", 'xchomp');
    {
        ## <insert tests for xchomp (\$) method here> ##
    }
}

if ( !$method || $method=~/\bunique_items\b/ ) {
    can_ok("RGTools::RGIO", 'unique_items');
    {
        ## <insert tests for unique_items method here> ##
    }
}

if ( !$method || $method=~/\btry_system_command\b/ ) {
    can_ok("RGTools::RGIO", 'try_system_command');
    {
        ## <insert tests for try_system_command method here> ##
    }
}

if ( !$method || $method=~/\bdate_time\b/ ) {
    can_ok("RGTools::RGIO", 'date_time');
    {
        ## <insert tests for date_time method here> ##
        my ($date) = split ' ', date_time();
        ok($date=~/^2014/, 'date is this year');

        my $debug = 1;
        my $today = '2012-01-29 12:10:44';
        
        my $tomorrow = date_time(-date=>$today,-offset=>'+3d', -debug=>$debug);
        is($tomorrow,'2012-02-01 12:10','go fwd three days');
        
        my ($yesterday) = date_time(-time=>$today,-offset=>'-1d', -debug=>1);
        is($yesterday,'2012-01-28 12:10','go back one day');
       
        my $lastmonth = date_time(-date=>$today, -offset=>'-1month');
        is($lastmonth, '2011-12-29 12:10','last month');

        my $nextyear = date_time(-date=>$today, -offset=>'+1y');
        is($nextyear, '2013-01-29 12:10','next year');
       
        my $current = date_time();
        my $tomorrow = date_time('+1d');
        my $backagain = date_time(-date=>$tomorrow,-offset=>'-1d');
        is($current, $backagain, 'there and back again');
    }
}

if ( !$method || $method=~/\btimestamp\b/ ) {
    can_ok("RGTools::RGIO", 'timestamp');
    {
        ## <insert tests for timestamp method here> ##
    }
}

if ( !$method || $method=~/\bdatestamp\b/ ) {
    can_ok("RGTools::RGIO", 'datestamp');
    {
        ## <insert tests for datestamp method here> ##
    }
}

if ( !$method || $method=~/\bnow\b/ ) {
    can_ok("RGTools::RGIO", 'now');
    {
        ## <insert tests for now method here> ##
    }
}

if ( !$method || $method=~/\btoday\b/ ) {
    can_ok("RGTools::RGIO", 'today');
    {
        ## <insert tests for today method here> ##
    }
}

if ( !$method || $method=~/\bweek_end_date\b/ ) {
    can_ok("RGTools::RGIO", 'week_end_date');
    {
        ## <insert tests for week_end_date method here> ##
    }
}

if ( !$method || $method=~/\bMessage\b/ ) {
    can_ok("RGTools::RGIO", 'Message');
    {
        ## <insert tests for Message method here> ##
    }
}

if ( !$method || $method=~/\bHTML_Comment\b/ ) {
    can_ok("RGTools::RGIO", 'HTML_Comment');
    {
        ## <insert tests for HTML_Comment method here> ##
    }
}

if ( !$method || $method=~/\bTest_Message\b/ ) {
    can_ok("RGTools::RGIO", 'Test_Message');
    {
        ## <insert tests for Test_Message method here> ##
    }
}

if ( !$method || $method=~/\bNote\b/ ) {
    can_ok("RGTools::RGIO", 'Note');
    {
        ## <insert tests for Note method here> ##
    }
}

if ( !$method || $method=~/\bget_line_with\b/ ) {
    can_ok("RGTools::RGIO", 'get_line_with');
    {
        ## <insert tests for get_line_with method here> ##
    }
}

if ( !$method || $method=~/\blist_contains\b/ ) {
    can_ok("RGTools::RGIO", 'list_contains');
    {
        ## <insert tests for list_contains method here> ##
    }
}

if ( !$method || $method=~/\badjust_list\b/ ) {
    can_ok("RGTools::RGIO", 'adjust_list');
    {
        ## <insert tests for adjust_list method here> ##
    }
}

if ( !$method || $method=~/\barray_containing\b/ ) {
    can_ok("RGTools::RGIO", 'array_containing');
    {
        ## <insert tests for array_containing method here> ##
    }
}

if ( !$method || $method=~/\btoggle_colour\b/ ) {
    can_ok("RGTools::RGIO", 'toggle_colour');
    {
        ## <insert tests for toggle_colour method here> ##
    }
}

if ( !$method || $method=~/\bdim_colour\b/ ) {
    can_ok("RGTools::RGIO", 'dim_colour');
    {
        ## <insert tests for dim_colour method here> ##
    }
}

if ( !$method || $method=~/\bLink_To\b/ ) {
    can_ok("RGTools::RGIO", 'Link_To');
    {
        ## <insert tests for Link_To method here> ##
    }
}

if ( !$method || $method=~/\bmake_thumbnail\b/ ) {
    can_ok("RGTools::RGIO", 'make_thumbnail');
    {
        ## <insert tests for make_thumbnail method here> ##
    }
}

if ( !$method || $method=~/\bHlink_padded\b/ ) {
    can_ok("RGTools::RGIO", 'Hlink_padded');
    {
        ## <insert tests for Hlink_padded method here> ##
    }
}

if ( !$method || $method=~/\bLog_Notes\b/ ) {
    can_ok("RGTools::RGIO", 'Log_Notes');
    {
        ## <insert tests for Log_Notes method here> ##
    }
}

if ( !$method || $method=~/\bFile_to_HTML\b/ ) {
    can_ok("RGTools::RGIO", 'File_to_HTML');
    {
        ## <insert tests for File_to_HTML method here> ##
    }
}

if ( !$method || $method=~/\brandom_int\b/ ) {
    can_ok("RGTools::RGIO", 'random_int');
    {
        ## <insert tests for random_int method here> ##
    }
}

if ( !$method || $method=~/\bload_Stats\b/ ) {
    can_ok("RGTools::RGIO", 'load_Stats');
    {
        ## <insert tests for load_Stats method here> ##
    }
}

if ( !$method || $method=~/\bLock_File\b/ ) {
    can_ok("RGTools::RGIO", 'Lock_File');
    {
        ## <insert tests for Lock_File method here> ##
    }
}

if ( !$method || $method=~/\bUnlock_File\b/ ) {
    can_ok("RGTools::RGIO", 'Unlock_File');
    {
        ## <insert tests for Unlock_File method here> ##
    }
}

if ( !$method || $method=~/\bShow_ENV\b/ ) {
    can_ok("RGTools::RGIO", 'Show_ENV');
    {
        ## <insert tests for Show_ENV method here> ##
    }
}

if ( !$method || $method=~/\bPrompt_Input\b/ ) {
    can_ok("RGTools::RGIO", 'Prompt_Input');
    {
        ## <insert tests for Prompt_Input method here> ##
    }
}

if ( !$method || $method=~/\bGet_Current_Dir\b/ ) {
    can_ok("RGTools::RGIO", 'Get_Current_Dir');
    {
        ## <insert tests for Get_Current_Dir method here> ##
    }
}

if ( !$method || $method=~/\bExtract_Values\b/ ) {
    can_ok("RGTools::RGIO", 'Extract_Values');
    {
        ## <insert tests for Extract_Values method here> ##
    }
}

if ( !$method || $method=~/\bShow_Moz_Tool_Tip\b/ ) {
    can_ok("RGTools::RGIO", 'Show_Moz_Tool_Tip');
    {
        ## <insert tests for Show_Moz_Tool_Tip method here> ##
    }
}

if ( !$method || $method=~/\bShow_Tool_Tip\b/ ) {
    can_ok("RGTools::RGIO", 'Show_Tool_Tip');
    {
        ## <insert tests for Show_Tool_Tip method here> ##
    }
}

if ( !$method || $method=~/\bArray_Exists\b/ ) {
    can_ok("RGTools::RGIO", 'Array_Exists');
    {
        ## <insert tests for Array_Exists method here> ##
    }
}

if ( !$method || $method=~/\bPopup_Menu\b/ ) {
    can_ok("RGTools::RGIO", 'Popup_Menu');
    {
        ## <insert tests for Popup_Menu method here> ##
    }
}

if ( !$method || $method=~/\bCall_Stack\b/ ) {
    can_ok("RGTools::RGIO", 'Call_Stack');
    {
        ## <insert tests for Call_Stack method here> ##
    }
}

if ( !$method || $method=~/\bCast_List\b/ ) {
    can_ok("RGTools::RGIO", 'Cast_List');
    {
        ## <insert tests for Cast_List method here> ##
        my $list = [ 1, 2, 3, '4' , '5'];
        my $target = "'1','2','3','4','5'";
        is_deeply( Cast_List(-list=>$list, -to=>'string', -autoquote=>1), $target, 'cast array to autoquoted string');
    
        my $list = join ',', ( 1, 2, 3, '4,5');
        is_deeply( Cast_List(-list=>$list, -to=>'string', -autoquote=>1), $target, 'cast comma-separated list to autoquoted string');
        
        my $list = [1.1, 2.2, 3.3, 4.4, 5.5];
        is_deeply( Cast_List(-list=>$list, -to=>'string', -resolve_range=>1, -autoquote=>0), '1.1,2.2,3.3,4.4,5.5', 'cast comma-separated list to autoquoted string');
        
        my $list = '1-4';
        is_deeply( Cast_List(-list=>$list, -to=>'string', -resolve_range=>1, -autoquote=>0), '1,2,3,4', 'cast range to string');

        my $list = '-1-4';
        is_deeply( Cast_List(-list=>$list, -to=>'string', -resolve_range=>1, -autoquote=>0), '-1,0,1,2,3,4', 'cast range including negative numbers to string');
        
        my $list = '-6 - -4';
        is_deeply( Cast_List(-list=>$list, -to=>'string', -resolve_range=>1, -autoquote=>0), '-6,-5,-4', 'cast range including negative number max to string');
    }
}

if ( !$method || $method=~/\bSafe_Freeze\b/ ) {
    can_ok("RGTools::RGIO", 'Safe_Freeze');
    {
        ## <insert tests for Safe_Freeze method here> ##
    }
}

if ( !$method || $method=~/\bSafe_Thaw\b/ ) {
    can_ok("RGTools::RGIO", 'Safe_Thaw');
    {
        ## <insert tests for Safe_Thaw method here> ##
    }
}

if ( !$method || $method=~/\binput_error_check\b/ ) {
    can_ok("RGTools::RGIO", 'input_error_check');
    {
        ## <insert tests for input_error_check method here> ##
    }
}

if ( !$method || $method=~/\bResolve_Path\b/ ) {
    can_ok("RGTools::RGIO", 'Resolve_Path');
    {
        ## <insert tests for Resolve_Path method here> ##
    }
}

if ( !$method || $method=~/\bParse_CSV_File\b/ ) {
    can_ok("RGTools::RGIO", 'Parse_CSV_File');
    {
        ## <insert tests for Parse_CSV_File method here> ##
    }
}

if ( !$method || $method=~/\bstrim\b/ ) {
    can_ok("RGTools::RGIO", 'strim');
    {
        ## <insert tests for strim method here> ##
    }
}

if ( !$method || $method=~/\btruncate_string\b/ ) {
    can_ok("RGTools::RGIO", 'truncate_string');
    {
        ## <insert tests for truncate_string method here> ##
    }
}

if ( !$method || $method=~/\bencode_var\b/ ) {
    can_ok("RGTools::RGIO", 'encode_var');
    {
        ## <insert tests for encode_var method here> ##
    }
}

if ( !$method || $method=~/\bdecode_var\b/ ) {
    can_ok("RGTools::RGIO", 'decode_var');
    {
        ## <insert tests for decode_var method here> ##
    }
}

if ( !$method || $method=~/\bday_elapsed\b/ ) {
    can_ok("RGTools::RGIO", 'day_elapsed');
    {
        ## <insert tests for day_elapsed method here> ##
    }
}

if ( !$method || $method=~/\bcompare_objects\b/ ) {
    can_ok("RGTools::RGIO", 'compare_objects');
    {
        ## <insert tests for compare_objects method here> ##
    }
}

if ( !$method || $method=~/\bcompare_data\b/ ) {
    can_ok("RGTools::RGIO", 'compare_data');
    {
        ## <insert tests for compare_data method here> ##
    }
}

if ( !$method || $method=~/\bread_dumper\b/ ) {
    can_ok("RGTools::RGIO", 'read_dumper');
    {
        ## <insert tests for read_dumper method here> ##
    }
}

if ( !$method || $method=~/\b_record_diff_struct\b/ ) {
    can_ok("RGTools::RGIO", '_record_diff_struct');
    {
        ## <insert tests for _record_diff_struct method here> ##
    }
}

if ( !$method || $method=~/\b_get_CSV_data\b/ ) {
    can_ok("RGTools::RGIO", '_get_CSV_data');
    {
        ## <insert tests for _get_CSV_data method here> ##
    }
}

if ( !$method || $method=~/\bcmp_file_timestamp\b/ ) {
    can_ok("RGTools::RGIO", 'cmp_file_timestamp');
    {
        ## <insert tests for cmp_file_timestamp method here> ##
        my $f1 = "/opt/alDente/www/dynamic/views/seqdev/Group/23/general/Rack_Contents.yml";
        my $f2 = "lims08:/opt/alDente/www/dynamic/views/sequence/Group/23/general/Rack_Contents.yml";
        my $result = cmp_file_timestamp( $f1, $f2 );
        print "compare $f1\nwith\n$f2\nresult = $result\n";
    }
}

if ( !$method || $method=~/\bstandardize_text_value\b/ ) {
    can_ok("RGTools::RGIO", 'standardize_text_value');
    {
	
        my $text = ' Space ';
	$text = RGTools::RGIO::standardize_text_value($text);
	is($text, 'Space', "The expected value is (Space). Got ($text)");
=begin	
	my $array = [' Space ', 'Test ', ' Apple Computer'];
	$array = RGTools::RGIO::standardize_text_value(-text=>$array);
	my $expected = ['Space', 'Test', 'Apple Computer'];
	is_deeply($array, $expected, 'Trimming spaces for array');
	
	my $text1;
	$text1 = &RGTools::RGIO::standardize_text_value(-text=>$text1);
	is_deeply($text1, undef, "The expected value is (). Got ($text1)");
=cut	
	my $text1 = '';
	$text1 = &RGTools::RGIO::standardize_text_value($text1);
	is_deeply($text1, '', "The expected value is (). Got ($text1)");
	
	my $text2;
	$text2 = &RGTools::RGIO::standardize_text_value($text2);
	is_deeply($text2, undef, "The expected value is undef. Got ($text2)");

	my $array1 = ['', NULL, ' Apple Computer'];
	$array1 = RGTools::RGIO::standardize_text_value($array1);
	my $expected1 = ['', NULL, 'Apple Computer'];
	is_deeply($array1, $expected1, 'Trimming spaces for array1');
	print Dumper $array1;	
    }
}

## END of TEST ##

ok( 1 ,'Completed RGIO test');

exit;
