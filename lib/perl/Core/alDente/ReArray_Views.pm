####################
# ReArray_Views.pm #
####################
#
# This contains various ReArray view pages:
#

package alDente::ReArray_Views;

use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Web_Form;
use RGTools::RGWeb;

use SDB::HTML;
use SDB::DBIO;
use SDB::CustomSettings;

use alDente::Validation;
use alDente::SDB_Defaults;
use alDente::Form;

use CGI qw(:standard);
use alDente::Tools;
use alDente::Tray;
use alDente::Tray_Views;

use vars qw(%Configs %Settings);
my $q  = new CGI;
my $BS = new Bootstrap();
use strict;
############################################
#
# Search page for ReArray (Refactored from Sequencing::ReArray::sequencing_rearray_home)
# Associated run mode: search_page, View ReArray
#
############################################
sub display_search_page {
###########################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $rearray_obj = new alDente::ReArray( -dbc => $dbc );

    my $output;
    $output = alDente::Form::start_alDente_form( -dbc => $dbc, -name => "Rearray_Search" );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App' );

    ### search options table

    # init date search
    my $date_spec = "";

    $date_spec = &display_date_field( -field_name => "date_range", -default => '', -quick_link => [ 'Today', '7 days', '1 month' ], -range => 1, -linefeed => 1 );

    # init library search
    # get all libraries

    my $library_spec = "<B> Library: </B>" 
        . lbr()
        . alDente::Tools::search_list(
        -dbc            => $dbc,
        -name           => 'Library.Library_Name',
        -default        => '',
        -search         => 1,
        -filter         => 1,
        -breaks         => 1,
        -width          => 390,
        -filter_by_dept => 1,
        -mode           => 'Scroll'
        );

    # init target plate ID search
    my $plateid_spec = '<B>Plate ID:</B><BR>' . textfield( -name => 'Target Plates', -size => 20 );

    # init employee search
    my @emp_array = $dbc->Table_find( "Employee,ReArray_Request", "distinct Employee_Name", "WHERE FK_Employee__ID=Employee_ID" );
    unshift( @emp_array, '-' );
    my $employee_spec = '<B>Requester:</B><BR>' . popup_menu( -name => 'Employee', -values => \@emp_array );

    # init rearray id search
    my $request_spec = '<B>Request IDs:</B><BR>' . textfield( -name => 'Request IDs', -size => 20, -force => 1 );

    # init plate number search
    my $platenum_spec = '<B>Plate Number:</B><BR>' . textfield( -name => 'Plate Number', -size => 20 );

    # init rearray status search
    # grab statuses from table
    my $status = $rearray_obj->get_rearray_request_status_list();
    unshift( @$status, '' );
    my $status_spec = '<B>Rearray Status:</B><BR>'
        . Show_Tool_Tip(
        popup_menu( -name => "ReArray Status", -values => $status ),
        "<B>Waiting for Primers:</B> Waiting for primers to arrive.<BR><B>Waiting for Preps:</B> Waiting for preps to be set up.<BR><B>Ready for Application:</B> ready to proceed<BR><B>Barcoded:</B> barcode printed, assumed to be applied<BR><B>Completed:</B> archived.<BR><B>Aborted:</B> Erroneous rearray. Not done."
        );

    # init rearray type search
    # grab statuses from table
    my $rearray_request_types = $rearray_obj->get_rearray_request_types();
    unshift( @$rearray_request_types, '' );
    my $type_spec = '<B>Rearray Type:</B><BR>'
        . Show_Tool_Tip(
        RGTools::Web_Form::Popup_Menu( name => 'ReArray Type', values => $rearray_request_types ),
        "<B>Reaction Rearrays:</B> Rearray leading to sequencing plates. Typically associated with primers/custom oligos. <BR><B>Clone Rearrays:</B> Rearray involving only DNA/clones. <BR><B>Manual Rearrays</B> Rearrays defined and/or defined manually."
        );

    my $rearray_search = HTML_Table->init_table( -title => "ReArray Search", -width => 600, -toggle => 'on' );
    $rearray_search->Set_Border(1);
    $rearray_search->Set_Row( [ $date_spec,    $library_spec,  $status_spec,   $type_spec ] );
    $rearray_search->Set_Row( [ $plateid_spec, $platenum_spec, $employee_spec, $request_spec ] );
    $rearray_search->Set_Row( [ RGTools::Web_Form::Submit_Button( -dbc => $dbc, -form => "ReArray_Search", name => "rm", value => "View ReArrays" ), '&nbsp', '&nbsp', '&nbsp' ] );
    $rearray_search->Set_VAlignment('top');
    $output .= $rearray_search->Printout(0);
    $output .= "<BR>";

    $output .= end_form();
    return $output;
}

############################################
#
# Utilities search page for ReArray (Refactored from Sequencing::ReArray::sequencing_rearray_home, separated from display_search_page)
# Associated run modes: Manually Set Up ReArray, Upload Qpix Log, Upload Yield Report, Rearray Summary, View Primer Plates, Set Primer Plate Well Status
#
############################################
sub display_utilities_search_page {
###########################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    ### rearray utilities table
    #my $rearray_utilities = new HTML_Table();
    #$rearray_utilities->Set_Title("Rearray Utilities");

    ## Flags below determine whether certain add ons should be included ##
    my ($qpix_installed) = $dbc->Table_find( 'Equipment', 'Equipment_ID', "WHERE Equipment_Name like 'QPIX-%'" );    ## this should be changed so that there is a QPIX Plugin or Package instead.
    my ($primer_plates_installed) = $dbc->table_loaded('Primer_Plate');

    require Sequencing::ReArray;
    my $rearray_obj = new Sequencing::ReArray( -dbc => $dbc );

    my $output;

    $output = alDente::Form::start_alDente_form( -dbc => $dbc, -name => "Rearray_Utilities" );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App' );

    my @target_types = ('Tube');
    my $lib_plates_installed = ( $Configs{Plugins} =~ /\bMultiwell_Plate\b/ );
    if ($lib_plates_installed) { push @target_types, ( '96-well', '384-well' ) }

    my $rearray_utilities = HTML_Table->init_table( -title => "ReArray Utilities", -width => 600, -toggle => 'on' );
    $rearray_utilities->Set_Border(1);
    $rearray_utilities->Set_Row(
        [   submit(
                -name  => 'rm',
                -value => 'Manually Set Up ReArray/Pooling',
                -class => "Std",
            ),
            "Target Well Nomenclature:<BR>"
                . popup_menu(
                -name   => "Target Well Nomenclature",
                -values => \@target_types
                )
        ]
    );

    my $template_file     = $Configs{upload_template_dir} . '/' . $dbc->{host} . '/' . $dbc->{dbase} . '/Core/Source_Pooling.yml';
    my $homelink          = $dbc->homelink();
    my $link              = &Link_To( $homelink, 'Download Source Pooling Template', "&cgi_application=alDente::Template_App&rm=Download Excel File&template_file=$template_file" );
    my $pool_action_table = HTML_Table->init_table();
    $pool_action_table->Set_Row( [ "Excel File Upload:", filefield( -name => 'input_file_name', -size => 20, -maxlength => 200 ) ] );
    $pool_action_table->Set_Row( [ "Source IDs:", Show_Tool_Tip( textfield( -name => 'Pool_Source_ID', -size => 20, -force => 1 ), "Enter list of source IDs for pooling. eg. 123,456,789" ) ] );
    $rearray_utilities->Set_Row(
        [   submit(
                -name   => 'rm',
                -value  => 'Batch Pooling Sources',
                -class  => "Std",
                onClick => "return validateForm(this.form,,,'input_file_name'); "
            ),
            $pool_action_table->Printout(0),
            $link
        ]
    );

    #$output .= set_validator( -name => 'input_file_name', -mandatory => 1 );

    $rearray_utilities->Set_Row(
        [   submit(
                -name  => 'rm',
                -value => 'Rearray Summary',
                -style => "background-color:lightgreen"
            ),
            'From Date:<BR>'
                . textfield( -name => 'Rearray From Date', -value => &date_time('-30d') )
                . br()
                . 'Library:<BR>'
                . textfield( -name => 'Summary Library' )
                . br()
                . 'Excluding Library:<BR>'
                . textfield( -name => 'Exclude Summary Library', -default => '' )
                . br()
                . checkbox( -name => "Remove Nonsequenced Transfers", -label => 'Remove Transfers' )
        ]
    );

    $rearray_utilities->Set_Row(
        [   submit(
                -name  => 'rm',
                -value => 'View Index and other related fields',
                -style => "background-color:lightgreen",
                -class => "Std"
            ),
            'Plate ID:<BR>' . Show_Tool_Tip( textfield( -name => 'plate_id', -value => '', -force => 1 ), "You can enter one ID or a bunch of them like 'pla1234pla5678'" )
        ]
    );

    ## the custom sections below should probably look for plugins with 'Rearray home_page blocks' and include those found ##

    # Pick from source plates from QPIX log on to target plate
    if ($qpix_installed) {
        $rearray_utilities->Set_sub_header( 'QPIX Options', 'lightredbw' );
        my $qpix_pick = submit( -name => 'rm', -value => 'Upload Qpix Log', -class => "Std" );
        my $qpix_target_plate = Show_Tool_Tip( textfield( -name => 'Qpix_Target_plate', -value => '', -force => 1 ), "Scan in QPIX target plate. This will create the rearray from parsing the log file." );

        $rearray_utilities->Set_Row( [ $qpix_pick, $qpix_target_plate ] );
    }

    if ($primer_plates_installed) {

        # upload Yield Reports
        $rearray_utilities->Set_sub_header( 'Primer_Plate Options', 'lightredbw' );
        $rearray_utilities->Set_Row(
            [   submit(
                    -name  => 'rm',
                    -value => 'Upload Yield Report',
                    -style => "background-color:lightgreen"
                    )
                    . lbr()
                    . checkbox( -name => 'Suppress_Print', -checked => 0, -label => 'Suppress Printing', -force => 1 ),
                popup_menu(
                    -name    => 'Yield Report Type',
                    -values  => [ 'Illumina', 'Invitrogen', 'IDT Batch' ],
                    -default => 'Illumina'
                ),
                filefield(
                    -name      => 'Yield Report',
                    -size      => 20,
                    -maxlength => 200
                )
            ]
        );

        my @primer_types = ('');
        push( @primer_types, $rearray_obj->{dbc}->Table_find( "Primer", "distinct Primer_Type", "WHERE 1" ) );
        @primer_types = @{ &unique_items( \@primer_types ) };

        # view primer orders and which rearrays (if any) they are associated with
        my @primer_plate_status = ('');
        push( @primer_plate_status, $rearray_obj->{dbc}->Table_find( 'Primer_Plate', 'distinct Primer_Plate_Status' ) );

        $rearray_utilities->Set_Row(
            [   submit(
                    -name  => "rm",
                    -value => "View Primer Plates",
                    -style => "background-color:lightgreen"
                ),
                "<BR> Primer Plate ID: <BR>"
                    . textfield( -name => "Primer Plate ID" )
                    . "<BR> Solution ID: <BR>"
                    . textfield( -name => "Primer Plate Solution ID" )
                    . "<BR> From Order Date: <BR>"
                    . textfield( -name => "Primer From Date" )
                    . "<BR>Status:<BR>"
                    . popup_menu(
                    -name   => "Primer Plate Status",
                    -values => \@primer_plate_status
                    )
                    . "<BR>Type:<BR>"
                    . popup_menu( -name => "Primer Types", -values => \@primer_types )
                    . "<BR>Notes:<BR>"
                    . textfield( -name => "Primer Notes" )
                    . checkbox( -name => "Exclude Canceled Orders", -label => 'Exclude Canceled Orders' )
            ]
        );
        $rearray_utilities->Set_Row( [ submit( -name => "rm", -value => "Set Primer Plate Well Status", -style => "background-color:lightgreen" ), "<BR> Scan in Primer Plate Solution ID: <BR>" . textfield( -name => "Primer Plate Solution ID" ) ] );
    }

    $output .= $rearray_utilities->Printout(0);

    # edit rearray options

    $output .= end_form();
    return $output;
}

#########################
sub span8_csv_views {
##########################
    my %args     = filter_input( \@_ );
    my %info     = %{ $args{-info} };
    my $dbc      = $args{-dbc};
    my $linkname = $args{-linkname};
    my $output;
    my @headers = ( "src_plate_ID", "Source", "SourceWell", "a", "b", "c", "Physical_Tube_Rac", "Dest", "DestWell", "Dest_plate_id", "Volume", "d" );

    my @headers_csv = ( "Source", "src_plate_ID", "SourceWell", "Physical_Tube_Rac", "Dest", "DestWell", "Dest_plate_id", "Volume" );

    #print $filename;

    $output = Link_To( $linkname, 'INSTRUCTIONS' );
    $output .= vspace();

=comment
    my $set_link = 1;
    while ( $set_link <= scalar keys(%info) ) {
        $output .= "Set: $set_link";
        $output .= SDB::HTML::display_hash(
            -hash              => $info{$set_link},
            -keys              => \@headers_csv,
            -title             => "Biomek Span-8 CSV Set: $set_link",
            -excel_link        => 1,
            -csv_link          => 1,
            -return_excel_link => 1,
            -dbc               => $dbc,
            -return_html       => 1,
            -excel_name        => "set_$set_link"
        );
        $output .= "<P>";
        $set_link++;
    }
=cut

    my $set_table = 1;
    while ( $set_table <= scalar keys(%info) ) {

        my $table = SDB::HTML::display_hash(
            -hash              => $info{$set_table},
            -keys              => \@headers_csv,
            -title             => "Biomek Span-8 CSV Set: $set_table",
            -excel_link        => 0,
            -csv_link          => 0,
            -return_excel_link => 1,
            -dbc               => $dbc,
            -return_html       => 1,
            -excel_name        => "set_$set_table"
        );

        $table .= SDB::HTML::display_hash(
            -hash        => $info{$set_table},
            -keys        => \@headers,
            -title       => "Biomek Span-8 CSV Set: $set_table",
            -excel_link  => 0,
            -csv_link    => 0,
            -return_html => 1,
            -dbc         => $dbc
        );

        $output .= SDB::HTML::create_tree( -tree => { "set:$set_table" => $table } );

        #$output .= "<P>";
        $set_table++;
    }

    return $output;
}

