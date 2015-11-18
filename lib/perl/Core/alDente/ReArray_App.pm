####################
# ReArray_App.pm #
####################
#
# This is a ReArray for the use of various MVC App modules (using the CGI Application module)
#
package alDente::ReArray_App;

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

use base alDente::CGI_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use CGI::Carp('fatalsToBrowser');
use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Web_Form;

use LampLite::File;

use alDente::Form;
use alDente::Validation;
use alDente::ReArray;
use alDente::ReArray_Views;

use SDB::CustomSettings;
use SDB::HTML;
use alDente::SDB_Defaults;

##############################
# global_vars                #
##############################
use vars qw(%Configs %Settings $qpix_log_dir);
my $BS = new Bootstrap();
################
# Dependencies #
################
#
# (document list methods accessed from external models)
#

############
sub setup {
############
    my $self = shift;

    $self->start_mode('default_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default_page'                            => 'default_page',
            'home_page'                               => 'home_page',
            'search_page'                             => 'search_page',
            'View ReArrays'                           => 'list_page',
            'View ReArray'                            => 'view_rearray',
            'Manually Set Up ReArray/Pooling'         => 'set_up_rearray',
            'Complete ReArray Specification'          => 'complete_manual_rearray',
            'Save manual rearray'                     => 'save_manual_rearray',
            'Upload Qpix Log'                         => 'upload_qpix_log',
            'Confirm QPix Log'                        => 'confirm_qpix_log',
            'Upload Yield Report'                     => 'upload_yield_report',
            'Rearray Summary'                         => 'rearray_summary',
            'View Primer Plates'                      => 'view_primer_plates',
            'Set Primer Plate Well Status'            => 'set_primer_plate_well_status',
            'Generate DNA Multiprobe'                 => 'generate_dna_multiprobe',
            'Generate Custom Primer Multiprobe'       => 'generate_custom_primer_multiprobe',
            'Generate Multiprobe'                     => 'generate_multiprobe',
            'Regenerate QPIX File'                    => 'regenerate_qpix_file',
            'Write to QPIX File'                      => 'write_to_qpix_file',
            'Show QPIX Rack'                          => 'show_qpix_rack',
            'Apply Rearrays'                          => 'apply_rearrays',
            'Move to Completed'                       => 'complete_rearray',
            'Abort Rearrays'                          => 'abort_rearray',
            'Create Remapped Custom Primer Plate'     => 'create_remapped_custom_primer_plate',
            'Primer Plate Summary'                    => 'primer_plate_summary',
            'Source Plate Count'                      => 'source_plate_count',
            'Group into Lab Request'                  => 'group_into_lab_request',
            'Locations'                               => 'rearray_locations',
            'View rearray source plates in one table' => 'rearray_grouped_locations',
            'Source Primer Plate Count'               => 'source_primer_plate_count',
            'rearray_map'                             => 'rearray_map',
            'ReArray Wells'                           => 'rearray_wells',
            'Pool To Tube By Rows'                    => 'pool_to_tube_by_rows',
            'Pool To Single Tube'                     => 'pool_to_single_tube',
            'ReArray/Pool Wells'                      => 'pool_wells',
            'Batch ReArray/Pool Wells'                => 'batch_pool_wells',
            'Submit ReArray/Pool Request'             => 'confirm_create_pool_wells_rearray',
            'Confirmed ReArray/Pool Request'          => 'confirm_create_pool_wells_rearray',
            'Create ReArray'                          => 'parse_create_rearray',
            'Batch Pooling Sources'                   => 'upload_batch_pooling_sources',
            'Generate ReArray Span-8 csv'             => 'generate_rearray_csv',
            'View Index and other related fields'     => 'indices_and_other_fields_check',
        }
    );

    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');

    return $self;
}

###############
## run modes ##
###############
sub indices_and_other_fields_check {
    my $self     = shift;
    my %args     = &filter_input( \@_ );
    my $dbc      = $self->param('dbc');
    my $q        = $self->query;
    my $plate_ids = $q->param('plate_id') || $args{-plate_id};
    my $no_view  = $args{-no_view} || 0;
    my $output;
    my $rearray_page;

    unless ($plate_ids) {
        $rearray_page .= $BS->message("No plate ID entered.");
        $rearray_page .= $self->search_page();
        return $rearray_page;
    }
        require Illumina::Solexa_Analysis;
        my $solexa_analysis_obj = Illumina::Solexa_Analysis->new( -dbc => $dbc );
    $plate_ids = &get_aldente_id( $dbc, $plate_ids, 'Plate' ) if $plate_ids;
    my @header = ( "sample_id", "sample_name", "source_plate", "solution_id", "index", "taxonomy", "source_well", "primer_plate_position", "primer_name" );
    my @plate_ids = Cast_List( -list => $plate_ids, -to => 'Array' );
    foreach my $plate_id (@plate_ids) {

        $dbc->message("Checking Index and other related fields of plate ID: $plate_id");
        $output = $solexa_analysis_obj->get_indices( -plate_id => $plate_id );

    my @keys   = keys %$output;
    my @values = values %$output;
    my $j      = 0;
    my $i      = 0;
    my @missing_col;
    my $message = "For Plate ID: $plate_id";
    my %data;

        my @x = keys %{ $values[$i] };
        for ( $j = 0; $j <= $#x; $j++ ) {    # total number of headers
            my @val;
            for ( $i = 0; $i <= $#keys; $i++ ) {    #total number of indices
                my @z = $values[$i]{"$x[$j]"};      # content of each header
                push @val, @z;
            }
            $data{"$x[$j]"} = \@val;
        }
        $data{"$x[$j]"} = \@val;
    }
    $j = 1;
    foreach my $col (@header) {
        if ( $data{$col} ) {
            my $actual_size  = @{ $data{$col} };
            my $suppose_size = @keys;
            if ( $actual_size > $suppose_size ) {
                $i = $actual_size - $suppose_size;
                $message .= " <br>Missing: $i $col </br>";
                push @missing_col, $j;
            }
            elsif ( $actual_size < $suppose_size ) {
                $i = $suppose_size - $actual_size;
                $message .= " <br>Missing: $i $col </br>";
                push @missing_col, $j;
            }
        }
        else { $message .= "<br>Missing: All $col </br>"; push @missing_col, $j; }
        $j++;
    }

    if (@missing_col) { $rearray_page .= $BS->warning("$message"); }
    if ( %data && !($no_view) ) {
            $rearray_page .= alDente::ReArray_Views::indices_and_other_fields_view( -dbc => $dbc, -data_ref => \%data, -num_rows => \@keys, -header_ref => \@header, -missing_col => \@missing_col, -plate_id => $plate_id );
    }
    }
    return $rearray_page;
}
#####################
#
# default_page (default)
#
# Return: display home_page if 1 id, list_page if a list of ids or search_page if no ids
#####################
sub default_page {
#####################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;

    my $dbc = $self->param('dbc');
    my @ids = $q->param('ID');

    my $output;
    if ( int(@ids) == 1 ) {
        my $id = $ids[0];
        return $self->home_page( -id => $id );
    }
    elsif (@ids) {
        return $self->list_page( -ids => \@ids );
    }
    else {
        return $self->search_page();
    }
    ## enable related object(s) as required

    return;
}

sub view_rearray {
    my $self     = shift;
    my $q        = $self->query;
    my @requests = $q->param('Request_ID') || $q->param('Request IDs');
    my $view_rearrays;

    foreach my $id (@requests) {
        my $rearray_home = $self->home_page( -id => $id );
        $view_rearrays .= $rearray_home;
    }

    return $view_rearrays;
}
#####################
#
# home_page for single ReArray
#
# Return: display (table)
#####################
sub home_page {
#####################
    my $self = shift;

    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $id   = $args{-id} || $q->param('ID');

    my $dbc = $self->param('dbc');

    my $output;

    if ($id) {
        ## enable related object(s) as required ##
        my $rearray_page = alDente::ReArray_Views::home_page( -dbc => $dbc, -id => $id );

        #        $self->param(
        #            'ReArray_Model'    => $ReArray,
        #        );
        $output .= $rearray_page;
    }
    else {
        $output .= "ID not recognized ($id)";
        $output .= $self->search_page();
    }

    return $output;
}

################################
# Search page for ReArrays
#
# Return: html page
############################
sub search_page {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $output = alDente::ReArray_Views::display_search_page( -dbc => $dbc );
    $output .= alDente::ReArray_Views::display_utilities_search_page( -dbc => $dbc );

    return $output;
}

