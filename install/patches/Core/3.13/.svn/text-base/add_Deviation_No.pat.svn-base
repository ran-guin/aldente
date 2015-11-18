## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

Add Deviation_No to Process_Deviation table. Update the indices.

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Process_Deviation ADD Deviation_No varchar(10) NOT NULL DEFAULT ''; 

ALTER TABLE Process_Deviation ADD UNIQUE INDEX Deviation_No (Deviation_No);
ALTER TABLE Process_Deviation DROP INDEX Process_Deviation_Name;

</SCHEMA> 

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
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
update DBField set Field_Reference = 'Deviation_No' where Field_Name = 'Process_Deviation_ID' and Field_Table = 'Process_Deviation';
update DBField set Field_Options = 'Mandatory', Field_Order = 2 where Field_Name = 'Deviation_No' and Field_Table = 'Process_Deviation';
update DBField set Field_Order = 3 where Field_Name = 'Process_Deviation_Name' and Field_Table = 'Process_Deviation';
update DBField set Field_Order = 4 where Field_Name = 'Process_Deviation_Description' and Field_Table = 'Process_Deviation';

</FINAL>
