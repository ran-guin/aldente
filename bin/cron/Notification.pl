#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################
#
# Notification.pl 
#
# This program drives various notification messages.
# Run quality Diagnostic monitoring
# Stock supply monitoring
# Reset temporary Solutions to 'Finished' (older than 24 hours)<BR>Reset old (unanalyzed runs) to Expired  (more than X days old)

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
################################################################################
#
# Notification.pl
#
# This program drives various notification messages.
#
# Run quality Diagnostic monitoring
# Stock supply monitoring
# Reset temporary Solutions to 'Finished' (older than 24 hours)
# Reset old (unanalyzed runs) to Expired  (more than X days old)
#
################################################################################
################################################################################
# $Id: Notification.pl,v 1.19 2004/11/29 16:16:43 jsantos Exp $
################################################################################
# CVS Revision: $Revision: 1.19 $
#     CVS Date: $Date: 2004/11/29 16:16:43 $
################################################################################

use strict;
use CGI qw(:standard);
use DBI;
use FindBin;
use Data::Dumper;

use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Core/";
use lib $FindBin::RealBin . "/../lib/perl/Imported/";
use SDB::DBIO;
 
use SDB::HTML;
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Process_Monitor;

use alDente::Employee;
use alDente::Notification;     ## Notification module
use alDente::Diagnostics;      ## Diagnostics module
use alDente::SDB_Defaults;
use alDente::Sequencing;
use alDente::Tools;

use alDente::Subscription; 	## Subscription module.  Replace Notification with this in the future
##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($opt_S $opt_C $opt_D $opt_X $opt_A $opt_I $opt_R $opt_T $opt_f $opt_F $opt_G);
use vars qw($Data_log_directory $testing $html_header);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
require "getopts.pl";
&Getopts('SDX:IRT:fF:GC');
my $home = "$URL_domain/$URL_dir_name/cgi-bin/barcode.pl?User=Auto&Database=sequence";
### get list of Notification processes to check ###
my $Stock = $opt_S || 0;      ## monitor Stock levels
my $Conflicts = $opt_C || 0;
my $Diag = $opt_D || 0;       ## check Run Quality Diagnostics
my $Expired = $opt_X || 0;    ## reset old (unAnalyzed) runs to 'Expired' and temporary solutions to 'Finished'
my $Runs = $opt_R || 0;
my $Integrity = $opt_I || 0;          ## Data integrity checks...
my $All = $opt_A || 0;        ## do ALL checks above...          
my $force = $opt_f || 0;      ## force notification even if normally not sent.
my $Finished = $opt_F || 0;
my $ThrowAway = $opt_G || 0;

## set all checks if none specified ##
if (!$Stock && !$Diag && !$Expired && !$Integrity && !$All && !$Runs && !$Finished && !$ThrowAway && !$Conflicts) {
    $All = 1;
}

my $host = 'lims02';
my $dbase = 'sequence';
my $login_name = 'cron';
my $login_pass;
my $dbc = SDB::DBIO->new(-host=>$host,-dbase=>$dbase,-user=>$login_name,-password=>$login_pass);
$dbc->connect();

my ($garbage_rack) = $dbc->Table_find('Rack','Rack_ID',"where Rack_Name='Garbage'");
## retrieve administrator ids based on Department and baseline permissions ##
my %admins = $dbc->Table_retrieve('Department,Employee',['Email_Address','Department_Name'],"WHERE FK_Department__ID=Department_ID AND Employee_ID=141");

my %Admin;
my $i = 0;
while (defined $admins{Email_Address}[$i]) {
    my $dept = $admins{Department_Name}[$i];
    my $email = $admins{Email_Address}[$i];
    $i++;
    if ($dept && $email) {
	push(@{$Admin{$dept}},$email);
	push(@{$Admin{All}}, $email);
    }
}
## combine into comma-delimited admin lists.
my %Admins;
foreach my $key (keys %Admin) {
    $Admins{$key} = join ',', @{$Admin{$key}};
} 

######################## construct Process_Monitor object for writing to log file ###########

my $Report = Process_Monitor->new('Notificatione.pl Script');


