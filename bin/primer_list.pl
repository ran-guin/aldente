#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################
#
# primer_list.pl
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
use alDente::Solution;
use vars qw(%Defaults);  ## std defaults (eg SOC_MEDIA_QTY)


use vars qw($opt_v $opt_c $opt_f);

use Getopt::Long;
&GetOptions(
	    'v=s'      => \$opt_v,
        'c' =>\$opt_c,
        'f'=>\$opt_f
);

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
print "Script starts\n";
    my $file_name = "/home/alanl/final_list.csv" ;
    open my $FILE,'>>', $file_name or die("can't open file $file_name");
     print $FILE "Primer Name,Last Used Date,Last Used By,Protocol\n";

#####################create dummy stock_Catalog record 4 all the solutions
my @primer_names = $dbc->Table_find('Primer','Primer_Name',"where primer_type = 'Standard' and primer_status <>'Inactive'");

foreach my $primer_name (@primer_names) {
#    my $solution_obj = alDente::Solution->new(-id=>$solution_id,-dbc=>$dbc);
    my @soln_ids = $dbc->Table_find('Stock,Solution,Stock_Catalog','Solution_ID',"where stock_catalog_name = '$primer_name' and fk_stock__id = stock_id and FK_Stock_Catalog__ID = Stock_Catalog_ID");
    my $soln_id_list = Cast_List(-list=>\@soln_ids,-to=>'string',-delimiter=>',');
    my @all_solutions = alDente::Solution::get_downstream_solutions($dbc,$soln_id_list);
    my $solutions_list = Cast_List(-list=>\@all_solutions,-to=>'string',-delimiter=>',');
    if ($solutions_list) {
    #Q: each of the solutions will have some
        my ($result) = $dbc->Table_find('Plate_Prep,Prep,Employee,Lab_Protocol','prep_datetime,employee_name,lab_protocol_name',"where fk_solution__id in ($solutions_list) and prep_id = fk_prep__id and employee_id = Prep.fk_employee__id and lab_protocol_id = fk_lab_protocol__id order by prep_datetime desc limit 1");

        my ($prep_date,$employee_name,$protocol_name) = split(/,/, $result);
        print $FILE "$primer_name,$employee_name,$protocol_name\n";
    }
}
close $FILE;
print "Script completed\n";
    # want to see the lab_protocol too that's why we need to use lab_protocol table

1;


