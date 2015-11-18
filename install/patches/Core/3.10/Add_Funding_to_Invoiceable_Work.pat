## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
- add FKApplicable_Funding__ID field to invoiceable_Work table, to tightly intergrate work with SOW
- backfill simple cases of work with funding_id

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
ALTER TABLE Invoiceable_Work
ADD COLUMN `FKApplicable_Funding__ID` int(11) NULL AFTER FK_Tray__ID,
ADD KEY (`FKApplicable_Funding__ID`);

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

UPDATE Invoiceable_Work
INNER JOIN (SELECT Invoiceable_Work_ID, Funding_ID FROM Invoiceable_Work INNER JOIN Plate ON FK_Plate__ID = Plate_ID INNER JOIN Library ON Plate.FK_Library__Name = Library_Name INNER JOIN Work_Request ON Work_Request.FK_Library__Name = Library_Name INNER JOIN Funding ON FK_Funding__ID = Funding_ID GROUP BY Invoiceable_Work_ID HAVING Count(DISTINCT Funding_ID) = 1) AS WF ON WF.Invoiceable_Work_ID = Invoiceable_Work.Invoiceable_Work_ID
SET Invoiceable_Work.FKApplicable_Funding__ID = WF.Funding_ID
WHERE Invoiceable_Work.FKApplicable_Funding__ID IS NULL OR Invoiceable_Work.FKApplicable_Funding__ID = 0;

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
