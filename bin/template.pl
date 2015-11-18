#!/usr/local/bin/perl

use Getopt::Long;

use vars qw($opt_ref $opt_module $opt_scope);

&GetOptions(
    'ref|r' => \$opt_ref,
    'module|m' => \$opt_module,
    'scope|s' => \$opt_scope,
);

if (!$scope || !$module) {
    print help();
    exit;
}


###########
sub help {
###########

    print <<USAGE;

Usage:
*******


Examples:
*********


USAGE

}
    
exit;

