################################################################################
#
# Stock.pm
#
# This module handles Miscellaneous Items.
#
################################################################################
################################################################################
# $Id: Stock.pm,v 1.83 2004/12/08 18:00:18 jsantos Exp $
################################################################################
# CVS Revision: $Revision: 1.83 $
#     CVS Date: $Date: 2004/12/08 18:00:18 $
################################################################################
package alDente::Stock;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Stock.pm - This module handles Miscellaneous Items.

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles Miscellaneous Items.<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter SDB::DB_Object);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    original_stock
    save_original_stock
    stock_used
    move_stock
    ReceiveStock
    ReceiveBoxItems
    get_new_Stock
);
@EXPORT_OK = qw();

##############################
# standard_modules_ref       #
##############################

use strict;
use CGI qw(:standard);
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
use alDente::Misc_Item;
use alDente::Solution;
use alDente::Microarray;
use alDente::Equipment;
use alDente::Form;
use alDente::Rack;
use alDente::Barcoding;
use alDente::HelpButtons;
use alDente::Validation;
use alDente::SDB_Defaults;
use alDente::Special_Branches;
use RGTools::Views;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Conversion;
use SDB::DBIO;
use alDente::Validation;
use SDB::DB_Form_Viewer;
use SDB::DB_Object;
use SDB::CustomSettings;
use SDB::Session;
##############################
# global_vars                #
##############################
our ( $scanner_mode, $testing, $homefile, $last_page );
our ( $style, $dbase, $Connection, $barcode, $user );
our ( $plate_id,  $current_plates, $plate_set );
our ( $equipment, $equipment_id,   $solution_id );
our ($errmsg);
our ( @users,       @plate_sizes, @plate_info, @plate_formats );
our ( @s_suppliers, @e_suppliers, @locations,  @libraries );
our ( $nowday,      $nowtime,     $nowDT );
our ( $size, $quadrant, $rack, $format, $button_style );
our ($MenuSearch);
use vars qw($URL_emp_dir);
use vars qw(%Settings %Mandatory_fields %Field_Info $Sess $Security);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
##############################
# constructor                #
##############################
##########
sub new {
##########
    #
    # Constructor of the object
    #
    my $this = shift;

    my %args     = @_;
    my $id       = $args{-id} || $args{-stock_id};
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle
    my $retrieve = $args{-retrieve};                                                                 ## retrieve information right away [0/1]
    my $verbose  = $args{-verbose};

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => [ 'Stock', 'Stock_Catalog' ] );
    my $class = ref($this) || $this;
    bless $self, $class;

    $self->{DBobject} = '';                                                                          ## will be set to Solution / Box / Equipment etc.
    $self->{dbc}      = $dbc;

    if ($id) {
        $self->{id} = $id;
        $self->primary_value( -table => 'Stock', -value => $id );
        $self->load_Object();
    }

    $self->{records} = 0;                                                                            ## number of records currently loaded

    return $self;
}

####################
sub load_Object {
####################
    #
    # load stock object - sets DBobject attribute and loads object depending upon type. (eg Equipment / Solution / Box)
####################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'id' );
    my $id   = $args{-id} || $self->{id};

    my $dbc = $self->{dbc};

    unless ($id) {
        Message("No id supplied");
        return 0;
    }

    my ($type) = $dbc->Table_find( 'Stock,Stock_Catalog', 'Stock_Catalog.Stock_Type', "WHERE Stock_ID = $id AND FK_Stock_Catalog__ID = Stock_Catalog_ID" );

    my $object = $type;
    if ( $type =~ /(Reagent|Solution|Primer|Buffer|Matrix)/ ) {
        $object = "Solution";
    }
    elsif ( $type =~ /(Box|Kit)/ ) {
        $object = "Box";
    }

    $self->add_tables($object);

    $self->SUPER::load_Object(%args);
    $self->set( 'DBobject', $object );

    return;
}

###############
sub home_page {
###############
    my $self = shift;

    unless ( $self->get('DBobject') ) {
        $self->load_Object();
    }

    my $object   = $self->get('DBobject');
    my $stock_id = $self->get_data('Stock_ID');
    my $dbc      = $self->{dbc};

    unless ( $self->get('DBobject') ) {
        Message("No id");
        return 0;
    }

    ## Solution object home page has been moved to the views module
    if ( $object eq 'Solution' ) {
        my $object_model = "alDente::$object";
        my $object       = $object_model->new( -dbc => $dbc, -stock_id => $stock_id, -Stock => $self );
        my $views        = $object_model . '_Views';
        my $object_views = $views->new( -dbc => $dbc, -id => $object->{id}, -Model => $object );
        return $object_views->home_page();
    }
    else {
        my $page = "alDente::$object";
        my $object_page = $page->new( -dbc => $dbc, -stock_id => $stock_id, -Stock => $self );
        $object_page->home_page();
    }

    return 1;
}

##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################
################################  new
sub get_organization_list {
###########################
    #   Takes in type of organization and returns all names that macth in array ref
    #
############################
    my $self      = shift;
    my %args      = @_;
    my $dbc       = $args{-dbc};
    my $type_ref  = $args{-type};              #reference to an array
    my @types     = @$type_ref if $type_ref;
    my $condition = 0;
    unless (@types) { Message('No organization types entered'); return; }
    for my $type (@types) { $condition .= " OR Organization_Type LIKE '\%$type%' " }
    my @organizations = ('');
    push @organizations, $dbc->Table_find( "Organization", 'Organization_Name', "WHERE 1 AND ($condition) order by Organization_Name" );
    return \@organizations;
}

################################  new
sub find_group_list {
###########################
    #   Takes in deaprtment NAME and returns the groups whcih belong to it
    #
############################
    my $self       = shift;
    my %args       = @_;
    my $dbc        = $args{-dbc};
    my $department = $args{-department};
    my @groups;
    if ( $department eq 'All' ) {
        @groups = $dbc->Table_find( "Department, Grp", 'Grp_ID', "WHERE FK_Department__ID = Department_ID" );
    }
    @groups = $dbc->Table_find( "Department, Grp", 'Grp_ID', "WHERE FK_Department__ID = Department_ID AND Department_Name IN ('$department') " );
    my $group_list = join ',', @groups;
    return $group_list;

}

################################  new
sub assign_category {
###########################     NEW
    my $self          = shift;
    my %args          = filter_input( \@_ );
    my $dbc           = $args{-dbc};
    my $catalog_id    = $args{-catalog_id};
    my $category_name = $args{-category};
    my $category_id;

    if ($category_name) {
        ($category_id) = $dbc->get_FK_ID( -field => 'FK_Equipment_Category__ID', -value => $category_name );
    }
    if ($category_id) {
        my @fields = ( 'FK_Equipment_Category__ID', 'Stock_Status' );
        my @values = ( "$category_id", "'Active'" );
        my $ok = $dbc->Table_update_array( -table => 'Stock_Catalog', -fields => \@fields, -values => \@values, -condition => "WHERE Stock_Catalog_ID = $catalog_id" );
        unless ($ok) { Message 'Failed to activate stock catalog record' }

        my @equipment_ids = $dbc->Table_find( 'Equipment,Stock', 'Equipment_ID', "WHERE FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = $catalog_id" );

        for my $equipment_id (@equipment_ids) {
            my ( $prefix, $number ) = _get_equipment_name( -dbc => $dbc, -category_id => $category_id );
            my $equipment_name   = $prefix . '-' . $number;
            my @equipment_fields = ( 'Equipment_Status', 'Equipment_Name' );
            my @equipment_values = ( 'In Use', $equipment_name );

            $ok = $dbc->Table_update_array( -table => 'Equipment', -fields => \@equipment_fields, -values => \@equipment_values, -condition => "WHERE Equipment_ID = $equipment_id", -autoquote => 1 );

            #            Message $equipment_name;
            unless ($ok) { Message 'Failed to activate equipment' }

            Message "Activated equipment: EQU$equipment_id";
            return $ok;
        }

    }

    return;

}

################################  new
sub activate_catalog_item {
###########################     NEW
    my $self       = shift;
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $catalog_id = $args{-catalog_id};
    my $category_id;

    my @fields = ('Stock_Status');
    my @values = ("'Active'");
    my $ok     = $dbc->Table_update_array( -table => 'Stock_Catalog', -fields => \@fields, -values => \@values, -condition => "WHERE Stock_Catalog_ID = $catalog_id" );
    unless ($ok) { Message 'Failed attempt' }
    return $ok;
}

