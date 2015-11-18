###################################################################################################################################
# SDB::Import.pm
#
# Model in the MVC structure
# 
# Contains the business logic and data of the application
#
###################################################################################################################################
package alDente::Import;

use base SDB::Import;

use strict;
use CGI qw(:standard);
use File::Copy;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## SDB modules

use vars qw( %Configs );

#####################
sub get_File_Link {
#####################
    my %args = filter_input(\@_,-args => 'file,title');
    my $file        = $args{-file};
    my $title       = $args{-title};
    my $url         = $Configs{URL_dir};
    my $project_dir = $Configs{project_dir};
    my $name;
    if ($file =~ /$project_dir\/(.+)/ ){
        $name = $1;
    }
    else {
        Message "File $file does not match format";
        return;
    }
    my $URL_path = 'dynamic/project/'.$name;
    if ($title) { $name = $title}
    my $link = "\n<BR><a href='/$URL_path'><b>$name</b></a>\n";

    return $link  ;
}





1;
