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
use Test::Differences;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use RGTools::Conversion;
############################
############################################################
use_ok("RGTools::Conversion");

if ( !$method || $method=~/\bsubtract_amounts\b/ ) {
    can_ok("RGTools::Conversion", 'subtract_amounts');
    {
        ## <insert tests for subtract_amounts method here> ##
    }
}

if ( !$method || $method=~/\badd_amounts\b/ ) {
    can_ok("RGTools::Conversion", 'add_amounts');
    {
        ## <insert tests for add_amounts method here> ##
	my ($v, $u) = RGTools::Conversion::add_amounts( -qty1 => 0, -units1 => 'l', -qty2 => 1, -units2 => 'ml', -check_negative => 1 );
	is($v, 1);
	is($u, 'ml');
    }
}

if ( !$method || $method=~/\bget_amount_units\b/ ) {
    can_ok("RGTools::Conversion", 'get_amount_units');
    {
        ## <insert tests for get_amount_units method here> ##
    }
}

if ( !$method || $method=~/\bget_base_units\b/ ) {
    can_ok("RGTools::Conversion", 'get_base_units');
    {
        ## <insert tests for get_base_units method here> ##
    }
}

if ( !$method || $method=~/\bunpack_to_array\b/ ) {
    can_ok("RGTools::Conversion", 'unpack_to_array');
    {
        ## <insert tests for unpack_to_array method here> ##
    }
}

if ( !$method || $method=~/\bextract_range\b/ ) {
    can_ok("RGTools::Conversion", 'extract_range');
    {
        ## <insert tests for extract_range method here> ##
        my $result = extract_range( "B02-B05" );
        is( $result, 'B02,B03,B04,B05', 'extract_range' );
    }
}

if ( !$method || $method=~/\bpad_Distribution\b/ ) {
    can_ok("RGTools::Conversion", 'pad_Distribution');
    {
        ## <insert tests for pad_Distribution method here> ##
    }
}

if ( !$method || $method=~/\bconvert_to_regexp\b/ ) {
    can_ok("RGTools::Conversion", 'convert_to_regexp');
    {
        ## <insert tests for convert_to_regexp method here> ##
    }
}

if ( !$method || $method=~/\bconvert_to_condition\b/ ) {
    can_ok("RGTools::Conversion", 'convert_to_condition');
    {
        ## <insert tests for convert_to_condition method here> ##
        is(convert_to_condition('12-15'),'( BETWEEN 12 AND 15)','12-15');
        is(convert_to_condition('12-15',-range_limit=>2),'( = \'12-15\')','12-15 (limit range to 2)');
        is(convert_to_condition('12-14',-range_limit=>2),'( BETWEEN 12 AND 14)','12-14 (limit range to 2)');
        is(convert_to_condition('14-12'),"( = '14-12')",'14-12');
        is(convert_to_condition('1|2|3'),"( IN ('1','2','3'))",'1|2|3');
        is(convert_to_condition('A|B|C'),"( IN ('A','B','C'))",'A|B|C');

        is(convert_to_condition("A[1-3],B[2-4],C3"),"( In ('A[1-3],B[2-4],C3','A1','A2','A3','B2','B3','B4','C3'))", " 'A[1-3],B[2-4],C3'");
    }
}

if ( !$method || $method=~/\bconvert_units\b/ ) {
    can_ok("RGTools::Conversion", 'convert_units');
    {
        ## <insert tests for convert_units method here> ##
    }
}

if ( !$method || $method=~/\bnormalize_time\b/ ) {
    can_ok("RGTools::Conversion", 'normalize_time');
    {
        ## <insert tests for normalize_time method here> ##
    }
}

if ( !$method || $method=~/\bend_of_day\b/ ) {
    can_ok("RGTools::Conversion", 'end_of_day');
    {
        ## <insert tests for end_of_day method here> ##
    }
}

if ( !$method || $method=~/\bconvert_to_hours\b/ ) {
    can_ok("RGTools::Conversion", 'convert_to_hours');
    {
        ## <insert tests for convert_to_hours method here> ##
    }
}

if ( !$method || $method=~/\bweek_days\b/ ) {
    can_ok("RGTools::Conversion", 'week_days');
    {
        ## <insert tests for week_days method here> ##
    }
}

if ( !$method || $method=~/\bconvert_to_mils\b/ ) {
    can_ok("RGTools::Conversion", 'convert_to_mils');
    {
        ## <insert tests for convert_to_mils method here> ##
    }
}

if ( !$method || $method=~/\bformat_well\b/ ) {
    can_ok("RGTools::Conversion", 'format_well');
    {
        ## <insert tests for format_well method here> ##
    }
}