#########################
# Subroutine: allows the user to view a list of rearray status for a rearray request type, and to apply a rearray
# Return: none
#########################
sub view_rearrays {
##########################
    #
    # View Re-Arrayed plates & allow Assignment to new Plate...
    #

    my %args = @_;
    my $dbc  = $args{-dbc};

    my $plate          = $args{-plate};
    my $type           = $args{-type};
    my $status         = $args{-status};
    my $request_ids    = $args{-request_ids};
    my $emp_id         = $args{-emp_id};
    my $target_library = $args{-target_library};
    my $from_date      = $args{-from_date};
    my $to_date        = $args{-to_date};
    my $platenum       = $args{-platenum};

    my $homelink = $dbc->homelink();

    my $extra_condition;
    my $order;
    my @field_list;
    my $flist;
    my @headers = ();

    my $sub_header_width = 2;    ##### width of subheaders for target/primer
    my $primer_field     = 7;    ##### index to primer_field
    my $tfield           = 7;    ###### toggle on field change...
    my $Sfield           = 1;    ###### index to source plate ID field

    if ($request_ids) {
        $extra_condition .= " AND ReArray_Request_ID in ($request_ids) ";
    }

    if ($emp_id) {
        $extra_condition .= " AND ReArray_Request.FK_Employee__ID in ($emp_id) ";
    }

    if ($target_library) {

        # add single quotes
        $target_library =~ s/,/','/g;
        $target_library = "'$target_library'";
        $extra_condition .= " AND Plate.FK_Library__Name in ($target_library) ";
    }

    if ($from_date) {
        $extra_condition .= " AND Plate_Created >= '$from_date 00:00:00' ";
    }

    if ($to_date) {
        $extra_condition .= " AND Plate_Created <= '$to_date 23:59:59' ";
    }

    if ($type) {
        $extra_condition .= " AND ReArray_Type = '$type' ";
    }

    if ($status) {
        $extra_condition .= " AND Status_Name like '$status' ";
    }

    if ($platenum) {
        $extra_condition .= " AND Plate_Number in ($platenum) ";
    }

    if ($plate) {
        $plate = &resolve_range($plate);
        $extra_condition .= " AND FKTarget_Plate__ID in ($plate) ";
    }

    @field_list = (
        "ReArray_Request_ID", "Employee_Name", "Status_Name as ReArray_Status",
        "ReArray_Type", "CASE WHEN Plate.Parent_Quadrant" . " THEN concat(FK_Library__Name,'-',Plate_Number,Plate.Parent_Quadrant)" . " ELSE concat(FK_Library__Name,'-',Plate_Number) END as Target_Name",
        "FKTarget_Plate__ID",
        "Left(Plate_Created,10) as Assigned",
        "concat(Left(ReArray_Comments,30),'...') as Comments"
    );

    # check all button
    my $toggleBoxes = "ToggleNamedCheckBoxes(document.ReArray,'ToggleAll','Request_ID');return 0;";

    @headers = (
        checkbox(
            -name    => "ToggleAll",
            -label   => '',
            -onClick => $toggleBoxes
        ),
        "Request_ID",
        "Requester",
        "Status", "Type",
        "Target_Name",
        "Target_Plate",
        "Assigned",
        "Comments"
    );

    my @header_labels = ( "ReArray_Request_ID", "Employee_Name", "ReArray_Status", "ReArray_Type", "Target_Name", "FKTarget_Plate__ID", "Assigned", "Comments" );

    my %rearray_info = $dbc->Table_retrieve( 'ReArray_Request,Employee,Plate,Status',
        \@field_list, "where FK_Status__ID=Status_ID" . " AND FKTarget_Plate__ID=Plate_ID" . " AND ReArray_Request.FK_Employee__ID=Employee_ID" . " $extra_condition" . " order by ReArray_Request_ID" );

    # first check to see if there are any rearrays with that type. If not, return with an error message
    if ( !( $rearray_info{ReArray_Request_ID} ) ) {
        my $extra_info = "";

        if ($request_ids) { $extra_info .= "ID:$request_ids - "; }
        if ($emp_id)      { $extra_info .= "Emp:$emp_id"; }

        Message("Rearray not found ($extra_info)");

        return;
    }

    # grab all the distinct Status and Types
    my @status_list = @{ $rearray_info{ReArray_Status} };
    my @type_list   = @{ $rearray_info{ReArray_Type} };

    @status_list = @{ &unique_items( \@status_list ) };
    @type_list   = @{ &unique_items( \@type_list ) };

    # get all ReArray_Request_IDs and search for their libraries
    my @rearray_ids = @{ $rearray_info{ReArray_Request_ID} };
    my $search_libs = join ",", @rearray_ids;

    ## get the library name of the source plates of all possible rearrays, and create a hash to map Request_ID=>Library
    my %request_lib;
    my $lastlib;

    # then get the target plate library, otherwise use the last source plate library

    my @source_libs = $dbc->Table_find_array( 'ReArray_Request,Plate', [ 'ReArray_Request_ID', 'FK_Library__Name' ], "WHERE FKTarget_Plate__ID=Plate_ID AND ReArray_Request_ID in ($search_libs)", "distinct" );
    foreach my $row (@source_libs) {
        my ( $id, $lib ) = split ',', $row;
        $request_lib{"$id"} = $lib;
    }

    # get all the rearray_format_sizes of all the requests that can be made
    my %format_plate = {};
    my $lastformat;
    my @rearray_size_format = $dbc->Table_find_array( 'ReArray_Request', [ 'ReArray_Request_ID', 'ReArray_Format_Size' ], "where ReArray_Request_ID in ($search_libs)" );

    foreach my $row (@rearray_size_format) {
        my ( $id, $fmt ) = split ',', $row;
        $format_plate{"$id"} = $fmt;
    }

    # get all the source plate sizes and target plate sizes (if the type is not requested). If not 384-384 don't generate a qpix link
    my @matching_ids = $dbc->Table_find_array(
        'ReArray, ReArray_Request, Plate As Source_Library_Plate, Plate As Target_Library_Plate',
        ['ReArray_Request_ID'],
        "where ReArray_Request_ID=FK_ReArray_Request__ID"
            . " AND ReArray.FKSource_Plate__ID=Source_Library_Plate.Plate_ID"
            . " AND ReArray_Request.FKTarget_Plate__ID = Target_Library_Plate.Plate_ID"
            . " AND ReArray_Request_ID in ($search_libs)"
            . " and Source_Library_Plate.Plate_Size  = '384-well'"
            . " and Target_Library_Plate.Plate_Size ='384-well'"
    );

    my %rearray_384_to_384;
    foreach my $id (@matching_ids) {
        $rearray_384_to_384{$id} = 1;
    }

    # initialize access hash
    my $groups = $dbc->get_local('groups');
    my $Table  = new HTML_Table();
    $Table->Set_HTML_Header($html_header);
    $Table->Set_Title("ReArray Status");
    $Table->Toggle_Colour(0);
    $Table->Set_Headers( \@headers );

    my $idfield;
    my $colour;
    my $colour1 = 'vlightyellowbw';
    my $colour2 = 'lightyellowbw';

    my $output = "";

    my $rearray_list = join ',', @rearray_ids;
    $output
        .= &alDente::Form::start_alDente_form( $dbc, -name => "ReArray", -url => $homelink ) . hidden( -name => 'Request IDs', -value => $rearray_list, -force => 1 ) . hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App', -force => 1 );

    $output
        .= &alDente::Form::start_alDente_form( $dbc, -name => "ReArray", -url => $homelink ) . hidden( -name => 'Request IDs', -value => $rearray_list, -force => 1 ) . hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App', -force => 1 );

    # display popup for view options (for group options)
    my @rearray_options = ( "--None--", 'Locations', 'View ReArray', 'Group into Lab Request', 'Generate ReArray Span-8 csv' );
    if ( grep( /Clone Rearray/, @type_list ) ) {
        push( @rearray_options, "Regenerate QPIX File", "Show QPIX Rack" );
    }

    if ( grep( /Reaction Rearray/, @type_list ) ) {
        push( @rearray_options, "Generate DNA Multiprobe", "Generate Custom Primer Multiprobe", "Create Remapped Custom Primer Plate" );
        push( @rearray_options, "Primer Plate Summary", "Source Plate Count", "Source Primer Plate Count" );
    }

    if ( grep( /Waiting for Primers/, @status_list ) ) {
        push( @rearray_options, "Regenerate Primer Order File" );
    }

    if ( grep( /Ready for Application/, @status_list ) ) {
        push( @rearray_options, "Apply Rearrays" );
    }

    if ( grep( /Barcoded|Completed/, @status_list ) ) {
        push( @rearray_options, "Re-Assign Rearray" );
    }

    if ( grep( /Barcoded|Ready for Application/, @status_list ) ) {
        push( @rearray_options, "Move to Completed" );
    }

    if ( grep( /Waiting for Primers|Waiting for Preps|Ready for Application/, @status_list ) ) {
        push( @rearray_options, "Abort Rearrays" );
    }

    $output .= popup_menu( -name => "rm", -values => \@rearray_options );
    $output .= RGTools::Web_Form::Submit_Button( -dbc => $dbc, -form => "ReArray", name => "ReArray_Action", value => "Advanced Options" );

    my $lib;
    my $target;
    my $count;
    my $last_rearray_id = 0;
    my $form_name       = 'ReArray';

    foreach my $id (@rearray_ids) {
        my @other_fields = ();
        foreach my $field (@header_labels) {
            push( @other_fields, $rearray_info{$field}[$count] );
        }

        my $rearray_type = $rearray_info{ReArray_Type}[$count];

        # check the LAST rearray
        my $checked = "";
        if ( $count == $#rearray_ids ) {
            $checked         = "CHECKED";
            $last_rearray_id = $id;
            $lastlib         = $request_lib{$id};
            $lastformat      = $format_plate{$id};
        }

        my @fields = ();

        # draw the checkboxes (for selecting rearrays to act on)
        my $onclick_checkbox = "";
        my $checkbox_string = checkbox( -name => "Request_ID", -value => $id, -label => '', -onClick => $onclick_checkbox );
        @fields = ($checkbox_string);

        push @fields, @other_fields;

        ####### toggle primary colour when first field (Request ID) changes #######
        unless ( $fields[$tfield] eq $idfield ) {

            $colour1 = toggle_colour( $colour1, 'vlightyellowbw', 'vlightyellowbw' );
            $colour2 = toggle_colour( $colour2, 'lightyellowbw',  'lightyellowbw' );

            $lib = substr( $fields[5], undef, 5 );

            print hidden( -name => "Library $idfield:$lib" );
        }

        $colour  = toggle_colour( $colour, $colour1, $colour2 );
        $idfield = $fields[$tfield];
        $target  = $idfield;

        my $field = 0;
        for ( 0 .. 2 ) {
            $fields[$field] = "<span class='mediumredtext'><B>$fields[$field]</B></span>";
            $field++;
        }

        for ( 1 .. $sub_header_width + 1 ) {
            $fields[$field] = "<span><B>$fields[$field]</B></span>";
            $field++;
        }

        for ( 1 .. $sub_header_width ) {
            $fields[$field] = "<B>$fields[$field]</B>";
            $field++;
        }

        my $orderarg = "Target_Well";
        push @fields, Link_To( $dbc->config('homelink'), "View", "&cgi_application=alDente::ReArray_App&rm=home_page&ID=$other_fields[0]&Expand+ReArray+View=1&Order=$orderarg", "$Settings{LINK_COLOUR}" );
        push @fields, Link_To( $dbc->config('homelink'), "LibView", "&cgi_application=alDente::ReArray_App&rm=rearray_map&ID=$other_fields[0]", "$Settings{LINK_COLOUR}" );

        $Table->Set_Row( \@fields, $colour );

        $count++;
    }

    $output .= hidden( -name => "Library $idfield:$lib" );    ### include last set...
    $output .= $Table->Printout( "$alDente::SDB_Defaults::URL_temp_dir/Re_Array@{[timestamp()]}.html", &date_time() );

    $output .= $Table->Printout(0);
    $output .= "<P>";

    my $Current_Department = $dbc->config('Target_Department');

    unless ( $dbc->Security->department_access($Current_Department) =~ /Bioinformatics|Lab|Admin/i ) {
        $output .= "\n</FORM>";
        return 1;
    }

    # if this is a pre-rearray, no need for creating/applying a plate as it still needs to be approved.
    unless ( grep( /Barcoded|Completed|Ready for Application/, @status_list ) ) {
        $output .= "\n</FORM>";
        return 1;
    }

    my $html_form = new SDB::DB_Form(
        -dbc    => $dbc,
        -wrap   => 0,
        -fields => [ 'Plate.FK_Library__Name', 'Plate.Plate_Size', 'Plate.FK_Plate_Format__ID', 'Plate.Plate_Created', 'Plate.FK_Pipeline__ID' ]
    );

    $output .= $html_form->generate(
        -title        => "Applying ReArrayed Plate from Selected ReArrays",
        -navigator_on => 0,
        -form_name    => 'ReArray',
        -return_html  => 1,
        -action       => 'search',
    );

    my $default_rack_id = alDente::Rack::get_default_rack( -dbc => $dbc );    # gets the id of a temporary rack
    $output .= hidden( -name => 'FK_Rack__ID', -value => $default_rack_id );

    $output .= checkbox(
        -name    => 'Set Unused',
        -label   => ' Set All other Wells to Unused',
        -force   => 1,
        -checked => 1,
        -onLoad  => "ResetSource(document.ReArray)"
    );
    $output .= br();
    $output .= "\n</FORM>";

    return $output;
}
###########################
sub manual_rearray_page {
###########################

    my %args                      = @_;
    my $plate                     = $args{-plate};
    my $plate_list                = $args{-plate_list};
    my $dbc                       = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $target_plate_nomenclature = $args{-target_plate_nomenclature};
    $plate = get_aldente_id( $dbc, $plate, 'Plate' );

    my $output = "";
    $output .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => "Manual Rearray" );

    $output .= hidden( -name => 'Plate ID', -value => $plate, -force => 1 );
    $output .= hidden( -name => 'ReArray Well Nomenclature', -value => $target_plate_nomenclature, -force => 1 );

    ( my $plate_info ) = &array_containing( \@plate_info, $Prefix{Plate} . $plate . ':' );

    if ($plate_info) {
        $output .= "Setting up ReArray onto:";
        $output .= section_heading("$plate_info");
    }
    else {
        $output .= section_heading("Pre-Selecting Wells to Re-Array");
    }

    my $Setup = HTML_Table->new();

    ## Flags below determine whether certain add ons should be included ##
    my ($lib_plates_installed) = ( $Configs{Plugins} =~ /\bMultiwell_Plate\b/ );
    my $primers_installed = $dbc->table_loaded('Primer');

    my @row = ('Get from<B> Plates/Tubes</B>: ');
    push @row, Show_Tool_Tip( textfield( -name => 'ReArrayed From', -size => 20, -default => $plate_list ), "For plates and trays, please put plate ids first.\nMay also scan a box id ($Prefix{Rack}) to include ALL Tube records in that box." );

    $Setup->Set_Row( \@row );
    $output .= set_validator( -name => 'ReArrayed From', -mandatory => 1 );

    my $hide   = "HideElement('row.from.wells'); HideElement('row.unused.wells'); HideElement('row.exclude.wells'); HideElement('row.total.wells'); HideElement('row.size.wells'); HideElement('Batch.mode')";
    my $unhide = "unHideElement('row.from.wells'); unHideElement('row.unused.wells'); unHideElement('row.exclude.wells'); unHideElement('row.total.wells'); unHideElement('row.size.wells'); unHideElement('Batch.mode')";
    if ($lib_plates_installed) {
        ## only applicable if Library_Plate Package installed ##
        $Setup->Set_Row(
            [ 'Source Container Format: ', radio_group( -name => 'Format', -values => ['Tube'], -onClick => $hide, -default => 'Tube' ) . radio_group( -name => 'Format', -values => ['Plate'], -default => 'Tube', -force => 1, -onClick => $unhide ) ] );

        @row = ('Using <B>Wells</B><BR>(may enter ranges. eg. a1-d12)<BR>');
        push @row, Show_Tool_Tip( textfield( -name => 'From Wells', -sie => 20 ), 'List range of wells to use from source plates' );

        $Setup->Set_Row( \@row, -element_id => 'row.from.wells', -spec => "style='display:none'" );

        @row = ("<B>Don't Use</B> Columns:<BR>(may enter range eg. 8-12)");
        push @row, Show_Tool_Tip( textfield( -name => 'Unused Columns', -size => 10 ), 'List range of columns that are NOT used' );
        $Setup->Set_Row( \@row, -element_id => 'row.exclude.wells', -spec => "style='display:none'" );

        @row = ("<B>Don't Use</B> Rows:<BR>(may enter range eg. A-D)");
        push @row, Show_Tool_Tip( textfield( -name => 'Unused_Rows', -size => 10 ), 'List range of rows that are NOT used' );
        $Setup->Set_Row( \@row, -element_id => 'row.unused.wells', -spec => "style='display:none'" );

        @row = ("<B>Total # </B>of ReArrayed Wells<BR>(defaults to 96 or # of Wells)");
        push @row, Show_Tool_Tip( textfield( -name => 'ReArray Total', -size => 5 ), 'Number of source wells that are rearrayed' );
        $Setup->Set_Row( \@row, -element_id => 'row.total.wells', -spec => "style='display:none'" );

        @row = ("<B>Target Plate Size</B> (defaults to 96)");
        if ( $target_plate_nomenclature =~ /96.*/ ) {
            ## allow option to array onto 384 well plate still ##
            push @row, Show_Tool_Tip( popup_menu( -name => 'Plate Size', -values => [ "96-well", "384-well" ] ), 'Select what plate size the target plate is' );
        }
        else {
            push @row, Show_Tool_Tip( popup_menu( -name => 'Plate Size', -values => ["$target_plate_nomenclature"] ), 'Select what plate size the target plate is' );
        }
        $Setup->Set_Row( \@row, -element_id => 'row.size.wells', -spec => "style='display:none'" );

        $Setup->Set_Row( [ submit( -name => 'rm', -value => 'Batch ReArray/Pool Wells', -class => "Std", -onClick => 'return validateForm(this.form)' ) ], -element_id => 'Batch.mode', -spec => "style='display:none'" );
    }
    else {
        $output .= hidden( -name => 'Plate Size', -value => 'Tube', -force => 1 );
    }

    $output .= $Setup->Printout(0);
    $output .= lbr();
    if ($primers_installed) {
        $output .= checkbox( -name => 'Specify Primers', -checked => 0 );
    }
    $output .= lbr();
    $output .= Show_Tool_Tip( checkbox( -name => 'Hybrid', -label => 'Create New Hybrid Library/Original Source Automatically', -checked => 0 ), 'Create new hybrid library / original source automatically' );
    $output .= lbr();
    $output .= Show_Tool_Tip( checkbox( -name => 'Transfer', -label => 'Transfer and Throw Away Source Container', -checked => 0 ), 'Transfer full amount from source container and throw source container away' );
    $output .= lbr();
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App' );

    if ( $target_plate_nomenclature != 'Tube' ) {
        $output .= &vspace(10);
        $output .= submit( -name => 'rm', -value => 'Complete ReArray Specification', -class => "Std", -onClick => 'return validateForm(this.form)' );
        $output .= " " . radio_group( -name => 'Fill By', -values => [ ' Fill By Row', ' Fill By Column' ] );
        $output .= lbr();
    }

    $output .= &vspace(10);
    $output .= submit( -name => 'rm', -value => 'ReArray/Pool Wells', -class => "Std", -onClick => 'return validateForm(this.form)' );
    $output .= end_form();

    return $output;

}
###############################
sub specify_rearray_wells {
###############################
    my %args           = filter_input( \@_ );
    my $dbc            = $args{-dbc};
    my $number         = $args{-number};
    my $plates         = $args{-source_plates};
    my $wells          = $args{-wells};
    my $rearray_format = $args{-rearray_format};
    my $plate_size     = $args{-plate_size};
    my $primers        = $args{-primers};
    my $fill_by        = $args{-fill_by};
    my $unused_columns = $args{-unused_columns};
    my $unused_rows    = $args{-unused_rows};

    if ( $plate_size eq 'Tube' ) {
        $dbc->warning("For rearray to a tube, please use aliqout in plate homepage instead of rearray");
        return 1;
    }

    if ( $plate_size =~ /(\d+)\-/ ) { $plate_size = $1 }    ## strip 96-well -> 96 if

    if ( $rearray_format eq '384-well' ) {
        $format = "384-well";
        $wells = &extract_range('a1-p24') if ( $wells eq '' );
    }
    else {
        $format = "96-well";
        $wells = &extract_range('a1-h12') if ( $wells eq '' );
    }

    #$plates ||= get_aldente_id($dbc,param('ReArrayed From'),'Plate');
    my @Rearray_plates = split ',', $plates;
    my @Rearray_wells  = split ',', $wells;

    $number ||= scalar(@Rearray_wells);    ### default to number of wells used * plates specified.

    my @Rearray_primers = $dbc->Table_find( 'Primer', 'Primer_Name', "where Primer_Type='Standard'", 'Distinct' );

    my @headers = ( 'Ignore', 'Source Plate', 'Source Well', 'Target Well' );
    push @headers, 'Primer' if $primers;

    if ( !$number ) { Message('Please specify number of clones'); return 0; }

    my $ReArray = HTML_Table->new();

    push( @Rearray_plates,  "''" );
    push( @Rearray_primers, "''" );

    my $current_date = &now();
    my $output       = '';
    $output .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => "ReArray" );
####
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App' );
    $output .= $output .= hidden( -name => 'ReArray Format', -value => $rearray_format, -force => 1 );
    $output .= hidden( -name => 'Actual Plate Size', -value => $plate_size );

    my $p_type = join ',', $dbc->Table_find( 'Plate', 'Plate_Type', "WHERE Plate_ID IN ($plates)", -distinct => 1 );    ## get plate_type to handle tubes slightly differently ...

    my @source_libs = $dbc->Table_find_array( 'Plate', ['FK_Library__Name'], "where Plate_ID in ($plates)", -distinct => 1 );
    my $related_libs = Cast_List( -list => alDente::Library::related_libraries( -dbc => $dbc, -library => \@source_libs ), -to => 'string', -autoquote => 1 );

    my $pipeline;
    my @pipelines = $dbc->Table_find_array( 'Plate', ['FK_Pipeline__ID'], "where Plate_ID in ($plates)", -distinct => 1 );
    if ( @pipelines && int(@pipelines) == 1 ) { $pipeline = $pipelines[0] }                                             ## preset pipeline if it is distinct

    $ReArray->Set_Alignment( 'right', 1 );
    $ReArray->Set_Title( '<B>Creating ReArrayed Plate from Current Request</B>', class => 'lightredbw' );
    $ReArray->Toggle_Colour(0);

    #    $ReArray->Set_Row(['Library', alDente::Tools->search_list(-dbc=>$dbc,-form=>'ReArray',-name=>'FK_Library__Name',-default=>'',-search=>1,-filter=>1,-breaks=>1,-filter_by_dept=>1)]);
    $ReArray->Set_Row(
        [   'Library',
            alDente::Tools->search_list( -dbc => $dbc, -form => 'ReArray', -name => 'FK_Library__Name', -default => '', -search => 1, -filter => 1, -breaks => 1, )    #-option_condition=>"Library_Name IN ($related_libs)")
        ]
    );
    $ReArray->Set_Row( [ 'Plate Size', "$plate_size" ] );

    # remove formats that are inappropriate
    #    my @modified_plate_formats = ();
    #    foreach my $format (@plate_formats) {
    #	if ($plate_size eq '96-well') {
    #	    push (@modified_plate_formats, $format);
    #	}
    #	elsif ($plate_size eq '384-well') {
    #	    if ($format =~ /(384.*)/) {
    #		push (@modified_plate_formats, $format);
    #	    }
    #	}
    #    }
    my $plate_format_box = alDente::Tools->search_list( -dbc => $dbc, -form => 'ReArray', -name => 'FK_Plate_Format__ID', -default => '', -search => 1, -filter => 1, -breaks => 1, -option_condition => "Wells like '$plate_size'" );

    my %layers;

    $layers{'Existing Plate'} = "Scan Existing Plate: " . Show_Tool_Tip( textfield( -name => 'Target Plate', -size => 20 ), "Scan in plate here if ADDING samples to an existing plate (In currently unused wells)" );

    $ReArray->Set_Row( [ "Plate Format:", $plate_format_box ] );
    $ReArray->Set_Row( [ "Location:",     alDente::Tools->search_list( -dbc => $dbc, -form => 'ReArray', -name => 'FK_Rack__ID', -default => '', -search => 1, -filter => 1, -breaks => 1 ) ] );
    $ReArray->Set_Row( [ "Created:",      "$current_date" ] );

    if ($pipeline) {
        $ReArray->Set_Row( [ '<B>Pipeline:</B>', alDente::Tools::alDente_ref( 'Pipeline', $pipeline, -dbc => $dbc ) . hidden( -name => 'FK_Pipeline__ID', -value => $pipeline, -force => 1 ) ] );
    }
    else {
        $ReArray->Set_Row( [ '<B>Pipeline:</B>', alDente::Tools->search_list( -dbc => $dbc, -form => 'ReArray', -name => 'FK_Pipeline__ID', -default => '', -search => 1, -filter => 1, -breaks => 1, -filter_by_dept => 1 ) ] );
    }

    $layers{'New Target Plate'} = $ReArray->Printout(0);

    $output .= define_Layers( -layers => \%layers, -order => [ 'Existing Plate', 'New Target Plate' ], -default => 'Existing Plate' );
