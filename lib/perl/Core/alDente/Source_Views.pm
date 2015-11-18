#
# Source_Views.pm #
####################
#
# This contains various source view pages directly
#

package alDente::Source_Views;

use base alDente::Object_Views;

use strict;
use RGTools::RGIO;
use RGTools::RGmath;
use SDB::HTML;
use SDB::CustomSettings;
use alDente::Tools;
use LampLite::Bootstrap;

use CGI qw(:standard);
use vars qw(%Configs %Settings $scanner_mode );

my $q  = new CGI;
my $BS = new Bootstrap();

#########################
# Quick method of generating multiple new Plate records from a (non-tracked) source
#
# This method generates a generic source record along with plate records as required.
#
# Options enable reception of plates in multiple formats at the same time
#
# Barcodes are generated at this time for the plates if applicable
#
#########################
sub receive_Samples {
#########################
    my %args        = &filter_input( \@_ );
    my $dbc         = $args{-dbc};
    my $options     = $args{-options};                                   ## Options for format eg {'1' => 2} (2 tubes of format 1)
    my $preset      = $args{-preset};
    my $sample_type = $args{-sample_type} || $q->param('Sample_Type');
    my $rack        = $args{-rack};                                      ## optional rack to start on
    my $origin      = $args{-origin};                                    ## optional original_source record if known.
    my $lib         = $args{-library};
    my $q           = new CGI;

    my ($sample_type_id) = $dbc->Table_find( 'Sample_Type', 'Sample_Type_ID', "WHERE Sample_Type = '$sample_type'" );    ## sample types should include all source types (and optionally more)

    $origin ||= $q->param('Original_Source_ID');
    $rack   ||= $q->param('Rack_ID');

    use RGTools::Views;
    my %Defaults;
    my @formats;

    my ( $date, $time ) = split ' ', date_time();
    $args{-preset} = $preset;

    my ($no_barcode) = $dbc->Table_find( 'Barcode_Label', 'Barcode_Label_ID', "WHERE Label_Descriptive_Name = 'No Barcode'" );
    my ($virtual_format) = $dbc->Table_find( 'Plate_Format', 'Plate_Format_ID', "WHERE Plate_Format_Type = 'Virtual Tube'", -limit => 1 );    ## <construction> change to virtual tube (need to create record)

    $args{-omit} = {
        'Source_Status'         => 'Active',
        'Current_Amount'        => '',
        'Original_Amount'       => '',
        'Amount_Units'          => '',
        'FK_Plate_Format__ID',  => $virtual_format,
        'FK_Barcode_Label__ID', => $no_barcode,
        'Source_Label'          => '',
        'Received_Date'         => "$date $time",
        'FKSource_Plate__ID'    => '',
        'FKParent_Source__ID'   => '',
        'Source_Number'         => '',
    };

    $args{-preset} = { 'External_Identifier' => '', };

    $args{-grey} = {
        'FK_Sample_Type__ID'      => $sample_type,
        'FKReceived_Employee__ID' => $dbc->get_FK_info( 'FK_Employee__ID', $dbc->get_local('user_id') ),
    };

    if ($rack) {
        $args{-omit}{FK_Rack__ID} = $dbc->get_FK_info( 'FK_Rack__ID', $rack );
    }
    if ($origin) {
        $args{-grey}{FK_Original_Source__ID} = $dbc->get_FK_info( 'FK_Original_Source__ID', $origin );
    }

    if ($options) {
        @formats = keys %$options;
        foreach my $id (@formats) {
            $Defaults{$id} = $options->{$id};
        }
    }

    my $form = SDB::HTML::query_form( -dbc => $dbc, %args, -table => 'Source', -return_html => 1, -submit => 0, -reset => 1 );

    if ( !@formats ) { @formats = $dbc->Table_find( 'Plate_Format', 'Plate_Format_ID' ) }

    my $types;
    foreach my $format (@formats) {
        my ( $id, $name ) = split ',', $format;

        #	if ($options && ! grep /\b$id\b/, @formats) { next }
        $name = $dbc->get_FK_info( 'FK_Plate_Format__ID', $id );
        $types .= '<BR>' . $q->textfield( -name => "Received $id", -size => 2, -default => $Defaults{$id}, -force => 1 ) . ' x ' . $name;
    }

    $types .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Source_App' );

    use alDente::Form;
    my $page = alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Collect_Samples' ) . $form . 'Sample Containers: <BR>' . $types;

    # Views::Table_Print(content=>[[$form,$types]],print=>0)
    if ($lib) { $page .= $q->hidden( -name => 'FK_Library__Name', -value => $lib ) }
    else {
        $page .= '<P>Associate with Collection: ' . alDente::Tools::search_list( -dbc => $dbc, -name => 'FK_Library__Name', -dbc => $dbc ) . set_validator( -name => 'FK_Library__Name', -mandatory => 1 ) . '<P>';
    }

    $page
        .= $q->hidden( -name => 'Plate_Created',      -value => &date_time() )
        . $q->hidden( -name  => 'FK_Sample_Type__ID', -value => $sample_type_id )
        . vspace(3)
        . $q->submit( -name => 'rm', -value => 'Generate Barcodes', -class => 'Action', -onClick => 'return validateForm(this.form)' )
        . $q->end_form();

    return $page;
}

##############################
# Home page for individual sources
##############################
sub home_page {
##############################
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'dbc,Source' );
    my $q      = new CGI;
    my $dbc    = $args{-dbc};
    my $Source = $args{-Source};
    my $id     = $args{-id};
    my $list   = $args{-list} || '';

    my @pool_srcs = '';

    my $info;
    my $details;
    my $header;

    my $hybrid = 0;
    my %layers;

    $dbc->Benchmark('source_home');
    if ( $id =~ /,/ ) { $list = $id }

    ## customized validation ##
    $Source ||= new alDente::Source( -dbc => $dbc, -id => $id );
    $id ||= $Source->value('Source.Source_ID');

    if ( $Source->is_reserved( -id => $id ) ) {
        Message "Found 'Reserved' source ids, defaulting to simple home page";
        return view_reserved_sources( -id => $id, -dbc => $dbc );
    }

    $dbc->debug_message("This method should be phased out ... should be directed via alDente::Object_App to display_record_page (or generic_page)");

    my $class  = 'alDente::Source';
    my $Object = $class->new( -dbc => $dbc, -id => $id );
    my $page   = $Object->View->std_home_page( -dbc => $dbc, -id => $id );    ## std_home_page generates default page, with customizations possible via local single/multiple/no _record_page method ##

    SDB::Errors::log_deprecated_usage('Source Home Page');

    return $page;
}

#
# Standard wrapper to display standard record home pages
# (Valid for both single record or multiple record home pages)
#
# Return: home page string
#############################
sub display_record_page {
#############################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'Source' );
    my $Source    = $args{-Source} || $args{-Object} || $self->Model();    ## not necessary ...
    my $dbc       = $args{-dbc} || $self->{dbc};
    my $source_id = $args{-id} || $self->{id};
    my $detailed  = $args{-detailed};

    my $src_list = Cast_List( -list => $source_id, -to => 'string' );
    my @srcs     = Cast_List( -list => $src_list,  -to => 'array' );
    ###################################################################################################################
    ### Label - defaults to using standard object_label method (not necessary to define here unless overriding this ###
    ###################################################################################################################
    my ( $label, $links, $right );

    ###############
    ### Layers ###
    ###############
    my @layers;
    push @layers, { label => 'Standard', content => $self->single_standard_options( -dbc => $dbc, -ids => $src_list, -source => $Source ) };
    push @layers, { label => 'Lab', content => single_Lab( $dbc, $src_list ) };
    push @layers, { label => 'Alerts', content => display_Source_Alerts( -dbc => $dbc, -id => $src_list ) };

    if ( $self->objects() > 1 ) {
        push @layers, { label => 'DB Record', content => multiple_Source( $dbc, $src_list ) };

        my ( $src_type, $valid ) = ( 'Ligation', 0 );
        my @source_types = $dbc->Table_find( 'Source', 'FK_Sample_Type__ID', "where Source_ID in ($src_list)", 'Distinct' );
        if ( scalar(@source_types) == 1 ) {
            $src_type = $source_types[0];
            $valid    = 1;
        }

        push @layers, { label => 'Pool Sources', content => $self->pool_sources( -dbc => $dbc, -source_id => \@srcs ) };
    }

    if ( $dbc->config('screen_mode') =~ /desktop/ ) {
        ## Only available on desktop modes - excluded in mobile modes to speed up ##

        if ( $self->objects() == 1 ) {
            ## when only showing data for a single record ##
            push @layers, { label => 'Active Samples', content => active_Samples( $dbc, $source_id ) };
            push @layers, { label => 'Work Request', content => display_WR_info( -dbc => $dbc, -id => $source_id ) };
            push @layers, { label => 'Redefine as Plates', content => redefine_as_Plates( -source_id => $source_id, -dbc => $dbc ) };

            ## Samples Layer ##
            my $auto_display = 200;    ## maximum number of samples to show
            my ($count) = $dbc->Table_find( 'Sample', 'Count(*)', "WHERE FK_Source__ID IN ($source_id)", -return_html => 1, -title => 'Associated Samples' );

            if ( $count <= $auto_display ) {
                push @layers, { label => 'Samples', content => $dbc->Table_retrieve_display( 'Sample', ['*'], "WHERE FK_Source__ID IN ($source_id)", -return_html => 1, -title => 'Associated Samples' ) };
            }
            else {
                push @layers, { label => 'Samples', content => "$count Samples found tied to Src$source_id" };
            }

            ## Associated Records Layer ##
            my $associated = $self->Model->related_sources_HTML();
            my $plates_table = derived_containers( -dbc => $dbc, -source_id => $source_id );

            $associated .= '<BR><BR>' . $plates_table;
            $associated
                .= '<BR><span class=small>'
                . &Link_To( $dbc->config('homelink'), "View all Plates/Tubes Derived from current Source(s)", "&cgi_application=alDente::Source_App&rm=View+Plates&Source_ID=$source_id", $Settings{LINK_COLOUR}, ['newwin'] )
                . '</SPAN>';
            push @layers, { label => 'Associated Records', content => $associated };

            ## Generate Ancestry ##
            $right = $self->Model->ancestry( -align => 'center' );
        }
    }

    ###############
    ### Links ###
    ###############

    if ( $self->objects() == 1 ) {
        ## Add view links
        my $view_invoiceable_info;
        my @libs = @{ $self->Model->get_libraries() };
        if ( $libs[0] ) {
            my $lib_string = join( ',', @libs );

            my ( $iw_view_root, $iw_view_sub_path ) = alDente::Tools::get_standard_Path( -type => 'view', -group => 43, -structure => 'DATABASE' );
            my $iw_view_filepath = $iw_view_root . $iw_view_sub_path . 'general/Invoiced_Work.yml';

            if ( -e $iw_view_filepath ) {
                $view_invoiceable_info = &Link_To( $dbc->config('homelink'), "View Invoiceable Info", "&cgi_application=alDente::View_App&rm=Display&File=$iw_view_filepath&Library_Name=$lib_string&Generate+Results=1" );
            }
        }

        my @label_rows = ();
        push @label_rows, $view_invoiceable_info;

        ## link for adding a goal-work_request to source
        my $add_goal = &Link_To( $dbc->config('homelink'), "Goal", "&cgi_application=alDente::Work_Request_App&rm=New Work Request&WR_source=$source_id" );
        my @associate_rows = ();

        if (@associate_rows) { push @associate_rows, '<hr />' }
        push @associate_rows, ( "Associate with:", $add_goal );

        if ( $dbc->table_loaded('Xenograft') ) {
            if ( $Source->value('Xenograft') ne 'Y' ) {
                my $xenograft_link = &Link_To( $dbc->homelink(), 'Add Xenograft Info', "&cgi_application=SDB::DB_Object_App&rm=Add Record&Table=Xenograft&FK_Source__ID=$source_id" );
                push @associate_rows, $xenograft_link;
            }
        }

        $links .= standard_label( \@label_rows );
        $links .= standard_label( \@associate_rows );
    }

    if ( $dbc->mobile() ) {
        return $self->SUPER::display_record_page(
            -right      => $right,                         ## only defined for single record home pages
            -mobile     => $links,                         ## only defined for single record home pages
            -layers     => \@layers,
            -visibility => { 'Samples' => ['desktop'] },
            -label_span => 3,
            -layer_type => 'mobile',
            -open_layer => 'Lab'
        );
    }
    else {
        return $self->SUPER::display_record_page(
            -centre     => $links,                         ## only defined for single record home pages
            -right      => $right,                         ## only defined for single record home pages
            -layers     => \@layers,
            -visibility => { 'Samples' => ['desktop'] },
            -detailed   => $detailed,
        );
    }
}

