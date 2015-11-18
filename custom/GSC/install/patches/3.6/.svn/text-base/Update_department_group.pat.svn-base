## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


Update Department set Department_Name = 'Lib_Construction' where Department_Name = 'Gene Expression';
Update Department set Department_Name = 'Cap_Seq' where Department_Name = 'Sequencing'; 
Insert INTO Department (Department_Name, Department_Status) Values ('UHTS', 'Inactive');

Update Grp set Grp_Name = replace(Grp_Name,'Gene Expression','Lib_Construction');
Update Grp set Grp_Name = replace(Grp_Name,'FG','Lib_Construction');
Update Grp set Grp_Name = replace(Grp_Name,'Sequencing','Cap_Seq');

Insert INTO Grp (Grp_Name, FK_Department__ID, Access, Grp_Type, Grp_Status) select 'UHTS', Department_ID,'Guest','Lab','Inactive' from Department where Department_Name = 'UHTS';
Insert INTO Grp (Grp_Name, FK_Department__ID, Access, Grp_Type, Grp_Status) select 'UHTS Admin', Department_ID,'Admin','Lab Admin','Inactive' from Department where Department_Name = 'UHTS';
Insert INTO Grp (Grp_Name, FK_Department__ID, Access, Grp_Type, Grp_Status) select 'UHTS Project Admin', Department_ID,'Report','Project Admin','Inactive' from Department where Department_Name = 'UHTS';
Insert INTO Grp (Grp_Name, FK_Department__ID, Access, Grp_Type, Grp_Status) select 'UHTS Production', Department_ID,'Lab','Production','Inactive' from Department where Department_Name = 'UHTS';
Insert INTO Grp (Grp_Name, FK_Department__ID, Access, Grp_Type, Grp_Status) select 'UHTS TechD', Department_ID,'Lab','Production','Inactive' from Department where Department_Name = 'UHTS';
Insert INTO Grp (Grp_Name, FK_Department__ID, Access, Grp_Type, Grp_Status) select 'UHTS TechD Admin', Department_ID,'Lab','Production','Inactive' from Department where Department_Name = 'UHTS';


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
