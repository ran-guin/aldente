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
# $Id: Lab_View.pm,v 1.21 2004/11/24 01:09:42 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.21 $ 
#     CVS Date: $Date: 2004/11/24 01:09:42 $
################################################################################
package Sequencing::Lab_View;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Lab_View.pm - This modules provides various views of Laboratory Status 

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This modules provides various views of Laboratory Status <BR>prep_status - view of preparation history by library or by date.<BR>

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
use alDente::Run;
use Sequencing::Sample_Sheet;           ### allow primer extraction routine..
use alDente::SDB_Defaults;
use SDB::DBIO;
use SDB::CustomSettings;
use SDB::HTML;
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
    my $dbc           = $args{dbc          } || $Connection;         ## Mandatory database handle
    my $library       = $args{library      }; ## library name 
    my $plate_numbers = $args{plates       }; ## optional list of plates
    my $date_min      = $args{from         };        ## show only where Date AFTER date_min
    my $date_max      = $args{to           };          ## show only where Date BEFORE date_max
    my $days_ago      = $args{days         };   ## show status for past $days_ago days.. 
    my $include       = $args{include      } || $args{library};  ## include completed runs (defaults on when Library specified)...
    my $details       = $args{details      } || 0;
    my $track_primers = $args{track_primers} || 0;

	my $homelink = $dbc->homelink();
	
    my $show_empty = 0;  ### show rows with no plates at all

    my $t1 = new Benchmark;

    my $page = page_heading("Prep Summary");
### Provide Link to Edit Preparation Tracking Settings (administrative permissions ) #### 
    $page .= Link_To( $homelink,
                   "Edit Prep Tracking Settings",
                   "&Info=1&Table=Protocol_Tracking",
                   'red',
                   ['newwin'] ) . &vspace(5);

    my @preps;
    my %Libs;
    my @plate_names;
    