##################
sub generic_page {
##################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'Source' );

    return {
        top    => section_heading('Generic Source Home Page'),
        layers => [ { label => 'Options', content => 'generic Source home page not tied to specific object(s) - nothing currently in place' } ],
    };
}

#########################
sub display_WR_info {
#########################
    my %args      = filter_input( \@_ );
    my $dbc       = $args{-dbc};
    my $source_id = $args{-id};

    my $work_request_info = $dbc->Table_retrieve_display(
        'Work_Request,Work_Request_Type', [ 'Work_Request_ID', 'Work_Request_Title', 'FK_Funding__ID AS Funding', 'FK_Goal__ID AS Goal', 'Goal_Target', ' Work_Request_Type_Name AS  Work_Request_Type', 'Comments' ],
        "WHERE FK_Work_Request_Type__ID = Work_Request_Type_ID AND FK_Source__ID=$source_id",
        -return_html => 1,
        -title       => 'List of work requests',
        -alt_message => "No records found "
    );
    return $work_request_info;

}

#########################
sub derived_containers {
#########################
    my %args             = filter_input( \@_ );
    my $dbc              = $args{-dbc};
    my $source_id        = $args{-source_id};
    my $include_location = $args{-include_location};

    my @fields = ( 'Count(*) as Count', 'Plate.FK_Library__Name as Lib', 'Sample_Type.Sample_Type as Contents', 'Plate_Status as Status' );

    if ( $source_id =~ /,/ ) { unshift @fields, 'Source.Source_ID as Source' }
    if ($include_location) { push @fields, 'GROUP_Concat(DISTINCT Plate.FK_Rack__ID) as Location' }

    my $derived = $dbc->Table_retrieve_display(
        'Source,Sample,Plate_Sample,Plate,Sample_Type',
        \@fields,
        "WHERE Sample.FK_Source__ID IN ($source_id) AND Sample.FK_Source__ID = Source.Source_ID AND Plate_Sample.FK_Sample__ID=Sample.Sample_ID AND 
        Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate.FK_Sample_Type__ID = Sample_Type.Sample_Type_ID AND Plate_Status = 'Active'",
        -group           => 'Source.Source_ID, Plate.FK_Library__Name, Sample_Type_ID, Plate_Status',
        -list_in_folders => ['Location'],
        -return_html     => 1,
        -title           => 'Summary of Active Derived Containers'
    );

    return $derived;
}

#################################
sub redefine_as_Plates {
#################################
    my %args      = filter_input( \@_, -args => 'dbc,source_id,type' );
    my $dbc       = $args{-dbc};
    my $source_id = $args{-source_id};
    my $extra     = $q->hidden( -name => 'Sources', -value => $source_id, -force => 1 );

    my $Import_View = new SDB::Import_Views( -dbc => $dbc );
    my $page = $Import_View->upload_file_box(
        -dbc             => $dbc,
        -cgi_application => 'alDente::Transform_App',
        -button          => $q->submit( -name => 'rm', -value => 'Upload Specimen Template', -force => 1, -class => 'Action' ),
        -extra           => [$extra]
    );

    return $page;
}

#################################
sub view_reserved_sources {
#################################
    my %args = filter_input( \@_, -args => 'dbc,id' );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};
    my $page;

    my @valid_labels = $dbc->Table_find( "Barcode_Label", "Label_Descriptive_Name", "WHERE Label_Descriptive_Name = 'Simple Source Label'" );
    my $list = $dbc->Table_retrieve_display( 'Source', ['*'], "WHERE Source_ID IN ($id)", -return_html => 1 );

    $page .= create_tree( -tree => { "Records" => $list } );

    if ( $valid_labels[0] ) {
        $page
            .= alDente::Form::start_alDente_form( -dbc => $dbc )
            . submit( -name => 'rm', -value => 'Re-Print Source Barcode', -class => 'Std', -force => 1, -onclick => 'return validateForm(this.form);' )
            . hidden( -name => 'table',  -value => 'Source' )
            . hidden( -name => 'src_id', -value => $id )
            . vspace()
            . hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 )
            . 'Type: '
            . popup_menu( -name => "Barcode Name", -values => \@valid_labels )
            . set_validator( -name => 'Barcode Name', -mandatory => 1 )
            . end_form();

    }

    return $page;
}

#################################
sub display_Source_Alerts {
#################################
    my %args = filter_input( \@_, -args => 'dbc,id' );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};
    unless ( $dbc->package_active('GSC') ) {return}

    my $page = $dbc->Table_retrieve_display(
        'Source_Alert',
        [ 'Source_Alert_ID As ID', 'FK_Source__ID As Source', 'Alert_Type As Type', 'FK_Alert_Reason__ID As Reason', 'FK_Employee__ID AS Employee', 'Alert_Notification_Date', 'Alert_Comments' ],
        "WHERE FK_Source__ID IN ($id)",
        -return_html => 1
    );

    return $page;
}

#################################
sub single_standard_options {
#################################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'ids' );
    my $source_id = $args{-ids};

    my $dbc    = $self->{dbc};
    my $Source = $self->Model();

    my @libs = @{ $Source->get_libraries() };
    my $form_name;
    my $condition;

    my $q = new LampLite::CGI;
    my $standard;
    if ( !$dbc->mobile() ) {
        my @types = $dbc->get_enum_list( 'Library', 'Library_Type' );
        my $new_lib
            = "<B>Collection Type:</B>"
            . Show_Tool_Tip( $q->popup_menu( -name => 'Library_Type', -values => [ '', @types ], -force => 1 ), "Indicate if this is a Sequencing Library or an RNA/DNA Collection" )
            . $q->submit( -name => 'rm', -value => 'Create New Library', -class => "Std", -force => 1 )
            . $q->hidden( -name => 'cgi_application', -value => 'alDente::Submission_App', -force => 1 )
            . $q->hidden( -name => 'Scanned ID', -value => 'src' . $source_id, -force => 1 );

        my $lib_table = HTML_Table->new( -width => 400 );
        $lib_table->Toggle_Colour('off');
        $lib_table->Set_Title( 'Define a new library', fsize => '-1' );

        $lib_table->Set_Row( [$new_lib] );
        $standard .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'new_library_form' ) . $lib_table->Printout(0) . vspace() . $q->end_form();

    }

    if ( !$dbc->mobile() && scalar(@libs) ) {
        my $new_container
            = "<B>Select Library/Collection:</B>"
            . $q->popup_menu( -name => 'Library_Name', -value => [@libs] )
            . $q->submit( -name => 'rm', -value => 'New Library_Plate', -class => 'Std', force  => 1 )
            . $q->submit( -name => 'rm', -value => 'New Tube',          -class => 'Std', -force => 1 )
            . $q->hidden( -name => 'cgi_application', -value => 'alDente::Container_App', force => 1 )
            . $q->hidden( -name => 'Source_ID', -value => $source_id, -force => 1 );

        my $create = HTML_Table->new( -width => 400 );
        $create->Toggle_Colour('off');
        $create->Set_Title( 'Create a new plate/tube', fsize => '-1' );
        $create->Set_Row( [$new_container] );

        $standard .= alDente::Form::start_alDente_form( $dbc, -form => 'new_container_form' ) . $create->Printout(0) . vspace() . $q->end_form();
    }

    if ( $dbc->package_active('Dynamic_Libraries') ) {

        if ( !$scanner_mode ) {
            my $search_libs = alDente::Tools::search_list(
                -dbc              => $dbc,
                -form             => $form_name,
                -element_name     => 'Library_Name',
                -table            => 'Library',
                -field            => 'Library_Name',
                -option_condition => $condition,
                -default          => '',
                -search           => 1,
                -filter           => 1,
                -breaks           => 1,
                -width            => 390,
                -filter_by_dept   => 1
            );
            my $add_new_link = &Link_To( $dbc->config('homelink'), 'Add a New Library/Collection', "&Create+New+Library=Create+New+Library&Scanned+ID=SRC$source_id", $Settings{LINK_COLOUR}, ['newwin'] );
            my $associate_source
                = "<B>Select Library/Collection:</B>" 
                . lbr
                . $search_libs
                . lbr
                . $q->submit( -name => 'rm', -value => 'Associate Library', -class => 'Std', -force => 1 )
                . " or $add_new_link"
                . $q->hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 )
                . $q->hidden( -name => 'Source_ID', -value => $source_id, -force => 1 );

            my $associate = HTML_Table->new( -width => '400' );
            $associate->Toggle_Colour('off');
            $associate->Set_Title( 'Associate this source with a library/collection', fsize => '-1' );
            $associate->Set_Row( [$associate_source] );

            $standard .= alDente::Form::start_alDente_form( $dbc, -form => 'associate_library_form' ) . $associate->Printout(0) . vspace() . $q->end_form();
        }
    }

    $standard .= '<hr>';

    my $start_tag = alDente::Form::start_alDente_form( -dbc => $dbc, -name => '_Source' );
    my $hidden = $q->hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 ) . $q->hidden( -name => 'src_id', -value => $source_id );

    my $Form = new LampLite::Form( -dbc => $dbc, -name => 'Cancel', -type => 'horizontal' );

    $Form->append( $q->submit( -name => 'rm', -value => 'Cancel Source', -force => 1, -class => 'Action btn' ),
        $q->submit( -name => 'rm', -value => 'Delete Source', -force => 1, -class => 'Action btn', -tooltip => 'Only delete if the record was created by accident' ) );
    $standard .= $Form->generate( -wrap => 1, -include => $hidden, -tag => $start_tag, -close => 1 );

    return $standard;
}

