## Patch file to modify a database

<DESCRIPTION>
Service centre table for tracking service centres within the orgnization
</DESCRIPTION>
<SCHEMA> 
CREATE TABLE `Service_Centre` (
  `Service_Centre_ID` int(11) NOT NULL auto_increment,
  `Service_Centre_Name` varchar(255) default NULL,
  `Service_Centre_Address` varchar(255) default NULL,
  `Service_Centre_Code` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Service_Centre_ID`),
  UNIQUE KEY `code` (`Service_Centre_Code`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
INSERT INTO Attribute SELECT '','Patient_Service_Centre','','FK_Service_Centre__ID', Grp_ID, 'Yes','Source' FROM Grp where Grp_Name = 'Lab';
</DATA>

<FINAL>
UPDATE DBField set Field_Reference = "Concat(Service_Centre_Name, ' ', Service_Centre_Code, ' - ',Service_Centre_Address)" WHERE Field_Name = 'Service_Centre_ID';
UPDATE DBField set Field_Format = "^.{0,255}" WHERE Field_Name = 'Service_Centre_Name';
UPDATE DBField set Field_Format = "^.{0,255}" WHERE Field_Name = 'Service_Centre_Address';
</FINAL>