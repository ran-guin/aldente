###################################################################################################################################
# alDente::Box_Viewa.pm
#
#
#
#
###################################################################################################################################
package alDente::Box_Views;
use base alDente::Object_Views;

use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use alDente::QC_Batch;
use alDente::Stock_Views;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::Conversion;

## alDente modules
use alDente::Box;
use vars qw();

#############################
sub display_record_page {
#############################
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'Object' );
    my $dbc    = $self->{dbc};
    my $Box    = $args{-Object} || $self->Model;
    my $box_id = $Box->{id};                               #|| $self->{id};

## display record page not set up properly for boxes. commented it out for now, using box views home page until fixed.

=cut
    my ( $centre, $right, $options, @layers);
    $right               = $self->current_Contents( -dbc => $dbc, -box_id => $box_id, -Box => $Box );
    $centre              = $self->extra_actions( -dbc => $dbc, -box_id => $box_id, -Box => $Box );
    push @layers, {'Add Items' => $self->extract_New_items( -dbc      => $dbc, -box_id => $box_id, -Box => $Box )};
    push @layers, {'Extract'   => $self->extract_Existing_items( -dbc => $dbc, -box_id => $box_id, -Box => $Box )};

    return $self->SUPER::display_record_page(
        -centre => $centre,
        -layers  => \@layers,
        -right => $right
    );
=cut

    $self->home_page( -dbc => $dbc, -Box => $Box, -id => $box_id );
}

####################
sub extract_New_items {
####################
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $dbc    = $self->{dbc};
    my $Box    = $args{-Box} || $self->Model;
    my $box_id = $Box->{id};                    #|| $self->{id};
    my $page;
    my $name = $Box->value('Stock_Catalog_Name');
    $page .= Views::Heading("Extracting new items (to be barcoded)");
    my $org = $Box->value('Stock_Catalog.FK_Organization__ID');

    if ( !$scanner_mode ) {
        my %labels;
        $labels{Reagent} = 'Standard Reagent';

        $page .= '<hr>';
        $page .= &alDente::Form::start_alDente_form( $dbc, 'ExtractFromBox' );
        $page .= hidden( -name => 'Box_ID', -value => $box_id, -force => 1 );
        $page .= hidden( -name => 'cgi_application', -value => 'alDente::Stock_App', -force => 1 );
        $page .= submit( -name => 'rm', -value => 'Extract New Stock from Box', -force => 1, -class => "Std" ) . vspace;
        $page .= "(only for new items that have NOT been extracted from this type of Box)" . vspace . "Otherwise, use other layer" . vspace;

        $page .= radio_group( -name => 'Boxed Items', -values => [ 'Reagent', 'Buffer', 'Primer', 'Matrix' ], -linebreak => 0, -labels => { Reagent => 'Standard Reagent' } ) . br();
        $page .= radio_group( -name => 'Boxed Items', -values => [ 'Box', 'Kit' ], -linebreak => 0 ) . br();
        $page .= radio_group( -name => 'Boxed Items', -values => ['Microarray'], -linebreak => 0 ) . br();

        ## add parameters for Stock retrieval run mode ##
        $page .= hidden( -name => 'FK_Box__ID', -value => $box_id, -force => 1 ) . hidden( -name => 'Stock_Source', -value => 'Box', -force => 1 ) . hidden( -name => 'FKManufacturer_Organization__ID', -value => $org, -force => 1 ) . end_form();
    }
    $page .= &vspace(4);

    return $page;
}