#######################
sub extract_table {
#######################
    my %args      = filter_input( \@_, -args => 'dbc,source_id,type' );
    my $dbc       = $args{-dbc};
    my $source_id = $args{-source_id};
    my $type      = $args{-type};

    my $dispense = HTML_Table->new( -width => 400 );
    my @storage_medium = $dbc->Table_find( 'Storage_Medium', 'Storage_Medium_Name', "Order by Storage_Medium_Name" );
    unshift @storage_medium, "";

    my %source_info = $dbc->Table_retrieve(
        'Source',
        [   'Group_Concat(FKParent_Source__ID) as Parent',
            'GROUP_CONCAT(DISTINCT FK_Original_Source__ID) as OS',
            'Group_Concat(DISTINCT Current_Amount) as Amt',
            'Group_Concat(DISTINCT Amount_Units) as Units',
            'Group_Concat(DISTINCT FK_Sample_Type__ID) as Type',
            'Group_Concat(DISTINCT FK_Storage_Medium__ID) as Medium',
            'Group_Concat(DISTINCT Storage_Medium_Quantity) as Medium_Qty',
            'Group_Concat(DISTINCT Storage_Medium_Quantity_Units) as Medium_Qty_Units',
            'Group_Concat(DISTINCT FK_Plate_Format__ID) as Format',
            'Group_Concat(DISTINCT Source_Label) as Label',
            'Group_Concat(DISTINCT Source_Status) as Status',
            'Group_Concat(DISTINCT Current_Concentration) as Concentration',
            'Group_Concat(DISTINCT Current_Concentration_Units) as Concentration_Units',
        ],
        "WHERE Source_ID IN ($source_id)"
    );

    foreach my $key ( keys %source_info ) {
        if ( $source_info{$key}[0] =~ /,/ ) {
            $source_info{$key}[0] = 'Mixed';
        }
    }

    my $current_amt      = $source_info{Amt}[0];
    my $current_units    = $source_info{Units}[0];
    my $medium           = $source_info{Medium}[0];
    my $medium_qty       = $source_info{Medium_Qty}[0];
    my $medium_qty_units = $source_info{Medium_Qty_Units}[0];
    my $label            = $source_info{Label}[0];
    my $status           = $source_info{Status}[0];
    my $concentration    = $source_info{Concentration}[0];
    my $con_units        = $source_info{Concentration_Units}[0];

    my $format;
    if   ( $source_info{Format}[0] =~ /,/ ) { $format = $source_info{Format}[0] }
    else                                    { $format = alDente::Tools::alDente_ref( 'Plate_Format', $source_info{Format}[0], -dbc => $dbc, -quiet => 1 ) }

    my $sample_type      = alDente::Tools::alDente_ref( 'Sample_Type', $source_info{Type}[0], -dbc => $dbc, -quiet => 1 );
    my $os_ids           = $source_info{OS}[0];
    my $parent_source_id = $source_info{Parent}[0];

    my $hide_extract = "HideElement('sample_type');";
    my $show_extract = "unHideElement('sample_type');";
    my $default_xfer = 'Aliquot';

    my $options;

    ## provide valid options based on Status ##
    if ( $status eq 'Active' ) {
        $options
            .= Show_Tool_Tip( radio_group( -name => 'split_type', -values => ['Aliquot'], -id => 'split_type', -onClick => $hide_extract, -default => $default_xfer, -force => 1 ), define_Term('Aliquot') )
            . &hspace(5)
            . Show_Tool_Tip( radio_group( -name => 'split_type', -values => ['Transfer'], -id => 'split_type', -onClick => $hide_extract, -default => $default_xfer, -force => 1 ), define_Term('Transfer') )
            . &hspace(5)
            . Show_Tool_Tip( radio_group( -name => 'split_type', -values => ['Extract'], -id => 'split_type', -onClick => $show_extract, -default => $default_xfer, -force => 1 ), define_Term('Extract') );
    }
    else {
        my $tip = "Laboratory handling of Sources can only be done on Active Src records<P>If necessary, you may scan SRC barcodes into a valid location and re-activate";
        $options .= Show_Tool_Tip( ' X Aliquot',  $tip );
        $options .= Show_Tool_Tip( ' X Transfer', $tip );
        $options .= Show_Tool_Tip( ' X Extract',  $tip );
        $default_xfer = 'Receive';
    }

    if ( $parent_source_id || $os_ids =~ /,/ ) {
        ## no 'Receive more' option if parent source or mutliple Original Sources ##
        $options .= &hspace(5) . Show_Tool_Tip( ' X Receive More', 'Valid option only for Original Starting Materials' );
    }
    else {
        $options .= Show_Tool_Tip( radio_group( -name => 'split_type', -values => ['Receive'], -id => 'split_type', -onClick => $show_extract, -force => 1, -labels => { 'Receive' => 'Receive More' }, -default => $default_xfer ),
            "Define newly received starting material received from the same original source" );
    }
    $dispense->Set_sub_header( $options, $Settings{HIGHLIGHT_CLASS} );

    ## currently only works for single Src records ##
    $dispense->Set_Title( 'Sample Transfer / Aliquot / Extraction / Receive', fsize => '-1' );
    $dispense->Set_Line_Colour( $Settings{LIGHT_BKGD} );

    $dispense->Set_Row( [ '', 'Current', '', 'Target', '' ], $Settings{HIGHLIGHT_CLASS} );

    my $reset_units_default = 'Ignore';
    my $reset_unit_prompt = Show_Tool_Tip( radio_group( -name => 'reset_units', -values => ['Reset Base Units'], -default => $reset_units_default, -force => 1, -onClick => "unHideElement('reset_units');" ),
        'Use this to change base units (eg 100 ml -> 5 mg) for target container' );
    my $retain_unit_prompt = Show_Tool_Tip( radio_group( -name => 'reset_units', -values => ['Ignore'], -default => $reset_units_default, -force => 1, -onClick => "HideElement('reset_units');" ), 'Leave base units (eg litres vs grams) the same' );
    my $aliq_btn = submit( -name => 'rm', -value => "Execute", -class => "Action", -onclick => 'return validateForm(this.form);' );
    my $batch_aliq;
    if ( $source_id =~ /,/ ) {
        $batch_aliq = Show_Tool_Tip( submit( -name => 'rm', -value => 'Batch Aliquot', -class => 'Action', -force => 1, -onclick => '' ), 'This button allows you to set different amounts and units to each source' );
    }

    $dispense->Set_Row(
        [   'Amount', "$current_amt $current_units",
            '', Show_Tool_Tip( textfield( -name => 'remove_amount', -size => 5 ), 'Amount removed from source container ' ) . hidden( -name => 'remove_units', -value => $current_units, -force => 1 ) . ' ' . $current_units . ' ' . $reset_unit_prompt
        ]
    );

    $dispense->Set_Row(
        [   'Reset Units to',
            '',
            '',
            Show_Tool_Tip( textfield( -name => 'final_amount', -id => 'final_amount', -size => 5, -force => 1 ), 'Use this to change base units (eg 100 ml -> 5 mg)' )
                . Show_Tool_Tip( popup_menu( -name => 'final_units', -id => 'final_units', -value => [ $dbc->get_enum_list( 'Source', 'Amount_Units' ) ], -default => '', -force => 1 ), 'Use this to change base units (eg 100 ml -> 5 mg)' ) . ' '
                . $retain_unit_prompt
        ],
        -element_id => 'reset_units',
        -spec       => "style='display:none'"
    );

    my $storage_default = "Target Container is Empty";
    my $unhide_storage  = Show_Tool_Tip(
        radio_group(
            -name    => 'hide_storage',
            -values  => ['Target Container is Empty'],
            -default => $storage_default,
            -force   => 1,
            -onClick => "HideElement('storage_medium'); HideElement('storage_qty_units'); HideElement('conc'); HideElement('conc_unit');HideElement('unhide_storage'); unHideElement('hide_storage')"
        ),
        'No Applicable Target Storage Medium Info'
    );
    my $hide_storage = Show_Tool_Tip(
        radio_group(
            -name    => 'hide_storage',
            -values  => ['Specify Target Storage Medium'],
            -default => $storage_default,
            -force   => 1,
            -onClick => "unHideElement('storage_medium'); unHideElement('storage_qty_units'); unHideElement('conc'); unHideElement('conc_unit'); HideElement('hide_storage'); unHideElement('unhide_storage')"
        ),
        'Indicate Volume and Storage Medium already in Target Container if applicable'
    );

    $dispense->Set_Row( [ '', '', '', $hide_storage ], -element_id => 'hide_storage' );
    $dispense->Set_Row( [ '', '', '', $unhide_storage ], -element_id => 'unhide_storage', -spec => "style='display:none'" );

    $dispense->Set_Row(
         [ 'Storage Medium', alDente::Tools::alDente_ref( 'Storage_Medium', $medium, -dbc => $dbc ), '', popup_menu( -name => 'FK_Storage_Medium__ID', -value => \@storage_medium, -default => '' ) ],
        -element_id => 'storage_medium',
        -spec       => "style='display:none'"
    );

    $dispense->Set_Row(
        [   'Storage Medium',
            "$medium_qty $medium_qty_units",
            '',
            Show_Tool_Tip( textfield( -name => 'Storage_Medium_Quantity', -id => 'storage_amount', -size => 5 ), 'The transferred amount will be added to this if base units are the same' ) . ' '
                . popup_menu( -name => 'Storage_Medium_Quantity_Units', -id => 'storage_units', -value => [ $dbc->get_enum_list( 'Source', 'Storage_Medium_Quantity_Units' ) ], -default => '' )
        ],
        -element_id => 'storage_qty_units',
        -spec       => "style='display:none'"
    );

    $dispense->Set_Row(
         [ 'Concentration', $concentration, '', textfield( -name => 'Current_Concentration', -size => 5 ) ],
        -element_id => 'conc',
        -spec       => "style='display:none'"

    );
    $dispense->Set_Row(
         [ 'Concentration Units', $con_units, '', alDente::Tools::search_list( -dbc => $dbc, -field => 'Current_Concentration_Units', -table => 'Source', -id => ) ],
        -element_id => 'conc_unit',
        -spec       => "style='display:none'"
    );

    $dispense->Set_Row( [ 'Container Format', $format, '', alDente::Tools::search_list( -dbc => $dbc, -field => 'FK_Plate_Format__ID' ) ] );
    $dispense->Set_Row(
         [ 'Sample Type', $sample_type, ' ', alDente::Tools::search_list( -dbc => $dbc, -field => 'FK_Sample_Type__ID', -id => "FK_Sample_Type__ID", -search => 1, -filter => 1, -short_list_size => 20 ) ],
        -element_id => 'sample_type',
        -spec       => "style='display:none'"
    );

    my $default_label = $label;
    if ( $default_label eq '(mixed)' ) { $default_label = '' }
    $dispense->Set_Row( [ 'Target Label', $label, '', Show_Tool_Tip( textfield( -name => 'Target_Label', -default => $default_label, -size => 20, -force => 1 ), 'Optional Label - applied to all daughter Src records if more than one' ) ] );
    $dispense->Set_Row(
        [ 'Repeat', '', '', Show_Tool_Tip( textfield( -name => 'DBRepeat', -default => '1', -size => 5, -force => 1 ) . '(Up to 99 repeat times)', 'Enter the number of repeat times for the action. The maximum number of repeats is 99.' ) ] );
    $dispense->Set_Row( [ $aliq_btn, $batch_aliq ] );

    my $page = alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'transfer_form' ) . $dispense->Printout(0);

    $page .= set_validator( -name => 'FK_Plate_Format__ID', -mandatory => 1, -prompt => 'You must specify a Container Format' );                                                                                 ## mandatory for all transfer types
    $page .= set_validator( -name => 'FK_Sample_Type__ID', -mandatory => 1, -prompt => 'You must specify a Target Sample Type if Extracting', -case_name => 'split_type', -case_value => 'Extract|Receive' );    ## mandatory for Extract only
    $page .= set_validator( -name => 'final_units',   -mandatory => 1, -prompt => 'You must specify Units if you include an amount', -case_name => 'final_amount' );                                             ## mandatory for Extract only
    $page .= set_validator( -name => 'storage_units', -mandatory => 1, -prompt => 'You must specify Units if you include an amount', -case_name => 'storage_amount' );                                           ## mandatory for Extract only
    $page .= set_validator( -name => 'DBRepeat', -format => '^\s*\d{1,2}\s*$', -prompt => 'The Repeat must be an integer number between 1 to 99' );

    $page .= hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 ) . hidden( -name => 'src_id', -value => $source_id, -force => 1 ) . hidden( -name => 'quick_copy', -value => "1", -force => 1 ) . end_form();

    return $page;

}

