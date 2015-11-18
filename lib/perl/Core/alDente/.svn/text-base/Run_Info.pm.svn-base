################################################################################
# SDB_Status.pm
#
# This modules provides various status feedback for the Sequencing Database
#
################################################################################
################################################################################
# $Id: Run_Info.pm,v 1.6 2004/08/27 18:19:33 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.85
#     CVS Date: $Date: 2004/08/27 18:19:33 $
################################################################################
package alDente::Run_Info;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Run_Info.pm - SDB_Status.pm

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
SDB_Status.pm<BR>This modules provides various status feedback for the Sequencing Database<BR>CVS Revision: $Revision: 1.85 <BR>

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
);

##############################
# standard_modules_ref       #
##############################

use strict;
use CGI qw(:standard);

#use Storable;
use File::stat;
use Statistics::Descriptive;
use GD;
use GD::Graph;
use GD::Graph::bars;    # was GIFgraph::bars
use Benchmark;

##############################
# custom_modules_ref         #
##############################
#use Imported::gdchart;
use SDB::CustomSettings;
use alDente::SDB_Defaults;
use RGTools::RGIO;
use SDB::HTML;
use SDB::DBIO;
use alDente::Validation;

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
##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

############################################################
# Extract hash of information on a run (or list of runs)
#
#####################
sub get_run_info {
#####################
    my %args = @_;

    my $dbc          = $args{'dbc'} || 0;                ### database handle (required unless source=cache)
    my @run_ids      = @{ $args{'run_ids'} };            ### run ids
    my $well         = $args{'well'};                    ### well (optional) - defaults to entire plate...
    my $source       = $args{'source'} || 'db';          ###
    my $quiet        = $args{'quiet'} || 0;              ### - quiet mode (no feedback)
    my $field_list   = $args{'fields'} || '';            ### - specify information to retrieve (MUST be field in Clone_Sequence table) - optional
    my $Qclipped     = $args{'quality_clipped'} || 0;    ### specify if quality to be clipped from Run/Sequence_Scores...
    my $Vclipped     = $args{'vector_clipped'} || 0;     ### specify if vector to be clipped from Run/Sequence_Scores...
    my $include_test = $args{'include_test'} || 0;
    my $include_NG   = $args{'include_NG'} || 0;
    my $get_stats    = $args{'statistics'} || 0;         ### retrieve statistics as well
    my $group        = $args{'group'} || 0;              ### Future - allow statistical grouping using a particular parameter (eg. Run_ID)

    my %Run_Info;
    my $table = "Clone_Sequence";

    my $well_spec;
    if ($well) { $well_spec .= "AND Well in ('$well') "; }
    unless ($include_test) {
        $table     .= ",Run,SequenceRun";
        $well_spec .= "AND FK_Run__ID=Run_ID AND FK_SequenceRun__ID=SequenceRun_ID";
        $well_spec .= "AND Run_Test_Status like 'Production' ";
    }
    unless ($include_NG) { $well_spec .= "AND Growth IN ('OK','Slow Grow') "; }    ## <construction> - include_NGs is really 'include NGs, Problematic Wells' (but NOT unused or empty ?)

    my @fields;
    if ($field_list) {
        @fields = @$field_list;
    }
    else {
        @fields = ( 'FK_Run__ID', 'Well', 'Sequence', 'Sequence_Length', 'Quality_Left', 'Quality_Length', &Sequencing::Tools::SQL_phred(20) . " as P20", 'Growth' );
    }

    my $id_list = join ',', @run_ids;

    if ( $source =~ /cache/i ) {
        unless ($quiet) { print "Data retrieved from cache\n"; }
    }
    elsif ( $dbc && ( $id_list =~ /\d/ ) ) {
        %Run_Info = &Table_retrieve( $dbc, $table, \@fields, "where FK_Run__ID in ($id_list) $well_spec" );
    }

    if ($Qclipped) {
        unless ( grep /^Quality_Left/,   @fields ) { print "Quality_Left must be included in field_list for Qclipped info\n"; }
        unless ( grep /^Quality_Length/, @fields ) { print "Quality_Left must be included in field_list for Qclipped info\n"; }
        unless ( grep /^Run/,            @fields ) { print "Run or Sequence_Scores must be included in field_list for Qclipped info\n"; }
    }

    unless ( $Qclipped || $Vclipped || $get_stats ) { return %Run_Info; }    ### return the retrieved hash directly (No clipping editing required)

    my @P20;
    my $index = 0;
    while ( defined $Run_Info{Quality_Left}[$index] ) {
        my $qleft   = $Run_Info{Quality_Left}[$index];
        my $qlength = $Run_Info{Quality_Length}[$index];
        my $length  = $Run_Info{Sequence_Length}[$index];
        my $vleft   = $Run_Info{Vector_Left}[$index];
        my $vright  = $Run_Info{Vector_Right}[$index];

        my $sequence   = $Run_Info{Sequence}[$index];
        my $P20        = $Run_Info{P20}[$index];
        my $cut_left   = 0;
        my $cut_length = $length;
        if ($Qclipped) {
            $cut_left = $qleft;
            $qlength  = $qlength;
        }
        if ($Vclipped) {
            if ( ( $vleft > 0 ) && ( $vleft > $cut_left ) ) { $cut_left = $vleft; }
            if ( ( $vright > 0 ) && ( $vright < $qleft + $qlength - 1 ) ) { $qlength = $vright - $qleft; }
            if ( $cut_length > 0 ) {
                my $clipped_sequence = substr( $sequence, $cut_left, $cut_length );
                $Run_Info{Sequence}[$index] = $clipped_sequence;    #### rewrite Run string..
            }
            else { $Run_Info{Sequence}[$index] = ''; }              #### clear Run (all vector)..
        }
        push( @P20, $P20 );
        $index++;
    }

    my $stats = Statistics::Descriptive::Full->new();
    $stats->add_data(@P20);

    $Run_Info{count}  = $stats->count;
    $Run_Info{median} = $stats->median();
    $Run_Info{mean}   = $stats->mean();
    $Run_Info{sum}    = $stats->sum();
    $Run_Info{stddev} = $stats->standard_deviation();
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

$Id: Run_Info.pm,v 1.6 2004/08/27 18:19:33 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
