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
-- Table structure for table `Lab_Protocol`
--

DROP TABLE IF EXISTS `Lab_Protocol`;
CREATE TABLE `Lab_Protocol` (
  `Lab_Protocol_Name` varchar(40) default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Lab_Protocol_Status` enum('Active','Old','Inactive') default NULL,
  `Lab_Protocol_Description` text,
  `Lab_Protocol_ID` int(11) NOT NULL auto_increment,
  `Lab_Protocol_VersionDate` date default NULL,
  `Max_Tracking_Size` enum('384','96') default '384',
  `Repeatable` enum('Yes','No') NOT NULL default 'Yes',
  PRIMARY KEY  (`Lab_Protocol_ID`),
  UNIQUE KEY `name` (`Lab_Protocol_Name`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

