## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
ALTER TABLE Pipeline ADD FKApplicable_Plate_Format__ID INT;
create index plate_format on Pipeline (FKApplicable_Plate_Format__ID);

### Moving Plate_Class to Plate from Library_Plate ###
alter table Plate add Plate_Class enum('Standard','Extraction','ReArray','Oligo') NULL default 'Standard';

ALTER TABLE Source MODIFY Source_Label VARCHAR(40) NOT NULL;
</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


INSERT INTO Equipment_Category VALUES ('','NA','','N/A','Undefined Items');
INSERT INTO Stock_Catalog select '','Undefined','Undefined Equipment Items','','Equipment','','Inactive',1,'pcs',0,0,'',Equipment_Category_ID from Equipment_Category where Category = 'N/A';

Insert into Stock (FK_Employee__ID,Stock_Number_in_Batch,FK_Grp__ID,FK_Barcode_Label__ID,FK_Stock_Catalog__ID) select 1,0,Grp_ID,0,Stock_Catalog_ID from Grp,Stock_Catalog where Grp_Name = 'Public' AND Stock_Catalog_Name = 'Undefined';
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
