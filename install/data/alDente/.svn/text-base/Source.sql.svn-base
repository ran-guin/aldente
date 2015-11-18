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
-- Table structure for table `Source`
--

DROP TABLE IF EXISTS `Source`;
CREATE TABLE `Source` (
  `Source_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FKParent_Source__ID` int(11) DEFAULT NULL,
  `External_Identifier` varchar(40) NOT NULL DEFAULT '',
  `Source_Status` enum('Active','Reserved','On Hold','Inactive','Thrown Out','Exported','Failed','Cancelled','Archived') DEFAULT NULL,
  `Source_Label` varchar(40) NOT NULL DEFAULT '',
  `FK_Original_Source__ID` int(11) DEFAULT NULL,
  `Received_Date` date NOT NULL DEFAULT '0000-00-00',
  `Current_Amount` float DEFAULT NULL,
  `Original_Amount` float DEFAULT NULL,
  `Amount_Units` enum('','ul','ml','ul/well','mg','ug','ng','pg','Cells','Embryos','Litters','Organs','Animals','Million Cells','Sections') DEFAULT NULL,
  `FKReceived_Employee__ID` int(11) DEFAULT NULL,
  `FK_Rack__ID` int(11) NOT NULL DEFAULT '0',
  `Source_Number` varchar(40) DEFAULT NULL,
  `FK_Barcode_Label__ID` int(11) NOT NULL DEFAULT '0',
  `Notes` text,
  `FKSource_Plate__ID` int(11) DEFAULT NULL,
  `FK_Plate_Format__ID` int(11) DEFAULT NULL,
  `FK_Shipment__ID` int(11) DEFAULT NULL,
  `FKReference_Project__ID` int(11) NOT NULL DEFAULT '0',
  `FK_Storage_Medium__ID` int(11) DEFAULT NULL,
  `Storage_Medium_Quantity_Units` enum('','ml','ul') DEFAULT NULL,
  `Storage_Medium_Quantity` double(8,4) DEFAULT NULL,
  `Sample_Collection_Time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `FK_Sample_Type__ID` int(11) NOT NULL,
  `FKOriginal_Source__ID` int(11) DEFAULT NULL,
  PRIMARY KEY (`Source_ID`),
  KEY `FK_Original_Source__ID` (`FK_Original_Source__ID`),
  KEY `FK_Rack__ID` (`FK_Rack__ID`),
  KEY `FKReceived_Employee__ID` (`FKReceived_Employee__ID`),
  KEY `FK_Barcode_Label__ID` (`FK_Barcode_Label__ID`),
  KEY `FKParent_Source__ID` (`FKParent_Source__ID`),
  KEY `label` (`Source_Label`),
  KEY `number` (`Source_Number`),
  KEY `id` (`External_Identifier`),
  KEY `FKSource_Plate__ID` (`FKSource_Plate__ID`),
  KEY `FK_Plate_Format__ID` (`FK_Plate_Format__ID`),
  KEY `Shipment` (`FK_Shipment__ID`),
  KEY `Reference_Project` (`FKReference_Project__ID`),
  KEY `Storage_Medium` (`FK_Storage_Medium__ID`),
  KEY `Sample_Type` (`FK_Sample_Type__ID`),
  KEY `Original_Source` (`FKOriginal_Source__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

