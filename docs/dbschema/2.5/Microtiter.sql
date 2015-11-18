-- MySQL dump 10.9
--
-- Host: lims02    Database: sequence
-- ------------------------------------------------------
-- Server version	4.1.20-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Microtiter`
--

DROP TABLE IF EXISTS `Microtiter`;
CREATE TABLE `Microtiter` (
  `Microtiter_ID` int(11) NOT NULL auto_increment,
  `Plates` int(11) default NULL,
  `Plate_Size` enum('96-well','384-well') default NULL,
  `Plate_Catalog_Number` varchar(40) default NULL,
  `VolumePerWell` int(11) default NULL,
  `Cell_Catalog_Number` varchar(40) default NULL,
  `FKSupplier_Organization__ID` int(11) default NULL,
  `Cell_Type` varchar(40) default NULL,
  `Media_Type` varchar(40) default NULL,
  `Sequencing_Type` enum('Primers','Transposon','Primers_and_transposon','Replicates') default NULL,
  `384_Well_Plates_To_Seq` int(11) default NULL,
  `FK_Source__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Microtiter_ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`),
  KEY `FKSupplier_Organization__ID` (`FKSupplier_Organization__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

