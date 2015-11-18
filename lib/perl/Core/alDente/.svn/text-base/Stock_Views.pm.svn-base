package alDente::Stock_Views;

use strict;
use RGTools::RGIO;
use RGTools::Conversion;

use SDB::HTML;
use SDB::DBIO;
use SDB::CustomSettings;
use SDB::DB_Form_Views;

#use alDente::Validation;
#use alDente::SDB_Defaults;
use alDente::Tools;
use alDente::Form;
use alDente::Stock;

use vars qw(%Configs $Security %Settings);

my $q = new CGI;
##################################################################
# Search for Stock Section
##################################################################
#########################
sub display_entry_page {
#########################
    my %args          = filter_input( \@_ );
    my $dbc           = $args{-dbc};
    my $box_item_type = $args{-box_item_type};
    my $box_id        = $args{-box_id};

    my $tip = 'Enter any portion of the catalog number or name to retrieve current stock item. Use * for wildcard if desired';
    my @choices = ( 'By Catalog Number', 'By Name' );

    my $table = alDente::Form::init_HTML_table( -title => 'Receive New Stock', -margin => 'on' );
    my $LV = new alDente::Login_Views(-dbc=>$dbc);
    $table->Set_Row(
        [   $LV->icons( 'Receiving', -dbc => $dbc ),
            RGTools::Web_Form::Submit_Button(
                form         => 'Catalog_box',
                name         => 'rm',
                label        => 'New Stock',
                validate     => 'Stock_Search_String',
                validate_msg => 'Please enter a stock catalog number or stock name first.'
                )
                . hspace(1)
                . $q->radio_group(
                -name    => 'Stock_Search_By',
                -value   => \@choices,
                -default => 'By Catalog Number'
                )
                . hspace(1)
                . Show_Tool_Tip(
                $q->textfield(
                    -name    => 'Stock_Search_String',
                    -size    => 15,
                    -default => ''
                ),
                "$tip"
                )
        ]
    );

    my $form .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Catalog_box' ) . $table->Printout(0) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Stock_App', -force => 1 );
    if ($box_id) {
        $form .= $q->hidden( -name => 'box_id', -value => $box_id, -force => 1 ) . $q->hidden( -name => 'box_item_type', -value => $box_item_type, -force => 1 );
    }

    $form .= $q->end_form();

    return $form;
}

#########################
sub display_stock_item {
#########################
    my %args         = filter_input( \@_ );
    my $dbc          = $args{-dbc};
    my $cat_ids_ref  = $args{-ids};
    my $table        = $args{-table};
    my $active       = $args{-active};
    my $id_term      = "$table" . "_ID";
    my $status_term  = "$table" . '_Status';
    my $cat_ids_list = join ',', @$cat_ids_ref;
    my $active_list  = "'In Use', 'Open', 'Unopen','Used','Unused','Unopened'";

    my $condition = "WHERE FK_Stock__ID = Stock_ID AND FK_Stock_Catalog__ID IN ($cat_ids_list)";
    if ($active) {
        $condition .= " AND $status_term IN ($active_list) ";
    }
    my @field_list = $dbc->get_field_list( -table => $table );
    my @item_ids = $dbc->Table_find( $table . ',Stock', "$id_term", $condition );
    my $item_id_list = join ',', @item_ids;
    unless ($item_id_list) {
        $item_id_list = 0;
    }

    my $view = &SDB::DB_Form_Viewer::mark_records(
         $dbc, $table, [@field_list], "WHERE $id_term in ($item_id_list)",
        -add_html    => '<HR>',
        -return_HTML => 1
    );

}