################################
# View rearray page for ReArrays (providing search result for search_page)
# Refactored from Button_Options:  elsif (param('View ReArray')) {
# Associted View: display_search_page
#
# Return: html page
############################
sub list_page {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    $dbc->message("Viewing Rearrays");

    my $targets          = join ',', $q->param('Target Plates');
    my $rearray_ids      = $q->param("Request IDs");
    my $emp              = $q->param("Employee");
    my $target_libraries = $q->param("Target Library String") || $q->param("Target Library") || get_Table_Param( -field => 'FK_Library__Name', -dbc => $dbc );
    my $from_date        = $q->param("from_date_range");
    my $to_date          = $q->param("to_date_range");
    my $rearray_type     = $q->param("ReArray Type");
    my $platenum         = $q->param("Plate Number");
    my $test             = $q->param("test");

    if ($test) { return "testing" }

    if ( $emp eq "-" ) {
        $emp = 0;
    }

    my ($emp_id) = $dbc->Table_find( "Employee", "Employee_ID", "WHERE Employee_Name like '$emp'" );

    $rearray_ids = &resolve_range($rearray_ids);
    $platenum    = &resolve_range($platenum);
    my $plate_targets = &get_aldente_id( $dbc, $targets, 'Plate' ) if $targets;
    my $rearray_status = $q->param('ReArray Status');

    my $output = alDente::ReArray_Views::view_rearrays(
        -dbc            => $dbc,
        -plate          => $plate_targets,
        -status         => $rearray_status,
        -request_ids    => $rearray_ids,
        -emp_id         => $emp_id,
        -target_library => $target_libraries,
        -from_date      => $from_date,
        -to_date        => $to_date,
        -type           => $rearray_type,
        -platenum       => $platenum
    );

    return $output;
}

################################
# Set up Rearray
# Refactored from Button_Options:  elsif (param('Set Up ReArray')) {
# Associted View: display_utilities_search_page
#
# Return: html page
############################
sub set_up_rearray {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    $dbc->message("Set up Rearray");

    my $target_plate              = $q->param('Plate ID');
    my $plate_list                = $q->param("Rearray Plates");
    my $target_plate_nomenclature = $q->param('Target Well Nomenclature');
    my $manual_rearray_page       = alDente::ReArray_Views::manual_rearray_page( -dbc => $dbc, -plate => $target_plate, -plate_list => $plate_list, -target_plate_nomenclature => $target_plate_nomenclature );

    return $manual_rearray_page;
}

#############################
sub complete_manual_rearray {
##############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $plate_size          = $q->param('Plate Size');
    my $rearray_size_format = $q->param('ReArray Well Nomenclature');
    my $target_plate        = $q->param('Plate ID');
    my $source_plates       = $q->param('ReArrayed From');
    my $include_primers     = $q->param('Specify Primers');
    my $fill_by             = $q->param('Fill By');

    $source_plates = $self->_replace_scanned_box_with_contents( -type => 'Plate', -barcode => $source_plates );    ## allow user to scan in Box (Rack_ID) instead of all tubes inside...

    if ( $source_plates =~ /$Prefix{Plate}/i ) {
        $source_plates = &get_aldente_id( $dbc, $source_plates, 'Plate' );
    }
    else {
        $source_plates = &extract_range($source_plates);
    }

    # get the total number of wells that the source plates have if ReArray Total is not defined
    my $number = 96;

    # get the maximum target number
    my $max_number = 384;
    if ( $plate_size =~ /(\d+).*/ ) {
        $max_number = $1;
    }

    my $min_source_size = '96-well';
    if ( $q->param('ReArray Total') ) {
        if ( $q->param('ReArray Total') <= $max_number ) {
            $number = $q->param('ReArray Total');
        }
        else {
            $number = $max_number;
        }
    }
    else {
        $number = 0;
        my @sizes = $dbc->Table_find_array( 'Plate', ['Plate_Size'], "where Plate_ID in ($source_plates)" );
        foreach my $size (@sizes) {
            if ( $size =~ /(\d+).*/ ) {
                $number += $1;
            }
        }
        $number = $max_number if ( $number > $max_number );
        if ( scalar( grep {/384/} @sizes ) ) {
            $min_source_size = '384-well';
        }
    }

    # see if the source plates are all 96-well plates. If they are, then the range should be 96-well
    my $source_wells   = &extract_range( $q->param('From Wells'), ",", "H" );
    my $unused_columns = $q->param('Unused Columns');
    my $unused_rows    = $q->param('Unused Rows');

    my $complete_manual_rearray_page = alDente::ReArray_Views::specify_rearray_wells(
        -dbc            => $dbc,
        -number         => $number,
        -source_plates  => $source_plates,
        -source_wells   => $source_wells,
        -rearray_format => $rearray_size_format,
        -plate_size     => $plate_size,
        -primers        => $include_primers,
        -fill_by        => $fill_by,
        -unused_columns => $unused_columns,
        -unused_rows    => $unused_rows,
    );

    return $complete_manual_rearray_page;
}

##########################
sub save_manual_rearray {
##########################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    # extract all information to create a plate
    # parse out parameters
    #my $actual_plate_size = param('Size');
    my $plate_format = get_Table_Param( -field => 'FK_Plate_Format__ID', -dbc => $dbc );
    $plate_format = $dbc->get_FK_ID( 'FK_Plate_Format__ID', $plate_format );
    my $rack = get_Table_Param( -field => 'FK_Rack__ID', -dbc => $dbc );
    $rack = $dbc->get_FK_ID( 'FK_Rack__ID', $rack );
    my $status   = $q->param('Plate Status') || 'Active';
    my $quadrant = $q->param('Quadrant');
    my $library  = get_Table_Param( -field => 'FK_Library__Name', -dbc => $dbc );
    $library = $dbc->get_FK_ID( 'FK_Library__Name', $library );
    my $created        = $q->param("Created");
    my $rearray_format = $q->param('ReArray Format');
    my $double_print   = $q->param("Print Two Labels");
    my $pipeline       = get_Table_Param( -field => 'FK_Pipeline__ID', -table => 'Plate', -dbc => $dbc );
    $pipeline = $dbc->get_FK_ID( "FK_Pipeline__ID", $pipeline );
    my $specify_primers = $q->param('ReArray Primer 1');
    my $rearray_obj = new alDente::ReArray( -dbc => $dbc );

    my $target_plate;
    if ( $q->param('Target Plate') ) {
        my $target = $q->param('Target Plate');
        $target_plate = get_aldente_id( $dbc, $target, 'Plate' );
        $dbc->message("Got $target_plate ($target)");
    }
    else {
    }

    #	my $number = param('ReArray Total');

    my @target_wells = ();

    my $plate_size = $q->param('Actual Plate Size');

    my $number;
    foreach my $name ( $q->param() ) {
        if ( $name =~ /ReArray Plate (\d+)/ ) {
            my $index = $1;
            if   ( $q->param("Ignore $index") ) { next; }
            else                                { $number++; }
        }
    }

    # get all the wells and their quadrant if necessary
    my $prev_quad = '';
    for ( my $index = 1; $index <= $number; $index++ ) {
        if ( defined $q->param("Ignore $index") ) {next}
        my $target_well = $q->param("Target Well $index");
        $target_well = uc( format_well($target_well) );

        # if quadrant is specified, convert to 384-well notation
        if ( ( $plate_size =~ /384.*/ ) && ( $rearray_format =~ /96.*/ ) ) {
            my $target_quad = $q->param("Target Quadrant $index");
            if ( $index == 1 ) {
                $prev_quad = $target_quad;
            }
            elsif ( $target_quad eq "''" ) {
                $target_quad = $prev_quad;
            }
            my $wells = &alDente::Well::well_convert( -dbc => $dbc, -wells => "$target_well", -quadrant => $target_quad, -source_size => '96', -target_size => '384' );
            ($target_well) = split ',', $wells;
            $target_well = uc( format_well($target_well) );
            $prev_quad   = $target_quad;
        }
        push( @target_wells, $target_well );
    }
    my $same_plate;
    my @source_plates;
    my @source_wells;
    foreach my $index ( 1 .. $number ) {
        if ( defined $q->param("Ignore $index") ) {
            next;
        }

        my $source_plate = $q->param("ReArray Plate $index");
        if ( $source_plate =~ /''/ ) {
            $source_plate = $same_plate;
        }
        $source_plate = get_aldente_id( $dbc, $source_plate, 'Plate' );    ### in case pla is included, get ID only..
        push @source_plates, $source_plate;
        $same_plate = $source_plate;

        #my $R_primer = $q->param("ReArray Primer $index");
        #if ($R_primer=~/''/) {
        #    $R_primer=$same_primer;
        #}
        #$same_primer=$R_primer;
        my $source_well = $q->param("ReArray Well $index");
        push @source_wells, $source_well;

        #my $T_well = $target_wells[$index-1] || $q->param("Target Well $index") || $R_well;
        #$R_well=format_well($R_well);

        #my $primer_type = 'Standard';
        #if ($R_primer eq 'Custom') {
        #    $primer_type = 'Custom';
        #}
    }
    my $rearray_request;
    if ($target_plate) {
        my $rearray_obj = alDente::ReArray->new( -dbc => $dbc );
        ( $rearray_request, $target_plate ) = $rearray_obj->create_rearray(

            -source_plates    => \@source_plates,
            -source_wells     => \@source_wells,
            -target_wells     => \@target_wells,
            -employee         => $dbc->get_local('user_id'),
            -request_type     => 'Manual Rearray',
            -status           => $status,
            -target_size      => $plate_size,
            -rearray_comments => "Manual ReArray",
            -plate_status     => 'Active',
            -target_plate_id  => $target_plate,
        );
        $rearray_obj->update_plate_sample_from_rearray( -request_id => $rearray_request );
    }
    else {

        my $rearray_obj = alDente::ReArray->new( -dbc => $dbc );
        ( $rearray_request, $target_plate ) = $rearray_obj->create_rearray(
            -target_library   => $library,
            -plate_format     => $plate_format,
            -target_rack      => $rack,
            -pipeline         => $pipeline,
            -source_plates    => \@source_plates,
            -source_wells     => \@source_wells,
            -target_wells     => \@target_wells,
            -employee         => $dbc->get_local('user_id'),
            -request_type     => 'Manual Rearray',
            -status           => $status,
            -target_size      => $plate_size,
            -rearray_comments => "Manual ReArray",
            -plate_status     => 'Active',
            -plate_class      => 'ReArray',
        );
        $rearray_obj->update_plate_sample_from_rearray( -request_id => $rearray_request );
    }
    $dbc->message("ReArray Request $rearray_request created");

    return 1;
}
################################
# upload_qpix_log
# Refactored from Button_Options:  elsif (param('Pick From Qpix')) {
# Associted View: display_utilities_search_page
#
# Return: html page
############################
sub upload_qpix_log {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');
    my $test = $q->param("test");

    if ($test) { return "testing" }

    $dbc->message("upload_qpix_log");

    my $rearray_obj = new alDente::ReArray( -dbc => $dbc );
    my $target_plate = $q->param('Qpix_Target_plate') || '';
    $target_plate = &get_aldente_id( $dbc, $target_plate, 'Plate' );

    #return alDente::ReArray_Views::get_qpix_log_files(-dbc=>$dbc,-target_plate=>$target_plate,-logfile_dir=>"$qpix_log_dir/Qpix3");
    my @qpix_log_dir = $dbc->Table_find( 'Machine_Default', 'Local_Data_dir', "WHERE Host like 'qpix%'" );
    return alDente::ReArray_Views::get_qpix_log_files( -dbc => $dbc, -target_plate => $target_plate, -logfile_dir => \@qpix_log_dir );

}

