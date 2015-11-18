## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

## Adds the column Invoice_Name into the Invoice table and update the field description of Invoice_Name and Invoice_Code.


</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Invoice
ADD COLUMN Invoice_Draft_Name varchar(20);

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

UPDATE DBField SET Field_Description = 'Readable string used as a reference for this invoice' WHERE Field_Table = 'Invoice' AND Field_Name = 'Invoice_Draft_Name';
UPDATE DBField SET Field_Description = 'Structured invoice code - normally formatted based on locally defined standards' WHERE Field_Table = 'Invoice' AND Field_Name = 'Invoice_Code';

</FINAL>