###########################     Revised
sub find_Stock {
###########################
    #
    # Status for Solutions in database...
    #
    # <CONSTRUCTION> - adjust to work as rm. should probably be separated into search method (Stock.pm) and display method (in Stock_Views.pm)
    #
###########################
    my $self        = shift;
    my %args        = &filter_input( \@_, -args => 'dbc,search,group' );
    my $dbc         = $args{-dbc};
    my $search_num  = convert_to_regexp( $args{-cat_num} );
    my $search_name = convert_to_regexp( $args{-cat_name} );
    my $grp         = $args{-group};
    my $condition   = $args{-condition};
    my $title       = $args{-title} || "Status for Solutions (containing '$search_name ($search_num)')";
    my $type        = $args{-type};
    my $search_by   = $args{-search_by} || 'cat';                                                          ## name or catalog
    my $debug       = $args{-debug};
    my $org_name    = $args{-org_name};
    my $source      = $args{-source};
    my $org_id      = $dbc->get_FK_ID( 'Organization_ID', $org_name ) if $org_name;

    unless ($search_name) {
        Message 'No name entered, defaulting to everything';
    }

    my $grp_condition;
    $grp_condition .= $condition                                                                                                        if $condition;
    $grp_condition .= " AND (Stock_Catalog.FK_Organization__ID IN ($org_id) OR Stock_Catalog.FKVendor_Organization__ID IN ($org_id) ) " if $org_id;
    $grp_condition .= " AND Stock_Catalog.Stock_Source IN ('$source') "                                                                 if $source;

    if ( $grp eq '--All--' ) {
    }    ## no extra group condition ##
    elsif ($grp) {
        my $parent_groups = alDente::Grp::get_parent_groups($grp);
        $grp .= ",$parent_groups" if $parent_groups;
        $grp_condition .= " AND FK_Grp__ID in ($grp)";
    }

    my $SQL_label
        = "CASE WHEN Stock_Catalog.Stock_Catalog_Number IS NOT NULL THEN concat(Stock_Catalog_Name,' - ',Stock_Catalog.Stock_Catalog_Number,' (',Stock_Catalog.Stock_Size,Stock_Catalog.Stock_Size_Units,')') ELSE concat(Stock_Catalog_Name,' (',Stock_Catalog.Stock_Size,Stock_Catalog.Stock_Size_Units,')') END";
    my @fields   = ( 'Stock_Catalog_Name', 'Stock_Catalog.Stock_Catalog_Number as Cat', 'count(*) as Count', 'Stock_Catalog.Stock_Size', 'Max(Stock_Catalog.Stock_Size_Units) as Units', "$SQL_label as Label" );
    my $group_by = "Stock_Catalog_Name,Stock_Catalog.Stock_Catalog_Number,Stock_Catalog.Stock_Size,Stock_Catalog.Stock_Size_Units,Status";
    my $order_by = "Stock_Catalog_Name,Stock_Catalog.Stock_Catalog_Number,Stock_Catalog.Stock_Size,Stock_Catalog.Stock_Size_Units,Status";

    if ( $type =~ /(Solution|Reagent)/i ) {
        push @fields, 'Solution_Status as Status';
        $type = 'Solution';
    }
    elsif ( $type =~ /(Box|Kit)/i ) {
        push @fields, "CASE WHEN Box_Opened > '000-00-00' THEN 'Opened' Else 'Unopened' END as Status";
        $type = 'Box';
    }
    else {
        Message("Currently not supporting $type searching ?");
    }

    my $string_condition = " AND Stock_Catalog.Stock_Catalog_Number like '$search_num' " if $search_num;
    $string_condition .= " AND Stock_Catalog_Name like '$search_name' " if $search_name;

    my %Stock_Info = $dbc->Table_retrieve(
        "$type, Stock, Stock_Catalog",
        \@fields,
        "where FK_Stock__ID=Stock_ID AND Stock.FK_Stock_Catalog__ID = Stock_Catalog_ID" . " $string_condition" . " $grp_condition group by $group_by" . " Order by $order_by",
        -debug => $debug
    );

    return \%Stock_Info;
}

############################`   Revised
sub get_Stock_details {
############################
    #
    # allow users to observe details for solutions
    # (allows multiple 'Empty', 'Open', or 'Unopen'
    #
    # <CONSTRUCTION> - adjust to work as rm. should probably be separated into search method (Stock.pm) and display method (in Stock_Views.pm)
    #
###########################
    my $self             = shift;
    my %args             = @_;
    my $dbc              = $args{-dbc};
    my $type             = $args{-type};
    my $s_name           = $args{-name} || '%';
    my $cat              = $args{-cat} || '%';
    my $include_finished = $args{-include_finished} || 0;
    my $s_size           = Extract_Values( [ $args{'Size'}, '' ] );
    my $label            = $args{-label};
    my $grp              = $args{-grp} || param('Search Group');
    my $search           = $args{-search} || param('Search String');    # maintain search string..

    my $grp_condition = '';
    if ( $grp eq '--All--' ) {
    }                                                                   ## no extra group condition ##
    elsif ($grp) {
        my $parent_groups = alDente::Grp::get_parent_groups($grp);
        $grp .= ",$parent_groups" if $parent_groups;
        $grp_condition = " AND FK_Grp__ID in ($grp)";
    }

    unless ( $s_name || $cat ) {
        Message("I need at least a name or catalog number");
        return 0;
    }

    my $SQL_label
        = "CASE WHEN Stock_Catalog.Stock_Catalog_Number IS NOT NULL THEN concat(UPPER(Stock_Catalog_Name),' - ',Stock_Catalog.Stock_Catalog_Number,' (',Stock_Catalog.Stock_Size,UPPER(Stock_Catalog.Stock_Size_Units),')') ELSE concat(UPPER(Stock_Catalog_Name),' (',Stock_Catalog.Stock_Size,UPPER(Stock_Catalog.Stock_Size_Units),')') END";

    my $extra_condition;
    if ($label) {
        $extra_condition .= " AND $SQL_label like UPPER('$label')";
    }
    else {
        if ($s_name) {
            $extra_condition .= " AND Stock_Catalog_Name like '$s_name'";
        }
        if ($cat) {
            $extra_condition .= " AND Stock_Catalog.Stock_Catalog_Number like '$cat'";
        }
    }

    my @fields = ( 'Stock_Catalog.Stock_Size_Units', 'Stock_Catalog.Stock_Size', 'Rack_ID', "$SQL_label as Label", 'Stock_Catalog_Name', 'Rack_Alias', $type . '_ID as ID', $type . '_Number as Number', $type . '_Number_in_Batch as Number_in_Batch', );

    if ( $type =~ /(solution|reagent)/i ) {
        $type = 'Solution';
        push @fields, ( 'Quantity_Used', 'Solution_Started as Started', 'Solution_Finished as Finished', 'Solution_Status as Status' );
    }
    elsif ( $type =~ /(box|Kit)/i ) {
        $type = 'Box';
        push @fields, ( "'N/A' as Quantity_Used", 'Box_Opened as Started', " 'N/A' as Finished", "CASE WHEN Box_Opened > '0000-00-00' THEN 'Opened' ELSE 'Unopened' END as Status" );
    }

    unless ($include_finished) {
        $extra_condition .= " AND Rack_Alias NOT like 'Garbage%'";
    }

    my %info = $dbc->Table_retrieve( "Equipment,Stock,Stock_Catalog, $type left join Rack on $type.FK_Rack__ID = Rack_ID",
        \@fields,, "WHERE Rack.FK_Equipment__ID=Equipment_ID AND Stock.FK_Stock_Catalog__ID=Stock_Catalog_ID" . " AND $type.FK_Stock__ID=Stock_ID" . " $extra_condition $grp_condition" );

    $dbc->Benchmark('retrieved');

    return \%info;

}

################################  new
sub get_type_matched_ids {
#####################
    #
    #   Takes in id list and a type then only returns ids taht match the type
    #
#################################

    my %args        = filter_input( \@_ );
    my $dbc         = $args{-dbc};
    my $type        = $args{-type};
    my $ids         = $args{-ids};
    my $matched_ids = join ',', $dbc->Table_find( 'Stock_Catalog', 'Stock_Catalog_ID', "WHERE Stock_Catalog_ID IN ($ids) AND Stock_Type = '$type'" );

}