#######

    $ReArray = HTML_Table->new();

    if ( ( $rearray_format eq '96-well' ) && ( $plate_size =~ /384/ ) ) {
        push( @headers, 'Target Quadrant' );
    }
    $ReArray->Set_Headers( \@headers );
    $output .= hidden( 'ReArray Total', -value => $number );

    my $well              = &alDente::ReArray::nextwell( undef, $format, $fill_by, $unused_columns, $unused_rows );
    my $first_well        = "";
    my $prev_counter      = 0;
    my $nextplate_counter = 0;
    foreach my $rearray_number ( 1 .. $number ) {
        my $well_index = $rearray_number;
        while ( $well_index >= scalar(@Rearray_wells) ) { $well_index -= scalar(@Rearray_wells); }
        my $d_well = &format_well( $Rearray_wells[ $well_index - 1 ] );

        my $d_plate  = "''";
        my $d_primer = "''";
        my $d_quad   = "''";
        if ( ( $rearray_number != 1 ) && ( $d_well eq $first_well ) ) {
            $nextplate_counter++;
            if ( $nextplate_counter == scalar(@Rearray_plates) ) {
                $nextplate_counter = 0;
            }
        }
        if ( $rearray_number == 1 ) {
            $d_plate    = $Rearray_plates[$nextplate_counter];
            $d_primer   = $Rearray_primers[0];
            $d_quad     = 'a';
            $first_well = $d_well;
        }
        if ( $nextplate_counter != $prev_counter ) {
            $d_plate      = $Rearray_plates[$nextplate_counter];
            $prev_counter = $nextplate_counter;
        }

        $d_well = 'n/a' unless ( $p_type =~ /Plate/i );

        my @row = (
            checkbox( -name   => "Ignore $rearray_number",        -value  => 0,                -label   => " $rearray_number" ),
            popup_menu( -name => "ReArray Plate $rearray_number", -values => \@Rearray_plates, -default => $d_plate ),
            textfield( -name  => "ReArray Well $rearray_number",  -size   => 8,                -value   => $d_well ),
            textfield( -name  => "Target Well $rearray_number",   -size   => 8,                -value   => $well )
        );

        if ( ( $rearray_format eq '96-well' ) && ( $plate_size =~ /384/ ) ) {
            push @row, Show_Tool_Tip( popup_menu( -name => "Target Quadrant $rearray_number", -values => [ "''", 'a', 'b', 'c', 'd' ] ), $d_quad );
        }
        if ($primers) {
            push @row, Show_Tool_Tip( popup_menu( -name => "ReArray Primer $rearray_number", -values => \@Rearray_primers ), $d_primer );
        }
        $ReArray->Set_Row( \@row );

        $well = &alDente::ReArray::nextwell( $well, $format, $fill_by, $unused_columns, $unused_rows );
    }
    $output .= submit( -name => 'rm', -value => 'Save manual rearray', -class => "Action" ) . "<br>" . checkbox( -name => 'Set Unused', -label => ' Set All other Wells to Unused', -force => 1, -checked => 1 );
    $output .= br() . checkbox( -name => 'Print Two Labels', -label => "Print Double Barcode", -force => 1 );

    $output .= $ReArray->Printout(0);
    $output .= end_form();
    return $output;
}
###########################
# display a summary of all rearrays pending
# return: none
###########################
sub rearray_summary {
###########################
    my %args             = @_;
    my $dbc              = $args{-dbc};
    my $library          = $args{-library};
    my $exclude_library  = $args{-exclude_library};
    my $user             = $args{-user_id};
    my $since_date       = $args{-since_date};
    my $to_date          = $args{-to_date};
    my $remove_transfers = $args{-remove_transfers};
    my $order            = 'Request_Date';

    # remove completed, manually applied, and reassigned rearrays
    my $rearray_condition = " Status_Name NOT IN ('Completed', 'Aborted') ";
    my $primer_condition  = " AND Primer_Plate_Status <> 'Inactive' ";

    my $condition = '1 ';

    my $message_str = 'Condition: ';

    # add since_date condition
    if ($since_date) {
        $rearray_condition .= " AND Request_Date >= '$since_date' ";
        $condition         .= " AND Request_Date >= '$since_date' ";
        $message_str       .= " since $since_date ";
    }

    # add library condition
    if ($library) {
        my @libs = split ',', $library;
        my $library = join( "','", @libs );
        $library = "'$library'";
        $rearray_condition .= " AND FK_Library__Name in ($library) ";
        $message_str       .= " lib $library ";
    }

    # add exclude_library condition
    if ($exclude_library) {
        my @libs = split ',', $exclude_library;
        my $exclude_library = join( "','", @libs );
        $exclude_library = "'$exclude_library'";
        $rearray_condition .= " AND FK_Library__Name NOT IN ($exclude_library) ";
        $message_str       .= " not in lib $exclude_library ";
    }

    Message("$message_str");

    # retrieve data about Rearrays in Lab_Requests
    # exclude Lab_Requests that have been completed and are over a month old (by default)

    my @rearray_info = $dbc->Table_find(
        "Lab_Request,ReArray_Request,Plate,Status",
        "Lab_Request_ID,
										Lab_Request.FK_Employee__ID,
										ReArray_Request_ID,
										ReArray_Type,
										Status_Name as ReArray_Status,
										FK_Library__Name,
										Request_Date",
        "WHERE FK_Status__ID=Status_ID AND 
										FK_Lab_Request__ID=Lab_Request_ID AND 
										FKTarget_Plate__ID=Plate_ID AND 
										$rearray_condition ORDER BY $order"
    );

    # retrieve data about Primer_Plates in Lab_Requests

    my @primer_plate_info = $dbc->Table_find(
        "Lab_Request join Primer_Plate on FK_Lab_Request__ID=Lab_Request_ID",
        "Lab_Request_ID,
											  Lab_Request.FK_Employee__ID,
											  Primer_Plate_ID,
											  Primer_Plate_Status",
        "WHERE $condition $primer_condition 
											  ORDER BY $order"
    );

    my @found_ids           = ();
    my @ordered_request_ids = ();

    # condense data into a hash keyed by Lab_Request_ID
    my %lab_request_info;
    foreach (@rearray_info) {
        my ( $lab_request_id, $requester, $rearray_id, $rearray_type, $rearray_status, $libname, $req_date ) = split ',', $_;

        push( @ordered_request_ids, $lab_request_id );
        $lab_request_info{$lab_request_id}{By}   = $requester;
        $lab_request_info{$lab_request_id}{Date} = $req_date;
        if ( defined $lab_request_info{$lab_request_id}{Library} ) {
            push( @{ $lab_request_info{$lab_request_id}{Library} }, $libname );
        }
        else {
            $lab_request_info{$lab_request_id}{Library} = [$libname];
        }
        my %data;
        $data{ID} = $rearray_id;
        if ( defined $lab_request_info{$lab_request_id}{$rearray_type}{$rearray_status} ) {
            push( @{ $lab_request_info{$lab_request_id}{$rearray_type}{$rearray_status} }, \%data );
        }
        else {
            $lab_request_info{$lab_request_id}{$rearray_type}{$rearray_status} = [ \%data ];
        }

        # retrieve all plates that have been directly derived from the target plate of a Clone rearray
        # split into two sets - sequenced ones and non-sequenced ones
        if ( $rearray_type eq 'Clone Rearray' ) {
            my @transferred_plates
                = $dbc->Table_find( "ReArray_Request,Plate left join Run on Run.FK_Plate__ID=Plate_ID", "Plate_ID,FK_Plate_Format__ID,FKTarget_Plate__ID,Run_ID", "WHERE FKTarget_Plate__ID=FKOriginal_Plate__ID AND ReArray_Request_ID=$rearray_id" );
            foreach my $row (@transferred_plates) {
                my ( $plate_id, $format_id, $original_plate, $sequence_id ) = split ',', $row;
                my $plate_format = $dbc->get_FK_info( "FK_Plate_Format__ID", $format_id );
                if ($sequence_id) {

                    # push plate ids in
                    if ( defined $lab_request_info{$lab_request_id}{'Sequenced Clone Transfer Plates'}{$original_plate}{$plate_format} ) {
                        push( @{ $lab_request_info{$lab_request_id}{'Sequenced Clone Transfer Plates'}{$original_plate}{$plate_format} }, $plate_id );
                    }
                    else {
                        $lab_request_info{$lab_request_id}{'Sequenced Clone Transfer Plates'}{$original_plate}{$plate_format} = [$plate_id];
                    }

                    # push sequence ids in
                    if ( defined $lab_request_info{$lab_request_id}{'Sequenced Clone Transfer Plates'}{$original_plate}{'Run IDs'} ) {
                        push( @{ $lab_request_info{$lab_request_id}{'Sequenced Clone Transfer Plates'}{$original_plate}{'Run IDs'} }, $sequence_id );
                    }
                    else {
                        $lab_request_info{$lab_request_id}{'Sequenced Clone Transfer Plates'}{$original_plate}{'Run IDs'} = [$sequence_id];
                    }
                }
                else {
                    unless ($remove_transfers) {
                        if ( defined $lab_request_info{$lab_request_id}{'Clone Transfer Plates'}{$original_plate}{$plate_format} ) {
                            push( @{ $lab_request_info{$lab_request_id}{'Clone Transfer Plates'}{$original_plate}{$plate_format} }, $plate_id );
                        }
                        else {
                            $lab_request_info{$lab_request_id}{'Clone Transfer Plates'}{$original_plate}{$plate_format} = [$plate_id];
                        }
                    }
                }
            }
        }

        # retrieve sequenced oligo plates
        if ( $rearray_type eq 'Reaction Rearray' ) {
            ###  Find the target plate given a rearray request
            my ($target_plate) = $dbc->Table_find( 'ReArray_Request', 'FKTarget_Plate__ID', "WHERE ReArray_Request_ID=$rearray_id " );
            ### find any child plates of the target plate to see if they have been sequenced
            my $child_list = &alDente::Container::get_Children( -dbc => $dbc, -id => $target_plate, -format => 'list', -include_self => 1 );

            my %transferred_plates = $dbc->Table_retrieve( "Plate left join Run on Run.FK_Plate__ID=Plate.Plate_ID", [ "Run_ID", "Plate_ID as FKTarget_Plate__ID" ], "WHERE Plate_ID in ($child_list) AND Run_Validation='Approved'" );

            my $counter = 0;
            while ( exists $transferred_plates{'Run_ID'}[$counter] ) {
                my $sequence_id    = $transferred_plates{'Run_ID'}[$counter];
                my $original_plate = $transferred_plates{'FKTarget_Plate__ID'}[$counter];
                $counter++;
                if ($sequence_id) {
                    if ( defined $lab_request_info{$lab_request_id}{'Sequenced Oligo Plates'}{$original_plate} ) {
                        push( @{ $lab_request_info{$lab_request_id}{'Sequenced Oligo Plates'}{$original_plate} }, $sequence_id );
                    }
                    else {
                        $lab_request_info{$lab_request_id}{'Sequenced Oligo Plates'}{$original_plate} = [$sequence_id];
                    }
                }
            }
        }

        # need to do a check if the ReArray_Requests use primers that are in house or grouped from other plates (instead of an order that is grouped with a submission)
        # include these as well
        my @primer_plates = $dbc->Table_find(
            "ReArray_Request,Plate_PrimerPlateWell,Primer_Plate_Well,Primer_Plate",                                                                                               "Primer_Plate_ID,Primer_Plate_Status",
            "WHERE FKTarget_Plate__ID=FK_Plate__ID AND FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID AND Primer_Plate_ID=FK_Primer_Plate__ID AND ReArray_Request_ID=$rearray_id", "distinct"
        );
        foreach my $row (@primer_plates) {
            my ( $primer_plate_id, $status ) = split ',', $row;
            push( @found_ids, $primer_plate_id );
            my %data;
            $data{ID} = $primer_plate_id;
            if ( defined $lab_request_info{$lab_request_id}{'Primer Plate'}{$status} ) {
                push( @{ $lab_request_info{$lab_request_id}{'Primer Plate'}{$status} }, \%data );
            }
            else {
                $lab_request_info{$lab_request_id}{'Primer Plate'}{$status} = [ \%data ];
            }
        }
    }
    foreach (@primer_plate_info) {
        my ( $lab_request_id, $requester, $primer_plate_id, $primer_plate_status ) = split ',', $_;
        my %data;
        $data{ID} = $primer_plate_id;
        if ( defined $lab_request_info{$lab_request_id}{'Primer Plate'}{$primer_plate_status} ) {
            push( @{ $lab_request_info{$lab_request_id}{'Primer Plate'}{$primer_plate_status} }, \%data );
        }
        else {
            $lab_request_info{$lab_request_id}{'Primer Plate'}{$primer_plate_status} = [ \%data ];
        }
    }

    # fill out each 'stage' separately
    my @stage_list = ( 'Date', 'Library', 'By', 'Primers on Order', 'Primers Arrived', 'Pending Clone', 'Done Clone', 'Transfers from Clone', 'Pending Oligo', 'Done Oligo' );

    # headers that correspond to the stages
    my @header_list = ( 'Date', 'Library', 'By', 'On Order', 'Arrived', 'Pending', 'Done', 'Transfers', 'Pending', 'Done' );
    my %stages;

    foreach my $stage (@stage_list) {

        # go through the information hash
        foreach my $id ( keys %lab_request_info ) {
            my $colour = undef;
            my $cell   = "";

            # fill out who made the Lab_Request
            if ( $stage eq 'By' ) {
                $cell = $dbc->get_FK_info( "FK_Employee__ID", $lab_request_info{$id}{'By'} );
            }
            elsif ( $stage eq 'Date' ) {
                $cell = $lab_request_info{$id}{'Date'};
            }
            elsif ( $stage eq 'Library' ) {
                my @lib_list = @{ &unique_items( $lab_request_info{$id}{'Library'} ) };
                $cell = join( ',', @lib_list );
            }
            elsif ( $stage eq 'Primers on Order' ) {
                if ( defined $lab_request_info{$id}{'Primer Plate'}{'Ordered'} ) {
                    my $primer_arrayref = $lab_request_info{$id}{'Primer Plate'}{'Ordered'};
                    my @plate_ids       = ();
                    foreach my $single_plate ( @{$primer_arrayref} ) {
                        push( @plate_ids, $single_plate->{ID} );
                    }
                    @plate_ids = @{ &unique_items( \@plate_ids ) };
                    my $count = scalar(@plate_ids);
                    my $link = Link_To( $dbc->config('homelink'), "($count) Ordered", "&View+Primer+Plates=1&Primer+Plate+ID=" . join( ',', @plate_ids ), "$Settings{LINK_COLOUR}", ["newwin"] );
                    $cell   = $link;
                    $colour = $Settings{HIGHLIGHT_WAITING_COLOUR};
                }
                if ( defined $lab_request_info{$id}{'Primer Plate'}{'To Order'} ) {
                    my $primer_arrayref = $lab_request_info{$id}{'Primer Plate'}{'To Order'};
                    my @plate_ids       = ();
                    foreach my $single_plate ( @{$primer_arrayref} ) {
                        push( @plate_ids, $single_plate->{ID} );
                    }
                    @plate_ids = @{ &unique_items( \@plate_ids ) };
                    my $count = scalar(@plate_ids);
                    my $link = Link_To( $dbc->config('homelink'), "($count) To Order", "&View+Primer+Plates=1&Primer+Plate+ID=" . join( ',', @plate_ids ), "$Settings{LINK_COLOUR}", ["newwin"] );
                    $colour = $Settings{HIGHLIGHT_WAITING_COLOUR};
                    if ($cell) {
                        $cell .= "<BR>$link";
                    }
                    else {
                        $cell .= "$link";
                    }
                }
            }
            elsif ( $stage eq 'Primers Arrived' ) {
                if ( defined $lab_request_info{$id}{'Primer Plate'}{'Received'} ) {
                    my $primer_arrayref = $lab_request_info{$id}{'Primer Plate'}{'Received'};
                    my @plate_ids       = ();
                    foreach my $single_plate ( @{$primer_arrayref} ) {
                        push( @plate_ids, $single_plate->{ID} );
                    }
                    @plate_ids = @{ &unique_items( \@plate_ids ) };
                    my $count = scalar(@plate_ids);
                    my $link = Link_To( $dbc->config('homelink'), "($count) Received", "&View+Primer+Plates=1&Primer+Plate+ID=" . join( ',', @plate_ids ), "$Settings{LINK_COLOUR}", ["newwin"] );
                    $cell = $link;
                }
            }
            elsif ( $stage eq 'Pending Clone' ) {
                if ( defined $lab_request_info{$id}{'Clone Rearray'}{'Ready for Application'} ) {
                    my $clone_arrayref = $lab_request_info{$id}{'Clone Rearray'}{'Ready for Application'};
                    my $count          = scalar( @{$clone_arrayref} );
                    my @rearray_ids    = ();
                    foreach my $single_rearray ( @{$clone_arrayref} ) {
                        push( @rearray_ids, $single_rearray->{ID} );
                    }

                    my $link = Link_To( $dbc->config('homelink'), "($count) Ready", "&cgi_application=alDente::ReArray_App&rm=View ReArrays&Request IDs=" . join( ',', @rearray_ids ), "$Settings{LINK_COLOUR}", ["newwin"] );
                    $colour = $Settings{HIGHLIGHT_READY_COLOUR};
                    $cell   = $link;
                }
            }
            elsif ( $stage eq 'Done Clone' ) {
                if ( ( defined $lab_request_info{$id}{'Clone Rearray'}{'Barcoded'} ) || ( defined $lab_request_info{$id}{'Clone Rearray'}{'Completed'} ) ) {
                    my $clone_arrayref = [];
                    if ( defined $lab_request_info{$id}{'Clone Rearray'}{'Barcoded'} ) {
                        push( @{$clone_arrayref}, @{ $lab_request_info{$id}{'Clone Rearray'}{'Barcoded'} } );
                    }
                    if ( defined $lab_request_info{$id}{'Clone Rearray'}{'Completed'} ) {
                        push( @{$clone_arrayref}, @{ $lab_request_info{$id}{'Clone Rearray'}{'Completed'} } );
                    }
                    my $count       = scalar( @{$clone_arrayref} );
                    my @rearray_ids = ();
                    foreach my $single_rearray ( @{$clone_arrayref} ) {
                        push( @rearray_ids, $single_rearray->{ID} );
                    }

                    my $link = Link_To( $dbc->config('homelink'), "($count) Barcoded", "&cgi_application=alDente::ReArray_App&rm=View ReArrays&Request IDs=" . join( ',', @rearray_ids ), "$Settings{LINK_COLOUR}", ["newwin"] );
                    $cell = $link;
                }
            }
            elsif ( $stage eq 'Transfers from Clone' ) {
                if ( defined $lab_request_info{$id}{'Clone Transfer Plates'} || defined $lab_request_info{$id}{'Sequenced Clone Transfer Plates'} ) {
                    my $link = '';

                    # for non-sequenced transfer plates
                    foreach my $original_plate ( keys %{ $lab_request_info{$id}{'Clone Transfer Plates'} } ) {
                        my $link_str = '';
                        foreach my $format ( keys %{ $lab_request_info{$id}{'Clone Transfer Plates'}{$original_plate} } ) {
                            my $plate_ids = join( ',', @{ $lab_request_info{$id}{'Clone Transfer Plates'}{$original_plate}{$format} } );
                            my $count = int( @{ $lab_request_info{$id}{'Clone Transfer Plates'}{$original_plate}{$format} } );
                            $link_str .= "($count) $format,";
                        }

                        # remove last comma
                        $link_str =~ s/,$//g;
                        $link .= Link_To( $dbc->config('homelink'), $link_str, "&Scan=1&Barcode=pla$original_plate", "$Settings{LINK_COLOUR}", ["newwin"] );
                        $link .= br();
                    }

                    # for sequenced transfer plates
                    foreach my $original_plate ( keys %{ $lab_request_info{$id}{'Sequenced Clone Transfer Plates'} } ) {
                        my $link_str = '';
                        foreach my $format ( keys %{ $lab_request_info{$id}{'Sequenced Clone Transfer Plates'}{$original_plate} } ) {
                            if ( $format eq 'Run IDs' ) {
                                next;
                            }
                            my $plate_ids = join( ',', @{ $lab_request_info{$id}{'Sequenced Clone Transfer Plates'}{$original_plate}{$format} } );
                            my $count = int( @{ $lab_request_info{$id}{'Sequenced Clone Transfer Plates'}{$original_plate}{$format} } );
                            $link_str .= "($count) $format (sequenced),";
                        }

                        # remove last comma
                        $link_str =~ s/,$//g;

                        # grab sequence ids
                        my $sequence_ids = join( ',', @{ $lab_request_info{$id}{'Sequenced Clone Transfer Plates'}{$original_plate}{'Run IDs'} } );
                        $link .= Link_To( $dbc->config('homelink'), $link_str, "&Last+24+Hours=1&Any+Date=1&Run+ID=$sequence_ids", "$Settings{LINK_COLOUR}", ["newwin"] );
                        $link .= br();
                    }
                    $cell = $link;
                }
            }
            elsif ( $stage eq 'Pending Oligo' ) {
                if (   ( defined $lab_request_info{$id}{'Reaction Rearray'}{'Waiting for Primers'} )
                    || ( defined $lab_request_info{$id}{'Reaction Rearray'}{'Waiting for Preps'} )
                    || ( defined $lab_request_info{$id}{'Reaction Rearray'}{'Ready for Application'} ) )
                {

                    my $primer_ref = [];
                    my $prep_ref   = [];
                    my $ready_ref  = [];

                    if ( defined $lab_request_info{$id}{'Reaction Rearray'}{'Waiting for Primers'} ) {
                        push( @{$primer_ref}, @{ $lab_request_info{$id}{'Reaction Rearray'}{'Waiting for Primers'} } );
                    }
                    if ( defined $lab_request_info{$id}{'Reaction Rearray'}{'Waiting for Preps'} ) {
                        push( @{$prep_ref}, @{ $lab_request_info{$id}{'Reaction Rearray'}{'Waiting for Preps'} } );
                    }
                    if ( defined $lab_request_info{$id}{'Reaction Rearray'}{'Ready for Application'} ) {
                        push( @{$ready_ref}, @{ $lab_request_info{$id}{'Reaction Rearray'}{'Ready for Application'} } );
                    }
                    my @oligo_list = ( $primer_ref, $prep_ref, $ready_ref );

                    foreach my $clone_arrayref (@oligo_list) {

                        #		    my $clone_arrayref = [];
                        my $count = scalar( @{$clone_arrayref} );
                        if ( $count == 0 ) {
                            next;
                        }
                        my @rearray_ids = ();
                        foreach my $single_rearray ( @{$clone_arrayref} ) {
                            push( @rearray_ids, $single_rearray->{ID} );
                        }

                        my $info_string   = "";
                        my $findprep_link = "";
                        my $link          = "";

                        # if there is still primer plates on order, $info_string is 'Waiting for Primers'
                        # if the clone rearrays (if any) have not yet been done and/or the source_plates are 0, $info_string is 'Waiting for Preps'
                        # else, it is 'Ready for Application'
                        # grab source plates that are 0
                        my @source_plates = $dbc->Table_find( 'ReArray', "FKSource_Plate__ID", "WHERE FK_ReArray_Request__ID in (" . join( ',', @rearray_ids ) . ") AND FKSource_Plate__ID=0" );

                        if ( ( defined $lab_request_info{$id}{'Reaction Rearray'}{'Ready for Application'} ) && ( $ready_ref == $clone_arrayref ) ) {
                            $colour      = $Settings{HIGHLIGHT_READY_COLOUR};
                            $info_string = 'Ready';
                            $link .= Link_To( $dbc->config('homelink'), "($count) $info_string", "&cgi_application=alDente::ReArray_App&rm=View ReArrays&Request IDs=" . join( ',', @rearray_ids ), "$Settings{LINK_COLOUR}", ["newwin"] ) . br();
                        }
                        if ( ( defined $lab_request_info{$id}{'Reaction Rearray'}{'Waiting for Primers'} ) && ( $primer_ref == $clone_arrayref ) ) {
                            $info_string   = 'Waiting for Primers';
                            $colour        = $Settings{HIGHLIGHT_WAITING_COLOUR};
                            $findprep_link = Link_To( $dbc->config('homelink'), "(link prep)", "&Display+Link+Rearray+Plates=1&Request+IDs=" . join( ',', @rearray_ids ), "$Settings{LINK_COLOUR}", ["newwin"] );
                            $link
                                .= Link_To( $dbc->config('homelink'), "($count) $info_string", "&cgi_application=alDente::ReArray_App&rm=View ReArrays&Request IDs=" . join( ',', @rearray_ids ), "$Settings{LINK_COLOUR}", ["newwin"] )
                                . br()
                                . $findprep_link
                                . br();
                        }
                        if ( ( int(@source_plates) > 0 ) || ( defined $lab_request_info{$id}{'Reaction Rearray'}{'Waiting for Preps'} ) && ( $prep_ref == $clone_arrayref ) ) {
                            $colour        = $Settings{HIGHLIGHT_WAITING_COLOUR};
                            $info_string   = 'Waiting for Preps';
                            $findprep_link = Link_To( $dbc->config('homelink'), "(link prep)", "&Display+Link+Rearray+Plates=1&Request+IDs=" . join( ',', @rearray_ids ), "$Settings{LINK_COLOUR}", ["newwin"] );
                            $link
                                .= Link_To( $dbc->config('homelink'), "($count) $info_string", "&cgi_application=alDente::ReArray_App&rm=View ReArrays&Request IDs=" . join( ',', @rearray_ids ), "$Settings{LINK_COLOUR}", ["newwin"] )
                                . br()
                                . $findprep_link
                                . br();
                        }

                        $cell .= $link;
                    }
                }
            }
            elsif ( $stage eq 'Done Oligo' ) {
                if ( ( defined $lab_request_info{$id}{'Reaction Rearray'}{'Barcoded'} ) || ( defined $lab_request_info{$id}{'Reaction Rearray'}{'Completed'} ) ) {
                    my $clone_arrayref = [];

                    # grab entries in the rearray table
                    if ( defined $lab_request_info{$id}{'Reaction Rearray'}{'Barcoded'} ) {
                        push( @{$clone_arrayref}, @{ $lab_request_info{$id}{'Reaction Rearray'}{'Barcoded'} } );
                    }
                    if ( defined $lab_request_info{$id}{'Reaction Rearray'}{'Completed'} ) {
                        push( @{$clone_arrayref}, @{ $lab_request_info{$id}{'Reaction Rearray'}{'Completed'} } );
                    }

                    # get plates that have been barcoded
                    my $count       = scalar( @{$clone_arrayref} );
                    my @rearray_ids = ();
                    foreach my $single_rearray ( @{$clone_arrayref} ) {
                        push( @rearray_ids, $single_rearray->{ID} );
                    }

                    my $link = Link_To( $dbc->config('homelink'), "($count) Barcoded", "&cgi_application=alDente::ReArray_App&rm=View ReArrays&Request IDs=" . join( ',', @rearray_ids ), "$Settings{LINK_COLOUR}", ["newwin"] );

                    # now get data for sequenced plates
                    if ( exists $lab_request_info{$id}{'Sequenced Oligo Plates'} ) {
                        my @sequence_ids = ();
                        my @plate_ids    = keys %{ $lab_request_info{$id}{'Sequenced Oligo Plates'} };
                        foreach my $plate_id (@plate_ids) {
                            push( @sequence_ids, @{ $lab_request_info{$id}{'Sequenced Oligo Plates'}{$plate_id} } );
                        }
                        $link .= br();
                        $link .= Link_To( $dbc->config('homelink'), "($count) Sequenced", "&Last+24+Hours=1&Any+Date=1&Run+ID=" . join( ',', @sequence_ids ), "$Settings{LINK_COLOUR}", ["newwin"] );
                    }
                    $cell = $link;
                }
            }

            # put into summary hash
            $stages{$id}{$stage}{value} = $cell || "&nbsp";
            $stages{$id}{$stage}{colour} = $colour if ( defined $colour );
        }

    }

    # set up table and subheaders
    my $summary = new HTML_Table();
    $summary->Set_Headers( \@header_list );
    $summary->Set_sub_title( 'General Info',      3, 'lightbluebw' );
    $summary->Set_sub_title( 'Primer Plates',     2, 'lightredbw' );
    $summary->Set_sub_title( 'Clone Rearrays',    3, 'lightgreenbw' );
    $summary->Set_sub_title( 'Reaction Rearrays', 2, 'mediumyellowbw' );
    $summary->Set_Border(1);

    @ordered_request_ids = @{ unique_items( \@ordered_request_ids ) };

    # print off each row - ordered by the original sorting
    #foreach my $lab_request_id (sort {$a <=> $b} keys %stages) {
    my $rowcounter    = 1;
    my $columncounter = 1;
    foreach my $lab_request_id (@ordered_request_ids) {
        my @row = ();
        foreach my $stage (@stage_list) {
            push( @row, $stages{$lab_request_id}{$stage}{value} );
            if ( defined $stages{$lab_request_id}{$stage}{colour} ) {
                $summary->Set_Cell_Colour( $rowcounter, $columncounter, $stages{$lab_request_id}{$stage}{colour} );
            }
            $columncounter++;
        }
        $summary->Set_Row( \@row );
        $rowcounter++;
        $columncounter = 1;
    }

    return $summary->Printout(0);

}

