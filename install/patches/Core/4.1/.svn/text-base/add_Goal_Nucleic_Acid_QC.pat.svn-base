## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Adding new goal 'Nucleic Acid QC' and expanding Experiment_Type enum to include option 'Other'

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
ALTER TABLE RNA_DNA_Collection MODIFY Experiment_Type enum('','SAGE','LongSAGE','PCR-SAGE','PCR-LongSAGE','SAGELite-SAGE','SAGELite-LongSAGE','Solexa','Microarray','SOLiD', 'Other');

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
INSERT INTO Goal(Goal_Name, Goal_Description, Goal_Tables, Goal_Count, Goal_Condition, Goal_Type, Goal_Scope) VALUES ('Nucleic Acid QC', 'Nucleic Acid QC', 'Plate, Plate_Prep, Prep', 1, "Plate.FK_Library__Name = '<LIBRARY>' AND Plate_Prep.FK_Plate__ID = Plate.Plate_ID AND Prep.Prep_ID = Plate_Prep.FK_Prep__ID AND Prep.FK_Lab_Protocol__ID = 745", 'Lab Work', 'Specific');

</DATA>
<CODE_BLOCK> 
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below


</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