################################  new
sub get_new_Stock {
#################
    # Prompt for new Stock Item (no current sample available)
    #
    #
################################
    my $dbc = shift;

    print "<h2>Adding New Stock Item (not previously ordered)</H2>";
    print "Add New: <P><UL>";

    my @types = ( 'Equipment', 'Box', 'Microarray' );
    my @reagent_types = ( 'Standard Reagent', 'Primer', 'Matrix', 'Buffer' );

    foreach my $type (@types) {
        print "<LI> " . &Link_To( $dbc->config('homelink'), "$type", "&New+Stock=$type" );
    }

    print "<LI>Reagents: <UL>";
    foreach my $reagent_type (@reagent_types) {

        my $r_type;
        if   ( $reagent_type =~ /Standard (\S+)/ ) { $r_type = $1; }
        else                                       { $r_type = $reagent_type; }

        print "<LI>" . &Link_To( $dbc->config('homelink'), "$reagent_type", "&New+Stock=New+Reagent&Solution_Type=$r_type" );
    }

    print "</UL>";
    print "</UL>";

    return;
}

################################  new
sub get_catalog_ids {
#######################
    #	Description:
    #		_ This function takes in a search string which could be full or partial catalog name or number and searches in Stock tables
    #			in database and returns matching catalog numbers
    #	Input:
    #		- dbc
    #		- catalog number
    #		- catalog name
    #	Output:
    #		- a reference to an array of catalog numbers (empty if no match found)
    #	Usage Example:
    #		$numbers =	$object -> get_catalog_numbers (	-dbc 	=> $dbc,
    #														-cat 	=> $cat,
    #														-name	=> $name);
#######################
    my $self              = shift;
    my %args              = filter_input( \@_ );
    my $dbc               = $args{-dbc};
    my $number            = $args{-cat};                                 ### catalog number entered (normal input for new stock) - presets most fields on form
    my $name              = $args{-name};                                ### stock name (normal input for new stock) - presets most fields on form
    my $stock_types_ref   = $args{-types};
    my $stock_sources_ref = $args{-sources};
    my $organization      = $args{-org};
    my $vendor            = $args{-vendor};
    my $category_ID       = $args{-Category_ID};
    my $category_name     = $args{-category};
    my $groups            = $args{-groups};
    my $other_condition   = $args{-dcondition};
    my $table             = $args{-table} || 'Stock_Catalog';
    my @stock_types       = @$stock_types_ref if $stock_types_ref;
    my @stock_sources     = @$stock_sources_ref if $stock_sources_ref;
    my $box_id            = $args{-box_id};
    my $box_item_type     = $args{-box_item_type};

    my @list;
    if ($category_name) {
        $category_name =~ /(.*)\s\-\s(.*)/;
        my $category_first = $1;
        my $sub_category   = $2;
        ($category_ID) = $dbc->Table_find( "Equipment_Category", "Equipment_Category_ID", "WHERE Category = '$category_first' and Sub_Category = '$sub_category'" );
    }

    my $search_condition = "WHERE 1  ";

    if ($number) {
        if ( $number =~ /\*/ ) {
            $number =~ s/\*/\%/g;
            $search_condition .= "AND Stock_Catalog.Stock_Catalog_Number like '$number' ";
        }
        else { $search_condition .= "AND Stock_Catalog.Stock_Catalog_Number = '$number'  " }
    }
    elsif ($name) {
        if ( $name =~ /\*/ ) {
            $name =~ s/\*/\%/g;
            $search_condition .= "AND Stock_Catalog_Name like '$name' ";
        }
        else { $search_condition .= "AND Stock_Catalog_Name = '$name' " }
    }

    if (@stock_types) {
        my $stock_types_sting = join( "', '", @stock_types );
        $search_condition .= "AND Stock_Catalog.Stock_Type IN ('$stock_types_sting') ";
    }
    if (@stock_sources) {
        my $stock_source_string = join( "', '", @stock_sources );
        $search_condition .= " AND Stock_Catalog.Stock_Source IN ('$stock_source_string') ";
    }
    if ($organization) {
        my $org_ID = join ',', $dbc->Table_find( -table => 'Organization', -fields => "Organization_ID", -condition => "WHERE Organization_Name IN ('$organization')" );
        $search_condition .= " AND Stock_Catalog.FK_Organization__ID IN ($org_ID)";
    }
    if ($vendor) {
        my $ven_ID = join ',', $dbc->Table_find( -table => 'Organization', -fields => "Organization_ID", -condition => "WHERE Organization_Name IN ('$vendor')" );
        $search_condition .= " AND Stock_Catalog.FKVendor_Organization__ID IN ($ven_ID)";
    }

    if ($category_ID) {
        $search_condition .= " AND FK_Equipment_Category__ID IN ($category_ID)";
    }
    if ($groups) {
        $search_condition .= " AND FK_Grp__ID IN ($groups)";
    }

    if ($box_id) {
        $search_condition .= " AND Stock_Source = 'Box' ";
        if ($box_item_type) {
            $search_condition .= " AND Stock_Type = '$box_item_type' ";
        }
    }
    else {
        $search_condition .= " AND Stock_Source = 'Order' ";
    }

    $search_condition .= " AND Stock_Source <> 'Made in House' ";

    #   Message "select Stock_Catalog_ID from $table $search_condition ";
    $search_condition .= $other_condition;
    @list = $dbc->Table_find(
        -table     => $table,
        -fields    => "Stock_Catalog_ID",
        -condition => "$search_condition " . " ORDER BY Stock_Status,Stock_Catalog_Name"
    );

    return \@list;
}

################################  new
sub save_catalog_info {
################################
    #
    #
    #
################################
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $type   = $args{-type};
    my $fields = $args{-fields};
    my $values = $args{ -values };

    my $condition       = "WHERE 1 ";
    my @fields          = @$fields if $fields;
    my @values          = @$values if $values;
    my @deciding_fields = ( 'Stock_Catalog_Name', 'Stock_Catalog_Number', 'FK_Organization__ID', 'Stock_Size', 'Stock_Size_Units', 'FK_Equipment_Category__ID', 'Stock_Source', 'FKVendor_Organization__ID' );

    for my $index ( 0 .. int @fields ) {
        if ( $values[$index] && grep {/$fields[$index]/} @deciding_fields ) {
            $condition .= " AND $fields[$index]='$values[$index]'";
        }
    }

    ( my $info ) = $dbc->Table_find_array( -table => 'Stock_Catalog', -fields => ['Stock_Catalog_ID'], -condition => $condition );

    ## saving parameters to databse
    if ($info) {
        Message("Item already exist in catalog.  No record added to Catalog");
        return $info;
    }

    my $stock_catalog_id = $dbc->Table_append_array( 'Stock_Catalog', $fields, $values, -autoquote => 1 );
    Message("Record added to catalog");
    return $stock_catalog_id;
}

################################  new
sub save_category_info {
################################
    #
    #
    #
################################
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $fields = $args{-fields};
    my $values = $args{ -values };

    ## checking to avoid duplicate entires - building the condition
    my $condition = "WHERE 1 ";
    my $cat = _return_value( -fields => $fields, -values => $values, -target => 'Category' );
    $condition .= " AND Category ='$cat'" if $cat;
    my $sub = _return_value( -fields => $fields, -values => $values, -target => 'Sub_Category' );
    $condition .= " AND Sub_Category ='$sub'" if $sub;

    ( my $info ) = $dbc->Table_find_array( -table => 'Equipment_Category', -fields => ['Category'], -condition => $condition );

    ## saving parameters to databse
    if ($info) {
        Message("Item already exist in catalog.  No record added to Catalog");
        return $info;
    }

    my $category_id = $dbc->Table_append_array( 'Equipment_Category', $fields, $values, -autoquote => 1 );
    Message("Added a new category $cat - $sub to the table, id = $category_id");
    return $category_id;
}

