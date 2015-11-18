#
# SolexaRun.pm
#

package Sequencing::SolexaRun;

@ISA = qw(SDB::DB_Object);

use strict;
use warnings;
use Data::Dumper;
use alDente::Validation;
use SDB::DB_Object;
use SDB::CustomSettings;
use SDB::Session;
use alDente::Run;
use RGTools::RGIO;
use CGI qw(:standard);
use alDente::Tools;
use SDB::HTML;
use alDente::Attribute;
use alDente::Attribute_Views;

# local constants
my $TABLE     = 'SolexaRun,Run';
my $NUM_LANES = 8;

use vars qw( $homelink $Sess );

# ============================================================================
# Returns    : 0 on error, SolexaRun object on success
# ============================================================================
sub new {
    my $this  = shift;
    my $class = ref($this) || $this;
    my %args  = @_;

    my $flowcell_code = $args{-flowcell_code};
    my $lanes_ref     = $args{-lanes};
    my $equipment_id  = $args{-equipment};
    my $dbc           = $args{-dbc} || $Connection;

    # arguments are valid.  Create the object
    my $self = SDB::DB_Object->new(
        -dbc    => $dbc,
        -tables => $TABLE,
    );

    $self->{dbc}           = $dbc;
    $self->{flowcell_code} = $flowcell_code;
    $self->{lanes}         = $lanes_ref;
    $self->{equipment_id}  = $equipment_id;

    if ( defined $args{-id} ) {
        $self->{run_id} = $args{-id};
        my ($id) = $dbc->Table_find( 'SolexaRun', 'SolexaRun_ID', "WHERE FK_Run__ID = $self->{run_id}" );
        $self->{id} = $id;

        $self->primary_value( -table => 'SolexaRun', -value => $id );
        $self->load_Object( -quick_load => 1, -id => $id );
    }
    else {

        # validate lanes
        _Lanes_are_valid(
            -dbc   => $dbc,
            -lanes => $lanes_ref
        ) || return err ( "Invalid lanes", 0 );

        # validate flowcell code
        #_Flowcell_Code_is_valid( $flowcell_code ) || return err( "Invalid flowcell code", 0 );

        # validate equipment
        #_Equipment_type_is_valid( -dbc          => $dbc,
        #		 -equipment_id => $equipment_id
        #			 ) || return err( "Invalid equipment", 0 );
    }

    bless $self, $class;

    return $self;

}

# ============================================================================
# Returns    : n/a
# ============================================================================
# sub load_object {
#     my $self = shift;
#     my $id   = shift || $self->{id};
#
#     if ( !defined $id ) {
#         Message("No ID supplied");
#         return 0;
#     }
#
#     # load flowcell_code, lanes and equipment_id
#
# }

# ============================================================================
# Returns    : n/a
# ============================================================================
sub home_page {
    my $self = shift;

    my $dbc = $self->{dbc};

    print $self->display_Record( -tables => [ 'SolexaRun', 'Run' ] );

}

# ============================================================================
# Returns    : n/a
# ============================================================================
sub request_broker {
    my %args = @_;
    my $dbc = $args{-dbc} || $Connection;
    
	my $user_id = $dbc->config('user_id');
    my $create_runs = param('Create_SolexaRun');

    if ($create_runs) {
        my @plate_ids         = param('Plate_IDs');
        my @used_lanes        = param('Lane_Numbers');
        my @control_lanes     = param('Control_Lane');
        my @spikein_sols      = param('phix_spikein_solution');
        my @spikein_percent   = param('spikein_percentage');
        my $flowcell_code     = param('flowcell_code');
        my $equipment_id      = param('Equipment_ID');
        my $cycles            = param('cycles');
        my $grafted           = param('grafted');
        my $lot_number        = param('lot_number');
        my $flowcell_position = param('Flowcell_Position');
        my $tiles             = param('Tiles');
        my $solexarun_type    = param('SolexaRun_Type');
        my $reagent_cartridge = param('Reagent_Cartridge');
        my $analysis_workflow = param('Analysis_Workflow');
        my $solexarun_mode    = param('SolexaRun_Mode');
        my $custom_primer     = param('Custom_Primer');
        my @lanes             = (0) x $NUM_LANES;
        my $plate_counter     = 0;

        # put plate ids into an array, at position indicated by their lane numbers
        foreach my $index (@used_lanes) {
            $lanes[ $index - 1 ] = $plate_ids[$plate_counter];
            $plate_counter++;
        }

        create_Runs(
            -dbc               => $dbc,
            -run_test_status   => 'Production',
            -plate_ids         => \@lanes,
            -equipment_id      => $equipment_id,
            -flowcell_code     => $flowcell_code,
            -grafted           => $grafted,
            -cycles            => $cycles,
            -tiles             => $tiles,
            -solexarun_type    => $solexarun_type,
            -lot_number        => $lot_number,
            -employee_id       => $user_id,
            -flowcell_position => $flowcell_position,
            -reagent_cartridge => $reagent_cartridge,
            -analysis_workflow => $analysis_workflow,
            -solexarun_mode    => $solexarun_mode,
            -custom_primer     => $custom_primer,
            -control_lanes     => \@control_lanes,
            -spikein_sols      => \@spikein_sols,
            -spikein_percent   => \@spikein_percent
        ) || return err ( "Could not create Runs", 0 );

        # success
        return 1;
    }

    # no valid parameters
    return err ( "No valid parameters passed to request broker", 0 );

}

# ============================================================================
# Returns    : nothing?
# ============================================================================
sub create_Run {
    my $self = shift;
    my %args = @_;

    my $run_options = $args{-run_options} || return err ( "Missing run options parameter", 0 );    # return 0 if no run options passed in

    # assign values
    foreach my $option ( keys %{$run_options} ) {
        $self->value( $option, $run_options->{$option} );
    }

    # TODO: Change global dbc object in DB_Object to argument passed in and check for $self->{dbc}->error();
    # add run to database
    my $run_id = $self->insert();

    return $run_id;
}

