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
-- Table structure for table `Change_History`
--

DROP TABLE IF EXISTS `Change_History`;
CREATE TABLE `Change_History` (
  `Change_History_ID` int(11) NOT NULL auto_increment,
  `FK_DBField__ID` int(11) NOT NULL default '0',
  `Old_Value` varchar(255) default NULL,
  `New_Value` varchar(255) default NULL,
  `FK_Employee__ID` int(11) NOT NULL default '0',
  `Modified_Date` datetime NOT NULL default '0000-00-00 00:00:00',
  `Record_ID` varchar(40) NOT NULL default '',
  `Comment` text,
  PRIMARY KEY  (`Change_History_ID`),
  KEY `FK_DBField__ID` (`FK_DBField__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
