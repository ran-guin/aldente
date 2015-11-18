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


use vars qw($opt_v $opt_c $opt_f);

use Getopt::Long;
&GetOptions(
	    'v=s'      => \$opt_v,
        'c' =>\$opt_c,
        'f'=>\$opt_f
);

if ($opt_c) {
    cleanup_stock_catalog();
    exit;
}

if ($opt_f) {
    fix_duplicate_stock_catalog();
    exit;
}

my $stock_id;
my $stock_name;
my $stock_catalog_number;
my $stock_type;
my $stock_source;
my $organization_id;
my $stock_description;
my $stock_size;
my $stock_size_units;
my $barcode_label_id;
my $condition;

my $host  = 'limsdev02';
my $dbase = 'seqdev';
my $login_name = 'cron';
my $login_pass;
my $dbc        = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $login_name, -password => $login_pass,-connect=>0);
$dbc->connect();
########################

#####################create dummy stock_Catalog record 4 all the solutions
#        my $insert_fields = 'Stock_Catalog_Name,Stock_Catalog_Number,Stock_Type,Stock_Source,Stock_Size,Stock_Size_Units,FK_Organization__ID,stock_catalog_description';
#        $stock_type =  $dbc->dbh()->quote('Solution');
#        $stock_size = 1;
#        $stock_size_units = $dbc->dbh()->quote('ml');
#        $stock_catalog_number =  $dbc->dbh()->quote('');
#        $stock_name =  $dbc->dbh()->quote('GSC Made Solution');
#        $stock_source =  $dbc->dbh()->quote('Made in House');
#        $organization_id = 27;
#        $stock_description =  $dbc->dbh()->quote('All the solutions made in house');
    
        
#        my $insert_values = "$stock_name,$stock_catalog_number,$stock_type,$stock_source,$stock_size,$stock_size_units,$organization_id,$stock_description";
      #  my $new_stock_catalog_number = $dbc->Table_append(-table=>'Stock_Catalog',-fields=>$insert_fields,-values=>$insert_values);
                
#        my $result = $dbc->Table_update('Stock','fk_Stock_catalog__id',$new_stock_catalog_number,"where stock_type = 'solution' and fk_stock_catalog__id = 0");
# print "Backfill all solution to dummy stock catalog record: $result";

######################

my $cond = "where fk_stock_catalog__id = 0 and (Stock_Source <> 'Made in House' or FK_Organization__ID <> 27) and (not(fk_organization__id is null)) and stock_name <>''"; #A

my @fields = qw(Stock_Catalog_Name Stock_Description Stock_Catalog_Number Stock_Tye Stock_Source Stock_Size Stock_Size_Units FK_Organization__ID);

my $Table_Name= 'Stock';
my @fields = ('Stock_ID','Stock_Name', 'Stock_Description', 'Stock_Catalog_Number', 'Stock_Type','Stock_Source', 'FK_Organization__ID','Stock_Size','Stock_Size_Units');

