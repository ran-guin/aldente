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
-- Table structure for table `Contact`
--

DROP TABLE IF EXISTS `Contact`;
CREATE TABLE `Contact` (
  `Contact_ID` int(11) NOT NULL auto_increment,
  `Contact_Name` varchar(80) default NULL,
  `Position` text,
  `FK_Organization__ID` int(11) default NULL,
  `Contact_Phone` text,
  `Contact_Email` text,
  `Contact_Type` enum('Collaborator','Maintenance','Technical Support','Sales','Academic') default NULL,
  `contact_status` enum('Current','Old','Basic','Active') default 'Active',
  `Contact_Notes` text,
  `Contact_Fax` text,
  `First_Name` text,
  `Middle_Name` text,
  `Last_Name` text,
  `Category` enum('Collaborator','Maintenance','Technical Support','Sales','Academic') default NULL,
  `Home_Phone` text,
  `Work_Phone` text,
  `Pager` text,
  `Fax` text,
  `Mobile` text,
  `Other_Phone` text,
  `Primary_Location` enum('home','work') default NULL,
  `Home_Address` text,
  `Home_City` text,
  `Home_County` text,
  `Home_Postcode` text,
  `Home_Country` text,
  `Work_Address` text,
  `Work_City` text,
  `Work_County` text,
  `Work_Postcode` text,
  `Work_Country` text,
  `Email` text,
  `Personal_Website` text,
  `Business_Website` text,
  `Alternate_Email_1` text,
  `Alternate_Email_2` text,
  `Birthday` date default NULL,
  `Anniversary` date default NULL,
  `Comments` text,
  `Canonical_Name` varchar(40) NOT NULL default '',
  PRIMARY KEY  (`Contact_ID`),
  UNIQUE KEY `Contact_Name` (`Contact_Name`),
  KEY `FK_Organization__ID` (`FK_Organization__ID`),
  KEY `type` (`Contact_Type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