if ( !$method || $method=~/\bSQL_well\b/ ) {
    can_ok("RGTools::Conversion", 'SQL_well');
    {
        ## <insert tests for SQL_well method here> ##
    }
}

if ( !$method || $method=~/\bSQL_hours\b/ ) {
    can_ok("RGTools::Conversion", 'SQL_hours');
    {
        ## <insert tests for SQL_hours method here> ##
    }
}

if ( !$method || $method=~/\btext_SQL_date\b/ ) {
    can_ok("RGTools::Conversion", 'text_SQL_date');
    {
        ## <insert tests for text_SQL_date method here> ##
    }
}

if ( !$method || $method=~/\bconvert_date\b/ ) {
    can_ok("RGTools::Conversion", 'convert_date');
    {
        ## <insert tests for convert_date method here> ##
        is(convert_date('2010-11-22 12:44:33', 'YYYY/MM'), '2010/11','time to YYYY/MM');
	is(convert_date('20110203123456','Simple'), 'Feb-03-2011 12:34:56', 'timestamp to Simple');
	is(convert_date('2010-11-22 12:44:33','YYYY Mon DD (HOUR:MINUTE)'), '2010 Nov 22 (12:44)', 'YYYY Mon DD (HOUR:MINUTE)'); 
        is(convert_date('Nov/22/2010 12:44:33', 'YYYY-MM-DD'), '2010-11-22','understood Nov/22/2010');
        is(convert_date('2010-NOV-22 12:44:33', 'YYYY-MM-DD'), '2010-11-22','understood 2010-NOV-22');
    }
}

if ( !$method || $method=~/\bconvert_time\b/ ) {
    can_ok("RGTools::Conversion", 'convert_time');
    {
        ## <insert tests for convert_time method here> ##
	is( convert_time('1:25'), '1:25',   'convert time: H:MM' );
	is( convert_time('2.5'),  '00:2:5', 'convert time: M.S' );
	is( convert_time('2'),    '0:0:2',  'convert time: S' );
	is( convert_time( 3667, 's' ), '1:1:7',  'convert time: N,s' );
	is( convert_time( 65,   'm' ), '1:5:00', 'convert time: N,m' );
	is( convert_time('65 min'), '1:5:00', 'convert time: N min' );
    }
}

if ( !$method || $method=~/\bSQL_day\b/ ) {
    can_ok("RGTools::Conversion", 'SQL_day');
    {
        ## <insert tests for SQL_day method here> ##
    }
}

if ( !$method || $method=~/\bSQL_weekdays\b/ ) {
    can_ok("RGTools::Conversion", 'SQL_weekdays');
    {
        ## <insert tests for SQL_weekdays method here> ##
    }
}

if ( !$method || $method=~/\bconvert_HofA_to_AofH\b/ ) {
    can_ok("RGTools::Conversion", 'convert_HofA_to_AofH');
    {
        ## <insert tests for convert_HofA_to_AofH method here> ##
    }
}

if ( !$method || $method=~/\bget_units\b/ ) {
    can_ok("RGTools::Conversion", 'get_units');
    {
        ## <insert tests for get_units method here> ##
    }
}

if ( !$method || $method=~/\bnormalize_units\b/ ) {
    can_ok("RGTools::Conversion", 'normalize_units');
    {
        ## <insert tests for normalize_units method here> ##
    }
}

if ( !$method || $method=~/\bsimplify_units\b/ ) {
    can_ok("RGTools::Conversion", 'simplify_units');
    {
        ## <insert tests for simplify_units method here> ##
    }
}

if ( !$method || $method=~/\bGet_Best_Units\b/ ) {
    can_ok("RGTools::Conversion", 'Get_Best_Units');
    {
        ## <insert tests for Get_Best_Units method here> ##
	my $amount;
	my $units;
	($amount, $units) = Get_Best_Units(-amount=>4000, -units=>'g');
	is($amount, 4);
	is($units, 'kg');
	($amount, $units) = Get_Best_Units(-amount=>4000, -units=>'ng/uL');
	is($amount, 4);
	is($units, 'ug/uL');
	($amount, $units) = Get_Best_Units(-amount=>0.004, -units=>'kg');
	is($amount, 4);
	is($units, 'g');

	#testing for list of amount and units
	($amount, $units) = Get_Best_Units(-amount=>"0.001,0.002,0.001", -units=>'kg,kg,kg');
	is($amount, "1,2,1");
	is($units, 'g,g,g');
	($amount, $units) = Get_Best_Units(-amount=>"4000,5", -units=>'ng/ul,ng/ul');
	is($amount, "4,5");
	is($units, 'ug/ul,ng/ul');

	#for list of amount and units not equal, let it behaves as before for now
	($amount, $units) = Get_Best_Units(-amount=>"4000,5", -units=>'ng/ul');
	is($amount, "4");
	is($units, 'ug/ul');
	($amount, $units) = Get_Best_Units(-amount=>"10", -units=>'ul,ul,ul');
	is($amount, "10");
	is($units, '');

    }
}

