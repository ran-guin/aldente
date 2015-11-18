package Sequencing::Run_Histogram;

##############################
# standard_modules_ref       #
##############################
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;
use POSIX;
use Statistics::Descriptive;
use strict;

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::Conversion;
use alDente::SDB_Defaults;
use alDente::Data_Images;

use vars qw($Connection);

################################################
# generates a Q20 distribution graph and a link
# to a CSV file with values used to generate the graph
################################################
sub generate_run_hist {
    my %args = @_;
    my $run_ids = $args{-run_ids};
    my $dbc = $args{-dbc} || $Connection;
    
    my $base_condition = "WHERE FK_Run__ID=Run_ID AND FK_SequenceRun__ID=SequenceRun_ID AND Run.FK_Plate__ID=Plate_ID AND FK_Library__Name=Library_Name and FK_RunBatch__ID=RunBatch_ID";
    $base_condition .= " AND Run_Status='Analyzed' AND Run_ID in ($run_ids)";
    
    my $base_tables = 'SequenceAnalysis,SequenceRun,Run,Plate,Library,RunBatch';
    
    my @total_Dist = ();
    
    my $total_runs = 0;
    my $total_reads = 0;
    
    
    my %Info = &Table_retrieve($dbc,$base_tables,['Q20array','Wells','NGs','SGs'],"$base_condition");  ### temporary limit to test GD function...(and change filename from temp)
    my @Q20 = ();
    my $index=0;
    my $NGs = 0;
    my $SGs = 0;
    my $wells = 0;
    while (defined $Info{'Q20array'}[$index]) {
	my $packed = $Info{'Q20array'}[$index];
	$NGs += $Info{'NGs'}[$index];
	$SGs += $Info{'SGs'}[$index];
	$wells += $Info{'Wells'}[$index];
	my @unpack = unpack "S*", $packed;
	push(@Q20,@unpack);
	$index++;
    }
    my $reads = int(@Q20);
    $total_runs += $index;
    $total_reads += $reads;

    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data(@Q20);
    
    my %Distribution = $stat->frequency_distribution($stat->max() - $stat->min() + 1);
    if ($stat->max() == $stat->min()) {
	$Distribution{int($stat->max())} = int(@Q20);
    }

    # print out stats (truncate to 2nd decimal place
    my $avg = int($stat->mean()*100)/100;
    my $stdev = int($stat->standard_deviation()*100)/100;
    my $max = $stat->max();
    my $median = $stat->median();
    my $min= $stat->min();
    
    print "Q20 Mean: ${avg}<BR>";
    print "Q20 Stdev: ${stdev}<BR>";
    print "Q20 Max: ${max}<BR>";
    print "Q20 Min: ${min}<BR>";
    print "Q20 Median: ${median}<BR>"; 

    print "Reads (excluding NGs): ${wells}<BR>";
    print "No Grows: ${NGs}<BR>";
    print "Slow Grows: ${SGs}<BR>";

    my @Dist = @{ pad_Distribution(\%Distribution,-binsize=>10) };  
    # find highest bin
    my $max_y = 0;
    foreach (@Dist) {
	if ($_ > $max_y) {
	    $max_y = $_;
	}
    }
    # write out distribution and Q20 file
    my $dist_file = "Q20Dist@{[timestamp()]}.csv";
    my $Q20_file = "Q20@{[timestamp()]}.csv";

    my $count = 1;
    open(OUTD, ">$alDente::SDB_Defaults::URL_temp_dir/".$dist_file);
    foreach (@Dist) {
	my $printstr = "";
	if ($_) {
	    $printstr = (($count++)*10).",$_\n";
	}
	else {
	    $printstr = (($count++)*10).",0\n";
	}
	print OUTD $printstr;
    }
    close OUTD;
    print "<a href='/dynamic/tmp/$dist_file'>Histogram (Distribution) file</a><BR>";

    open(OUTQ, ">$alDente::SDB_Defaults::URL_temp_dir/".$Q20_file);
    foreach (@Q20) {
	print OUTQ "$_\n";
    }
    close OUTQ;
    print "<a href='/dynamic/tmp/$Q20_file'>Raw Q20 file</a><BR>";

    # figure out how where to put the hashes (~1/3 - 2/3), rounded down to nearest modulo 10
    my @yhash = (int($max_y/3) - (int($max_y/3)%10),int(2*$max_y/3) - (int(2*$max_y/3)%10));

    my $filename = "RunHist@{[timestamp()]}.png";
    my ($Q20Hist) = alDente::Data_Images::generate_run_hist(
				      path=>"$alDente::SDB_Defaults::URL_temp_dir",
				      data=>\@Dist,
				      filename=> $filename,
				      xlabel => 'Phred20 Quality',
				      binwidth => 2,
				      height => 100,
				      x_ticks => [20,40,60,80],      
				      x_labels => [200,400,600,800],
				      y_ticks => \@yhash,
				      y_labels => \@yhash,
				      ylabel=>'Reads',
				      remove_zero=>1,
				      );

    print "<img src='/dynamic/tmp/$filename'>";

}

return 1;
