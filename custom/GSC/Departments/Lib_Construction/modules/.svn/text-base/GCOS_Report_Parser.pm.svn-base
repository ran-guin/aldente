###################################################################################################################################
# GCOS_Report_Parser.pm
#
# Customized function code for reading affymetrix report files
#
###################################################################################################################################
package Lib_Construction::GCOS_Report_Parser;

### Reference to standard Perl modules
use strict;
use CGI qw(:standard);
use DBI;
use Data::Dumper;
use Storable;


### Reference to alDente modules
use alDente::SDB_Defaults;
use SDB::CustomSettings;
use SDB::DBIO;
use RGTools::RGIO;
use RGTools::Object;

### Global variables
use vars qw($user $bin_home $Connection $project_dir %Configs);

### Hash that maps from header names to field names
my %header_hash;
$header_hash{Mapping}{'Called Gender'} = 'Called_Gender';
$header_hash{Mapping}{'SNP Call'} = 'SNP_Call_Percent';
$header_hash{Mapping}{'AA Call'} = 'AA_Call_Percent';
$header_hash{Mapping}{'AB Call'} = 'AB_Call_Percent';
$header_hash{Mapping}{'BB Call'} = 'BB_Call_Percent';
$header_hash{Mapping}{'MCR'} = 'QC_MCR_Percent';
$header_hash{Mapping}{'MDR'} = 'QC_MDR_Percent';
$header_hash{Mapping}{'AFFX-5Q-123'} = 'QC_AFFX_5Q_123';
$header_hash{Mapping}{'AFFX-5Q-456'} = 'QC_AFFX_5Q_456';
$header_hash{Mapping}{'AFFX-5Q-789'} = 'QC_AFFX_5Q_789';
$header_hash{Mapping}{'AFFX-5Q-ABC'} = 'QC_AFFX_5Q_ABC';


########################
# resolve the report file into file that contains report of single experiment and that is named
# return hash ref keyed by file name, value is array ref of single exp (hash ref keyed by project, library, run_name and content)
#######################
sub resolve_report {
#######################
  my %args = @_;
  my $file_name = $args{-filename};
  my $run_directory = $args{-run_directory};  # target run directories. if not found, no rewrite
  my $dbc = $args{-dbc} || $Connection;

  my @run_dirs = split (",", $run_directory);
  my %run_dirs_hash;
  foreach my $run (@run_dirs){
    $run_dirs_hash{$run} = 1;
  }

  my $assay_type;
  my %data;

  my $in_block = 0;
  my %run_names; # to track multiple mapping assays in one file

  my @lines;

  my $found = 0;

  if (open (my $FH, $file_name)){# or die "cannot open $file_name: $!";
    while (<$FH>){
      my $line = $_;
      push (@lines, $line);
      $line = &chomp_edge_whitespace($line);
      if ($line =~ /mapping array report/i){
	$assay_type = "Mapping";
      }
      elsif ($line =~ /expression report/i){
	$assay_type = "Expression";
      }

      if ($assay_type eq 'Mapping'){
	
	if ($line =~ /^\s*$/){
	  $in_block = 0;
	}
	elsif ($line =~ /^CEL Data/){
	  $in_block = 1;
	  next;
	}
	elsif ($in_block && $line =~ /(\S+)\t+\S+/){
	  my $experiment_name = $1;
	  if (exists $run_dirs_hash{$experiment_name}){
	    $found = 1;
	  }
	  $run_names{$experiment_name} = 1;
	}
	
      }

    }
    close $FH;
  }else{
    Message("Error: cannot open $file_name: $!");
  }

  my %return;
  my @return_array;
  #### Expression assay ##################
  if($assay_type eq 'Expression'){
    my $results = &read_expression_file(-filename=>$file_name);
    my $run_name = $results->{Experiment_Name};
    if (exists $run_dirs_hash{$run_name}){
      $found = 1;
    }
    my ($project, $library) = _find_project_library(-dbc=>$dbc, -run_name=>$run_name);

    my %exp;
    $exp{project} = $project;
    $exp{library} = $library;
    $exp{run_name} = $run_name;
    $exp{content} = join ("", @lines);
    push (@return_array, \%exp);

  } # end expression file

  #### Mapping assay ##################
  elsif($assay_type eq 'Mapping'){

    foreach my $run_name (keys %run_names){
      # find out project and library
      my ($project, $library) = _find_project_library(-dbc=>$dbc, -run_name=>$run_name);
      # file content
      my @new_lines;
      foreach my $line (@lines){
	if ($line =~ /Report File Name/){
	  $line =~ s/Report.+\.RPT/Report File Name - $run_name\.RPT/;
	  push (@new_lines, $line);
	}
	else {
	  my $found = 0;
	  foreach my $key (keys %run_names){
	    if ($line =~ /$key/ && $key ne $run_name) { # other runs
	      $found = 1;
	    }
	  }
	  if (!$found){
	    push (@new_lines, $line);
	  }
	}
      }
      my %exp;
      $exp{project} = $project;
      $exp{library} = $library;
      $exp{run_name} = $run_name;
      $exp{content} = join ("", @new_lines);
      push (@return_array, \%exp);
    } # end all exps

  } # end mapping file

  $return{$file_name} = \@return_array;
  if (!$found){
    %return = ();
  }
  return (\%return);

}




