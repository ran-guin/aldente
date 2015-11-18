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
  `Stock_Type` enum('Solution','Reagent','Kit','Box','Microarray','Equipment','Service_Contract','Computer_Equip','Misc_Item') default NULL,
  `FK_Box__ID` int(11) default NULL,
  `Stock_Catalog_Number` varchar(80) default NULL,
  `Stock_Number_in_Batch` int(11) default NULL,
  `Stock_Cost` float default NULL,
  `FK_Organization__ID` int(11) default NULL,
  `Stock_Source` enum('Box','Order','Sample','Made in House') default NULL,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FK_Barcode_Label__ID` int(11) default NULL,
  `Identifier_Number` varchar(80) default NULL,
  `Identifier_Number_Type` enum('','Component Number') default NULL,
  `Purchase_Order` varchar(20) default NULL,
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
  KEY `stockname` (`Stock_Name`),
  KEY `lot` (`Stock_Lot_Number`),
  KEY `identifier` (`Identifier_Number_Type`),
  KEY `indentifier_number` (`Identifier_Number`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

