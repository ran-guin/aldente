###################################################################################################################################
# alDente::Solution_App.pm
#
#
#
#
###################################################################################################################################
package alDente::Solution_App;

use base RGTools::Base_App;
use strict;

## SDB modules
use SDB::CustomSettings;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;
use RGTools::Conversion;

## alDente modules
#use alDente::Form;
use alDente::Stock_App;
use alDente::Stock;
use alDente::Solution_Views;
use alDente::Solution;
use alDente::SDB_Defaults;

use LampLite::Bootstrap;
use vars qw( $Connection %Configs  $Security);

######################################################
##          Controller                              ##
######################################################
my $BS = new Bootstrap();

###########################
sub setup {
###########################

    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Add New Item to Catalog'          => 'new_catalog_item',
        'Batch Dilute'                     => 'dilute_batch',
        'Check Chemistry Calculator'       => 'display_chem_calculator',
        'default'                          => 'entry_page',
        'Define New Primer'                => 'new_primer_table',
        'Delete Solution'                  => 'delete_Solution',
        'Empty Solution(s)'                => 'empty_solution',
        'Home'                             => 'main_page',
        'List'                             => 'list_page',
        'Prepare Standard Solution'        => 'display_standard_solution_page',
        'New Primer Stock'                 => 'new_primer_stock',
        'Re-Print Solution Labels'         => 'print_barcode',
        'Save Batch Info'                  => 'save_batch_dilute',
        'Save Standard Mixture'            => 'save_standard_mixture',
        'Mix Box Contents'                 => 'save_standard_mixture',
        'Set Valid Primer for Vector'      => 'new_vector',
        'Re-calculate Standard Solution'   => 'display_standard_solution_page',
        'Soon to Expire'                   => 'display_expiring_solutions',
        'Check Recently Created Solutions' => 'recent_Solutions',
        'Check Recently Received Reagents' => 'recent_Solutions',
        'Find Solution'                    => 'search_Solution',
        'Check Applications'               => 'show_Reagent_Applications',
        'Extensive Solution Search'        => 'find_Solution',
        'Set Expiry Date'                  => 'set_expiry_date',
        'Solution Action'                  => 'solution_actions',
        'Export Solution(s)'               => 'export_Solution',
        'Activate Solutions'               => 'activate_Solutions',
    );
    my $dbc = $self->param('dbc');

    #$q   = $self->query();

    my $Solution = alDente::Solution->new( -dbc => $dbc );
    my $View = new alDente::Solution_Views( -model => $Solution, -dbc => $dbc );

    $self->param( 'Model' => $Solution );
    $self->param( 'View'  => $View );
    $self->param( 'dbc'   => $dbc );

    $ENV{CGI_APP_RETURN_ONLY} = 1;
    return $self;

}

###########################
sub list_page {
###########################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $list = $q->param('list') || $args{-list};
    return alDente::Solution_Views::display_list_page( -dbc => $dbc, -list => $list );
}

###########################
sub entry_page {
###########################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $id   = $q->param('ID') || $args{-id};

    unless ($id) { return $self->main_page( -dbc => $dbc ) }
    if ( $id =~ /,/ ) { return $self->list_page( -dbc => $dbc, -list => $id ) }
    else              { return $self->home_page( -dbc => $dbc, -id => $id ) }
    return 'Error: Inform LIMS';
}

###########################
sub main_page {
###########################
    #
    # General Equipment home page...
    #
    # This is NOT used for scanner mode
    #
###########################
    my $self = shift;
    my $dbc = $self->param('dbc') || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $page;
    if ($scanner_mode) {
        $page .= alDente::Solution_Views::display_scanner_mode( -dbc => $dbc );
    }
    else {
        $page .= page_heading("Chemical/Reagent/Solution Main Page");
        $page .= alDente::Solution_Views::display_mix_block( -dbc => $dbc );
        $page .= alDente::Solution_Views::display_batch_block( -dbc => $dbc );
        if ( $dbc->package_active('Genomic') ) {
            $page .= $self->display_primer_block( -dbc => $dbc );
        }
        $page .= $self->display_search_block( -dbc => $dbc );
        $page .= $self->display_chemistry_block( -dbc => $dbc );
        $page .= vspace(2) . alDente::Solution_Views::new_catalog_link( -flag => 'in_house', -dbc => $dbc );
    }

    #    print $page;
    return $page;
}

###########################
sub home_page {
###########################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $id   = $q->param('id') || $args{-id};
    my $View = new alDente::Solution_Views( -dbc => $dbc, -id => $id );
    my $view = $View->home_page();
    return $view;
}

###########################
sub solution_actions {
###########################
    my $self       = shift;
    my %args       = @_;
    my $q          = $self->query;
    my $dbc        = $self->param('dbc');
    my $id         = $q->param('Solution_ID') || $q->param('id');
    my $action     = $q->param('Action');
    my $open_date  = $q->param('Open Date');
    my $quantity   = $q->param('Dispense Qty');
    my $units      = $q->param('Dispense Units');
    my $containers = $q->param('Containers');
    my $label      = $q->param('FK_Barcode_Label__ID') || $q->param('FK_Barcode_Label__ID Choice');
    my $expiry     = $q->param('Solution-Solution_Expiry') || $q->param('Solution_Expiry');

    if ( $action =~ /open/i ) {
        open_bottle( $id, $open_date );
    }
    elsif ( $label && $quantity && $label !~ /Select/i ) {
        ($quantity) = &convert_to_mils( $quantity, $units );
        my ( $decant, $empty );
        if    ( $action =~ /Transfer/i ) { $empty  = 1 }
        elsif ( $action =~ /Decant/i )   { $decant = 1 }
        dispense_solution( -dbc => $dbc, -sol_id => $id, -total => $quantity * $containers, -bottles => $containers, -decant => $decant, -empty => $empty, -label => $label, -expiry => $expiry );
    }
    else {
        $dbc->error("Barcode Label or Quantity is mandatory");
    }

    my $View = new alDente::Solution_Views( -dbc => $dbc, -id => $id );
    my $view = $View->home_page();
    return $view;
}

##########################
sub display_expiring_solutions {
##########################
    my $self      = shift;
    my $q         = $self->query;
    my $dbc       = $self->param('dbc');
    my $day_range = $q->param('Since');

    return alDente::Solution::expiring_solutions( -dbc => $dbc, -days => $day_range );
}

