package alDente::Solution_Views;
use base alDente::Object_Views;

use strict;

use RGTools::RGIO;
use RGTools::Conversion;
use SDB::HTML;
use SDB::DBIO;
use SDB::CustomSettings;
use alDente::Tools;
use alDente::Form;
use alDente::Stock;
use alDente::Solution;
use alDente::SDB_Defaults;
use alDente::Validation;

use LampLite::Bootstrap;
use LampLite::CGI;

my $BS = new Bootstrap();
my $q  = new LampLite::CGI;
##################################################################

use vars qw(%Configs $Security %Settings);

#####################
sub new {
#####################
    # Description:
    #     - Constrcutor
    # Input:
    #     - id: ID of solution
    #     - model:  Object(alDente::Solution)
    #     - dbc: database handle
    # Output:
    #     - View OBject
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );

    my $self  = {};
    my $model = $args{-Model};
    my $id    = $args{-id};
    my $dbc   = $args{-dbc} || $model->{dbc};

    my ($class) = ref($this) || $this;
    bless $self, $class;
    $self->load_object( -id => $id, -dbc => $dbc, -Model => $model );
    return $self;
}

#####################
sub load_object {
#####################
    # Description:
    #     - load the attributes of the object
    # Input:
    #     - id and dbc (optional: model object)
    # Output:
    #
#####################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $Solution = $args{-Model};
    my $dbc      = $args{-dbc};
    my $id       = $args{-id};
    $Solution ||= new alDente::Solution( -dbc => $dbc, -id => $id );

    $self->{id}     = $id;
    $self->{dbc}    = $dbc;
    $self->{Model}  = $Solution;
    $self->{loaded} = 1;
    return $self;
}

##########################
sub display_record_page {
##########################
    my $self = shift;
    my $dbc = $self->dbc();
    my $id = $self->{id};
    
    my @layers;
    push @layers, {'label' => 'Search', 'content' => $self->display_Usage() };
    push @layers, {'label' => 'Actions', 'content' => $self->display_Actions() };
    
    return $self->SUPER::display_record_page(
        -right => $self->standard_options(),
        -layers     => \@layers,
        -visibility => { 'Search' => ['desktop'] },
        -label_span => 3,
        -open_layer => 'Actions',
    );
}

#######################
sub standard_options {
#######################
    my $self = shift;
    my $dbc = $self->dbc();
    my $id = $self->{id};

    my $empty_prompt = $q->submit( -name => 'rm', -value => 'Empty Solution(s)', -class => "Action" );
    my $reprint_prompt = $q->submit( -name => 'rm', -value => 'Re-Print Solution Labels', -class => 'Std' )
        . alDente::Tools::search_list( -dbc => $dbc, -field => 'FK_Barcode_Label__ID', -condition => "Barcode_Label_Type like 'solution' AND Barcode_Label_Status ='Active'" )
        . " Repeat: "
        . $q->popup_menu( -name => 'Repeat', -value => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] )
        . ' time(s)';
            
    my $Form = alDente::Form::start_alDente_form($dbc)
    . $q->hidden(-name=>'cgi_app', -value=>'alDente::Solution_App', -force=>1)
    . $q->hidden(-name=>'Solution_ID', -value=>$id, -force=>1)
    . '<P></P>'
    . $empty_prompt
    . '<P></P>'
    . $reprint_prompt;
    
    if ( $dbc->Security->department_access() =~ /Admin/i ) {
        $Form .= '<P></P>'
        . $q->submit( -name => 'rm', -value => 'Delete Solution', -force => 1, -class => "Action" );
    }
    
    $Form .= $q->end_form();
    
    return $Form;
}

####################
sub object_label {
####################
    my $self        = shift;
    my $dbc         = $self->{dbc};
    my $solution_id = $self->{id};
    my $Solution    = $self->{Model};

    my $sol_name        = $Solution->value('Stock_Catalog.Stock_Catalog_Name');                  #solution_info{Stock_ Name}[0];
    my $catalog_name    = $Solution->value('Stock_Catalog.Stock_Catalog_Number');
    my $expiry          = $Solution->value('Solution_Expiry');
    my $status          = $Solution->value('Solution_Status');
    my $type            = $Solution->value('Solution_Type');
    my $number          = $Solution->value('Solution_Number');
    my $Nof             = $Solution->value('Solution_Number_in_Batch');
    my $rcvd            = $Solution->value('Stock_Received');
    my $started         = $Solution->value('Solution_Started');
    my $finished        = $Solution->value('Solution_Finished');
    my $lot             = $Solution->value('Stock_Lot_Number');
    my $identifier_type = $Solution->value('Stock.Identifier_Number_Type');
    my $identifier      = $Solution->value('Stock.Identifier_Number');
    my $desc            = $Solution->value('Stock_Catalog.Stock_Description');
    my $qc_status       = $Solution->value('QC_Status');
    my $rack            = $dbc->get_FK_info( 'FK_Rack__ID', $Solution->value('FK_Rack__ID') );
    
    my $title = "Sol$solution_id: $sol_name ($type $number/$Nof)";

    my @rows;
    push( @rows, $desc ) if $desc;
    
    my ($made) = split ' ', $started;
    if ($started) { 
        my ($date) = split ' ', $started;
        push( @rows, "<B>Started:</B> " . alDente::Solution::convert_date( $made, 'Simple' ) . " ($status)" );
    }
    else {
        push( @rows, "<B>Started:</B> No start date ($status)" );
    }
    
    push( @rows, "$identifier_type: $identifier" ) if $identifier;

    my $details;
    $details .= "<B>Cat: </B>$catalog_name; " if $catalog_name;
    $details .= "<B>Lot: </B>$lot; "          if $lot;
    
    push( @rows, $details ) if $details;

    push( @rows, "<B>Located: </B>" . $rack ) if $rack;

    ## show primer details...##
    if ( $type =~ /primer/i ) {
        alDente::Solution::show_primer_info($solution_id);
    }

    push @rows, "<B>Status: $status</B>;";
    my $colour = $Settings{LIGHT_BKGD};
    unless ( $qc_status =~ /^(|N\/A|Passed)$/i ) {
        push @rows, "<B>QC Status: $qc_status</B>";
        $colour = 'FF9999';
    }

    ## some details should be included even if we are in scanner_mode ##
    push( @rows, "EXP: $expiry" ) if $expiry =~ /[1-9]/;


        my $page .= "<B>$title</B><BR>";
        $page .= join "<BR>", @rows;
    
    
    return $page;
}

