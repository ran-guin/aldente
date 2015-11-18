###################################################################################################################################
# alDente::Equipment_Views.pm
#
#
#
#
###################################################################################################################################
package alDente::Equipment_Views;
use base alDente::Object_Views;

use strict;

use LampLite::CGI;

use alDente::Equipment;
use alDente::SDB_Defaults;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::Conversion;

## alDente modules
use alDente::Tools;

my $q = new LampLite::CGI;
#######################                     Should be earased
sub equipment_main {
#######################
    #
    # General Equipment home page...
    #
    # This is NOT used for scanner mode
    #
#######################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $page = &Views::Heading("Equipment Home Page") . &vspace(10);

    my @Etypes = $dbc->Table_find( 'Equipment_Category', 'Category', "WHERE 1", 'Distinct' );

    my @Sequencer_Types;
    if ( $dbc->package_active('Sequencing') ) {
        @Sequencer_Types = $dbc->Table_find( 'Sequencer_Type', 'Sequencer_Type_Name', 'ORDER BY Sequencer_Type_Name', 'Distinct' );
    }

    #    print alDente::Form::start_alDente_form($dbc, 'Emain');

    my $search_header = h3('Search') . '<BR>' . "\n<img src='/$URL_dir_name/$image_dir/search.png'>";
    my $search_block = alDente::Form::start_alDente_form( $dbc, 'Esearch' );
    $search_block .= Show_Tool_Tip( $q->submit( -name => 'Search for', -value => "Search/Edit Equipment", -class => "Search" ), "Search for Equipment" ) . &hspace(10) . checkbox( -name => 'Multi-Record' ) . "<BR><BR>";
    $search_block .= Show_Tool_Tip( $q->submit( -name => 'List Equipment', -class => "Search" ), "Display a list of Equipment in the system" );
    $search_block .= &hspace(10) . "Specify Type: " . Show_Tool_Tip( popup_menu( -name => 'Equip Type', -values => [ '', sort @Etypes ], -default => "" ), "Equipment Types" ) . " (optional)";
    $search_block .= $q->hidden( -name => 'Table', -value => 'Equipment', -force => 1 );
    $search_block .= $q->end_form();

    my $inventory_header = h3('Inventory');
    my $inventory = alDente::Form::start_alDente_form( $dbc, 'Einventory' );
    $inventory .= Show_Tool_Tip( $q->submit( -name => 'Inventory_Home', -value => "Inventory Home", -class => "Std" ), "Inventory home page" ) . "<BR><BR>";
    $inventory .= $q->end_form();

    my $maint_header = h3('Maintenance');
    my $maint_block  = maintenance_block($dbc);

    my $new_equip_header = h3('Add');
    my $new_equip_block = alDente::Form::start_alDente_form( $dbc, 'Enew' );
    $new_equip_block .= $q->submit( -name => 'New Stock', -value => "New Equipment", -class => "Std" );
    $new_equip_block .= $q->end_form();

    my $sequencing_header;
    my $sequencing_block;
    if ( $dbc->package_active('Sequencing') ) {
        $sequencing_header = h3('Sequencers');
        $sequencing_block = alDente::Form::start_alDente_form( $dbc, 'Eseq' );

        $sequencing_block .= Show_Tool_Tip( $q->submit( -name => 'Sequencer Status', -class => "Search" ), "Summary of Runs and Reads for Sequencers" ) . "<BR>";
        $sequencing_block .= Show_Tool_Tip( $q->submit( -name => 'Configure_SS', -value => "Configure Sample Sheet", -class => "Search" ), "Configure Sample Sheet for Type of Sequencer" ) . &hspace(10);

        $sequencing_block .= "Sequencer Type: " . $q->popup_menu( -name => 'Sequencer_Type', -values => [@Sequencer_Types], -default => "" );
        $sequencing_block .= $q->end_form();
    }

    my $rack_header = h3('Rack');
    my $rack_block = alDente::Form::start_alDente_form( $dbc, 'Erack' );
    $rack_block
        .= Show_Tool_Tip( $q->submit( -name => 'Barcode_Event', -value => 'Print Slot Barcodes', -class => "Std" ), "Specify barcodes for slots on a rack" )
        . hspace(1)
        . "Max Row: "
        . $q->textfield( -name => 'Max_Row', -value => 'i', -size => 3 )
        . hspace(1)
        . "Max Col: "
        . $q->textfield( -name => 'Max_Col', -value => '9', -size => 3 )
        . hspace(1)
        . "Scale: "
        . $q->textfield( -name => 'Scale', -value => 1, -size => 2 )
        . hspace(1)
        . "Height: "
        . $q->textfield( -name => 'Height', -value => 30, -size => 2 )
        . hspace(1)
        . "Vertical Spacing: "
        . $q->textfield( -name => 'Vspace', -value => 5, -size => 2 );
    $rack_block .= $q->end_form();

    my $large_label_header = h3("Large Label") . "<img src='/$URL_dir_name/$image_dir/largelabel.gif'>";
    my $large_label_block = alDente::Form::start_alDente_form( $dbc, 'Ellabel' );
    $large_label_block .= "Field 1 : " . $q->textfield( -name => 'Field1', -force => 1 ) . '<BR>';
    $large_label_block .= "Field 2 : " . $q->textfield( -name => 'Field2', -force => 1 ) . '<BR>';
    $large_label_block .= "Field 3 : " . $q->textfield( -name => 'Field3', -force => 1 ) . '<BR>';
    $large_label_block .= "Field 4 : " . $q->textfield( -name => 'Field4', -force => 1 ) . '<BR>';
    $large_label_block .= "Field 5 : " . $q->textfield( -name => 'Field5', -force => 1 ) . '<BR>';
    $large_label_block .= $q->submit( -name => 'Barcode_Event', -value => "Print Simple Large Label", -class => "Std" );
    $large_label_block .= $q->end_form();

    my $small_label_header = h3("Small Label") . "<img src='/$URL_dir_name/$image_dir/smalllabel.gif'>";
    my $small_label_block = alDente::Form::start_alDente_form( $dbc, 'Eslabel' );
    $small_label_block .= "Field 1 : " . $q->textfield( -name => 'Field1', -force => 1 ) . '<BR>';
    $small_label_block .= "Field 2 : " . $q->textfield( -name => 'Field2', -force => 1 ) . '<BR>';
    $small_label_block .= $q->submit( -name => "Barcode_Event", -value => "Print Simple Small Label", -class => "Std" );
    $small_label_block .= $q->end_form();

    my $tube_label_header = h3("Tube Label") . "<img src='/$URL_dir_name/$image_dir/smalllabel.gif'>";
    my $tube_label_block = alDente::Form::start_alDente_form( $dbc, 'Etlabel' );
    $tube_label_block .= "Field 1 : " . $q->textfield( -name => 'Field1', -force => 1 ) . '<BR>';
    $tube_label_block .= "Field 2 : " . $q->textfield( -name => 'Field2', -force => 1 ) . '<BR>';
    $tube_label_block .= "Field 3 : " . $q->textfield( -name => 'Field3', -force => 1 ) . '<BR>';
    $tube_label_block .= "Field 4 : " . $q->textfield( -name => 'Field4', -force => 1 ) . '<BR>';
    $tube_label_block .= "Field 5 : " . $q->textfield( -name => 'Field5', -force => 1 ) . '<BR>';
    $tube_label_block .= $q->submit( -name => 'Barcode_Event', -value => "Print Simple Tube Label", -class => "Std" );
    $tube_label_block .= $q->end_form();

    my @rows = ();
    push @rows, [ $search_header, $search_block ], [ '<hr>', '<hr>' ];

    push @rows, [ $inventory_header, $inventory ],       [ '<hr>', '<hr>' ];
    push @rows, [ $maint_header,     $maint_block ],     [ '<hr>', '<hr>' ];
    push @rows, [ $new_equip_header, $new_equip_block ], [ '<hr>', '<hr>' ];
    if ($sequencing_block) { push @rows, [ $sequencing_header, $sequencing_block ], [ '<hr>', '<hr>' ]; }
    push @rows, [ $rack_header,        $rack_block ],        [ '<hr>', '<hr>' ];
    push @rows, [ $large_label_header, $large_label_block ], [ '<hr>', '<hr>' ];
    push @rows, [ $small_label_header, $small_label_block ], [ '<hr>', '<hr>' ];
    push @rows, [ $tube_label_header,  $tube_label_block ],  [ '<hr>', '<hr>' ];

    $page .= &Views::Table_Print( content => \@rows, -return_html => 1 );
    return $page;
}

