###################################################################################################################################
# Lib_Construction::Genechip_Summary.pm
#
# This class inherits alDente::View. It defines the configurations specific to GenechipRun
#
# This module contains the following functions/methods:
#
# Methods:
# set_input_options:            set the searching parameters
# set_output_options:           set the output fields.
# set_general_options:          set the general options
# get_actions:                  define possible actions to the result set
# do_actions:                   define the reactions for each action. this function should print html if the actions require so
# display_summary:              display a customizable summary table for the result set
# qc_plot:                      a customized function defined in the configuration hash
# re_scan:                      a customized function defined to determine if a run is a re-scan
#
# Notes on sub-classing alDente::View
# The following methods have to be implemented in a sub-class:
# set_input_options:
# set_output_options:
# set_general_options
#
###################################################################################################################################

package Microarray::Genechip_Summary;

use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules
use alDente::View;
use vars qw($Connection $user_id $homelink);

our @ISA = qw(alDente::View);

#################################
sub set_general_options {
#################################
    #
    # Set general options for the view
    #
    my $self = shift;
    my %args = filter_input( \@_ );

    $self->SUPER::set_general_options;    ## call super

    my $title = $self->{config}{title};   ## init title

    $self->{config}{API_module}  = 'Microarray_API';            ## API modules to be used
    $self->{config}{API_path}    = 'Departments/Microarray';    ## path to the API module
    $self->{config}{API_scope}   = 'genechiprun';               ## use method get_genechiprun_xxx
    $self->{config}{API_type}    = 'data';                      ## use method get_xxx_data
    $self->{config}{key_field}   = 'run_id';                    ## define the key field in the result set.
    $self->{config}{view_tables} = 'Run, Plate';

    return;
}

################################
sub set_input_options {
################################
    #
    # set input options for the view
    #
    my $self = shift;
    my %args = filter_input( \@_ );
    $self->SUPER::set_input_options;

    my $title = $self->{config}{title};

    ## preset API argument value.
    if ( $title =~ /expression/i ) {
        $self->{API_args}{-analysis_type}{value} = Cast_List( -list => ["Expression"], -to => "String", -autoquote => 1 );
        $self->{API_args}{-analysis_type}{preset} = 1;
    }
    elsif ( $title =~ /mapping/i ) {
        $self->{API_args}{-analysis_type}{value} = Cast_List( -list => ["Mapping"], -to => "String", -autoquote => 1 );
        $self->{API_args}{-analysis_type}{preset} = 1;
    }
    else {
        ## do nothing
    }

    ## default for the date field
    my $default    = date_time('-1d');
    my $default_to = now();

    # set -sub_array_type and -name values
    my @genechip_type_name_list;
    my @sub_array_type_list;
    if ( $title =~ /mapping/i ) {
        @genechip_type_name_list = $self->{dbc}->Table_find( "Genechip_Type", "Genechip_Type_Name", "where Array_Type = 'Mapping'" );
        @sub_array_type_list     = $self->{dbc}->Table_find( "Genechip_Type", "Sub_Array_Type",     "where Array_Type = 'Mapping' and Sub_Array_Type <>''" );
    }
    elsif ( $title =~ /expression/i ) {
        @genechip_type_name_list = $self->{dbc}->Table_find( "Genechip_Type", "Genechip_Type_Name", "where Array_Type = 'Expression'" );
        @sub_array_type_list     = $self->{dbc}->Table_find( "Genechip_Type", "Sub_Array_Type",     "where Array_Type = 'Expression' and Sub_Array_Type <>''" );
    }
    else {
        @genechip_type_name_list = $self->{dbc}->Table_find( "Genechip_Type", "Genechip_Type_Name" );
        @sub_array_type_list     = $self->{dbc}->Table_find( "Genechip_Type", "Sub_Array_Type" );
    }

    @genechip_type_name_list = sort { $a cmp $b } @genechip_type_name_list;
    @sub_array_type_list     = sort { $a cmp $b } @sub_array_type_list;

    ## data structure to store input_options to be used by the View.pm
    ## key: table.field
    ## argument: to be used as -argument in the API (need to be added to your API module if necessary)
    ## value: default value (array ref)
    ## list: customized drop-down menu (otherwise use what is in the database)

    $self->{config}{input_options} = {
        'Library.FK_Project__ID' => { argument => '-project_id', value => '' },
        'Plate.Plate_ID'         => { argument => '-plate_id',   value => '' },
        'Plate.FK_Library__Name' => { argument => '-library',    value => '' },
        'Run.Run_DateTime' => { argument => '',            value => $default . "<=>" . $default_to, type => 'date' },  ## if it is a date field, provide a type=>'date' and default in the format of '$start_date<=>$end_date'. e.g.: '2006-12-01<=>2007-01-30'
        'Run.Run_ID'       => { argument => '-run_id',     value => '' },
        'Run.Run_Status'   => { argument => '-run_status', value => '' },
        'Run.Run_Validation'                  => { argument => '-run_validation',     value => '' },
        'Genechip_Type.Sub_Array_Type'        => { argument => '-sub_array_type',     value => '', list => \@sub_array_type_list },
        'Genechip_Type.Genechip_Type_Name'    => { argument => '-genechip_type_name', value => '', list => \@genechip_type_name_list },
        'GenechipRun.FKScanner_Equipment__ID' => { argument => '-scanner_equipment',  value => '' },
    };

    ## order when appear on the page
    $self->{config}{input_order} = [
        'Library.FK_Project__ID', 'Plate.Plate_ID',               'Plate.FK_Library__Name',           'Run.Run_DateTime', 'Run.Run_ID', 'Run.Run_Status',
        'Run.Run_Validation',     'Genechip_Type.Sub_Array_Type', 'Genechip_Type.Genechip_Type_Name', 'GenechipRun.FKScanner_Equipment__ID'
    ];

    return;
}

