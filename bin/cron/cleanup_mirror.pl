#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

cleanup_mirror.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
perldoc_header             
superclasses               
system_variables           
standard_modules_ref       
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
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Core/";
use lib $FindBin::RealBin . "/../lib/perl/Imported/";
use alDente::SDB_Defaults;
use SDB::DBIO;
use File::stat;
 
use SDB::CustomSettings;
use Data::Dumper;
use Benchmark;
use RGTools::RGIO;
use RGTools::Process_Monitor;
use SDB::Report;
use POSIX;
use Digest::MD5;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($opt_h $opt_m $opt_S $opt_s $opt_t);
use vars qw($Data_log_directory);

##############################
# modular_vars               #
##############################

######################## construct Process_Monitor object for writing to log file ###########

my $Report = Process_Monitor->new('cleanup_mirror.pl Script',
				  -quiet => 0,
				  -verbose => 0
				  );

##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
require "getopts.pl";
&Getopts('l:s:t:m:S:h');

if ($opt_s && $opt_t && $opt_S) {
    my $curr_epoch_time = POSIX::time();
    my ($source_count,$target_count,$removed_count,$failed_count) = traverse_and_compare(-source=>"$opt_s",-target=>"$opt_t",-save_from=>$opt_S,-epoch=>$curr_epoch_time,-skip_dir=>1); 

    $Report->set_Detail("**** SUMMARY for $opt_s,".&date_time);
    $Report->set_Message("Total files/directories in $opt_s   : $target_count");
    $Report->set_Message("Total files/directories in $opt_t   : $source_count") ;
    $Report->set_Message("Total files removed from mirror     : $removed_count");
    $Report->set_Message("Total files that failed checksum    : $failed_count" );

    $Report->completed();
    $Report->DESTROY();
    exit;
}

if ($opt_m && $opt_S) {
##################################
#### Cleanup Mirror directory ####
##################################
#
# This should clean up the mirror directory.
# Files already in the archive directory should be erased.
# A list of Files sitting around should be sent to administrators for cleaning out or checking.... 
##################################
##### NEW CODE: 
# look at all directories in $mirror_dir
# check if the directory exists in $archive_dir
# check if file count for directory matches $archive_dir's filecount
# check if checksum matches for all files in directory
# if at any stage, this fails the test, skip those files and note in log
# if all checks succeed, delete $mirror/$seqid/$id/$data/$data_subdir/$run_subdir
    my $dbc = SDB::DBIO->new(-dbase=>'sequence',-host=>'lims02',-user=>'viewer',-password=>'viewer');
    $dbc->connect();
    my @machine_default_ids = ();
    my $logfile = "$Data_log_directory/cleanup/cleanup_mirror_".&today.".log";
    #my $logfile = "cleanup_mirror_".&today.".log";
    my $condition_string = "WHERE FK_Equipment__ID = Equipment_ID AND Equipment_Status = 'In Use' AND Equipment_Type = 'Sequencer' ";
    my $sequencer = $opt_m;
    if ($sequencer eq "all") {
	@machine_default_ids = &Table_find($dbc,"Machine_Default,Equipment","Machine_Default_ID", "WHERE FK_Equipment__ID = Equipment_ID AND Equipment_Type = 'Sequencer'");
    }
    elsif ($sequencer =~ /.+/) {
	$sequencer =~ s/,/','/g;
	@machine_default_ids = &Table_find($dbc,"Machine_Default,Equipment","Machine_Default_ID","where FK_Equipment__ID = Equipment_ID AND Equipment_Type = 'Sequencer' AND Host in ('$sequencer')");
	my $ids = join "','",@machine_default_ids;
	$condition_string .= " AND Machine_Default_ID in ('$ids')";
    }
    if (scalar(@machine_default_ids) == 0) {
	open (INF, $logfile);
	$Report->set_Error("ERROR: No sequencers match input");
	print INF "ERROR: No sequencers match input";
	print "ERROR: No sequencers match input";
	close(INF, $logfile);
    }
    my %Sequencer_Info = &Table_retrieve($dbc,'Machine_Default,Equipment',['Local_Data_Dir'],$condition_string);
    $dbc->disconnect();
    #get information for each sequencer
    my $index = 0;
    while (defined %Sequencer_Info->{Local_Data_Dir}[$index]) {  
	my $data_dir = %Sequencer_Info->{Local_Data_Dir}[$index];
	$index++; 
	# clean the mirror directories of each sequencer that is in use
	# print preamble
	my @df = split "\n",try_system_command("df -h $mirror_dir");

	$Report->set_Detail("Starting log for mirror cleanup $data_dir, ".&date_time);
	$Report->set_Message("Disk capacity report before : $df[1] ");

	my $curr_epoch_time = POSIX::time();
	my ($source_count,$target_count,$removed_count,$failed_count) = traverse_and_compare(-source=>"$mirror_dir/$data_dir",-target=>"$archive_dir/$data_dir",-save_from=>$opt_S,-epoch=>$curr_epoch_time,-skip_dir=>1);	

	$Report->set_Detail("**** SUMMARY for $data_dir,".&date_time);
	$Report->set_Detail("Total files/directories in archive directory : $target_count");
	$Report->set_Detail("Total files/directories in mirror directory : $source_count");
	$Report->set_Detail("Total files removed from mirror : $removed_count");
	$Report->set_Detail("Total files that failed checksum : $failed_count");	
        $Report->set_Message("Targ: $target_count, Src: $source_count, MirrorRemoved: $removed_count, FailChecksum: $failed_count");
	
	my @df = split "\n",try_system_command("df -h $mirror_dir");
	
	$Report->set_Detail("Ending log for mirror cleanup $data_dir, ".&date_time);
	$Report->set_Message("Disk capacity report after  : $df[2]"); 
    }

    $Report->completed();
    $Report->DESTROY();
    exit;
}

