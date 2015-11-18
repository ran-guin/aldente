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
-- Table structure for table `GenechipRun`
--

DROP TABLE IF EXISTS `GenechipRun`;
CREATE TABLE `GenechipRun` (
  `GenechipRun_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `FKScanner_Equipment__ID` int(11) default NULL,
  `CEL_file` char(100) default NULL,
  `DAT_file` char(100) default NULL,
  `CHP_file` char(100) default NULL,
  `FKOven_Equipment__ID` int(11) default NULL,
  `FKSample_GCOS_Config__ID` int(11) NOT NULL default '0',
  `FKExperiment_GCOS_Config__ID` int(11) NOT NULL default '0',
  `Invoiced` enum('No','Yes') default 'No',
  PRIMARY KEY  (`GenechipRun_ID`),
  KEY `run` (`FK_Run__ID`),
  KEY `FKSample_GCOS_Config__ID` (`FKSample_GCOS_Config__ID`),
  KEY `FKExperiment_GCOS_Config__ID` (`FKExperiment_GCOS_Config__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

