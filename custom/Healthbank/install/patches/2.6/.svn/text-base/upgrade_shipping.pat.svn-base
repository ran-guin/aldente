## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

insert into Department values ('','BCG_Mobile','Active');
insert into Grp select '','Mobile',Department_ID,'Lab','Lab','Active' from Department where Department_name = 'BCG_Mobile';
insert into GrpEmployee select '',Grp_ID,Employee_ID from Grp,Employee where Grp_Name = 'Mobile' AND Employee_Name in ('tmcdonald','Rguin','Admin','LabAdmin');
update Department set Department_Name = 'BC_Generations' where Department_Name like 'Healthbank';

INSERT INTO Lab_Protocol values ('Add to Sample Shipment',1,'Inactive','Collect Samples into Transporter Box', '', '','','Yes');

insert into Protocol_Step select 1,'Insert into Transporter Box','','','','FK_Rack__ID:Mandatory_Rack',0,'Scan Transporter Box',1,'','',Lab_Protocol_ID, '','','' from Lab_Protocol where Lab_Protocol_Name like 'Add to Sample Shipment';

UPDATE Protocol_Step,Lab_Protocol set Protocol_Step_Number = Protocol_Step_Number + 3 WHERE FK_Lab_Protocol__ID=Lab_Protocol_ID AND Lab_Protocol_Name = 'EDTA Tube SOP';

UPDATE Protocol_Step,Lab_Protocol set Input=Concat(Input,':Mandatory_Rack') WHERE FK_Lab_Protocol__ID=Lab_Protocol_ID AND Lab_Protocol_Name ='EDTA Tube SOP' AND Input like '%FK_Rack__ID';

INSERT INTO Protocol_Step SELECT 1,'Pre-Print Blood Plasma out to cryovial','pre-print barcodes for plasma cryovials','',3,'Split',1, 'apply barcodes to cryovials for Plasma',1,'','',Lab_Protocol_ID,'','','' FROM Lab_Protocol where Lab_Protocol_Name = 'EDTA Tube SOP';
INSERT INTO Protocol_Step SELECT 2,'Pre-Print White Blood Cells out to cryovial','pre-print barcodes for WBC cryovials','','','',1, 'apply barcodes to cryovials for White Blood Cells',1,'','',Lab_Protocol_ID,'','','' FROM Lab_Protocol where Lab_Protocol_Name = 'EDTA Tube SOP';
INSERT INTO Protocol_Step SELECT 3,'Pre-Print Red Blood Cells out to cryovial','pre-print barcodes for RBC cryovials','','','',1, 'apply barcodes to cryovials for Red Blood Cells',1,'','',Lab_Protocol_ID,'','','' FROM Lab_Protocol where Lab_Protocol_Name = 'EDTA Tube SOP';

INSERT INTO Attribute values ('','Max_Transit_Temp_in_C','text','Int',0,'No','Prep');
INSERT INTO Attribute values ('','Min_Transit_Temp_in_C','text','Int',0,'No','Prep');
INSERT INTO Attribute values ('','Waybill_Number','text','Int',0,'No'        ,'Prep');
INSERT INTO Attribute values ('','Data_Logger_Serial_No','text','Int',0,'No'        ,'Prep');
INSERT INTO Attribute values ('','Shipping_Temp_in_C','text','Int',0,'No'        ,'Prep');
INSERT INTO Attribute values ('','Shipper','text','Int',0,'No'        ,'Prep');

INSERT INTO Site Values ('','Echelon','Suite 100 - 570 West 7th Ave', 'Vancouver', 'BC','Canada','V5Z 4S6');

update Site set Site_Address = 'Suite 100 - 570 West 7th Ave', Site_City = 'Vancouver', Site_State = 'BC',Site_Country='Canada', Site_Zip = 'V5Z 4S6' WHERE Site_Name IN ('Freezer Farm','Echelon');

update Site set Site_Address = '7-208 675 West 10th Ave', Site_City = 'Vancouver', Site_State = 'BC',Site_Country='Canada', Site_Zip = 'V5Z 1L3' WHERE Site_Name like 'CRC';

update Site set Site_Address = '2775 Laurel St', Site_City = 'Vancouver', Site_State = 'BC',Site_Country='Canada', Site_Zip = 'V5Z 1M9' WHERE Site_Name like 'DHCC';


UPDATE Protocol_Step set Scanner = 1, Input = 'Prep_Attribute=Waybill_Number:Prep_Attribute=Shipping_Temp_in_C:Prep_Attribute=Shipper:Prep_Attribute=Data_Logger_Serial_No:Prep_Comments' WHERE Protocol_Step_Name = 'Export Samples';

UPDATE Protocol_Step set Scanner=1, Input = 'Prep_Attribute=Max_Transit_Temp_in_C:Prep_Attribute=Min_Transit_Temp_in_C:Prep_Comments' WHERE Protocol_Step_Name = 'Receive Sample Shipment';

update Protocol_Step set Input = CASE WHEN Length(Input) > 2 THEN concat(Input,':Prep_Comments') ELSE 'Prep_Comments' END WHERE FK_Lab_Protocol__ID >2 and Input NOT LIKE '%Prep_Comments';

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