##########################
sub show_Reagent_Applications {
##########################
    my $self     = shift;
    my $q        = $self->query;
    my $dbc      = $self->param('dbc');
    my $reagent  = join ',', $q->param('Solution_ID');
    my $protocol = join ',', $q->param('Protocol_ID');
    my $since    = $q->param('AppliedSince');
    my $page .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Applications' );
    $page .= alDente::Solution::show_applications( -dbc => $dbc, -solution_id => $reagent, -protocol_id => $protocol, -include_reagents => 1, -form => 'Applications' );

    $page .= submit( -name => 'Last 24 Hours', -value => 'Downstream Cap Seq Summaries', -class => 'Search', -onclick => "SetSelection(this.form,'cgi_application','');" );

    ## this block should replace similar block in Button Options - still used and tested in Button_Options ##

    ## add additional link for Illumina using MVC (Last 24 Hours link above still needs to be removed from Button_Options) ##
    $page .= &hspace(5);
    $page .= submit( -name => 'Solexa Runs', -value => 'Downstream Solexa Summaries', -class => 'Search', -onclick => "SetSelection(this.form,'cgi_application','Illumina::Solexa_Summary_App');" );
    ## parameters below only applicable for Illumina run mode at this time ##
    $page .= hidden( -name => 'rm', -value => 'Results', -force => 1 );
    $page .= hidden( -name => 'cgi_application', -value => '', -force => 1 );

    $page .= $q->hidden( -name => 'Any Date', -value => 1 );
    $page .= $q->end_form();

    return $page;

}

##########################
sub find_Solution {
##########################
    my $self      = shift;
    my $q         = $self->query;
    my $dbc       = $self->param('dbc');
    my $name      = $q->param('Stock_Catalog_Name');
    my $group     = $q->param('FK_Grp__ID') || $q->param('Grp');
    my $type      = $q->param('Solution_Type');
    my @equipment = $q->param('Equipment_Name Choice');
    my $rack      = $q->param('FK_Rack__ID Choice');

    my $condition  = "WHERE 1 ";
    my $page       = &Views::Heading("Solution Results");
    my @field_list = ( "Solution_ID", "FK_Stock__ID", "concat(Solution_Number,' of ',Solution_Number_in_Batch) as Bottle", "Solution_Status as Status", "Solution_Started as Started", 'FK_Rack__ID as Location' );
    if ($group) {
        my $grp_id = $dbc->get_FK_ID( 'FK_Grp__ID', $group );
        $condition .= " AND Stock.FK_Grp__ID = $grp_id";
    }
    if ($type) {
        $condition .= " AND Solution.Solution_Type = '$type'";
    }
    if ($name) {
        $name =~ s/\*/\%/g;
        $condition .= " AND Stock_Catalog_Name LIKE '$name'";
    }
    if ( int @equipment ) {
        my $equipment_name = Cast_List( -list => \@equipment, -to => 'string', -autoquote => 1 );
        my $racks = join ',', $dbc->Table_find( 'Rack,Equipment', 'Rack_ID', "WHERE FK_Equipment__ID = Equipment_ID and Equipment_Name IN ($equipment_name)" );
        $condition .= " AND Solution.FK_Rack__ID IN ($racks)" if $racks;
    }
    if ($rack) {
        my $rack_id = $dbc->get_FK_ID( 'FK_Rack__ID', $rack );
        $condition .= " AND Solution.FK_Rack__ID IN ($rack_id)" if $rack_id;
    }

    my $solution_ids = join ',', $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Solution_ID', "$condition AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID " );
    if ( $solution_ids =~ /\d/ ) {
        $page .= SDB::DB_Form_Viewer::mark_records( $dbc, 'Solution', \@field_list, "WHERE Solution_ID in ($solution_ids)", -run_modes => [ 'Delete Record', 'Barcode_Event:Re-Print Solution Labels' ], -return_html => 1 );
    }
    else {
        Message("No Solutions matched your search criteria.");
    }

    return $page;
}

##########################
sub search_Solution {
##########################
    my $self   = shift;
    my $q      = $self->query;
    my $dbc    = $self->param('dbc');
    my $string = $q->param('Search String');
    my $group  = $q->param('FK_Grp__ID');

    my $title .= " (containing '$string')" if $string;
    $title    .= " (Group: $group)"        if $group;
    my $page = &Views::Heading($title);
    my $grp_id = $dbc->get_FK_ID( 'FK_Grp__ID', $group ) if $group;

    my $stock_obj = new alDente::Stock( -dbc => $dbc );
    my $Stock_Info = $stock_obj->find_Stock( -dbc => $dbc, -type => 'Solution', -cat_name => $string, -group => $grp_id, -title => "Finding Reagents/Solutions" );    ##, -condition => $date_condition
    $page .= alDente::Stock_Views::display_stock_inventory( -dbc => $dbc, -info => $Stock_Info, -type => 'Solution', -search => $string, -group => $grp_id );
    return $page;
}

##########################
sub recent_Solutions {
##########################
    my $self      = shift;
    my $q         = $self->query;
    my $dbc       = $self->param('dbc');
    my $rm        = $q->param('rm');
    my $day_range = $q->param('MadeWithin') || $q->param('Since');
    my $all_users = $q->param('All users');

    my $condition = "WHERE 1 ";
    my $page;

    my $user_id = $dbc->config('user_id');
    my @field_list = ( "Solution_ID", "FK_Stock__ID", "concat(Solution_Number,' of ',Solution_Number_in_Batch) as Bottle", "Solution_Status as Status", "Solution_Started as Started", 'FK_Rack__ID as Location' );

    if ($day_range) {
        $condition .= " AND DATE_SUB(CURDATE(),INTERVAL $day_range DAY) <= Solution_Started";
    }
    unless ($all_users) {
        $condition .= " AND Stock.FK_Employee__ID = $user_id";
    }

    if ( $rm =~ /created/i ) {
        $page      .= &Views::Heading("Created Solutions");
        $condition .= " AND Stock_Catalog.Stock_Source='Made in House'";
    }
    elsif ( $rm =~ /received/i ) {
        $page .= &Views::Heading("Recordeceived Reagents");
        ## <Construction> - not sure how items extracted from boxes are dated (?), so am just excluding 'made in house' stock.
        $condition .= " and Stock_Catalog.Stock_Source <> 'Made in House'";
    }

    my $solution_ids = join ',', $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Solution_ID', "$condition AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID" );
    if ( $solution_ids =~ /\d/ ) {
        $page .= SDB::DB_Form_Viewer::mark_records( $dbc, 'Solution', \@field_list, "WHERE Solution_ID in ($solution_ids)", -run_modes => [ 'Delete Record', 'Barcode_Event:Re-Print Solution Labels' ], -return_html => 1 );
    }
    else {
        Message("No Solutions matched your search criteria.");
    }

    return $page;
}