if ( $opt_h || 1 ) {
    print "SYNTAX:\n";
    print "cleanup_mirror.pl -m <sequencer> -S <duration>\n";
    print "   <sequencer> is the sequencer name (ie d3100-1, d3730-2)\n";
    print "   <duration> is the number of days to preserve from current date.\n\n";
    print "EXAMPLE: \n";
    print "   cleanup_mirror.pl -m d3100-1 -S 7 \n";
    print "   - This will remove files from the mirror directory of d3100-1 unless they\n";
    print "     are more recent than 7 days\n";
    print "\n\n- OR -\n\n";
    print "cleanup_mirror.pl -s <source> -t <target> -S <duration> -l <logfile>\n";
    print "   <source> is the source directory (ie the mirror directory). THIS DIRECTORY WILL HAVE FILES DELETED!\n";
    print "   <target> is the target directory (ie the archive directory).\n";
    print "   <duration> is the number of days to preserve from current date.\n";
    print "   <logfile> is the logfile to write to. This file will be appended to.\n\n";
    print "EXAMPLE: \n";
    print "   cleanup_mirror.pl -s /home/mirror -t /home/archive -S 7 -l /home/archive/logs/logmirror.log\n";
    print "   - This will remove files from the mirror directory unless they are more recent than 7 days\n";
    exit;
}

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

