################################################################################
#
# Fasta.pm
#
# This provides routines for generating fasta files from the Sequencing Database
#
################################################################################
################################################################################
# $Id: Fasta.pm,v 1.7 2004/10/26 19:41:38 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.7 $
#     CVS Date: $Date: 2004/10/26 19:41:38 $
################################################################################
package Sequencing::Fasta;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Fasta.pm - This provides routines for generating fasta files from the Sequencing Database

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This provides routines for generating fasta files from the Sequencing Database<BR>

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
use strict;

##############################
# custom_modules_ref         #
##############################
use SDB::CustomSettings;
use SDB::DBIO;use alDente::Validation;
use alDente::SDB_Defaults;

##############################
# global_vars                #
##############################
our ($testing, $project_dir);   ### requires project directory global to be set to specify where data is located.

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

###############################################################################
#
# Perl Module:  Fasta (containing database information retrieval routines)
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
#    $dbc = SDB::DBIO->new(-dbase=>$dbase,-user=>$login_name,-password=>$login_pass,-trace_level=>$trace_level,-connect=>0);
#    $dbc->connect();
#
# (where $dbase = 'sequence' normally)
# This method is in the DBIO.pm module.
#
#############
#  Methods: #
#############
#  
#  %seq = get_library_sequences($dbc,$library,$fastafile,$Options)
#  %seq = get_run_sequences($dbc,$library,$fastafile,$Options)
#  
#  - returns indexed quality sequences from an entire library (or from a sequence run)
#   eg. after running: ... %seq->{CN0011a_B05}='gcaat...'
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
#  Note:  an example of how to use the functions in this module is in Fasta_test.pl
#
###########################################################################

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
    my $dbc = shift || $Connection;
    my $library = shift;
    my $filename = shift;
    my $Options = shift;
    
    my $all_runs = $Options->{all} || 0;
#    my $whole_sequence = $Options->{whole} || 0;
    my $qtrim = $Options->{qtrim};
    my $vtrim = $Options->{vtrim};
    my $choose_by = $Options->{choose_by};
    my $chemcode = $Options->{chemcode} || 0;
    my $source = $Options->{source} || 0;
    my $info = $Options->{info} || 0;
    my $N_threshold = $Options->{N_threshold} || 0; 

    if ($chemcode) {$chemcode = "%.$chemcode";}
    else {$chemcode = "";}

    my %sequences = get_sequences($dbc,"where Library like \"$library$chemcode%\"",$Options);
    unless (%sequences) {return;}
    
    if ($filename=~/\S/) {   
	my $SEQFILE;
	open(SEQFILE,">$filename") or print "Error opening $SEQFILE ($filename)";
	foreach my $thiskey (sort keys %sequences) {
	    if ($thiskey=~/^Clone:/) {next;}
	    my $output = %sequences->{$thiskey};
	    my $length = length($output);
	    if ($thiskey=~/[a-zA-Z0-9]+/) {
		my $clone = %sequences->{"Clone:$thiskey"};

		######### adjust output based on Options ... #########
		($output,$clone) = &fix_output($output,$clone,$Options);

		print SEQFILE ">$thiskey - $clone\n";
		
		if ($output=~/\S+/) {print SEQFILE "$output\n";}
#		print ">$thiskey\n$output\n";
	    }
	}
	
	print "Wrote to $filename\n";
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

    my $dbc = shift || $Connection;
    my $run = shift;
    my $filename = shift;
    my $Options = shift;

    my $all_runs = $Options->{all} || 1;  ### in case it is a test run..
#    my $whole_sequence = $Options->{whole} || 0;
#    my $vector = $Options->{vector} || 0;
    my $qtrim = $Options->{qtrim};
    my $vtrim = $Options->{vtrim};
    my $choose_by = $Options->{choose_by};
    
    my $chemcode = $Options->{chemcode} || 0;
    my $source = $Options->{source} || 0;
    my $info = $Options->{info} || 0;
    my $N_threshold = $Options->{N_threshold} || 0;

    my %sequences = get_sequences($dbc,"where Run_ID in ($run)",$Options);
    unless (%sequences) { return; }

    print "Looking for run $run<BR>\n";

    if ($filename=~/\S/) {
	my  $SEQFILE;
	open(SEQFILE,">$filename") or print "Error opening $SEQFILE ($filename).";
	#|| print "Error opening $SEQFILE";
	foreach my $thiskey (sort keys %sequences) {
	    if ($thiskey=~/Clone:/) {next;}
	    my $output = %sequences->{$thiskey};
	    if ($thiskey=~/[a-zA-Z0-9]+/) {
		my $clone = %sequences->{"Clone:$thiskey"};
		
		######### adjust output based on Options ... #########
		($output,$clone) = &fix_output($output,$clone,$Options);

		print SEQFILE ">$thiskey - $clone\n";
		if ($output=~/\S+/) {print SEQFILE "$output\n";}
#		print ">$thiskey\n$output\n";
	    }
	}
	print "Wrote to $filename<BR>\n";
	close SEQFILE or print "Error closing $SEQFILE";
    }

    return %sequences
}

