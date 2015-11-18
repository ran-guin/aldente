####################
# Rack_Views.pm #
####################
#
# This contains various rack view pages directly
#
package alDente::Rack_Views;

use base alDente::Object_Views;
use strict;

use RGTools::RGIO;
use RGTools::Views;
use RGTools::Conversion;
use RGTools::String;

use SDB::HTML;
use SDB::DBIO;
use SDB::CustomSettings;
use SDB::Import_Views;

use alDente::Tools;
use alDente::Form;
use alDente::Rack;
use alDente::Validation;

use LampLite::CGI;
use LampLite::Bootstrap;

##############################
# global_vars                #
##############################
use vars qw(%Settings %Prefix);
my $MAX_ROWS_TO_DISPLAY = 400;

my $q                   = new LampLite::CGI;
my $BS = new Bootstrap;
#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $self = {};

    my ($class) = ref($this) || $this;
    bless $self, $class;

    $self->{dbc} = $dbc;

    return $self;
}

###################
sub Rack_home {
###################
    my %args = &filter_input( \@_, -args => 'dbc,rack_id,barcode' );
    my $dbc = $args{-dbc};

    my $original_barcode = $args{-original_barcode};
    $original_barcode = alDente::Scanner::scanned_barcode( -barcode => $original_barcode );    ## decode if necessary

    my @rack_list = Cast_List( -list => $args{-rack_id}, -to => 'array' );
    my @item_list = Cast_List( -list => $args{-barcode}, -to => 'array' );

    my $page;

    my $prefix = $dbc->barcode_prefix('Rack');
    my $equ_prefix = $dbc->barcode_prefix('Equipment');
    
    if ($original_barcode) {
        $original_barcode =~ /$prefix(\d+)/i;
        my $rack_id = $1;

        my @moves = split /$prefix\d+/i, $original_barcode;

        ## initialize with simple case (single rack scanned)
        my @racks = ($rack_id);
        my @items = ($original_barcode);

        if ( int(@moves) >= 1 ) {
            ## multiple target locations indicated ##
            @racks = ();
            @items = ();

            my $racks = $original_barcode;
            my $i     = 0;
            if ( !$moves[0] ) {
                $i++;
            }    ## if Rac is scanned prior to items, shift out first blank list of items
            while ( $racks =~ s /$prefix(\d+)//i ) {
                push @racks, $1;
                push @items, $moves[ $i++ ];
            }
        }
        @rack_list = @racks;
        @item_list = @items;
    }

    #    if (!$original_barcode) {#
    else {
        ## keep track of full original barcode even if supplied as multiple move event ##
        foreach my $i ( 1 .. int(@rack_list) ) {
            $original_barcode .= 'Rac' . $rack_list[ $i - 1 ] . $item_list[ $i - 1 ];
        }
        $args{-original_barcode} = $original_barcode;
    }

    my $slot_choice = $args{-slot_choice};

    if ( int(@rack_list) && int(@item_list) && ( int(@rack_list) ne int(@item_list) ) ) {
        Message("Warning: Ambiguous application of items to racks");
        return;
    }

    #    my $equip = &get_aldente_id( $dbc, $original_barcode, 'Equipment' );
    my $plates    = &get_aldente_id( $dbc, $original_barcode, 'Plate' );
    my $tubes     = &get_aldente_id( $dbc, $original_barcode, 'Plate' );
    my $solutions = &get_aldente_id( $dbc, $original_barcode, 'Solution' );
    my $sources   = &get_aldente_id( $dbc, $original_barcode, 'Source' );
    my $racks     = &get_aldente_id( $dbc, $original_barcode, 'Rack' );
    my $boxes     = &get_aldente_id( $dbc, $original_barcode, 'Box' );

    if ( ( $original_barcode =~ /$prefix(\d+)$prefix(\d+)/i ) || ( $original_barcode =~ /()$equ_prefix\d+$prefix\d+/i ) || ( $original_barcode =~ /()$prefix(\d+)$equ_prefix\d+/i ) ) {
        ## moving storage locations ##

        if ( $plates || $tubes || $solutions || $sources || $boxes ) {
            $dbc->session->error("Ambiguous movement specification");
        }
        else {
            $page .= scanned_Racks($dbc);
        }
    }

    $page .= alDente::Form::start_alDente_form( $dbc, 'Rack list' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 ) . $q->hidden( -name => 'Barcode', -value => $original_barcode );

    $page .= $q->hidden( -name => 'Fill By', -value => $args{-fill_by} );

    foreach my $i ( 1 .. int(@rack_list) ) {
        my $rack_id = $rack_list[ $i - 1 ];
        my $barcode = $item_list[ $i - 1 ];

        $args{-rack_id} = $rack_id;
        $args{-barcode} = $barcode;
        if ( $i > 1 ) {
            $args{-repeated} = 1;
        }    ## suppresses duplication of prefix button options

        my $plates    = &get_aldente_id( $dbc, $barcode, 'Plate' );
        my $tubes     = &get_aldente_id( $dbc, $barcode, 'Plate' );
        my $solutions = &get_aldente_id( $dbc, $barcode, 'Solution' );
        my $sources   = &get_aldente_id( $dbc, $barcode, 'Source' );

        my $equip = &get_aldente_id( $dbc, $barcode, 'Equipment' );
        my $target_rack = alDente::Rack::get_rack_parameter( 'Target_Rack', -dbc => $dbc );    ## param('Target_Rack') || param('Target Rack Choice');

        my $racks = &get_aldente_id( $dbc, $barcode, 'Rack' );

        if ( ( $original_barcode =~ /$prefix\d+$prefix\d+/i ) ) {
            ## moving Racks ##
            if ( $plates || $tubes || $solutions || $sources ) {
                Message("Warning: Cannot move Items at the same time as storage locations (too confusing)");
                Message("O: $original_barcode contains $prefix multiples");
                return $page;
            }
        }

        unless ( $racks || $rack_id ) {
            Message("No valid racks in $barcode");
            return;
        }

        my $source_rack = $racks;
        if ($target_rack) {
            my $target_rack_id = &get_FK_ID( $dbc, 'FK_Rack__ID', $target_rack );
            if ( $target_rack_id =~ /[1-9]/ ) { $racks .= ",$target_rack_id"; }
        }

        my $confirmed         = $args{-confirmed} || param('Confirm Move');
        my $transfer_items    = param('Transfer Rack Contents');
        my $transfer_includes = join ',', param('Include Items');
        my $delete_rack       = param('delete_rack');

        if ($delete_rack) {
            my $deleted = alDente::Rack::delete_rack( -dbc => $dbc, -rack_id => $racks );
            if ($deleted) {
                Message("Deleted rack(s)");
            }
            Message("nothing deleted");
            return;
        }

        $page .= alDente::Rack::process_rack_request(%args);

        #	my ( $moving_contents, $moving_racks ) = alDente::Rack::process_rack_request(%args);
        #
        my $items_scanned = $equip || $tubes || $plates || $solutions || $sources;

        my $moving_racks = ( $racks =~ /,/ && !$items_scanned );
        my $moving_contents = ( $racks && $items_scanned );

        if ($confirmed) {

            #	    Message("<B>Move Confirmed</B>");
            &main::home('main');
        }
        elsif ($moving_racks) {

            my @objects = alDente::Rack::get_stored_material_types( undef, -dbc => $dbc );
            $page .= $q->hr;
            if ( $racks =~ /,/ ) {
                Message("To Transfer items from one rack to another, indicate items to be transferred below:");
                $page .= $q->submit(
                    -name  => 'rm',
                    -value => 'Transfer Rack Contents',
                    -class => "Std"
                    )
                    . &hspace(5)
                    . " of Type: "
                    . checkbox_group(
                    -name    => 'Include Items',
                    -value   => \@objects,
                    -checked => [ 0, 1, 0 ]
                    ) . lbr();
                $page .= $q->submit( -name => 'rm', -value => 'Delete Rack', -class => 'Action' );
            }
        }
        elsif ($moving_contents) {
            Message("nothing more");
            ## nothing more ... ##
        }
        else {
            $page .= home_page( $dbc, $rack_id );
        }
        $page .= '<p ></p>';
    }
    $page .= $q->end_form();
    $page .= '..done';

    #    &main::leave();
    return $page;
}

###################
sub display_Main_Page {
###################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $transport_box  = $self->display_Barcode_transport_box( -dbc => $dbc );
    my $throw_away_box = $self->display_throw_away_box( -dbc        => $dbc );
    my $location_block = $self->display_Barcode_bench( -dbc         => $dbc );
    my $inventory_block
        = alDente::Form::start_alDente_form( $dbc, 'Inventory Search' )
        . $q->hidden(-name=>'cgi_application', -value=>'alDente::Equipment_App', -force=>1)
        . Show_Tool_Tip( $q->submit( -name => 'rm', -value=>'Inventory', -class => "Std" ), "Inventory home page" )
        . &hspace(20)
        . " <- <i>Perform inventory on storage fridge / freezers</i>"
        . $q->end_form();

    my $rack_block        = $self->display_slots();
    my $pre_barcode_block = $self->display_Pre_Barcode_Block();
    my $move_block        = $self->display_move_Block();

    my $storage_icon = $BS->icon('suitcase', -size=>'5x'); ## LampLite::Login_Views::icons( 'Storage', -dbc => $dbc );
    my $shipping_icon = $BS->icon('truck', -size=>'5x'); ## LampLite::Login_Views::icons( 'Receiving', -dbc => $dbc )
    
    my $storage = alDente::Form::init_HTML_table( "Storage Fridges/Freezers/Shelves", -margin => 'on' );
    $storage->Set_Row( [ $storage_icon, $throw_away_box . '<hr>' . $location_block . '<hr>' . $transport_box . '<hr>' . $inventory_block . '<hr>' . $rack_block . '<hr>' . $pre_barcode_block . '<hr>' . $move_block ] );

    my $transit = alDente::Form::init_HTML_table( "In Transit", -margin => 'on' );
    $transit->Set_Row( [ $shipping_icon,  in_transit($dbc) ] );

    my $page = $storage->Printout(0);
    $page .= $transit->Printout(0);

    return $page;

}

###########################
sub display_move_Block {
###########################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->{dbc};
    my $view = alDente::Form::start_alDente_form( $dbc, 'PB_Block' )
        . Show_Tool_Tip(
        $q->submit(
            -name    => 'rm',
            -value   => 'Move Samples',
            -force   => 1,
            -class   => 'Action',
            -onClick => 'return validateForm(this.form)',
        ),
        "to add a rack of pre-printed SRC barcodes"
        )
        . set_validator( -name => 'Rack', -mandatory => 1, -prompt => 'Please select a target box' )
        . set_validator( -name => 'Scanned_Rack_File', -mandatory => 1, -prompt => 'Please select a CSV file' )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 )
        . &hspace(20)
        . "Slotted Box: "
        . Show_Tool_Tip( $q->textfield( -name => 'Rack', -value => '', -size => 10 ), 'Slotted Box ID' )
        . $q->radio_group( -name => 'Object', -id => 'Object', -values => [ 'Source', 'Plate' ], -default => 'Source', -force => 1, )
        . &vspace()
        . 'Scanned CSV File: '
        . $q->filefield( -name => 'Scanned_Rack_File', -size => 30 )
        . $q->end_form();

    return $view;
}

###########################
sub display_Pre_Barcode_Block {
###########################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->{dbc};
    my $view = alDente::Form::start_alDente_form( $dbc, 'PB_Block' )
        . Show_Tool_Tip(
        $q->submit(
            -name    => 'rm',
            -value   => 'Add Pre-Labeled Box',
            -force   => 1,
            -class   => 'Action',
            -onClick => 'return validateForm(this.form)',
        ),
        "to add a rack of pre-printed SRC barcodes"
        )
        . set_validator( -name => 'Equip_Location', -mandatory => 1, -prompt => 'Please select an initial location for transport box' )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 )
        . &hspace(20)
        . "Number of Tubes: "
        . Show_Tool_Tip( $q->textfield( -name => 'tubes_count', -value => '', -class => 'narrow-txt', -default => '96' ), 'Number of Samples' )
        . hspace(10)
        . "Order: "
        . hspace(2)
        . $q->radio_group(
        -name    => 'Order',
        -id      => 'Order',
        -values  => [ 'Row', 'Column' ],
        -default => 'Row',
        -force   => 1,
        ) . $q->end_form();

    return $view;
}

###########################
sub display_throw_away_box {
###########################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $block = alDente::Form::start_alDente_form( $dbc, 'AddingRack' ) 
        . $q->submit( -name => 'rm', -value => 'Throw Away', -force => 1, -class => 'Action', -onClick => 'return validateForm(this.form)' ) 
        . &hspace(20)
        . SDB::HTML::dynamic_text_element(
        -name         => 'Rack_List',
        -cols         => 20,
        -rows         => 1,
        -force        => 1,
        -class        => 'medium',
        -max_cols     => 20,
        -max_rows     => 10,
        -split_commas => 1
        )
        . set_validator( -name => 'Rack_List', -mandatory => 1, -prompt => 'Please select an initial location for transport box' )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 )
        . $q->end_form();
    return $block;

}

###########################
sub display_slots {
###########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $rack_block = alDente::Form::start_alDente_form( $dbc, 'Rack Search Page' );

    $rack_block
        .= Show_Tool_Tip( $q->submit( -name => 'Barcode_Event', -value => 'Print Slot Barcodes', -class => "Std" ), "Specify barcodes for slots on a rack" )
        . hspace(1)
        . "Max Row: "
        . $q->textfield( -name => 'Max_Row', -value => 'i', -class => 'narrow-txt' )
        . hspace(1)
        . "Max Col: "
        . $q->textfield( -name => 'Max_Col', -value => '9', -class => 'narrow-txt' )
        . hspace(1)
        . "Scale: "
        . $q->textfield( -name => 'Scale', -value => 1, -class => 'narrow-txt' )
        . hspace(1)
        . "Height: "
        . $q->textfield( -name => 'Height', -value => 30, -class => 'narrow-txt' )
        . hspace(1)
        . "Vertical Spacing: "
        . $q->textfield( -name => 'Vspace', -value => 5, -class => 'narrow-txt' )
        . $q->end_form();
    return $rack_block;
}

###########################
sub display_Barcode_transport_box {
###########################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->{dbc};

    my @location_ids = $dbc->Table_find( 'Location', 'Location_ID', "WHERE Location_Type ='Internal' " );
    my $locs = join ',', @location_ids;
    my @locations = $dbc->get_FK_info_list( -field => 'FK_Location__ID', -condition => "WHERE Location_ID IN ($locs)" );

    my $transport_box = alDente::Form::start_alDente_form( $dbc, 'AddingRack' )
        . Show_Tool_Tip(
        $q->submit(
            -name    => 'rm',
            -value   => 'Barcode Transport Box',
            -force   => 1,
            -class   => 'Action',
            -onClick => 'return validateForm(this.form)',
        ),
        "to add a transport box please select its location and press button"
        )
        . set_validator( -name => 'Equip_Location', -mandatory => 1, -prompt => 'Please select an initial location for transport box' )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 )
        . &hspace(20)
        . "Full Rack Name(Without Number): "
        . Show_Tool_Tip( $q->textfield( -name => 'Rack_Name', -value => '', -size => 20 ), ' Optional: Defaults to R if not set' )
        . ' in location: '
        . $q->popup_menu( -name => 'Equip_Location', -values => [ '', @locations ], -default => "" )
        . &hspace(20)
        . &Link_To( $dbc->config('homelink'), 'Add NEW Location', "&cgi_application=alDente::Rack_App&rm=Add New Location", 'red' )
        . $q->end_form();
    return $transport_box;
}

###########################
sub display_Barcode_bench {
###########################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->{dbc};

    my @location_ids = $dbc->Table_find( 'Location', 'Location_ID', "WHERE 1 " );
    my $locs = join ',', @location_ids;
    my @locations = $dbc->get_FK_info_list( -field => 'FK_Location__ID', -condition => "WHERE Location_ID IN ($locs)" );

    my $location_block
        = alDente::Form::start_alDente_form( -dbc => $dbc, -form => 'AddingRack' )
        . Show_Tool_Tip( $q->submit( -name => 'rm', -value => "Barcode Bench", -force => 1, -class => 'Action', -onClick => 'return validateForm(this.form)', ), "to barcode a bench please select its location and press button" )
        . &hspace(20)
        . "Full Rack Name: "
        . Show_Tool_Tip( $q->textfield( -name => 'Rack_Name', -value => '', -size => 20 ), 'This name has to be unique' )
        . ' in location: '
        . &hspace(20)
        . $q->popup_menu( -name => 'Equip_Location', -values => [ '', @locations ], -default => "" )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 )
        . set_validator( -name => 'Equip_Location', -mandatory => 1, -prompt => 'Please select a location in where your bench is located. Add new location if not available ' )

        . &hspace(20) . &Link_To( $dbc->config('homelink'), 'Add NEW Location', "&cgi_application=alDente::Rack_App&rm=Add New Location", 'red' ) . $q->end_form();
    return $location_block;
}

###############################
sub show_Relocation_History {
###############################
    my %args      = filter_input( \@_, -args => 'object,id', -mandatory => 'dbc,object,id' );
    my $dbc       = $args{-dbc};
    my $object    = $args{-object};
    my $object_id = $args{-id};
    my $printable = $args{-printable};

    my $location_history;
    if ( $object eq 'Rack' ) {
        ### check for shipment containers  ##
        $location_history .= vspace()
            . $dbc->Table_retrieve_display(
            'Shipped_Object,Shipment',
            [ 'FK_Shipment__ID', 'Shipment_Status', 'FKFrom_Site__ID', 'FKFrom_Grp__ID', 'FKTarget_Grp__ID', 'FKTarget_Site__ID', 'Shipment_Comments' ],
            "WHERE FK_Shipment__ID=Shipment_ID AND FKTransport_Rack__ID = $object_id",
            -title       => 'Shipment History',
            -distinct    => 1,
            -alt_message => 'No shipments tied to this specific location (may be tied to parent containers)',
            -return_html => 1
            );

        ### check for shipped boxes ##
        $location_history .= vspace()
            . $dbc->Table_retrieve_display(
            'Shipped_Object,Shipment,Object_Class',
            [ 'FK_Shipment__ID', 'Shipment_Status', 'FKFrom_Site__ID', 'FKFrom_Grp__ID', 'FKTarget_Grp__ID', 'Addressee', 'FKTarget_Site__ID', 'Shipment_Comments' ],
            "WHERE FK_Shipment__ID=Shipment_ID AND FK_Object_Class__ID=Object_Class_ID AND Object_Class='Rack' AND Object_ID = $object_id",
            -title       => 'Shipped History',
            -distinct    => 1,
            -alt_message => 'No shipments containing this Box (may be tied to parent containers)',
            -return_html => 1,
            -border      => 1
            );

        ## track location of racks via aliases ##
        $location_history .= vspace()
            . $dbc->Table_retrieve_display(
            'Change_History,DBField,Employee',
            [ 'Old_Value as Moved_From', 'New_Value as Moved_To', 'Employee_Name as Moved_by', 'Modified_Date', 'Change_History.Comment' ],
            "WHERE FK_DBField__ID=DBField_ID AND Field_Table = '$object' AND Field_Name = 'Rack_Alias' AND Record_ID = $object_id AND Change_History.FK_Employee__ID=Employee_ID",
            -order       => 'Modified_Date ASC',
            -alt_message => 'No Movement Tracked for this specific location (though parent containers may have been moved)',
            -return_html => 1,
            -print_link  => $printable,
            -title       => "Re-Location History for Rack $object_id",
            -border      => 1
            );

    }
    else {
        if ( $object ne 'Equipment' ) {
            $location_history .= $dbc->Table_retrieve_display(
                '(Change_History,DBField,Employee,Rack as New_Rack) LEFT JOIN Rack as Old_Rack ON Old_Rack.Rack_ID = Old_Value',
                [ 'Old_Rack.Rack_Alias as Moved_From', 'New_Rack.Rack_Alias as Moved_To', 'Change_History.Comment as Movement_History', 'Employee_Name as Moved_by', 'Modified_Date' ],
                "WHERE FK_DBField__ID=DBField_ID AND Field_Table = '$object' AND Field_Name = 'FK_Rack__ID' AND Record_ID = $object_id AND New_Rack.Rack_ID = New_Value AND Change_History.FK_Employee__ID=Employee_ID",
                -order       => 'Modified_Date ASC',
                -return_html => 1,
                -alt_message => "No Movement Tracked for this $object",
                -print_link  => $printable,
                -title       => "Re-Location History for $object $object_id",
            );
        }

        ### check for shipments ##
        my ($class) = $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE Object_Class = '$object'" );
        if ($class) {
            $location_history .= &vspace(5)
                . $dbc->Table_retrieve_display(
                'Shipped_Object,Shipment',
                [ 'FK_Shipment__ID', 'Shipment_Status', 'Shipment_Sent', 'Shipment_Received', 'FKFrom_Site__ID', 'FKFrom_Grp__ID', 'FKTarget_Grp__ID', 'FKTarget_Site__ID' ],
                "WHERE FK_Shipment__ID=Shipment_ID AND FK_Object_Class__ID = $class AND Object_ID = $object_id",
                -return_html => 1,
                -alt_message => 'No shipments associated with this sample ',
                -title       => "Shipments of $object $object_id"
                );
        }
    }

    if ( $location_history =~ /\bNo Movement Tracked/ && $location_history =~ /\bNo shipments/ ) { $location_history = '' }

    if ($printable) { return $location_history }

    if ($location_history) {
        return create_tree( -tree => { 'Relocation History' => $location_history } );
    }
    else {return}

}

######################
sub scanned_Racks {
######################
    my %args      = filter_input( \@_, -args => 'dbc,barcode' );
    my $dbc       = $args{-dbc};
    my $barcode   = $args{-barcode};
    my $confirmed = $args{-confirmed};
    my $source    = $args{-source_racks};
    my $target    = $args{-target_rack};
    my $target_rack;
    my $source_racks;
    my $page;

    my @racks = split ',', get_aldente_id( $dbc, $barcode, 'Rack' );
    my $equip = get_aldente_id( $dbc, $barcode, 'Equipment' );

    if ( $source && $target ) {
        $target_rack  = $target;
        $source_racks = $source;
    }
    else {
        $target_rack = pop @racks;
        $source_racks = join ',', @racks;
    }

    if ( !$source_racks ) {
        ## only one rack supplied .. ##
        $page .= list_Contents( $dbc, -racks => $target_rack );
    }
    elsif (
        alDente::Rack::can_move_rack(
            -dbc          => $dbc,
            -rack_id      => $source_racks,
            -target_rack  => $target_rack,
            -equipment_id => $equip
        )
        )
    {
        Message("Move $source_racks -> $target_rack ($equip)");
        $page .= alDente::Rack_Views::move_Rack(
            -dbc          => $dbc,
            -source_racks => $source_racks,
            -target_rack  => $target_rack,
            -equip        => $equip,
            -confirmed    => $confirmed
        );
    }
    elsif (
        alDente::Rack::can_move_content(
            -dbc         => $dbc,
            -rack_id     => $source_racks,
            -target_rack => $target_rack
        )
        )
    {
        Message("Move Content of $source_racks -> $target_rack");
        $page .= alDente::Rack_Views::move_Rack_Content(
            -dbc       => $dbc,
            -source    => $source_racks,
            -target    => $target_rack,
            -confirmed => $confirmed
        );
    }
    else {

        #	Message("Multiple locations scanned ($source_racks;$target_rack");
        $page .= list_Contents( $dbc, -racks => "$source_racks,$target_rack" );
    }

    return $page;
}

######################
sub move_Rack_Content {
######################
    # Description:
    #
    #
    #
    # Input:
    #
    # Output:
    #
######################
    my %args      = filter_input( \@_ );
    my $dbc       = $args{-dbc};
    my $confirmed = $args{-confirmed};
    my $source    = $args{-source};
    my $target    = $args{-target};
    my @classes;
    my $racks;
    my $page;

    my $source_column = label( -dbc => $dbc, -rack_id => $source ) . list_Contents( -dbc => $dbc, -racks => $source, -no_actions => 1 );
    my $target_column = label( -dbc => $dbc, -rack_id => $target ) . list_Contents( -dbc => $dbc, -racks => $target, -no_actions => 1 );
    my $warning = alDente::Rack::display_content_move_warning( -dbc => $dbc, -source => $source, -target => $target );

    my %colspan;
    $colspan{1}->{1} = 2;    ## set the Heading to span 2 columns
    $page .= &Views::Table_Print( content => [ [ $source_column, "&nbsp&nbsp&nbsp&nbsp", $target_column ] ], -colspan => \%colspan, -spacing => "10", print => 0 );

    $page .= move_contents( -dbc => $dbc, -racks => $source, -classes => \@classes, -target => $target );

    return $page;
}

