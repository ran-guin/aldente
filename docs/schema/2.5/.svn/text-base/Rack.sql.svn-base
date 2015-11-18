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
-- Table structure for table `Rack`
--

DROP TABLE IF EXISTS `Rack`;
CREATE TABLE `Rack` (
  `Rack_ID` int(4) NOT NULL auto_increment,
  `FK_Equipment__ID` int(11) default NULL,
  `Rack_Type` enum('Shelf','Rack','Box','Slot') NOT NULL default 'Shelf',
  `Rack_Name` varchar(80) default NULL,
  `Movable` enum('Y','N') NOT NULL default 'Y',
  `Rack_Alias` varchar(80) default NULL,
  `FKParent_Rack__ID` int(11) default NULL,
  PRIMARY KEY  (`Rack_ID`),
  UNIQUE KEY `alias` (`Rack_Alias`),
  KEY `Equipment_FK` (`FK_Equipment__ID`),
  KEY `type` (`Rack_Type`),
  KEY `name` (`Rack_Name`),
  KEY `parent_rack_id` (`FKParent_Rack__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

