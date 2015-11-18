#!/usr/local/bin/perl

use strict;
use warnings;

use FindBin;
use CGI;

use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../lib/perl/Core/RGTools";

use RGTools::RGIO;
use LampLite::Form;
use LampLite::Bootstrap;

print "Content-type: text/html\n\n";

my $q = new CGI;
my $BS = new Bootstrap;

my $path = $0;
$path =~s/(.*)\/(.*?)\.pl/$1\/\.\./;

my $debug = $q->param('Debug');   

print "Path: $path<P>";

print "Checking modules...<P>";
my @modules = $q->param('Module');
print "Module(s): ";
print Cast_List(-list=>\@modules, -to=>'OL');

my @directories = $q->param('Directory');

@directories = qw(RGTools LampLite SDB alDente Departments::GSC Departments::Healthbank);
print "Directory(s):\n";
print Cast_List(-list=>\@directories, -to=>'OL');

print "<hr>\n";

if (@directories) {
    foreach my $dir (@directories) {
        test_directory(-modules=>\@modules, -directory=>$dir);
    }
}

print "done.";
exit;

#####################
sub test_directory {
#####################
    my %args = @_;
    my $modules = $args{-modules};
    my $dir = $args{-directory};
  
    my $scope = 'Core';
    if ($dir =~/(.*)\:\:(.*)/) {
        $scope = $1;
        $dir = $2;
    }
    
    if ($dir) {
        my @files = split "\n", `ls $path/lib/perl/$scope/$dir`;

        print "<h2>Checking: $path/lib/perl/$scope/$dir/</h2>";
        print "(found " . int(@files) . " files in  $path/lib/perl/$scope/$dir)..<P>"; 
        foreach my $file (@files) {
            if ($file =~s /\.pm$//) {   
                if ($modules && ! grep /^$file$/, @$modules) { next }
                $file =~s/(.*)\/(.+)$/$2/;
                
                my $require = $dir . '::' . $file;
                my $ok = eval "require $require";
                
                use LampLite::HTML;
                print HTML_Dump "require $require", $ok;
                
                if (!$ok || $@) {
                    my $errors = $@;
                    $errors =~s/\n/<BR>/g;
                    print "FAILED $require<BR>\n";
                    print "$ok<BR>$errors<HR>\n";
                }
                elsif ($debug) { 
                    print "$require PASSED [$ok] $@<BR>"  
                }
            }
            else {
                if ($debug) { print "... skipping $file<BR>\n" }
            }
        }
    }
    
    return;
}

#############
sub prompt {
#############
    
my @choose_dirs;
my @dirs = qw(RGTools LampLite SDB alDente custom);
foreach my $dir (@dirs) {
    push @choose_dirs, $q->checkbox(-name=>'Directory', -label=>$dir, -value=>$dir);
}

my $Form = new LampLite::Form;
$Form->append('Module:', $q->textfield(-name=>'Module', -size=>20) );


my $choose = join '<BR>', @choose_dirs;
$Form->append('Directory:', $choose );
$Form->append('', $q->submit(-name=>'Test'));
return $Form->generate(-wrap=>1) . '<HR>';
}

