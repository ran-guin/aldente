################################################################################
#
# Seq_Data.pm
#
# This provides data from the Sequencing Database on Runs and extracted sequences
#
################################################################################
#
# Perl Module:  Seq_Data (containing database information retrieval routines)
###############################################################################
#
#  Routines will gradually be built up for this module to facilitate common
#  interfacing functions with the database by external programs.
#
#############
#
#  Note:
##########
#
#  All of these methods require passing of a database handle which is 
#  initialized with the command... 
#
#
#############
#  Methods: #
#############
#  
#  %seq = get_library_sequences($dbc,$library,$fastafile,$Options)
#  %seq = get_run_sequences($dbc,$library,$fastafile,$Options)
#  
#  - returns indexed quality sequences from an entire library (or from a sequence run)
#   eg. after running: ... $seq{CN0011a_B05}='gcaat...'
#  - the third parameter is optional and allows dumping to a fasta format file
#  - the fourth parameter is optional and provides a hash reference to various options
#
#  $passed = library_phred_passes($dbc,$library,$threshold)
#  $passed = sequence_phred_passes($dbc,$sequence,$threshold)
#
#  - returns the total number of sequenced basepairs for an entire library 
#    (or for a specified sequence run)
#    with a 'quality' value above a specified threshold (default = 20)
#
###############################################################################
#
#  Note:  an example of how to use the functions in this module is in Seq_Data_test.pl
#
###########################################################################
################################################################################
# $Id: Seq_Data.pm,v 1.22 2004/11/16 22:25:44 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.22 $
#     CVS Date: $Date: 2004/11/16 22:25:44 $
################################################################################
package Sequencing::Seq_Data;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Seq_Data.pm - This provides data from the Sequencing Database on Runs and extracted sequences

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This provides data from the Sequencing Database on Runs and extracted sequences<BR>Perl Module:  Seq_Data (containing database information retrieval routines)<BR>Routines will gradually be built up for this module to facilitate common<BR>interfacing functions with the database by external programs.<BR>Note:<BR>All of these methods require passing of a database handle which is <BR>initialized with the command... <BR>$dbc = DB_Connect(dbase=>$dbase);<BR>(where $dbase = 'sequence' normally)<BR>This method is in the DBIO.pm module.<BR>Methods: #<BR>%seq = get_library_sequences($dbc,$library,$fastafile,$Options)<BR>%seq = get_run_sequences($dbc,$library,$fastafile,$Options)<BR>- returns indexed quality sequences from an entire library (or from a sequence run)<BR>eg. after running: ... $seq{CN0011a_B05}='gcaat...'<BR>- the third parameter is optional and allows dumping to a fasta format file<BR>- the fourth parameter is optional and provides a hash reference to various options<BR>$passed = library_phred_passes($dbc,$library,$threshold)<BR>$passed = sequence_phred_passes($dbc,$sequence,$threshold)<BR>- returns the total number of sequenced basepairs for an entire library <BR>(or for a specified sequence run)<BR>with a 'quality' value above a specified threshold (default = 20)<BR>Note:  an example of how to use the functions in this module is in Seq_Data_test.pl<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
	     get_library_sequences
	     get_run_sequences
	     library_phred_passes
	     sequence_phred_passes
	     threshold_phred_scores
	     get_good_sequence
	     get_sequences
	     fix_output
);
@EXPORT_OK = qw(
	     get_library_sequences
	     get_run_sequences
	     library_phred_passes
	     sequence_phred_passes
	     threshold_phred_scores
	     get_good_sequence
	     get_sequences
	     fix_output
	     );

##############################
# standard_modules_ref       #
##############################

use CGI qw(standard);
use DBI;
#use Storable;
use File::stat;
use Statistics::Descriptive;
use Data::Dumper;
use strict;

##############################
# custom_modules_ref         #
##############################
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use alDente::Validation;
use alDente::Container;
use RGTools::RGIO;  