####################
sub extract_Existing_items {
####################
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $dbc    = $self->{dbc};
    my $Box    = $args{-Box} || $self->Model;
    my $box_id = $Box->{id};                    #|| $self->{id};
    my $page;
    my $name    = $Box->value('Stock_Catalog_Name');
    my $box_cat = $Box->value('Stock_Catalog.Stock_Catalog_Number');
    my $rcvd    = $Box->value('Stock_Received');
    my $exp     = $Box->value('Box_Expiry');
    my $rack    = $Box->value('FK_Rack__ID');
    require alDente::Barcoding;

    my $similar_boxes = join ',',
        $dbc->Table_find( 'Box,Stock,Stock_Catalog', 'Box_ID as ID',
        "WHERE FK_Stock_Catalog__ID = Stock_Catalog_ID and FK_Stock__ID=Stock_ID AND (Stock_Catalog_Name = \"$name\" OR (Stock_Catalog.Stock_Catalog_Number='$box_cat' AND Length(Stock_Catalog.Stock_Catalog_Number)>0)) ORDER BY Stock_Received DESC" );

    my %Last = $dbc->Table_retrieve(
        'Stock,Stock_Catalog',
        [ 'Stock_ID as ID', 'Stock_Catalog.Stock_Catalog_Number as Cat', 'Stock_Catalog_Name', 'FK_Grp__ID as Grp', 'Stock.FK_Barcode_Label__ID as Label', 'Stock_Type', 'Stock_Catalog_ID' ],
        "WHERE Stock_Catalog_ID = FK_Stock_Catalog__ID and FK_Box__ID in ($similar_boxes) AND Stock_Catalog.Stock_Status='Active' ORDER BY Stock_Catalog_Name, Stock_Received DESC"
    );
    my %Received;

    if ( defined $Last{ID} && ( $Last{ID}[0] =~ /[1-9]/ ) ) {

        my $Samples = HTML_Table->new( -title => "Select Items Below to Extract in Batch from Box(es): $box_id." );
        $Samples->Set_Headers( [ 'Select', 'Item', 'Catalog No.', 'Type', 'Lot Number', '<B><Font color=red>Number in Batch</Font></B>', '<B><Font color=red>Received</Font>', 'Expiry', 'Location', 'Group', 'Label', 'Cost', 'Update' ] );
        my $i = 0;
        my %Found;

        my @ids;
        while ( defined $Last{ID}[$i] ) {
            my ( $id, $cat, $name, $grp, $barcode, $type, $catalog_id ) = ( $Last{ID}[$i], $Last{Cat}[$i], $Last{Stock_Catalog_Name}[$i], $Last{Grp}[$i], $Last{Label}[$i], $Last{Stock_Type}[$i], $Last{Stock_Catalog_ID}[$i] );

            if ( defined $Found{"$name:$cat"} ) { $i++; next; }
            $Found{"$name:$cat"} = 1;
            my $grp_info        = $dbc->get_FK_info( 'FK_Grp__ID',           $grp )     if $grp;
            my $barcode_default = $dbc->get_FK_info( 'FK_Barcode_Label__ID', $barcode ) if $barcode;
            my $default_rack    = $dbc->get_FK_info( 'FK_Rack__ID',          $rack )    if $rack;

            $i++;
            if ( $name && $Received{name}{$name} && !$Received{cat}{$cat} ) {

                #	      Message("$name ALREADY retrieved from a different catalog number ($cat) - Prompting for the most recent stock entry (you should change the name of one if these are unique !)");
                #	      next;
            }
            elsif ( $cat && $Received{cat}{$cat} && !$Received{name}{$name} ) {
                $dbc->warning("This catalog number ($cat) is associated with items of different name ($name) - please edit if necessary");
            }
            elsif ( $Received{name}{$name} && $Received{cat}{$cat} ) {
                next;
            }

            $Received{cat}{$cat}++;
            $Received{name}{$name}++;
            my $label = $name;

            my $expiry_item;

            if ( $type =~ /Reagent|Buffer|Solution|Box|Microarray/i ) {
                if ( $type =~ /Microarray/ ) {
                    my ($microarray_expiry) = $dbc->Table_find( "Microarray", "Expiry_DateTime", "where FK_Stock__ID = $id" );
                    $exp = $microarray_expiry;
                }
                $expiry_item = display_date_field( -field_name => "Expy$id", -default => $exp );
            }
            else {
                $expiry_item = 'N/A';
            }

            $Samples->Set_Row(
                [   checkbox( -name => 'BoxSample', -label => '', -value => $id ),
                    $label,
                    $cat,
                    $type,
                    Show_Tool_Tip( textfield( -name => "Lot$id",  -size => 6 ), "Optional - for $name" ),
                    Show_Tool_Tip( textfield( -name => "NinB$id", -size => 4 ), "Number of $name Items to be extracted (from each box if more than one box scanned)" ),

                    display_date_field( -field_name => "Rcvd$id", -default => $rcvd ),
                    Show_Tool_Tip( $expiry_item, "Optional - indicate expiry date for $name" ),
                    Show_Tool_Tip(
                        &alDente::Tools::search_list( -dbc => $dbc, -id => "Rack$id", -field => 'FK_Rack__ID', -search => 1, -filter => 1, -default => $default_rack, ),
                        "Where Item is to be stored"
                    ),
                    &alDente::Tools::search_list( -dbc => $dbc, -id => "Grp$id", -field => 'FK_Grp__ID', -search => 1, -filter => 1, -default => $grp_info, ),
                    Show_Tool_Tip( RGTools::Web_Form::Popup_Menu( name => "Label$id", values => &alDente::Barcoding::barcode_options( $type, -dbc => $dbc ), width => 60, default => $barcode_default ), "Type of Barcode label to print out" ),
                    textfield( -name => "Cost$id", -size => 5, -default => 0 ),
                    &Link_To( $dbc->config('homelink'), '(view last record)', "&Search=1&Table=Stock&Search+List=$id" ),
                    hidden( -name => "catalog_id$id", value => $catalog_id )

                ]
            );
            push @ids, $id;
        }

        $Samples->Toggle_Colour_on_Column(3);

        $page .= &alDente::Form::start_alDente_form( $dbc, 'ExtractFromBox2' );

        if ($exp) {
            ## enable toggle of expiry date from Box
            my ( $set_expiry, $clear_expiry );
            foreach my $id (@ids) {
                $set_expiry   .= "SetSelection(this.form,'Expy$id','$exp','2001-01-01');";
                $clear_expiry .= "SetSelection(this.form,'Expy$id','','2001-01-01');";
            }

            $page .= radio_group( -name => 'toggle', -values => 'Inherit Expiry Date', -onClick => $set_expiry );
            $page .= radio_group( -name => 'toggle', -values => 'Clear Expiry Date',   -onClick => $clear_expiry );
        }

        $page
            .= $Samples->Printout(0)
            . submit( -name => 'Receive BoxSamples', -value => 'Extract Selected Items', -class => 'Action' )
            . &vspace(10)
            . hidden( -name => 'Box_ID',     -value => $box_id, -force => 1 )
            . hidden( -name => 'FK_Box__ID', -value => $box_id, -force => 1 )
            . end_form();
    }

    return $page;
}

