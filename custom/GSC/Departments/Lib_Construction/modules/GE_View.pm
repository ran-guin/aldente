################################################################################
# Lab_View.pm
#
# This modules provides various views of Laboratory Status 
#
# prep_status - view of preparation history by library or by date.
#             
#
#
################################################################################
################################################################################
# $Id: GE_View.pm,v 1.11 2004/10/12 23:05:53 jsantos Exp $
################################################################################
# CVS Revision: $Revision: 1.11 $ 
#     CVS Date: $Date: 2004/10/12 23:05:53 $
################################################################################
package Lib_Construction::GE_View;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

GE_View.pm - Lab_View.pm

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
Lab_View.pm<BR>This modules provides various views of Laboratory Status <BR>prep_status - view of preparation history by library or by date.<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
	     );

##############################
# standard_modules_ref       #
##############################

use strict;
use CGI qw(:standard);
use Benchmark;
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
use alDente::Container;
use Sequencing::Sequence;
use Sequencing::Sample_Sheet;           ### allow primer extraction routine..
use alDente::SDB_Defaults;

use SDB::HTML;
use SDB::CustomSettings;

use RGTools::RGIO;
use RGTools::Views;
use RGTools::Conversion;

##############################
# global_vars                #
##############################
use vars qw($run_maps_dir $testing);
use vars qw(%Parameters);

##############################
# modular_vars               #
##############################
use vars qw($Connection $user_id $homelink);
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

