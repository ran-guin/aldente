## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

CREATE TABLE `Sample_Request` (
  `Sample_Request_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Sample_Count` int(11) NOT NULL,
  `FK_Object_Class__ID` int(11) NOT NULL,
  `FK_Contact__ID` int(11) NOT NULL,
  `FK_Organization__ID` int(11) NOT NULL,
  `FK_Employee__ID` int(11) NOT NULL,
  `Addressee` varchar(255) DEFAULT NULL,
  `Shipping_Address`  text,
  `Shipping_Account_Number` varchar(255) DEFAULT NULL,
  `Request_Status` enum('Initiated','Sent','Completed') NOT NULL,
  `Request_Date` date NOT NULL DEFAULT '0000-00-00',
  `Requested_Completion_Date` date NOT NULL DEFAULT '0000-00-00',
  `Completion_Date` date NOT NULL DEFAULT '0000-00-00',
  `FK_Funding__ID` int(11) DEFAULT NULL,
  `Request_Comments` text,
  PRIMARY KEY (`Sample_Request_ID`),
  KEY `FK_Object_Class__ID` (`FK_Object_Class__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_Organization__ID` (`FK_Organization__ID`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`),
  KEY `Funding` (`FK_Funding__ID`)
);

ALTER TABLE Shipment ADD FK_Sample_Request__ID int(11) DEFAULT NULL ;
ALTER TABLE Shipment ADD `Shipping_Address`  text;
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

update DBField set Field_Options = 'ReadOnly' WHERE Field_Table = 'Shipment' and Field_Name = 'FK_Sample_Request__ID';
update DBField set Field_Options = 'Mandatory' WHERE Field_Table = 'Sample_Request' and Field_Name = 'Sample_Count';



</FINAL>
