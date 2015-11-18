###########
# Read.pm #
###########
#
# This module is used to handle 'Read' objects
# 
# (associated with Records in the 'Clone_Sequence' table of the 'sequence' database)
#
# Much of the functionality of this module is inherited from the 'DB_Object' module 
# (record extraction, viewing, appending etc)
###################
package Sequencing::Read;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Read.pm - This module is used to handle 'Read' objects

=head1 SYNOPSIS <UPLINK>

 ## The retrieval of data is dependent upon the DB_Object.pm module (see this module for more info) ##
  
 ## Connect to the database using DBIO module ##
 my $dbc = SDB::DBIO->new(-dbase=>'sequence',-host=>'athena',-user=>'viewer',-password=>$pass);
 $dbc->connect();

 ## Define fields that you wish to retrieve ##
 my @fields = ('Library_Name',"counnt(*) as Count", "sum(Sequence_Length) as SL_total","Library.Library_Description", "Library_Source_Name", "Max(Run_DateTime) as Latest","Average_Q20");
  
 my $Reads = Read->new(-dbc=>$dbc);    ## initialize 'Read' object
  
 ## specify connected tables to include and retrieve with custom condition ###
  
 $Reads->add_tables('Run,Plate,Library');
 $Reads->load_Object(-fields=>\@fields,-condition=>"FK_Project__ID in (4) AND Run_Status='Analyzed'",-group_by=>'Library_Name',-multiple=>1,-order_by=>'Library_Name');
  
 ## OR ##
  
 ## standard retrieval of data for given project(s) (do not need to include tables, or project condition) ##
  
 $Reads->retrieve_by_Project(-fields=>\@fields,-project_id=>4,-condition=>"Run_Status='Analyzed'",-group_by=>'Library_Name',-order_by=>'Library_Name');
  
 ## Print out values retrieved... ##
 print "Query:\n******\n" . $Reads->{retrieve_query};
 print " (found $Reads->{record_count} records)\n";
  
 print "\n\nRetrieved: \n***************\n";
 foreach my $field (@fields) {
     if ($field =~/(.+) as (.+)/) { $field = $2 }
     foreach my $index (1..$Reads->{record_count}) {
 	 print "$field ($index) = " . $Reads->value(-field=>$field,-index=>$index-1) . "\n";
     }
     my @values = keys %{$Reads->values(-field=>$field)};
     print "Combined: @values.\n";
 }

=head1 DESCRIPTION <UPLINK>

