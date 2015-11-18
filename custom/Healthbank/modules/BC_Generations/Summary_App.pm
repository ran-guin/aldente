##################
# Statistics_App.pm #
##################
#
# This module is used to monitor Goals for Library and Project objects.
#
package Healthbank::BC_Generations::Summary_App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##

use base Healthbank::Summary_App;
use strict;

use SDB::HTML;
use Healthbank::BC_Generations::Summary_Views;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Summary');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Summary' => 'summary',
        'Generate Summary' => 'summary',
        'Re-Generate Summary' => 'summary',
        );

    my $dbc = $self->param('dbc');
    my $q   = $self->query();

    $self->{dbc} = $dbc;
    $self->update_session_info();
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

##############
sub summary {
###############
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $include_breakdown = $q->param('include_breakdown');
    my $include_times = $q->param('Include Times');
    
    my $page = page_heading("BCG Sample Summary");
    if ($include_breakdown || $include_times) {
        my $since            = $q->param('from_date_range');
        my $until            = $q->param('to_date_range');
        my $first_subject    = $q->param('from_subject');
        my $last_subject     = $q->param('to_subject');
        my $exclude_subjects = $q->param('exclude_subjects');
        my $min_freeze_time  = $q->param('min_freeze_time');
        my $max_freeze_time  = $q->param('max_freeze_time');
        my $layer            = $q->param('Layer');
        my $group            = $q->param('Group');

        my $debug              = $q->param('Debug');
        my $include_times      = $q->param('Include Times');
        my $include_test       = $q->param('Include Test Samples');
        my $include_production = $q->param('Include Production Samples');
        my $prefix             = $q->param('Prefix');

        my $dept = $q->param('Target_Department');
        
        if ($dept eq 'BC_Generations' && !$prefix) { $prefix = 'BC' }
        elsif ($dept eq 'GENIC' && !$prefix) { $prefix = 'SHE' }
        elsif ($dept eq 'MMyeloma' && !$prefix) { $prefix = 'MM' }

        my $condition = $q->param('Condition') || 1;
        my $encoded_condition = $q->param('Encoded_Condition');
        if ($encoded_condition) { $condition = url_decode($condition) }

        my ( $plate_condition, $source_condition ) = ( 1, 1 );
        if   ($include_times) { $plate_condition  = $condition }
        else                  { $source_condition = $condition }

        if ($prefix) {
            $source_condition .= " AND Patient_Identifier LIKE '$prefix%'";
            $plate_condition  .= " AND Plate.Plate_Label LIKE '$prefix%'";
        }

        if ($since)         { 
            $source_condition .= " AND Received_Date >= '$since'";
            $plate_condition .= " AND Plate.Plate_Created >= '$since'";
        }
        if ($until)         { 
            $source_condition .= " AND Received_Date <= '$until 23:59:59'";
            $plate_condition .= " AND Plate.Plate_Created <= '$until 23:59:59'"; 
        }
        if ($first_subject) { 
            $source_condition .= " AND Right(Patient_Identifier,6) >= $first_subject";
            $plate_condition .= " AND MID(Plate.Plate_Label,3,6) >= $first_subject";
        }
        if ($last_subject)  { 
            $source_condition .= " AND Right(Patient_Identifier,6) <= $last_subject";
            $plate_condition .= " AND MID(Plate.Plate_Label,3,6) <= $last_subject";
        }
        if ($exclude_subjects) {
            $exclude_subjects =~ s /(BC|SHE|MM)//g;
            $source_condition .= " AND Right(Patient_Identifier,6) != $exclude_subjects";
            $plate_condition .= " AND MID(Plate.Plate_Label,3,6) != $exclude_subjects";
        }

        if ($min_freeze_time =~ /\S/ ) { $plate_condition .= " AND FreezeTime.Attribute_Value >= $min_freeze_time" }
        if ($max_freeze_time =~ /\S/ ) { $plate_condition .= " AND FreezeTime.Attribute_Value <= $max_freeze_time" }

        if ( !$include_test && $include_production)       { $plate_condition .= " AND Plate.Plate_Test_Status != 'Test'" }
        if ( !$include_production && $include_test) { $plate_condition .= " AND Plate.Plate_Test_Status != 'Production'" }

        ################
        
        $page .= $self->View->bcg_summary( $dbc, -prefix => $prefix, -include_times => $include_times, -source_condition => $source_condition, -plate_condition => $plate_condition );
    }

    $page .= $self->SUPER::summary();
    
    return $page;
}


return 1;

