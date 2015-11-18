## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Drop 'TechD' from Grp.Access enum list 
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
ALTER TABLE Grp MODIFY Access enum('Lab','Admin','Guest','Report','Bioinformatics');
</SCHEMA> 

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
update Grp set Access = 'Lab' where Grp_Name in ( 'Cap_Seq TechD', 'Mapping TechD', 'MGC_TechD', 'Lib_Construction TechD', 'UHTS TechD' );
# fix data errors
update Grp set Access = 'Admin' where Grp_Name = 'UHTS TechD Admin';
update Grp set Grp_Type = 'TechD' where Grp_Name = 'UHTS TechD';
update Grp set Grp_Type = 'Lab Admin' where Grp_Name = 'UHTS TechD Admin';
update Grp_Relationship set FKBase_Grp__ID = 8 where FKDerived_Grp__ID = 41;
update Grp_Relationship set FKBase_Grp__ID = 58 where FKDerived_Grp__ID = 62;
insert into Grp_Relationship values ('', 62, 63 );
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

 