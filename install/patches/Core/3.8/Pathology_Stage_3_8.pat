## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Original_Source MODIFY Pathology_Stage enum('0','I','I-A','I-B','I-C','II','II-A','II-B','II-C','III','III-A','III-B','III-C','III-AE', 'IV','IV-A','IV-B','>=pT2') ;

ALTER TABLE Original_Source MODIFY Pathology_Grade set('G1','G2','G3','G4','Low','High');     


</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
