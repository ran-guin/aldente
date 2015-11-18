## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Add table to give tags certain attributes and group them together.  This can be used to pull out groups of info in views etc.

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

CREATE TABLE `Attribute_Tag` (
  `Attribute_Tag_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Attribute_Tag_Name` varchar(40) DEFAULT NULL,
  `Attribute_Tag_Description` text,
  PRIMARY KEY (`Attribute_Tag_ID`),
  UNIQUE KEY `Attribute_Tag` (`Attribute_Tag_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

ALTER TABLE Attribute add FK_Attribute_Tag__ID int(11) default NULL;
ALTER TABLE Attribute add index Attribute_Tag (FK_Attribute_Tag__ID);

</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)



</DATA>


<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