####################
sub extra_actions {
####################
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $dbc    = $self->{dbc};
    my $Box    = $args{-Box} || $self->Model;
    my $box_id = $Box->{id};                    #|| $self->{id};
    my $page;
    my $name       = $Box->value('Stock_Catalog_Name');
    my $box_status = $Box->value('Box_Status');

    $page .= &alDente::Form::start_alDente_form( $dbc, 'BoxPage' );
    $page .= hidden( -name => 'Box_ID', -value => $box_id, -force => 1 );
    $page .= &vspace() . submit( -name => 'rm', -value => "Re-Print Box Barcode", -class => "Std" ) . " for Box(es) $box_id ($name)";
    $page .= &vspace();
    $page .= hidden( -name => 'cgi_application', -value => 'alDente::Box_App', -force => 1 );
    $page .= submit( -name => 'rm', -value => 'Throw Away Box', -class => 'Action', -force => 1 );

    if ( $box_status eq 'Unopened' ) {
        $page .= vspace();
        $page .= submit( -name => 'rm', -value => 'Open Box', -class => "Action" );
        if ( !$scanner_mode ) { $page .= " <- simply mark as open, but do not track items<BR>" }
    }
    $page .= end_form();

    return $page;
}

####################
sub foreign_label {
####################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $self->{dbc};
    my $Box  = $args{-Box} || $self->Model;

    my $page;
    my $box_id     = $args{-box_id} || $Box->{id} || $Box->value('Box_ID');
    my $id         = $Box->value('Box_ID');
    my $name       = $Box->value('Stock_Catalog_Name');
    my $number     = $Box->value('Box_Number');
    my $Nof        = $Box->value('Box_Number_in_Batch');
    my $rcvd       = $Box->value('Stock_Received');
    my $opened     = $Box->value('Box_Opened');
    my $cost       = $Box->value('Stock_Cost');
    my $exp        = $Box->value('Box_Expiry');
    my $box_status = $Box->value('Box_Status');

    my $edit_link = alDente::Stock_Views::edit_Records_Link( -ids => $id, -dbc => $dbc, -object => "Box" );
    my $page;
    if ( !$scanner_mode ) {
        $page .= &Link_To( $dbc->config('homelink'), "<B>$name</B>", "&HomePage=Box&ID=$box_id" ) . vspace(2);
    }
    else {
        $page .= "$name\n" . vspace();
    }
    $page .= "Box(es) $box_id:" . vspace() . "Received: $rcvd" . vspace();
    if ($opened) { $page .= "Opened:   $opened " . vspace(); }
    if ( $exp =~ /[1-9]/ ) { $page .= "Expiry:   $exp" . vspace(); }
    if ( $exp =~ /[1-9]/ && ( convert_date( $exp, 'SQL' ) < &date_time() ) ) { $dbc->warning("This Box has Expired already (Exp: $exp) - contents should not be used"); }    ## message if expired...

    $page .= "Box $number of $Nof " . vspace();
    if ($cost) { $page .= " (\$$cost);" . vspace(); }                                                                                                                        ## show cost if available...

    ## show quarantine status if applicable ##
    my $quarantined = alDente::QC_Batch::check_Quarantine( -dbc => $dbc, -class => 'Box', -id => $box_id );
    if ($quarantined) {
        $dbc->warning("QC'ed Items Detected in Box(es) $box_id");
        $page .= vspace() . $quarantined . vspace();
    }
    $page .= $edit_link;
    return $page;
}

