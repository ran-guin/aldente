<SCHEMA>
## Change Tube Concentration field
ALTER TABLE Tube change Concentration Original_Concentration float default NULL; 
alter table Tube change Concentration_Units Original_Concentration_Units enum('cfu','ng/ul','ug/ul','nM','pM') default NULL;

## Tables for Template
CREATE TABLE `Template` (
  `Template_ID` int(11) NOT NULL auto_increment,
  `Template_Name` varchar(34) NOT NULL default '',
  `Template_Type` enum('Submission','Master') NOT NULL default 'Submission',
  `Template_Description` text,
  PRIMARY KEY  (`Template_ID`),
  UNIQUE KEY `Template_Name` (`Template_Name`)
);

CREATE TABLE `Template_Assignment` (
  `Template_Assignment_ID` int(11) NOT NULL auto_increment,
  `FK_Template__ID` int(11) NOT NULL default '0',
  `FK_Grp__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Template_Assignment_ID`),
  KEY `FK_Template__ID` (`FK_Template__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`)
);

CREATE TABLE `Template_Field` (
  `Template_Field_ID` int(11) NOT NULL auto_increment,
  `Template_Field_Name` varchar(80) NOT NULL default '',
  `FK_DBField__ID` int(11) NOT NULL default 0,
  `FK_Attribute__ID` int(11) NOT NULL default 0,
  `Template_Field_Option` set('Mandatory','Unique') default NULL,
  `Template_Field_Format` varchar(80) default NULL,
  `FK_Template__ID` int(11) NOT NULL default 0,
  PRIMARY KEY  (`Template_Field_ID`),
  KEY `FK_DBField__ID` (`FK_DBField__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`),
  KEY `FK_Template__ID` (`FK_Template__ID`)
);

##### Microarray batch submission template data starts ####################
##### All statements below are in the following file: /Plugins/Microarray/install/upgrade/sql/upgrade_2.6_data.sql#########################

#insert into Template (Template_Name) values ("Microarray_Submission_OS_S_L");

#insert into Template_Assignment (FK_Template__ID, FK_Grp__ID) select Template_ID, Grp_ID from Template, Grp where Template_Name = 'Microarray_Submission_OS_S_L' and Grp_Name = 'Microarray';

#insert into Template_Field (Template_Field_Name, FK_Template__ID) select "Original_Source_Name", Template_ID from Template where Template_Name = 'Microarray_Submission_OS_S_L';
#update Template_Field set FK_DBField__ID = (select DBField_ID from DBField, DBTable where FK_DBTable__ID = DBTable_ID and DBTable_Name = 'Original_Source' and Field_Name = 'Original_Source_Name'), Template_Field_Option = 'Mandatory' where Template_Field_Name = 'Original_Source_Name';

#insert into Template_Field (Template_Field_Name, FK_Template__ID) select "External_Identifier",Template_ID from Template where Template_Name = 'Microarray_Submission_OS_S_L';
#update Template_Field set FK_DBField__ID = (select DBField_ID from DBField, DBTable where FK_DBTable__ID = DBTable_ID and DBTable_Name = 'Source' and Field_Name = 'External_Identifier'), Template_Field_Option = 'Mandatory' where Template_Field_Name = 'External_Identifier';

#insert into Template_Field (Template_Field_Name, FK_Template__ID) select "Label", Template_ID from Template where Template_Name = 'Microarray_Submission_OS_S_L';
#update Template_Field set FK_DBField__ID = (select DBField_ID from DBField, DBTable where FK_DBTable__ID = DBTable_ID and DBTable_Name = 'Source' and Field_Name = 'Label') where Template_Field_Name = 'Label';

#insert into Template_Field (Template_Field_Name, FK_Template__ID) select "Sex", Template_ID from Template where Template_Name = 'Microarray_Submission_OS_S_L';
#update Template_Field set FK_DBField__ID = (select DBField_ID from DBField, DBTable where FK_DBTable__ID = DBTable_ID and DBTable_Name = 'Original_Source' and Field_Name = 'Sex') where Template_Field_Name = 'Sex';

#insert into Template_Field (Template_Field_Name, FK_Template__ID) select "Family_ID", Template_ID from Template where Template_Name = 'Microarray_Submission_OS_S_L';
## End block moved to <root_dir>/Plugins/Microarray/install/upgrade/sql/upgrade_2.6_data.sql

ALTER TABLE Plate ADD FK_Sample_Type__ID INT NOT NULL;

ALTER TABLE Sample ADD (FKOriginal_Plate__ID INT NOT NULL, Original_Well char(3), FK_Library__Name varchar(8), Plate_Number int, FK_Sample_Type__ID INT NOT NULL);


CREATE TABLE Sample_Type (Sample_Type_ID INT NOT NULL Auto_Increment Primary Key, Sample_Type varchar(40));
 
 ALTER TABLE Sample ADD Sample_Source enum('Original','Extraction','Clone');
alter table Location add Column FK_Site__ID int (11) NOT NULL;
alter Table Location add column Location_Type enum('External','Internal') NOT NULL;



##### Temporary changes should be removed when implemented in Sequence
# made in order to eliminate multiple entries in Stock_Catalog table
alter table Stock modify Identifier_Number_Type enum ('Component Number' , 'Reference ID');

#### Stock_Catalog table ######################

 alter table Stock add column FK_Stock_Catalog__ID int(11) NOT NULL;
 alter table Stock add column Stock_Notes text default NULL;
 alter table Stock modify Stock_Type enum('Solution','Reagent','Kit','Box','Microarray','Equipment','Service_Contract','Computer_Equip','Misc_Item','Matrix','Buffer','Primer');

alter table Equipment add FK_Equipment_Category__ID int(11) NULL;
 # is this line necessary? equipment_comments already is null by default and can be null
alter table Equipment modify Equipment_Comments Text NULL default NULL;
alter table Equipment modify Equipment_Status enum('In Use', 'Inactive - Removed', 'Inactive - In Repair', 'Inactive - Hold', 'Sold', 'Unknown', 'Returned to Vendor (RTV)','In Transit') NULL default NULL;
alter table Equipment add Concurrency_ID varchar(20)  default NULL;
alter table Stock add PO_Number varchar(20)  default NULL;
alter table Stock add Requisition_Number varchar(20)  default NULL;
alter table Equipment add FK_Organization__ID int(11)  default NULL;
alter table Equipment modify Acquired date NULL default NULL;
alter table Equipment modify Equipment_Alias varchar(40) NULL  default NULL;
alter table Equipment modify  Equipment_Condition enum('-80 degrees','-40 degrees','-20 degrees','+4 degrees','Variable','Room Temperature','') NULL  default NULL;
alter table Equipment modify  Equipment_Cost float NULL default NULL;
#alter table Equipment modify  Equipment_Location enum('Sequence Lab','Chromos','CDC','CRC','Functional Genomics','Linen','GE Lab','GE Lab - RNA area','GE Lab - DITAG area','Mapping Lab','MGC Lab') null  default NULL;
alter table Equipment modify  Equipment_Number int(11) null  default NULL;
alter table Equipment modify  Equipment_Number_in_Batch int(11) null  default NULL;
alter table Equipment modify  Equipment_Type enum('','Sequencer','Centrifuge','Thermal Cycler','Freezer','Liquid Dispenser','Platform Shaker','Incubator','Colony Picker','Plate Reader','Storage','Power Supply','Miscellaneous','Genechip Scanner','Gel Comb','Gel Box','Fluorimager','Spectrophotometer','Bioanalyzer','Hyb Oven','Solexa','GCOS Server','Printer','Pipette','Balance','PDA','Cluster Station') null  default NULL;
    
create table `Stock_Catalog` (
 `Stock_Catalog_ID` int(11) NOT NULL auto_increment ,
 `Stock_Catalog_Name` varchar(80) NOT NULL default '',
 `Stock_Catalog_Description` text default NULL,
 `Stock_Catalog_Number` varchar(80) default NULL,
 `Stock_Type`  enum('Box','Buffer','Equipment','Kit','Matrix','Microarray','Primer','Reagent','Solution','Service_Contract','Computer_Equip','Misc_Item') default NULL,
 `Stock_Source` enum('Box','Order','Sample','Made in House') default NULL,
 `Stock_Status` enum ('Active','Inactive') default 'Active',
 `Stock_Size` float default NULL,
 `Stock_Size_Units` enum('mL','uL','litres','mg','grams','kg','pcs','boxes','tubes','rxns','n/a') default NULL,
 `FK_Organization__ID` int(11),
 `FKVendor_Organization__ID` int(11),
 `Model` varchar(20) default NULL,
 `FK_Equipment_Category__ID` int(11) default 0,
 PRIMARY KEY  (`Stock_Catalog_ID`)
);

alter table Work_Request add FK_Funding__ID INT;
alter table Plate add FK_Work_Request__ID INT;
alter table Work_Request_Type add Work_Request_Type_Status enum('Active','Inactive') default 'Active';
alter table Work_Request_Type add FK_Grp__ID INT NOT NULL;
alter table Work_Request_Type add Work_Request_Label varchar(40);

alter Table Service add FK_Equipment_Category__ID int(11);
alter Table Service drop column FK_Equipment__Type;


## Add new Goal_Target_Type
alter table Work_Request modify Goal_Target_Type enum('Original Request','Add to Original Target','Included in Original Target') NULL default NULL;

# dbtable and dbfield records for stock_catalog will be created w/ dbfield_set.pl, changes to the DBField/DBTable should be put in upgrade_2.6_final.sql
# ./bin/dbfield_set.pl -host limsdev02 -dbase seqdev -u super_cron -new_tables Stock_Catalog

alter table Organization modify Organization_Type set('Manufacturer','Collaborator') null default null;


## Look in ./Plugins/Sequencing/upgrade_2.6.sql
## alter table Sequencing_Library change Sequencing_Library_Type Sequencing_Library_Type enum('SAGE','cDNA','Genomic','EST','Transposon','PCR','Test','PCR_Product','Vector_Based')  default NULL;

## Look in ./Plugins/Sequencing/upgrade_2.6_data.sql
#insert into DB_Form (form_table,fkparent_db_form__id,parent_field,parent_value) values ('PCR_Product_Library',31,'Sequencing_Library_Type','PCR_Product');

# insert into DB_Form (form_table,fkparent_db_form__id,parent_field,parent_value) values ('Vector_Based_Library',31,'Sequencing_Library_Type','Vector_Based');
## End block in ./Plugins/Sequencing/upgrade_2.6_data.sql

## Begin block moved to ./upgrade_2.6_data.sql
#update DBTable set DBTable_Title = 'Transformed Cells' where DBTable_title = 'X-Formed Cells';

