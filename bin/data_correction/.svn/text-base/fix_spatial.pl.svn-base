#!/usr/local/bin/perl

use strict;
use DBI;
use Data::Dumper;
use Getopt::Std;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Core/";
use lib $FindBin::RealBin . "/../lib/perl/Imported/";

use RGTools::RGIO;
 
use SDB::DBIO;
use SDB::Transaction;

use vars qw($testing);
use vars qw($opt_t $opt_q $opt_p $opt_l $opt_s $opt_w $opt_L $opt_n $opt_a $opt_v);
getopts('t:qp:l:s:w:L:n:av');

print "***********\n Connect to Database \n**************\n";

my $path = "/home/sequence/archive/3730/6/data1/Data";
my $pass = 'aldente';
my $dbc = SDB::DBIO->new(-dbase=>'sequence',-host=>'lims01',-user=>'lims_tester',-password=>$pass);
$dbc->connect();

my @runs_96 = &Table_find($dbc,'Run,RunBatch,Plate,Plate_Format','Run_ID,Run_Directory',
			  "WHERE FK_RunBatch__ID=RunBatch_ID AND FK_Plate__ID=Plate_ID AND FK_Equipment__ID = 325 AND FK_Plate_Format__ID=Plate_Format_ID AND Run_ID<29407 AND Plate_Format_Size like '96%'");

my @runs_384 = &Table_find($dbc,'Run,RunBatch,Plate,Plate_Format','Run_ID,Run_Directory',
			  "WHERE FK_RunBatch__ID=RunBatch_ID AND FK_Plate__ID=Plate_ID AND FK_Equipment__ID = 325 AND FK_Plate_Format__ID=Plate_Format_ID AND Run_ID<29407 AND Plate_Format_Size like '384%'");

## rename 96 well runs ##

my @reanalyze = ();
my $runs = 0;
my $renamed_96 = 0;
foreach my $info (@runs_96) {
    my ($id,$run) = split ',', $info;
#    if ($runs >= 4) { next; }
    $renamed_96 += check_run($run,96,$runs,$id);
    $runs++;
}
print "** Completed $runs 96 well run fixes **\n";

my $run = "<runname>";
my $renamed = 0;

## same thing for 384 well runs ##
$runs = 0;
my $renamed_384 = 0;
foreach my $info (@runs_384) {
    my ($id,$run) = split ',', $info;
#    if ($runs >= 4) { next; }
    $renamed_384 += check_run($run,384,$runs,$id);
    $runs++;
}

print "** Completed $runs 384 well run checks/fixes **\n";
print "*********************************************************************\n";
print "** Completed: Changed $renamed_96 96-well run files; $renamed_384 384-well run files **\n";
print "********************************************************************\n";
$renamed = 0;

print "Runs to reanalyze:\n";
print join ',', @reanalyze;

exit;

############
# Some after the fact checks that may need to be run... 
#
#
############
sub check_run {
#############
    my $run = shift;
    my $size = shift;
    my $runs = shift;      ## runs so far shown...
    my $id   = shift;

    my $cmd = '';
    
    my $ok = 0;
    if (-e "$path/$run.prefix") { 
#	print "** $run remapped **\n";

	my ($master) = &Table_find($dbc,'MultiPlate_Run,Run','FKMaster_Run__ID',"WHERE Run_Directory like '$run' AND FK_Run__ID=Run_ID");    
	if ($master =~ /[1-9]/) {
	    if ($master == $id) {
#		print "Master = $id..";
		$size = 384; ## indicate larger size of sequenced plate.
	    }   
	    else {
#		print "(already remapped master run)\n"; 
		return 0;
	    }
	}
	
	my $count = `ls $path/$run.rid*/*.ab1 | wc`;
	if ($count=~/(\d+)/) { $count = $1 }
#	print "Found $count.\n";
	if ($count =~/^(96|192|288|384)$/) { $ok++ }
	else { 
	    print "$run contains $count ab1 files ($size ??!!) - check\n"; 
	    my $fix = fix_duplicate($run,$size,$id); 
	    print "** $run ** $count *.ab1 files found - Fixed $fix.\n";
	    print "****** NEW COUNT = " . int($count - $fix) . " ******\n";
	}
    } else {
	print "*****************************\n";
	print "** $run NOT remapped ? **\n";
	print "*****************************\n";
    }
    return;
}

################
sub fix_duplicate {
################
    my $run = shift;
    my $size = shift;
    my $id  = shift;

    my @rows = (1,2);
    my @cols = ('C'..'H');
    if ($size =~/384/) { @rows = (1,2,3,4); @cols = ('E'..'P'); }
    
    my $remove = 0;
    foreach my $row (@rows) {
	if ($row < 10) { $row = '0'.$row }
	foreach my $col (@cols) {
	    my $well = $col . $row;
	    my @new = split "\n", `ls $path/$run.rid*/*_$well*.ab1`;
	    my $old = `ls $path/$run.prefix/*_$well*.ab1`;
	    if ($old =~/(.*)\/(.+)/) { $old = $2; }
	    if (int(@new) < 2) {  
		## only remove if there is at least one new file.. 
		#print "$well NOT duplicated\n"; 
		next; 
	    }          
	    foreach my $newfile (@new) {
		if ($newfile =~/(.*)\/(.+)/) { $newfile = $2; }
		if ($newfile eq $old) { 
		    #print "** REMOVE $newfile\n==$old\n"; 
#		    `rm -f $path/$run.rid*/$newfile`;
#		    print "rm -f $path/$newfile\n";
		    $remove++;
		    push(@reanalyze,$id) unless grep /^$id$/, @reanalyze;
		}
	    }
	}
    }
    return $remove;
}