#################################
sub set_output_options {
#################################
    #
    # set output options for the view
    #
    my $self = shift;
    my %args = filter_input( \@_ );
    $self->SUPER::set_input_options;
    my $title = $self->{config}{title};

    ## general output for mapping and expression
    ## key: aliases in API. you need to add the alias to the API module if necessary
    ## picked: default picked if set to 1
    $self->{config}{output_options} = {
        'run_id'                => { picked => 1 },
        'run_name'              => { picked => 1 },
        're_scan'               => { picked => 1 },
        'run_time'              => { picked => 1 },
        'run_status'            => { picked => 1 },
        'billable'              => { picked => 1 },
        'genechiprun_invoiced'  => { picked => 1 },
        'subdirectory'          => { picked => 1 },
        'validation'            => { picked => 1 },
        'sample_name'           => { picked => 1 },
        'analysis_type'         => { picked => 1 },
        'analysis_datetime'     => { picked => 1 },
        'artifact'              => { picked => 1 },
        'QC_plot'               => { picked => 1 },
        'patient_id'            => { picked => 1 },
        'gender'                => { picked => 1 },
        'chip_external_barcode' => { picked => 1 },
    };
    ## if a field needs its own function retrieve the value (i.e.,not obtained from the API), list function name here.
    ## the function needs to be defined in this module
    $self->{config}{output_function} = {
        'QC_plot' => "qc_plot",
        're_scan' => "re_scan",
    };
    ## if a field has a link as appeared on the page, list the URL here
    ## <VALUE> will be replaced by the field's value when processed
    $self->{config}{output_link} = { 'run_id' => "&HomePage=GenechipRun&ID=<VALUE>", };
    ## order as appeared on the page
    $self->{config}{output_order} = [
        'run_id',        'run_name',          're_scan',  'run_time', 'run_status', 'billable', 'genechiprun_invoiced', 'subdirectory', 'validation', 'sample_name',
        'analysis_type', 'analysis_datetime', 'artifact', 'QC_plot',  'patient_id', 'gender',   'chip_external_barcode',
    ];

    #$self->{config}{group_by} = { # these need to be the same as they appear in the API as output fields
    #'project_id' => {picked => 1},
    #'library'    => {picked => 0},
    #'pipeline_name' => {picked => 0},
    #};

    ## extra fields for expression or mapping
    my @extra_fields;

    if ( $title =~ /expression/i ) {
        @extra_fields = (
            'absent_probe_sets',          'absent_probe_sets_percent', 'algorithm',         'avg_a_signal',     'avg_p_signal',        'avg_m_signal',
            'avg_background',             'avg_centralminus',          'avg_cornerminus',   'avg_cornerplus',   'avg_noise',           'avg_signal',
            'controls',                   'count_centralminus',        'count_cornerminus', 'count_cornerplus', 'marginal_probe_sets', 'marginal_probe_sets_percent',
            'max_background',             'max_noise',                 'min_background',    'min_noise',        'noise_rawq',          'present_probe_sets',
            'present_probe_sets_percent', 'probe_pair_thr',            'std_background',    'std_noise',        'total_probe_sets',    'alpha1',
            'alpha2',                     'tau',                       'noise_rawq',        'scale_factor',     'norm_factor',         'tgt'
        );
    }
    elsif ( $title =~ /mapping/i ) {
        @extra_fields = ( 'total_snp', 'called_gender', 'snp_call_percent', 'qc_mcr_percent', 'qc_mdr_percent', 'aa_call_percent', 'ab_call_percent', 'bb_call_percent', 'qc_affx_5q_123', 'qc_affx_5q_456', 'qc_affx_5q_789', 'qc_affx_5q_abc' );

    }
    else {
        @extra_fields = ();
    }

    foreach my $item (@extra_fields) {
        $self->{config}{output_options}{$item}{picked} = 0;
        push( @{ $self->{config}{output_order} }, $item );
    }

    return;
}

