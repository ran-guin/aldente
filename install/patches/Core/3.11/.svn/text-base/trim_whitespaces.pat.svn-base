## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

## Adds the column Invoice_Name into the Invoice table and update the field description of Invoice_Name and Invoice_Code.


</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

UPDATE Original_Source SET Original_Source_Name = LTRIM(Original_Source_Name) where Original_Source_Name like ' %';
UPDATE Original_Source SET Original_Source_Name = RTRIM(Original_Source_Name) where Original_Source_Name like '% ';
UPDATE Library SET Library_Name = RTRIM(Library_Name) where Library_Name like '% ';
UPDATE Library SET Library_Name = LTRIM(Library_Name) where Library_Name like ' %';
UPDATE Protocol_Step SET Protocol_Step_Name = RTRIM(Protocol_Step_Name) where Protocol_Step_Name like '% ';
UPDATE Protocol_Step SET Protocol_Step_Name = LTRIM(Protocol_Step_Name) where Protocol_Step_Name like ' %';
UPDATE Prep SET Prep_Name = LTRIM(Prep_Name) where Prep_Name like ' %';
UPDATE Prep SET Prep_Name = RTRIM(Prep_Name) where Prep_Name like '% ';

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