#########################
sub qc_Section {
#########################
    # Description:
    #     Displays QC button options
#########################
    my $self   = shift;
    my $dbc    = $self->{dbc};
    my $sol_id = $self->{id};    ### solution_id of solution

    my $qc_status = &alDente::QA::check_for_qc( -dbc => $dbc, -ids => $sol_id, -table => "Solution" );
    my $page
        = '<hr>'
        . "<B>Quality Control: </B>"
        . vspace()
        . alDente::Form::start_alDente_form( $dbc, 'qc' )
        . $q->hidden( -name => 'Solution_ID', -value => $sol_id )
        . &alDente::QA_Views::get_qc_prompt( -dbc => $dbc, -qc_status => $qc_status )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::QA_App', -force => 1 )
        . $q->end_form();
    return $page;
}

#########################
sub display_Usage {
#########################
    # Description:
    #     Displays what the solution is mdae of , what is made with it and where it was applied
    #     as well as help locate similar solutions
#########################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my $id   = $self->{id};    ### solution_id of solution

    if ($scanner_mode) {
        return;
    }

    my $cat_name = $self->{Model}->value('Stock_Catalog_Name');
    my $display = alDente::Form::start_alDente_form( $dbc, 'stock' ) . $q->hidden( -name => 'Solution_ID', -value => $id );

    if ($id) {
        $display .= $dbc->Table_retrieve_display(
            'Mixture,Solution,Stock,Stock_Catalog',
            [ 'Solution_ID as ID', 'Stock_Catalog_Name as Contains', 'Mixture.Quantity_Used as Amount', 'Units_Used as Units' ],
            "where FK_Stock_Catalog__ID = Stock_Catalog_ID AND FK_Stock__ID=Stock_ID and FKUsed_Solution__ID=Solution_ID and FKMade_Solution__ID in ($id)",
            '',
            "Constituents: ",
            -return_html => 1,
            -alt_message => "(This solution was not created locally)",
        );

        $display .= $dbc->Table_retrieve_display(
            'Mixture,Solution,Stock,Stock_Catalog', [ 'Stock_Catalog_Name as Used_in', 'Solution_ID as ID', 'Mixture.Quantity_Used as Amount', 'Units_Used as Units', 'Solution_Started as Made' ],
            "where FK_Stock_Catalog__ID = Stock_Catalog_ID AND FK_Stock__ID=Stock_ID and FKMade_Solution__ID=Solution_ID and FKUsed_Solution__ID in ($id)",
            -title       => "Used in making:",
            -return_html => 1,
            -alt_message => "(No solutions were found using this reagent)"
        ) . &vspace(5);

        $display .= &Link_To( $dbc->config('homelink'), "List of Applications", "&Solution_ID=$id&Reagent+Applications=1", $Settings{LINK_COLOUR}, ['newwin'] ) . " <i>(to Plates/Tubes etc)</i>" . &vspace(5);
    }

    if ($cat_name) {
        my @groups = @{ $dbc->get_local('groups') };
        $display .= "Group: " 
            . RGTools::Web_Form::Popup_Menu( name => 'Group', values => [ '--ALL--', @groups ], default => 'All' )
            . Show_Tool_Tip( $q->submit( -name => 'Find Solution', -value => 'Find Stock Items', -class => "Search" ) . $q->hidden( -name => 'Search String', -value => $cat_name, -force => 1 ),
            "Find other stock items of the same type (belonging to group(s) indicated)" )
            . &vspace(5);
    }
    $display .= $q->end_form();
    return $display;
}

