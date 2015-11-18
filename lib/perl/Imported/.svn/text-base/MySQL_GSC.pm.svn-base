package Imported::MySQL_GSC;

use POSIX qw(strftime);
use Benchmark;
#@@@use Math::VecStat qw(max min maxabs minabs sum average);
use Statistics::Descriptive;
use Data::Dumper;
use Imported::MySQLdb;
use Imported::MySQL_Tools;

my $debug = 0;

################################################################
# Assorted GSC-local tools for MySQL_X modules
#
# CVS: $Revision: 1.2 $
# Date: $Date: 2003/11/27 18:47:44 $
#
################################################################

=pod

=head1 NAME

MySQLdb_GSC - Assorted, generic functions used by the MySQLdb and other MySQL_X modules. These are functions local to the Genome Run Centre and the format of its sequencing database. For MySQL-level functions, see MySQL_Tools.

=head1 DESCRIPTION

This module is not an object, but a collection of functions meant to be used by objects modelling the MySQL database and searches within the Genome Run Centre.

=head1 SYNOPSIS

See USAGE

=cut

=pod

=head1 USAGE

=over

=item GetSequenceDb

GetSequenceDb() connects to the sequence database using the server list in /home/mysql/servers. This file contains servers for the database, in decreasing order of authority. If one server cannot provide a connection, the next one in the file is tried.

=back

=cut

################################################################
# Connects to the sequence database using a read-only
# user.
sub GetSequenceDb {

  # Take the server list from the server file
  #my $serverfile = "/home/mysql/servers";
  #open(SERVFILE,$serverfile) || return undef;
  #my @servers = <SERVFILE>;
  #close SERVFILE;

  my $db = Imported::MySQLdb->new();
  # Try to connect to each of the servers.
  #my $server;
  #For now hardcode to connect to seqdb01 to retrieve latest data. In the future, hard-code will be removed after integrating this suite into the main alDente codebase.
  my $server = 'limsdev01.bcgsc.ca'; 
  #foreach $server (@servers) {
    $db->Connect({'user'=>'viewer','server'=>$server,
		  'pass'=>'viewer','db'=>'sequence'});
    if($db) {
      if(Debug()) {
	print "Connected to $server\n";
      }
      return $db;
    }
  #}
  if(Debug()) {
    print "Could not connect to any server.\n";
  }
  # None of the servers provided us with a connection.
  return undef;

}
################################################################

################################################################
# Narrows down a search in the sequence database through
# the Clone_Sequence table based on filters according to
#   - machine
#   - runid
#   - employee
#   - project
#   - library
#   - test     (values: no, yes (default), only)
#   - quality  (values: no (default), yes)
# The function is passed the search handle and a scope text
# which has the syntax
#
#  "<scope1>:<scopevalue1>,<scope2>:<scopevalue2>,..."
#
# It is a : delimited set of , delimited pairs. <scopeX> can
# take on the values: 
#   - runid, sequencer, employee, project, library
# <scopevalueX> should be the value you wish to search for
#
# This function is a wrapper for AddFK and AddField functions.