#######################
sub single_Lab {
#######################
    my %args      = filter_input( \@_, -args => 'dbc,source_id,type' );
    my $dbc       = $args{-dbc};
    my $source_id = $args{-source_id};
    my $type      = $args{-type};

    require alDente::Rack;
    my @location_list = sort @{ alDente::Rack::get_export_locations( -dbc => $dbc ) };

    ##  Gotta separate into two tables and two forms one with cgi_application

    ### Do not prompt for lab actions if any current Src records are not Active ##
    my @inactive = join ', ', $dbc->Table_find( 'Source', 'Source_ID', "WHERE Source_Status != 'Active' AND FKOriginal_Source__ID != Source_ID AND Source_ID IN ($source_id)" );
    if ( $inactive[0] ) {
        return "Source handling in the lab can only be performed on Active Src records. <P>If necessary, you may scan SRC barcodes into a valid location and re-activate. <P> Inactive Src records scanned: " . Cast_List( -list => @inactive, -to => 'UL' );
    }

    my $options = HTML_Table->new( -width => 400 );
    $options->Set_Line_Colour( $Settings{LIGHT_BKGD} );
    $options->Set_Title( 'Options', fsize => '-1' );
    $options->Set_Row(
        [         alDente::Form::start_alDente_form( $dbc, -form => 'option_form 1' )
                . hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 )
                . hidden( -name => 'src_id', -value => $source_id, -force => 1 )
                . set_validator( -name => 'Destination', -mandatory => 1 )

                . Show_Tool_Tip(
                submit( -name => 'rm', -value => 'Export Source', -class => 'Action', -force => 1, -onclick => "return validateForm(this.form,'','','Destination');" )
                    . set_validator( -confirmPrompt => "Are you sure you want to Export this container without tracking it via a shipment?" ),
                "This simply flags this container as having been exported, but does not track its location.  Please export containers using a Shipment if you wish to track it more effectively"
                ),
            ' To: ',
            &Link_To( $dbc->config('homelink'), 'Add NEW Location', "&cgi_application=alDente::Rack_App&rm=Add New Location", 'red' )
                . hspace(3)
                . popup_menu( -name => 'Destination', -values => [ '-- Select Destination --', @location_list ], -default => '-- Select Destination --', -force => 1 ),
            "Comments: "
                . textfield( -name => 'Export_Comments', -size => 17 )
                . end_form()

        ]
    );

    $options->Set_Row(
        [   alDente::Form::start_alDente_form( $dbc, -form => 'option_form 2' )
                . hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 )
                . hidden( -name => 'src_id', -value => $source_id, -force => 1 )
                . set_validator( -name => 'Target_Rack', -mandatory => 1 )
                . submit( -name => 'rm', -label => 'Move', -class => 'Action', -force => 1, -onclick => "return validateForm(this.form,'','','Target_Rack');" ),
            "To: ",
            Show_Tool_Tip( textfield( -name => 'Target_Rack', -size => 17 ), "Scan A Rack" ) . end_form()
        ]
    );

    $options->Set_Row(
        [         alDente::Form::start_alDente_form( $dbc, -form => 'option_form 3' )
                . hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 )
                . hidden( -name => 'src_id', -value => $source_id, -force => 1 )
                . submit( -name => 'rm', -label => 'Throw Away', -class => 'Action', -force => 1 )
                . end_form()
        ]
    );

    my $pending_requests = 0;
    my $unavailable      = 0;

    my %requests = $dbc->Table_retrieve(
        'Replacement_Source_Request,Replacement_Source_Reason',
        [ 'Replacement_Source_Requested', 'Replacement_Source_Reason', 'Replacement_Source_Status', 'FKReplacement_Source__ID', 'Replacement_Source_Received', 'FK_Source__ID', 'Replacement_Source_Request_Comments', 'Replacement_Source_Request_ID' ],
        "WHERE FK_Replacement_Source_Reason__ID=Replacement_Source_Reason_ID AND FK_Source__ID IN ($source_id)"
    );

    my $request_count = 0;
    while ( defined $requests{FK_Source__ID}[$request_count] ) {
        ## Replacement already requested ##
        my $date        = $requests{Replacement_Source_Requested}[$request_count];
        my $reason      = $requests{Replacement_Source_Reason}[$request_count];
        my $status      = $requests{Replacement_Source_Status}[$request_count];
        my $replacement = $requests{FKReplacement_Source__ID}[$request_count];
        my $rcvd        = $requests{Replacement_Source_Received}[$request_count];
        my $original    = $requests{FK_Source__ID}[$request_count];
        my $comment     = $requests{Replacement_Source_Request_Comments}[$request_count];
        my $id          = $requests{Replacement_Source_Request_ID}[$request_count];
        $request_count++;

        my $colour = 'mediumyellowbw';

        my $replaced;
        if ($replacement) {
            $replaced = Link_To( $dbc->config('homelink'), 'Rcvd', "&HomePage=Source&ID=$replacement", -tooltip => "Rcvd ($rcvd):\n" . alDente::Tools::alDente_ref( 'Source', $replacement, -dbc => $dbc ) );
            $colour = 'mediumgreenbw';
        }

        my $title = Link_To( $dbc->config('homelink'), 'Replacement Requested', "&HomePage=Replacement_Source_Request&ID=$id", -tooltip => "View Request Details" );    #

        $options->Set_Row( [ $title, $date, "($reason)", $comment, $replaced ], $colour );

        if    ( $status eq 'Requested' )     { $pending_requests++ }                                                                                                    ## at least one request is still pending
        elsif ( $status eq 'Not Available' ) { $unavailable++ }
    }

    if ( !$pending_requests ) {
        my ($pooled) = $dbc->Table_find( 'Source_Pool', 'FKChild_Source__ID', "WHERE FKChild_Source__ID IN ($source_id)" );
        if ($pooled) {
            $options->Set_sub_header('Replacement requests not available for Pooled Sources');
        }
        elsif ($unavailable) {
            $options->Set_sub_header("Replacement Not Available for $unavailable Source(s)");
        }
        else {
            ## Request Replacement ##
            $options->Set_Row(
                [   alDente::Form::start_alDente_form( $dbc, -form => 'option_form 3' )
                        . hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 )
                        . hidden( -name => 'src_id', -value => $source_id, -force => 1 )
                        . set_validator( -name => 'FK_Replacement_Source_Reason__ID', -mandatory => 1 )
                        . submit( -name => 'rm', -value => 'Request Replacement', -class => 'Action', -force => 1, -onclick => "return validateForm(this.form,'','','FK_Replacement_Source_Reason__ID');" ),
                    'Due to: ',
                    alDente::Tools::search_list( -dbc => $dbc, -field => 'FK_Replacement_Source_Reason__ID' ),
                    textfield( -name => 'Replacement_Comment', -size => 17 ) . end_form()
                ]
            );
        }
        $options->Set_sub_header('<hr>');
    }

    my ($label_name) = $dbc->Table_find( 'Source,Barcode_Label', 'Label_Descriptive_Name', "where FK_Barcode_Label__ID=Barcode_Label_ID AND Source_ID IN ($source_id)", -distinct => 1 );
    my @valid_labels = $dbc->Table_find( "Barcode_Label", "Label_Descriptive_Name", "WHERE Barcode_Label_Type like 'source' AND Barcode_Label_Status ='Active'" );
    if ( $#valid_labels > 0 ) {
        unshift( @valid_labels, '--Select--' );
        $options->Set_Row(
            [         alDente::Form::start_alDente_form( $dbc, -form => 'option_form 4' )
                    . hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 )
                    . hidden( -name => 'src_id', -value => $source_id, -force => 1 )
                    . set_validator( -name => 'Barcode Name', -mandatory => 1 )

                    . submit( -name => 'rm', -value => 'Re-Print Source Barcode', -class => 'Std', -force => 1, -onclick => "return validateForm(this.form,'','','Barcode Name');" )
                    . hidden( -name => 'table',  -value => 'Source' )
                    . hidden( -name => 'src_id', -value => $source_id ),
                'Type: ',
                popup_menu( -name => "Barcode Name", -values => \@valid_labels, -default => $label_name )
                    . end_form()

            ]
        );
    }
    elsif ( $valid_labels[0] ) {
        $options->Set_Row(
            [         alDente::Form::start_alDente_form( $dbc, -form => 'option_form 5' )
                    . hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 )
                    . hidden( -name => 'src_id', -value => $source_id, -force => 1 )
                    . set_validator( -name => 'Barcode Name', -mandatory => 1 )

                    . submit( -name => 'rm', -value => 'Re-Print Source Barcode', -class => 'Std', -onclick => "return validateForm(this.form,'','','Barcode Name');", -force => 1 )
                    . hidden( -name => 'table',        -value => 'Source' )
                    . hidden( -name => 'src_id',       -value => $source_id )
                    . hidden( -name => 'Barcode Name', -value => $valid_labels[0] ),
                'Type: ',
                ,
                " <i>($valid_labels[0])</i>" . end_form()
            ]
        );
    }

    ## lab layer ##
    my $lab = extract_table( -dbc => $dbc, -source_id => $source_id, -type => $type ) . vspace(5);

    $lab .= $options->Printout(0);
    return $lab;
}

###########################
sub throw_away_prompt {
###########################
    my $dbc = shift;
    my $ids = shift;

    my $prompt;
    $prompt
        .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'ThrowAwaySources' )
        . submit( -name => 'label', -value => "Yes - I want to throw away Source(s) $ids", -class => 'Action' )
        . hidden( -name => 'rm',              -value => 'Throw Away Source',   -force => 1 )
        . hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 )
        . hidden( -name => 'Source_ID',       -value => $ids )
        . hidden( -name => 'Confirmed',       -value => 1 );

    $prompt .= end_form();

    return $prompt;
}

#########################
sub multiple_Source {
#########################
    my $dbc        = shift;
    my $source_ids = shift;

    my @fields = $dbc->get_field_list( -table => 'Source' );
    unshift @fields, ('CONCAT("SRC",Source_ID) AS Barcode');
    return $dbc->Table_retrieve_display( 'Source', \@fields, "WHERE Source_ID IN ($source_ids)", -return_html => 1, -excel_link => 1 );

}

########################
sub active_Samples {
########################
    my $dbc = shift;
    my $list = shift || 0;

    return $dbc->Table_retrieve_display(
        'Source,Sample,Plate',
        [ 'FK_Source__ID', 'Sample.FKOriginal_Plate__ID as Original_Container', 'Plate_ID as Plate', 'Plate.FK_Plate_Format__ID', 'Plate.FK_Rack__ID as Location', 'Count(*) as Samples' ],
        "WHERE FK_Source__ID=Source_ID AND Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate_Status = 'Active' AND Source_ID IN ($list) Group by Plate_ID",
        -total_columns => 'Samples',
        -return_html   => 1
    );
}
##############################
#  Displays the web page content given the columns
#
#  Ex: _display_content(-col1=>$col1, -col2=>$col2);
#
#  Returns:
#
##############################
sub _display_content {

    my %args = &filter_input( \@_, -args => 'col1,col2', -mandatory => 'col1' );
    my $col1 = $args{-col1};
    my $col2 = $args{-col2};

    my %colspan;
    $colspan{1}->{1} = 2;    ## set the Heading to span 2 columns
    return &Views::Table_Print( content => [ [ $col1, "&nbsp&nbsp&nbsp&nbsp", $col2 ] ], -colspan => \%colspan, -spacing => "10", print => 0 );

}

