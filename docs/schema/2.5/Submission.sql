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
-- Table structure for table `Submission`
--

DROP TABLE IF EXISTS `Submission`;
CREATE TABLE `Submission` (
  `Submission_ID` int(11) NOT NULL auto_increment,
  `Submission_DateTime` datetime default NULL,
  `Submission_Source` enum('External','Internal') default NULL,
  `Submission_Status` enum('Draft','Submitted','Approved','Completed','Cancelled','Rejected') default NULL,
  `FK_Contact__ID` int(11) default NULL,
  `FKSubmitted_Employee__ID` int(11) default NULL,
  `Submission_Comments` text,
  `FKApproved_Employee__ID` int(11) default NULL,
  `Approved_DateTime` datetime default NULL,
  `FKTo_Grp__ID` int(11) default NULL,
  `FKFrom_Grp__ID` int(11) default NULL,
  `Table_Name` varchar(40) default NULL,
  `Key_Value` varchar(40) default NULL,
  PRIMARY KEY  (`Submission_ID`),
  KEY `FKSubmitted_Employee__ID` (`FKSubmitted_Employee__ID`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`),
  KEY `FKApproved_Employee__ID` (`FKApproved_Employee__ID`),
  KEY `FK_Grp__ID` (`FKTo_Grp__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

