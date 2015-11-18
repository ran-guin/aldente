## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Data fix for dropping Plate_Format_Size 

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


update Plate_Format set Capacity_Units = 'well' where Plate_Format_ID between 1 and 18 or Plate_Format_ID IN (37, 49, 51, 56, 60, 61, 62);
update Plate_Format set Capacity_Units = 'ml', Well_Capacity_mL = 1.5 where Plate_Format_ID = 28;
update Plate_Format set Wells = 96 where Plate_Format_ID IN (17,60);
update Plate_Format set Well_Capacity_mL = NULL, Capacity_Units = NULL where Plate_Format_ID = 63;


update Protocol_Step set Protocol_Step_Name = CASE WHEN Protocol_Step_Name like '%.%' THEN Replace(Protocol_Step_Name,' ml','0 mL') ELSE Replace(Protocol_Step_Name,' ml','.00 mL') END where Protocol_Step_Name like '%ml%';

update Prep set Prep_Name = CASE WHEN Prep_Name like '%.%' THEN Replace(Prep_Name,' ml','0 mL') ELSE Replace(Prep_Name,' ml','.00 mL') END where Prep_Name like '% ml%';


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
