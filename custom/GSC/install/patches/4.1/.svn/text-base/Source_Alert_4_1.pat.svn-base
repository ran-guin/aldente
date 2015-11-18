## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Source_Alert MODIFY Alert_Comments text NOT NULL;
ALTER TABLE Alert_Reason MODIFY Alert_Reason varchar(80) NOT NULL;

</SCHEMA> 
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

## MANDATORY type source reason

</FINAL>

 
