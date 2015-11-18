#######################################
#
# This module handles custom data access functions for the Mapping plug-in
#
#######################################
package Mapping_API;

=head1 SYNOPSIS <UPLINK>

#### Example of Usage ####

###########################################
###########################################
use Mapping::Mapping_API;

my $API = Mapping_API->new(
        -host=>'lims02', 
        -dbase=>'seqtest',
        -LIMS_user=>'Reza',
        -LIMS_password=>'*****',
        -DB_user=>'mapper_admin',
        -DB_password=>'******',
        -connect=>1
        );

$API->connect();

###########################################
###########################################
## set analysis status ##
$API->set_analysis_status(
    -run_ids=>'62928',
    -status=>'Bandcalled',
    -details=>{Bandleader_Version=>'3.2.4'},
    -timestamp=>'2007-01-01 12:34:57');


Status can be any of the following: [Started, Lanetracked, Bandcalled, Marker Checked, Marker Edited, Data Captured, Sanitized, Self Checked, Cross Checked, Swap Checked, Submited, Completed FPC, Completed, Re-Analyze]

Details can be any of the following: [Gel_Name, Bandleader_Version, Swap_Check, Index_Check]


###########################################
###########################################
## Create Lanes for a given Run ID ##
$API->create_lanes( -run_ids=>'62928' );


If a set of Lanes have already been created, '-force' can be supplied to the create_lanes() method to overwrite Lane information


###########################################
###########################################
## Fail a set of lanes for a given Run ID ##
$API->fail_lane(
         -run_id=>'5000',
         -lanes=>'12,18,103',
         -reason=>'Manually Deselected',
         -comments=>'Optional comment'
         );


###########################################
###########################################
## Create/Update Bands for a given Run ID ##
%bands = ( 
             'run_id' => {
                       'lane' => {
                                  'bands' = [bands_array],
                                  'sizes' = [sizes_array]
                                }
             },
             '5000' => {
                       1 => {
                                  'bands' => [889, 936, 1089, 1127, 1167, 1248, 1274, 1382, 1453],
                                  'sizes' => [435, 477, 527,  544,  555,  581,  683,  685,  760]
                       },
                       2 => {
                                  'bands' => [889, 936, 1089, 1127, 1167, 1248, 1274, 1382, 1453],
                                  'sizes' => [435, 477, 527,  544,  555,  581,  683,  685,  760]
                       }
                        ...
             },
          );
$API->update_bands(-bands=>\%bands);


#######################################################################
# Note: for more options and details see alDente::alDente_API module ##
#######################################################################

=cut


##############################
# superclasses               #
##############################
@ISA = (alDente::alDente_API);

##############################
# standard_modules_ref       #
##############################
use strict;
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
use alDente::alDente_API;
use alDente::GelAnalysis;
use RGTools::RGIO;

##################
#
# <snip>
#       my $API = Mapping::Mapping_API->new(-host=>'lims02',-dbase=>'sequence',-user=>'rsanaie',-password=>'*****');
#       $API->connect();
# </snip>
#
#########
sub new {
#########
    my $class   = shift;
    my %params  = @_;
    my $self    = alDente::alDente_API->new(@_);
    return (bless($self, $class));
}



############################
#
# <snip>
#       $API->set_analysis_status(-run_ids=>'1,2',-status=>'Bandcalled',-timestamp=>'2007-01-01 12:34:57');
# </snip>
#
############################
sub set_analysis_status {
############################
    my $self = shift;
    $self->log_parameters(@_);
    my $start = timestamp();

    my %args = &filter_input(\@_,-args=>'run_ids,status',-mandatory=>'run_ids,status');
    if($args{ERRORS}) {
        Message($args{ERRORS});
        return 0;
    }
    $args{-dbc} = $self;
    $args{-run_type} = 'Gel';
    my $output = &alDente::Run::set_analysis_status(%args);
    return $self->api_output(-data=>$output,-start=>$start,-log=>1,-customized_output=>1);
}

############################
#
# <snip>
#       $API->fail_lane(
#                -run_id=>'5000',
#                -lanes=>'12,18,103',
#                -reason=>'Manually Deselected',
#                -comments=>'Optional comment'
#                );
# </snip>
#
############################
sub fail_lane {
############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_,-args=>'run_id,lanes,reason',-mandatory=>'run_id,lanes,reason');
    my $run_id = $args{-run_id};       # mandatory run_id specification (only one per call)
    my $lanes = $args{-lanes};         # mandatory list of lanes (comma-delimited string or array reference)
    my $reason = $args{-reason};       # mandatory reason (text)
    my $comments = $args{-comments};   # optional comments
    if($args{ERRORS}) {
        Message($args{ERRORS});
        return 0;
    }
    my $start = timestamp();

    require alDente::Lane;

    $args{-dbc} = $self;
    my $output = &alDente::Lane::fail_lanes(%args);
    return $self->api_output(-data=>$output,-start=>$start,-log=>1,-customized_output=>1);

}