##########################
sub display_record_page {
##########################
    my $self = shift;
    my %args      = filter_input( \@_, -args => 'dbc,equipment_id' );
    my $dbc = $args{-dbc} || $self->dbc();
    my $id  = $args{-id}  || $self->{id};

    my @layers;
    
    my $init = alDente::Form::start_alDente_form( $dbc, 'status' )
    . $q->hidden( -name => 'Equipment', -value => $id, -force => 1 )
    . $q->hidden( -name => 'FK_Employee__ID', -value => $dbc->get_local('user_id') );

    my $maintenance;
    if ( $dbc->package_active('Maintenance') ) {
        $maintenance .= $init
        . $q->submit( -name => 'Maintenance', -class => "Std" ) . " (perform service) " . $q->p();

        unless ($dbc->mobile()) {
            my ($lastyear) = split ' ', &date_time( -offset => '-30d' );
            $maintenance .= $q->submit( -name => 'Machine History', -class => "Std" ) . " (for Equ:$id) " . $q->p();
            
            my @process_types = $dbc->Table_find( "Maintenance_Process_Type", "Process_Type_Name" );
            
            my @default_actions = ();  ## account for Matrix / Buffer (custom ?)
            $maintenance .= $q->scrolling_list( -name => "Include Types", -values => \@process_types, -default => \@default_actions, -multiple => 'true', -force => 1 );
            
            $maintenance .= $q->p() . $q->checkbox( -name => 'Go Back Only', -checked => 1, -force => 1 ) . " to show records SINCE: " . $q->textfield( -name => 'History Since', -size => 10, -default => $lastyear );
            $maintenance .= scheduled_maintenance( $dbc, -equipment_id => $id, -return_html => 1 );
        }
        $maintenance .= $q->end_form();
        
        push @layers, { 'label' => 'Maintenance', 'content' => $maintenance};
    }    
    
    if ($id !~/,/) { push @layers, { 'label' => 'Contents',  'content' =>  $self->content_block() } }
   
    my $relocation_history = alDente::Rack_Views::show_Relocation_History( -dbc => $dbc, -object => 'Equipment', -id => $id );
    if ($relocation_history !~/no shipments/) {  push @layers, { 'label' => 'Transport', 'content' => $relocation_history} }
    
    return $self->SUPER::display_record_page(
        -right => $self->standard_options(),
        -layers     => \@layers,
        -visibility => { 'Search' => ['desktop'] },
        -label_span => 3,
        -open_layer => 'Contents',
    );
}

