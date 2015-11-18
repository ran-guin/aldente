#!/usr/local/bin/perl

###############################
# Site_Map.pl
###############################

use strict;

use DBI;
use CGI qw(:standard);

#use lib "/usr/local/ulib/prod/perl5";
#use Barcode;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../custom/GSC/modules";

use vars qw($html_header %Configs $homelink $URL_address $banner $Settings $dbc $java_header);

use SDB::CustomSettings;
use SDB::Errors;
use RGTools::RGIO;

use alDente::Help;
use alDente::SDB_Defaults;  
use alDente::Web;

use RGTools::Barcode;
use SDB::DBIO;

my $login_name = 'viewer';
my $login_pass = 'viewer';
my $host = $Configs{SQL_HOST};
my $dbase = $Configs{DATABASE};

    
use alDente::Site_Map;

my $manual = "limsmaster/SDB/docs/out/";
    
print "Content-type: text/html\n\n";
print $java_header;
print <<JAVASCRIPT;                                    ### imported from Default File (SDB_Defaults.pm)
<!------------ Style Sheets ------------->

<LINK rel=stylesheet type='text/css' href='/SDB/css/FormNav.css'>

<LINK rel=stylesheet type='text/css' href='/SDB/css/calendar.css'>

<LINK rel=stylesheet type='text/css' href='/SDB/css/style.css'>

<LINK rel=stylesheet type='text/css' href='/SDB/css/colour.css'>

<!------------ JavaScript ------------->

<script src='/SDB/js/FormNav.js'></script>

<script src='/SDB/js/calendar.js'></script>

<script src='/SDB/js/SDB.js'></script>

<script src='/SDB/js/onmouse.js'></script>

<script src='/SDB/js/json.js'></script>

<script src='/SDB/js/Prototype.js'></script>

<script src='/SDB/js/alttxt.js'></script>

<script src='/SDB/js/DHTML.js'></script>

<script src='/SDB/js/jquery.js'></script>
<script type="text/javascript">
jQuery.noConflict();
</script>
<script src='/SDB/js/alDente.js'></script>

<script src='/SDB/js/scrollbar.js'></script>


JAVASCRIPT



if (param('Element')) {
    my $element = param('Element');
    my $dir = "$Configs{web_dir}/docs/out";
    
    if (-e "$dir/$element") {
        print `cat $dir/$element`;
    }
    else {
        print "$dir/$element NOT FOUND";
    }
}
else {
    my $link = param('Link');
    my $mode = param('Database_Mode');
    my $Map = new alDente::Site_Map(-link=>$link, -mode=>$mode);
    my $chapter;
    print $Map->alDente::Site_Map::site_map('Site Map');
    print $Map->alDente::Site_Map::site_map('Help Map');

}

exit;