sub RefineScope {

  my $search = shift;
  my $scopetext = shift;

  my %scope;
  my $scopepair;
  if(defined $scopetext) {
    foreach $scopepair (split(/,/,$scopetext)) {
      my ($scope,$value) = split(/:/,$scopepair);
      if($scope ne "" && $value ne "") {
	$scope{$scope} = $value;
      }
    }
  }
  my $q_scopefound=0;
  foreach $scope (keys %scope) {
    if($scope =~ /quality/i) {
      $q_scopefound=1;
      if($scope{$scope} =~ /no|0/i) {
	$search->AddViewField({'field'=>'Clone_Sequence.Phred_Histogram','alias'=>'Histogram'});
      } else {
	$search->AddViewField({'field'=>'Clone_Sequence.Quality_Histogram','alias'=>'Histogram'});
      } 
    }
    if($scope =~ /test/i) {
      if($scope{$scope} =~ /no|0/i) {
	$search->AddFK({'field'=>'Run.ID'});
	$search->AddField({'field'=>'Run.Run_Status','regexp'=>"Production",});
      } elsif ($scope{$scope} =~ /only/i) {
	$search->AddFK({'field'=>'Run.ID'});
	$search->AddField({'field'=>'Run.Run_Status','value'=>"Test"});
      }
    }
    if($scope =~ /runid/i) {
      $search->AddFK({'field'=>'Run.ID'});
      $search->AddField({'field'=>'Run.Run_ID','value'=>$scope{$scope}});
      $search->AddViewField({'field'=>'Clone_Sequence.Well'});
      $search->AddViewField({'field'=>'Clone_Sequence.Sequence_Length','alias'=>'Sequence_Length'});  
      $search->Order({'field'=>'Clone_Sequence.Well'});
    }
    if($scope =~ /sequencer/i) {
      $search->AddFK({'field'=>'Run.ID'});
      $search->AddFK({'field'=>'RunBatch.ID','fktable'=>'Run'});
      $search->AddFK({'field'=>'Equipment.ID','fktable'=>'RunBatch'});
      $search->AddField({'field'=>'Equipment.Equipment_Name',
			 'value'=>$scope{$scope}});
    }
    if($scope =~ /employee/i) {
      $search->AddFK({'field'=>'Run.ID'});
      $search->AddFK({'field'=>'RunBatch.ID','fktable'=>'Run'});
      $search->AddFK({'field'=>'Employee.ID','fktable'=>'RunBatch'});
      $search->AddField({'field'=>'Employee.Employee_Name',
			 'value'=>$scope{$scope}});
    }
    if ($scope =~ /project/i) {
      $search->AddFK({'field'=>'Run.ID'});
      $search->AddFK({'field'=>'Plate.ID','fktable'=>'Run'});
      $search->AddFK({'field'=>'Library.Name','fktable'=>'Plate'});
      $search->AddFK({'field'=>'Project.ID','fktable'=>'Library'});
      $search->AddField({'field'=>'Project.Project_Name','value'=>$scope{$scope}});
    }
    if ($scope =~ /library/i) {
      $search->AddFK({'field'=>'Run.ID'});
      $search->AddFK({'field'=>'Plate.ID','fktable'=>'Run'});
      $search->AddFK({'field'=>'Library.Name','fktable'=>'Plate'});
      $search->AddField({'field'=>'Library.Library_Name','value'=>$scope{$scope}});
    }
  }
  # If the quality scope was not specified, assume the default value (use regular histogram)
  if(! $q_scopefound) {
    $search->AddViewField({'field'=>'Clone_Sequence.Phred_Histogram','alias'=>'Histogram'});
  }
}


################################################################
# Extracts phred histograms from the database, based on
# filters passed to this function.
# 
# Returns an array of arrays to the phred lengths of reads
# that were searched for. See bottom of this function for
# the structure of the returned data.
#
sub GetPhredLengths {

  my $self = shift;
  my $hash = shift || "";
  my $dbh = $self;
  my $phreds;
  my $search;
  my $scopetext;

  $self->Imported::MySQL_Tools::ArgAssign({'phreds'=>\$phreds,
				 'scope'=>\$scopetext,
				 'search'=>\$search,
				},$hash);

  #print "Inside getphred lengths ",Now(),"<BR>";
  # Parse the scope field. The there may be many scopes.
  if(defined $search && (ref $search) =~ /mysql_search/i) {
    $search->AddViewField({'field'=>'Clone_Sequence.Phred_Histogram','alias'=>'Histogram'}); 
  } else {
    $search = $dbh->CreateSearch($searchtime.int(rand(100000)));
    $search->SetTable("Clone_Sequence");
    RefineScope($search,$scopetext);
  }
  #print "Refined search",Now(),"<BR>";
  $search->Execute();
#  $search->Print("html");
  #print "Executed search",Now(),"<BR>";
  my $phred;
  my $phredidx;
  my $phred_values;
  while($r = $search->ForEachRecord) {
    $phredbin = $r->GetFieldValue("Histogram");
    my $seq_length = $r->GetFieldValue("Sequence_Length");
    # If the histogram is not of the right length, skip this record.
    #if(length($phredbin) ne 200) {next}
    $phredidx=0;
    foreach $phred (@{$phreds}) {
	if ($seq_length < 0) {
	    push(@{$phred_values->[$phredidx++]},'Fail');	    
	}
	else {
	    push(@{$phred_values->[$phredidx++]},unpack("S",substr($phredbin,2*$phred,2)));
	}
    }
  }

  return $phred_values;
  # The structure of $phred_values above is:
  #
  # $phred_values->[phred_idx]->[record_idx] = phred value
  #
  # where phred_idx enumerates the phred value passed to the function. For example
  # if the 'phred' variable was passed [20,30,40] then 
  #
  #   phred_idx = 0 for phred 20
  #   phred_idx = 1 for phred 30
  #   phred_idx = 2 for phred 40
  #
  # record_idx enumerates all the reads. If the scope criteria isolated 1000 reads
  # then record_idx = 0...999 and
  #
  # $phred_values->[1]->[500] would be the phred 30 length of read 500+1.
}
#
################################################################

