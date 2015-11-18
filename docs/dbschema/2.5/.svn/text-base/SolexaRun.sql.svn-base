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
-- Table structure for table `SolexaRun`
--

DROP TABLE IF EXISTS `SolexaRun`;
CREATE TABLE `SolexaRun` (
  `SolexaRun_ID` int(11) NOT NULL auto_increment,
  `Lane` enum('1','2','3','4','5','6','7','8') default NULL,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `FK_Flowcell__ID` int(11) NOT NULL default '0',
  `Cycles` int(11) default NULL,
  `Files_Status` enum('Raw','Deleting Images','Images Deleted','Ready for Storage','Storing','Stored','Protected','Delete/Move') default 'Raw',
  `QC_Check` enum('N/A','Pending','Failed','Re-Test','Passed') default 'N/A',
  `Protected` enum('Yes','No') default 'No',
  `Solexa_Sample_Type` enum('Control','SAGE','miRNA','TS') default NULL,
  `SolexaRun_Type` enum('Single','Paired') NOT NULL default 'Single',
  `SolexaRun_Finished` datetime default NULL,
  `Tiles` smallint(6) default NULL,
  PRIMARY KEY  (`SolexaRun_ID`),
  KEY `run_id` (`FK_Run__ID`),
  KEY `FK_Flowcell__ID` (`FK_Flowcell__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

