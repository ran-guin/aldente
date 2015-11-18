## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
update field "Organization_Type" in table Organization to include "Data Repository" as the allowable enum set value
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
ALTER TABLE Organization MODIFY COLUMN Organization_Type set('Manufacturer','Collaborator','Vendor','Funding Source','Local','Sample Supplier','Data Repository') default NULL;
</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
</DATA>

<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)
</FINAL>