#####################
sub content_block {
#####################
    my $self = shift;
    my %args      = filter_input( \@_, -args => 'dbc,equipment_id' );
    my $dbc = $args{-dbc} || $self->dbc();
    my $id  = $args{-id}  || $self->{id};

    my $condition_ref = alDente::Rack::get_all_rack_conditions( -dbc => $dbc );
    my @conditions    = @$condition_ref;
    my ($def_cond)    = $dbc->Table_find( 'Rack,Equipment,Stock,Stock_Catalog,Equipment_Category',
        'Sub_Category', "where FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_equipment_Category__ID = Equipment_Category_ID AND FK_Equipment__ID = Equipment_ID AND Equipment_ID IN ($id) LIMIT 1" );
    $def_cond = alDente::Rack::validate_rack_condition( -dbc => $dbc, -condition => $def_cond );
    my @types = get_enum_list( $dbc, 'Rack', 'Rack_Type' );
    pop @types;    ## remove Slot option ...

    my $def_type  = 'Shelf';
    my $labelinfo = "<br><span class=small>Label defaults to 'S','R',or 'B' for Shelves, Racks, and Boxes</span>" . "<br><span class=small>Number field defaults to lowest available number</span>";

    my $Rack_footer = alDente::Form::start_alDente_form( $dbc, 'rack_options' ) 
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 ) 
        . $q->hidden( -name => 'Equipment', -value => $id, -force => 1 );

    $Rack_footer .= $q->submit( -name => 'rm', -value => 'Show Equipment Contents', -class => "Std", -force => 1 ) . '<BR>' . '<BR>';
    $Rack_footer .= 'Content Report Type:<BR>';

    my $default = 'Sorted List';
    $Rack_footer .= $q->radio_group( -name => 'Generate Report', -values => ['Sorted List'],        -default => $default, -force => 1 ) . ' ';
    $Rack_footer .= $q->radio_group( -name => 'Generate Report', -values => ['Content Summary'],    -default => $default, -force => 1 ) . ' ';
    $Rack_footer .= $q->radio_group( -name => 'Generate Report', -values => ['Full Sample Report'], -default => $default, -force => 1 ) . ' ';
    $Rack_footer .= '<HR>';

    $Rack_footer .= Views::Table_Print(
        print   => 0,
        content => [
            [   $q->submit( -name => 'rm', -value => 'Add', -class => "Action", -force => 1 ),
                Show_Tool_Tip( $q->textfield( -name => 'New Racks', -size => 5, -default => 1, -class => 'narrow-txt' ), 'Indicate number of new Shelves/Racks/Boxes to generate' )
            ],
            [ 'Type: ',   $q->popup_menu( -name               => 'Rack_Types',  -value => [@types], -default => $def_type, -class => 'short-txt' ) ],
            [ 'Prefix: ', Show_Tool_Tip( $q->textfield( -name => 'Rack_Prefix', -size  => 10,       -default => '' ),      "Optional: defaults to S (Shelf), R (Rack), B (Box)\n[unless alphabetic starting# is used below]" ) ],
            [   'Starting #: ',
                Show_Tool_Tip(
                    $q->textfield( -name => 'Starting Number', -size => 4, -class => 'narrow-txt', -default => '' ),
                    "Optional: defaults to next available number.\n\nMay also enter starting letter (leave prefix blank) to generate alphabetic section names\n(eg A-D instead of S1-S4)"
                )
            ],
            [ 'Conditions: ', $q->popup_menu( -name => 'Conditions', -value => [@conditions], -default => $def_cond ) ]
        ],
        -column_style => { 1 => 'text-align:right;' }
    );

    $Rack_footer .= $labelinfo . &vspace(20) . $q->end_form();

    $Rack_footer .= $q->end_form;
    
    return $Rack_footer;
}
########################
sub standard_options {
########################
    my $self = shift;
    my %args      = filter_input( \@_, -args => 'dbc,equipment_id' );
    my $dbc = $args{-dbc} || $self->dbc();
    my $id  = $args{-id}  || $self->{id};
    
    my $init = alDente::Form::start_alDente_form( $dbc, 'status' )
    . $q->hidden( -name => 'Equipment', -value => $id, -force => 1 )
    . $q->hidden( -name => 'FK_Employee__ID', -value => $dbc->get_local('user_id') );
    
    my $block = $init
    . $q->submit( -name => 'Barcode_Event', -value => 'Re-Print Equipment Barcode', -class => "Std" )
    . $q->end_form();
}

####################
sub home_page {
####################
    my %args      = filter_input( \@_, -args => 'dbc,equipment_id' );
    my $dbc       = $args{-dbc};
    my $Equipment = $args{-Equipment};
    my $id        = $args{-equipment_id} || $args{-id} || $Equipment->{id};
    my $barcode   = $args{-barcode};

    if ( !$Equipment ) {
        $Equipment = alDente::Equipment->new( -dbc => $dbc, -id => $id );
    }

    my $page;
    foreach my $id ( split ',', $id ) {
        $page .= equipment_label( -dbc => $dbc, -Equipment => $Equipment, -id => $id ) . '<hr>';
    }
    my $status = $Equipment->value('Equipment_Status');
    my $name   = $Equipment->value('Equipment_Name');

    if ( $dbc->package_active('Sci_Print') ) {
        require Sci_Print::Equipment;
        require Sci_Print::Equipment_Views;
        my $category_id = $Equipment->value('FK_Equipment_Category__ID');
        my $Sci_Printer = new Sci_Print::Equipment( -dbc => $dbc, -id => $id );
        if ( $Sci_Printer->match_Category( -category_id => $category_id ) ) {
            $page .= $Sci_Printer->{'View'}->display_Slots( -id => $id );
            $page .= $Sci_Printer->{'View'}->setup_page( -id => $id );
        }
    }

    if ( $id =~ /[1-9]/ ) {
        if ( ( $status eq 'In Transit' ) && ( $name !~ /^Site\-%/ ) ) {

            ## If Equipment is in Transit (and not standard Site identifier) - only allow receipt of Equipment ##
            $page
                .= alDente::Form::start_alDente_form( $dbc, 'receiveEquip' )
                . alDente::Tools::search_list( -name => 'FK_Location__ID' )
                . $q->submit( -name => 'rm', -value => 'Receive Equipment', -class => 'Action', -onclick => 'return validateForm(this.form)' )
                . $q->hidden( -name => 'cgi_application', -value => 'alDente::Shipment_App', -force => 1 )
                . $q->hidden( -name => 'Equipment_ID', -value => $id, -force => 1 )
                . set_validator( -name => 'FK_Location__ID', -mandatory => 1 );
        }
        else {
            $page .= equipment_footer( -id => $id, -Equipment => $Equipment, -barcode => $barcode );
        }

        ( my $type ) = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
            'Category', "WHERE FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID and Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID AND Equipment_ID IN ($id)" );

        my $machine_info_flag;
        if ( $dbc->table_loaded('Machine_Default') ) {
            ($machine_info_flag) = $dbc->Table_find( 'Equipment,Machine_Default', 'Machine_Default_ID', "WHERE FK_equipment__ID = Equipment_ID and Equipment_ID IN ($id)" );
        }

        my @tables = ( 'Equipment', 'Stock', 'Stock_Catalog' );
        if ($machine_info_flag) { push( @tables, 'Machine_Default' ); }

        my $details;
        if ($scanner_mode) {
            &Views::Table_Print( content => [ [$page] ], spacing => 5 );
        }
        elsif ( $id !~ /,/ ) {
            $details = $Equipment->display_Record();
        }
        unless ($scanner_mode) {
            return &Views::Table_Print( content => [ [ $page, $details ] ], spacing => 5, -return_html => 1 );
        }
    }
    $dbc->session->homepage("Equipment=$id");
    return 'no id';
}

####################
sub object_label {
####################
    my $self = shift;
    my %args = filter_input(\@_);
    
    $args{-dbc} = $self->dbc();
    $args{-Equipment} = $self;
    
    return equipment_label(%args);
    
}

