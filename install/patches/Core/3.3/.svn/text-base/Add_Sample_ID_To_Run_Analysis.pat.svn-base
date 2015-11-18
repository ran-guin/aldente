## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Add FK_Sample__ID to Run_Analysis and Run_Analysis_Type to Run_Analysis

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
alter table Run_Analysis add FK_Sample__ID int(11) NOT NULL default 0;
alter table Run_Analysis add column Run_Analysis_Type enum('Primary','Secondary','Tertiary') NULL default 'Secondary';
</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
update Run_Analysis,SOLID_Run_Analysis set Run_Analysis.FK_Sample__ID = SOLID_Run_Analysis.FK_Sample__ID where FK_Run_Analysis__ID = Run_Analysis_ID;
update Run_Analysis,Solexa_Run_Analysis set Run_Analysis.FK_Sample__ID = Solexa_Run_Analysis.FK_Sample__ID where FK_Run_Analysis__ID = Run_Analysis_ID;
update Run_Analysis,Run,Plate,Plate_Sample set Run_Analysis.FK_Sample__ID = Plate_Sample.FK_Sample__ID where Run_Analysis.FK_Sample__ID = 0 AND FK_Run__ID = Run_ID and FK_Plate__ID = Plate_ID and Plate.FKOriginal_Plate__ID = Plate_Sample.FKOriginal_Plate__ID;

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
