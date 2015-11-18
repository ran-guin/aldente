## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Add Funding_Attribute table

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
CREATE TABLE `Funding_Attribute` (
  `Funding_Attribute_ID` int(11) NOT NULL auto_increment,
  `FK_Funding__ID` int(11) NOT NULL default 0,
  `FK_Attribute__ID` int(11) NOT NULL default 0,
  `Attribute_Value` text NOT NULL default '',
  `FK_Employee__ID` int(11) NULL default NULL,
  `Set_DateTime` datetime NOT NULL default '0000-00-00 00:00:00' ,
  PRIMARY KEY  (`Funding_Attribute_ID`),
  KEY `FK_Funding__ID` (`FK_Funding__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
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


</FINAL>
