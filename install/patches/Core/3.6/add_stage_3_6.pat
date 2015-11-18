## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Creating TechD Access


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
ALTER TABLE Original_Source MODIFY Pathology_Stage enum('0','I','I-A','I-B','I-C','II','II-A','II-B','II-C','III','III-A','III-B','III-C','IV','>=pT2') DEFAULT NULL;

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

UPDATE Source SET FKOriginal_Source__ID=Source_ID WHERE FKOriginal_Source__ID IS NULL;
UPDATE Source SET FKOriginal_Source__ID=Source_ID WHERE FKOriginal_Source__ID=0;

</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