sub confirm_qpix_log {
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');
    my $test = $q->param("test");

    if ($test) { return "testing" }

    $dbc->message("Confirming rearray");
    my $target_plate  = $q->param('Target_Plate');
    my @source_plates = $q->param('Source_Plates');
    my @source_wells  = $q->param('Source_Wells');
    my @target_wells  = $q->param('Target_Wells');
    my @logfiles      = $q->param('Logfiles');
    my $rearray_obj   = new alDente::ReArray( -dbc => $dbc );
    $rearray_obj->confirm_qpix_log_rearray(
        -target_plate  => $target_plate,
        -source_plates => \@source_plates,
        -source_wells  => \@source_wells,
        -target_wells  => \@target_wells,
        -logfiles      => \@logfiles
    );
}

################################
# upload_yield_report
# Refactored from Button_Options:  elsif (param('Upload Yield Report')) {
# Associted View: display_utilities_search_page
#
# Return: html page
############################
sub upload_yield_report {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');
    my $test = $q->param("test");

    if ($test) { return "testing" }

    $dbc->message("upload_yield_report");

    my $report_fh      = $q->param('Yield Report');
    my $report_type    = $q->param('Yield Report Type');
    my $suppress_print = $q->param('Suppress_Print');
    use alDente::Primer_Plate;
    my $seq_rearray_obj = alDente::Primer_Plate->new( -dbc => $dbc );
    $seq_rearray_obj->process_yield_report( -fh => $report_fh, -type => $report_type, -suppress_print => $suppress_print );

    return '';
}

################################
# rearray_summary
# Refactored from Button_Options:  elsif (param('Rearray Summary')) {
# Associted View: display_utilities_search_page
#
# Return: html page
############################
sub rearray_summary {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $since_date          = $q->param("Rearray From Date") || &date_time('-30d');
    my $library             = $q->param('Summary Library');
    my $exclude_library     = $q->param('Exclude Summary Library');
    my $filter_nonsequenced = $q->param("Remove Nonsequenced Transfers");
    my $output              = alDente::ReArray_Views::rearray_summary( -dbc => $dbc, -since_date => $since_date, -library => $library, -exclude_library => $exclude_library, -remove_transfers => $filter_nonsequenced );

    return $output;
}

sub rearray_locations {
    my $self             = shift;
    my %args             = &filter_input( \@_ );
    my $q                = $self->query;
    my $dbc              = $self->param('dbc');
    my @rearray_requests = $q->param('Request_ID');
    my $rearray_requests = Cast_List( -list => \@rearray_requests, -to => 'String' );
    my $locations        = alDente::ReArray_Views::view_rearray_locations( -request => $rearray_requests, -dbc => $dbc );
    return $locations;
}

sub rearray_grouped_locations {
    my $self             = shift;
    my %args             = &filter_input( \@_ );
    my $q                = $self->query;
    my $dbc              = $self->param('dbc');
    my @rearray_requests = $q->param('Request_ID');
    my $rearray_requests = Cast_List( -list => \@rearray_requests, -to => 'String' );
    my $locations        = alDente::ReArray_Views::view_rearray_locations( -request => $rearray_requests, -dbc => $dbc, -group_all => 1 );
    return $locations;
}

################################
# view_primer_plates
# Refactored from Button_Options:  elsif (param('View Primer Plates')) {
# Associted View: display_utilities_search_page
#
# Return: html page
############################
sub view_primer_plates {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');
    my $test = $q->param("test");

    if ($test) { return "testing" }

    #Message("view_primer_plates");

    require alDente::Primer;
    my $primer_status    = $q->param("Primer Plate Status");
    my $from_date        = $q->param("Primer From Date");
    my $notes            = $q->param("Primer Notes");
    my $primer_type      = $q->param("Primer Types");
    my $primer_plate_ids = $q->param("Primer Plate ID");
    my $solution_ids     = $q->param("Primer Plate Solution ID");
    my $button_options   = $q->param("button options");
    my $extra_condition;
    $extra_condition = " Primer_Plate_Status <> 'Canceled' " if ( $q->param("Exclude Canceled Orders") eq 'on' );

    $solution_ids = get_aldente_id( $dbc, $solution_ids, 'Solution' );
    my $primer_obj = new alDente::Primer( -dbc => $dbc );
    $primer_obj->view_primer_plates(
        -button_options            => $button_options,
        -primer_plate_ids          => $primer_plate_ids,
        -primer_plate_solution_ids => $solution_ids,
        -primer_status             => $primer_status,
        -from_order_date           => $from_date,
        -notes                     => $notes,
        -type                      => $primer_type,
        -extra_condition           => $extra_condition
    );

    return '';
}

sub primer_plate_summary {
    my $self         = shift;
    my %args         = &filter_input( \@_ );
    my $q            = $self->query;
    my $dbc          = $self->param('dbc');
    my @rearray_reqs = $q->param('Request_ID');
    return alDente::ReArray_Views::view_rearray_primer_plates( -rearray_ids => \@rearray_reqs, -dbc => $dbc );

}

sub source_plate_count {
    my $self         = shift;
    my %args         = &filter_input( \@_ );
    my $q            = $self->query;
    my $dbc          = $self->param('dbc');
    my @rearray_reqs = $q->param('Request_ID');
    return alDente::ReArray_Views::view_source_plate_count( -rearray_ids => \@rearray_reqs, -dbc => $dbc );

}

sub source_primer_plate_count {
    my $self         = shift;
    my %args         = &filter_input( \@_ );
    my $q            = $self->query;
    my $dbc          = $self->param('dbc');
    my @rearray_reqs = $q->param('Request_ID');
    return alDente::ReArray_Views::view_primer_plate_count( -rearray_ids => \@rearray_reqs, -dbc => $dbc );

}
################################
# set_primer_plate_well_status
# Refactored from Button_Options:  elsif (param('Set Primer_Plate Well Status')) {
# Associted View: display_utilities_search_page
#
# Return: html page
############################
sub set_primer_plate_well_status {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    $dbc->message("set_primer_plate_well_status");

    require alDente::Primer;
    my $solutions  = $q->param('Primer Plate Solution ID');
    my $sol_ids    = Cast_List( -list => get_aldente_id( $dbc, $solutions, 'Solution' ), -to => 'string' );
    my $primer_obj = new alDente::Primer( -dbc => $dbc );
    $primer_obj->display_primer_wells( -primer_plate_solution => $sol_ids, -dbc => $dbc );

    return '';
}

sub complete_rearray {
    my $self             = shift;
    my $q                = $self->query;
    my $dbc              = $self->param('dbc');
    my @rearray_requests = $q->param('Request_ID');
    my $rearray_obj      = new alDente::ReArray( -dbc => $dbc );

    if ( !@rearray_requests ) { return "No ReArray Requests" }

    $rearray_obj->complete_rearray( -rearray_requests => \@rearray_requests );
}

