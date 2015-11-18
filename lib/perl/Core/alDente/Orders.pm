###############################
#
# Orders.pm
#
###############################
################################################################################
# $Id: Orders.pm,v 1.9 2004/09/08 23:31:49 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.9 $
#     CVS Date: $Date: 2004/09/08 23:31:49 $
################################################################################
package alDente::Orders;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Orders.pm - 

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    Orders_Page
    Orders_Icons
);
@EXPORT_OK = qw(
    Orders_Page
    Orders_Icons
);

##############################
# standard_modules_ref       #
##############################

use strict;
use CGI qw(:standard);
use DBI;
use Benchmark;
use Date::Calc qw(Day_of_Week);

#use Storable;
use GD;

##############################
# custom_modules_ref         #
##############################
use alDente::Stock;
use SDB::DB_Form_Viewer;
use SDB::DB_Record;
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use RGTools::RGIO;
use SDB::HTML;

##############################
# global_vars                #
##############################
our ( $homefile, $testing, $home_web_dir );
our ( @plate_sizes, @organizations, @s_suppliers, @locations, @rack_info );
our ( $stock_page, $Fclass );    ### keep track of current page...
our (@FontClasses);
our ( $dbase, $user );
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
@FontClasses = ( 'vsmall', 'small', 'medium', 'large', 'vlarge' );
my $ADorder = 'Desc';
my $anydate;
my $list_limit    = 50;    #### default limit on length of list of displayed records.
my @Orders_fields = (
    'Orders_ID as ID',
    'Orders_Quantity as Qty',
    'Item_Unit as Unit',
    'Orders_Received as Rcvd',
    'Orders_Catalog_Number as Cat_Num',
    'Orders_Item as Item',
    'Orders_Item_Description as Description',
    'Item_Size as Size',
    'Item_Units as Size_Units',
    'FKVendor_Organization__ID as Vendor',
    'FKManufacturer_Organization__ID as Manufacturer',
    'Orders_Status as Status',
    'Req_Date',
    'Req_Number',
    'PO_Date',
    'PO_Number',
    'Orders_Received_Date as Rcvd_Date',
    'Orders_Lot_Number as Lot_Num',
    'Quote_Number as Quote',
    'Unit_Cost',
    'Currency',
    'Orders_Cost as Total_Cost',
    'Freight_Costs as Freight',
    'Taxes',
    'FK_Account__ID as Expense_Code',
    'Serial_Num',
    'FK_Funding__Code as Funding',
    'Orders_Notes as Notes',
    'Total_Ledger_Amount as Ledger_Amt',
    'Ledger_Period',
    'MSDS',
    'Warranty'
);
### add TEMPORARILY ###
#push (@Orders_fields,'old_Orders_Received');
#push (@Orders_fields,'old_Unit_Cost');
#push (@Orders_fields,'old_Orders_Cost');
#push (@Orders_fields,'old_Total_Ledger_Amount');
#push (@Orders_fields,'old_Freight_Cost');
#push (@Orders_fields,'old_Taxes');
my @Orders_display = ( 'Qty', 'Unit', 'Rcvd', 'Cat_Num', 'Item', 'Description', 'Size', 'Size_Units', 'Req_Date', 'Expense_Code', 'Lot_Num', 'Notes' );
my $set_display    = 0;
my $Orders_Title   = "Items On Order";
############ Fields in Orders Database ####################
( my $since ) = split ' ', &RGTools::RGIO::date_time('-30d');
( my $upto )  = split ' ', &RGTools::RGIO::date_time();         ### todays date...
my $basic_condition = "where Req_Date > '$since'";

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

#my $search_orders = 'Search';   # flag to indicate whether we are searching through the orders table...