################################  new
sub save_stock_info {
################################
    #	Description:
    #		_ This function saves information to Stock and on other Table from list (Solution, Microarray, Box,Misc_Item, Solution_Info)
    #	Input:
    #		- dbc
    #		- Stock Type
    #		- Stock Catalog ID
    #       - all the fields and values of stock and the other table
    #       - category (which decides teh table to which info will be appended)
    #	Output:
    #		- a string of stock id's added seperated by ',' or 0 if it fails
    #	Usage Example:
    #       my $id_list = $stock_item -> save_stock_info( -dbc =>$dbc ,               -type       => $type,           -category   => $category,
    #                                                     -fields => $fields,         -values     => $values,
    #                                                     -s_fields => $stock_fields, -s_values   => $stock_values,
    #                                                     -p_fields =>$primer_fields, -p_values   => $primer_values );
################################
    my $self            = shift;
    my %args            = &filter_input( \@_ );
    my $dbc             = $args{-dbc} || $self->param('dbc');
    my $type            = $args{-type};
    my $category        = $args{-category};
    my $fields          = $args{-fields};
    my $values          = $args{ -values };
    my $stock_fields    = $args{-s_fields};
    my $stock_values    = $args{-s_values};
    my $sub_type        = $args{-sub_type};
    my $sub_type_fields = $args{-st_fields};
    my $sub_type_values = $args{-st_values};
    my $primer_fields   = $args{-p_fields};
    my $primer_values   = $args{-p_values};

    my $number = _return_value( -fields => $stock_fields, -values => $stock_values, -target => 'Stock_Number_in_Batch' ) - 1;
    my $ok = 1;
    my $primer_id;
    my @primer_id_array;
    my @id_array;
    ##  starting the transaction (to avoid writing information partially)
    $dbc->start_trans( -name => 'Saving_Info' );
    my @temp_values = @$values;
    my $primer_id_index = _return_value( -fields => $fields, -values => $values, -index_return => 1, -target => 'FK_Solution_Info__ID' );

    ## 'Solution_Info' table only for primers
    if ( $type eq 'Primer' ) {
        my @primer_values_array = @$primer_values;
        my @primer_fields_array = @$primer_fields;
        for my $counter ( 0 .. $number ) {
            my @primer_output;
            my $field_counter = 0;
            foreach my $temp_field (@primer_fields_array) {
                $primer_output[$field_counter] = $primer_values_array[$field_counter][0][$counter];
                $field_counter++;
            }
            $primer_id = $dbc->Table_append_array( 'Solution_Info', $primer_fields, \@primer_output, -autoquote => 1 );
            push @primer_id_array, $primer_id;
            $temp_values[$primer_id_index][0][$counter] = $primer_id;

            unless ($primer_id) { $ok = 0 }
        }
    }

    ## 'Stock' table
    my $stock_id = $dbc->Table_append_array( 'Stock', $stock_fields, $stock_values, -autoquote => 1 );
    unless ($stock_id) { $ok = 0 }

    ## Box/Solution/Microarray/Misc_item Tables
    my $id_index     = _return_value( -fields => $fields, -values => $values, -index_return => 1, -target => 'FK_Stock__ID' );          ## these functions return the index of their desired fields
    my $number_index = _return_value( -fields => $fields, -values => $values, -index_return => 1, -target => $category . '_Number' );
    $temp_values[$id_index][0][0] = $stock_id;

    for my $counter ( 0 .. $number ) {
        my @output_values;
        my $field_counter = 0;
        foreach my $temp_field (@$fields) {
            if   ( exists $temp_values[$field_counter][0][$counter] ) { $output_values[$field_counter] = $temp_values[$field_counter][0][$counter] }
            else                                                      { $output_values[$field_counter] = $temp_values[$field_counter][0][0] }
            if ($number_index) { $output_values[$number_index] = $counter + 1 }
            $field_counter++;
        }
        my $type_id = $dbc->Table_append_array( $category, $fields, \@output_values, -autoquote => 1 );

        if ($sub_type) {
            my @st_values;
            my $st_field_counter = 0;

            foreach my $sub_type_field (@$sub_type_fields) {
                my @foreign_keys = &get_fields( $dbc, $sub_type, -like => "FK%$type%" );
                my $fk = $foreign_keys[0];
                if ( $fk =~ /(.*)\.(.*) AS .*/g ) {
                    $fk = $2;
                }
                if ( $fk eq $sub_type_field ) {
                    $st_values[$st_field_counter] = $type_id;
                }
                elsif ( exists $sub_type_values->[$st_field_counter][0][$counter] ) { $st_values[$st_field_counter] = $sub_type_values->[$st_field_counter][0][$counter] }
                else                                                                { $st_values[$st_field_counter] = $sub_type_values->[$st_field_counter][0][0] }
                $st_field_counter++;
            }
            my $sub_type_id = $dbc->Table_append_array( $sub_type, $sub_type_fields, \@st_values, -autoquote => 1 );
        }

        if ($type_id) { push @id_array, $type_id; }
        else          { $ok = 0; }
    }

    ## All tables have been filled now, time to make sure there was no errors
    if ($ok) {
        $dbc->finish_trans('Saving_Info');
        Message('Records successfully added');
    }
    else {
        $dbc->rollback_trans( 'Saving_Info', -error => "problem adding info" );
        return 0;
    }

    my $id_list = join( ', ', @id_array );
    return $id_list;
}

################################ new
sub print_stock_barcodes {
################################
    #   Description:
    #       - a function to print the barcodes of stock
################################
    my $self     = shift;
    my %args     = @_;
    my $dbc      = $args{-dbc};
    my $category = $args{-category};
    my $list     = $args{-id_list};
    my $option   = $args{-option};
    $list =~ s/ //g;
    alDente::Barcoding::PrintBarcode( $dbc, $category, $list, $option );
    return;
}

################################ new
sub save_equipment {
################################
    #	Description:
    #		_ This function saves information to Stock and Equipment Table
    #	Input:
    #		- dbc
    #		- Stock Type
    #		- Stock Catalog ID
    #       - all the fields and values of stock and Equipment tables
    #	Output:
    #		- a string of stock id's added seperated by ',' or 0 if it fails
    #	Usage Example:
    #           my $id_list = $equipment_item -> save_equipment( -dbc =>$dbc , -type  => $type, -id  => $catalog_id,
    #                                                            -fields => $fields, -values => $values, -s_fields => $stock_fields, -s_values => $stock_values );
################################
    my $self         = shift;
    my %args         = &filter_input( \@_ );
    my $dbc          = $args{-dbc} || $self->param('dbc');
    my $type         = $args{-type};
    my $cat_id       = $args{-id};
    my $fields       = $args{-fields};
    my $values       = $args{ -values };
    my $stock_fields = $args{-s_fields};
    my $stock_values = $args{-s_values};
    my $number       = _return_value( -fields => $stock_fields, -values => $stock_values, -target => 'Stock_Number_in_Batch' ) - 1;
    my $ok           = 1;
    my $id_list;
    my @id_array;
    my $equipment_id;

    ##  starting the transaction (to avoid writing information partially)
    $dbc->start_trans( -name => 'Saving_Equipment_Info' );

    ## 'Stock' Table
    my $stock_id = $dbc->Table_append_array( 'Stock', $stock_fields, $stock_values, -autoquote => 1 );
    unless ($stock_id) { $ok = 0 }

    my $id_index = _return_value( -fields => $fields, -values => $values, -index_return => 1, -target => 'FK_Stock__ID' );

    ##  'Equipment' Table
    my @temp_values = @$values;
    $temp_values[$id_index][0][0] = $stock_id;

    for my $counter ( 0 .. $number ) {
        my @output_values;
        my $field_counter = 0;
        foreach my $temp_field (@$fields) {
            if ( exists $temp_values[$field_counter][0][$counter] ) {
                $output_values[$field_counter] = $temp_values[$field_counter][0][$counter];
            }
            else {
                $output_values[$field_counter] = $temp_values[$field_counter][0][0];
            }
            $field_counter++;
        }
        $equipment_id = $dbc->Table_append_array( 'Equipment', $fields, \@output_values, -autoquote => 1 );
        if ($equipment_id) { push @id_array, $equipment_id; }
    }

    ### cheking transaction
    if ($ok) {
        $dbc->finish_trans('Saving_Equipment_Info');
        Message('Items were added to database successfully');

        # 		return 1;
    }
    else {
        $dbc->rollback_trans( 'Saving_Equipment_Info', -error => "problem adding info" );

        # 		return 0;
    }
    $id_list = join( ', ', @id_array );
    return $id_list;
}

