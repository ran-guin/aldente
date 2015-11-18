###################################################################################################################################
# alDente::Stock_App.pm
#
#
#
# Created by: Ash Shafiei July 2008
###################################################################################################################################
package alDente::Stock_App;

use base RGTools::Base_App;
use strict;

#use Data::Dumper;

## SDB modules
use SDB::CustomSettings;
use SDB::DB_Form;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;

#use RGTools::Views;

## alDente modules
use alDente::Stock;
use alDente::Stock_Views;
use alDente::Solution;
use alDente::Form;
use alDente::SDB_Defaults;
use alDente::Form;
use alDente::Barcoding;
use alDente::Tools;

use vars qw($Connection %Configs $Security);

#####################################
# Setup                             #
#####################################
###########################
sub setup {
###########################
    my $self = shift;

    $self->start_mode('Default Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(

        'Activate'                   => 'activate_action',
        'Activate Catalog Item'      => 'active_catalog_record_page',
        'Add Box Info'               => 'new_box_page',                 ##
        'Add Catalog Item'           => 'save_catalog_info',            ##
        'Add Equipment Category'     => 'save_category',
        'Add Equipment Info'         => 'new_equipment_page',
        'Add Microarray Info'        => 'new_micro_page',               ##
        'Add Misc_Item Info'         => 'new_Misc_Item_page',           ##
        'Add Solution Info'          => 'new_reagent_page',             ##
        'Assign Category'            => 'activate_action',
        'Catalog Form'               => 'new_stock_catalog_page',       ##
        'Default Page'               => 'display_entry_page',
        'Find Solution'              => 'find_solution',
        'Find Stock Items'           => 'find_stock_items',
        'Log In'                     => 'display_entry_page',
        'New Category'               => 'new_category',
        'New Stock'                  => 'display_search_results',       ##
        'Save Equipment Info'        => 'save_equipment_info',
        'Save Info'                  => 'save_stock_details',           ##
        'Search Catalog'             => 'display_search_results',       ##
        'Search Inventory'           => 'inventory_search_result',
        'Stock Details'              => 'find_stock_details',
        'Stock Form'                 => 'new_stock_page',               ##
        'Stock Used'                 => 'display_stock_used',
        'Show Multiple Box Records'  => 'new_box_page',
        'Extract New Stock from Box' => 'display_entry_page',

    );
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');
    $self->param(
        'Model' => alDente::Stock->new( -dbc => $dbc )

            #	'View'  =>
    );

    return 0;

}
#####################################
# Run Modes                         #
#####################################
###########################
sub find_stock_items {
###########################
    my $self           = shift;
    my $q              = $self->query;
    my $dbc            = $self->param('dbc');
    my $stock_type     = $q->param('stock_type');
    my @marked         = $q->param('Mark');
    my $active         = $q->param('Active');
    my $stock_category = _get_category($stock_type);

    return alDente::Stock_Views::display_stock_item( -dbc => $dbc, -table => $stock_category, -ids => \@marked, -active => $active );

}

###########################
sub find_solution {
###########################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $since;
    my $until;
    my $stock              = $q->param('Stock_Catalog_Name');
    my $solution_type      = $q->param('Solution_Type');
    my $solutions          = $q->param('Solutions');
    my $grp                = $q->param('Grp');
    my $show_null          = $q->param('Show_Null_Racks');
    my $show_TBD           = $q->param('Show_TBD');
    my $search_child_racks = $q->param('Search_Child_Racks');
    my $equ_condition      = join( ",", $q->param('Equipment_Condition') );                       # || $q->param('Equipment_Condition Choice'));
    my @group_by           = $q->param('Group_By');                                               # || param ('Group_By Choice');
    my @equip              = $q->param('Equipment_Name') || $q->param('Equipment_Name Choice');

    $equ_condition = Cast_List( -list => $equ_condition, -to => 'String', -autoquote => 1 ) if $equ_condition;
    my $equip = Cast_List( -list => \@equip, -to => 'String', -autoquote => 1 ) if (@equip);

    unless (@group_by) {
        @group_by = ( 'Equipment_Condition', 'Equipment', 'Rack_ID', 'FK_Stock__ID', 'Solution_ID' );
    }

    my $rack_id;
    if    ( $q->param('FK_Rack__ID') =~ /Rac(\d+)/ ) { $rack_id = $1; }
    elsif ( $q->param('FK_Rack__ID') =~ /(\d+)/ )    { $rack_id = $q->param('FK_Rack__ID'); }

    $grp = get_FK_ID( $dbc, 'FK_Grp__ID', $grp );

    my $found = &alDente::Rack_Views::find(
        -dbc                 => $dbc,
        -equipment           => $equip,
        -rack_id             => $rack_id,
        -search_child_racks  => $search_child_racks,
        -since               => $since,
        -until               => $until,
        -equipment_condition => $equ_condition,
        -group_by            => \@group_by,
        -show_null           => $show_null,
        -show_TBD            => $show_TBD,
        -stock               => $stock,
        -solution_type       => $solution_type,
        -solutions           => $solutions,
        -find                => 'Solution',
        -grp                 => $grp
    );

    unless ($found) {
        eval "require alDente::Solution_App";
        my $webapp = alDente::Solution_App->new( PARAMS => { dbc => $dbc } );
        return $webapp->entry_page();
    }
}

###########################
sub inventory_search_result {
###########################
    my $self          = shift;
    my $q             = $self->query;
    my $dbc           = $self->param('dbc');
    my $search_option = $q->param('Search Options');
    my $cat_name      = $q->param('Stock_Catalog_Name');
    my $cat_num       = $q->param('Stock_Catalog_Number');
    my $date_range    = $q->param('MadeWithin');
    my $all_users     = $q->param('All users');
    my $include       = $q->param('Include');
    my $department    = join ',', $q->param('FK_Department__ID Choice');
    my $organization  = join "','", $q->param('FK_Organization__ID Choice');
    my $stock_source  = join "','", $q->param('Stock_Source');
    unless ($department)   { $department   = join ',',   $q->param('FK_Department__ID') }
    unless ($organization) { $organization = join "','", $q->param('FK_Organization__ID') }
    my $title       = "Finding Reagents/Solutions";
    my $search_type = 'Solution';
    if ( $search_option eq 'Find Boxes' ) { $title = "Finding Boxs/Kits"; $search_type = 'Box' }

    my $condition;
    my $groups = $self->param('Model')->find_group_list( -department => $department, -dbc => $dbc );
    if ($groups) { $condition .= " AND Stock.FK_Grp__ID IN ($groups) " }
    if ( $include eq 'Active Only' ) { $condition .= " AND Stock_Catalog.Stock_Status = 'Active' " }

    if ( !$cat_name && !$cat_num && !$organization && !$date_range ) {
        Message("You need to specify some search criteria.  Choosing at least one of 'Catalog Name', 'Catalog Number','Manufacturer', or 'date' is mandatory.");
        my @types = ( 'Manufacturer', 'Vendor' );
        my $org_list = $self->param('Model')->get_organization_list( -type => \@types, -dbc => $dbc );
        return &alDente::Stock_Views::search_stock_box( -dbc => $dbc, -organizations => $org_list );

    }
    elsif ( $search_option eq 'Find Solutions' || $search_option eq 'Find Boxes' ) {
        $condition .= " AND DATE_SUB(CURDATE(),INTERVAL $date_range DAY) <= Stock_Received" if $date_range;
        my $Stock_Info = $self->param('Model')->find_Stock(
             $dbc,
            -type      => $search_type,
            -cat_name  => $cat_name,
            -cat_num   => $cat_num,
            -group     => $groups,
            -condition => $condition,

            -org_name => $organization,
            -source   => $stock_source
        );
        return alDente::Stock_Views::display_stock_inventory(
            -dbc      => $dbc,
            -info     => $Stock_Info,
            -type     => $search_type,
            -title    => $title,
            -cat_name => $cat_name,
            -cat_num  => $cat_num,
            -group    => $groups
        );
    }
    elsif ( $search_option eq 'Find All Stock' ) {
        $condition .= " AND DATE_SUB(CURDATE(),INTERVAL $date_range DAY) <= Stock_Received" if $date_range;
        $condition .= " AND Stock_Catalog_ID = FK_Stock_Catalog__ID";
        my @sources = split ',', $stock_source;
        my $catalog_IDS = $self->param('Model')->get_catalog_ids(
            -dbc        => $dbc,
            -name       => $cat_name,
            -cat        => $cat_num,
            -groups     => $groups,
            -dcondition => $condition,
            -org        => $organization,
            -table      => 'Stock,Stock_Catalog',
            -sources    => \@sources
        );

        if (@$catalog_IDS) {
            return &alDente::Stock_Views::display_inventory_records( -dbc => $dbc, -catalog_ids => $catalog_IDS );
        }
        else {
            Message("No Result.");
            return &alDente::Stock_Views::search_stock_box( -dbc => $dbc );
        }
    }
    Message('Warning: You should not be here. Inform LIMS');
    return;
}