##############################
# global_vars                #
##############################
use vars qw($testing);
use vars qw( $project_dir $Connection);

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
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
sub get_library_sequences {
##############################
#
# Returns indexed quality portions of sequence for entire library.
#  (all_runs flag indicates that Test runs should be included)
#
# (returns "" if Quality Right = 0)
#
#
    my $dbc = shift || $Connection || $Connection;
    my $library = shift;
    my $filename = shift;
    my $Options = shift;   ### (see Options in 'get_sequences')
    my $custom_header = shift;

    my $chemcode = $Options->{chemcode} || 0;

    if ($chemcode) {$chemcode = "%.$chemcode";}
    else {$chemcode = "";}

    my ($ret1,$ret2) = get_sequences($dbc,"where Library like \"$library$chemcode%\"",$Options);

    my %sequences = %$ret1;
    my %tags = %$ret2;

    if ($filename=~/\S/) {   
	my $SEQFILE;
	open(SEQFILE,">$filename") or print "Error opening $SEQFILE ($filename)";
	my $count = 0;
	foreach my $thiskey (sort keys %sequences) {
	    if ($thiskey=~/^Clone:/) {next;}
	    my $output = $sequences{$thiskey};
	    my $length = length($output);
	    if ($thiskey=~/[a-zA-Z0-9]+/) {
		my $clone = $sequences{"Clone:$thiskey"};

		######### adjust output based on Options ... #########
		($output,$clone) = &fix_output($output,$clone,$Options);
		print "-> $thiskey\n";
		my $header = ">$thiskey - $clone\n";
		if ($custom_header) {
		    ($header = $custom_header) =~ s/(<<[A-Z]+>>)/$tags{$thiskey}{$1}/g; 
		    $header .= "\n";
		}
		print SEQFILE $header;
		if ($output=~/\S+/) {print SEQFILE "$output\n";}
		$count++;
	    }
	}
	
	print "Wrote ($count reads) to $filename\n";
	close(SEQFILE) or print "Error closing $SEQFILE";
    }

    return %sequences
}

############################
sub get_run_sequences {
############################
#
    # Returns indexed quality portions of sequence for specified sequence runs.
    # (sequence runs can be listed in comma-separated format without spaces)
    #
    # (returns "" if Quality Right = 0)

    my $dbc = shift || $Connection || $Connection;
    my $run = shift;
    my $filename = shift;
    my $Options = shift;  ### (see Options in 'get_sequences')
    my $custom_header = shift;
    
    my $quiet = $Options->{quiet};

    my ($ret1,$ret2) = get_sequences($dbc,"WHERE Run_ID in ($run)",$Options);

    unless ($ret1 && $ret2) { print "No sequence data returned\n"; return {}; }
    my %sequences = %$ret1;
    my %tags = %$ret2;

    print "Looking for run $run<BR>\n" unless $quiet;
    my $count = 0;
    if ($filename=~/\S/) {
	my  $SEQFILE;
	open(SEQFILE,">$filename") or print "Error opening $filename.";
	foreach my $thiskey (sort keys %sequences) {
	    if ($thiskey=~/Clone:/) {next;}
	    my $output = $sequences{$thiskey};
	    if ($thiskey=~/[a-zA-Z0-9]+/) {
		my $clone = $sequences{"Clone:$thiskey"};
		
		######### adjust output based on Options ... #########
		($output,$clone) = &fix_output($output,$clone,$Options);
		print "--> $thiskey\n" unless $quiet;
		my $header = ">$thiskey - $clone\n";
		if ($custom_header) {
		    print "(customized)..";
		    ($header = $custom_header) =~ s/(<<[A-Z]+>>)/$tags{$thiskey}{$1}/g; 
		    $header .= "\n";
		}
		print SEQFILE $header;
		if ($output=~/\S+/) {print SEQFILE "$output\n";}
		$count++;
	    }
	}
	print "Wrote ($count reads) to $filename<BR>\n";
	close SEQFILE or print "Error closing $SEQFILE";
    }

    return %sequences
}

sub library_phred_passes {
######################################################################
# eg library_phred_passes($dbc,$library,$threshold)
#######################################################################
    my $dbc = shift || $Connection || $Connection;
    my $library = shift;
    my $threshold = shift;

    $threshold ||= 20; # default

    my $passes = threshold_phred_scores($dbc,$threshold,"Run_Directory like \"$library%\"");
    
    return $passes;
}

############################
sub sequence_phred_passes {
############################
    my $dbc = shift || $Connection || $Connection;
    my $sequence_id = shift;
    my $threshold = shift;

    $threshold ||= 20; # default

    if ($sequence_id=~/^[A-Z]{2}\w{3}\d+/) {
	$sequence_id=Table_find($dbc,'Run','Run_ID',"where Run_Directory like \"$sequence_id\""); 
    }	
    my $passes = threshold_phred_scores($dbc,$threshold,"Run_ID in ($sequence_id)");

    return $passes;
}

#######################

