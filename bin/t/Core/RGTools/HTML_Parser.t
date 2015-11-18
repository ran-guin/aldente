#!/usr/bin/perl

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";

use Test::Simple no_plan;
use Test::More;
use Test::Differences;
use Data::Dumper;
use RGTools::HTML_Parser;
use RGTools::Table_Content_Parser;
use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);
my $method = $opt_method; 
my $obj = new HTML_Parser();
my $result;
my @fields;
my $file_name = $FindBin::RealBin . "/Summary.htm";
use_ok("RGTools::HTML_Parser");

if ( !$method || $method =~ /\bextract_data\b/ ) {

    can_ok("HTML_Parser", 'extract_data');
    {
       # my $string = "<html><tr>wah</tr></html>";
       # $string =~ s/<tr>(\s)+<\/tr>//;
       # print "1: $string\n";
       # my $string = "<html><tr>\n\n</tr></html>";
       # $string =~ s/<tr>(\s)+<\/tr>//;
       # print "2: $string\n";
        
        $fields[0] = 'Field 1';

        # case 1: if the function can not open the html_file specified, it will return undef
        #commented out because the script dies if it can't open the specified file   
        #	($result) = $obj->extract_data(-file_name=>"Smiley.htm",-table=>'Lane 8',-fields=>['Field 1']);
	    #    eq_or_diff($result,undef,"extract_data can't open the specified html_file");

#----------------------------- uncomment when done
        # case 2: if the requested field can not be found in the table, the field value will be undef
       	($result) = $obj->extract_data(-file_name=>$file_name,-table=>'Lane Results Summary',-fields=>\@fields);
    	is($result,undef,"requested field can not be found in the table");
        
        # case 3: if the requested field can be found in the table, the field value will be the value in the table
        $fields[0] = 'Run Folder';
       ($result) = $obj->extract_data(-file_name=>$file_name,-table=>'Chip Summary',-fields=>\@fields,-table_type=>1);
    	my $run_folder = $result->[0]{'Run Folder'};
        
       is($run_folder,'PHIX14..11.L8',"requested field can be found in the table");
            

        # case 4: test extract Lane Parameter Summary.  Horizontal table w/ multiple values for each fields
        @fields = ('Lane','Sample ID','Sample Target','Sample Type','Length');
        
	    ($result) = $obj->extract_data(-file_name=>$file_name,-table=>'Lane Parameter Summary',-fields=>\@fields,-table_type=>0);
    	my $expected_result = [{'Lane'=>'1','Sample ID'=>'unknown','Sample Target'=>undef,'Sample Type'=>'ELAND','Length'=>'35'},{'Lane'=>'2','Sample ID'=>'unknown','Sample Target'=>undef,'Sample Type'=>'ELAND','Length'=>'35'},{'Lane'=>'3','Sample ID'=>'unknown','Sample Target'=>undef,'Sample Type'=>'ELAND','Length'=>'35'},{'Lane'=>'4','Sample ID'=>'unknown','Sample Target'=>undef,'Sample Type'=>'ELAND','Length'=>'35'},{'Lane'=>'5','Sample ID'=>'unknown','Sample Target'=>undef,'Sample Type'=>'ELAND','Length'=>'35'},{'Lane'=>'6','Sample ID'=>'unknown','Sample Target'=>undef,'Sample Type'=>'ELAND','Length'=>'35'},{'Lane'=>'7','Sample ID'=>'unknown','Sample Target'=>undef,'Sample Type'=>'ELAND','Length'=>'35'},{'Lane'=>'8','Sample ID'=>'unknown','Sample Target'=>'phi_plus_SNPs.fa','Sample Type'=>'DEFAULT','Length'=>'27'}];
        eq_or_diff($result,$expected_result,"test extract Lane Parameter Summary"); #is won't work

        # case 5: test Expanded Lane.  Horizontal table w/ 2 rows of column headers
        $#fields = -1;
        @fields = ('% Phasing','% Prephasing');
        
	    ($result) = $obj->extract_data(-file_name=>$file_name,-table=>'Expanded Lane Summary',-fields=>\@fields,-skip=>1,-table_type=>0);
#works
 #       print "what we get: ".Dumper($result)."\n";
#        print "$result->[0]->{'% Phasing'},$result->[0]->{'% Prephasing'}\n";

        $expected_result = [{'% Phasing'=>'0.6000','% Prephasing'=>'0.3100'}];
        eq_or_diff($result,$expected_result,"test extract Expanded Lane Summary");
#die();

#TC 6 complicated case do later
    #    $#fields = -1;
     #   @fields = ('% Phasing','% Prephasing');
        
	#    ($result) = $obj->extract_data(-file_name=>'Summary1.htm',-table=>'Table 1',-fields=>\@fields,-table_type=>1,-skip=>1);
    #    $expected_result = [{'% Phasing'=>'0.6','% Prephasing'=>'0.31'}];
    #    eq_or_diff($result,$expected_result,"TC 6 test extract Expanded Lane Summary");

    }   
}

