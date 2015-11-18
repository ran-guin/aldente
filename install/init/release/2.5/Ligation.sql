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
-- Table structure for table `Ligation`
--

DROP TABLE IF EXISTS `Ligation`;
CREATE TABLE `Ligation` (
  `Ligation_ID` int(11) NOT NULL auto_increment,
  `Ligation_Volume` int(11) default NULL,
  `cfu` int(11) default NULL,
  `Sequencing_Type` enum('Primers','Transposon','Primers_and_transposon','Replicates','N/A') default NULL,
  `384_Well_Plates_To_Seq` int(11) default NULL,
  `FKExtraction_Plate__ID` int(11) default NULL,
  `FK_Source__ID` int(11) NOT NULL default '0',
  `384_Well_Plates_To_Pick` int(11) default '0',
  PRIMARY KEY  (`Ligation_ID`),
  KEY `FKExtraction_Plate__ID` (`FKExtraction_Plate__ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