########   Check Stock Supplies (Send EMAIL if necessary) ################################
if ($Stock || $All) {
    $Report->set_Detail("Checking Stocked Supplies");
    my $target = $opt_T;  ### otherwise set below from Notice table...
## retrieve details for Stock to check up on (specified by Catalog Number ##
    my %NoticeInfo = $dbc->Table_retrieve('Order_Notice',['Order_Notice_ID as ID','Catalog_Number as Cat','Order_Text as Msg','Target_List as Target','Minimum_Units as Min','Maximum_Units as Max','Notice_Sent as Sent','Notice_Frequency as Freq','FK_Grp__ID as Grp'],-date_format=>'SQL');
    my $header = "Content-type: text/html\n\n";
    my $index=0;
    while (defined $NoticeInfo{Cat}[$index]) {
	my $id     = $NoticeInfo{ID}[$index];
	my $cat_no = $NoticeInfo{Cat}[$index];
	my $msg = $NoticeInfo{Msg}[$index];
	$target ||= $NoticeInfo{Target}[$index];
	my $min = $NoticeInfo{Min}[$index];
	my $grp = $NoticeInfo{Grp}[$index];
	my $max = $NoticeInfo{Max}[$index];
	my $sent = $NoticeInfo{Sent}[$index];
	my $repeat_span = $NoticeInfo{Freq}[$index];
	
	my $grp_name = alDente_ref('Grp',$grp,-dbc=>$dbc);
	$index++;
	unless ($repeat_span > 0) { next }  ### if 0 they are presumed inactive... ###
	my $Stock_Note = HTML_Table->new();
	$Stock_Note->Set_Headers(['Owner','Item that is Low','Catalog Number','Edit Stock',"Edit Items",'Status','Items','(Last Received)']);
	unless ($min || $max) {
            $Report->set_Warning("No Min or Max defined for $cat_no"); 
            next;
        }

	unless ($cat_no) {
            $Report->set_Warning("No Catalog Number defined for Order Notification"); 
            next;
        }
	$repeat_span .= "d";  #### specify units of order notice frequency (days)
        $Report->set_Message("Checking Catalog #: $cat_no (Target list: $target) Min (Grp$grp):$min Max:$max, Freq: $repeat_span");
	###### check if this message was already sent... ############
	unless ($force) {  ## force notification 
	    my $timecheck = &today("-$repeat_span");
	    $sent =~s/\-//g;
	    $timecheck=~s /\-//g;
	    if ($sent > $timecheck) {
                $Report->set_Message("... already sent notice on $sent for $cat_no");
                next;
            }
	}
	my ($last_recvd) = $dbc->Table_find('Stock','Stock_Name,Stock_Type',"where Stock_Catalog_Number = '$cat_no' Order by Stock_ID DESC LIMIT 1");
	my ($name,$type) = split ',', $last_recvd;
	$type =~s/Kit/Box/;
	$type =~s/Reagent/Solution/;
	my %supplies = $dbc->Table_retrieve("$type,Stock",
					    ['Stock_Name','Stock_Catalog_Number',"${type}_Status",'count(*) as count','max(Stock_Received) as Received','max(Stock_ID) as latestID','Stock.FK_Grp__ID as Owned_by'],
					    "where FK_Stock__ID=Stock_ID AND (Stock_Catalog_Number = '$cat_no' OR Stock_Name = '$name') GROUP BY Stock_Name,${type}_Status,Stock_Catalog_Number,FK_Grp__ID ORDER BY FK_Grp__ID,latestID DESC");
	my $send = 0;
	my $unopened = 0;
	my $opened = 0;
	my $name= '';
	my $unopened_cats = 0;  ### count number of unique catalog numbers/names
        my $index = -1;
        while($supplies{Stock_Name}[++$index]) {            
	    #my ($thisname,$thiscat,$status,$count,$received,$items) = split ',',$info;
            my $thisname        = $supplies{Stock_Name}[$index];
            my $thiscat         = $supplies{Stock_Catalog_Number}[$index];
            my $status          = $supplies{"${type}_Status"}[$index];
            my $count           = $supplies{count}[$index];
            my $received        = $supplies{Received}[$index];
            my $items           = $supplies{latestID}[$index];
	    my $owner            = $supplies{Owned_by}[$index];
	    my $colour='lightgrey';
	    
	    my $owner_name = alDente_ref('Grp',$owner,-dbc=>$dbc);
	    if ($status=~/unopened/i) {
#		$unopened_cats++;
		if ($thiscat eq $cat_no) { 
		    $unopened = $count if ($owner =~ /^$grp$/);
		}  	    
		$colour='lightgreen';
	    }
	    elsif ($status=~/open/i) {
		$opened = $count; 
		$colour='lightyellow';
	    } 
	    my $allnames = join ',',$dbc->Table_find('Stock','Stock_ID',"where Stock_Name like '$thisname' AND Stock_Type = '$type'",'Distinct');
	    my $allcats = join ',',$dbc->Table_find('Stock','Stock_ID',"where Stock_Catalog_Number like '$thiscat'",'Distinct');
	    my $combos = join ',',$dbc->Table_find("Stock,$type",'Stock_ID',
							  "where FK_Stock__ID=Stock_ID AND Stock_Catalog_Number = '$thiscat' AND Stock_Name like '$thisname' AND ${type}_Status = '$status'",
							  -distinct=>1);
	    my $foundcombos = int(split ',', $combos);
	    my $hide = 'Stock_Source,FK_Orders__ID,FK_Box__ID';
	    my $combo_link = &Link_To($home,"edit ($foundcombos)","&Edit+Table=Edit+Stock+Table&Field=Stock_ID&Like=$combos&Hide=$hide",'blue',['newwin']);
	    my $item_link  = &Link_To($home,"items ($count)","&Info=1&Table=$type&Field=FK_Stock__ID&Like=$combos",'blue',['newwin']);
	    my $name_link = &Link_To($home,"$thisname","&Edit+Table=Edit+Stock+Table&Field=Stock_ID&Like=$allnames&Hide=$hide",'blue',['newwin']);
	    my $cat_link = &Link_To($home,"$thiscat","&Edit+Table=Edit+Stock+Table&Field=Stock_ID&Like=$allcats&Hide=$hide",'blue',['newwin']);
#            unless($received =~ / /) {
#                print Dumper($received,$info);
#            }
#	    ($received)     = split ' ',$received;
	    $Stock_Note->Set_Row([$owner_name,$name_link,$cat_link,$combo_link,$item_link,$status,$count,convert_date($received,'Simple')],"bgcolor=$colour");
	    $Report->set_Detail("$thisname: $thiscat  ($status : $count)"); 	  
	}	
	if ($unopened < $min) {
	    $Report->set_Detail("Need more $name ! ($opened Open, $unopened Unopened)");
	    $msg = "<BR>Unopened <Font color=red><B>Supply Level Low !</B></Font> ($unopened < $min for $grp_name)<BR><B>$msg</B><BR>" .
		&Link_To($home,'<- (edit this notification)',"&Search=1&Table=Order_Notice&Search List=$id") . "<BR>";
            $msg .= "\n<BR>(This message will be repeated if necessary after $repeat_span days)<BR>\n";
	    $send = 1;
	}
	elsif (($unopened>$max) && ($max > 0)) {
	    $Report->set_Detail("You have OVER-STOCKED on $name !","($opened Open, $unopened Unopened)");
	    $msg = "Supply <Font color=red><B>OVER-STOCKED</B></Font> ! (limit to $max) $msg";
	    $msg .= "\n<BR>(This message will be repeated if necessary after $repeat_span days)\n";
	    $send = 1;
	}
#	elsif ($unopened_cats > 1) {
# 	    my $Table = $Stock_Note->Printout(0);
#	    my $subject = "Stock Supplies";
#	    $msg = "Please Check <Font color=red><B>Consistency of Name/Catalog Number</B></Font><BR>".
#		"(Particularly for Unopened Supplies)";
#	    $send = 1;
#	}
	else {
	    $Report->set_Detail("$name Supply Ok: $opened Open, $unopened Unopened");
	    $send = 0;
	}
	if ($send) {
	    my $subject = 'Stock Supplies';
	    $msg .= "\n<BR>" &Link_To($home,'Check/Edit Notification Table',"&Edit+Table=Order_Notice",'blue',['newwin']);
	    $msg .= &hspace(20) &Link_To($home,'Help','&Help=Stock_Notification&Search+for+Help=1','blue',['newwin']);
	    my $notice = "<B>$msg</B><HR>\n";

 	    my $Table = $Stock_Note->Printout(0);
#Comment by Alan on 9/6/2007: According to Ran, This check is applied to different reagent which is at a finer granuality than the Subscription module.  Thus we will leave this unchanged for now.

	    my $ok = &alDente::Notification::Email_Notification($target,'Supply Monitor<aldente@bcgsc.bc.ca>',$subject,"$notice\n$Table",-content_type=>'html',
								-testing=>$dbc->{test_mode});

	    if ($ok) {
		my $send_date = &today();
		my $fback = $dbc->Table_update_array('Order_Notice',['Notice_Sent'],[$send_date],"where Catalog_Number like '$cat_no'",-autoquote=>1); 
                if($DBI::errstr) {
                    $Report->set_Error($DBI::errstr);
                }

		if ($fback) {$Report->set_Detail("updated notification date to ".&today());}
		else {$Report->set_Detail("Notice_Sent date not updated");}
	    }
	    else {
                $Report->set_Message("Email notice not sent ($subject)");
            }
	}
    }
    
}