######################################################
##          Views                                  ##
######################################################
######################
# Description:
#	Returns a HTML page with 2 layers for a given rack to barcode plates (from sources)
#	Layer 1: Use existing library
#	Layer 2: Create new libraries
# Input:
#	Rack_id (Must be a box rack and contain sources)
######################
sub show_Src_to_Tube_option {
######################
    my %args       = filter_input( \@_, -args => 'dbc,rack_id' );
    my $dbc        = $args{-dbc};
    my $rack_id    = $args{-rack_id};
    my $source     = $args{-source};
    my $ordered_by = $args{-ordered_by};                            ## pass in current ordering within box if applicable ##

    my %layers;
    my ($slots) = $dbc->Table_find( 'Rack', 'count(Rack_ID)', "WHERE Rack_Type = 'Slot' and FKParent_Rack__ID = $rack_id" );
    my $source_list = Cast_List( -list => $source, -to => 'string', -autoquote => 0 );

    my $cur_order;
    unless ( $ordered_by =~ /source_id/i ) {
        $cur_order = alDente::Rack::SQL_Slot_order($ordered_by);
    }
    else {
        $cur_order = $ordered_by;
    }
    my %info = $dbc->Table_retrieve( 'Source, Original_Source,Rack', ['Original_Source_Name'], "WHERE Source.FK_Original_Source__ID = Original_Source_ID AND Rack.Rack_ID=Source.FK_Rack__ID AND Source_ID IN ($source_list)", -order_by => $cur_order, );
    unless ( $info{Original_Source_Name} ) {
        return;
    }

    $layers{'Redefine Sources as Plates from Existing Library'} = select_existing_library( -dbc       => $dbc, -rack_id => $rack_id, -source => $source, -slots => $slots, -ordered_by => $ordered_by );
    $layers{'Upload New Libraries from Excel Template'}         = upload_new_collection( -dbc         => $dbc, -rack_id => $rack_id, -source => $source, -slots => $slots, -ordered_by => $ordered_by );
    $layers{'Create New Libraries from Preset Template'}        = reference_template_collection( -dbc => $dbc, -rack_id => $rack_id, -source => $source, -slots => $slots, -ordered_by => $ordered_by );

    my $page;

    ## check for repeat libraries
    my %existing_libs = $dbc->Table_retrieve(
        'Source, Original_Source,Library, Plate, Rack',
        [ 'Original_Source_Name', 'GROUP_CONCAT(distinct Library_Name) AS libraries' ],
        "WHERE Source.FK_Original_Source__ID = Original_Source_ID and Source.FK_Original_Source__ID=Library.FK_Original_Source__ID AND Plate.FK_Library__Name=Library_Name AND Rack.Rack_ID=Source.FK_Rack__ID AND Rack.Rack_ID = $rack_id",
        -group_by => 'Original_Source_Name',
        -order_by => 'Original_Source_Name',
        -distinct => 1,
    );
    if ( int( keys %existing_libs ) > 0 ) {
        my @os;
        my $index = 0;
        while ( defined $existing_libs{Original_Source_Name}[$index] ) {
            push @os, $existing_libs{Original_Source_Name}[$index] . " (" . $existing_libs{libraries}[$index] . ")";
            $index++;
        }
        my $html = "<UL><LI>";
        $html .= join '</LI><LI>', @os;
        $html .= "</UL>";
        $page .= $dbc->warning( "Identical Specimens (same OS) have been barcoded onto Plates before....  Previously defined Libraries:", -subtext => $html, -hide => 1 ) . '<p ></p>';
    }

    $page .= &define_Layers(
        -layers    => \%layers,
        -format    => 'tab',
        -tab_width => 100,
        -align     => 'left',
        -width     => '100%',
        -order     => [ 'Create New Libraries from Preset Template', 'Upload New Libraries from Excel Template', 'Redefine Sources as Plates from Existing Library' ],
    ) . "</TABLE>";    #,

    return $page;
}

#
# Method to verify expected ordering of Samples within a Box.
#
# This generates warnings if items are not in consecutive order or if the ordering is not as expected
#
# Additional warnings may also be provided to warn of empty slot locations
#
# Return: ($order, $message)
##################
sub check_order {
##################
    my %args           = filter_input( \@_, -args => 'dbc,rack_id,class,expected_order' );
    my $dbc            = $args{-dbc};
    my $rack_id        = $args{-rack_id};
    my $class          = $args{-class};
    my $expected_order = $args{-expected_order} || 'Row';
    my $control_column = $args{-control_column};                                             ### ignore record ids in control column(s) if supplied...
    my $control_row    = $args{-control_row};

    my $non_slotted_warning = $args{-non_slotted_warning};                                   ### flag to indicate if a warning should be issued for non-slotted boxes
    my $debug               = $args{-debug};
    my ( $order, $message );                                                                 ## initialize output parameters

    if ( $expected_order !~ /^(Row|Column|\w+_ID)$/ ) {
        $message .= Message( "Warning: expected order should be Row, Column or ID (not $expected_order)", -return_html => 1 );
        $expected_order = 'Row';
    }

    ## IGNORE if not box ##
    my ($rack_type) = $dbc->Table_find( 'Rack', 'Rack.Rack_Type', "WHERE Rack.Rack_ID = $rack_id" );

    ## include optional condition if users are using specified rows/columns for controls ##
    my $control_condition;
    if ($control_column) {
        my $controls = Cast_List( -list => $control_column, -to => 'string', -autoquote => 1 );
        $control_condition .= " AND LEFT(Rack.Rack_Name,1) NOT IN ($controls) ";
        $message .= Message( "Ignoring Column(s): $controls to avoid flagging control samples", -return_html => 1 );
    }
    if ($control_row) {
        my $controls = Cast_List( -list => $control_row, -to => 'string', -autoquote => 1 );
        $control_condition .= " AND 1*Mid(Rack.Rack_Name,2,3) NOT IN ($controls) ";
        $message .= Message( "Ignoring Row(s): $controls to avoid flagging control samples", -return_html => 1 );
    }

    if ( $rack_type ne 'Box' ) {
        ## no need to check ordering except for Boxes ... ##
        return;
    }

    my %Sorted;    ## check sorting by Row, Column and ID as required ... ##
    ## define ordering logic ##
    foreach my $order_by ( 'Row', 'Column', 'ID' ) {
        my $SQL_order = alDente::Rack::SQL_Slot_order($order_by);    ## get SQL for Sorting logic
        my @list
            = $dbc->Table_find( 'Source, Rack, Rack as Box', "${class}_ID, Rack.Rack_Name", "WHERE Rack.Rack_ID=FK_Rack__ID AND Box.Rack_ID = Rack.FKParent_Rack__ID AND Box.Rack_ID = $rack_id $control_condition Order by $SQL_order", -debug => $debug );

        if ( !@list ) {
            ## abort in case query fails and generates false match between '' and sorted '' ##
            if ($non_slotted_warning) {
                my @non_slotted = $dbc->Table_find_array( 'Source, Rack', [ "${class}_ID", 'Rack.Rack_Name' ], "WHERE Rack.Rack_ID=FK_Rack__ID AND Rack.Rack_ID = $rack_id Order by ${class}_ID" );

                if (@non_slotted) {
                    $message .= $dbc->warning( "$class records may not be sorted (Box not tracked as independent slots) - ordering by ${class}_ID", -return_html => 1 );
                    return ( "${class}_ID", $message );
                }
            }
            return ( 'undef', $message );    ## no $class records in Box... no need to check order ...

        }

        my ( @fwd, @rev, @pos );
        foreach my $row (@list) {
            my ( $id, $rack ) = split ',', $row;
            push @fwd, $id;
            unshift @rev, $id;
            push @pos, $rack;
        }

        my @sorted     = sort @fwd;
        my @sorted_rev = reverse sort @fwd;

        @{ $Sorted{$order_by} }        = @fwd;
        @{ $Sorted{"$order_by DESC"} } = @rev;
        @{ $Sorted{"$order_by Rack"} } = @pos;

        @{ $Sorted{"$order_by SORTED"} } = @sorted;

        if ( ( join ',', @sorted ) eq ( join ',', @fwd ) ) {
            $order = $order_by;
        }
        elsif ( ( join ',', @sorted_rev ) eq ( join ',', @fwd ) ) {
            $order = "$order_by DESC";
        }

        if ( $order && defined $Sorted{$expected_order} ) {last}    ## no need to check other ordering options if ordering found
    }

    if ($order) {
        ## check for skipped slots ... first ##
        my $positions = join ',', $dbc->Table_find( 'Rack', 'Rack_Name', "WHERE FKParent_Rack__ID = $rack_id $control_condition ORDER BY " . alDente::Rack::SQL_Slot_order($order) );
        my $filled_positions = join ',', @{ $Sorted{"$order Rack"} };

        if ( $positions =~ /^$filled_positions\b/ ) {
            ## no slots skipped ##
        }
        elsif ( $positions =~ /(.*),$filled_positions\b/ ) {
            my @skipped = split ',', $1;
            $message .= Message( "Warning: first " . int(@skipped) . ' slot positions skipped', -return_html => 1 );
        }
        else {
            $message .= Message( "Warning: empty slot positions found:", -return_html => 1 );
            my @all    = Cast_List( -list => $positions,        -to => 'array' );
            my @filled = Cast_List( -list => $filled_positions, -to => 'array' );

            my ( $ok, $empty, $undef ) = RGmath::intersection( \@all, \@filled );

            $message .= "Empty wells: @$empty<BR>";
            if (@$undef) { $message .= "Undefined wells: @$undef<BR>" }
        }

        $message .= $dbc->message( "$class Objects ordered by $order within Box", -return_html => 1 );
    }
    else {
        ## order did not match at some point ... ##
        if ( !%Sorted ) {return}
        elsif ( !defined $Sorted{$expected_order} ) { $message .= Message("Cannot find ordering for $expected_order ?") }
        else {
            $message .= Message( "Warning: $class Objects NOT in consecutive order within Box", -return_html => 1 );

            my @expected = @{ $Sorted{"$expected_order SORTED"} };
            my @actual   = @{ $Sorted{$expected_order} };
            my @pos      = @{ $Sorted{"$expected_order Rack"} };

            my @list;
            foreach my $i ( 0 .. $#actual ) {
                if   ( $actual[$i] ne $expected[$i] ) { push @list, "$pos[$i]: $actual[$i] (expected $expected[$i])" }
                else                                  { push @list, "$pos[$i] : $actual[$i]" }
            }
            $message .= create_tree( -tree => { "$class positions in Box (by $expected_order)" => Cast_List( -list => \@list, -to => 'OL' ) } );
            $order = 'undef';
        }
    }

    if ( $expected_order && $expected_order ne $order ) {
        $message .= Message( "Warning: Note Order ($order) not as expected ($expected_order)", -return_html => 1 );
    }
    return ( $order, $message );
}

######################
# Description:
#	Returns a table for selecting info for an existing library to create plates
#
# Input:
#	Rack_id (Must be a box rack and contain sources)
######################
sub select_existing_library {
######################
    my %args       = filter_input( \@_, -args => 'dbc,rack_id' );
    my $dbc        = $args{-dbc};
    my $rack_id    = $args{-rack_id};
    my $source     = $args{-source};
    my $slots      = $args{-slots};
    my $ordered_by = $args{-ordered_by};

    my $sources;
    $sources = join ',', @$source if $source;
    my $extra = $q->hidden( -name => 'Reference_Field', -value => 'Source.Source_ID', -force => 1 ) . $q->hidden( -name => 'Reference_IDs', -value => $sources, -force => 1 );
    $extra
        .= 'Select Library/Collection: '
        . alDente::Tools::search_list( -dbc => $dbc, -name => 'FK_Library__Name', -dbc => $dbc, -search => 1, -filter => 1 )
        . set_validator( -name => 'FK_Library__Name', -mandatory => 1, -prompt => 'You must enter a Library' );

    my @extras = ($extra);

    ## Order of source ids depends if the box is sloted or not
    if ($slots) {
        unshift @extras, "Link by: ";
        $extras[-1] .= $q->radio_group( -name => 'Order', -values => [ 'Row', 'Column' ], -default => $ordered_by, -force => 1 ) . set_validator( -name => 'Order', -mandatory => 1 );
    }
    else {
        unshift @extras, "Link by: ";
        $extras[-1] .= $q->radio_group( -name => 'Order', -values => ["$ordered_by"], -default => $ordered_by, -force => 1 ) . set_validator( -name => 'Order', -mandatory => 1 );
    }

    require SDB::Import_Views;
    my $Import_View = new SDB::Import_Views( -dbc => $dbc );
    my $page = $Import_View->upload_file_box(
        -dbc             => $dbc,
        -cgi_application => 'alDente::Transform_App',
        -button          => $q->submit( -name => 'rm', -value => 'Redefine Sources as Plates', -force => 1, -class => 'Action', -onclick => 'return validateForm(this.form)' ),
        -extra           => [ \@extras ],
        -ordered         => $ordered_by,                                                                                                                                          ### allow user to specify control rows / columns for order validation
    );

    return $page;
}

######################
sub reference_template_collection {
######################
    my %args       = filter_input( \@_, -args => 'dbc,rack_id' );
    my $dbc        = $args{-dbc};
    my $rack_id    = $args{-rack_id};
    my $source     = $args{-source};
    my $slots      = $args{-slots};
    my $ordered_by = $args{-ordered_by};
    my $preset     = $args{-preset};

    my $Template = new alDente::Template( -dbc => $dbc );
    my ( $templates, $labels ) = $Template->get_Template_list( -dbc => $dbc, -custom => 1, -reference => 'Source' );
    my $default = '--- Select Template ---';
    push @$templates, $default if $templates;

    my $button = RGTools::Web_Form::Submit_Button( form => 'Online_Form', name => 'rm', value => 'Link Records to Template File', class => 'Action', onClick => 'return validateForm(this.form); ', force => 1, newwin => 'online_form' );

    my $page = alDente::Form::start_alDente_form( 'add', -dbc => $dbc )

        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Transform_App', -force => 1 )
        . $q->hidden( -name => 'Reference_Field', -value => 'Source.Source_ID',       -force => 1 )
        . $q->hidden( -name => 'Reference_IDs',   -value => $source,                  -force => 1 )
        . Safe_Freeze( -name => "Preset", -value => $preset, -format => 'hidden', -encode => 1 );
    if ($slots) {
        $page .= "Link by: ";
        $page .= $q->radio_group( -name => 'Order', -values => [ 'Row', 'Column' ], -default => $ordered_by, -force => 1 ) . set_validator( -name => 'Order', -mandatory => 1 );
    }
    else {
        $page .= $q->hidden( -name => 'Order', -value => $ordered_by, -force => 1 );
    }

    $page
        .= $button
        . hspace(5)
        . $q->popup_menu( -name => 'template_file', -values => $templates, -labels => $labels, -default => $default, -force => 1 )
        . set_validator( -name => 'template_file', -mandatory => 1 )
        . hspace(5)
        . $q->checkbox( -name => 'Edit Prior to Upload' )
        . $q->end_form();

    return $page;

}

######################
# Description:
#	Returns a table for selecting info to add libraries and plates
#
# Input:
#	Rack_id (Must be a box rack and contain sources)
######################
sub upload_new_collection {
######################
    my %args       = filter_input( \@_, -args => 'dbc,rack_id' );
    my $dbc        = $args{-dbc};
    my $rack_id    = $args{-rack_id};
    my $source     = $args{-source};
    my $slots      = $args{-slots};
    my $ordered_by = $args{-ordered_by};
    my $preset     = $args{-preset};

    my $sources;
    $sources = join ',', @$source if $source;

    #    my $extra = $q->hidden( -name => 'Sources', -value => $sources, -force => 1 );

    my $extra = $q->hidden( -name => 'Reference_Field', -value => 'Source.Source_ID', -force => 1 ) . $q->hidden( -name => 'Reference_IDs', -value => $sources, -force => 1 );

    my $page;

    my @extras = ($extra);

    ## Order of source ids depends if the box is sloted or not
    if ($slots) {
        unshift @extras, "Link by: ";
        $extras[-1] .= $q->radio_group( -name => 'Order', -values => [ 'Row', 'Column' ], -default => $ordered_by, -force => 1 ) . set_validator( -name => 'Order', -mandatory => 1 );
    }
    else {
        unshift @extras, "Link by: ";
        $extras[-1] .= $q->radio_group( -name => 'Order', -values => ["$ordered_by"], -default => $ordered_by, -force => 1 ) . set_validator( -name => 'Order', -mandatory => 1 );

        #$extras[-1] .= $q->hidden( -name => 'Order', -value => $ordered_by, -force => 1 );
    }

    # $extras[-1] .= $q->hidden( -name => 'FK_Rack__ID', -value => $rack_id, -force => 1 );

    #   $extras[-1] .= set_validator(-name=>'Order', -mandatory=>1);

    require SDB::Import_Views;
    my $Import_View = new SDB::Import_Views( -dbc => $dbc );
    $page .= $Import_View->upload_file_box(
        -dbc             => $dbc,
        -cgi_application => 'alDente::Transform_App',
        -button          => $q->submit( -name => 'rm', -value => 'Upload Specimen Template', -force => 1, -class => 'Action', -onClick => 'return validateForm(this.form, 4)' ),
        -extra           => [ \@extras ],
        -ordered         => $ordered_by,                                                                                                                                           ### allow user to specify control rows / columns for order validation
    );

    return $page;
}

######################
# Description:
#	displays rack label, top part of the homepage
#
# Input:
#	Rack_id
#   dbc
######################
sub label {
######################
    my %args      = filter_input( \@_, -args => 'dbc,rack_id' );
    my $dbc       = $args{-dbc};
    my $rack_id   = $args{-rack_id} || $args{-id};
    my %rack_info = Table_retrieve(
        $dbc,
        'Rack,Equipment,Location,Stock,Stock_Catalog,Equipment_Category',
        [ 'Rack_ID', 'Sub_Category as Conditions', 'Equipment_Name as Equip', 'Equipment_ID as Equip_ID', 'Rack_Alias as Alias', 'Rack_Type', 'Rack_Type+0 as TypeNum', 'FKParent_Rack__ID', 'FK_Location__ID', 'Location_Name' ],
        "where FK_Equipment__ID=Equipment_ID AND FK_Location__ID=Location_ID AND Rack_ID IN ($rack_id) AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_Id and Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID"
    );

    my $cond          = $rack_info{Conditions}[0];
    my $alias         = $rack_info{Alias}[0];
    my $type          = $rack_info{Rack_Type}[0];
    my $equip         = $rack_info{Equip}[0];
    my $equip_id      = $rack_info{Equip_ID}[0];
    my $parent_rack   = $rack_info{FKParent_Rack__ID}[0];
    my $location      = $rack_info{FK_Location__ID}[0];
    my $location_name = $rack_info{Location_Name}[0];

    my $rack_link = $dbc->display_value('Rack',$rack_id); ## &Link_To( $dbc->config('homelink'), "<B>$prefix$rack_id</B> ", "&Info=1&Table=Rack&Field=Rack_ID&Like=$rack_id", 'blue', ['newwin'] );
    my $location_link;

    my $prefix = $dbc->barcode_prefix('Rack');
    if ($parent_rack) {
        my ($parent_name) = $dbc->Table_find( 'Rack', 'Rack_Alias', "WHERE Rack_ID = $parent_rack" );
        $location_link = &Link_To( $dbc->config('homelink'), $parent_name, "&cgi_application=alDente::Scanner_App&rm=Scan&Barcode=$prefix" . $parent_rack );
        $location_link = $dbc->display_value('Rack', $parent_rack);
        ## check if this rack is currently in transit ##
    }
    elsif ($equip_id) {
        $location_link = &Link_To( $dbc->config('homelink'), "<B>$equip ($equip_id)</B>: ", "&cgi_application=alDente::Scanner_App&rm=Scan&Barcode=Equ" . $equip_id, 'blue', ['newwin'] );
    }
    else {
        $location_link = '(lab shelf)';
    }
    my %rack_contains = Table_retrieve( $dbc, 'Rack', [ 'count(Rack_ID) as Count_ID', 'Rack_Type' ], "where FKParent_Rack__ID = $rack_id  and Rack_Type <> 'Shipment' group by Rack_Type" );

    my $page .= "$rack_link ($type)  Condition: $cond" . &vspace(3);
    $page    .= '[' . $dbc->barcode_prefix('Rack') . $rack_id . ']' . &vspace(5);
    $page .= "In / On: $location_link " . hspace(5) . '(' . alDente_ref( 'Location', $location, -dbc => $dbc ) . ')';
    $page .= vspace(5);

    my $i        = 0;
    my $has_slot = 0;

    my $contents;
    while ( exists $rack_contains{Count_ID}[$i] ) {
        my $rack_count = $rack_contains{Count_ID}[$i];
        my $rack_type  = $rack_contains{Rack_Type}[$i];
        if ( $rack_type =~ /slot/i ) {
            $has_slot = 1;
        }

        my @racks = $dbc->Table_find( 'Rack', 'Rack_ID', "where FKParent_Rack__ID = $rack_id AND Rack_Type = '$rack_type'" );
        $contents .= list_Racks( -rack_id => \@racks, -title => "$rack_type locations", -dbc => $dbc );
        $i++;
    }

    if   ($contents) { $page .= 'Contains :<P>' . $contents }
    else             { $page .= "$type without defined sub-sections<br/>" }

    $page .= '<HR>';
    return $page;
}

####################
sub object_label {
####################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc} || $self->dbc();
    
    $args{-dbc} = $dbc;
    return label(%args);
}

###########################
sub display_record_page {
###########################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc} || $self->dbc();
    my $rack_id  = $args{-id}  || $self->{id};
    
    my @layers;
    
    my $prefix = $dbc->barcode_prefix('Rack');
    
    my %rack_info = Table_retrieve(
        $dbc,
        'Rack,Equipment,Location,Stock,Stock_Catalog,Equipment_Category',
        [ 'Rack_ID', 'Sub_Category as Conditions', 'Equipment_Name as Equip', 'Equipment_ID as Equip_ID', 'Rack_Alias as Alias', 'Rack_Type', 'Rack_Type+0 as TypeNum', 'FKParent_Rack__ID', 'FK_Location__ID', 'Location_Name' ],
        "where FK_Equipment__ID=Equipment_ID AND FK_Location__ID=Location_ID AND Rack_ID IN ($rack_id) AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_Id and Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID"
    );
    my $has_slot = $dbc->Table_find( "Rack", "Rack_ID", " WHERE FKParent_Rack__ID = $rack_id and Rack_Type = 'Slot'" );

    my $type        = $rack_info{Rack_Type}[0];
    my $parent_rack = $rack_info{FKParent_Rack__ID}[0];

    #####################
    ### Content Layer ###
    #####################
    
    my $contents;
    if ( !$dbc->mobile ) {
        ############## Show rack contents############
        $contents .= alDente::Form::start_alDente_form( $dbc, 'Show_Rack' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 ) . $q->hidden( -name => 'Rack_ID', -value => $rack_id, -force => 1 );
        $contents .= $q->submit(
            -name  => 'rm',
            -value => 'Show Rack Contents',
            -class => "Search",
            -force => 1
        );
        
        $contents .= $q->checkbox(
            -name    => 'Recursive',
            -label   => 'Recursively show contents from child racks',
            -checked => 1
        );
        $contents .= $q->end_form() . '<hr>';
    }

    $contents .= scanned_Racks( -dbc => $dbc, -barcode => $dbc->barcode_prefix('Rack') . $rack_id );
    
    push @layers, { label => 'Contents', content => $contents};
    push @layers, { label => 'Relocation History', content => show_Relocation_History( -dbc => $dbc, -object => 'Rack', -id => $rack_id, -printable=>1) };
    
    unless ($type =~/box/i && $has_slot) {
        my $location_link;
        if ($parent_rack) {
            my ($parent_name) = $dbc->Table_find( 'Rack', 'Rack_Alias', "WHERE Rack_ID = $parent_rack" );
            $location_link = &Link_To( $dbc->config('homelink'), $parent_name, "&cgi_application=alDente::Scanner_App&rm=Scan&Barcode=$prefix" . $parent_rack );
        }
        push @layers, { label =>"Add Sections to $type", content=> add_sub_rack_form( -dbc => $dbc, -rack_info => \%rack_info, -location => $location_link ) } 
    }
    
    return $self->SUPER::display_record_page(
        -right => print_options( -id => $rack_id, -dbc => $dbc ),
        -layers     => \@layers,
        -visibility => { 'Search' => ['desktop'] },
        -label_span => 1,
        -open_layer => 'Contents',
    );
}
##################
sub home_page {
##################
    my %args    = filter_input( \@_, -args => 'dbc,rack_id' );
    my $dbc     = $args{-dbc};
    my $rack_id = $args{-rack_id} || $args{-id};

    my $prefix = $dbc->barcode_prefix('Rack');
    
    $rack_id = get_aldente_id( $dbc, $rack_id, 'Rack' );
    unless ($rack_id) {
        $dbc->session->warning("No valid Rack entered... ");
        return;
    }

    my %rack_info = Table_retrieve(
        $dbc,
        'Rack,Equipment,Location,Stock,Stock_Catalog,Equipment_Category',
        [ 'Rack_ID', 'Sub_Category as Conditions', 'Equipment_Name as Equip', 'Equipment_ID as Equip_ID', 'Rack_Alias as Alias', 'Rack_Type', 'Rack_Type+0 as TypeNum', 'FKParent_Rack__ID', 'FK_Location__ID', 'Location_Name' ],
        "where FK_Equipment__ID=Equipment_ID AND FK_Location__ID=Location_ID AND Rack_ID IN ($rack_id) AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_Id and Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID"
    );
    my $has_slot = $dbc->Table_find( "Rack", "Rack_ID", " WHERE FKParent_Rack__ID = $rack_id and Rack_Type = 'Slot'" );

    my $type        = $rack_info{Rack_Type}[0];
    my $parent_rack = $rack_info{FKParent_Rack__ID}[0];

    my $location_link;
    if ($parent_rack) {
        my ($parent_name) = $dbc->Table_find( 'Rack', 'Rack_Alias', "WHERE Rack_ID = $parent_rack" );
        $location_link = &Link_To( $dbc->config('homelink'), $parent_name, "&cgi_application=alDente::Scanner_App&rm=Scan&Barcode=$prefix" . $parent_rack );
        ## check if this rack is currently in transit ##
    }

    my $show_add = 1;
    if ( $type =~ /box/i && $has_slot ) {
        $show_add = 0;
    }

    my $page = label( -dbc => $dbc, -rack_id => $rack_id );
    if ( !$scanner_mode ) {
        ############## Show rack contents############
        $page .= alDente::Form::start_alDente_form( $dbc, 'Show_Rack' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 ) . $q->hidden( -name => 'Rack_ID', -value => $rack_id, -force => 1 );
        $page .= $q->submit(
            -name  => 'rm',
            -value => 'Show Rack Contents',
            -class => "Search",
            -force => 1
        );
        $page .= $q->checkbox(
            -name    => 'Recursive',
            -label   => 'Recursively show contents from child racks',
            -checked => 1
        );
        $page .= $q->end_form() . '<hr>';
    }

    my $found = scanned_Racks( -dbc => $dbc, -barcode => $prefix . $rack_id );    ## show option available for multiple scanned racks (move contents) ...
    $page .= $found;
    $page .= show_Relocation_History( -dbc => $dbc, -object => 'Rack', -id => $rack_id );
    $page .= '<hr>';
    $page .= alDente::Form::start_alDente_form( $dbc, 'Rack' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 ) . $q->hidden( -name => 'Rack_ID', -value => $rack_id, -force => 1 );

    my ( $transit_racks, $shipment_id ) = alDente::Rack::in_transit( -dbc => $dbc, -rack_id => $rack_id );

    $page .= "\n" . $q->end_form() . "\n";

    if ($transit_racks) { return $page }

    ############# Add racks #############
    if ($show_add) { $page .= add_sub_rack_form( -dbc => $dbc, -rack_info => \%rack_info, -location => $location_link ) . $q->hr }

    ### allow printout of barcodes...
    $page .= print_options( -id => $rack_id, -dbc => $dbc );
    $page .= $q->hr;

    if ( !$scanner_mode ) {
        $page .= alDente::Form::start_alDente_form( $dbc, 'Annotate' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 ) . $q->hidden( -name => 'Rack_ID', -value => $rack_id, -force => 1 );
        $page .= $q->submit(
            -name    => 'rm',
            -value   => 'Annotate Contents',
            -class   => "Search",
            -force   => 1,
            -onClick => 'return validateForm(this.form)',
            -force   => 1
        );
        $page .= $q->textfield( -name => 'Annotation', -size => 20 );
        $page .= set_validator(
            -name      => 'Annotation',
            -mandatory => 1,
            -prompt    => 'You must enter a comment string'
        );

        $page .= $q->end_form();

        if ( $type eq 'Box' ) {
            $page .= '<hr>' . prompt_to_confirm_Contents( -dbc => $dbc, -rack_id => $rack_id );
        }

        ### Source Block
        ### If Rack Contains only sources and is a box we display options to create plates in batch

        my $rack_obj = new alDente::Rack( -dbc => $dbc, -id => $rack_id );
        my $rack_content = $rack_obj->get_box_content( -objects => 1, -quiet => 1, -id => $rack_id );
        my @rack_objects;
        @rack_objects = keys %$rack_content if $rack_content;
        my $object_count = @rack_objects;    ## both object and object_Position returned... so this number is 2 x # of objects

        my ( $order, $message ) = check_order( $dbc, $rack_id, 'Source', -non_slotted_warning => 1 );

        if ( ( grep {/Source/} @rack_objects ) && $type =~ /box/i && $has_slot ) {
            $page .= display_Action_Buttons( -rack_id => $rack_id, -dbc => $dbc );
        }

        if ($message) {
            $page .= '<HR>';
            $page .= $message;
        }
        if ( $rack_objects[0] =~ /Source/ && ( $object_count == 2 ) && !$transit_racks ) {
            ## why go here if Source object found and count = 2 ?..... ### please fix or clarify !
            $page .= '<HR>';
            $page .= vspace();
            $page .= show_Src_to_Tube_option( -rack_id => $rack_id, -dbc => $dbc, -source => $rack_content->{Source}, -ordered_by => $order );
            $page .= '</HR>';
        }
        ###	/Source Block

    }

    return $page;
}

