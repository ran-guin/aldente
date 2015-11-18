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
-- Table structure for table `Primer`
--

DROP TABLE IF EXISTS `Primer`;
CREATE TABLE `Primer` (
  `Primer_Name` varchar(40) NOT NULL default '',
  `Primer_Sequence` text NOT NULL,
  `Primer_ID` int(2) NOT NULL auto_increment,
  `Purity` text,
  `Tm1` int(2) default NULL,
  `Tm50` int(2) default NULL,
  `GC_Percent` int(2) default NULL,
  `Coupling_Eff` float(10,2) default NULL,
  `Primer_Type` enum('Standard','Custom','Oligo','Amplicon','Adapter') default NULL,
  `Primer_OrderDateTime` datetime default NULL,
  `Primer_External_Order_Number` varchar(80) default NULL,
  `Primer_Status` enum('','Ordered','Received','Inactive') default '',
  PRIMARY KEY  (`Primer_ID`),
  UNIQUE KEY `primer` (`Primer_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

