#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

fix_plates.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>system_variables           #<BR>standard_modules_ref       #<BR>

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
use strict;
use Getopt::Std;
use Data::Dumper;
use DBI;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use SDB::CustomSettings;
use SDB::DBIO;
use RGTools::RGIO;
use alDente::SDB_Defaults;
use alDente::Barcoding;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($opt_D $opt_u $opt_p $opt_P $opt_L $opt_N $opt_C);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
getopts('D:u:p:P:L:N:C:');
my $dbase = $opt_D;
my $user = $opt_u;
my $password = $opt_p;
my $plate = $opt_P; #plate ID to be renamed
my $lib = $opt_L; #new library name
my $platenum = $opt_N; #new plate number 
my $comments = $opt_C; #plate comments
unless ($dbase && $user && $password && $plate && $lib && $platenum) {print "Missing parameters.\n"; exit}
unless (try_system_command("whoami") =~ /sequence/) {print "You must log in as 'sequence' user to run this script.\n"; exit}
#unless (try_system_command("uname -n") =~ /plebe/) {print "You must run this script on plebe.\n"; exit}
my $dbc = SDB::DBIO->new(-dbase=>$dbase,-host=>'lims02',-user=>$user,-password=>$password,-connect=>0);
my $dbc->connect();
#First make sure the new library exists in db and grab its coressponding project
my ($project) = Table_find_array($dbc,'Library,Project',['Project_Path'],"where Project_ID=FK_Project__ID and Library_Name = '$lib'");
unless ($project) {
    print "Libary $lib does not exist in the database.\n";
    exit;
}
#Now grab the existing library, plate number for the plate....
my %info = Table_retrieve($dbc,'Plate,Library,Project',['Project_Path','FK_Library__Name','Plate_Number'],"where Project_ID=FK_Project__ID and Library_Name=FK_Library__Name and Plate_ID = $plate");
unless (%info) {
    print "Plate $plate does not exist in the database.\n";
    exit;
}
my $old_project = %info->{Project_Path}[0];
my $old_lib = %info->{FK_Library__Name}[0];
my $old_platenum = %info->{Plate_Number}[0];
#Now find all the child plates of this plate....
my @update_plates;
push (@update_plates,$plate);
my @info = Table_find_array($dbc,'Plate',['Plate_ID'],"where FKParent_Plate__ID in ($plate)");
while (@info) {
    foreach my $child (@info) {
	push(@update_plates,$child);
    }
    my $ids = join(',',@info);
    @info = ();
    @info = Table_find_array($dbc,'Plate',['Plate_ID'],"where FKParent_Plate__ID in ($ids)");
}
#Now update library and plate number
print "------------------------------------------------------------\n";
print "Updating plate IDs: (" . join(',',@update_plates) . ") to library $lib and plate number $platenum...\n";
print "------------------------------------------------------------\n";
unless ($comments) {
    $comments = "Relinked from $old_lib-$old_platenum to $lib-$platenum";
}
my $updated = Table_update_array($dbc,'Plate',['FK_Library__Name','Plate_Number','Plate_Comments'],["'$lib'",$platenum,"concat(Plate_Comments,';','$comments')"],"where Plate_ID in (" . join(',',@update_plates) . ")");
print "Updated $updated records.\n";
####Reprint plate barcodes####
foreach my $plate (@update_plates) {
    my $barcode = 'pla' . $plate;
    &alDente::Barcoding::PrintBarcode($dbc,'Plate',$barcode);
}
##############################
#Now rename the folders and directories.
my %info = Table_retrieve($dbc,'RunBatch,Run,SequenceRun,SequenceAnalysis,Equipment',['Run_ID','Run_Directory','Equipment_ID','Equipment_Name','Run_Directory'],"where RunBatch_ID = FK_RunBatch__ID AND Run_ID=FK_Run__ID AND SequenceRun_ID=FK_SequenceRun__ID and Equipment_ID = FK_Equipment__ID and FK_Plate__ID in (" . join(',',@update_plates) . ")");
my @sids;  #keep track of the sids for running update seequence later.
my %eids;  #Keep track of the sequencers that we need to mount.
my $i = 0;
while (defined %info->{Run_ID}[$i]) {
    my $sid = %info->{Run_ID}[$i];
    my $subdir = %info->{Run_Directory}[$i];
    my $eid = %info->{Equipment_ID}[$i];
    my $equip = %info->{Equipment_Name}[$i];
    my $run_dir = %info->{Run_Directory}[$i];
    my $equip_type;
    my $equip_number;
    my $data_dir;
    if ($equip =~ /MB([0-9]+)/) {
	$equip_type = 'mbace';
	$equip_number = $1;
	$data_dir = 'data2';
    }
    elsif ($equip =~ /D(\d+)-(\d+)/) {
	$equip_type = $1;
	$equip_number = $2;
	$data_dir = 'data1';
    }
    #Figure out the new subdirectory name
    my $new_subdir;
    $subdir =~ /[A-Za-z0-9]+(\..*)/;
    $new_subdir = "$lib$platenum$1";
    #See if we need to mount the sequencer...
    unless (exists %eids->{$eid}) {
	my %info = &Table_retrieve($dbc,'Machine_Default,Equipment',['Mount'],"WHERE FK_Equipment__ID = Equipment_ID AND Equipment_ID = $eid");
	my $mnt_dir = %info->{Mount}[0];
	chdir "/";
	#_umount($mnt_dir);
	#_mount($mnt_dir);
	%eids->{$eid} = $mnt_dir;
    }
    #Find out the archive subdirectories and rename those files...
    print "------------------------------------------------------------\n";
    print "Renaming trace files in archive/mirror/sequencers folders for SID $sid...\n";
    print "------------------------------------------------------------\n";
    my $find_dir = "/home/sequence/archive/$equip_type/$equip_number/$data_dir/Data/";
    _rename_files($find_dir,$subdir,%eids->{$eid},$run_dir);
    #Now rename and move the sample sheets to the new library folder.
    print "------------------------------------------------------------\n";
    print "Renaming and moving sample sheets for SID $sid...\n";
    print "------------------------------------------------------------\n";    
    my $ss_dir = "/home/sequence/Projects/$old_project/$old_lib/SampleSheets/";
    my $new_ss_dir = "/home/sequence/Projects/$project/$lib/SampleSheets/";
    print "Finding samplesheets with name like '$subdir.???' under '$ss_dir'\n";
    my $ss = try_system_command("find $ss_dir -name '$subdir.???'");
    #print "SS_DIR=$ss_dir;SUBDIR=$subdir;SS=$ss\n";
    foreach my $s (split /\n/, $ss) {
	my $new_s = $s;
	$new_s =~ s/$old_lib$old_platenum/$lib$platenum/g;
	$new_s =~ s/$old_lib/$lib/g;
	print "Moving '$s'\n to    '$new_s'...\n";
	print try_system_command("mv $s $new_s");
    }
    #Need to update the sequence subdirectory in the Run database.
    print "------------------------------------------------------------\n";
    print "Updating sequence subdirectory of SID $sid in Run table from '$subdir' to '$new_subdir'...\n";
    print "------------------------------------------------------------\n";	
    my $updated = Table_update_array($dbc,'Run',['Run_Directory'],[$new_subdir],"where Run_ID = $sid",-autoquote=>1);
    print "Updated $updated records.\n";
    push(@sids,$sid);
    $i++;
}
#Umount the sequencers...
#chdir "/";
#foreach my $eid (%eids) {
    #_umount(%eids->{$eid});
