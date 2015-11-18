################################################################################
# Data_Images.pm
#
# This modules enables generation of various data viewing images for alDente
#
################################################################################
################################################################################
# $Id: Data_Images.pm,v 1.3 2004/11/08 19:52:16 rguin Exp $ID$
################################################################################
# CVS Revision: $Revision: 1.3 $
#     CVS Date: $Date: 2004/11/08 19:52:16 $
################################################################################
package alDente::Data_Images;

use CGI qw(:standard);
use Data::Dumper;
use Statistics::Descriptive;
use RGTools::Barcode;
use strict;

##############################
# custom_modules_ref         #
##############################

use SDB::HTML;
use SDB::Data_Viewer;
use SDB::CustomSettings;
use SDB::DBIO;
use alDente::Validation;

use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Views;

use vars qw($testing $Security $URL_cache $Connection);

################################
sub generate_q20_histogram {
################################
    #
    #  This simply generates a histogram file for Q20 distribution
    # (one for overall Production runs, and one for Production Runs in last 30 days)
    #
    my %args            = filter_input( \@_ );
    my $dbc             = $args{-dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);
    my $extra_condition = $args{-condition} || 1;
    my $filename        = $args{-file} || 'Q20Hist';
    my $by_month        = $args{-by_month};
    my $recent          = $args{-include_recent};
    my $path            = $args{-path} || "$URL_cache/Q20_Distributions";
    my $quiet           = $args{-quiet};

#### Re-generate Overall Q20 Histogram.. ###
    my $base_condition = "WHERE FK_Run__ID=Run_ID AND FK_SequenceRun__ID=SequenceRun_ID AND Run.FK_Plate__ID=Plate_ID AND FK_Library__Name=Library_Name and FK_RunBatch__ID=RunBatch_ID";
    $base_condition .= " AND Run_Status='Analyzed' AND Run_Test_Status='Production'";

    my $base_tables = 'SequenceAnalysis,SequenceRun,Run,Plate,Library,RunBatch';

    print "Generating Q20 Histograms\n********************\n" unless $quiet;
    print &date_time() . "\n"                                 unless $quiet;

    my ($start) = $dbc->Table_find( $base_tables, 'Month(Min(Run_DateTime)) as first_month,Year(Min(Run_DateTime)) as first_year', "$base_condition AND Run_DateTime > '1999' AND $extra_condition" );
    my ($last)  = $dbc->Table_find( $base_tables, 'Month(Max(Run_DateTime)) as last_month,Year(Max(Run_DateTime)) as last_year',   "$base_condition AND Run_DateTime > '1999' AND $extra_condition" );

    my ( $first_month, $first_year ) = split ',', $start;
    my ( $last_month,  $last_year )  = split ',', $last;

    my ( $month, $year ) = ( $first_month, $first_year );

    unless ( $year && $month ) {return 'No Sequence Runs'}

    my @total_Dist = ();

    my %Project_Dist;
    my %Equip_Dist;
    my %Library_Dist;
    my $result;
    my $total_runs  = 0;
    my $total_reads = 0;
    print "Getting Runs from $first_year-$first_month .. until .. $last_year-$last_month\n(WHERE $extra_condition)" . &date_time() . "\n" unless $quiet;

    while ( ( $year < $last_year ) || ( $year <= $last_year && $month <= $last_month ) ) {
        my %Info  = &Table_retrieve( $dbc, $base_tables, ['Q20array'], "$base_condition AND MONTH(Run_DateTime) = $month AND YEAR(Run_DateTime) = $year AND $extra_condition" );    ### temporary limit to test GD function...(and change filename from temp)
        my @Q20   = ();
        my $index = 0;
        while ( defined $Info{'Q20array'}[$index] ) {
            my $packed = $Info{'Q20array'}[$index];
            my @unpack = unpack "S*", $packed;
            push( @Q20, @unpack );
            $index++;
        }                                                                                                                                                                           #
        my $reads = int(@Q20);
        $total_runs  += $index;
        $total_reads += $reads;

        my @Dist;
        my $stat = Statistics::Descriptive::Full->new();
        $stat->add_data(@Q20);

        my %Distribution = $stat->frequency_distribution( $stat->max() - $stat->min() + 1 );
        if ( $stat->max() == $stat->min() ) {
            $Distribution{ int( $stat->max() ) } = int(@Q20);
        }
        if ($by_month) {    ## cache monthly totals as well ##
            my @Dist = @{ pad_Distribution( \%Distribution, -binsize => 10 ) };    ## just for this month
	    if (@Dist && @Q20) {
		$result = generate_Q20Hist( \@Dist, -file => "$filename.Month.$year-$month.png", -title => 'Monthly Distribution', -path => $path, -quiet => $quiet );
		if ( !( defined($result) ) ) { return err ('alDente::Data_Images::generate_q20_histogram(), error from generate_Q20Hist'); }
	    }
        }

        ## accumulate ##
        @total_Dist = @{ pad_Distribution( \%Distribution, -binsize => 10, -accumulate => \@total_Dist ) };
        print "Retrieved $reads Reads from $index Runs ($year-$month) bin1=$total_Dist[1] : " . &date_time() . "\n" unless $quiet;

        $month++;
        if ( $month > 12 ) { $month = 1; $year++; }
    }

    print "** Wrote to $filename.Summary.png **\n" unless $quiet;
    generate_Q20Hist( \@total_Dist, -file => "$filename.Summary.png", -title => 'Overall Distribution', -path => $path, -quiet => $quiet );

    my $days_ago = $alDente::SDB_Defaults::look_back;
    my ($since) = split ' ', &date_time( '-' . $days_ago . 'd' );

    if ($recent) {
        print "Getting only more recent runs...(Since $since) : " . &date_time() . "\n" unless $quiet;
        my %Info  = &Table_retrieve( $dbc, $base_tables, ['Q20array'], "$base_condition AND Run_DateTime > '$since' AND $extra_condition" );
        my @Q20   = ();
        my $index = 0;
        while ( defined $Info{'Q20array'}[$index] ) {
            my $packed = $Info{'Q20array'}[$index];
            push( @Q20, unpack "S*", $packed );
            $index++;
        }
        print "Retrieved " . int(@Q20) . " Reads (From $index Runs)\n" unless $quiet;

        my @Dist;
        my $stat = Statistics::Descriptive::Full->new();
        $stat->add_data(@Q20);

        my %Distribution = $stat->frequency_distribution( $stat->max() / 10 );
        for ( sort { $a <=> $b } keys %Distribution ) {
            push( @Dist, $Distribution{$_} );

        }

        my $count = 0;
        foreach my $bin (@Dist) {
            $count += $bin;
        }
	if (@Dist && @Q20) {
	    generate_Q20Hist( \@Dist, -file => "$filename.Recent.png", -title => 'Recent Distribution', -path => $path, -quiet => $quiet );
	    print "** Wrote to $filename.Recent.png (data for last $days_ago days) **\n" unless $quiet;
	}
    }

    return 1;
}

