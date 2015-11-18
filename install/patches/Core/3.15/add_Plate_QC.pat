## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

Create tables for tracking multiple QC statuses for a given plate

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

CREATE TABLE `Plate_QC` (
  `Plate_QC_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_Plate__ID` int(11) NOT NULL,
  `FK_QC_Type__ID` int(11) NOT NULL,
  `QC_Status` enum('N/A','Pending','Failed','Re-Test','Passed','Expired') default 'N/A',    
  `QC_DateTime` DATETIME NOT NULL,
  PRIMARY KEY (`Plate_QC_ID`),
  UNIQUE KEY `Plate_QC_Key` (`FK_Plate__ID`,`FK_QC_Type__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `QC_Type` (
  `QC_Type_ID` int(11) NOT NULL AUTO_INCREMENT,
  `QC_Type_Name` varchar(80) default NULL,
  `Inherited` enum('Yes','No') NOT NULL,
  PRIMARY KEY (`QC_Type_ID`),
  UNIQUE KEY `QC_Type_Name` (`QC_Type_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;




</SCHEMA> 

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
insert into QC_Type values (NULL,'Standard', 'Yes');
insert into QC_Type values (NULL,'RD Template QC', 'No');
insert into QC_Type values (NULL,'RD Shearing QC', 'No');
insert into QC_Type values (NULL,'RD Amplicon QC', 'No');

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