sub abort_rearray {
    my $self             = shift;
    my $q                = $self->query;
    my $dbc              = $self->param('dbc');
    my @rearray_requests = $q->param('Request_ID');
    my $rearray_obj      = new alDente::ReArray( -dbc => $dbc );

    if ( !@rearray_requests ) { return "No ReArray Requests" }

    $rearray_obj->abort_rearray( -rearray_requests => \@rearray_requests );
}

sub apply_rearrays {
    my $self             = shift;
    my $q                = $self->query;
    my @rearray_requests = $q->param('Request_ID');
    my $dbc              = $self->param('dbc');
    $dbc->message("Applying rearrays");

    # if format is undefined, show an error and return to main rearray page
    # if rack is undefined, show an error and return to main rearray page
    my $rack_id = get_Table_Param( -field => 'FK_Rack__ID', -dbc => $dbc );

    # parse out parameters
    my $plate_size   = $q->param('Plate_Size');
    my $plate_format = get_Table_Param( -field => 'FK_Plate_Format__ID', -dbc => $dbc );
    my $rack         = '';
    my $status       = $q->param('Plate Status') || 'Active';

    my $quadrant = $q->param('Quadrant');
    my $library  = get_Table_Param( -field => "FK_Library__Name", -dbc => $dbc );
    my $created  = $q->param("Plate_Created");
    my $location = $q->param("Location");
    my $pipeline = get_Table_Param( -field => 'FK_Pipeline__ID', -dbc => $dbc );

    # error check for applying rearrays
    if ( $pipeline !~ /.+/ ) {

        #$dbc->error("Pipeline Not Defined!");
        $dbc->error("Pipeline Not Defined");
        return;
    }

    $rack     = $dbc->get_FK_ID( "FK_Rack__ID",     $rack_id );
    $pipeline = $dbc->get_FK_ID( "FK_Pipeline__ID", $pipeline );
    if ( $plate_format !~ /.+/ ) {

        #$dbc->error("Plate Format Not Defined!");
        $dbc->message("Plate format not defined");
        return;
    }
    elsif ( $rack_id !~ /.+/ ) {

        #$dbc->error("Plate Location Not Defined!");
        $dbc->message("Error: Location not defined");
        return;
    }

    my $rearray_obj = new alDente::ReArray( -dbc => $dbc );
    $rearray_obj->apply_rearrays(
        -request_ids  => \@rearray_requests,
        -size         => $plate_size,
        -format       => $plate_format,
        -rack         => $rack,
        -status       => $status,
        -quadrant     => $quadrant,
        -library      => $library,
        -created_date => $created,
        -location     => $location,
        -pipeline     => $pipeline
    );

}

sub group_into_lab_request {
    my $self         = shift;
    my %args         = &filter_input( \@_ );
    my $q            = $self->query;
    my $dbc          = $self->param('dbc');
    my @rearray_reqs = $q->param('Request_ID');
    my $rearray_obj  = new alDente::ReArray( -dbc => $dbc );
    my $employee     = $dbc->get_local('user_id');

    $rearray_obj->add_to_lab_request( -request_ids => \@rearray_reqs, -employee_id => $employee );
}

################################
# generate_dna_multiprobe
# Refactored from Button_Options:  elsif (param('Rearray Action'), $option eq "Generate DNA Multiprobe") {
# Associted View: view_rearrays
#
# Return: html page
############################
sub generate_dna_multiprobe {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    $dbc->message("generate_dna_multiprobe");
    my $output;
    my @rearray_reqs = $q->param('Request_ID');
    my $rearray_obj  = new alDente::ReArray( -dbc => $dbc );
    my @type_list    = $dbc->Table_find( "ReArray_Request", "ReArray_Type", "WHERE ReArray_Request_ID in (" . join( ',', @rearray_reqs ) . ")" ) if @rearray_reqs;
    @type_list = @{ &unique_items( \@type_list ) };

    #require Sequencing::Multiprobe;
    if ( ( scalar(@type_list) == 1 ) && ( $type_list[0] eq 'Reaction Rearray' ) ) {
        my $id_list = join( ',', @rearray_reqs );

        #&Sequencing::Multiprobe::prompt_multiprobe_limit(-dbc=>$dbc, -rearray_id => $id_list, -type => "DNA" );
        $output = &alDente::ReArray_Views::prompt_multiprobe_limit( -dbc => $dbc, -rearray_id => $id_list, -type => "DNA" );
    }
    else {
        $dbc->message('Can only generate Multiprobe control files for Reaction rearrays');
    }
    return $output;
}

################################
# generate_custom_primer_multiprobe
# Refactored from Button_Options:  elsif (param('Rearray Action'), $option eq "Generate Custom Primer Multiprobe") {
# Associted View: view_rearrays
#
# Return: html page
############################
sub generate_custom_primer_multiprobe {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    $dbc->message("generate_custom_primer_multiprobe");
    my $output;
    my @rearray_reqs = $q->param('Request_ID');
    my @type_list = $dbc->Table_find( "ReArray_Request", "ReArray_Type", "WHERE ReArray_Request_ID in (" . join( ',', @rearray_reqs ) . ")" );
    @type_list = @{ &unique_items( \@type_list ) };

    #require Sequencing::Multiprobe;
    if ( ( scalar(@type_list) == 1 ) && ( $type_list[0] eq 'Reaction Rearray' ) ) {
        my $id_list = join( ',', @rearray_reqs );

        #&Sequencing::Multiprobe::prompt_multiprobe_limit(-dbc=>$dbc, -rearray_id=>$id_list,-type=>"Primer");
        $output = &alDente::ReArray_Views::prompt_multiprobe_limit( -dbc => $dbc, -rearray_id => $id_list, -type => "Primer" );
    }
    else {
        $dbc->message('Can only generate Multiprobe control files for Oligo rearrays');
    }

    return $output;
}

################################
# generate_multiprobe
# Refactored from Button_Options:  elsif (param('Generate Multiprobe')) {
# Associted View: prompt_multiprobe_limit
#
# Return: html page
############################
sub generate_multiprobe {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    $dbc->message("generate_multiprobe");

    #require Sequencing::Multiprobe;
    require Plugins::Equipment::Multiprobe;
    my $rearray_ids      = $q->param("Rearray ID");
    my $primer_plate_ids = $q->param("Primer Plate ID");
    my $type             = $q->param("Multiprobe Type");
    my $limit            = $q->param("SourceLimit");

    my $multiprobe_obj = new Plugins::Equipment::Multiprobe( -dbc => $dbc );
    if ($rearray_ids) {
        foreach my $rearray_id ( split( ',', $rearray_ids ) ) {

            #&Sequencing::Multiprobe::write_multiprobe_file(-dbc=>$dbc,-rearray_id=>$rearray_id,-type=>$type,-plate_limit=>$limit);
            $multiprobe_obj->generate_multiprobe_file_for_plate( -dbc => $dbc, -rearray_id => $rearray_id, -type => $type, -plate_limit => $limit );
        }
    }
    elsif ($primer_plate_ids) {
        foreach my $primer_plate_id ( split( ',', $primer_plate_ids ) ) {

            #&Sequencing::Multiprobe::write_multiprobe_file( -dbc => $dbc, -primer_plate_id => $primer_plate_id, -type => $type, -plate_limit => $limit );
            $multiprobe_obj->generate_multiprobe_file_for_primer_plate( -dbc => $dbc, -primer_plate_ids => $primer_plate_id, -type => $type, -plate_limit => $limit );
        }
    }
    else {
        $dbc->error("No Rearray or Primer Plate IDs defined");
    }

    return '';
}

################################
# regenerate_qpix_file
# Refactored from Button_Options:  elsif (param('Rearray Action'), $option eq "Regenerate QPIX File") {
# Associted View: view_rearrays
#
# Return: html page
############################
sub regenerate_qpix_file {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    $dbc->message("regenerate_qpix_file");
    my $output;

    my @rearray_reqs = $q->param('Request_ID');
    my @type_list = $dbc->Table_find( "ReArray_Request", "ReArray_Type", "WHERE ReArray_Request_ID in (" . join( ',', @rearray_reqs ) . ")" );
    @type_list = @{ &unique_items( \@type_list ) };

    if ( !( ( scalar(@type_list) == 1 ) && ( $type_list[0] =~ /Clone/ ) ) ) {
        $dbc->message('Can only generate QPIX control files for Clone rearrays');
    }
    else {
        my $rearray_ids = join( ',', @rearray_reqs );

        # check if the rearrays all exist, and they are all clone rearrays.
        # if they are, generate the qpix layout. Otherwise, go back to original qpix
        my @resultset = $dbc->Table_find( "ReArray_Request", "ReArray_Request_ID,ReArray_Type", "WHERE ReArray_Request_ID in ($rearray_ids)" );
        my $ok_to_generate = 1;
        foreach my $row (@resultset) {
            my ( $id, $type ) = split ',', $row;
            if ( $type !~ /Clone/ ) {
                $dbc->message("ReArray Request $id is not a Clone rearray");
                $ok_to_generate = 0;
                last;
            }
        }
        if ($ok_to_generate) {

            #require Sequencing::QPIX;
            #&Sequencing::QPIX::prompt_qpix_options(-dbc=>$dbc,-request=>$rearray_ids);
            $output = &alDente::ReArray_Views::prompt_qpix_options( -dbc => $dbc, -request => $rearray_ids );
        }
    }

    return $output;
}