#
#
###########################
sub display_Action_Buttons {
###########################
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $rack_id = $args{-rack_id};
    my $page
        = alDente::Form::start_alDente_form( -dbc => $dbc ) . '<HR>'
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 )
        . $q->hidden( -name => 'Rack_ID',         -value => $rack_id,            -force => 1 )
        . $q->hidden( -name => 'Object',          -value => 'Source',            -force => 1 )

        #   . $q->submit( -name => 'rm', -value => 'Record Bottom Barcode', -class => "Search", -force => 1, -onClick => 'return validateForm(this.form)' )
        #  . hspace(5)
        . $q->submit( -name => 'rm', -value => 'Display Bottom Barcode', -class => "Search", -force => 1, -onClick => 'return validateForm(this.form)' )
        . hspace(5)
        . $q->submit( -name => 'rm', -value => 'Prefill Excel File', -class => "Std", -force => 1, -onClick => 'return validateForm(this.form)' )
        . $q->end_form();

    return $page;
}

###########################
sub download_Content_File {
###########################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $rack_id = $args{-rack_id};
    my $object  = $args{-object};
    my $debug   = $args{-debug};
    my ($primary) = $dbc->get_field_info( $object, undef, 'PRI' );
    my $page;
    my $timestamp = timestamp();

    my @headers = ( 'Row', 'Columns', "$primary" );
    my %results = $dbc->Table_retrieve( "$object,Rack", [ 'UPPER(LEFT(Rack_Name,1)) AS Row', 'RIGHT(Rack_Name,LENGTH(Rack_Name)-1) AS Columns', "$primary" ], " WHERE FK_Rack__ID = Rack_ID AND FKParent_Rack__ID = $rack_id order by Rack_ID" );

    my $Table = new HTML_Table();
    $Table->Set_Headers( \@headers );
    $Table->Set_Column( $results{Row} );
    $Table->Set_Column( $results{Columns} );
    $Table->Set_Column( $results{$primary} );

    $page .= $Table->Printout( "$URL_temp_dir/File" . $timestamp . ".xlsx", $html_header, -xls_settings => { 'show_title' => 1 } );

    return $page;
}

#
###########################
sub display_Prefil_Excel_Page {
###########################
    my $self         = shift;
    my %args         = filter_input( \@_ );
    my $dbc          = $args{-dbc};
    my $rack_id      = $args{-rack_id};
    my $object       = $args{-object};
    my $debug        = $args{-debug};
    my $default      = '--- Select Template ---';
    my $fill_default = 1;
    my $page;

    require alDente::Template;
    require alDente::Template_Views;
    my $Template = new alDente::Template( -dbc => $dbc );
    my $Template_View = new alDente::Template_Views( -dbc => $dbc, -Template => $Template );

    my ( $core_templates, $core_labels ) = $Template->get_Template_list( -dbc => $dbc, -debug => $debug );
    my ( $custom_templates, $custom_labels ) = $Template->get_Template_list( -dbc => $dbc, -custom => 1, -debug => $debug );
    unshift @$core_templates,   $default;
    unshift @$custom_templates, $default;

    my $download = RGTools::Web_Form::Submit_Button( form => 'Download_Excel', name => 'rm', value => 'Download Excel File', class => 'Std', onClick => 'return validateForm(this.form); ', force => 1, newwin => 'download_excel' ) . hspace(5);
    my $other
        = $q->hidden( -name => 'cgi_application', -value => 'alDente::Template_App', -force => 1 )
        . set_validator( -name => 'template_file', -mandatory => 1 )
        . $q->hidden( -name => 'rack_id', -value => $rack_id, -force => 1 )
        . $q->hidden( -name => 'object',  -value => $object,  -force => 1 )
        . "Location Tracking: "
        . $q->radio_group( -name => 'Location_Track', -values => [ 'None', 'Row_Column', 'Well' ], -default => 'None', -force => 1 );

    my $core_block
        = alDente::Form::start_alDente_form( $dbc, 'uploader' )
        . String::format_Text( -text => "Core System Templates:  ", -color => 'green', -bold => 1, -size => 3 )
        . vspace()
        . $q->popup_menu( -name => 'template_file', -values => $core_templates, -labels => $core_labels, -default => $default, -force => 1 )
        . vspace()
        . $download
        . $other
        . $q->end_form();

    my $group_block
        = alDente::Form::start_alDente_form( $dbc, 'uploader' )
        . String::format_Text( -text => "User Customized Templates:  ", -color => 'green', -bold => 1, -size => 3 )
        . vspace()
        . $q->popup_menu( -name => 'template_file', -values => $custom_templates, -labels => $custom_labels, -default => $default, -force => 1 )
        . vspace()
        . $download
        . $other
        . $q->end_form();

    my $simple_block = String::format_Text( -text => "Simple Location and ID:  ", -color => 'green', -bold => 1, -size => 3 ) . vspace() . $self->download_Content_File( -rack_id => $rack_id, -dbc => $dbc, -object => $object ) . vspace();

    return $simple_block . $q->hr . $core_block . $q->hr . $group_block;

}

#
# Generate section prompting user to add subracks to given rack or equipment
#
###########################
sub add_sub_rack_form {
###########################
    my %args          = filter_input( \@_, -args => 'dbc,rack_info,location' );
    my $dbc           = $args{-dbc};
    my $rack_info     = $args{-rack_info};
    my $location_link = $args{-location};

    my $rack_id     = $rack_info->{Rack_ID}[0];
    my $type        = $rack_info->{Rack_Type}[0];
    my $type_number = $rack_info->{TypeNum}[0];
    my $equip_id    = $rack_info->{Equip_ID}[0];

    my $page = alDente::Form::start_alDente_form( $dbc, 'Add' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 ) . $q->hidden( -name => 'Rack_ID', -value => $rack_id, -force => 1 );

    my $rack_equipment_categories = "'Freezer','Storage'";    ## The categories of equipment which are concidered long term storages for racks

    my @conditions = $dbc->Table_find( 'Equipment_Category', 'Sub_Category', "WHERE Category IN ($rack_equipment_categories)" );
    my ($def_cond) = $dbc->Table_find( 'Rack,Equipment,Stock,Stock_Catalog,Equipment_Category',
        'Sub_Category', "where Rack_ID = $rack_id AND Equipment_ID=FK_Equipment__ID AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_Id and Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID LIMIT 1" );

    my @types = get_enum_list( $dbc, 'Rack', 'Rack_Type' );

    foreach my $skip_type ( 1 .. $type_number ) {
        shift @types;                                         ## do not allow racks of larger scope than current rack ##
    }
    unless ( $type =~ /box/i ) {
        pop @types;                                           ## remove slot option except for boxes ...
    }

    my $def_type = $types[0] || 'Shelf';
    $page .= $q->hidden( -name => 'FK_Equipment__ID',  -value => $equip_id, -force => 1 );
    $page .= $q->hidden( -name => 'FKParent_Rack__ID', -value => $rack_id,  -force => 1 );

    my $label_field;

    $label_field = Show_Tool_Tip( $q->textfield( -name => 'Rack_Prefix', -size => 10, -default => '', -class => 'narrow-txt' ), 'Optional - defaults to R (Rack) or B (Box)' );

    my $num_field;

    my $slot;

    my $count_field = $q->textfield( -name => 'New Racks', -size => 5, -default => 1, -class => 'narrow-txt' );

    my @content;
    if ( int(@types) ) {
        $page .= subsection_heading("Adding New Racks WITHIN Rack $rack_id");

        $content[0] = [ $q->submit( -name => 'rm', -value => 'Add', -class => "Action", -onclick => "return validateForm(this.form)" ) ];

        if ( @types == 1 && $types[-1] eq 'Slot' ) {
            ## Special case when existing type is one level above a 'slot' (eg a slotted Box) ##

            ## Defined Slotted Box Types ##
            my @Box_Types = ( { 'label' => "9x9 [a1..i9]", 'max_row' => 'i', 'max_col' => '9' }, { 'label' => "8x12 [a1..h12]", 'max_row' => 'h', 'max_col' => '12' }, { 'label' => "custom [a1..N]", 'max_row' => '', 'max_col' => '' }, );

            ## create slot prompt (which can be turned on and off depending upon context ##

            $slot
                = "<div id='slotfields'>"
                . "Max Row: "
                . Show_Tool_Tip( $q->textfield( -name => "Max_Rack_Row", -size => 2, -default => '', -class => 'narrow-txt' ), 'Indicate number of Racks/Boxes to add' )
                . hspace(1)
                . "Max Col: "
                . $q->textfield( -name => "Max_Rack_Col", -size => 2, -default => '', -class => 'narrow-txt' )
                . "</div>";

            my $type_specification = $q->hidden( -name => 'Rack_Type', -value => $types[-1], -force => 1 )
                . $q->radio_group( -name => 'New Type', -value => "single Slot", -checked => 0, -onclick => "unHideElement('numfields'); HideElement('slotfields'); SetSelection(this.form, 'Max_Rack_Row','a'); SetSelection(this.form,'Max_Rack_Col','1');" );

            ## Generate radio button for each box type - dynamically activate slot element above and preset applicable max row / column values ##
            foreach my $type (@Box_Types) {
                my $a = $type->{max_row};
                my $b = $type->{max_col};
                $type_specification
                    .= $q->radio_group( -name => 'New Type', -value => $type->{label}, -onclick => "HideElement('numfields'); unHideElement('slotfields'); SetSelection(this.form,'Max_Rack_Row','$a'); SetSelection(this.form,'Max_Rack_Col','$b');" );
            }
            $content[1] = [ 'Type: ', $type_specification ];

            ## ensure that the row and column elements are supplied if generating multiple slots ##
            $page .= set_validator( -name => 'Max_Rack_Row', -mandatory => 1 );
            $page .= set_validator( -name => 'Max_Rack_Col', -mandatory => 1 );

            my $num_prompt = _num_prompt( -style => "display:none", -append => "Prefix: $label_field #: " );

            # $content[2] = ['Prefix: ', $label_field];
            $content[3] = [ 'Slots: ', $num_prompt . $slot ];

        }
        else {
            push @{ $content[0] }, Show_Tool_Tip( $q->textfield( -name => 'New Racks', -size => 5, -default => 1, -class => 'narrow-txt' ), 'Indicate number of records to add' );
            my $type_specification;
            foreach my $type (@types) {
                $type_specification .= $q->radio_group( -name => 'Rack_Type', -value => $type, -default => $types[0] ) . ' ';
            }
            $content[1] = [ 'Type: ',      $type_specification ];
            $content[2] = [ 'Prefix: ',    $label_field ];
            $content[3] = [ "Starting #:", _num_prompt() ];

        }

        $page .= Views::Table_Print( content => \@content, print => 0, -column_style => { 1 => 'text-align:right' } );
        $page .= set_validator( -name => 'Rack_Type', -mandatory => 1 );
        $page .= $q->hidden( -name => 'Conditions', -value => $def_cond ) . &vspace(20);
    }
    else {
        Message("(No location unit more specific than '$type')");
    }

    $page .= $q->end_form();
    return $page;
}

#################
sub _num_prompt {
#################
    my %args   = @_;
    my $style  = $args{-style};
    my $append = $args{-append};

    my $prompt
        = "<div id='numfields' style='$style'>" 
        . $append
        . Show_Tool_Tip( $q->textfield( -name => 'Starting Number', -size => 4, -default => '', -class => 'narrow-txt' ), 'Optional - defaults to next available number' )
        . "<br><span class=small>Label/Number combinations must be unique for a given parent-rack"
        . "<br>Label defaults to 'B','R',or 'S' for a Box, Rack, or Shelf"
        . "<br>Number defaults to lowest unused number if left blank</span></div>";

    return $prompt;
}

########################################
sub add_shipping_container_form {
########################################
    my %args         = filter_input( \@_, -args => 'dbc,equipment_id' );
    my $dbc          = $args{-dbc};
    my $equipment_id = $args{-equipment_id};                               # dbc->get_local('site_id');

    my $page;
    $page
        .= alDente::Form::start_alDente_form( $dbc, 'Add' )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 )
        . $q->hidden( -name => 'FK_Equipment__ID', -value => $equipment_id, -force => 1 )
        . $q->hidden( -name => 'Shipping Container', -value => 1 );

    my @types = get_enum_list( $dbc, 'Rack', 'Rack_Type' );

    unshift @types, '';                                                    ## no slots ...
    unshift @types, '';                                                    ## no boxes

    my $label_field = " Label:" . $q->textfield( -name => 'Rack_Prefix', -size => 10, -default => '' );

    my $count_field = $q->textfield( -name => 'New Racks', -size => 5, -default => 1 );

    $page .= $q->submit(
        -name    => 'rm',
        -value   => 'Add',
        -class   => "Action",
        -onClick => 'return validateForm(this.form)'
        )
        . " "
        . $count_field
        . " New Shipping Containers";

    $page .= '<p ></p>Type: '
        . Show_Tool_Tip(
        $q->radio_group(
            -name    => 'Rack_Type',
            -value   => 'Shelf',
            -labels  => { 'Shelf' => 'Outer' },
            -checked => 0,
            -force   => 1
        ),
        "Outer Container may NOT be place in another Container, but they MAY contain Inner Containers"
        )
        . Show_Tool_Tip(
        $q->radio_group(
            -name    => 'Rack_Type',
            -value   => 'Rack',
            -labels  => { 'Rack' => 'Inner' },
            -checked => 0,
            -force   => 1
        ),
        "Inner Containers MAY be placed in an outer Container, but may NOT contain other Containers"
        )
        . '<P>'
        . $label_field
        . set_validator(
        -name      => 'Rack_Prefix',
        -mandatory => 1,
        -prompt    => 'You must enter a name'
        )
        . set_validator(
        -name     => 'Rack_Type',
        -mandtory => 1,
        -prompt   => 'Choose whether container is an Inner or Outer Container'
        ) . &vspace(20);

    $page .= $q->end_form();
    return $page;
}