#########################
sub display_Mixture_Table {
#########################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $dbc     = $args{-dbc} || $self->{dbc};
    my $s_ref   = $args{-solution};
    my $type    = $args{-type};
    my $samples = $args{-samples};
    my $ids     = $args{-ids};
    my $Model   = $args{-Model};
    my @id;
    my %Sol = %$s_ref if $s_ref;
    my $recalculate = recalculate($samples);

    my $total_quantity = 0.0;
    if ( $Sol{message} ) { $dbc->message( $Sol{message} ) }
    if ($ids) { @id = split ',', $ids; }    ### if solutions are pre-scanned...
    my $width = 33;
    if ( $dbc->mobile() ) { $width = 100 }
    my $table = alDente::Form::init_HTML_table( -title => "Mixture", -width => "$width%" );
    my @sol_types;
    my @sol_labels;
    my @sol_formats;
    my $well_default;
    my $well_default_units;

    foreach my $sol_num ( 1 .. $Sol{solutions} ) {

        my $def_id  = 'Sol' . $id[ $sol_num - 1 ] if $id[ $sol_num - 1 ];
        my $label   = $Sol{labels}[ $sol_num - 1 ];
        my $format  = $Sol{format}[ $sol_num - 1 ] || '.';
        my $SolType = $Sol{SolType}[ $sol_num - 1 ] || '.';
        my $qty     = $Sol{quantities}[ $sol_num - 1 ];
        my $units   = $Sol{units}[ $sol_num - 1 ];
        ( $qty, $units ) = simplify_units( $qty, $units );
        ( $well_default, $well_default_units ) = simplify_units( $total_quantity / $samples, 'ml' ) if $samples;
        push @sol_types,   $SolType;
        push @sol_labels,  $label;
        push @sol_formats, $format;

        if ( $Sol{prompt_units} =~ /l$/ ) {
            ( $qty, $units ) = RGTools::Conversion::convert_volume( $qty, $units, $Sol{prompt_units} );
        }
        elsif ( $Sol{prompt_units} ) { $dbc->message("Could not force units to $Sol{prompt_units}") }

        my $qty_prompt;
        unless ($scanner_mode) {
            $qty_prompt = $q->textfield(
                -name     => 'Std_Quantities',
                -size     => 15,
                -default  => $qty,
                -onChange => $recalculate,
                -force    => 1
            );
            $qty_prompt .= $q->popup_menu(
                -name     => 'Std_Quantities_Units',
                -values   => [ 'l', 'ml', 'ul', 'nl', 'pl' ],
                -default  => $units,
                -onChange => $recalculate,
                -force    => 1
            );
        }

        $table->Set_Row(
            [   "<B>$label</B><Br>"
                    . Show_Tool_Tip(
                    $q->textfield(
                        -name    => 'Solution Included',
                        -size    => 8,
                        -default => $def_id,
                        -force   => 1
                    ),
                    "Scan Reagent - or enter barcode"
                    ),
                "qty:<BR>" . $qty_prompt
            ]
        );
        my ( $liquid_volume, $liquid_units ) = convert_to_mils( $qty, $units );
        unless ( $units =~ /g/i ) { $total_quantity += $liquid_volume; }
    }

    $table->Set_Row(
        [   "<B>Total Quantity</B>",
            $q->textfield(
                -name     => 'Solution_Quantity',
                -size     => 15,
                -default  => $total_quantity,
                -onChange => $recalculate,
                -force    => 1
            )
        ],
        'mediumredbw'
    );
    $table->Set_Row(
        [   "<B>Total/Well</B>",
            $q->textfield(
                -name    => 'Maximum Available Per Well',
                -size    => 15,
                -default => "$well_default $well_default_units",
                -force   => 1
            )
        ],
        'mediumredbw'
    );
    $table->Set_Row( [ "<B>            </B>", " (ignores entries in grams)" ], 'mediumredbw' );

    my $block = vspace() . alDente::Form::start_alDente_form( $dbc, 'Mixture' );
    $block .= Safe_Freeze(
        -name   => "Sol_Information",
        -value  => \%Sol,
        -format => 'hidden',
        -encode => 1
    );

    $block .= $table->Printout(0) . vspace();

    $block .= $q->hidden( -name => 'SFormat', -value => \@sol_formats, -force => 1 ) . $q->hidden( -name => 'SolType', -value => \@sol_types, -force => 1 );

    my $possible_new_solution = $Model->get_possible_target_solution( -dbc => $dbc, -ids => $ids ) if $ids;

    ( my $stock_catalog_id ) = $dbc->Table_find( 'Stock_Catalog', 'Stock_Catalog_ID', "WHERE Stock_Catalog_Name = '$type'" );

    if ($stock_catalog_id) {
        $block .= $self->display_extra_parameter_table(
            -dbc    => $dbc,
            -type   => $type,
            -button => 'Save Standard Mixture'
        );
        $block .= $q->hidden( -name => 'Standard', -value => 'Standard', -force => 1 );
    }
    elsif ($ids) {
        $block .= $self->display_extra_parameter_table(
            -dbc           => $dbc,
            -type          => $type,
            -button        => 'Save Standard Mixture',
            -mixture       => 1,
            -ids           => $ids,
            -possible_made => $possible_new_solution
        );
    }
    else {
        $block .= $self->display_extra_parameter_table(
            -dbc            => $dbc,
            -type           => $type,
            -button         => 'Save Standard Mixture',
            -add_to_catalog => 1
        );
        $block .= $q->hidden( -name => 'Standard', -value => 'Standard', -force => 1 );
    }

    $block .= "<B>(divided into " . $q->textfield( -name => 'Bottles', -size => 5, -default => 1, -force => 1 ) . " containers)</Font></B>";
    $block .= $q->hidden( -name => 'Samples', -values => $samples, force => 1 );
    $block .= $q->end_form();
    unless ($scanner_mode) {
        $block .= vspace(4) . alDente::Solution_Views::new_catalog_link( -flag => 'in_house', -dbc => $dbc );
    }
    return $block;

}

