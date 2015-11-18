#!/usr/local/bin/perl

################################################################################
#
# update_sequence.pl
#
# Updates the sequence SQL database by reading data that was mirrored from
# the Sequencers. It calls phred, cross-match and analysis procedures.
#
# "Here's thirty thousand pounds,
#  quick take it before they arrest me,
#  it's hot."
#
################################################################################

################################################################################
# $Id: run_analysis.pl,v 1.2 2002/11/06 21:50:40 achan Exp $
################################################################################
# CVS Revision: $Revision: 1.2 $
#     CVS Date: $Date: 2002/11/06 21:50:40 $
################################################################################

use CGI ':standard';
use Time::Local;
use strict;
use Getopt::Std;
use Date::Calc qw(Now Today);

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

 
use SDB::RGIO;
use SDB::SDB_Defaults;
use SDB::Post;
use SDB::Report;
use SDB::CustomSettings;

our ($opt_h, $opt_A, $opt_x, $opt_v, $opt_S, $opt_D, $opt_i, $opt_M, $opt_t, $opt_l, $opt_v, $opt_R, $opt_f, $opt_F);
our ($style, $dbase, $nowdate, $nowtime, $reversal);
our ($ERROR, $REPORT);
our ($dbc);
use vars qw($testing $local_drive);

my $dbase = "sequence";
$dbc = DB_Connect(dbase=>$dbase);

my $actions;
my $exclusions;
my $inclusions;
my $base;
my $chemcode;
my $ver;
my $verbose = 0;    # verbose flag.
my $force = 0;      # Force analysis flag. Set to 1 to force for a quadrant. Set to 2 to force no matter what.
my $seq_list;
my $machine_choice; # gets set to a snippet of a SELECT statement to limit runs to a particular machine
my @sequences;

getopts('A:x:vS:D:i:M:t:lvRfFh');

$nowdate = sprintf("%4d-%02d-%02d", Today());
$nowtime = sprintf("%02d:%02d:%02d", Now());

if ($opt_D) {$dbase = $opt_D } # database to use
if ($opt_v) {$verbose = 1 }    # verbose mode
if ($opt_R) {
  print "NOTE: Reversed Plate Orientation!\n";
  $reversal = 1;   # allow for plate reversal
}
if ($opt_x) { $exclusions = $opt_x } # exclude these Run IDs
if ($opt_i) { $inclusions = $opt_i } # include only these Run IDs
if ($opt_f) { $force = 1 }           # force analysis for quadrant of 384 well
elsif ($opt_F) { $force = 2 }        # force even if not even 96 files found

if ((!$opt_A && !$opt_l) or ($opt_h)) {
  usage();
  exit;
}
else {
  $actions = $opt_A;
  if ($actions =~ /all/i) {$actions = "get,Update";}
}

# Select runs by id
if ($opt_S) {
  $seq_list = $opt_S;

  # replace ranges. e.g. '1,3-6' becomes '1,3,4,5,6'
  while (($seq_list=~/(\d+)[-](\d+)/) && ($2>$1)) {
    my $numlist = join ',',($1..$2);
    $seq_list=~s/$1[-]$2/$numlist/;
  }
}

# Select runs by Sequencer machine
if ($opt_M) {
  my $M_id;
  my $Mname = $opt_M;
  if ( $Mname =~ m/mbace(\d+)/ ) { $Mname = "MB" . $1 }
  elsif ( $Mname =~ m/d3700-(\d+)/ ) { $Mname = "D3700-".$1 }

  $M_id = join ',',Table_find($dbc,'Equipment','Equipment_ID',"where Equipment_Name = \"$Mname\"");

  if ($M_id eq 'NULL') { print "Invalid Machine name entered\n\n"; exit; }
  $machine_choice = "and Equipment_ID = $M_id";
}

# Select runs by time period
my $date_choice;
if ($opt_t) {
  if ($opt_t =~ m/[>](\d\d\d\d-\d\d-\d\d)/) {
    $date_choice = " and RunBatch_RequestDateTime > \"$1\"";
  }
  elsif ($opt_t =~ m/(\d\d\d\d-\d\d-\d\d)/) {
    $date_choice = " and RunBatch_RequestDateTime > \"$1 00:00:00\" and RunBatch_RequestDateTime <= \"$1 23:59:59\" ";
  }
}

print "*** Starting update_sequence.pl ***\n";

