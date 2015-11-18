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
-- Table structure for table `Stock_Catalog`
--

DROP TABLE IF EXISTS `Stock_Catalog`;
CREATE TABLE `Stock_Catalog` (
  `Stock_Catalog_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Stock_Catalog_Name` varchar(80) NOT NULL DEFAULT '',
  `Stock_Catalog_Description` text,
  `Stock_Catalog_Number` varchar(80) DEFAULT NULL,
  `Stock_Type` enum('Box','Buffer','Equipment','Kit','Matrix','Microarray','Primer','Reagent','Solution','Service_Contract','Computer_Equip','Misc_Item','Untracked') DEFAULT NULL,
  `Stock_Source` enum('Box','Order','Sample','Made in House') DEFAULT NULL,
  `Stock_Status` enum('Active','Inactive') DEFAULT 'Active',
  `Stock_Size` float DEFAULT NULL,
  `Stock_Size_Units` enum('mL','uL','litres','mg','grams','kg','pcs','boxes','tubes','rxns','nmoles','nL','n/a') DEFAULT NULL,
  `FK_Organization__ID` int(11) DEFAULT NULL,
  `FKVendor_Organization__ID` int(11) DEFAULT NULL,
  `Model` varchar(20) DEFAULT NULL,
  `FK_Equipment_Category__ID` int(11) DEFAULT '0',
  PRIMARY KEY (`Stock_Catalog_ID`),
  KEY `category_id` (`FK_Equipment_Category__ID`),
  KEY `Catalog_Name` (`Stock_Catalog_Name`),
  KEY `Catalog_Number` (`Stock_Catalog_Number`),
  KEY `FK_Organization__ID` (`FK_Organization__ID`),
  KEY `type` (`Stock_Type`),
  KEY `source` (`Stock_Source`),
  KEY `size` (`Stock_Size`,`Stock_Size_Units`),
  KEY `FKVendor_Organization__ID` (`FKVendor_Organization__ID`)
) ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