########################
sub equipment_label {
########################
    my %args      = &filter_input( \@_, -args => 'id' );
    my $Equipment = $args{-Equipment};
    my $dbc       = $args{-dbc} || $Equipment->{dbc};
    my $id        = $args{-id} || $Equipment->{id};
    my $quiet     = $args{-quiet} || $scanner_mode;
    my $max_num   = 200;                                   ## maximum number of storage locations to display directly from Equipment home page

    my $page = &alDente::Tools::alDente_ref( 'Equipment', $id, -dbc => $dbc );

    if ( $id =~ /[1-9]/ ) {

        my %info = $dbc->Table_retrieve(
            'Equipment,Stock,Stock_Catalog,Organization,Location,Equipment_Category',
            [ 'Equipment_Name', 'Model', 'Category', 'Organization_Name', 'Location_Name', 'Equipment_Status', 'Sub_Category' ],
            "where FK_Location__ID = Location_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID and FK_Stock__ID = Stock_ID and Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID AND Stock_Catalog.FK_Organization__ID = Organization_ID AND Equipment_ID in ($id)"
        );
        my $name         = $info{Equipment_Name}[0];
        my $model        = $info{Model}[0];
        my $type         = $info{Category}[0];
        my $supplier     = $info{Organization_Name}[0];
        my $location     = $info{Location_Name}[0];
        my $eq_status    = $info{Equipment_Status}[0];
        my $sub_category = $info{Sub_Category}[0];

        if ( $name =~ /NULL/ ) {
            Message("Equipment $id not found");
            &main::home();
            return 0;
        }

        $page .= "<P>";
        $page .= "Model: " . $model . '<BR>';
        unless ($quiet) {
            $page .= "($supplier)" . &vspace(5);
        }
        $page .= "Category: " . "$type-$sub_category" . alDente::Equipment_Views::display_Equipment_Activation_Button( -ids => $id, -dbc => $dbc );
        $page .= vspace(5);

        if ( $eq_status !~ /^In Use/i ) {
            $page .= "<BR><Font color=red><B>Warning: This equipment is NOT active (edit if necessary)</B></Font><P>\n";
        }

        unless ($type) {
            return $page;
        }

        #	$page .= &Link_To($homelink,"<B>$name $model $type</B>","&Info=1&Table=Equipment&Field=Equipment_ID&Like=$id",$Settings{LINK_COLOUR},['newwin']).
        #	    &vspace(5);

        ## show list of locations without parents (eg shelves) directly on this page ##
        my @direct_racks = $dbc->Table_find( 'Rack', 'Rack_ID', "where FK_Equipment__ID in ($id) AND (FKParent_Rack__ID IS NULL OR FKParent_Rack__ID = 0)" );
        $page .= alDente::Rack_Views::list_Racks( -title => 'Storage Sections', -dbc => $dbc, -rack_id => \@direct_racks, );

        if ( ( $id !~ /,/ ) && @direct_racks ) { $page .= &Link_To( $dbc->config('homelink'), "Storage Map", "&cgi_application=alDente::Rack_App&rm=Freezer+Map&Equipment_ID=$id" ) . '<P>' }

        my @racks = $dbc->Table_find( 'Rack', 'Rack_ID', "where FK_Equipment__ID in ($id)" );
        if ( int(@racks) > 0 ) {
            my $num = int(@racks);
            my $rack_id_list = join ',', @racks;

            if ( $num < $max_num ) {
                $page .= &Link_To(
                     $dbc->homelink(), "View all $num Total Storage Locations", "&Info=1&Table=Rack&Field=Rack_ID&Like=$rack_id_list",
                    -colour  => $Settings{LINK_COLOUR},
                    -window  => ['newwin'],
                    -tooltip => 'Click here to see a full list of all internal storage sections'
                ) . '<p ></p>';
            }
        }

    }
    return $page;
}

