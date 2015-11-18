#!/usr/local/bin/perl

use strict;
use CGI qw(:standard);
use DBI;
use FindBin;
use Data::Dumper;

use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Core/";
use lib $FindBin::RealBin . "/../lib/perl/Imported/";
use SDB::DBIO;
 
use SDB::Report;                ## Seq_Notes
use SDB::HTML;
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Process_Monitor;
use alDente::Employee;
use alDente::Notification;
use alDente::Subscription;
use Benchmark;

use vars qw($Connection $opt_host $opt_dbase $opt_user $opt_pass $opt_u $opt_p $opt_help $opt_h $opt_d $opt_expire $opt_throwaway $opt_debug);

use Getopt::Long;
&GetOptions(
	    'host=s'      => \$opt_host,
	    'dbase=s'     => \$opt_dbase,
	    'user=s'      => \$opt_user,
	    'u=s'         => \$opt_u,
	    'pass=s'      => \$opt_pass,
	    'p=s'         => \$opt_p,
	    'help'        => \$opt_help,
	    'h'           => \$opt_h,
	    'd=s'         => \$opt_d,
	    'expire'      => \$opt_expire,
	    'throwaway'   => \$opt_throwaway,
	    'debug'       => \$opt_debug
	    );


my $host = $opt_host || $opt_h;
my $dbase = $opt_dbase || $opt_d;
my $login_name = $opt_user || $opt_u;
my $login_pass = $opt_pass || $opt_p;

my $Report = Process_Monitor->new('cleanup_DB Script');

unless ($host || $dbase || $login_name || $login_pass) {
    $Report->set_Error("Invalid arguments Dbase: $dbase, Host: $host, Login: $login_name, Pass: $login_pass");
    exit;
}

my $dbc = SDB::DBIO->new(-host=>$host,-dbase=>$dbase,-user=>$login_name,-password=>$login_pass);
$dbc->connect();

my $today = &today;
my $time = date_time();

my $log_file = "$Data_log_directory/Notification/ExpiringSol_Plates_". $today . '.log';

######################## construct Process_Monitor object for writing to log file ###########


my ($garbage_rack) = &Table_find($dbc,'Rack','Rack_ID',"where Rack_Name='Garbage'");

## retrieve administrator ids based on Grp ending with 'Admin' (excluding Project Admins) ##
my @admins = &Table_find($dbc,'Grp,GrpEmployee','FK_Employee__ID',"WHERE FK_Grp__ID=Grp_ID AND Grp_Name like '%Admin' AND Access='Admin'",-distinct=>1);

my $SolExp = $opt_expire;
my $ThrowAway = $opt_throwaway;

my $debug = $opt_debug;

if($debug) {
  print 'x' x 40 . "\n"x3 . 'Debug mode' . "\n"x3 . 'x' x 40;
}