####################
sub rewrite_report {
####################
  my %args = @_;
  my $data = $args{-data}; # return value of resolve_report
  my $run_directory = $args{-run_directory};  # target run directories. if not found, no rewrite
  my $debug = $args{-debug}; # if debug, write to trash
  my $force = $args{-force}; # overwirte old report
  my $dbc = $args{-dbc} || $Connection;

  my @run_dirs = split (",", $run_directory);
  my %run_dirs_hash;
  foreach my $run (@run_dirs){
    $run_dirs_hash{$run} = 1;
  }

  my %return_value;

  foreach my $file (keys %$data){
    my $dir;
    my $exp_count = 0;
    my %return;
    my @exps = @{$data->{$file}};
    foreach my $exp (@exps){
      my $project = $exp->{project};
      my $library = $exp->{library};
      my $run_name = $exp->{run_name};
      my $content = $exp->{content};
      if($dbc->{dbase} eq 'sequence' && $project && $library && !$debug) { # production database, normal case, increment count
	$dir = $project_dir."/".$project."/".$library."/AnalyzedData/";

	if (exists $run_dirs_hash{$run_name} || (scalar (keys %run_dirs_hash)) == 0){

	  my $full_file_name = $dir."/".$run_name.".RPT";
	  if ((!(-e $full_file_name)) || $force){
	    if ((-e $full_file_name) && $force){
	      Message("$full_file_name exists, overwriting");
	    }else{
	      Message("$full_file_name does not exist, creating");
	    }
	    if (open (my $FH, ">$full_file_name")){# or die "cannot open $full_file_name: $!";
	      print $FH $content;
	      close $FH;
	      $return{$full_file_name} = $run_name;
	      $exp_count ++;
	    }else{
	      Message("Error: cannot open $full_file_name:$!");
	    }
	  }elsif (-e $full_file_name){
	    Message("Warning: $full_file_name exists, skipped");
	    $exp_count ++;
	  }

	}

      }elsif($dbc->{dbase} eq 'sequence' && !$debug){ # production database, exp may not be tracked, increment count
	$dir = $Configs{Data_home_dir}."/Trash/GCOS_test/Reports/";
	Message("Warning: cannot find project or library for $run_name, writing to $dir");

	if (exists $run_dirs_hash{$run_name} || (scalar (keys %run_dirs_hash)) == 0){
	  my $full_file_name = $dir."/".$run_name.".RPT";
	  if (open (my $FH, ">$full_file_name")){# or die "cannot open $full_file_name: $!";
	    print $FH $content;
	    close $FH;

	    $return{$full_file_name} = $run_name;
	    $exp_count ++;
	  }else{
	    Message("Error: cannot open $full_file_name:$!");
	  }

	}

      }else{ # non-production or debug, not increment
	$dir = $Configs{Data_home_dir}."/Trash/GCOS_test/Reports/";
	Message("Warning: non-production or debug, writing to $dir");
	if (exists $run_dirs_hash{$run_name} || (scalar (keys %run_dirs_hash)) == 0){
	  my $full_file_name = $dir."/".$run_name.".RPT";
	  if (open (my $FH, ">$full_file_name")){# or die "cannot open $full_file_name: $!";
	    print $FH $content;
	    close $FH;
	    $return{$full_file_name} = $run_name;
	  }else{
	    Message("Error: cannot open $full_file_name:$!");
	  }
	}
      }

    } # end writing files 
    $return_value{$file}{data} = \%return;
    # if all exps are accounted for, mark archive file as done
    if ($exp_count == scalar @exps){
      $return_value{$file}{status} = 1; ## this file is done
    }else{
      $return_value{$file}{status} = 0;
    }

  }
  return \%return_value;

}



