-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Stock`
--

DROP TABLE IF EXISTS `Stock`;
CREATE TABLE `Stock` (
  `Stock_ID` int(11) NOT NULL auto_increment,
  `Stock_Name` varchar(80) default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Stock_Lot_Number` varchar(80) default NULL,
  `Stock_Received` date default NULL,
  `Stock_Size` float default NULL,
  `Stock_Size_Units` enum('mL','uL','litres','mg','grams','kg','pcs','boxes','tubes','rxns','n/a') default NULL,
  `Stock_Description` text,
  `FK_Orders__ID` int(11) default NULL,
  `Stock_Type` enum('Solution','Reagent','Kit','Box','Equipment','Service Contract','Computer Equip','Misc_Item') default NULL,
  `FK_Box__ID` int(11) default NULL,
  `Stock_Catalog_Number` varchar(80) default NULL,
  `Stock_Number_in_Batch` int(11) default NULL,
  `Stock_Cost` float default NULL,
  `FK_Organization__ID` int(11) default NULL,
  `Stock_Source` enum('Box','Order','Sample','Made in House') default NULL,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FK_Barcode_Label__ID` int(11) default NULL,
  `Identifier_Number` varchar(80) default NULL,
  `Identifier_Number_Type` enum('Component Number') default NULL,
  PRIMARY KEY  (`Stock_ID`),
  KEY `cat` (`Stock_Catalog_Number`),
  KEY `name` (`Stock_Name`),
  KEY `box` (`FK_Box__ID`),
  KEY `FK_Orders__ID` (`FK_Orders__ID`),
  KEY `FK_Barcode_Label__ID` (`FK_Barcode_Label__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Organization__ID` (`FK_Organization__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `grp_id` (`FK_Grp__ID`),
  KEY `employee_id` (`FK_Employee__ID`),
  KEY `barcode_label` (`FK_Barcode_Label__ID`),
  KEY `catnum` (`Stock_Catalog_Number`),
  KEY `stockname` (`Stock_Name`)
) TYPE=InnoDB;