##########################
sub delete_Solution {
##########################
    my $self      = shift;
    my $q         = $self->query;
    my $dbc       = $self->param('dbc');
    my $confirmed = $q->param("confirmed");
    my $id        = $q->param("Solution_ID");

    my ( $ref_tables, $details, $ref_fields ) = $dbc->get_references(
        -table    => 'Solution',
        -field    => 'Solution_ID',
        -value    => $id,
        -indirect => 1
    );

    if ($confirmed) {
        my $ok = alDente::Solution::delete_Solution( -id => $id, -dbc => $dbc );
        return "SOL" . $id . " was deleted successfully." if $ok;
    }
    else {
        return alDente::Solution_Views::delete_confirmation_page(
            -dbc        => $dbc,
            -ids        => $id,
            -ref_tables => $ref_tables,
            -ref_fields => $ref_fields,
        );
    }

}

####################################
sub display_standard_solution_page {
####################################
    #
    #
###########################
    my $self      = shift;
    my %args = filter_input(\@_);
    
    my $q         = $self->query;                                                                       ### ids of solutions to mix together...
    my $ids       = $args{-ids} || $self->param('ids'); 
    my $name      = $args{-name};
    my $type      = $q->param('Make Std Solution') || $q->param('Last Solution');
    my $dbc       = $self->dbc() || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $blocks    = $q->param('Blocks');
    my $blocksX   = $q->param('BlocksX');
    my $samples   = $q->param('Samples');
     my $solutions = $self->param('solutions') || 2;                                                          ### optional number of solutions to mix together
    my $page;

    $ids =~s/\s//g;   ## clear blank space to enable comparison between exact validation lists and given lists 
    
    if ( !$ids && !$type ) {
        Message 'You need to select a standard solution or scan in the reagent ids';
        if ($scanner_mode) {
            return alDente::Solution_Views::display_scanner_mode( -dbc => $dbc );
        }
        else {
            return alDente::Solution_Views::display_mix_block( -dbc => $dbc );
        }
    }

    if ( $blocksX && $blocks ) { $samples = $blocks * $blocksX }

    my %Sol;
    my $include_well_totals = 0;
    if ($type) {
        %Sol = &alDente::Chemistry::Chemistry_Parameters( -dbc => $dbc, -type => $type, -samples => $samples );
        $Sol{name} = $type;
        $include_well_totals = 1;
    }
    elsif ($ids) {
        my $valid_ids = &SDB::DBIO::valid_ids(
             $dbc, $ids, 'Solution',
            -validate   => 1,
            -qc_check   => 1,
            -fatal_flag => 0
        ) if $ids;
        
        $Sol{name} = $name; 
        $type = $name; 
        
        unless ( $valid_ids eq $ids ) {
            $dbc->warning( "Some entered ID(s) were invalid (expired solution?) and have been omitted");
            $ids = $valid_ids;
            my @solutions = split( ',', $ids );
            $solutions = scalar(@solutions);
        }

        my $index    = 0;
        my @solnames = ();
        my $def_Type = '';
        $Sol{solutions} = $solutions;

        foreach my $id ( split ',', $ids ) {
            my ( $name, $size_units ) = split ',', join ',',
                $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Stock_Catalog_Name,Stock_Catalog.Stock_Size_Units', "where FK_Stock_Catalog__ID = Stock_Catalog_ID AND FK_Stock__ID=Stock_ID and Solution_ID=$id" );
            ( my $type ) = $dbc->Table_find( 'Solution', 'Solution_Type', "where Solution_ID=$id && Solution_Type != 'Reagent'" );
            $Sol{labels}[$index] = $name;
            $Sol{units}[$index]  = $size_units;
            push( @solnames, $name );
            if ( $name =~ /water|h2o/i ) {
            }    ## allow def_Type to be Other Solution type if this is water
            elsif ( $type =~ /Primer|Matrix|Buffer/ && $def_Type =~ /^($type|)$/ ) {
                $def_Type = $type;
            }    ## if undefined or same type of solution
            else {
                $def_Type = 'Solution';
            }    ## for all cases (except water + special_type only)
            $index++;
        }

    }

    $page .= $self->display_mixture_table( -dbc => $dbc, -solution => \%Sol, -type => $type, -ids => $ids, -samples => $samples, -include_well_totals=>$include_well_totals);

    return $page;
}

