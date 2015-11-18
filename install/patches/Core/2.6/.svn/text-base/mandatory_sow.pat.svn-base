## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

alter table Submission add Reference_Code varchar(40);


</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

update DBField set Field_Options = 'Mandatory',Prompt='SOW code',Field_Format='\\d\\d\\d\\d',Field_Description = 'Required reference code - If you do not know what this is please contact us to receive a valid SOW code'  where Field_Name like 'Reference_Code';

</FINAL>
