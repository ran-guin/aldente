###############################################################
#
#  SDB::Summary
#
#  Show HTML from the Perl statistics that are enumerated from
#  the dbsummary-front cron jobs
#
###############################################################
package alDente::Summary;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Summary.pm - SDB::Summary

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
SDB::Summary<BR>Show HTML from the Perl statistics that are enumerated from<BR>the dbsummary-front cron jobs<BR>

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
    fetch_summary_cache
    print_lib_recent_runs
    print_seq_recent_run_results
);
@EXPORT_OK = qw();

##############################
# standard_modules_ref       #
##############################

use strict;
use CGI qw(:standard);
use POSIX qw(strftime);

#use Storable;
use GD;
use GD::Graph;
use GD::Graph::bars;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
use SDB::HTML;

##############################
# global_vars                #
##############################
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
GD::Graph::colour::read_rgb("/usr/local/apache/site-images/rgb.txt");
my $CACHEDIR      = "/usr/local/apache/tmp/";
my $CACHEFILEROOT = "seqdb.cache.";
my $CACHETTL      = 3600;
my $IMGURL        = "http://www.bcgsc.ca/images/icons";
my @DATA          = ();
my %DATA;
my %HIST;
my ( $DATA_aref, $DATA_array_age );
my ( $DATA_href, $DATA_hash_age );
my ( $HIST_href, $HIST_age, $RUN_HIST_href, $RUN_HIST_age );
my @avgfields     = ( "AvgQ20",  "AvgQ30",  "AvgQ40", "Success100" );
my @maxfields     = ( "MaxQ20",  "MaxQ30",  "MaxQ40", );
my @sequencer_ids = ( 'D3700-1', 'D3700-2', 'D3700-3', 'D3700-4', 'D3700-5', 'D3700-6', 'MB1', 'MB2', 'MB3' );
my $scriptname     = "http://www.bcgsc.ca/cgi-bin/intranet/sequence/summary/dbsummary-front";
my $scriptname_old = "http://www.bcgsc.ca/cgi-bin/intranet/sequence/summary/dbsummary";

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

#########
#
# Cache handling subroutines
#

sub fetch_summary_cache {

    # unfreeze the Perl data from disk

    ( $DATA_aref,     $DATA_array_age ) = FetchData( cachefile => $CACHEFILEROOT . "avg",      cachedir => $CACHEDIR );
    ( $DATA_href,     $DATA_hash_age )  = FetchData( cachefile => $CACHEFILEROOT . "count",    cachedir => $CACHEDIR );
    ( $HIST_href,     $HIST_age )       = FetchData( cachefile => $CACHEFILEROOT . "hist",     cachedir => $CACHEDIR );
    ( $RUN_HIST_href, $RUN_HIST_age )   = FetchData( cachefile => $CACHEFILEROOT . "run_hist", cachedir => $CACHEDIR );

    @DATA = @$DATA_aref;
    %DATA = %$DATA_href;
    %HIST = ( %$HIST_href, %$RUN_HIST_href );    # merge together our HIST caches

    return 1;
}

sub CacheAge {
    ################################################################
    # Fetch the age of a cache file using stat.
    #
    # $age = CacheAge(cachefile=>FILENAME,cachedir=>CACHEDIR);
    #
    # where $age is the age of the file in seconds, or UNDEF
    # if the file does not exist.

    my %flags      = @_;
    my $cache_file = $flags{cachefile};
    my $cache_dir  = $flags{cachedir};
    my $age        = undef;
    if ( -e "$cache_dir/$cache_file" ) {
        my $ctime = ( stat("$cache_dir/$cache_file") )[10];
        my $now = strftime "%s", localtime;
        $age = $now - $ctime;
    }
    return $age;
}

sub FetchData {

    # Fetch data from the the cache

    my %flags      = @_;
    my $cache_file = $flags{cachefile};
    my $cache_dir  = $flags{cachedir};
    my $DATA_ref;
    my $DATA_age;
    if ( -e "$cache_dir/$cache_file" ) {

        # Get the age of the file
        $DATA_age = CacheAge(%flags);
        $DATA_ref = retrieve("$cache_dir/$cache_file");
    }
    else {

        # If there is no cache, then ...
        print "Woops! Where did the cache go?\n";
    }
    return ( $DATA_ref, $DATA_age );
}

#########
#
# HTML subroutines
#