#######################
sub prep_status {
###########################
#
# Generate Schedule from Protocol Tracking Steps
#
# (generally retrieves by Library or by Date Range)
#
    my %args = @_;
    my $dbc = $args{dbc} || $Connection;         ## Mandatory database handle
    my $library = $args{library}; ## library name 
    my $plate_numbers = $args{plates}; ## optional list of plates
    my $date_min = $args{from};        ## show only where Date AFTER date_min
    my $date_max = $args{to};          ## show only where Date BEFORE date_max
    my $days_ago = $args{days} || 5;   ## show status for past $days_ago days.. 
    my $include = $args{include} || $args{$library};  ## include completed runs (defaults on when Library specified)...
    my $details = $args{details} || 0;
    my $track_primers = $args{track_primers} || 0;

    my $show_empty = 0;  ### show rows with no plates at all

    my $t1 = new Benchmark;

    my $page = SDB::HTML::page_heading("Prep Summary");
### Provide Link to Edit Preparation Tracking Settings (administrative permissions ) #### 
    $page .= Link_To($homelink,"Edit Prep Tracking Settings",
		  "&Info=1&Table=Protocol_Tracking",'red',['newwin']).
		      &vspace(5);

    my @preps;
    my %Libs;
    my @plate_names;
    
### Generate conditions ###

    my $condition;
    my $Pcondition;
    if (!$library) {         ### if no library selected, look for recently prepped/created plates...
	$date_min ||= date_time('-' . $days_ago . 'd');
	### Find Preparation steps completed since date_min ###
	@preps = $dbc->Table_find('Prep,Plate_Prep,Plate,Plate_Set','FK_Library__Name,Plate_Number',
				 "where Plate_Set.FK_Plate__ID=Plate_ID AND Plate_Prep.FK_Plate_Set__Number=Plate_Set_Number AND Prep_ID=FK_Prep__ID AND Prep_DateTime > '$date_min'",'Distinct');
	foreach my $prep (@preps) {      ### Generate list of recently used Libraries, Plate Numbers...
	    my ($lib,$plate_number) = split ',', $prep;
	    $Libs{$lib} = 1;
	    push(@plate_names,"$lib$plate_number");
	}
	my $plates = join "','",@plate_names;
	$condition = "AND concat(FK_Library__Name,Plate_Number) in ('$plates')";
    } else {    ### if Library specified store library and (optionally) plate numbers 
	if ($library =~ /(.*):/) { $library = $1; }
	$Libs{$library} = 1;
	$condition = "AND FK_Library__Name='$library'";
	if ($plate_numbers) { 
	    $plate_numbers = &extract_range($plate_numbers);
	    $condition .= " AND Plate_Number in ($plate_numbers)";
	}
    }
    $Pcondition = "$condition";

    my @libs = keys %Libs; 
    
### show detailed Library Preparation status only when Library chosen ###      
    if ($library && $details) {           
	$page .= show_Prepped_Plates($dbc,$condition);
    }

    ### Search for data based on Plate info and tracked steps... 

    my %Found = Track_Plates(dbc=>$dbc,condition=>$condition,check_runs=>1);

    ### Track Steps completed ..### 

    my @steps = $dbc->Table_find('Protocol_Tracking,Grp,Department','Protocol_Tracking_Title,Protocol_Tracking_Step_Name,Protocol_Tracking_Type',"where Protocol_Tracking_Status = 'Active' AND FK_Grp__ID=Grp_ID AND FK_Department__ID=Department_ID AND Department_Name='$Current_Department' Order by Protocol_Tracking_Order");

    unless (@steps) { $page .= "No Customized Prep Tracking steps setup for current department ($Current_Department).<br>(See LIMS admin to help set up this advanced functionality)"; return}
    
    my $step_num = 0;
    foreach my $step (@steps) {  
	unless ($step) {next}
	$step_num++;
	my ($stepTitle,$track_step,$step_type) = split ',', $step;
	push(@{$Found{Steps}},$stepTitle);
	$Found{Step_Type}->{$step_num} = $step_type;
	$Found{Step_Track}->{$step_num} = $track_step;
	my @show;
	if ($step_type =~ /Plastic/i) {
	    my @plastic = $dbc->Table_find("Plate,Plate_Format",'FK_Library__Name,Plate_Number,Plate_ID,Plate_Size',"where FK_Plate_Format__ID=Plate_Format_ID AND Plate_Format_Type regexp '$track_step' $Pcondition Order by FK_Library__Name,Plate_Number,Plate_Size");
	    foreach my $plate (@plastic) {   ### regardless of Preparation stages... 
		my ($lib,$Pnum,$Pquad,$plate_id,$Psize) = split ',', $plate;
		$Found{IDs}->{$lib}->{"$Pnum$Pquad ($Psize)"}->{$step_num}->{$plate_id} = 1;
	    }
	}
	else {
	    foreach my $lib (keys %{ $Found{IDlist} }) {
		foreach my $item ( keys %{ $Found{IDlist}->{$lib}} ) {
		    my $item_condition = "AND concat(FK_Library__Name,Plate_Number,' (',Plate_Size,')')='$lib$item'";

		    my $preps = $Found{Preps}->{$lib}->{$item};
		    unless ($preps) {next}
		    if ($track_step =~ /Brew/) {  ### check type of brew dispensed
			my @brews = $dbc->Table_find_array("Prep,Solution,Stock,Stock_Catalog",['Prep_ID','Left(Stock_Catalog_Name,2)'],"where FK_Stock_Catalog__ID = Stock_Catalog_ID AND FK_Stock__ID=Stock_ID AND FK_Solution__ID=Solution_ID AND Prep_Name like '$track_step' AND Prep_ID in ($preps) Order by Left(Stock_Catalog_Name,2)");
			foreach my $brew (@brews) {
			    my ($prep_id,$brew) = split ',', $brew;
			    my $plates = join ',', $dbc->Table_find_array('Prep,Plate_Prep,Plate_Set,Plate',['Plate_ID'],
								     "where Prep_ID in ($prep_id) AND Plate_Prep.FK_Plate_Set__Number=Plate_Set_Number AND Prep_ID=FK_Prep__ID AND (Plate_Prep.FK_Plate__ID is NULL OR Plate_Prep.FK_Plate__ID=Plate_Set.FK_Plate__ID) AND Plate_Set.FK_Plate__ID=Plate_ID $Pcondition $item_condition",'Distinct');
			    $Found{IDs}->{$lib}->{$item}->{$step_num}->{$brew}->{$prep_id} = $plates;
			}
		    }
		    else {      ### Track Steps taken within Protocols ###
			my @trackplates = $dbc->Table_find("Prep",'Prep_ID',"where Prep_Name like '$track_step%' AND Prep_ID in ($preps)");
			foreach my $prep_id (@trackplates) {
			    my $plates = join ',', $dbc->Table_find_array('Prep,Plate_Prep,Plate,Plate_Set',['Plate_ID'],
								     "where Prep_ID in ($prep_id) AND Plate_Prep.FK_Plate_Set__Number=Plate_Set_Number AND Prep_ID=FK_Prep__ID AND (Plate_Prep.FK_Plate__ID is NULL OR Plate_Prep.FK_Plate__ID=Plate_Set.FK_Plate__ID) AND Plate_Set.FK_Plate__ID=Plate_ID $Pcondition $item_condition",'Distinct');
			    $Found{IDs}->{$lib}->{$item}->{$step_num}->{$prep_id} = $plates;
			}
		    }
		}
	    }
	}
    }

    ### Generate Schedule ###

    my @headers = ("Plate",@{ $Found{Steps} });
    if (!$library) { @headers = ('Library',@headers) }
    else { $page .= section_heading("$library Tubes") }

    my @groups = keys %{$Found{IDs}};
    foreach my $group (@groups) {       ### For each group (Library) 
	my $rownum=0;
	my $Schedule = HTML_Table->new();
	$Schedule->Set_Width('100%');
	$Schedule->Set_Headers([@headers]);
	$Schedule->Set_Class('small');
	
	unless (defined $Found{Items}->{$group}) { next }
	my @items = @{ $Found{Items}->{$group} };

	foreach my $item (@items) {     ### For each row item (Plate Number) 
	    if (!$include && ($Found{Complete}->{$group}->{$item} =~/Yes/i)) { next }  ### ignore completed plates if desired
	    $rownum++;
	    my @row;
	    if ($library) { @row = ("<B>$item</B>") }
	    else { @row = ("<B>$group<B>","<B>$item</B>") }
	    
	    my $colnum = int(@row);
	    foreach my $step (1..$step_num) {       ### For each step... 
		my @show = ();
		my $step_type = $Found{Step_Type}->{$step};
		my $step_tracked = $Found{Step_Track}->{$step};
		if (defined $Found{IDs}->{$group}->{$item}->{$step}) {
		    my @list = keys %{ $Found{IDs}->{$group}->{$item}->{$step}};
		    my $idlist = join ',', @list;
		    
		    my $count = int(@list);
		    if ($step_type=~/plastic/i) { ### Plasticware tracking 
			push(@show,&Link_To($homelink,$count,"&Info=1&Table=Plate&Field=Plate_ID&Like=$idlist",'black',['newwin']));
		    } elsif ($step_tracked=~/brew/i) {   #### Brew tracking 
			foreach my $brew (@list) {
			    my @preps = keys %{ $Found{IDs}->{$group}->{$item}->{$step}->{$brew} };
			    my @plates;
			    foreach my $prep (@preps) {
				my $platelist = $Found{IDs}->{$group}->{$item}->{$step}->{$brew}->{$prep};
				foreach my $plate (split ',', $platelist) {
				    unless (grep /^$plate$/, @plates) { push(@plates,$plate) }
				}
			    } 
			    my $platelist = join ',', @plates;
			    my $count = int(@plates);
			    my $plate_link = &Link_To($homelink,"$brew : $count","&Info=1&Table=Plate&Field=Plate_ID&Like=$platelist",'black',['newwin']);
			    my $preplist = join ',', @preps;
			    my $prepcount = int(@preps);
			    my $prep_link = &Link_To($homelink,"(prep $prepcount)","&Info=1&Table=Prep&Field=Prep_ID&Like=$preplist",'black',['newwin']);
			    push(@show,"$plate_link $prep_link");
			}
		    } else {                            ### other Step tracking
			my @plates;
			foreach my $prep (@list) {
			    my $platelist = $Found{IDs}->{$group}->{$item}->{$step}->{$prep};
			    foreach my $plate (split ',', $platelist) {
				unless (grep /^$plate$/, @plates) { push(@plates,$plate) }
			    }
			} 
			my $platelist = join ',', @plates;
			my $count = int(@plates);
			if ($count) {
			    my $plate_link = &Link_To($homelink,"$count","&Info=1&Table=Plate&Field=Plate_ID&Like=$platelist",'black',['newwin']);
			    my $preplist = join ',', @list;
			    my $prepcount = int(@list);
			    my $prep_link = &Link_To($homelink,"(prep $prepcount)","&Info=1&Table=Prep&Field=Prep_ID&Like=$preplist",'black',['newwin']);
			    push(@show,"$plate_link $prep_link");
			} else { push(@show,"-") }
		    } 
		}
		push(@row, join '<BR>',@show);
		$colnum++;

		### highlight steps where next step is missing
		my @keys = keys %{$Found{IDs}->{$group}->{$item}->{$step} };
		my @nextkeys = keys %{$Found{IDs}->{$group}->{$item}->{$step + 1} };
		if (int(@keys) && ($step == $step_num)) {  ### if last step check for completed Plate ###
		    unless ($Found{Complete}->{$group}->{$item}=~/Yes/i) {
			$Schedule->Set_Cell_Colour($rownum,$colnum,'yellow');
		    } 
		} 	
		elsif (int(@keys)) {		           ### otherwise, see if next step has been done
		    unless (int(@nextkeys)) {  
			$Schedule->Set_Cell_Colour($rownum,$colnum,'yellow');
		    } 
		}
	    }
	    $Schedule->Set_Row(\@row);
	}
	$Schedule->Printout();                          ### print out separately for each library...
	$page .= "<HR>";
    }

    return $page;    
}

