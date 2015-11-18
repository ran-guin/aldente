## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database



</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

CREATE TABLE `Package_Condition` (
  `Package_Condition_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Package_Condition_Name` varchar(40) NOT NULL,
  PRIMARY KEY (`Package_Condition_ID`),
  UNIQUE KEY `Package_Condition_Name` (`Package_Condition_Name`)
);
ALTER TABLE Shipment ADD FK_Package_Condition__ID int(11);
INSERT INTO Package_Condition (SELECT  Distinct '' ,  Package_Conditions from  Shipment WHERE Package_Conditions> 0);
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ( 'frozen - wet ice');
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ( 'refrigerated - cold packs-frozen');
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ( 'refrigerated - cold packs-thawed cold');
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ( 'refrigerated - cold packs-thawed warm');
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ( 'multiple conditions');

UPDATE  Shipment, Package_Condition set FK_Package_Condition__ID = Package_Condition_ID   WHERE Package_Conditions = Package_Condition_Name ;


ALTER TABLE Shipment DROP Package_Conditions;




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
UPDATE DBField set Field_Reference = 'Package_Condition_Name'  WHERE Field_Table = 'Package_Condition' and Field_Name = 'Package_Condition_ID'; 
UPDATE DBField set Field_Order = 10   WHERE Field_Table = 'Shipment' and Field_Name = 'FK_Package_Condition__ID';
UPDATE DBField set Prompt = 'Package_Conditions'   WHERE Field_Table = 'Shipment' and Field_Name = 'FK_Package_Condition__ID';


</FINAL>