###########################
# Function to read a report file and insert data into the database
###########################
sub process_report_file {
###########################
    my %args = &filter_input(\@_,-args=>'run_name,filename,dbc',-mandatory=>'run_name,filename,dbc');

    my $run_name = $args{-run_name};
    my $filename = $args{-filename};
    my $dbc = $args{-dbc} || $Connection;
    
    # first, retrieve the array type (Mapping or Expression), and the genechip type (Mapping50K_Hind240, Mapping50K_Xba240, Mapping250K_Nsp, HG_U133plus2, etc).
    my @array_info = $dbc->Table_find("Run,Array,Genechip,Genechip_Type","Array_Type,Genechip_Type.Genechip_Type_Name,Run_ID","WHERE Run.FK_Plate__ID = Array.FK_Plate__ID AND Array.FK_Microarray__ID=Genechip.FK_Microarray__ID AND FK_Genechip_Type__ID=Genechip_Type_ID AND Run_Directory = '$run_name'");
    my ($array_type,$genechip_type,$run_id) = split ',',$array_info[0];

    # parse accordingly
    my $results = &read_report_file(-filename=>$filename,-assay_type=>$array_type);
    my $analysis_datetime = $results->{'Report_Date'};
    delete $results->{'Report_Date'};
    delete $results->{'Experiment_Name'};
    delete $results->{'Probe_Array_Type'};

    # insert into the appropriate GenechipAnalysis tables
    # GenechipMapAnalysis for Mapping chip runs
    my @fields = ();
    my @values = ();


    if($run_id){
      push (@fields, "FK_Run__ID");
      push (@values, "$run_id");

      $dbc->Table_update_array("Run",['Run_Status'],['Analyzed'],"WHERE Run_ID=$run_id",-autoquote=>1);

      if ($array_type eq 'Mapping') {
	push(@fields, keys %{$results});
	push(@values,values %{$results});

	# check if this run has been analyzed
	my @gma_ids = $dbc->Table_find("GenechipMapAnalysis,Run","GenechipMapAnalysis_ID","WHERE FK_Run__ID = Run_ID AND Run_Directory='$run_name'");
	my ($gma_id) = split ',',$gma_ids[0];
	if($gma_id){
	  $dbc->Table_update_array("GenechipMapAnalysis", \@fields, \@values, "WHERE GenechipMapAnalysis_ID = $gma_id", -autoquote=>1);
	}else{
	  $dbc->smart_append(-tables=>"GenechipMapAnalysis",-fields=>\@fields,-values=>\@values,-autoquote=>1);
	}
      }
      elsif ($array_type eq 'Expression') {
	# grab non Housekeeping Controls and/or Spike Controls values
	foreach my $key (keys %{$results}) {
	    if ($key ne 'Housekeeping_Controls' && $key ne 'Spike_Controls') {
		push (@fields, $key);
		push (@values, $results->{$key});
	    }
	}

	# check if this run has been analyzed
	my @gea_ids = $dbc->Table_find("GenechipExpAnalysis,Run","GenechipExpAnalysis_ID","WHERE FK_Run__ID = Run_ID AND Run_Directory='$run_name'");
	my ($gea_id) = split ',',$gea_ids[0];

	my $newid;

	if($gea_id){ #update
	  $dbc->Table_update_array("GenechipExpAnalysis", \@fields, \@values, "WHERE GenechipExpAnalysis_ID = $gea_id", -autoquote=>1);
	  $newid = $gea_id;
	}else{
	  my $newids_hash = $dbc->smart_append(-tables=>"GenechipExpAnalysis",-fields=>\@fields,-values=>\@values,-autoquote=>1);
	  $newid = $newids_hash->{"GenechipExpAnalysis"}{newids}[0];
	}
	
        # grab Probe Set Value data
	my @probe_set_fields =  qw(FK_Probe_Set__ID FK_GenechipExpAnalysis__ID Probe_Set_Type);
	my @stat_fields = qw(Sig5 Det5 SigM DetM Sig3 Det3 SigAll Sig35);
	my %probe_set_info;
	my $index = 1;
	# get housekeeping control data
	foreach my $probe_set (keys %{$results->{'Housekeeping_Controls'}}) {
	    my ($probe_set_id) = $dbc->Table_find("Probe_Set","Probe_Set_ID","WHERE Probe_Set_Name='$probe_set'");

	    if (!$probe_set_id){ # this is a new probe set id, add it
	      $dbc->dbh()->do("insert into Probe_Set (Probe_Set_Name) values ('$probe_set')");
	      ($probe_set_id) = $dbc->Table_find("Probe_Set","Probe_Set_ID","WHERE Probe_Set_Name='$probe_set'");
	    }

	    my @probe_array = ($probe_set_id,$newid,'Housekeeping Control');
	    foreach my $stat (@stat_fields) {
		push (@probe_array, $results->{'Housekeeping_Controls'}{$probe_set}{$stat});
	    }
	    $probe_set_info{$index} = \@probe_array;
	    $index++;
	}
	# get spike control data
	foreach my $probe_set (keys %{$results->{'Spike_Controls'}}) {
	    my ($probe_set_id) = $dbc->Table_find("Probe_Set","Probe_Set_ID","WHERE Probe_Set_Name='$probe_set'");
	    if (!$probe_set_id){ # this is a new probe set id, add it
	      $dbc->dbh()->do("insert into Probe_Set (Probe_Set_Name) values ('$probe_set')");
	      ($probe_set_id) = $dbc->Table_find("Probe_Set","Probe_Set_ID","WHERE Probe_Set_Name='$probe_set'");
	    }
	    my @probe_array = ($probe_set_id,$newid,'Spike Control');
	    foreach my $stat (@stat_fields) {
		push (@probe_array, $results->{'Spike_Controls'}{$probe_set}{$stat});
	    }
	    $probe_set_info{$index} = \@probe_array;
	    $index++;
	}

	# delete from Probe_Set_Value anything of this run ($newid)
	my @probe_set_value_ids = $dbc->Table_find("Probe_Set_Value","Probe_Set_Value_ID","WHERE FK_GenechipExpAnalysis__ID = $newid");
	if (scalar (@probe_set_value_ids) > 0) {
	  $dbc->delete_records(-table=>"Probe_Set_Value",-dfield=>"Probe_Set_Value_ID",-id_list=>join(',',@probe_set_value_ids), -quiet=>1);
	}

	$dbc->smart_append(-tables=>"Probe_Set_Value",-fields=>[@probe_set_fields,@stat_fields],-values=>\%probe_set_info,-autoquote=>1);
	
      }
    }
    else {
      Message ("Warning: no valid run for $run_name");
    }
}


