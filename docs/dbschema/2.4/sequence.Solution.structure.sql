-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Solution`
--

DROP TABLE IF EXISTS `Solution`;
CREATE TABLE `Solution` (
  `Solution_ID` int(11) NOT NULL auto_increment,
  `Solution_Started` datetime default NULL,
  `Solution_Quantity` float default NULL,
  `Solution_Expiry` date default NULL,
  `Quantity_Used` float default '0',
  `FK_Rack__ID` int(11) default NULL,
  `Solution_Finished` date default NULL,
  `Solution_Type` enum('Reagent','Solution','Primer','Buffer','Matrix') default NULL,
  `Solution_Status` enum('Unopened','Open','Finished','Temporary','Expired') default 'Unopened',
  `Solution_Cost` float default NULL,
  `FK_Stock__ID` int(11) default NULL,
  `FK_Solution_Info__ID` int(11) default NULL,
  `Solution_Number` int(11) default NULL,
  `Solution_Number_in_Batch` int(11) default NULL,
  `Solution_Notes` text,
  `QC_Status` enum('N/A','Pending','Failed','Re-Test','Passed') default 'N/A',
  PRIMARY KEY  (`Solution_ID`),
  KEY `stock` (`FK_Stock__ID`),
  KEY `FK_Solution_Info__ID` (`FK_Solution_Info__ID`),
  KEY `FK_Rack__ID` (`FK_Rack__ID`)
) TYPE=InnoDB;

