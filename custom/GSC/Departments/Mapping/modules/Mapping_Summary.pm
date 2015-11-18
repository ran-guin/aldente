package Mapping::Mapping_Summary;

@ISA = qw(alDente::View);

use strict;
use CGI qw(:standard);

## SDB modules
use alDente::SDB_Defaults;
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules
use alDente::View;
use alDente::GelAnalysis;
use alDente::Run;
use alDente::Fail;
use alDente::Tools;

use vars qw($Connection $user_id $homelink $project_dir);

sub set_general_options {
    my $self = shift;
    my %args = filter_input( \@_ );
    $self->SUPER::set_general_options;

    my $title = $self->{config}{title};

    $self->{config}{API_scope}   = 'gelrun';
    $self->{config}{API_type}    = 'data';                        # use get_xxx_data
    $self->{config}{view_tables} = 'Run,Plate,GelRun,RunBatch';
    $self->{config}{key_field}   = 'run_id';

    return;
}

################################
sub set_input_options {
################################
    my $self = shift;
    my %args = filter_input( \@_ );
    $self->SUPER::set_input_options;

    my $title = $self->{config}{title};

    # if you want the list to be multiple selectable, you need to provide your own list

    my $default    = date_time('-1d');
    my $default_to = now();

    my @run_status     = ( 'Initiated', 'In Process', 'Data Acquired', 'Analyzed' );
    my @run_validation = ( 'Approved',  'Pending' );
    my @run_qc_status  = ( 'N/A',       'Pending', 'Failed', 'Passed' );

    my $run_id = param('Run_ID');
    my @run_id_default_value;
    if ($run_id) {
        $default              = "";
        $default_to           = "";
        @run_id_default_value = Cast_List( -list => $run_id, -to => 'array' );
        @run_status           = ( @run_status, ( 'Aborted', 'Failed', 'Expired', 'Not Applicable', 'Analyzing' ) );
        push( @run_validation, 'Rejected' );
        push( @run_qc_status,  'Re-Test' );
    }

    $self->{config}{input_options} = {
        'Library.FK_Project__ID' => { argument => '-project_id',     value => '' },
        'Run.Run_ID'             => { argument => '-run_id',         value => \@run_id_default_value },
        'Run.Run_Status'         => { argument => '-run_status',     value => \@run_status },
        'Run.QC_Status'          => { argument => '-run_qc_status',  value => \@run_qc_status },
        'Run.Run_Validation'     => { argument => '-run_validation', value => \@run_validation },
        'Plate.FK_Library__Name' => { argument => '-library',        value => '' },
        'Plate.Plate_Number'     => { argument => '-plate_number',   value => '' },
        'Run.Run_DateTime'       => { argument => '',                value => $default . "<=>" . $default_to, type => 'date' },
        'GelRun.GelRun_Type'     => { argument => '-type',           value => ['Sizing Gel'] },
    };

    $self->{config}{input_order} = [ 'GelRun.GelRun_Type', 'Library.FK_Project__ID', 'Plate.FK_Library__Name', 'Plate.Plate_Number', 'Run.Run_DateTime', 'Run.Run_ID', 'Run.Run_Status', 'Run.QC_Status', 'Run.Run_Validation', ];
    return;
}