if ( !$method || $method =~ /\b_get_field_indices_by_col\b/ ) {

    can_ok("HTML_Parser", '_get_field_indices_by_col');
    {   #1 row w/ 2 col
        $TCP_hash = [ {'rows' => [ {'cells'=>[{'data'=>'Lane Info'},{'data'=>'% Phasing'} ]}]}];

        # case 1: if the function can not find the fields in TCP_hash, it will return undef
    	@fields = qw /field/;

        ($result) = $obj->_get_field_indices_by_col(-hash_ref=>\$TCP_hash,-fields=>\@fields);
        eq_or_diff($result,[],"_get_field_indices_by_col can't find the fields in TCP_hash");

        $fields[0] = '% Phasing';
        # case 2: requested field can be found in the TCP_hash
    	($result) = $obj->_get_field_indices_by_col(-hash_ref=>\$TCP_hash,-fields=>\@fields);
        eq_or_diff($result->[0],1,"_get_field_indices_by_col found existing fields in TCP_hash");
        
        #     case 3: requested field located on 2nd row         rows w/ 1 col
        $TCP_hash = [ {'rows' => [{'cells'=>[{'data'=>'Lane Info'}]},{'cells'=>[{'data'=>'% Phasing'}]} ] } ];

    	($result) = $obj->_get_field_indices_by_col(-hash_ref=>\$TCP_hash,-fields=>\@fields);
	    eq_or_diff($result->[0],undef,"_get_field_indices_by_col can't find the fields in the 1st row of the table");

        # case 4: requested field located on 2nd row with the skip parameter set to 1
	    ($result) = $obj->_get_field_indices_by_col(-hash_ref=>\$TCP_hash,-fields=>\@fields,-skip=>1);
	    eq_or_diff($result->[0],0,"requested field located on 2nd row w/ skip=1");
	
    }
}


if ( !$method || $method =~ /\b_get_field_indices_by_row\b/ ) {

    can_ok("HTML_Parser", '_get_field_indices_by_row');
    {   
	
        #2 rows w/ 1 col
        $TCP_hash = [ {'rows' => [{'cells'=>[{'data'=>'Lane Info'}]},{'cells'=>[{'data'=>'% Phasing'}]} ] } ];
        # case 1: if the function can not find the fields in TCP_hash, it will return undef
    	@fields = qw /field/;

        ($result) = $obj->_get_field_indices_by_row(-hash_ref=>\$TCP_hash,-fields=>\@fields);
        eq_or_diff($result,[],"_get_field_indices_by_row can't find the fields in TCP_hash");

        $fields[0] = '% Phasing';
        # case 2: requested field can be found in the TCP_hash
    	($result) = $obj->_get_field_indices_by_row(-hash_ref=>\$TCP_hash,-fields=>\@fields);

        eq_or_diff($result->[0],1,"_get_field_indices_by_row found existing fields in TCP_hash");
        
	    #1 row w/ 2 col
        $TCP_hash = [ {'rows' => [ {'cells'=>[{'data'=>'Lane Info'},{'data'=>'% Phasing'} ]}]}];
        # case 3: requested field located on 2nd row
    	($result) = $obj->_get_field_indices_by_row(-hash_ref=>\$TCP_hash,-fields=>\@fields);
	    eq_or_diff($result->[0],undef,"_get_field_indices_by_row can't find the fields in the 1st column of the table");

        # case 4: requested field located on 2nd row with the skip parameter set to 1
	    ($result) = $obj->_get_field_indices_by_row(-hash_ref=>\$TCP_hash,-fields=>\@fields,-skip=>1);
	    eq_or_diff($result->[0],0,"requested field located on 2nd column w/ skip=1");
	
    }
}

