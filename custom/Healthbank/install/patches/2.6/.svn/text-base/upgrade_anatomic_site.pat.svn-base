## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

INSERT INTO Anatomic_Site values ('','Blood','','Blood','Bodily_Fluid','yes');
INSERT INTO Anatomic_Site values ('','Urine','','Urine','Bodily_Fluid','yes');
INSERT INTO Anatomic_Site values ('','Saliva','','Saliva','Bodily_Fluid','yes');

UPDATE Original_Source,Anatomic_Site SET FK_Anatomic_Site__ID=Anatomic_Site_ID,Original_Source_Type='Bodily_Fluid' WHERE Anatomic_Site_Name = 'Blood';

Insert into Patient (Patient_Identifier) SELECT DISTINCT LEFT(External_Identifier,8) FROM Source ORDER by External_Identifier;

UPDATE Original_Source,Patient SET FK_Patient__ID=Patient_ID WHERE Original_Source_Name = Patient_Identifier;

</DATA>

<CODE_BLOCK> 
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below
if (_check_block('NAME_GOES_HERE')) { 
		


}
</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