#######################################
#  general routines to extract data...
#######################################
sub threshold_phred_scores {
################################
#
# This routine looks at all phred scores given a search condition
#  and a threshold phred quality.
#  (search condition can use anything from Run or Clone_Sequence Table)
# 
# It returns an array of values, each one containing (tab-delimited)
#  the length of the sequence, the number of pairs that passed the threshold test, 
#  and the number of pairs that failed.
#
# eg. to check phred scores of better than 20 for sequence run #45
#  @results = threshold_phred_scores($dbc,20,"where Run_ID=45");
#
# (for library specification use format: 'where Library like "CC001%') 
#
#  each result may contain something like:  "894 \t 653 \t 241"; 
#  indicating that the sequence length was 894 with 653 scores > 20
#
######################################################################
#
#
# eg threshold_phred_scores($dbc,$threshold,$condition)
#
#######################################################################

    my $dbc = shift || $Connection || $Connection;          ### database handle
    my $threshold = shift;    ### threshold for 'pass' phred scores
    my $condition = shift || 1;    ### condition for runs to retrieve (from Clone_Sequence,Run table)
#    $condition=~s/ Library/ Run_Directory/ig;

    my @all_results;

    my @scores = Table_find($dbc,'Clone_Sequence,Run','Sequence_Scores',
			    "WHERE $condition AND FK_Run__ID=Run_ID");

    my $total_passed;
    my $total_failed;
    my $total_tested;
    foreach my $score (@scores) {
	my $remaining = $score;
	my $how_many;
	my $failed;
	my $passed;

	while ($remaining) {
	    my $single_score = substr($remaining, 0, 2);
	    $remaining = substr ($remaining, 2);
	    if ($single_score > $threshold) {
		$passed++;
	    }
	    else {
		$failed++;
	    }
	    $how_many++;
	}
	
	$total_passed += $passed;
	$total_failed += $failed;
	$total_tested += $how_many;
	my $results = "$passed\t$failed\t$how_many";
	push(@all_results,$results);
    }
    return $total_passed;
}

########################
sub get_good_sequence {
########################
    my $dbc = shift || $Connection;     ### database handle
    my $Options = shift; ### Options - see get_sequence (quality_file, column_width)
    my $id = shift;      ### run id
    my $well = shift;    ### well 
    my $cut_left = shift || 0;    ### left cut index in sequence
    my $cut_length = shift;       ### length of extracted sequence
    my $threshold = shift || 0;   ### threshold for substituting bp with 'n'

    (my $scores) = Table_find($dbc,'Clone_Sequence','Sequence_Scores',"where FK_Run__ID=$id and Well = '$well'");
    (my $sequence) = Table_find_array($dbc,'Clone_Sequence',['Sequence'],"where FK_Run__ID=$id and Well = '$well'");

    $cut_length ||= length($sequence);

#    my $extract = substr($scores,$cut_left,$cut_length);
    my @phred_scores = unpack "C*", $scores;

    my $index = 0;

    if ($Options->{quality_file}) {  ### return quality scores in place of nucleotide
	my $score_string = '';
	my $index=0;
	my $printed = 0;
	foreach my $score (@phred_scores) {
	    if ($index < $cut_left) {$index++; next;}
	    elsif ($index >= ($cut_length + $cut_left)) {$index++; next;}
#	    print "$index..";
	    
	    if ($score < 10) {
		$score_string .= " 0$score";
	    }
	    elsif ($score=~/\d/) {
		$score_string .= " $score";
	    }
	    else {
		$score_string .= " 00";
	    }
	 
	    $printed++;
	    if ($Options->{column_width}) {
		if ($printed >= $Options->{column_width}) {
		    $score_string .= "\n";
		    $printed = 0;  ## reset column index..
		}
		
	    }
	    $index++;
	}
	return $score_string;
    }

    foreach my $score (@phred_scores) {
	my $bp = substr($sequence,$index,1);
	if ($score<$threshold) {
	    substr($sequence,$index,1) = 'n';
	}
	elsif ($score >= 20) {
	    substr($sequence,$index,1) = uc($bp);
	} 
	$index++;
    }	    
   
    my $sequence_string = substr($sequence,$cut_left,$cut_length);
    if ($Options->{column_width}) {
	my $columnated_string = '';
	my $start = 0;
	while (length($sequence_string) > $start) {
	    $columnated_string .= substr($sequence_string,$start,$Options->{column_width}) . "\n";
	    $start += $Options->{column_width};
	}
	if ($columnated_string) {chop $columnated_string;}
	$sequence_string = $columnated_string;
    }
    return $sequence_string;
}