#insert into Goal (Goal_Name,goal_description,Goal_Tables,goal_count,goal_condition) value ('384 well Plates to Prep','Number of 384-well plates to prep (count 4 96-well sequenced plates as 1 384-well sequenced plate)','Plate,Prep,Plate_Prep','CASE WHEN Plate_Size like \'96%\' THEN 0.25 ELSE 1 END as 384well_Plates','FK_Plate__ID=Plate_ID AND FK_Library__Name = \'\' and Prep_ID = FK_Prep__ID and Plate_Status != \'Failed\' and Prep_Action = \'Completed\'');
## ^ The above statement is in ^ ./upgrade_2.6_data.sql

##Add FK_Object_Class__ID to Fail
alter table Fail add FK_Object_Class__ID INT NOT NULL default 0;
alter table Fail add index (FK_Object_Class__ID);

##Add Version status to allow tracking database version
ALTER TABLE Version ADD Status enum('In use','Not in use') not null default 'Not in use';

## Change Source.Label to Source.Source_Label
ALTER TABLE Source change Label Source_Label varchar(40) default NULL;

## Add Solution_Label to Solution
ALTER TABLE Solution ADD Solution_Label varchar(40) default NULL;
ALTER TABLE Solution ADD INDEX label (Solution_Label);

alter table Work_Request add  Work_Request_Title varchar (255) ;

alter TABLE Organization Modify Organization_Type set('Manufacturer','Collaborator','Vendor','Funding Source');


Create TABLE Site( Site_ID INT NOT NULL auto_increment primary key,Site_Name varchar(40));

alter table Grp add Grp_Type enum('Public','Lab','Lab Admin','Project Admin','TechD','Production','Research','Technical Support','Informatics','QC','Purchasing','Shared');

alter table Grp add Grp_Status enum('Active','Inactive') default 'Active';

insert into Trigger values ('','GrpEmployee','Perl',"require alDente::Employee;  my $ok=alDente::Employee::new_GrpEmployee_trigger($self,<ID>); return $ok;",'insert','Active','if in shared groups - change to multiple derived group membership','No');

ALTER TABLE Plate_Format change Capacity Well_Capacity_mL float;

create index category on Equipment_Category (Category);
create index sub_category on Equipment_Category (Sub_Category);

## Moved to ./upgrade_2.6_data.sql:


ALTER TABLE DBTable ADD FK_Package__ID int not null default 0;
ALTER TABLE DBTable MODIFY Scope enum('Core','Lab','Plugin','Option','Custom');

alter table Library modify Library_Type enum('Sequencing','RNA/DNA','Mapping','PCR_Product') NULL default NULL;

</SCHEMA>
<DATA>
INSERT INTO Sample_Type values ('','Mixed'),('','Tissue'),('','Cells');

## Replaced in the code block of upgrade:
## update Plate, Sample_Type set Plate.FK_Sample_Type__ID = Sample_Type_ID where Plate.Plate_Content_Type = Sample_Type.Sample_Type;

update Stock,Solution Set Stock_Cost= Solution_Cost WHERE Stock_ID = FK_Stock__ID and (Stock_Cost = 0 or Stock_Cost is NULL) AND (Solution_Cost <> 0 and Solution_Cost is not NULL);

update Stock set Identifier_Number_Type = 'Reference ID' WHERE Stock_Name = 'Custom Oligo Plate%'  AND Identifier_Number is Null ;
update Stock set Identifier_Number = Stock_Catalog_Number WHERE Stock_Name = 'Custom Oligo Plate%'  AND Identifier_Number is Null;
update Stock set Stock_Catalog_Number = Null WHERE Stock_Name LIKE 'Custom Oligo Plate%' ;

update Equipment, Equipment_Transfer set Equipment.FK_Equipment_Category__ID = Equipment_Transfer.FK_Equipment_Category__ID Where Equipment.Equipment_ID = Equipment_Transfer.Equipment_ID;

update Equipment set FK_Equipment_Category__ID = 71
where  FK_Equipment_Category__ID is NULL  and Equipment_type = 'Sequencer' and Equipment_Name like 'D3100%';

update Equipment set FK_Equipment_Category__ID = 72
where  FK_Equipment_Category__ID is NULL  and Equipment_type = 'Sequencer' and Equipment_Name like 'D3730%';

update Equipment set FK_Equipment_Category__ID = 75
where  FK_Equipment_Category__ID is NULL  and Equipment_type = 'Sequencer' and Equipment_Name like 'MB%';

update Equipment set FK_Equipment_Category__ID = 91
where  FK_Equipment_Category__ID is NULL  and Equipment_type = 'Thermal Cycler' and Model like '%Alpha Unit%';

update Equipment set FK_Equipment_Category__ID = 91
where  FK_Equipment_Category__ID is NULL and Equipment_type = 'Thermal Cycler' and Equipment_Name like '%Alpha Unit%';

update Equipment set FK_Equipment_Category__ID = 26
where  FK_Equipment_Category__ID is NULL and Equipment_type = 'Freezer' and Equipment_Name like 'F80%';

update Equipment set FK_Equipment_Category__ID = 27
where  FK_Equipment_Category__ID is NULL and Equipment_type = 'Freezer' and Equipment_Name like 'F20%';

update Equipment set FK_Equipment_Category__ID = 28
where  FK_Equipment_Category__ID is NULL  and Equipment_type = 'Freezer' and Equipment_Name like 'F4%';

update Equipment set FK_Equipment_Category__ID = 51
where  FK_Equipment_Category__ID is NULL  and Equipment_type = 'Liquid Dispenser' and Equipment_Name like 'Bio%';

update Equipment set FK_Equipment_Category__ID = 56
where  FK_Equipment_Category__ID is NULL  and Equipment_type = 'Liquid Dispenser' and Model like 'Q%fill%';

update Equipment,Equipment_Category set FK_Equipment_Category__ID = Equipment_Category_ID
WHERE Equipment_Name Like 'D3100%'AND Category = 'Sequencer' AND Sub_Category = '3100' and FK_Equipment_Category__ID = 0;

update Equipment,Equipment_Category set FK_Equipment_Category__ID = Equipment_Category_ID
WHERE Equipment_Name Like 'D3730%'AND Category = 'Sequencer' AND Sub_Category = '3730' and FK_Equipment_Category__ID = 0 ; 

update Equipment,Equipment_Category set FK_Equipment_Category__ID = Equipment_Category_ID
WHERE Equipment_Name Like 'D3700%'AND Category = 'Sequencer' AND Sub_Category = '3700' and (FK_Equipment_Category__ID = 0 OR FK_Equipment_Category__ID IS NULL); 

update Equipment set FK_Equipment_Category__ID = 12 where  FK_Equipment_Category__ID is NULL  and Equipment_type = 'Colony Picker';
update Equipment set FK_Equipment_Category__ID = 64 where  FK_Equipment_Category__ID IS NULL  and Equipment_type = 'Power Supply';
update Equipment set FK_Equipment_Category__ID = 30 where  FK_Equipment_Category__ID IS NULL  and Equipment_type = 'Gel Comb';
update Equipment set FK_Equipment_Category__ID = 3 where  FK_Equipment_Category__ID IS NULL  and Equipment_type = 'Balance';
update Equipment set FK_Equipment_Category__ID = 21 where  FK_Equipment_Category__ID IS NULL  and Equipment_type = 'PDA';
update Equipment set FK_Equipment_Category__ID = 105 where  FK_Equipment_Category__ID IS NULL and Equipment_type = 'Pipette' and Equipment_name Like 'Dis%';
update Equipment set FK_Equipment_Category__ID = 29 where  FK_Equipment_Category__ID IS NULL   and Equipment_Type =  'Gel Box';
update Equipment set FK_Equipment_Category__ID = 61 where  FK_Equipment_Category__ID IS NULL   and Equipment_Name LIKE  'Microwa%' ;

update Equipment_Category,Equipment, Stock Set Stock_Name = concat(Stock_Name,' - ',Sub_Category)
Where FK_Stock__ID = Stock_ID AND FK_Equipment_Category__ID = Equipment_Category_ID AND Stock_Name <> Sub_Category  AND Sub_Category <> 'N/A';

update  Stock,Solution set Stock_Type = 'Matrix' Where Solution.Solution_Type = 'Matrix' and Solution.FK_Stock__ID = Stock.Stock_ID;
update  Stock,Solution set Stock_Type = 'Buffer' Where Solution.Solution_Type = 'Buffer' and Solution.FK_Stock__ID = Stock.Stock_ID;
update  Stock,Solution set Stock_Type = 'Primer' Where Solution.Solution_Type = 'Primer' and Solution.FK_Stock__ID = Stock.Stock_ID;

INSERT INTO Work_Request_Type (Work_Request_Type_Name, Work_Request_Type_Description, Work_Request_Type_Status, FK_Grp__ID, Work_Request_Label) VALUES ('Default Work Request', NULL, 'Active', 0, NULL);

## Done now in upgrade_2.6.pl
#update Work_Request, Work_Request_Type set FK_Work_Request_Type__ID = Work_Request_Type_ID where Work_Request_Type_Name = Work_Request_Type;

update DBTable set DBTable_Title = 'Transformed Cells' where DBTable_title = 'X-Formed Cells';

update Fail,FailReason set Fail.FK_Object_Class__ID = FailReason.FK_Object_Class__ID where FK_FailReason__ID = FailReason_ID;

UPDATE Version SET Status = 'Not in use' WHERE Version_Name != '2.6';
UPDATE Version SET Status = 'In use' WHERE Version_Name = '2.6';

UPDATE DBField set Field_Options = 'Obsolete' where Field_Name = 'FK_Funding__ID' and Field_Table='Project';
INSERT INTO Trigger values ('','Project','Method','new_Project_trigger','insert','Active','on insertion, add new Project_ID to active list in connection object','No');

INSERT INTO Subscription_Event VALUES ('','Library_Status Updates','Notice',"Notification when Libraries are automatically set to 'Completed' or reverted to 'In Production' based upon completion of Goals"); 
INSERT INTO Subscription SELECT '',Subscription_Event_ID,NULL,NULL,NULL,NULL,Subscription_Event_Name from Subscription_Event where Subscription_Event_Name like 'Library_Status Updates';
insert into Goal (Goal_Name,Goal_Tables,Goal_Count,Goal_Condition) value ('Custom Goal','Library',1,"Library_Name='<LIBRARY>'");
insert into Goal (Goal_Name,goal_description,Goal_Tables,goal_count,goal_condition) value ('384 well Plates to Prep','Number of 384-well plates to prep (count 4 96-well sequenced plates as 1 384-well sequenced plate)','Plate,Prep,Plate_Prep','CASE WHEN Plate_Size like \'96%\' THEN 0.25 ELSE 1 END as 384well_Plates','FK_Plate__ID=Plate_ID AND FK_Library__Name = \'\' and Prep_ID = FK_Prep__ID and Plate_Status != \'Failed\' and Prep_Action = \'Completed\'');

