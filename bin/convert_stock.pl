#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################
#
# convert_stock.pl
#
# This script convert all the entries in the Stock table into the new Stock table and back fills the Stock_Catalog table.  
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
use vars qw(%Defaults);  ## std defaults (eg SOC_MEDIA_QTY)


use vars qw($opt_v $opt_c);

use Getopt::Long;
&GetOptions(
	    'v=s'      => \$opt_v,
        'c' =>\$opt_c
);

if ($opt_c) {
    cleanup_stock_catalog();
    exit;
}
my $host  = 'limsdev02';
my $dbase = 'seqdev';
my $login_name = 'cron';
my $login_pass;
my $dbc        = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $login_name, -password => $login_pass,-connect=>0);
$dbc->connect();
# extra condition for
#my $cond = "where fk_stock_catalog__id = 0 and (not(stock_name is null)) and (not(stock_source is null))"; 
#my $cond = "where stock_type <> 'Solution' and fk_stock_catalog__id = 0"; 
my $cond = "where fk_stock_catalog__id = 0"; #A

my @fields = qw(Stock_Catalog_Name Stock_Description Stock_Catalog_Number Stock_Tye Stock_Source Stock_Size Stock_Size_Units FK_Organization__ID);
my $condition;
my $distinct;
my $Table_Name= 'Stock';
my @fields = ('Stock_ID','Stock_Name', 'Stock_Description', 'Stock_Catalog_Number', 'Stock_Type','Stock_Source', 'FK_Organization__ID','Stock_Size','Stock_Size_Units');
my $stock_id;
my $stock_name;
my $stock_catalog_number;
my $stock_type;
my $stock_source;
my $organization_id;
my $stock_description;
my $stock_size;
my $stock_size_units;


# run the following in order
if ($opt_v == 1) {
    $cond .=" and not(fk_organization__id is null) and stock_name <>'' and not (stock_size is null) and stock_size <>'' and stock_size_units <>'' and not (stock_size_units is null) and stock_catalog_number <>''";
  $condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_catalog_name = $stock_name and stock_catalog_number = $stock_catalog_number and (stock_size between $stock_size - 1 and $stock_size + 1) and stock_size_units = $stock_size_units";
}
# no stock catalog number
if ($opt_v == 2) {
    $cond .=" and not(fk_organization__id is null) and stock_name <>'' and not (stock_size is null) and stock_size <>'' and stock_size_units <>'' and not (stock_size_units is null)";
          $condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source andd stock_catalog_name = $stock_name and (stock_size between $stock_size - 1 and $stock_size + 1)  and stock_size_units = $stock_size_units";

}

if ($opt_v == 3) {
# exclude organization__id
    $cond .=" and stock_name <>'' and not (stock_size is null) and stock_size <>'' and stock_size_units <>'' and not (stock_size_units is null) and stock_catalog_number <>''";

     $condition = "where stock_type = $stock_type and stock_source = $stock_source and stock_catalog_name = $stock_name and stock_catalog_number = $stock_catalog_number and (stock_size between $stock_size - 1 and $stock_size + 1)  and stock_size_units = $stock_size_units";
}

# no stock units
if ($opt_v == 4) {
    $cond .=" and not(stock_type in ('Solution','Reagent','Buffer','Primer','Matrix')) and not(fk_organization__id is null) and stock_name <>'' and not (stock_size is null) and stock_size <>''  and stock_catalog_number <>''";

     $condition ="where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_catalog_name = $stock_name and stock_catalog_number = $stock_catalog_number and (stock_size between $stock_size - 1 and $stock_size + 1)";
}

if ($opt_v == 5) {
    $cond .=" and not(stock_type in ('Solution','Reagent','Buffer','Primer','Matrix')) and not(fk_organization__id is null) and stock_name <>'' and stock_size_units <>'' and not (stock_size_units is null) and stock_catalog_number <>''";

# no stock size
     $condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_catalog_name = $stock_name and stock_catalog_number = $stock_catalog_number and stock_size_units = $stock_size_units";
}

if ($opt_v == 6) {
    $cond .=" and not(stock_type in ('Solution','Reagent','Buffer','Primer','Matrix')) and not(fk_organization__id is null) and stock_name <>'' and stock_catalog_number <>''";


# for things other than solution,reagent,primer,buffer,matrix stock_size & unit don't matter (A)
     $condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_catalog_name = $stock_name and stock_catalog_number = $stock_catalog_number";
}
# no stock_name
if ($opt_v == 7) {
    $cond .=" and not(fk_organization__id is null) and not (stock_size is null) and stock_size <>'' and stock_size_units <>'' and not (stock_size_units is null) and stock_catalog_number <>''";

  $condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_catalog_number = $stock_catalog_number and stock_size = $stock_size and stock_size_units = $stock_size_units";
}

# fix the 117 records w/ wrong size
if ($opt_v == 8) {
    $cond .=" and not(fk_organization__id is null) and stock_size = 4 and stock_size_units = 'litres' and stock_catalog_number <>''";

  $condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_catalog_number = $stock_catalog_number and stock_size = 4000 and stock_size_units = 'ml'";
}

if ($opt_v == 9) {
    $cond .=" and not(fk_organization__id is null) and stock_size = 4 and stock_size_units = 'litres'";

  $condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_size = 4000 and stock_size_units = 'ml'";
}

if ($condition eq '') { print "invalid condition.  Try again\n"; exit;}
print "\n================= =XStock_Catalog condition ($opt_v): $cond, filter: $condition ===========================\n" ; 

my %values = $dbc->Table_retrieve($Table_Name,\@fields,$cond,-debug=>1);

