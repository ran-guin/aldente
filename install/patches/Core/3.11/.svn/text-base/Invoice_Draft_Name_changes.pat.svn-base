## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

Creating NULL values as Invoice_Code. This is for when you do not have the Invoice code to somethings
Making all blank values as NULL in Invoice_Code. There should only be 1.
Making Invoice_Draft_Name as a not null. Also increases the Invoice_Draft_Name max size to  255 characters.
Adding Uniqueness constraint.
Making Invoice_Draft_Name display if Invoice_Code is NULL


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Invoice MODIFY Invoice_Code varchar(20) NULL;
ALTER TABLE Invoice MODIFY Invoice_Draft_Name varchar(255) NOT NULL;
ALTER TABLE Invoice ADD UNIQUE (Invoice_Draft_Name);



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

UPDATE DBField SET Field_Reference = 'CASE WHEN Invoice_Code IS NOT NULL THEN Invoice_Code ELSE CONCAT(Invoice_Draft_Name, \' - DRAFT\') END' WHERE Field_Table = 'Invoice' and Field_Name = 'Invoice_ID';

</FINAL>