####################
sub current_Contents {
####################
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $dbc    = $self->{dbc};
    my $Box    = $args{-Box} || $self->Model;
    my $box_id = $Box->{id};                    #|| $self->{id};

    my $page;
    my %contents = $dbc->Table_retrieve(
        'Stock,Stock_Catalog LEFT JOIN Solution ON Solution.FK_Stock__ID=Stock_ID',
        [   'Stock_ID', 'Stock_Catalog_Name', 'Stock_Type', 'Stock_Number_in_Batch', 'Stock_Received', 'Stock_Catalog_Number', 'Stock_Lot_Number', 'FK_Box__ID', 'Solution_ID',
            "CASE WHEN Solution_Number_in_Batch = 1 THEN '' ELSE Concat(Solution_Number,'/',Solution_Number_in_Batch) END as Solution_Index",
            'Solution_Quantity', 'Solution_Status'
        ],
        "WHERE FK_Box__ID IN ($box_id) AND Stock_Catalog_ID = FK_Stock_Catalog__ID",
        -order => "Stock_Catalog_Name , Solution_Number"
    );

    my $Contents = HTML_Table->new( -title => 'Current Contents', -alt_message => 'No contents associated with this type of box' );
    $Contents->Set_Headers( [ 'Mix', 'Qty (mils)', '', 'Item', 'Type', ' # ', 'Received:', 'Catalog Number', 'Lot Number', 'Status' ] );

    my $index    = 0;
    my $reagents = 0;
    while ( defined $contents{Stock_ID}[$index] ) {
        my @row = ();

        my $solution_id = $contents{Solution_ID}[$index];
        my $number      = $contents{Solution_Index}[$index];
        my $qty         = $contents{Solution_Quantity}[$index];
        ## provide checkbox for users to select solutions... (for mixing)
        if ($solution_id) {
            push @row, checkbox( -name => 'Solution Included', -label => '', -value => $solution_id );
            push @row, textfield( -name => "Sol$solution_id Qty", -size => 10, -default => $qty );
            push @row, $number;
            $reagents++;
        }
        else {
            push @row, '', '', '';
        }

        my $box_id   = $contents{FK_Box__ID}[$index];
        my $stock_id = $contents{Stock_ID}[$index] || 0;           ## default to 0 to prevent crashing link if null for some reason.
        my $name     = $contents{Stock_Catalog_Name}[$index];
        my $cat      = $contents{Stock_Catalog_Number}[$index];
        my $lot      = $contents{Stock_Lot_Number}[$index];
        my $type     = $contents{Stock_Type}[$index];
        my $num      = $contents{Stock_Number_in_Batch}[$index];
        my $rcvd     = $contents{Stock_Received}[$index];
        my $status   = $contents{Solution_Status}[$index];

        my $item = &Link_To( $dbc->config('homelink'), $name, "&HomePage=Solution&ID=$solution_id" );
        push @row, ( $item, $type, $num, $rcvd, $cat, $lot, $status );

        $Contents->Set_Row( \@row );
        $index++;
    }

    $Contents->Toggle_Colour_on_Column(1);

    if ($index) {

        # contents found #
        $page .= &alDente::Form::start_alDente_form( $dbc, 'MixBox' );
        $page .= $Contents->Printout(0);
        $page .= hidden( -name => 'Box_ID', -value => $box_id, -force => 1 );
        $page .= hidden( -name => 'cgi_application', -value => 'alDente::Solution_App', -force => 1 );

        if ($reagents) {
            ## reagents found ... ##

            ## add new catalog record for mixture from this box type... ##
            my $catalog_name = $Box->value('Stock_Catalog_Name') . ' Mix';
            my ($existing_stock) = $dbc->Table_find( 'Stock_Catalog', 'Stock_Catalog_ID', "WHERE Stock_Catalog_Name = '$catalog_name' and Stock_Type = 'Solution'" );
            if ($existing_stock) {
                $page .= hidden( -name => 'FK_Stock_Catalog__ID', -value => $existing_stock, -force => 1 );
            }
            else {
                $page .= hidden( -name => 'AddingCatalog',      -value => 1 );
                $page .= hidden( -name => 'Stock_Catalog_Name', -value => $catalog_name );
            }

            $page .= submit( -name => 'rm', -value => 'Mix Box Contents', -force => 1, -class => 'Action', -onclick => 'return validateForm(this.form)' ) . ' into: ' . $catalog_name;

            $page .= vspace(4);

            $page .= 'Label Format: ' . alDente::Tools::search_list( -dbc => $dbc, -name => "FK_Barcode_Label__ID", -condition => "Barcode_Label_Type = 'solution'", -prompt => 'Please choose label type' );
            $page .= hidden( -name => 'FK_Grp__ID', -value => $Box->value('FK_Grp__ID') );
            $page .= set_validator( -name => "FK_Barcode_Label__ID", -mandatory => 1 );
        }
        $page .= end_form();
        $page .= vspace(4);
    }

    return $page;
}