##############################
#  Displays a custom dbform for Original_Source, Source and source type
#
# (This ASSUMES that there are form wrappers (<Form> ... </Form>) handled outside of this method.
#
#
#  Ex: $source_obj->display_source_form(-dbc=>$dbc,-tables=>$tables,-type=>$type,-presets=>\@presets,-ids=>\@src_ids,-amount=>$amount=>,-units=>$units);
#
#  Returns: $form
#
##############################
sub display_source_form {
#####################

    my %args = &filter_input( \@_, -args => 'dhb,tables,sub_table,type,presets,pla,OS_id,submission,pool_info,form_name,show', -mandatory => 'dbc,tables,type,form_name' );

    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $tables    = $args{-tables};
    my $sub_table = $args{-sub_table};
    my $type      = $args{-type};
    my $presets   = $args{-presets};
    my $pla       = $args{-pla} || 0;
    my $OS_id     = $args{-OS_id};
    my $sub       = $args{-submission};
    my $pool_info = $args{-pool_info};
    my $form_name = $args{-form_name} || "DsplySrcFrm";
    my $show      = $args{-show};
    my $append    = $args{-append};
    my $user_id   = $dbc->get_local('user_id');

    my $date = &date_time();
    my %set;
    my %grey;      ## DB_Form customization - greyed out parameters
    my %preset;    ## DB_Form customization - preset parameters
    my %hidden;    ## DB_Form customization - hidden parameters
    my %list;
    my %extra;
    my $form;

    my $src_amnt_units;
    my $src_amnt = 0;
    my $pool_ids = 0;
    my @pool_ids = ();
    my %pool_info;

    my ($sample_type_id) = $dbc->Table_find( 'Sample_Type', 'Sample_Type_ID', "where Sample_Type = '$type'" );

    my $output = alDente::Form::start_alDente_form( $dbc, -form => $form_name );

    if ($pool_info) {
        %pool_info = %{$pool_info};
        @pool_ids  = @{ $pool_info->{src_ids} };
        $pool_ids  = join( ',', @pool_ids );
    }

    # if preset fields differ between the sources to be pooled set them to "Mixed"
    if ($presets) {
        my @presets = @{$presets};
        foreach my $preset (@presets) {
            my $table_list = $tables;
            if ($sub_table) { $table_list .= ",$sub_table" }
            my @temp = $dbc->Table_find( "$table_list", $preset, "where FK_Original_Source__ID=Original_Source_ID AND Source_ID in ($pool_ids)", -distinct => 1 );
            if ( scalar(@temp) == 1 && $temp[0] ne 'NULL' ) {
                $set{$preset} = $temp[0];

            }
            else {
                if ($pool_info) {
                    if ( $dbc->foreign_key_check( -field => "$preset" ) ) {
                        $set{$preset} = "";
                    }
                    else {
                        $set{$preset} = "Mixed";
                    }
                }
                else {
                    $set{$preset} = "";
                }

            }
        }
    }

    my $flag = 0;

    # determine the amount of each source to be pooled, convert all to mL and determine the total pooled volume
    foreach my $pool_src (@pool_ids) {
        if ( $flag == 0 ) {
            $src_amnt       = $pool_info{$pool_src}{amnt};
            $src_amnt_units = $pool_info{$pool_src}{unit};
            $flag++;
        }
        else {
            ( $src_amnt, $src_amnt_units ) = &alDente::Tools::calculate(
                -p1_amnt  => $src_amnt,
                -p1_units => $src_amnt_units,
                -p2_amnt  => $pool_info{$pool_src}{amnt},
                -p2_units => $pool_info{$pool_src}{unit},
                -action   => 'add'
            );
        }
    }

    ### Commenting out the get best units, since it may result in units that do not exist in Source.Amount_Units enum field
    ## ($src_amnt,$src_amnt_units) = &Get_Best_Units(-amount=>$src_amnt,-units=>$src_amnt_units);

    ##grey out the appropriate fields
    if ($pla) {
        $grey{FKSource_Plate__ID} = $dbc->get_FK_info( "FKSource_Plate__ID", $pla );
    }
    else {
        $hidden{FKSource_Plate__ID} = $dbc->get_FK_info( "FKSource_Plate__ID", $pla );
    }
    $grey{FK_Sample_Type__ID} = $sample_type_id;
    $grey{Original_Amount}    = $src_amnt;
    $grey{Amount_Units}       = $src_amnt_units;
    $grey{FK_Rack__ID}        = 1;
    $grey{FK_Shipment__ID}    = 0;

    ## preset the appropriate fields
    my $table_list = "Source";
    $table_list .= ",$sub_table" if ($sub_table);
    my $tmp_form = SDB::DB_Form->new( -dbc => $dbc );
    $tmp_form->merge_data(
        -tables        => $table_list,
        -primary_field => 'Source.Source_ID',
        -primary_list  => $pool_info{src_ids},
        -preset        => \%preset,
        -skip_list     => [qw(Received_Date FK_Rack__ID FKReceived_Employee__ID Source_Number Current_Amount Original_Amount)]
    );
    $preset{Received_Date} = &date_time();

    $preset{FK_Barcode_Label__ID} = $set{'FK_Barcode_Label__ID'};

    ## hide appropriate fields
    # if source being pooled come fro the OS there should be an entry in the %pool_info->{os_id}
    if ( $pool_info->{os_id} ) {
        $grey{FK_Original_Source__ID} = $pool_info->{os_id};
    }
    else {
        $grey{FK_Original_Source__ID} = $OS_id;
    }
    $hidden{Source_Status}           = 'Active';
    $hidden{FK_Source__ID}           = '';
    $hidden{Source_ID}               = '';
    $hidden{FKParent_Source__ID}     = '';
    $hidden{Source_Number}           = 'TBD';
    $hidden{FKReceived_Employee__ID} = $user_id;
    if ($sub_table) {
        $hidden{ $sub_table . "_ID" } = '';
    }

    # don't preset OS values if user chose to use an existing HOS
    if ( !$OS_id ) {
        $preset{FK_Taxonomy__ID}      = $set{'FK_Taxonomy__ID'};
        $preset{FK_Anatomic_Site__ID} = $set{'FK_Anatomic_Site__ID'};
        $preset{Host}                 = $set{'Host'};
        $preset{FK_Strain__ID}        = $set{'FK_Strain__ID'};
        $preset{Sex}                  = $set{'Sex'};
        $preset{FK_Contact__ID}       = $set{'FK_Contact__ID'};

        $hidden{Defined_Date}           = $date;
        $hidden{FKCreated_Employee__ID} = $user_id;
        $hidden{FK_Original_Source__ID} = '';
        $hidden{Original_Source_ID}     = '';
    }

    my $target = 'Database';
    if ($sub) {
        $target = 'Storable';
    }

    # if using an existing HOS don't display the OS form
    if ($OS_id) {

        #$grey{FK_Original_Source__ID} = $OS_id;
        my $src_form = SDB::DB_Form->new( -dbc => $dbc, -form_name => $form_name, -table => 'Source', -target => $target, -quiet => 1, -wrap => 0, -start_form => 0, -end_form => 1 );
        $src_form->configure( -list => \%list, -extra => \%extra );
        $form = $src_form->generate( -grey => \%grey, -omit => \%hidden, -preset => \%preset, -freeze => 0, -submit => 0, -navigator_on => 0 );

        if ($sub_table) {
            my $type_form = SDB::DB_Form->new( -dbc => $dbc, -title => "$sub_table Info", -form_name => $form_name, -table => $sub_table, -target => $target, -quiet => 1, -wrap => 0 );
            $form = $type_form->generate( -title => "$sub_table Info", -append => $src_form->{form}, -grey => \%grey, -omit => \%hidden, -preset => \%preset, -freeze => 0, -submit => 0, -end_form => 0, -navigator_on => 0 );
        }

    }
    else {

        my $osrc_form = SDB::DB_Form->new( -dbc => $dbc, -form_name => $form_name, -table => 'Original_Source', -target => $target, -quiet => 1, -start_form => 0, -end_form => 0 );
        $form = $osrc_form->generate( -grey => \%grey, -omit => \%hidden, -freeze => 0, -preset => \%preset, -submit => 0, -navigator_on => 0 );

        my $src_form = SDB::DB_Form->new( -dbc => $dbc, -form_name => $form_name, -table => 'Source', -target => $target, -quiet => 1, -wrap => 0, -start_form => 0 );
        $src_form->configure( -list => \%list, -extra => \%extra );
        $src_form->generate( -append => $osrc_form->{form}, -grey => \%grey, -omit => \%hidden, -preset => \%preset, -freeze => 0, -submit => 0, -navigator_on => 0 );

        if ($sub_table) {
            my $type_form = SDB::DB_Form->new( -dbc => $dbc, -title => "$sub_table Info", -form_name => $form_name, -table => $sub_table, -target => $target, -quiet => 1, -wrap => 0, -start_form => 0 );
            $form = $type_form->generate( -append => $src_form->{form}, -grey => \%grey, -omit => \%hidden, -preset => \%preset, -freeze => 0, -submit => 0, -end_form => 0, -navigator_on => 0 );
        }
    }

    if ($show) {
        $output .= $form->Printout(0);
        $output .= Safe_Freeze( -name => "pool_info", -value => \%pool_info, -format => 'hidden', -encode => 1 );
        if ($OS_id) {
            $output .= hidden( -name => 'OS_id', -value => $OS_id );
        }
        $output .= hidden( -name => 'tables', -value => "$tables,$sub_table" );
        $output .= hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 );
        $output .= submit( -name => 'rm', -value => 'Pool Sources', -class => "Std", -force => 1 );

        _display_content( -col1 => $output );
    }
    else {
        $output .= $form;
    }

    if ($append) {
        $output .= $append;
    }

    $output .= end_form();
    return $output;

}

################################
#  Source pooling GUI
#
#  Ex: pooling_gui(-dbc=>$dbc,-ids=>\@pool_ids,-type=>$source_type,-submission=>1);
#
#  Returns:
#
################################
sub pooling_gui {
####################
    my %args        = @_;
    my $dbc         = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my @pool_ids    = @{ $args{-ids} };
    my $type        = $args{-type};
    my $valid       = $args{-pool};
    my $sub         = $args{-submission} || 0;
    my $tables      = 'Original_Source,Source';
    my $form_name   = $args{-form_name};
    my $date        = &date_time();
    my $status_flag = 0;
    my $amount      = '';
    my @src_ids;
    my @src_status;
    my @src_amount;
    my @src_amnt_units;
    my @OS_ids;
    my $common_OS_id;

    if ( !$valid ) {
        Message("The Source_Type of all sources selected for pooling must be the same!");
        return;
    }

    my $pool_pg = '<Table><TR><TD width=375 bgcolor=#eeeefe>Source Pooling</TD></TR></Table><BR><span class=small>';
    $pool_pg .= '<B>Sources selected for pooling:</B>';
    $pool_pg .= '<TABLE span class=small>';

    ## create links out of source ids to be pooled
    my $pool_id_list = Cast_List( -list => \@pool_ids, -to => 'string' );
    my %src_info = $dbc->Table_retrieve( 'Source', [ 'Source_ID', 'Source_Status', 'Current_Amount', 'Amount_Units', 'FK_Original_Source__ID' ], "where Source_ID in ($pool_id_list)" );

    @src_ids        = @{ $src_info{Source_ID} };
    @src_status     = @{ $src_info{Source_Status} };
    @src_amount     = @{ $src_info{Current_Amount} };
    @src_amnt_units = @{ $src_info{Amount_Units} };
    @OS_ids         = @{ $src_info{FK_Original_Source__ID} };

    # check if Sources to be pooled come from the same OS (not HOS)
    my @OS = $dbc->Table_find( 'Source', 'distinct(FK_Original_Source__ID)', "where Source_ID in ($pool_id_list)" );
    if ( scalar(@OS) == 1 ) {
        $common_OS_id = $OS[0];
    }
    else {
        $common_OS_id = 0;
    }

    for ( my $i = 0; $i < scalar(@src_ids); $i++ ) {
        my $pool_src_link = &Link_To( $dbc->config('homelink'), alDente::Source::source_name( undef, -dbc => $dbc, -id => $src_ids[$i] ), "&HomePage=Source&ID=$src_ids[$i]", $Settings{LINK_COLOUR}, ['newwin'] );

        $pool_pg .= '<TR><TD>' . $pool_src_link . '</TD>';

        ## check the status of all sources to be pooled
        if ( $src_status[$i] eq 'Active' ) {
            $pool_pg .= '<TD><font color=green> - ' . $src_status[$i] . '</font></TD></TR>';
        }
        else {
            $pool_pg .= '<TD><font color=red> - ' . $src_status[$i] . '</font></TD></TR>';

            ## if any of the sources is inactive set the flag (used in alerting the user)
            $status_flag = 1;
        }
    }

    if ($status_flag) {
        $pool_pg .= '</TABLE>';
        $pool_pg .= "<P><B>One of these Sources is Inactive and cannot be pooled, please revise your list of Sources</B>";
        return $pool_pg;
    }
    else {
        $pool_pg .= "</TABLE><HR>\n";

        my $OS_id_list = Cast_List( -list => \@OS_ids, -to => 'string' );
        my @amnt_units = ( '', 'ml', 'ul', 'ul/well', 'mg', 'ug', 'ng', 'pg', 'Cells', 'Embryos', 'Litters', 'Organs' );

        # pull out ids of HOSs associated with each SRC to be pooled, if any exist at all
        my @HOS_ids = $dbc->Table_find( 'Hybrid_Original_Source', 'distinct(FKChild_Original_Source__ID)', "WHERE FKParent_Original_Source__ID IN ($OS_id_list)" );

        $pool_pg .= alDente::Form::start_alDente_form( $dbc, 'SourcePage' );
        $pool_pg .= hidden( -name => 'Pool_Source_IDS', -value => \@pool_ids, -force => 1 );
        $pool_pg .= hidden( -name => 'type',            -value => $type,      -force => 1 );
        $pool_pg .= hidden( -name => 'form_name',       -value => $form_name, -force => 1 );

        # Source pooling table
        my $HOS_choice = HTML_Table->new();
        $HOS_choice->Set_Line_Colour( $Settings{LIGHT_BKGD} );
        $HOS_choice->Set_Title( "Source Pooling", fsize => '-1' );

        ## if either of the SRCs to be pooled is associated with a HOS give user a choice to create a new HOS or simply use the one the already exists
        if ( exists $HOS_ids[0] ) {

            my @HOS_menu = ( 'Select', 'New Sample_Origin' );

            foreach my $HOS (@HOS_ids) {

                # for each HOS retrieve the associated Library
                my ($lib_name) = $dbc->Table_find( "Library", "Library_Name", "WHERE FK_Original_Source__ID = $HOS" );
                my $HOS_id = $dbc->get_FK_info( 'FK_Original_Source__ID', $HOS );
                push @HOS_menu, "$HOS_id --$lib_name";
            }
            $HOS_choice->Set_sub_header( '<SPAN CLASS=small>Select Original_Source to use:  ' . popup_menu( -name => 'HOS_name', -value => [@HOS_menu] ) . "</SPAN>", $Settings{HIGHLIGHT_CLASS} );

            # if Sources to be pooled come from different OSs and have not been pooled before
        }
        elsif ( !$common_OS_id ) {
            $pool_pg .= hidden( -name => "HOS_name", -value => "New Sample_Origin" );
        }

        # Construct pooling table
        for ( my $i = 0; $i < scalar(@pool_ids); $i++ ) {
            my $curr_amnt  = $src_amount[$i];
            my $amnt_units = $src_amnt_units[$i];

            my $pool_src_link = &Link_To( $dbc->config('homelink'), alDente::Source::source_name( undef, -dbc => $dbc, -id => $pool_ids[$i] ), "&HomePage=Source&ID=$pool_ids[$i]", $Settings{LINK_COLOUR}, ['newwin'] );
            $HOS_choice->Set_Row(
                [   "$pool_src_link ($curr_amnt$amnt_units)",
                    'Amount to pool: ' . textfield( -name => "pool_amnt $i", -size => 8, -defaultValue => $curr_amnt, -value => '', -force => 1, -structname => 'inputfield' ),
                    'Units: '
                        . popup_menu( -name => "pool_unit $i", -value => \@amnt_units, -defaultValue => $amnt_units, -selected => '', -force => 1, -structname => 'inputfield' )
                        . hidden( -name => "curr_amnt $i", -value => "$curr_amnt,$amnt_units" )
                        . hidden( -name => 'common_OS_id', -value => $common_OS_id )
                ]
            );
        }
        $HOS_choice->Set_Row(
            [   checkbox(
                    -name    => 'all',
                    -label   => "Pool entire amount of each Source",
                    -force   => 1,
                    -onClick => "ToggleFormElements('srcform',0,'inputfield')"
                )
            ]
        );

        $HOS_choice->Set_Row(
            [   checkbox(
                    -name  => 'throw_away_original',
                    -label => "Throw away used sources",
                    -force => 1,

                    #                 -onClick => "ToggleFormElements('srcform',0,'inputfield')"
                )
            ]
        );

        $pool_pg .= hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 );
        $HOS_choice->Set_Row( [ submit( -name => 'rm', -value => "Source Pooling Continue", -class => "Std", -force => 1 ) ] );
        $pool_pg .= $HOS_choice->Printout(0);
        $pool_pg .= end_form();
    }

    return $pool_pg;
}

