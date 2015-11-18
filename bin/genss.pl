#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

genss.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>This program generates Sample Sheets for Sequencing Runs (and updates database)<BR>

=cut

##############################
# superclasses               #
##############################
################################################################################
# genss.pl
#
# This program generates Sample Sheets for Sequencing Runs (and updates database)
# 
################################################################################
################################################################################
# $Id: genss.pl,v 1.7 2004/09/29 01:36:04 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.7 $
#     CVS Date: $Date: 2004/09/29 01:36:04 $
################################################################################

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw();

##############################
# standard_modules_ref       #
##############################

use CGI qw(:standard);
use Carp qw(carp cluck);
use Shell qw(cp mkdir);
use File::stat;
use Time::Local;
use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use RGTools::RGIO;
use SDB::DBIO;
use SDB::Report;
use SDB::CustomSettings;
use alDente::Plate;
use Sequencing::Sequence;
use alDente::Solution;
use alDente::SDB_Defaults;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($opt_h $opt_n $opt_N $opt_f $opt_m $opt_v $opt_c $opt_x);
use vars qw($opt_C $opt_P $opt_S $opt_A $opt_w $opt_s $opt_t $opt_W);
use vars qw($opt_u $opt_d $opt_D $opt_o $opt_X $opt_B $opt_T);
use vars qw($ERROR $Data_log_directory);
use vars qw(%Defaults);
use vars qw($project_dir);
our ($SS);
our ($request_dir);
our ($mirror, $adir, $sssdir, $phred_dir, $continuation);
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
&Getopts('hn:N:fm:v:c:x:C:P:S:A:w:stWu:dD:o:X:BT:');
########################
#  Global Variables 
########################
my $transfer;
if ($opt_t) {$transfer = $opt_t;}  ### send request to file_transfer request...
my $terminator;
if ($opt_T) {$terminator = $opt_T;}
my $output = "";
my $log_file = $Data_log_directory."/genss/genss_".&today;
############################
#           HELP           #
############################
if (!$opt_s) {
    Seq_Notes("Err:","Improper usage",'text',$log_file);
    print <<HELP
USAGE:
sequence.pl (options)
Options:
********
    -s     Generate Sample Sheet
    -P     Plate ID number
	OR
    -n     basename (library..plate number..quadrant eg.  CN0012c)
    -N     Project Name (Chlor, Cneo, Test ...)
    -X N  X N plates (eg.  -X 4 for 384 well plate Sequencing)
Both Requiring...
for Megabace sample sheet generation:   
        -c     Specify chemistry code;
        -m     Specify Sequencing Machine number;
for ABI sample sheet generation: 
        -u     Specify user (person generating sequence)
        -c     Specify chemistry code;
        -m     Specify Sequencing Machine number;
    (Optional)
        -v     Specify Version number (NOTE: this overrides automatic versioning)
	-C     Add comments to file (add Agarose, Primer info)
	-W     Write results to Sequencing machine (NOT possible via web)
	-o (options) specify default override options
	    eg '-o "IV=200,RTemp=50"'
######################
Note:  this can be run from the command line without requiring either Netscape or the MySQL database...
example of running bypassing MYSQL database:
 genss.pl -m D3700-3 -n CN0018a -c B7 -o "Mobility=v3" -s -a 0.0 -p T7 -N Cneoformans -u 'Duane Smailus' -C 'CN001-8A 6ul DNA 1X BDTerm T7 20ul rxn BDT1CT37 PCR EtOh/NaOAc pptn'
########################
HELP
}
######################################
#   evaluate options   #
########################
my $stop = 0;
### Mandatory ... ####
my $basename;
my @Plate_ids;
my $plate_id;
my $project;
my $chemcode;
my $Mname;
my $proj_id;
my $library; 
my $chemcode;
my $plate_num;
my $quadrant;
my $ver;
my $options;
my $dbase;
my $select_wells;
my $Xwells;
my $Blank;
my $comments;
my $blank = 0;  ## flag to indicate only make a skeleton (blank) version...
if ($opt_n) {    $basename = $opt_n;
}
elsif ($opt_P) {
    @Plate_ids = split ',', $opt_P;
    $plate_id = $Plate_ids[0];  ### if multi-plate SSname comes from 1st plate.
}
else {
    Seq_Notes("Error: ","Need Plate ID or Basename",'text',$log_file);
    $stop=1;
}
if ($opt_N) {
    $project = $opt_N;
}
if ($opt_X) {
    $Xwells = $opt_X;
}
if ($opt_B) {
    $Blank = 1;
}
if ($opt_c) {
    $chemcode = ".".$opt_c;
}
else {
    Seq_Notes("Error: ","Need chemistry code",'text',$log_file);
    $stop=1;
}
if ($opt_m) {
    $Mname = $opt_m;
}
else {
    Seq_Notes("Error: ","Need machine\n",'text',$log_file);
    $stop=1;
}
#
# Establish type of sequencer is to be used
#
my $Sequencer_Type;
my $ssext;
if ($Mname =~ /MB(\d+)/) { 
    $Sequencer_Type = 'Megabace';
    $ssext = ".psd";
} elsif ($Mname =~/^D37\d\d-(\d+)/) {
    $Sequencer_Type = 'ABI';
    $ssext = ".plt";
} else {    
    Seq_Notes("Error: ","Unrecognized Machine type ($Mname)\n",'text',$log_file);
    $stop=1;
}
if ($opt_w) {
    my $s_wells = $opt_w;
    if ($Sequencer_Type eq 'Megabace') {   ### Megabace
	foreach my $s_well (split ',',$s_wells) {
	    if ($s_well=~/([A-Z])([0-9])/) {
		$s_well= $1."0".$2;
	    }
	    $select_wells .= $s_well.",";
	}
	chop $select_wells;
    } else {                                ### ABI
	foreach my $s_well (split ',',$s_wells) {
	    if ($s_well=~/^([A-Z])0([0-9])$/) {
		$s_well= $1.$2;
	    }
	    $select_wells .= $s_well.",";
	}
	chop $select_wells;
    }
}
if ((defined $opt_v) && $opt_v) {    ### if > 0... 
    $ver = ".".$opt_v;
}
elsif (defined $opt_v) {$ver = "";}  ### for version 0...
#else {$ver = "";}
if ($opt_C) {
    $comments = $opt_C;
}
$dbase = $Defaults{DATABASE};
if ($opt_D) {
    $dbase = $opt_D;                          ### well separated from basename ?
}
### Abort if information not complete ###
if ($stop) { print "Aborted.\n"; &leave(); }
if ($opt_o) {
    $options = $opt_o;                          ### well separated from basename ?
}
print "<B>Options</B>:<BR>*************<BR>$options";
########################################
#   get info from MySQL database...
########################################
########################################################
#   specifications for specific sample:
##############################################
# Machine Dependant options...
#
# set sample sheet extension to .psd (if MB\d) or .plt
#
################################
#     local variables
################################
############################################
#        Global variables
###########################################
my $equipment_id;
my $path;
my $dbc = DB_Connect(dbase=>$dbase);
($equipment_id) =  &Table_find($dbc,'Equipment,Machine_Default,Sequencer_Type','Equipment_ID',"where FK_Sequencer_Type__ID = Sequencer_Type_ID and Equipment_ID = FK_Equipment__ID and Equipment_Name like '%$Mname%'");
####### Get Machine Specific Defaults.. #############
my %Info = &Table_retrieve($dbc,'Machine_Default,Equipment',['Run_Module','An_Module','Host','Sharename','NT_Samplesheet_dir'],"where FK_Equipment__ID = Equipment_ID AND FK_Equipment__ID = $equipment_id");

