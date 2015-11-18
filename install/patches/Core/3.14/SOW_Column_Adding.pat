## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

## Adding a new column to the Work_Request table which will specify what the scope of the work request is.

## Modifies the table so that we are able to have NULL values for Library_Name and Source_ID

## Also drop the Work_Request_Type column

## Adds a field description to the new "Scope" column

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Work_Request ADD COLUMN Scope ENUM('SOW', 'Source', 'Library');
ALTER TABLE Work_Request MODIFY FK_Library__Name varchar(40);
ALTER TABLE Work_Request MODIFY FK_Source__ID int(11);

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

UPDATE DBField SET Field_Options = 'Obsolete' WHERE Field_Name = 'Work_Request_Type' AND Field_Table = 'Work_Request';
UPDATE DBField SET Field_Description = 'An internal tracking field used to specify what level of work request this is.' WHERE Field_Name = 'Scope' AND Field_Table = 'Work_Request';

</FINAL>