##########################
sub save_standard_mixture {
###########################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $catalog_flag = $q->param('AddingCatalog');
    my $catalog_name = $q->param('Stock_Catalog_Name');
    my $bottles      = $q->param('Bottles') || 1;
    my @quantity     = $q->param('Std_Quantities');
    my @units        = $q->param('Std_Quantities_Units');

    my @solutions     = $q->param('Solution Included');
    my $stock_catalog = $q->param('FK_Stock_Catalog__ID');    # either Stock_Catalog_Name or Stock_Catalog_ID

    my @solution_types  = $q->param('SolType');
    my @solution_format = $q->param('SFormat');
    my $SOL_info        = $q->param('Sol_Information');
    my $standard_flag   = $q->param('Standard');
    my $samples         = $q->param('Samples');

    ## Combine quantities with units
    my @quantities;
    my $i = 0;
    foreach my $q (@quantity) {
        my $qty = $quantity[$i] . " " . $units[$i];
        push @quantities, $qty;
        $i++;
    }

    ( my $stock_fields, my $stock_values ) = alDente::Form::get_form_input( -table => 'Stock', -object => $self, -dbc => $dbc );

    ( my $sol_fields, my $sol_values ) = alDente::Form::get_form_input( -table => 'Solution', -object => $self, -dbc => $dbc );

    # stop if no primers are found for Primer stocks
    if ($stock_catalog) {
        my $stock_catalog_name = '';
        if ( $stock_catalog =~ /^\d+$/ ) {
            ($stock_catalog_name) = $dbc->Table_find( 'Stock_Catalog', 'Stock_Catalog_Name', "Where Stock_Catalog_ID = '$stock_catalog'" );
        }
        else {
            $stock_catalog_name = $stock_catalog;
        }
        my ($stock_type) = $dbc->Table_find( 'Stock_Catalog', 'Stock_Type', "Where Stock_Catalog_Name = '$stock_catalog_name'" );
        if ( $stock_type =~ /Primer/ ) {
            ( my $found ) = $dbc->Table_find( 'Primer,Stock_Catalog', 'Primer_ID', "WHERE Stock_Catalog_Name = Primer_Name AND Stock_Catalog_Name = '$stock_catalog_name'" );
            unless ($found) {
                Message( "ERROR: There is no Primer record for Stock Catalog " . $stock_catalog_name . ".  Please ask your LAB Admin to add primers before continue" );
                return;
            }
        }
    }

    if ($scanner_mode) {
        my $passed_check = $dbc->check_mandatory_fields( -tables => [ 'Stock', 'Solution' ] );
        unless ($passed_check) {return}
    }

    my @stock_values = @$stock_values;

    if ($catalog_flag) {
        my $fields = [ 'Stock_Catalog_Name', 'Stock_Type', 'Stock_Source', 'Stock_Status', 'Stock_Size', 'Stock_Size_Units', 'FK_Organization__ID', 'FKVendor_Organization__ID' ];
        my $values = [ $catalog_name, 'Solution', 'Made in House', 'Active', '1', 'n/a', 27, 27 ];
        my $catalog_id = $dbc->Table_append_array( "Stock_Catalog", $fields, $values, -autoquote => 1 );
        my $catalog_index = _return_value(
            -fields       => $stock_fields,
            -values       => $stock_values,
            -target       => 'FK_Stock_Catalog__ID',
            -index_return => 1
        );
        $stock_values[$catalog_index] = $catalog_id;
    }

    ## alternative Quantity input option ##
    my $total_quantity;
    if ( !@quantities ) {
        foreach my $sol (@solutions) {
            my $qty = $q->param("Sol$sol Qty");
            push @quantities, $qty;
            $total_quantity += $qty;
        }
    }
    $total_quantity ||= $q->param('Solution_Quantity');

    my $ids = $self->Model->save_mixture_info(
        -dbc          => $dbc,
        -stock_fields => $stock_fields,
        -stock_values => \@stock_values,
        -sol_fields   => $sol_fields,
        -sol_values   => $sol_values,
        -bottles      => $bottles,
        -quantity     => \@quantities,
        -solutions    => \@solutions,
        -types        => \@solution_types,
        -format       => \@solution_format,
        -total        => $total_quantity
    );

    if ( $ids && $standard_flag ) {
        my $sol = Safe_Thaw( -name => 'Sol_Information', -thaw => 1, -encoded => 1 );
        $sol->{'Solution_ID'} = \@solutions;
        my @quanty = ();
        my @units  = ();

        foreach my $qty (@quantities) {
            my $unit = 'mL';
            if ( $qty =~ /([\.\d]*)\s*([a-zA-Z]+)/ ) {
                $qty  = $1;
                $unit = $2;
            }
            ( $qty, $unit ) = &Get_Best_Units( -amount => $qty, -units => $unit );
            push( @quanty, $qty );
            push( @units,  $unit );
        }
        $sol->{'quantities'}    = \@quanty;
        $sol->{'units'}         = \@units;
        $sol->{'new solutions'} = $ids;
        require alDente::Chemistry;
        &alDente::Chemistry::print_chemistry_sheet( -sol => $sol, -dbc => $dbc, -samples => $samples );

        if ($scanner_mode) {
            return vspace() . alDente::Solution_Views::display_scanner_mode( -dbc => $dbc );
        }
        else {
            return vspace(6) . alDente::Solution_Views::display_mix_block( -dbc => $dbc );
        }

    }

    return;
}

##########################
sub save_batch_dilute {
##########################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');
    ## Volume Table Info
    my $diluted_solutions = $q->param("Diluted Solutions");
    my $water_solution    = $q->param("Water Solution");
    my $solution_volume   = $q->param("Solution Volume");
    my $water_volume      = $q->param("Water Volume");
    my @sol_ids           = split( ',', $diluted_solutions );
    my @water_id          = split( ',', $water_solution );

    ## Extra Parameter Table Info
    my $expiry     = $q->param('Solution_Expiry');
    my $rack       = $q->param("FK_Rack__ID") || $q->param("FK_Rack__ID Choice");
    my $type       = $q->param("Solution_Type");
    my $group      = $q->param("FK_Grp__ID") || $q->param("FK_Grp__ID Choice");
    my $barcode_id = $q->param("FK_Barcode_Label__ID");
    my $catalog_id = $q->param("FK_Stock_Catalog__ID");

    $rack = $dbc->get_FK_ID( "Rack_ID", $rack );
    unless ($rack) {
        ($rack) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Name = 'Temporary'" );
    }
    $group      = $dbc->get_FK_ID( "Grp_ID",           $group );
    $barcode_id = $dbc->get_FK_ID( "Barcode_Label_ID", $barcode_id );

    &alDente::Solution::batch_dilute(
        -dbc             => $dbc,
        -expiry          => $expiry,
        -sol_ids         => \@sol_ids,
        -water_id        => \@water_id,
        -rack_id         => $rack,
        -type            => $type,
        -group_id        => $group,
        -label_id        => $barcode_id,
        -catalog_id      => $catalog_id,
        -solution_volume => $solution_volume,
        -solution_unit   => 'uL',
        -water_volume    => $water_volume,
        -water_unit      => 'mL'
    );
}

##########################
sub new_primer_table {
##########################
    #
    #
    #
##########################
    my $self  = shift;
    my $dbc   = $self->param('dbc');
    my $table = SDB::DB_Form->new(
        -dbc    => $dbc,
        -table  => 'Primer',
        -target => 'Database'
    );
    return $table->generate( -navigator_on => 1, -return_html => 1 );
}

##########################
sub new_primer_stock {
##########################
    #
    #
##########################
    my $self        = shift;
    my $q           = $self->query;
    my $dbc         = $self->param('dbc');
    my $primer_name = $q->param('Standard Primer Name');
    my @catalog_ids = $dbc->Table_find(
        -table     => 'Stock_Catalog',
        -fields    => "Stock_Catalog_ID",
        -condition => "WHERE Stock_Catalog_Name = '$primer_name'"
    );

    my $stock_app_object = alDente::Stock_App->new( -dbc => $dbc );
    return $stock_app_object->display_search_results(
        -dbc         => $dbc,
        -catalog_ids => \@catalog_ids
    );
}

##########################
sub new_vector {
##########################
    #
    #
    #
    #
##########################
    my $self  = shift;
    my $dbc   = $self->param('dbc');
    my $table = SDB::DB_Form->new(
        -dbc    => $dbc,
        -table  => 'Vector_TypePrimer',
        -target => 'Database'
    );
    return $table->generate( -navigator_on => 1, -return_html => 1 );
}

