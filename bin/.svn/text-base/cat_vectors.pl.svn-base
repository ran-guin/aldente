#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

cat_vectors.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>This program regenerates a file with all vectors (and ecoli) to be screened<BR>by cross-match...<BR>

=cut

##############################
# superclasses               #
##############################
#
################################################################################
# cat_vectors.pl
#
# This program regenerates a file with all vectors (and ecoli) to be screened
#   by cross-match...
# 
################################################################################
################################################################################
# $Id: cat_vectors.pl,v 1.1 2006/12/19 00:36:11 mingham Exp $
################################################################################
# CVS Revision: $Revision: 1.1 $
#     CVS Date: $Date: 2006/12/19 00:36:11 $
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

use CGI ':standard';
use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Process_Monitor;
 
use SDB::DBIO;
use alDente::SDB_Defaults;
use alDente::Notification;
use alDente::Employee;
use SDB::CustomSettings;
use Data::Dumper;
use Getopt::Long;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($vector_directory $opt_host $opt_dbase $opt_user %Configs);

##############################
# modular_vars               #
##############################

##############################
# constants                  #
##############################
##############################
# main_header                #
##############################

&GetOptions(
            'host=s'                => \$opt_host,
            'dbase=s'               => \$opt_dbase,
    	    'user=s'                => \$opt_user);

my $host = $opt_host || $Configs{PRODUCTION_HOST};
my $dbase = $opt_dbase || $Configs{PRODUCTION_DATABASE};
my $user = $opt_user;

my $dbc = SDB::DBIO->new(-dbase=>$dbase,-host=>$host,-user=>$user,-connect=>1);
############ Construct Report object for writing to log files ###########
my $Report = Process_Monitor->new();

## Custom insert (temporary) <CONSTRUCION> - change to allow user log in ? (remove hardcoded Admin id (141) ##
$dbc->set_local('user_id',141);
my $eo = new alDente::Employee(-dbc=>$dbc,-id=>141);
$Report->set_Message("Using Emp141 user");
$eo->define_User();

## First go through all data in the database, and ensure there are matching vector files.
my @vectors = &Table_find($dbc,'Vector_Type','Vector_Type_Name,Vector_Sequence_File,Vector_Sequence',"WHERE Length(Vector_Sequence_File) > 0");

my $feedback;
my $errors;
my $warnings;

$Report->set_Message("Checking Database vectors...");

foreach my $vector (@vectors) {
    my ($name,$file,$sequence) = split ',', $vector;
    unless ($file) { 
	$Report->set_Error("no Vector sequence file specified for $name");
        $errors ||= 1;
	next; 
    }
    $sequence =~s/\s//g;       ## remove spaces if they exist... 
    $sequence =~s/\d//g;       ## remove number indexes if they exist... 

    if (-e "$vector_directory/$file") {
	## Add check to ensure sequences match..##
	my ($found_sequence) = &parse_vector_file($file,$name);
	unless ($found_sequence) { next; }
	if (!$sequence) {      ## update database with sequence if not currently stored.. ## 
	    my $ok = &Table_update_array($dbc,'Vector_Type',['Vector_Sequence'],[$found_sequence],"WHERE Vector_Sequence_File = '$file' AND (Vector_Sequence is NULL OR Length(Vector_Sequence)<2)",-autoquote=>1);
            if ($ok) {
                $Report->set_Message("$file Sequence missing in Database ... updating...");
            } else {
                if($DBI::errstr) {
                    $Report->set_Error($DBI::errstr);
                }
            }
	    next; 
	}
	$found_sequence =~s/\s//g;
	$sequence =~s/\s//g;

	if ($found_sequence =~ /^$sequence$/i) { 
           $Report->set_Detail("Matching $file file found"); 
	   $Report->succeeded();
	}
	else { 
	    my $err = "** Error: $file NOT MATCHING sequence in Database (please investigate)\n";
	    if ($found_sequence =~/(.*)$sequence(.*)/) {
		$err .= "** File sequence contains extra base pairs:\nPrefix: $1\nSuffix: $2\n";
	    } 
	    elsif ($found_sequence =~/(.*)$sequence(.*)/) {
		$err .= "** Database sequence contains extra base pairs:\nPrefix: $1\nSuffix: $2\n";		
	    } 
	    elsif ($sequence =~ /[BD-FH-MO-SU-Z]/) {
		$err .= "Non AGTCN characters in sequence\n";
	    } 
	    else {
		  my $seq_length = length($sequence);
		  my $file_length = length($found_sequence);
		$err .= "(Ambiguous sequence conflict between file ($file_length) and database sequence ($seq_length)\n";
	    }
	    $Report->set_Error($err);
            $errors ||= 1;
	}
    } else {
	my $failed = 0;
	open(VFILE,">$vector_directory/$file") or $failed++;
	if ($failed) { 
	    $Report->set_Error("Error opening new $file (in $vector_directory)");
	} 
	else {
	    $Report->succeeded();
	}
	
	print VFILE ">$name\n$sequence\n";
	close(VFILE);
	$Report->set_Detail("ADDED $file\n");
    }
}