if ($Conflicts || $All) {
    $Report->set_Message("Checking Stock Naming Conflicts");
    my $target = $opt_T;  ### otherwise set below from Notice table...
    ## retrieve details for Stock to check up on (specified by Catalog Number ##
#    my $header = "Content-type: text/html\n\n";
    ### check for Stock Name Consistency ###
    my @cat_conflicts  = $dbc->Table_find('Stock,Solution',"Stock_Name","WHERE FK_Stock__ID=Stock_ID AND Solution_Status LIKE 'Unopened' Group by Stock_Name having count(distinct Stock_Catalog_Number,FK_Organization__ID) > 1");
    
    my @name_conflicts  = $dbc->Table_find('Stock,Solution','Stock_Catalog_Number',"WHERE FK_Stock__ID=Stock_ID AND Solution_Status LIKE 'Unopened' Group by Stock_Catalog_Number having count(distinct Stock_Name,FK_Organization__ID) > 1");
    
    my $Table = "Stock Inconsistencies (excluding Finished items)<P><span class='small'>(click on links to edit)</span><P>";
    $Table .= print_conflicts(\@name_conflicts,"Inconsistencies in Stock Names",'Name');
    $Table .= print_conflicts(\@cat_conflicts,"Inconsistencies in Catalog Numbers",'Cat');

#------------------------------This section will be replaced by the Subscription module functions calls in the future---------------------------------------
#    my $ok = &alDente::Notification::Email_Notification('alDente','Stock Name Consistency Checker<aldente@bcgsc.bc.ca>',"Stock Naming Conflicts",$Table,-content_type=>'html',-testing=>$dbc->{test_mode});
#-------------------------------------------------------

#++++++++++++++++++++++++++++++ Subscription Module version of Notification

    my $tmp = alDente::Subscription->new(-dbc=>$dbc);
    my $ok = $tmp->send_notification(-name=>"Stock Naming Conflicts",-from=>'Stock Name Consistency Checker<aldente@bcgsc.bc.ca>',-subject=>"Stock Naming Conflicts (from Subscription Module)",-body=>$Table,-content_type=>'html',-testing=>0,-to=>'aldente',-bypass=>1);
	
#++++++++++++++++++++++++++++++

    if($ok) {
        $Report->set_Message("Sent notification for " . scalar(@name_conflicts) . " Stock Name conflicts and " . scalar(@cat_conflicts) . " Catalog Number conflicts");
    }



}
    
