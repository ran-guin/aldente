#!/usr/local/bin/perl
#
################################################################################
#

use strict;
use CGI qw(:standard);
use DBI;
use File::stat;

use Archive::Tar;
require "getopts.pl";

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;

 
use SDB::CustomSettings;

use alDente::SDB_Defaults;

use vars qw($opt_m);

use vars qw($mirror_dir $session_dir $project_dir);

&Getopts('m');

my @machine_list = split ',', $opt_m;

my @machines = (1,2,3,4,5,6);

if ($machine) {@machines = @machine_list; }

foreach my $num (@machines) {
    my $pattern = "/home/aldente/public/mirror/3700/$num/data1/Data";
    my @dirs = glob("$pattern/*");
    
    my $index;
    print "Glob: $pattern/Run*\n\n";
    my $zipped = 0;
    
    my %Linked;
    my %Tarred;
    foreach my $dir (@dirs) {
	if ($dir =~ /^.*\/(Run.*).tar.gz$/) {
	    %Tarred->{$1} = 1;
	} elsif ($dir =~ /^.*\/(\S+)(Run.*).tar.gz$/) {
	    %Linked->{$2} = $1;
	}
    }
    
    shell_command("echo \"*** Checking linked in 3700-$num directories\" > /home/aldente/private/logs/tarred_files.$num"); 
    
    foreach my $dir (@dirs) {
#	print "$dir..\n";
	my $path;
	my $directory;
	if ($dir =~ /^(.*)\/(Run.*).tar.gz$/) {
	    $path = $1;
	    $directory = $2;
	    if (%Linked->{$directory}) {
		my $link = %Linked->{$directory};
		print "** $link \t--> \t$directory **\n";

		shell_command("echo \"Already linked $directory to $link\" >> /home/aldente/private/logs/tarred_files.$num"); 
		next;
	    }
	} else {next;}
	
	my $target_file;
	my $subdir_name;
	
	my $feedback;
	`cd /`;
	my $command = "tar -t -z -v -f $dir *.ab*";
	
#	print "check $0..\n";
#    print "$command\n";
	unless (-e "$dir") { print "$dir files not found ??"; next; }
	
#	my @zipped_files = split "\n", shell_command($command);
	
	my  $tar = Archive::Tar->new();
	my @zipped_files;
	if ($tar->read($dir)) { 	
	    @zipped_files = $tar->list_files();
	} else { 
	    my $newname = $dir;
	    $newname=~s/\/Run_/\/corrupted_Run_/;
	    if ($dir =~/^(.*).tar.gz$/) {
		my $subdir = $1;
		my $found = &try_system_command("ls $dir/ | wc");
		if ($found == 96) {
		    unlink("$dir.tar.gz");
		    print "** DELETED $dir.tar.gz (96 files found) **"; 
		}
		else { 
		    `mv $dir $newname`;
		    print "** $dir to $newname CORRUPTED ? (Found $found) **\n";
		}
	    } else {
		`mv $dir $newname`;
		print "** $dir to $newname CORRUPTED ? **\n";
	    }
	    next;
	}
	
	if ($zipped_files[0] =~/Not found/i) { print "** $dir NOT FOUND (or nothing in it) **\n"; next; }
	my $name = $zipped_files[$#zipped_files]; ### get last zipped filename...
	chomp $name;
	my $subdir_name;
	if ($name =~ /(.*)\/(Run.*)\/(.*?)_(.*?)$/) {
	    $subdir_name = $3;
	} elsif ( $name =~ /(.*)\/(Run.*)\/(\S+)(.*?)$/ ) {
	    $subdir_name = "Special_" . $3;
	}
	
	unless ($subdir_name) { print "no subdirectory_name found for $name..\n"; next;}
	
	my $target_name = "$path/$directory";
	$name = $directory;
	
	if ($target_name =~/^(.*)\/(.*?)$/) {
	    $target_file = "$1/$subdir_name$2";
	} else {$target_file = $target_name;}
	
	if (-e "$target_file.tar.gz") {
	    print "$target_file.tar.gz EXISTS\n";
	} else {
#	    my $command = "ln -s $dir $target_file.tar.gz";
#	    shell_command("ln -s $dir $target_file.tar.gz");
	    symlink($dir, "$target_file.tar.gz");
	    print "** LINKed $target_file **\n";
	    shell_command("echo \"*** LINKED $target_file.tar.gz\" >> /home/aldente/private/logs/tarred_files.$num ***"); 
	}
	
	next;
    }
}

exit;

############# Options for Cleaning UP ###########
my $home_dir = $project_dir;

my $dbc = DB_Connect(dbase=>'sequence');

my @subdirs = &Table_find_array($dbc,'Library,Project,Run,Equipment,RunBatch',['Run_Directory','Equipment_Name',"concat(Project_Path,'/',Left(Run_Directory,5),'/SampleSheets')"],"where FK_RunBatch__ID=Sequence_Batch_ID AND FK_Equipment__ID=Equipment_ID AND Left(Run_Directory,5)=Library_Name AND FK_Project__ID=Project_ID Order by Library_Name");

my $found = 0;
my $missing = 0;
my $number = int(@subdirs);

foreach my $dir (@subdirs) {
    my ($subdir, $machine, $path) = split ',', $dir;
    my $ext;
    if ($machine=~/MB/) {$ext = "psd";}
    elsif ($machine=~/3700/) {$ext = "plt";}

    my $found = shell_command("cd $home_dir/$path; ls $home_dir/$path/$subdir.p*");
    if ($found=~/no such/i) {
	print "$missing:\tmissing $home_dir/$path/$subdir.$ext ";
	my $ok = shell_command("touch $home_dir/$path/$subdir.$ext");
	$missing++;
	my $ok = shell_command("echo \"$subdir.ext\" >> $home_dir/$path/MISSING_FILES");
	print "$ok\n";
    }
    else {$found++;}
}


print "\nFound $found... Missing $missing(of $number).\n";
exit;

#######################
sub shell_command {
#######################
    my $command = shift;
    
    my $out = `$command`;

    return $out;
}