################################
# write_to_qpix_file
# Refactored from Button_Options:  elsif (param('Write to File')) {
# Associted View: view_rearrays
#
# Return: html page
############################
sub write_to_qpix_file {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    $dbc->message("write_to_qpix_file");

    my @rearrays           = $q->param('Request_ID');
    my $split_files        = $q->param('Split Files');
    my $filetype           = $q->param("Filetype");
    my $split_quad         = $q->param("Split Quadrant");
    my $split_source_plate = $q->param('Number_Of_Source_Plates');

    #require Sequencing::QPIX;
    require Plugins::Equipment::QPIX;
    my $qpix_obj = new Plugins::Equipment::QPIX();

    foreach my $rearray_req (@rearrays) {

        #&Sequencing::QPIX::write_qpix_to_disk(-dbc=>$dbc,-plate_limit=>$split_source_plate,-type=>$filetype,-rearray_ids=>$rearray_req,-split_quadrant=>$split_quad,-split_files=>$split_files);
        #&Sequencing::QPIX::view_qpix_rack(-dbc=>$dbc,-request=>$rearray_req,-split_quadrant=>$split_quad,-plate_limit=>$split_source_plate);
        $qpix_obj->Plugins::Equipment::QPIX::write_qpix_to_disk( -dbc => $dbc, -plate_limit => $split_source_plate, -type => $filetype, -rearray_ids => $rearray_req, -split_quadrant => $split_quad, -split_files => $split_files );
        $qpix_obj->Plugins::Equipment::QPIX::view_qpix_rack( -dbc => $dbc, -request => $rearray_req, -split_quadrant => $split_quad, -plate_limit => $split_source_plate );
    }

    return '';
}

################################
# show_qpix_rack
# Refactored from Button_Options:  elsif (param('Rearray Action'), $option eq "Show QPIX Rack") {
# Associted View: view_rearrays
#
# Return: html page
############################
sub show_qpix_rack {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    $dbc->message("show_qpix_rack");

    my @rearray_reqs = $q->param('Request_ID');
    my @type_list = $dbc->Table_find( "ReArray_Request", "ReArray_Type", "WHERE ReArray_Request_ID in (" . join( ',', @rearray_reqs ) . ")" );
    @type_list = @{ &unique_items( \@type_list ) };

    unless ( ( scalar(@type_list) == 1 ) && ( $type_list[0] =~ /Clone/ ) ) {
        $dbc->message('Can only view QPIX racks for Clone rearrays');
    }
    my $rearray_ids = join( ',', @rearray_reqs );
    my $split_quad  = $q->param("Split Quadrant");
    my $plate_limit = $q->param("Max_Plates_Per_Rack");
    require Plugins::Equipment::QPIX;
    my $qpix_obj = new Plugins::Equipment::QPIX();
    $qpix_obj->Plugins::Equipment::QPIX::view_qpix_rack( -dbc => $dbc, -request => $rearray_ids, -split_quadrant => $split_quad, -plate_limit => $plate_limit );

    return '';
}

################################
# create_remapped_custom_primer_plate
# Refactored from Button_Options:  elsif (param('Rearray Action'), $option eq "Show QPIX Rack") {
# view_rearrays
#
# Return: html page
############################
sub create_remapped_custom_primer_plate {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    $dbc->message("Create Remapped Custom Primer Plate");

    my @rearray_reqs = $q->param('Request_ID');
    @rearray_reqs = @{ &unique_items( \@rearray_reqs ) };
    my @type_list = $dbc->Table_find( "ReArray_Request", "ReArray_Type", "WHERE ReArray_Request_ID in (" . join( ',', @rearray_reqs ) . ")" );
    @type_list = @{ &unique_items( \@type_list ) };
    my $rearray_obj = new alDente::ReArray( -dbc => $dbc );

    if ( ( scalar(@type_list) == 1 ) && ( $type_list[0] eq 'Reaction Rearray' ) ) {
        my $confirm = $q->param('Confirm');
        if ( !($confirm) ) {
            &alDente::ReArray_Views::confirm_remap_primer_plate( -dbc => $dbc, -rearray_ids => \@rearray_reqs );
        }
        else {
            foreach my $id (@rearray_reqs) {
                my $primer_plate_name = $q->param("Primer_Plate_Name_${id}");
                my $notes             = $q->param("Notes_${id}");
                $rearray_obj->remap_primer_plate_from_rearray( -rearray_id => $id, -primer_plate_name => $primer_plate_name, -notes => $notes );
            }
        }
    }
    else {
        $dbc->message('Can only remap Reaction rearrays');
    }

    return '';
}

sub rearray_map {
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');
    my $ID   = $q->param('ID');

    &alDente::ReArray_Views::display_rearray_map( -dbc => $dbc, -request_id => $ID );
}

sub rearray_wells {
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');
    my $test = $q->param("test");

    if ($test) { return "testing" }

    #<CONSTRUCTION> this should be in ReArray_Views
    alDente::Library_Plate::parse_rearray_wells();
}

sub pool_to_tube_by_rows {
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    $dbc->message('Pooling selected wells from each row into tube');

    my $format_id = $q->param('Target Plate Format');
    $format_id = $dbc->get_FK_ID( 'FK_Plate_Format__ID', $format_id );
    my ($Plate_Format_Style) = $dbc->Table_find( 'Plate_Format', 'Plate_Format_Type', "WHERE Plate_Format_ID = $format_id" );
    if ( $Plate_Format_Style ne 'Tube' ) { $dbc->message('Only can pool to tube, please go back and choose the right format'); return '' }
    my $source_plate_id   = $q->param('source_plates');
    my $target_plate_size = $q->param('Target_Plate_Size');
    my $library           = &SDB::HTML::get_Table_Param( -table => 'Library', -field => 'FK_Library__Name', -dbc => $dbc );
    $library = $dbc->get_FK_ID( 'FK_Library__Name', $library );

    my ($sample_type_id) = $dbc->Table_find( 'Plate', 'FK_Sample_Type__ID', "WHERE Plate_ID IN ($source_plate_id)" );

    my ($Wells) = $dbc->Table_find( 'Plate,Plate_Format', 'Wells', "WHERE Plate_ID IN ($source_plate_id) and FK_Plate_Format__ID = Plate_Format_ID " );

    my @plates;
    my $rearray = alDente::ReArray->new( -dbc => $dbc );
    my $Well = &alDente::ReArray::nextwell( undef, $Wells, 'Row' );
    my $preWell;
    my @row;
    ##Use nextwell to get all the wells from a row
    for my $count ( 1 .. $Wells ) {
        push @row, $Well;
        $preWell = $Well;
        $Well = &alDente::ReArray::nextwell( $Well, $Wells, 'Row' );

        my $wellrow = $Well;
        $wellrow =~ s/^(.).*/$1/;
        if ( $preWell !~ /$wellrow/ ) {

            #Got all the wells from a single row

            #do single row of selected wells one at a time
            my @rearray_source_wells = $q->param('Wells');
            @rearray_source_wells = map { uc( format_well("$_") ) } @rearray_source_wells;
            @rearray_source_wells = sort @{ &set_operations( \@rearray_source_wells, \@row, 'intersect' ) };

            if (@rearray_source_wells) {
                my $plate
                    = $rearray->pool_to_tube( -format_id => $format_id, -library => $library, -source_plate_id => $source_plate_id, -target_plate_size => $target_plate_size, -sample_type_id => $sample_type_id, -source_wells => \@rearray_source_wells );
                push @plates, $plate;
            }

            #reset
            @row = ();
        }
    }

    if (@plates) {
        my $id_list = join ',', @plates;
        my $plate = new alDente::Container( -dbc => $dbc, -id => $id_list );
        return $plate->View->std_home_page( -id => $id_list );
    }
}

#################
sub pool_to_single_tube {
#################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    $dbc->message('Pooling selected wells into a tube');

    my $format_id = $q->param('Target Plate Format');
    $format_id = $dbc->get_FK_ID( 'FK_Plate_Format__ID', $format_id );
    my ($Plate_Format_Style) = $dbc->Table_find( 'Plate_Format', 'Plate_Format_Type', "WHERE Plate_Format_ID = $format_id" );
    if ( $Plate_Format_Style ne 'Tube' ) { $dbc->message('Only can pool to tube, please go back and choose the right format'); return '' }
    my $source_plate_id   = $q->param('source_plates');
    my $target_plate_size = $q->param('Target_Plate_Size');
    my $library           = &SDB::HTML::get_Table_Param( -table => 'Library', -field => 'FK_Library__Name', -dbc => $dbc );
    $library = $dbc->get_FK_ID( 'FK_Library__Name', $library );

    my ($sample_type_id) = $dbc->Table_find( 'Plate', 'FK_Sample_Type__ID', "WHERE Plate_ID IN ($source_plate_id)" );

    my ($Wells) = $dbc->Table_find( 'Plate,Plate_Format', 'Wells', "WHERE Plate_ID IN ($source_plate_id) and FK_Plate_Format__ID = Plate_Format_ID " );

    my $rearray = alDente::ReArray->new( -dbc => $dbc );
    my @rearray_source_wells = $q->param('Wells');
    @rearray_source_wells = map { uc( format_well("$_") ) } @rearray_source_wells;

    my $plate;
    if (@rearray_source_wells) {
        $plate = $rearray->pool_to_tube( -format_id => $format_id, -library => $library, -source_plate_id => $source_plate_id, -target_plate_size => $target_plate_size, -sample_type_id => $sample_type_id, -source_wells => \@rearray_source_wells );
    }

    if ($plate) {
        $plate = new alDente::Container( -dbc => $dbc, -id => $plate );
        return $plate->View->std_home_page( -id => $plate );
    }
}

