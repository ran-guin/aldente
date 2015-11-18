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
-- Table structure for table `SS_Config`
--

DROP TABLE IF EXISTS `SS_Config`;
CREATE TABLE `SS_Config` (
  `SS_Config_ID` int(11) NOT NULL auto_increment,
  `FK_Sequencer_Type__ID` int(4) NOT NULL default '0',
  `SS_Title` char(80) NOT NULL default '',
  `SS_Section` int(2) NOT NULL default '0',
  `SS_Order` tinyint(4) default NULL,
  `SS_Default` char(80) NOT NULL default '',
  `SS_Alias` char(80) NOT NULL default '',
  `SS_Orientation` enum('Column','Row','N/A') default NULL,
  `SS_Type` enum('Titled','Untitled','Hidden') NOT NULL default 'Titled',
  `SS_Prompt` enum('Text','Radio','Default','No') default NULL,
  `SS_Track` char(40) NOT NULL default '',
  PRIMARY KEY  (`SS_Config_ID`),
  KEY `FK_Sequencer_Type__ID` (`FK_Sequencer_Type__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

