#!/usr/local/bin/perl

use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
 
use SDB::DBIO;
use alDente::SDB_Defaults;
use Data::Dumper;

#my $data = &try_system_command("get_comment < /home/sage/data/Agencourt/processed/SM134_7.ab1/chromat_dir/SM134_7_H12.ab1");

use vars qw($testing $opt_ids $opt_groups $project_dir);
use Getopt::Long;
&GetOptions(
	    'ids=s'     => \$opt_ids,
	    'groups=s'  => \$opt_groups,
	    );

my $ids = $opt_ids;
my $groups = $opt_groups;

my $dbase = 'sequence';
my $host  = 'lims01';
my $user  = 'rguin';
my $pass;

my $dbc = SDB::DBIO->new(-dbase=>$dbase,-host=>$host,-user=>$user,-password=>$pass,-connect=>1);

unless ($ids || $groups) {
    print _usage();
    exit;
}

my $Group = {
    'Group 1 - 1/16 chemistry' => [25458,25459,25460,25461,16537,16538,16539,16540,20297,20298,20299,20300,22264,22265,22266,22267,22583, 22584,22585,22586,22623,22624,22625,22626],
    'Group 1 - 1/256 chemistry' => [33506,33505,33513,33502,33512,33515],

    'Group 2 - 1/16 chemistry' => [32602,32625,32616,32626,32631,32597],
    'Group 2 - 1/256 chemistry' => [33463,33458,33461,33459,33467,33471],

    'Group 3 - 1/16 chemistry' => [23267,23268,23270,23271,22062,22063,22064,22065,23300,23301,23302,23303,22683,22684,22685,22686,22746,22747,22748,22749,24956,24957,24958,24959],
    'Group 3 - 1/256 chemistry' => [33510,33504,33573,33503,33572,33514],
    
    'Group 4 - 1/16 chemistry' => [29468,28328],
    'Group 4 - 1/256 chemistry' => [33457,33465,33467],

    'Group 5 - 1/16 chemistry' => [24588,26415,26427,26430,26433,26436],
    'Group 5 - 1/256 chemistry' => [33466,33460,33469,33462,33464,33468],

    'Group 6 - 1/512 dilution' => [34057,34058,34060,34061],
    'Group 7 - 1/1024 dilution' => [34063,34064],  
    'Group 8 - 1/2560 dilution' => [34075,34076,34110,34111],
    
    'Group 9 - 1/16 BD Chemistry (GA000)' => [34169,34170,34171,34172,34173,34174],
    'Group 9 - 1/256 BD Chemistry' => [33346,33347,33348,33361,33362,33363,33364,33365,33366,33367,33368,33352,33353,33354,33375,33376,33377,33378,33379],

};

if ($ids) {
    my @list = split ',', $ids;
    $Group = { 'List' => \@list }
} elsif ($groups) {
    ## allow  more complicated input: -groups <label1>=<id_list1>:<label2>=<id_list2> ##
    print "parsing $groups.\n";
    $Group = {};
    my @group_list = split ':', $groups;
    foreach my $group_list (@group_list) {
	my ($label,$ids) = split '=', $group_list;
	print "$group_list -> $label ids: $ids\n";
	my @list = split ',', $ids;
	$Group->{$label} = \@list;
    }
}
print "Successful reads count (trimmed quality length >= 100 bps)\n";
print "Runs\tSuccessful Reads\tRate(%)\tGroup\n";
foreach my $key (sort keys %{$Group}) {
#    print "**" . '*'x(length($key) + 2) . "**\n";
#    print "** $key **\n";
#    print "**" . '*'x(length($key) + 2) . "**\n";
 #   my @id_list = $Group{$key};
 #   get_signal_strength($Group->{$key},$key);
    my $list = join ',', @{$Group->{$key}};
    my @data = &Table_find($dbc,'SequenceAnalysis,SequenceRun','successful_reads,Wells',"WHERE FK_SequenceRun__ID=SequenceRun_ID AND FK_Run__ID IN ($list)");
    my $total_sr = 0;
    my $total_wells = 0;
    my $runs = 0;
    foreach my $item (@data) {
	my ($sr,$wells) = split ',', $item;
	$total_sr += $sr;
	$total_wells += $wells;
	$runs++;
    }
    printf "$runs\t$total_sr / $total_wells\t%0.1f\t$key\n", 100*$total_sr/$total_wells;
}

exit;

