#!/usr/local/bin/perl

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use alDente::Issue;
use alDente::Notification;

use SDB::DBIO;
use SDB::CustomSettings qw($html_header);

use RGTools::RGIO;

my $dbc = SDB::DBIO->new(-dbase=>'sequence',-host=>'lims01',-user=>'viewer',-password=>'viewer');
$dbc->connect();
   

send_WorkPackage_Report(-target=>'lims');

exit;

#############################
sub send_WorkPackage_Report {
#############################
    my %args = &filter_input(\@_,-args=>'target,condition');
    my $target = $args{-target};
    my $condition = $args{-condition};
 
    my ($next_version) = $dbc->Table_find('Version','Version_Name',"WHERE Release_Date > now() ORDER BY Release_Date ASC LIMIT 1");
    ## get Issues assigned to next version (or unclosed issues from previous versions) ##
    $condition ||= "((Assigned_Release < '$next_version' AND Status NOT IN ('Closed')) OR Assigned_Release = '$next_version')";
    
    my $monthly_temp = "/opt/alDente/www/dynamic/month";
    my $table = &alDente::Issue::_print_work_package_stats($dbc, 
							   -condition=>$condition,
							   -summarize_ETA=>1,
							   -print_path=>$monthly_temp,
							   -link_name=>$link_name);
    
    my $reference = "Summary contained at: 'http://limsdev01/dynamic/month/$link_name'";
    
    &alDente::Notification::Email_Notification(-to=>$target,-subject=>'Work Package Status',-body=>$table,-content_type=>'html');
    return;
}

exit;


