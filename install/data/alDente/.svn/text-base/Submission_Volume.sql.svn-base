-- MySQL dump 10.9
--
-- Host: limsdev04    Database: Core_Current
-- ------------------------------------------------------
-- Server version	5.5.10

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Submission_Volume`
--

DROP TABLE IF EXISTS `Submission_Volume`;
CREATE TABLE `Submission_Volume` (
  `Submission_Volume_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Submission_Target` text,
  `Volume_Name` varchar(40) NOT NULL DEFAULT '',
  `Submission_Date` date DEFAULT NULL,
  `FKSubmitter_Employee__ID` int(11) DEFAULT NULL,
  `Volume_Status` enum('In Process','Bundled','Submitted','Accepted','Rejected') DEFAULT NULL,
  `Volume_Comments` text,
  `Records` int(11) NOT NULL DEFAULT '0',
  `Approved_Date` date DEFAULT NULL,
  `SID` varchar(40) DEFAULT NULL,
  `FKRequester_Employee__ID` int(11) DEFAULT NULL,
  PRIMARY KEY (`Submission_Volume_ID`),
  UNIQUE KEY `name` (`Volume_Name`),
  KEY `FKSubmitter_Employee__ID` (`FKSubmitter_Employee__ID`),
  KEY `FKRequester_Employee__ID` (`FKRequester_Employee__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