sub library_phred_passes {
######################################################################
# eg library_phred_passes($dbc,$library,$threshold)
#######################################################################
    my $dbc = shift || $Connection;
    my $library = shift;
    my $threshold = shift;

    $threshold ||= 20; # default

    my $passes = threshold_phred_scores($dbc,$threshold,"where Run_Directory like \"$library%\"");
    
    return $passes;
}

############################
sub sequence_phred_passes {
############################
    my $dbc = shift || $Connection;
    my $sequence_id = shift;
    my $threshold = shift;

    $threshold ||= 20; # default

    if ($sequence_id=~/^[A-Z]{2}\w{3}\d+/) {
	$sequence_id=$dbc->Table_find('Run','Run_ID',"where Run_Directory like \"$sequence_id\""); 
    }	
    my $passes = threshold_phred_scores($dbc,$threshold,"where Run_ID in ($sequence_id)");

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

    my $dbc = shift || $Connection;
    my $threshold = shift;
    my $condition = shift;
#    $condition=~s/ Run_ID/ Run.Run_ID/g;
    $condition=~s/ Library/ Run_Directory/ig;

    my @all_results;

    my @scores = $dbc->Table_find('Clone_Sequence,Run','Sequence_Scores',"$condition and FK_Run__ID=Run_ID");

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
#    my $totals = "$total_passed\t$total_failed\t$total_tested";
#    push(@return_values,$totals);
#    push(@return_values,@all_results);
#    return @return_values;
    return $total_passed;
}