if ( !$method || $method =~ /\b_populate_hash\b/ ) {

    can_ok("HTML_Parser", '_populate_hash');
    {   #1 row w/ 2 col
        $TCP_hash = [ 
			{'rows' => [ 
				{'cells'=>[{'data'=>'Lane'},{'data'=>'Clusters'} ]}, 
				{'cells'=>[{'data'=>'8'},{'data'=>'39683+/-1050'}]}
				]
			}	 
			];

        # case 1: if the function can not find the fields in TCP_hash, it will return undef
    	@fields = qw /Lane Clusters/;
	    my @indices = (0,1);
        ($result) = $obj->_populate_hash(-hash_ref=>\$TCP_hash,-fields=>\@fields,-indices=>\@indices,-skip=>1,-table_type=>0);
         
         $expected_result = [ {'Lane'=>'8','Clusters'=>'39683+/-1050'}];

        eq_or_diff($result,$expected_result,"_populate_hash can find the fields in TCP_hash (Horizontal table, multiple fields, Single Value for each field)");
        # case 2: requested field is in 2nd row but the skip parameter is not set (i.e. start at row 1).  Function will return an erroroneous element in the hash.  3 rows 1 column
        $TCP_hash = [ 
			{'rows' => [ 
				{'cells'=>[{'data'=>'Lane Info'}]},
				{'cells'=>[{'data'=>'Lane'}]}, 
				{'cells'=>[{'data'=>'8'}]}
				]
			}	 
			];


        @fields = qw /Lane/;
	    my @indices = (0);
    
        $expected_result = [{'Lane' => 'Lane'},{'Lane' => '8'}];

        ($result) = $obj->_populate_hash(-hash_ref=>\$TCP_hash,-fields=>\@fields,-indices=>\@indices,-skip=>1,-table_type=>0);
	    eq_or_diff($result,$expected_result,"_populate_hash can't find the fields in TCP_hash (skip parameter not set)");


	    #case 3: same as case 2 and now set skip=2 (Start at row 2)
        ($result) = $obj->_populate_hash(-hash_ref=>\$TCP_hash,-fields=>\@fields,-indices=>\@indices,-skip=>2,-table_type=>0);
        $expected_result = [{'Lane' => '8'}];
    	eq_or_diff($result,$expected_result,"_populate_hash can find the fields in TCP_hash (skip parameter is set)");


        # case 4: horizontal table, multiple values for each fields.  3 rows 1 column
        $TCP_hash = [ 
			{'rows' => [ 
				{'cells'=>[{'data'=>'Lane'}]},
				{'cells'=>[{'data'=>'1'}]}, 
				{'cells'=>[{'data'=>'2'}]}
				]
			}	 
			];
        ($result) = $obj->_populate_hash(-hash_ref=>\$TCP_hash,-fields=>\@fields,-indices=>\@indices,-skip=>1,-table_type=>0);
	    $expected_result = [{'Lane'=>'1'},{'Lane'=>'2'}];
        eq_or_diff($result,$expected_result,"horizontal table, multiple values for each fields");
 
#--------------------------------------

       # case 5: horizontal table, multiple values for each fields.  3 rows, 1st row 2 col, 2 and 3 rd, 4 col
        $TCP_hash = [ 
			{'rows' => [ 
				{'cells'=>[{'data'=>'Lane Info'},{'data'=>'Phasing Info'}]},
				{'cells'=>[{'data'=>'Lane'},{'data'=>'Clusters'},{'data'=>'% Phasing'},{'data'=>'% Prephasing'}]}, 
				{'cells'=>[{'data'=>'8'},{'data'=>'39683'},{'data'=>'0.6000'},{'data'=>'0.3100'}]}
				]
			}	 
			];
            @fields = ('% Phasing', '% Prephasing');
            @indices = (2,3);
        ($result) = $obj->_populate_hash(-hash_ref=>\$TCP_hash,-fields=>\@fields,-indices=>\@indices,-skip=>2,-table_type=>0);
    	$expected_result = [{'% Phasing'=>'0.6000','% Prephasing'=>'0.3100'}];
        eq_or_diff($result,$expected_result,"case 4a:horizontal table, multiple values for each fields");




#-----------------------------------

        #case 6: horizontal table, multiple fields w/ single val each.  2 rows w/ 1 col
        $TCP_hash = [ 	{'rows' => [{'cells'=>[{'data'=>'Machine'},{'data'=>'Unknown'} ]}, 	{'cells'=>[{'data'=>'Run Folder'},{'data'=>'PHIX14.11.L8'}]}	]	}	 ];
        @indices = (0,1);
        @fields = ('Machine', 'Run Folder');

        ($result) = $obj->_populate_hash(-hash_ref=>\$TCP_hash,-fields=>\@fields,-indices=>\@indices,-skip=>1,-table_type=>1);
    	$expected_result = [{'Machine'=>'Unknown','Run Folder'=>'PHIX14.11.L8'}];
        eq_or_diff($result,$expected_result,"vertical table, single values for each fields");


        #case 7:
        $TCP_hash = [{'rows' => [ {'cells'=>[{'data'=>'Machine'},{'data'=>'Machine1'},{'data'=>'Machine2'} ]}, {'cells'=>[{'data'=>'Run Folder'},{'data'=>'Run Folder 1'},{'data'=>'Run Folder 2'}]}]}	 ];
        ($result) = $obj->_populate_hash(-hash_ref=>\$TCP_hash,-fields=>\@fields,-indices=>\@indices,-skip=>1,-table_type=>1);
    	$expected_result = [{'Machine'=>'Machine1','Run Folder'=>'Run Folder 1'},{'Machine'=>'Machine2','Run Folder'=>'Run Folder 2'}];
        eq_or_diff($result,$expected_result,"vertical table, multiple values for each fields");

  #     case 8: testing the skip flag w/ vertical table.  first w/o it being set, the result will be empty
        $TCP_hash = [ {'rows' => [ {'cells'=>[{'data'=>'header'},{'data'=>'header1'},{'data'=>'value'} ]} ] } ];	
    	@indices = (0);
        $#fields = -1;
        @fields = qw/header1/;
        $expected_result = [{'header1'=>'header1'},{'header1'=>'value'}];

    	($result) = $obj->_populate_hash(-hash_ref=>\$TCP_hash,-fields=>\@fields,-indices=>\@indices,-skip=>1,-table_type=>1);
	    eq_or_diff($result,$expected_result,"_populate_hash can't find the fields in the 1st column of the table");


        # case 9: testing the skip flag w/ vertical table.  now it 's being set, the result will be not empty
    	($result) = $obj->_populate_hash(-hash_ref=>\$TCP_hash,-fields=>\@fields,-indices=>\@indices,-skip=>2,-table_type=>1);
	    $expected_result = [{'header1'=>'value'}];

    	eq_or_diff($result,$expected_result,"requested field located on 2nd column w/ skip=2");
	
        $TCP_hash = [ {'rows' => [ {'cells'=>[{'data'=>'header'},{'data'=>'header1'},{'data'=>'value'} ]} ] } ];	
    }
}
#if ( !$method || $method =~ /\b\b/ ) {

#    can_ok("RGTools::HTML_Parser", undef);
#    {
#    }
#}
ok(1,'Completed HTML_Parser test');
exit;
