###################################################################################################################################
# alDente::Prep_Views.pm
#
#
#
#
###################################################################################################################################
package alDente::Prep_Views;

use strict;
use CGI qw(:standard);
use Benchmark;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::RGmath;

use alDente::Prep;
use alDente::Rack_Views;
use alDente::Attribute_Views;

use vars qw(%Prefi  %Benchmark);

use LampLite::CGI;

my $q = new LampLite::CGI;

#################
sub prompt_Step {
#################
    my $Prep             = shift;
    my %args             = &filter_input( \@_ );
    my $instructions     = $args{-instructions} || 0;
    my $confirm_fail     = $args{-confirm_fail} || 0;
    my $repeat_last_step = $args{-repeat_last_step};
    my $step_num         = $args{-step_num};
    my $append           = $args{-append};                ## optionally append step name for recorded prep with string.
    my $attachment       = $args{-attachment};
    my $dbc              = $Prep->{dbc} || $args{-dbc};

    my $prompt = alDente::Container::Display_Input($dbc);
    if ($repeat_last_step) {
        ## Set the current step to the step number
        $Prep->{thisStep}         = $step_num;
        $Prep->{repeat_last_step} = 1;
    }

    if ( !$scanner_mode ) { print '<h2>Protocol: ' . $Prep->{protocol_name} . '</h2>' }

    $current_plates ||= $Prep->{plate_ids};

    my $protocol    = $Prep->{protocol_name};
    my $protocol_id = $Prep->{protocol_id};

    ## get count of plates ##
    my $count += () = $Prep->{plate_ids} =~ /,/g;
    $count++;

    unless ( $Prep->check_valid_plates() ) {
        $dbc->error("Invalid plates found in plate set, cannot proceed with protocol");
        &main::leave();
    }
    if ( $Configs{pipeline_tracking} ) {
        $Prep->check_pipeline_status();
    }

    #$scanner_mode = 1;
    my $space;
    my $span             = 'small';
    my $textbox_size     = 15;
    my $css_class        = 'small';
    my $html_table_width = 400;
    if ( !$scanner_mode ) {
        $span             = 'medium';
        $textbox_size     = 50;
        $css_class        = 'input-lg';
        $html_table_width = 800;
        $space            = &vspace(5);
    }

    $prompt .= "<span class='$span'>";

    unless ($step_num) { $step_num = $Prep->_get_NextStep() }

=begin
    unless ($step_num) {
        if ( $Prep->{transferred_plates} ) {
            my @array1 = Cast_List( -list => $Prep->{plate_ids},          -to => 'array', -autoquote => 0 );
            my @array2 = Cast_List( -list => $Prep->{transferred_plates}, -to => 'array', -autoquote => 0 );
            my @array3 = &RGmath::minus( \@array1, \@array2 );

            if ( scalar(@array3) > 0 ) {
                my $plate_list = Cast_List( -list => \@array3, -to => 'string', -autoquote => 0 );
                $prompt .= '<P>';
                $prompt .= Link_To( $dbc->config('homelink'), "Remove plates that have been transferred and Save to a new plate set", "&cgi_application=alDente::Container_App&rm=Save Plate Set&Plate_ID=$plate_list" );
                $prompt .= '<P>';
                return $prompt;
            }
        }
    }
=cut

    unless ($step_num) {
        if ( $Prep->_get_NextStep( -check_completed => 1 ) eq 'Completed' ) {
            if ( $Prep->{tracksteps} && $Prep->track_completion() ) {

                #$Prep->Record( -step => "Completed $Prep->{protocol_name} Protocol", -change_location => 0 );
                $Prep->Record( -step => "Completed Protocol", -change_location => 0 );
            }
            else {
                ## do not track completed protocol if using Export Samples Protocol unless there are no tracked steps ##
                # Message("not tracking completion. $Prep->{tracksteps} && " . $Prep->track_completion());
            }
        }
        else {

            #      Message('no next step..');
            ## Some of the plates may not have completed the protocol
        }

        ## Warn the user for any plates that have not been scanned into a rack (in temporary)
        # $prompt .= $Prep->_plates_to_be_scanned(-default_rack=>'In Use');

        if ( $Prep->{tracksteps} ) {
            ##<CONSTRUCTION> Maybe move this to outside to make it a more stronger check
            my $not_completed = _get_not_completed_prompt($Prep);

            if ($not_completed) {
                $prompt .= $not_completed;
                return $prompt;
            }

            $dbc->message("$protocol Completed. (tracked $Prep->{tracksteps} steps)");
            if ( $Prep->{protocol_name} =~ /^(Receive Samples|Export Samples)$/ ) {
                ## special case for completion of export or import samples ##
                $prompt .= alDente::Rack_Views::generate_manifest_button( $dbc, -Prep => $Prep, -set => $Prep->{set_number}, -protocol => $Prep->{protocol_name} );
            }
        }
        return $prompt;
    }

    my $last_step_num = $step_num - 1;
    if ( exists $Prep->{Step}->{$last_step_num} ) {
        my ( $format, $xfer ) = &alDente::Protocol::new_plate( $Prep->{Step}->{$last_step_num}, -exclude => 'Setup' );
        if ( $format && $xfer ) {
            if ( $xfer->{focus} eq 'target' ) {

                ## add event record for plates created inside protocol ##
                $Prep->Record( -step => 'Moved to a new container', -simple => 1 );
            }
        }
    }

    my $step;
    if ( exists $Prep->{Step}->{$step_num} ) {
        $step = $Prep->{Step}->{$step_num};
    }
    else {
        $dbc->error("Error finding Step $step_num");
    }

    ## Generate Protocol Step Prompt ##

    if ( !$Prep->{tracksteps} ) { $prompt .= "No tracked steps in protocol" }
    elsif ( $Prep->{thisStep} ) {
        $prompt .= "<B>$step:</B> ($step_num / $Prep->{tracksteps})";
    }
    else { $prompt .= "Protocol complete" }

    my $Form = new LampLite::Form( -framework => 'bootstrap', -class => 'form-horizontal', -span => [ 2, 10 ], -style => 'background-color:#eee' );

    # alDente::Form::start_alDente_form( $dbc, 'prep' );

    $Prep->{Set} = '';

    my $hidden = hidden( -name => 'cgi_application', -value => 'alDente::Prep_App', -force => 1 );

    $hidden .= Safe_Freeze( -name => "Freeze Protocol", -value => $Prep, -format => 'hidden', -encode => 1, -exclude => 'dbc,connection,dbh,plate_field_list,plate_value_list,Format,field_list,value_list,fields,values' );

    my $record_step = $step;
    if ($append) {
        $hidden .= hidden( -name => 'Append Comments', -value => $append, -force => 1 );
        ## enable suffix to recorded step completed (eg 'Export Samples' + ' to Freezer Farm')
    }

    $hidden
        .= hidden( -name => "Last Page",      -force => 1, -value => "Continue Prep" )
        . hidden( -name  => 'Protocol',       -force => 1, -value => $Prep->{protocol_name} )
        . hidden( -name  => 'Prep Step Name', -force => 1, -value => $record_step )
        . hidden( -name  => 'Plate Set',      -force => 1, -value => $Prep->{set_number} )
        . hidden( -name  => 'Current Plates', -force => 1, -value => $Prep->{plate_ids} );

    if ($instructions) {
        $Prep->{dbc} = $dbc;    ## add dbc back after freeze
        $Form->append( -label => '', -input => $Prep->_print_instructions( -step => $Prep->{Step}->{$step_num} ) );
    }
    elsif ($confirm_fail) {
        $dbc->warning("Failing entire step requires confirmation");

        $Form->append( -label => '', -input => $q->checkbox( -name => 'Confirm Fail', -force => 1 ) );
        $Form->append( -label => '', -input => $q->submit( -name => 'rm', -value => 'Fail Prep, Remove Container(s) from Set', -force => 1, -class => "Action" ) );
        $Form->append( -label => '', -input => $q->submit( -name => 'rm', -value => 'Abort Fail and Continue', -class => "Std" ) );

        &main::leave();
    }

    my @inputs  = split ':', $Prep->{Input}->{ $Prep->{thisStep} };
    my @defs    = split ':', $Prep->{Default}->{ $Prep->{thisStep} };
    my @formats = split ':', $Prep->{Format}->{ $Prep->{thisStep} };

    #
    # Get input field info (& default values) from Protocol Table...
    #
    my $num_inputs = scalar(@inputs);
    my $num_defs   = scalar(@defs);

    if ( $num_inputs > $num_defs ) {
        foreach my $index ( $num_defs .. $num_inputs ) {
            $defs[$index] = "";
        }
    }

    #    Deprecate old way of generating prompts in favour of the cleaner form generation using LampLite::Form object ##
    #    my $Prot_Prompts = HTML_Table->new( -width => $html_table_width, -padding => '0' );
    #    $Prot_Prompts->Set_Class($css_class);

    #### $Prompt .= step messages
    if ( defined $Prep->{Message}->{$step_num} && $Prep->{Message}->{$step_num} && ( $Prep->{Message}->{$step_num} ne $step ) ) {
        $Form->append( -input => $dbc->message( $Prep->{Message}->{$step_num}, -hide => 1 ), -no_format => 1, -span => [12] );
    }

    my $text_help
        = "use comma-delimited list if necessary to apply different values for different containers; \n\nNote: Auto-expanding text area will convert linefeeds automatically to commas when reduced, and delimit values with linefeeds when expanded.\n\nDefault rows display in expanded box should match current number of containers being tracked";

    my $textsize = $textbox_size;    ## default size for textfields
    for my $index ( 1 .. $num_inputs ) {
        $_ = $inputs[ $index - 1 ];

        my $input_style;
        my $no_format = 1;

        my $size = $Prep->{Input}->{ $inputs[ $index - 1 ] }->{size} || $textsize;    ## get size if defined

        ## Special cases ##
        # Attribute prompts
        if ( $inputs[ $index - 1 ] =~ /_Attribute/ ) {
            my ( $attr_type, $attr_name ) = split( '=', $inputs[ $index - 1 ] );
            if ( defined $Prep->{Input}->{ $inputs[ $index - 1 ] }->{prompt} ) {
                $Form->append( -label => $attr_name, -input => $Prep->{Input}->{ $inputs[ $index - 1 ] }->{prompt} );    ## not set (but may be set up)  ## -label=>'',
            }
            else {
                my $tip;
                if ( $attr_type =~ /plate/i ) {
                    $tip = "Use comma separated values if assigning different values; otherwise enter a single value for all plates";
                }
                my $object;
                $attr_type =~ /^(\w+)_Attribute/;
                $object = $1;
                my $attribute_info = alDente::Attribute::get_attribute_info( -dbc => $dbc, -names => $attr_name, -class => $object );
                my @attr_ids       = keys %$attribute_info;
                my $attr_id        = $attr_ids[0];

                my $expandable = 0;
                if ( $Prep->{dynamic_text_elements} ) { $expandable = $count }
                my ( $prompt, $element )
                    = alDente::Attribute_Views::prompt_for_attribute( -dbc => $dbc, -attribute_id => $attr_id, -name => $attr_name, -preset => $defs[ $index - 1 ], -list => 1, -expandable => $expandable, -tooltip => $text_help, -help_button => 1 )
                    ;    #, -default=>$default, -preset => $preset, -mandatory=>$Mandatory{$attr_id}

                my $attribute_element = $element . hidden( -name => "$attr_type", -value => "$attr_name", -force => 1 );

                $Form->append( -label => "[$object] $prompt", -input => $attribute_element, -no_format => $no_format );    ## -label=>"[$object] $prompt",

                #                $Prot_Prompts->Set_Row( [ "[$object] $prompt", $attribute_element ] );
            }
        }

        elsif ( $inputs[ $index - 1 ] =~ /Solution_Quantity/ ) {
            ## (if Solution/Reagent associated, record quantity ###

            my ( $amount, $quantity_units ) = RGTools::Conversion::get_amount_units( $defs[ $index - 1 ] );

            my $quantity_fields;
            if ( $Prep->{plate_type} =~ /Library_Plate/i ) {
                $quantity_fields = " x " . textfield( -name => 'QuantityX', -force => 1, -size => 3, -class => $css_class, -default => $Prep->{plate_format_wells} ) . " wells " . " x <B>$count</B> Plates";
            }
            elsif ( $Prep->{plate_type} =~ /Tube/i ) {
                $quantity_fields = " x <B>$count</B> Tubes";
            }

            $Prep->{solution_units} = $quantity_units;

            my $get_sol_qty = SDB::HTML::dynamic_text_element(
                -name         => 'Solution_Quantity',
                -force        => 1,
                -class        => $css_class,
                -default      => $amount,
                -cols         => 10,
                -rows         => 1,
                -max_cols     => 10,
                -max_rows     => $count,
                -split_commas => 1,
                -auto_expand  => $count,
                -multiplier   => 'Split_X',
                -static       => !$Prep->{dynamic_text_elements},
                -suffix       => " $quantity_units " . $quantity_fields . hidden( -name => 'Quantity_Units', -value => $quantity_units, -force => 1 ),
                -placeholder  => "-- Qty --",
            );
            $input_style = 'padding:0px';

            $Form->append( -label => 'Use:', -input => $get_sol_qty, -no_format => $no_format, -input_style => $input_style );    ## -label=>'Use:',

            #            $Prot_Prompts->Set_Row(
            #                [   "Use:",
            #                    $get_sol_qty
            #                ]
            #            );
        }
        elsif ( $inputs[ $index - 1 ] =~ /Track_Transfer/ ) {
            ## if Transfering Quantity  record quantity ###
            my @plates_unit_list = &get_enum_list( $dbc, 'Plate', 'Current_Volume_Units' );

            my ( $amount, $quantity_units ) = RGTools::Conversion::get_amount_units( $defs[ $index - 1 ] );

            unless ( grep( /^$quantity_units$/, @plates_unit_list ) ) {
                $quantity_units = 'ml';    #Default units to mL.
            }

            #$prompt .= "Transfer: <Nobr>",
            #textfield(-name=>'Transfer_Quantity',-size=>4,-force=>1,-default=>$amount),
            #popup_menu(-name=>'Transfer_Quantity_Units',-values=>\@plates_unit_list,-default=>$quantity_units,-force=>1);

            my $get_transfer = SDB::HTML::dynamic_text_element(
                -name         => 'Transfer_Quantity',
                -cols         => $size,
                -rows         => 1,
                -force        => 1,
                -class        => $css_class,
                -default      => $amount,
                -max_cols     => 60,
                -max_rows     => $count,
                -split_commas => 1,
                -auto_expand  => $count,
                -multiplier   => 'Split_X',
                -static       => !$Prep->{dynamic_text_elements},
                -suffix       => popup_menu( -name => 'Transfer_Quantity_Units', -values => \@plates_unit_list, -default => $quantity_units, -force => 1 )
            );

            $Form->append( -input => $get_transfer );    ## -label=>'Transfer:',

            #            $Prot_Prompts->Set_Row(
            #                [   "Transfer:",
            #                    $get_transfer
            #                ]
            #            );
        }
        elsif ( $inputs[ $index - 1 ] =~ /Split/ ) {
            my $split_prompt;
            $split_prompt .= hidden( -name => 'Sources', -value => $count, -force => 1 );

            my $xfer          = &alDente::Protocol::new_plate($step);
            my $target_format = $xfer->{'new_format'} || $Prep->{plate_format};
            my $split         = $defs[ $index - 1 ];
            $split_prompt .= textfield( -name => 'Split_X', -id => 'Split_X', -default => $split, -size => 4, -class => $css_class, -force => 1 ) . "$target_format(s)<BR>";

            $Form->append( -label => 'Split X:', -input => $split_prompt );    ## -label=>'Split each target into:',

            #            $Prot_Prompts->Set_Row( [ "Split each target into: ", $split_prompt ] );

            ### <CONSTRUCTION> Allow split here (allow count above to be multiplied by N) ####
        }
        elsif ( $inputs[ $index - 1 ] =~ /Label/ ) {
            my $label = $defs[ $index - 1 ];

            my $get_target_label = Show_Tool_Tip(
                SDB::HTML::dynamic_text_element(
                    -name         => "Target Plate Label",
                    -cols         => $size,
                    -rows         => 1,
                    -max_cols     => 60,
                    -max_rows     => $count,
                    -split_commas => 1,
                    -values       => '',
                    -default      => $label,
                    -class        => $css_class,
                    -force        => 1,
                    -auto_expand  => $count,
                    -multiplier   => 'Split_X',
                    -static       => !$Prep->{dynamic_text_elements},
                    -placeholder  => '-- Target Label --',
                ),
                'Specify label for target container'
            );

            $Form->append( -label => 'Target Label:', -input => $get_target_label );    ## -label=>'Target Label:',

            #            $Prot_Prompts->Set_Row(
            #                [   "Target Label: ",
            #                    $get_target_label
            #                ]
            #            );
        }
        elsif ( defined $Prep->{Input}->{ $inputs[ $index - 1 ] } ) {
            ## Normal Case ##

            my $suffix;
            if ( $inputs[$index] eq 'Mandatory_Rack' ) {
                ## add validator for mandatory field(s) ##
                $suffix .= set_validator( -name => 'FK_Rack__ID', -mandatory => 1 );    ## only works when used with desktop ##
            }

            if ( $inputs[$index] =~ /Mandatory_(\w+)Attribute_(\w+)/ ) {
                ## add validator for mandatory attribute(s) ##
                my $attr_name = $2;
                $suffix .= set_validator( -name => $attr_name, -mandatory => 1 );       ## only works for the first attribute ##
            }

            ## suffix (if defined)
            if ( defined $Prep->{Input}->{ $inputs[ $index - 1 ] }->{suffix} ) {
                $suffix .= $Prep->{Input}->{ $inputs[ $index - 1 ] }->{suffix};
            }

            ## input field (textfield by default)
            my $label = $Prep->{Input}->{ $inputs[ $index - 1 ] }->{prefix} if ( defined $Prep->{Input}->{ $inputs[ $index - 1 ] }->{prefix} );

            my $get_input;
            if ( defined $Prep->{Input}->{ $inputs[ $index - 1 ] }->{prompt} ) {
                ## not quite sure why this is here.. ?...
                $get_input .= $Prep->{Input}->{ $inputs[ $index - 1 ] }->{prompt};    ## not set (but may be set up)
                $get_input .= $suffix;
            }
            else {
                my $element_name = $inputs[ $index - 1 ];

                my $dynamic = $Prep->{dynamic_text_elements};
                if ( $inputs[ $index - 1 ] =~ /(comments|description)/i ) {
                    ## larger textfields with no dynamic scaling (due to possibility of commas in text) ##
                    if ( $Settings{BIG_TEXTFIELD_SIZE} > $size ) { $size = $Settings{BIG_TEXTFIELD_SIZE} }
                    $dynamic = 0;
                }

                if ($dynamic) {
                    $get_input .= SDB::HTML::dynamic_text_element(
                        -name         => $inputs[ $index - 1 ],
                        -cols         => 30,
                        -rows         => 1,
                        -force        => 1,
                        -class        => $css_class,
                        -default      => $defs[ $index - 1 ],
                        -tooltip      => $text_help,
                        -help_button  => 1,
                        -max_cols     => 40,
                        -max_rows     => $count,
                        -split_commas => 1,
                        -auto_expand  => $count,
                        -static       => !$dynamic,
                        -multiplier   => 'Split_X',
                        -suffix       => $suffix,
                        -placeholder  => "-- $label --",
                    );

                    $input_style = 'padding:0px';
                }
                else {
                    ## dynamic text elements turned off ##
                    $get_input .= Show_Tool_Tip( textfield( -name => $inputs[ $index - 1 ], -size => $size, -force => 1, -class => $css_class, -default => $defs[ $index - 1 ], -placeholder => "-- $label --" ), $text_help, -help_button => 1 );
                    $get_input .= $suffix;
                    $input_style = 'padding:0px';
                }

            }

            if ($label) {
                $Form->append( -label => $label, -input => $get_input, -no_format => $no_format, -input_style => $input_style );    # -label => $label,

                #                $Prot_Prompts->Set_Row( [ $prompt, $suffix ] );
            }
        }
        elsif (/^\s?$/) { }
        else            { $dbc->warning("unrecognized input ($_)"); }
    }

    # If doing pooling, then ask for volumes for each source container
    if ( $step =~ /Pool to/ ) {
        ## Check the containers to see if they are tubes or plate

        my $table = HTML_Table->new();
        $table->Set_Class($css_class);
        if ( $Prep->{plate_type} =~ /Plate/i ) {
            ## Pool plates
            $table->Set_Row( [ "Pool to: ", textfield( -name => 'Pool_X', -value => '', -class => $css_class, -size => 5 ), "plates" ] );
            $hidden .= hidden( -name => 'Pool_Type', -value => 'Pool_Plate' );
        }
        else {
            ## Pool tubes
            my @pool_units = &get_enum_list( $dbc, 'PoolSample', 'Sample_Quantity_Units' );

            $table->Set_Headers( [ "Pool from", 'Quantity', 'Units' ] );
            foreach my $plate ( split /,/, $Prep->{plate_ids} ) {

                # Get remaining quantities
                my $tube = alDente::Tube->new( -dbc => $dbc, -plate_id => $plate );
                my ( $remaining_quantity, $remaining_quantity_used ) = $tube->get_remaining_quantity();
                $table->Set_Row(
                    [   "$Prefix{Plate}$plate ($remaining_quantity $remaining_quantity_used remaining)",
                        textfield( -name  => "Pool_Quantity:$plate", -size   => 4, -class => $css_class, -force => 1 ),
                        popup_menu( -name => "Pool_Units:$plate",    -values => \@pool_units )
                    ]
                );
            }
        }
        $Form->append( -label => '', -input => $table->Printout(0) );    ## -label=>'',
    }

    # if doing a transfer/aliquot, show a choice for all Pipelines and default the current pipeline
    if ( &alDente::Protocol::new_plate( $step, -exclude => [ 'Setup', 'Pre-Print' ] ) ) {
        my @current_pipelines = $dbc->Table_find( "Plate", "FK_Pipeline__ID", "WHERE Plate_ID in ($current_plates)", -distinct => 1 );
        my $grps              = $dbc->get_local('group_list');
        my @next_pipelines    = alDente::Protocol::next_pipeline_options( -dbc => $dbc, -pipeline => \@current_pipelines, -protocol => $protocol_id, -grp => $grps );
        my $next_pipelines    = join ',', @next_pipelines;

        if (@next_pipelines) {
            my $default;
            if ( int(@next_pipelines) == 1 ) { $default = $next_pipelines[0] }

            my $get_pipeline = alDente::Tools::search_list(
                -dbc         => $dbc,
                -name        => "FK_Pipeline__ID",
                -field       => 'FK_Pipeline__ID',
                -default     => $default,
                -condition   => "Pipeline_ID IN ($next_pipelines)",
                -tip         => "Choose pipeline to which target container will be assigned",
                -placeholder => '-- Set Pipeline --',
            );

            $Form->append( -label => 'Set Pipeline:', -input => $get_pipeline );    ## -label=>'Set Pipeline:',

            #            $Prot_Prompts->Set_Row(
            #                [   "Pipeline: ",
            #                    $get_pipeline
            #                ]
            #            );
        }
    }

    # If doing decant, then ask for Decant type ( Decant down to / Decant out )
    if ( $step =~ /Decant/ ) {
        my $table = HTML_Table->new();
        $table->Set_Class($css_class);
        $table->Set_Row( [ radio_group( -name => "Decant_Type", -values => [ 'Decant_Down_To', 'Decant_Out' ], -labels => { 'Decant_Down_To' => 'Decant Down To', 'Decant_Out' => 'Decant Out' }, -default => 'Decant_Down_To' ) ] );
        $Form->append( -label => '', -input => $table->Printout(0) );    ## -label=>'',
    }

    if ( $step =~ /Start QC/ ) {
        my @qc_types = $dbc->Table_find( 'QC_Type', 'QC_Type_Name', "WHERE 1" );
        my $qc_prompt = popup_menu( -name => 'QC_Type', -values => \@qc_types, -force => 1 );
        $Form->append( -label => 'QC Type: ', -input => $qc_prompt );
    }

    my $protocol_step_id = $Prep->{StepID}->{$step_num};

    #$prompt .= $protocol_step_id;
    # Check if the step name exists in the Prep Detail Options lookup table
    my ($prep_step_id) = $dbc->Table_find( 'Prep_Attribute_Option', 'FK_Protocol_Step__ID', "WHERE FK_ProtocoL_Step__ID=$protocol_step_id" );

    if ( defined $prep_step_id ) {

        # Get the Attribute Name, Type, Format
        my %prep_detail_options = Table_retrieve( $dbc, 'Prep_Attribute_Option,Attribute', [ 'Attribute_Name', 'Attribute_Type', 'Attribute_Format', 'Option_Description' ], "WHERE FK_ProtocoL_Step__ID= $prep_step_id and Attribute_ID=FK_Attribute__ID" );

        my $index = 0;
        while ( defined $prep_detail_options{Attribute_Name}[$index] ) {
            my $attribute_name     = $prep_detail_options{Attribute_Name}[$index];
            my $attribute_format   = $prep_detail_options{Attribute_Format}[$index];
            my $option_description = $prep_detail_options{Option_Description}[$index];
            ## Check the attribute type
            my $attribute_type = $prep_detail_options{Attribute_Type}[$index];
            my $attribute_field;
            if ( $attribute_type =~ /text/i ) {
                if ( $Prep->{dynamic_text_elements} ) {
                    $attribute_field = SDB::HTML::dynamic_text_element(
                        -name         => $attribute_name,
                        -size         => 20,
                        -force        => 1,
                        -class        => $css_class,
                        -default      => "",
                        -tooltip      => "$option_description\n\n$text_help",
                        -help_button  => 1,
                        -max_rows     => 10,
                        -max_cols     => 50,
                        -split_commas => 1,
                        -auto_expand  => $count,
                        -multiplier   => 'Split_X',
                        -static       => !$Prep->{dynamic_text_elements},
                    );
                }
                else {
                    $attribute_field = Show_Tool_Tip( textfield( -name => $attribute_name, -size => 20, -force => 1, -class => $css_class, -default => "" ), "$option_description\n\n$text_help", -help_button => 1 );
                }
            }
            elsif ( $attribute_type =~ /enum/ ) {
                my $enum_def = $attribute_type;
                $enum_def =~ s/enum\((.*)\)/$1/;

                my @enum_values = ();
                push( @enum_values, split ',', $enum_def );
                foreach (@enum_values) {
                    unless ( ( $_ eq "''" ) || ( $_ eq "\"\"" ) ) {
                        s/\'//g;
                        s/\"//g;
                    }
                    $attribute_field = Show_Tool_Tip( $q->popup_menu( -name => $attribute_name, -values => [ "", @enum_values ], -default => "" ), $option_description );

                }
            }

            # Display the attribute field and an input
            $Form->append( -label => '', -input => "$attribute_name: " . $attribute_field );    ## -label=>'',
            $index++;
        }
    }

    $Form->append( -label => '', -input => Show_Tool_Tip( $q->submit( -name => 'rm', -force => 1, -value => 'Completed Step', -class => "Action", -onClick => 'return validateForm(this.form)' ), "completed <B>$step</B>" ) );

    $Prep->{dbc} = $dbc;

    my $footer = _print_Prep_footer( $Prep, -step => $step );
    $Form->append( -label => '', -input => $footer );                                           ## -label=>'',

    my $start_tag = alDente::Form::start_alDente_form( $dbc, 'prep', -class => 'form-horizontal' );
    $prompt .= $Form->generate( -open => 1, -close => 1, -include => $hidden, -tag => $start_tag );

    $prompt .= "</span>";

    return $prompt;
}