###############################################################
# Subroutine: Displays a rearray map, color-coded by library
# RETURN: none
##############################################################
sub display_rearray_map {
    my %args = @_;
    my $dbc  = $args{-dbc};

    my $rearray_id = $args{-request_id};

    # define all colours that can be used for libraries
    my %colours = (
        lightsepia  => '#dfaca0',
        lightorange => '#ffcc66',
        lightcyan   => '#99ffff',
        lightpurple => '#ff99ff',
        lightyellow => '#ffff99',
        lightgreen  => '#99ff99',
        lightblue   => '#9999ff',
        lightred    => '#ff9999',
        lightgrey   => '#bbbbbb',
        white       => '#ffffff'
    );

    ## grab all information necessary (Source_Well, Source_Library, Target_Library, Target_Plate_Number, Target_Plate_ID, Target_Plate_Size, ReArray type)
    # get target plate information

    my ($target_info) = $dbc->Table_find( "ReArray_Request,Plate", "FK_Library__Name,Plate_Number,Plate_ID,Plate_Size,ReArray_Type", "WHERE FKTarget_Plate__ID=Plate_ID AND ReArray_Request_ID=$rearray_id" );
    my ( $target_lib, $target_platenum, $target_plateid, $target_platesize, $rearray_type ) = split ',', $target_info;

    # get rearray information
    my @source_info = $dbc->Table_find( "ReArray,Plate", "FK_Library__Name,Target_Well,Source_Well", "WHERE FKSource_Plate__ID=Plate_ID AND FK_ReArray_Request__ID=$rearray_id" );

    # get wells to fill in from Well_Lookup
    my $rows;
    my $cols;
    if ( $target_platesize =~ /96/ ) {
        $rows = "H";
        $cols = "12";
    }
    elsif ( $target_platesize =~ /384/ ) {
        $rows = "P";
        $cols = "24";
    }
    else {
        Message("Invalid size - $target_platesize");
        return;
    }
    my %well_to_lib;
    my %target_well_to_source_well;
    my %libraries;
    foreach my $row (@source_info) {
        my ( $source_lib, $target_well, $source_well ) = split ',', $row;
        $well_to_lib{$target_well}                = $source_lib;
        $target_well_to_source_well{$target_well} = $source_well;
        $libraries{$source_lib}                   = 1;
    }

    # assign a colour to each library - assume there are max 10 libraries - more than that, loop back to first colour
    my %lib_to_colour;
    my @colour_array = keys %colours;
    my $index        = 0;
    foreach my $lib ( keys %libraries ) {
        $lib_to_colour{$lib} = $colour_array[ $index % 10 ];
        $index++;
    }

    # build table
    my $table = new HTML_Table();
    $table->Set_HTML_Header($html_header);
    $table->Set_sub_header( "ReArray $rearray_id<BR>Type: $rearray_type<BR>Target Plate: $target_lib-$target_platenum (pla$target_plateid)", 'darkblue' );

    # put in column headers
    my @col_header_row = ("&nbsp");
    foreach my $col ( 1 .. $cols ) {
        push( @col_header_row, $col );
    }
    my $rowcounter = 0;
    $table->Set_Row( \@col_header_row );
    foreach my $row ( 'A' .. $rows ) {
        $rowcounter++;
        my @table_row = ($row);
        foreach my $col ( 1 .. $cols ) {
            my $well = &format_well("$row$col");
            if ( defined $well_to_lib{$well} ) {
                my $lib         = $well_to_lib{$well};
                my $source_well = $target_well_to_source_well{$well};
                $table->Set_Cell_Colour( $rowcounter + 2, $col + 1, $colours{ $lib_to_colour{$lib} } );
                push( @table_row, $source_well );
            }
            else {
                $table->Set_Cell_Colour( $rowcounter + 2, $col + 1, '#000000' );
                push( @table_row, "&nbsp" );
            }
        }
        $table->Set_Row( \@table_row );
    }

    #print $table->Printout("$alDente::SDB_Defaults::URL_temp_dir/Rearray_map@{[timestamp()]}.html",$html_header);
    $table->Printout();
    print br();
    $rowcounter = 0;
    my $legend_table = new HTML_Table();
    $legend_table->Set_sub_header( "Library Legend", 'darkblue' );
    foreach my $lib ( keys %lib_to_colour ) {
        $rowcounter++;
        $legend_table->Set_Cell_Colour( $rowcounter + 1, 1, $colours{ $lib_to_colour{$lib} } );
        $legend_table->Set_Row( [$lib] );
    }
    $legend_table->Printout();
    return '';
}