###########################
sub display_extra_parameter_table {
###########################
    #
    #
###########################
    my $self                  = shift;
    my %args                  = @_;
    my $dbc                   = $args{-dbc} || $self->param('dbc');
    my $type                  = $args{-type};                         ## Catalog Name
    my $button                = $args{-button};
    my $sol_ids               = $args{-ids};
    my $mixture_flag          = $args{-mixture};                      ## used to flag this is not a standard mixture
    my $catalog_list          = $args{-ids_list};
    my $possible_new_solution = $args{-possible_made};
    my $add_cat_flag          = $args{-add_to_catalog};

    if ($add_cat_flag) {
        Message('adding to catalog');
    }
    my $previous_label;
    my $previous_grp;

    ( my $stock_catalog_id ) = $dbc->Table_find( 'Stock_Catalog', 'Stock_Catalog_ID', "WHERE Stock_Catalog_Name = '$type'" );
    if ($stock_catalog_id) {
        $previous_label = alDente::Stock_App::_get_barcode_label(
            -catalog_id => $stock_catalog_id,
            -dbc        => $dbc
        );
        $previous_grp = alDente::Stock_App::_get_previous_grp(
            -catalog_id => $stock_catalog_id,
            -dbc        => $dbc
        );
    }

    ## Getting the preset information
    my @labels = $dbc->get_FK_info_list( 'FK_Barcode_Label__ID', "WHERE Barcode_Label_Type = 'Solution'" );    ## getting the list of labels
    my @target_fields;
    my %preset;
    my %list;
    my %grey;

    $grey{FK_Employee__ID} = $dbc->get_FK_info( 'FK_Employee__ID', $user_id );
    $grey{FK_Stock_Catalog__ID} = $stock_catalog_id if $type;
    $list{FK_Barcode_Label__ID} = \@labels;

    if ($mixture_flag) {
        my @solution_names = $dbc->get_FK_info_list( 'FK_Stock_Catalog__ID', "  Stock_Source = 'Made in House' AND FK_Organization__ID = 27 " );
        $list{FK_Stock_Catalog__ID} = \@solution_names;
        $preset{FK_Stock_Catalog__ID} = $possible_new_solution if $possible_new_solution;
        my $common_group = _get_common_group_name( -dbc => $dbc, -ids => $sol_ids );
        $preset{FK_Grp__ID} = $common_group if $common_group;
        my $common_barcode = _get_common_barcode_name( -dbc => $dbc, -ids => $sol_ids );
        $preset{FK_Barcode_Label__ID} = $common_barcode if $common_barcode;
    }
    else {
        $list{FK_Stock_Catalog__ID}   = $catalog_list   if $catalog_list;
        $preset{FK_Grp__ID}           = $previous_grp   if $previous_grp;
        $preset{FK_Barcode_Label__ID} = $previous_label if $previous_label;
    }

    if ($add_cat_flag) {
        $grey{Stock_Catalog_Name} = $type if $type;
        @target_fields = qw(Solution.Solution_Type Solution.Solution_Expiry Stock.FK_Grp__ID Stock.FK_Barcode_Label__ID  Stock_Catalog.Stock_Catalog_Name );
    }
    else {
        @target_fields = qw(Solution.Solution_Expiry Stock.FK_Grp__ID Stock.FK_Barcode_Label__ID  Stock.FK_Stock_Catalog__ID );
    }

    ## Building query form
    my $table = SDB::DB_Form->new(
        -dbc    => $dbc,
        -fields => \@target_fields,
        -target => 'Database',
        -wrap   => 0
    );
    $table->configure( -list => \%list, -grey => \%grey, -preset => \%preset );
    my $page .= $table->generate(
        -button       => { 'rm' => $button },
        -navigator_on => 0,
        -return_html  => 1
        )
        . $q->hidden(
        -name  => 'cgi_application',
        -value => 'alDente::Solution_App',
        -force => 1
        );
    $page .= $q->hidden( -name => 'AddingCatalog', -value => '1', -force => 1 ) if $add_cat_flag;

    my $outer = alDente::Form::init_HTML_table( -title => "Other Parameters", -width => '33%' );
    $outer->Set_Row( [$page] );

    return $outer->Printout(0);
}

##########################
sub _get_common_group_name {
##########################
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $ids  = $args{-ids};
    my @ids  = split ',', $ids;

    my @groups = $dbc->Table_find( 'Solution,Stock', 'FK_Grp__ID', "WHERE FK_Stock__ID = Stock_ID and Solution_ID IN ($ids)", 'Distinct' );
    my $size = @groups;
    if ( $size == 1 ) {
        my $name = $dbc->get_FK_info( 'FK_Grp__ID', -id => $groups[0] );

        return $name;
    }
    else {return}
}

##########################
sub _get_common_barcode_name {
##########################
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $ids  = $args{-ids};
    my @ids  = split ',', $ids;

    my @barcodes = $dbc->Table_find( 'Solution,Stock', 'FK_Barcode_Label__ID', "WHERE FK_Stock__ID = Stock_ID and Solution_ID IN ($ids)", 'Distinct' );
    my $size = @barcodes;
    if ( $size == 1 ) {
        my $name = $dbc->get_FK_info( 'FK_Barcode_Label__ID', -id => $barcodes[0] );

        return $name;
    }
    else {return}
}

##################
sub recalculate {
##################
    my $samples = shift;

    my $form_name = 'Mixture';
    my $qty_used  = 'Std_Quantities';
    my $qty_total = 'Solution_Quantity';
    my $ignore    = 'g';
    my $multiply  = 'Maximum Available Per Well';

    my $recalculate = "TrackTotal(document.$form_name, '$qty_used', '$qty_total', '$ignore');";

    if ($samples) {
        my $factor   = 1 / $samples;
        my $decimals = 2;              ## two significant digits ##
        $recalculate .= "MultiplyBy(document.$form_name,'$qty_total','$multiply',$factor,$decimals);";
    }

    #   my $fullcalculate  = "BrewCalc(document.$form_name);" . $recalculate;

    return $recalculate;
}