################################################################
#
sub GetPhredInfo {

  my $self = shift;
  my $hash = shift || "";
  my $dbh = $self;
  my $phreds;      # Array of phred values to use, e.g. [20,30,35]
  my $scopetext;   # comma-delimited list of search conditions, e.g.
                   #   library:CN001,project=hemoc,sequencer=MB1
                   #
                   # The scope:scopevalue pairs can contain
                   #   <scope>: library, project, sequencer, employee
  my $search;      # we could possibly pass a search over to this 
                   # function which already has all the necessary AddFields
                   # In this case, all we need to do is AddViewFields
  my $testruns;
  my $qualityonly;

  $self->Imported::MySQL_Tools::ArgAssign({'phreds'=>\$phreds,
				 'scope'=>\$scopetext,
				 'search'=>\$search,
				 'testruns'=>\$testruns,
				 'qualityonly'=>\$qualityonly},
				 $hash);

  # Name the search based on the and a random number.
  my $searchtime = strftime "%H%M%S",localtime;
  if(defined $search && (ref $search) =~ /mysql_search/i) {
    $search->AddViewField({'field'=>'Clone_Sequence.Phred_Histogram','alias'=>'Histogram'});
  } else {
    $search = $dbh->CreateSearch($searchtime.int(rand(100000)));
    $search->SetTable("Clone_Sequence");
    RefineScope($search,$scopetext);
  }
  $search->Execute();

  #$search->Print("html");
  if($debug) {
    print "PHREDSEARCH:::: $scopetext ",$search->get_nrecs(),"<BR>";
  }
  # $search->Print("html");
  # Ok now that we have all the records, go through them.

  my $t00 = new Benchmark;

  # The phred values are in the array @{$phreds}
  # We return an array of arrays, each of these arrays is the histogram info
  # for the associated phred value.

  my $phred;
  my $phredidx;
  my $phred_values;
  my $phred_sets = @{$phreds};
  my $records = $search->get_nrecs;
  my $recordidx=0; # Output array index
  my $skipped =0;  # Skipped records
  while($r = $search->ForEachRecord) {
    my $phredbin = $r->GetFieldValue("Histogram");
    if(length($phredbin) ne 200) {
      $skipped++;
      next;
    }
    $phredidx=0;
    foreach $phred (@{$phreds}) {
      my $phredvalue = unpack("S",substr($phredbin,$phred*2,2));
      $phred_values->[$phredidx++]->[$recordidx] = $phredvalue;
    }
    $recordidx++;
  }
  my $t01 = new Benchmark;
  my $benchmark = timestr(timediff($t01,$t00));
  return ($phred_values,$search->get_nrecs,$recordidx,$skipped,$benchmark);
  # The $phred_values data structure is the same structure returned by the 
  # GetPhredLengths function. This function keeps track of the skipped
  # reads (when the histogram is malformed) and reports the benchmark info.				
				
}
#
################################################################