if ( !$method || $method=~/\bget_number\b/ ) {
    can_ok("RGTools::Conversion", 'get_number');
    {
        ## <insert tests for get_number method here> ##
    }
}

if ( !$method || $method=~/\bnumber\b/ ) {
    can_ok("RGTools::Conversion", 'number');
    {
        ## <insert tests for number method here> ##
    }
}

if ( !$method || $method=~/\bConvert_Case\b/ ) {
    can_ok("RGTools::Conversion", 'Convert_Case');
    {
        ## <insert tests for Convert_Case method here> ##
    }
}

if ( !$method || $method=~/\bCustom_Convert_Units\b/ ) {
    can_ok("RGTools::Conversion", 'Custom_Convert_Units');
    {
        ## <insert tests for Custom_Convert_Units method here> ##
    }
}

if ( !$method || $method=~/\bconvert_volume\b/ ) {
    can_ok("RGTools::Conversion", 'convert_volume');
    {
        ## <insert tests for Custom_Convert_Units method here> ##
        my $vol = join '', RGTools::Conversion::convert_volume('20','ml','ul');
        is($vol,'20000ul','convert ml to ul');

        $vol = join '', RGTools::Conversion::convert_volume('1000.000','mL','ul');
        is($vol,'1000000ul','convert ml to ul');

        $vol = join '', RGTools::Conversion::convert_volume('20','ul','ml');
        is($vol,'0.02ml','convert ul to ml');

        $vol = join '', RGTools::Conversion::convert_volume('20','mg','ul');
        is($vol,'20mg','convert mg to ul');
    }
}

if ( !$method || $method=~/\bwiki_to_HTML\b/ ) {
    can_ok("RGTools::Conversion", 'wiki_to_HTML');
    {
        ## <insert tests for wiki_to_HTML method here> ##
    }
}

if ( !$method || $method=~/\bconvert_tags\b/ ) {
    can_ok("RGTools::Conversion", 'convert_tags');
    {
        ## <insert tests for convert_tags method here> ##
    }
}

if ( !$method || $method=~/\bescape_regex_special_chars\b/ ) {
    can_ok("RGTools::Conversion", 'convert_tags');
    {
        my $result;

        $result = &RGTools::Conversion::escape_regex_special_chars('ab (cd)');
        is ($result , 'ab \(cd\)','Passed "ab (cd)"');

        $result = &RGTools::Conversion::escape_regex_special_chars('ab (cd)|');
        is ($result , 'ab \(cd\)\|','Passed "ab (cd)|"');

        $result = &RGTools::Conversion::escape_regex_special_chars('ab ((cd)|');
        is ($result , 'ab \(\(cd\)\|','Passed "ab ((cd)|"');

        $result = &RGTools::Conversion::escape_regex_special_chars('ab (cd)',-preserve=>'(');
        is ($result , 'ab (cd\)','Passed "ab (cd)", preserve (');

        $result = &RGTools::Conversion::escape_regex_special_chars('ab$$ (cd)',-preserve=>'()');
        is ($result , 'ab\$\$ (cd)','Passed "ab$$ (cd)", preserve ()');

        $result = &RGTools::Conversion::escape_regex_special_chars('ab$$ (cd)',-preserve=>'$');
        is ($result , 'ab$$ \(cd\)','Passed "ab$$ (cd)", preserve $');

    }
}

if ( !$method || $method=~/\bHTML_to_xml\b/ ) {
    can_ok("RGTools::Conversion", 'HTML_to_xml');
    {
        ## <insert tests for HTML_to_xml method here> ##
    }
}

if ( !$method || $method=~/\bwiki_to_xml\b/ ) {
    can_ok("RGTools::Conversion", 'wiki_to_xml');
    {
        ## <insert tests for wiki_to_xml method here> ##
    }
}

if ( !$method || $method =~ /\bwildcard_to_SQL\b/ ) {
    can_ok("RGTools::Conversion", 'wildcard_to_SQL');
    {
        ## <insert tests for wildcard_to_SQL method here> ##
    }
}

if ( !$method || $method =~ /\btranslate_date\b/ ) {
    can_ok("RGTools::Conversion", 'translate_date');
    {
        ## <insert tests for translate_date method here> ##
    }
}