#########################
sub home_page {
##########################
    my %args        = @_;
    my $dbc         = $args{-dbc};
    my $rearray_ids = $args{-id};
    my $order       = $args{-order} || "Order by Target_Well";

    # if multiple rearray requests, just display a set of tables
    my $csv_table;
    my $all_tables = "";
    $all_tables = new HTML_Table();
    $all_tables->Set_HTML_Header($html_header);

    my @rearray_id_array = Cast_List( -list => $rearray_ids, -to => 'Array' );
    my $output = "";
    foreach my $rearray (@rearray_id_array) {

        my @field_list = (
            "concat(Plate.FK_Library__Name,'-',Plate.Plate_Number,Plate.Parent_Quadrant) as Source_Name",
            "ReArray.FKSource_Plate__ID", "ReArray.Source_Well", "Primer_Name", 'Primer_Plate_Name', 'Tm_Working', 'Primer_Sequence', 'Parent_Well.Well',
            "concat(Target_Plate.FK_Library__Name,'-',Target_Plate.Plate_Number,Target_Plate.Parent_Quadrant) as Target_Name",
            "FKTarget_Plate__ID", "ReArray.Target_Well as Target_Well",
            "FK_Solution__ID", 'ReArray_Purpose'
        );
        my @field_headers = ();

        my $extra_condition = "";
        my $tables          = "";

        ## need to display the parent primer plate info even if it has been remapped
        # flag that determined whether the Primer_Plates can be remapped
        my $new_primer_plate = 0;

        # grab primer plate/s
        my @primer_plate_ids
            = $dbc->Table_find( "ReArray_Request,Plate_PrimerPlateWell,Primer_Plate_Well", "distinct FK_Primer_Plate__ID", "WHERE FKTarget_Plate__ID=FK_Plate__ID AND FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID AND ReArray_Request_ID=$rearray" );

        # more than 1 source primer plate - definitive indication that it can be remapped
        if ( scalar(@primer_plate_ids) > 1 ) {
            $new_primer_plate = 0;
        }
        else {

            # check to see if the primer plate has the same mapping as Plate_PrimerPlateWell and it is made in house
            # if it is, then it has been mapped already
            my @well_match = $dbc->Table_find( "ReArray_Request,Plate_PrimerPlateWell,Primer_Plate_Well,Primer_Plate,Solution,Stock,Stock_Catalog", "Plate_Well,Well",
                "WHERE FKTarget_Plate__ID=FK_Plate__ID AND FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID AND FK_Primer_Plate__ID=Primer_Plate_ID and  FK_Stock_Catalog__ID = Stock_Catalog_ID AND FK_Solution__ID=Solution_ID AND FK_Stock__ID=Stock_ID AND ReArray_Request_ID=$rearray AND Stock_Source like 'Made in House'"
            );
            foreach (@well_match) {
                my ( $plate_well, $primer_well ) = split ',', $_;
                if ( $plate_well ne $primer_well ) {
                    $new_primer_plate = 0;
                    last;
                }
                else {

                    # if it passed this test, then they are the same
                    $new_primer_plate = 1;
                }
            }
        }
        my @result_array = ();

        # already created a new Primer_Plate. Display its parents' information
        if ( $new_primer_plate == 1 ) {
            Message("REMAPPED");
            $tables
                = 'ReArray_Request,ReArray left join Plate_PrimerPlateWell on (Plate_Well=Target_Well AND FKTarget_Plate__ID=Plate_PrimerPlateWell.FK_Plate__ID) left join Primer_Plate_Well as Child_Well on FK_Primer_Plate_Well__ID=Child_Well.Primer_Plate_Well_ID left join Primer_Plate_Well as Parent_Well on Child_Well.FKParent_Primer_Plate_Well__ID=Parent_Well.Primer_Plate_Well_ID left join Primer on Parent_Well.FK_Primer__Name=Primer_Name left join Primer_Plate on Parent_Well.FK_Primer_Plate__ID=Primer_Plate_ID left join Primer_Customization on Primer_Customization.FK_Primer__Name=Primer_Name left join Plate on ReArray.FKSource_Plate__ID=Plate.Plate_ID left join Library_Plate on Library_Plate.FK_Plate__ID=Plate.Plate_ID left join Plate_Format on Plate_Format_ID=Plate.FK_Plate_Format__ID,Plate as Target_Plate';
        }
        else {

            # did not create a new Primer_Plate. Display
            $tables
                = 'ReArray_Request,ReArray left join Plate_PrimerPlateWell on (Plate_Well=Target_Well AND FKTarget_Plate__ID=Plate_PrimerPlateWell.FK_Plate__ID) left join Primer_Plate_Well as Parent_Well on FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID left join Primer on Parent_Well.FK_Primer__Name=Primer_Name left join Primer_Plate on FK_Primer_Plate__ID=Primer_Plate_ID left join Primer_Customization on Primer_Customization.FK_Primer__Name=Primer_Name left join Plate on ReArray.FKSource_Plate__ID=Plate.Plate_ID left join Library_Plate on Library_Plate.FK_Plate__ID=Plate.Plate_ID left join Plate_Format on Plate_Format_ID=Plate.FK_Plate_Format__ID,Plate as Target_Plate';
        }

        my @modified_field_list = @field_list;
        if ( $order =~ 'Equipment' ) {
            $tables          .= ",Equipment,Rack";
            $extra_condition .= " AND Plate.FK_Rack__ID=Rack_ID AND FK_Equipment__ID=Equipment_ID";
            my @new_fields = ( 'Equipment_ID', 'Equipment_Name', 'Rack_ID' );
            push( @modified_field_list, @new_fields );
        }
        if ( $order =~ 'Quadrant' ) {
            $tables          .= ",Well_Lookup";
            $extra_condition .= "AND Target_Well=CASE WHEN (Length(Plate_384)=2) THEN ucase(concat(left(Plate_384,1),'0',Right(Plate_384,1))) ELSE Plate_384 END";
        }

        # add rearray id to field list
        push( @modified_field_list, 'ReArray.ReArray_ID' );
        push( @modified_field_list, 'Plate.Plate_Size' );
        push( @modified_field_list, 'Wells' );
        push( @modified_field_list, 'Library_Plate.Plate_Position' );

        # get format size
        my ($plate_format_size) = $dbc->Table_find( "Plate_Format,Plate,ReArray_Request", "Wells", "WHERE ReArray_Request_ID=$rearray AND FKTarget_Plate__ID=Plate_ID AND FK_Plate_Format__ID=Plate_Format_ID" );

        # get mapping from 96-well to 384-well (in case it is necessary)
        my %well_lookup = $dbc->Table_retrieve( "Well_Lookup", [ 'Quadrant', 'Plate_96', 'Plate_384' ], 'order by Quadrant,Plate_96' );
        my %well_96_to_384;
        my $index = 0;
        foreach my $well ( @{ $well_lookup{'Plate_96'} } ) {
            $well_96_to_384{ uc( $well_lookup{'Plate_96'}[$index] ) . $well_lookup{'Quadrant'}[$index] } = $well_lookup{'Plate_384'}[$index];
            $index++;
        }

        my %rearray_info = $dbc->Table_retrieve( $tables, \@modified_field_list, "where ReArray.FK_ReArray_Request__ID=ReArray_Request_ID AND ReArray_Request_ID=$rearray AND FKTarget_Plate__ID=Target_Plate.Plate_ID $extra_condition $order ASC" );
        unless (%rearray_info) {
            Message('ReArray information returned empty.');
            return;
        }

        # get status and comments for rearray
        my ($rearray_status)   = $dbc->Table_find( 'ReArray_Request,Status', 'Status_Name',      "where FK_Status__ID=Status_ID AND ReArray_Request_ID=$rearray" );
        my ($rearray_comments) = $dbc->Table_find( 'ReArray_Request',        'ReArray_Comments', "where ReArray_Request_ID=$rearray" );

        my $sub_header_width = 3;    ##### width of subheaders for target/primer
        my $primer_field     = 4;    ##### index to primer_field
        my $tfield           = 5;    ###### toggle on field change...
        my $Sfield           = 1;    ###### index to source plate ID field

        $output = "";

        $output .= &alDente::Form::start_alDente_form( $dbc, "ReArray", $dbc->homelink() );

        if ( ( $rearray_status =~ /Waiting for Primers|Waiting for Preps|Ready for Application/ ) && ( int(@rearray_id_array) == 1 ) ) {
            if ( $rearray_status =~ /Waiting for Primers/ ) {
                print "<B><font size=-2>Order Number for Primer Plate: " . textfield( -name => "Oligo Order Number" ) . hspace(20);
                my ($sol_id) = $dbc->Table_find(
                    "ReArray_Request,Plate_PrimerPlateWell,Primer_Plate_Well,Primer_Plate",                                                                                                                  "FK_Solution__ID",
                    "WHERE FKTarget_Plate__ID=FK_Plate__ID AND Plate_PrimerPlateWell.FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID AND Primer_Plate_ID=FK_Primer_Plate__ID AND ReArray_Request_ID=$rearray", 'distinct'
                );

                print "Barcode for Primer Plate: " . textfield( -name => "Solution_ID", -value => $sol_id ) . "</font></B>" . hspace(20);
            }
            $output .= hidden( -name => 'ReArray ID', -default => $rearray );
            $output .= submit( -name => 'Submit Modifications', -style => "background-color:lightgreen" );
        }

        my $idfield;
        my $colour;
        my $colour1 = 'vlightyellowbw';
        my $colour2 = 'lightyellowbw';

        my @target_wells = @{ $rearray_info{Target_Well} };
        my $count        = 0;
        my $countinc     = 1;
        my $total_temp   = 0;

        my $prev_source = "";

        # get status of rearray
        my @rearray_status_array = $dbc->Table_find( 'ReArray_Request,Status', 'Status_Name as ReArray_Status,ReArray_Type', "where FK_Status__ID=Status_ID AND ReArray_Request_ID=$rearray" );
        ( $rearray_status, my $rearray_type ) = split ',', $rearray_status_array[0];

        # get target_name
        my @target_names = @{ &RGTools::RGIO::unique_items( $rearray_info{"Target_Name"} ) };
        my $target_name  = $target_names[0];

        # get target plate
        my @target_ids = @{ &RGTools::RGIO::unique_items( $rearray_info{"FKTarget_Plate__ID"} ) };
        my $target_id  = $target_ids[0];

        # get primer_plate_names
        my @primer_plate_names = @{ $rearray_info{"Primer_Plate_Name"} };
        @primer_plate_names = @{ &RGTools::RGIO::unique_items( \@primer_plate_names ) };
        map { delete $primer_plate_names[$_] if ( $primer_plate_names[$_] eq "" ) } ( 0 .. scalar(@primer_plate_names) - 1 );

        # get solution_id
        my @primer_solutions = @{ &RGTools::RGIO::unique_items( $rearray_info{"FK_Solution__ID"} ) };
        map { delete $primer_solutions[$_] if ( $primer_solutions[$_] eq "" ) } ( 0 .. scalar(@primer_solutions) - 1 );

        # grab all rearray attributes
        my @rearray_well_ids = @{ $rearray_info{"ReArray_ID"} };

        # if rearray attributes exist, then add another sub_title called Attributes, and headers for each attribute name
        # add a new column for each attribute, putting the value if it exists for the column, or &nbsp otherwise
        my @attribute_info = $dbc->Table_find( "ReArray_Attribute,Attribute", "FK_ReArray__ID,Attribute_Value,Attribute_Name", "WHERE FK_Attribute__ID=Attribute_ID AND FK_ReArray__ID in (" . join( ',', @rearray_well_ids ) . ")" );

        # array for storing attribute names that are found
        my @rearray_attributes = ();
        if ( int(@attribute_info) > 0 ) {

            # there are some attributes, process the attributes into a hash
            my %attrib_hash;
            foreach my $row (@attribute_info) {
                my ( $id, $value, $name ) = split ',', $row;
                unless ( grep /$name/, @rearray_attributes ) {
                    push( @rearray_attributes, $name );
                }
                $attrib_hash{$id}{$name} = $value;
            }

            # parse into the rearray info hash
            foreach my $id (@rearray_well_ids) {
                foreach my $attrib_name (@rearray_attributes) {
                    unless ( exists $rearray_info{$attrib_name} ) {
                        $rearray_info{$attrib_name} = [];
                    }
                    if ( exists $attrib_hash{$id}{$attrib_name} ) {
                        push( @{ $rearray_info{"$attrib_name"} }, $attrib_hash{$id}{$attrib_name} );
                    }
                    else {
                        push( @{ $rearray_info{"$attrib_name"} }, '&nbsp' );
                    }
                }
            }
        }

        my $Table = HTML_Table->new( -autosort => 1, -autosort_end_skip => 2 );
        $Table->Set_Border(1);
        $Table->Toggle_Colour(0);
        my $primer_sub_header_width;    ##### width of subheaders for primer
        my $target_sub_header_width;    ##### width of subheaders for target
        my $attrib_sub_header_width = int(@rearray_attributes);    ##### width of subheaders for attributes

        if ( ( $rearray_status eq 'Waiting for Primers' ) || ( scalar(@primer_plate_names) > 0 ) ) {
            $primer_sub_header_width = 3;                          ##### width of subheaders for primer
            $target_sub_header_width = 1;                          ##### width of subheaders for target

            @field_headers = ( "Source_Name", "FKSource_Plate__ID", "Source_Well", 'Primer_Plate_Name', 'Primer_Name', 'Well', "Target_Well" );

            my @headers = ( "Source Name", "Source ID", "Source Well", "Order Number", "Primer", "Primer Well", "Target Well" );
            $Table->Set_sub_title( 'Source', 3,                        'lightredbw' );
            $Table->Set_sub_title( 'Primer', $primer_sub_header_width, 'mediumgreenbw' );
            $Table->Set_sub_title( 'Target', $target_sub_header_width, 'mediumyellowbw' );

            # add rearray attributes
            if ( int(@rearray_attributes) > 0 ) {
                push( @headers,       @rearray_attributes );
                push( @field_headers, @rearray_attributes );
                foreach my $attrib_name (@rearray_attributes) {
                    $Table->Set_sub_title( 'Attributes', int(@rearray_attributes), 'mediumbluebw' );
                }
            }
            $Table->Set_Headers( \@headers );

        }
        elsif ( ( $rearray_type eq 'Reaction Rearray' ) || ( $rearray_type eq 'Manual Rearray' ) ) {
            $primer_sub_header_width = 1;                                                                                      ##### width of subheaders for primer
            $target_sub_header_width = 1;                                                                                      ##### width of subheaders for target
            @field_headers           = ( "Source_Name", "FKSource_Plate__ID", "Source_Well", "Primer_Name", "Target_Well" );

            my @headers = ( "Source Name", "Source ID", "Source Well", "Primer", "Target Well" );
            $Table->Set_sub_title( 'Source', 3,                        'lightredbw' );
            $Table->Set_sub_title( 'Primer', $primer_sub_header_width, 'mediumgreenbw' );
            $Table->Set_sub_title( 'Target', $target_sub_header_width, 'mediumyellowbw' );

            # add rearray attributes
            if ( int(@rearray_attributes) > 0 ) {
                push( @headers,       @rearray_attributes );
                push( @field_headers, @rearray_attributes );
                foreach my $attrib_name (@rearray_attributes) {
                    $Table->Set_sub_title( 'Attributes', int(@rearray_attributes), 'mediumbluebw' );
                }
            }
            $Table->Set_Headers( \@headers );
        }
        else {
            $target_sub_header_width = 1;                                                                       ##### width of subheaders for target
            $primer_sub_header_width = 0;                                                                       ##### width of subheaders for primer
            @field_headers           = ( "Source_Name", "FKSource_Plate__ID", "Source_Well", "Target_Well" );

            my @headers = ( "Source Name", "Source ID", "Source Well", "Target Well" );
            $Table->Set_sub_title( 'Source', 3, 'lightredbw' );
            $Table->Set_sub_title( 'Target', $target_sub_header_width, 'mediumyellowbw' );

            # add rearray attributes
            if ( int(@rearray_attributes) > 0 ) {
                push( @headers,       @rearray_attributes );
                push( @field_headers, @rearray_attributes );
                foreach my $attrib_name (@rearray_attributes) {
                    $Table->Set_sub_title( 'Attributes', int(@rearray_attributes), 'mediumbluebw' );
                }
            }
            $Table->Set_Headers( \@headers );
        }

        # hash mapping between a source plate and a mul barcode (if a mul barcode exists)
        my %source_plate_to_mul;

        # search for all the mul barcodes
        # get all the source plates
        my @source_plates = @{ &RGTools::RGIO::unique_items( $rearray_info{"FKSource_Plate__ID"} ) };

        my @mul_barcode_search = ();
        my $tray;
        if ( ( scalar(@source_plates) > 0 ) && ( $source_plates[0] != 0 ) ) {
            $tray = alDente::Tray->new( -dbc => $dbc, -plates => join( ',', @source_plates ) );
        }

        foreach (@source_plates) {
            if ( $tray->{plates}{$_}{tray} ) {
                $source_plate_to_mul{$_} = 'Tra' . $tray->{plates}{$_}{tray};
            }
        }

        foreach my $row (@target_wells) {

            my $field            = 0;
            my @fields           = ();
            my $curr_target_well = "";
            foreach my $field (@field_headers) {
                my $field_value = $rearray_info{$field}[$count];
                if ( ( $field eq "Source_Well" ) && ( $rearray_info{"Plate_Size"}[$count] eq "96" ) && ( $rearray_info{'Wells'}[$count] eq "384" ) ) {
                    my $quadrant = $rearray_info{"Plate_Position"}[$count];
                    $field_value = &format_well( $well_96_to_384{ $field_value . $quadrant } ) . " ($field_value$quadrant)";
                }
                if ( $field eq "Target_Well" ) {
                    $curr_target_well = $field_value;
                }
                if ( $field eq "FKSource_Plate__ID" ) {
                    if ( defined $source_plate_to_mul{$field_value} ) {
                        $field_value .= "($source_plate_to_mul{$field_value})";
                    }
                }
                push( @fields, $field_value );
            }

            # keep track of temperature
            $total_temp += $rearray_info{"Tm_Working"}[$count];
            for ( 0 .. 2 ) {

                # if source plates are not set, blank out source name and put in a text field
                if ( ( $rearray_status =~ /Waiting for Primers|Waiting for Preps|Ready for Application/ ) && ( $_ == 1 ) ) {

                    #if (  ($_==1)) {
                    my $source_value = "''";
                    if ( $fields[$field] ne $prev_source ) {
                        $source_value = $fields[$field];
                    }
                    $prev_source = $fields[$field];
                    $fields[$field] = &textfield( -name => "sourceplate$countinc", -size => 8, -default => $source_value, -force => 1 );
                    print hidden( -name => "targetwell$countinc", -default => $curr_target_well );
                }
                else {
                    $fields[$field] = "<span class='mediumredtext'><B>$fields[$field]</B></span>";
                }
                $field++;
            }

            for ( my $i = 0; $i < $primer_sub_header_width; $i++ ) {
                $fields[$field] = "<span><B>$fields[$field]</B></span>";
                $field++;
            }
            for ( 1 .. $target_sub_header_width ) {
                $fields[$field] = "<B>$fields[$field]</B>";
                $field++;
            }
            for ( 1 .. $attrib_sub_header_width ) {
                $fields[$field] = "$fields[$field]";
                $field++;
            }
            $Table->Set_Row( \@fields, $colour );
            $count++;
            $countinc++;
        }
        $csv_table = $Table;
        $csv_table->{sub_titles} = '';

        # if there is more than 1 primer plate name, then the primer name information is displayed
        # already. If there is only one, display it on the title as a summary
        my $primer_string = "<BR>Primer Plate : <BR>";
        for ( my $i = 0; $i < scalar(@primer_plate_names); $i++ ) {
            $primer_string .= "$primer_plate_names[$i] (sol$primer_solutions[$i])<BR>";
        }
        if ( scalar(@primer_plate_names) > 0 ) {
            $primer_string = "<BR>Primer Plate: <BR>$primer_string";
        }

        # if there are rearray comments, add them in
        if ( ( defined $rearray_comments ) && ( $rearray_comments ne '' ) ) {
            $rearray_comments = "<BR>Comments: <BR>$rearray_comments";
        }
        my $img      = "ReArray_Barcode@{[timestamp()]}.png";
        my $img_path = "$alDente::SDB_Defaults::URL_temp_dir";
        
        require alDente::Barcode;
        my $Barcode = new alDente::Barcode(-dbc=>$dbc);
        $Barcode->generate_barcode_image( -file => "$img_path/$img", -value => "rry${rearray}" );
        
        my $header_table = new HTML_Table( -width => '100%' );
        $header_table->Set_Row( [ "ReArray Request $rearray<BR>Type: $rearray_type<BR>Target: $target_name(pla$target_id) $primer_string $rearray_comments", "<img src='/dynamic/tmp/$img'>" ], 'mediumbluebw' );

        #Create a random name for the javascript mergesort and pass it to HTML_Table
        my $randname = rand();

        # get the eight least significant figures
        $randname = substr( $randname, -8 );

        #A normal javascript mergesort that sort alphanumerically is mergesort($#field_headers,$randname)
        #so for example: A01 B02 B01 A02 is sorted to A01 A02 B01 B02
        #Here is using a special javascript mergesort that swap digits and non-digits first and then sort with a smart sort (same algorithm as in RGmath)
        #and that's why there is a 1 in the function call mergesort($#field_headers,$randname,1)
        #so for example: A01 B02 B01 A02 is sorted to A01 B01 A02 B02
        my ($target_well_index) = grep $field_headers[$_] eq 'Target_Well', 0 .. $#field_headers;
        $header_table->Set_Row( ["<a href='' onclick='return mergesort($target_well_index,$randname,1)'>Sort Target Well By Column (click again to reverse order)</a>"], 'mediumbluebw' );
        $header_table->Set_Row( ["<a href='' onclick='return mergesort($target_well_index,$randname)'>Sort Target Well By Row (click again to reverse order)</a>"],      'mediumbluebw' );
        $Table->Set_Title( $header_table->Printout(0), bgcolour => 'white' );

        # print average temperature
        # truncate to 2 decimal places
        my $ave_temp = ( int( ( $total_temp / ($count) ) * 100 ) ) / 100;
        $Table->Set_Row( [ "<B>AvgTmp =</B>", $ave_temp ], "$colour" );
        $Table->Set_Row( [ "<B>Sort By:</B>", _linkto_order_by_encoding( $dbc, $rearray, "Equipment/Rack", "Equipment_Name,Plate.FK_Rack__ID,Plate.Plate_ID" ) ] );
        if ( $plate_format_size == '384' ) {
            $Table->Set_Row( [ "", _linkto_order_by_encoding( $dbc, $rearray, "Quadrant", "Quadrant,Target_Well" ) ] );
            $Table->Set_Autosort_End_Skip(3);
        }

        $all_tables->Set_Row( [ $Table->Printout( 0, -randname => $randname ) ] );

        $output .= hidden( -name => "NumWells", -default => $count );
    }
    $output .= $all_tables->Printout( "$alDente::SDB_Defaults::URL_temp_dir/Re_Array@{[timestamp()]}.html", $html_header . $java_header );
    if ( int(@rearray_id_array) == 1 ) {
        $output .= $csv_table->Printout("$alDente::SDB_Defaults::URL_temp_dir/Re_Array@{[timestamp()]}.csv");
    }
    $output .= $all_tables->Printout(0);

    $output .= end_form();

    return $output;
}