INSERT INTO Work_Request_Type (Work_Request_Type_Name, Work_Request_Type_Description, Work_Request_Type_Status, FK_Grp__ID, Work_Request_Label) VALUES ('Custom Type', NULL, 'Active', 0, NULL);

INSERT INTO Trigger (Table_Name, Trigger_Type,Value,Trigger_On, Status,Trigger_Description,Fatal) values ('Location','Perl','require alDente::Rack; my $ok = alDente::Rack::add_rack_for_location(-dbc=>$self,-id=>);','insert','Active','Need to add record to equipment and rack as well','Yes');

update Trigger set Table_Name='Work_Request', Value=REPLACE(Value,'library_goal','work_request') where Table_Name = 'LibraryGoal';

INSERT INTO Site (Site_Name) values ('External');

update Organization, Temp_GSOT_Organization set Organization.Organization_Type = Temp_GSOT_Organization.Organization_Type
    WHERE  Organization.Organization_Type <> Temp_GSOT_Organization.Organization_Type
    AND  Organization.Organization_ID = Temp_GSOT_Organization.Organization_ID;

Insert INTO Organization (Select *  from Temp_GSOT_Organization WHERE organization_id NOT IN (select Organization_ID from Organization));
  
update Equipment,Asset,Vendor,Organization Set  FK_Organization__ID = Organization_ID  Where Equipment_ID= LIMSNum  AND Asset.VenID = Vendor.VenID AND Vendor.org_name = Organization.Organization_Name;
   
INSERT INTO Employee VALUES ('','API Client','','API','aldente','API Client','BioInformatics','Active','R,W,U,D,S,P,A','',Password('IPA'),'','',1);

INSERT INTO Funding (Funding_Name,Funding_Source) VALUES ('Default Funding','Internal');
UPDATE Project SET FK_Funding__ID = (SELECT Funding_ID FROM Funding WHERE Funding_Name = 'Default Funding') WHERE Project_Name = 'Default Project';

update  Solution,Stock set Solution_Quantity = Stock_Size WHERE FK_stock__ID= stock_id  and Solution_Status NOT IN ('Finished','Expired') AND (Solution_Quantity =0 or Solution_Quantity is NULL) and Stock_Size_Units = 'mL';
update Solution,Stock set Solution_Quantity= Stock_Size/1000 WHERE FK_stock__ID= stock_id and Solution_Status NOT IN ('Finished','Expired') AND (Solution_Quantity =0 or Solution_Quantity is NULL) and Stock_Size_Units = 'uL';
update Solution,Stock set Solution_Quantity= Stock_Size*1000 WHERE FK_stock__ID= stock_id  and Solution_Status NOT IN ('Finished','Expired') AND (Solution_Quantity =0 or Solution_Quantity is NULL) and Stock_Size_Units = 'litres';

update DBField set field_options = 'Obsolete' where field_table = 'Stock'  and field_name in ('stock_size_units','stock_description','stock_catalog_number','stock_size','stock_type','fk_organization__id','stock_source','purchase_order','Stock_Name');
update DBField set field_options = 'Obsolete' where Field_Table = 'Solution' and field_name IN ('Solution_Cost');
update DBField set field_options = 'Obsolete' where Field_Table = 'Equipment' and field_name IN ('acquired','Comments','Concurrency_ID','equipment_alias','equipment_condition','equipment_cost','equipment_type','equipment_location','equipment_description','FK_Organization__ID','FK_Equipment_Category__ID','Model' );
update DBField set Field_options = 'Obsolete' WHERE Field_Name = 'FK_Organization__ID' and Field_Table = 'Stock';

update Sample,Extraction_Sample set Sample.FKOriginal_Plate__ID = Extraction_Sample.FKOriginal_Plate__ID where FK_Sample__ID = Sample_ID;

update Sample,Clone_Sample set Sample.FKOriginal_Plate__ID = Clone_Sample.FKOriginal_Plate__ID where FK_Sample__ID = Sample_ID;

## add type for standard external submissions
INSERT INTO Work_Request_Type values ('','External','','Active','','');


###New trigger for Branch_Condition
INSERT INTO Trigger(Table_Name, Trigger_Type, Value, Trigger_On, Status, Trigger_Description, Fatal) Values ('Branch_Condition','Perl','require alDente::Branch; my $ok = alDente::Branch::new_branch_condition_trigger(-dbc=>$self,-id=><ID>);','insert','Active','Prevent inserting an ambiguous branch condition','Yes');
update Branch_Condition set FKParent_Branch__Code = '' where FKParent_Branch__Code = '0';


###Replace Bi-directional 96-well plates to sequence with 96 well Plates to Sequence with double amount of target
update Work_Request set FK_Goal__ID = 1, Goal_Target = (Goal_Target*2) where Work_Request_ID IN (315,316,336,337,341,405,416,464,465,466,487,521,526,536,579,623,653,674,675,676,677,685,689,690,691,692,760,761,763,777,778,779,797,798,812,813,844,878,880,882,884,885,886,889,895,903,904,905,906,912,913,914,915,916,917,918,922,931,946,953,957,976,998,999,1001,1002,1010,1013,1019,1022,1023,1024,1030,1031,1034,1036,1037,1038,1039,1041,1044,1048,1049,1053,1055,1073,1075,1076,1078,1084,1085,1100,1101,1102,1103,1113,1114,1115,1116,1117,1118,1119,1120,1121,1122,1127,1133,1141,1142,1143);

update LibraryGoal set FK_Goal__ID = 1, Goal_Target = (Goal_Target*2) where LibraryGoal_ID IN (607,658,669,672,673,678,681,683,684,706,709,757,1095,1110,1112,3835,3861,4010,4011,4012,4013,4316,5042);

</DATA>
<CODE_BLOCK>

my $arg1;
my $arg2;
my $arg3;

####################################################
# Blocks:
####################################################
#
# Note: header information should not be put in this file 
#   (a header file is concatenated to this file prior to execution) 
# 
####################################################



#if (_check_block('test')) {
#
#}

if (_check_block('fill_work_request_type_lookup_table')) {
    my %Work_Request_Info = $dbc->Table_retrieve(
                                                 -table=>'Work_Request',
                                                 -fields=>['Work_Request_Type'],
                                                 -condition=>"WHERE 1",
                                                 -distinct=>1
                                                 );
    my %Work_Request_Type_Info = $dbc->Table_retrieve(-table=>'Work_Request_Type',-fields=>['Work_Request_Type_Name'],-condition=>"WHERE 1",-distinct=>1);
    my @types = @{$Work_Request_Type_Info{Work_Request_Type_Name}};
    my $index = 0;
    while (exists $Work_Request_Info{Work_Request_Type}[$index]) {
        my $work_request_type = $Work_Request_Info{Work_Request_Type}[$index];
        unless (!(defined $Work_Request_Info{Work_Request_Type}[$index])) {
            if (!(grep /$work_request_type/, @types)) {
                $dbc->Table_append_array(
                                         -table=>'Work_Request_Type',
                                         -fields=>['Work_Request_Type_Name','Work_Request_Type_Description','Work_Request_Type_Status','FK_Grp__ID','Work_Request_Label'],
                                         -values=>["'$work_request_type'",'NULL',"'Active'","0",'NULL']
                                         );
            }
        }
        $index++;
    }
    $dbc->Table_update_array(-table=>'Work_Request,Work_Request_Type',-fields=>["FK_Work_Request_Type__ID"],-values=>["Work_Request_Type.Work_Request_Type_ID"],-condition=>"WHERE Work_Request.Work_Request_Type = Work_Request_Type.Work_Request_Type_Name");
}