###########################
sub receive_shipment {
###########################
    my %args        = filter_input( \@_, -args => 'dbc,shipment_id' );
    my $dbc         = $args{-dbc};
    my $rack_id     = $args{-rack_id};
    my $shipment_id = $args{-shipment_id};

    ## this rack is a transporter box and is currently in transit ##
    my $page = alDente::Form::start_alDente_form( $dbc, 'Receive_shipment' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Shipment_App', -force => 1 ) . $q->hidden( -name => 'Rack_ID', -value => $rack_id, -force => 1 );

    $page .= 'Receive and Move Contents to: ' . Show_Tool_Tip( $q->textfield( -name => 'Target_Rack_ID', -size => 20 ), 'Scan in the target BOX location here' );
    $page .= $q->submit(
        -name    => 'rm',
        -value   => 'Receive Shipment',
        -class   => 'Action',
        -force   => 1,
        -onClick => 'return validateForm(this.form)'
    );
    $page .= $q->hidden( -name => 'Shipment_ID', -value => $shipment_id );

    if ( my $site_id = $dbc->session->{site_id} ) {
        $page .= $q->hidden( -name => 'FK_Site__ID', -value => $site_id, -force => 1 );
        $page .= ' Received at ' . alDente_ref( 'Site', $site_id, -dbc => $dbc );
    }
    else { $page .= ' at: ' . alDente::Tools::search_list( -dbc => $dbc, -name => 'FK_Site__ID' ) }
    $page .= set_validator( -name => 'FK_Site__ID',    -mandatory => 1 );
    $page .= set_validator( -name => 'Target_Rack_ID', -mandatory => 1 );
    $page .= $q->end_form();

    #    $page .= ' to: ';
    #
    #    my @target_list = $dbc->Table_find('Equipment,Location,Site','Equipment_ID',"WHERE FK_Location__ID=Location_ID AND FK_Site__ID=Site_ID AND Site_Name NOT LIKE 'External' AND Equipment_Name like 'Site-%'", -distinct=>1);
    #    $page .= $q->popup_menu(-name=>'
    #    $page .= alDente::Tools::search_list(-dbc=>$dbc,-form=>$form,-name=>'FK_Rack__ID',
    #					 -condition=>"Rack_Alias=Rack_Name AND FKParent_Rack__ID=0 AND Rack_Name NOT IN ('Garbage','In Transit','In Use','Exported')",
    #					 -filter=>1,-search=>1);
    #
    #    $page .= set_validator(-name=>'FK_Rack__ID', -mandatory=>1, -prompt=>'You must indicate the target site');

    $page .= '<HR>';
    $page .= alDente::Form::start_alDente_form( $dbc, 'Receive_Shipment' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 ) . $q->hidden( -name => 'Rack_ID', -value => $rack_id, -force => 1 );

    $page .= reprint_Button( $dbc, $rack_id );
    $page .= $q->end_form();
    return $page;
}

##################
sub list_Racks {
##################
    my %args  = filter_input( \@_, -args => 'rack_id,title' );
    my $racks = $args{-rack_id};
    my $title = $args{-title} || 'Storage Locations';
    my $dbc   = $args{-dbc};

    my $page;
    if ( int(@$racks) ) {
        my $num = int(@$racks);
        my $direct;
        foreach my $rack (@$racks) {
            $direct .= alDente_ref( 'Rack', $rack, -dbc => $dbc ) . vspace();
        }
        $page .= create_tree( -tree => { "$num $title" => $direct } );
    }
    return $page;
}

########################################################
# Display the contents of a rack
#
# Return: HTML Table Printout of the contents of the rack
#############################
sub show_Contents {
#############################
    my %args = filter_input( \@_, -args => 'rack_id,rack_contents,level' );
    my $dbc           = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $rack_id       = $args{-rack_id};                                                                 ## Rack
    my $rack_contents = $args{-rack_contents};                                                           ## OPTIONAL hash ref containing items in the rack
    my $level         = $args{-level};                                                                   ## check for the first level of items in the rack
    my $title         = $args{-title} || $dbc->get_FK_info( 'FK_Rack__ID', $rack_id );
    my $no_tree       = $args{-no_tree};                                                                 ## OPTIONALLY disable create tree grouping
    my $printable     = $args{-printable};                                                               ## do not add printable page
    my $item_count    = $args{-item_count} || 1;
    my $recursive     = $args{-recursive};                                                               ## Recursively search the contents of the rack
    my $show_barcodes = $args{-show_barcodes};                                                           ## display barcodes beside Racks / Boxes if requested.

    my %rack_contents = ();
    
    my @objects       = alDente::Rack::get_stored_material_types( undef, -dbc => $dbc, -include_self => 1 );
    my %prefix        = alDente::Rack::reverse_Prefix($dbc, \@objects );

    my $barcode;

    my $running_total = $args{-running_total};
    %rack_contents = %{$rack_contents} if defined $rack_contents;

    my $rack_table = HTML_Table->new();
    $rack_table->Set_Border(1);
    $rack_table->toggle();
    $rack_table->Toggle_Colour('off');
    $rack_table->Set_Class('small');

    my %Primary;
    foreach my $key ( keys %prefix ) {
        my $table = $prefix{$key};
        my ($primary) = $dbc->get_field_info( $table, undef, 'PRI' );
        $Primary{$key} = $primary;
    }

    unless ($rack_contents) {
        alDente::Rack::get_rack_contents(
            -rack_id       => $rack_id,
            -rack_contents => \%rack_contents,
            -recursive     => $recursive,
            -dbc           => $dbc
        );
    }
    my ($rack_type) = $dbc->Table_find( 'Rack', 'Rack_Type', "WHERE Rack_ID = $rack_id" );

    if ( $show_barcodes =~ /$rack_type/i ) {
        $barcode = rack_barcode_img( $dbc, $rack_id, -link => 1 );
    }
    
    my $prefix = $dbc->barcode_prefix('Rack');
    if ( $rack_contents{"$prefix$rack_id"} ) {
        my @contents = split ',', $rack_contents{"$prefix$rack_id"};
        my $rt = 0;
        if ($item_count) {

            #$rt = $$running_total +  scalar(@contents);
            $title .= " [" . scalar(@contents) . "]";

        }

        my %contents;
        foreach my $content ( sort @contents ) {
            if ( $rack_contents{$content} ) {
                my $content_block = show_Contents(
                    -rack_id       => get_aldente_id( $dbc, $content, 'Rack' ),
                    -rack_contents => \%rack_contents,
                    -no_tree       => $no_tree,
                    -recursive     => $recursive,
                    -show_barcodes => $show_barcodes
                );
                $rack_table->Set_Row( [$content_block] );
            }
            else {

                #	my $content_link =
                $content =~ /(\w{3})\d+/i;

                push( @{ $contents{$1} }, $content );

                #$rack_table->Set_Row([$content]);
            }
        }

        my @sort_contents = keys %contents;
        @sort_contents = sort @sort_contents;

        foreach my $key (@sort_contents) {
            my @links;
            my %slots;
            foreach my $cont ( @{ $contents{$key} } ) {

                $cont =~ /(\w{3})(\d+)/i;
                my $pre = $1;
                my $id  = $2;

                my $primary = $Primary{$pre};
                my $table   = $prefix{$pre};

                # my ($primary) = $dbc->get_field_info( $table, undef, 'PRI' );
                my $link = alDente_ref( $table, $id, -dbc => $dbc );

                if ( $rack_type eq 'Box' ) {
                    ## show slot location ...

                    my ($slot) = $dbc->Table_find( "$table,Rack", 'Rack_Name', "WHERE FK_Rack__ID=Rack_ID AND ${table}_ID = $id" );    ## <CONSTRUCTION>... should be able to make this faster by retrieving earlier with other query.
                    $link .= " ($slot)";

                    $slots{$link} = $slot;
                }
                elsif ( $show_barcodes && $primary =~ /Rac/i ) {
                    my ($thistype) = $dbc->Table_find( "Rack", 'Rack_Type', "WHERE Rack_ID = $id" );
                    if ( $show_barcodes =~ /\b$thistype\b/i ) {
                        $link = rack_barcode_img( $dbc, $id, -link => 1 );
                    }                                                                                                                  ## add barcode label
                }

                push( @links, $link );
            }
            my @sorted_contents;

            if (%slots) {
                @sorted_contents = reverse sort { alDente::Rack::compare_Well( $slots{$a}, $slots{$b} ) || $b cmp $a } keys %slots;
            }
            else {
                @sorted_contents = @links;
            }

            my $count = int(@sorted_contents);

            if ($no_tree) {
                my @display_contents = map { "<LI>" . $_ . "</LI>" } @sorted_contents;
                my $display_contents = join '', @display_contents;
                $rack_table->Set_sub_header("$prefix{$key}(s)");
                $rack_table->Set_Row( [$display_contents] );
            }
            elsif ( $prefix{$key} ) {
                my $type = $prefix{$key};
                my $open = 0;
                if ( $type eq 'Rack' ) {
                    ($type) = $dbc->Table_find( 'Rack', 'Rack_Type', "WHERE Rack_ID = $rack_id" );
                    $type = "$type Sub-Storage Location";
                    $open = 1;
                }
                $rack_table->Set_Row(
                    [   create_tree(
                            -tree         => { "$type(s) [$count]" => \@sorted_contents },
                            -print        => 0,
                            -default_open => ["$type(s)"]
                        )
                    ]
                );
            }
            else {
                $rack_table->Set_Row(
                    [   create_tree(
                            -tree  => { "Item(s) [$count]" => \@sorted_contents },
                            -print => 0
                        )
                    ]
                );
            }
        }
    }
    else {

        $rack_table->Set_Row( ["No items"] );

    }
    $rack_table->Set_Title("$title");

    my $page;

    if ($barcode) {
        $rack_table->Set_Column( [$barcode] );
    }    ## Add barcode as an extra column on the right ...

    if ( $level == 1 && $printable ) {
        $page = $rack_table->Printout( "$alDente::SDB_Defaults::URL_temp_dir/Rack_Contents_@{[timestamp()]}.html", "$java_header\n$html_header" ) . $rack_table->Printout(0);
    }
    else {
        $page = $rack_table->Printout(0);
    }

    return $page;

}

#####################
sub rack_prompt {
#####################

    my %args = @_;
    my $dbc  = $args{-dbc};

    if ($scanner_mode) { $args{-filter} = 0; $args{-search} = 0; $args{-mode} = 'text'; }
    else               { $args{-filter} = 1; $args{-search} = 1; }

    return alDente::Tools::search_list(%args);
}

############################
# From Rack_home
############################
sub display_home_page {
############################

    my %args = &filter_input( \@_ );

    return home_page(%args);
}

#
# From Rack::Move_Racks
#
##################
sub move_Rack {
##################
    my %args         = filter_input( \@_ );
    my $dbc          = $args{-dbc};
    my $equip        = $args{-equip};
    my $source_racks = $args{-source_racks};
    my $target_rack  = $args{-target_rack};

    my $table = HTML_Table->new();
    $table->Set_Width('60%');
    $table->Set_Headers( [ 'Rack', 'From', 'To' ] );
    my @Valid_Racks;

    my ($in_transit) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_ID IN ($source_racks) AND Rack_Alias like '%In Transit%'" );
    if ($in_transit) {
        ## intercept movements involving 'In Transit' boxes ##
        $dbc->warning("Requires receipt of shipment prior to storage");
        return '<hr>' . home_page( -dbc => $dbc, -id => $in_transit );
    }

    my $page = '<h2>Confirm Storage Relocation</h2>';

    $page .= alDente::Form::start_alDente_form( $dbc, 'relocate Racks' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 ) . $q->hidden( -name => 'Move Storage Location', -value => 1 ) . &vspace();

    if ($equip) {
        my %source_info = $dbc->Table_retrieve(
            'Rack LEFT JOIN Equipment ON FK_Equipment__ID = Equipment_ID',
            [ 'Rack_ID', 'Equipment_ID', 'Rack_Alias', 'Rack_Type', 'Movable', "CONCAT(Equipment_Name,' (EQU:',Equipment_ID,')') AS Equip_Info" ],
            "WHERE Rack_ID in ($source_racks)"
        );

        $page .= $q->hidden( -name => 'Target_Equipment', -value => $equip );
        my @requested;
        @requested = @{ $source_info{Rack_Type} } if ( $source_info{Rack_Type} );

        ### Get their names
        my $avail = alDente::Rack::_get_available_names( -dbc => $dbc, -equ_id => $equip, -list => \@requested );
        unless ($avail) {
            return 0;
        }

        my $i = -1;
        while ( defined $source_info{Rack_ID}[ ++$i ] ) {
            my $s_rack_id = $source_info{Rack_ID}[$i];
            my $s_type    = $source_info{Rack_Type}[$i];
            my $s_alias   = $source_info{Rack_Alias}[$i];
            my $s_movable = $source_info{Movable}[$i];
            if ( $s_movable eq 'N' ) {
                Message("Error: Rack $s_alias is not movable.");
                next;
            }
            elsif ( alDente::Rack::in_transit( -dbc => $dbc, -rack_id => $s_rack_id ) ) {
                Message("Error: Rack $s_rack_id is in transit and has to be imported before moving.");
                next;
            }
            else {
                push( @Valid_Racks, $s_rack_id );
            }

            my $new_rack_name = shift( @{ $avail->{$s_type} } );

            my $Sequip = $source_info{Equipment_ID}[$i];
            my $old_info = alDente_ref( 'Equipment', $Sequip, -dbc => $dbc );    ## b( "Equ" . $source_info{Equipment_ID}[$i] ) . lbr . $source_info{Equip_Info}[$i];

            my ($source_equip_info) = $dbc->Table_find_array(
                'Equipment,Stock,Stock_Catalog,Equipment_Category,Location',
                ["Concat('(',Sub_Category,') ',Location_Name)"],
                "where FK_Location__ID=Location_ID AND Equipment_ID=$Sequip AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_Id and Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID"
            );
            $old_info .= lbr . $source_equip_info;

            my $new_name = $q->textfield(
                -name  => "New_Rack_Name:$s_rack_id",
                -value => "$new_rack_name",
                -size  => '8',
                -force => 1
            );
            my ($target_equip_info) = $dbc->Table_find_array(
                'Equipment,Stock,Stock_Catalog,Equipment_Category,Location',
                ["Concat('(',Sub_Category,') ',Location_Name)"],
                "where FK_Location__ID=Location_ID AND Equipment_ID=$equip AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_Id and Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID"
            );

            my $new_info = alDente_ref( 'Equipment', $equip, -dbc => $dbc );    ## b("Equ$equip") . lbr . $target_equip_info;
            $new_info .= lbr . $target_equip_info;

            if ( alDente::Rack::static_rack( $dbc, $s_rack_id ) ) {
                $new_info .= lbr . "Label: $new_name";
            }

            $table->Set_Row( [ $s_alias, $old_info, $new_info ] );
        }

    }
    else {
        my %source_info = $dbc->Table_retrieve(
            'Rack,Equipment LEFT JOIN Rack AS PRack ON Rack.FKParent_Rack__ID = PRack.Rack_ID',
            [ 'Rack.Rack_ID', 'Rack.Rack_Name', 'Rack.Rack_Type', 'PRack.Rack_Alias AS Parent_Rack_Alias', 'Rack.Rack_Alias', 'Rack.Movable' ],
            "WHERE Rack.Rack_ID IN ($source_racks) AND Rack.FK_Equipment__ID=Equipment_ID ORDER BY Rack.Rack_ID"
        );

        $page .= $q->hidden( -name => 'Target_Rack', -value => $target_rack );
        my @requested;
        @requested = @{ $source_info{Rack_Type} } if ( $source_info{Rack_Type} );

        ### Get their names
        my $avail = alDente::Rack::_get_available_names(
            -dbc     => $dbc,
            -rack_id => $target_rack,
            -list    => \@requested
        );

        unless ($avail) {
            return 0;
        }

        my $i = -1;
        while ( defined $source_info{Rack_ID}[ ++$i ] ) {
            my $s_rack_id = $source_info{Rack_ID}[$i];
            my $s_type    = $source_info{Rack_Type}[$i];
            my $s_alias   = $source_info{Rack_Alias}[$i];
            my $s_name    = $source_info{Rack_Name}[$i];
            my $s_movable = $source_info{Movable}[$i];

            if ( $s_movable eq 'N' ) {
                Message("Error: Rack $s_alias is not movable.");
                next;
            }
            elsif ( alDente::Rack::in_transit( -dbc => $dbc, -rack_id => $s_rack_id ) ) {
                Message("Error: Rack $s_rack_id is in transit and has to be imported before moving.");
                next;
            }
            else {
                push( @Valid_Racks, $s_rack_id );
            }

            my $old_info = $source_info{Parent_Rack_Alias}[$i];

            my $t_alias = alDente_ref( 'Rack', $target_rack, -dbc => $dbc );
            my $new_info = $t_alias;    ## b("$prefix$target_rack") . lbr .

            my $new_rack_name = shift( @{ $avail->{$s_type} } );
            $new_info .= lbr . "Name: ";
            if ( $s_alias eq $s_name ) {
                ## leave names on statically named racks ##
                $new_rack_name = $s_alias;
                $new_info .= $new_rack_name;    ## leave simply as text (no option to change)
            }
            else {
                $new_info .= $q->textfield(
                    -name  => "New_Rack_Name:$s_rack_id",
                    -value => "$new_rack_name",
                    -size  => '8',
                    -force => 1
                );
            }

            $table->Set_Row( [ $s_alias, $old_info, $new_info ] );
        }
    }

    if (@Valid_Racks) {
        $page .= $table->Printout(0);
        my $racks = join ',', @Valid_Racks;
        $page .= $q->hidden( -name => 'Source_Racks', -value => $racks );
        $page .= Show_Tool_Tip( $q->checkbox( -name => 'Suppress Barcodes', -checked => 0 ), 'will not auto-generate barcodes automatically with upload (if applicable)' ) . vspace();
        $page .= $q->submit(
            -name  => 'rm',
            -value => 'Confirm Storage Relocation',
            -class => 'Action'
        );
    }

    $page .= $q->end_form();
    return $page;
}

######################
sub list_Contents {
######################
    my %args       = filter_input( \@_, -args => 'dbc,racks' );
    my $dbc        = $args{-dbc};
    my $racks      = $args{-racks};
    my $type       = $args{-type};
    my $no_actions = $args{-no_actions};

    my $prefix = $dbc->barcode_prefix('Rack');

    my $page;
    foreach my $rack ( split ',', $racks ) {
        $page .= alDente_ref( 'Rack', $rack, -dbc => $dbc );
        $page .= '<HR>';
    }

    $page .= alDente::Form::start_alDente_form( $dbc, 'relocate' );
    $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 );
    $page .= $q->end_form();

    my $slot_racks = join ',', $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FKParent_Rack__ID IN ($racks) AND Rack_Type = 'Slot'" );

    my $rack_list = $racks;
    if ($slot_racks) { $rack_list = "$racks,$slot_racks" }

    my ( $links, $details, $refs ) = $dbc->get_references( 'Rack', { 'Rack_ID' => $rack_list }, -type => $type );    ## third element is the hash of references

    my @classes;
    my @temp_classes;
    my ($internal) = $dbc->Table_find('Grp',"Where Grp_Name like '%Internal'");
    
    if ($refs) {
        @temp_classes = keys %$refs;
        foreach my $class (@temp_classes) {
            if ( $class !~ /Shipment\./ && $class !~ /Rack\./ ) { push @classes, $class }
        }

        foreach my $class (@classes) {
            my @fields    = $class . '_ID';
            my $rack_list = $racks;
            if ($slot_racks) { $rack_list .= ",$slot_racks" }

            my $condition = "WHERE $class IN ($rack_list)";
            $condition .= " ORDER BY $class";

            $class =~ s/\..*//;    ## strip .FK_Rack__ID reference ...

            my $edit_link = Link_To( $dbc->config('homelink'), 'Edit these records', "&TableName=$class&Search+Matching+Records=1&EDIT+FIELD+FK_Rack__ID=$rack_list&SEARCH+FIELD+FK_Rack__ID=$rack_list" );
            my $view_link;

            if ( $class =~ /(Plate)|(Source)/ ) {
                $view_link = &Link_To(
                    $dbc->homelink(),
                    "View: Rack Contents - $class",
                    "&cgi_application=alDente::View_App&rm=Display&File=" . $dbc->config('dynamic_web_dir') . '/views/' . $dbc->config('dbase') . "/Group/$internal/general/Rack Contents - $class.yml&Rack_ID=$rack_list&Generate+Results=1"
                );
            }
            my ($count) = $dbc->Table_find( $class, 'count(*)', $condition );
            my $list = $dbc->Table_retrieve_display( $class, ['*'], $condition, -return_html => 1, -limit => $MAX_ROWS_TO_DISPLAY );

            my $title = $class . ' Records';

            #if ( $list =~ /(\d+) Records/ ) { $title = "$1 $class Records" }
            if ( $count > 0 ) {
                $title = "$count $class Records";
                if ( $count > $MAX_ROWS_TO_DISPLAY ) {
                    $title .= " (Only displaying $MAX_ROWS_TO_DISPLAY records here)";
                }
            }

            $page .= create_tree( -tree => { $title => $edit_link . lbr() . $view_link . $list } );
        }

    }

    my $empty;
    if ( int(@classes) > 1 ) { @classes = ( '', @classes ) }
    elsif ( int(@classes) == 0 ) {

        $page .= "...nothing in/on Rack(s): $racks" . '<P>';
        $page .= _delete_prompt( $dbc, $racks );
        $empty = 1;

        # return $page;
    }    ## nothing on Rack(s)sthore

    my $in_transit_count = 0;
    foreach my $rack ( split ',', $racks ) {
        my ( $in_transit, $shipment_id ) = alDente::Rack::in_transit( $dbc, $racks );
        if ($in_transit) {
            my ($shipment_type) = $dbc->Table_find( 'Shipment', 'Shipment_Type', "WHERE Shipment_ID = $shipment_id" );
            if ( $shipment_type =~ /roundtrip/i ) {

                require alDente::Shipment;
                require alDente::Shipment_Views;

                my $Shipment = new alDente::Shipment( -dbc => $dbc, -id => $shipment_id );
                my $Shipment_View = new alDente::Shipment_Views( -model => { 'Shipment' => $Shipment } );

                #                $page .= $Shipment_View->roundtrip_Shipment( -id => $shipment_id, -dbc => $dbc, -Shipment => $Shipment );
            }
            else {
                $page .= receive_shipment( -dbc => $dbc, -rack_id => $rack, -shipment_id => $shipment_id );
            }
            $in_transit_count++;
        }
    }

    if ($in_transit_count) { return $page }
    elsif ( !$empty && !$no_actions ) {
        $page .= move_contents( $dbc, $racks, \@classes );

        my $contents = alDente::Rack::get_rack_contents( -dbc => $dbc, -rack_id => "$racks" );
        my $ids = $contents->{"$prefix$racks"};

        # get plate ids
        # We may need to make it generic for items other than plates
        my $plate = $dbc->barcode_prefix('Plate'); ## Prefix{'Plate'};
        $ids =~ s/$plate//g;

        if ( $ids !~ /[a-zA-Z]/ ) {

            #Throw out rack contents
            $page .= alDente::Form::start_alDente_form( $dbc, 'Throw_Out' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Container_App', -force => 1 ) . $q->hidden( -name => 'Plate IDs', -value => $ids, -force => 1 );
            $page .= $q->submit( -name => 'rm', -value => 'Throw Out Plates', -class => 'Action' );
            $page .= '<hr>';
            $page .= "\n" . $q->end_form() . "\n";

            #Fail rack contents
            my $groups   = $dbc->get_local('group_list');
            my $reasons  = alDente::Fail::get_reasons( -dbc => $dbc, -object => 'Plate', -grps => $groups );
            my $checkbox = 'Confirm_Fail';

            $page .= alDente::Form::start_alDente_form( $dbc, 'Fail' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Container_App', -force => 1 ) . $q->hidden( -name => 'Plate IDs', -value => $ids, -force => 1 );

            $page .= 'Fail Reason: ';
            $page .= $q->popup_menu(
                -name   => 'FK_FailReason__ID',
                -values => [ sort keys %{$reasons} ],
                -labels => $reasons,
                -force  => 1
            );

            $page .= hspace(4);
            $page .= ' Notes: ';
            $page .= $q->textfield( -name => 'Mark Note', -size => 20, -id => 'Mark Note' );
            $page .= set_validator( -name => 'FK_FailReason__ID', -mandatory => 1 );
            $page .= lbr $page .= $q->checkbox( -name => 'Throw_out', -label => 'Fail & throw out' );
            $page .= $q->submit( -name => 'rm', -value => 'Fail Plates', -class => 'Action' );
            $page .= '<hr>';
            $page .= "\n" . $q->end_form() . "\n";
        }
    }

    return $page;
}

####################
sub _delete_prompt {
####################
    my $dbc   = shift;
    my $racks = shift;

    my $prompt
        = alDente::Form::start_alDente_form($dbc)
        . Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'Delete Rack', -force => 1, -class => 'Action' ), "Will cascade delete contained racks/boxes/slots, but will abort if anything is contained on any underlying storage location" )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 )
        . $q->hidden( -name => 'Rack_ID', -value => $racks, -force => 1 )
        . $q->end_form();

    return $prompt;

}

######################
sub move_contents {
######################
    my %args      = filter_input( \@_, -args => 'dbc,racks,class_ref' );
    my $dbc       = $args{-dbc};
    my $racks     = $args{-racks};
    my $class_ref = $args{-class_ref};
    my $target    = $args{-target};
    my @classes;

    if ($class_ref) {
        @classes = @$class_ref;
    }
    else {
        my $slot_racks = join ',', $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FKParent_Rack__ID IN ($racks) AND Rack_Type = 'Slot'" );
        my $rack_list = $racks;
        if ($slot_racks) { $rack_list .= ",$slot_racks" }

        my ( $links, $details, $refs ) = $dbc->get_references( 'Rack', { 'Rack_ID' => $rack_list } );    ## third element is the hash of references
        if ($refs) {
            @classes = keys %$refs;
        }
        foreach my $class (@classes) {
            $class =~ s/\..*//;                                                                          ## strip .FK_Rack__ID reference ...
        }
        push @classes, '';
    }
    my $Form = new LampLite::Form(-dbc=>$dbc);
    my $hidden = $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 )
        . $q->hidden( -name => 'Source_Racks', -value => $racks, -force => 1 );

    $Form->append('Move:', $q->popup_menu( -name => 'Types', -values => \@classes, -default => '', -force => 1 ) . ' items (<B>moves everything if nothing chosen</B>)' );
    $Form->append('Include:', alDente::Tools::search_list( -dbc => $dbc, -field => 'Sample_Type', -table => 'Sample_Type', -mode=>'scroll') . ' Samples (includes everything if nothing chosen)');
    
    if ($target) {
        $hidden .= $q->hidden( -name => 'Target_Rack', -value => $target, -force => 1 );
    }
    else {
        $hidden .= set_validator( -name => 'Target_Rack', -mandatory => 1 );
        $Form->append('Redistribute into', Show_Tool_Tip( $q->textfield( -name => 'Target_Rack', -size => 40, -placeholder=>'-- Target Location(s) --' ) ) );
        $Form->append('Note: If multiple locations scanned, similar items will be distributed across targets<BR>See LIMS Admin for information regarding distribution logic');
    }       

    my $split;
    if ( grep /Plate/, @classes ) {
        $split
            .= $q->checkbox( -name => 'Split', -value => 'Plate.FKOriginal_Plate__ID', -label => 'Original Plate/Tube', -checked => 1 )
            . $q->checkbox( -name  => 'Split', -value => 'Plate.FK_Sample_Type__ID',   -label => 'Sample Type',         -checked => 1 )
            . $q->checkbox( -name  => 'Split', -value => 'Plate.Plate_Label',          -label => 'Label',               -checked => 1 );
    }
    if ( grep /Source/, @classes ) {
        $split
            .= $q->checkbox( -name => 'Split', -value => 'Source.FKParent_Source__ID', -label => 'Starting Material' )
            . $q->checkbox( -name => 'Split', -value => 'Source.FK_Sample_Type__ID', -label => 'Starting Material Type', -checked => 1 )
            . $q->checkbox( -name => 'Split', -value => 'Source.Source_Label', -label => 'Label', -checked => 1 );
    }
    if ( grep /Solution/, @classes ) {
        $split .= $q->checkbox( -name => 'Split', -value => 'Solution.FK_Stock__ID', -label => 'Stock Batch' );
    }    
    $Form->append('Split up samples based upon:', $split);
    $Form->append('Target Positioning:', $q->radio_group(-name=>'Fill_By', -values=>['Maintain Original Slot Position', 'Fill by Row', 'Fill by Column'], -default=>'Fill by Row', -force=>1));

    $Form->append('', 
        $q->submit(
            -name    => 'rm',
            -value   => 'Relocate Rack Contents',
            -class   => 'Action',
            -onClick => 'return validateForm(this.form)',
            -force   => 1
            )
        );
        

    my $page = subsection_heading("Relocate Contents");    
    $page .= $Form->generate(-wrap=>1, -include=>$hidden) . '<HR>';
    Call_Stack();
    return $page;
    
    ## old version... ## 
    
    $page .= alDente::Form::start_alDente_form( $dbc, 'move_contents' );
    $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 );

    $page .= '<P>Move: ' . $q->popup_menu( -name => 'Types', -values => \@classes, -default => '', -force => 1 ) . ' items (<B>moves everything if nothing chosen</B>)';
    $page .= $q->hidden( -name => 'Source_Racks', -value => $racks, -force => 1 );

    $page .= "<P>Include: " . alDente::Tools::search_list( -dbc => $dbc, -field => 'Sample_Type', -table => 'Sample_Type', -mode=>'scroll') . ' Samples (includes everything if nothing chosen)';

    if ($target) {
        $page .= $q->hidden( -name => 'Target_Rack', -value => $target, -force => 1 );
        $hidden .= $q->hidden( -name => 'Target_Rack', -value => $target, -force => 1 );
    }
    else {
        $page .= '<P>';
        $page
            .= 'Redistribute items into: '
            . Show_Tool_Tip( $q->textfield( -name => 'Target_Rack', -size => 40 ),
            'Scan target Shelf/Rack/Box<BR>If multiple locations scanned, similar items will be distributed across targets<BR>See LIMS Admin for information regarding distribution logic' );

        $page .= set_validator( -name => 'Target_Rack', -mandatory => 1 );
        
        $hidden .= set_validator( -name => 'Target_Rack', -mandatory => 1 );
        
    }

    $page .= '<p ></p>Split up samples based upon: ';    ## <CONSTRUCTION> - need options for GROUP (all items in group go to same box (eg box 1 = Human; box 2 = Mouse)) or SPLIT (distribute all items in group across boxes (eg box 2 = extra samples))
    if ( grep /Plate/, @classes ) {
        $page
            .= $q->checkbox( -name => 'Split', -value => 'Plate.FKOriginal_Plate__ID', -label => 'Original Plate/Tube', -checked => 1 )
            . $q->checkbox( -name  => 'Split', -value => 'Plate.FK_Sample_Type__ID',   -label => 'Sample Type',         -checked => 1 )
            . $q->checkbox( -name  => 'Split', -value => 'Plate.Plate_Label',          -label => 'Label',               -checked => 1 );
    }
    if ( grep /Source/, @classes ) {
        $page
            .= $q->checkbox( -name => 'Split', -value => 'Source.FKParent_Source__ID', -label => 'Starting Material' )
            . $q->checkbox( -name => 'Split', -value => 'Source.FK_Sample_Type__ID', -label => 'Starting Material Type', -checked => 1 )
            . $q->checkbox( -name => 'Split', -value => 'Source.Source_Label', -label => 'Label', -checked => 1 );
    }
    if ( grep /Solution/, @classes ) {
        $page .= $q->checkbox( -name => 'Split', -value => 'Solution.FK_Stock__ID', -label => 'Stock Batch' );
    }

    $page .= '<p ></p>'
        . 'Target Slot Positioning: '
        . $q->radio_group(-name=>'Fill_By', -values=>['Maintain Original Slot Position', 'Fill by Row', 'Fill by Column'], -default=>'Fill by Row', -force=>1);    
    ## <CONSTRUCTION> - need options for GROUP (all items in group go to same box (eg box 1 = Human; box 2 = Mouse)) or SPLIT (distribute all items in group across boxes (eg box 2 = extra samples))

    $page .= '<P>'
        . $q->submit(
        -name    => 'rm',
        -value   => 'Relocate Rack Contents',
        -class   => 'Action',
        -onClick => 'return validateForm(this.form)',
        -force   => 1
        );

    $page .= '<HR>';
    

    $page .= $q->end_form();

    return $page;
}

#################################
sub prompt_to_confirm_Contents {
#################################
    my %args    = filter_input( \@_, -args => 'rack_id', -mandatory => 'rack_id' );
    my $dbc     = $args{-dbc};
    my $rack_id = $args{-rack_id};

    my $page = alDente::Form::start_alDente_form( $dbc, 'verify' );

    $page .= set_validator( -name => 'Scanned_Rack_File', -mandatory => 1 );

    $page .= $q->hidden( -name => 'Rack_ID', -value => $rack_id, -force => 1 );
    $page .= 'Scanned CSV File: ' . $q->filefield( -name => 'Scanned_Rack_File', -size => 30 );
    $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 );
    $page .= &hspace(5)
        . Show_Tool_Tip(
        $q->submit( -name => 'rm', -value => 'Validate Contents', -force => 1, -onclick => 'return validateForm(this.form)', -class => 'Action' ),
        "Validate Contents of micro-Barcoded Plate (correlate with scanner-generated CSV file containing positions of barcoded tubes173) "
        );
    $page .= $q->end_form();

    return $page;
}

########################
sub reprint_Button {
########################
    my %args  = filter_input( \@_, -args => 'dbc,racks' );
    my $dbc   = $args{-dbc};
    my $racks = $args{-racks} || $args{-rack_id};
    my $wrap  = $args{-wrap};

    ### allow printout of barcodes...
    my $page;
    if ($wrap) {
        $page .= alDente::Form::start_alDente_form( $dbc, 'reprint' );
    }

    $page .= $q->hidden( -name => 'Rack ID', -value => $racks, -force => 1 );
    $page .= Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'Re-Print Rack Barcode',       -class => 'Std' ), "Re-Print Rack barcodes for Racks: $racks" );
    $page .= Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'Re-Print Small Rack Barcode', -class => 'Std' ), "Re-Print Rack barcodes for Racks: $racks" );

    if ($wrap) {
        $page .= $q->end_form();
    }
    return $page;
}

############################
sub display_search_page {
############################
    
    print "UNDER CONSTRUCTION";
    return;
}

