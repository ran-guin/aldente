-- MySQL dump 10.9
--
-- Host: lims01    Database: sequence
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
-- Table structure for table `GelRun`
--

DROP TABLE IF EXISTS `GelRun`;
CREATE TABLE `GelRun` (
  `GelRun_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) default NULL,
  `FKPoured_Employee__ID` int(11) default NULL,
  `FKComb_Equipment__ID` int(11) default NULL,
  `FKAgarose_Solution__ID` int(11) default NULL,
  `FKAgarosePour_Equipment__ID` int(11) default NULL,
  `Agarose_Percentage` varchar(5) default NULL,
  `File_Extension_Type` enum('sizes','none') default NULL,
  `GelRun_Type` enum('Sizing Gel','Other') default NULL,
  `FKGelBox_Equipment__ID` int(11) default NULL,
  `FK_GelRun_Purpose__ID` int(11) default NULL,
  PRIMARY KEY  (`GelRun_ID`),
  KEY `FK_Run__ID` (`FK_Run__ID`),
  KEY `FKPoured_Employee__ID` (`FKPoured_Employee__ID`),
  KEY `FKComb_Equipment__ID` (`FKComb_Equipment__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