my $Run_Module = %Info->{Run_Module}[0];
my $An_Module = %Info->{An_Module}[0];
my $NThost = %Info->{Host}[0];
my $NTsharename = %Info->{Sharename}[0];
my $NTssdir = %Info->{NT_Samplesheet_dir}[0];
my $cv="";
if ($options=~/Chem_Version=v?(\d+)/) {
    $cv=$1;
}
#### D3700 Options... ######
my $mv;
my $Dye_set;
my $Mob_File;
my $foilprcon=0;
if ($Sequencer_Type eq 'Megabace') {} ## no chemistry specs for Megabaces.. 
else {                                 ## ABI ###
    unless ($cv) {Message("Error no chemistry version specified."); &leave(); }
    my $dye_term = $terminator;
    unless ($dye_term) {Message("Error no terminator specified."); &leave(); }
    if ($dye_term eq 'Water') {$dye_term = 'Big Dye';} ### use standard big dye files
    my %Chemistry = &Table_retrieve($dbc,'Dye_Chemistry',['Mobility_Version','Dye_Set','Mob_File'],
				    "where Terminator like '$dye_term' and Chemistry_Version like '$cv'");
    $mv = %Chemistry->{Mobility_Version}[0];
    $Dye_set = %Chemistry->{Dye_Set}[0];
    $Mob_File = %Chemistry->{Mob_File}[0];
    $comments .= "CV=$cv.MV=$mv.";
}
##### correct for Foil Piercing if necessary #####
if ($options=~/FoilPrcOn/) {
    $comments .= "FoilPrcOn."; 
    $foilprcon=1;   
    $Run_Module =~s/FoilPrcOff/FoilPrcOn/;
}
else {
    $Run_Module =~s/FoilPrcOn/FoilPrcOff/;
}   
########### MegaBace Options... ##################
my %Defaults = &Table_retrieve($dbc,'Machine_Default',['Injection_Voltage','Injection_Time','Run_Voltage','Run_Time','Run_Temp','PMT1','PMT2'],"where FK_Equipment__ID = $equipment_id");
my $ssIV = %Defaults->{Injection_Voltage}[0];        ## (3)
my $ssIT =  %Defaults->{Injection_Time}[0];       ## (10)
my $ssRV =  %Defaults->{Run_Voltage}[0];       ## (6)
my $ssRTime =  %Defaults->{Run_Time}[0];    ## (200)
my $ssRTemp =  %Defaults->{Run_Temp}[0];    ## (44)
my $ssPMT1 =  %Defaults->{PMT1}[0];     ## (750)
my $ssPMT2 =  %Defaults->{PMT2}[0];     ## (790)							   
##################################
if (!$basename) {
    (my $lib_dir) = &Table_find($dbc,'Plate natural left join Library','Library.Library_Name,Plate_Number,FK_Project__ID',"where Plate_ID=$plate_id and FK_Library__Name=Library_Name"); 
    ($library,$plate_num,$proj_id) = split ',', $lib_dir;
    (my $project_path) = Table_find($dbc,'Project','Project_Path',"where Project_ID like \"$proj_id\"");
    ($quadrant) = Table_find($dbc,'Plate','Parent_Quadrant',"where Plate_ID like \"$plate_id\"");
    $path = "$project_dir/$project_path/$library";
    $basename = $library.$plate_num . lc($quadrant); ## force to lower case 
}  
else {
    print "No Basename specified";
    &leave();
            ### remove this stuff... ###
    my $proj;
    if ($project=~/^Ch/i) {$proj="Chlorarachnion";}
    elsif ($project=~/^Cn/i) {$proj="Cneoformans";}
    elsif ($project=~/^T/i) {$proj="Diagnostics";}
    elsif ($project=~/^Hemo/i) {$proj="Hemochromatosis";}
    else {print "invalid project\n\n"; &leave();}
    $basename=~/([\w]{5})\d+\w?/;
    $path = "$project_dir/$proj/$1/";
}
my $savedir="$path/$adir";
my $ssdir = "$path/$sssdir";
my $testdir = "$project_dir/Test_files";
my $overwrite = 0;
my $nver = next_version($ssdir,"$basename$chemcode",$ssext);
if ($nver) {print "(version=$nver).\n";}
else {print "(original_version).";}
if (!(defined $ver) && ($opt_s)) {
    if ($nver) {$ver = ".".$nver;}
    else {$ver="";}
} 
elsif (defined $ver && ($ver<$nver)) {$overwrite=1;} 
my $longname=$basename.$chemcode.$ver;
my $suffixname = $chemcode.$ver;
my $outfile = "$savedir/$longname/$phred_dir/phredscores$ver";
my $storedir = "$savedir/$longname/";
##################### Copy to local machine #################################
if ($opt_s) {
####################################
#   Generate Sample Sheet file
####################################
# MegaBace Sequencers (need agarose, Primer -> psd files)
    my $fback;
    if ($plate_id && $equipment_id && $user && $chemcode) {	
	my $user;
	if ($opt_u) {$user = $opt_u;} 
	else {Seq_Notes("Err:","For now please specify user\n",'text',$log_file); die "$!\n";}
	print "Using New SampleSheet generator...<P>";
	generate_ss('Plate'=>'pla'.$plate_id,'Equipment_ID'=>$equipment_id,'User'=>$user,'User_Comment'=>$comments,'Chemistry_Version'=>$chemcode); 
    }
    elsif ($Sequencer_Type eq 'Megabace') {  ### Megabace
	generate_psd($comments);
##################### Copy to local machine #################################
    } else {                              ### ABI
	my $user;
	if ($opt_u) {$user = $opt_u;} 
	else {Seq_Notes("Err:","For now please specify user\n",'text',$log_file); die "$!\n";}
	$fback = &generate_plt($user,$comments,$Xwells);
    }
    if ($fback) {Message($fback);}
    unless ($fback=~/Error/) {
	if ($overwrite) {print "\nOverwrote_";}
	else {print "\nCreated_";}
	my $testf = '';
	if ($dbase ne 'sequence') {$testf = "Test_files/";}
	print "file=<B>$testf$longname$ssext</B>\n";
#    print "PATH=$ssdir\n";
	my $request_id;
	if ($transfer && ($dbase eq 'sequence')) {
	    $Mname=~s/-/_/g;     ### convert for generate_request ..
	    $request_id = &generate_request("$ssdir/$longname$ssext",$Mname);
	}
	Seq_Notes("Request_ID:","$request_id",'text',$log_file);
    }
    &leave();
}
############
#  feedback 
############
if ($opt_f) {
    Seq_Notes("Note:","...Done.\n\n",'text',$log_file);
}
# return $output;
&leave();

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

