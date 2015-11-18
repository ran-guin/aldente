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
-- Table structure for table `Patch`
--

DROP TABLE IF EXISTS `Patch`;
CREATE TABLE `Patch` (
  `Patch_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_Package__ID` int(11) NOT NULL DEFAULT '0',
  `Patch_Type` enum('bug fix','installation') NOT NULL DEFAULT 'installation',
  `Patch_Name` varchar(60) NOT NULL DEFAULT '',
  `Install_Status` enum('Installed','Marked for install','Not installed','Installed with errors','Installation aborted','Installing') DEFAULT NULL,
  `Installation_Date` date NOT NULL DEFAULT '0000-00-00',
  `FKRelease_Version__ID` int(11) NOT NULL DEFAULT '0',
  `Patch_Version` varchar(40) NOT NULL DEFAULT '',
  `Patch_Description` text,
  PRIMARY KEY (`Patch_ID`),
  UNIQUE KEY `patch_version` (`Patch_Version`),
  UNIQUE KEY `patch_name` (`Patch_Name`),
  KEY `FK_Package__ID` (`FK_Package__ID`),
  KEY `version` (`FKRelease_Version__ID`)
) ENGINE=MyISAM AUTO_INCREMENT=89 DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