# ============================================================================
# Returns    : nothing
# ============================================================================
sub create_Runs {
    my %args = @_;

    my $dbc                  = $args{-dbc};
    my $run_test_status      = $args{-run_test_status};
    my $employee_id          = $args{-employee_id};
    my $equipment_id         = $args{-equipment_id};
    my $plate_id_ref         = $args{-plate_ids};
    my $lot_number           = $args{-lot_number};
    my $cycles               = $args{-cycles};
    my $tiles                = $args{-tiles};
    my $flowcell_position    = $args{-flowcell_position};
    my $solexarun_type       = $args{-solexarun_type};
    my $grafted              = $args{-grafted};
    my $control_lanes_ref    = $args{-control_lanes};
    my $update_flowcell_code = $args{-flowcell_code};
    my $reagent_cartridge    = $args{-reagent_cartridge};
    my $analysis_workflow    = $args{-analysis_workflow};
    my $solexarun_mode       = $args{-solexarun_mode};
    my $custom_primer        = $args{-custom_primer};
    my $spikein_sols         = $args{-spikein_sols};
    my $spikein_percent      = $args{-spikein_percent};
    ## check flowcell code is valid
    #_Flowcell_Code_is_valid($flowcell_code) || return err( "Invalid flowcell", 0 );
    #
    #my $flowcell_code_already_exists = $dbc->Table_find( 'Flowcell',
    #						'Flowcell_Code',
    #							"WHERE Flowcell_Code = '$flowcell_code'"
    #						);

    #if ( $flowcell_code_already_exists ) {
    #    return err( "Flowcell '$flowcell_code' already exists in the database and can not be added again.", 0 );
    #}
    my $run_plates = Cast_List( -list => $plate_id_ref, -to => 'String' );
    my ($flowcell_info) = $dbc->Table_find( 'Flowcell,Tray,Plate_Tray', 'Flowcell_ID,Flowcell_Code', "WHERE Flowcell.FK_Tray__ID = Tray_ID and Plate_Tray.FK_Tray__ID = Tray_ID and FK_Plate__ID in ($run_plates)", -distinct => 1 );

    if ( !$flowcell_info && $update_flowcell_code ) {
        ## Doesn't have flowcell info and need to add to database
        my ($tray_id) = $dbc->Table_find( "Plate_Tray", "FK_Tray__ID", "WHERE FK_Plate__ID IN ($run_plates)" );
        my @fields = ( "Flowcell_Code", "FK_Tray__ID" );
        my @values = ( $update_flowcell_code, $tray_id );
        if ($reagent_cartridge) {
            push @fields, "Flowcell_Reagent_Cartridge";
            push @values, $reagent_cartridge;
        }
        my $new_flowcell_id = $dbc->Table_append_array( "Flowcell", \@fields, \@values, -autoquote => 1 );
        Message($new_flowcell_id);
        $flowcell_info = "$new_flowcell_id,$update_flowcell_code";
    }

    my ( $flowcell_id, $flowcell_code ) = split ',', $flowcell_info;
    ## Check if the flowcell has already been assigned to a run...
    my ($flowcell_assigned) = $dbc->Table_find( 'Flowcell,SolexaRun', 'Flowcell_ID', "WHERE Flowcell_ID = FK_Flowcell__ID and Flowcell_ID = $flowcell_id" );
    if ($flowcell_assigned) {
        $dbc->session->warning("Flowcell has already been run") if $dbc->session;
    }
    Message("Tiles $tiles");
    my $run_batch_id = alDente::Run::create_runbatch(
        -fk_plate__id     => $run_plates,
        -fk_equipment__id => $equipment_id,
        -run_type         => 'SolexaRun',
        -comments         => "",
        -fk_employee__id  => $employee_id,
        -quiet            => 1,
        -dbc              => $dbc
    ) || return err ( "no runbatch", 0 );

    #    my $flowcell_id = add_flowcell(-grafted        => $grafted,
    #				   -flow_cell_code => $flowcell_code,
    #				   -lot_number     => $lot_number,
    #				   -dbc     => $dbc
    #				   ) || return err( "can't add flowcell\n", 0 );

    my $lane_number = 1;
    my $index       = 0;
    my $solexa_plate_links;

    foreach my $plate_id ( @{$plate_id_ref} ) {

        if ($plate_id) {

            # Get run directory name
            my ( $run_dir_name, $error ) = alDente::Run::_nextname(
                -plate_ids    => [$plate_id],
                -check_branch => 0,
                -dbc          => $dbc
            );
            my $solexa_sample_type;
            my $pipeline_code = get_pipeline_of_parent_plate( -dbc => $dbc, -plate_id => $plate_id );
            if ( grep /$plate_id/, @{$control_lanes_ref} ) {
                $solexa_sample_type = 'Control';
            }
            else {
                ## Check the pipeline for the parent plate
                if ( $pipeline_code =~ /SAGE/i ) {
                    $solexa_sample_type = 'SAGE';
                }
                elsif ( $pipeline_code =~ /miRNA/i ) {
                    $solexa_sample_type = 'miRNA';
                }
                elsif ( $pipeline_code =~ /TS/i || $pipeline_code =~ /PET/i ) {
                    $solexa_sample_type = 'TS';
                }
            }

            #my ($slx_pipeline) = $dbc->Table_find('Plate,Pipeline', 'Pipeline_Code', "WHERE FK_Pipeline__ID = Pipeline_ID and Plate_ID = $plate_id");
            #if ($pipeline_code =~/PET/i || $slx_pipeline =~/PES/i) {
            #        $solexa_run_type = 'Paired';
            #}
            # need to check for errors
            if ( defined $error ) { return err ( $error, 0 ); }

            my $run_options = {
                "Run.Run_ID"                   => '',
                "Run.Run_Status"               => 'In Process',
                "Run.Run_Validation"           => 'Pending',
                "Run.Run_Type"                 => 'SolexaRun',
                "Run.FK_Plate__ID"             => "$plate_id",
                "Run.FK_RunBatch__ID"          => "$run_batch_id",
                "Run.Run_DateTime"             => date_time(),
                "Run.Run_Test_Status"          => "$run_test_status",
                "Run.Run_Directory"            => "$run_dir_name->[0]",
                "SolexaRun.Lane"               => "$lane_number",
                "SolexaRun.FK_Flowcell__ID"    => "$flowcell_id",
                "SolexaRun.Cycles"             => "$cycles",
                "SolexaRun.Tiles"              => "$tiles",
                "SolexaRun.Solexa_Sample_Type" => "$solexa_sample_type",
                "SolexaRun.SolexaRun_Type"     => $solexarun_type,
                "SolexaRun.Flowcell_Position"  => "$flowcell_position",
                "SolexaRun.SolexaRun_Mode"     => "$solexarun_mode"
            };

            my $new_run = Sequencing::SolexaRun->new(
                -dbc           => $dbc,
                -lanes         => $plate_id_ref,
                -equipment     => $equipment_id,
                -flowcell_code => $flowcell_code,

                #						     -cycles        => $cycles
            ) || return err ( "can't create SolexaRun in create_Runs()", 0 );

            my $run_id = $new_run->create_Run( -run_options => $run_options ) || return err ( "can't create run", 0 );
            $run_id = $run_id->{newids}{Run}[0];
            $solexa_plate_links .= &Link_To( $dbc->homelink(), $plate_id, "&Scan=1&Barcode=PLA$plate_id", $Settings{LINK_COLOUR} ) . " ";

            if ($analysis_workflow) {
                my $request = alDente::Attribute::set_attribute( -dbc => $dbc, -object => 'Run', -attribute => 'Analysis_Workflow', -id => $run_id, -value => $analysis_workflow );
                require Illumina::MiSeq;
                my $miseq = new Illumina::MiSeq( -dbc => $dbc );
                my $sample_sheet = $miseq->create_sample_sheet( -dbc => $dbc, -run_id => $run_id, -generate_sample_sheet => 1, -custom_primer => $custom_primer );
                $solexa_plate_links .= lbr() . "<PRE>" . $sample_sheet . "</PRE>";
            }

            if ( $spikein_sols->[$index] ) {

                #Adding spike in solution
                my $sol_id     = $spikein_sols->[$index];
                my $percentage = $spikein_percent->[$index];

                if ( $sol_id =~ /$Prefix{Plate}/i ) {
		    require Indexed_Run::Indexed_Run;
                    my $plate_id = alDente::Validation::get_aldente_id( $dbc, $sol_id, 'Plate' );
                    my $indexed_run_obj = Indexed_Run::Indexed_Run->new( -dbc      => $dbc );
                    my $result          = $indexed_run_obj->get_indices( -plate_id => $plate_id );

                    my $count = keys %{$result};
                    if ( $count == 1 ) {
                        for my $key ( keys %{$result} ) {
                            $sol_id = $result->{$key}{solution_id};
                        }
			my $request = alDente::Attribute::set_attribute( -dbc => $dbc, -object => 'Run', -attribute => 'Phix_Spikein_Plate_ID', -id => $run_id, -value => $plate_id );
                    }
                    else {
                        $dbc->warning("Multiplex indices found. Phix spike in solution not entered. Please contact LIMS adamin.");
                        $sol_id = '';
                    }
                }
                else {
                    $sol_id = alDente::Validation::get_aldente_id( $dbc, $sol_id, 'Solution' );
                }

                if ( !$sol_id ) {
                    $dbc->error("Can't find solution id $spikein_sols->[$index]");
                }
                else {

                    #update spikein fields
                    $dbc->Table_update_array( 'SolexaRun', [ 'FKPhix_SpikeIn_Solution__ID', 'SpikeIn_Percentage' ], [ $sol_id, $percentage ], "WHERE FK_Run__ID IN ($run_id)", -autoquote => 1 );
                }
            }
        }
        $index++;
        $lane_number++;
    }

    # success

    print "Success!  Solexa Run created for : $solexa_plate_links \n";
    return 1;
}