#######################
sub get_sequences {
#######################
#
# This is called by:
#
#    get_run_sequences
#    get_library_sequences
#
#  to retrieve indexed sequence information
#
# (Returns hash with all Clone info (eg. $returnval{'CN0011a.BA'} = 'gtagtagta...')
# AND Comments in form: $returnval{Clone:CN0011a.BA} = "CN0011a.Ba.BA (132) Note: Recurring String"
# where Comments is typically used for fasta file header. 
#
    my $dbc = shift || $Connection;           ### database handle
    my $condition = shift;     ### condition string (using Run,Clone_Sequence Tables)
    my $Options = shift;       ### containing various options below... 

    my $all = $Options->{all} || 0;      ### include test runs
    my $approved = $Options->{approved} || 0;      ### include ONLY approved runs
    my $billable = $Options->{billable} || 0;      ### include ONLY approved runs
    my $qtrim = $Options->{qtrim};       ### trim for quality (1=choose by trimmed length)
    my $vtrim = $Options->{vtrim};       ### trim for vector (2=choose by total length)
    my $notrim = $Options->{notrim};     ### no trimming...
    my $source = $Options->{source} || 0; ### use source name rather than internal name in header
    my $info = $Options->{info} || 0;     ### specify threshold for 
    my $N_threshold = $Options->{N_threshold} || 0;  ### set all basepairs below N_threshold to 'N'
    my $Q_file = $Options->{quality_file} || 0;      ### generate Quality output (instead of base pairs)
    my $exclusion_file = $Options->{exclude};        ### exclude runs (specified in this file)
    my $inclusion_file = $Options->{include};        ### include only runs specified in this file
    my $exclude_noted_runs = $Options->{best_only} || 0;  ### exclude any runs with Read_Warnings or Read_Errors
    my $quiet = $Options->{quiet} || 0;
    my $include_NG = $Options->{include_NG} || 0;
    my $minimum_Q20 = $Options->{minimum_Q20};
    my $minimum_QL = $Options->{minimum_QL};
    my $minimum_QT = $Options->{minimum_QT};
    
    ## put options chosen together into one hash for logging purposes
    my %Choose;
    foreach my $option (keys %{$Options}) {
	if ($Options->{$option}) { $Choose{$option} = $Options->{$option} }
    }
    &log_usage(-log=>"$Data_log_directory/fasta/fasta_usage.log",-object=>\%Choose);
    
### Only used by external routines ###
#
#     $Options->{upper} || 0;     ### generate all upper case output (defaults to mixed (upper > phred20)
#     $Options->{lower} || 0;     ### generate all lower case output (defaults to mixed (upper > phred20)
#     $Options->{column_width} || 0;     ### if specified, generate output in columns this wide
#     $Options->{Clip_Poly_T} || 0;     ### if specified, clip poly_T tails where found... 
#    

    my $order;
    my $contaminated = 0;
    my $skipped      = 0;

    my %Ifiles;
    if ($inclusion_file) {
	open(FILE,"$inclusion_file") or die "could not find $inclusion_file";
	while (<FILE>) {
	    chomp;
	    $Ifiles{$_} = 1;
	}
	close(FILE) or print "could not CLOSE $inclusion_file";
	print "Including clones: \n";
	foreach my $key (keys %Ifiles) {
	    print "$key\n";
	}
    }
    my %Xfiles;
    if ($exclusion_file) {
	open(FILE,"$exclusion_file") or die "could not find $exclusion_file";
	while (<FILE>) {
	    chomp;
	    $Xfiles{$_} = 1;
	}
	close(FILE) or print "could not CLOSE $exclusion_file";
	print "Excluding clones: \n";
	foreach my $key (keys %Xfiles) {
	    print "$key\n";
	}
    }

    if ($vtrim == 1) {print "Trimming Vector (maximize length of quality region)<BR>\n" unless $quiet}
    elsif ($vtrim == 2) {print "Trimming Vector (maximize total length extracted)<BR>\n" unless $quiet}
    if ($qtrim) {print "Trimming poor Quality (maximize length of quality region)<BR>\n" unless $quiet}

    if (!$vtrim && !$qtrim) {print "Nothing trimmed from Run<BR>\n" unless $quiet}
    if ($all) {print "(Including Test,Development Runs)<BR>\n" unless $quiet}
    if ($approved) {print "(Including only approved Runs)<BR>\n" unless $quiet}
    if ($billable) {print "(Including only Billable Runs)<BR>\n" unless $quiet}
    else {print "(Excluding Test,Development Runs)<BR>\n" unless $quiet}
    
    if ($exclude_noted_runs) { print "(Excluding any runs with Read Warnings/Errors)" unless $quiet }
    if ($Q_file) {print "Replacing nucleotide sequences with Quality scores<BR>\n" unless $quiet}

    $condition=~s/ Run_ID/ Run.Run_ID/g;
    $condition=~s/ Library/ Run_Directory/ig;
    ## Base condition : join condition + ALWAYS exclude Failed / Aborted runs ##
    $condition .= " AND Run_ID=Clone_Sequence.FK_Run__ID AND Clone_Sequence.FK_Sample__ID=Sample_ID AND Run_Status = 'Analyzed'";
    if (!$all) {$condition .= " AND Run_Test_Status like '%Production%'";}               ## only production runs unless 'all' chosen
    if ($approved) { $condition .= " AND Run_Validation='Approved'"; }              ## only approved runs
    if ($billable) { $condition .= " AND Billable='Yes'"; }                         ## only billable runs
    if ($exclude_noted_runs) { $condition .= " AND Read_Warning = '' AND Read_Error = ''"; }
    unless ($include_NG) {$condition .= "AND Growth IN ('OK','Slow Grow') "; }

    $order .= " Order by Clone_Sequence.Well,Run_Directory";
    
    my $table_list = 'Clone_Sequence,Run,Sample';
    my @data_list = ('Run_Directory','Clone_Sequence.Well as Well','Sequence','Quality_Left','Quality_Length','Vector_Left','Vector_Right','Read_Warning','Read_Error','Run_ID','FK_Plate__ID','Sequence_Length','Clone_Sequence_Comments','Sample_ID','Sample_Name',&Sequencing::Tools::SQL_phred(20) ." as Q20",'Vector_Quality');
   
    my %run_info = Table_retrieve($dbc,$table_list,\@data_list,"$condition $order");
    unless ($run_info{Run_ID}) { print "No data found : (try using -A to include test data ?\n"; return (); }

    my $found = int(@{$run_info{Run_ID}});
    print "Found $found sequences<BR>\n" unless $quiet;

    my $save_length;
    my %sequences;
    my %tags;
    my %scores;
    my %slength;
    my %clones;
#    my %index=0;

    ######## make well lookup table...
    my $Well = {};
    my $PlateSourceName = {};
    my $PlateSource = {};

    if ($source) {
	for my $quad ('a'..'d') {
	    for my $row ('A'..'H') {
		for my $col (1..12) {
		    if ($col<10) {$col='0'.$col;}
		    (my $newname) = Table_find($dbc,'Well_Lookup','Plate_384',"where Plate_96 like '$row$col' and Quadrant='$quad'");
		    if ($newname=~/^(\w)(\d)$/) {$newname = uc($1)."0".$2;}
		    else {$newname = uc($newname);}
		    $Well->{"$row$col"}->{$quad} = $newname;
#		    print "$row$col -> $newname..";
		}
	    }
	}
	
	print "mapping plates onto original Source names...\n";
	my $index = 0;
	while (defined $run_info{Run_ID}[$index]) {
	    my $plate = $run_info{FK_Plate__ID}[$index];
	    my $well = $run_info{Well}[$index];
	    my $sample_id = $run_info{Sample_ID}[$index];
	    my $sample_name = $run_info{Sample_Name}[$index];
	    $index++;

	    my %alias = &Table_retrieve($dbc,"Clone_Source,Clone_Sample LEFT JOIN Sample_Alias ON Sample_Alias.FK_Sample__ID=Clone_Sample.FK_Sample__ID AND Source = '$source' LEFT JOIN Organization on Clone_Source.FKSource_Organization__ID=Organization_ID",['Source_Name','Organization_Name','Source','Alias'],"WHERE Clone_Source.FK_Clone_Sample__ID=Clone_Sample_ID AND Clone_Sample.FK_Sample__ID=$sample_id ");
	    my ($source_org,$name);
	    if ($alias{Alias}[0]) {
		$name = $alias{Alias}[0];
		$source_org = $alias{Source}[0];
	    } elsif ($alias{Source_Name}[0]) {
		$name = $alias{Source_Name}[0];
		$source_org = $alias{Organization_Name}[0];
	    } else {
		$name = "$sample_name";
		$source_org = "GSC";
	    }

	    $PlateSourceName->{"$plate$well"} = $name;
	    $PlateSource->{"$plate$well"}     = $source_org;
	}
    } 
	
    my $similar = 0;
    my $index = 0;
    while (defined $run_info{Run_ID}[$index]) {
	my $ssdir = $run_info{Run_Directory}[$index];
	my $well = $run_info{Well}[$index];
	my $seq = $run_info{Sequence}[$index];
	my $qleft = $run_info{Quality_Left}[$index];
	my $qlength = $run_info{Quality_Length}[$index];
	my $vl = $run_info{Vector_Left}[$index];
	my $vr = $run_info{Vector_Right}[$index];
	my $vq = $run_info{Vector_Quality}[$index];
	my $warning = $run_info{Read_Warning}[$index];
	my $error = $run_info{Read_Error}[$index];
	my $run_id = $run_info{Run_ID}[$index];
	my $plate = $run_info{FK_Plate__ID}[$index];
	my $slength = $run_info{Sequence_Length}[$index];
	my $comment = $run_info{Clone_Sequence_Comments}[$index];
	my $sample_name = $run_info{Sample_Name}[$index];
	my $Q20 = $run_info{Q20}[$index];

	my $trimmed_length = $qlength - $vq;        ## trimmed length excluding vector ..
	$index++;

#	(my $ssdir,my $well,my $seq,my $qleft,my $qlength,my $vl,my $vr,my $warning,my $error,my $run_id,my $plate,my $slength, my $comment) = split ',',$run;
	
	if ($Options->{ecoli}) {
	    my $threshold = 1/(10 ** $Options->{ecoli});
	    if ( $comment=~/\(P=(\d+)\)/ ) {  ### contamination comment format 
		my $P_value = $1;
		if ($P_value < $threshold) {
		    print "Run$run_id $ssdir $well ($comment)\n";
		    $contaminated++;
		    next;
		}
	    }
	} 
	if ($minimum_Q20 && $Q20 < $minimum_Q20) {
	    print "Run$run_id $ssdir $well EXCLUDED ($Q20 < $minimum_Q20 cutoff for Q20)\n";
	    $skipped++;
	    next;
	} elsif ($minimum_QL && $qlength < $minimum_QL) {
	    print "Run$run_id $ssdir $well EXCLUDED ($qlength < $minimum_QL cutoff for Quality region)\n";
	    $skipped++;
	    next;
	} elsif ($minimum_QT && $trimmed_length < $minimum_QT) {
	    print "Run$run_id $ssdir $well EXCLUDED ($trimmed_length < $minimum_QT cutoff for Trimmed Quality region)\n";
	    $skipped++;
	    next;
	}
	
	my $note = '';
	if (($warning ne 'NULL') && $warning) { $note .= "Warning: $warning;"; print "Warning ($run_id:$well) (trimmed: $trimmed_length) $warning.\n" unless $quiet; }
	if (($error ne 'NULL') && $error) { $note .= "Error: $error;"; print "Error ($run_id:$well) $error.\n" unless $quiet; }
	
	if ($info) {
	    my $lib_name = substr ($ssdir,0,5);
	    (my $proj_dir) = Table_find($dbc,'Project,Library','Project_Path',"where FK_Project__ID=Project_ID and Library_Name = '$lib_name'");
	    my $lib_dir = "$project_dir/$proj_dir/$lib_name";
	    my $trace = "(Trace: $lib_dir/AnalyzedData/$ssdir/chromat_dir/$lib_name*$well*)";
	    $note = "RunID:$run_id $trace $note";
	}
	
	my $qright = $qleft + $qlength -1;
	## if "include low quality sequence is chosen"... ##

#	my $clone;
#	if ($ssdir =~ /^([a-zA-Z0-9]{5})(\d+)([a-zA-Z]?)/) {
#	    $clone = $1.$2.$3."_".$well;
#	    if ($Options->{include_redundancies}) {$clone = "$ssdir:$well";}  
#	}	
#	else {$clone = ""; print "\nStrange Clone name ($ssdir)";}
#	
#	my $prenote;
#	if ($source) {
    my $clone = $PlateSourceName->{"$plate$well"} || $sample_name;
    my $prenote = $PlateSource->{"$plate$well"} || 'GSC';

	if ($Options->{include_redundancies}) {$clone .= " $ssdir:$well"; }
	
#            # ($dbc,$plate,$source,$well,$Well);
#	}
	
#######  Determine if clone name is mentioned in include/exclude files .. #########
	my $skip = 0;
	if ($inclusion_file) {
	    unless ($Ifiles{$clone}) {$skip=1;}
	    else {print "Include $clone..\n";} 
	}
	elsif ($exclusion_file) {
	    if ($Xfiles{$clone}) {print "Exclude $clone..\n"; $skip=1;}
	    elsif ($Xfiles{$sample_name}) {print "Exclude $clone..\n"; $skip=1;}
	    elsif ($Xfiles{$run_id}) { print "Exclude Run $run_id"; }
	}
	if ($skip) {next;}
######

	my $ql = $qleft;
	my $qr = $qright;

	if ($vtrim) {   ## trim for vector 
	    if ($vl>=0 && $ql<=$vl) {$ql = $vl+1;}
	    if ($vr>=0 && $qr>=$vr) {$qr = $vr-1;}
	}
	my $length = $qr - $ql + 1;

	my $cut_right = $qr;  #### save separate indexes for cutting sequence out
	my $cut_left = $ql; 
	unless ($qtrim) {
	    $cut_left=0; 
	    $cut_right=length($seq) -1;
	
	    if ($vtrim) {   
		if ($vl>=0) {$cut_left=$vl+1;}
		if ($vr>=0) {$cut_right=$vr-1;}
	    }
	}
	my $cut_length = $cut_right - $cut_left +1;
	if ($cut_length<0) {$cut_length = 0;}

	if (($vtrim == 2) || ($notrim == 2)) {  ### if ordering by whole sequence...
	    $length=$cut_length;
	}
	else {                       ### if ordering by quality region...
	    if ($qr<0) {$length=0;}
	}
#	$sequences->[$index]->[0]=$clone;
	if ($sequences{$clone}) {
	    if ($slength{$clone} && ($length > $slength{$clone})) {
		$save_length=$length;
		if ($cut_length>0) {
		    $sequences{$clone} = get_good_sequence($dbc,$Options,$run_id,$well,$cut_left,$cut_length,$N_threshold);
		}
		else {$sequences{$clone} = "";} 
		$slength{$clone} = $length;
		$sequences{"Clone:$clone"} = "$prenote $ssdir $well ($cut_length) $note";
		$tags{"$clone"}{"<<PRENOTE>>"} = $prenote;
		$tags{"$clone"}{"<<SSDIR>>"} = $ssdir;
		$tags{"$clone"}{"<<WELL>>"} = $well;
		$tags{"$clone"}{"<<LENGTH>>"} = $cut_length;
		$tags{"$clone"}{"<<NOTE>>"} = $note;

		$similar++;
	    }
	}
	else {
	    if ($cut_length > 0) {
		$sequences{$clone} = get_good_sequence($dbc,$Options,$run_id,$well,$cut_left,$cut_length,$N_threshold);
	    }
	    else {$sequences{$clone} = "";}

	    $slength{$clone} = $length;
	    $sequences{"Clone:$clone"} =  "$prenote $ssdir $well ($cut_length) $note";
	    $tags{"$clone"}{"<<PRENOTE>>"} = $prenote;
	    $tags{"$clone"}{"<<SSDIR>>"} = $ssdir;
	    $tags{"$clone"}{"<<WELL>>"} = $well;
	    $tags{"$clone"}{"<<LENGTH>>"} = $cut_length;
	    $tags{"$clone"}{"<<NOTE>>"} = $note;
#		print $sequences{"Clone:$clone"}."\n";

	    $similar = 0;
	}
#	$index++;
#	print "\n$clone: ".$sequences{$clone} . $sequences{"Clone:$clone"};
    }
    my $unique = int(keys %sequences)/2;

    print "($unique Unique)\n" unless $quiet;
    if ( $Options->{ecoli} ) { print "($contaminated Contaminated with e-coli)\n"; }
    return (\%sequences,\%tags);
}