## now look for files that are in the vector directory (may not be in database)...

my @vector_files = <$vector_directory/*.seq>;
my $new_screen_file = "$vector_directory/temp_screen_file";
my $screen_file = "$vector_directory/vector";

unless(open (NFILE,">$new_screen_file")) {
    $errors ||= 1;
    $Report->set_Error("error opening $new_screen_file");
}

foreach my $vector (@vector_files) {
    if ($vector =~ /(.*)\/(.+)/) { $vector = $2; }
    my ($found_sequence,$header) = parse_vector_file($vector);
    if ($found_sequence) {
	print NFILE ">$header\n";
	print NFILE "$found_sequence\n";
    }
}

my $diff = try_system_command("diff $screen_file $new_screen_file");

if ($diff) {
    my $archive_name = "screen_".convert_date(&today,'Simple');

    my $command;
    
    $command = "mv $screen_file $vector_directory/history/$archive_name";
    $Report->set_Detail("EXEC: $command");
    $feedback = try_system_command($command);
    $Report->set_Detail($feedback);


    $command = "mv $new_screen_file $screen_file";
    $Report->set_Detail("EXEC: $command");
    $feedback = try_system_command($command);
    $Report->set_Detail($feedback);

    $command = "chmod 666 $screen_file";
    $Report->set_Detail("EXEC: $command");
    $feedback = try_system_command($command);
    $Report->set_Detail($feedback);

    $Report->set_Message("Concatenated all *.seq files into $screen_file");
} else {
    $Report->set_Message("$screen_file unchanged");
}
close(NFILE);


$Report->set_Message("Tested " . int(@vectors) . " vectors"); 

## grab the list of vectors with NULL Vector_Sequence_Files
my @null_files = &Table_find($dbc,"Vector_Type","Vector_Type_Name","WHERE Vector_Type_Name <> 'No Vector' AND (Vector_Sequence_File IS NULL OR length(Vector_Sequence_File) = 0)");
## grab the list of vectors with an empty Vector_Sequence field
my @null_sequence = &Table_find($dbc,"Vector_Type","Vector_Type_Name","WHERE Vector_Type_Name <> 'No Vector' AND (Vector_Sequence IS NULL OR length(Vector_Sequence) = 0)");

foreach my $null_file (@null_files) {
    $Report->set_Warning("$null_file does not have a defined vector sequence file");
    $warnings ||= 1;
}

foreach my $null_sequence (@null_sequence) {
    $Report->set_Detail("$null_sequence does not have a defined vector sequence, will use all vectors to crossmatch");
}

if ($errors || $warnings) {
    $Report->set_Message("<b>Problems were noted with the current Vector sequence files located in $vector_directory.<br>Please address these as soon as possible to ensure correct vector trimming.</b>");
}

$Report->completed();
$Report->DESTROY();
exit;

####################
sub parse_vector_file {
####################
    my $file = shift;
    my $name = shift;

    open(VFILE,"$vector_directory/$file") or $Report->set_Error("error opening $file for reading (in $vector_directory)");
    
    my $found_sequence = '';
    my $header = <VFILE>;
    if ($header =~/^>([^\|]+)/) { 
	my $label = $1;
        xchomp ($label);
	if ($name && ($label !~ /\Q$name\E/i) ) { 
	    $Report->set_Warning("Header name ($label) doesn't match Vector name ($name) in $file.");
	}
    } else { 
	$Report->set_Error("Incorrect/missing header in $file sequence file:\n$header\n");
	return 0; 
    }
    while (<VFILE>) { 
	if (/^>/) {  
	   $Report->set_Error("Multiple vectors in one file ($file) (must be separated).");
	   return 0; 
	}  ## more than one sequence in file.. 
	elsif (/^([agtcn\s]+)$/i) {
            $found_sequence .= $1
        }
	else { 
	    $Report->set_Error("Unrecognized characters found in ($file) where sequence expected: $_."); 
	    return 0; 
	}
    }
    $found_sequence =~s /\s//g;   ## remove any linebreaks / spaces ...
    close(VFILE);
    
    return ($found_sequence,$header);
}
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

$Id: cat_vectors.pl,v 1.1 2006/12/19 00:36:11 mingham Exp $ (Release: $Name:  $)

=cut


