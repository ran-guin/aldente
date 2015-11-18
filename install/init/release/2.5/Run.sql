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
-- Table structure for table `Run`
--

DROP TABLE IF EXISTS `Run`;
CREATE TABLE `Run` (
  `Run_ID` int(11) NOT NULL auto_increment,
  `Run_Type` enum('SequenceRun','GelRun','SpectRun','BioanalyzerRun','GenechipRun','SolexaRun') NOT NULL default 'SequenceRun',
  `FK_Plate__ID` int(11) default NULL,
  `FK_RunBatch__ID` int(11) default NULL,
  `Run_DateTime` datetime default NULL,
  `Run_Comments` text,
  `Run_Test_Status` enum('Production','Test') default 'Production',
  `FKPosition_Rack__ID` int(11) default NULL,
  `Run_Status` enum('Initiated','In Process','Data Acquired','Analyzed','Aborted','Failed','Expired','Not Applicable','Analyzing') default 'Initiated',
  `Run_Directory` varchar(80) default NULL,
  `Billable` enum('Yes','No') default 'Yes',
  `Run_Validation` enum('Pending','Approved','Rejected') default 'Pending',
  `Excluded_Wells` text,
  `QC_Status` enum('N/A','Pending','Failed','Re-Test','Passed') default 'N/A',
  PRIMARY KEY  (`Run_ID`),
  UNIQUE KEY `Run_Directory` (`Run_Directory`),
  KEY `date` (`Run_DateTime`),
  KEY `plate` (`FK_Plate__ID`),
  KEY `state` (`Run_Status`),
  KEY `position` (`FKPosition_Rack__ID`),
  KEY `FK_RunBatch__ID` (`FK_RunBatch__ID`),
  KEY `Run_Validation` (`Run_Validation`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