####################
#  Subroutines  
####################

##############################################################################

sub generate_psd {
#########################################################
#   Generate *.psd files for sequencer 
#########################################
    my $comments = shift;
#
# specify sample sheet header defaults...
#
    
    my $ssCHEM = "ET Terminators";  ## chemistry ..
    my $ssBC = "Cimarron 1.53 Slim Phredify";

    if ($terminator=~/^B/) {
	$ssCHEM = "Big Dye Chemistry";
    }

    if ($options=~/IV=(\d+)/) {$ssIV=$1;}
    if ($options=~/IT=(\d+)/) {$ssIT=$1;}
    if ($options=~/RV=(\d+)/) {$ssRV=$1;}
    if ($options=~/RTime=(\d+)/) {$ssRTime=$1;}
    if ($options=~/RTemp=(\d+)/) {$ssRTemp=$1;}
    if ($options=~/PMT1=(\d+)/) {$ssPMT1=$1;}
    if ($options=~/PMT2=(\d+)/) {$ssPMT2=$1;}
    
    my $ssCOMM = $comments;

    my $ssheader="Plate ID\t$longname\r\n";
    $ssheader.="RUN TIME\t$ssRTime\r\n";
    $ssheader.="RUN VOLTAGE\t$ssRV\r\n";
    $ssheader.="INJECTION TIME\t$ssIT\r\n";
    $ssheader.="INJECTION VOLTAGE\t$ssIV\r\n";
    $ssheader.="RUN TEMPERATURE\t$ssRTemp\r\n";
    $ssheader.="COMMENT\t$ssCOMM\r\n";
    $ssheader.="PMT2 VOLTAGE\t$ssPMT2\r\n";
    $ssheader.="PMT1 VOLTAGE\t$ssPMT1\r\n";
    $ssheader.="CHEMISTRY\t$ssCHEM\r\n";
    $ssheader.="BASE CALLER\t$ssBC\r\n";
    
### Write to file... ########

    $SS= ">"."$ssdir/$longname$ssext";

    if ($dbase ne 'sequence') {
	$SS = ">"."$testdir/$longname$ssext"; 
	Message("Test ss wrote to $SS");
    }
    open SS or die "Error Opening File: $SS.\n";       

    my $LastLetter = 'H';
    my $LastNum = 12;
    
    if ($Xwells=~/384/) {
	$LastLetter = "P";
	$LastNum = 24;
    }

    print SS $ssheader;
    my @list = ('A'..$LastLetter);
    foreach my $letter (@list) {
	for (my $i=1; $i<=$LastNum; $i++) {
	    my $num=$i;
	    if ($i<10) {$num="0".$i;}
	    my $well = $letter.$num;
	    if (!$select_wells || ($select_wells=~/$well/)) {
		print SS $well."\t".$basename.$well.$suffixname."\r\n";
	    }
	}
    }
    close SS;
    if ($opt_f) {
	print "\n\nDone Generating Sample sheet...\n\n";
    }
}

