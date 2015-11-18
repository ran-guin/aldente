-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Source`
--

DROP TABLE IF EXISTS `Source`;
CREATE TABLE `Source` (
  `Source_ID` int(11) NOT NULL auto_increment,
  `FKParent_Source__ID` int(11) default NULL,
  `External_Identifier` varchar(40) NOT NULL default '',
  `Source_Type` enum('Library_Segment','RNA_Source','ReArray_Plate','Ligation','Microtiter','Xformed_Cells','External') default NULL,
  `Source_Status` enum('Active','Inactive') default 'Active',
  `Label` varchar(40) default NULL,
  `FK_Original_Source__ID` int(11) default NULL,
  `Received_Date` date NOT NULL default '0000-00-00',
  `Current_Amount` float(10,3) default NULL,
  `Original_Amount` float(10,3) default NULL,
  `Amount_Units` enum('','ul','ml','ul/well','mg','ug','ng','pg','Cells','Embryos','Litters','Organs','Animals') default NULL,
  `FKReceived_Employee__ID` int(11) default NULL,
  `FK_Rack__ID` int(11) NOT NULL default '0',
  `Source_Number` int(11) NOT NULL default '1',
  `FK_Barcode_Label__ID` int(11) NOT NULL default '0',
  `Notes` text,
  `FKSource_Plate__ID` int(11) default NULL,
  PRIMARY KEY  (`Source_ID`),
  KEY `FK_Original_Source__ID` (`FK_Original_Source__ID`),
  KEY `FK_Rack__ID` (`FK_Rack__ID`),
  KEY `FKReceived_Employee__ID` (`FKReceived_Employee__ID`),
  KEY `FK_Barcode_Label__ID` (`FK_Barcode_Label__ID`),
  KEY `FKParent_Source__ID` (`FKParent_Source__ID`)
) TYPE=InnoDB;

