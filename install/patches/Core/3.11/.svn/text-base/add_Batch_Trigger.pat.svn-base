## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Add 'batch_inset', 'batch_update', 'batch_delete' to the enum values of Trigger_On. This allows for implementing batch triggers.
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
ALTER TABLE DB_Trigger MODIFY Trigger_On enum('update','insert','delete','batch_update','batch_insert','batch_delete') DEFAULT NULL;
</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
INSERT INTO DB_Trigger VALUES ('', 'Plate', 'Perl', 'require alDente::Container; my $ok = alDente::Container::new_container_batch_trigger(-dbc=>$self,-id=>$id)', 'batch_insert', 'Active', NULL, 'Yes', NULL );
update DB_Trigger set Trigger_On = 'batch_insert', Value = 'require alDente::Rack; alDente::Rack::rack_change_history_batch_trigger(-dbc=>$self,-change_history_id=>$id); ' where Table_Name = 'Change_History';
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