###############################
sub generate_plt {
##############################################
#   Generate *.plt files for 3700 sequencers
##############################################
    my $user = shift;
    my $comments = shift;
    my $wells = shift;

    Seq_Notes('*.plt file',"$user, $wells wells\n$comments",'text',$log_file);

    $comments=~s /\t/ /g; ## replace tabs in comments with spaces
    $comments=~s /\n/ /g; ## replace linefeeds in comments with spaces

    my $default_mv="v3";  ### correlated with ...POP5LR

    my $default_cv="v2";  ### correlated with ...POP5LR

   my $size = '96-Well';
    if ($wells=~/384/) {$size = '384-Well';}
    
    my $fback;

    if (!$Run_Module || !$An_Module ||!$Mob_File) {
	$fback = "Error: default module not found ($Run_Module,$An_Module,$Mob_File)"; 
	return $fback;
    }

#
# specify sample sheet header defaults...
#
#
# Replace: Filename, Size, User, Comments

    my $ssheader="1.0\n$longname\tSQ\t$size\t$user\t$comments\n";

    $ssheader .= "Well\tSample Name\tDye Set\tMobility File\tComment\t";
    $ssheader .= "Project Name\tSample Tracking Id\t";
    $ssheader .= "Run Module\tAnalysis Module\n";
    
### Write to file... ########

    $SS= ">"."$ssdir/$longname$plt_ext";
    
    if ($dbase ne 'sequence') {
	$SS = ">"."$testdir/$longname$ssext"; 
	Message("Test ss wrote to $SS");
    }
    open SS or die "Error Opening File: $SS.\n";       

    my $LastLetter = 'H';
    my $LastNum = 12;
    
    if ($Xwells=~/384/) {
	$LastLetter = "P";
	$LastNum = 24;
    }
    elsif ($blank) {
	$LastLetter = "A";
	$LastNum = 1;
    }

    print SS $ssheader;
    my @list = ('A'..$LastLetter);
    foreach my $letter (@list) {
	for (my $i=1; $i<=$LastNum; $i++) {
	    my $num=$i;
#	    if ($i<10) {$num="0".$i;}
	    my $well = $letter.$num;
	    if (!$select_wells || ($select_wells=~/$well/)) {
		print SS "$well\t-\t$Dye_set\t$Mob_File\t \t3700Project1\t \t$Run_Module\t$An_Module\n";
	    }
	}
    }
    if ($blank) {print SS "...384-well copy... \n";}

    close SS;
    if ($opt_f) {
	print "\n\nDone Generating Sample sheet...\n\n";
    }
    return 0;
}

