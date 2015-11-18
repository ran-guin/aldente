###################################################################################################################################
# alDente::Equipment_App.pm
#
#
#
#   By Ash Shafiei, October 2008
###################################################################################################################################
package alDente::Equipment_App;

use base alDente::CGI_App;
use strict;

## SDB modules
use SDB::CustomSettings;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;

## alDente modules
use alDente::Form;
use alDente::Stock_App;
use alDente::Stock;
use alDente::SDB_Defaults;
use alDente::Equipment_Views;

use vars qw( $Connection %Configs  $Security);

###########################
sub setup {
###########################

    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'default'                 => 'entry_page',
        'Home'                    => 'main_page',
        'List'                    => 'list_page',
        'New Equipment'           => 'new_equipment',
        'Find Equipment'          => 'display_search_results',
        'List Equipment'          => 'list_equipment',
        'Re-Categorize Equipment' => 'activate_equipment',
        'Activate Equipment'      => 'activate_equipment',
        'Assign Category'         => 'assign_category',
        'Define Demo'             => 'define_demo',
        'Inventory'               => 'inventory_home',
    );
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');
    my $q   = $self->query;

    my $id = $q->param('ID') || $q->param('Equipment_ID');
    my $Equipment = new alDente::Equipment( -dbc => $dbc, -id => $id );
    $self->param( 'Model' => $Equipment );

    return 0;

}
######################################################
##          Controller                              ##
######################################################

#####################
sub inventory_home {
###########################
    my $self          = shift;
    my %args          = filter_input( \@_ );
    my $q   = $self->query;
    my $dbc = $self->dbc;
    
    $dbc->debug_message('Update Inventory');
    
    return "Under construction";
}

###########################
sub assign_category {
###########################
    my $self          = shift;
    my %args          = filter_input( \@_ );
    my $q             = $self->query;
    my $equipment_id  = $q->param('equipment_id');
    my $dbc           = $self->param('dbc');
    my $equipment     = $self->param('Model');
    my $catalog_id    = $q->param('catalog_id');
    my $category_name = $q->param('FK_Equipment_Category__ID Choice') || $q->param('FK_Equipment_Category__ID');

    $equipment->assign_category(
        -dbc          => $dbc,
        -equipment_id => $equipment_id,
        -category     => $category_name,
        -catalog_id   => $catalog_id
    );

    return $equipment->home_info( -id => $equipment_id );
}

###########################
sub activate_equipment {
###########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $q    = $self->query;
    my $ids  = $q->param('ids');
    my $dbc  = $self->param('dbc');
    return alDente::Equipment_Views::display_Equipment_Activation_Page( -dbc => $dbc, -ids => $ids );
}

###########################
sub list_page {
###########################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $list = $q->param('list') || $args{-list};
    my $view = $dbc->Table_retrieve_display(
        -table       => "Equipment",
        -fields      => [ 'Equipment_ID', 'Equipment_Name', 'FK_Location__ID', 'FK_Stock__ID', 'Serial_Number' ],
        -condition   => "WHERE Equipment_ID IN ($list)",
        -return_html => 1,
    );
    return $view;
}

###########################
sub entry_page {
###########################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $id   = $q->param('ID');

    unless ($id) { return $self->main_page( -dbc => $dbc ) }
    if ( $id =~ /,/ ) { return $self->list_page( -dbc => $dbc, -list => $id ) }
    else              { return $self->home_page( -dbc => $dbc, -id => $id ) }
    return 'Error: Inform LIMS';
}

###########################
sub home_page {
###########################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $id   = $q->param('id') || $args{-id};
    my $view = $self->display_equipment_homepage( -dbc => $dbc, -id => $id );
    return $view;
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
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $page = &Views::Heading("Equipment Main Page");
    $page .= $self->display_new_equipment_block( -dbc => $dbc );
    $page .= $self->display_search_block( -dbc => $dbc );
    $page .= $self->display_maintenance_block( -dbc => $dbc );

    my $labels;
    $labels .= $self->display_large_Label_block( -dbc => $dbc );
    $labels .= $self->display_small_label_block( -dbc => $dbc );
    $labels .= $self->display_tube_label_block( -dbc => $dbc );

    $page .= create_tree( -tree => { 'Labels' => $labels }, -print => 0 );

    return $page;
}