=for html
This module is used to handle 'Read' objects<BR>(associated with Records in the 'Clone_Sequence' table of the 'sequence' database)<BR>Much of the functionality of this module is inherited from the 'DB_Object' module <BR>(record extraction, viewing, appending etc)<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(SDB::DB_Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;

use SDB::DB_Object;
use SDB::DBIO;use alDente::Validation;
use SDB::DB_Form_Viewer;
use SDB::HTML;
use SDB::CustomSettings;

use Sequencing::Tools qw(SQL_phred);

use lib "/opt/alDente/versions/rguin/lib/perl/Imported/";
use Bio::Tools::BPbl2seq;

##############################
# global_vars                #
##############################
use vars qw(%Field_Info $URL_temp_dir $testing);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my $TABLE              = 'Clone_Sequence';
my @RELATED_TABLES     = ('Run','RunBatch','Plate');
my $FK_RUN_FIELD       = 'FK_Run__ID';
my $WELL_FIELD         = 'Well';
my $PLATE_NUMBER_FIELD = 'Plate_Number';
my $RUN_NAME_FIELD     = 'Run.Run_Directory';

##############################
# constructor                #
##############################

#########
sub new {
#########
#
# Constructor of the object
#
    my $this  = shift;
    my $class  = ref($this) || $this;

    my %args = @_;
    my $dbc       = $args{-dbc} || $Connection;
    my $run_id    = $args{-run_id};    ## specify Plate ID [int]
    my $well      = $args{-well};      ##  ... along with Well [char(3)]
    my $retrieve  = $args{-retrieve};  ## retrieve information right away [0/1]
    my $verbose = $args{-verbose};

    my $self = $this->SDB::DB_Object::new(-dbc=>$dbc,-tables=>['Clone_Sequence']);
    
    bless $self,$class;       

    $self->{dbc} = $dbc if $dbc;
   
    $self->{records} = 0;              ## number of records currently loaded

    if ($run_id) {
	$self->{run_id} = $run_id;
	$self->{well} = $well;
	my $id = $self->retrieve_by_Run(-run_id=>$run_id,
					-well=>$well,
					-retrieve=>$retrieve,
					-verbose=>$verbose);
    }
    
    ### set up aliases for standard 'phred 20- (and phred 30, phred 40) ###
    $self->{Field_Alias}->{Q20} = SQL_phred(20);
    $self->{Field_Alias}->{Q30} = SQL_phred(30);
    $self->{Field_Alias}->{Q40} = SQL_phred(40);    

    $self->{Field_Alias}->{Average_Q20} = "Sum(" . SQL_phred(20) . ")/Count(*)";
    $self->{Field_Alias}->{Average_Q30} = "Sum(" . SQL_phred(30) . ")/Count(*)";
    $self->{Field_Alias}->{Average_Q40} = "Sum(" . SQL_phred(40) . ")/Count(*)";

    return $self;
}

##############################
# public_methods             #
##############################

##########################################
# Retrieve Record Data from the Database #
##########################################

####################
sub load_Sequence_Runs {
####################
    my $self = shift;
    my %args = @_;        ## arguments passed

    my $study_id     = $args{-study_id} || '';     # quadrant              - optional
    my $project_id   = $args{-project_id};      # Project_ID - (may be comma-delimeted list)    
    my $library      = $args{-library};            # Library name 
    my $plate_number = $args{-plate_number};       # plate number (not id) - optional 
    my $quadrant     = $args{-quadrant} || '';     # quadrant              - optional
    my $condition    = $args{-condition} || 1;     # condition (optional additional condition for finding runs)

    my $well         = $args{-well};               # well                  - optional
    my $include      = $args{-include} || 'approved,production';
    my $fields       = $args{-fields};
    my $group_by     = $args{-group_by};
    my $order_by     = $args{-order_by} || 'Run_ID';

    my $runs = &get_experiment_list(-project_id=>$project_id,-library=>$library,-plate_number=>$plate_number,-quadrant=>$quadrant,-study=>$study_id,-condition=>$condition,-include=>$include);

    my $read_condition = "FK_Run__ID IN ($runs)";

    ## update condition if well given    
    $well =~s/,/','/g;
    if ($well) { $read_condition .= " AND $WELL_FIELD in ('$well')" }                       
    
    $self->add_tables(\@RELATED_TABLES);
    $self->add_tables('Library');
    ## generate retrieve statement including related tables ##
    my $found = $self->load_Object(-fields=>$fields,-condition=>$read_condition ,-multiple=>1,-group_by=>$group_by,-order_by=>$order_by);
    
    $self->{reads} = $found;
    return $found;  ## number of records retrieved 
}
    
#####################
sub retrieve_by_Project {
#####################
#
# Standard interface to retrieve Record(s)
#
    my $self = shift;
    my %args = @_;        ## arguments passed

    my $project_id      = $args{-project_id};      # Project_ID - (may be comma-delimeted list)    
    my $library      = $args{-library};            # Library name 
    my $plate_number = $args{-plate_number};       # plate number (not id) - optional 
    my $quadrant     = $args{-quadrant} || '';     # quadrant              - optional
    my $well         = $args{-well};               # well                  - optional
    my $condition    = $args{-condition} || 1;     # condition (optional additional condition)
    my $fields       = $args{-fields};
    my $group_by     = $args{-group_by};
    my $order_by     = $args{-order_by} || 'Run_ID';
  
    unless ($project_id) { return }      # user MUST provide a library name for this method

    $condition = "$condition AND FK_Project__ID in ($project_id)";

    ## update condition if plate_number given
    if ($library) { $condition .= " AND Library_Name in ('$library')" }

    ## update condition if plate_number given
    if ($plate_number) { $condition .= " AND $PLATE_NUMBER_FIELD in ($plate_number)" }

    ## update condition if well given    
    $well =~s/,/','/g;
    if ($well) { $condition .= " AND $WELL_FIELD in ('$well')" }                       
    
    $self->add_tables(\@RELATED_TABLES);
    $self->add_tables('Library');
    ## generate retrieve statement including related tables ##
    my $found = $self->load_Object(-fields=>$fields,-condition=>$condition ,-multiple=>1,-group_by=>$group_by,-order_by=>$order_by);
    
    $self->{reads} = $found;
    return $found;  ## number of records retrieved 
}

#####################
sub retrieve_by_Library {
#####################
#
# Standard interface to retrieve Record(s)
#
    my $self = shift;
    my %args = @_;        ## arguments passed

    my $library      = $args{-library};            # Library name 
    my $plate_number = $args{-plate_number};       # plate number (not id) - optional 
    my $quadrant     = $args{-quadrant} || '';     # quadrant              - optional
    my $well         = $args{-well};               # well                  - optional
    my $condition    = $args{-condition} || 1;     # condition (optional additional condition)
    my $fields       = $args{-fields};
    my $group_by     = $args{-group_by};
    my $order_by     = $args{-order} || 'Run_ID';
  
    unless ($library) { return }      # user MUST provide a library name for this method

    $condition = "$condition AND Library_Name like '$library%'";

    ## update condition if plate_number given
    if ($plate_number) { $condition .= " AND $PLATE_NUMBER_FIELD in ($plate_number)" }

    ## update condition if well given    
    $well =~s/,/','/g;
    if ($well) { $condition .= " AND $WELL_FIELD in ('$well')" }                       
    
    $self->add_tables(\@RELATED_TABLES);
    $self->add_tables('Library');
    ## generate retrieve statement including related tables ##
    my $found = $self->load_Object(-fields=>$fields,-condition=>$condition ,-multiple=>1,-group_by=>$group_by,-order_by=>$order_by);
    
    $self->{reads} = $found;
    return $found;  ## number of records retrieved 
}

##################
sub retrieve_by_Run {
##################
#
# Retrieve Records by supplying Run_ID
#
    my $self = shift;
    my %args = @_;

    my $run_id   = $args{-run_id};     
    my $well     = $args{-well};
    my $retrieve = $args{-retrieve};    ## retrieve values (otherwise, only sets primary_value)
    my $verbose  = $args{-verbose};     ## include details for related tables
    my $fields       = $args{-fields};
    my $group_by     = $args{-group};
    my $order_by     = $args{-order} || 'Run_ID';
    my $dbc      = $self->{dbc} || $Connection;
    
    ## get the primary value ##
    my $condition;
    if ($run_id && $well) {
	my ($primary_value) = $dbc->Table_find($TABLE,$self->{primary_field},
					  "where $FK_RUN_FIELD = $run_id AND $WELL_FIELD = '$well'");
	$self->primary_value($primary_value) if $primary_value;
    } else {
	$condition = "$FK_RUN_FIELD in ($run_id)";
    }

    ## retrieve the records if desired ##
    my $found = 0;
    if ($retrieve) { 
	if ($verbose) {   ## include extra tables ##
	    $found = $self->load_Object(-fields=>$fields,-condition=>$condition ,-multiple=>1,-group_by=>$group_by,-order_by=>$order_by); 
	} else {          ## only local table ##
	    $found = $self->load_Object();
	}
    }
    $self->{reads} = $found;
    return $found;  ## primary key value for this object 
}

##################
sub retrieve_by_Name {
##################
#
# Retrieve Records given 'Name' 
# (eg. -name=>'CN0011a.BR' (96 records)  or 'CN0011a.BR_A03' (1 record) 
#
	my $self = shift;		

# (under construction)

    return;
}

####################
sub retrieve_by_Source {
####################
#
# Retrieve Records given Source information 
# (eg. -source=>'MGC',-source_name=>'3350620')
#
    my $self = shift;

# (under construction)
    return;
}

######################
# Access Record Data #
######################

###########
sub get_QL {
###########
#
# return Quality Length
#
    my $self = shift;
    my %args = @_;
    my $list = $args{-list};       ## supply array of values if more than one record loaded
    
    my $key = 'value';
    if ($list) { $key = 'values' }
    
    return $self->{fields}->{'Quality_Length'}->{$key};
}

#################
sub get_Phred {
#################
#
# return Phred count (ie Q20, Q30 etc)
#
    my $self = shift;
    my $phred = shift;
    my %args = @_;
    my $list = $args{-list};        ## supply array of values if more than one record loaded
    
    if ($list) {
	my @qvalues = ();
	my @hists = @{ $self->{fields}->{'Phred_Histogram'}->{values} };
	foreach my $hist (@hists) {
	    push(@qvalues,_unpack($hist,-bytes=>2,-index=>$phred));
	}
	return \@qvalues;
    } else {
	my $hist = $self->{fields}->{'Phred_Histogram'}->{value};
	return _unpack($hist,-bytes=>2,-index=>$phred) ;
    }
}

############
sub get_Name {
############
# 
# Retrieve Read Name (in standard format)
#
# - may also retrieve optional aliases (eg. MGC#) if available)
#
    my $self = shift;
    my %args = @_;
    my $list = $args{-list};        ## supply array of Names if more than one loaded
    
    my $key = 'value';
    if ($list) { 
	$key = 'values';
	my @names;
	my @values = @{$self->{fields}->{$RUN_NAME_FIELD}->{$key}};
	my @wells = @{$self->{fields}->{$WELL_FIELD}->{$key}};
	my $index=0;
	foreach my $run_name (@values) {
	    my $name = $run_name . '_' . $wells[$index++];
	    push(@names,$name);
	}
	return \@names;
    } else {
	my $name = $self->{fields}->{$RUN_NAME_FIELD}->{$key} .
	    '_'. 
		$self->{fields}->{$WELL_FIELD}->{$key};
	return $name;
    }
}

#############################
# compare 2 runs (useful for QA purposes)
#
# <snip>
#  Example:
#  my %Results = compare_runs(123,124);
#
# print "matched wells: @$Results{match}";
# foreach my $failed_well (@$Results{fail}) { print "Failed $failed_well : $Results{$failed_well}{Message} }
# </snip>
#
# Return: \%hash containing keys: fail, match, warning, poor(lists of wells); also %hash{<WELL>} keys: Message, Result
###################
sub compare_runs {
###################
    my $self = shift;
    my %args = &filter_input(\@_,-args=>'run1,run2');
    my $run1 = $args{-run1};
    my $run2 = $args{-run2};
    my $poor_threshold   = $args{-poor_threshold} || 100;           ## threshold quality to ignore non-correlating wells
    my $pass_percentage  = $args{-pass_percentage} || 90;           ## percentage match for pass (or warnings generated)    

    my $runs = $args{-runs};
    if ($runs) { ($run1,$run2) = Cast_List(-list=>$runs,-to=>'array') }  ## allow passing of runs in an array or list
    my $quiet = shift;   ## suppress message feedback

    my $dbc = $self->{dbc};

    my $output = "/home/sequence/Trash/blast.out";  ## <TEMPORARY> ##

    my @wells = $dbc->Table_find('Clone_Sequence','Well',"WHERE FK_Run__ID=$run1",-distinct=>1);
    
    my %Run1 = &Table_retrieve($dbc,'Run,RunBatch,Equipment',['Run_Directory','Equipment_Name'],
				  "WHERE FK_RunBatch__ID=RunBatch_ID AND FK_Equipment__ID=Equipment_ID AND Run_ID = $run1");
    my %Run2 = &Table_retrieve($dbc,'Run,RunBatch,Equipment',['Run_Directory','Equipment_Name'],
			       "WHERE FK_RunBatch__ID=RunBatch_ID AND FK_Equipment__ID=Equipment_ID AND Run_ID = $run2");

    my $run1_name = $Run1{Run_Directory}[0];
    my $run1_equip = $Run1{Equipment_Name}[0];
    
    my $run2_name = $Run2{Run_Directory}[0];
    my $run2_equip = $Run2{Equipment_Name}[0]; 
    
    Message("Comparing runs $run1_name (on $run1_equip) vs $run2_name (on $run2_equip)") unless $quiet;
    my %Results;
    foreach my $well (@wells) {
		### run blast for each well one at a time ###
		my %well_results = %{ $self->blast_against(-pass_percentage=>$pass_percentage,-poor_threshold=>$poor_threshold,-run_id=>[$run1,$run2],-well=>$well,-output=>$output,-include=>'percent',-quiet=>1) };

		$Results{$well} = \%well_results;
		my $result = $well_results{Result};
		push(@{$Results{$result}},$well);
    }

    return %Results;
    
}

######################################################
# Correlate 2 Reads (requires both run_ids and wells) 
#  (this is useful for QA purposes)
#
# Return: \%hash with keys:  Result = match result;  Message = text message containing info regarding match.
###################
sub blast_against {
###################
    my $self = shift;
    my %args = &filter_input(\@_,-args=>'run_id,well',-mandatory=>'run_id,well');
    my $run_id = $args{-run_id};                  ## list (or array) of runs to compare
    my $well   = $args{-well};                    ## optional well specification (defaults to current well || 'A01')
    my $output = $args{-output} || $args{-append} || '$URL_temp_dir/QA_blast_test.txt';  ## output file for blast results
    my $append = $args{-append};                  
    my $quiet  = $args{-quiet} || 0;              ## suppress all messages except problems..
    my $blast_path = "/home/sequence/Trash/blast2.2.10/bin";
    my $threshold = $args{-poor_threshold} || 0;     ## threshold quality to ignore non-correlating wells
    my $good      = $args{-pass_percentage} || 90;           ## percentage match for pass (or warnings generated)
    
    my ($run1,$run2,$well1,$well2);
    ## basic input verification ##
    if (ref($run_id) eq 'ARRAY') {          ## specify two runs in an array
	$run1 = $run_id->[0];
	$run2 = $run_id->[1];
    } elsif ($self->{run_id} && $run_id) {  ## specify one run (to compare with current run_id) 
	$run1 = $self->{run_id};
	$run2 = $run_id;
    }    
    else { 
	Message("function caller(0) requires 2 run_id ($run1-$run2;$well1-$well2) / well pairs") unless $quiet;
	return;
    }
    
    ## Establish wells to use ## 
    if (ref($well) eq 'ARRAY') {
	$well1 = $well->[0];
	$well2 = $well->[1];
    } elsif ($self->{well} && $well) {
	$well1 = $self->{run_id};
	$well2 = $run_id;
    } else { 
	$well1 = $self->{well} || $well || 'A01';
	$well2 = $well1;
    } 
    
    Message("Runs: $run1 $run2;  Wells: $well1 $well2") unless $quiet;

    ## generate temporary files to store sequence information to enable bl2seq execution ##
    my $file1 = "$URL_temp_dir/QA_test1.tmp";
    my $file2 = "$URL_temp_dir/QA_test2.tmp";
    
    my $blast_command = "$blast_path/bl2seq -i $file1 -j $file2 -o $output -p blastn";
    my $blast_output;

    ## extract trace names based on run information
    my %Read1 = &Table_retrieve($self->{dbc},'Clone_Sequence',['Sequence','Quality_Length'],"WHERE FK_Run__ID = $run1 AND Well = '$well1'");
    my $sequence1 = $Read1{Sequence}[0];

    my %Read2 = &Table_retrieve($self->{dbc},'Clone_Sequence',['Sequence','Quality_Length'],"WHERE FK_Run__ID = $run2 AND Well = '$well2'");
    my $sequence2 = $Read2{Sequence}[0];
    
    if ($append) {
	open(F1,">>$file1") or die "Cannot append file : $file1; ($!)";
    } else {
	open(F1,">$file1") or die "Cannot open file : $file1; ($!)";
    }
    print F1 ">$run1 $well1\n$sequence1\n";
    close(F1);

    if ($append) {
	open(F2,">>$file2") or die "Cannot append file : $file2; ($!)";
    } else {
	open(F2,">$file2") or die "Cannot open file : $file2; ($!)";
    }
    print F2 ">$run2 $well2\n$sequence2\n";
    close(F2);
  
    my $trace1 = '';     
    my $trace2 = '';     
    
    ### perform blast between 2 reads ###
    my $fback = `$blast_command`;
	unlink $file1;
	unlink $file2;
    Message("B:$blast_command") unless  $quiet;
    Message("Output in $output\n") unless $quiet;

    ### parse output -> summary file
    my $Blast_results = Bio::Tools::BPbl2seq->new(-file => $output);
    my $q1 = $Read1{Quality_Length}[0];
    my $q2 = $Read2{Quality_Length}[0];

    my $message;  ## store messages (ignored mismatch due to poor quality in at least one well)
    my $result;
    my $percent;
    if (defined $Blast_results->{_current_sbjct}) {    ## this seems to be returned when a match of some kind is found ## 
	my $hsp = $Blast_results->next_feature;

#	if (defined $hsp) {
	$percent = $hsp->percent;

	if ($percent > $good) {                        ## percentage match exceeds specified ($good) threshold
	    $message = "Well $well. ($percent %) Q: $q1; $q2";
	    $result  = 'match';
	} else {                                       ## match falls below specified threshold
	    #Message("Warning: Only $percent PERCENT match for Well $well.  Q: $q1; $q2");
	    $message = "Only $percent PERCENT match for Well $well.  Q: $q1; $q2";
	    $result = 'warning';
	}
    } else {                                           ## NO MATCH ##
	if ($q1 < $threshold || $q2 < $threshold) {    ## ignore since quality is too poor to consider reliable
	    #Message("No match for well $well.  OK due to poor quality (< $threshold) in one or more wells ($q1; $q2)");
	    $message = "No match for well $well.  OK due to poor quality (< $threshold) in one or more wells ($q1; $q2)";
	    $result = 'poor';
	} else {                                       ## error - since reliable reads result in no match ##
	    #Message("Warning: No match for Well $well. Q: $q1; $q2");
	    $message = "No match for Well $well. Q: $q1; $q2";
	    $result = 'fail';
	}
    }
    ###############################################################################################
    ## Need to explicitly kill the object otherwise the nubmer of open filehandles exeeds limit
    ## Required the addition of DESTROY destructor to Bio::Tools::BPbl2seq
    $Blast_results->DESTROY;
    ###############################################################################################
    
    ### send summary -> lab administrators if warning generated (suppress repeat warnings ?)
    my %Results;
    $Results{Message} = $message;  ## return message string
    $Results{Percent} = $percent;
    $Results{Result}  = $result;   ## return match result
    return \%Results;
}

############################################################
# used in sequence analysis to blast read sequence against contamination sequence
#
#################
sub parse_blastall {
#################
   
    my %args = &filter_input(\@_,-args=>'file');
    my $file = $args{-file};
    my $e_threshold = $args{'-E_threshold'} || '1e-1';
    my $score_threshold = $args{'-score_threshold'} || 0;
    
    my $E_value_string = 'Score';

    my $well = '';
    my $found = 0;
    my $matches = 0;

    my ($name,$results);
    my %ri;
    my %Blast_results;
    open(SCREEN, "$file") or print "Error opening $file";
    while (<SCREEN>) {
	my $line = $_;
	if ($line=~/Query=\s+(\S+)/) {
	    my $clone = $1;
	    $clone=~s/$ri{'chemcode'}//;
	    if ($clone=~/$ri{'library'}(\S*)([A-P]{1}\d{2})[\._]/) {
		$well = $2; 
		$found=1;
	    }
	}
	elsif ($found && ($line=~/$E_value_string/)) {
	    $found = 0;
	    if ($line=~/No Hits/) {next;}
	    $line=<SCREEN>;  ## Skip at least one more line... 		
	    $line=<SCREEN>;  ## Skip at least one more line... 		
	    while ($line =~ /^\s+/) {$line=<SCREEN>;}
	    my $prob = 1;  
	    my $score = 0;  
	    if ($line=~/\.\.\.\s+(\d+)\s+(\S+)/) {$score =$1; $prob = $2;}
	    if (($prob >= $e_threshold) || ($score < $score_threshold)) { next;}
	    
	    $line=<SCREEN>;		
	    while ($line =~ /^\s+/) {$line=<SCREEN>;}
	    
	    my $c_name;
	    if ($line=~/^[\>](.*)/) { $c_name = $1;}
	    else { $c_name = $name; }
	    $results .= "Run$ri{'sequence_id'} $well : Score=$score; E=$prob.\n";
	    $matches++;
	    $Blast_results{contaminant}[$matches] = $c_name;
	    $Blast_results{score}[$matches] = $score;
	    $Blast_results{probability}[$matches] = $prob;
	    $Blast_results{well}[$matches] = $well;   
	} else {next;}
    }  
    close(SCREEN);    
    $Blast_results{summary} = $results;
    $Blast_results{matches} = $matches;
    return \%Blast_results;
}

##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

###############
sub _unpack {
###############
#
# Unpack Binary values
#
    my $packed = shift;
    my %args = @_;
    
    my $bytes = $args{-bytes} || 1;       ## number of bytes allocated for value 
    my $index = $args{-index} || 0;       ## index to retrieve (otherwise returns array)

    my @values;
    if ($bytes eq 1) {
	@values = unpack "C*", $packed;
    } elsif ($bytes eq 2) {
	@values = unpack "S*", $packed;
    } 
    
    if ($index) { return $values[$index] }
    else { return @values }
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

Ran Guin

Andy Chan

=head1 CREATED <UPLINK>

2003-08-22

=head1 REVISION <UPLINK>

$Id: Read.pm,v 1.9 2004/09/08 23:31:50 rguin Exp $ (Release: $Name:  $)

=cut


return 1;