if ($SolExp) {
  my ($today) = split ' ', date_time();
  my $expiry_threshold = 30;	## days at which to notify administrators of expired Reagents
  my $expiry_warning_date = date_time('+' . $expiry_threshold . 'd');

  $Report->set_Message("Check for 'Expired' Solutions/Boxes ($expiry_threshold day warning messages ( < $expiry_warning_date) generated)  as of $today");

  ### find all solutions that are Expiring ..

  my %Sol_expiry_info = Table_retrieve($dbc,'Solution,Stock,Rack LEFT JOIN Grp ON Stock.FK_Grp__ID=Grp_ID',['Grp_Name','Solution_ID','Solution_Expiry','Rack_Alias','Grp_ID','Stock_Name',"CASE WHEN Solution_Expiry > '$today' THEN 'Expiring' ELSE 'Expired' END AS Status",'Solution_Number','Solution_Number_in_Batch'],"where FK_Rack__ID=Rack_ID AND FK_Stock__ID=Stock_ID AND Rack_ID NOT IN ($garbage_rack) AND Solution_Expiry BETWEEN '2000-01-01' AND '$expiry_warning_date' AND  Solution_Status IN('Unopened','Open') ORDER BY Solution_Expiry ");

  my %Expire;
  my %Warn;
  my %Temporary;

  my $index = 0;
  my @expired_sol_ids;
  my @expired_box_ids;
  my %Group;
  my @groups;  ## Check each expired Solution ##
  while (defined $Sol_expiry_info{Solution_ID}[$index]) {
    my $name = $Sol_expiry_info{Stock_Name}[$index];
    my $exp_date = $Sol_expiry_info{Solution_Expiry}[$index];
    my $group    = $Sol_expiry_info{Grp_ID}[$index] || 'undef';
    my $status   = $Sol_expiry_info{Status}[$index];
    my $id       = $Sol_expiry_info{Solution_ID}[$index];
    my $rack = $Sol_expiry_info{Rack_Alias}[$index];
    my $bottle = $Sol_expiry_info{Solution_Number}[$index];
    my $bottles = $Sol_expiry_info{Solution_Number_in_Batch}[$index];
    my $group_name = $Sol_expiry_info{Grp_Name}[$index];

    push(@groups, $group) unless (grep /^$group$/, @groups);
    $Group{$group} =  $group_name;

    if ($status eq 'Expired') {  
      push(@{$Expire{$group}}, ["SOL $id","(<B>$name</B> - $bottle/$bottles)","<B>$exp_date</B>",$rack,$group_name,$status]);
      push(@expired_sol_ids,$id);
    } else {
      push(@{$Warn{$group}}, ["SOL $id", "(<B>$name</B> - $bottle/$bottles)","<B>$exp_date</B>", $rack, $group_name,$status]);
    }
    $index++;
  }  
  if(@expired_sol_ids) {
      my $expired_list = join ',', @expired_sol_ids;
      $Report->set_Detail("***** Updating the database with the expired solution list (" . scalar(@expired_sol_ids) . ')');
      
      my $updated;
      if($debug) {
	  Dumper(\@expired_sol_ids);
      } else {
	  $updated = &Table_update($dbc,'Solution','Solution_Status','Expired',"WHERE Solution_ID IN ($expired_list)",-autoquote=>1);
      }
      $Report->set_Message("Changed the status of $updated solutions to expired");
  }

  ## Same for expired Boxes ##

  my $expiry_condition = "Box_Expiry BETWEEN '2000-01-01' AND '$expiry_warning_date'";
  my $valid_condition = "Box_Status NOT IN ('Inactive') AND Rack_ID NOT IN ($garbage_rack)";

  my %Box_expiry_info = Table_retrieve($dbc,
				       'Box,Stock,Rack LEFT JOIN Grp ON Stock.FK_Grp__ID=Grp_ID',
				       ['Grp_Name','Box_ID','Box_Expiry','Rack_Alias','Grp_ID','Stock_Name',
					"CASE WHEN Box_Expiry > '$today' THEN 'Expiring' ELSE 'Expired' END AS Status",
					'Box_Number','Box_Number_in_Batch'],
				       "WHERE FK_Rack__ID=Rack_ID AND FK_Stock__ID=Stock_ID AND $valid_condition AND $expiry_condition ORDER BY Box_Expiry ");

  $index = 0;
  while (defined $Box_expiry_info{Box_ID}[$index]) {
    my $name = $Box_expiry_info{Stock_Name}[$index];
    my $exp_date = $Box_expiry_info{Box_Expiry}[$index];
    my $group    = $Box_expiry_info{Grp_ID}[$index] || 'undef';
    my $status   = $Box_expiry_info{Status}[$index];
    my $id       = $Box_expiry_info{Box_ID}[$index];
    my $rack = $Box_expiry_info{Rack_Alias}[$index];
    my $bottle = $Box_expiry_info{Box_Number}[$index];
    my $bottles = $Box_expiry_info{Box_Number_in_Batch}[$index];
    my $group_name = $Box_expiry_info{Grp_Name}[$index];
    $Group{$group} =  $group_name;

    push(@groups, $group) unless (grep /^$group$/, @groups);

    if ($status eq 'Expired' ) {
      push(@{$Expire{$group}}, ["BOX $id","(<B>$name</B> - $bottle/$bottles)","<B>$exp_date</B>",$rack,$group_name, $status]);
      push(@expired_box_ids,$id);
    } else {
      push(@{$Warn{$group}}, ["BOX $id", "(<B>$name</B> - $bottle/$bottles)","<B>$exp_date</B>", $rack, $group_name, $status]);
    }
    $index++;
  }

  if(@expired_box_ids) {
    my $expired_list = join ',', @expired_box_ids;
    $Report->set_Detail("***** Noted expired boxes which have not been thrown away ****");
    $Report->set_Detail("***** Updating the database with the expired box list (" . scalar(@expired_box_ids) . ')');

    my $updated;
    if($debug) {
      print Dumper(\@expired_box_ids);
    } else {
      $updated = &Table_update($dbc,'Box','Box_Status','Expired',"WHERE Box_ID IN ($expired_list)",-autoquote=>1);
    }
    $Report->set_Message("Changed the status of $updated Boxes to expired");
  }

    foreach my $group (@groups) {
	my @expired_items;
	my @expiring_items;
	my $admin_email;

	my $group_name = $Group{$group};
	my $Message = "<B>Expiring Reagents/Solutions/Boxes (Group: $group_name)</B><P>";

	if ($group =~ /[1-9]/) {
	    my $email_list = &alDente::Employee::get_email_list(-group=>$group,-list=>'admin',-dbc=>$dbc);
            $admin_email = Cast_List(-list=>$email_list,-to=>'string');
	    $admin_email .= ",aldente\@bcgsc.bc.ca";  ## <CONSTRUCTION> this should already be included, but just in case.. (remove this line)
	} else {
	    $admin_email = "aldente\@bcgsc.bc.ca";
	}
	
	if($Expire{$group}) {
	    push(@expired_items,@{$Expire{$group}});
	}
	if($Warn{$group}) {
	    push(@expiring_items,@{$Warn{$group}});
	}
	
	my $Table = HTML_Table->new(-title=>"Expiring Reagents/Solutions on $dbase\@$host");
	$Table->Set_Headers(["Barcode","Reagent / Solution","Expiry Date","Location","Owned By","Status"]);
	
	my $records = "Exp: ". scalar(@expired_items) . ", To Be Exp: ".scalar(@expiring_items);
	
	if (@expired_items) {
	    $Table->Set_sub_header("<i>Expired Items:</i> ");
	    foreach my $exp (@expired_items) { $Table->Set_Row($exp); }
	}

	if (@expiring_items) {
	    $Table->Set_sub_header("<b><i>Soon to Expire:</i></b>");
	    foreach my $exp (@expiring_items) { $Table->Set_Row($exp); }
	}

	$Message .= $Table->Printout(0);
	
	if($debug) {  ## send message (and list of recipients) to aldente ##
	    $Message .= "Recipient List: $admin_email\n";
	    $admin_email = 'aldente@bcgsc.ca';
	}

	### Send Notification as required ###
	if (@expired_items || @expiring_items) {
            $Report->set_Message("Generated ($records) notification messages for Group $group_name");
	    &alDente::Notification::Email_Notification($admin_email,'Expiration Notice',"Expiring Reagents/Solutions (Group: $group_name)",$Message,-content_type=>'html');

#++++++++++++++++++++++++++++++ Subscription Module version of Notification
    my $tmp = alDente::Subscription->new(-dbc=>$dbc);

    my $ok = $tmp->send_notification(-name=>"Expiration Notice",-from=>'aldente@bcgsc.ca',-subject=>"Expiring Reagents/Solutions (Group: $group_name) (from Subscription Module)",-body=>$Message,-content_type=>'html',-testing=>1);

#++++++++++++++++++++++++++++++

	}
    }
  
}