#########################
sub display_category_activation_page {
#########################
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $catalog_id = $args{-catalog_id};
    my $list       = $args{-catalog_ids_list};

    my $db_obj = SDB::DB_Object->new( -dbc => $dbc );
    $db_obj->add_tables('Stock_Catalog');
    $db_obj->{stock_catalog_id} = $catalog_id;
    $db_obj->primary_value( -table => 'Stock_Catalog', -value => $catalog_id );    ## same thing as above..
    $db_obj->load_Object( -type => 'Stock_Catalog' );
    my $details = $db_obj->display_Record( -tables => ['Stock_Catalog'], -index => "index $catalog_id", -truncate => 40 );
    Message ' DONT GUESS the category, ask someone or if it is not available please contact LIMS';

    my $message = 'This item has been deactivated because it did not have a equipment category. ' . vspace() . ' Note that this selection is very important and should not be treated lightly. ' . vspace() . vspace();

    my $selection
        = $message
        . alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Category_Assigning' )
        . &SDB::HTML::query_form( -dbc => $dbc, -fields => ['Stock_Catalog.FK_Equipment_Category__ID'], -action => 'search' )
        . $q->hidden( -name => 'cgi_application',  -value => 'alDente::Stock_App', -force => 1 )
        . $q->hidden( -name => 'catalog_id',       -value => $catalog_id,          -force => 1 )
        . $q->hidden( -name => 'catalog_ids_list', -value => $list,                -force => 1 )
        . $q->hidden( -name => 'confirmed',        -value => 1,                    -force => 1 )
        .

        RGTools::Web_Form::Submit_Button(
        form         => 'Category_Assigning',
        name         => 'rm',
        class        => 'Action',
        label        => 'Assign Category',
        validate     => 'FK_Equipment_Category__ID Choice',
        validate_msg => 'You need to select a category first.'
        ) . $q->end_form();

    return $selection . vspace() . $details;

    #    &Views::Table_Print( content => [ [ $selection, $details ] ], spacing => 3 );
    #    return ;
}

#########################
sub display_simple_activation_page {
#########################
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $catalog_id = $args{-catalog_id};
    my $list       = $args{-catalog_ids_list};

    my $db_obj = SDB::DB_Object->new( -dbc => $dbc );
    $db_obj->add_tables('Stock_Catalog');
    $db_obj->{stock_catalog_id} = $catalog_id;
    $db_obj->primary_value( -table => 'Stock_Catalog', -value => $catalog_id );    ## same thing as above..
    $db_obj->load_Object( -type => 'Stock_Catalog' );
    my $details = $db_obj->display_Record( -tables => ['Stock_Catalog'], -index => "index $catalog_id", -truncate => 40 );
    Message('Are you sure you wish to activate this Stock Catalog Entry?');
    my $selection
        = alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Simple_Activation' )
        . $q->submit( -name => 'rm', -value => 'Activate', -force => 1, -class => 'Action' )
        . $details
        . $q->hidden( -name => 'confirmed',        -value => 'confirmed',          -force => 1 )
        . $q->hidden( -name => 'cgi_application',  -value => 'alDente::Stock_App', -force => 1 )
        . $q->hidden( -name => 'catalog_id',       -value => $catalog_id,          -force => 1 )
        . $q->hidden( -name => 'catalog_ids_list', -value => $list,                -force => 1 )
        . $q->end_form();
}