###########################
sub find_stock_details {
#####################
    my $self = shift;
    my $q    = $self->query;

    my $dbc         = $self->param('dbc');
    my $search_name = $q->param('Search String Name');
    my $search_num  = $q->param('Search String Number');
    my $grp         = $q->param('Search Group') || $q->param('Grp');
    my $condition   = $q->param('Search Condition');
    my $s_type      = $q->param('Stock Type');
    my $s_label     = $q->param('Details for Stock');
    my $search_by   = $q->param('Search By');
    my $include     = $q->param('Include Finished Bottles');

    my $cat  = $search_num;
    my $name = $search_name;
    $s_label =~ s/\*/\%/g;

    my $info = $self->param('Model')->get_Stock_details(
        -dbc              => $dbc,
        -name             => $name,
        -cat              => $cat,
        -grp              => $grp,
        -condition        => $condition,
        -type             => $s_type,
        -label            => $s_label,
        -include_finished => $include,
        -search_name      => $search_name,
        -search_num       => $search_num
    );

    return alDente::Stock_Views::display_stock_details( -info => $info, -dbc => $dbc, -name => $name, -cat => $cat, -type => $s_type, -label => $s_label, -search_name => $search_name, -search_num => $search_num );

}

###########################
sub display_entry_page {
###########################
    # Description:
    #	- this runmode to be called from receiving home page by setting cgi-application=alDente::Stock_App
    #	- it promts the catalog number or name from user
    # Input:
    #	- database connection: dbc
###########################
    my $self          = shift;
    my %args          = &filter_input( \@_ );
    my $q             = $self->query;
    my $dbc           = $self->param('dbc') || $args{-dbc};
    my $box_item_type = $self->param('type') || $args{-box_item_type} || $q->param('Boxed Items');
    my $box_id        = $self->param('box_id') || $args{-box_id} || $q->param('Box_ID');

    return alDente::Stock_Views::display_entry_page( -dbc => $dbc, -box_id => $box_id, -box_item_type => $box_item_type );
}

###########################
sub display_search_results {
###########################
    # Description:
    #	- This run mode will call a function to decide if there is a UNIQUE match for the prompted catalog name or number
    #		and according to the results of the finding it will execute one of two options
    #
###########################
    my $self          = shift;
    my $q             = $self->query;
    my %args          = @_;
    my $dbc           = $self->param('dbc') || $args{-dbc};
    my $search_by     = $q->param('Stock_Search_By');
    my $cat           = $q->param('Catalog_Number');
    my $name          = $q->param('Stock_Name') || $q->param('Stock_Catalog_Name');
    my $stock_object  = $self->param('Model');
    my @stock_types   = $q->param('Stock_Type');
    my @stock_sources = $q->param('Stock_Source');
    my $organization  = $q->param('FK_Organization__ID Choice') || $q->param('FK_Organization__ID');
    my $category      = $q->param('FK_Equipment_Category__ID Choice');
    my $vendor        = $q->param('FKVendor_Organization__ID Choice') || $q->param('FKVendor_Organization__ID');
    my $box_id        = $q->param('box_id');
    my $box_item_type = $q->param('box_item_type');

    my $catalog_ids_ref = $args{-catalog_ids};
    my $form;

    if ( !$cat && !$name ) {
        if    ( $search_by =~ /By Catalog Num/i ) { $cat  = $q->param('Stock_Search_String') }
        elsif ( $search_by =~ /By Name/i )        { $name = $q->param('Stock_Search_String') }
    }

    $catalog_ids_ref ||= $stock_object->get_catalog_ids(
        -dbc           => $dbc,
        -cat           => $cat,
        -name          => $name,
        -types         => \@stock_types,
        -sources       => \@stock_sources,
        -category      => $category,
        -org           => $organization,
        -vendor        => $vendor,
        -box_id        => $box_id,
        -box_item_type => $box_item_type
    );
    my @catalog_ids = @$catalog_ids_ref;
    my $list_size   = @catalog_ids;

    if ( $list_size > 1 ) {
        $form .= $self->list_page( -dbc => $dbc, -list => $catalog_ids_ref, -box_id => $box_id, -box_item_type => $box_item_type );
        if ( $dbc->Security->department_access() =~ /Admin/i ) {
            $form .= $self->new_item( -dbc => $dbc, -box_id => $box_id, -box_item_type => $box_item_type );
        }

    }
    elsif ($list_size) {
        if ( $self->check_validity( -dbc => $dbc, -id => $catalog_ids[0] ) ) {
            $form .= $self->new_stock_page( -dbc => $dbc, -id => $catalog_ids[0], -box_id => $box_id, -box_item_type => $box_item_type );
        }
        else {
            $form .= $self->list_page( -dbc => $dbc, -list => $catalog_ids_ref, -box_id => $box_id, -box_item_type => $box_item_type );
            if ( $dbc->Security->department_access() =~ /Admin/i ) {
                $form .= $self->new_item( -dbc => $dbc, -box_id => $box_id, -box_item_type => $box_item_type );
            }
        }
    }
    else {
        Message("Nothing found");
        $form .= $self->display_empty_page( -dbc => $dbc, -box_id => $box_id, -box_item_type => $box_item_type );
    }

    return $form;
}    ##end of seach_results

###########################
sub check_validity {
###########################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};
    my ($status) = $dbc->Table_find( 'Stock_Catalog', 'Stock_Status', "WHERE Stock_Catalog_ID = $id" );
    if   ( $status =~ /^active/i ) { return 1 }
    else                           { return; }

}

