## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Make Source_Created mandatory and Received_Date not mandatory.
Received_Date will be sync'd with Shipment_Received

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

ALTER TABLE Source CHANGE Received_Date Received_Date datetime NOT NULL default '0000-00-00 00:00:00';

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
UPDATE DBField set Field_Options = 'Mandatory' where Field_Table = 'Source' and Field_Name = 'Source_Created';
UPDATE DBField set Field_Default = '<TODAY>' where Field_Table = 'Source' and Field_Name = 'Source_Created';
UPDATE DBField set Field_Options = '' where Field_Table = 'Source' and Field_Name = 'Received_Date';
</FINAL>