####################
sub ancestry_view {
####################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $ancestry  = $args{-ancestry};
    my $parents   = $args{-parents};
    my $children  = $args{-children};
    my $source_id = $args{-id};
    my $detailed  = $args{-detailed};
    my $align     = $args{-align};

    my $dbc = $self->{dbc};
    if ($ancestry) { ( $parents, $children ) = @$ancestry }

    my $table = new HTML_Table( -title => "Source Ancestry", -border => 1, -align => $align );
    my @rows = ();

    my @parent_rows;
    foreach my $gen (@$parents) {
        my @parents = @$gen;
        my @generation;
        if (@parents) {
            map {
                if ($_) { push @generation, $self->object_label( -source_id => $_, -dbc => $dbc, -detailed => $detailed ) }
            } @parents;
        }
        push @parent_rows, auto_compress( \@generation );
    }

    push @rows, @parent_rows;

    my $parent_generations = int(@rows);
    push @rows, $self->object_label( -source_id => $source_id, -dbc => $dbc, -detailed => $detailed );

    my @child_rows;
    foreach my $gen (@$children) {
        my @offspring = @$gen;
        my @generation;
        if (@offspring) {
            map {
                if ($_) { push @generation, $self->object_label( -source_id => $_, -dbc => $dbc, -detailed => $detailed ) }
            } @offspring;
        }
        push @child_rows, auto_compress( \@generation );
    }

    push @rows, @child_rows;

    my $child_generations = int(@rows) - $parent_generations - 1;

    $table->Set_Row( \@rows );
    if ($parent_generations) { $table->Set_sub_title( 'Aliquots/Pools FROM: ', $parent_generations, 'mediumbluebw' ) }
    $table->Set_sub_title( 'current', 1, 'mediumgreenbw' );
    if ($child_generations) { $table->Set_sub_title( 'Aliquots/Pools TO: ', $child_generations, 'lightredbw' ) }
    my $view = $table->Printout(0);

    return $view;
}

################
sub auto_compress {
################
    my $list = shift;
    my $limit = shift || 3;

    my @items = Cast_List( -list => $list, -to => 'array' );

    my $breakout = join '<BR>', @items;

    if ( int(@items) > $limit ) {
        my $count = int(@items);

        return create_tree( -tree => { "$count records" => $breakout } );
    }
    else {
        return $breakout;
    }

}

########################################
# Generates a small label describing the container
#
# Options:
#  table type - returns small colour coded table cell
#  tooltip type - returns link to plate with details showing up as tooltip
#  details type - returns details of plate in text string (can be used for external tooltips) #
#
# Returns a string containing info about a container
####################
sub object_label {
####################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'source_id,include' );
    my $dbc  = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $source_id = $args{-source_id} || $args{-id} || $self->{id};
    my $type = $args{-type} || 'table';    ## eg 'tooltip', 'table', or 'details'
    my $verbose    = $args{-verbose};                               ## more details than the concise label.
    my $border     = defined $args{-border} ? $args{-border} : 1;
    my $colour     = $args{-colour} || '#ffffff';
    my $highlight  = $args{-highlight};
    my $tip        = $args{-tip};
    my $link_label = $args{-label};                                 ## optionally override label to appear in link...
    my $detailed   = $args{-detailed} || $verbose;

    my $br = "<BR>\n";

    my $text_colour = 'black';

    if ( $highlight =~ /\b$source_id\b/ ) { $colour = 'red'; $text_colour = 'red'; }

    my $tables = '(Source,Original_Source,Rack,Sample_Type) LEFT JOIN Shipment ON Source.FK_Shipment__ID=Shipment_ID';
    my @fields = (
        'Received_Date', 'Original_Source_ID', 'Original_Source_Name', 'External_Identifier', 'Shipment_ID', 'Rack_Alias as Location',
        'Source_Status', 'Source_Number', 'Sample_Type',
        "CONCAT(Current_Amount,' ',Amount_Units) as Amount",
        'Source.FK_Rack__ID as Rack_ID',
        'FKSource_Plate__ID', 'FKParent_Source__ID', 'FK_Storage_Medium__ID', 'Storage_Medium_Quantity_Units',
        'Storage_Medium_Quantity'
    );

    my $condition = "WHERE Source.FK_Original_Source__ID=Original_Source_ID AND Source.FK_Rack__ID=Rack_ID AND FK_Sample_Type__ID=Sample_Type_ID AND Source_ID IN ($source_id)";

    if ( $dbc->table_loaded('Taxonomy') ) {
        $tables .= ',Taxonomy';
        push @fields, 'Taxonomy_Name as Taxonomy';
        $condition .= ' AND FK_Taxonomy__ID=Taxonomy_ID';
    }

    if ( $dbc->table_loaded('Anatomic_Site') ) {
        $tables .= ',Anatomic_Site';
        push @fields, "Anatomic_Site_Alias as Anatomical_Site";
        $condition .= ' AND FK_Anatomic_Site__ID=Anatomic_Site_ID';
    }

    my %data = $dbc->Table_retrieve( $tables, \@fields, $condition );

    my ( $tax, $tissue );
    if ( $dbc->table_loaded('Taxonomy') )      { $tax    = $data{Taxonomy}[0]; }
    if ( $dbc->table_loaded('Anatomic_Site') ) { $tissue = $data{Anatomic_Site}[0]; }

    my $os_id      = $data{Original_Source_ID}[0];
    my $os_name    = $data{Original_Source_Name}[0];
    my $eid        = $data{External_Identifier}[0];
    my $location   = $data{Location}[0];
    my $rack_id    = $data{Rack_ID}[0];
    my $status     = $data{Source_Status}[0] || 'undef status';
    my $amount     = $data{Amount}[0];
    my $rcvd       = $data{Received_Date}[0];
    my $derivation = $data{FKSource_Plate__ID}[0];
    my $parent     = $data{FKParent_Source__ID}[0];
    my $src_number = $data{Source_Number}[0];
    my $sm_type    = $data{FK_Storage_Medium__ID}[0];
    my $sm_unit    = $data{Storage_Medium_Quantity_Units}[0];
    my $sm_volume  = $data{Storage_Medium_Quantity}[0];
    my $src_type   = $data{Sample_Type}[0];

    $sm_volume =~ s/0+$/0/;    ## trim trailing zeros...

    my $redefine;
    if ( $source_id && $source_id !~ /,/ ) {
        ($redefine) = $dbc->Table_find( ' Plate_Attribute , Attribute', 'FK_Plate__ID', "WHERE FK_Attribute__ID = Attribute_ID and Attribute_Name = 'Redefined_Source_For' and Attribute_Value =$source_id" );
    }

    my $label = "\n<!--- Source LABEL --->\n";
    $label .= alDente::Tools::alDente_ref( 'Source', $source_id, -dbc => $dbc ) . " [<B>$status</B>]\n";
    $label .= "<BR>Rcvd: $rcvd\n";
    $label .= "<BR>Origin: $os_name\n";

    ## colour grey if inactive, or red if failed/cancelled ##
    if ( $status =~ /(Failed|Cancelled)/ ) { $colour = '#FFcccc' }
    elsif ( $status !~ /^Active/i ) { $colour = '#cccccc' }

    if ( $dbc->table_loaded('Taxonomy') && $dbc->table_loaded('Anatomic_Site') ) { $label .= "[$tax : $tissue]\n" }

    my ($nature) = $dbc->Table_find( 'Source', 'FK_Sample_Type__ID', "WHERE Source_ID=$source_id" );
    if ($nature) { $label .= "<BR>Type:" . alDente::Tools::alDente_ref( 'Sample_Type', $nature, -dbc => $dbc ) . " ($amount)\n" }

    if ($eid) { $label .= "<BR>External ID: <B>$eid</B>\n" }
    $label .= "<BR>Location: " . alDente::Tools::alDente_ref( 'Rack', $rack_id, -dbc => $dbc ) . "\n";
    if ($sm_type)    { $label .= "<BR>In $sm_volume $sm_unit of " . alDente::Tools::alDente_ref( 'Storage_Medium', $sm_type,    -dbc => $dbc ) . "\n" }
    if ($derivation) { $label .= "<BR>Derived from: " . alDente::Tools::alDente_ref( 'Plate',                      $derivation, -dbc => $dbc ) . "\n" }
    if ($redefine)   { $label .= "<BR>Redefined into: " . alDente::Tools::alDente_ref( 'Plate',                    $redefine,   -dbc => $dbc ) . "\n" }
    if ($parent)     { $label .= "<BR>Parent: " . alDente::Tools::alDente_ref( 'Source',                           $parent,     -dbc => $dbc ) . "\n" }

    ## check if Source has associated libraries and create links out of library names
    my @libs = $dbc->Table_find( 'Library_Source', 'FK_Library__Name', "WHERE FK_Source__ID IN ($source_id)", -distinct => 1 );

    my $lib_list = '';
    if (@libs) {
        foreach my $lib (@libs) {
            my $lib_link = &Link_To( $dbc->config('homelink'), $lib, "&HomePage=Library&ID=$lib", $Settings{LINK_COLOUR}, ['newwin'] );
            $lib_list .= "$lib_link ";
        }
    }
    else {
        pop @libs;
        $lib_list .= '<font color=red> None </font>';
    }
    $label .= "<BR>Source of Collections: " . $lib_list . "\n";

    #label =~ s/\n/<BR>/g;
    if ($verbose) {
        if ( $dbc->package_active('GSC') ) {
            my @alerts = $dbc->Table_find( 'Source_Alert, Alert_Reason', "Concat(Source_Alert.Alert_Type,': ' ,Alert_Reason, ' (',Alert_Notification_Date,')') AS Alert", " WHERE FK_Alert_Reason__ID = Alert_Reason_ID AND FK_Source__ID IN ($source_id)" );
            my $alert_label;
            if ( int @alerts ) {
                $alert_label = "Alerts: " . vspace();
                for my $alert (@alerts) {
                    $alert =~ s/,//g;
                    $alert_label .= "<font color=red> $alert </font>" . vspace();
                }

                $label .= '<BR>' . $alert_label;
            }
        }
    }

    ## show process deviation
    if ($verbose) {
        my @pds = $dbc->Table_find( 'Process_Deviation_Object,Object_Class', 'FK_Process_Deviation__ID', "WHERE FK_Object_Class__ID = Object_Class_ID and Object_Class = 'Source' and Object_ID in ($source_id) " );
        if ( int(@pds) ) {
            require alDente::Process_Deviation_Views;
            my $deviation_label = alDente::Process_Deviation_Views::deviation_label( -dbc => $dbc, -deviation_ids => \@pds );
            $label .= '<BR>' . $deviation_label;
        }
    }

    # .= '<hr>';
    $label .= '<BR>' . alDente::Attribute_Views::show_Attributes( $dbc, 'Source', $source_id );

    if ($verbose) {
        my $relocation_link = $dbc->homelink() . 'cgi_application=alDente::Rack_App&rm=Storage+History&Table=Source&ID=' . $source_id;
        $label .= '<P></P>' . &Link_To( $relocation_link, "Show Relocation History" );

        # $label .= '<P></P>' . alDente::Rack_Views::show_Relocation_History( 'Source', $source_id, -dbc => $dbc );
    }
    else {
        ## basic information only ##
        my $title;
        if ( !$dbc->mobile() ) {
            $title = Link_To( $dbc->config('homelink'), $Prefix{Source} . $source_id, "&HomePage=Source&ID=$source_id", -tooltip => $label, -convert_to_HTML => 0 );
        }
        else {
            my $modal_label = &object_label( -id => $source_id, -dbc => $dbc, -verbose => 1 );
            my $src_link = "<h4 style='float:left'>" . Link_To( $dbc->config('homelink'), "Click to View Homepage for $Prefix{Source}$source_id", "&HomePage=Source&ID=$source_id", -convert_to_HTML => 0 ) . "</h4>";
            $title = $BS->custom_modal( -id => $source_id, -label => $Prefix{Source} . $source_id, -title => $Prefix{Source} . $source_id, -body => $modal_label, -type => 'primary', -footer => $src_link );
        }

        if ($detailed) {
            if ( $src_number =~ /^p(\d+)/i ) {
                $title .= $br . "Part of Pool $1";
            }

            $title .= $br . $src_type . ' # ' . $src_number;                                                       ##  alDente::Tools::alDente_ref( 'Sample_Type', $nature, -dbc => $dbc ) if $nature;
            $title .= $br . 'from OS ' . alDente::Tools::alDente_ref( 'Original_Source', $os_id, -dbc => $dbc );

            if ( $sm_type && $sm_volume > 0 ) {
                $title .= $br . 'In ' . $sm_volume . $sm_unit . ' of ' . alDente::Tools::alDente_ref( 'Storage_Medium', $sm_type, -dbc => $dbc );
            }
            $title .= $br;
        }
        $label = $title;
    }

    $label .= "\n<!-- End of span div -->\n<!-- End of Source Label -->\n\n";
    return $label;
}