##################
sub generate_Q20Hist {
##################
    my $data     = shift;
    my %args     = &filter_input( \@_ );
    my $filename = $args{-file};
    my $title    = $args{-title} || 'distribution';
    my $path     = $args{-path};
    my $x_max    = $args{-x_max};    ## use 120 (for %) or 1200 
    my $quiet    = $args{-quiet};

    my $count = 0;
    foreach my $bin (@$data) {
        $count += $bin;
    }

    #    print "Found $count datapoints in $title.\n" unless $quiet;

    my ($Q20Hist) = generate_run_hist(
				     x_max => $x_max,
        path        => $path,
        data        => $data,
        filename    => $filename,
        xlabel      => 'Phred20 Quality / Read',
        binwidth    => 2,
        height      => 100,
        x_ticks     => [ 20, 40, 60, 80 ],
        x_labels    => [ 200, 400, 600, 800 ],
        remove_zero => 1,
    );
    if ($Q20Hist) {
        return $Q20Hist;
    }
    else {
        return err ('Aldente::Data_Image::generate_Q20Hist(), generate_run_hist returns an error');

    }
}

###########################
sub generate_run_hist {
###########################
    #
    # change this to more object oriented to handle options...
    # This calls the generate histogram routine with a number of settings
    #  specific to run info...
    #
    use warnings;
    my %args = @_;
    my $x_max = $args{'x_max'} || 120;   ## x_labels vs X_tick position (eg 0..120 pixels represents 0..1200 with factor=10)

    my $factor = 10 * int($x_max/ 1000);
    $factor ||= 1;     
    #
## Standard Default Values for Runs...
    #
## Mandatory Fields: ###

    my @ticks = (1, 2, 3, 4, 5, 6);

    my $data         = $args{'data'};
    my $image_format = $args{image_format};
    my @Bins;
    if ($data) { @Bins = @$data; }    ### add options for Project/Lib data retrieval ?

    my $filename = $args{'filename'} || "Hist.png";
## Specific defaults unless otherwise specified...
    my $remove_zero = $args{'remove_zero'} || 0;
    my $binwidth    = $args{'binwidth'}    || 20/$factor;    ### width of bin in pixels...
    my $group   = Extract_Values( [ $args{'group'},   $factor ] );    ### group N bins together by colour
    my $colours = Extract_Values( [ $args{'colours'}, 13 ] );    ### number of unique colours
    my $xlabel   = $args{'xlabel'}   || 'P20 Quality / Read';

    my $ylabel   = $args{'ylabel'}   || '';
    my $height = Extract_Values( [ $args{'height'}, 100 ] );
    my $width  = Extract_Values( [ $args{'width'},  220 ] );
    my $stamp = $args{'timestamp'} || '';
    my $path = $args{'path'};

    my $yline = $args{'yline'} || 0;                             ### if a line should be drawn at a given y position.

    my @X_ticks  = map { $_*2*$factor } @ticks; ## ( 20,  40,  60,  80,  100,  120 );
    my @X_labels = map { $_*$factor*20 } @ticks; ## ( 200, 400, 600, 800, 1000, 1200 );

    my $x_ticks  = $args{'x_ticks'}  || \@X_ticks;               ## (200,400,600];
    my $x_labels = $args{'x_labels'} || \@X_labels;              ## (200,400,600];

    my @Y_ticks;
    my @Y_labels;
    my $y_ticks  = $args{'y_ticks'}  || \@Y_ticks;
    my $y_labels = $args{'y_labels'} || \@Y_labels;

    my ( $img, $zero, $max ) = Generate_Histogram(
        path         => $path,
        data         => \@Bins,
        filename     => $filename,
        remove_zero  => $remove_zero,
        binwidth     => $binwidth,
        group        => $group,
        Ncolours     => $colours,
        x_ticks      => $x_ticks,
        x_labels     => $x_labels,
        xlabel       => $xlabel,
        y_ticks      => $y_ticks,
        y_labels     => $y_labels,
        ylabel       => $ylabel,
        height       => $height,
        width        => $width,
        timestamp    => $stamp,
        yline        => $yline,
        image_format => $image_format
    );

    if (defined($img) && defined($zero) && defined($max)) {
        return ( $img, $zero, $max );
    }
    else {
        return err ('Aldente::Data_Image::generate_run_hist, Generate Histogram returns an error');
    }
}

