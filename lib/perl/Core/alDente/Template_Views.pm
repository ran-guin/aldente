###################################################################################################################################
# alDente::Template_Views.pm
#
# Interface generating methods for the Template MVC  (associated with Template.pm, Template_App.pm)
#
###################################################################################################################################
package alDente::Template_Views;
use base SDB::Template_Views;
use strict;

## Standard modules ##
use CGI qw(:standard);

## Local modules ##

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

use alDente::Template;

## alDente modules


1;
