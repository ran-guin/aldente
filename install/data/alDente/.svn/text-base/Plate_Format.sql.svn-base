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
-- Table structure for table `Plate_Format`
--

DROP TABLE IF EXISTS `Plate_Format`;
CREATE TABLE `Plate_Format` (
  `Plate_Format_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Plate_Format_Type` char(40) DEFAULT NULL,
  `Plate_Format_Status` enum('Active','Inactive') DEFAULT NULL,
  `FK_Barcode_Label__ID` int(11) DEFAULT NULL,
  `Max_Row` char(2) DEFAULT NULL,
  `Max_Col` tinyint(4) DEFAULT NULL,
  `Plate_Format_Style` enum('Plate','Tube','Array','Gel') DEFAULT NULL,
  `Well_Capacity_mL` float DEFAULT NULL,
  `Capacity_Units` char(4) DEFAULT NULL,
  `Wells` smallint(6) NOT NULL DEFAULT '1',
  `Well_Lookup_Key` enum('Plate_384','Plate_96','Gel_121_Standard','Gel_121_Custom','Tube') DEFAULT NULL,
  PRIMARY KEY (`Plate_Format_ID`),
  UNIQUE KEY `name` (`Plate_Format_Type`),
  KEY `FK_Barcode_Label__ID` (`FK_Barcode_Label__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

