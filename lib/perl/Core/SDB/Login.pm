###################################################################################################################################
# LampLite::Login.pm
#
# Basic login functionality
#
###################################################################################################################################
package SDB::Login;

use base LampLite::Login;

use strict;

## Standard modules ##
use CGI qw(:standard);
use Time::localtime;

## Local modules ##
use RGTools::RGIO;

use LampLite::Bootstrap();

my $BS = new Bootstrap;


1;
