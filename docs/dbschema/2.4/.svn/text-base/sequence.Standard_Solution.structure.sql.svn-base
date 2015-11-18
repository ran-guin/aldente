-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Standard_Solution`
--

DROP TABLE IF EXISTS `Standard_Solution`;
CREATE TABLE `Standard_Solution` (
  `Standard_Solution_ID` int(11) NOT NULL auto_increment,
  `Standard_Solution_Name` varchar(40) default NULL,
  `Standard_Solution_Parameters` int(11) default NULL,
  `Standard_Solution_Formula` text,
  `Standard_Solution_Status` enum('Active','Inactive','Development') default NULL,
  `Standard_Solution_Message` text,
  `Reagent_Parameter` varchar(40) default NULL,
  `Label_Type` enum('Laser','ZPL') default 'ZPL',
  `FK_Barcode_Label__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Standard_Solution_ID`),
  UNIQUE KEY `name` (`Standard_Solution_Name`)
) TYPE=InnoDB;