# ============================================================================
# Returns    : true/false
# ============================================================================
sub _Equipment_type_is_valid {
    my %args = @_;

    my $dbc          = $args{-dbc};
    my $equipment_id = $args{-equipment_id};

    my ($equipment_type) = $dbc->Table_find(
        'Equipment,Stock,Stock_Catalog,Equipment_Category',
        'Sub_Category', "WHERE Equipment_ID = $equipment_id AND FK_Stock__ID= Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID",
    );

    # will this always be "solexa"?
    return $equipment_type =~ /Genome Analyzer/i ? 1 : 0;

}

# ============================================================================
# Returns    : the equipment id
# ============================================================================
sub get_Equipment_id {
    my $self = shift;

    return $self->{equipment_id};
}

# ============================================================================
# Returns    : 0 on errors, 1 otherwise
# ============================================================================
sub set_Equipment_id {
    my $self = shift;
    my %args = @_;

    my $dbc          = $args{-dbc};
    my $equipment_id = $args{-equipment_id};

    _Equipment_type_is_valid(
        -dbc          => $dbc,
        -equipment_id => $equipment_id,
    ) || return err ( "Invalid equipment type", 0 );

    $self->{equipment_id} = $equipment_id;

    return 1;
}

# ============================================================================
# Returns    : true/false
# ============================================================================
sub _Lanes_are_valid {    # private
    my %args = @_;

    my $lanes_ref = $args{-lanes};
    my $dbc = $args{-dbc} || $Connection;

    # check that there are the correct number of lanes
    return 0 if scalar @{$lanes_ref} != $NUM_LANES;

    # ...and that all the plate ids are valid
    foreach my $plate_id ( @{$lanes_ref} ) {
        if ($plate_id) {
            alDente::Validation::get_aldente_id( $dbc, $plate_id, 'Plate' ) || return err ( "could not get aldente id", 0 );
        }
    }

    # everything passed, so...
    return 1;
}