#########################
sub display_list_page {
#########################
    my %args          = filter_input( \@_ );
    my $dbc           = $args{-dbc};
    my $box_id        = $args{-box_id};
    my $box_item_type = $args{-box_item_type};
    my $list_ref      = $args{-list};            ### a reference to array of matched catalog id's

    #   my $number		= $args { -cat	};  					 	### catalog number entered (normal input for new stock) - presets most fields on form
    #   my $name		= $args { -name	};  						### stock name (normal input for new stock) - presets most fields on form

### 	to create link to edit page
    my $found_ids = join ',', @$list_ref;
    my $hide      = 'Stock_Source,Stock_Size,Stock_Size_Units';
    my $edit_link = &Link_To( $dbc->config('homelink'), 'edit these', "&Edit+Table=Stock_Catalog&Field=Stock_Catalog_ID&Like=$found_ids&Hide=$hide", 'red', ['newwin'] );

    ##      creating the page
    my $page = "Please $edit_link names if they are inconsistent" . lbr;
    $page .= "<UL>";

    my $table = alDente::Form::init_HTML_table( -title => 'Catalog', -width => '80%' );
    $table->Set_Row( [ 'Stock Description', 'Type', 'Manufacturer', 'Vendor', 'Catalog Number', 'Size', 'Units', 'Status', 'Edit Item' ], 'lightblue' );

    foreach my $stock_id (@$list_ref) {
        my @info = $dbc->Table_find(
            -table     => 'Stock_Catalog',
            -fields    => "Stock_Status,Stock_Type,Stock_Size,Stock_Size_Units, FK_Organization__ID,FKVendor_Organization__ID,Stock_Catalog_Number",
            -condition => "WHERE Stock_Catalog_ID = $stock_id"
        );
        my ( $status, $type, $size, $units, $manufacturer_id, $vendor_id, $cat_number ) = split ',', $info[0];
        my $manufacturer = alDente_ref( 'Organization', -id => $manufacturer_id, -dbc => $dbc );
        my $vendor       = alDente_ref( 'Organization', -id => $vendor_id,       -dbc => $dbc );
        my $cat_id = alDente_ref( 'Stock_Catalog', -id => $stock_id, -new_link => "&cgi_application=alDente::Stock_App&rm=Stock+Form&stock_catalog_id=$stock_id", -dbc => $dbc );
        if ($box_id) {
            $cat_id = alDente_ref( 'Stock_Catalog', -id => $stock_id, -new_link => "&cgi_application=alDente::Stock_App&rm=Stock+Form&stock_catalog_id=$stock_id&Box_ID=$box_id", -dbc => $dbc );
        }
        my $single_edit_link = &Link_To( $dbc->config('homelink'), 'Edit', "&Search=1&Table=Stock_Catalog&Search+List=$stock_id&No+Copy=1", 'red', ['newwin'] );

        if ( $status eq 'Inactive' ) {
            $status = Show_Tool_Tip( &Link_To( $dbc->config('homelink'), $status, "&cgi_application=alDente::Stock_App&rm=Activate+Catalog+Item&stock_catalog_id=$stock_id&cata_id_list=$found_ids", 'red' ),
                'This item has been deactived, Please click here to reactivate it' );

            $cat_id = alDente_ref( 'Stock_Catalog', -id => $stock_id, -no_link => 1, -dbc => $dbc );

            # $cat_id =Show_Tool_Tip( alDente_ref( 'Stock_Catalog', -id => $stock_id, -no_link=>1),
            #                    'This item has been deactived, Please click on the "Inactive" link to reactivate it');
        }
        $table->Set_Row( [ $cat_id, $type, $manufacturer, $vendor, $cat_number, $size, $units, $status, $single_edit_link ] );
    }
    $page .= $table->Printout(0);
    $page .= "</UL><HR/>";
    return $page;

}

#########################
sub display_inventory_records {
#########################
    my %args        = filter_input( \@_ );
    my $dbc         = $args{-dbc};
    my $catalog_IDS = $args{-catalog_ids};
    my $id_list     = join ',', @$catalog_IDS;
    my @fields_list = (
        'Stock_Catalog_Name',
        'Stock_Catalog.Stock_Type as Type',
        'Stock_Catalog.FK_Organization__ID',
        'Stock_Catalog.Stock_Catalog_Number as CatalogNumber',
        'FKVendor_Organization__ID as Vendor',
        'Stock_Catalog.Stock_Source as Source',
        'Stock_Catalog.Stock_Size as Size',
        'Stock_Catalog.Stock_Size_Units as Units',
        'Stock_Catalog.Stock_Status as Status'
    );
    my %layers;
    my $order;
    my @types = $dbc->get_enum_list( 'Stock_Catalog', 'Stock_Type' );

    for my $layer (@types) {

        my $type_ids = alDente::Stock::get_type_matched_ids( -dbc => $dbc, -type => $layer, -ids => $id_list );
        unless ($type_ids) { next; }
        my $add_on = $q->hidden( -name => 'stock_type', -value => $layer, -force => 1 );
        my $active_option = Show_Tool_Tip( $q->checkbox( -name => "Active", -force => 1, -checked => 1, -label => 'Active Items Only' ), 'Does not include, inactive.expired or thrown away items' );
        my $view = &SDB::DB_Form_Viewer::mark_records(
             $dbc, 'Stock_Catalog,Stock', [@fields_list], "WHERE FK_Stock_Catalog__ID=Stock_Catalog_ID AND Stock_Catalog_ID in ($type_ids) GROUP BY Stock_Catalog_ID Order by Stock_Catalog_Name",
            -add_html    => '<HR>',
            -application => 'alDente::Stock_App',
            -run_modes   => ['Find Stock Items'],
            -return_HTML => 1,
            -add_html    => $add_on . $active_option
        );
        $layers{$layer} = $view;
        $order .= "$layer,";
    }

    my $output = define_Layers(
        -layers => \%layers,
        ,
        -order     => $order,
        -tab_width => 100
    );
    return $output;
}

