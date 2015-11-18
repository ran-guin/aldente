## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
- Backfill invoiceable_work_comments from billable change history
- Set indirectly invoiceable_work comments to 'See parent work comment'
- update billable status from run

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)


</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
 
 
 /*Update billable status*/
UPDATE Invoiceable_Work 
INNER JOIN Invoiceable_Run ON FK_Invoiceable_Work__ID = Invoiceable_Work_ID 
INNER JOIN Run on Run_ID = FK_Run__ID 
SET Invoiceable_Work.Billable  = Run.Billable;

/*Copy billable comments from change history to Invoiceable_Comments*/
UPDATE Invoiceable_Work 
INNER JOIN Invoiceable_Run ON Invoiceable_Work_ID = FK_Invoiceable_Work__ID 
INNER JOIN (
	Select Run_ID, GROUP_CONCAT('[', Modified_Date, ' | Billable(', New_Value , ')]-', Comment ORDER BY Modified_Date SEPARATOR '\n') AS Comments 
	FROM Change_History 
	INNER JOIN Run ON Run_ID = Record_ID 
	WHERE Run.Run_DateTime > '2011-01-01' AND FK_DBField__ID = 2845 AND Comment NOT LIKE '' 
	GROUP BY Run_ID) a ON  FK_Run__ID = a.Run_ID
	
SET Invoiceable_Work_Comments = a.Comments
WHERE Invoiceable_Work.Indexed = 0 OR Invoiceable_Work.Indexed IS NULL;

UPDATE Invoiceable_Work
SET Invoiceable_Work_Comments =  'See parent work comment'
WHERE Invoiceable_Work.Indexed >0;

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

UPDATE DBField SET Field_Reference = 'Indication by the lab if the work record is billlable' WHERE Field_Table = 'Invoiceable_Work' AND Field_Name = 'Billable';
UPDATE DBField SET Field_Reference = 'Indication by the lab if the run is billlable' WHERE Field_Table = 'Run' AND Field_Name = 'Billable';


</FINAL>