################################################################
# This is a brief version of GetPhredInfo. It calls
# GetPhredInfo and then does some statistics on the 
# data returned.
#
sub GetPhredInfoSummary {

  my $self = shift;
  my $hash = shift || "";
  my $dbh = $self;
  my $phreds;      # Array of phred values to use, e.g. [20,30,35]
  my $scopetext;   # comma-delimited list of search conditions, e.g.
                   #   library:CN001,project=hemoc,sequencer=MB1
  my $testruns;
  my $qualityonly;
  my $search;

  $self->Imported::MySQL_Tools::ArgAssign({'phreds'=>\$phreds,
				 'scope'=>\$scopetext,
				 'testruns'=>\$testruns,
				 'search'=>\$search,
				 'qualityonly'=>\$qualityonly},
				$hash);

  my ($phred_values,$nrecs,$good,$skipped,$bench) = GetPhredInfo($dbh,$hash);

  my $phred;
  my $phredidx=0;
  my $phred_summary;
  foreach $phred (@{$phreds}) {
    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data(@{$phred_values->[$phredidx]});
    my $totalbp=$stat->sum();
    my $modelength=$stat->mode();
    my $avglength=$stat->mean();
    my $medianlength=$stat->median();
    my $varlength=$stat->variance();
    my $reads=@{$phred_values->[$phredidx]};
    $phred_summary->[$phredidx] = {'phred'=>$phred,'reads'=>$reads,'totbp'=>$totalbp,'avglength'=>$avglength,'varlength'=>$varlength,'medianlength'=>$medianlength,'bench'=>$bench,'skipped'=>$skipped,'nrecs'=>$nrecs};
    $phredidx++;
  }
  # returns hash with keys:
  #   phred
  #   reads
  #   totbp
  #   avglength
  #   varlength
  #   medianlength

  return $phred_summary;

}

################################################################
# Fetch the status of a BP in a given read. The possible
# values returned are:
#   quality,vector,outside
# The status 'quality' and 'vector' could be returned as a list,
# since it is possible for a base pair to be both.
#
# For a sequence of L+1 base pairs:
#
# Vector assignment:     
# 
# 0...................................................L
# --vector--^                      ^--vector-----------
#           VL                     VR
#
# Quality assignment:     
# 
# 0...................................................L
#          ^----quality-------^
#          QL                 QR
#
#

sub GetBPStatus {
  
  my $read_summary = shift;
  my $well_idx = shift;
  my $bp_idx = shift;
  my $qt = $read_summary->[$well_idx]->{'qt'};
  my $ql = $read_summary->[$well_idx]->{'ql'};
  my $qr = $read_summary->[$well_idx]->{'qr'};
  my $vt = $read_summary->[$well_idx]->{'vt'};
  my $vl = $read_summary->[$well_idx]->{'vl'};
  my $vr = $read_summary->[$well_idx]->{'vr'};
  my $tot = $read_summary->[$well_idx]->{'length'};
  if($ql < 0) { $ql = 0; }
  if($qr < 0) { $qr = 0; }
#  if($vl < 0) { $vl = 0; }
#  if($vr < 0) { $vr = 0; }
  my @status;
  # Check for quality
  if($bp_idx > $tot) {
    push(@status,"outside");
  } else {
    if($bp_idx >= $ql && $bp_idx <= $qr) {
      push(@status,"quality");
    }
    # BELOW:
    # Bug fix. The vector calculation was not correct. The old code was calculating
    # something like a complement of what was supposed to be shown
    # if ($bp_idx >= $vl && $bp_idx <= $vl+$vt) then vector
    # (26 Oct 2000 MK)
    if($vl > $vr && ! $vr) {
      # All vector
      push(@status,"vector");
    } else {
      # Check for left vector first.
      if($vl > 0 && $bp_idx <= $vl) {
	push(@status,"vector");
      }
      if($vr > 0 && $bp_idx >= $vr) {
	push(@status,"vector");
      }
    }
  }
  return join(",",@status);
}
#
################################################################