#################################
sub set_output_options {
#################################
    my $self = shift;
    my %args = filter_input( \@_ );
    $self->SUPER::set_input_options;
    my $title = $self->{config}{title};

    # general output for mapping and expression
    $self->{config}{output_options} = {
        'run_id'              => { picked => 1 },
        'run_display_name'    => { picked => 1 },
        'run_name'            => { picked => 0 },
        'Gel_Name'            => { picked => 0 },
        'Swap_Check'          => { picked => 0 },
        'Self_Check'          => { picked => 0 },
        'Cross_Check'         => { picked => 0 },
        'run_time'            => { picked => 0 },
        'run_status'          => { picked => 0 },
        'run_QC_status'       => { picked => 0 },
        'run_validation'      => { picked => 0 },
        'autopass'            => { picked => 0 },
        'test_status'         => { picked => 0 },
        'Analysis_Status'     => { picked => 0 },
        'Poured'              => { picked => 0 },
        'Comb'                => { picked => 0 },
        'GelTray'             => { picked => 0 },
        'PouredDate'          => { picked => 0 },
        'Loaded'              => { picked => 0 },
        'LoadDate'            => { picked => 0 },
        'GelBox'              => { picked => 0 },
        'Scanner'             => { picked => 0 },
        'thumbnail'           => { picked => 1 },
        'TIF'                 => { picked => 0 },
        'run_comments'        => { picked => 0 },
        'plate_id'            => { picked => 0 },
        'plate_format'        => { picked => 0 },
        'pipeline_name'       => { picked => 1 },
        'branch_code'         => { picked => 1 },
        'agarose_solution'    => { picked => 0 },
        'lab_comments'        => { picked => 0 },
        'analysis_start_time' => { picked => 0 },
        'bandleader_version'  => { picked => 0 },
        'validation_override' => { picked => 0 },
        'poured_equipment'    => { picked => 0 },
        'gelrun_purpose'      => { picked => 0 },
    };

    $self->{config}{output_order} = [
        'run_id',              'run_display_name', 'run_name',     'Gel_Name',         'run_time',    'run_status',   'run_QC_status', 'run_validation', 'autopass',            'test_status',
        'Analysis_Status',     'Poured',           'PouredDate',   'agarose_solution', 'Comb',        'GelTray',      'Loaded',        'LoadDate',       'GelBox',              'Scanner',
        'thumbnail',           'TIF',              'run_comments', 'plate_id',         'branch_code', 'plate_format', 'pipeline_name', 'lab_comments',   'analysis_start_time', 'bandleader_version',
        'validation_override', 'poured_equipment', 'Swap_Check',   'Self_Check',       'Cross_Check', 'gelrun_purpose',
    ];

    $self->{config}{output_link} = {
        'plate_id' => "&cgi_application=alDente::Container_App&rm=Plate+History&FK_Plate__ID=<value>",
        'library'  => "&Scan=1&Barcode=<value>",
        'run_id'   => "&Scan=1&Barcode=run<value>",
    };

    $self->{config}{output_function} = {
        'thumbnail'        => 'get_thumbnail_link',
        'TIF'              => 'get_TIF_link',
        'lab_comments'     => 'get_lab_comments',
        'agarose_solution' => 'get_sol_FK_info',
    };

    return;
}

#####################
#
#
#
#################
sub format_html {
#################
    my $self = shift;
    my %args = @_;
    my $dbc  = $self->{dbc};

    my $text = $args{-output_value};

    $text =~ s/\n/<br>/g;

    return $text;
}

######################
sub get_thumbnail_link {
######################
    my $self = shift;
    my %args = @_;
    my $dbc  = $self->{dbc};

    my $run_id   = $args{-key_field_value};    ## run_id
    my $filepath = $args{-output_value};

    my $thumb_sm = $filepath;
    $thumb_sm =~ s/annotated\.jpg$/thumb.jpg/;
    my $stats_page = $filepath;
    $stats_page =~ s/annotated\.jpg$/stats.html/;

    my $objid = rand();

    # get the eight least significant figures
    $objid = 'Summary' . substr( $objid, -8 );

    my $return;

    if ( -e "$project_dir/$filepath" ) {
        $return = "<img src='../images/icons/magnify.gif' onMouseOver=\"writetxt('Click to see full size Image')\" onMouseOut='writetxt(0)' onClick=\"window.open('../dynamic/data_home/public/Projects/$filepath')\" width=13 height=13/>
            <div id='${objid}img' onMouseOver=\"writetxt(this.getAttribute('tip'))\" tip='Click to see statistics' onMouseOut='writetxt(0)'>
                <img src='../dynamic/data_home/public/Projects/$thumb_sm' onClick=\"if(document.getElementById('$objid').style.display=='none') {Effect.BlindDown('$objid')} else {Effect.BlindUp('$objid')}\" width=60 height=40/>
            </div>
            <div id='$objid' style='display:none;'></div>";

        my $attributes = join ',', $dbc->Table_find( 'Run_Attribute', 'Run_Attribute_ID', "WHERE FK_Run__ID=$run_id" );
        if ( -e "$project_dir/$stats_page" and $attributes ) {
            $return .= "<script>load_content_from_url('$objid','','../dynamic/data_home/public/Projects/$stats_page')</script>";
        }
        else {
            $return .= "<script>document.getElementById('$objid' + 'img').setAttribute('tip','<h3>Summary page is unavailable!</h3>');</script>";
        }

    }
    else {
        $return = "<Img Src ='/$URL_dir_name/images/wells/Pending_Run.png' border=1/>";
    }

    my ($test_status) = $dbc->Table_find( 'Run', 'Run_Test_Status', "WHERE Run_ID=$run_id" );
    if ( $test_status eq 'Test' ) {
        $return = "<div style='background-color:#FCC'>$return</div>";
    }

    return $return;
}