my %values = $dbc->Table_retrieve($Table_Name,\@fields,$cond,-debug=>1);
###############################33
my $i = 0;
my $match = 0;
my $match_no_sc = 0;
my $no_match = 0;
while (defined %values->{'Stock_ID'}[$i]) {
    $stock_id = %values->{'Stock_ID'}[$i];
    $stock_name = $dbc->dbh()->quote(%values->{'Stock_Name'}[$i]);
    $stock_catalog_number = $dbc->dbh()->quote(%values->{'Stock_Catalog_Number'}[$i]);
         
    $stock_type = $dbc->dbh()->quote(%values->{'Stock_Type'}[$i]);
    $stock_source = $dbc->dbh()->quote(%values->{'Stock_Source'}[$i]);
    $organization_id = %values->{'FK_Organization__ID'}[$i];
    #    $barcode_label_id = %values->{'FK_barcode_label__ID'}[$i];

    $stock_description =  $dbc->dbh()->quote(%values->{'Stock_Description'}[$i]);
    $stock_size =  %values->{'Stock_Size'}[$i];
    my $lower = $stock_size -1;
    my $upper = $stock_size + 1 ;
    $stock_size_units =  $dbc->dbh()->quote(%values->{'Stock_Size_Units'}[$i]); 
    $condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_catalog_name = $stock_name"; # and stock_catalog_number = $stock_catalog_number";

    my $insert_fields = 'Stock_Catalog_Name,Stock_Catalog_Number,Stock_Type,Stock_Source,Stock_Size,Stock_Size_Units,FK_Organization__ID,stock_catalog_description';

    my $insert_values = "$stock_name,$stock_catalog_number,$stock_type,$stock_source,$stock_size,$stock_size_units,$organization_id,$stock_description";

    #    if ($barcode_label_id) {#
     #       $insert_values.=",$barcode_label_id";
     #       $insert_fields.=',fk_barcode_label__id';
      #  }


    if (($stock_type eq 'Reagent') || ($stock_type eq 'Solution')  || ($stock_type eq 'Primer')  || ($stock_type eq 'Buffer')  || ($stock_type eq 'Matrix')) {
        # volume must match
	$condition .= " and (stock_size between $lower and $upper)  and stock_size_units = $stock_size_units";    
    }
    my $new_cond = $condition;
    if ($stock_catalog_number ne '') {
	$new_cond .=" and stock_catalog_number = $stock_catalog_number";
    }

    my @stock_catalog_ids = $dbc->Table_find( 'Stock_Catalog','Stock_catalog_id',$new_cond,-debug=>1);
    
    my $count = scalar(@stock_catalog_ids) ;
    if ($count == 0) {
	# do same search as above but this time w/o stock_catalog_number
	my @stock_catalog_ids = $dbc->Table_find( 'Stock_Catalog','Stock_catalog_id',"$condition",-debug=>1);
        
	my $new_count = scalar(@stock_catalog_ids) ;
	if ($new_count == 0) {
	    #add the record
#            print "exact match found for the Stock w/ id = $stock_id, stock_catalog_id: $new_stock_catalog_number\n";
	    my $new_stock_catalog_number = $dbc->Table_append(-table=>'Stock_Catalog',-fields=>$insert_fields,-values=>$insert_values);
	    
	    my $result = $dbc->Table_update('Stock','fk_Stock_catalog__id',$new_stock_catalog_number,"where stock_id = $stock_id");
	    
	    $match_no_sc++;

	}
	elsif ($new_count ==1) {
	    #use this record
	    my $new_stock_catalog_number = $dbc->dbh()->quote($stock_catalog_ids[0]);
	    my $result = $dbc->Table_update('Stock','fk_Stock_catalog__id',$new_stock_catalog_number,"where stock_id = $stock_id");
	    $match++;
	    
	}
	elsif ($new_count>1) {
	    print "There is $new_count match for the following Stock_Catalog record\nstockid (w/o matching stock_catlog_no): $stock_id\nstock_name: $stock_name\nstock_type: $stock_type\nstock_src: $stock_source\norg_id: $organization_id\nstock_desc: $stock_description\n";
	    my $new_stock_catalog_number = $dbc->dbh()->quote($stock_catalog_ids[0]);
	    my $result = $dbc->Table_update('Stock','fk_Stock_catalog__id',$new_stock_catalog_number,"where stock_id = $stock_id");
	    
	    $no_match++;

	}

    }
    elsif ($count == 1) {
	#use this record
	my $new_stock_catalog_number = $dbc->dbh()->quote($stock_catalog_ids[0]);
	my $result = $dbc->Table_update('Stock','fk_Stock_catalog__id',$new_stock_catalog_number,"where stock_id = $stock_id");
	$match++;

    }
    elsif ($count>1) {
	print "There is $count match for the following Stock_Catalog record\nstockid: $stock_id\nstock_name: $stock_name\nstock_catalog_no: $stock_catalog_number\nstock_type: $stock_type\nstock_src: $stock_source\norg_id: $organization_id\nstock_desc: $stock_description\n";
	
# just use the 1st one
	my $new_stock_catalog_number = $dbc->dbh()->quote($stock_catalog_ids[0]);
	my $result = $dbc->Table_update('Stock','fk_Stock_catalog__id',$new_stock_catalog_number,"where stock_id = $stock_id");

	$no_match++;

    }

    $i++;

}
print "Total records examined: $i, $match has exact match, $no_match doesn't\n";