####################
# Function to link report files into project directory
#
#####################
sub link_report {
#####################
  my %args = &filter_input(\@_,-args=>'dbc,filename',-mandatory=>'filename,dbc');
  my $filename = $args{-filename}; # base report file name (not full path)
  my $dbc = $args{-dbc} || $Connection;
  my $archive_dir = $args{-archive_dir} || $Configs{'archive_dir'}."/GCOS/01/GCLims/Data/";

  my $run_dir = $filename;
  $run_dir =~ s/\.RPT//;

  # find project, library from filename
  my %run_data = $dbc->Table_retrieve("Run, Plate, Library, Project",["Project_Path", "Library_Name"],"WHERE Run.Run_Directory = '$run_dir' and Run.FK_Plate__ID = Plate_ID and Plate.FK_Library__Name = Library_Name and Library.FK_Project__ID = Project_ID");
  my $project = $run_data{Project_Path}->[0];
  my $library = $run_data{Library_Name}->[0];

  my $symlink_dir = $project_dir."/".$project."/".$library."/AnalyzedData/".$run_dir."/";

  # link
  my $command = "ln -s ".$archive_dir.$filename." ".$symlink_dir;
  &try_system_command($command);

}





##################
# Function to determine what function to call to parse a report file
# PRE: The filename of the report file 
# RETURN: A hash reference of the data in the file, with the keys being the field names, or undef if there has been an error
##################
sub read_report_file {
##################
    my %args = &filter_input(\@_,-args=>'filename,assay_type',-mandatory=>'filename,assay_type');

    my $filename = $args{-filename};          # (Scalar} Filename to read. 
    my $assay_type = $args{-assay_type};       # (Scalar) Assay Type of the chip. One of Expression or Mapping

    my $results;
    if ($assay_type =~ /Expression/i) {
	$results = &read_expression_file(-filename=>$filename);
    }
    elsif ($assay_type =~ /Mapping/i) {
	$results = &read_mapping_file(-filename=>$filename);
    }
    else {
	$results = undef;
    }

    return $results;
}