###########################
sub list_equipment {
###########################
    my $self     = shift;
    my $q        = $self->query;
    my $dbc      = $self->param('dbc');
    my $type     = $q->param('Equip Type');
    my $vendor   = $q->param('Equip Vendor');
    my $manufac  = $q->param('Equip Manufacturer');
    my $group    = $q->param('Equip Grp');
    my $location = $q->param('Equip Location');

    my $category_id = $dbc->get_FK_ID( -field => 'FK_Equipment_Category__ID', -value => $type );
    my $vandor_id   = $dbc->get_FK_ID( -field => 'FK_Organization__ID',       -value => $vendor );
    my $manufac_id  = $dbc->get_FK_ID( -field => 'FK_Organization__ID',       -value => $manufac );
    my $group_id    = $dbc->get_FK_ID( -field => 'FK_Grp__ID',                -value => $group );
    my $location_id = $dbc->get_FK_ID( -field => 'FK_Location__ID',           -value => $location );

    my $condition = "WHERE Equipment_Status = 'In Use' AND Stock_ID = FK_Stock__ID and FK_Stock_Catalog__ID = Stock_Catalog_ID ";
    if ($category_id) { $condition .= " AND FK_Equipment_Category__ID = $category_id " }
    if ($vandor_id)   { $condition .= " AND FK_Organization__ID = $vandor_id " }
    if ($manufac_id)  { $condition .= " AND FK_Organization__ID = $manufac_id " }
    if ($group_id)    { $condition .= " AND FK_Grp__ID = $group_id " }
    if ($location_id) { $condition .= " AND FK_Location__ID = $location_id " }

    my @equipment_ids = $dbc->Table_find( 'Stock_Catalog,Stock,Equipment', 'Equipment_ID', $condition );
    my $equipment_list = join ',', @equipment_ids;
    unless ($equipment_list) {
        Message('No items found');
        return $self->home_page( -dbc => $dbc );
    }

    my $display_condition = "WHERE FK_Location__ID=Location_ID AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID and Equipment_ID IN ($equipment_list) ";
    my $Table             = $dbc->Table_retrieve_display(
        'Equipment,Location,Stock,Stock_Catalog',
        [   qw( Equipment_ID     Equipment_Name
                Stock_Catalog.Model   Serial_Number
                Stock_Received Location_Name
                Equipment_Status )
        ],
        $display_condition,
        -toggle_on_column => 3,
        -return_table     => 1
    );
    return $Table->Printout( "$URL_temp_dir/Equipment_List.html", &date_time() ) . $Table->Printout(0);
}

###########################
sub new_equipment {
###########################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my @fields = qw(Stock_Catalog.FK_Equipment_Category__ID Stock_Catalog.Stock_Source Stock_Catalog.FK_Organization__ID);
    my $table = &SDB::HTML::query_form( -dbc => $dbc, -fields => \@fields, -action => 'search' );

    my $page = &Views::Heading("Searching for Equipment") . alDente::Form::start_alDente_form( $dbc, 'Catalog_Lookup' );

    if ( $dbc->Security->department_access() =~ /Admin/i ) {
        $page .= &Link_To( $dbc->config('homelink'), "Add New Equipment to Catalog", "&cgi_application=alDente::Stock_App&rm=Catalog+Form&Stock_Type=Equipment&dbc=$dbc" );
    }

    $page .= $table . $q->hidden( -name => 'cgi_application', -value => 'alDente::Equipment_App', -force => 1 ) . $q->submit( -name => 'rm', -value => 'Find Equipment', -force => 1, -class => 'Search' ) . $q->end_form();

    return $page;
}

###########################
sub display_search_results {
###########################
    my $self           = shift;
    my $q              = $self->query;
    my $dbc            = $self->param('dbc');
    my @organization   = $q->param('FK_Organization__ID Choice');
    my @stock_sources  = $q->param('Stock_Source');
    my @category_names = $q->param("FK_Equipment_Category__ID Choice");
    my @stock_types    = ('Equipment');
    my $page;
    my $organization = join "','", @organization;

    my $cat_ids = $self->param('Model')->get_equipment_type_ids( -dbc => $dbc, -names => \@category_names );
    my $catalog_ids_ref = alDente::Stock::get_catalog_ids(
         $self,
        -dbc         => $dbc,
        -types       => \@stock_types,
        -sources     => \@stock_sources,
        -Category_ID => $cat_ids,
        -org         => $organization
    );

    my @catalog_ids = @$catalog_ids_ref;
    if (@catalog_ids) {
        $page = &alDente::Stock_Views::display_list_page( -dbc => $dbc, -list => $catalog_ids_ref );
    }
    else {
        Message('No matches in catalog');
        $page = new_equipment( $self, -dbc => $dbc );
    }

    return $page;

}

