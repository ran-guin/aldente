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
-- Table structure for table `Box`
--

DROP TABLE IF EXISTS `Box`;
CREATE TABLE `Box` (
  `Box_ID` int(11) NOT NULL auto_increment,
  `Box_Opened` date default NULL,
  `FK_Rack__ID` int(11) default NULL,
  `Box_Number` int(11) default NULL,
  `Box_Number_in_Batch` int(11) default NULL,
  `FK_Stock__ID` int(11) default NULL,
  `FKParent_Box__ID` int(11) default NULL,
  `Box_Serial_Number` text,
  `Box_Type` enum('Box','Kit','Supplies') NOT NULL default 'Box',
  `Box_Expiry` date default NULL,
  `Box_Status` enum('Unopened','Open','Expired','Inactive') default 'Unopened',
  PRIMARY KEY  (`Box_ID`),
  KEY `stock` (`FK_Stock__ID`),
  KEY `FK_Rack__ID` (`FK_Rack__ID`),
  KEY `FKParent_Box__ID` (`FKParent_Box__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