###########################
# Function to parse a Mapping RPT file
###########################
sub read_expression_file {
###########################
    my %args = &filter_input(\@_,-args=>'filename',-mandatory=>'filename');

    my $filename = $args{-filename};
    # open file
    open(INF, "$filename");
    my @lines = <INF>;
    close INF;

    # parse out header information: 
    #
    # find line numbers: 
    #

    my $experiment_name;
    my $probe_array_type;
    my $linenum = 0;
    my $housekeeping_line;
    my $spike_line;
    my $report_date;

    my $algorithm;
    my $probe_pair_thr;
    my $controls;
    my $alpha1;
    my $alpha2;
    my $tau;
    my $tgt;
    my $noise_RawQ;
    my $scale_factor;
    my $norm_factor;
    my $total_probe_sets;
    my $present_probe_sets;
    my $present_probe_sets_percent;
    my $absent_probe_sets;
    my $absent_probe_sets_percent;
    my $marginal_probe_sets;
    my $marginal_probe_sets_percent;
    my $avg_P_signal;
    my $avg_A_signal;
    my $avg_M_signal;
    my $avg_signal;

    my $background_avg;
    my $background_std;
    my $background_min;
    my $background_max;
    my $noise_avg;
    my $noise_std;
    my $noise_min;
    my $noise_max;
    my $corner_plus_avg;
    my $corner_plus_count;
    my $corner_minus_avg;
    my $corner_minus_count;
    my $central_minus_avg;
    my $central_minus_count;

    # clean up lines
    foreach (@lines) {
	$_ = &chomp_edge_whitespace($_);
    }

    foreach my $line (@lines) {

      if ($line =~ /^Filename/){
	(undef,$experiment_name) = split /\t+/,$line;
	$experiment_name =~ s/\.CHP$//;
      }

      if ($line =~ /^Probe Array Type/){
	(undef,$probe_array_type) = split /\t+/,$line;
      }

	# find line where Housekeeping Controls start
	if ($line =~ /^Housekeeping Controls/) {
	    $housekeeping_line = $linenum;
	}	
        # find line where Spike Controls start
	elsif ($line =~ /^Spike Controls/) {
	    $spike_line = $linenum;
	}
	# find report date
	elsif ($line =~ /^Date:/) {
	    (undef,$report_date) = split /\t+/,$line;
	    $report_date =~ s/\//\-/g;
	}
	elsif ($line =~ /^Algorithm:/) {
	    (undef,$algorithm) = split /\t+/,$line;
	}
	elsif ($line =~ /^Probe Pair Thr:/) {
	    (undef,$probe_pair_thr) = split /\t+/,$line;
	}
	elsif ($line =~ /^Controls:/) {
	    (undef,$controls) = split /\t+/,$line;
	}
	elsif ($line =~ /^Alpha1:/) {
	    (undef,$alpha1) = split /\t+/,$line;
	}
	elsif ($line =~ /^Alpha2:/) {
	    (undef,$alpha2) = split /\t+/,$line;
	}
	elsif ($line =~ /^Tau:/) {
	    (undef,$tau) = split /\t+/,$line;
	}
	elsif ($line =~ /^TGT Value:/) {
	    (undef,$tgt) = split /\t+/,$line;
	}
	elsif ($line =~ /^Noise \(RawQ\):/) {
	    (undef,$noise_RawQ) = split /\t+/,$line;
	}
	elsif ($line =~ /^Scale Factor \(SF\):/) {
	    (undef,$scale_factor) = split /\t+/,$line;
	}
	elsif ($line =~ /^Norm Factor \(NF\):/) {
	    (undef,$norm_factor) = split /\t+/,$line;
	}
	elsif ($line =~ /^Total Probe Sets:/) {
	    (undef,$total_probe_sets) = split /\t+/,$line;
	}
	elsif ($line =~ /^Number Present:/) {
	    (undef,$present_probe_sets,$present_probe_sets_percent) = split /\t+/,$line;
	}
	elsif ($line =~ /^Number Absent:/) {
	    (undef,$absent_probe_sets,$absent_probe_sets_percent) = split /\t+/,$line;
	}
	elsif ($line =~ /^Number Marginal:/) {
	    (undef,$marginal_probe_sets,$marginal_probe_sets_percent) = split /\t+/,$line;
	}
	elsif ($line =~ /^Average Signal \(P\):/) {
	    (undef,$avg_P_signal) = split /\t+/,$line;
	}
	elsif ($line =~ /^Average Signal \(A\):/) {
	    (undef,$avg_A_signal) = split /\t+/,$line;
	}
	elsif ($line =~ /^Average Signal \(M\):/) {
	    (undef,$avg_M_signal) = split /\t+/,$line;
	}
	elsif ($line =~ /^Average Signal \(All\):/) {
	    (undef,$avg_signal) = split /\t+/,$line;
	}
	elsif ($line =~ /^Background:/) {
	    (undef,$background_avg,undef,$background_std,undef,$background_min,undef,$background_max) = split /[\s\t]+/,$lines[$linenum+1];
	}
	elsif ($line =~ /^Noise:/) {
	    (undef,$noise_avg,undef,$noise_std,undef,$noise_min,undef,$noise_max) = split /[\s\t]+/,$lines[$linenum+1]; 
	}
	elsif ($line =~ /^Corner\+/) {
	    (undef,$corner_plus_avg,undef,$corner_plus_count) = split /[\s\t]+/,$lines[$linenum+1]; 
	}
	elsif ($line =~ /^Corner\-/) {
	    (undef,$corner_minus_avg,undef,$corner_minus_count) = split /[\s\t]+/,$lines[$linenum+1]; 	    
	}
	elsif ($line =~ /^Central\-/) {
	    (undef,$central_minus_avg,undef,$central_minus_count) = split /[\s\t]+/,$lines[$linenum+1]; 
	}

	$linenum++;
    }

    my %field_hash;
    $field_hash{Housekeeping_Controls} = {};
    _read_csv_portion($housekeeping_line,\@lines,$field_hash{Housekeeping_Controls},'Expression');
    $field_hash{Spike_Controls} = {};
    _read_csv_portion($spike_line,\@lines,$field_hash{Spike_Controls},'Expression');

    $field_hash{'Experiment_Name'} = $experiment_name;
    $field_hash{'Probe_Array_Type'} = $probe_array_type;
    $field_hash{'Report_Date'} = $report_date;
    $field_hash{'Algorithm'} =  $algorithm;
    $field_hash{'Probe_Pair_Thr'} = $probe_pair_thr;
    $field_hash{'Controls'} = $controls;
    $field_hash{'Alpha1'} = $alpha1;
    $field_hash{'Alpha2'} = $alpha2;
    $field_hash{'Tau'} = $tau;
    $field_hash{'TGT'} = $tgt;
    $field_hash{'Noise_RawQ'} = $noise_RawQ;
    $field_hash{'Scale_Factor'} = $scale_factor;
    $field_hash{'Norm_Factor'} = $norm_factor;
    $field_hash{'Total_Probe_Sets'} = $total_probe_sets;
    $field_hash{'Present_Probe_Sets'} = $present_probe_sets;
    $field_hash{'Present_Probe_Sets_Percent'} = $present_probe_sets_percent;
    $field_hash{'Absent_Probe_Sets'} = $absent_probe_sets;
    $field_hash{'Absent_Probe_Sets_Percent'} = $absent_probe_sets_percent;
    $field_hash{'Marginal_Probe_Sets'} = $marginal_probe_sets;
    $field_hash{'Marginal_Probe_Sets_Percent'} = $marginal_probe_sets_percent;
    $field_hash{'Avg_P_Signal'} = $avg_P_signal;
    $field_hash{'Avg_A_Signal'} = $avg_A_signal;
    $field_hash{'Avg_M_Signal'} = $avg_M_signal;
    $field_hash{'Avg_Signal'} = $avg_signal;

    $field_hash{'Avg_Background'} = $background_avg;
    $field_hash{'Std_Background'} = $background_std;
    $field_hash{'Min_Background'} = $background_min;
    $field_hash{'Max_Background'} = $background_max;
    $field_hash{'Avg_Noise'} = $noise_avg;
    $field_hash{'Std_Noise'} = $noise_std;
    $field_hash{'Min_Noise'} = $noise_min;
    $field_hash{'Max_Noise'} = $noise_max;
    $field_hash{'Avg_CornerPlus'} = $corner_plus_avg;
    $field_hash{'Count_CornerPlus'} = $corner_plus_count;
    $field_hash{'Avg_CornerMinus'} = $corner_minus_avg;
    $field_hash{'Count_CornerMinus'} = $corner_minus_count;
    $field_hash{'Avg_CentralMinus'} = $central_minus_avg;
    $field_hash{'Count_CentralMinus'} = $central_minus_count;

    return \%field_hash;
}