###########################
sub list_page {
###########################
    # 	Description
    #		- This page is called when the search string has not been matched to multiple stocks in Stock Catalog
    #	Input:
    #		- An array containing list of Stock_Catalog_ID's  and dbc (database connection)
    #	Output:
    #		- a page in form of html links to each of the ID's which will be connected to the form_page
###########################
    my $self          = shift;
    my %args          = &filter_input( \@_ );
    my $dbc           = $args{-dbc};
    my $number        = $args{-cat};             ### catalog number entered (normal input for new stock) - presets most fields on form
    my $name          = $args{-name};            ### stock name (normal input for new stock) - presets most fields on form
    my $list_ref      = $args{-list};            ### a reference to array of matched catalog id's
    my $box_id        = $args{-box_id};
    my $box_item_type = $args{-box_item_type};

    return alDente::Stock_Views::display_list_page( -dbc => $dbc, -list => $list_ref, -box_id => $box_id );

}    ##end of list_page

###########################
sub display_empty_page {
###########################
    # Description
    #	- This page is called when the search string has not been partially or uniquely matched
###########################
    my $self          = shift;
    my %args          = &filter_input( \@_ );
    my $q             = $self->query;
    my $dbc           = $self->param('dbc') || $args{-dbc};
    my $dbc           = $args{-dbc};
    my $number        = $args{-cat};                          ### catalog number entered (normal input for new stock) - presets most fields on form
    my $name          = $args{-name};                         ### stock name (normal input for new stock) - presets most fields on form
    my $box_id        = $args{-box_id};
    my $box_item_type = $args{-box_item_type};

    #generate Message
    my $form .= "<B><i>Enter any portion of the catalog number or name to retrieve current stock item. Use * for wildcard if desired.<Br>" . "Or you  could use 'Catalog Lookup' to search the full catalog. </i></B><Br>" . vspace(2);

    $form .= $self->display_entry_page( -dbc => $dbc, -box_id => $box_id, -box_item_type => $box_item_type ) . '<HR/>';

    # advanced seach
    $form .= $self->display_catalog_lookup( -dbc => $dbc, -box_id => $box_id, -box_item_type => $box_item_type ) . '<HR/>';
    $form .= $self->new_item( -dbc => $dbc, -box_id => $box_id, -box_item_type => $box_item_type ) . '<HR/>';

    return $form;

}

##########################
sub display_catalog_lookup {
##########################
    #   Description:
    #       - Displays a search table which will search the catalog to find catalog id's
##########################
    my $self          = shift;
    my %args          = filter_input( \@_ );
    my $dbc           = $args{-dbc};
    my $q             = $self->query;
    my $open_option   = '1';
    my $manufacturers = $self->param('Model')->get_organization_list( -dbc => $dbc, -type => ['Manufacturer'] );
    my $vendors       = $self->param('Model')->get_organization_list( -dbc => $dbc, -type => ['Vendor'] );

    my $page = alDente::Stock_Views::display_catalog_lookup( -dbc => $dbc, -manufacturer => $manufacturers, -vendor => $vendors );
    return $page;

}

##########################
sub new_stock_page {
###########################
    #   Desciption:
    #   - run mode, it displays a query from which asks the user for information to be stored in 'Stock' table
###########################
    my $self             = shift;
    my %args             = &filter_input( \@_ );
    my $q                = $self->query;
    my $dbc              = $self->param('dbc') || $args{-dbc};
    my $stock_catalog_id = $self->param('stock_catalog_id') || $q->param('stock_catalog_id') || $args{-id};
    my $box_id           = $self->param('box_id') || $q->param('box_id') || $args{-box_id};
    my $box_item_type    = $self->param('box_item_type') || $args{-box_item_type};

    ## Getting the preset information
    my %info       = $dbc->Table_retrieve( 'Stock_Catalog', [ 'Stock_Type', 'Stock_Catalog_Name', 'FK_Equipment_Category__ID' ], "where Stock_Catalog_ID = $stock_catalog_id" );
    my $stock_type = $info{Stock_Type}[0];
    my $stock_name = $info{Stock_Catalog_Name}[0];
    my $cat_ID     = $info{FK_Equipment_Category__ID}[0];
    my $category   = _get_category($stock_type);

    my $next_page = 'Add ' . _get_category($stock_type) . ' Info';                                                 ## the next page button
    my @labels    = $dbc->get_FK_info_list( 'FK_Barcode_Label__ID', "WHERE Barcode_Label_Type = '$category'" );    ## getting the list of labels
    my @groups    = $dbc->get_FK_info_list( 'FK_Grp__ID', "WHERE Grp_Type NOT LIKE '%dmin'" );                     ## getting the list of labels

    my $previous_label = _get_barcode_label( -catalog_id => $stock_catalog_id, -dbc => $dbc );
    my $previous_grp   = _get_previous_grp( -catalog_id  => $stock_catalog_id, -dbc => $dbc );

    my %preset;
    my %grey;
    my %list;
    my %hidden;
    $grey{FK_Employee__ID}              = $dbc->get_local('user_id');
    $grey{FK_Stock_Catalog__ID}         = $stock_catalog_id;
    $preset{Stock_Received}             = "<TODAY>";
    $list{'Stock.FK_Barcode_Label__ID'} = \@labels;
    $list{'Stock.FK_Grp__ID'}           = \@groups;
    if ($box_id) {
        $grey{'Stock.FK_Box__ID'} = $box_id;
    }
    else {
        $hidden{'Stock.FK_Box__ID'} = '';
    }
    if ($previous_label) { $preset{'Stock.FK_Barcode_Label__ID'} = $previous_label }
    if ($previous_grp)   { $preset{'Stock.FK_Grp__ID'}           = $previous_grp }

    ## Building query form
    my $table = SDB::DB_Form->new( -dbc => $dbc, -table => 'Stock', -target => 'Database', -wrap => 0 );
    $table->configure( -list => \%list, -grey => \%grey, -preset => \%preset, -omit => \%hidden );

    my $display_this = alDente::Stock_Views::display_stock_catalog_record( -dbc => $dbc, -id => $stock_catalog_id );

    my $page
        = Views::sub_Heading( "Receiving Stock", 1 )
        . alDente::Form::start_alDente_form( $dbc, 'Stock Form' )
        . "<Table cellpadding=10 width=100%><TR>"
        . "</TD><TD height=1 valign=top>"
        . $table->generate( -button => { 'rm' => $next_page }, -navigator_on => 0, -return_html => 1 )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Stock_App', -force => 1 )
        . $q->hidden( -name => 'catalog id',      -value => $stock_catalog_id,    -force => 1 )
        . $q->hidden( -name => 'stock type',      -value => $stock_type,          -force => 1 )
        . $q->hidden( -name => 'category ID',     -value => $cat_ID,              -force => 1 )
        . "</TD><TD rowspan=3 valign=top>"
        . $display_this
        . "</TD>\n";
    $page .= "</TD></TR></Table>" . $q->end_form();
    return $page;
}