#############################################################################
#
# Older Modules need to be revised and reviewd#
#
#############################################################################

################################
sub stock_used {
#####################

    my $proj     = shift;
    my $library  = shift;
    my $reagents = shift;         ### also show reagents (slower)
    my $dbc      = $Connection;

    my @lib_list = split ',', $library;
    my $grouping = ',Plate_Status,Failed,Plate_Test_Status';
    my $libs;

    my $libraries = $library;
    if ($library) {
        $libs = join ',', map { $dbc->dbh()->quote($_) } @lib_list;
        $grouping = ",FK_Library__Name";
        ($proj) = $dbc->Table_find( 'Project,Library', 'Project_Name', "WHERE FK_Project__ID=Project_ID" . " and Library_Name in ($libs)" );
    }
    elsif ($proj) {

        my $proj_id_spec;    ### allow input of project id only...
        if ( $proj =~ /^\d+$/ ) {
            $proj_id_spec = "OR Project_ID = $proj";
        }

        $libs = join ',', map { $dbc->dbh()->quote($_) } $dbc->Table_find( 'Library,Project', 'Library_Name', "WHERE FK_Project__ID=Project_ID" . " AND (Project_Name like '$proj' $proj_id_spec)" );
        $libraries = "All Libraries in Project: $proj";
    }
    else {
        $libs      = join ',', map { $dbc->dbh()->quote($_) } $dbc->Table_find( 'Library', 'Library_Name' );
        $libraries = "All Libraries";
        $proj      = "(ALL)";
    }

    print &Views::Heading("PROJECT: $proj");
    print &Views::Heading("LIBRARY: $libs");
    print "<font size='small'>Note: Only including solutions with well-defined units</font><BR>";

    my %Plate_Info;
    my @solution_info;
    if ($libs) {
        %Plate_Info = &Table_retrieve(
            $dbc, 'Plate,Plate_Format',
            [ "count(*) as Number", "Plate_Format_Type as Format", "Plate_Status as Status", "Failed", "Plate_Test_Status as Test_Status" ],
            "WHERE FK_Plate_Format__ID=Plate_Format_ID" . " AND FK_Library__Name in ($libs)" . " GROUP BY Plate_Format_Type $grouping"
        );

        my $plate_ids = join ',', $dbc->Table_find( 'Plate', 'Plate_ID', "WHERE FK_Library__Name in ($libs)" );

        if ($plate_ids) {
            my @plate_sets = $dbc->Table_find( 'Plate_Set', 'Plate_Set_Number', "WHERE FK_Plate__ID in ($plate_ids)", 'distinct' );

            my $sets = join ',', @plate_sets;

            if ($sets) {
                @solution_info = $dbc->Table_find(
                    'Prep,Plate_Prep,Solution,Stock,Stock_Catalog',
                    "Plate_Prep.FK_Solution__ID,Plate_Prep.Solution_Quantity," . "FK_Plate_Set__Number,FK_Plate__ID,Stock_Catalog_Name,Prep_ID",
                    "WHERE Plate_Prep.FK_Solution__ID=Solution_ID" . " AND FK_Stock_Catalog__ID = Stock_Catalog_ID " . " AND FK_Stock__ID=Stock_ID" . " AND Plate_Prep.FK_Prep__ID=Prep_ID" . " AND Plate_Prep.FK_Plate__ID in ($plate_ids)"
                );
            }
            else {
                print "No Plate Sets from $plate_ids.<BR>";
            }

        }
        else {
            print "No Plate IDs in $libs.<BR>";
        }

    }
    else {
        print "No Libraries found<BR>";
    }

    my $Plate = HTML_Table->new();
    $Plate->Set_Title("Plates used from libraries: $library");
    $Plate->Set_Headers( [ 'Number', 'Format', 'Status', 'Failed', 'Production/Test' ] );

    if (%Plate_Info) {
        my $index = 0;
        while ( defined $Plate_Info{Format}[$index] ) {
            my $format  = $Plate_Info{Format}[$index];
            my $count   = $Plate_Info{Number}[$index];
            my $status  = $Plate_Info{Status}[$index];
            my $failed  = $Plate_Info{Failed}[$index];
            my $Tstatus = $Plate_Info{Test_Status}[$index];

            my $list = join ',',
                $dbc->Table_find( 'Plate,Plate_Format', 'Plate_ID',
                "WHERE FK_Plate_Format__ID=Plate_Format_ID" . " AND FK_Library__Name in ($libs)" . " AND Plate_Status='$status'" . " AND Failed='$failed'" . " AND Plate_Test_Status = '$Tstatus'" . " AND Plate_Format_Type = '$format'" );

            my $flink = &Link_To( $dbc->config('homelink'), "<B>$format</B>", "&Info=1&Table=Plate&Field=Plate_ID&Like=$list", $Settings{LINK_COLOUR}, ['newwin'] );

            $Plate->Set_Row( [ $count, $flink, $status, $failed, $Tstatus ] );
            $index++;
        }
    }

    print "<Table><TR><TD valign=top>";
    $Plate->Printout();
    print $Plate->Printout( "$URL_temp_dir/$library" . "_Plates_Used.html" );

    unless ($reagents) {
        print "</TD></TR></Table>";
        return 1;
    }

    my %Quantity    = {};
    my %ReagentName = {};
    my %SolName     = {};
    my %SolQty      = {};
    my %IDs         = {};
    my %Unknown;
    my %Prep     = {};
    my %PrepList = {};

    foreach my $detail (@solution_info) {
        my ( $sol, $used, $set, $pid, $solname, $prep_id ) = split ',', $detail;

        $Prep{$solname} = $used;

        push @{ $PrepList{$solname} }, $prep_id;
        push( @{ $IDs{$solname} }, $sol ) unless ( grep /\b$sol\b/, @{ $IDs{$solname} } );

        my $number_in_set;
        if ($set) {
            $number_in_set = $dbc->Table_find( 'Plate_Set', 'count(*)', "WHERE Plate_Set_Number=$set" );
        }
        elsif ($pid) {
            $number_in_set = $dbc->Table_find( 'Plate_Set', 'count(*)', "WHERE FK_Plate__ID in ($pid)" );
        }

        if ( $set > 0 && $number_in_set > 1 ) {
            $used = $used / $number_in_set;
        }    ### get fraction used

        my %Used = get_reagent_amounts( $sol, $used );

        unless (%Used) {
            $Unknown{$sol} = $used;

            next;
        }

        my @reagents = keys %{ $Used{Quantity} };
        foreach my $reagent (@reagents) {

            if ( $Used{Type}->{$reagent} =~ /Reagent/ ) {
                my $name = $Used{Name}->{$reagent};

                $Quantity{$name} ||= 0;
                $Quantity{$name} += $Used{Quantity}->{$reagent};

                push( @{ $IDs{$name} }, $reagent ) unless ( grep /\b$reagent\b/, @{ $IDs{$name} } );
            }

            if ( $Used{Type}->{$reagent} =~ /Solution/ ) {
                my $name = $Used{Name}->{$reagent};

                $SolQty{$name} ||= 0;
                $SolQty{$name} += $Used{Quantity}->{$reagent};

                push( @{ $IDs{$name} }, $reagent ) unless ( grep /\b$reagent\b/, @{ $IDs{$name} } );
            }
        }
    }

    print "</TD><TD valign=top>";

    my $Reagent = HTML_Table->new();
    $Reagent->Set_Title("Reagents/Solutions applied directly");
    $Reagent->Set_Headers( [ 'Solution/Reagent', 'Quantity Used' ] );

    foreach my $reagent ( keys %Prep ) {
        if ( $reagent =~ /^HASH/ ) {
            next;
        }    ### keep out other hashes

        my $prep_list = join ',', @{ $PrepList{$reagent} };
        my $stock = &Link_To( $dbc->config('homelink'), "<B>$reagent</B>", "&Info=1&Table=Prep&Field=Prep_ID&Like=$prep_list", $Settings{LINK_COLOUR}, ['newwin'] );

        my ( $amount, $units ) = Get_Best_Units( -amount => $Prep{$reagent}, -units => 'mL' );
        $Reagent->Set_Row( [ $stock, "$amount $units" ] );
    }

    $Reagent->Set_sub_header( 'Original Reagent Totals', 'lightblue' );

    foreach my $reagent ( keys %Quantity ) {
        if ( $reagent =~ /^HASH/ ) {
            next;
        }    ### keep out other hashes

        my $p_reagent = $reagent;
        $p_reagent =~ s/\s/\+/g;
        my $ids = 0;
        $ids = join ',', @{ $IDs{$reagent} } if $IDs{$reagent};
        my $stock = &Link_To( $dbc->config('homelink'), "<B>$reagent</B>", "&Info=1&Table=Solution&Field=Solution_ID&Like=$ids", $Settings{LINK_COLOUR}, ['newwin'] );

        my ( $amount, $units ) = Get_Best_Units( -amount => $Prep{$reagent}, -units => 'mL' );

        $Reagent->Set_Row( [ $stock, "$amount $units" ] );
    }

    $Reagent->Set_sub_header( 'Solutions generated in the process', 'lightblue' );
    foreach my $reagent ( keys %SolQty ) {
        if ( $reagent =~ /^HASH/ ) {
            next;
        }    ### keep out other hashes

        my $p_reagent = $reagent;
        $p_reagent =~ s/\s/\+/g;
        my $ids = 0;
        $ids = join ',', @{ $IDs{$reagent} } if $IDs{$reagent};
        my $stock = &Link_To( $dbc->config('homelink'), "<B>$reagent</B>", "&Info=1&Table=Solution&Field=Solution_ID&Like=$ids", $Settings{LINK_COLOUR}, ['newwin'] );

        $Reagent->Set_Row( [ $stock, number( $SolQty{$reagent} / 1000, 2 ) ] );
    }

    if (%Unknown) {
        $Reagent->Set_sub_header( 'Solutions with missing data (<B>Complete if possible</B>)', 'lightblue' );
        foreach my $reagent ( keys %Unknown ) {
            if ( $reagent =~ /^HASH/ ) {
                next;
            }    ### keep out other hashes

            my $p_reagent = $reagent;
            $p_reagent =~ s/\s/\+/g;
            ( my $name ) = $dbc->Table_find( 'Stock,Solution,Stock_Catalog', 'Stock_Catalog_Name', "WHERE FK_Stock__ID=Stock_ID and Solution_ID = $reagent AND FK_Stock_Catalog__ID = Stock_Catalog_ID " );
            my $stock = &Link_To( $dbc->config('homelink'), "<B>Sol$reagent: $name</B>", "&Info=1&Table=Solution&Field=Solution_ID&Like=$p_reagent", $Settings{LINK_COLOUR}, ['newwin'] );
            $Reagent->Set_Row( [ $stock, number( $Unknown{$reagent} / 1000, 2 ) . 'L' ] );
        }
    }

    $Reagent->Printout();
    print $Reagent->Printout( "$URL_temp_dir/$library" . "_Stock_Used.html" );
    print "</TD></TR></Table>";

    return;
}