sub GetRunSummary {

  my $db = shift;
  $runid = shift;
  $search = $db->CreateSearch("runsummary".int(rand(10000)));
  $search->SetTable("Run");
  $search->AddFK({'field'=>'RunBatch.ID','fktable'=>'Run'});
  $search->AddFK({'field'=>'Equipment.ID','fktable'=>'RunBatch'});
  $search->AddFK({'field'=>'Employee.ID','fktable'=>'RunBatch'});
  $search->AddFK({'field'=>'Plate.ID'});
  $search->AddFK({'field'=>'Library.Name','fktable'=>'Plate'});
  $search->AddFK({'field'=>'Project.ID','fktable'=>'Library'});
  $search->AddField({'field'=>'Run_ID','value'=>$runid});
  $search->Execute();
  my $read_summary;
  while ($r = $search->ForEachRecord) {
    $read_summary->{'runid'} = $runid;
    $read_summary->{'sequencer'} = $r->GetFieldValue("Equipment_Name");
    $read_summary->{'employee'} = $r->GetFieldValue("Employee_Name");
    $read_summary->{'platedate'} = $r->GetFieldValue("Plate_Created");
    $read_summary->{'rundate'} = $r->GetFieldValue("Sequence_DateTime");
    $read_summary->{'library'} = $r->GetFieldValue("Library_Name");
    $read_summary->{'project'} = $r->GetFieldValue("Project_Name");
  }
  return $read_summary;
}

################################################################
# 15 Oct 2000
# Added nogrow and slowgrow flags to the summary
#
sub GetReadSummary {

  my $db = shift;
  $runid = shift;
  $search = $db->CreateSearch("runsummary".int(rand(10000)));
  $search->SetTable("Clone_Sequence");
  $search->AddFK({'field'=>'Run.ID'});
  $search->AddField({'field'=>'Run.Run_ID','value'=>$runid});
  $search->Order({'field'=>'Clone_Sequence.Well'});
  $search->Execute();

  my $read_summary;

  my $r;
  my $record_idx=0;
  while ($r = $search->ForEachRecord) {
    $read_summary->[$record_idx]->{'runid'} = $runid;
    $read_summary->[$record_idx]->{'well'} = $r->GetFieldValue("Well");
    $read_summary->[$record_idx]->{'length'} = $r->GetFieldValue("Sequence_Length");
    $read_summary->[$record_idx]->{'sequence'} = $r->GetFieldValue("Run");
    $read_summary->[$record_idx]->{'ql'} = $r->GetFieldValue("Quality_Left");
    $read_summary->[$record_idx]->{'qt'} = $r->GetFieldValue("Quality_Length");
    $read_summary->[$record_idx]->{'qr'} = $r->GetFieldValue("Quality_Left") +
	$r->GetFieldValue("Quality_Length") - 1;
    $read_summary->[$record_idx]->{'vl'} = $r->GetFieldValue("Vector_Left");
    $read_summary->[$record_idx]->{'vr'} = $r->GetFieldValue("Vector_Right");
    $read_summary->[$record_idx]->{'vt'} = $r->GetFieldValue("Vector_Total");
    $read_summary->[$record_idx]->{'comment'} = $r->GetFieldValue("Clone_Sequence_Comments");
    $read_summary->[$record_idx]->{'growth'} = $r->GetFieldValue("Growth");
    $read_summary->[$record_idx]->{'capillary'} = $r->GetFieldValue("Capillary");
    $record_idx++;

  }
  return $read_summary;
}
#
################################################################

sub GetScores {

  my $db = shift;
  my $runid = shift;
  my $well  = shift;
  if($runid =~ /[A-Za-z]/) {
    ($runid,$well) = ($well,$runid);
  }
  $search = $db->CreateSearch("run$runid$well");
  $search->SetTable("Clone_Sequence");
  $search->AddFK({'field'=>'Run.ID'});
  $search->AddField({'field'=>'Run.Run_ID','value'=>$runid});
  $search->AddField({'field'=>'Well','value'=>$well});
  $search->AddViewField({'field'=>'Clone_Sequence.Sequence_Scores'});
  $search->Execute();
  if($search->get_nrecs) {
    my $scores  = $search->GetRecord(0)->GetFieldValue("Sequence_Scores");
    my @scores  =  unpack("C*",$scores);
    return @scores;
  } else {
    return ();
  }

}

