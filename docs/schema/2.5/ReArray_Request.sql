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
-- Table structure for table `ReArray_Request`
--

DROP TABLE IF EXISTS `ReArray_Request`;
CREATE TABLE `ReArray_Request` (
  `ReArray_Notify` text,
  `ReArray_Format_Size` enum('96-well','384-well') NOT NULL default '96-well',
  `ReArray_Type` enum('Clone Rearray','Manual Rearray','Reaction Rearray','Extraction Rearray','Pool Rearray') default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Request_DateTime` datetime default NULL,
  `FKTarget_Plate__ID` int(11) default NULL,
  `ReArray_Comments` text,
  `ReArray_Request` text,
  `ReArray_Request_ID` int(11) NOT NULL auto_increment,
  `FK_Lab_Request__ID` int(11) default NULL,
  `FK_Status__ID` int(11) NOT NULL default '0',
  `ReArray_Purpose` enum('Not applicable','96-well oligo prep','96-well EST prep','384-well oligo prep','384-well EST prep','384-well hardstop prep') default 'Not applicable',
  PRIMARY KEY  (`ReArray_Request_ID`),
  KEY `request_time` (`Request_DateTime`),
  KEY `request_target` (`FKTarget_Plate__ID`),
  KEY `request_emp` (`FK_Employee__ID`),
  KEY `FK_Lab_Request__ID` (`FK_Lab_Request__ID`),
  KEY `FK_Status__ID` (`FK_Status__ID`),
  KEY `ReArray_Purpose` (`ReArray_Purpose`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

