-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Barcode_Label`
--

DROP TABLE IF EXISTS `Barcode_Label`;
CREATE TABLE `Barcode_Label` (
  `Barcode_Label_ID` int(11) NOT NULL auto_increment,
  `Barcode_Label_Name` char(40) default NULL,
  `Label_Height` float default NULL,
  `Label_Width` float default NULL,
  `Zero_X` int(11) default NULL,
  `Zero_Y` int(11) default NULL,
  `Top` int(11) default NULL,
  `FK_Setting__ID` int(11) NOT NULL default '0',
  `Label_Descriptive_Name` char(40) NOT NULL default '',
  `Barcode_Label_Type` enum('plate','mulplate','solution','equipment','source','employee') default NULL,
  PRIMARY KEY  (`Barcode_Label_ID`),
  KEY `setting` (`FK_Setting__ID`)
) TYPE=InnoDB;

