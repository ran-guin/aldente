<SCHEMA>
## Schema updates for the GSC

alter table Equipment modify  Equipment_Location enum('Sequence Lab','Chromos','CDC','CRC','Functional Genomics','Linen','GE Lab','GE Lab - RNA area','GE Lab - DITAG area','Mapping Lab','MGC Lab') null  default NULL;

CREATE TABLE `Genome` (
  `Genome_ID` int NOT NULL auto_increment,
  `FK_Taxonomy__ID` int NOT NULL,
  `Genome_Path` varchar(80) default NULL,
  `Genome_Type` enum('Genome','Transcriptome') default 'Genome',
  `Genome_Name` varchar(40) default NULL,
  PRIMARY KEY  (`Genome_ID`)
) ENGINE=InnoDB;
ALTER TABLE SolexaAnalysis add FK_Genome__ID int default NULL;

</SCHEMA>
<DATA>
## moved from Core ##
update Equipment, Stock, Grp Set FK_Grp__ID = Grp_ID WHERE FK_Stock__ID = Stock_ID AND Grp_Name = 'Vectorology' AND Equipment_ID IN (1772,1413,1722,1724,877,1327,1723,1762,1597,1598,1599,637,687,1215,698,696,697,216,832,1891,1703,1704,1092,1094,1088,1097,1090,1091,1095,1099,1093,1096,1098,1089);
update Equipment, Stock, Grp Set FK_Grp__ID = Grp_ID WHERE FK_Stock__ID = Stock_ID AND Grp_Name = 'QC'     AND Equipment_ID IN (508,1683);
update Equipment, Stock, Grp Set FK_Grp__ID = Grp_ID WHERE FK_Stock__ID = Stock_ID AND Grp_Name = 'Gene Expression Base' AND Equipment_ID IN (1701,282,292,293,307,306,308,311,280,309,1770,285,876,1142,284,279,283);
update Equipment, Stock, Grp Set FK_Grp__ID = Grp_ID WHERE FK_Stock__ID = Stock_ID AND Grp_Name = 'Mapping Base'   AND Equipment_ID IN (56,1185,1154,794,498,1057,208,1198,176,1199,167,1085,1196);
update Equipment, Stock, Grp Set FK_Grp__ID = Grp_ID WHERE FK_Stock__ID = Stock_ID AND Grp_Name = 'MGC_Closure' AND Equipment_ID IN (882,13,14,398,79,25,22,8,68,168,137,202,1100,278,865,829,1032);
update Equipment, Stock, Grp Set FK_Grp__ID = Grp_ID WHERE FK_Stock__ID = Stock_ID AND Grp_Name = 'Brain Research'  AND Equipment_ID IN (702,215);
update Equipment, Stock, Grp Set FK_Grp__ID = Grp_ID WHERE FK_Stock__ID = Stock_ID AND Grp_Name = 'Programmed Cell Death (PCD)' AND Equipment_ID IN (55);
update Equipment, Stock, Grp Set FK_Grp__ID = Grp_ID WHERE FK_Stock__ID = Stock_ID AND Grp_Name = 'Microarray' AND Equipment_ID IN (310,1324,367,1325,281);
update Equipment, Stock, Grp Set FK_Grp__ID = Grp_ID WHERE FK_Stock__ID = Stock_ID AND Grp_Name = 'Proteomics' AND Equipment_ID IN (201,816,843,617);

INSERT INTO Department (Department_Name,Department_Status) values ('Projects_Admin','Active');
INSERT INTO Grp (Grp_Name,FK_Department__ID,Access) values ('Projects_Admin',10,'Admin');

UPDATE Employee,Department SET FK_Department__ID=Department_ID WHERE Department_Name = 'Projects_Admin' AND Employee_Name IN ('Robyn','dmiller','Joanne','JJohnson','Cecilia');

## Stock entries

UPDATE Stock, Stock_Catalog set Stock.fk_stock_catalog__id = Stock_Catalog.stock_catalog_id where Stock.stock_name  = 'Long SAGE Ditag PCR Module' and Stock_Catalog.stock_catalog_name = Stock.stock_name and  Stock.fk_organization__id = 47 and Stock_Catalog.fk_organization__id = Stock.fk_organization__id and Stock.stock_type = 'box' and Stock_Catalog.stock_type = Stock.stock_type and Stock.fk_stock_catalog__id = 0;