###############################33
	 my $i = 0;
     my $match = 0;
     my $no_match = 0;
	 while (defined %values->{'Stock_ID'}[$i]) {
         $stock_id = %values->{'Stock_ID'}[$i];
         $stock_name = $dbc->dbh()->quote(%values->{'Stock_Name'}[$i]);
         $stock_catalog_number = $dbc->dbh()->quote(%values->{'Stock_Catalog_Number'}[$i]);
         $stock_type = $dbc->dbh()->quote(%values->{'Stock_Type'}[$i]);
         $stock_source = $dbc->dbh()->quote(%values->{'Stock_Source'}[$i]);
         $organization_id = %values->{'FK_Organization__ID'}[$i];
	     $stock_description =  $dbc->dbh()->quote(%values->{'Stock_Description'}[$i]);
         $stock_size =  %values->{'Stock_Size'}[$i];
         my $lower = $stock_size -1;
         my $upper = $stock_size + 1 ;
         $stock_size_units =  $dbc->dbh()->quote(%values->{'Stock_Size_Units'}[$i]); 

        if ($opt_v == 1) {
            $condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_catalog_name = $stock_name and stock_catalog_number = $stock_catalog_number and (stock_size between $lower and $upper)  and stock_size_units = $stock_size_units";
        } elsif ($opt_v ==2) {

          $condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_catalog_name = $stock_name and (stock_size between  $lower and $upper) and stock_size_units = $stock_size_units";
        }

        elsif ($opt_v == 3) {
# exclude organization__id

         $condition = "where stock_type = $stock_type and stock_source = $stock_source and stock_catalog_name = $stock_name and stock_catalog_number = $stock_catalog_number and (stock_size between  $lower and $upper) and stock_size_units = $stock_size_units";
        }

    # no stock units
    elsif ($opt_v == 4) {

        $condition ="where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_catalog_name = $stock_name and stock_catalog_number = $stock_catalog_number and (stock_size between  $lower and $upper)";
    }

    elsif ($opt_v == 5) {

        # no stock size
         $condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_catalog_name = $stock_name and stock_catalog_number = $stock_catalog_number and stock_size_units = $stock_size_units";
}

    elsif ($opt_v == 6) {


    # for things other than solution,reagent,primer,buffer,matrix stock_size & unit don't matter (A)
         $condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_catalog_name = $stock_name and stock_catalog_number = $stock_catalog_number";
    }
# no stock_name
    elsif ($opt_v == 7) {

        $condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_catalog_number = $stock_catalog_number and (stock_size between $lower and $upper) and stock_size_units = $stock_size_units";
    }   
    elsif ($opt_v == 8) {

  $condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_catalog_number = $stock_catalog_number and stock_size = 4000 and stock_size_units = 'ml'";
    }   
    elsif ($opt_v == 9) {

  $condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_size = 4000 and stock_size_units = 'ml'";
    } 
    elsif ($opt_v == 10) {

  $condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_catalog_number = $stock_catalog_number and stock_size = 2000 and stock_size_units = 'grams'";
    }   
    
    
        my @stock_catalog_ids = $dbc->Table_find( 'Stock_Catalog','Stock_catalog_id',$condition,-debug=>1);
print "what's in stock_cat_id array : ".Dumper(@stock_catalog_ids)."\n";        
        my $count = scalar(@stock_catalog_ids) ;
        if ($count == 1) {
            my $new_stock_catalog_number = $dbc->dbh()->quote($stock_catalog_ids[0]);
#            print "exact match found for the Stock w/ id = $stock_id, stock_catalog_id: $new_stock_catalog_number\n";
           my $result = $dbc->Table_update('Stock','fk_Stock_catalog__id',$new_stock_catalog_number,"where stock_id = $stock_id");
            $match++;
        }
        else {
            print "There is $count match for the following Stock_Catalog record\nstockid: $stock_id\nstock_name: $stock_name\nstock_catalog_no: $stock_catalog_number\nstock_type: $stock_type\nstock_src: $stock_source\norg_id: $organization_id\nstock_desc: $stock_description\n";
            $no_match++;

        }
        $i++;

	 }
print "Total records examined: $i, $match has exact match, $no_match doesn't\n";

##############################33

# make the fields in the Stock table mentioned in 1. hidden/obosolete

1;

sub cleanup_stock_catalog {
    my $host  = 'limsdev02';
my $dbase = 'seqdev';
my $login_name = 'cron';
my $login_pass;
my $dbc        = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $login_name, -password => $login_pass,-connect=>0);
$dbc->connect();

my $sql = "select stock_catalog_id from Stock_Catalog S where S.stock_catalog_number = '' and exists (select stock_catalog_id from Stock_Catalog where stock_catalog_name = S.stock_catalog_name and fk_organization__id = S.fk_organization__id and stock_type = S.stock_type and stock_size = S.stock_size and stock_size_units = S.stock_size_units and stock_source = S.stock_source and stock_catalog_number <>'')";

my @ids = $dbc->Table_find("Stock_Catalog S","stock_catalog_id","where S.stock_catalog_number = '' and exists (select stock_catalog_id from Stock_Catalog where stock_catalog_name = S.stock_catalog_name and fk_organization__id = S.fk_organization__id and stock_type = S.stock_type and stock_size = S.stock_size and stock_size_units = S.stock_size_units and stock_source = S.stock_source and stock_catalog_number <>'')",-debug=>1);
print Dumper(@ids);
my $id_list = Cast_List(-list=>\@ids,-to=>'string');
my $ok = $dbc->delete_records(-table=>'Stock_Catalog',-dfield=>'stock_catalog_id',-id_list=>$id_list);
}