######################
sub get_sol_FK_info {
######################
    my $self   = shift;
    my %args   = @_;
    my $dbc    = $self->{dbc};
    my $sol_id = $args{-output_value};

    return $dbc->get_FK_info( 'FK_Solution__ID', $sol_id ) if $sol_id;

}

######################
sub get_TIF_link {
######################
    my $self = shift;
    my %args = @_;
    my $dbc  = $self->{dbc};

    my $run_id   = $args{-key_field_value};    ## run_id
    my $filepath = $args{-output_value};

    if ( -e "$project_dir/$filepath" ) {
        return "<a href='../dynamic/data_home/public/Projects/$filepath'>download</a>";
    }
    else {
        return "-";
    }
}

######################
sub get_lab_comments {
######################
    my $self = shift;
    my %args = @_;
    my $dbc  = $self->{dbc};

    my $run_id = $args{-key_field_value};    ## run_id

    my ($plate_id) = $dbc->Table_find( 'Run', 'FK_Plate__ID', "WHERE Run_ID = $run_id" );
    return &alDente::Container::get_Notes( -dbc => $dbc, -plate_id => $plate_id, -output => 'tooltip' ) if $plate_id;
}

# find the GelAnalysis_ID to replace the <function> tag in the link
###################
#
#
###################
sub status_link {
###################
    my $self            = shift;
    my %args            = @_;
    my $key_field_value = $args{-key_field_value};    # run_id
    my $dbc             = $self->{dbc};
    my ($gel_analysis_id) = $dbc->Table_find( "GelAnalysis", "GelAnalysis_ID", "where FK_Run__ID = $key_field_value" );
    return $gel_analysis_id;
}