######################################
# Find objects in racks and display
#
#
#
#########################
sub find {
#########################
    my %args                      = &filter_input( \@_, -args => 'dbc' );
    my $dbc                       = $args{-dbc};
    my $equipment_name            = $args{-equipment};                      ## Equipment Name
    my $rack_id_choice            = $args{-rack_id};                        ## Rack ID
    my $search_child_racks        = $args{-search_child_racks};             ## Search child racks
    my $equipment_conditions_list = $args{-equipment_condition};
    unless ($equipment_conditions_list) {
        my @condition_list = get_all_rack_conditions( -dbc => $dbc, -blank => 1 );
        $equipment_conditions_list = Cast_List( -list => @condition_list, -to => 'String', -autoquote => 1 );
    }
    my $default_rack_cond = $args{-default_rack_cond};
    my $group_by_ref      = $args{-group_by};
    my $find              = $args{ -find } || 'Plate';                      ## Plate or Solution
    my $since             = $args{-since};
    my $until             = $args{ -until };

    my $prefix = $dbc->barcode_prefix('Rack');

            ### Source specific options
            my $original_source = $args{-original_source};
            my $source_number   = $args{-source_number};
            my $sample_type     = $args{-sample_type};
            my $source_received = $args{-source_received};
            my $organism        = $args{-organism};
            my $tissue          = $args{-tissue};
            my $sex             = $args{-sex};
            my $host            = $args{-host};
            my $strain          = $args{-strain};

            ### Solution specific options
            my $grp           = $args{-grp};
            my $solutions     = $args{-solution_ids};
            my $stock         = $args{-stock};
            my $solution_type = $args{-solution_type};

            ### Plate specific options
            my $project         = $args{-project};
            my $library         = $args{-library};
            my $plate_num       = $args{-plate_num};
            my $plate_ids       = $args{-plate_ids} || '';
            my $plate_format_id = $args{-plate_format_id};
            my $plate_status    = $args{-plate_status};
            my $failed          = $args{-failed};
            my $plate_comments  = $args{-plate_comments};

            my @group_by = @$group_by_ref;

            # Specify tables to retrieve from
            my $tables = "$find LEFT JOIN Rack on $find.FK_Rack__ID = Rack.Rack_ID LEFT JOIN Equipment on Rack.FK_Equipment__ID = Equipment.Equipment_ID 
                        LEFT JOIN Stock as Storage_Stock on Storage_Stock.Stock_ID = Equipment.FK_Stock__ID 
                        LEFT JOIN Stock_Catalog as Storage_Catalog on Storage_Stock.FK_Stock_Catalog__ID = Storage_Catalog.Stock_Catalog_ID
                        LEFT JOIN Equipment_Category ON Storage_Catalog.FK_Equipment_Category__ID = Equipment_Category.Equipment_Category_ID";

            # Specify fields to retrieve from
            my @fields = ( "concat('$prefix',FK_Rack__ID) AS Rack_ID", 'Equipment_Category.Sub_Category', 'Equipment.Equipment_Name AS Equipment' );

    # Specify retrieve conditions
    my $condition       = "WHERE 1";
    my $extra_condition = '';

    # Establish the hierachy and see how we want to group the results
    my @primary_groups = ( 'Sub_Category', 'Equipment', 'Rack_ID' );    # These groups demand a separate entity/section on the results page
    my @secondary_groups;

    if ($rack_id_choice) {
        my $rack_ancestry = $rack_id_choice;
        if ($search_child_racks) {
            my @rack_ancestry;
            _get_rack_children(
                -dbc      => $dbc,
                -rack_id  => $rack_id_choice,
                -children => \@rack_ancestry
            );
            $rack_ancestry = join( ",", @rack_ancestry );
        }
        $extra_condition .= " AND Rack.Rack_ID IN ($rack_ancestry)";
    }
    elsif ($equipment_conditions_list) {
        if ( $equipment_conditions_list =~ /other/i ) { $equipment_conditions_list .= ",''"; }
        $extra_condition .= " AND (Equipment_Category.Sub_Category IN ($equipment_conditions_list) OR Equipment_Category.Sub_Category IS NULL)";    #######
    }
    else {
        $extra_condition .= " AND Equipment_Category.Sub_Category IS NULL";                                                                         ############
    }
    my $find_prefix;
    my $key_field;
    if ($equipment_name) {
        unless ( $equipment_name eq "''" ) {
            $extra_condition .= " AND Equipment_Name IN ($equipment_name) ";
        }
    }

    ##  specific tables, fields, conditions for plates or solutions
    if ( $find eq 'Plate' ) {
        if ($project) {

            #Need to include the Project and Library tables as well if searching by project.
            $tables .= ',Plate_Format,Library,Project';
        }
        else {
            $tables .= ',Plate_Format';
        }
        ### Add the plate fields
        my @plate_fields = ( 'Plate.FK_Library__Name AS Library', 'Plate_Format.Plate_Format_Type AS Plate_Format_Type', 'Plate.Plate_Number AS Plate_Number', 'Plate.Plate_ID' );
        push( @fields, @plate_fields );
        ### Add plate conditions
        $condition .= " AND Plate.FK_Plate_Format__ID = Plate_Format.Plate_Format_ID";

        if ($plate_status) {
            $extra_condition .= " AND Plate.Plate_Status IN ($plate_status)";
        }
        if ($failed) {
            $extra_condition .= " AND Plate.Failed IN ($failed)";
        }
        if ($since) {
            if ($until) {
                $extra_condition .= " AND Plate_Created between '$since' and '$until'";
            }
            else { $extra_condition .= " AND Plate.Plate_Created > '$since'" }
        }
        if ($plate_ids) {
            $extra_condition .= " AND Plate.Plate_ID in ($plate_ids)";
        }
        if ( $equipment_name =~ /\w/ ) {
            $extra_condition .= " AND Equipment.Equipment_Name IN ($equipment_name)";
        }

        if ($project) {
            $condition       .= " AND Plate.FK_Library__Name = Library.Library_Name AND Library.FK_Project__ID = Project.Project_ID";
            $extra_condition .= "AND Project.Project_Name IN ($project)";
        }
        if ($library) { $extra_condition .= " AND FK_Library__Name IN ($library)" }
        if ($plate_num) {
            $plate_num = resolve_range($plate_num);
            $extra_condition .= " AND Plate.Plate_Number IN ($plate_num)";
        }
        if ($plate_comments) {
            $plate_comments = convert_to_regexp($plate_comments);    ## allow wildcard here..
            $extra_condition .= " AND Plate_Comments LIKE '$plate_comments'";
        }
        if ($plate_format_id) {
            $extra_condition .= " AND Plate.FK_Plate_Format__ID IN ($plate_format_id)";
        }

        @secondary_groups = ( 'Library', 'Plate_Number', 'Plate_Format_Type', 'Plate_ID' );    # These groups will just be combined together
        ##
        $find_prefix = "pla";
        $key_field   = "Plate_ID";
    }
    elsif ( $find eq 'Solution' ) {
        ### Add the solution tables
        $tables .= ", Stock, Stock_Catalog, Grp";
        ### Add the solution fields
        my @solution_fields = ( 'Stock_Catalog.Stock_Catalog_Name', 'Grp_ID', 'Solution_Type', 'Solution_ID' );
        push( @fields, @solution_fields );
        ### Add solution conditions
        $condition .= " AND Solution.FK_Stock__ID = Stock.Stock_ID and Grp_ID=Stock.FK_Grp__ID AND Stock.FK_Stock_Catalog__ID = Stock_Catalog.Stock_Catalog_ID";
        if ($grp) { $extra_condition .= " AND Stock.FK_Grp__ID IN ($grp)" }
        if ($stock) {
            $extra_condition .= " AND Stock_Catalog.Stock_Catalog_Name like '%$stock%'";
        }
        if ($solution_type) { $extra_condition .= " AND Solution_Type IN ('$solution_type')" }
        if ($solutions)     { $extra_condition .= " AND Solution_ID IN ($solutions)"; }
        if ($since)         { $extra_condition .= " AND Solution_Started > '$since'"; }
        @secondary_groups = ( 'Stock_Catalog.Stock_Catalog_Name', 'Grp_ID', 'Solution_Type', 'Solution_ID' );    # These groups will just be combined together
        $find_prefix      = "sol";
        $key_field        = "Solution_ID";
    }
    elsif ( $find eq 'Source' ) {
        $tables .= ", Original_Source";
        my @source_fields = ( 'Original_Source_Name', 'Source_Number', 'FK_Sample_Type__ID as Sample_Type', 'Source_ID' );
        push( @fields, @source_fields );
        $condition .= " AND Source.FK_Original_Source__ID = Original_Source_ID";
        if ($sample_type) { $extra_condition .= " AND FK_Sample_Type__ID IN ($sample_type)" }
        if ($original_source) {
            $extra_condition .= " AND Original_Source_Name like '%$original_source%'";
        }
        if ($source_number) { $extra_condition .= " AND Source_Number IN ('$source_number')" }
        if ($source_received) {
            $extra_condition .= " AND Received_Date like '%$source_received%'";
        }

        #if ($tissue){$extra_condition .= " and Anatomic_Site like '%$tissue%'"}
        if ($sex)    { $extra_condition .= " and Sex like '%$sex%'" }
        if ($host)   { $extra_condition .= " and Host like '%$host%'" }
        if ($strain) { $extra_condition .= " and FK_Strain__ID = $strain" }
        @secondary_groups = ( 'Original_Source_Name', 'Source_Number', 'Source_Type', 'Source_ID' );    # These groups will just be combined together
        $find_prefix      = "src";
        $key_field        = "Source_ID";
    }

    ### Add ORDER BY condition
    my $order = " ORDER BY Equipment_Category.Sub_Category, Equipment.Equipment_Name, Rack.Rack_ID";    ###############

    my $rack_contents = $dbc->Table_retrieve(
        -table     => $tables,
        -fields    => \@fields,
        -condition => "$condition $extra_condition $order",
        -format    => 'AofH'
    );

    unless ($rack_contents) {
        Message("No records found");
        return;
    }

    my @hierachy = ('All');
    if ( int(@group_by) ) {
        foreach my $pg (@primary_groups) {
            if ( grep /^$pg$/, @group_by ) { push( @hierachy, $pg ) }
        }
        my @sgs;
        foreach my $sg (@secondary_groups) {
            if ( grep /^$sg$/, @group_by ) { push( @sgs, $sg ) }
        }
        if (@sgs) { push( @hierachy, join( ',', @sgs ) ) }
    }

    # Transform the info into another hash that is keyed based on the hierachy
    my %info;
    foreach my $rack_content (@$rack_contents) {

        my $curr_hash_ref = \%info;    # Reference to the hash of the current level
        foreach ( my $i = 0; $i <= $#hierachy; $i++ ) {
            my $key = $hierachy[$i];
            if ( $i == $#hierachy ) {

                # If we are at the last level of the hierachy then need to keep the Plate_ID
                my $key_name = $key;
                $key_name =~ s/(\w+)/$rack_content->{$1}/g;
                push( @{ $curr_hash_ref->{$key_name} }, $rack_content->{$key_field} );
            }
            else {
                my $item;
                if ( exists $rack_content->{$key} ) { $item = $rack_content->{$key} }
                elsif ( $key eq 'All' ) { $item = $key }
                unless ( exists $curr_hash_ref->{$item} ) {
                    $curr_hash_ref->{$item} = {};
                }
                $curr_hash_ref = $curr_hash_ref->{$item};
            }
        }
    }

    my %totals;
    my $output = HTML_Table->new();
    $output->Set_Line_Colour( 'white', 'white' );

    my ($ret) = found_Items(
        -curr_info   => \%info,
        -curr_level  => 0,
        -dbc         => $dbc,
        -hierachy    => \@hierachy,
        -find_prefix => $find_prefix
    );
    $output->Set_Row( [$ret] );
    $output->Set_VAlignment('Top');
    return $output->Printout(0);
}

#######################################################################
# Recursive routine which goes through all entities and return each entity as a HTML table object
#######################################################################
sub found_Items {
######################
    my %args         = @_;
    my $dbc          = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $curr_info    = $args{-curr_info};
    my $curr_level   = $args{-curr_level};
    my $hierachy_ref = $args{-hierachy};
    my $find_prefix  = $args{-find_prefix};

    my @hierachy   = @$hierachy_ref;
    my $group_name = $hierachy[$curr_level];
    my $output;
    my @horizontals;
    my $total_count = 0;

    foreach my $group_by ( sort keys %$curr_info ) {
        if ( $curr_level == $#hierachy ) {

            # We are at the lowest level
            my $ids = join( ",", map {$_} @{ $curr_info->{$group_by} } );
            my $frozen = Safe_Freeze(
                -name   => "IDs",
                -value  => \$ids,
                -format => 'url',
                -encode => 1,
            );
            my $list = &Link_To( $dbc->config('homelink'), $group_by, "&cgi_application=alDente::Rack_App&rm=Display_Lab_Object&$frozen&Type=$find_prefix", 'blue', ['newwin'] );
            my $plate_count = int( @{ $curr_info->{$group_by} } );
            $total_count += $plate_count;

            $output .= "<nobr>" . $q->checkbox( -name => "Barcode", -value => "$find_prefix$ids", -label => "" ) . "$list ($plate_count)</nobr><br>";
        }
        else {
            my $table = HTML_Table->new();
            $table->Set_Class('small');
            $table->Set_Border(1);

            # Get the output for the entity of the next level down
            my ( $ret, $t ) = found_Items(
                -dbc         => $dbc,
                -curr_info   => $curr_info->{$group_by},
                -curr_level  => $curr_level + 1,
                -hierachy    => $hierachy_ref,
                -find_prefix => $find_prefix
            );
            $total_count += $t;    # Add up the totals from entities below as well

            $table->Set_Title("<nobr>$group_by ($t)</nobr>");

            if ( ( $curr_level + 1 ) == $#hierachy ) {

                # If next level is the lowest level or only one level, then we need to print the group name headers
                $group_name =~ s/\bLibrary\b/Lib/i;
                $group_name =~ s/\bPlate_Number\b/Pla\#/i;
                $group_name =~ s/\bPlate_Format_Type\b/Type/i;
                $group_name =~ s/\bPlate_ID\b/ID/i;

                my $header = "<nobr>";
                $header .= $q->checkbox(
                    -name    => "Select_All",
                    -value   => "Select_All",
                    -label   => "",
                    -onClick => "ToggleCheckBoxes(document.$group_by,'Select_All');"
                );
                $header .= "$hierachy[$curr_level+1]</nobr>";

                $table->Set_Headers( [$header] );
            }
            $table->Set_Row( [$ret] );
            $table->Set_VAlignment('Top');

            my $curr_output;
            if ( ( $curr_level + 1 ) == $#hierachy ) {

                # If next level is the lowest level or only one level, then we need to print the move plates feature footer
                my $start_form = alDente::Form::start_alDente_form( -dbc => $dbc, -name => $group_by )
                    . $q->hidden(
                    -name  => 'cgi_application',
                    -value => 'alDente::Rack_App',
                    -force => 1
                    );

                my $move_plates_feature = $q->submit( -name => 'rm', -value => "Move Object", -class => "Action" ) . $q->br . rack_prompt( -dbc => $dbc, -name => 'FK_Rack__ID', -form => $group_by );

                my $end_form = "</form>";

                ### put the contents of the hash in a create_tree
                my %rack_hash;
                my $form_output = $start_form . $table->Printout(0) . $move_plates_feature . $end_form;

                $rack_hash{"$group_by ($t)"} = [$form_output];

                $curr_output .= create_tree( -tree => \%rack_hash, -print_tree => 0, -toggle_open => 1 );

            }
            else {
                $curr_output = $table->Printout(0);
            }

            if ( $group_name =~ /Equipment/i ) {

                # Horizontal placement of entities
                push( @horizontals, $curr_output );
            }
            else {

                # Vertical placement of entities
                $output .= $curr_output;

            }
        }
    }

    if (@horizontals) {
        $output .= &Views::Table_Print( content => [ \@horizontals ], print => 0 );
    }

    return ( $output, $total_count );
}

#########################################################################################
# Define the find page for a rack given the object to find, ie. Plate, Solution, Source
#
#
#####################
sub find_in_rack {
#####################
    my %args  = filter_input( \@_, -args => 'find' );
    my $find  = $args{ -find };
    my $title = $args{-title};
    my $dbc   = $args{-dbc};

    my $startform;
    if ( defined $args{-form} ) {
        $startform = $args{-form};
    }
    else {
        $startform = 1;
    }

    my $form = "Find$find";

    my $form_output;

    if ($startform) {
        $form_output .= alDente::Form::start_alDente_form( $dbc, 'SourceSearch' );
        $form_output .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => $form, -type => 'start' );
    }

    ### Find page
    my $find_option_page = HTML_Table->new();

    $find_option_page->Set_Title("Find $find");
    $find_option_page->toggle();
    $find_option_page->Toggle_Colour('Off');
    $find_option_page->Set_Border(1);

    ## Define the generic rack search options for the page
    my $equipment_conditions_ref = alDente::Rack::get_all_rack_conditions( -dbc => $dbc );
    my @equipment_conditions = @$equipment_conditions_ref;

    ## Define the rack condition defaults;
    my @rc_defaults;
    foreach my $rc (@equipment_conditions) {
        push( @rc_defaults, $rc ) if ( $rc =~ /room|degrees/i );
    }

    my $equipment_conditions_filter = [
        "<b>Equipment Condition: </b>",
        join ' ',
        $q->checkbox_group(
            -name    => 'Equipment_Condition',
            -values  => \@equipment_conditions,
            -default => \@rc_defaults
        )
    ];
    my @equipment = $dbc->Table_find( 'Equipment,Rack', 'Equipment_Name', "WHERE FK_Equipment__ID=Equipment_ID ORDER BY Equipment_Name", 'distinct' );

    # my $equipment_filter = ["<b>Equipment Name: </b>", &alDente::Tools::search_list(-dbc=>$dbc,-form=>$form,-name=>'Equipment_Name',-options=>\@equipment,-filter=>1,-search=>1, -mode=>'Scroll')];
    my $equipment_filter = [
        "<b>Freezer/Shelf Name: </b>",
        &alDente::Tools::search_list(
            -dbc     => $dbc,
            -form    => $form,
            -name    => 'Equipment.Equipment_Name',
            -options => \@equipment,
            -default => \@rc_defaults,
            -filter  => 1,
            -search  => 1,
            -mode    => 'Scroll'
        )
    ];

    my $rack_filter = [
        "<b>Rack: </b>",

        #		       &alDente::Tools::search_list(-dbc=>$dbc,-form=>$form,-name=>'FK_Rack__ID',-options=>\@locations,-filter=>1,-search=>1)
        rack_prompt( -dbc => $dbc, -name => 'FK_Rack__ID', -form => $form ) . "<BR>"
            . $q->checkbox(
            -name    => 'Search_Child_Racks',
            -checked => 1,
            -label   => 'Search Child Racks'
            )
    ];

    ## Group BY
    my @grp_by_values = ( 'Equipment', 'Rack_ID' );    #'Equipment_C ondition',
    my @default_grp;
    push( @default_grp, @grp_by_values );

    ## Define the search options for specific objects
    if ( $find eq 'Plate' ) {
        my @search_by_projects = $dbc->Table_find( 'Project', 'distinct Project_Name', 'ORDER BY Project_Name' );
        my $project_filter = [
            "<b>Project: </b>",
            &alDente::Tools::search_list(
                -dbc     => $dbc,
                -form    => $form,
                -name    => 'Project_Name',
                -options => \@search_by_projects,
                -filter  => 1,
                -search  => 1,
                -mode    => 'Scroll'
            )
        ];
        my $plate_num_filter = "<b>Plate Number: </b>" . $q->textfield( -name => 'Plate_Number', -size => 3 );

        my @libraries = $dbc->Table_find( 'Library', 'distinct Library_Name', 'ORDER BY Library_Name' );
        my $library_filter = [
            "<b>Library: </b>",
            &alDente::Tools::search_list(
                -dbc     => $dbc,
                -form    => $form,
                -name    => 'Library_Name',
                -options => \@libraries,
                -filter  => 1,
                -search  => 1,
                -mode    => 'Scroll'
                )
                . $plate_num_filter
        ];

        my @plate_status = get_enum_list( $dbc, 'Plate', 'Plate_Status' );

        #my $status_filter = ["<b>Plate Status: </b>" , &alDente::Tools::search_list(-dbc=>$dbc,-form=>$form,-name=>'Plate_Status',-options=>\@plate_status,-default=>'Active', -filter=>0,-search=>0,-mode=>'Scroll')];
        my $status_filter = [
            "<b>Plate Status: </b>",
            join ' ',
            checkbox_group(
                -name    => 'Plate_Status',
                -values  => \@plate_status,
                -default => 'Active',
                -force   => 1
            )
        ];
        
        my @failed = get_enum_list( $dbc, 'Plate', 'Failed' );
        my $failed_filter = [
            "<b>Failed: </b>",
            join ' ',
            checkbox_group(
                -name    => 'Failed',
                -values  => \@failed,
                -default => 'No',
                -force   => 1
            )
        ];

        my $comment_filter = [ "<b>Plate Comments: </b>", textfield( -name => 'Plate_Comments', -size => 60 ) ];
        
        my @plate_formats = &get_FK_info(
            $dbc,
            'Plate.FK_Plate_Format__ID',
            -order => "ORDER BY
            Plate_Format_Type,Well_Capacity_mL",
            -list => 1
        );
        my $plate_format_filter = [
            "<b>Plate Format: </b>",
            &alDente::Tools::search_list(
                -dbc     => $dbc,
                -form    => $form,
                -name    => 'Plate_Format',
                -options => \@plate_formats,
                -filter  => 1,
                -search  => 1,
                -mode    => 'Scroll'
            )
        ];

        push( @grp_by_values, 'Library', 'Plate_Number', 'Plate_Format_Type', 'Plate_ID' );
        push( @default_grp, 'Library', 'Plate_Number' );
        $find_option_page->Set_Row($project_filter);
        $find_option_page->Set_Row($library_filter);
        $find_option_page->Set_Row($status_filter);
        $find_option_page->Set_Row($failed_filter);
        $find_option_page->Set_Row($comment_filter);
        $find_option_page->Set_Row($plate_format_filter);

    }
    elsif ( $find eq 'Solution' ) {
        my $stock_filter = [ "<b>Stock Name <b>", $q->textfield( -name => 'Stock_Catalog_Name', -default => '', -force => 1 ) ];
        my @solution_type = get_enum_list( $dbc, 'Solution', 'Solution_Type' );
        my $solution_type_filter = [ "<b>Solution Type: </b>", $q->popup_menu( -name => 'Solution_Type', -value => [ '', @solution_type ] ) ];
        my @grp_list             = @{ $dbc->get_local('groups') };
        my $grp_filter           = [ "<b>Groups: </b>", $q->popup_menu( -name => 'Grp', -value => [ '', @grp_list ] ) ];
        $find_option_page->Set_Row($stock_filter);
        $find_option_page->Set_Row($solution_type_filter);
        $find_option_page->Set_Row($grp_filter);
        push( @grp_by_values, 'Stock_Catalog_Name', 'Solution_Type', 'Solution_ID' );
        push( @default_grp, 'Stock_Catalog_Name', 'Solution_ID' );

    }
    elsif ( $find eq 'Source' ) {
        my @sample_type = $dbc->Table_find( 'Sample_Type', 'Sample_Type', 'WHERE 1', -distinct => 1 );
        my $sample_type_filter = [
            "<b>Sample Type: </b>",
            Show_Tool_Tip(
                $q->popup_menu(
                    -name  => 'Sample_Type',
                    -value => [ '', @sample_type ],
                    -force => 1
                ),
                "Types of Available Sources"
            )
        ];
        my $orig_src_filter = [ "<b>Original Source:<b>", Show_Tool_Tip( $q->textfield( -name => 'Orig_Src_Name', -default => '', -force => 1 ), "Find all instances matching original source name entered" ) ];
        my $source_num_filter = [ "<b>Source Number: </b>", $q->textfield( -name => 'Source_Number', -size => 3, -force => 1 ) ];

        my $source_received_filter = [ "<b>Source Received: </b>", $q->textfield( -name => 'Source_Received', -size => 10, -force => 1 ) . " (YYYY-MM-DD)" ];
        my $sex = [ "<b>Sex: </b>", $q->textfield( -name => 'Sex', -force => 1 ) ];

        #my $tissue = ["<b>Anatomic_Site: </b>", $q->textfield(-name=>'Anatomic_Site',-force=>1)];
        my $strain = [ "<b>Strain: </b>", $q->textfield( -name => 'FK_Strain__ID', -force => 1 ) ];
        my $host   = [ "<b>Host: </b>",   $q->textfield( -name => 'Host',          -force => 1 ) ];
        push( @grp_by_values, 'Sample_Type', 'Original_Source_Name', 'Source_Number', 'Source_ID' );
        push( @default_grp, 'Original_Source_Name', 'Source_Number', 'Source_ID' );
        $find_option_page->Set_Row($sample_type_filter);
        $find_option_page->Set_Row($orig_src_filter);
        $find_option_page->Set_Row($source_num_filter);

        #$find_option_page->Set_Row($organism);
        $find_option_page->Set_Row($sex);

        #$find_option_page->Set_Row($tissue);
        $find_option_page->Set_Row($strain);
        $find_option_page->Set_Row($host);
        $find_option_page->Set_Row($source_received_filter);
    }

    #    my $group_filter = [
    #        "<b>Group by: </b>",
    #        join ' ',
    #        checkbox_group(
    #            -name    => 'Group_By',
    #            -values  => \@grp_by_values,
    #            -default => \@default_grp,
    #            -force   => 1
    #        )
    #    ];

    #&alDente::Tools::search_list(-dbc=>$dbc,-form=>$form,-name=>'Group_By',-options=>\@grp_by_values,-default=>\@default_grp,-filter=>0,-search=>0,-mode=>'Scroll')
    $find_option_page->Set_Row($equipment_filter);
    $find_option_page->Set_Row($rack_filter);
    $find_option_page->Set_Row($equipment_conditions_filter);

    #  $find_option_page->Set_Row($group_filter);
    $find_option_page->Set_sub_header( $q->submit( -name => "rm", -value => "Find $find", -class => "Search" ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 ) );
    $form_output .= $find_option_page->Printout(0);

    $form_output .= $q->end_form() if ($startform);

    return $form_output;

    #return $find_option_page;
}