if (_check_block('convert_librarygoal_to_workrequest_and_backfill_fk_work_request__ID')) {
    my %Library_Goals = $dbc->Table_retrieve(
			     -table=>'Library left join LibraryGoal on Library_Name = FK_Library__Name left join Project on Project_ID = FK_Project__ID left join Funding on FK_Funding__ID = Funding_ID',
			     -fields=>['Library_Name','LibraryGoal_ID','FK_Goal__ID','Goal_Target','FK_Funding__ID'],
			     -condition=>"Order By LibraryGoal_ID",
					     );

    my $index = 0;
    my %processed_library;
    while (defined $Library_Goals{Library_Name}[$index]) {
	
	#Simplest case where only 1 librarygoal for library
	my $library = $Library_Goals{Library_Name}[$index];
	my $librarygoal_id = $Library_Goals{LibraryGoal_ID}[$index];
	my $fk_goal_id = $Library_Goals{FK_Goal__ID}[$index];
	my $goal_target = $Library_Goals{Goal_Target}[$index];
	my $goal_target_type = "Original Request";
	my $comment = "BackFill using LibraryGoal $librarygoal_id";
	my $fk_funding_id = $Library_Goals{FK_Funding__ID}[$index];
	my $link_plate = 1;
    
	my ($no_defined_goal) = $dbc->Table_find('Goal','Goal_ID',"WHERE Goal_Name = 'No Defined Goals'"); 
	#When there are no library goals for a library
	if (!$librarygoal_id) {
	    $fk_goal_id = $no_defined_goal; # No Defined goals
	    $goal_target = 0;
	    $comment = "No LibraryGoal at the time of BackFill";
	}
    
	#When there are more than 1 library goals for a library, change goal_target_type to Add to Original Target and no linking work_request to plate
	if ($processed_library{$library}) {
	    $goal_target_type = 'Add to Original Target';
	    $link_plate = 0;
	}
    
	$processed_library{$library} = 1;
    
	## Update previous work request with Funding ID
	my $UpdateNum = $dbc -> Table_update('Work_Request','FK_Funding__ID',$fk_funding_id,"WHERE FK_Library__Name = '$library'");
	
	## Create a work request base on the library goal
	my ($work_request_type_id) = $dbc -> Table_find('Work_Request_Type','Work_Request_Type_ID',"WHERE Work_Request_Type_Name = 'Default Work Request'");

	my $Work_Request = $dbc -> Table_append_array('Work_Request',['FK_Goal__ID','Goal_Target','FK_Library__Name','FK_Work_Request_Type__ID','Comments','Goal_Target_Type','FK_Funding__ID'],[$fk_goal_id, $goal_target, $library, $work_request_type_id, $comment, $goal_target_type, $fk_funding_id],-autoquote=>1);

	if ($link_plate) {
	    ## Find all plates in the Library and update their FK_Work_Request__ID
	    my $UpdateNum = $dbc -> Table_update('Plate','FK_Work_Request__ID',$Work_Request,"WHERE FK_Library__Name = '$library'");
	}

	$index++;
    } 
}
if (_check_block('sample_type_lookup_table')) {
    #my %Plate_Info = $dbc->Table_retrieve(
    #                                      -table=>'Plate',
    #                                      -fields=>['Plate_Content_Type'],
    #                                      -condition=>"WHERE 1",
    #                                      -distinct=>1
    #                                      );
    my %Plate_Info = $dbc->Table_retrieve(-fields=>["distinct Plate_Content_Type as 'ALL' from Plate union select distinct Sample_Type as 'ALL' from Sample"]);
    my %Sample_Type_Info = $dbc->Table_retrieve(
                                                -table=>'Sample_Type',
                                                -fields=>['Sample_Type'],
                                                -condition=>"WHERE 1"
                                                );
    my @types =  @{$Sample_Type_Info{Sample_Type}} unless (!(defined $Sample_Type_Info{Sample_Type}));

    my $index = 0;
#    while (exists $Plate_Info{Plate_Content_Type}[$index]) {
#        if (defined $Plate_Info{Plate_Content_Type}[$index] && $Plate_Info{Plate_Content_Type}[$index])  {
#            my $plate_content_type = $Plate_Info{Plate_Content_Type}[$index];
    while (exists $Plate_Info{"'ALL' from Sample"}[$index]) {
        if (defined $Plate_Info{"'ALL' from Sample"}[$index] && $Plate_Info{"'ALL' from Sample"}[$index])  {
            my $plate_content_type = $Plate_Info{"'ALL' from Sample"}[$index];
            unless (grep /^$plate_content_type$/,@types) {
                $dbc->Table_append_array(
                                         -table=>'Sample_Type',
                                         -fields=>['Sample_Type'],
                                         -values=>["'$plate_content_type'"]
                                         );
            }
        }
        $index++;
    }
    $dbc->Table_update(-table=>"Plate,Sample_Type",-fields=>"FK_Sample_Type__ID",-values=>"Sample_Type.Sample_Type_ID",-condition=>"WHERE Plate.Plate_Content_Type = Sample_Type.Sample_Type");
    $dbc->Table_update(-table=>"Sample,Sample_Type",-fields=>"FK_Sample_Type__ID",-values=>"Sample_Type.Sample_Type_ID",-condition=>"WHERE Sample.Sample_Type = Sample_Type.Sample_Type");
    $dbc->Table_update(-table=>"Plate,Plate_Sample,Sample", -fields=>"Plate.FK_Sample_Type__ID",-values=>"Sample.FK_Sample_Type__ID",-condition=>"where Plate.FKOriginal_Plate__ID = Plate_Sample.FKOriginal_Plate__ID and FK_Sample__ID = Sample_ID and (Plate.Plate_Content_Type IS NULL or Plate_Content_Type = 0)");

}


if (_check_block('convert_stock')) {
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
    my $debug = 0;

    my $stock_table = "Stock";
    my $stock_catalog_table = "Stock_Catalog";

	my %Stock_Catalog_Data;

	## first populate all items with stock_catalog_numbers ... then remaining orders... then made in house items...
	## (do we need to handle box items differently ??) 

	## custom ##
	my $local_org = 27;
	
	my @cases = (
		"Length(Stock_Catalog_Number) > 1",
		"(Stock_Source <> 'Made in House' OR FK_Organization__ID <> $local_org)",
		"(Stock_Source = 'Made in House' AND FK_Organization__ID = $local_org)",
	);

	my $case_number = 0;
	foreach my $case (@cases) {
		$case_number++;
	## convert Orders only first (where Stock name is not blank, and stock_catalog record is not already defined)  ##		
	    my $cond = "where $case AND fk_stock_catalog__id = 0 AND (NOT(fk_organization__id is null)) and stock_name <>''";

    my @fields = qw(Stock_Catalog_Name Stock_Description Stock_Catalog_Number Stock_Type Stock_Source Stock_Size Stock_Size_Units FK_Organization__ID);

    my $Table_Name= $stock_table;
    my @fields = ('Stock_ID','Stock_Name', 'Stock_Description', 'Stock_Catalog_Number', 'Stock_Type','Stock_Source', 'FK_Organization__ID','Stock_Size','Stock_Size_Units');

    my %values = $dbc->Table_retrieve($Table_Name,\@fields,$cond,-debug=>$debug);
###############################
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

	$stock_description =  $dbc->dbh()->quote(%values->{'Stock_Description'}[$i]);
	$stock_size =  %values->{'Stock_Size'}[$i];

	my $lower = $stock_size -1;
	my $upper = $stock_size + 1 ;
	$stock_size_units =  $dbc->dbh()->quote(%values->{'Stock_Size_Units'}[$i]);
		
	## find this item if it already seems to be in the Stock_Catalog Table (ie retrieve Stock_Catalog_ID) ##
	
	$condition = "where fk_organization__id = $organization_id and stock_type = $stock_type and stock_source = $stock_source and stock_catalog_name = $stock_name ";  ## Stock_Catalog_Number needs to agree but only if it is defined in the Stock table already.. (below)

	my $Hindex = "$organization_id:$stock_type:$stock_source:$stock_name";
	
	if ($case_number == 3 ) { $stock_size = "'undef'"; $stock_size_units = "'n/a'"; } 

	my $insert_fields = ['Stock_Catalog_Name','Stock_Catalog_Number','Stock_Type','Stock_Source','Stock_Size','Stock_Size_Units','FK_Organization__ID','Stock_Catalog_Description'];

	my $insert_values = [$stock_name,$stock_catalog_number,$stock_type,$stock_source,$stock_size,$stock_size_units,$organization_id,$stock_description];

	if (($stock_type eq 'Reagent') || ($stock_type eq 'Solution')  || ($stock_type eq 'Primer')  || ($stock_type eq 'Buffer')  || ($stock_type eq 'Matrix')) {
	        # volume must match only for orders #
		if ($case_number < 3) {
		    $condition .= " and (stock_size between $lower and $upper)  and stock_size_units = $stock_size_units";
		    $Hindex .= ":$stock_size";	
		}
	}

	my $new_cond = $condition;
	my $cat_index = '';
	if ($stock_catalog_number =~/\w/) {
	    $new_cond .=" and stock_catalog_number = $stock_catalog_number";
	    $cat_index = "$stock_catalog_number";
	}

#	my @stock_catalog_ids = $dbc->Table_find( $stock_catalog_table,'Stock_catalog_id',$new_cond,-debug=>$debug);
	my @stock_catalog_ids;
	if (defined $Stock_Catalog_Data{$Hindex} && defined $Stock_Catalog_Data{$Hindex}{$cat_index}) {
		@stock_catalog_ids = @{$Stock_Catalog_Data{$Hindex}{$cat_index}};
	}
	else {
		@stock_catalog_ids = ();
	}
	my $count = scalar(@stock_catalog_ids) ;

	### Below are all of the possible cases wrt matches found... ##
	if ($count == 0) {
	    # do same search as above but this time w/o stock_catalog_number (no items with same stock number and all other info..)
###	    my @stock_catalog_ids = $dbc->Table_find( $stock_catalog_table,'Stock_catalog_id',"$condition",-debug=>$debug);
	    
	    if (defined $Stock_Catalog_Data{$Hindex}) {
	    	my @cats = keys %{$Stock_Catalog_Data{$Hindex}};
	    	foreach my $cat (@cats) {
			push @stock_catalog_ids, @{$Stock_Catalog_Data{$Hindex}{$cat}}; 
	    	}
	    }

	    my $new_count = scalar(@stock_catalog_ids) ;
	    if ($new_count == 0 || $stock_catalog_number) {
            	# add the record (no matches in stock_catalog table)
		## Add catalog record ##
		my $new_stock_catalog_number = $dbc->Table_append_array(-table=>$stock_catalog_table,-fields=>$insert_fields,-values=>$insert_values,-debug=>$debug);
		push @{$Stock_Catalog_Data{$Hindex}{$cat_index}}, $new_stock_catalog_number;

		my $result = $dbc->Table_update($stock_table,'fk_Stock_catalog__id',$new_stock_catalog_number,"where stock_id = $stock_id");

		if ($debug) { print "** Stock $stock_id: New record created for $stock_catalog_number = $new_stock_catalog_number.\n"; }

		$match_no_sc++;

	    }
	    elsif ($new_count == 1) {
            # use this record ONLY IF original stock_catalog_number was blank... #
		my $new_stock_catalog_number = $dbc->dbh()->quote($stock_catalog_ids[0]);
		my $result = $dbc->Table_update($stock_table,'fk_Stock_catalog__id',$new_stock_catalog_number,"where stock_id = $stock_id");
		$match++;
		if ($debug) { print "** Stock $stock_id: Exact match with new Cat# $new_stock_catalog_number. \n"; }
	    }
	    elsif ($new_count>1) {
		print "There is $new_count match for the following Stock_Catalog record\nstockid (w/o matching stock_catlog_no): $stock_id\nstock_name: $stock_name\nstock_type: $stock_type\nstock_src: $stock_source\norg_id: $organization_id\nstock_desc: $stock_description\n";
		my $new_stock_catalog_number = $dbc->dbh()->quote($stock_catalog_ids[0]);
		my $result = $dbc->Table_update($stock_table,'fk_Stock_catalog__id',$new_stock_catalog_number,"where stock_id = $stock_id");
		if ($debug) { print "** Stock $stock_id:  $new_count matches w/o cat_no - using first value ($new_stock_catalog_number)\n"; }

		$no_match++;

	    }
	    else {
		if ($debug) { print "** Stock $stock_id: Error 2 (new Count ($new_count) not 0, 1 or > 1 ??\n"; }
	    }

	}
	elsif ($count == 1) {
        # use this record
	    my $new_stock_catalog_number = $dbc->dbh()->quote($stock_catalog_ids[0]);
	    my $result = $dbc->Table_update($stock_table,'fk_Stock_catalog__id',$new_stock_catalog_number,"where stock_id = $stock_id");
	    if ($debug) { print "** Stock $stock_id:  Found exactly one match - using $new_stock_catalog_number.\n"; }
	    $match++;
	}
	elsif ($count>1) {
	    print "There is $count match for the following Stock_Catalog record\nstockid: $stock_id\nstock_name: $stock_name\nstock_catalog_no: $stock_catalog_number\nstock_type: $stock_type\nstock_src: $stock_source\norg_id: $organization_id\nstock_desc: $stock_description\n";

	# just use the 1st one
	    my $new_stock_catalog_number = $dbc->dbh()->quote($stock_catalog_ids[0]);
	    my $result = $dbc->Table_update($stock_table,'fk_Stock_catalog__id',$new_stock_catalog_number,"where stock_id = $stock_id");
	    if ($debug) { print "** Stock $stock_id: Found multiple matches for full index - using first one ($new_stock_catalog_number)\n"; }

	    $no_match++;

	}
	else {
   		if ($debug) { print "** Stock $stock_id: Error 3 (Original Count ($count) not 0, 1 or > 1 ??\n"; }
	}

	$i++;

    }
	
	print "Case: $case\n";
	print "Total records examined: $i, $match has exact match, $no_match doesn't\n";
	}    
	return 1;
}