############################
sub monthly_histograms {
############################
    my %args      = @_;
    my $year      = $args{-year};
    my $month     = $args{-month};
    my $separator = $args{-separator} || '<BR>';
    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);
    my $today     = &date_time();

    ## get all months ##
    my ($start) = $dbc->Table_find( 'Run', 'Month(Min(Run_DateTime)) as first_month,Year(Min(Run_DateTime)) as first_year', "WHERE Run_DateTime > '1900' AND Run_Status='Analyzed' AND Run_Test_Status='Production'" );
    my ($last)  = $dbc->Table_find( 'Run', 'Month(Max(Run_DateTime)) as last_month,Year(Max(Run_DateTime)) as last_year',   "WHERE Run_DateTime > '1900' AND Run_Status='Analyzed' AND Run_Test_Status='Production' " );
    my ( $first_month, $first_year ) = split ',', $start;
    my ( $last_month,  $last_year )  = split ',', $last;

    my $display = Views::Heading("Q20 Distribution (for Production runs analyzed)");

    unless ( $month && $year ) {
        ( $month, $year ) = ( $first_month, $first_year );
    }
    $display .= Views::Heading($year);

    my $Table = HTML_Table->new( -title => "Monthly Q20 Distribution" );
    my @headers = ( $first_year .. $last_year );
    $Table->Set_Headers( [ 'Month', @headers ] );
    my @Month = ( 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' );
    foreach my $month ( 1 .. 12 ) {
        my @row = ( $Month[ $month - 1 ] );
        $Table->Set_Cell_Colour( $month, 1, 'lightblue' );
        foreach my $year ( $first_year .. $last_year ) {
            if ( -e "$URL_cache/Q20_Distributions/All/Q20Hist.Month.$year-$month.png" ) {
                push( @row, "<IMG src='/dynamic/cache/Q20_Distributions/All/Q20Hist.Month.$year-$month.png'>\n" );
            }
            else {
                push( @row, "(no data)" );
            }
        }
        $Table->Set_Row( \@row );
    }
    $Table->Printout();

    return $display;
}

return 1;