### Generate conditions ###
    
    my $condition;
    my $Pcondition;
    #if (!$library) {         ### if no library selected, look for recently prepped/created plates...
    #    $date_min ||= date_time('-' . $days_ago . 'd');
    #    Message("Get preps since $date_min.");
    #
    #    ### Find Preparation steps completed since date_min ###
    #    @preps = $dbc->Table_find('Prep,Plate_Prep,Plate',
    #                              'FK_Library__Name,Plate_Number',
    #                              "where Plate_Prep.FK_Plate__ID=Plate_ID AND Prep_ID=FK_Prep__ID AND Prep_DateTime > '$date_min'",'Distinct');
    #
    #    foreach my $prep (@preps) {      ### Generate list of recently used Libraries, Plate Numbers...
    #        my ($lib,$plate_number) = split ',', $prep;
    #        $Libs{$lib} = 1;
    #        push(@plate_names,"$lib$plate_number");
    #    }
    #
    #    my $plates = join "','",@plate_names;
    #    $condition = "AND concat(FK_Library__Name,Plate_Number) in ('$plates')";
    #}
    #else {    ### if Library specified store library and (optionally) plate numbers 
    #    if ($library =~ /(.*):/) { $library = $1; }
    #    $Libs{$library} = 1;
    #    $condition = "AND FK_Library__Name='$library'";
    #
    #    if ($plate_numbers) { 
    #        $plate_numbers = &extract_range($plate_numbers);
    #        $condition    .= " AND Plate_Number in ($plate_numbers)";
    #    }
    #}

    ### Change logic from OR to AND, uncomment above and comment below until (not including) $Pcondition = "$condition";
    ### Change my $days_ago      = $args{days         }; to my $days_ago      = $args{days         } || 5; to revert
    if ($library =~ /(.*):/) { $library = $1; }
    if ($library) {
	$Libs{$library} = 1;
	$condition = "AND FK_Library__Name='$library'";
    }
    
    if ($plate_numbers) {
	$plate_numbers = &extract_range($plate_numbers);
	$condition    .= " AND Plate_Number in ($plate_numbers)";
    }

    if ($days_ago) {
	$date_min ||= date_time('-' . $days_ago . 'd');
	Message("Get preps since $date_min.");
	
	### Find Preparation steps completed since date_min ###
	@preps = $dbc->Table_find('Prep,Plate_Prep,Plate',
				  'FK_Library__Name,Plate_Number',
				  "where Plate_Prep.FK_Plate__ID=Plate_ID AND Prep_ID=FK_Prep__ID AND Prep_DateTime > '$date_min' $condition",'Distinct');
	
	foreach my $prep (@preps) {      ### Generate list of recently used Libraries, Plate Numbers...
	    my ($lib,$plate_number) = split ',', $prep;
	    $Libs{$lib} = 1;
	    push(@plate_names,"$lib$plate_number");
	}
    
    
	my $plates = join "','",@plate_names;
	$condition = "AND concat(FK_Library__Name,Plate_Number) in ('$plates')";
    }


    $Pcondition = "$condition";

    my @libs = keys %Libs;
    
    ### show detailed Library Preparation status only when Library chosen ###      
    if ($library && $details) {
        $page .= show_Prepped_Plates($dbc, $condition);
    }

    ### Search for data based on Plate info and tracked steps... 

    my $label = "concat(FK_Library__Name,Plate_Number,Parent_Quadrant,' (',Plate_Size,') - ',Plate.Plate_Class)";
    my %Found = Track_Plates( dbc=>$dbc, condition=>$condition, check_runs=>1 );

    ### Track Steps completed ..### 

    my $groups = $dbc->get_local('group_list'); 
    my @steps  = $dbc->Table_find( 'Protocol_Tracking,Grp',
                                   'Protocol_Tracking_Title,Protocol_Tracking_Step_Name,Protocol_Tracking_Type',
                                   "where Protocol_Tracking_Status = 'Active' AND FK_Grp__ID=Grp_ID AND Grp_ID IN ($groups) Order by Protocol_Tracking_Order");

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
            my @plastic = $dbc->Table_find_array( "Plate,Plate_Format,Library_Plate",
                                                  ['FK_Library__Name','Plate_ID',"$label as Plabel"],
                                                  "where FK_Plate_Format__ID=Plate_Format_ID AND Plate_ID=FK_Plate__ID AND Plate_Format_Type regexp '$track_step' $Pcondition Order by FK_Library__Name,Plate_Number,Plate.Parent_Quadrant,Plate_Size");
            foreach my $plate (@plastic) {   ### regardless of Preparation stages... 
                my ($lib,$plate_id,$Plabel) = split ',', $plate;
                $Found{IDs}->{$lib}->{"$Plabel"}->{$step_num}->{$plate_id} = 1;
            }
        }
        else {
            foreach my $lib (keys %{ $Found{IDlist} }) {
                foreach my $item ( keys %{ $Found{IDlist}->{$lib}} ) {
                    my $item_condition = "AND $label = '$lib$item'";
                    my $preps          = $Found{Preps}->{$lib}->{$item};

                    unless ($preps) {next}

                    if ($track_step =~ /Brew/) {  ### check type of brew dispensed
                        my @brews = $dbc->Table_find_array("Prep,Plate_Prep,Solution,Stock,Stock_Catalog",
                                                           ['Prep_ID','Left(Stock_Catalog_Name,2)'],
                                                           "WHERE Prep_ID = Plate_Prep.FK_Prep__ID AND FK_Stock__ID=Stock_ID AND Stock_Catalog_ID = FK_Stock_Catalog__ID AND Plate_Prep.FK_Solution__ID=Solution_ID AND Prep_Name like '$track_step' AND Prep_ID in ($preps) Order by Left(Stock_Catalog_Name,2)");

                        foreach my $brew (@brews) {
                            my ($prep_id,$brew) = split ',', $brew;

                            my $plates = join ',', $dbc->Table_find_array( "Prep,Plate_Prep,Plate LEFT JOIN Library_Plate ON Library_Plate.FK_Plate__ID=Plate_ID",
                                                                           ['Plate_ID'],
                                                                           "where Prep_ID in ($prep_id) AND Prep_ID=FK_Prep__ID AND Plate_Prep.FK_Plate__ID=Plate_ID $Pcondition $item_condition",
                                                                           -distinct=>1);
                            $Found{IDs}->{$lib}->{$item}->{$step_num}->{$brew}->{$prep_id} = $plates;
                        }
                    }
                    else {      ### Track Steps taken within Protocols ###
                        my @trackplates = $dbc->Table_find( "Prep",
                                                            'Prep_ID',
                                                            "where Prep_Name like '$track_step%' AND Prep_ID in ($preps)");
                        foreach my $prep_id (@trackplates) {
                            my $plates = join ',', $dbc->Table_find_array("Prep,Plate_Prep,Plate LEFT JOIN Library_Plate ON Library_Plate.FK_Plate__ID=Plate_ID",
                                                                          ['Plate_ID'],
                                                                          "where Prep_ID in ($prep_id) AND Prep_ID=FK_Prep__ID AND Plate_Prep.FK_Plate__ID=Plate_ID $Pcondition $item_condition",
                                                                          -distinct=>1);
                            $Found{IDs}->{$lib}->{$item}->{$step_num}->{$prep_id} = $plates;
                        }
                    }
                }
            }
        }
    }
    ### Generate Schedule ###

    my @headers = ("Plate",@{ $Found{Steps} });
    my $title   = "$library Library Plates";

    unless ($include)  { $title .= " (Completed plates excluded)"; }

    if     (!$library) { @headers = ('Library',@headers) }
    else               { $page .= section_heading($title) }

    my @groups = sort keys %{$Found{Items}} ;
    foreach my $group (@groups) {       ### For each group (Library) 
        my $rownum  = 0;
        my @primers = @{ $Found{PrimerList}->{$group} };
        my @more_headers;

        foreach my $primer (@primers) {
            push(@more_headers,'IP');
            push(@more_headers,$primer);
        }

        my $Schedule = HTML_Table->new();
        $Schedule->Set_Width('100%');
        $Schedule->Set_Headers([@headers,@more_headers]);
        $Schedule->Set_Class('small');

        unless (defined $Found{Items}->{$group}) { next }

        my @items = @{ $Found{Items}->{$group} };
        foreach my $item (@items) {     ### For each row item (Plate Number) 
            if (!$include && ($Found{Complete}->{$group}->{$item} =~/Yes/i)) { next }  ### ignore completed plates if desired

            $rownum++;
            my @row;
            if   ($library) { @row = ("<B>$item</B>") }
            else            { @row = ("<B>$group<B>","<B>$item</B>") }

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
                        my $link = Show_Tool_Tip(
                            &Link_To($homelink,$count,"&Info=1&Table=Plate&Field=Plate_ID&Like=$idlist",'black',['newwin']),
                            "Check this list of plates") if $idlist;
                        $link ||= "(no plates)";
                        push(@show,$link);
                    }
                    elsif ($step_tracked=~/brew/i) {   #### Brew tracking 
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
                            my $plate_link = Show_Tool_Tip(
                                &Link_To($homelink,"$brew : $count","&Info=1&Table=Plate&Field=Plate_ID&Like=$platelist",'black',['newwin']),
                                "Check list of plates for $brew") if $platelist;
                            $plate_link ||= "(no brews)";
			    
                            #			    my $plate_link = &Link_To($homelink,"$brew : $count","&Info=1&Table=Plate&Field=Plate_ID&Like=$platelist",'black',['newwin']);
                            my $preplist = join ',', @preps;
                            my $prepcount = int(@preps);

                            my $prep_link = Show_Tool_Tip(
                                &Link_To($homelink,"(prep $prepcount)","&Info=1&Table=Prep&Field=Prep_ID&Like=$preplist",'black',['newwin']),
                                "Check list of preps") if $preplist;
                            $prep_link ||= "(no preps)";

                            push(@show,"$plate_link $prep_link");
                        }
                    }
                    else {                            ### other Step tracking
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
                            my $plate_link = Show_Tool_Tip(
                                &Link_To($homelink,"$count","&Info=1&Table=Plate&Field=Plate_ID&Like=$platelist",'black',['newwin']),
                                "show plates") if $platelist;
                            $plate_link ||= '(no plates)';

                            my $preplist = join ',', @list;
                            my $prepcount = int(@list);
                            my $prep_link = Show_Tool_Tip(
                                &Link_To($homelink,"(prep $prepcount)","&Info=1&Table=Prep&Field=Prep_ID&Like=$preplist",'black',['newwin']),
                                "show preps") if $preplist;
                            $prep_link ||= '(no preps)';

                            push(@show,"$plate_link $prep_link");
                        }
                        else { push(@show,"-") }
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
            
            ### show completed, in process runs for EACH suggested Primer...

            foreach my $primer_num (1..$Found{Primers}->{$group}) {
                my $IP = $Found{IP}->{$primer_num}->{$group}->{$item};
                push(@row, "$IP");
                $colnum++;
                if   ($IP) { $Schedule->Set_Cell_Colour($rownum,$colnum,'yellow'); }
                else       { $Schedule->Set_Cell_Colour($rownum,$colnum,'lightyellow') }

                my $sequenced = $Found{Sequenced}->{$primer_num}->{$group}->{$item};
                push(@row, "$sequenced");
                $colnum++;
                if   ($sequenced) { $Schedule->Set_Cell_Colour($rownum,$colnum,'lightgrey'); }
                else              { $Schedule->Set_Cell_Colour($rownum,$colnum,'gray') }
            }
            $Schedule->Set_Row(\@row);
        }
        $page .= $Schedule->Printout(0);                          ### print out separately for each library...
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
    
    my $dbc        = $args{dbc       } || $Connection;   ## mandatory database handle
    my $condition  = $args{condition };                  ## plate condition
    my $check_runs = $args{check_runs};                  ## flag to indicate checking for run completion (for Sequencing if applicable)
    my $label      = $args{label     };                  ## <CONSTRUCTION>  make sure this syncs with the label 'NumQuad (Size) - Class'

	my $homelink = $dbc->homelink();
	
    my @plates = $dbc->Table_find_array( 'Plate,Library_Plate',
                                         ['FK_Library__Name','Plate_ID','Plate_Number','Plate.Parent_Quadrant','Plate.Plate_Size','Plate.Plate_Class'],
                                         "where FK_Plate__ID=Plate_ID $condition Order by FK_Library__Name,Plate_Number,Parent_Quadrant,Plate_Size");

    my @groups;  ## keep track of groups in order (libraries)
    my %Found;
    foreach my $plate (@plates) {
        my ($lib,$Pid,$Pnum,$Pquad,$Psize,$Pclass) = split ',', $plate;
	
        my $item = "$Pnum$Pquad ($Psize) - $Pclass";
	
        unless (grep /^$lib$/, @groups) { push(@groups,$lib) }   ### keep track of groups
        unless (grep /^$Pnum$Pquad \($Psize\) \- $Pclass$/, @{ $Found{Items}->{$lib} }) {   ### keep track of items in groups
            push(@{ $Found{Items}->{$lib}},$item);
        }
        push(@{ $Found{IDlist}->{$lib}->{$item} },$Pid);        ### keep list of ids for each group
    }


    foreach my $lib (keys %{ $Found{IDlist} } ) { ## for each library
        my @primers = $dbc->Table_find( 'LibraryApplication,Primer,Object_Class',
                                        'Primer_Name',
                                        "where FK_Library__Name = '$lib' and Object_ID = Primer_ID and Object_Class_ID = FK_Object_Class__ID and Object_Class='Primer'");
        $Found{Primers   }->{$lib} = int(@primers);
        $Found{PrimerList}->{$lib} = \@primers;
        foreach my $item (keys %{ $Found{IDlist}->{$lib} } ) {  ## for each item (Plate Number etc)
            my  ($Pnum,$Pquad,$Psize);
            if ($item =~/(\d+)([a-zA-Z]?) \((.*)\)/ ) {
                $Pnum  = $1;
                $Pquad = $2; 
                $Psize = $3;
            }
            else { next }  

            my @idlist = @{ $Found{IDlist}->{$lib}->{$item} };
            my $ids = join ',', @idlist;                                     ## populate id list for this Plate Number
#	    my @setlist = $dbc->Table_find('Plate_Set','Plate_Set_Number', 
#				      "where FK_Plate__ID in ($ids)");
#	    my $sets = '0';
#	    if ($setlist[0]=~/[1-9]/) {
#		$sets = join ',', @setlist;                                  ## populate list of sets for this Plate Number
#	    } 
	    
            my $plate_set_cond = "Plate_ID=Plate_Prep.FK_Plate__ID AND Plate_ID=Library_Plate.FK_Plate__ID AND Prep_ID=FK_Prep__ID AND Plate_Number = $Pnum AND Plate.Parent_Quadrant = '$Pquad' AND Plate_Prep.FK_Plate__ID in ($ids)";
	    
            my @preplist = $dbc->Table_find('Prep,Plate_Prep,Plate,Library_Plate',
                                            'Prep_ID',
                                            "where $plate_set_cond");
            my $preps = '0';
            if ($preplist[0]=~/[1-9]/) {
                $preps = join ',', @preplist;                                 ### Populate list of Prep steps
            } 
            $Found{Preps}->{$lib}->{$item} = $preps;
            #	    $Found{Sets}->{$lib}->{$item} = $sets;

            my $primer_num = 0;
            my $Snum = join ',',$dbc->Table_find('Run','count(*)',"where Run_Directory like '$lib$Pnum$Pquad.%'");
	    
            unless ($check_runs) { next }  ## the following only applies to tracking sequencing runs ...

            ## Set flag to indicate runs for all 'suggested' primers finished ##
            if   (int(@primers)) { $Found{Complete}->{$lib}->{$item} = 'Yes'; }
            else                 { $Found{Complete}->{$lib}->{$item} = 'No'; }     ## preset to 1; then fail if any primer runs are missing

            foreach my $primer (@primers) {
                $primer_num++;
                my @IP;
                my $IPnum;
                my @sequenced;
                my $run;          
                my $applied;
                if ($Snum) {
                    @sequenced = $dbc->Table_find( 'Stock_Catalog,Run,SequenceRun,Solution left join Stock on FK_Stock__ID=Stock_ID',
                                                   'Run_ID',
                                                   "where FK_Stock_Catalog__ID= Stock_Catalog_ID AND FK_Run__ID=Run_ID AND Run_Directory like '$lib$Pnum$Pquad.%' and FKPrimer_Solution__ID=Solution_ID and Stock_Catalog_Name = '$primer' and (Run_DateTime like '2%' and Run_Status like 'Analyzed' AND Run_Validation='Approved') Order by Run_DateTime desc");

                    @IP = $dbc->Table_find( 'Stock_Catalog,Run,SequenceRun,Solution left join Stock on FK_Stock__ID=Stock_ID',
                                            'Run_ID',
                                            "where FK_Stock_Catalog__ID= Stock_Catalog_ID AND FK_Run__ID=Run_ID AND Run_Directory like '$lib$Pnum$Pquad.%' and FKPrimer_Solution__ID=Solution_ID and Stock_Catalog_Name = '$primer' and (Run_DateTime like '0%' or Run_Status IN ('Initiated','In Process','Data Acquired') or Run_Validation like 'Pending') Order by Run_DateTime desc");
### Check for application of Primers to these Plates (slower ?).. #		    
#		my ($Aprimer,$Pname,$Pfound) = &get_primer($dbc,$ids,'quiet');
#		my ($primer,$Pname,$found) = &Sequencing::Sample_Sheet::get_primer($dbc,$check_id,'quiet');

                }
                if ($sequenced[0]=~/[1-9]/) {   ######## provide link back to Last 24 Hours Page... ##########
		    my $project_path = &alDente::Run::get_data_path(-dbc=>$dbc,-run_id=>$sequenced[0], -simple=>1);
                    my $img = "<Img src ='/dynamic/data_home/private/Projects/$project_path/phd_dir/Run$sequenced[0].png'</A></TD>";
                    $run = int(@sequenced) .'-'. 
                        Show_Tool_Tip(
                            &Link_To($homelink,$img,"&SeqRun_View=$sequenced[0]",'black',['newwin']),
                            "Most recent approved run");
                }
                else {$run = 0}

                if ($IP[0]=~/[1-9]/) {
                    my $IPlist = join ',',@IP;
                    $IPnum = Show_Tool_Tip(
                        &Link_To($homelink,int(@IP),"&Last+24+Hours=1&Any+Date=1&Library_Name=$lib&Run+Plate+Number=$Pnum",'black',['newwin']),
                        "Still Running or Pending Approval (click here to check/edit runs)");
                }
                else { $IPnum = 0 }

                unless ($run || $IPnum) { $Found{Complete}->{$lib}->{$item} = 'No';}  ### Set as incomplete if primer run still missing..
                $Found{Sequenced}->{$primer_num}->{$lib}->{$item} = $run;
                $Found{IP       }->{$primer_num}->{$lib}->{$item} = $IPnum;
            }
        }
    }

    return %Found;
}