</CODE_BLOCK>
<FINAL>

update DBField set field_options = 'Obsolete' where field_table = 'Stock'  and field_name in ('stock_size_units','stock_description','stock_catalog_number','stock_size','stock_type','fk_organization__id','stock_source','purchase_order','Stock_Name');
update DBField set field_options = 'Obsolete' where Field_Table = 'Solution' and field_name IN ('Solution_Cost');
update DBField set field_options = 'Obsolete' where Field_Table = 'Equipment' and field_name IN ('acquired','Comments','Concurrency_ID','equipment_alias','equipment_condition','equipment_cost','equipment_type','equipment_location','equipment_description','FK_Organization__ID','FK_Equipment_Category__ID','Model' );

update DBField set Field_Options = 'Obsolete' where Field_Table = 'Plate_Format' and Field_Name = 'Plate_Format_Size';
update DBField set Field_Options = 'Mandatory' where Field_Table = 'Plate_Format' and Field_Name = 'Wells';

ALTER TABLE Plate_Format DROP INDEX name;
CREATE INDEX name on Plate_Format (Plate_Format_Type);
CREATE INDEX wells on Plate_Format (Wells);

## Setting up stock Table
update DBField set field_format = '' where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') and field_name = 'stock_size';
update DBField set field_size = 5 where field_table = 'Stock'  and Field_Name in ( 'PO_Number', 'Requisition_Number');
update DBField set Field_Scope = 'Core'  WHERE  Field_Table = 'Stock' AND Field_Options <> 'Obsolete';
update DBField set field_options = 'Mandatory' where field_table = 'Stock' and field_name in ('fk_stock_catalog__id');
update DBField set field_options = 'Hidden' where field_table = 'Stock' and field_name in ('fk_orders__id');
update DBField set field_order = null where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock');
update DBField set field_order = 1 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') and field_name = 'Stock_ID';
update DBField set field_order = 2,prompt = 'Catalog ID' where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') and field_name = 'FK_Stock_Catalog__ID';
update DBField set field_order = 3 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') and field_name = 'stock_number_in_batch';
update DBField set field_order = 4 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') and field_name = 'FK_Grp__ID';
update DBField set field_order = 5 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') and field_name = 'stock_received';
update DBField set field_order = 6 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') and field_name = 'fk_employee__id';
update DBField set field_order = 7 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') and field_name = 'FK_Barcode_Label__ID';
update DBField set field_order = 8 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') and field_name = 'stock_cost';
update DBField set field_order = 9 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') and field_name = 'stock_lot_number';
update DBField set field_order = 10 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') and field_name = 'identifier_number';
update DBField set field_order = 11 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') and field_name = 'identifier_number_type';
update DBField set field_order = 12 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') and field_name = 'PO_Number';
update DBField set field_order = 13 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') and field_name = 'Requisition_Number';
update DBField set field_order = 14 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') and field_name = 'stock_notes';
update DBField set field_order = 15 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') and field_name = 'fk_box__id';
update DBField set field_order = 20 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') and field_name = 'fk_orders__id';
update DBField set Field_reference = 'Stock_Catalog_ID' Where Field_table = 'Stock' and Field_Name = 'FK_Stock_Catalog__ID';
update DBField set Editable = 'no'  WHERE Field_Table = 'Stock' AND Field_Name IN ('Stock_ID','FK_Stock_Catalog__ID' ,'Stock_Number_in_Batch','Stock_Received','FK_Employee__ID','FK_Box__ID');
update DBField set Tracked = 'yes'  WHERE Field_Table = 'Stock' AND Field_Name IN ('Stock_ID','FK_Stock_Catalog__ID' ,'Stock_Number_in_Batch','Stock_Received','FK_Employee__ID','FK_Box__ID','FK_Grp__ID','FK_Barcode_Label__ID','Stock_Cost','PO_Number','Requisition_Number');
update DBField set Prompt = 'Catalog' where field_name = 'FK_Stock_Catalog__ID' and field_table = 'Stock' ;
update DBField set Prompt = 'Purchase Order Number' where field_name = 'PO_Number' and field_table = 'Stock' ;
update DBField set field_reference = 'Concat(Stock_Catalog_Name,\'(\',Stock_Size,\' \',Stock_Size_Units,\')\')' where field_name = 'stock_id' and fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock') ;
        

## Setting up Stock Catalog table
update DBField set field_options = 'Mandatory' where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Stock_Catalog') and field_name in ('stock_source','fk_organization__id','stock_catalog_name','stock_size_units','Stock_Type','Stock_Status');
#update DBField set Field_Reference = "concat(Stock_Catalog_Name,' (' , Stock_Size,' ',Stock_Size_Units,')')"  WHERE Field_Name = 'Stock_Catalog_ID' AND Field_Table = 'Stock_Catalog';
update DBField set Field_Reference =  "CASE WHEN (Stock_Size_Units = 'n/a') THEN Stock_Catalog_Name ELSE concat(Stock_Catalog_Name,' (' , Stock_Size,' ',Stock_Size_Units,')') END" WHERE Field_Name = 'Stock_Catalog_ID' AND Field_Table = 'Stock_Catalog';
update DBField set Field_Reference = 'Equipment_Category_ID'  WHERE Field_Name = 'FK_Equipment_Category__ID' AND Field_Table = 'Stock_Catalog';
update DBField set Field_Reference = 'Organization_ID'  WHERE Field_Name = 'FKVendor_Organization__ID' AND Field_Table = 'Stock_Catalog';
update DBField set Field_Reference = 'Organization_ID'  WHERE Field_Name = 'FK_Organization__ID' AND Field_Table = 'Stock_Catalog';
update DBField set Prompt = 'Manufacturer' where field_name = 'fk_organization__id' and field_table = 'Stock_Catalog' ;
update DBField set Prompt = 'Category' where field_name = 'fk_Equipment_category__id' and field_table = 'Stock_Catalog' ;
update DBField set Prompt = 'Vendor' where field_name = 'fkvendor_organization__id' and field_table= 'Stock_Catalog' ;
update DBField set Prompt = 'Size' where field_name = 'Stock_Size' and field_table = 'Stock_Catalog' ;
update DBField set Prompt = 'Size Units' where field_name = 'Stock_Size_Units' and field_table= 'Stock_Catalog' ;
update DBField set Prompt = 'Catalog Name' where field_name = 'Stock_Catalog_Name' and field_table= 'Stock_Catalog' ;

update DBField set Prompt = "Category (Equipment Only)" Where Field_table = 'Stock_Catalog' and Field_Name = 'FK_Equipment_Category__ID';
update DBField set Field_Scope = 'Core'  WHERE  Field_Table = 'Stock_Catalog' AND Field_Options <> 'Obsolete';
update DBField set Tracked = 'yes'  WHERE Field_Table = 'Stock_Catalog'  AND Field_Name NOT IN ('Stock_Catalog_Description');
update DBField set Editable = 'no'  WHERE Field_Table = 'Stock_Catalog' AND Field_Name NOT IN ('Stock_Catalog_Description','Stock_Status');
update DBField set Field_Description = 'This is the organization that produces the product (Should be GSC for any item made in house)' WHERE Field_Table = 'Stock_Catalog' AND Field_Name = 'FK_Organization__ID';
update DBField set Field_Description = 'This is the organization that we purchase the product from' WHERE Field_Table = 'Stock_Catalog' AND Field_Name = 'FKVendor_Organization__ID';
update DBField set Field_Description = 'Select made in house for anything made in GSC, Order if it is bought from another organization, or box if it was part of a box' WHERE Field_Table = 'Stock_Catalog' AND Field_Name = 'Stock_Source';
update DBField set Field_Description = 'The number in vendors catalog for the item' WHERE Field_Table = 'Stock_Catalog' AND Field_Name = 'Stock_Catalog_Number';
update DBField set Field_Description = 'Applies to equipment' WHERE Field_Table = 'Stock_Catalog' AND Field_Name = 'Model';
update DBField set Field_Description = 'Applies to equipment ONLY' WHERE Field_Table = 'Stock_Catalog' AND Field_Name = 'FK_Equipment_Category__ID';

    
## Setting up Microarray , Box, Misc Tables
update DBField set field_options = 'Mandatory' where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name in ('Microarray','Box','Misc_Item')) and field_name IN ('fk_Rack__id','FK_Stock__ID');
update DBField set field_type = 'date' where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name ='Microarray') and field_name in ('Expiry_DateTime','Used_DateTime');
update DBField set field_order = 3 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Microarray') and field_name = 'Microarray_Number';
update DBField set field_order = 4 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Microarray') and field_name = 'Microarray_Number_in_Batch';
update DBField set field_order = 5 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Microarray') and field_name = 'FK_Rack__ID';
update DBField set field_order = 6 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Microarray') and field_name = 'Microarray_Type';
update DBField set field_order = 7 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Microarray') and field_name = 'Microarray_Status';
update DBField set field_order = 8 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Microarray') and field_name = 'Expiry_DateTime';
update DBField set field_order = 9 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Microarray') and field_name = 'Used_DateTime';
update DBField set Field_Scope = 'Custom'  WHERE  Field_Table = 'Microarray' AND Field_Options <> 'Obsolete';
update DBField set Field_reference = "Rack_ID" Where Field_table = 'Microarray' and Field_Name = 'FK_Rack__ID';
update DBField set Field_reference = "Stock_ID" Where Field_table = 'Microarray' and Field_Name = 'FK_Stock__ID';
update DBField set Editable = 'no'  WHERE Field_Table = 'Microarray' AND Field_Name IN ('Microarray_ID','FK_Stock__ID','Microarray_number','Microarray_Number_in_Batch');
update DBField set Tracked = 'yes'  WHERE Field_Table = 'Microarray' AND Field_Name IN ('Microarray_Number_In_Batch','Microarray_Type','FK_Stock__ID','Microarray_ID','Expiry_DateTime');
update DBField set Field_Scope = 'Core'  WHERE  Field_Table = 'Box' AND Field_Options <> 'Obsolete';
update DBField set Editable = 'no'  WHERE Field_Table = 'Box' AND Field_Name IN ('Box_ID','FK_Stock__ID','Box_Number','Box_Number_in_Batch');
update DBField set Tracked = 'yes'  WHERE Field_Table = 'Box' AND Field_Name IN ('Box_ID','FK_Stock__ID','Box_Number','Box_Number_in_Batch','FKParent_Box__ID','Serial Number');

    
## Settign up Solution Table
update DBField set field_options = 'Mandatory' where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Solution') and field_name IN ('Solution_Type','Solution_Status','FK_Stock__ID','Solution_Number');
update DBField set field_options = '' where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Solution') and field_name in ('Solution_Number_in_Batch');
update DBField set field_order = 3 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Solution') and field_name = 'FK_Rack__ID';
update DBField set field_order = 4 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Solution') and field_name = 'FK_Stock__ID';
update DBField set field_order = 5 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Solution') and field_name = 'FK_Solution_Info__ID';
update DBField set field_order = 6 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Solution') and field_name = 'Quantity_Used';
update DBField set field_order = 7 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Solution') and field_name = 'Solution_Quantity';
update DBField set field_order = 8 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Solution') and field_name = 'Solution_Expiry';
update DBField set field_order = 9 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Solution') and field_name = 'Solution_Started';
update DBField set field_order = 10 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Solution') and field_name = 'Solution_Finished';
update DBField set field_order = 11 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Solution') and field_name = 'Solution_Number';
update DBField set field_order = 12 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Solution') and field_name = 'Solution_Number_in_Batch';
update DBField set field_order = 13 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Solution') and field_name = 'QC_Status';
update DBField set field_order = 14 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Solution') and field_name = 'Solution_Status';
update DBField set field_order = 15 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Solution') and field_name = 'Solution_Label';
update DBField set field_order = 16 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Solution') and field_name = 'Solution_Notes';
update DBField set Field_Scope = 'Core'  WHERE  Field_Table = 'Solution' AND Field_Options <> 'Obsolete';
update DBField set Editable = 'no'  WHERE Field_Table = 'Solution' AND Field_Name IN ('Solution_ID','FK_Stock__ID','FK_Solution_Info__ID');
update DBField set Tracked = 'yes'  WHERE Field_Table = 'Solution' AND Field_Name IN ('Solution_Number_In_Batch','Solution_Type','FK_Stock__ID','FK_Solution_Info__ID','Solution_Expiry');
update DBField set Prompt = 'Solution' where field_name = 'Solution_ID' and field_table = 'Solution' ;
update DBField set Field_Description = 'Additional label to appear on barcode, besides name (Optional)' WHERE Field_Table  = 'Solution' AND Field_Name = 'Solution_Label';
update DBField set Field_Reference = "concat('Sol',Solution_ID,': ',Stock_Catalog_Name,' (',Solution_Number,'/',Solution_Number_in_Batch,')')" WHERE Field_Table = 'Solution' AND Field_Name = 'Solution_ID';
update DBField Set Field_Options = '' WHERE FIELD_TABLE = 'Solution' AND Field_Name = 'Solution_Quantity';

