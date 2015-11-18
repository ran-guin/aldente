#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

decompress.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html

=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
#use strict;
use CGI qw(:standard);
use DBI;
use Benchmark;
use Carp;
use CGI::Carp qw(fatalsToBrowser);
use File::stat;
use Date::Calc qw(Day_of_Week);
use Storable;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
############## Local Modules ################

#use Imported::Barcode;
use SDB::DBIO;
 
use SDB::CustomSettings;
use alDente::SDB_Defaults;
use RGTools::RGIO;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($testing $dumps_dir $mirror $projects_root);
use vars qw($opt_L $opt_d $opt_D $opt_t $opt_W $opt_w $opt_f $opt_c); 
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
&Getopts('L:d:D:t:w:W:fc');
my $date = $opt_d || '';
my $database = $opt_D || 'sequence';
my $find = $opt_f || 0;  ## force decompression of ALL Library files...
my $check = $opt_c || 0;  ## just check for compressed files to ensure numbers are ok..
my @unzipped = ();
my $username = `whoami`;
chomp $username;
unless ($username eq 'sequence') {
    print "\n$username does not have permission to run update command.";
    print "\nPlease 'su sequence' and try again.\n\n";
    exit;
}
my $lib = $opt_L || '';
########### General variables ... ##############


my $Connection;
if (!$lib ) {
    print <<HELP
decompress.pl -L (Library_Name) [-d (date)
*********************************************
This script will decompress chromat files.
-L (library): The library to decompress 
               (It may be suffixed with the plate and quadrant number to decompress specific Runs).
    eg.  -L CC002     ... or -L CC0023 ... or -L CC0023a
-d (date): This is used to speed up the decompression by looking for runs completed on a specific date.
(this date appears in the ab1 file names for 3700 Sequence Run chromat files)
    eg.  -d 2001-06-06
(This command must be run as sequence)
*********** NOTE for 384-well format Sequencing ***********  
Do NOT specify the Quadrant for 384-well sequenced plates
(since all quadrants are saved under the same filename) 
... AND if a variety of plates are run on one 384-well plate, use only the library/plate specification for the 1st plate (in quadrant 'a' position)... 
OR to uncompress Dumped backups...
*************************************
decompress.pl (options)
Options:
__________
-D (database)
-d (date) - (YYYY-MM-DD format)
-t (time) - (HH:MM format - optional) - defaults to 18:50 (last daily backup)
-w (well) - specify a well to check (in case well A01 is ok, but others require decompressing)...
          -  (you only need to find a single well that is compressed, (to allow the compressed file to be found), and all of the wells will be decompressed.
eg.  decompress.pl -D sequence -d 2001-09-01 -t 16:00
NOTE:  To turn off regular compression of mirrored files: 
        remove '-m' switch from 'cleanup.pl' in the cron job run on SQL server by sequence.
HELP
}
elsif ($lib) {
    my @pressed = (); ######## Array of directories to compress...
    my @datafiles = ();
    my $lib_path;
    if (length($lib) > 5) {$lib_path = substr($lib,0,5);}
    elsif (length($lib) < 5) {$lib_path = "$lib*";}
    else {$lib_path = $lib;}
    $dbc = SDB::DBIO->new(-dbase=>$database,-user=>'viewer',-password=>'viewer');
    $dbc->connect();
    my $lib_like = substr($lib,0,5);
    my $proj = join ',', &Table_find($dbc,'Library,Project','Project_Path',"where FK_Project__ID=Project_ID AND Library_Name like '$lib_like%'",'Distinct');
    $dbc->disconnect();
    if ($proj=~/,/) {
	print "Library spec is too general (more than one applicable projects)\n";
	print "Please use a bit more specific library name (may require running more than once)\n";
	$proj =~s/,/\n/g;
	print "Found valid Projects: \n$proj";
	exit;
    }
    elsif ($proj=~/NULL/) {print "Project not found..? for lib: $lib.\n"; exit;}
    my @dates;
    my $runs = {};
    if ($date) {@dates = ($date);}
    elsif ($find) {
	my $well = $opt_w || $opt_W || "A01";  ### search only for these wells (quicker)
	print "This may take a bit of time... \n";
	print "especially for 3700 files which do not have the library name in the directory name\n\n...";
	my $command = "find $projects_root/$proj/$lib_path/AnalyzedData/$lib*/chromat_dir/*$well* -xtype l";
	print "Looking for broken links to this library...\n";
	print "\n$command\n";
	my @list = split "\n",try_system_command($command);
	$command =~s/A01\*/A04\*/;    ### for separate folders of 384 well plates...
	push(@list,split "\n",try_system_command($command));
	$command =~s/A04\*/A07\*/;    ### for separate folders of 384 well plates...
	push(@list,split "\n",try_system_command($command));
	$command =~s/A07\*/A10\*/;    ### for separate folders of 384 well plates...
	push(@list,split "\n",try_system_command($command));
	foreach my $file (@list) {
	    unless ($file) {next;}
	    my $command = "ls -ll $file | cut -d '>' -f 2";
	    my $linktofile = try_system_command($command);
	    chomp $linktofile;
	    if ($linktofile=~/Run_[D]?3700-(\d)(.*?)\//i) {
		my $thisdate = $1.$2;
		unless (grep /^$thisdate$/, @dates) {push(@dates,$1.$2);}
		$runs->{$1} ||= 0;
		$runs->{$1}++;
		print "found $file -> $linktofile\n";
	    }
	}
    }
    if (@dates) {
	print "Found Dates for 3700 files:\n***************************\n";
	print join "\n", @dates;
	print "\n\nBy Sequencer:\n*********************\n";
	print "3700-1:" . $runs->{1}."\n"; 
	print "3700-2:" . $runs->{2}."\n"; 
	print "3700-3:" . $runs->{3}."\n"; 
	print "3700-4:" . $runs->{4}."\n"; 
	print "3700-5:" . $runs->{5}."\n"; 
    }
    elsif ($find) {
	print "No broken links (only used in 3700 files)\n";
	print "********************* NOTE ***************************\n";
	print "\nIf well A01 is missing or is uncompressed, but other files from the same run are compressed, you may need to specify a well\n\n";
	print "\nIf files still seem to be compressed, check the wells by typing:\n";
	print "\nls $projects_root/*/*/AnalyzedData/$lib_path*/chromat_dir/*\n\n";
	print "If you notice a broken link, specify that well with the switch -w...\n";
	print "(eg. if the file for Well A05 is compressed in the TL0671a run, try:\n";
	print ">decompress.pl -L TL0671a -w A05\n\n";
	print "(you only need to find the well for one compressed file for each run.  The files for ALL of the wells will then be decompressed.)\n\n";
	print "****************** NOTE for 384 Well Files ***********************\n";
	print "\nDue to the funky nature in which 3700 plates are broken up, 384 well files are all stored with the filename of the plate in the 1st 96 well quadrant.  (normally the 'a' quadrant)... use this label to decompress\n\n";
	print "\nie. to decompress TL0671c files, you should NOT specify the quadrant - just use -L TL0671 (since all 384 well files have the same name - and are NOT named by quadrant individually)\n";
	### summary... ####
	print "\n\nBy Sequencer:\n*********************\n";
	print "3700-1:" . $runs->{1}."\n"; 
	print "3700-2:" . $runs->{2}."\n"; 
	print "3700-3:" . $runs->{3}."\n"; 
	print "3700-4:" . $runs->{4}."\n"; 
	print "3700-5:" . $runs->{5}."\n"; 
#    foreach my $thisdate (@dates) {
#	push(@pressed, glob("/home/sequence/mirror/3700/*/data1/Data/Run*$thisdate*gz"));  ### 3700 files (diff format)
#
# Note: revised 3700 directory format to simplify searching for tarred files...
#
    } else {
	#### if whole subdirectory given, check for master file... 
	if ($lib=~/.{5}\d+[a-d]*\.[a-zA-Z]/) {	    
	    print "Check $lib for master file.\n";
	    ## if part of multiplate run get master file... ##    
#	    my $dbc = DB_Connect(dbase=>$database);
	    $dbc = SDB::DBIO->new(-dbase=>$database,-user=>'viewer',-password=>'viewer');

	    my ($master) = &Table_find($dbc,'Run,MultiPlate_Run','FKMaster_Run__ID',"where FK_Run__ID = Run_ID AND Run_Directory like '$lib' and FK_Run__ID != FKMaster_Run__ID");
	    print "Master: $master\n";
	    if ($master=~/\d/) {
		($lib) =  &Table_find($dbc,'Run','Run_Directory',"where Run_ID = $master");
		print "Master Name: $lib\n";
	    }
	    $dbc->disconnect();
	    ### 3700 files (diff format)   
	    push(@pressed, glob("$mirror/3700/*/data1/Data/$lib"."Run*gz")); 
	    ### mbace files 
	    push(@pressed, glob("$mirror/mbace/*/data2/Data/$lib"."Run*gz"));          
	    ### mbace files     
	    push(@pressed, glob("$mirror/mbace/*/data2/AnalyzedData/$lib"."Run*gz")); 
	}
	else { ### allow anything from Library.. ### 
	    ### 3700 files (diff format)   
	    push(@pressed, glob("$mirror/3700/*/data1/Data/$lib*gz")); 
	    ### mbace files 
	    push(@pressed, glob("$mirror/mbace/*/data2/Data/$lib*gz"));          
	    ### mbace files     
	    push(@pressed, glob("$mirror/mbace/*/data2/AnalyzedData/$lib*gz")); 
	}
	if (int(@pressed)) {
	    print "Decompress:\n********************\n";
	    print join "\n", @pressed .
		"\n*************************\n";
	    print &decompress_directories(\@pressed,$check);         
	} else { print "Nothing Like:  '$lib' zipped up\n(check for $mirror/<model>/*/data1/Data/$lib"."Run*gz)\n"; }
#    }
    }
}
elsif ($database) {
    unless ($date=~/\d\d\d\d-\d\d-\d\d/) {
	print "You MUST specify a date to unzip a Dump directory\n";
	exit;
    }
    my $time = $opt_t || '18:50';  ### get last backup of day by default...
    $time=~s/:/_/g;
    my @dir = ("$dumps_dir/$database.$date/$database.$date.$time.tar.gz");
    &decompress_directories(\@dir,$check);
}
print "Done..\n";
exit;

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

#################################
sub decompress_directories {
#################################
    my $list = shift;
    my $check = shift;  ### just count directories to ensure existence...

    my @directories = @$list;

    chdir "/";
    foreach my $dir (@directories) {
	my $newdir;
	my $path;
	if ($dir=~/(.*)\/(.+)\.tar\.gz$/) {
	    $path = $1;
	    $newdir = $2;
	}	
	elsif ($dir=~/(.*)\/(.+)\.tgz$/) {
	    $path = $1;
	    $newdir = $2;
	}
	else {next;}

	if ($dir =~ /(.*)\/(\S+?)[_]*(Run.*)\.t/) {
	    my $subdir = $2;
	    my $rundir = $3;
	    my $count = try_system_command("ls $path/$rundir/ | wc");
	    chomp $count;
	    if ($count=~/\s*(\d+)/) {
		my $found = $1;
		if ($found >= 96) { 
		    print "$subdir -> $count..(open)\n";
		    next; 
		}  ## skip if already found
	    }
	    print "$subdir -> $count..(open)\n";
	}

	if ($check) {
	    if (-e "$dir.files") {
		print "$dir found: ".
		    &try_system_command("cat $dir.files | wc");
		next;
	    }  
	    print "$dir found: ".
		&try_system_command("tar tzvf $dir *$lib* | wc");
	    next;
	}
	else {
	    print "*** tar zxvf $dir *$lib*\n";
	    `cd /`;
	    if (grep /^$dir\:$lib$/, @unzipped) {
		print "already decompressed $dir $lib*\n";
		next;
	    } else {
		print "** UNZIP $dir : $lib **\n";
		push(@unzipped,"$dir:$lib");
	    }
	    my $retrieved = &try_system_command("tar xzvf $dir *$lib*");
	    if ($retrieved =~/(\S+)\/(Run.*?)(\d+)\/(.*?)_/) {
		my $path = $1;
		my $run_directory = $2;
		my $run_number = $3;
		my $link = $4;
		my $count = int(split "\n", $retrieved);
		print "retrieved $number_retrieved files";
		try_system_command("ln -s /$path/$run_directory$run_number /$path/$link.chromat.rid$run_number.$count");
	    }
	    `cd -`;
	}
    }
    return 1;
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

$Id: decompress.pl,v 1.11 2004/09/21 17:54:57 rguin Exp $ (Release: $Name:  $)

=cut