##############################
sub get_plates_HTML {
##############################
    # Get details of the offspring sources for a particular Sample_Origin (plates, etc)
    #
    #  Ex: $source_obj->get_plates_HTML();
    #
    #  Returns:
    #
##############################

    my %args = @_;
    my $dbc  = $args{-dbc};

    my $Source                  = $args{-Source};
    my $source_id               = $args{-source_id} || $Source->{id};
    my $include_inactive_plates = $args{-include_inactive};
    my $tables                  = 'Source,Sample,Plate_Sample,Plate,Sample_Type LEFT JOIN Plate_Attribute ON Plate_Attribute.FK_Plate__ID=Plate_ID LEFT JOIN Attribute ON Plate_Attribute.FK_Attribute__ID=Attribute_ID';
    my @names;
    my @plate_ids;
    my @plate_name;
    my @plate_type;
    my @plate_status;
    my @rack_id;
    my $plate_link;
    my $message         = 'No records';
    my $extra_condition = " AND Plate_Status='Active'" unless $include_inactive_plates;
    my $name_view       = "concat(Plate.FK_Library__Name,'-',Plate.Plate_Number)";

    my %plates = $dbc->Table_retrieve(
        'Source,Sample,Plate_Sample,Plate,Sample_Type', [ 'Plate_ID', 'Plate.FK_Library__Name as Lib', "$name_view as Name", 'Sample_Type.Sample_Type as Contents', 'Plate_Status as Status', 'Failed', 'Plate.FK_Rack__ID as Rack', ],
        "WHERE Sample.FK_Source__ID IN ($source_id) AND Sample.FK_Source__ID = Source.Source_ID AND Plate_Sample.FK_Sample__ID=Sample.Sample_ID AND 
        Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate.FK_Sample_Type__ID = Sample_Type.Sample_Type_ID $extra_condition", -distinct => 1
    );

    my $Ancestry = new HTML_Table( -title => 'Plates/Tubes Associated to Src: $source_id' );
    $Ancestry->Set_Headers( [ 'Plate_ID', 'Library', 'Contents', 'Status', 'Failed', 'Location' ] );

    ## generate this form manually so that plate labels (object_label) can be included instead of standard plate_id links ##

    my $index = 0;
    while ( defined $plates{Plate_ID}[$index] ) {
        my ( $plate, $name, $status, $failed, $rack, $contents ) = ( $plates{Plate_ID}[$index], $plates{Name}[$index], $plates{Status}[$index], $plates{Failed}[$index], $plates{Rack}[$index], $plates{Contents}[$index] );
        $index++;
        $Ancestry->Set_Row(
            [   Link_To( $dbc->config('homelink'), "$plate", "&HomePage=Plate&ID=$plate", -tooltip => alDente::Container_Views::object_label( -dbc => $dbc, -plate_id => $plate ) ),
                $name, $contents, $status, $failed, alDente::Tools::alDente_ref( 'Rack', $rack, -dbc => $dbc )
            ]
        );
    }

    my $page;
    $page .= $Ancestry->Printout(0);

    return $page;
}

##############################
#  Displays a confirmation page for the deletion of Source and corresponding FK_Source__ID records.
#
#  Usage:
#  ($ref_tables, $details, $ref_fields) = $dbc->getreferences ( -table => $table, -field => $primary, -value => $ids, -indirect => 1 );
#  delete_confirmation_page( -dbc => $dbc, $ids => $ids, -ref_tables => $ref_tables, -ref_fields => $ref_fields);
#
##############################
sub delete_confirmation_page {
##############################
    my %args       = &filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $ids        = $args{-ids};
    my $ref_tables = $args{-ref_tables};
    my $ref_fields = $args{-ref_fields};
    my $debug      = $args{-debug};
    my $q          = new CGI;

    # $ref_tables contains links which sometimes have comma-delimited lists embedded
    # in them. Therefore split by link tag (</a>) to avoid breaking the links.
    my @tables = split /<\/a>,/i, $ref_tables;
    my @broken_links = splice( @tables, 0, -1 );
    my $last_link = $tables[-1];

    @tables = map { $_ .= '</a>' } @broken_links;
    push @tables, $last_link;

    my %fields = %$ref_fields if $ref_fields;

    my $messages = "Are you sure you wish to delete these sources and the fields that reference them?" . vspace();
    my %table_hash;

    foreach my $link (@tables) {
        $link =~ /<a.+Field=(\w+).+>(.+)<\/a>/i;
        my $record = "$2.$1";
        Message( "Deleting " . scalar @{ $fields{$record} } . " records in " . $link );
    }

    my $page = alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'confirmation' )
        . $dbc->Table_retrieve_display(
        -table       => 'Source',
        -title       => 'Source',
        -condition   => " WHERE Source_ID IN ($ids)",
        -fields      => ['*'],
        -return_html => 1
        )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 )
        . $q->hidden( -name => 'src_id',          -value => $ids,                  -force => 1 )
        . $q->hidden( -name => 'confirm',         -value => '1',                   -force => 1 )
        . vspace()
        . $messages
        . $q->submit( -name => 'rm', -value => 'Delete Source', -force => 1, -class => "Action" )
        . $q->end_form('confirmation');

    return $page;
}

############################################
# Add goal button for creating work requests
# for selected sources
############################################
sub add_goal_btn {
##############################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my $validation_filter = "this.form.target='_blank';sub_cgi_app( 'alDente::Source_App');";
    my $form_output = Show_Tool_Tip( submit( -name => 'rm', -value => 'Add Goals', -class => 'Action', -onClick => "$validation_filter", -force => 1 ), "Create work request and add goals for selected sources. " );

    $form_output .= hidden( -id => 'sub_cgi_application', -force => 1 );
    $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true',          -force => 1 );
    $form_output .= hidden( -name => 'class',                -value => 'Source',        -force => 1 );
    $form_output .= hidden( -name => 'key',                  -value => 'FK_Source__ID', -force => 1 );

    return $form_output;
}