#
# Storage method enabling distribution of samples across multiple locations as required
#
# Formatted 'Store' hash indicates method of distribution:
#
#  Store{1234} = Pla1Pla2Pla3 - store objects in indicated Storage locations (Plates: 1,2,3 -> Rack 1234)
#  Store{RNA}{1234} = Pla1Pla2 - store RNA from Plates 1,2 -> Rack 1234
#
# (uses confirm_Storage wrapper to generate Store hash)
#
# Return: interface page to confirm storage request
#######################
sub confirm_Store {
#######################
    my %args = filter_input( \@_, -args => 'dbc,Store,fill_by' );

    my $dbc       = $args{-dbc};
    my $store_ref = $args{-Store};     # '$rack_id' => 'Pla$id[0]Pla$id[1]...'
    my $fill_by   = $args{-fill_by};
    my $slot_ref  = $args{-Slots};
    my $order     = $args{-order};
    my $exclude   = $args{-exclude};
    my $debug     = $args{-debug};
    my %Store     = %$store_ref;

    my %Slots;
    %Slots = %$slot_ref if $slot_ref;
    my $page = alDente::Form::start_alDente_form( $dbc, 'confirm_redistribution' );
    $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 );

    my $sim_scan;                      ## simulate full move scan

    my @types = alDente::Rack::get_stored_material_types( undef, -dbc => $dbc );
    my $repeated = 0;

    my $prefix = $dbc->barcode_prefix('Rack');

    my @target_racks = sort keys %Store;
    if ($order) { @target_racks = @$order }    ## if order supplied explicitly

    foreach my $key (@target_racks) {
        if ( $key =~ /^\d+$/ ) {
            ## Storage format is 'rack_id' => barcode_array ##
            ## key = Rack_ID ##
            $sim_scan .= $prefix . $key;

            my @types = keys %{$dbc->barcode_prefix };          ## potentially any prefixed item (barcodable) may be stored ##
            $page .= section_heading( "Relocating Items -> " . alDente_ref( 'Rack', $key, -dbc => $dbc ) );
            foreach my $type (@types) {
                my $pf = $dbc->barcode_prefix($type);
                my @store_list = grep /^$pf\d+/i, @{ $Store{$key} };
                my @slots;
                if ( $slot_ref && $Slots{$key} ) {
                    @slots = @{ $Slots{$key} };    ## should only be applicable when 1 item in store_list above...
                }

                my $itemlist = join '', @store_list;

                my $id_list = join ',', @store_list;
                $id_list =~ s/$pf//gi;

                $page .= '<P>';
                if ($itemlist) {
                    $sim_scan .= $itemlist;
                    $page     .= move_Page(
                        -dbc      => $dbc,
                        -type     => $type,
                        -ids      => $id_list,
                        -rack     => $key,
                        -slots    => \@slots,
                        -repeated => $repeated++,
                        -fill_by  => $fill_by,
                        -exclude  => $exclude,
                    );
                }
            }
        }
        else {

            ## Storage format is 'class' => 'rack_id' => id_array ##
            ## key = Item Class
            my $pf = $dbc->barcode_prefix($key);

            my @targets = sort keys %{ $Store{$key} };
            if ($order) { @targets = @$order }    ## if order supplied explicitly

            foreach my $rack_id (@targets) {
                my $id_list = join ',', @{ $Store{$key}{$rack_id} };
                my @slots;
                @slots = @{ $Slots{$key}{$rack_id} } if $slot_ref;

                # my $list = $dbc->Table_retrieve_display($key, ["${key}_ID as $key", 'FK_Rack__ID as Original_Location'], "WHERE ${key}_ID IN ($id_list) ORDER BY ${key}_ID", -return_html=>1);
                # $page .= create_tree(-tree=>{ '-> ' . alDente_ref('Rack', $rack_id, -dbc=>$dbc) => $list});

                if ($id_list) {
                    $sim_scan .= $prefix . $rack_id;
                    $sim_scan .= $pf . $id_list;
                    $sim_scan =~ s/,/$pf/g;
                    $page .= move_Page(
                        -dbc      => $dbc,
                        -type     => $key,
                        -ids      => $id_list,
                        -slots    => \@slots,
                        -rack     => $rack_id,
                        -repeated => $repeated++,
                        -fill_by  => $fill_by,
                        -exclude  => $exclude,
                    );
                }
            }
        }
    }

    if ($debug) {
        $page .= "<P>SIMSCAN: $sim_scan<P>";
    }    ## simulated scan equivalent to execute the same object movement
    $page .= $q->hidden( -name => 'sim_scan', -value => $sim_scan );

    $page .= $q->submit(
        -name  => 'rm',
        -value => 'Confirm Re-Distribution',
        -class => 'Action',
        -force => 1
    );
    $page .= $q->end_form();

    return $page;
}

#
# Refactored above method to make it more intuitive and scalable
# (may still need to recode sections that still use above method (confirm_Store))
#
# Input:	    Message("IDS: $id_list");

# arrays representing required information for items to be moved:
#  * Object types (eg ['Plate','Plate','Source'];
#  * IDs eg [$plate_id[0], $plate_id[1], $source_id[0]];
#  * rack locations eg [123, 123, 123];    ## NOTE: for slotted boxes, use the BOX rack_id
#  * slots (optional slot locations if above rack is a slotted box)
#
#  This generates a confirmation page (with preselected slots if applicable)
#
# Return: confirmation page for relocation
#########################
sub confirm_Storage {
#########################
    my %args        = filter_input( \@_, -mandatory => 'Rack,objects,ids,racks|rack' );
    my $Rack        = $args{-Rack};
    my $objects     = $args{-objects};
    my $ids         = $args{-ids};
    my $racks       = $args{-racks};
    my $single_rack = $args{-rack};                                                       ## optionally supply single rack for all items.
    my $slots       = $args{-slots};

    my $exclude = $args{-exclude};
    my $fill_by = $args{-fill_by};
    my $order   = $args{-order};
    my $debug   = $args{-debug};

    #
    my $dbc = $Rack->{dbc};

    #    my $page = alDente::Form::start_alDente_form($dbc, 'confirm_redistribution');
    #    $page .= 'Relocating Items:<P>';
    #    $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 );

    my $sim_scan;    ## simulate full move scan

    my @types    = @{ unique_items($objects) };
    my $repeated = 0;

    my @slot_list;
    my @ids;

    my %Store;
    my %Slots;       ## optional hash to store slot specification

    my $prefix = $dbc->barcode_prefix('Rack');

    if ( $racks && int(@$racks) == 1 ) {
        $single_rack = $racks->[0];
        foreach my $i ( 2 .. int(@$ids) ) { $racks->[ $i - 1 ] = $single_rack }
    }
    elsif ( $racks && ( int(@$racks) < int(@$ids) ) ) {
        $dbc->warning("Rack count differs from object count - Cycling through Rack locations...");
        my $rack_index = 0;
        foreach my $i ( int(@$racks) .. int(@$ids) - 1 ) {
            ## fill in missing rack ids ##
            $racks->[$i] = $racks->[$rack_index];
            $rack_index++;
            if ( $rack_index >= int(@$racks) ) { $rack_index = 0 }
        }
    }

    foreach my $item_count ( 1 .. int(@$ids) ) {
        my $object = $objects->[ $item_count - 1 ];
        my $rack   = $single_rack || $racks->[ $item_count - 1 ];
        my $id     = $ids->[ $item_count - 1 ];
        my $slot;
        if ($slots) { $slot = $slots->[ $item_count - 1 ] }

        #push @{$ids{$object}{$rack}}, $id;
        #push @{$slots{$object}{$rack}}, $slot;
        push @ids,       $id;
        push @slot_list, $slot;

        if ( ( $item_count < int(@$ids) ) && ( $object eq $objects->[$item_count] ) && ( $rack == $racks->[$item_count] ) ) {
            next;
        }
        else {
            my $pf = $dbc->barcode_prefix($object);
            my $id_list = join "$pf", @ids;    ## @{$ids{$object}{$rack}};
            if ($id_list) {
                $sim_scan .= $prefix . $rack . $pf . $id_list;
                push @{ $Store{$rack} }, map { $pf . $_ } @ids;
                push @{ $Slots{$rack} }, @slot_list;
            }
            ## clear arrays of ids, slot_list .. ##
            @ids       = ();
            @slot_list = ();
        }
    }

    return confirm_Store( $dbc, \%Store, -Slots => \%Slots, -fill_by => $fill_by, -order => $order, -exclude => $exclude );
}

############################
#
# Display failed objects and ask user to choose to move failed objects not
#
############################
sub prompt_to_confirm_move {
############################
    my %args         = filter_input( \@_, -mandatory => 'dbc,need_confirm,objects,ids,racks' );
    my $dbc          = $args{-dbc};
    my $need_confirm = $args{-need_confirm};
    my $exclude      = $args{-exclude};
    my $fill_by      = $args{-fill_by};

    my ( $objects, $ids, $racks, $slots );
    if ( $args{-objects} ) { $objects = join ',', @{ $args{-objects} } }
    if ( $args{-ids} )     { $ids     = join ',', @{ $args{-ids} } }
    if ( $args{-racks} )   { $racks   = join ',', @{ $args{-racks} } }
    if ( $args{-slots} )   { $slots   = join ',', @{ $args{-slots} } }

    my $page = alDente::Form::start_alDente_form( $dbc, 'verify' );

    if ( $need_confirm->{Failed} ) {
        foreach my $obj ( keys %{ $need_confirm->{Failed} } ) {
            my $failed_count = int( @{ $need_confirm->{Failed}{$obj} } );
            my $failed_ids = join ',', @{ $need_confirm->{Failed}{$obj} };
            my ( $table, @fields, $conditions );
            if ( $obj =~ /Plate/xmsi ) {
                $table      = 'Plate LEFT JOIN Plate_Tray ON Plate_Tray.FK_Plate__ID = Plate_ID';
                @fields     = ( 'Plate_ID', 'FK_Library__Name', 'Plate_Status', 'Failed', 'Plate_Position' );
                $conditions = "WHERE Plate_ID in ($failed_ids)";
            }
            $page .= "$failed_count $obj are Failed: ";
            $page .= $dbc->Table_retrieve_display( $table, \@fields, $conditions, -title => "Failed", -return_html => 1 );
        }
        $page .= "<BR>Please confirm if they will be moved together:";
        $page .= vspace(5);
        $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 );
        $page .= $q->submit( -name => 'rm', -value => 'Move Excluding Failed Object', -force => 1, -class => 'Action' );
        $page .= hspace(10);
        $page .= $q->submit( -name => 'rm', -value => 'Move Including Failed Object', -force => 1, -class => 'Action' );
        $page .= Safe_Freeze( -name => "Failed", -value => $need_confirm->{Failed}, -format => 'hidden', -encode => 1 );
        $page .= $q->hidden( -name => "objects", -value => $objects, -force => 1 );
        $page .= $q->hidden( -name => "ids",     -value => $ids,     -force => 1 );
        $page .= $q->hidden( -name => "racks",   -value => $racks,   -force => 1 );
        $page .= $q->hidden( -name => "slots",   -value => $slots,   -force => 1 );
        $page .= $q->hidden( -name => "exclude", -value => $exclude, -force => 1 );
        $page .= $q->hidden( -name => "fill_by", -value => $fill_by, -force => 1 );
    }

    $page .= end_form();
    return $page;
}

#
#####################################################
#
# Page prompting users to confirm movement of items
#
#
#
# Return: html page
##################
sub move_Page {
##################
    my %args        = filter_input( \@_, -args => 'dbc,type,ids,fill_by', -mandatory => 'ids,rack' );
    my $Rack        = $args{-Rack};
    my $ids         = $args{-ids};
    my $type        = $args{-type};
    my $fill_by     = $args{-fill_by};
    my $slot_choice = $args{-slot_choice};
    my $slots       = $args{-slots};
    my $exclude     = $args{-exclude};                                                                  ## slots to skip or exclude
    my $rack        = $args{-rack};
    my $repeated    = $args{'-repeated'} || 0;                                                          ## this page is repeated (enables hiding of header / footer options)
    my $locations   = $args{'-locations'};                                                              ## comma deliminated and has to match the number of ids
    my $title       = $args{-title};
    my $confirmed   = $args{-confirmed};                                                                ## in this mode, just show page as log (ie no form required)
    my $debug       = $args{-debug};
    my $dbc         = $args{-dbc} || $Rack->{dbc};

    my $rack_prefix = $dbc->barcode_prefix('Rack');

    if ( $rack && !$Rack ) {
        $Rack = new alDente::Rack( -id => $rack, -dbc => $dbc );
    }
    elsif ( $Rack && !$rack ) {
        $rack = $Rack->{id};
    }
    
    if ( ref $ids eq 'ARRAY' ) { $ids = Cast_List( -list => $ids, -to => 'string' ) }
    my @id_list = split /,/, $ids;
    my $id_count = int(@id_list);
    my ($primary_field) = $dbc->get_field_info( $type, undef, 'PRI' );
    my ($slotted_box) = $dbc->Table_find_array( 'Rack', ["count(*)"], "WHERE Rack_Type = 'Slot' and FKParent_Rack__ID = $rack" );

    ### This figures out if source rack is ONE slotted box
    my @distinct_source_racks = $dbc->Table_find_array( "$type, Rack", ["Rack_Type"], "WHERE $primary_field in ($ids) AND Rack_ID = FK_Rack__ID GROUP BY FKParent_Rack__ID" ) if $ids;
    my $source_rack_option;

    unless ($fill_by) {
        $fill_by = 'Row,Column';
        ### This chanegs the default slot assignment for slotted boxes
#        if ( $distinct_source_racks[0] =~ /slot/i && int @distinct_source_racks == 1 && $slotted_box ) { $fill_by = 'Match' }
    }

    if ( $distinct_source_racks[0] =~ /slot/i && int @distinct_source_racks == 1 ) { $source_rack_option = 1 }

    if ( $fill_by =~ /match/i && !$locations ) {
        $locations = $Rack->get_Object_slots( -dbc => $dbc, -object => $type, -ids => $ids );
        my @temp = split ',', $locations;
        $slots = \@temp;
    }

    my @locs = split /,/, $locations;
    my $loc_count = int(@locs);

    ## Checking to see if the number of ids matches number of locations
    if ( !( $loc_count == $id_count ) && $locations ) {
        Message "Number of locations ($loc_count) does not match number of objects($id_count).  Ignoring preset locations";
        $locations = '';
    }

    if ( !$repeated && !$slots ) { Message("Filling Box by $fill_by") }
    ## (form already initiated in Rack_home) ##

    my $group = "$rack_prefix$rack.$type";
    my $page = $q->hidden( -name => 'Store_Group', -value => $group, -force => 1 );

    my $archive_check;    ## only applicable for plates
    if ( $type =~ /(Plate|Library_Plate|Tube)/ ) {
        $archive_check = Show_Tool_Tip( $q->checkbox( -name => 'Archive', -label => 'Archive these Samples' ),
            "If checked, will set Status to 'Archived' for all containers scanned once move is confirmed.  This will also inactivate the containers, but can they be reactivated for further use." );
    }

    my $label_field = $dbc->get_Label_field( -table => $type );

    my $prefix;
    if ( !$repeated ) {
        ## don't show these buttons more than once ##
        if ($slotted_box) {

            $prefix .= _reorder_header( -fill_by => $fill_by, -exclude => $exclude, -source_rack_option => $source_rack_option );    # (def_row, $def_col, $def_fill);

            my $pf = $dbc->barcode_prefix($type);
            my $sim_scan = 'Rac' . $rack . $pf . $ids;
            $sim_scan =~ s/\,/$pf/g;

            $prefix .= $q->hidden( -name => 'sim_scan', -value => $sim_scan, -force => 1 );
            $prefix .= '<hr>';
        }
    }

    $page .= $prefix;

    # Grab new rack info
    my ($new_rack) = $dbc->Table_find_array(
        'Rack LEFT JOIN Rack AS Slot ON Slot.FKParent_Rack__ID=Rack.Rack_ID AND Slot.Rack_Type = \'Slot\'',
        [ 'Rack.Rack_Name', 'Rack.Rack_Type', 'Rack.FKParent_Rack__ID', "CASE WHEN Slot.Rack_ID IS NULL THEN 0 ELSE 1 END AS Slotted" ],
        "WHERE Rack.Rack_ID = $rack"
    );
    my ( $new_rack_name, $new_rack_type, $parent_rack_id, $slotted ) = split /,/, $new_rack;
    my $new_rack_info;
    if ( $new_rack_type eq 'Slot' ) {
        $new_rack_info = get_FK_info( $dbc, 'FK_Rack__ID', $parent_rack_id );
        $new_rack_info .= " slot $new_rack_name";
    }
    else {
        $new_rack_info = get_FK_info( $dbc, 'FK_Rack__ID', $rack );
    }

    #    if ( $type !~ /(Plate|Library_Plate|Tube|Source)/ ) {
    #	if ($ids) { return "Moving: <B>$type ($ids) -> $new_rack_info.</B>" . vspace(5) }
    #	else { return }
    #    }

    my $old_info;
    if ( $type =~ /(Tube|Source)/i ) {
        ## these types can be moved into slots if desired ##

        my $type_table = $1;
        if ( $type_table eq 'Tube' ) { $type_table = 'Plate' }

        ## (Tubes and Sources have the added possibility of being stored in 'slots' within boxes) ##

        $old_info = $dbc->Table_retrieve(
            -table  => $type_table . ',Rack AS Child_Rack LEFT JOIN Rack AS Parent_Rack ON Child_Rack.FKParent_Rack__ID=Parent_Rack.Rack_ID',
            -fields => [
                $type_table . '_ID',
                'Child_Rack.Rack_ID AS Child_Rack_ID',
                'Child_Rack.Rack_Name AS Child_Rack_Name',
                'Child_Rack.Rack_Type AS Child_Rack_Type',
                'Parent_Rack.Rack_ID AS Parent_Rack_ID',
                'Parent_Rack.Rack_Name AS Parent_Rack_Name',
                'Parent_Rack.Rack_Type AS Parent_Rack_Type'
            ],
            -condition => "WHERE Child_Rack.Rack_ID = $type_table.FK_Rack__ID AND $type_table" . "_ID in ($ids)",
            -format    => 'AofH',
            -debug     => $debug
        );
    }
    elsif ($type) {

        #	$type ||= 'Plate';
        my $fk = "FK_Rack__ID";
        if ( $type =~ /Rack/ ) {
            $fk = "FKParent_Rack__ID";
        }
        $old_info = $dbc->Table_retrieve(
            "$type,Rack as Loc",
            [ "'$type.$type' as Type",
                "$type.${type}_ID",
                'Loc.FKParent_Rack__ID as Parent_Rack_ID',
                'Loc.Rack_ID as Child_Rack_ID',
                'Loc.Rack_Name as Child_Rack_Name',
                'Loc.Rack_Type as Child_Rack_Type'
            ],
            "WHERE Loc.Rack_ID=$type.$fk AND $type.${type}_ID in ($ids)",
            -format => 'AofH',
            -debug  => $debug
        );

        #	$fill_by = '';   ## cannot track to slots ##
    }
    else {
        return $dbc->session->error("Type of item to be moved is undefined");
    }

    $title ||= "$id_count '$type' Items for $new_rack_info ($rack_prefix$rack)";    # . alDente_ref('Rack',$rack,$dbc);

    my $table = HTML_Table->new( -title => $title, -border => 1 );
    my @headers = ( $type, 'Label' );
    if ($label_field) {
        push @headers, $label_field;
    }
    push @headers, ( 'From', 'To' );

    $table->Set_Headers( \@headers );

    my $prefill = 0;
    if ($old_info) { $prefill = scalar @$old_info }
    else           { Message("Warning: Problem finding previous location") }

    unless ($slot_choice) {
        $slot_choice = '';
    }

    my $order;
    if ($fill_by) { $order = $fill_by }

    my $dir = 'ASC';
    if ( $fill_by =~ /\bDESC/i ) {
        $dir = 'DESC';
    }

    my $empty_slots;
    if ($slotted) {
        $empty_slots = $Rack->get_slots(
            -dbc           => $dbc,
            -rack_id       => $rack,
            -empty_only    => 1,
            -order         => $order,
            -direction     => $dir,
            -prefill_count => $prefill,
            -count         => $id_count,
            -exclude       => $exclude,
            -blank         => 1,
        );
    }
    
    my @slots;
    if ($slots) { @slots = @$slots }
    ## if list of slots supplied... ##

    my $pf = $dbc->barcode_prefix($type);
    for ( my $i = 0; $i < scalar $prefill; $i++ ) {
        my $current;
        my $new;
        my $old_id;
        my $old_name;
        my $old_rack_type;

        my $old;

        my $barcode_id;
        my $barcode_value;
        my $j = 0;
        while ( !$barcode_id || ( $barcode_id != $id_list[$i] ) ) {
            ## skip ahead to the appropriate old_info record
            $old           = $old_info->[ $j++ ];
            $barcode_id    = $old->{"${type}_ID"};
            $barcode_value = $pf . $barcode_id;
            if ( $j > scalar(@$old_info) ) { $dbc->error("Location Information missing for some records"); return; }
        }

        if ( $old->{'Child_Rack_Type'} eq 'Slot' ) {

            # Display info of parent rack instead (Except rack type)
            $old_id        = $old->{'Parent_Rack_ID'};
            $old_name      = $old->{'Parent_Rack_Name'};
            $old_rack_type = $old->{'Child_Rack_Type'};
        }
        else {
            $old_id        = $old->{'Child_Rack_ID'};
            $old_name      = $old->{'Child_Rack_Name'};
            $old_rack_type = $old->{'Child_Rack_Type'};
        }

        $current .= '<B>' . get_FK_info( $dbc, 'FK_Rack__ID', $old_id ) . "</B>";
        $new .= '<B>' . $new_rack_info . '</B>';

        $current .= "<BR>Name: <B>$old_name</B>";
        $new     .= "<BR>Name: <B>$new_rack_name</B>";

        if ( $old_rack_type eq 'Slot' ) {
            $current .= "<BR>Slot: <B>$old->{Child_Rack_Name}</B>";
        }
        if ($empty_slots) {
            my $supplied_slot;
            if (@slots && $slots[$i]) {
                ($supplied_slot) = grep /^$slots[$i]$/i, @$empty_slots;
            }
            
            my $default_slot = $slot_choice || $supplied_slot || $Rack->next_slot( $rack, $i );    ## add on for empty option

            $Rack->reserve_slot( $rack, $default_slot );
            if ( !$supplied_slot && @slots ) {
                if ( $slots[$i] ) { $page .= $dbc->warning( "$slots[$i] is not empty - Assigning to $default_slot (or reassign)", -return_html => 1 ) }
                elsif ( !grep /\w/, @slots ) { }                                                                                                              ## $dbc->message('no slot assignments') }
                else                         { $page .= $dbc->warning( "No slot assignment for item $i - Assigning to $default_slot", -return_html => 1 ) }
            }

            if ( !$default_slot ) {
                my ($defined_slots) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FKParent_Rack__ID = $rack AND Rack_Type = 'Slot' ORDER BY Rack_ID" );

                if ($defined_slots) {
                    ## Ran out of space in box ##
                    my $warning_message = "Ran out of space after $i Items ($barcode_value... NOT moved)";
                    $dbc->session->warning($warning_message);
                    $table->Set_sub_header( $warning_message, 'lightredbw' );
                    $page .= $table->Printout(0);
                    return $page;
                }
            }
            
            if ($confirmed) {
                $new .= "<BR>Slot: <B>$default_slot</B>";
            }
            elsif ($scanner_mode) {
                $new .= "<BR>Slot: <B>"
                    . $q->textfield(
                    -name    => "$barcode_value.Slot",
                    -size    => 3,
                    -default => $default_slot,
                    -force   => 1
                    ) . "</B>";
            }
            else {
                $new .= "<BR>Slot: <B>" . $q->hidden( -name => 'ForceSearch', -value => 'Search', -force => 1 ) . $q->popup_menu(
                    -name    => "$barcode_value.Slot",
                    -values  => $empty_slots,
                    -default => $default_slot,

                    #-class   => 'narrow-txt',
                    -force => 1
                ) . "</B>";
            }
        }

        #    }

        $current .= "<BR>Type: <B>$old_rack_type</B>";
        $new     .= "<BR>Type: <B>$new_rack_type</B>";

        $new .= $q->hidden( -name => "$barcode_value.Target", -value => $rack, -force => 1 );

        my $ref = alDente_ref( $type, $barcode_id, -dbc => $dbc );
        my $cur_label;
        my @current_row = ( $q->hidden( -name => 'Move_Barcode', -value => $barcode_value, -force => 1 ) . $barcode_value, $ref );
        if ($label_field) {
            ($cur_label) = $dbc->Table_find( $type, $label_field, " WHERE $primary_field = $barcode_id" );
            push @current_row, $cur_label;
        }
        push @current_row, ( $current, $new );
        $table->Set_Row( \@current_row );
    }
    $page .= $table->Printout( $dbc->config('tmp_web_dir') . "/2." . timestamp() . ".html", $html_header );
    $page .= $table->Printout(0);

    $dbc->Benchmark('"end_move.$type.$rack"');

    return $page;
}

########################
sub _reorder_header {
########################
    my %args = filter_input( \@_ );

    my $fill_by            = $args{-fill_by};
    my $exclude            = $args{-exclude};
    my $source_rack_option = $args{-source_rack_option};

    my ( $def_fill, $def_row, $def_col );

    if    ( $fill_by =~ /^Match/i ) { $def_fill = 'Match Source Rack' }
    elsif ( $fill_by =~ /^Row/i )   { $def_fill = 'Rows First' }
    else                            { $def_fill = 'Columns First' }

    if   ( $fill_by =~ /Row (\w+)/i ) { $def_row = $1; }
    else                              { $def_row = 'ASC'; }

    if   ( $fill_by =~ /Column (\w+)/i ) { $def_col = $1 }
    else                                 { $def_col = 'ASC' }

    my $prefix;
    $prefix .= '<hr>';
    $prefix .= 'Order Rows: '
        . Show_Tool_Tip(
        $q->radio_group(
            -name    => 'Fill Rows',
            -value   => 'ASC',
            -default => $def_row,
            -force   => 1
        ),
        "Asc - <B>Top to Bottom</B> (eg a..h)"
        );
    $prefix .= Show_Tool_Tip(
        $q->radio_group(
            -name    => 'Fill Rows',
            -value   => 'DESC',
            -default => $def_row,
            -force   => 1
        ),
        "Desc - <B>Bottom to Top</B> (eg h..a)"
    );

    $prefix .= &hspace(20);
    $prefix .= 'Order Columns: '
        . Show_Tool_Tip(
        $q->radio_group(
            -name    => 'Fill Columns',
            -value   => 'ASC',
            -default => $def_col,
            -force   => 1
        ),
        "Asc - <B>Left to Right</B> (eg 1..9)"
        );
    $prefix .= Show_Tool_Tip(
        $q->radio_group(
            -name    => 'Fill Columns',
            -value   => 'DESC',
            -default => $def_col,
            -force   => 1
        ),
        "Desc - <B>Right to Left</B> (eg 9..1)"
    );

    $prefix .= &vspace(2);
    $prefix .= 'Fill: ';
    $prefix .= Show_Tool_Tip(
        $q->radio_group(
            -name    => 'Fill First',
            -value   => 'Rows First',
            -default => $def_fill,
            -force   => 1
        ),
        "eg a1,a2,a3 (if ascending order)"
    );

    $prefix .= Show_Tool_Tip(
        $q->radio_group(
            -name    => 'Fill First',
            -value   => 'Columns First',
            -default => $def_fill,
            -force   => 1
        ),
        "eg a1,b1,c1 (if ascending order)"
    );

    if ($source_rack_option) {
        $prefix .= Show_Tool_Tip(
            $q->radio_group(
                -name    => 'Fill First',
                -value   => 'Match Source Rack',
                -default => $def_fill,
                -force   => 1
            ),
            "eg a1,b1,c1 (if ascending order)"
        );
    }

    $prefix .= hspace(20);

    $prefix .= 'Exclude: ' . Show_Tool_Tip( $q->textfield( -name => 'Exclude', -default => $exclude, -size => 15 ), 'optionally indicate slots to skip or exclude.  Ranges are ok (eg a1-b12 or a1-h1)' );

    $prefix .= vspace(5);
    $prefix .= Show_Tool_Tip( $q->submit( -name => 'rm', -value => 're-Order Slots', -class => 'Std' ), "(click here to reload the default slot order)" );

    #
    #    Revert below would be helpful IF we can change the re-order above to work with javascript
    #
    #    $prefix .= vspace(5);
    #    $prefix .= reset( -name => 'Reset', -value => 'revert Order', -class => 'Std' );

    return $prefix;
}