############################################################
# Generate a view which summarizes primer plates used for a set of rearrays
# RETURN: 1 if successful, 0 otherwise
############################################################
sub view_rearray_primer_plates {
############################################################

    my %args = &filter_input( \@_ );

    my $dbc         = $args{-dbc};
    my $rearray_ids = $args{-rearray_ids};    # (Scalar) Rearray IDs to view

    unless ($rearray_ids) {
        Message("ERROR: No rearray ids provided.");
        return 0;
    }
    ## ERROR CHECK ##
    # Make sure all rearrays are Reaction Rearrays
    $rearray_ids = &Cast_List( -list => $rearray_ids, -to => "arrayref" );
    my $rearray_id_str = join( ',', @{$rearray_ids} );

    my @reaction_rearrays = $dbc->Table_find( "ReArray_Request", "ReArray_Request_ID", "WHERE ReArray_Type='Reaction Rearray' AND ReArray_Request_ID in ($rearray_id_str)" );
    unless ( int(@reaction_rearrays) == int( @{$rearray_ids} ) ) {
        Message("ERROR: One or more rearrays are not reaction rearrays");
        return 0;
    }

    ## END ERROR CHECK

    # retrieve data needed for viewing primer plates
    my %primer_info = $dbc->Table_retrieve(
        'ReArray_Request,ReArray,Plate,
											Plate_PrimerPlateWell,
											Primer_Plate_Well as Child,
											Primer_Plate_Well as Parent,
											Primer_Plate as Parent_Plate,
											Primer_Plate as Child_Plate,
											Primer,Primer_Customization,
											Solution as Parent_Solution',
        [   'FKTarget_Plate__ID',
            'Parent_Plate.Primer_Plate_Name as Primer_Plate',
            'Parent_Plate.FK_Solution__ID as Solution',
            'Tm_Working',
            'ReArray_Request_ID',
            'Child_Plate.Primer_Plate_Name as Target_Primer_Plate',
            'Child_Plate.FK_Solution__ID as Target_Solution_ID',
            'Parent_Solution.FK_Rack__ID as Source_Location',
            "ReArray_Comments"
        ],
        "WHERE ReArray_Request_ID=ReArray.FK_ReArray_Request__ID and 
											FKTarget_Plate__ID=FK_Plate__ID and 
											Plate_ID = FKTarget_Plate__ID and 
											Child.Primer_Plate_Well_ID=FK_Primer_Plate_Well__ID AND 
											Child.FK_Primer_Plate__ID=Child_Plate.Primer_Plate_ID AND 
											Child.FKParent_Primer_Plate_Well__ID=Parent.Primer_Plate_Well_ID AND 
											Parent.FK_Primer_Plate__ID=Parent_Plate.Primer_Plate_ID and 
											Child.FK_Primer__Name=Primer_Name and 
											Child.Primer_Plate_Well_ID = Plate_PrimerPlateWell.FK_Primer_Plate_Well__ID and 
											Plate_Well = Target_Well and 
											Primer_Customization.FK_Primer__Name=Primer_Name AND 
											Parent_Plate.FK_Solution__ID=Parent_Solution.Solution_ID AND 
											ReArray_Request_ID in ($rearray_id_str) 
											group by FKTarget_Plate__ID, Child_Plate.FK_Solution__ID,Plate_Well"
    );

    # build hash with rearray ID as the key, and associated information as values
    my $index = 0;
    my %rearray_info;
    foreach my $rearray_id ( @{ $primer_info{'ReArray_Request_ID'} } ) {
        my $target_plate        = $primer_info{"FKTarget_Plate__ID"}[$index];
        my $primer_plate        = $primer_info{"Primer_Plate"}[$index];
        my $rack_id             = $primer_info{"Source_Location"}[$index];
        my $sol_id              = $primer_info{"Solution"}[$index];
        my $target_solution_id  = $primer_info{"Target_Solution_ID"}[$index];
        my $target_primer_plate = $primer_info{"Target_Primer_Plate"}[$index] || '';
        my $rearray_comments    = $primer_info{"ReArray_Comments"}[$index];
        my $tm                  = $primer_info{"Tm_Working"}[$index];
        if ( !defined $rearray_info{$rearray_id} ) {
            $rearray_info{$rearray_id} = {
                'Target_Comments' => $rearray_comments,
                'Target_Plate'    => $target_plate,
                'Tm_Working'      => []
            };
        }
        my $primer_key = "$primer_plate" . "$target_primer_plate";
        $rearray_info{$rearray_id}{'Primer_Plate'}{$primer_key}{'Primer_Plate'}           = $primer_plate;
        $rearray_info{$rearray_id}{'Primer_Plate'}{$primer_key}{'Solution_ID'}            = $sol_id;
        $rearray_info{$rearray_id}{'Primer_Plate'}{$primer_key}{'Rack_ID'}                = $rack_id;
        $rearray_info{$rearray_id}{'Primer_Plate'}{$primer_key}{'Target_Primer_Plate'}    = $target_primer_plate;
        $rearray_info{$rearray_id}{'Primer_Plate'}{$primer_key}{'Target_Primer_Solution'} = $target_solution_id;
        push( @{ $rearray_info{$rearray_id}{'Tm_Working'} }, $tm );

        $index++;
    }

    my $all_tables = new HTML_Table();
    foreach my $rearray_id ( sort { $a <=> $b } keys %rearray_info ) {

        # get average temperature
        my $avg_tmp = 0;
        my $sum_tmp = 0;
        foreach my $tmp ( @{ $rearray_info{$rearray_id}{'Tm_Working'} } ) {
            $sum_tmp += $tmp;
        }
        $avg_tmp = int( ( ( $sum_tmp / int( @{ $rearray_info{$rearray_id}{'Tm_Working'} } ) ) * 100 ) ) / 100;

        # get target plate name
        my $plate_id           = $rearray_info{$rearray_id}{"Target_Plate"};
        my $target_solution_id = $rearray_info{$rearray_id}{"Target_Solution"};
        my $target_comments    = $rearray_info{$rearray_id}{"Target_Comments"};
        $plate_id = $dbc->get_FK_info( "FK_Plate__ID", $plate_id );

        # get target solution ID

        my $table = new HTML_Table( -autosort => 1 );
        $table->Toggle_Colour('off');
        $table->Set_Border('on');
        $table->Set_Title("Rearray: $rearray_id<BR> Target Plate: <BR>&emsp;$plate_id  <BR>Average Temp: $avg_tmp <BR> Comments: $target_comments <BR>");

        $table->Set_Headers( [ 'Primer Plate Name', 'Solution ID', 'Target Primer Plate', 'Target Solution ID', "Equipment", "Rack" ] );
        $table->Set_sub_title( 'Primer Plate', 4, 'mediumgreenbw' );
        $table->Set_sub_title( 'Location',     2, 'lightredbw' );
        my @rows                = ();
        my $target_plate_exists = 0;
        foreach my $primer_key ( keys %{ $rearray_info{$rearray_id}{'Primer_Plate'} } ) {
            my $primer_plate        = $rearray_info{$rearray_id}{'Primer_Plate'}{$primer_key}{'Primer_Plate'};
            my $sol_id              = $rearray_info{$rearray_id}{'Primer_Plate'}{$primer_key}{'Solution_ID'};
            my $rack_id             = $rearray_info{$rearray_id}{'Primer_Plate'}{$primer_key}{'Rack_ID'};
            my $target_primer_plate = $rearray_info{$rearray_id}{'Primer_Plate'}{$primer_key}{'Target_Primer_Plate'};
            my $target_solution_id  = $rearray_info{$rearray_id}{'Primer_Plate'}{$primer_key}{'Target_Primer_Solution'};
            if ($target_primer_plate) {
                $target_plate_exists = 1;
            }

            my ($rack_info) = $dbc->Table_find( "Rack,Equipment", "Equipment_Name,Rack_Alias", "WHERE FK_Equipment__ID=Equipment_ID AND Rack_ID=$rack_id" );
            my ( $equ_name, $rack_name ) = split ',', $rack_info;
            push( @rows, [ $primer_plate, $sol_id, $target_primer_plate, $target_solution_id, $rack_name, $equ_name ] );
        }
        if ($target_plate_exists) {
            ## sort by target plate name
            @rows = sort { $a->[2] cmp $b->[2] } @rows;
        }
        else {
            ## sort by solution id
            @rows = sort { $a->[1] <=> $b->[1] } @rows;
        }
        foreach my $row (@rows) {
            $table->Set_Row($row);
        }
        $all_tables->Set_Row( [ $table->Printout(0) ] );

    }
    my $output;
    $output .= $all_tables->Printout("$alDente::SDB_Defaults::URL_temp_dir/Primer_plate_summary@{[timestamp()]}.html");
    $output .= $all_tables->Printout(0);
    return $output;
}

#############################
# function to match rearrays with source plates (if they haven't been assigned yet)
#############################
sub display_rearray_link {
    my $self        = shift;
    my %args        = @_;
    my $request_ids = $args{-request_ids};    # (ArrayRef) array of rearray ids
    my $dbc         = $args{-dbc};

    # check if the request is part of a Lab_Request that encompasses clone rearrays
    # if it isn't, just display the scanbox
    # if it is, grab the FKTarget_Plate__IDs of the clone rearrays and display all available plates
    # (optionally look for Completed Preps step?)
    print alDente::Form::start_alDente_form( $dbc, "RearrayLink", $dbc->homelink() );
    print "<div class=small>";
    my $heading = "For Rearray(s) " . join( ',', @{$request_ids} );
    print &Views::Heading($heading);
    print "Scan Prep Plates:" . textfield( -name => "Plate_ID" ) . br();
    my @rearray_targets = ();
    foreach my $request_id ( @{$request_ids} ) {
        print hidden( -name => 'Request_ID', -value => $request_id );
        my ($lab_request_id) = $dbc->Table_find( "ReArray_Request", "FK_Lab_Request__ID", "WHERE ReArray_Request_ID=$request_id" );
        if ($lab_request_id) {

            # search for clone rearray targets
            push( @rearray_targets, $dbc->Table_find( "ReArray_Request", "FKTarget_Plate__ID", "WHERE FK_Lab_Request__ID=$lab_request_id AND ReArray_Type='Clone Rearray'" ) );
        }
    }
    my %treehash;

    # get all plates that descend from the rearray targets
    if ( int(@rearray_targets) > 0 ) {
        my $targets = join( ',', @rearray_targets );
        my %plate_info = $dbc->Table_retrieve( "Plate", [ 'Plate_ID', 'FK_Plate_Format__ID' ], "WHERE FKOriginal_Plate__ID in ($targets) ORDER BY Plate_ID" );
        my $index = 0;
        while ( exists $plate_info{'Plate_ID'}[$index] ) {
            my $plate_id     = $plate_info{'Plate_ID'}[$index];
            my $format_id    = $plate_info{'FK_Plate_Format__ID'}[$index];
            my $plate        = $dbc->get_FK_info( "FK_Plate__ID", $plate_id );
            my $format       = $dbc->get_FK_info( "FK_Plate_Format__ID", $format_id );
            my $checkboxname = "Plate_checkbox_${plate_id}";
            my $keystr       = checkbox(
                -name  => "$checkboxname",
                -value => $plate_id,
                -label => '',
                -onClick =>
                    "if (document.RearrayLink.$checkboxname.checked) { document.RearrayLink.Plate_ID.value=document.RearrayLink.Plate_ID.value + 'pla$plate_id'; } else { document.RearrayLink.Plate_ID.value=document.RearrayLink.Plate_ID.value.replace(/pla$plate_id/g,''); }"
            );
            $keystr .= "$plate ($format)";

            #my $keystr = "$plate ($format)";
            # get all preps done on this plate
            my @prep_names = $dbc->Table_find( "Prep,Plate_Prep", "distinct Prep_Name", "WHERE FK_Prep__ID=Prep_ID AND FK_Plate__ID=$plate_id ORDER BY Prep_ID" );
            $treehash{"$keystr"} = \@prep_names;
            $index++;
        }
    }

    #print HTML_Dump \%treehash;
    my $output = SDB::HTML::create_tree( -tree => \%treehash, -print => 1, -toggle_open => 1 );

    print "</div>";
    print submit( -name => "Link Rearray Plates", -style => "background-color:red" );
    print end_form();
}

############################################################
# Generate a view which shows the number of times a source plate has been used
# RETURN: 1 if successful, 0 otherwise
############################################################
sub view_source_plate_count {
############################################################
    my %args = &filter_input( \@_ );

    my $dbc         = $args{-dbc};
    my $rearray_ids = $args{-rearray_ids};    # (Scalar) Rearray IDs to view

    unless ($rearray_ids) {
        Message("ERROR: No rearray ids provided.");
        return 0;
    }
    ## ERROR CHECK ##
    # Make sure all rearrays are Reaction Rearrays
    $rearray_ids = &Cast_List( -list => $rearray_ids, -to => "arrayref" );
    my $rearray_id_str = join( ',', @{$rearray_ids} );

    my @reaction_rearrays = $dbc->Table_find( "ReArray_Request", "ReArray_Request_ID", "WHERE ReArray_Type='Reaction Rearray' AND ReArray_Request_ID in ($rearray_id_str)" );
    unless ( int(@reaction_rearrays) == int( @{$rearray_ids} ) ) {
        Message("ERROR: One or more rearrays are not reaction rearrays");
        return 0;
    }

    ## END ERROR CHECK

    # get each distinct source plate ID and a count of each
    my @source_count = $dbc->Table_find(
        "ReArray,Plate",
        "Plate_ID,concat(FK_Library__Name,'-',Plate_Number,Parent_Quadrant),Source_Well,count(*)",
        "WHERE FKSource_Plate__ID=Plate_ID AND FK_ReArray_Request__ID in ($rearray_id_str) GROUP BY FKSource_Plate__ID,Source_Well ORDER BY FKSource_Plate__ID"
    );

    my %source_info;
    foreach my $row (@source_count) {
        my ( $plate_id, $plate_name, $well, $count ) = split ',', $row;
        if ( defined $source_info{$plate_id} ) {
            if ( $source_info{$plate_id}{'count'} < $count ) {
                $source_info{$plate_id}{'count'} = $count;
            }
        }
        else {
            $source_info{$plate_id} = { 'plate_name' => $plate_name, 'count' => $count };
        }
    }

    my $title_str = '';
    my $counter   = 0;
    foreach my $rearray_id ( @{$rearray_ids} ) {
        if ( ( $counter % 5 ) == 0 ) {
            $title_str .= "<BR>&emsp;";
        }
        else {
            $title_str .= ",";
        }
        $title_str .= "$rearray_id";
        $counter++;
    }

    # display results
    my $table = new HTML_Table( -autosort => 1 );
    $table->Set_HTML_Header($html_header);
    $table->Set_Title("Rearray Source Plate Count <BR> Rearray IDs: $title_str");
    $table->Toggle_Colour('off');
    $table->Set_Border('on');
    $table->Set_Headers( [ 'Plate Name', 'Plate ID', "Count" ] );
    $table->Set_sub_title( 'Plate', 2, 'mediumyellowbw' );
    $table->Set_sub_title( 'Usage', 1, 'lightredbw' );
    foreach my $plate_id ( keys %source_info ) {
        my $plate_name = $source_info{$plate_id}{'plate_name'};
        my $count      = $source_info{$plate_id}{'count'};

        $table->Set_Row( [ $plate_name, "pla$plate_id", $count ] );
    }
    my $output;

    $output .= $table->Printout("$alDente::SDB_Defaults::URL_temp_dir/Rearray_plate_count@{[timestamp()]}.html");
    $output .= $table->Printout(0);
    return $output;
}

############################################################
# Generate a view which shows the maximum number of times a primer plate has been used
# RETURN: 1 if successful, 0 otherwise
############################################################
sub view_primer_plate_count {
############################################################
    my %args = &filter_input( \@_ );

    my $dbc         = $args{-dbc};
    my $rearray_ids = $args{-rearray_ids};    # (Scalar) Rearray IDs to view

    unless ($rearray_ids) {
        Message("ERROR: No rearray ids provided.");
        return 0;
    }
    ## ERROR CHECK ##
    # Make sure all rearrays are Reaction Rearrays
    $rearray_ids = &Cast_List( -list => $rearray_ids, -to => "arrayref" );
    my $rearray_id_str = join( ',', @{$rearray_ids} );

    my @reaction_rearrays = $dbc->Table_find( "ReArray_Request", "ReArray_Request_ID", "WHERE ReArray_Type='Reaction Rearray' AND ReArray_Request_ID in ($rearray_id_str)" );
    unless ( int(@reaction_rearrays) == int( @{$rearray_ids} ) ) {
        Message("ERROR: One or more rearrays are not reaction rearrays");
        return 0;
    }

    ## END ERROR CHECK

    # find all primers used for the specified rearrays and count how many times they were used
    my @primer = $dbc->Table_find( 'ReArray_Request,ReArray,Plate_PrimerPlateWell,Primer_Plate_Well',
        'FK_Primer__Name,count(*)',
        "WHERE FK_Plate__ID = FKTarget_Plate__ID and FK_ReArray_Request__ID=ReArray_Request_ID and Primer_Plate_Well_ID = FK_Primer_Plate_Well__ID and Plate_Well = Target_Well AND ReArray_Request_ID in ($rearray_id_str) GROUP BY FK_Primer__Name" );

    # for each unique primer name, find the primer plate it was originally found in.
    # the maximum number of times a primer plate has been used is the largest number of times a primer has been used on that primer plate
    # for example: a primer plate has 3 primers used
    # A1 - 3x
    # A2 - 5x
    # A3 - 1x
    # th maximum number of times this primer plate has been used is 5x.

    my %primer_info;
    foreach my $row (@primer) {
        my ( $primer, $count ) = split ',', $row;
        my ($primer_plate_row) = $dbc->Table_find( "Stock,Stock_Catalog,Solution,Primer_Plate,Primer_Plate_Well", "Primer_Plate_Name,FK_Solution__ID",
            "WHERE FK_Stock__ID=Stock_ID AND Stock_Catalog_ID = FK_Stock_Catalog__ID and  FK_Solution__ID=Solution_ID AND FK_Primer_Plate__ID=Primer_Plate_ID AND Primer_Plate_Status <> 'Inactive' AND Stock_Source <> 'Made in House' AND FK_Primer__Name='$primer'"
        );
        my ( $primer_plate_name, $solution_id ) = split ',', $primer_plate_row;

        if ( defined $primer_info{$primer_plate_name} ) {
            if ( $primer_info{$primer_plate_name}{'count'} < $count ) {
                $primer_info{$primer_plate_name}{'count'} = $count;
            }
        }
        else {
            $primer_info{$primer_plate_name} = { 'count' => $count, 'solution_id' => $solution_id };
        }
    }

    my $title_str = '';
    my $counter   = 0;
    foreach my $rearray_id ( @{$rearray_ids} ) {
        if ( ( $counter % 5 ) == 0 ) {
            $title_str .= "<BR>&emsp;";
        }
        else {
            $title_str .= ",";
        }
        $title_str .= "$rearray_id";
        $counter++;
    }

    # display results
    my $table = new HTML_Table( -autosort => 1 );
    $table->Set_HTML_Header($html_header);
    $table->Set_Title("Rearray Source Primer Plate Count <BR> Rearray IDs: $title_str");
    $table->Toggle_Colour('off');
    $table->Set_Border('on');
    $table->Set_Headers( [ 'Primer Plate Name', 'Solution ID', "Max Count" ] );
    $table->Set_sub_title( 'Primer Plate', 2, 'mediumyellowbw' );
    $table->Set_sub_title( 'Usage',        1, 'lightredbw' );
    foreach my $primer_plate_name ( keys %primer_info ) {
        my $solution_id = $primer_info{$primer_plate_name}{'solution_id'};
        my $count       = $primer_info{$primer_plate_name}{'count'};

        $table->Set_Row( [ $primer_plate_name, "sol$solution_id", $count ] );
    }
    my $output;
    $output .= $table->Printout("$alDente::SDB_Defaults::URL_temp_dir/Rearray_primer_plate_count@{[timestamp()]}.html");
    $output .= $table->Printout(0);
    return $output;
}

