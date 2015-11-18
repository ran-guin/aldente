## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database



</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER Table Contact ADD Group_Contact ENUM('Yes','No') NOT NULL DEFAULT 'No' ;



CREATE TABLE `Contact_Relation` (
  `Contact_Relation_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FKGroup_Contact__ID` int(11) NOT NULL,
  `FKMember_Contact__ID` int(11) NOT NULL,
  PRIMARY KEY (`Contact_Relation_ID`),
  KEY `group` (`FKGroup_Contact__ID`),
  KEY `memeber` (`FKMember_Contact__ID`)
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
UPDATE DBField set Editable ='No', Field_Description = "This is No for most contacts, but could be set to Yes to set up a group of multiple users - each of whom need to be individually assigned to the group" WHERE Field_Table = 'Contact' and Field_Name IN ('Group_Contact');
update DBField set Field_Options = 'ReadOnly', Prompt = 'Group Submitter' WHERE Field_Name = 'FKAdmin_Contact__ID' AND Field_Table = 'Submission'; 

</FINAL>