#####################
sub define_demo {
#####################
    my $self         = shift;
    my $equipment_id = $q->param('Equipment_ID');

    $self->param('Model')->define_demo_category( -equipment_id => $equipment_id );
    return;
}

######################################################
##          View                                    ##
######################################################
###########################
sub display_equipment_homepage {
###########################
    my $self  = shift;
    my %args  = @_;
    my $q     = $self->query;
    my $dbc   = $args{-dbc};
    my $id    = $args{-id};
    my $quiet = $args{-quiet};

    return $self->param('Model')->home_info($id);

}

###########################
sub display_new_equipment_block {
###########################
    #
    #
###########################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query;

    my $new_equip_block
        = alDente::Form::start_alDente_form( $dbc, 'New Equipment Form' )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Equipment_App', -force => 1 )
        . $q->submit( -name => 'rm', -value => "New Equipment", -class => "Std", -force => 1 )
        . $q->end_form();

    my $new_category_block = '';
    if ( defined $dbc->Security->{login}->{LIMS_admin} ) {
        if ( $dbc->Security->{login}->{LIMS_admin} ) {
            $new_category_block
                = alDente::Form::start_alDente_form( $dbc, 'New category Form' )
                . Show_Tool_Tip( $q->submit( -name => 'rm', -value => "New Category", -class => "Std" ), "Equipment Category home page" ) . "<BR>"
                . $q->hidden( -name => 'cgi_application', -value => 'alDente::Stock_App', -force => 1 )
                . $q->end_form();
        }
    }

    my $table = alDente::Form::init_HTML_table( "Add Equipment", -margin => 'on' );
    $table->Set_Row( [ '', $new_equip_block . hspace(20) . $new_category_block ] );
    my $add_block = $table->Printout(0);

    return $add_block;
}

