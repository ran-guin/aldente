## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
factory_barcode_3_17.pat

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Lab_Protocol ADD Lab_Protocol_Modified_Date date;
ALTER TABLE Lab_Protocol ADD Lab_Protocol_Created_Date date;

</SCHEMA>

<DATA> ## 




</DATA>


<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
