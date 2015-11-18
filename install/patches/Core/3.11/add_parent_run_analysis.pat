## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

Add FKParent_Run_Analysis__ID to Run Analysis table

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Run_Analysis add FKParent_Run_Analysis__ID int(11) default NULL; 
</SCHEMA> 
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