# ============================================================================
# Returns    : 0 on errors, 1 otherwise
# ============================================================================
sub set_Lanes {
    my $self      = shift;
    my %args      = @_;
    my $dbc       = $args{-dbc} || $Connection;
    my $lanes_ref = $args{-lanes};

    # check that the lanes supplied are valid
    _Lanes_are_valid(
        -dbc   => $dbc,
        -lanes => $lanes_ref
    ) || return err ( "Invalid lanes", 0 );

    $self->{lanes} = $lanes_ref;

    return 1;
}

# ============================================================================
# Returns    : in array context, a list of lanes, else a string of lanes
# ============================================================================
sub get_Lanes {
    my $self = shift;

    return wantarray ? @{ $self->lanes } : join q{,}, @{ self->lanes };
}

# ============================================================================
# Returns    : true/false
# ============================================================================
sub _Flowcell_Code_is_valid {
    my ($flowcell_code) = @_;

    return 0 if !defined $flowcell_code;

    #return $flowcell_code =~ /\A\d+\w+\z/mi ? 1 : 0;
    return 1;

}

# ============================================================================
# Returns    : 0 on error, otherwise 1
# ============================================================================
sub set_Flowcell_Code {
    my $self = shift;
    my %args = @_;

    my $flowcell_code = $args{-flowcell_code};

    _Flowcell_Code_is_valid($flowcell_code) || return err ( "Invalid flowcell code", 0 );

    $self->{flowcell_code} = $flowcell_code;

    return 1;
}

# ============================================================================
# Returns    : flowcell code
# ============================================================================
sub get_Flowcell_Code {
    my $self = shift;

    return $self->{flowcell_code};
}

# ============================================================================
# Returns    : 0 on error, otherwise 1
# ============================================================================
sub display_SolexaRun_form {
    my %args = @_;

    my $hiseq        = $args{-hiseq};
    my $equipment_id = $args{-equipment_id};
    my $plate_ids    = $args{-plate_ids};
    my $dbc          = $args{-dbc};
    my $miseq        = $args{-miseq};
    my $lanes        = $args{-lanes};

    my $equipment_name = '';
    if ($equipment_id) {
        ($equipment_name) = $dbc->Table_find( "Equipment", "Equipment_Name", "WHERE Equipment_ID = $equipment_id" );
    }

    print alDente::Form::start_alDente_form( $dbc, 'SolexaRun_Form', $dbc->homelink() );

    my $solexa_run_table = HTML_Table->new(
        -title => "Enter Solexa Run Information -- $equipment_name",
        -class => 'small'
    );

    my $cycles_text_box = textfield(
        -name  => 'cycles',
        -value => '',
        -force => 1
    );

    my $flowcell_code_text_box = textfield(
        -name  => 'flowcell_code',
        -value => '',
        -force => 1
    );

    my $flowcell_grafted_text_box = textfield(
        -name  => 'grafted',
        -value => '',
        -force => 1
    );

    my $flowcell_lot_number_text_box = textfield(
        -name  => 'lot_number',
        -value => '',
        -force => 1
    );

    $solexa_run_table->Set_Row( [ "Number of Cycles", $cycles_text_box ] );

    #$solexa_run_table->Set_Row( [ "Flowcell Code",             $flowcell_code_text_box       ] );
    #$solexa_run_table->Set_Row( [ "Flowcell Grafted Datetime", $flowcell_grafted_text_box    ] );
    #$solexa_run_table->Set_Row( [ "Flowcell Lot Number",       $flowcell_lot_number_text_box ] );

    my $num_tiles_radio .= radio_group( -name => 'Tiles', -values => [ '32', '48', '64', '96', '100', '120', '200', '300' ], -linebreak => 0 );
    my $solexarun_type_radio .= radio_group( -name => 'SolexaRun_Type', -values => [ 'Single', 'Paired' ], -linebreak => 0 );
    my $flowcell_position_dropdown;
    my $flowcell_code;
    my $reagent_cartridge;
    my $analysis_workflow;
    my $solexarun_mode_radio;
    my $solexarun_mode_default = 'High Throughput';
    my $custom_primer_selection;

    if ( $lanes == 2 ) {
        $flowcell_code = textfield( -name => 'flowcell_code', -value => '', -force => 1 );
        $solexarun_mode_default = 'Rapid';
    }
    if ($hiseq) {
        $flowcell_position_dropdown = popup_menu(
            -name   => 'Flowcell_Position',
            -values => [ 'A', 'B' ],
            -force  => 1
        );
        $solexarun_mode_radio = radio_group( -name => 'SolexaRun_Mode', -values => [ 'High Throughput', 'Rapid' ], -linebreak => 0, -default => $solexarun_mode_default );
    }
    elsif ($miseq) {
        $solexarun_mode_default = 'Rapid';
        $solexarun_mode_radio = hidden( -name => 'SolexaRun_Mode', -value => $solexarun_mode_default, -force => 1 );
        print $solexarun_mode_radio;
        $num_tiles_radio = radio_group( -name => 'Tiles', -values => [ '14', '28', '38' ], -default => 28, -linebreak => 0 );
        $solexarun_type_radio = radio_group( -name => 'SolexaRun_Type', -values => [ 'Single', 'Paired' ], -linebreak => 0, -default => 'Paired' );
        $flowcell_position_dropdown = 'A';
        print hidden( -name => 'Flowcell_Position', -value => 'A' );
        $flowcell_code     = textfield( -name => 'flowcell_code',     -value => '', -force => 1 );
        $reagent_cartridge = textfield( -name => 'Reagent_Cartridge', -value => '', -force => 1 );
        my $prompt;
        my ($attribute_id) = $dbc->Table_find( "Attribute", "Attribute_ID", "WHERE Attribute_Name = 'Analysis_Workflow'" );
        ( $prompt, $analysis_workflow ) = alDente::Attribute_Views::prompt_for_attribute( -dbc => $dbc, -attribute_id => $attribute_id, -name => "Analysis_Workflow", -preset => 'BclOnly' );
        $custom_primer_selection = radio_group( -name => 'Custom_Primer', -values => [ 'None', 'Custom Read 1 primer', 'Custom index primer', 'Custom Read 2 primer', 'Custom Read 1 primer and Custom Read 2 primer' ], -default => 'None', -linebreak => 0 );
    }
    else {
        print hidden( -name => 'Flowcell_Position', -value => 'Not Applicable' );
    }
    $solexa_run_table->Set_Row( [ "Number of Tiles", $num_tiles_radio ] );
    $solexa_run_table->Set_Row( [ "Single/PET Run",  $solexarun_type_radio ] );
    if ( !$miseq ) {
        $solexa_run_table->Set_Row( [ "Run Mode", $solexarun_mode_radio ] );
    }
    $solexa_run_table->Set_Row( [ "Flowcell Position", $flowcell_position_dropdown ] ) if $flowcell_position_dropdown;
    $solexa_run_table->Set_Row( [ "Flowcell",          $flowcell_code ] )              if $flowcell_code;
    $solexa_run_table->Set_Row( [ "Reagent Cartridge", $reagent_cartridge ] )          if $reagent_cartridge;
    $solexa_run_table->Set_Row( [ "Analysis Workflow", $analysis_workflow ] )          if $analysis_workflow;
    $solexa_run_table->Set_Row( [ "Custom Primer",     $custom_primer_selection ] )    if $custom_primer_selection;

    my $create_run_button = submit(
        -name  => "Create_SolexaRun",
        -value => "Create Solexa Run"
    );

    $solexa_run_table->Set_Row( [$create_run_button] );

    my $plate_lanes_table = HTML_Table->new(
        -title => 'Current Lanes',
        -class => 'small'
    );

    # find lane numbers
    my %used_lanes;
    foreach my $plate_id ( @{$plate_ids} ) {

        my ($plate_position) = $dbc->Table_find( 'Plate_Tray', 'Plate_Position', "WHERE FK_Plate__ID = $plate_id" );

        # check that the lane hasn't already been used
        if ( defined $used_lanes{$plate_position} ) {
            return err ( "Multiple plates tried to use the same lane.  This should never happen.", 0 );
        }

        $used_lanes{$plate_position} = $plate_id;
    }

    # check that there are only the correct number of lanes
    if ( scalar keys %used_lanes > $NUM_LANES ) {
        return err ( "There can not be more than $NUM_LANES lanes requested on a Solexa Run.", 0 );
    }

    $plate_lanes_table->Set_Headers( [ 'Lane', 'Plate ID', 'Control Lane', 'Phix SpikeIn Solution ID', 'SpikeIn Percentage' ] );

    foreach my $lane ( sort keys %used_lanes ) {
        my $plate_id           = $used_lanes{$lane};
        my $plate_info         = alDente_ref( 'Plate', $plate_id, -dbc => $dbc );
        my $control_lane       = checkbox( -name => 'Control_Lane', -value => $plate_id, -force => 1, -label => '' );
        my $spikein_solution   = textfield( -name => "phix_spikein_solution", -force => 1 );
        my $spikein_percentage = textfield( -name => "spikein_percentage", -force => 1 );

        $plate_lanes_table->Set_Row( [ $lane, $plate_info, $control_lane, $spikein_solution, $spikein_percentage ] );

        print hidden( -name => 'Plate_IDs',    -value => $plate_id );
        print hidden( -name => 'Lane_Numbers', -value => $lane );
    }

    print hidden( -name => 'SolexaRun',    -value => 'SolexaRun' );
    print hidden( -name => 'Equipment_ID', -value => $equipment_id );

    $solexa_run_table->Printout();
    print "<br />\n";
    $plate_lanes_table->Printout();

    return 1;
}