if ( !$method || $method =~ /\bescape_regex_special_chars\b/ ) {
    can_ok("RGTools::Conversion", 'escape_regex_special_chars');
    {
        ## <insert tests for escape_regex_special_chars method here> ##
    }
}

if ( !$method || $method =~ /\bwiki_to_xml_old\b/ ) {
    can_ok("RGTools::Conversion", 'wiki_to_xml_old');
    {
        ## <insert tests for wiki_to_xml_old method here> ##
    }
}

if ( !$method || $method =~ /\brecast_value\b/ ) {
    can_ok("RGTools::Conversion", 'recast_value');
    {
        ## <insert tests for recast_value method here> ##
        is_deeply([Dumper recast_value('1','int')],[Dumper 1],"recast '1' to 1");
        is_deeply([Dumper recast_value('1','text')],[Dumper '1'],"recast '1' to 1");
        is_deeply([Dumper recast_value(undef,'int')],[Dumper undef],"recast undef to undef");
   
        is_deeply([Dumper recast_value(-value=>'',-type=>'int')],[Dumper 0],"recast '' to 0 for int");    
        is_deeply([Dumper recast_value(-value=>'',-type=>'int')],[Dumper 0],"recast '' to 0 for int");    
        is_deeply([Dumper recast_value(-value=>'',-type=>'text')],[Dumper ''],"recast '' to '' for text");    
        is_deeply([Dumper recast_value(-value=>undef,-type=>'int')],[Dumper undef],"recast undef for int to undef");    
        is_deeply([Dumper recast_value(0,'text')],[Dumper '0'],"recast 0 to '0' for text");    
        is_deeply([Dumper recast_value('0','text')],[Dumper '0'],"recast '0' to '0' for text");    
        is_deeply([Dumper recast_value(0,'int')],[Dumper 0],"recast 0 to 0 for int");    
        is_deeply([recast_value('Jan 3, 2011','date','SQL')],['2011-01-03'],"recast date");    
       
        ## NOTE Dumper cannot tell difference between 1.56 and '1.56'... ##
        is_deeply([Dumper recast_value(-value=>'1.56',-type=>'float')],[Dumper 1.56],"recast '1.56' to 1.56 for float");    
        is_deeply([Dumper recast_value(-value=>'1.56',-type=>'float')],[Dumper '1.56'],"recast '1.56' to 1.56 for float");    
        is_deeply([Dumper recast_value(-value=>'1.56',-type=>'int')],[Dumper 1],"recast '1.56' to 1 for int");    
        is_deeply([Dumper recast_value(-value=>1.56,-type=>'text')],[Dumper '1.56'],"recast 1.56 to '1.56' for test");    
        is_deeply([Dumper recast_value(-value=>'2.5.6',-type=>'float')],[Dumper '2.5.6'],"recast '2.5.6' to '2.5.' for text");    
    }
}

if ( !$method || $method =~ /\bconvert_HofA_to_HHofA\b/ ) {
    can_ok("RGTools::Conversion", 'convert_HofA_to_HHofA');
    {
        ## <insert tests for convert_HofA_to_HHofA method here> ##
    }
}

if ( !$method || $method =~ /\bget_standard_unit_bases\b/ ) {
    can_ok("RGTools::Conversion", 'get_standard_unit_bases');
    {
        ## <insert tests for get_standard_unit_bases method here> ##
    }
}

if ( !$method || $method =~ /\bconvert_file_path\b/ ) {
    can_ok("RGTools::Conversion", 'convert_file_path');
    {
        ## <insert tests for convert_file_path method here> ##
        my $result = RGTools::Conversion::convert_file_path( -from => 'unix', -to => 'windows', -path => '/projects/labinstruments/bioanalyzer/BA2100-4/DNA#5454_DNA 1000_DE20901540_2012-12-11_13-25-40.xad' );
        ok( $result eq '\projects\labinstruments\bioanalyzer\BA2100-4\DNA#5454_DNA 1000_DE20901540_2012-12-11_13-25-40.xad', 'convert_file_path from Unix to Windows' );

        my $result = RGTools::Conversion::convert_file_path( -from => 'windows', -to => 'linux', -path => '\projects\labinstruments\bioanalyzer\BA2100-4\DNA#5454_DNA 1000_DE20901540_2012-12-11_13-25-40.xad' );
        ok( $result eq '/projects/labinstruments/bioanalyzer/BA2100-4/DNA#5454_DNA 1000_DE20901540_2012-12-11_13-25-40.xad', 'convert_file_path from Windows to Linux' );
    }
}

## END of TEST ##

ok( 1 ,'Completed Conversion test');

exit;