######################
sub Orders_Page {
######################

    my $page            = shift;
    my $dbc             = $Connection;
    my $table           = 'Orders';
    my $order_field     = param('Order By') || 'Req_Date Desc';
    my $order_condition = " Order by $order_field";
	my $homelink = $dbc->homelink();
	
    my $Order_Records = DB_Record->new( $dbc, 'Orders', $homelink );

    #    $Order_Records->{View} = 'Basic';

    $stock_page = param('Orders Page') || param('PageName') || 'Received Orders';

    if ( $stock_page =~ /Main Orders/i ) { $stock_page = 'Received Orders'; }    ### do not have a Main page

    my $Standard_Fields = {};
    @{ $Standard_Fields->{Orders} } = ( 'Qty', 'Unit', 'Rcvd', 'Cat_Num', 'Item', 'Description', 'Size', 'Size_Units', 'Req_Date', 'Expense_Code', 'Lot_Num', 'Notes' );
    @{ $Standard_Fields->{Solution} } = ( 'Solution_Type', 'Solution_Status', 'Solution_Number_in_Batch' );
    @{ $Standard_Fields->{Equipment} } = ( 'Equipment_Name', 'Equipment_Serial_Number' );
    @{ $Standard_Fields->{Misc_Item} } = ( 'Misc_Item_Name', 'Misc_Item_Description', 'Misc_Item_Serial_Number' );
    @{ $Standard_Fields->{Box} }       = ( 'Box_Name',       'Box_Description', 'Box_Serial_Number' );

###### list of fields when entering a new order.. ###### MUST include FK_Account__ID ...
    my @Orders_sort_fields
        = ( 'Orders_Item as Item', 'Orders_Quantity as Qty', 'Orders_Item_Description', 'Orders_Received as Rcvd', 'Orders_Received_Date as Rcvd_Date', 'FKVendor_Organization__ID', 'Req_Date', 'PO_Date', 'FK_Account__ID', 'Req_Number', 'PO_Number' );
    my @Orders_fields = (
        'Orders_ID as ID',
        'Orders_Quantity as Qty',
        'Item_Unit as Unit',
        'Orders_Received as Rcvd',
        'Orders_Catalog_Number as Cat_Num',
        'Orders_Item as Item',
        'Orders_Item_Description as Description',
        'Item_Size as Size',
        'Item_Units as Size_Units',
        'FKVendor_Organization__ID as Vendor',
        'FKManufacturer_Organization__ID as Manufacturer',
        'Orders_Status as Status',
        'Req_Date',
        'Req_Number',
        'PO_Date',
        'PO_Number',
        'Orders_Received_Date as Rcvd_Date',
        'Orders_Lot_Number as Lot_Num',
        'Quote_Number as Quote',
        'Unit_Cost',
        'Currency',
        'Orders_Cost as Total_Cost',
        'Freight_Costs as Freight',
        'Taxes',
        'FK_Account__ID as Expense_Code',
        'Serial_Num',
        'FK_Funding__Code as Funding',
        'Orders_Notes as Notes',
        'Total_Ledger_Amount as Ledger_Amt',
        'Ledger_Period',
        'MSDS',
        'Warranty'
    );

    my @new_order_display = (
        'Orders_Quantity as Qty',
        'Item_Unit as Unit',
        'Orders_Catalog_Number as Cat_Num',
        'Orders_Item as Item',
        'Orders_Item_Description as Description',
        'Item_Size as Size',
        'Item_Units as Size_Units',
        'FKVendor_Organization__ID as Vendor',
        'Req_Date',
        'Req_Number',
        'Quote_Number as Quote',
        'Unit_Cost',
        'Currency',
        'Orders_Cost as Total_Cost',
        'FK_Account__ID as Expense_Code',
        'FK_Funding__Code as Funding',
        'Orders_Notes as Notes'
    );

###### list of fields when receiving an order.. ########
    my @received_display = (
        'Orders_Quantity as Qty',
        'Item_Unit as Unit',
        'Orders_Received as Rcvd',
        'Orders_Catalog_Number as Cat_Num',
        'Orders_Item as Item',
        'Orders_Item_Description as Description',
        'Item_Size as Size',
        'Item_Units as Size_Units',
        'Orders_Received_Date as Rcvd_Date',
        'FKVendor_Organization__ID as Vendor',
        'Orders_Lot_Number as Lot_Num',
        'Serial_Num',
        'FK_Funding__Code as Funding',
        'Orders_Cost as Total_Cost',
        'Taxes',
        'Freight_Costs as Freight',
        'Total_Ledger_Amount as Ledger_Amt',
        'Ledger_Period',
        'FK_Account__ID as Account',
        'Warranty',
        'MSDS',
        'Orders_Notes as Notes'
    );

    my @conditions = ('1');    ######### initialize an array of conditions
    my %Orders;

    if ( $stock_page =~ /Received/i ) {
        push( @conditions, "Orders_Received < Orders_Quantity" );
        $Orders_Title = "<B>Orders Awaiting Receival</B>";
        $Order_Records->Display_Fields( \@received_display, [ 4, 4, 4, 10, 10, 15, 20, 4, 4, 8, 8, 10, 10, 10, 5, 4, 4, 20 ] );
        $Order_Records->{Page}        = 'Received Orders';
        $Order_Records->{Auto_append} = 0;                   ### turn off Auto-append ###
    }
    elsif ( $stock_page =~ /New/i ) {
        $Orders_Title = "<B>New Order Entry Form</B>";
        $Order_Records->Display_Fields( \@new_order_display, [ 4, 4, 10, 15, 20, 4, 4, 10, 8, 10, 10, 5, 4, 6, 10, 10, 20 ] );
        $Order_Records->{Page}        = 'New Orders';
        $Order_Records->{Auto_Append} = 1;
    }
    else {
        $Order_Records->Display_Fields( \@Orders_sort_fields, [ 15, 5, 20, 8, 8, 10, 10 ] );
        $Order_Records->{Page}        = 'Main Orders';
        $Order_Records->{Auto_append} = 0;                   ### turn off Auto-append ###
    }

    my $date_field = param('DateField') || 'Req_Date';

########### {Page Header) ###########
    &Orders_Icons( -dbc => $dbc );
    print "<B>", "Database: <Font color=red>$dbase</Font>", &space(10), "User: <Font color=red>$user</Font>", &space(10), "Page: <Font color=red>$stock_page</Font>", &space(30),

        #    "Size: <Font color=red>".$FontClasses[$Fclass]."</Font>",
        "</B><hr>";

    $Order_Records->Set_Title($Orders_Title);

    my $option1 = &Link_To( $dbc->config('homelink'), "<B>New Order</B>", "&PageName=New+Orders" ) . &hspace(20) . &Link_To( $dbc->config('homelink'), "<B>Received</B>", "&PageName=Received+Orders" );
    my @funds = $Connection->Table_find( 'Funding', 'Funding_Name', "where Funding_Status = 'Received' OR Funding_Status = 'Pending'" );
    my @fund_options = ( '', SDB::DBIO::get_FK_info( $dbc, 'FK_Funding__Code' ) );

    my $pick_funding = "\n<B>Specify </B> " . &Link_To( $dbc->config('homelink'), 'Funding:', "&Info=1&Table=Funding", 'black', ['newwin'] ) . '<BR>' . popup_menu( -name => 'FUNDING FK_Funding__Code', -values => \@fund_options, -default => '' );

    ####### note make sure to include custom edit in DB_Record to include search for FUNDING FK_Funding__Code in 'Search' subroutine..
    $Order_Records->Set_Option( $option1,      1, 'include' );
    $Order_Records->Set_Option( $pick_funding, 2, 'include' );    ### even non-advanced view..
    $Order_Records->{OrderBy}  = 'Orders_ID';
    $Order_Records->{OrderDir} = 'DESC';

    if ( $Order_Records->DB_Record_Viewer() ) {
        return 1;
    }
    else { return 0; }
    return 1;
}

