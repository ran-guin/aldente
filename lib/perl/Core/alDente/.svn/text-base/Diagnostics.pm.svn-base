###############################
#
# Diagnostics.pm
#
# This module supplies some basic Sequencing database diagnostics checks.
#
# It should be run from somewhere where the Cached statistics are visible
# (ie on web server)
#
##################################################################################
################################################################################
# $Id: Diagnostics.pm,v 1.10 2004/09/08 23:31:48 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.10 $
#     CVS Date: $Date: 2004/09/08 23:31:48 $
################################################################################
package alDente::Diagnostics;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Diagnostics.pm - This module supplies some basic Sequencing database diagnostics checks.

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module supplies some basic Sequencing database diagnostics checks.<BR>It should be run from somewhere where the Cached statistics are visible<BR>(ie on web server)<BR>

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
    Diagnostics_home
    compare_plate_histories
    sequencing_diagnostics
    get_diagnostics
    get_zoom_in
    show_sequencing_diagnostics
);
@EXPORT_OK = qw(
    Diagnostics_home
    compare_plate_histories
    sequencing_diagnostics
    get_diagnostics
    get_zoom_in
    show_sequencing_diagnostics
);

##############################
# standard_modules_ref       #
##############################

use strict;
use CGI qw(:standard);
use DBI;
use Storable;

##############################
# custom_modules_ref         #
##############################
use alDente::SDB_Defaults;
use alDente::Container;
use alDente::Form;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Views;
use RGTools::HTML_Table;
use SDB::Histogram;
use SDB::HTML;
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;

##############################
# global_vars                #
##############################
use vars qw( $Stats_dir $URL_temp_dir $Connection);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################

my @monitor_prep_fields = ( 'Plate_Prep.FK_Solution__ID as Sol', 'Plate_Prep.FK_Equipment__ID as Equ', 'Prep.FK_Employee__ID as Emp' );
my @monitor_sequence_fields
    = ( 'FKBuffer_Solution__ID as Buffer', 'FKMatrix_Solution__ID as Matrix', 'FKPrimer_Solution__ID as Primer', 'FK_Equipment__ID as Sequencer', 'FK_Branch__Code as Branch', 'FK_Pipeline__ID as Pipeline', 'RunBatch.FK_Employee__ID as Employee',
    'Wells' );
my @monitor_gelrun_fields = (
    'RunBatch.FK_Employee__ID as Start_Run_Employee',
    'FK_Equipment__ID as Fluorimager',
    'FKPoured_Employee__ID as Poured_Employee',
    'FKComb_Equipment__ID as Comb',
    'FKAgarose_Solution__ID as Argarose_Solution',
    'FKAgarosePour_Equipment__ID as Poured_Equipment',
    'FKGelBox_Equipment__ID as GelBox',
    'Date(Run_DateTime) as Run_Date',
    'Run_Comments'
);

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

#########################
sub Diagnostics_home {
#########################
    #
    # A prompt generated to allow branching to the Diagnostics display...
    #
    #
    my $dbc = shift;

    ( my $today )     = split ' ', &RGTools::RGIO::date_time();
    ( my $lastmonth ) = split ' ', &RGTools::RGIO::date_time('-120d');

    print alDente::Form::start_alDente_form( $dbc, -form => "Diagnostics" );

    print submit( -name => 'Sequence Run Diagnostics', -style => "background-color:yellow" ), "<P> (Flagging Run quality +/- ", textfield( -name => 'Percent', -size => 4, -default => 20 ), " % of average Quality)", '<p ></p>', "Since ",
        textfield( -name => 'From', -size => 12, default => $lastmonth ), " Until: ", textfield( -name => 'Until', -size => 12, -default => $today ), " Note: A large set of runs will require a much longer evaluation time", br,
        checkbox( -name => 'Include Test Runs', -default => 0, -force => 1 ), '<p ></p>', textfield( -name => 'Condition', -size => 50, -default => '' ), '<p ></p>', textfield( -name => 'Zoom', -size => 20 ), "\n</FORM>";
    return 1;
}

##################################
sub compare_plate_histories {
##################################
    #
    # This outputs a comparison between two plates,
    # highlighting the differences in Preparation procedures.
    #
    #
    my $dbc    = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate1 = shift;                                                                     ### respective Plate IDs
    my $plate2 = shift;

    my $parents1 = &alDente::Container::get_Parents( -dbc => $dbc, -id => $plate1, -format => 'list' );    ### grab all parent plates
    my $parents2 = &alDente::Container::get_Parents( -dbc => $dbc, -id => $plate2, -format => 'list' );

    my $plate_sets1 = &get_plate_sets( $dbc, $plate1, 0 );                                                 ### get list of applicable plate sets
    my $plate_sets2 = &get_plate_sets( $dbc, $plate2, 0 );

    my $plate1_info = &get_FK_info( $dbc, 'FK_Plate__ID', $plate1 );
    my $plate2_info = &get_FK_info( $dbc, 'FK_Plate__ID', $plate2 );

    print &Views::Heading("Preparation Comparison between plates: $plate1_info, $plate2_info");

    print "<B>History for Plate $plate1:</b><BR>";
    print "(including $parents1)", br;
    my %P1 = plate_history($plate1);
    print hr;

    print "<B>History for Plate $plate2:</B><BR>";
    print "(including $parents2)", br;
    my %P2 = plate_history($plate2);
    print hr;

    unless ( defined $P1{Step}[0] ) {
        RGTools::RGIO::Message("No History for Plate $plate1");
        return 0;
    }
    unless ( defined $P2{Step}[0] ) {
        RGTools::RGIO::Message("No History for Plate $plate2");
        return 0;
    }

    my $CH = HTML_Table->new();
    $CH->Set_sub_title( "<B>Plate $plate1_info</B>", 4, 'mediumgreenbw' );
    $CH->Set_sub_title( "<B>Plate $plate2_info</B>", 4, 'lightredbw' );
    $CH->Set_Headers( [ 'Step1', 'Sol1', 'Equ1', 'Emp1', 'Step2', 'Sol2', 'Equ2', 'Emp2' ] );

    my $index    = 0;
    my $laststep = '';
    my $lasttime;
    my $rows = 0;
    while ( defined $P1{Step}[$index] ) {

        #	my $plate = $P1{Plate}[$index];
        #	unless (($parents1/^$plate$/) || ($plate=~/NULL/)) {next;}
        my $prot_id = $P1{Protocol_ID}[$index];
        my $step    = $P1{Step}[$index];
        $index++;

        if ( $step =~ /Skipped (.*)/ ) { $step = $1; }
        if ( $laststep =~ /^$prot_id $step$/ ) { next; }
        my $laststep = "$prot_id $step";

        #	my $sol =  $P1{Sol}[$index] || '-';
        #	my $equ =  $P1{Equ}[$index] || '-';
        #	my $init = $P1{Init}[$index] || '-';

        my %Similar1 = &Table_retrieve(
            $dbc,
            'Preparation left join Employee on FK_Employee__ID=Employee_ID left join Equipment on Equipment_ID=FK_Equipment__ID',
            [ 'Preparation_Name', 'FK_Solution__ID', 'Equipment_Name', 'Initials', 'Preparation_DateTime' ],
            "where Preparation_Name like '%$step' and FK_Protocol__ID = $prot_id and (FK_Plate__ID in ($parents1) or (FK_Plate__ID is NULL and FK_Plate_Set__Number in ($plate_sets1)))"
        );
        my %Similar2 = &Table_retrieve(
            $dbc,
            'Preparation left join Employee on FK_Employee__ID=Employee_ID left join Equipment on Equipment_ID=FK_Equipment__ID',
            [ 'Preparation_Name', 'FK_Solution__ID', 'Equipment_Name', 'Initials', 'Preparation_DateTime' ],
            "where Preparation_Name like '%$step' and FK_Protocol__ID = $prot_id and (FK_Plate__ID in ($parents2) or (FK_Plate__ID is NULL and FK_Plate_Set__Number in ($plate_sets2)))"
        );

        my $index1 = 0;
        my $index2 = 0;
        my $sol1   = $Similar1{FK_Solution__ID}[$index1] || '-';
        my $sol2   = $Similar2{FK_Solution__ID}[$index2] || '-';

        my $equ1 = $Similar1{Equipment_Name}[$index1] || '-';
        my $equ2 = $Similar2{Equipment_Name}[$index2] || '-';

        my $init1 = $Similar1{Initials}[$index1] || '-';
        my $init2 = $Similar2{Initials}[$index2] || '-';

        my $step1 = $Similar1{Preparation_Name}[$index1];
        my $step2 = $Similar2{Preparation_Name}[$index2];

        my $timestamp1 = $Similar1{Preparation_DateTime}[$index1];
        my $timestamp2 = $Similar2{Preparation_DateTime}[$index2];
        $lasttime ||= $timestamp2;

        unless ($step2) {
            $CH->Set_Row( [ $step, $sol1, $equ1, $init1 ], 'lightredbw' );
            $rows++;
            next;
        }

        ######### get any steps inbetween this one and the last one
        my %Missing = &Table_retrieve(
            $dbc,
            'Preparation left join Employee on FK_Employee__ID=Employee_ID left join Equipment on Equipment_ID=FK_Equipment__ID',
            [ 'Preparation_Name', 'FK_Solution__ID', 'Equipment_Name', 'Initials', 'Preparation_DateTime' ],
            "where Preparation_DateTime>'$lasttime' AND Preparation_DateTime < '$timestamp2' and (FK_Plate__ID in ($parents2) or (FK_Plate__ID is NULL and FK_Plate_Set__Number in ($plate_sets2)))"
        );
        while ( defined $Missing{Preparation_Name}[$index2] ) {
            my $step2 = $Missing{Preparation_Name}[$index2];
            unless ($step2) { next; }
            my $sol2  = $Missing{FK_Solution__ID}[$index2] || '-';
            my $equ2  = $Missing{Equipment_Name}[$index2]  || '-';
            my $init2 = $Missing{Initials}[$index2]        || '-';

            $CH->Set_Row( [ '', '', '', '', $step2, $sol2, $equ2, $init2 ], 'lightredbw' );
            $rows++;
            $index2++;
        }
        $lasttime = $timestamp2;

        #	my $sol2 = $P2{Sol}[$index2];
        #	if ($sol2) {$sol2 = &get_FK_info($dbc,'FK_Solution__ID',$sol2 )}
        #	else {$sol2 = '-';}

        #	my $equ2 = $P2{Equ}[$index2] || '-';
        #	my $init2 = $P2{Init}[$index2] || '-';h
        #	my $step2 = $P2{Step}[$index2] || '-';
        #	    my  ($step2,$sol2,$equ2,$init2) = split ',', $similar_step;
        #	print "found $step/$step = $sol1/$sol2 $equ1/$equ2 $init1/$init2",br;

        $CH->Set_Row( [ $step1, $sol1, $equ1, $init1, $step2, $sol2, $equ2, $init2 ] );

        unless ( $step1 =~ /^$step2$/ ) { $CH->Set_Cell_Colour( $rows + 1, 1, 'yellow' ); $CH->Set_Cell_Colour( $rows + 1, 5, 'yellow' ); }
        unless ( $sol1  =~ /^$sol2$/ )  { $CH->Set_Cell_Colour( $rows + 1, 2, 'yellow' ); $CH->Set_Cell_Colour( $rows + 1, 6, 'yellow' ); }
        unless ( $equ1  =~ /^$equ2$/ )  { $CH->Set_Cell_Colour( $rows + 1, 3, 'yellow' ); $CH->Set_Cell_Colour( $rows + 1, 7, 'yellow' ); }
        unless ( $init1 =~ /^$init2$/ ) { $CH->Set_Cell_Colour( $rows + 1, 4, 'yellow' ); $CH->Set_Cell_Colour( $rows + 1, 8, 'yellow' ); }

        $rows++;
    }
    $CH->Printout();

    return 1;
}