sub transfer_to_flowcell_btn {
##############################
    my %args                 = filter_input( \@_, -args => 'dbc' );
    my $dbc                  = $args{-dbc};
    my $miseq                = $args{-miseq};
    my $default_plate_format = $args{-plate_format} || '8-well FlowCell';

    $default_plate_format = 'FlowCell' if $miseq;
    my $plate_format = hidden( -name => 'Target Plate Format', -value => $default_plate_format );
    my $plate_action = hidden( -name => 'Plate_Action',        -value => 'Aliquot', -force => 1 );
    my $plate_event  = hidden( -name => 'Plate_Event',         -value => 'Go', -force => 1 );
    my $plate_type   = hidden( -name => 'Plate_Type',          -value => 'Tube', -force => 1 );
    my $pipeline_set .= "  Pipeline: " . &alDente::Tools::search_list( -dbc => $dbc, -name => 'FK_Pipeline__ID', -filter_by_dept => 1, -search => 1, -filter => 1 );

    #my $onClick = "SetSelection(this.form,'Action','Aliquot');SetSelection(this.form,'Plate_Event','Go');SetSelection(this.form,'Plate_Type','Tube');sub_cgi_app( 'Illumina::Run_App' )";
    my $onClick = "sub_cgi_app( 'Illumina::Run_App' )";

    my $form_output;
    $form_output .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Transfer To Flowcell', -class => 'Action', -onClick => $onClick, -force => 1 ), "Create flowcell for the selected tubes" );
    $form_output .= $pipeline_set . $plate_format . $plate_action . $plate_event . $plate_type;
    $form_output .= hidden( -id => 'sub_cgi_application', -force => 1 );
    $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true', -force => 1 );
    return $form_output;
}
##############################
sub set_protected_status_btn {
##############################
    return submit( -name => 'Set Protected Status', -value => 'Protect Images', -class => 'Action' );
}

