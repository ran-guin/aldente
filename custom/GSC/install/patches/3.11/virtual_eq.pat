## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)


</SCHEMA> 
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
UPDATE Equipment_Category set Sub_Category = 'Storage_Site' WHERE Category= 'Storage' and Sub_Category = 'Virtual';
 UPDATE Stock_Catalog set Stock_Catalog_Name = 'Storage Area'  WHERE Stock_Catalog_Name like 'Virtual Storage';

</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
