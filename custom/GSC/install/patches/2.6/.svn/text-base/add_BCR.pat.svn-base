## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
This patch is for adding the tables which were supposed to be in GSC package

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
CREATE TABLE `BCR_Batch` (
  `BCR_Batch_ID` int(11) NOT NULL auto_increment,
  `FK_BCR_Study__ID` int(11) NOT NULL default '0',
  `FKSupplier_Organization__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`BCR_Batch_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `BCR_Study` (
  `BCR_Study_ID` int(11) NOT NULL auto_increment,
  `BCR_Study_Code` varchar(8) NOT NULL default '',
  `BCR_Study_Name` varchar(255) NOT NULL default '',
  `FK_Genome__ID` int(11) default NULL,
  PRIMARY KEY  (`BCR_Study_ID`),
  UNIQUE KEY `code` (`BCR_Study_Code`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

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
