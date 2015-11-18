#!/usr/local/bin/perl

##############################################
#
# CVS Revision: $Revision: 1.3 $
#     CVS Date: $Date: 2003/01/16 20:30:41 $
#
############################################## 

use CGI qw(:standard);
use DBI;
use POSIX;
use local::gscweb;

use SDB::CustomSettings;
 

use RGTools::RGIO;

use strict;
	
####### ET Terminator Constants ######### 

my $ET_premix = 8;
my $ET_premix_name = "DYEnamic ET Premix Solution";
my $ET_buffer = 0;
my $ET_primer = 1;
my $ET_prep = 6;      ####### DNA preparation volume #########      
my $ET_total_volume = 20;
my $ET_EtOH_factor = 60;
my $ET_OAc_factor = 2;
my $ET_OAc_name = "7.5M NH4OAc";
my $ET_glass = "96 ET";
my $ET_plate_adjustment = 0.5; ####### changed from 2.6;

####### BD Terminator Constants ##########

my $BD_premix = 2;
my $BD_premix_name = "Ready Reaction Mix";
my $BD_buffer = 0;
my $BD_primer = 0.64;
my $BD_prep = 1.5;        ####### DNA preparation volume ##########
my $BD_total_volume = 10;
#my $BD_EtOH_factor = 60;
#my $BD_EtOH_factor = 60;
#my $BD_OAc_factor = 2;
#my $BD_OAc_name = "3M NaOAC ph4.6";
my $BD_IPA_factor = 15;      ### replace EtOH, OAc
my $BD_IPA_name = "Isopropanol";

my $BD_glass = "uAMP";
my $BD_plate_adjustment = 0.5;  ####### changed from 4;

####### Create standard GSC webpage... ########

my $links = {"Protocols" => ["protocol"]};

my $page = 'gscweb'->new();
$page->SetTitle("Chemistry calculator");
$page->SetConfigFile("/home/edere/www/htdocs/config.dat");
$page->SetLinks($links);
$page->TopBar();

if (param('Calculate')) {
    if (param('Option')) {
	&calculate;
    } else {
	print h2("Need to select one of the options");
	&home;
    }
    
} elsif (param('R and D')) {
    if (param('Option')) {
	&development;
    } else {
	print h2("Need to select one of the options");
	&home;
    }
    
} else {
    &home;
}

$page->BottomBar();

##################
sub home {
#
# Generates the chemistry calculator homepage.
##################
    my @chemistries = ("ET Terminator 1X", "Big Dye Terminator 0.5X");
    my @option = ("Brew Mix", "Precipitation Reaction");
    my $dbase = "sequence";
    my $dbc = DB_Connect(dbase=>$dbase);
#    my @users = Table_find($dbc, 'Employee', 'Employee_Name', 'where Status like "Production%" or Status like "Lab%" order by Status desc');
    my @users = Table_find($dbc, 'Employee', 'Employee_Name', 'where Status like "Production" or Active_User>0 or Status like "Lab%" order by Status desc');
    $dbc->disconnect();
    
    print "<h2><span class=darkredtext>Chemistry Calculator -</span></h2>",
    start_form,
    "<TABLE cellspacing=1 border=0><TR>",
    "<TD width=120 bgcolor=#EEEEFF><BR><H4>Select User: </H4></TD><TD>",
    popup_menu(-name=>'User', -value=>[@users]),
    "</TD></TR><TR><TD width=120 bgcolor=#EEEEFF><BR><H4>Select Chemistry: </H4></TD><TD>",
    popup_menu(-name=>'Chemistry', -value=>[@chemistries]),
    "</TD><TD>",
    checkbox_group(-name=>'Option',-values=>[@option], -default=>[@option], -linebreak=>1),
    "</TD></TR><TR><TD bgcolor=#EEEEFF><BR><H4>Number of Plates: </H3></TD><TD>",
    textfield(-name=>'Plates', -value=>1,-force=>1, -size=>3, -maxlength=>3),
    "</TD></TR><TR><TD width=120 bgcolor=#EEEEFF><BR><H4>Source Plates: </H4></TD><TD>",
    textfield(-name=>'Source', -force=>1, -size=>20),
    "</TD><TD><span class=darkredtext>eg. 1340-1346,1350</span></TD></TR><TR>",
    "<TD width=120 bgcolor=#EEEEFF><BR><H4>Destination Plates: </H4></TD><TD>",
    textfield(-name=>'Destination', -force=>1, -size=>20),
    "</TD><TD><span class=darkredtext>eg. 1356-1362,1369</span></TD></TR></TABLE>",br,
    submit(-name=>'Calculate'),
    submit(-name=>'R and D'),
    end_form;   
}

