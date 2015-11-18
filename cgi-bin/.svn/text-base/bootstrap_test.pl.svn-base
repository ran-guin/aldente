#!/usr/local/bin/perl

use strict;
use warnings;

use FindBin;

print "Content-type: text/html\n\n";

my $path = $FindBin::RealBin;
my $path = "./..";

use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use alDente::Config;
use LampLite::Bootstrap;
use SDB::HTML;
my $BS = new Bootstrap();

my $config_file = $FindBin::RealBin . '/../conf/personalize.cfg';
my $Setup = LampLite::Config->load_std_yaml_files(-files=>[$config_file]);

##############
my $Config_Module = 'SDB::Config';

my $Config = $Config_Module->new( -root => $FindBin::RealBin . '/..', -bootstrap => 1, -initialize=>$Setup);

print LampLite::HTML::initialize_page(-path=>$path, -css_files=>$Config->{css_files}, -js_files=>$Config->{js_files});    ## generate Content-type , body tags, load css & js files ... ##
print $BS->open(-width=>'90%');

# print LampLite::HTML::initialize_page( -path => "/$path", -css_files => $css_files, -js_files => $js_files, -suppress_content_type=>1, -style=>'padding-top:80px;');    ## generate Content-type , body tags, load css & js files ... ##
# print $BS->open();

my $version;

if ($path =~/\/(\w+?)\/cgi-bin/) {
    $version = $1;
}

if ($version) { $version = "SDB_" . $version }

 print $BS->test_page();

 print $BS->close();

print 'body content...';

print "</body>\n";
print "</html>\n";

exit;