if ($ThrowAway) {
  ## throw away plates / solutions in 'Temporary location that are more than 24 hours old' ##
  my $yesterday = &date_time("-1d");
  my $temp_racks = join ',', &Table_find($dbc,'Rack','Rack_ID',"WHERE Rack_Name like 'Temporary'");
  my $temp_plate_ids = join ',', Table_find($dbc,'Plate','Plate_ID',"WHERE FK_Rack__ID in ($temp_racks) AND Plate_Status IN ('Active','Temporary','Failed','Thrown Out') AND Plate_Created < '$yesterday' ORDER BY Plate_Created");

  if ($temp_plate_ids) {
    require alDente::Container;
    my $temp_plates_count;
    if($debug) {
      $temp_plates_count = scalar(split(',',$temp_plate_ids));
    } else {
      $temp_plates_count = &alDente::Container::throw_away(-dbc=>$dbc,-ids=>$temp_plate_ids,-notes=>'Thrown out during the nightly cleanup of temporary plates',-confirmed=>1);
    }
    if($temp_plates_count) {
      $Report->set_Message("** Threw away $temp_plates_count temporary plates (moved to Rack_ID:$garbage_rack)");
    } else {
      $Report->set_Error("** Attempted to throw away temporary plates but did not succeed.\n $temp_plate_ids");
    }
  }

    require alDente::Prep;
  ## return 'In Use' plates to storage location from which it was retrieved ##  
  my $returned = alDente::Prep::return_in_use_plates($dbc);
  $Report->set_Message("** Returned $returned plates to original storage location.");

  my $tmp_sol_ids = join ',', &Table_find($dbc,'Solution','Solution_ID',"WHERE FK_Rack__ID in ($temp_racks) AND Solution_Started < '$yesterday' ORDER BY Solution_Started");
  if($tmp_sol_ids) {
    require alDente::Solution;
    my $temp_solutions_count;
    if($debug) {
      $temp_solutions_count = scalar(split(',',$tmp_sol_ids));
    } else {
      $temp_solutions_count = &alDente::Solution::empty(-dbc=>$dbc,-id=>$tmp_sol_ids,-notes=>'Thrown out during the nightly cleanup of temporary solutions');
      $temp_solutions_count = &Table_update_array($dbc,'Solution',['FK_Rack__ID'],[$garbage_rack],"WHERE Solution_ID IN ($tmp_sol_ids)");
    }
    if($temp_solutions_count) {
      $Report->set_Message("** Threw away $temp_solutions_count temporary solutions (moved to Rack_ID:$garbage_rack).");
    } else {
      $Report->set_Error("** Attempted to throw away temporary plates but did not succeed.\n $temp_plate_ids");
    }
  }
}

$dbc->disconnect();
$Report->completed();
$Report->DESTROY();
exit;
