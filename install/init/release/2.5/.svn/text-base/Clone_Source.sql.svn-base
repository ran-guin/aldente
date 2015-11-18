-- MySQL dump 10.9
--
-- Host: limsdev02    Database: aldente_init
-- ------------------------------------------------------
-- Server version	4.1.20

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Clone_Source`
--

DROP TABLE IF EXISTS `Clone_Source`;
CREATE TABLE `Clone_Source` (
  `Clone_Source_ID` int(11) NOT NULL auto_increment,
  `Source_Description` varchar(40) default NULL,
  `FK_Clone_Sample__ID` int(11) NOT NULL default '0',
  `FK_Plate__ID` int(11) default NULL,
  `clone_quadrant` enum('','a','b','c','d') default NULL,
  `Clone_Well` char(3) default NULL,
  `Well_384` char(3) default NULL,
  `FKSource_Organization__ID` int(11) default NULL,
  `Source_Name` varchar(40) default NULL,
  `Source_Comments` text,
  `Source_Library_ID` varchar(40) default NULL,
  `Source_Collection` varchar(40) default NULL,
  `Source_Library_Name` varchar(40) default NULL,
  `Source_Row` varchar(4) NOT NULL default '',
  `Source_Col` varchar(4) NOT NULL default '',
  `Source_5Prime_Site` text,
  `Source_Plate` int(11) default NULL,
  `Source_3Prime_Site` text,
  `Source_Vector` varchar(40) default NULL,
  `Source_Score` int(11) default NULL,
  `3prime_tag` varchar(40) default NULL,
  `5prime_tag` varchar(40) default NULL,
  `Source_Clone_Name` varchar(40) default NULL,
  `Source_Clone_Name_Type` varchar(40) default NULL,
  PRIMARY KEY  (`Clone_Source_ID`),
  KEY `clonesource_plate` (`FK_Plate__ID`),
  KEY `clonesource_clone` (`FK_Clone_Sample__ID`),
  KEY `clone` (`FK_Clone_Sample__ID`),
  KEY `name` (`Source_Name`),
  KEY `library` (`Source_Library_Name`),
  KEY `plate` (`Source_Plate`),
  KEY `well` (`Source_Collection`,`Source_Plate`,`Source_Row`,`Source_Col`),
  KEY `source_org_id` (`FKSource_Organization__ID`),
  KEY `clone_name` (`Source_Clone_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