###########################
# Function to parse an Expression RPT file
###########################
sub read_mapping_file {
###########################
    my %args = &filter_input(\@_,-args=>'filename',-mandatory=>'filename');
    
    my $filename = $args{-filename};
    # open file
    open(INF, "$filename");
    my @lines = <INF>;
    close INF;

    # parse out header information: Total_SNPs, Total_QC_Probes, and Date
    # find line numbers of the SNP Performance, QC performance, and Shared SNP patterns
    my $total_SNP;
    my $total_QC_Probes;
    my $report_date;
    my $SNP_performance_line;
    my $QC_performance_line;
    my $shared_SNP_line;

    my $linenum = 0;
    foreach my $line (@lines) {
	$line = &chomp_edge_whitespace($line);
	# find report date
	if ($line =~ /^Date:/) {
	    (undef,$report_date) = split /\t+/,$line;
	    $report_date =~ s/\//\-/g;
	}
	# find total number of SNPs
	elsif ($line =~ /^Total number of SNPs:/) {
	    (undef,$total_SNP) = split "\t",$line;	    
	}
	# find total number of QC Probes
	elsif ($line =~ /^Total number of QC Probes:/) {
	    (undef,$total_QC_Probes) = split "\t",$line;
	}
	# find line where SNP performance area starts
	elsif ($line =~ /^SNP Performance/) {
	    $SNP_performance_line = $linenum;
	}
	# find line where QC performance area starts
	elsif ($line =~ /^QC Performance/) {
	    $QC_performance_line = $linenum;
	}
	# find line where Shared SNP patterns start
	elsif ($line =~ /^Shared SNP Patterns/) {
	    $shared_SNP_line = $linenum;
	}
	$linenum++;
    }

    my %field_hash;
    # read SNP,QC, and shared SNP areas of the file
    $field_hash{SNP_Performance} = {};
    _read_csv_portion($SNP_performance_line,\@lines,$field_hash{SNP_Performance},'Mapping');
    $field_hash{QC_Performance} = {};
    _read_csv_portion($QC_performance_line,\@lines,$field_hash{QC_Performance},'Mapping');
    $field_hash{Shared_SNP_Call} = {};
    _read_csv_portion($shared_SNP_line,\@lines,$field_hash{Shared_SNP_Call},'Mapping');

    # fill in other information from file
    $field_hash{Report_Date} = $report_date;
    $field_hash{Total_SNP} = $total_SNP;
    $field_hash{Total_QC_Probes} = $total_QC_Probes;

    # post process SNP, QC, and Shared_SNP_Call to collapse into a 1D set of data.
    foreach my $probe (keys %{$field_hash{SNP_Performance}}) {
	foreach my $stat (keys %{$field_hash{SNP_Performance}{$probe}}) {
	    my $value = $field_hash{SNP_Performance}{$probe}{$stat};
	    $field_hash{"$stat"} = $value;
	}
    }
    delete $field_hash{SNP_Performance};
    foreach my $probe (keys %{$field_hash{QC_Performance}}) {
	foreach my $stat (keys %{$field_hash{QC_Performance}{$probe}}) {
	    my $value = $field_hash{QC_Performance}{$probe}{$stat};
	    $field_hash{"$stat"} = $value;
	}
    }
    delete $field_hash{QC_Performance};
    foreach my $probe (keys %{$field_hash{Shared_SNP_Call}}) {
	foreach my $stat (keys %{$field_hash{Shared_SNP_Call}{$probe}}) {
	    my $value = $field_hash{Shared_SNP_Call}{$probe}{$stat};
	    $field_hash{"$stat"} = $value;
	}
    }
    delete $field_hash{Shared_SNP_Call};

    return \%field_hash;
}

