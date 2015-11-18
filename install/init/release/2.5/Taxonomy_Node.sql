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
-- Table structure for table `Taxonomy_Node`
--

DROP TABLE IF EXISTS `Taxonomy_Node`;
CREATE TABLE `Taxonomy_Node` (
  `FK_Taxonomy__ID` int(11) NOT NULL default '0',
  `FKParent_Taxonomy__ID` int(11) default NULL,
  `Rank` varchar(40) default NULL,
  `embl_code` varchar(40) default NULL,
  `FK_Taxonomy_Division__ID` int(11) default NULL,
  `Inherited_Division` tinyint(4) default NULL,
  `FK_Genetic_Code__ID` int(11) default NULL,
  `Inherited_Genetic_Code` tinyint(4) default NULL,
  `FKMitochondrial_Genetic_Code__ID` int(11) default NULL,
  `Inherited_Mitochondrial_Genetic_Code` tinyint(4) default NULL,
  `GenBank_Hidden` tinyint(4) default NULL,
  `Hidden_Subtree_Root_Flag` tinyint(4) default NULL,
  `Taxonomy_Comments` text,
  KEY `Tax_ID` (`FK_Taxonomy__ID`),
  KEY `FKParent_Tax__ID` (`FKParent_Taxonomy__ID`),
  KEY `Mito_Genetic_Code_ID` (`FKMitochondrial_Genetic_Code__ID`),
  KEY `FK_Genetic_Code__ID` (`FK_Genetic_Code__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