#########################
sub display_chem_calculator {
##########################
    #
    #
    #
##########################
    my $self  = shift;
    my $dbc   = $self->param('dbc');
    my $q     = $self->query;
    my $wells = $q->param('Wells');
    my $chem  = $q->param('Chemistry');
    $chem =~ s/\+/ /g;

    my $Formula = alDente::Chemistry->new( -dbc => $dbc, -name => $chem );
    if ($chem) {
        $Formula->show_Formula();
    }
    else {
        $Formula->list_Formulas();
    }
    return 1;

}
##########################
sub export_Solution {
##########################
    #
    #
    #
##########################
    my $self        = shift;
    my $dbc         = $self->param('dbc');
    my $q           = $self->query;
    my $solution    = $q->param('Solution_ID');
    my $destination = $q->param('Destination');
    my $comments    = $q->param('Export_Comments');

    my $ids = alDente::Validation::get_aldente_id( $dbc, $solution, 'Solution' );
    if ($ids) {
        $self->param('Model')->export_Solutions( -ids => $ids, -destination => $destination, -comments => $comments );
    }
    else {
        Message "No solutions to export.";
    }
    return $self->entry_page();

}

##########################
sub empty_solution {
##########################
    #
    #
    #
##########################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $solution_id = $q->param('Solution_ID');
    my $empty_date  = &date_time();

    my @solution = $solution_id;
    my $solution = Cast_List( -list => \@solution, -to => 'String' );
    $solution = alDente::Validation::get_aldente_id( $dbc, $solution, 'Solution' );
    $solution ||= 0;
    $self->param('Model')->empty(
        -id      => $solution,
        -dbc     => $dbc,
        -nowdate => $empty_date
    );
    return $self->entry_page( -id => $solution );
}

##########################
sub print_barcode {
##########################
    #
    #
    #
    #
##########################
    my $self        = shift;
    my $q           = $self->query();
    my $dbc         = $self->param('dbc');
    my $event       = $q->param('Barcode_Event');
    my $barcode     = $q->param('Barcode Name');
    my $solution_id = $q->param('Solution_ID');
    my $repeat      = $q->param('Repeat') || 1;
    my $type        = $q->param('FK_Barcode_Label__ID');

    require alDente::Barcoding;

    if ( $solution_id =~ /(\d+)-(\d+)/ ) {
        my @solutions = $dbc->Table_find( 'Solution', 'Solution_ID', "WHERE Solution_ID BETWEEN $1 AND $2", -distinct => 1 );
        $solution_id = join ',', @solutions;
    }

    my ($type_id) = $dbc->get_FK_ID( 'FK_Barcode_Label__ID', $type );
    my ($bl_name) = $dbc->Table_find( 'Barcode_Label', 'Barcode_Label_Name', "WHERE Barcode_Label_ID IN ($type_id)" );
    alDente::Barcoding::PrintBarcode( -dbc => $dbc, -table => 'Solution', -id => $solution_id, -count => $repeat, -barcode_label => $bl_name );

    return $self->entry_page( -id => $solution_id );
}

##########################
sub activate_Solutions {
##########################
    my $self        = shift;
    my $q           = $self->query();
    my $dbc         = $self->param('dbc');
    my $solution_id = $q->param('Solution_ID');
    my $expiry_date = $q->param('Active_Expiry_Date');

    my @solution = $solution_id;
    my $solution = Cast_List( -list => \@solution, -to => 'String' );
    $solution = alDente::Validation::get_aldente_id( $dbc, $solution, 'Solution' );
    $solution ||= 0;

    unless ($solution) {
        return $self->entry_page( -id => $solution );
    }

    my $page = alDente::Solution::activate_Solution( -ids => $solution, -confirm => 1, -dbc => $dbc );

    if ($expiry_date) {
        $self->param('Model')->set_expiry(
            -id          => $solution,
            -dbc         => $dbc,
            -expiry_date => $expiry_date
        );
    }
    $page .= $self->entry_page( -id => $solution );

    return $page;
}

##########################
sub set_expiry_date {
##########################
    my $self        = shift;
    my $q           = $self->query();
    my $dbc         = $self->param('dbc');
    my $solution_id = $q->param('Solution_ID');
    my $expiry_date = $q->param('Expiry_Date');

    my @solution = $solution_id;
    my $solution = Cast_List( -list => \@solution, -to => 'String' );
    $solution = alDente::Validation::get_aldente_id( $dbc, $solution, 'Solution' );
    $solution ||= 0;
    $self->param('Model')->set_expiry(
        -id          => $solution,
        -dbc         => $dbc,
        -expiry_date => $expiry_date
    );

    return $self->entry_page( -id => $solution );

}

##########################
sub dilute_batch {
##########################
    my $self     = shift;
    my $dbc      = $self->param('dbc');
    my $q        = $self->query();
    my $sol_ids  = $q->param('Diluted Solutions');
    my $water_id = $q->param('Water Solution');

    # make sure all IDs are valid
    my $sol_ids = Cast_List(
        -list => alDente::Validation::get_aldente_id( $dbc, $sol_ids, 'Solution' ),
        -to   => 'string'
    );
    my $water_id = Cast_List(
        -list => alDente::Validation::get_aldente_id( $dbc, $water_id, 'Solution' ),
        -to   => 'string'
    );

    ## ERROR CHECK ##
    my $escape;
    unless ( $sol_ids or $water_id ) {
        Message("Error: Invalid Solution or Water scanned");
        $escape = 1;
    }

    # make sure sol ids have the same name
    my @sol_name = $dbc->Table_find( 'Stock,Solution,Stock_Catalog', 'Stock_Catalog_Name', "WHERE FK_Stock_Catalog__ID = Stock_Catalog_ID AND  Stock_ID=FK_Stock__ID AND Solution_ID IN ($sol_ids)", -distinct => 1 ) if $sol_ids;
    unless ( scalar(@sol_name) == 1 ) {
        Message("Error: Solutions must have the same name");
        Message( "Solution Names provided: " . join ',', @sol_name );
        $escape = 1;
    }

    # error check - make sure water ID is water
    my @water_name = $dbc->Table_find( 'Stock,Solution,Stock_Catalog', 'Stock_Catalog_Name', "WHERE FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_ID=FK_Stock__ID AND Solution_ID IN ($water_id)" ) if $water_id;
    if ( scalar(@water_name) != 1 ) {
        Message("Error: Only one water solution must be scanned");
        $escape = 1;
    }
    elsif ( ( $water_name[0] !~ /water/i ) && ( $water_name[0] !~ /h2o/i ) ) {
        Message("Error: $water_name[0] is not 'Water' or 'H2O'");
        $escape = 1;
    }
    if ($escape) {
        return $self->home_page();
    }

    my $catalog_ids = $self->Model->get_made_solution_catalog_ids( -dbc => $dbc, -used_solution => $sol_ids );

    my $page = $self->display_standard_solution_page(-dbc=>$dbc, -ids=>"$sol_ids, $water_id", -name=>"$sol_name[0] Dilution");

    return $page;
}