###############################
sub _linkto_order_by_encoding {
###############################
    my $dbc          = shift;
    my $rearray      = shift;
    my $field_name   = shift;
    my $order_clause = shift;

    return Link_To( $dbc->config('homelink'), "$field_name", "&Request_ID=$rearray&Expand+ReArray+View=1&Order=$order_clause", "black" );

}

###############################################################
# Subroutine: Confirms remapping of a primer plate and queries for name and notes.
# Return: none
###############################################################
sub confirm_remap_primer_plate {
    my %args            = &filter_input( \@_ );
    my $dbc             = $args{-dbc};
    my $rearray_ids_ref = $args{-rearray_ids};

    # first, check to see if the rearray does not need to be remapped
    # if its Primer_Plate matches the Rearray exactly, then there is no need
    # error out if this happens
    my $error = 0;
    $rearray_ids_ref = &unique_items($rearray_ids_ref);
    foreach my $id ( @{$rearray_ids_ref} ) {
        my %well_info = $dbc->Table_retrieve(
            "ReArray,ReArray_Request,Plate_PrimerPlateWell,Primer_Plate_Well",
            [ "Target_Well", "Well as Primer_Well" ],
            "WHERE ReArray_Request_ID=$id AND FK_ReArray_Request__ID=ReArray_Request_ID AND (FKTarget_Plate__ID=FK_Plate__ID AND Plate_Well=Target_Well) AND FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID"
        );
        my $counter   = 0;
        my $can_remap = 0;
        while ( exists $well_info{"Target_Well"}[$counter] ) {
            if ( $well_info{"Target_Well"}[$counter] ne $well_info{"Primer_Well"}[$counter] ) {
                $can_remap = 1;
                last;
            }
            $counter++;
        }
        if ( $can_remap == 0 ) {
            $dbc->warning("Primer Plate already in correct configuration for Rearray $id");
            $error = 1;
        }
    }
    if ($error) {
        return;
    }

    print &alDente::Form::start_alDente_form( $dbc, "Remap_Confirm", $dbc->homelink() );
    foreach my $id ( @{$rearray_ids_ref} ) {
        my @retval            = $dbc->Table_find_array( "ReArray_Request,Plate", ["concat(FK_Library__Name,'-',Plate_Number)"], "WHERE FKTarget_Plate__ID=Plate_ID AND ReArray_Request_ID=$id" );
        my $target_name       = $retval[0];
        my @numplates         = $dbc->Table_find( "Primer_Plate", "Primer_Plate_ID", "WHERE Primer_Plate_Name like '$target_name.PrimerPlate%'" );
        my $primer_plate_name = "${target_name}.PrimerPlate." . ( scalar(@numplates) + 1 );
        my $table             = new HTML_Table();
        $table->Set_Title("Remap Information for Rearray $id ($target_name)");
        $table->Set_Row( [ "Primer Plate Name:", $primer_plate_name ] );
        $table->Set_Row( [ "Notes:", textfield( -name => "Notes_$id" ) ] );
        $table->Printout();
        print hidden( -name => "Request_ID",            -value => $id );
        print hidden( -name => "Primer_Plate_Name_$id", -value => $primer_plate_name );
    }

    # set hidden fields to trigger update
    print hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App' );
    print hidden( -name => "Confirm",         -value => 1 );
    print hidden( -name => "rm",              -value => "Create Remapped Custom Primer Plate" );
    print submit( -name => "Confirm Primer Plates", -style => "background-color:red" );

    print end_form();
}

########################################
# Subroutine: Prompts for the maximum number of source plates for a multiprobe
# RETURN: none
########################################
sub prompt_multiprobe_limit {
########################################
    my %args = &filter_input( \@_, -args => 'rearray_id,primer_plate_id,type' );

    my $rearray_id      = $args{-rearray_id};         # (Scalar) rearray id for this primer multiprobe
    my $primer_plate_id = $args{-primer_plate_id};    # (Scalar) primer plate id for this primer multiprobe
    my $type            = $args{-type};               # (Scalar) Type of multiprobe file. One of DNA or Primer
    my $dbc             = $args{-dbc};

    my $output = alDente::Form::start_alDente_form( -dbc => $dbc, -name => "Multiprobe Prompt" );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App' );

    my $table = new HTML_Table();
    $table->Set_Title("Additional Information (if applicable)");
    $table->Set_Row( [ 'Max number of source plates', &textfield( -name => 'SourceLimit' ) ] );
    $table->Set_Row( [ '', &submit( -name => 'rm', -value => 'Generate Multiprobe', -class => "Std" ) ] );
    $output .= $table->Printout(0);
    if ($rearray_id) {
        $output .= hidden( -name => "Rearray ID", -value => $rearray_id );
    }
    elsif ($primer_plate_id) {
        $output .= hidden( -name => "Primer Plate ID", -value => $primer_plate_id );
    }
    $output .= hidden( -name => "Multiprobe Type", -value => $type );
    $output .= end_form();

    return $output;
}

###############################################################
# Subroutine: prompts user for QPIX file options
# RETURN: none
###############################################################
sub prompt_qpix_options {
###############################################################
    my %args        = &filter_input( \@_, -args => "dbc,request" );
    my $rearray_ids = $args{-request};                                # (Scalar) a comma-delimited string of rearray ids to generate a qpix for
    my $dbc         = $args{-dbc};                                    # (ObjectRef) database handle

    my $output = alDente::Form::start_alDente_form( -dbc => $dbc, -name => "QPIX Options" );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App' );
    $output .= hidden( -name => 'Request_ID',      -value => $rearray_ids );

    # prompt user for PO, filetype, and if the order is to be split
    my $table = new HTML_Table();
    $table->Set_Title("Additional information (if applicable)");
    my %type_labels = ( 'Source Only' => 'Source Only (Old)', 'Source and Destination' => 'Source and Destination (New)' );
    $table->Set_Row( [ "File type:", &popup_menu( -name => "Filetype", -values => [ 'Source Only', 'Source and Destination' ], -labels => \%type_labels ) ] );
    $table->Set_Row( [ "Split Files per Rearray:", &checkbox( -name => "Split Files", -label => '' ) ] );
    $table->Set_Row( [ "Max number of source plates", textfield( -name => "Number_Of_Source_Plates", -value => '', -force => 1, -size => 4 ) ] );

    #$table->Set_Row(["Split Files per Quadrant:",&checkbox(-name=>"Split Quadrant",-label=>'')]);
    $table->Set_Row( [ '', &submit( -name => "rm", -value => "Write to QPIX File", -class => "Std" ) ] );
    $output .= $table->Printout(0);
    $output .= end_form();

    return $output;
}
##########################
sub get_qpix_log_files {
##########################
    my %args         = filter_input( \@_, -args => 'dbc,target_plate, logfile_dir', -mandatory => 'target_plate' );
    my $target_plate = $args{-target_plate};
    my @logfile_dirs = @{ $args{-logfile_dir} };
    my $dbc          = $args{-dbc};

    ## Check if the target plate already has Plate Samples
    my ($plate_sample_count) = $dbc->Table_find( 'Plate_Sample', 'count(FK_Sample__ID)', "WHERE FKOriginal_Plate__ID = $target_plate" );
    if ( $plate_sample_count > 0 ) {
        Message("Target plate has already been processed");
        return;
    }

    my @target_log;
    for my $logfile_dir (@logfile_dirs) {

        #@target_log = split '\n', try_system_command(-command=>"grep -nri 'sample destination=\"pla.*$target_plate\"' $logfile_dir/*.XML | grep -v 'Copy of'");
        @target_log = split '\n', try_system_command( -command => "find $logfile_dir/ -name '*.XML' -type f -print0 | xargs -0 grep -nri 'sample destination=\"pla.*$target_plate\"' | grep -v 'Copy of'" );
        last if @target_log;
    }

    unless (@target_log) {
        Message("No log files found for plate: $target_plate");
        return;
    }
    my @source_plates;
    my @target_wells;
    my %logfiles;
    ##  parse the log file
    foreach my $target_log (@target_log) {
        my ( $qpix_file, $line_num, $xml_info ) = split ':', $target_log;
        my $location;
        my $source_plate;

        if ( $xml_info =~ /location=\"(.*?)\".+?source=\"(\w+)\"/ ) {
            $location = $1;
            $source_plate = get_aldente_id( $dbc, $2, 'Plate' );

            #print "$source_plate<BR>";
        }
        $logfiles{$qpix_file}++;
        push( @source_plates, $source_plate );
        push( @target_wells,  $location );
    }
    @target_wells = map { $_ = format_well($_) } @target_wells;

    my $target_well_list = Cast_List( -list => \@target_wells, -to => 'String', -autoquote => 1 );
    my @rearrayed_wells = $dbc->Table_find( 'ReArray,ReArray_Request', 'Target_Well', "WHERE FK_ReArray_Request__ID = ReArray_Request_ID and Target_Well in ($target_well_list) and FKTarget_Plate__ID = $target_plate" );
    if (@rearrayed_wells) {
        my $targeted_wells = Cast_List( -list => \@rearrayed_wells, -to => 'String', -autoquote => 1 );
        Message("Error: These wells have been rearrayed already :  $targeted_wells");
        return;
    }

    ## from tubes
    my @source_wells = ('n/a') x scalar(@source_plates);

    #my ($target_size) = $dbc->Table_find( 'Plate', 'Plate_Size', "WHERE Plate_ID = $target_plate");

    ## preview
    require RGTools::HTML_Table;
    my $preview_qpix_log = HTML_Table->new( -class => 'small' );
    my $title = "Pick from source plates to $target_plate";
    $preview_qpix_log->Set_Title($title);
    my @headers = ( 'Source Plate', 'Source Well', 'Target Well' );
    $preview_qpix_log->Set_Headers( \@headers );
    my $i                = 0;
    my $num_target_wells = scalar(@target_wells);
    $preview_qpix_log->Set_sub_title("$num_target_wells Wells Picked");

    foreach my $source_plate (@source_plates) {
        $preview_qpix_log->Set_Row( [ $source_plate, $source_wells[$i], $target_wells[$i] ] );
        $i++;
    }

    $preview_qpix_log->Set_Row( [ submit( -name => 'rm', -value => 'Confirm QPix Log', -style => "background-color:lightgreen" ) ] );
    my $output = "";
    $output .= alDente::Form::start_alDente_form( $dbc, 'Qpix_Log', $dbc->homelink() );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App' );
    $output .= $preview_qpix_log->Printout(0);
    $output .= hidden( -name => 'Source_Plates', -value => \@source_plates );
    $output .= hidden( -name => 'Source_Wells', -value => \@source_wells );
    $output .= hidden( -name => 'Target_Wells', -value => \@target_wells );
    $output .= hidden( -name => 'Target_Plate', -value => $target_plate );
    my @logfiles = keys %logfiles;
    $output .= hidden( -name => 'Logfiles', -value => \@logfiles );
    $output .= end_form();
    return $output;
}

sub view_rearray_locations {
    my %args        = @_;
    my $dbc         = $args{-dbc};
    my $rearray_ids = $args{-request};      # (Scalar) Rearray ID
    my $group_all   = $args{-group_all};    # (Scalar) if 0, separate into rearrays. Group everything together otherwise.

    # error check
    unless ($rearray_ids) {
        Message("No rearrays specified");
        return;
    }

    my $order = $args{-order} || 'Order by Equipment_Name,Rack_ID,FK_Library__Name,Plate_Number,Plate.Parent_Quadrant';    # (Scalar) order clause

    my @field_list    = ( "concat(FK_Library__Name,'-',Plate_Number,Plate.Parent_Quadrant) as Plate_Name", "FKSource_Plate__ID", "Equipment_Name", "concat(Rack_ID,' : ',Rack_Alias) as Rack_Name" );
    my @field_headers = ( "Plate_Name",                                                                    "FKSource_Plate__ID", "Equipment_Name", "Rack_Name" );
    my $tables        = "ReArray,Plate,Equipment,Rack";

    my @rearray_list = ();
    if ($group_all) {
        @rearray_list = ($rearray_ids);
    }
    else {
        @rearray_list = split ',', $rearray_ids;
    }
    my $output;
    $output .= alDente::Form::start_alDente_form( $dbc, "Rearray Locations", $dbc->homelink() );
    my $all_loc_table = new HTML_Table();
    $all_loc_table->Set_HTML_Header($html_header);

    foreach my $rearray_id ( sort { $a <=> $b } @rearray_list ) {
        my @headers = ( "Plate Name", "Plate ID", "Equipment_Name", "Rack" );
        my $extra_condition = "";

        my %loc_info = &Table_retrieve( $dbc, $tables, \@field_list, "where FK_ReArray_Request__ID in ($rearray_id) AND FKSource_Plate__ID=Plate_ID AND FK_Rack__ID=Rack_ID AND FK_Equipment__ID=Equipment_ID $extra_condition $order DESC", -distinct => 1 );

        # hash mapping between a source plate and a mul barcode (if a mul barcode exists)
        my %source_plate_to_mul;

        # search for all the mul barcodes
        # get all the source plates
        my @source_plates = @{ &RGTools::RGIO::unique_items( $loc_info{"FKSource_Plate__ID"} ) };

        my $tray = alDente::Tray->new( -dbc => $dbc, -plates => join( ',', @source_plates ) );

        foreach (@source_plates) {
            $source_plate_to_mul{$_} = 'Tra' . $tray->{plates}{$_}{tray};
        }

        my @target_plates = $dbc->Table_find( "ReArray_Request", "FKTarget_Plate__ID", "WHERE ReArray_Request_ID in ($rearray_id)" );
        my $target_plate_str = '';
        foreach my $plate (@target_plates) {
            $target_plate_str .= &get_FK_info( $dbc, "FK_Plate__ID", $plate ) . "<BR>\n";
        }

        my @comments = $dbc->Table_find( "ReArray_Request", "ReArray_Comments", "WHERE ReArray_Request_ID in ($rearray_id)" );
        my $comments_str = '';
        foreach my $comment (@comments) {
            $comments_str .= "$comment <BR>\n";
        }

        my $Table = new HTML_Table( -autosort => 1 );

        $Table->Set_Title( "Rearray $rearray_id<BR>" . "$target_plate_str" . "Comments: $comments_str" );
        $Table->Set_Headers( \@headers );
        $Table->Set_Border(1);
        $Table->Toggle_Colour('off');
        $Table->Set_sub_title( 'Plate',    2, 'mediumgreenbw' );
        $Table->Set_sub_title( 'Location', 2, 'lightredbw' );
        my $idfield;
        my $colour;
        my $colour1 = 'vlightyellowbw';
        my $colour2 = 'lightyellowbw';

        my @source_ids = $loc_info{FKSource_Plate__ID} ? @{ $loc_info{FKSource_Plate__ID} } : undef;
        my $count = 0;

        foreach my $row (@source_ids) {

            my $field  = 0;
            my @fields = ();
            foreach my $field (@field_headers) {
                my $field_value = $loc_info{$field}[$count];
                if ( $field eq "FKSource_Plate__ID" ) {
                    if ( defined $source_plate_to_mul{$field_value} ) {
                        $field_value .= "($source_plate_to_mul{$field_value})";
                    }
                }
                push( @fields, $field_value );
            }

            for ( 0 .. 1 ) {
                $fields[$field] = "<span class='mediumredtext'><B>$fields[$field]</B></span>";
                $field++;
            }
            for ( 2 .. 3 ) {
                $fields[$field] = "<span><B>$fields[$field]</B></span>";
                $field++;
            }
            $Table->Set_Row( \@fields, $colour );
            $count++;
        }

        $all_loc_table->Set_Row( [ $Table->Printout(0) ] );
        $output .= hidden( -name => 'Request_ID', -value => $rearray_id );
    }
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App' );

    $output .= submit( -name => 'rm', -value => "View rearray source plates in one table", -style => "background-color:lightgreen" ) . br() unless ($group_all);
    $output .= $all_loc_table->Printout("$alDente::SDB_Defaults::URL_temp_dir/Re_Array_Locations@{[timestamp()]}.html");
    $output .= $all_loc_table->Printout(0);
    $output .= end_form();
    return $output;
}

