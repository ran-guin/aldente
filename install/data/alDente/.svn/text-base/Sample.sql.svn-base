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
-- Table structure for table `Sample`
--

DROP TABLE IF EXISTS `Sample`;
CREATE TABLE `Sample` (
  `Sample_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Sample_Name` varchar(40) DEFAULT NULL,
  `Sample_Type` enum('Clone','Extraction') DEFAULT NULL,
  `Sample_Comments` text,
  `FKParent_Sample__ID` int(11) DEFAULT NULL,
  `FK_Source__ID` int(11) NOT NULL DEFAULT '0',
  `FKOriginal_Plate__ID` int(11) NOT NULL DEFAULT '0',
  `Original_Well` char(3) DEFAULT NULL,
  `FK_Library__Name` varchar(8) DEFAULT NULL,
  `Plate_Number` int(11) DEFAULT NULL,
  `FK_Sample_Type__ID` int(11) NOT NULL DEFAULT '0',
  `Sample_Source` enum('Original','Extraction','Clone') DEFAULT NULL,
  PRIMARY KEY (`Sample_ID`),
  KEY `name` (`Sample_Name`),
  KEY `FKParent_Sample__ID` (`FKParent_Sample__ID`),
  KEY `Sample_Type` (`Sample_Type`),
  KEY `FK_Source__ID` (`FK_Source__ID`),
  KEY `lpw` (`FK_Library__Name`,`Plate_Number`,`Original_Well`),
  KEY `type` (`FK_Sample_Type__ID`),
  KEY `orig` (`FKOriginal_Plate__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

