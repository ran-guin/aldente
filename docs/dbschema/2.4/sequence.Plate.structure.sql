-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Plate`
--

DROP TABLE IF EXISTS `Plate`;
CREATE TABLE `Plate` (
  `Plate_ID` int(11) NOT NULL auto_increment,
  `Plate_Size` enum('1-well','16-well','32-well','48-well','64-well','80-well','96-well','384-well','1.5 ml','50 ml','15 ml','5 ml','2 ml','0.5 ml','0.2 ml') default NULL,
  `Plate_Created` datetime default '0000-00-00 00:00:00',
  `FK_Library__Name` varchar(40) default NULL,
  `FK_Rack__ID` int(11) default NULL,
  `Plate_Number` int(4) NOT NULL default '0',
  `FK_Employee__ID` int(11) default NULL,
  `FKParent_Plate__ID` int(11) default NULL,
  `Plate_Comments` text NOT NULL,
  `Plate_Status` enum('Active','Pre-Printed','Reserved','Temporary','Failed','Thrown Out','Exported') default 'Active',
  `Plate_Test_Status` enum('Test','Production') default 'Production',
  `FK_Plate_Format__ID` int(11) default NULL,
  `Plate_Application` enum('Sequencing','PCR','Mapping','Gene Expression') default NULL,
  `Plate_Type` enum('Library_Plate','Tube') default NULL,
  `FKOriginal_Plate__ID` int(10) unsigned default NULL,
  `Current_Volume` float default NULL,
  `Current_Volume_Units` enum('l','ml','ul','nl','g','mg','ug','ng') NOT NULL default 'ul',
  `Plate_Content_Type` enum('DNA','RNA','Protein','Mixed','Amplicon','Clone') default NULL,
  `Parent_Quadrant` enum('','a','b','c','d') NOT NULL default '',
  `Plate_Parent_Well` char(3) NOT NULL default '',
  `QC_Status` enum('N/A','Pending','Failed','Re-Test','Passed') default 'N/A',
  PRIMARY KEY  (`Plate_ID`),
  KEY `lib` (`FK_Library__Name`),
  KEY `user` (`FK_Employee__ID`),
  KEY `made` (`Plate_Created`),
  KEY `number` (`Plate_Number`),
  KEY `orderlist` (`FK_Library__Name`,`Plate_Number`),
  KEY `parent` (`FKParent_Plate__ID`),
  KEY `format` (`FK_Plate_Format__ID`),
  KEY `FK_Rack__ID` (`FK_Rack__ID`),
  KEY `FKOriginal_Plate__ID` (`FKOriginal_Plate__ID`),
  KEY `FKOriginal_Plate__ID_2` (`FKOriginal_Plate__ID`),
  KEY `Plate_Status` (`Plate_Status`),
  KEY `Plate_Content_Type` (`Plate_Content_Type`)
) TYPE=InnoDB;

