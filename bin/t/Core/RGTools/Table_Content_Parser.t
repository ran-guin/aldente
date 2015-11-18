#!/usr/local/bin/perl

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";

#use Test;
use Test::Simple no_plan;
use Test::More;
use Test::Differences;

use Data::Dumper;
#DISPLAY date of test and version #
#BEGIN { plan tests => 34 }

## If in @INC, should succeed
use RGTools::Table_Content_Parser;

use_ok("RGTools::Table_Content_Parser");
if ( !$method || $method =~ /\bparse\b/ ) {

    can_ok("Table_Content_Parser", 'parse');
    {

        ## Test object creation

        my $obj = new Table_Content_Parser();
#       my $obj = RGTools::Table_Content_Parser->new();


        ## Test basic functionality. Create a table, and make sure parsing it returns
        ## the correct values to the callback.


        $table_caption  = 'This is a caption';
        $table_content1 = 'This is table cell content 1';
        $table_content2 = 'This is table cell content 2';
        $table_content3 = '<a href="SomeLink">This is table cell content 3, a link</a>';
        $table_content4 = 'Some more text wrapping <a href="SomeLink">This is table cell content 4</a> a link.';
        $header_text = 'Header text';

$html = qq{
<html>
<head>
</head>
<body>
<h1>Table 1</h1>
<TABLE id='foo' name='bar' border='0'>
<CAPTION id='test'>$table_caption</CAPTION>
<th>$header_text</th>
<tr><td>$table_content1</td></tr>
<tr><td>$table_content2</td></tr>
<tr><td>$table_content3</td></tr>
<tr><td>$table_content4</td></tr>
</table>
</body>
</html>
};
        $tables = $obj->parse($html);
        eq_or_diff (defined($tables),1, "parsing an html file which has a table");

        
        $html = "<html></html>";
        $tables = $obj->parse($html);
        eq_or_diff ($tables,undef,"parsing an html file which has no table");
    
    }
}
ok(1,'Completed Table_Content_Parser test');
exit;
