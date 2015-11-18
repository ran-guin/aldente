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
-- Table structure for table `GenechipMapAnalysis`
--

DROP TABLE IF EXISTS `GenechipMapAnalysis`;
CREATE TABLE `GenechipMapAnalysis` (
  `GenechipMapAnalysis_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `Total_SNP` int(11) default NULL,
  `Total_QC_Probes` int(11) default NULL,
  `Called_Gender` char(2) default NULL,
  `SNP_Call_Percent` decimal(5,2) default NULL,
  `AA_Call_Percent` decimal(5,2) default NULL,
  `AB_Call_Percent` decimal(5,2) default NULL,
  `BB_Call_Percent` decimal(5,2) default NULL,
  `QC_AFFX_5Q_123` decimal(10,2) default NULL,
  `QC_AFFX_5Q_456` decimal(10,2) default NULL,
  `QC_AFFX_5Q_789` decimal(10,2) default NULL,
  `QC_AFFX_5Q_ABC` decimal(10,2) default NULL,
  `QC_MCR_Percent` decimal(5,2) default NULL,
  `QC_MDR_Percent` decimal(5,2) default NULL,
  `SNP1` char(10) default NULL,
  `SNP2` char(10) default NULL,
  `SNP3` char(10) default NULL,
  `SNP4` char(10) default NULL,
  `SNP5` char(10) default NULL,
  `SNP6` char(10) default NULL,
  `SNP7` char(10) default NULL,
  `SNP8` char(10) default NULL,
  `SNP9` char(10) default NULL,
  `SNP10` char(10) default NULL,
  `SNP11` char(10) default NULL,
  `SNP12` char(10) default NULL,
  `SNP13` char(10) default NULL,
  `SNP14` char(10) default NULL,
  `SNP15` char(10) default NULL,
  `SNP16` char(10) default NULL,
  `SNP17` char(10) default NULL,
  `SNP18` char(10) default NULL,
  `SNP19` char(10) default NULL,
  `SNP20` char(10) default NULL,
  `SNP21` char(10) default NULL,
  `SNP22` char(10) default NULL,
  `SNP23` char(10) default NULL,
  `SNP24` char(10) default NULL,
  `SNP25` char(10) default NULL,
  `SNP26` char(10) default NULL,
  `SNP27` char(10) default NULL,
  `SNP28` char(10) default NULL,
  `SNP29` char(10) default NULL,
  `SNP30` char(10) default NULL,
  `SNP31` char(10) default NULL,
  `SNP32` char(10) default NULL,
  `SNP33` char(10) default NULL,
  `SNP34` char(10) default NULL,
  `SNP35` char(10) default NULL,
  `SNP36` char(10) default NULL,
  `SNP37` char(10) default NULL,
  `SNP38` char(10) default NULL,
  `SNP39` char(10) default NULL,
  `SNP40` char(10) default NULL,
  `SNP41` char(10) default NULL,
  `SNP42` char(10) default NULL,
  `SNP43` char(10) default NULL,
  `SNP44` char(10) default NULL,
  `SNP45` char(10) default NULL,
  `SNP46` char(10) default NULL,
  `SNP47` char(10) default NULL,
  `SNP48` char(10) default NULL,
  `SNP49` char(10) default NULL,
  `SNP50` char(10) default NULL,
  PRIMARY KEY  (`GenechipMapAnalysis_ID`),
  KEY `run_id` (`FK_Run__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