#####################
sub show_Prepped_Plates {
#####################
    my $dbc = shift;
    my $condition = shift || 1;

    unless ($condition =~/^\s*AND /i) { $condition = "AND $condition"; }
    my $include_test = param('Include Test Runs');

    my $run_condition = $condition;
    unless ($include_test) { $run_condition .= "AND Run_Test_Status like 'Production'" }

    ################# Plates Created Summary #####################

    my $PStatus = Views::sub_Heading('Plate Prep Info');

    ###### Show  Weekly Generation of Plates for this Library ###########
    my ($today) = split ' ', &date_time();

    my %Plates_Made = &Table_retrieve( $dbc,
                                       'Plate,Library_Plate,Plate_Format',
                                       ['FK_Plate_Format__ID as ID','Plate_Format_Type as Format','count(*) as Count','Week(Plate_Created) as Week',"Year(Plate_Created) as Year","Week('$today') as ThisWeek","Year('$today') as ThisYear"],
                                       "where FK_Plate_Format__ID=Plate_Format_ID AND FK_Plate__ID=Plate_ID $condition group by FK_Plate_Format__ID,Week(Plate_Created) Order by Plate_Created Desc");

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
    
#####################  Growth Summary... ###################
    if (0) {
        my @latest = $dbc->Table_find( 'Plate,Library_Plate',
                                       'Plate_Number,Parent_Quadrant,Max(Plate_Created)',
                                       "where 1 AND Plate_ID=FK_Plate__ID $condition Group by Plate_Number,Parent_Quadrant Order by Plate_Number, FKParent_Plate__ID desc, Parent_Quadrant");  ### order to place originals AFTER quadrants...

        my @plate_list;
        my @Formats;
        my @NoGrows;
        my @SlowGrows;
        my @Unused;

        my $total_nogrows = 0;
        my $total_slowgrows = 0;
        my $total_unused = 0;

        $PStatus .= &start_custom_form('Growth',undef,%Parameters);
        my $lastnum;
        my $Growth_message = "Growth of Plates"; 

        foreach my $format (@latest) {
            (my $number,my $quad,my $created) = split ',', $format;
            if (!$quad && ($lastnum == $number)) {next;}  ## ignore original plates if subplates exist.
            push(@plate_list,"$number$quad");
            my %info = &Table_retrieve( $dbc,
                                        'Plate,Library_Plate,Plate_Format',
                                        ['Library_Plate.No_Grows','Library_Plate.Slow_Grows','Library_Plate.Unused_Wells','Plate_Format_Type as Format'],
                                        "where FK_Plate__ID=Plate_ID and Plate_Number=$number and Plate.Parent_Quadrant='$quad' AND Plate_Created='$created' $condition");

            my $nogrows   = $info{No_Grows    }[0] || '-';
            my $slowgrows = $info{Slow_Grows  }[0] || '-';
            my $unused    = $info{Unused_Wells}[0] || '-';
            my $format    = $info{Format      }[0];

            $format =~ /(\S*)$/;
            $format =  $1;

            ##### send hidden message for retrieval through checkbox... ######
            $PStatus .= hidden(-name=>"NoGrows $number $quad:",   -value=>$nogrows);
            $PStatus .= hidden(-name=>"SlowGrows $number $quad:", -value=>$slowgrows);
            $PStatus .= hidden(-name=>"Unused $number $quad:",    -value=>$unused);

            if ($nogrows=~/\d/)   { $total_nogrows   += scalar(my @list = split ',', $nogrows);}
            if ($slowgrows=~/\d/) { $total_slowgrows += scalar(my @list = split ',', $slowgrows);}
            if ($unused=~/\d/)    { $total_unused    += scalar(my @list = split ',', $unused);}

            if (length($nogrows)   > 25) {$nogrows   = substr($nogrows,0,25)   . "...";}
            if (length($slowgrows) > 25) {$slowgrows = substr($slowgrows,0,25) . "...";}
            if (length($unused)    > 25) {$unused    = substr($unused,0,25)    . "...";}

            push(@NoGrows,$nogrows);
            push(@SlowGrows,$slowgrows);
            push(@Unused,$unused);
            push(@Formats,$format);
            $lastnum = $number;
        }

        my $Grows=HTML_Table->new();
        $Grows->Set_Class('small');
        $Grows->Set_Title('<B>No Grows/Slow Grows in Most Recent Plates</B>');
        $Grows->Set_Headers([' ','No Grows','Slow Grows','(Unused Wells)']);

        $Grows->Set_Row(['<B>Totals:</B>',"<B>$total_nogrows</B>","<b>$total_slowgrows</b>","<B>$total_unused</B>"],'mediumyellowbw');

        $PStatus = "<Table><TR>\n<TD>"
                 . $Recent->Printout(0)
                 . "</TD><TD>"
                 . hspace(100)
                 . "</TD><TD valign=top>\n"
                 . $Grows->Printout(0)
                 . "<BR>";

        $PStatus .= "\n</TD></TR></Table>\n";
        $PStatus .= "</FORM>";
    }
    ######### Print out

    my $RunStatus .= Views::sub_Heading('Post Analysis Info',undef,undef,undef,5,0,1);
    
    #Now retrieve growth info from database.
    if ($include_test) {  
        $RunStatus .= &Views::sub_Heading("Including Test Runs (As of last night)",-2,'class = mediumredbw',undef,5,0,1) 
	}
    else { 
        $RunStatus .= &Views::sub_Heading("Excluding Test Runs (As of last night)",-2,'class = mediumredbw',undef,5,0,1) 
	}
    
    my ($info) = $dbc->Table_find_array( 'Plate,Run,SequenceRun,SequenceAnalysis',
                                         ['count(*)','Sum(Wells)', 'Sum(NGs)','Sum(SGs)'],
                                         "where FK_Run__ID=Run_ID AND Plate.Plate_ID = Run.FK_Plate__ID AND SequenceRun_ID = SequenceAnalysis.FK_SequenceRun__ID $run_condition");
    
    my ($runs,$wells,$ngs,$sgs) = split ',', $info;
    $runs  += 0;
    $wells += 0;
    $ngs   += 0;
    $sgs   += 0;
    
    $RunStatus .= "<P><B>Runs: $runs;<BR>Reads: $wells;</B> (excluding Unused Wells)<BR>No Grows: $ngs;<BR>Slow Grows: $sgs;<P>\n";

    ############ Get Bin counts....
    if ($runs) {
        $RunStatus .= &vspace();
        my $title = "P20 quality / Read";
        my @Data = $dbc->Table_find_array('SequenceAnalysis,Run,SequenceRun,Plate',
                                          ['Q20array'],
                                          "where FK_Run__ID=Run_ID AND FK_SequenceRun__ID=SequenceRun_ID AND FK_Plate__ID=Plate_ID $run_condition");
	
        my @q20_total = ();
        foreach my $q20 (@Data) {
            my @thisdata = unpack 'S*', $q20;
            push(@q20_total,@thisdata);
        }
        $RunStatus .= &Sequencing::Sequence::Bin_counts(\@q20_total,'type'=>'dist','title'=>$title);
    }

    ## put tables together.. ##
    $PStatus = "<Table><TR>\n<TD valign>".
        $Recent->Printout(0) . 
            "</TD><TD>". hspace(100) . "</TD><TD valign=top>\n".
                $RunStatus . "<BR>";
    
    $PStatus .= "\n</TD></TR></Table>\n";
    $PStatus .= "</FORM>";

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

$Id: Lab_View.pm,v 1.21 2004/11/24 01:09:42 rguin Exp $ (Release: $Name:  $)

=cut


return 1;