#################
sub get_actions {
#################
    #
    # define action items to be applied to the result set
    #
    my $self  = shift;
    my $title = $self->{config}{title};
    my $dbc   = $self->{dbc} || $Connection;
    my %actions;

    ## set Run.Run_Validation
    $actions{1} = submit(
        -name    => 'Set_Validation_Status',
        -value   => 'Set Grid Alignment',
        -class   => 'Action',
        -onClick => "
        unset_mandatory_validators(this.form);
        document.getElementById('comments_validator').setAttribute('mandatory',(this.form.ownerDocument.getElementById('validation_status').value=='Rejected') ? 1 : 0)
        return validateForm(this.form)
        "
        )
        . '&nbsp;'
        . popup_menu( -name => 'Validation Status', -values => [ '', $dbc->get_enum_list( 'Run', 'Run_Validation' ) ], -default => '', -id => 'validation_status', -force => 1 );

    ## set Run.Billable
    $actions{2} = submit( -name => 'Set_Billable', -value => 'Set Billable', -class => 'Action' ) . '&nbsp;' . popup_menu( -name => 'Billable', -values => [ $dbc->get_enum_list( 'Run', 'Billable' ) ], -default => 'Yes', -id => 'billable', -force => 1 );

    ## set GenechipAnalysis.Artifact
    $actions{3}
        = submit( -name => 'Set_Artifact', -value => 'Set Artifact', -class => 'Action' ) 
        . '&nbsp;'
        . popup_menu( -name => 'Artifact Status', -values => [ $dbc->get_enum_list( 'GenechipAnalysis', 'Artifact' ) ], -default => 'No', -id => 'artifact_status', -force => 1 );

    my $groups = $self->{dbc}->get_local('group_list');
    my $reasons = alDente::Fail::get_reasons( -dbc => $dbc, -object => 'Run', -grps => $groups );

    ## set Failed and Failed reason
    $actions{4} = submit(
        -name    => 'Set_as_Failed',
        -value   => 'Set as Failed',
        -class   => 'Action',
        -onClick => "
        unset_mandatory_validators(this.form);
        document.getElementById('failreason_validator').setAttribute('mandatory',1);
        document.getElementById('comments_validator').setAttribute('mandatory',1);
        return validateForm(this.form)"
        )
        . '&nbsp;'
        . popup_menu( -name => 'FK_FailReason__ID', -values => [ '', sort keys %{$reasons} ], -labels => $reasons, -force => 1 )
        . set_validator( -name => 'FK_FailReason__ID', -id => 'failreason_validator' );

    ## set GenechipRun.Invoiced
    $actions{5}
        = submit( -name => 'Set_Invoiced', -value => 'Set Invoiced', -class => 'Action' ) . '&nbsp;' . popup_menu( -name => 'Invoiced', -values => [ $dbc->get_enum_list( 'GenechipRun', 'Invoiced' ) ], -default => 'No', -id => 'invoiced', -force => 1 );

    ## get QC Plot
    $actions{6} = submit( -name => 'Get_QC_Plot', -class => 'Std', -value => 'Get QC Plot' );

    ## compare Shared SNPs if mapping
    if ( $title =~ /mapping/i ) {
        $actions{7} = submit( -name => 'Compare_Shared_SNPs', -class => 'Std', -value => 'Compare Shared SNPs' );
    }

    return %actions;
}