sub rcopy {
#################################
#  Remote Copy 
#################################
    my $host = shift;
    my $source = shift;
    my $target = shift;

    my $syscommand = "rsh $host \"cp $source \\\"$target\\\"\"";
    if ($opt_f) {
#	print "...copying to $MbaceDir on $host";
	print $syscommand;
    }
    system($syscommand);
    return;
}

#####################
sub next_version {
#####################
    my $basedir=shift;
    my $basename=shift;
    my $ext=shift;
    
    my @files = split "\n",try_system_command("ls $basedir/$basename*");

    my $maxversion=0; my $found=0;
    foreach my $thisfilename (@files) {
#	print "\n***** $thisfilename **********\n";
	if ($thisfilename =~ /No such file/i) { return ""; }  ## no files found... 

	if ($thisfilename=~/$basename/) {
	    $found++;
	}
	if ($thisfilename=~/$basename\.(\d+)/) {
	    if ($1>$maxversion) {$maxversion=$1;}
	}
    }
    my $nextversion=$maxversion + 1;
    if ($opt_f) {
	print "next version of $basename* = $nextversion (found $found like $basename)";
    }

    if (($nextversion > 1) || $found) {return $nextversion;}
    else {return "";}
}

#############################
sub generate_request {
#############################
#
# generate request file to automatically copy to NT machines...
#
# required format:   'request.#' containig:
#  nthostname (host eg d3700-2)
#  ntsharename (eg data1)
#  ntdirname (eg AnalyzedData/SampleSheets/)
#  ntfilename (CC0011a.E7.plt)
#  networkfile (/home/sequence/Projects/Chlorarachnion/CC001/SampleSheets/)
#

    my $filename = shift;
    my $machine_name = shift;

    my $file;
    if ($filename=~/^(.*)\/([a-zA-Z_0-9\.]*)$/) {$file = $2;}

    my @requests = <$request_dir/request.*>;

    my $this_id = 0;
    my $last_id = 0;
    foreach my $thisrequest (@requests) {
	if ($thisrequest=~/request.(\d+)$/) {
	    $this_id = $1;
	    if ($this_id > $last_id) {$last_id = $this_id;}
	}
	elsif ($thisrequest=~/request.(\d+).done$/) {
	    $this_id = $1;
	    if ($this_id > $last_id) {$last_id = $this_id;}
	}
    }
    my $request_id = $last_id + 1;
   
    my $REQUEST;
    open(REQUEST,">$request_dir/request.$request_id") or print "Error opening  request file: $request_dir/request.$request_id";

    print REQUEST "nthostname $NThost\n";
    print REQUEST "ntsharename $NTsharename\n";
    print REQUEST "ntdirname $NTssdir\n";
    print REQUEST "ntfilename $file\n";
    print REQUEST "networkfile $filename\n";
#    if ($Xwells=~/384/) {print REQUEST "384-Well\n";}
    &leave();

    return $request_id;
}

sub leave {
    if ($dbc) { $dbc->disconnect(); }
    exit;
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

$Id: genss.pl,v 1.7 2004/09/29 01:36:04 rguin Exp $ (Release: $Name:  $)

=cut