###########################
sub new_stock_catalog_page {
###########################
    #   Desciption:
    #   - run mode, it displays a query from which asks the user for information to be stored in 'Stock_Catalog' table
    # Notes:    BOX_ID will only exist if the item is being extracted from a box and therefore affect the settings
    #           Made in House Flag will be set if the item is beig made in house and therefore will preset moset of the fields
    #           Fields "Model", "FK_Equipment_Cateogry__ID" only relate to equipment and are therefore turned off for all other items
###########################
    my $self          = shift;
    my %args          = &filter_input( \@_ );
    my $q             = $self->query;
    my $stock_type    = $q->param('Stock_Type');
    my $dbc           = $self->param('dbc') || $args{-dbc};
    my $box_id        = $self->param('box_id') || $q->param('box_id');
    my $box_item_type = $self->param('box_item_type') || $q->param('box_item_type');
    my $made_in_house = $self->param('in_house') || $q->param('in_house');

    ## pre-setting the information which have been already decided
    my $category      = _get_category($stock_type);
    my @labels        = $dbc->get_FK_info_list( 'FK_Barcode_Label__ID', "WHERE Barcode_Label_Type = '$category'" );
    my @manufacturers = $dbc->get_FK_info_list( "FK_Organization__ID", "Where Organization_Type Like '%Manufacturer%'" );
    my @vendors       = $dbc->get_FK_info_list( "FK_Organization__ID", "Where Organization_Type Like '%Vendor%'" );
    my %require;
    my %preset;
    my %grey;
    my %list;

    $preset{'Stock_Catalog.Stock_Status'}            = 'Active';
    $list{'Stock_Catalog.FK_Organization__ID'}       = \@manufacturers;
    $list{'Stock_Catalog.FKVendor_Organization__ID'} = \@vendors;

    if ( $category ne 'Solution' ) {
        $preset{'Stock_Catalog.Stock_Size'}       = 1;
        $preset{'Stock_Catalog.Stock_Size_Units'} = 'pcs';
    }

    if   ($box_id) { $grey{'Stock_Catalog.Stock_Source'} = 'Box' }
    else           { $grey{'Stock_Catalog.Stock_Source'} = 'Order' }

    if ( $category eq 'Equipment' ) {
        $require{'Stock_Catalog.FK_Equipment_Category__ID'} = 1;
    }
    else {
        $grey{'Stock_Catalog.FK_Equipment_Category__ID'} = '';
        $grey{'Stock_Catalog.Model'}                     = '';
    }

    if ($made_in_house) {
        require alDente::Tools;
        my $org = alDente::Tools::get_local_organization_id( -dbc => $dbc, -return => 'Name' );
        $grey{'Stock_Catalog.Stock_Source'}              = 'Made in House';
        $grey{'Stock_Catalog.Stock_Size'}                = '0';
        $grey{'Stock_Catalog.Stock_Size_Units'}          = 'n/a';
        $grey{'Stock_Catalog.FK_Organization__ID'}       = $org;
        $grey{'Stock_Catalog.FKVendor_Organization__ID'} = $org;
        $grey{'Stock_Catalog.Model'}                     = '';
        $grey{'Stock_Catalog.Stock_Catalog_Number'}      = '';
        $list{'Stock_Catalog.Stock_Type'}                = [ 'Buffer', 'Matrix', 'Primer', 'Reagent', 'Solution' ];
    }
    else {
        $require{'Stock_Catalog.Stock_Size'} = 1;
        $grey{'Stock_Catalog.Stock_Type'}    = $stock_type;
    }

    ## creating the table
    my $table = SDB::DB_Form->new( -dbc => $dbc, -table => 'Stock_Catalog', -target => 'Database', -wrap => 0 );
    $table->configure( -grey => \%grey, -preset => \%preset, -list => \%list, -require => \%require );

    my $page
        .= alDente::Form::start_alDente_form( $dbc, 'Stock Catalog Form' )
        . $table->generate( -button => { 'rm' => 'Add Catalog Item' }, -navigator_on => 0, -return_html => 1 )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Stock_App', -force => 1 )
        . $q->hidden( -name => 'stock type', -value => $stock_type, -force => 1 );
    $page .= $q->hidden( -name => 'box_id',             -value => $box_id,        -force => 1 ) if $box_id;
    $page .= $q->hidden( -name => 'made in house flag', -value => $made_in_house, -force => 1 ) if $made_in_house;

    $page .= $q->end_form();

    return $page;

}

###########################
sub activate_action {
###########################
    my $self       = shift;
    my %args       = &filter_input( \@_ );
    my $dbc        = $self->param('dbc') || $args{-dbc};
    my $q          = $self->query;
    my $category   = $q->param('FK_Equipment_Category__ID Choice');
    my $catalog_id = $q->param('catalog_id');
    my $list       = $q->param('catalog_ids_list');
    my $confirmed  = $q->param('confirmed');

    if ( $confirmed && !$category ) {
        my $ok = $self->param('Model')->activate_catalog_item( -catalog_id => $catalog_id, -dbc => $dbc );
    }
    elsif ($category) {
        my $ok = $self->param('Model')->assign_category( -category => $category, -catalog_id => $catalog_id, -dbc => $dbc );
    }
    else {
        Message " No Category selected";
    }
    my @id_list = split ',', $list;
    return alDente::Stock_Views::display_list_page( -dbc => $dbc, -list => \@id_list );

}

###########################
sub active_catalog_record_page {
###########################
    my $self       = shift;
    my %args       = &filter_input( \@_ );
    my $q          = $self->query;
    my $catalog_id = $q->param('stock_catalog_id');
    my $dbc        = $self->param('dbc') || $args{-dbc};
    my $list       = $q->param('cata_id_list');
    if ( $dbc->Security->department_access() =~ /Admin/i ) {
        my @info = $dbc->Table_find( -table => 'Stock_Catalog', -fields => "Stock_Type,FK_Equipment_Category__ID", -condition => "WHERE Stock_Catalog_ID = $catalog_id" );
        ( my $type, my $category ) = split ',', $info[0];
        if ( $type eq 'Equipment' && !$category ) {
            return alDente::Stock_Views::display_category_activation_page( -dbc => $dbc, -catalog_id => $catalog_id, -catalog_ids_list => $list );
        }
        else {
            return alDente::Stock_Views::display_simple_activation_page( -dbc => $dbc, -catalog_id => $catalog_id, -catalog_ids_list => $list );
        }
    }
    else {
        Message 'This page is only accessible to admin, please ask an admin to activate this equipment for you';
        my @id_list = split ',', $list;
        return alDente::Stock_Views::display_list_page( -dbc => $dbc, -list => \@id_list );
    }

}