################################
sub move_stock {
####################

    my $stock_id   = shift;
    my $stock_type = shift;
    my $rack_id    = shift;
    my $dbc        = $Connection;

    my $rack = get_aldente_id( $dbc, $rack_id, 'Rack' );

    unless ( ( $rack =~ /[1-9]/ ) && !( $rack =~ /,/ ) ) {
        Message("Requires single valid rack");

        return 0;
    }

    #### works for Plate, Solution, or Tube... #########

    if ( $stock_type =~ /plate/i ) {
        my $plates = get_aldente_id( $dbc, $stock_id, 'Plate' );
        $dbc->Table_update( 'Plate', 'FK_Rack__ID', $rack, "WHERE Plate_ID in ($plates)" );
    }
    elsif ( $stock_type =~ /solution/i ) {
        my $sols = get_aldente_id( $dbc, $stock_id, 'Solution' );
        $dbc->Table_update( 'Solution', 'FK_Rack__ID', $rack, "WHERE Solution_ID in ($sols)" );
    }
    elsif ( $stock_type =~ /tube/i ) {
        my $tubes = get_aldente_id( $dbc, $stock_id, 'Tube' );
        $dbc->Table_update( 'Tube', 'FK_Rack__ID', $rack, "WHERE Tube_ID in ($tubes)" );
    }

    return 1;
}

################################ Should replace REceiveBOXITems
sub Receive_Box_Items {
################################
    my %args          = @_;
    my $dbc           = $args{-dbc};
    my $sample        = $args{-sample};
    my $lot           = $args{-lot};
    my $number        = $args{-number} || 1;
    my $box           = $args{-box} || 1;
    my $org           = $args{-organization};
    my $employee      = $args{-employee};
    my $obtained      = $args{-date};
    my $rack          = $args{-rack};
    my $cost          = $args{-cost};
    my $serial_number = $args{-serial_number};
    my $label         = $args{-label};
    my $grp           = $args{-grp};
    my $expired       = $args{-expired};

    print HTML_Dump \%args;

}

