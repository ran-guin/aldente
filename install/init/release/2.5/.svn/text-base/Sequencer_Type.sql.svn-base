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
-- Table structure for table `Sequencer_Type`
--

DROP TABLE IF EXISTS `Sequencer_Type`;
CREATE TABLE `Sequencer_Type` (
  `Sequencer_Type_ID` tinyint(4) NOT NULL auto_increment,
  `Sequencer_Type_Name` varchar(20) NOT NULL default '',
  `Well_Ordering` enum('Columns','Rows') NOT NULL default 'Columns',
  `Zero_Pad_Columns` enum('YES','NO') NOT NULL default 'NO',
  `FileFormat` varchar(255) NOT NULL default '',
  `RunDirectory` varchar(255) NOT NULL default '',
  `TraceFileExt` varchar(40) NOT NULL default '',
  `FailedTraceFileExt` varchar(40) NOT NULL default '',
  `SS_extension` varchar(5) default NULL,
  `Default_Terminator` enum('Big Dye','Water') NOT NULL default 'Water',
  `Capillaries` int(3) default NULL,
  `Sliceable` enum('Yes','No') default 'No',
  `By_Quadrant` enum('Yes','No') default 'No',
  PRIMARY KEY  (`Sequencer_Type_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

