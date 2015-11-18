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
-- Table structure for table `Pipeline`
--

DROP TABLE IF EXISTS `Pipeline`;
CREATE TABLE `Pipeline` (
  `Pipeline_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Pipeline_Name` varchar(40) DEFAULT NULL,
  `FK_Grp__ID` int(11) NOT NULL DEFAULT '0',
  `Pipeline_Description` text,
  `Pipeline_Code` char(3) NOT NULL DEFAULT '',
  `FKParent_Pipeline__ID` int(11) DEFAULT NULL,
  `FK_Pipeline_Group__ID` int(11) DEFAULT NULL,
  `Pipeline_Status` enum('Active','Inactive') DEFAULT 'Active',
  `FKApplicable_Plate_Format__ID` int(11) DEFAULT NULL,
  PRIMARY KEY (`Pipeline_ID`),
  UNIQUE KEY `pipelineCode` (`Pipeline_Code`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Pipeline_Group__ID` (`FK_Pipeline_Group__ID`),
  KEY `FKParent_Pipeline__ID` (`FKParent_Pipeline__ID`),
  KEY `plate_format` (`FKApplicable_Plate_Format__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