#######################################################
#
#Generates a readable input for the protocol step columns in batch edit protocol
#
#########################
sub Input_readable_name {
#########################
    my %args = filter_input( \@_ );
    my $fld  = $args{-string};
    if ( $fld eq 'Track_Transfer' ) {
        return 'Transfer_Quantity';
    }
    if ( $fld =~ /(Pool)/ ) {
        return 'Pool To';
    }
    if ( $fld =~ /(Decant)/ ) {
        return $1;
    }
    if ( $fld =~ /^FK_([a-zA-Z]+)/ ) {
        my $type = $1;
        return $type;
    }
    elsif ( $fld =~ /^(\w+)\_Attribute\=(\w+)/ ) {
        my $type = $1;
        my $att  = $2;
        return $att;
    }
    else {
        return $fld;
    }
}

########################################################
# Page generated when stepping users through protocols
#
#
#
#########################
sub Protocol_step_page {
#########################
    my $Prep              = shift;
    my %args              = filter_input( \@_, -args => 'completed,error_step' );
    my $completed         = $args{-completed};
    my $error_stepnum_ref = $args{-error_step};                                     # (ArrayRef) Step numbers of rows that have errors (from $self->{TrackStepNum})

    my $dbc = $Prep->{dbc};
    my %Completed;
    if ($completed) { %Completed = %$completed }

    my @error_stepnums = ();
    @error_stepnums = @{$error_stepnum_ref} if ($error_stepnum_ref);

    my $Protocol = HTML_Table->new( -title => "$Prep->{protocol_name}", -border => 1, -class => 'small' );

    #    my @input_types = ( 'Equipment', 'Transfer_Quantity', 'Transfer_Quantity_Units', 'FK_Solution__ID', 'Solution_Quantity', 'Conditions', 'Time', 'Comments' );

    my @input_types;
    foreach my $step_number ( 1 .. $Prep->{tracksteps} ) {    ### set up rows for uncompleted steps...
        my $step = $Prep->{Step}->{$step_number};
        my @input = split ':', $Prep->{Input}->{$step_number};
        ## This for loop sets up the columns that will be printed out in the batch edit protocol box
        if ( $step =~ /(Pool to)/ ) {
            push @input_types, 'Pool_X';
        }
        if ( $step =~ /Decant/ ) {
            push @input_types, 'Decant_Type';
        }
        foreach my $input_num ( 0 .. $#input ) {
            my $fld = $input[$input_num];
            unless ( $fld =~ /^Mandatory_([a-zA-Z]+)/ ) {     #Mandatory flag is handled below
                push @input_types, $fld;
            }
        }
    }

    my $input_types = RGmath::distinct_list( \@input_types );
    @input_types = @$input_types if $input_types;
    my @cleaned_headers;
    my @prep_attr;
    my @pla_attr;

    foreach my $input_num ( 0 .. $#input_types ) {
        my $fld = $input_types[$input_num];
        my $field_name = Input_readable_name( -string => $fld );
        if ($field_name) { push @cleaned_headers, $field_name; }
        if ( $fld =~ /_Attribute/ ) {
            my @attr = split '=', $fld;
            if ( $attr[0] =~ /Plate_/ ) {
                push @pla_attr, $attr[1];
            }
            elsif ( $attr[0] =~ /Prep_/ ) {
                push @prep_attr, $attr[1];
            }
        }
    }

    # set SELECT ALL checkbox
    my $select_all = checkbox( -name => "SELECT_ALL", -label => "", -onClick => "ToggleCheckBoxes(document.Update_Protocol,'SELECT_ALL');" );
    $Protocol->Set_Headers( [ "$select_all", "Select", 'Step', 'Timestamp', @cleaned_headers, 'Set Pipeline' ] );

    # get the latest date the prep has been modified. If it is earlier than the Protocol_Step modification date
    # just print out all the information - it is assumed that the Prep has been finished already
    # this is a workaround for instances when the Protocol has changed, and so the algorithm cannot
    # determine if a step has been done or not

    my ($lastmodified_prep)     = $dbc->Table_find_array( 'Prep,Plate_Prep', ['Left(max(Prep_DateTime),10)'], "where Prep_ID=FK_Prep__ID AND FK_Lab_Protocol__ID=$Prep->{protocol_id} AND FK_Plate__ID in ($Prep->{plate_ids})" );
    my ($lastmodified_protocol) = $dbc->Table_find_array( 'Protocol_Step',   ['max(Protocol_Step_Changed)'],  "where FK_Lab_Protocol__ID=$Prep->{protocol_id}" );

    if ( $lastmodified_prep && ( $lastmodified_prep lt $lastmodified_protocol ) ) {
        $dbc->warning("Prep date $lastmodified_prep < Protocol change date $lastmodified_protocol");
        $dbc->warning("OLD PREPARATION, CANNOT UPDATE");

        # Message("Prep date $lastmodified_prep < Protocol change date $lastmodified_protocol");
        # Message("OLD PREPARATION, CANNOT UPDATE");

        my @keys = keys %{$Prep};
        foreach my $stepname (@keys) {
            $Protocol->Set_Row( $Completed{$stepname} );
        }
        return $Protocol->Printout(0);
    }

    ## get count of plates ##
    my $count += () = $Prep->{plate_ids} =~ /,/g;
    $count++;

    my $validation;
    my $rowcount   = 1;
    my @table_rows = ();
    my @pool_check;
    my @pipeline_check;
    my $page;

    foreach my $step_number ( 1 .. $Prep->{tracksteps} ) {    ### set up rows for uncompleted steps...
        my $step      = $Prep->{Step}->{$step_number};
        my @input     = split ':', $Prep->{Input}->{$step_number};     ###Gets the inputs needed per step exactly what I need
        my @defaults  = split ':', $Prep->{Default}->{$step_number};
        my $error_row = 0;

        if ( grep { $step_number == $_ } @error_stepnums ) {
            $error_row = 1;
        }

        my $timestamp = &date_time();
        my $done      = 0;
        if ( defined $Completed{$step} ) {
            $Protocol->Set_Row( $Completed{$step} );
        }
        else {
            my @options = (
                checkbox( -name  => "SELECTED",                -label => "",                        -checked => $done,      -force => 1, -value => "$rowcount" ),
                textfield( -name => "Prep_Name-$rowcount",     -size  => $Settings{TEXTFIELD_SIZE}, -default => $step,      -force => 1, -class => 'wide-txt' ),
                textfield( -name => "Prep_DateTime-$rowcount", -size  => $Settings{DATEFIELD_SIZE}, -default => $timestamp, -force => 1 ),
            );
            foreach my $input_field (@input_types) {
                if ( grep /^$input_field$/, @input ) {
                    my $index;
                    foreach my $input_num ( 0 .. $#input ) {
                        if ( $input[$input_num] =~ /$input_field/i ) {
                            my $link;
                            my ( $prompt, $element );
                            my $fld = $input[$input_num];
                            if ( $fld =~ /^FK_([a-zA-Z]+)/ ) {
                                ## check to see if primary reference class is mandatory (eg FK_Equipment, FK_Solution) ##
                                my $type = $1;

                                if ( grep /Mandatory_${type}/, @input ) {
                                    $validation .= set_validator( -name => "$fld-$rowcount", -mandatory => 1, -case_name => "SELECTED", -case_value => $rowcount );
                                }
                            }
                            elsif ( $fld =~ /^(\w+)\_Attribute\=(\w+)/ ) {
                                ## check to see if attribute is mandatory (eg Plate_Attribute) ## (slightly weird Input formatting) - may change to make cleaner ##
                                my $type      = $1;
                                my $att       = $2;
                                my $mandatory = 0;
                                if ( grep /Mandatory\_${type}Attribute\_$att/, @input ) {
                                    $mandatory = 1;
                                    $validation .= set_validator( -name => "$fld-$rowcount", -mandatory => 1, -case_name => "SELECTED", -case_value => $rowcount );
                                }
#################### EDIT HERE
                                my ( $attr_type, $attr_name ) = split( '=', $fld );
                                my $attribute_info = alDente::Attribute::get_attribute_info( -dbc => $dbc, -names => $attr_name, -class => $type );
                                my @attr_ids       = keys %$attribute_info;
                                my $attr_id        = $attr_ids[0];
                                ( $prompt, $element ) = alDente::Attribute_Views::prompt_for_attribute( -dbc => $dbc, -name => $attr_name, -attribute_id => $attr_id );    #, -mandatory => $mandatory );
                            }
                            ## Skip mandatory checks
                            if ( $input[$input_num] =~ /mandatory/i ) {next}

                            my $element_name = "$input[$input_num]-$rowcount";
                            my $dynamic      = $Prep->{dynamic_text_elements};
                            my $size         = $Prep->{Input}->{ $input[$input_num] }->{size} || $Settings{SCANFIELD_SIZE};                                                ## get size if defined

                            if ( $input[$input_num] =~ /(comments|description)/i ) {
                                $dynamic = 0;
                                if ( $Settings{BIG_TEXTFIELD_SIZE} > $size ) { $size = $Settings{BIG_TEXTFIELD_SIZE} }
                            }
                            if ( $fld =~ /^(\w+)\_Attribute\=(\w+)/ ) {
                                $link = ( $prompt, $element );
                            }
                            elsif ( $fld =~ /Split/ ) {
                                my $split_prompt;
                                $split_prompt .= hidden( -name => "Sources-$rowcount", -value => $count, -force => 1 );
                                my $xfer          = &alDente::Protocol::new_plate($step);
                                my $target_format = $xfer->{'new_format'} || $Prep->{plate_format};
                                my $split         = $defaults[$fld];
                                $split_prompt .= textfield( -name => "Split_X-$rowcount", -id => 'Split_X', -default => $split, -size => 4, -class => 'narrow-txt', -force => 1 ) . "$target_format(s)<BR>";
                                $link = $split_prompt;
                            }
                            else {
                                my @defs = split ':', $Prep->{Default}->{$step_number};
                                my ( $amount, $quantity_units ) = RGTools::Conversion::get_amount_units( $defs[$index] );
                                my @plates_unit_list = &get_enum_list( $dbc, 'Plate', 'Current_Volume_Units' );

                                my $suffix;
                                my $suffix_name;
                                my $css_class;
                                my $default = $defaults[$input_num];

                                if ( $fld =~ /Solution_Quantity/ || $fld =~ /Track_Transfer/ || $fld =~ /Transfer_Quantity/ ) {
                                    $default   = '';
                                    $css_class = 'narrow-txt';

                                    if ( $fld =~ /Solution_Quantity/ ) {
                                        $Prep->{solution_units} = $quantity_units;
                                        $suffix_name = "Quantity_Units-$rowcount";
                                        my $quantity_fields;
                                        if ( $Prep->{plate_type} =~ /Library_Plate/i ) {
                                            $quantity_fields
                                                = " x " . textfield( -name => "Quantity_Fields-$rowcount", -force => 1, -size => 3, -class => $css_class, -default => $Prep->{plate_format_wells} ) . " wells " . " x <B>$count</B> Plates " . &vspace(2);
                                        }
                                        elsif ( $Prep->{plate_type} =~ /Tube/i ) {
                                            $quantity_fields = " x <B>$count</B> Tubes " . vspace(2);
                                        }

                                        $Prep->{solution_units} = $quantity_units;

                                        $suffix = " $quantity_units " . $quantity_fields . hidden( -name => "$suffix_name", -value => $quantity_units, -force => 1 );
                                    }
                                    elsif ( $fld =~ /Track_Transfer/ || $fld =~ /Transfer_Quantity/ ) {
                                        $suffix_name = "Transfer_Quantity_Units-$rowcount";
                                        $suffix      = popup_menu(
                                            -name    => "$suffix_name",
                                            -values  => \@plates_unit_list,
                                            -default => $quantity_units,
                                            -force   => 1,
                                            -class   => 'auto-width'
                                        );
                                    }

                                }

                                $link = SDB::HTML::dynamic_text_element(
                                    -name         => "$element_name",
                                    -class        => $css_class,
                                    -rows         => 1,
                                    -cols         => $size,
                                    -default      => $default,
                                    -force        => 1,
                                    -max_rows     => $count,
                                    -max_cols     => 60,
                                    -split_commas => 1,
                                    -auto_expand  => $count,
                                    -multiplier   => 'Split_X',
                                    -static       => !$dynamic,
                                    -suffix       => $suffix,
                                );
                            }
                            push( @options, $link );
                            last;
                        }
                        $index++;
                    }
                }
                elsif ( $step =~ /Decant/ && $input_field =~ /Decant/ ) {
                    my $table = HTML_Table->new();
                    $table->Set_Class('normal-txt');
                    $table->Set_Row( [ radio_group( -name => "Decant_Type-$rowcount", -values => [ 'Decant_Down_To', 'Decant_Out' ], -labels => { 'Decant_Down_To' => 'Decant Down To', 'Decant_Out' => 'Decant Out' }, -default => 'Decant_Down_To' ) ] );
                    push @options, $table->Printout(0);
                }
                elsif ( $step =~ /Pool to/ && $input_field =~ /Pool/ ) {
                    my $table = HTML_Table->new();
                    $table->Set_Class('narrow-txt');
                    if ( $Prep->{plate_type} =~ /Plate/i ) {
                        $table->Set_Row( [ "Pool to: ", textfield( -name => "Pool_X-$rowcount", -value => '', -class => 'normal-txt', -size => 5 ), "plates" ] );
                        $page .= hidden( -name => "Pool_Type-$rowcount", -value => 'Pool_Plate' );
                        push @pool_check, "Pool_X-$rowcount";
                        push @pool_check, "Pool_Type-$rowcount";
                    }
                    else {
                        my @pool_units = &get_enum_list( $dbc, 'PoolSample', 'Sample_Quantity_Units' );
                        $table->Set_Headers( [ "Pool from", 'Quantity', 'Units' ] );
                        foreach my $plate ( split /,/, $Prep->{plate_ids} ) {
                            my $tube = alDente::Tube->new( -dbc => $dbc, -plate_id => $plate );
                            my ( $remaining_quantity, $remaining_quantity_used ) = $tube->get_remaining_quantity();
                            $table->Set_Row(
                                [   "$Prefix{Plate}$plate ($remaining_quantity $remaining_quantity_used remaining)",
                                    textfield( -name  => "Pool_Quantity:$plate", -size   => 4, -class => 'narrow-txt', -force => 1 ),
                                    popup_menu( -name => "Pool_Units:$plate",    -values => \@pool_units )
                                ]
                            );
                            push @pool_check, "Pool_Quantity:$plate";
                            push @pool_check, "Pool_Units:$plate";
                        }
                    }
                    push @options, $table->Printout(0);
                }
                else {
                    push( @options, '-' );
                }

            }
            ## add pipeline dropdown for transfer steps ##
            if ( alDente::Protocol::new_plate( $step, -exclude => [ 'Setup', 'Pre-Print' ] ) ) {
                my $current_plates ||= $Prep->{plate_ids};
                my $protocol_id       = $Prep->{protocol_id};
                my $grps              = $dbc->get_local('group_list');
                my @current_pipelines = $dbc->Table_find( "Plate", "FK_Pipeline__ID", "WHERE Plate_ID in ($current_plates)", -distinct => 1 );
                my @next_pipelines    = alDente::Protocol::next_pipeline_options( -dbc => $dbc, -pipeline => \@current_pipelines, -protocol => $protocol_id, -grp => $grps );
                my $next_pipelines    = join ',', @next_pipelines;

                if (@next_pipelines) {
                    my $default;
                    if ( int(@next_pipelines) == 1 ) { $default = $next_pipelines[0] }

                    push @pipeline_check, "FK_Pipeline__ID-$rowcount";
                    push @options,
                        &alDente::Tools::search_list(
                        -dbc            => $dbc,
                        -name           => "FK_Pipeline__ID",
                        -field          => 'FK_Pipeline__ID',
                        -default        => $default,
                        -condition      => "Pipeline_ID IN ($next_pipelines)",
                        -tip            => "Choose pipeline to which target container will be assigned",
                        -filter_by_dept => 1
                        );
                }
            }
            else {
                push @options, '-';
            }
            if ( $error_row == 1 ) {
                $Protocol->Set_Row( [ "", @options ], 'lightredbw' );
            }
            else {
                $Protocol->Set_Row( [ "", @options ] );
            }
            $rowcount++;
        }
    }

    #    $page .= '<p ></p>' . Link_To( $dbc->{homelink}, "Return to home page for current plate(s)", "&HomePage=Plate&ID=$Prep->{plate_ids}" ) . '<p ></p>';

    # pass the row count as a parameter
    $page .= hidden( -name => "NumInputRows", -value => "$rowcount" );
    if (@pipeline_check) {
        push @input_types, @pipeline_check;
    }
    if (@pool_check) {
        push @input_types, "Pool_Type";
        push @input_types, @pool_check;
    }
    my $input = join ',', @input_types;
    $page .= hidden( -name => "InputFields",     -value => $input,      -force => 1 );
    $page .= hidden( -name => "Plate_Attribute", -value => \@pla_attr,  -force => 1 );
    $page .= hidden( -name => "Prep_Attribute",  -value => \@prep_attr, -force => 1 );

    $page
        .= &vspace(3)
        . $q->submit( -name => 'rm', -value => 'Batch Update', -class => 'Action', -onClick => "return validateForm(this.form);" )
        . $validation
        . &vspace(3)
        . "Completed Protocol ?: "
        . radio_group( -name => 'Completed Protocol', -value => [ 'yes', 'no' ], -default => '', -force => 1, )
        . vspace(3)
        . set_validator( -name => 'SELECTED',           -mandatory => 1, -prompt => 'You must select at least one step to mark as completed' )
        . set_validator( -name => 'Completed Protocol', -mandatory => 1, -prompt => 'You must indicate if the protocol has been completed' );
    $page .= hidden( -name => 'cgi_application', -value => 'alDente::Prep_App', -force => 1 );
    ### also show those completed that are not in current list of steps...

    $page .= $Protocol->Printout(0);
    return $page;
}