#########################
sub display_catalog_lookup {
#########################
    my %args          = filter_input( \@_ );
    my $dbc           = $args{-dbc};
    my $manufacturers = $args{-manufacturer};
    my $vendors       = $args{-vendor};
    my %list;
    my $open_option = 0;
    $list{'Stock_Catalog.FK_Organization__ID'}       = $manufacturers;
    $list{'Stock_Catalog.FKVendor_Organization__ID'} = $vendors;
    my @fields = qw(Stock_Catalog.Stock_Type Stock_Catalog.Stock_Source Stock_Catalog.FK_Organization__ID Stock_Catalog.FKVendor_Organization__ID );    ## maybe add in future: Stock_Catalog.FK_Equipment_Category__ID
    my $table = &SDB::HTML::query_form( -dbc => $dbc, -fields => \@fields, -action => 'search', -list => \%list );

    my $page
        = alDente::Form::start_alDente_form( $dbc, 'Catalog_Lookup' ) 
        . $table
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Stock_App', -force => 1 )
        . $q->submit( -name => 'rm', -value => 'Search Catalog', -force => 1, -class => 'Search' )
        . $q->end_form();

    my @fields = qw(Stock_Catalog.FK_Equipment_Category__ID );
    my $category_table = &SDB::HTML::query_form( -dbc => $dbc, -fields => \@fields, -action => 'search' );

    my $equipment_search
        = alDente::Form::start_alDente_form( $dbc, 'Catalog_Lookup' )
        . $category_table
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Stock_App', -force => 1 )
        . $q->submit( -name => 'rm', -value => 'Search Catalog', -force => 1, -class => 'Search' )
        . $q->end_form();

    my %view_layer = (
        'Search All Stock' => $page,
        'Search Equipment' => $equipment_search
    );

    my $form
        = "<h2>Catalog Lookup</H2>"
        . "Choose an option from 'Search All Stock' for general search or use 'Search Equipment' for choosing equipment according to their category"
        . vspace()
        . create_tree( -tree => \%view_layer, -tab_width => 100, -print => 0 );    # -default_open	=> 'Search All Stock'

    return $form;
}