#########################
sub display_Actions {
#########################
    # Description:
    #     Displays action buttons from solutions
#########################
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc} || $self->{dbc};
    my $id     = $args{-id} || $self->{id};                  ### solution_id of solution
    
    my $status = $self->{Model}->value('Solution_Status');
    ( my $today ) = split ' ', &date_time();
    my @units = ( 'ml', 'ul', 'nl', 'pl', 'mg', 'ug', 'ng', 'pg' );

    my $page
        = alDente::Form::start_alDente_form( -dbc => $dbc )
        . $q->hidden( -name => 'Solution_ID',     -value => $id,                     -force => 1 )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Solution_App', -force => 1 )
        . $q->hidden( -name => 'rm',              -value => 'Solution Action',       -force => 1 );

    ## Generate footer options (opening and emptying bottles, reprinting barcode) ##
    unless ( $status eq 'Open' ) {
        $page .= $q->submit( -name => 'Action', -value => "Open", -class => 'Action' ) . " " . $q->textfield( -name => 'Open Date', -size => 12, -default => $today ) . '<BR>';
    }

    unless ( $status eq 'Finished' ) {
        my $dispense;
        my $transfer_title = '<Font size=-1><B>Transfer, Decant or Aliquot</B></Font>';
        unless ($scanner_mode) {
            $dispense = HTML_Table->new( -title => $transfer_title );
            $dispense->Set_Class('small');
            $dispense->Toggle_Colour('off');
        }

        my @prompts;
        my @rows;

        push( @prompts, "Amount:" );
        push( @rows, Show_Tool_Tip( $q->textfield( -name => 'Dispense Qty', -size => 5 ), "Entire volume assumed if not entered", 'no tips' ) . $q->popup_menu( -name => 'Dispense Units', -values => \@units ) );

        push( @prompts, "Repeat X:" );
        push( @rows, $q->textfield( -name => 'Containers', -size => 5, -default => '1' ) );

        my @valid_labels = $dbc->Table_find( "Barcode_Label", "Label_Descriptive_Name", "WHERE Barcode_Label_Type like 'Solution' AND Barcode_Label_Status='Active'" );

        unshift( @valid_labels, '--Select--' );
        if ( $#valid_labels > 0 ) {
            my $default_barcode_label = $dbc->get_FK_info( 'FK_Barcode_Label__ID', $self->{Model}->value('FK_Barcode_Label__ID'), );
            push( @prompts, "Label: " );
            push( @rows, $q->popup_menu( -name => "FK_Barcode_Label__ID", -values => \@valid_labels, -force => 1, -default => $default_barcode_label ) );
        }
        elsif ( $valid_labels[0] ) {
            $page .= $q->hidden( -name => 'FK_Barcode_Label__ID', -value => $valid_labels[0] );
        }

        push( @prompts, "Expiry Date:" );
        push( @rows, alDente::Tools::get_prompt_element( -dbc => $dbc, -name => 'Solution.Solution_Expiry', -force => 1 ) );

        foreach my $index ( 0 .. $#rows ) {
            if ($scanner_mode) {
                $page .= "$prompts[$index] $rows[$index]<BR>";
            }
            else {
                $dispense->Set_Row( [ "<B>$prompts[$index]</B>", $rows[$index] ] );
            }
        }

        $page .= $dispense->Printout(0) unless $scanner_mode;
        ## Hide if solution is already finished

        $page .= Show_Tool_Tip( $q->submit( -name => 'Action', -value => 'Transfer', -class => "Action", -force => 1 ), "Empties original bottle",                                                   $scanner_mode ) . hspace(5);
        $page .= Show_Tool_Tip( $q->submit( -name => 'Action', -value => 'Decant',   -class => "Action", -force => 1 ), "Just remove volume from current bottle (no tracking of portion dispensed)", $scanner_mode ) . hspace(5);
        $page .= Show_Tool_Tip( $q->submit( -name => 'Action', -value => 'Aliquot',  -class => "Action", -force => 1 ), "same as Transfer, but does NOT imply original bottle is emptied.",          $scanner_mode );
    }

    $page .= $q->end_form();

    return $page;
}

###########################
sub delete_solution_button {
###########################
    #
    #
###########################
    my %args = &filter_input( \@_, -args => 'dbc,id' );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my $page
        = alDente::Form::start_alDente_form( -dbc => $dbc )
        . $q->hidden( -name => 'Solution_ID', -value => $id, -force => 1 )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Solution_App', -force => 1 )
        . $q->submit( -name => 'rm', -value => 'Delete Solution', -force => 1, -class => 'action' )
        . $q->end_form();

    return $page;
}

##############################
sub delete_confirmation_page {
##############################
    my %args       = &filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $ids        = $args{-ids};
    my $ref_tables = $args{-ref_tables};
    my $ref_fields = $args{-ref_fields};
    my $debug      = $args{-debug};
    my $delete_prevent;

    my $messages;

    if ($ref_tables) {

        # $ref_tables contains links which sometimes have comma-delimited lists embedded
        # in them. Therefore split by link tag (</a>) to avoid breaking the links.
        my @tables = split /<\/a>,/i, $ref_tables;
        my @broken_links = splice( @tables, 0, -1 );
        my $last_link = $tables[-1];

        @tables = map { $_ .= '</a>' } @broken_links;
        push @tables, $last_link;

        my %fields = %$ref_fields if $ref_fields;
        my @fields = keys %fields;
        my %table_hash;

        foreach my $link (@tables) {
            $link =~ /<a.+Field=(\w+).+>(.+)<\/a>/i;
            my $record = "$2.$1";
            Message( "Deleting " . scalar @{ $fields{$record} } . " records in " . $link );
        }

        if ( grep /FKUsed_Solution__ID/, @fields ) {
            $delete_prevent = 1;
            $messages .= "This solution cannot be deleted because it was used to create other solutions.";
        }
        elsif ( grep /Plate_Prep/, @tables ) {
            $delete_prevent = 1;
            $messages .= "This solution cannot be deleted because it was used in a protocol.";
        }
        elsif ( grep /SequenceRun|GelRun/, @tables ) {
            $delete_prevent = 1;
            $messages .= "This solution cannot be deleted because it was used in a run.";
        }
        elsif ( grep /Primer_Plate|QC_Batch/, @tables ) {
            $delete_prevent = 1;
            $messages .= "This solution cannot be deleted because it was used in a primer plate or QC batch.";
        }

    }

    unless ($delete_prevent) {
        $messages = "Are you sure you wish to delete these solutions and the fields that reference them?" . vspace();
    }

    my $page = alDente::Form::start_alDente_form( $dbc, 'confirmation' )
        . $dbc->Table_retrieve_display(
        -table       => 'Solution',
        -title       => 'Solution',
        -condition   => " WHERE Solution_ID IN ($ids)",
        -fields      => ['*'],
        -return_html => 1
        )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Solution_App', -force => 1 )
        . $q->hidden( -name => 'Solution_ID',     -value => $ids,                    -force => 1 )
        . $q->hidden( -name => 'confirmed',       -value => '1',                     -force => 1 )
        . vspace()
        . $messages;

    unless ($delete_prevent) {
        $page .= $q->submit( -name => 'rm', -value => 'Delete Solution', -force => 1, -class => "Action" );
    }

    $page .= $q->end_form('confirmation');
    return $page;
}