#}
#One last step - run update sequence..........
print "------------------------------------------------------------\n";
print "Running update_sequence.pl for (" . join(',',@sids) . ")...\n";
print "------------------------------------------------------------\n";
print try_system_command("update_sequence.pl -A all -S " . join(',',@sids));

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

######################
sub _rename_files {
######################
    my $find_dir = shift;
    my $subdir = shift;
    my $mnt_dir = shift;
    my $run_dir = shift;

    #my $archive_links = try_system_command("find $find_dir -name '$subdir*' -type l");
    #print "Searching for archive links with the name like '$subdir' under '$find_dir'...\n";
    #print "SID=$sid;SD=$new_subdir;AL=$archive_links\n";
    #foreach my $archive_link (split /\n/, $archive_links) {
	#print "Searching for files under the archive link '$archive_link'...\n";
	#my $archive_dir = readlink($archive_link);
        my $archive_dir = "$find_dir/$run_dir";
	my $mirror_dir = $archive_dir;
	$mirror_dir =~ s/archive/mirror/;
	#print "SID=$sid;AD=$archive_dir\n";

	#Rename files in archive folder....
	my $files = try_system_command("ls $archive_dir");
	foreach my $file (split /\n/, $files) {
	    $file =~ /[a-zA-Z0-9]+([abcd]?\..*\.ab1)/;
	    my $new_file = "$lib$platenum$1";
	    if ($1) {
		print "Renaming '$archive_dir/$file'\n to      '$archive_dir/$new_file'...\n";
		print try_system_command("mv $archive_dir/$file $archive_dir/$new_file");
	    }
	}

	#Rename files in mirror folder...
	my $files = try_system_command("ls $mirror_dir");
	foreach my $file (split /\n/, $files) {
	    $file =~ /[a-zA-Z0-9]+([abcd]?\..*\.ab1)/;
	    my $new_file = "$lib$platenum$1";
	    if ($1) {
		print "Renaming '$mirror_dir/$file'\n to      '$mirror_dir/$new_file'...\n";
		print try_system_command("mv $mirror_dir/$file $mirror_dir/$new_file");
	    }
	}

	#Rename files in the sequencers...
	#my $seq_dir;
	#$archive_dir =~ /.*(Run_.*)$/;
	#$seq_dir = "$mnt_dir/Data/$1";
	#my $files = try_system_command("ls $seq_dir");
	#foreach my $file (split /\n/, $files) {
	    #$file =~ /[a-zA-Z0-9]+([abcd]{1}\..*\.ab1)/;
	    #my $new_file = "$lib$platenum$1";
	    #print "Renaming '$seq_dir/$file'\n to      '$seq_dir/$new_file'...\n";
	    #print try_system_command("mv $seq_dir/$file $seq_dir/$new_file");
	#}
	
    #}    
}

##############
sub _mount {
##############
#
# Unmount point 
#
# - return 0 if successful
# - return message if problem... 
#  
    my $fs = shift;
    my $error = try_system_command("sudo mount $fs");

    print "MSG1: $error";

    if ($error) { print "Error mounting ?\n$error\n"; }
    else { print "Mounting $fs\n";}
    return $error;
}

##################
sub _umount {
##################
#
# Unmount point 
#
# - return 0 if successful
# - return -1 if not mounted
# - return message if problem... 
#
  my $fs = shift;
  my $error = try_system_command("sudo umount $fs");
  
  print "MSG2: $error";

  if ($error=~/not mounted/) {
      return -1;            ## not mounted...
  } elsif ($error) {
      print "** Error: Problem Unmounting ?\n$error"; 
      return 1;
  } else { return 0; } ### success 
}

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

$Id: fix_plates.pl,v 1.5 2004/06/03 18:12:15 achan Exp $ (Release: $Name:  $)

=cut