###############################
# Subroutine: helper function that cleans out a mirror and archive directory
#             
# Return: none
###############################
sub traverse_and_compare {
    my %args = @_;
    my $source = $args{-source};
    my $target = $args{-target};
    my $save_duration = $args{-save_from};
    my $epoch = $args{-epoch};
    my $skip_dir = $args{-skip_dir} || 0;

    # log file summary information
    my $target_element_count = 0;
    my $source_element_count = 0;
    my $removed_file_count = 0;
    my $failed_checksum_count = 0;

    $Report->set_Detail("IN DIRECTORY $source");

    my @sources = glob "$source/*";
    my @targets = glob "$target/*";

    $Report->set_Detail("ELEMENTCOUNT: source(".@sources.") vs target(".@targets.")");
    
    # update counts
    $source_element_count += scalar(@sources);
    $target_element_count += scalar(@targets);

    my @checksum_files_source = ();
    my @checksum_files_target = ();
    foreach my $source_branch (@sources) {
	# if it is a directory and it exists in $target, recurse
	# if it doesn't exist in $target, skip this directory
	my $target_branch = $source_branch;
	$target_branch =~ s/$source/$target/;
	if (-d $source_branch) {
	    if ( (-e $target_branch) && (-d $target_branch) ) {
		# determine age of directory. If younger than $save_duration, skip
		my @stat_info = stat("$source_branch");
		my $dir_age = ((POSIX::difftime($epoch,$stat_info[9]))/86400);
		if ($dir_age < $save_duration) {
		    $Report->set_Detail("$source_branch is $dir_age days old, skipping");
		    next;
		}
		else {
		    $Report->set_Detail("$source_branch is $dir_age days old, recursing.");
		    
		    my ($source_count,$target_count,$removed_count,$failed_count) = traverse_and_compare(-source=>$source_branch,-target=>$target_branch,-save_from=>$save_duration,-epoch=>$epoch);
		    $source_element_count += $source_count;
		    $target_element_count += $target_count;
		    $removed_file_count += $removed_count;
		    $failed_checksum_count += $failed_count; 
		}
	    }
	    else {

		### check to see if the sequencer is incorrectly identified ###
		my $switched = 0;
		foreach my $i (1..9) {
		    my $try_target_branch = $target_branch;
		    $try_target_branch =~s /\/\d\//\/$i\//;
		    if ( (-e $target_branch) && (-d $target_branch) ) {
#			print $fh  "\n Equipment improperly scanned for $target_branch ? (try $i) \n";
			$Report->set_Warning("Equipment improperly scanned ? (try $i) ");
			$switched++;
			last;
		    }
		}
		unless ($switched) {
#		    print $fh  "\n source_branch does not exist in $target dir, skipping\n";

		    _move_unidentified($source_branch);

#		    $Report->set_Warning("$source_branch does not exist in $target dir, skipping");
		}
		next;
	    }
	}
	elsif (-f $source_branch) {
	    # if it is a file, check for existence in target and add to list of files to check for checksum for source
	    # if the file does not exist in $target, skip this directory
	    if ( (!(-e $target_branch)) && $skip_dir) {
		
		_move_unidentified($source_branch);

		$Report->set_Warning("$target_branch does not exist, skipping...");
	    }
	    elsif (!(-e $target_branch)) {
		_move_unidentified($source_branch);
		$Report->set_Warning("$target_branch does not exist, skipping...");
		return ($source_element_count,$target_element_count,$removed_file_count,$failed_checksum_count);
	    }
	    push (@checksum_files_source, $source_branch);
	}
	else {
	    # if it is not a file or directory, what is it?? skip
	    next;
	}
    }

    foreach my $target_branch (@targets) {
	# add to target
	if (-f $target_branch) {
	    push (@checksum_files_target, $target_branch);
	}
    }

    # if not equal in size, something is wrong, skip
    if ( (scalar(@checksum_files_source) != 0) && (scalar(@checksum_files_target) != scalar(@checksum_files_source))  && (scalar(@checksum_files_target) !~ /^96|192|288|384$/)) {
	$Report->set_Error("filecount failed. $source(".@checksum_files_source.") != $target(".@checksum_files_target.")");

	return ($source_element_count,$target_element_count,$removed_file_count,$failed_checksum_count);	
    }
    else {
	$Report->set_Detail("filecount passed or source has 0 files. \n    $source(".@checksum_files_source.") == $target(".@checksum_files_target.")");
    }

    # only calculate checksums if there is > 0 files in source
    if ( scalar(@checksum_files_source) > 0) {
	$Report->set_Detail("CALCULATING checksums...");
	
	# compile all files into a single checksum
	my $md5source = Digest::MD5->new;
	my $md5target = Digest::MD5->new;
	my $source_filelist = join " ",@checksum_files_source;
	my $target_filelist = join " ",@checksum_files_target;
	
	my %source_hash;
	my %target_hash;
	
	# compute single checksum
	foreach my $md5file (@checksum_files_source) {
	    open (FILECHECK,$md5file);
	    binmode FILECHECK;
	    $md5source->addfile(FILECHECK);
	    $source_hash{$md5source->hexdigest()} = $md5file;
	    close (FILECHECK);
	}
	# compute single checksum
	foreach my $md5file (@checksum_files_target) {
	    open (FILECHECK,$md5file);
	    binmode FILECHECK;
	    $md5target->addfile(FILECHECK);
	    $target_hash{$md5target->hexdigest()} = $md5file;
	    close (FILECHECK);
	}
	
	# do a set difference on the keys
	my @source_keys = keys %source_hash;
	my @target_keys = keys %target_hash;
	my $diff_ref = &_set_difference(\@source_keys,\@target_keys);
	my @difference = @{$diff_ref};
	
	# the ones that are left have failed the checksum
	my @checksum_errors = map {$_ = $source_hash{$_}." FAILED existence/checksum check"; } @difference;
	
	my $passed_checksum = scalar(keys %source_hash) - scalar(@checksum_errors);
	$Report->set_Detail("PASSED CHECKSUM for " . $passed_checksum . " files");
	
	# if checksums aren't the same, skip
	if (@checksum_errors > 0) {
	    foreach $checksum_error (@checksum_errors) {
		$Report->set_Error("CHECKSUM mismatch:, skipping....\n Error is:$checksum_error");
	    }
	    return ($source_element_count,$target_element_count,$removed_file_count,$failed_checksum_count+scalar(@checksum_errors));
	}
    }

    if (scalar(@checksum_files_source) != 0) {
	$Report->set_Detail("CHECKSUM correct, continuing....");
    }
    else {
	$Report->set_Detail("directory empty, continuing....");
    }
    # if checksums are the same, remove the source files
    unlink (@checksum_files_source);
    $Report->set_Detail(" UNLINKED ".@checksum_files_source." files in $source");

    $removed_file_count +=  scalar(@checksum_files_source);
    # remove the $source directory unless it has contents
    if ( (scalar(glob "$source/*") == 0) && ($skip_dir == 0) ) {
	rmdir $source;
	$Report->set_Detail("REMOVED DIRECTORY $source");
	
    }
    $Report->succeeded();
    return ($source_element_count,$target_element_count,$removed_file_count,$failed_checksum_count);
}

