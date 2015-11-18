## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

CREATE TABLE `RNA_Strategy` (
  `RNA_Strategy_ID` int(11) NOT NULL AUTO_INCREMENT,
  `RNA_Strategy_Name` varchar(40) NOT NULL,
  PRIMARY KEY (`RNA_Strategy_ID`),
  UNIQUE KEY `name` (`RNA_Strategy_Name`)
);


</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
INSERT INTO RNA_Strategy values ('','Strand_specific');
UPDATE Attribute set Attribute_Type = 'FK_RNA_Strategy__ID'  WHERE Attribute_Name = 'RNA_Strategy';

update Attribute, Plate_Attribute set Attribute_Value = 1  WHERE Attribute_Name = 'RNA_Strategy' and FK_Attribute__ID = Attribute_ID;


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
<FINAL> 
UPDATE DBField set Editable = 'no' WHERE Field_Name = 'RNA_Strategy_Name'; 

</FINAL>