################
sub do_actions {
################
    #
    # handle for actions
    #
    my $self = shift;

    ## get key field (run_id)
    my @ids;
    if ( param('SelectRun') ) {
        @ids = param('SelectRun');
    }
    elsif ( param('run_id') ) {
        @ids = param('run_id');
    }

    my $dbc = $self->{dbc};

    if ( scalar @ids > 0 ) {
        my $ids_string = join( ",", @ids );

        if ( param("Set_Artifact") ) {    ##########    Set Artifact

            my $artifact = param("Artifact Status");
            if ($artifact) {
                my $ok = $dbc->Table_update_array( 'GenechipAnalysis', ['Artifact'], [$artifact], "WHERE FK_Run__ID in ($ids_string)", -autoquote => 1 );
                Message("Updated $ok records");
            }

        }
        elsif ( param("Set_Billable") ) {
            my $billable = param("Billable");
            if ($billable) {
                my $ok = $dbc->Table_update_array( 'Run', ['Billable'], [$billable], "WHERE Run_ID in ($ids_string)", -autoquote => 1 );
                Message("Updated $ok records");
            }
        }
        elsif ( param("Set_Invoiced") ) {    ########### set invoiced
            my $invoiced = param("Invoiced");
            if ($invoiced) {
                my $ok = $dbc->Table_update_array( 'GenechipRun', ['Invoiced'], [$invoiced], "WHERE FK_Run__ID in ($ids_string)", -autoquote => 1 );
                Message("Updated $ok records");
            }

        }
        elsif ( param("Set_as_Failed") ) {

            my $fk_failreason__id = param('FK_FailReason__ID');
            my $comments          = param('Comments');
            my $Last_ids          = join ',', param('Last IDs');
            $Last_ids ||= 0;
            if ( $fk_failreason__id && $ids_string =~ /[1-9]/ ) {
                alDente::Fail::Fail( -object => 'Run', -ids => $ids_string, -reason => $fk_failreason__id, -comments => $comments );
            }
            else {
                Message("You must select at least one Run ID");
            }

        }
        elsif ( param("Set_Validation_Status") ) {    ######### Set Validation Status

            # set validation status
            my $validation = param("Validation Status");

            my $Last_ids = join ',', param('Last IDs');
            $Last_ids ||= 0;
            my $comments    = param('Comments');
            my $emp_initial = $dbc->get_local('user_initials');
            my ($date) = split ' ', &date_time();
            $comments = $validation . " by $emp_initial on $date: $comments.";
            if ( $validation && $ids_string =~ /[1-9]/ ) {
                my $ok = $dbc->Table_update_array( 'Run', ['Run_Validation'], [$validation], "WHERE Run_ID in ($ids_string)", -autoquote => 1 );
                $ok = alDente::Run::annotate_runs( -run_ids => $ids_string, -comments => $comments );
                Message("Updated $ok records");
            }
            else {
                Message("You need to set the validation status ($validation) and select at least 1 id.");
            }

        }
        elsif ( param("Compare_Shared_SNPs") ) {    ########## Compare Shared SNPs
            my @snps_array;
            foreach my $index ( 1 .. 50 ) {
                push( @snps_array, "SNP" . $index );
            }
            my %snps = $dbc->Table_retrieve( 'GenechipMapAnalysis', [ 'FK_Run__ID', @snps_array ], "WHERE FK_Run__ID in ($ids_string)" );

            my %snps_hash;

            foreach my $snp (@snps_array) {
                my $int = 0;
                while ( $snps{FK_Run__ID}->[$int] ) {
                    my $run_id   = $snps{FK_Run__ID}->[$int];
                    my $snp_data = $snps{$snp}->[$int];
                    $snps_hash{$snp}{$run_id} = $snp_data;
                    $int++;
                }
                my @data_array;
                foreach my $id (@ids) {
                    push @data_array, $snps_hash{$snp}{$id};
                }
                $snps_hash{$snp}{data} = \@data_array;
            }

            my $html = HTML_Table->new( -class => 'small', -title => 'Shared SNPs Across Runs' );
            $html->Set_Headers( [ 'SNPs', @ids ] );
            foreach my $snp (@snps_array) {
                $html->Set_Row( [ $snp, @{ $snps_hash{$snp}{data} } ] );
            }
            print $html->Printout(0);
            print "<hr/>";

        }
        elsif ( param("Get_QC_Plot") ) {    ########## QC plot

            my $title = $self->{config}{title};

            require Microarray::GenechipRun;

            my $genechip_run = Microarray::GenechipRun->new( -dbc => $dbc );
            my $plot = $genechip_run->display_qc_plot( -run_ids => $ids_string, -graph_title => $title, -layout => 'horizontal' );

            my $table_title = $title . " for Run " . $ids_string;
            print "<h1>$table_title</h1>";
            print $plot;
            print "<hr/>";

        }    # end of QC Plot

    }
    else {

    }

}