################################
sub generate_rearray_csv {
################################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my @rearray_req_ids = $q->param('Request_ID');

    if ( scalar @rearray_req_ids == 0 ) {
        $dbc->error("Nothing selected, go back and select with checkbox");
        return 0;
    }

    #my $reqest_id = @rearray_req_ids[0];
    #Message("$reqest_id");

    my $rearray  = alDente::ReArray->new( -dbc                  => $dbc );
    my $info     = $rearray->generate_span8_csv( -request_id    => \@rearray_req_ids );
    my $linkname = $rearray->generate_span8_instructions( -info => $info );

    #print HTML_Dump \%info;

    my $page = alDente::ReArray_Views::span8_csv_views( -dbc => $dbc, -info => $info, -linkname => $linkname );

    return $page;
}

#########################################
sub _replace_scanned_box_with_contents {
#########################################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc} || $self->dbc();
    my $barcode = $args{-barcode};
    my $type    = $args{-type};

    my $box = get_aldente_id( $dbc, $barcode, 'Rack' );
    if ( $box && $type ) {
        ## If Boxes are included, include all Plates within Box ##
        my $Rack = new alDente::Rack( -dbc => $dbc );
        foreach my $b ( split ',', $box ) {
            my $box_content = $Rack->get_box_content( -id => $b );
            my $include_plates = $box_content->{$type};
            if ( $include_plates && @$include_plates ) {
                my $add = join "$Prefix{Plate}", @$include_plates;
                $barcode =~ s/$Prefix{Rack}$b([a-z]|\b|$)/$Prefix{$type}$add$1/ig;
            }
        }
    }

    return $barcode;
}

#################
sub pool_wells {
#################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $source_plates = $q->param('ReArrayed From');
    my $target_size   = $q->param('Plate Size');
    my $hybrid        = $q->param('Hybrid');
    my $transfer      = $q->param('Transfer');

    $source_plates = $self->_replace_scanned_box_with_contents( -type => 'Plate', -barcode => $source_plates );    ## allow user to scan in Box (Rack_ID) instead of all tubes inside...

    my @plates;

    #Adjust plate_id for trays
    if ( $source_plates =~ /$Prefix{Tray}/i ) {
        my @trays = split( /($Prefix{Tray})/i, $source_plates );
        my $additional = shift @trays;
        for ( my $i = 0; $i <= $#trays; $i++ ) {
            if ( $i % 2 == 1 ) { push @plates, "$trays[$i-1]$trays[$i]" }
        }
        if ( $additional && $additional =~ /$Prefix{Plate}/i ) {
            $additional = &get_aldente_id( $dbc, $additional, 'Plate' );
            my @additional_plates = split( /,/, $additional );
            push @plates, @additional_plates;
        }
    }
    elsif ( $source_plates =~ /$Prefix{Plate}/i ) {
        $source_plates = &get_aldente_id( $dbc, $source_plates, 'Plate' );
        @plates = split( /,/, $source_plates );
    }
    else {
        $source_plates = &extract_range($source_plates);
        @plates = split( /,/, $source_plates );
    }

    # if hybrid is flagged, check Library_Type. Only 'RNA/DNA' is supported currently
    if ($hybrid) {
        my $plate_list = join ',', @plates;
        my @non_RNA_DNA = $dbc->Table_find( 'Plate,Library', 'Plate_ID', "WHERE FK_Library__Name = Library_Name AND Library_Type <> 'RNA/DNA' AND Plate_ID in ($plate_list)" );
        my $count = int(@non_RNA_DNA);
        if ($count) {
            my $list = join ',', @non_RNA_DNA;
            $dbc->error("Sorry, Only RNA/DNA library plates are supported for the Pool/ReArray to Hybrid Library option!");
            $dbc->error("$count plate(s) are NOT RNA/DNA library plate(s): $list");
            return;
        }
    }

    return &alDente::ReArray_Views::pool_wells( -dbc => $dbc, -plate_id => \@plates, -target_size => $target_size, -test => 1, -hybrid => $hybrid, -transfer => $transfer );

}

#################
sub batch_pool_wells {
#################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    $dbc->message("Batch Pool Wells: This will make a rearray for each plate that's scanned in!!!");

    my $source_plates = $q->param('ReArrayed From');
    my $target_size   = $q->param('Plate Size');

    $source_plates = $self->_replace_scanned_box_with_contents( -type => 'Plate', -barcode => $source_plates );    ## allow user to scan in Box (Rack_ID) instead of all tubes inside...

    if ( $source_plates =~ /$Prefix{Plate}/i ) {
        $source_plates = &get_aldente_id( $dbc, $source_plates, 'Plate' );
    }
    else {
        $source_plates = &extract_range($source_plates);
    }

    my @Plate_Format = $dbc->Table_find( "Plate", "FK_Plate_Format__ID", "WHERE Plate_ID IN ($source_plates)", -distinct => 1 );

    if ( @Plate_Format > 1 ) {
        $dbc->error("Can't batch pool wells of different plate formats");
        return;
    }

    my @plates = split( /,/, $source_plates );
    $dbc->message("The same pool wells for $plates[0] will be applied to $source_plates");
    return &alDente::ReArray_Views::pool_wells( -dbc => $dbc, -plate_id => [ $plates[0] ], -target_size => $target_size, -batch => $source_plates );

}

########################################
sub confirm_create_pool_wells_rearray {
########################################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    #Check for well that already pooled before and ask for confirmation if it did
    my $pooled_already = 0;
    my @pool_wells     = $q->param('poolTargetWells');
    my $confirmed      = $q->param('confirmed');
    my $transfer       = $q->param('Transfer');

    if ( !@pool_wells ) { return "No wells to pool" }

    for my $pool_wells (@pool_wells) {
        next if $confirmed;
        my @wells = split( /,/, $pool_wells );
        my @all_check_wells;
        for my $well (@wells) {
            my ( $source_plate, $source_well ) = split( /-/, $well );
            $source_well = uc( format_well($source_well) );
            if ( $source_plate =~ /$Prefix{Tray}/i ) {
                $source_plate =~ s/$Prefix{Tray}//i;
                ($source_plate) = $dbc->Table_find( "Plate_Tray", "FK_Plate__ID", "WHERE FK_Tray__ID = $source_plate AND Plate_Position = '$source_well'" );
            }

            #print HTML_Dump $source_plate, $source_well;
            my $condition = "FKSource_Plate__ID = $source_plate";
            my ($source_plate_type) = $dbc->Table_find( 'Plate', 'Plate_Type', "WHERE Plate_ID IN ($source_plate)" );
            if ( $source_plate_type ne 'Tube' ) { $condition .= " AND Source_Well = '$source_well'"; }
            push @all_check_wells, $condition;
        }
        my $all_conditions = join( " OR ", @all_check_wells );
        my @previous_pools
            = $dbc->Table_find( "ReArray,ReArray_Request", "FKTarget_Plate__ID,FK_ReArray_Request__ID,FKSource_Plate__ID,Source_Well", "WHERE ($all_conditions) AND FK_ReArray_Request__ID = ReArray_Request_ID AND ReArray_Type = 'Pool Rearray'" )
            if $all_conditions;

        #print HTML_Dump \@previous_pools;

        for my $previous_pool (@previous_pools) {
            my ( $target_plate, $rearray_request, $source_plate, $source_well ) = split( ",", $previous_pool );
            $dbc->warning("$source_plate-$source_well already being used to pool in $target_plate (rry$rearray_request)");
            $pooled_already = 1;
        }
    }

    if ( $pooled_already && !$confirmed ) {
        my $output;
        return &alDente::ReArray_Views::confirm_create_pool_wells_rearray_page( -dbc => $dbc, -query => $q );
    }
    else {
        my $pool_to_tube = $q->param('pool to tube');
        my $output;

        $dbc->start_trans('create_pool_wells_rearray');

        #print HTML_Dump $pool_to_tube;
        if ( $pool_to_tube > 1 ) {
            my @pool_wells = $q->param('poolTargetWells');
            my $library = get_Table_Params( -field => 'FK_Library__Name', -dbc => $dbc ) || $q->param('Library_Name');

            #$library = $dbc->get_FK_ID( 'FK_Library__Name', $library );
            #print HTML_Dump $library;
            my @all_target_plates;
            for ( my $i = 0; $i < $pool_to_tube; $i++ ) {

                # $dbc->error/message didn't work properly if this is called within a loop
                my $Bootstrap = new Bootstrap;
                $Bootstrap->message( "Pooling $pool_wells[$i] ...", -print => 1 );

                #print HTML_Dump $pool_wells[$i], $library->[$i];
                my $new_plate = $self->create_pool_wells_rearray( -pooltargetwells => $pool_wells[$i], -library => $library->[$i], -return_plate_id => 1 );
                if ($new_plate) {
                    push @all_target_plates, $new_plate;
                }
                ## pool error occurred
                else {
                    $dbc->rollback_trans( 'create_pool_wells_rearray', -error => "Error pooling wells $pool_wells[$i]" );
                    $Bootstrap->error( "Error pooling $pool_wells[$i]. All the pools have been rolled back. Please discard the printed barcodes if any.", -print => 1 );
                    return;
                }
            }

            my $all_target = join( ",", @all_target_plates );
            my $target_plate_obj = new alDente::Container( -dbc => $dbc, -id => $all_target );
            $output = $target_plate_obj->View->std_home_page( -id => $all_target );
        }
        else {
            $output = $self->create_pool_wells_rearray();
        }

        $dbc->finish_trans('create_pool_wells_rearray');

        return $output;
    }
}

