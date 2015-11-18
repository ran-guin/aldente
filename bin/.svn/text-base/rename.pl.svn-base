#!/usr/local/bin/perl 
#############################################################
# analyze_standards.pl
#############################################################
use CGI qw(:standard);
use Shell qw(ls cp mv rm);

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";

use RGTools::RGIO;


use strict;

use vars qw($opt_s $opt_r $opt_d $opt_R $opt_A $opt_P $opt_S $opt_C $opt_q $opt_t $opt_f $opt_x);
use vars qw($NEWFILE $OLDFILE);

require "getopts.pl";
&Getopts('s:r:d:RAP:S:Cqtf:x');

my $search = $opt_s; 
my $replace = $opt_r;
my $directory = $opt_d;
my $confirm = $opt_C;

my $dir;
my $newdir;
my $temp;
my $file;
my $file_list;
if ($opt_f) {$file_list = $opt_f}

my $prefix = $opt_P || '';
my $suffix = $opt_S || '';
my $quote  = $opt_q || 0;
my $regexp = $opt_x || 0;
my $test   = $opt_t || 0;

if ((!$opt_d && !$opt_f) || !$opt_s || !$opt_r) {

    print <<END;

File:  rename.pl
###################

This file is used to rename a group of files 
(as well as the contents of the files if requested).

Usage:
######

rename.pl -s searchstring -r replacestring -d directory


Need to enter Directory, Search string, Replace string
(eg. rename.pl -s before -r after -d ./)

Options:
#########

For files:
*********
-P (prefix) ... prefixes all file names with specified string.
-S (suffix) ... adds a suffix to the filename BEFORE the extension.
-d Directory to search for
-f A comma-delimited list of files to search for

eg.  rename.pl -s A -r abc -P PRE -S POST

would change the file:  'A01.ext' to 'PREabcPOST.ext'

Recursive options:
*****************

-R ... recursively replaces string INSIDE the files as well.
      (In the above example it would replace all incidences of 'A' in the text to 'abc'.)
-q If specified, then the search string will be regexp-quoted.
-x If specified, then allow regexp matches to be replaced (eg may use $1..$9 as required)
    (eg -s \'%(\w+?)->{(\w+?)}\' -r \'\$\$1{\$2}\')
-t     only perform a test on the lines that will be replaced (i.e. file would not be change)

END

    exit;
}

print "Checking directory: $directory...\n";

my @files;
if ($file_list) {
    @files = split(/,/, $file_list);
}
else {
    @files = glob("$directory/*");
}
my @adirs = <$directory/*/>;
my @dirs = <$directory/*$search*/>;
print "Found ".scalar(@files)." files.\n";

my $changed = 0;
my $renamed = 0;
my $total_found = 0;
foreach $file (@files) {
    if ($confirm) {
        print "F: $file ?";
        my $continue = Prompt_Input(-type=>'char');
        if ($continue !~/y/i) { print "Aborting...\n\n"; exit; }
    }
    
    my $newfile=$file;
    if ($newfile=~/$directory\/(.*)$/) {
	my $fname = $1;
	my $basename;
	my $ext;
	if ($fname=~/^(\w*)([.][a-zA-Z]{3})$/) {
	    $basename=$1; $ext=$2;
	    $fname = $basename.$suffix.$ext;
	}
	$newfile = $directory."/".$prefix.$fname;
    }
print "DIR: $directory\n";
if ($quote && $newfile=~s/\Q$search/$replace/) {print "File: $file -> $newfile\n"; $renamed++;}
elsif ($newfile=~s/\Q$search/$replace/) {print "File: $file -> $newfile\n"; $renamed++;}

if (!$opt_R) {
    if ($newfile eq $file) {;}
    elsif ($newfile=~/$file/i) {
	mv($file,'temp');
	mv('temp',$newfile);
    }
    else {
	mv($file,$newfile);
   }
}
elsif($opt_R) {
    print "opening $file..\n";
    open(OLDFILE,"$file") or die "Error opening file $file\n";
    my $temp_name;
    if ($newfile=~/^$file$/i) {
	$temp_name = "temp";
    }
    else {
	$temp_name = $newfile;
    }
    
    unless ($test) {}
    
    my $found = 0;
    my $replaced = '';
    my $fixed = '';
    while (<OLDFILE>) {
	my $newline = $_;
	my $line = $newline;
	if ($quote) {
	    if ($line =~/\Q$search/) {
		$line =~s/\Q$search/$replace/g;
		$found++;
		$fixed .= $line;
		print "Q $found:\t$newline->\t$line\n" if $test; 
	    }
	}
	elsif ($regexp && $line =~/\Q$search/) {
	    my @indices;
	    $indices[1] = $1;
	    $indices[2] = $2;
	    $indices[3] = $3;
	    $indices[4] = $4;
	    $indices[5] = $5;
	    $indices[6] = $6;
	    $indices[7] = $7;
	    $indices[8] = $8;
	    $indices[9] = $9;
	    my $index = 1;
	    my $replacement = $replace;
	    while ($replacement =~ /\$$index/) { 
		$replacement =~s/\$$index/$indices[$index]/; 
		$index++;
	    }
	    $line =~s/\Q$search/$replacement/g;
	    $found++;
	    $fixed .= $line;		
	    print "REGEXP $found:\t$newline->\t$line\n" if $test; 
	} elsif ($line =~/\Q$search/) {
	    $line =~s/\Q$search/$replace/eg;
	    $found++;
	    $fixed .= $line;
	    print "Found $found:\t$newline->\t$line\n" if $test; 
	} 
	$replaced .= $line;
    }
    unless ($test) {
	open my $NEWFILE, '>', $temp_name or die "Error opening $temp_name.";
	print $NEWFILE $replaced;
	close $NEWFILE;
	if ($newfile=~/^$file$/i) {mv('temp','-f',$newfile);}
    }
    
    if ($found) {
	print "changes in $file\n$search  ->  $replace\n"; 
	print "**************************************\n";
	print $fixed;
	$changed++ unless $test;
    }
    close (OLDFILE);
    $total_found += $found;
}

print "Found $total_found instances\n";
print "Changed $changed Files\n";
print "Renamed $renamed Files\n";
print "Search String: $search\n";
print "Replace String: $replace\n";

if ($opt_A) {
    foreach $dir (@adirs) {
	chop $dir;
	$newdir=$dir;
	if ($quote) {$newdir=~s/\Q$search/$replace/;}
	else {$newdir=~s/\Q$search/$replace/;}
	if ($newdir ne $dir) {
	    print "Copying $dir to $newdir\n";
	    cp($dir,'-R',$newdir);
     	
	    print "operating on $newdir\n";
	}
	else {
	    $temp = $directory."/TEMP";
	    cp($dir,'-R',$temp);
	    $newdir = $temp;
	}
	my $command ="perl /home/rguin/Perl/rename.pl -d $newdir -s \"$search\" -r \"$replace\" -R -A"; 
	print "New command:\n$command\n\n";
	try_system_command($command);
	print "executed\n";
	if ($newdir=~/TEMP/) {rm($dir,'-Rf'); mv($newdir,$dir);}
    }
}
}

exit;