#################
sub home_page {
#################
    my $self = shift;
    my %args = filter_input( \@_ );
########################################## THIS SHOULD BE DEPRICATED ##################################
    my $Box = $args{-Box};
    my $id  = $args{-id};
    my $dbc = $args{-dbc};
    $dbc->admin_warning('Depricated Functionality');

    if ($Box) {
        $dbc ||= $Box->{dbc};
        $id  ||= $Box->{id};
    }
    elsif ($id) {
        $Box = new alDente::Box( -dbc => $dbc, -id => $id );
    }
    else {
        return generic_home_page();
    }
    my $edit_link = alDente::Stock_Views::edit_Records_Link( -ids => $id, -dbc => $dbc, -object => "Box" );

    my %args = &filter_input( \@_, -args => 'box_id' );
    if ( $args{ERRORS} ) { Message( $args{ERRORS} ); return 0; }

    my $box_id     = $args{-box_id} || $Box->{id} || $Box->value('Box_ID');
    my $id         = $Box->value('Box_ID');
    my $name       = $Box->value('Stock_Catalog_Name');
    my $grp_owner  = $Box->value('FK_Grp__ID');
    my $number     = $Box->value('Box_Number');
    my $Nof        = $Box->value('Box_Number_in_Batch');
    my $rcvd       = $Box->value('Stock_Received');
    my $opened     = $Box->value('Box_Opened');
    my $rack       = $Box->value('FK_Rack__ID');
    my $cost       = $Box->value('Stock_Cost');
    my $box_cat    = $Box->value('Stock_Catalog.Stock_Catalog_Number');
    my $org        = $Box->value('Stock_Catalog.FK_Organization__ID');
    my $exp        = $Box->value('Box_Expiry');
    my $box_status = $Box->value('Box_Status');

    my $status;
    if ($opened) { $status = "Opened"; }
    elsif ( $id =~ /\d/ ) { $status = "Rcvd"; }
    else                  { $status = "Unknown"; }

    my $page = "Box(es) $box_id:<P>";
    if ( !$scanner_mode ) {
        $page .= &Link_To( $dbc->config('homelink'), "<B>$name</B>", "&HomePage=Box&ID=$box_id" ) . &vspace(2);
    }
    else {
        $page .= "<B>$name</B>\n" . &vspace(2);
    }

    unless ( $number > 0 ) { Message( "Error: ", "Box $box_id not found" ); }

    if ( $box_id =~ /,/ ) { Message("Details displayed only for first box in list"); }

    $page .= "Received: $rcvd<BR>";
    if ($opened) { $page .= "Opened:   $opened <BR>"; }
    if ( $exp =~ /[1-9]/ ) { $page .= "Expiry:   $exp <BR>"; }

    if ( $exp =~ /[1-9]/ && ( convert_date( $exp, 'SQL' ) < &date_time() ) ) { Message("Warning: This Box has Expired already (Exp: $exp) - contents should not be used"); }    ## message if expired...
    ## <CONSTRUCTION> - send message if ANY Of boxes in current list are expired, (and remove expired ones from list ?)

    $page .= &vspace() . "Box $number of $Nof ";
    if ($cost) { $page .= &vspace() . " (\$$cost);"; }                                                                                                                          ## show cost if available...

    ## show quarantine status if applicable ##
    my $quarantined = alDente::QC_Batch::check_Quarantine( -dbc => $dbc, -class => 'Box', -id => $box_id );
    if ($quarantined) {
        $page .= '<hr>';
        $dbc->warning("QC'ed Items Detected in Box(es) $box_id");
        $page .= $quarantined;
        $page .= '<hr>';
    }

    my %contents = $dbc->Table_retrieve(
        'Stock,Stock_Catalog LEFT JOIN Solution ON Solution.FK_Stock__ID=Stock_ID',
        [   'Stock_ID', 'Stock_Catalog_Name', 'Stock_Type', 'Stock_Number_in_Batch', 'Stock_Received', 'Stock_Catalog_Number', 'Stock_Lot_Number', 'FK_Box__ID', 'Solution_ID', 'Stock_Size_Units',
            "CASE WHEN Solution_Number_in_Batch = 1 THEN '' ELSE Concat(Solution_Number,'/',Solution_Number_in_Batch) END as Solution_Index",
            'Solution_Quantity', 'Solution_Status'
        ],
        "WHERE FK_Box__ID IN ($box_id) AND Stock_Catalog_ID = FK_Stock_Catalog__ID"
    );
    if ( !$scanner_mode ) {
        $page .= vspace() . $edit_link;
    }
    $page .= &alDente::Form::start_alDente_form( $dbc, 'BoxPage' );
    $page .= hidden( -name => 'Box_ID', -value => $box_id, -force => 1 );
    $page .= &vspace(2) . submit( -name => 'rm', -value => "Re-Print Box Barcode", -class => "Std" ) . " for Box(es) $box_id ($name)";
    $page .= &vspace(4);

    $page .= hidden( -name => 'cgi_application', -value => 'alDente::Box_App', -force => 1 );
    $page .= submit( -name => 'rm', -value => 'Throw Away Box', -class => 'Action', -force => 1 );
    $page .= &vspace(4);
    $page .= end_form();

    my $Contents = HTML_Table->new( -title => 'Current Contents', -alt_message => 'No contents associated with this type of box' );
    $Contents->Set_Headers( [ 'Mix', 'Qty (mils)', 'Current Volume', '', 'Item', 'Type', ' # ', 'Received:', 'Catalog Number', 'Lot Number', 'Status' ] );

    my $index    = 0;
    my $reagents = 0;
    while ( defined $contents{Stock_ID}[$index] ) {
        my @row = ();

        my $solution_id = $contents{Solution_ID}[$index];
        my $units       = $contents{Stock_Size_Units}[$index];
        my $number      = $contents{Solution_Index}[$index];
        my $qty         = $contents{Solution_Quantity}[$index];
        ## provide checkbox for users to select solutions... (for mixing)
        if ($solution_id) {
            push @row, checkbox( -name => 'Solution Included', -label => '', -value => $solution_id );
            push @row, textfield( -name => "Sol$solution_id Qty", -size => 10, -default => $qty );
            push @row, $qty . ' ' . $units;
            push @row, $number;
            $reagents++;
        }
        else {
            push @row, '', '', '', '';
        }

        my $box_id   = $contents{FK_Box__ID}[$index];
        my $stock_id = $contents{Stock_ID}[$index] || 0;           ## default to 0 to prevent crashing link if null for some reason.
        my $name     = $contents{Stock_Catalog_Name}[$index];
        my $cat      = $contents{Stock_Catalog_Number}[$index];
        my $lot      = $contents{Stock_Lot_Number}[$index];
        my $type     = $contents{Stock_Type}[$index];
        my $num      = $contents{Stock_Number_in_Batch}[$index];
        my $rcvd     = $contents{Stock_Received}[$index];
        my $status   = $contents{Solution_Status}[$index];

        my $item = &Link_To( $dbc->config('homelink'), $name, "&HomePage=Stock&ID=$stock_id" );

        push @row, ( $item, $type, $num, $rcvd, $cat, $lot, $status );

        $Contents->Set_Row( \@row );
        $index++;
    }

    $Contents->Toggle_Colour_on_Column(1);

    if ($index) {

        # contents found #
        $page .= &alDente::Form::start_alDente_form( $dbc, 'MixBox' );
        $page .= $Contents->Printout(0);
        $page .= hidden( -name => 'Box_ID', -value => $box_id, -force => 1 );
        $page .= hidden( -name => 'cgi_application', -value => 'alDente::Solution_App', -force => 1 );

        if ($reagents) {
            ## reagents found ... ##

            ## add new catalog record for mixture from this box type... ##
            my $catalog_name = $name . ' Mix';
            my ($existing_stock) = $dbc->Table_find( 'Stock_Catalog', 'Stock_Catalog_ID', "WHERE Stock_Catalog_Name = '$catalog_name' and Stock_Type = 'Solution'" );
            if ($existing_stock) {
                $page .= hidden( -name => 'FK_Stock_Catalog__ID', -value => $existing_stock, -force => 1 );
            }
            else {
                $page .= hidden( -name => 'AddingCatalog',      -value => 1 );
                $page .= hidden( -name => 'Stock_Catalog_Name', -value => $catalog_name );
            }

            $page .= submit( -name => 'rm', -value => 'Mix Box Contents', -force => 1, -class => 'Action', -onclick => 'return validateForm(this.form)' ) . ' into: ' . $catalog_name;

            $page .= vspace(4);

            $page .= 'Label Format: ' . alDente::Tools::search_list( -dbc => $dbc, -name => "FK_Barcode_Label__ID", -condition => "Barcode_Label_Type = 'solution'", -prompt => 'Please choose label type' );
            $page .= hidden( -name => 'FK_Grp__ID', -value => $grp_owner );
            $page .= set_validator( -name => "FK_Barcode_Label__ID", -mandatory => 1 );
        }
        $page .= end_form();
        $page .= vspace(4);
    }

    $page .= Views::Heading("Extracting new items (to be barcoded)");

    if ( $box_status eq 'Unopened' ) {
        $page .= &alDente::Form::start_alDente_form( $dbc, 'OpenBox' );
        $page .= hidden( -name => 'cgi_application', -value => 'alDente::Box_App', -force => 1 );
        $page .= hidden( -name => 'Box_ID',          -value => $box_id,            -force => 1 );
        $page .= &vspace(4);
        $page .= submit( -name => 'rm', -value => 'Open Box', -class => "Action" );
        if ( !$scanner_mode ) { $page .= " <- simply mark as open, but do not track items<BR>" }

        $page .= end_form();
    }

    if ( !$scanner_mode ) {
        my %labels;
        $labels{Reagent} = 'Standard Reagent';

        $page .= '<hr>';
        $page .= &alDente::Form::start_alDente_form( $dbc, 'ExtractFromBox' );
        $page .= hidden( -name => 'Box_ID', -value => $box_id, -force => 1 );
        $page .= hidden( -name => 'cgi_application', -value => 'alDente::Stock_App', -force => 1 );
        $page .= submit( -name => 'rm', -value => 'Extract New Stock from Box', -force => 1, -class => "Std" );
        $page .= "<I><Font size=-1>(only for new items that have NOT been extracted from this type of Box)<BR>Otherwise, use extraction form below" . &vspace();

        $page .= radio_group( -name => 'Boxed Items', -values => [ 'Reagent', 'Buffer', 'Primer', 'Matrix' ], -linebreak => 0, -labels => { Reagent => 'Standard Reagent' } ) . br();
        $page .= radio_group( -name => 'Boxed Items', -values => [ 'Box', 'Kit' ], -linebreak => 0 ) . br();
        $page .= radio_group( -name => 'Boxed Items', -values => ['Microarray'], -linebreak => 0 ) . br();

        #        $page .= radio_group( -name => 'Boxed Items', -values => ['Nothing'], -linebreak => 0, -default => 'Nothing' ) . ' (just open)', $page .= "</font>\n";

        ## add parameters for Stock retrieval run mode ##
        $page .= hidden( -name => 'FK_Box__ID', -value => $box_id, -force => 1 ) . hidden( -name => 'Stock_Source', -value => 'Box', -force => 1 ) . hidden( -name => 'FKManufacturer_Organization__ID', -value => $org, -force => 1 ) . end_form();
    }
    $page .= &vspace(4);

    #hidden(-name=>'FK_Rack__ID',-value=>"Rac$rack",-force=>1);

### Scanner mode - just print out basic details, return. ###
    if ($scanner_mode) { return $page }

    ### Workstation mode ###
    my $details = $Box->display_Record();
    &Views::Table_Print( content => [ [ $page, $details ] ], spacing => 5, width => '100%', align => [ 'left', 'right' ] );

    ### Check to see if the boxes scanned are of the same name

    my @distinct_box_names = $dbc->Table_find( 'Stock,Box,Stock_Catalog', 'Stock_Catalog_Name', "WHERE Stock_ID=FK_Stock__ID and Box_ID IN ($box_id) AND FK_Stock_Catalog__ID = Stock_Catalog_ID ", -distinct => 1 );

    if ( scalar(@distinct_box_names) > 1 ) {
        Message( "Warning: Different box names scanned (" . join( ',', @distinct_box_names ) . "). Can not do multiple extractions." );
        return 1;
    }

    ### Extraction form

    my $similar_boxes = join ',',
        $dbc->Table_find( 'Box,Stock,Stock_Catalog', 'Box_ID as ID',
        "WHERE FK_Stock_Catalog__ID = Stock_Catalog_ID and FK_Stock__ID=Stock_ID AND (Stock_Catalog_Name = \"$name\" OR (Stock_Catalog.Stock_Catalog_Number='$box_cat' AND Length(Stock_Catalog.Stock_Catalog_Number)>0)) ORDER BY Stock_Received DESC" );

    my %Last = $dbc->Table_retrieve(
        'Stock,Stock_Catalog',
        [ 'Stock_ID as ID', 'Stock_Catalog.Stock_Catalog_Number as Cat', 'Stock_Catalog_Name', 'FK_Grp__ID as Grp', 'Stock.FK_Barcode_Label__ID as Label', 'Stock_Type', 'Stock_Catalog_ID' ],
        "WHERE Stock_Catalog_ID = FK_Stock_Catalog__ID and FK_Box__ID in ($similar_boxes) AND Stock_Catalog.Stock_Status='Active' ORDER BY Stock_Received DESC"
    );
    my %Received;

    #    my @rack_locations = $Connection->Table_find('Rack','Rack_ID',"WHERE Rack_Type <> 'Slot' ORDER BY Rack_Alias");
    my @rack_locations = $dbc->get_FK_info( 'FK_Rack__ID', -condition => "WHERE Rack_Type <> 'Slot' ORDER BY Rack_Alias", -list => 1 );
    my @groups = @{ $dbc->get_local('groups') };

    Message("Important: Items extracted will be removed from EACH box in current box list") if ( $box_id =~ /,/ );    ## clarify for user...

    if ( defined $Last{ID} && ( $Last{ID}[0] =~ /[1-9]/ ) ) {

        my $Samples = HTML_Table->new( -title => "Select Items Below to Extract in Batch from Box(es): $box_id." );
        $Samples->Set_Headers( [ 'Select', '', 'Item', 'Catalog No.', 'Type', 'Lot Number', '<B><Font color=red>Number in Batch</Font></B>', '<B><Font color=red>Received</Font>', 'Expiry', 'Location', 'Group', 'Label', 'Cost', 'Update' ] );
        my $i = 0;
        my %Found;

        my @ids;
        while ( defined $Last{ID}[$i] ) {
            my ( $id, $cat, $name, $grp, $barcode, $type, $catalog_id ) = ( $Last{ID}[$i], $Last{Cat}[$i], $Last{Stock_Catalog_Name}[$i], $Last{Grp}[$i], $Last{Label}[$i], $Last{Stock_Type}[$i], $Last{Stock_Catalog_ID}[$i] );

            if ( defined $Found{"$name:$cat"} ) { $i++; next; }
            $Found{"$name:$cat"} = 1;
            my $grp_info        = $dbc->get_FK_info( 'FK_Grp__ID',           $grp )     if $grp;
            my $barcode_default = $dbc->get_FK_info( 'FK_Barcode_Label__ID', $barcode ) if $barcode;
            my $default_rack    = $dbc->get_FK_info( 'FK_Rack__ID',          $rack )    if $rack;

            $i++;
            if ( $name && $Received{name}{$name} && !$Received{cat}{$cat} ) {

                #	      Message("$name ALREADY retrieved from a different catalog number ($cat) - Prompting for the most recent stock entry (you should change the name of one if these are unique !)");
                #	      next;
            }
            elsif ( $cat && $Received{cat}{$cat} && !$Received{name}{$name} ) {
                Message("WARNING: This catalog number ($cat) is associated with items of different name ($name) - please edit if necessary");
            }
            elsif ( $Received{name}{$name} && $Received{cat}{$cat} ) {
                next;
            }

            $Received{cat}{$cat}++;
            $Received{name}{$name}++;
            my $label = $name;

            my $expiry_item;
            if ( $type =~ /Reagent|Buffer|Solution|Box|Microarray/i ) {

                if ( $type =~ /Microarray/ ) {
                    my ($microarray_expiry) = $dbc->Table_find( "Microarray", "Expiry_DateTime", "where FK_Stock__ID = $id" );
                    $expiry_item = display_date_field( -field_name => "Expy$id", -size => 10, -default => $microarray_expiry );
                }
                else {
                    $expiry_item = display_date_field( -field_name => "Expy$id", -size => 10, -default => $exp );
                }
            }
            else {
                $expiry_item = 'N/A';
            }
            require alDente::Barcoding;
            $Samples->Set_Row(
                [   checkbox( -name => 'BoxSample', -label => '', -value => $id ),
                    &Link_To(
                        $dbc->homelink(),

                        Show_Tool_Tip(
                            "<img src='/$URL_dir_name/images/icons/nav_next.gif' height=10 width=8 border=0>",

                            "Extract this item from this box only"
                        ),
                        "&Incoming=1&Stock_Source=Box&FK_Box__ID=$box_id&Stock_Catalog_Name=$name&Catalog_Number=$cat",
                        -tooltip => "Extract this item from this box only"
                    ),
                    $label,
                    $cat,
                    $type,
                    Show_Tool_Tip( textfield( -name => "Lot$id",  -size => 6 ), "Optional - for $name" ),
                    Show_Tool_Tip( textfield( -name => "NinB$id", -size => 4 ), "Number of $name Items to be extracted (from each box if more than one box scanned)" ),

                    display_date_field( -field_name => "Rcvd$id", -size => 10, -default => $rcvd ),    ## changed to box received date (preferred to date removed)
                    Show_Tool_Tip( $expiry_item, "Optional - indicate expiry date for $name" ),
                    Show_Tool_Tip(

                        #	     RGTools::Web_Form::Popup_Menu(name=>"Rack$id",values=>[@rack_locations],default=>$default_rack,force=>1,width=>100),
                        &alDente::Tools::search_list( -dbc => $dbc, -name => "Rack$id", -options => \@rack_locations, -filter => 1, -search => 1, -default => $default_rack, -breaks => 2 ),
                        "Where Item is to be stored"
                    ),
                    Show_Tool_Tip( RGTools::Web_Form::Popup_Menu( name => "Grp$id", values => \@groups, default => $grp_info ), "Owned by" )
                        .

                        #       $grp_info .
                        #                        hidden( -name => "Org$id", -value => $org ),                    # . hidden(-name=>"Grp$id",-value=>$grp),
                        hidden( -name => "catalog_id$id", value => $catalog_id )
                        . Show_Tool_Tip( RGTools::Web_Form::Popup_Menu( name => "Label$id", values => &alDente::Barcoding::barcode_options($type, -dbc=>$dbc), width => 60, default => $barcode_default ), "Type of Barcode label to print out" ),
                    textfield( -name => "Cost$id", -size => 5, -default => 0 ),
                    &Link_To( $dbc->config('homelink'), '(view last record)', "&Search=1&Table=Stock&Search+List=$id" ),
                ]
            );
            push @ids, $id;
        }

        $Samples->Toggle_Colour_on_Column(3);

        print &alDente::Form::start_alDente_form( $dbc, 'ExtractFromBox2' );

        if ($exp) {
            ## enable toggle of expiry date from Box
            my ( $set_expiry, $clear_expiry );
            foreach my $id (@ids) {
                $set_expiry   .= "SetSelection(this.form,'Expy$id','$exp','2001-01-01');";
                $clear_expiry .= "SetSelection(this.form,'Expy$id','','2001-01-01');";
            }

            print radio_group( -name => 'toggle', -values => 'Inherit Expiry Date', -onClick => $set_expiry );
            print radio_group( -name => 'toggle', -values => 'Clear Expiry Date',   -onClick => $clear_expiry );
        }

        print $Samples->Printout(0)
            . submit( -name => 'Receive BoxSamples', -value => 'Extract Selected Items', -class => 'Action' )
            . &vspace(10)
            . hidden( -name => 'Box_ID',     -value => $box_id, -force => 1 )
            . hidden( -name => 'FK_Box__ID', -value => $box_id, -force => 1 )

            #            . hidden( -name => 'Stock_Source',                    -value => 'Box',   -force => 1 )
            #           . hidden( -name => 'FKManufacturer_Organization__ID', -value => $org,    -force => 1 )
            . end_form();
    }
    return 1;
}

#
# Generic home page for Box Object (no specific box(es) defined)
#
#
###########################
sub generic_home_page {
###########################

    return "Standard Generic Box Home Page";
}

1;