#######################
sub calculate {
#
# Performs the chemistry calculations.
#######################
    my $chemistry = shift || param('Chemistry');
    my $plates = shift || param('Plates');
    my @options = ('Brew Mix','Precipitation Reaction');
    my $returnvals = shift || 0;   ###### flag to indicate values to be returned in array
    my %Mix; ##### array to return instead of display if required.

    my $user = param('User');
    my $source = param('Source');
    my $destination = param('Destination');
    my $total = param('Total');	

    my $rxns = 96;      ##### changed from 101 (now add 0.5 to number of plates)
    my $unadjusted_plates = $plates;
    my $span = "<span class=vdarkbluetext>";
    my $option = join ',', @options;
    my $date = today();
    
    unless ($returnvals) {
	print  "<H2><span class=darkredtext>Chemistry calculator: </span><span class=vdarkpurple>$chemistry</span></H2>",
	"<H4>User: $user<BR>Date: $date<BR></H4>";
    }

    #######  Brew Mix Calculator ########
    if ($option =~ /Brew Mix/) {
     	print h2("Brew Mix Calculator:");

     	my $premix;
     	my $buffer;
     	my $primer;
     	my $water;
     	my $prep;
     	my $brew;
     	my $ready_mix;
	my $per_well;
	my $primer_tubes;
	my $premix_tubes;
	my $FV;
	my $glassware;
	
	###### ET Terminator #########
     	if ($chemistry =~ /^ET/) {
	    if (param('RD')) {  # research and development mode
		$premix = param('Premix');
		$primer = param('Primer');
         	$prep = param('DNA');
           	$buffer = param('Buffer');
	    } else {
		$total = $ET_total_volume;
		$premix = $ET_premix * ($total/$ET_total_volume);
		$primer = $ET_primer * ($total/$ET_total_volume);
		$prep = $ET_prep;
		$buffer = $ET_buffer;		
	    }
	    $plates += $ET_plate_adjustment;
	    $ready_mix = $ET_premix_name;
	    $glassware = $ET_glass;
	    
	####### Big Dye Terminator ########
     	} elsif ($chemistry =~ /^Big Dye/)  {						
	    if (param('RD')) {  # research and development mode
		$premix = param('Premix');
		$primer = param('Primer');
		$prep = param('DNA');
		$buffer = param('Buffer');
	    } else {
		$total = $BD_total_volume;
		$premix = $BD_premix * ($total/$BD_total_volume);
		$primer = $BD_primer * ($total/$BD_total_volume);
		$prep = $BD_prep;
		$buffer = $BD_buffer;
	    }
	    $plates += $BD_plate_adjustment;
	    $ready_mix = $BD_premix_name;
	    $glassware = $BD_glass;
     	}
	else {print "Unrecognized Chemistry";}

	$per_well = $total - $prep;
	$FV = $per_well * $unadjusted_plates;

# Total  = N X ul/well + (Fixed amt)
# 
# For Water: Total = Total_Expected - (Totals of Other Stuff).
#
#
#
	###### the amount of water used is determined from all the other amounts ######
     	$water = $rxns * $plates * ($total - $premix - $primer - $prep - $buffer);
     	$premix *= $rxns * $plates;
     	$primer *= $rxns * $plates;

	Message("$water = $rxns x $plates * ($total - $premix - $primer - $prep - $buffer)");
	### RG Feb. 15 /2001...
	$buffer *= $rxns * $plates; 

	$primer_tubes = ceil($primer/101);
	$premix_tubes = ceil($premix/808);
     	$brew = $premix + $buffer + $primer + $water;

	if ($returnvals) {
	    %Mix->{water}=$water;
	    %Mix->{premix}=$premix;
	    %Mix->{ReadyMix} = $ready_mix;
	    %Mix->{Buffer} = $buffer;
	    %Mix->{Primer} = $primer;
	    %Mix->{Brew} = $brew;
	    %Mix->{Prep} = $prep;
	    %Mix->{PerWell} = $per_well;
	    %Mix->{FV} =$FV;
	    Message("returned..");
	}
	else {
	    print "<TABLE border=1 cellspacing=1 cellpadding=5><TR>";
	    
	    ### ddH20 ###
	    print "<TR><TD align=right bgcolor=#EEEEFF>$span" . "$water ul</span></TD>",
	    "<TD bgcolor=#FFEEEE>$span". "of 0.2um 18mOhm ddH2O</span></TD></TR>";
	    
	    if ($premix_tubes > 1) {
		print "<TD align=right bgcolor=#EEEEFF>$span" . "$premix ul ($premix_tubes tubes)</span></TD>";
	    } else {
		print "<TD align=right bgcolor=#EEEEFF>$span" . "$premix ul ($premix_tubes tube)</span></TD>";
	    }
	    print "<TD bgcolor=#FFEEEE>$span" . "of $ready_mix</span></TD></TR>";
	    
	#### Buffer ###

	    if ($chemistry !~ /ET Terminator 1X/) {
		print "<TR><TD align=right bgcolor=#EEEEFF>$span" . "$buffer ul</span></TD>",
		"<TD bgcolor=#FFEEEE>$span". "of 5X Reaction Buffer</span></TD></TR>";
	    }
	    
	    #### Primer ####
	    if ($primer_tubes > 1) {
		print "<TR><TD align=right bgcolor=#EEEEFF>$span" . "$primer ul ($primer_tubes tubes)</span></TD>";
	    } else {
		print "<TR><TD align=right bgcolor=#EEEEFF>$span" . "$primer ul ($primer_tubes tube)</span></TD>";
	    }
	    print "<TD bgcolor=#FFEEEE>$span" . "of Primer (5pmol/ul)</span></TD></TR>",
	    
	    "<TR><TD align=right bgcolor=#DDD1FF>$span" . "$brew ul</span></TD>",
	    "<TD class=vlightred>$span" . "of Brew Mix in 50ml Falcon tube</span></TD>",
	    "<TD width=10></TD><TD bgcolor=#EEEEFF>Source Plates:</TD></TR>",
	    "<TR><TD align=right bgcolor=#DDD1FF>$span" . "$prep ul/well</span></TD>",
	    "<TD class=vlightred>$span" . "Amount of DNA Prep per well</span></TD>",
	    "<TD width=10></TD><TD bgcolor=#EEEEFF>&nbsp;$source</TD></TR>",
	    "<TR><TD align=right bgcolor=#DDD1FF>$span" . "$per_well ul brew/well $glassware</span></TD>",
	    "<TD class=vlightred>$span" . "Amount of brew mix per well</span></TD>",
	    "<TD width=10></TD><TD bgcolor=#FFEEEE>Destination Plates:</TD></TR>",
	    "<TR><TD align=right bgcolor=#DDD1FF>$span" . "$FV ul</span></TD>",
	    "<TD class=vlightred>$span" . "FV Setting</span></TD>",
	    "<TD width=10></TD><TD bgcolor=#FFEEEE>&nbsp;$destination</TD></TR>",
	    "</TABLE><BR><BR>";
	}   
    }
    
    ######## Precipitation Mix Calculator #############
    if ($option =~ /Precipitation Reaction/) {
     	unless ($returnvals) {print h2("Precipitation Mix Calculator");}
     	my $EtOH;
	my $IPA;
     	my @tray = qw(3600 120);
     	my $tubes;
	my $trays;
     	my $reagent;
     	my $reagent_factor;

	####### ET Terminitor ########
     	if ($chemistry =~ /ET Terminator 1X/) {
	    if (param('RD')) {  # research and development mode
		$EtOH = param('EtOH');
           	$reagent_factor = param('Reagent');
	    } else {
		$EtOH = $ET_EtOH_factor;
		$reagent_factor = $ET_OAc_factor;
           	$total = $ET_total_volume;
	    }
	    $reagent = $ET_OAc_name;

	####### Big Dye Terminator #########
     	} else {
	    if (param('RD')) {  # research and development mode
#		$EtOH = param('EtOH');
		$IPA = param('IPA');
           	$reagent_factor = param('Reagent');
	    } else {
#		$EtOH = $BD_EtOH_factor;
#		$reagent_factor = $BD_OAc_factor;
		$IPA = $BD_IPA_factor;
		$reagent_factor = $BD_IPA_factor;
           	$total = $BD_total_volume;
	    }
#	    $reagent = $BD_OAc_name;
	    $reagent = $BD_IPA_name;
     	}
	
	### total_default = 10;

	$EtOH = $EtOH * $rxns * $unadjusted_plates * ($total/$ET_total_volume);
	$IPA = $BD_IPA_factor * $rxns * $unadjusted_plates * ($total/$BD_total_volume);
     	$tubes = ceil(($EtOH+$tray[0])/50000);
	$trays = $tubes;
     	$EtOH += $tray[0];
     	$IPA += $tray[0];
     	$EtOH /= $tubes;
	$EtOH = sprintf("%0.3f", $EtOH/1000);
	$IPA = sprintf("%0.3f", $IPA/1000);
	if ($chemistry=~/ET Terminator 1X/) {
	    $reagent_factor = (($reagent_factor * $rxns * $unadjusted_plates * ($total/$ET_total_volume)) + $tray[1])/$tubes;
	}
	else {
	    $reagent_factor = (($reagent_factor * $rxns * $unadjusted_plates * ($total/$BD_total_volume)) + $tray[1])/$tubes;
	}
	$reagent_factor = sprintf("%0.1f", $reagent_factor);
 

	
	if ($returnvals) {
	    %Mix->{Isopropanol} = $IPA;
	    %Mix->{EtOH} = $EtOH;
	    %Mix->{reagent} = $reagent_factor/1000.0;
	    Message("Returned PR : ");
	}
	else {
	    print "<TABLE border=1 cellspacing=1 cellpadding=5><TR>",
	    "<TD align=right bgcolor=#DDD1FF>$span" . "$tubes</span></TD>",
	    "<TD class=vlightred>$span" . "Number of 50ml Falcon Tubes required</span></TD></TR>",
	    "<TR><TD align=right bgcolor=#DDD1FF>$span" . "$trays</span></TD>",
	    "<TD class=vlightred>$span" . "Number of V-Trays required</span></TD></TR>";
	    if ($chemistry =~ /ET Terminator 1X/) {
		print "<TR><TD align=right bgcolor=#DDD1FF>$span" . "$EtOH ml/tube</span></TD>",
		"<TD class=vlightred>$span" . "of 95% EtOH</span></TD></TR>",
		"<TR><TD align=right bgcolor=#DDD1FF>$span" . "$reagent_factor ul/tube</span></TD>",
		"<TD class=vlightred>$span" . "of $reagent</span></TD></TR>";
	    }
	    else {
		print "<TR><TD align=right bgcolor=#DDD1FF>$span" . "$IPA ml</span></TD>",
		"<TD class=vlightred>$span" . "of Isopropanol</span></TD></TR>";
	    }
	    "</TABLE>";
	    
	    if ($tubes > 1) {
		print h4("Add the contents of the $tubes Falcon tubes to the $trays V-trays");
	    } else {
		print h4("Add the contents of the Falcon tube to the V-tray");
	    }
	}
    }
    
    if ($returnvals) {return %Mix;}
}


