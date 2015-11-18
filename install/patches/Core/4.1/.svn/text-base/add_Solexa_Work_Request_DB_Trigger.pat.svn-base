## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Adding DB Trigger to set work request for a run upon insert into Run table
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
INSERT INTO DB_Trigger(Table_Name, DB_Trigger_Type, Value, Trigger_On, Status, Trigger_Description, Fatal) VALUES ('Run', 'Perl', 'require alDente::Work_Request; my $ok = alDente::Work_Request->set_solexa_work_request_trigger( -dbc => $dbc, -run => <ID> );', 'insert', 'Active', 'Set work request for plate run was done on', 'No');
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

 