##########################
sub new_catalog_item {
##########################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;
    ## Volume Table Info
    my $diluted_solutions = $q->param("Diluted Solutions");
    my $water_solution    = $q->param("Water Solution");
    my $solution_volume   = $q->param("Solution Volume");
    my $water_volume      = $q->param("Water Volume");
    my @sol_ids           = split( ',', $diluted_solutions );
    my @water_id          = split( ',', $water_solution );

    ## Extra Parameter Table Info
    my $expiry       = $q->param('Solution_Expiry');
    my $rack         = $q->param("FK_Rack__ID") || $q->param("FK_Rack__ID Choice");
    my $type         = $q->param("Solution_Type");
    my $group        = $q->param("FK_Grp__ID") || $q->param("FK_Grp__ID Choice");
    my $barcode_id   = $q->param("FK_Barcode_Label__ID");
    my $catalog_name = $q->param("New Catalog Item");

    $rack = $dbc->get_FK_ID( "Rack_ID", $rack );
    unless ($rack) {
        ($rack) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Name = 'Temporary'" );
    }
    $group      = $dbc->get_FK_ID( "Grp_ID",           $group );
    $barcode_id = $dbc->get_FK_ID( "Barcode_Label_ID", $barcode_id );

    my @fields = qw (Stock_Catalog_Name Stock_Type  Stock_Source    Stock_Size  Stock_Size_Units    FK_Organization__ID );
    my @values = ( $catalog_name, '$type', 'Made in House', 'undef', 'n/a', 27, );

    my $catalog_id = $dbc->Table_append_array( 'Stock_Catalog', \@fields, \@values, -autoquote => 1 );
    Message("Added item to catalog (ID = $catalog_id )") if $catalog_id;

    &alDente::Solution::batch_dilute(
        -dbc             => $dbc,
        -expiry          => $expiry,
        -sol_ids         => \@sol_ids,
        -water_id        => \@water_id,
        -rack_id         => $rack,
        -type            => $type,
        -group_id        => $group,
        -label_id        => $barcode_id,
        -catalog_id      => $catalog_id,
        -solution_volume => $solution_volume,
        -solution_unit   => 'uL',
        -water_volume    => $water_volume,
        -water_unit      => 'mL'
    );
}
######################################################
##          View                                    ##
######################################################
###########################
sub display_dilute_tables {
###########################
    #
    #
###########################
    my $self        = shift;
    my $q           = $self->query;
    my %args        = @_;
    my $dbc         = $args{-dbc} || $self->param('dbc');
    my $sol_name    = $args{-sol_name};
    my $water_name  = $args{-water_name};
    my $catalog_ids = $args{-ids_list};

    my $volume_table = alDente::Form::init_HTML_table( -title => "Volumes", -width => '33%' );
    $volume_table->Set_Row( [ "$sol_name :",  $q->textfield( -name => "Solution Volume" ) . "&emsp;uL" ] );
    $volume_table->Set_Row( [ "$water_name:", $q->textfield( -name => "Water Volume" ) . "&emsp;uL" ] );

    my $block = $volume_table->Printout(0) 
        . vspace()
        . alDente::Solution_Views->display_extra_parameter_table(
        -dbc      => $dbc,
        -button   => 'Save Batch Info',
        -ids_list => $catalog_ids
        );
    return $block;
}

