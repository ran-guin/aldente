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
-- Table structure for table `Trace_Submission`
--

DROP TABLE IF EXISTS `Trace_Submission`;
CREATE TABLE `Trace_Submission` (
  `Trace_Submission_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_Run__ID` int(11) DEFAULT NULL,
  `Well` char(4) NOT NULL DEFAULT '',
  `Submission_Status` enum('Bundled','In Process','Accepted','Rejected') DEFAULT NULL,
  `FK_Sample__ID` int(11) NOT NULL DEFAULT '0',
  `Submitted_Length` int(11) NOT NULL DEFAULT '0',
  `FK_Submission_Volume__ID` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`Trace_Submission_ID`),
  UNIQUE KEY `sequence_read` (`FK_Run__ID`,`Well`,`FK_Submission_Volume__ID`),
  KEY `length` (`Submitted_Length`),
  KEY `FK_Sample__ID` (`FK_Sample__ID`),
  KEY `FK_Submission_Volume__ID` (`FK_Submission_Volume__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

