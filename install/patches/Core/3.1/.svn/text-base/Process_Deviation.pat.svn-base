## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Adding Process Deviation table

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
CREATE TABLE `Process_Deviation` (
  `Process_Deviation_ID` int(11) NOT NULL auto_increment,
  `Process_Deviation_Name` varchar(80) NOT NULL default '',
  `Process_Deviation_Description` text NULL default NULL,
  PRIMARY KEY  (`Process_Deviation_ID`),
  UNIQUE KEY `Process_Deviation_Name` (`Process_Deviation_Name`)
);
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

update DBField set Field_Reference = 'Process_Deviation_Name' where Field_Name = 'Process_Deviation_ID';
update DBField set Field_Options = 'Mandatory' where Field_Name = 'Process_Deviation_Name';

</FINAL>