# Catches the files status btn, sets the status of the files for that run to "Delete/Move"
#
# Returns: none
############################
sub catch_set_protected_status_btn {
############################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};
    my $confirmed;    # = param('Confirm Protection');
    my $run_id = get_param( -parameter => 'Mark', -list => 1, -empty => 0 ) || get_param( -parameter => 'run_id', -list => 1 );
    my @runs = Cast_List( -list => $run_id, -to => 'Array' );
    my $num_updated = 0;
    if ( param('Set Protected Status') eq 'Protect Images' ) {
        $num_updated = set_solexa_protected_flag( -dbc => $dbc, -run_id => \@runs, -status => 'Yes' );
        $dbc->message("$num_updated runs were Protected");
    }
    elsif ( param('Set Protected Status') eq 'Un-Protect Images' ) {
        $num_updated = set_solexa_protected_flag( -dbc => $dbc, -run_id => \@runs, -status => 'No' );
        $dbc->message("$num_updated runs were un-protected");
    }
    else {
        ## Do not do anything
    }
    return;
}

############################
sub slx_run_validation_btn {
############################
    my %args = filter_input( \@_, -args => "dbc" );
    my $dbc = $args{-dbc};
    return alDente::Run::run_validation_btn( -btn_name => 'Set_SolexaRun_Validation_Status', -dbc => $dbc );
}

############################
sub catch_slx_run_validation_btn {
############################
    my %args         = filter_input( \@_, -args => "dbc,validation,runs" );
    my $dbc          = $args{-dbc};
    my $validation   = $args{-validation} || param('Validation Status');
    my $auto_comment = $args{-auto_comment} || param('Auto_Comment');                                                                                      ### flag to automatically comment run with validation stamp (user date)
    my $run          = $args{-run_id} || get_param( -parameter => 'Mark', -empty => 0, -list => 1 ) || get_param( -parameter => 'run_id', -list => 1 );    ## array ref to list of run_ids
    my $comments     = $args{-comments} || param('Comments');
    my $set_status   = $args{-set_status} || param('Set_SolexaRun_Validation_Status');                                                                     ## not sure why this is necessary, but included to prevent changing logic
    if ($set_status) {
        my $ok = alDente::Run::set_validation_status( -dbc => $dbc, -run_ids => $run, -status => $validation, -auto_comment => $auto_comment );
        if ( $validation eq 'Rejected' ) { my $non_billable = alDente::Run::set_billable_status( -dbc => $dbc, -run_id => $run, -billable_status => 'No' ); }
    }
    return 1;
}

sub set_run_qc_status_btn {
    my %args              = filter_input( \@_, -args => 'dbc' );
    my $dbc               = $args{-dbc};
    my $run_qc_status_btn = submit( -name => 'Set Run QC Status', -value => 'Set Run QC Status', -class => 'Action' );

    $run_qc_status_btn .= hspace(10)
        . popup_menu(
        -name    => 'Run_QC_Status',
        -values  => [ '', $dbc->get_enum_list( 'Run', 'QC_Status' ) ],
        -default => '',
        -force   => 1
        );
    return $run_qc_status_btn;
}

sub catch_run_qc_status_btn {
    my %args          = filter_input( \@_, -args => "dbc,run_qc_status,run_id" );
    my $dbc           = $args{-dbc};
    my $run_qc_status = $args{-run_qc_status} || param('Run_QC_Status');
    my $run           = $args{-run_id} || get_param( -parameter => 'Mark', -empty => 0, -list => 1 ) || get_param( -parameter => 'run_id', -list => 1 );    ## array ref to list of run_ids
    my $auto_comment  = $args{-autocomment} || param('Auto_Comment');
    my $comments      = $args{-comments} || param('Comments');
    my $set_status    = $args{-set_status} || param('Set Run QC Status');
    if ($set_status) {
        my $ok = alDente::Run::set_run_qc_status( -dbc => $dbc, -run_ids => $run, -qc_status => $run_qc_status, -auto_comment => $auto_comment, -comments => $comments );
    }
    return 1;
}

##############################
sub set_unprotect_status_btn {
##############################
    return submit( -name => 'Set Protected Status', -value => 'Un-Protect Images', -class => 'Action' );
}

# Set the Solexa Protected status
#
# Returns: number of runs updated
######################
sub set_solexa_files_status {
######################
    my %args   = filter_input( \@_, -args => 'dbc,run_id,status' );
    my $dbc    = $args{-dbc};
    my $run_id = $args{-run_id};
    my $status = $args{-status};

    my $run_ids = Cast_List( -list => $run_id, -to => 'String' );
    my @available_statuses = get_solexa_files_status_list( -dbc => $dbc );
    my $num_runs_updated;
    if ( grep /^$status$/, @available_statuses ) {
        $num_runs_updated = $dbc->Table_update_array( 'SolexaRun', ['Files_Status'], [$status], "WHERE FK_Run__ID IN ($run_ids)", -autoquote => 1 );
    }
    return $num_runs_updated;
}
###############################
sub set_solexa_protected_flag {
###############################
    my %args             = filter_input( \@_, -args => 'dbc,run_id,status' );
    my $dbc              = $args{-dbc};
    my $run_id           = $args{-run_id};
    my $status           = $args{-status};
    my $run_ids          = Cast_List( -list => $run_id, -to => 'String' );
    my $num_runs_updated = $dbc->Table_update_array( 'SolexaRun', ['Protected'], [$status], "WHERE FK_Run__ID IN ($run_ids)", -autoquote => 1 );
    return $num_runs_updated;
}
#############################
sub get_solexa_files_status_list {
#############################
    my %args                  = filter_input( \@_, -args => 'dbc' );
    my $dbc                   = $args{-dbc};
    my @solexa_files_statuses = $dbc->get_enum_list( 'SolexaRun', 'Files_Status' );
    return @solexa_files_statuses;
}