################
sub pool_wells {
################
    my %args        = filter_input( \@_, -args => 'dbc,plate_id', -mandatory => 'dbc,plate_id,target_size' );
    my $dbc         = $args{-dbc};
    my $plate_ref   = $args{-plate_id};
    my $target_size = $args{-target_size};
    my $batch       = $args{-batch};
    my $library     = $args{-library};                                                                          ## optional specification of target library ...
    my $on_conflict = $args{-on_conflict};
    my $hybrid      = $args{-hybrid};
    my $test     = $args{-test};       ## flag indicating we are only prompting for user input at this stage...                                                                     ## handling details for pooling conflict
    my $transfer = $args{-transfer};

    my @plate_ids = Cast_List( -list => $plate_ref, -to => 'array' );
    my $plate_list = join ',', @plate_ids;

    my @libraries = $dbc->Table_find( 'Plate', 'FK_Library__Name', "WHERE Plate_ID IN ($plate_list)", -distinct => 1 ) if $plate_list !~ /$Prefix{Tray}/i;
    if ( int(@libraries) == 1 ) { $library ||= $libraries[0] }

    my $output = alDente::Form::start_alDente_form( -dbc => $dbc );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App' );
    if ($batch) { $output .= hidden( -name => 'batch', -value => $batch ) }

    my $library_prompt;
    my $lib_element_name;
    if ($library) {
        $library_prompt = popup_menu( -name => 'FK_Library__Name', -id => 'FK_Library__Name', -values => [$library], -force => 1 );
        $lib_element_name = 'FK_Library__Name';
    }
    else {
        $library_prompt = alDente::Tools->search_list( -dbc => $dbc, -element_id => 'FK_Library__Name', -form => 'ReArray', -name => 'FK_Library__Name', -default => '', -search => 1, -filter => 1, -breaks => 1 );
        $lib_element_name = 'FK_Library__Name Choice';
    }

    my $pipeline;
    my @pipelines = $dbc->Table_find_array( 'Plate', ['FK_Pipeline__ID'], "where Plate_ID in ($plate_list)", -distinct => 1 ) if $plate_list !~ /$Prefix{Tray}/i;
    if ( @pipelines && int(@pipelines) == 1 ) { $pipeline = $pipelines[0] }    ## preset pipeline if it is distinct

    my $max_row;
    my $max_col;
    my $plate_size;
    my $plate_format_box;
    my $tube;

    my $instructions = "To ReArray/Pool: Select well(s) to pool/rearray on left and then Click on Target well on right to apply";
    if ( $target_size =~ 96 ) {
        $max_row    = 'H';
        $max_col    = '12';
        $plate_size = $target_size;
        $output .= hidden( -name => 'Target_Plate_Size', -value => $target_size );
        $plate_format_box = alDente::Tools->search_list( -dbc => $dbc, -form => 'ReArray', -name => 'FK_Plate_Format__ID', -default => '', -search => 1, -filter => 1, -breaks => 1, -option_condition => "Wells like '96'" );
    }
    elsif ( $target_size =~ 384 ) {
        $max_row    = 'P';
        $max_col    = '24';
        $plate_size = $target_size;
        $output .= hidden( -name => 'Target_Plate_Size', -value => $target_size );
        $plate_format_box = alDente::Tools->search_list( -dbc => $dbc, -form => 'ReArray', -name => 'FK_Plate_Format__ID', -default => '', -search => 1, -filter => 1, -breaks => 1, -option_condition => "Wells like '384'" );
    }
    else {    #Tube
        $max_row = 'A';
        $max_col = '1';
        $output .= hidden( -name => 'pool to tube', -id => 'pool_to_tube', -value => 1 );
        $plate_format_box = alDente::Tools->search_list( -dbc => $dbc, -form => 'ReArray', -name => 'FK_Plate_Format__ID', -default => '', -search => 1, -filter => 1, -breaks => 1, -option_condition => "Plate_Format_Style = 'Tube'" );
        $tube             = 1;
        $instructions     = "To ReArray/Pool: Select well(s) to pool/rearray on left and then Apply using 'ReArray/Pool Selected Samples' Button on right";
    }

    my $current_date = &now();

    ## Table for target plate information (library, format, etc)
    my $ReArray = HTML_Table->new();
    $ReArray->Set_Alignment( 'right', 1 );
    $ReArray->Set_Title( '<B>Creating ReArrayed Plate from Current Request</B>', class => 'lightredbw' );
    $ReArray->Toggle_Colour(0);

    $ReArray->Set_Row( [ 'Library', alDente::Tools->search_list( -dbc => $dbc, -form => 'ReArray', -name => 'FK_Library__Name', -default => 'INX538', -search => 1, -filter => 1, -breaks => 1 ) ] ) if !$tube;
    $ReArray->Set_Row( [ 'Plate/Tube Size', "$plate_size" ] ) if $plate_size;
    $ReArray->Set_Row( [ "Plate/Tube Format:", $plate_format_box ] );
    $ReArray->Set_Row( [ "Location:",          alDente::Tools->search_list( -dbc => $dbc, -form => 'ReArray', -name => 'FK_Rack__ID', -default => '', -search => 1, -filter => 1, -breaks => 1 ) ] );
    $ReArray->Set_Row( [ "Created:",           "$current_date" ] );

    #if ($pipeline) {
    #    $ReArray->Set_Row( [ '<B>Pipeline:</B>', alDente::Tools::alDente_ref( 'Pipeline', $pipeline, -dbc => $dbc ) . hidden( -name => 'FK_Pipeline__ID', -value => $pipeline, -force => 1 ) ] );
    #}
    #else {
    $pipeline = &get_FK_info( $dbc, "FK_Pipeline__ID", $pipeline );
    $ReArray->Set_Row( [ '<B>Pipeline:</B>', alDente::Tools->search_list( -dbc => $dbc, -form => 'ReArray', -name => 'FK_Pipeline__ID', -default => $pipeline, -search => 1, -filter => 1, -breaks => 1, -filter_by_dept => 1 ) ] );

    #}

    $output .= $ReArray->Printout(0);
    $output .= lbr();

    ###########################################
    ## Add specs to handle pooling conflicts ##
    ###########################################
    if ($hybrid) {
        ## option for hybrid libraries ##

        $library_prompt = "<div id='Lib.Prompt' style='display:none'>$library_prompt</div>\n";

        $library_prompt .= "<div id='hybrid' style='display:none'>"
            . radio_group(
            -name    => 'hybrid',
            -value   => 'auto-generate hybrid library',
            -onclick => "unHideElement('hybrid.Lib'); HideElement('Lib.Prompt'); HideElement('hybrid'); unHideElement('existing'); unset_mandatory_validators(this.form,'$lib_element_name'); set_mandatory_validators(this.form,'OC.*');"
            ) . "</div>\n";

        $library_prompt .= "<div id='existing' style='display:block'>"
            . radio_group(
            -name    => 'hybrid',
            -id      => 'existing',
            -value   => 'choose existing library',
            -onclick => " HideElement('hybrid.Lib'); unHideElement('Lib.Prompt'); unHideElement('hybrid'); HideElement('existing'); set_mandatory_validators(this.form,'$lib_element_name'); unset_mandatory_validators(this.form,'OC.*'); "
            ) . "</div>\n";

        my $cleaned_plate_list = alDente::Tray::convert_tray_to_plate( -dbc => $dbc, -barcode => $plate_list );
        if ( $cleaned_plate_list =~ s/^Pla(\d+)/$1/i ) { $cleaned_plate_list =~ s/Pla/,/ig }    ## convert scannable pla list to ids ##
        $dbc->message($cleaned_plate_list);

        my ( %conflicts, %preset );
        alDente::Container::merge_libs( -dbc => $dbc, -plate_id => $cleaned_plate_list, -preset => \%preset, -unresolved => \%conflicts, -on_conflict => $on_conflict, -test => $test );

        $output .= "<div id='hybrid.Lib' style='display:block'>\n";
        $output .= alDente::Form::merging_info( -dbc => $dbc, -preset => \%preset, -conflicts => \%conflicts, -ignore => 'FK_Original_Source__ID,FK_Library__Name' );
        $output .= "<P></div>\n";
    }
    else {
        $output .= set_validator( -name => $lib_element_name, -mandatory => 1, -prompt => 'Library Required' );
    }

    if ($transfer) {
        $output .= hidden( -name => 'Transfer', -value => $transfer );
    }

    ############################################
    ############################################
    $output .= set_validator( -name => 'FK_Plate_Format__ID', -mandatory => 1, -prompt => "Require Plate/Tube Format" );
    $output .= set_validator( -name => 'FK_Pipeline__ID',     -mandatory => 1, -prompt => "Require Pipeline" );

    #    $output .= set_validator( -name => 'poolTargetWells',     -mandatory => 1, -prompt => "Require Pipeline" );

    ## Start table for choosing wells from source plates and set them to wells to target plate
    my $rearray_action = RGTools::Web_Form::Submit_Button(
        name         => 'rm',
        value        => 'Submit ReArray/Pool Request',
        class        => 'Action',
        validate     => 'poolTargetWells',
        form         => 'thisform',
        validate_msg => 'Please enter target well information by selecting source wells (left hand side) and click on the target well (right hand side)',
        onClick => "return validateForm(this.form);"    ## if (!getElementValue(document.thisform,\'$lib_element_name\')) {alert(\'Missing $lib_element_name\'); return false;}
    );

    my $allTables = HTML_Table->new( -title => "Select Wells from Source Plates/Tubes to ReArray/Pool to Target Plates<BR>$rearray_action", -border => 1 );
    $allTables->Set_Headers( [ 'Source', 'Target' ] );
    $allTables->Set_sub_header( $instructions, 'lightredbw' );

    my $clearwell;
    for my $plate_id (@plate_ids) {
        $clearwell .= "SetSelection(this.form,\"Wells$plate_id\",0,\"all\");";
    }

    ## Source plates table
    my $clear = button( -name => 'Clear Selected List', onClick => $clearwell, -class => 'Std' );
    my $sourceTables = HTML_Table->new( -title => "Source Plates/Tubes $clear" );

    #print HTML_Dump \@plate_ids;
    for my $plate_id (@plate_ids) {
        my ($type) = $dbc->Table_find( 'Plate', 'Plate_Type', "WHERE Plate_ID = $plate_id" ) if $plate_id !~ /$Prefix{Tray}/i;

        my ( $min_row, $max_row, $min_col, $max_col, $size );
        my %availability;
        my $plate_type;
        my $prefix = $Prefix{Plate};
        my $plate_box;

        my $title = "Select Wells to ReArray for $prefix$plate_id";
        if ( $plate_id =~ /$Prefix{Tray}/i ) {
            my $tray_view = alDente::Tray_Views->new( -dbc => $dbc );
            $plate_box = $tray_view->tray_of_tube_box( -tray_id => $plate_id );
        }
        elsif ( $type eq 'Library_Plate' ) {
            ( $min_row, $max_row, $min_col, $max_col, $size ) = &alDente::Well::get_Plate_dimension( -dbc => $dbc, -plate => $plate_id );
            my @plate_info_fields = ( 'No_Grows', 'Slow_Grows', 'Unused_Wells', 'Problematic_Wells', 'Empty_Wells', 'Plate_Size' );
            my %wells = $dbc->Table_retrieve( 'Plate,Library_Plate', \@plate_info_fields, "WHERE Library_Plate.FK_Plate__ID=Plate_ID AND Plate_ID IN ($plate_id)" );
            my ( @NGs, @SGs, @Us, @Ps, @Es );
            @NGs = map { &format_well( $_, 'nopad' ) } split( ',', $wells{No_Grows}[0] );
            @SGs = map { &format_well( $_, 'nopad' ) } split( ',', $wells{Slow_Grows}[0] );
            @Us  = map { &format_well( $_, 'nopad' ) } split( ',', $wells{Unused_Wells}[0] );
            @Ps  = map { &format_well( $_, 'nopad' ) } split( ',', $wells{Problematic_Wells}[0] );
            @Es  = map { &format_well( $_, 'nopad' ) } split( ',', $wells{Empty_Wells}[0] );

            for my $well (@Us) {
                $availability{$well} = 0;
            }

            my @sample_wells = $dbc->Table_find( 'Plate_Sample,Plate', 'Well', "WHERE Plate_Sample.FKOriginal_Plate__ID = Plate.FKOriginal_Plate__ID AND Plate_ID IN ($plate_id)" );
            my $sample_well_s = join ",", @sample_wells;
            $sample_well_s = &format_well($sample_well_s);
            my @wells_no_sample = &alDente::Library_Plate::not_wells( $sample_well_s, $wells{Plate_Size}[0] );
            for my $well (@wells_no_sample) {
                $well = &format_well( $well, 'nopad' );
                $availability{$well} = 0;
            }
            $prefix    = "Pla";
            $plate_box = &alDente::Container_Views::select_wells_on_plate(
                -dbc          => $dbc,
                -table_id     => 'Select_Wells',
                -max_row      => $max_row,
                -max_col      => $max_col,
                -input_type   => 'checkbox',
                -availability => \%availability,
                -plate_id     => $plate_id,
            );
        }
        else {
            ### simpler view for Tubes ###
            $max_row = 'A';
            $max_col = '01';

            $title     = "Tube: $prefix$plate_id";
            $plate_box = Views::Table_Print(
                -return_html => 1,
                content      => [
                    [   alDente::Container_Views::foreign_label( -plate_id => $plate_id, -dbc => $dbc ),
                        'Select Tube:' . Show_Tool_Tip( checkbox( -id => "Wells$plate_id", -name => "Wells$plate_id", -value => 'A1', -label => '', -checked => 0, -force => 1 ), "Select this sample well/tube for pooling/rearraying" )
                    ]
                ]
            );
        }

        my $req = HTML_Table->new( -title => $title );
        $req->Set_Row(
            [   create_tree(
                    -tree         => { "$prefix$plate_id" => $plate_box },
                    -default_open => ["$prefix$plate_id"]
                )
            ]
        );
        $sourceTables->Set_Row( [ $req->Printout(0) ] );
    }

    #print $sourceTables->Printout(0);

    ## Target plate table
    my $target_action = Show_Tool_Tip( button( -name => 'Clear Target List', onClick => "SetSelection(this.form,\"poolTargetWells\",'',\"all\");", -class => 'Std' ), "Clear List of Selected Wells Below for All Target Tube(s)" );
    my $add_action = Show_Tool_Tip( button( -name => 'ReArray/Pool Selected Samples', onClick => "addPool('target_table','pool_to_tube','Submit ReArray/Pool Request');", -class => "Std" ), "Apply Wells Selected at Left to next available Tube" );
    my $remove_action = button( -name => 'Remove Last ReArray/Pool Entry', onClick => "remove_row('target_table', 2, 'pool_to_tube');", -class => "Std" );
    my $target_table = HTML_Table->new( -title => "Target Plate(s)/Tube(s) $target_action", -id => 'target_table' );

    for my $row ( 'A' .. $max_row ) {
        my $row_textbox;    ## only for non-tube targets...
        for my $col ( 1 .. $max_col ) {
            my $textbox
                = Show_Tool_Tip( textfield( -id => "Target$row$col", -name => "poolTargetWells", -value => '', -size => 70, -force => 1, -onClick => "fill_single_well(this.form,'Target$row$col');" ), "Click here to apply currently selected wells" );
            my $label = &format_well("$row$col");
            $label = "Tube" if $tube;

            if ($tube) {
                $target_table->Set_Row( [ $label . &hspace(3) . $textbox, 'Library:', $library_prompt ] );
            }
            else {
                $textbox = Show_Tool_Tip( $textbox, "Click on target well position to pool/rearray selected samples here" );
                $row_textbox .= $label . &hspace(3) . $textbox . lbr;
            }
        }
        $target_table->Set_Row( [ create_tree( -tree => { $row => $row_textbox }, -default_open => [$row] ) ] ) if !$tube;
    }

=for comment
    $target_table->Set_Row([&alDente::Container_Views::select_wells_on_plate(-table_id=>'Select_Wells',
                                                                 -max_row=>'H',
                                                                 -max_col=>'12',
								 -input_type=>'text',
                                                                 -action       => 'fill_wells',
                                                                 -fill_single_well => 1,
                                                                        )]);
=cut

    my @row = ( $sourceTables->Printout(0) );
    if ($tube) { push @row, &vspace(50) . $add_action . &vspace(50) . $remove_action }
    push @row, $target_table->Printout(0);

    $allTables->Set_Row( \@row );
    $allTables->Set_VAlignment('top');

    #    $allTables->Set_Column( [ $sourceTables->Printout(0) ] );
    #    $allTables->Set_Column( [ &vspace(50) . $add_action . &vspace(50) . $remove_action ] ) if $tube;
    #    $allTables->Set_Column( [ $target_table->Printout(0) ] );
    $output .= $allTables->Printout(0);
    $output .= end_form();
    return $output;

}

sub confirm_create_pool_wells_rearray_page {
    my %args = filter_input( \@_, -args => 'dbc,query', -mandatory => 'dbc,query' );
    my $dbc  = $args{-dbc};
    my $q    = $args{-query};

    my $library = get_Table_Params( -field => 'FK_Library__Name', -dbc => $dbc );

    #$library = $dbc->get_FK_ID( 'FK_Library__Name', $library );
    my $format_id = get_Table_Param( -field => 'FK_Plate_Format__ID', -dbc => $dbc );
    $format_id = $dbc->get_FK_ID( 'FK_Plate_Format__ID', $format_id );
    my $target_rack = get_Table_Param( -field => 'FK_Rack__ID', -dbc => $dbc );
    $target_rack = $dbc->get_FK_ID( 'FK_Rack__ID', $target_rack );
    my $pipeline = get_Table_Param( -field => 'FK_Pipeline__ID', -table => 'Plate', -dbc => $dbc );
    $pipeline = $dbc->get_FK_ID( "FK_Pipeline__ID", $pipeline );

    my $target_plate_size = $q->param('Target_Plate_Size');
    my @pool_wells        = $q->param('poolTargetWells');
    my $pool_to_tube      = $q->param('pool to tube');
    my $batch             = $q->param('batch');
    my $transfer          = $q->param('Transfer');

    #print HTML_Dump $q, $library, $format_id, $target_rack, $pipeline;

    my $output = alDente::Form::start_alDente_form( -dbc => $dbc, -name => "Confirm" );
    $output .= hidden( -name => 'Library_Name',      -value => $library );
    $output .= hidden( -name => 'Plate_Format_ID',   -value => $format_id );
    $output .= hidden( -name => 'Rack_ID',           -value => $target_rack );
    $output .= hidden( -name => 'Pipeline_ID',       -value => $pipeline );
    $output .= hidden( -name => 'Target_Plate_Size', -value => $target_plate_size );
    $output .= hidden( -name => 'pool to tube',      -value => $pool_to_tube );
    $output .= hidden( -name => 'batch',             -value => $batch );
    $output .= hidden( -name => 'Transfer',          -value => $transfer );
    for my $pool_well (@pool_wells) { $output .= hidden( -name => 'poolTargetWells', -value => $pool_well ); }
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App' );
    $output .= hidden( -name => 'confirmed',       -value => 1 );
    $output .= submit( -name => 'rm', -value => 'Confirmed ReArray/Pool Request', class => 'Action' );
    $output .= end_form();
    return $output;
}

####################
sub indices_and_other_fields_view {
####################
    my %args        = filter_input( \@_ );
    my $dbc         = $args{-dbc};
    my $data_ref    = $args{-data_ref};
    my $num_rows    = @{ $args{-num_rows} };
    my $header_ref  = $args{-header_ref};                                        #array ref
    my $plate_id    = $args{-plate_id};
    my @missing_col = @{ $args{-missing_col} } if defined $args{-missing_col};

    my $index_out = alDente::Form::start_alDente_form( -dbc => $dbc );
    $index_out .= hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App' );

    my $index = HTML_Table->init_table( -title => "Summary for $plate_id", -width => 800, -toggle => 'on' );

    $index->Set_Border(1);

    $index->Load_From_Hash( -headers => $header_ref, -data => $data_ref, -sort_by => "sample_id", order => "asc" );

    foreach my $col (@missing_col) {
        $index->Set_Column_Colour( $col, "#FBB450", $num_rows );
    }

    $index_out .= $index->Printout(0);
    $index_out .= end_form();

    return $index_out;
}

return 1;