###########################
sub equipment_footer {
###########################
    #
    # Footer (with options) for Equipment
    #
    my %args      = filter_input( \@_ );
    my $Equipment = $args{-Equipment};
    my $dbc       = $args{-dbc} || $Equipment->{dbc};
    my $ids       = $args{-id} || $Equipment->{id};
    my $barcode   = $args{-barcode};

    my $multi_equipment = 0;

    my $defMB = '';
    if ( $barcode =~ /sol/gi ) {
        $defMB = get_aldente_id( $dbc, $barcode, 'Solution' );
        if   ($defMB) { $defMB = "Sol$defMB"; }
        else          { $defMB = ''; }
    }

    if ( $ids =~ /,/, ) { $multi_equipment = 1; }    ### flag if multiple equipment

    my $footer = '';
    my $Rack_footer = alDente::Form::start_alDente_form( $dbc, 'rack_options' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 ) . $q->hidden( -name => 'Equipment', -value => $ids, -force => 1 );

    if ($ids) {
        my ($info) = $dbc->Table_find_array(
            'Equipment,Stock,Stock_Catalog,Equipment_Category',
            [ 'Category', 'Equipment_Status' ],
            "where FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID AND Equipment_ID in ($ids)"
        );

        my ( $type, $status ) = split ',', $info;

        if ( !$multi_equipment ) {
            unless ($type) {
                return;
            }
        }

        $footer .= alDente::Form::start_alDente_form( $dbc, 'status' );
        $footer .= $q->hidden( -name => 'Equipment', -value => $ids, -force => 1 );
        $footer .= "<p ></p>\n";

        # print out a warning if more than one equipment is scanned in and use just the first one.
        my @id_list = split ',', $ids;
        if ( int(@id_list) > 1 ) {
            $ids = $id_list[0];
        }

        my @default_actions = ();
        if ( $type =~ /sequencer/i ) {
            if ($ids) {
                my ( $dmatrix, $Mtime ) = &alDente::Equipment::get_MatrixBuffer( $dbc, 'Matrix', $ids );
                my ( $dbuffer, $Btime ) = &alDente::Equipment::get_MatrixBuffer( $dbc, 'Buffer', $ids );
                $Mtime = convert_date( $Mtime, 'Simple' );
                $Btime = convert_date( $Btime, 'Simple' );
                $footer .= "<BR><span size=small><B>Current Matrix:<BR>";
                if ( $dmatrix =~ /[1-9]/ ) {
                    $footer .= alDente_ref( 'Solution', $dmatrix, -dbc => $dbc ) . " <i>($Mtime)</i>";
                }
                else { $footer .= " (No Matrix found)"; }

                $footer .= &vspace(5);

                $footer .= "Current Buffer:<BR>";
                if ( $dbuffer =~ /[1-9]/ ) {
                    $footer .= alDente_ref( 'Solution', $dbuffer, -dbc => $dbc ) . " <i>($Btime)</i>";
                }
                else { $footer .= " (No Buffer found)"; }
                $footer .= "<BR></Span>" . &vspace(10);
            }
            $footer .= $q->submit( -name => 'Change MB', -value => 'Change Matrix and/or Buffer', -class => "Action" );
            if ($multi_equipment) {
                $footer .= " for all sequencers";
            }
            $footer .= " to: ", $footer .= $q->textfield( -name => 'MatrixBuffer', -size => 10, -default => $defMB ) . " <B>(may scan BOTH)</B>" . &vspace();
            @default_actions = ( 'Change Matrix', 'Change Buffer' );
        }

        # allow racks to be added to any equipment
        elsif ( !$multi_equipment ) {
            my $condition_ref = alDente::Rack::get_all_rack_conditions( -dbc => $dbc );
            my @conditions    = @$condition_ref;
            my ($def_cond)    = $dbc->Table_find( 'Rack,Equipment,Stock,Stock_Catalog,Equipment_Category',
                'Sub_Category', "where FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_equipment_Category__ID = Equipment_Category_ID AND FK_Equipment__ID = Equipment_ID AND Equipment_ID IN ($ids) LIMIT 1" );
            $def_cond = alDente::Rack::validate_rack_condition( -dbc => $dbc, -condition => $def_cond );
            my @types = get_enum_list( $dbc, 'Rack', 'Rack_Type' );
            pop @types;    ## remove Slot option ...

            my $def_type  = 'Shelf';
            my $labelinfo = "<br><span class=small>Label defaults to 'S','R',or 'B' for Shelves, Racks, and Boxes</span>" . "<br><span class=small>Number field defaults to lowest available number</span>";

            $Rack_footer .= $q->submit( -name => 'rm', -value => 'Show Equipment Contents', -class => "Std", -force => 1 ) . '<BR>' . '<BR>';
            $Rack_footer .= 'Content Report Type:<BR>';

            my $default = 'Sorted List';
            $Rack_footer .= $q->radio_group( -name => 'Generate Report', -values => ['Sorted List'],        -default => $default, -force => 1 ) . ' ';
            $Rack_footer .= $q->radio_group( -name => 'Generate Report', -values => ['Content Summary'],    -default => $default, -force => 1 ) . ' ';
            $Rack_footer .= $q->radio_group( -name => 'Generate Report', -values => ['Full Sample Report'], -default => $default, -force => 1 ) . ' ';
            $Rack_footer .= '<HR>';

            $Rack_footer .= Views::Table_Print(
                print   => 0,
                content => [
                    [   $q->submit( -name => 'rm', -value => 'Add', -class => "Action", -force => 1 ),
                        Show_Tool_Tip( $q->textfield( -name => 'New Racks', -size => 5, -default => 1, -class => 'narrow-txt' ), 'Indicate number of new Shelves/Racks/Boxes to generate' )
                    ],
                    [ 'Type: ',   $q->popup_menu( -name               => 'Rack_Types',  -value => [@types], -default => $def_type, -class => 'short-txt' ) ],
                    [ 'Prefix: ', Show_Tool_Tip( $q->textfield( -name => 'Rack_Prefix', -size  => 10,       -default => '' ),      "Optional: defaults to S (Shelf), R (Rack), B (Box)\n[unless alphabetic starting# is used below]" ) ],
                    [   'Starting #: ',
                        Show_Tool_Tip(
                            $q->textfield( -name => 'Starting Number', -size => 4, -class => 'narrow-txt', -default => '' ),
                            "Optional: defaults to next available number.\n\nMay also enter starting letter (leave prefix blank) to generate alphabetic section names\n(eg A-D instead of S1-S4)"
                        )
                    ],
                    [ 'Conditions: ', $q->popup_menu( -name => 'Conditions', -value => [@conditions], -default => $def_cond ) ]
                ],
                -column_style => { 1 => 'text-align:right;' }
            );

            $Rack_footer .= $labelinfo . &vspace(20) . $q->end_form();

            $Rack_footer .= alDente::Rack_Views::show_Relocation_History( -dbc => $dbc, -object => 'Equipment', -id => $ids );
        }
        $Rack_footer .= $q->end_form;
        $footer .= $q->hidden( -name => 'FK_Employee__ID', -value => $dbc->get_local('user_id') );

        if ( $dbc->package_active('Maintenance') ) {

            $footer .= $q->submit( -name => 'Maintenance', -class => "Std" ) . " (perform service) " . &vspace(10);

            unless ($scanner_mode) {
                my ($lastyear) = split ' ', &date_time( -offset => '-30d' );
                $footer .= $q->submit( -name => 'Machine History', -class => "Std" ) . " (for Equ:$ids) " . &vspace(2);
                my @process_types = $dbc->Table_find( "Maintenance_Process_Type", "Process_Type_Name" );

                $footer .= $q->scrolling_list( -name => "Include Types", -values => \@process_types, -default => \@default_actions, -multiple => 'true', -force => 1 ) . &vspace(2);
                $footer .= $q->checkbox( -name => 'Go Back Only', -checked => 1, -force => 1 ) . " to show records SINCE: " . $q->textfield( -name => 'History Since', -size => 10, -default => $lastyear ) . &vspace(10);
                $footer .= scheduled_maintenance( $dbc, -equipment_id => $ids, -return_html => 1 );
                $footer .= '<hr>';
            }
        }

        $footer .= $q->submit( -name => 'Barcode_Event', -value => 'Re-Print Equipment Barcode', -class => "Std" );
        unless ($multi_equipment) {

            ## Check if the equipment is currently being inventoried
            require alDente::Inventory;

            my $inventory_id = alDente::Inventory::check_if_inventory_exists( -dbc => $dbc, -equipment => $ids );

            if ($inventory_id) {
                $footer .= '<BR>' . '<BR>' . &Link_To( $dbc->config('homelink'), 'Continue Inventory', "&Inventory_Home=1&HomePage=Inventory&ID=$inventory_id" );
            }
            else {
                $footer .= '<BR>' . '<BR>' . &Link_To( $dbc->config('homelink'), 'Start Inventory', "&Inventory_Home=1&Start_Inventory=1&FK_Equipment__ID=$ids" );
            }
        }
        $footer .= "\n" . $q->end_form . "\n";

        $footer .= "\n<hr>\n" . $Rack_footer;
    }
    else { Message("No Equipment ID ?"); }

    return $footer;
}