if ($Diag) {
############################ Check for Poor Quality Runs ###################################
    my $target = $opt_T || $Admins{'Cap_Seq'};
    my $percent;
    (my $from) = split ' ', &date_time('-120d');
    (my $upto) = split ' ', &date_time();
    my ($output,my $poor_runs) = &sequencing_diagnostics($dbc,$percent,$from,$upto,'email','Exclude Test Runs');
    $Report->set_Detail("Diagnostics******************\n $output");
    my $msg .= "Poor Sequence Run Monitor\n********************************\n";
    $msg .= "\nThis lists a number of solutions/equipment associated with poor sequence runs (Phred20 < 400).\n(Solution names are preceeded by their ID)\n\n";
    $msg .= "Numbers to the right indicate Average Phred20 values for a plate\n(and as a percentage of the Average Phred20 Quality for the month),\nas well as the number of runs over which this has been calculated.\n\n";
    $msg .= "For more info see link at bottom of page\n\n";
    my $send;
    foreach my $line (split '\n', $output) {
	if ($line=~/^Diagnostics/) {$msg .= "$line\n";}
	elsif (($line=~/^Poor/)) {
	    $msg .= "$line\n";
	    $line=~s/./*/g;
	    $msg .= "$line\n";
	}
	elsif ($line=~/^Using (.*) :/) {
	    my $thismsg .= &Send_Notice($dbc,$Admins{'Cap_Seq'},'Poor Quality Sequence Runs',"Using $1",'-14d',0);   
#### if not sent within 2 weeks (don't send now)
	    if ($thismsg) {$send .= "$line\n";}
	}
    }
    if ($send=~/Using/) {
	$msg .= $send;
	$msg .= "\n\n(Warnings are not repeated until two weeks after original message)";
	$msg .= "\n\nFor more detailed info go to: $home&Sequence+Run+Diagnostics=1#Diag";
	my $ok = &alDente::Notification::Email_Notification($target,'Diagnostics Monitor<rguin@bcgsc.bc.ca>','Poor Runs Warning',"$msg",-content_type=>'html',
								-testing=>$dbc->test_mode());
#++++++++++++++++++++++++++++++ Replacing the above with the Subscription Module version
 #   my $ok = alDente::Subscription::send_notification('Poor Runs Warning',-from=>'Diagnostics Monitor<rguin@bcgsc.bc.ca>',-subject=>'Poor Runs Warning',-body=>$msg,-content_type=>'html',-testing=>$dbc->{test_mode});

    my $tmp = alDente::Subscription->new(-dbc=>$dbc);
    my $ok = $tmp->send_notification(-name=>"Poor Runs Warning",-from=>'Diagnostics Monitor <rguin@bcgsc.ca>',-subject=>'Poor Sequence Runs Warning (from Subscription Module)',-body=>$msg,-content_type=>'html',-testing=>1);
	
#++++++++++++++++++++++++++++++

    }    
}
if ($Finished || $All) {
############### Set all temporary solutions older X days to 'finished' ##########
    my $target = $opt_T || $Admins{All}; 
    my $threshold = $Finished || '1'; # Default to 1 day
    $threshold = date_time('-' . $threshold . 'd');
    my $expired = date_time();
    (my $temp_loc) = $dbc->Table_find('Rack','Rack_ID',"where Rack_Name='Temporary'");
    
    ### find all solutions that are not FULLY set to expired Temporary Solutions...
    my $old_solutions = join ',', $dbc->Table_find('Solution,Rack','Solution_ID',"where FK_Rack__ID=Rack_ID AND Solution_Started < \"$threshold\" AND Rack_ID NOT IN ($garbage_rack) AND (Rack_Name='Temporary' OR (Solution_Status='Temporary'))");
    ## removed from condition (?): and (Solution_Finished <= Solution_Started or Solution_Finished is NULL or Rack_Name <> 'Temporary' or Solution_Status <> 'Finished') 
    if ($old_solutions=~/[1-9]/) {
	$Report->set_Detail("Set $old_solutions to 'Finished' (Temporary Solutions)...".&today());
	my $ok = $dbc->Table_update_array('Solution',['Solution_Status','Solution_Finished','FK_Rack__ID'],["'Finished'","'$expired'",$garbage_rack],"where Solution_ID in ($old_solutions)");
        if($DBI::errstr) {
            $Report->set_Error($DBI::errstr);
        }

        $Report->set_Message("Marked $ok Solutions as Finished");
    }
    else {$Report->set_Detail("No temporary solutions found");}
}
if ($Expired || $All) {

    ################  Set all Runs older than X days to 'Expired' ###################
    my $target = $opt_T || $Admins{'Cap_Seq'};;
    my $threshold = $Expired || '2'; # Default to 2 days

    $threshold = date_time('-' . $threshold . 'd');

    my $old_test_runs = join ',', $dbc->Table_find('Run,SequenceRun','Run_ID',"where Run_ID=FK_Run__ID AND Run_Test_Status = 'Test' AND Run_Status = 'In Process' AND Run_DateTime < '$threshold'");
    my $old_production_runs = join ',', $dbc->Table_find('Run,SequenceRun','Run_ID',"where Run_ID=FK_Run__ID AND Run_Status = 'In Process' and Run_Test_Status='Production' AND Run_DateTime < '$threshold'");
    $Report->set_Message("Check for 'Expired' Runs - $threshold days old run requests still 'In Process' as of ".&today());

    my $expired = 0;
    my $expired2 = 0;
    if ($old_test_runs=~/[1-9]/) {
	$expired += $dbc->Table_update_array('Run',['Run_Status'],['Expired'],"where Run_ID in ($old_test_runs)",-autoquote=>1);

        if($DBI::errstr) {
            $Report->set_Error($DBI::errstr);
        }

	my $msg = "Expired $expired Runs ". 
	    "\n(View at: $home&Info=1&Table=Run&Field=Run_ID&Like=$old_test_runs)\n\n";
#	my $ok = &alDente::Notification::Email_Notification($target,'Notification Cron Job<rguin@bcgsc.bc.ca>','Expiring Runs',"$msg",-content_type=>'html',-testing=>$dbc->test_mode());
#++++++++++++++++++++++++++++++ Replacing the above with the Subscription Module version

    my $tmp = alDente::Subscription->new(-dbc=>$dbc);
    my $ok = $tmp->send_notification(-name=>'Expiring Runs',-from=>'Notification Cron Job<rguin@bcgsc.bc.ca>',-subject=>"Expiring Test Runs $expired (Run ID: $old_test_runs) (from Subscription Module)",-body=>$msg,-content_type=>'html',-testing=>0,-to=>'aldente',-bypass=>1);
	
#++++++++++++++++++++++++++++++

    }
    if ($old_production_runs=~/[1-9]/) {
	$expired2 += $dbc->Table_update_array('Run',['Run_Status'],['Expired'],"where Run_ID in ($old_production_runs)",-autoquote=>1);

        if($DBI::errstr) {
            $Report->set_Error($DBI::errstr);
        }

	my $msg = "Expired $expired2 Runs".
	    "\n(View at: $home&Info=1&Table=Run&Field=Run_ID&Like=$old_production_runs)\n\n";
	my $ok = &alDente::Notification::Email_Notification($target,'Notification Cron Job<rguin@bcgsc.bc.ca>','Expiring Runs',"$msg",-content_type=>'html',-testing=>$dbc->test_mode());   
#++++++++++++++++++++++++++++++ Replacing the above with the Subscription Module version
        my $tmp = alDente::Subscription->new(-dbc=>$dbc);

        my $ok = $tmp->send_notification(-name=>"Expiring Runs",-from=>'Notification Cron Job<rguin@bcgsc.bc.ca>',-subject=>"Expiring Production Runs $expired2 (Run ID: $old_production_runs) (from Subscription Module)",-body=>$msg,-content_type=>'html');
	
#++++++++++++++++++++++++++++++

    }

    ################  Set all GelRuns that are 'In Process' to 'Expired'###################
    ##### (since this script runs overnight and no gel runs should still be running)
    my $old_gel_runs = join ',', $dbc->Table_find('Run,GelRun','Run_ID',"WHERE Run_ID=FK_Run__ID AND Run_Status='In Process'");
    if ($old_gel_runs) {
        require alDente::GelRun;

        $expired += $dbc->Table_update_array('Run',['Run_Status'],['Expired'],"where Run_ID in ($old_gel_runs)",-autoquote=>1);
        ### Move the parent rack out of the gel box, into the TBD Equipment
        my ($tmp_equ) = $dbc->Table_find('Equipment','Equipment_ID',"WHERE Equipment_Name='Cart #1'");
        my @parent_racks = $dbc->Table_find('Run,Rack','FKParent_Rack__ID',"WHERE Rack_ID=FKPosition_Rack__ID AND Run_ID IN ($old_gel_runs)",-distinct=>1);
        foreach my $pr (@parent_racks) {
            &alDente::GelRun::move_geltray_to_equ($dbc,$pr,$tmp_equ);
        }

        ### Mark them as Rejected as well
        &alDente::Run::set_validation_status(-dbc=>$dbc,-run_ids=>$old_gel_runs,-status=>'Rejected');

    }


    if ($expired) {$Report->set_Message("Expired $expired Test runs");}
    if ($expired2) {$Report->set_Message("Expired $expired2 Production runs");}
    else {$Report->set_Message("No expired runs found");}
}   
if ($Integrity || $All) {
    $Report->set_Message("Checking specific data integrity for notification of lab admins");
    my $target = $opt_T || $Admins{'Cap_Seq'};    
    
###### Vector files exist for all vectors specified #######
    my @vector_files = $dbc->Table_find('Vector_Type','Vector_Type_ID,Vector_Type_Name as Vector,Vector_Sequence_File',"where Length(Vector_Sequence_File) > 0");
    my @current_files = split "\n",&try_system_command("ls $vector_directory/");

    my %Vectors;
    foreach my $vector (@current_files) {
	%Vectors->{$vector} = 1;
    }
    my $msg = '';
    my $id;
    my @relevant_grps;
    foreach my $vector (@vector_files) {
	($id,my $name,my $file) = split ',', $vector;
	unless (%Vectors->{$file}) {
            $msg .= "**** Found $name Vector, but '$file' NOT FOUND in Vector Directory.\n<BR>";
            $Report->set_Warning("Found $name Vector, but '$file' NOT FOUND in Vector Directory.");
	
            my @grps = $dbc->Table_find('Library,LibraryVector,Vector,Vector_Type','FK_Grp__ID',"where FK_Vector_Type__ID = Vector_Type_ID and LibraryVector.FK_Vector__ID = Vector_ID and LibraryVector.FK_Library__Name=Library_Name AND Vector_Type_Name = '$name'",-distinct=>1,-debug=>1);
            print "val of grps array: ".Dumper(@grps);
            push(@relevant_grps,@grps) if (@grps);

        }
    }
    if ($msg) {
       &alDente::Notification::Email_Notification($target,'Integrity Monitor <aldente@bcgsc.bc.ca>','Strange Data',"$msg\n\nPlease ensure that this data is updated ASAP !!<BR>\n" . &Link_To($home,"check record","&Search=1&Table=Vector_Type&Search+List=$id"),-content_type=>'html',
                                                  -testing=>$dbc->test_mode());

#++++++++++++++++++++++++++++++ Replacing the above with the Subscription Module version
#verified by Alan on 9/18/07

#            print "val of rel grps afterwards: \n".Dumper(@relevant_grps)."\n";
#	    my $tmp = alDente::Subscription->new(-dbc=>$dbc);
#	    my $ok = $tmp->send_notification(-name=>'Missing Vector Sequence File',-from=>'Integrity Monitor <aldente@bcgsc.bc.ca>',-subject=>'Strange Data (from Subscription Module)',-body=>$msg."\n\nPlease ensure that this data is updated ASAP !!<BR>\n" . &Link_To($home,"check record","&Search=1&Table=Vector_Type&Search+List=$id"),-content_type=>'html',-group_ids=>\@relevant_grps);

    my $tmp = alDente::Subscription->new(-dbc=>$dbc);
    my $ok = $tmp->send_notification(-name=>"Missing Vector Sequence File",-from=>'Integrity Monitor <aldente@bcgsc.ca',-subject=>'Missing Vector Sequence File (from Subscription Module)',-body=>$msg."\n\nPlease ensure that this data is updated ASAP !!<BR>\n" . &Link_To($home,"check record","&Search=1&Table=Vector_Type&Search+List=$id"),-content_type=>'html',-testing=>0);

#++++++++++++++++++++++++++++++

    } else {
        $Report->set_Message("No data integrity issues detected regarding Vectors");
    }
}

if ($Runs || $All) {
#    print "Checking Runs for issues\n";
}


$dbc->disconnect();
$Report->completed();
$Report->DESTROY();
exit;	


#########################
sub print_conflicts {
#########################
    my $list_ref = shift;
    my $title    = shift;
    my $section  = shift;

    my @conflicts = @$list_ref if $list_ref;
    
    my $toggle = 1;
    if ($section eq 'Name') { $toggle = 3; }
    elsif ($section eq 'Cat') { $toggle = 1; }

    my $Stock_Note = HTML_Table->new(-title=>$title,-class=>'small');
    $Stock_Note->Set_Headers(['Owner','Item Name','Organization','Catalog Number','Status','Items','(Last Received)']);
    
    foreach my $label (@conflicts) {
	unless ($label) { next }  ## skip blanks... 
	if ($label =~ /^Custom/) { next } ## skip custom items that may have distinct cat nums

        $label =~ s/\'/\\\'/g;    #escape quotes
	my %supplies = $dbc->Table_retrieve('Solution,Stock',
					    ['Solution_ID','Stock_Name','Stock_Catalog_Number','Solution_Status','count(*) as count','max(Stock_Received) as max','FK_Organization__ID','FK_Grp__ID AS Owned_By'],
					    "where FK_Stock__ID=Stock_ID AND (Stock_Catalog_Number = '$label' OR Stock_Name = '$label') AND Solution_Status NOT LIKE 'Finished' GROUP BY Stock_Name,Solution_Status,Stock_Catalog_Number,FK_Organization__ID,FK_Grp__ID");
	my $send = 0;
 	my $unopened = 0;
 	my $opened = 0;
 	my $name= '';
 	my $unopened_cats = 0;  ### count number of unique catalog numbers/names
 	my $lastsection = '';
	my $index = -1;
	while($supplies{Solution_ID}[++$index]) {
 	    my ($id,$cat);
	    my $thisname   = $supplies{Stock_Name}[$index];
	    my $thiscat    = $supplies{Stock_Catalog_Number}[$index];
	    my $status     = $supplies{Solution_Status}[$index];
	    my $count      = $supplies{count}[$index];
	    my $grp        = $supplies{Owned_By}[$index];
            my $started    = $supplies{max}[$index];
            my $organization_id = $supplies{FK_Organization__ID}[$index];
	    
	    my $grp_name = alDente_ref('Grp',$grp,-dbc=>$dbc);

	    my $colour='gray';
	    if ($status=~/unopened/i) {
		$unopened_cats++;
		if (($thiscat eq $id) && ($count>$unopened)) { 
		    $unopened = $count;
		}  	    
		$colour='red';
	    }
	    elsif($status=~/open/i) {
		$opened = $count; 
		$colour='lightgreen';
	    }
	    
	    $organization_id ||= 0;
	    (my $org) = $dbc->Table_find('Organization','Organization_Name',"WHERE Organization_ID = $organization_id");
	    $org ||= 'undef';

	    my $combos = join ',',$dbc->Table_find('Stock,Solution','Stock_ID',"where FK_Stock__ID=Stock_ID AND Stock_Catalog_Number = '$thiscat' AND Stock_Name like \"$thisname\" AND Solution_Status = '$status'",'Distinct');
	    my $foundcombos = int(split ',', $combos);
	    my $hide = 'Stock_Source,FK_Orders__ID,FK_Box__ID';  ## Hide fields

	    my $name_link = &Link_To($home,"$thisname","&Edit+Table=Edit+Stock+Table&Field=Stock_Name&Like=$thisname&Hide=$hide",'blue',['newwin']);
	    my $cat_link = &Link_To($home,"$thiscat","&Edit+Table=Edit+Stock+Table&Field=Stock_Catalog_Number&Like=$thiscat&Hide=$hide",'blue',['newwin']);
	    ($started) = split ' ',$started;
	    ## highlight current grouping:
	    if ($section eq 'Cat') { $thiscat = "<B>$thiscat</B>"; } 
	    elsif ($section eq 'Name') { $thisname = "<B>$thisname</B>"; }

	    $Stock_Note->Set_Row([$grp_name,$name_link,$org,$cat_link,$status,$count,convert_date($started,'Simple')],$colour);
	}	
    }
    $Stock_Note->Set_Header($html_header);
    $Stock_Note->Toggle_Colour_on_Column($toggle);
    return $Stock_Note->Printout(0);
}