################################
#
#
#
#################
sub get_actions {
#################
    my $self = shift;
    my $dbc = $self->{dbc} || $Connection;

    my %actions;
    my $action_index = 0;

    my $access = $dbc->get_local('Access');

    $actions{ ++$action_index } = set_validator( -name => 'Comments', -id => 'comments_validator' ) . submit(
        -name    => 'Annotate Runs',
        -label   => 'Comment',
        -class   => 'Action',
        -force   => 1,
        -onClick => "
            unset_mandatory_validators(this.form);
            document.getElementById('comments_validator').setAttribute('mandatory',1);
            return validateForm(this.form)"
        )
        . hspace(10)
        . Show_Tool_Tip( textfield( -name => 'Comments', -size => 30, -default => '', -force => 1 ), "Mandatory for Rejected and Failed runs" );

    if ( grep( /Admin/, @{ $access->{$Current_Department} } ) || $access->{'LIMS Admin'} ) {
        $actions{ ++$action_index } = submit(
            -name    => 'Set_Validation_Status',
            -value   => 'Set Validation Status',
            -class   => 'Action',
            -onClick => "
            unset_mandatory_validators(this.form);
            document.getElementById('validation_validator').setAttribute('mandatory',1);
            return validateForm(this.form)
            "
            )
            . hspace(10)
            . popup_menu( -name => 'Validation Status', -values => [ '', get_enum_list( $dbc, 'Run', 'Run_Validation' ) ], -default => '', -id => 'validation_status', -force => 1 )
            . set_validator( -name => 'Validation Status', -id => 'validation_validator' );

        $actions{ ++$action_index } = submit( -name => 'Pass_QC_and_Approve_Run', -value => 'Pass QC and Approve Run', -class => 'Action' );

        my $groups = $dbc->get_local('group_list');
        my $reasons = alDente::Fail::get_reasons( -dbc => $dbc, -object => 'Plate', -grps => $groups );

        if ($reasons) {
            my $on_click = "unset_mandatory_validators(this.form);
                document.getElementById('failreason_validator').setAttribute('mandatory',1);
                return validateForm(this.form)";

            $actions{ ++$action_index } = submit( -name => 'Set_as_Failed', -value => 'RePrep', -class => 'Action', -onClick => $on_click ) . hspace(5) .

                #popup_menu(-name=>'FK_Pipeline__ID',-values=>['', 'MP3', 'MP9'],-default=>'',-force=>1) . hspace(5) .
                alDente::Tools::search_list( -dbc => $dbc, -name => 'Plate.FK_Pipeline__ID', -search => 1, -filter => 1, -mode => 'popup', -filter_by_dept => 1 )
                . submit( -name => 'Set_as_Failed', -value => 'ReCut', -class => 'Action', -onClick => $on_click )
                . hspace(5)
                . submit( -name => 'Set_as_Failed', -value => 'ReLoad', -class => 'Action', -onClick => $on_click )
                . hspace(10)
                . popup_menu( -name => 'FK_FailReason__ID', -values => [ '', sort values %{$reasons} ], -force => 1 )
                . set_validator( -name => 'FK_FailReason__ID', -prompt => 'Fail reason', -id => 'failreason_validator' );
        }
    }

    $actions{ ++$action_index } = submit( -name => 'Abort Runs', -value => 'Abort Selected', -class => 'Action' );

    $actions{ ++$action_index } = submit(
        -name    => 'Set Test Status',
        -class   => 'Action',
        -onClick => "unset_mandatory_validators(this.form); document.getElementById('test_status_validator').setAttribute('mandatory',1); return validateForm(this.form)"
        )
        . hspace(10)
        . set_validator( -name => 'Test Status', -id => 'test_status_validator' )
        . popup_menu( -name => 'Test Status', -values => [ '', get_enum_list( $dbc, 'Run', 'Run_Test_Status' ) ], -force => 1 );

    $actions{ ++$action_index } = submit(
        -name    => 'Set Billable',
        -class   => 'Action',
        -onClick => "unset_mandatory_validators(this.form); document.getElementById('billable_validator').setAttribute('mandatory',1); return validateForm(this.form)"
        )
        . hspace(10)
        . set_validator( -name => 'Billable', -id => 'billable_validator' )
        . popup_menu( -name => 'Billable', -values => [ '', get_enum_list( $dbc, 'Run', 'Billable' ) ], -force => 1 );

    $actions{ ++$action_index } = submit( -name => 'View_Lanes',           -value => 'View Lanes',           -class => 'Std' );
    $actions{ ++$action_index } = submit( -name => 'View_Diagnostic_Page', -value => 'View Diagnostic Page', -class => 'Std' );

    $actions{ ++$action_index } = submit( -name => 'Re_Print_Barcode', -value => 'Re-Print Barcodes', -class => 'Std' );

    #if(grep(/Bioinformatics/,@{$access->{$Current_Department}}) || $access->{'LIMS Admin'}) {
    #my @GA_status = $dbc->Table_find('Status','Status_Name',"WHERE Status_Type='GelAnalysis'");

    #$actions{++$action_index} = submit(-name=>'Set_Analysis_Status',-value=>'Set Analysis Status', -class=>'Action',-onClick=>"
    #unset_mandatory_validators(this.form);
    #document.getElementById('failreason_validator').setAttribute('mandatory',1);
    #return validateForm(this.form)") . '&nbsp;' . popup_menu(-name=>'Analysis_Status',-values=>['',@GA_status]) . set_validator(-name=>'Analysis_Status',-id=>'analysis_status_validator');
    #}

    return %actions;
}