###########################
sub new_box_page {
###########################
    #   - Description
    #           Creates a query form for Boxes
###########################
    my $self       = shift;
    my $q          = $self->query;
    my $dbc        = $self->param('dbc');
    my $catalog_id = $q->param('catalog id');
    my $type       = $q->param('stock type') || $q->param('Stock type');
    my $Mul_flag   = 0;                                                    ## This flag indicates if multiple row or single row records shold be displayed
    if ( $q->param('rm') eq 'Show Multiple Box Records' ) { $Mul_flag = 1 }

    ## getting the parameters
    ( my $fields, my $values ) = alDente::Form::get_form_input( -table => 'Stock', -object => $self, -dbc => $dbc );
    my $hidden_info = alDente::Form::get_form_input( -table => 'Stock', -object => $self, -HTML_on => 1, -dbc => $dbc );
    my $num_in_batch = _return_value( -fields => $fields, -values => $values, -target => 'Stock_Number_in_Batch' );

    ## Setting up the pre decided fields
    my $rack_condition = $self->_get_rack_condition( -dbc => $dbc );
    my %condition;
    $condition{'FK_Rack__ID'} = $rack_condition;

    my %grey;
    $grey{'Box_Number_in_Batch'} = $num_in_batch;
    $grey{'Box_Type'}            = $type;
    $grey{'Box_Status'}          = 'Unopened';
    my @numbers;
    for my $counter ( 1 .. $num_in_batch ) { push @numbers, $counter }
    $grey{'Box_Number'} = \@numbers;
    if ( $num_in_batch == 1 ) { $grey{'Box_Number'} = 1 }
    my %omit;
    $omit{'FK_Stock__ID'}     = 1;
    $omit{'Used_DateTime'}    = 1;
    $omit{'FKParent_Box__ID'} = '';

    ##creating the new form
    my @target_fields = $dbc->get_field_list( -table => 'Box', -qualify => 1 );
    my %autofill_hash = map { $_ => 1 } @target_fields;    #make it into a hash

    my $repeat;
    if   ($Mul_flag) { $repeat             = $num_in_batch - 1 }
    else             { $omit{'Box_Number'} = 1 }

    my $table = &SDB::HTML::query_form(
        -dbc       => $dbc,
        -table     => 'Box',
        -action    => 'append',
        -grey      => \%grey,
        -condition => \%condition,
        -omit      => \%omit,
        -submit    => 1,
        -autofill  => \%autofill_hash,
        -button    => { 'rm' => 'Save Info' },
        -repeat    => $repeat
    );

    my $page = Views::sub_Heading( "Adding Box Information", 1 ) . alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Box_Form' );
    unless ($Mul_flag) {
        $page
            .= $q->submit( -name => 'rm', -value => 'Show Multiple Box Records', -force => 1, -class => "Std" )
            . vspace()
            . vspace()
            . "To set specific data for each individual item press the button above,"
            . vspace()
            . " otherwise given info will be assumed to be identical for all $num_in_batch items"
            . vspace();
    }
    $page
        .= $table
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Stock_App', -force => 1 )
        . $q->hidden( -name => 'Stock type',      -value => $type,                -force => 1 )
        . $q->hidden( -name => 'Catalog ID',      -value => $catalog_id,          -force => 1 )
        . $hidden_info
        . $q->end_form();

    return $page;
}

###########################
sub new_Misc_Item_page {
###########################
    #   - Description
    #           Creates a query form for Miscalanous Items
    #           Obsulete for now
###########################
    my $self       = shift;
    my $q          = $self->query;
    my $dbc        = $self->param('dbc');
    my $catalog_id = $q->param('catalog id');
    my $type       = $q->param('stock type');

    ## getting the parameters
    ( my $fields, my $values ) = alDente::Form::get_form_input( -table => 'Stock', -object => $self, -dbc => $dbc );
    my $num_in_batch = _return_value( -fields => $fields, -values => $values, -target => 'Stock_Number_in_Batch' );
    my $hidden_info = alDente::Form::get_form_input( -table => 'Stock', -object => $self, -HTML_on => 1, -dbc => $dbc );
    my $rack_condition = $self->_get_rack_condition( -dbc => $dbc );
    my %condition;
    $condition{'FK_Rack__ID'} = $rack_condition;

    my %grey;
    $grey{'Misc_Item_Number_in_Batch'} = $num_in_batch;
    $grey{'Misc_Item_Type'}            = $type;

    my @target_fields = qw(Misc_Item.FK_Rack__ID Misc_Item.Misc_Item_Type Misc_Item.Misc_Item_Number_in_Batch Misc_Item.Misc_Item_Serial_Number);
    my $table         = &SDB::HTML::query_form(
        -dbc       => $dbc,
        -fields    => \@target_fields,
        -action    => 'append',
        -grey      => \%grey,
        -condition => \%condition,
        -button    => { 'rm' => 'Save Info' },
        -repeat    => $num_in_batch - 1
    );

    my $page
        = alDente::Form::start_alDente_form( $dbc, 'Box Form' ) 
        . $table
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Stock_App', -force => 1 )
        . $q->hidden( -name => 'Stock type',      -value => $type,                -force => 1 )
        . $q->hidden( -name => 'Catalog ID',      -value => $catalog_id,          -force => 1 )
        . $hidden_info
        . $q->end_form();

    return $page;
}

###########################
sub new_micro_page {
###########################
    #   - Description
    #           Creates a query form for Microarrays
###########################
    my $self       = shift;
    my $q          = $self->query;
    my $dbc        = $self->param('dbc');
    my $catalog_id = $q->param('catalog id');
    my $type       = $q->param('stock type');

    ## getting the parameters from last table
    ( my $fields, my $values ) = alDente::Form::get_form_input( -table => 'Stock', -object => $self, -dbc => $dbc );
    my $hidden_info = alDente::Form::get_form_input( -table => 'Stock', -object => $self, -HTML_on => 1, -dbc => $dbc );
    my $num_in_batch = _return_value( -fields => $fields, -values => $values, -target => 'Stock_Number_in_Batch' );

    ## Setting up the pre decided fields
    my $rack_condition = $self->_get_rack_condition( -dbc => $dbc );
    my %condition;
    $condition{'FK_Rack__ID'} = $rack_condition;

    my %grey;
    $grey{'Microarray_Number_in_Batch'} = $num_in_batch;
    $grey{'Microarray_Status'}          = 'Unused';
    my @numbers;
    for my $counter ( 1 .. $num_in_batch ) { push @numbers, $counter }
    $grey{'Microarray_Number'} = \@numbers;
    if ( $num_in_batch == 1 ) { $grey{'Microarray_Number'} = 1 }
    my %omit;
    $omit{'FK_Stock__ID'}      = 1;
    $omit{'Used_DateTime'}     = '';
    $omit{'FK_Microarray__ID'} = 1;

    ## Creating the form
    my @target_fields = $dbc->get_field_list( -table => 'Microarray', -qualify => 1 );
    push @target_fields, $dbc->get_field_list( -table => 'Genechip', -qualify => 1 );
    my %autofill_hash = map { $_ => 1 } @target_fields;    #make it into a hash

    my $table = &SDB::HTML::query_form(
        -dbc    => $dbc,
        -fields => \@target_fields,

        #-table    => 'Microarray',
        -action    => 'append',
        -grey      => \%grey,
        -condition => \%condition,
        -omit      => \%omit,
        -autofill  => \%autofill_hash,
        -button    => { 'rm' => 'Save Info' },
        -repeat    => $num_in_batch - 1
    );

    my $page
        = Views::sub_Heading( "Adding Microarray Information", 1 )
        . alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Microarray_Form' )
        . $table
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Stock_App', -force => 1 )
        . $q->hidden( -name => 'Stock type',      -value => $type,                -force => 1 )
        . $q->hidden( -name => 'Stock Sub Type',  -value => 'Genechip',           -force => 1 )
        . $q->hidden( -name => 'Catalog ID',      -value => $catalog_id,          -force => 1 )
        . $hidden_info
        . $q->end_form();
    return $page;
}