###########################
sub maintenance_block {
###########################
    my $dbc = shift;

    my $q = new CGI;

    my $maint_block = Show_Tool_Tip( $q->submit( -name => 'Maintenance', -class => "Std" ), "Enter maintenance record for Equipment" ) . hspace(20);

    if ( $dbc->package_active('Sequencing') ) {
        $maint_block .= Show_Tool_Tip( $q->submit( -name => 'Capillary Stats', -class => "Search" ), "Usage count for sequencers since last capillary change" ) . hspace(20);
    }

    $maint_block
        .= Show_Tool_Tip( $q->submit( -name => 'HomePage', -value => 'Maintenance_Schedule', -class => "Search" ), "Check currently scheduled maintenance tasks" )
        . hspace(20)
        . Show_Tool_Tip( $q->submit( -name => 'Maintenance History', -class => "Search" ), "Maintenance history for all equipment in the last 30 days" )
        . " (view equipment service/repairs) "
        . hspace(20);

    my $table = alDente::Form::init_HTML_table( "Maintenance", -margin => 'on' );
    $table->Set_Row( [ LampLite::Login_Views->icons( -dbc => $dbc, -name => 'Maintenance' ), $maint_block ] );

    my $block = alDente::Form::start_alDente_form( $dbc, 'Maintenance Search' );
    $block .= $table->Printout(0);
    $block .= $q->end_form();

    return $block;
}

###########################
sub display_Equipment_Activation_Button {
###########################
    my %args = filter_input( \@_ );
    my $ids  = $args{-ids};
    my $dbc  = $args{-dbc};
    my $q    = new CGI;

    ## admin test
    unless ( $dbc->admin_access ) { return; }

    my ($eq_cat_id) = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog', 'FK_Equipment_Category__ID', "WHERE Stock_ID = FK_Stock__ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Equipment_ID = $ids" );

    if ($eq_cat_id) {

        my $edit_link = ' [' . &Link_To( $dbc->config('homelink'), 'Re-Categorize', "&cgi_application=alDente::Equipment_App&ids=$ids&rm=Activate+Equipment", 'red' ) . ']';
        return $edit_link;
    }
    else {
        my $form
            = alDente::Form::start_alDente_form( $dbc, 'Activation' )
            . $q->hidden( -name => 'cgi_application', -value => 'alDente::Equipment_App', -force => 1 )
            . $q->hidden( -name => 'ids', -value => $ids, -force => 1 )
            . $q->submit( -name => 'rm', -value => 'Activate Equipment', -force => 1, -class => "Std" )
            . vspace()
            . $q->end_form();
        return $form;
    }
    return;
}

#########################
sub display_Equipment_Activation_Page {
#########################
    my %args         = filter_input( \@_ );
    my $dbc          = $args{-dbc};
    my $equipment_id = $args{-ids};
    my ($catalog_id) = $dbc->Table_find( 'Equipment,Stock', 'FK_Stock_Catalog__ID', "WHERE FK_Stock__ID = Stock_ID and Equipment_ID = $equipment_id" );
    my @eq_ids = $dbc->Table_find( 'Equipment,Stock', 'Equipment_ID', "WHERE FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = $catalog_id" );
    my @records;
    my $q = new CGI;

    for my $id (@eq_ids) {
        my $record = SDB::DB_Object->new( -dbc => $dbc, -tables => ['Equipment'], -load => { 'Equipment' => $id } );
        push @records, $record->display_Record();
    }
    $dbc -> message ("You are Changing the record for the following equipment");
    &Views::Table_Print( content => [ \@records ], spacing => 5 );

    $dbc -> message ( ' DONT GUESS the category, ask someone or if it is not available please contact LIMS');
    my $message = ' Note that this selection is very important and should not be treated lightly. ' . vspace() . vspace();

    my $selection
        = $message
        . alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Category_Assigning' )
        . &SDB::HTML::query_form( -dbc => $dbc, -fields => ['Stock_Catalog.FK_Equipment_Category__ID'], -action => 'search' )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Equipment_App', -force => 1 )
        . $q->hidden( -name => 'catalog_id',      -value => $catalog_id,              -force => 1 )
        . $q->hidden( -name => 'equipment_id',    -value => $equipment_id,            -force => 1 )
        . RGTools::Web_Form::Submit_Button(
        form         => 'Category_Assigning',
        name         => 'rm',
        class        => 'Action',
        label        => 'Assign Category',
        validate     => 'FK_Equipment_Category__ID Choice',
        validate_msg => 'You need to select a category first.'
        ) . $q->end_form();

    my $record = SDB::DB_Object->new( -dbc => $dbc, -tables => [ 'Equipment', 'Stock', 'Stock_Catalog' ], -load => { 'Equipment' => $equipment_id } );
    my $details = $record->display_Record();
    return $selection . vspace() . $details;
}

###########################
sub maintenance_block_old {
###########################
    my $dbc = shift;

    my $maint_block = alDente::Form::start_alDente_form( $dbc, 'Emaintenance' );
    $maint_block .= Show_Tool_Tip( $q->submit( -name => 'Maintenance',         -class => "Std" ),    "Enter maintenance record for Equipment" ) . "<BR><BR>";
    $maint_block .= Show_Tool_Tip( $q->submit( -name => 'Maintenance History', -class => "Search" ), "Maintenance history for all equipment in the last 30 days" ) . " (view equipment service/repairs) <BR><BR>";
    if ( $dbc->package_active('Sequencing') ) {
        $maint_block .= Show_Tool_Tip( $q->submit( -name => 'Capillary Stats', -class => "Search" ), "Usage count for sequencers since last capillary change" ) . "<BR><BR>";
    }
    $maint_block .= Show_Tool_Tip( $q->submit( -name => 'HomePage', -value => 'Maintenance_Schedule', -class => "Search" ), "Check currently scheduled maintenance tasks" );
    $maint_block .= $q->end_form();

    return $maint_block;
}