Update Stock, Stock_Catalog set Stock.fk_stock_catalog__id = Stock_Catalog.stock_catalog_id where Stock.stock_name  = 'Long SAGE Ditag PCR Module' and Stock_Catalog.stock_catalog_name = Stock.stock_name and  Stock.fk_organization__id = 100 and Stock_Catalog.fk_organization__id = Stock.fk_organization__id and Stock.stock_type = 'box' and Stock_Catalog.stock_type = Stock.stock_type and Stock.fk_stock_catalog__id = 0;


update Stock, Stock_Catalog set Stock.fk_stock_catalog__id = Stock_Catalog.stock_catalog_id where Stock.stock_name  = 'I-SAGE cDNA Synthesis +4' and Stock_Catalog.stock_catalog_name = Stock.stock_name and  Stock.fk_organization__id = 47 and Stock_Catalog.fk_organization__id = Stock.fk_organization__id and Stock.stock_type = 'box' and Stock_Catalog.stock_type = Stock.stock_type and Stock.fk_stock_catalog__id = 0;


uPdate Stock, Stock_Catalog set Stock.fk_stock_catalog__id = Stock_Catalog.stock_catalog_id where Stock.stock_name  = 'Big Dye v.3.1 Terminator' and Stock_Catalog.stock_catalog_name = Stock.stock_name and  Stock.fk_organization__id = 44 and Stock_Catalog.fk_organization__id = Stock.fk_organization__id and Stock.stock_type = 'kit' and Stock_Catalog.stock_type = Stock.stock_type and Stock.stock_catalog_number = '4336921' and Stock_Catalog.stock_catalog_number = Stock.stock_catalog_number and Stock.fk_stock_catalog__id = 0;

UPdate Stock, Stock_Catalog set Stock.fk_stock_catalog__id = Stock_Catalog.stock_catalog_id where Stock.stock_name  = 'I-SAGE NlaIII Module' and Stock_Catalog.stock_catalog_name = Stock.stock_name and  Stock.fk_organization__id = 47 and Stock_Catalog.fk_organization__id = Stock.fk_organization__id and Stock.stock_type = 'box' and Stock_Catalog.stock_type = Stock.stock_type and Stock.fk_stock_catalog__id = 0;

upDate Stock, Stock_Catalog set Stock.fk_stock_catalog__id = Stock_Catalog.stock_catalog_id where Stock.stock_name  = 'long SAGE Cleavage Module' and Stock_Catalog.stock_catalog_name = Stock.stock_name and  Stock.fk_organization__id = 47 and Stock_Catalog.fk_organization__id = Stock.fk_organization__id and Stock.stock_type = 'box' and Stock_Catalog.stock_type = Stock.stock_type and Stock.fk_stock_catalog__id = 0;


updAte Stock, Stock_Catalog set Stock.fk_stock_catalog__id = Stock_Catalog.stock_catalog_id where Stock.stock_name  = 'I-SAGE cDNA Synthesis -20' and Stock_Catalog.stock_catalog_name = Stock.stock_name and  Stock.fk_organization__id = 47 and Stock_Catalog.fk_organization__id = Stock.fk_organization__id and Stock.stock_type = 'box' and Stock_Catalog.stock_type = Stock.stock_type and Stock.fk_stock_catalog__id = 0;


updaTe Stock, Stock_Catalog set Stock.fk_stock_catalog__id = Stock_Catalog.stock_catalog_id where Stock.stock_name  = 'long performance check module' and Stock_Catalog.stock_catalog_name = Stock.stock_name and  Stock.fk_organization__id = 47 and Stock_Catalog.fk_organization__id = Stock.fk_organization__id and Stock.stock_type = 'box' and Stock_Catalog.stock_type = Stock.stock_type and Stock.fk_stock_catalog__id = 0;



updatE Stock, Stock_Catalog set Stock.fk_stock_catalog__id = Stock_Catalog.stock_catalog_id where Stock.stock_name  = 'Long SAGE Ditag Formation Module' and Stock_Catalog.stock_catalog_name = Stock.stock_name and  Stock.fk_organization__id = 47 and Stock_Catalog.fk_organization__id = Stock.fk_organization__id and Stock.stock_type = 'box' and Stock_Catalog.stock_type = Stock.stock_type and Stock.fk_stock_catalog__id = 0;