## Setting up Equipment Table
update DBField set field_options = 'Mandatory' where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Equipment') and field_name in ('fk_stock__id','Equipment_Name','FK_Location__ID','Equipment_Status');
update DBField set field_options = '' where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Equipment') and field_name in ('Equipment_Comments');
update DBField set field_size = 5 where field_table = 'Equipment'  and Field_Name in ('Serial_Number', 'Concurrency_ID' );
update DBField set field_order = 5 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Equipment') and field_name = 'FK_Location__ID';
update DBField set field_order = 20 where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Equipment') and field_name = 'Equipment_Comments';
update DBField set Prompt = 'Equipment' where field_name = 'Equipment_ID' and field_table = 'Equipment' ;
update DBField set Prompt = 'Equipment Name' where field_name = 'Equipment_Name' and field_table = 'Equipment' ;
#update DBField set Prompt = 'Category' where field_name = 'FK_Equipment_Category__ID' and field_table = 'Equipment' ;
update DBField set Field_Reference = "concat(Equipment_Name,' - EQU',Equipment_ID)"  WHERE Field_Name = 'Equipment_ID' AND Field_Table = 'Equipment';
update DBField set Field_Reference = 'Equipment_Category_ID'  WHERE Field_Name = 'FK_Equipment_Category__ID' AND Field_Table = 'Equipment';
update DBField set Editable = 'no'  WHERE Field_Table = 'Equipment' AND Field_Name IN ('FK_Stock__ID','Equipment_Name','Equipment_ID','FK_Equipment_Category__ID');
update DBField set Tracked = 'yes'  WHERE Field_Table = 'Equipment' AND Field_Name IN ('FK_Stock__ID','Equipment_Name','Equipment_ID');
update DBField set Field_Scope = 'Core'  WHERE  Field_Table = 'Equipment' AND Field_Options <> 'Obsolete';


## Setting up Category Table
update DBField set field_options = 'Mandatory' where fk_dbtable__id in (select dbtable_id from DBTable where dbtable_name = 'Equipment_Category') and field_name in ('category','prefix','Sub_Category');
update DBField set Prompt = 'Equipment Category' where field_name = 'Equipment_Category_ID' and field_table = 'Equipment_Category' ;
update DBField set Field_Reference = "concat(Category, '    ' ,Sub_Category,' (' ,Prefix,')')"  WHERE Field_Name = 'Equipment_Category_ID' AND Field_Table = 'Equipment_Category';
update DBField set Field_reference = "concat(Category,' - ',Sub_Category)" Where Field_table = 'Equipment_Category'and Field_Name = 'Equipment_Category_ID';
update DBField set Field_Scope = 'Core'  WHERE  Field_Table = 'Equipment_Category' AND Field_Options <> 'Obsolete';
update DBField set Tracked = 'yes'  WHERE Field_Table = 'Equipment_Category'  AND Field_Name <> 'Equipment_Description';
update DBField set Editable = 'no'  WHERE Field_Table = 'Equipment_Category' AND Field_Name <> 'Equipment_Description';





update DBField set Field_Scope = NULL   WHERE DBField_ID = '3654';

UPDATE DBField SET Field_Reference = 'Concat(Sample_Type_ID,\': \',Sample_Type)' WHERE FK_DBTable__ID IN (SELECT DBTable_ID from DBTable WHERE DBTable_Name = 'Sample_Type') AND Field_Name = 'Sample_Type_ID';

update DBField set prompt= 'Project Name' Where Field_Table= 'Project' and Field_name = 'Project_Name';
UPDATE DBField set Field_Options = 'Obsolete' where Field_Name = 'FK_Funding__ID' and Field_Table='Project';

update DBField set Field_Options = 'Hidden' where Concat(Field_Table,'.',Field_Name) IN ('Vector.Inducer','Vector.Vector_Sequence_Source','Vector.Substrate','Vector.Vector_Catalog_Number','Xformed_Cells.Cell_Catalog_Number','Xformed_Cells.Xform_Method','Xformed_Cells.FKSupplier_Organization__ID','Xformed_Cells.Sequencing_Type','Ligation.Sequencing_Type','Microtiter.Sequencing_Type','Microtiter.Cell_Catalog_Number');

update DBField set Field_Options = concat(Field_Options,',NewLink') where Field_Name like 'FKSupplier_Organization__ID';

update DBField set Prompt = 'Number of Plates' where field_table = 'Microtiter' and field_name = 'plates';

update DBField set Prompt = 'Number of Tubes' where field_table = 'Xformed_Cells' and field_name = 'tubes';
update DBTable set DBTable_Title = 'Transformed Cells' where DBTable_title = 'X-Formed Cells';

update DBField set field_options = '' where field_name = 'library_obtained_Date' and field_table = 'Library';

## Replace Library Goal with Work Request in DB_Form
update DB_Form set FKParent_DB_Form__ID = 29 where DB_Form_ID = 15;
update DB_Form set FKParent_DB_Form__ID = NULL where DB_Form_ID = 33;

## Replace the use of Work_Request_Type with the use of FK_Work_Request_Type__ID
update DBField set Field_Options = 'Hidden' where Field_Table = 'Work_Request' and Field_Name = 'Work_Request_Type';
update DBField set Field_Options = 'Mandatory', Prompt = 'Type', Field_Order = 8 where Field_Table = 'Work_Request' and Field_Name = 'FK_Work_Request_Type__ID';
update DB_Form set Parent_Field = 'FK_Work_Request_Type__ID' where Parent_Field = 'Work_Request_Type';