#
# New
#
#
############################
sub display_mixture_table {
############################
    my $self    = shift;
    my $q       = $self->query;
    my %args    = @_;
    my $dbc     = $args{-dbc} || $self->param('dbc');
    my $Sol_ref = $args{-solution};
    my %Sol     = %$Sol_ref;
    my $type    = $args{-type};
    my $samples = $args{-samples};
    my $ids     = $args{-ids};                          ### ids of solutions to mix together...
    my $include_well_totals = $args{-include_well_totals};

    my @id;

#    return $self->param('View')->display_Mixture_Table( -solution => $Sol_ref, -type => $type, -samples => $samples, -ids => $ids, -Model => $self->param('Model') );
#
# =cut
    my $total_quantity = 0.0;
    if ( $Sol{message} ) { $dbc->message( $Sol{message} ) }
    if ($ids) { @id = split ',', $ids; }                ### if solutions are pre-scanned...

    my $recalculate = recalculate($samples);

    # "TrackTotal(document.Mixture,'Std_Quantities','Total Quantity','g'); MultiplyBy(document.Mixture,'Total Quantity','Maximum Available Per Well',1000/96,100);";

    my @sol_types;
    my @sol_labels;
    my @sol_formats;
    my ( @target_fields, @target_labels );
    my %onchange;

    my $name = $Sol{name};
    my $validation;
    
    my $Form = new LampLite::Form( -dbc => $dbc, -name => 'Mixture', -style => 'background-color:#ccc', -span => [ 3, 9 ], -type => 'horizontal', -framework => 'table', -title => "<center>Preparing $name</center>" );
    foreach my $sol_num ( 1 .. $Sol{solutions} ) {
        my $def_id  = 'Sol' . $id[ $sol_num - 1 ] if $id[ $sol_num - 1 ];
        my $label   = $Sol{labels}[ $sol_num - 1 ];
        my $format  = $Sol{format}[ $sol_num - 1 ] || '.';
        my $SolType = $Sol{SolType}[ $sol_num - 1 ] || '.';
        my $qty     = $Sol{quantities}[ $sol_num - 1 ];
        my $units   = $Sol{units}[ $sol_num - 1 ];

        #        $units =~s/L$/l/;   ## in case units are incorrectly supplied as 'L' for litres ...
        ( $qty, $units ) = simplify_units( $qty, $units );
        $units =~ s/L$/l/;    ## in case units are incorrectly supplied as 'L' for litres ...

        push @sol_types,   $SolType;
        push @sol_labels,  $label;
        push @sol_formats, $format;

        #        if ( $Sol{prompt_units} =~ /l$/ ) {
        #            ( $qty, $units ) = RGTools::Conversion::convert_volume( $qty, $units, $Sol{prompt_units} );
        #        }
        #        elsif ( $Sol{prompt_units} ) { Message("Could not force units to $Sol{prompt_units}") }

        my ( $liquid_volume, $liquid_units ) = convert_to_mils( $qty, $units );
        unless ( $units =~ /g/i ) { $total_quantity += $liquid_volume; }

        $onchange{"Sample_Quantity"}       = recalculate($samples);
        $onchange{"Sample_Quantity_Units"} = recalculate($samples);

        my $placeholder = $label;
        if ( length($label) > 15 ) { $placeholder = 'Scan Reagent' }

        my $reagent = $Form->View->prompt( -name => 'FKUsed_Solution__ID', -id=>"Sol-$sol_num", -type => 'barcode', -default=>$def_id, -force=>1, -label => $label, -class => '', -placeholder=>"-- $placeholder --") || $label;
        my $r_qty = $Form->View->prompt( -name => 'Sample_Quantity', -id=>"Qty-$sol_num", -label => 'Qty', -class => '', -default=>$qty, -force=>1, -onchange => recalculate($samples) );
        my $r_qty_units = $Form->View->prompt( -name => 'Sample_Quantity_Units', -id=>"QU-$sol_num", -class=>'', -type => 'enum', -default => $units, -force=>1, -list => [ 'l', 'ml','ul', 'nl', 'pl'], -onchange => recalculate($samples) );
      
        my $prompt = $BS->row([$reagent, $r_qty, $r_qty_units], -span=>[6,4,2], -size=>'xs');
                    
        foreach my $att ('Sol', 'Qty', 'QU') {
            $validation .= set_validator( -id=>"$att-$sol_num", -mandatory=>1 );
        }
        $Form->append( -label => $label, -input => $prompt );
    }

    my ( $total, $total_units ) = simplify_units( $total_quantity, 'ml' );
     my ($well_default, $well_default_units) = simplify_units($total_quantity / $samples, 'ml');

    $Form->append( -label => 'Total',        -input => $BS->text_element( -name => 'Solution_Quantity',  -value=>"$total $total_units", -force=>1, -class => 'standard' ), -class => 'attn-highlight' );
    if ($include_well_totals) { 
        $Form->append( -label => 'total / well', -input => $BS->text_element( -name => 'Maximum Available Per Well', -value=>"$well_default $well_default_units", -force=>1, -class => 'standard' ), -class => 'attn-highlight' );
    }
    
    $Form->append( -label => '<center><B>Additional Info</B></center>', -class => 'subsection-heading', -fullwidth => 1 );

    my $block;
    $block .= Safe_Freeze(
        -name   => "Sol_Information",
        -value  => \%Sol,
        -format => 'hidden',
        -encode => 1
    );

    $block .= $q->hidden( -name => 'SFormat', -value => \@sol_formats, -force => 1 ) . $q->hidden( -name => 'SolType', -value => \@sol_types, -force => 1 );

    my $possible_new_solution = $self->Model->get_possible_target_solution( -dbc => $dbc, -ids => $ids ) if $ids;

    ( my $stock_catalog_id ) = $dbc->Table_find( 'Stock_Catalog', 'Stock_Catalog_ID', "WHERE Stock_Catalog_Name = '$type'" );

    my ( $mixture, $add_to_catalog );
    if ($stock_catalog_id) {
        $block .= $q->hidden( -name => 'Standard', -value => 'Standard', -force => 1 );
    }
    elsif ($ids) {
        $mixture = 1;
    }
    else {
        $block .= $q->hidden( -name => 'Standard', -value => 'Standard', -force => 1 );
        $add_to_catalog = 1;
    }

    my $element_id = 'MixtureForm';

    my $add_rows = $self->extra_mixture_parameters(
        -dbc            => $dbc,
        -type           => $type,
        -button         => 'Save Standard Mixture',
        -mixture        => $mixture,
        -ids            => $ids,
        -element_id     => $element_id,
        -possible_made  => $possible_new_solution,
        -add_to_catalog => $add_to_catalog,
        -target_fields  => \@target_fields,
        -target_labels  => \@target_labels,
        -onchange       => \%onchange,
    );

    $validation .= set_validator( -name => "FK_Grp__ID",           -mandatory => 1 );
    $validation .= set_validator( -name => "FK_Barcode_Label__ID", -mandatory => 1 );
    $validation .= set_validator( -name => "FK_Stock_Catalog__ID", -mandatory => 1 );
    $validation .= set_validator( -name => "Bottles",              -mandatory => 1 );
    $validation .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Solution_App', -force => 1 );

    foreach my $row (@$add_rows) {
        $Form->append( -raw => $row );
    }
    if ($add_to_catalog) { $Form->append( -label => '', -input => alDente::Solution_Views::new_catalog_link( -flag => 'in_house', -dbc => $dbc ) ) }    ## , -span=>[4,6]) }

    $Form->append( -label => '', -input => 'Divide into ' . $Form->View->prompt( -name => 'Bottles', -default => 1, -class => 'short-txt', -label => '#' ) . " Containers\n");
    $Form->append( -input => $q->submit( -name => 'rm', -value => 'Save Standard Mixtures', -force => 1, -class => 'Action btn', -onclick => "validateForm(this.form); return false;" ) );
    return $Form->generate( -wrap => 1, -include=>$validation);
# =cut

}

####################################
sub extra_mixture_parameters {
####################################
    #
    #
###########################
    my $self                  = shift;
    my %args                  = @_;
    my $dbc                   = $args{-dbc} || $self->param('dbc');
    my $element_id            = $args{-element_id};
    my $type                  = $args{-type};                         ## Catalog Name
    my $sol_ids               = $args{-ids};
    my $q                     = $self->query;
    my $mixture_flag          = $args{-mixture};                      ## used to flag this is not a standard mixture
    my $catalog_list          = $args{-ids_list};
    my $possible_new_solution = $args{-possible_made};
    my $add_cat_flag          = $args{-add_to_catalog};
    my $target_fields         = $args{-target_fields} || [];
    my $target_labels         = $args{-target_labels} || [];
    my $onchange              = $args{-onchange} || {};

    if ($add_cat_flag) {
        Message('adding to catalog');
    }
    my $previous_label;
    my $previous_grp;
    my $user_id = $dbc->config('user_id');

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

    my @target_fields = @$target_fields;
    my @target_labels = @$target_labels;

    my %preset;
    my %default;
    my %list;
    my %grey;

    $default{Sample_Quantity_Units} = 'ml';
    $grey{FK_Employee__ID}          = $dbc->get_FK_info( 'FK_Employee__ID', $user_id );
    $grey{FK_Stock_Catalog__ID}     = $stock_catalog_id if $type;
    $list{FK_Barcode_Label__ID}     = \@labels;

    if ($mixture_flag) {
        require alDente::Organization;
        my $internal_org_id = alDente::Organization::local_organization_id($dbc);

        my @solution_names = $dbc->get_FK_info_list( 'FK_Stock_Catalog__ID', "  Stock_Source = 'Made in House' AND FK_Organization__ID = $internal_org_id " );
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
        push @target_fields, qw(Solution.Solution_Type Solution.Solution_Expiry Stock.FK_Grp__ID Stock.FK_Barcode_Label__ID  Stock_Catalog.Stock_Catalog_Name );
    }
    else {
        push @target_fields, qw(Solution.Solution_Expiry Stock.FK_Grp__ID Stock.FK_Barcode_Label__ID  Stock.FK_Stock_Catalog__ID );
    }

    my $table = SDB::DB_Form->new(
        -dbc       => $dbc,
        -fields    => \@target_fields,
        -labels    => \@target_labels,
        -target    => 'Database',
        -wrap      => 0,
        -span      => [ 4, 8 ],
        -framework => 'table'
    );

    ## new ... ##
    $table->configure_form_element( -field => 'FK_Barcode_Label__ID', -condition => "Barcode_Label_Type = 'Solution'" );
    $table->configure( -grey => \%grey, -preset => \%preset, -default => \%default, -onchange => $onchange );

    my $append = $q->hidden( -name => 'AddingCatalog', -value => '1', -force => 1 ) if $add_cat_flag;
    Message $table->View;
    return $table->View->field_input( -id => $element_id, -append => [$append] );
}