##############################
sub equipment_stats {
############################
    #
    #  General Stats for Equipment (including Maintenance procedures)
    #
##############################
    my %args = filter_input( \@_ );

    my $dbc      = $args{-dbc};
    my $ids      = $args{-ids} || '';
    my $find     = $args{-find} || '';
    my $since    = $args{-since} || '';
    my $includes = $args{-include};

    if ($find) {
        $ids = Extract_Values( [ $find, $equipment_id ] );
    }

    my %equip_info = ();

    %equip_info = &Table_retrieve(
        $dbc,
        'Equipment,Organization,Stock,Stock_Catalog,Equipment_Category',
        [ 'Equipment_Name', 'Category', 'Equipment_Comments', 'Organization_Name', 'Stock_Catalog.Model', 'Serial_Number' ],
        "where Equipment_ID in ($ids) and Stock_Catalog_ID = FK_Stock_Catalog__ID and FK_Stock__ID = Stock_ID and Stock_Catalog.FK_Organization__ID=Organization_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID"
    );

    my $include = '';
    if ( $includes && ( int( @{$includes} ) > 0 ) ) {
        my $include_str = join( ',', @{$includes} );
        Message("Types: $include_str");
        $include_str = &autoquote_string($include_str);
        $include .= " AND (Process_Type_Name in ($include_str)) ";
    }

    my $history_limit = $since;

    if ($history_limit) { $include .= " AND Maintenance_DateTime > '$history_limit'"; }

    my $EStats = "";

    my %EInfo;
    my $index = 0;
    while ( defined $equip_info{Equipment_Name}[$index] ) {
        my $name     = $equip_info{Equipment_Name}[$index];
        my $type     = $equip_info{Category}[$index];
        my $comments = $equip_info{Equipment_Comments}[$index];
        my $org      = $equip_info{Organization_Name}[$index];
        my $model    = $equip_info{Model}[$index] || '';
        my $serial   = $equip_info{Serial_Number}[$index];

        #      my $warranty =  $equip_info{Warranty}[$index];

        $EInfo{$name} = "$model $type<BR>($org) SN:#$serial." . &vspace(5);

        #      if ($warranty) {$EInfo{$name} .= "Warranty: $warranty" . &vspace(5);}
        if ($comments) { $EInfo{$name} .= $comments; }
        $index++;
    }

    print &vspace(10) . &Link_To( $dbc->config('homelink'), "Edit History", "&Edit+Table=Maintenance&Field=FK_Equipment__ID&Like=$ids", $Settings{LINK_COLOUR}, ['newwin'] ) . &vspace(20);

    $EStats .= $dbc->Table_retrieve_display(
        'Maintenance,Equipment,Employee,Maintenance_Process_Type,Status',
        [   'Maintenance_ID',
            'FK_Equipment__ID as Machine',
            'FK_Maintenance_Process_Type__ID as Task',
            'FKMaintenance_Status__ID as Status',
            'Maintenance_DateTime',
            'Employee_Name as Done_By',
            'Maintenance.FK_Contact__ID as Done_By_External',
            'FK_Solution__ID as Applied_Solution',
            'Maintenance_Description as Description',
        ],
        "where FK_Maintenance_Process_Type__ID=Maintenance_Process_Type_ID AND FKMaintenance_Status__ID=Status_ID AND FK_Equipment__ID=Equipment_ID and FK_Employee__ID=Employee_ID and Equipment_ID in ($ids) $include Order by Equipment_Name,Maintenance_DateTime desc",
        -title            => 'Performed Maintenance',
        -highlight_string => 'Failed',
        -return_html      => 1,
    );

    print $EStats;
    print $q->p();

    if ( !$scanner_mode ) {
        Views::Print_Page( $EStats, "$URL_temp_dir/Equipment_Stats.html", undef, $html_header );
    }

    return 1;
}