###########################
sub display_list_page {
###########################
    #
    #
###########################
    my %args = @_;
    my $dbc  = $args{-dbc};
    my $list = $args{-list};

    my $table = $dbc->Table_retrieve_display(
        -table            => "Solution,Stock,Stock_Catalog",
        -fields           => [ 'Solution_ID', 'Stock_Catalog_Name', 'Solution_Type', 'FK_Rack__ID', 'Stock_Received', 'Solution_Status', 'QC_Status' ],
        -condition        => "WHERE Solution_ID IN ($list) AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__Id = Stock_Catalog_ID",
        -selectable_field => 'Solution_ID',
        -return_html      => 1,
    );

    my ($finished) = $dbc->Table_find( "Solution", "Solution_ID", "WHERE Solution_ID IN ($list) AND Solution_Status = 'Finished'" );

    require alDente::QA;
    my $qc_table;
    if ( !$finished ) {
        $qc_table = HTML_Table->new( -title => "QC Options" );
        my $qc_status = &alDente::QA::check_for_qc( -ids => $list, -table => "Solution", -dbc => $dbc );
        my $qc_prompt = &alDente::QA_Views::get_qc_prompt(
            -dbc       => $dbc,
            -qc_status => $qc_status,
            -tables    => 'Solution'
        );
        $qc_table->Set_Row( [$qc_prompt] );
        $qc_table = $qc_table->Printout(0);
    }

    my $view
        = alDente::Form::start_alDente_form( -dbc => $dbc )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::QA_App', -force => 1 )
        . $q->hidden( -name => 'type',            -value => 'Solution',        -force => 1 )
        . $table
        . vspace()
        . $qc_table
        . $q->end_form();

    return $view;
}

###########################
sub display_mix_block {
###########################
    #
    #
###########################
    my %args               = @_;
    my $dbc                = $args{-dbc};
    my $default_block_size = $User_Setting{BLOCK_SIZE} || 384;

    my @StandardSolutionList = @{
        $dbc->Security->get_accessible_items(
            -table           => 'Standard_Solution',
            -extra_condition => "Standard_Solution_Status = 'Active'"
        )
        };
    my $header = LampLite::Login_Views->icons( -name => 'Test_Tubes', -dbc => $dbc );
    
    my $block = $q->submit(
        -name  => 'rm',
        -value => 'Prepare Standard Solution',
        -class => "Std",
        -force => 1
        )
        . '   :   '
        . Show_Tool_Tip(
        $q->popup_menu(
            -name    => 'Make Std Solution',
            -values  => [ '', @StandardSolutionList ],
            -default => ''
        ),
        "If your solution does not show up here, make sure you are in the correct department (tabs at top)"
        )
        . "   For:   "
        . $q->textfield( -name => 'Blocks', -size => 4, -default => '1' ) . " x "
        . $q->popup_menu(
        -name   => 'BlocksX',
        -values => [ '', 384, 96, 1 ],
        -default => $default_block_size -class => 'normal-txt',
        ) . " Samples";

    my $search_link = 'Search for: ' . &Link_To( $dbc->config('homelink'), 'Solution/Reagent', '&Search+for=1&Table=Solution' );

    my $table = alDente::Form::init_HTML_table( -left => 'Reagents / Solutions', -right => $search_link, -margin => 'on' );

    $table->Set_Row( [ '', $block ] );
    $table->Set_Row( [ $header, "<HR>" ] );

    $table->Set_Row(
        [   '',
            "Solutions to dilute:"
                . &hspace(5)
                . $q->textfield( -name => "Diluted Solutions" )
                . "&emsp;"
                . HTML_Comment("(scan barcodes)") . "<BR>"
                . "Water solution:"
                . &hspace(20)
                . $q->textfield( -name => "Water Solution" )
                . "&emsp;"
                . HTML_Comment("(scan barcode)") . "<BR>"
                . $q->submit(
                -name    => 'rm',
                -value   => 'Batch Dilute',
                -class   => "Action",
                -onClick => 'return validateForm(this.Batch_Block)'
                )
        ]
    );

    my $page = alDente::Form::start_alDente_form( $dbc, 'Mix Block' ) 
        . $table->Printout(0)
        . $q->hidden(
        -name  => 'cgi_application',
        -value => 'alDente::Solution_App',
        -force => 1
        ) . $q->end_form();
    return $page;
}

###########################
sub display_Solution_Options {
###########################
    #
    #
###########################
    my %args         = filter_input( \@_ );
    my $dbc          = $args{-dbc};
    my $solution_ids = $args{-solution_ids};
    my $page;

    my $empty_prompt = $q->submit( -name => 'rm', -value => 'Empty Solution(s)', -class => "Action" );
    my $reprint_prompt
        = $q->submit( -name => 'rm', -value => 'Re-Print Solution Labels', -class => 'Std' )
        . alDente::Tools::search_list( -dbc => $dbc, -field => 'FK_Barcode_Label__ID', -condition => "Barcode_Label_Type like 'solution' AND Barcode_Label_Status ='Active'" )
        . vspace()
        . "Repeat: "
        . $q->popup_menu( -name => 'Repeat', -value => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] )
        . ' time(s)';

    my $sol_table = HTML_Table->new( -title => "Solution Options" );
    $sol_table->Set_Row( [$empty_prompt] );
    $sol_table->Set_Row( [$reprint_prompt] );

    $page .= alDente::Form::start_alDente_form( $dbc, -form => 'Display_Solution_Options' );
    $page .= $sol_table->Printout(0);
    $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Solution_App', -force => 1 );
    $page .= $q->hidden( -name => 'Solution_ID',     -value => $solution_ids );
    $page .= $q->end_form();

    return $page;

}

