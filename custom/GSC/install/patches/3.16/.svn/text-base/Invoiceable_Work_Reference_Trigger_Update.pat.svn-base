## Patch file to modify a database

<DESCRIPTION>

## This will update Invoiceable_Work_Reference in DB_Trigger table 

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA> 
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

DELETE FROM DB_Trigger WHERE DB_Trigger_ID = 45 and Table_Name = 'Invoiceable_Work_Reference' and DB_Trigger_Type = 'SQL' and Trigger_On = 'update';

UPDATE DB_Trigger SET value = REPLACE(value,"'Invoiceable_Work'","'Invoiceable_Work_Reference'"), Trigger_On = 'batch_update' WHERE DB_Trigger_ID = 47 and Table_Name = 'Invoiceable_Work_Reference' and DB_Trigger_Type = 'Perl' and Trigger_On = 'update';

</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