# Get a list of solexa runs that are in progress
#
#
#########################
sub get_in_process_runs {
#########################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my %in_process_runs = $dbc->Table_retrieve(
        'SolexaRun,Run,Flowcell',
        [ 'Run_ID', 'Run_Directory', 'Flowcell_ID', 'Flowcell_Code', 'Lane', 'Solexa_Sample_Type', 'SolexaRun_Type', 'Cycles' ],
        "WHERE FK_Run__ID = Run_ID and FK_Flowcell__ID = Flowcell_ID and Run_Status = 'In Process' and Run_Validation NOT IN ('Rejected','Approved')",
        -order_by => "Run_ID,Lane"
    );

    return \%in_process_runs;
}

# Get a list of solexa runs that are in progress
#
#
#########################
sub get_data_acquired_runs {
#########################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my %data_acquired_runs = $dbc->Table_retrieve(
        'SolexaRun,Run,Flowcell,RunBatch',
        [ 'Run_ID', 'Flowcell_ID', 'Flowcell_Code', 'Lane', 'Solexa_Sample_Type', 'SolexaRun_Type', 'FK_Equipment__ID' ],
        "WHERE FK_Run__ID = Run_ID and FK_RunBatch__ID = RunBatch_ID and FK_Flowcell__ID = Flowcell_ID and Run_Validation NOT IN ('Rejected','Approved') and Run_Status = 'Data Acquired'",
        -order_by => "Run_ID,Lane"
    );

    return \%data_acquired_runs;
}

########################
sub get_solexa_run_validation {
########################
    my %args           = filter_input( \@_, -args => "dbc,library" );
    my $dbc            = $args{-dbc};
    my $library        = $args{-library};
    my $run_validation = $args{-run_validation};

    my @libraries = Cast_List( -list => $library, -to => 'Array' );

    my @run_counts;
    foreach my $library (@libraries) {
        my ($run_count) = $dbc->Table_find( 'Plate,SolexaRun,Run', "count(Run_ID)", "WHERE FK_Plate__ID = Plate_ID and FK_Run__ID = Run_ID and FK_Library__Name = '$library' and Run_Status <> 'Failed' and Run_Validation = '$run_validation'" );
        push @run_counts, $run_count;
    }
    return \@run_counts;
}

sub get_flowcell_plate_count {
    my %args            = filter_input( \@_, -args => 'dbc,library' );
    my $dbc             = $args{-dbc};
    my $library         = $args{-library};
    my $flowcell_status = $args{-flowcell_status};

    my @libraries = Cast_List( -list => $library, -to => 'Array' );

    my $add_tables;
    my $extra_condition;
    if ( $flowcell_status eq 'Scheduled' ) {
        $add_tables      = "LEFT JOIN Flowcell ON Plate_Tray.FK_Tray__ID = Flowcell.FK_Tray__ID LEFT JOIN Fail on Plate_ID = Object_ID and FK_Object_Class__ID IN ( SELECT Object_Class_ID from Object_Class where Object_Class = 'Plate') ";
        $extra_condition = " and Flowcell_ID is NULL and Fail_ID is NULL";
    }
    elsif ( $flowcell_status eq 'Queued' ) {
        $add_tables
            = "JOIN Flowcell ON Plate_Tray.FK_Tray__ID = Flowcell.FK_Tray__ID LEFT JOIN Run ON Run.FK_Plate__ID = Plate_ID LEFT JOIN Fail on Plate_ID = Object_ID and FK_Object_Class__ID IN ( SELECT Object_Class_ID from Object_Class where Object_Class = 'Plate') ";
        $extra_condition = " and Run.FK_Plate__ID is NULL and Fail_ID is NULL";
    }
    my @counts = ();
    foreach my $library (@libraries) {
        my ($plate_count) = $dbc->Table_find(
            "Plate,Plate_Format,Plate_Tray $add_tables",
            "count(distinct Plate_ID)",
            "WHERE Plate_Format_ID = Plate.FK_Plate_Format__ID and Plate_Format_Type like '%Flowcell%' and Plate_Tray.FK_Plate__ID = Plate_ID and FK_Library__Name = '$library' $extra_condition"
        );
        push @counts, $plate_count;
    }

    return \@counts;
}

# Get the pipeline for the tube used to make the flow cell
#
#
##################################
sub get_pipeline_of_parent_plate {
##################################
    my %args     = filter_input( \@_, -args => 'dbc,plate_id' );
    my $plate_id = $args{-plate_id};
    my $dbc      = $args{-dbc};
    my ($pipeline) = $dbc->Table_find( 'Plate,Plate as Parent,Pipeline', "Pipeline_Name", "WHERE Parent.FK_Pipeline__ID = Pipeline.Pipeline_ID and Plate.Plate_ID = $plate_id and Plate.FKParent_Plate__ID = Parent.Plate_ID" );
    return $pipeline;
}

# Given a flowcell and lane or run_id, find the end read type for the run
#
# Usage:
#
# my $solexarun_type = get_solexarun_type(-dbc=>$dbc,-run_id=>20319);
#
# my $solexarun_type = get_solexarun_type(-dbc=>$dbc,-flowcell=>"FC1222",-lane=>1);
#
# Return: End Read Type
#######################
sub get_solexarun_type {
#######################
    my %args            = filter_input( \@_, -args => 'dbc,run_id,flowcell,lane' );
    my $dbc             = $args{-dbc};
    my $run_id          = $args{-run_id};
    my $flowcell        = $args{-flowcell};
    my $lane            = $args{-lane};
    my $extra_condition = "";
    if ($run_id) {
        $run_id = Cast_List( -list => $run_id, -to => 'String', -autoquote => 1 );
        $extra_condition .= " AND Run_ID IN ($run_id)";
    }
    elsif ( $flowcell && $lane ) {
        $extra_condition .= "AND Flowcell_Code = '$flowcell' AND Lane = '$lane'";
    }
    else {
        Message("No condition set");
        return 0;
    }

    my ($solexarun_type) = $dbc->Table_find(
        'SolexaRun,Run,Flowcell', 'SolexaRun_Type', "WHERE FK_Flowcell__ID = Flowcell_ID
                                                                                        and FK_Run__ID = Run_ID
                                                                                        $extra_condition"
    );
    return $solexarun_type;
}