########################
sub _print_Prep_footer {
########################
    #
    # print out standard buttons at the bottom of the Protocol following steps.
    #
    my $Prep = shift;
    my %args = @_;      ## optionally allow arguments to specify (or hide) options...

    my $dbc       = $Prep->{dbc};
    my $step      = $args{-step};
    my $plate_ids = $args{-plate_ids} || $Prep->{plate_ids};

    #$scanner_mode = 0;
    my $css_class;

    my $footer = "\n<hr>\n";

    if ( !$scanner_mode ) { $css_class = 'form-control'; }

    my $skip_prep_step = $q->submit( -name => 'rm', -value => 'Skip Step', -force => 1, -class => "Action" );

    my $back_step;
    if ( $Prep->{thisStep} == 1 ) {
        ## no back step in this case... ##
    }
    else {
        my $laststep = $Prep->{thisStep} - 1;
        if ( $Prep->{Repeatable}{$laststep} ) {
            $back_step = set_validator( -confirmPrompt => "Warning: are you sure you want to repeat the last step (will re-generate new barcodes in some cases)" )
                . $q->submit( -name => 'rm', -value => "Repeat Last Step", -class => "Action", onClick => "return validateForm(this.form);", -force => 1 );
        }
        elsif ( alDente::Protocol::new_plate($Prep->{Step}{$laststep}) ) {
            $back_step = '<B>Cannot go back</B><BR>if necessary, rescan parent plates to repeat transfer step';
        }
        elsif ( $Prep->{Step}{$laststep} =~ /(Throw Away)/) {
            $back_step = "<B>Cannot undo throw away from here</B>";
        }
        else {
            $back_step = $q->submit( -name => 'rm', -value => "Go Back One Step", -class => "Action", -force => 1 );
        }
    }

    my $annotate_button = $q->submit( -name => 'rm', -value => 'Prep Notes', -class => "Action" );
    my $annotate_note = $q->textfield( -name => 'Prep Plate Note', -size => 28, -class => "$css_class", -placeholder => '-- Note --' );
    my $annotate_prep_plate = $annotate_button . ' ' . $annotate_note;

    my $fail_button = $q->submit( -name => 'rm', -value => 'Fail Prep, Remove Container(s) from Set', -force => 1, -class => "Action" );
    my $fail_list = Show_Tool_Tip(
        $q->textfield( -name => 'Plates To Fail Prep', -force => 1, -default => "", -class => "$css_class", -placeholder => '-- Scan Plates to Fail --' ),
        "These plates will be removed from the existing set (leave blank to include all plates), allowing you to continue with the other plates.<BR>This DOES NOT mark the plate as failed."
    );
    my $fail_prep_remove_from_set = $fail_button . ' ' . $fail_list;

    my $prep_instruction;
    if ( $Prep->{Protocol_Step_Instructions}{ $Prep->{thisStep} } ) {
        my $instructions = $Prep->{Protocol_Step_Instructions}{ $Prep->{thisStep} };
        $instructions =~ s/\n/\\n/g;
        $prep_instruction = $q->submit( -name => 'rm', -value => 'Get Instructions', -onclick => "alert('$instructions'); return false;", -border => 0, -class => "Search" );
    }
    my @valid_labels = $dbc->Table_find( "Barcode_Label", "Label_Descriptive_Name", "WHERE Barcode_Label_Type like 'Plate' AND Barcode_Label_Status='Active'" );

    my $reprint_barcode = $q->submit( -name => 'rm', -value => 'Re-Print Plate Barcodes', -class => "Std", -align => "right" ) . &hspace(5);
    my $reprint_barcode_choice;

    if ( int(@valid_labels) > 0 ) {
        unshift( @valid_labels, '-- Select Label Type --' );
        $reprint_barcode_choice .= $q->popup_menu( -name => "Barcode Name", -values => \@valid_labels, -class => "$css_class" );
    }
    elsif ( $valid_labels[0] ) {
        $footer .= hidden( -name => 'Barcode Name', -value => $valid_labels[0] ) . " <i>($valid_labels[0])</i>";
    }

    # $footer .= lbr() . &Link_To( $dbc->config('homelink'), "Check History", "&Plate+History=1&Plate+IDs=$plate_ids&Protocol_ID=$Prep->{protocol_id}", $Settings{LINK_COLOUR}, ['newwin'] ), &vspace(2);
    my $check_history = &Link_To( $dbc->config('homelink'), "Check History for Current Samples", "&cgi_application=alDente::Container_App&rm=Plate+History&FK_Plate__ID=$plate_ids&Protocol_ID=$Prep-\>{protocol_id}", $Settings{LINK_COLOUR}, ['newwin'] ),
        &vspace(2);

    ## Display footer section as an evenly split table with a slightly grey background colour to set it apart from the other input ##
    my $Form = new LampLite::Form( -framework => 'table', -class => 'form-horizontal', -span => [ 6, 6 ], -style => 'background-color:#ddd' );

    if ($prep_instruction) { $Form->append( $prep_instruction, -fullwidth => 1 ) }

    if ( $back_step || $skip_prep_step ) {
        ## add options to go forward or backwards ##
        $Form->append( $back_step, $skip_prep_step );
    }

    $Form->append( $fail_list,              $fail_button );
    $Form->append( $annotate_note,          $annotate_button );
    $Form->append( $reprint_barcode_choice, $reprint_barcode );
    $Form->append( $check_history,          -fullwidth => 1 );

    return $Form->generate( -open => 0, -close => 0 );

}

########################
sub _get_not_completed_prompt {
########################
    #
    # Returns a prompt if some of the PLAs have not completed the protocol
    #
    my $Prep = shift;

    my $dbc  = $Prep->{dbc};
    my %args = @_;
    my $prompt;

    my @array1 = Cast_List( -list => $Prep->{plate_ids},        -to => 'array', -autoquote => 0 );
    my @array2 = Cast_List( -list => $Prep->{Plates_Completed}, -to => 'array', -autoquote => 0 );
    my @array3 = &RGmath::minus( \@array1, \@array2 );
    if ( scalar(@array3) > 0 ) {    #there are plates that have not completed the protocol
        my $plate_list               = Cast_List( -list => \@array3, -to => 'string', -autoquote => 0 );
        my $plate_completed_protocol = Cast_List( -list => \@array2, -to => 'string', -autoquote => 0 );
        Message("Plate(s) $plate_completed_protocol have completed the protocol.");
        $prompt .= '<P>';
        $prompt .= Link_To( $dbc->config('homelink'), "Remove plates that have completed the protocol and Save the rest to a new plate set", "&cgi_application=alDente::Container_App&rm=Save Plate Set&Plate_ID=$plate_list" );
        $prompt .= '<P>';

    }

    return $prompt;
}

1;