###########################
sub new_reagent_page {
###########################
    #   - Description
    #           Creates a query form for Reagents, Solutions, Primers ,...
###########################
    my $self       = shift;
    my $q          = $self->query;
    my $dbc        = $self->param('dbc');
    my $catalog_id = $q->param('catalog id');
    my $type       = $q->param('stock type');

    ## getting the parameters from last table
    ( my $fields, my $values ) = alDente::Form::get_form_input( -table => 'Stock', -object => $self, -dbc => $dbc );
    my $hidden_info = alDente::Form::get_form_input( -table => 'Stock', -object => $self, -HTML_on => 1, -dbc => $dbc );
    my $num_in_batch = _return_value( -fields => $fields, -values => $values, -target => 'Stock_Number_in_Batch' );
    ( my $quantity ) = $dbc->Table_find( 'Stock_Catalog', 'Stock_Size', "Where Stock_Catalog_ID = $catalog_id" );

    ## Setting defaults and set lists
    #   my @TBD_racks = $dbc->get_FK_info_list( -field => 'WHERE FK_Rack__ID', -condition => "Rack_Alias LIKE '%TBD%' AND FKParent_Rack__ID = 0" );
    my $racks          = $self->_get_rack_list( -dbc      => $dbc );
    my $rack_condition = $self->_get_rack_condition( -dbc => $dbc );
    my %list;
    $list{'FK_Rack__ID'} = $racks;
    my %condition;
    $condition{'FK_Rack__ID'} = $rack_condition;
    my %grey;
    $grey{'Solution_Number_in_Batch'} = $num_in_batch;
    $grey{'Solution_Type'}            = $type;
    $grey{'Solution_Status'}          = 'Unopened';
    $grey{'Solution_Quantity'}        = $quantity;
    my %omit;
    $omit{'FK_Stock__ID'}         = 1;
    $omit{'FK_Solution_Info__ID'} = '';
    $omit{'Quantity_Used'}        = '0';
    $omit{'Solution_Started'}     = '';
    $omit{'Solution_Finished'}    = '';
    $omit{'Solution_Notes'}       = '';

    my @numbers;
    for my $counter ( 1 .. $num_in_batch ) { push @numbers, $counter }
    $grey{'Solution_Number'} = \@numbers;
    if ( $num_in_batch == 1 ) { $grey{'Solution_Number'} = 1 }
    ##  Creating the query form
    my $info_table;
    my @info_target_fields;
    if ( $type eq 'Primer' ) {
        @info_target_fields = qw(Solution_Info.nMoles Solution_Info.micrograms Solution_Info.ODs );
    }

    my @target_fields = $dbc->get_field_list( -table => 'Solution', -qualify => 1 );
    push @target_fields, @info_target_fields;

    my @autofill_fields = @target_fields;
    my %autofill_hash = map { $_ => 1 } @autofill_fields;    #make it into a hash

    my $table = &SDB::HTML::query_form(
        -dbc       => $dbc,
        -fields    => \@target_fields,
        -action    => 'append',
        -grey      => \%grey,
        -condition => \%condition,
        -omit      => \%omit,
        -autofill  => \%autofill_hash,
        -button    => { 'rm' => 'Save Info' },
        -repeat    => $num_in_batch - 1
    );

    ## Creating the full page
    my $page
        = Views::sub_Heading( "Adding Reagent / Solution Information", 1 )
        . alDente::Form::start_alDente_form( $dbc, 'Box Form' )
        . $info_table
        . $table
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Stock_App', -force => 1 )
        . $q->hidden( -name => 'Stock type',      -value => $type,                -force => 1 )
        . $q->hidden( -name => 'Catalog ID',      -value => $catalog_id,          -force => 1 )
        . $hidden_info
        . $q->end_form();

    return $page;

}

###########################
sub new_equipment_page {
###########################
    #   - Description
    #           Creates a query form for Equipment
###########################
    my $self       = shift;
    my $q          = $self->query;
    my $dbc        = $self->param('dbc');
    my $catalog_id = $q->param('catalog id');
    my $type       = $q->param('stock type');
    my $cat_ID     = $q->param('category ID');    ##category id
    ## getting the parameters
    ( my $fields, my $values ) = alDente::Form::get_form_input( -table => 'Stock', -object => $self, -dbc => $dbc );
    my $hidden_info = alDente::Form::get_form_input( -table => 'Stock', -object => $self, -HTML_on => 1, -dbc => $dbc );
    my $num_in_batch = _return_value( -fields => $fields, -values => $values, -target => 'Stock_Number_in_Batch' );
    my $repeat       = $num_in_batch - 1;
    my @vendors      = $dbc->get_FK_info_list( 'FK_Organization__ID', " Organization_Type IN ('Manufacturer','Vendor')" );
    my %list;
    $list{'FK_Organization__ID'} = \@vendors;
    my %grey;
    $grey{'Equipment_Status'}          = 'In Use';
    $grey{'FK_Equipment_Category__ID'} = $cat_ID;
    my %omit;
    $omit{'FK_Stock__ID'} = 1;

    ##  creating a list of names
    my @name_list;
    for my $counter ( 0 .. $repeat ) {
        my ( $prefix, $index ) = _get_equipment_name( -category_id => $cat_ID, -dbc => $dbc );
        push @name_list, $prefix . "-" . ( $index + $counter );
    }
    if   ($repeat) { $grey{'Equipment_Name'} = \@name_list }
    else           { $grey{'Equipment_Name'} = @name_list[0] }

    ##  creating the quesry form
    my @target_fields = qw( Equipment.Equipment_Name
        Equipment.FK_Location__ID
        Equipment.Serial_Number
        Equipment.Equipment_Comments
        Equipment.Equipment_Status);

    my %autofill_hash = map { $_ => 1 } @target_fields;    #make it into a hash

    my $table = &SDB::HTML::query_form(
        -dbc   => $dbc,
        -table => 'Equipment',

        #	-fields => \@target_fields,
        -action => 'append',
        -grey   => \%grey,
        -omit   => \%omit,

        #   -list   =>  \%list,
        -repeat   => $repeat,
        -autofill => \%autofill_hash,
        -button   => { 'rm' => 'Save Equipment Info' }
    );

    ## Creating the full page
    my $page
        = Views::sub_Heading( "Adding Equipment Information", 1 )
        . alDente::Form::start_alDente_form( $dbc, 'Equipment Form' )
        . $table
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Stock_App', -force => 1 )
        . $q->hidden( -name => 'Stock type',      -value => $type,                -force => 1 )
        . $q->hidden( -name => 'Catalog ID',      -value => $catalog_id,          -force => 1 )
        . $hidden_info
        . $q->end_form();

    return $page;
}

###########################
sub new_category {
##########################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};

    my %preset;
    $preset{Sub_Category} = 'N/A';

    ## creating the table
    my $table = SDB::DB_Form->new( -dbc => $dbc, -table => 'Equipment_Category', -target => 'Database', -wrap => 0 );
    $table->configure( -preset => \%preset );
    my $page .= alDente::Form::start_alDente_form( $dbc, 'Category Form' ) . $self->display_categories( -dbc => $dbc ) . $table->generate( -button => { 'rm' => 'Add Equipment Category' }, -navigator_on => 0, -return_html => 1 ) . $q->end_form();

    return $page;

}