######################

my $cond = "where fk_stock_catalog__id = 0 and Stock_Source = 'Made in House' AND FK_Organization__ID = 27 and (not(fk_organization__id is null)) and stock_name <>''"; #A

my @fields = qw(Stock_Catalog_Name Stock_Description Stock_Catalog_Number Stock_Tye Stock_Source Stock_Size Stock_Size_Units FK_Organization__ID);

my $Table_Name= 'Stock';
my @fields = ('Stock_ID','Stock_Name', 'Stock_Description', 'Stock_Catalog_Number', 'Stock_Type','Stock_Source', 'FK_Organization__ID','Stock_Size','Stock_Size_Units');

my %values = $dbc->Table_retrieve($Table_Name,\@fields,$cond,-debug=>1);

###############################33
my $i = 0;
my $match = 0;
my $match_no_sc = 0;
my $no_match = 0;
while (defined %values->{'Stock_ID'}[$i]) {
    $stock_id = %values->{'Stock_ID'}[$i];
    $stock_name = $dbc->dbh()->quote(%values->{'Stock_Name'}[$i]);
    $stock_catalog_number = $dbc->dbh()->quote(%values->{'Stock_Catalog_Number'}[$i]);
    
    $stock_type = $dbc->dbh()->quote(%values->{'Stock_Type'}[$i]);
    $stock_source = $dbc->dbh()->quote(%values->{'Stock_Source'}[$i]);
    $organization_id = %values->{'FK_Organization__ID'}[$i];
    #    $barcode_label_id = %values->{'FK_barcode_label__ID'}[$i];
    
    $stock_description =  $dbc->dbh()->quote(%values->{'Stock_Description'}[$i]);
    $condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_catalog_name = $stock_name"; # and stock_catalog_number = $stock_catalog_number";

    my $insert_fields = 'Stock_Catalog_Name,Stock_Catalog_Number,Stock_Type,Stock_Source,Stock_Size,Stock_Size_Units,FK_Organization__ID,stock_catalog_description';

    my $insert_values = "$stock_name,$stock_catalog_number,$stock_type,$stock_source,'undef','n/a',$organization_id,$stock_description";

    #    if ($barcode_label_id) {#
     #       $insert_values.=",$barcode_label_id";
     #       $insert_fields.=',fk_barcode_label__id';
      #  }


    if (($stock_type eq 'Reagent') || ($stock_type eq 'Solution')  || ($stock_type eq 'Primer')  || ($stock_type eq 'Buffer')  || ($stock_type eq 'Matrix')) {
        # volume must match
	#   $condition .= " and (stock_size between $lower and $upper)  and stock_size_units = $stock_size_units";    
    }
    my $new_cond = $condition;
    if ($stock_catalog_number ne '') {
	$new_cond .=" and stock_catalog_number = $stock_catalog_number";
    }

    my @stock_catalog_ids = $dbc->Table_find( 'Stock_Catalog','Stock_catalog_id',$new_cond,-debug=>1);
    
    my $count = scalar(@stock_catalog_ids) ;
    if ($count == 0) {
	# do same search as above but this time w/o stock_catalog_number
	my @stock_catalog_ids = $dbc->Table_find( 'Stock_Catalog','Stock_catalog_id',"$condition",-debug=>1);
        
	my $new_count = scalar(@stock_catalog_ids) ;
	if ($new_count == 0) {
	    #add the record
#            print "exact match found for the Stock w/ id = $stock_id, stock_catalog_id: $new_stock_catalog_number\n";
	    my $new_stock_catalog_number = $dbc->Table_append(-table=>'Stock_Catalog',-fields=>$insert_fields,-values=>$insert_values);
                
	    my $result = $dbc->Table_update('Stock','fk_Stock_catalog__id',$new_stock_catalog_number,"where stock_id = $stock_id");
	    
	    $match_no_sc++;

	}
	elsif ($new_count ==1) {
	    #use this record
	    my $new_stock_catalog_number = $dbc->dbh()->quote($stock_catalog_ids[0]);
	    my $result = $dbc->Table_update('Stock','fk_Stock_catalog__id',$new_stock_catalog_number,"where stock_id = $stock_id");
	    $match++;
	    
	}
	elsif ($new_count>1) {
	    print "There is $new_count match for the following Stock_Catalog record\nstockid (w/o matching stock_catlog_no): $stock_id\nstock_name: $stock_name\nstock_type: $stock_type\nstock_src: $stock_source\norg_id: $organization_id\nstock_desc: $stock_description\n";
	    my $new_stock_catalog_number = $dbc->dbh()->quote($stock_catalog_ids[0]);
	    my $result = $dbc->Table_update('Stock','fk_Stock_catalog__id',$new_stock_catalog_number,"where stock_id = $stock_id");
	    
	    $no_match++;

	}

    }
    elsif ($count == 1) {
	#use this record
	my $new_stock_catalog_number = $dbc->dbh()->quote($stock_catalog_ids[0]);
	my $result = $dbc->Table_update('Stock','fk_Stock_catalog__id',$new_stock_catalog_number,"where stock_id = $stock_id");
	$match++;

    }
    elsif ($count>1) {
	print "There is $count match for the following Stock_Catalog record\nstockid: $stock_id\nstock_name: $stock_name\nstock_catalog_no: $stock_catalog_number\nstock_type: $stock_type\nstock_src: $stock_source\norg_id: $organization_id\nstock_desc: $stock_description\n";
	
# just use the 1st one
	my $new_stock_catalog_number = $dbc->dbh()->quote($stock_catalog_ids[0]);
	my $result = $dbc->Table_update('Stock','fk_Stock_catalog__id',$new_stock_catalog_number,"where stock_id = $stock_id");
	
	$no_match++;

    }

    $i++;

}
print "Total records examined: $i, $match has exact match, $no_match doesn't\n";

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

