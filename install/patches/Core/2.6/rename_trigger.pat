## Patch file to modify a database

<DESCRIPTION>
Trigger is now a reserved word in MySQL 5.0 and 5.1. We want to rename the table Trigger to DB_Trigger
</DESCRIPTION>
<SCHEMA> 
ALTER TABLE `Trigger` RENAME DB_Trigger;
alter table DB_Trigger change Trigger_ID DB_Trigger_ID int(11);
alter table DB_Trigger change Trigger_Type DB_Trigger_Type enum('SQL','Perl','Form','Method','Shell');
</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

</DATA>

<FINAL> 
update DBField set Field_Table = 'DB_Trigger' where Field_Table = 'Trigger';
update DBField set Field_Name = 'DB_Trigger_ID' where Field_Name = 'Trigger_ID';
update DBField set Field_Name = 'DB_Trigger_Type' where Field_Name = 'Trigger_Type';
update DBTable set DBTable_Name = 'DB_Trigger' and DBTable_Title = 'DB_Trigger' where DBTable_Name = 'Trigger';
</FINAL>