################################
sub create_pool_wells_rearray {
################################
    my $self            = shift;
    my %args            = &filter_input( \@_ );
    my $q               = $self->query;
    my $dbc             = $self->param('dbc');
    my $return_plate_id = $args{-return_plate_id};
    my $transfer        = $q->param('Transfer');
    my $output          = '';
    $dbc->message('Creating Pool Wells ReArray');

    my @pool_wells = $args{-pooltargetwells} || $q->param('poolTargetWells');

    #print HTML_Dump @wells;

    my @source_plates;
    my @rearray_source_wells;
    my @rearray_target_wells;

    my $library = $args{-library} || get_Table_Param( -field => 'FK_Library__Name', -dbc => $dbc ) || $q->param('Library_Name');
    $library = $dbc->get_FK_ID( 'FK_Library__Name', $library );
    my $format_id = get_Table_Param( -field => 'FK_Plate_Format__ID', -dbc => $dbc ) || $q->param('Plate_Format_ID');
    $format_id = $dbc->get_FK_ID( 'FK_Plate_Format__ID', $format_id );
    my $target_rack = get_Table_Param( -field => 'FK_Rack__ID', -dbc => $dbc ) || $q->param('Rack_ID');
    $target_rack = $dbc->get_FK_ID( 'FK_Rack__ID', $target_rack );
    my $pipeline = get_Table_Param( -field => 'FK_Pipeline__ID', -table => 'Plate', -dbc => $dbc ) || $q->param('Pipeline_ID');
    $pipeline = $dbc->get_FK_ID( "FK_Pipeline__ID", $pipeline );

    my $target_plate_size = $q->param('Target_Plate_Size');
    my $sample_type_id    = 1;
    my $plate_type        = 'Library_Plate';
    my $pool_to_tube      = $q->param('pool to tube');
    if ($pool_to_tube) { $plate_type = 'Tube'; }

    my $max_row;
    my $max_col;
    if ( $target_plate_size =~ 96 ) {
        $max_row = 'H';
        $max_col = '12';
    }
    elsif ( $target_plate_size =~ 384 ) {
        $max_row = 'P';
        $max_col = '24';
    }
    else {    #Tube
        $max_row           = 'A';
        $max_col           = '1';
        $target_plate_size = 1;
    }

    #print HTML_Dump \@pool_wells;
    for my $row ( 'A' .. $max_row ) {
        for my $col ( 1 .. $max_col ) {
            my $value = shift @pool_wells;
            my @wells = split( /,/, $value );
            for my $well (@wells) {
                my ( $source_plate, $source_well ) = split( /-/, $well );
                $source_well = uc( format_well($source_well) );
                if ( $source_plate =~ /$Prefix{Tray}/i ) {
                    $source_plate =~ s/$Prefix{Tray}//i;
                    ($source_plate) = $dbc->Table_find( "Plate_Tray", "FK_Plate__ID", "WHERE FK_Tray__ID = $source_plate AND Plate_Position = '$source_well'" );
                }

                my ($source_plate_type) = $dbc->Table_find( 'Plate', 'Plate_Type', "WHERE Plate_ID IN ($source_plate)" );
                if ( $source_plate_type eq 'Tube' ) { $source_well = 'N/A'; }
                my $target_well = "$row$col";
                $target_well = uc( format_well($target_well) );
                if ($pool_to_tube) { $target_well = 'N/A'; }
                push @source_plates,        $source_plate;
                push @rearray_source_wells, $source_well;
                push @rearray_target_wells, $target_well;
            }

            #print "$row$col: $value<br>";
        }
    }

    my @batches;
    my $batch = $q->param('batch');
    if ($batch) { @batches = split( ",", $batch ) }
    else        { push @batches, 1 }

    #$dbc->start_trans('create_pool_rearray');

    my @all_target_plates;
    for my $b (@batches) {
        if ($batch) {
            @source_plates = map {$b} @source_plates;
        }

        #print HTML_Dump \@source_plates, \@rearray_source_wells, \@rearray_target_wells, 'pipeline', $pipeline, 'plate_size', $target_plate_size, 'library', $library, 'format', $format_id, 'target_rack', $target_rack;

        ### The portion of the code is for generating a hybrid library when no libary is specifiy, skip this of a library is given
        ### BEGIN hybrid library processing
        if ( !$library ) {
            ### Generate Hybrid Library automatically if required ###

            # Retrieve conflict handling specification if provided (as per alDente::Form)
            my $on_conflict;
            my @conflict_list = $q->param('Conflict_List');
            foreach my $key (@conflict_list) {
                if ( my $val = $q->param("OC.$key") ) {
                    if ( $dbc->foreign_key_check($key) ) { $val = $dbc->get_FK_ID( $key, $val ) }
                    $on_conflict->{$key} = $val;
                    $dbc->message("Resolved $key conflict: $val");
                }
                else {
                    $dbc->warning("$key conflict still unresolved");
                }
            }

            my %unresolved;
            my $lib = alDente::Container::merge_libs( -dbc => $dbc, -plate_id => \@source_plates, -unresolved => \%unresolved, -on_conflict => $on_conflict );

            if ($lib) {
                $dbc->message("Created Hybrid Library: $lib");
                $library = $lib;
            }
            else {
                $dbc->warning("*** UNRESOLVED CONFLICTS REMAIN ***");
                print alDente::ReArray_Views::pool_wells( -dbc => $dbc, -plate_id => \@source_plates, -target_size => $target_plate_size );
                &main::leave();
            }
        }
        ### END hybrid library processing

        my $rearray = alDente::ReArray->new( -dbc => $dbc );
        my ( $rearray_request, $target_plate ) = $rearray->create_rearray(
            -source_plates    => \@source_plates,
            -source_wells     => \@rearray_source_wells,
            -target_wells     => \@rearray_target_wells,
            -employee         => $dbc->get_local('user_id'),
            -pipeline         => $pipeline,
            -request_type     => "Pool Rearray",
            -request_status   => 'Completed',
            -target_size      => $target_plate_size,
            -create_plate     => 1,
            -rearray_comments => "",
            -target_library   => $library,
            -plate_format     => $format_id,
            -sample_type_id   => $sample_type_id,
            -plate_status     => 'Active',
            -target_rack      => $target_rack,
            -plate_class      => 'ReArray',
            -plate_type       => $plate_type,
        );

        if ($target_plate) {

            my $ok = $rearray->create_pool_sample(
                -dbc                  => $dbc,
                -library              => $library,
                -target_plate         => $target_plate,
                -source_plates        => \@source_plates,
                -rearray_request      => $rearray_request,
                -rearray_source_wells => \@rearray_source_wells,
                -rearray_target_wells => \@rearray_target_wells
            );
            if ( !$ok ) {

                #$dbc->rollback_trans( 'create_pool_rearray', -error => "No pool sample created" );
                return 0;
            }

            if ( $dbc->package_active('Indexed_Run') && !$batch ) {

                #test for duplicate index in the pool
                require Indexed_Run::Indexed_Run;
                my $index_run = new Indexed_Run::Indexed_Run( -dbc => $dbc );
                $index_run->duplicate_index_check( -plate_id => $target_plate );
            }
            print $self->indices_and_other_fields_check( -plate_id => $target_plate );

            if ($batch) {
                my ($info) = $dbc->Table_find( "Plate", "Plate_Label,Plate_Parent_Well", "WHERE Plate_ID = $b" );
                my ( $plate_label, $plate_parent_well ) = split( ",", $info );
                $dbc->Table_update( "Plate", "Plate_Label",       $plate_label,       "WHERE Plate_ID = $target_plate", -autoquote => 1 ) if $plate_label;
                $dbc->Table_update( "Plate", "Plate_Parent_Well", $plate_parent_well, "WHERE Plate_ID = $target_plate", -autoquote => 1 ) if $plate_parent_well;
            }
            alDente::Barcoding::PrintBarcode( $dbc, 'Plate', $target_plate );
            push @all_target_plates, $target_plate;

            if ($transfer) {
                my $container_set = new alDente::Container_Set( -dbc => $dbc );
                my ( $total_quantity, $total_units, $volumes ) = $container_set->_pool_volumes( -ids => \@source_plates, -empty => 1 );

                #update pooled plate's quantity and volume
                $dbc->Table_update_array( 'Plate', [ 'Current_Volume', 'Current_Volume_Units' ], [ $total_quantity, $total_units ], "WHERE Plate_ID = $target_plate", -autoquote => 1 );
            }
        }
    }

    #$dbc->finish_trans('create_pool_rearray');

    my $all_target = join( ",", @all_target_plates );
    my $target_plate_obj = new alDente::Container( -dbc => $dbc, -id => $all_target );

    if ($return_plate_id) {
        $output .= $all_target;
        return $output;
    }
    $output .= $target_plate_obj->View->std_home_page( -id => $all_target );
    return $output;

}