sub GetSequenceText {

  my $db = shift;
  my $runid = shift;
  my $well  = shift;
  if($runid =~ /[A-Za-z]/) {
    ($runid,$well) = ($well,$runid);
  }
  $search = $db->CreateSearch("sequence".int(rand(10000)));
  $search->SetTable("Clone_Sequence");
  $search->AddFK({'field'=>'Run.ID'});
  $search->AddField({'field'=>'Run.Run_ID','value'=>$runid});
  $search->AddField({'field'=>'Well','value'=>$well});
  $search->Execute();
  if($search->get_nrecs) {
    return $search->GetRecord(0)->GetFieldValue("Run");
  } else {
    return "";
  }
}



sub GetDistinctEmployees {

  my $dbh = GetSequenceDb;
  my $search = $dbh->CreateSearch("distinct");
  $search->SetTable("RunBatch");
  $search->AddFK({"field"=>"Employee.ID"});
  $search->AddViewField({"field"=>"Employee.Employee_Name","function"=>"distinct","alias"=>"value"});
  $search->Execute();  
  my @list = FetchValues($search,"value");
  return @list;

}
sub GetDistinctChemistries {
  my $dbh = GetSequenceDb;
  my $search = $dbh->CreateSearch("distinct");
  $search->SetTable("Run");
  $search->AddViewField({"field"=>"FK_Chemistry_Code__Name","function"=>"distinct","alias"=>"value"});
  $search->Execute();  
  my @list = FetchValues($search,"value");
  return @list;
}
sub GetDistinctProjects {
  my $dbh = GetSequenceDb;
  my $search = $dbh->CreateSearch("distinct");
  $search->SetTable("Run");
  $search->AddFK({"field"=>"Plate.ID"});
  $search->AddFK({"field"=>"Library.Name","fktable"=>"Plate"});
  $search->AddFK({"field"=>"Project.ID","fktable"=>"Library"});
  $search->AddViewField({"field"=>"Project.Project_Name","function"=>"distinct","alias"=>"value"});
  $search->Execute();  
  my @list = FetchValues($search,"value");
  return @list;
}

sub GetDistinctLibraries {
  my $dbh = GetSequenceDb;
  my $search = $dbh->CreateSearch("distinct");
  $search->SetTable("Run");
  $search->AddFK({"field"=>"Plate.ID"});
  $search->AddViewField({"field"=>"Plate.FK_Library__Name","function"=>"distinct","alias"=>"value"});
  $search->Execute();  
  my @list = FetchValues($search,"value");
  return @list;
}

sub GetDistinctLibraryLabels {
  my $dbh = GetSequenceDb;
  my $search = $dbh->CreateSearch("distinct");
  $search->SetTable("Library");
  $search->AddViewField({"field"=>"Library_Name","alias"=>"Name"});
  $search->AddViewField({"field"=>"Library_FullName","alias"=>"LSN"});
  $search->Execute();
  my @list = FetchValues($search, "Name");
  my @list2 = FetchValues($search,"LSN");
  my %hash;
  my $i = 0;
  foreach (@list) {
    $hash{$list[$i]} = $list[$i] . " : " . $list2[$i];
    $i++;
  }
  return %hash;
}

sub FetchValues {

  my $search    = shift;
  my $fieldname  = shift;

  my @values;
  my $rec;
  while($rec = $search->ForEachRecord) {
    push(@values,$rec->GetFieldValue($fieldname));
  }
  return @values;
}

=pod

=over

=item Debug

Accessor and modifier of the internal debug flag. This function is used to set or clear the debug flag and upon exiting, returns the debug flag.

e.g. 
$debug = Imported::MySQL_GSC->Debug(1); 

Imported::MySQL_GSC->Debug(0);

$debug = Imported::MySQL_GSC->Debug;

The debug flag is used to force the module to output significant messages during execution.

=back

=cut


sub Debug {

  my $flag = shift;
  if(defined $flag) {
    $Imported::MySQL_GSC::debug = $flag;
  }
  return $Imported::MySQL_GSC::debug;
}

################################################################
# Stop-watch
{
  my $prevtime;
  sub Now {
    my $delta;
    my $now = strftime "%s",localtime;
    if(defined $prevtime) {
      $delta = $now - $prevtime;
    } else {
      $delta = 0;
    }
    if(! defined $delta || $delta < 0 ) {$delta = 0}
    $prevtime = $now;
    my $timestring = strftime "%M:%S",localtime;
    return "$timestring ($delta)";
  }
}

1;