################################
sub ReceiveBoxItems {
#####################
    # Extract Standard items from a Box in batch
    # (This should be called once for each unique item, indicating the number of items to receive at once)
    #
#############################################
    my %args          = @_;
    my $dbc           = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $sample        = $args{-sample};
    my $lot           = $args{-lot};
    my $number        = $args{-number} || 1;
    my $box           = $args{-box} || 1;
    my $org           = $args{-organization};
    my $employee      = $args{-employee};
    my $obtained      = $args{-date};
    my $rack          = $args{-rack};
    my $cost          = $args{-cost};
    my $serial_number = $args{-serial_number};
    my $label         = $args{-label};
    my $grp           = $args{-grp};
    my $expired       = $args{-expired};
    my $catalog_id    = $args{-catalog_id};

    my @tables = 'Stock';
    my ($type) = $dbc->Table_find( 'Stock,Stock_Catalog', 'Stock_Catalog.Stock_Type', "WHERE Stock_ID = $sample AND FK_Stock_Catalog__ID = Stock_Catalog_ID" );

    my $extra_table;

    if    ( $type =~ /(Reagent|Solution|Buffer|Matrix|Primer)/ ) { $extra_table = 'Solution'; }
    elsif ( $type =~ /(Equipment)/ )                             { $extra_table = 'Equipment'; }
    elsif ( $type =~ /(Box|Kit)/ )                               { $extra_table = 'Box'; }
    elsif ( $type =~ /(Microarray)/ )                            { $extra_table = 'Microarray'; }
    else                                                         { $extra_table = 'Misc_Item'; }

    my $Stock_Item = SDB::DB_Object->new( -dbc => $dbc, -tables => 'Stock,Stock_Catalog' );

    $Stock_Item->primary_value( -table => 'Stock', -value => $sample );
    $Stock_Item->load_Object();

    $label = &get_FK_ID( $dbc, 'FK_Barcode_Label__ID', $label );

    my $id = $Stock_Item->value('Stock_ID');

    $grp ||= $Stock_Item->value('FK_Grp__ID');
    $Stock_Item->{tables} = ['Stock'];
    $Stock_Item->value( -field => 'Stock_ID',              -value => 0 );                                   ## reset ID
    $Stock_Item->value( -field => 'Stock_Lot_Number',      -value => $lot );                                ## reset Lot
    $Stock_Item->value( -field => 'Stock_Number_in_Batch', -value => $number );                             ## reset # in Batch
    $Stock_Item->value( -field => "FK_Employee__ID",       -value => $employee );                           ## reset Employee
    $Stock_Item->value( -field => "Stock_Received",        -value => convert_date( $obtained, 'SQL' ) );    ## reset Rcvd Date
    $Stock_Item->value( -field => "FK_Box__ID",            -value => $box );                                ## reset parent box

    #    $Stock_Item->value( -field => "Stock_Catalog.FK_Organization__ID", -value => $org );                                ## reset parent box
    #    $Stock_Item->value( -field => "Stock_Catalog.Stock_Source",        -value => 'Box' );
    $Stock_Item->value( -field => "FK_Barcode_Label__ID", -value => $label );
    $Stock_Item->value( -field => "FK_Grp__ID",           -value => $grp );
    $Stock_Item->value( -field => "Stock_Cost",           -value => $cost );
    $Stock_Item->value( -field => "FK_Stock_Catalog__ID", -value => $catalog_id );
    my $added = $Stock_Item->insert();

    $rack = &get_FK_ID( $dbc, 'FK_Rack__ID', $rack );
    $grp  = &get_FK_ID( $dbc, 'FK_Grp__ID',  $grp );

    my $new_id;

    if ( $added->{Stock} ) {
        $new_id = $Stock_Item->{newids}{Stock}[-1];    ## get last id added ..
    }
    else {
        Message("Error adding Stock ?.. ");
        return;
    }

    my @fields = ( 'FK_Stock__ID', $extra_table . "_Number", $extra_table . "_Number_in_Batch", 'FK_Rack__ID' );

    my $sol_type;
    my $sol_quantity;
    if ( $extra_table eq 'Solution' ) {
        my %s_info = $dbc->Table_retrieve( 'Stock,Solution,Stock_Catalog', [ 'Solution_Type', 'Stock_Size' ], "WHERE Stock_Catalog_ID = FK_Stock_Catalog__ID AND Stock_ID=FK_Stock__ID" . " AND Stock_ID=$sample" . " ORDER BY Stock_ID DESC" . " LIMIT 1" );
        $sol_type     = $s_info{Solution_Type}[0];
        $sol_quantity = $s_info{Stock_Size}[0];
        unless ($sol_quantity) { $sol_quantity = 10 }
        push( @fields, 'Solution_Expiry', 'Solution_Type', 'QC_Status', 'Solution_Quantity', 'Solution_Status' );
    }
    elsif ( $extra_table eq 'Box' ) {
        push @fields, 'Box_Expiry';
    }
    elsif ( $extra_table eq 'Microarray' ) {
        push @fields, 'Expiry_DateTime';
    }

    my %values;
    foreach my $index ( 1 .. $number ) {
        $values{$index} = [ $new_id, $index, $number, $rack ];
        if ( $extra_table eq 'Solution' || $extra_table eq 'Box' || $extra_table eq 'Microarray' ) {
            push @{ $values{$index} }, convert_date( $expired, 'SQL' );
        }

        if ( $extra_table eq 'Solution' ) {
            push @{ $values{$index} }, $type;
            push @{ $values{$index} }, 'N/A';
            push @{ $values{$index} }, $sol_quantity;
            push @{ $values{$index} }, 'Unopened';

        }
    }

    my $ok = $dbc->smart_append(
        -tables    => $extra_table,
        -fields    => \@fields,
        -values    => \%values,
        -autoquote => 1
    );

    if ( defined $ok->{$extra_table}{newids} ) {
        my $new_ids = join ',', @{ $ok->{$extra_table}{newids} };
        my $name = $Stock_Item->value( -field => 'Stock_Catalog_Name' );

        Message("Added new $name ($extra_table): $new_ids.");
        &alDente::Barcoding::PrintBarcode( $dbc, $extra_table, $new_ids );

        # <CONSTRUCTION> add Genechip if Microarray, this should be done in a better way
        if ( $extra_table eq 'Microarray' ) {

            # find Genechip_Type
            my ($genechip_type_id) = $dbc->Table_find_array( 'Stock,Microarray,Genechip', ['FK_Genechip_Type__ID'], "where Stock_ID = FK_Stock__ID and FK_Microarray__ID = Microarray_ID and Stock_ID = $sample" );

            unless ($genechip_type_id) {next}
            my @insert_fields = ( 'FK_Microarray__ID', 'FK_Genechip_Type__ID' );
            my @ids_array     = split( ",",            $new_ids );
            my $num_chips     = scalar @ids_array;
            my %insert_hash;
            foreach my $index ( 1 .. $num_chips ) {
                $insert_hash{$index} = [ $ids_array[ $index - 1 ], $genechip_type_id ];
            }
            my $ok1 = $dbc->smart_append(
                -tables    => 'Genechip',
                -fields    => \@insert_fields,
                -values    => \%insert_hash,
                -autoquote => 1
            );

            if ( defined $ok1->{Genechip}{newids} ) {
                my $new_chip_ids = join ',', @{ $ok1->{Genechip}{newids} };
                Message("Added new Genechip: $new_chip_ids.");
            }

        }

    }

    return;
}

##############################
# private_functions          #
##############################
##########################  NEW
sub _get_equipment_name {
##########################
    my %args        = &filter_input( \@_ );
    my $dbc         = $args{-dbc};
    my $category_id = $args{-category_id};

    my $command = "Concat(Max(Replace(Equipment_Name,concat(Prefix,'-'),'') + 1)) as Next_Name";
    my ($name) = $dbc->Table_find_array( 'Equipment_Category', -fields => ['Prefix'], -condition => "WHERE Equipment_Category_ID=$category_id" );
    my ($number) = $dbc->Table_find_array( 'Equipment,Equipment_Category,Stock,Stock_Catalog',
        [$command], "WHERE  FK_Stock__ID = Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND  FK_Equipment_Category__ID=Equipment_Category_ID AND Equipment_Category_ID=$category_id" );
    unless ($number) { $number = 1 }
    return ( $name, $number );
}
#########################   NEW
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