###########################
sub display_categories {
###########################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};

    my @info = $dbc->Table_find( "Equipment_Category", "Category, Sub_Category,Prefix", "WHERE Category <> 'Pipette' order by Category" );
    my $category_table = alDente::Form::init_HTML_table( -title => 'Categories', -width => '40%' );
    $category_table->Set_Row( [ "Category", "Sub Category", "Prefix" ], 'lightblue' );

    my $prev_cat;
    my $number = @info - 1;
    for my $counter ( 0 .. $number ) {

        ( my $cat, my $sub, my $prefix ) = split ',', $info[$counter];
        if ( $cat eq $prev_cat ) {
            $category_table->Set_Row( [ vspace(), $sub, $prefix ] );
        }
        else {
            $category_table->Set_Row( [ "<HR>", "<HR>", "<HR>" ] );
            $category_table->Set_Row( [ $cat, $sub, $prefix ] );
        }
        $prev_cat = $cat;
    }

    my @pipettes = $dbc->Table_find( "Equipment_Category", "Sub_Category", "WHERE Category = 'Pipette' order by Category, Sub_Category" );
    my $pip_HTML = join( '<br>', @pipettes );
    my $pip_table = alDente::Form::init_HTML_table( -title => 'Pipettes' );
    $pip_table->Set_Row( [$pip_HTML] );

    my %view_layer = (
        'Pipettes'        => $pip_table->Printout(0),
        'Other Equipment' => $category_table->Printout(0)
    );
    my $form = "<h2>Category Lookup</H2>"
        . create_tree(
        -tree         => \%view_layer,
        -tab_width    => 100,
        -default_open => 0,
        -print        => 0
        );

    return $form;
}

###########################
sub new_item {
##########################
    my $self          = shift;
    my %args          = &filter_input( \@_ );
    my $dbc           = $self->param('dbc') || $args{-dbc};
    my $box_id        = $args{-box_id};
    my $box_item_type = $args{-box_item_type};

    my $box_link = "&box_id=$box_id" if $box_id;
    $box_link .= "&box_item_type=$box_item_type" if $box_item_type;

    my @types         = qw(Equipment Microarray);           ## Misc_Item
    my @box_types     = qw(Box Kit);
    my @reagent_types = qw(Reagent Primer Matrix Buffer);

    my $form .= "<h2>Adding New Catalog Item (not previously ordered)</H2>" . "Add New:" . vspace() . "<UL>";

    $form .= "<LI> " . &Link_To( $dbc->config('homelink'), "Items Made in House", "&cgi_application=alDente::Stock_App&rm=Catalog+Form&&dbc=$dbc&in_house=1" );

    foreach my $type (@types) {
        $form .= "<LI> " . &Link_To( $dbc->config('homelink'), "$type", "&cgi_application=alDente::Stock_App&rm=Catalog+Form&Stock_Type=$type&dbc=$dbc" . "$box_link" );
    }

    $form .= "<LI>Reagent Types: <UL>";
    foreach my $reagent_type (@reagent_types) {
        my $r_type;
        if   ( $reagent_type =~ /Standard (\S+)/ ) { $r_type = 'Reagent' }
        else                                       { $r_type = $reagent_type }
        $form .= "<LI>" . &Link_To( $dbc->config('homelink'), "$reagent_type", "&cgi_application=alDente::Stock_App&rm=Catalog+Form&Stock_Type=$reagent_type&dbc=$dbc" . "$box_link" );
    }
    $form .= "</UL>" . "<LI>Box Types: <UL>";
    foreach my $box_type (@box_types) {
        $form .= "<LI>" . &Link_To( $dbc->config('homelink'), "$box_type", "&cgi_application=alDente::Stock_App&rm=Catalog+Form&Stock_Type=$box_type&dbc=$dbc" . "$box_link" );
    }
    $form .= "</UL>" . "</UL>";

    return $form;
}

###########################
sub save_category {
###########################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');
    ## getting the parameters entered in the form
    ( my $fields, my $values ) = alDente::Form::get_form_input( -table => 'Equipment_Category', -object => $self, -dbc => $dbc );

    ##saving the information
    my $category_item = alDente::Stock->new( -dbc => $dbc );
    my $category = $category_item->save_category_info( -dbc => $dbc, -fields => $fields, -values => $values );

    my $form = $self->new_category( -dbc => $dbc );

    return $form;

}

###########################
sub save_catalog_info {
###########################
    my $self          = shift;
    my $q             = $self->query;
    my $dbc           = $self->param('dbc');
    my $type          = $q->param('stock type');
    my $made_in_house = $q->param('made in house flag');
    ## getting the parameters entered in the form
    ( my $fields, my $values ) = alDente::Form::get_form_input( -table => 'Stock_Catalog', -object => $self, -dbc => $dbc );

    ##saving the information
    my $catalog_item = alDente::Stock->new( -dbc => $dbc );
    my $stock_catalog_id = $catalog_item->save_catalog_info( -dbc => $dbc, -fields => $fields, -values => $values, -type => $type );
    if ($made_in_house) { return; }
    ## Calling the next page
    my $form = $self->new_stock_page(
        -id  => $stock_catalog_id,
        -dbc => $dbc
    );

    return $form;
}

###########################
sub save_stock_details {
###########################
    my $self       = shift;
    my $q          = $self->query;
    my $dbc        = $self->param('dbc');
    my $catalog_id = $q->param('Catalog ID');
    my $type       = $q->param('Stock type');

    ## getting the parameters entered in the form
    my $category = _get_category($type);
    ( my $fields, my $values ) = alDente::Form::get_form_input( -table => $category, -object => $self, -array_return => 1, -dbc => $dbc );
    ## CONSTRUCTION ##
    my $sub_type = $q->param('Stock Sub Type');
    my $sub_type_fields;
    my $sub_type_values;
    if ($sub_type) {
        ( $sub_type_fields, $sub_type_values ) = alDente::Form::get_form_input( -table => $sub_type, -object => $self, -array_return => 1, -dbc => $dbc );
    }

    ( my $stock_fields, my $stock_values ) = alDente::Form::get_form_input( -table => 'Stock', -object => $self, -dbc => $dbc );
    ( my $primer_fields, my $primer_values ) = alDente::Form::get_form_input( -table => 'Solution_Info', -object => $self, -array_return => 1, -dbc => $dbc );

    ## saving the information
    my $stock_item = alDente::Stock->new( -dbc => $dbc );
    my $id_list = $stock_item->save_stock_info(
        -dbc       => $dbc,
        -type      => $type,
        -category  => $category,
        -sub_type  => $sub_type,
        -fields    => $fields,
        -values    => $values,
        -s_fields  => $stock_fields,
        -s_values  => $stock_values,
        -st_fields => $sub_type_fields,
        -st_values => $sub_type_values,
        -p_fields  => $primer_fields,
        -p_values  => $primer_values
    );

    ## print the barcodes
    $stock_item->print_stock_barcodes( -dbc => $dbc, -category => $category, -id_list => $id_list );

    return alDente::Stock_Views::display_added_stock_items( -dbc => $dbc, -category => $category, -id_list => $id_list );
}

