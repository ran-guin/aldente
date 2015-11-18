-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Plate_Format`
--

DROP TABLE IF EXISTS `Plate_Format`;
CREATE TABLE `Plate_Format` (
  `Plate_Format_ID` int(11) NOT NULL auto_increment,
  `Plate_Format_Type` char(40) default NULL,
  `Plate_Format_Size` enum('1-well','96-well','384-well','1.5 ml','50 ml','15 ml','5 ml','2 ml','0.5 ml','0.2 ml') default NULL,
  `Plate_Format_Status` enum('Active','Inactive') default NULL,
  `FK_Barcode_Label__ID` int(11) default NULL,
  `Max_Row` char(2) default NULL,
  `Max_Col` tinyint(4) default NULL,
  `Plate_Format_Style` enum('Plate','Tube') default NULL,
  `Format_Size` char(4) default NULL,
  `Format_Size_Units` enum('wells','ml') default NULL,
  `Wells` smallint(6) NOT NULL default '1',
  PRIMARY KEY  (`Plate_Format_ID`),
  UNIQUE KEY `name` (`Plate_Format_Type`,`Plate_Format_Size`),
  KEY `FK_Barcode_Label__ID` (`FK_Barcode_Label__ID`)
) TYPE=InnoDB;

