## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Update the Priority_Object table 
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
ALTER TABLE Priority_Object MODIFY Priority_Value enum('5 Highest','4 High','3 Medium','2 Low','1 Lowest', '0 Off') NOT NULL DEFAULT '3 Medium';
ALTER TABLE Priority_Object MODIFY Priority_Description text NOT NULL;
ALTER TABLE Priority_Object ADD Priority_Date DATETIME DEFAULT NULL;
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
</CODE_BLOCK>

<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)
#Update DBField set Field_Type = "enum('5 Highest','4 High','3 Medium','2 Low','1 Lowest', '0 Off')", Null_ok = 'NO', Field_Default = '3 Medium' where Field_Table = 'Priority_Object' and Field_Name = 'Priority_Value'; 
#Update DBField set Null_ok = 'NO' where Field_Table = 'Priority_Object' and Field_Name = 'Priority_Description'; 
</FINAL>

 