############################
#
# <snip>
#       $API->unfail_lane(
#                -run_id=>'5000',
#                -lanes=>'12,18,103',
#                );
# </snip>
#
############################
sub unfail_lanes {
############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_,-args=>'run_id,lanes',-mandatory=>'run_id,lanes');
    my $run_id = $args{-run_id};       # mandatory run_id specification (only one per call)
    my $lanes = $args{-lanes};         # mandatory list of lanes (comma-delimited string or array reference)
    if($args{ERRORS}) {
        Message($args{ERRORS});
        return 0;
    }
    my $start = timestamp();

    require alDente::Lane;

    $args{-dbc} = $self;
    my $output = &alDente::Lane::unfail_lanes(%args);
    return $self->api_output(-data=>$output,-start=>$start,-log=>1,-customized_output=>1);

}
############################
#
# <snip>
#       $API->create_lane(
#                -run_ids=>'5000,5001',
#                );
# </snip>
#
############################
sub create_lanes {
############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_,-args=>'run_ids',-mandatory=>'run_ids');
    if($args{ERRORS}) {
        Message($args{ERRORS});
        return 0;
    }
    my $start = timestamp();

    require alDente::Lane;
    $args{-dbc} = $self;
    my $output = &alDente::Lane::create_lanes(%args);
    return $self->api_output(-data=>$output,-start=>$start,-log=>1,-customized_output=>1);
}

####################################
#
# <snip>
#       $API->update_bands(-bands=>\%bands);
# </snip>
#
#  %bands = ( 
#               'run_id' => {
#                         'lane' => {
#                                    'mobilities' => [mobilities_array],
#                                    'sizes' => [sizes_array]
#                                  }
#               },
#               '5000' => {
#                         1 => {
#                                    'mobilities' => [889, 936, 1089, 1127, 1167, 1248, 1274, 1382, 1453],
#                                    'sizes' => [435, 477, 527,  544,  555,  581,  683,  685,  760]
#                         },
#                         2 => {
#                                    'mobilities' => [889, 936, 1089, 1127, 1167, 1248, 1274, 1382, 1453],
#                                    'sizes' => [435, 477, 527,  544,  555,  581,  683,  685,  760]
#                         }
#                          ...
#               },
#            );
#
###################
sub update_bands {
###################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_,-args=>'bands',-mandatory=>'bands');
    if($args{ERRORS}) {
        Message($args{ERRORS});
        return 0;
    }
    my $start = timestamp();

    require alDente::GelRun;
    $args{-dbc} = $self;
    my $output = &alDente::GelRun::update_gel_bands(%args);
    return $self->api_output(-data=>$output,-start=>$start,-log=>1,-customized_output=>1);

}

# Updates the plate samples and the lane mapping
# Example:
#
# <snip>
#     my $num_wells_updated = $API->update_rearray_well_map(-rearray_request=>12345,
#                                                           -target_plate=>117,
#                                                           -target_wells=>['A02','A01'],
#                                                           -source_wells=>['A01','A03'],
#                                                           -source_plates=>[5000,5001]);
# </snip>
# Returns: Number of wells updated
#########################
sub update_lane_mapping {
#########################
    my $self = shift;
    my %args = filter_input(\@_); 
    
    require alDente::ReArray;
    
    my $rearray_obj = alDente::ReArray->new(-dbc=>$self);
    my $num_wells_updated = $rearray_obj->update_rearray_well_map(%args);
    my $target_plate = $args{-target_plate};
    
    ## update the lane mapping because the redundant sample ids are now incorrect 
    $self->query(-query=>"UPDATE Plate_Sample,Run,GelRun,Lane,Plate SET Lane.FK_Sample__ID=Plate_Sample.FK_Sample__ID WHERE Plate_Sample.Well = Lane.Well and Run.FK_Plate__ID = Plate.Plate_ID and GelRun.FK_Run__ID = Run_ID and Plate.FKOriginal_Plate__ID = Plate_Sample.FKOriginal_Plate__ID and Plate_Sample.FKOriginal_Plate__ID = $target_plate and GelRun_ID = Lane.FK_GelRun__ID and Lane.FK_Sample__ID <> Plate_Sample.FK_Sample__ID"); 
    return $num_wells_updated;
}

return 1;

