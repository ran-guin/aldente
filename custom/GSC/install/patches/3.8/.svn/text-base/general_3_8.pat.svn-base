## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

update DBField set Field_Reference = "concat('PLA',FK_Plate__ID,' - ',Prep.Prep_Name)"  WHERE Field_Table = 'Plate_Prep' and Field_Name = 'Plate_Prep_ID';
</FINAL>