###########
sub fix_run {
###########
    my $run = shift;
    my $size = shift;
    my $runs = shift;      ## runs so far shown...

    my $cmd = '';

#    if (-e "$run.prefix") { 
#	print "** $run already remapped **\n";
#	return 0;
#    } else {
	print "*****************************\n";
	print "** $run **\n";
	print "*****************************\n";
#    }
    
    $cmd = "mkdir $run.prefix";    
    #`$cmd`; 
#    print "$cmd\n" unless $runs;
    $cmd = "cp -p $run.rid*/*.ab1 $run.prefix/";
    #`$cmd`;  
#    print "$cmd\n" unless $runs;
    $cmd = "cp spatial_README $run.prefix/README";
    #`$cmd`;  
#    print "$cmd\n" unless $runs;
 
    if (-e "$run.prefix") { 
	my $found = `ls $run.prefix | wc`;
	if ($found >= 96) { 	
	    print "** (saved old files to prefix directory) **\n";
	} else {    
	    my ($master) = &Table_find($dbc,'MultiPlate_Run,Run','FK_Run__ID',"WHERE Run_Directory like '$run' AND FK_Run__ID=Run_ID AND FKMaster_Run__ID <> FK_Run__ID");
	    
	    if ($master =~ /[1-9]/) { print "(already remapped master run)\n"; return 0;}
	    print "** M=$master. - (insufficient files found in prefix directory ($found) - aborting) **\n";
	    return 0;
	}
    } else {
	print " (No prefix directory found ($run.prefix)?) - aborting \n";
	return 0;
    }
 
    $renamed = 0;
    if ($size =~/96/) {
	my @row = ('A'..'H');
	$cmd = "rename $run" . "_H01 $run" . "_XXX $path/$run.rid*/*.*";
	#`$cmd`;  
	print "$cmd\n" unless $runs && !$opt_v;
	$renamed += 1;
	for my $index (0..4) {
	    # print "I=$index\n";
	    $cmd = "rename $run" . "_$row[7-$index]02 $run" . "_$row[7-$index]01 $path/$run.rid*/*.*";
	    #`$cmd`;  
	    print "$cmd\n" unless $runs && !$opt_v;
	    $cmd = "rename $run" . "_$row[7-$index-1]01  $run" . "_$row[7-$index]02 $path/$run.rid*/*.*";
	    #`$cmd`;  
	    print "$cmd\n" unless $runs && !$opt_v;
	    $renamed += 2;
	}
	$cmd = "rename $run" . "_XXX $run" . "_C01 $path/$run.rid*/*.*";
	#`$cmd`;  
	print "$cmd\n" unless $runs && !$opt_v;

	print "** (Renamed $renamed 96 well files / run) **\n";

    }
###### Do the same for the 384-well runs ... ######
    elsif ($size =~ /384/) {	
	my @row = ('A'..'P');
	$cmd = "rename $run" . "_P01 $run" . "_XXa $path/$run.rid*/*.*";
	#`$cmd`;  
	print "$cmd\n" unless $runs && !$opt_v;
	$cmd = "rename $run" . "_P02 $run" . "_XXb $path/$run.rid*/*.*";
	#`$cmd`;  
	print "$cmd\n" unless $runs && !$opt_v;
	$cmd = "rename $run" . "_O01 $run" . "_XXc $path/$run.rid*/*.*";
	#`$cmd`;  
	print "$cmd\n" unless $runs && !$opt_v;
	$cmd = "rename $run" . "_O02 $run" . "_XXd $path/$run.rid*/*.*";
	#`$cmd`;  
	print "$cmd\n" unless $runs && !$opt_v;
	
	$renamed += 4;
	
	for my $index (0..9) {
	    #print "I=$index\n";
	    #print "$path/$run.rid*/*.*\n" unless $runs && !$opt_v;
	    $cmd = "rename $run" . "_$row[15-$index]03   $run" . "_$row[15-$index]01 $path/$run.rid*/*.*";
	    #`$cmd`;  
	    print "$cmd\n" unless $runs && !$opt_v;
	    $cmd = "rename $run" . "_$row[15-$index]04   $run" . "_$row[15-$index]02 $path/$run.rid*/*.*";
	    #`$cmd`;  
	    print "$cmd\n" unless $runs && !$opt_v;
	    $cmd = "rename $run" . "_$row[15-$index-2]01   $run" . "_$row[15-$index]03 $path/$run.rid*/*.*";
	    #`$cmd`;  
	    print "$cmd\n" unless $runs && !$opt_v;
	    $cmd = "rename $run" . "_$row[15-$index-2]02   $run" . "_$row[15-$index]04 $path/$run.rid*/*.*";
	    #`$cmd`;  
	    print "$cmd\n" unless $runs && !$opt_v; 
	    $renamed += 4;
	}

	$cmd = "rename $run" . "_XXa  $run" . "_F01 $path/$run.rid*/*.*";
	#`$cmd`;  
	print "$cmd\n" unless $runs && !$opt_v;
	$cmd = "rename $run" . "_XXb  $run" . "_F02 $path/$run.rid*/*.*";
	#`$cmd`;  
	print "$cmd\n" unless $runs && !$opt_v;
	$cmd = "rename $run" . "_XXc  $run" . "_E01 $path/$run.rid*/*.*";
	#`$cmd`;  
	print "$cmd\n" unless $runs && !$opt_v;
	$cmd = "rename $run" . "_XXd  $run" . "_E02 $path/$run.rid*/*.*";
	#`$cmd`;  
	print "$cmd\n" unless $runs && !$opt_v;

	print "** (Renamed $renamed 384 well files / run) **\n";
    } else { print "** UNRECOGNIZED SIZE argument **\n"; }
    
#    print "Time: " . &date_time();
    return $renamed;
}