############################
#
# Parse View Actions
#
#########################
sub do_actions {

    my $self    = shift;
    my @run_ids = param('run_id');
    my $run_ids = join( ',', @run_ids );

    my $comments = param('Comments');
    my $dbc      = $self->{dbc};

    if ($comments) {
        ### Annotate the runs
        my $ok = &alDente::Run::annotate_runs( $run_ids, $comments );
        Message("Annotated $ok Runs");
    }

#################################################
    if ( param('Set_Validation_Status') ) {

        my $validation = param('Validation Status');

        if ($validation) {

            if ( $validation eq 'Pending' ) {
                Message("Warning: Setting Run_Validation to 'Pending' for $run_ids");
            }

            my $override_list = join( ',', $dbc->Table_find( 'Run,GelAnalysis', 'Run_ID', "WHERE Run_ID=FK_Run__ID AND Run_Validation NOT IN ('Pending','$validation') AND Run_ID IN ($run_ids)" ) );
            $dbc->Table_update_array( 'GelAnalysis', ['Validation_Override'], ['YES'], "WHERE FK_Run__ID IN ($override_list)", -autoquote => 1 ) if $override_list;

            ## Set the validation status
            my $update = &alDente::Run::set_validation_status( $run_ids, $validation );
            Message("Updated validation status to '$validation' for $update run(s).");
        }
    }
    elsif ( param('Pass_QC_and_Approve_Run') ) {
        my $validation    = "Approved";
        my $qc_status     = "Passed";
        my $override_list = join( ',', $dbc->Table_find( 'Run,GelAnalysis', 'Run_ID', "WHERE Run_ID=FK_Run__ID AND Run_Validation NOT IN ('Pending','$validation') AND Run_ID IN ($run_ids)" ) );
        $dbc->Table_update_array( 'GelAnalysis', ['Validation_Override'], ['YES'], "WHERE FK_Run__ID IN ($override_list)", -autoquote => 1 ) if $override_list;

        ## Set the validation status
        my $update = &alDente::Run::set_validation_status( $run_ids, $validation );
        Message("Updated validation status to '$validation' for $update run(s).");

        ## Set the qc status
        my $update = &alDente::QA::set_qc_status( -method => $qc_status, -table => 'Run', -ids => $run_ids );
        Message("Updated QC status to '$qc_status' for $update run(s).");

    }
    elsif ( param('Set Test Status') ) {
        my $test_status = param('Test Status');

        if ($test_status) {
            $dbc->Table_update_array( 'Run', ['Run_Test_Status'], [$test_status], "WHERE Run_ID IN ($run_ids)", -autoquote => 1 );
        }
        else {
            Message("Invalid Test Status: '$test_status'");
        }
    }
    elsif ( param('Set Billable') ) {
        my $status = param('Billable');
        &alDente::Run::set_billable_status( $dbc, $run_ids, $status );
#################################################
        # } elsif (param('Set_Analysis_Status')) { my $status = param('Analysis_Status'); Message("Not doing anything");
#################################################
    }
    elsif ( param('Set_as_Failed') ) {
        my $fail_type        = param('Set_as_Failed');
        my $plate_failreason = param('FK_FailReason__ID');
        my ($gel_failreason_id) = $dbc->Table_find( 'FailReason,Object_Class', 'FailReason_ID', "WHERE Object_Class='Run' AND Object_Type='GelRun' AND Object_Class_ID=FK_Object_Class__ID AND FailReason_Name='General Reason'" );
        my $ok = &alDente::Fail::Fail( -object => 'Run', -object_type => 'GelRun', -ids => $run_ids, -reason => $gel_failreason_id, -comments => "$fail_type: $plate_failreason" );
        alDente::Run::set_validation_status( -dbc => $dbc, -run_ids => $run_ids, -status => 'Rejected' );

        my @plate_ids = $dbc->Table_find( 'Run', 'FK_Plate__ID', "WHERE Run_ID IN ($run_ids)" );

        my @PTF;                ### Plates to Fail
        my %rePrep_Original;    ### Original Plate for rePrep
        foreach my $plate_id (@plate_ids) {
            push( @PTF, $plate_id );

            my %parents = &alDente::Container::get_Parents( -dbc => $dbc, -id => $plate_id );
            for ( my $i = 0; $i <= $parents{parent_generations}; $i++ ) {
                ### Mapping Customization
                ### birth starts at -0
                if ( $parents{generation}{"-$i"} ) {

                    #                    if ($fail_type eq 'RePrep' and $parents{birth}{"-$i"} =~ /^Original Plate/) {
                    #			$rePrep_Original{$parents{generation}{"-$i"}} = 1;
                    #			last;
                    #		    }
                    if ( $fail_type eq 'RePrep' and $i > 3 ) {

                        #for the 5th parent, if it is a culture plate but not original plate, then can fail
                        if ( $parents{formats}{"-$i"} =~ /culture/i and $parents{birth}{"-$i"} !~ /^Original Plate/ ) {
                            push( @PTF, $parents{generation}{"-$i"} );
                        }

                        #find original plate
                        for ( my $c = $i; $c <= $parents{parent_generations}; $c++ ) {
                            if ( $parents{birth}{"-$c"} =~ /^Original Plate/ ) {
                                $rePrep_Original{ $parents{generation}{"-$c"} } = 1;
                                last;
                            }
                        }
                        last;
                    }
                    if ( $fail_type eq 'ReCut' and ( $parents{birth}{"-$i"} =~ /^MP Prep/ || $i > 1 ) ) { last; }

                    #For ReLoad manual
                    if ( $fail_type eq 'ReLoad' and ( $parents{birth}{"-$i"} =~ /^MP Digest/ || $i > 0 ) and $parents{formats}{"-$i"} !~ /ferro/i ) { last; }

                    #For ReLoad ferro
                    if ( $fail_type eq 'ReLoad' and ( $parents{birth}{"-$i"} =~ /^MP Digest/ || $i > 0 ) and $parents{formats}{"-$i"} =~ /ferro/i ) {
                        push( @PTF, $parents{generation}{"-$i"} );
                        last;
                    }
                    push( @PTF, $parents{generation}{"-$i"} );
                }
            }
        }

        alDente::Fail::Fail( -object => 'Plate', -ids => \@PTF, -reason => $plate_failreason, -comments => "$fail_type: $plate_failreason", -fail_status_field => 'Failed', -fail_status_value => 'Yes', -quiet => 1 ) if @PTF;
        Message("Failed Runs: $run_ids");

        my $pipeline = param('Plate.FK_Pipeline__ID');
        $pipeline =~ s/\s:.*//;
        my ($FK_Pipeline__ID) = $dbc->Table_find( 'Pipeline', 'Pipeline_ID', "WHERE Pipeline_Code = '$pipeline'" );

        #Message ("pipeline -> $pipeline");
        #Message ("FK_Pipeline__ID -> $FK_Pipeline__ID");
        if ( keys %rePrep_Original && $pipeline ) {
            my @original_ids     = keys %rePrep_Original;
            my $original_ids     = Cast_List( -list => \@original_ids, -to => 'String' );                                                     #"(" . join (",", keys %rePrep_Original) . ")";
            my $UpdateNum        = $dbc->Table_update( 'Plate', 'FK_Pipeline__ID', $FK_Pipeline__ID, "WHERE Plate_ID IN ($original_ids)" );
            my $display_pipeline = alDente_ref( 'Pipeline', $FK_Pipeline__ID );
            Message("Reset Pipeline for Plate $original_ids to $display_pipeline");
        }

#################################################
    }
    elsif ( param('Abort Runs') ) {
        Sequencing::Sequence::run_state_swap( -dbc => $dbc, -search => 'Initiated|In Process', -replace => 'Aborted', -notes => $comments, -ids => $run_ids );
        alDente::Run::set_validation_status( -dbc => $dbc, -run_ids => $run_ids, -status => 'Rejected' );
        Message("Aborted Runs: $run_ids");
#################################################
    }
    elsif ( param('View_Lanes') ) {
        my $output = '';
        foreach ( split( ',', $run_ids ) ) {
            my $gel = alDente::GelRun->new( -dbc => $dbc, -run_id => $_ );
            $output .= lbr() . $gel->display_Gel_Lanes();
        }
        print $output;
#################################################
    }
    elsif ( param('View_Diagnostic_Page') ) {
        if ($run_ids) {
            my @headers         = ( 'FK_Run__ID', 'Gel_Name', 'Gel_Checking', 'Lane_Tracking', 'Band_Calling', 'Rejected_Clones', 'Index_Checking' );
            my @display_headers = ( 'Run_ID',     'Gel_Name', 'Gel_Checking', 'Lane_Tracking', 'Band_Calling', 'Rejected_Clones', 'Index_Checking' );
            my %diagnostic = $self->{dbc}->Table_retrieve( 'GelAnalysis', [@headers], "WHERE FK_Run__ID in ($run_ids)" );
            my $html = HTML_Table->new( -class => 'small', -title => 'Gel Diagnostic Page' );
            $html->Set_Headers( [@display_headers] );

            my $index = 0;
            while ( $diagnostic{FK_Run__ID}->[$index] ) {
                my @data_row;
                @data_row = map { $diagnostic{$_}->[$index] } @headers;
                $html->Set_Row( [@data_row] );
                $index++;
            }

            print $html->Printout(0);
            print "<hr/>";
        }

    }
    elsif ( param('Re_Print_Barcode') ) {
        foreach (@run_ids) {
            my ($plate_id) = $dbc->Table_find( 'Run', 'FK_Plate__ID', "WHERE Run_ID=$_" );
            if ($plate_id) {
                &alDente::Barcoding::PrintBarcode( $dbc, 'Run', $_ );
            }
            else {
                &alDente::Barcoding::PrintBarcode( $dbc, 'GelRun', $_ );
            }
        }

    }
    return 0;
}

return 1;