###########################
sub display_batch_block {
###########################
    #
    #
###########################
    my %args         = @_;
    my $dbc          = $args{-dbc};
    my @valid_labels = $dbc->Table_find( "Barcode_Label", "Label_Descriptive_Name", "WHERE Barcode_Label_Type like 'Solution' AND Barcode_Label_Status='Active'" );
    my $header;

    my $reprint_prompt;
    if ( $#valid_labels > 0 ) {
        unshift( @valid_labels, '--Select--' );
        $reprint_prompt .= $q->popup_menu( -name => "Barcode Name", -values => \@valid_labels );
    }
    elsif ( $valid_labels[0] ) {
        $reprint_prompt .= $q->hidden( -name => 'Barcode Name', -value => $valid_labels[0] );
        $reprint_prompt .= " <i>($valid_labels[0])</i>";
    }
    my $location_list = alDente::Rack::get_export_locations( -dbc => $dbc );

    my $block
        .= "Scan reagent(s)/solution(s) -> "
        . $q->textfield( -name => 'Solution_ID', -size => 20 )
        . set_validator( -name => 'Solution_ID', -mandatory => 1, -prompt => 'You must indicate the solutions ids' )
        . vspace()
        . $q->submit( -name => 'rm', -value => 'Activate Solutions', -class => "Action", -onClick => 'return validateForm(this.form)' )
        . hspace()
        . 'Expiry Date: '
        . $q->textfield( -name => 'Active_Expiry_Date', -id => 'Active_Expiry_Date', -size => 20 )
        . $BS->calendar( -id => 'Active_Expiry_Date', -show_time => 'false', -format => 'Y-m-d', -close_on_date => 'true' )
        . vspace()
        . $q->submit( -name => 'rm', -value => 'Empty Solution(s)', -class => "Action", -onClick => 'return validateForm(this.form)' )
        . hspace()
        . vspace()
        . $q->submit( -name => 'rm', -value => 'Re-Print Solution Labels', -class => "Std", -onClick => 'return validateForm(this.form)' )
        . hspace()
        . $reprint_prompt
        . vspace()
        . $q->submit( -name => 'rm', -value => 'Set Expiry Date', -class => "Action", -onClick => 'return validateForm(this.form)' )
        . hspace()
        . $q->textfield( -name => 'Expiry_Date', -id => 'Expiry_Date', -size => 20 )
        . $BS->calendar( -id => 'Expiry_Date', -show_time => 'false', -format => 'Y-m-d', -close_on_date => 'true' )
        . vspace()
        . $q->submit( -name => 'rm', -value => 'Export Solution(s)', -class => "Action", -onClick => 'return validateForm(this.form)' ) . ' To: '
        . hspace(3)
        . $q->popup_menu( -name => 'Destination', -values => $location_list, -force => 1 )
        . "Comments: "
        . $q->textfield( -name => 'Export_Comments', -size => 17 )
        . &Link_To( $dbc->config('homelink'), 'Add NEW Location', "&cgi_application=alDente::Rack_App&rm=Add New Location", 'red' );

    my $table = alDente::Form::init_HTML_table( "Batch Options", -margin => 'on' );
    $table->Set_Row( [ $header, $block ] );

    my $page = alDente::Form::start_alDente_form( $dbc, 'Batch_Block' )
        . $q->hidden(
        -name  => 'cgi_application',
        -value => 'alDente::Solution_App',
        -force => 1
        )
        . $table->Printout(0)
        . $q->end_form();
    return $page;
}

