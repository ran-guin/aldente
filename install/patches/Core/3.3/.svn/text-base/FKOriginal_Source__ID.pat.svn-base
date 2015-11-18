## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Add FKOriginal_Source__ID to Source table

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Source add FKOriginal_Source__ID int(11);
ALTER TABLE Source MODIFY Source_Status enum('Active','Reserved','On Hold','Inactive','Thrown Out','Exported','Failed','Cancelled','Archived');

## Start off with just originals  ##
UPDATE Source SET Source.FKOriginal_Source__ID=Source_ID WHERE FKParent_Source__ID IS NULL;
## Default original to parent if it exists
 UPDATE  Source SET FKOriginal_Source__ID = FKParent_Source__ID where FKParent_Source__ID> 0;

## create temporary list of parent sources ##
CREATE TABLE temp_Src SELECT Source_ID as Src, FKParent_Source__ID as Parent from Source where FKParent_Source__ID > 0;

CREATE INDEX srcid ON temp_Src (Src);

## correct Original Source where another generation is present ##
UPDATE Source, temp_Src SET FKOriginal_Source__ID=temp_Src.Parent where FKOriginal_Source__ID=temp_Src.Src;

## repeat (iteratively fixes 897, 118, 39, 2, 0 records ...)
UPDATE Source, temp_Src SET FKOriginal_Source__ID=temp_Src.Parent where FKOriginal_Source__ID=temp_Src.Src;
UPDATE Source, temp_Src SET FKOriginal_Source__ID=temp_Src.Parent where FKOriginal_Source__ID=temp_Src.Src;
UPDATE Source, temp_Src SET FKOriginal_Source__ID=temp_Src.Parent where FKOriginal_Source__ID=temp_Src.Src;
UPDATE Source, temp_Src SET FKOriginal_Source__ID=temp_Src.Parent where FKOriginal_Source__ID=temp_Src.Src;
UPDATE Source, temp_Src SET FKOriginal_Source__ID=temp_Src.Parent where FKOriginal_Source__ID=temp_Src.Src;


DROP Table temp_Src;

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


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