##############################
# private_methods            #
##############################

##############################
# function: takes the set difference
# return: elements of A that are not in B
##############################
sub _set_difference {
    my $A = shift;
    my $B = shift;

    my %seen; # lookup table
    my @difference;
		    
    # build lookup table
    @seen{ @{$B} } = ();
		    
    foreach my $item ( @{$A} ){
	push(@difference, $item) unless exists $seen{$item};
    }
    return \@difference;
}

sub _move_unidentified {

    #CHECK FOR PAST FILES/DIRS FIRST!
    my $file = shift;    
    my $stats = stat("$file");
#    print Dumper $stats;
    my $stamp = &date_time($stats->mtime);

    my ($date) = split ' ', &date_time();
    my ($year, $month, $day ) = split '-', $date;
    try_system_command("mkdir /home/sequence/mirror/unidentified");
    try_system_command("mkdir /home/sequence/mirror/unidentified/$year");
    try_system_command("mkdir /home/sequence/mirror/unidentified/$year/$month");
    unless ($stamp =~ /2007/) {
	print "File to move: $file\n";
	try_system_command("mv $file /home/sequence/mirror/unidentified/$year/$month/");
			   }
}    
    




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

$Id: cleanup_mirror.pl,v 1.8 2004/05/12 16:31:01 jsantos Exp $ (Release: $Name:  $)

=cut