#########################
sub display_stock_details {
#########################
    my %args   = &filter_input( \@_, -args => 'dbc,search,group' );
    my $dbc    = $args{-dbc};
    my $type   = $args{-type};
    my $search = $args{-search};
    my $s_name = $args{-name} || '%';
    my $label  = $args{-label};

    my $homelink = $dbc->homelink();

    my $info_ref = $args{-info};
    my %info = %$info_ref if $info_ref;

    my $colour = toggle_colour();

    my $details_table = HTML_Table->new( -title => 'Stock supply' );
    $details_table->Set_Headers( [ 'ID', 'Name', 'Bottle', 'Amount Used', 'Original Size', 'Opened/Created', 'Storage Location', 'Empty<Br><span class=\'mediumredtext\'>(Finished)</span></B>' ] );
    $details_table->Set_Border(1);

    $search ||= $s_name;

    my $row = 0;
    while ( defined $info{ID}[$row] ) {
        my $id       = $info{'ID'}[$row];
        my $bottle   = $info{'Number'}[$row];
        my $bottles  = $info{'Number_in_Batch'}[$row];
        my $used     = $info{'Quantity_Used'}[$row];
        my $units    = $info{'Stock_Size_Units'}[$row];
        my $size     = $info{'Stock_Size'}[$row];
        my $started  = $info{'Started'}[$row];
        my $finished = $info{'Finished'}[$row];
        my $rack     = $info{'Rack_Alias'}[$row];
        my $rack_id  = $info{'FK_Rack__ID'}[$row];
        my $status   = $info{'Status'}[$row];
        my $name     = $info{'Stock_Catalog_Name'}[$row];

        my $vol = &get_units( $size, $units );

        if ( $started =~ /^(\S+)/ ) {
            $started = $1;
        }    ### just show day (not time)

        if ( $finished =~ /^(\S+)/ ) {
            $finished = $1;
        }

        my $used_vol = &get_units( $used, $units );

        if ( $status =~ /Unopened/ ) {
            $details_table->Set_Cell_Colour( $row + 1, 5, $Settings{START_COLOUR} );
        }
        elsif ( $status =~ /Open/ ) {
            $status = $started;
            $details_table->Set_Cell_Colour( $row + 1, 5, $Settings{IP_COLOUR} );
        }
        elsif ( $status =~ /Finished/ ) {
            $status = $started;
            $details_table->Set_Cell_Colour( $row + 1, 5, $Settings{DONE_COLOUR} );
        }

        unless ($finished) {
            $finished = "No";
        }

        $details_table->Set_Row(
            [   $q->checkbox(
                    -name  => "Select Sol$id",
                    -force => 1,
                    -label => " "
                    )
                    . "<A Href=$homelink&HomePage=$type&ID=$id>$id</A>",
                $name,
                $bottle . "/" . $bottles,
                $used_vol,
                $vol, $status, $rack,
                $finished
            ]
        );

        $colour = &toggle_colour($colour);
        $row++;
    }

    my $SStats;
    $SStats .= $q->h2("Available $label");

    $SStats .= alDente::Form::start_alDente_form( $dbc, 'status' );

    $SStats .= $q->hidden( -name => 'Search String', -force => 1, -value => "$search" );

    $SStats .= $details_table->Printout( "$URL_temp_dir/Stock_Details.html", $html_header );
    $SStats .= $details_table->Printout(0);

    ( my $today ) = split ' ', &date_time();

    if ( $type eq 'Solution' || $type eq 'solution' ) {
        $SStats .= $q->submit( -name => 'Empty Bottles', -value => 'Empty Selected Bottles', -style => "background-color:$Settings{'DONE_COLOUR'}" );
        $SStats .= " ";

        $SStats .= $q->submit( -name => 'Open Bottles',   -value => 'Open Selected Bottles', -style => "background-color:$Settings{'IP_COLOUR'}" );
        $SStats .= " ";
        $SStats .= $q->submit( -name => 'Unopen Bottles', -value => 'Reset to Un-Opened',    -style => "background-color:$Settings{'START_COLOUR'}" );
        $SStats .= "<BR>Effective: " . $q->textfield( -name => 'Bottle Handling Date', -size => 10, -default => $today );
    }

    $SStats .= $q->end_form();

    $dbc->Benchmark('donehere');

    return $SStats;
}

