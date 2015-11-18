## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

CREATE TABLE `Tissue_Source_Site` (
  `Tissue_Source_Site_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Tissue_Source_Site_Code` varchar(8) NOT NULL DEFAULT '',
  `FKSource_Organization__ID`  int(11) DEFAULT NULL,
  `FKSupplier_Organization__ID` int(11) DEFAULT NULL,
  `FK_BCR_Study__ID` int(11) DEFAULT NULL,
  PRIMARY KEY (`Tissue_Source_Site_ID`),
  UNIQUE KEY `code` (`Tissue_Source_Site_Code`),
  KEY `Supplier` (`FKSupplier_Organization__ID`),
  KEY `Source` (`FKSource_Organization__ID`),
  KEY `Study` (`FK_BCR_Study__ID`)
);

</SCHEMA> 
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)
## UPDATE DBField set Field_Reference = 'Study_Name' WHERE Field_Name = 'BCR_Study_ID'\G


</FINAL>
