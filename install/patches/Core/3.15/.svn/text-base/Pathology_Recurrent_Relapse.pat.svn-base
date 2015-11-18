## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Correct a spelling error in the enum type for the column Pathology_Occurrence of Original_Source table
</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Original_Source MODIFY Pathology_Occurrence enum('Primary','Reccurent-Relapse','Recurrent-Relapse','Metastatic','Remission','Undetermined','Unspecified') NOT NULL DEFAULT 'Unspecified'; 
UPDATE Original_Source set Pathology_Occurrence = 'Recurrent-Relapse' WHERE Pathology_Occurrence = 'Reccurent-Relapse';
ALTER TABLE Original_Source MODIFY Pathology_Occurrence enum('Primary','Recurrent-Relapse','Metastatic','Remission','Undetermined','Unspecified') NOT NULL DEFAULT 'Unspecified'; 

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

</DATA>
<CODE_BLOCK> 
if (_check_block('NAME_GOES_HERE')) { 
		


}
</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

</FINAL>
