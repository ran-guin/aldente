###################################################################################################################################
# alDente::Site_Admin_Views.pm
#
# View in the MVC structure
# 
# Contains the business logic and data of the application
#
###################################################################################################################################
package alDente::Site_Admin_Views;

use base SDB::Site_Admin_Views;
use strict;
use alDente::Site_Admin;

my $q = new LampLite::CGI;

use RGTools::RGIO;   ## include standard tools

1;


