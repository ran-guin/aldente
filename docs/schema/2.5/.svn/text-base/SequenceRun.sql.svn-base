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
-- Table structure for table `SequenceRun`
--

DROP TABLE IF EXISTS `SequenceRun`;
CREATE TABLE `SequenceRun` (
  `SequenceRun_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) default NULL,
  `FK_Chemistry_Code__Name` varchar(5) default NULL,
  `FKPrimer_Solution__ID` int(11) default NULL,
  `FKMatrix_Solution__ID` int(11) default NULL,
  `FKBuffer_Solution__ID` int(11) default NULL,
  `DNA_Volume` float default NULL,
  `Total_Prep_Volume` smallint(6) default NULL,
  `BrewMix_Concentration` float default NULL,
  `Reaction_Volume` tinyint(4) default NULL,
  `Resuspension_Volume` tinyint(4) default NULL,
  `Slices` varchar(20) default NULL,
  `Run_Format` enum('96','384','96x4','16xN') default NULL,
  `Run_Module` varchar(128) default NULL,
  `Run_Time` int(11) default NULL,
  `Run_Voltage` int(11) default NULL,
  `Run_Temperature` int(11) default NULL,
  `Injection_Time` int(11) default NULL,
  `Injection_Voltage` int(11) default NULL,
  `Mobility_Version` enum('','1','2','3') default '',
  `PlateSealing` enum('None','Foil','Heat Sealing','Septa') default 'None',
  `Run_Direction` enum('3prime','5prime','N/A','Unknown') default 'N/A',
  PRIMARY KEY  (`SequenceRun_ID`),
  UNIQUE KEY `FK_Run__ID_2` (`FK_Run__ID`),
  KEY `FK_Run__ID` (`FK_Run__ID`),
  KEY `FKPrimer_Solution__ID` (`FKPrimer_Solution__ID`),
  KEY `FK_Chemistry_Code__Name` (`FK_Chemistry_Code__Name`),
  KEY `FKMatrix_Solution__ID` (`FKMatrix_Solution__ID`,`FKBuffer_Solution__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

