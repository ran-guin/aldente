-- MySQL dump 10.9
--
-- Host: lims02    Database: sequence
-- ------------------------------------------------------
-- Server version	4.1.20-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Equipment`
--

DROP TABLE IF EXISTS `Equipment`;
CREATE TABLE `Equipment` (
  `Equipment_ID` int(4) NOT NULL auto_increment,
  `Equipment_Name` varchar(40) default NULL,
  `Equipment_Type` enum('','Sequencer','Centrifuge','Thermal Cycler','Freezer','Liquid Dispenser','Platform Shaker','Incubator','Colony Picker','Plate Reader','Storage','Power Supply','Miscellaneous','Genechip Scanner','Gel Comb','Gel Box','Fluorimager','Spectrophotometer','Bioanalyzer','Hyb Oven','Solexa','GCOS Server','Printer','Pipette','Balance','PDA','Cluster Station') default NULL,
  `Equipment_Comments` text,
  `Model` varchar(80) default NULL,
  `Serial_Number` varchar(80) default NULL,
  `Acquired` date default NULL,
  `Equipment_Cost` float default NULL,
  `Equipment_Number` int(11) default NULL,
  `Equipment_Number_in_Batch` int(11) default NULL,
  `FK_Stock__ID` int(11) default NULL,
  `Equipment_Alias` varchar(40) default NULL,
  `Equipment_Description` text,
  `Equipment_Location` enum('Sequence Lab','Chromos','CDC','CRC','Functional Genomics','Linen','GE Lab','GE Lab - RNA area','GE Lab - DITAG area','Mapping Lab','MGC Lab') default NULL,
  `Equipment_Status` enum('In Use','Not In Use','Removed') default 'In Use',
  `FK_Location__ID` int(11) NOT NULL default '0',
  `Equipment_Condition` enum('-80 degrees','-40 degrees','-20 degrees','+4 degrees','Variable','Room Temperature','') NOT NULL default '',
  PRIMARY KEY  (`Equipment_ID`),
  UNIQUE KEY `equip` (`Equipment_Name`),
  KEY `FK_Stock__ID` (`FK_Stock__ID`),
  KEY `model` (`Model`),
  KEY `serial` (`Serial_Number`),
  KEY `type` (`Equipment_Type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