################
sub Track_Plates {
################
#
# This is simply used to populate the %Found hash for the prep_status routine,
#   storing details for Plate preparation status 
#
    my %args = @_;
    
    my $dbc = $args{dbc} || $args{-dbc} || $Connection;   ## mandatory database handle
    my $condition = $args{condition};     ## plate condition
    my $check_runs = $args{check_runs};   ## flag to indicate checking for run completion (for Sequencing if applicable)
 
    my @plates = $dbc->Table_find('Plate,Tube','FK_Library__Name,Plate_ID,Plate_Number,Plate.Plate_Size',"where FK_Plate__ID=Plate_ID $condition Order by FK_Library__Name,Plate_Number,Plate_Size");

    my @groups;  ## keep track of groups in order (libraries)  
    my %Found;
    foreach my $plate (@plates) {
	my ($lib,$Pid,$Pnum,$Psize) = split ',', $plate;

	my $item = "$Pnum ($Psize)";
	
	unless (grep /^$lib$/, @groups) { push(@groups,$lib) }   ### keep track of groups
	unless (grep /^$Pnum \($Psize\)$/, @{ $Found{Items}->{$lib} }) {   ### keep track of items in groups
	    push(@{ $Found{Items}->{$lib}},$item);
	}

	push(@{ $Found{IDlist}->{$lib}->{$item} },$Pid);        ### keep list of ids for each group
    }

    foreach my $lib (keys %{ $Found{IDlist} } ) { ## for each library
	foreach my $item (keys %{ $Found{IDlist}->{$lib} } ) {  ## for each item (Plate Number etc)
	    my  ($Pnum,$Psize);
	    if ($item =~/(\d+) \((.*)\)/ ) {
		$Pnum = $1;
		$Psize = $2;
	    } else { next }  

	    my @idlist = @{ $Found{IDlist}->{$lib}->{$item} };
	    my $ids = join ',', @idlist;                                     ## populate id list for this Plate Number
	    my @setlist = $dbc->Table_find('Plate_Set','Plate_Set_Number', 
				      "where FK_Plate__ID in ($ids)");
	    my $sets = '0';
	    if ($setlist[0]=~/[1-9]/) {
		$sets = join ',', @setlist;                                  ## populate list of sets for this Plate Number
	    } 
	    
	    my $plate_set_cond = "Plate_Prep.FK_Plate_Set__Number=Plate_Set_Number AND Plate_ID=Plate_Set.FK_Plate__ID AND Prep_ID=FK_Prep__ID AND Plate_Number = $Pnum AND (FK_Plate_Set__Number in ($sets) AND (Plate_Prep.FK_Plate__ID is NULL OR Plate_Prep.FK_Plate__ID in ($ids)) )";
	    
	    my @preplist = $dbc->Table_find('Prep,Plate_Prep,Plate_Set,Plate','Prep_ID',
				       "where $plate_set_cond");
	    my $preps = '0';
	    if ($preplist[0]=~/[1-9]/) {
		$preps = join ',', @preplist;                                 ### Populate list of Prep steps
	    } 
	    $Found{Preps}->{$lib}->{$item} = $preps;
	    $Found{Sets}->{$lib}->{$item} = $sets;
	}
    }

    #print Dumper %Found;
    return %Found;
}