sub fix_duplicate_stock_catalog {

    change_stock_catalog_id(-old_ids=>"417",-new_id=>359);
    change_stock_catalog_id(-old_ids=>"597",-new_id=>596);
    change_stock_catalog_id(-old_ids=>"1478",-new_id=>1622);
    change_stock_catalog_id(-old_ids=>"1467,1620,1622",-new_id=>1466);
    change_stock_catalog_id(-old_ids=>"895",-new_id=>427);
    change_stock_catalog_id(-old_ids=>"896",-new_id=>428);
    change_stock_catalog_id(-old_ids=>"894",-new_id=>431);
    change_stock_catalog_id(-old_ids=>"893",-new_id=>430);
    change_stock_catalog_id(-old_ids=>"900",-new_id=>429);
    change_stock_catalog_id(-old_ids=>"898",-new_id=>433);
    change_stock_catalog_id(-old_ids=>"899",-new_id=>432);
    change_stock_catalog_id(-old_ids=>"2193",-new_id=>301);
    change_stock_catalog_id(-old_ids=>"1502",-new_id=>1944);
=begin
    change_stock_catalog_id(-old_ids=>"1988,1989,1990,1991,1992",-new_id=>1987);
    change_stock_catalog_id(-old_ids=>"1568",-new_id=>1567);
    change_stock_catalog_id(-old_ids=>"1571",-new_id=>1569);
    change_stock_catalog_id(-old_ids=>"2033",-new_id=>2032);
    change_stock_catalog_id(-old_ids=>"1947",-new_id=>1946);
    change_stock_catalog_id(-old_ids=>"1962,1963",-new_id=>1961);
    change_stock_catalog_id(-old_ids=>"2159",-new_id=>2160);
    change_stock_catalog_id(-old_ids=>"1887",-new_id=>1886);
    change_stock_catalog_id(-old_ids=>"788,789,790",-new_id=>787);
    change_stock_catalog_id(-old_ids=>"258,2025",-new_id=>251);
    change_stock_catalog_id(-old_ids=>"2177",-new_id=>2176);
    change_stock_catalog_id(-old_ids=>"261",-new_id=>260);
    change_stock_catalog_id(-old_ids=>"1811,1812,1813",-new_id=>1810);
    change_stock_catalog_id(-old_ids=>"411",-new_id=>371);
    change_stock_catalog_id(-old_ids=>"307",-new_id=>1661);
=cut
 
#martix
    change_stock_catalog_id(-old_ids=>"203",-new_id=>221);
    change_stock_catalog_id(-old_ids=>"78",-new_id=>79);
    change_stock_catalog_id(-old_ids=>"910",-new_id=>350);
    
# solution
    change_stock_catalog_id(-old_ids=>"1600",-new_id=>1902);
    change_stock_catalog_id(-old_ids=>"1614",-new_id=>2208);
    change_stock_catalog_id(-old_ids=>"521",-new_id=>519);

#equipment
=begin
    change_stock_catalog_id(-old_ids=>"770",-new_id=>769);
    change_stock_catalog_id(-old_ids=>"772",-new_id=>771);
    change_stock_catalog_id(-old_ids=>"792",-new_id=>376);
    change_stock_catalog_id(-old_ids=>"791",-new_id=>375);
    change_stock_catalog_id(-old_ids=>"2075",-new_id=>2076);
    change_stock_catalog_id(-old_ids=>"1873,1874,1875,1876,1877",-new_id=>1872);
    change_stock_catalog_id(-old_ids=>"1793",-new_id=>1797);
    change_stock_catalog_id(-old_ids=>"1799",-new_id=>1800);
=cut

#buffer
    change_stock_catalog_id(-old_ids=>"609",-new_id=>589);
    change_stock_catalog_id(-old_ids=>"447",-new_id=>733);
    change_stock_catalog_id(-old_ids=>"84",-new_id=>83);
    change_stock_catalog_id(-old_ids=>"86",-new_id=>85);
    change_stock_catalog_id(-old_ids=>"906,907,908",-new_id=>905);
    change_stock_catalog_id(-old_ids=>"912",-new_id=>911);
    change_stock_catalog_id(-old_ids=>"1106",-new_id=>1105);
    change_stock_catalog_id(-old_ids=>"415",-new_id=>1285);
    change_stock_catalog_id(-old_ids=>"591",-new_id=>983);
    change_stock_catalog_id(-old_ids=>"171",-new_id=>193);
    change_stock_catalog_id(-old_ids=>"290",-new_id=>909);
    change_stock_catalog_id(-old_ids=>"479",-new_id=>757);
    change_stock_catalog_id(-old_ids=>"1512",-new_id=>486);
    change_stock_catalog_id(-old_ids=>"1295",-new_id=>1294);
    change_stock_catalog_id(-old_ids=>"471",-new_id=>470);
    change_stock_catalog_id(-old_ids=>"478,987",-new_id=>723);


}

sub change_stock_catalog_id {
    my %args = @_;
    my $old_stock_catalog_ids = $args{-old_ids};
    my $new_stock_catalog_id = $args{-new_id};
    
    my $host  = 'limsdev02';
    my $dbase = 'seqdev';
    my $login_name = 'cron';
    my $login_pass;
    my $dbc        = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $login_name, -password => $login_pass,-connect=>0);
$dbc->connect();

    #update all the stock records with the stock_catalog_ids in old_stock_catalog_ids
    my @ids = $dbc->Table_update("Stock","fk_stock_catalog__id",$new_stock_catalog_id,"where fk_stock_catalog__id in ($old_stock_catalog_ids)",-debug=>1);

    #delete all the stock catalog records w/ the old ids   
    my $ok = $dbc->delete_records(-table=>'Stock_Catalog',-dfield=>'stock_catalog_id',-id_list=>$old_stock_catalog_ids);

}
