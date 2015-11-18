# Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
## Patch Table

### Add reference to Plate_Format in pipeline to enable automatic format specific pipelines ###

alter table Lab_Protocol modify Max_Tracking_Size enum('384','96','1') Default '384';
ALTER TABLE Plate_Format MODIFY Well_Capacity_mL FLOAT;
ALTER TABLE DBField ADD FKParent_DBField__ID INT;
ALTER TABLE DBField ADD Parent_Value VARCHAR(255);
ALTER TABLE DBField MODIFY Field_Options set('Hidden','Mandatory','Primary','Unique','NewLink','ViewLink','ListLink','Searchable','Obsolete','ReadOnly','Required') Default NULL;
ALTER TABLE Protocol_Step ADD Repeatable ENUM('Yes','No','') DEFAULT '';

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


## PRimer Validation Auttomation
insert into DB_Trigger (Table_Name,DB_Trigger_Type,Value,Trigger_On,Status,Trigger_Description,Fatal) 
values('Vector_Type','Perl','require alDente::Vector; my $ok = alDente::Vector::new_Vector_trigger(-dbc=>$self,-id=><ID>);','insert','Active','Anytime a vector is added primers should be validated for it accordingly','No');
insert into DB_Trigger (Table_Name,DB_Trigger_Type,Value,Trigger_On,Status,Trigger_Description,Fatal) 
values('Primer','Method','new_Primer_trigger','insert','Active','Anytime a primer is added vectors should be validated for it accordingly','No');


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
## Sample
update DBField set Field_Options = 'Hidden' WHERE Field_Table = 'Sample' and Field_Name = 'Sample_Type';
## Extraction_Sample
INSERT INTO DBField (Field_Table,Prompt,Field_Alias, Field_Order,Field_Name,Field_Type,FK_DBTable__ID,Field_Scope) values ("Protocol_Step","Repeatable","Repeatable",16,"Repeatable","enum('Yes','No','')",67,"Custom");

## Clone_Sample
update DBField set Field_Options = 'Hidden' WHERE Field_Table = 'Extraction_Sample' and Field_Name = 'FK_Library__Name';
update DBField set Field_Options = 'Hidden' WHERE Field_Table = 'Extraction_Sample' and Field_Name = 'Plate_Number';
update DBField set Field_Options = 'Hidden' WHERE Field_Table = 'Extraction_Sample' and Field_Name = 'Original_Well';

UPDATE  DBField SET Editable = 'no'  WHERE Field_Options LIKE '%Primary%';
UPDATE DBField set Tracked = 'yes' WHERE Field_Table = 'Department';

UPDATE  DBField SET Editable = 'no'  WHERE Field_Table IN  ('Hybrid_Original_Source','Jira','Mixture','Prep');
UPDATE DBField SET Field_Options =  concat(Field_Options,',ReadOnly')  WHERE Field_Table IN  ('Hybrid_Original_Source','Jira','Mixture','Prep') and Field_Options NOT LIKE '%Primary%' and Field_Options <> '';
UPDATE DBField SET Field_Options =  'ReadOnly'  WHERE Field_Table IN  ('Hybrid_Original_Source','Jira','Mixture','Prep') and Field_Options NOT LIKE '%Primary%' and Field_Options = '';
UPDATE DBField set Editable = 'no' WHERE Field_Table = 'Plate_Prep' and Field_Name IN ('FK_Plate__ID','FK_Prep__ID','FK_Plate_Set__Number');
UPDATE DBTable set DBTable_Type = 'DB Management' WHERE DBTable_Name IN ('Patch','Package','Version');
UPDATE DBTable set DBTable_Type= 'Recursive Lookup'  WHERE DBTable_Name LIKE 'Sample_Type';

UPDATE DBTable, DBField SET Editable = 'no', Tracked= 'yes'  WHERE FK_DBTable__ID = DBTable_ID and DBTable_Type = 'DB Management';
UPDATE DBTable, DBField SET Editable = 'no'  WHERE FK_DBTable__ID = DBTable_ID and DBTable_Type = 'Join';
UPDATE DBTable, DBField SET Editable = 'no'  WHERE FK_DBTable__ID = DBTable_ID and DBTable_Type LIKE '%Lookup%';

SET @a = (select DBField_ID from DBField where Field_Table = 'Original_Source' AND Field_Name = 'Disease_Status');
UPDATE DBField SET FKParent_DBField__ID = @a, Parent_Value = 'Diseased' WHERE Field_Table = 'Original_Source' AND Field_Name IN
 ('FK_Pathology__ID','Pathology_Type','Pathology_Grade','Pathology_Stage','Invasive','Metastatic');

SET @b = (select DBField_ID from DBField where Field_Table = 'Original_Source' AND Field_Name = 'Original_Source_Type');
UPDATE DBField SET FKParent_DBField__ID = @b, Parent_Value = 'Cell_Line' WHERE Field_Table = 'Original_Source' AND Field_Name IN
 ('FK_Cell_Line__ID');


UPDATE DBField as parent, DBField as child set child.FKParent_DBField__ID = parent.DBField_ID  WHERE parent.Field_Name = 'Shipment_Type' and child.Field_Name IN ('Waybill_Number', 'Package_Conditions');
update DBField set Parent_Value = 'Import' WHERE Field_Name IN ('Waybill_Number', 'Package_Conditions');
update DBField set Field_Options = 'Required' WHERE Field_Table = 'Original_Source' and Field_Name IN ('FK_Cell_Line__ID','FK_Pathology__ID','Pathology_Type');

update DBField set List_Condition="<Original_Source.Original_Source_Type> = Anatomic_Site.Anatomic_Site_Type" where Field_Table = 'Original_Source' AND Field_Name IN ('FK_Pathology__ID','FK_Anatomic_Site__ID');

UPDATE DBField SET Field_Options = 'Mandatory'  WHERE Field_Name IN ('Anatomic_Site_Type','Original_Source_Type');
<\FINAL>