#########################
sub parse_create_rearray {
#########################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $q       = $self->query;
    my $dbc     = $self->param('dbc');
    my $user_id = $dbc->get_local('user_id');

    my @source_wells      = $q->param('Wells');
    my @target_wells      = $q->param('TargetWells');
    my $library           = $q->param('Library');
    my $format_id         = $q->param('Plate_Format');
    my $source_plate_id   = $q->param('Source_Plate');
    my $target_plate_size = $q->param('Target_Plate_Size');
    my $existing_plate    = $q->param('Existing_Plate');
    my $target_plate;

    my $target_rack = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Name='Temporary'" );

    print alDente::Form::start_alDente_form( $dbc, );

    my @rearray_source_wells = ();
    my @rearray_target_wells = ();
    my $source_index         = 0;
    foreach my $source_well (@source_wells) {
        if ( $source_well =~ /\w\d+/i ) {
            push( @rearray_source_wells, uc( format_well("$source_well") ) );
            push( @rearray_target_wells, uc( format_well("$target_wells[$source_index]") ) );

        }
        $source_index++;
    }
    my @source_plates = ($source_plate_id) x scalar(@rearray_source_wells);
    my $status        = 'Completed';
    my $target_size;
    my $rearray_comments = "";

    #     my $plate_application = $dbc->Table_find('Plate','Plate_Application',"WHERE Plate_ID = $source_plate_id");
    my ($sample_type_id) = $dbc->Table_find( 'Plate', 'FK_Sample_Type__ID', "WHERE Plate_ID IN ($source_plate_id)" );
    my $Plate_Format_Style;
    my $existing_plate = get_aldente_id( $dbc, $existing_plate, 'Plate' );
    if   ($existing_plate) { ($Plate_Format_Style) = $dbc->Table_find( 'Plate_Format,Plate', 'Plate_Format_Type', "WHERE FK_Plate_Format__ID = Plate_Format_ID AND Plate_ID IN ($source_plate_id)" ); }
    else                   { ($Plate_Format_Style) = $dbc->Table_find( 'Plate_Format',       'Plate_Format_Type', "WHERE Plate_Format_ID = $format_id" ); }

    my $rearray_request;
    my $type = 'Manual Rearray';

    require alDente::ReArray;
    my $rearray = alDente::ReArray->new( -dbc => $dbc );

    if ($existing_plate) {

        $target_size = $dbc->Table_find( 'Plate', 'Plate_Size', "WHERE Plate_ID = $existing_plate" );
        ( $rearray_request, $target_plate ) = $rearray->create_rearray(
            -source_plates    => \@source_plates,
            -source_wells     => \@rearray_source_wells,
            -target_wells     => \@rearray_target_wells,
            -target_plate_id  => $existing_plate,
            -employee         => $user_id,
            -request_type     => $type,
            -status           => $status,
            -target_size      => $target_size,
            -rearray_comments => $rearray_comments,
            -target_library   => $library,
            -plate_format     => $format_id,
            -sample_type_id   => $sample_type_id,
            -plate_status     => 'Active',
            -create_plate     => 0,
            -plate_class      => 'ReArray'
        );
        $target_plate = $existing_plate;
    }
    else {
        my $plate_type;
        if ( $Plate_Format_Style eq 'Tube' ) {
            $plate_type           = 'Tube';
            @rearray_source_wells = $q->param('Selected_Wells');
            @rearray_source_wells = map { uc( format_well("$_") ) } @rearray_source_wells;
            @rearray_target_wells = ('N/A') x scalar(@rearray_source_wells);
            @source_plates        = ($source_plate_id) x scalar(@rearray_source_wells);
            $type                 = 'Pool Rearray';
        }

        ( $rearray_request, $target_plate ) = $rearray->create_rearray(
            -source_plates    => \@source_plates,
            -source_wells     => \@rearray_source_wells,
            -target_wells     => \@rearray_target_wells,
            -employee         => $user_id,
            -request_type     => $type,
            -status           => $status,
            -target_size      => $target_plate_size,
            -create_plate     => 1,
            -rearray_comments => $rearray_comments,
            -target_library   => $library,
            -plate_format     => $format_id,
            -sample_type_id   => $sample_type_id,
            -plate_status     => 'Active',
            -target_rack      => $target_rack,
            -plate_class      => 'ReArray',
            -plate_type       => $plate_type,
        );
        if ($target_plate) { alDente::Barcoding::PrintBarcode( $dbc, 'Plate', $target_plate ); }
    }

    my $pool = 0;
    if ( $Plate_Format_Style eq 'Tube' ) {
        $pool = 1;
        my ($new_sample_type) = $dbc->Table_find( 'Plate,Sample_Type', 'Sample_Type', "WHERE Plate_ID IN ($source_plate_id) AND FK_Sample_Type__ID = Sample_Type_ID" );
        my @source_ids
            = $dbc->Table_find( "Plate,Plate_Sample,Sample", "FK_Source__ID", "WHERE Plate.FKOriginal_Plate__ID=Plate_Sample.FKOriginal_Plate__ID AND FK_Sample__ID=Sample_ID AND Plate_ID in ($source_plate_id) AND FK_Source__ID <> 0", -distinct => 1 );

        if ( int(@source_ids) > 1 ) {
            $dbc->warning("Multiple samples identified!!!!");
        }
        elsif ( int(@source_ids) < 1 ) {
            $dbc->message("No source ids identified");
        }

        my $ok = alDente::Sample::create_samples( -dbc => $dbc, -source_id => $source_ids[0], -type => $new_sample_type, -plate_id => $target_plate );
    }

    $rearray->update_plate_sample_from_rearray( -request_id => $rearray_request, -pool => $pool );

    if ($target_plate) {
        require alDente::Info;
        alDente::Info::GoHome( $dbc, 'Container', $target_plate );
    }
    print $q->end_form();

}

####################################
# Do batch pooling
#
# Return: HTML
#
####################################
sub upload_batch_pooling_sources {
####################################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $self->param('dbc');
    my $q     = $self->query;
    my $debug = $args{-debug};

    my $filename   = $q->param('input_file_name');
    my $srouce_ids = $q->param('Pool_Source_ID');
    my %batches;

    if ( !$filename && !$srouce_ids ) { $dbc->message("No input sources for pooling!"); return $self->search_page() }

    require SDB::Import;
    my ( $headers, $data );
    my $Import = new SDB::Import( -dbc => $dbc );

    if ( $filename =~ /\.xls$/ ) {
        my $local_filename;
        if ( ref $filename eq 'Fh' ) {
            ## archive uploaded file locally ##
            $local_filename = LampLite::File->archive_data_file( -filehandle => $filename, -type => 'xls', -path => $Configs{URL_temp_dir} );
        }
        else { $local_filename = $filename }

        ## parse the data & headers from the excel file ##
        ( $headers, $data ) = $Import->load_excel_data( -file => $local_filename );
        print HTML_Dump "header:", $headers if ($debug);
        print HTML_Dump "data:",   $data    if ($debug);
        if ( $data && @{ $data->{Batch_ID} } ) {
            my $max_i = @{ $data->{Batch_ID} } - 1;
            foreach my $i ( 0 .. $max_i ) {
                my $batch_id = $data->{Batch_ID}[$i];
                my $src_id   = $data->{Source}[$i];
                if ( exists $batches{$batch_id}{src_ids} ) {
                    push @{ $batches{$batch_id}{src_ids} }, $src_id;
                }
                else { $batches{$batch_id}{src_ids} = [$src_id] }
                if ( defined $data->{Amount} ) { $batches{$batch_id}{$src_id}{amnt} = $data->{Amount}[$i] }
                if ( defined $data->{Unit} )   { $batches{$batch_id}{$src_id}{unit} = $data->{Unit}[$i] }
            }
        }
    }
    elsif ($filename) {
        $dbc->message("The input file format is not supported!");
        return $self->search_page();
    }
    require alDente::Source_Views;
    return alDente::Source_Views::pool_sources( -dbc => $dbc, -source_id => $srouce_ids, -batches => \%batches );
}

return 1;
