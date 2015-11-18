-- MySQL dump 10.9
--
-- Host: limsdev04    Database: Core_Current
-- ------------------------------------------------------
-- Server version	5.5.10

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
  `Stock_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_Employee__ID` int(11) DEFAULT NULL,
  `Stock_Lot_Number` varchar(80) DEFAULT NULL,
  `Stock_Received` date DEFAULT NULL,
  `FK_Orders__ID` int(11) DEFAULT NULL,
  `FK_Box__ID` int(11) DEFAULT NULL,
  `Stock_Number_in_Batch` int(11) DEFAULT NULL,
  `Stock_Cost` float DEFAULT NULL,
  `FK_Grp__ID` int(11) NOT NULL DEFAULT '0',
  `FK_Barcode_Label__ID` int(11) DEFAULT NULL,
  `Identifier_Number` varchar(80) DEFAULT NULL,
  `Identifier_Number_Type` enum('Component Number','Reference ID') DEFAULT NULL,
  `FK_Stock_Catalog__ID` int(11) NOT NULL DEFAULT '0',
  `Stock_Notes` text,
  `PO_Number` varchar(20) DEFAULT NULL,
  `Requisition_Number` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`Stock_ID`),
  KEY `box` (`FK_Box__ID`),
  KEY `FK_Orders__ID` (`FK_Orders__ID`),
  KEY `FK_Barcode_Label__ID` (`FK_Barcode_Label__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `grp_id` (`FK_Grp__ID`),
  KEY `employee_id` (`FK_Employee__ID`),
  KEY `barcode_label` (`FK_Barcode_Label__ID`),
  KEY `lot` (`Stock_Lot_Number`),
  KEY `identifier` (`Identifier_Number_Type`),
  KEY `indentifier_number` (`Identifier_Number`),
  KEY `Catalog_ID` (`FK_Stock_Catalog__ID`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

