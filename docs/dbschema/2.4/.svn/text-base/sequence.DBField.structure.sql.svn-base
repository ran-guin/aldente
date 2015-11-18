-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `DBField`
--

DROP TABLE IF EXISTS `DBField`;
CREATE TABLE `DBField` (
  `DBField_ID` int(11) NOT NULL auto_increment,
  `Field_Description` text NOT NULL,
  `Field_Table` text NOT NULL,
  `Prompt` varchar(255) NOT NULL default '',
  `Field_Alias` varchar(255) NOT NULL default '',
  `Field_Options` set('Hidden','Mandatory','Primary','Unique','NewLink','ViewLink','ListLink','Searchable') default NULL,
  `Field_Reference` varchar(255) NOT NULL default '',
  `Field_Order` int(11) NOT NULL default '0',
  `Field_Name` varchar(255) NOT NULL default '',
  `Field_Type` varchar(255) NOT NULL default '',
  `Field_Index` varchar(255) NOT NULL default '',
  `NULL_ok` enum('NO','YES') NOT NULL default 'YES',
  `Field_Default` varchar(255) NOT NULL default '',
  `Field_Size` tinyint(4) default '20',
  `Field_Format` varchar(80) default NULL,
  `FK_DBTable__ID` int(11) default NULL,
  `Foreign_Key` varchar(255) default NULL,
  `DBField_Notes` text,
  `Editable` enum('yes','no') default 'yes',
  `Tracked` enum('yes','no') default 'no',
  PRIMARY KEY  (`DBField_ID`),
  UNIQUE KEY `tblfld` (`FK_DBTable__ID`,`Field_Name`),
  UNIQUE KEY `field_name` (`Field_Name`,`FK_DBTable__ID`),
  KEY `fld` (`Field_Name`)
) TYPE=InnoDB;

