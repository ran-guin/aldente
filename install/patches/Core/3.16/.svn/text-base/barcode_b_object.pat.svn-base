## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

Add DBField_Relationship table to capture the relationship among fields


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

CREATE TABLE `Factory_Barcode` (
  `Factory_Barcode_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Barcode_Value` varchar(40) NOT NULL,
  `Object_ID` varchar(40) NOT NULL,
  `FK_Object_Class__ID` int(11) NOT NULL,
  PRIMARY KEY (`Factory_Barcode_ID`),
  KEY `Object_ID` (`Object_ID`),
  KEY `FK_Object_Class__ID` (`FK_Object_Class__ID`)
);
CREATE UNIQUE INDEX record on Factory_Barcode (Object_ID,FK_Object_Class__ID);
CREATE UNIQUE INDEX unique_Barcode_Value on Factory_Barcode (Barcode_Value,FK_Object_Class__ID);


</SCHEMA> 

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
INSERT INTO Barcode_Label VALUES ('','src_simple_tube','0.6','1.7',25,25,15,4,'Simple Source Label','source',4,'Active');

DELETE Source_Attribute  from Source_Attribute, Attribute WHERE Attribute_Name = 'Biospecimen_Barcode' and FK_Attribute__ID= Attribute_ID AND Attribute_Value like '%+%' ;
DELETE Source_Attribute  from Source, Source_Attribute, Attribute WHERE Attribute_Name = 'Biospecimen_Barcode' and FK_Attribute__ID= Attribute_ID AND FK_Source__ID= Source_ID  AND (Source_Number LIKE '%.%' OR Source_Number LIKE '%p%');
DELETE Source_Attribute  from Source_Attribute, Attribute WHERE Attribute_Name = 'Biospecimen_Barcode' and FK_Attribute__ID= Attribute_ID and Attribute_Value like 'NA';

INSERT INTO Factory_Barcode (select DISTINCT '', Attribute_Value, FK_Source__ID, Object_Class_ID  from Source_Attribute, Attribute, Object_Class WHERE Attribute_Name = 'Biospecimen_Barcode' and FK_Attribute__ID= Attribute_ID AND Object_Class='Source');
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
