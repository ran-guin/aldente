## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Update attribute types and formats
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
## map the old status to the new status
update Attribute set Attribute_Type = 'Text', Attribute_Format = "^[><]?[\\d,]+(\\.\\d+)?(-[\\d,]+(\\.\\d+)?)?$" where Attribute_Name = 'Tumour_Content_Percentage';
update Attribute set Attribute_Type = 'Text', Attribute_Format = "^[><]?[\\d,]+(\\.\\d+)?(-[\\d,]+(\\.\\d+)?)?$" where Attribute_Name = 'Submitted_Concentration';
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