#This function is should be phased out and removed, use get_diagnostics instead
##################################
sub sequencing_diagnostics {
##################################
    my %args = &filter_input( \@_, -args => 'dbc,percent,since,until,display_mode,include_test' );
    my $dbc      = $args{-dbc}     || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $Fpercent = $args{-percent} || 25;                                                               #### percentage above/below average for flagging.
    my $from     = $args{-since};
    my $upto     = $args{ -until };
            my $display_mode      = $args{-display_mode};                                               #### flag for html format or email format.
            my $include_test_runs = $args{-include_test} || 0;
            my $condition         = $args{-condition} || 1;                                             ## optional additional condition
            my $debug             = $args{-debug};
            my $min_counts        = $args{-min_counts} || 4;                                            ### number of Runs required to send flag...

            my $homelink = $dbc->homelink();

    my $html_output;

    ( my $lastmonth ) = split ' ', &RGTools::RGIO::date_time('-120d');
    my ( $today, $stamp ) = split ' ', &RGTools::RGIO::date_time();

    ############ customize data if a different date is specified ###################
    if ( !$from && !$upto && ( $condition eq '1' ) ) { $from = $lastmonth; $upto = $today; }            ## default to previous month if no conditions supplied ##

    my $note;
    if   ($include_test_runs) { $note .= "Test Runs INCLUDED; " }
    else                      { $note .= "Text Runs Excluded; " }

    my $good_threshold = 850;                                                                           ###### (100+$Fpercent)/100;
    my $bad_threshold  = 400;                                                                           ######## (100-$Fpercent)/100;

    if ( $from && $upto ) {
        $condition .= " AND Run_DateTime BETWEEN '$from' AND '$upto'";
    }
    elsif ($from) {
        $condition .= " AND Run_DateTime >= '$from'";
    }
    elsif ($upto) {
        $condition .= " AND Run_DateTime <= '$upto'";
    }

    my $output = "Sequencing Diagnostics\n***********************\n";

    #    my %Info = %{&retrieve("$Stats_dir/Diagnostics")};

    my %Info = Table_retrieve(
        $dbc, 'Run,RunBatch,SequenceRun,SequenceAnalysis,Plate',
        [ @monitor_sequence_fields, 'Run_Test_Status', 'Plate_ID as Plate', 'Q20mean as Quality', 'Run_DateTime as TimeStamp', 'Run_ID as ID', 'Wells' ],
        "WHERE FK_RunBatch__ID=RunBatch_ID AND SequenceAnalysis.FK_SequenceRun__ID=SequenceRun_ID AND SequenceRun.FK_Run__ID=Run_ID AND FK_Plate__ID=Plate_ID AND $condition",
        -date_format => 'SQL',
        -debug       => $debug
    );

    my $total_reads = 0;
    my $total_qual  = 0;
    my $total_count = 0;
    my $index       = 0;
    my $maxdate     = 0;

    $from =~ s/[-:\s]//g;    ###### convert to integer;
    $upto =~ s/[-:\s]//g;    ###### convert to integer;

    #    $from = eval($from);
    #    $upto = eval($upto);

    my @good = ();
    my @bad  = ();

    my $average;
    my %Correlate;
    if (1) {                 ################################# Slower Extraction of info if Customized Date Specified #########################
        my $quality = "Avg(Quality_Length)";

        while ( defined $Info{ID}[$index] ) {
            my $id     = $Info{ID}[$index];
            my $qual   = $Info{Quality}[$index];
            my $plate  = $Info{Plate}[$index];
            my $date   = $Info{TimeStamp}[$index];
            my $status = $Info{Run_Test_Status}[$index];
            my $reads  = $Info{Wells}[$index];

            $total_reads += $reads;
            if ( ( $status =~ /Test/i ) && !$include_test_runs ) { $index++; next; }
            $date =~ s/[-:\s]//g;    ###### convert to integer;
            $date = substr( $date, 0, 8 );    ##### get only YYYYMMDD
            if ( $from && ( $date < $from ) ) {
                $index++;
                next;
            }
            elsif ( $upto && ( $date > $upto ) ) {
                $index++;
                next;
            }

            if ( $date > $maxdate ) { $maxdate = $date; }
            $total_qual += $qual;
            $total_count++;
            foreach my $item (@monitor_sequence_fields) {
                if ( $item =~ /(.*) as (.*)/ ) { $item = $2; }
                my $key = $Info{$item}[$index];
                if ($key) {
                    $Correlate{"$item=$key"}[0] += $reads;
                    $Correlate{"$item=$key"}[1] += $qual;
                    $Correlate{"$item=$key"}[2] += 1;
                    $Correlate{"$item=$key"}[3] .= "$id,";
                }
            }
            my $parents = &alDente::Container::get_Parents( -dbc => $dbc, -id => $plate, -format => 'list' );

            #	    my $sets = &get_plate_sets($dbc,$plate);
            my %Preps = &Table_retrieve( $dbc, 'Prep,Plate_Prep', [ 'Prep_Name', @monitor_prep_fields ], "WHERE FK_Prep__ID=Prep_ID AND FK_Plate__ID in ($parents)" );
            my $step = 0;
            while ( defined $Preps{Prep_Name}[$step] ) {
                my $step_name = $Preps{Prep_Name}[$step];
                foreach my $field (@monitor_prep_fields) {
                    my $item = $field;
                    if ( $item =~ /(.*) as (.*)/ ) { $item = $2; }
                    my $used = $Preps{$item}[$step] || 0;
                    if ( $used && !( $used =~ /NULL/ ) ) {

                        #		    $Correlate{"$item$used"}[0] += $qual;
                        #		    $Correlate{"$item$used"}[1] += 1;
                        #
                        $Correlate{"$step_name with $item=$used"}[0] += $reads;
                        $Correlate{"$step_name with $item=$used"}[1] += $qual;
                        $Correlate{"$step_name with $item=$used"}[2] += 1;
                        $Correlate{"$step_name with $item=$used"}[3] .= "$id,";
                    }
                }
                $step++;
            }
            %Preps = {};
            $index++;
        }
        $output .= "\nCorrelations\n*******************\n";
        if ($total_count) { $average = $total_qual / $total_count; }
    }
    #################### Unless recalculated Correlations are as calculated nightly ##############
    #    else {
    #	%Correlate = %{retrieve("$Stats_dir/StdCorrelations")};
    #	$reads = $Correlate{Details}[0];
    #	$average = $Correlate{Details}[1];
    #	$total_count = $Correlate{Details}[2];
    #	$from = $Correlate{Details}[3];
    #	$upto = $Correlate{Details}[4];
    #	$maxdate = $Correlate{Details}[5];
    #	my @keys = keys %Correlate;
    #    }
    if ( $from    =~ /(\d\d\d\d)(\d\d)(\d\d)/ ) { $from    = "$1-$2-$3"; }
    if ( $upto    =~ /(\d\d\d\d)(\d\d)(\d\d)/ ) { $upto    = "$1-$2-$3"; }
    if ( $maxdate =~ /(\d\d\d\d)(\d\d)(\d\d)/ ) { $maxdate = "$1-$2-$3"; }

    #    my $Diag = HTML_Table->new();
    #    $Diag->Set_Width('100%');
    #    $Diag->Set_Title("Diagnostics Summary");
    #    $Diag->Set_Headers(['From','Until','Reads','Avg P20']);
    #    $Diag->Set_Row([$from,$upto,$reads,sprintf "%0.2f", $average]);
    #    $Diag->Printout();

    $output .= "Monitoring Sequence Runs";
    $output .= " from $from" if $from;
    $output .= " until $upto\n" if $upto;

    $html_output = &Views::Heading("Diagnostics for Selected Runs") || '';
    $html_output .= "(Latest Run found: $maxdate)<P>";

    my $Diagnostics = HTML_Table->new();
    if ( $display_mode =~ /html/i ) {
        $Diagnostics->Set_Title( "<B>Particularly <Font color=Green>GOOD</Font> or <Font color=Red>BAD</Font> Correlations</B> (if found in > $min_counts runs)<BR>(highlighting runs below $bad_threshold or better than $good_threshold)",
            class => 'mediumyellowbw' );
        $Diagnostics->Set_Headers( [ 'Process/Variant', 'Using:', 'Quality<BR>(% of Avg)', 'Runs' ], 'lightgrey' );
    }
    elsif ( $display_mode =~ /email/i ) {
        $Diagnostics->Set_Title( "<B>Particularly <Font color=Red>BAD</Font> Correlations</B><BR>(highlighting poorer than $bad_threshold Reads)", class => 'mediumyellowbw' );
        $Diagnostics->Set_Headers( [ 'Process/Variant', 'Using:', 'Quality<BR>(% of Avg)', 'Runs' ], 'lightgrey' );
    }
    ############# Set up Summary of Best/Worst Runs #############################
    my %Step;
    my $StepAvg   = {};
    my $StepRuns  = {};
    my $StepIndex = {};
    my $step      = '';

    foreach my $key ( keys %Correlate ) {
        if ( $key =~ /HASH/ )      { next; }    ### ignore hash keys...
        if ( $key =~ /^Details$/ ) { next; }    ######## this only contains specific details as generated by update_Stats.pl
        my $reads  = $Correlate{$key}[0] || 0;
        my $total  = $Correlate{$key}[1] || 0;
        my $counts = $Correlate{$key}[2] || 0;
        my $runs   = $Correlate{$key}[3] || 0;

        while ( $runs =~ s/,$//g ) { }          ### get rid of trailing commas...

        #	$total_qual += $total;
        #	$total_count += $counts;

        my $avg = 'N/A';
        if ($counts) {
            $avg = sprintf '%0.0f', $total / $counts;
        }
        else { $avg = -1; }

        unless ($counts) { next; }
        my $info = "$key";
        my $using;
        if    ( $key =~ /^equ=(\d+)/i ) { $info = &get_FK_info( $dbc, 'FK_Equipment__ID', $1 ); }
        elsif ( $key =~ /^sol=(\d+)/i ) { $info = &get_FK_info( $dbc, 'FK_Solution__ID',  $1 ); }
        elsif ( $key =~ /^primer=(\d+)/i ) {
            $using = $1;
            $step  = 'Primer';
            $info  = &get_FK_info( $dbc, 'FK_Solution__ID', $using );
        }
        elsif ( $key =~ /^matrix=(\d+)/i ) {
            $using = $1;
            $step  = 'Matrix';
            $info  = &get_FK_info( $dbc, 'FK_Solution__ID', $using );
        }
        elsif ( $key =~ /^buffer=(\d+)/i ) {
            $using = $1;
            $step  = 'Buffer';
            $info  = &get_FK_info( $dbc, 'FK_Solution__ID', $using );
        }
        elsif ( $key =~ /^Sequencer=(\d+)/i ) {
            $using = $1;
            $step  = 'Sequencer';
            $info  = &get_FK_info( $dbc, 'FK_Equipment__ID', $using );
        }
        elsif ( $key =~ /^Employee=(\d+)/i ) {
            $using = $1;
            $step  = 'Employee';
            $info  = &get_FK_info( $dbc, 'FK_Employee__ID', $using );
        }
        elsif ( $key =~ /(.*) with Equ=(\d+)/i ) {
            $using = $1;
            $step  = $1;
            my $using = $2;
            $info = &get_FK_info( $dbc, 'FK_Equipment__ID', $using );
        }
        elsif ( $key =~ /(.*) with Sol=(\d+)/i ) {
            $step = $1;
            my $using = $2;
            $info = &get_FK_info( $dbc, 'FK_Solution__ID', $using );
        }
        elsif ( $key =~ /(.*) with Emp=(\d+)/i ) {
            $using = $1;
            $step  = $1;
            my $using = $2;
            $info = &get_FK_info( $dbc, 'FK_Employee__ID', $using );
        }
        elsif ( $key =~ /^(Pipeline)=(\d+)/i ) {
            $step = $1;
            my $using = $2;
            $info = &get_FK_info( $dbc, 'FK_Pipeline__ID', $using );
        }
        elsif ( $key =~ /^(Branch)=(\d+)/i ) {
            $step = $1;
            my $using = $2;
            $info = &get_FK_info( $dbc, 'FK_Branch__Code', $using );
        }
        elsif ( $key =~ /(.*)=(.*)/ ) {
            $step  = $1;
            $using = $2;
        }
        else {
            $step = 'Misc';
            my $using = $key;
            $info = "info";
        }

        if ( $step =~ /\>(.*)\</ ) { $step = $1; }    ### remove html tag if present

        unless ( defined $StepIndex->{$step} ) { $StepIndex->{$step} = 0; }

        if ( $info && $step && $runs ) {
            $Step{$step}[ $StepIndex->{$step} ] = $info;
            $StepIndex->{$step}++;
            $StepAvg->{"$step$info"} = $avg;
            $StepRuns->{"$step$info"} .= $runs;
        }

        #	print "$step$info : $runs<BR>";

        if ( $average && $step ) {
            my $padded_step = $step;
            $padded_step =~ s/\s/_/g;
            $step = "<A Href=#$padded_step>$step</A>";

            #	    my $link_to_runs = "<A Href=$homelink&Info=1&Table=Run&Field=Run_ID&Like=$runs>$counts</A>";
            my $link_to_runs = "<A Href=$homelink&Run+Department=Cap_Seq&Last+24+Hours=1&Run+ID=$runs&Any+Date=1>$counts</A>";
            if ( ( $avg > $good_threshold ) && ( $avg > $average ) ) {
                my $percent = sprintf '%0.1f', 100 * $avg / $average;
                push( @good, " $info :\t$avg = $percent % (over $counts runs - $reads read(s))" );
                if ( ( $display_mode =~ /html/i ) && $counts > $min_counts ) { $Diagnostics->Set_Row( [ $step, $info, "$avg ($percent %)", $link_to_runs ], 'mediumgreenbw' ); }
            }
            elsif ( $avg < $bad_threshold ) {
                my $percent = sprintf '%0.1f', 100 * $avg / $average;
                push( @bad, "Using $info :\t$avg = $percent % (over $counts run(s))" );
                if ( $display_mode && $counts > $min_counts ) { $Diagnostics->Set_Row( [ $step, $info, "$avg ($percent %)", $link_to_runs ], 'lightredbw' ); }
            }
        }
        $output .= "$info : avg Q = $avg % (over $counts run(s))\n";
    }
################ calculate overall average... ###########################
    $average = sprintf "%0.1f", $average;
    $output .= "Overall Avg: $average  $note - over $total_count Runs ($total_reads Reads)\n\n";

    ## put list of standard run parameters in an array ##
    my @special_types = @monitor_sequence_fields;
    map {
        if (/.* AS (\w+)/) { $_ = $2 }
    } @special_types;

    #('Sequencer','Primer','Buffer','Matrix');
    if ( $display_mode =~ /html/i ) {
        my $Options = HTML_Table->new();    ######## Generate Clickable list of Options to Monitor Quality by..
        $Options->Set_Title("<B>Monitor Quality By Variations in:</B>");
        $Options->Set_Headers( [ "<B>Sample/Run Attributes</B>", "Sample Handling Processes" ] );
        $Options->Set_Width('100%');

        my $options;
        foreach my $key ( sort @special_types ) {
            my $padded_key = $key;
            $padded_key =~ s/\s/_/g;
            $options .= "<A Href=#$padded_key>$key</A><BR>";
        }
        $Options->Set_Column( [$options] );
        $options = '';
        foreach my $key ( sort keys %Step ) {
            my $padded_key = $key;
            $padded_key =~ s/\s/_/g;
            if ( $key =~ /^HASH/ ) { next; }
            if ( grep /^$key$/, @special_types ) { next; }
            $options .= "<A Href=#$padded_key>$key</A><BR>";
        }
        $Options->Set_Column( [$options] );
        $html_output .= $Options->Printout(0) . hr();
    }
    else {
        $output .= "\nGood Runs (above $good_threshold): \n";
        $output .= "**********************************************\n";
        foreach my $goodkey (@good) {
            $output .= "$goodkey\n";
        }

        $output .= "\nPoorer Runs (below $bad_threshold): \n";
        $output .= "**********************************************\n";
        foreach my $badkey (@bad) {
            $output .= "$badkey\n";
        }
    }

############## Do some standard types first #################
    if ($display_mode) {
        unless ( $Diagnostics->{rows} ) {
            $Diagnostics->Set_Row( ['No runs selected above or below specified thresholds'] );
        }
        $html_output .= "<A Name=Diag>\n" . $Diagnostics->Printout(0);
    }

    my $hist_desc = "<I>Note: Shade of bins darkens with frequency of use (eg light columns indicate low sampling rate)</I><BR>";
    my $StdHist   = SDB::Histogram->new();
    my $colours   = $StdHist->{colours};                                                                                            ### track histogram bin colours ###
    $StdHist->Get_Colours;

    if ( $display_mode =~ /html/i ) {
        $html_output .= &Views::Heading("Diagnostics");

        #	$html_output .= "<Table width=100% cellpadding=0 cellspacing=0><TR valign=top>";
        my $column  = 0;
        my $columns = 1;

        foreach my $type (@special_types) {

            my $Table = HTML_Table->new();
            $Table->Set_Title("Diagnostics for $type");
            $Table->Set_Headers( [ "Variant", "Quality Avg", 'Runs' ] );
            $Table->Set_Width('700');
            $Table->Set_Column_Widths( [ 500, 150, 50, 50 ], [ 0, 1, 2, 3 ] );
            my $index = 0;
            my @hist;
            my @shades;
            my $colour = 0;

            while ( defined $Step{$type}[$index] ) {
                my $used         = $Step{$type}[$index];
                my $avg          = $StepAvg->{"$type$used"};
                my $runs         = $StepRuns->{"$type$used"};
                my $num_runs     = int( my @list = split ',', $runs );
                my $link_to_runs = $num_runs;
                if ($runs) {

                    #		    $link_to_runs = "<A Href=$homelink&Info=1&Table=Run&Field=Run_ID&Like=$runs>$num_runs</A>";
                    $link_to_runs = "<A Href=$homelink&Run+Department=Cap_Seq&Last+24+Hours=1&Run+ID=$runs&Any+Date=1>$num_runs</A>";
                }

                my $percent = int( 100 * $avg / $average );
                $Table->Set_Row( [ $used, "$avg ($percent % of avg)", $link_to_runs ] );
                $Table->Set_Cell_Colour( $index + 1, 3, "'$StdHist->{BinColours}[$colour]'" );
                if ( $avg < $bad_threshold ) {
                    $Table->Set_Cell_Colour( $index + 1, 2, 'red' );
                }
                elsif ( ( $avg > $good_threshold ) && ( $avg > $average ) ) {
                    $Table->Set_Cell_Colour( $index + 1, 2, 'green' );
                }

                $colour++;
                if ( $colour >= $colours ) { $colour = 0; }
                $index++;
                push( @hist,   $avg );
                push( @shades, $num_runs );
            }
            my $padded_type = $type;
            $padded_type =~ s/\s/_/g;
            $html_output .= "\n<A Name=$padded_type></A>\n";

            #	    $html_output .= "<TD align=left>\n";

            ############# Print out Histogram as well... #############
            if ( $index > 1 ) {
                my $Hist = SDB::Histogram->new();
                $Hist->Set_Bins( \@hist, 10 );
                $Hist->Set_Background( 150, 150, 255 );
                $Hist->Set_Shades( -shades => \@shades, -scale => 10, -invert => 1 );
                $type =~ s/\W/_/g;
                ( my $scale, my $max1 ) = $Hist->DrawIt( "Diag_Hist$type$stamp.png", height => 50, -visible_zero => 0 );

                #		$html_output .= "<TD align=left>";
                $html_output .= $hist_desc . "<Img src='/dynamic/tmp/Diag_Hist$type$stamp.png'>";

                #		print "</TD>"
            }
            ############# Print out Table below Histogram ############
            $html_output .= $Table->Printout(0);
            $html_output .= "<A Href=#Top>Return to Top</A>";
            $html_output .= hr;

            #	    $html_output .= "\n</TD>";
            #	    $column++;
            #	    if ($column>=$columns) {$column=0; $html_output .= "</TR><TR>";}
            #	    else {$html_output .= "</TD><TD width=30>-</TD>";}
        }

        #	$html_output .= "</TR></Table>";
        $html_output .= hr;

        $html_output .= &Views::Heading("Diagnostics By Procedure");
        $column = 0;

        #	$html_output .= "<Table width=100% cellpadding=0 cellspacing=0><TR valign=top>";

        foreach my $type ( keys %Step ) {
            if     ( $type =~ /^HASH/ ) { next; }
            unless ( $type =~ /\S/ )    { next; }
            if ( grep /^$type$/, @special_types ) {next}

            my $Table = HTML_Table->new();
            $Table->Set_Title("Variations of '$type'");
            $Table->Set_Headers( [ "Variant", "Quality Avg", 'Runs' ] );
            $Table->Set_Width('700');

            #	    $Table->Set_Column_Widths([100,50,25],[2,3,4]);
            $Table->Set_Column_Widths( [ 500, 150, 50, 50 ], [ 0, 1, 2, 3 ] );
            my $index = 0;
            my @hist;
            my @shades;
            my $colour = 0;
            while ( defined $Step{$type}[$index] ) {
                my $used         = $Step{$type}[$index];
                my $avg          = $StepAvg->{"$type$used"};
                my $runs         = $StepRuns->{"$type$used"};
                my $num_runs     = int( my @list = split ',', $runs );
                my $link_to_runs = "$num_runs $type $used($runs)";
                if ($runs) {

                    #		    $link_to_runs = "<A Href=$homelink&Info=1&Table=Run&Field=Run_ID&Like=$runs>$num_runs</A>";
                    $link_to_runs = "<A Href=$homelink&Run+Department=Cap_Seq&Last+24+Hours=1&Run+ID=$runs&Any+Date=1>$num_runs</A>";
                }
                my $percent = int( 100 * $avg / $average );
                $Table->Set_Row( [ $used, "$avg ($percent % of avg)", $link_to_runs ] );
                $Table->Set_Cell_Colour( $index + 1, 3, "'$StdHist->{BinColours}[$colour]'" );
                if ( $avg < $bad_threshold ) {
                    $Table->Set_Cell_Colour( $index + 1, 2, 'red' );
                }
                elsif ( ( $avg > $good_threshold ) && ( $avg > $average ) ) {
                    $Table->Set_Cell_Colour( $index + 1, 2, 'green' );
                }
                $colour++;
                if ( $colour >= $colours ) { $colour = 0; }
                $index++;
                push( @hist,   $avg );
                push( @shades, $num_runs );
            }
            my $padded_type = $type;
            $padded_type =~ s/\s/_/g;
            $html_output .= "\n<A Name=$padded_type></A>\n";

            #	    $html_output .= "<TD align=left>\n";

            ############# Print out Histogram as well... #############
            if ( $index > 1 ) {
                my $Hist = SDB::Histogram->new();
                $Hist->Set_Bins( \@hist, 10 );
                $Hist->Set_Background( 150, 150, 255 );
                $Hist->Set_Shades( -shades => \@shades, -scale => 10, -invert => 1 );
                $type =~ s/\W/_/g;
                ( my $scale, my $max1 ) = $Hist->DrawIt( "Diag_Hist$type$stamp.png", height => 50, -visible_zero => 0 );

                #		$html_output .= "<TD align=left>";
                $html_output .= $hist_desc . "<Img src='/dynamic/tmp/Diag_Hist$type$stamp.png'>";

                #		$html_output .= </TD>";
            }

            ## enable zoom options ##
            $html_output .= ' zoom on: ';
            foreach my $object ( 'Equipment', 'Solution', 'Employee' ) {
                $html_output .= Link_To( $dbc->config('homelink'), $object, "&Sequence Run Diagnostics=1&Condition=$condition&Zoom=$type&Zoom_Type=$object" );
                $html_output .= ', ';
            }
            ############# Print out Table below Histogram ############
            $html_output .= $Table->Printout(0);
            $html_output .= "<A Href=#Top>Return to Top</A>";
            $html_output .= hr;

            #	    $html_output .= "\n</TD>";

            #	    $column++;
            #	    if ($column>=$columns) {$column=0; $html_output .= "</TR><TR valign=top>";}
            #	    else {$html_output .= "<TD width=30>-</TD>";}
        }

        #	$html_output .= "</TR></Table>";
    }

    $output .= "\nLatest Run: $maxdate\n";

    return ( $output, $html_output );
}

# This function is meant to replace sequencing_diagnostics by taking sequencing specific information in sequencing_diagnostics and make them into aruguments so that it is more general and can apply to other diagnostics
##################################
sub get_diagnostics {
##################################
    my %args = &filter_input( \@_, -args => 'dbc,percent,since,until,display_mode,include_test' );
    my $dbc      = $args{-dbc}     || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $Fpercent = $args{-percent} || 25;                                                               #### percentage above/below average for flagging.
    my $from     = $args{-since};
    my $upto     = $args{ -until };
            my $display_mode      = $args{-display_mode};                                               #### flag for html format or email format.
            my $include_test_runs = $args{-include_test} || 0;
            my $condition         = $args{-condition} || 1;                                             ## optional additional condition
            my $debug             = $args{-debug};
            my $min_counts        = $args{-min_counts} || 4;                                            ### number of Runs required to send flag...
            my $add_tables        = $args{-add_tables};
            my $add_conditions    = $args{-add_conditions};
            my $quality           = $args{-quality};
            my $monitor_fieldsr   = $args{-monitor_fields};
            my @monitor_fields    = @{$monitor_fieldsr};
            my $run_link          = $args{-run_link};
            my $good_threshold    = $args{-good_threshold};
            my $bad_threshold     = $args{-bad_threshold};

            my $homelink = $dbc->homelink();
    my $runlink = $homelink . $run_link;

    my $html_output;

    ( my $lastmonth ) = split ' ', &RGTools::RGIO::date_time('-120d');
    my ( $today, $stamp ) = split ' ', &RGTools::RGIO::date_time();

    ############ customize data if a different date is specified ###################
    if ( !$from && !$upto && ( $condition eq '1' ) ) { $from = $lastmonth; $upto = $today; }    ## default to previous month if no conditions supplied ##

    my $note;
    if   ($include_test_runs) { $note .= "Test Runs INCLUDED; " }
    else                      { $note .= "Text Runs Excluded; " }

    if ( $from && $upto ) {
        $condition .= " AND Run_DateTime BETWEEN '$from' AND '$upto'";
    }
    elsif ($from) {
        $condition .= " AND Run_DateTime >= '$from'";
    }
    elsif ($upto) {
        $condition .= " AND Run_DateTime <= '$upto'";
    }

    my $output = "Sequencing Diagnostics\n***********************\n";

    #    my %Info = %{&retrieve("$Stats_dir/Diagnostics")};
    my $tables = "Run,RunBatch,Plate";
    $tables .= ",$add_tables" if $add_tables;

    my %Info = Table_retrieve(
        $dbc, $tables,
        [ @monitor_fields, 'Run_Test_Status', 'Plate_ID as Plate', "$quality as Quality", 'Run_DateTime as TimeStamp', 'Run_ID as ID' ],
        "WHERE FK_RunBatch__ID=RunBatch_ID AND FK_Plate__ID=Plate_ID AND $condition",
        -date_format => 'SQL',
        -debug       => $debug
    );

    my $total_reads = 0;
    my $total_qual  = 0;
    my $total_count = 0;
    my $index       = 0;
    my $maxdate     = 0;

    $from =~ s/[-:\s]//g;    ###### convert to integer;
    $upto =~ s/[-:\s]//g;    ###### convert to integer;

    #    $from = eval($from);
    #    $upto = eval($upto);

    my @good = ();
    my @bad  = ();

    my $average;
    my %Correlate;
    my %FK_Map_hash;         #This hash is used to get Field Name, Actual Name mapping later used to get FK_info
    if (1) {                 ################################# Slower Extraction of info if Customized Date Specified #########################
        my $quality = "Avg(Quality_Length)";

        while ( defined $Info{ID}[$index] ) {
            my $id     = $Info{ID}[$index];
            my $qual   = $Info{Quality}[$index];
            my $plate  = $Info{Plate}[$index];
            my $date   = $Info{TimeStamp}[$index];
            my $status = $Info{Run_Test_Status}[$index];
            my $reads  = $Info{Wells}[$index];

            $total_reads += $reads;
            if ( ( $status =~ /Test/i ) && !$include_test_runs ) { $index++; next; }
            $date =~ s/[-:\s]//g;    ###### convert to integer;
            $date = substr( $date, 0, 8 );    ##### get only YYYYMMDD
            if ( $from && ( $date < $from ) ) {
                $index++;
                next;
            }
            elsif ( $upto && ( $date > $upto ) ) {
                $index++;
                next;
            }

            if ( $date > $maxdate ) { $maxdate = $date; }
            $total_qual += $qual;
            $total_count++;
            foreach my $item (@monitor_fields) {
                if ( $item =~ /(.*) as (.*)/ ) {
                    $item = $2;
                    $FK_Map_hash{$2} = $1;
                }
                my $key = $Info{$item}[$index];
                if ($key) {
                    $Correlate{"$item=$key"}[0] += $reads;
                    $Correlate{"$item=$key"}[1] += $qual;
                    $Correlate{"$item=$key"}[2] += 1;
                    $Correlate{"$item=$key"}[3] .= "$id,";
                }
            }
            my $parents = &alDente::Container::get_Parents( -dbc => $dbc, -id => $plate, -format => 'list' );

            #	    my $sets = &get_plate_sets($dbc,$plate);
            my %Preps = &Table_retrieve( $dbc, 'Prep,Plate_Prep', [ 'Prep_Name', @monitor_prep_fields ], "WHERE FK_Prep__ID=Prep_ID AND FK_Plate__ID in ($parents)" );
            my $step = 0;
            while ( defined $Preps{Prep_Name}[$step] ) {
                my $step_name = $Preps{Prep_Name}[$step];
                foreach my $field (@monitor_prep_fields) {
                    my $item = $field;
                    if ( $item =~ /(.*) as (.*)/ ) { $item = $2; }
                    my $used = $Preps{$item}[$step] || 0;
                    if ( $used && !( $used =~ /NULL/ ) ) {

                        #		    $Correlate{"$item$used"}[0] += $qual;
                        #		    $Correlate{"$item$used"}[1] += 1;
                        #
                        $Correlate{"$step_name with $item=$used"}[0] += $reads;
                        $Correlate{"$step_name with $item=$used"}[1] += $qual;
                        $Correlate{"$step_name with $item=$used"}[2] += 1;
                        $Correlate{"$step_name with $item=$used"}[3] .= "$id,";
                    }
                }
                $step++;
            }
            %Preps = {};
            $index++;
        }
        $output .= "\nCorrelations\n*******************\n";
        if ($total_count) { $average = $total_qual / $total_count; }
    }
    #################### Unless recalculated Correlations are as calculated nightly ##############
    #    else {
    #	%Correlate = %{retrieve("$Stats_dir/StdCorrelations")};
    #	$reads = $Correlate{Details}[0];
    #	$average = $Correlate{Details}[1];
    #	$total_count = $Correlate{Details}[2];
    #	$from = $Correlate{Details}[3];
    #	$upto = $Correlate{Details}[4];
    #	$maxdate = $Correlate{Details}[5];
    #	my @keys = keys %Correlate;
    #    }
    if ( $from    =~ /(\d\d\d\d)(\d\d)(\d\d)/ ) { $from    = "$1-$2-$3"; }
    if ( $upto    =~ /(\d\d\d\d)(\d\d)(\d\d)/ ) { $upto    = "$1-$2-$3"; }
    if ( $maxdate =~ /(\d\d\d\d)(\d\d)(\d\d)/ ) { $maxdate = "$1-$2-$3"; }

    #    my $Diag = HTML_Table->new();
    #    $Diag->Set_Width('100%');
    #    $Diag->Set_Title("Diagnostics Summary");
    #    $Diag->Set_Headers(['From','Until','Reads','Avg P20']);
    #    $Diag->Set_Row([$from,$upto,$reads,sprintf "%0.2f", $average]);
    #    $Diag->Printout();

    $output .= "Monitoring Sequence Runs";
    $output .= " from $from" if $from;
    $output .= " until $upto\n" if $upto;

    $html_output = &Views::Heading("Diagnostics for Selected Runs") || '';
    $html_output .= "(Latest Run found: $maxdate)<P>";

    my $Diagnostics = HTML_Table->new();
    if ( $display_mode =~ /html/i ) {
        $Diagnostics->Set_Title( "<B>Particularly <Font color=Green>GOOD</Font> or <Font color=Red>BAD</Font> Correlations</B> (if found in > $min_counts runs)<BR>(highlighting runs below $bad_threshold or better than $good_threshold)",
            class => 'mediumyellowbw' );
        $Diagnostics->Set_Headers( [ 'Process/Variant', 'Using:', 'Quality<BR>(% of Avg)', 'Runs' ], 'lightgrey' );
    }
    elsif ( $display_mode =~ /email/i ) {
        $Diagnostics->Set_Title( "<B>Particularly <Font color=Red>BAD</Font> Correlations</B><BR>(highlighting poorer than $bad_threshold Reads)", class => 'mediumyellowbw' );
        $Diagnostics->Set_Headers( [ 'Process/Variant', 'Using:', 'Quality<BR>(% of Avg)', 'Runs' ], 'lightgrey' );
    }
    ############# Set up Summary of Best/Worst Runs #############################
    my %Step;
    my $StepAvg   = {};
    my $StepRuns  = {};
    my $StepIndex = {};
    my $step      = '';

    foreach my $key ( keys %Correlate ) {
        if ( $key =~ /HASH/ )      { next; }    ### ignore hash keys...
        if ( $key =~ /^Details$/ ) { next; }    ######## this only contains specific details as generated by update_Stats.pl
        my $reads  = $Correlate{$key}[0] || 0;
        my $total  = $Correlate{$key}[1] || 0;
        my $counts = $Correlate{$key}[2] || 0;
        my $runs   = $Correlate{$key}[3] || 0;

        while ( $runs =~ s/,$//g ) { }          ### get rid of trailing commas...

        #	$total_qual += $total;
        #	$total_count += $counts;

        my $avg = 'N/A';
        if ($counts) {
            $avg = sprintf '%0.0f', $total / $counts;
        }
        else { $avg = -1; }

        unless ($counts) { next; }
        my $info = "$key";
        my $using;

        my $joinkey = join( '|', keys %FK_Map_hash );
        if    ( $key =~ /^equ=(\d+)/i ) { $info = &get_FK_info( $dbc, 'FK_Equipment__ID', $1 ); }
        elsif ( $key =~ /^sol=(\d+)/i ) { $info = &get_FK_info( $dbc, 'FK_Solution__ID',  $1 ); }
        elsif ( $key =~ /^($joinkey)=(\d+)/i ) {
            $step = $1;
            my $using = $2;
            $info = &get_FK_info( $dbc, $FK_Map_hash{$step}, $using );
        }

        elsif ( $key =~ /^primer=(\d+)/i ) {
            $using = $1;
            $step  = 'Primer';
            $info  = &get_FK_info( $dbc, 'FK_Solution__ID', $using );
        }
        elsif ( $key =~ /^matrix=(\d+)/i ) {
            $using = $1;
            $step  = 'Matrix';
            $info  = &get_FK_info( $dbc, 'FK_Solution__ID', $using );
        }
        elsif ( $key =~ /^buffer=(\d+)/i ) {
            $using = $1;
            $step  = 'Buffer';
            $info  = &get_FK_info( $dbc, 'FK_Solution__ID', $using );
        }
        elsif ( $key =~ /^Sequencer=(\d+)/i ) {
            $using = $1;
            $step  = 'Sequencer';
            $info  = &get_FK_info( $dbc, 'FK_Equipment__ID', $using );
        }
        elsif ( $key =~ /^Employee=(\d+)/i ) {
            $using = $1;
            $step  = 'Employee';
            $info  = &get_FK_info( $dbc, 'FK_Employee__ID', $using );
        }
        elsif ( $key =~ /(.*) with Equ=(\d+)/i ) {
            $using = $1;
            $step  = $1;
            my $using = $2;
            $info = &get_FK_info( $dbc, 'FK_Equipment__ID', $using );
        }
        elsif ( $key =~ /(.*) with Sol=(\d+)/i ) {
            $step = $1;
            my $using = $2;
            $info = &get_FK_info( $dbc, 'FK_Solution__ID', $using );
        }
        elsif ( $key =~ /(.*) with Emp=(\d+)/i ) {
            $using = $1;
            $step  = $1;
            my $using = $2;
            $info = &get_FK_info( $dbc, 'FK_Employee__ID', $using );
        }
        elsif ( $key =~ /^(Pipeline)=(\d+)/i ) {
            $step = $1;
            my $using = $2;
            $info = &get_FK_info( $dbc, 'FK_Pipeline__ID', $using );
        }
        elsif ( $key =~ /^(Branch)=(\d+)/i ) {
            $step = $1;
            my $using = $2;
            $info = &get_FK_info( $dbc, 'FK_Branch__Code', $using );
        }
        elsif ( $key =~ /(.*)=(.*)/ ) {
            $step  = $1;
            $using = $2;
        }
        else {
            $step = 'Misc';
            my $using = $key;
            $info = "info";
        }

        if ( $step =~ /\>(.*)\</ ) { $step = $1; }    ### remove html tag if present

        unless ( defined $StepIndex->{$step} ) { $StepIndex->{$step} = 0; }

        if ( $info && $step && $runs ) {
            $Step{$step}[ $StepIndex->{$step} ] = $info;
            $StepIndex->{$step}++;
            $StepAvg->{"$step$info"} = $avg;
            $StepRuns->{"$step$info"} .= $runs;
        }

        #	print "$step$info : $runs<BR>";

        if ( $average && $step ) {
            my $padded_step = $step;
            $padded_step =~ s/\s/_/g;
            $step = "<A Href=#$padded_step>$step</A>";

            #	    my $link_to_runs = "<A Href=$homelink&Info=1&Table=Run&Field=Run_ID&Like=$runs>$counts</A>";
            #my $link_to_runs = "<A Href=$homelink&Run+Department=Sequencing&Last+24+Hours=1&Run+ID=$runs&Any+Date=1>$counts</A>";
            my $link_to_runs = "<A Href=$runlink$runs>$counts</A>";
            if ( ( $avg > $good_threshold ) && ( $avg > $average ) ) {
                my $percent = sprintf '%0.1f', 100 * $avg / $average;
                push( @good, " $info :\t$avg = $percent % (over $counts runs - $reads read(s))" );
                if ( ( $display_mode =~ /html/i ) && $counts > $min_counts ) { $Diagnostics->Set_Row( [ $step, $info, "$avg ($percent %)", $link_to_runs ], 'mediumgreenbw' ); }
            }
            elsif ( $avg < $bad_threshold ) {
                my $percent = sprintf '%0.1f', 100 * $avg / $average;
                push( @bad, "Using $info :\t$avg = $percent % (over $counts run(s))" );
                if ( $display_mode && $counts > $min_counts ) { $Diagnostics->Set_Row( [ $step, $info, "$avg ($percent %)", $link_to_runs ], 'lightredbw' ); }
            }
        }
        $output .= "$info : avg Q = $avg % (over $counts run(s))\n";
    }
################ calculate overall average... ###########################
    $average = sprintf "%0.1f", $average;
    $output .= "Overall Avg: $average  $note - over $total_count Runs ($total_reads Reads)\n\n";

    ## put list of standard run parameters in an array ##
    my @special_types = @monitor_fields;
    map {
        if (/.* AS (\w+)/) { $_ = $2 }
    } @special_types;

    #('Sequencer','Primer','Buffer','Matrix');
    if ( $display_mode =~ /html/i ) {
        my $Options = HTML_Table->new();    ######## Generate Clickable list of Options to Monitor Quality by..
        $Options->Set_Title("<B>Monitor Quality By Variations in:</B>");
        $Options->Set_Headers( [ "<B>Sample/Run Attributes</B>", "Sample Handling Processes" ] );
        $Options->Set_Width('100%');

        my $options;
        foreach my $key ( sort @special_types ) {
            my $padded_key = $key;
            $padded_key =~ s/\s/_/g;
            $options .= "<A Href=#$padded_key>$key</A><BR>";
        }
        $Options->Set_Column( [$options] );
        $options = '';
        foreach my $key ( sort keys %Step ) {
            my $padded_key = $key;
            $padded_key =~ s/\s/_/g;

            if ( $key =~ /^HASH/ ) { next; }
            if ( grep /\Q^$key$\E/, @special_types ) { next; }
            $options .= "<A Href=#$padded_key>$key</A><BR>";
        }
        $Options->Set_Column( [$options] );
        $html_output .= $Options->Printout(0) . hr();
    }
    else {
        $output .= "\nGood Runs (above $good_threshold): \n";
        $output .= "**********************************************\n";
        foreach my $goodkey (@good) {
            $output .= "$goodkey\n";
        }

        $output .= "\nPoorer Runs (below $bad_threshold): \n";
        $output .= "**********************************************\n";
        foreach my $badkey (@bad) {
            $output .= "$badkey\n";
        }
    }

############## Do some standard types first #################
    if ($display_mode) {
        unless ( $Diagnostics->{rows} ) {
            $Diagnostics->Set_Row( ['No runs selected above or below specified thresholds'] );
        }
        $html_output .= "<A Name=Diag>\n" . $Diagnostics->Printout(0);
    }

    my $hist_desc = "<I>Note: Shade of bins darkens with frequency of use (eg light columns indicate low sampling rate)</I><BR>";
    my $StdHist   = SDB::Histogram->new();
    my $colours   = $StdHist->{colours};                                                                                            ### track histogram bin colours ###
    $StdHist->Get_Colours;

    if ( $display_mode =~ /html/i ) {
        $html_output .= &Views::Heading("Diagnostics");

        #	$html_output .= "<Table width=100% cellpadding=0 cellspacing=0><TR valign=top>";
        my $column  = 0;
        my $columns = 1;

        foreach my $type (@special_types) {

            my $Table = HTML_Table->new();
            $Table->Set_Title("Diagnostics for $type");
            $Table->Set_Headers( [ "Variant", "Quality Avg", 'Runs' ] );
            $Table->Set_Width('700');
            $Table->Set_Column_Widths( [ 500, 150, 50, 50 ], [ 0, 1, 2, 3 ] );
            my $index = 0;
            my @hist;
            my @shades;
            my $colour = 0;

            while ( defined $Step{$type}[$index] ) {
                my $used         = $Step{$type}[$index];
                my $avg          = $StepAvg->{"$type$used"};
                my $runs         = $StepRuns->{"$type$used"};
                my $num_runs     = int( my @list = split ',', $runs );
                my $link_to_runs = $num_runs;
                if ($runs) {

                    #		    $link_to_runs = "<A Href=$homelink&Info=1&Table=Run&Field=Run_ID&Like=$runs>$num_runs</A>";
                    #$link_to_runs = "<A Href=$homelink&Run+Department=Sequencing&Last+24+Hours=1&Run+ID=$runs&Any+Date=1>$num_runs</A>";
                    $link_to_runs = "<A Href=$runlink$runs>$num_runs</A>";
                }

                #my $percent = int( 100 * $avg / $average );
                my $percent = 0;
                $percent = int( 100 * $avg / $average ) if $average > 0;

                $Table->Set_Row( [ $used, "$avg ($percent % of avg)", $link_to_runs ] );
                $Table->Set_Cell_Colour( $index + 1, 3, "'$StdHist->{BinColours}[$colour]'" );
                if ( $avg < $bad_threshold ) {
                    $Table->Set_Cell_Colour( $index + 1, 2, 'red' );
                }
                elsif ( ( $avg > $good_threshold ) && ( $avg > $average ) ) {
                    $Table->Set_Cell_Colour( $index + 1, 2, 'green' );
                }

                $colour++;
                if ( $colour >= $colours ) { $colour = 0; }
                $index++;
                push( @hist,   $avg );
                push( @shades, $num_runs );
            }
            my $padded_type = $type;
            $padded_type =~ s/\s/_/g;
            $html_output .= "\n<A Name=$padded_type></A>\n";

            #	    $html_output .= "<TD align=left>\n";

            ############# Print out Histogram as well... #############
            if ( $index > 1 ) {
                my $Hist = SDB::Histogram->new();
                $Hist->Set_Bins( \@hist, 10 );
                $Hist->Set_Background( 150, 150, 255 );
                $Hist->Set_Shades( -shades => \@shades, -scale => 10, -invert => 1 );
                $type =~ s/\W/_/g;
                ( my $scale, my $max1 ) = $Hist->DrawIt( "Diag_Hist$type$stamp.png", height => 50, -visible_zero => 0 );

                #		$html_output .= "<TD align=left>";
                $html_output .= $hist_desc . "<Img src='/dynamic/tmp/Diag_Hist$type$stamp.png'>";

                #		print "</TD>"
            }
            ############# Print out Table below Histogram ############
            $html_output .= $Table->Printout(0);
            $html_output .= "<A Href=#Top>Return to Top</A>";
            $html_output .= hr;

            #	    $html_output .= "\n</TD>";
            #	    $column++;
            #	    if ($column>=$columns) {$column=0; $html_output .= "</TR><TR>";}
            #	    else {$html_output .= "</TD><TD width=30>-</TD>";}
        }

        #	$html_output .= "</TR></Table>";
        $html_output .= hr;

        $html_output .= &Views::Heading("Diagnostics By Procedure");
        $column = 0;

        #	$html_output .= "<Table width=100% cellpadding=0 cellspacing=0><TR valign=top>";

        foreach my $type ( keys %Step ) {
            if     ( $type =~ /^HASH/ ) { next; }
            unless ( $type =~ /\S/ )    { next; }
            if ( grep /\Q^$type$\E/, @special_types ) {next}

            my $Table = HTML_Table->new();
            $Table->Set_Title("Variations of '$type'");
            $Table->Set_Headers( [ "Variant", "Quality Avg", 'Runs' ] );
            $Table->Set_Width('700');

            #	    $Table->Set_Column_Widths([100,50,25],[2,3,4]);
            $Table->Set_Column_Widths( [ 500, 150, 50, 50 ], [ 0, 1, 2, 3 ] );
            my $index = 0;
            my @hist;
            my @shades;
            my $colour = 0;
            while ( defined $Step{$type}[$index] ) {
                my $used         = $Step{$type}[$index];
                my $avg          = $StepAvg->{"$type$used"};
                my $runs         = $StepRuns->{"$type$used"};
                my $num_runs     = int( my @list = split ',', $runs );
                my $link_to_runs = "$num_runs $type $used($runs)";
                if ($runs) {

                    #		    $link_to_runs = "<A Href=$homelink&Info=1&Table=Run&Field=Run_ID&Like=$runs>$num_runs</A>";
                    #$link_to_runs = "<A Href=$homelink&Run+Department=Sequencing&Last+24+Hours=1&Run+ID=$runs&Any+Date=1>$num_runs</A>";
                    $link_to_runs = "<A Href=$runlink$runs>$num_runs</A>";
                }

                #my $percent = int( 100 * $avg / $average );
                my $percent = 0;
                $percent = int( 100 * $avg / $average ) if $average > 0;
                $Table->Set_Row( [ $used, "$avg ($percent % of avg)", $link_to_runs ] );
                $Table->Set_Cell_Colour( $index + 1, 3, "'$StdHist->{BinColours}[$colour]'" );
                if ( $avg < $bad_threshold ) {
                    $Table->Set_Cell_Colour( $index + 1, 2, 'red' );
                }
                elsif ( ( $avg > $good_threshold ) && ( $avg > $average ) ) {
                    $Table->Set_Cell_Colour( $index + 1, 2, 'green' );
                }
                $colour++;
                if ( $colour >= $colours ) { $colour = 0; }
                $index++;
                push( @hist,   $avg );
                push( @shades, $num_runs );
            }
            my $padded_type = $type;
            $padded_type =~ s/\s/_/g;
            $html_output .= "\n<A Name=$padded_type></A>\n";

            #	    $html_output .= "<TD align=left>\n";

            ############# Print out Histogram as well... #############
            if ( $index > 1 ) {
                my $Hist = SDB::Histogram->new();
                $Hist->Set_Bins( \@hist, 10 );
                $Hist->Set_Background( 150, 150, 255 );
                $Hist->Set_Shades( -shades => \@shades, -scale => 10, -invert => 1 );
                $type =~ s/\W/_/g;
                ( my $scale, my $max1 ) = $Hist->DrawIt( "Diag_Hist$type$stamp.png", height => 50, -visible_zero => 0 );

                #		$html_output .= "<TD align=left>";
                $html_output .= $hist_desc . "<Img src='/dynamic/tmp/Diag_Hist$type$stamp.png'>";

                #		$html_output .= </TD>";
            }

            ## enable zoom options ##
            $html_output .= ' zoom on: ';
            foreach my $object ( 'Equipment', 'Solution', 'Employee' ) {

                #$html_output .= Link_To( $dbc->config('homelink'), $object, "&Sequence Run Diagnostics=1&Condition=$condition&Zoom=$type&Zoom_Type=$object" );
                #$html_output .= ', ';
                $html_output .= Link_To( $dbc->config('homelink'), $object, "&cgi_application=alDente::Diagnostics_App&rm=show_zoom_in&Zoom=$type&Zoom_Type=$object&add_tables=$add_tables&add_conditions=$add_conditions&quality=$quality" );
                $html_output .= ', ';
            }
            ############# Print out Table below Histogram ############
            $html_output .= $Table->Printout(0);
            $html_output .= "<A Href=#Top>Return to Top</A>";
            $html_output .= hr;

            #	    $html_output .= "\n</TD>";

            #	    $column++;
            #	    if ($column>=$columns) {$column=0; $html_output .= "</TR><TR valign=top>";}
            #	    else {$html_output .= "<TD width=30>-</TD>";}
        }

        #	$html_output .= "</TR></Table>";
    }

    $output .= "\nLatest Run: $maxdate\n";

    return ( $output, $html_output );
}

#############
sub get_zoom_in {
#############
    my %args            = &filter_input( \@_, -args => 'dbc,zoom_type,zoom_value', -mandatory => 'dbc,zoom_type,zoom_value' );
    my $dbc             = $args{-dbc};
    my $type            = $args{-zoom_type};
    my $value           = $args{-zoom_value};
    my $extra_condition = $args{-zoom_condition} || 'Prep_DateTime > DATE_SUB(CURDATE(), INTERVAL 1 month)';                     ## default to last 6 months ##
    my $add_tables      = $args{-add_tables};
    my $add_conditions  = $args{-add_conditions};
    my $quality         = $args{-quality};

    my $debug = $args{-debug} || 0;

    my %Hash;
    my %Record;

    #    $Hash{Run_Validation} = [''];
    #    $Hash{Quality} = [0];
    #    $Hash{Count} = [0];

    my $condition = "$extra_condition AND Prep_Name like \"$value\"";
    my $check_field;

    if ( $type eq 'Equipment' ) {
        $check_field = 'FK_Equipment__ID';
    }
    elsif ( $type eq 'Employee' ) {
        $check_field = 'Prep.FK_Employee__ID as FK_Employee__ID';
    }
    elsif ( $type eq 'Solution' ) {
        $check_field = 'FK_Solution__ID';
    }
    else {
        Message("Undefined type: $type (?)");
    }

    my $check_field_alias = $check_field;
    my $check_field_name  = $check_field;
    if ( $check_field =~ /(.+) AS (.+)/i ) {
        $check_field_name  = $1;
        $check_field_alias = $2;
    }
    $condition .= " AND $check_field_name > 0";

    my $order = " ORDER BY $check_field_name";

    ## correlate with specific protocol steps ##
    my %Prepped = $dbc->Table_retrieve(
        "Plate,Plate_Prep,Prep,Library,Lab_Protocol,Original_Source",
        [ 'Plate_ID', 'Plate.FK_Library__Name', 'Plate.Plate_Number', 'Plate.FK_Branch__Code', 'Plate.Plate_Status', $check_field ],
        -condition => "WHERE FK_Library__Name=Library_Name AND FK_Lab_Protocol__ID=Lab_Protocol_ID AND FK_Original_Source__ID=Original_Source_ID AND Plate_Prep.FK_Plate__ID=Plate.Plate_ID AND FK_Prep__ID=Prep_ID AND $condition $order",
        -debug     => $debug
    );

    my $i       = 0;
    my $no_runs = 0;

    my @run_fields = ( 'Run_Validation', "$quality as Quality", 'Count(*) as Runs' );

    while ( defined $Prepped{Plate_ID}[$i] ) {
        my $plate  = $Prepped{Plate_ID}[$i];
        my $object = $Prepped{$check_field_alias}[$i];
        $i++;
        my $daughters = &alDente::Container::get_Children( -dbc => $dbc, -id => $plate, -format => 'list' ) || 0;

        my %Runs = &Table_retrieve( $dbc, 'Prep,Plate_Prep', [ 'Prep_Name', @monitor_prep_fields ], "WHERE FK_Prep__ID=Prep_ID AND FK_Plate__ID in ($plate,$daughters)" );

        my $group = "GROUP BY Run_Validation";

        my %Info = $dbc->Table_retrieve(
            "Run,RunBatch,Plate,$add_tables",
            \@run_fields,
            "WHERE FK_RunBatch__ID=RunBatch_ID AND $add_conditions AND FK_Plate__ID=Plate_ID AND Plate_ID IN ($plate,$daughters) $group",
            -date_format => 'SQL',
            -debug       => $debug
        );

        my $count = 0;
        while ( defined $Info{Runs}[$count] ) {
            my $quality = $Info{Quality}[$count];

            my $run_count = $Info{Runs}[$count];
            my $run_valid = $Info{Run_Validation}[$count];
            $count++;

            $Record{$object}{$run_valid}{Quality} ||= 0;
            $Record{$object}{$run_valid}{Quality} += $quality * $run_count;

            $Record{$object}{$run_valid}{Count} += $run_count;
        }

        if ( !$count ) {
            $Record{$object}{'n/a'}{Count}++;
            $Record{$object}{'n/a'}{Quality} = 'n/a';
            $no_runs++;
        }
    }

    ## Populate the overall summary hash ##
    my $count = 0;
    foreach my $object ( sort keys %Record ) {
        foreach my $validation ( keys %{ $Record{$object} } ) {
            $Hash{$check_field_alias}[$count] = $object;
            $Hash{Run_Validation}[$count] = $validation;
            foreach my $attr ( 'Quality', 'Count' ) {
                $Hash{$attr}[$count] = $Record{$object}{$validation}{$attr};
            }
            if ( $Hash{Quality}[$count] =~ /[1-9]/ ) { $Hash{Quality}[$count] = int( $Hash{Quality}[$count] / $Hash{Count}[$count] ) }    ## normalize accumulating quality means...
            $count++;
        }
    }

    return %Hash;
}

########################################

#This function is should be phased out and removed, use get_zoom_in instead
#############
sub zoom_in {
#############
    my %args            = &filter_input( \@_, -args => 'dbc,type,value', -mandatory => 'dbc,type,value' );
    my $dbc             = $args{-dbc};
    my $type            = $args{-type};
    my $value           = $args{-value};
    my $extra_condition = $args{-condition} || 'Prep_DateTime > DATE_SUB(CURDATE(), INTERVAL 1 month)';      ## default to last 6 months ##
    my $debug           = $args{-debug} || 0;

    my %Hash;
    my %Record;

    #    $Hash{Run_Validation} = [''];
    #    $Hash{Quality} = [0];
    #    $Hash{Count} = [0];

    my $condition = "$extra_condition AND Prep_Name like \"$value\"";
    my $check_field;

    if ( $type eq 'Equipment' ) {
        $check_field = 'FK_Equipment__ID';
    }
    elsif ( $type eq 'Employee' ) {
        $check_field = 'Prep.FK_Employee__ID as FK_Employee__ID';
    }
    elsif ( $type eq 'Solution' ) {
        $check_field = 'FK_Solution__ID';
    }
    else {
        Message("Undefined type: $type (?)");
    }

    my $check_field_alias = $check_field;
    my $check_field_name  = $check_field;
    if ( $check_field =~ /(.+) AS (.+)/i ) {
        $check_field_name  = $1;
        $check_field_alias = $2;
    }
    $condition .= " AND $check_field_name > 0";

    my $order = " ORDER BY $check_field_name";

    ## correlate with specific protocol steps ##
    my %Prepped = $dbc->Table_retrieve(
        "Plate,Plate_Prep,Prep,Library,Lab_Protocol,Original_Source",
        [ 'Plate_ID', 'Plate.FK_Library__Name', 'Plate.Plate_Number', 'Plate.FK_Branch__Code', 'Plate.Plate_Status', $check_field ],
        -condition => "WHERE FK_Library__Name=Library_Name AND FK_Lab_Protocol__ID=Lab_Protocol_ID AND FK_Original_Source__ID=Original_Source_ID AND Plate_Prep.FK_Plate__ID=Plate.Plate_ID AND FK_Prep__ID=Prep_ID AND $condition $order",
        -debug     => $debug
    );

    my $i       = 0;
    my $no_runs = 0;

    my @run_fields = ( 'Run_Validation', 'Q20mean as Quality', 'Count(*) as Runs', 'Wells as Samples' );

    while ( defined $Prepped{Plate_ID}[$i] ) {
        my $plate  = $Prepped{Plate_ID}[$i];
        my $object = $Prepped{$check_field_alias}[$i];
        $i++;
        my $daughters = &alDente::Container::get_Children( -dbc => $dbc, -id => $plate, -format => 'list' ) || 0;

        my %Runs = &Table_retrieve( $dbc, 'Prep,Plate_Prep', [ 'Prep_Name', @monitor_prep_fields ], "WHERE FK_Prep__ID=Prep_ID AND FK_Plate__ID in ($plate,$daughters)" );

        my $group = "GROUP BY Run_Validation";

        my %Info = $dbc->Table_retrieve(
            'Run,RunBatch,SequenceRun,SequenceAnalysis,Plate',
            \@run_fields,
            "WHERE FK_RunBatch__ID=RunBatch_ID AND SequenceAnalysis.FK_SequenceRun__ID=SequenceRun_ID AND SequenceRun.FK_Run__ID=Run_ID AND FK_Plate__ID=Plate_ID AND Plate_ID IN ($plate,$daughters) $group",
            -date_format => 'SQL',
            -debug       => $debug
        );

        my $count = 0;
        while ( defined $Info{Runs}[$count] ) {
            my $quality = $Info{Quality}[$count];

            #                my $samples = $Info{Samples}[$count];
            my $run_count = $Info{Runs}[$count];
            my $run_valid = $Info{Run_Validation}[$count];
            $count++;

            $Record{$object}{$run_valid}{Quality} ||= 0;
            $Record{$object}{$run_valid}{Quality} += $quality * $run_count;

            #                $Record{$object}{$run_valid}{Samples} += $wells;
            $Record{$object}{$run_valid}{Count} += $run_count;
        }

        if ( !$count ) {
            $Record{$object}{'n/a'}{Count}++;
            $Record{$object}{'n/a'}{Quality} = 'n/a';
            $no_runs++;
        }
    }

    ## Populate the overall summary hash ##
    my $count = 0;
    foreach my $object ( sort keys %Record ) {
        foreach my $validation ( keys %{ $Record{$object} } ) {
            $Hash{$check_field_alias}[$count] = $object;
            $Hash{Run_Validation}[$count] = $validation;
            foreach my $attr ( 'Quality', 'Count' ) {
                $Hash{$attr}[$count] = $Record{$object}{$validation}{$attr};
            }
            if ( $Hash{Quality}[$count] =~ /[1-9]/ ) { $Hash{Quality}[$count] = int( $Hash{Quality}[$count] / $Hash{Count}[$count] ) }    ## normalize accumulating quality means...
            $count++;
        }
    }

    print SDB::HTML::display_hash(
        -dbc              => $dbc,
        -title            => "Data results downstream from '$value' step (by $type)",
        -hash             => \%Hash,
        -return_html      => 1,
        -toggle_on_column => 'FK_Equipment__ID',
        -keys             => [ $check_field_alias, 'Count', 'Run_Validation', 'Quality' ],
        -average_columns  => 'Quality',
        -total_columns    => 'Count',
        -highlight_string => { 'Rejected' => 'lightred', 'Approved' => 'lightgreen', 'n/a' => 'lightgrey', 'Pending' => 'lightyellow' },
    );

    print &vspace(5);
    print alDente::Form::start_alDente_form( $dbc, -form => "Diagnostics" );
    print hidden( -name => 'Zoom',      -value => $value );
    print hidden( -name => 'Zoom_Type', value  => $type );
    print Show_Tool_Tip( textfield( -name => 'Zoom Condition', -size => 120, -default => $extra_condition ), "optional SQL condition (referencing Plate or Prep fields) - available for rapid customization - see LIMS Admin if needed" );
    print lbr;
    print submit( -name => 'Sequence Run Diagnostics', -value => 'Regenerate with extra condition', -class => 'Search' );
    print end_form();

    return;
}

########################################

#This function is should be phased out and removed, use show_diagnostics in Diagnostics_App instead
########################################
sub show_sequencing_diagnostics {
########################################
    my %args = &filter_input( \@_, -args => 'dbc,percent,since,until,display_mode' );
    my $dbc     = $args{-dbc}     || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $percent = $args{-percent} || 25;                                                               #### percentage above/below average for flagging.
    my $since   = $args{-since};
    my $until   = $args{ -until };
            my $display_mode      = $args{-display_mode};                                              #### flag for html format or email format.
            my $include_test_runs = $args{-include_test} || 0;
            my $condition         = $args{-condition} || 1;                                            ## optional additional condition
            my $id_ref            = $args{-run_ids};
            my $debug             = $args{-debug};
            my $zoom              = $args{-zoom};                                                      ### zoom in on a particular correlation (step name or heading eg 'Sequencer' or 'Dispense Brew')
            my $zoom_type         = $args{-zoom_type};
            my $zoom_condition    = $args{-zoom_condition};

            my $ids = join ', ', @$id_ref if $id_ref;
            $condition .= " AND Run_ID IN ($ids)" if $ids;

            if ($zoom) {
        return zoom_in( $dbc, $zoom_type, $zoom, -condition => $zoom_condition );
    }

    my $returnval = "<A Name=Top></A>";
    my ( $output, $html ) = sequencing_diagnostics( $dbc, $percent, $since, $until, $display_mode, $include_test_runs, -condition => $condition, -debug => $debug );

    #    my $Verbose=HTML_Table->new();
    #    $Verbose->Set_Title('Item by Item Correlations with Run Quality');
    #    $Verbose->Set_Headers(['Using:','Quality Length','Runs']);

    my $show_poor = 0;    ### flag used to display poor runs..
    my $poor_runs = '';
    my $colour;
    foreach my $line ( split "\n", $output ) {
        if ( $line =~ /^Correlations/i ) {
        }
        if ( $line =~ /^Overall/ ) {
            $returnval .= "\n<A Name=Overall></A>\n";
            $returnval .= h3($line);
        }
        elsif ( $line =~ /^Good/ ) {
            my $state = 'good';

            #	    print h3($line);
            $colour = 'mediumgreenbw';

            #	    $Diagnostics->Set_sub_header("Good Runs (Quality > $percent % above Average)",$color);
        }
        elsif ( $line =~ /^Poor/ ) {
            my $state     = 'bad';
            my $show_poor = 1;       ###### turn on poor runs display.

            #	    print h3($line);
            $colour = 'lightredbw';

            #	    $Diagnostics->Set_sub_header("Poorer Runs (Quality > $percent % above Average)",'lightredbw');
        }
        elsif ( $line =~ /\*/ ) { next; }
        elsif ( $line =~ /^Using(.*):\t(.*)%(.*?)(\d+)/i ) {
            my $item    = $1;
            my $average = $2;
            my $counts  = $4;
            $poor_runs .= "$item\t$average\t$counts\n";
        }
        elsif ( $line =~ /^(.*):(.*?)([\d]+)(.*?(\d+))/i ) {
            my $item    = $1;
            my $average = $2;
            my $counts  = $4;

            #	    $Verbose->Set_Row([$item,$average,$counts],$colour);
        }
        elsif ( $line =~ /^Latest Run:(.*)$/ ) {

            #	    print h3("Latest Recorded Run: $1");
        }
    }
    $returnval .= hr;
    if ($display_mode) { $returnval .= $html; }
    else {
        $output =~ s/\n/<BR>/g;
        $returnval = $output;
    }

    #    if ($verbose) {$Verbose->Printout();}
    return ( $returnval, $poor_runs );    #### return html page and poor_runs listing
}

return 1;

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

$Id: Diagnostics.pm,v 1.10 2004/09/08 23:31:48 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