#########################
sub display_stock_inventory {
#########################
    my %args        = &filter_input( \@_, -args => 'dbc,search,group' );
    my $dbc         = $args{-dbc};
    my $search_name = convert_to_regexp( $args{-cat_name} );
    my $search_num  = convert_to_regexp( $args{-cat_num} );
    my $grp         = $args{-group};
    my $condition   = $args{-condition};
    my $title       = $args{-title} || "Status for Solutions (containing '$search_name ($search_num)')";
    my $type        = $args{-type};
    my $search_by   = $args{-search_by} || 'cat';                                                          ## name or catalog
    my $debug       = $args{-debug};

    my $Stock_Info_ref = $args{-info};
    my %Stock_Info = %$Stock_Info_ref if $Stock_Info_ref;

    ## define colours..
    ###### Header colours ####
    #### dynamic colour #####
    my $oc             = $Settings{'IP_COLOUR'};
    my $uc             = $Settings{'START_COLOUR'};
    my $ec             = $Settings{'EMPTY_COLOUR'};
    my $warning_colour = $Settings{'DONE_COLOUR'};

    ## Creating table
    my $Stock_Table       = HTML_Table->new();
    my $stock_table_index = 1;
    $Stock_Table->Set_Headers( [ 'Name - Catalog (Size)', 'Number Open', 'Number Unopened', 'Number Used Up (if applicable)' ] );
    $Stock_Table->Set_Border(1);

    my @keys;
    my %Status;

    ## Populate hash with data ##
    my $index = 0;
    while ( defined $Stock_Info{Stock_Catalog_Name}[$index] ) {
        my $s_name = $Stock_Info{Stock_Catalog_Name}[$index];
        my $num    = $Stock_Info{Count}[$index];
        my $cat    = $Stock_Info{Cat}[$index];
        my $size   = $Stock_Info{Stock_Size}[$index];
        my $status = $Stock_Info{Status}[$index];
        my $units  = $Stock_Info{Units}[$index];
        my $label  = $Stock_Info{Label}[$index];

        $index++;

        my $vol = &get_units( $size, $units );
        my $name = "$s_name - $cat ($vol)";

        $Status{$label}{$status} += $num;
        $Status{$label}{Name} = $s_name;
    }

    ## Dump hash to Table ##
    $index = 1;
    foreach my $key ( sort { $a cmp $b } keys %Status ) {
        unless ($key) {
            next;
        }
        my $opened   = $Status{$key}{'Open'}     || 0;
        my $unopened = $Status{$key}{'Unopened'} || 0;
        my $finished = $Status{$key}{'Finished'} || 0;

        $Stock_Table->Set_Row(
            [   Show_Tool_Tip(
                    $q->submit(
                        -name  => "Details for Stock",
                        -force => 1,
                        -value => $key,
                        -class => "Search"
                    ),
                    "Show details for items of this size"
                ),
                "<B>$opened</B>",
                "<B>$unopened</B>",
                "<B>$finished</B>"
            ]
        );

        $Stock_Table->Toggle_Colour_on_Column(1);

        if ( !$opened ) {
            $Stock_Table->Set_Cell_Colour( $index, 2, $Settings{'EMPTY_COLOUR'} );
        }
        else {
            $Stock_Table->Set_Cell_Colour( $index, 2, $Settings{'IP_COLOUR'} );
        }

        if ( !$unopened ) {
            $Stock_Table->Set_Cell_Colour( $index, 3, $Settings{'EMPTY_COLOUR'} );
        }
        else {
            $Stock_Table->Set_Cell_Colour( $index, 3, $Settings{'START_COLOUR'} );
        }

        if ( !$finished ) {
            $Stock_Table->Set_Cell_Colour( $index, 4, $Settings{'EMPTY_COLOUR'} );
        }
        else {
            $Stock_Table->Set_Cell_Colour( $index, 4, $Settings{'DONE_COLOUR'} );
        }
        $index++;
    }
    $Stock_Table->Set_Alignment('center');
    $Stock_Table->Set_Alignment( 'left', 1 );

    ###### Building page

    my $SStats .= alDente::Form::start_alDente_form( $dbc, 'status' );
    $SStats .= $q->h2($title);
    $SStats .= $q->hidden( -name => 'rm', -value => 'Stock Details', -force => 1 );
    $SStats .= $q->hidden( -name => 'Search By',            -value => $search_by );
    $SStats .= $q->hidden( -name => 'Search String Name',   -value => $search_name );
    $SStats .= $q->hidden( -name => 'Search String Number', -value => $search_num );
    $SStats .= $q->hidden( -name => 'Search Group',         -value => $grp );
    $SStats .= $q->hidden( -name => 'Stock Type',           -value => $type );
    $SStats .= $q->hidden( -name => 'cgi_application',      -value => 'alDente::Stock_App', -force => 1 );
    $SStats .= $q->hidden( -name => 'rm',                   -value => 'Stock Details', -force => 1 );
    $SStats .= 'List All stock like: ' . Show_Tool_Tip(
        $q->submit(
            -name => "Details for Stock",

            #                      -accesskey => 'G',
            -force => 1,
            -value => "$search_name",
            -title => "Retrieve details for All reagents/stock like '$search_name'",
            -class => 'search'
        ),
        "Includes old bottles"
    ) . lbr;

    #  $SStats .= 'List All stock with catalog number like: ' .
    #             Show_Tool_Tip(#
    #            $q-> submit(-name      => "Details for Stock",
    #                      -force     => 1,
    #                     -value     => "$search_num",
    #                    -title     => "Retrieve details for All reagents/stock like '$search_num'",
    #                   -class     => 'search' ),
    #       "Includes old bottles"
    #      )   .       lbr ;
    $SStats .= $q->checkbox( -name => 'Include Finished Bottles' );
    $SStats .= $Stock_Table->Printout( "$URL_temp_dir/Stock_Status.html", $html_header );
    $SStats .= $Stock_Table->Printout( undef, undef, 1 );
    $SStats .= $q->end_form();
    return $SStats;
}

