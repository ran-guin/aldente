## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Normalize status options for Lab_Protocol and Standard_Solution. LIMS-8612
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
ALTER TABLE Lab_Protocol MODIFY Lab_Protocol_Status enum('Active','Archived','Under Development') DEFAULT NULL;
ALTER TABLE Standard_Solution MODIFY Standard_Solution_Status enum('Active','Archived','Under Development') DEFAULT NULL;
</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
## map the old status to the new status
update Lab_Protocol set Lab_Protocol_Status = 'Archived' where Lab_Protocol_Status = 0;
update Lab_Protocol set Lab_Protocol_Status = 'Archived' where Lab_Protocol_Status is NULL;
update Standard_Solution set Standard_Solution_Status = 'Under Development' where Standard_Solution_ID in ( 189,204,248,249,255,261,262,291,292,294 );
update Standard_Solution set Standard_Solution_Status = 'Archived' where Standard_Solution_Status = 0;
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
