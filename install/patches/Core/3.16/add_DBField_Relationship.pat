## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

Add DBField_Relationship table to capture the relationship among fields


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

CREATE TABLE `DBField_Relationship` (
  `DBField_Relationship_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FKParent_DBField__ID` int(11) NOT NULL,
  `FKChild_DBField__ID` int NOT NULL,
  PRIMARY KEY (`DBField_Relationship_ID`),
  KEY `FKParent_DBField__ID` (`FKParent_DBField__ID`),
  KEY `FKChild_DBField__ID` (`FKChild_DBField__ID`)
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
