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
-- Table structure for table `GenechipExpAnalysis`
--

DROP TABLE IF EXISTS `GenechipExpAnalysis`;
CREATE TABLE `GenechipExpAnalysis` (
  `GenechipExpAnalysis_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `Absent_Probe_Sets` float(10,3) default NULL,
  `Absent_Probe_Sets_Percent` decimal(5,2) default NULL,
  `Algorithm` char(40) default NULL,
  `Alpha1` float(10,3) default NULL,
  `Alpha2` float(10,3) default NULL,
  `Avg_A_Signal` float(10,3) default NULL,
  `Avg_Background` float(10,3) default NULL,
  `Avg_CentralMinus` float(10,3) default NULL,
  `Avg_CornerMinus` float(10,3) default NULL,
  `Avg_CornerPlus` float(10,3) default NULL,
  `Avg_M_Signal` float(10,3) default NULL,
  `Avg_Noise` float(10,3) default NULL,
  `Avg_P_Signal` float(10,3) default NULL,
  `Avg_Signal` float(10,3) default NULL,
  `Controls` char(40) default NULL,
  `Count_CentralMinus` float(10,3) default NULL,
  `Count_CornerMinus` float(10,3) default NULL,
  `Count_CornerPlus` float(10,3) default NULL,
  `Marginal_Probe_Sets` float(10,3) default NULL,
  `Marginal_Probe_Sets_Percent` decimal(5,2) default NULL,
  `Max_Background` float(10,3) default NULL,
  `Max_Noise` float(10,3) default NULL,
  `Min_Background` float(10,3) default NULL,
  `Min_Noise` float(10,3) default NULL,
  `Noise_RawQ` float(10,3) default NULL,
  `Norm_Factor` float(10,3) default NULL,
  `Present_Probe_Sets` float(10,3) default NULL,
  `Present_Probe_Sets_Percent` decimal(5,2) default NULL,
  `Probe_Pair_Thr` float(10,3) default NULL,
  `Scale_Factor` float(10,3) default NULL,
  `Std_Background` float(10,3) default NULL,
  `Std_Noise` float(10,3) default NULL,
  `Tau` float(10,3) default NULL,
  `TGT` float(10,3) default NULL,
  `Total_Probe_Sets` float(10,3) default NULL,
  PRIMARY KEY  (`GenechipExpAnalysis_ID`),
  KEY `run_id` (`FK_Run__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

