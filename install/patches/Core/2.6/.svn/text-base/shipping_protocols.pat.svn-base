## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Site add (Site_Address varchar(80), Site_City varchar(40), Site_State varchar(20), Site_Zip varchar(10), Site_Country varchar(40));

alter table Printer_Group add (FK_Site__ID INT NOT NULL, Printer_Group_Status enum('Active','Inactive') default 'Active');

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

### Moving Plate_Class to Plate from Library_Plate ###

INSERT INTO Equipment_Category values ('','Site','Virtual','Storage','Meta-equipment for tracking general Locations untied to Freezers');
INSERT INTO Stock_Catalog Values ('','Virtual Storage','Meta-equipment for tracking general Locations unrelated to Freezers','','Equipment','Virtual','Active','','','','','','');
insert into Stock (FK_Employee__ID,FK_Grp__ID,FK_Barcode_Label__ID, FK_Stock_Catalog__ID) select 1,Grp_ID,Barcode_Label_ID,Stock_Catalog_ID from Stock_Catalog,Grp,Barcode_Label where Grp_Name = 'Public' AND Stock_Catalog_Name = 'Virtual Storage' AND Barcode_Label_Name = 'equip_label';

UPDATE Stock_Catalog,Equipment_Category set FK_Equipment_Category__ID = Equipment_Category_ID WHERE Stock_Catalog_Name = 'Virtual Storage' AND Category = 'Storage' AND Sub_Category = 'Virtual';

INSERT INTO Equipment (Equipment_Name, Equipment_Number, FK_Stock__ID, Equipment_Status, FK_Location__ID) SELEct Concat('Site-',FK_Site__ID),FK_Site__ID,Stock_ID,'In Use',Location_ID from Location,Stock,Stock_Catalog,Equipment_Category where Prefix='Site' AND FK_Stock_Catalog__ID=Stock_Catalog_ID AND Stock_Catalog_Name = 'Virtual Storage' GROUP BY FK_Site__ID;

## get rid of old records if they were in there ##
DELETE from Lab_Protocol WHERE Lab_Protocol_Name IN ('Export Samples','Receive Samples');
DELETE from Protocol_Step WHERE Protocol_Step_Name IN ('Export Samples','Receive Sample Shipment');

INSERT INTO Lab_Protocol values ('Export Samples',1,'Inactive','Export sample to another site', '', '','','Yes');
INSERT INTO Lab_Protocol values ('Receive Samples',1,'Inactive','Receive samples exported from another site', '', '','','Yes');

insert into Protocol_Step select 1,'Export Samples','','','','Prep_Comments',1,'',1,'','',Lab_Protocol_ID, '','','' from Lab_Protocol where Lab_Protocol_Name like 'Export Samples';
insert into Protocol_Step select 1,'Receive Sample Shipment','','','','Prep_Comments',1,'',1,'','',Lab_Protocol_ID, '','','' from Lab_Protocol where Lab_Protocol_Name like 'Receive Samples';

## ADD In Transit Rack and Location ##
insert into Location select '','In Transit','active',Site_ID,'External' from Site where Site_Name = 'External';
insert into Rack SELECT '',Equipment_ID,'Shelf','In Transit','N','In Transit',0 from Equipment,Location where FK_Location__ID=Location_ID AND Equipment_Name = "In Transit";
update Equipment,Location set FK_Location__ID=Location_ID WHERE Equipment_Name = 'In Transit' AND Location_Name = 'In Transit';


insert into `Trigger` values ('','Site','Perl',"require alDente::Equipment; my $ok = alDente::Equipment::new_site(-dbc=>$self, -id=><ID>); ", 'insert','Active','Add generic location & Equipment records when new site added', 'No');

</DATA>
<CODE_BLOCK> 
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below
if (_check_block('NAME_GOES_HERE')) { 
		


}
</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

</FINAL>