###########################
sub display_scanner_mode {
###########################
    #
    #
###########################
    my %args = @_;
    my $dbc  = $args{-dbc};

    my $default_block_size = $User_Setting{BLOCK_SIZE} || 384;

    my @StandardSolutionList = @{
        $dbc->Security->get_accessible_items(
            -table           => 'Standard_Solution',
            -extra_condition => "Standard_Solution_Status = 'Active'"
        )
        };
    my $header;

    my $blocks_query = $q->textfield( -name => 'Blocks', -size => 4, -default => '1' );
    my $blocks_x = $q->popup_menu(
        -name    => 'BlocksX',
        -values  => [ '', 384, 96, 1 ],
        -default => $default_block_size,
    );

    my $block_prompt = "for: " . $blocks_query . " x " . $blocks_x . " Samples";

    my $mix_prompt = $q->submit(
        -name    => 'rm',
        -value   => 'Prepare Standard Solution',
        -class   => 'Std',
        -style   => 'height:46px;',                                                ### overrides form-control height setting
        -force   => 1,
        -onclick => "return validateForm(this.form,'','','Make Std Solution');",
        -size    => 'large',
    );

    my $options = Show_Tool_Tip(
        $q->popup_menu(
            -name        => 'Make Std Solution',
            -values      => [ '-- Select Std Mixture --', @StandardSolutionList ],
            -default     => '-- Select Std Mixture --',
            -placeholder => 'Select Mixture',
        ),
        "If your solution does not show up here, make sure you are in the correct department (tabs at top)"
    );

    my $empty_prompt = $q->textfield( -name => 'Solution_ID', -size => 20 ) . $q->submit( -name => 'rm', -value => 'Empty Solution(s)', -class => "Action", -onclick => "return validateForm(this.form,'','','Solution_ID');" );

    my $empty_prompt = $BS->text_group_element(
        -append_button_text => 'Empty Solution(s)',
        -placeholder        => 'SOL#',
        -name               => 'Solution_ID',
        -run_mode           => 'Empty Solution(s)',
        -tooltip            => "Empty Scanned Solutions",
        -button_class       => 'Action',
        -app                => 'alDente::Solution_App',
        -flex               => [ 0,, 1 ],
    );

    my $scan_block;    ##  = alDente::Web::scan_button($dbc);   ## included in header

    my $sol_block
        = alDente::Form::start_alDente_form( $dbc, 'Scanner Mode Standard' )
        . "$block_prompt"
        . "<P></P>$empty_prompt <BR>"
        . $mix_prompt
        . set_validator( -name => 'Make Std Solution', -mandatory => 1 )
        . set_validator( -name => 'Solution_ID',       -mandatory => 1 )
        . $q->hidden(
        -name  => 'cgi_application',
        -value => 'alDente::Solution_App',
        -force => 1
        ) . $q->end_form();

###
    my $validations = set_validator( -name => 'Make Std Solution', -mandatory => 1 ) .  set_validator( -name => 'Solution_ID', -mandatory => 1 ) . set_validator( -name => 'Blocks', -mandatory => 1 ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Solution_App', -force => 1 );

    my $Form = new LampLite::Form(-dbc=>$dbc, -framework=>'bootstrap');
    $Form->append(-label=>'Prepare:', -input=> $options);
    $Form->append(-label=>'', -input=> $block_prompt, -no_format=>1);
    $Form->append(-label=>'',-input=> $mix_prompt );
    $Form->append(-label=>'', -input=> '<hr>');
    $Form->append(-label=>'', -input=> $BS->form_element( -input => $empty_prompt, -span => [ 0, 12 ] ));
    
    my $start_tag = alDente::Form::start_alDente_form( $dbc, 'prep', -class=>'form-horizontal'); 
    return $Form->generate(-open=>1, -close=>1, -tag=>$start_tag, -include=>$validations);
}

##########################
sub new_catalog_link {
##########################
    my %args   = @_;
    my $flag   = $args{-flag};                ## optional flag to include along with standard rm.
    my $dbc    = $args{-dbc};
    my $access = $dbc->get_local('Access');

    if ($flag) { $flag = "&$flag=1" }
    if ( grep( /Admin/, @{ $access->{ $dbc->config('Target_Department') } } ) || $access->{'LIMS Admin'} ) {
        return &Link_To(
            $dbc->homelink(),
            ' (define new Solution for Catalog)',
            "&cgi_application=alDente::Stock_App&rm=Catalog+Form&dbc=$dbc" . "$flag",
            undef, ['newCat'], -tooltip => 'Click here to define a new Catalog item if this is a new type of Reagent/Solution etc<BR>You will need to then refresh this screen to enable choosing that item'
        );
    }
    else {
        return ('If you wish to add to catalog please ask an admin for assistance. You need admin permission to add to catalog.  ');
    }
}

##########################
sub display_Solution_to_Plate {
##########################
    my %args      = @_;
    my $dbc       = $args{-dbc};
    my $plates    = $args{-plates};
    my $solutions = $args{-solutions};

    my $page = alDente::Form::start_alDente_form( $dbc, 'PlateSolution' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Prep_App', -force => 1 );
    my @solutions      = split ',', $solutions;
    my $solution_count = int @solutions;
    my @solution_units = SDB::DBIO::get_enum_list( $dbc, 'Plate_Prep', 'Solution_Quantity_Units' );

    for my $index ( 0 .. $solution_count - 1 ) {
        $page .= $q->hidden( -name => 'Solution_' . $index, -value => $solutions[$index], -force => 1 ) 
            . $q->textfield( -name => 'Apply Quantity_' . $index, -size => 5, -force => 1 )
            . $q->popup_menu(
            -name   => 'Quantity_Units_' . $index,
            -values => \@solution_units,
            -force  => 1,
            -width  => 20
            )
            . " of "
            . alDente_ref( 'Solution', $solutions[$index], -dbc => $dbc )
            . " to Plate(s)"
            . vspace();
    }

    $page
        .= $q->submit( -name => 'rm', -value => 'Apply Solution to Plate', -class => "Action", -force => 1 )
        . $q->hidden( -name => 'Plate_ID', -value => $plates )
        . $q->hidden( -name => 'Number_of_Solutions', -value => $solution_count, -force => 1 )
        . $q->end_form();
    return $page;

}

####################
sub display_Search_Box {
####################
    my %args   = filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $header = LampLite::Login_Views->icons( -name => 'Search', -no_label => 1, -no_link => 1, -dbc => $dbc );

    ## Building block elements

    my $rack_search
        = alDente::Form::start_alDente_form( $dbc, 'Search Options' )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Solution_App', -force => 1 )
        . $q->hidden( -name => 'rm', -value => 'Extensive Solution Search', -force => 1 )
        . create_tree( -tree => { "Extensive Search" => alDente::Rack_Views::find_in_rack( -dbc => $dbc, -find => 'Solution', -form => 0 ) }, -print => 0 )
        . $q->end_form();

    my $quick_search
        = "Search string: "
        . $q->textfield( -name => 'Search String', -size => 20 )
        . HTML_Comment("(use * for wildcard)")
        . " for items owned by: "
        . alDente::Tools::search_list( -name => 'FK_Grp__ID', -dbc => $dbc )
        . vspace()
        . Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'Find Solution', -class => "Search" ) . HTML_Comment("- Searches Database for Stock Supplies (Grouped by Name : Size)") );

    my $expire
        = Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'Soon to Expire', -class => "Search" ), "Find items that are expected to expire within specified time frame" )
        . ' within '
        . $q->textfield( -name => 'Since', -size => 5, -default => 30 ) . ' days';

    my $recent
        = Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'Check Recently Created Solutions', -class => "Search" ), "Find Solutions that have been made by me" )
        . ' within: '
        . $q->textfield( -name => 'MadeWithin', -size => 5, -default => 30 )
        . ' days '
        . $q->checkbox( -name => 'All users', -force => 1 )
        . vspace()
        . Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'Check Recently Received Reagents', -class => "Search" ), "Find Reagents received recently" );

    my $applications
        = Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'Check Applications', -class => "Search" ), "Find Applications" ) . " of " . Show_Tool_Tip( $q->textfield( -name => 'Solution_ID', -size => 10 ), "Scan list of Solutions to check for" );

    my $block
        = $rack_search . "<HR>"
        . alDente::Form::start_alDente_form( $dbc, 'Search Options' )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Solution_App', -force => 1 )
        . $quick_search . "<HR>"
        . $expire . "<HR>"
        . $recent . "<HR>"
        . $applications . "<HR>"
        . $q->end_form();

    my $table = alDente::Form::init_HTML_table( "Search Options", -margin => 'on' );
    $table->Set_Row( [ $header, $block ] );

    my $page = $table->Printout(0);
    return $page;

}

1;
