###################################################################################################################################
#
# Wrapper for objects for standard <class>_Views method.
#
# Methods should include the line:
# use base alDente::Object_Views if it is to be defined as an Object.
#
###################################################################################################################################
package alDente::Object;

use base SDB::DB_Object;
use strict;
use CGI qw(:standard);

use RGTools::RGIO;

1;
