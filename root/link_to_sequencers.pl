#!/usr/bin/perl
#
###############################
# link_to_sequencers.pl
###############################

#######################################
#
# This program is designed to communicate with the sequencers.
#
# It is used to send files to the sequencers (sample sheets)
# (and possibly retrieve files from the sequencers)
#
#######################################

################################################################################
# $Id: link_to_sequencers.pl,v 1.2 2002/11/05 21:55:09 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.2 $
#     CVS Date: $Date: 2002/11/05 21:55:09 $
################################################################################
#
# Author           : Ran Guin 
# 
# Purpose          : Main interface program for Sequencers 
#
# Standard Modules : CGI, DBI, Benchmark, Storable, GD, Date, FindBin, Barcode
#
# Custom Modules   : SDB:: (all)
#
# Setup Required   : Initialization of variables in SDB::CustomSettings.pm 
#
################################################################################
use strict;

use CGI qw(:standard);
use DBI;
use Benchmark;
use Date::Calc qw(Day_of_Week);

use Storable;
use GD;
use Getopt::Long;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/"; # add the local directory to the lib search path

use SDB::DB_IO qw(DB_Connect);
use SDB::GSDB;
use SDB::CustomSettings;

use RGTools::RGIO;
use RGTools::Views;

use alDente::SDB_Defaults;

use vars qw($request_dir);

########## Here there be Global Variables ##########

my $condition = "WHERE FK_Equipment__ID = Equipment_ID AND Equipment_Type = 'Sequencer'";

my ($sequencer);
&GetOptions("sequencer=s"=>\$sequencer);

if ($sequencer=~/^\d+$/) { $condition .= " AND FK_Equipment__ID=$sequencer"; }

my $dbh = DB_Connect(dbase=>'sequence',user=>'viewer');

my %Sequencer_Info = &Table_retrieve($dbh,'Machine_Default,Equipment',['Local_Data_Dir','Local_Samplesheet_dir','Host','FK_Equipment__ID as Eid'],
				     $condition);

######## Run for each of sequencers (unless one is specified) #############
my $timestamp = &RGTools::RGIO::timestamp();

my $index = 0;
while (defined %Sequencer_Info->{Host}[$index]) {
    my $host = %Sequencer_Info->{Host}[$index]; 
    my $Eid = %Sequencer_Info->{Eid}[$index]; 
    my $ss_path = %Sequencer_Info->{Local_Samplesheet_dir}[$index];
    $index++; 
    unless ($ss_path) {next;}
    unless (-e "$request_dir/Request.$Eid") {next;}   ### skip if no requests for this machine
    print "check Samplesheet Requests for $host \n";
    print "_______________________________________\n";
    my @files = split "\n", try_system_command("cat $request_dir/Request.$Eid");
    `mv $request_dir/Request.$Eid $request_dir/Moved.$Eid.$timestamp`;
    print "Moved:\n";
    foreach my $file (@files) {
	my $fback = `cp -p $file $ss_path/`;
	if ($fback) {  ## if there is a problem log the feedback..  
	    print "$fback\n"; 
	    `echo "$fback" >> $request_dir/Request.$Eid.$timestamp.failed`;
	}
	else {print "$file\n";}
    }
}

$dbh->disconnect();

exit;