UpdatE Stock, Stock_Catalog set Stock.fk_stock_catalog__id = Stock_Catalog.stock_catalog_id where Stock.stock_name  = 'I-SAGE Concatemer Module' and Stock_Catalog.stock_catalog_name = Stock.stock_name and  Stock.fk_organization__id = 47 and Stock_Catalog.fk_organization__id = Stock.fk_organization__id and Stock.stock_type = 'box' and Stock_Catalog.stock_type = Stock.stock_type and Stock.fk_stock_catalog__id = 0;


update Stock, Stock_Catalog set Stock.fk_stock_catalog__id = Stock_Catalog.stock_catalog_id where Stock.stock_name  = 'Illumina Paired-end Sample Prep Kit' and Stock_Catalog.stock_catalog_name = Stock.stock_name and  Stock.fk_organization__id = 108 and Stock_Catalog.fk_organization__id = Stock.fk_organization__id and Stock.stock_type = 'box' and Stock_Catalog.stock_type = Stock.stock_type and Stock.fk_stock_catalog__id = 0;

UpDATE Stock, Stock_Catalog set Stock.fk_stock_catalog__id = Stock_Catalog.stock_catalog_id where Stock.stock_name  = '10x DNase I Buffer' and Stock_Catalog.stock_catalog_name = Stock.stock_name and  Stock.fk_organization__id = 47 and Stock_Catalog.fk_organization__id = Stock.fk_organization__id and Stock.stock_type = 'box' and Stock_Catalog.stock_type = Stock.stock_type and Stock.fk_stock_catalog__id = 0;

upDATE Stock, Stock_Catalog set Stock.fk_stock_catalog__id = Stock_Catalog.stock_catalog_id where Stock.stock_name  = 'Highspeed Plasmid Maxi Kit' and Stock_Catalog.stock_catalog_name = Stock.stock_name and  Stock.fk_organization__id = 129 and Stock_Catalog.fk_organization__id = Stock.fk_organization__id and Stock.stock_type = 'box' and Stock_Catalog.stock_type = Stock.stock_type and Stock.fk_stock_catalog__id = 0;

UPDate Stock, Stock_Catalog set Stock.fk_stock_catalog__id = Stock_Catalog.stock_catalog_id where Stock.stock_name  = 'DNase I Amplication Grade' and Stock_Catalog.stock_catalog_name = Stock.stock_name and  Stock.fk_organization__id = 47 and Stock_Catalog.fk_organization__id = Stock.fk_organization__id and Stock.stock_type = 'box' and Stock_Catalog.stock_type = Stock.stock_type and Stock.stock_source = 'box' and Stock_Catalog.stock_source = Stock.stock_source and Stock.fk_stock_catalog__id = 0;

#INSERT INTO `Package` VALUES ('','Plugin','y','Genomic','Installed',NULL),('','Plugin','y','Sequencing','Installed',NULL),('','Option','y','Funding_Tracking','Installed',NULL),('','Plugin','y','Fingerprinting','Installed',NULL),('','Plugin','y','Microarray','Installed',NULL),('','Plugin','y','Mapping','Installed',NULL),('','Option','y','Receiving','Installed',NULL),('','Plugin','y','Help','Installed',NULL),('','Option','y','Submissions','Installed',NULL),('','Option','n','Issue_Tracking','Installed',NULL),('','Option','y','Subscriptions','Installed',NULL),('','Option','y','Dynamic_Libraries','Installed',NULL),('','Option','y','Primers','Installed',NULL),('','Option','n','Storage_Tracking','Not installed',NULL),('','Option','y','Vectors','Installed',NULL),('','Plugin','y','SolexaRun','Installed',NULL);

insert into Department (Department_Name, Department_Status) values ('Systems','Active');
insert into Department (Department_Name, Department_Status) values ('Engineering','Active');
insert into Grp (Grp_Name, FK_Department__ID, Access) values ('Systems',11,'Bioinformatics');
insert into Grp (Grp_Name, FK_Department__ID, Access) values ('Engineering',12,'Bioinformatics');
insert into Grp (Grp_Name, FK_Department__ID, Access) values ('Brain Research',7,'Guest');
insert into Grp (Grp_Name, FK_Department__ID, Access) values ('Vectorology',7,'Guest');
insert into Grp_Relationship values ('',13, 35);
INSERT INTO Site (Site_Name) values ('Echelon');
INSERT INTO Site (Site_Name) values ('CRC');
INSERT INTO Site (Site_Name) values ('UBC');
update Location set Location_Name = RIGHT(Location_Name ,Length(Location_name)-6)   WHERE  Location_Name LIKE 'CRC - %';