####################
sub freezer_map {
####################
    my %args = filter_input( \@_, -args => 'dbc,equipment_id' );
    my $dbc = $args{-dbc};

    my $equipment_id = $args{-equipment_id};
    my $rack_id      = $args{-rack_id};

    my $page = alDente_ref( 'Equipment', $equipment_id, -dbc => $dbc );

    my $page_table = new HTML_Table(
        -border => 1,
        -title  => alDente_ref( 'Equipment', $equipment_id, -dbc => $dbc )
    );

    if ($equipment_id) {
        my @shelves = $dbc->Table_find( 'Rack', 'Rack_ID,Rack_Name', "WHERE FK_Equipment__ID=$equipment_id and Rack_Type = 'Shelf' ORDER BY CAST(Mid(Rack_Name,2,Length(Rack_Name)) AS UNSIGNED)" );
        foreach my $shelf (@shelves) {
            my ( $shelf_id, $shelf_name ) = split ',', $shelf;
            my @racks = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FKParent_Rack__ID='$shelf_id' and Rack_Type = 'Rack' ORDER BY CAST(Mid(Rack_Name,2,Length(Rack_Name)) AS UNSIGNED)" );

            my $table = new HTML_Table();

            my $content_header;
            if   (@racks) { $content_header = ' Racks on this Shelf:' }
            else          { $content_header = '(with no Racks)' }

            $table->Set_Row( [ $shelf_name, rack_barcode_img( $dbc, $shelf_id ), $content_header ], 'vlightbluebw' );
            my @row = ('');
            foreach my $rack (@racks) {
                push @row, rack_barcode_img( $dbc, $rack );
            }
            my @extra = $dbc->Table_find( 'Rack', 'Rack_Alias', "WHERE FKParent_Rack__ID='$shelf_id' and Rack_Type != 'Rack'" );
            my $extra_list = join '<LI>', @extra;
            if ($extra_list) { push @row, "<u>Out of Place</u>:<UL><LI>$extra_list</LI></UL>" }
            $table->Set_Row( \@row );

            $page_table->Set_Row( [ $table->Printout(0) ] );
        }
        my @extra = $dbc->Table_find( 'Rack', 'Rack_Alias', "WHERE FK_Equipment__ID=$equipment_id AND (FKParent_Rack__ID IS NULL OR FKParent_Rack__ID=0) AND Rack_Type != 'Shelf'" );
        my $extra_list = join '<LI>', @extra;
        if ($extra_list) { $extra_list = "<HR>Out of Place:<UL><LI>$extra_list</LI></UL>" }
        $page_table->Set_sub_header($extra_list);
    }
    else {
        Message("Freezer map currently only set up for equipment (requires equipment_id)");
        return;
    }

    return $page_table->Printout( $dbc->config('tmp_web_dir')  . "/Freezer_Map.$equipment_id.html" ) . $page_table->Printout(0);
}

###########################
sub rack_barcode_img {
###########################
    my %args    = filter_input( \@_, -args => 'dbc,rack_id' );
    my $dbc     = $args{-dbc};
    my $rack_id = $args{-rack_id};
    my $link    = $args{ -link };                                ## flag to indicate should be a link to rack home page...

    my ($alias) = $dbc->Table_find( 'Rack', 'Rack_Alias', "WHERE Rack_ID = $rack_id" );

    my $img = "Rack$rack_id.png";
    
    my $prefix = $dbc->barcode_prefix('Rack');
    
    my $Barcode = new alDente::Barcode(-dbc=>$dbc);    
    $Barcode->generate_barcode_image(
        -file  => $dbc->config('tmp_web_dir') ."/$img",
        -value => "$prefix$rack_id"
    );
    my $page = "$alias<BR><img src='/dynamic/tmp/$img'>";

    if ($link) {
        $page = Link_To( $dbc->config('homelink'), $page, "&Homepage=Rack&ID=$rack_id" );
    }
    return $page;
}

################################
sub generate_manifest_button {
################################
    my %args     = filter_input( \@_, -args => 'dbc,Prep' );
    my $dbc      = $args{-dbc};
    my $Prep     = $args{-Prep};
    my $set      = $args{-set};
    my $protocol = $args{-protocol} || 'Export';

    my $page = '<h2>Shipping Manifest</h2>';
    if ( $Prep && $set ) {

        ## show comments if applicable ##
        my $details = new HTML_Table( -title => "$protocol (details)", -width => '100%' );

        if ( defined $Prep->{'field_list'} ) {
            my $i = 0;
            foreach my $field ( @{ $Prep->{'field_list'} } ) {
                if ( $field eq 'Prep_Comments' ) {
                    $details->Set_Row( [ 'Comments:', $Prep->{'value_list'}[$i] ] );
                }
                $i++;
            }
        }

        ## show attributes if applicable ##
        if ( defined $Prep->{'prep_attr_field_list'} ) {
            my $i = 0;
            foreach my $attribute ( @{ $Prep->{'prep_attr_field_list'} } ) {
                $details->Set_Row( [ $Prep->{'prep_attr_field_list'}[$i], $Prep->{'prep_attr_value_list'}[$i] ] );
                $i++;
            }
        }

        my $details_table = $details->Printout(0) . '<hr>';

        my @boxes = $dbc->Table_find( 'Plate,Plate_Set', 'FK_Rack__ID', "WHERE FK_Plate__ID=Plate_ID AND Plate_Set_Number = '$set' ORDER BY FK_Rack__ID", -distinct => 1 );

        ## append Prep details to manifest page generated ##
        my $Shipment = new alDente::Shipment(-dbc=>$dbc);
        my $manifest = $Shipment->manifest_file( -rack => $boxes[0] );
        
        my ($shipment) = $dbc->Table_find( 'Shipment', 'Shipment_ID', "WHERE FKTransport_Rack__ID='$boxes[0]' ORDER BY Shipment_ID DESC", -limit => 1 );
        if ($shipment) { $page .= 'Shipment ' . alDente::Tools::alDente_ref( 'Shipment', $shipment, -dbc => $dbc ) . '<hr>' }

        my $manifest_target = "$manifest";
        if ( $protocol =~ /^Receive/i ) {
            $manifest_target =~ s/(sent|html)/rcvd/;    # "$manifest.rcvd";
        }
        else {
            $manifest_target =~ s/html/sent/;
        }

        if ( -e "$manifest" ) {
            my $manifest_page = `cat $manifest`;
            my $full_page     = new HTML_Table();
            $full_page->Set_Row( [$details_table] );
            $full_page->Set_Row( [$manifest_page] );
            $page .= $full_page->Printout( $dbc->config('tmp_web_dir')  . "/Manifest.$boxes[0].html" );
            $page .= $full_page->Printout(0);

            ## copy received manifest page back to shipping_manifests directory ##
            my $tmp = $dbc->config('tmp_web_dir') ;
            `cp $tmp/Manifest.$set.html $manifest_target.html`;
        }
        else {
            $page .= $details_table;
            $page .= " (current manifest text '$manifest' does not exist)";
        }
    }

    return $page;
}

######################
sub manifest_form {
######################
    my %args  = filter_input( \@_, -args => 'dbc' );
    my $dbc   = $args{-dbc};
    my $sr_id = $args{-sample_request_id};

    my ($today) = split ' ', date_time;
    my ( $key, $group, $contents ) = ( 'Plate.FK_Library__Name as Lib', 'Sample_Type.Sample_Type' );
    my $pick_source_content = pick_Source_Manifest_Content( -dbc => $dbc );
    my $pick_plate_content  = pick_Plate_Manifest_Content( -dbc  => $dbc );

    my $Form = new LampLite::Form(-dbc=>$dbc, -framework=>'bootstrap');
    
    $Form->append('Boxes to Ship:', $q->textfield( -name => 'Box_List', -placeholder=>'-- Scan Box(es) to Ship --') );
    $Form->append( $Form->View->prompt(-table=>'Shipment', -field=>'FKFrom_Grp__ID'));
    $Form->append( 'To: ', $q->textfield( -name => 'Target_Destination', -placeholder=>'-- Optional Addressee --', -tooltip=>'Optional receiver name/title' ));
    $Form->append( $Form->View->prompt(-table=>'Shipment', -field=>'FKTarget_Site__ID', -placeholder=>'-- Target Site --', -tooltip=>'Optional target site' ));
    $Form->append( $Form->View->prompt(-table=>'Shipment', -field=> 'FKTarget_Grp__ID', -default => '', -force => 1 ));
    $Form->append('Contents: ', $q->textfield(-name=>'Contents', -default=>$contents, -force=>1, -placeholder=>'-- Optional description of Contents --'));
    $Form->append('', $q->submit( -name => 'rm', -value => 'Generate Shipping Manifest', -class => 'Action', -force => 1, -onClick => 'return validateForm(this.form)' ) );
    $Form->append('', $q->checkbox( -name => 'Include Sample List', -checked => 1, -force => 1) , -no_format=>1);
 
    my $hidden = $q->hidden( -name => 'Key', -value => $key, -force => 1 ) 
        . $q->hidden( -name => 'Group', -value => $group, -force => 1 )
        . set_validator( -name => 'Box_List', -mandatory => 1, -prompt => "You must scan the BOX you wish to ship\nIf necessary, you may need to start off moving all samples to be shipped into a single barcoded box)\n" )
        . set_validator( -name => 'FKFrom_Grp__ID', -mandatory => 1, -prompt => "you must indicate the name of the GROUP SENDING these samples\n(use External if required)\n" )
        . set_validator( -name => 'FKTarget_Grp__ID', -mandatory => 1, -prompt => "you must indicate the name of the GROUP RECEIVING these samples\n(use External if required)\n" )
        . set_validator( -name => 'FKTarget_Site__ID', -mandatory => 1, -prompt => 'You must indicate the Target Site' );
        
    if ( !$sr_id ) {
        $Form->append( '', $q->checkbox( -name => 'Roundtrip', -label => 'Roundtrip Shipment', -checked => 0 , -tooltip=> "Only used if you are sending out items which will be sent back to you" ) , -no_format=>1);
        $Form->append( '', $q->checkbox( -name => 'Virtual', -label => 'Virtual Shipment', -checked => 0, -force => 1, -tooltip=> "Only used for shipment which never happened in reality" ) , -no_format=>1)
    }
    else {
        $hidden .= $q->hidden( -name => 'Roundtrip', -value => 'on', -force => 1 );
        $hidden .= $q->hidden( -name => 'sample_request_id', -value => $sr_id, -force => 1 );
    }
    
    my $start_tag = alDente::Form::start_alDente_form( $dbc, 'manifest' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 );
    my $form = $Form->generate(-open=>1, -close=>0, -tag=>$start_tag, -include=>$hidden);

    $form .= create_tree( -tree => { "Manifest Source Content" => $pick_source_content } );
    $form .= create_tree( -tree => { "Manifest Plate Content"  => $pick_plate_content } );
    $form .= "\n" . $q->end_form() . "\n";

    return $form;
}

################################
sub pick_Plate_Manifest_Content {
################################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};
    my $form;
    my $prompt;

    my @picked_fields = (
        'Plate.FK_Library__Name AS Library',
        'Plate.Plate_ID as Container_ID',
        'Plate.FK_Sample_Type__ID as Sample_Type',
        'CONCAT(Plate.Current_Volume,Plate.Current_Volume_Units) AS Quantity',
        'Plate.Plate_Comments as Plate_Comments',
        'Plate.FK_Plate_Format__ID as Plate_Format',
        'Plate.Plate_Label as Label',
        'Plate.FK_Rack__ID as Location',
        'Plate.Plate_Created as Created',
        'Plate.FK_Employee__ID as Created_By',
    );

    my @unpicked_fields
        = ( 'Plate.Parent_Quadrant as Parent_Quadrant', 'Plate.Plate_Parent_Well as Parent_Well', 'Plate.QC_Status as QC_Status', 'Plate.FKOriginal_Plate__ID as Sample', 'Plate.FK_Pipeline__ID as Pipeline', 'Plate.FK_Employee__ID as Created_By' );

    my $Reorder = new HTML_Table( -title => 'Plate Fields', -sortable => 1 );
    foreach my $field (@picked_fields) {
        if   ( $field =~ /AS (.+)/i ) { $prompt = $1 }
        else                          { $prompt = $field }
        $Reorder->Set_Row( [ $q->checkbox( -name => "ITEM $field", -label => $prompt, -checked => 1 ) . $q->hidden( -name => 'new_field_order', -value => "ITEM $field", -force => 1 ) ] );
    }
    foreach my $field (@unpicked_fields) {
        if   ( $field =~ /AS (.+)/i ) { $prompt = $1 }
        else                          { $prompt = $field }
        $Reorder->Set_Row( [ $q->checkbox( -name => "ITEM $field", -label => $prompt, -checked => 0 ) . $q->hidden( -name => 'new_field_order', -value => "ITEM $field", -force => 1 ) ] );
    }

    $form .= $Reorder->Printout(0);

    return $form;
}

################################
sub pick_Source_Manifest_Content {
################################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};
    my $form;

    my @picked_fields = (
        'Source.FK_Original_Source__ID AS Sample_Origin',
        'Source.Source_ID', 'Source.External_Identifier', 'Source.Source_Label',
        'Source.FK_Sample_Type__ID AS Sample_Type',
        'CONCAT(Source.Current_Amount,Source.Amount_Units) AS Amount',
        'Source.FK_Storage_Medium__ID AS Storage_Medium',
        'CONCAT(Source.Current_Concentration, Source.Current_Concentration_Units) AS Concentration',
        'Source.Current_Concentration_Measured_by',
        'Source.Notes', 'Source.FK_Plate_Format__ID AS Plate_Format',
    );
    my @unpicked_fields = (
        'Original_Source.FK_Anatomic_Site__ID as Tissue',
        'Original_Source.FK_Pathology__ID as Pathology',
        'CONCAT(Source.Storage_Medium_Quantity," ",Source.Storage_Medium_Quantity_Units) AS Storage_Medium_Amount',
        'Source.Xenograft', 'Source.FKReference_Project__ID AS Project',
    );

    my $Reorder = new HTML_Table( -title => 'Source Fields', -sortable => 1 );
    my $prompt;
    foreach my $field (@picked_fields) {
        if   ( $field =~ /AS (.+)/i ) { $prompt = $1 }
        else                          { $prompt = $field }
        $Reorder->Set_Row( [ $q->checkbox( -name => "ITEM $field", -label => $prompt, -checked => 1 ) . $q->hidden( -name => 'new_field_order', -value => "ITEM $field", -force => 1 ) ] );
    }
    foreach my $field (@unpicked_fields) {
        if   ( $field =~ /AS (.+)/i ) { $prompt = $1 }
        else                          { $prompt = $field }
        $Reorder->Set_Row( [ $q->checkbox( -name => "ITEM $field", -label => $prompt, -checked => 0 ) . $q->hidden( -name => 'new_field_order', -value => "ITEM $field", -force => 1 ) ] );
    }

    $form .= $Reorder->Printout(0);

    return $form;
}

## oLD
########################
sub shipping_manifest {
########################
    my %args             = filter_input( \@_, -args => 'dbc' );
    my $dbc              = $args{-dbc};
    my $rack             = $args{-rack};
    my $equipment        = $args{-equipment};
    my $since            = $args{'-since'};
    my $until            = $args{'-until'};
    my $id_list          = $args{-id_list};
    my $target           = $args{-to};
    my $target_site      = $args{-target_site};
    my $address          = $args{-from};
    my $content          = $args{-contents};                                                                   ## optional description of contents
    my $header           = $args{-header};
    my $extra_condition  = $args{-condition};
    my $shipper          = $args{-shipper} || $dbc->get_local('user_name') || '_________';
    my $key              = $args{-key} || "concat(Plate.FK_Library__Name,'-',Plate.Plate_Number) as Plate";    ## count contents by this key eg 'Original_Source_Name as Subject'
    my $group            = $args{-group} || 'Plate_Format_Type';                                               ## display summary grouped by this;
    my $debug            = $args{-debug};
    my $title            = $args{-title};
    my $include_box_list = $args{-include_box_list};
    my $sample_list      = $args{-sample_list};
    my $contents_only    = $args{-contents_only};
    my $save_set         = $args{-save_set};                                                                   ### need to save now so that manifest can be tied to this set

    my $Manifest;
    $Manifest = $rack->{Manifest} if $rack;

    my $key_name = $key;
    if ( $key =~ /(.+) as (.+)/ ) {
        $key      = $1;
        $key_name = $2;
    }

    my $plate_tables = 'Plate,Plate_Sample,Sample,Source,Original_Source,Sample_Type,Plate_Format,Rack,Equipment,Location';
    my $plate_condition
        = "WHERE Plate_Sample.FK_Sample__ID=Sample_ID AND Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate_Status = 'Active' AND Sample.FK_Source__ID=Source_ID AND Source.FK_Original_Source__ID=Original_Source_ID AND Plate.FK_Sample_Type__ID=Sample_Type_ID AND Plate.FK_Plate_Format__ID=Plate_Format_ID AND Plate.FK_Rack__ID=Rack_ID AND Rack.FK_Equipment__ID=Equipment_ID AND Equipment.FK_Location__ID=Location_ID";

    $title ||= "Items found";
    if ($since) { $title .= " (since $since)" }
    if ($until) { $title .= " (until $until)" }

    if ( $since && $since !~ /\:/ ) { $since .= ' 00:00:00' }
    if ( $until && $until !~ /\:/ ) { $until .= ' 23:59:59' }

    if ($since) { $extra_condition .= " AND Plate_Created >= '$since'" }
    if ($until) { $extra_condition .= " AND Plate_Created <= '$until'" }

    if ($id_list) {
        $title           .= " from specified list";
        $extra_condition .= " AND Plate_ID IN ($id_list)";
    }

    my $transport_container;
    if ($rack) {
        my $rack_id = $dbc->get_FK_ID( 'FK_Rack__ID', $rack );
        my $child_racks = join ',', alDente::Rack::get_child_racks( $dbc, $rack_id );
        $extra_condition .= " AND Plate.FK_Rack__ID IN ($child_racks)";
        $title           .= " in/on: '$rack'";
        $transport_container = alDente_ref( 'Rack', $rack, -dbc => $dbc );
    }
    if ($equipment) {
        my $equipment_id = $dbc->get_FK_ID( 'FK_Equipment__ID', $equipment );
        my $child_racks = join ',', alDente::Rack::get_child_racks( -dbc => $dbc, -equipment_id => $equipment_id );
        $extra_condition .= " AND Plate.FK_Rack__ID IN ($child_racks)";

        $title .= " in '$equipment'";
        $transport_container = alDente_ref( 'Equipment', $equipment, -dbc => $dbc );
    }
    if ( !$extra_condition ) {
        Message("Warning: must specify some conditions to generate shipping manifest");
        return;
    }

    my $condition .= $plate_condition . "$extra_condition";

    my $manifest_header = "Sample Manifest<P>";

    $manifest_header .= create_tree( -tree => { 'Search Conditions' => $title . '<P>' . 'WHERE ... ' . $extra_condition } );
    my @fields = ( "count(distinct $key) as ${key_name}_Records", "Max($key) as last_$key_name", "Min($key) as first_$key_name", 'Min(FK_Site__ID) as Min_Site', 'Max(FK_Site__ID) as Max_Site', "GROUP_CONCAT(Distinct Plate.FK_Rack__ID) as Box_List" );

    my %data = $dbc->Table_retrieve( $plate_tables, \@fields, "$condition", -debug => $debug + 1);
    my $width = '500';

    my $subjects = $data{ $key_name . '_Records' }[0];

    if ( !$subjects ) {
        $dbc->Table_retrieve( $plate_tables, \@fields, "$condition GROUP BY Plate_ID", -debug => $debug );

        return $dbc->session->warning("No Samples found using defined search criteria... try again<P>$manifest_header");
    }

    my $site_id = $data{"Max_Site"}[0];
    my $boxes   = $data{"Box_List"}[0];

    if ( $data{'Min_Site'}[0] ne $data{'Max_Site'}[0] ) {
        $dbc->session->warning( "different source sites found... (" . aleente_ref( 'Site', $data{Min_Site}[0], -dbc => $dbc ) . '..' . alDente_ref( 'Site', $data{Max_Site}[0], -dbc => $dbc ) );
    }

    my $Header = new HTML_Table( -width => $width );

    $Header->Set_Row( [ '<u>Date</u>: ' . date_time, hspace(50), "<u>Shipper</u>: $shipper" ] );

    if ( !$contents_only ) {
        my ($site_name) = $dbc->Table_find( 'Site', 'Site_Name', "WHERE Site_ID = $site_id" );
        my $source_address = alDente::Rack::get_Site_Address( $dbc, -site_id => $site_id ) || "(undefined address for Site $site_name)";

        my ($target_name) = $dbc->Table_find( 'Site', 'Site_Name', "WHERE Site_ID = $target_site" );
        my $target_address = alDente::Rack::get_Site_Address( $dbc, -site_id => $target_site );
        $target_address ||= "(undefined address for Site $target_name)";

        $Header->Set_Row( [ $address . '<BR>' . $site_name . '<P>' . $source_address, '', $target . '<BR>' . $target_name . '<P>' . $target_address ] );
    }

    $header .= $Header->Printout(0);

    my $page = new HTML_Table( -title => 'Shipping Manifest' );
    $page->Set_sub_header( $header . '<hr>' );

    my ( $plate_manifest, $plate_content_summary ) = plate_manifest( -dbc => $dbc, -subjects => $subjects, -key => $key_name, -condition => $condition, -group => $group, -debug => $debug );
    $page->Set_sub_header( $plate_content_summary . '<hr>' );
    $page->Set_Row( [$plate_manifest] );

    my $file = $dbc->config('tmp_web_dir') . "/shipping_manifest";

    $manifest_header .= $page->Printout("$file.html");
    $manifest_header .= $page->Printout("$file.xls");

    my $manifest = "<details></details>\n";    ## leave space at top of page for shipping manifest details ##

    $manifest .= $page->Printout(0);

    if ($sample_list) {
        $manifest .= '<HR>';
        $manifest .= plate_manifest();

        ## save text copy of manifest body ##
        my $Shipment = new alDente::Shipment(-dbc=>$dbc);
        my $manifest_file = $Shipment->manifest_file( -rack => $rack, -timestamp => timestamp() );

        if ($manifest_file) {
            open my $MANIFEST, '>', $manifest_file or die "CANNOT OPEN '$manifest_file'";
            print $MANIFEST $manifest;
            close $MANIFEST;

            ## set permissions ##
            `chown aldente:lims $manifest`;
            `chmod 771 $manifest_file`;
            $dbc->message("Saved copy of manifest to $manifest_file");
        }
        $manifest .= alDente::Form::start_alDente_form( $dbc, 'Shipping list' );
        $manifest .= $q->hidden( -name => 'cgi_application',   -value => 'alDente::Shipment_App',  -force => 1 );
        $manifest .= $q->hidden( -name => 'Site_ID',           -value => $target_site,             -force => 1 );
        $manifest .= $q->hidden( -name => 'Shipped_Container', -value => $rack,                    -force => 1 );
        $manifest .= $q->hidden( -name => 'Shipped_Boxes',     -value => $Manifest->{boxes},       -force => 1 );
        $manifest .= $q->hidden( -name => 'Plate_IDs',         -value => $Manifest->{plate_list},  -force => 1 );
        $manifest .= $q->hidden( -name => 'Source_IDs',        -value => $Manifest->{source_list}, -force => 1 );
        $manifest .= $q->hidden( -name => 'Rack_IDs',          -value => $Manifest->{rack_list},   -force => 1 );

        $manifest .= $q->submit( -name => 'rm', -value => 'Ship Samples', class => 'Action', -force => 1 );

        ## add new shipment form ##
        my $shipment_form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Shipment', -db_action => 'append', -wrap => 0 );
        $shipment_form->configure( -grey => { 'Shipment_Received' => '2010-02-02' } );
        $manifest .= $shipment_form->generate( -return_html => 1, -wrap => 0 );
        $manifest .= '.. included Shipment form';

        $manifest .= $q->end_form();

    }

    return $manifest_header . $manifest;
}
###########################
# Show in transit shipments
#
# Usage:	my $page = in_transit( -dbc => $dbc );
# Input:	-dbc			:	the database connection
#			-department		:	specify department name or id
#			-untracked		:	flag to include untracked export records
#			-shipping		:	flag to show shipping containers
#			-all_item		:	flag to show all items in transit
#			-all_shipments	:	flag to show all shipments in transit. It only shows in transit shipments specific to the current department if -all_shipments flag is off and no -department is passed in.
# Return:	HTML page of in transit shipments
###########################
####################
sub in_transit {
####################
    my %args          = filter_input( \@_, -args => 'dbc,department' );
    my $dbc           = $args{-dbc};
    my $department    = $args{-department};
    my $untracked     = $args{-untracked};                                ## include untracked export records ##
    my $shipping      = $args{-shipping};
    my $all_items     = $args{-all_items};
    my $all_shipments = $args{-all_shipments};

    if ($all_shipments) {                                                 # show all shipments
        $department = undef;
    }
    elsif ( !$department ) {                                              # deafult to current department
        $department = $dbc->config('Target_Department');
    }

    if ( $department && $department !~ /^\d+$/ ) {
        $department = $dbc->get_FK_ID( -field => 'FK_Department__ID', -value => $department );    # get the ID
    }
    require alDente::Shipment;
    my $objects = alDente::Shipment::get_Shippable_Objects( -dbc => $dbc );
    my ( $additional_tables, $additional_fields ) = _get_fields_and_condition( -dbc => $dbc, -objects => $objects );

    my $page;
    $page .= Link_To( $dbc->config('homelink'), ' Search Previous Shipments', '&cgi_application=SDB::DB_Object_App&rm=Search Records&Table=Shipment' ) . '<p ></p>';
    my $tables = 'Shipment LEFT JOIN Rack ON FKTransport_Rack__ID=Rack.Rack_ID LEFT JOIN Shipped_Object ON FK_Shipment__ID=Shipment_ID LEFT JOIN Object_Class ON FK_Object_Class__ID=Object_Class_ID'
        . " LEFT JOIN Grp from_grp on FKFrom_Grp__ID = from_grp.Grp_ID LEFT JOIN Grp to_grp on to_grp.Grp_ID = FKTarget_Grp__ID $additional_tables ";
    my $conditions = "WHERE Shipment_Status = 'Sent' ";

    my @fields = ( 'Shipment_ID as Shipment', 'GROUP_CONCAT(DISTINCT Object_Class) as Item_Type' );
    if ($additional_fields) {
        push @fields, @$additional_fields;
    }

    push @fields, ( 'FKTransport_Rack__ID as Transport_Container', 'Shipment_Sent', 'FKSender_Employee__ID as Sent_By', 'FKFrom_Grp__ID as From_Grp', 'FKTarget_Grp__ID as Target_Grp', 'Addressee', 'FK_Contact__ID as Contact' );

    if ($department) {
        ## separate outbound and inbound shipments
        my $dep_name = $dbc->get_FK_info( 'FK_Department__ID', $department );
        $page .= $dbc->Table_retrieve_display(
             $tables, \@fields, $conditions . " AND to_grp.FK_Department__ID = $department ",
            -group       => 'Shipment_ID',
            -title       => "Tracked Incoming Transit items for $dep_name",
            -alt_message => "No currently tracked incoming shipments for $dep_name",
            -return_html => 1
        );
        $page .= vspace(5);
        $page .= $dbc->Table_retrieve_display(
             $tables, \@fields, $conditions . " AND from_grp.FK_Department__ID = $department ",
            -group       => 'Shipment_ID',
            -title       => "Tracked Outbound Transit items from $dep_name",
            -alt_message => "No currently tracked outbound shipments from $dep_name",
            -return_html => 1
        );
    }
    else {
        $page .= $dbc->Table_retrieve_display( $tables, \@fields, $conditions, -group => 'Shipment_ID', -title => "Tracked Shipments In Transit", -alt_message => 'No currently tracked shipments in transit', -return_html => 1 );
    }

    if ($shipping) {
        $page .= '<HR>';
        $page .= show_Shipping_Containers($dbc);
    }

    if ($all_items) {
        $page .= '<hr>';
        $page .= show_Items_in_Transit($dbc);

        $page .= '<hr>';
        $page .= $dbc->message( "The following items have been received on Site, but have not been tracked to a storage location", -hide => 1 );
        $page .= show_Items_in_Transit( $dbc, 'In Limbo' );
    }

    if ($untracked) {
        $page .= '<hr>';

        $page .= $dbc->Table_retrieve_display(
            'Plate,Plate_Prep,Prep,Rack',
            [ 'FK_Plate_Set__Number', 'count(*) as Containers', 'Prep_DateTime as Shipped' ],
            "WHERE Plate_Prep.FK_Plate__ID=Plate_ID AND Plate_Prep.FK_Prep__ID=Prep_ID AND Plate.FK_Rack__ID=Rack_ID AND Prep_Name like 'Export%' AND Plate_Status = 'Exported' AND Rack_Name = 'Exported' GROUP BY FK_Plate_Set__Number,Prep_DateTime",
            -title       => 'Containers Exported (Untracked)',
            -return_html => 1
        );
    }

    $page .= '<hr>Regenerate Detailed Information for Shipped Samples:<P>';
    $page .= alDente::Form::start_alDente_form( $dbc, 'in_transit' );
    $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 );
    $page .= $q->checkbox( -name => 'Show Untracked Items',          -checked => 0 ) . '<BR>';
    $page .= $q->checkbox( -name => 'Show Shipping Containers',      -checked => 1 ) . '<BR>';
    $page .= $q->checkbox( -name => 'Show all Items in Transit',     -checked => 1 ) . '<BR>';
    $page .= $q->checkbox( -name => 'Show all in Transit Shipments', -checked => 0 ) . '<BR>';
    $page .= '<p ></p>';
    $page .= $q->submit( -name => 'rm', -value => 'View Items in Transit', -class => 'Search', -force => 1 );
    $page .= $q->end_form();

    return $page;

}