##################
sub recalculate {
##################
    my $samples = shift;

    my $form_name = 'Mixture';
    my $qty_used  = 'Sample_Quantity';
    my $qty_total = 'Solution_Quantity';
    my $ignore    = 'g';
    my $multiply  = 'Maximum Available Per Well';

    my $recalculate = "TrackTotal(document.Mixture, '$qty_used', '$qty_total', '$ignore');";

    if ($samples) {
        my $factor   = 1 / $samples;
        my $decimals = 2;              ## two significant digits ##
        $recalculate .= "MultiplyBy(document.$form_name,'$qty_total','$multiply',$factor,$decimals);";
    }

    #   my $fullcalculate  = "BrewCalc(document.$form_name);" . $recalculate;

    return $recalculate;
}

###########################
sub display_batch_block {
###########################
    #
    #
###########################
    my $self         = shift;
    my %args         = @_;
    my $dbc          = $args{-dbc} || $self->param('dbc');
    my $q            = $self->query;
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

    my $block
        .= "Scan reagent(s)/solution(s) -> "
        . $q->textfield( -name => 'Solution_ID', -size => 20 )
        . vspace()
        . $q->submit( -name => 'rm', -value => 'Empty Solution(s)', -class => "Action" )
        . hspace(10)
        . $q->submit( -name => 'rm', -value => 'Re-Print Solution Labels', -class => "Action" )
        . $reprint_prompt;

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
sub display_primer_block {
###########################
    #
    #
###########################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query;

    my @std_primers = $dbc->Table_find( "Primer", "Primer_Name", "WHERE Primer_Type = 'Standard' ORDER BY Primer_Name" );
    unshift( @std_primers, '- Select Primer -' );
    my $header = "\n<img src='/$URL_dir_name/$image_dir/chem.png'>";

    my $block = "<FONT color=red>To receive new reagents/kits, go to 'Receiving' home page</FONT>" 
        . &vspace()
        . $q->hidden(
        -name  => 'cgi_application',
        -value => 'alDente::Solution_App',
        -force => 1
        )
        . $q->submit( -name => 'rm', -value => "Define New Primer", -class => "Std" )
        . &vspace()
        . $q->submit( -name => 'rm', -value => 'New Primer Stock', -class => "Std" )
        . &hspace(2)
        . $q->popup_menu(
        -name    => 'Standard Primer Name',
        -values  => \@std_primers,
        -default => '- Select Primer -',
        -force   => 1
        )
        . HTML_Comment('(receive stock)')
        . &vspace()
        . $q->submit( -name => 'rm', -value => "Set Valid Primer for Vector", -class => "Std" );
    my $table = alDente::Form::init_HTML_table( "Primer Options", -margin => 'on' );
    $table->Set_Row( [ $header, $block ] );

    my $page = alDente::Form::start_alDente_form( $dbc, 'Primer Options' ) . $table->Printout(0) . $q->end_form();
    return $page;
}

###########################
sub display_search_block {
###########################
    #
    #
###########################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query;

    return alDente::Solution_Views::display_Search_Box( -dbc => $dbc );
}

###########################
sub display_chemistry_block {
###########################
    #
    #
###########################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query;

    my @StandardSolutionList = @{
        $dbc->Security->get_accessible_items(
            -table           => 'Standard_Solution',
            -extra_condition => "Standard_Solution_Status = 'Active'"
        )
        };
    my $header = "\n<img src='/$URL_dir_name/$image_dir/test_tubes.png'>";

    my $block = $q->submit(
        -name  => 'rm',
        -value => 'Check Chemistry Calculator',
        -class => "Search"
        )
        . ' for: '
        . $q->popup_menu(
        -name    => 'Chemistry',
        -values  => [ '', @StandardSolutionList ],
        -default => ''
        )
        . "<BR> Test for "
        . $q->textfield( -name => 'Wells', -size => 4, -default => '' )
        . ' wells '
        . HTML_Comment('(leave blank to edit Formula/Parameters)')
        . $q->hidden( -name => 'Table', -value => 'Solution', -force => 1 );

    my $table = alDente::Form::init_HTML_table( "Chemistry Calculator", -margin => 'on' );
    $table->Set_Row( [ $header, $block ] );

    my $page = alDente::Form::start_alDente_form( $dbc, 'Chemistry Calculator' ) 
        . $table->Printout(0)
        . $q->hidden(
        -name  => 'cgi_application',
        -value => 'alDente::Solution_App',
        -force => 1
        ) . $q->end_form();
    return $page;

}

######################################################
##          Private                                 ##
######################################################
##########################
sub _return_value {
##########################
    my %args         = &filter_input( \@_ );
    my $fields_ref   = $args{-fields};
    my $values_ref   = $args{ -values };
    my $target       = $args{-target};
    my $index_return = $args{-index_return};

    my $value;
    my @fields  = @$fields_ref;
    my @values  = @$values_ref;
    my $counter = 0;

    foreach my $field_name (@fields) {
        if ( $field_name eq $target ) {
            if ($index_return) {
                return $counter;
            }
            else {
                return $values[$counter];
            }
        }
        $counter++;
    }
    return;
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

1;
