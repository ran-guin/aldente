## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

Allow setting of Process Deviation for plates, libraries, samples, runs


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

CREATE TABLE `Process_Deviation_Object` (
  `Process_Deviation_Object_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_Process_Deviation__ID` int(11) NOT NULL,
  `FK_Object_Class__ID` int NOT NULL,
  `Object_ID` varchar(40) NOT NULL,
  `FK_Employee__ID` int(11) DEFAULT NULL,
  `Set_DateTime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`Process_Deviation_Object_ID`),
  UNIQUE KEY `Object_Key` (`FK_Process_Deviation__ID`,`FK_Object_Class__ID`,`Object_ID`),
  KEY `FK_Process_Deviation__ID` (`FK_Process_Deviation__ID`),
  KEY `FK_Object_Class__ID` (`FK_Object_Class__ID`),
  KEY `Object_ID` (`Object_ID`),  
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `Set_DateTime` (`Set_DateTime`)    
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