########################
sub get_good_sequence {
########################
    my $dbc = shift || $Connection;
    my $Options = shift;
    my $id = shift;
    my $well = shift;
    my $cut_left = shift || 0;
    my $cut_length = shift;
    my $threshold = shift || 0;

    (my $scores) = $dbc->Table_find('Clone_Sequence','Sequence_Scores',"where FK_Run__ID=$id and Well = '$well'");
    (my $sequence) = $dbc->Table_find_array('Clone_Sequence',['Sequence'],"where FK_Run__ID=$id and Well = '$well'");

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
#
    my $dbc = shift || $Connection;
    my $condition = shift;
    my $Options = shift;

    my $order;

    my $all = $Options->{all} || 0;
#    my $whole_sequence = $Options->{whole} || 0;
#    my $vector = $Options->{vector} || 0;
    my $qtrim = $Options->{qtrim};
    my $vtrim = $Options->{vtrim};
    my $choose_by = $Options->{choose_by};
    my $source = $Options->{source} || 0;
    my $info = $Options->{info} || 0;
    my $N_threshold = $Options->{N_threshold} || 0;
    my $Q_file = $Options->{quality_file} || 0;
    my $exclusion_file = $Options->{exclude};
    my $inclusion_file = $Options->{include};

    my $contaminated = 0;

    my %Ifiles;
    if ($inclusion_file) {
	open(FILE,"$inclusion_file") or die "could not find $inclusion_file";
	while (<FILE>) {
	    chomp;
	    %Ifiles->{$_} = 1;
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
	    %Xfiles->{$_} = 1;
	}
	close(FILE) or print "could not CLOSE $exclusion_file";
	print "Excluding clones: \n";
	foreach my $key (keys %Xfiles) {
	    print "$key\n";
	}
    }

    if ($vtrim) {print "Trimming for Vector \n";}
    if ($qtrim) {print "Trimming for Quality<BR>\n";}
    print "(maximize length of $choose_by) <BR>\n";
    if (!$vtrim && !$qtrim) {print "Nothing trimmed from Run<BR>\n";}

    if ($all) {print "(Including Test,Development Runs)<BR>\n";}
    else {print "(Excluding Test,Development Runs)<BR>\n";}
    if ($Q_file) {print "Replacing nucleotide sequences with Quality scores<BR>\n";}

    $condition=~s/ Run_ID/ Run.Run_ID/g;
    $condition=~s/ Library/ Run_Directory/ig;
    $condition .= " AND Run_ID=Clone_Sequence.FK_Run__ID";
    if (!$all) {$condition .= " AND Run_Test_Status like '%Production%'";}
    $order .= " Order by Clone_Sequence.Well,Run_Directory";

    my $table_list = 'Clone_Sequence,Run LEFT JOIN Note on FK_Note__ID=Note_ID';
    my @data_list = ('Run_Directory','Clone_Sequence.Well','Clone_Sequence.Sequence','Quality_Left','Quality_Length','Vector_Left','Vector_Right','Note_Text','Read_Warning','Run_ID','FK_Plate__ID','Sequence_Length','Clone_Sequence_Comments');

    my %Read_info = &Table_retrieve($dbc,$table_list,\@data_list,"$condition $order");

    unless (defined %Read_info->{Run_ID}) { return; } 
    my $found = int(@{ %Read_info->{Run_ID} });
    print "Found $found sequences<BR>\n";
    
    my $save_length;
    my %sequences;
    my %scores;
    my %slength;
    my %clones;
#    my %index=0;

    ######## make well lookup table...
    my $Well = {};
    my $PlateSourceName = {};
    my $PlateSource = {};

    if ($source) {   ### use Source Name in Fasta Header (rather than local Sequence_subdirectory identifier)
	for my $quad ('a'..'d') {
	    for my $row ('A'..'H') {
		for my $col (1..12) {
		    if ($col<10) {$col='0'.$col;}
		    (my $newname) = $dbc->Table_find('Well_Lookup','Plate_384',"where Plate_96 like '$row$col' and Quadrant='$quad'");
		    if ($newname=~/^(\w)(\d)$/) {$newname = uc($1)."0".$2;}
		    else {$newname = uc($newname);}
		    $Well->{"$row$col"}->{$quad} = $newname;
#		    print "$row$col -> $newname..";
		}
	    }
	}

	my $sourcename = 'Clone_Source_Name';
	my $source = 'Clone_Source';
	
	print "mapping plates onto original Source names...\n";
#	foreach my $plateinfo (@info) {
	my $index = 0;
	while (defined %Read_info->{Run_ID}[$index]) {
#	    my @all_info = split ',', $plateinfo;
#	    my $plate = $all_info[9];
#	    my $well = $all_info[1];
	    my $plate = %Read_info->{FK_Plate__ID}[$index];
	    my $well = %Read_info->{Well}[$index];

	    my $plates = get_Plate_parents($dbc,$plate);
	    (my $parent_quad) = $dbc->Table_find('Plate','Max(Parent_Quadrant)',"where Plate_ID in ($plates)");
	    my $srcinfo = join ',', $dbc->Table_find('Clone,Plate',"$sourcename,$source,Clone_Source_Row,Clone_Source_Col,Clone_Quadrant","where FK_Plate__ID=Plate_ID and Plate_ID in ($plates) and ((Clone_Quadrant='$parent_quad' and Clone_Well='$well') or (Clone_Well = 'all'))");
	    (my $name,my $Src,my $row,my $col,my $quad) = split ',', $srcinfo;
	    $parent_quad ||= $quad;

	    my $src_well;
	    if ($row=~/NULL/) {$src_well = $Well->{$well}->{$parent_quad};}
	    else {$src_well = $row.$col;}
	
	    $PlateSourceName->{"$plate$well"}="$name$src_well";
	    $PlateSource->{"$plate$well"}=$Src;
	    print "map $plate($well) -> $name$src_well ($Src) \n";
	    $index++;
	}
    }
    
    my $similar = 0;
    my $index = 0;
    while (defined %Read_info->{Run_ID}[$index]) {
#	foreach my $run (@info) {
	my $ssdir = %Read_info->{Run_Directory}[$index];
	my $well = %Read_info->{Well}[$index];
	my $seq = %Read_info->{Sequence}[$index];
	my $qleft = %Read_info->{Quality_Left}[$index];
	my $qlength = %Read_info->{Quality_Length}[$index];
	my $vl = %Read_info->{Vector_Left}[$index];
	my $vr = %Read_info->{Vector_Right}[$index];
	my $note = %Read_info->{Note_Text}[$index];
	my $warning = %Read_info->{Read_Warning}[$index];
	my $id = %Read_info->{Run_ID}[$index];
	my $plate = %Read_info->{FK_Plate__ID}[$index];
	my $slength = %Read_info->{Sequence_Length}[$index];
	my $comment = %Read_info->{Clone_Sequence_Comments}[$index];
#	(my $ssdir,my $well,my $seq,my $qleft,my $qlength,my $vl,my $vr,my $note,my $warning,my $id,my $plate,my $slength, my $comment) = split ',',$run;
	
	if ($Options->{ecoli} && ($warning=~/Contam/)) {
	    my ($E_value) = $dbc->Table_find('Contaminant','E_value',"where FK_Run__ID=$id AND Well='$well'"); 
	    my $threshold = 1/(10 ** $Options->{ecoli});
	    if ($E_value=~/\d+/) {  ### contamination comment format 
		if ($E_value < $threshold) {
		    print "Run$id $ssdir $well ($warning (E=$E_value)\n";
		    $contaminated++;
		    $index++;
		    next;
		}
	    } else { $note.= "(E=$E_value)"; }
	}
	    
	if (($note ne 'NULL') && $note) { $note = "Note: $note"; }
	else {$note = "";}
	
	if ($info) {
	    my $lib_name = substr ($ssdir,0,5);
	    (my $proj_dir) = $dbc->Table_find('Project,Library','Project_Path',"where FK_Project__ID=Project_ID and Library_Name = '$lib_name'");
	    my $lib_dir = "$project_dir/$proj_dir/$lib_name";
	    my $trace = "(Trace: $lib_dir/AnalyzedData/$ssdir/chromat_dir/$lib_name*$well*)";
	    $note = "RunID:$id $trace $note";
	}
	
	my $qright = $qleft + $qlength -1;
	## if "include low quality sequence is chosen"... ##

	my $clone;
	if ($ssdir =~ /^([a-zA-Z0-9]{5})(\d+)([a-zA-Z]?)/) {
	    $clone = $1.$2.$3."_".$well;
	    if ($Options->{include_redundancies}) {$clone = "$ssdir:$well";}  
	}	
	else {$clone = ""; print "\nStrange Clone name ($ssdir)";}
	
	my $prenote;
	if ($source) {
	    $clone = $PlateSourceName->{"$plate$well"};
	    $prenote = $PlateSource->{"$plate$well"};
            # ($dbc,$plate,$source,$well,$Well);
	}
	
#######  Determine if clone name is mentioned in include/exclude files .. #########
	my $skip = 0;
	if ($inclusion_file) {
	    unless (%Ifiles->{$clone}) {$skip=1;}
	    else {"Include $clone..\n";} 
#	    my $skip=1;
#	    foreach my $key (keys %Ifiles) {
#		chomp $key;
#		unless ($key=~/\S/) {next;}
#		if ($clone=~/^$key/) {$skip=0;}
#		elsif ($id=~/^$key$/) {$skip=0;}
#	    }
	}
	elsif ($exclusion_file) {
	    if (%Xfiles->{$clone}) {print "Exclude $clone..\n"; $skip=1;}
#	    foreach my $key (keys %Xfiles) {
#		chomp $key;
#		unless ($key=~/\S/) {next;}
#		if ($clone=~/^$key/) {$skip=1; print "Skip $clone\n";}
#		elsif ($id=~/^$key$/) {$skip=1; print "Skip $clone\n";}
#	    }
	}
	if ($skip) { $index++; next;}
######

	my $ql = $qleft;
	my $qr = $qright;

	if ($vtrim) {   ## trim for vector 
	    if ($vl>=0 && $ql<=$vl) {$ql = $vl+1;}
	    if ($vr>=0 && $qr>=$vr) {$qr = $vr-1;}
	}
	my $length = $qr - $ql + 1;     ### quality_length generated 

	my $cut_right = $qr;  #### save separate indexes for cutting sequence out
	my $cut_left = $ql; 
	unless ($qtrim) {      #### reset cut positions to entire sequence
	    $cut_left=0; 
	    $cut_right=length($seq) -1;
	
	    if ($vtrim) {   
		if ($vl>=0) {$cut_left=$vl+1;}
		if ($vr>=0) {$cut_right=$vr-1;}
	    }
	}
	my $cut_length = $cut_right - $cut_left +1;
	if ($cut_length<0) {$cut_length = 0;}

	if ($choose_by =~ /total/i) {  ### if ordering by whole sequence...
	    $length=$cut_length;
	}
	else {                       ### if ordering by quality region...
	    if ($qr<0) {$length=0;}
	}
#	$sequences->[$index]->[0]=$clone;
	if (%sequences->{$clone}) {
	    if (%slength->{$clone} && ($length > %slength->{$clone})) {
		$save_length=$length;
		if ($cut_length>0) {
		    %sequences->{$clone} = get_good_sequence($dbc,$Options,$id,$well,$cut_left,$cut_length,$N_threshold);
		}
		else {%sequences->{$clone} = "";} 
		%slength->{$clone} = $length;
		%sequences->{"Clone:$clone"} = "$prenote $ssdir ($cut_length) $note";

		$similar++;
	    }
	}
	else {
	    if ($cut_length > 0) {
		%sequences->{$clone} = get_good_sequence($dbc,$Options,$id,$well,$cut_left,$cut_length,$N_threshold);
	    }
	    else {%sequences->{$clone} = "";}

	    %slength->{$clone} = $length;
	    %sequences->{"Clone:$clone"} =  "$ssdir ($cut_length) $note";
#		print %sequences->{"Clone:$clone"}."\n";

	    $similar = 0;
	}
	$index++;
#	print "\n$clone: ".%sequences->{$clone} . %sequences->{"Clone:$clone"};
    }
    my $unique = int(keys %sequences)/2;

    print "($unique Unique)\n";
    if ( $Options->{ecoli} ) { print "($contaminated Contaminated with e-coli)\n"; }
    return %sequences;
}

###################
sub fix_output {
###################
#
# Adjust fast file output based on options...
#
    my $output = shift;
    my $header = shift;
    my $Options = shift;

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

#    print "\nClipping $Fclip from the front";
#    print "\nClipping $Bclip from the back";
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

$Id: Fasta.pm,v 1.7 2004/10/26 19:41:38 rguin Exp $ (Release: $Name:  $)

=cut


return 1;