##############################
# OBsolete           #
##############################
#######################                            Obsolete
sub ReceiveStock {
#######################
    #
    #  Prompt for new stock form based on incoming stock number...
    #
    #
    Message('You should not see this, this function is obsolete.  Please inform LIMS of this error (Code RECEIEVE)');
    return;

    return 1;
}
###########################                         OBSOLETE
sub original_stock {
###########################

    Message('This function should be obsolete.  If you see this Message please inform LIMS');
    return;

}
################################                   OBSOLETE
sub save_original_stock {
################################
    #
    # Add record to database based on original_stock input...
    #

    Message('This function should be obsolete.  If you see this Message please inform LIMS (CODE: SAVE ORIGINAL STOCK)');
    return;

}
##########################                  OBSOLETE
sub _preFormPrompt {
#########################
    Message('You should not see this obsolete function. Please inform LIMS');
    return;
    my $dbc        = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $stock_type = shift;
    my $item_type  = shift || '';
    my $rack       = shift || '';
    my $homelink   = $dbc->homelink();

    my $source = param('Stock_Source')  || 'Order';    ## carry through stock source
    my $box    = param('FK_Box__ID')    || 0;          ## if from box...
    my $order  = param('FK_Orders__ID') || 0;

    my $form_name = "AddStock";
## change WHERE condition in line below to look for particular temperatures,
## if a group wants to be notified when it is missing equipment
## with certain conditions
## to clarify the notification, the warning message a few lines below
## must be changed to specify the searched-for conditions also

    my ($tbd_rackid) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Alias='TBD'" );
    my $tbd_rackinfo;

    if ($tbd_rackid) {
        $tbd_rackinfo = $dbc->get_FK_info( 'FK_Rack__ID', $tbd_rackid );
    }
    else {
        Message('Warning: Did not find any TBD (equipment conditions) Racks');
    }

    my $extra_parameters = '';
    if    ($box)   { $extra_parameters = "&FK_Box__ID=$box"; }
    elsif ($order) { $extra_parameters = "&FK_Orders__ID=$order"; }

    if ( $stock_type =~ /Equipment/ ) {    ### pre-enter equipment name (retrieved in routine below ... )
        my @Types = get_enum_list( $dbc, 'Equipment', 'Equipment_ Type' );
        my @E_locations = get_FK_info( $dbc, 'FK_Location__ID', -list => 1 );
        my $def_Location = '';

        # needed for the next bit of javascript
        my %default_params;

        my $submit_url;
        if ($homelink) {

            # a home link with some parameters at the end
            $homelink =~ /([^\?]*)(.*)?/;
            $submit_url = $1;
            my $pars = $2;

            $pars =~ s/^\??//;
            foreach ( split '&', $pars ) {
                my ( $name, $value ) = split( '=', $_ );
                $default_params{$name} = $value;
            }
        }

        $default_params{Database} = $dbc->{dbase};

        require JSON;
        my $default_params;
        if (JSON->VERSION =~/^1/) { $default_params = JSON::jsonToObj(\%default_params) }
        else { $default_params = JSON::from_json(\%default_params) }


        # some javascript setup for the "add new Location" link
        print "<table><tr>"
            . "<td id='navRoadMap'></td>"
            . "<td id='formPlaceHolder'><!-- Form goes here --></td>"
            . "<span class='HiddenData'>"
            . "<textarea id=formNavTempData></textarea>"
            . "<textarea id=formNavTempMap></textarea>"
            . "</span></tr></table>";

        print "<script language='javascript'>
        var formStruct = {};
        var roadMapObj = {};
        var formConfigs = {
            'default_parameters':$default_params,
            'submitsingle': '/$URL_dir_name/cgi-bin/ajax/storeobject.pl',
            'formgen': '/$URL_dir_name/cgi-bin/ajax/formgen.pl',
            'database':'$dbc->{dbase}',
            'database_host':'$dbc->{host}',
        };
        </script>";

        print "Note: if more than one Location required, please edit the Location for the Equipment afterwards.<P>";

        print submit(
            -name  => 'List Equipment Names',
            -value => 'List Ref Names/Aliases',
            -class => "Search"
        ) . "<B> of Type as selected below..</B>";

        my $background = "bgcolor=lightgrey";

        print "<Table width = 100%><TR>" . "<TD colspan = 2 bgcolor=yellow>" . "<B>Add Details for Equipment Here:</B><BR>" . "(May use comma-delimited list if more than one piece of equipment)" . "</TD></TR>";

        print "<TR><TD $background><B><font color=red>Ref Name/Alias</font></B> (eg 'F20-3'):</TD>"
            . "<TD $background>"
            . textfield( -name => 'Equipment_Name', -size => 40 )
            . set_validator( -name => 'Equipment_Name', -mandatory => 1 )
            . "</TD></TR>"
            . "<TR><TD $background><B><font color=red>Location:</font></B></TD>"
            . "<TD $background>"
            . popup_menu(
            -name    => 'Equipment _Location',
            -id      => 'Equipment _Location',
            -values  => [ '', @E_locations ],
            -default => $def_Location
            )
            . set_validator(
            -name      => 'Equipment _Location',
            -mandatory => 1
            )
            . qq^ <a href="javascript:formAddNew('Location','Equipment_ Location')">(add new)</a>^
            . "</TD></TR>"
            . "<TR><TD $background><font color=red>Equipment Type:</font></TD>"
            . "<TD $background>"
            . popup_menu(
            -name    => 'Equipment_T ype',
            -values  => \@Types,
            -default => $item_type,
            -force   => 1
            )
            . set_validator(
            -name      => 'Equipment_ Type',
            -mandatory => 1
            )
            . "</TD></TR>"
            . "<TR><TD $background><font color=red>Model Name:</font></TD>"
            . "<TD $background>"
            . textfield( -name => 'Model', -size => 40 )
            . set_validator( -name => 'Model', -mandatory => 1 )
            . "</TD></TR>"
            . "<TR><TD $background><font color=red>Serial Number :</font></TD>"
            . "<TD $background>"
            . textfield( -name => 'Serial_Number', -size => 40 )
            . set_validator( -name => 'Serial_Number', -mandatory => 1 )
            . "</TD></TR></Table>"
            . &vspace(10);
    }
    elsif ( $stock_type =~ /Reagent|Solution/ ) {
        ### pre-enter type if req'd
        my @types = get_enum_list( $dbc, 'Solution', 'Solution_Type' );

        print "<font size=-1>";
        Message("Information specific to Solutions/Reagents:");
        print "<Table width=90% bgcolor='DDDDDD'><TR>";

        #As the user change the popup menu, the URL will be redirected based on the solution type choosen (i.e. this.value in JavaScript's context).
        print "<TD colspan=2><font size=-1>Adjust ONLY <B>if Primer/Matrix/Buffer : </B>"
            . popup_menu(
            -name     => 'Solution_Type',
            -value    => \@types,
            -default  => $item_type,
            -onChange => "goTo('$homelink','&New+Stock=New+Reagent&Stock_Source=$source$extra_parameters&Solution_Type=' + this.value)"
            ) . "</Font></TD>";

        print "<TR><TD><font color=red>Location</font></td><td>"
            . alDente::Tools->search_list(
            -dbc     => $dbc,
            -name    => 'FK_Rack__ID',
            -default => $tbd_rackinfo,
            -search  => 1,
            -filter  => 1,
            -breaks  => 1,
            -mode    => 'Popup'
            )
            . set_validator( -name => 'FK_Rack__ID', -mandatory => 1 )
            . "</TD></TR>";

        if ( $item_type =~ /Primer/i ) {
            print "<TD align=right>" . 'ODs:'
                . textfield( -name => 'ODs', -size => 10 )
                . &vspace()
                . 'nMoles:'
                . textfield( -name => 'nMoles', -size => 10 )
                . &vspace()
                . 'micrograms:'
                . textfield( -name => 'micrograms', -size => 10 )
                . &vspace()
                . "</TD></TR>";
        }

        print "<TR><TD colspan=3><HR></TD></TR>";

        print "<TR><TD align=right><B>Expiry: </B></TD>" . "<TD colspan=2 align=left>" . textfield( -name => 'Expiry' ) . "<font size=-1>('2002-01-27' or 'Jan-01-2002')</Font>" . "</TD></TR> </Table>" . &vspace(10);
    }
    elsif ( $stock_type =~ /Kit|Box/ ) {

        my @box_types = $dbc->get_enum_list( 'Box', 'Box_Type' );
        my $table = new HTML_Table();

        $table->Set_Title("Box Details");

        $table->Set_Row(
            [   "<font color=red><B>Box Type</B></font>",
                popup_menu(
                    -name    => 'Box_Type',
                    -values  => [ '', @box_types ],
                    -default => $item_type,
                    -force   => 1
                ),
            ]
        );

        $table->Set_Row(
            [   b("<font color=red>Location</font>"),
                alDente::Tools->search_list(
                    -dbc     => $dbc,
                    -name    => 'FK_Rack__ID',
                    -default => $tbd_rackinfo,
                    -search  => 1,
                    -filter  => 1,
                    -breaks  => 1
                    )
                    . set_validator(
                    -name      => 'FK_Rack__ID',
                    -mandatory => 1
                    ),
            ]
        );

        $table->Set_Row( [ "<font color=red><B><font color=red>Box_Expiry</font></B></font>", textfield( -name => 'Box_Expiry' ) . "<font size=-1>('2002-01-27' or 'Jan-01-2002')</Font>", ] );

        $table->Printout();
    }
    elsif ( $stock_type =~ /Misc_Item/ ) {
        print "<TR><TD><font color=red>Location</font></td><td>"
            . alDente::Tools->search_list(
            -dbc     => $dbc,
            -name    => 'FK_Rack__ID',
            -default => $tbd_rackinfo,
            -search  => 1,
            -filter  => 1,
            -breaks  => 1
            )
            . set_validator( -name => 'FK_Rack__ID', -mandatory => 1 )
            . "</TD></TR>";
    }
    elsif ( $stock_type =~ /Microarray/ ) {
        my @microarray_types = $dbc->get_enum_list( 'Microarray', 'Microarray_Type' );
        my @genechip_types   = $dbc->get_FK_info_list('FK_Genechip_Type__ID');
        my $table            = new HTML_Table();

        $table->Set_Title("Microarray Details");

        $table->Set_Row(
            [   "Microarray Type",
                popup_menu(
                    -name    => 'Microarray_Type',
                    -values  => [ '', @microarray_types ],
                    -default => $item_type,
                    -force   => 1
                ),
            ]
        );

        $table->Set_Row(
            [   b("<font color=red>Location</font>"),
                alDente::Tools->search_list(
                    -dbc     => $dbc,
                    -name    => 'FK_Rack__ID',
                    -default => $tbd_rackinfo,
                    -search  => 1,
                    -filter  => 1,
                    -breaks  => 1
                    )
                    . set_validator(
                    -name      => 'FK_Rack__ID',
                    -mandatory => 1
                    ),
            ]
        );

        $table->Set_Row( [ "<B><font color=red>Expiry Date</font></B>", textfield( -name => 'Expiry_Date' ) . "<font size=-1>('2002-01-27' or 'Jan-01-2002')</Font>", ] );

        #$table->Set_Row(["External Barcode",textfield(-name=>"External_Barcode")]); # should be entered when the chip is used

        $table->Set_Row(
            [   "<B><font color=red>Genechip Type</font></B>",
                popup_menu(
                    -name    => "Chip_Type",
                    -values  => [ '', @genechip_types ],
                    -default => '',
                    -force   => 1
                ),
            ]
        );

        $table->Printout();
    }

    return;
}

##########################
return 1;

##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Stock.pm,v 1.83 2004/12/08 18:00:18 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