###########################
sub save_equipment_info {
###########################
    my $self       = shift;
    my $q          = $self->query;
    my $dbc        = $self->param('dbc');
    my $catalog_id = $q->param('Catalog ID');
    my $type       = $q->param('Stock type');

## take in info
    ( my $fields, my $values ) = alDente::Form::get_form_input( -table => 'Equipment', -object => $self, -array_return => 1, -dbc => $dbc );
    ( my $stock_fields, my $stock_values ) = alDente::Form::get_form_input( -table => 'Stock', -object => $self, -dbc => $dbc );

    ## saving the information
    my $equipment_item = alDente::Stock->new( -dbc => $dbc );
    my $id_list = $equipment_item->save_equipment(
        -dbc      => $dbc,
        -type     => $type,
        -id       => $catalog_id,
        -fields   => $fields,
        -values   => $values,
        -s_fields => $stock_fields,
        -s_values => $stock_values
    );

    ## print the barcodes
    $equipment_item->print_stock_barcodes( -dbc => $dbc, -category => 'Equipment', -id_list => $id_list );

    return alDente::Stock_Views::display_added_equipment_items( -dbc => $dbc, -category => 'Equipment', -id_list => $id_list );
}

###########################
sub display_stock_used {
###########################
    my $self       = shift;
    my $q          = $self->query;
    my $dbc        = $self->param('dbc');
    my $library    = $q->param('Library_Name');
    my $project_id = $q->param('Project_ID');

    &stock_used( $project_id, $library, 1 );

}

#####################################
# private functions and methods     #
#####################################
##############################
sub _get_previous_grp {
##############################
    my %args             = @_;
    my $stock_catalog_id = $args{-catalog_id};
    my $dbc              = $args{-dbc};
    my @groups           = $dbc->Table_find( 'Stock', 'FK_Grp__ID', "where FK_Stock_Catalog__ID = $stock_catalog_id ", 'distinct' );
    my $size             = @groups;
    if ( $size == 1 ) {
        return $groups[0];
    }
    else {
        return 0;
    }

}

##############################
sub _get_rack_condition {
##############################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc};

    my $groups = $dbc->get_local('group_list');
    my $dept   = $dbc->get_local('home_dept');
    if ( $dept =~ /receiving/i ) {
        ($groups) = $dbc->Table_find( 'Grp', 'Grp_ID', "WHERE Grp_Name = 'Receiving'" );
    }

    my %condition;

    $condition{join_tables}    = 'Equipment,Stock';
    $condition{join_condition} = "FK_Equipment__ID = Equipment_ID and FK_Stock__ID = Stock_ID and FK_Grp__ID IN ($groups)";
    $condition{condition}      = "Rack_Type <> 'Slot'";

    return \%condition;
}

##############################
sub _get_rack_list {
##############################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc};
    my @racks;

    my $groups = $dbc->get_local('group_list');
    my $dept   = $dbc->get_local('home_dept');
    if ( $dept =~ /receiving/i ) {
        ($groups) = $dbc->Table_find( 'Grp', 'Grp_ID', "WHERE Grp_Name = 'Receiving'" );
    }

    my @rack_ids = $dbc->Table_find( 'Rack,Equipment,Stock', 'Rack_ID', "WHERE FK_Equipment__ID = Equipment_ID and FK_Stock__ID = Stock_ID and FK_Grp__ID IN ($groups) AND Rack_Type <> 'Slot' ", 'distinct' );
    my $racks = join ',', @rack_ids;

    my @rack_names = $dbc->get_FK_info_list( -field => 'FK_Rack__ID', -condition => "WHERE Rack_ID IN ($racks) order by Rack_ID" ) if $racks;

    return \@rack_names;
}

##############################
sub _get_barcode_label {
##############################
    my %args             = @_;
    my $stock_catalog_id = $args{-catalog_id};
    my $dbc              = $args{-dbc};
    my ($last_date) = $dbc->Table_find( 'Stock', 'MAX(Stock_Received)', "where FK_Stock_Catalog__ID = $stock_catalog_id" );
    my @labels = $dbc->Table_find( 'Stock', 'FK_Barcode_Label__ID', "where FK_Stock_Catalog__ID = $stock_catalog_id AND Stock_Received = '$last_date'" );
    if ( $labels[0] ) { return $labels[0] }
    return;
}

##############################
sub _convert_table {
##############################

}

##############################
sub _convert_code {
##############################
    my $code = shift;
    if ( $code > 320 && $code < 328 ) {
        if ( $code == 321 ) { return 'In Use' }
        if ( $code == 322 ) { return 'Inactive - Removed' }
        if ( $code == 323 ) { return 'Inactive - Removed' }
        if ( $code == 324 ) { return 'Unknown' }
        if ( $code == 325 ) { return 'Inactive - In Repair' }
        if ( $code == 326 ) { return 'Inactive - Hold' }
        if ( $code == 327 ) { return 'Returned to Vendor (RTV)' }
        return 0;
    }
    elsif ( $code > 150 && $code < 174 ) {

        if ( $code == 151 ) { return 13 }
        if ( $code == 152 ) { return 29 }
        if ( $code == 153 ) { return 2 }
        if ( $code == 154 ) { return 32 }
        if ( $code == 155 ) { return 9 }
        if ( $code == 156 ) { return 36 }
        if ( $code == 157 ) { return 33 }
        if ( $code == 158 ) { return 18 }
        if ( $code == 159 ) { return 41 }
        if ( $code == 160 ) { return 44 }
        if ( $code == 161 ) { return 31 }
        if ( $code == 162 ) { return 40 }
        if ( $code == 163 ) { return 42 }
        if ( $code == 165 ) { return 30 }
        if ( $code == 166 ) { return 43 }
        if ( $code == 167 ) { return 34 }
        if ( $code == 168 ) { return 22 }
        if ( $code == 172 ) { return 44 }
        if ( $code == 173 ) { return 23 }
        return 0;
    }
    elsif ( $code > 340 && $code < 347 ) {
        if ( $code == 341 ) { return 7 }
        if ( $code == 342 ) { return 2 }
        if ( $code == 343 ) { return 1 }
        if ( $code == 344 ) { return 10 }
        if ( $code == 345 ) { return 14 }
        if ( $code == 346 ) { return 0 }
        return 0;
    }
    else {
        Message("not valid code: $code");

        #  print Call_Stack();
    }

}

##########################
sub _get_category {
##########################
    my $type = shift;
    my $category
        = ( $type =~ /(Reagent|Primer|Matrix|Buffer|Solution)/ ) ? 'Solution'
        : ( $type =~ /(Equipment)/ )  ? 'Equipment'
        : ( $type =~ /(Box|Kit)/ )    ? 'Box'
        : ( $type =~ /(Microarray)/ ) ? 'Microarray'
        :                               'Misc_Item';

    return $category;
}

##########################
sub _get_equipment_name {
##########################
    my %args        = &filter_input( \@_ );
    my $dbc         = $args{-dbc};
    my $category_id = $args{-category_id};

    my $command = "Concat(Max(Replace(Equipment_Name,concat(Prefix,'-'),'') + 1)) as Next_Name";
    my ($name) = $dbc->Table_find_array( 'Equipment_Category', -fields => ['Prefix'], -condition => "WHERE Equipment_Category_ID=$category_id" );
    my ($number) = $dbc->Table_find_array( 'Equipment,Equipment_Category,Stock,Stock_Catalog',
        [$command], "WHERE FK_Stock__ID = Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND FK_Equipment_Category__ID=Equipment_Category_ID AND Equipment_Category_ID=$category_id" );
    unless ($number) { $number = 1 }
    return ( $name, $number );
}

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
1;