###########################
sub display_search_block {
###########################
    #
    #
###########################
    my $self          = shift;
    my %args          = @_;
    my $dbc           = $args{-dbc} || $self->param('dbc');
    my $q             = $self->query;
    my $types         = $self->param('Model')->get_equipment_types( -dbc => $dbc );
    my $search_header = alDente::Web::icons( 'Search', -dbc => $dbc );                                                                                    ## "\n<img src='/$URL_dir_name/$image_dir/search.png'>";
    my @vendors       = $dbc->get_FK_info_list( -field => 'FK_Organization__ID', -condition => "WHERE Organization_Type like '%Vendor%'" );
    my @manufacturers = $dbc->get_FK_info_list( -field => 'FK_Organization__ID', -condition => "WHERE Organization_Type like '%manufacturer%'" );
    my @groups        = $dbc->get_FK_info_list( -field => 'FK_Grp__ID', -condition => "WHERE Grp_Status = 'Active'" );
    my @locations     = $dbc->get_FK_info_list( -field => 'FK_Location__ID', -condition => "WHERE Location_Status = 'Active' order by Location_Name" );

    my $search
        = alDente::Form::start_alDente_form( $dbc, 'Equipment Search' )
        . Show_Tool_Tip( $q->submit( -name => 'Search for', -value => "Search/Edit Equipment", -class => "Search" ), "Detailed search for Equipment" )
        . &hspace(10)
        . $q->checkbox( -name => 'Multi-Record' )
        . $q->hidden( -name => 'Table', -value => 'Equipment', -force => 1 ) . '<hr>'
        . $q->end_form;

    my $table = alDente::Form::init_HTML_table( "Search", -margin => 'on' );
    $table->Set_Row( [ $search_header, "", $search ] );
    $table->Set_Row(
        [ '', '', alDente::Form::start_alDente_form( $dbc, 'Equipment Search MVC' ) . Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'List Equipment', -force => 1, -class => 'Search' ), "Display a list of ACTIVE Equipment in the system" ) ] );
    $table->Set_Row( [ '', 'Type:',          $q->popup_menu( -name => 'Equip Type',         -values => [ '', @$types ],        -default => "" ) ] );
    $table->Set_Row( [ '', "Vendor: ",       $q->popup_menu( -name => 'Equip Vendor',       -values => [ '', @vendors ],       -default => "" ) ] );
    $table->Set_Row( [ '', "Manufacturer: ", $q->popup_menu( -name => 'Equip Manufacturer', -values => [ '', @manufacturers ], -default => "" ) ] );
    $table->Set_Row( [ '', "Group: ",        $q->popup_menu( -name => 'Equip Grp',          -values => [ '', @groups ],        -default => "" ) ] );
    $table->Set_Row( [ '', "Location: ",     $q->popup_menu( -name => 'Equip Location',     -values => [ '', @locations ],     -default => "" ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Equipment_App', -force => 1 ) . $q->end_form ] );
    $table->Set_Alignment( 'right', 2 );
    $table->Set_Alignment( 'left',  3 );
    return $table->Printout(0);

}

###########################
sub display_maintenance_block {
###########################
    #
    #
###########################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query;

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
    $table->Set_Row( [ alDente::Web::icons( 'Maintenance', -dbc => $dbc ), $maint_block ] );

    my $block = alDente::Form::start_alDente_form( $dbc, 'Maintenance Search' );
    $block .= $table->Printout(0);
    $block .= $q->end_form();

    return $block;

}

###########################
sub display_small_label_block {
###########################
    #
    #
###########################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query;

    my $small_label_header = "<img src='/$URL_dir_name/$image_dir/smalllabel.gif'>";

    my $small_label_block = alDente::Form::start_alDente_form( $dbc, 'Small Label' );
    $small_label_block .= "Field 1 : " . $q->textfield( -name => 'Field1', -force => 1 ) . $q->br();
    $small_label_block .= "Field 2 : " . $q->textfield( -name => 'Field2', -force => 1 ) . $q->br();
    $small_label_block .= $q->submit( -name => "Barcode_Event", -value => "Print Simple Small Label", -class => "Std" );
    $small_label_block .= hspace(5) . "RepeatX  " . $q->textfield( -name => 'RepeatX', default => '', -force => 1, -size => 5 );
    $small_label_block .= $q->end_form();
    my $table = alDente::Form::init_HTML_table( "Small Tube", -margin => 'on' );
    $table->Set_Row( [ alDente::Web::icons( 'Barcodes', -dbc => $dbc ), $small_label_header, $small_label_block ] );
    return $table->Printout(0);
}

###########################
sub display_large_Label_block {
###########################
    #
    #
###########################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query;

    my $large_label_header = "<img src='/$URL_dir_name/$image_dir/largelabel.gif'>";

    my $large_label_block = alDente::Form::start_alDente_form( $dbc, 'Large Label' );
    $large_label_block .= "Field 1 : " . $q->textfield( -name => 'Field1', -force => 1 ) . $q->br();
    $large_label_block .= "Field 2 : " . $q->textfield( -name => 'Field2', -force => 1 ) . $q->br();
    $large_label_block .= "Field 3 : " . $q->textfield( -name => 'Field3', -force => 1 ) . $q->br();
    $large_label_block .= "Field 4 : " . $q->textfield( -name => 'Field4', -force => 1 ) . $q->br();
    $large_label_block .= "Field 5 : " . $q->textfield( -name => 'Field5', -force => 1 ) . $q->br();
    $large_label_block .= $q->submit( -name => 'Barcode_Event', -value => "Print Simple Large Label", -class => "Std" );
    $large_label_block .= hspace(5) . "RepeatX  " . $q->textfield( -name => 'RepeatX', default => '', -force => 1, -size => 5 );
    $large_label_block .= $q->end_form();

    my $table = alDente::Form::init_HTML_table( "Large Label", -margin => 'on' );
    $table->Set_Row( [ '', $large_label_header, $large_label_block ] );
    return $table->Printout(0);
}

###########################
sub display_tube_label_block {
###########################
    #
    #
###########################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query;

    my $tube_label_header = "<img src='/$URL_dir_name/$image_dir/smalllabel.gif'>";

    my $tube_label_block = alDente::Form::start_alDente_form( $dbc, 'Tube Label' );
    $tube_label_block .= "Field 1 : " . $q->textfield( -name => 'Field1', -force => 1 ) . $q->br();
    $tube_label_block .= "Field 2 : " . $q->textfield( -name => 'Field2', -force => 1 ) . $q->br();
    $tube_label_block .= "Field 3 : " . $q->textfield( -name => 'Field3', -force => 1 ) . $q->br();
    $tube_label_block .= "Field 4 : " . $q->textfield( -name => 'Field4', -force => 1 ) . $q->br();
    $tube_label_block .= "Field 5 : " . $q->textfield( -name => 'Field5', -force => 1 ) . $q->br();
    $tube_label_block .= $q->submit( -name => 'Barcode_Event', -value => "Print Simple Tube Label", -class => "Std" );
    $tube_label_block .= hspace(5) . "RepeatX  " . $q->textfield( -name => 'RepeatX', default => '', -force => 1, -size => 5 );
    $tube_label_block .= $q->end_form();

    my $table = alDente::Form::init_HTML_table( "Tube Label", -margin => 'on' );
    $table->Set_Row( [ '', $tube_label_header, $tube_label_block ] );
    return $table->Printout(0);
}

1;