if ($seq_list =~ m/all/i) {
  @sequences = Table_find($dbc, 'Run,RunBatch,Equipment','Run_ID, FK_Plate__ID, Run_Directory, Equipment_Name,RunBatch_RequestDateTime',"where FK_RunBatch__ID=Sequence_Batch_ID and RunBatch.FK_Equipment__ID=Equipment_ID and Run_State like '%In Process%' $machine_choice Order by Run_ID");
}
elsif ($seq_list) {
  @sequences = Table_find($dbc, 'Run,RunBatch,Equipment','Run_ID, FK_Plate__ID, Run_Directory, Equipment_Name,RunBatch_RequestDateTime',"where FK_RunBatch__ID=Sequence_Batch_ID and Run_ID in ($seq_list) and RunBatch.FK_Equipment__ID=Equipment_ID $date_choice Order by Run_ID");
}
elsif ($date_choice) {
  @sequences = Table_find($dbc, 'Run,RunBatch,Equipment','Run_ID, FK_Plate__ID, Run_Directory, Equipment_Name,RunBatch_RequestDateTime',"where FK_RunBatch__ID=Sequence_Batch_ID and RunBatch.FK_Equipment__ID=Equipment_ID $date_choice Order by Run_ID");
}
else {
  ######### find Sequences which have been run but not recorded (Date=0) #####
  @sequences = Table_find($dbc, 'Run,RunBatch,Equipment','Run_ID, FK_Plate__ID, Run_Directory, Equipment_Name,RunBatch_RequestDateTime',"where FK_RunBatch__ID=Sequence_Batch_ID and Run_State like \"%In Process%\" and RunBatch.FK_Equipment__ID=Equipment_ID $machine_choice Order by Run_ID");
}
$dbc->disconnect();


foreach my $id_dir (@sequences) {
  if (!($id_dir =~ /\S/) || $id_dir eq 'NULL') {
    Report("No Runs selected");
    exit;
  }
  else {
    (my $id, my $Pid, my $ss, my $equip, my $date) = split ',', $id_dir;
    $equip = sprintf "%10s", $equip;
    print "Run $id :\t Plate $Pid\t$equip\t ($date) \t$ss";
    if ($id && $Pid && $equip && $ss) { print "\n"; }
    else { print " ******* ??? Warning ************\n"; }
  }
}

# List run info only
if ($opt_l) { exit }

my $found = scalar(@sequences);
if ($found == 1 && $sequences[0] eq 'NULL') {
  Report("No sequences to update");
  exit;
}
else {
  print "Updating $found runs: *** $nowdate ***\n";
}

# quick security check hack to ensure we are being run as user 'sequence'
my $username = `whoami`;
chomp $username;
unless ($username eq 'sequence') {
  print "\n$username does not have permission to run update command.";
  print "\nPlease 'su sequence' and try again.\n\n";
  exit;
}

print "\n*** Updating commands: ($actions) ***\n";
&Report("Started Update");

my $options;

if ($opt_A) {$options .= " -A $opt_A";}
else {
    print "Without option flag, only providing list...";
    $options .= " -l";
}

if ($opt_F) {$options .= " -F";}
elsif ($opt_f) {$options .= " -f";}

############# Call post_sequence routine.. #################

foreach my $id_dir (@sequences) {
    (my $id) = split ',', $id_dir;
    my $fback = try_system_command("/home/rguin/CVS/SeqDB/cgi-bin/post_sequence.pl $options -S $id -d");
    if ($opt_v) {
	print "\n*******\n$id_dir\n********\n". $fback . "\n********\n";
    }	
}
exit;
sub usage {
  # Usage instructions

print <<END;
update_sequence.pl is run after trace files have been mirrored onto
the file server. It handles things like running Phred, Phrap, updating
the SQL database, generating GIF colour maps, and zipping up data files.

Usage: update_sequence.pl [-A actions] [options]

  Using the -A switch to specify which actions you want to perform.

  By default, it searches for sequence runs with no associated date.
  There are a number of switches that change the sequence runs
  operated on.


Options:

* Operational modes:

  -A  actions to take.

      get    : Gets files from the local sequencing drives
      phred  : Generates Phred Scores and Cross-Match data
      update : Updates the database with parsed data from phred files
      all    : Does all three actions: get,phred,update

* Run selection modifiers:

  -S  sequence_ID list. Performs updates for indicated sequences (or "-S all" for ALL sequences)
      You may also supply imbedded ranges: "-S 1-3,8,10-12" selects 1,2,3,8,10,11,12

  -i  include specific Run IDs (similar functionality to -S)

  -x  exclude specific Run IDs (can be used in combination with other options)

  -M  machine Perform update for new sequences on a specified Machine (mbace1, d3700-2)
               (eg: -M mbace2 or -M d3700-2 )

  -t  date    Perform update for all sequences done on a specified date (-t 2000-09-18)
               (eg: -t 2000-09-25 )

* Operational modifiers:

  -R  reverse plate Orientation due to incorrect positioning of plate

  -f  force analysis even if only 1 quadrant of 384 well plate is done

  -F  force analysis even if less than 1 quadrant is done

  -D  specify database name (normally 'sequence')

* Informative output:

  -h  help. print this help text and then exit

  -v  verbose mode

  -l  list chosen sequences on queue and then exit
     (this dumps Run_ID, Plate_ID, Run_Directory, Machine)


Examples:

  Generally all actions will be performed on new runs using the command:

    update_sequence.pl -A all

 Or to regenerate all sequences:

    update_sequence.pl -A Phred,Update -S all

  To run phred on data sequenced on the 22nd of September, given that
  the trace files have already been transferred to /home/sequence/Projects/:

    update_sequence.pl -A Phred,Update -t 2000-09-22

  To transfer files AND run data on sequence runs 455, 456 and 457 (already mirrored):

    update_sequence.pl -A all -S 455,456,457

END
  return 1;
}
