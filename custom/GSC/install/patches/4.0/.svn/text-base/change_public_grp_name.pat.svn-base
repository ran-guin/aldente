## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Change the group name of 'public' (Grp_ID=23) to 'Internal' - LIMS-10284
Change Department name from Projects_Admin to Projects - LIMS-11562
Changing Grp Name to 'Projects Admin' and deleting the duplicate Projects Admin group - LIMS-11562
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
update Grp set Grp_Name = 'GSC_Internal', FK_Department__ID = 20, Access = 'Lab', Grp_Type = 'Shared' where Grp_ID = 23 and Grp_Name = 'public';
UPDATE Department SET Department_Name = 'Projects' WHERE Department_ID = 10;
INSERT INTO Grp (Grp_Name, FK_Department__ID, Access, Grp_Type, Grp_Status) values ( 'Public', 9, 'Guest', 'Public', 'Inactive' );
UPDATE Grp SET Grp_Name = 'Projects Admin' WHERE Grp_ID = 43;


## Deleting the Dupliate Grp record and anything that is associated with it

DELETE FROM Grp_Relationship WHERE Grp_Relationship_ID IN (65,66);
DELETE FROM GrpEmployee WHERE GrpEmployee_ID IN (1744,1745,1746,1747);
DELETE FROM Grp WHERE Grp_ID = 76;




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
