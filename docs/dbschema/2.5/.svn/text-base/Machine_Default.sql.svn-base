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
-- Table structure for table `Machine_Default`
--

DROP TABLE IF EXISTS `Machine_Default`;
CREATE TABLE `Machine_Default` (
  `Machine_Default_ID` int(11) NOT NULL auto_increment,
  `FK_Equipment__ID` int(11) default NULL,
  `Run_Module` text,
  `NT_Data_dir` text,
  `NT_Samplesheet_dir` text,
  `Local_Samplesheet_dir` text,
  `Host` varchar(40) default NULL,
  `Local_Data_dir` text,
  `Sharename` text,
  `Agarose_Percentage` float default NULL,
  `Injection_Voltage` int(11) default NULL,
  `Injection_Time` int(11) default NULL,
  `Run_Voltage` int(11) default NULL,
  `Run_Time` int(11) default NULL,
  `Run_Temp` int(11) default NULL,
  `PMT1` int(11) default NULL,
  `PMT2` int(11) default NULL,
  `An_Module` text,
  `Foil_Piercing` tinyint(4) default NULL,
  `Chemistry_Version` tinyint(4) default NULL,
  `FK_Sequencer_Type__ID` tinyint(4) NOT NULL default '0',
  `Mount` varchar(80) default NULL,
  PRIMARY KEY  (`Machine_Default_ID`),
  KEY `FK_Equipment__ID` (`FK_Equipment__ID`),
  KEY `FK_Sequencer_Type__ID` (`FK_Sequencer_Type__ID`),
  KEY `host` (`Host`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

