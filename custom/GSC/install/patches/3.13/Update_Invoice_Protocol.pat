## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

## Updating the statuses of some protocols on the Invoice_Protocol table.

</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)


</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


UPDATE Invoice_Protocol set Invoice_Protocol_Status = 'Inactive' where Invoice_Protocol_Type = 'Library_Construction';


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
