## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Add Plate.Failed column.
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
ALTER TABLE Plate ADD Failed enum('Yes', 'No') NOT NULL DEFAULT 'No';
</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
UPDATE Plate SET Failed = 'Yes' WHERE Plate_Status = 'Failed';
</DATA>

<CODE_BLOCK>

## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below
</CODE_BLOCK>

<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)
UPDATE DBField set Prompt = 'Plate Status', Field_Alias = 'Plate_Status' where Field_Table = 'Plate' and Field_Name = 'Plate_Status'; 
UPDATE DBField set Field_Order = 16, Field_Options = 'Mandatory', Editable = 'no', Tracked = 'no' where Field_Table = 'Plate' and Field_Name = 'Failed'; 
UPDATE DBField set Field_Order = 17 where Field_Table = 'Plate' and Field_Name = 'FK_Rack__ID';
UPDATE DBField set Field_Order = 18 where Field_Table = 'Plate' and Field_Name = 'Current_Volume';
UPDATE DBField set Field_Order = 19 where Field_Table = 'Plate' and Field_Name = 'Current_Volume_Units';
UPDATE DBField set Field_Order = 20 where Field_Table = 'Plate' and Field_Name = 'Plate_Test_Status';
UPDATE DBField set Field_Order = 21 where Field_Table = 'Plate' and Field_Name = 'Parent_Quadrant';
UPDATE DBField set Field_Order = 22 where Field_Table = 'Plate' and Field_Name = 'Plate_Parent_Well';
UPDATE DBField set Field_Order = 23 where Field_Table = 'Plate' and Field_Name = 'QC_Status';
UPDATE DBField set Field_Order = 24 where Field_Table = 'Plate' and Field_Name = 'Plate_Type';
UPDATE DBField set Field_Order = 25 where Field_Table = 'Plate' and Field_Name = 'FKOriginal_Plate__ID';
UPDATE DBField set Field_Order = 26 where Field_Table = 'Plate' and Field_Name = 'FK_Branch__Code';
UPDATE DBField set Field_Order = 27 where Field_Table = 'Plate' and Field_Name = 'Plate_Label';
UPDATE DBField set Field_Order = 28 where Field_Table = 'Plate' and Field_Name = 'Plate_Comments'; 
UPDATE DBField set Field_Order = 29 where Field_Table = 'Plate' and Field_Name = 'FKLast_Prep__ID'; 
UPDATE DBField set Field_Order = 30 where Field_Table = 'Plate' and Field_Name = 'FK_Sample_Type__ID'; 
UPDATE DBField set Field_Order = 31 where Field_Table = 'Plate' and Field_Name = 'FK_Work_Request__ID'; 
UPDATE DBField set Field_Order = 32 where Field_Table = 'Plate' and Field_Name = 'Plate_Class'; 
</FINAL>

 