#####################
sub show_Prepped_Plates {
#####################
    my $dbc = shift || $Connection;
    my $condition = shift;

################# Plates Created Summary #####################

    my $PStatus = Views::sub_Heading('Tube Prep Info');

    ###### Show  Weekly Generation of Plates for this Library ###########
    my ($today) = split ' ', &date_time();
    my %Plates_Made = $dbc->Table_retrieve('Plate,Tube,Plate_Format',['FK_Plate_Format__ID as ID','Plate_Format_Type as Format','count(*) as Count','Week(Plate_Created) as Week',"Year(Plate_Created) as Year","Week('$today') as ThisWeek","Year('$today') as ThisYear"],"where FK_Plate_Format__ID=Plate_Format_ID and FK_Plate__ID=Plate_ID $condition group by FK_Plate_Format__ID,Week(Plate_Created) Order by Plate_Created Desc");

    my $thisweek = $Plates_Made{ThisWeek}[0];
    my $index = 0;
    my @weeks = ();
    my @formats = ();
    my @format_ids = ();

    while (defined $Plates_Made{ID}[$index]) {
	my $id = $Plates_Made{ID}[$index];
	my $week = $Plates_Made{Week}[$index]; 
	unless ($Plates_Made{Year}[$index] eq $Plates_Made{ThisYear}[$index]) {
	    $week -= 52 * ($Plates_Made{ThisYear}[$index] -
			   $Plates_Made{Year}[$index]);
	}
	my $format = $Plates_Made{Format}[$index];
	my $count =  $Plates_Made{Count}[$index];
	$Plates_Made{"$week:$id"} = $count;
	unless (grep /^$week$/ , @weeks) {push(@weeks,$week);}
	unless (grep /^$format$/ , @formats) {push(@formats,$format);}
	unless (grep /^$id$/ , @format_ids) {push(@format_ids,$id);}
	$index++;
    }		     
    my $Recent = HTML_Table->new();
    $Recent->Set_Headers(['<B>Plates Created</B>',@formats]);
#    $Recent->Set_Width('100%');
    $Recent->Set_Class('small');

    $index = 0;
    my %totals;    
    foreach my $week (@weeks) {   
	my @week_counts = ();
	foreach my $format_id (@format_ids) {
	    my $num = $Plates_Made{"$week:$format_id"};
	    $totals{$format_id} += $num;
	    push(@week_counts,$num);
	}
	my $title = $thisweek-$week . " Weeks Ago";
	if ($thisweek eq $week) {
	    $title = "<B>This Week</B><BR>(From Monday AM)";
	}
	elsif ($thisweek == $week+1) {
	    $title = "<B>Last Week</B>";
	}
	$Recent->Set_Row([$title,@week_counts]);
    }
    
    my @format_totals;
    foreach my $format_id (@format_ids) {
	push(@format_totals,"<B>". $totals{$format_id} . "</B>");
    }
    
    $Recent->Set_Row(["<B>Totals</B>",@format_totals],'mediumyellowbw');
    
    return $PStatus;
} 

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: GE_View.pm,v 1.11 2004/10/12 23:05:53 jsantos Exp $ (Release: $Name:  $)

=cut


return 1;
