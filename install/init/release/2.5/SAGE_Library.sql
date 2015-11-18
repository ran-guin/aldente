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
-- Table structure for table `SAGE_Library`
--

DROP TABLE IF EXISTS `SAGE_Library`;
CREATE TABLE `SAGE_Library` (
  `SAGE_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Sequencing_Library__ID` int(11) NOT NULL default '0',
  `Concatamer_Size_Fraction` int(11) NOT NULL default '0',
  `Clones_under500Insert_Percent` int(11) default '0',
  `Clones_over500Insert_Percent` int(11) default '0',
  `Tags_Requested` int(11) default NULL,
  `RNA_DNA_Extraction` text,
  `SAGE_Library_Type` enum('SAGE','LongSAGE','PCR-SAGE','PCR-LongSAGE','SAGELite-SAGE','SAGELite-LongSAGE') default NULL,
  `FKInsertSite_Enzyme__ID` int(11) default NULL,
  `FKAnchoring_Enzyme__ID` int(11) default NULL,
  `FKTagging_Enzyme__ID` int(11) default NULL,
  `Clones_with_no_Insert_Percent` int(11) default '0',
  `Starting_RNA_DNA_Amnt_ng` float(10,3) default NULL,
  `PCR_Cycles` int(11) default NULL,
  `cDNA_Amnt_Used_ng` float(10,3) default NULL,
  `DiTag_PCR_Cycle` int(11) default NULL,
  `DiTag_Template_Dilution_Factor` int(11) default NULL,
  `Adapter_A` varchar(20) default NULL,
  `Adapter_B` varchar(20) default NULL,
  `Blue_White_Selection` enum('Yes','No') NOT NULL default 'No',
  PRIMARY KEY  (`SAGE_Library_ID`),
  KEY `lib_id` (`FK_Sequencing_Library__ID`),
  KEY `FKAnchoring_Enzyme__ID` (`FKAnchoring_Enzyme__ID`),
  KEY `FKTagging_Enzyme__ID` (`FKTagging_Enzyme__ID`),
  KEY `FKInsertSite_Enzyme__ID` (`FKInsertSite_Enzyme__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