update Location set Location_type = 'Internal';
update Location set Location_Type = 'External' WHERE Location_Name IN ('7th floor, CG','External');
update Location,Site set FK_Site__ID  = Site_ID WHERE Site_Name = 'Echelon';
update Location,Site set FK_Site__ID  = Site_ID WHERE Site_Name = 'CRC' and (Location_Name like '%7th%' or Location_Name like '%9th%');
update Location,Site set FK_Site__ID  = Site_ID WHERE Site_Name = 'External' and Location_Name = 'External';

update Grp set Grp_Type = 'Production' where Grp_Name like '%Production';
update Grp set Grp_Type = 'TechD' where Grp_Name like '%TechD';
update Grp set Grp_Type = 'Project Admin' where Grp_Name like '%Project Admin';
update Grp set Grp_Type = 'Lab Admin' where Grp_Name like '%Admin' and Grp_Type is null;
update Grp set Grp_Type = 'Lab' where Grp_Name like '%Base' and Grp_Type is null;
update Grp set Grp_Type = 'Technical Support' where Grp_Name in ('Systems','Engineering');
update Grp set Grp_Type = 'Research' where Grp_Name in ('Prostate','Cancer Genetics','Vectorology','Proteomics','Programmed Cell Death (PCD)','Gastrointestinal Cancer (GI)','Genomics','Brain Research');
update Grp set Grp_Type = 'Informatics' where Grp_Name like '%Bioinformatics';
update Grp set Grp_Type = 'Public' where Grp_Name IN ('Public','External');
update Grp set Grp_Type = 'Lab' where Grp_Name IN ('Receiving');
update Grp set Grp_Type = 'Shared' WHERE Grp_Name IN ('Mapping','Sequencing','Gene Expression');
update Grp set Grp_Type = 'QC' where Grp_Name IN ('QC');
update Grp set Grp_Type = 'Purchasing' where Grp_Name IN ('Receiving');
update Grp set Grp_Type = 'Lab' WHERE Grp_Name = 'MGC_Closure';
#update Grp set Access = '' WHERE Access = 'Guest';
#update Grp set Access = 'Guest' WHERE  Grp_type IN ('Lab','Research','Public')
#update Grp set Access = 'Guest'  WHERE Access = '' AND Grp_Name IN ('Projects_Admin')

## add type for mapping
INSERT INTO Work_Request_Type values ('','Fingerprinting','','Active',13,'');
## add type for Replicates 
INSERT INTO Work_Request_Type values ('','Replicates','','Active','','');
</DATA>
<CODE_BLOCK>
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO.
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below


