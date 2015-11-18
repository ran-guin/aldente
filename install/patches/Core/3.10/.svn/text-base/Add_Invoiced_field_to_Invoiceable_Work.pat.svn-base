## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
- Add field to allow filtering of invoiced items vs non-invoiced items
-also remove field reference for Invoiceable_Work_ID

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Invoiceable_Work 
ADD COLUMN `Invoiceable_Work_Invoiced` ENUM('Yes','No') NOT NULL DEFAULT 'No';

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

/* Correct current Invoiced status of Invoiceable work items */
UPDATE Invoiceable_Work
SET Invoiceable_Work_Invoiced = 'Yes'
WHERE Invoiceable_Work.FK_Invoice__ID > 0;


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

UPDATE DBField  SET Field_Reference = '' WHERE Field_Table = 'Invoiceable_Work' AND Field_Name = 'Invoiceable_Work_ID';


</FINAL>