UPDATE DBField,DBTable SET Field_Options = Concat(Field_Options,',','Mandatory') WHERE FK_DBTable__ID=DBTable_ID AND CONCAT(DBTable_Name,'.',Field_Name) IN ('Array.FK_Microarray__ID','Array.FK_Plate__ID','Branch_Condition.FK_Object_Class__ID','Change_History.FK_DBField__ID','Child_Ordered_Procedure.FKChild_Ordered_Procedure__ID','Child_Ordered_Procedure.FKParent_Ordered_Procedure__ID','Clone_Alias.FK_Clone_Sample__ID','Clone_Sample.FKOriginal_Plate__ID','Clone_Sample.FK_Sample__ID','Clone_Sequence.FK_Note__ID','Clone_Sequence.FK_Run__ID','Clone_Sequence.FK_Sample__ID','Clone_Source.FK_Clone_Sample__ID','Communication.FK_Contact__ID','Communication.FK_Employee__ID','Communication.FK_Organization__ID','ConcentrationRun.FK_Equipment__ID','ConcentrationRun.FK_Plate__ID','Concentrations.FK_ConcentrationRun__ID','Contaminant.FK_Contamination__ID','Contaminant.FK_Run__ID','Cross_Match.FK_Run__ID','DBField.FK_DBTable__ID','DB_Login.FK_Employee__ID','Defined_Plate_Set.FK_Employee__ID','DepartmentSetting.FK_Department__ID','DepartmentSetting.FK_Setting__ID','EST_Library.FK_Sequencing_Library__ID','EmployeeSetting.FK_Employee__ID','EmployeeSetting.FK_Setting__ID','Extraction.FKSource_Plate__ID','Extraction.FKTarget_Plate__ID','Extraction_Details.FK_Band__ID','Extraction_Details.FK_Extraction_Sample__ID','Extraction_Sample.FKOriginal_Plate__ID','Extraction_Sample.FK_Sample__ID','Fail.FK_Employee__ID','Fail.FK_FailReason__ID','FailReason.FK_Grp__ID','FailureReason.FK_Grp__ID','Field_Map.FKTarget_DBField__ID','Field_Map.FK_Attribute__ID','Flowcell.FK_Tray__ID','GCOS_Config_Record.FK_GCOS_Config__ID','Gel.FK_Plate__ID','GelRun.FK_Run__ID','Genechip.FK_Microarray__ID','GenechipAnalysis.FK_Run__ID','GenechipAnalysis.FK_Sample__ID','GenechipExpAnalysis.FK_Run__ID','GenechipMapAnalysis.FK_Run__ID','GenechipRun.FK_Run__ID','How_To_Step.FK_How_To_Topic__ID','How_To_Topic.FK_How_To_Object__ID','Hybrid_Original_Source.FKChild_Original_Source__ID','Hybrid_Original_Source.FKParent_Original_Source__ID','Issue.FKAssigned_Employee__ID','Issue_Detail.FKSubmitted_Employee__ID','Issue_Detail.FK_Issue__ID','Issue_Log.FKSubmitted_Employee__ID','Issue_Log.FK_Issue__ID','Lab_Request.FK_Employee__ID','Lane.FK_GelRun__ID','Library_Attribute.FK_Attribute__ID','Library_Attribute.FK_Employee__ID','Library_Segment.FK_Antibiotic__ID','Library_Segment.FK_Restriction_Site__ID','Library_Segment.FK_Source__ID','Library_Segment.FK_Vector__ID','Library_Source.FK_Source__ID','Machine_Default.FK_Equipment__ID','Maintenance_Schedule.FK_Equipment__ID','Microarray.FK_Stock__ID','Optical_Density.FK_Plate__ID','Ordered_Procedure.FK_Object_Class__ID','Ordered_Procedure.FK_Pipeline__ID','Original_Source_Attribute.FK_Attribute__ID','Original_Source_Attribute.FK_Original_Source__ID','Pipeline.FK_Grp__ID','Pipeline_Step.FK_Object_Class__ID','Pipeline_Step.FK_Pipeline__ID','Pipeline_StepRelationship.FKChild_Pipeline_Step__ID','Pipeline_StepRelationship.FKParent_Pipeline_Step__ID','Plate_Attribute.FK_Plate__ID','Plate_Prep.FK_Plate__ID','Plate_Prep.FK_Prep__ID','Plate_Schedule.FK_Plate__ID','Plate_Set.FK_Plate__ID','Plate_Tray.FK_Plate__ID','PoolSample.FK_Sample__ID','Prep_Attribute.FK_Attribute__ID','Prep_Attribute.FK_Employee__ID','Prep_Attribute.FK_Prep__ID','Primer_Info.FK_Solution__ID','Printer_Assignment.FK_Label_Format__ID','Printer_Assignment.FK_Printer_Group__ID','Printer_Assignment.FK_Printer__ID','Probe_Set_Value.FK_GenechipExpAnalysis__ID','ProcedureTest_Condition.FK_Ordered_Procedure__ID','ProcedureTest_Condition.FK_Test_Condition__ID','Protocol_Step.FK_Employee__ID','Protocol_Tracking.FK_Grp__ID','RNA_DNA_Source.FK_Source__ID','RNA_DNA_Source_Attribute.FK_Attribute__ID','RNA_DNA_Source_Attribute.FK_RNA_DNA_Source__ID','ReArray_Attribute.FK_Attribute__ID','ReArray_Attribute.FK_ReArray__ID','ReArray_Plate.FK_Source__ID','ReArray_Request.FK_Status__ID','RunDataAnnotation.FK_Employee__ID','RunDataAnnotation.FK_RunDataAnnotation_Type__ID','RunDataReference.FK_RunDataAnnotation__ID','RunDataReference.FK_Run__ID','Run_Attribute.FK_Run__ID','SS_Config.FK_Sequencer_Type__ID','SS_Option.FK_SS_Config__ID','Sample_Alias.FK_Sample__ID','Sample_Attribute.FK_Attribute__ID','Sample_Attribute.FK_Sample__ID','Sample_Pool.FKTarget_Plate__ID','Sample_Pool.FK_Pool__ID','SequenceAnalysis.FK_SequenceRun__ID','SequenceRun.FK_Run__ID','SolexaAnalysis.FK_Run__ID','SolexaRun.FK_Flowcell__ID','SolexaRun.FK_Run__ID','Solution.FK_Stock__ID','Sorted_Cell.FK_Source__ID','Source_Attribute.FK_Attribute__ID','Source_Pool.FKParent_Source__ID','Submission_Alias.FK_Trace_Submission__ID','Submission_Detail.FKSubmission_DBTable__ID','Submission_Detail.FK_Submission__ID','Submission_Volume.FKSubmitter_Employee__ID','Subscriber.FK_Grp__ID','Subscriber.FK_Subscription__ID','Subscription.FK_Subscription_Event__ID','Suggestion.FK_Employee__ID','Tissue_Source.FK_Source__ID','TraceData.FK_Run__ID','Trace_Submission.FK_Run__ID','Trace_Submission.FK_Sample__ID','Trace_Submission.FK_Submission_Volume__ID','Transposon.FK_Organization__ID','Transposon_Library.FK_Sequencing_Library__ID','Transposon_Pool.FK_Source__ID','UseCase.FK_Employee__ID','UseCase_Step.FK_UseCase__ID','VectorPrimer.FK_Primer__ID','VectorPrimer.FK_Vector__ID','Vector_TypeAntibiotic.FK_Antibiotic__ID','Warranty.FK_Equipment__ID','Warranty.FK_Organization__ID','WorkLog.FK_Employee__ID','WorkLog.FK_Issue__ID','WorkPackage.FK_Issue__ID','WorkPackage_Attribute.FK_Attribute__ID','Band.FK_Lane__ID','Box.FK_Stock__ID','Clone_Details.FK_Clone_Sample__ID','Mixture.FKMade_Solution__ID','MultiPlate_Run.FKMaster_Run__ID','MultiPlate_Run.FK_Run__ID','Plate.FK_Employee__ID','Plate_Attribute.FK_Attribute__ID','Plate_PrimerPlateWell.FK_Plate__ID','Plate_PrimerPlateWell.FK_Primer_Plate_Well__ID','Plate_Sample.FKOriginal_Plate__ID','Plate_Sample.FK_Sample__ID','Plate_Tray.FK_Tray__ID','ReArray.FKSource_Plate__ID','ReArray_Request.FKTarget_Plate__ID','Run.FK_RunBatch__ID','Sample.FK_Source__ID');

update DBField set Field_Options = concat(Field_Options,',Searchable') where Field_Name like '%Organization__ID';
update DBField set Field_options = 'Obsolete' WHERE Field_Name = 'FK_Organization__ID' and Field_Table IN ('Stock','Equipment');

update DBField set Field_Description = "Please contact Admins if the list of work request type doesn't fit your need" where Field_Table = 'Work_Request' and Field_Name = 'FK_Work_Request_Type__ID';

update DBField set Field_Description = "Select the furthest stage to process plates to" where Field_Table = 'Work_Request' and Field_Name = 'FK_Goal__ID';

update DBField set Field_Description = "Format in which the starting material is stored. Xformed_Cells is short for Transformed_Cells." where Field_Table = 'Source' and Field_Name = 'Source_Type';

update DBField set Field_Options = '' where Field_Table = 'Ligation' and Field_Name = 'Ligation_Volume';

UPDATE DBTable SET DBTable_Title = 'Addon_Package' WHERE DBTable_Name = 'Package';
UPDATE DBTable SET DBTable_Title = 'DB_Patch' WHERE DBTable_Name = 'Patch';

update DBField set Field_Options = 'Obsolete' where Field_Table = 'Plate' AND Field_Name = 'Plate_Content_Type';