if (_check_block("add_locations")){

	my $date_time = &date_time();
	$date_time =~ /(.*) (.*)/;
	my $date = $1;

	## Equipment Category Record 
	my @category_fields = qw (Category  Sub_Category    Prefix);
	my @category_values = qw (Storage   Virtual         Store);
	my $Category_ID     = $dbc->Table_append_array('Equipment_Category',\@category_fields, \@category_values,-autoquote=>1);
	# print "Adding Category ID = $Category_ID\n\n";

	## Stock Catalog Record
	my $description = 'This is a virtual storage.  ';
	my @catalog_fields  = qw (Stock_Catalog_Name            Stock_Type      Stock_Source    Stock_Size  Stock_Size_Units    FK_Organization__ID    Stock_Status        FK_Equipment_Category__ID);
	my @catalog_values  =    ('Virtual Storage',  'Equipment',    'Order',        1,          'pcs',              27 ,                   'Active',     $Category_ID);     
	my $SC_ID           = $dbc->Table_append_array('Stock_Catalog',\@catalog_fields, \@catalog_values,-autoquote=>1);
	# print "Adding Catalog ID= $SC_ID\n\n";

	## Stock Record
	my ($admin) = $dbc->Table_find('Employee','Employee_ID',"WHERE Employee_Name like '%Admin'"); 
	my @stock_fields    = qw (FK_Employee__ID Stock_Received  Stock_Number_in_Batch   FK_Grp__ID  FK_Barcode_Label__ID    FK_Stock_Catalog__ID);
	my @stock_values    =    ($admin,            $date,          1,                      1,          10 ,                     $SC_ID                 );     
	my $stock_ID        = $dbc->Table_append_array('Stock',\@stock_fields, \@stock_values,-autoquote=>1);
	# print "Adding Stock Record ID = $stock_ID\n\n";

	## Getting all current location and creating equipment for each

	my @location_info =    $dbc->Table_find(-table		=> 'Location',    -fields		=> "Location_ID, Location_Name");

	my $counter= 1;
	for my $info (@location_info) {
    	my ($location_id,$location_name, $location_details) = split ',' , $info;
    	$location_name .= ",$location_details" if $location_details;
    	my ($prefix, $index) =  _get_equipment_name (-category_id   => $Category_ID, -dbc=>$dbc);
    	my $equipment_name = "$prefix-$index";
 		# print "$equipment_name\n";
  
    	my @equipment_fields =   qw (Equipment_Name     Equipment_Status    FK_Location__ID FK_Stock__ID    Equipment_Comments                      FK_Equipment_Category__ID);
    	my @equipment_values =      ($equipment_name,   'In Use',           $location_id,   $stock_ID,      "virtual equipment for $location_name", $Category_ID);
    	my $equipment_ID    = $dbc->Table_append_array('Equipment',\@equipment_fields, \@equipment_values,-autoquote=>1);
 		#   print "Adding Equipment ID = $equipment_ID\n" if $equipment_ID ;

    	my @rack_fields =   qw (Rack_Type       Rack_Name               Rack_Alias          Movable     FK_Equipment__ID);
    	my @rack_values =      ('Shelf',     "VS-$equipment_name",     "$location_name",    'N',        $equipment_ID);
    	my $rack_ID     = $dbc->Table_append_array('Rack',\@rack_fields, \@rack_values,-autoquote=>1);
  		#  print "Adding Rack ID = $rack_ID\n\n" if $rack_ID;

    	$counter++;
	}
}

##########################
sub _get_equipment_name {
##########################
    my %args 	= &filter_input(\@_);
    my $dbc 	= $args {-dbc};
    my $category_id      = $args {-category_id};
    
    my $command = "Concat(Max(Replace(Equipment_Name,concat(Prefix,'-'),'') + 1)) as Next_Name";
    my ($name)    =$dbc->Table_find_array('Equipment_Category', -fields=> ['Prefix'], -condition => "WHERE Equipment_Category_ID=$category_id");    
    my ($number) = $dbc->Table_find_array('Equipment,Equipment_Category',[$command], "WHERE FK_Equipment_Category__ID=Equipment_Category_ID AND Equipment_Category_ID=$category_id");
    unless ($number) { $number = 1}
    return ($name,$number);
}