###################
sub fix_output {
###################
#
# Adjust fast file output based on options...
#
    my $output = shift;   ### current output (to be edited as required)
    my $header = shift;   ### use this for the header (for fasta files)
    my $Options = shift;  ### see get_sequences (use Clip_Poly_T, upper, lower) ###    

    my $clip = $Options->{Clip_Poly_T} || 0;
    my $upper = $Options->{upper} || 0;
    my $lower = $Options->{lower} || 0;

    ########## reformat output for case, poly T clipping if necessary...
    if ($lower) {$output = lc($output);}
    if ($upper) {$output = uc($output);}

    my $Fclip = 0; # clip from the front flag
    my $Bclip = 0; # clip from the back flag 

    if ($clip=~/^(\d+)$/) {$Fclip = $clip; $Bclip = $clip;}
    if ($clip=~/F(\d+)/i) {$Fclip = $1;}
    if ($clip=~/B(\d+)/i) {$Bclip = $1;}

################ clip from the front ##############3
    if ($Fclip) {
	if ($output=~/^([tT]+)(.*)$/) {
	    my $clipped = length($1);
	    if ($clipped > $Fclip) {
		$output = $2;
		$header .= " (clipped $clipped bp poly_T tail from front)";
	    }
	}
    }

    ######## clip from the back ###########
    if ($Bclip) {
	if ($output=~/(.*)([tT]+)$/) {
	    my $clipped = length($2);
	    if ($clipped > $Bclip) {
		$output = $1;
	    $header .= " (clipped $clipped bp poly_T tail from back)";
	    }
	}
    }
    
    return ($output,$header);
}