UPDATE DBField,DBTable SET Field_Options = CASE WHEN Field_Options = '' THEN 'Mandatory' ELSE CONCAT(Field_Options,',Mandatory') END WHERE FK_DBTable__ID=DBTable_ID AND CONCAT(DBTable_Name,'.',Field_Name) IN ('Array.FK_Microarray__ID','Array.FK_Plate__ID','Branch_Condition.FK_Object_Class__ID','Change_History.FK_DBField__ID','Child_Ordered_Procedure.FKChild_Ordered_Procedure__ID','Child_Ordered_Procedure.FKParent_Ordered_Procedure__ID','Clone_Alias.FK_Clone_Sample__ID','Clone_Sample.FKOriginal_Plate__ID','Clone_Sample.FK_Sample__ID','Clone_Sequence.FK_Note__ID','Clone_Sequence.FK_Run__ID','Clone_Sequence.FK_Sample__ID','Clone_Source.FK_Clone_Sample__ID','Communication.FK_Contact__ID','Communication.FK_Employee__ID','Communication.FK_Organization__ID','ConcentrationRun.FK_Equipment__ID','ConcentrationRun.FK_Plate__ID','Concentrations.FK_ConcentrationRun__ID','Contaminant.FK_Contamination__ID','Contaminant.FK_Run__ID','Cross_Match.FK_Run__ID','DBField.FK_DBTable__ID','DB_Login.FK_Employee__ID','Defined_Plate_Set.FK_Employee__ID','DepartmentSetting.FK_Department__ID','DepartmentSetting.FK_Setting__ID','EST_Library.FK_Sequencing_Library__ID','EmployeeSetting.FK_Employee__ID','EmployeeSetting.FK_Setting__ID','Extraction.FKSource_Plate__ID','Extraction.FKTarget_Plate__ID','Extraction_Details.FK_Band__ID','Extraction_Details.FK_Extraction_Sample__ID','Extraction_Sample.FKOriginal_Plate__ID','Extraction_Sample.FK_Sample__ID','Fail.FK_Employee__ID','Fail.FK_FailReason__ID','FailReason.FK_Grp__ID','FailureReason.FK_Grp__ID','Field_Map.FKTarget_DBField__ID','Field_Map.FK_Attribute__ID','Flowcell.FK_Tray__ID','GCOS_Config_Record.FK_GCOS_Config__ID','Gel.FK_Plate__ID','GelRun.FK_Run__ID','Genechip.FK_Microarray__ID','GenechipAnalysis.FK_Run__ID','GenechipAnalysis.FK_Sample__ID','GenechipExpAnalysis.FK_Run__ID','GenechipMapAnalysis.FK_Run__ID','GenechipRun.FK_Run__ID','How_To_Step.FK_How_To_Topic__ID','How_To_Topic.FK_How_To_Object__ID','Hybrid_Original_Source.FKChild_Original_Source__ID','Hybrid_Original_Source.FKParent_Original_Source__ID','Issue.FKAssigned_Employee__ID','Issue_Detail.FKSubmitted_Employee__ID','Issue_Detail.FK_Issue__ID','Issue_Log.FKSubmitted_Employee__ID','Issue_Log.FK_Issue__ID','Lab_Request.FK_Employee__ID','Lane.FK_GelRun__ID','Library_Attribute.FK_Attribute__ID','Library_Attribute.FK_Employee__ID','Library_Segment.FK_Antibiotic__ID','Library_Segment.FK_Restriction_Site__ID','Library_Segment.FK_Source__ID','Library_Segment.FK_Vector__ID','Library_Source.FK_Source__ID','Machine_Default.FK_Equipment__ID','Maintenance_Schedule.FK_Equipment__ID','Microarray.FK_Stock__ID','Optical_Density.FK_Plate__ID','Ordered_Procedure.FK_Object_Class__ID','Ordered_Procedure.FK_Pipeline__ID','Original_Source_Attribute.FK_Attribute__ID','Original_Source_Attribute.FK_Original_Source__ID','Pipeline.FK_Grp__ID','Pipeline_Step.FK_Object_Class__ID','Pipeline_Step.FK_Pipeline__ID','Pipeline_StepRelationship.FKChild_Pipeline_Step__ID','Pipeline_StepRelationship.FKParent_Pipeline_Step__ID','Plate_Attribute.FK_Plate__ID','Plate_Prep.FK_Plate__ID','Plate_Prep.FK_Prep__ID','Plate_Schedule.FK_Plate__ID','Plate_Set.FK_Plate__ID','Plate_Tray.FK_Plate__ID','PoolSample.FK_Sample__ID','Prep_Attribute.FK_Attribute__ID','Prep_Attribute.FK_Employee__ID','Prep_Attribute.FK_Prep__ID','Primer_Info.FK_Solution__ID','Printer_Assignment.FK_Label_Format__ID','Printer_Assignment.FK_Printer_Group__ID','Printer_Assignment.FK_Printer__ID','Probe_Set_Value.FK_GenechipExpAnalysis__ID','ProcedureTest_Condition.FK_Ordered_Procedure__ID','ProcedureTest_Condition.FK_Test_Condition__ID','Protocol_Step.FK_Employee__ID','Protocol_Tracking.FK_Grp__ID','RNA_DNA_Source.FK_Source__ID','RNA_DNA_Source_Attribute.FK_Attribute__ID','RNA_DNA_Source_Attribute.FK_RNA_DNA_Source__ID','ReArray_Attribute.FK_Attribute__ID','ReArray_Attribute.FK_ReArray__ID','ReArray_Plate.FK_Source__ID','ReArray_Request.FK_Status__ID','RunDataAnnotation.FK_Employee__ID','RunDataAnnotation.FK_RunDataAnnotation_Type__ID','RunDataReference.FK_RunDataAnnotation__ID','RunDataReference.FK_Run__ID','Run_Attribute.FK_Run__ID','SS_Config.FK_Sequencer_Type__ID','SS_Option.FK_SS_Config__ID','Sample_Alias.FK_Sample__ID','Sample_Attribute.FK_Attribute__ID','Sample_Attribute.FK_Sample__ID','Sample_Pool.FKTarget_Plate__ID','Sample_Pool.FK_Pool__ID','SequenceAnalysis.FK_SequenceRun__ID','SequenceRun.FK_Run__ID','SolexaAnalysis.FK_Run__ID','SolexaRun.FK_Flowcell__ID','SolexaRun.FK_Run__ID','Solution.FK_Stock__ID','Sorted_Cell.FK_Source__ID','Source_Attribute.FK_Attribute__ID','Source_Pool.FKParent_Source__ID','Submission_Alias.FK_Trace_Submission__ID','Submission_Detail.FKSubmission_DBTable__ID','Submission_Detail.FK_Submission__ID','Submission_Volume.FKSubmitter_Employee__ID','Subscriber.FK_Grp__ID','Subscriber.FK_Subscription__ID','Subscription.FK_Subscription_Event__ID','Suggestion.FK_Employee__ID','Tissue_Source.FK_Source__ID','TraceData.FK_Run__ID','Trace_Submission.FK_Run__ID','Trace_Submission.FK_Sample__ID','Trace_Submission.FK_Submission_Volume__ID','Transposon.FK_Organization__ID','Transposon_Library.FK_Sequencing_Library__ID','Transposon_Pool.FK_Source__ID','UseCase.FK_Employee__ID','UseCase_Step.FK_UseCase__ID','VectorPrimer.FK_Primer__ID','VectorPrimer.FK_Vector__ID','Vector_TypeAntibiotic.FK_Antibiotic__ID','Warranty.FK_Equipment__ID','Warranty.FK_Organization__ID','WorkLog.FK_Employee__ID','WorkLog.FK_Issue__ID','WorkPackage.FK_Issue__ID','WorkPackage_Attribute.FK_Attribute__ID','Band.FK_Lane__ID','Box.FK_Stock__ID','Clone_Details.FK_Clone_Sample__ID','Mixture.FKMade_Solution__ID','MultiPlate_Run.FKMaster_Run__ID','MultiPlate_Run.FK_Run__ID','Plate.FK_Employee__ID','Plate_Attribute.FK_Attribute__ID','Plate_PrimerPlateWell.FK_Plate__ID','Plate_PrimerPlateWell.FK_Primer_Plate_Well__ID','Plate_Sample.FKOriginal_Plate__ID','Plate_Sample.FK_Sample__ID','Plate_Tray.FK_Tray__ID','ReArray.FKSource_Plate__ID','ReArray_Request.FKTarget_Plate__ID','Run.FK_RunBatch__ID');


update DBField set Field_Description = 'The organization which this location belongs to' WHERE Field_Table= 'Location' and Field_Name = 'FK_Organization__ID';



## Remove Primer LibraryApplication with Library and use Primer LibraryApplication with Work_Request instead
update DB_Form set FKParent_DB_Form__ID = NULL where DB_Form_ID = 43;

## Make Goal and Goal Target Mandatory
update DBField set Field_Options = 'Mandatory' where Field_Table = 'Work_Request' and Field_Name = 'FK_Goal__ID';
update DBField set Field_Options = 'Mandatory' where Field_Table = 'Work_Request' and Field_Name = 'Goal_Target';

## Update Prompt for FK_Sample_Type__ID in Plate
update DBField set Prompt = 'Sample Type' where Field_Table = 'Plate' and Field_Name = 'FK_Sample_Type__ID';

## Update Field_Reference for Sample_Type
## update DBField set Field_Reference = 'Sample_Type.Sample_Type' where Field_Name = 'Sample_Type_ID';

## Update Field_Reference for Work_Request_ID
update DBField set Field_Reference = "CASE WHEN LENGTH(Work_Request_Title) > 0 THEN CONCAT(Work_Request_ID,': ',Work_Request_Title) ELSE CONCAT(Work_Request_ID,': ', Goal_Name, ' for ', Funding_Name,' - ',Work_Request.FK_Library__Name, ' - ', Goal_Target_Type) END" where Field_Table = 'Work_Request' and Field_Name = 'Work_Request_ID';

##Line moved to upgrade_2.6_final in Plugins/Sequencing/install/...:
#update DBField set field_options = 'Mandatory' where field_table = 'Vector_Based_Library' and field_name = 'blue_white_selection';
 
update DBField SET Field_Reference = "CONCAT(Package_ID,': ',Package_Name)" WHERE Field_Name = 'Package_ID';

update DBField SET Field_Description = 'Filename of patch' WHERE Field_Name = 'Patch_Name';

## Change Source.Label to Source.Source_Label
update DBField set field_description = 'Label attached to the sample container', Field_Index = 'MUL', Field_Format = '^.{0,40}$', Tracked = 'yes', Field_Scope = NULL where field_table = 'Source' and field_name = 'Source_Label';
delete from DBField where Field_Table = 'Source' and Field_Name = 'Label';

## Update Work_Request_Title here so that it is done after upgrade_2.6.pl
#update Work_Request,Goal set Work_Request_Title = Concat(Goal_Name, ' for ' , FK_Library__Name)  Where FK_Goal__ID = Goal_ID ;

update DBField set Field_options= '' WHERE Field_Table = 'Stock_Catalog' and Field_Name = 'Stock_Size';

########## Site and organization
update DBField set Field_Reference = 'Site_ID' WHERE Field_Table = 'Organization' And  Field_name = 'FK_Site__ID';
update DBField set Field_Reference = 'Site_Name' WHERE Field_Table = 'Site' And  Field_name = 'Site_ID';
update DBField set Prompt = 'Site' WHERE Field_Table = 'Site' And  Field_name = 'Site_ID';
update DBField set Editable = 'no' WHERE Field_Table = 'Site' And  Field_name IN ('Site_Name','Site_ID');
update DBField set Tracked = 'yes' WHERE Field_Table = 'Site' And  Field_name IN ('Site_Name','Site_ID');
update DBField set Field_Scope = 'Core' WHERE Field_Table = 'Site' ;
   
########## TEMP
update DBField set Field_Options =  ''  where Field_Name = 'FK_Organization__ID'  and Field_table = 'Stock_Catalog';
update DBField set Field_Options =  ''  where Field_Name IN ('FK_Location__ID')   and Field_table = 'Equipment';


###Make Plate.FK_Sample_Type__ID mandatory
update DBField set Field_Options='Mandatory' where Field_Table = 'Plate' and Field_Name = 'FK_Sample_Type__ID';
update DBField Set Field_Options = 'Obsolete'  WHERE Field_Table = 'Microtiter' AND Field_NAme = 'Plate_Size';


Create INDEX lpw ON Sample (FK_Library__Name,Plate_Number,Original_Well);
Create INDEX type ON Sample (FK_Sample_Type__ID);
Create INDEX orig ON Sample (FKOriginal_Plate__ID); 

create index Catalog_ID on Stock (FK_Stock_Catalog__ID);
create index category_id on Stock_Catalog (FK_Equipment_Category__ID);
create index Catalog_Name on Stock_Catalog (Stock_Catalog_Name);
create index Catalog_Number on Stock_Catalog (Stock_Catalog_Number);
create index FK_Organization__ID on Stock_Catalog (FK_Organization__ID);
create index type on Stock_Catalog (Stock_Type);
create index source on Stock_Catalog (Stock_Source);
create index size on Stock_Catalog (Stock_Size, Stock_Size_Units);

create unique index condition on Branch_Condition (Object_ID, FK_Object_Class__ID,FK_Pipeline__ID,FKParent_Branch__Code, Branch_Condition_Status);
</FINAL>