sub print_lib_recent_runs {
    my $size = 50;
    my %libs = %{ runs_by_lib_data( size => $size ) };

    my @run_ids;
    foreach my $lib_key ( sort keys %libs ) {
        foreach my $run_key ( keys %{ $libs{$lib_key} } ) {
            push( @run_ids, $libs{$lib_key}{$run_key}{'ID'} );
        }
    }
    my $grow_href = count_slow_and_no_grows( \@run_ids );

    print qq{&nbsp;<br>\n<table border="0" cellpadding="6" cellspacing="2" width="100%">\n};
    print qq{<tr>\n<td colspan="1" class="vvlightprodblue">\n};
    print qq{<b><span class=large>$size Most Recent Runs by Library</span></b>\n};
    print qq{<table border="0" cellpadding="2" cellspacing="0" align="right">\n};
    print qq{<tr><td><span class="smaller">\n};
    print qq{<a href="$scriptname?view=cache&T=avg,count&c=cachegen&d=t&f=t" target="Window2">Refresh the cache</a><br>\n};
    print "(cache age = " . int( $DATA_array_age / 60 ) . " minutes)";
    print qq{</span></td></tr></table>\n};
    print qq{</td>\n</tr>\n};

    foreach my $lib ( keys %libs ) {
        print qq{<tr><td colspan="1" class="vvlightgrey">\n};
        print "<b>" . $lib . "</b> \n";
        my ( $rc, $no_grow, $slow_grow, $avg, $max );
        foreach my $run ( sort keys %{ $libs{$lib} } ) {
            my $href = $libs{$lib}{$run};
            $rc++;
            $avg = $avg + $href->{'AvgQ20'};
            if ( $href->{'MaxQ20'} > $max ) { $max = $href->{'MaxQ20'} }
            $no_grow   = $no_grow + $$grow_href{ $href->{'ID'} }{'no_grow'};
            $slow_grow = $slow_grow + $$grow_href{ $href->{'ID'} }{'slow_grow'};
        }
        $avg = $avg / $rc;
        print qq{<span class="smaller">};
        print RoundSigDig( num => int($avg), sd => 2 ) . "/" . $max . " \n[";

        # No Grows
        if ( $no_grow > 0 ) { print "<span style='color: red;'>" }
        print $no_grow;
        if ( $no_grow > 0 ) { print "</span>"; }
        print "/";

        # Slow Grows
        if ( $slow_grow > 0 ) { print "<span style='color: red;'>" }
        print $slow_grow;
        if ( $slow_grow > 0 ) { print "</span>"; }
        print "]";
        print qq{ for $rc run};
        if ( $rc > 1 ) { print "s" }

        print qq{<table border="0" cellpadding="2" cellspacing="0" align="right">\n};
        print qq{<tr><td><span class="smaller">\n};
        print qq{<a href="$scriptname?view=recentlibs&lib=$lib&size=25&show_hist=1">25</a>|};
        print qq{<a href="$scriptname?view=recentlibs&lib=$lib&size=50&show_hist=1">50</a>|};
        print qq{<a href="$scriptname?view=recentlibs&lib=$lib&size=200&show_hist=1">200</a>&nbsp;&nbsp;\n};
        print qq{<a href="$scriptname?view=recentlibs&lib=$lib&size=3days&show_hist=1">3d</a>|};
        print qq{<a href="$scriptname?view=recentlibs&lib=$lib&size=7days&show_hist=1">7d</a>|};
        print qq{<a href="$scriptname?view=recentlibs&lib=$lib&size=30days&show_hist=1">30d</a><br>\n};
        print qq{</span></td></tr></table>\n};

        print qq{</span></td></tr>\n};

    }
    print qq{<tr><td colspan="1" class="vlightgrey">\n};
    print qq{<span class="smaller">Overview of recent runs: };
    print qq{<a href="$scriptname?view=sumrecentlibs&size=50">50</a>|};
    print qq{<a href="$scriptname?view=sumrecentlibs&size=100">100</a>|};
    print qq{<a href="$scriptname?view=sumrecentlibs&size=250">250</a>&nbsp;&nbsp;\n};
    print qq{<a href="$scriptname?view=sumrecentlibs&size=3days">3d</a>|};
    print qq{<a href="$scriptname?view=sumrecentlibs&size=7days">7d</a>|};
    print qq{<a href="$scriptname?view=sumrecentlibs&size=30days">30d</a>&nbsp;&nbsp;\n};
    print qq{</span></td></tr>\n};
    print qq{</table>\n\n};

    # Legend
    print "<span class=small><b>LEGEND: </b> ";
    print "Library AvgQ20/MaxQ20 [No Grows/Slow Grows]";
    print "</span><br>";

}