if (_check_block('Equipment_names')) {
	##############################################
	###  This block is used to update equipment info and them rename all equipment

	my $host 		= $dbc->{host};
	my $login_name 	= $dbc->{login_name};
	my $login_pass 	= $dbc->{login_pass};
	my $dbase 		= $dbc->{dbase};
	
	my $connect = "mysql -h $host -u $login_name -p"."$login_pass $dbase";  
	my @commands;
	$commands[0] = "update Equipment,Equipment_Category set FK_Equipment_Category__ID = Equipment_Category_ID WHERE Equipment_Type = \"Storage\" and (Equipment.FK_Equipment_Category__ID=0 OR Equipment.FK_Equipment_Category__ID  IS NULL) AND FK_Stock__ID > 0 AND Category = \"Storage\" AND Sub_Category = \"Room Temperature\" ";

	$commands[1] = "update Stock_Catalog, Stock, Equipment  Set Stock_Catalog.FK_Equipment_Category__ID = Equipment.FK_Equipment_Category__ID
                Where Stock_Catalog.Stock_Type = \"Equipment\"
                AND FK_Stock_Catalog__ID = Stock_Catalog_ID
                AND FK_Stock__ID = Stock_ID
                AND Stock_Catalog.Stock_Type = \"Equipment\"
                AND Equipment.FK_Equipment_Category__ID <> 0 ;";
	$commands[2] = "Alter Table Equipment ADD (Old_Equipment_Name varchar(40))";
	$commands[3] = "update Equipment set Old_Equipment_Name = Equipment_Name";
	$commands[4] = "update Equipment set Equipment_Name = NULL ";

	$commands[5] = "update Equipment, Equipment_Category set Equipment_Name = Old_Equipment_Name
                where FK_Equipment_Category__ID = Equipment_Category_ID 
                and Left(Old_Equipment_Name,Length(Prefix)+1) = CONCAT(Prefix,\"-\") 
                and Old_Equipment_Name not like \"% %\" 
                and  Mid(Old_Equipment_Name,Length(Prefix)+2,99) NOT REGEXP \"[:digit:]\" ";
	$commands[6] = "update Equipment,Asset set Concurrency_ID =ConcurrencyID Where LIMSNum = Equipment_ID";
	$commands[7] = "update Equipment,Asset,Stock set Stock.Requisition_Number=RequisitionNumber Where LIMSNum = Equipment_ID AND FK_Stock__ID = Stock_ID";
	$commands[8] = "update Equipment,Asset,Stock set Stock.PO_Number =PONumber Where LIMSNum = Equipment_ID AND FK_Stock__ID = Stock_ID";
	$commands[9] = "update Stock_Catalog set Stock_Size_Units = \"pcs\" Where Stock_Type = \"Equipment\"";
	$commands[10] = "update Stock_Catalog set Stock_Size = 1 Where Stock_Type = \"Equipment\"";
	$commands[11] = "update Stock_Catalog,Stock,Equipment set FKVendor_Organization__ID = Equipment.FK_Organization__ID WHERE FK_Stock_Catalog__ID = Stock_Catalog_ID AND FK_Stock__ID = Stock_ID";
	$commands[12] = "update DBField set field_options = \"Mandatory\" where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = \"Stock_Catalog\") and field_name in 	(\"FK_Organization__ID\",\"FKVendor_Organization__ID\")";
	$commands[13] = "update Stock_Catalog set Stock_Status = \"Inactive\" WHERE Stock_type=\"Equipment\" AND FK_Equipment_Category__ID = 0";
	$commands[14] = "update Equipment,Stock,Stock_Catalog set Stock_Catalog.Model = Equipment.Model WHERE FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.Stock_Type = \"Equipment\"";
	$commands[15] = "update Equipment,Stock,Stock_Catalog set Equipment.FK_Equipment_Category__ID= Stock_Catalog.FK_Equipment_Category__ID WHERE FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND 	Equipment.FK_Equipment_Category__ID IS NULL";
	$commands[16] = "update Stock_Catalog set Stock_Status = \"Inactive\" WHERE Stock_Catalog_Name IN (\"Cluster buffer\", \"Cluster Station Kit (Box 1 of 3)\",\"Cluster Station Kit (Box 2 of 3)\")";

	# update DBField set field_options = 'Mandatory' where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Equipment') and field_name IN ('Equipment_Name','Equipment_Status','FK_Location__ID');


	for my $command (@commands) {
    	#print "\n\n $command \n" ;
    	my $response = try_system_command("$connect -e  \'$command\'");
    	print $response;
    	if ($response =~ /ERROR/) {last}
	}


	#######################
	### First set of SQL commands executed
	##  Now we rename Equipment
	print "\n Now we rename equipment according to category\n";
	my $stock_ID;
	my @ids =   $dbc->Table_find(-table		=> 'Equipment',    -fields		=> "Equipment_ID, FK_Equipment_Category__ID",
                             	-condition	=> "WHERE  Equipment_Name is NULL  and FK_Equipment_Category__ID <> 0" );
	for my $counter (@ids) {
     	(my $id, my $category_id) = split ',' , $counter;
     	my ($prefix, $index) =  _get_equipment_name (-category_id   => $category_id, -dbc=>$dbc);
     	my $fields = 'Equipment_Name';
     	my $values = "'$prefix-$index'";
    
    	my $num_records = $dbc->Table_update(-table=>'Equipment', -fields=>$fields, -values=>$values, -condition=>"WHERE Equipment_ID = $id");
	}

	############################
	#   Final Commands for updating equipment
	my @final_commands;

	$final_commands[0] = "update Equipment set Equipment_Name = \"TBD\" WHERE Old_Equipment_Name = \"TBD\" ";
	$final_commands[1] = "update Equipment set Equipment_Status = \"Inactive - Hold\"    Where Equipment_Name is NULL AND Equipment_Status IN (\"In Use\" ,\"\")";

	for my $command (@final_commands) {
    	my $response = try_system_command("$connect -e  \'$command\'");
    	print $response;
    	if ($response =~ /ERROR/) {last}
	}

}


if (_check_block('remove_base_grps')) {
    use alDente::Grp;

    alDente::Grp::remove_Grp($dbc,'Mapping Lab','Mapping Production');
    alDente::Grp::remove_Grp($dbc,'Microarray Base','Microarray');
    alDente::Grp::remove_Grp($dbc,'MGC Closure Base','MGC_Closure');

    $dbc->Table_update_array('Grp',['Grp_Name'],["Replace(Grp_Name,' Base','')"],"WHERE Grp_Name like '% Base'");
}

if (_check_block('fix_submission_subscriptions')) {

    $dbc->start_trans('submission_fix');
    
    my @Events = ('Approved Submission','Cancelled Submission','Submitted Submission');
    
    my @groups = ('Mapping','Sequencing','Gene Expression');
    foreach my $grp (@groups) {
	my ($grp_base) = $dbc->Table_find('Grp','Grp_ID',"WHERE Grp_Name = '$grp'");
	foreach my $event_name (@Events) {
	    my ($event_id) = $dbc->Table_find('Subscription_Event','Subscription_Event_ID',"WHERE Subscription_Event_Name = '$event_name'");
	    
	    my $subscription = $dbc->Table_append_array('Subscription',
							['FK_Subscription_Event__ID','FK_Grp__ID','Subscription_Name'],
							[$event_id,$grp_base,"$event_name for $grp"],-debug=>1,-autoquote=>1);
	    
	    my ($old_subscription) = $dbc->Table_find('Subscription','Subscription_ID',"WHERE Subscription_Name = '$event_name'");
#	    my $remove_old = $dbc->delete_records('Subscription','Subscription_ID',$old_subscription,-cascade=>['Subscriber'],-debug=>1);
	    
	    my ($admin_id) = $dbc->Table_find('Grp','Grp_ID',"WHERE Grp_Name = '$grp Admin'");
	    if ($admin_id) {
		$dbc->Table_append_array('Subscriber',['FK_Subscription__ID','Subscriber_Type','FK_Grp__ID'],[$subscription, 'Grp',$admin_id],-debug=>1,-autoquote=>1);	
	    }
	    
	    my ($pa_id) = $dbc->Table_find('Grp','Grp_ID',"WHERE Grp_Name = '$grp Project Admin'");
	    if ($pa_id) {
		$dbc->Table_append_array('Subscriber',['FK_Subscription__ID','Subscriber_Type','FK_Grp__ID'],[$subscription, 'Grp',$pa_id],-debug=>0,-autoquote=>1);	
	    }
	    
	}
    }
    $dbc->finish_trans('submission_fix');

}

if (_check_block('project_admins')) {
	my ($project_grp)  = $dbc->Table_find('Grp','Grp_ID',"WHERE Grp_Name like 'Projects_Admin'");	

	my @admins = $dbc->Table_find('Grp,GrpEmployee','FK_Employee__ID',"WHERE FK_Grp__ID=Grp_ID AND Grp_Name like '%Project Admin'");
	foreach my $admin (@admins) {
	    my ($exists) = $dbc->Table_find('GrpEmployee','count(*)',"WHERE FK_Grp__ID = $project_grp AND FK_Employee__ID = $admin");
	    if ($exists) { Message("Emp $admin already in Grp $project_grp") }
	    else { $dbc->Table_append_array('GrpEmployee',['FK_Grp__ID','FK_Employee__ID'],[$project_grp,$admin]) }
	}
	
}

</CODE_BLOCK>
<FINAL>
update DBField set Field_Options = 'Hidden' WHERE Field_Table = 'Equipment' and Field_Name ='Old_Equipment_Name';
update DBField set Field_Options = 'Mandatory' WHERE Field_Table = 'Stock_Catalog' and Field_Name IN ('FK_Organization__ID','FKVendor_Organization__ID');
update Organization set Organization_Type = 'Manufacturer,Funding Source' Where organization_name  = 'n/a';

</FINAL>