#########################
# Helper function to read a tab-delimited portion of a data file
# assume the Identifier field is the first field
#########################
sub _read_csv_portion {
#########################
    my ($linenum,$data,$dest_hash,$type) = @_;

    my $curr_line = $linenum + 1;
    my @headers = split /\t+/,$data->[$curr_line];
    foreach (@headers) {
	if ($_ =~ /Sig\(3\'\/5\'\)/) {
	    $_ = 'Sig35';
	}
	elsif ($_ =~ /Sig\(5\'\)/) {
	    $_ = 'Sig5';
	}
	elsif ($_ =~ /Sig\(3\'\)/) {
	    $_ = 'Sig3';
	}
	elsif ($_ =~ /Sig\(M\'\)/) {
	    $_ = 'SigM';
	}
	elsif ($_ =~ /Det\(5\'\)/) {
	    $_ = 'Det5';
	}
	elsif ($_ =~ /Det\(3\'\)/) {
	    $_ = 'Det3';
	}
	elsif ($_ =~ /Det\(M\'\)/) {
	    $_ = 'DetM';
	}
	elsif ($_ =~ /Sig\(all\)/) {
	    $_ = 'SigAll';
	}
    }

    $curr_line++;
    my $limit = 1000;
    my $count = 0;
    while ( ($count < $limit) && $data->[$curr_line] && ($data->[$curr_line] !~ /^[\-\_]+$/) && ($data->[$curr_line] !~ /^\s+$/) ) {
	my @values = split /\t+/,$data->[$curr_line];
	my $identifier = $values[0];
	
	my @other_values = @values[1..$#values];
	my @other_headers = @headers[1..$#headers];
	$dest_hash->{$identifier} = {};
	@{$dest_hash->{$identifier}}{@other_headers} = @other_values;
	
	_map_to_field($dest_hash->{$identifier},$header_hash{$type}) if (exists $header_hash{$type});
	$count++;
	$curr_line++;
    }
}


##########################
# Helper function to map headers to fields
##########################
sub _map_to_field {
##########################
    my ($target_hash,$header_map)  = @_;
    foreach my $key (keys %{$target_hash}) {
	if (exists $header_map->{$key}) {
	    my $value = $target_hash->{$key};
	    my $new_name = $header_map->{$key};
	    delete $target_hash->{$key};
	    $target_hash->{$new_name} = $value;
	}
    }
}

#######################################################
# given a run name, find project_path and library name
#######################################################
sub _find_project_library {
#######################################################
  my %args = @_;
  my $dbc = $args{-dbc} || $Connection;
  my $run_name = $args{-run_name};
  my %run_data = $dbc->Table_retrieve("Run, Plate, Library, Project",["Project_Path", "Library_Name"],"WHERE Run.Run_Directory = '$run_name' and Run.FK_Plate__ID = Plate_ID and Plate.FK_Library__Name = Library_Name and Library.FK_Project__ID = Project_ID");

  my $project = $run_data{Project_Path}->[0];
  my $library = $run_data{Library_Name}->[0];
  return ($project, $library);
}

return 1;