############################################
# Display archive button for archiving sources
#
# Return: HTML page
############################################
sub display_archive_btn {
##############################
    my %args      = filter_input( \@_, -args => 'dbc' );
    my $dbc       = $args{-dbc};                           # the database connection
    my $from_view = $args{-from_view};                     # A parameter that needs to be set if this button is being used in a view. If it is from a view, the run mode will be handled via sub_cgi_app

    my $page;
    my $onclick;
    if ($from_view) {
        $page .= hidden( -id => 'sub_cgi_application', -force => 1 );
        $page .= hidden( -name => 'RUN_CGI_APP', -value => 'AFTER', -force => 1 );
        $onclick = "sub_cgi_app( 'alDente::Source_App')";
    }
    else {
        $page .= hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 );
    }

    $page
        .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Archive Source', -class => 'Action', -onClick => "$onclick", -force => 1 ), "Archive selected sources" )
        . hspace(5)
        . Show_Tool_Tip( "Comments: " . textfield( -name => 'Comments', -size => 30, -default => '' ), "Comments will be appended to Source Notes" );

    return $page;

}
###########################
# Display the source pooling interface
#
#	<Usage>
#		my $page = alDente::Source_Views::pool_sources( -dbc => $dbc, -source_id => $srouce_ids, -batches => \%batches, -on_conflict => $on_conflict );
#
# Return:	HTML page
###########################
sub pool_sources {
###########################
    my %args                    = filter_input( \@_, -args => 'dbc,batches,input_value', -mandatory => 'dbc' );
    my $dbc                     = $args{-dbc};
    my $source_id               = $args{-source_id};
    my $batches                 = $args{-batches};                                                                # batches of source ids. e.g. $batches{batch1} = [123, 456]
    my $on_conflict             = $args{-on_conflict};
    my $input_value             = $args{-input_value};                                                            # contains user entered values for the fields that need input
    my $pool_all_amount_default = $args{-pool_all_amount};                                                        # carry forward the choice made from the previous page
    my $test = $args{-test};    ## flag indicating we are only prompting for user input at this stage...                                                                     ## handling details for pooling conflict

    my @batch_arr  = sort keys %$batches;
    my @source_ids = ();
    if ($source_id) { @source_ids = Cast_List( -list => $source_id, -to => 'array' ) }

    # combine all sources
    my $all_sources = \@source_ids;
    foreach my $batch (@batch_arr) {
        $all_sources = RGmath::union( $all_sources, $batches->{$batch}{src_ids} );
    }
    if ( !int(@$all_sources) ) { $dbc->error("No sources for pooling!"); return }

    my $all_source_str = join ',', @$all_sources;
    my %source_volumes = $dbc->Table_retrieve( 'Source', [ 'Source_ID', 'Current_Amount', 'Amount_Units' ], "WHERE Source_ID in ($all_source_str)", -key => 'Source_ID', -distinct => 1 );

    my $action_button = RGTools::Web_Form::Submit_Button(
        name         => 'rm',
        value        => 'Validate Pooling',                                                                                                                        #'Submit Pooling Request'
        class        => 'Action',
        validate     => 'poolTargetWells',
        form         => 'thisform',
        validate_msg => 'Please enter target pool batch information by selecting sources (left hand side) and click on the target pool batch (right hand side)',
        onClick      => "return validateForm(this.form);"
    );

    my $output = alDente::Form::start_alDente_form( -dbc => $dbc );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 );
    $output .= Safe_Freeze( -name => "Pool_Batch_Info", -value => $batches, -format => 'hidden', -encode => 1 );
    my $instructions = "To Pool: Select sources to pool on left and then click on Pool Selected Sources button or Target pool batch column on right to apply";
    my $allTables = HTML_Table->new( -title => "Select Sources from 'Sources To Pool' to 'Target Pool Batches'", -border => 1 );
    $allTables->Set_Headers( [ 'Source', ' ', 'Target Pool' ] );
    $allTables->Set_sub_header( $instructions, 'lightredbw' );

    ## source table
    my $selectwell;
    my $clearwell;

    foreach my $sid (@$all_sources) {
        $clearwell  .= "SetSelection(this.form,\"Wells$sid\",0,\"all\");";
        $selectwell .= "SetSelection(this.form,\"Wells$sid\",1,\"all\");";
    }
    my $selectAll = button( -name => 'Select All',          onClick => $selectwell, -class => 'Std' );
    my $clear     = button( -name => 'Clear Selected List', onClick => $clearwell,  -class => 'Std' );
    $output .= hidden( -name => 'Exclude', -id => 'Exclude', -value => '', -force => 1 );    # SetListSelection requires 'Exclude', although 'Exclude' is not used here
    my $all_amount_box
        = Show_Tool_Tip( checkbox( -name => "Pool_All_Amount", -value => 'Pool_All_Amount', -label => 'Pool entire amount of each Source ', -checked => $pool_all_amount_default, -force => 1 ), "Check to use entire content of each source for pooling" );

    my $sourceTables = HTML_Table->new( -title => "Sources To Pool" . hspace(20) . $selectAll . hspace(20) . $clear . hspace(50) . $all_amount_box );
    $sourceTables->Set_Headers( [ 'Source_ID', 'Select', 'Current_Amount', 'Amount_Units', 'Amount and Units To Pool' ] );

    ## Target batch table
    my $add_action = Show_Tool_Tip( button( -name => 'Pool Selected Sources', onClick => "addPoolBatch('target_table','Pool_Count','Submit Pool Request');", -class => "Std" ), "Apply Sources Selected At Left To Next Pool" );
    my $remove_action = button( -name => 'Remove Last Pool Entry', onClick => "removePoolBatch('target_table', 'Pool_Count');", -class => "Std" );
    my $target_table = HTML_Table->new( -title => "Target Pool Batches", -id => 'target_table' );

    my $batch_count   = int(@batch_arr);
    my $next_batch_ID = 1;
    if ($batch_count) { $next_batch_ID = $batch_arr[-1] + 1 }
    $output .= hidden( -id => 'Next_Batch_ID', -name => 'Next_Batch_ID', -value => $next_batch_ID, -force => 1 );
    $output .= hidden( -name => 'Pool_Count', -id => 'Pool_Count', -value => $batch_count, -force => 1 );
    if ($input_value) {
        $output .= Safe_Freeze( -name => "Input_Value", -value => $input_value, -format => 'hidden', -encode => 1 );
    }
    my %input_for_all;
    my @shown = ();
    foreach my $batch (@batch_arr) {
        my @srcs = Cast_List( -list => $batches->{$batch}{src_ids}, -to => 'array' );
        my @source_info;
        for my $sid (@srcs) {
            if ( defined $batches->{$batch}{$sid}{amnt} && $batches->{$batch}{$sid}{amnt} ) {
                push @source_info, $sid . '[' . $batches->{$batch}{$sid}{amnt} . ' ' . $batches->{$batch}{$sid}{unit} . ']';
            }
            else {
                push @source_info, $sid;
            }
            unless ( grep /^$sid$/, @shown ) {
                my $source_label = alDente::Source_Views::object_label( -source_id => $sid, -dbc => $dbc );
                my $select_box = Show_Tool_Tip( checkbox( -id => "Wells$sid", -name => "Wells$sid", -label => '', -checked => 0, -force => 1 ), "Select source $sid for pooling" );
                my @source_unit_list = $dbc->get_enum_list( 'Source', 'Amount_Units' );
                my $default_amnt     = '';                                                #$source_volumes{$sid}{Current_Amount}[0];	# set default amount to the current amount???
                my $default_unit     = $source_volumes{$sid}{Amount_Units}[0];            # set the default unit to be the Amount_Units
                my $pool_volume_spec = Show_Tool_Tip(
                    textfield( -name => "Pool_Amount$sid", -id => "Pool_Amount$sid", -default => $default_amnt, -force => 1, -class => 'narrow-txt' )
                        . popup_menu( -name => "Pool_Units$sid", -id => "Pool_Units$sid", -values => \@source_unit_list, -default => $default_unit, -force => 1 ),
                    "Enter the amount and units to pool"
                );
                $sourceTables->Set_Row( [ $source_label, $select_box, $source_volumes{$sid}{Current_Amount}[0], $source_volumes{$sid}{Amount_Units}[0], $pool_volume_spec ] );

                push @shown, $sid;
            }
        }
        my $text = join ',', @source_info;

        my $textbox = Show_Tool_Tip( textfield( -id => "Target$batch", -name => "poolTargetWells.$batch", -class => 'For_Update', -value => '', -default => $text, -size => 70, -force => 1, -onClick => "fill_single_pool(this.form,'Target$batch');" ),
            "Click here to apply currently selected sources" );
        my $label = "<span id='Pool_Label'>Pool $batch</span>";

        ## conflicts
        my $assign_for_batch;
        if ($input_value) { $assign_for_batch = $input_value->{$batch} }
        my ( %conflicts, %preset, %need_input );
        alDente::Source::merge_sources( -dbc => $dbc, -from_sources => $batches->{$batch}{src_ids}, -preset => \%preset, -unresolved => \%conflicts, -on_conflict => $on_conflict, -need_input => \%need_input, -assign => $assign_for_batch, -test => 1 );
        foreach my $field ( keys %need_input ) {
            foreach my $table ( keys %{ $need_input{$field} } ) {
                $input_for_all{$field}{$table}++;
            }
        }
        my $config_msg .= "<div id='pool.Source' style='display:block'>\n";
        $config_msg .= alDente::Form::merging_info( -dbc => $dbc, -preset => \%preset, -conflicts => \%conflicts, -id => $batch, -input => \%need_input, -ignore => 'FK_Original_Source__ID' );
        $config_msg .= "<P></div>\n";

        $target_table->Set_Row( [ $label . &hspace(3) . $textbox, create_tree( -tree => { "Pool Configuration" => $config_msg }, -default_open => "Pool Configuration" ) ] );
    }

    ## append sources that are not in the batches
    foreach my $sid (@$all_sources) {
        unless ( grep /^$sid$/, @shown ) {
            my $source_label = alDente::Source_Views::object_label( -source_id => $sid, -dbc => $dbc );
            my $select_box = Show_Tool_Tip( checkbox( -id => "Wells$sid", -name => "Wells$sid", -label => '', -checked => 0, -force => 1 ), "Select source $sid for pooling" );
            my $default_amnt = '';                                        #$source_volumes{$sid}{Current_Amount}[0];	# set default amount to the current amount???
            my $default_unit = $source_volumes{$sid}{Amount_Units}[0];    # set the default unit to be the Amount_Units

            my @source_unit_list = $dbc->get_enum_list( 'Source', 'Amount_Units' );
            my $pool_volume_spec = Show_Tool_Tip(
                textfield( -name => "Pool_Amount$sid", -id => "Pool_Amount$sid", -default => $default_amnt, -force => 1, -class => 'narrow-txt' )
                    . popup_menu( -name => "Pool_Units$sid", -id => "Pool_Units$sid", -values => \@source_unit_list, -default => $default_unit, -force => 1 ),
                "Enter the amount and units to pool"
            );
            $sourceTables->Set_Row( [ $source_label, $select_box, $source_volumes{$sid}{Current_Amount}[0], $source_volumes{$sid}{Amount_Units}[0], $pool_volume_spec ] );
            push @shown, $sid;
        }
    }

    # display one row if no preset batch
    if ( !$batch_count ) {
        my $batch = $next_batch_ID;
        my $label = "<span id='Pool_Label'>Pool $batch</span>";

        my $textbox = Show_Tool_Tip( textfield( -id => "Target$batch", -name => "poolTargetWells.$batch", -class => 'For_Update', -value => '', -size => 70, -force => 1, -onClick => "fill_single_pool(this.form,'Target$batch');" ),
            "Click here to apply currently selected sources" );
        $target_table->Set_Row( [ $label . &hspace(3) . $textbox, "<span>Pooling Conflicts Not Determined</span>" ] );
    }

    my @row = ( $sourceTables->Printout(0) );
    push @row, &vspace(50) . $add_action . &vspace(50) . $remove_action;
    push @row, $target_table->Printout(0);

    $allTables->Set_Row( \@row );
    $allTables->Set_VAlignment('top');

    ## add the section for user to enter values to apply to all batches
    if ( keys %input_for_all ) {
        my $PC = new HTML_Table( -title => "Global User Input" );
        foreach my $field ( keys %input_for_all ) {
            my @tables = keys %{ $input_for_all{$field} };
            my $table = int(@tables) ? $tables[0] : '';

            $output .= hidden( -name => 'Global_Input_List', -value => $field, -force => 1 );
            my ($type) = $dbc->Table_find( 'DBField', 'Field_Type', "WHERE Field_Name = '$field'" );
            my $input_spec = &SDB::DB_Form_Views::get_Element_Output(
                -dbc          => $dbc,
                -field        => $field,
                -table        => $table,
                -element_name => "IN.$field",
                -field_type   => $type,
            );
            $PC->Set_Row( [ $field, $input_spec ] );
        }
        $output .= $PC->Printout(0);

        $output .= submit( -name => 'rm', -value => 'Apply To All Batches', -class => "Std" );
        $output .= "<P>";
    }

    $output .= $allTables->Printout(0);
    $output .= '<BR>' . $action_button;
    $output .= end_form();

    return $output;
}

##################################
# This method displays the source pooling confirmation page
#
# Usage:
#	my $output = alDente::Source_Views::display_pool_sources_confirmation( -dbc => $dbc, -batches => \%pools, -user_input => \%input_value, -preset => \%preset );
#
# Return:
#	HTML string
##################################
sub display_pool_sources_confirmation {
##################################
    my %args           = filter_input( \@_, -args => 'dbc,batches,preset,consensus,no_volume', -mandatory => 'dbc' );
    my $dbc            = $args{-dbc};
    my $batches        = $args{-batches};                                                                               # hash ref, batch information
    my $consensus      = $args{-consensus};                                                                             # pooling consensus values
    my $preset         = $args{-preset};                                                                                # preset values
    my $auto_throw_out = $args{-auto_throw_out};                                                                        # flag for automatically throw away sources that are used up
    my $cell_style     = $args{-cell_style};
    my $debug          = $args{-debug};

    print HTML_Dump "batches:",   $batches   if ($debug);
    print HTML_Dump "preset:",    $preset    if ($debug);
    print HTML_Dump "consensus:", $consensus if ($debug);

    my $homelink   = $dbc->homelink();
    my $cell_style = $args{-cell_style} || "border-right: 1px solid white; padding:5px;";                               # indicate style for table cells if applicable.

    my $pool_table = new HTML_Table( -title => "Confirm Details Of Source Pooling", -border => 1, -cell_style => $cell_style, -size => 'medium' );
    $pool_table->Set_Headers( [ 'Pool Batch', 'Source Volumes', 'Presets', 'Pooling Consensus Values in Conflict' ] );
    foreach my $batch ( keys %$batches ) {
        my $source_ids = $batches->{$batch}{src_ids};
        ## volume
        my $volume_table = new HTML_Table( -padding => 10 );
        foreach my $sid (@$source_ids) {
            my $name = $dbc->get_FK_info( -field => 'FK_Source__ID', -id => $sid );
            my $src_link = &Link_To( $homelink, $name, "&HomePage=Source&ID=$sid", $Settings{LINK_COLOUR} );
            if ($auto_throw_out) {
                my $throw_out = '';
                if ( $batches->{$batch}{$sid}{used_up} ) { $throw_out = '(Throw Away)' }
                $volume_table->Set_Row( [ $src_link, $batches->{$batch}{$sid}{amnt}, $batches->{$batch}{$sid}{unit}, $throw_out ] );
            }
            else {
                $volume_table->Set_Row( [ $src_link, $batches->{$batch}{$sid}{amnt}, $batches->{$batch}{$sid}{unit} ] );
            }
        }

        ## preset
        my $preset_table = new HTML_Table( -padding => 10 );
        foreach my $key ( keys %{ $preset->{$batch} } ) {
            my $value = $preset->{$batch}{$key};
            my ( $TableName, $id_field, $descrip ) = $dbc->foreign_key_check($key);
            if ( $TableName && $id_field && $value ) {
                $value = $dbc->get_FK_info( -field => $key, -id => $value );
                $value = &Link_To( $homelink, $value, "&HomePage=$TableName&ID=$preset->{$batch}{$key}", $Settings{LINK_COLOUR} );
            }
            $preset_table->Set_Row( [ $key, $value ] );
        }

        ## pooling consensus
        my $consensus_table = new HTML_Table();
        foreach my $key ( keys %{ $consensus->{$batch} } ) {
            my $value = $consensus->{$batch}{$key};
            my ( $TableName, $id_field, $descrip ) = $dbc->foreign_key_check($key);
            if ( $TableName && $id_field && $value ) {
                $value = $dbc->get_FK_info( -field => $key, -id => $value );
                $value = &Link_To( $homelink, $value, "&HomePage=$TableName&ID=$consensus->{$batch}{$key}", $Settings{LINK_COLOUR} );
            }
            $consensus_table->Set_Row( [ $key, $value ] );
        }
        my $consensus_tree = create_tree( -tree => { 'Concensus Values' => $consensus_table->Printout(0) } );
        $pool_table->Set_Row( [ $batch, $volume_table->Printout(0), $preset_table->Printout(0), $consensus_tree ] );
    }

    my $output = alDente::Form::start_alDente_form( "confirm_pooling", -dbc => $dbc );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 );
    $output .= Safe_Freeze( -name => 'Batches',   -value => $batches,   -format => 'hidden', -encode => 1 );
    $output .= Safe_Freeze( -name => 'Preset',    -value => $preset,    -format => 'hidden', -encode => 1 );
    $output .= Safe_Freeze( -name => 'Consensus', -value => $consensus, -format => 'hidden', -encode => 1 );
    $output .= $pool_table->Printout(0);
    $output .= '<BR>' . submit( -name => 'rm', -value => 'Confirm Pooling', -class => "Action", -force => 1 );
    $output .= end_form();

    return $output;
}

############################################
# Display Throw Away button
#
# Return: HTML page
############################################
sub display_throw_away_btn {
##############################
    my %args      = filter_input( \@_, -args => 'dbc' );
    my $dbc       = $args{-dbc};                           # the database connection
    my $from_view = $args{-from_view};                     # A parameter that needs to be set if this button is being used in a view. If it is from a view, the run mode will be handled via sub_cgi_app
    my $confirmed = $args{-confirmed};

    my $page;
    my $onclick;
    if ($from_view) {
        $page .= hidden( -id => 'sub_cgi_application', -force => 1 );
        $page .= hidden( -name => 'RUN_CGI_APP', -value => 'AFTER', -force => 1 );
        $onclick = "sub_cgi_app( 'alDente::Source_App')";
    }
    else {
        $page .= hidden( -name => 'cgi_application', -value => 'alDente::Source_App', -force => 1 );
    }

    $page .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Throw Away Source', -class => 'Action', -onClick => "$onclick", -force => 1 ), "Throw away selected sources" );

    if ($confirmed) { $page .= hidden( -name => 'Confirmed', -value => $confirmed, -force => 1 ) }

    return $page;

}

1;