sub print_seq_recent_run_results {
    ################################################################
    # print_seq_recent_run_results
    # Shows the most recent sequencer run results
    #

    my %sequencer = %{ enumerateRecentRuns( size => 5 ) };

    my @run_ids;
    foreach my $seq_key ( sort keys %sequencer ) {
        foreach my $run_key ( keys %{ $sequencer{$seq_key} } ) {
            push( @run_ids, $sequencer{$seq_key}{$run_key}{'ID'} );
        }
    }
    my $grow_href = count_slow_and_no_grows( \@run_ids );

    print qq{&nbsp;<br>\n<table border="0" cellpadding="6" cellspacing="2" width="100%">\n};
    print qq{<tr>\n<td colspan="7" class="vvlightprodblue">\n};
    print qq{<b><span class=large>5 Most Recent Runs per Sequencer</span></b>\n};
    print qq{<table border="0" cellpadding="2" cellspacing="0" align="right">\n};
    print qq{<tr><td><span class="smaller">\n};
    print qq{<a href="$scriptname?view=cache&T=avg,count&c=cachegen&d=t&f=t" target="Window2">Refresh the cache</a><br>\n};
    print "(cache age = " . int( $DATA_array_age / 60 ) . " minutes)";
    print qq{</span></td></tr></table>\n};
    print qq{</td>\n</tr>\n};

    my @run_table = @{ build_recent_runs_table( size => 5 ) };

    # output Sequencer names
    print qq{<tr valign="top">\n};
    foreach my $href ( @{ $run_table[0] } ) {
        print qq{<td width="100" class="vvlightgrey">\n};
        print $href->{'Sequencer'};
        print qq{</td>\n};
    }
    print qq{</tr>\n};

    # print out the array of arrays
    foreach my $aref (@run_table) {
        print qq{<tr valign="top">\n};
        foreach my $href (@$aref) {
            my $class = "vvvlightgrey";
            if ( ( $href->{'AvgQ20'} ) < 201 ) {
                $class = "lightredbw";
            }
            elsif ( ( $href->{'AvgQ20'} ) < 401 ) {
                $class = "vlightyellowbw";
            }

            if ( $href->{'Status'} =~ m/Test/ ) {
                $class = "vvlightgrey";
            }
            print qq{<td class="$class"><span class="smaller">\n};

            my $imgname = GetQImage( q => $href->{'AvgQ20'} );
            print qq{<img width="8" height="8" src="$IMGURL/$imgname" border="0"> \n};

            my @lt = @{ sqltime2lt( $href->{'Date'} ) };
            print qq{<a href="$scriptname_old?scope=RunID&scopevalue=};
            print $href->{'ID'};
            print qq{&option=bpsummary" style="color: #004271;"><b>};
            print $href->{'Library'} . "<br>\n";
            print qq{</b></a>};
            print strftime( "%a&nbsp;%H:%M", @lt ) . " ";
            if ( $href->{'Status'} =~ m/Test/ ) { print "[T] "; }
            print RoundSigDig( num => int( $href->{'AvgQ20'} ), sd => 2 ) . "/" . $href->{'MaxQ20'} . "\n [";

            # No Grows
            if ( ( $grow_href->{ $href->{'ID'} }{'no_grow'} ) > 0 ) { print "<span style='color: red;'>" }
            print $$grow_href{ $href->{'ID'} }{'no_grow'};
            if ( ( $grow_href->{ $href->{'ID'} }{'no_grow'} ) > 0 ) { print "</span>" }
            print "/";

            # Slow Grows
            if ( ( $grow_href->{ $href->{'ID'} }{'slow_grow'} ) > 0 ) { print "<span style='color: red;'>" }
            print $$grow_href{ $href->{'ID'} }{'slow_grow'};
            if ( ( $grow_href->{ $href->{'ID'} }{'slow_grow'} ) > 0 ) { print "</span>" }
            print "]";
            print qq{</span></td>\n};
        }
        print qq{</tr>\n};
    }

    # summary statistics for the last 5 runs for each sequencer
    # AvgQ20 average / MaxQ20 maximum [ total slow grows / total no grows ]
    # first hack together a quick enumeration
    my %short_sum;
    foreach my $aref (@run_table) {
        foreach my $href (@$aref) {
            my $sid = $href->{'Sequencer'};
            $short_sum{$sid}{'AvgQ20'} = $short_sum{$sid}{'AvgQ20'} + ( $href->{'AvgQ20'} / 5 );
            if ( $href->{'MaxQ20'} > $short_sum{$sid}{'MaxQ20'} ) {
                $short_sum{$sid}{'MaxQ20'} = $href->{'MaxQ20'};
            }
            $short_sum{ $href->{'Sequencer'} }{'no_grow'}   = $short_sum{ $href->{'Sequencer'} }{'no_grow'} + $$grow_href{ $href->{'ID'} }{'no_grow'};
            $short_sum{ $href->{'Sequencer'} }{'slow_grow'} = $short_sum{ $href->{'Sequencer'} }{'slow_grow'} + $$grow_href{ $href->{'ID'} }{'slow_grow'};
        }
    }

    # now print out the summary statistics
    print qq{<tr valign="top">\n};
    foreach my $href ( @{ $run_table[0] } ) {
        print qq{<td width="100" class="vvlightgrey"><span class="smaller">\n};
        print RoundSigDig( num => int( $short_sum{ $href->{'Sequencer'} }{'AvgQ20'} ), sd => 2 ) . "/";
        print $short_sum{ $href->{'Sequencer'} }{'MaxQ20'} . " \n[";

        # No Grows
        if ( ( $short_sum{ $href->{'Sequencer'} }{'no_grow'} ) > 0 ) { print "<span style='color: red;'>" }
        print $short_sum{ $href->{'Sequencer'} }{'no_grow'};
        if ( ( $short_sum{ $href->{'Sequencer'} }{'no_grow'} ) > 0 ) { print "</span>"; }
        print "/";

        # Slow Grows
        if ( ( $short_sum{ $href->{'Sequencer'} }{'slow_grow'} ) > 0 ) { print "<span style='color: red;'>" }
        print $short_sum{ $href->{'Sequencer'} }{'slow_grow'};
        if ( ( $short_sum{ $href->{'Sequencer'} }{'slow_grow'} ) > 0 ) { print "</span>"; }
        print "]";
        print qq{</span></td>\n};
    }
    print qq{</tr>\n};

    # links to recent runs by sequencer
    print qq{<tr valign="top" class="vlightgrey">\n};
    foreach my $seq_key ( sort keys %sequencer ) {
        print qq{<td><span class="smaller">\n};
        print qq{<a href="$scriptname?view=recentruns&seq_key=$seq_key&size=25">25</a>|};
        print qq{<a href="$scriptname?view=recentruns&seq_key=$seq_key&size=50">50</a>|};
        print qq{<a href="$scriptname?view=recentruns&seq_key=$seq_key&size=200">200</a><br>\n};
        print qq{<a href="$scriptname?view=recentruns&seq_key=$seq_key&size=3days">3d</a>|};
        print qq{<a href="$scriptname?view=recentruns&seq_key=$seq_key&size=7days">7d</a>|};
        print qq{<a href="$scriptname?view=recentruns&seq_key=$seq_key&size=30days">30d</a><br>\n};
        print qq{</span></td>\n};
    }
    print qq{</tr>\n};
    print qq{</table>\n\n};

    # Quality icon legend
    print "<span class=small><b>QUALITY: </b> ";
    print GetQImage(
        legend   => 1,
        template => qq{QVAL <img src="$IMGURL/IMGTEXT.png"> &nbsp;&nbsp;}
    );
    print "<br>";

    # Legend
    print "<span class=small><b>LEGEND: </b> ";
    print "Library DateTime [Test Run] AvgQ20/MaxQ20 [No Grows/Slow Grows]";
    print "<br>";

}

#########
#
# Private subroutines
#
########

####################
sub runs_by_lib_data {
    ##########
    # Data organized by library/time:
    #
    # %Library{library}{run_id}{DATA-KEY}
    #

    my %flags = @_;
    my $size = Extract_Values( [ $flags{'size'}, 30 ] );

    my %Library;

    # if the size param is of the format 3days
    # then show runs for the last number of days
    if ( $size =~ m/days/ ) {

        # build a recent run array by time in hours
        my @today = Today();

        # set @closing_time to the time X number of days in the past
        # from the current time
        $size =~ m/(\d+)days/;
        my $ddays = $1;
        my @closing_time;
        ( @closing_time[ 0, 1, 2 ] ) = Add_Delta_Days( @today[ 0, 1, 2 ], -($ddays) );

        my $i       = 0;
        my @rundate = ();
        my $run;
    RUN: while ( defined( $run = $DATA[$i] ) ) {

            $run->{'Date'} =~ m/^(\d+)-(\d+)-(\d+)/;
            @rundate = ( int($1), int($2), int($3) );

            # if the run date falls on the same day as our closing date
            # then stop adding runs to the hash for the current sequencer
            last RUN if ( int( Delta_Days( @closing_time[ 0, 1, 2 ], @rundate[ 0, 1, 2 ] ) ) < 0 );

            # otherwise, add the run to our hash
            $Library{ $run->{'Library'} }{$i} = $run;
            $i++;
        }
    }

    # otherwise the size param should be the number of most
    # recent runs you wish to see (25|50|200)
    else {
        my ( $run, $lib );
        for ( my $i = 0; $i < $size; $i++ ) {
            $run               = $DATA[$i];
            $lib               = $run->{'Library'};
            $Library{$lib}{$i} = $run;
        }
    }

    return \%Library;
}

sub count_slow_and_no_grows {
    ################################################################
    # count_slow_and_no_grows
    # Given a array of run_ids, count the number of slow and no grows for each
    # return a hash of the structure  RUN_ID->{GROW_TYPE}
    #

    my $run_ids_ref = shift;
    my $sql;
    my %results;

    foreach my $run_id (@$run_ids_ref) {

        # No Grows
        $sql = qq{select count(*) as count from Clone_Sequence};
        $sql .= qq{ where Growth = "No Grow" and FK_Run__ID = $run_id};
        my $sth = $main::dbc->prepare($sql);
        $sth->execute();
        my $row = $sth->fetchrow_hashref;
        $results{$run_id}{'no_grow'} = $$row{'count'};
        $sth->finish();

        # Slow Grows
        $sql = qq{select count(*) as count from Clone_Sequence};
        $sql .= qq{ where Growth = "Slow Grow" and FK_Run__ID = $run_id};
        $sth = $main::dbc->prepare($sql);
        $sth->execute();
        $row = $sth->fetchrow_hashref;
        $results{$run_id}{'slow_grow'} = $$row{'count'};
        $sth->finish();

    }

    return \%results;
}

sub RoundSigDig {
    ################################################################
    # Round a number to X significant digits. This function is
    # meant only for integers.

    my %flags = @_;
    my $num   = $flags{num};

    my $result;

    # Return what we get if num
    #  - is not defined
    #  - is less than 10 (handles num=0) (this function does not handle single digits)
    #  - includes non-digits
    if ( !defined $num || $num < 10 || $num =~ /\D/ ) {
        return $num;
    }
    my $sd        = Extract_Values( [ $flags{sd}, 2 ] );
    my $size      = int( log($num) / log(10) + 1 );
    my $roundsize = $size - $sd;
    if ( $roundsize < 0 ) {
        return $result;
    }
    my $mult = 10**$roundsize;
    my $rem  = ( $num % $mult );
    if ( $rem < $mult / 2 ) {
        $result = $mult * int( $num / $mult );
    }
    else {
        $result = $mult * ( int( $num / $mult ) + 1 );
    }
    return $result;
}

sub enumerateRecentRuns {
    ##########
    # Data organized by sequencer/time. This data structure should look like so:
    #
    # %Sequencers{sequencer_id}{recent_run_number}{DATA-KEY}
    #

    my %flags = @_;
    my $size = Extract_Values( [ $flags{'size'}, 30 ] );

    my %sequencer;
    my $run;

    # if the size param is of the format 3days
    # then show runs for the last number of days
    if ( $size =~ m/days/ ) {

        # build a recent run array by time in hours
        my @today = Today();
        foreach my $seq_key (@sequencer_ids) {
            unless ( $seq_key =~ /^-/ ) {

                # set @closing_time to the time X number of days in the past
                # from the current time
                $size =~ m/(\d+)days/;
                my $ddays = $1;
                my @closing_time;
                ( @closing_time[ 0, 1, 2 ] ) = Add_Delta_Days( @today[ 0, 1, 2 ], -($ddays) );

                my $i       = 0;
                my $j       = 0;
                my @rundate = ();
            RUN: while ( defined( $run = $DATA[$i] ) ) {

                    # if a run matches the current sequencer, check it out
                    if ( $$run{'Sequencer'} eq $seq_key ) {
                        $$run{'Date'} =~ m/^(\d+)-(\d+)-(\d+)/;
                        @rundate = ( int($1), int($2), int($3) );

                        # if the run date falls on the same day as our closing date
                        # then stop adding runs to the hash for the current sequencer
                        last RUN if ( int( Delta_Days( @closing_time[ 0, 1, 2 ], @rundate[ 0, 1, 2 ] ) ) < 0 );

                        # otherwise, add the run to our hash
                        $sequencer{$seq_key}{$j} = $run;
                        $j++;
                    }
                    $i++;
                }
            }
        }
    }

    # otherwise the size param should be the number of most
    # recent runs you wish to see (25|50|200)
    else {
        foreach my $seq_key (@sequencer_ids) {
            unless ( $seq_key =~ /^-/ ) {

                # idiomatically, this next block could probably be improved,
                # but it does produce the desired results
                my $i = 0;
                my $j = 0;
            RUN: while ( defined( $run = $DATA[$i] ) ) {

                    # feret out the desired number of runs for the sequencer
                    if ( $$run{'Sequencer'} eq $seq_key ) {

                        # got a recent run
                        $sequencer{$seq_key}{$j} = $run;
                        $j++;
                    }
                    last RUN if ( $j == $size );
                    $i++;
                }
            }
        }
    }
    return \%sequencer;
}

sub build_recent_runs_table {
    ##########
    # build_recent_runs_table
    # Create a list of lists of recent runs organized by sequencer
    # (letters are sequencers, numbers are most recent run #)
    #
    #   +----+----+----+
    #   | a1 | b1 | c1 |
    #   +----+----+----+
    #   | a2 | b2 | c2 |
    #   +----+----+----+
    #

    my %flags = @_;
    my $size = Extract_Values( [ $flags{'size'}, 5 ] );

    my @table;

    for ( my $row = 0; $row < $size; $row++ ) {
        my $col = 0;
        foreach my $seq_key (@sequencer_ids) {
            unless ( $seq_key =~ /^-/ ) {
                my $seq_counter = 0;
                my $i;
            RUN: while ( defined( my $run = $DATA[$i] ) ) {
                    $i++;
                    if ( ( ${$run}{'Sequencer'} eq $seq_key ) and ( $seq_counter == $row ) ) {

                        # got a recent run for the sequencer of interest
                        $table[$row][$col] = $run;
                        $col++;
                        last RUN;
                    }
                    elsif ( ${$run}{'Sequencer'} eq $seq_key ) {
                        $seq_counter++;
                    }
                }
            }
        }
    }

    return \@table;
}

sub GetQImage {
    my %flags = @_;
    my $q     = $flags{q};
    my $ext   = ".png";
    my @scale = ( [ 700, "q_exc" ], [ 650, "q_vhigh" ], [ 600, "q_high" ], [ 550, "q_vgood" ], [ 500, "q_good" ], [ 450, "q_avg" ], [ 400, "q_bavg" ], [ 350, "q_bbavg" ], [ 300, "q_low" ], [ 200, "q_vlow" ], [ -1, "q_poor" ], );
    if ( $flags{legend} ) {
        my $legend = "";
        my $lastmin;
        my $item_idx = 0;
        foreach my $item (@scale) {
            my $min = $item->[0];
            if ( $min < 0 ) {
                $min = "&lt;$lastmin";
            }
            if ( !$item_idx ) {
                $min = "&gt;$min";
            }
            $item_idx++;
            my $img = $item->[1];
            my $template = $flags{template} || "QVAL <img src=\"$IMGURL/IMGTEXT.png\">";
            $template =~ s/QVAL/$min/g;
            $template =~ s/IMGTEXT/$img/g;
            $legend .= $template;
            $lastmin = $min;
        }
        return $legend;
    }
    else {
        foreach my $item (@scale) {
            if ( $q > $item->[0] ) {
                return $item->[1] . $ext;
            }
        }
    }
}

#############
sub sqltime2lt {
#############
    # sqltime2lt
    # converts a DateTime string from the SQL database into a Perlish @localtime
    # suitable for use with the strftime function

    my $sqltime = shift;

    my @lt = ();
    $lt[0] = substr( $sqltime, 17, 2 );
    $lt[1] = substr( $sqltime, 14, 2 );
    $lt[2] = substr( $sqltime, 11, 2 );
    $lt[3] = substr( $sqltime, 8,  2 );
    $lt[4] = substr( $sqltime, 5,  2 ) - 1;
    $lt[5] = substr( $sqltime, 0,  4 ) - 1900;
    return \@lt;
}

return 1;

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

$Id: Summary.pm,v 1.8 2004/09/08 23:31:52 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
