#!/usr/local/bin/perl

use strict;
use CGI qw(:standard);
use CGI qw(fatalsToBrowser);

print "Content-type: text/html\n\n";

#my $cmd = "touch '/home/sequence/www/htdocs/external_submissions/2004-06-14_11:24:50.361.381.modified'";
#print ">>>Trying '$cmd'<BR>";
#print `$cmd`;

my $id = param('ID');
if ($id =~/^\d+$/) {
    print "Killing $id...<BR>";

    my $cmd = "kill -9 $id";
    print ">>>Trying '$cmd'<BR>";
    print `$cmd`;
} else {
    print "'$id' is not a valid Process ID...Aborting.";
}

exit;