#####################
sub re_scan {
#####################
    #
    # determine if a run is a re-scan
    #
    my $self            = shift;
    my %args            = @_;
    my $key_field_value = $args{-key_field_value};    ## run_id
    my $dbc             = $self->{dbc};

    my $re_scan = "No";

    ## find if this run is a re-scan (if the chip has been used before in another run)
    my ($chip) = $dbc->Table_find( "Run, Array, Genechip", "Genechip_ID", "where Run_ID = $key_field_value and Run.FK_Plate__ID = Array.FK_Plate__ID and Array.FK_Microarray__ID = Genechip.FK_Microarray__ID", -distinct => 1 );

    my @all_runs = $dbc->Table_find( "Run, Array, Genechip", "Run_ID", "where Genechip_ID = $chip and Run.FK_Plate__ID = Array.FK_Plate__ID and Array.FK_Microarray__ID = Genechip.FK_Microarray__ID order by Run_DateTime", -distinct => 1 );

    if ( scalar @all_runs > 1 && $all_runs[0] != $key_field_value ) {
        $re_scan = "Yes";
    }

    return $re_scan;

}

####################
sub qc_plot {
####################
    #
    # draw QC plot thumbnail
    #
    my $self            = shift;
    my %args            = @_;
    my $key_field_value = $args{-key_field_value};    ## run_id
    my $dbc             = $self->{dbc};

    my $title     = $self->{config}{title};
    my $key_field = $self->{config}{key_field};

    require RGTools::Graphs;

    my %data;
    if ( $title =~ /mapping/i ) {
        my @array = $dbc->Table_find( "GenechipMapAnalysis", "QC_AFFX_5Q_456, QC_AFFX_5Q_123, QC_AFFX_5Q_789, QC_AFFX_5Q_ABC", "where FK_Run__ID = $key_field_value" );
        my @items = split( ",", $array[0] );
        $data{'set 1'} = [ $items[0], $items[1], $items[2], $items[3] ];
        $data{'x_axis'} = [ 'QC_AFFX_5Q_456', 'QC_AFFX_5Q_123', 'QC_AFFX_5Q_789', 'QC_AFFX_5Q_ABC' ];

    }
    elsif ( $title =~ /expression/i ) {
        my @array = $dbc->Table_find(
            "Probe_Set_Value, Probe_Set, GenechipExpAnalysis",
            "Probe_Set.Probe_Set_Name, Sig3, SigM, Sig5, Sig35",
            " where FK_GenechipExpAnalysis__ID = GenechipExpAnalysis_ID and FK_Run__ID = $key_field_value and FK_Probe_Set__ID = Probe_Set_ID and Probe_Set.Probe_Set_Name in ('AFFX-HUMGAPDH/M33197', 'AFFX-HSAC07/X00351')"
        );

        $data{x_axis} = [ "Sig3", "SigM", "Sig5", "Sig35" ];
        foreach my $item (@array) {
            my @items = split( ",", $item );
            $data{ $items[0] } = [ $items[1], $items[2], $items[3], $items[4] ];
        }
    }

    my $graph = Graphs->new( -height => 100, -width => 100 );

    if ( scalar( keys %data ) > 1 ) {

        $graph->set_config( -data => \%data, -title => $title, -x_label => 'QC Items', -y_label => 'Values', -thumbnail => 1 );
        $graph->create_graph( -type => 'line' );

        #Message("temp", $URL_temp_dir);
        my $alt = "click to see larger graph";

        return $graph->get_PNG_HTML( -file_path => $URL_temp_dir . "/" . $key_field_value . ".png", -file_url => "/SDB/dynamic/tmp/" . $key_field_value . ".png", -alt => $alt );
    }
    else {
        return "No Data";
    }

}