#####################
sub Orders_Icons {
#####################
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc};
    my $homelink = $dbc->homelink();

    print "<Table cellspacing=0 cellpadding =3 border=0><TR align=center><TD>";
    print "\n<A Href='$homelink'><Img src='/SDB/images/png/stripe.png' alt = 'Home' align = top border=0 height=20 width=190></A><img src='/SDB/images/png/Space.png' width=100 height=1></TD><TD>";
    print "\n<A Href='$homelink&PageName=Main+Orders&Last+Page=Orders'><Img src='/SDB/images/png/box.png' alt = 'Orders' align=top border=0 height=40 width=40></A><img src='/SDB/images/png/Space.png' width=10 height=1></TD><TD>";
    print "\n<A Href='$homelink&PageName=New+Orders&Last+Page=Orders'><Img src=\"/SDB/images/png/NEW.png\" alt = 'New Order' align = top border=0></A><img src='/SDB/images/png/Space.png' width=10 height=1></TD><TD>";
    print "\n<A Href='$homelink&PageName=Received+Orders&Last+Page=Orders'><Img src=\"/SDB/images/png/full_box.png\" alt = 'Received' align = top border=0 height=40 width=40></A><img src='/SDB/images/png/Space.png' width=100 height=1></TD><TD>";

    print "\n<A Href='$homelink&Main+Contact=1'><Img src=\"/SDB/images/png/contacts.gif\" alt = 'Contacts' align = top border=0 height=32 width=32></A><img src='/SDB/images/png/Space.png' width=10 height=1></TD><TD>";

    print "</TR><TR align=left>";
    print "<TD><BR><span class=small>Barcode Home Page</Span></TD>", "<TD><BR><span class=small>Orders</Span></TD>", "<TD><BR><span class=small>New Order</Span></TD>", "<TD><BR><span class=small>Received</Span></TD>",

        "<TD><BR><span class=small>Contacts</Span></TD>", "</TR></Table>";
    print "\n<HR>";
    return 1;
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
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

$Id: Orders.pm,v 1.9 2004/09/08 23:31:49 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