###########################
sub get_signal_strength {
###########################
    my $ids = shift;
    my $key = shift;

    my $trimmed = 0;
    
    my @fields = ('Well','Project_Path','Library_Name','Run_ID','Run_Directory');
    if ($trimmed) {
	push(@fields,"CASE WHEN Quality_Length < 1 THEN '' ELSE MID(Run,Quality_Left+1,Quality_Length) END AS Run");
    } else {
	push(@fields,'Run');
    }

    my $cmd_path = "~/alDente/staden-linux-1-5-3/linux-bin";
    my $id_list = join ',', @$ids;
    my %run_details = &Table_retrieve($dbc,'Clone_Sequence,Run,SequenceRun,Plate,Library,Project',\@fields,
				      "WHERE FK_Run__ID=Run_ID AND FK_SequenceRun__ID=SequenceRuN_ID AND FK_Plate__ID=Plate_ID AND FK_Library__Name=Library_Name AND FK_Project__ID=Project_ID AND Run_Status = 'Analyzed' AND Run_ID IN ($id_list) AND Growth NOT IN ('No Grow') Order by Run_ID");
    my $total_count = 0;
    my ($total_A,$total_C,$total_G,$total_T) = (0,0,0,0);
    my ($total_A_count,$total_C_count,$total_G_count,$total_T_count,$total_N_count) = (0,0,0,0,0);
    my $index = 0;
    my %Wells;
    my %Run;
    while (defined $run_details{'Run_ID'}[$index]) {
	my $run_id = $run_details{'Run_ID'}[$index];
	my $well   = $run_details{'Well'}[$index];
	my $sequence     = $run_details{'Run'}[$index];
	$Run{"$run_id:$well"} = $sequence;
	if (defined $Wells{$run_id}) { push(@{$Wells{$run_id}},$well); $index++; next; }
	else {  $Wells{$run_id} = [$well]; } ## continue if first time for the run.. 
    }

    my %Finished;
    my $index = 0;
    my $read_count = 0;
    ## go through results again (this time, just once per run ...)
    while (defined $run_details{'Run_ID'}[$index]) {
	my $run_id = $run_details{'Run_ID'}[$index];
	
	if (defined $Finished{$run_id}) { $index++; next; }
	else {$Finished{$run_id} = 1 }
	
	my $project_path = $run_details{'Project_Path'}[$index];
	my $library = $run_details{'Library_Name'}[$index];
	my $run_name = $run_details{'Run_Directory'}[$index];
	my $project_path = $run_details{'Project_Path'}[$index];
	my $well         = $run_details{'Well'}[$index];
	$index++;
	
	my $directory = "$project_dir/$project_path/$library/AnalyzedData/$run_name/chromat_dir";
	# print "Dir: $directory\n";
	my @files = <$directory/*.ab*>;
	my $count = 0;
	my ($run_A,$run_C,$run_G,$run_T) = (0.0,0.0,0.0,0.0);
	my ($A_run_count, $G_run_count, $T_run_count, $C_run_count, $N_run_count) = (0,0,0,0,0);
	foreach my $file (@files) {
	    my $well;
	    my @valid_wells;
	    if ($file =~ /$directory\/$run_name\_([A-P]\d{2})/ ) {
		$well = $1;	
		@valid_wells = @{$Wells{$run_id}};
		## only include wells with valid Clone_Sequence records which are NOT No Grows...
	    } else {
		print "*** ERROR *** Unidentified file format ?: $file\n";
		next;
	    }
	    my $data = &try_system_command("$cmd_path/get_comment SIGN < $file");
	    my $sequence = $Run{"$run_id:$well"};
	    my ($A_count, $G_count, $T_count, $C_count, $N_count) = (0,0,0,0,0);
	    while ($sequence =~s/a//i) { $A_count++ }
	    while ($sequence =~s/g//i) { $G_count++ }
	    while ($sequence =~s/t//i) { $T_count++ }
	    while ($sequence =~s/c//i) { $C_count++ }
	    while ($sequence =~s/n//i) { $N_count++ }
	        
	    if ($data=~/SIGN=A=(\d+),C=(\d+),G=(\d+),T=(\d+)/) {
		my $A = $1;
		my $C = $2;
		my $G = $3;
		my $T = $4;
		chomp $data;
#		&Table_update_array($dbc,'Clone_Sequence',['Signal_Strength_A','Signal_Strength_C','Signal_Strength_T','Signal_Strength_G'],
#				    [$A,$C,$T,$G],"WHERE FK_Run__ID=$run_id AND Well = '$well'");
		
		unless ( grep /^$well$/, @valid_wells ) { 
		    print "(excluded $well)..\n"; 
		    next; 
		}

		print "$file\t$run_id:$well\n$data (AGTCN: $A_count $G_count $T_count $C_count $N_count)\n";		

		$run_A += $A*$A_count;
		$run_C += $C*$C_count;
		$run_G += $G*$G_count;
		$run_T += $T*$T_count;

		$A_run_count += $A_count;
		$C_run_count += $C_count;
		$G_run_count += $G_count;
		$T_run_count += $T_count;
		$N_run_count += $N_count;
	    } elsif ($data) {
		print "Data format for get_comment from $file ?: $data\n";
	    }
#	    print '.';
	    $count++;
	}
	$read_count += $count;
#	&Table_update_array($dbc,'SequenceAnalysis',['A_SStotal','C_SStotal','G_SStotal','T_SStotal','SSarray']],
#			    [$run_A,$run_C,$run_T,$run_G,$run_array]);
	$total_A_count += $A_run_count;
	$total_C_count += $C_run_count;
	$total_T_count += $T_run_count;
	$total_G_count += $G_run_count;
	$total_N_count += $N_run_count;

	$total_A += $run_A; 
	$total_C += $run_C;
	$total_G += $run_G;
	$total_T += $run_T;
	
	my $Run_SS_A = $run_A/$A_run_count if $A_run_count;
	my $Run_SS_T = $run_T/$T_run_count if $T_run_count;
	my $Run_SS_G = $run_G/$G_run_count if $G_run_count;
	my $Run_SS_C = $run_C/$C_run_count if $C_run_count;

	my $bp_count = $A_run_count + $G_run_count + $T_run_count + $C_run_count + $N_run_count;
	#print "Base_pair_count:\t$bp_count = $A_run_count + $T_run_count + $G_run_count + $C_run_count + $N_run_count (A+T+C+G+N) bps\t\n";
	#print "Signal Strength:\t$run_A + $run_T + $run_G + $run_C\n";

	printf "Run $run_id ($run_name) *** WEIGHTED AVG: A=%0.0f C=%0.0f G=%0.0f T=%0.0f - over $count reads ($A_run_count $C_run_count $G_run_count $T_run_count $N_run_count bps)\n", $Run_SS_A,  $Run_SS_T, $Run_SS_G, $Run_SS_C;
    }

    my $SS_A = $total_A/$total_A_count if $total_A_count;
    my $SS_G = $total_G/$total_G_count if $total_G_count;
    my $SS_T = $total_T/$total_T_count if $total_T_count;
    my $SS_C = $total_C/$total_C_count if $total_C_count;
    
    printf "*** Totals *** WEIGHTED AVG: A=%0.0f C=%0.0f G=%0.0f T=%0.0f (ATGC bps: $total_A_count $total_T_count $total_G_count $total_C_count)\n", $SS_A, $SS_G, $SS_T, $SS_C;
    
    my $SS = $total_A + $total_C + $total_T + $total_G;
    my $total_count = $total_A_count + $total_G_count + $total_C_count + $total_T_count;

    my $final_SS_avg = $SS / $total_count if $total_count;
    printf "*** ($SS / $total_count bps ($total_N_count N bps) -  over $read_count reads):  %0.0f ***\n", $final_SS_avg;    
    print "**********************************************************************************\n";
    print " *** $key : Avg SS = %0.0f ***\n" , $final_SS_avg;
    print "**********************************************************************************\n";

    
    return;
}

sub _usage {

	 print<<HELP;
Usage:
*********

    shell_API.pl -scope <scope> [options]

	Scope indicates the scope of data retrieval. Options include:
               
           sample, read, oligo (subset of read), run, library, SAGE (subset of library), plate, rearray (subset of plate data), concentration

	Record filtering options:
	**************************     
    -ids <id_list>        - specify a list of ids to get information for.

	Advanced options:
	*****************
	    you may also supply a number of groups in a clearly specified format:
            NO SPACES
            separate lists of ids with a comma (,) - no space
            separate group lists with a colon (:) - no space

    -groups <label 1>=<id_list 1>:<label 2>=<id_list 2>   - specify a particular project

	eg -groups List1=1,2,3,4,5:List2=6,7,8,9,10

	    This will group output into two lines representing results for each list.


Examples:
***********

get_ss.pl -ids 3095,3096,3097,3098

get_ss.pl -groups List1=3095,3096:List2=3097,3098

HELP

}