###########################
sub scheduled_maintenance {
##########################
    #
    # Method to check for maintenance that is overdue
    #  (based upon scheduled maintenance procedures for Equipment)
    #
    # <SNIP>
    #  Example:
    #
    #  my $sheduled = alDente::Equipment($dbc,-equipment_type=>'Sequencer',-overdue=>1);      ## overdue flag indicates to only return hash if something is overdue
    #  if ($scheduled) {            #
    #    print SDB::HTML::display_hash($dbc,
    #        -hash=>%hash,
    #        -highlight_string=>'Overdue'),
    #    }
    #
    # </SNIP>
    #
    # Return: hash of overdue maintenance procedures (return undef if nothing is overdue and -overdue flag is set)
##########################
    my %args           = &filter_input( \@_, -args => 'dbc,equipment_id' );
    my $dbc            = $args{-dbc};
    my $equipment_id   = $args{-equipment_id};
    my $equipment_type = $args{-equipment_type};
    my $schedule_id    = $args{-schedule_id};
    my $due            = $args{-due};                                         ## only return value if something is overdue
    my $date           = $args{-date} || "CURDATE()";
    my $due_buffer     = $args{-due_buffer} || 1;                             ## days to look ahead for due maintenance
    my $return_html    = $args{-return_html};
    my $send_notice    = $args{-send_notice};                                 ## triggers email notification if applicable

    if ( $date =~ /^\d/ ) { $date = "'$date'" }                               ## quote dates to enable inclusion in query

    my @scheduled = $dbc->Table_find_array(
        'Maintenance_Schedule',
        [   'Maintenance_Schedule_ID', 'FK_Maintenance_Process_Type__ID',
            'FK_Equipment__ID', 'Scheduled_Equipment_Type', 'Scheduled_Frequency', 'Notice_Sent',
            "DATE_SUB($date, INTERVAL Scheduled_Frequency DAY) as Due",
            "DATE_SUB($date, INTERVAL Scheduled_Frequency-$due_buffer DAY) as Overdue"
        ],
    );

    my %Maintenance;
    my $i             = 0;
    my $overdue_count = 0;
    my $due_count     = 0;

    my @grps_due;
    my @grps_overdue;

    foreach my $scheduled_maintenance (@scheduled) {
        my ( $sched_id, $process_type_id, $equip_id, $type, $freq, $sent, $due, $overdue ) = split ',', $scheduled_maintenance;

        my $tables = 'Maintenance_Schedule,Equipment';
        my $condition;

        if ($equipment_id) {
            $condition = " AND Equipment_ID IN ($equipment_id)";
        }
        elsif ($equipment_type) {
            $condition = " AND Category = '$equipment_type' AND FK_Stock__ID = Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID";
            $tables .= ',Stock,Stock_Catalog,Equipment_Category';
        }
        elsif ($schedule_id) {
            $condition = " AND Maintenance_Schedule_ID=$schedule_id";
        }
        else {
            ## no extra condition ##
        }

        my @equip_ids = $dbc->Table_find(
             $tables, 'Equipment_ID',
            -condition => "WHERE Maintenance_Schedule_ID=$sched_id AND FK_Equipment__ID=Equipment_ID $condition",
            -distinct  => 1
        );

        foreach my $equip (@equip_ids) {

            my ($latest_info) = $dbc->Table_find_array(
                'Maintenance,Equipment,Status,Stock',
                [ 'Maintenance_DateTime as Last_Done', 'Status_Name', "CASE WHEN Maintenance_DateTime > '$overdue' AND Status_Name NOT LIKE '%Failed%' THEN 'OK' WHEN Maintenance_DateTime > '$due' THEN 'Due' ELSE 'Overdue' END as Status", 'FK_Grp__ID' ],
                "WHERE FK_Equipment__ID=Equipment_ID AND FK_Stock__ID=Stock_ID AND FKMaintenance_Status__ID=Status_ID AND Equipment_Status = 'In Use' AND FK_Maintenance_Process_Type__ID=$process_type_id AND FK_Equipment__ID=$equip ORDER BY Maintenance_DateTime DESC LIMIT 1",
            );

            my ( $latest, $m_status, $status, $grp ) = split ',', $latest_info;
            my ($category_name) = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
                'Category', "where FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID AND Equipment_ID = $equip" );

            $status ||= 'Overdue';    ## set in case no maintenance records currently exist
            $Maintenance{Maintenance_Schedule_ID}[$i]         = $sched_id;
            $Maintenance{Category}[$i]                        = $category_name;
            $Maintenance{FK_Maintenance_Process_Type__ID}[$i] = $process_type_id;
            $Maintenance{FK_Equipment__ID}[$i]                = $equip;
            $Maintenance{Frequency}[$i]                       = "$freq days";
            $Maintenance{Last_Done}[$i]                       = $latest;
            $Maintenance{Maintenance_Status}[$i]              = $m_status;
            $Maintenance{Status}[$i]                          = $status;
            $Maintenance{Notice_Sent}[$i]                     = $sent;
            $Maintenance{FK_Grp__ID}[$i]                      = $grp;

            if ( $status eq 'Overdue' ) { push @grps_overdue, $grp; $overdue_count++; }
            if ( $status eq 'Due' ) { $due_count++; push @grps_due, $grp; }

            $i++;
        }
    }
    if ( $due && !$overdue_count && !$due_count ) {return}    ## nothing due or overdue

    if ($send_notice) {
        ## send notification if not sent recently ##
        print Dumper \%Maintenance;
        print "done...\n";
    }

    my $output;
    if ( $return_html || $send_notice ) {
        $output = Views::Heading("Scheduled Maintenance");

        $output .= SDB::HTML::display_hash(
            -dbc              => $dbc,
            -title            => "Scheduled Maintenance",
            -hash             => \%Maintenance,
            -labels           => { 'FK_Grp__ID' => 'Owners', 'FK_Maintenance_Process_Type__ID' => 'Maintenance', 'Maintenance_Schedule_ID' => 'Schedule_ID' },
            -keys             => [ 'Maintenance_Schedule_ID', 'FK_Equipment__ID', 'Category', 'FK_Maintenance_Process_Type__ID', 'Maintenance_Status', 'Last_Done', 'Frequency', 'Status', 'Notice_Sent', 'FK_Grp__ID' ],
            -highlight_string => 'Overdue',
            -alt_message      => 'No scheduled maintenance tasks found',
            -return_html      => 1
        );

        $output .= $q->p();
        if ($schedule_id) { $output .= &Link_To( $dbc->config('homelink'), 'Edit', "&Search=1&Table=Maintenance_Schedule&Search List=$schedule_id" ) . $q->p() }

        $output .= &Link_To( $dbc->config('homelink'), 'add scheduled maintenance', '&New Entry=New Maintenance_Schedule' );

        if ($send_notice) {
            my @grps;
            if   ( $send_notice =~ /overdue/ ) { @grps = @grps_overdue }
            else                               { @grps = @grps_due }

            if (@grps) {
                require alDente::Subscription;
                my $subscription = alDente::Subscription->new( -dbc => $dbc );
                my $sent = $subscription->send_notification( -name => 'Scheduled Maintenance', -group => \@grps, -subject => 'Maintenance Due  (from Subscription Module)', -body => $output, -to => 'rguin' )
                    ;    ### send notice to all groups affected by due/overdue maintenance tasks
            }
        }
    }

    if ($return_html) {
        return $output;
    }
    elsif (%Maintenance) {
        return \%Maintenance;
    }
    else {
        return;
    }
}

#####################################
sub confirm_MatrixBuffer {
#####################################
    # Prompts for confirmation of matrix and buffer change
    # Called when sequencers are scanned with matrix/buffer
#####################################
    my %args      = &filter_input( \@_, -args => "equipment_id,sol_id", -mandatory => 'equipment_id,sol_id' );
    my $dbc       = $args{-dbc};
    my $Equipment = $args{-Equipment};
    my $equipment = $args{-equipment_id} || $Equipment->{id};
    my $sols      = $args{-sol_id};

    print alDente::Form::start_alDente_form( $dbc, 'status' );

    my @equipment_ids = split ',', $equipment;
    print h2("Sequencers");
    print "<UL>";
    foreach my $id (@equipment_ids) {

        #	print $dbc->get_FK_info("FK_Equipment__ID",$id).'<BR>';
        print "<LI>" . alDente_ref( 'Equipment', $id, -dbc => $dbc );
    }
    print "</UL>";

    print h2("Buffers/Matrices to Apply");
    print "<UL>";
    my $sol_barcodes = "";
    foreach my $id (@$sols) {

        #	print $dbc->get_FK_info("FK_Solution__ID",$id).'<BR>';
        print "<LI>" . alDente_ref( 'Solution', $id, -dbc => $dbc );
        $sol_barcodes .= "sol$id";
    }
    print "</UL>";

    print $q->hidden( -name => 'MatrixBuffer', -value => $sol_barcodes );
    print $q->hidden( -name => 'Equipment', -value => $equipment, -force => 1 );
    print $q->hidden( -name => 'Change MB', -value => 'Change Matrix and/or Buffer', -class => "Action" );
    print "\n" . $q->end_form() . "\n";
}

###########################                Should be earased
sub new_equipment {
###########################
    #
    # Prompt to enter in new equipment
    #

    Message('This is an obsolete function and if you are seeing this error please contact LIMS. CODE: new equipment');
    return;

}

1;
