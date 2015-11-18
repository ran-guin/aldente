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
-- Table structure for table `Probe_Set_Value`
--

DROP TABLE IF EXISTS `Probe_Set_Value`;
CREATE TABLE `Probe_Set_Value` (
  `Probe_Set_Value_ID` int(11) NOT NULL auto_increment,
  `FK_Probe_Set__ID` int(11) NOT NULL default '0',
  `FK_GenechipExpAnalysis__ID` int(11) NOT NULL default '0',
  `Probe_Set_Type` enum('Housekeeping Control','Spike Control') default NULL,
  `Sig5` float(10,2) default NULL,
  `Det5` char(10) default NULL,
  `SigM` float(10,2) default NULL,
  `DetM` char(10) default NULL,
  `Sig3` float(10,2) default NULL,
  `Det3` char(10) default NULL,
  `SigAll` float(10,2) default NULL,
  `Sig35` float(10,2) default NULL,
  PRIMARY KEY  (`Probe_Set_Value_ID`),
  KEY `genechipanalysis` (`FK_GenechipExpAnalysis__ID`),
  KEY `probe_set` (`FK_Probe_Set__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

