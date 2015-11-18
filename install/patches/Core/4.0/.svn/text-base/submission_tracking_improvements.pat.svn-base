## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
LIMS-11290

Add External Analysis Field_Type and External_Analysis_Field_Value to the Analysis_File table
to allow for external key value pairs for ids.. ie a bioapps repositioned file that has been submitted

Assuming External_Analysis_Field_value = INT

Add completed date to Analysis_Submission;

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Analysis_File add External_Analysis_Field_Value int(11) default NULL;
ALTER TABLE Analysis_File add External_Analysis_Field_Type varchar(40) default NULL;

ALTER TABLE Analysis_Submission add Analysis_Submission_Finished datetime default NULL;
ALTER TABLE Analysis_Submission add Analysis_Submission_Started datetime default NULL;

</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


</DATA>

<CODE_BLOCK> 
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