####################################
sub show_Shipping_Containers {
####################################
    my $dbc = shift;

    my $page = '<h2>Shipping Containers</h2>';

    $page .= '<P>';
    $page .= &Link_To( $dbc->config('homelink'), 'Define New Shipping Container', '&cgi_application=alDente::Rack_App&rm=Define+Shipping+Container' );

    $page .= '<p ></p><i>To receive these items begin by simply scanning in the transport / storage container</i>' . vspace(2);

    $page .= create_tree(
        -tree => {
            'Shipping Containers' => $dbc->Table_retrieve_display(
                'Rack,Equipment,Location',
                [ 'Rack_ID', 'Rack_Alias', 'FK_Location__ID', 'FK_Site__ID' ],
                "WHERE FK_Equipment__ID=Equipment_ID AND FK_Location__ID=Location_ID AND Rack_Name = Rack_Alias AND Movable = 'Y'",
                -return_html => 1
            )
        }
    );
    return $page;
}

################################
sub show_Items_in_Transit {
################################
    my $dbc = shift;
    my $status = shift || 'In Transit';

    my $equipment_name = $status;
    if ( $status =~ /limbo/i ) {
        $equipment_name = 'Site-%';
    }

    my $page = "<h2>Items $status</h2>";

    $page .= '<P>';
    $page .= $dbc->Table_retrieve_display(
        'Rack,Equipment LEFT JOIN Shipment ON Shipment.FKTransport_Rack__ID=Rack_ID', [ 'Rack_Alias', 'Rack_ID as Rack_ID', 'Shipment_ID as Shipment', 'Shipment_Sent', 'Shipment_Received', 'FKRecipient_Employee__ID', 'Addressee' ],
        "WHERE FKParent_Rack__ID = 0 AND Equipment_ID=FK_Equipment__ID AND Equipment_Name like '$equipment_name'",
        -title       => "Boxes $status",
        -return_html => 1,
        -alt_message => "No storage containers currently $status",
    );
    $page .= '<P>';
    $page .= '<hr>';

    my @types = ( 'Plate', 'Source' );
    foreach my $type (@types) {
        
        my @fields = ( "count(*) as ${type}s", "CASE WHEN Rack_Type = 'Slot' THEN FKParent_Rack__ID ELSE Rack_ID END as Rack" );
        my $folders;
        if ($type eq 'Plate') { 
            push @fields, , ("Group_Concat(DISTINCT FK_Library__Name) as Library", "Group_Concat(DISTINCT Plate_Label) as Labels");
            $folders = "Labels,Libs";
        }
        elsif ($type eq 'Source') { 
            push @fields, "Group_Concat(DISTINCT Source_Label) as Labels";
            $folders = 'Labels';
        }
               
        my $items = $dbc->Table_retrieve_display(
            "$type,Rack,Equipment",
            \@fields,
            "WHERE $type.FK_Rack__ID=Rack_ID AND Rack.FK_Equipment__ID=Equipment_ID AND Equipment_Name like '$equipment_name' GROUP BY Rack",
            -title       => "${type}s $status",
            -return_html => 1,
            -list_in_folders=>$folders,
            -alt_message => "No $type records $status"
        );

        $page .= $items;
        $page .= '<hr>';
    }
    $page .= '<P>';
    $page .= $dbc->Table_retrieve_display(
        'Equipment', [ 'Equipment_ID', 'Equipment_Name' ],
        "WHERE Equipment_Status = '$status'",
        -title       => "Equipment $status",
        -return_html => 1,
        -alt_message => "No equipment currently $status",
    );
    $page .= '<P>';
    $page .= '<hr>';

    return $page;
}

#
# Generate output showing manifest for given Rack(s).
#
# This assumes that the build_manifest method has been called.
#
# Return: html output
#######################
sub view_manifest {
#######################
    my %args = filter_input( \@_ );

    my $Rack             = $args{-Rack};
    my $Shipment         = $args{-Shipment};                      ## IF manifest is prepared for shipment
    my $header           = $args{-header};
    my $debug            = $args{-debug};
    my $title            = $args{-title};
    my $include_box_list = $args{-include_box_list};
    my $sample_list      = $args{-sample_list};
    my $contents_only    = $args{-contents_only};
    my $contents         = $args{-contents};
    my $Manifest         = $Rack->{Manifest};
    my $scope            = $args{-scope} || $Manifest->{scope};
    my $dbc              = $args{-dbc} || $Rack->{dbc};

    my $manifest_header = "<H1>Manifest </H1>";
    if ($scope) { $manifest_header .= "Scope: <B>$scope</B><P>" }

    ## Generate Manifest (starting with overview / summary) ##
    my $Manifest_table = generate_manifest_Table( -Rack => $Rack, -Shipment => $Shipment, -contents => $contents, -header => $header );

    my @types = ( @{ $Manifest->{item_types} } );
    foreach my $type (@types) {
        generate_manifest_summary( -Rack => $Rack, -type => $type, -sample_list => $sample_list );

        if ( $Manifest->{"${type}_overview"} ) {
            $Manifest_table->Set_sub_header( $Manifest->{"${type}_summary"} . $Manifest->{"${type}_overview"} );
            $dbc->message("Add $type overview / summary");
        }
    }

    my $file = $dbc->config('tmp_web_dir') . "/shipping_manifest";

    $manifest_header .= $Manifest_table->Printout("$file.html");

    my $manifest = "<details></details>\n";    ## leave space at top of page for shipping manifest details ##
    $manifest .= $Manifest_table->Printout(0);

    ## Add itemized manifest if desired ##
    if ($sample_list) {

        foreach my $type (@types) {
            if ( $Manifest->{"${type}_manifest"} && ( $Manifest->{"${type}_manifest"} !~ /\bNo records/ ) ) {
                my $records = int( @{ $Manifest->{"${type}_list"} } );
                $manifest .= '<HR>' . create_tree( -tree => { "$type Manifest [$records records]" => $Manifest->{"${type}_manifest"} } );
            }
        }

        #$LOGBASE, convert_date( &date_time(), 'YYYY/MM/DD'), '777' );
        my $month = convert_date( date_time(), 'YYYY/MM' );

        ## Note: Shipment manifests simply link to these Rack manifest files ##
        my $Shipment = new alDente::Shipment(-dbc=>$dbc);
        my $manifest_file = $Shipment->manifest_file( -timestamp => timestamp(), -scope => $scope );

        $dbc->message("Generating manifest: $manifest_file");

        ## save text copy of manifest body ##
        open my $MANIFEST, '>', $manifest_file or return "CANNOT OPEN '$manifest_file'";
        print $MANIFEST $manifest;
        close $MANIFEST;

        $Manifest->{filename} = $manifest_file;
        ## set permissions ##
        `chown aldente:lims $manifest`;
        `chmod 771 $manifest_file`;
        $dbc->message("Saved Manifest: $manifest_file");
    }

    return $manifest_header . $manifest;
}

#
# Return HTML_Table with header for manifest
#
#################################
sub generate_manifest_Table {
#################################
    my %args     = filter_input( \@_ );
    my $Rack     = $args{-Rack};
    my $Shipment = $args{-Shipment};
    my $header   = $args{-header};
    my $contents = $args{-contents};

    my $Manifest = $Rack->{Manifest};

    my $dbc            = $Rack->{dbc};
    my $target         = $Shipment->{target};
    my $target_site_id = $Shipment->{target_site};
    my $shipper        = $Shipment->{shipper};

    my $source_grp;
    my $target_grp;
    $source_grp = ' [' . $dbc->get_FK_info( 'FK_Grp__ID', $Shipment->{source_grp} ) . '] ' if $Shipment->{source_grp};
    $target_grp = ' [' . $dbc->get_FK_info( 'FK_Grp__ID', $Shipment->{target_grp} ) . '] ' if $Shipment->{target_grp};
    my $user = $dbc->get_local('user_name');
    
    my $Table;
    if ($target_site_id) {
        ## shipping manifest ##
        $Table = new HTML_Table( -title => "Shipping Manifest" );

        ## Generate Header with source and target address information ##
        my $Header = new HTML_Table( -width => 500);
        $Header->Set_Headers( [ "<B>Shipper</B>: $shipper", ' -> ', '<B>Destination:</B>' ], 'mediumgray' );

        my ($site_name) = $dbc->Table_find( 'Site', 'Site_Name', "WHERE Site_ID = " . $dbc->config('site_id') );
        my $source_address = alDente::Rack::get_Site_Address( $dbc, -site_id => $dbc->config('site_id') ) || "(undef address)";

        my ($target_name) = $dbc->Table_find( 'Site', 'Site_Name', "WHERE Site_ID = $target_site_id" );
        my $target_address = alDente::Rack::get_Site_Address( $dbc, -site_id => $target_site_id );
        $target_address ||= "(undefined address for Site $target_name)";

        $Header->Set_Row( [ $user . $source_grp . '<BR>' . $site_name, ' ', $target . $target_grp . '<BR>' . $target_name ] );
        $Header->Set_Row( [ $source_address, ' ', $target_address ] );
        $header .= $Header->Printout(0);

        $Table->Set_sub_header( $header . '<hr>' );
        $Table->Set_Row( [ '<u>Date</u>: ', date_time ] );
        if ($contents) { $Table->Set_Row( [ 'Contents: ', $contents ] ) }

    }
    else {
        ## general (non-shipping) manifest ##
        $Table = new HTML_Table( -title => "Standard Manifest" );
        $Table->Set_Row( [ '<u>Date</u>: ', date_time ] );
    }
    return $Table;
}

#
# Overview of items in manifest
#
#  Data extracted is content specific so variables differ depending upon 'type' of items in manifest
#
# Currently supports Plate and Source items.
#
# * populates summary, overview and manifest attributes)
# * generates full manifest for indicated item type
#
###################################
sub generate_manifest_summary {
###################################
    my %args = filter_input( \@_ );
    my $Rack = $args{-Rack};

    my $debug = $args{-debug};
    my $type  = $args{-type} || 'Plate';
    my $title = $args{-title} || "$type Manifest";
    my $key = $args{-key};

    my $dbc      = $Rack->{dbc};
    my $Manifest = $Rack->{Manifest};

    #    my $condition = $Manifest->{manifest_condition};   ## condition reinitialized below...

    my $include_box_list = 1;

    my $width = '500';
    my $summary;


    my ( $tables, $condition, @group, $location, $volume, $volume_units );    ## Define type specific variables
    $tables    = 'Equipment,Location,Rack';
    $condition = "WHERE Rack.FK_Equipment__ID=Equipment_ID AND Equipment.FK_Location__ID=Location_ID AND Rack_ID IN ($Manifest->{child_racks})";

    if ( $type eq 'Plate' ) {
        $Manifest->{Plate_tables}     = 'Plate,Plate_Format, Sample_Type';
        $Manifest->{Plate_conditions} = 'Plate_Format_ID = Plate.FK_Plate_Format__ID AND Plate.FK_Sample_Type__ID=Sample_Type_ID';

        $key ||= "Plate_Label"; ## concat(Plate.FK_Library__Name,'-',Plate.Plate_Number) as Plate";    ## count contents by this key eg 'Original_Source_Name as Subject'
        $location     = 'Plate.FK_Rack__ID';
        $volume       = 'Plate.Current_Volume';
        $volume_units = "${volume}_Units";
        @group        = ('Plate_Format.Plate_Format_Type', 'Sample_Type.Sample_Type');

        $tables    .= ',' . $Manifest->{Plate_tables};
        $condition .= " AND $Manifest->{Plate_conditions} AND $location=Rack_ID";
    }
    elsif ( $type eq 'Source' ) {
        $Manifest->{Source_tables}     = 'Source,Original_Source,Anatomic_Site,Plate_Format';
        $Manifest->{Source_conditions} = 'Source.FK_Original_Source__ID=Original_Source_ID AND FK_Anatomic_Site__ID=Anatomic_Site_ID';

        $key ||= 'Anatomic_Site.Anatomic_Site_Alias as Anatomic_Site';
        $location     = 'Source.FK_Rack__ID';
        $volume       = 'Source.Current_Amount';
        $volume_units = 'Source.Amount_Units';
        @group        = ('Source.FK_Sample_Type__ID');
        $tables    .= ',' . $Manifest->{Source_tables};
        $condition .= " AND $Manifest->{Source_conditions} AND $location = Rack_ID";
    }
    elsif ($type eq 'Rack') { 
        ## ignore internal Rack items (eg slot records) ##
        return;
    }
    else {
        $dbc->message("$type items not available in manifest");
        return;
    }

    my $key_name = $key;
    if ( $key =~ /(.+) as (.+)/ ) {
        $key      = $1;
        $key_name = $2;
    }

    my @fields = ( "count(distinct $key) as ${key_name}_Records", "Max($key) as last_$key_name", "Min($key) as first_$key_name", 'Min(FK_Site__ID) as Min_Site', 'Max(FK_Site__ID) as Max_Site', "GROUP_CONCAT(Distinct $location) as Box_List" );

    my %data = $dbc->Table_retrieve( $tables, \@fields, $condition, -debug => $debug );
    my $subjects = $data{ $key_name . '_Records' }[0];    ## eg N Plate_Records

    if ( $data{'Min_Site'}[0] ne $data{'Max_Site'}[0] ) {
        $dbc->session->warning( "different source sites found... (" . alDente::Tools::alDente_ref( 'Site', $data{Min_Site}[0], -dbc => $dbc ) . '..' . alDente::Tools::alDente_ref( 'Site', $data{Max_Site}[0], -dbc => $dbc ) );
    }

    if ( !$subjects ) {
        $dbc->Table_retrieve( $tables, \@fields, "$condition GROUP BY ${type}_ID", -debug => $debug );

        return;    ##  $dbc->session->warning("No Samples found using defined search criteria... try again");
    }

    my $boxes = $data{"Box_List"}[0];

    ## Generate Plate overview ##
    
    my $group = join ',', @group;
    my $section = $dbc->Table_retrieve_display(
        $tables,
        [ @group,
            "Sum(Wells)/count(*) as Samples_per_$key_name",
            "count(*) as ${key_name}_count",
            "sum(CASE WHEN $volume_units='ul' then $volume/1000 WHEN $volume_units = 'ml' then $volume ELSE NULL END) as Total_Volume_in_mL"
        ],
        "$condition GROUP BY $group",
        -return_html   => 1,
        -width         => '100%',
        -border        => 1,
        -total_columns => "${key_name}_count,Samples,Total_Volume_in_mL",
        -debug         => $debug
    );

    $Manifest->{"${type}_overview"} = $section;

    ## Generate Plate summary ##
    my $first_subject = $data{"first_$key_name"}[0];
    my $last_subject  = $data{"last_$key_name"}[0];

    my $plate_summary = new HTML_Table( -title => "<u>$type Content Summary</u>", -width => $width );

    $plate_summary->Set_Row( [ "$key_name Records:", $subjects ] );
    if   ( $first_subject eq $last_subject ) { $plate_summary->Set_Row( [ "$key_name:", $first_subject ] ) }
    else                                     { $plate_summary->Set_Row( [ "$key_name:", "$first_subject ... $last_subject" ] ) }

    if ($include_box_list) {

        my @boxes_only = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_ID IN ($boxes) AND Rack_Type != 'Slot'", -distinct => 1 );
        my @parents = $dbc->Table_find( 'Rack', 'FKParent_Rack__ID', "WHERE Rack_ID IN ($boxes) AND Rack_Type = 'Slot'", -distinct => 1 );
        my $list = &RGmath::union( \@boxes_only, \@parents );
        my $list_string = join ', ', @{$list};
        $Manifest->{shipped_boxes} = $list_string;
        $plate_summary->Set_Row( [ 'Box List:', $list_string ] );
    }
    $summary = $plate_summary->Printout(0);
    $Manifest->{"${type}_summary"} = $summary;

    return;
}

#######################
sub print_options {
#######################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my @valid_labels = $dbc->Table_find( "Barcode_Label", "Label_Descriptive_Name", "WHERE Barcode_Label_Type like 'rack' AND Barcode_Label_Status='Active'" );
    unshift( @valid_labels, '--Select--' );

    my $page
        = alDente::Form::start_alDente_form( $dbc, 'reprint' )
        . $q->submit( -name => 'rm', -value => "Re-Print Rack Barcode", -class => "Std", -force => 1 )
        . $q->hidden( -name => "cgi_application", -value => 'alDente::Rack_App', -force => 1 )
        . $q->hidden( -name => "Rack_ID", -value => $id, -force => 1 )
        . $q->popup_menu( -name => "Barcode Name", -values => \@valid_labels, -force => 1 )
        . $q->end_form();

    return $page;
}

######################################################
sub view_Relocation_History {
######################################################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $id   = $args{-id};
    my $class = $args{-class};
    my $dbc  = $args{-dbc} || $self->dbc();
    
    my $barcode_prefix = $dbc->barcode_prefix($class);
    
    my $ids = Cast_List(-list=>$id, -to=>'string',-autoquote=>1);
    return $dbc->Table_retrieve_display(
        "$class, Change_History, DBField, Rack as FromRack, Rack as ToRack", 
        ["${class}_ID as ${barcode_prefix}_ID", "${class}_ID as $class", 'Change_History.FK_Employee__ID as Employee', 'Modified_Date', 'FromRack.FK_Equipment__ID as From_Freezer', 'FromRack.Rack_Alias as From_Position', 'ToRack.FK_Equipment__ID as To_Freezer', 'ToRack.Rack_Alias as To_Position'],
        "WHERE Change_History.FK_DBField__ID=DBField_ID AND DBField.Field_Table = '$class' AND Field_Name = 'FK_Rack__ID' AND Change_History.Record_ID = $class.${class}_ID AND FromRack.Rack_ID=Old_Value AND ToRack.Rack_ID=Round(New_Value) AND Plate_ID IN ($ids)",
        -title=> "Relocation History for $barcode_prefix $id", 
        -order => "Change_History.Modified_Date",
        -return_html=>1);    
}

######################################################
##         Private                                  ##
######################################################

####################
sub _get_fields_and_condition {
####################
    my %args    = filter_input( \@_, -args => 'dbc,department' );
    my $dbc     = $args{-dbc};
    my $objects = $args{-objects};
    my @fields;
    my $tables;
    unless ($objects) {return}

    for my $object (@$objects) {
        my ($id) = $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE Object_Class = '$object'" );
        unless ($id) {next}
        my ($primary) = $dbc->get_field_info( $object, undef, 'PRI' );
        $tables .= " LEFT JOIN $object as O$object ON O$object.$primary = Object_ID AND FK_Object_Class__ID = $id ";
        push @fields, "COUNT(DISTINCT O$object.$primary) as $object";
    }

    return ( $tables, \@fields );
}

sub plate_manifest {

}

############################
#
# Display failed objects and ask user to confirm to include in manifest
#
############################
sub prompt_to_confirm_manifest {
############################
    my %args          = filter_input( \@_, -mandatory => 'dbc,failed,manifest_info' );
    my $dbc           = $args{-dbc};
    my $failed        = $args{-failed};
    my $manifest_info = $args{-manifest_info};
    my $page          = alDente::Form::start_alDente_form( $dbc, 'verify' );

    if ($failed) {
        foreach my $obj ( keys %$failed ) {
            my $failed_count = int( @{ $failed->{$obj} } );
            my $failed_ids = join ',', @{ $failed->{$obj} };
            my ( $table, @fields, $conditions );
            if ( $obj =~ /Plate/xmsi ) {
                $table      = 'Plate LEFT JOIN Plate_Tray ON Plate_Tray.FK_Plate__ID = Plate_ID';
                @fields     = ( 'Plate_ID', 'FK_Library__Name', 'Plate_Status', 'Failed', 'Plate_Position' );
                $conditions = "WHERE Plate_ID in ($failed_ids)";
            }
            $page .= "<font class=panel-title>$failed_count $obj are Failed: </font>";
            $page .= $dbc->Table_retrieve_display( $table, \@fields, $conditions, -title => "Failed $obj", -return_html => 1 );
        }
        $page .= "<BR><font class=text-warning>";
        $page .= "Click 'Abort' if you don't want them to be shipped, move them out of the shipping container, and re-do this step<BR>";
        $page .= "Click 'Continue Generating Shipping Manifest' if you want to include the above Failed objects in the manifest and shipment";
        $page .= "</font>" . vspace(5);
        $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 );
        $page .= $q->submit( -name => 'rm', -value => 'Abort', -force => 1, -class => 'Action' );
        $page .= hspace(10) . $q->submit( -name => 'rm', -value => 'Continue Generating Shipping Manifest', -force => 1, -class => 'Action' );
        $page .= Safe_Freeze( -name => "Manifest_Info", -value => $manifest_info, -format => 'hidden', -encode => 1 );
        $page .= $q->hidden( -name => 'Rack_ID', -value => $manifest_info->{Rack_object}{Manifest}{child_racks}, -force => 1 );
    }

    $page .= end_form();
    return $page;
}

return 1;