#########################
sub edit_Records_Link {
#########################
    my %args   = filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $ids    = $args{-ids};
    my $object = $args{-object};

    my ($primary_id) = $dbc->get_field_info( $object, undef, 'Primary' );
    my $stock_ids = join ',', $dbc->Table_find( $object, "FK_Stock__ID", " WHERE $primary_id IN ($ids)", -distinct => 1 );

    my $output
        = SDB::DB_Form_Views::get_update_link( -object => $object, -dbc => $dbc, -id => $ids, -display => "Edit $object Info" )
        . vspace()
        . SDB::DB_Form_Views::get_update_link( -object => "Stock", -dbc => $dbc, -id => $stock_ids, -display => "Edit Stock Info" )
        . vspace();

    return $output;
}

#########################
sub display_added_equipment_items {
#########################
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $type = $args{-category};
    my $ids  = $args{-id_list};

    my $view = $dbc->Table_retrieve_display(
        -table       => "Equipment,Stock,Stock_Catalog",
        -fields      => [ 'Equipment_ID', 'Equipment_Name', 'Serial_Number', 'Stock_Catalog.Model', 'Stock_Catalog.FK_Equipment_Category__ID' ],
        -condition   => "WHERE Equipment_ID IN ($ids) and FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID",
        -return_html => 1,
    );
}

#########################
sub display_added_stock_items {
#########################
    my %args           = &filter_input( \@_ );
    my $dbc            = $args{-dbc};
    my $type           = $args{-category};
    my $ids            = $args{-id_list};
    my $type_id        = $type . '_ID';
    my $type_number    = $type . '_Number';
    my $type_num_batch = $type . '_Number_in_Batch';

    my $view = $dbc->Table_retrieve_display(
        -table       => "$type,Stock,Stock_Catalog",
        -fields      => [ $type_id, 'Stock_Catalog_Name', $type_number, $type_num_batch, 'Stock_Catalog.Stock_Size', 'Stock_Catalog.Stock_Size_Units', 'FK_Grp__ID' ],
        -condition   => "WHERE $type_id IN ($ids) and FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID",
        -return_html => 1,
    );

}

