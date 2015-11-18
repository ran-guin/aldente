-- MySQL dump 10.9
--
-- Host: limsdev04    Database: skeleton
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
-- Table structure for table `Grp`
--

DROP TABLE IF EXISTS `Grp`;
CREATE TABLE `Grp` (
  `Grp_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Grp_Name` varchar(80) NOT NULL DEFAULT '',
  `FK_Department__ID` int(11) NOT NULL DEFAULT '0',
  `Access` enum('Lab','Admin','Guest','Report','Bioinformatics') DEFAULT NULL,
  `Grp_Type` enum('Public','Lab','Lab Admin','Project Admin','TechD','Production','Research','Technical Support','Informatics','QC','Purchasing','Shared') DEFAULT NULL,
  `Grp_Status` enum('Active','Inactive') DEFAULT 'Active',
  `FK_DB_Login__ID` int(11) DEFAULT NULL,
  PRIMARY KEY (`Grp_ID`),
  KEY `dept_id` (`FK_Department__ID`),
  KEY `DB_Login` (`FK_DB_Login__ID`)
) ENGINE=InnoDB AUTO_INCREMENT=82 DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