#####################
sub get_run_info {
#####################
#
# A simple routine to simply extract info for a run
#
# (may also retrieve statistics for a specified list of runs)
#
#
    my %args = @_;

    my $dbc = $args{'dbc'} || $Connection;          ### database handle (required unless source=cache)
    my @run_ids = @{ $args{'run_ids'} };  ### run ids
    my $well = $args{'well'};      ### well (optional) - defaults to entire plate...
    my $source = $args{'source'} || 'db';  ###
    my $quiet = $args{'quiet'} || 0;       ### - quiet mode (no feedback)
    my $field_list = $args{'fields'} || '';     ### - specify information to retrieve (MUST be field in Clone_Sequence table) - optional
    my $Qclipped = $args{'quality_clipped'} || 0;  ### specify if quality to be clipped from Run/Sequence_Scores...
    my $Vclipped = $args{'vector_clipped'} || 0;   ### specify if vector to be clipped from Run/Sequence_Scores... 
    my $include_test = $args{'include_test'} || 0;
    my $include_NG = $args{'include_NG'} || 0;
    my $stats = $args{'statistics'} || 0;          ### retrieve statistics as well
    my $group = $args{'group'} || 0;               ### Future - allow statistical grouping using a particular parameter (eg. Run_ID)
    
    my %Run_Info;
    my $table = "Clone_Sequence,Run";
    my $base_condition = "WHERE FK_Run__ID=Run_ID AND Run_Status='Analyzed'";  ## ALWAYS exclude Failed / Aborted runs

    my $well_spec;
    if ($well) { $well_spec .= "AND Well in ('$well') "; }
    unless ($include_test) {
	$well_spec .= "AND Run_Test_Status like 'Production' "; 
    }
    unless ($include_NG) {$well_spec .= "AND Growth IN ('OK','Slow Grow') "; }
    
    my @fields = ('FK_Run__ID','Run_Directory','Well','Sequence','Sequence_Length','Quality_Left','Quality_Length',&Sequencing::Tools::SQL_phred(20) ." as P20",'Growth');
    
    ### add extra fields if necessary.. ###
    if ($field_list) {
	foreach my $field (@$field_list) {
	    unless (grep /^$field$/, @fields) {
		push(@fields,$field);
	    }
	}
    }
    
    my $id_list = join ',', @run_ids;

    if ($source =~ /cache/i) { 
	unless ($quiet) { print "Data retrieved from cache\n"; } 
    } elsif ($dbc && ($id_list=~/\d/)) {
	%Run_Info = &Table_retrieve($dbc,$table,\@fields,
				    "$base_condition AND FK_Run__ID in ($id_list) $well_spec Order by FK_Run__ID,Well");
    }
   
    if ($Qclipped) {
	unless (grep /^Quality_Left/, @fields) { print "Quality_Left must be included in field_list for Qclipped info\n"; }
	unless (grep /^Quality_Length/, @fields) { print "Quality_Left must be included in field_list for Qclipped info\n"; }
 	unless (grep /^Run/, @fields) { print "Run or Sequence_Scores must be included in field_list for Qclipped info\n"; }
    } 

    unless ($Qclipped || $Vclipped || $stats) { return %Run_Info; }   ### return the retrieved hash directly (No clipping editing required)

    my @P20;
    my $index = 0;
    while (defined $Run_Info{Quality_Left}[$index]) {
	my $qleft = $Run_Info{Quality_Left}[$index];
	my $qlength =  $Run_Info{Quality_Length}[$index];
	my $length =  $Run_Info{Sequence_Length}[$index];
	my $vleft = $Run_Info{Vector_Left}[$index];
	my $vright = $Run_Info{Vector_Right}[$index];

	my $sequence = $Run_Info{Sequence}[$index];
	my $P20 = $Run_Info{P20}[$index];
	my $cut_left = 0;
	my $cut_length = $length;
	if ($Qclipped) {
	    $cut_left = $qleft;
	    $qlength = $qlength;
	}
	if ($Vclipped) {
	    if (($vleft>0) && ($vleft > $cut_left)) {$cut_left = $vleft;}
	    if (($vright>0) && ($vright < $qleft+$qlength-1)) { $qlength = $vright-$qleft; }
	    if ($cut_length > 0 ) {
		my $clipped_sequence = substr($sequence,$cut_left,$cut_length);
		$Run_Info{Sequence}[$index] = $clipped_sequence;       #### rewrite Run string.. 
	    } else { $Run_Info{Sequence}[$index]=''; }                  #### clear Run (all vector).. 
	}
	push(@P20,$P20);
	$index++;
	
    }
    
    my $statistics = Statistics::Descriptive::Full->new();
    $statistics->add_data(@P20);

    $Run_Info{count} = $statistics->count;
    $Run_Info{median} = $statistics->median();
    $Run_Info{mean} = $statistics->mean();
    $Run_Info{sum} = $statistics->sum();
    $Run_Info{stddev} = $statistics->standard_deviation();

    return %Run_Info;
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

$Id: Seq_Data.pm,v 1.22 2004/11/16 22:25:44 rguin Exp $ (Release: $Name:  $)

*** May 21 (R.Guin) ***
Excluded Failed / Aborted runs automatically in base condition
Added options:
-b (for billable only)
-a (for approved runs only)
-q (for quiet mode)
-g (to exclude no grows)

=cut


return 1;
