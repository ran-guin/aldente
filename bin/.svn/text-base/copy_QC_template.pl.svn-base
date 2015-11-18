#!/usr/local/bin/perl

##########################
# copy_QC_template.pl
#
# This script is used to copy the QC Template file from the tmp directory to a subfolders of the format  yyyy/mm
# under /home/sequence/Scans_on_Filer01/PrepQC/Source wells
# See LIMS-2348 for details
#
#########################
use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Process_Monitor;

my $Report = Process_Monitor->new();

my $path = '/home/sequence/Scans_on_Filer01/PrepQC/Source wells';
my $subfolders = convert_date( &date_time(),'YYYY/Mon');
my $new_path ="$path/$subfolders";

create_dir($path,$subfolders ,'775'); ## create subdirectories for date 

my $command = "cp -u /opt/alDente/www/dynamic/tmp/QC*.xls '$new_path'";
print "**\n$command\n";
$Report->set_Message("$command"); 

my $result = &try_system_command($command);

my $command = "chmod 775 '$new_path'/QC*.xls";
print "**\n$command\n";
$Report->set_Message("$command");
 
my $result = &try_system_command($command);

$Report->completed();
$Report->DESTROY();

exit;