#########################
sub search_stock_box {
#########################
    my %args          = &filter_input( \@_, -args => 'embedded' );
    my $embedded      = $args{-embedded};
    my $dbc           = $args{-dbc};
    my $org_list      = $args{-organizations};
    my $short_version = $args{-short};

    my $search_link = 'Search for: ' . &Link_To( $dbc->config('homelink'), 'Bottles', '&Search+for=1&Table=Solution' ) . &hspace(5) . &Link_To( $dbc->config('homelink'), 'Stock', '&Search+for=1&Table=Stock' );
    unless ($org_list) { $org_list = alDente::Stock::get_organization_list( '', -type => [ 'Manufacturer', 'Vendor' ], -dbc => $dbc ); }    ###WARNING SHOULD BE USED

    my $stock_search = alDente::Form::init_HTML_table( -left => 'Inventory Search', -right => $search_link, -margin => 'on' );

    if ($embedded) {
        $stock_search->Set_Title('');
        $stock_search->Set_Row( ["<B>Searching for Reagents/Solutions</B>"] );
    }

    # my @fields = qw(Stock_Catalog.Stock_Source Stock_Catalog.Model ); ## maybe add in future: Stock_Catalog.FK_Equipment_Category__ID
    #	my $table 	= &SDB::HTML::query_form (-dbc => $dbc, -fields => \@fields, -action=>'search');

    my @choices = ( '--Select--', 'All Stock', 'Solution', 'Box' );                                                                         #drop-down menu choices

    my @fields = qw(Stock_Catalog.Stock_Catalog_Name Stock_Catalog.Stock_Catalog_Number Stock_Catalog.FK_Organization__ID Stock_Catalog.Stock_Source Grp.FK_Department__ID);
    if ($short_version) {
        @fields = qw(Stock_Catalog.Stock_Catalog_Name Stock_Catalog.Stock_Catalog_Number);
    }

    my $category_table = &SDB::HTML::query_form( -dbc => $dbc, -fields => \@fields, -action => 'search', -submit => 0 );

    $stock_search->Set_Row( [ "\n<img src='/$URL_dir_name/$image_dir/flashlight.png'>", $category_table ] );

    $stock_search->Set_Row(
        [   '',
            'Include:  ' 
                . hspace(30)
                . $q->radio_group(
                -name    => 'Include',
                -values  => [ 'Everything', 'Active Only' ],
                -default => 'Active Only'
                )
                . hspace(30)
                . '(Received or created within: '
                . $q->textfield( -name => 'MadeWithin', -force => 1, -size => 5, -default => '' ) . 'days)'
                . vspace(1)
        ]
    );

    # $stock_search->Set_Row( [ '', '(Received or created within: ' . $q->textfield( -name => 'MadeWithin', -force => 1, -size => 5, -default => '' ) . 'days)' . vspace(1) ] );

    $stock_search->Set_Row(
        [   '',
            $q->submit( -name       => 'Search Options', -value => 'Find All Stock', -force => 1, -class => 'Search' )
                . $q->submit( -name => 'Search Options', -value => 'Find Solutions', -force => 1, -class => 'Search' )
                . $q->submit( -name => 'Search Options', -value => 'Find Boxes',     -force => 1, -class => 'Search' )
        ]
    );

    #	$stock_search->Set_Row([ '',
    #			'Find: '. hspace(100) .
    #		                    $q -> popup_menu(-name=>'Search Options',-value=>\@choices ,default=>'--Select--',-force=>1).hspace(50) .
    #                           $q->  submit(-name=>'Go',-class=>'Std') ]);

    my $output .= alDente::Form::start_alDente_form( $dbc, 'search_stock' );
    $output .= $stock_search->Printout(0) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Stock_App', -force => 1 ) . $q->hidden( -name => 'rm', -value => 'Search Inventory', -force => 1 );
    $output .= $q->end_form();
    return $output;

}

#########################
sub display_stock_catalog_record {
#########################
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $id     = $args{-id};
    my $db_obj = SDB::DB_Object->new( -dbc => $dbc );
    $db_obj->add_tables('Stock_Catalog');
    $db_obj->{stock_Catalog_id} = $id;
    $db_obj->primary_value( -table => 'Stock_Catalog', -value => $id );    ## same thing as above..
    $db_obj->load_Object( -type => 'Stock_Catalog' );
    return $db_obj->display_Record( -tables => ['Stock_Catalog'], -index => "index $id", -truncate => 40 );
}

1;
