#!/usr/local/bin/perl

################################################################################
# genss.pl
#
# This program generates Sample Sheets for Sequencing Runs (and updates database)
# 
################################################################################

################################################################################
# $Id: genss.pl,v 1.2 2002/11/06 21:50:16 achan Exp $
################################################################################
# CVS Revision: $Revision: 1.2 $
#     CVS Date: $Date: 2002/11/06 21:50:16 $
################################################################################

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();

use CGI qw(:standard);
use Carp qw(carp cluck);

use lib "/home/martink/export/prod/modules/gscweb";
use gscweb;
#use local::gscweb;

use Shell qw(cp mkdir);
use File::stat;
use Time::Local;

our ($SS);
our (%Mdir);
our ($NTsharename, $NThost, $NTssdir, $request_dir);
our ($dbc,$trace_file_ext1,$trace_file_ext2,$psd_ext);
our ($plt_ext, $mirror, $project_dir, $adir, $sssdir, $phred_dir, $continuation);

use strict;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

 
use SDB::RGIO;
use SDB::Plate;
use SDB::SDB_Defaults;
use SDB::Run;
use SDB::Solutions;
use SDB::Table;
use SDB::Report;

use vars qw($opt_h $opt_n $opt_N $opt_f $opt_m $opt_v $opt_c $opt_x);
use vars qw($opt_C $opt_P $opt_S $opt_A $opt_w $opt_s $opt_t $opt_W);
use vars qw($opt_u $opt_d $opt_D $opt_o $opt_t $opt_X $opt_B $opt_T);
use vars qw($ERROR $log_directory $project_dir);
use vars qw($RunModule $AnModule $MobFile);

require "getopts.pl";

&Getopts('hn:N:fm:v:c:x:C:P:S:A:w:stWu:dD:o:X:BT:');

########################
#  Global Variables 
########################

my $transfer;
if ($opt_t) {$transfer = $opt_t;}
my $terminator;
if ($opt_T) {$terminator = $opt_T;}

my $output = "";

my $log_file = $log_directory."/genss/genss_".&today;
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
 
for MB1 sample sheet generation:   

        -c     Specify chemistry code;
        -m     Specify Sequencing Machine number;
 
for D3700 sample sheet generation: 

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
my $trace_file_ext;
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
    Seq_Notes("Error: ","Need machine number\n",'text',$log_file);
    $stop=1;
}

### optional switches ###

