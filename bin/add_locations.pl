#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################
#
##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
################################################################################

use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use Data::Dumper;
use Getopt::Std;

use RGTools::RGIO;
use SDB::DBIO;
use alDente::SDB_Defaults;
use vars qw(%Defaults);    ## std defaults (eg SOC_MEDIA_QTY)
use vars qw($opt_v $opt_c $opt_f);

use Getopt::Long;
&GetOptions(
    'v=s' => \$opt_v,
    'c'   => \$opt_c,
    'f'   => \$opt_f
);

if ($opt_c) {
    exit;
}

if ($opt_f) {
    exit;
}

my $host       = 'limsdev02';
my $dbase      = 'seqdev';
my $login_name = 'super_cron_user';

my $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $login_name, -connect => 0 );
$dbc->connect();

my $date_time = &date_time();
$date_time =~ /(.*) (.*)/;
my $date = $1;

## Equipment Category Record
my @category_fields = qw (Category  Sub_Category    Prefix);
my @category_values = qw (Storage   Virtual         Store);
my $Category_ID     = $dbc->Table_append_array( 'Equipment_Category', \@category_fields, \@category_values, -autoquote => 1 );

# print "Adding Category ID = $Category_ID\n\n";

## Stock Catalog Record
my $description    = 'This is a virtual storage.  ';
my @catalog_fields = qw (Stock_Catalog_Name            Stock_Type      Stock_Source    Stock_Size  Stock_Size_Units    FK_Organization__ID    Stock_Status        FK_Equipment_Category__ID);
my @catalog_values = ( 'Virtual Storage', 'Equipment', 'Order', 1, 'pcs', 27, 'Active', $Category_ID );
my $SC_ID          = $dbc->Table_append_array( 'Stock_Catalog', \@catalog_fields, \@catalog_values, -autoquote => 1 );

# print "Adding Catalog ID= $SC_ID\n\n";

## Stock Record
my @stock_fields = qw (FK_Employee__ID Stock_Received  Stock_Number_in_Batch   FK_Grp__ID  FK_Barcode_Label__ID    FK_Stock_Catalog__ID);
my @stock_values = ( 331, $date, 1, 1, 10, $SC_ID );
my $stock_ID     = $dbc->Table_append_array( 'Stock', \@stock_fields, \@stock_values, -autoquote => 1 );

# print "Adding Stock Record ID = $stock_ID\n\n";

## Getting all current location and creating equipment for each

my @location_info = $dbc->Table_find( -table => 'Location', -fields => "Location_ID, Location_Name" );

my $counter = 1;
for my $info (@location_info) {
    my ( $location_id, $location_name, $location_details ) = split ',', $info;
    $location_name .= ",$location_details" if $location_details;
    my ( $prefix, $index ) = _get_equipment_name( -category_id => $Category_ID, -dbc => $dbc );
    my $equipment_name = "$prefix-$index";

    # print "$equipment_name\n";

    my @equipment_fields = qw (Equipment_Name     Equipment_Status    FK_Location__ID FK_Stock__ID    Equipment_Comments                      FK_Equipment_Category__ID);
    my @equipment_values = ( $equipment_name, 'In Use', $location_id, $stock_ID, "virtual equipment for $location_name", $Category_ID );
    my $equipment_ID     = $dbc->Table_append_array( 'Equipment', \@equipment_fields, \@equipment_values, -autoquote => 1 );

    #   print "Adding Equipment ID = $equipment_ID\n" if $equipment_ID ;

    my @rack_fields = qw (Rack_Type       Rack_Name               Rack_Alias          Movable     FK_Equipment__ID);
    my @rack_values = ( 'Shelf', "VS-$equipment_name", "$location_name", 'N', $equipment_ID );
    my $rack_ID     = $dbc->Table_append_array( 'Rack', \@rack_fields, \@rack_values, -autoquote => 1 );

    #  print "Adding Rack ID = $rack_ID\n\n" if $rack_ID;

    $counter++;
}

1;
##########################
sub _get_equipment_name {
##########################
    my %args        = &filter_input( \@_ );
    my $dbc         = $args{-dbc};
    my $category_id = $args{-category_id};

    my $command = "Concat(Max(Replace(Equipment_Name,concat(Prefix,'-'),'') + 1)) as Next_Name";
    my ($name) = $dbc->Table_find_array( 'Equipment_Category', -fields => ['Prefix'], -condition => "WHERE Equipment_Category_ID=$category_id" );
    my ($number) = $dbc->Table_find_array( 'Equipment,Equipment_Category', [$command], "WHERE FK_Equipment_Category__ID=Equipment_Category_ID AND Equipment_Category_ID=$category_id" );
    unless ($number) { $number = 1 }
    return ( $name, $number );
}
