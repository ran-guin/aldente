## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)



</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
UPDATE DBField set Field_Default = '<USER>' WHERE Field_Name LIKE 'FK%EMployee%ID'  AND (Field_Table IN ('Lab_Protocol','Plate', 'Pool','Protocol_Step','Stock','Primer_Order','Prep','Library','Original_Source','Change_History','GelRun', 'Defined_Plate_Set','RunBatch','Work_Request')OR Field_Table LIKE '%_Attribute' );

</DATA>


<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