if ($opt_w) {
    my $s_wells = $opt_w;
    if ($Mname=~/^MB/) {
	foreach my $s_well (split ',',$s_wells) {
	    if ($s_well=~/([A-Z])([0-9])/) {
		$s_well= $1."0".$2;
	    }
	    $select_wells .= $s_well.",";
	}
	chop $select_wells;
    }
    else { 
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

########### Get database from configuration file ######################
my $default_dbase = "sequence";
my $CONFIG;
open(CONFIG,"/home/sequence/intranet/config") or Message("Error","can't open");
while (<CONFIG>) {
    if (/^database:(\w+)/) {$default_dbase=$1;}
}
close(CONFIG);

$dbase = $default_dbase;

if ($opt_D) {
    $dbase = $opt_D;                          ### well separated from basename ?
}

if ($stop) {die "$!\n";}

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
    
my $Mnum;    
my $ssext;
my $template;
my $E_drive;

if ($Mname =~ /MB/) {$trace_file_ext||=$trace_file_ext1; $ssext = $psd_ext;}
else { $trace_file_ext||=$trace_file_ext2; $ssext = $plt_ext;}

if ($Mname =~ /MB(\d+)/) {$Mnum=$1;}
elsif ($Mname =~ /3700-(\d+)/) {$Mnum=$1; $template=$1;}

else {Seq_Notes("Err:","Invalid Machine name entered",'text',$log_file); die "$!\n";}

my $MbaceDir = $mirror."/mbace/$Mnum/system/Program Files/Molecular Dynamics/MegaBACE/Psd/";
$E_drive=$mirror."/mbace/$Mnum/data2";

if ($stop) {exit;}

################################
#     local variables
################################

############################################
#        Global variables
###########################################

my $path;
if (!$basename) {
    $dbc = DB_Connect(dbase=>$dbase);
   
    (my $lib_dir) = &Table_find($dbc,'Plate natural left join Library','Library.Library_Name,Plate_Number,FK_Project__ID',"where Plate_ID=$plate_id and FK_Library__Name=Library_Name"); 
    ($library,$plate_num,$proj_id) = split ',',$lib_dir;
    
    (my $project_path) = Table_find($dbc,'Project','Project_Path',"where Project_ID like \"$proj_id\"");

    ($quadrant) = Table_find($dbc,'Plate','Parent_Quadrant',"where Plate_ID like \"$plate_id\"");

    $dbc->disconnect();

    $path = "$project_dir/$project_path/$library";
    $basename = $library.$plate_num.lc($quadrant); ## force to lower case 
}  
else {
    my $proj;
    if ($project=~/^Ch/i) {$proj="Chlorarachnion";}
    elsif ($project=~/^Cn/i) {$proj="Cneoformans";}
    elsif ($project=~/^T/i) {$proj="Diagnostics";}
    elsif ($project=~/^Hemo/i) {$proj="Hemochromatosis";}
    else {print "invalid project\n\n"; exit;}
 
    $basename=~/([\w]{5})\d+\w?/;
    $path = "$project_dir/$proj/$1/";
}

my $savedir="$path/$adir";
my $ssdir = "$path/$sssdir";

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
    if ($Mname=~/MB(\d+)/i) {
	if ($opt_C) {$comments = $opt_C;}	
	generate_psd($comments);
##################### Copy to local machine #################################
    }

# for D-3700 sequencers... (need user -> plt files)
#
#
    else {
	my $user;
	if ($opt_u) {$user = $opt_u;} 
	else {Seq_Notes("Err:","For now please specify user\n",'text',$log_file); die "$!\n";}
	if ($opt_C) {$comments = $opt_C;}
	else {$comments="";}
	
	$fback = &generate_plt($user,$comments,$template,$Xwells);
    }

    if ($fback) {Message($fback);}

    if ($overwrite) {print "\nOverwrote_";}
    else {print "\nCreated_";}
    print "file=<B>$longname$ssext</B>\n";
#    print "PATH=$ssdir\n";

    my $request_id;
    if ($transfer && ($dbase eq 'sequence')) {
	$Mname=~s/-/_/g;     ### convert for generate_request ..
	$request_id = &generate_request("$ssdir/$longname$ssext",$Mname);
    }
    Seq_Notes("Request_ID:","$request_id",'text',$log_file);
exit;
}

############
#  feedback 
############
if ($opt_f) {
    Seq_Notes("Note:","...Done.\n\n",'text',$log_file);
}

# return $output;
exit;

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
    my $ssIV = 3;                ## Injection Voltage
    my $ssIT = 10;               ## Injection Time
    my $ssRV = 6;                ## Run Voltage
    my $ssRTime = 200;           ## Run Time
    my $ssCHEM = "ET Terminators";  ## chemistry ..
    my $ssRTemp = 44;               ## Run Temperature
    my $ssPMT1 = 750;               ## PMT1 
    my $ssPMT2 = 790;               ## PMT2 
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

    $SS= ">"."$ssdir/$longname$psd_ext";
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
    my $template_num = shift;  ## machine number 
    my $wells = shift;

    Seq_Notes('*.plt file',"$user, (template $template_num), $wells wells\n$comments",'text',$log_file);

    $comments=~s /\t/ /g; ## replace tabs in comments with spaces
    $comments=~s /\n/ /g; ## replace linefeeds in comments with spaces

    my $default_mv="v3";  ### correlated with ...POP5LR
    my $mv="v3";

    my $default_cv="v2";  ### correlated with ...POP5LR
    my $cv="";
    my $foilprcon=0;
    if ($options=~/FoilPrcOn/) {$comments .= "FoilPrcOn."; $foilprcon=1;}
    if ($options=~/Mobility=v?(\d+)/) {
	$comments .= "MV=$1."; 
	$mv="v$1";
    }

    if ($options=~/Chem_Version=v?(\d+)/) {
	$comments .= "CV=$1."; 
	$cv=$1;
    }

    my $size = '96-Well';
    if ($wells=~/384/) {$size = '384-Well';}

    my $Dye_set = 'E';           ##### default dye set (changes to D for chem_ver 3

    my $template = "D3700_".$template_num;

    my $fback;
    my $RM = $RunModule->{$template};
    my $AM = $AnModule->{$template};
    my $MF = $MobFile->{$template};
    if (!$RM || !$AM ||!$MF) {
	$fback = "default module not found"; 
	return $fback;
    }

    ########### adjust mobility version info ################
    if ($cv==3) {
	$mv = "v1"; ### force mobility to version 1
	$Dye_set = 'D';     ###### change dye set to D... ##########
	$comments=~s/MV=\d/MV=1/;  
    }   
    if ($cv==2) {
	$mv = "v3"; ### force mobility to version 2
	$Dye_set = 'E';     ###### force dye set to D... ##########
	$comments=~s/MV=\d/MV=3/;
    }
    if ($terminator=~/^E/) {
	$mv = "";
	$Dye_set = 'F';
    }
    
    # upgraded the software on the 3700s to data collection 1.1.1,
    # so we replaced POP5opt with POP5LR
    # - kteague
    
    ########## adjust mobility file version...
    if ($mv ne $default_mv) {
	$MF =~s/$default_mv/$mv/;
    }
    if ($mv=~/2/) {
	$AM=~s/POP5opt/POP5LR/;
	$MF=~s/v\d\.mob/v2\.mob/;
    }   
    elsif ($mv=~/3/) {
	$AM=~s/POP5LR/POP5LR/;
	$MF=~s/v\d\.mob/v3\.mob/;
    }   
    elsif ($mv=~/1/) {
	$AM=~s/POP5LR/POP5LR/;
	$MF=~s/v\d\.mob/v1\.mob/;
    }   
    elsif (!$mv) {
	$AM=~s/POP5LR/POP5LR/;
	$MF=~s/v\d\.mob/\.mob/;
    }   
  
    ########### adjust chemistry version info ################
 
    if ($Mname=~/^MB/) {
	$MF=~s/BD/ET/;
    }
    if ($cv==2) {
	$MF=~s/POP5\{BDv3\}/POP5\{BD\}/;
    }   
    elsif ($cv==3) {
	$MF=~s/POP5\{BD\}/POP5\{BDv3\}/;
    }   

## use '...POP5LR with mobility version 2

    if ($foilprcon) {$RM =~s/FoilPrcOff/FoilPrcOn/;}
    else {$RM =~s/FoilPrcOn/FoilPrcOff/;}    

#
# specify sample sheet header defaults...
#
#

#
# Replace: Filename, Size, User, Comments

    my $ssheader="1.0\n$longname\tSQ\t$size\t$user\t$comments\n";

    $ssheader .= "Well\tSample Name\tDye Set\tMobility File\tComment\t";
    $ssheader .= "Project Name\tSample Tracking Id\t";
    $ssheader .= "Run Module\tAnalysis Module\n";
    
### Write to file... ########

    $SS= ">"."$ssdir/$longname$plt_ext";
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
		print SS "$well\t-\t$Dye_set\t$MF\t \t3700Project1\t \t$RM\t$AM\n";
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
	print "...copying to $MbaceDir on $host";
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
	if ($thisfilename=~/$basename$ext/) {
	    $found++;
	}
	if ($thisfilename=~/$basename\.(\d+)$ext/) {
	    if ($1>$maxversion) {$maxversion=$1;}
	}
    }
    my $nextversion=$maxversion + 1;
    if ($opt_f) {
	print "next version of $basename* = $nextversion (found $found like $basename$ext)";
    }
    if ($nextversion>1 || $found) {return $nextversion;}
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
    open(REQUEST,">$request_dir/request.$request_id") or print "Error opening $REQUEST";

    print REQUEST "nthostname $NThost->{$machine_name}\n";
    print REQUEST "ntsharename $NTsharename->{$machine_name}\n";
    print REQUEST "ntdirname $NTssdir->{$machine_name}\n";
    print REQUEST "ntfilename $file\n";
    print REQUEST "networkfile $filename\n";
#    if ($Xwells=~/384/) {print REQUEST "384-Well\n";}
    exit;

    return $request_id;
}
