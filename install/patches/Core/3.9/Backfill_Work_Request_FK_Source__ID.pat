## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

- Backfill FK_Source__ID for Work_Request table
- Simple backfill where libraries have one source >90%
- Then backfill using plate and sample

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


/*backfill using library_source*/

UPDATE Work_Request WR 
INNER JOIN (Select FK_Library__Name, FK_Source__ID From Library_Source Group BY FK_Library__Name  HAVING Count(FK_Source__ID) = 1 ) a ON a.FK_Library__Name = WR.FK_Library__Name SET WR.FK_Source__ID = a.FK_Source__ID;


/* backfill extra via using plate and sample, whatever more we can find (same Source_ID)*/
UPDATE Work_Request WR
INNER JOIN (
SELECT DISTINCT Work_Request_ID, Sample.FK_Source__ID
From Work_Request 
INNER JOIN Plate ON Plate.FK_Work_Request__ID = Work_Request_ID 
INNER JOIN Plate_Sample ON Plate_Sample.FKOriginal_Plate__ID = Plate.FKOriginal_Plate__ID
INNER JOIN Sample ON Plate_Sample.FK_Sample__ID = Sample_ID
WHERE Work_Request.FK_Source__ID = 0 
GROUP BY Work_Request_ID 
HAVING Count(DISTINCT Sample.FK_Source__ID)  = 1 ) AS a ON a.Work_Request_ID = WR.Work_Request_ID
SET WR.FK_Source__ID = a.FK_Source__ID
WHERE WR.FK_Source__ID = 0;

/*  same FKOriginal_Source__ID*/
UPDATE Work_Request WR
INNER JOIN (
SELECT DISTINCT Work_Request_ID, Source.FKOriginal_Source__ID
From Work_Request 
INNER JOIN Plate ON Plate.FK_Work_Request__ID = Work_Request_ID 
INNER JOIN Plate_Sample ON Plate_Sample.FKOriginal_Plate__ID = Plate.FKOriginal_Plate__ID
INNER JOIN Sample ON Plate_Sample.FK_Sample__ID = Sample_ID
INNER JOIN Source ON Sample.FK_Source__ID = Source.Source_ID
WHERE Work_Request.FK_Source__ID = 0 
GROUP BY Work_Request_ID 
HAVING Count(DISTINCT Source.FKOriginal_Source__ID)  = 1 ) AS a ON a.Work_Request_ID = WR.Work_Request_ID
SET WR.FK_Source__ID = a.FKOriginal_Source__ID
WHERE WR.FK_Source__ID = 0;


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
