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
-- Table structure for table `Original_Source`
--

DROP TABLE IF EXISTS `Original_Source`;
CREATE TABLE `Original_Source` (
  `Original_Source_ID` int(11) NOT NULL auto_increment,
  `Original_Source_Name` varchar(40) NOT NULL default '',
  `Organism` varchar(40) default NULL,
  `Sex` varchar(20) default NULL,
  `Tissue` varchar(40) default NULL,
  `Strain` varchar(40) default NULL,
  `Host` text NOT NULL,
  `Description` text,
  `FK_Contact__ID` int(11) default NULL,
  `FKCreated_Employee__ID` int(11) default NULL,
  `Defined_Date` date NOT NULL default '0000-00-00',
  `FK_Stage__ID` int(11) NOT NULL default '0',
  `FK_Tissue__ID` int(11) NOT NULL default '0',
  `FK_Organism__ID` int(11) NOT NULL default '0',
  `Subtissue_temp` varchar(40) default NULL,
  `Tissue_temp` varchar(40) NOT NULL default '',
  `Organism_temp` varchar(40) default NULL,
  `Stage_temp` varchar(40) default NULL,
  `Note_temp` varchar(40) NOT NULL default '',
  `Thelier_temp` varchar(40) default NULL,
  `Sample_Available` enum('Yes','No','Later') default NULL,
  `FK_Taxonomy__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Original_Source_ID`),
  UNIQUE KEY `OS_Name` (`Original_Source_Name`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`),
  KEY `FKCreated_Employee__ID` (`FKCreated_Employee__ID`),
  KEY `taxonomy` (`FK_Taxonomy__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

