-- MySQL dump 10.9
--
-- Host: limsdev04    Database: tg
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
-- Table structure for table `Site`
--

DROP TABLE IF EXISTS `Site`;
CREATE TABLE `Site` (
  `Site_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Site_Name` varchar(255) NOT NULL,
  `Site_Description` text,
  `Image_Name` varchar(255) DEFAULT NULL,
  `Site_Status` enum('Active','Pending','Inactive') DEFAULT NULL,
  `Audio_File` varchar(255) DEFAULT NULL,
  `Site_Title` varchar(15) NOT NULL,
  `FKTour_Site__ID` int(11) NOT NULL,
  `Site_Type` enum('City','Tour','Cultural','Restaurant','POI') NOT NULL DEFAULT 'POI',
  `Latitude` decimal(10,6) DEFAULT NULL,
  `Longitude` decimal(10,6) DEFAULT NULL,
  `Site_Address` varchar(255) DEFAULT NULL,
  `FKOwner_User__ID` int(11) NOT NULL,
  `FK_Tour__ID` int(11) DEFAULT NULL,
  PRIMARY KEY (`Site_ID`),
  KEY `Site_Name` (`Site_Name`,`Site_Status`),
  KEY `Site_Title` (`Site_Title`,`FKTour_Site__ID`),
  KEY `FKTour_Site__ID` (`FKTour_Site__ID`),
  KEY `Site_Type` (`Site_Type`),
  KEY `Owner_User` (`FKOwner_User__ID`),
  KEY `Tour` (`FK_Tour__ID`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