##################
sub get_taxonomy {
##################
    my %args          = filter_input( \@_, -args => 'dbc,run_id' );
    my $dbc           = $args{-dbc};
    my $run_id        = $args{-run_id};
    my ($taxonomy_id) = $dbc->Table_find(
        'Run,Plate,Library,Original_Source', 'FK_Taxonomy__ID',
        "WHERE FK_Plate__ID = Plate_ID and 
                                         Library_Name = FK_Library__Name and 
                                         FK_Original_Source__ID = Original_Source_ID and 
                                         Run_ID = $run_id"
    );
    return $taxonomy_id;
}

# Get the number of flowcells that have finished running since a given date
#
#
#######################
sub get_flowcells_run {
#######################
    my %args  = filter_input( \@_, -args => 'dbc,since' );
    my $since = $args{-since};
    my $dbc   = $args{-dbc};

    my ($number_flowcells_run) = $dbc->Table_find( 'Flowcell,Run,SolexaRun', "count distinct(Flowcell_Code)", "WHERE FK_Run__ID =Run_ID and FK_Flowcell__ID = Flowcell_ID and SolexaRun_Finished > '$since'" );
    return $number_flowcells_run;
}

# Wrapper get the qc status for a list of libraries
#
#
###########################################
sub get_solexarun_qc_status_for_libraries {
###########################################
    my %args           = filter_input( \@_, -args => 'dbc,library' );
    my $dbc            = $args{-dbc};
    my $library        = $args{-library};
    my $run_validation = $args{-run_validation};
    my @libraries      = Cast_List( -list => $library, -to => 'Array' );
    my @qc_status;
    foreach my $lib (@libraries) {
        my $qc_status = get_solexarun_qc_status( -dbc => $dbc, -library => $lib, -limit => 1, -run_validation => $run_validation );
        push @qc_status, $qc_status;
    }

    return \@qc_status;
}

# Get the qc status for a solexarun
#
#
#
###############################
sub get_solexarun_qc_status {
###############################
    my %args           = filter_input( \@_, -args => 'dbc,library,flowcell,lane,run_validation,limit' );
    my $dbc            = $args{-dbc};
    my $library        = $args{-library};
    my $flowcell       = $args{-flowcell};
    my $lane           = $args{-lane};
    my $run_validation = $args{-run_validation};
    my $limit          = $args{-limit};

    my $condition;

    if ($library) {
        $condition .= " AND Library_Name IN ('$library')";
    }
    if ( $flowcell && $lane ) {
        $condition .= " AND Flowcell_Code IN ('$flowcell') and Lane in ($lane)";
    }

    if ($run_validation) {

        $condition .= " AND Run_Validation IN ('$run_validation')";
    }

    my $qc_status;

    ($qc_status) = $dbc->Table_find(
        'SolexaRun,Run,Plate,Library', 'Run.QC_Status', "WHERE 
                                                                                SolexaRun.FK_Run__ID = Run_ID and 
                                                                                Plate.Plate_ID = Run.FK_Plate__ID and 
                                                                                Plate.FK_Library__Name = Library_Name $condition", -limit => $limit
    );

    return $qc_status;
}

1;

__END__

    =head1 NAME

Sequencing::SolexaRun - This module handles routines specific to Solexa Runs

    =head1 VERSION

    This documentation refers to Sequencing::SolexaRun version 0.0.1.

    =head1 SYNOPSIS

use Sequencing::SolexaRun;
my @lanes = ();
my $equipment_id;
my $solexa_run = Sequencing::SolexaRun->new( -lanes => \@lanes, -equipment => $equipment_id );

$solexa_run->display_SolexaRun_form();

===============

    ISA alDente::Run;

sub new {

    my $self;
    my %args = filter_input( \@_, -arguments => "equipment,lanes,flowcell_code" );

    my $equipment     = $args{-equipment    };
    my $lanes         = $args{-lanes        };
    my $flowcell_code = $args{-flowcell_code};

    $self->{Lanes        } = ( 0, 0, $plate1, 0, $plate2, 0, 0, 0);
    $self->{Flowcell_Code} = "";
    $self->{Equipment    } = "";  ## The Solexa Sequence Reader

}


sub request_broker {
    ## parse out the HTML Parameters

    my $solexa_run = Solexa_Run->new( -lanes => $lanes, -flowcell_code => $flowcell );

    $solexa_run->create_Run();

    return;
}


sub create_Run {

    $self->SUPER::create_run_batch( -equipment => $self->{equipment} );  #returns batch_id, do we want to capture that?  Also, does it have to be a SUPER?
    $self->SUPER::create_run();
    ### add solexa specific attributes

}

sub set_Lanes {
}

sub set_Flowcell_Code {



}

sub get_Lanes {
}

sub get_Flowcell_Code {
}

sub display_Lane_selection {
}

sub display_Flowcell_selection {
}

sub display_SolexaRun_form {

    $self->display_Lane_selection();
    $self->display_Flowcell_selection();

}


===============

    create SolexaRun => database

    create Run from Run.pm

    call create run batch

    find flowcell_code

    add flowcell_code to the SolexaRun / add attribute for Flowcell number

    add attribute for Lanes

    select lane

    get/set

    find Solexa equipment


    =head1 DESCRIPTION

    Description goes here

    =head1 SUBROUTINES/METHODS

    =head2 Public Subroutines/Methods

    =head2 Private Subroutines/Methods

    =head1 DIAGNOSTICS

    =head1 CONFIGURATION AND ENVIRONMENT

    =head1 DEPENDENCIES

    =head1 INCOMPATIBILITIES

    =head1 BUGS AND LIMITATIONS

    =head1 EXAMPLES

    =head1 COMMON USAGE MISTAKES

    =head1 NOTES