#########################
sub development {
#
# Generates the web form for Research and Development.
# 
########################
    my $chemistry = param('Chemistry');
    my $plates = param('Plates');
    my $user = param('User');
    my @options = param('Option');
    my $source = param('Source');
    my $destination = param('Destination');

    my $premix;
    my $reagent;
    my $option = join ',', @options;
    
    if ($chemistry =~ /ET Terminator 1X/) {
	$premix = $ET_premix_name . ":";
	$reagent = $ET_OAc_name .":";
    } else {
	$premix = $BD_premix_name . ":";
	$reagent = $BD_IPA_name . ":";
    }

    print "<H1>Research and Development: <span class=vdarkpurple>$chemistry</span></H1><BR>",
    start_form,
    "<TABLE border=0 cellspacing=1><TR><TD width=145 class=vlightred>",
    "<BR><H4>Number of Plates: </H4></TD><TD>",
    textfield(-name=>'Plates', -value=>"$plates", -force=>1, -size=>5, -maxlength=>5),
    "</TD></TR><TR><TD class=vlightred>",
    "<BR><H4>Total Volume: </H4></TD><TD>";
    
    if ($chemistry =~ /ET Terminator 1X/) {
   	print textfield(-name=>'Total', -value=>"$ET_total_volume", -force=>1, -size=>5, -maxlength=>5);
    } else {
   	print textfield(-name=>'Total', -value=>"$BD_total_volume", -force=>1, -size=>5, -maxlength=>5);
    }
    print " ul/well</TD></TR></TABLE>";

    ###### Brew Mix Calculator ##########
    if ($option =~ /Brew Mix/) {
	print h2("Brew Mix Calculator"),
	"<TABLE border=0 cellspacing=1><TR><TD width=145 bgcolor=#EEEEFF><BR><H4>$premix </H4></TD><TD>";

	if ($chemistry =~ /ET Terminator 1X/) {
	    print textfield(-name=>'Premix', -value=>$ET_premix, -force=>1, -size=>5, -maxlength=>5);
	} else {
	    print textfield(-name=>'Premix', -value=>$BD_premix, -force=>1, -size=>5, -maxlength=>5);
	}
	print " ul/well</TD></TR><TR><TD bgcolor=#EEEEFF><BR><H4>5X Reaction Buffer: </H4></TD><TD>";
	if ($chemistry =~ /ET Terminator 1X/) {
	    print textfield(-name=>'Buffer', -value=>"$ET_buffer", -force=>1, -size=>5, -maxlength=>5);
	} else {
	    print textfield(-name=>'Buffer', -value=>"$BD_buffer", -force=>1, -size=>5, -maxlength=>5);
	}
	print " ul/well</TD></TR><TR><TD bgcolor=#EEEEFF><BR><H4>Primer (5pmol/ul): </H4></TD><TD>";
	if ($chemistry =~ /ET Terminator 1X/) {
	    print textfield(-name=>'Primer', -value=>"$ET_primer", -force=>1, -size=>5, -maxlength=>5);
	} else {
	    print textfield(-name=>'Primer', -value=>"$BD_primer", -force=>1, -size=>5, -maxlength=>5);
	}
	print " ul/well</TD></TR><TR><TD bgcolor=#EEEEFF><BR><H4>DNA Prep: </H4></TD><TD>";
	if ($chemistry =~ /ET Terminator 1X/) {
	    print textfield(-name=>'DNA', -value=>"$ET_prep", -force=>1, -size=>5, -maxlength=>5);
	} else {
	    print textfield(-name=>'DNA', -value=>"$BD_prep", -force=>1, -size=>5, -maxlength=>5);
	}
	print " ul/well</TD></TR></TABLE><BR>";
    } 

    ######## Precipitation Mix Calculator #############
    if ($option =~ /Precipitation Reaction/) {
	print h2("Precipitation Mix Calculator"),
	"<TABLE border=0 cellspacing=1><TR>",
	"<TD width=145 bgcolor=#EEEEFF><BR><H4>95% EtOH: </H4></TD><TD>";
	my $default;

	if ($chemistry =~ /ET Terminator 1X/) {
	    $default = $ET_EtOH_factor * ($ET_total_volume/$ET_total_volume);
	    print textfield(-name=>'EtOH', -value=>"$default", -force=>1, -size=>5, -maxlength=>5);
	} else {
#	    $default = $BD_EtOH_factor * ($BD_total_volume/$total_default);
#	    print textfield(-name=>'EtOH', -value=>"$default", -force=>1, -size=>5, -maxlength=>5);
	    $default = $BD_IPA_factor * ($BD_total_volume/$BD_total_volume);
	    print textfield(-name=>'IPA', -value=>"$default", -force=>1, -size=>5, -maxlength=>5);
	}
	print " ul/well</TD></TR><TR><TD bgcolor=#EEEEFF><BR><H4>$reagent </H4></TD><TD>";

	if ($chemistry =~ /ET Terminator 1X/) {
	    $default = $ET_OAc_factor * ($ET_total_volume/$ET_total_volume);
	    print textfield(-name=>'Reagent', -value=>"$default", -force=>1, -size=>5, -maxlength=>5);
	} else {
	    $default = $BD_IPA_factor * ($BD_total_volume/$BD_total_volume);
	    print textfield(-name=>'Reagent', -value=>"$default", -force=>1, -size=>5, -maxlength=>5);
	}
	print " ul/well</TD></TR></TABLE><BR>";
    }
    
    print hidden(-name=>'Chemistry', -value=>"$chemistry"),
    hidden(-name=>'Option', -value=>"@options"),
    hidden(-name=>'RD', -value=>'RD'),
    hidden(-name=>'User', -value=>"$user"),
    hidden(-name=>'Source', -value=>"$source"),
    hidden(-name=>'Destination', -value=>"$destination"),
    submit(-name=>'Calculate');
    end_form;
}

