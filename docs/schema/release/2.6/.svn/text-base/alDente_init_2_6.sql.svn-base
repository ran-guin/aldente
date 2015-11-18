-- MySQL dump 10.9
--
-- Host: limsdev02    Database: alDente_init_2_5
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
-- Table structure for table `Account`
--

DROP TABLE IF EXISTS `Account`;
CREATE TABLE `Account` (
  `Account_ID` int(11) NOT NULL default '0',
  `Account_Description` text,
  `Account_Type` text,
  `Account_Name` text,
  `Account_Dept` enum('Orders','Admin') default NULL,
  PRIMARY KEY  (`Account_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Account`
--


/*!40000 ALTER TABLE `Account` DISABLE KEYS */;
LOCK TABLES `Account` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Account` ENABLE KEYS */;

--
-- Table structure for table `Agilent_Assay`
--

DROP TABLE IF EXISTS `Agilent_Assay`;
CREATE TABLE `Agilent_Assay` (
  `Agilent_Assay_ID` int(11) NOT NULL auto_increment,
  `Agilent_Assay_Name` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`Agilent_Assay_ID`),
  KEY `name` (`Agilent_Assay_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Agilent_Assay`
--


/*!40000 ALTER TABLE `Agilent_Assay` DISABLE KEYS */;
LOCK TABLES `Agilent_Assay` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Agilent_Assay` ENABLE KEYS */;

--
-- Table structure for table `Antibiotic`
--

DROP TABLE IF EXISTS `Antibiotic`;
CREATE TABLE `Antibiotic` (
  `Antibiotic_ID` int(10) unsigned NOT NULL auto_increment,
  `Antibiotic_Name` varchar(40) default NULL,
  PRIMARY KEY  (`Antibiotic_ID`),
  UNIQUE KEY `Antibiotic_Name` (`Antibiotic_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Antibiotic`
--


/*!40000 ALTER TABLE `Antibiotic` DISABLE KEYS */;
LOCK TABLES `Antibiotic` WRITE;
INSERT INTO `Antibiotic` VALUES (5,' no antibiotic'),(1,'Ampicillin'),(2,'Chloramphenicol'),(4,'Kanamycin');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Antibiotic` ENABLE KEYS */;

--
-- Table structure for table `Array`
--

DROP TABLE IF EXISTS `Array`;
CREATE TABLE `Array` (
  `Array_ID` int(11) NOT NULL auto_increment,
  `FK_Microarray__ID` int(11) default NULL,
  `FK_Plate__ID` int(11) default NULL,
  PRIMARY KEY  (`Array_ID`),
  KEY `microarray_id` (`FK_Microarray__ID`),
  KEY `plate_id` (`FK_Plate__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Array`
--


/*!40000 ALTER TABLE `Array` DISABLE KEYS */;
LOCK TABLES `Array` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Array` ENABLE KEYS */;

--
-- Table structure for table `Attribute`
--

DROP TABLE IF EXISTS `Attribute`;
CREATE TABLE `Attribute` (
  `Attribute_ID` int(11) NOT NULL auto_increment,
  `Attribute_Name` varchar(40) default NULL,
  `Attribute_Format` varchar(40) default NULL,
  `Attribute_Type` varchar(40) default NULL,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `Inherited` enum('Yes','No') NOT NULL default 'No',
  `Attribute_Class` varchar(40) default NULL,
  PRIMARY KEY  (`Attribute_ID`),
  UNIQUE KEY `Attribute_Key` (`Attribute_Name`,`Attribute_Class`),
  KEY `grp` (`FK_Grp__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Attribute`
--


/*!40000 ALTER TABLE `Attribute` DISABLE KEYS */;
LOCK TABLES `Attribute` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Attribute` ENABLE KEYS */;

--
-- Table structure for table `Band`
--

DROP TABLE IF EXISTS `Band`;
CREATE TABLE `Band` (
  `Band_ID` int(11) unsigned NOT NULL auto_increment,
  `Band_Size` int(10) unsigned default NULL,
  `Band_Mobility` float(6,1) default NULL,
  `Band_Number` int(4) unsigned default NULL,
  `FKParent_Band__ID` int(11) default NULL,
  `FK_Lane__ID` int(11) unsigned default NULL,
  `Band_Intensity` enum('Unspecified','Weak','Medium','Strong') default NULL,
  `Band_Type` enum('Insert','Vector') default NULL,
  PRIMARY KEY  (`Band_ID`),
  KEY `FKParent_Band__ID` (`FKParent_Band__ID`),
  KEY `lane` (`FK_Lane__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Band`
--


/*!40000 ALTER TABLE `Band` DISABLE KEYS */;
LOCK TABLES `Band` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Band` ENABLE KEYS */;

--
-- Table structure for table `Barcode_Label`
--

DROP TABLE IF EXISTS `Barcode_Label`;
CREATE TABLE `Barcode_Label` (
  `Barcode_Label_ID` int(11) NOT NULL auto_increment,
  `Barcode_Label_Name` char(40) default NULL,
  `Label_Height` float default NULL,
  `Label_Width` float default NULL,
  `Zero_X` int(11) default NULL,
  `Zero_Y` int(11) default NULL,
  `Top` int(11) default NULL,
  `FK_Setting__ID` int(11) NOT NULL default '0',
  `Label_Descriptive_Name` char(40) NOT NULL default '',
  `Barcode_Label_Type` enum('plate','mulplate','solution','equipment','source','employee','microarray') default NULL,
  `FK_Label_Format__ID` int(11) NOT NULL default '0',
  `Barcode_Label_Status` enum('Inactive','Active') NOT NULL default 'Active',
  PRIMARY KEY  (`Barcode_Label_ID`),
  KEY `setting` (`FK_Setting__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Barcode_Label`
--


/*!40000 ALTER TABLE `Barcode_Label` DISABLE KEYS */;
LOCK TABLES `Barcode_Label` WRITE;
INSERT INTO `Barcode_Label` VALUES (1,'seqnightcult',0.75,2.25,15,25,15,1,'1D Large Plate Labels','plate',1,'Active'),(2,'seqnightcult_s',0.25,2.25,5,15,15,3,'1D Small Plate Labels','plate',3,'Active'),(3,'seqnightcult_smult',0.25,2.25,5,15,15,3,'1D Small MUL Plate Labels','mulplate',3,'Active'),(5,'seqnightcult_mult',0.75,2.25,15,25,15,1,'1D Large MUL Plate Labels','mulplate',1,'Active'),(6,'ge_tube_barcode_2D',0.6,1.7,25,25,15,4,'2D Tube Labels','plate',4,'Active'),(7,'tube_solution_2D',0.6,1.7,25,25,15,1,'2D Tube Solution Labels','solution',1,'Active'),(8,'solution',0.75,2.25,15,25,15,1,'1D Large Solution/Box/Kit Labels','solution',1,'Active'),(9,'solution_small',0.25,2.25,5,15,15,3,'1D Small Solution Labels','solution',3,'Active'),(10,'equip_label',0.75,2.25,15,25,15,1,'1D Equipment Labels','equipment',1,'Active'),(15,'agar_plate',0.75,2.25,15,25,15,1,'1D Large Agar Labels','plate',1,'Active'),(16,'chemistry_calc',1,2.25,15,15,15,2,'1D Chemistry Label','',2,'Active'),(17,'src_plate',0.25,2.25,5,15,15,3,'1D Source Label','source',3,'Active'),(18,'src_tube',0.6,1.7,25,25,15,4,'2D Source Label','source',4,'Active'),(19,'agar_plate_s',0.25,2.25,5,15,15,3,'1D Small Agar Label','plate',3,'Active'),(20,'proc_med',0.75,2.25,5,15,15,1,'Large Procedure Label','',1,'Active'),(21,'label1',0.75,2.25,25,25,15,1,'Simple Large Label','',1,'Active'),(22,'label2',0.25,2.25,25,25,15,3,'Simple Small Label','',3,'Active'),(23,'employee',0.75,2.25,15,25,15,1,'Employee Barcode','employee',1,'Active'),(24,'barcode2',0.75,2.25,15,15,15,1,'1D Large Plain Label','',1,'Active'),(25,'laser',11.5,8,0,0,0,0,'Plain Paper Label','',0,'Active'),(26,'plain_tube',0.6,1.7,10,0,45,4,'Simple Tube Label','',4,'Active'),(27,'custom_large',0.75,2.25,25,25,15,1,'Large Custom Label','',1,'Active'),(28,'equip_small',0.25,2.25,15,15,15,3,'1D Small Equipment Labels','equipment',3,'Active'),(29,'gelpour_barcode_1D',0.75,2.25,0,0,0,1,'Gel Run Barcode Label','',1,'Active'),(30,'run_barcode_1D',0.75,2.25,0,0,0,1,'Run Barcode Label','',1,'Active'),(31,'src_no_barcode',0,0,0,0,0,0,'No Barcode','source',0,'Active'),(32,'microarray',0.75,2.25,10,10,10,1,'1D Large Microarray Label','microarray',1,'Active'),(33,'custom_2D_tube',0.75,1.7,25,25,15,4,'2D simple tube labels','plate',4,'Active');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Barcode_Label` ENABLE KEYS */;

--
-- Table structure for table `BioanalyzerAnalysis`
--

DROP TABLE IF EXISTS `BioanalyzerAnalysis`;
CREATE TABLE `BioanalyzerAnalysis` (
  `BioanalyzerAnalysis_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `File_Name` text,
  PRIMARY KEY  (`BioanalyzerAnalysis_ID`),
  KEY `FK_Run__ID` (`FK_Run__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `BioanalyzerAnalysis`
--


/*!40000 ALTER TABLE `BioanalyzerAnalysis` DISABLE KEYS */;
LOCK TABLES `BioanalyzerAnalysis` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `BioanalyzerAnalysis` ENABLE KEYS */;

--
-- Table structure for table `BioanalyzerRead`
--

DROP TABLE IF EXISTS `BioanalyzerRead`;
CREATE TABLE `BioanalyzerRead` (
  `BioanalyzerRead_ID` int(11) NOT NULL auto_increment,
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `FK_Run__ID` int(11) NOT NULL default '0',
  `Well` varchar(4) default NULL,
  `Well_Status` enum('Empty','OK','Problematic','Unused') default NULL,
  `Well_Category` enum('Sample','Ladder') default NULL,
  `RNA_DNA_Concentration` float default NULL,
  `RNA_DNA_Concentration_Unit` varchar(15) default NULL,
  `RNA_DNA_Integrity_Number` float default NULL,
  `Read_Error` enum('low concentration','low RNA Integrity Number') default NULL,
  `Read_Warning` enum('low concentration','low RNA Integrity Number') default NULL,
  `Sample_Comment` text,
  PRIMARY KEY  (`BioanalyzerRead_ID`),
  KEY `FK_Run__ID` (`FK_Run__ID`),
  KEY `FK_Sample__ID` (`FK_Sample__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `BioanalyzerRead`
--


/*!40000 ALTER TABLE `BioanalyzerRead` DISABLE KEYS */;
LOCK TABLES `BioanalyzerRead` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `BioanalyzerRead` ENABLE KEYS */;

--
-- Table structure for table `BioanalyzerRun`
--

DROP TABLE IF EXISTS `BioanalyzerRun`;
CREATE TABLE `BioanalyzerRun` (
  `BioanalyzerRun_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `FKScanner_Equipment__ID` int(11) default NULL,
  `Dilution_Factor` varchar(20) NOT NULL default '1',
  `Invoiced` enum('No','Yes') default 'No',
  PRIMARY KEY  (`BioanalyzerRun_ID`),
  KEY `FK_Run__ID` (`FK_Run__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `BioanalyzerRun`
--


/*!40000 ALTER TABLE `BioanalyzerRun` DISABLE KEYS */;
LOCK TABLES `BioanalyzerRun` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `BioanalyzerRun` ENABLE KEYS */;

--
-- Table structure for table `Box`
--

DROP TABLE IF EXISTS `Box`;
CREATE TABLE `Box` (
  `Box_ID` int(11) NOT NULL auto_increment,
  `Box_Opened` date default NULL,
  `FK_Rack__ID` int(11) default NULL,
  `Box_Number` int(11) default NULL,
  `Box_Number_in_Batch` int(11) default NULL,
  `FK_Stock__ID` int(11) default NULL,
  `FKParent_Box__ID` int(11) default NULL,
  `Box_Serial_Number` text,
  `Box_Type` enum('Box','Kit','Supplies') NOT NULL default 'Box',
  `Box_Expiry` date default NULL,
  `Box_Status` enum('Unopened','Open','Expired','Inactive') default 'Unopened',
  PRIMARY KEY  (`Box_ID`),
  KEY `stock` (`FK_Stock__ID`),
  KEY `FK_Rack__ID` (`FK_Rack__ID`),
  KEY `FKParent_Box__ID` (`FKParent_Box__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Box`
--


/*!40000 ALTER TABLE `Box` DISABLE KEYS */;
LOCK TABLES `Box` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Box` ENABLE KEYS */;

--
-- Table structure for table `Branch`
--

DROP TABLE IF EXISTS `Branch`;
CREATE TABLE `Branch` (
  `Branch_Code` varchar(5) NOT NULL default '',
  `Branch_Description` text NOT NULL,
  `Object_ID` int(11) NOT NULL default '0',
  `FK_Object_Class__ID` int(11) NOT NULL default '0',
  `FKParent_Branch__Code` varchar(5) default NULL,
  `FK_Pipeline__ID` int(11) default NULL,
  `Branch_Status` enum('Active','Inactive') default 'Active',
  PRIMARY KEY  (`Branch_Code`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Branch`
--


/*!40000 ALTER TABLE `Branch` DISABLE KEYS */;
LOCK TABLES `Branch` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Branch` ENABLE KEYS */;

--
-- Table structure for table `Branch_Condition`
--

DROP TABLE IF EXISTS `Branch_Condition`;
CREATE TABLE `Branch_Condition` (
  `Branch_Condition_ID` int(11) NOT NULL auto_increment,
  `FK_Branch__Code` varchar(5) NOT NULL default '',
  `FK_Object_Class__ID` int(11) NOT NULL default '0',
  `Object_ID` int(11) NOT NULL default '0',
  `FK_Pipeline__ID` int(11) default NULL,
  `FKParent_Branch__Code` varchar(5) default NULL,
  `Branch_Condition_Status` enum('Active','Inactive') default NULL,
  PRIMARY KEY  (`Branch_Condition_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Branch_Condition`
--


/*!40000 ALTER TABLE `Branch_Condition` DISABLE KEYS */;
LOCK TABLES `Branch_Condition` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Branch_Condition` ENABLE KEYS */;

--
-- Table structure for table `Change_History`
--

DROP TABLE IF EXISTS `Change_History`;
CREATE TABLE `Change_History` (
  `Change_History_ID` int(11) NOT NULL auto_increment,
  `FK_DBField__ID` int(11) NOT NULL default '0',
  `Old_Value` varchar(255) default NULL,
  `New_Value` varchar(255) default NULL,
  `FK_Employee__ID` int(11) NOT NULL default '0',
  `Modified_Date` datetime NOT NULL default '0000-00-00 00:00:00',
  `Record_ID` varchar(40) NOT NULL default '',
  `Comment` text,
  PRIMARY KEY  (`Change_History_ID`),
  KEY `FK_DBField__ID` (`FK_DBField__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Change_History`
--


/*!40000 ALTER TABLE `Change_History` DISABLE KEYS */;
LOCK TABLES `Change_History` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Change_History` ENABLE KEYS */;

--
-- Table structure for table `Chemistry_Code`
--

DROP TABLE IF EXISTS `Chemistry_Code`;
CREATE TABLE `Chemistry_Code` (
  `Chemistry_Code_Name` varchar(5) NOT NULL default '',
  `Chemistry_Description` text NOT NULL,
  `FK_Primer__Name` varchar(40) default NULL,
  `Terminator` enum('None','ET','Big Dye') default NULL,
  `Dye` enum('N/A','term') default NULL,
  PRIMARY KEY  (`Chemistry_Code_Name`),
  UNIQUE KEY `code` (`FK_Primer__Name`,`Terminator`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Chemistry_Code`
--


/*!40000 ALTER TABLE `Chemistry_Code` DISABLE KEYS */;
LOCK TABLES `Chemistry_Code` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Chemistry_Code` ENABLE KEYS */;

--
-- Table structure for table `Child_Ordered_Procedure`
--

DROP TABLE IF EXISTS `Child_Ordered_Procedure`;
CREATE TABLE `Child_Ordered_Procedure` (
  `Child_Ordered_Procedure_ID` int(11) NOT NULL auto_increment,
  `FKParent_Ordered_Procedure__ID` int(11) NOT NULL default '0',
  `FKChild_Ordered_Procedure__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Child_Ordered_Procedure_ID`),
  KEY `FKParent_Procedure__ID` (`FKParent_Ordered_Procedure__ID`),
  KEY `FKChild_Procedure__ID` (`FKChild_Ordered_Procedure__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Child_Ordered_Procedure`
--


/*!40000 ALTER TABLE `Child_Ordered_Procedure` DISABLE KEYS */;
LOCK TABLES `Child_Ordered_Procedure` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Child_Ordered_Procedure` ENABLE KEYS */;

--
-- Table structure for table `Clone_Alias`
--

DROP TABLE IF EXISTS `Clone_Alias`;
CREATE TABLE `Clone_Alias` (
  `Clone_Alias_ID` int(11) NOT NULL auto_increment,
  `FK_Clone_Sample__ID` int(11) NOT NULL default '0',
  `FKSource_Organization__ID` int(11) default NULL,
  `Source` char(80) default NULL,
  `Alias` char(80) default NULL,
  `Alias_Type` enum('Primary','Secondary') default NULL,
  PRIMARY KEY  (`Clone_Alias_ID`),
  KEY `name` (`Alias`),
  KEY `source` (`Source`),
  KEY `organization` (`FKSource_Organization__ID`),
  KEY `clone` (`FK_Clone_Sample__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Clone_Alias`
--


/*!40000 ALTER TABLE `Clone_Alias` DISABLE KEYS */;
LOCK TABLES `Clone_Alias` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Clone_Alias` ENABLE KEYS */;

--
-- Table structure for table `Clone_Details`
--

DROP TABLE IF EXISTS `Clone_Details`;
CREATE TABLE `Clone_Details` (
  `Clone_Details_ID` int(11) NOT NULL auto_increment,
  `FK_Clone_Sample__ID` int(11) NOT NULL default '0',
  `Clone_Comments` text,
  `PolyA_Tail` int(11) default NULL,
  `Chimerism_check_with_ESTs` enum('no','yes','warning','single EST match') default NULL,
  `Score` int(11) default NULL,
  `5Prime_found` tinyint(4) default NULL,
  `Genes_Protein` text,
  `Incyte_Match` int(11) default NULL,
  `PolyA_Signal` int(11) default NULL,
  `Clone_Vector` text,
  `Genbank_ID` text,
  `Lukas_Passed` int(11) default NULL,
  `Size_Estimate` int(11) default NULL,
  `Size_StdDev` int(11) default NULL,
  PRIMARY KEY  (`Clone_Details_ID`),
  UNIQUE KEY `clone` (`FK_Clone_Sample__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Clone_Details`
--


/*!40000 ALTER TABLE `Clone_Details` DISABLE KEYS */;
LOCK TABLES `Clone_Details` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Clone_Details` ENABLE KEYS */;

--
-- Table structure for table `Clone_Sample`
--

DROP TABLE IF EXISTS `Clone_Sample`;
CREATE TABLE `Clone_Sample` (
  `Clone_Sample_ID` int(11) NOT NULL auto_increment,
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `FK_Library__Name` char(5) default NULL,
  `Library_Plate_Number` int(11) default NULL,
  `Original_Quadrant` char(2) default NULL,
  `Original_Well` char(3) default NULL,
  `FKOriginal_Plate__ID` int(11) default NULL,
  PRIMARY KEY  (`Clone_Sample_ID`),
  KEY `sample` (`FK_Sample__ID`),
  KEY `plate` (`FKOriginal_Plate__ID`,`Original_Well`),
  KEY `lib` (`FK_Library__Name`,`Library_Plate_Number`,`Original_Quadrant`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Clone_Sample`
--


/*!40000 ALTER TABLE `Clone_Sample` DISABLE KEYS */;
LOCK TABLES `Clone_Sample` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Clone_Sample` ENABLE KEYS */;

--
-- Table structure for table `Clone_Sequence`
--

DROP TABLE IF EXISTS `Clone_Sequence`;
CREATE TABLE `Clone_Sequence` (
  `FK_Run__ID` int(11) default NULL,
  `Sequence` text NOT NULL,
  `Sequence_Scores` blob NOT NULL,
  `Quality_Left` smallint(6) NOT NULL default '-2',
  `Vector_Quality` smallint(6) NOT NULL default '-2',
  `Vector_Total` smallint(6) NOT NULL default '-2',
  `Well` char(3) NOT NULL default '',
  `Phred_Histogram` varchar(200) NOT NULL default '',
  `Vector_Left` smallint(6) NOT NULL default '-2',
  `Vector_Right` smallint(6) NOT NULL default '-2',
  `Sequence_Length` smallint(6) NOT NULL default '-2',
  `Quality_Histogram` varchar(200) NOT NULL default '',
  `Quality_Length` smallint(6) NOT NULL default '-2',
  `Clone_Sequence_Comments` varchar(255) NOT NULL default '',
  `FK_Note__ID` tinyint(4) default NULL,
  `Growth` enum('OK','Slow Grow','No Grow','Unused','Empty','Problematic') default NULL,
  `Test_Run_Flag` tinyint(4) NOT NULL default '0',
  `Capillary` char(3) NOT NULL default '',
  `Clone_Sequence_ID` int(11) NOT NULL auto_increment,
  `Read_Error` enum('trace data missing','Empty Read','Analysis Aborted') default NULL,
  `Read_Warning` set('Vector Only','Vector Segment','Recurring String','Contamination','Poor Quality') default NULL,
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `Peak_Area_Ratio` float(6,5) NOT NULL default '0.00000',
  PRIMARY KEY  (`Clone_Sequence_ID`),
  KEY `growth` (`Growth`),
  KEY `warnings` (`FK_Note__ID`),
  KEY `warning` (`Read_Warning`),
  KEY `clone` (`FK_Sample__ID`),
  KEY `seq_read` (`FK_Run__ID`,`Well`),
  KEY `length` (`Sequence_Length`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=4294967295 AVG_ROW_LENGTH=2448;

--
-- Dumping data for table `Clone_Sequence`
--


/*!40000 ALTER TABLE `Clone_Sequence` DISABLE KEYS */;
LOCK TABLES `Clone_Sequence` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Clone_Sequence` ENABLE KEYS */;

--
-- Table structure for table `Clone_Source`
--

DROP TABLE IF EXISTS `Clone_Source`;
CREATE TABLE `Clone_Source` (
  `Clone_Source_ID` int(11) NOT NULL auto_increment,
  `Source_Description` varchar(40) default NULL,
  `FK_Clone_Sample__ID` int(11) NOT NULL default '0',
  `FK_Plate__ID` int(11) default NULL,
  `clone_quadrant` enum('','a','b','c','d') default NULL,
  `Clone_Well` char(3) default NULL,
  `Well_384` char(3) default NULL,
  `FKSource_Organization__ID` int(11) default NULL,
  `Source_Name` varchar(40) default NULL,
  `Source_Comments` text,
  `Source_Library_ID` varchar(40) default NULL,
  `Source_Collection` varchar(40) default NULL,
  `Source_Library_Name` varchar(40) default NULL,
  `Source_Row` varchar(4) NOT NULL default '',
  `Source_Col` varchar(4) NOT NULL default '',
  `Source_5Prime_Site` text,
  `Source_Plate` int(11) default NULL,
  `Source_3Prime_Site` text,
  `Source_Vector` varchar(40) default NULL,
  `Source_Score` int(11) default NULL,
  `3prime_tag` varchar(40) default NULL,
  `5prime_tag` varchar(40) default NULL,
  `Source_Clone_Name` varchar(40) default NULL,
  `Source_Clone_Name_Type` varchar(40) default NULL,
  PRIMARY KEY  (`Clone_Source_ID`),
  KEY `clonesource_plate` (`FK_Plate__ID`),
  KEY `clonesource_clone` (`FK_Clone_Sample__ID`),
  KEY `clone` (`FK_Clone_Sample__ID`),
  KEY `name` (`Source_Name`),
  KEY `library` (`Source_Library_Name`),
  KEY `plate` (`Source_Plate`),
  KEY `well` (`Source_Collection`,`Source_Plate`,`Source_Row`,`Source_Col`),
  KEY `source_org_id` (`FKSource_Organization__ID`),
  KEY `clone_name` (`Source_Clone_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Clone_Source`
--


/*!40000 ALTER TABLE `Clone_Source` DISABLE KEYS */;
LOCK TABLES `Clone_Source` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Clone_Source` ENABLE KEYS */;

--
-- Table structure for table `Collaboration`
--

DROP TABLE IF EXISTS `Collaboration`;
CREATE TABLE `Collaboration` (
  `FK_Project__ID` int(11) default NULL,
  `Collaboration_ID` int(11) NOT NULL auto_increment,
  `FK_Contact__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Collaboration_ID`),
  KEY `FK_Project__ID` (`FK_Project__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Collaboration`
--


/*!40000 ALTER TABLE `Collaboration` DISABLE KEYS */;
LOCK TABLES `Collaboration` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Collaboration` ENABLE KEYS */;

--
-- Table structure for table `Communication`
--

DROP TABLE IF EXISTS `Communication`;
CREATE TABLE `Communication` (
  `Communication_ID` int(11) NOT NULL auto_increment,
  `FK_Contact__ID` int(11) default NULL,
  `FK_Organization__ID` int(11) default NULL,
  `Communication_Description` text,
  `Communication_Date` date default NULL,
  `FK_Employee__ID` int(11) default NULL,
  PRIMARY KEY  (`Communication_ID`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`),
  KEY `FK_Organization__ID` (`FK_Organization__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Communication`
--


/*!40000 ALTER TABLE `Communication` DISABLE KEYS */;
LOCK TABLES `Communication` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Communication` ENABLE KEYS */;

--
-- Table structure for table `ConcentrationRun`
--

DROP TABLE IF EXISTS `ConcentrationRun`;
CREATE TABLE `ConcentrationRun` (
  `ConcentrationRun_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_Plate__ID` int(10) unsigned NOT NULL default '0',
  `FK_Equipment__ID` int(10) unsigned NOT NULL default '0',
  `DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `CalibrationFunction` text NOT NULL,
  PRIMARY KEY  (`ConcentrationRun_ID`),
  KEY `plate` (`FK_Plate__ID`),
  KEY `equipment_id` (`FK_Equipment__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `ConcentrationRun`
--


/*!40000 ALTER TABLE `ConcentrationRun` DISABLE KEYS */;
LOCK TABLES `ConcentrationRun` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `ConcentrationRun` ENABLE KEYS */;

--
-- Table structure for table `Concentrations`
--

DROP TABLE IF EXISTS `Concentrations`;
CREATE TABLE `Concentrations` (
  `Concentration_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_ConcentrationRun__ID` int(10) unsigned NOT NULL default '0',
  `Well` char(3) default NULL,
  `Measurement` varchar(10) default NULL,
  `Units` varchar(15) default NULL,
  `Concentration` varchar(10) default NULL,
  `FK_Sample__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Concentration_ID`),
  KEY `Measurement` (`Measurement`),
  KEY `Concentration` (`Concentration`),
  KEY `sample_id` (`FK_Sample__ID`),
  KEY `FK_ConcentrationRun__ID` (`FK_ConcentrationRun__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Concentrations`
--


/*!40000 ALTER TABLE `Concentrations` DISABLE KEYS */;
LOCK TABLES `Concentrations` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Concentrations` ENABLE KEYS */;

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

--
-- Dumping data for table `Contact`
--


/*!40000 ALTER TABLE `Contact` DISABLE KEYS */;
LOCK TABLES `Contact` WRITE;
INSERT INTO `Contact` VALUES (3,'Jim Crawford','Big Wig',2,'','jim.crawford@am.apbiotech.com','Collaborator','Active','','','','','','','','','','','','','','','','','','','','','','','','','','','','','0000-00-00','0000-00-00','','');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Contact` ENABLE KEYS */;

--
-- Table structure for table `Contaminant`
--

DROP TABLE IF EXISTS `Contaminant`;
CREATE TABLE `Contaminant` (
  `Contaminant_ID` int(11) NOT NULL auto_increment,
  `Well` char(3) default NULL,
  `FK_Run__ID` int(11) default NULL,
  `Detection_Date` date default NULL,
  `E_value` float unsigned default NULL,
  `Score` int(11) default NULL,
  `FK_Contamination__ID` int(11) default NULL,
  PRIMARY KEY  (`Contaminant_ID`),
  KEY `run` (`FK_Run__ID`),
  KEY `FK_Contamination__ID` (`FK_Contamination__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Contaminant`
--


/*!40000 ALTER TABLE `Contaminant` DISABLE KEYS */;
LOCK TABLES `Contaminant` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Contaminant` ENABLE KEYS */;

--
-- Table structure for table `Contamination`
--

DROP TABLE IF EXISTS `Contamination`;
CREATE TABLE `Contamination` (
  `Contamination_ID` int(11) NOT NULL auto_increment,
  `Contamination_Name` text,
  `Contamination_Description` text,
  `Contamination_Alias` text,
  PRIMARY KEY  (`Contamination_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Contamination`
--


/*!40000 ALTER TABLE `Contamination` DISABLE KEYS */;
LOCK TABLES `Contamination` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Contamination` ENABLE KEYS */;

--
-- Table structure for table `Cross_Match`
--

DROP TABLE IF EXISTS `Cross_Match`;
CREATE TABLE `Cross_Match` (
  `FK_Run__ID` int(11) default NULL,
  `Well` char(3) default NULL,
  `Match_Name` char(80) default NULL,
  `Match_Start` int(11) default NULL,
  `Match_Stop` int(11) default NULL,
  `Cross_Match_Date` date default NULL,
  `Cross_Match_ID` int(11) NOT NULL auto_increment,
  `Match_Direction` enum('','C') default NULL,
  PRIMARY KEY  (`Cross_Match_ID`),
  KEY `well` (`FK_Run__ID`,`Well`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Cross_Match`
--


/*!40000 ALTER TABLE `Cross_Match` DISABLE KEYS */;
LOCK TABLES `Cross_Match` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Cross_Match` ENABLE KEYS */;

--
-- Table structure for table `DBField`
--

DROP TABLE IF EXISTS `DBField`;
CREATE TABLE `DBField` (
  `DBField_ID` int(11) NOT NULL auto_increment,
  `Field_Description` text NOT NULL,
  `Field_Table` text NOT NULL,
  `Prompt` varchar(255) NOT NULL default '',
  `Field_Alias` varchar(255) NOT NULL default '',
  `Field_Options` set('Hidden','Mandatory','Primary','Unique','NewLink','ViewLink','ListLink','Searchable','Obsolete') default NULL,
  `Field_Reference` varchar(255) NOT NULL default '',
  `Field_Order` int(11) NOT NULL default '0',
  `Field_Name` varchar(255) NOT NULL default '',
  `Field_Type` text NOT NULL,
  `Field_Index` varchar(255) NOT NULL default '',
  `NULL_ok` enum('NO','YES') NOT NULL default 'YES',
  `Field_Default` varchar(255) NOT NULL default '',
  `Field_Size` tinyint(4) default '20',
  `Field_Format` varchar(80) default NULL,
  `FK_DBTable__ID` int(11) default NULL,
  `Foreign_Key` varchar(255) default NULL,
  `DBField_Notes` text,
  `Editable` enum('yes','no') default 'yes',
  `Tracked` enum('yes','no') default 'no',
  `Field_Scope` enum('Core','Optional','Custom') default 'Custom',
  PRIMARY KEY  (`DBField_ID`),
  UNIQUE KEY `tblfld` (`FK_DBTable__ID`,`Field_Name`),
  UNIQUE KEY `field_name` (`Field_Name`,`FK_DBTable__ID`),
  KEY `fld` (`Field_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `DBField`
--


/*!40000 ALTER TABLE `DBField` DISABLE KEYS */;
LOCK TABLES `DBField` WRITE;
INSERT INTO `DBField` VALUES (620,'','Account','Account ID','ID','Primary','concat(Account_ID, \' (\',Account_Name,\')\')',1,'Account_ID','int(11)','PRI','NO','0',20,'',1,'','','yes','no',''),(621,'','Account','Description','Description','','',2,'Account_Description','text','','YES','',20,'',1,'','','yes','no',''),(622,'','Account','Type','Type','','',3,'Account_Type','text','','YES','',20,'',1,'','','yes','no',''),(623,'','Account','Name','Name','','',4,'Account_Name','text','','YES','',20,'',1,'','','yes','no',''),(624,'','Account','Dept','Dept','','',5,'Account_Dept','enum(\'Orders\',\'Admin\')','','YES','',20,'',1,'','','yes','no',''),(625,'','Barcode_Label','Barcode Label ID','ID','Primary','Label_Descriptive_Name',1,'Barcode_Label_ID','int(11)','PRI','NO','',20,'',2,'','','yes','no',''),(626,'','Barcode_Label','Name','Name','','',2,'Barcode_Label_Name','char(40)','','YES','',20,'',2,'','','yes','no',''),(627,'','Barcode_Label','Label Height','Label_Height','','',3,'Label_Height','float','','YES','',20,'',2,'','','yes','no',''),(628,'','Barcode_Label','Label Width','Label_Width','','',4,'Label_Width','float','','YES','',20,'',2,'','','yes','no',''),(629,'','Barcode_Label','Zero X','Zero_X','','',5,'Zero_X','int(11)','','YES','',20,'',2,'','','yes','no',''),(630,'','Barcode_Label','Zero Y','Zero_Y','','',6,'Zero_Y','int(11)','','YES','',20,'',2,'','','yes','no',''),(631,'','Barcode_Label','Top','Top','','',7,'Top','int(11)','','YES','',20,'',2,'','','yes','no',''),(632,'','Box','Number','Number','','',1,'Box_Number','int(11)','','YES','',20,'',3,'','','yes','no',''),(633,'','Box','Number in Batch','Number_in_Batch','','',2,'Box_Number_in_Batch','int(11)','','YES','',20,'',3,'','','yes','no',''),(634,'','Box','Stock','Stock__ID','','Stock_ID',3,'FK_Stock__ID','int(11)','MUL','YES','',20,'',3,'Stock.Stock_ID','','yes','no',''),(635,'','Box','Parent Box','Parent_Box__ID','','Box_ID',4,'FKParent_Box__ID','int(11)','MUL','YES','',20,'',3,'Box.Box_ID','','yes','no',''),(636,'Rack ID and an optional slot name','Box','Rack','Rack__ID','Searchable','Rack_ID',5,'FK_Rack__ID','int(11)','MUL','YES','<DEFAULT_LOCATION>',20,'',3,'Rack.Rack_ID','','yes','no',''),(637,'','Box','Serial Number','Serial_Number','','',6,'Box_Serial_Number','text','','YES','',20,'',3,'','','yes','no',''),(638,'','Box','Box ID','ID','Primary','concat(\'Box\',Box_ID,\': \',Box_Number,\'/\',Box_Number_in_Batch)',7,'Box_ID','int(11)','PRI','NO','',20,'',3,'','','yes','no',''),(639,'','Box','Opened','Opened','Hidden','',8,'Box_Opened','date','','YES','',20,'',3,'','','yes','no',''),(640,'','Box','Type','Type','Hidden','',9,'Box_Type','enum(\'Box\',\'Kit\',\'Supplies\')','','NO','Box',20,'',3,'','','yes','no',''),(641,'Chemistry Code Name - limit to 4 characters (eg. B7)','Chemistry_Code','Name','Name','Mandatory,Primary,ViewLink','',1,'Chemistry_Code_Name','varchar(5)','PRI','NO','',20,'^\'?[a-zA-Z0-9]{1,4}\'?$',4,'','','yes','no',''),(642,'','Chemistry_Code','Chemistry Description','Chemistry_Description','','',2,'Chemistry_Description','text','','NO','',20,'',4,'','','yes','no',''),(643,'must match EXACTLY with defined Primer name','Chemistry_Code','Primer','Primer__Name','NewLink','Primer_Name',3,'FK_Primer__Name','varchar(40)','MUL','YES','',20,'',4,'Primer.Primer_Name','','yes','no',''),(644,'','Chemistry_Code','Terminator','Terminator','','',4,'Terminator','enum(\'None\',\'ET\',\'Big Dye\')','','YES','',20,'',4,'','','yes','no',''),(645,'','Chemistry_Code','Dye','Dye','','',5,'Dye','enum(\'N/A\',\'term\')','','YES','',20,'',4,'','','yes','no',''),(689,'','DBTable','DBTable ID','ID','Primary','DBTable_Name',1,'DBTable_ID','int(11)','PRI','NO','',20,'',28,'','','yes','no',''),(690,'','DBTable','Name','Name','','',2,'DBTable_Name','varchar(80)','UNI','NO','',20,'^.{0,80}$',28,'','','yes','no',''),(691,'','DBTable','Description','Description','','',3,'DBTable_Description','text','','YES','',20,'',28,'','','yes','no',''),(692,'','DBTable','Status','Status','','',4,'DBTable_Status','text','','YES','',20,'',28,'','','yes','no',''),(693,'','DBTable','Status Last Updated','Status_Last_Updated','','',5,'Status_Last_Updated','datetime','','NO','0000-00-00 00:00:00',20,'',28,'','','yes','no',''),(694,'','Employee','Password','Password','Hidden','',11,'Password','varchar(80)','','YES','78a302dd267f6044',20,'^.{0,80}$',30,'','','yes','no',''),(695,'','LibraryPrimer','Clones Estimate','Clones_Estimate','','',4,'Clones_Estimate','int(11)','','NO','0',20,'',41,'','','yes','no',''),(696,'','LibraryPrimer','TagsRequested','TagsRequested','','',5,'TagsRequested','int(11)','','NO','0',20,'',41,'','','yes','no',''),(698,'','Machine_Default','Mount','Mount','','',22,'Mount','varchar(80)','','YES','',20,'^.{0,80}$',43,'','','yes','no',''),(699,'','Plate_Format','Max Row','Max_Row','Mandatory','',6,'Max_Row','char(2)','','YES','',20,'[A-Z]',60,'','','yes','no',''),(700,'','Plate_Format','Max Col','Max_Col','Mandatory','',7,'Max_Col','tinyint(4)','','YES','',20,'[0-9]+',60,'','','yes','no',''),(726,'','Sequencer_Type','Sequencer Type ID','ID','Primary','Sequencer_Type_Name',1,'Sequencer_Type_ID','tinyint(4)','PRI','NO','0',20,'',74,'','','yes','no',''),(727,'','Sequencer_Type','Name','Name','','',2,'Sequencer_Type_Name','varchar(20)','','NO','',20,'^.{0,20}$',74,'','','yes','no',''),(728,'','Sequencer_Type','Well Ordering','Well_Ordering','','',3,'Well_Ordering','enum(\'Columns\',\'Rows\')','','NO','Columns',20,'',74,'','','yes','no',''),(729,'','Sequencer_Type','Zero Pad Columns','Zero_Pad_Columns','','',4,'Zero_Pad_Columns','enum(\'YES\',\'NO\')','','NO','NO',20,'',74,'','','yes','no',''),(730,'','Sequencer_Type','FileFormat','FileFormat','','',5,'FileFormat','varchar(255)','','NO','',20,'^.{0,255}$',74,'','','yes','no',''),(731,'','Sequencer_Type','RunDirectory','RunDirectory','','',6,'RunDirectory','varchar(255)','','NO','',20,'^.{0,255}$',74,'','','yes','no',''),(732,'','Sequencer_Type','TraceFileExt','TraceFileExt','','',7,'TraceFileExt','varchar(40)','','NO','',20,'^.{0,40}$',74,'','','yes','no',''),(733,'','Sequencer_Type','FailedTraceFileExt','FailedTraceFileExt','','',8,'FailedTraceFileExt','varchar(40)','','NO','',20,'^.{0,40}$',74,'','','yes','no',''),(734,'','Sequencer_Type','SS extension','SS_extension','','',9,'SS_extension','varchar(5)','','YES','',20,'^.{0,5}$',74,'','','yes','no',''),(735,'','Sequencer_Type','Default Terminator','Default_Terminator','','',10,'Default_Terminator','enum(\'Big Dye\',\'Water\')','','NO','Water',20,'',74,'','','yes','no',''),(748,'','Clone_Sequence','Well','Well','Mandatory','',2,'Well','char(3)','','NO','',20,'',15,'','','yes','no',''),(754,'','Collaboration','Project','Project__ID','Mandatory','Project_ID',2,'FK_Project__ID','int(11)','MUL','YES','',20,'',17,'Project.Project_ID','','yes','no',''),(755,'','Communication','Employee','Employee__ID','','Employee_ID',1,'FK_Employee__ID','int(11)','MUL','YES','',20,'',18,'Employee.Employee_ID','','yes','no',''),(756,'','Communication','Contact','Contact__ID','NewLink','Contact_ID',2,'FK_Contact__ID','int(11)','MUL','YES','',20,'',18,'Contact.Contact_ID','','yes','no',''),(757,'','Communication','Organization','Organization__ID','','Organization_ID',3,'FK_Organization__ID','int(11)','MUL','YES','',20,'',18,'Organization.Organization_ID','','yes','no',''),(758,'','ConcentrationRun','Plate','Plate__ID','','Plate_ID',2,'FK_Plate__ID','int(10) unsigned','MUL','NO','0',20,'',21,'Plate.Plate_ID','','yes','no',''),(759,'','ConcentrationRun','Equipment','Equipment__ID','ViewLink','Equipment_ID',3,'FK_Equipment__ID','int(10) unsigned','MUL','NO','0',20,'',21,'Equipment.Equipment_ID','','yes','no',''),(760,'','Concentrations','Well','Well','','',3,'Well','char(3)','','YES','',20,'',23,'','','yes','no',''),(761,'','Concentrations','Concentration','Concentration','','',6,'Concentration','varchar(10)','MUL','YES','',20,'^.{0,10}$',23,'','','yes','no',''),(762,'Organization assciated with this person','Contact','Organization','Organization__ID','Mandatory,NewLink','Organization_ID',1,'FK_Organization__ID','int(11)','MUL','YES','',20,'',24,'Organization.Organization_ID','','yes','no',''),(763,'','Contact','Position','Position','','',3,'Position','text','','YES','',20,'',24,'','','yes','no',''),(764,'','Contact','Fax','Fax','Hidden','',18,'Fax','text','','YES','',20,'',24,'','','yes','no',''),(765,'','Contact','Email','Email','Hidden','',32,'Email','text','','YES','',20,'',24,'','','yes','no',''),(766,'','Contact','Comments','Comments','Hidden','',39,'Comments','text','','YES','',20,'',24,'','','yes','no',''),(767,'','Contaminant','Well','Well','','',2,'Well','char(3)','','YES','',20,'',25,'','','yes','no',''),(770,'','Cross_Match','Well','Well','','',2,'Well','char(3)','','YES','',20,'',27,'','','yes','no',''),(786,'','Dye_Chemistry','Chemistry Version','Chemistry_Version','','',3,'Chemistry_Version','int(11)','','YES','',20,'',29,'','','yes','no',''),(787,'','Dye_Chemistry','Mobility Version','Mobility_Version','','',4,'Mobility_Version','int(11)','','YES','',20,'',29,'','','yes','no',''),(788,'','Equipment','Stock','Stock__ID','','Stock_ID',8,'FK_Stock__ID','int(11)','MUL','YES','',20,'',31,'Stock.Stock_ID','','yes','no',''),(789,'','Error_Check','Field Name','Field_Name','','',3,'Field_Name','mediumtext','','NO','',20,'',32,'','','yes','no',''),(790,'','Error_Check','Comments','Comments','','',7,'Comments','text','','YES','',20,'',32,'','','yes','no',''),(804,'','Gel','Gel ID','ID','Primary','',1,'Gel_ID','int(10) unsigned','PRI','NO','0',20,'',37,'','','yes','no',''),(805,'','Gel','Plate','Plate__ID','','Plate_ID',2,'FK_Plate__ID','int(11)','MUL','NO','',20,'',37,'Plate.Plate_ID','','yes','no',''),(806,'','Gel','Date','Date','','',5,'Gel_Date','datetime','','NO','0000-00-00 00:00:00',20,'',37,'','','yes','yes',''),(807,'','Gel','Employee','Employee__ID','','Employee_ID',6,'FK_Employee__ID','int(4)','MUL','YES','',20,'',37,'Employee.Employee_ID','','yes','no',''),(810,'','Lab_Protocol','Employee','Employee__ID','','Employee_ID',2,'FK_Employee__ID','int(11)','MUL','YES','',20,'',39,'Employee.Employee_ID','','yes','yes',''),(812,'','LibraryPrimer','Library','Library__Name','Mandatory,Searchable','Library_Name',2,'FK_Library__Name','varchar(40)','MUL','YES','',20,'',41,'Library.Library_Name','','yes','no',''),(813,'','LibraryPrimer','Primer','Primer__Name','Mandatory,NewLink','Primer_Name',3,'FK_Primer__Name','varchar(40)','MUL','YES','',20,'',41,'Primer.Primer_Name','','yes','no',''),(814,'','LibraryProgress','Library','Library__Name','Searchable','Library_Name',3,'FK_Library__Name','varchar(5)','MUL','YES','',20,'',42,'Library.Library_Name','','yes','no',''),(815,'','Machine_Default','Equipment','Equipment__ID','ViewLink','Equipment_ID',2,'FK_Equipment__ID','int(11)','MUL','YES','',20,'',43,'Equipment.Equipment_ID','','yes','no',''),(816,'','Machine_Default','Agarose Percentage','Agarose_Percentage','Hidden','',10,'Agarose_Percentage','float','','YES','',20,'',43,'','','yes','no',''),(817,'','Machine_Default','Injection Voltage','Injection_Voltage','Hidden','',11,'Injection_Voltage','int(11)','','YES','',20,'',43,'','','yes','no',''),(818,'','Machine_Default','Injection Time','Injection_Time','Hidden','',12,'Injection_Time','int(11)','','YES','',20,'',43,'','','yes','no',''),(819,'','Machine_Default','Run Voltage','Run_Voltage','Hidden','',13,'Run_Voltage','int(11)','','YES','',20,'',43,'','','yes','no',''),(820,'','Machine_Default','Run Time','Run_Time','Hidden','',14,'Run_Time','int(11)','','YES','',20,'',43,'','','yes','no',''),(821,'','Machine_Default','PMT1','PMT1','Hidden','',16,'PMT1','int(11)','','YES','',20,'',43,'','','yes','no',''),(822,'','Machine_Default','PMT2','PMT2','Hidden','',17,'PMT2','int(11)','','YES','',20,'',43,'','','yes','no',''),(823,'','Machine_Default','Foil Piercing','Foil_Piercing','Hidden','',19,'Foil_Piercing','tinyint(4)','','YES','',20,'',43,'','','yes','no',''),(824,'','Machine_Default','Chemistry Version','Chemistry_Version','Hidden','',20,'Chemistry_Version','tinyint(4)','','YES','',20,'',43,'','','yes','no',''),(825,'','Machine_Default','Sequencer Type','Sequencer_Type__ID','','Sequencer_Type_ID',21,'FK_Sequencer_Type__ID','tinyint(4)','MUL','NO','0',20,'',43,'Sequencer_Type.Sequencer_Type_ID','','yes','no',''),(826,'','Maintenance','Equipment','Equipment__ID','ViewLink','Equipment_ID',3,'FK_Equipment__ID','int(11)','MUL','YES','',20,'',44,'Equipment.Equipment_ID','','yes','no',''),(827,'','Maintenance','Solution used','Solution__ID','','Solution_ID',4,'FK_Solution__ID','int(11)','MUL','YES','',20,'',44,'Solution.Solution_ID','','yes','no',''),(828,'','Maintenance','Employee','Employee__ID','Mandatory','Employee_ID',6,'FK_Employee__ID','int(11)','MUL','YES','',20,'',44,'Employee.Employee_ID','','yes','no',''),(829,'','Maintenance_Protocol','Employee','Employee__ID','','Employee_ID',6,'FK_Employee__ID','int(11)','MUL','YES','',20,'',45,'Employee.Employee_ID','','yes','no',''),(831,'','Message','Employee','Employee__ID','','Employee_ID',2,'FK_Employee__ID','int(11)','MUL','YES','',20,'',46,'Employee.Employee_ID','','yes','no',''),(832,'','Misc_Item','Stock','Stock__ID','','Stock_ID',5,'FK_Stock__ID','int(11)','MUL','YES','',20,'',47,'Stock.Stock_ID','','yes','no',''),(833,'','Mixture','Quantity Used','Quantity_Used','','',4,'Quantity_Used','float','','YES','',20,'',48,'','','yes','no',''),(834,'','Notice','Target List','Target_List','','',5,'Target_List','text','','YES','',20,'',52,'','','yes','no',''),(835,'','Optical_Density','Plate','Plate__ID','','Plate_ID',1,'FK_Plate__ID','int(11)','MUL','NO','0',20,'',53,'Plate.Plate_ID','','yes','no',''),(836,'','Plate','Library','Library__Name','Mandatory,Searchable','Library_Name',2,'FK_Library__Name','varchar(40)','MUL','YES','',20,'',59,'Library.Library_Name','','no','yes',''),(837,'','Plate','Employee','Employee__ID','','Employee_ID',8,'FK_Employee__ID','int(11)','MUL','YES','',20,'',59,'Employee.Employee_ID','','no','no',''),(838,'Rack ID and an optional slot name','Plate','Rack','Rack__ID','Searchable','Rack_ID',16,'FK_Rack__ID','int(11)','MUL','YES','<DEFAULT_LOCATION>',20,'',59,'Rack.Rack_ID','The default rack was set as a temporary fix','no','no',''),(839,'','Plate_Set','Plate','Plate__ID','','Plate_ID',2,'FK_Plate__ID','int(11)','MUL','YES','',20,'',61,'Plate.Plate_ID','','yes','no',''),(840,'','Plate_Tube','Plate','Plate__ID','','Plate_ID',2,'FK_Plate__ID','int(11)','MUL','YES','',20,'',62,'Plate.Plate_ID','','yes','no',''),(841,'','Plate_Tube','Tube','Tube__ID','','Tube_ID',3,'FK_Tube__ID','int(11)','MUL','YES','',20,'',62,'Tube.Tube_ID','','yes','no',''),(843,'','Pool','Employee','Employee__ID','','Employee_ID',5,'FK_Employee__ID','int(11)','MUL','YES','',20,'',11,'Employee.Employee_ID','','yes','no',''),(851,'','Primer_Info','Solution','Solution__ID','','Solution_ID',1,'FK_Solution__ID','int(11)','MUL','YES','',20,'',65,'Solution.Solution_ID','','yes','no',''),(852,'','Primer_Info','nMoles','nMoles','','',2,'nMoles','float','','YES','',20,'',65,'','','yes','no',''),(853,'','Primer_Info','micrograms','micrograms','','',3,'micrograms','float','','YES','',20,'',65,'','','yes','no',''),(854,'','Primer_Info','ODs','ODs','','',4,'ODs','float','','YES','',20,'',65,'','','yes','no',''),(855,'','Protocol_Step','Employee','Employee__ID','','Employee_ID',9,'FK_Employee__ID','int(11)','MUL','YES','',20,'',67,'Employee.Employee_ID','','yes','yes',''),(856,'Mandatory EXCEPT for Lab shelves (set conditions to Room Temperature)','Rack','Equipment','Equipment__ID','Mandatory,ViewLink','Equipment_ID',2,'FK_Equipment__ID','int(11)','MUL','YES','',20,'',69,'Equipment.Equipment_ID','','yes','no',''),(858,'','SS_Config','SS Config ID','ID','Primary','concat(FK_Sequencer_Type__ID,\': \',SS_Alias)',1,'SS_Config_ID','int(11)','PRI','NO','',20,'',72,'','','yes','no',''),(859,'','SS_Config','Sequencer Type','Sequencer_Type__ID','','Sequencer_Type_ID',2,'FK_Sequencer_Type__ID','int(4)','MUL','NO','0',20,'',72,'Sequencer_Type.Sequencer_Type_ID','','yes','no',''),(860,'','SS_Config','SS Title','SS_Title','','',3,'SS_Title','char(80)','','NO','',20,'',72,'','','yes','no',''),(861,'','SS_Config','SS Section','SS_Section','','',4,'SS_Section','int(2)','','NO','0',20,'',72,'','','yes','no',''),(862,'','SS_Config','SS Order','SS_Order','','',5,'SS_Order','tinyint(4)','','YES','',20,'',72,'','','yes','no',''),(863,'','SS_Config','SS Default','SS_Default','','',6,'SS_Default','char(80)','','NO','',20,'',72,'','','yes','no',''),(864,'','SS_Config','SS Alias','SS_Alias','','',7,'SS_Alias','char(80)','','NO','',20,'',72,'','','yes','no',''),(865,'','SS_Config','SS Orientation','SS_Orientation','','',8,'SS_Orientation','enum(\'Column\',\'Row\',\'N/A\')','','YES','',20,'',72,'','','yes','no',''),(866,'','SS_Config','SS Type','SS_Type','','',9,'SS_Type','enum(\'Titled\',\'Untitled\',\'Hidden\')','','NO','Titled',20,'',72,'','','yes','no',''),(867,'','SS_Config','SS Prompt','SS_Prompt','','',10,'SS_Prompt','enum(\'Text\',\'Radio\',\'Default\',\'No\')','','YES','',20,'',72,'','','yes','no',''),(868,'','SS_Config','SS Track','SS_Track','','',11,'SS_Track','char(40)','','NO','',20,'',72,'','','yes','no',''),(870,'','SS_Option','SS Option ID','ID','Primary','concat(FK_SS_Config__ID,\': \',SS_Option_Alias)',1,'SS_Option_ID','int(11)','PRI','NO','',20,'',73,'','','yes','no',''),(871,'','SS_Option','Equipment','Equipment__ID','ViewLink','Equipment_ID',2,'FK_Equipment__ID','int(11)','MUL','YES','',20,'',73,'Equipment.Equipment_ID','','yes','no',''),(872,'','SS_Option','Alias','Alias','','',3,'SS_Option_Alias','char(80)','','YES','',20,'',73,'','','yes','no',''),(873,'','SS_Option','Value','Value','','',4,'SS_Option_Value','char(80)','','YES','',20,'',73,'','','yes','no',''),(874,'','SS_Option','SS Config','SS_Config__ID','','SS_Config_ID',5,'FK_SS_Config__ID','int(11)','MUL','YES','',20,'',73,'SS_Config.SS_Config_ID','','yes','no',''),(875,'','SS_Option','Option Order','Option_Order','','',6,'SS_Option_Order','tinyint(4)','','YES','',20,'',73,'','','yes','no',''),(876,'','SS_Option','Status','Status','','',7,'SS_Option_Status','enum(\'Active\',\'Inactive\',\'Default\',\'AutoSet\')','','NO','Active',20,'',73,'','','yes','no',''),(882,'','Service','Equipment','Equipment__ID','ViewLink','Equipment_ID',1,'FK_Equipment__ID','int(11)','MUL','YES','',20,'',75,'Equipment.Equipment_ID','','yes','no',''),(883,'','Service_Contract','Organization','Organization__ID','','Organization_ID',3,'FK_Organization__ID','int(11)','MUL','YES','',20,'',76,'Organization.Organization_ID','','yes','no',''),(884,'','Service_Contract','Equipment','Equipment__ID','ViewLink','Equipment_ID',4,'FK_Equipment__ID','int(11)','MUL','YES','',20,'',76,'Equipment.Equipment_ID','','yes','no',''),(885,'','Service_Contract','Orders','Orders__ID','Hidden','Orders_ID',5,'FK_Orders__ID','int(11)','MUL','YES','',20,'',76,'Orders.Orders_ID','','yes','no',''),(887,'Rack ID and an optional slot name','Solution','Rack','Rack__ID','Mandatory,Searchable','Rack_ID',11,'FK_Rack__ID','int(11)','MUL','YES','<DEFAULT_LOCATION>',20,'',5,'Rack.Rack_ID','','yes','no',''),(889,'Manufacturer of Item (as opposed to Vendor).  This is of interest to lab in cases of problems.','Stock','Manufacturer','Organization__ID','Mandatory,NewLink,Obsolete','Organization_ID',4,'FK_Organization__ID','int(11)','MUL','YES','',20,'',7,'Organization.Organization_ID','','yes','no',''),(890,'','Stock','Employee','Employee__ID','Mandatory','Employee_ID',17,'FK_Employee__ID','int(11)','MUL','YES','',20,'',7,'Employee.Employee_ID','','yes','no',''),(892,'','Suggestion','Employee','Employee__ID','','Employee_ID',3,'FK_Employee__ID','int(11)','MUL','YES','',20,'',78,'Employee.Employee_ID','','yes','no',''),(893,'','Transposon','Organization','Organization__ID','','Organization_ID',2,'FK_Organization__ID','int(11)','MUL','YES','',20,'',12,'Organization.Organization_ID','','yes','no',''),(894,'','Transposon','Antibiotic Marker','Antibiotic_Marker','','',6,'Antibiotic_Marker','enum(\'Kanamycin\',\'Chloramphenicol\',\'Tetracycline\')','','YES','',20,'',12,'','','yes','no',''),(895,'','SS_Option','Reference SS Option','Reference_SS_Option__ID','','SS_Option_ID',8,'FKReference_SS_Option__ID','int(11)','MUL','YES','',20,'',73,'SS_Option.SS_Option_ID','','yes','no',''),(896,'','Vector','Manufacturer Organization','Manufacturer_Organization__ID','NewLink','Organization_ID',10,'FKManufacturer_Organization__ID','int(11)','MUL','YES','',20,'',81,'Organization.Organization_ID','','yes','no',''),(897,'','Vector','Source Organization','Source_Organization__ID','Hidden,Obsolete','Organization_ID',11,'FKSource_Organization__ID','int(11)','MUL','YES','',20,'',81,'Organization.Organization_ID','','yes','no',''),(913,'','Clone_Sequence','Sequence Length','Sequence_Length','','',3,'Sequence_Length','smallint(6)','MUL','NO','-2',20,'',15,'','','yes','no',''),(914,'','Clone_Sequence','Quality Left','Quality_Left','','',4,'Quality_Left','smallint(6)','','NO','-2',20,'',15,'','','yes','no',''),(915,'','Clone_Sequence','Quality Length','Quality_Length','','',5,'Quality_Length','smallint(6)','','NO','-2',20,'',15,'','','yes','no',''),(916,'','Clone_Sequence','Vector Left','Vector_Left','','',6,'Vector_Left','smallint(6)','','NO','-2',20,'',15,'','','yes','no',''),(917,'','Clone_Sequence','Vector Right','Vector_Right','','',7,'Vector_Right','smallint(6)','','NO','-2',20,'',15,'','','yes','no',''),(918,'','Clone_Sequence','Note','Note__ID','','Note_ID',8,'FK_Note__ID','tinyint(4)','MUL','YES','',20,'',15,'Note.Note_ID','','yes','no',''),(919,'','Clone_Sequence','Read Error','Read_Error','','',9,'Read_Error','enum(\'trace data missing\',\'Empty Read\',\'Analysis Aborted\')','','YES','',20,'',15,'','','yes','no',''),(920,'','Clone_Sequence','Read Warning','Read_Warning','','',10,'Read_Warning','set(\'Vector Only\',\'Vector Segment\',\'Recurring String\',\'Contamination\',\'Poor Quality\')','MUL','YES','',20,'',15,'','','yes','no',''),(921,'','Clone_Sequence','Growth','Growth','','',11,'Growth','enum(\'OK\',\'Slow Grow\',\'No Grow\',\'Unused\',\'Empty\',\'Problematic\')','MUL','YES','OK',20,'',15,'','','yes','no',''),(922,'','Clone_Sequence','Sequence','Sequence','Hidden','',12,'Sequence','text','','NO','',20,'',15,'','','yes','no',''),(923,'','Clone_Sequence','Sequence Scores','Sequence_Scores','Hidden','',13,'Sequence_Scores','blob','','NO','',20,'',15,'','','yes','no',''),(924,'','Clone_Sequence','Vector Quality','Vector_Quality','Hidden','',14,'Vector_Quality','smallint(6)','','NO','-2',20,'',15,'','','yes','no',''),(925,'','Clone_Sequence','Vector Total','Vector_Total','Hidden','',15,'Vector_Total','smallint(6)','','NO','-2',20,'',15,'','','yes','no',''),(926,'','Clone_Sequence','Phred Histogram','Phred_Histogram','Hidden','',16,'Phred_Histogram','varchar(200)','','NO','',20,'^.{0,200}$',15,'','','yes','no',''),(927,'','Clone_Sequence','Quality Histogram','Quality_Histogram','Hidden','',17,'Quality_Histogram','varchar(200)','','NO','',20,'^.{0,200}$',15,'','','yes','no',''),(928,'','Clone_Sequence','Comments','Comments','Hidden','',18,'Clone_Sequence_Comments','varchar(255)','','NO','',20,'^.{0,255}$',15,'','','yes','no',''),(929,'','Clone_Sequence','Test Run Flag','Test_Run_Flag','Hidden','',19,'Test_Run_Flag','tinyint(4)','','NO','0',20,'',15,'','','yes','no',''),(930,'','Clone_Sequence','Capillary','Capillary','Hidden','',20,'Capillary','char(3)','','NO','',20,'',15,'','','yes','no',''),(931,'','Clone_Sequence','Clone Sequence ID','ID','Primary','',21,'Clone_Sequence_ID','int(11)','PRI','NO','',20,'',15,'','','yes','no',''),(938,'','Collaboration','Collaboration ID','ID','Primary','',3,'Collaboration_ID','int(11)','PRI','NO','',20,'',17,'','','yes','no',''),(939,'','Communication','Date','Date','','',4,'Communication_Date','date','','YES','<TODAY>',20,'',18,'','','yes','no',''),(940,'','Communication','Description','Description','','',5,'Communication_Description','text','','YES','',20,'',18,'','','yes','no',''),(941,'','Communication','Communication ID','ID','Primary','',6,'Communication_ID','int(11)','PRI','NO','',20,'',18,'','','yes','no',''),(942,'','ConcentrationRun','ConcentrationRun ID','ID','Primary','',1,'ConcentrationRun_ID','int(10) unsigned','PRI','NO','',20,'',21,'','','yes','no',''),(943,'','ConcentrationRun','DateTime','DateTime','','',4,'DateTime','datetime','','NO','0000-00-00 00:00:00',20,'',21,'','','yes','yes',''),(944,'','ConcentrationRun','CalibrationFunction','CalibrationFunction','','',5,'CalibrationFunction','text','','NO','',20,'',21,'','','yes','no',''),(945,'','Concentrations','Concentration ID','Concentration_ID','Primary','',1,'Concentration_ID','int(10) unsigned','PRI','NO','',20,'',23,'','','yes','no',''),(946,'','Concentrations','ConcentrationRun','ConcentrationRun__ID','','ConcentrationRun_ID',2,'FK_ConcentrationRun__ID','int(10) unsigned','MUL','NO','0',20,'',23,'ConcentrationRun.ConcentrationRun_ID','','yes','no',''),(947,'','Concentrations','Measurement','Measurement','','',4,'Measurement','varchar(10)','MUL','YES','',20,'^.{0,10}$',23,'','','yes','no',''),(948,'','Concentrations','Units','Units','','',5,'Units','varchar(15)','','YES','',20,'^.{0,15}$',23,'','','yes','no',''),(949,'','Contact','Name','Name','Mandatory','',2,'Contact_Name','varchar(80)','MUL','YES','',20,'^.{0,80}$',24,'','','yes','no',''),(950,'','Contact','Type','Type','','',4,'Contact_Type','enum(\'Collaborator\',\'Maintenance\',\'Technical Support\',\'Sales\',\'Academic\')','MUL','YES','',20,'',24,'','','yes','no',''),(951,'','Contact','Phone','Phone','','',5,'Contact_Phone','text','','YES','',20,'',24,'','','yes','no',''),(952,'','Contact','Fax','Fax','','',6,'Contact_Fax','text','','YES','',20,'',24,'','','yes','no',''),(953,'','Contact','Email','Email','Mandatory','',7,'Contact_Email','text','','YES','',20,'',24,'','','yes','no',''),(954,'','Contact','Status','Status','','',8,'contact_status','enum(\'Current\',\'Old\',\'Basic\',\'Active\')','','YES','Active',20,'',24,'','','yes','no',''),(955,'','Contact','Notes','Notes','','',9,'Contact_Notes','text','','YES','',20,'',24,'','','yes','no',''),(956,'','Contact','Contact ID','ID','Primary','Contact_Name',10,'Contact_ID','int(11)','PRI','NO','',20,'',24,'','','yes','no',''),(957,'','Contact','First Name','First_Name','Hidden','',11,'First_Name','text','','YES','',20,'',24,'','','yes','no',''),(958,'','Contact','Middle Name','Middle_Name','Hidden','',12,'Middle_Name','text','','YES','',20,'',24,'','','yes','no',''),(959,'','Contact','Last Name','Last_Name','Hidden','',13,'Last_Name','text','','YES','',20,'',24,'','','yes','no',''),(960,'','Contact','Category','Category','Hidden','',14,'Category','enum(\'Collaborator\',\'Maintenance\',\'Technical Support\',\'Sales\',\'Academic\')','','YES','',20,'',24,'','','yes','no',''),(961,'','Contact','Home Phone','Home_Phone','Hidden','',15,'Home_Phone','text','','YES','',20,'',24,'','','yes','no',''),(962,'','Contact','Work Phone','Work_Phone','Hidden','',16,'Work_Phone','text','','YES','',20,'',24,'','','yes','no',''),(963,'','Contact','Pager','Pager','Hidden','',17,'Pager','text','','YES','',20,'',24,'','','yes','no',''),(964,'','Contact','Mobile','Mobile','Hidden','',19,'Mobile','text','','YES','',20,'',24,'','','yes','no',''),(965,'','Contact','Other Phone','Other_Phone','Hidden','',20,'Other_Phone','text','','YES','',20,'',24,'','','yes','no',''),(966,'','Contact','Primary Location','Primary_Location','Hidden','',21,'Primary_Location','enum(\'home\',\'work\')','','YES','',20,'',24,'','','yes','no',''),(967,'','Contact','Home Address','Home_Address','Hidden','',22,'Home_Address','text','','YES','',20,'',24,'','','yes','no',''),(968,'','Contact','Home City','Home_City','Hidden','',23,'Home_City','text','','YES','',20,'',24,'','','yes','no',''),(969,'','Contact','Home County','Home_County','Hidden','',24,'Home_County','text','','YES','',20,'',24,'','','yes','no',''),(970,'','Contact','Home Postcode','Home_Postcode','Hidden','',25,'Home_Postcode','text','','YES','',20,'',24,'','','yes','no',''),(971,'','Contact','Home Country','Home_Country','Hidden','',26,'Home_Country','text','','YES','',20,'',24,'','','yes','no',''),(972,'','Contact','Work Address','Work_Address','Hidden','',27,'Work_Address','text','','YES','',20,'',24,'','','yes','no',''),(973,'','Contact','Work City','Work_City','Hidden','',28,'Work_City','text','','YES','',20,'',24,'','','yes','no',''),(974,'','Contact','Work County','Work_County','Hidden','',29,'Work_County','text','','YES','',20,'',24,'','','yes','no',''),(975,'','Contact','Work Postcode','Work_Postcode','Hidden','',30,'Work_Postcode','text','','YES','',20,'',24,'','','yes','no',''),(976,'','Contact','Work Country','Work_Country','Hidden','',31,'Work_Country','text','','YES','',20,'',24,'','','yes','no',''),(977,'','Contact','Personal Website','Personal_Website','Hidden','',33,'Personal_Website','text','','YES','',20,'',24,'','','yes','no',''),(978,'','Contact','Business Website','Business_Website','Hidden','',34,'Business_Website','text','','YES','',20,'',24,'','','yes','no',''),(979,'','Contact','Alternate Email 1','Alternate_Email_1','Hidden','',35,'Alternate_Email_1','text','','YES','',20,'',24,'','','yes','no',''),(980,'','Contact','Alternate Email 2','Alternate_Email_2','Hidden','',36,'Alternate_Email_2','text','','YES','',20,'',24,'','','yes','no',''),(981,'','Contact','Birthday','Birthday','Hidden','',37,'Birthday','date','','YES','',20,'',24,'','','yes','no',''),(982,'','Contact','Anniversary','Anniversary','Hidden','',38,'Anniversary','date','','YES','',20,'',24,'','','yes','no',''),(983,'','Contaminant','Contaminant ID','ID','Primary','',1,'Contaminant_ID','int(11)','PRI','NO','',20,'',25,'','','yes','no',''),(984,'','Contaminant','Detection Date','Detection_Date','','',4,'Detection_Date','date','','YES','<TODAY>',20,'',25,'','','yes','yes',''),(985,'','Contaminant','E value','E_value','','',5,'E_value','float unsigned','','YES','',20,'',25,'','','yes','no',''),(986,'','Contaminant','Score','Score','','',6,'Score','int(11)','','YES','',20,'',25,'','','yes','no',''),(987,'','Contaminant','Contamination','Contamination__ID','','Contamination_ID',7,'FK_Contamination__ID','int(11)','MUL','YES','',20,'',25,'Contamination.Contamination_ID','','yes','no',''),(988,'','Contamination','Contamination ID','ID','Primary','Contamination_Alias',1,'Contamination_ID','int(11)','PRI','NO','',20,'',26,'','','yes','no',''),(989,'','Contamination','Name','Name','','',2,'Contamination_Name','text','','YES','',20,'',26,'','','yes','no',''),(990,'','Contamination','Description','Description','','',3,'Contamination_Description','text','','YES','',20,'',26,'','','yes','no',''),(991,'','Contamination','Alias','Alias','','',4,'Contamination_Alias','text','','YES','',20,'',26,'','','yes','no',''),(992,'','Cross_Match','Match Name','Match_Name','','',3,'Match_Name','char(80)','','YES','',20,'',27,'','','yes','no',''),(993,'','Cross_Match','Match Start','Match_Start','','',4,'Match_Start','int(11)','','YES','',20,'',27,'','','yes','no',''),(994,'','Cross_Match','Match Stop','Match_Stop','','',5,'Match_Stop','int(11)','','YES','',20,'',27,'','','yes','no',''),(995,'','Cross_Match','Date','Date','','',6,'Cross_Match_Date','date','','YES','<TODAY>',20,'',27,'','','yes','yes',''),(996,'','Cross_Match','Cross Match ID','ID','Primary','',7,'Cross_Match_ID','int(11)','PRI','NO','',20,'',27,'','','yes','no',''),(997,'','Cross_Match','Match Direction','Match_Direction','','',8,'Match_Direction','enum(\'\',\'C\')','','YES','',20,'',27,'','','yes','no',''),(999,'','Dye_Chemistry','Dye Chemistry ID','ID','Primary','',1,'Dye_Chemistry_ID','int(11)','PRI','NO','',20,'',29,'','','yes','no',''),(1000,'','Dye_Chemistry','Terminator','Terminator','','',2,'Terminator','varchar(20)','','YES','',20,'^.{0,20}$',29,'','','yes','no',''),(1001,'','Dye_Chemistry','Mob File','Mob_File','','',5,'Mob_File','varchar(255)','','YES','',20,'^.{0,255}$',29,'','','yes','no',''),(1002,'','Dye_Chemistry','Dye Set','Dye_Set','','',6,'Dye_Set','varchar(5)','','YES','',20,'^.{0,5}$',29,'','','yes','no',''),(1003,'brief Name / Alias','Employee','Name','Name','','',1,'Employee_Name','varchar(80)','MUL','YES','',20,'^.{0,80}$',30,'','','yes','no',''),(1004,'','Employee','Initials','Initials','','',2,'Initials','varchar(4)','MUL','YES','',20,'^.{0,4}$',30,'','','yes','no',''),(1005,'Full Name','Employee','FullName','FullName','','',3,'Employee_FullName','varchar(80)','MUL','YES','',20,'^.{0,80}$',30,'','','yes','no',''),(1006,'','Employee','Position','Position','','',4,'Position','text','','YES','',20,'',30,'','','yes','no',''),(1007,'Email address (do not need to include the domain (@bcgsc.ca) if internal)','Employee','Email Address','Email_Address','','',5,'Email_Address','varchar(80)','MUL','YES','',20,'^.{0,80}$',30,'','','yes','no',''),(1008,'','Employee','Status','Status','','',6,'Employee_Status','enum(\'Active\',\'Inactive\',\'Old\')','','YES','',20,'',30,'','','yes','no',''),(1009,'','Employee','IP Address','IP_Address','Hidden','',7,'IP_Address','text','','YES','',20,'',30,'','','yes','no',''),(1010,'','Employee','Permissions','Permissions','Hidden','',8,'Permissions','set(\'R\',\'W\',\'U\',\'D\',\'S\',\'P\',\'A\')','','YES','',20,'',30,'','','yes','no',''),(1011,'','Employee','Employee ID','ID','Primary','Employee_Name',9,'Employee_ID','int(4)','PRI','NO','',20,'',30,'','','yes','no',''),(1012,'','Employee','Start Date','Start_Date','Hidden','',10,'Employee_Start_Date','date','','YES','',20,'',30,'','','yes','no',''),(1013,'','Equipment','Type','Type','','',2,'Equipment_Type','enum(\'\',\'Sequencer\',\'Centrifuge\',\'Thermal Cycler\',\'Freezer\',\'Liquid Dispenser\',\'Platform Shaker\',\'Incubator\',\'Colony Picker\',\'Plate Reader\',\'Storage\',\'Power Supply\',\'Miscellaneous\',\'Genechip Scanner\',\'Gel Comb\',\'Gel Box\',\'Fluorimager\',\'Spectrophotometer\',\'Bioanalyzer\',\'Hyb Oven\',\'Solexa\',\'GCOS Server\',\'Printer\',\'Pipette\',\'Balance\',\'PDA\',\'Cluster Station\')','MUL','YES','Miscellaneous',20,'',31,'','','yes','yes',''),(1014,'','Equipment','Description','Description','','',3,'Equipment_Description','text','','YES','',20,'',31,'','','yes','no',''),(1015,'','Equipment','Name','Name','','',4,'Equipment_Name','varchar(40)','MUL','YES','',20,'^.{0,40}$',31,'','','yes','yes',''),(1016,'','Equipment','Location','Location','Hidden,Obsolete','',5,'Equipment_Location','enum(\'Sequence Lab\',\'Chromos\',\'CDC\',\'CRC\',\'Functional Genomics\',\'Linen\',\'GE Lab\',\'GE Lab - RNA area\',\'GE Lab - DITAG area\',\'Mapping Lab\',\'MGC Lab\')','','YES','Sequence Lab',20,'',31,'','','yes','yes',''),(1017,'','Equipment','Model','Model','','',6,'Model','varchar(80)','MUL','YES','',20,'^.{0,80}$',31,'','','yes','yes',''),(1018,'','Equipment','Serial Number','Serial_Number','','',7,'Serial_Number','varchar(80)','MUL','YES','',20,'^.{0,80}$',31,'','','yes','yes',''),(1019,'','Equipment','Cost','Cost','','',9,'Equipment_Cost','float','','YES','',20,'',31,'','','yes','no',''),(1020,'','Equipment','Equipment ID','ID','Primary','concat(Equipment_Name,\' \',Equipment_Type)',1,'Equipment_ID','int(4)','PRI','NO','',20,'',31,'','','yes','no',''),(1021,'','Equipment','Comments','Comments','Hidden','',10,'Equipment_Comments','text','','YES','',20,'',31,'','','yes','no',''),(1022,'','Equipment','Acquired','Acquired','Hidden','',11,'Acquired','date','','YES','<TODAY>',20,'',31,'','','yes','no',''),(1023,'','Equipment','Number','Number','Hidden','',12,'Equipment_Number','int(11)','','YES','',20,'',31,'','','yes','yes',''),(1024,'','Equipment','Number in Batch','Number_in_Batch','Hidden','',13,'Equipment_Number_in_Batch','int(11)','','YES','',20,'',31,'','','yes','no',''),(1025,'','Equipment','Alias','Alias','Hidden','',14,'Equipment_Alias','varchar(40)','','YES','',20,'^.{0,40}$',31,'','','yes','no',''),(1026,'','Error_Check','Error Check ID','ID','Primary','',1,'Error_Check_ID','int(11)','PRI','NO','',20,'',32,'','','yes','no',''),(1027,'','Error_Check','Table Name','Table_Name','','',2,'Table_Name','mediumtext','','NO','',20,'',32,'','','yes','no',''),(1029,'','Error_Check','Username','Username','','',5,'Username','varchar(20)','','NO','',20,'^.{0,20}$',32,'','','yes','no',''),(1030,'','Error_Check','Command String','Command_String','','',6,'Command_String','mediumtext','','NO','',20,'',32,'','','yes','no',''),(1036,'Brief Readable name for this funding source / SOW','Funding','Name','Name','Mandatory','',1,'Funding_Name','varchar(80)','UNI','NO','',80,'^.{0,80}$',36,'','','yes','no',''),(1037,'Unambiguous identifier (eg Account code or SOW#)','Funding','Code','Code','Mandatory','concat(Funding_Code,\': \',Funding_Name)',2,'Funding_Code','varchar(20)','MUL','YES','',20,'^.{0,20}$',36,'','','yes','no',''),(1038,'','Funding','Description','Description','','',3,'Funding_Description','text','','NO','',20,'',36,'','','yes','no',''),(1039,'','Funding','Status','Status','','',4,'Funding_Status','enum(\'Applied for\',\'Pending\',\'Received\',\'Terminated\')','','YES','Received',20,'',36,'','','yes','no',''),(1040,'','Funding','Conditions','Conditions','','',5,'Funding_Conditions','text','','NO','',20,'',36,'','','yes','no',''),(1041,'','Funding','Funding ID','ID','Primary','CASE WHEN (Funding_Code=Funding_Name OR Funding_Code is NULL) THEN Funding_Name ELSE CONCAT(Funding_Name,\': \',Funding_Code) END',6,'Funding_ID','int(11)','PRI','NO','',20,'',36,'','','yes','no',''),(1043,'','Gel','Comments','Comments','','',4,'Gel_Comments','text','','YES','',20,'',37,'','','yes','no',''),(1054,'','Lab_Protocol','Name','Name','Mandatory','',1,'Lab_Protocol_Name','varchar(40)','MUL','YES','',20,'^.{0,40}$',39,'','','yes','yes',''),(1055,'','Lab_Protocol','Status','Status','','',3,'Lab_Protocol_Status','enum(\'Active\',\'Old\',\'Inactive\')','','YES','',20,'',39,'','','yes','yes',''),(1056,'','Lab_Protocol','Description','Description','','',4,'Lab_Protocol_Description','text','','YES','',20,'',39,'','','yes','yes',''),(1057,'','Lab_Protocol','Lab Protocol ID','ID','Primary','Lab_Protocol_Name',5,'Lab_Protocol_ID','int(11)','PRI','NO','',20,'',39,'','','yes','yes',''),(1058,'','Lab_Protocol','VersionDate','VersionDate','','',6,'Lab_Protocol_VersionDate','date','','YES','<TODAY>',20,'',39,'','','yes','yes',''),(1059,'','Library','Project','Project__ID','Mandatory','Project_ID',1,'FK_Project__ID','int(11)','MUL','YES','',20,'',40,'Project.Project_ID','','no','no',''),(1060,'A GSC specific ID name consisting of alphanumeric characters (5 characters for Sequencing Library and 6 characters for RNA Source).','Library','Name','Name','Mandatory,Primary','CASE WHEN LENGTH(Library_FullName) = 0 THEN Library_Name WHEN Library_FullName=Library_Name THEN Library_Name ELSE concat(Library_Name,\':\',Library_FullName) END',2,'Library_Name','varchar(40)','PRI','NO','',20,'^\'?[a-zA-Z0-9]{5,6}\'?$',40,'','','no','no',''),(1061,'A Concise name for referencing the library (may contain spaces)','Library','FullName','FullName','Mandatory','',3,'Library_FullName','varchar(80)','','YES','',20,'S+',40,'','','yes','no',''),(1062,'Objectives to be met for the library','Library','Goals','Goals','Hidden','',7,'Library_Goals','text','','YES','',20,'',40,'','','yes','no',''),(1063,'Status of the Library (eg Pending, In Production)','Library','Status','Status','','',12,'Library_Status','enum(\'Submitted\',\'On Hold\',\'In Production\',\'Complete\',\'Cancelled\',\'Contaminated\')','','YES','Submitted',20,'',40,'','','yes','yes',''),(1069,'','Library','Type','Type','Mandatory','',1,'Library_Type','enum(\'Sequencing\',\'RNA/DNA\',\'Mapping\')','','YES','',20,'',40,'','','no','no',''),(1070,'A full prose description of the library','Library','Description','Description','','',8,'Library_Description','text','','YES','',20,'',40,'','','yes','no',''),(1073,'Who supplied the original library?','Library','Source','Source','Hidden','',5,'Library_Source','text','','YES','',20,'',40,'','','yes','no',''),(1074,'How is the Library referenced by those who supplied it ?','Library','Source Name','Source_Name','Hidden','',6,'Library_Source_Name','text','','YES','',20,'',40,'','','yes','no',''),(1075,'Date when library was obtained','Library','Obtained Date','Obtained_Date','Mandatory','',4,'Library_Obtained_Date','date','','NO','0000-00-00',20,'',40,'','','yes','yes',''),(1078,'Optional notes about this library','Library','Notes','Notes','','',25,'Library_Notes','text','','YES','',20,'',40,'','','yes','no',''),(1081,'','Library','Parent Library','Parent_Library__Name','Hidden','Library_Name',31,'FKParent_Library__Name','varchar(40)','MUL','YES','',20,'',40,'Library.Library_Name','','no','no',''),(1083,'','LibraryPrimer','LibraryPrimer ID','ID','Primary','',1,'LibraryPrimer_ID','int(11)','PRI','NO','',20,'',41,'','','yes','no',''),(1084,'','LibraryProgress','LibraryProgress ID','ID','Primary','',1,'LibraryProgress_ID','int(11)','PRI','NO','',20,'',42,'','','yes','no',''),(1085,'','LibraryProgress','Date','Date','','',2,'LibraryProgress_Date','date','','YES','<TODAY>',20,'',42,'','','yes','yes',''),(1086,'','LibraryProgress','Comments','Comments','','',4,'LibraryProgress_Comments','text','','YES','',20,'',42,'','','yes','no',''),(1087,'','Machine_Default','Machine Default ID','ID','Primary','',1,'Machine_Default_ID','int(11)','PRI','NO','',20,'',43,'','','yes','no',''),(1088,'','Machine_Default','Run Module','Run_Module','Hidden','',3,'Run_Module','text','','YES','',20,'',43,'','','yes','no',''),(1089,'','Machine_Default','NT Data dir','NT_Data_dir','','',4,'NT_Data_dir','text','','YES','',20,'',43,'','','yes','no',''),(1090,'','Machine_Default','NT Samplesheet dir','NT_Samplesheet_dir','','',5,'NT_Samplesheet_dir','text','','YES','',20,'',43,'','','yes','no',''),(1091,'','Machine_Default','Local Samplesheet dir','Local_Samplesheet_dir','','',6,'Local_Samplesheet_dir','text','','YES','',20,'',43,'','','yes','no',''),(1092,'','Machine_Default','Host','Host','','',7,'Host','varchar(40)','MUL','YES','',20,'^.{0,40}$',43,'','','yes','no',''),(1093,'','Machine_Default','Local Data dir','Local_Data_dir','','',8,'Local_Data_dir','text','','YES','',20,'',43,'','','yes','no',''),(1094,'','Machine_Default','Sharename','Sharename','','',9,'Sharename','text','','YES','',20,'',43,'','','yes','no',''),(1095,'','Machine_Default','Run Temp','Run_Temp','Hidden','',15,'Run_Temp','int(11)','','YES','',20,'',43,'','','yes','no',''),(1096,'','Machine_Default','An Module','An_Module','Hidden','',18,'An_Module','text','','YES','',20,'',43,'','','yes','no',''),(1097,'','Maintenance','What was done','Process','Obsolete','',1,'Maintenance_Process','text','','YES','',20,'',44,'','','yes','no',''),(1098,'','Maintenance','Description','Description','','',2,'Maintenance_Description','text','','NO','',20,'',44,'','','yes','no',''),(1099,'','Maintenance','DateTime','DateTime','Mandatory','',5,'Maintenance_DateTime','datetime','','YES','<NOW>',20,'',44,'','','yes','yes',''),(1100,'','Maintenance','Who performed work (if external)','Contact__ID','NewLink','Contact_ID',7,'FK_Contact__ID','int(11)','MUL','YES','',20,'',44,'Contact.Contact_ID','','yes','no',''),(1101,'','Maintenance','Maintenance ID','ID','Primary','',8,'Maintenance_ID','int(11)','PRI','NO','',20,'',44,'','','yes','no',''),(1102,'','Maintenance','Cost','Cost','Hidden','',9,'Maintenance_Cost','float','','YES','',20,'',44,'','','yes','no',''),(1103,'','Maintenance_Protocol','Maintenance Protocol ID','ID','Primary','Maintenance_Protocol_Name',1,'Maintenance_Protocol_ID','int(11)','PRI','NO','',20,'',45,'','','yes','no',''),(1104,'','Maintenance_Protocol','Service','Service__Name','Mandatory','Service_Name',2,'FK_Service__Name','varchar(40)','MUL','YES','',20,'',45,'Service.Service_Name','','yes','no',''),(1105,'','Maintenance_Protocol','Step','Step','Mandatory','',3,'Step','int(11)','','YES','',20,'',45,'','','yes','no',''),(1106,'','Maintenance_Protocol','Maintenance Step Name','Maintenance_Step_Name','','',4,'Maintenance_Step_Name','varchar(40)','','YES','',20,'^.{0,40}$',45,'','','yes','no',''),(1107,'','Maintenance_Protocol','Maintenance Instructions','Maintenance_Instructions','','',5,'Maintenance_Instructions','text','','YES','',20,'',45,'','','yes','no',''),(1108,'','Maintenance_Protocol','Protocol Date','Protocol_Date','','',7,'Protocol_Date','date','','YES','0000-00-00',20,'',45,'','','yes','yes',''),(1109,'','Maintenance_Protocol','Name','Name','','',8,'Maintenance_Protocol_Name','text','','YES','',20,'',45,'','','yes','no',''),(1110,'','Message','Text','Text','','',1,'Message_Text','text','','YES','',20,'',46,'','','yes','no',''),(1111,'','Message','Link','Link','','',3,'Message_Link','text','','YES','',20,'',46,'','','yes','no',''),(1112,'','Message','Date','Date','','',4,'Message_Date','datetime','','YES','<NOW>',20,'',46,'','','yes','no',''),(1113,'','Message','Status','Status','','',5,'Message_Status','enum(\'Urgent\',\'Active\',\'Old\')','','YES','Active',20,'',46,'','','yes','no',''),(1114,'','Message','Type','Type','','',6,'Message_Type','enum(\'Public\',\'Private\',\'Admin\',\'Group\')','','YES','Private',20,'',46,'','','yes','no',''),(1115,'','Message','Message ID','ID','Primary','',7,'Message_ID','int(11)','PRI','NO','',20,'',46,'','','yes','no',''),(1116,'','Misc_Item','Misc Item ID','ID','Primary','',1,'Misc_Item_ID','int(11)','PRI','NO','',20,'',47,'','','yes','no',''),(1117,'','Misc_Item','Serial Number','Serial_Number','','',2,'Misc_Item_Serial_Number','text','','YES','',20,'',47,'','','yes','no',''),(1118,'','Misc_Item','Number','Number','','',3,'Misc_Item_Number','int(11)','','NO','0',20,'',47,'','','yes','no',''),(1119,'','Misc_Item','Number in Batch','Number_in_Batch','','',4,'Misc_Item_Number_in_Batch','int(11)','','YES','',20,'',47,'','','yes','no',''),(1121,'','Mixture','Mixture ID','ID','Primary','',1,'Mixture_ID','int(8)','PRI','NO','',20,'',48,'','','yes','no',''),(1122,'','Mixture','Made Solution','Made_Solution__ID','','Solution_ID',2,'FKMade_Solution__ID','int(11)','MUL','YES','',20,'',48,'Solution.Solution_ID','','yes','no',''),(1123,'','Mixture','Used Solution','Used_Solution__ID','','Solution_ID',3,'FKUsed_Solution__ID','int(11)','MUL','YES','',20,'',48,'Solution.Solution_ID','','yes','no',''),(1124,'','Mixture','Comments','Comments','','',5,'Mixture_Comments','text','','YES','',20,'',48,'','','yes','no',''),(1125,'','Mixture','Units Used','Units_Used','','',6,'Units_Used','varchar(10)','','YES','',20,'^.{0,10}$',48,'','','yes','no',''),(1126,'','MultiPlate_Run','MultiPlate Run ID','ID','Primary','',1,'MultiPlate_Run_ID','int(11)','PRI','NO','',20,'',49,'','','yes','no',''),(1129,'','MultiPlate_Run','Quadrant','Quadrant','','',4,'MultiPlate_Run_Quadrant','char(1)','','YES','',20,'',49,'','','yes','no',''),(1130,'','Multiple_Barcode','Multiple Barcode ID','ID','Primary','',1,'Multiple_Barcode_ID','int(11)','PRI','NO','',20,'',50,'','','yes','no',''),(1131,'','Multiple_Barcode','Multiple Text','Multiple_Text','','',2,'Multiple_Text','varchar(100)','MUL','YES','',20,'^.{0,100}$',50,'','','yes','no',''),(1132,'','Note','Note ID','ID','Primary','concat(Note_ID,\': \',Note_Text)',1,'Note_ID','int(11)','PRI','NO','',20,'',51,'','','yes','no',''),(1133,'','Note','Text','Text','','',2,'Note_Text','varchar(40)','','YES','',20,'^.{0,40}$',51,'','','yes','no',''),(1134,'','Note','Type','Type','','',3,'Note_Type','varchar(40)','','YES','',20,'^.{0,40}$',51,'','','yes','no',''),(1135,'','Note','Description','Description','','',4,'Note_Description','text','','YES','',20,'',51,'','','yes','no',''),(1136,'','Notice','Notice ID','ID','Primary','',1,'Notice_ID','int(11)','PRI','NO','',20,'',52,'','','yes','no',''),(1137,'','Notice','Text','Text','','',2,'Notice_Text','text','','YES','',20,'',52,'','','yes','no',''),(1138,'','Notice','Subject','Subject','','',3,'Notice_Subject','text','','YES','',20,'',52,'','','yes','no',''),(1139,'','Notice','Date','Date','','',4,'Notice_Date','date','','YES','<TODAY>',20,'',52,'','','yes','no',''),(1140,'','Optical_Density','260nm Corrected','260nm_Corrected','','',2,'260nm_Corrected','float','','YES','',20,'',53,'','','yes','no',''),(1141,'','Optical_Density','280nm Corrected','280nm_Corrected','','',3,'280nm_Corrected','float','','YES','',20,'',53,'','','yes','no',''),(1142,'','Optical_Density','Density','Density','','',4,'Density','float','','YES','',20,'',53,'','','yes','no',''),(1143,'','Optical_Density','DateTime','DateTime','','',5,'Optical_Density_DateTime','datetime','','YES','<NOW>',20,'',53,'','','yes','yes',''),(1144,'','Optical_Density','Concentration','Concentration','','',6,'Concentration','float','','YES','',20,'',53,'','','yes','no',''),(1145,'','Optical_Density','Optical Density ID','ID','Primary','',7,'Optical_Density_ID','int(11)','PRI','NO','0',20,'',53,'','','yes','no',''),(1146,'','Optical_Density','Well','Well','','',8,'Well','char(3)','PRI','NO','',20,'',53,'','','yes','no',''),(1147,'Notification message (sent via email)','Order_Notice','Order Text','Order_Text','','',1,'Order_Text','text','','YES','',20,'',54,'','','yes','no',''),(1148,'','Order_Notice','Catalog Number','Catalog_Number','','',2,'Catalog_Number','varchar(40)','','NO','',20,'^.{0,40}$',54,'','','yes','no',''),(1149,'List of who should be notified (domain not required if internal)','Order_Notice','Target List','Target_List','','',3,'Target_List','text','','YES','',20,'',54,'','','yes','no',''),(1150,'Minimum acceptable number of units which should remain Unopened','Order_Notice','Minimum Units','Minimum_Units','','',4,'Minimum_Units','int(11)','','YES','',20,'',54,'','','yes','no',''),(1151,'Maximum acceptable number of units which should remain Unopened','Order_Notice','Maximum Units','Maximum_Units','','',5,'Maximum_Units','int(11)','','YES','0',20,'',54,'','','yes','no',''),(1152,'Date of most recent notification','Order_Notice','Notice Sent','Notice_Sent','','',6,'Notice_Sent','date','','YES','',20,'',54,'','','yes','no',''),(1153,'Days between repeat notices (set to 0 to turn off)','Order_Notice','Notice Frequency','Notice_Frequency','','',7,'Notice_Frequency','int(11)','','YES','',20,'',54,'','','yes','no',''),(1154,'','Order_Notice','Order Notice ID','ID','Primary','',8,'Order_Notice_ID','int(11)','PRI','NO','',20,'',54,'','','yes','no',''),(1155,'','Orders','Orders ID','ID','Primary','Orders_ID, Orders_Item',1,'Orders_ID','int(11)','PRI','NO','',20,'',55,'','','yes','no',''),(1156,'','Orders','Quantity','Quantity','Mandatory','',2,'Orders_Quantity','int(11)','','YES','',20,'',55,'','','yes','no',''),(1157,'','Orders','Item Units','Item_Units','','',3,'Item_Units','enum(\'mL\',\'litres\',\'mg\',\'grams\',\'kg\',\'pcs\',\'boxes\',\'tubes\',\'n/a\')','','YES','',20,'',55,'','','yes','no',''),(1159,'','Orders','Catalog Number','Catalog_Number','','',5,'Orders_Catalog_Number','text','','YES','',20,'',55,'','','yes','no',''),(1160,'','Orders','Item','Item','Mandatory','',6,'Orders_Item','text','','YES','',20,'',55,'','','yes','no',''),(1161,'','Orders','Item Description','Item_Description','','',7,'Orders_Item_Description','text','','YES','',20,'',55,'','','yes','no',''),(1162,'','Orders','Item Size','Item_Size','','',8,'Item_Size','float','','YES','',20,'',55,'','','yes','no',''),(1163,'','Orders','Received Date','Received_Date','','',10,'Orders_Received_Date','date','','YES','<TODAY>',20,'',55,'','','yes','yes',''),(1164,'','Orders','Vendor Organization','Vendor_Organization__ID','','Organization_ID',11,'FKVendor_Organization__ID','int(11)','MUL','YES','',20,'',55,'Organization.Organization_ID','','yes','no',''),(1165,'','Orders','Manufacturer Organization','Manufacturer_Organization__ID','','Organization_ID',12,'FKManufacturer_Organization__ID','int(11)','MUL','YES','',20,'',55,'Organization.Organization_ID','','yes','no',''),(1166,'','Orders','Req Number','Req_Number','Mandatory','',13,'Req_Number','text','','YES','',20,'',55,'','','yes','no',''),(1167,'','Orders','Req Date','Req_Date','','',14,'Req_Date','date','','YES','',20,'',55,'','','yes','yes',''),(1168,'','Orders','Lot Number','Lot_Number','','',15,'Orders_Lot_Number','text','','YES','',20,'',55,'','','yes','no',''),(1169,'','Orders','Quote Number','Quote_Number','','',16,'Quote_Number','text','','YES','',20,'',55,'','','yes','no',''),(1170,'','Orders','Serial Num','Serial_Num','','',17,'Serial_Num','text','','YES','',20,'',55,'','','yes','no',''),(1171,'','Orders','Funding','Funding__Code','Mandatory','Funding_Code',18,'FK_Funding__Code','text','','NO','',20,'',55,'Funding.Funding_Code','','yes','no',''),(1172,'','Orders','Unit Cost','Unit_Cost','','',19,'Unit_Cost','float','','YES','',20,'',55,'','','yes','no',''),(1173,'','Orders','Currency','Currency','','',20,'Currency','enum(\'Can\',\'US\')','','YES','Can',20,'',55,'','','yes','no',''),(1174,'','Orders','Cost','Cost','','',21,'Orders_Cost','float(6,2)','','YES','',20,'',55,'','','yes','no',''),(1175,'','Orders','Taxes','Taxes','','',22,'Taxes','float','','YES','',20,'',55,'','','yes','no',''),(1176,'','Orders','Freight Costs','Freight_Costs','','',23,'Freight_Costs','float','','YES','',20,'',55,'','','yes','no',''),(1177,'','Orders','Total Ledger Amount','Total_Ledger_Amount','','',24,'Total_Ledger_Amount','float','','YES','',20,'',55,'','','yes','no',''),(1178,'','Orders','Ledger Period','Ledger_Period','','',25,'Ledger_Period','text','','YES','',20,'',55,'','','yes','no',''),(1179,'','Orders','Account','Account__ID','Mandatory','Account_ID',26,'FK_Account__ID','int(11)','MUL','YES','',20,'',55,'Account.Account_ID','','yes','no',''),(1180,'','Orders','Warranty','Warranty','','',27,'Warranty','text','','YES','',20,'',55,'','','yes','no',''),(1181,'','Orders','MSDS','MSDS','','',28,'MSDS','enum(\'Yes\',\'No\',\'N/A\')','','YES','',20,'',55,'','','yes','no',''),(1182,'','Orders','Notes','Notes','','',29,'Orders_Notes','text','','YES','',20,'',55,'','','yes','no',''),(1183,'','Orders','Req Number','Req_Number','Hidden','',30,'Orders_Req_Number','text','','YES','',20,'',55,'','','yes','no',''),(1184,'','Orders','PO Number','PO_Number','Hidden','',31,'Orders_PO_Number','text','','YES','',20,'',55,'','','yes','no',''),(1185,'','Orders','Received','Received','Hidden','',32,'Orders_Received','int(11)','','NO','0',20,'',55,'','','yes','no',''),(1186,'','Orders','Status','Status','Hidden','',33,'Orders_Status','enum(\'On Order\',\'Received\',\'Incomplete\',\'Pending\')','','YES','',20,'',55,'','','yes','no',''),(1187,'','Orders','PO Date','PO_Date','Hidden','',34,'PO_Date','date','','YES','',20,'',55,'','','yes','yes',''),(1188,'','Orders','Quantity Received','Quantity_Received','Hidden','',35,'Orders_Quantity_Received','int(11)','','NO','0',20,'',55,'','','yes','no',''),(1189,'','Orders','Expense Code','Expense_Code','Hidden','',36,'Expense_Code','text','','YES','',20,'',55,'','','yes','no',''),(1190,'','Orders','Expense Type','Expense_Type','Hidden','',37,'Expense_Type','enum(\'Reagents\',\'Equip - C\',\'Equip -M\',\'Glass\',\'Plastics\',\'Kits\',\'Service\',\'Other\')','','YES','',20,'',55,'','','yes','no',''),(1191,'','Orders','Item Unit','Item_Unit','Hidden','',38,'Item_Unit','enum(\'EA\',\'CS\',\'BX\',\'PK\',\'RL\',\'HR\')','','YES','',20,'',55,'','','yes','no',''),(1192,'','Orders','PO Number','PO_Number','Hidden','',39,'PO_Number','text','','YES','',20,'',55,'','','yes','no',''),(1193,'','Orders','old Expense','old_Expense','Hidden','',40,'old_Expense','text','','YES','',20,'',55,'','','yes','no',''),(1194,'','Orders','old Org Name','old_Org_Name','Hidden','',41,'old_Org_Name','text','','YES','',20,'',55,'','','yes','no',''),(1195,'Brief Name used to refer to company (eg. ABI)','Organization','Name','Name','Mandatory','',1,'Organization_Name','varchar(80)','MUL','YES','',20,'^.{0,80}$',56,'','','yes','no',''),(1196,'Full Name used to refer to company (eg. Applied Biosystems)','Organization','FullName','FullName','','',2,'Organization_FullName','text','','YES','',20,'',56,'','','yes','no',''),(1197,'Type of Relationship this organization has with us','Organization','Type','Type','Mandatory','',3,'Organization_Type','set(\'Manufacturer\',\'Collaborator\')','','YES','',20,'',56,'','','yes','no',''),(1198,'','Organization','Address','Address','','',4,'Address','text','','YES','',20,'',56,'','','yes','no',''),(1199,'','Organization','City','City','','',5,'City','text','','YES','',20,'',56,'','','yes','no',''),(1200,'','Organization','State','State','','',6,'State','text','','YES','',20,'',56,'','','yes','no',''),(1201,'','Organization','Phone','Phone','','',7,'Phone','text','','YES','',20,'',56,'','','yes','no',''),(1202,'','Organization','Fax','Fax','','',8,'Fax','text','','YES','',20,'',56,'','','yes','no',''),(1203,'','Organization','Email','Email','','',9,'Email','text','','YES','',20,'',56,'','','yes','no',''),(1204,'','Organization','Zip','Zip','Hidden','',10,'Zip','text','','YES','',20,'',56,'','','yes','no',''),(1205,'','Organization','Country','Country','','',11,'Country','text','','YES','Canada',20,'',56,'','','yes','no',''),(1206,'','Organization','Notes','Notes','Hidden','',12,'Notes','text','','YES','',20,'',56,'','','yes','no',''),(1207,'','Organization','Organization ID','ID','Primary','Organization_Name',13,'Organization_ID','int(11)','PRI','NO','',20,'',56,'','','yes','no',''),(1208,'','Organization','Website','Website','','',14,'Website','text','','YES','',20,'',56,'','','yes','no',''),(1209,'','Parameter','Standard Solution','Standard_Solution__ID','','Standard_Solution_ID',1,'FK_Standard_Solution__ID','int(11)','MUL','YES','',20,'',57,'Standard_Solution.Standard_Solution_ID','','yes','yes',''),(1210,'(as per formula) - multiple variable names are appended with an index (eg. v1, v2, v3 - where v is a variable in the formula)','Parameter','Name','Name','','',2,'Parameter_Name','varchar(40)','','YES','',20,'^.{0,40}$',57,'','','yes','yes',''),(1211,'(The name of the individual reagents or the variable)','Parameter','Description','Description','','',3,'Parameter_Description','text','','YES','',20,'',57,'','','yes','yes',''),(1212,'','Parameter','Value','Value','','',4,'Parameter_Value','float','','YES','',20,'',57,'','','yes','yes',''),(1213,'(Multiple parameters vary for each reagent.  Names for these parameters should consist of the name used in the formula followed by an integer (eg v1,v2,v3 - where v is a variable in the formula)','Parameter','Type','Type','','',5,'Parameter_Type','enum(\'Static\',\'Multiple\',\'Variable\',\'Hidden\')','','YES','',20,'',57,'','','yes','yes',''),(1214,'','Parameter','Parameter ID','ID','Primary','Parameter_Name',6,'Parameter_ID','int(11)','PRI','NO','',20,'',57,'','','yes','yes',''),(1215,'for Multiple types ONLY - Format requirement for reagent name (eg. Water|H20 for multiple possibilities)','Parameter','Format','Format','','',7,'Parameter_Format','text','','YES','',20,'',57,'','','yes','yes',''),(1216,'for Multiple types ONLY - (only relevant for multiple types if used)','Parameter','Units','Units','','',8,'Parameter_Units','enum(\'ml\',\'ul\',\'mg\',\'ug\',\'g\',\'l\')','','YES','',20,'',57,'','','yes','yes',''),(1217,'for Multiple types ONLY - Type of Reagent / Solution required (generally used to require Primer/Buffer types)','Parameter','SType','SType','','',9,'Parameter_SType','enum(\'Reagent\',\'Solution\',\'Primer\',\'Buffer\',\'Matrix\')','','YES','',20,'',57,'','','yes','yes',''),(1218,'','Plate','Plate ID','ID','Primary','concat(FK_Library__Name,\'-\',Plate_Number,Parent_Quadrant,\'.\',FK_Branch__Code)',1,'Plate_ID','int(11)','PRI','NO','',20,'',59,'','','yes','no',''),(1219,'','Plate','Number','Number','','',3,'Plate_Number','int(4)','MUL','NO','0',20,'',59,'','','no','yes',''),(1221,'','Plate','Application','Application','Obsolete','',6,'Plate_Application','enum(\'Sequencing\',\'PCR\',\'Mapping\',\'Gene Expression\',\'Affymetrix\')','','YES','Sequencing',20,'',59,'','','yes','no',''),(1222,'','Plate','Created','Created','','',7,'Plate_Created','datetime','MUL','YES','0000-00-00 00:00:00',20,'',59,'','','no','no',''),(1223,'','Plate','Container Format','Format__ID','Mandatory','Plate_Format_ID',9,'FK_Plate_Format__ID','int(11)','MUL','YES','',20,'',59,'Plate_Format.Plate_Format_ID','','no','yes',''),(1224,'','Plate','Size','Size','','',10,'Plate_Size','enum(\'1-well\',\'8-well\',\'16-well\',\'32-well\',\'48-well\',\'64-well\',\'80-well\',\'96-well\',\'384-well\',\'1.5 ml\',\'50 ml\',\'15 ml\',\'5 ml\',\'2 ml\',\'0.5 ml\',\'0.2 ml\')','','YES','',20,'',59,'','','no','yes',''),(1225,'','Plate','Parent Plate','Parent_Plate__ID','','Plate_ID',13,'FKParent_Plate__ID','int(11)','MUL','YES','',20,'',59,'Plate.Plate_ID','','no','no',''),(1229,'','Plate','Status','Status','Mandatory','',15,'Plate_Status','enum(\'Active\',\'Pre-Printed\',\'Reserved\',\'Temporary\',\'Failed\',\'Thrown Out\',\'Exported\',\'Archived\',\'On Hold\')','MUL','YES','Active',20,'',59,'','','no','no',''),(1230,'','Plate','Comments','Comments','','',24,'Plate_Comments','text','','NO','',20,'',59,'','','yes','yes',''),(1231,'','Plate','Test Status','Test_Status','','',18,'Plate_Test_Status','enum(\'Test\',\'Production\')','','YES','Production',20,'',59,'','','yes','no',''),(1233,'','Plate_Format','Plate Format ID','ID','Primary','CASE WHEN Plate_Format_Size<>\'\' THEN concat(Plate_Format_Size,\' \',Plate_Format_Type) ELSE Plate_Format_Type END',1,'Plate_Format_ID','int(11)','PRI','NO','',20,'',60,'','','yes','no',''),(1234,'','Plate_Format','Type','Type','Mandatory','',2,'Plate_Format_Type','char(40)','MUL','YES','',20,'',60,'','','yes','no',''),(1235,'','Plate_Format','Size','Size','Mandatory','',3,'Plate_Format_Size','enum(\'1-well\',\'8-well\',\'96-well\',\'384-well\',\'1.5 ml\',\'50 ml\',\'15 ml\',\'5 ml\',\'2 ml\',\'0.5 ml\',\'0.2 ml\')','','YES','96-well',20,'',60,'','','yes','no',''),(1236,'','Plate_Format','Status','Status','Mandatory','',4,'Plate_Format_Status','enum(\'Active\',\'Inactive\')','','YES','',20,'',60,'','','yes','no',''),(1237,'','Plate_Format','Barcode Label','Barcode_Label__ID','Mandatory,ViewLink','Barcode_Label_ID',5,'FK_Barcode_Label__ID','int(11)','MUL','YES','',20,'',60,'Barcode_Label.Barcode_Label_ID','','yes','no',''),(1238,'','Plate_Set','Plate Set ID','ID','Primary','',1,'Plate_Set_ID','int(4)','PRI','NO','',20,'',61,'','','yes','no',''),(1239,'','Plate_Set','Number','Number','','Plate_Set_Number',3,'Plate_Set_Number','int(11)','MUL','YES','',20,'',61,'','','yes','no',''),(1240,'','Plate_Tube','Plate Tube ID','ID','Primary','',1,'Plate_Tube_ID','int(11)','PRI','NO','',20,'',62,'','','yes','no',''),(1241,'','Pool','Pool ID','ID','Primary','',1,'Pool_ID','int(11)','PRI','NO','',20,'',11,'','','yes','no',''),(1243,'','Pool','Description','Description','','',3,'Pool_Description','text','','NO','',20,'',11,'','','yes','no',''),(1244,'','Pool','Date','Date','','',6,'Pool_Date','date','','NO','0000-00-00',20,'',11,'','','yes','yes',''),(1245,'','Pool','Comments','Comments','','',7,'Pool_Comments','text','','YES','',20,'',11,'','','yes','no',''),(1264,'','Primer','Name','Name','Mandatory','',1,'Primer_Name','varchar(40)','UNI','NO','',20,'^.{0,40}$',64,'','','yes','no',''),(1265,'','Primer','Sequence','Sequence','','',2,'Primer_Sequence','text','','NO','',20,'',64,'','','yes','no',''),(1266,'','Primer','Purity','Purity','','',3,'Purity','text','','YES','',20,'',64,'','','yes','no',''),(1267,'','Primer','Tm1','Tm1','','',4,'Tm1','int(2)','','YES','',20,'',64,'','','yes','no',''),(1268,'','Primer','Tm50','Tm50','','',5,'Tm50','int(2)','','YES','',20,'',64,'','','yes','no',''),(1269,'','Primer','GC Percent','GC_Percent','','',6,'GC_Percent','int(2)','','YES','',20,'',64,'','','yes','no',''),(1270,'','Primer','Coupling Eff','Coupling_Eff','','',7,'Coupling_Eff','float(10,2)','','YES','',20,'',64,'','','yes','no',''),(1271,'Note: only Standard Primers will show up in auto-generated menus','Primer','Type','Type','Mandatory','',8,'Primer_Type','enum(\'Standard\',\'Custom\',\'Oligo\',\'Amplicon\',\'Adapter\')','','YES','',20,'',64,'','','yes','no',''),(1272,'','Primer','Primer ID','ID','Primary','Primer_Name',9,'Primer_ID','int(2)','PRI','NO','',20,'',64,'','','yes','no',''),(1273,'','Primer','OrderDateTime','OrderDateTime','','',10,'Primer_OrderDateTime','datetime','','YES','',20,'',64,'','','yes','yes',''),(1274,'','Primer','External Order Number','External_Order_Number','','',11,'Primer_External_Order_Number','varchar(80)','','YES','',20,'^.{0,80}$',64,'','','yes','no',''),(1275,'','Primer_Info','Primer Info ID','ID','Primary','',5,'Primer_Info_ID','int(11)','PRI','NO','',20,'',65,'','','yes','no',''),(1276,'','Project','Name','Name','Mandatory','',1,'Project_Name','varchar(40)','UNI','NO','',20,'^.{1,40}$',66,'','','yes','yes',''),(1277,'','Project','Description','Description','','',2,'Project_Description','text','','YES','',20,'',66,'','','yes','no',''),(1278,'','Project','Type','Type','Obsolete','',3,'Project_Type','enum(\'EST\',\'EST+\',\'SAGE\',\'cDNA\',\'PCR\',\'PCR Product\',\'Genomic Clone\',\'Other\',\'Test\')','','YES','',20,'',66,'','','yes','no',''),(1279,'','Project','Funding','Funding__ID','Mandatory,NewLink','Funding_ID',4,'FK_Funding__ID','int(11)','MUL','YES','',20,'',66,'Funding.Funding_ID','','yes','yes',''),(1280,'This is the name of the subdirectory within the Projects directory.<BR>It is where the data will be stored.\n(It must be unique with no spaces)<BR><B>You may simply use the project name itself, but remember to replace spaces with underscores</B>','Project','Path','Path','Mandatory','',5,'Project_Path','varchar(80)','MUL','YES','',20,'^w{3,80}$',66,'','','no','yes',''),(1281,'','Project','Initiated','Initiated','','',6,'Project_Initiated','date','','NO','0000-00-00',20,'',66,'','','yes','yes',''),(1282,'','Project','Completed','Completed','','',7,'Project_Completed','date','','YES','0000-00-00',20,'',66,'','','yes','yes',''),(1283,'','Project','Status','Status','Mandatory','',8,'Project_Status','enum(\'Active\',\'Inactive\',\'Completed\')','','YES','Active',20,'',66,'','','yes','yes',''),(1284,'','Project','Project ID','ID','Primary','Project_Name',9,'Project_ID','int(11)','PRI','NO','',20,'',66,'','','yes','no',''),(1285,'','Protocol_Step','Number','Number','Mandatory','',1,'Protocol_Step_Number','int(11)','','YES','',20,'',67,'','','yes','yes',''),(1286,'','Protocol_Step','Name','Name','Mandatory','',2,'Protocol_Step_Name','varchar(80)','MUL','NO','',20,'^.{0,80}$',67,'','','yes','yes',''),(1287,'','Protocol_Step','Instructions','Instructions','','',3,'Protocol_Step_Instructions','text','','YES','',20,'',67,'','','yes','yes',''),(1288,'','Protocol_Step','Protocol Step ID','ID','Primary','concat(Protocol_Step_ID,\': \',Protocol_Step_Number,\'-\',Protocol_Step_Name',4,'Protocol_Step_ID','int(11)','PRI','NO','',20,'',67,'','','yes','yes',''),(1289,'','Protocol_Step','Defaults','Defaults','','',5,'Protocol_Step_Defaults','text','','YES','',20,'',67,'','','yes','yes',''),(1290,'','Protocol_Step','Input','Input','','',6,'Input','text','','YES','',20,'',67,'','','yes','yes',''),(1291,'','Protocol_Step','Scanner','Scanner','','',7,'Scanner','tinyint(3) unsigned','','YES','1',20,'',67,'','','yes','yes',''),(1292,'','Protocol_Step','Message','Message','','',8,'Protocol_Step_Message','varchar(40)','','YES','',20,'^.{0,40}$',67,'','','yes','yes',''),(1293,'','Protocol_Step','Changed','Changed','','',10,'Protocol_Step_Changed','date','','YES','<TODAY>',20,'',67,'','','yes','yes',''),(1294,'','Protocol_Step','Input Format','Input_Format','','',11,'Input_Format','text','','NO','',20,'',67,'','','yes','yes',''),(1295,'Reference to Protocol from which Step is derived','Protocol_Step','Lab Protocol','Lab_Protocol__ID','Mandatory','Lab_Protocol_ID',12,'FK_Lab_Protocol__ID','int(11)','MUL','YES','',20,'',67,'Lab_Protocol.Lab_Protocol_ID','','yes','yes',''),(1296,'','Protocol_Tracking','Protocol Tracking ID','ID','Primary','',1,'Protocol_Tracking_ID','int(11)','PRI','NO','',20,'',68,'','','yes','no',''),(1297,'','Protocol_Tracking','Title','Title','','',2,'Protocol_Tracking_Title','char(20)','','YES','',20,'',68,'','','yes','no',''),(1298,'','Protocol_Tracking','Step Name','Step_Name','','',3,'Protocol_Tracking_Step_Name','char(40)','','YES','',20,'',68,'','','yes','no',''),(1299,'','Protocol_Tracking','Tracking Order','Tracking_Order','','',4,'Protocol_Tracking_Order','int(11)','','YES','',20,'',68,'','','yes','no',''),(1300,'','Protocol_Tracking','Type','Type','','',5,'Protocol_Tracking_Type','enum(\'Step\',\'Plasticware\')','','YES','',20,'',68,'','','yes','no',''),(1301,'','Protocol_Tracking','Status','Status','','',6,'Protocol_Tracking_Status','enum(\'Active\',\'InActive\')','','YES','',20,'',68,'','','yes','no',''),(1302,'','Rack','Rack ID','ID','Primary','Rack_Alias',1,'Rack_ID','int(4)','PRI','NO','',20,'',69,'','','yes','no',''),(1305,'','ReArray','Source Plate','Source_Plate__ID','','Plate_ID',2,'FKSource_Plate__ID','int(11)','MUL','NO','0',20,'',70,'Plate.Plate_ID','','yes','yes',''),(1306,'','ReArray','Source Well','Source_Well','Mandatory','',3,'Source_Well','char(3)','','NO','',20,'',70,'','','yes','yes',''),(1308,'','ReArray','Target Well','Target_Well','Mandatory','',5,'Target_Well','char(3)','MUL','NO','',20,'',70,'','','yes','yes',''),(1313,'','ReArray','ReArray ID','ID','Primary','',10,'ReArray_ID','int(11)','PRI','NO','',20,'',70,'','','yes','no',''),(1316,'','Restriction_Site','Name','Name','Mandatory','',1,'Restriction_Site_Name','varchar(20)','UNI','NO','',20,'^.{0,20}$',71,'','','yes','no',''),(1317,'','Restriction_Site','Recognition Sequence','Recognition_Sequence','Mandatory','',2,'Recognition_Sequence','text','','YES','',20,'',71,'','','yes','no',''),(1375,'','Service','Equipment  Type','Equipment__Type','','Equipment_Type',2,'FK_Equipment__Type','varchar(40)','MUL','YES','',20,'',75,'Equipment.Equipment_Type','','yes','no',''),(1376,'','Service','Service Interval','Service_Interval','','',3,'Service_Interval','tinyint(4)','','YES','',20,'',75,'','','yes','no',''),(1377,'','Service','Interval Frequency','Interval_Frequency','','',4,'Interval_Frequency','enum(\'Year\',\'Month\',\'Week\',\'Day\')','','YES','',20,'',75,'','','yes','no',''),(1378,'','Service','Name','Name','','',5,'Service_Name','text','','YES','',20,'',75,'','','yes','no',''),(1379,'','Service','Service ID','ID','Primary','Service_Name',6,'Service_ID','int(11)','PRI','NO','',20,'',75,'','','yes','no',''),(1380,'','Service_Contract','BeginDate','BeginDate','','',1,'Service_Contract_BeginDate','date','','YES','',20,'',76,'','','yes','yes',''),(1381,'','Service_Contract','ExpiryDate','ExpiryDate','','',2,'Service_Contract_ExpiryDate','date','','YES','',20,'',76,'','','yes','yes',''),(1382,'','Service_Contract','Number','Number','','',6,'Service_Contract_Number','int(11)','','YES','',20,'',76,'','','yes','no',''),(1383,'','Service_Contract','Number in Batch','Number_in_Batch','','',7,'Service_Contract_Number_in_Batch','int(11)','','YES','',20,'',76,'','','yes','no',''),(1384,'','Service_Contract','Service Contract ID','ID','Primary','',8,'Service_Contract_ID','int(11)','PRI','NO','',20,'',76,'','','yes','no',''),(1391,'','Solution','Type','Type','','',2,'Solution_Type','enum(\'Reagent\',\'Solution\',\'Primer\',\'Buffer\',\'Matrix\')','','YES','',20,'',5,'','','yes','no',''),(1392,'','Solution','Quantity Used','Quantity_Used','','',3,'Quantity_Used','float','','YES','0',20,'',5,'','','yes','no',''),(1393,'','Solution','Started','Started','','',4,'Solution_Started','datetime','','YES','',20,'',5,'','','yes','no',''),(1394,'','Solution','Finished','Finished','','',5,'Solution_Finished','date','','YES','',20,'',5,'','','yes','no',''),(1395,'','Solution','Number','Number','','',6,'Solution_Number','int(11)','','YES','',20,'',5,'','','yes','no',''),(1396,'','Solution','Status','Status','','',7,'Solution_Status','enum(\'Unopened\',\'Open\',\'Finished\',\'Temporary\',\'Expired\')','','YES','Unopened',20,'',5,'','','yes','no',''),(1397,'','Solution','Stock','Stock__ID','','Stock_ID',8,'FK_Stock__ID','int(11)','MUL','YES','',20,'',5,'Stock.Stock_ID','','yes','no',''),(1398,'','Solution','Notes','Notes','','',9,'Solution_Notes','text','','YES','',20,'',5,'','','yes','no',''),(1399,'Expiry date tracked for individual reagents','Solution','Expiry','Expiry','','',10,'Solution_Expiry','date','','YES','',20,'',5,'','','yes','no',''),(1400,'','Solution','Info','Info__ID','','Solution_Info_ID',12,'FK_Solution_Info__ID','int(11)','MUL','YES','',20,'',5,'Solution_Info.Solution_Info_ID','','yes','no',''),(1401,'','Solution','Solution ID','ID','Primary','concat(\'Sol\',Solution_ID,\': \',Stock_Name,\' (\',Solution_Number,\'/\',Solution_Number_in_Batch,\')\')',1,'Solution_ID','int(11)','PRI','NO','',20,'',5,'','','yes','no',''),(1402,'','Solution','Quantity','Quantity','Hidden','',14,'Solution_Quantity','float','','YES','',20,'',5,'','','yes','no',''),(1403,'','Solution','Cost','Cost','Hidden','',15,'Solution_Cost','float','','YES','',20,'',5,'','','yes','no',''),(1404,'','Solution','Number in Batch','Number_in_Batch','Hidden','',16,'Solution_Number_in_Batch','int(11)','','YES','',20,'',5,'','','yes','no',''),(1405,'','Solution_Info','Solution Info ID','ID','Primary','concat(Solution_Info_ID,\': \',ODs,\'ODs \',nMoles,\'nM \',micrograms,\'ug\')',1,'Solution_Info_ID','int(11)','PRI','NO','',20,'',6,'','','yes','no',''),(1406,'','Solution_Info','nMoles','nMoles','','',2,'nMoles','float','','YES','',20,'',6,'','','yes','no',''),(1407,'','Solution_Info','ODs','ODs','','',3,'ODs','float','','YES','',20,'',6,'','','yes','no',''),(1408,'','Solution_Info','micrograms','micrograms','','',4,'micrograms','float','','YES','',20,'',6,'','','yes','no',''),(1409,'Name for Resulting solution','Standard_Solution','Name','Name','Mandatory','',1,'Standard_Solution_Name','varchar(40)','MUL','YES','',20,'^.{0,40}$',58,'','','yes','yes',''),(1410,'Formula to be calculated for each of parameters indicated (\'wells\' will be replaced by the number of samples/wells) eg: V*wells + Extra*wells + DV','Standard_Solution','Formula','Formula','','',2,'Standard_Solution_Formula','text','','YES','',20,'',58,'','','yes','yes',''),(1411,'Number of different reagents to be prompted for','Standard_Solution','Parameters','Parameters','','',3,'Standard_Solution_Parameters','int(11)','','YES','',20,'',58,'','','yes','yes',''),(1412,'Message seen by users (everything to the right of the = sign will be evaluated)','Standard_Solution','Message','Message','','',4,'Standard_Solution_Message','text','','YES','',20,'',58,'','','yes','yes',''),(1413,'','Standard_Solution','Status','Status','','',5,'Standard_Solution_Status','enum(\'Active\',\'Inactive\',\'Development\')','','YES','',20,'',58,'','','yes','yes',''),(1414,'','Standard_Solution','Standard Solution ID','ID','Primary','Standard_Solution_Name',6,'Standard_Solution_ID','int(11)','PRI','NO','',20,'',58,'','','yes','yes',''),(1415,'Name for Stock. If your Primer name does not appear in the dropdown list add a New Primer definition from the Solutions homepage','Stock','Name','Name','Mandatory,NewLink,Searchable','',2,'Stock_Name','varchar(80)','MUL','YES','',20,'^.{0,80}$',7,'','','yes','no',''),(1416,'','Stock','Source','Source','Mandatory,Obsolete','',11,'Stock_Source','enum(\'Box\',\'Order\',\'Sample\',\'Made in House\')','','YES','',20,'',7,'','','yes','no',''),(1417,'','Stock','Type','Type','Mandatory,Obsolete','',12,'Stock_Type','enum(\'Solution\',\'Reagent\',\'Kit\',\'Box\',\'Microarray\',\'Equipment\',\'Service_Contract\',\'Computer_Equip\',\'Misc_Item\')','','YES','',20,'',7,'','','yes','no',''),(1418,'Size of each Item received','Stock','Size','Size','Mandatory,Obsolete','',14,'Stock_Size','float','','YES','',20,'[1-9]+',7,'','','yes','no',''),(1419,'','Stock','Size Units','Size_Units','Obsolete','',15,'Stock_Size_Units','enum(\'mL\',\'uL\',\'litres\',\'mg\',\'grams\',\'kg\',\'pcs\',\'boxes\',\'tubes\',\'rxns\',\'n/a\')','','YES','',20,'',7,'','','yes','no',''),(1420,'Catalog Number - should be identical for ALL items in this batch','Stock','Catalog Number','Catalog_Number','Obsolete','',5,'Stock_Catalog_Number','varchar(80)','MUL','YES','',20,'^.{0,80}$',7,'','','yes','no',''),(1421,'Lot Number - should be identical for ALL items in this batch','Stock','Lot Number','Lot_Number','','',6,'Stock_Lot_Number','varchar(80)','MUL','YES','',20,'^.{0,80}$',7,'','','yes','no',''),(1422,'','Stock','Received','Received','Mandatory','',16,'Stock_Received','date','','YES','<TODAY>',20,'',7,'','','yes','no',''),(1423,'','Stock','Orders','Orders__ID','Hidden','Orders_ID',18,'FK_Orders__ID','int(11)','MUL','YES','',20,'',7,'Orders.Orders_ID','','yes','no',''),(1424,'Number of Items Received = NUMBER OF BARCODES that will be made','Stock','Number in Batch','Number_in_Batch','Mandatory','',13,'Stock_Number_in_Batch','int(11)','','YES','',20,'[1-9]+',7,'','','yes','no',''),(1425,'','Stock','Box','Box__ID','','Box_ID',19,'FK_Box__ID','int(11)','MUL','YES','',20,'',7,'Box.Box_ID','','yes','no',''),(1426,'','Stock','Stock ID','ID','Primary','concat(Stock_ID,\': \',Stock_Name)',1,'Stock_ID','int(11)','PRI','NO','',20,'',7,'','','yes','no',''),(1427,'','Stock','Description','Description','Obsolete','',3,'Stock_Description','text','','YES','',20,'',7,'','','yes','no',''),(1428,'','Stock','Cost','Cost','','',20,'Stock_Cost','float','','YES','',20,'',7,'','','yes','no',''),(1429,'','Suggestion','Text','Text','','',1,'Suggestion_Text','text','','YES','',20,'',78,'','','yes','no',''),(1430,'','Suggestion','Date','Date','','',2,'Suggestion_Date','date','','YES','<TODAY>',20,'',78,'','','yes','no',''),(1431,'','Suggestion','Response Text','Response_Text','','',4,'Response_Text','text','','YES','',20,'',78,'','','yes','no',''),(1432,'','Suggestion','Implementation Date','Implementation_Date','','',5,'Implementation_Date','date','','YES','',20,'',78,'','','yes','no',''),(1433,'','Suggestion','Priority','Priority','','',6,'Priority','enum(\'Urgent\',\'Useful\',\'Wish\')','','NO','Urgent',20,'',78,'','','yes','no',''),(1434,'','Suggestion','Suggestion ID','ID','Primary','',7,'Suggestion_ID','int(11)','PRI','NO','',20,'',78,'','','yes','no',''),(1436,'','Transposon','Name','Name','','',1,'Transposon_Name','varchar(80)','','NO','',20,'^.{0,80}$',12,'','','yes','no',''),(1437,'','Transposon','Description','Description','','',3,'Transposon_Description','text','','YES','',20,'',12,'','','yes','no',''),(1438,'','Transposon','Sequence','Sequence','','',4,'Transposon_Sequence','text','','YES','',20,'',12,'','','yes','no',''),(1439,'','Transposon','Source ID','Source_ID','','',5,'Transposon_Source_ID','text','','YES','',20,'',12,'','','yes','no',''),(1440,'','Transposon','Transposon ID','ID','Primary','concat(Transposon_ID,\': \',Transposon_Name)',7,'Transposon_ID','int(11)','PRI','NO','',20,'',12,'','','yes','no',''),(1444,'','Tube','Quantity','Quantity','Hidden','',4,'Tube_Quantity','float','','YES','',20,'',79,'','','yes','no',''),(1452,'','Tube','Tube ID','ID','Primary','',12,'Tube_ID','int(11)','PRI','NO','',20,'',79,'','','yes','no',''),(1453,'','Tube_Application','Tube Application ID','ID','Primary','',1,'Tube_Application_ID','int(11)','PRI','NO','',20,'',80,'','','yes','no',''),(1454,'','Tube_Application','Solution','Solution__ID','','Solution_ID',2,'FK_Solution__ID','int(11)','MUL','YES','',20,'',80,'Solution.Solution_ID','','yes','no',''),(1455,'','Tube_Application','Tube','Tube__ID','','Tube_ID',3,'FK_Tube__ID','int(11)','MUL','YES','',20,'',80,'Tube.Tube_ID','','yes','no',''),(1456,'','Tube_Application','Comments','Comments','','',4,'Comments','text','','YES','',20,'',80,'','','yes','no',''),(1457,'','Vector','Name','Name','Hidden,Obsolete','',1,'Vector_Name','varchar(40)','','NO','',20,'^.{0,40}$',81,'','','yes','no',''),(1458,'','Vector','Sequence File','Sequence_File','Hidden,Obsolete','',2,'Vector_Sequence_File','text','','NO','',20,'',81,'','','yes','no',''),(1459,'','Vector','Manufacturer','Manufacturer','Hidden,Obsolete','',3,'Vector_Manufacturer','text','','YES','',20,'',81,'','','yes','no',''),(1460,'','Vector','Antibiotic Marker','Antibiotic_Marker','Hidden,Obsolete','',4,'Antibiotic_Marker','enum(\'Ampicillin\',\'Zeocin\',\'Kanamycin\',\'Chloramphenicol\',\'Tetracycline\',\'N/A\')','','YES','',20,'',81,'','','yes','no',''),(1461,'','Vector','Sequence Source','Sequence_Source','','',5,'Vector_Sequence_Source','text','','YES','',20,'',81,'','','yes','no',''),(1462,'','Vector','Inducer','Inducer','','',6,'Inducer','varchar(40)','','YES','',20,'^.{0,40}$',81,'','','yes','no',''),(1463,'','Vector','Substrate','Substrate','','',7,'Substrate','varchar(40)','','YES','',20,'^.{0,40}$',81,'','','yes','no',''),(1464,'','Vector','Catalog Number','Catalog_Number','','',8,'Vector_Catalog_Number','text','','YES','',20,'',81,'','','yes','no',''),(1465,'','Vector','Vector ID','ID','Primary','Vector_Name',9,'Vector_ID','int(11)','PRI','NO','',20,'',81,'','','yes','no',''),(1466,'','VectorPrimer','Vector','Vector__Name','Mandatory,NewLink,ViewLink','Vector_Name',1,'FK_Vector__Name','varchar(80)','MUL','YES','',20,'',82,'Vector.Vector_Name','','yes','no',''),(1467,'','VectorPrimer','Primer','Primer__Name','Mandatory,NewLink','Primer_Name',2,'FK_Primer__Name','varchar(40)','MUL','YES','',20,'',82,'Primer.Primer_Name','','yes','no',''),(1468,'','VectorPrimer','Direction','Direction','Mandatory','',3,'Direction','enum(\'3\'\'\',\'5\'\'\',\'N/A\',\'3prime\',\'5prime\')','','YES','',20,'',82,'','','yes','no',''),(1469,'','VectorPrimer','VectorPrimer ID','ID','Primary','',4,'VectorPrimer_ID','int(10) unsigned','PRI','NO','',20,'',82,'','','yes','no',''),(1470,'','Warranty','BeginDate','BeginDate','','',1,'Warranty_BeginDate','date','','YES','',20,'',83,'','','yes','no',''),(1471,'','Warranty','ExpiryDate','ExpiryDate','','',2,'Warranty_ExpiryDate','date','','YES','',20,'',83,'','','yes','no',''),(1472,'','Warranty','Organization','Organization__ID','','Organization_ID',3,'FK_Organization__ID','int(11)','MUL','YES','',20,'',83,'Organization.Organization_ID','','yes','no',''),(1473,'','Warranty','Equipment','Equipment__ID','ViewLink','Equipment_ID',4,'FK_Equipment__ID','int(11)','MUL','YES','',20,'',83,'Equipment.Equipment_ID','','yes','no',''),(1474,'','Warranty','Conditions','Conditions','','',5,'Warranty_Conditions','text','','YES','',20,'',83,'','','yes','no',''),(1475,'','Warranty','Warranty ID','ID','Primary','',6,'Warranty_ID','int(11)','PRI','NO','',20,'',83,'','','yes','no',''),(1476,'','Well_Lookup','Plate 384','Plate_384','Primary','',1,'Plate_384','char(3)','PRI','NO','',20,'',84,'','','yes','no',''),(1477,'','Well_Lookup','Plate 96','Plate_96','','',2,'Plate_96','char(3)','MUL','NO','',20,'',84,'','','yes','no',''),(1478,'','Well_Lookup','Quadrant','Quadrant','','',3,'Quadrant','char(1)','','NO','',20,'',84,'','','yes','no',''),(1504,'','Microtiter','Microtiter ID','ID','Primary','',1,'Microtiter_ID','int(11)','PRI','NO','',20,'',86,'','','yes','no',''),(1505,'','Microtiter','Plates','Plates','','',2,'Plates','int(11)','','YES','',20,'',86,'','','yes','no',''),(1506,'','Microtiter','Plate Size','Plate_Size','','',3,'Plate_Size','enum(\'96-well\',\'384-well\')','','YES','',20,'',86,'','','yes','no',''),(1507,'','Microtiter','Plate Catalog Number','Plate_Catalog_Number','','',4,'Plate_Catalog_Number','varchar(40)','','YES','',20,'^.{0,40}$',86,'','','yes','no',''),(1508,'','Microtiter','VolumePerWell','VolumePerWell','Hidden','',5,'VolumePerWell','int(11)','','YES','',20,'',86,'','','yes','no',''),(1509,'','Microtiter','Cell Catalog Number','Cell_Catalog_Number','','',6,'Cell_Catalog_Number','varchar(40)','','YES','',20,'^.{0,40}$',86,'','','yes','no',''),(1511,'','Ligation','Ligation ID','ID','Primary','',1,'Ligation_ID','int(11)','PRI','NO','',20,'',87,'','','yes','no',''),(1512,'','Ligation','Volume','Volume','Hidden','',2,'Ligation_Volume','int(11)','','YES','',20,'',87,'','','yes','no',''),(1515,'','Xformed_Cells','Xformed Cells ID','ID','Primary','',1,'Xformed_Cells_ID','int(11)','PRI','NO','',20,'',88,'','','yes','no',''),(1516,'','Xformed_Cells','VolumePerTube','VolumePerTube','Hidden','',2,'VolumePerTube','int(11)','','YES','',20,'',88,'','','yes','no',''),(1517,'Number of Tubes','Xformed_Cells','Tubes','Tubes','','',3,'Tubes','int(11)','','YES','',20,'',88,'','','yes','no',''),(1518,'','Xformed_Cells','cfu/ul','EstimatedClones','Mandatory','',4,'EstimatedClones','int(11)','','YES','',20,'',88,'','','yes','no',''),(1519,'','Xformed_Cells','Cell Catalog Number','Cell_Catalog_Number','','',5,'Cell_Catalog_Number','varchar(40)','','YES','',20,'^.{0,40}$',88,'','','yes','no',''),(1522,'','Submission','Submission ID','ID','Primary','',1,'Submission_ID','int(11)','PRI','NO','',20,'',89,'','','yes','no',''),(1524,'','Submission','Status','Status','','',3,'Submission_Status','enum(\'Draft\',\'Submitted\',\'Approved\',\'Completed\',\'Cancelled\',\'Rejected\')','','YES','',20,'',89,'','','yes','no',''),(1525,'','Submission','Contact','Contact__ID','NewLink','Contact_ID',4,'FK_Contact__ID','int(11)','MUL','YES','',20,'',89,'Contact.Contact_ID','','yes','no',''),(1529,'','SAGE_Library','SAGE Library ID','ID','Primary','',1,'SAGE_Library_ID','int(11)','PRI','NO','',0,'',90,'','','yes','no',''),(1534,'','SAGE_Library','Concatamer Size Fraction','Concatamer_Size_Fraction','Mandatory','',6,'Concatamer_Size_Fraction','int(11)','','NO','',0,'',90,'','','yes','no',''),(1538,'','cDNA_Library','cDNA Library ID','ID','Primary','',1,'cDNA_Library_ID','int(11)','PRI','NO','',0,'',91,'','','yes','no',''),(1540,'','cDNA_Library','5Prime Insert Site Enzyme','5Prime_Insert_Site_Enzyme','Hidden','',4,'5Prime_Insert_Site_Enzyme','varchar(40)','','NO','',0,'^.{0,40}$',91,'','','yes','no',''),(1541,'','cDNA_Library','3Prime Insert Site Enzyme','3Prime_Insert_Site_Enzyme','Hidden','',5,'3Prime_Insert_Site_Enzyme','varchar(40)','','NO','',0,'^.{0,40}$',91,'','','yes','no',''),(1542,'','cDNA_Library','Blue White Selection','Blue_White_Selection','Mandatory','',6,'Blue_White_Selection','enum(\'Yes\',\'No\')','','NO','No',0,'',91,'','','yes','no',''),(1543,'','Genomic_Library','Genomic Library ID','ID','Primary','',1,'Genomic_Library_ID','int(11)','PRI','NO','',0,'',92,'','','yes','no',''),(1545,'Type of vector (one of Plasmid, Fosmid, Cosmid, or BAC)','Genomic_Library','Vector Type','Vector_Type','Hidden','',3,'Vector_Type','enum(\'Unspecified\',\'Plasmid\',\'Fosmid\',\'Cosmid\',\'BAC\')','','NO','Plasmid',0,'',92,'','','yes','yes',''),(1546,'Insert Size Enzyme','Genomic_Library','Insert Site Enzyme','Insert_Site_Enzyme','Hidden','',4,'Insert_Site_Enzyme','varchar(40)','','NO','',0,'^.{0,40}$',92,'','','yes','yes',''),(1547,'Method of DNA shearing. One of Mechanical, Enzyme)','Genomic_Library','DNA Shearing Method','DNA_Shearing_Method','Mandatory','',5,'DNA_Shearing_Method','enum(\'Unspecified\',\'Mechanical\',\'Enzyme\')','','NO','Unspecified',0,'',92,'','','yes','yes',''),(1548,'','Genomic_Library','DNA Shearing Enzyme','DNA_Shearing_Enzyme','Hidden','',6,'DNA_Shearing_Enzyme','varchar(40)','','YES','',0,'^.{0,40}$',92,'','','yes','yes',''),(1549,'Number of 384-well plates to pick','Genomic_Library','384 Well Plates To Pick','384_Well_Plates_To_Pick','Hidden','',7,'384_Well_Plates_To_Pick','int(11)','','NO','',0,'',92,'','','yes','no',''),(1550,'','PCR_Library','PCR Library ID','ID','Primary','',1,'PCR_Library_ID','int(11)','PRI','NO','',0,'',93,'','','yes','no',''),(1552,'Species involved','PCR_Library','Species','Species','Mandatory,Obsolete','',3,'Species','varchar(40)','','YES','',0,'^.{0,40}$',93,'','','yes','no',''),(1553,'Cleanup procedure used for this library','PCR_Library','Cleanup Procedure','Cleanup_Procedure','Mandatory','',4,'Cleanup_Procedure','text','','NO','',0,'',93,'','','yes','no',''),(1554,'Product size for this library','PCR_Library','PCR Product Size','PCR_Product_Size','Mandatory','',5,'PCR_Product_Size','int(11)','','NO','',0,'',93,'','','yes','no',''),(1555,'Concentration of DNA per Well','PCR_Library','Concentration Per Well ng per uL','Concentration_Per_Well','Mandatory','',6,'Concentration_Per_Well','float(10,3)','','NO','0.000',0,'',93,'','','yes','yes',''),(1556,'','Xformed_Cells','Xform Method','Xform_Method','','',8,'Xform_Method','varchar(40)','','YES','',0,'^.{0,40}$',88,'','','yes','no',''),(1557,'','Xformed_Cells','Cell Type','Cell_Type','','',9,'Cell_Type','varchar(40)','','YES','',0,'^.{0,40}$',88,'','','yes','no',''),(1558,'','Xformed_Cells','Supplier Organization','Supplier_Organization__ID','NewLink','Organization_ID',10,'FKSupplier_Organization__ID','int(11)','MUL','YES','',0,'',88,'Organization.Organization_ID','','yes','no',''),(1559,'','Xformed_Cells','Sequencing Type','Sequencing_Type','Mandatory','',11,'Sequencing_Type','enum(\'Primers\',\'Transposon\',\'Primers_and_transposon\',\'Replicates\')','','YES','',0,'',88,'','','yes','no',''),(1560,'','Xformed_Cells','384 Well Plates To Seq','384_Well_Plates_To_Seq','Hidden','',12,'384_Well_Plates_To_Seq','int(11)','','YES','',0,'',88,'','','yes','no',''),(1561,'','Microtiter','Supplier Organization','Supplier_Organization__ID','NewLink','Organization_ID',9,'FKSupplier_Organization__ID','int(11)','MUL','YES','',0,'',86,'Organization.Organization_ID','','yes','no',''),(1562,'','Microtiter','Cell Type','Cell_Type','','',10,'Cell_Type','varchar(40)','','YES','',0,'^.{0,40}$',86,'','','yes','no',''),(1563,'','Microtiter','Media Type','Media_Type','','',11,'Media_Type','varchar(40)','','YES','',0,'^.{0,40}$',86,'','','yes','no',''),(1564,'','Microtiter','Sequencing Type','Sequencing_Type','Mandatory','',12,'Sequencing_Type','enum(\'Primers\',\'Transposon\',\'Primers_and_transposon\',\'Replicates\')','','YES','',0,'',86,'','','yes','no',''),(1565,'','Microtiter','384 Well Plates To Seq','384_Well_Plates_To_Seq','Hidden','',13,'384_Well_Plates_To_Seq','int(11)','','YES','',0,'',86,'','','yes','no',''),(1566,'','Ligation','Sequencing Type','Sequencing_Type','Mandatory','',6,'Sequencing_Type','enum(\'Primers\',\'Transposon\',\'Primers_and_transposon\',\'Replicates\',\'N/A\')','','YES','',0,'',87,'','','yes','no',''),(1567,'','Ligation','384 Well Plates To Seq','384_Well_Plates_To_Seq','Hidden','',7,'384_Well_Plates_To_Seq','int(11)','','YES','',0,'',87,'','','yes','no',''),(1568,'','LibraryPrimer','Direction','Direction','Mandatory','',6,'Direction','enum(\'3prime\',\'5prime\',\'N/A\',\'Unknown\')','','YES','',20,'',41,'','','yes','no',''),(1573,'','Funding','Source','Source','Mandatory','',7,'Funding_Source','enum(\'Internal\',\'External\')','','NO','Internal',0,'',36,'','','yes','yes',''),(1574,'','Vector','Sequence','Sequence','Hidden,Obsolete','',12,'Vector_Sequence','longtext','','YES','',0,'',81,'','','yes','no',''),(1575,'','Issue','Issue ID','ID','Primary','CONCAT(Issue_ID,\': \',LEFT(Description,60),\'...\')',1,'Issue_ID','int(11)','PRI','NO','',20,'',94,'','','yes','no',''),(1576,'','Issue','Type','Type','','',2,'Type','enum(\'Reported\',\'Defect\',\'Enhancement\',\'Conformance\',\'Maintenance\',\'Requirement\',\'Work Request\',\'Ongoing Maintenance\',\'User Error\')','','YES','',20,'',94,'','','yes','no',''),(1577,'','Issue','Description','Description','','',3,'Description','text','','NO','',20,'',94,'','','yes','no',''),(1578,'','Issue','Priority','Priority','Mandatory','',4,'Priority','enum(\'Critical\',\'High\',\'Medium\',\'Low\')','MUL','NO','High',20,'',94,'','','yes','no',''),(1579,'','Issue','Severity','Severity','Hidden','',5,'Severity','enum(\'Fatal\',\'Major\',\'Minor\',\'Cosmetic\')','MUL','NO','Major',20,'',94,'','','yes','no',''),(1580,'','Issue','Status','Status','','',6,'Status','enum(\'Reported\',\'Approved\',\'Open\',\'In Process\',\'Resolved\',\'Closed\',\'Deferred\')','MUL','YES','Reported',20,'',94,'','','yes','no',''),(1581,'','Issue','Found Release','Found_Release','Hidden','',7,'Found_Release','varchar(9)','','NO','',20,'^.{0,9}$',94,'','','yes','no',''),(1582,'','Issue','Assigned Release','Assigned_Release','','',8,'Assigned_Release','varchar(9)','','YES','',20,'^.{0,9}$',94,'','','yes','no',''),(1583,'','Issue','Submitted Employee','Submitted_Employee__ID','','Employee_ID',9,'FKSubmitted_Employee__ID','int(11)','MUL','NO','',20,'',94,'Employee.Employee_ID','','yes','no',''),(1584,'','Issue','Submitted DateTime','Submitted_DateTime','','',10,'Submitted_DateTime','datetime','','NO','0000-00-00 00:00:00',20,'',94,'','','yes','no',''),(1585,'','Issue','Assigned Employee','Assigned_Employee__ID','','Employee_ID',11,'FKAssigned_Employee__ID','int(11)','MUL','YES','',20,'',94,'Employee.Employee_ID','','yes','no',''),(1586,'','Issue','Resolution','Resolution','','',12,'Resolution','enum(\'By Design\',\'Cannot Reproduce\',\'Code Fix\',\'Data Fix\',\'Do Not Fix\',\'Duplicate Issue\',\'False Submission\',\'System Fix\',\'Code Design\')','MUL','YES','',20,'',94,'','','yes','no',''),(1587,'','Issue','Last Modified','Last_Modified','Hidden','',13,'Last_Modified','datetime','','YES','',20,'',94,'','','yes','no',''),(1589,'','TraceData','TraceData ID','ID','Primary','',2,'TraceData_ID','int(11)','PRI','NO','',20,'',95,'','','yes','no',''),(1590,'','TraceData','Mirrored','Mirrored','','',3,'Mirrored','int(11)','','YES','',20,'',95,'','','yes','no',''),(1591,'','TraceData','Archived','Archived','','',4,'Archived','int(11)','','YES','',20,'',95,'','','yes','no',''),(1592,'','TraceData','Checked','Checked','','',5,'Checked','datetime','','YES','',20,'',95,'','','yes','no',''),(1593,'','TraceData','Machine','Machine','','',6,'Machine','varchar(20)','','YES','',20,'^.{0,20}$',95,'','','yes','no',''),(1594,'','TraceData','Links','Links','','',7,'Links','int(11)','','YES','',20,'',95,'','','yes','no',''),(1595,'','TraceData','Files','Files','','',8,'Files','int(11)','','YES','',20,'',95,'','','yes','no',''),(1596,'','TraceData','Broken','Broken','','',9,'Broken','int(11)','','YES','',20,'',95,'','','yes','no',''),(1597,'','TraceData','Path','Path','','',10,'Path','enum(\'\',\'Not Found\',\'OK\')','','YES','',20,'',95,'','','yes','no',''),(1598,'','TraceData','Zipped','Zipped','','',11,'Zipped','int(11)','','YES','',20,'',95,'','','yes','no',''),(1599,'','TraceData','Format','Format','','',12,'Format','varchar(20)','','YES','',20,'^.{0,20}$',95,'','','yes','no',''),(1600,'','TraceData','MirroredSize','MirroredSize','','',13,'MirroredSize','int(11)','','YES','',20,'',95,'','','yes','no',''),(1601,'','TraceData','ArchivedSize','ArchivedSize','','',14,'ArchivedSize','int(11)','','YES','',20,'',95,'','','yes','no',''),(1602,'','TraceData','ZippedSize','ZippedSize','','',15,'ZippedSize','int(11)','','YES','',20,'',95,'','','yes','no',''),(1632,'','Primer_Customization','Primer Customization ID','ID','Primary','',1,'Primer_Customization_ID','int(11)','PRI','NO','',20,'',97,'','','yes','no',''),(1633,'','Primer_Customization','Primer','Primer__Name','','Primer_Name',2,'FK_Primer__Name','varchar(40)','MUL','NO','',20,'',97,'Primer.Primer_Name','','yes','no',''),(1634,'','Primer_Customization','Tm Working','Tm_Working','','',3,'Tm_Working','float(5,2)','','YES','',20,'',97,'','','yes','no',''),(1635,'','Primer_Order','Primer Order ID','ID','Primary','',1,'Primer_Order_ID','int(11)','PRI','NO','',20,'',98,'','','yes','no',''),(1636,'','Primer_Order','Primer Name','Primer_Name','Mandatory','',2,'Primer_Name','varchar(40)','','YES','',20,'^.{0,40}$',98,'','','yes','no',''),(1637,'','Primer_Order','Order DateTime','Order_DateTime','','',3,'Order_DateTime','date','','YES','',20,'',98,'','','yes','yes',''),(1638,'(Set to \'0000-00-00\' if still on order)','Primer_Order','Received DateTime','Received_DateTime','','',4,'Received_DateTime','date','','YES','0000-00-00',20,'',98,'','','yes','yes',''),(1639,'','Primer_Order','Employee','Employee__ID','Mandatory','Employee_ID',5,'FK_Employee__ID','int(11)','MUL','YES','',20,'',98,'Employee.Employee_ID','','yes','no',''),(1640,'','Setting','Setting ID','ID','Primary','Setting_Name',1,'Setting_ID','int(11)','PRI','NO','',20,'',99,'','','yes','no',''),(1641,'','Setting','Name','Name','','',2,'Setting_Name','varchar(40)','','YES','',20,'^.{0,40}$',99,'','','yes','no',''),(1642,'','Setting','Default Setting','Default_Setting','','',3,'Setting_Default','varchar(40)','','YES','',20,'^.{0,40}$',99,'','','yes','no',''),(1643,'','Setting','Description','Description','','',4,'Setting_Description','text','','YES','',20,'',99,'','','yes','no',''),(1644,'','EmployeeSetting','EmployeeSetting ID','ID','Primary','',1,'EmployeeSetting_ID','int(11)','PRI','NO','',20,'',100,'','','yes','no',''),(1645,'','EmployeeSetting','Setting','Setting__ID','','Setting_ID',2,'FK_Setting__ID','int(11)','MUL','YES','',20,'',100,'Setting.Setting_ID','','yes','no',''),(1646,'','EmployeeSetting','Employee','Employee__ID','','Employee_ID',3,'FK_Employee__ID','int(11)','MUL','YES','',20,'',100,'Employee.Employee_ID','','yes','no',''),(1647,'','EmployeeSetting','Setting Value','Setting_Value','','',4,'Setting_Value','char(40)','','YES','',20,'',100,'','','yes','no',''),(1651,'','Clone_Alias','Clone Alias ID','ID','Primary','',1,'Clone_Alias_ID','int(11)','PRI','NO','',20,'',102,'','','yes','no',''),(1652,'','Clone_Alias','Clone Sample','Clone_Sample__ID','','Clone_Sample_ID',2,'FK_Clone_Sample__ID','int(11)','MUL','NO','',20,'',102,'Clone_Sample.Clone_Sample_ID','','yes','no',''),(1653,'','Clone_Alias','Source Organization','Source_Organization__ID','','Organization_ID',3,'FKSource_Organization__ID','int(11)','MUL','YES','',20,'',102,'Organization.Organization_ID','','yes','no',''),(1654,'','Clone_Alias','Source','Source','','',4,'Source','char(80)','MUL','YES','',20,'',102,'','','yes','no',''),(1655,'','Clone_Alias','Alias','Alias','','',5,'Alias','char(80)','MUL','YES','',20,'',102,'','','yes','no',''),(1656,'','Clone_Alias','Alias Type','Alias_Type','','',6,'Alias_Type','enum(\'Primary\',\'Secondary\')','','YES','',20,'',102,'','','yes','no',''),(1657,'','Clone_Details','Clone Details ID','ID','Primary','',1,'Clone_Details_ID','int(11)','PRI','NO','',20,'',103,'','','yes','no',''),(1658,'','Clone_Details','Clone Sample','Clone_Sample__ID','','Clone_Sample_ID',2,'FK_Clone_Sample__ID','int(11)','UNI','NO','',20,'',103,'Clone_Sample.Clone_Sample_ID','','yes','no',''),(1659,'','Clone_Details','Clone Comments','Clone_Comments','','',3,'Clone_Comments','text','','YES','',20,'',103,'','','yes','no',''),(1660,'','Clone_Details','PolyA Tail','PolyA_Tail','','',4,'PolyA_Tail','int(11)','','YES','',20,'',103,'','','yes','no',''),(1661,'','Clone_Details','Chimerism check with ESTs','Chimerism_check_with_ESTs','','',5,'Chimerism_check_with_ESTs','enum(\'no\',\'yes\',\'warning\',\'single EST match\')','','YES','',20,'',103,'','','yes','no',''),(1662,'','Clone_Details','Score','Score','','',6,'Score','int(11)','','YES','',20,'',103,'','','yes','no',''),(1663,'','Clone_Details','5Prime found','5Prime_found','','',7,'5Prime_found','tinyint(4)','','YES','',20,'',103,'','','yes','no',''),(1664,'','Clone_Details','Genes Protein','Genes_Protein','','',8,'Genes_Protein','text','','YES','',20,'',103,'','','yes','no',''),(1665,'','Clone_Details','Incyte Match','Incyte_Match','','',9,'Incyte_Match','int(11)','','YES','',20,'',103,'','','yes','no',''),(1666,'','Clone_Details','PolyA Signal','PolyA_Signal','','',10,'PolyA_Signal','int(11)','','YES','',20,'',103,'','','yes','no',''),(1667,'','Clone_Details','Clone Vector','Clone_Vector','','',11,'Clone_Vector','text','','YES','',20,'',103,'','','yes','no',''),(1668,'','Clone_Details','Genbank ID','Genbank_ID','','',12,'Genbank_ID','text','','YES','',20,'',103,'','','yes','no',''),(1669,'','Clone_Details','Lukas Passed','Lukas_Passed','','',13,'Lukas_Passed','int(11)','','YES','',20,'',103,'','','yes','no',''),(1680,'','Clone_Sample','Clone Sample ID','ID','Primary','',1,'Clone_Sample_ID','int(11)','PRI','NO','',20,'',105,'','','yes','no',''),(1681,'','Clone_Sample','Sample','Sample__ID','Mandatory','Sample_ID',2,'FK_Sample__ID','int(11)','MUL','NO','',20,'',105,'Sample.Sample_ID','','yes','no',''),(1682,'','Clone_Sample','Library','Library__Name','Searchable','Library_Name',3,'FK_Library__Name','char(5)','MUL','YES','',20,'',105,'Library.Library_Name','','yes','no',''),(1683,'','Clone_Sample','Library Plate Number','Library_Plate_Number','','',4,'Library_Plate_Number','int(11)','','YES','',20,'',105,'','','yes','no',''),(1684,'','Clone_Sample','Original Quadrant','Original_Quadrant','','',5,'Original_Quadrant','char(2)','','YES','',20,'',105,'','','yes','no',''),(1685,'','Clone_Sample','Original Well','Original_Well','','',6,'Original_Well','char(3)','','YES','',20,'',105,'','','yes','no',''),(1686,'','Clone_Sample','Original Plate','Original_Plate__ID','','Plate_ID',7,'FKOriginal_Plate__ID','int(11)','MUL','YES','',20,'',105,'Plate.Plate_ID','','yes','no',''),(1705,'','DBField','DBField ID','ID','Primary','Field_Name',1,'DBField_ID','int(11)','PRI','NO','',20,'',107,'','','yes','no',''),(1706,'','DBField','Field Description','Field_Description','','',2,'Field_Description','text','','NO','',20,'',107,'','','yes','no',''),(1707,'','DBField','Field Table','Field_Table','','',3,'Field_Table','text','','NO','',20,'',107,'','','yes','no',''),(1708,'','DBField','Prompt','Prompt','','',4,'Prompt','varchar(255)','','NO','',20,'^.{0,255}$',107,'','','yes','no',''),(1709,'','DBField','Field Alias','Field_Alias','','',5,'Field_Alias','varchar(255)','','NO','',20,'^.{0,255}$',107,'','','yes','no',''),(1710,'','DBField','Field Options','Field_Options','','',6,'Field_Options','set(\'Hidden\',\'Mandatory\',\'Primary\',\'Unique\',\'NewLink\',\'ViewLink\',\'ListLink\',\'Searchable\',\'Obsolete\')','','YES','',20,'',107,'','','yes','no',''),(1711,'','DBField','Field Reference','Field_Reference','','',7,'Field_Reference','varchar(255)','','NO','',20,'^.{0,255}$',107,'','','yes','no',''),(1712,'','DBField','Field Order','Field_Order','','',8,'Field_Order','int(11)','','NO','',20,'',107,'','','yes','no',''),(1713,'','DBField','Field Name','Field_Name','','',9,'Field_Name','varchar(255)','MUL','NO','',20,'^.{0,255}$',107,'','','yes','no',''),(1714,'','DBField','Field Type','Field_Type','','',10,'Field_Type','text','','NO','',20,'',107,'','','yes','no',''),(1715,'','DBField','Field Index','Field_Index','','',11,'Field_Index','varchar(255)','','NO','',20,'^.{0,255}$',107,'','','yes','no',''),(1716,'','DBField','NULL ok','NULL_ok','','',12,'NULL_ok','enum(\'NO\',\'YES\')','','NO','YES',20,'',107,'','','yes','no',''),(1717,'','DBField','Field Default','Field_Default','','',13,'Field_Default','varchar(255)','','NO','',20,'^.{0,255}$',107,'','','yes','no',''),(1718,'','DBField','Field Size','Field_Size','','',14,'Field_Size','tinyint(4)','','YES','20',20,'',107,'','','yes','no',''),(1719,'','DBField','Field Format','Field_Format','','',15,'Field_Format','varchar(80)','','YES','',20,'^.{0,80}$',107,'','','yes','no',''),(1720,'','DBField','DBTable','DBTable__ID','','DBTable_ID',16,'FK_DBTable__ID','int(11)','MUL','YES','',20,'',107,'DBTable.DBTable_ID','','yes','no',''),(1721,'','DBField','Foreign Key','Foreign_Key','','',17,'Foreign_Key','varchar(255)','','YES','',20,'^.{0,255}$',107,'','','yes','no',''),(1722,'','DBField','Notes','Notes','','',18,'DBField_Notes','text','','YES','',20,'',107,'','','yes','no',''),(1723,'','DBTable','Type','Type','','',6,'DBTable_Type','enum(\'General\',\'Lab Object\',\'Lab Process\',\'Object Detail\',\'Settings\',\'Dynamic\',\'DB Management\',\'Application Specific\',\'Class\',\'Subclass\',\'Lookup\',\'Join\',\'Imported\')','','YES','',20,'^.{0,20}$',28,'','','yes','no',''),(1724,'','DBTable','Title','Title','','',7,'DBTable_Title','varchar(80)','','NO','',20,'^.{0,80}$',28,'','','yes','no',''),(1725,'','DB_Form','DB Form ID','ID','Primary','concat(DB_Form_ID,\': \',Form_Table)',1,'DB_Form_ID','int(11)','PRI','NO','',20,'',108,'','','yes','no',''),(1726,'','DB_Form','Form Table','Form_Table','','',2,'Form_Table','varchar(80)','','NO','',20,'^.{0,80}$',108,'','','yes','no',''),(1727,'','DB_Form','Min Records','Min_Records','','',3,'Min_Records','int(2)','','NO','1',20,'',108,'','','yes','no',''),(1728,'','DB_Form','Max Records','Max_Records','','',4,'Max_Records','int(2)','','NO','1',20,'',108,'','','yes','no',''),(1729,'','DB_Form','Parent DB Form','Parent_DB_Form__ID','','DB_Form_ID',5,'FKParent_DB_Form__ID','int(11)','MUL','YES','',20,'',108,'DB_Form.DB_Form_ID','','yes','no',''),(1730,'','DB_Form','Parent Field','Parent_Field','','',6,'Parent_Field','varchar(80)','','YES','',20,'^.{0,80}$',108,'','','yes','no',''),(1731,'','DB_Form','Parent Value','Parent_Value','','',7,'Parent_Value','varchar(200)','','YES','',20,'^.{0,200}$',108,'','','yes','no',''),(1732,'','Department','Department ID','ID','Primary','Department_Name',1,'Department_ID','int(11)','PRI','NO','',20,'',109,'','','yes','no',''),(1733,'','Department','Name','Name','','',2,'Department_Name','char(40)','','YES','',20,'',109,'','','yes','no',''),(1734,'','Department','Status','Status','','',3,'Department_Status','enum(\'Active\',\'Inactive\')','','YES','',20,'',109,'','','yes','no',''),(1735,'','Employee','Machine Name','Machine_Name','','',12,'Machine_Name','varchar(20)','','YES','',20,'^.{0,20}$',30,'','','yes','no',''),(1736,'','Employee','Department','Department','Hidden','',13,'Department','enum(\'Receiving\',\'Administration\',\'Sequencing\',\'Mapping\',\'BioInformatics\',\'Gene Expression\',\'None\')','','YES','',20,'',30,'','','yes','no',''),(1737,'','Employee','Department','Department__ID','','Department_ID',14,'FK_Department__ID','int(11)','MUL','YES','',20,'',30,'Department.Department_ID','','yes','no',''),(1738,'','Enzyme','Enzyme ID','ID','Primary','concat(Enzyme_ID,\': \',Enzyme_Name)',1,'Enzyme_ID','int(11)','PRI','NO','',20,'',110,'','','yes','no',''),(1739,'','Enzyme','Name','Name','','',2,'Enzyme_Name','varchar(30)','','YES','',20,'^.{0,30}$',110,'','','yes','no',''),(1741,'','Equipment','Status','Status','','',15,'Equipment_Status','enum(\'In Use\',\'Not In Use\',\'Removed\')','','YES','In Use',20,'',31,'','','yes','yes',''),(1742,'','Error_Check','Command Type','Command_Type','','',5,'Command_Type','enum(\'SQL\',\'RegExp\',\'FullSQL\',\'Perl\')','','YES','',20,'',32,'','','yes','no',''),(1743,'','Error_Check','Notice Sent','Notice_Sent','','',7,'Notice_Sent','date','','YES','',20,'',32,'','','yes','no',''),(1744,'','Error_Check','Notice Frequency','Notice_Frequency','','',8,'Notice_Frequency','int(11)','','YES','',20,'',32,'','','yes','no',''),(1745,'','Funding','ApplicationDate','ApplicationDate','','',8,'ApplicationDate','date','','YES','',20,'',36,'','','yes','yes',''),(1746,'','Funding','Contact Employee','Contact_Employee__ID','','Employee_ID',9,'FKContact_Employee__ID','int(11)','MUL','YES','',20,'',36,'Employee.Employee_ID','','yes','no',''),(1747,'','Funding','Source Organization','Source_Organization__ID','','Organization_ID',10,'FKSource_Organization__ID','int(11)','MUL','YES','',20,'',36,'Organization.Organization_ID','','yes','no',''),(1748,'','Funding','Source ID','Source_ID','','concat(Source_Type,\'-\',Source_Number)',11,'Source_ID','text','','YES','',20,'',36,'','','yes','no',''),(1749,'','Funding','AppliedFor','AppliedFor','','',12,'AppliedFor','int(11)','','YES','',20,'',36,'','','yes','no',''),(1750,'','Funding','Duration','Duration','','',13,'Duration','text','','YES','',20,'',36,'','','yes','no',''),(1751,'','Funding','Type','Type','','',14,'Funding_Type','enum(\'New\',\'Renewal\')','','YES','',20,'',36,'','','yes','no',''),(1752,'','Funding','Currency','Currency','','',15,'Currency','enum(\'US\',\'Canadian\')','','YES','Canadian',20,'',36,'','','yes','no',''),(1753,'','Funding','ExchangeRate','ExchangeRate','','',16,'ExchangeRate','float','','YES','',20,'',36,'','','yes','no',''),(1754,'','Funding_Applicant','Funding Applicant ID','ID','Primary','',1,'Funding_Applicant_ID','int(11)','PRI','NO','',20,'',111,'','','yes','no',''),(1755,'','Funding_Applicant','Funding','Funding__ID','','Funding_ID',2,'FK_Funding__ID','int(11)','MUL','YES','',20,'',111,'Funding.Funding_ID','','yes','no',''),(1756,'','Funding_Applicant','Employee','Employee__ID','','Employee_ID',3,'FK_Employee__ID','int(11)','MUL','YES','',20,'',111,'Employee.Employee_ID','','yes','no',''),(1757,'','Funding_Applicant','Contact','Contact__ID','NewLink','Contact_ID',4,'FK_Contact__ID','int(11)','MUL','YES','',20,'',111,'Contact.Contact_ID','','yes','no',''),(1758,'','Funding_Applicant','Applicant Type','Applicant_Type','','',5,'Applicant_Type','enum(\'Primary\',\'Collaborator\')','','YES','',20,'',111,'','','yes','no',''),(1759,'','Funding_Distribution','Funding Distribution ID','ID','Primary','',1,'Funding_Distribution_ID','int(11)','PRI','NO','',20,'',112,'','','yes','no',''),(1760,'','Funding_Distribution','Funding Segment','Funding_Segment__ID','','Funding_Segment_ID',2,'FK_Funding_Segment__ID','int(11)','MUL','YES','',20,'',112,'Funding_Segment.Funding_Segment_ID','','yes','no',''),(1761,'','Funding_Distribution','Funding Start','Funding_Start','','',3,'Funding_Start','date','','YES','',20,'',112,'','','yes','no',''),(1762,'','Funding_Distribution','Funding End','Funding_End','','',4,'Funding_End','date','','YES','',20,'',112,'','','yes','no',''),(1763,'','Funding_Segment','Funding Segment ID','ID','Primary','',1,'Funding_Segment_ID','int(11)','PRI','NO','',20,'',113,'','','yes','no',''),(1764,'','Funding_Segment','Funding','Funding__ID','','Funding_ID',2,'FK_Funding__ID','int(11)','MUL','YES','',20,'',113,'Funding.Funding_ID','','yes','no',''),(1765,'','Funding_Segment','Amount','Amount','','',3,'Amount','int(11)','','YES','',20,'',113,'','','yes','no',''),(1766,'','Funding_Segment','Currency','Currency','','',4,'Currency','enum(\'US\',\'Canadian\')','','YES','',20,'',113,'','','yes','no',''),(1767,'','Funding_Segment','Notes','Notes','','',5,'Funding_Segment_Notes','text','','YES','',20,'',113,'','','yes','no',''),(1774,'','Genomic_Library','Sequencing Library','Sequencing_Library__ID','Mandatory','Sequencing_Library_ID',2,'FK_Sequencing_Library__ID','int(11)','MUL','NO','',20,'',92,'Sequencing_Library.Sequencing_Library_ID','','yes','yes',''),(1775,'','GrantApplication','GrantApplication ID','ID','Primary','',1,'GrantApplication_ID','int(11)','PRI','NO','',20,'',115,'','','yes','no',''),(1776,'','GrantApplication','Title','Title','','',2,'Title','char(80)','','YES','',20,'',115,'','','yes','no',''),(1777,'','GrantApplication','Contact Employee','Contact_Employee__ID','','Employee_ID',3,'FKContact_Employee__ID','int(11)','MUL','YES','',20,'',115,'Employee.Employee_ID','','yes','no',''),(1778,'','GrantApplication','AppliedFor','AppliedFor','','',4,'AppliedFor','float','','YES','',20,'',115,'','','yes','no',''),(1779,'','GrantApplication','Duration','Duration','','',5,'Duration','int(11)','','YES','',20,'',115,'','','yes','no',''),(1780,'','GrantApplication','Duration Units','Duration_Units','','',6,'Duration_Units','enum(\'days\',\'months\',\'years\')','','YES','',20,'',115,'','','yes','no',''),(1781,'','GrantApplication','Grant Type','Grant_Type','','',7,'Grant_Type','char(40)','','YES','',20,'',115,'','','yes','no',''),(1782,'','GrantApplication','ApplicationStatus','ApplicationStatus','','',8,'ApplicationStatus','enum(\'Awarded\',\'Declined\',\'Applied\')','','YES','',20,'',115,'','','yes','no',''),(1783,'','GrantApplication','Award','Award','','',9,'Award','float','','YES','',20,'',115,'','','yes','no',''),(1784,'','GrantApplication','Currency','Currency','','',10,'Currency','enum(\'US\',\'Canadian\')','','YES','',20,'',115,'','','yes','no',''),(1785,'','GrantApplication','Application Date','Application_Date','','',11,'Application_Date','date','','YES','<TODAY>',20,'',115,'','','yes','yes',''),(1786,'','GrantApplication','Application Number','Application_Number','','',12,'Application_Number','int(11)','','YES','',20,'',115,'','','yes','no',''),(1787,'','GrantApplication','Funding Frequency','Funding_Frequency','','',13,'Funding_Frequency','char(40)','','YES','',20,'',115,'','','yes','no',''),(1788,'','GrantDistribution','GrantDistribution ID','ID','Primary','',1,'GrantDistribution_ID','int(11)','PRI','NO','',20,'',116,'','','yes','no',''),(1789,'','GrantDistribution','GrantApplication','GrantApplication__ID','','GrantApplication_ID',2,'FK_GrantApplication__ID','int(11)','MUL','YES','',20,'',116,'GrantApplication.GrantApplication_ID','','yes','no',''),(1790,'','GrantDistribution','StartDate','StartDate','','',3,'StartDate','date','','YES','',20,'',116,'','','yes','yes',''),(1791,'','GrantDistribution','EndDate','EndDate','','',4,'EndDate','date','','YES','',20,'',116,'','','yes','yes',''),(1792,'','GrantDistribution','Amount','Amount','','',5,'Amount','float','','YES','',20,'',116,'','','yes','no',''),(1793,'','GrantDistribution','Currency','Currency','','',6,'Currency','enum(\'Canadian\',\'US\')','','YES','',20,'',116,'','','yes','no',''),(1794,'','GrantDistribution','AwardStatus','AwardStatus','','',7,'AwardStatus','enum(\'Spent\',\'Received\',\'Awarded\',\'Declined\',\'Pending\',\'TBD\')','','YES','',20,'',116,'','','yes','no',''),(1795,'','GrantDistribution','Spent','Spent','','',8,'Spent','float','','YES','',20,'',116,'','','yes','no',''),(1796,'','GrantDistribution','SpentAsOf','SpentAsOf','','',9,'SpentAsOf','date','','YES','',20,'',116,'','','yes','no',''),(1797,'','Grp','Grp ID','ID','Primary','Grp_Name',1,'Grp_ID','int(11)','PRI','NO','',20,'',117,'','','yes','no',''),(1798,'','Grp','Name','Name','Mandatory','',2,'Grp_Name','varchar(80)','','NO','',20,'^.{0,80}$',117,'','','yes','no',''),(1799,'','Grp','Department','Department__ID','Mandatory','Department_ID',3,'FK_Department__ID','int(11)','MUL','NO','',20,'',117,'Department.Department_ID','','yes','no',''),(1800,'','Grp','Access','Access','Mandatory','',4,'Access','enum(\'Lab\',\'Admin\',\'Guest\',\'Report\',\'Bioinformatics\')','','NO','Guest',20,'',117,'','','yes','no',''),(1801,'','GrpDBTable','GrpDBTable ID','ID','Primary','',1,'GrpDBTable_ID','int(11)','PRI','NO','',20,'',118,'','','yes','no',''),(1802,'','GrpDBTable','Grp','Grp__ID','Mandatory','Grp_ID',2,'FK_Grp__ID','int(11)','MUL','NO','',20,'',118,'Grp.Grp_ID','','yes','no',''),(1803,'','GrpDBTable','DBTable','DBTable__ID','Mandatory','DBTable_ID',3,'FK_DBTable__ID','int(11)','MUL','NO','',20,'',118,'DBTable.DBTable_ID','','yes','no',''),(1804,'','GrpDBTable','Permissions','Permissions','Mandatory','',4,'Permissions','set(\'R\',\'W\',\'U\',\'D\',\'O\')','','NO','R',20,'',118,'','','yes','no',''),(1805,'','GrpEmployee','GrpEmployee ID','ID','Primary','',1,'GrpEmployee_ID','int(11)','PRI','NO','',20,'',119,'','','yes','no',''),(1806,'','GrpEmployee','Grp','Grp__ID','Mandatory','Grp_ID',2,'FK_Grp__ID','int(11)','MUL','NO','',20,'',119,'Grp.Grp_ID','','yes','no',''),(1807,'','GrpEmployee','Employee','Employee__ID','Mandatory','Employee_ID',3,'FK_Employee__ID','int(11)','MUL','NO','',20,'',119,'Employee.Employee_ID','','yes','no',''),(1808,'','GrpLab_Protocol','GrpLab Protocol ID','ID','Primary','',1,'GrpLab_Protocol_ID','int(11)','PRI','NO','',20,'',120,'','','yes','no',''),(1809,'','GrpLab_Protocol','Grp','Grp__ID','Mandatory','Grp_ID',2,'FK_Grp__ID','int(11)','MUL','NO','',20,'',120,'Grp.Grp_ID','','yes','no',''),(1810,'','GrpLab_Protocol','Lab Protocol','Lab_Protocol__ID','Mandatory','Lab_Protocol_ID',3,'FK_Lab_Protocol__ID','int(11)','MUL','NO','',20,'',120,'Lab_Protocol.Lab_Protocol_ID','','yes','no',''),(1811,'','GrpStandard_Solution','GrpStandard Solution ID','ID','Primary','',1,'GrpStandard_Solution_ID','int(11)','PRI','NO','',20,'',121,'','','yes','no',''),(1812,'','GrpStandard_Solution','Grp','Grp__ID','Mandatory','Grp_ID',2,'FK_Grp__ID','int(11)','MUL','NO','',20,'',121,'Grp.Grp_ID','','yes','no',''),(1813,'','GrpStandard_Solution','Standard Solution','Standard_Solution__ID','Mandatory','Standard_Solution_ID',3,'FK_Standard_Solution__ID','int(11)','MUL','NO','',20,'',121,'Standard_Solution.Standard_Solution_ID','','yes','no',''),(1814,'','Grp_Relationship','Grp Relationship ID','ID','Primary','',1,'Grp_Relationship_ID','int(11)','PRI','NO','',20,'',122,'','','yes','no',''),(1815,'','Grp_Relationship','Base Grp','Base_Grp__ID','Mandatory','Grp_ID',2,'FKBase_Grp__ID','int(11)','MUL','NO','',20,'',122,'Grp.Grp_ID','','yes','no',''),(1816,'','Grp_Relationship','Derived Grp','Derived_Grp__ID','Mandatory','Grp_ID',3,'FKDerived_Grp__ID','int(11)','MUL','NO','',20,'',122,'Grp.Grp_ID','','yes','no',''),(1817,'','Issue','Estimated Time','Estimated_Time','','',13,'Estimated_Time','float','','YES','',20,'',94,'','','yes','no',''),(1818,'','Issue','Estimated Time Unit','Estimated_Time_Unit','','',14,'Estimated_Time_Unit','enum(\'FTE\',\'Minutes\',\'Hours\',\'Days\',\'Weeks\',\'Months\')','','YES','',20,'',94,'','','yes','no',''),(1819,'','Issue','Actual Time','Actual_Time','','',15,'Actual_Time','float','','YES','',20,'',94,'','','yes','no',''),(1820,'','Issue','Actual Time Unit','Actual_Time_Unit','','',16,'Actual_Time_Unit','enum(\'Minutes\',\'Hours\',\'Days\',\'Weeks\',\'Months\')','','YES','',20,'',94,'','','yes','no',''),(1821,'','Issue','Department','Department__ID','','Department_ID',18,'FK_Department__ID','int(11)','MUL','YES','',20,'',94,'Department.Department_ID','','yes','no',''),(1822,'','Issue','SubType','SubType','','',19,'SubType','enum(\'General\',\'View\',\'Forms\',\'I/O\',\'Report\',\'Settings\',\'Error Checking\',\'Auto-Notification\',\'Documentation\',\'Scanner\',\'Background Process\')','','YES','General',20,'',94,'','','yes','no',''),(1823,'','Issue','Parent Issue','Parent_Issue__ID','','Issue_ID',20,'FKParent_Issue__ID','int(11)','MUL','YES','',20,'',94,'Issue.Issue_ID','','yes','no',''),(1824,'','Issue_Detail','Issue Detail ID','ID','Primary','',1,'Issue_Detail_ID','int(11)','PRI','NO','',20,'',123,'','','yes','no',''),(1825,'','Issue_Detail','Issue','Issue__ID','','Issue_ID',2,'FK_Issue__ID','int(11)','MUL','NO','',20,'',123,'Issue.Issue_ID','','yes','no',''),(1826,'','Issue_Detail','Submitted Employee','Submitted_Employee__ID','','Employee_ID',3,'FKSubmitted_Employee__ID','int(11)','MUL','NO','',20,'',123,'Employee.Employee_ID','','yes','no',''),(1827,'','Issue_Detail','Submitted DateTime','Submitted_DateTime','','',4,'Submitted_DateTime','datetime','','NO','0000-00-00 00:00:00',20,'',123,'','','yes','no',''),(1828,'','Issue_Detail','Message','Message','','',5,'Message','text','','YES','',20,'',123,'','','yes','no',''),(1829,'','Issue_Log','Issue Log ID','ID','Primary','',1,'Issue_Log_ID','int(11)','PRI','NO','',20,'',124,'','','yes','no',''),(1830,'','Issue_Log','Issue','Issue__ID','','Issue_ID',2,'FK_Issue__ID','int(11)','MUL','NO','',20,'',124,'Issue.Issue_ID','','yes','no',''),(1831,'','Issue_Log','Submitted Employee','Submitted_Employee__ID','','Employee_ID',3,'FKSubmitted_Employee__ID','int(11)','MUL','YES','',20,'',124,'Employee.Employee_ID','','yes','no',''),(1832,'','Issue_Log','Submitted DateTime','Submitted_DateTime','','',4,'Submitted_DateTime','datetime','','NO','0000-00-00 00:00:00',20,'',124,'','','yes','no',''),(1833,'','Issue_Log','Log','Log','','',5,'Log','text','','NO','',20,'',124,'','','yes','no',''),(1834,'Reference contact responsible for this information','Library','Internal Contact','Contact__ID','Mandatory,NewLink','Contact_ID',13,'FK_Contact__ID','int(11)','MUL','YES','',20,'',40,'Contact.Contact_ID','','yes','no',''),(1835,'','Library','Grp','Grp__ID','Mandatory','Grp_ID',14,'FK_Grp__ID','int(11)','MUL','NO','',20,'',40,'Grp.Grp_ID','','yes','no',''),(1836,'','LibraryStudy','LibraryStudy ID','ID','Primary','',1,'LibraryStudy_ID','int(11)','PRI','NO','',20,'',125,'','','yes','no',''),(1837,'','LibraryStudy','Library','Library__Name','Mandatory,Searchable','Library_Name',2,'FK_Library__Name','varchar(40)','MUL','YES','',20,'',125,'Library.Library_Name','','yes','no',''),(1838,'','LibraryStudy','Study','Study__ID','Mandatory','Study_ID',3,'FK_Study__ID','int(11)','MUL','YES','',20,'',125,'Study.Study_ID','','yes','no',''),(1839,'','Library_Plate','Library Plate ID','ID','Primary','',1,'Library_Plate_ID','int(11)','PRI','NO','',20,'',126,'','','no','no',''),(1840,'','Library_Plate','Plate','Plate__ID','Mandatory','Plate_ID',2,'FK_Plate__ID','int(11)','MUL','YES','',20,'',126,'Plate.Plate_ID','','yes','no',''),(1841,'','Library_Plate','Plate Class','Plate_Class','','',3,'Plate_Class','enum(\'Standard\',\'ReArray\',\'Oligo\')','','YES','Standard',20,'',126,'','','yes','yes',''),(1842,'','Library_Plate','No Grows','No_Grows','','',4,'No_Grows','text','','YES','',20,'',126,'','','no','yes',''),(1843,'','Library_Plate','Slow Grows','Slow_Grows','','',5,'Slow_Grows','text','','YES','',20,'',126,'','','no','yes',''),(1844,'','Library_Plate','Unused Wells','Unused_Wells','','',6,'Unused_Wells','text','','YES','',20,'',126,'','','no','yes',''),(1846,'','Library_Plate','Sub Quadrants','Sub_Quadrants','','',8,'Sub_Quadrants','set(\'\',\'a\',\'b\',\'c\',\'d\',\'none\')','','YES','',20,'',126,'','','yes','yes',''),(1847,'','Library_Plate','Slice','Slice','','',9,'Slice','varchar(8)','','YES','',20,'^.{0,8}$',126,'','','yes','yes',''),(1848,'','Library_Plate','Plate Position','Plate_Position','','',10,'Plate_Position','enum(\'\',\'a\',\'b\',\'c\',\'d\')','','YES','',20,'',126,'','','yes','yes',''),(1849,'','Ligation','Extraction Plate','Extraction_Plate__ID','Hidden','Plate_ID',8,'FKExtraction_Plate__ID','int(11)','MUL','YES','',20,'',87,'Plate.Plate_ID','','yes','no',''),(1850,'','Maintenance_Protocol','Contact','Contact__ID','NewLink','Contact_ID',9,'FK_Contact__ID','int(11)','MUL','YES','',20,'',45,'Contact.Contact_ID','','yes','no',''),(1851,'','Matched_Funding','Matched Funding ID','ID','Primary','',1,'Matched_Funding_ID','int(11)','PRI','NO','',20,'',127,'','','yes','no',''),(1852,'','Matched_Funding','Number','Number','','',2,'Matched_Funding_Number','int(11)','','YES','',20,'',127,'','','yes','no',''),(1853,'','Matched_Funding','Funding','Funding__ID','','Funding_ID',3,'FK_Funding__ID','int(11)','MUL','YES','',20,'',127,'Funding.Funding_ID','','yes','no',''),(1854,'Rack ID and an optional slot name','Misc_Item','Rack','Rack__ID','Searchable','Rack_ID',6,'FK_Rack__ID','int(11)','MUL','YES','<DEFAULT_LOCATION>',20,'',47,'Rack.Rack_ID','','yes','no',''),(1855,'','Misc_Item','Type','Type','','',7,'Misc_Item_Type','text','','YES','',20,'',47,'','','yes','no',''),(1856,'','PCR_Library','Sequencing Library','Sequencing_Library__ID','Mandatory','Sequencing_Library_ID',2,'FK_Sequencing_Library__ID','int(11)','MUL','NO','',20,'',93,'Sequencing_Library.Sequencing_Library_ID','','yes','yes',''),(1859,'','Plate','Type','Type','Mandatory','',22,'Plate_Type','enum(\'Library_Plate\',\'Tube\',\'Array\')','','YES','',20,'',59,'','','no','no',''),(1860,'','Plate','Original Plate','Original_Plate__ID','','Plate_ID',23,'FKOriginal_Plate__ID','int(10) unsigned','MUL','YES','',20,'',59,'Plate.Plate_ID','','no','no',''),(1861,'','Plate_Format','Style','Style','','',8,'Plate_Format_Style','enum(\'Plate\',\'Tube\',\'Array\',\'Gel\')','','YES','',20,'',60,'','','yes','no',''),(1864,'','Plate_Prep','Plate Prep ID','ID','Primary','',1,'Plate_Prep_ID','int(11)','PRI','NO','',20,'',128,'','','yes','no',''),(1865,'','Plate_Prep','Plate','Plate__ID','','Plate_ID',2,'FK_Plate__ID','int(11)','MUL','YES','',20,'',128,'Plate.Plate_ID','','yes','no',''),(1866,'','Plate_Prep','Prep','Prep__ID','','Prep_ID',3,'FK_Prep__ID','int(11)','MUL','YES','',20,'',128,'Prep.Prep_ID','','yes','no',''),(1867,'','Plate_Prep','Plate Set','Plate_Set__Number','','Plate_Set_Number',4,'FK_Plate_Set__Number','int(11)','MUL','YES','',20,'',128,'Plate_Set.Plate_Set_Number','','yes','no',''),(1872,'','Plate_Sample','Plate Sample ID','ID','Primary','',1,'Plate_Sample_ID','int(11)','PRI','NO','',20,'',130,'','','yes','no',''),(1873,'','Plate_Sample','Original Plate','Original_Plate__ID','','Plate_ID',2,'FKOriginal_Plate__ID','int(11)','MUL','NO','',20,'',130,'Plate.Plate_ID','','yes','no',''),(1874,'','Plate_Sample','Sample','Sample__ID','Mandatory','Sample_ID',3,'FK_Sample__ID','int(11)','MUL','NO','',20,'',130,'Sample.Sample_ID','','yes','no',''),(1875,'','Plate_Sample','Well','Well','','',4,'Well','char(3)','','YES','',20,'',130,'','','yes','no',''),(1877,'','Pool','Type','Type','Mandatory','',11,'Pool_Type','enum(\'Library\',\'Sample\',\'Transposon\')','','YES','Library',20,'',11,'','','yes','no',''),(1878,'','PoolSample','PoolSample ID','ID','Primary','',1,'PoolSample_ID','int(11)','PRI','NO','',20,'',131,'','','yes','no',''),(1879,'','PoolSample','Pool','Pool__ID','Mandatory','Pool_ID',2,'FK_Pool__ID','int(11)','MUL','NO','',20,'',131,'Pool.Pool_ID','','yes','no',''),(1880,'','PoolSample','Plate','Plate__ID','Mandatory','Plate_ID',3,'FK_Plate__ID','int(11)','MUL','NO','',20,'',131,'Plate.Plate_ID','','yes','no',''),(1881,'','PoolSample','Well','Well','','',4,'Well','char(3)','','YES','',20,'',131,'','','yes','no',''),(1883,'','PoolSample','Sample','Sample__ID','','Sample_ID',6,'FK_Sample__ID','int(11)','MUL','YES','',20,'',131,'Sample.Sample_ID','','yes','no',''),(1884,'Name of the action / event performed on the plate(s)','Prep','Name','Name','','',1,'Prep_Name','varchar(80)','','YES','',20,'^.{0,80}$',132,'','','yes','no',''),(1885,'','Prep','Employee','Employee__ID','','Employee_ID',2,'FK_Employee__ID','int(11)','MUL','YES','',20,'',132,'Employee.Employee_ID','','yes','no',''),(1886,'','Prep','DateTime','DateTime','','',3,'Prep_DateTime','datetime','MUL','NO','0000-00-00 00:00:00',20,'',132,'','','yes','yes',''),(1887,'','Prep','Time','Time','','',4,'Prep_Time','text','','YES','',20,'',132,'','','yes','no',''),(1888,'','Prep','Conditions','Conditions','','',5,'Prep_Conditions','text','','YES','',20,'',132,'','','yes','no',''),(1889,'','Prep','Comments','Comments','','',6,'Prep_Comments','text','','YES','',20,'',132,'','','yes','no',''),(1893,'','Prep','Failure Date','Failure_Date','','',10,'Prep_Failure_Date','datetime','','NO','0000-00-00 00:00:00',20,'',132,'','','yes','yes',''),(1894,'','Prep','Action','Action','','',11,'Prep_Action','enum(\'Completed\',\'Failed\',\'Skipped\')','','YES','',20,'',132,'','','yes','no',''),(1895,'','Prep','Lab Protocol','Lab_Protocol__ID','','Lab_Protocol_ID',12,'FK_Lab_Protocol__ID','int(11)','MUL','YES','',20,'',132,'Lab_Protocol.Lab_Protocol_ID','','yes','no',''),(1896,'','Prep','Prep ID','ID','Primary','concat(Prep_Name,\': \',Prep_DateTime)',13,'Prep_ID','int(11)','PRI','NO','',20,'',132,'','','yes','no',''),(1897,'','Primer','Status','Status','','',12,'Primer_Status','enum(\'\',\'Ordered\',\'Received\',\'Inactive\')','','YES','',20,'',64,'','','yes','no',''),(1898,'','Primer_Plate','Primer Plate ID','ID','Primary','Primer_Plate_Name',1,'Primer_Plate_ID','int(11)','PRI','NO','',20,'',133,'','','yes','no',''),(1899,'','Primer_Plate','Name','Name','','',2,'Primer_Plate_Name','text','MUL','YES','',20,'',133,'','','yes','no',''),(1900,'','Primer_Plate','Order DateTime','Order_DateTime','','',3,'Order_DateTime','datetime','','YES','<NOW>',20,'',133,'','','yes','yes',''),(1901,'','Primer_Plate','Arrival DateTime','Arrival_DateTime','','',4,'Arrival_DateTime','datetime','MUL','YES','',20,'',133,'','','yes','yes',''),(1902,'','Primer_Plate','Status','Status','','',5,'Primer_Plate_Status','enum(\'To Order\',\'Ordered\',\'Received\',\'Inactive\')','MUL','YES','',20,'',133,'','','yes','no',''),(1903,'','Primer_Plate','Solution','Solution__ID','','Solution_ID',6,'FK_Solution__ID','int(11)','MUL','YES','',20,'',133,'Solution.Solution_ID','','yes','no',''),(1904,'','Primer_Plate_Well','Primer Plate Well ID','ID','Primary','',1,'Primer_Plate_Well_ID','int(11)','PRI','NO','',20,'',134,'','','yes','no',''),(1905,'','Primer_Plate_Well','Well','Well','','',2,'Well','char(3)','MUL','YES','',20,'',134,'','','yes','no',''),(1906,'','Primer_Plate_Well','Primer','Primer__Name','','Primer_Name',3,'FK_Primer__Name','varchar(80)','MUL','YES','',20,'',134,'Primer.Primer_Name','','yes','no',''),(1907,'','Primer_Plate_Well','Primer Plate','Primer_Plate__ID','','Primer_Plate_ID',4,'FK_Primer_Plate__ID','int(11)','MUL','YES','',20,'',134,'Primer_Plate.Primer_Plate_ID','','yes','no',''),(1913,'','ProjectStudy','ProjectStudy ID','ID','Primary','',1,'ProjectStudy_ID','int(11)','PRI','NO','',20,'',136,'','','yes','no',''),(1914,'','ProjectStudy','Project','Project__ID','Mandatory','Project_ID',2,'FK_Project__ID','int(11)','MUL','YES','',20,'',136,'Project.Project_ID','','yes','no',''),(1915,'','ProjectStudy','Study','Study__ID','Mandatory','Study_ID',3,'FK_Study__ID','int(11)','MUL','YES','',20,'',136,'Study.Study_ID','','yes','no',''),(1916,'','Protocol_Tracking','Grp','Grp__ID','','Grp_ID',7,'FK_Grp__ID','int(11)','MUL','YES','',20,'',68,'Grp.Grp_ID','','yes','no',''),(1943,'Hierarchy must be maintained (Shelves contain Racks contain Boxes contain Slots)','Rack','Type','Type','Mandatory','',4,'Rack_Type','enum(\'Shelf\',\'Rack\',\'Box\',\'Slot\')','MUL','NO','Shelf',20,'',69,'','','yes','no',''),(1944,'Name of Rack (eg. R1) - used to generate Alias (eg. S1-R1).  Must be unique for lab shelves.','Rack','Name','Name','Mandatory','',5,'Rack_Name','varchar(80)','MUL','YES','',20,'^.{0,80}$',69,'','','yes','no',''),(1945,'Automatically set based upon name / equipment / parent name','Rack','Alias','Alias','Hidden','',6,'Rack_Alias','varchar(80)','MUL','YES','',20,'^.{0,80}$',69,'','','no','yes',''),(1946,'(Only required if this is located on/in another rack)','Rack','Parent Rack','Parent_Rack__ID','Hidden','Rack_ID',7,'FKParent_Rack__ID','int(11)','MUL','YES','',20,'',69,'Rack.Rack_ID','','yes','no',''),(1948,'','ReArray','Request','Request__ID','Mandatory','ReArray_Request_ID',6,'FK_ReArray_Request__ID','int(11)','MUL','NO','',20,'',70,'ReArray_Request.ReArray_Request_ID','','yes','no',''),(1949,'','ReArray_Request','ReArray Notify','ReArray_Notify','','',1,'ReArray_Notify','text','','YES','',20,'',140,'','','yes','no',''),(1950,'','ReArray_Request','ReArray Format Size','ReArray_Format_Size','Mandatory','',2,'ReArray_Format_Size','enum(\'96-well\',\'384-well\')','','NO','96-well',20,'',140,'','','yes','no',''),(1951,'','ReArray_Request','ReArray Type','ReArray_Type','Mandatory','',3,'ReArray_Type','enum(\'Clone Rearray\',\'Manual Rearray\',\'Reaction Rearray\',\'Extraction Rearray\',\'Pool Rearray\')','','YES','Standard',20,'',140,'','','yes','no',''),(1952,'','ReArray_Request','Employee','Employee__ID','Mandatory','Employee_ID',4,'FK_Employee__ID','int(11)','MUL','YES','',20,'',140,'Employee.Employee_ID','','yes','no',''),(1953,'','ReArray_Request','Request DateTime','Request_DateTime','','',5,'Request_DateTime','datetime','MUL','YES','<NOW>',20,'',140,'','','yes','yes',''),(1954,'','ReArray_Request','Target Plate','Target_Plate__ID','','Plate_ID',6,'FKTarget_Plate__ID','int(11)','MUL','YES','',20,'',140,'Plate.Plate_ID','','yes','no',''),(1955,'','ReArray_Request','ReArray Comments','ReArray_Comments','','',7,'ReArray_Comments','text','','YES','',20,'',140,'','','yes','no',''),(1956,'','ReArray_Request','ReArray Request','ReArray_Request','','',8,'ReArray_Request','text','','YES','',20,'',140,'','','yes','no',''),(1958,'','ReArray_Request','ReArray Request ID','ID','Primary','',10,'ReArray_Request_ID','int(11)','PRI','NO','',20,'',140,'','','yes','no',''),(1959,'','Restriction_Site','Restriction Site ID','ID','Primary','concat(Restriction_Site_Name,\': \',Recognition_Sequence)',3,'Restriction_Site_ID','int(11)','PRI','NO','',20,'',71,'','','yes','no',''),(1960,'','RunPlate','Sequence ID','Sequence_ID','','Sequence_Subdirectory',1,'Sequence_ID','int(11)','','NO','',20,'',141,'','','yes','no',''),(1961,'','RunPlate','Plate Number','Plate_Number','','',2,'Plate_Number','int(4)','','NO','',20,'',141,'','','yes','no',''),(1962,'','RunPlate','Parent Quadrant','Parent_Quadrant','','',3,'Parent_Quadrant','char(1)','','YES','',20,'',141,'','','yes','no',''),(1963,'','SAGE_Library','Sequencing Library','Sequencing_Library__ID','Mandatory','Sequencing_Library_ID',2,'FK_Sequencing_Library__ID','int(11)','MUL','NO','',20,'',90,'Sequencing_Library.Sequencing_Library_ID','','yes','yes',''),(1964,'Type of SAGE library (eg LongSAGE, 14bp SAGE)','SAGE_Library','Type','Type','','',8,'SAGE_Library_Type','enum(\'SAGE\',\'LongSAGE\',\'PCR-SAGE\',\'PCR-LongSAGE\',\'SAGELite-SAGE\',\'SAGELite-LongSAGE\')','','YES','',20,'',90,'','','yes','yes',''),(1965,'','SAGE_Library','InsertSite Enzyme','InsertSite_Enzyme__ID','Mandatory','Enzyme_ID',9,'FKInsertSite_Enzyme__ID','int(11)','MUL','YES','',20,'',90,'Enzyme.Enzyme_ID','','yes','no',''),(1966,'','SAGE_Library','Anchoring Enzyme','Anchoring_Enzyme__ID','Mandatory','Enzyme_ID',10,'FKAnchoring_Enzyme__ID','int(11)','MUL','YES','',20,'',90,'Enzyme.Enzyme_ID','','yes','no',''),(1967,'','SAGE_Library','Tagging Enzyme','Tagging_Enzyme__ID','Mandatory','Enzyme_ID',11,'FKTagging_Enzyme__ID','int(11)','MUL','YES','',20,'',90,'Enzyme.Enzyme_ID','','yes','no',''),(1969,'','Sample','Sample ID','ID','Primary','Sample_Name',1,'Sample_ID','int(11)','PRI','NO','',20,'',142,'','','yes','no',''),(1970,'','Sample','Name','Name','','',2,'Sample_Name','varchar(40)','MUL','YES','',20,'^.{0,40}$',142,'','','yes','no',''),(1971,'','Sample','Type','Type','','',3,'Sample_Type','enum(\'Clone\',\'Extraction\')','MUL','YES','',20,'',142,'','','yes','no',''),(1972,'','Sample','Comments','Comments','','',4,'Sample_Comments','text','','YES','',20,'',142,'','','yes','no',''),(1979,'','Sequencer_Type','Capillaries','Capillaries','','',11,'Capillaries','int(3)','','YES','',20,'',74,'','','yes','no',''),(1980,'','Sequencer_Type','Sliceable','Sliceable','','',12,'Sliceable','enum(\'Yes\',\'No\')','','YES','No',20,'',74,'','','yes','no',''),(1981,'','Sequencing_Library','Sequencing Library ID','ID','Primary','concat(Sequencing_Library_ID,\': \',FK_Library__Name)',1,'Sequencing_Library_ID','int(11)','PRI','NO','',20,'',143,'','','yes','yes',''),(1982,'','Sequencing_Library','Library','Library__Name','Mandatory,Searchable','Library_Name',2,'FK_Library__Name','varchar(40)','UNI','NO','',20,'^\'?[a-zA-Z0-9]{5}\'?$',143,'Library.Library_Name','','yes','yes',''),(1983,'Type of this library','Sequencing_Library','Type','Type','Mandatory','',1,'Sequencing_Library_Type','enum(\'SAGE\',\'cDNA\',\'Genomic\',\'EST\',\'Transposon\',\'PCR\',\'Test\')','','YES','',20,'',143,'','','no','yes',''),(1984,'','Sequencing_Library','Vector','Vector__Name','Hidden','Vector_Name',4,'FK_Vector__Name','varchar(40)','MUL','YES','',20,'',143,'Vector.Vector_Name','','yes','yes',''),(1985,'','Sequencing_Library','Host','Host','Hidden','',10,'Host','text','','NO','',20,'',143,'','','yes','yes',''),(1986,'Organism this library is obtained from','Sequencing_Library','Organism','Organism','Hidden','',11,'Organism','varchar(40)','','YES','',20,'^.{0,40}$',143,'','','yes','yes',''),(1989,'Sex of the organism','Sequencing_Library','Sex','Sex','Hidden','',14,'Sex','varchar(20)','','YES','',20,'^.{0,20}$',143,'','','yes','yes',''),(1990,'Tissue this library is obtained from','Sequencing_Library','Tissue','Tissue','Hidden,Obsolete','',15,'Tissue','varchar(40)','','YES','',20,'^.{0,40}$',143,'','','yes','yes',''),(1991,'Strain of the organism this library is obtained from','Sequencing_Library','Strain','Strain','Hidden','',16,'Strain','varchar(40)','','YES','',20,'^.{0,40}$',143,'','','yes','yes',''),(1994,'','Sequencing_Library','Vector','Vector__ID','Hidden','Vector_ID',19,'FK_Vector__ID','int(11)','MUL','YES','',20,'',143,'Vector.Vector_ID','','yes','yes',''),(1997,'Number of Colonies screened','Sequencing_Library','Colonies Screened','Colonies_Screened','','',22,'Colonies_Screened','int(11)','','YES','',20,'',143,'','','yes','yes',''),(1998,'','Sequencing_Library','Clones NoInsert Percent','Clones_NoInsert_Percent','','',23,'Clones_NoInsert_Percent','float(5,2)','','YES','',20,'',143,'','','yes','yes',''),(1999,'Average insert size','Sequencing_Library','AvgInsertSize','AvgInsertSize','','',24,'AvgInsertSize','int(11)','','YES','',20,'',143,'','','yes','yes',''),(2000,'Minimum Insert Size','Sequencing_Library','InsertSizeMin','InsertSizeMin','','',25,'InsertSizeMin','int(11)','','YES','',20,'',143,'','','yes','yes',''),(2001,'Maximum Insert Size','Sequencing_Library','InsertSizeMax','InsertSizeMax','','',26,'InsertSizeMax','int(11)','','YES','',20,'',143,'','','yes','yes',''),(2003,'','Sequencing_Library','BlueWhiteSelection','BlueWhiteSelection','Hidden','',28,'BlueWhiteSelection','enum(\'Yes\',\'No\')','','YES','',20,'',143,'','','yes','yes',''),(2004,'Format this library was received as (e.g. Pooled, Microtiter plates)','Sequencing_Library','Format','Format','Hidden','',29,'Sequencing_Library_Format','set(\'Ligation\',\'Transformed Cells\',\'Microtiter Plates\',\'ReArrayed\')','','YES','',20,'',143,'','','yes','yes',''),(2005,'The company which made the vector that is being used','Sequencing_Library','Vector Manufacturer','Vector_Organization__ID','Hidden','Organization_ID',6,'FKVector_Organization__ID','int(11)','MUL','YES','',20,'',143,'Organization.Organization_ID','','yes','yes',''),(2006,'','Sequencing_Library','Vector Type','Vector_Type','Hidden,Obsolete','',7,'Vector_Type','enum(\'Plasmid\',\'Fosmid\',\'Cosmid\',\'BAC\')','','YES','',20,'',143,'','','yes','yes',''),(2007,'','Sequencing_Library','Vector Catalog Number','Vector_Catalog_Number','Hidden','',8,'Vector_Catalog_Number','text','','YES','',20,'',143,'','','yes','yes',''),(2008,'Antibiotic concentration (ug/mL) required for this library ','Sequencing_Library','Antibiotic Conc. (ug/mL)','Antibiotic_Concentration','','',33,'Antibiotic_Concentration','float','','YES','',20,'',143,'','','yes','yes',''),(2009,'','Sequencing_Library','3Prime Restriction Site','3Prime_Restriction_Site__ID','Hidden,NewLink','Restriction_Site_ID',34,'FK3Prime_Restriction_Site__ID','int(11)','MUL','YES','',20,'',143,'Restriction_Site.Restriction_Site_ID','','yes','yes',''),(2010,'','Sequencing_Library','5Prime Restriction Site','5Prime_Restriction_Site__ID','Hidden,NewLink','Restriction_Site_ID',35,'FK5Prime_Restriction_Site__ID','int(11)','MUL','YES','',20,'',143,'Restriction_Site.Restriction_Site_ID','','yes','yes',''),(2011,'','Stock','Grp','Grp__ID','Mandatory','Grp_ID',22,'FK_Grp__ID','int(11)','MUL','NO','',20,'',7,'Grp.Grp_ID','','yes','no',''),(2012,'','Study','Study ID','ID','Primary','Study_Name',1,'Study_ID','int(11)','PRI','NO','',20,'',144,'','','yes','no',''),(2013,'','Study','Name','Name','Mandatory','',2,'Study_Name','varchar(40)','UNI','NO','',20,'^.{0,40}$',144,'','','yes','no',''),(2014,'','Study','Description','Description','','',3,'Study_Description','text','','YES','',20,'',144,'','','yes','no',''),(2015,'','Study','Initiated','Initiated','','',4,'Study_Initiated','date','','YES','<TODAY>',20,'',144,'','','yes','no',''),(2016,'','Submission','DateTime','DateTime','','',2,'Submission_DateTime','datetime','','YES','<NOW>',20,'',89,'','','yes','yes',''),(2017,'','Submission','Source','Source','','',3,'Submission_Source','enum(\'External\',\'Internal\')','','YES','',20,'',89,'','','yes','no',''),(2018,'','Submission','Submitted Employee','Submitted_Employee__ID','','Employee_ID',6,'FKSubmitted_Employee__ID','int(11)','MUL','YES','',20,'',89,'Employee.Employee_ID','','yes','no',''),(2019,'','Submission','Additional Comments','Comments','','',7,'Submission_Comments','text','','YES','',20,'',89,'','','yes','no',''),(2020,'','Submission','Approved Employee','Approved_Employee__ID','','Employee_ID',8,'FKApproved_Employee__ID','int(11)','MUL','YES','',20,'',89,'Employee.Employee_ID','','yes','no',''),(2021,'','Submission','Approved DateTime','Approved_DateTime','','',9,'Approved_DateTime','datetime','','YES','',20,'',89,'','','yes','yes',''),(2022,'','Submission_Detail','Submission Detail ID','ID','Primary','',1,'Submission_Detail_ID','int(11)','PRI','NO','',20,'',145,'','','yes','no',''),(2023,'','Submission_Detail','Submission','Submission__ID','','Submission_ID',2,'FK_Submission__ID','int(11)','MUL','NO','',20,'',145,'Submission.Submission_ID','','yes','no',''),(2024,'','Submission_Detail','Submission DBTable','Submission_DBTable__ID','','DBTable_ID',3,'FKSubmission_DBTable__ID','int(11)','MUL','NO','',20,'',145,'DBTable.DBTable_ID','','yes','no',''),(2025,'','Submission_Detail','Reference','Reference','','',4,'Reference','varchar(40)','','NO','',20,'^.{0,40}$',145,'','','yes','no',''),(2026,'','Transposon_Pool','Transposon Pool ID','ID','Primary','',1,'Transposon_Pool_ID','int(11)','PRI','NO','',20,'',146,'','','yes','no',''),(2028,'','Transposon_Pool','Transposon','Transposon__ID','Mandatory','Transposon_ID',3,'FK_Transposon__ID','int(11)','MUL','NO','',20,'',146,'Transposon.Transposon_ID','','yes','no',''),(2029,'','Transposon_Pool','Optical Density','Optical_Density__ID','','Optical_Density_ID',4,'FK_Optical_Density__ID','int(11)','MUL','YES','',20,'',146,'Optical_Density.Optical_Density_ID','','yes','no',''),(2031,'','Transposon_Pool','Reads Required','Reads_Required','','',6,'Reads_Required','int(11)','','YES','',20,'',146,'','','yes','no',''),(2032,'','Transposon_Pool','Pipeline','Pipeline','Mandatory','',7,'Pipeline','enum(\'Standard\',\'Gateway\',\'PCR/Gateway (pGATE)\')','','YES','',20,'',146,'','','yes','no',''),(2033,'','Tube','Plate','Plate__ID','Mandatory','Plate_ID',2,'FK_Plate__ID','int(11)','MUL','YES','',20,'',79,'Plate.Plate_ID','','yes','no',''),(2034,'','Tube','Quantity Units','Quantity_Units','Hidden','',4,'Tube_Quantity_Units','enum(\'ml\',\'ul\',\'mg\',\'ug\',\'ng\',\'pg\')','','YES','',20,'',79,'','','yes','no',''),(2038,'','Version','Version ID','ID','Primary','Version_Name',1,'Version_ID','int(11)','PRI','NO','',20,'',147,'','','yes','no',''),(2039,'','Version','Name','Name','','',2,'Version_Name','varchar(8)','','YES','',20,'^.{0,8}$',147,'','','yes','no',''),(2040,'','Version','Description','Description','','',3,'Version_Description','text','','YES','',20,'',147,'','','yes','no',''),(2041,'','Version','Release Date','Release_Date','','',4,'Release_Date','date','','YES','',20,'',147,'','','yes','no',''),(2042,'','Version','Last Modified Date','Last_Modified_Date','','',5,'Last_Modified_Date','date','','YES','',20,'',147,'','','yes','no',''),(2043,'','Warranty','time','time','','',7,'time','datetime','','YES','',20,'',83,'','','yes','no',''),(2044,'','cDNA_Library','Sequencing Library','Sequencing_Library__ID','Mandatory','Sequencing_Library_ID',2,'FK_Sequencing_Library__ID','int(11)','MUL','NO','',20,'',91,'Sequencing_Library.Sequencing_Library_ID','','yes','yes',''),(2051,'','Concentrations','Sample','Sample__ID','','Sample_ID',7,'FK_Sample__ID','int(11)','MUL','NO','',20,'',23,'Sample.Sample_ID','','yes','no',''),(2052,'','Optical_Density','Sample','Sample__ID','','Sample_ID',9,'FK_Sample__ID','int(11)','MUL','NO','',20,'',53,'Sample.Sample_ID','','yes','no',''),(2053,'','Clone_Sequence','Sample','Sample__ID','','Sample_ID',22,'FK_Sample__ID','int(11)','MUL','NO','',20,'',15,'Sample.Sample_ID','','yes','no',''),(2062,'','Barcode_Label','Setting','Setting__ID','','Setting_ID',8,'FK_Setting__ID','int(11)','MUL','NO','',20,'',2,'Setting.Setting_ID','','yes','no',''),(2075,'','DepartmentSetting','DepartmentSetting ID','ID','Primary','',1,'DepartmentSetting_ID','int(11)','PRI','NO','',20,'',152,'','','yes','no',''),(2076,'','DepartmentSetting','Setting','Setting__ID','','Setting_ID',2,'FK_Setting__ID','int(11)','MUL','YES','',20,'',152,'Setting.Setting_ID','','yes','no',''),(2077,'','DepartmentSetting','Department','Department__ID','','Department_ID',3,'FK_Department__ID','int(11)','MUL','YES','',20,'',152,'Department.Department_ID','','yes','no',''),(2078,'','DepartmentSetting','Setting Value','Setting_Value','','',4,'Setting_Value','char(40)','','YES','',20,'',152,'','','yes','no',''),(2079,'','Gel','Directory','Directory','','',5,'Gel_Directory','varchar(80)','','NO','',20,'^.{0,80}$',37,'','','yes','no',''),(2080,'','Gel','Status','Status','','',6,'Status','enum(\'Active\',\'Failed\',\'On_hold\',\'lane tracking\',\'run bandleader\',\'bandleader completed\',\'bandleader failure\',\'finished\',\'sizes imported\',\'size importing failure\')','','YES','Active',20,'',37,'','','yes','no',''),(2095,'','PoolSample','Sample Quantity Units','Sample_Quantity_Units','','',8,'Sample_Quantity_Units','enum(\'ml\',\'ul\',\'mg\',\'ug\',\'ng\',\'pg\')','','YES','',20,'',131,'','','yes','no',''),(2096,'','PoolSample','Sample Quantity','Sample_Quantity','','',9,'Sample_Quantity','float','','YES','',20,'',131,'','','yes','no',''),(2103,'','Barcode_Label','Label Descriptive Name','Label_Descriptive_Name','','',9,'Label_Descriptive_Name','char(40)','','NO','',20,'',2,'','','yes','no',''),(2111,'','Sample_Pool','Sample Pool ID','ID','Primary','',1,'Sample_Pool_ID','int(11)','PRI','NO','',20,'',157,'','','yes','no',''),(2112,'','Sample_Pool','Pool','Pool__ID','','Pool_ID',2,'FK_Pool__ID','int(11)','UNI','NO','',20,'',157,'Pool.Pool_ID','','yes','no',''),(2113,'','Sample_Pool','Target Plate','Target_Plate__ID','','Plate_ID',3,'FKTarget_Plate__ID','int(11)','UNI','NO','',20,'',157,'Plate.Plate_ID','','yes','no',''),(2120,'','ReArray_Plate','ReArray Plate ID','ID','Primary','',1,'ReArray_Plate_ID','int(11)','PRI','NO','',20,'',158,'','','yes','no',''),(2138,'','Stock','Barcode Label','Barcode_Label__ID','Mandatory,Obsolete','Barcode_Label_ID',23,'FK_Barcode_Label__ID','int(11)','MUL','YES','',20,'',7,'Barcode_Label.Barcode_Label_ID','','yes','no',''),(2139,'Custom Identifier ID (optional)','Stock','Identifier Number','Identifier_Number','','',7,'Identifier_Number','varchar(80)','MUL','YES','',20,'^.{0,80}$',7,'','','yes','no',''),(2140,'Type of Identifier ID (if used)','Stock','Identifier Number Type','Identifier_Number_Type','','',8,'Identifier_Number_Type','enum(\'Component Number\',\'Reference ID\')','MUL','YES','',20,'',7,'','','yes','no',''),(2141,'','Agilent_Assay','Agilent Assay ID','ID','Primary','concat(Agilent_Assay_ID,\' : \',Agilent_Assay_Name)',1,'Agilent_Assay_ID','int(11)','PRI','NO','',20,'',160,'','','yes','no',''),(2142,'','Agilent_Assay','Name','Name','','',2,'Agilent_Assay_Name','varchar(255)','MUL','NO','',20,'^.{0,255}$',160,'','','yes','no',''),(2143,'','DB_Form','Form Order','Form_Order','','',3,'Form_Order','int(2)','','YES','1',20,'',108,'','','yes','no',''),(2144,'','DB_Login','DB Login ID','ID','Primary','',1,'DB_Login_ID','int(11)','PRI','NO','',20,'',161,'','','yes','no',''),(2145,'','DB_Login','Employee','Employee__ID','','Employee_ID',2,'FK_Employee__ID','int(11)','MUL','NO','',20,'',161,'Employee.Employee_ID','','yes','no',''),(2146,'','DB_Login','DB User','DB_User','','',3,'DB_User','char(40)','','NO','',20,'',161,'','','yes','no',''),(2147,'','Error_Check','Description','Description','','',10,'Description','text','','YES','',20,'',32,'','','yes','no',''),(2148,'','Error_Check','Action','Action','','',11,'Action','text','','YES','',20,'',32,'','','yes','no',''),(2149,'','Error_Check','Priority','Priority','','',12,'Priority','mediumtext','','YES','',20,'',32,'','','yes','no',''),(2150,'','Extraction','Extraction ID','ID','Primary','',1,'Extraction_ID','int(11)','PRI','NO','',20,'',162,'','','yes','no',''),(2151,'','Extraction','Source Plate','Source_Plate__ID','','Plate_ID',2,'FKSource_Plate__ID','int(11)','MUL','NO','',20,'',162,'Plate.Plate_ID','','yes','no',''),(2152,'','Extraction','Target Plate','Target_Plate__ID','','Plate_ID',3,'FKTarget_Plate__ID','int(11)','MUL','NO','',20,'',162,'Plate.Plate_ID','','yes','no',''),(2153,'','Extraction_Details','Extraction Details ID','ID','Primary','',1,'Extraction_Details_ID','int(11)','PRI','NO','',20,'',163,'','','yes','no',''),(2154,'','Extraction_Details','Extraction Sample','Extraction_Sample__ID','','Extraction_Sample_ID',2,'FK_Extraction_Sample__ID','int(11)','MUL','NO','',20,'',163,'Extraction_Sample.Extraction_Sample_ID','','yes','no',''),(2156,'','Extraction_Details','Isolated Employee','Isolated_Employee__ID','','Employee_ID',4,'FKIsolated_Employee__ID','int(11)','MUL','YES','',20,'',163,'Employee.Employee_ID','','yes','no',''),(2157,'','Extraction_Details','Disruption Method','Disruption_Method','','',5,'Disruption_Method','enum(\'Homogenized\',\'Sheared\')','','YES','',20,'',163,'','','yes','no',''),(2158,'','Extraction_Details','Isolation Method','Isolation_Method','','',6,'Isolation_Method','enum(\'Trizol\',\'Qiagen Kit\')','','YES','',20,'',163,'','','yes','no',''),(2159,'','Extraction_Details','Resuspension Volume','Resuspension_Volume','','',7,'Resuspension_Volume','int(11)','','YES','',20,'',163,'','','yes','no',''),(2160,'','Extraction_Details','Resuspension Volume Units','Resuspension_Volume_Units','','',8,'Resuspension_Volume_Units','enum(\'ul\')','','YES','',20,'',163,'','','yes','no',''),(2163,'','Extraction_Details','Agilent Assay','Agilent_Assay__ID','','Agilent_Assay_ID',11,'FK_Agilent_Assay__ID','int(11)','MUL','NO','',20,'',163,'Agilent_Assay.Agilent_Assay_ID','','yes','no',''),(2164,'','Extraction_Details','Assay Quality','Assay_Quality','','',12,'Assay_Quality','enum(\'Degraded\',\'Partially Degraded\',\'Good\')','','YES','',20,'',163,'','','yes','no',''),(2165,'','Extraction_Details','Assay Quantity','Assay_Quantity','','',13,'Assay_Quantity','int(11)','','YES','',20,'',163,'','','yes','no',''),(2166,'','Extraction_Details','Assay Quantity Units','Assay_Quantity_Units','','',14,'Assay_Quantity_Units','enum(\'ug/ul\',\'ng/ul\',\'pg/ul\')','','YES','',20,'',163,'','','yes','no',''),(2167,'','Extraction_Details','Total Yield','Total_Yield','','',15,'Total_Yield','int(11)','','YES','',20,'',163,'','','yes','no',''),(2168,'','Extraction_Details','Total Yield Units','Total_Yield_Units','','',16,'Total_Yield_Units','enum(\'ug\',\'ng\',\'pg\')','','YES','',20,'',163,'','','yes','no',''),(2169,'','Extraction_Sample','Extraction Sample ID','ID','Primary','',1,'Extraction_Sample_ID','int(11)','PRI','NO','',20,'',164,'','','yes','no',''),(2170,'','Extraction_Sample','Sample','Sample__ID','Mandatory','Sample_ID',2,'FK_Sample__ID','int(11)','MUL','NO','',20,'',164,'Sample.Sample_ID','','yes','no',''),(2171,'','Extraction_Sample','Library','Library__Name','Searchable','Library_Name',3,'FK_Library__Name','char(6)','MUL','YES','',20,'',164,'Library.Library_Name','','yes','no',''),(2173,'','Extraction_Sample','Volume','Volume','','',5,'Volume','int(11)','','YES','',20,'',164,'','','yes','no',''),(2174,'','Extraction_Sample','Original Plate','Original_Plate__ID','','Plate_ID',6,'FKOriginal_Plate__ID','int(11)','MUL','YES','',20,'',164,'Plate.Plate_ID','','yes','no',''),(2175,'','Extraction_Sample','Type','Type','','',7,'Extraction_Sample_Type','enum(\'DNA\',\'RNA\',\'Protein\',\'Mixed\',\'Amplicon\',\'Clone\',\'mRNA\',\'Tissue\',\'Cells\',\'RNA - DNase Treated\',\'cDNA\',\'1st strand cDNA\',\'Amplified cDNA\',\'Ditag\',\'Concatemer - Insert\',\'Concatemer - Cloned\')','','YES','Mixed',20,'',164,'','','yes','no',''),(2176,'','Library','Created Employee','Created_Employee__ID','Mandatory','Employee_ID',14,'FKCreated_Employee__ID','int(11)','MUL','YES','',20,'',40,'Employee.Employee_ID','','no','no',''),(2177,'','Message','Grp','Grp__ID','','Grp_ID',8,'FK_Grp__ID','int(11)','MUL','YES','',20,'',46,'Grp.Grp_ID','','yes','no',''),(2178,'','Original_Source','Original Source ID','ID','Primary','concat(Original_Source_ID,\': \', Original_Source_Name)',1,'Original_Source_ID','int(11)','PRI','NO','',20,'',165,'','','yes','yes',''),(2193,'','Sample_Alias','Sample Alias ID','ID','Primary','',1,'Sample_Alias_ID','int(11)','PRI','NO','',20,'',169,'','','yes','no',''),(2194,'','Sample_Alias','Sample','Sample__ID','','Sample_ID',2,'FK_Sample__ID','int(11)','MUL','NO','',20,'',169,'Sample.Sample_ID','','yes','no',''),(2195,'','Sample_Alias','Source Organization','Source_Organization__ID','','Organization_ID',3,'FKSource_Organization__ID','int(11)','MUL','NO','',20,'',169,'Organization.Organization_ID','','yes','no',''),(2196,'','Sample_Alias','Alias','Alias','','',4,'Alias','varchar(40)','MUL','YES','',20,'^.{0,40}$',169,'','','yes','no',''),(2197,'','Sample_Alias','Alias Type','Alias_Type','','',5,'Alias_Type','varchar(40)','MUL','YES','',20,'^.{0,40}$',169,'','','yes','no',''),(2200,'','Sequencer_Type','By Quadrant','By_Quadrant','','',13,'By_Quadrant','enum(\'Yes\',\'No\')','','YES','No',20,'',74,'','','yes','no',''),(2202,'The culmulative amount of sample withdrawn from this tube. This field is automatically populated by the LIMS based on amounts specified on transfer/aliquot steps. It should not be manually edited unless manual override is required.','Tube','Quantity Used','Quantity_Used','Hidden','',5,'Quantity_Used','float','','YES','',20,'',79,'','','yes','no',''),(2203,'','Tube','Quantity Used Units','Quantity_Used_Units','Hidden','',6,'Quantity_Used_Units','enum(\'ml\',\'ul\',\'mg\',\'ug\',\'ng\',\'pg\')','','YES','',20,'',79,'','','yes','no',''),(2204,'','Barcode_Label','Type','Type','','',10,'Barcode_Label_Type','enum(\'plate\',\'mulplate\',\'solution\',\'equipment\',\'source\',\'employee\',\'microarray\')','','YES','',20,'',2,'','','yes','no',''),(2205,'','Printer','Printer ID','ID','Primary','Printer_Name',1,'Printer_ID','int(11)','PRI','NO','',20,'',171,'','','yes','no',''),(2206,'','Printer','Name','Name','','',2,'Printer_Name','varchar(40)','MUL','YES','',20,'^.{0,40}$',171,'','','yes','no',''),(2207,'','Printer','DPI','DPI','','',3,'Printer_DPI','int(11)','','NO','',20,'',171,'','','yes','no',''),(2208,'','Printer','Location','Location','','',4,'Printer_Location','varchar(40)','','YES','',20,'^.{0,40}$',171,'','','yes','no',''),(2209,'','Primer_Customization','Direction','Direction','','',4,'Direction','enum(\'Forward\',\'Reverse\',\'Unknown\')','','YES','Unknown',20,'',97,'','','yes','no',''),(2210,'','Primer_Customization','Amplicon Length','Amplicon_Length','','',5,'Amplicon_Length','int(11)','','YES','',20,'',97,'','','yes','no',''),(2211,'','Extraction_Sample','Plate Number','Plate_Number','','',4,'Plate_Number','int(11)','','YES','',20,'',164,'','','yes','no',''),(2212,'','Extraction_Sample','Original Well','Original_Well','','',8,'Original_Well','char(3)','','YES','',20,'',164,'','','yes','no',''),(2213,'','Extraction_Details','Extraction Size Estimate','Extraction_Size_Estimate','','',17,'Extraction_Size_Estimate','int(11)','','YES','',20,'',163,'','','yes','no',''),(2214,'','Sample','Parent Sample','Parent_Sample__ID','','Sample_ID',5,'FKParent_Sample__ID','int(11)','MUL','YES','',20,'',142,'Sample.Sample_ID','','yes','no',''),(2215,'','Primer_Plate','Notes','Notes','','',7,'Notes','varchar(40)','','YES','',20,'^.{0,40}$',133,'','','yes','no',''),(2216,'','Primer_Plate','Notify List','Notify_List','','',8,'Notify_List','text','','YES','',20,'',133,'','','yes','no',''),(2217,'','Attribute','Attribute ID','ID','Primary','Attribute_Name',1,'Attribute_ID','int(11)','PRI','NO','',20,'',172,'','','yes','no',''),(2218,'','Attribute','Name','Name','','',2,'Attribute_Name','varchar(40)','MUL','YES','',20,'^.{0,40}$',172,'','','yes','no',''),(2219,'','Attribute','Format','Format','','',3,'Attribute_Format','varchar(40)','','YES','',20,'^.{0,40}$',172,'','','yes','no',''),(2220,'','Attribute','Type','Type','','',4,'Attribute_Type','varchar(40)','','YES','',20,'^.{0,40}$',172,'','','yes','no',''),(2221,'','Attribute','Grp','Grp__ID','','Grp_ID',5,'FK_Grp__ID','int(11)','MUL','NO','',20,'',172,'Grp.Grp_ID','','yes','no',''),(2222,'','Attribute','Inherited','Inherited','','',6,'Inherited','enum(\'Yes\',\'No\')','','NO','No',20,'',172,'','','yes','no',''),(2223,'','Attribute','Class','Class','','',7,'Attribute_Class','varchar(40)','','YES','',20,'^.{0,40}$',172,'','','yes','no',''),(2224,'','Band','Band ID','ID','Primary','',1,'Band_ID','int(11) unsigned','PRI','NO','',20,'',173,'','','yes','no',''),(2225,'','Band','Size','Size','','',2,'Band_Size','int(10) unsigned','','YES','',20,'',173,'','','yes','no',''),(2226,'','Band','Number','Number','','',3,'Band_Number','int(4) unsigned','','YES','',20,'',173,'','','yes','no',''),(2227,'','Band','Parent Band','Parent_Band__ID','','Band_ID',4,'FKParent_Band__ID','int(11)','MUL','YES','',20,'',173,'Band.Band_ID','','yes','no',''),(2228,'','Band','Lane','Lane__ID','','Lane_ID',5,'FK_Lane__ID','int(11) unsigned','MUL','YES','',20,'',173,'Lane.Lane_ID','','yes','no',''),(2229,'','Band','Intensity','Intensity','','',6,'Band_Intensity','enum(\'Unspecified\',\'Weak\',\'Medium\',\'Strong\')','','YES','',20,'',173,'','','yes','no',''),(2230,'','Clone_Details','Size Estimate','Size_Estimate','','',14,'Size_Estimate','int(11)','','YES','',20,'',103,'','','yes','no',''),(2231,'','DB_Form','Finish','Finish','','',9,'Finish','int(11)','','YES','',20,'',108,'','','yes','no',''),(2232,'','Extraction_Details','Band','Band__ID','','Band_ID',18,'FK_Band__ID','int(11)','MUL','NO','',20,'',163,'Band.Band_ID','','yes','no',''),(2233,'','Gel','Bandleader Version','Bandleader_Version','','',8,'Bandleader_Version','varchar(40)','','YES','2.3.5',20,'^.{0,40}$',37,'','','yes','no',''),(2234,'','Gel','Agarose Percent','Agarose_Percent','','',9,'Agarose_Percent','float(10,2)','','YES','1.20',20,'',37,'','','yes','no',''),(2235,'','Gel','File Extension Type','File_Extension_Type','','',10,'File_Extension_Type','enum(\'sizes\',\'none\')','','YES','none',20,'',37,'','','yes','no',''),(2236,'','How_To_Object','How To Object ID','ID','Primary','How_To_Object_Name',1,'How_To_Object_ID','int(11)','PRI','NO','',20,'',174,'','','yes','no',''),(2237,'','How_To_Object','Name','Name','','',2,'How_To_Object_Name','varchar(80)','UNI','NO','',20,'^.{0,80}$',174,'','','yes','no',''),(2238,'','How_To_Object','Description','Description','','',3,'How_To_Object_Description','text','','YES','',20,'',174,'','','yes','no',''),(2239,'','How_To_Step','How To Step ID','ID','Primary','',1,'How_To_Step_ID','int(11)','PRI','NO','',20,'',175,'','','yes','no',''),(2240,'','How_To_Step','Number','Number','','',2,'How_To_Step_Number','int(11)','','YES','',20,'',175,'','','yes','no',''),(2241,'','How_To_Step','Description','Description','','',3,'How_To_Step_Description','text','','YES','',20,'',175,'','','yes','no',''),(2242,'','How_To_Step','Result','Result','','',4,'How_To_Step_Result','text','','YES','',20,'',175,'','','yes','no',''),(2243,'','How_To_Step','Users','Users','','',5,'Users','set(\'A\',\'T\',\'L\')','','YES','T',20,'',175,'','','yes','no',''),(2244,'','How_To_Step','Mode','Mode','','',6,'Mode','set(\'Scanner\',\'PC\')','','YES','PC',20,'',175,'','','yes','no',''),(2245,'','How_To_Step','How To Topic','How_To_Topic__ID','','How_To_Topic_ID',7,'FK_How_To_Topic__ID','int(11)','MUL','YES','',20,'',175,'How_To_Topic.How_To_Topic_ID','','yes','no',''),(2246,'','How_To_Topic','How To Topic ID','ID','Primary','',1,'How_To_Topic_ID','int(11)','PRI','NO','',20,'',176,'','','yes','no',''),(2247,'','How_To_Topic','Topic Number','Topic_Number','','',2,'Topic_Number','int(11)','','YES','',20,'',176,'','','yes','no',''),(2248,'','How_To_Topic','Topic Name','Topic_Name','','',3,'Topic_Name','varchar(80)','','NO','',20,'^.{0,80}$',176,'','','yes','no',''),(2249,'','How_To_Topic','Topic Type','Topic_Type','','',4,'Topic_Type','enum(\'\',\'New\',\'Update\',\'Find\',\'Edit\')','','NO','',20,'',176,'','','yes','no',''),(2250,'','How_To_Topic','Topic Description','Topic_Description','','',5,'Topic_Description','text','','YES','',20,'',176,'','','yes','no',''),(2251,'','How_To_Topic','How To Object','How_To_Object__ID','','How_To_Object_ID',6,'FK_How_To_Object__ID','int(11)','MUL','YES','',20,'',176,'How_To_Object.How_To_Object_ID','','yes','no',''),(2252,'','Hybrid_Original_Source','Hybrid Original Source ID','ID','Primary','',1,'Hybrid_Original_Source_ID','int(11)','PRI','NO','',20,'',177,'','','yes','no',''),(2254,'','Hybrid_Original_Source','Child Original Source','Child_Original_Source__ID','','Original_Source_ID',3,'FKChild_Original_Source__ID','int(11)','MUL','YES','',20,'',177,'Original_Source.Original_Source_ID','','yes','no',''),(2263,'','Lab_Request','Lab Request ID','ID','Primary','',1,'Lab_Request_ID','int(11)','PRI','NO','',20,'',180,'','','yes','no',''),(2264,'','Lab_Request','Employee','Employee__ID','','Employee_ID',2,'FK_Employee__ID','int(11)','MUL','NO','',20,'',180,'Employee.Employee_ID','','yes','no',''),(2265,'','Lab_Request','Request Date','Request_Date','','',3,'Request_Date','date','','NO','0000-00-00',20,'',180,'','','yes','yes',''),(2267,'','Lane','Well','Well','','',2,'Well','char(3)','','NO','',20,'',181,'','','yes','no',''),(2270,'','Lane','Lane ID','ID','Primary','',5,'Lane_ID','int(11)','PRI','NO','',20,'',181,'','','yes','no',''),(2271,'','Lane','Sample','Sample__ID','','Sample_ID',6,'FK_Sample__ID','int(11)','','YES','',20,'',181,'Sample.Sample_ID','','yes','no',''),(2272,'','Lane','Band Size Estimate','Band_Size_Estimate','','',7,'Band_Size_Estimate','int(11)','','YES','',20,'',181,'','','yes','no',''),(2273,'','Library','Original Source','Original_Source__ID','Mandatory','Original_Source_ID',16,'FK_Original_Source__ID','int(11)','MUL','NO','',20,'',40,'Original_Source.Original_Source_ID','','no','no',''),(2274,'','Library_Plate','Problematic Wells','Problematic_Wells','','',10,'Problematic_Wells','text','','YES','',20,'',126,'','','no','yes',''),(2275,'','Library_Plate','Empty Wells','Empty_Wells','','',11,'Empty_Wells','text','','YES','',20,'',126,'','','no','yes',''),(2276,'','Library_Source','Library Source ID','ID','Primary','',1,'Library_Source_ID','int(11)','PRI','NO','',20,'',182,'','','yes','no',''),(2277,'','Library_Source','Source','Source__ID','','Source_ID',2,'FK_Source__ID','int(11)','MUL','NO','',20,'',182,'Source.Source_ID','','yes','no',''),(2278,'','Library_Source','Library','Library__Name','Mandatory','Library_Name',3,'FK_Library__Name','varchar(40)','MUL','NO','',20,'',182,'Library.Library_Name','','yes','no',''),(2279,'','Ligation','Source','Source__ID','','Source_ID',10,'FK_Source__ID','int(11)','MUL','NO','',20,'',87,'Source.Source_ID','','yes','no',''),(2280,'','Microtiter','Source','Source__ID','','Source_ID',15,'FK_Source__ID','int(11)','MUL','NO','',20,'',86,'Source.Source_ID','','yes','no',''),(2281,'Concise reference name for this tissue/organism information','Original_Source','Original Source Name','Name','Mandatory','',3,'Original_Source_Name','varchar(40)','UNI','NO','',20,'^.{1,40}$',165,'','','yes','yes',''),(2282,'Organism name only','Original_Source','Organism','Organism','Hidden','',24,'Organism','varchar(40)','','YES','',20,'^.{0,40}$',165,'','','yes','yes',''),(2283,'Sex, eg. Male, Female','Original_Source','Sex','Sex','','',7,'Sex','varchar(20)','','YES','',20,'^.{0,20}$',165,'','','yes','yes',''),(2284,'Type of Tissue, eg. Lung, Heart','Original_Source','Tissue','Tissue','Hidden,Obsolete','',26,'Tissue','varchar(40)','','YES','',20,'^.{0,40}$',165,'','','yes','yes',''),(2285,'','Original_Source','Strain','Strain','','',9,'Strain','varchar(40)','','YES','',20,'^.{0,40}$',165,'','','yes','yes',''),(2286,'Type of Host, eg E. coli','Original_Source','Host','Host','','',10,'Host','text','','NO','',20,'',165,'','','yes','yes',''),(2287,'Additional information (if applicable)','Original_Source','Description','Description','','',20,'Description','text','','YES','',20,'',165,'','','yes','yes',''),(2288,'Person supplying this information (collaborator or internal contact)','Original_Source','Contact','Contact__ID','Mandatory,NewLink','Contact_ID',12,'FK_Contact__ID','int(11)','MUL','YES','',20,'',165,'Contact.Contact_ID','','yes','yes',''),(2289,'Employee uploading this information','Original_Source','Created Employee','Created_Employee__ID','Mandatory,Searchable','Employee_ID',13,'FKCreated_Employee__ID','int(11)','MUL','YES','',20,'',165,'Employee.Employee_ID','','yes','yes',''),(2290,'When the original source information is first entered','Original_Source','Defined Date','Defined_Date','','',14,'Defined_Date','date','','NO','0000-00-00',20,'',165,'','','yes','yes',''),(2297,'','Original_Source_Attribute','Original Source','Original_Source__ID','','Original_Source_ID',1,'FK_Original_Source__ID','int(11)','MUL','NO','',20,'',184,'Original_Source.Original_Source_ID','','yes','no',''),(2298,'','Original_Source_Attribute','Attribute','Attribute__ID','','Attribute_ID',2,'FK_Attribute__ID','int(11)','MUL','NO','',20,'',184,'Attribute.Attribute_ID','','yes','no',''),(2299,'','Original_Source_Attribute','Attribute Value','Attribute_Value','','',3,'Attribute_Value','text','','NO','',20,'',184,'','','yes','no',''),(2300,'','Original_Source_Attribute','Original Source Attribute ID','ID','Primary','',4,'Original_Source_Attribute_ID','int(11)','PRI','NO','',20,'',184,'','','yes','no',''),(2305,'','Pipeline','Pipeline ID','ID','Primary','concat(Pipeline_Code,\' : \', Pipeline_Name)',1,'Pipeline_ID','int(11)','PRI','NO','',20,'',187,'','','yes','no',''),(2306,'','Pipeline','Name','Name','','',2,'Pipeline_Name','varchar(40)','','YES','',20,'^.{0,40}$',187,'','','yes','no',''),(2307,'','Pipeline','Grp','Grp__ID','','Grp_ID',3,'FK_Grp__ID','int(11)','MUL','NO','',20,'',187,'Grp.Grp_ID','','yes','no',''),(2308,'','Plate','Current Volume','Current_Volume','','',17,'Current_Volume','float','','YES','',20,'',59,'','','yes','no',''),(2309,'','Plate','Current Volume Units','Current_Volume_Units','','',18,'Current_Volume_Units','enum(\'l\',\'ml\',\'ul\',\'nl\',\'g\',\'mg\',\'ug\',\'ng\')','','NO','ul',20,'',59,'','','yes','no',''),(2310,'','Plate','Content Type','Content_Type','','',19,'Plate_Content_Type','enum(\'DNA\',\'RNA\',\'Protein\',\'Mixed\',\'Amplicon\',\'Clone\',\'mRNA\',\'Tissue\',\'Cells\',\'RNA - DNase Treated\',\'cDNA\',\'1st strand cDNA\',\'Amplified cDNA\',\'Ditag\',\'Concatemer - Insert\',\'Concatemer - Cloned\')','MUL','YES','',20,'',59,'','','yes','no',''),(2311,'','Plate','Parent Quadrant','Parent_Quadrant','','',20,'Parent_Quadrant','enum(\'\',\'a\',\'b\',\'c\',\'d\')','','NO','',20,'',59,'','','no','no',''),(2312,'','Plate','Parent Well','Parent_Well','','',21,'Plate_Parent_Well','char(3)','','NO','',20,'',59,'','','no','no',''),(2313,'','Plate_Format','Wells','Wells','','',11,'Wells','smallint(6)','','NO','1',20,'',60,'','','yes','no',''),(2314,'','Plate_PrimerPlateWell','Plate PrimerPlateWell ID','ID','Primary','',1,'Plate_PrimerPlateWell_ID','int(11)','PRI','NO','',20,'',188,'','','yes','no',''),(2315,'','Plate_PrimerPlateWell','Plate','Plate__ID','','Plate_ID',2,'FK_Plate__ID','int(11)','MUL','NO','',20,'',188,'Plate.Plate_ID','','yes','no',''),(2316,'','Plate_PrimerPlateWell','Primer Plate Well','Primer_Plate_Well__ID','','Primer_Plate_Well_ID',3,'FK_Primer_Plate_Well__ID','int(11)','MUL','NO','',20,'',188,'Primer_Plate_Well.Primer_Plate_Well_ID','','yes','no',''),(2317,'','Plate_PrimerPlateWell','Plate Well','Plate_Well','','',4,'Plate_Well','char(3)','MUL','YES','',20,'',188,'','','yes','no',''),(2318,'','Prep_Detail_Option','Prep Detail Option ID','ID','Primary','',1,'Prep_Detail_Option_ID','int(11)','PRI','NO','',20,'',189,'','','yes','no',''),(2319,'','Prep_Detail_Option','Protocol Step','Protocol_Step__ID','','Protocol_Step_ID',2,'FK_Protocol_Step__ID','int(11)','MUL','NO','',20,'',189,'Protocol_Step.Protocol_Step_ID','','yes','no',''),(2320,'','Prep_Detail_Option','Option Description','Option_Description','','',3,'Option_Description','text','','YES','',20,'',189,'','','yes','no',''),(2321,'','Prep_Detail_Option','Attribute','Attribute__ID','','Attribute_ID',4,'FK_Attribute__ID','int(11)','MUL','NO','',20,'',189,'Attribute.Attribute_ID','','yes','no',''),(2322,'','Prep_Details','Prep Details ID','ID','Primary','',1,'Prep_Details_ID','int(11)','PRI','NO','',20,'',190,'','','yes','no',''),(2323,'','Prep_Details','Prep','Prep__ID','','Prep_ID',2,'FK_Prep__ID','int(11)','MUL','NO','',20,'',190,'Prep.Prep_ID','','yes','no',''),(2324,'','Prep_Details','Attribute','Attribute__ID','','Attribute_ID',3,'FK_Attribute__ID','int(11)','MUL','NO','',20,'',190,'Attribute.Attribute_ID','','yes','no',''),(2325,'','Prep_Details','Value','Value','','',4,'Prep_Details_Value','text','','YES','',20,'',190,'','','yes','no',''),(2326,'','Primer_Plate','Lab Request','Lab_Request__ID','','Lab_Request_ID',9,'FK_Lab_Request__ID','int(11)','MUL','YES','',20,'',133,'Lab_Request.Lab_Request_ID','','yes','no',''),(2327,'','Primer_Plate_Well','Parent Primer Plate Well','Parent_Primer_Plate_Well__ID','','Primer_Plate_Well_ID',5,'FKParent_Primer_Plate_Well__ID','int(11)','MUL','NO','',20,'',134,'Primer_Plate_Well.Primer_Plate_Well_ID','','yes','no',''),(2348,'','ReArray','Sample','Sample__ID','','Sample_ID',6,'FK_Sample__ID','int(11)','MUL','YES','-1',20,'',70,'Sample.Sample_ID','','yes','no',''),(2349,'','ReArray_Plate','Source','Source__ID','','Source_ID',4,'FK_Source__ID','int(11)','MUL','NO','',20,'',158,'Source.Source_ID','','yes','no',''),(2350,'','ReArray_Request','Lab Request','Lab_Request__ID','','Lab_Request_ID',11,'FK_Lab_Request__ID','int(11)','MUL','YES','',20,'',140,'Lab_Request.Lab_Request_ID','','yes','no',''),(2351,'','Sample','Source','Source__ID','','Source_ID',6,'FK_Source__ID','int(11)','MUL','NO','',20,'',142,'Source.Source_ID','','no','no',''),(2352,'','Sample_Attribute','Sample','Sample__ID','','Sample_ID',1,'FK_Sample__ID','int(11)','MUL','NO','',20,'',193,'Sample.Sample_ID','','yes','no',''),(2353,'','Sample_Attribute','Attribute','Attribute__ID','','Attribute_ID',2,'FK_Attribute__ID','int(11)','MUL','NO','',20,'',193,'Attribute.Attribute_ID','','yes','no',''),(2354,'','Sample_Attribute','Attribute Value','Attribute_Value','','',3,'Attribute_Value','text','','NO','',20,'',193,'','','yes','no',''),(2355,'','Sample_Attribute','Sample Attribute ID','ID','Primary','',4,'Sample_Attribute_ID','int(11)','PRI','NO','',20,'',193,'','','yes','no',''),(2356,'','Source','Source ID','ID','Primary','concat(Source_Type,\'-\',Source_Number,\' \',Label)',1,'Source_ID','int(11)','PRI','NO','',20,'',194,'','','yes','yes',''),(2357,'(only applicable if this is an aliquot from another tracked source)','Source','Parent Source','Parent_Source__ID','','Source_ID',19,'FKParent_Source__ID','int(11)','MUL','YES','',20,'',194,'Source.Source_ID','','no','yes',''),(2358,'Name provided by external source/collaborator','Source','External Identifier','External_Identifier','','',3,'External_Identifier','varchar(40)','MUL','NO','',20,'^.{0,40}$',194,'','','yes','yes',''),(2359,'Format in which the starting material is stored','Source','Type','Type','Mandatory','',1,'Source_Type','enum(\'Library_Segment\',\'RNA_DNA_Source\',\'ReArray_Plate\',\'Ligation\',\'Microtiter\',\'Xformed_Cells\',\'Sorted_Cell\',\'Tissue_Sample\',\'External\',\'Cells\')','MUL','YES','',20,'',194,'','','no','yes',''),(2360,'','Source','Status','Status','Mandatory','',16,'Source_Status','enum(\'Active\',\'Reserved\',\'Inactive\',\'Thrown Out\')','','YES','Active',20,'',194,'','','yes','yes',''),(2361,'Label attached to the sample container','Source','Label','Label','','',6,'Label','varchar(40)','MUL','YES','',20,'^.{0,40}$',194,'','','yes','yes',''),(2362,'Reference to sample origin information','Source','Original Source','Original_Source__ID','Mandatory','Original_Source_ID',2,'FK_Original_Source__ID','int(11)','MUL','YES','',20,'',194,'Original_Source.Original_Source_ID','','no','yes',''),(2363,'','Source','Received Date','Received_Date','Mandatory','',8,'Received_Date','date','','NO','0000-00-00',20,'',194,'','','yes','yes',''),(2364,'Amount of source currently in stock','Source','Current Amount','Current_Amount','','',9,'Current_Amount','float','','YES','',20,'',194,'','','yes','yes',''),(2365,'Amount of source when received','Source','Original Amount','Original_Amount','','',10,'Original_Amount','float','','YES','',20,'',194,'','','no','yes',''),(2366,'','Source','Amount Units','Amount_Units','','',11,'Amount_Units','enum(\'\',\'ul\',\'ml\',\'ul/well\',\'mg\',\'ug\',\'ng\',\'pg\',\'Cells\',\'Embryos\',\'Litters\',\'Organs\',\'Animals\',\'Million Cells\')','','YES','',20,'',194,'','','yes','yes',''),(2367,'','Source','Received Employee','Received_Employee__ID','Mandatory','Employee_ID',14,'FKReceived_Employee__ID','int(11)','MUL','YES','',20,'',194,'Employee.Employee_ID','','no','yes',''),(2368,'Rack ID and an optional slot name','Source','Rack','Rack__ID','Mandatory,Searchable','Rack_ID',15,'FK_Rack__ID','int(11)','MUL','NO','<DEFAULT_LOCATION>',20,'',194,'Rack.Rack_ID','','yes','yes',''),(2369,'indexed number (for each type of sample)','Source','Number','Number','','',5,'Source_Number','varchar(40)','','YES','1',20,'^.{0,40}$',194,'','','yes','yes',''),(2370,'type of barcode label','Source','Barcode Label','Barcode_Label__ID','Mandatory','Barcode_Label_ID',17,'FK_Barcode_Label__ID','int(11)','MUL','NO','',20,'',194,'Barcode_Label.Barcode_Label_ID','','yes','yes',''),(2371,'additional information (if applicable) specific to this actual sample','Source','Notes','Notes','','',18,'Notes','text','','YES','',20,'',194,'','','yes','yes',''),(2372,'The variable in the formula which refers to the individual reagents (eg if formula = R*wells + DeadVolume; R is the reagent Parameter)','Standard_Solution','Reagent Parameter','Reagent_Parameter','Mandatory','',7,'Reagent_Parameter','varchar(40)','','YES','',20,'^.{0,40}$',58,'','','yes','yes',''),(2373,'','SubmissionVolume','SubmissionVolume ID','ID','Primary','',1,'SubmissionVolume_ID','int(11)','PRI','NO','',20,'',195,'','','yes','no',''),(2374,'','SubmissionVolume','Volume Name','Volume_Name','','',2,'Volume_Name','varchar(40)','','YES','',20,'^.{0,40}$',195,'','','yes','no',''),(2375,'','SubmissionVolume','Contact Employee','Contact_Employee__ID','','Employee_ID',3,'FKContact_Employee__ID','int(11)','MUL','NO','',20,'',195,'Employee.Employee_ID','','yes','no',''),(2376,'','SubmissionVolume','Submission Status','Submission_Status','','',4,'Submission_Status','enum(\'Sent\',\'In Process\',\'Pending\',\'Accepted\',\'Rejected\')','','YES','',20,'',195,'','','yes','no',''),(2377,'','SubmissionVolume','Submission DateTime','Submission_DateTime','','',5,'Submission_DateTime','date','','YES','<TODAY>',20,'',195,'','','yes','yes',''),(2378,'','SubmissionVolume','Volume Description','Volume_Description','','',6,'Volume_Description','text','','YES','',20,'',195,'','','yes','no',''),(2379,'','Submission_Alias','Submission Alias ID','ID','Primary','',1,'Submission_Alias_ID','int(11)','PRI','NO','',20,'',196,'','','yes','no',''),(2380,'','Submission_Alias','Trace Submission','Trace_Submission__ID','','Trace_Submission_ID',2,'FK_Trace_Submission__ID','int(11)','MUL','NO','',20,'',196,'Trace_Submission.Trace_Submission_ID','','yes','no',''),(2381,'','Submission_Alias','Submission Reference','Submission_Reference','','',3,'Submission_Reference','char(40)','','YES','',20,'',196,'','','yes','no',''),(2382,'','Submission_Alias','Submission Reference Type','Submission_Reference_Type','','',4,'Submission_Reference_Type','enum(\'Genbank_ID\',\'Accession_ID\')','MUL','YES','',20,'',196,'','','yes','no',''),(2383,'','Submission_Volume','Submission Volume ID','ID','Primary','',1,'Submission_Volume_ID','int(11)','PRI','NO','',20,'',197,'','','yes','no',''),(2384,'','Submission_Volume','Submission Target','Submission_Target','','',2,'Submission_Target','text','','YES','',20,'',197,'','','yes','no',''),(2385,'','Submission_Volume','Volume Name','Volume_Name','','',3,'Volume_Name','varchar(40)','UNI','NO','',20,'^.{0,40}$',197,'','','yes','no',''),(2386,'','Submission_Volume','Submission Date','Submission_Date','','',4,'Submission_Date','date','','YES','<TODAY>',20,'',197,'','','yes','yes',''),(2387,'','Submission_Volume','Submitter Employee','Submitter_Employee__ID','','Employee_ID',5,'FKSubmitter_Employee__ID','int(11)','MUL','YES','',20,'',197,'Employee.Employee_ID','','yes','no',''),(2388,'','Submission_Volume','Volume Status','Volume_Status','','',6,'Volume_Status','enum(\'In Process\',\'Bundled\',\'Submitted\',\'Accepted\',\'Rejected\')','','YES','',20,'',197,'','','yes','no',''),(2389,'','Submission_Volume','Volume Comments','Volume_Comments','','',7,'Volume_Comments','text','','YES','',20,'',197,'','','yes','no',''),(2390,'','Submission_Volume','Records','Records','','',8,'Records','int(11)','','NO','',20,'',197,'','','yes','no',''),(2391,'','Trace_Submission','Trace Submission ID','ID','Primary','',1,'Trace_Submission_ID','int(11)','PRI','NO','',20,'',198,'','','yes','no',''),(2393,'','Trace_Submission','Well','Well','','',3,'Well','char(4)','','NO','',20,'',198,'','','yes','no',''),(2394,'','Trace_Submission','Submission Status','Submission_Status','','',4,'Submission_Status','enum(\'Bundled\',\'In Process\',\'Accepted\',\'Rejected\')','','YES','',20,'',198,'','','yes','no',''),(2395,'','Trace_Submission','Sample','Sample__ID','','Sample_ID',5,'FK_Sample__ID','int(11)','MUL','NO','',20,'',198,'Sample.Sample_ID','','yes','no',''),(2396,'','Trace_Submission','Submitted Length','Submitted_Length','','',6,'Submitted_Length','int(11)','MUL','NO','',20,'',198,'','','yes','no',''),(2397,'','Trace_Submission','Submission Volume','Submission_Volume__ID','','Submission_Volume_ID',7,'FK_Submission_Volume__ID','int(11)','MUL','NO','',20,'',198,'Submission_Volume.Submission_Volume_ID','','yes','no',''),(2398,'','Transposon_Pool','Test Status','Test_Status','','',7,'Test_Status','enum(\'Test\',\'Production\')','','NO','Production',20,'',146,'','','yes','no',''),(2399,'','Transposon_Pool','Status','Status','','',8,'Status','enum(\'Data Pending\',\'Dilutions\',\'Ready For Pooling\',\'In Progress\',\'Complete\',\'Failed-Redo\')','','YES','',20,'',146,'','','yes','no',''),(2400,'','Transposon_Pool','Source','Source__ID','','Source_ID',9,'FK_Source__ID','int(11)','MUL','YES','',20,'',146,'Source.Source_ID','','yes','no',''),(2401,'','Transposon_Pool','Pool','Pool__ID','Mandatory','Pool_ID',10,'FK_Pool__ID','int(11)','MUL','YES','',20,'',146,'Pool.Pool_ID','','yes','no',''),(2402,'','Trigger','Trigger ID','ID','Primary','',1,'Trigger_ID','int(11)','PRI','NO','',20,'',199,'','','yes','no',''),(2403,'','Trigger','Table Name','Table_Name','','',2,'Table_Name','varchar(40)','','NO','',20,'^.{0,40}$',199,'','','yes','no',''),(2404,'','Trigger','Type','Type','','',3,'Trigger_Type','enum(\'SQL\',\'Perl\',\'Form\',\'Method\',\'Shell\')','','YES','',20,'',199,'','','yes','no',''),(2405,'','Trigger','Value','Value','','',4,'Value','text','','YES','',20,'',199,'','','yes','no',''),(2406,'','Trigger','Trigger On','Trigger_On','','',5,'Trigger_On','enum(\'update\',\'insert\',\'delete\')','','YES','',20,'',199,'','','yes','no',''),(2407,'','Trigger','Status','Status','','',6,'Status','enum(\'Active\',\'Inactive\')','','NO','Active',20,'',199,'','','yes','no',''),(2408,'','Xformed_Cells','Source','Source__ID','','Source_ID',14,'FK_Source__ID','int(11)','MUL','NO','',20,'',88,'Source.Source_ID','','yes','no',''),(2409,'','cDNA_Library','3PrimeInsert Restriction Site','3PrimeInsert_Restriction_Site__ID','Mandatory,NewLink','Restriction_Site_ID',6,'FK3PrimeInsert_Restriction_Site__ID','int(11)','MUL','YES','',20,'',91,'Restriction_Site.Restriction_Site_ID','','yes','no',''),(2410,'','cDNA_Library','5PrimeInsert Restriction Site','5PrimeInsert_Restriction_Site__ID','Mandatory,NewLink','Restriction_Site_ID',7,'FK5PrimeInsert_Restriction_Site__ID','int(11)','MUL','YES','',20,'',91,'Restriction_Site.Restriction_Site_ID','','yes','no',''),(2411,'','Parameter','Prompt','Prompt','','',10,'Parameter_Prompt','varchar(30)','','NO','',20,'^.{0,30}$',57,'','','yes','yes',''),(2412,'','Plate_Attribute','Plate','Plate__ID','','Plate_ID',1,'FK_Plate__ID','int(11)','MUL','NO','',20,'',200,'Plate.Plate_ID','','yes','no',''),(2413,'','Plate_Attribute','Attribute','Attribute__ID','','Attribute_ID',2,'FK_Attribute__ID','int(11)','MUL','NO','',20,'',200,'Attribute.Attribute_ID','','yes','no',''),(2414,'','Plate_Attribute','Attribute Value','Attribute_Value','','',3,'Attribute_Value','text','','NO','',20,'',200,'','','yes','no',''),(2415,'','Plate_Attribute','Plate Attribute ID','ID','Primary','',4,'Plate_Attribute_ID','int(11)','PRI','NO','',20,'',200,'','','yes','no',''),(2416,'','WorkLog','WorkLog ID','ID','Primary','',1,'WorkLog_ID','int(11)','PRI','NO','',20,'',201,'','','yes','no',''),(2417,'','WorkLog','Employee','Employee__ID','','Employee_ID',2,'FK_Employee__ID','int(11)','','NO','',20,'',201,'Employee.Employee_ID','','yes','no',''),(2418,'','WorkLog','Work Date','Work_Date','','',3,'Work_Date','date','','YES','<TODAY>',20,'',201,'','','yes','no',''),(2419,'','WorkLog','Hours Spent','Hours_Spent','','',4,'Hours_Spent','decimal(6,2)','','YES','',20,'',201,'','','yes','no',''),(2420,'','WorkLog','Issue','Issue__ID','','Issue_ID',5,'FK_Issue__ID','int(11)','','YES','',20,'',201,'Issue.Issue_ID','','yes','no',''),(2421,'','WorkLog','Log Date','Log_Date','','',6,'Log_Date','date','','YES','<TODAY>',20,'',201,'','','yes','no',''),(2422,'','WorkLog','Log Notes','Log_Notes','','',7,'Log_Notes','text','','YES','',20,'',201,'','','yes','no',''),(2423,'','Issue','Comment','Comment','','',21,'Issue_Comment','text','','NO','',20,'',94,'','','yes','no',''),(2424,'','Contact','Canonical Name','Canonical_Name','','',40,'Canonical_Name','varchar(40)','','NO','',20,'^.{0,40}$',24,'','','yes','no',''),(2425,'','WorkPackage','WorkPackage ID','ID','Primary','WP_Name',1,'WorkPackage_ID','int(11)','PRI','NO','',20,'',202,'','','yes','no',''),(2426,'','WorkPackage','Issue','Issue__ID','','Issue_ID',2,'FK_Issue__ID','int(11)','','YES','',20,'',202,'Issue.Issue_ID','','yes','no',''),(2427,'','WorkPackage','File','File','','',3,'WorkPackage_File','text','','YES','',20,'',202,'','','yes','no',''),(2428,'','WorkPackage','WP Name','WP_Name','','',4,'WP_Name','varchar(60)','MUL','YES','',20,'^.{0,60}$',202,'','','yes','no',''),(2429,'','WorkPackage','WP Comments','WP_Comments','','',5,'WP_Comments','text','','YES','',20,'',202,'','','yes','no',''),(2430,'PHASED OUT - moved to WorkPackage_Attribute','WorkPackage','WP Obstacles','WP_Obstacles','Hidden','',6,'WP_Obstacles','text','','YES','',20,'',202,'','','yes','no',''),(2431,'PHASED OUT - moved to WorkPackage_Attribute','WorkPackage','WP Priority Details','WP_Priority_Details','Hidden','',7,'WP_Priority_Details','text','','YES','',20,'',202,'','','yes','no',''),(2432,'','WorkPackage','WP Description','WP_Description','','',8,'WP_Description','text','','YES','',20,'',202,'','','yes','no',''),(2433,'','Issue','Grp','Grp__ID','','Grp_ID',22,'FK_Grp__ID','int(11)','','NO','1',20,'',94,'Grp.Grp_ID','','yes','no',''),(2434,'','Printer_Assignment','Printer Assignment ID','ID','Primary','',1,'Printer_Assignment_ID','int(11)','PRI','NO','',20,'',203,'','','yes','no',''),(2435,'','Printer_Assignment','Printer Group','Printer_Group__ID','','Printer_Group_ID',2,'FK_Printer_Group__ID','int(11)','MUL','NO','',20,'',203,'Printer_Group.Printer_Group_ID','','yes','no',''),(2436,'','Printer_Assignment','Printer','Printer__ID','','Printer_ID',3,'FK_Printer__ID','int(11)','','NO','',20,'',203,'Printer.Printer_ID','','yes','no',''),(2437,'','Printer_Group','Printer Group ID','ID','Primary','Printer_Group_Name',1,'Printer_Group_ID','int(11)','PRI','NO','',20,'',204,'','','yes','no',''),(2438,'','Printer_Group','Name','Name','','',2,'Printer_Group_Name','varchar(40)','','NO','',20,'^.{0,40}$',204,'','','yes','no',''),(2442,'','UseCase','UseCase ID','ID','Primary','concat(UseCase_ID,\' : \',UseCase_Name)',1,'UseCase_ID','int(11)','PRI','NO','',20,'',205,'','','yes','no',''),(2443,'','UseCase','Name','Name','','',2,'UseCase_Name','varchar(80)','UNI','NO','',20,'^.{0,80}$',205,'','','yes','no',''),(2445,'','UseCase','Description','Description','','',4,'UseCase_Description','text','','YES','',20,'',205,'','','yes','no',''),(2446,'','UseCase','Created','Created','','',5,'UseCase_Created','datetime','','YES','0000-00-00 00:00:00',20,'',205,'','','yes','no',''),(2447,'','UseCase','Modified','Modified','','',6,'UseCase_Modified','datetime','','YES','0000-00-00 00:00:00',20,'',205,'','','yes','no',''),(2448,'','UseCase','Parent UseCase','Parent_UseCase__ID','','UseCase_ID',7,'FKParent_UseCase__ID','int(11)','','YES','',20,'',205,'UseCase.UseCase_ID','','yes','no',''),(2449,'','UseCase','Step','Step__ID','','UseCase_Step_ID',8,'FK_UseCase_Step__ID','int(11)','','YES','',20,'',205,'UseCase_Step.UseCase_Step_ID','','yes','no',''),(2450,'','UseCase_Step','UseCase Step ID','ID','Primary','concat(UseCase_Step_ID,\' : \',UseCase_Step_Title)',1,'UseCase_Step_ID','int(11)','PRI','NO','',20,'',206,'','','yes','no',''),(2451,'','UseCase_Step','Title','Title','','',2,'UseCase_Step_Title','text','','YES','',20,'',206,'','','yes','no',''),(2452,'','UseCase_Step','Description','Description','','',3,'UseCase_Step_Description','text','','YES','',20,'',206,'','','yes','no',''),(2453,'','UseCase_Step','Comments','Comments','','',4,'UseCase_Step_Comments','text','','YES','',20,'',206,'','','yes','no',''),(2454,'','UseCase_Step','UseCase','UseCase__ID','','UseCase_ID',5,'FK_UseCase__ID','int(11)','MUL','YES','',20,'',206,'UseCase.UseCase_ID','','yes','no',''),(2455,'','UseCase_Step','Parent UseCase Step','Parent_UseCase_Step__ID','','UseCase_Step_ID',6,'FKParent_UseCase_Step__ID','int(11)','','YES','',20,'',206,'UseCase_Step.UseCase_Step_ID','','yes','no',''),(2456,'','UseCase_Step','Branch','Branch','','',7,'UseCase_Step_Branch','enum(\'0\',\'1\')','','YES','',20,'',206,'','','yes','no',''),(2457,'','Clone_Source','Clone Source ID','ID','Primary','',1,'Clone_Source_ID','int(11)','PRI','NO','',20,'',106,'','','yes','no',''),(2458,'','Clone_Source','Source Description','Source_Description','','',2,'Source_Description','varchar(40)','','YES','',20,'^.{0,40}$',106,'','','yes','no',''),(2459,'','Clone_Source','Clone Sample','Clone_Sample__ID','','Clone_Sample_ID',3,'FK_Clone_Sample__ID','int(11)','MUL','NO','',20,'',106,'Clone_Sample.Clone_Sample_ID','','yes','no',''),(2460,'','Clone_Source','Plate','Plate__ID','','Plate_ID',4,'FK_Plate__ID','int(11)','MUL','YES','',20,'',106,'Plate.Plate_ID','','yes','no',''),(2461,'','Clone_Source','Clone Quadrant','Clone_Quadrant','','',5,'clone_quadrant','enum(\'\',\'a\',\'b\',\'c\',\'d\')','','YES','',20,'',106,'','','yes','no',''),(2462,'','Clone_Source','Clone Well','Clone_Well','','',6,'Clone_Well','char(3)','','YES','',20,'',106,'','','yes','no',''),(2463,'','Clone_Source','Well 384','Well_384','','',7,'Well_384','char(3)','','YES','',20,'',106,'','','yes','no',''),(2464,'','Clone_Source','Source Organization','Source_Organization__ID','','Organization_ID',8,'FKSource_Organization__ID','int(11)','MUL','YES','',20,'',106,'Organization.Organization_ID','','yes','no',''),(2465,'','Clone_Source','Source Name','Source_Name','','',9,'Source_Name','varchar(40)','MUL','YES','',20,'^.{0,40}$',106,'','','yes','no',''),(2466,'','Clone_Source','Source Comments','Source_Comments','','',10,'Source_Comments','text','','YES','',20,'',106,'','','yes','no',''),(2467,'','Clone_Source','Source Library ID','Source_Library_ID','','',11,'Source_Library_ID','varchar(40)','','YES','',20,'^.{0,40}$',106,'','','yes','no',''),(2468,'','Clone_Source','Source Collection','Source_Collection','','',12,'Source_Collection','varchar(40)','MUL','YES','',20,'^.{0,40}$',106,'','','yes','no',''),(2469,'','Clone_Source','Source Library Name','Source_Library_Name','','',13,'Source_Library_Name','varchar(40)','MUL','YES','',20,'^.{0,40}$',106,'','','yes','no',''),(2470,'','Clone_Source','Source Row','Source_Row','','',14,'Source_Row','varchar(4)','','NO','',20,'^.{0,4}$',106,'','','yes','no',''),(2471,'','Clone_Source','Source Col','Source_Col','','',15,'Source_Col','varchar(4)','','NO','',20,'^.{0,4}$',106,'','','yes','no',''),(2472,'','Clone_Source','Source 5Prime Site','Source_5Prime_Site','','',16,'Source_5Prime_Site','text','','YES','',20,'',106,'','','yes','no',''),(2473,'','Clone_Source','Source Plate Number','Source_Plate','','',17,'Source_Plate','int(11)','MUL','YES','',20,'',106,'','','yes','no',''),(2474,'','Clone_Source','Source 3Prime Site','Source_3Prime_Site','','',18,'Source_3Prime_Site','text','','YES','',20,'',106,'','','yes','no',''),(2476,'','Clone_Source','Source Vector','Source_Vector','','',20,'Source_Vector','varchar(40)','','YES','',20,'^.{0,40}$',106,'','','yes','no',''),(2477,'','Clone_Source','Source Score','Source_Score','','',21,'Source_Score','int(11)','','YES','',20,'',106,'','','yes','no',''),(2478,'','Clone_Source','3prime tag','3prime_tag','Hidden','',22,'3prime_tag','varchar(40)','','YES','',20,'^.{0,40}$',106,'','','yes','no',''),(2479,'','Clone_Source','5prime tag','5prime_tag','Hidden','',23,'5prime_tag','varchar(40)','','YES','',20,'^.{0,40}$',106,'','','yes','no',''),(2480,'','Clone_Source','Source Clone Name','Source_Clone_Name','Hidden','',24,'Source_Clone_Name','varchar(40)','MUL','YES','',20,'^.{0,40}$',106,'','','yes','no',''),(2481,'','Clone_Source','Source Clone Name Type','Source_Clone_Name_Type','Hidden','',25,'Source_Clone_Name_Type','varchar(40)','','YES','',20,'^.{0,40}$',106,'','','yes','no',''),(2482,'','WorkPackage_Attribute','WorkPackage Attribute ID','ID','Primary','',1,'WorkPackage_Attribute_ID','int(11)','PRI','NO','',20,'',207,'','','yes','no',''),(2483,'','WorkPackage_Attribute','Attribute','Attribute__ID','','Attribute_ID',2,'FK_Attribute__ID','int(11)','','NO','',20,'',207,'Attribute.Attribute_ID','','yes','no',''),(2484,'','WorkPackage_Attribute','WorkPackage','WorkPackage__ID','','WorkPackage_ID',3,'FK_WorkPackage__ID','int(11)','','NO','',20,'',207,'WorkPackage.WorkPackage_ID','','yes','no',''),(2485,'','WorkPackage_Attribute','Attribute Value','Attribute_Value','','',4,'Attribute_Value','text','','YES','',20,'',207,'','','yes','no',''),(2486,'','Primer_Customization','Position','Position','','',6,'Position','enum(\'Outer\',\'Nested\')','','YES','',20,'',97,'','','yes','no',''),(2487,'','Box','Expiry','Expiry','','',10,'Box_Expiry','date','','YES','',20,'',3,'','','yes','no',''),(2488,'','Change_History','Change History ID','ID','Primary','',1,'Change_History_ID','int(11)','PRI','NO','',20,'',208,'','','yes','no',''),(2489,'','Change_History','DBField','DBField__ID','','DBField_ID',2,'FK_DBField__ID','int(11)','MUL','NO','',20,'',208,'DBField.DBField_ID','','yes','no',''),(2490,'','Change_History','Old Value','Old_Value','','',3,'Old_Value','varchar(255)','','YES','',20,'',208,'','','yes','no',''),(2491,'','Change_History','New Value','New_Value','','',4,'New_Value','varchar(255)','','YES','',20,'',208,'','','yes','no',''),(2492,'','Change_History','Employee','Employee__ID','','Employee_ID',5,'FK_Employee__ID','int(11)','MUL','NO','',20,'',208,'Employee.Employee_ID','','yes','no',''),(2493,'','Change_History','Modified Date','Modified_Date','','',6,'Modified_Date','datetime','','NO','0000-00-00 00:00:00',20,'',208,'','','yes','no',''),(2494,'','Change_History','Record ID','Record_ID','','',7,'Record_ID','varchar(40)','','NO','',20,'^.{0,40}$',208,'','','yes','no',''),(2495,'','Change_History','Comment','Comment','','',8,'Comment','text','','YES','',20,'',208,'','','yes','no',''),(2496,'','Child_Ordered_Procedure','Child Ordered Procedure ID','ID','Primary','',1,'Child_Ordered_Procedure_ID','int(11)','PRI','NO','',20,'',209,'','','yes','no',''),(2497,'','Child_Ordered_Procedure','Parent Ordered Procedure','Parent_Ordered_Procedure__ID','','Ordered_Procedure_ID',2,'FKParent_Ordered_Procedure__ID','int(11)','MUL','NO','',20,'',209,'Ordered_Procedure.Ordered_Procedure_ID','','yes','no',''),(2498,'','Child_Ordered_Procedure',' ID','_ID','','Ordered_Procedure_ID',3,'FKChild_Ordered_Procedure__ID','int(11)','MUL','NO','',20,'',209,'Ordered_Procedure.Ordered_Procedure_ID','','yes','no',''),(2499,'','Clone_Details','Size StdDev','Size_StdDev','','',15,'Size_StdDev','int(11)','','YES','',20,'',103,'','','yes','no',''),(2541,'','Collaboration','Contact','Contact__ID','Mandatory,NewLink','Contact_ID',3,'FK_Contact__ID','int(11)','','NO','',20,'',17,'Contact.Contact_ID','','yes','no',''),(2542,'','DBField','Editable','Editable','','',19,'Editable','enum(\'yes\',\'no\')','','YES','yes',20,'',107,'','','yes','no',''),(2543,'','DBField','Tracked','Tracked','','',20,'Tracked','enum(\'yes\',\'no\')','','YES','no',20,'',107,'','','yes','no',''),(2544,'','Equipment','Location','Location__ID','','Location_ID',16,'FK_Location__ID','int(11)','','NO','',20,'',31,'Location.Location_ID','','yes','no',''),(2545,'','FailureReason','FailureReason ID','ID','Primary','FailureReason_Name',1,'FailureReason_ID','int(11)','PRI','NO','',20,'',212,'','','yes','no',''),(2546,'','FailureReason','Grp','Grp__ID','','Grp_ID',2,'FK_Grp__ID','int(11)','MUL','NO','',20,'',212,'Grp.Grp_ID','','yes','no',''),(2547,'','FailureReason','Name','Name','','',3,'FailureReason_Name','varchar(40)','MUL','YES','',20,'^.{0,40}$',212,'','','yes','no',''),(2548,'','FailureReason','Failure Description','Failure_Description','','',4,'Failure_Description','text','','YES','',20,'',212,'','','yes','no',''),(2549,'','GCOS_Config','GCOS Config ID','ID','Primary','Template_Name',1,'GCOS_Config_ID','int(11)','PRI','NO','',20,'',213,'','','yes','no',''),(2562,'','Genechip_Experiment','Genechip Experiment ID','ID','Primary','',1,'Genechip_Experiment_ID','int(11)','PRI','NO','',20,'',214,'','','yes','no',''),(2563,'','Genechip_Experiment','Plate','Plate__ID','','Plate_ID',2,'FK_Plate__ID','int(11)','','NO','',20,'',214,'Plate.Plate_ID','','yes','no',''),(2564,'','Genechip_Experiment','Chip Type','Chip_Type','','',3,'Chip_Type','enum(\'HG-U133A\',\'HG-U133\')','','YES','',20,'',214,'','','yes','no',''),(2565,'','Genechip_Experiment','Experiment Count','Experiment_Count','','',4,'Experiment_Count','int(11)','','NO','',20,'',214,'','','yes','no',''),(2566,'','Genechip_Experiment','Data Subdirectory','Data_Subdirectory','','',5,'Data_Subdirectory','varchar(80)','','NO','',20,'^.{0,80}$',214,'','','yes','no',''),(2567,'','Genechip_Experiment','Comments','Comments','','',6,'Comments','text','','YES','',20,'',214,'','','yes','no',''),(2568,'','Genechip_Experiment','Equipment','Equipment__ID','','Equipment_ID',7,'FK_Equipment__ID','int(11)','','NO','',20,'',214,'Equipment.Equipment_ID','','yes','no',''),(2569,'','Genechip_Experiment','Employee','Employee__ID','','Employee_ID',8,'FK_Employee__ID','int(11)','','NO','',20,'',214,'Employee.Employee_ID','','yes','no',''),(2570,'','Genechip_Experiment','Experiment DateTime','Experiment_DateTime','','',9,'Experiment_DateTime','date','','YES','<TODAY>',20,'',214,'','','yes','no',''),(2571,'','Genechip_Experiment','Experiment Name','Experiment_Name','','',10,'Experiment_Name','varchar(80)','','NO','',20,'^.{0,80}$',214,'','','yes','no',''),(2572,'','Genechip_Experiment','Genechip Barcode','Genechip_Barcode','','',11,'Genechip_Barcode','varchar(80)','','NO','',20,'^.{0,80}$',214,'','','yes','no',''),(2573,'','GrpProject','GrpProject ID','ID','Primary','',1,'GrpProject_ID','int(11)','PRI','NO','',20,'',215,'','','yes','no',''),(2574,'','GrpProject','Project','Project__ID','','Project_ID',2,'FK_Project__ID','int(11)','MUL','NO','',20,'',215,'Project.Project_ID','','yes','no',''),(2575,'','GrpProject','Grp','Grp__ID','','Grp_ID',3,'FK_Grp__ID','int(11)','MUL','NO','',20,'',215,'Grp.Grp_ID','','yes','no',''),(2576,'','Hybrid_Original_Source','Parent Original Source','Parent_Original_Source__ID','','Original_Source_ID',2,'FKParent_Original_Source__ID','int(11)','MUL','YES','',20,'',177,'Original_Source.Original_Source_ID','','yes','no',''),(2577,'','Issue','Latest ETA','Latest_ETA','','',23,'Latest_ETA','decimal(10,2)','','YES','',20,'',94,'','','yes','no',''),(2578,'Non-GSC name. How is the Library referenced by those who supplied it? ','Library','External Library Name','External_Library_Name','','',6,'External_Library_Name','text','','NO','',20,'',40,'','','yes','no',''),(2579,'Optional URL that refers to this library','Library','URL','URL','','',18,'Library_URL','text','','YES','',20,'',40,'','','yes','no',''),(2580,'Optional - only set if you wish to set the first plate created to something greater than 1','Library','Starting Plate Number','Starting_Plate_Number','Mandatory','',19,'Starting_Plate_Number','smallint(6)','','NO','1',20,'[1-9]',40,'','','yes','no',''),(2581,'Track details for the incoming source','Library','Source In House','Source_In_House','Mandatory','',20,'Source_In_House','enum(\'Yes\',\'No\')','','NO','Yes',20,'',40,'','','no','no',''),(2582,'','Ligation','cfu/ul','cfu','Mandatory','',3,'cfu','int(11)','','YES','',20,'',87,'','','yes','no',''),(2583,'','Location','Location ID','ID','Primary','Location_Name',1,'Location_ID','int(11)','PRI','NO','',20,'',216,'','','yes','no',''),(2584,'','Location','Name','Name','','',2,'Location_Name','char(40)','','YES','',20,'',216,'','','yes','no',''),(2585,'','Ordered_Procedure','Ordered Procedure ID','ID','Primary','',1,'Ordered_Procedure_ID','int(11)','PRI','NO','',20,'',217,'','','yes','no',''),(2587,'','Ordered_Procedure','Object ID','Object_ID','Mandatory','',3,'Object_ID','int(11)','MUL','NO','',20,'',217,'','','yes','no',''),(2588,'','Ordered_Procedure','Procedure Order','Procedure_Order','','',4,'Procedure_Order','tinyint(4)','','NO','',20,'',217,'','','yes','no',''),(2589,'','Ordered_Procedure','Pipeline','Pipeline__ID','','Pipeline_ID',5,'FK_Pipeline__ID','int(11)','','NO','',20,'',217,'Pipeline.Pipeline_ID','','yes','no',''),(2590,'','Organism','Organism ID','ID','Primary','Organism_Name',1,'Organism_ID','int(11)','PRI','NO','',20,'',218,'','','yes','no',''),(2591,'Common name for the organism','Organism','Common Name','Name','Mandatory','',2,'Organism_Name','varchar(255)','UNI','NO','',20,'^.{0,255}$',218,'','','yes','no',''),(2592,'Standard taxonomic (Latin name) for species','Organism','Taxonomic Name','Species','','',3,'Species','varchar(255)','','YES','',20,'^.{0,255}$',218,'','','yes','no',''),(2596,'','Original_Source','Stage','Stage__ID','NewLink,Searchable','Stage_ID',8,'FK_Stage__ID','int(11)','','NO','',20,'',165,'Stage.Stage_ID','','yes','yes',''),(2597,'Select Unspecified when not applicable','Original_Source','Tissue','Tissue__ID','Mandatory,NewLink,Searchable','Tissue_ID',5,'FK_Tissue__ID','int(11)','','NO','',20,'',165,'Tissue.Tissue_ID','','yes','yes',''),(2598,'','Original_Source','Organism','Organism__ID','Obsolete','Organism_ID',4,'FK_Organism__ID','int(11)','','NO','',20,'',165,'Organism.Organism_ID','','yes','yes',''),(2599,'','Pipeline','Description','Description','','',4,'Pipeline_Description','text','','YES','',20,'',187,'','','yes','no',''),(2600,'','Plate_Prep','Equipment','Equipment__ID','','Equipment_ID',5,'FK_Equipment__ID','int(11)','MUL','YES','',20,'',128,'Equipment.Equipment_ID','','yes','yes',''),(2601,'','Plate_Prep','Solution','Solution__ID','','Solution_ID',6,'FK_Solution__ID','int(11)','MUL','YES','',20,'',128,'Solution.Solution_ID','','yes','yes',''),(2602,'','Plate_Prep','Solution Quantity','Solution_Quantity','','',7,'Solution_Quantity','float','','YES','',20,'',128,'','','yes','no',''),(2603,'','Plate_Prep','Transfer Quantity','Transfer_Quantity','','',8,'Transfer_Quantity','float','','YES','',20,'',128,'','','yes','no',''),(2604,'','Plate_Prep','Transfer Quantity Units','Transfer_Quantity_Units','','',9,'Transfer_Quantity_Units','enum(\'pl\',\'nl\',\'ul\',\'ml\',\'l\',\'g\',\'mg\',\'ug\',\'ng\',\'pg\')','','YES','',20,'',128,'','','yes','no',''),(2605,'','Plate_Set','Parent Plate Set','Parent_Plate_Set__Number','','Plate_Set_Number',4,'FKParent_Plate_Set__Number','int(11)','MUL','YES','',20,'',61,'Plate_Set.Plate_Set_Number','','yes','no',''),(2606,'','Plate_Tray','Plate Tray ID','ID','Primary','',1,'Plate_Tray_ID','int(11)','PRI','NO','',20,'',219,'','','yes','no',''),(2607,'','Plate_Tray','Plate','Plate__ID','','Plate_ID',2,'FK_Plate__ID','int(11)','UNI','NO','',20,'',219,'Plate.Plate_ID','','yes','no',''),(2608,'','Plate_Tray','Tray','Tray__ID','','Tray_ID',3,'FK_Tray__ID','int(11)','MUL','NO','',20,'',219,'Tray.Tray_ID','','yes','no',''),(2609,'','Plate_Tray','Plate Position','Plate_Position','','',4,'Plate_Position','char(3)','','NO','N/A',20,'',219,'','','yes','no',''),(2610,'','Prep','FailureReason','FailureReason__ID','','FailureReason_ID',16,'FK_FailureReason__ID','int(11)','MUL','YES','',20,'',132,'FailureReason.FailureReason_ID','','yes','no',''),(2611,'','Printer','Type','Type','','',5,'Printer_Type','varchar(40)','','NO','',20,'^.{0,40}$',171,'','','yes','no',''),(2612,'','Printer','Address','Address','','',6,'Printer_Address','varchar(80)','','NO','',20,'^.{0,80}$',171,'','','yes','no',''),(2613,'','Printer','Output','Output','','',7,'Printer_Output','enum(\'text\',\'ZPL\',\'latex\',\'OFF\')','','NO','ZPL',20,'',171,'','','yes','no',''),(2614,'','ProcedureTest_Condition','ProcedureTest Condition ID','ID','Primary','',1,'ProcedureTest_Condition_ID','int(11)','PRI','NO','',20,'',220,'','','yes','no',''),(2615,'','ProcedureTest_Condition','Ordered Procedure','Ordered_Procedure__ID','','Ordered_Procedure_ID',2,'FK_Ordered_Procedure__ID','int(11)','MUL','NO','',20,'',220,'Ordered_Procedure.Ordered_Procedure_ID','','yes','no',''),(2616,'','ProcedureTest_Condition','Test Condition','Test_Condition__ID','','Test_Condition_ID',3,'FK_Test_Condition__ID','int(11)','MUL','NO','',20,'',220,'Test_Condition.Test_Condition_ID','','yes','no',''),(2617,'','ProcedureTest_Condition','Test Condition Number','Test_Condition_Number','','',4,'Test_Condition_Number','tinyint(11)','','NO','',20,'',220,'','','yes','no',''),(2618,'','ReArray_Attribute','ReArray Attribute ID','ID','Primary','',1,'ReArray_Attribute_ID','int(11)','PRI','NO','',20,'',221,'','','yes','no',''),(2619,'','ReArray_Attribute','Attribute','Attribute__ID','','Attribute_ID',2,'FK_Attribute__ID','int(11)','MUL','NO','',20,'',221,'Attribute.Attribute_ID','','yes','no',''),(2620,'','ReArray_Attribute','ReArray','ReArray__ID','','ReArray_ID',3,'FK_ReArray__ID','int(11)','MUL','NO','',20,'',221,'ReArray.ReArray_ID','','yes','no',''),(2621,'','ReArray_Attribute','Attribute Value','Attribute_Value','','',4,'Attribute_Value','text','','YES','',20,'',221,'','','yes','no',''),(2622,'','ReArray_Request','Status','Status__ID','','Status_ID',11,'FK_Status__ID','int(11)','MUL','NO','',20,'',140,'Status.Status_ID','','yes','no',''),(2623,'','ReArray_Request','ReArray Purpose','ReArray_Purpose','','',12,'ReArray_Purpose','enum(\'Not applicable\',\'96-well oligo prep\',\'96-well EST prep\',\'384-well oligo prep\',\'384-well EST prep\',\'384-well hardstop prep\')','MUL','YES','Not applicable',20,'',140,'','','yes','no',''),(2628,'plate/tube from which this material came (only applicable when transferring from a previous sample collection)','Source','Plate','Plate__ID','','Plate_ID',19,'FKSource_Plate__ID','int(11)','','YES','',20,'',194,'Plate.Plate_ID','','yes','yes',''),(2629,'','Source_Pool','Source Pool ID','ID','Primary','',1,'Source_Pool_ID','int(11)','PRI','NO','',20,'',222,'','','yes','no',''),(2630,'','Source_Pool','Parent Source','Parent_Source__ID','','Source_ID',2,'FKParent_Source__ID','int(11)','','YES','',20,'',222,'Source.Source_ID','','yes','no',''),(2631,'','Source_Pool','Child Source','Child_Source__ID','','Source_ID',3,'FKChild_Source__ID','int(11)','','YES','',20,'',222,'Source.Source_ID','','yes','no',''),(2634,'','Standard_Solution','Label Type','Label_Type','','',8,'Label_Type','enum(\'Laser\',\'ZPL\')','','YES','ZPL',20,'',58,'','','yes','yes',''),(2635,'','Standard_Solution','Barcode Label','Barcode_Label__ID','','Barcode_Label_ID',9,'FK_Barcode_Label__ID','int(11)','','NO','',20,'',58,'Barcode_Label.Barcode_Label_ID','','yes','yes',''),(2636,'','Status','Status ID','ID','Primary','Status_Name',1,'Status_ID','int(11)','PRI','NO','',20,'',223,'','','yes','no',''),(2637,'','Status','Type','Type','','',2,'Status_Type','enum(\'ReArray_Request\',\'Maintenance\',\'GelAnalysis\')','','YES','',20,'',223,'','','yes','no',''),(2638,'','Status','Name','Name','','',3,'Status_Name','char(40)','MUL','YES','',20,'',223,'','','yes','no',''),(2639,'','Submission_Info','Submission Info ID','ID','Primary,Obsolete','',1,'Submission_Info_ID','int(11)','PRI','NO','',20,'',224,'','','yes','no',''),(2640,'','Submission_Info','Submission','Submission__ID','Obsolete','Submission_ID',2,'FK_Submission__ID','int(11)','MUL','NO','',20,'',224,'Submission.Submission_ID','','yes','no',''),(2641,'','Submission_Info','Submission Comments','Submission_Comments','Obsolete','',3,'Submission_Comments','text','','YES','',20,'',224,'','','yes','no',''),(2645,'','Submission_Volume','Approved Date','Approved_Date','','',9,'Approved_Date','date','','YES','',20,'',197,'','','yes','no',''),(2646,'','Test_Condition','Test Condition ID','ID','Primary','',1,'Test_Condition_ID','int(11)','PRI','NO','',20,'',225,'','','yes','no',''),(2647,'','Test_Condition','Condition Name','Condition_Name','','',2,'Condition_Name','varchar(40)','','YES','',20,'^.{0,40}$',225,'','','yes','no',''),(2648,'','Test_Condition','Condition Tables','Condition_Tables','','',3,'Condition_Tables','text','','YES','',20,'',225,'','','yes','no',''),(2649,'','Test_Condition','Condition Field','Condition_Field','','',4,'Condition_Field','text','','YES','',20,'',225,'','','yes','no',''),(2650,'','Test_Condition','Condition String','Condition_String','','',5,'Condition_String','text','','YES','',20,'',225,'','','yes','no',''),(2651,'','Test_Condition','Condition Type','Condition_Type','','',6,'Condition_Type','enum(\'Ready\',\'In Process\',\'Completed\',\'Transferred within Protocol\',\'Ready For Next Protocol\',\'Custom\')','','YES','Custom',20,'',225,'','','yes','no',''),(2652,'','Test_Condition','Procedure Link','Procedure_Link','','',7,'Procedure_Link','varchar(80)','','YES','',20,'^.{0,80}$',225,'','','yes','no',''),(2653,'','Test_Condition','Condition Description','Condition_Description','','',8,'Condition_Description','text','','YES','',20,'',225,'','','yes','no',''),(2654,'','Test_Condition','Condition Key','Condition_Key','','',9,'Condition_Key','varchar(40)','','YES','',20,'^.{0,40}$',225,'','','yes','no',''),(2655,'','Test_Condition','Extra Clause','Extra_Clause','','',10,'Extra_Clause','text','','YES','',20,'',225,'','','yes','no',''),(2663,'','Tray','Tray ID','ID','Primary','concat(\'tra\',Tray_ID, \' \', Tray_Label)',1,'Tray_ID','int(11)','PRI','NO','',20,'',226,'','','yes','no',''),(2664,'','UseCase','Employee','Employee__ID','','Employee_ID',3,'FK_Employee__ID','int(11)','','YES','',20,'',205,'Employee.Employee_ID','','yes','no',''),(2665,'','WorkLog','Revised ETA','Revised_ETA','','',8,'Revised_ETA','decimal(10,0)','','YES','',20,'',201,'','','yes','no',''),(2666,'','Tissue','Tissue ID','ID','Primary','CASE WHEN LENGTH(Tissue_Subtype)>1 THEN concat(Tissue_Name,\': \',Tissue_Subtype) ELSE Tissue_Name END',1,'Tissue_ID','int(11)','PRI','NO','',20,'',227,'','','yes','no',''),(2667,'','Tissue','Name','Name','','',2,'Tissue_Name','varchar(255)','MUL','NO','',20,'^.{0,255}$',227,'','','no','no',''),(2668,'','Tissue','Subtype','Subtype','','',3,'Tissue_Subtype','varchar(255)','','NO','',20,'^.{0,255}$',227,'','','no','no',''),(2673,'','Stage','Stage ID','ID','Primary','Stage_Name',1,'Stage_ID','int(11)','PRI','NO','',20,'',228,'','','yes','no',''),(2674,'','Stage','Name','Name','','',2,'Stage_Name','varchar(255)','','NO','',20,'^.{0,255}$',228,'','','no','no',''),(2676,'','Submission_Table_Link','Submission Table Link ID','ID','Primary','',1,'Submission_Table_Link_ID','int(11)','PRI','NO','',20,'',229,'','','yes','no',''),(2677,'','Submission_Table_Link','Submission','Submission__ID','','',2,'FK_Submission__ID','int(11)','','NO','',20,'',229,'Submission.Submission_ID','','yes','no',''),(2678,'','Submission_Table_Link','Table Name','Table_Name','','',3,'Table_Name','char(40)','','NO','',20,'',229,'','','yes','no',''),(2679,'','Submission_Table_Link','Key Value','Key_Value','','',4,'Key_Value','char(40)','','YES','',20,'',229,'','','yes','no',''),(2681,'','Original_Source','Subtissue','Subtissue_temp','Hidden','',36,'Subtissue_temp','varchar(40)','','YES','',20,'^.{0,40}$',165,'','','yes','yes',''),(2682,'','Original_Source','Tissue temp','Tissue_temp','Hidden','',37,'Tissue_temp','varchar(40)','','NO','',20,'^.{0,40}$',165,'','','yes','yes',''),(2683,'','Original_Source','Organism temp','Organism_temp','Hidden','',38,'Organism_temp','varchar(40)','','YES','',20,'^.{0,40}$',165,'','','yes','yes',''),(2684,'','Original_Source','Stage','Stage_temp','Hidden','',39,'Stage_temp','varchar(40)','','YES','',20,'^.{0,40}$',165,'','','yes','yes',''),(2685,'','Original_Source','Note temp','Note_temp','Hidden','',40,'Note_temp','varchar(40)','','NO','',20,'^.{0,40}$',165,'','','yes','yes',''),(2686,'','Original_Source','Thelier Stage','Thelier_temp','Hidden','',41,'Thelier_temp','varchar(40)','','YES','',20,'^.{0,40}$',165,'','','yes','yes',''),(2687,'','SAGE_Library','Clones under500Insert Percent','Clones_under500Insert_Percent','Mandatory','',4,'Clones_under500Insert_Percent','int(11)','','YES','',20,'',90,'','','yes','no',''),(2688,'','SAGE_Library','Clones over500Insert Percent','Clones_over500Insert_Percent','Mandatory','',5,'Clones_over500Insert_Percent','int(11)','','YES','',20,'',90,'','','yes','no',''),(2689,'Number of Tags requested by the colaborator for this library','SAGE_Library','Tags Requested','Tags_Requested','Mandatory','',6,'Tags_Requested','int(11)','','YES','',20,'',90,'','','yes','no',''),(2690,'','SAGE_Library','Clones with no Insert Percent','Clones_with_no_Insert_Percent','Hidden','',12,'Clones_with_no_Insert_Percent','int(11)','','YES','',20,'',90,'','','yes','no',''),(2691,'Number of 384 well glycerol plates to pick from the agar plates','Ligation','384 Well Plates To Pick','384_Well_Plates_To_Pick','Hidden','',9,'384_Well_Plates_To_Pick','int(11)','','YES','',20,'',87,'','','yes','no',''),(2692,'Number of 384 well glycerol plates to pick from the agar plates','Xformed_Cells','384 Well Plates To Pick','384_Well_Plates_To_Pick','Hidden','',13,'384_Well_Plates_To_Pick','int(11)','','YES','',20,'',88,'','','yes','no',''),(2693,'','Submission_Info','Submitting Group','Grp__ID','Obsolete','',4,'FK_Grp__ID','int(11)','','YES','',20,'',224,'Grp.Grp_ID','','yes','no',''),(2694,'','Prep_Attribute_Option','Prep Attribute Option ID','ID','Primary','',1,'Prep_Attribute_Option_ID','int(11)','PRI','NO','',20,'',230,'','','yes','no',''),(2695,'','Prep_Attribute_Option','Protocol Step','Protocol_Step__ID','','',2,'FK_Protocol_Step__ID','int(11)','MUL','NO','',20,'',230,'Protocol_Step.Protocol_Step_ID','','yes','no',''),(2696,'','Prep_Attribute_Option','Option Description','Option_Description','','',3,'Option_Description','text','','YES','',20,'',230,'','','yes','no',''),(2697,'','Prep_Attribute_Option','Attribute','Attribute__ID','','',4,'FK_Attribute__ID','int(11)','MUL','NO','',20,'',230,'Attribute.Attribute_ID','','yes','no',''),(2698,'','Prep_Attribute','Prep','Prep__ID','','',1,'FK_Prep__ID','int(11)','MUL','NO','',20,'',231,'Prep.Prep_ID','','yes','no',''),(2699,'','Prep_Attribute','Attribute','Attribute__ID','','',2,'FK_Attribute__ID','int(11)','MUL','NO','',20,'',231,'Attribute.Attribute_ID','','yes','no',''),(2700,'','Prep_Attribute','Attribute Value','Attribute_Value','','',3,'Attribute_Value','text','','NO','',20,'',231,'','','yes','no',''),(2701,'','Prep_Attribute','Prep Attribute ID','ID','Primary','',4,'Prep_Attribute_ID','int(11)','PRI','NO','',20,'',231,'','','yes','no',''),(2702,'','EST_Library','EST Library ID','ID','Primary','',1,'EST_Library_ID','int(11)','PRI','NO','',20,'',232,'','','yes','no',''),(2703,'','EST_Library','Sequencing Library','Sequencing_Library__ID','','',2,'FK_Sequencing_Library__ID','int(11)','MUL','NO','',20,'',232,'Sequencing_Library.Sequencing_Library_ID','','yes','no',''),(2704,'','EST_Library','5Prime Insert Site Enzyme','5Prime_Insert_Site_Enzyme','','',3,'5Prime_Insert_Site_Enzyme','varchar(40)','','NO','',20,'^.{0,40}$',232,'','','yes','no',''),(2705,'','EST_Library','3Prime Insert Site Enzyme','3Prime_Insert_Site_Enzyme','','',4,'3Prime_Insert_Site_Enzyme','varchar(40)','','NO','',20,'^.{0,40}$',232,'','','yes','no',''),(2706,'','EST_Library','Blue White Selection','Blue_White_Selection','Mandatory','',5,'Blue_White_Selection','enum(\'Yes\',\'No\')','','NO','No',20,'',232,'','','yes','no',''),(2707,'','EST_Library','Enriched For Full Length','Enriched_For_Full_Length','','',6,'Enriched_For_Full_Length','enum(\'Yes\',\'No\')','','NO','Yes',20,'',232,'','','yes','no',''),(2708,'','EST_Library','Construction Correction','Construction_Correction','','',7,'Construction_Correction','enum(\'\',\'Normalized\',\'Subtracted\')','','NO','',20,'',232,'','','yes','no',''),(2709,'','EST_Library','3PrimeInsert Restriction Site','3PrimeInsert_Restriction_Site__ID','NewLink','',8,'FK3PrimeInsert_Restriction_Site__ID','int(11)','MUL','YES','',20,'',232,'Restriction_Site.Restriction_Site_ID','','yes','no',''),(2710,'','EST_Library','5PrimeInsert Restriction Site','5PrimeInsert_Restriction_Site__ID','NewLink','',9,'FK5PrimeInsert_Restriction_Site__ID','int(11)','MUL','YES','',20,'',232,'Restriction_Site.Restriction_Site_ID','','yes','no',''),(2711,'','Transposon_Library','Transposon Library ID','ID','Primary','',1,'Transposon_Library_ID','int(11)','PRI','NO','',20,'',233,'','','yes','no',''),(2712,'','Transposon_Library','Sequencing Library','Sequencing_Library__ID','','',2,'FK_Sequencing_Library__ID','int(11)','MUL','NO','',20,'',233,'Sequencing_Library.Sequencing_Library_ID','','yes','no',''),(2713,'','Transposon_Library','Transposon','Transposon__ID','Mandatory','',3,'FK_Transposon__ID','int(11)','MUL','NO','',20,'',233,'Transposon.Transposon_ID','','yes','no',''),(2714,'','Transposon_Library','Pool','Pool__ID','','',4,'FK_Pool__ID','int(11)','MUL','NO','',20,'',233,'Pool.Pool_ID','','yes','no',''),(2715,'','Work_Request','Work Request ID','ID','Primary','',1,'Work_Request_ID','int(11)','PRI','NO','',20,'',234,'','','yes','no',''),(2716,'','Work_Request','Plate Size','Plate_Size','Obsolete','',2,'Plate_Size','enum(\'96-well\',\'384-well\')','','NO','96-well',20,'',234,'','','yes','no',''),(2717,'','Work_Request','Plates To Seq','Plates_To_Seq','Obsolete','',3,'Plates_To_Seq','int(11)','','YES','',20,'',234,'','','yes','no',''),(2718,'','Work_Request','Plates To Pick','Plates_To_Pick','Obsolete','',4,'Plates_To_Pick','int(11)','','YES','',20,'',234,'','','yes','no',''),(2719,'','WorkLog','Grp','Grp__ID','','',9,'FK_Grp__ID','int(11)','','YES','',20,'',201,'Grp.Grp_ID','','yes','no',''),(2720,'','Genomic_Library','Type','Type','','',8,'Genomic_Library_Type','enum(\'Shotgun\',\'BAC\',\'Fosmid\')','','YES','',20,'',92,'','','yes','no',''),(2721,'','Rack','Movable','Movable','','',6,'Movable','enum(\'Y\',\'N\')','','NO','Y',20,'',69,'','','yes','no',''),(2722,'','Trigger','Description','Description','','',7,'Trigger_Description','text','','YES','',20,'',199,'','','yes','no',''),(2723,'Starting Material Tracked','Original_Source','Starting Material supplied to the Lab?','Sample_Available','Mandatory','',1,'Sample_Available','enum(\'Yes\',\'No\',\'Later\')','','YES','',5,'',165,'','','yes','yes',''),(2724,'','Antibiotic','Antibiotic ID','ID','Primary','Antibiotic_Name',1,'Antibiotic_ID','int(10) unsigned','PRI','NO','',20,'',235,'','','yes','no',''),(2725,'','Antibiotic','Name','Name','','',2,'Antibiotic_Name','varchar(40)','MUL','YES','',20,'^.{0,40}$',235,'','','yes','no',''),(2726,'','Band','Type','Type','','',7,'Band_Type','enum(\'Insert\',\'Vector\')','','YES','',20,'',173,'','','yes','no',''),(2727,'','Contaminant','Run','Run__ID','','',3,'FK_Run__ID','int(11)','MUL','YES','',20,'',25,'Run.Run_ID','','yes','no',''),(2728,'','Cross_Match','Run','Run__ID','','',1,'FK_Run__ID','int(11)','MUL','YES','',20,'',27,'Run.Run_ID','','yes','no',''),(2729,'','DB_Form','Class','Class','','',10,'Class','varchar(40)','','YES','',20,'^.{0,40}$',108,'','','yes','no',''),(2730,'','Event','Event ID','ID','Primary','',1,'Event_ID','int(10) unsigned','PRI','NO','',20,'',236,'','','yes','no',''),(2731,'','Event','Employee','Employee__ID','','',2,'FK_Employee__ID','int(11)','MUL','NO','',20,'',236,'Employee.Employee_ID','','yes','no',''),(2732,'','Event','Type','Type','','',3,'Event_Type','enum(\'Inventory\')','','YES','',20,'',236,'','','yes','no',''),(2733,'','Event','Start','Start','','',4,'Event_Start','datetime','','NO','0000-00-00 00:00:00',20,'',236,'','','yes','no',''),(2734,'','Event','Finish','Finish','','',5,'Event_Finish','datetime','','NO','0000-00-00 00:00:00',20,'',236,'','','yes','no',''),(2735,'','Event','Status','Status__ID','','',6,'FKEvent_Status__ID','int(11)','MUL','NO','',20,'',236,'Status.Status_ID','','yes','no',''),(2736,'','Event_Attribute','Event Attribute ID','ID','Primary','',1,'Event_Attribute_ID','int(11)','PRI','NO','',20,'',237,'','','yes','no',''),(2737,'','Event_Attribute','Event','Event__ID','','',2,'FK_Event__ID','int(11)','MUL','NO','',20,'',237,'Event.Event_ID','','yes','no',''),(2738,'','Event_Attribute','Attribute','Attribute__ID','','',3,'FK_Attribute__ID','int(11)','MUL','NO','',20,'',237,'Attribute.Attribute_ID','','yes','no',''),(2739,'','Event_Attribute','Attribute Value','Attribute_Value','','',4,'Attribute_Value','text','','NO','',20,'',237,'','','yes','no',''),(2740,'','Event_Attribute','Employee','Employee__ID','','',5,'FK_Employee__ID','int(11)','','YES','',20,'',237,'Employee.Employee_ID','','yes','no',''),(2741,'','Event_Attribute','Set DateTime','Set_DateTime','','',6,'Set_DateTime','datetime','','NO','0000-00-00 00:00:00',20,'',237,'','','yes','no',''),(2742,'','Fail','Fail ID','ID','Primary','',1,'Fail_ID','int(11)','PRI','NO','',20,'',238,'','','yes','no',''),(2743,'','Fail','Object ID','Object_ID','Mandatory','',2,'Object_ID','int(11)','MUL','NO','',20,'',238,'','','yes','no',''),(2744,'','Fail','Employee','Employee__ID','','',3,'FK_Employee__ID','int(11)','MUL','NO','',20,'',238,'Employee.Employee_ID','','yes','no',''),(2745,'','Fail','FailReason','FailReason__ID','','',4,'FK_FailReason__ID','int(11)','MUL','NO','',20,'',238,'FailReason.FailReason_ID','','yes','no',''),(2746,'','Fail','DateTime','DateTime','','',5,'DateTime','datetime','','NO','0000-00-00 00:00:00',20,'',238,'','','yes','no',''),(2747,'','Fail','Comments','Comments','','',6,'Comments','text','','YES','',20,'',238,'','','yes','no',''),(2748,'','FailReason','FailReason ID','ID','Primary','FailReason_Name',1,'FailReason_ID','int(11)','PRI','NO','',20,'',239,'','','yes','no',''),(2749,'','FailReason','Grp','Grp__ID','','',2,'FK_Grp__ID','int(11)','MUL','NO','',20,'',239,'Grp.Grp_ID','','yes','no',''),(2750,'','FailReason','Name','Name','','',3,'FailReason_Name','varchar(100)','MUL','YES','',100,'^.{0,100}$',239,'','','yes','no',''),(2751,'','FailReason','Description','Description','','',4,'FailReason_Description','text','','YES','',20,'',239,'','','yes','no',''),(2752,'','FailReason','Object Class','Object_Class__ID','Mandatory','',5,'FK_Object_Class__ID','int(11)','MUL','NO','',20,'',239,'Object_Class.Object_Class_ID','','yes','no',''),(2753,'','Field_Map','Field Map ID','ID','Primary','',1,'Field_Map_ID','int(11)','PRI','NO','',20,'',240,'','','yes','no',''),(2754,'','Field_Map','Attribute','Attribute__ID','','',2,'FK_Attribute__ID','int(11)','','YES','',20,'',240,'Attribute.Attribute_ID','','yes','no',''),(2755,'','Field_Map','Source DBField','Source_DBField__ID','','',3,'FKSource_DBField__ID','int(11)','','YES','',20,'',240,'DBField.DBField_ID','','yes','no',''),(2756,'','Field_Map','Target DBField','Target_DBField__ID','','',4,'FKTarget_DBField__ID','int(11)','MUL','NO','',20,'',240,'DBField.DBField_ID','','yes','no',''),(2766,'','GelAnalysis','GelAnalysis ID','ID','Primary','',1,'GelAnalysis_ID','int(11)','PRI','NO','',20,'',242,'','','yes','no',''),(2768,'','GelAnalysis','DateTime','DateTime','','',3,'GelAnalysis_DateTime','datetime','','YES','',20,'',242,'','','yes','no',''),(2769,'','GelAnalysis','Bandleader Version','Bandleader_Version','','',4,'Bandleader_Version','varchar(15)','','YES','',20,'^.{0,15}$',242,'','','yes','no',''),(2770,'','GelRun','GelRun ID','ID','Primary','',1,'GelRun_ID','int(11)','PRI','NO','',20,'',243,'','','yes','no',''),(2771,'','GelRun','Run','Run__ID','','',2,'FK_Run__ID','int(11)','MUL','YES','',20,'',243,'Run.Run_ID','','yes','no',''),(2772,'','GelRun','Employee who poured the gel','Poured_Employee__ID','','',3,'FKPoured_Employee__ID','int(11)','MUL','YES','',20,'',243,'Employee.Employee_ID','','yes','no',''),(2773,'','GelRun','Comb Used','Comb_Equipment__ID','','',4,'FKComb_Equipment__ID','int(11)','MUL','YES','',20,'',243,'Equipment.Equipment_ID','','yes','no',''),(2775,'','GelRun','Agarose Solution ID','Agarose_Solution__ID','','',6,'FKAgarose_Solution__ID','int(11)','','YES','',20,'',243,'Solution.Solution_ID','','yes','no',''),(2776,'','GelRun','Agarose Percentage','Agarose_Percentage','','',7,'Agarose_Percentage','varchar(5)','','YES','',20,'^.{0,5}$',243,'','','yes','no',''),(2777,'','GelRun','File Extension Type','File_Extension_Type','','',8,'File_Extension_Type','enum(\'sizes\',\'none\')','','YES','',20,'',243,'','','yes','no',''),(2778,'','Goal','Goal ID','ID','Primary','Goal_Name',1,'Goal_ID','int(11)','PRI','NO','',20,'',244,'','','yes','no',''),(2779,'','Goal','Name','Name','','',2,'Goal_Name','varchar(255)','','YES','',20,'^.{0,255}$',244,'','','yes','no',''),(2780,'','Goal','Description','Description','','',3,'Goal_Description','text','','YES','',20,'',244,'','','yes','no',''),(2781,'','Goal','Query','Query','','',4,'Goal_Query','text','','YES','',20,'',244,'','','yes','no',''),(2782,'','Goal','Tables','Tables','','',5,'Goal_Tables','varchar(255)','','YES','',20,'^.{0,255}$',244,'','','yes','no',''),(2783,'','Goal','Count','Count','','',6,'Goal_Count','varchar(255)','','YES','',20,'^.{0,255}$',244,'','','yes','no',''),(2784,'','Goal','Goal Condition','Goal_Condition','','',7,'Goal_Condition','varchar(255)','','YES','',20,'^.{0,255}$',244,'','','yes','no',''),(2785,'','Lane','GelRun','GelRun__ID','','',2,'FK_GelRun__ID','int(11)','MUL','YES','',20,'',181,'GelRun.GelRun_ID','','yes','no',''),(2786,'','Lane','Number','Number','','',4,'Lane_Number','int(11)','','YES','',20,'',181,'','','yes','no',''),(2787,'','Lane','Status','Status','','',5,'Lane_Status','enum(\'Passed\',\'Failed\',\'Marker\')','','YES','',20,'',181,'','','yes','no',''),(2788,'','Lane','Bands Count','Bands_Count','','',7,'Bands_Count','int(11)','','YES','',20,'',181,'','','yes','no',''),(2796,'','Library','Requested Completion Date','Requested_Completion_Date','','',21,'Requested_Completion_Date','date','','YES','',20,'',40,'','','yes','no',''),(2797,'Reference to contact responsible for constructing this library/collection','Library','Constructed By','Constructed_Contact__ID','','',22,'FKConstructed_Contact__ID','int(11)','','YES','',20,'',40,'Contact.Contact_ID','','yes','no',''),(2798,'','LibraryApplication','LibraryApplication ID','ID','Primary','',1,'LibraryApplication_ID','int(11)','PRI','NO','',20,'',246,'','','yes','no',''),(2799,'','LibraryApplication','Library','Library__Name','Searchable','',2,'FK_Library__Name','varchar(40)','MUL','NO','',20,'',246,'Library.Library_Name','','yes','no',''),(2800,'','LibraryApplication','Object ID','Object_ID','Mandatory','',3,'Object_ID','varchar(40)','MUL','NO','',20,'^.{0,40}$',246,'','','yes','no',''),(2801,'','LibraryApplication','Object Class','Object_Class__ID','Mandatory','',4,'FK_Object_Class__ID','int(11)','MUL','NO','',20,'',246,'Object_Class.Object_Class_ID','','yes','no',''),(2802,'Only applicable for Primers','LibraryApplication','Direction','Direction','','',5,'Direction','enum(\'3prime\',\'5prime\',\'N/A\',\'Unknown\')','','YES','N/A',20,'',246,'','','yes','no',''),(2803,'','LibraryGoal','LibraryGoal ID','ID','Primary','',1,'LibraryGoal_ID','int(11)','PRI','NO','',20,'',247,'','','yes','no',''),(2804,'','LibraryGoal','Library','Library__Name','Searchable','',2,'FK_Library__Name','varchar(6)','','YES','',20,'',247,'Library.Library_Name','','yes','no',''),(2805,'','LibraryGoal','Goal Type','Goal_Type','Mandatory','',3,'FK_Goal__ID','int(11)','','NO','',20,'',247,'Goal.Goal_ID','','yes','yes',''),(2806,'','LibraryGoal','Goal Target','Goal_Target','Mandatory','',4,'Goal_Target','int(11)','','NO','',20,'d+',247,'','','yes','yes',''),(2807,'','LibraryVector','LibraryVector ID','ID','Primary','',1,'LibraryVector_ID','int(11)','PRI','NO','',20,'',248,'','','yes','no',''),(2808,'','LibraryVector','Library','Library__Name','Mandatory,Searchable','',2,'FK_Library__Name','varchar(40)','MUL','YES','',20,'',248,'Library.Library_Name','','yes','no',''),(2809,'','LibraryVector','Vector','Vector__ID','Mandatory,NewLink','',3,'FK_Vector__ID','int(11)','MUL','NO','',20,'',248,'Vector.Vector_ID','','yes','no',''),(2811,'','Library_Segment','Library Segment ID','ID','Primary','',1,'Library_Segment_ID','int(11)','PRI','NO','',20,'',249,'','','yes','no',''),(2812,'','Library_Segment','Vector','Vector__ID','','',2,'FK_Vector__ID','int(11)','','NO','',20,'',249,'Vector.Vector_ID','','yes','no',''),(2813,'','Library_Segment','Non Recombinants','Non_Recombinants','','',3,'Non_Recombinants','float(5,2)','','YES','',20,'',249,'','','yes','no',''),(2814,'','Library_Segment','Non Insert Clones','Non_Insert_Clones','','',4,'Non_Insert_Clones','float(5,2)','','YES','',20,'',249,'','','yes','no',''),(2815,'','Library_Segment','Recombinant Clones','Recombinant_Clones','','',5,'Recombinant_Clones','float(5,2)','','YES','',20,'',249,'','','yes','no',''),(2816,'','Library_Segment','Average Insert Size','Average_Insert_Size','','',6,'Average_Insert_Size','int(11)','','YES','',20,'',249,'','','yes','no',''),(2817,'','Library_Segment','Antibiotic','Antibiotic__ID','','',7,'FK_Antibiotic__ID','int(11)','','YES','',20,'',249,'Antibiotic.Antibiotic_ID','','yes','no',''),(2818,'','Library_Segment','Genome Coverage','Genome_Coverage','','',8,'Genome_Coverage','float(5,2)','','YES','',20,'',249,'','','yes','no',''),(2819,'','Library_Segment','Restriction Site','Restriction_Site__ID','NewLink','',9,'FK_Restriction_Site__ID','int(11)','','YES','',20,'',249,'Restriction_Site.Restriction_Site_ID','','yes','no',''),(2820,'','Maintenance','Finished','Finished','','',10,'Maintenance_Finished','datetime','','YES','',20,'',44,'','','yes','no',''),(2821,'','Maintenance','Status','Status__ID','Mandatory','',11,'FKMaintenance_Status__ID','int(11)','','YES','',20,'',44,'Status.Status_ID','','yes','no',''),(2822,'','MultiPlate_Run','Master Run','Master_Run__ID','','',2,'FKMaster_Run__ID','int(11)','MUL','YES','',20,'',49,'Run.Run_ID','','yes','no',''),(2823,'','MultiPlate_Run','Run','Run__ID','','',3,'FK_Run__ID','int(11)','MUL','YES','',20,'',49,'Run.Run_ID','','yes','no',''),(2824,'','Object_Class','Object Class ID','ID','Primary','Object_Class',1,'Object_Class_ID','int(11)','PRI','NO','',20,'',250,'','','yes','no',''),(2825,'','Object_Class','Object Class','Object_Class','','',2,'Object_Class','varchar(40)','MUL','NO','',20,'^.{0,40}$',250,'','','yes','no',''),(2826,'Object type is used to group together object classes that have the same applications, ie. Enzymes,Antibiotics and Primers are all solutions and validation treats these in the same way','Object_Class','Object Type','Object_Type','','',3,'Object_Type','varchar(40)','MUL','YES','',20,'^.{0,40}$',250,'','','yes','no',''),(2827,'','Organism','Sub species','Sub_species','','',4,'Sub_species','varchar(255)','','YES','',20,'^.{0,255}$',218,'','','yes','no',''),(2828,'','Organism','Common Name','Common_Name','Hidden','',5,'Common_Name','varchar(255)','MUL','YES','',20,'^.{0,255}$',218,'','','yes','no',''),(2829,'','Plate','QC Status','QC_Status','','',22,'QC_Status','enum(\'N/A\',\'Pending\',\'Failed\',\'Re-Test\',\'Passed\')','','YES','N/A',20,'',59,'','','no','yes',''),(2830,'','Plate_Attribute','Employee','Employee__ID','','',5,'FK_Employee__ID','int(11)','','YES','',20,'',200,'Employee.Employee_ID','','yes','no',''),(2831,'','Plate_Attribute','Set DateTime','Set_DateTime','','',6,'Set_DateTime','datetime','','NO','0000-00-00 00:00:00',20,'',200,'','','yes','no',''),(2832,'','Prep','Attr temp','Attr_temp','','',17,'Attr_temp','text','','YES','',20,'',132,'','','yes','no',''),(2833,'','Prep_Attribute','Employee','Employee__ID','','',5,'FK_Employee__ID','int(11)','','YES','',20,'',231,'Employee.Employee_ID','','yes','no',''),(2834,'','Prep_Attribute','Set DateTime','Set_DateTime','','',6,'Set_DateTime','datetime','','NO','0000-00-00 00:00:00',20,'',231,'','','yes','no',''),(2835,'','Run','Run ID','ID','Primary','Run_Directory',1,'Run_ID','int(11)','PRI','NO','',20,'',251,'','','yes','no',''),(2836,'','Run','Type','Type','Mandatory','',2,'Run_Type','enum(\'SequenceRun\',\'GelRun\',\'SpectRun\',\'BioanalyzerRun\',\'GenechipRun\',\'SolexaRun\')','','NO','SequenceRun',20,'',251,'','','yes','no',''),(2837,'','Run','Plate','Plate__ID','','',3,'FK_Plate__ID','int(11)','MUL','YES','',20,'',251,'Plate.Plate_ID','','yes','no',''),(2838,'','Run','RunBatch','RunBatch__ID','','',4,'FK_RunBatch__ID','int(11)','MUL','YES','',20,'',251,'RunBatch.RunBatch_ID','','yes','no',''),(2839,'','Run','DateTime','DateTime','','',5,'Run_DateTime','datetime','MUL','YES','',20,'',251,'','','yes','yes',''),(2840,'','Run','Comments','Comments','','',6,'Run_Comments','text','','YES','',20,'',251,'','','yes','yes',''),(2841,'','Run','Test Status','Test_Status','','',7,'Run_Test_Status','enum(\'Production\',\'Test\')','','YES','Production',20,'',251,'','','yes','yes',''),(2842,'','Run','Position Rack','Position_Rack__ID','','',8,'FKPosition_Rack__ID','int(11)','MUL','YES','',20,'',251,'Rack.Rack_ID','','yes','no',''),(2843,'(Failed indicates machine failed to complete run or generate files; Aborted indicates user stopped run for any reason)','Run','Status','Status','','',9,'Run_Status','enum(\'Initiated\',\'In Process\',\'Data Acquired\',\'Analyzed\',\'Aborted\',\'Failed\',\'Expired\',\'Not Applicable\',\'Analyzing\')','MUL','YES','Initiated',20,'',251,'','','no','no',''),(2844,'','Run','Directory','Directory','','',10,'Run_Directory','varchar(80)','MUL','YES','',20,'^.{0,80}$',251,'','','yes','no',''),(2845,'','Run','Billable','Billable','','',11,'Billable','enum(\'Yes\',\'No\')','','YES','Yes',20,'',251,'','','yes','yes',''),(2846,'','Run','Validation','Validation','','',12,'Run_Validation','enum(\'Pending\',\'Approved\',\'Rejected\')','MUL','YES','Pending',20,'',251,'','','yes','yes',''),(2847,'','RunBatch','RunBatch ID','ID','Primary','',1,'RunBatch_ID','int(11)','PRI','NO','',20,'',252,'','','yes','no',''),(2848,'','RunBatch','RequestDateTime','RequestDateTime','','',2,'RunBatch_RequestDateTime','datetime','','NO','0000-00-00 00:00:00',20,'',252,'','','yes','no',''),(2849,'','RunBatch','Employee','Employee__ID','Mandatory','',3,'FK_Employee__ID','int(11)','','YES','',20,'',252,'Employee.Employee_ID','','yes','no',''),(2850,'','RunBatch','Equipment','Equipment__ID','Mandatory','',4,'FK_Equipment__ID','int(11)','','YES','',20,'',252,'Equipment.Equipment_ID','','yes','no',''),(2851,'','RunBatch','Comments','Comments','','',5,'RunBatch_Comments','text','','YES','',20,'',252,'','','yes','no',''),(2886,'','Run_Attribute','Run Attribute ID','ID','Primary','',1,'Run_Attribute_ID','int(11)','PRI','NO','',20,'',254,'','','yes','no',''),(2887,'','Run_Attribute','Run','Run__ID','','',2,'FK_Run__ID','int(11)','MUL','NO','',20,'',254,'Run.Run_ID','','yes','no',''),(2888,'','Run_Attribute','Attribute','Attribute__ID','','',3,'FK_Attribute__ID','int(11)','MUL','NO','',20,'',254,'Attribute.Attribute_ID','','yes','no',''),(2889,'','Run_Attribute','Attribute Value','Attribute_Value','','',4,'Attribute_Value','text','','NO','',20,'',254,'','','yes','no',''),(2891,'','SAGE_Library','PCR Cycles','PCR_Cycles','','',14,'PCR_Cycles','int(11)','','YES','',20,'',90,'','','yes','no',''),(2892,'','SAGE_Library','cDNA Amnt Used ng','cDNA_Amnt_Used_ng','','',15,'cDNA_Amnt_Used_ng','float(10,3)','','YES','',20,'',90,'','','yes','no',''),(2893,'','SAGE_Library','DiTag PCR Cycle','DiTag_PCR_Cycle','','',16,'DiTag_PCR_Cycle','int(11)','','YES','',20,'',90,'','','yes','no',''),(2894,'','SAGE_Library','DiTag Template Dilution Factor','DiTag_Template_Dilution_Factor','','',17,'DiTag_Template_Dilution_Factor','int(11)','','YES','',20,'',90,'','','yes','no',''),(2895,'','SAGE_Library','Adapter A','Adapter_A','','',18,'Adapter_A','varchar(20)','','YES','',20,'^.{0,20}$',90,'','','yes','no',''),(2896,'','SAGE_Library','Adapter B','Adapter_B','','',19,'Adapter_B','varchar(20)','','YES','',20,'^.{0,20}$',90,'','','yes','no',''),(2897,'','SequenceAnalysis','SequenceAnalysis ID','ID','Primary','',1,'SequenceAnalysis_ID','int(11)','PRI','NO','',20,'',255,'','','yes','no',''),(2898,'','SequenceAnalysis','SequenceRun','SequenceRun__ID','','',2,'FK_SequenceRun__ID','int(11)','MUL','YES','',20,'',255,'SequenceRun.SequenceRun_ID','','yes','no',''),(2899,'','SequenceAnalysis','DateTime','DateTime','','',3,'SequenceAnalysis_DateTime','datetime','','NO','0000-00-00 00:00:00',20,'',255,'','','yes','no',''),(2900,'','SequenceAnalysis','Phred Version','Phred_Version','','',4,'Phred_Version','varchar(20)','','NO','',20,'^.{0,20}$',255,'','','yes','no',''),(2901,'','SequenceAnalysis','Seq Analysis Reads','Seq_Analysis_Reads','','',5,'Reads','int(11)','','YES','',20,'',255,'','','yes','no',''),(2902,'','SequenceAnalysis','Q20array','Q20array','','',6,'Q20array','blob','','YES','',20,'',255,'','','yes','no',''),(2903,'','SequenceAnalysis','SLarray','SLarray','','',7,'SLarray','blob','','YES','',20,'',255,'','','yes','no',''),(2904,'','SequenceAnalysis','Q20mean','Q20mean','','',8,'Q20mean','int(11)','','YES','',20,'',255,'','','yes','no',''),(2905,'','SequenceAnalysis','Q20median','Q20median','','',9,'Q20median','int(11)','','YES','',20,'',255,'','','yes','no',''),(2906,'','SequenceAnalysis','Q20max','Q20max','','',10,'Q20max','int(11)','','YES','',20,'',255,'','','yes','no',''),(2907,'','SequenceAnalysis','Q20min','Q20min','','',11,'Q20min','int(11)','','YES','',20,'',255,'','','yes','no',''),(2908,'','SequenceAnalysis','SLmean','SLmean','','',12,'SLmean','int(11)','','YES','',20,'',255,'','','yes','no',''),(2909,'','SequenceAnalysis','SLmedian','SLmedian','','',13,'SLmedian','int(11)','','YES','',20,'',255,'','','yes','no',''),(2910,'','SequenceAnalysis','SLmax','SLmax','','',14,'SLmax','int(11)','','YES','',20,'',255,'','','yes','no',''),(2911,'','SequenceAnalysis','SLmin','SLmin','','',15,'SLmin','int(11)','','YES','',20,'',255,'','','yes','no',''),(2912,'','SequenceAnalysis','QVmean','QVmean','','',16,'QVmean','int(11)','','YES','',20,'',255,'','','yes','no',''),(2913,'','SequenceAnalysis','QVtotal','QVtotal','','',17,'QVtotal','int(11)','','YES','',20,'',255,'','','yes','no',''),(2914,'','SequenceAnalysis','Wells','Wells','','',18,'Wells','int(11)','','YES','',20,'',255,'','','yes','no',''),(2915,'','SequenceAnalysis','NGs','NGs','','',19,'NGs','int(11)','','YES','',20,'',255,'','','yes','no',''),(2916,'','SequenceAnalysis','SGs','SGs','','',20,'SGs','int(11)','','YES','',20,'',255,'','','yes','no',''),(2917,'','SequenceAnalysis','EWs','EWs','','',21,'EWs','int(11)','','YES','',20,'',255,'','','yes','no',''),(2918,'','SequenceAnalysis','PWs','PWs','','',22,'PWs','int(11)','','YES','',20,'',255,'','','yes','no',''),(2919,'','SequenceAnalysis','QLmean','QLmean','','',23,'QLmean','int(11)','','YES','',20,'',255,'','','yes','no',''),(2920,'','SequenceAnalysis','QLtotal','QLtotal','','',24,'QLtotal','int(11)','','YES','',20,'',255,'','','yes','no',''),(2921,'','SequenceAnalysis','Q20total','Q20total','','',25,'Q20total','int(11)','','YES','',20,'',255,'','','yes','no',''),(2922,'','SequenceAnalysis','SLtotal','SLtotal','','',26,'SLtotal','int(11)','','YES','',20,'',255,'','','yes','no',''),(2923,'','SequenceAnalysis','AllReads','AllReads','','',27,'AllReads','int(11)','','YES','',20,'',255,'','','yes','no',''),(2924,'','SequenceAnalysis','AllBPs','AllBPs','','',28,'AllBPs','int(11)','','YES','',20,'',255,'','','yes','no',''),(2925,'','SequenceAnalysis','VectorSegmentWarnings','VectorSegmentWarnings','','',29,'VectorSegmentWarnings','int(11)','','YES','',20,'',255,'','','yes','no',''),(2926,'','SequenceAnalysis','ContaminationWarnings','ContaminationWarnings','','',30,'ContaminationWarnings','int(11)','','YES','',20,'',255,'','','yes','no',''),(2927,'','SequenceAnalysis','VectorOnlyWarnings','VectorOnlyWarnings','','',31,'VectorOnlyWarnings','int(11)','','YES','',20,'',255,'','','yes','no',''),(2928,'','SequenceAnalysis','RecurringStringWarnings','RecurringStringWarnings','','',32,'RecurringStringWarnings','int(11)','','YES','',20,'',255,'','','yes','no',''),(2929,'','SequenceAnalysis','PoorQualityWarnings','PoorQualityWarnings','','',33,'PoorQualityWarnings','int(11)','','YES','',20,'',255,'','','yes','no',''),(2930,'','SequenceAnalysis','PeakAreaRatioWarnings','PeakAreaRatioWarnings','','',34,'PeakAreaRatioWarnings','int(11)','','YES','',20,'',255,'','','yes','no',''),(2931,'','SequenceAnalysis','successful reads','successful_reads','','',35,'successful_reads','int(11)','','YES','',20,'',255,'','','yes','no',''),(2932,'','SequenceAnalysis','trimmed successful reads','trimmed_successful_reads','','',36,'trimmed_successful_reads','int(11)','','YES','',20,'',255,'','','yes','no',''),(2933,'','SequenceAnalysis','A SStotal','A_SStotal','','',37,'A_SStotal','int(11)','','YES','',20,'',255,'','','yes','no',''),(2934,'','SequenceAnalysis','T SStotal','T_SStotal','','',38,'T_SStotal','int(11)','','YES','',20,'',255,'','','yes','no',''),(2935,'','SequenceAnalysis','G SStotal','G_SStotal','','',39,'G_SStotal','int(11)','','YES','',20,'',255,'','','yes','no',''),(2936,'','SequenceAnalysis','C SStotal','C_SStotal','','',40,'C_SStotal','int(11)','','YES','',20,'',255,'','','yes','no',''),(2937,'','SequenceRun','SequenceRun ID','ID','Primary','',1,'SequenceRun_ID','int(11)','PRI','NO','',20,'',256,'','','yes','no',''),(2938,'','SequenceRun','Run','Run__ID','','',2,'FK_Run__ID','int(11)','MUL','YES','',20,'',256,'Run.Run_ID','','yes','no',''),(2939,'','SequenceRun','Chemistry Code','Chemistry_Code__Name','','',3,'FK_Chemistry_Code__Name','varchar(5)','MUL','YES','',20,'',256,'Chemistry_Code.Chemistry_Code_Name','','yes','no',''),(2940,'','SequenceRun','Primer Solution','Primer_Solution__ID','','',4,'FKPrimer_Solution__ID','int(11)','MUL','YES','',20,'',256,'Solution.Solution_ID','','yes','no',''),(2941,'','SequenceRun','Matrix Solution','Matrix_Solution__ID','','',5,'FKMatrix_Solution__ID','int(11)','MUL','YES','',20,'',256,'Solution.Solution_ID','','yes','no',''),(2942,'','SequenceRun','Buffer Solution','Buffer_Solution__ID','','',6,'FKBuffer_Solution__ID','int(11)','','YES','',20,'',256,'Solution.Solution_ID','','yes','no',''),(2943,'','SequenceRun','DNA Volume','DNA_Volume','','',7,'DNA_Volume','float','','YES','',20,'',256,'','','yes','no',''),(2944,'','SequenceRun','Total Prep Volume','Total_Prep_Volume','','',8,'Total_Prep_Volume','smallint(6)','','YES','',20,'',256,'','','yes','no',''),(2945,'','SequenceRun','BrewMix Concentration','BrewMix_Concentration','','',9,'BrewMix_Concentration','float','','YES','',20,'',256,'','','yes','no',''),(2946,'','SequenceRun','Reaction Volume','Reaction_Volume','','',10,'Reaction_Volume','tinyint(4)','','YES','',20,'',256,'','','yes','no',''),(2947,'','SequenceRun','Resuspension Volume','Resuspension_Volume','','',11,'Resuspension_Volume','tinyint(4)','','YES','',20,'',256,'','','yes','no',''),(2948,'','SequenceRun','Slices','Slices','','',12,'Slices','varchar(20)','','YES','',20,'^.{0,20}$',256,'','','yes','no',''),(2949,'','SequenceRun','Run Format','Run_Format','','',13,'Run_Format','enum(\'96\',\'384\',\'96x4\',\'16xN\')','','YES','',20,'',256,'','','yes','no',''),(2950,'','SequenceRun','Run Module','Run_Module','','',14,'Run_Module','varchar(128)','','YES','',20,'^.{0,128}$',256,'','','yes','no',''),(2951,'','SequenceRun','Run Time','Run_Time','','',15,'Run_Time','int(11)','','YES','',20,'',256,'','','yes','no',''),(2952,'','SequenceRun','Run Voltage','Run_Voltage','','',16,'Run_Voltage','int(11)','','YES','',20,'',256,'','','yes','no',''),(2953,'','SequenceRun','Run Temperature','Run_Temperature','','',17,'Run_Temperature','int(11)','','YES','',20,'',256,'','','yes','no',''),(2954,'','SequenceRun','Injection Time','Injection_Time','','',18,'Injection_Time','int(11)','','YES','',20,'',256,'','','yes','no',''),(2955,'','SequenceRun','Injection Voltage','Injection_Voltage','','',19,'Injection_Voltage','int(11)','','YES','',20,'',256,'','','yes','no',''),(2956,'','SequenceRun','Mobility Version','Mobility_Version','','',20,'Mobility_Version','enum(\'\',\'1\',\'2\',\'3\')','','YES','',20,'',256,'','','yes','no',''),(2957,'','SequenceRun','PlateSealing','PlateSealing','','',21,'PlateSealing','enum(\'None\',\'Foil\',\'Heat Sealing\',\'Septa\')','','YES','None',20,'',256,'','','yes','no',''),(3006,'','Solution','QC Status','QC_Status','','',16,'QC_Status','enum(\'N/A\',\'Pending\',\'Failed\',\'Re-Test\',\'Passed\')','','YES','N/A',20,'',5,'','','yes','yes',''),(3007,'','Source_Attribute','Source Attribute ID','ID','Primary','',1,'Source_Attribute_ID','int(11)','PRI','NO','',20,'',259,'','','yes','no',''),(3008,'','Source_Attribute','Source','Source__ID','','',2,'FK_Source__ID','int(11)','MUL','NO','',20,'',259,'Source.Source_ID','','yes','no',''),(3009,'','Source_Attribute','Attribute','Attribute__ID','','',3,'FK_Attribute__ID','int(11)','MUL','NO','',20,'',259,'Attribute.Attribute_ID','','yes','no',''),(3010,'','Source_Attribute','Attribute Value','Attribute_Value','','',4,'Attribute_Value','text','','NO','',20,'',259,'','','yes','no',''),(3011,'','Source_Attribute','Employee','Employee__ID','','',5,'FK_Employee__ID','int(11)','','YES','',20,'',259,'Employee.Employee_ID','','yes','no',''),(3012,'','Source_Attribute','Set DateTime','Set_DateTime','','',6,'Set_DateTime','datetime','','NO','0000-00-00 00:00:00',20,'',259,'','','yes','no',''),(3013,'','Trace_Submission','Run','Run__ID','','',2,'FK_Run__ID','int(11)','MUL','YES','',20,'',198,'Run.Run_ID','','yes','no',''),(3014,'','Transposon_Pool','GelRun','GelRun__ID','','',4,'FK_GelRun__ID','int(11)','MUL','YES','',20,'',146,'GelRun.GelRun_ID','','yes','no',''),(3015,'','Vector','Vector Name','Type__ID','Mandatory,NewLink','',13,'FK_Vector_Type__ID','int(11)','','NO','',20,'',81,'Vector_Type.Vector_Type_ID','','yes','no',''),(3016,'','VectorPrimer','Vector','Vector__ID','','',5,'FK_Vector__ID','int(11)','','NO','',20,'',82,'Vector.Vector_ID','','yes','no',''),(3017,'','VectorPrimer','Primer','Primer__ID','','',6,'FK_Primer__ID','int(11)','','NO','',20,'',82,'Primer.Primer_ID','','yes','no',''),(3018,'','Vector_Type','Vector Type ID','ID','Primary','Vector_Type.Vector_Type_Name',1,'Vector_Type_ID','int(11)','PRI','NO','',20,'',260,'','','yes','no',''),(3019,'','Vector_Type','Name','Name','','',2,'Vector_Type_Name','varchar(40)','UNI','NO','',20,'^.{0,40}$',260,'','','yes','no',''),(3020,'','Vector_Type','Vector Sequence File','Vector_Sequence_File','','',3,'Vector_Sequence_File','text','','NO','',20,'',260,'','','yes','no',''),(3021,'','Vector_Type','Vector Sequence','Vector_Sequence','','',4,'Vector_Sequence','longtext','','YES','',20,'^[AaGgTtCcNns]*$',260,'','','yes','no',''),(3022,'','Vector_TypeAntibiotic','Vector TypeAntibiotic ID','ID','Primary','',1,'Vector_TypeAntibiotic_ID','int(10) unsigned','PRI','NO','',20,'',261,'','','yes','no',''),(3023,'','Vector_TypeAntibiotic','Vector Type','Vector_Type__ID','Mandatory','',2,'FK_Vector_Type__ID','int(11)','MUL','NO','',20,'',261,'Vector_Type.Vector_Type_ID','','yes','no',''),(3024,'','Vector_TypeAntibiotic','Antibiotic','Antibiotic__ID','','',3,'FK_Antibiotic__ID','int(11)','MUL','NO','',20,'',261,'Antibiotic.Antibiotic_ID','','yes','no',''),(3025,'','Vector_TypePrimer','Vector TypePrimer ID','ID','Primary','',1,'Vector_TypePrimer_ID','int(10) unsigned','PRI','NO','',20,'',262,'','','yes','no',''),(3026,'','Vector_TypePrimer','Vector Type','Vector_Type__ID','Mandatory','',2,'FK_Vector_Type__ID','int(11)','MUL','NO','',20,'',262,'Vector_Type.Vector_Type_ID','','yes','no',''),(3027,'','Vector_TypePrimer','Primer','Primer__ID','Mandatory','',3,'FK_Primer__ID','int(11)','MUL','NO','',20,'',262,'Primer.Primer_ID','','yes','no',''),(3028,'','Vector_TypePrimer','Direction','Direction','Mandatory','',4,'Direction','enum(\'N/A\',\'3prime\',\'5prime\')','','YES','',20,'',262,'','','yes','no',''),(3029,'','View','View ID','ID','Primary','View_Name',1,'View_ID','int(10) unsigned','PRI','NO','',20,'',263,'','','yes','no',''),(3030,'','View','Name','Name','','',2,'View_Name','varchar(40)','','YES','',20,'^.{0,40}$',263,'','','yes','no',''),(3031,'','View','Description','Description','','',3,'View_Description','text','','YES','',20,'',263,'','','yes','no',''),(3032,'','View','Tables','Tables','','',4,'View_Tables','text','','YES','',20,'',263,'','','yes','no',''),(3033,'','View','Grp','Grp__ID','','',5,'FK_Grp__ID','int(11)','MUL','NO','',20,'',263,'Grp.Grp_ID','','yes','no',''),(3034,'','ViewInput','ViewInput ID','ID','Primary','',1,'ViewInput_ID','int(10) unsigned','PRI','NO','',20,'',264,'','','yes','no',''),(3035,'','ViewInput','View','View__ID','','',2,'FK_View__ID','int(11)','MUL','NO','',20,'',264,'View.View_ID','','yes','no',''),(3036,'','ViewInput','Input Field','Input_Field','','',3,'Input_Field','varchar(80)','','YES','',20,'^.{0,80}$',264,'','','yes','no',''),(3037,'','ViewJoin','ViewJoin ID','ID','Primary','',1,'ViewJoin_ID','int(10) unsigned','PRI','NO','',20,'',265,'','','yes','no',''),(3038,'','ViewJoin','View','View__ID','','',2,'FK_View__ID','int(11)','MUL','NO','',20,'',265,'View.View_ID','','yes','no',''),(3039,'','ViewJoin','Join Condition','Join_Condition','','',3,'Join_Condition','text','','YES','',20,'',265,'','','yes','no',''),(3040,'','ViewJoin','Join Type','Join_Type','','',4,'Join_Type','enum(\'LEFT\',\'INNER\')','','YES','INNER',20,'',265,'','','yes','no',''),(3041,'','ViewOutput','ViewOutput ID','ID','Primary','',1,'ViewOutput_ID','int(10) unsigned','PRI','NO','',20,'',266,'','','yes','no',''),(3042,'','ViewOutput','View','View__ID','','',2,'FK_View__ID','int(11)','MUL','NO','',20,'',266,'View.View_ID','','yes','no',''),(3043,'','ViewOutput','Output Field','Output_Field','','',3,'Output_Field','varchar(80)','','YES','',20,'^.{0,80}$',266,'','','yes','no',''),(3044,'','Work_Request','Goal','Goal__ID','','',5,'FK_Goal__ID','int(11)','','YES','',20,'',234,'Goal.Goal_ID','','yes','yes',''),(3045,'','Work_Request','Goal Target','Goal_Target','','',6,'Goal_Target','int(11)','','YES','',20,'',234,'','','yes','yes',''),(3046,'','Work_Request','Comments','Comments','','',7,'Comments','text','','YES','',20,'',234,'','','yes','no',''),(3047,'','Work_Request','Submission','Submission__ID','Obsolete','',8,'FK_Submission__ID','int(11)','','NO','',20,'',234,'Submission.Submission_ID','','yes','no',''),(3048,'','Work_Request','Type','Type','Mandatory','',9,'Work_Request_Type','enum(\'1/16 End Reads\',\'1/24 End Reads\',\'1/256 End Reads\',\'1/16 Custom Reads\',\'1/24 Custom Reads\',\'1/256 Custom Reads\',\'DNA Preps\',\'Bac End Reads\',\'1/256 Submission QC\',\'1/256 Transposon\',\'1/256 Single Prep End Reads\',\'1/16 Glycerol Rearray Custom Reads\',\'Primer Plates Ready\',\'1/48 End Reads\',\'1/48 Custom Reads\')','','YES','',20,'',234,'','','no','no',''),(3049,'','Work_Request','Num Plates Submitted','Num_Plates_Submitted','','',10,'Num_Plates_Submitted','int(11)','','NO','',20,'',234,'','','yes','no',''),(3050,'','Work_Request','Container Format','Plate_Format__ID','','',11,'FK_Plate_Format__ID','int(11)','','NO','',20,'',234,'Plate_Format.Plate_Format_ID','','yes','no',''),(3051,'','Clone_Sequence','Run','Run__ID','','',1,'FK_Run__ID','int(11)','MUL','YES','',20,'',15,'Run.Run_ID','','yes','no',''),(3052,'','Clone_Sequence','Peak Area Ratio','Peak_Area_Ratio','','',23,'Peak_Area_Ratio','float(6,5)','','NO','0.00000',20,'',15,'','','yes','no',''),(3053,'','Library_Segment','Source','Source__ID','','',10,'FK_Source__ID','int(11)','','NO','',20,'',249,'Source.Source_ID','','yes','no',''),(3054,'','SequenceAnalysis','Vtotal','Vtotal','','',41,'Vtotal','int(11)','','YES','',20,'',255,'','','yes','no',''),(3055,'','Run_Attribute','Employee','Employee__ID','','',5,'FK_Employee__ID','int(11)','','YES','',20,'',254,'Employee.Employee_ID','','yes','no',''),(3056,'','Run_Attribute','Set DateTime','Set_DateTime','','',6,'Set_DateTime','datetime','','NO','0000-00-00 00:00:00',20,'',254,'','','yes','no',''),(3057,'','Original_Source_Attribute','Employee','Employee__ID','','',5,'FK_Employee__ID','int(11)','','YES','',20,'',184,'Employee.Employee_ID','','yes','no',''),(3058,'','Original_Source_Attribute','Set DateTime','Set_DateTime','','',6,'Set_DateTime','datetime','','NO','0000-00-00 00:00:00',20,'',184,'','','yes','no',''),(3059,'','Array','ID','ID','Primary','',1,'Array_ID','int(11)','PRI','NO','',20,'',267,'','','yes','no',''),(3060,'','Array','Microarray','Microarray__ID','','',2,'FK_Microarray__ID','int(11)','MUL','YES','',20,'',267,'Microarray.Microarray_ID','','yes','no',''),(3061,'','Array','Plate','Plate__ID','','',3,'FK_Plate__ID','int(11)','MUL','YES','',20,'',267,'Plate.Plate_ID','','yes','no',''),(3062,'','Band','Mobility','Mobility','','',3,'Band_Mobility','float(6,1)','','YES','',20,'',173,'','','yes','no',''),(3063,'','BioanalyzerAnalysis','ID','ID','Primary','',1,'BioanalyzerAnalysis_ID','int(11)','PRI','NO','',20,'',268,'','','yes','no',''),(3064,'','BioanalyzerAnalysis','Run','Run__ID','','',2,'FK_Run__ID','int(11)','MUL','NO','',20,'',268,'Run.Run_ID','','yes','no',''),(3065,'','BioanalyzerAnalysis','File Name','File_Name','','',3,'File_Name','text','','YES','',20,'',268,'','','yes','no',''),(3066,'','BioanalyzerRead','ID','ID','Primary','',1,'BioanalyzerRead_ID','int(11)','PRI','NO','',20,'',269,'','','yes','no',''),(3067,'','BioanalyzerRead','Sample','Sample__ID','','',2,'FK_Sample__ID','int(11)','MUL','NO','',20,'',269,'Sample.Sample_ID','','yes','no',''),(3068,'','BioanalyzerRead','Run','Run__ID','','',3,'FK_Run__ID','int(11)','MUL','NO','',20,'',269,'Run.Run_ID','','yes','no',''),(3069,'','BioanalyzerRead','Well','Well','','',4,'Well','varchar(4)','','YES','',20,'^.{0,4}$',269,'','','yes','no',''),(3070,'','BioanalyzerRead','Well Status','Well_Status','','',5,'Well_Status','enum(\'Empty\',\'OK\',\'Problematic\',\'Unused\')','','YES','',20,'',269,'','','yes','no',''),(3071,'','BioanalyzerRead','Well Category','Well_Category','','',6,'Well_Category','enum(\'Sample\',\'Ladder\')','','YES','',20,'',269,'','','yes','no',''),(3075,'','BioanalyzerRead','Read Error','Read_Error','','',10,'Read_Error','enum(\'low concentration\',\'low RNA Integrity Number\')','','YES','',20,'',269,'','','yes','no',''),(3076,'','BioanalyzerRead','Read Warning','Read_Warning','','',11,'Read_Warning','enum(\'low concentration\',\'low RNA Integrity Number\')','','YES','',20,'',269,'','','yes','no',''),(3077,'','BioanalyzerRead','Sample Comment','Sample_Comment','','',12,'Sample_Comment','text','','YES','',20,'',269,'','','yes','no',''),(3078,'','BioanalyzerRun','ID','ID','Primary','',1,'BioanalyzerRun_ID','int(11)','PRI','NO','',20,'',270,'','','yes','no',''),(3079,'','BioanalyzerRun','Run','Run__ID','','',2,'FK_Run__ID','int(11)','MUL','NO','',20,'',270,'Run.Run_ID','','yes','no',''),(3080,'','BioanalyzerRun','Scanner Equipment','Scanner_Equipment__ID','','',3,'FKScanner_Equipment__ID','int(11)','','YES','',20,'',270,'Equipment.Equipment_ID','','yes','no',''),(3081,'','BioanalyzerRun','Dilution Factor','Dilution_Factor','','',4,'Dilution_Factor','varchar(20)','','NO','1',20,'^.{0,20}$',270,'','','yes','no',''),(3082,'Branch Code for Samples after indicated reagent has been applied (optional)','Branch','Code','Code','Mandatory,Primary','concat(Branch_Code,\' : \', Branch_Description)',1,'Branch_Code','varchar(5)','PRI','NO','',20,'^w{1,4}$',271,'','','yes','no',''),(3083,'How is this branch defined','Branch','Description','Description','Mandatory','',2,'Branch_Description','text','','NO','',20,'',271,'','','yes','no',''),(3084,'Set branch code when this Reagent is applied a plate or tube','Branch','Object ID','Object_ID','Obsolete','',3,'Object_ID','int(11)','','NO','',20,'',271,'','','yes','no',''),(3085,'','Branch','Object Class','Object_Class__ID','Obsolete','',4,'FK_Object_Class__ID','int(11)','','NO','',20,'',271,'Object_Class.Object_Class_ID','','yes','no',''),(3086,'Only set new branch code if currently on this branch','Branch','Parent Branch','Parent_Branch__Code','Obsolete','',5,'FKParent_Branch__Code','varchar(5)','','YES','',20,'',271,'Branch.Branch_Code','','yes','no',''),(3087,'Only set Branch if sample in this pipeline','Branch','Pipeline','Pipeline__ID','Obsolete','',6,'FK_Pipeline__ID','int(11)','','YES','',20,'',271,'Pipeline.Pipeline_ID','','yes','no',''),(3088,'','Branch','Status','Status','Obsolete','',7,'Branch_Status','enum(\'Active\',\'Inactive\')','','YES','Active',20,'',271,'','','yes','no',''),(3089,'','Enzyme','Sequence','Sequence','','',3,'Enzyme_Sequence','text','','YES','',20,'',110,'','','yes','no',''),(3090,'','Equipment','Equip Condition','Equip_Condition','','',17,'Equipment_Condition','enum(\'-80 degrees\',\'-40 degrees\',\'-20 degrees\',\'+4 degrees\',\'Variable\',\'Room Temperature\',\'\')','','NO','',20,'',31,'','','yes','no',''),(3091,'','GelAnalysis','Run','Run__ID','','',2,'FK_Run__ID','int(11)','MUL','YES','',20,'',242,'Run.Run_ID','','yes','no',''),(3092,'','GelAnalysis','Status','Status__ID','','',5,'FK_Status__ID','int(11)','','YES','',20,'',242,'Status.Status_ID','','yes','no',''),(3093,'','GelRun','Type','Type','','',9,'GelRun_Type','enum(\'Sizing Gel\',\'Other\')','','YES','',20,'',243,'','','yes','no',''),(3094,'','Genechip','ID','ID','Primary','',1,'Genechip_ID','int(11)','PRI','NO','',20,'',272,'','','yes','no',''),(3095,'','Genechip','Microarray','Microarray__ID','','',2,'FK_Microarray__ID','int(11)','MUL','YES','',20,'',272,'Microarray.Microarray_ID','','yes','no',''),(3096,'','Genechip','Type','Type__ID','Mandatory','',3,'FK_Genechip_Type__ID','int(11)','MUL','NO','',20,'',272,'Genechip_Type.Genechip_Type_ID','','yes','no',''),(3097,'','Genechip','External Barcode','External_Barcode','','',4,'External_Barcode','char(100)','MUL','NO','',20,'',272,'','','yes','no',''),(3098,'','GenechipAnalysis','ID','ID','Primary','',1,'GenechipAnalysis_ID','int(11)','PRI','NO','',20,'',273,'','','yes','no',''),(3099,'','GenechipAnalysis','Run','Run__ID','','',2,'FK_Run__ID','int(11)','MUL','NO','',20,'',273,'Run.Run_ID','','yes','no',''),(3100,'','GenechipAnalysis','DateTime','DateTime','','',3,'GenechipAnalysis_DateTime','datetime','','YES','',20,'',273,'','','yes','no',''),(3101,'','GenechipAnalysis','Analysis Type','Analysis_Type','','',4,'Analysis_Type','enum(\'Mapping\',\'Expression\',\'Universal\')','','YES','',20,'',273,'','','yes','no',''),(3102,'','GenechipAnalysis','Sample','Sample__ID','','',5,'FK_Sample__ID','int(11)','MUL','NO','',20,'',273,'Sample.Sample_ID','','yes','no',''),(3103,'','GenechipAnalysis_Attribute','GenechipAnalysis','GenechipAnalysis__ID','','',1,'FK_GenechipAnalysis__ID','int(11)','MUL','NO','',20,'',274,'GenechipAnalysis.GenechipAnalysis_ID','','yes','no',''),(3104,'','GenechipAnalysis_Attribute','Attribute','Attribute__ID','','',2,'FK_Attribute__ID','int(11)','MUL','NO','',20,'',274,'Attribute.Attribute_ID','','yes','no',''),(3105,'','GenechipAnalysis_Attribute','Attribute Value','Attribute_Value','','',3,'Attribute_Value','text','','NO','',20,'',274,'','','yes','no',''),(3106,'','GenechipAnalysis_Attribute','ID','ID','Primary','',4,'GenechipAnalysis_Attribute_ID','int(11)','PRI','NO','',20,'',274,'','','yes','no',''),(3107,'','GenechipExpAnalysis','ID','ID','Primary','',1,'GenechipExpAnalysis_ID','int(11)','PRI','NO','',20,'',275,'','','yes','no',''),(3108,'','GenechipExpAnalysis','Run','Run__ID','','',2,'FK_Run__ID','int(11)','MUL','NO','',20,'',275,'Run.Run_ID','','yes','no',''),(3109,'','GenechipExpAnalysis','Absent Probe Sets','Absent_Probe_Sets','','',3,'Absent_Probe_Sets','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3110,'','GenechipExpAnalysis','Absent Probe Sets Percent','Absent_Probe_Sets_Percent','','',4,'Absent_Probe_Sets_Percent','decimal(5,2)','','YES','',20,'',275,'','','yes','no',''),(3111,'','GenechipExpAnalysis','Algorithm','Algorithm','','',5,'Algorithm','char(40)','','YES','',20,'',275,'','','yes','no',''),(3112,'','GenechipExpAnalysis','Alpha1','Alpha1','','',6,'Alpha1','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3113,'','GenechipExpAnalysis','Alpha2','Alpha2','','',7,'Alpha2','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3114,'','GenechipExpAnalysis','Avg A Signal','Avg_A_Signal','','',8,'Avg_A_Signal','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3115,'','GenechipExpAnalysis','Avg Background','Avg_Background','','',9,'Avg_Background','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3116,'','GenechipExpAnalysis','Avg CentralMinus','Avg_CentralMinus','','',10,'Avg_CentralMinus','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3117,'','GenechipExpAnalysis','Avg CornerMinus','Avg_CornerMinus','','',11,'Avg_CornerMinus','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3118,'','GenechipExpAnalysis','Avg CornerPlus','Avg_CornerPlus','','',12,'Avg_CornerPlus','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3119,'','GenechipExpAnalysis','Avg M Signal','Avg_M_Signal','','',13,'Avg_M_Signal','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3120,'','GenechipExpAnalysis','Avg Noise','Avg_Noise','','',14,'Avg_Noise','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3121,'','GenechipExpAnalysis','Avg P Signal','Avg_P_Signal','','',15,'Avg_P_Signal','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3122,'','GenechipExpAnalysis','Avg Signal','Avg_Signal','','',16,'Avg_Signal','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3123,'','GenechipExpAnalysis','Controls','Controls','','',17,'Controls','char(40)','','YES','',20,'',275,'','','yes','no',''),(3124,'','GenechipExpAnalysis','Count CentralMinus','Count_CentralMinus','','',18,'Count_CentralMinus','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3125,'','GenechipExpAnalysis','Count CornerMinus','Count_CornerMinus','','',19,'Count_CornerMinus','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3126,'','GenechipExpAnalysis','Count CornerPlus','Count_CornerPlus','','',20,'Count_CornerPlus','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3127,'','GenechipExpAnalysis','Marginal Probe Sets','Marginal_Probe_Sets','','',21,'Marginal_Probe_Sets','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3128,'','GenechipExpAnalysis','Marginal Probe Sets Percent','Marginal_Probe_Sets_Percent','','',22,'Marginal_Probe_Sets_Percent','decimal(5,2)','','YES','',20,'',275,'','','yes','no',''),(3129,'','GenechipExpAnalysis','Max Background','Max_Background','','',23,'Max_Background','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3130,'','GenechipExpAnalysis','Max Noise','Max_Noise','','',24,'Max_Noise','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3131,'','GenechipExpAnalysis','Min Background','Min_Background','','',25,'Min_Background','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3132,'','GenechipExpAnalysis','Min Noise','Min_Noise','','',26,'Min_Noise','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3133,'','GenechipExpAnalysis','Noise RawQ','Noise_RawQ','','',27,'Noise_RawQ','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3134,'','GenechipExpAnalysis','Norm Factor','Norm_Factor','','',28,'Norm_Factor','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3135,'','GenechipExpAnalysis','Present Probe Sets','Present_Probe_Sets','','',29,'Present_Probe_Sets','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3136,'','GenechipExpAnalysis','Present Probe Sets Percent','Present_Probe_Sets_Percent','','',30,'Present_Probe_Sets_Percent','decimal(5,2)','','YES','',20,'',275,'','','yes','no',''),(3137,'','GenechipExpAnalysis','Probe Pair Thr','Probe_Pair_Thr','','',31,'Probe_Pair_Thr','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3138,'','GenechipExpAnalysis','Scale Factor','Scale_Factor','','',32,'Scale_Factor','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3139,'','GenechipExpAnalysis','Std Background','Std_Background','','',33,'Std_Background','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3140,'','GenechipExpAnalysis','Std Noise','Std_Noise','','',34,'Std_Noise','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3141,'','GenechipExpAnalysis','Tau','Tau','','',35,'Tau','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3142,'','GenechipExpAnalysis','TGT','TGT','','',36,'TGT','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3143,'','GenechipExpAnalysis','Total Probe Sets','Total_Probe_Sets','','',37,'Total_Probe_Sets','float(10,3)','','YES','',20,'',275,'','','yes','no',''),(3144,'','GenechipMapAnalysis','ID','ID','Primary','',1,'GenechipMapAnalysis_ID','int(11)','PRI','NO','',20,'',276,'','','yes','no',''),(3145,'','GenechipMapAnalysis','Run','Run__ID','','',2,'FK_Run__ID','int(11)','MUL','NO','',20,'',276,'Run.Run_ID','','yes','no',''),(3146,'','GenechipMapAnalysis','Total SNP','Total_SNP','','',3,'Total_SNP','int(11)','','YES','',20,'',276,'','','yes','no',''),(3147,'','GenechipMapAnalysis','Total QC Probes','Total_QC_Probes','','',4,'Total_QC_Probes','int(11)','','YES','',20,'',276,'','','yes','no',''),(3148,'','GenechipMapAnalysis','Called Gender','Called_Gender','','',5,'Called_Gender','char(2)','','YES','',20,'',276,'','','yes','no',''),(3149,'','GenechipMapAnalysis','SNP Call Percent','SNP_Call_Percent','','',6,'SNP_Call_Percent','decimal(5,2)','','YES','',20,'',276,'','','yes','no',''),(3150,'','GenechipMapAnalysis','AA Call Percent','AA_Call_Percent','','',7,'AA_Call_Percent','decimal(5,2)','','YES','',20,'',276,'','','yes','no',''),(3151,'','GenechipMapAnalysis','AB Call Percent','AB_Call_Percent','','',8,'AB_Call_Percent','decimal(5,2)','','YES','',20,'',276,'','','yes','no',''),(3152,'','GenechipMapAnalysis','BB Call Percent','BB_Call_Percent','','',9,'BB_Call_Percent','decimal(5,2)','','YES','',20,'',276,'','','yes','no',''),(3153,'','GenechipMapAnalysis','QC AFFX 5Q 123','QC_AFFX_5Q_123','','',10,'QC_AFFX_5Q_123','decimal(10,2)','','YES','',20,'',276,'','','yes','no',''),(3154,'','GenechipMapAnalysis','QC AFFX 5Q 456','QC_AFFX_5Q_456','','',11,'QC_AFFX_5Q_456','decimal(10,2)','','YES','',20,'',276,'','','yes','no',''),(3155,'','GenechipMapAnalysis','QC AFFX 5Q 789','QC_AFFX_5Q_789','','',12,'QC_AFFX_5Q_789','decimal(10,2)','','YES','',20,'',276,'','','yes','no',''),(3156,'','GenechipMapAnalysis','QC AFFX 5Q ABC','QC_AFFX_5Q_ABC','','',13,'QC_AFFX_5Q_ABC','decimal(10,2)','','YES','',20,'',276,'','','yes','no',''),(3157,'','GenechipMapAnalysis','QC MCR Percent','QC_MCR_Percent','','',14,'QC_MCR_Percent','decimal(5,2)','','YES','',20,'',276,'','','yes','no',''),(3158,'','GenechipMapAnalysis','QC MDR Percent','QC_MDR_Percent','','',15,'QC_MDR_Percent','decimal(5,2)','','YES','',20,'',276,'','','yes','no',''),(3159,'','GenechipMapAnalysis','SNP1','SNP1','','',16,'SNP1','char(10)','','YES','',20,'',276,'','','yes','no',''),(3160,'','GenechipMapAnalysis','SNP2','SNP2','','',17,'SNP2','char(10)','','YES','',20,'',276,'','','yes','no',''),(3161,'','GenechipMapAnalysis','SNP3','SNP3','','',18,'SNP3','char(10)','','YES','',20,'',276,'','','yes','no',''),(3162,'','GenechipMapAnalysis','SNP4','SNP4','','',19,'SNP4','char(10)','','YES','',20,'',276,'','','yes','no',''),(3163,'','GenechipMapAnalysis','SNP5','SNP5','','',20,'SNP5','char(10)','','YES','',20,'',276,'','','yes','no',''),(3164,'','GenechipMapAnalysis','SNP6','SNP6','','',21,'SNP6','char(10)','','YES','',20,'',276,'','','yes','no',''),(3165,'','GenechipMapAnalysis','SNP7','SNP7','','',22,'SNP7','char(10)','','YES','',20,'',276,'','','yes','no',''),(3166,'','GenechipMapAnalysis','SNP8','SNP8','','',23,'SNP8','char(10)','','YES','',20,'',276,'','','yes','no',''),(3167,'','GenechipMapAnalysis','SNP9','SNP9','','',24,'SNP9','char(10)','','YES','',20,'',276,'','','yes','no',''),(3168,'','GenechipMapAnalysis','SNP10','SNP10','','',25,'SNP10','char(10)','','YES','',20,'',276,'','','yes','no',''),(3169,'','GenechipMapAnalysis','SNP11','SNP11','','',26,'SNP11','char(10)','','YES','',20,'',276,'','','yes','no',''),(3170,'','GenechipMapAnalysis','SNP12','SNP12','','',27,'SNP12','char(10)','','YES','',20,'',276,'','','yes','no',''),(3171,'','GenechipMapAnalysis','SNP13','SNP13','','',28,'SNP13','char(10)','','YES','',20,'',276,'','','yes','no',''),(3172,'','GenechipMapAnalysis','SNP14','SNP14','','',29,'SNP14','char(10)','','YES','',20,'',276,'','','yes','no',''),(3173,'','GenechipMapAnalysis','SNP15','SNP15','','',30,'SNP15','char(10)','','YES','',20,'',276,'','','yes','no',''),(3174,'','GenechipMapAnalysis','SNP16','SNP16','','',31,'SNP16','char(10)','','YES','',20,'',276,'','','yes','no',''),(3175,'','GenechipMapAnalysis','SNP17','SNP17','','',32,'SNP17','char(10)','','YES','',20,'',276,'','','yes','no',''),(3176,'','GenechipMapAnalysis','SNP18','SNP18','','',33,'SNP18','char(10)','','YES','',20,'',276,'','','yes','no',''),(3177,'','GenechipMapAnalysis','SNP19','SNP19','','',34,'SNP19','char(10)','','YES','',20,'',276,'','','yes','no',''),(3178,'','GenechipMapAnalysis','SNP20','SNP20','','',35,'SNP20','char(10)','','YES','',20,'',276,'','','yes','no',''),(3179,'','GenechipMapAnalysis','SNP21','SNP21','','',36,'SNP21','char(10)','','YES','',20,'',276,'','','yes','no',''),(3180,'','GenechipMapAnalysis','SNP22','SNP22','','',37,'SNP22','char(10)','','YES','',20,'',276,'','','yes','no',''),(3181,'','GenechipMapAnalysis','SNP23','SNP23','','',38,'SNP23','char(10)','','YES','',20,'',276,'','','yes','no',''),(3182,'','GenechipMapAnalysis','SNP24','SNP24','','',39,'SNP24','char(10)','','YES','',20,'',276,'','','yes','no',''),(3183,'','GenechipMapAnalysis','SNP25','SNP25','','',40,'SNP25','char(10)','','YES','',20,'',276,'','','yes','no',''),(3184,'','GenechipMapAnalysis','SNP26','SNP26','','',41,'SNP26','char(10)','','YES','',20,'',276,'','','yes','no',''),(3185,'','GenechipMapAnalysis','SNP27','SNP27','','',42,'SNP27','char(10)','','YES','',20,'',276,'','','yes','no',''),(3186,'','GenechipMapAnalysis','SNP28','SNP28','','',43,'SNP28','char(10)','','YES','',20,'',276,'','','yes','no',''),(3187,'','GenechipMapAnalysis','SNP29','SNP29','','',44,'SNP29','char(10)','','YES','',20,'',276,'','','yes','no',''),(3188,'','GenechipMapAnalysis','SNP30','SNP30','','',45,'SNP30','char(10)','','YES','',20,'',276,'','','yes','no',''),(3189,'','GenechipMapAnalysis','SNP31','SNP31','','',46,'SNP31','char(10)','','YES','',20,'',276,'','','yes','no',''),(3190,'','GenechipMapAnalysis','SNP32','SNP32','','',47,'SNP32','char(10)','','YES','',20,'',276,'','','yes','no',''),(3191,'','GenechipMapAnalysis','SNP33','SNP33','','',48,'SNP33','char(10)','','YES','',20,'',276,'','','yes','no',''),(3192,'','GenechipMapAnalysis','SNP34','SNP34','','',49,'SNP34','char(10)','','YES','',20,'',276,'','','yes','no',''),(3193,'','GenechipMapAnalysis','SNP35','SNP35','','',50,'SNP35','char(10)','','YES','',20,'',276,'','','yes','no',''),(3194,'','GenechipMapAnalysis','SNP36','SNP36','','',51,'SNP36','char(10)','','YES','',20,'',276,'','','yes','no',''),(3195,'','GenechipMapAnalysis','SNP37','SNP37','','',52,'SNP37','char(10)','','YES','',20,'',276,'','','yes','no',''),(3196,'','GenechipMapAnalysis','SNP38','SNP38','','',53,'SNP38','char(10)','','YES','',20,'',276,'','','yes','no',''),(3197,'','GenechipMapAnalysis','SNP39','SNP39','','',54,'SNP39','char(10)','','YES','',20,'',276,'','','yes','no',''),(3198,'','GenechipMapAnalysis','SNP40','SNP40','','',55,'SNP40','char(10)','','YES','',20,'',276,'','','yes','no',''),(3199,'','GenechipMapAnalysis','SNP41','SNP41','','',56,'SNP41','char(10)','','YES','',20,'',276,'','','yes','no',''),(3200,'','GenechipMapAnalysis','SNP42','SNP42','','',57,'SNP42','char(10)','','YES','',20,'',276,'','','yes','no',''),(3201,'','GenechipMapAnalysis','SNP43','SNP43','','',58,'SNP43','char(10)','','YES','',20,'',276,'','','yes','no',''),(3202,'','GenechipMapAnalysis','SNP44','SNP44','','',59,'SNP44','char(10)','','YES','',20,'',276,'','','yes','no',''),(3203,'','GenechipMapAnalysis','SNP45','SNP45','','',60,'SNP45','char(10)','','YES','',20,'',276,'','','yes','no',''),(3204,'','GenechipMapAnalysis','SNP46','SNP46','','',61,'SNP46','char(10)','','YES','',20,'',276,'','','yes','no',''),(3205,'','GenechipMapAnalysis','SNP47','SNP47','','',62,'SNP47','char(10)','','YES','',20,'',276,'','','yes','no',''),(3206,'','GenechipMapAnalysis','SNP48','SNP48','','',63,'SNP48','char(10)','','YES','',20,'',276,'','','yes','no',''),(3207,'','GenechipMapAnalysis','SNP49','SNP49','','',64,'SNP49','char(10)','','YES','',20,'',276,'','','yes','no',''),(3208,'','GenechipMapAnalysis','SNP50','SNP50','','',65,'SNP50','char(10)','','YES','',20,'',276,'','','yes','no',''),(3209,'','GenechipRun','ID','ID','Primary','',1,'GenechipRun_ID','int(11)','PRI','NO','',20,'',277,'','','yes','no',''),(3210,'','GenechipRun','Run','Run__ID','','',2,'FK_Run__ID','int(11)','MUL','NO','',20,'',277,'Run.Run_ID','','yes','no',''),(3211,'','GenechipRun','Scanner Equipment','Scanner_Equipment__ID','','',3,'FKScanner_Equipment__ID','int(11)','','YES','',20,'',277,'Equipment.Equipment_ID','','yes','no',''),(3212,'','GenechipRun','CEL file','CEL_file','','',4,'CEL_file','char(100)','','YES','',20,'',277,'','','yes','no',''),(3213,'','GenechipRun','DAT file','DAT_file','','',5,'DAT_file','char(100)','','YES','',20,'',277,'','','yes','no',''),(3214,'','GenechipRun','CHP file','CHP_file','','',6,'CHP_file','char(100)','','YES','',20,'',277,'','','yes','no',''),(3215,'','Genechip_Type','ID','ID','Primary','Genechip_Type_Name',1,'Genechip_Type_ID','int(11)','PRI','NO','',20,'',278,'','','yes','no',''),(3216,'','Genechip_Type','Array Type','Array_Type','','',2,'Array_Type','enum(\'Expression\',\'Mapping\',\'Resequencing\',\'Universal\')','','NO','Expression',20,'',278,'','','yes','no',''),(3218,'','Lane','Growth','Growth','','',9,'Lane_Growth','enum(\'No Grow\',\'Slow Grow\',\'Unused\',\'Problematic\',\'Empty\')','','YES','',20,'',181,'','','yes','no',''),(3219,'','Microarray','ID','ID','Primary','',1,'Microarray_ID','int(11)','PRI','NO','',20,'',279,'','','yes','no',''),(3220,'','Microarray','Stock','Stock__ID','','',2,'FK_Stock__ID','int(11)','MUL','YES','',20,'',279,'Stock.Stock_ID','','yes','no',''),(3221,'','Microarray','Rack','Rack__ID','','',3,'FK_Rack__ID','int(11)','','YES','',20,'',279,'Rack.Rack_ID','','yes','no',''),(3222,'','Microarray','Type','Type','','',4,'Microarray_Type','enum(\'Genechip\')','','NO','Genechip',20,'',279,'','','yes','no',''),(3223,'','Microarray','Expiry DateTime','Expiry_DateTime','','',5,'Expiry_DateTime','datetime','','YES','',20,'',279,'','','yes','no',''),(3224,'','Microarray','Used DateTime','Used_DateTime','','',6,'Used_DateTime','datetime','','YES','',20,'',279,'','','yes','no',''),(3225,'','Microarray','Number','Number','','',7,'Microarray_Number','int(11)','','NO','',20,'',279,'','','yes','no',''),(3226,'','Microarray','Number in Batch','Number_in_Batch','','',8,'Microarray_Number_in_Batch','int(11)','','NO','',20,'',279,'','','yes','no',''),(3227,'','Microarray','Status','Status','','',9,'Microarray_Status','enum(\'Unused\',\'Used\',\'Thrown Out\',\'Expired\')','','NO','Unused',20,'',279,'','','yes','no',''),(3228,'','Ordered_Procedure','Object Class','Object_Class__ID','','',2,'FK_Object_Class__ID','int(11)','MUL','NO','',20,'',217,'Object_Class.Object_Class_ID','','yes','no',''),(3229,'','Pipeline','Code','Code','','',5,'Pipeline_Code','char(3)','UNI','NO','',20,'w{1,3}',187,'','','yes','no',''),(3230,'','Plate','Branch','Branch__Code','','',23,'FK_Branch__Code','varchar(5)','','NO','',20,'',59,'Branch.Branch_Code','','no','yes',''),(3231,'','Plate','Pipeline','Pipeline__ID','Mandatory','',5,'FK_Pipeline__ID','int(11)','','NO','',20,'',59,'Pipeline.Pipeline_ID','','yes','no',''),(3232,'','Probe_Set','ID','ID','Primary','Probe_Set_Name',1,'Probe_Set_ID','int(11)','PRI','NO','',20,'',280,'','','yes','no',''),(3234,'','Probe_Set_Value','ID','ID','Primary','',1,'Probe_Set_Value_ID','int(11)','PRI','NO','',20,'',281,'','','yes','no',''),(3235,'','Probe_Set_Value','Probe Set','Probe_Set__ID','','',2,'FK_Probe_Set__ID','int(11)','MUL','NO','',20,'',281,'Probe_Set.Probe_Set_ID','','yes','no',''),(3236,'','Probe_Set_Value','GenechipExpAnalysis','GenechipExpAnalysis__ID','','',3,'FK_GenechipExpAnalysis__ID','int(11)','MUL','NO','',20,'',281,'GenechipExpAnalysis.GenechipExpAnalysis_ID','','yes','no',''),(3237,'','Probe_Set_Value','Probe Set Type','Probe_Set_Type','','',4,'Probe_Set_Type','enum(\'Housekeeping Control\',\'Spike Control\')','','YES','',20,'',281,'','','yes','no',''),(3238,'','Probe_Set_Value','Sig5','Sig5','','',5,'Sig5','float(10,2)','','YES','',20,'',281,'','','yes','no',''),(3239,'','Probe_Set_Value','Det5','Det5','','',6,'Det5','char(10)','','YES','',20,'',281,'','','yes','no',''),(3240,'','Probe_Set_Value','SigM','SigM','','',7,'SigM','float(10,2)','','YES','',20,'',281,'','','yes','no',''),(3241,'','Probe_Set_Value','DetM','DetM','','',8,'DetM','char(10)','','YES','',20,'',281,'','','yes','no',''),(3242,'','Probe_Set_Value','Sig3','Sig3','','',9,'Sig3','float(10,2)','','YES','',20,'',281,'','','yes','no',''),(3243,'','Probe_Set_Value','Det3','Det3','','',10,'Det3','char(10)','','YES','',20,'',281,'','','yes','no',''),(3244,'','Probe_Set_Value','SigAll','SigAll','','',11,'SigAll','float(10,2)','','YES','',20,'',281,'','','yes','no',''),(3245,'','Probe_Set_Value','Sig35','Sig35','','',12,'Sig35','float(10,2)','','YES','',20,'',281,'','','yes','no',''),(3246,'','Run','Excluded Wells','Excluded_Wells','','',13,'Excluded_Wells','text','','YES','',20,'',251,'','','yes','no',''),(3247,'','SpectAnalysis','ID','ID','Primary','',1,'SpectAnalysis_ID','int(11)','PRI','NO','',20,'',282,'','','yes','no',''),(3248,'','SpectAnalysis','Run','Run__ID','','',2,'FK_Run__ID','int(11)','MUL','NO','',20,'',282,'Run.Run_ID','','yes','no',''),(3249,'','SpectAnalysis','A260 Blank Avg','A260_Blank_Avg','','',3,'A260_Blank_Avg','float(4,3)','','YES','',20,'',282,'','','yes','no',''),(3250,'','SpectAnalysis','A280 Blank Avg','A280_Blank_Avg','','',4,'A280_Blank_Avg','float(4,3)','','YES','',20,'',282,'','','yes','no',''),(3251,'','SpectRead','ID','ID','Primary','',1,'SpectRead_ID','int(11)','PRI','NO','',20,'',283,'','','yes','no',''),(3252,'','SpectRead','Run','Run__ID','','',2,'FK_Run__ID','int(11)','MUL','NO','',20,'',283,'Run.Run_ID','','yes','no',''),(3253,'','SpectRead','Sample','Sample__ID','','',3,'FK_Sample__ID','int(11)','MUL','NO','',20,'',283,'Sample.Sample_ID','','yes','no',''),(3254,'','SpectRead','Well','Well','','',4,'Well','char(3)','','YES','',20,'',283,'','','yes','no',''),(3255,'','SpectRead','Well Status','Well_Status','','',5,'Well_Status','enum(\'OK\',\'Empty\',\'Unused\',\'Problematic\',\'Ignored\')','','YES','',20,'',283,'','','yes','no',''),(3256,'','SpectRead','Well Category','Well_Category','','',6,'Well_Category','enum(\'Sample\',\'Blank\',\'ssDNA\',\'hgDNA\')','','YES','',20,'',283,'','','yes','no',''),(3257,'','SpectRead','A260m','A260m','','',7,'A260m','float(4,3)','','YES','',20,'',283,'','','yes','no',''),(3258,'','SpectRead','A260cor','A260cor','','',8,'A260cor','float(4,3)','','YES','',20,'',283,'','','yes','no',''),(3259,'','SpectRead','A280m','A280m','','',9,'A280m','float(4,3)','','YES','',20,'',283,'','','yes','no',''),(3260,'','SpectRead','A280cor','A280cor','','',10,'A280cor','float(4,3)','','YES','',20,'',283,'','','yes','no',''),(3261,'','SpectRead','A260','A260','','',11,'A260','float(4,3)','','YES','',20,'',283,'','','yes','no',''),(3262,'','SpectRead','A280','A280','','',12,'A280','float(4,3)','','YES','',20,'',283,'','','yes','no',''),(3263,'','SpectRead','A260 A280 ratio','A260_A280_ratio','','',13,'A260_A280_ratio','float(4,3)','','YES','',20,'',283,'','','yes','no',''),(3264,'','SpectRead','Dilution Factor','Dilution_Factor','','',14,'Dilution_Factor','float(4,3)','','YES','',20,'',283,'','','yes','no',''),(3265,'','SpectRead','Concentration','Concentration','','',15,'Concentration','float','','YES','',20,'',283,'','','yes','no',''),(3266,'','SpectRead','Unit','Unit','','',16,'Unit','varchar(15)','','YES','',20,'^.{0,15}$',283,'','','yes','no',''),(3267,'','SpectRead','Read Error','Read_Error','','',17,'Read_Error','enum(\'low concentration\',\'low A260cor/A280cor ratio\',\'A260m below 0.100\',\'SS DNA concentration out of range\',\'human gDNA concentration out of range\')','','YES','',20,'',283,'','','yes','no',''),(3268,'','SpectRead','Read Warning','Read_Warning','','',18,'Read_Warning','enum(\'low A260cor/A280cor ratio\',\'SS DNA concentration out of range\',\'human gDNA concentration out of range\')','','YES','',20,'',283,'','','yes','no',''),(3269,'','SpectRun','ID','ID','Primary','',1,'SpectRun_ID','int(11)','PRI','NO','',20,'',284,'','','yes','no',''),(3270,'','SpectRun','Run','Run__ID','','',2,'FK_Run__ID','int(11)','MUL','NO','',20,'',284,'Run.Run_ID','','yes','no',''),(3271,'','SpectRun','Scanner Equipment','Scanner_Equipment__ID','','',3,'FKScanner_Equipment__ID','int(11)','','YES','',20,'',284,'Equipment.Equipment_ID','','yes','no',''),(3274,'','Genomic_Library','InsertSite Enzyme','InsertSite_Enzyme__ID','Mandatory,NewLink','',4,'FKInsertSite_Enzyme__ID','int(11)','','YES','',20,'',92,'Enzyme.Enzyme_ID','','yes','no',''),(3275,'','Genomic_Library','DNAShearing Enzyme','DNAShearing_Enzyme__ID','NewLink','',7,'FKDNAShearing_Enzyme__ID','int(11)','','YES','',20,'',92,'Enzyme.Enzyme_ID','','yes','no',''),(3276,'','Genomic_Library','Genomic Coverage','Genomic_Coverage','','',11,'Genomic_Coverage','float(5,2)','','YES','',20,'',92,'','','yes','no',''),(3277,'','Genomic_Library','Recombinant Clones','Recombinant_Clones','','',12,'Recombinant_Clones','int(11)','','YES','',20,'',92,'','','yes','no',''),(3278,'','Genomic_Library','Non Recombinant Clones','Non_Recombinant_Clones','','',13,'Non_Recombinant_Clones','int(11)','','YES','',20,'',92,'','','yes','no',''),(3279,'','Sorted_Cell','ID','ID','Primary','',1,'Sorted_Cell_ID','int(11)','PRI','NO','',20,'',285,'','','yes','no',''),(3280,'','Sorted_Cell','Source','Source__ID','','',2,'FK_Source__ID','int(11)','MUL','NO','',20,'',285,'Source.Source_ID','','yes','no',''),(3281,'','Sorted_Cell','SortedBy Contact','SortedBy_Contact__ID','','',3,'FKSortedBy_Contact__ID','int(11)','','NO','',20,'',285,'Contact.Contact_ID','','yes','no',''),(3282,'','Sorted_Cell','Type','Type','','',4,'Sorted_Cell_Type','enum(\'CD19+_Kappa+ B-Cells\',\'CD19+_Lambda Light Chain+ B-Cells\',\'CD19+ B-Cells\')','','YES','',20,'',285,'','','yes','no',''),(3283,'','Sorted_Cell','Cell Condition','Cell_Condition','','',5,'Sorted_Cell_Condition','enum(\'Fresh\',\'Frozen\')','','YES','',20,'',285,'','','yes','no',''),(3284,'','Source','Container Format','Plate_Format__ID','','',12,'FK_Plate_Format__ID','int(11)','','YES','20',20,'',194,'Plate_Format.Plate_Format_ID','','yes','no',''),(3285,'','SequenceAnalysis','mask restriction site','mask_restriction_site','','',42,'mask_restriction_site','enum(\'Yes\',\'No\')','','YES','Yes',20,'',255,'','','yes','no',''),(3286,'','Stock','Purchase Order','Purchase_Order','','',21,'Purchase_Order','varchar(20)','','YES','',20,'^.{0,20}$',7,'','','yes','no',''),(3287,'','Tissue_Source','ID','ID','Primary','',1,'Tissue_Source_ID','int(11)','PRI','NO','',20,'',286,'','','yes','no',''),(3288,'','Tissue_Source','Source','Source__ID','','',2,'FK_Source__ID','int(11)','MUL','YES','',20,'',286,'Source.Source_ID','','yes','no',''),(3289,'','Tissue_Source','Type','Type','','',3,'Tissue_Source_Type','varchar(40)','','YES','',20,'^.{0,40}$',286,'','','yes','no',''),(3290,'','Tissue_Source','Source Condition','Source_Condition','','',4,'Tissue_Source_Condition','enum(\'Fresh\',\'Frozen\')','','YES','',20,'',286,'','','yes','no',''),(3291,'','Pipeline','Parent Pipeline','Parent_Pipeline__ID','','',6,'FKParent_Pipeline__ID','int(11)','','YES','',20,'',187,'Pipeline.Pipeline_ID','This field indicates whether current entry is a subset of another pipeline','yes','no',''),(3298,'','SolexaRun','ID','ID','Primary','',1,'SolexaRun_ID','int(11)','PRI','NO','',20,'',288,'','','yes','no',''),(3299,'','SolexaRun','Lane','Lane','','',2,'Lane','enum(\'1\',\'2\',\'3\',\'4\',\'5\',\'6\',\'7\',\'8\')','','YES','',20,'',288,'','','yes','no',''),(3300,'','SolexaRun','Run','Run__ID','','',3,'FK_Run__ID','int(11)','MUL','NO','',20,'',288,'Run.Run_ID','','yes','no',''),(3301,'','SolexaAnalysis','ID','ID','Primary','',1,'SolexaAnalysis_ID','int(11)','PRI','NO','',20,'',289,'','','yes','no',''),(3306,'','SolexaAnalysis','Run','Run__ID','','',6,'FK_Run__ID','int(11)','MUL','NO','',20,'',289,'Run.Run_ID','','yes','no',''),(3307,'','RunBatch_Attribute','RunBatch','RunBatch__ID','','',1,'FK_RunBatch__ID','int(11)','MUL','NO','',20,'',290,'RunBatch.RunBatch_ID','','yes','no',''),(3308,'','RunBatch_Attribute','Attribute','Attribute__ID','','',2,'FK_Attribute__ID','int(11)','MUL','NO','',20,'',290,'Attribute.Attribute_ID','','yes','no',''),(3309,'','RunBatch_Attribute','Attribute Value','Attribute_Value','','',3,'Attribute_Value','text','','NO','',20,'',290,'','','yes','no',''),(3310,'','RunBatch_Attribute','ID','ID','Primary','',4,'RunBatch_Attribute_ID','int(11)','PRI','NO','',20,'',290,'','','yes','no',''),(3311,'','RunBatch_Attribute','Employee','Employee__ID','','',5,'FK_Employee__ID','int(11)','','YES','',20,'',290,'Employee.Employee_ID','','yes','no',''),(3312,'','RunBatch_Attribute','Set DateTime','Set_DateTime','','',6,'Set_DateTime','datetime','','NO','0000-00-00 00:00:00',20,'',290,'','','yes','no',''),(3313,'','SequenceRun','Run Direction','Run_Direction','','',22,'Run_Direction','enum(\'3prime\',\'5prime\',\'N/A\',\'Unknown\')','','YES','N/A',20,'',256,'','','yes','no',''),(3314,'','Flowcell','ID','ID','Primary','Flowcell_Code',1,'Flowcell_ID','int(11)','PRI','NO','',20,'',291,'','','yes','no',''),(3315,'','Flowcell','Flowcell Code','Code','','',2,'Flowcell_Code','varchar(40)','MUL','NO','',20,'^.{0,40}$',291,'','','yes','no',''),(3316,'','Flowcell','Grafted Datetime','Grafted_Datetime','Obsolete','',3,'Grafted_Datetime','datetime','','YES','',20,'',291,'','','yes','no',''),(3317,'','Flowcell','Lot Number','Lot_Number','Obsolete','',4,'Lot_Number','varchar(40)','','YES','',20,'^.{0,40}$',291,'','','yes','no',''),(3318,'','SolexaRun','Flowcell','Flowcell__ID','','',4,'FK_Flowcell__ID','int(11)','MUL','NO','',20,'',288,'Flowcell.Flowcell_ID','','yes','no',''),(3319,'','TraceData','Run','Run__ID','','',1,'FK_Run__ID','int(11)','MUL','YES','',20,'',95,'Run.Run_ID','','yes','no',''),(3320,'','Trigger','Fatal','Fatal','','',8,'Fatal','enum(\'Yes\',\'No\')','','YES','Yes',20,'',199,'','','yes','no',''),(3321,'','Barcode_Label','FK_Label_Format__ID','FK_Label_Format__ID','','',11,'FK_Label_Format__ID','int(11)','','NO','',20,'',2,'Label_Format.Label_Format_ID','','yes','no',''),(3322,'','BioanalyzerRead','RNA DNA Concentration','RNA_DNA_Concentration','','',7,'RNA_DNA_Concentration','float','','YES','',20,'',269,'','','yes','no',''),(3323,'','BioanalyzerRead','RNA DNA Concentration Unit','RNA_DNA_Concentration_Unit','','',8,'RNA_DNA_Concentration_Unit','varchar(15)','','YES','',20,'^.{0,15}$',269,'','','yes','no',''),(3324,'','BioanalyzerRead','RNA DNA Integrity Number','RNA_DNA_Integrity_Number','','',9,'RNA_DNA_Integrity_Number','float','','YES','',20,'',269,'','','yes','no',''),(3325,'','BioanalyzerRun','Invoiced','Invoiced','','',5,'Invoiced','enum(\'No\',\'Yes\')','','YES','No',20,'',270,'','','yes','no',''),(3326,'','Box','Box Status','Box_Status','','',11,'Box_Status','enum(\'Unopened\',\'Open\',\'Expired\',\'Inactive\')','','YES','Unopened',20,'',3,'','','yes','no',''),(3327,'','Branch_Condition','Branch Condition ID','Branch_Condition_ID','Primary','',1,'Branch_Condition_ID','int(11)','PRI','NO','',20,'',292,'','','yes','no',''),(3328,'','Branch_Condition','Branch','FK_Branch__Code','','',2,'FK_Branch__Code','varchar(5)','','NO','',20,'',292,'Branch.Branch_Code','','yes','no',''),(3329,'','Branch_Condition','Object_Class','FK_Object_Class__ID','Mandatory','',3,'FK_Object_Class__ID','int(11)','','NO','',20,'',292,'Object_Class.Object_Class_ID','','yes','no',''),(3330,'','Branch_Condition','Object ID','Object_ID','Mandatory,Searchable','',4,'Object_ID','int(11)','','NO','',20,'',292,'','','yes','no',''),(3331,'','Branch_Condition','Pipeline','FK_Pipeline__ID','','',5,'FK_Pipeline__ID','int(11)','','YES','',20,'',292,'Pipeline.Pipeline_ID','','yes','no',''),(3332,'','Branch_Condition','Parent Branch','FKParent_Branch__Code','','',6,'FKParent_Branch__Code','varchar(5)','','YES','',20,'',292,'Branch.Branch_Code','','yes','no',''),(3333,'','Branch_Condition','Branch Condition Status','Branch_Condition_Status','Mandatory','',7,'Branch_Condition_Status','enum(\'Active\',\'Inactive\')','','YES','',20,'',292,'','','yes','no',''),(3334,'','Defined_Plate_Set','Defined Plate Set ID','Defined_Plate_Set_ID','Primary','',1,'Defined_Plate_Set_ID','int(11)','PRI','NO','',20,'',293,'','','yes','no',''),(3335,'','Defined_Plate_Set','Plate Set Defined','Plate_Set_Defined','','',2,'Plate_Set_Defined','datetime','','YES','',20,'',293,'','','yes','no',''),(3336,'','Defined_Plate_Set','Employee','FK_Employee__ID','','',3,'FK_Employee__ID','int(11)','','YES','',20,'',293,'Employee.Employee_ID','','yes','no',''),(3337,'','Extraction_Details','RNA DNA Isolated Date','RNA_DNA_Isolated_Date','','',3,'RNA_DNA_Isolated_Date','date','','YES','',20,'',163,'','','yes','no',''),(3338,'','Extraction_Details','Amount RNA DNA Source Used','Amount_RNA_DNA_Source_Used','','',9,'Amount_RNA_DNA_Source_Used','int(11)','','YES','',20,'',163,'','','yes','no',''),(3339,'','Extraction_Details','Amount RNA DNA Source Used Units','Amount_RNA_DNA_Source_Used_Units','','',10,'Amount_RNA_DNA_Source_Used_Units','enum(\'Cells\',\'Gram of Tissue\',\'Embryos\',\'Litters\',\'Organs\',\'ug/ng\')','','YES','',20,'',163,'','','yes','no',''),(3340,'','GCOS_Config','Template Name','Template_Name','','',2,'Template_Name','varchar(34)','UNI','NO','',20,'^.{0,34}$',213,'','','yes','no',''),(3341,'','GCOS_Config','Template Class','Template_Class','','',3,'Template_Class','enum(\'Sample\',\'Experiment\')','','NO','Sample',20,'',213,'','','yes','no',''),(3342,'','GCOS_Config_Record','GCOS Config Record ID','GCOS_Config_Record_ID','Primary','',1,'GCOS_Config_Record_ID','int(11)','PRI','NO','',20,'',294,'','','yes','no',''),(3343,'','GCOS_Config_Record','Attribute Type','Attribute_Type','','',2,'Attribute_Type','enum(\'Field\',\'Prep\')','','YES','',20,'',294,'','','yes','no',''),(3344,'','GCOS_Config_Record','Attribute Name','Attribute_Name','','',3,'Attribute_Name','char(50)','','NO','',20,'',294,'','','yes','no',''),(3345,'','GCOS_Config_Record','Attribute Table','Attribute_Table','','',4,'Attribute_Table','char(50)','','YES','',20,'',294,'','','yes','no',''),(3346,'','GCOS_Config_Record','Attribute Step','Attribute_Step','','',5,'Attribute_Step','char(50)','','YES','',20,'',294,'','','yes','no',''),(3347,'','GCOS_Config_Record','Attribute Field','Attribute_Field','','',6,'Attribute_Field','char(50)','','NO','',20,'',294,'','','yes','no',''),(3348,'','GCOS_Config_Record','GCOS_Config','FK_GCOS_Config__ID','','',7,'FK_GCOS_Config__ID','int(11)','','NO','',20,'',294,'GCOS_Config.GCOS_Config_ID','','yes','no',''),(3349,'','GCOS_Config_Record','Attribute Default','Attribute_Default','','',8,'Attribute_Default','char(50)','','YES','',20,'',294,'','','yes','no',''),(3350,'','GelAnalysis','Gel Name','Gel_Name','','',6,'Gel_Name','varchar(40)','','YES','',20,'^.{0,40}$',242,'','','yes','no',''),(3357,'','GelRun','Equipment','FKGelBox_Equipment__ID','','',9,'FKGelBox_Equipment__ID','int(11)','','YES','',20,'',243,'Equipment.Equipment_ID','','yes','no',''),(3358,'','GenechipAnalysis','Artifact','Artifact','','',6,'Artifact','enum(\'No\',\'Yes\')','','YES','No',20,'',273,'','','yes','no',''),(3359,'','GenechipRun','Equipment','FKOven_Equipment__ID','','',7,'FKOven_Equipment__ID','int(11)','','YES','',20,'',277,'Equipment.Equipment_ID','','yes','no',''),(3360,'','GenechipRun','GCOS_Config','FKSample_GCOS_Config__ID','','',8,'FKSample_GCOS_Config__ID','int(11)','MUL','NO','',20,'',277,'GCOS_Config.GCOS_Config_ID','','yes','no',''),(3361,'','GenechipRun','GCOS_Config','FKExperiment_GCOS_Config__ID','','',9,'FKExperiment_GCOS_Config__ID','int(11)','MUL','NO','',20,'',277,'GCOS_Config.GCOS_Config_ID','','yes','no',''),(3362,'','GenechipRun','Invoiced','Invoiced','','',10,'Invoiced','enum(\'No\',\'Yes\')','','YES','No',20,'',277,'','','yes','no',''),(3363,'','Genechip_Type','Genechip Type Name','Genechip_Type_Name','','',3,'Genechip_Type_Name','char(50)','','YES','',20,'',278,'','','yes','no',''),(3364,'','Genechip_Type','Sub Array Type','Sub_Array_Type','','',4,'Sub_Array_Type','enum(\'\',\'500K Mapping\',\'250K Mapping\',\'100K Mapping\',\'10K Mapping\',\'Other Mapping\',\'Human Expression\',\'Rat Expression\',\'Mouse Expression\',\'Yeast Expression\',\'Other Expression\',\'Mouse Tiling\')','','YES','',20,'',278,'','','yes','no',''),(3365,'','Genomic_Library','Blue White Selection','Blue_White_Selection','Mandatory','',14,'Blue_White_Selection','enum(\'Yes\',\'No\')','','NO','No',20,'',92,'','','yes','no',''),(3366,'','Label_Format','Label Format ID','Label_Format_ID','Primary','Label_Format_Name',1,'Label_Format_ID','int(11)','PRI','NO','',20,'',295,'','','yes','no',''),(3367,'','Label_Format','Label Format Name','Label_Format_Name','','',2,'Label_Format_Name','varchar(20)','','NO','',20,'^.{0,20}$',295,'','','yes','no',''),(3368,'','Label_Format','Label Description','Label_Description','','',3,'Label_Description','text','','NO','',20,'',295,'','','yes','no',''),(3369,'','Maintenance','Maintenance Type','FK_Maintenance_Process_Type__ID','Mandatory','',1,'FK_Maintenance_Process_Type__ID','int(11)','','NO','',20,'',44,'Maintenance_Process_Type.Maintenance_Process_Type_ID','','yes','no',''),(3370,'','Maintenance_Process_Type','Maintenance Process Type ID','Maintenance_Process_Type_ID','Primary','Process_Type_Name',1,'Maintenance_Process_Type_ID','int(11)','PRI','NO','',20,'',296,'','','yes','no',''),(3371,'','Maintenance_Process_Type','Process Type Description','Process_Type_Description','','',2,'Process_Type_Description','text','','YES','',20,'',296,'','','yes','no',''),(3372,'','Maintenance_Process_Type','Process Type Name','Process_Type_Name','','',3,'Process_Type_Name','varchar(100)','','NO','',20,'^.{0,100}$',296,'','','yes','no',''),(3373,'','Pipeline_Step','Pipeline Step ID','Pipeline_Step_ID','Primary','',1,'Pipeline_Step_ID','int(11)','PRI','NO','',20,'',297,'','','yes','no',''),(3374,'','Pipeline_Step','Object_Class','FK_Object_Class__ID','','',2,'FK_Object_Class__ID','int(11)','MUL','NO','',20,'',297,'Object_Class.Object_Class_ID','','yes','no',''),(3375,'','Pipeline_Step','Object ID','Object_ID','','',3,'Object_ID','int(11)','MUL','NO','',20,'',297,'','','yes','no',''),(3376,'','Pipeline_Step','Pipeline Step Order','Pipeline_Step_Order','','',4,'Pipeline_Step_Order','tinyint(4)','','NO','',20,'',297,'','','yes','no',''),(3377,'','Pipeline_Step','Pipeline','FK_Pipeline__ID','','',5,'FK_Pipeline__ID','int(11)','MUL','NO','',20,'',297,'Pipeline.Pipeline_ID','','yes','no',''),(3378,'','Pipeline_StepRelationship','Pipeline StepRelationship ID','Pipeline_StepRelationship_ID','Primary','',1,'Pipeline_StepRelationship_ID','int(11)','PRI','NO','',20,'',298,'','','yes','no',''),(3379,'','Pipeline_StepRelationship','Pipeline_Step','FKParent_Pipeline_Step__ID','','',2,'FKParent_Pipeline_Step__ID','int(11)','MUL','NO','',20,'',298,'Pipeline_Step.Pipeline_Step_ID','','yes','no',''),(3380,'','Pipeline_StepRelationship','Pipeline_Step','FKChild_Pipeline_Step__ID','','',3,'FKChild_Pipeline_Step__ID','int(11)','MUL','NO','',20,'',298,'Pipeline_Step.Pipeline_Step_ID','','yes','no',''),(3381,'','Plate','Plate Label','Plate_Label','','',24,'Plate_Label','varchar(40)','MUL','YES','',20,'^.{0,40}$',59,'','','yes','no',''),(3382,'','Plate_Format','Capacity','Capacity','','',9,'Capacity','char(4)','','YES','',20,'',60,'','','yes','no',''),(3383,'','Plate_Format','Capacity Units','Capacity_Units','','',10,'Capacity_Units','char(4)','','YES','',20,'',60,'','','yes','no',''),(3384,'','Plate_Format','Well Lookup Key','Well_Lookup_Key','','',12,'Well_Lookup_Key','enum(\'Plate_384\',\'Plate_96\',\'Gel_121_Standard\',\'Gel_121_Custom\',\'Tube\')','','YES','',20,'',60,'','','yes','no',''),(3385,'','Printer','Equipment','FK_Equipment__ID','','',8,'FK_Equipment__ID','int(11)','','NO','',20,'',171,'Equipment.Equipment_ID','','yes','no',''),(3386,'','Printer','Label_Format','FK_Label_Format__ID','','',9,'FK_Label_Format__ID','int(11)','','NO','',20,'',171,'Label_Format.Label_Format_ID','','yes','no',''),(3387,'','Printer_Assignment','Label_Format','FK_Label_Format__ID','','',4,'FK_Label_Format__ID','int(11)','','NO','',20,'',203,'Label_Format.Label_Format_ID','','yes','no',''),(3388,'','Probe_Set','Probe Set Name','Probe_Set_Name','','',2,'Probe_Set_Name','char(50)','MUL','YES','',20,'',280,'','','yes','no',''),(3389,'','Protocol_Step','Attribute','FKQC_Attribute__ID','','',13,'FKQC_Attribute__ID','int(11)','','YES','',20,'',67,'Attribute.Attribute_ID','','yes','no',''),(3390,'','Protocol_Step','QC Condition','QC_Condition','','',14,'QC_Condition','varchar(40)','','YES','',20,'^.{0,40}$',67,'','','yes','no',''),(3391,'','Protocol_Step','Validate','Validate','','',15,'Validate','enum(\'Primer\',\'Enzyme\',\'Antibiotic\')','','YES','',20,'',67,'','','yes','no',''),(3392,'','RNA_DNA_Collection','RNA DNA Collection ID','RNA_DNA_Collection_ID','Primary','',1,'RNA_DNA_Collection_ID','int(11)','PRI','NO','',20,'',299,'','','yes','no',''),(3393,'','RNA_DNA_Collection','Collection','FK_Library__Name','Searchable','',2,'FK_Library__Name','varchar(6)','UNI','NO','',20,'^\'?[a-zA-Z0-9]{6}\'?$',299,'Library.Library_Name','','yes','no',''),(3394,'','RNA_DNA_Collection','RNA DNA Source Format','RNA_DNA_Source_Format','','',3,'RNA_DNA_Source_Format','enum(\'RNA_DNA_Tube\')','','NO','RNA_DNA_Tube',20,'',299,'','','yes','no',''),(3395,'','RNA_DNA_Collection','RNA DNA Collection Type','Collection_Type','','',4,'Collection_Type','enum(\'\',\'SAGE\',\'LongSAGE\',\'PCR-SAGE\',\'PCR-LongSAGE\',\'SAGELite-SAGE\',\'SAGELite-LongSAGE\',\'Solexa\',\'Microarray\')','','YES','',20,'',299,'','','yes','no',''),(3396,'','RNA_DNA_Source','RNA DNA Source ID','RNA_DNA_Source_ID','Primary','',1,'RNA_DNA_Source_ID','int(11)','PRI','NO','',20,'',300,'','','yes','no',''),(3397,'','RNA_DNA_Source','Starting Material','FK_Source__ID','','',2,'FK_Source__ID','int(11)','MUL','NO','',20,'',300,'Source.Source_ID','','yes','no',''),(3398,'','RNA_DNA_Source','Sample Collection Date','Sample_Collection_Date','','',3,'Sample_Collection_Date','date','','NO','0000-00-00',20,'',300,'','','yes','no',''),(3399,'','RNA_DNA_Source','RNA DNA Isolation Date','RNA_DNA_Isolation_Date','','',4,'RNA_DNA_Isolation_Date','date','','NO','0000-00-00',20,'',300,'','','yes','no',''),(3400,'','RNA_DNA_Source','RNA DNA Isolation Method','RNA_DNA_Isolation_Method','','',5,'RNA_DNA_Isolation_Method','varchar(40)','','YES','',20,'^.{0,40}$',300,'','','yes','no',''),(3401,'','RNA_DNA_Source','Nature','Nature','','',6,'Nature','enum(\'\',\'Total RNA\',\'mRNA\',\'Tissue\',\'Cells\',\'RNA - DNase Treated\',\'cDNA\',\'1st strand cDNA\',\'Amplified cDNA\',\'Ditag\',\'Concatemer - Insert\',\'Concatemer - Cloned\',\'DNA\',\'labeled cRNA\')','','YES','',20,'',300,'','','yes','no',''),(3402,'Additional information (not already provided)','RNA_DNA_Source','Description','Description','','',7,'Description','text','','YES','',20,'',300,'','','yes','no',''),(3403,'','RNA_DNA_Source','Submitted Amount','Submitted_Amount','Obsolete','',8,'Submitted_Amount','double(8,4)','','YES','',20,'',300,'','','yes','no',''),(3404,'','RNA_DNA_Source','Submitted Amount Units','Submitted_Amount_Units','Obsolete','',9,'Submitted_Amount_Units','enum(\'\',\'Cells\',\'Embryos\',\'Litters\',\'Organs\',\'mg\',\'ug\',\'ng\',\'pg\')','','YES','',20,'',300,'','','yes','no',''),(3405,'','RNA_DNA_Source','Storage Medium','Storage_Medium','','',10,'Storage_Medium','enum(\'\',\'RNALater\',\'Trizol\',\'Lysis Buffer\',\'Ethanol\',\'DEPC Water\',\'Qiazol\',\'TE 10:0.1\',\'TE 10:1\',\'RNAse-free Water\',\'Water\',\'EB Buffer\')','','YES','',20,'',300,'','','yes','no',''),(3406,'(use as required if source amounts tracked in non-volume units)','RNA_DNA_Source','Storage Medium Quantity','Storage_Medium_Quantity','','',11,'Storage_Medium_Quantity','double(8,4)','','YES','',20,'',300,'','','yes','no',''),(3407,'(use as required if source amounts tracked in non-volume units)','RNA_DNA_Source','Storage Medium Quantity Units','Storage_Medium_Quantity_Units','','',12,'storage_medium_quantity_units','enum(\'\',\'ml\',\'ul\')','','YES','',20,'',300,'','','yes','no',''),(3408,'','RNA_DNA_Source_Attribute','RNA DNA Source Attribute ID','RNA_DNA_Source_Attribute_ID','Primary','',1,'RNA_DNA_Source_Attribute_ID','int(11)','PRI','NO','',20,'',301,'','','yes','no',''),(3409,'','RNA_DNA_Source_Attribute','RNA_DNA_Source','FK_RNA_DNA_Source__ID','','',2,'FK_RNA_DNA_Source__ID','int(11)','MUL','NO','',20,'',301,'RNA_DNA_Source.RNA_DNA_Source_ID','','yes','no',''),(3410,'','RNA_DNA_Source_Attribute','Attribute','FK_Attribute__ID','','',3,'FK_Attribute__ID','int(11)','MUL','NO','',20,'',301,'Attribute.Attribute_ID','','yes','no',''),(3411,'','RNA_DNA_Source_Attribute','Attribute Value','Attribute_Value','','',4,'Attribute_Value','text','','NO','',20,'',301,'','','yes','no',''),(3412,'','RNA_DNA_Source_Attribute','Employee','FK_Employee__ID','','',5,'FK_Employee__ID','int(11)','','YES','',20,'',301,'Employee.Employee_ID','','yes','no',''),(3413,'','RNA_DNA_Source_Attribute','Set DateTime','Set_DateTime','','',6,'Set_DateTime','datetime','','NO','0000-00-00 00:00:00',20,'',301,'','','yes','no',''),(3414,'','SAGE_Library','RNA DNA Extraction','RNA_DNA_Extraction','','',7,'RNA_DNA_Extraction','text','','YES','',20,'',90,'','','yes','no',''),(3415,'','SAGE_Library','Starting RNA DNA Amnt ng','Starting_RNA_DNA_Amnt_ng','','',13,'Starting_RNA_DNA_Amnt_ng','float(10,3)','','YES','',20,'',90,'','','yes','no',''),(3416,'','SAGE_Library','Blue White Selection','Blue_White_Selection','Mandatory','',20,'Blue_White_Selection','enum(\'Yes\',\'No\')','','NO','No',20,'',90,'','','yes','no',''),(3417,'','Sequencing_Library','Source RNA DNA','Source_RNA_DNA','','',16,'Source_RNA_DNA','text','','YES','',20,'',143,'','','yes','no',''),(3418,'','Service_Contract','Service Contract Status','Service_Contract_Status','','',9,'Service_Contract_Status','enum(\'Pending\',\'Current\',\'Expired\',\'Invalid\')','','YES','Pending',20,'',76,'','','yes','no',''),(3419,'','Submission','To Group','FKTo_Grp__ID','Mandatory','',10,'FKTo_Grp__ID','int(11)','MUL','YES','',20,'',89,'Grp.Grp_ID','','yes','no',''),(3420,'','Submission','From Group','FKFrom_Grp__ID','Mandatory','',11,'FKFrom_Grp__ID','int(11)','','YES','',20,'',89,'Grp.Grp_ID','','yes','no',''),(3421,'','Submission','Table Name','Table_Name','','',12,'Table_Name','varchar(40)','','YES','',20,'^.{0,40}$',89,'','','yes','no',''),(3422,'','Submission','Key Value','Key_Value','','',13,'Key_Value','varchar(40)','','YES','',20,'^.{0,40}$',89,'','','yes','no',''),(3423,'','Transposon_Library','Blue White Selection','Blue_White_Selection','Mandatory','',5,'Blue_White_Selection','enum(\'Yes\',\'No\')','','NO','No',20,'',233,'','','yes','no',''),(3424,'','Vector','Vector Type','Vector_Type','','',14,'Vector_Type','enum(\'Plasmid\',\'Fosmid\',\'Cosmid\',\'BAC\',\'N/A\')','','YES','',20,'',81,'','','yes','no',''),(3425,'','Well_Lookup','Gel 121 Standard','Gel_121_Standard','','',4,'Gel_121_Standard','int(11)','','YES','',20,'',84,'','','yes','no',''),(3426,'','Well_Lookup','Gel 121 Custom','Gel_121_Custom','','',5,'Gel_121_Custom','int(11)','','YES','',20,'',84,'','','yes','no',''),(3427,'','Well_Lookup','Tube','Tube','','',6,'Tube','char(3)','','YES','',20,'',84,'','','yes','no',''),(3428,'','Work_Request','FK_Work_Request_Type__ID','FK_Work_Request_Type__ID','Obsolete','',12,'FK_Work_Request_Type__ID','int(11)','','YES','',20,'',234,'Work_Request_Type.Work_Request_Type_ID','','yes','no',''),(3429,'','Work_Request','Collection','FK_Library__Name','Searchable','',13,'FK_Library__Name','varchar(40)','','NO','',20,'',234,'Library.Library_Name','','yes','no',''),(3430,'','Work_Request_Type','Work Request Type ID','Work_Request_Type_ID','Primary','Work_Request_Type_Name',1,'Work_Request_Type_ID','int(11)','PRI','NO','',20,'',302,'','','yes','no',''),(3431,'','Work_Request_Type','Work Request Type Name','Work_Request_Type_Name','','',2,'Work_Request_Type_Name','varchar(100)','','NO','',20,'^.{0,100}$',302,'','','yes','no',''),(3432,'','Work_Request_Type','Work Request Type Description','Work_Request_Type_Description','','',3,'Work_Request_Type_Description','text','','YES','',20,'',302,'','','yes','no',''),(3433,'','Location','Location Status','Location_Status','','',3,'Location_Status','enum(\'active\',\'inactive\')','','NO','active',20,'',216,'','','yes','no',''),(3434,'','Plate','Last Prep','FKLast_Prep__ID','','',25,'FKLast_Prep__ID','int(11)','MUL','YES','',20,'',59,'Prep.Prep_ID','','no','no',''),(3435,'','Pipeline','FK_Pipeline_Group__ID','FK_Pipeline_Group__ID','','',7,'FK_Pipeline_Group__ID','int(11)','MUL','YES','',20,'',187,'Pipeline_Group.Pipeline_Group_ID','','yes','no',''),(3438,'','SolexaRun','Cycles','Cycles','','',5,'Cycles','int(11)','','YES','',20,'',288,'','','yes','no',''),(3439,'Grp monitoring this stock','Order_Notice','Monitoring Grp','Monitoring_Grp','Mandatory','',2,'FK_Grp__ID','int(11)','','YES','',20,'',54,'Grp.Grp_ID','','yes','yes',''),(3440,'','GelAnalysis','Swap Check','Swap_Check','','',7,'Swap_Check','enum(\'Passed\',\'Failed\',\'Pending\')','','NO','Pending',20,'',242,'','','yes','no',''),(3442,'','GelAnalysis','Validation Override','Validation_Override','','',9,'Validation_Override','enum(\'NO\',\'YES\')','','NO','NO',20,'',242,'','','yes','yes',''),(3443,'Submission ID (returned from submitter) - eg accession_id','Submission_Volume','SID','SID','','',4,'SID','varchar(40)','','YES','',15,'^.{0,40}$',197,'','','no','no',''),(3444,'','Barcode_Label','Barcode Label Status','Barcode_Label_Status','','',12,'Barcode_Label_Status','enum(\'Inactive\',\'Active\')','','NO','Active',20,'',2,'',NULL,'yes','no','Custom'),(3445,'','DBField','Field Scope','Field_Scope','','',21,'Field_Scope','enum(\'Core\',\'Optional\',\'Custom\')','','YES','Custom',20,'',107,'',NULL,'yes','no','Custom'),(3446,'','DBTable','Scope','Scope','','',8,'Scope','enum(\'Core\',\'Lab\',\'Genomic\',\'Option\',\'Plugin\',\'Sequencing\',\'Fingerprinting\',\'Microarray\')','','YES','',20,'',28,'',NULL,'yes','no','Custom'),(3447,'','DBTable','Package Name','Package_Name','','',9,'Package_Name','varchar(40)','','YES','',20,'^.{0,40}$',28,'',NULL,'yes','no','Custom'),(3448,'','DBTable','Records','Records','','',10,'Records','int(11)','','NO','',20,'',28,'',NULL,'yes','no','Custom'),(3449,'','Flowcell','Tray','FK_Tray__ID','','',5,'FK_Tray__ID','int(11)','MUL','YES','',20,'',291,'Tray.Tray_ID',NULL,'yes','no','Custom'),(3450,'','GelAnalysis','Self Check','Self_Check','','',9,'Self_Check','enum(\'Passed\',\'Failed\',\'Pending\')','','NO','Pending',20,'',242,'',NULL,'yes','no','Custom'),(3451,'','GelAnalysis','Cross Check','Cross_Check','','',10,'Cross_Check','enum(\'Passed\',\'Failed\',\'Pending\')','','NO','Pending',20,'',242,'',NULL,'yes','no','Custom'),(3452,'','GelRun','Equipment','FKAgarosePour_Equipment__ID','','',6,'FKAgarosePour_Equipment__ID','int(11)','','YES','',20,'',243,'Equipment.Equipment_ID',NULL,'yes','no','Custom'),(3453,'','Genetic_Code','Genetic Code ID','Genetic_Code_ID','Primary','Genetic_Code_Name',1,'Genetic_Code_ID','int(11)','PRI','NO','',20,'',303,'',NULL,'yes','no','Custom'),(3454,'','Genetic_Code','Genetic Code Abbr','Genetic_Code_Abbr','','',2,'Genetic_Code_Abbr','char(3)','','NO','',20,'',303,'',NULL,'yes','no','Custom'),(3455,'','Genetic_Code','Genetic Code Name','Genetic_Code_Name','','',3,'Genetic_Code_Name','varchar(80)','MUL','YES','',20,'^.{0,80}$',303,'',NULL,'yes','no','Custom'),(3456,'','Genetic_Code','CDE','CDE','','',4,'CDE','text','','YES','',20,'',303,'',NULL,'yes','no','Custom'),(3457,'','Genetic_Code','Starts','Starts','','',5,'Starts','text','','YES','',20,'',303,'',NULL,'yes','no','Custom'),(3458,'','Lab_Protocol','Max Tracking Size','Max_Tracking_Size','','',7,'Max_Tracking_Size','enum(\'384\',\'96\')','','YES','384',20,'',39,'',NULL,'yes','no','Custom'),(3459,'','Lab_Protocol','Repeatable','Repeatable','','',8,'Repeatable','enum(\'Yes\',\'No\')','','NO','Yes',20,'',39,'',NULL,'yes','no','Custom'),(3460,'','Library','Library Completion Date','Library_Completion_Date','','',23,'Library_Completion_Date','date','','YES','',20,'',40,'',NULL,'yes','no','Custom'),(3461,'','Library_Attribute','Library Attribute ID','Library_Attribute_ID','Primary','',1,'Library_Attribute_ID','int(11)','PRI','NO','',20,'',304,'',NULL,'yes','no','Custom'),(3462,'','Library_Attribute','Collection','FK_Library__Name','','',2,'FK_Library__Name','varchar(6)','MUL','YES','',20,'',304,'Library.Library_Name',NULL,'yes','no','Custom'),(3463,'','Library_Attribute','Attribute','FK_Attribute__ID','','',3,'FK_Attribute__ID','int(11)','MUL','NO','',20,'',304,'Attribute.Attribute_ID',NULL,'yes','no','Custom'),(3464,'','Library_Attribute','Attribute Value','Attribute_Value','','',4,'Attribute_Value','text','','NO','',20,'',304,'',NULL,'yes','no','Custom'),(3465,'','Library_Attribute','Employee','FK_Employee__ID','','',5,'FK_Employee__ID','int(11)','','YES','',20,'',304,'Employee.Employee_ID',NULL,'yes','no','Custom'),(3466,'','Library_Attribute','Set DateTime','Set_DateTime','','',6,'Set_DateTime','datetime','','NO','0000-00-00 00:00:00',20,'',304,'',NULL,'yes','no','Custom'),(3467,'','Maintenance_Schedule','Maintenance Schedule ID','Maintenance_Schedule_ID','Primary','',1,'Maintenance_Schedule_ID','int(11)','PRI','NO','',20,'',305,'',NULL,'yes','no','Custom'),(3468,'','Maintenance_Schedule','Maintenance_Process_Type','FK_Maintenance_Process_Type__ID','','',2,'FK_Maintenance_Process_Type__ID','int(11)','','NO','',20,'',305,'Maintenance_Process_Type.Maintenance_Process_Type_ID',NULL,'yes','no','Custom'),(3469,'','Maintenance_Schedule','Equipment','FK_Equipment__ID','','',3,'FK_Equipment__ID','int(11)','','YES','',20,'',305,'Equipment.Equipment_ID',NULL,'yes','no','Custom'),(3470,'','Maintenance_Schedule','Scheduled Equipment Type','Scheduled_Equipment_Type','','',4,'Scheduled_Equipment_Type','char(20)','','YES','',20,'',305,'',NULL,'yes','no','Custom'),(3471,'','Maintenance_Schedule','Scheduled Frequency','Scheduled_Frequency','','',5,'Scheduled_Frequency','int(11)','','YES','',20,'',305,'',NULL,'yes','no','Custom'),(3472,'','Maintenance_Schedule','Notice Frequency','Notice_Frequency','','',6,'Notice_Frequency','int(11)','','YES','7',20,'',305,'',NULL,'yes','no','Custom'),(3473,'','Maintenance_Schedule','Notice Sent','Notice_Sent','','',7,'Notice_Sent','date','','YES','',20,'',305,'',NULL,'yes','no','Custom'),(3474,'','Original_Source','FK_Taxonomy__ID','FK_Taxonomy__ID','','',22,'FK_Taxonomy__ID','int(11)','MUL','NO','',20,'',165,'Taxonomy.Taxonomy_ID',NULL,'yes','no','Custom'),(3475,'','Pipeline','Pipeline Status','Pipeline_Status','','',8,'Pipeline_Status','enum(\'Active\',\'Inactive\')','','YES','Active',20,'',187,'',NULL,'yes','no','Custom'),(3476,'','Pipeline_Group','Pipeline Group ID','Pipeline_Group_ID','Primary','Pipeline_Group_Name',1,'Pipeline_Group_ID','int(11)','PRI','NO','',20,'',306,'',NULL,'yes','no','Custom'),(3477,'','Pipeline_Group','Pipeline Group Name','Pipeline_Group_Name','','',2,'Pipeline_Group_Name','varchar(40)','','YES','',20,'^.{0,40}$',306,'',NULL,'yes','no','Custom'),(3478,'','Plate_Prep','Solution Quantity Units','Solution_Quantity_Units','','',8,'Solution_Quantity_Units','enum(\'pl\',\'nl\',\'ul\',\'ml\',\'l\')','','YES','',20,'',128,'',NULL,'yes','no','Custom'),(3479,'','Plate_Schedule','Plate Schedule ID','Plate_Schedule_ID','Primary','',1,'Plate_Schedule_ID','int(11)','PRI','NO','',20,'',307,'',NULL,'yes','no','Custom'),(3480,'','Plate_Schedule','Container','FK_Plate__ID','','',2,'FK_Plate__ID','int(11)','MUL','NO','',20,'',307,'Plate.Plate_ID',NULL,'yes','no','Custom'),(3481,'','Plate_Schedule','Pipeline','FK_Pipeline__ID','','',3,'FK_Pipeline__ID','int(11)','MUL','NO','',20,'',307,'Pipeline.Pipeline_ID',NULL,'yes','no','Custom'),(3482,'','Plate_Schedule','Plate Schedule Priority','Plate_Schedule_Priority','','',4,'Plate_Schedule_Priority','tinyint(4)','','NO','',20,'',307,'',NULL,'yes','no','Custom'),(3483,'','Primer_Customization','nt index','nt_index','','',7,'nt_index','int(11)','','YES','',20,'',97,'',NULL,'yes','no','Custom'),(3484,'','Primer_Plate_Well','Primer Plate Well Check','Primer_Plate_Well_Check','','',6,'Primer_Plate_Well_Check','enum(\'Passed\',\'Failed\')','','YES','',20,'',134,'',NULL,'yes','no','Custom'),(3485,'','Report','Report ID','Report_ID','Primary','',1,'Report_ID','int(11)','PRI','NO','',20,'',308,'',NULL,'yes','no','Custom'),(3486,'','Report','Parameter String','Parameter_String','','',2,'Parameter_String','text','','YES','',20,'',308,'',NULL,'yes','no','Custom'),(3487,'','Report','Target','Target','','',3,'Target','text','','YES','',20,'',308,'',NULL,'yes','no','Custom'),(3488,'','Report','Extract File','Extract_File','','',4,'Extract_File','text','','YES','',20,'',308,'',NULL,'yes','no','Custom'),(3489,'','Report','Report Frequency','Report_Frequency','','',5,'Report_Frequency','int(11)','','YES','',20,'',308,'',NULL,'yes','no','Custom'),(3490,'','Report','Report Sent','Report_Sent','','',6,'Report_Sent','datetime','','YES','',20,'',308,'',NULL,'yes','no','Custom'),(3491,'','Run','QC Status','QC_Status','','',14,'QC_Status','enum(\'N/A\',\'Pending\',\'Failed\',\'Re-Test\',\'Passed\')','','YES','N/A',20,'',251,'',NULL,'yes','no','Custom'),(3492,'','RunDataAnnotation','RunDataAnnotation ID','RunDataAnnotation_ID','Primary','',1,'RunDataAnnotation_ID','int(11)','PRI','NO','',20,'',309,'',NULL,'yes','no','Custom'),(3493,'','RunDataAnnotation','FK_RunDataAnnotation_Type__ID','FK_RunDataAnnotation_Type__ID','','',2,'FK_RunDataAnnotation_Type__ID','int(11)','MUL','NO','',20,'',309,'RunDataAnnotation_Type.RunDataAnnotation_Type_ID',NULL,'yes','no','Custom'),(3494,'','RunDataAnnotation','Value','Value','','',3,'Value','float','','NO','',20,'',309,'',NULL,'yes','no','Custom'),(3495,'','RunDataAnnotation','Employee','FK_Employee__ID','','',4,'FK_Employee__ID','int(11)','','NO','',20,'',309,'Employee.Employee_ID',NULL,'yes','no','Custom'),(3496,'','RunDataAnnotation','Date Time','Date_Time','','',5,'Date_Time','timestamp','','YES','CURRENT_TIMESTAMP',20,'',309,'',NULL,'yes','no','Custom'),(3497,'','RunDataAnnotation','Comments','Comments','','',6,'Comments','varchar(255)','','YES','',20,'^.{0,255}$',309,'',NULL,'yes','no','Custom'),(3498,'','RunDataAnnotation_Type','RunDataAnnotation Type ID','RunDataAnnotation_Type_ID','Primary','RunDataAnnotation_Type_Name',1,'RunDataAnnotation_Type_ID','int(11)','PRI','NO','',20,'',310,'',NULL,'yes','no','Custom'),(3499,'','RunDataAnnotation_Type','RunDataAnnotation Type Name','RunDataAnnotation_Type_Name','','',2,'RunDataAnnotation_Type_Name','varchar(30)','','NO','',20,'^.{0,30}$',310,'',NULL,'yes','no','Custom'),(3500,'','RunDataAnnotation_Type','RunDataAnnotation Type Description','RunDataAnnotation_Type_Description','','',3,'RunDataAnnotation_Type_Description','varchar(255)','','NO','',20,'^.{0,255}$',310,'',NULL,'yes','no','Custom'),(3501,'','RunDataReference','RunDataReference ID','RunDataReference_ID','Primary','',1,'RunDataReference_ID','int(11)','PRI','NO','',20,'',311,'',NULL,'yes','no','Custom'),(3502,'','RunDataReference','Run','FK_Run__ID','','',2,'FK_Run__ID','int(11)','MUL','NO','',20,'',311,'Run.Run_ID',NULL,'yes','no','Custom'),(3503,'','RunDataReference','Well','Well','','',3,'Well','char(3)','','NO','',20,'',311,'',NULL,'yes','no','Custom'),(3504,'','RunDataReference','RunDataAnnotation','FK_RunDataAnnotation__ID','','',4,'FK_RunDataAnnotation__ID','int(11)','','NO','',20,'',311,'RunDataAnnotation.RunDataAnnotation_ID',NULL,'yes','no','Custom'),(3505,'','SolexaAnalysis','SolexaAnalysis Type','SolexaAnalysis_Type','','',3,'SolexaAnalysis_Type','enum(\'eland\',\'default\')','','YES','default',20,'',289,'',NULL,'yes','no','Custom'),(3506,'','SolexaAnalysis','Phasing','Phasing','','',4,'Phasing','float','','YES','',20,'',289,'',NULL,'yes','no','Custom'),(3507,'','SolexaAnalysis','Prephasing','Prephasing','','',5,'Prephasing','float','','YES','',20,'',289,'',NULL,'yes','no','Custom'),(3508,'','SolexaAnalysis','Read Length','Read_Length','','',6,'Read_Length','smallint(6)','','YES','',20,'',289,'',NULL,'yes','no','Custom'),(3509,'','SolexaAnalysis','SolexaAnalysis Started','SolexaAnalysis_Started','','',7,'SolexaAnalysis_Started','datetime','','YES','',20,'',289,'',NULL,'yes','no','Custom'),(3510,'','SolexaAnalysis','SolexaAnalysis Finished','SolexaAnalysis_Finished','','',8,'SolexaAnalysis_Finished','datetime','','YES','',20,'',289,'',NULL,'yes','no','Custom'),(3511,'','SolexaAnalysis','Clusters','Clusters','','',9,'Clusters','int(11)','','YES','',20,'',289,'',NULL,'yes','no','Custom'),(3512,'','SolexaAnalysis','Error Rate Percentage','Error_Rate_Percentage','','',10,'Error_Rate_Percentage','float','','YES','',20,'',289,'',NULL,'yes','no','Custom'),(3513,'','SolexaAnalysis','Align Percentage','Align_Percentage','','',11,'Align_Percentage','float','','YES','',20,'',289,'',NULL,'yes','no','Custom'),(3514,'','SolexaAnalysis','Firecrest Dir','Firecrest_Dir','','',12,'Firecrest_Dir','varchar(50)','','YES','',20,'^.{0,50}$',289,'',NULL,'yes','no','Custom'),(3515,'','SolexaAnalysis','Bustard Dir','Bustard_Dir','','',13,'Bustard_Dir','varchar(50)','','YES','',20,'^.{0,50}$',289,'',NULL,'yes','no','Custom'),(3516,'','SolexaAnalysis','Gerald Dir','Gerald_Dir','','',14,'Gerald_Dir','varchar(50)','','YES','',20,'^.{0,50}$',289,'',NULL,'yes','no','Custom'),(3517,'','SolexaAnalysis','End Read Type','End_Read_Type','','',15,'End_Read_Type','enum(\'Single\',\'PET 1\',\'PET 2\')','','YES','',20,'',289,'',NULL,'yes','no','Custom'),(3518,'','SolexaAnalysis','Tiles Analyzed','Tiles_Analyzed','','',16,'Tiles_Analyzed','int(11)','','YES','',20,'',289,'',NULL,'yes','no','Custom'),(3519,'','SolexaRun','Files Status','Files_Status','','',6,'Files_Status','enum(\'Raw\',\'Deleting Images\',\'Images Deleted\',\'Ready for Storage\',\'Storing\',\'Stored\',\'Protected\',\'Delete/Move\')','','YES','Raw',20,'',288,'',NULL,'yes','no','Custom'),(3520,'','SolexaRun','QC Check','QC_Check','','',7,'QC_Check','enum(\'N/A\',\'Pending\',\'Failed\',\'Re-Test\',\'Passed\')','','YES','N/A',20,'',288,'',NULL,'yes','no','Custom'),(3521,'','SolexaRun','Protected','Protected','','',8,'Protected','enum(\'Yes\',\'No\')','','YES','No',20,'',288,'',NULL,'yes','no','Custom'),(3522,'','SolexaRun','Solexa Sample Type','Solexa_Sample_Type','','',9,'Solexa_Sample_Type','enum(\'Control\',\'SAGE\',\'miRNA\',\'TS\')','','YES','',20,'',288,'',NULL,'yes','no','Custom'),(3523,'','SolexaRun','SolexaRun Type','SolexaRun_Type','','',10,'SolexaRun_Type','enum(\'Single\',\'Paired\')','','NO','Single',20,'',288,'',NULL,'yes','no','Custom'),(3524,'','SolexaRun','SolexaRun Finished','SolexaRun_Finished','','',11,'SolexaRun_Finished','datetime','','YES','',20,'',288,'',NULL,'yes','no','Custom'),(3525,'','SolexaRun','Tiles','Tiles','','',12,'Tiles','smallint(6)','','YES','',20,'',288,'',NULL,'yes','no','Custom'),(3526,'','Standard_Solution','Prompt Units','Prompt_Units','','',10,'Prompt_Units','enum(\'\',\'pl\',\'ul\',\'ml\',\'l\')','','YES','',20,'',58,'',NULL,'yes','no','Custom'),(3527,'','Subscriber','Subscriber ID','Subscriber_ID','Primary','',1,'Subscriber_ID','int(11)','PRI','NO','',20,'',312,'',NULL,'yes','no','Custom'),(3528,'','Subscriber','FK_Subscription__ID','FK_Subscription__ID','','',2,'FK_Subscription__ID','int(11)','','NO','',20,'',312,'Subscription.Subscription_ID',NULL,'yes','no','Custom'),(3529,'','Subscriber','Subscriber Type','Subscriber_Type','','',3,'Subscriber_Type','enum(\'Employee\',\'Grp\',\'Contact\',\'ExternalEmail\')','','NO','Employee',20,'',312,'',NULL,'yes','no','Custom'),(3530,'','Subscriber','Employee','FK_Employee__ID','','',4,'FK_Employee__ID','int(11)','','YES','',20,'',312,'Employee.Employee_ID',NULL,'yes','no','Custom'),(3531,'','Subscriber','Grp','FK_Grp__ID','','',5,'FK_Grp__ID','int(11)','','YES','',20,'',312,'Grp.Grp_ID',NULL,'yes','no','Custom'),(3532,'','Subscriber','Contact','FK_Contact__ID','','',6,'FK_Contact__ID','int(11)','','YES','',20,'',312,'Contact.Contact_ID',NULL,'yes','no','Custom'),(3533,'','Subscriber','External Email','External_Email','','',7,'External_Email','varchar(255)','','YES','',20,'^.{0,255}$',312,'',NULL,'yes','no','Custom'),(3534,'','Subscription','Subscription ID','Subscription_ID','Primary','Subscription_Name',1,'Subscription_ID','int(11)','PRI','NO','',20,'',313,'',NULL,'yes','no','Custom'),(3535,'','Subscription','FK_Subscription_Event__ID','FK_Subscription_Event__ID','','',2,'FK_Subscription_Event__ID','int(11)','','NO','',20,'',313,'Subscription_Event.Subscription_Event_ID',NULL,'yes','no','Custom'),(3536,'','Subscription','Equipment','FK_Equipment__ID','','',3,'FK_Equipment__ID','int(11)','','YES','',20,'',313,'Equipment.Equipment_ID',NULL,'yes','no','Custom'),(3537,'','Subscription','Collection','FK_Library__Name','','',4,'FK_Library__Name','varchar(255)','','YES','',20,'',313,'Library.Library_Name',NULL,'yes','no','Custom'),(3538,'','Subscription','Project','FK_Project__ID','','',5,'FK_Project__ID','int(11)','','YES','',20,'',313,'Project.Project_ID',NULL,'yes','no','Custom'),(3539,'','Subscription','Grp','FK_Grp__ID','','',6,'FK_Grp__ID','int(11)','','YES','',20,'',313,'Grp.Grp_ID',NULL,'yes','no','Custom'),(3540,'','Subscription','Subscription Name','Subscription_Name','','',7,'Subscription_Name','varchar(255)','','YES','',20,'^.{0,255}$',313,'',NULL,'yes','no','Custom'),(3541,'','Subscription_Event','Subscription Event ID','Subscription_Event_ID','Primary','Subscription_Event_Name',1,'Subscription_Event_ID','int(11)','PRI','NO','',20,'',314,'',NULL,'yes','no','Custom'),(3542,'','Subscription_Event','Subscription Event Name','Subscription_Event_Name','','',2,'Subscription_Event_Name','varchar(50)','','NO','',20,'^.{0,50}$',314,'',NULL,'yes','no','Custom'),(3543,'','Subscription_Event','Subscription Event Type','Subscription_Event_Type','','',3,'Subscription_Event_Type','varchar(50)','','NO','',20,'^.{0,50}$',314,'',NULL,'yes','no','Custom'),(3544,'','Subscription_Event','Subscription Event Details','Subscription_Event_Details','','',4,'Subscription_Event_Details','varchar(255)','','NO','',20,'^.{0,255}$',314,'',NULL,'yes','no','Custom'),(3545,'','Table_Type','Table Type ID','Table_Type_ID','Primary','',1,'Table_Type_ID','int(11)','PRI','NO','',20,'',315,'',NULL,'yes','no','Custom'),(3546,'','Table_Type','Table Scope','Table_Scope','','',2,'Table_Scope','enum(\'Core\',\'Plugin\',\'Custom\')','','YES','',20,'',315,'',NULL,'yes','no','Custom'),(3547,'','Table_Type','Table Type','Table_Type','','',3,'Table_Type','enum(\'Object\',\'Detail\',\'Data\',\'Join\',\'Subclass\',\'Lookup\')','','YES','',20,'',315,'',NULL,'yes','no','Custom'),(3548,'','Table_Type','DBTable','FK_DBTable__ID','','',4,'FK_DBTable__ID','int(11)','','NO','',20,'',315,'DBTable.DBTable_ID',NULL,'yes','no','Custom'),(3549,'','Table_Type','Table Type Comment','Table_Type_Comment','','',5,'Table_Type_Comment','text','','YES','',20,'',315,'',NULL,'yes','no','Custom'),(3550,'','Taxonomy','Taxonomy ID','Taxonomy_ID','Primary','Taxonomy_Name',1,'Taxonomy_ID','int(11)','PRI','NO','',20,'',316,'',NULL,'yes','no','Custom'),(3551,'','Taxonomy','Taxonomy Name','Taxonomy_Name','','',2,'Taxonomy_Name','varchar(80)','MUL','NO','',20,'^.{0,80}$',316,'',NULL,'yes','no','Custom'),(3552,'','Taxonomy','Common Name','Common_Name','','',3,'Common_Name','varchar(80)','MUL','NO','',20,'^.{0,80}$',316,'',NULL,'yes','no','Custom'),(3553,'','Taxonomy_Division','Taxonomy Division ID','Taxonomy_Division_ID','Primary','Taxonomy_Division_Name',1,'Taxonomy_Division_ID','int(11)','PRI','NO','',20,'',317,'',NULL,'yes','no','Custom'),(3554,'','Taxonomy_Division','Taxonomy Division Code','Taxonomy_Division_Code','','',2,'Taxonomy_Division_Code','char(3)','MUL','NO','',20,'',317,'',NULL,'yes','no','Custom'),(3555,'','Taxonomy_Division','Taxonomy Division Name','Taxonomy_Division_Name','','',3,'Taxonomy_Division_Name','varchar(80)','','YES','',20,'^.{0,80}$',317,'',NULL,'yes','no','Custom'),(3556,'','Taxonomy_Division','Taxonomy Division Comments','Taxonomy_Division_Comments','','',4,'Taxonomy_Division_Comments','text','','YES','',20,'',317,'',NULL,'yes','no','Custom'),(3557,'','Taxonomy_Name','Taxonomy','FK_Taxonomy__ID','','',1,'FK_Taxonomy__ID','int(11)','','NO','',20,'',318,'Taxonomy.Taxonomy_ID',NULL,'yes','no','Custom'),(3558,'','Taxonomy_Name','NCBI Taxonomy Name','NCBI_Taxonomy_Name','','',2,'NCBI_Taxonomy_Name','varchar(80)','MUL','NO','',20,'^.{0,80}$',318,'',NULL,'yes','no','Custom'),(3559,'','Taxonomy_Name','Unique Taxonomy Name','Unique_Taxonomy_Name','','',3,'Unique_Taxonomy_Name','varchar(80)','MUL','YES','',20,'^.{0,80}$',318,'',NULL,'yes','no','Custom'),(3560,'','Taxonomy_Name','Taxonomy Name Class','Taxonomy_Name_Class','','',4,'Taxonomy_Name_Class','varchar(80)','','YES','',20,'^.{0,80}$',318,'',NULL,'yes','no','Custom'),(3561,'','Taxonomy_Node','Taxonomy','FK_Taxonomy__ID','','',1,'FK_Taxonomy__ID','int(11)','MUL','NO','',20,'',319,'Taxonomy.Taxonomy_ID',NULL,'yes','no','Custom'),(3562,'','Taxonomy_Node','Taxonomy','FKParent_Taxonomy__ID','','',2,'FKParent_Taxonomy__ID','int(11)','MUL','YES','',20,'',319,'Taxonomy.Taxonomy_ID',NULL,'yes','no','Custom'),(3563,'','Taxonomy_Node','Rank','Rank','','',3,'Rank','varchar(40)','','YES','',20,'^.{0,40}$',319,'',NULL,'yes','no','Custom'),(3564,'','Taxonomy_Node','embl code','embl_code','','',4,'embl_code','varchar(40)','','YES','',20,'^.{0,40}$',319,'',NULL,'yes','no','Custom'),(3565,'','Taxonomy_Node','Taxonomy_Division','FK_Taxonomy_Division__ID','','',5,'FK_Taxonomy_Division__ID','int(11)','','YES','',20,'',319,'Taxonomy_Division.Taxonomy_Division_ID',NULL,'yes','no','Custom'),(3566,'','Taxonomy_Node','Inherited Division','Inherited_Division','','',6,'Inherited_Division','tinyint(4)','','YES','',20,'',319,'',NULL,'yes','no','Custom'),(3567,'','Taxonomy_Node','Genetic_Code','FK_Genetic_Code__ID','','',7,'FK_Genetic_Code__ID','int(11)','MUL','YES','',20,'',319,'Genetic_Code.Genetic_Code_ID',NULL,'yes','no','Custom'),(3568,'','Taxonomy_Node','Inherited Genetic Code','Inherited_Genetic_Code','','',8,'Inherited_Genetic_Code','tinyint(4)','','YES','',20,'',319,'',NULL,'yes','no','Custom'),(3569,'','Taxonomy_Node','Genetic_Code','FKMitochondrial_Genetic_Code__ID','','',9,'FKMitochondrial_Genetic_Code__ID','int(11)','MUL','YES','',20,'',319,'Genetic_Code.Genetic_Code_ID',NULL,'yes','no','Custom'),(3570,'','Taxonomy_Node','Inherited Mitochondrial Genetic Code','Inherited_Mitochondrial_Genetic_Code','','',10,'Inherited_Mitochondrial_Genetic_Code','tinyint(4)','','YES','',20,'',319,'',NULL,'yes','no','Custom'),(3571,'','Taxonomy_Node','GenBank Hidden','GenBank_Hidden','','',11,'GenBank_Hidden','tinyint(4)','','YES','',20,'',319,'',NULL,'yes','no','Custom'),(3572,'','Taxonomy_Node','Hidden Subtree Root Flag','Hidden_Subtree_Root_Flag','','',12,'Hidden_Subtree_Root_Flag','tinyint(4)','','YES','',20,'',319,'',NULL,'yes','no','Custom'),(3573,'','Taxonomy_Node','Taxonomy Comments','Taxonomy_Comments','','',13,'Taxonomy_Comments','text','','YES','',20,'',319,'',NULL,'yes','no','Custom'),(3574,'','Template','Template ID','Template_ID','Primary','Template_Name',1,'Template_ID','int(11)','PRI','NO','',20,'',320,'',NULL,'yes','no','Custom'),(3575,'','Template','Template Name','Template_Name','','',2,'Template_Name','varchar(34)','UNI','NO','',20,'^.{0,34}$',320,'',NULL,'yes','no','Custom'),(3576,'','Template','Template Type','Template_Type','','',3,'Template_Type','enum(\'Submission\',\'Master\')','','NO','Submission',20,'',320,'',NULL,'yes','no','Custom'),(3577,'','Template','Template Description','Template_Description','','',4,'Template_Description','text','','YES','',20,'',320,'',NULL,'yes','no','Custom'),(3578,'','Template_Assignment','Template Assignment ID','Template_Assignment_ID','Primary','',1,'Template_Assignment_ID','int(11)','PRI','NO','',20,'',321,'',NULL,'yes','no','Custom'),(3579,'','Template_Assignment','Template','FK_Template__ID','','',2,'FK_Template__ID','int(11)','MUL','NO','',20,'',321,'Template.Template_ID',NULL,'yes','no','Custom'),(3580,'','Template_Assignment','Grp','FK_Grp__ID','','',3,'FK_Grp__ID','int(11)','MUL','NO','',20,'',321,'Grp.Grp_ID',NULL,'yes','no','Custom'),(3581,'','Template_Field','Template Field ID','Template_Field_ID','Primary','Template_Field_Name',1,'Template_Field_ID','int(11)','PRI','NO','',20,'',322,'',NULL,'yes','no','Custom'),(3582,'','Template_Field','Template Field Name','Template_Field_Name','','',2,'Template_Field_Name','varchar(80)','','NO','',20,'^.{0,80}$',322,'',NULL,'yes','no','Custom'),(3583,'','Template_Field','DBField','FK_DBField__ID','','',3,'FK_DBField__ID','int(11)','MUL','NO','',20,'',322,'DBField.DBField_ID',NULL,'yes','no','Custom'),(3584,'','Template_Field','Attribute','FK_Attribute__ID','','',4,'FK_Attribute__ID','int(11)','MUL','NO','',20,'',322,'Attribute.Attribute_ID',NULL,'yes','no','Custom'),(3585,'','Template_Field','Template Field Option','Template_Field_Option','','',5,'Template_Field_Option','set(\'Mandatory\',\'Unique\')','','YES','',20,'',322,'',NULL,'yes','no','Custom'),(3586,'','Template_Field','Template Field Format','Template_Field_Format','','',6,'Template_Field_Format','varchar(80)','','YES','',20,'^.{0,80}$',322,'',NULL,'yes','no','Custom'),(3587,'','Template_Field','Template','FK_Template__ID','','',7,'FK_Template__ID','int(11)','MUL','NO','',20,'',322,'Template.Template_ID',NULL,'yes','no','Custom'),(3588,'','Tray','Tray Label','Tray_Label','','',2,'Tray_Label','varchar(10)','','YES','',20,'^.{0,10}$',226,'',NULL,'yes','no','Custom'),(3589,'','Tube','Original Concentration','Original_Concentration','','',7,'Original_Concentration','float','','YES','',20,'',79,'',NULL,'yes','no','Custom'),(3590,'','Tube','Original Concentration Units','Original_Concentration_Units','','',8,'Original_Concentration_Units','enum(\'cfu\',\'ng/ul\',\'ug/ul\',\'nM\',\'pM\')','','YES','',20,'',79,'',NULL,'yes','no','Custom'),(3591,'','Work_Request','Goal Target Type','Goal_Target_Type','','',14,'Goal_Target_Type','enum(\'Add to Original Target\',\'Included in Original Target\')','','YES','',20,'',234,'',NULL,'yes','no','Custom'),(3592,'','junk','Library Name','Library_Name','','CASE WHEN LENGTH(Library_FullName) > 0 THEN Library_Name ELSE concat(Library_Name,\':\',Library_FullName) END',1,'Library_Name','varchar(40)','','NO','',20,'^.{0,40}$',323,'',NULL,'yes','no','Custom'),(3593,'','junk','comp','comp','','',2,'comp','datetime','','YES','',20,'',323,'',NULL,'yes','no','Custom'),(3594,'','org_tax_origin','organism','organism','','',1,'organism','int(11)','','YES','',20,'',324,'',NULL,'yes','no','Custom'),(3595,'','org_tax_origin','taxonomy','taxonomy','','',2,'taxonomy','int(11)','','YES','',20,'',324,'',NULL,'yes','no','Custom'),(3596,'','org_tax_origin','original source','original_source','','',3,'original_source','int(11)','','YES','',20,'',324,'',NULL,'yes','no','Custom'),(3597,'','temp_tax','Tax ID','Tax_ID','','',1,'Tax_ID','int(11)','','NO','',20,'',325,'',NULL,'yes','no','Custom'),(3598,'','temp_tax','Organism','Organism','','',2,'Organism','varchar(255)','','YES','',20,'^.{0,255}$',325,'',NULL,'yes','no','Custom'),(3599,'','','Stock ID','Stock_ID','Primary','concat(Stock_ID,\': \',Stock_Name)',1,'Stock_ID','int(11)','','NO','',20,NULL,326,'',NULL,'yes','no','Custom'),(3600,'','','Stock Name','Stock_Name','','',2,'Stock_Name','varchar(80)','','YES','',20,NULL,326,'',NULL,'yes','no','Custom'),(3601,'','','Employee','FK_Employee__ID','','',3,'FK_Employee__ID','int(11)','','YES','',20,NULL,326,'Employee.Employee_ID',NULL,'yes','no','Custom'),(3602,'','','Stock Lot Number','Stock_Lot_Number','','',4,'Stock_Lot_Number','varchar(80)','','YES','',20,NULL,326,'',NULL,'yes','no','Custom'),(3603,'','','Stock Received','Stock_Received','','',5,'Stock_Received','date','','YES','',20,NULL,326,'',NULL,'yes','no','Custom'),(3604,'','','Stock Size','Stock_Size','','',6,'Stock_Size','float','','YES','',20,NULL,326,'',NULL,'yes','no','Custom'),(3605,'','','Stock Size Units','Stock_Size_Units','','',7,'Stock_Size_Units','enum(\'mL\',\'uL\',\'litres\',\'mg\',\'grams\',\'kg\',\'pcs\',\'boxes\',\'tubes\',\'rxns\',\'n/a\')','','YES','',20,NULL,326,'',NULL,'yes','no','Custom'),(3606,'','','Stock Description','Stock_Description','','',8,'Stock_Description','text','','YES','',20,NULL,326,'',NULL,'yes','no','Custom'),(3607,'','','Orders','FK_Orders__ID','','',9,'FK_Orders__ID','int(11)','','YES','',20,NULL,326,'Orders.Orders_ID',NULL,'yes','no','Custom'),(3608,'','','Stock Type','Stock_Type','','',10,'Stock_Type','enum(\'Solution\',\'Reagent\',\'Kit\',\'Box\',\'Microarray\',\'Equipment\',\'Service_Contract\',\'Computer_Equip\',\'Misc_Item\',\'Matrix\',\'Primer\',\'Buffer\')','','YES','',20,NULL,326,'',NULL,'yes','no','Custom'),(3609,'','','Box','FK_Box__ID','','',11,'FK_Box__ID','int(11)','','YES','',20,NULL,326,'Box.Box_ID',NULL,'yes','no','Custom'),(3610,'','','Stock Catalog Number','Stock_Catalog_Number','','',12,'Stock_Catalog_Number','varchar(80)','','YES','',20,NULL,326,'',NULL,'yes','no','Custom'),(3611,'','','Stock Number in Batch','Stock_Number_in_Batch','','',13,'Stock_Number_in_Batch','int(11)','','YES','',20,NULL,326,'',NULL,'yes','no','Custom'),(3612,'','','Stock Cost','Stock_Cost','','',14,'Stock_Cost','float','','YES','',20,NULL,326,'',NULL,'yes','no','Custom'),(3613,'','','Organization','FK_Organization__ID','','',15,'FK_Organization__ID','int(11)','','YES','',20,NULL,326,'Organization.Organization_ID',NULL,'yes','no','Custom'),(3614,'','','Stock Source','Stock_Source','','',16,'Stock_Source','enum(\'Box\',\'Order\',\'Sample\',\'Made in House\')','','YES','',20,NULL,326,'',NULL,'yes','no','Custom'),(3615,'','','Grp','FK_Grp__ID','','',17,'FK_Grp__ID','int(11)','','NO','',20,NULL,326,'Grp.Grp_ID',NULL,'yes','no','Custom'),(3616,'','','Barcode_Label','FK_Barcode_Label__ID','','',18,'FK_Barcode_Label__ID','int(11)','','YES','',20,NULL,326,'Barcode_Label.Barcode_Label_ID',NULL,'yes','no','Custom'),(3617,'','','Identifier Number','Identifier_Number','','',19,'Identifier_Number','varchar(80)','','YES','',20,NULL,326,'',NULL,'yes','no','Custom'),(3618,'','','Identifier Number Type','Identifier_Number_Type','','',20,'Identifier_Number_Type','enum(\'Component Number\',\'Reference ID\')','','YES','',20,NULL,326,'',NULL,'yes','no','Custom'),(3619,'','','Purchase Order','Purchase_Order','','',21,'Purchase_Order','varchar(20)','','YES','',20,NULL,326,'',NULL,'yes','no','Custom'),(3620,'','','FK_Stock_Catalog__ID','FK_Stock_Catalog__ID','','',22,'FK_Stock_Catalog__ID','int(11)','','NO','',20,NULL,326,'Stock_Catalog.Stock_Catalog_ID',NULL,'yes','no','Custom'),(3621,'','','FK_Sample_Type__ID','FK_Sample_Type__ID','','',26,'FK_Sample_Type__ID','int(11)','','NO','',20,NULL,59,'Sample_Type.Sample_Type_ID',NULL,'yes','no','Custom'),(3622,'','','Container','FKOriginal_Plate__ID','','',7,'FKOriginal_Plate__ID','int(11)','','NO','',20,NULL,142,'Plate.Plate_ID',NULL,'yes','no','Custom'),(3623,'','','Original Well','Original_Well','','',8,'Original_Well','char(3)','','YES','',20,NULL,142,'',NULL,'yes','no','Custom'),(3624,'','','Collection','FK_Library__Name','','',9,'FK_Library__Name','varchar(8)','','YES','',20,NULL,142,'Library.Library_Name',NULL,'yes','no','Custom'),(3625,'','','Plate Number','Plate_Number','','',10,'Plate_Number','int(11)','','YES','',20,NULL,142,'',NULL,'yes','no','Custom'),(3626,'','','FK_Sample_Type__ID','FK_Sample_Type__ID','','',11,'FK_Sample_Type__ID','int(11)','','NO','',20,NULL,142,'Sample_Type.Sample_Type_ID',NULL,'yes','no','Custom'),(3627,'','','Sample Source','Sample_Source','','',12,'Sample_Source','enum(\'Original\',\'Extraction\',\'Clone\')','','YES','',20,NULL,142,'',NULL,'yes','no','Custom'),(3628,'','','Sample Type ID','Sample_Type_ID','Primary','',1,'Sample_Type_ID','int(11)','','NO','',20,NULL,327,'',NULL,'yes','no','Custom'),(3629,'','','Sample Type','Sample_Type','','',2,'Sample_Type','varchar(40)','','YES','',20,NULL,327,'',NULL,'yes','no','Custom'),(3630,'','','FK_Stock_Catalog__ID','FK_Stock_Catalog__ID','','',22,'FK_Stock_Catalog__ID','int(11)','','NO','',20,NULL,7,'Stock_Catalog.Stock_Catalog_ID',NULL,'yes','no','Custom'),(3631,'','','Stock Notes','Stock_Notes','','',23,'Stock_Notes','text','','YES','',20,NULL,7,'',NULL,'yes','no','Custom'),(3632,'','','Stock Catalog ID','Stock_Catalog_ID','Primary','',1,'Stock_Catalog_ID','int(11)','','NO','',20,NULL,328,'',NULL,'yes','no','Custom'),(3633,'','','Stock Catalog Name','Stock_Catalog_Name','','',2,'Stock_Catalog_Name','varchar(80)','','NO','',20,NULL,328,'',NULL,'yes','no','Custom'),(3634,'','','Stock Catalog Description','Stock_Catalog_Description','','',3,'Stock_Catalog_Description','text','','YES','',20,NULL,328,'',NULL,'yes','no','Custom'),(3635,'','','Stock Catalog Number','Stock_Catalog_Number','','',4,'Stock_Catalog_Number','varchar(80)','','YES','',20,NULL,328,'',NULL,'yes','no','Custom'),(3636,'','','Stock Type','Stock_Type','','',5,'Stock_Type','enum(\'Solution\',\'Reagent\',\'Kit\',\'Box\',\'Microarray\',\'Equipment\',\'Service_Contract\',\'Computer_Equip\',\'Misc_Item\',\'Matrix\',\'Primer\',\'Buffer\')','','YES','',20,NULL,328,'',NULL,'yes','no','Custom'),(3637,'','','Stock Source','Stock_Source','','',6,'Stock_Source','enum(\'Box\',\'Order\',\'Sample\',\'Made in House\')','','YES','',20,NULL,328,'',NULL,'yes','no','Custom'),(3638,'','','Stock Size','Stock_Size','','',7,'Stock_Size','float','','YES','',20,NULL,328,'',NULL,'yes','no','Custom'),(3639,'','','Stock Size Units','Stock_Size_Units','','',8,'Stock_Size_Units','enum(\'mL\',\'uL\',\'litres\',\'mg\',\'grams\',\'kg\',\'pcs\',\'boxes\',\'tubes\',\'rxns\',\'n/a\')','','YES','',20,NULL,328,'',NULL,'yes','no','Custom'),(3640,'','','Organization','FK_Organization__ID','','',9,'FK_Organization__ID','int(11)','','YES','',20,NULL,328,'Organization.Organization_ID',NULL,'yes','no','Custom'),(3641,'','','Barcode_Label','FK_Barcode_Label__ID','','',10,'FK_Barcode_Label__ID','int(11)','','YES','',20,NULL,328,'Barcode_Label.Barcode_Label_ID',NULL,'yes','no','Custom');
UNLOCK TABLES;
/*!40000 ALTER TABLE `DBField` ENABLE KEYS */;

--
-- Table structure for table `DBTable`
--

DROP TABLE IF EXISTS `DBTable`;
CREATE TABLE `DBTable` (
  `DBTable_ID` int(11) NOT NULL auto_increment,
  `DBTable_Name` varchar(80) NOT NULL default '',
  `DBTable_Description` text,
  `DBTable_Status` text,
  `Status_Last_Updated` datetime NOT NULL default '0000-00-00 00:00:00',
  `DBTable_Type` enum('General','Lab Object','Lab Process','Object Detail','Settings','Dynamic','DB Management','Application Specific','Class','Subclass','Lookup','Join','Imported') default NULL,
  `DBTable_Title` varchar(80) NOT NULL default '',
  `Scope` enum('Core','Lab','Genomic','Option','Plugin','Sequencing','Fingerprinting','Microarray') default NULL,
  `Package_Name` varchar(40) default NULL,
  `Records` int(11) NOT NULL default '0',
  PRIMARY KEY  (`DBTable_ID`),
  UNIQUE KEY `DBTable_Name` (`DBTable_Name`),
  UNIQUE KEY `name` (`DBTable_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `DBTable`
--


/*!40000 ALTER TABLE `DBTable` DISABLE KEYS */;
LOCK TABLES `DBTable` WRITE;
INSERT INTO `DBTable` VALUES (1,'Account','Accounts used for purchasing/ordering','Missing values from the Account Type column - perhaps changed to enum','2002-11-20 15:09:00','General','Account','Option','',22),(2,'Barcode_Label','Barcode formats used for the scanners','OK','2002-11-20 15:09:00','General','Barcode_Label','Core','',31),(3,'Box','Boxes received in the lab','Some boxes have no data at all (box 9 and 10); Some boxes do not have a corresponding box type even only Kit and Supplies are the only enums; also dates for Box_Opened are questionable','2002-11-20 15:09:00','Lab Object','Box','Lab','',5353),(4,'Chemistry_Code','Chemistry used for the sequencers','Chemistry_Description not nullable yet a lot of chemistry code have blank description; Terminator and Dye fields have values not belonged to the enum list','2002-11-20 15:09:00','General','Chemistry_Code','Lab','',112),(5,'Solution','Individual solutions used in the lab','There are solutions with Quantity_Used filled in but without Solution_Quantity;  Also there are solutions that have no solution type; when linked with the Stock table, there are a solutions that belongs to different solution_type for the same stock_name - currently Jeff/George are taking a look at the list to see how it can be cleaned up.;Also whether there should be Solution that does not belong to any Stock.','2002-11-20 15:09:00','Lab Object','Solution','Lab','',89871),(6,'Solution_Info','Extra information for solutions used in the lab','The idea of this table is many Solution can share the same Solution_Info.  However, there are a lot of records in the Solution_Info table that have the exact same nMoles, ODs and micrograms, causing redundant information.  The combination of these 3 fields should be unique','2002-11-20 15:09:00','Object Detail','Solution_Info','Lab','',10129),(7,'Stock','Stock item in the lab','There are a lot of entries having NO Stock_Catalog_Number even though their Stock_Source is not Made In House;Also currently there are a lot of entries with the same Stock_Catalog_Number but having different Stock_Name;Lots of entries have slightly different Stock_Name which can be propably be amalgamated - Jeff/George are currently going over the list.','2002-11-20 15:09:00','Lab Object','Stock','Lab','',49782),(11,'Pool','A pool of clones','Contains both FK_Transposon__Name and FK_Transposon__ID fields - this is redundant. All we need is the FK_Transponson__ID which can link us to the Transposon table via Transposon.Transposon_ID','2002-11-20 16:13:44','Lab Process','Pool','Lab','',689),(12,'Transposon','Transposons','Currently only contains one record','2002-11-20 16:33:46','Lab Object','Transposon','Genomic','',2),(15,'Clone_Sequence','Stores the actual sequences along with other statistics and comments/notes','Finished cleaning up the Clone_Sequence_Comments field;Next step is to get rid of the FK_Note__ID field','2002-11-27 10:15:34','Application Specific','Clone_Sequence','Option','',10578150),(17,'Collaboration','GSC collaborations','Currently only 1 record. Need to fill in the missing data','2002-11-20 17:32:15','Join','Collaboration','Core','',162),(18,'Communication','Communications/messages between GSC staff and another contact','Only few records now - whether table is really used at all','2002-11-20 17:36:06','General','Communication','Core','',4),(21,'ConcentrationRun','Correlates the plate ID and equipment ID for the concentration information of the individual wells from the Concentraions table','1 record has empty value for CalibrationFunction - probably should be set to n/a as well','2002-11-21 11:31:00','Application Specific','ConcentrationRun','Plugin','',433),(23,'Concentrations','Concentration of the wells','Currently the Units field is a varchar - probably should make it into an enum','2002-11-21 11:36:31','General','Concentrations','Plugin','',39306),(24,'Contact','Contacts for GSC','There are records that contain no Contact_Name - perhaps this is because the organization itself is the contact - still maybe better to make the Contact_Name field non-nullable; Also there is a contact called nobody - what is this for; There are multiple records that contain the same contact name and if fact they are the same person - the difference is they belong to a different organzation - this could cause data inconsistency and duplicate data - It will be better to create a new table called Person that actually stores the personal info like name, personal phone, personal email, personal address, etc and hence link the Contact table to the Person table via a FK_Person__ID - this will also help to remove various other personal related fields from the Contact table; There are also various fields related to the workplae info like Work_Address, Work_City etc - perhaps this can be removed as well since we already have a link to the Organization table via FK_Organization__ID;','2002-11-21 11:52:40','General','Contact','Core','',545),(25,'Contaminant','Contaminants found in wells during sequence runs','OK','2002-11-21 12:44:29','Lab Object','Contaminant','Genomic','',1985551),(26,'Contamination','Contaminations that could be found during sequence runs','Are the only 2 records in the table the same thing','2002-11-21 13:01:44','Application Specific','Contamination','Genomic','',3),(27,'Cross_Match','Stores the results of the vector screening of sequences based on the Cross_Match program','OK','2002-11-21 13:37:08','Application Specific','Cross_Match','Option','',6536944),(28,'DBTable','Descriptions and status of all tables in the current database','OK','2002-11-21 13:39:27','DB Management','DBTable','Core','',262),(29,'Dye_Chemistry','Various information of dyes used for sequencing','This table will probably be removed after the new addition of the sample sheet tables like SS_Config and SS_Option','2002-11-21 13:44:24','Lookup','Dye_Chemistry','Lab','',4),(30,'Employee','GSC employees - users of the alDente system','Other than some info like positions are outdated/inaccurate, in general the table is fine','2002-11-21 13:55:52','General','Employee','Core','',234),(31,'Equipment','Equipments in the lab','There are equipments that have the same Serial_Number but have different Equipment_Name - in some cases this is because of having different equipment number but this info is already in the Equipment_Number field and so should not appear in Equipment_Name - worth to look into; Also there are equipments that have no FK_Stock__ID - ok or not','2002-11-21 14:11:18','General','Equipment','Core','',1944),(32,'Error_Check','Error checking criteria for database fields','Not understand how this table is used;There are records in the table that are not even referencing a table from the database or are some testing data;Also most records are for the seqtest database - wonder whether this is an obsolete table','2002-11-21 14:22:20','DB Management','Error_Check','Core','',57),(36,'Funding','Fundings for GSC','Seems like the data is not up-to-date/a lot of funding missing','2002-11-21 14:41:28','General','Funding','Core','',166),(37,'Gel','Gel run for plates','Data looks pretty incomplete','2002-11-21 14:49:31','General','Gel','Option','',425),(39,'Lab_Protocol','Protocols created by lab administrators to be used in the lab','There are few protocols that links to FK_Employee__ID of zero - since there is no such employees this should be fixed','2002-11-21 15:53:37','Lab Process','Lab_Protocol','Lab','',338),(40,'Library','Information about a proposed collection/library.','There are libraries that do not have Library_Source_Name - whether it is a good idea to make this a required field; Also no records has a FK_Vector__ID - they all link to the Vector table via FK_Vector__Name - hence probably can remove the FK_Vector__ID field','2002-11-21 16:25:34','General','Collection','Lab','',4289),(41,'LibraryPrimer','Assign a primer to a library. Once done adding primers, click skip to go to the next form.','There are records that contain no FK_Library__Name - should look into it','2002-11-21 16:33:52','Join','LibraryPrimer','Option','',1361),(42,'LibraryProgress','Progess/status of libraries','Looks like this table is not updated often - in fact the only progress in the table is Created;Need to determine whether this table will be continued to be used and if so probably so frequently track the progress - perhaps should create a new field that is a enum of different progresses and use the existing LibraryProgress_Comments field to store extra detail info','2002-11-21 16:39:23','General','LibraryProgress','Lab','',43),(43,'Machine_Default','Stores default machine configurations for the sequencers','With the new addition of the sample sheet tables like SS_Config and SS_Option, many fields in this table can be dropped; Also the information from other fields are stored in the Sequence_Batch table at the sequence batch level - Need to determine whether these fields can be removed from Machine_Default as well','2002-11-21 16:46:13','General','Machine_Default','Sequencing','',24),(44,'Maintenance','Historical record for maintenance performed on machines','There are records with no Maintenance_Process - probably this should be a required field and perhaps even worth to make this an enum field','2002-11-21 17:01:06','Lab Process','Maintenance','Lab','',6493),(45,'Maintenance_Protocol','Detail steps for regular machine maintenance/services from the Service table','There are currently no records in this table, and in fact there are only 2 records in the Service table - Need to determine whether these tables are obsolete and if not then need to encourage users to use them','2002-11-21 17:19:57','Lab Process','Maintenance_Protocol','Lab','',0),(46,'Message','Messages','Seems like an obsolete table that no one is using anymore','2002-11-21 17:35:25','Lookup','Message','Core','',863),(47,'Misc_Item','Miscellaneous lab items','Contains no data','2002-11-21 17:42:51','Lab Object','Misc_Item','Lab','',0),(48,'Mixture','Mixtures made from solutions','The older records do not have data for Units_Used - should backfill these data and make the Units_Used field not nullable','2002-11-21 17:47:36','General','Mixture','Lab','',107824),(49,'MultiPlate_Run','Multiplate sequence runs','OK','2002-11-22 09:28:48','General','MultiPlate_Run','Sequencing','',35755),(50,'Multiple_Barcode','Correlates a MUL barcode to the individual PLAs','There are some MULs that only contains a single PLA','2002-11-22 09:32:53','General','Multiple_Barcode','Option','',0),(51,'Note','Notes from sequence runs','Probably better to make the field Note_Type to be enum; Probably the table will be dropped','2002-11-22 09:37:04','General','Note','Option','',7),(52,'Notice','Notice sent to users during sequence runs','Target_List has missing and inconsistent data; also no new data in a while','2002-11-22 09:41:21','General','Notice','Option','',1509),(53,'Optical_Density','Optical Density and concentration measurements for wells','None of the records have any data for 260nm_Corrected, 280nm_Corrected and Density','2002-11-22 09:50:04','Object Detail','Optical_Density','Option','',29112),(54,'Order_Notice','Notice sent to users when supply is low and may need to order','No new data for a while','2002-11-22 09:53:29','General','Order_Notice','Core','',8),(55,'Orders','Orders of items','Currently not being used - need to integrate this part of alDente with the Excel system currently used; Also might be worthwhile to create a separate Item table to store some of the detail info of an item to get rid of redundant data and data inconsistency - in this case the Orders table will link to the Item table via FK_Item__ID','2002-11-22 10:03:23','General','Orders','Option','',103),(56,'Organization','Organizations that GSC deals with','In the process of removing redundant/outdated organizations','2002-11-27 10:10:34','General','Organization','Core','',254),(57,'Parameter','Parameters for the standard solution chemistry calculator','There are a few records that are missing Standard_Solution_ID and/or Parameter_Type - look into it','2002-11-22 10:27:47','Settings','Parameter','Core','',1077),(58,'Standard_Solution','Contains the formula for the chemistry calulator for those solutions that are used often in the lab','OK','2002-11-22 10:29:10','General','Standard_Solution','Lab','',218),(59,'Plate','Plates','There are plates that have no FK_Rack__ID - need to clean these up','2002-11-22 10:38:47','Lab Object','Container','Lab','',216571),(60,'Plate_Format','Various plate formats of the plates','OK','2002-11-22 10:40:34','Object Detail','Plate_Format','Lab','',60),(61,'Plate_Set','Correlates a plate set number to its individual plates','OK','2002-11-22 10:45:26','Lab Object','Plate_Set','Lab','',321623),(62,'Plate_Tube','Junction table between plates and tubes','Currently contains no records','2002-11-22 10:48:35','General','Plate_Tube','Lab','',0),(64,'Primer','Primer Types','Most of the primer sequences are in lower cases except for a few - wonder whether should make it consistent','2002-11-22 11:20:38','General','Primer','Option','',314664),(65,'Primer_Info','Extra information for Primers','OK','2002-11-22 11:32:00','Application Specific','Primer_Info','Option','',103),(66,'Project','GSC projects','Project 20 has no Project_Type; Also a lot of projects are missing FK_Funding__ID','2002-11-22 11:36:06','General','Project','Core','',283),(67,'Protocol_Step','Individual steps of lab protocols','OK','2002-11-22 11:41:15','General','Protocol_Step','Lab','',2530),(68,'Protocol_Tracking','Lab protocol steps to be tracked when performed','OK','2002-11-22 11:50:42','General','Protocol_Tracking','Lab','',6),(69,'Rack','Racks for storing plates','OK','2002-11-22 11:53:08','Lab Object','Rack','Lab','',39885),(70,'ReArray','Information about rearrays, including source and target plates/wells and other info','OK','2002-11-22 12:00:07','Lab Process','ReArray','Lab','',1280774),(71,'Restriction_Site','Restriction sites and their sequences','OK','2002-11-22 12:02:14','General','Restriction_Site','Genomic','',24),(72,'SS_Config','Sample sheet configurations for the sequencers','OK','2002-11-22 12:43:52','Application Specific','SS_Config','Lab','',94),(73,'SS_Option','Option values for sample sheet configurations for the sequencers','OK','2002-11-22 12:44:41','Application Specific','SS_Option','Lab','',61),(74,'Sequencer_Type','Different types of sequencers along with some of their parameters','OK','2002-11-22 12:47:22','Application Specific','Sequencer_Type','Sequencing','',4),(75,'Service','Regular maintenance/service for the lab equipments','Currently only 2 records in the table','2002-11-22 12:49:32','General','Service','Option','',2),(76,'Service_Contract','Service contracts for lab equipments','Currently contains no records','2002-11-22 12:51:23','General','Service_Contract','Option','',0),(78,'Suggestion','Suggestions for improving the alDente system','Not sure how FK_Employee__ID and FK_Person__ID works','2002-11-22 13:16:15','Lookup','Suggestion','Core','',13),(79,'Tube','Tubes containing DNA/RNA/Tissue, DNA ligation tubes or agar plates prior to colony picking, etc','Currently contains no records','2002-11-22 13:21:43','Lab Object','Tube','Lab','',29585),(80,'Tube_Application','Junction table between tubes and solutions','Currently contains no records','2002-11-22 13:24:43','Lab Process','Tube_Application','Lab','',0),(81,'Vector','Info about the vectors','Vector 81 and 82 contains no Vector_Name; Not sure how Vector_Manufacturer is different than Vector_Sequence_Source - perhaps should link to FK_Organization__ID rather than specifying the names directly','2002-11-22 13:30:56','Lab Object','Vector','Genomic','',521),(82,'VectorPrimer','Primers for the vectors','Record 84 contains no FK_Vector__Name','2002-11-22 13:33:45','Lab Object','VectorPrimer','Genomic','',251),(83,'Warranty','Warranties for the equipments','Currently contains no records','2002-11-22 13:36:07','General','Warranty','Option','',1),(84,'Well_Lookup','Maps well positions between 384-wells plate and 96-wells plate','OK','2002-11-22 13:39:37','General','Well_Lookup','Lab','',384),(86,'Microtiter','','','0000-00-00 00:00:00','Application Specific','Microtiter','Option','',534),(87,'Ligation','','','0000-00-00 00:00:00','Application Specific','Ligation','Option','',1848),(88,'Xformed_Cells','','','0000-00-00 00:00:00','Application Specific','X-Formed Cells','Option','',271),(89,'Submission','','','0000-00-00 00:00:00','General','Submission','Option','',2870),(90,'SAGE_Library','Detailed information about a SAGE library.','','0000-00-00 00:00:00','Application Specific','SAGE_Library','Plugin','',622),(91,'cDNA_Library','Detailed information about cDNA libraries','','0000-00-00 00:00:00','Application Specific','cDNA_Library','Option','',415),(92,'Genomic_Library','Detailed information about genomic libraries.','','0000-00-00 00:00:00','Application Specific','Genomic_Library','Plugin','',306),(93,'PCR_Library','Detailed information about PCR libraries. ','','0000-00-00 00:00:00','Application Specific','PCR_Library','Plugin','',118),(94,'Issue','','','0000-00-00 00:00:00','General','Issue','Option','',3353),(95,'TraceData','','','0000-00-00 00:00:00','General','TraceData','Plugin','',16259),(97,'Primer_Customization','Customization info for Primers','','0000-00-00 00:00:00','Object Detail','Primer_Customization','Option','',306473),(98,'Primer_Order','','','0000-00-00 00:00:00','General','Primer_Order','Option','',0),(99,'Setting','','','0000-00-00 00:00:00','Lookup','Setting','Core','',8),(100,'EmployeeSetting','','','0000-00-00 00:00:00','Join','EmployeeSetting','Core','',18),(102,'Clone_Alias','','','0000-00-00 00:00:00','Object Detail','Clone_Alias','Option','',49680),(103,'Clone_Details','','','0000-00-00 00:00:00','Object Detail','Clone_Details','Lab','',88852),(105,'Clone_Sample','','','0000-00-00 00:00:00','General','Clone_Sample','Lab','',13091359),(106,'Clone_Source','','','0000-00-00 00:00:00','General','Clone_Source','Option','',37511),(107,'DBField','','','0000-00-00 00:00:00','DB Management','DBField','Core','',2093),(108,'DB_Form','','','0000-00-00 00:00:00','DB Management','DB_Form','Core','',60),(109,'Department','','','0000-00-00 00:00:00','General','Department','Core','',9),(110,'Enzyme','','','0000-00-00 00:00:00','Lookup','Enzyme','Lab','',50),(111,'Funding_Applicant','','','0000-00-00 00:00:00','General','Funding_Applicant','Option','',0),(112,'Funding_Distribution','','','0000-00-00 00:00:00','General','Funding_Distribution','Option','',0),(113,'Funding_Segment','','','0000-00-00 00:00:00','General','Funding_Segment','Option','',0),(115,'GrantApplication','','','0000-00-00 00:00:00','General','GrantApplication','Option','',0),(116,'GrantDistribution','','','0000-00-00 00:00:00','General','GrantDistribution','Option','',0),(117,'Grp','','','0000-00-00 00:00:00','DB Management','Grp','Core','',39),(118,'GrpDBTable','Join table between Table and Grps (indicating permissions)','','0000-00-00 00:00:00','DB Management','GrpDBTable','Core','',9181),(119,'GrpEmployee','Join table, Grp-Employee','','0000-00-00 00:00:00','Join','Employee Groups','Core','',476),(120,'GrpLab_Protocol','Join table, Grp-Lab_Protocol','','0000-00-00 00:00:00','General','GrpLab_Protocol','Lab','',397),(121,'GrpStandard_Solution','Join table, Grp-Standard_Solution','','0000-00-00 00:00:00','General','GrpStandard_Solution','Lab','',207),(122,'Grp_Relationship','Join table, Grp-Grp','','0000-00-00 00:00:00','DB Management','Grp_Relationship','Core','',36),(123,'Issue_Detail','','','0000-00-00 00:00:00','General','Issue_Detail','Option','',2792),(124,'Issue_Log','','','0000-00-00 00:00:00','General','Issue_Log','Option','',1973),(125,'LibraryStudy','','','0000-00-00 00:00:00','General','LibraryStudy','Option','',4),(126,'Library_Plate','','','0000-00-00 00:00:00','Lab Object','Library_Plate','Lab','',185978),(127,'Matched_Funding','','','0000-00-00 00:00:00','General','Matched_Funding','Option','',0),(128,'Plate_Prep','','','0000-00-00 00:00:00','General','Plate_Prep','Lab','',1801353),(130,'Plate_Sample','','','0000-00-00 00:00:00','General','Plate_Sample','Lab','',13787753),(131,'PoolSample','','','0000-00-00 00:00:00','Join','PoolSample','Lab','',21538),(132,'Prep','','','0000-00-00 00:00:00','Lab Process','Prep','Lab','',417562),(133,'Primer_Plate','','','0000-00-00 00:00:00','General','Primer_Plate','Option','',9411),(134,'Primer_Plate_Well','','','0000-00-00 00:00:00','Join','Primer_Plate_Well','Option','',864145),(136,'ProjectStudy','','','0000-00-00 00:00:00','Join','ProjectStudy','Option','',17),(140,'ReArray_Request','','','0000-00-00 00:00:00','General','ReArray_Request','Lab','',7246),(141,'RunPlate','','','0000-00-00 00:00:00','General','RunPlate','Sequencing','',17411),(142,'Sample','','','0000-00-00 00:00:00','Lab Object','Sample','Lab','',13162807),(143,'Sequencing_Library','Additional information about this library','','0000-00-00 00:00:00','Application Specific','Library','Sequencing','',2006),(144,'Study','','','0000-00-00 00:00:00','General','Study','Option','',14),(145,'Submission_Detail','','','0000-00-00 00:00:00','General','Submission_Detail','Option','',3958),(146,'Transposon_Pool','','','0000-00-00 00:00:00','Lab Object','Transposon_Pool','Genomic','',531),(147,'Version','','','0000-00-00 00:00:00','DB Management','Version','Core','',10),(152,'DepartmentSetting','','','0000-00-00 00:00:00','Join','DepartmentSetting','Core','',20),(157,'Sample_Pool','','','0000-00-00 00:00:00','Lab Object','Sample_Pool','Lab','',155),(158,'ReArray_Plate','','','0000-00-00 00:00:00','General','ReArray Plate','Lab','',26),(160,'Agilent_Assay','','','0000-00-00 00:00:00','General','Agilent_Assay','Option','',1),(161,'DB_Login','','','0000-00-00 00:00:00','DB Management','DB_Login','Core','',9),(162,'Extraction','','','0000-00-00 00:00:00','General','Extraction','Lab','',196),(163,'Extraction_Details','','','0000-00-00 00:00:00','General','Extraction_Details','Lab','',1308),(164,'Extraction_Sample','','','0000-00-00 00:00:00','General','Extraction_Sample','Lab','',68261),(165,'Original_Source','Generic information about the source of a sample','','0000-00-00 00:00:00','General','Sample Origin','Lab','',3686),(169,'Sample_Alias','','','0000-00-00 00:00:00','Object Detail','Sample_Alias','Lab','',5009893),(171,'Printer','','','0000-00-00 00:00:00','General','Printer','Core','',19),(172,'Attribute','','','0000-00-00 00:00:00','Lookup','Attribute','Core','',182),(173,'Band','','','0000-00-00 00:00:00','General','Band','Option','',23208109),(174,'How_To_Object','','','0000-00-00 00:00:00','General','How_To_Object','Option','',1),(175,'How_To_Step','','','0000-00-00 00:00:00','General','How_To_Step','Option','',1),(176,'How_To_Topic','','','0000-00-00 00:00:00','General','How_To_Topic','Option','',1),(177,'Hybrid_Original_Source','','','0000-00-00 00:00:00','General','Hybrid_Original_Source','Lab','',268),(180,'Lab_Request','','','0000-00-00 00:00:00','General','Lab_Request','Option','',2355),(181,'Lane','','','0000-00-00 00:00:00','General','Lane','Option','',467320),(182,'Library_Source','','','0000-00-00 00:00:00','General','Library/Source Link','Lab','',5589),(184,'Original_Source_Attribute','','','0000-00-00 00:00:00','Object Detail','Original_Source_Attribute','Lab','',1589),(187,'Pipeline','','','0000-00-00 00:00:00','General','Pipeline','Core','',163),(188,'Plate_PrimerPlateWell','','','0000-00-00 00:00:00','Join','Plate_PrimerPlateWell','Option','',500832),(189,'Prep_Detail_Option','','','0000-00-00 00:00:00','Object Detail','Prep_Detail_Option','Lab','',0),(190,'Prep_Details','','','0000-00-00 00:00:00','Object Detail','Prep_Details','Lab','',0),(193,'Sample_Attribute','','','0000-00-00 00:00:00','Object Detail','Sample_Attribute','Lab','',885698),(194,'Source','Information about the sample being sent to the GSC.','','0000-00-00 00:00:00','Lab Object','Starting Material','Lab','',5555),(195,'SubmissionVolume','','','0000-00-00 00:00:00','Object Detail','SubmissionVolume','Option','',0),(196,'Submission_Alias','','','0000-00-00 00:00:00','Object Detail','Submission_Alias','Option','',251194),(197,'Submission_Volume','','','0000-00-00 00:00:00','Object Detail','Submission_Volume','Option','',179),(198,'Trace_Submission','','','0000-00-00 00:00:00','General','Trace_Submission','Plugin','',942641),(199,'Trigger','','','0000-00-00 00:00:00','DB Management','Trigger','Core','',14),(200,'Plate_Attribute','','','0000-00-00 00:00:00','Object Detail','Plate_Attribute','Lab','',37929),(201,'WorkLog','','','0000-00-00 00:00:00','DB Management','WorkLog','Core','',4594),(202,'WorkPackage','','','0000-00-00 00:00:00','DB Management','WorkPackage','Core','',63),(203,'Printer_Assignment','','','0000-00-00 00:00:00','General','Printer_Assignment','Core','',31),(204,'Printer_Group','','','0000-00-00 00:00:00','Join','Printer_Group','Core','',10),(205,'UseCase','','','0000-00-00 00:00:00','General','UseCase','Core','',35),(206,'UseCase_Step','','','0000-00-00 00:00:00','General','UseCase_Step','Option','',78),(207,'WorkPackage_Attribute','','','0000-00-00 00:00:00','Object Detail','WorkPackage_Attribute','Core','',172),(208,'Change_History','','','0000-00-00 00:00:00','General','Change_History','Core','',252454),(209,'Child_Ordered_Procedure','','','0000-00-00 00:00:00','Lab Process','Child_Ordered_Procedure','Lab','',94),(212,'FailureReason','','','0000-00-00 00:00:00','General','FailureReason','Lab','',7),(213,'GCOS_Config','','','0000-00-00 00:00:00','General','GCOS_Config','Microarray','',4),(214,'Genechip_Experiment','','','0000-00-00 00:00:00','General','Genechip_Experiment','Microarray','',0),(215,'GrpProject','','','0000-00-00 00:00:00','General','GrpProject','Option','',0),(216,'Location','','','0000-00-00 00:00:00','Lookup','Location','Core','',9),(217,'Ordered_Procedure','','','0000-00-00 00:00:00','Lab Process','Ordered_Procedure','Lab','',108),(218,'Organism','','','0000-00-00 00:00:00','Lookup','Organism','Lab','',98),(219,'Plate_Tray','','','0000-00-00 00:00:00','General','Plate_Tray','Lab','',51849),(220,'ProcedureTest_Condition','','','0000-00-00 00:00:00','Join','ProcedureTest_Condition','Option','',292),(221,'ReArray_Attribute','','','0000-00-00 00:00:00','Object Detail','ReArray_Attribute','Option','',14457),(222,'Source_Pool','','','0000-00-00 00:00:00','General','Source_Pool','Lab','',279),(223,'Status','','','0000-00-00 00:00:00','Lookup','Status','Core','',27),(224,'Submission_Info','','','0000-00-00 00:00:00','General','Submission_Info','Option','',839),(225,'Test_Condition','','','0000-00-00 00:00:00','General','Test_Condition','Option','',13),(226,'Tray','','','0000-00-00 00:00:00','General','Tray','Option','',13827),(227,'Tissue','','','0000-00-00 00:00:00','Lookup','Tissue','Lab','',327),(228,'Stage','','','0000-00-00 00:00:00','Lookup','Stage','Lab','',120),(229,'Submission_Table_Link','','','0000-00-00 00:00:00','Object Detail','Submission_Table_Link','Option','',1103),(230,'Prep_Attribute_Option','','','0000-00-00 00:00:00','Object Detail','Prep_Attribute_Option','Lab','',0),(231,'Prep_Attribute','','','0000-00-00 00:00:00','Object Detail','Prep_Attribute','Lab','',484),(232,'EST_Library','','','0000-00-00 00:00:00','General','EST_Library','Option','',21),(233,'Transposon_Library','','','0000-00-00 00:00:00','Lab Object','Transposon_Library','Genomic','',17),(234,'Work_Request','','','0000-00-00 00:00:00','DB Management','Work_Request','Core','',1011),(235,'Antibiotic','','','0000-00-00 00:00:00','Lookup','Antibiotic','Genomic','',5),(236,'Event','','','0000-00-00 00:00:00','General','Event','Core','',0),(237,'Event_Attribute','','','0000-00-00 00:00:00','Object Detail','Event_Attribute','Core','',0),(238,'Fail','','','0000-00-00 00:00:00','General','Fail','Lab','',36798),(239,'FailReason','','','0000-00-00 00:00:00','Lookup','FailReason','Lab','',66),(240,'Field_Map','','','0000-00-00 00:00:00','DB Management','Field_Map','Core','',10),(242,'GelAnalysis','','','0000-00-00 00:00:00','General','GelAnalysis','Option','',4693),(243,'GelRun','','','0000-00-00 00:00:00','General','GelRun','Option','',19535),(244,'Goal','','','0000-00-00 00:00:00','General','Goal','Lab','',8),(246,'LibraryApplication','','','0000-00-00 00:00:00','General','Association','Lab','',4466),(247,'LibraryGoal','','','0000-00-00 00:00:00','General','Target Goals','Lab','',4482),(248,'LibraryVector','','','0000-00-00 00:00:00','Join','LibraryVector','Option','',2008),(249,'Library_Segment','','','0000-00-00 00:00:00','Lab Object','Segmented Source','Lab','',2),(250,'Object_Class','','','0000-00-00 00:00:00','Lookup','Object_Class','Core','',8),(251,'Run','','','0000-00-00 00:00:00','General','Run','Lab','',83756),(252,'RunBatch','','','0000-00-00 00:00:00','General','RunBatch','Lab','',51181),(254,'Run_Attribute','','','0000-00-00 00:00:00','Object Detail','Run_Attribute','Sequencing','',111484),(255,'SequenceAnalysis','','','0000-00-00 00:00:00','General','SequenceAnalysis','Sequencing','',59839),(256,'SequenceRun','','','0000-00-00 00:00:00','General','SequenceRun','Sequencing','',60952),(259,'Source_Attribute','','','0000-00-00 00:00:00','Object Detail','Source_Attribute','Lab','',2579),(260,'Vector_Type','','','0000-00-00 00:00:00','Lookup','Vector_Type','Genomic','',116),(261,'Vector_TypeAntibiotic','','','0000-00-00 00:00:00','Join','Vector_TypeAntibiotic','Genomic','',63),(262,'Vector_TypePrimer','','','0000-00-00 00:00:00','Join','Vector_TypePrimer','Genomic','',346),(263,'View','','','0000-00-00 00:00:00','DB Management','View','Core','',0),(264,'ViewInput','','','0000-00-00 00:00:00','DB Management','ViewInput','Core','',0),(265,'ViewJoin','','','0000-00-00 00:00:00','General','ViewJoin','Core','',0),(266,'ViewOutput','','','0000-00-00 00:00:00','DB Management','ViewOutput','Core','',0),(267,'Array','','','0000-00-00 00:00:00','General','Array','Option','',1010),(268,'BioanalyzerAnalysis','','','0000-00-00 00:00:00','General','BioanalyzerAnalysis','Microarray','',0),(269,'BioanalyzerRead','','','0000-00-00 00:00:00','General','BioanalyzerRead','Microarray','',0),(270,'BioanalyzerRun','','','0000-00-00 00:00:00','General','BioanalyzerRun','Microarray','',0),(271,'Branch','','','0000-00-00 00:00:00','General','Branch','Lab','',189),(272,'Genechip','','','0000-00-00 00:00:00','General','Genechip','Microarray','',1718),(273,'GenechipAnalysis','','','0000-00-00 00:00:00','General','GenechipAnalysis','Microarray','',967),(274,'GenechipAnalysis_Attribute','','','0000-00-00 00:00:00','Object Detail','GenechipAnalysis_Attribute','Microarray','',0),(275,'GenechipExpAnalysis','','','0000-00-00 00:00:00','Lab Process','GenechipExpAnalysis','Microarray','',192),(276,'GenechipMapAnalysis','','','0000-00-00 00:00:00','Lab Process','GenechipMapAnalysis','Microarray','',598),(277,'GenechipRun','','','0000-00-00 00:00:00','General','GenechipRun','Microarray','',967),(278,'Genechip_Type','','','0000-00-00 00:00:00','General','Genechip_Type','Microarray','',76),(279,'Microarray','','','0000-00-00 00:00:00','Lab Object','Microarray','Microarray','',1718),(280,'Probe_Set','','','0000-00-00 00:00:00','General','Probe_Set','Microarray','',32),(281,'Probe_Set_Value','','','0000-00-00 00:00:00','General','Probe_Set_Value','Microarray','',3975),(282,'SpectAnalysis','','','0000-00-00 00:00:00','Lab Process','SpectAnalysis','Microarray','',0),(283,'SpectRead','','','0000-00-00 00:00:00','General','SpectRead','Microarray','',0),(284,'SpectRun','','','0000-00-00 00:00:00','General','SpectRun','Microarray','',0),(285,'Sorted_Cell','','','0000-00-00 00:00:00','General','Sorted Cells','Option','',88),(286,'Tissue_Source','','','0000-00-00 00:00:00','General','Tissue_Source','Lab','',7),(288,'SolexaRun','','','0000-00-00 00:00:00','General','SolexaRun','Plugin','',2299),(289,'SolexaAnalysis','','','0000-00-00 00:00:00','General','SolexaAnalysis','Plugin','',2934),(290,'RunBatch_Attribute','','','0000-00-00 00:00:00','Object Detail','RunBatch_Attribute','Sequencing','',0),(291,'Flowcell','','','0000-00-00 00:00:00','General','Flowcell','Plugin','',292),(292,'Branch_Condition','','','0000-00-00 00:00:00','General','Branch_Condition','Lab','',200),(293,'Defined_Plate_Set','','','0000-00-00 00:00:00','Lab Object','Defined_Plate_Set','Lab','',21032),(294,'GCOS_Config_Record','','','0000-00-00 00:00:00','General','GCOS_Config_Record','Microarray','',33),(295,'Label_Format','','','0000-00-00 00:00:00','Lookup','Label_Format','Core','',5),(296,'Maintenance_Process_Type','','','0000-00-00 00:00:00','General','Maintenance_Process_Type','Lab','',12),(297,'Pipeline_Step','','','0000-00-00 00:00:00','General','Pipeline_Step','Lab','',205),(298,'Pipeline_StepRelationship','','','0000-00-00 00:00:00','Join','Pipeline_StepRelationship','Option','',155),(299,'RNA_DNA_Collection','','','0000-00-00 00:00:00','General','RNA_DNA_Collection','Option','',2286),(300,'RNA_DNA_Source','','','0000-00-00 00:00:00','General','RNA_DNA_Source','Option','',2584),(301,'RNA_DNA_Source_Attribute','','','0000-00-00 00:00:00','Object Detail','RNA_DNA_Source_Attribute','Option','',512),(302,'Work_Request_Type','','','0000-00-00 00:00:00','DB Management','Work_Request_Type','Core','',9),(303,'Genetic_Code',NULL,NULL,'0000-00-00 00:00:00',NULL,'Genetic_Code',NULL,NULL,0),(304,'Library_Attribute',NULL,NULL,'0000-00-00 00:00:00',NULL,'Library_Attribute',NULL,NULL,0),(305,'Maintenance_Schedule',NULL,NULL,'0000-00-00 00:00:00',NULL,'Maintenance_Schedule',NULL,NULL,0),(306,'Pipeline_Group',NULL,NULL,'0000-00-00 00:00:00',NULL,'Pipeline_Group',NULL,NULL,0),(307,'Plate_Schedule',NULL,NULL,'0000-00-00 00:00:00',NULL,'Plate_Schedule',NULL,NULL,0),(308,'Report',NULL,NULL,'0000-00-00 00:00:00',NULL,'Report',NULL,NULL,0),(309,'RunDataAnnotation',NULL,NULL,'0000-00-00 00:00:00',NULL,'RunDataAnnotation',NULL,NULL,0),(310,'RunDataAnnotation_Type',NULL,NULL,'0000-00-00 00:00:00',NULL,'RunDataAnnotation_Type',NULL,NULL,0),(311,'RunDataReference',NULL,NULL,'0000-00-00 00:00:00',NULL,'RunDataReference',NULL,NULL,0),(312,'Subscriber',NULL,NULL,'0000-00-00 00:00:00',NULL,'Subscriber',NULL,NULL,0),(313,'Subscription',NULL,NULL,'0000-00-00 00:00:00',NULL,'Subscription',NULL,NULL,0),(314,'Subscription_Event',NULL,NULL,'0000-00-00 00:00:00',NULL,'Subscription_Event',NULL,NULL,0),(315,'Table_Type',NULL,NULL,'0000-00-00 00:00:00',NULL,'Table_Type',NULL,NULL,0),(316,'Taxonomy',NULL,NULL,'0000-00-00 00:00:00',NULL,'Taxonomy',NULL,NULL,0),(317,'Taxonomy_Division',NULL,NULL,'0000-00-00 00:00:00',NULL,'Taxonomy_Division',NULL,NULL,0),(318,'Taxonomy_Name',NULL,NULL,'0000-00-00 00:00:00',NULL,'Taxonomy_Name',NULL,NULL,0),(319,'Taxonomy_Node',NULL,NULL,'0000-00-00 00:00:00',NULL,'Taxonomy_Node',NULL,NULL,0),(320,'Template',NULL,NULL,'0000-00-00 00:00:00',NULL,'Template',NULL,NULL,0),(321,'Template_Assignment',NULL,NULL,'0000-00-00 00:00:00',NULL,'Template_Assignment',NULL,NULL,0),(322,'Template_Field',NULL,NULL,'0000-00-00 00:00:00',NULL,'Template_Field',NULL,NULL,0),(323,'junk',NULL,NULL,'0000-00-00 00:00:00',NULL,'junk',NULL,NULL,0),(324,'org_tax_origin',NULL,NULL,'0000-00-00 00:00:00',NULL,'org_tax_origin',NULL,NULL,0),(325,'temp_tax',NULL,NULL,'0000-00-00 00:00:00',NULL,'temp_tax',NULL,NULL,0),(326,'New_Stock',NULL,NULL,'0000-00-00 00:00:00',NULL,'New_Stock',NULL,NULL,0),(327,'Sample_Type',NULL,NULL,'0000-00-00 00:00:00',NULL,'Sample_Type',NULL,NULL,0),(328,'Stock_Catalog',NULL,NULL,'0000-00-00 00:00:00',NULL,'Stock_Catalog',NULL,NULL,0);
UNLOCK TABLES;
/*!40000 ALTER TABLE `DBTable` ENABLE KEYS */;

--
-- Table structure for table `DB_Form`
--

DROP TABLE IF EXISTS `DB_Form`;
CREATE TABLE `DB_Form` (
  `DB_Form_ID` int(11) NOT NULL auto_increment,
  `Form_Table` varchar(80) NOT NULL default '',
  `Form_Order` int(2) default '1',
  `Min_Records` int(2) NOT NULL default '1',
  `Max_Records` int(2) NOT NULL default '1',
  `FKParent_DB_Form__ID` int(11) default NULL,
  `Parent_Field` varchar(80) default NULL,
  `Parent_Value` varchar(200) default NULL,
  `Finish` int(11) default '0',
  `Class` varchar(40) default NULL,
  PRIMARY KEY  (`DB_Form_ID`),
  KEY `FKParent_DB_Form__ID` (`FKParent_DB_Form__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `DB_Form`
--


/*!40000 ALTER TABLE `DB_Form` DISABLE KEYS */;
LOCK TABLES `DB_Form` WRITE;
INSERT INTO `DB_Form` VALUES (1,'Employee',1,1,1,0,'','',0,''),(2,'GrpEmployee',1,1,5,1,'','',1,''),(3,'Primer',1,1,1,0,'','',0,''),(4,'Primer_Customization',1,0,1,3,'','',1,''),(5,'Branch',2,1,1,3,'','',0,'Primer'),(6,'Plate',1,1,1,0,'','',0,''),(7,'Tube',1,1,1,6,'Plate_Type','Tube',0,''),(8,'Standard_Solution',1,1,1,0,'','',0,''),(9,'GrpStandard_Solution',1,1,-1,8,'','',0,''),(10,'Study',1,1,1,0,'','',0,''),(11,'ProjectStudy',1,1,5,10,'','',0,''),(12,'RunBatch',1,1,1,0,'','',0,''),(13,'Run',1,1,1,12,'','',0,''),(14,'GelRun',1,1,1,13,'','',0,''),(15,'Work_Request',1,1,5,0,'','',0,''),(16,'LibraryApplication',1,1,1,15,'Work_Request_Type','DNA Preps',1,'Antibiotic'),(17,'LibraryApplication',1,1,3,15,'Work_Request_Type','1/16 End Reads|1/256 End Reads|1/24 End Reads|1/48 End Reads',1,'Primer'),(18,'LibraryApplication',1,0,1,15,'Work_Request_Type','1/16 Custom Reads|1/256 Custom Reads',1,'Primer'),(19,'LibraryApplication',1,1,2,15,'Work_Request_Type','1/24 Custom Reads|1/48 Custom Reads',1,'Primer'),(20,'Original_Source',1,1,1,0,'','',1,''),(21,'Source',1,1,1,20,'Sample_Available','Yes',0,''),(22,'RNA_DNA_Source',1,1,1,21,'Source_Type','RNA_DNA_Source',1,''),(23,'ReArray_Plate',1,1,1,21,'Source_Type','ReArray_Plate',1,''),(24,'Ligation',1,1,1,21,'Source_Type','Ligation',1,''),(25,'Microtiter',1,1,1,21,'Source_Type','Microtiter',1,''),(26,'Xformed_Cells',1,1,1,21,'Source_Type','Xformed_Cells',1,''),(27,'Library_Segment',1,1,1,21,'Source_Type','Library_Segment',1,''),(28,'Sorted_Cell',1,1,1,21,'Source_Type','Sorted_Cell',1,''),(29,'Library',1,1,1,20,'','',0,''),(30,'RNA_DNA_Collection',1,1,1,29,'Library_Type','RNA/DNA',0,''),(31,'Sequencing_Library',1,1,1,29,'Library_Type','Sequencing|Mapping',0,''),(32,'LibraryApplication',2,1,15,29,'Library_Type','Mapping',0,'Enzyme'),(33,'LibraryGoal',1,1,2,29,'','',0,''),(34,'Vector',1,1,1,31,'','',0,''),(35,'LibraryVector',1,1,1,34,'','',0,''),(36,'LibraryApplication',1,1,1,35,'','',0,'Antibiotic'),(37,'SAGE_Library',1,1,1,31,'Sequencing_Library_Type','SAGE',0,''),(38,'cDNA_Library',1,1,1,31,'Sequencing_Library_Type','cDNA',0,''),(39,'Genomic_Library',1,1,1,31,'Sequencing_Library_Type','Genomic',0,''),(40,'PCR_Library',1,1,1,31,'Sequencing_Library_Type','PCR',0,''),(41,'Transposon_Library',1,1,1,31,'Sequencing_Library_Type','Transposon',0,''),(42,'EST_Library',1,1,1,31,'Sequencing_Library_Type','EST',0,''),(43,'LibraryApplication',2,1,4,29,'Library_Type','Sequencing',0,'Primer'),(44,'Library_Source',1,1,1,0,'','',1,''),(45,'Enzyme',1,1,1,0,'','',1,''),(46,'Branch',1,1,1,45,'','',0,'Enzyme');
UNLOCK TABLES;
/*!40000 ALTER TABLE `DB_Form` ENABLE KEYS */;

--
-- Table structure for table `DB_Login`
--

DROP TABLE IF EXISTS `DB_Login`;
CREATE TABLE `DB_Login` (
  `DB_Login_ID` int(11) NOT NULL auto_increment,
  `FK_Employee__ID` int(11) NOT NULL default '0',
  `DB_User` char(40) NOT NULL default '',
  PRIMARY KEY  (`DB_Login_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `DB_Login`
--


/*!40000 ALTER TABLE `DB_Login` DISABLE KEYS */;
LOCK TABLES `DB_Login` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `DB_Login` ENABLE KEYS */;

--
-- Table structure for table `Defined_Plate_Set`
--

DROP TABLE IF EXISTS `Defined_Plate_Set`;
CREATE TABLE `Defined_Plate_Set` (
  `Defined_Plate_Set_ID` int(11) NOT NULL auto_increment,
  `Plate_Set_Defined` datetime default NULL,
  `FK_Employee__ID` int(11) default NULL,
  PRIMARY KEY  (`Defined_Plate_Set_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Defined_Plate_Set`
--


/*!40000 ALTER TABLE `Defined_Plate_Set` DISABLE KEYS */;
LOCK TABLES `Defined_Plate_Set` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Defined_Plate_Set` ENABLE KEYS */;

--
-- Table structure for table `Department`
--

DROP TABLE IF EXISTS `Department`;
CREATE TABLE `Department` (
  `Department_ID` int(11) NOT NULL auto_increment,
  `Department_Name` char(40) default NULL,
  `Department_Status` enum('Active','Inactive') default NULL,
  PRIMARY KEY  (`Department_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Department`
--


/*!40000 ALTER TABLE `Department` DISABLE KEYS */;
LOCK TABLES `Department` WRITE;
INSERT INTO `Department` VALUES (1,'LIMS Admin','Active'),(2,'Sequencing','Active'),(3,'Gene Expression','Active'),(4,'Receiving','Active');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Department` ENABLE KEYS */;

--
-- Table structure for table `DepartmentSetting`
--

DROP TABLE IF EXISTS `DepartmentSetting`;
CREATE TABLE `DepartmentSetting` (
  `DepartmentSetting_ID` int(11) NOT NULL auto_increment,
  `FK_Setting__ID` int(11) default NULL,
  `FK_Department__ID` int(11) default NULL,
  `Setting_Value` char(40) default NULL,
  PRIMARY KEY  (`DepartmentSetting_ID`),
  KEY `FK_Department__ID` (`FK_Department__ID`),
  KEY `FK_Setting__ID` (`FK_Setting__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `DepartmentSetting`
--


/*!40000 ALTER TABLE `DepartmentSetting` DISABLE KEYS */;
LOCK TABLES `DepartmentSetting` WRITE;
INSERT INTO `DepartmentSetting` VALUES (1,1,2,'auto1@urania'),(2,2,2,'auto1@saturnia');
UNLOCK TABLES;
/*!40000 ALTER TABLE `DepartmentSetting` ENABLE KEYS */;

--
-- Table structure for table `Dye_Chemistry`
--

DROP TABLE IF EXISTS `Dye_Chemistry`;
CREATE TABLE `Dye_Chemistry` (
  `Dye_Chemistry_ID` int(11) NOT NULL auto_increment,
  `Terminator` varchar(20) default NULL,
  `Chemistry_Version` int(11) default NULL,
  `Mobility_Version` int(11) default NULL,
  `Mob_File` varchar(255) default NULL,
  `Dye_Set` varchar(5) default NULL,
  PRIMARY KEY  (`Dye_Chemistry_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Dye_Chemistry`
--


/*!40000 ALTER TABLE `Dye_Chemistry` DISABLE KEYS */;
LOCK TABLES `Dye_Chemistry` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Dye_Chemistry` ENABLE KEYS */;

--
-- Table structure for table `EST_Library`
--

DROP TABLE IF EXISTS `EST_Library`;
CREATE TABLE `EST_Library` (
  `EST_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Sequencing_Library__ID` int(11) NOT NULL default '0',
  `5Prime_Insert_Site_Enzyme` varchar(40) NOT NULL default '',
  `3Prime_Insert_Site_Enzyme` varchar(40) NOT NULL default '',
  `Blue_White_Selection` enum('Yes','No') NOT NULL default 'No',
  `Enriched_For_Full_Length` enum('Yes','No') NOT NULL default 'Yes',
  `Construction_Correction` enum('','Normalized','Subtracted') NOT NULL default '',
  `FK3PrimeInsert_Restriction_Site__ID` int(11) default NULL,
  `FK5PrimeInsert_Restriction_Site__ID` int(11) default NULL,
  PRIMARY KEY  (`EST_Library_ID`),
  KEY `lib_id` (`FK_Sequencing_Library__ID`),
  KEY `FK3PrimeInsert_Restriction_Site__ID` (`FK3PrimeInsert_Restriction_Site__ID`),
  KEY `FK5PrimeInsert_Restriction_Site__ID` (`FK5PrimeInsert_Restriction_Site__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `EST_Library`
--


/*!40000 ALTER TABLE `EST_Library` DISABLE KEYS */;
LOCK TABLES `EST_Library` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `EST_Library` ENABLE KEYS */;

--
-- Table structure for table `Employee`
--

DROP TABLE IF EXISTS `Employee`;
CREATE TABLE `Employee` (
  `Employee_ID` int(4) NOT NULL auto_increment,
  `Employee_Name` varchar(80) default NULL,
  `Employee_Start_Date` date default NULL,
  `Initials` varchar(4) default NULL,
  `Email_Address` varchar(80) default NULL,
  `Employee_FullName` varchar(80) default NULL,
  `Position` text,
  `Employee_Status` enum('Active','Inactive','Old') default NULL,
  `Permissions` set('R','W','U','D','S','P','A') default NULL,
  `IP_Address` text,
  `Password` varchar(80) default '78a302dd267f6044',
  `Machine_Name` varchar(20) default NULL,
  `Department` enum('Receiving','Administration','Sequencing','Mapping','BioInformatics','Gene Expression','None') default NULL,
  `FK_Department__ID` int(11) default NULL,
  PRIMARY KEY  (`Employee_ID`),
  UNIQUE KEY `initials` (`Initials`),
  UNIQUE KEY `name` (`Employee_Name`),
  KEY `FK_Department__ID` (`FK_Department__ID`),
  KEY `email` (`Email_Address`),
  KEY `fullname` (`Employee_FullName`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Employee`
--


/*!40000 ALTER TABLE `Employee` DISABLE KEYS */;
LOCK TABLES `Employee` WRITE;
INSERT INTO `Employee` VALUES (1,'Steve Jones','0000-00-00','SJ','sjones','Steve Jones','Director','Active','R,W,U,S,P','','78a302dd267f6044','','BioInformatics',6),(2,'Marco','0000-00-00','MM','mmarra','Marco Marra','Director','Active','R,W,U,S,P','','234468877d771ec1','','Administration',2),(3,'Duane','0000-00-00','DS','dsmailus','Duane Smailus','Process Development Co-ordinator','Active','R,W,U,S,P,A','10.1.1.69','2deec50356ca62b4','','Sequencing',2),(4,'Ran','2000-02-03','RG','rguin','Ran Guin','LIMS Admin','Active','R,W,U,D,S,P,A','10.9.203.158','459f153e2794f6da','sthenno','BioInformatics',1),(5,'Jeff Stott','0000-00-00','JMS','jstott','Jeff Stott','Production Co-ordinator','Inactive','R,W,U,D,S,P,A','10.1.1.184','04226cb809ee7456','10.9.204.55','Sequencing',2),(6,'Admin','2001-01-01','ADM',NULL,'Administrator','BioInformatics','Active','R,W,U,D,S,P,A',NULL,'459f153e2794f6da',NULL,NULL,1);
UNLOCK TABLES;
/*!40000 ALTER TABLE `Employee` ENABLE KEYS */;

--
-- Table structure for table `EmployeeSetting`
--

DROP TABLE IF EXISTS `EmployeeSetting`;
CREATE TABLE `EmployeeSetting` (
  `EmployeeSetting_ID` int(11) NOT NULL auto_increment,
  `FK_Setting__ID` int(11) default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Setting_Value` char(40) default NULL,
  PRIMARY KEY  (`EmployeeSetting_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_Setting__ID` (`FK_Setting__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `EmployeeSetting`
--


/*!40000 ALTER TABLE `EmployeeSetting` DISABLE KEYS */;
LOCK TABLES `EmployeeSetting` WRITE;
INSERT INTO `EmployeeSetting` VALUES (1,1,110,'auto1@jetdirect02'),(2,1,139,'auto1@jetdirect02'),(3,1,163,'auto1@jetdirect02'),(4,1,109,'auto1@jetdirect02');
UNLOCK TABLES;
/*!40000 ALTER TABLE `EmployeeSetting` ENABLE KEYS */;

--
-- Table structure for table `Enzyme`
--

DROP TABLE IF EXISTS `Enzyme`;
CREATE TABLE `Enzyme` (
  `Enzyme_ID` int(11) NOT NULL auto_increment,
  `Enzyme_Name` varchar(30) default NULL,
  `Enzyme_Sequence` text,
  PRIMARY KEY  (`Enzyme_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Enzyme`
--


/*!40000 ALTER TABLE `Enzyme` DISABLE KEYS */;
LOCK TABLES `Enzyme` WRITE;
INSERT INTO `Enzyme` VALUES (1,'SphI','GCATGC'),(2,'NlaIII',''),(3,'BsmFI',''),(4,'MmeI',''),(5,'other','other'),(6,'EcoRI','GAATTC'),(7,'XhoI','CTCGAG'),(8,'NotI','GCGGCCGC'),(9,'Hind III','AAGCTT'),(10,'SfiI','GGCCNNNNNGGCC'),(11,'SalI','GTCGAC'),(12,'Custom',''),(13,'MboI','GATC'),(14,'EcoRI/Meth','GAATTC'),(15,'test','AATTCCG(10)N(4)'),(17,'BamHI','GGATCC'),(18,'ApaI','GGGCCC'),(19,'Hinc II','GACCTG'),(20,'None',''),(21,'Unknown',''),(22,'EcoRV','GATATC'),(23,'Mixed',''),(24,'TBD',''),(25,'n/a',''),(26,'TA Cloned',''),(27,'ApaLI','GTGCAC'),(28,'BglII','AGATCT'),(29,'KpnI','GGTACC'),(30,'NcoI','CCATGG'),(31,'Pst I','CTGCAG'),(32,'PvuI','CGATCG'),(33,'PvuII','CAGCTG'),(34,'Phusion HF DNA Polymerase',''),(35,'iProof Polymerase',''),(36,'NdeI','CATATG'),(37,'BstXI','CCANNNNNNTGG'),(38,'MseI','TTAA'),(39,'Eco72 I','CACGTG'),(40,'Sau3A I','NGATCN'),(41,'Msl I','CAYNNNNRTG'),(42,'DpnII','GATC'),(43,'DpnII','GATC'),(44,'EcoRI/EcoRV','');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Enzyme` ENABLE KEYS */;

--
-- Table structure for table `Equipment`
--

DROP TABLE IF EXISTS `Equipment`;
CREATE TABLE `Equipment` (
  `Equipment_ID` int(4) NOT NULL auto_increment,
  `Equipment_Name` varchar(40) default NULL,
  `Equipment_Type` enum('','Sequencer','Centrifuge','Thermal Cycler','Freezer','Liquid Dispenser','Platform Shaker','Incubator','Colony Picker','Plate Reader','Storage','Power Supply','Miscellaneous','Genechip Scanner','Gel Comb','Gel Box','Fluorimager','Spectrophotometer','Bioanalyzer','Hyb Oven','Solexa','GCOS Server','Printer','Pipette','Balance','PDA','Cluster Station') default NULL,
  `Equipment_Comments` text,
  `Model` varchar(80) default NULL,
  `Serial_Number` varchar(80) default NULL,
  `Acquired` date default NULL,
  `Equipment_Cost` float default NULL,
  `Equipment_Number` int(11) default NULL,
  `Equipment_Number_in_Batch` int(11) default NULL,
  `FK_Stock__ID` int(11) default NULL,
  `Equipment_Alias` varchar(40) default NULL,
  `Equipment_Description` text,
  `Equipment_Location` enum('Sequence Lab','Chromos','CDC','CRC','Functional Genomics','Linen','GE Lab','GE Lab - RNA area','GE Lab - DITAG area','Mapping Lab','MGC Lab') default NULL,
  `Equipment_Status` enum('In Use','Not In Use','Removed') default 'In Use',
  `FK_Location__ID` int(11) NOT NULL default '0',
  `Equipment_Condition` enum('-80 degrees','-40 degrees','-20 degrees','+4 degrees','Variable','Room Temperature','') NOT NULL default '',
  PRIMARY KEY  (`Equipment_ID`),
  UNIQUE KEY `equip` (`Equipment_Name`),
  KEY `FK_Stock__ID` (`FK_Stock__ID`),
  KEY `model` (`Model`),
  KEY `serial` (`Serial_Number`),
  KEY `type` (`Equipment_Type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Equipment`
--


/*!40000 ALTER TABLE `Equipment` DISABLE KEYS */;
LOCK TABLES `Equipment` WRITE;
INSERT INTO `Equipment` VALUES (1,'Shelf','','','','','0000-00-00',0,0,0,0,'','','Sequence Lab','In Use',1,''),(2,'MB1','Sequencer','','MegaBase 1000','13367','1999-09-13',0,0,0,1090,'','','Sequence Lab','Not In Use',1,'');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Equipment` ENABLE KEYS */;

--
-- Table structure for table `Error_Check`
--

DROP TABLE IF EXISTS `Error_Check`;
CREATE TABLE `Error_Check` (
  `Error_Check_ID` int(11) NOT NULL auto_increment,
  `Username` varchar(20) NOT NULL default '',
  `Table_Name` mediumtext NOT NULL,
  `Field_Name` mediumtext NOT NULL,
  `Command_Type` enum('SQL','RegExp','FullSQL','Perl') default NULL,
  `Command_String` mediumtext NOT NULL,
  `Notice_Sent` date default NULL,
  `Notice_Frequency` int(11) default NULL,
  `Comments` text,
  `Description` text,
  `Action` text,
  `Priority` mediumtext,
  PRIMARY KEY  (`Error_Check_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Error_Check`
--


/*!40000 ALTER TABLE `Error_Check` DISABLE KEYS */;
LOCK TABLES `Error_Check` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Error_Check` ENABLE KEYS */;

--
-- Table structure for table `Event`
--

DROP TABLE IF EXISTS `Event`;
CREATE TABLE `Event` (
  `Event_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_Employee__ID` int(11) NOT NULL default '0',
  `Event_Type` enum('Inventory') default NULL,
  `Event_Start` datetime NOT NULL default '0000-00-00 00:00:00',
  `Event_Finish` datetime NOT NULL default '0000-00-00 00:00:00',
  `FKEvent_Status__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Event_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FKEvent_Status__ID` (`FKEvent_Status__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Event`
--


/*!40000 ALTER TABLE `Event` DISABLE KEYS */;
LOCK TABLES `Event` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Event` ENABLE KEYS */;

--
-- Table structure for table `Event_Attribute`
--

DROP TABLE IF EXISTS `Event_Attribute`;
CREATE TABLE `Event_Attribute` (
  `Event_Attribute_ID` int(11) NOT NULL auto_increment,
  `FK_Event__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text NOT NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Set_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`Event_Attribute_ID`),
  UNIQUE KEY `event_attribute` (`FK_Event__ID`,`FK_Attribute__ID`),
  KEY `FK_Event__ID` (`FK_Event__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Event_Attribute`
--


/*!40000 ALTER TABLE `Event_Attribute` DISABLE KEYS */;
LOCK TABLES `Event_Attribute` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Event_Attribute` ENABLE KEYS */;

--
-- Table structure for table `Extraction`
--

DROP TABLE IF EXISTS `Extraction`;
CREATE TABLE `Extraction` (
  `Extraction_ID` int(11) NOT NULL auto_increment,
  `FKSource_Plate__ID` int(11) NOT NULL default '0',
  `FKTarget_Plate__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Extraction_ID`),
  KEY `source_plate` (`FKSource_Plate__ID`),
  KEY `target_plate` (`FKTarget_Plate__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Extraction`
--


/*!40000 ALTER TABLE `Extraction` DISABLE KEYS */;
LOCK TABLES `Extraction` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Extraction` ENABLE KEYS */;

--
-- Table structure for table `Extraction_Details`
--

DROP TABLE IF EXISTS `Extraction_Details`;
CREATE TABLE `Extraction_Details` (
  `Extraction_Details_ID` int(11) NOT NULL auto_increment,
  `FK_Extraction_Sample__ID` int(11) NOT NULL default '0',
  `RNA_DNA_Isolated_Date` date default NULL,
  `FKIsolated_Employee__ID` int(11) default NULL,
  `Disruption_Method` enum('Homogenized','Sheared') default NULL,
  `Isolation_Method` enum('Trizol','Qiagen Kit') default NULL,
  `Resuspension_Volume` int(11) default NULL,
  `Resuspension_Volume_Units` enum('ul') default NULL,
  `Amount_RNA_DNA_Source_Used` int(11) default NULL,
  `Amount_RNA_DNA_Source_Used_Units` enum('Cells','Gram of Tissue','Embryos','Litters','Organs','ug/ng') default NULL,
  `FK_Agilent_Assay__ID` int(11) NOT NULL default '0',
  `Assay_Quality` enum('Degraded','Partially Degraded','Good') default NULL,
  `Assay_Quantity` int(11) default NULL,
  `Assay_Quantity_Units` enum('ug/ul','ng/ul','pg/ul') default NULL,
  `Total_Yield` int(11) default NULL,
  `Total_Yield_Units` enum('ug','ng','pg') default NULL,
  `Extraction_Size_Estimate` int(11) default NULL,
  `FK_Band__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Extraction_Details_ID`),
  KEY `extraction_sample__id` (`FK_Extraction_Sample__ID`),
  KEY `isolated_employee_id` (`FKIsolated_Employee__ID`),
  KEY `agilent_assay_id` (`FK_Agilent_Assay__ID`),
  KEY `band_id` (`FK_Band__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Extraction_Details`
--


/*!40000 ALTER TABLE `Extraction_Details` DISABLE KEYS */;
LOCK TABLES `Extraction_Details` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Extraction_Details` ENABLE KEYS */;

--
-- Table structure for table `Extraction_Sample`
--

DROP TABLE IF EXISTS `Extraction_Sample`;
CREATE TABLE `Extraction_Sample` (
  `Extraction_Sample_ID` int(11) NOT NULL auto_increment,
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `FK_Library__Name` char(6) default NULL,
  `Plate_Number` int(11) default NULL,
  `Volume` int(11) default NULL,
  `FKOriginal_Plate__ID` int(11) default NULL,
  `Extraction_Sample_Type` enum('DNA','RNA','Protein','Mixed','Amplicon','Clone','mRNA','Tissue','Cells','RNA - DNase Treated','cDNA','1st strand cDNA','Amplified cDNA','Ditag','Concatemer - Insert','Concatemer - Cloned') default NULL,
  `Original_Well` char(3) default NULL,
  PRIMARY KEY  (`Extraction_Sample_ID`),
  KEY `sample` (`FK_Sample__ID`),
  KEY `plate` (`FKOriginal_Plate__ID`),
  KEY `library_name` (`FK_Library__Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Extraction_Sample`
--


/*!40000 ALTER TABLE `Extraction_Sample` DISABLE KEYS */;
LOCK TABLES `Extraction_Sample` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Extraction_Sample` ENABLE KEYS */;

--
-- Table structure for table `Fail`
--

DROP TABLE IF EXISTS `Fail`;
CREATE TABLE `Fail` (
  `Fail_ID` int(11) NOT NULL auto_increment,
  `Object_ID` int(11) NOT NULL default '0',
  `FK_Employee__ID` int(11) NOT NULL default '0',
  `FK_FailReason__ID` int(11) NOT NULL default '0',
  `DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `Comments` text,
  PRIMARY KEY  (`Fail_ID`),
  KEY `FK_FailReason__ID` (`FK_FailReason__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `Object_ID` (`Object_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Fail`
--


/*!40000 ALTER TABLE `Fail` DISABLE KEYS */;
LOCK TABLES `Fail` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Fail` ENABLE KEYS */;

--
-- Table structure for table `FailReason`
--

DROP TABLE IF EXISTS `FailReason`;
CREATE TABLE `FailReason` (
  `FailReason_ID` int(11) NOT NULL auto_increment,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FailReason_Name` varchar(100) default NULL,
  `FailReason_Description` text,
  `FK_Object_Class__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`FailReason_ID`),
  UNIQUE KEY `Unique_type_name` (`FailReason_Name`,`FK_Object_Class__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Object_Class__ID` (`FK_Object_Class__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `FailReason`
--


/*!40000 ALTER TABLE `FailReason` DISABLE KEYS */;
LOCK TABLES `FailReason` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `FailReason` ENABLE KEYS */;

--
-- Table structure for table `FailureReason`
--

DROP TABLE IF EXISTS `FailureReason`;
CREATE TABLE `FailureReason` (
  `FailureReason_ID` int(11) NOT NULL auto_increment,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FailureReason_Name` varchar(40) default NULL,
  `Failure_Description` text,
  PRIMARY KEY  (`FailureReason_ID`),
  UNIQUE KEY `failurereason_name_nique` (`FailureReason_Name`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `FailureReason`
--


/*!40000 ALTER TABLE `FailureReason` DISABLE KEYS */;
LOCK TABLES `FailureReason` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `FailureReason` ENABLE KEYS */;

--
-- Table structure for table `Field_Map`
--

DROP TABLE IF EXISTS `Field_Map`;
CREATE TABLE `Field_Map` (
  `Field_Map_ID` int(11) NOT NULL auto_increment,
  `FK_Attribute__ID` int(11) default NULL,
  `FKSource_DBField__ID` int(11) default NULL,
  `FKTarget_DBField__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Field_Map_ID`),
  UNIQUE KEY `Field_Attr_Map_Key` (`FKTarget_DBField__ID`,`FK_Attribute__ID`),
  UNIQUE KEY `Field_Field_Map_Key` (`FKTarget_DBField__ID`,`FKSource_DBField__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Field_Map`
--


/*!40000 ALTER TABLE `Field_Map` DISABLE KEYS */;
LOCK TABLES `Field_Map` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Field_Map` ENABLE KEYS */;

--
-- Table structure for table `Flowcell`
--

DROP TABLE IF EXISTS `Flowcell`;
CREATE TABLE `Flowcell` (
  `Flowcell_ID` int(11) NOT NULL auto_increment,
  `Flowcell_Code` varchar(40) NOT NULL default '',
  `Grafted_Datetime` datetime default NULL,
  `Lot_Number` varchar(40) default NULL,
  `FK_Tray__ID` int(11) default NULL,
  PRIMARY KEY  (`Flowcell_ID`),
  KEY `code` (`Flowcell_Code`),
  KEY `FK_Tray__ID` (`FK_Tray__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Flowcell`
--


/*!40000 ALTER TABLE `Flowcell` DISABLE KEYS */;
LOCK TABLES `Flowcell` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Flowcell` ENABLE KEYS */;

--
-- Table structure for table `Funding`
--

DROP TABLE IF EXISTS `Funding`;
CREATE TABLE `Funding` (
  `Funding_ID` int(11) NOT NULL auto_increment,
  `Funding_Status` enum('Applied for','Pending','Received','Terminated') default 'Received',
  `Funding_Name` varchar(80) NOT NULL default '',
  `Funding_Conditions` text NOT NULL,
  `Funding_Code` varchar(20) default NULL,
  `Funding_Description` text NOT NULL,
  `Funding_Source` enum('Internal','External') NOT NULL default 'Internal',
  `ApplicationDate` date default NULL,
  `FKContact_Employee__ID` int(11) default NULL,
  `FKSource_Organization__ID` int(11) default NULL,
  `Source_ID` text,
  `AppliedFor` int(11) default NULL,
  `Duration` text,
  `Funding_Type` enum('New','Renewal') default NULL,
  `Currency` enum('US','Canadian') default 'Canadian',
  `ExchangeRate` float default NULL,
  PRIMARY KEY  (`Funding_ID`),
  UNIQUE KEY `name` (`Funding_Name`),
  UNIQUE KEY `code` (`Funding_Code`),
  KEY `FKSource_Organization__ID` (`FKSource_Organization__ID`),
  KEY `FKContact_Employee__ID` (`FKContact_Employee__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Funding`
--


/*!40000 ALTER TABLE `Funding` DISABLE KEYS */;
LOCK TABLES `Funding` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Funding` ENABLE KEYS */;

--
-- Table structure for table `Funding_Applicant`
--

DROP TABLE IF EXISTS `Funding_Applicant`;
CREATE TABLE `Funding_Applicant` (
  `Funding_Applicant_ID` int(11) NOT NULL auto_increment,
  `FK_Funding__ID` int(11) default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `FK_Contact__ID` int(11) default NULL,
  `Applicant_Type` enum('Primary','Collaborator') default NULL,
  PRIMARY KEY  (`Funding_Applicant_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`),
  KEY `FK_Funding__ID` (`FK_Funding__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Funding_Applicant`
--


/*!40000 ALTER TABLE `Funding_Applicant` DISABLE KEYS */;
LOCK TABLES `Funding_Applicant` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Funding_Applicant` ENABLE KEYS */;

--
-- Table structure for table `Funding_Distribution`
--

DROP TABLE IF EXISTS `Funding_Distribution`;
CREATE TABLE `Funding_Distribution` (
  `Funding_Distribution_ID` int(11) NOT NULL auto_increment,
  `FK_Funding_Segment__ID` int(11) default NULL,
  `Funding_Start` date default NULL,
  `Funding_End` date default NULL,
  PRIMARY KEY  (`Funding_Distribution_ID`),
  KEY `FK_Funding_Segment__ID` (`FK_Funding_Segment__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Funding_Distribution`
--


/*!40000 ALTER TABLE `Funding_Distribution` DISABLE KEYS */;
LOCK TABLES `Funding_Distribution` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Funding_Distribution` ENABLE KEYS */;

--
-- Table structure for table `Funding_Segment`
--

DROP TABLE IF EXISTS `Funding_Segment`;
CREATE TABLE `Funding_Segment` (
  `Funding_Segment_ID` int(11) NOT NULL auto_increment,
  `FK_Funding__ID` int(11) default NULL,
  `Amount` int(11) default NULL,
  `Currency` enum('US','Canadian') default NULL,
  `Funding_Segment_Notes` text,
  PRIMARY KEY  (`Funding_Segment_ID`),
  KEY `FK_Funding__ID` (`FK_Funding__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Funding_Segment`
--


/*!40000 ALTER TABLE `Funding_Segment` DISABLE KEYS */;
LOCK TABLES `Funding_Segment` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Funding_Segment` ENABLE KEYS */;

--
-- Table structure for table `GCOS_Config`
--

DROP TABLE IF EXISTS `GCOS_Config`;
CREATE TABLE `GCOS_Config` (
  `GCOS_Config_ID` int(11) NOT NULL auto_increment,
  `Template_Name` varchar(34) NOT NULL default '',
  `Template_Class` enum('Sample','Experiment') NOT NULL default 'Sample',
  PRIMARY KEY  (`GCOS_Config_ID`),
  UNIQUE KEY `Template_Name` (`Template_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `GCOS_Config`
--


/*!40000 ALTER TABLE `GCOS_Config` DISABLE KEYS */;
LOCK TABLES `GCOS_Config` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `GCOS_Config` ENABLE KEYS */;

--
-- Table structure for table `GCOS_Config_Record`
--

DROP TABLE IF EXISTS `GCOS_Config_Record`;
CREATE TABLE `GCOS_Config_Record` (
  `GCOS_Config_Record_ID` int(11) NOT NULL auto_increment,
  `Attribute_Type` enum('Field','Prep') default NULL,
  `Attribute_Name` char(50) NOT NULL default '',
  `Attribute_Table` char(50) default '',
  `Attribute_Step` char(50) default '',
  `Attribute_Field` char(50) NOT NULL default '',
  `FK_GCOS_Config__ID` int(11) NOT NULL default '0',
  `Attribute_Default` char(50) default NULL,
  PRIMARY KEY  (`GCOS_Config_Record_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `GCOS_Config_Record`
--


/*!40000 ALTER TABLE `GCOS_Config_Record` DISABLE KEYS */;
LOCK TABLES `GCOS_Config_Record` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `GCOS_Config_Record` ENABLE KEYS */;

--
-- Table structure for table `Gel`
--

DROP TABLE IF EXISTS `Gel`;
CREATE TABLE `Gel` (
  `Gel_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_Plate__ID` int(11) NOT NULL default '0',
  `Gel_Date` datetime NOT NULL default '0000-00-00 00:00:00',
  `FK_Employee__ID` int(4) default NULL,
  `Gel_Directory` varchar(80) NOT NULL default '',
  `Status` enum('Active','Failed','On_hold','lane tracking','run bandleader','bandleader completed','bandleader failure','finished','sizes imported','size importing failure') default 'Active',
  `Gel_Comments` text,
  `Bandleader_Version` varchar(40) default '2.3.5',
  `Agarose_Percent` float(10,2) default '1.20',
  `File_Extension_Type` enum('sizes','none') default 'none',
  PRIMARY KEY  (`Gel_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_Plate__ID` (`FK_Plate__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Gel`
--


/*!40000 ALTER TABLE `Gel` DISABLE KEYS */;
LOCK TABLES `Gel` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Gel` ENABLE KEYS */;

--
-- Table structure for table `GelAnalysis`
--

DROP TABLE IF EXISTS `GelAnalysis`;
CREATE TABLE `GelAnalysis` (
  `GelAnalysis_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) default NULL,
  `GelAnalysis_DateTime` datetime default NULL,
  `Bandleader_Version` varchar(15) default NULL,
  `FK_Status__ID` int(11) default NULL,
  `Gel_Name` varchar(40) default NULL,
  `Validation_Override` enum('NO','YES') NOT NULL default 'NO',
  `Swap_Check` enum('Passed','Failed','Pending') NOT NULL default 'Pending',
  `Self_Check` enum('Passed','Failed','Pending') NOT NULL default 'Pending',
  `Cross_Check` enum('Passed','Failed','Pending') NOT NULL default 'Pending',
  PRIMARY KEY  (`GelAnalysis_ID`),
  UNIQUE KEY `FK_Run__ID` (`FK_Run__ID`),
  KEY `FK_GelRun__ID` (`FK_Run__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `GelAnalysis`
--


/*!40000 ALTER TABLE `GelAnalysis` DISABLE KEYS */;
LOCK TABLES `GelAnalysis` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `GelAnalysis` ENABLE KEYS */;

--
-- Table structure for table `GelRun`
--

DROP TABLE IF EXISTS `GelRun`;
CREATE TABLE `GelRun` (
  `GelRun_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) default NULL,
  `FKPoured_Employee__ID` int(11) default NULL,
  `FKComb_Equipment__ID` int(11) default NULL,
  `FKAgarose_Solution__ID` int(11) default NULL,
  `FKAgarosePour_Equipment__ID` int(11) default NULL,
  `Agarose_Percentage` varchar(5) default NULL,
  `File_Extension_Type` enum('sizes','none') default NULL,
  `GelRun_Type` enum('Sizing Gel','Other') default NULL,
  `FKGelBox_Equipment__ID` int(11) default NULL,
  PRIMARY KEY  (`GelRun_ID`),
  KEY `FK_Run__ID` (`FK_Run__ID`),
  KEY `FKPoured_Employee__ID` (`FKPoured_Employee__ID`),
  KEY `FKComb_Equipment__ID` (`FKComb_Equipment__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `GelRun`
--


/*!40000 ALTER TABLE `GelRun` DISABLE KEYS */;
LOCK TABLES `GelRun` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `GelRun` ENABLE KEYS */;

--
-- Table structure for table `Genechip`
--

DROP TABLE IF EXISTS `Genechip`;
CREATE TABLE `Genechip` (
  `Genechip_ID` int(11) NOT NULL auto_increment,
  `FK_Microarray__ID` int(11) default NULL,
  `FK_Genechip_Type__ID` int(11) NOT NULL default '0',
  `External_Barcode` char(100) NOT NULL default '',
  PRIMARY KEY  (`Genechip_ID`),
  KEY `microarray_id` (`FK_Microarray__ID`),
  KEY `extbarcode` (`External_Barcode`),
  KEY `genechip_type_id` (`FK_Genechip_Type__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Genechip`
--


/*!40000 ALTER TABLE `Genechip` DISABLE KEYS */;
LOCK TABLES `Genechip` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Genechip` ENABLE KEYS */;

--
-- Table structure for table `GenechipAnalysis`
--

DROP TABLE IF EXISTS `GenechipAnalysis`;
CREATE TABLE `GenechipAnalysis` (
  `GenechipAnalysis_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `GenechipAnalysis_DateTime` datetime default NULL,
  `Analysis_Type` enum('Mapping','Expression','Universal') default NULL,
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `Artifact` enum('No','Yes') default 'No',
  PRIMARY KEY  (`GenechipAnalysis_ID`),
  KEY `run_id` (`FK_Run__ID`),
  KEY `sample_id` (`FK_Sample__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `GenechipAnalysis`
--


/*!40000 ALTER TABLE `GenechipAnalysis` DISABLE KEYS */;
LOCK TABLES `GenechipAnalysis` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `GenechipAnalysis` ENABLE KEYS */;

--
-- Table structure for table `GenechipAnalysis_Attribute`
--

DROP TABLE IF EXISTS `GenechipAnalysis_Attribute`;
CREATE TABLE `GenechipAnalysis_Attribute` (
  `FK_GenechipAnalysis__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text NOT NULL,
  `GenechipAnalysis_Attribute_ID` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`GenechipAnalysis_Attribute_ID`),
  UNIQUE KEY `exp_attribute` (`FK_GenechipAnalysis__ID`,`FK_Attribute__ID`),
  KEY `FK_GenechipAnalysis__ID` (`FK_GenechipAnalysis__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `GenechipAnalysis_Attribute`
--


/*!40000 ALTER TABLE `GenechipAnalysis_Attribute` DISABLE KEYS */;
LOCK TABLES `GenechipAnalysis_Attribute` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `GenechipAnalysis_Attribute` ENABLE KEYS */;

--
-- Table structure for table `GenechipExpAnalysis`
--

DROP TABLE IF EXISTS `GenechipExpAnalysis`;
CREATE TABLE `GenechipExpAnalysis` (
  `GenechipExpAnalysis_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `Absent_Probe_Sets` float(10,3) default NULL,
  `Absent_Probe_Sets_Percent` decimal(5,2) default NULL,
  `Algorithm` char(40) default NULL,
  `Alpha1` float(10,3) default NULL,
  `Alpha2` float(10,3) default NULL,
  `Avg_A_Signal` float(10,3) default NULL,
  `Avg_Background` float(10,3) default NULL,
  `Avg_CentralMinus` float(10,3) default NULL,
  `Avg_CornerMinus` float(10,3) default NULL,
  `Avg_CornerPlus` float(10,3) default NULL,
  `Avg_M_Signal` float(10,3) default NULL,
  `Avg_Noise` float(10,3) default NULL,
  `Avg_P_Signal` float(10,3) default NULL,
  `Avg_Signal` float(10,3) default NULL,
  `Controls` char(40) default NULL,
  `Count_CentralMinus` float(10,3) default NULL,
  `Count_CornerMinus` float(10,3) default NULL,
  `Count_CornerPlus` float(10,3) default NULL,
  `Marginal_Probe_Sets` float(10,3) default NULL,
  `Marginal_Probe_Sets_Percent` decimal(5,2) default NULL,
  `Max_Background` float(10,3) default NULL,
  `Max_Noise` float(10,3) default NULL,
  `Min_Background` float(10,3) default NULL,
  `Min_Noise` float(10,3) default NULL,
  `Noise_RawQ` float(10,3) default NULL,
  `Norm_Factor` float(10,3) default NULL,
  `Present_Probe_Sets` float(10,3) default NULL,
  `Present_Probe_Sets_Percent` decimal(5,2) default NULL,
  `Probe_Pair_Thr` float(10,3) default NULL,
  `Scale_Factor` float(10,3) default NULL,
  `Std_Background` float(10,3) default NULL,
  `Std_Noise` float(10,3) default NULL,
  `Tau` float(10,3) default NULL,
  `TGT` float(10,3) default NULL,
  `Total_Probe_Sets` float(10,3) default NULL,
  PRIMARY KEY  (`GenechipExpAnalysis_ID`),
  KEY `run_id` (`FK_Run__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `GenechipExpAnalysis`
--


/*!40000 ALTER TABLE `GenechipExpAnalysis` DISABLE KEYS */;
LOCK TABLES `GenechipExpAnalysis` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `GenechipExpAnalysis` ENABLE KEYS */;

--
-- Table structure for table `GenechipMapAnalysis`
--

DROP TABLE IF EXISTS `GenechipMapAnalysis`;
CREATE TABLE `GenechipMapAnalysis` (
  `GenechipMapAnalysis_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `Total_SNP` int(11) default NULL,
  `Total_QC_Probes` int(11) default NULL,
  `Called_Gender` char(2) default NULL,
  `SNP_Call_Percent` decimal(5,2) default NULL,
  `AA_Call_Percent` decimal(5,2) default NULL,
  `AB_Call_Percent` decimal(5,2) default NULL,
  `BB_Call_Percent` decimal(5,2) default NULL,
  `QC_AFFX_5Q_123` decimal(10,2) default NULL,
  `QC_AFFX_5Q_456` decimal(10,2) default NULL,
  `QC_AFFX_5Q_789` decimal(10,2) default NULL,
  `QC_AFFX_5Q_ABC` decimal(10,2) default NULL,
  `QC_MCR_Percent` decimal(5,2) default NULL,
  `QC_MDR_Percent` decimal(5,2) default NULL,
  `SNP1` char(10) default NULL,
  `SNP2` char(10) default NULL,
  `SNP3` char(10) default NULL,
  `SNP4` char(10) default NULL,
  `SNP5` char(10) default NULL,
  `SNP6` char(10) default NULL,
  `SNP7` char(10) default NULL,
  `SNP8` char(10) default NULL,
  `SNP9` char(10) default NULL,
  `SNP10` char(10) default NULL,
  `SNP11` char(10) default NULL,
  `SNP12` char(10) default NULL,
  `SNP13` char(10) default NULL,
  `SNP14` char(10) default NULL,
  `SNP15` char(10) default NULL,
  `SNP16` char(10) default NULL,
  `SNP17` char(10) default NULL,
  `SNP18` char(10) default NULL,
  `SNP19` char(10) default NULL,
  `SNP20` char(10) default NULL,
  `SNP21` char(10) default NULL,
  `SNP22` char(10) default NULL,
  `SNP23` char(10) default NULL,
  `SNP24` char(10) default NULL,
  `SNP25` char(10) default NULL,
  `SNP26` char(10) default NULL,
  `SNP27` char(10) default NULL,
  `SNP28` char(10) default NULL,
  `SNP29` char(10) default NULL,
  `SNP30` char(10) default NULL,
  `SNP31` char(10) default NULL,
  `SNP32` char(10) default NULL,
  `SNP33` char(10) default NULL,
  `SNP34` char(10) default NULL,
  `SNP35` char(10) default NULL,
  `SNP36` char(10) default NULL,
  `SNP37` char(10) default NULL,
  `SNP38` char(10) default NULL,
  `SNP39` char(10) default NULL,
  `SNP40` char(10) default NULL,
  `SNP41` char(10) default NULL,
  `SNP42` char(10) default NULL,
  `SNP43` char(10) default NULL,
  `SNP44` char(10) default NULL,
  `SNP45` char(10) default NULL,
  `SNP46` char(10) default NULL,
  `SNP47` char(10) default NULL,
  `SNP48` char(10) default NULL,
  `SNP49` char(10) default NULL,
  `SNP50` char(10) default NULL,
  PRIMARY KEY  (`GenechipMapAnalysis_ID`),
  KEY `run_id` (`FK_Run__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `GenechipMapAnalysis`
--


/*!40000 ALTER TABLE `GenechipMapAnalysis` DISABLE KEYS */;
LOCK TABLES `GenechipMapAnalysis` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `GenechipMapAnalysis` ENABLE KEYS */;

--
-- Table structure for table `GenechipRun`
--

DROP TABLE IF EXISTS `GenechipRun`;
CREATE TABLE `GenechipRun` (
  `GenechipRun_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `FKScanner_Equipment__ID` int(11) default NULL,
  `CEL_file` char(100) default NULL,
  `DAT_file` char(100) default NULL,
  `CHP_file` char(100) default NULL,
  `FKOven_Equipment__ID` int(11) default NULL,
  `FKSample_GCOS_Config__ID` int(11) NOT NULL default '0',
  `FKExperiment_GCOS_Config__ID` int(11) NOT NULL default '0',
  `Invoiced` enum('No','Yes') default 'No',
  PRIMARY KEY  (`GenechipRun_ID`),
  KEY `run` (`FK_Run__ID`),
  KEY `FKSample_GCOS_Config__ID` (`FKSample_GCOS_Config__ID`),
  KEY `FKExperiment_GCOS_Config__ID` (`FKExperiment_GCOS_Config__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `GenechipRun`
--


/*!40000 ALTER TABLE `GenechipRun` DISABLE KEYS */;
LOCK TABLES `GenechipRun` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `GenechipRun` ENABLE KEYS */;

--
-- Table structure for table `Genechip_Experiment`
--

DROP TABLE IF EXISTS `Genechip_Experiment`;
CREATE TABLE `Genechip_Experiment` (
  `Genechip_Experiment_ID` int(11) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) NOT NULL default '0',
  `Chip_Type` enum('HG-U133A','HG-U133') default NULL,
  `Experiment_Count` int(11) NOT NULL default '0',
  `Data_Subdirectory` varchar(80) NOT NULL default '',
  `Comments` text,
  `FK_Equipment__ID` int(11) NOT NULL default '0',
  `FK_Employee__ID` int(11) NOT NULL default '0',
  `Experiment_DateTime` date default NULL,
  `Experiment_Name` varchar(80) NOT NULL default '',
  `Genechip_Barcode` varchar(80) NOT NULL default '',
  PRIMARY KEY  (`Genechip_Experiment_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Genechip_Experiment`
--


/*!40000 ALTER TABLE `Genechip_Experiment` DISABLE KEYS */;
LOCK TABLES `Genechip_Experiment` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Genechip_Experiment` ENABLE KEYS */;

--
-- Table structure for table `Genechip_Type`
--

DROP TABLE IF EXISTS `Genechip_Type`;
CREATE TABLE `Genechip_Type` (
  `Genechip_Type_ID` int(11) NOT NULL auto_increment,
  `Array_Type` enum('Expression','Mapping','Resequencing','Universal') NOT NULL default 'Expression',
  `Genechip_Type_Name` char(50) default NULL,
  `Sub_Array_Type` enum('','500K Mapping','250K Mapping','100K Mapping','10K Mapping','Other Mapping','Human Expression','Rat Expression','Mouse Expression','Yeast Expression','Other Expression','Mouse Tiling') default NULL,
  PRIMARY KEY  (`Genechip_Type_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Genechip_Type`
--


/*!40000 ALTER TABLE `Genechip_Type` DISABLE KEYS */;
LOCK TABLES `Genechip_Type` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Genechip_Type` ENABLE KEYS */;

--
-- Table structure for table `Genetic_Code`
--

DROP TABLE IF EXISTS `Genetic_Code`;
CREATE TABLE `Genetic_Code` (
  `Genetic_Code_ID` int(11) NOT NULL default '0',
  `Genetic_Code_Abbr` char(3) NOT NULL default '',
  `Genetic_Code_Name` varchar(80) default NULL,
  `CDE` text,
  `Starts` text,
  PRIMARY KEY  (`Genetic_Code_ID`),
  KEY `Genetic_Code_Name` (`Genetic_Code_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Genetic_Code`
--


/*!40000 ALTER TABLE `Genetic_Code` DISABLE KEYS */;
LOCK TABLES `Genetic_Code` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Genetic_Code` ENABLE KEYS */;

--
-- Table structure for table `Genomic_Library`
--

DROP TABLE IF EXISTS `Genomic_Library`;
CREATE TABLE `Genomic_Library` (
  `Genomic_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Sequencing_Library__ID` int(11) NOT NULL default '0',
  `Vector_Type` enum('Unspecified','Plasmid','Fosmid','Cosmid','BAC') NOT NULL default 'Plasmid',
  `FKInsertSite_Enzyme__ID` int(11) default NULL,
  `Insert_Site_Enzyme` varchar(40) NOT NULL default '',
  `DNA_Shearing_Method` enum('Unspecified','Mechanical','Enzyme') NOT NULL default 'Unspecified',
  `FKDNAShearing_Enzyme__ID` int(11) default NULL,
  `DNA_Shearing_Enzyme` varchar(40) default NULL,
  `384_Well_Plates_To_Pick` int(11) NOT NULL default '0',
  `Genomic_Library_Type` enum('Shotgun','BAC','Fosmid') default NULL,
  `Genomic_Coverage` float(5,2) default NULL,
  `Recombinant_Clones` int(11) default NULL,
  `Non_Recombinant_Clones` int(11) default NULL,
  `Blue_White_Selection` enum('Yes','No') NOT NULL default 'No',
  PRIMARY KEY  (`Genomic_Library_ID`),
  KEY `lib_id` (`FK_Sequencing_Library__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Genomic_Library`
--


/*!40000 ALTER TABLE `Genomic_Library` DISABLE KEYS */;
LOCK TABLES `Genomic_Library` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Genomic_Library` ENABLE KEYS */;

--
-- Table structure for table `Goal`
--

DROP TABLE IF EXISTS `Goal`;
CREATE TABLE `Goal` (
  `Goal_ID` int(11) NOT NULL auto_increment,
  `Goal_Name` varchar(255) default NULL,
  `Goal_Description` text,
  `Goal_Query` text,
  `Goal_Tables` varchar(255) default NULL,
  `Goal_Count` varchar(255) default NULL,
  `Goal_Condition` varchar(255) default NULL,
  PRIMARY KEY  (`Goal_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Goal`
--


/*!40000 ALTER TABLE `Goal` DISABLE KEYS */;
LOCK TABLES `Goal` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Goal` ENABLE KEYS */;

--
-- Table structure for table `GrantApplication`
--

DROP TABLE IF EXISTS `GrantApplication`;
CREATE TABLE `GrantApplication` (
  `GrantApplication_ID` int(11) NOT NULL auto_increment,
  `Title` char(80) default NULL,
  `FKContact_Employee__ID` int(11) default NULL,
  `AppliedFor` float default NULL,
  `Duration` int(11) default NULL,
  `Duration_Units` enum('days','months','years') default NULL,
  `Grant_Type` char(40) default NULL,
  `ApplicationStatus` enum('Awarded','Declined','Applied') default NULL,
  `Award` float default NULL,
  `Currency` enum('US','Canadian') default NULL,
  `Application_Date` date default NULL,
  `Application_Number` int(11) default NULL,
  `Funding_Frequency` char(40) default NULL,
  PRIMARY KEY  (`GrantApplication_ID`),
  KEY `FKContact_Employee__ID` (`FKContact_Employee__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `GrantApplication`
--


/*!40000 ALTER TABLE `GrantApplication` DISABLE KEYS */;
LOCK TABLES `GrantApplication` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `GrantApplication` ENABLE KEYS */;

--
-- Table structure for table `GrantDistribution`
--

DROP TABLE IF EXISTS `GrantDistribution`;
CREATE TABLE `GrantDistribution` (
  `GrantDistribution_ID` int(11) NOT NULL auto_increment,
  `FK_GrantApplication__ID` int(11) default NULL,
  `StartDate` date default NULL,
  `EndDate` date default NULL,
  `Amount` float default NULL,
  `Currency` enum('Canadian','US') default NULL,
  `AwardStatus` enum('Spent','Received','Awarded','Declined','Pending','TBD') default NULL,
  `Spent` float default NULL,
  `SpentAsOf` date default NULL,
  PRIMARY KEY  (`GrantDistribution_ID`),
  KEY `FK_GrantApplication__ID` (`FK_GrantApplication__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `GrantDistribution`
--


/*!40000 ALTER TABLE `GrantDistribution` DISABLE KEYS */;
LOCK TABLES `GrantDistribution` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `GrantDistribution` ENABLE KEYS */;

--
-- Table structure for table `Grp`
--

DROP TABLE IF EXISTS `Grp`;
CREATE TABLE `Grp` (
  `Grp_ID` int(11) NOT NULL auto_increment,
  `Grp_Name` varchar(80) NOT NULL default '',
  `FK_Department__ID` int(11) NOT NULL default '0',
  `Access` enum('Lab','Admin','Guest','Report','Bioinformatics') NOT NULL default 'Guest',
  PRIMARY KEY  (`Grp_ID`),
  KEY `dept_id` (`FK_Department__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Grp`
--


/*!40000 ALTER TABLE `Grp` DISABLE KEYS */;
LOCK TABLES `Grp` WRITE;
INSERT INTO `Grp` VALUES (1,'LIMS Admin',1,'Admin'),(2,'Sequencing Base',2,'Guest'),(4,'Sequencing Production',2,'Lab'),(5,'Sequencing TechD',2,'Lab'),(6,'Sequencing Project Admin',2,'Report');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Grp` ENABLE KEYS */;

--
-- Table structure for table `GrpDBTable`
--

DROP TABLE IF EXISTS `GrpDBTable`;
CREATE TABLE `GrpDBTable` (
  `GrpDBTable_ID` int(11) NOT NULL auto_increment,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FK_DBTable__ID` int(11) NOT NULL default '0',
  `Permissions` set('R','W','U','D','O') NOT NULL default 'R',
  PRIMARY KEY  (`GrpDBTable_ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_DBTable__ID` (`FK_DBTable__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `GrpDBTable`
--


/*!40000 ALTER TABLE `GrpDBTable` DISABLE KEYS */;
LOCK TABLES `GrpDBTable` WRITE;
INSERT INTO `GrpDBTable` VALUES (1,10,1,'R,W,U,D'),(2,6,1,'R,W,U,D'),(3,12,1,'R,W,U,D'),(4,7,2,'R,W,U,D'),(5,16,2,'R'),(6,11,2,'R,W,U,D'),(7,7,3,'R,W,U,D'),(8,16,3,'R'),(9,11,3,'R,W,U,D'),(10,12,3,'R,W,U,D'),(11,7,4,'R,W,U,D'),(12,4,105,'R,W,U'),(13,10,17,'R,W,U,D'),(14,6,17,'R,W,U,D'),(15,12,17,'R,W,U,D'),(16,5,18,'R,W,U'),(17,14,18,'R,W,U'),(18,17,18,'R,W,U'),(19,7,18,'R,W,U'),(20,11,18,'R,W,U'),(21,4,18,'R,W,U'),(22,2,18,'R,W,U'),(23,8,18,'R,W,U'),(24,15,18,'R,W,U'),(25,9,18,'R,W,U'),(27,6,18,'R,W,U'),(28,16,18,'R,W,U'),(29,12,18,'R,W,U'),(30,13,18,'R,W,U'),(31,10,18,'R,W,U'),(32,10,24,'R,W,U,D'),(33,6,24,'R,W,U,D'),(34,12,24,'R,W,U,D'),(35,4,24,'R,W,U'),(36,14,24,'R,W,U'),(37,9,24,'R,W,U'),(38,7,29,'R,W,U,D'),(39,7,30,'R,W,U'),(40,16,30,'R'),(41,11,30,'R,W,U'),(42,7,110,'R,W,U,D'),(43,16,110,'R'),(44,11,110,'R,W,U,D'),(45,7,31,'R,W,U,D'),(46,16,31,'R'),(47,11,31,'R,W,U,D'),(48,12,31,'R,W,U,D'),(49,10,36,'R,W,U,D'),(50,6,36,'R,W,U,D'),(51,12,36,'R,W,U,D'),(52,7,92,'R,W,U,D'),(53,7,119,'R,W,U,D'),(54,16,119,'R'),(55,11,119,'R,W,U,D'),(56,7,120,'R,W,U,D'),(57,16,120,'R'),(58,11,120,'R,W,U,D'),(59,7,121,'R,W,U,D'),(60,16,121,'R'),(61,11,121,'R,W,U,D'),(62,5,94,'R,W,U'),(63,14,94,'R,W,U'),(64,17,94,'R,W,U'),(65,7,94,'R,W,U'),(66,11,94,'R,W,U'),(67,4,94,'R,W,U'),(68,2,94,'R,W,U'),(69,8,94,'R,W,U'),(70,15,94,'R,W,U'),(71,9,94,'R,W,U'),(73,6,94,'R,W,U'),(74,16,94,'R,W,U'),(75,12,94,'R,W,U'),(76,13,94,'R,W,U'),(77,10,94,'R,W,U'),(78,5,123,'R,W,U'),(79,14,123,'R,W,U'),(80,17,123,'R,W,U'),(81,7,123,'R,W,U'),(82,11,123,'R,W,U'),(83,4,123,'R,W,U'),(84,2,123,'R,W,U'),(85,8,123,'R,W,U'),(86,15,123,'R,W,U'),(87,9,123,'R,W,U'),(89,6,123,'R,W,U'),(90,16,123,'R,W,U'),(91,12,123,'R,W,U'),(92,13,123,'R,W,U'),(93,10,123,'R,W,U'),(94,5,124,'R,W,U'),(95,14,124,'R,W,U'),(96,17,124,'R,W,U'),(97,7,124,'R,W,U'),(98,11,124,'R,W,U'),(99,4,124,'R,W,U'),(100,2,124,'R,W,U'),(101,8,124,'R,W,U'),(102,15,124,'R,W,U'),(103,9,124,'R,W,U'),(105,6,124,'R,W,U'),(106,16,124,'R,W,U'),(107,12,124,'R,W,U'),(108,13,124,'R,W,U'),(109,10,124,'R,W,U'),(110,7,39,'R,W,U,D'),(111,16,39,'R'),(112,11,39,'R,W,U,D'),(113,7,40,'R,W,U,D'),(114,16,40,'R'),(115,11,40,'R,W,U,D'),(116,7,41,'R,W,U,D'),(117,4,125,'R,W,U,D'),(118,14,125,'R,W,U,D'),(119,9,125,'R,W,U,D'),(120,4,126,'R,W,U,D'),(121,7,87,'R,W,U,D'),(122,4,44,'R,W,U'),(123,14,44,'R,W,U'),(124,9,44,'R,W,U'),(125,5,46,'R,W,U'),(126,14,46,'R,W,U'),(127,17,46,'R,W,U'),(128,7,46,'R,W,U'),(129,11,46,'R,W,U'),(130,4,46,'R,W,U'),(131,2,46,'R,W,U'),(132,8,46,'R,W,U'),(133,15,46,'R,W,U'),(134,9,46,'R,W,U'),(136,6,46,'R,W,U'),(137,16,46,'R,W,U'),(138,12,46,'R,W,U'),(139,13,46,'R,W,U'),(140,10,46,'R,W,U'),(141,7,86,'R,W,U,D'),(142,4,48,'R,W,U,D'),(143,14,48,'R,W,U,D'),(144,9,48,'R,W,U,D'),(145,4,49,'R,W,U,D'),(146,4,50,'R,W,U'),(147,14,50,'R,W,U'),(148,9,50,'R,W,U'),(149,5,52,'R,W,U'),(150,14,52,'R,W,U'),(151,17,52,'R,W,U'),(152,7,52,'R,W,U'),(153,11,52,'R,W,U'),(154,4,52,'R,W,U'),(155,2,52,'R,W,U'),(156,8,52,'R,W,U'),(157,15,52,'R,W,U'),(158,9,52,'R,W,U'),(160,6,52,'R,W,U'),(161,16,52,'R,W,U'),(162,12,52,'R,W,U'),(163,13,52,'R,W,U'),(164,10,52,'R,W,U'),(165,12,54,'R,W,U,D'),(166,12,55,'R,W,U,D'),(167,10,56,'R,W,U'),(168,6,56,'R,W,U'),(169,12,56,'R,W,U,D'),(170,7,93,'R,W,U,D'),(171,7,57,'R,W,U,D'),(172,16,57,'R'),(173,11,57,'R,W,U,D'),(174,4,59,'R,W,O'),(175,14,59,'R,W,O'),(176,9,59,'R,W,O'),(177,7,59,'R,W,U,D'),(178,16,59,'R'),(179,11,59,'R,W,U,D'),(180,7,60,'R,W,U,D'),(181,4,128,'R,W,U'),(182,14,128,'R,W,U'),(183,9,128,'R,W,U'),(184,4,61,'R,W,U,D'),(185,14,61,'R,W,U,D'),(186,9,61,'R,W,U,D'),(187,4,11,'R,W,O'),(188,14,11,'R,W,O'),(189,9,11,'R,W,O'),(190,4,131,'R,W,U,D'),(191,14,131,'R,W,U,D'),(192,9,131,'R,W,U,D'),(193,4,132,'R,W,U'),(194,14,132,'R,W,U'),(195,9,132,'R,W,U'),(196,7,64,'R,W,U,D'),(197,17,64,'R,W,U'),(198,7,97,'R,W,U,D'),(199,17,97,'R,W,U'),(200,7,65,'R,W,U,D'),(201,12,65,'R,W,U,D'),(202,10,66,'R,W,U'),(203,6,66,'R,W,U'),(204,12,66,'R,W,U'),(205,4,136,'R,W,U,D'),(206,14,136,'R,W,U,D'),(207,9,136,'R,W,U,D'),(208,7,67,'R,W,U,D'),(209,16,67,'R'),(210,11,67,'R,W,U,D'),(211,7,68,'R,W,U,D'),(212,16,68,'R'),(213,11,68,'R,W,U,D'),(217,4,69,'R,W,U,D'),(218,14,69,'R,W,U,D'),(219,9,69,'R,W,U,D'),(220,4,70,'R,W,U'),(221,14,70,'R,W,U'),(222,9,70,'R,W,U'),(223,17,70,'R,W,U'),(224,4,140,'R,W,U'),(225,14,140,'R,W,U'),(226,9,140,'R,W,U'),(227,17,140,'R,W,U'),(228,7,71,'R,W,U,D'),(229,7,90,'R,W,U,D'),(230,7,72,'R,W,U,D'),(231,7,73,'R,W,U,D'),(232,4,142,'R,W,U'),(233,14,142,'R,W,U'),(234,9,142,'R,W,U'),(237,7,74,'R,W,U,D'),(238,7,143,'R,W,U,D'),(239,4,75,'R,W,U'),(240,14,75,'R,W,U'),(241,9,75,'R,W,U'),(242,12,75,'R,W,U'),(243,7,76,'R,W,U,D'),(244,16,76,'R'),(245,11,76,'R,W,U,D'),(246,12,76,'R,W,U,D'),(247,4,5,'R,W,U,D'),(248,14,5,'R,W,U,D'),(249,9,5,'R,W,U,D'),(250,12,5,'R,W,U,D'),(251,4,6,'R,W,U,D'),(252,12,6,'R,W,U,D'),(253,7,58,'R,W,U,D'),(254,16,58,'R'),(255,11,58,'R,W,U,D'),(256,7,7,'R,W,U,D'),(257,16,7,'R'),(258,11,7,'R,W,U,D'),(259,12,7,'R,W,U,D'),(260,4,7,'R,W,U'),(261,14,7,'R,W,U'),(262,9,7,'R,W,U'),(263,4,144,'R,W,U,D'),(264,14,144,'R,W,U,D'),(265,9,144,'R,W,U,D'),(266,4,89,'R,W'),(267,14,89,'R,W'),(268,9,89,'R,W'),(269,7,89,'R,W,U'),(270,16,89,'R,W'),(271,11,89,'R,W,U'),(272,4,145,'R,W'),(273,14,145,'R,W'),(274,9,145,'R,W'),(275,7,145,'R,W,U'),(276,16,145,'R'),(277,11,145,'R,W,U'),(278,5,78,'R,W,U'),(279,14,78,'R,W,U'),(280,17,78,'R,W,U'),(281,7,78,'R,W,U'),(282,11,78,'R,W,U'),(283,4,78,'R,W,U'),(284,2,78,'R,W,U'),(285,8,78,'R,W,U'),(286,15,78,'R,W,U'),(287,9,78,'R,W,U'),(289,6,78,'R,W,U'),(290,16,78,'R,W,U'),(291,12,78,'R,W,U'),(292,13,78,'R,W,U'),(293,10,78,'R,W,U'),(294,4,146,'R,W,U,D'),(295,4,79,'R,W,U,D'),(296,14,79,'R,W,U,D'),(297,9,79,'R,W,U,D'),(298,7,81,'R,W,U,D'),(299,7,82,'R,W,U,D'),(300,7,83,'R,W,U,D'),(301,16,83,'R'),(302,11,83,'R,W,U,D'),(303,12,83,'R,W,U,D'),(304,7,88,'R,W,U,D'),(305,7,91,'R,W,U,D'),(306,2,37,'R'),(307,4,37,'R,W,O'),(309,10,37,'R'),(310,5,37,'R'),(311,11,37,'R,W,U,D'),(312,6,37,'R'),(313,12,37,'R'),(314,7,37,'R,W,U,D'),(315,13,37,'R'),(316,8,37,'R'),(317,14,37,'R,W,O'),(318,9,37,'R,W,O'),(319,15,37,'R'),(320,16,37,'R'),(321,17,37,'R,W,O'),(322,2,39,'R'),(323,4,39,'R'),(325,10,39,'R'),(326,5,39,'R'),(327,6,39,'R'),(328,12,39,'R'),(329,13,39,'R'),(330,8,39,'R'),(331,14,39,'R'),(332,9,39,'R'),(333,15,39,'R'),(334,17,39,'R'),(335,2,140,'R'),(337,10,140,'R'),(338,5,140,'R'),(339,11,140,'R'),(340,6,140,'R'),(341,12,140,'R'),(342,7,140,'R'),(343,13,140,'R'),(344,8,140,'R'),(345,15,140,'R'),(346,16,140,'R'),(347,2,141,'R'),(348,4,141,'R'),(350,10,141,'R'),(351,5,141,'R'),(352,11,141,'R'),(353,6,141,'R'),(354,12,141,'R'),(355,7,141,'R'),(356,13,141,'R'),(357,8,141,'R'),(358,14,141,'R'),(359,9,141,'R'),(360,15,141,'R'),(361,16,141,'R'),(362,17,141,'R'),(363,2,142,'R'),(365,10,142,'R'),(366,5,142,'R'),(367,11,142,'R,W,U,D'),(368,6,142,'R'),(369,12,142,'R'),(370,7,142,'R,W,U,D'),(371,13,142,'R'),(372,8,142,'R'),(373,15,142,'R'),(374,16,142,'R'),(375,17,142,'R,W,U'),(376,2,143,'R'),(377,4,143,'R'),(379,10,143,'R'),(380,5,143,'R'),(381,11,143,'R,W,U,D'),(382,6,143,'R'),(383,12,143,'R'),(384,13,143,'R'),(385,8,143,'R'),(386,14,143,'R'),(387,9,143,'R'),(388,15,143,'R'),(389,16,143,'R'),(390,17,143,'R'),(391,2,144,'R'),(393,10,144,'R'),(394,5,144,'R'),(395,11,144,'R'),(396,6,144,'R'),(397,12,144,'R'),(398,7,144,'R'),(399,13,144,'R'),(400,8,144,'R'),(401,15,144,'R'),(402,16,144,'R'),(403,17,144,'R,W,U,D'),(404,2,145,'R'),(406,10,145,'R'),(407,5,145,'R'),(408,6,145,'R'),(409,12,145,'R'),(410,13,145,'R'),(411,8,145,'R'),(412,15,145,'R'),(413,17,145,'R'),(414,2,146,'R'),(416,10,146,'R'),(417,5,146,'R'),(418,11,146,'R'),(419,6,146,'R'),(420,12,146,'R'),(421,7,146,'R'),(422,13,146,'R'),(423,8,146,'R'),(424,14,146,'R'),(425,9,146,'R'),(426,15,146,'R'),(427,16,146,'R'),(428,17,146,'R'),(429,2,147,'R'),(430,4,147,'R'),(432,10,147,'R'),(433,5,147,'R'),(434,11,147,'R'),(435,6,147,'R'),(436,12,147,'R'),(437,7,147,'R'),(438,13,147,'R'),(439,8,147,'R'),(440,14,147,'R'),(441,9,147,'R'),(442,15,147,'R'),(443,16,147,'R'),(444,17,147,'R'),(461,2,40,'R'),(462,4,40,'R'),(464,10,40,'R'),(465,5,40,'R'),(466,6,40,'R'),(467,12,40,'R'),(468,13,40,'R'),(469,8,40,'R'),(470,14,40,'R'),(471,9,40,'R'),(472,15,40,'R'),(473,17,40,'R'),(474,2,41,'R'),(475,4,41,'R'),(477,10,41,'R'),(478,5,41,'R'),(479,11,41,'R,W,U,D'),(480,6,41,'R'),(481,12,41,'R'),(482,13,41,'R'),(483,8,41,'R'),(484,14,41,'R'),(485,9,41,'R'),(486,15,41,'R'),(487,16,41,'R'),(488,17,41,'R'),(489,2,42,'R'),(490,4,42,'R'),(492,10,42,'R'),(493,5,42,'R'),(494,11,42,'R'),(495,6,42,'R'),(496,12,42,'R'),(497,7,42,'R'),(498,13,42,'R'),(499,8,42,'R'),(500,14,42,'R'),(501,9,42,'R'),(502,15,42,'R'),(503,16,42,'R'),(504,17,42,'R'),(505,2,43,'R'),(506,4,43,'R'),(508,10,43,'R'),(509,5,43,'R'),(510,11,43,'R'),(511,6,43,'R'),(512,12,43,'R'),(513,7,43,'R'),(514,13,43,'R'),(515,8,43,'R'),(516,14,43,'R'),(517,9,43,'R'),(518,15,43,'R'),(519,16,43,'R'),(520,17,43,'R'),(521,2,44,'R'),(523,10,44,'R'),(524,5,44,'R'),(525,11,44,'R'),(526,6,44,'R'),(527,12,44,'R'),(528,7,44,'R'),(529,13,44,'R'),(530,8,44,'R'),(531,15,44,'R'),(532,16,44,'R'),(533,17,44,'R'),(534,2,45,'R'),(535,4,45,'R'),(537,10,45,'R'),(538,5,45,'R'),(539,11,45,'R'),(540,6,45,'R'),(541,12,45,'R'),(542,7,45,'R'),(543,13,45,'R'),(544,8,45,'R'),(545,14,45,'R'),(546,9,45,'R'),(547,15,45,'R'),(548,16,45,'R'),(549,17,45,'R'),(550,2,47,'R'),(551,4,47,'R'),(553,10,47,'R'),(554,5,47,'R'),(555,11,47,'R'),(556,6,47,'R'),(557,12,47,'R'),(558,7,47,'R'),(559,13,47,'R'),(560,8,47,'R'),(561,14,47,'R'),(562,9,47,'R'),(563,15,47,'R'),(564,16,47,'R'),(565,17,47,'R'),(566,2,48,'R'),(568,10,48,'R'),(569,5,48,'R'),(570,11,48,'R'),(571,6,48,'R'),(572,12,48,'R'),(573,7,48,'R'),(574,13,48,'R'),(575,8,48,'R'),(576,15,48,'R'),(577,16,48,'R'),(578,17,48,'R'),(579,2,49,'R'),(581,10,49,'R'),(582,5,49,'R'),(583,11,49,'R'),(584,6,49,'R'),(585,12,49,'R'),(586,7,49,'R'),(587,13,49,'R'),(588,8,49,'R'),(589,14,49,'R'),(590,9,49,'R'),(591,15,49,'R'),(592,16,49,'R'),(593,17,49,'R'),(594,2,1,'R'),(595,4,1,'R'),(597,5,1,'R'),(598,11,1,'R'),(599,7,1,'R'),(600,13,1,'R'),(601,8,1,'R'),(602,14,1,'R'),(603,9,1,'R'),(604,15,1,'R'),(605,16,1,'R'),(606,17,1,'R'),(607,2,2,'R'),(608,4,2,'R'),(610,10,2,'R'),(611,5,2,'R'),(612,6,2,'R'),(613,12,2,'R'),(614,13,2,'R'),(615,8,2,'R'),(616,14,2,'R'),(617,9,2,'R'),(618,15,2,'R'),(619,17,2,'R'),(620,2,3,'R'),(621,4,3,'R,W,U'),(623,10,3,'R'),(624,5,3,'R'),(625,6,3,'R'),(626,13,3,'R'),(627,8,3,'R'),(628,14,3,'R,W,U'),(629,9,3,'R,W,U'),(630,15,3,'R'),(631,17,3,'R'),(632,2,4,'R'),(633,4,4,'R'),(635,10,4,'R'),(636,5,4,'R'),(637,11,4,'R'),(638,6,4,'R'),(639,12,4,'R'),(640,13,4,'R'),(641,8,4,'R'),(642,14,4,'R'),(643,9,4,'R'),(644,15,4,'R'),(645,16,4,'R'),(646,17,4,'R'),(647,2,5,'R'),(649,10,5,'R'),(650,5,5,'R'),(651,11,5,'R'),(652,6,5,'R'),(653,7,5,'R'),(654,13,5,'R'),(655,8,5,'R'),(656,15,5,'R'),(657,16,5,'R'),(658,17,5,'R,W,U'),(659,2,6,'R'),(661,10,6,'R'),(662,5,6,'R'),(663,11,6,'R'),(664,6,6,'R'),(665,7,6,'R'),(666,13,6,'R'),(667,8,6,'R'),(668,14,6,'R,W,U,D'),(669,9,6,'R,W,U,D'),(670,15,6,'R'),(671,16,6,'R'),(672,17,6,'R,W,U'),(673,2,7,'R'),(675,10,7,'R'),(676,5,7,'R'),(677,6,7,'R'),(678,13,7,'R'),(679,8,7,'R'),(680,15,7,'R'),(681,17,7,'R,W,U'),(714,2,50,'R'),(716,10,50,'R'),(717,5,50,'R'),(718,11,50,'R'),(719,6,50,'R'),(720,12,50,'R'),(721,7,50,'R'),(722,13,50,'R'),(723,8,50,'R'),(724,15,50,'R'),(725,16,50,'R'),(726,17,50,'R'),(727,2,51,'R'),(728,4,51,'R'),(730,10,51,'R'),(731,5,51,'R'),(732,11,51,'R'),(733,6,51,'R'),(734,12,51,'R'),(735,7,51,'R'),(736,13,51,'R'),(737,8,51,'R'),(738,14,51,'R'),(739,9,51,'R'),(740,15,51,'R'),(741,16,51,'R'),(742,17,51,'R'),(743,2,53,'R'),(744,4,53,'R'),(746,10,53,'R'),(747,5,53,'R'),(748,11,53,'R'),(749,6,53,'R'),(750,12,53,'R'),(751,7,53,'R'),(752,13,53,'R'),(753,8,53,'R'),(754,14,53,'R'),(755,9,53,'R'),(756,15,53,'R'),(757,16,53,'R'),(758,17,53,'R'),(759,2,54,'R'),(760,4,54,'R'),(762,10,54,'R'),(763,5,54,'R'),(764,11,54,'R'),(765,6,54,'R'),(766,7,54,'R'),(767,13,54,'R'),(768,8,54,'R'),(769,14,54,'R'),(770,9,54,'R'),(771,15,54,'R'),(772,16,54,'R'),(773,17,54,'R'),(774,2,55,'R'),(775,4,55,'R'),(777,10,55,'R'),(778,5,55,'R'),(779,11,55,'R'),(780,6,55,'R'),(781,7,55,'R'),(782,13,55,'R'),(783,8,55,'R'),(784,14,55,'R'),(785,9,55,'R'),(786,15,55,'R'),(787,16,55,'R'),(788,17,55,'R'),(789,2,56,'R'),(790,4,56,'R'),(792,5,56,'R'),(793,11,56,'R,W,U,D'),(794,7,56,'R,W,U,D'),(795,13,56,'R'),(796,8,56,'R'),(797,14,56,'R'),(798,9,56,'R'),(799,15,56,'R'),(800,16,56,'R,W,U'),(801,17,56,'R'),(802,2,57,'R'),(803,4,57,'R'),(805,10,57,'R'),(806,5,57,'R'),(807,6,57,'R'),(808,12,57,'R'),(809,13,57,'R'),(810,8,57,'R'),(811,14,57,'R'),(812,9,57,'R'),(813,15,57,'R'),(814,17,57,'R'),(815,2,58,'R'),(816,4,58,'R'),(818,10,58,'R'),(819,5,58,'R'),(820,6,58,'R'),(821,12,58,'R'),(822,13,58,'R'),(823,8,58,'R'),(824,14,58,'R'),(825,9,58,'R'),(826,15,58,'R'),(827,17,58,'R'),(828,2,59,'R'),(830,10,59,'R'),(831,5,59,'R'),(832,6,59,'R'),(833,12,59,'R'),(834,13,59,'R'),(835,8,59,'R'),(836,15,59,'R'),(837,17,59,'R,W,O'),(838,2,60,'R'),(839,4,60,'R'),(841,10,60,'R'),(842,5,60,'R'),(843,11,60,'R,W,U,D'),(844,6,60,'R'),(845,12,60,'R'),(846,13,60,'R'),(847,8,60,'R'),(848,14,60,'R'),(849,9,60,'R'),(850,15,60,'R'),(851,16,60,'R'),(852,17,60,'R'),(853,2,61,'R'),(855,10,61,'R'),(856,5,61,'R'),(857,11,61,'R'),(858,6,61,'R'),(859,12,61,'R'),(860,7,61,'R'),(861,13,61,'R'),(862,8,61,'R'),(863,15,61,'R'),(864,16,61,'R'),(865,17,61,'R'),(866,2,62,'R'),(867,4,62,'R'),(869,10,62,'R'),(870,5,62,'R'),(871,11,62,'R'),(872,6,62,'R'),(873,12,62,'R'),(874,7,62,'R'),(875,13,62,'R'),(876,8,62,'R'),(877,14,62,'R'),(878,9,62,'R'),(879,15,62,'R'),(880,16,62,'R'),(881,17,62,'R'),(898,2,64,'R'),(899,4,64,'R'),(901,10,64,'R'),(902,5,64,'R'),(903,11,64,'R,W,U,D'),(904,6,64,'R'),(905,12,64,'R'),(906,13,64,'R'),(907,8,64,'R'),(908,14,64,'R'),(909,9,64,'R'),(910,15,64,'R'),(911,16,64,'R'),(912,2,65,'R'),(913,4,65,'R'),(915,10,65,'R'),(916,5,65,'R'),(917,11,65,'R'),(918,6,65,'R'),(919,13,65,'R'),(920,8,65,'R'),(921,14,65,'R'),(922,9,65,'R'),(923,15,65,'R'),(924,16,65,'R'),(925,17,65,'R'),(926,2,66,'R'),(927,4,66,'R'),(929,5,66,'R'),(930,11,66,'R'),(931,7,66,'R'),(932,13,66,'R'),(933,8,66,'R'),(934,14,66,'R'),(935,9,66,'R'),(936,15,66,'R'),(937,16,66,'R'),(938,17,66,'R'),(939,2,67,'R'),(940,4,67,'R'),(942,10,67,'R'),(943,5,67,'R'),(944,6,67,'R'),(945,12,67,'R'),(946,13,67,'R'),(947,8,67,'R'),(948,14,67,'R'),(949,9,67,'R'),(950,15,67,'R'),(951,17,67,'R'),(952,2,68,'R'),(953,4,68,'R'),(955,10,68,'R'),(956,5,68,'R'),(957,6,68,'R'),(958,12,68,'R'),(959,13,68,'R'),(960,8,68,'R'),(961,14,68,'R'),(962,9,68,'R'),(963,15,68,'R'),(964,17,68,'R'),(965,2,69,'R'),(967,10,69,'R'),(968,5,69,'R'),(969,11,69,'R'),(970,6,69,'R'),(971,12,69,'R'),(972,7,69,'R'),(973,13,69,'R'),(974,8,69,'R'),(975,15,69,'R'),(976,16,69,'R'),(977,17,69,'R'),(978,2,70,'R'),(980,10,70,'R'),(981,5,70,'R'),(982,11,70,'R'),(983,6,70,'R'),(984,12,70,'R'),(985,7,70,'R'),(986,13,70,'R'),(987,8,70,'R'),(988,15,70,'R'),(989,16,70,'R'),(990,2,71,'R'),(991,4,71,'R'),(993,10,71,'R'),(994,5,71,'R'),(995,11,71,'R'),(996,6,71,'R'),(997,12,71,'R'),(998,13,71,'R'),(999,8,71,'R'),(1000,14,71,'R'),(1001,9,71,'R'),(1002,15,71,'R'),(1003,16,71,'R'),(1004,17,71,'R'),(1005,2,72,'R'),(1006,4,72,'R'),(1008,10,72,'R'),(1009,5,72,'R'),(1010,11,72,'R'),(1011,6,72,'R'),(1012,12,72,'R'),(1013,13,72,'R'),(1014,8,72,'R'),(1015,14,72,'R'),(1016,9,72,'R'),(1017,15,72,'R'),(1018,16,72,'R'),(1019,17,72,'R'),(1020,2,73,'R'),(1021,4,73,'R'),(1023,10,73,'R'),(1024,5,73,'R'),(1025,11,73,'R'),(1026,6,73,'R'),(1027,12,73,'R'),(1028,13,73,'R'),(1029,8,73,'R'),(1030,14,73,'R'),(1031,9,73,'R'),(1032,15,73,'R'),(1033,16,73,'R'),(1034,17,73,'R'),(1035,2,74,'R'),(1036,4,74,'R'),(1038,10,74,'R'),(1039,5,74,'R'),(1040,11,74,'R'),(1041,6,74,'R'),(1042,12,74,'R'),(1043,13,74,'R'),(1044,8,74,'R'),(1045,14,74,'R'),(1046,9,74,'R'),(1047,15,74,'R'),(1048,16,74,'R'),(1049,17,74,'R'),(1050,2,75,'R'),(1052,10,75,'R'),(1053,5,75,'R'),(1054,11,75,'R'),(1055,6,75,'R'),(1056,7,75,'R'),(1057,13,75,'R'),(1058,8,75,'R'),(1059,15,75,'R'),(1060,16,75,'R'),(1061,17,75,'R'),(1062,2,76,'R'),(1063,4,76,'R'),(1065,10,76,'R'),(1066,5,76,'R'),(1067,6,76,'R'),(1068,13,76,'R'),(1069,8,76,'R'),(1070,14,76,'R'),(1071,9,76,'R'),(1072,15,76,'R'),(1073,17,76,'R'),(1074,2,100,'R'),(1075,4,100,'R'),(1076,2,208,'R,W'),(1077,4,208,'R,W'),(1078,6,208,'R,W'),(1079,5,208,'R,W'),(1080,2,89,'R,W'),(1081,6,89,'R,W'),(1082,5,89,'R,W'),(1083,2,201,'R,W,U'),(1084,4,201,'R,W,U'),(1085,6,201,'R,W,U'),(1086,5,201,'R,W,U'),(1087,2,234,'R,W'),(1088,4,234,'R,W'),(1089,6,234,'R,W'),(1090,5,234,'R,W'),(1091,6,127,'R'),(1092,4,127,'R'),(1093,2,127,'R'),(1094,5,127,'R'),(1095,6,32,'R'),(1096,4,32,'R'),(1097,2,32,'R'),(1098,5,32,'R'),(1099,6,276,'R'),(1100,4,276,'R'),(1101,2,276,'R'),(1102,5,276,'R'),(1103,6,90,'R'),(1104,4,90,'R'),(1105,2,90,'R'),(1106,5,90,'R'),(1107,6,206,'R'),(1108,4,206,'R'),(1109,2,206,'R'),(1110,5,206,'R'),(1111,6,118,'R'),(1112,4,118,'R'),(1113,2,118,'R'),(1114,5,118,'R'),(1115,6,102,'R'),(1116,4,102,'R'),(1117,2,102,'R'),(1118,5,102,'R'),(1119,6,84,'R'),(1120,4,84,'R'),(1121,2,84,'R'),(1122,5,84,'R'),(1123,6,233,'R'),(1124,4,233,'R'),(1125,2,233,'R'),(1126,5,233,'R'),(1127,6,259,'R'),(1128,4,259,'R'),(1129,2,259,'R'),(1130,5,259,'R'),(1131,6,194,'R'),(1132,4,194,'R'),(1133,2,194,'R'),(1134,5,194,'R'),(1135,6,220,'R'),(1136,4,220,'R'),(1137,2,220,'R'),(1138,5,220,'R'),(1139,6,316,'R'),(1140,4,316,'R'),(1141,2,316,'R'),(1142,5,316,'R'),(1143,6,163,'R'),(1144,4,163,'R'),(1145,2,163,'R'),(1146,5,163,'R'),(1147,6,175,'R'),(1148,4,175,'R'),(1149,2,175,'R'),(1150,5,175,'R'),(1151,6,31,'R'),(1152,4,31,'R'),(1153,2,31,'R'),(1154,5,31,'R'),(1155,6,11,'R'),(1156,2,11,'R'),(1157,5,11,'R'),(1158,6,93,'R'),(1159,4,93,'R'),(1160,2,93,'R'),(1161,5,93,'R'),(1162,6,292,'R'),(1163,4,292,'R'),(1164,2,292,'R'),(1165,5,292,'R'),(1166,6,325,'R'),(1167,4,325,'R'),(1168,2,325,'R'),(1169,5,325,'R'),(1170,6,29,'R'),(1171,4,29,'R'),(1172,2,29,'R'),(1173,5,29,'R'),(1174,6,291,'R'),(1175,4,291,'R'),(1176,2,291,'R'),(1177,5,291,'R'),(1178,6,199,'R'),(1179,4,199,'R'),(1180,2,199,'R'),(1181,5,199,'R'),(1182,6,226,'R'),(1183,4,226,'R'),(1184,2,226,'R'),(1185,5,226,'R'),(1186,6,15,'R'),(1187,4,15,'R'),(1188,2,15,'R'),(1189,5,15,'R'),(1190,6,311,'R'),(1191,4,311,'R'),(1192,2,311,'R'),(1193,5,311,'R'),(1194,6,198,'R'),(1195,4,198,'R'),(1196,2,198,'R'),(1197,5,198,'R'),(1198,6,320,'R'),(1199,4,320,'R'),(1200,2,320,'R'),(1201,5,320,'R'),(1202,6,280,'R'),(1203,4,280,'R'),(1204,2,280,'R'),(1205,5,280,'R'),(1206,6,273,'R'),(1207,4,273,'R'),(1208,2,273,'R'),(1209,5,273,'R'),(1210,6,236,'R'),(1211,4,236,'R'),(1212,2,236,'R'),(1213,5,236,'R'),(1214,6,249,'R'),(1215,4,249,'R'),(1216,2,249,'R'),(1217,5,249,'R'),(1218,6,218,'R'),(1219,4,218,'R'),(1220,2,218,'R'),(1221,5,218,'R'),(1222,6,202,'R'),(1223,4,202,'R'),(1224,2,202,'R'),(1225,5,202,'R'),(1226,6,184,'R'),(1227,4,184,'R'),(1228,2,184,'R'),(1229,5,184,'R'),(1230,2,24,'R'),(1231,5,24,'R'),(1232,6,285,'R'),(1233,4,285,'R'),(1234,2,285,'R'),(1235,5,285,'R'),(1236,6,131,'R'),(1237,2,131,'R'),(1238,5,131,'R'),(1239,6,181,'R'),(1240,4,181,'R'),(1241,2,181,'R'),(1242,5,181,'R'),(1243,6,314,'R'),(1244,4,314,'R'),(1245,2,314,'R'),(1246,5,314,'R'),(1247,6,307,'R'),(1248,4,307,'R'),(1249,2,307,'R'),(1250,5,307,'R'),(1251,6,23,'R'),(1252,4,23,'R'),(1253,2,23,'R'),(1254,5,23,'R'),(1255,6,160,'R'),(1256,4,160,'R'),(1257,2,160,'R'),(1258,5,160,'R'),(1259,6,98,'R'),(1260,4,98,'R'),(1261,2,98,'R'),(1262,5,98,'R'),(1263,6,270,'R'),(1264,4,270,'R'),(1265,2,270,'R'),(1266,5,270,'R'),(1267,6,195,'R'),(1268,4,195,'R'),(1269,2,195,'R'),(1270,5,195,'R'),(1271,6,21,'R'),(1272,4,21,'R'),(1273,2,21,'R'),(1274,5,21,'R'),(1275,6,288,'R'),(1276,4,288,'R'),(1277,2,288,'R'),(1278,5,288,'R'),(1279,6,193,'R'),(1280,4,193,'R'),(1281,2,193,'R'),(1282,5,193,'R'),(1283,6,119,'R'),(1284,4,119,'R'),(1285,2,119,'R'),(1286,5,119,'R'),(1287,6,324,'R'),(1288,4,324,'R'),(1289,2,324,'R'),(1290,5,324,'R'),(1291,6,180,'R'),(1292,4,180,'R'),(1293,2,180,'R'),(1294,5,180,'R'),(1295,6,244,'R'),(1296,4,244,'R'),(1297,2,244,'R'),(1298,5,244,'R'),(1299,6,162,'R'),(1300,4,162,'R'),(1301,2,162,'R'),(1302,5,162,'R'),(1303,6,246,'R'),(1304,4,246,'R'),(1305,2,246,'R'),(1306,5,246,'R'),(1307,6,240,'R'),(1308,4,240,'R'),(1309,2,240,'R'),(1310,5,240,'R'),(1311,6,230,'R'),(1312,4,230,'R'),(1313,2,230,'R'),(1314,5,230,'R'),(1315,6,299,'R'),(1316,4,299,'R'),(1317,2,299,'R'),(1318,5,299,'R'),(1319,6,115,'R'),(1320,4,115,'R'),(1321,2,115,'R'),(1322,5,115,'R'),(1323,6,103,'R'),(1324,4,103,'R'),(1325,2,103,'R'),(1326,5,103,'R'),(1327,6,113,'R'),(1328,4,113,'R'),(1329,2,113,'R'),(1330,5,113,'R'),(1331,6,152,'R'),(1332,4,152,'R'),(1333,2,152,'R'),(1334,5,152,'R'),(1335,6,189,'R'),(1336,4,189,'R'),(1337,2,189,'R'),(1338,5,189,'R'),(1339,6,295,'R'),(1340,4,295,'R'),(1341,2,295,'R'),(1342,5,295,'R'),(1343,6,266,'R'),(1344,4,266,'R'),(1345,2,266,'R'),(1346,5,266,'R'),(1347,6,91,'R'),(1348,4,91,'R'),(1349,2,91,'R'),(1350,5,91,'R'),(1351,6,107,'R'),(1352,4,107,'R'),(1353,2,107,'R'),(1354,5,107,'R'),(1355,6,87,'R'),(1356,4,87,'R'),(1357,2,87,'R'),(1358,5,87,'R'),(1359,6,174,'R'),(1360,4,174,'R'),(1361,2,174,'R'),(1362,5,174,'R'),(1363,6,214,'R'),(1364,4,214,'R'),(1365,2,214,'R'),(1366,5,214,'R'),(1367,6,221,'R'),(1368,4,221,'R'),(1369,2,221,'R'),(1370,5,221,'R'),(1371,6,97,'R'),(1372,4,97,'R'),(1373,2,97,'R'),(1374,5,97,'R'),(1375,6,12,'R'),(1376,4,12,'R'),(1377,2,12,'R'),(1378,5,12,'R'),(1379,6,312,'R'),(1380,4,312,'R'),(1381,2,312,'R'),(1382,5,312,'R'),(1383,6,302,'R'),(1384,4,302,'R'),(1385,2,302,'R'),(1386,5,302,'R'),(1387,6,229,'R'),(1388,4,229,'R'),(1389,2,229,'R'),(1390,5,229,'R'),(1391,6,260,'R'),(1392,4,260,'R'),(1393,2,260,'R'),(1394,5,260,'R'),(1395,6,237,'R'),(1396,4,237,'R'),(1397,2,237,'R'),(1398,5,237,'R'),(1399,6,309,'R'),(1400,4,309,'R'),(1401,2,309,'R'),(1402,5,309,'R'),(1403,6,188,'R'),(1404,4,188,'R'),(1405,2,188,'R'),(1406,5,188,'R'),(1407,6,315,'R'),(1408,4,315,'R'),(1409,2,315,'R'),(1410,5,315,'R'),(1411,6,116,'R'),(1412,4,116,'R'),(1413,2,116,'R'),(1414,5,116,'R'),(1415,6,136,'R'),(1416,2,136,'R'),(1417,5,136,'R'),(1418,6,100,'R'),(1419,5,100,'R'),(1420,6,300,'R'),(1421,4,300,'R'),(1422,2,300,'R'),(1423,5,300,'R'),(1424,6,222,'R'),(1425,4,222,'R'),(1426,2,222,'R'),(1427,5,222,'R'),(1428,6,25,'R'),(1429,4,25,'R'),(1430,2,25,'R'),(1431,5,25,'R'),(1432,6,286,'R'),(1433,4,286,'R'),(1434,2,286,'R'),(1435,5,286,'R'),(1436,6,120,'R'),(1437,4,120,'R'),(1438,2,120,'R'),(1439,5,120,'R'),(1440,6,83,'R'),(1441,4,83,'R'),(1442,2,83,'R'),(1443,5,83,'R'),(1444,6,305,'R'),(1445,4,305,'R'),(1446,2,305,'R'),(1447,5,305,'R'),(1448,6,308,'R'),(1449,4,308,'R'),(1450,2,308,'R'),(1451,5,308,'R'),(1452,6,254,'R'),(1453,4,254,'R'),(1454,2,254,'R'),(1455,5,254,'R'),(1456,6,177,'R'),(1457,4,177,'R'),(1458,2,177,'R'),(1459,5,177,'R'),(1460,6,217,'R'),(1461,4,217,'R'),(1462,2,217,'R'),(1463,5,217,'R'),(1464,6,239,'R'),(1465,4,239,'R'),(1466,2,239,'R'),(1467,5,239,'R'),(1468,6,122,'R'),(1469,4,122,'R'),(1470,2,122,'R'),(1471,5,122,'R'),(1472,6,281,'R'),(1473,4,281,'R'),(1474,2,281,'R'),(1475,5,281,'R'),(1476,6,269,'R'),(1477,4,269,'R'),(1478,2,269,'R'),(1479,5,269,'R'),(1480,6,205,'R'),(1481,4,205,'R'),(1482,2,205,'R'),(1483,5,205,'R'),(1484,6,158,'R'),(1485,4,158,'R'),(1486,2,158,'R'),(1487,5,158,'R'),(1488,6,235,'R'),(1489,4,235,'R'),(1490,2,235,'R'),(1491,5,235,'R'),(1492,6,301,'R'),(1493,4,301,'R'),(1494,2,301,'R'),(1495,5,301,'R'),(1496,4,36,'R'),(1497,2,36,'R'),(1498,5,36,'R'),(1499,6,213,'R'),(1500,4,213,'R'),(1501,2,213,'R'),(1502,5,213,'R'),(1503,6,317,'R'),(1504,4,317,'R'),(1505,2,317,'R'),(1506,5,317,'R'),(1507,6,296,'R'),(1508,4,296,'R'),(1509,2,296,'R'),(1510,5,296,'R'),(1511,6,265,'R'),(1512,4,265,'R'),(1513,2,265,'R'),(1514,5,265,'R'),(1515,6,169,'R'),(1516,4,169,'R'),(1517,2,169,'R'),(1518,5,169,'R'),(1519,6,132,'R'),(1520,2,132,'R'),(1521,5,132,'R'),(1522,6,171,'R'),(1523,4,171,'R'),(1524,2,171,'R'),(1525,5,171,'R'),(1526,6,200,'R'),(1527,4,200,'R'),(1528,2,200,'R'),(1529,5,200,'R'),(1530,6,125,'R'),(1531,2,125,'R'),(1532,5,125,'R'),(1533,6,27,'R'),(1534,4,27,'R'),(1535,2,27,'R'),(1536,5,27,'R'),(1537,6,161,'R'),(1538,4,161,'R'),(1539,2,161,'R'),(1540,5,161,'R'),(1541,6,190,'R'),(1542,4,190,'R'),(1543,2,190,'R'),(1544,5,190,'R'),(1545,6,272,'R'),(1546,4,272,'R'),(1547,2,272,'R'),(1548,5,272,'R'),(1549,6,95,'R'),(1550,4,95,'R'),(1551,2,95,'R'),(1552,5,95,'R'),(1553,6,298,'R'),(1554,4,298,'R'),(1555,2,298,'R'),(1556,5,298,'R'),(1557,6,313,'R'),(1558,4,313,'R'),(1559,2,313,'R'),(1560,5,313,'R'),(1561,6,109,'R'),(1562,4,109,'R'),(1563,2,109,'R'),(1564,5,109,'R'),(1565,6,231,'R'),(1566,4,231,'R'),(1567,2,231,'R'),(1568,5,231,'R'),(1569,6,243,'R'),(1570,4,243,'R'),(1571,2,243,'R'),(1572,5,243,'R'),(1573,6,294,'R'),(1574,4,294,'R'),(1575,2,294,'R'),(1576,5,294,'R'),(1577,6,106,'R'),(1578,4,106,'R'),(1579,2,106,'R'),(1580,5,106,'R'),(1581,6,157,'R'),(1582,4,157,'R'),(1583,2,157,'R'),(1584,5,157,'R'),(1585,6,275,'R'),(1586,4,275,'R'),(1587,2,275,'R'),(1588,5,275,'R'),(1589,6,197,'R'),(1590,4,197,'R'),(1591,2,197,'R'),(1592,5,197,'R'),(1593,6,203,'R'),(1594,4,203,'R'),(1595,2,203,'R'),(1596,5,203,'R'),(1597,6,261,'R'),(1598,4,261,'R'),(1599,2,261,'R'),(1600,5,261,'R'),(1601,6,81,'R'),(1602,4,81,'R'),(1603,2,81,'R'),(1604,5,81,'R'),(1605,6,321,'R'),(1606,4,321,'R'),(1607,2,321,'R'),(1608,5,321,'R'),(1609,6,86,'R'),(1610,4,86,'R'),(1611,2,86,'R'),(1612,5,86,'R'),(1613,6,284,'R'),(1614,4,284,'R'),(1615,2,284,'R'),(1616,5,284,'R'),(1617,6,247,'R'),(1618,4,247,'R'),(1619,2,247,'R'),(1620,5,247,'R'),(1621,6,204,'R'),(1622,4,204,'R'),(1623,2,204,'R'),(1624,5,204,'R'),(1625,6,165,'R'),(1626,4,165,'R'),(1627,2,165,'R'),(1628,5,165,'R'),(1629,6,289,'R'),(1630,4,289,'R'),(1631,2,289,'R'),(1632,5,289,'R'),(1633,4,17,'R'),(1634,2,17,'R'),(1635,5,17,'R'),(1636,6,82,'R'),(1637,4,82,'R'),(1638,2,82,'R'),(1639,5,82,'R'),(1640,6,110,'R'),(1641,4,110,'R'),(1642,2,110,'R'),(1643,5,110,'R'),(1644,6,228,'R'),(1645,4,228,'R'),(1646,2,228,'R'),(1647,5,228,'R'),(1648,6,323,'R'),(1649,4,323,'R'),(1650,2,323,'R'),(1651,5,323,'R'),(1652,6,268,'R'),(1653,4,268,'R'),(1654,2,268,'R'),(1655,5,268,'R'),(1656,6,112,'R'),(1657,4,112,'R'),(1658,2,112,'R'),(1659,5,112,'R'),(1660,6,319,'R'),(1661,4,319,'R'),(1662,2,319,'R'),(1663,5,319,'R'),(1664,6,172,'R'),(1665,4,172,'R'),(1666,2,172,'R'),(1667,5,172,'R'),(1668,6,224,'R'),(1669,4,224,'R'),(1670,2,224,'R'),(1671,5,224,'R'),(1672,6,187,'R'),(1673,4,187,'R'),(1674,2,187,'R'),(1675,5,187,'R'),(1676,6,223,'R'),(1677,4,223,'R'),(1678,2,223,'R'),(1679,5,223,'R'),(1680,6,282,'R'),(1681,4,282,'R'),(1682,2,282,'R'),(1683,5,282,'R'),(1684,6,262,'R'),(1685,4,262,'R'),(1686,2,262,'R'),(1687,5,262,'R'),(1688,6,79,'R'),(1689,2,79,'R'),(1690,5,79,'R'),(1691,6,121,'R'),(1692,4,121,'R'),(1693,2,121,'R'),(1694,5,121,'R'),(1695,6,212,'R'),(1696,4,212,'R'),(1697,2,212,'R'),(1698,5,212,'R'),(1699,6,126,'R'),(1700,2,126,'R'),(1701,5,126,'R'),(1702,6,238,'R'),(1703,4,238,'R'),(1704,2,238,'R'),(1705,5,238,'R'),(1706,6,251,'R'),(1707,4,251,'R'),(1708,2,251,'R'),(1709,5,251,'R'),(1710,6,279,'R'),(1711,4,279,'R'),(1712,2,279,'R'),(1713,5,279,'R'),(1714,6,176,'R'),(1715,4,176,'R'),(1716,2,176,'R'),(1717,5,176,'R'),(1718,6,209,'R'),(1719,4,209,'R'),(1720,2,209,'R'),(1721,5,209,'R'),(1722,6,216,'R'),(1723,4,216,'R'),(1724,2,216,'R'),(1725,5,216,'R'),(1726,6,256,'R'),(1727,4,256,'R'),(1728,2,256,'R'),(1729,5,256,'R'),(1730,6,117,'R'),(1731,4,117,'R'),(1732,2,117,'R'),(1733,5,117,'R'),(1734,6,80,'R'),(1735,4,80,'R'),(1736,2,80,'R'),(1737,5,80,'R'),(1738,6,26,'R'),(1739,4,26,'R'),(1740,2,26,'R'),(1741,5,26,'R'),(1742,6,227,'R'),(1743,4,227,'R'),(1744,2,227,'R'),(1745,5,227,'R'),(1746,6,99,'R'),(1747,4,99,'R'),(1748,2,99,'R'),(1749,5,99,'R'),(1750,6,255,'R'),(1751,4,255,'R'),(1752,2,255,'R'),(1753,5,255,'R'),(1754,6,264,'R'),(1755,4,264,'R'),(1756,2,264,'R'),(1757,5,264,'R'),(1758,6,297,'R'),(1759,4,297,'R'),(1760,2,297,'R'),(1761,5,297,'R'),(1762,6,182,'R'),(1763,4,182,'R'),(1764,2,182,'R'),(1765,5,182,'R'),(1766,6,108,'R'),(1767,4,108,'R'),(1768,2,108,'R'),(1769,5,108,'R'),(1770,6,277,'R'),(1771,4,277,'R'),(1772,2,277,'R'),(1773,5,277,'R'),(1774,6,92,'R'),(1775,4,92,'R'),(1776,2,92,'R'),(1777,5,92,'R'),(1778,6,232,'R'),(1779,4,232,'R'),(1780,2,232,'R'),(1781,5,232,'R'),(1782,6,225,'R'),(1783,4,225,'R'),(1784,2,225,'R'),(1785,5,225,'R'),(1786,6,207,'R'),(1787,4,207,'R'),(1788,2,207,'R'),(1789,5,207,'R'),(1790,6,263,'R'),(1791,4,263,'R'),(1792,2,263,'R'),(1793,5,263,'R'),(1794,6,133,'R'),(1795,4,133,'R'),(1796,2,133,'R'),(1797,5,133,'R'),(1798,6,290,'R'),(1799,4,290,'R'),(1800,2,290,'R'),(1801,5,290,'R'),(1802,6,304,'R'),(1803,4,304,'R'),(1804,2,304,'R'),(1805,5,304,'R'),(1806,6,173,'R'),(1807,4,173,'R'),(1808,2,173,'R'),(1809,5,173,'R'),(1810,6,293,'R'),(1811,4,293,'R'),(1812,2,293,'R'),(1813,5,293,'R'),(1814,6,274,'R'),(1815,4,274,'R'),(1816,2,274,'R'),(1817,5,274,'R'),(1818,6,306,'R'),(1819,4,306,'R'),(1820,2,306,'R'),(1821,5,306,'R'),(1822,6,322,'R'),(1823,4,322,'R'),(1824,2,322,'R'),(1825,5,322,'R'),(1826,6,88,'R'),(1827,4,88,'R'),(1828,2,88,'R'),(1829,5,88,'R'),(1830,6,30,'R'),(1831,4,30,'R'),(1832,2,30,'R'),(1833,5,30,'R'),(1834,6,128,'R'),(1835,2,128,'R'),(1836,5,128,'R'),(1837,6,252,'R'),(1838,4,252,'R'),(1839,2,252,'R'),(1840,5,252,'R'),(1841,6,28,'R'),(1842,4,28,'R'),(1843,2,28,'R'),(1844,5,28,'R'),(1845,6,310,'R'),(1846,4,310,'R'),(1847,2,310,'R'),(1848,5,310,'R'),(1849,6,134,'R'),(1850,4,134,'R'),(1851,2,134,'R'),(1852,5,134,'R'),(1853,6,283,'R'),(1854,4,283,'R'),(1855,2,283,'R'),(1856,5,283,'R'),(1857,6,250,'R'),(1858,4,250,'R'),(1859,2,250,'R'),(1860,5,250,'R'),(1861,6,303,'R'),(1862,4,303,'R'),(1863,2,303,'R'),(1864,5,303,'R'),(1865,6,215,'R'),(1866,4,215,'R'),(1867,2,215,'R'),(1868,5,215,'R'),(1869,6,278,'R'),(1870,4,278,'R'),(1871,2,278,'R'),(1872,5,278,'R'),(1873,6,271,'R'),(1874,4,271,'R'),(1875,2,271,'R'),(1876,5,271,'R'),(1877,6,130,'R'),(1878,4,130,'R'),(1879,2,130,'R'),(1880,5,130,'R'),(1881,6,267,'R'),(1882,4,267,'R'),(1883,2,267,'R'),(1884,5,267,'R'),(1885,6,219,'R'),(1886,4,219,'R'),(1887,2,219,'R'),(1888,5,219,'R'),(1889,6,318,'R'),(1890,4,318,'R'),(1891,2,318,'R'),(1892,5,318,'R'),(1893,6,105,'R'),(1894,2,105,'R'),(1895,5,105,'R'),(1896,6,248,'R'),(1897,4,248,'R'),(1898,2,248,'R'),(1899,5,248,'R'),(1900,6,111,'R'),(1901,4,111,'R'),(1902,2,111,'R'),(1903,5,111,'R'),(1904,6,164,'R'),(1905,4,164,'R'),(1906,2,164,'R'),(1907,5,164,'R'),(1908,6,196,'R'),(1909,4,196,'R'),(1910,2,196,'R'),(1911,5,196,'R'),(1912,6,242,'R'),(1913,4,242,'R'),(1914,2,242,'R'),(1915,5,242,'R'),(1916,6,327,'R'),(1917,4,327,'R'),(1918,2,327,'R'),(1919,5,327,'R'),(1920,6,326,'R'),(1921,4,326,'R'),(1922,2,326,'R'),(1923,5,326,'R'),(1924,6,328,'R'),(1925,4,328,'R'),(1926,2,328,'R'),(1927,5,328,'R');
UNLOCK TABLES;
/*!40000 ALTER TABLE `GrpDBTable` ENABLE KEYS */;

--
-- Table structure for table `GrpEmployee`
--

DROP TABLE IF EXISTS `GrpEmployee`;
CREATE TABLE `GrpEmployee` (
  `GrpEmployee_ID` int(11) NOT NULL auto_increment,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FK_Employee__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`GrpEmployee_ID`),
  UNIQUE KEY `UniqueKey` (`FK_Grp__ID`,`FK_Employee__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `GrpEmployee`
--


/*!40000 ALTER TABLE `GrpEmployee` DISABLE KEYS */;
LOCK TABLES `GrpEmployee` WRITE;
INSERT INTO `GrpEmployee` VALUES (16,1,4),(324,1,6),(54,1,141),(38,1,152),(51,1,171),(323,1,197);
UNLOCK TABLES;
/*!40000 ALTER TABLE `GrpEmployee` ENABLE KEYS */;

--
-- Table structure for table `GrpLab_Protocol`
--

DROP TABLE IF EXISTS `GrpLab_Protocol`;
CREATE TABLE `GrpLab_Protocol` (
  `GrpLab_Protocol_ID` int(11) NOT NULL auto_increment,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FK_Lab_Protocol__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`GrpLab_Protocol_ID`),
  UNIQUE KEY `UniqueKey` (`FK_Grp__ID`,`FK_Lab_Protocol__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Lab_Protocol__ID` (`FK_Lab_Protocol__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `GrpLab_Protocol`
--


/*!40000 ALTER TABLE `GrpLab_Protocol` DISABLE KEYS */;
LOCK TABLES `GrpLab_Protocol` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `GrpLab_Protocol` ENABLE KEYS */;

--
-- Table structure for table `GrpProject`
--

DROP TABLE IF EXISTS `GrpProject`;
CREATE TABLE `GrpProject` (
  `GrpProject_ID` int(11) NOT NULL auto_increment,
  `FK_Project__ID` int(11) NOT NULL default '0',
  `FK_Grp__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`GrpProject_ID`),
  KEY `FK_Project__ID` (`FK_Project__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `GrpProject`
--


/*!40000 ALTER TABLE `GrpProject` DISABLE KEYS */;
LOCK TABLES `GrpProject` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `GrpProject` ENABLE KEYS */;

--
-- Table structure for table `GrpStandard_Solution`
--

DROP TABLE IF EXISTS `GrpStandard_Solution`;
CREATE TABLE `GrpStandard_Solution` (
  `GrpStandard_Solution_ID` int(11) NOT NULL auto_increment,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FK_Standard_Solution__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`GrpStandard_Solution_ID`),
  UNIQUE KEY `UniqueKey` (`FK_Grp__ID`,`FK_Standard_Solution__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Standard_Solution__ID` (`FK_Standard_Solution__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `GrpStandard_Solution`
--


/*!40000 ALTER TABLE `GrpStandard_Solution` DISABLE KEYS */;
LOCK TABLES `GrpStandard_Solution` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `GrpStandard_Solution` ENABLE KEYS */;

--
-- Table structure for table `Grp_Relationship`
--

DROP TABLE IF EXISTS `Grp_Relationship`;
CREATE TABLE `Grp_Relationship` (
  `Grp_Relationship_ID` int(11) NOT NULL auto_increment,
  `FKBase_Grp__ID` int(11) NOT NULL default '0',
  `FKDerived_Grp__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Grp_Relationship_ID`),
  KEY `FKDerived_Grp__ID` (`FKDerived_Grp__ID`),
  KEY `FKBase_Grp__ID` (`FKBase_Grp__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Grp_Relationship`
--


/*!40000 ALTER TABLE `Grp_Relationship` DISABLE KEYS */;
LOCK TABLES `Grp_Relationship` WRITE;
INSERT INTO `Grp_Relationship` VALUES (1,2,4),(4,2,6);
UNLOCK TABLES;
/*!40000 ALTER TABLE `Grp_Relationship` ENABLE KEYS */;

--
-- Table structure for table `How_To_Object`
--

DROP TABLE IF EXISTS `How_To_Object`;
CREATE TABLE `How_To_Object` (
  `How_To_Object_ID` int(11) NOT NULL auto_increment,
  `How_To_Object_Name` varchar(80) NOT NULL default '',
  `How_To_Object_Description` text,
  PRIMARY KEY  (`How_To_Object_ID`),
  UNIQUE KEY `object_name` (`How_To_Object_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `How_To_Object`
--


/*!40000 ALTER TABLE `How_To_Object` DISABLE KEYS */;
LOCK TABLES `How_To_Object` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `How_To_Object` ENABLE KEYS */;

--
-- Table structure for table `How_To_Step`
--

DROP TABLE IF EXISTS `How_To_Step`;
CREATE TABLE `How_To_Step` (
  `How_To_Step_ID` int(11) NOT NULL auto_increment,
  `How_To_Step_Number` int(11) default NULL,
  `How_To_Step_Description` text,
  `How_To_Step_Result` text,
  `Users` set('A','T','L') default 'T',
  `Mode` set('Scanner','PC') default 'PC',
  `FK_How_To_Topic__ID` int(11) default NULL,
  PRIMARY KEY  (`How_To_Step_ID`),
  KEY `title` (`FK_How_To_Topic__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `How_To_Step`
--


/*!40000 ALTER TABLE `How_To_Step` DISABLE KEYS */;
LOCK TABLES `How_To_Step` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `How_To_Step` ENABLE KEYS */;

--
-- Table structure for table `How_To_Topic`
--

DROP TABLE IF EXISTS `How_To_Topic`;
CREATE TABLE `How_To_Topic` (
  `How_To_Topic_ID` int(11) NOT NULL auto_increment,
  `Topic_Number` int(11) default NULL,
  `Topic_Name` varchar(80) NOT NULL default '',
  `Topic_Type` enum('','New','Update','Find','Edit') NOT NULL default '',
  `Topic_Description` text,
  `FK_How_To_Object__ID` int(11) default NULL,
  PRIMARY KEY  (`How_To_Topic_ID`),
  KEY `object` (`FK_How_To_Object__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `How_To_Topic`
--


/*!40000 ALTER TABLE `How_To_Topic` DISABLE KEYS */;
LOCK TABLES `How_To_Topic` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `How_To_Topic` ENABLE KEYS */;

--
-- Table structure for table `Hybrid_Original_Source`
--

DROP TABLE IF EXISTS `Hybrid_Original_Source`;
CREATE TABLE `Hybrid_Original_Source` (
  `Hybrid_Original_Source_ID` int(11) NOT NULL auto_increment,
  `FKParent_Original_Source__ID` int(11) default NULL,
  `FKChild_Original_Source__ID` int(11) default NULL,
  PRIMARY KEY  (`Hybrid_Original_Source_ID`),
  KEY `FKParent_Source__ID` (`FKParent_Original_Source__ID`),
  KEY `FKChild_Original_Source__ID` (`FKChild_Original_Source__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Hybrid_Original_Source`
--


/*!40000 ALTER TABLE `Hybrid_Original_Source` DISABLE KEYS */;
LOCK TABLES `Hybrid_Original_Source` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Hybrid_Original_Source` ENABLE KEYS */;

--
-- Table structure for table `Issue`
--

DROP TABLE IF EXISTS `Issue`;
CREATE TABLE `Issue` (
  `Issue_ID` int(11) NOT NULL auto_increment,
  `Type` enum('Reported','Defect','Enhancement','Conformance','Maintenance','Requirement','Work Request','Ongoing Maintenance','User Error') default NULL,
  `Description` text NOT NULL,
  `Priority` enum('Critical','High','Medium','Low') NOT NULL default 'High',
  `Severity` enum('Fatal','Major','Minor','Cosmetic') NOT NULL default 'Major',
  `Status` enum('Reported','Approved','Open','In Process','Resolved','Closed','Deferred') default 'Reported',
  `Found_Release` varchar(9) NOT NULL default '',
  `Assigned_Release` varchar(9) default NULL,
  `FKSubmitted_Employee__ID` int(11) NOT NULL default '0',
  `Submitted_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `FKAssigned_Employee__ID` int(11) default NULL,
  `Resolution` enum('By Design','Cannot Reproduce','Code Fix','Data Fix','Do Not Fix','Duplicate Issue','False Submission','System Fix','Code Design') default NULL,
  `Estimated_Time` float default NULL,
  `Estimated_Time_Unit` enum('FTE','Minutes','Hours','Days','Weeks','Months') default NULL,
  `Actual_Time` float default NULL,
  `Actual_Time_Unit` enum('Minutes','Hours','Days','Weeks','Months') default NULL,
  `Last_Modified` datetime default NULL,
  `FK_Department__ID` int(11) default NULL,
  `SubType` enum('General','View','Forms','I/O','Report','Settings','Error Checking','Auto-Notification','Documentation','Scanner','Background Process') default 'General',
  `FKParent_Issue__ID` int(11) default NULL,
  `Issue_Comment` text NOT NULL,
  `FK_Grp__ID` int(11) NOT NULL default '1',
  `Latest_ETA` decimal(10,2) default NULL,
  PRIMARY KEY  (`Issue_ID`),
  KEY `Priority` (`Priority`),
  KEY `Severity` (`Severity`),
  KEY `Status` (`Status`),
  KEY `Submitted` (`FKSubmitted_Employee__ID`),
  KEY `Assigned` (`FKAssigned_Employee__ID`),
  KEY `Resolution` (`Resolution`),
  KEY `FKParent_Issue__ID` (`FKParent_Issue__ID`),
  KEY `FK_Department__ID` (`FK_Department__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Issue`
--


/*!40000 ALTER TABLE `Issue` DISABLE KEYS */;
LOCK TABLES `Issue` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Issue` ENABLE KEYS */;

--
-- Table structure for table `Issue_Detail`
--

DROP TABLE IF EXISTS `Issue_Detail`;
CREATE TABLE `Issue_Detail` (
  `Issue_Detail_ID` int(11) NOT NULL auto_increment,
  `FK_Issue__ID` int(11) NOT NULL default '0',
  `FKSubmitted_Employee__ID` int(11) NOT NULL default '0',
  `Submitted_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `Message` text,
  PRIMARY KEY  (`Issue_Detail_ID`),
  KEY `FKSubmitted_Employee__ID` (`FKSubmitted_Employee__ID`),
  KEY `FK_Issue__ID` (`FK_Issue__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Issue_Detail`
--


/*!40000 ALTER TABLE `Issue_Detail` DISABLE KEYS */;
LOCK TABLES `Issue_Detail` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Issue_Detail` ENABLE KEYS */;

--
-- Table structure for table `Issue_Log`
--

DROP TABLE IF EXISTS `Issue_Log`;
CREATE TABLE `Issue_Log` (
  `Issue_Log_ID` int(11) NOT NULL auto_increment,
  `FK_Issue__ID` int(11) NOT NULL default '0',
  `FKSubmitted_Employee__ID` int(11) default NULL,
  `Submitted_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `Log` text NOT NULL,
  PRIMARY KEY  (`Issue_Log_ID`),
  KEY `FKSubmitted_Employee__ID` (`FKSubmitted_Employee__ID`),
  KEY `FK_Issue__ID` (`FK_Issue__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Issue_Log`
--


/*!40000 ALTER TABLE `Issue_Log` DISABLE KEYS */;
LOCK TABLES `Issue_Log` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Issue_Log` ENABLE KEYS */;

--
-- Table structure for table `Lab_Protocol`
--

DROP TABLE IF EXISTS `Lab_Protocol`;
CREATE TABLE `Lab_Protocol` (
  `Lab_Protocol_Name` varchar(40) default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Lab_Protocol_Status` enum('Active','Old','Inactive') default NULL,
  `Lab_Protocol_Description` text,
  `Lab_Protocol_ID` int(11) NOT NULL auto_increment,
  `Lab_Protocol_VersionDate` date default NULL,
  `Max_Tracking_Size` enum('384','96') default '384',
  `Repeatable` enum('Yes','No') NOT NULL default 'Yes',
  PRIMARY KEY  (`Lab_Protocol_ID`),
  UNIQUE KEY `name` (`Lab_Protocol_Name`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Lab_Protocol`
--


/*!40000 ALTER TABLE `Lab_Protocol` DISABLE KEYS */;
LOCK TABLES `Lab_Protocol` WRITE;
INSERT INTO `Lab_Protocol` VALUES ('Rxns_ET384_0.5X_10ulRxn_3.0ulDNA',137,'Inactive','',1,'0000-00-00','384','Yes');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Lab_Protocol` ENABLE KEYS */;

--
-- Table structure for table `Lab_Request`
--

DROP TABLE IF EXISTS `Lab_Request`;
CREATE TABLE `Lab_Request` (
  `Lab_Request_ID` int(11) NOT NULL auto_increment,
  `FK_Employee__ID` int(11) NOT NULL default '0',
  `Request_Date` date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`Lab_Request_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Lab_Request`
--


/*!40000 ALTER TABLE `Lab_Request` DISABLE KEYS */;
LOCK TABLES `Lab_Request` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Lab_Request` ENABLE KEYS */;

--
-- Table structure for table `Label_Format`
--

DROP TABLE IF EXISTS `Label_Format`;
CREATE TABLE `Label_Format` (
  `Label_Format_ID` int(11) NOT NULL auto_increment,
  `Label_Format_Name` varchar(20) NOT NULL default '',
  `Label_Description` text NOT NULL,
  PRIMARY KEY  (`Label_Format_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Label_Format`
--


/*!40000 ALTER TABLE `Label_Format` DISABLE KEYS */;
LOCK TABLES `Label_Format` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Label_Format` ENABLE KEYS */;

--
-- Table structure for table `Lane`
--

DROP TABLE IF EXISTS `Lane`;
CREATE TABLE `Lane` (
  `Lane_ID` int(11) NOT NULL auto_increment,
  `FK_GelRun__ID` int(11) default NULL,
  `FK_Sample__ID` int(11) default NULL,
  `Lane_Number` int(11) default NULL,
  `Lane_Status` enum('Passed','Failed','Marker') default NULL,
  `Band_Size_Estimate` int(11) default NULL,
  `Bands_Count` int(11) default NULL,
  `Well` char(3) NOT NULL default '',
  `Lane_Growth` enum('No Grow','Slow Grow','Unused','Problematic','Empty') default NULL,
  PRIMARY KEY  (`Lane_ID`),
  KEY `FK_GelRun__ID` (`FK_GelRun__ID`,`FK_Sample__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Lane`
--


/*!40000 ALTER TABLE `Lane` DISABLE KEYS */;
LOCK TABLES `Lane` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Lane` ENABLE KEYS */;

--
-- Table structure for table `Library`
--

DROP TABLE IF EXISTS `Library`;
CREATE TABLE `Library` (
  `Library_Source_Name` text,
  `Library_Type` enum('Sequencing','RNA/DNA','Mapping') default NULL,
  `Library_Obtained_Date` date NOT NULL default '0000-00-00',
  `Library_Source` text,
  `Library_Name` varchar(40) NOT NULL default '',
  `External_Library_Name` text NOT NULL,
  `Library_Description` text,
  `FK_Project__ID` int(11) default NULL,
  `Library_Notes` text,
  `Library_FullName` varchar(80) default NULL,
  `FKParent_Library__Name` varchar(40) default NULL,
  `Library_Goals` text,
  `Library_Status` enum('Submitted','On Hold','In Production','Complete','Cancelled','Contaminated') default 'Submitted',
  `FK_Contact__ID` int(11) default NULL,
  `FKCreated_Employee__ID` int(11) default NULL,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FK_Original_Source__ID` int(11) NOT NULL default '0',
  `Library_URL` text,
  `Starting_Plate_Number` smallint(6) NOT NULL default '1',
  `Source_In_House` enum('Yes','No') NOT NULL default 'Yes',
  `Requested_Completion_Date` date default NULL,
  `FKConstructed_Contact__ID` int(11) default '0',
  `Library_Completion_Date` date default NULL,
  PRIMARY KEY  (`Library_Name`),
  KEY `proj` (`FK_Project__ID`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`),
  KEY `FKParent_Library__Name` (`FKParent_Library__Name`),
  KEY `FKCreated_Employee__ID` (`FKCreated_Employee__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Original_Source__ID` (`FK_Original_Source__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Library`
--


/*!40000 ALTER TABLE `Library` DISABLE KEYS */;
LOCK TABLES `Library` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Library` ENABLE KEYS */;

--
-- Table structure for table `LibraryApplication`
--

DROP TABLE IF EXISTS `LibraryApplication`;
CREATE TABLE `LibraryApplication` (
  `LibraryApplication_ID` int(11) NOT NULL auto_increment,
  `FK_Library__Name` varchar(40) NOT NULL default '',
  `Object_ID` varchar(40) NOT NULL default '',
  `FK_Object_Class__ID` int(11) NOT NULL default '0',
  `Direction` enum('3prime','5prime','N/A','Unknown') default 'N/A',
  PRIMARY KEY  (`LibraryApplication_ID`),
  UNIQUE KEY `LibApp` (`FK_Library__Name`,`Object_ID`,`FK_Object_Class__ID`),
  KEY `FK_Library__Name` (`FK_Library__Name`),
  KEY `Object_ID` (`Object_ID`),
  KEY `FK_Object_Class__ID` (`FK_Object_Class__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='Generic TABLE for reagents (etc) applied to a library';

--
-- Dumping data for table `LibraryApplication`
--


/*!40000 ALTER TABLE `LibraryApplication` DISABLE KEYS */;
LOCK TABLES `LibraryApplication` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `LibraryApplication` ENABLE KEYS */;

--
-- Table structure for table `LibraryGoal`
--

DROP TABLE IF EXISTS `LibraryGoal`;
CREATE TABLE `LibraryGoal` (
  `LibraryGoal_ID` int(11) NOT NULL auto_increment,
  `FK_Library__Name` varchar(6) default NULL,
  `FK_Goal__ID` int(11) NOT NULL default '0',
  `Goal_Target` int(11) NOT NULL default '0',
  PRIMARY KEY  (`LibraryGoal_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `LibraryGoal`
--


/*!40000 ALTER TABLE `LibraryGoal` DISABLE KEYS */;
LOCK TABLES `LibraryGoal` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `LibraryGoal` ENABLE KEYS */;

--
-- Table structure for table `LibraryPrimer`
--

DROP TABLE IF EXISTS `LibraryPrimer`;
CREATE TABLE `LibraryPrimer` (
  `LibraryPrimer_ID` int(11) NOT NULL auto_increment,
  `FK_Library__Name` varchar(40) default NULL,
  `FK_Primer__Name` varchar(40) default NULL,
  `Clones_Estimate` int(11) NOT NULL default '0',
  `TagsRequested` int(11) NOT NULL default '0',
  `Direction` enum('3prime','5prime','N/A','Unknown') default NULL,
  PRIMARY KEY  (`LibraryPrimer_ID`),
  UNIQUE KEY `combo` (`FK_Library__Name`,`FK_Primer__Name`),
  KEY `FK_Primer__Name` (`FK_Primer__Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `LibraryPrimer`
--


/*!40000 ALTER TABLE `LibraryPrimer` DISABLE KEYS */;
LOCK TABLES `LibraryPrimer` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `LibraryPrimer` ENABLE KEYS */;

--
-- Table structure for table `LibraryProgress`
--

DROP TABLE IF EXISTS `LibraryProgress`;
CREATE TABLE `LibraryProgress` (
  `LibraryProgress_ID` int(11) NOT NULL auto_increment,
  `LibraryProgress_Date` date default NULL,
  `FK_Library__Name` varchar(5) default NULL,
  `LibraryProgress_Comments` text,
  PRIMARY KEY  (`LibraryProgress_ID`),
  KEY `FK_Library__Name` (`FK_Library__Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `LibraryProgress`
--


/*!40000 ALTER TABLE `LibraryProgress` DISABLE KEYS */;
LOCK TABLES `LibraryProgress` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `LibraryProgress` ENABLE KEYS */;

--
-- Table structure for table `LibraryStudy`
--

DROP TABLE IF EXISTS `LibraryStudy`;
CREATE TABLE `LibraryStudy` (
  `LibraryStudy_ID` int(11) NOT NULL auto_increment,
  `FK_Library__Name` varchar(40) default NULL,
  `FK_Study__ID` int(11) default NULL,
  PRIMARY KEY  (`LibraryStudy_ID`),
  KEY `library_name` (`FK_Library__Name`),
  KEY `study_id` (`FK_Study__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `LibraryStudy`
--


/*!40000 ALTER TABLE `LibraryStudy` DISABLE KEYS */;
LOCK TABLES `LibraryStudy` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `LibraryStudy` ENABLE KEYS */;

--
-- Table structure for table `LibraryVector`
--

DROP TABLE IF EXISTS `LibraryVector`;
CREATE TABLE `LibraryVector` (
  `LibraryVector_ID` int(11) NOT NULL auto_increment,
  `FK_Library__Name` varchar(40) default NULL,
  `FK_Vector__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`LibraryVector_ID`),
  UNIQUE KEY `combo` (`FK_Library__Name`,`FK_Vector__ID`),
  KEY `FK_Vector__ID` (`FK_Vector__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `LibraryVector`
--


/*!40000 ALTER TABLE `LibraryVector` DISABLE KEYS */;
LOCK TABLES `LibraryVector` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `LibraryVector` ENABLE KEYS */;

--
-- Table structure for table `Library_Attribute`
--

DROP TABLE IF EXISTS `Library_Attribute`;
CREATE TABLE `Library_Attribute` (
  `Library_Attribute_ID` int(11) NOT NULL auto_increment,
  `FK_Library__Name` varchar(6) default NULL,
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text NOT NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Set_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`Library_Attribute_ID`),
  UNIQUE KEY `FK_Attribute__ID_2` (`FK_Attribute__ID`,`FK_Library__Name`),
  KEY `FK_Library__Name` (`FK_Library__Name`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Library_Attribute`
--


/*!40000 ALTER TABLE `Library_Attribute` DISABLE KEYS */;
LOCK TABLES `Library_Attribute` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Library_Attribute` ENABLE KEYS */;

--
-- Table structure for table `Library_Plate`
--

DROP TABLE IF EXISTS `Library_Plate`;
CREATE TABLE `Library_Plate` (
  `Library_Plate_ID` int(11) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) default NULL,
  `Plate_Class` enum('Standard','ReArray','Oligo') default 'Standard',
  `No_Grows` text,
  `Slow_Grows` text,
  `Unused_Wells` text,
  `Sub_Quadrants` set('','a','b','c','d','none') default NULL,
  `Slice` varchar(8) default NULL,
  `Plate_Position` enum('','a','b','c','d') default '',
  `Problematic_Wells` text,
  `Empty_Wells` text,
  PRIMARY KEY  (`Library_Plate_ID`),
  KEY `plate_id` (`FK_Plate__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Library_Plate`
--


/*!40000 ALTER TABLE `Library_Plate` DISABLE KEYS */;
LOCK TABLES `Library_Plate` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Library_Plate` ENABLE KEYS */;

--
-- Table structure for table `Library_Segment`
--

DROP TABLE IF EXISTS `Library_Segment`;
CREATE TABLE `Library_Segment` (
  `Library_Segment_ID` int(11) NOT NULL auto_increment,
  `FK_Vector__ID` int(11) NOT NULL default '0',
  `Non_Recombinants` float(5,2) default NULL,
  `Non_Insert_Clones` float(5,2) default NULL,
  `Recombinant_Clones` float(5,2) default NULL,
  `Average_Insert_Size` int(11) default NULL,
  `FK_Antibiotic__ID` int(11) default NULL,
  `Genome_Coverage` float(5,2) default NULL,
  `FK_Restriction_Site__ID` int(11) default NULL,
  `FK_Source__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Library_Segment_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Library_Segment`
--


/*!40000 ALTER TABLE `Library_Segment` DISABLE KEYS */;
LOCK TABLES `Library_Segment` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Library_Segment` ENABLE KEYS */;

--
-- Table structure for table `Library_Source`
--

DROP TABLE IF EXISTS `Library_Source`;
CREATE TABLE `Library_Source` (
  `Library_Source_ID` int(11) NOT NULL auto_increment,
  `FK_Source__ID` int(11) NOT NULL default '0',
  `FK_Library__Name` varchar(40) NOT NULL default '',
  PRIMARY KEY  (`Library_Source_ID`),
  KEY `FK_Library__Name` (`FK_Library__Name`),
  KEY `FK_Source__ID` (`FK_Source__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Library_Source`
--


/*!40000 ALTER TABLE `Library_Source` DISABLE KEYS */;
LOCK TABLES `Library_Source` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Library_Source` ENABLE KEYS */;

--
-- Table structure for table `Ligation`
--

DROP TABLE IF EXISTS `Ligation`;
CREATE TABLE `Ligation` (
  `Ligation_ID` int(11) NOT NULL auto_increment,
  `Ligation_Volume` int(11) default NULL,
  `cfu` int(11) default NULL,
  `Sequencing_Type` enum('Primers','Transposon','Primers_and_transposon','Replicates','N/A') default NULL,
  `384_Well_Plates_To_Seq` int(11) default NULL,
  `FKExtraction_Plate__ID` int(11) default NULL,
  `FK_Source__ID` int(11) NOT NULL default '0',
  `384_Well_Plates_To_Pick` int(11) default '0',
  PRIMARY KEY  (`Ligation_ID`),
  KEY `FKExtraction_Plate__ID` (`FKExtraction_Plate__ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Ligation`
--


/*!40000 ALTER TABLE `Ligation` DISABLE KEYS */;
LOCK TABLES `Ligation` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Ligation` ENABLE KEYS */;

--
-- Table structure for table `Location`
--

DROP TABLE IF EXISTS `Location`;
CREATE TABLE `Location` (
  `Location_ID` int(11) NOT NULL auto_increment,
  `Location_Name` char(40) default NULL,
  `Location_Status` enum('active','inactive') NOT NULL default 'active',
  PRIMARY KEY  (`Location_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Location`
--


/*!40000 ALTER TABLE `Location` DISABLE KEYS */;
LOCK TABLES `Location` WRITE;
INSERT INTO `Location` VALUES (1,'Sequence Lab','active');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Location` ENABLE KEYS */;

--
-- Table structure for table `Machine_Default`
--

DROP TABLE IF EXISTS `Machine_Default`;
CREATE TABLE `Machine_Default` (
  `Machine_Default_ID` int(11) NOT NULL auto_increment,
  `FK_Equipment__ID` int(11) default NULL,
  `Run_Module` text,
  `NT_Data_dir` text,
  `NT_Samplesheet_dir` text,
  `Local_Samplesheet_dir` text,
  `Host` varchar(40) default NULL,
  `Local_Data_dir` text,
  `Sharename` text,
  `Agarose_Percentage` float default NULL,
  `Injection_Voltage` int(11) default NULL,
  `Injection_Time` int(11) default NULL,
  `Run_Voltage` int(11) default NULL,
  `Run_Time` int(11) default NULL,
  `Run_Temp` int(11) default NULL,
  `PMT1` int(11) default NULL,
  `PMT2` int(11) default NULL,
  `An_Module` text,
  `Foil_Piercing` tinyint(4) default NULL,
  `Chemistry_Version` tinyint(4) default NULL,
  `FK_Sequencer_Type__ID` tinyint(4) NOT NULL default '0',
  `Mount` varchar(80) default NULL,
  PRIMARY KEY  (`Machine_Default_ID`),
  KEY `FK_Equipment__ID` (`FK_Equipment__ID`),
  KEY `FK_Sequencer_Type__ID` (`FK_Sequencer_Type__ID`),
  KEY `host` (`Host`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Machine_Default`
--


/*!40000 ALTER TABLE `Machine_Default` DISABLE KEYS */;
LOCK TABLES `Machine_Default` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Machine_Default` ENABLE KEYS */;

--
-- Table structure for table `Maintenance`
--

DROP TABLE IF EXISTS `Maintenance`;
CREATE TABLE `Maintenance` (
  `Maintenance_ID` int(11) NOT NULL auto_increment,
  `FK_Equipment__ID` int(11) default NULL,
  `Maintenance_Process` text,
  `Maintenance_Description` text NOT NULL,
  `Maintenance_DateTime` datetime default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `FK_Contact__ID` int(11) default NULL,
  `FK_Solution__ID` int(11) default NULL,
  `Maintenance_Cost` float default NULL,
  `Maintenance_Finished` datetime default NULL,
  `FKMaintenance_Status__ID` int(11) default '0',
  `FK_Maintenance_Process_Type__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Maintenance_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_Equipment__ID` (`FK_Equipment__ID`),
  KEY `FK_Solution__ID` (`FK_Solution__ID`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Maintenance`
--


/*!40000 ALTER TABLE `Maintenance` DISABLE KEYS */;
LOCK TABLES `Maintenance` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Maintenance` ENABLE KEYS */;

--
-- Table structure for table `Maintenance_Process_Type`
--

DROP TABLE IF EXISTS `Maintenance_Process_Type`;
CREATE TABLE `Maintenance_Process_Type` (
  `Maintenance_Process_Type_ID` int(11) NOT NULL auto_increment,
  `Process_Type_Description` text,
  `Process_Type_Name` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`Maintenance_Process_Type_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Maintenance_Process_Type`
--


/*!40000 ALTER TABLE `Maintenance_Process_Type` DISABLE KEYS */;
LOCK TABLES `Maintenance_Process_Type` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Maintenance_Process_Type` ENABLE KEYS */;

--
-- Table structure for table `Maintenance_Protocol`
--

DROP TABLE IF EXISTS `Maintenance_Protocol`;
CREATE TABLE `Maintenance_Protocol` (
  `Maintenance_Protocol_ID` int(11) NOT NULL auto_increment,
  `FK_Service__Name` varchar(40) default NULL,
  `Step` int(11) default NULL,
  `Maintenance_Step_Name` varchar(40) default NULL,
  `Maintenance_Instructions` text,
  `FK_Employee__ID` int(11) default NULL,
  `Protocol_Date` date default '0000-00-00',
  `Maintenance_Protocol_Name` text,
  `FK_Contact__ID` int(11) default NULL,
  PRIMARY KEY  (`Maintenance_Protocol_ID`),
  UNIQUE KEY `step` (`FK_Service__Name`,`Step`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Maintenance_Protocol`
--


/*!40000 ALTER TABLE `Maintenance_Protocol` DISABLE KEYS */;
LOCK TABLES `Maintenance_Protocol` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Maintenance_Protocol` ENABLE KEYS */;

--
-- Table structure for table `Maintenance_Schedule`
--

DROP TABLE IF EXISTS `Maintenance_Schedule`;
CREATE TABLE `Maintenance_Schedule` (
  `Maintenance_Schedule_ID` int(11) NOT NULL auto_increment,
  `FK_Maintenance_Process_Type__ID` int(11) NOT NULL default '0',
  `FK_Equipment__ID` int(11) default NULL,
  `Scheduled_Equipment_Type` char(20) default NULL,
  `Scheduled_Frequency` int(11) default NULL,
  `Notice_Frequency` int(11) default '7',
  `Notice_Sent` date default NULL,
  PRIMARY KEY  (`Maintenance_Schedule_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Maintenance_Schedule`
--


/*!40000 ALTER TABLE `Maintenance_Schedule` DISABLE KEYS */;
LOCK TABLES `Maintenance_Schedule` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Maintenance_Schedule` ENABLE KEYS */;

--
-- Table structure for table `Matched_Funding`
--

DROP TABLE IF EXISTS `Matched_Funding`;
CREATE TABLE `Matched_Funding` (
  `Matched_Funding_ID` int(11) NOT NULL auto_increment,
  `Matched_Funding_Number` int(11) default NULL,
  `FK_Funding__ID` int(11) default NULL,
  PRIMARY KEY  (`Matched_Funding_ID`),
  KEY `FK_Funding__ID` (`FK_Funding__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Matched_Funding`
--


/*!40000 ALTER TABLE `Matched_Funding` DISABLE KEYS */;
LOCK TABLES `Matched_Funding` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Matched_Funding` ENABLE KEYS */;

--
-- Table structure for table `Message`
--

DROP TABLE IF EXISTS `Message`;
CREATE TABLE `Message` (
  `Message_ID` int(11) NOT NULL auto_increment,
  `Message_Text` text,
  `Message_Date` datetime default NULL,
  `Message_Link` text,
  `Message_Status` enum('Urgent','Active','Old') default 'Active',
  `FK_Employee__ID` int(11) default NULL,
  `Message_Type` enum('Public','Private','Admin','Group') default NULL,
  `FK_Grp__ID` int(11) default NULL,
  PRIMARY KEY  (`Message_ID`),
  KEY `fk_grp` (`FK_Grp__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Message`
--


/*!40000 ALTER TABLE `Message` DISABLE KEYS */;
LOCK TABLES `Message` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Message` ENABLE KEYS */;

--
-- Table structure for table `Microarray`
--

DROP TABLE IF EXISTS `Microarray`;
CREATE TABLE `Microarray` (
  `Microarray_ID` int(11) NOT NULL auto_increment,
  `FK_Stock__ID` int(11) default NULL,
  `FK_Rack__ID` int(11) default NULL,
  `Microarray_Type` enum('Genechip') NOT NULL default 'Genechip',
  `Expiry_DateTime` datetime default NULL,
  `Used_DateTime` datetime default NULL,
  `Microarray_Number` int(11) NOT NULL default '0',
  `Microarray_Number_in_Batch` int(11) NOT NULL default '0',
  `Microarray_Status` enum('Unused','Used','Thrown Out','Expired') NOT NULL default 'Unused',
  PRIMARY KEY  (`Microarray_ID`),
  KEY `stock_id` (`FK_Stock__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Microarray`
--


/*!40000 ALTER TABLE `Microarray` DISABLE KEYS */;
LOCK TABLES `Microarray` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Microarray` ENABLE KEYS */;

--
-- Table structure for table `Microtiter`
--

DROP TABLE IF EXISTS `Microtiter`;
CREATE TABLE `Microtiter` (
  `Microtiter_ID` int(11) NOT NULL auto_increment,
  `Plates` int(11) default NULL,
  `Plate_Size` enum('96-well','384-well') default NULL,
  `Plate_Catalog_Number` varchar(40) default NULL,
  `VolumePerWell` int(11) default NULL,
  `Cell_Catalog_Number` varchar(40) default NULL,
  `FKSupplier_Organization__ID` int(11) default NULL,
  `Cell_Type` varchar(40) default NULL,
  `Media_Type` varchar(40) default NULL,
  `Sequencing_Type` enum('Primers','Transposon','Primers_and_transposon','Replicates') default NULL,
  `384_Well_Plates_To_Seq` int(11) default NULL,
  `FK_Source__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Microtiter_ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`),
  KEY `FKSupplier_Organization__ID` (`FKSupplier_Organization__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Microtiter`
--


/*!40000 ALTER TABLE `Microtiter` DISABLE KEYS */;
LOCK TABLES `Microtiter` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Microtiter` ENABLE KEYS */;

--
-- Table structure for table `Misc_Item`
--

DROP TABLE IF EXISTS `Misc_Item`;
CREATE TABLE `Misc_Item` (
  `Misc_Item_ID` int(11) NOT NULL auto_increment,
  `Misc_Item_Number` int(11) NOT NULL default '0',
  `Misc_Item_Number_in_Batch` int(11) default NULL,
  `FK_Stock__ID` int(11) default NULL,
  `Misc_Item_Serial_Number` text,
  `FK_Rack__ID` int(11) default NULL,
  `Misc_Item_Type` text,
  PRIMARY KEY  (`Misc_Item_ID`),
  KEY `FK_Stock__ID` (`FK_Stock__ID`),
  KEY `FK_Rack__ID` (`FK_Rack__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Misc_Item`
--


/*!40000 ALTER TABLE `Misc_Item` DISABLE KEYS */;
LOCK TABLES `Misc_Item` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Misc_Item` ENABLE KEYS */;

--
-- Table structure for table `Mixture`
--

DROP TABLE IF EXISTS `Mixture`;
CREATE TABLE `Mixture` (
  `Mixture_ID` int(8) NOT NULL auto_increment,
  `FKMade_Solution__ID` int(11) default NULL,
  `FKUsed_Solution__ID` int(11) default NULL,
  `Quantity_Used` float default NULL,
  `Mixture_Comments` text,
  `Units_Used` varchar(10) default NULL,
  PRIMARY KEY  (`Mixture_ID`),
  KEY `made_solution` (`FKMade_Solution__ID`),
  KEY `used_solution` (`FKUsed_Solution__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Mixture`
--


/*!40000 ALTER TABLE `Mixture` DISABLE KEYS */;
LOCK TABLES `Mixture` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Mixture` ENABLE KEYS */;

--
-- Table structure for table `MultiPlate_Run`
--

DROP TABLE IF EXISTS `MultiPlate_Run`;
CREATE TABLE `MultiPlate_Run` (
  `MultiPlate_Run_ID` int(11) NOT NULL auto_increment,
  `FKMaster_Run__ID` int(11) default NULL,
  `FK_Run__ID` int(11) default NULL,
  `MultiPlate_Run_Quadrant` char(1) default NULL,
  PRIMARY KEY  (`MultiPlate_Run_ID`),
  KEY `FK_Sequence__ID` (`FK_Run__ID`),
  KEY `FKMaster_Sequence__ID` (`FKMaster_Run__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `MultiPlate_Run`
--


/*!40000 ALTER TABLE `MultiPlate_Run` DISABLE KEYS */;
LOCK TABLES `MultiPlate_Run` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `MultiPlate_Run` ENABLE KEYS */;

--
-- Table structure for table `Multiple_Barcode`
--

DROP TABLE IF EXISTS `Multiple_Barcode`;
CREATE TABLE `Multiple_Barcode` (
  `Multiple_Barcode_ID` int(11) NOT NULL auto_increment,
  `Multiple_Text` varchar(100) default NULL,
  PRIMARY KEY  (`Multiple_Barcode_ID`),
  UNIQUE KEY `text` (`Multiple_Text`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Multiple_Barcode`
--


/*!40000 ALTER TABLE `Multiple_Barcode` DISABLE KEYS */;
LOCK TABLES `Multiple_Barcode` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Multiple_Barcode` ENABLE KEYS */;

--
-- Table structure for table `New_Stock`
--

DROP TABLE IF EXISTS `New_Stock`;
CREATE TABLE `New_Stock` (
  `Stock_ID` int(11) NOT NULL auto_increment,
  `Stock_Name` varchar(80) default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Stock_Lot_Number` varchar(80) default NULL,
  `Stock_Received` date default NULL,
  `Stock_Size` float default NULL,
  `Stock_Size_Units` enum('mL','uL','litres','mg','grams','kg','pcs','boxes','tubes','rxns','n/a') default NULL,
  `Stock_Description` text,
  `FK_Orders__ID` int(11) default NULL,
  `Stock_Type` enum('Solution','Reagent','Kit','Box','Microarray','Equipment','Service_Contract','Computer_Equip','Misc_Item','Matrix','Primer','Buffer') default NULL,
  `FK_Box__ID` int(11) default NULL,
  `Stock_Catalog_Number` varchar(80) default NULL,
  `Stock_Number_in_Batch` int(11) default NULL,
  `Stock_Cost` float default NULL,
  `FK_Organization__ID` int(11) default NULL,
  `Stock_Source` enum('Box','Order','Sample','Made in House') default NULL,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FK_Barcode_Label__ID` int(11) default NULL,
  `Identifier_Number` varchar(80) default NULL,
  `Identifier_Number_Type` enum('Component Number','Reference ID') default NULL,
  `Purchase_Order` varchar(20) default NULL,
  `FK_Stock_Catalog__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Stock_ID`),
  KEY `cat` (`Stock_Catalog_Number`),
  KEY `name` (`Stock_Name`),
  KEY `box` (`FK_Box__ID`),
  KEY `FK_Orders__ID` (`FK_Orders__ID`),
  KEY `FK_Barcode_Label__ID` (`FK_Barcode_Label__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Organization__ID` (`FK_Organization__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `grp_id` (`FK_Grp__ID`),
  KEY `employee_id` (`FK_Employee__ID`),
  KEY `barcode_label` (`FK_Barcode_Label__ID`),
  KEY `catnum` (`Stock_Catalog_Number`),
  KEY `stockname` (`Stock_Name`),
  KEY `lot` (`Stock_Lot_Number`),
  KEY `identifier` (`Identifier_Number_Type`),
  KEY `indentifier_number` (`Identifier_Number`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `New_Stock`
--


/*!40000 ALTER TABLE `New_Stock` DISABLE KEYS */;
LOCK TABLES `New_Stock` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `New_Stock` ENABLE KEYS */;

--
-- Table structure for table `Note`
--

DROP TABLE IF EXISTS `Note`;
CREATE TABLE `Note` (
  `Note_ID` int(11) NOT NULL auto_increment,
  `Note_Text` varchar(40) default NULL,
  `Note_Type` varchar(40) default NULL,
  `Note_Description` text,
  PRIMARY KEY  (`Note_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Note`
--


/*!40000 ALTER TABLE `Note` DISABLE KEYS */;
LOCK TABLES `Note` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Note` ENABLE KEYS */;

--
-- Table structure for table `Notice`
--

DROP TABLE IF EXISTS `Notice`;
CREATE TABLE `Notice` (
  `Notice_ID` int(11) NOT NULL auto_increment,
  `Notice_Text` text,
  `Notice_Subject` text,
  `Notice_Date` date default NULL,
  `Target_List` text,
  PRIMARY KEY  (`Notice_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Notice`
--


/*!40000 ALTER TABLE `Notice` DISABLE KEYS */;
LOCK TABLES `Notice` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Notice` ENABLE KEYS */;

--
-- Table structure for table `Object_Class`
--

DROP TABLE IF EXISTS `Object_Class`;
CREATE TABLE `Object_Class` (
  `Object_Class_ID` int(11) NOT NULL auto_increment,
  `Object_Class` varchar(40) NOT NULL default '',
  `Object_Type` varchar(40) default NULL,
  PRIMARY KEY  (`Object_Class_ID`),
  UNIQUE KEY `object_type_class` (`Object_Type`,`Object_Class`),
  KEY `Object_Type` (`Object_Type`),
  KEY `Object_Class` (`Object_Class`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='Object Types in the database, ie Enzyme, Antibiotic';

--
-- Dumping data for table `Object_Class`
--


/*!40000 ALTER TABLE `Object_Class` DISABLE KEYS */;
LOCK TABLES `Object_Class` WRITE;
INSERT INTO `Object_Class` VALUES (5,'Lab_Protocol',''),(8,'Lane',''),(3,'Plate',''),(4,'Run',''),(7,'Run','GelRun'),(1,'Antibiotic','Solution'),(6,'Enzyme','Solution');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Object_Class` ENABLE KEYS */;

--
-- Table structure for table `Optical_Density`
--

DROP TABLE IF EXISTS `Optical_Density`;
CREATE TABLE `Optical_Density` (
  `FK_Plate__ID` int(11) NOT NULL default '0',
  `260nm_Corrected` float default NULL,
  `280nm_Corrected` float default NULL,
  `Density` float default NULL,
  `Optical_Density_DateTime` datetime default NULL,
  `Concentration` float default NULL,
  `Optical_Density_ID` int(11) NOT NULL default '0',
  `Well` char(3) NOT NULL default '',
  `FK_Sample__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Well`,`Optical_Density_ID`),
  KEY `plate_id` (`FK_Plate__ID`),
  KEY `sample_id` (`FK_Sample__ID`),
  KEY `Optical_Density_ID` (`Optical_Density_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Optical_Density`
--


/*!40000 ALTER TABLE `Optical_Density` DISABLE KEYS */;
LOCK TABLES `Optical_Density` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Optical_Density` ENABLE KEYS */;

--
-- Table structure for table `Order_Notice`
--

DROP TABLE IF EXISTS `Order_Notice`;
CREATE TABLE `Order_Notice` (
  `Minimum_Units` int(11) default NULL,
  `Order_Text` text,
  `Catalog_Number` varchar(40) NOT NULL default '',
  `Notice_Sent` date default NULL,
  `Notice_Frequency` int(11) default NULL,
  `Target_List` text,
  `Maximum_Units` int(11) default '0',
  `Order_Notice_ID` int(11) NOT NULL auto_increment,
  `FK_Grp__ID` int(11) default NULL,
  PRIMARY KEY  (`Order_Notice_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Order_Notice`
--


/*!40000 ALTER TABLE `Order_Notice` DISABLE KEYS */;
LOCK TABLES `Order_Notice` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Order_Notice` ENABLE KEYS */;

--
-- Table structure for table `Ordered_Procedure`
--

DROP TABLE IF EXISTS `Ordered_Procedure`;
CREATE TABLE `Ordered_Procedure` (
  `Ordered_Procedure_ID` int(11) NOT NULL auto_increment,
  `FK_Object_Class__ID` int(11) NOT NULL default '0',
  `Object_ID` int(11) NOT NULL default '0',
  `Procedure_Order` tinyint(4) NOT NULL default '0',
  `FK_Pipeline__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Ordered_Procedure_ID`),
  KEY `Object_ID` (`Object_ID`),
  KEY `Object_Name` (`FK_Object_Class__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Ordered_Procedure`
--


/*!40000 ALTER TABLE `Ordered_Procedure` DISABLE KEYS */;
LOCK TABLES `Ordered_Procedure` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Ordered_Procedure` ENABLE KEYS */;

--
-- Table structure for table `Orders`
--

DROP TABLE IF EXISTS `Orders`;
CREATE TABLE `Orders` (
  `Orders_ID` int(11) NOT NULL auto_increment,
  `Orders_Item` text,
  `Orders_Quantity` int(11) default NULL,
  `Item_Size` float default NULL,
  `Item_Units` enum('mL','litres','mg','grams','kg','pcs','boxes','tubes','n/a') default NULL,
  `Orders_Catalog_Number` text,
  `Orders_Lot_Number` text,
  `Unit_Cost` float default NULL,
  `Orders_Notes` text,
  `Orders_Req_Number` text,
  `Orders_PO_Number` text,
  `Quote_Number` text,
  `Orders_Received` int(11) NOT NULL default '0',
  `Orders_Status` enum('On Order','Received','Incomplete','Pending') default NULL,
  `PO_Date` date default NULL,
  `Orders_Quantity_Received` int(11) NOT NULL default '0',
  `Req_Date` date default NULL,
  `Orders_Cost` float(6,2) default NULL,
  `Taxes` float default NULL,
  `Freight_Costs` float default NULL,
  `Total_Ledger_Amount` float default NULL,
  `Ledger_Period` text,
  `Expense_Code` text,
  `Serial_Num` text,
  `FK_Funding__Code` text NOT NULL,
  `Expense_Type` enum('Reagents','Equip - C','Equip -M','Glass','Plastics','Kits','Service','Other') default NULL,
  `Item_Unit` enum('EA','CS','BX','PK','RL','HR') default NULL,
  `Req_Number` text,
  `PO_Number` text,
  `Warranty` text,
  `MSDS` enum('Yes','No','N/A') default NULL,
  `old_Expense` text,
  `old_Org_Name` text,
  `Orders_Received_Date` date default NULL,
  `Currency` enum('Can','US') default 'Can',
  `FK_Account__ID` int(11) default NULL,
  `FKVendor_Organization__ID` int(11) default NULL,
  `FKManufacturer_Organization__ID` int(11) default NULL,
  `Orders_Item_Description` text,
  PRIMARY KEY  (`Orders_ID`),
  KEY `FKManufacturer_Organization__ID` (`FKManufacturer_Organization__ID`),
  KEY `FKVendor_Organization__ID` (`FKVendor_Organization__ID`),
  KEY `FK_Account__ID` (`FK_Account__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Orders`
--


/*!40000 ALTER TABLE `Orders` DISABLE KEYS */;
LOCK TABLES `Orders` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Orders` ENABLE KEYS */;

--
-- Table structure for table `Organism`
--

DROP TABLE IF EXISTS `Organism`;
CREATE TABLE `Organism` (
  `Organism_ID` int(11) NOT NULL auto_increment,
  `Organism_Name` varchar(255) NOT NULL default '',
  `Species` varchar(255) default NULL,
  `Sub_species` varchar(255) default NULL,
  `Common_Name` varchar(255) default NULL,
  PRIMARY KEY  (`Organism_ID`),
  UNIQUE KEY `Organism_Name` (`Organism_Name`),
  KEY `common_name` (`Common_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Organism`
--


/*!40000 ALTER TABLE `Organism` DISABLE KEYS */;
LOCK TABLES `Organism` WRITE;
INSERT INTO `Organism` VALUES (1,'Populus trichocarpa','','',''),(2,'Unspecified','','','unidentified'),(3,'Escherichia coli','','',''),(4,'Spruce','','','Picea glauca'),(5,'Caenorhabditis elegans','','',''),(6,'Haemophilus influenzae','','',''),(7,'Oncorhynchus nerka','','',''),(8,'Ratus ratus','','','Rattus'),(9,'Ustilago hordei','','',''),(10,'Xenopus','','',''),(11,'Chicken','','','Tympanuchus'),(12,'Homo sapiens','','',''),(13,'Obliquum clavigerum','','','Schizodium obliquum subsp. clavigerum'),(14,'Puccinia triticina','','',''),(15,'Ustilago maydis','','',''),(16,'Euglena gracilis','','',''),(17,'Picea sitchensis','','',''),(18,'Pig','','','Sus scrofa'),(19,'Salmo salar','','',''),(20,'Chlamydia trachomatis','','',''),(21,'Bos taurus','','',''),(22,'Unknown','','','unidentified'),(23,'Cryptococcus neoformans','','',''),(24,'Poplar','','','Populus'),(25,'Rhodococcus','','',''),(26,'Mus musculus','','',''),(27,'Felis catus','','',''),(28,'Caenorhabditis briggsae','','',''),(29,'Picea mariana','','',''),(30,'Drosophila melanogaster','','',''),(31,'Pincea glauca','','','Picea glauca'),(32,'Gibbon','Nomascus leucogenys','','Nomascus leucogenys'),(33,'Horseshoe Bat','Rhinolophus ferrumequinum','','Rhinolophus ferrumequinum'),(34,'Winter wheat','Triticum aestivum','Norstar','Pseudomonas aeruginosa PAO1'),(35,'Rainbow Smelt','Osmerus Mordax','','Osmerus Mordax'),(36,'Flying Fox','Pteropus vampyrus','','Pteropus vampyrus'),(37,'Tree shrew','Tupaia belangeri','','Tupaia belangeri'),(38,'Rock Hyrax','Procavia capensis','','Procavia capensis'),(39,'Horse','Equus caballus','','Equus caballus'),(40,'Spruce Budworm','Christoneura Fumiferana','','Choristoneura fumiferana'),(41,'Planarian','Schmidtea mediterranea','','Schmidtea mediterranea'),(42,'Schmidtea mediterranea','','',''),(43,'Mixed','','','mixed subtypes'),(44,'Caronavirus','','','coronavirus'),(45,'Arabidopsis','Arabidopsis thaliana','','Arabidopsis thaliana'),(46,'Mosquito','Aedes aegypti','','Aedes aegypti'),(47,'P. aeruginosa PA01','Pseudomonas aeruginosa PA01','','Pseudomonas aeruginosa PAO1');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Organism` ENABLE KEYS */;

--
-- Table structure for table `Organization`
--

DROP TABLE IF EXISTS `Organization`;
CREATE TABLE `Organization` (
  `Organization_Name` varchar(80) default NULL,
  `Address` text,
  `City` text,
  `State` text,
  `Zip` text,
  `Phone` text,
  `Fax` text,
  `Email` text,
  `Country` text,
  `Notes` text,
  `Organization_ID` int(11) NOT NULL auto_increment,
  `Organization_Type` set('Manufacturer','Collaborator') default NULL,
  `Website` text,
  `Organization_FullName` text,
  PRIMARY KEY  (`Organization_ID`),
  UNIQUE KEY `name` (`Organization_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Organization`
--


/*!40000 ALTER TABLE `Organization` DISABLE KEYS */;
LOCK TABLES `Organization` WRITE;
INSERT INTO `Organization` VALUES ('CMMT','','','','','','','','','',1,'Manufacturer','','Mandel Scientific');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Organization` ENABLE KEYS */;

--
-- Table structure for table `Original_Source`
--

DROP TABLE IF EXISTS `Original_Source`;
CREATE TABLE `Original_Source` (
  `Original_Source_ID` int(11) NOT NULL auto_increment,
  `Original_Source_Name` varchar(40) NOT NULL default '',
  `Organism` varchar(40) default NULL,
  `Sex` varchar(20) default NULL,
  `Tissue` varchar(40) default NULL,
  `Strain` varchar(40) default NULL,
  `Host` text NOT NULL,
  `Description` text,
  `FK_Contact__ID` int(11) default NULL,
  `FKCreated_Employee__ID` int(11) default NULL,
  `Defined_Date` date NOT NULL default '0000-00-00',
  `FK_Stage__ID` int(11) NOT NULL default '0',
  `FK_Tissue__ID` int(11) NOT NULL default '0',
  `FK_Organism__ID` int(11) NOT NULL default '0',
  `Subtissue_temp` varchar(40) default NULL,
  `Tissue_temp` varchar(40) NOT NULL default '',
  `Organism_temp` varchar(40) default NULL,
  `Stage_temp` varchar(40) default NULL,
  `Note_temp` varchar(40) NOT NULL default '',
  `Thelier_temp` varchar(40) default NULL,
  `Sample_Available` enum('Yes','No','Later') default NULL,
  `FK_Taxonomy__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Original_Source_ID`),
  UNIQUE KEY `OS_Name` (`Original_Source_Name`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`),
  KEY `FKCreated_Employee__ID` (`FKCreated_Employee__ID`),
  KEY `taxonomy` (`FK_Taxonomy__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Original_Source`
--


/*!40000 ALTER TABLE `Original_Source` DISABLE KEYS */;
LOCK TABLES `Original_Source` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Original_Source` ENABLE KEYS */;

--
-- Table structure for table `Original_Source_Attribute`
--

DROP TABLE IF EXISTS `Original_Source_Attribute`;
CREATE TABLE `Original_Source_Attribute` (
  `FK_Original_Source__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text NOT NULL,
  `Original_Source_Attribute_ID` int(11) NOT NULL auto_increment,
  `FK_Employee__ID` int(11) default NULL,
  `Set_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`Original_Source_Attribute_ID`),
  UNIQUE KEY `original_source_attribute` (`FK_Original_Source__ID`,`FK_Attribute__ID`),
  KEY `FK_Original_Source__ID` (`FK_Original_Source__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Original_Source_Attribute`
--


/*!40000 ALTER TABLE `Original_Source_Attribute` DISABLE KEYS */;
LOCK TABLES `Original_Source_Attribute` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Original_Source_Attribute` ENABLE KEYS */;

--
-- Table structure for table `PCR_Library`
--

DROP TABLE IF EXISTS `PCR_Library`;
CREATE TABLE `PCR_Library` (
  `PCR_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Sequencing_Library__ID` int(11) NOT NULL default '0',
  `Species` varchar(40) default NULL,
  `Cleanup_Procedure` text NOT NULL,
  `PCR_Product_Size` int(11) NOT NULL default '0',
  `Concentration_Per_Well` float(10,3) NOT NULL default '0.000',
  PRIMARY KEY  (`PCR_Library_ID`),
  KEY `lib_id` (`FK_Sequencing_Library__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `PCR_Library`
--


/*!40000 ALTER TABLE `PCR_Library` DISABLE KEYS */;
LOCK TABLES `PCR_Library` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `PCR_Library` ENABLE KEYS */;

--
-- Table structure for table `Parameter`
--

DROP TABLE IF EXISTS `Parameter`;
CREATE TABLE `Parameter` (
  `FK_Standard_Solution__ID` int(11) default NULL,
  `Parameter_Name` varchar(40) default NULL,
  `Parameter_Description` text,
  `Parameter_Value` float default NULL,
  `Parameter_Type` enum('Static','Multiple','Variable','Hidden') default NULL,
  `Parameter_ID` int(11) NOT NULL auto_increment,
  `Parameter_Format` text,
  `Parameter_Units` enum('ml','ul','mg','ug','g','l') default NULL,
  `Parameter_SType` enum('Reagent','Solution','Primer','Buffer','Matrix') default NULL,
  `Parameter_Prompt` varchar(30) NOT NULL default '',
  PRIMARY KEY  (`Parameter_ID`),
  UNIQUE KEY `FK_Standard_Solution__ID` (`FK_Standard_Solution__ID`,`Parameter_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Parameter`
--


/*!40000 ALTER TABLE `Parameter` DISABLE KEYS */;
LOCK TABLES `Parameter` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Parameter` ENABLE KEYS */;

--
-- Table structure for table `Pipeline`
--

DROP TABLE IF EXISTS `Pipeline`;
CREATE TABLE `Pipeline` (
  `Pipeline_ID` int(11) NOT NULL auto_increment,
  `Pipeline_Name` varchar(40) default NULL,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `Pipeline_Description` text,
  `Pipeline_Code` char(3) NOT NULL default '',
  `FKParent_Pipeline__ID` int(11) default NULL,
  `FK_Pipeline_Group__ID` int(11) default NULL,
  `Pipeline_Status` enum('Active','Inactive') default 'Active',
  PRIMARY KEY  (`Pipeline_ID`),
  UNIQUE KEY `pipelineCode` (`Pipeline_Code`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Pipeline_Group__ID` (`FK_Pipeline_Group__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Pipeline`
--


/*!40000 ALTER TABLE `Pipeline` DISABLE KEYS */;
LOCK TABLES `Pipeline` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Pipeline` ENABLE KEYS */;

--
-- Table structure for table `Pipeline_Group`
--

DROP TABLE IF EXISTS `Pipeline_Group`;
CREATE TABLE `Pipeline_Group` (
  `Pipeline_Group_ID` int(11) NOT NULL auto_increment,
  `Pipeline_Group_Name` varchar(40) default NULL,
  PRIMARY KEY  (`Pipeline_Group_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Pipeline_Group`
--


/*!40000 ALTER TABLE `Pipeline_Group` DISABLE KEYS */;
LOCK TABLES `Pipeline_Group` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Pipeline_Group` ENABLE KEYS */;

--
-- Table structure for table `Pipeline_Step`
--

DROP TABLE IF EXISTS `Pipeline_Step`;
CREATE TABLE `Pipeline_Step` (
  `Pipeline_Step_ID` int(11) NOT NULL auto_increment,
  `FK_Object_Class__ID` int(11) NOT NULL default '0',
  `Object_ID` int(11) NOT NULL default '0',
  `Pipeline_Step_Order` tinyint(4) NOT NULL default '0',
  `FK_Pipeline__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Pipeline_Step_ID`),
  KEY `Object_ID` (`Object_ID`),
  KEY `Object_Name` (`FK_Object_Class__ID`),
  KEY `FK_Pipeline__ID` (`FK_Pipeline__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Pipeline_Step`
--


/*!40000 ALTER TABLE `Pipeline_Step` DISABLE KEYS */;
LOCK TABLES `Pipeline_Step` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Pipeline_Step` ENABLE KEYS */;

--
-- Table structure for table `Pipeline_StepRelationship`
--

DROP TABLE IF EXISTS `Pipeline_StepRelationship`;
CREATE TABLE `Pipeline_StepRelationship` (
  `Pipeline_StepRelationship_ID` int(11) NOT NULL auto_increment,
  `FKParent_Pipeline_Step__ID` int(11) NOT NULL default '0',
  `FKChild_Pipeline_Step__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Pipeline_StepRelationship_ID`),
  KEY `FKParent_Pipeline_Step__ID` (`FKParent_Pipeline_Step__ID`),
  KEY `FKChild_Pipeline_Step__ID` (`FKChild_Pipeline_Step__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Pipeline_StepRelationship`
--


/*!40000 ALTER TABLE `Pipeline_StepRelationship` DISABLE KEYS */;
LOCK TABLES `Pipeline_StepRelationship` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Pipeline_StepRelationship` ENABLE KEYS */;

--
-- Table structure for table `Plate`
--

DROP TABLE IF EXISTS `Plate`;
CREATE TABLE `Plate` (
  `Plate_ID` int(11) NOT NULL auto_increment,
  `Plate_Size` enum('1-well','8-well','16-well','32-well','48-well','64-well','80-well','96-well','384-well','1.5 ml','50 ml','15 ml','5 ml','2 ml','0.5 ml','0.2 ml') default NULL,
  `Plate_Created` datetime default '0000-00-00 00:00:00',
  `FK_Library__Name` varchar(40) default NULL,
  `FK_Rack__ID` int(11) default NULL,
  `Plate_Number` int(4) NOT NULL default '0',
  `FK_Employee__ID` int(11) default NULL,
  `FKParent_Plate__ID` int(11) default NULL,
  `Plate_Comments` text NOT NULL,
  `Plate_Status` enum('Active','Pre-Printed','Reserved','Temporary','Failed','Thrown Out','Exported','Archived','On Hold') default NULL,
  `Plate_Test_Status` enum('Test','Production') default 'Production',
  `FK_Plate_Format__ID` int(11) default NULL,
  `Plate_Application` enum('Sequencing','PCR','Mapping','Gene Expression','Affymetrix') default NULL,
  `Plate_Type` enum('Library_Plate','Tube','Array') default NULL,
  `FKOriginal_Plate__ID` int(10) unsigned default NULL,
  `Current_Volume` float default NULL,
  `Current_Volume_Units` enum('l','ml','ul','nl','g','mg','ug','ng') NOT NULL default 'ul',
  `Plate_Content_Type` enum('DNA','RNA','Protein','Mixed','Amplicon','Clone','mRNA','Tissue','Cells','RNA - DNase Treated','cDNA','1st strand cDNA','Amplified cDNA','Ditag','Concatemer - Insert','Concatemer - Cloned') default NULL,
  `Parent_Quadrant` enum('','a','b','c','d') NOT NULL default '',
  `Plate_Parent_Well` char(3) NOT NULL default '',
  `QC_Status` enum('N/A','Pending','Failed','Re-Test','Passed') default 'N/A',
  `FK_Branch__Code` varchar(5) NOT NULL default '',
  `FK_Pipeline__ID` int(11) NOT NULL default '0',
  `Plate_Label` varchar(40) default NULL,
  `FKLast_Prep__ID` int(11) default NULL,
  `FK_Sample_Type__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Plate_ID`),
  KEY `lib` (`FK_Library__Name`),
  KEY `user` (`FK_Employee__ID`),
  KEY `made` (`Plate_Created`),
  KEY `number` (`Plate_Number`),
  KEY `orderlist` (`FK_Library__Name`,`Plate_Number`),
  KEY `parent` (`FKParent_Plate__ID`),
  KEY `format` (`FK_Plate_Format__ID`),
  KEY `FK_Rack__ID` (`FK_Rack__ID`),
  KEY `FKOriginal_Plate__ID` (`FKOriginal_Plate__ID`),
  KEY `FKOriginal_Plate__ID_2` (`FKOriginal_Plate__ID`),
  KEY `Plate_Status` (`Plate_Status`),
  KEY `Plate_Content_Type` (`Plate_Content_Type`),
  KEY `FKLast_Prep__ID` (`FKLast_Prep__ID`),
  KEY `label` (`Plate_Label`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Plate`
--


/*!40000 ALTER TABLE `Plate` DISABLE KEYS */;
LOCK TABLES `Plate` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Plate` ENABLE KEYS */;

--
-- Table structure for table `Plate_Attribute`
--

DROP TABLE IF EXISTS `Plate_Attribute`;
CREATE TABLE `Plate_Attribute` (
  `FK_Plate__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text NOT NULL,
  `Plate_Attribute_ID` int(11) NOT NULL auto_increment,
  `FK_Employee__ID` int(11) default NULL,
  `Set_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`Plate_Attribute_ID`),
  UNIQUE KEY `FK_Attribute__ID_2` (`FK_Attribute__ID`,`FK_Plate__ID`),
  KEY `FK_Plate__ID` (`FK_Plate__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Plate_Attribute`
--


/*!40000 ALTER TABLE `Plate_Attribute` DISABLE KEYS */;
LOCK TABLES `Plate_Attribute` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Plate_Attribute` ENABLE KEYS */;

--
-- Table structure for table `Plate_Format`
--

DROP TABLE IF EXISTS `Plate_Format`;
CREATE TABLE `Plate_Format` (
  `Plate_Format_ID` int(11) NOT NULL auto_increment,
  `Plate_Format_Type` char(40) default NULL,
  `Plate_Format_Size` enum('1-well','8-well','96-well','384-well','1.5 ml','50 ml','15 ml','5 ml','2 ml','0.5 ml','0.2 ml') default NULL,
  `Plate_Format_Status` enum('Active','Inactive') default NULL,
  `FK_Barcode_Label__ID` int(11) default NULL,
  `Max_Row` char(2) default NULL,
  `Max_Col` tinyint(4) default NULL,
  `Plate_Format_Style` enum('Plate','Tube','Array','Gel') default NULL,
  `Capacity` char(4) default NULL,
  `Capacity_Units` char(4) default NULL,
  `Wells` smallint(6) NOT NULL default '1',
  `Well_Lookup_Key` enum('Plate_384','Plate_96','Gel_121_Standard','Gel_121_Custom','Tube') default NULL,
  PRIMARY KEY  (`Plate_Format_ID`),
  UNIQUE KEY `name` (`Plate_Format_Type`,`Plate_Format_Size`),
  KEY `FK_Barcode_Label__ID` (`FK_Barcode_Label__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Plate_Format`
--


/*!40000 ALTER TABLE `Plate_Format` DISABLE KEYS */;
LOCK TABLES `Plate_Format` WRITE;
INSERT INTO `Plate_Format` VALUES (1,'Genetix - Glycerol','384-well','Active',2,'P',24,'Plate','','',384,''),(2,'Beckman - Culture','96-well','Active',1,'H',12,'Plate','','',96,''),(3,'Robbins - ET','96-well','Active',2,'H',12,'Plate','','',96,''),(4,'Costar - Round Bottom Assay','96-well','Inactive',2,'H',12,'Plate','','',96,''),(5,'NUNC','96-well','Inactive',2,'H',12,'Plate','','',96,''),(6,'MicroAmp','96-well','Active',2,'H',12,'Plate','','',96,''),(7,'MJR384','384-well','Active',2,'P',24,'Plate','','',384,''),(8,'PE384','384-well','Active',2,'P',24,'Plate','','',384,''),(9,'384-well Axygen-384-240','384-well','Active',2,'P',24,'Plate','','',384,''),(10,'MJR96 - skirted','96-well','Active',2,'H',12,'Plate','','',96,''),(11,'IS800 - skirted','96-well','Inactive',2,'H',12,'Plate','','',96,''),(12,'Axygen_OLD','96-well','Inactive',2,'H',12,'Plate','','',96,''),(13,'Glycerol96','96-well','Active',2,'H',12,'Plate','','',96,''),(14,'BD_Falcon','96-well','Active',2,'H',12,'Plate','','',96,''),(15,'Axygen-384-240','384-well','Active',1,'P',24,'Plate','','',384,''),(16,'Virtual','96-well','Active',2,'H',12,'Plate','','',96,''),(17,'Virtual Slice','','Active',2,'H',12,'Plate','','',1,''),(18,'Virtual 384','384-well','Active',2,'P',24,'Plate','','',384,''),(19,'Tube','1.5 ml','Active',6,'A',1,'Tube','1.5','ml',1,''),(20,'Undefined - To Be Determined','','Active',2,'A',1,'','','',1,''),(21,'Wallac384','384-well','Active',2,'P',24,'Plate','384','well',384,''),(22,'Axygen96_RBHH','96-well','Active',1,'H',12,'Plate','96','well',96,''),(23,'Phase Lock Gel-Heavy','','Active',6,'A',1,'Tube','2','ml',1,''),(26,'Phase-Lock Gel Tube','','Active',6,'A',1,'Tube','15','ml',1,''),(27,'Eppendorf Tube','','Active',6,'A-',9,'Tube','','',1,''),(28,' cRNA Cleanup column','1.5 ml','Active',6,'A',1,'Tube','','',1,''),(29,' cDNA Cleanup Column','1.5 ml','Active',6,'A',1,'Tube','1.5','ml',1,''),(30,'Non-Stick','1.5 ml','Active',6,'Z',9,'Tube','1.5','ml',1,''),(31,'AB384','384-well','Active',2,'P',24,'Plate','384','well',384,''),(32,'Screw-cap Conical Tube','','Active',6,'A',1,'Tube','15','ml',1,''),(33,'Tube','','Active',6,'A',1,'Tube','','',1,''),(34,'cDNA Cleanup Column','','Active',6,'A',1,'Tube','2','ml',1,''),(35,'cRNA Cleanup Column','','Active',6,'A',1,'Tube','2','ml',1,''),(36,'Agar Plate','','Active',19,'A',1,'Tube','','',1,''),(37,'Manual 121 Lane Gel','','Active',2,'H',12,'Gel','121','',96,'Gel_121_Standard'),(38,'Tube','50 ml','Active',6,'A',1,'Tube','50','ml',1,''),(39,'Tube','15 ml','Active',6,'A',1,'Tube','15','ml',1,''),(40,'Tube','5 ml','Active',6,'A',1,'Tube','5','ml',1,''),(41,'Tube','2 ml','Active',6,'A',1,'Tube','2','ml',1,''),(42,'Eppendorf','2 ml','Active',6,'Z',9,'Tube','2','ml',1,''),(43,'Phase Lock Gel Tube Heavy','2 ml','Active',6,'Z',9,'Tube','2','ml',1,''),(44,'Tube','0.5 ml','Active',6,'A',1,'Tube','0.5','ml',1,''),(45,'Tube','0.2 ml','Active',6,'A',1,'Tube','0.2','ml',1,''),(46,'Non-stick','0.5 ml','Active',6,'Z',9,'Tube','0.5','ml',1,''),(47,'Greiner','96-well','Active',2,'H',12,'Plate','','well',96,''),(48,'ABGene','96-well','Active',2,'H',12,'Plate','96','well',96,''),(49,'Whatman','96-well','Active',1,'H',12,'Plate','0.8','ml',96,''),(50,'Axygen96 P-96-450V','96-well','Active',2,'H',12,'Plate','96','well',96,''),(51,'Abgene_HHRB','96-well','Active',1,'H',12,'Plate','1.2','ml',96,''),(52,'Genetix X6004','384-well','Active',2,'P',24,'Plate','384','well',384,''),(53,'Genechip','1-well','Active',6,'A',1,'Array','','',1,''),(54,'MJR96 - unskirted','96-well','Active',2,'H',12,'Plate','96','well',96,''),(55,'Agar Plate Q Tray','1-well','Active',19,'A',1,'Tube','','',1,''),(56,'NUNC','384-well','Active',2,'P',24,'Plate','0.12','ml',384,''),(57,'Abgene - Culture','384-well','Active',1,'P',24,'Plate','','well',384,''),(58,'FlowCell','8-well','Active',1,'A',8,'Plate','8','well',8,''),(59,'Square Well - AB1127','96-well','Active',1,'A',1,'Plate','96','well',96,'');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Plate_Format` ENABLE KEYS */;

--
-- Table structure for table `Plate_Prep`
--

DROP TABLE IF EXISTS `Plate_Prep`;
CREATE TABLE `Plate_Prep` (
  `Plate_Prep_ID` int(11) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) default NULL,
  `FK_Prep__ID` int(11) default NULL,
  `FK_Plate_Set__Number` int(11) default NULL,
  `FK_Equipment__ID` int(11) default NULL,
  `FK_Solution__ID` int(11) default NULL,
  `Solution_Quantity` float default NULL,
  `Solution_Quantity_Units` enum('pl','nl','ul','ml','l') default NULL,
  `Transfer_Quantity` float default NULL,
  `Transfer_Quantity_Units` enum('pl','nl','ul','ml','l','g','mg','ug','ng','pg') default NULL,
  PRIMARY KEY  (`Plate_Prep_ID`),
  KEY `plate` (`FK_Plate__ID`),
  KEY `plate_set` (`FK_Plate_Set__Number`),
  KEY `prep` (`FK_Prep__ID`),
  KEY `FK_Equipment__ID` (`FK_Equipment__ID`),
  KEY `FK_Solution__ID` (`FK_Solution__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Plate_Prep`
--


/*!40000 ALTER TABLE `Plate_Prep` DISABLE KEYS */;
LOCK TABLES `Plate_Prep` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Plate_Prep` ENABLE KEYS */;

--
-- Table structure for table `Plate_PrimerPlateWell`
--

DROP TABLE IF EXISTS `Plate_PrimerPlateWell`;
CREATE TABLE `Plate_PrimerPlateWell` (
  `Plate_PrimerPlateWell_ID` int(11) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) NOT NULL default '0',
  `FK_Primer_Plate_Well__ID` int(11) NOT NULL default '0',
  `Plate_Well` char(3) default NULL,
  PRIMARY KEY  (`Plate_PrimerPlateWell_ID`),
  KEY `plate` (`FK_Plate__ID`),
  KEY `primer` (`FK_Primer_Plate_Well__ID`),
  KEY `well` (`Plate_Well`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Plate_PrimerPlateWell`
--


/*!40000 ALTER TABLE `Plate_PrimerPlateWell` DISABLE KEYS */;
LOCK TABLES `Plate_PrimerPlateWell` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Plate_PrimerPlateWell` ENABLE KEYS */;

--
-- Table structure for table `Plate_Sample`
--

DROP TABLE IF EXISTS `Plate_Sample`;
CREATE TABLE `Plate_Sample` (
  `Plate_Sample_ID` int(11) NOT NULL auto_increment,
  `FKOriginal_Plate__ID` int(11) NOT NULL default '0',
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `Well` char(3) default NULL,
  PRIMARY KEY  (`Plate_Sample_ID`),
  UNIQUE KEY `origplate` (`FKOriginal_Plate__ID`,`Well`),
  KEY `sampleid` (`FK_Sample__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Plate_Sample`
--


/*!40000 ALTER TABLE `Plate_Sample` DISABLE KEYS */;
LOCK TABLES `Plate_Sample` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Plate_Sample` ENABLE KEYS */;

--
-- Table structure for table `Plate_Schedule`
--

DROP TABLE IF EXISTS `Plate_Schedule`;
CREATE TABLE `Plate_Schedule` (
  `Plate_Schedule_ID` int(11) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) NOT NULL default '0',
  `FK_Pipeline__ID` int(11) NOT NULL default '0',
  `Plate_Schedule_Priority` tinyint(4) NOT NULL default '0',
  PRIMARY KEY  (`Plate_Schedule_ID`),
  KEY `FK_Plate__ID` (`FK_Plate__ID`),
  KEY `FK_Pipeline__ID` (`FK_Pipeline__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Plate_Schedule`
--


/*!40000 ALTER TABLE `Plate_Schedule` DISABLE KEYS */;
LOCK TABLES `Plate_Schedule` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Plate_Schedule` ENABLE KEYS */;

--
-- Table structure for table `Plate_Set`
--

DROP TABLE IF EXISTS `Plate_Set`;
CREATE TABLE `Plate_Set` (
  `Plate_Set_ID` int(4) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) default NULL,
  `Plate_Set_Number` int(11) default NULL,
  `FKParent_Plate_Set__Number` int(11) default NULL,
  PRIMARY KEY  (`Plate_Set_ID`),
  KEY `num` (`Plate_Set_Number`),
  KEY `FK_Plate__ID` (`FK_Plate__ID`),
  KEY `parent_set` (`FKParent_Plate_Set__Number`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Plate_Set`
--


/*!40000 ALTER TABLE `Plate_Set` DISABLE KEYS */;
LOCK TABLES `Plate_Set` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Plate_Set` ENABLE KEYS */;

--
-- Table structure for table `Plate_Tray`
--

DROP TABLE IF EXISTS `Plate_Tray`;
CREATE TABLE `Plate_Tray` (
  `Plate_Tray_ID` int(11) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) NOT NULL default '0',
  `FK_Tray__ID` int(11) NOT NULL default '0',
  `Plate_Position` char(3) NOT NULL default 'N/A',
  PRIMARY KEY  (`Plate_Tray_ID`),
  UNIQUE KEY `FK_Plate__ID` (`FK_Plate__ID`),
  UNIQUE KEY `Plate_Position` (`FK_Tray__ID`,`Plate_Position`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='For multiple plates on a tray';

--
-- Dumping data for table `Plate_Tray`
--


/*!40000 ALTER TABLE `Plate_Tray` DISABLE KEYS */;
LOCK TABLES `Plate_Tray` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Plate_Tray` ENABLE KEYS */;

--
-- Table structure for table `Plate_Tube`
--

DROP TABLE IF EXISTS `Plate_Tube`;
CREATE TABLE `Plate_Tube` (
  `Plate_Tube_ID` int(11) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) default NULL,
  `FK_Tube__ID` int(11) default NULL,
  PRIMARY KEY  (`Plate_Tube_ID`),
  KEY `FK_Tube__ID` (`FK_Tube__ID`),
  KEY `FK_Plate__ID` (`FK_Plate__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Plate_Tube`
--


/*!40000 ALTER TABLE `Plate_Tube` DISABLE KEYS */;
LOCK TABLES `Plate_Tube` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Plate_Tube` ENABLE KEYS */;

--
-- Table structure for table `Pool`
--

DROP TABLE IF EXISTS `Pool`;
CREATE TABLE `Pool` (
  `Pool_ID` int(11) NOT NULL auto_increment,
  `Pool_Description` text NOT NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Pool_Date` date NOT NULL default '0000-00-00',
  `Pool_Comments` text,
  `Pool_Type` enum('Library','Sample','Transposon') default NULL,
  PRIMARY KEY  (`Pool_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Pool`
--


/*!40000 ALTER TABLE `Pool` DISABLE KEYS */;
LOCK TABLES `Pool` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Pool` ENABLE KEYS */;

--
-- Table structure for table `PoolSample`
--

DROP TABLE IF EXISTS `PoolSample`;
CREATE TABLE `PoolSample` (
  `PoolSample_ID` int(11) NOT NULL auto_increment,
  `FK_Pool__ID` int(11) NOT NULL default '0',
  `FK_Plate__ID` int(11) NOT NULL default '0',
  `Well` char(3) default NULL,
  `FK_Sample__ID` int(11) default NULL,
  `Sample_Quantity_Units` enum('ml','ul','mg','ug','ng','pg') default NULL,
  `Sample_Quantity` float default NULL,
  PRIMARY KEY  (`PoolSample_ID`),
  KEY `sample` (`FK_Sample__ID`),
  KEY `pool` (`FK_Pool__ID`),
  KEY `plated` (`FK_Plate__ID`,`Well`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `PoolSample`
--


/*!40000 ALTER TABLE `PoolSample` DISABLE KEYS */;
LOCK TABLES `PoolSample` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `PoolSample` ENABLE KEYS */;

--
-- Table structure for table `Prep`
--

DROP TABLE IF EXISTS `Prep`;
CREATE TABLE `Prep` (
  `Prep_Name` varchar(80) default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Prep_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `Prep_Time` text,
  `Prep_Conditions` text,
  `Prep_Comments` text,
  `Prep_Failure_Date` datetime NOT NULL default '0000-00-00 00:00:00',
  `Prep_Action` enum('Completed','Failed','Skipped') default NULL,
  `FK_Lab_Protocol__ID` int(11) default NULL,
  `Prep_ID` int(11) NOT NULL auto_increment,
  `FK_FailureReason__ID` int(11) default NULL,
  `Attr_temp` text,
  PRIMARY KEY  (`Prep_ID`),
  KEY `protocol` (`FK_Lab_Protocol__ID`,`Prep_Name`),
  KEY `timestamp` (`Prep_DateTime`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_FailureReason__ID` (`FK_FailureReason__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Prep`
--


/*!40000 ALTER TABLE `Prep` DISABLE KEYS */;
LOCK TABLES `Prep` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Prep` ENABLE KEYS */;

--
-- Table structure for table `Prep_Attribute`
--

DROP TABLE IF EXISTS `Prep_Attribute`;
CREATE TABLE `Prep_Attribute` (
  `FK_Prep__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text NOT NULL,
  `Prep_Attribute_ID` int(11) NOT NULL auto_increment,
  `FK_Employee__ID` int(11) default NULL,
  `Set_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`Prep_Attribute_ID`),
  UNIQUE KEY `FK_Attribute__ID_2` (`FK_Attribute__ID`,`FK_Prep__ID`),
  KEY `FK_Prep__ID` (`FK_Prep__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Prep_Attribute`
--


/*!40000 ALTER TABLE `Prep_Attribute` DISABLE KEYS */;
LOCK TABLES `Prep_Attribute` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Prep_Attribute` ENABLE KEYS */;

--
-- Table structure for table `Prep_Attribute_Option`
--

DROP TABLE IF EXISTS `Prep_Attribute_Option`;
CREATE TABLE `Prep_Attribute_Option` (
  `Prep_Attribute_Option_ID` int(11) NOT NULL auto_increment,
  `FK_Protocol_Step__ID` int(11) NOT NULL default '0',
  `Option_Description` text,
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Prep_Attribute_Option_ID`),
  KEY `FK_Protocol_Step__ID` (`FK_Protocol_Step__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Prep_Attribute_Option`
--


/*!40000 ALTER TABLE `Prep_Attribute_Option` DISABLE KEYS */;
LOCK TABLES `Prep_Attribute_Option` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Prep_Attribute_Option` ENABLE KEYS */;

--
-- Table structure for table `Prep_Detail_Option`
--

DROP TABLE IF EXISTS `Prep_Detail_Option`;
CREATE TABLE `Prep_Detail_Option` (
  `Prep_Detail_Option_ID` int(11) NOT NULL auto_increment,
  `FK_Protocol_Step__ID` int(11) NOT NULL default '0',
  `Option_Description` text,
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Prep_Detail_Option_ID`),
  KEY `FK_Protocol_Step__ID` (`FK_Protocol_Step__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Prep_Detail_Option`
--


/*!40000 ALTER TABLE `Prep_Detail_Option` DISABLE KEYS */;
LOCK TABLES `Prep_Detail_Option` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Prep_Detail_Option` ENABLE KEYS */;

--
-- Table structure for table `Prep_Details`
--

DROP TABLE IF EXISTS `Prep_Details`;
CREATE TABLE `Prep_Details` (
  `Prep_Details_ID` int(11) NOT NULL auto_increment,
  `FK_Prep__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Prep_Details_Value` text,
  PRIMARY KEY  (`Prep_Details_ID`),
  KEY `prep_id` (`FK_Prep__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Prep_Details`
--


/*!40000 ALTER TABLE `Prep_Details` DISABLE KEYS */;
LOCK TABLES `Prep_Details` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Prep_Details` ENABLE KEYS */;

--
-- Table structure for table `Primer`
--

DROP TABLE IF EXISTS `Primer`;
CREATE TABLE `Primer` (
  `Primer_Name` varchar(40) NOT NULL default '',
  `Primer_Sequence` text NOT NULL,
  `Primer_ID` int(2) NOT NULL auto_increment,
  `Purity` text,
  `Tm1` int(2) default NULL,
  `Tm50` int(2) default NULL,
  `GC_Percent` int(2) default NULL,
  `Coupling_Eff` float(10,2) default NULL,
  `Primer_Type` enum('Standard','Custom','Oligo','Amplicon','Adapter') default NULL,
  `Primer_OrderDateTime` datetime default NULL,
  `Primer_External_Order_Number` varchar(80) default NULL,
  `Primer_Status` enum('','Ordered','Received','Inactive') default '',
  PRIMARY KEY  (`Primer_ID`),
  UNIQUE KEY `primer` (`Primer_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Primer`
--


/*!40000 ALTER TABLE `Primer` DISABLE KEYS */;
LOCK TABLES `Primer` WRITE;
INSERT INTO `Primer` VALUES ('M13 Reverse','caggaaacagctatgac',1,'Desalted',61,39,47,99.00,'Standard','0000-00-00 00:00:00','','');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Primer` ENABLE KEYS */;

--
-- Table structure for table `Primer_Customization`
--

DROP TABLE IF EXISTS `Primer_Customization`;
CREATE TABLE `Primer_Customization` (
  `Primer_Customization_ID` int(11) NOT NULL auto_increment,
  `FK_Primer__Name` varchar(40) NOT NULL default '',
  `Tm_Working` float(5,2) default NULL,
  `Direction` enum('Forward','Reverse','Unknown') default 'Unknown',
  `Amplicon_Length` int(11) default NULL,
  `Position` enum('Outer','Nested') default NULL,
  `nt_index` int(11) default NULL,
  PRIMARY KEY  (`Primer_Customization_ID`),
  KEY `fk_primer` (`FK_Primer__Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Primer_Customization`
--


/*!40000 ALTER TABLE `Primer_Customization` DISABLE KEYS */;
LOCK TABLES `Primer_Customization` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Primer_Customization` ENABLE KEYS */;

--
-- Table structure for table `Primer_Info`
--

DROP TABLE IF EXISTS `Primer_Info`;
CREATE TABLE `Primer_Info` (
  `Primer_Info_ID` int(11) NOT NULL auto_increment,
  `FK_Solution__ID` int(11) default NULL,
  `nMoles` float default NULL,
  `micrograms` float default NULL,
  `ODs` float default NULL,
  PRIMARY KEY  (`Primer_Info_ID`),
  KEY `FK_Solution__ID` (`FK_Solution__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Primer_Info`
--


/*!40000 ALTER TABLE `Primer_Info` DISABLE KEYS */;
LOCK TABLES `Primer_Info` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Primer_Info` ENABLE KEYS */;

--
-- Table structure for table `Primer_Order`
--

DROP TABLE IF EXISTS `Primer_Order`;
CREATE TABLE `Primer_Order` (
  `Primer_Order_ID` int(11) NOT NULL auto_increment,
  `Primer_Name` varchar(40) default NULL,
  `Order_DateTime` date default NULL,
  `Received_DateTime` date default '0000-00-00',
  `FK_Employee__ID` int(11) default NULL,
  PRIMARY KEY  (`Primer_Order_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Primer_Order`
--


/*!40000 ALTER TABLE `Primer_Order` DISABLE KEYS */;
LOCK TABLES `Primer_Order` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Primer_Order` ENABLE KEYS */;

--
-- Table structure for table `Primer_Plate`
--

DROP TABLE IF EXISTS `Primer_Plate`;
CREATE TABLE `Primer_Plate` (
  `Primer_Plate_ID` int(11) NOT NULL auto_increment,
  `Primer_Plate_Name` text,
  `Order_DateTime` datetime default NULL,
  `Arrival_DateTime` datetime default NULL,
  `Primer_Plate_Status` enum('To Order','Ordered','Received','Inactive') default NULL,
  `FK_Solution__ID` int(11) default NULL,
  `Notes` varchar(40) default NULL,
  `Notify_List` text,
  `FK_Lab_Request__ID` int(11) default NULL,
  PRIMARY KEY  (`Primer_Plate_ID`),
  KEY `primerplate_arrival` (`Arrival_DateTime`),
  KEY `primerplate_status` (`Primer_Plate_Status`),
  KEY `primerplate_name` (`Primer_Plate_Name`(40)),
  KEY `FK_Solution__ID` (`FK_Solution__ID`),
  KEY `FK_Lab_Request__ID` (`FK_Lab_Request__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Primer_Plate`
--


/*!40000 ALTER TABLE `Primer_Plate` DISABLE KEYS */;
LOCK TABLES `Primer_Plate` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Primer_Plate` ENABLE KEYS */;

--
-- Table structure for table `Primer_Plate_Well`
--

DROP TABLE IF EXISTS `Primer_Plate_Well`;
CREATE TABLE `Primer_Plate_Well` (
  `Primer_Plate_Well_ID` int(11) NOT NULL auto_increment,
  `Well` char(3) default NULL,
  `FK_Primer__Name` varchar(80) default NULL,
  `FK_Primer_Plate__ID` int(11) default NULL,
  `FKParent_Primer_Plate_Well__ID` int(11) NOT NULL default '0',
  `Primer_Plate_Well_Check` enum('Passed','Failed') default NULL,
  PRIMARY KEY  (`Primer_Plate_Well_ID`),
  KEY `primerplate_well` (`Well`),
  KEY `primerplatewell_name` (`FK_Primer__Name`),
  KEY `primerplatewell_fkplate` (`FK_Primer_Plate__ID`),
  KEY `parent` (`FKParent_Primer_Plate_Well__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Primer_Plate_Well`
--


/*!40000 ALTER TABLE `Primer_Plate_Well` DISABLE KEYS */;
LOCK TABLES `Primer_Plate_Well` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Primer_Plate_Well` ENABLE KEYS */;

--
-- Table structure for table `Printer`
--

DROP TABLE IF EXISTS `Printer`;
CREATE TABLE `Printer` (
  `Printer_ID` int(11) NOT NULL auto_increment,
  `Printer_Name` varchar(40) default '',
  `Printer_DPI` int(11) NOT NULL default '0',
  `Printer_Location` varchar(40) default NULL,
  `Printer_Type` varchar(40) NOT NULL default '',
  `Printer_Address` varchar(80) NOT NULL default '',
  `Printer_Output` enum('text','ZPL','latex','OFF') NOT NULL default 'ZPL',
  `FK_Equipment__ID` int(11) NOT NULL default '0',
  `FK_Label_Format__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Printer_ID`),
  KEY `prnname` (`Printer_Name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Printer`
--


/*!40000 ALTER TABLE `Printer` DISABLE KEYS */;
LOCK TABLES `Printer` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Printer` ENABLE KEYS */;

--
-- Table structure for table `Printer_Assignment`
--

DROP TABLE IF EXISTS `Printer_Assignment`;
CREATE TABLE `Printer_Assignment` (
  `Printer_Assignment_ID` int(11) NOT NULL auto_increment,
  `FK_Printer_Group__ID` int(11) NOT NULL default '0',
  `FK_Printer__ID` int(11) NOT NULL default '0',
  `FK_Label_Format__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Printer_Assignment_ID`),
  UNIQUE KEY `label` (`FK_Printer_Group__ID`,`FK_Label_Format__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Printer_Assignment`
--


/*!40000 ALTER TABLE `Printer_Assignment` DISABLE KEYS */;
LOCK TABLES `Printer_Assignment` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Printer_Assignment` ENABLE KEYS */;

--
-- Table structure for table `Printer_Group`
--

DROP TABLE IF EXISTS `Printer_Group`;
CREATE TABLE `Printer_Group` (
  `Printer_Group_ID` int(11) NOT NULL auto_increment,
  `Printer_Group_Name` varchar(40) NOT NULL default '',
  PRIMARY KEY  (`Printer_Group_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Printer_Group`
--


/*!40000 ALTER TABLE `Printer_Group` DISABLE KEYS */;
LOCK TABLES `Printer_Group` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Printer_Group` ENABLE KEYS */;

--
-- Table structure for table `Probe_Set`
--

DROP TABLE IF EXISTS `Probe_Set`;
CREATE TABLE `Probe_Set` (
  `Probe_Set_ID` int(11) NOT NULL auto_increment,
  `Probe_Set_Name` char(50) default NULL,
  PRIMARY KEY  (`Probe_Set_ID`),
  UNIQUE KEY `name` (`Probe_Set_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Probe_Set`
--


/*!40000 ALTER TABLE `Probe_Set` DISABLE KEYS */;
LOCK TABLES `Probe_Set` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Probe_Set` ENABLE KEYS */;

--
-- Table structure for table `Probe_Set_Value`
--

DROP TABLE IF EXISTS `Probe_Set_Value`;
CREATE TABLE `Probe_Set_Value` (
  `Probe_Set_Value_ID` int(11) NOT NULL auto_increment,
  `FK_Probe_Set__ID` int(11) NOT NULL default '0',
  `FK_GenechipExpAnalysis__ID` int(11) NOT NULL default '0',
  `Probe_Set_Type` enum('Housekeeping Control','Spike Control') default NULL,
  `Sig5` float(10,2) default NULL,
  `Det5` char(10) default NULL,
  `SigM` float(10,2) default NULL,
  `DetM` char(10) default NULL,
  `Sig3` float(10,2) default NULL,
  `Det3` char(10) default NULL,
  `SigAll` float(10,2) default NULL,
  `Sig35` float(10,2) default NULL,
  PRIMARY KEY  (`Probe_Set_Value_ID`),
  KEY `genechipanalysis` (`FK_GenechipExpAnalysis__ID`),
  KEY `probe_set` (`FK_Probe_Set__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Probe_Set_Value`
--


/*!40000 ALTER TABLE `Probe_Set_Value` DISABLE KEYS */;
LOCK TABLES `Probe_Set_Value` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Probe_Set_Value` ENABLE KEYS */;

--
-- Table structure for table `ProcedureTest_Condition`
--

DROP TABLE IF EXISTS `ProcedureTest_Condition`;
CREATE TABLE `ProcedureTest_Condition` (
  `ProcedureTest_Condition_ID` int(11) NOT NULL auto_increment,
  `FK_Ordered_Procedure__ID` int(11) NOT NULL default '0',
  `FK_Test_Condition__ID` int(11) NOT NULL default '0',
  `Test_Condition_Number` tinyint(11) NOT NULL default '0',
  PRIMARY KEY  (`ProcedureTest_Condition_ID`),
  KEY `FK_Ordered_Procedure__ID` (`FK_Ordered_Procedure__ID`),
  KEY `FK_Test_Condition__ID` (`FK_Test_Condition__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `ProcedureTest_Condition`
--


/*!40000 ALTER TABLE `ProcedureTest_Condition` DISABLE KEYS */;
LOCK TABLES `ProcedureTest_Condition` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `ProcedureTest_Condition` ENABLE KEYS */;

--
-- Table structure for table `Project`
--

DROP TABLE IF EXISTS `Project`;
CREATE TABLE `Project` (
  `Project_Name` varchar(40) NOT NULL default '',
  `Project_Description` text,
  `Project_Initiated` date NOT NULL default '0000-00-00',
  `Project_Completed` date default NULL,
  `Project_Type` enum('EST','EST+','SAGE','cDNA','PCR','PCR Product','Genomic Clone','Other','Test') default NULL,
  `Project_Path` varchar(80) default NULL,
  `Project_ID` int(11) NOT NULL auto_increment,
  `Project_Status` enum('Active','Inactive','Completed') default NULL,
  `FK_Funding__ID` int(11) default NULL,
  PRIMARY KEY  (`Project_ID`),
  UNIQUE KEY `Project_Name` (`Project_Name`),
  UNIQUE KEY `path` (`Project_Path`),
  KEY `FK_Funding__ID` (`FK_Funding__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Project`
--


/*!40000 ALTER TABLE `Project` DISABLE KEYS */;
LOCK TABLES `Project` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Project` ENABLE KEYS */;

--
-- Table structure for table `ProjectStudy`
--

DROP TABLE IF EXISTS `ProjectStudy`;
CREATE TABLE `ProjectStudy` (
  `ProjectStudy_ID` int(11) NOT NULL auto_increment,
  `FK_Project__ID` int(11) default NULL,
  `FK_Study__ID` int(11) default NULL,
  PRIMARY KEY  (`ProjectStudy_ID`),
  UNIQUE KEY `projectstudy` (`FK_Project__ID`,`FK_Study__ID`),
  KEY `project_id` (`FK_Project__ID`),
  KEY `study_id` (`FK_Study__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `ProjectStudy`
--


/*!40000 ALTER TABLE `ProjectStudy` DISABLE KEYS */;
LOCK TABLES `ProjectStudy` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `ProjectStudy` ENABLE KEYS */;

--
-- Table structure for table `Protocol_Step`
--

DROP TABLE IF EXISTS `Protocol_Step`;
CREATE TABLE `Protocol_Step` (
  `Protocol_Step_Number` int(11) default NULL,
  `Protocol_Step_Name` varchar(80) NOT NULL default '',
  `Protocol_Step_Instructions` text,
  `Protocol_Step_ID` int(11) NOT NULL auto_increment,
  `Protocol_Step_Defaults` text,
  `Input` text,
  `Scanner` tinyint(3) unsigned default '1',
  `Protocol_Step_Message` varchar(40) default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Protocol_Step_Changed` date default NULL,
  `Input_Format` text NOT NULL,
  `FK_Lab_Protocol__ID` int(11) default NULL,
  `FKQC_Attribute__ID` int(11) default NULL,
  `QC_Condition` varchar(40) default NULL,
  `Validate` enum('Primer','Enzyme','Antibiotic') default NULL,
  PRIMARY KEY  (`Protocol_Step_ID`),
  UNIQUE KEY `naming` (`Protocol_Step_Name`,`FK_Lab_Protocol__ID`),
  KEY `prot` (`FK_Lab_Protocol__ID`),
  KEY `employee_id` (`FK_Employee__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Protocol_Step`
--


/*!40000 ALTER TABLE `Protocol_Step` DISABLE KEYS */;
LOCK TABLES `Protocol_Step` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Protocol_Step` ENABLE KEYS */;

--
-- Table structure for table `Protocol_Tracking`
--

DROP TABLE IF EXISTS `Protocol_Tracking`;
CREATE TABLE `Protocol_Tracking` (
  `Protocol_Tracking_ID` int(11) NOT NULL auto_increment,
  `Protocol_Tracking_Title` char(20) default NULL,
  `Protocol_Tracking_Step_Name` char(40) default NULL,
  `Protocol_Tracking_Order` int(11) default NULL,
  `Protocol_Tracking_Type` enum('Step','Plasticware') default NULL,
  `Protocol_Tracking_Status` enum('Active','InActive') default NULL,
  `FK_Grp__ID` int(11) default NULL,
  PRIMARY KEY  (`Protocol_Tracking_ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Protocol_Tracking`
--


/*!40000 ALTER TABLE `Protocol_Tracking` DISABLE KEYS */;
LOCK TABLES `Protocol_Tracking` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Protocol_Tracking` ENABLE KEYS */;

--
-- Table structure for table `RNA_DNA_Collection`
--

DROP TABLE IF EXISTS `RNA_DNA_Collection`;
CREATE TABLE `RNA_DNA_Collection` (
  `RNA_DNA_Collection_ID` int(11) NOT NULL auto_increment,
  `FK_Library__Name` varchar(6) NOT NULL default '',
  `RNA_DNA_Source_Format` enum('RNA_DNA_Tube') NOT NULL default 'RNA_DNA_Tube',
  `Collection_Type` enum('','SAGE','LongSAGE','PCR-SAGE','PCR-LongSAGE','SAGELite-SAGE','SAGELite-LongSAGE','Solexa','Microarray') default NULL,
  PRIMARY KEY  (`RNA_DNA_Collection_ID`),
  UNIQUE KEY `FK_Library__Name` (`FK_Library__Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `RNA_DNA_Collection`
--


/*!40000 ALTER TABLE `RNA_DNA_Collection` DISABLE KEYS */;
LOCK TABLES `RNA_DNA_Collection` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `RNA_DNA_Collection` ENABLE KEYS */;

--
-- Table structure for table `RNA_DNA_Source`
--

DROP TABLE IF EXISTS `RNA_DNA_Source`;
CREATE TABLE `RNA_DNA_Source` (
  `RNA_DNA_Source_ID` int(11) NOT NULL auto_increment,
  `FK_Source__ID` int(11) NOT NULL default '0',
  `Sample_Collection_Date` date NOT NULL default '0000-00-00',
  `RNA_DNA_Isolation_Date` date NOT NULL default '0000-00-00',
  `RNA_DNA_Isolation_Method` varchar(40) default NULL,
  `Nature` enum('','Total RNA','mRNA','Tissue','Cells','RNA - DNase Treated','cDNA','1st strand cDNA','Amplified cDNA','Ditag','Concatemer - Insert','Concatemer - Cloned','DNA','labeled cRNA') default NULL,
  `Description` text,
  `Submitted_Amount` double(8,4) default NULL,
  `Submitted_Amount_Units` enum('','Cells','Embryos','Litters','Organs','mg','ug','ng','pg') default NULL,
  `Storage_Medium` enum('','RNALater','Trizol','Lysis Buffer','Ethanol','DEPC Water','Qiazol','TE 10:0.1','TE 10:1','RNAse-free Water','Water','EB Buffer') default NULL,
  `Storage_Medium_Quantity` double(8,4) default NULL,
  `storage_medium_quantity_units` enum('','ml','ul') default NULL,
  PRIMARY KEY  (`RNA_DNA_Source_ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `RNA_DNA_Source`
--


/*!40000 ALTER TABLE `RNA_DNA_Source` DISABLE KEYS */;
LOCK TABLES `RNA_DNA_Source` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `RNA_DNA_Source` ENABLE KEYS */;

--
-- Table structure for table `RNA_DNA_Source_Attribute`
--

DROP TABLE IF EXISTS `RNA_DNA_Source_Attribute`;
CREATE TABLE `RNA_DNA_Source_Attribute` (
  `RNA_DNA_Source_Attribute_ID` int(11) NOT NULL auto_increment,
  `FK_RNA_DNA_Source__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text NOT NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Set_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`RNA_DNA_Source_Attribute_ID`),
  UNIQUE KEY `RNA_source_attribute` (`FK_RNA_DNA_Source__ID`,`FK_Attribute__ID`),
  KEY `FK_RNA_Source__ID` (`FK_RNA_DNA_Source__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `RNA_DNA_Source_Attribute`
--


/*!40000 ALTER TABLE `RNA_DNA_Source_Attribute` DISABLE KEYS */;
LOCK TABLES `RNA_DNA_Source_Attribute` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `RNA_DNA_Source_Attribute` ENABLE KEYS */;

--
-- Table structure for table `Rack`
--

DROP TABLE IF EXISTS `Rack`;
CREATE TABLE `Rack` (
  `Rack_ID` int(4) NOT NULL auto_increment,
  `FK_Equipment__ID` int(11) default NULL,
  `Rack_Type` enum('Shelf','Rack','Box','Slot') NOT NULL default 'Shelf',
  `Rack_Name` varchar(80) default NULL,
  `Movable` enum('Y','N') NOT NULL default 'Y',
  `Rack_Alias` varchar(80) default NULL,
  `FKParent_Rack__ID` int(11) default NULL,
  PRIMARY KEY  (`Rack_ID`),
  UNIQUE KEY `alias` (`Rack_Alias`),
  KEY `Equipment_FK` (`FK_Equipment__ID`),
  KEY `type` (`Rack_Type`),
  KEY `name` (`Rack_Name`),
  KEY `parent_rack_id` (`FKParent_Rack__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Rack`
--


/*!40000 ALTER TABLE `Rack` DISABLE KEYS */;
LOCK TABLES `Rack` WRITE;
INSERT INTO `Rack` VALUES (1,1,'Shelf','Temporary','N','Temporary Rack',0),(2,36,'Shelf','S3','N','TBD (Room Temperature)',0),(3,36,'Shelf','S1','N','TBD (-20 degrees)',0),(4,36,'Shelf','S2','N','TBD (+4 degrees)',0),(6,36,'Shelf','S4','N','TBD (-80 degrees)',0);
UNLOCK TABLES;
/*!40000 ALTER TABLE `Rack` ENABLE KEYS */;

--
-- Table structure for table `ReArray`
--

DROP TABLE IF EXISTS `ReArray`;
CREATE TABLE `ReArray` (
  `FKSource_Plate__ID` int(11) NOT NULL default '0',
  `Source_Well` char(3) NOT NULL default '',
  `Target_Well` char(3) NOT NULL default '',
  `ReArray_ID` int(11) NOT NULL auto_increment,
  `FK_ReArray_Request__ID` int(11) NOT NULL default '0',
  `FK_Sample__ID` int(11) default '-1',
  PRIMARY KEY  (`ReArray_ID`),
  KEY `rearray_req` (`FK_ReArray_Request__ID`),
  KEY `target` (`Target_Well`),
  KEY `source` (`FKSource_Plate__ID`),
  KEY `fk_sample` (`FK_Sample__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `ReArray`
--


/*!40000 ALTER TABLE `ReArray` DISABLE KEYS */;
LOCK TABLES `ReArray` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `ReArray` ENABLE KEYS */;

--
-- Table structure for table `ReArray_Attribute`
--

DROP TABLE IF EXISTS `ReArray_Attribute`;
CREATE TABLE `ReArray_Attribute` (
  `ReArray_Attribute_ID` int(11) NOT NULL auto_increment,
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `FK_ReArray__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text,
  PRIMARY KEY  (`ReArray_Attribute_ID`),
  UNIQUE KEY `Attribute_ReArray` (`FK_Attribute__ID`,`FK_ReArray__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`),
  KEY `FK_ReArray__ID` (`FK_ReArray__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `ReArray_Attribute`
--


/*!40000 ALTER TABLE `ReArray_Attribute` DISABLE KEYS */;
LOCK TABLES `ReArray_Attribute` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `ReArray_Attribute` ENABLE KEYS */;

--
-- Table structure for table `ReArray_Plate`
--

DROP TABLE IF EXISTS `ReArray_Plate`;
CREATE TABLE `ReArray_Plate` (
  `ReArray_Plate_ID` int(11) NOT NULL auto_increment,
  `FK_Source__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`ReArray_Plate_ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `ReArray_Plate`
--


/*!40000 ALTER TABLE `ReArray_Plate` DISABLE KEYS */;
LOCK TABLES `ReArray_Plate` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `ReArray_Plate` ENABLE KEYS */;

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

--
-- Dumping data for table `ReArray_Request`
--


/*!40000 ALTER TABLE `ReArray_Request` DISABLE KEYS */;
LOCK TABLES `ReArray_Request` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `ReArray_Request` ENABLE KEYS */;

--
-- Table structure for table `Report`
--

DROP TABLE IF EXISTS `Report`;
CREATE TABLE `Report` (
  `Report_ID` int(11) NOT NULL auto_increment,
  `Parameter_String` text,
  `Target` text,
  `Extract_File` text,
  `Report_Frequency` int(11) default NULL,
  `Report_Sent` datetime default NULL,
  PRIMARY KEY  (`Report_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Report`
--


/*!40000 ALTER TABLE `Report` DISABLE KEYS */;
LOCK TABLES `Report` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Report` ENABLE KEYS */;

--
-- Table structure for table `Restriction_Site`
--

DROP TABLE IF EXISTS `Restriction_Site`;
CREATE TABLE `Restriction_Site` (
  `Restriction_Site_Name` varchar(20) NOT NULL default '',
  `Recognition_Sequence` text,
  `Restriction_Site_ID` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`Restriction_Site_ID`),
  UNIQUE KEY `Restriction_Site_Name` (`Restriction_Site_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Restriction_Site`
--


/*!40000 ALTER TABLE `Restriction_Site` DISABLE KEYS */;
LOCK TABLES `Restriction_Site` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Restriction_Site` ENABLE KEYS */;

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

--
-- Dumping data for table `Run`
--


/*!40000 ALTER TABLE `Run` DISABLE KEYS */;
LOCK TABLES `Run` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Run` ENABLE KEYS */;

--
-- Table structure for table `RunBatch`
--

DROP TABLE IF EXISTS `RunBatch`;
CREATE TABLE `RunBatch` (
  `RunBatch_ID` int(11) NOT NULL auto_increment,
  `RunBatch_RequestDateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `FK_Employee__ID` int(11) default NULL,
  `FK_Equipment__ID` int(11) default NULL,
  `RunBatch_Comments` text,
  PRIMARY KEY  (`RunBatch_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `RunBatch`
--


/*!40000 ALTER TABLE `RunBatch` DISABLE KEYS */;
LOCK TABLES `RunBatch` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `RunBatch` ENABLE KEYS */;

--
-- Table structure for table `RunBatch_Attribute`
--

DROP TABLE IF EXISTS `RunBatch_Attribute`;
CREATE TABLE `RunBatch_Attribute` (
  `FK_RunBatch__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text NOT NULL,
  `RunBatch_Attribute_ID` int(11) NOT NULL auto_increment,
  `FK_Employee__ID` int(11) default NULL,
  `Set_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`RunBatch_Attribute_ID`),
  UNIQUE KEY `runbatch_attribute` (`FK_RunBatch__ID`,`FK_Attribute__ID`),
  KEY `FK_RunBatch__ID` (`FK_RunBatch__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `RunBatch_Attribute`
--


/*!40000 ALTER TABLE `RunBatch_Attribute` DISABLE KEYS */;
LOCK TABLES `RunBatch_Attribute` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `RunBatch_Attribute` ENABLE KEYS */;

--
-- Table structure for table `RunDataAnnotation`
--

DROP TABLE IF EXISTS `RunDataAnnotation`;
CREATE TABLE `RunDataAnnotation` (
  `RunDataAnnotation_ID` int(11) NOT NULL auto_increment,
  `FK_RunDataAnnotation_Type__ID` int(11) NOT NULL default '0',
  `Value` float NOT NULL default '0',
  `FK_Employee__ID` int(11) NOT NULL default '0',
  `Date_Time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `Comments` varchar(255) default NULL,
  PRIMARY KEY  (`RunDataAnnotation_ID`),
  KEY `FK_RunDataAnnotation_Type__ID` (`FK_RunDataAnnotation_Type__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `RunDataAnnotation`
--


/*!40000 ALTER TABLE `RunDataAnnotation` DISABLE KEYS */;
LOCK TABLES `RunDataAnnotation` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `RunDataAnnotation` ENABLE KEYS */;

--
-- Table structure for table `RunDataAnnotation_Type`
--

DROP TABLE IF EXISTS `RunDataAnnotation_Type`;
CREATE TABLE `RunDataAnnotation_Type` (
  `RunDataAnnotation_Type_ID` int(11) NOT NULL auto_increment,
  `RunDataAnnotation_Type_Name` varchar(30) NOT NULL default '',
  `RunDataAnnotation_Type_Description` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`RunDataAnnotation_Type_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `RunDataAnnotation_Type`
--


/*!40000 ALTER TABLE `RunDataAnnotation_Type` DISABLE KEYS */;
LOCK TABLES `RunDataAnnotation_Type` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `RunDataAnnotation_Type` ENABLE KEYS */;

--
-- Table structure for table `RunDataReference`
--

DROP TABLE IF EXISTS `RunDataReference`;
CREATE TABLE `RunDataReference` (
  `RunDataReference_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `Well` char(3) NOT NULL default '',
  `FK_RunDataAnnotation__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`RunDataReference_ID`),
  KEY `FK_Run__ID` (`FK_Run__ID`,`FK_RunDataAnnotation__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `RunDataReference`
--


/*!40000 ALTER TABLE `RunDataReference` DISABLE KEYS */;
LOCK TABLES `RunDataReference` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `RunDataReference` ENABLE KEYS */;

--
-- Table structure for table `RunPlate`
--

DROP TABLE IF EXISTS `RunPlate`;
CREATE TABLE `RunPlate` (
  `Sequence_ID` int(11) NOT NULL default '0',
  `Plate_Number` int(4) NOT NULL default '0',
  `Parent_Quadrant` char(1) default ''
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `RunPlate`
--


/*!40000 ALTER TABLE `RunPlate` DISABLE KEYS */;
LOCK TABLES `RunPlate` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `RunPlate` ENABLE KEYS */;

--
-- Table structure for table `Run_Attribute`
--

DROP TABLE IF EXISTS `Run_Attribute`;
CREATE TABLE `Run_Attribute` (
  `Run_Attribute_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text NOT NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Set_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`Run_Attribute_ID`),
  UNIQUE KEY `run_attribute` (`FK_Attribute__ID`,`FK_Run__ID`),
  KEY `FK_Run__ID` (`FK_Run__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Run_Attribute`
--


/*!40000 ALTER TABLE `Run_Attribute` DISABLE KEYS */;
LOCK TABLES `Run_Attribute` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Run_Attribute` ENABLE KEYS */;

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

--
-- Dumping data for table `SAGE_Library`
--


/*!40000 ALTER TABLE `SAGE_Library` DISABLE KEYS */;
LOCK TABLES `SAGE_Library` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `SAGE_Library` ENABLE KEYS */;

--
-- Table structure for table `SS_Config`
--

DROP TABLE IF EXISTS `SS_Config`;
CREATE TABLE `SS_Config` (
  `SS_Config_ID` int(11) NOT NULL auto_increment,
  `FK_Sequencer_Type__ID` int(4) NOT NULL default '0',
  `SS_Title` char(80) NOT NULL default '',
  `SS_Section` int(2) NOT NULL default '0',
  `SS_Order` tinyint(4) default NULL,
  `SS_Default` char(80) NOT NULL default '',
  `SS_Alias` char(80) NOT NULL default '',
  `SS_Orientation` enum('Column','Row','N/A') default NULL,
  `SS_Type` enum('Titled','Untitled','Hidden') NOT NULL default 'Titled',
  `SS_Prompt` enum('Text','Radio','Default','No') default NULL,
  `SS_Track` char(40) NOT NULL default '',
  PRIMARY KEY  (`SS_Config_ID`),
  KEY `FK_Sequencer_Type__ID` (`FK_Sequencer_Type__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `SS_Config`
--


/*!40000 ALTER TABLE `SS_Config` DISABLE KEYS */;
LOCK TABLES `SS_Config` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `SS_Config` ENABLE KEYS */;

--
-- Table structure for table `SS_Option`
--

DROP TABLE IF EXISTS `SS_Option`;
CREATE TABLE `SS_Option` (
  `SS_Option_ID` int(11) NOT NULL auto_increment,
  `FK_Equipment__ID` int(11) default NULL,
  `SS_Option_Alias` char(80) default NULL,
  `SS_Option_Value` char(80) default NULL,
  `FK_SS_Config__ID` int(11) default NULL,
  `SS_Option_Order` tinyint(4) default NULL,
  `SS_Option_Status` enum('Active','Inactive','Default','AutoSet') NOT NULL default 'Active',
  `FKReference_SS_Option__ID` int(11) default NULL,
  PRIMARY KEY  (`SS_Option_ID`),
  KEY `FKReference_SS_Option__ID` (`FKReference_SS_Option__ID`),
  KEY `FK_Equipment__ID` (`FK_Equipment__ID`),
  KEY `FK_SS_Config__ID` (`FK_SS_Config__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `SS_Option`
--


/*!40000 ALTER TABLE `SS_Option` DISABLE KEYS */;
LOCK TABLES `SS_Option` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `SS_Option` ENABLE KEYS */;

--
-- Table structure for table `Sample`
--

DROP TABLE IF EXISTS `Sample`;
CREATE TABLE `Sample` (
  `Sample_ID` int(11) NOT NULL auto_increment,
  `Sample_Name` varchar(40) default NULL,
  `Sample_Type` enum('Clone','Extraction') default NULL,
  `Sample_Comments` text,
  `FKParent_Sample__ID` int(11) default NULL,
  `FK_Source__ID` int(11) NOT NULL default '0',
  `FKOriginal_Plate__ID` int(11) NOT NULL default '0',
  `Original_Well` char(3) default NULL,
  `FK_Library__Name` varchar(8) default NULL,
  `Plate_Number` int(11) default NULL,
  `FK_Sample_Type__ID` int(11) NOT NULL default '0',
  `Sample_Source` enum('Original','Extraction','Clone') default NULL,
  PRIMARY KEY  (`Sample_ID`),
  KEY `name` (`Sample_Name`),
  KEY `FKParent_Sample__ID` (`FKParent_Sample__ID`),
  KEY `Sample_Type` (`Sample_Type`),
  KEY `FK_Source__ID` (`FK_Source__ID`),
  KEY `lpw` (`FK_Library__Name`,`Plate_Number`,`Original_Well`),
  KEY `type` (`FK_Sample_Type__ID`),
  KEY `orig` (`FKOriginal_Plate__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Sample`
--


/*!40000 ALTER TABLE `Sample` DISABLE KEYS */;
LOCK TABLES `Sample` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Sample` ENABLE KEYS */;

--
-- Table structure for table `Sample_Alias`
--

DROP TABLE IF EXISTS `Sample_Alias`;
CREATE TABLE `Sample_Alias` (
  `Sample_Alias_ID` int(11) NOT NULL auto_increment,
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `FKSource_Organization__ID` int(11) NOT NULL default '0',
  `Alias` varchar(40) default NULL,
  `Alias_Type` varchar(40) default NULL,
  PRIMARY KEY  (`Sample_Alias_ID`),
  UNIQUE KEY `spec` (`FK_Sample__ID`,`Alias_Type`,`Alias`),
  KEY `sample` (`FK_Sample__ID`),
  KEY `alias` (`Alias`),
  KEY `type` (`Alias_Type`),
  KEY `FKSource_Organization__ID` (`FKSource_Organization__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Sample_Alias`
--


/*!40000 ALTER TABLE `Sample_Alias` DISABLE KEYS */;
LOCK TABLES `Sample_Alias` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Sample_Alias` ENABLE KEYS */;

--
-- Table structure for table `Sample_Attribute`
--

DROP TABLE IF EXISTS `Sample_Attribute`;
CREATE TABLE `Sample_Attribute` (
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text NOT NULL,
  `Sample_Attribute_ID` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`Sample_Attribute_ID`),
  UNIQUE KEY `sample_attribute` (`FK_Sample__ID`,`FK_Attribute__ID`),
  KEY `FK_Sample__ID` (`FK_Sample__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Sample_Attribute`
--


/*!40000 ALTER TABLE `Sample_Attribute` DISABLE KEYS */;
LOCK TABLES `Sample_Attribute` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Sample_Attribute` ENABLE KEYS */;

--
-- Table structure for table `Sample_Pool`
--

DROP TABLE IF EXISTS `Sample_Pool`;
CREATE TABLE `Sample_Pool` (
  `Sample_Pool_ID` int(11) NOT NULL auto_increment,
  `FK_Pool__ID` int(11) NOT NULL default '0',
  `FKTarget_Plate__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Sample_Pool_ID`),
  UNIQUE KEY `pool_id` (`FK_Pool__ID`),
  UNIQUE KEY `target_plate` (`FKTarget_Plate__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Sample_Pool`
--


/*!40000 ALTER TABLE `Sample_Pool` DISABLE KEYS */;
LOCK TABLES `Sample_Pool` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Sample_Pool` ENABLE KEYS */;

--
-- Table structure for table `Sample_Type`
--

DROP TABLE IF EXISTS `Sample_Type`;
CREATE TABLE `Sample_Type` (
  `Sample_Type_ID` int(11) NOT NULL auto_increment,
  `Sample_Type` varchar(40) default NULL,
  PRIMARY KEY  (`Sample_Type_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Sample_Type`
--


/*!40000 ALTER TABLE `Sample_Type` DISABLE KEYS */;
LOCK TABLES `Sample_Type` WRITE;
INSERT INTO `Sample_Type` VALUES (1,'Mixed'),(2,'Clone'),(3,'DNA'),(4,'RNA'),(5,'Protein'),(6,'Amplicon'),(7,'mRNA'),(8,'Tissue'),(9,'Cells'),(10,'RNA - DNase Treated'),(11,'cDNA'),(12,'1st strand cDNA'),(13,'Amplified cDNA'),(14,'Ditag'),(15,'Concatemer - Insert'),(16,'Concatemer - Cloned');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Sample_Type` ENABLE KEYS */;

--
-- Table structure for table `SequenceAnalysis`
--

DROP TABLE IF EXISTS `SequenceAnalysis`;
CREATE TABLE `SequenceAnalysis` (
  `SequenceAnalysis_ID` int(11) NOT NULL auto_increment,
  `FK_SequenceRun__ID` int(11) default NULL,
  `SequenceAnalysis_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `Phred_Version` varchar(20) NOT NULL default '',
  `Reads` int(11) default NULL,
  `Q20array` blob,
  `SLarray` blob,
  `Q20mean` int(11) default NULL,
  `Q20median` int(11) default NULL,
  `Q20max` int(11) default NULL,
  `Q20min` int(11) default NULL,
  `SLmean` int(11) default NULL,
  `SLmedian` int(11) default NULL,
  `SLmax` int(11) default NULL,
  `SLmin` int(11) default NULL,
  `QVmean` int(11) default NULL,
  `QVtotal` int(11) default NULL,
  `Wells` int(11) default NULL,
  `NGs` int(11) default NULL,
  `SGs` int(11) default NULL,
  `EWs` int(11) default NULL,
  `PWs` int(11) default NULL,
  `QLmean` int(11) default NULL,
  `QLtotal` int(11) default NULL,
  `Q20total` int(11) default NULL,
  `SLtotal` int(11) default NULL,
  `AllReads` int(11) default NULL,
  `AllBPs` int(11) default NULL,
  `VectorSegmentWarnings` int(11) default NULL,
  `ContaminationWarnings` int(11) default NULL,
  `VectorOnlyWarnings` int(11) default NULL,
  `RecurringStringWarnings` int(11) default NULL,
  `PoorQualityWarnings` int(11) default NULL,
  `PeakAreaRatioWarnings` int(11) default NULL,
  `successful_reads` int(11) default NULL,
  `trimmed_successful_reads` int(11) default NULL,
  `A_SStotal` int(11) default NULL,
  `T_SStotal` int(11) default NULL,
  `G_SStotal` int(11) default NULL,
  `C_SStotal` int(11) default NULL,
  `Vtotal` int(11) default NULL,
  `mask_restriction_site` enum('Yes','No') default 'Yes',
  PRIMARY KEY  (`SequenceAnalysis_ID`),
  UNIQUE KEY `FK_SequenceRun__ID_2` (`FK_SequenceRun__ID`),
  KEY `FK_SequenceRun__ID` (`FK_SequenceRun__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `SequenceAnalysis`
--


/*!40000 ALTER TABLE `SequenceAnalysis` DISABLE KEYS */;
LOCK TABLES `SequenceAnalysis` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `SequenceAnalysis` ENABLE KEYS */;

--
-- Table structure for table `SequenceRun`
--

DROP TABLE IF EXISTS `SequenceRun`;
CREATE TABLE `SequenceRun` (
  `SequenceRun_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) default NULL,
  `FK_Chemistry_Code__Name` varchar(5) default NULL,
  `FKPrimer_Solution__ID` int(11) default NULL,
  `FKMatrix_Solution__ID` int(11) default NULL,
  `FKBuffer_Solution__ID` int(11) default NULL,
  `DNA_Volume` float default NULL,
  `Total_Prep_Volume` smallint(6) default NULL,
  `BrewMix_Concentration` float default NULL,
  `Reaction_Volume` tinyint(4) default NULL,
  `Resuspension_Volume` tinyint(4) default NULL,
  `Slices` varchar(20) default NULL,
  `Run_Format` enum('96','384','96x4','16xN') default NULL,
  `Run_Module` varchar(128) default NULL,
  `Run_Time` int(11) default NULL,
  `Run_Voltage` int(11) default NULL,
  `Run_Temperature` int(11) default NULL,
  `Injection_Time` int(11) default NULL,
  `Injection_Voltage` int(11) default NULL,
  `Mobility_Version` enum('','1','2','3') default '',
  `PlateSealing` enum('None','Foil','Heat Sealing','Septa') default 'None',
  `Run_Direction` enum('3prime','5prime','N/A','Unknown') default 'N/A',
  PRIMARY KEY  (`SequenceRun_ID`),
  UNIQUE KEY `FK_Run__ID_2` (`FK_Run__ID`),
  KEY `FK_Run__ID` (`FK_Run__ID`),
  KEY `FKPrimer_Solution__ID` (`FKPrimer_Solution__ID`),
  KEY `FK_Chemistry_Code__Name` (`FK_Chemistry_Code__Name`),
  KEY `FKMatrix_Solution__ID` (`FKMatrix_Solution__ID`,`FKBuffer_Solution__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `SequenceRun`
--


/*!40000 ALTER TABLE `SequenceRun` DISABLE KEYS */;
LOCK TABLES `SequenceRun` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `SequenceRun` ENABLE KEYS */;

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

--
-- Dumping data for table `Sequencer_Type`
--


/*!40000 ALTER TABLE `Sequencer_Type` DISABLE KEYS */;
LOCK TABLES `Sequencer_Type` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Sequencer_Type` ENABLE KEYS */;

--
-- Table structure for table `Sequencing_Library`
--

DROP TABLE IF EXISTS `Sequencing_Library`;
CREATE TABLE `Sequencing_Library` (
  `Sequencing_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Library__Name` varchar(40) NOT NULL default '',
  `Sequencing_Library_Type` enum('SAGE','cDNA','Genomic','EST','Transposon','PCR','Test') default NULL,
  `FK_Vector__Name` varchar(40) default NULL,
  `Host` text NOT NULL,
  `Organism` varchar(40) default NULL,
  `Sex` varchar(20) default NULL,
  `Tissue` varchar(40) default NULL,
  `Strain` varchar(40) default NULL,
  `FK_Vector__ID` int(11) default NULL,
  `Colonies_Screened` int(11) default NULL,
  `Clones_NoInsert_Percent` float(5,2) default NULL,
  `AvgInsertSize` int(11) default NULL,
  `InsertSizeMin` int(11) default NULL,
  `InsertSizeMax` int(11) default NULL,
  `Source_RNA_DNA` text,
  `BlueWhiteSelection` enum('Yes','No') default NULL,
  `Sequencing_Library_Format` set('Ligation','Transformed Cells','Microtiter Plates','ReArrayed') default NULL,
  `FKVector_Organization__ID` int(11) default NULL,
  `Vector_Type` enum('Plasmid','Fosmid','Cosmid','BAC') default NULL,
  `Vector_Catalog_Number` text,
  `Antibiotic_Concentration` float default NULL,
  `FK3Prime_Restriction_Site__ID` int(11) default NULL,
  `FK5Prime_Restriction_Site__ID` int(11) default NULL,
  PRIMARY KEY  (`Sequencing_Library_ID`),
  UNIQUE KEY `FK_Library__Name` (`FK_Library__Name`),
  KEY `FKVector_Organization__ID` (`FKVector_Organization__ID`),
  KEY `FK3Prime_Restriction_Site__ID` (`FK3Prime_Restriction_Site__ID`),
  KEY `FK_Vector__Name` (`FK_Vector__Name`),
  KEY `FK_Vector__ID` (`FK_Vector__ID`),
  KEY `FK5Prime_Restriction_Site__ID` (`FK5Prime_Restriction_Site__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Sequencing_Library`
--


/*!40000 ALTER TABLE `Sequencing_Library` DISABLE KEYS */;
LOCK TABLES `Sequencing_Library` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Sequencing_Library` ENABLE KEYS */;

--
-- Table structure for table `Service`
--

DROP TABLE IF EXISTS `Service`;
CREATE TABLE `Service` (
  `FK_Equipment__ID` int(11) default NULL,
  `FK_Equipment__Type` varchar(40) default NULL,
  `Service_Interval` tinyint(4) default NULL,
  `Interval_Frequency` enum('Year','Month','Week','Day') default NULL,
  `Service_Name` text,
  `Service_ID` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`Service_ID`),
  UNIQUE KEY `service` (`FK_Equipment__ID`,`FK_Equipment__Type`),
  KEY `FK_Equipment__Type` (`FK_Equipment__Type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Service`
--


/*!40000 ALTER TABLE `Service` DISABLE KEYS */;
LOCK TABLES `Service` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Service` ENABLE KEYS */;

--
-- Table structure for table `Service_Contract`
--

DROP TABLE IF EXISTS `Service_Contract`;
CREATE TABLE `Service_Contract` (
  `Service_Contract_BeginDate` date default NULL,
  `Service_Contract_ExpiryDate` date default NULL,
  `FK_Organization__ID` int(11) default NULL,
  `FK_Equipment__ID` int(11) default NULL,
  `FK_Orders__ID` int(11) default NULL,
  `Service_Contract_Number` int(11) default NULL,
  `Service_Contract_Number_in_Batch` int(11) default NULL,
  `Service_Contract_ID` int(11) NOT NULL auto_increment,
  `Service_Contract_Status` enum('Pending','Current','Expired','Invalid') default 'Pending',
  PRIMARY KEY  (`Service_Contract_ID`),
  KEY `FK_Orders__ID` (`FK_Orders__ID`),
  KEY `FK_Organization__ID` (`FK_Organization__ID`),
  KEY `FK_Equipment__ID` (`FK_Equipment__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Service_Contract`
--


/*!40000 ALTER TABLE `Service_Contract` DISABLE KEYS */;
LOCK TABLES `Service_Contract` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Service_Contract` ENABLE KEYS */;

--
-- Table structure for table `Setting`
--

DROP TABLE IF EXISTS `Setting`;
CREATE TABLE `Setting` (
  `Setting_ID` int(11) NOT NULL auto_increment,
  `Setting_Name` varchar(40) default NULL,
  `Setting_Default` varchar(40) default NULL,
  `Setting_Description` text,
  PRIMARY KEY  (`Setting_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Setting`
--


/*!40000 ALTER TABLE `Setting` DISABLE KEYS */;
LOCK TABLES `Setting` WRITE;
INSERT INTO `Setting` VALUES (1,'LARGE_LABEL_PRINTER','auto1@urania','Printer to send large labels to'),(2,'CHEMISTRY_PRINTER','auto1@zebraps2-01.bcgsc.ca','Printer to send chemistry labels to'),(3,'SMALL_LABEL_PRINTER','auto1@saturnia','Printer to send small labels to'),(4,'2D_BARCODE_PRINTER','auto1@jetdirect01','Printer to send 2d barcode labels to'),(5,'PRINTER_GROUP','6th Floor Printers (Sequencing)','Defaults set of printers to use for this group'),(6,'BLOCK_SIZE','384','Number of wells in standard plate size (eg 96 or 384)'),(7,'LASER_PRINTER','polyhymnia','Printer to send paper labels to'),(8,'DEFAULT_LOCATION','153','Location used when the actual location is not known');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Setting` ENABLE KEYS */;

--
-- Table structure for table `SolexaAnalysis`
--

DROP TABLE IF EXISTS `SolexaAnalysis`;
CREATE TABLE `SolexaAnalysis` (
  `SolexaAnalysis_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `SolexaAnalysis_Type` enum('eland','default') default 'default',
  `Phasing` float default NULL,
  `Prephasing` float default NULL,
  `Read_Length` smallint(6) default NULL,
  `SolexaAnalysis_Started` datetime default NULL,
  `SolexaAnalysis_Finished` datetime default NULL,
  `Clusters` int(11) default NULL,
  `Error_Rate_Percentage` float default NULL,
  `Align_Percentage` float default NULL,
  `Firecrest_Dir` varchar(50) default NULL,
  `Bustard_Dir` varchar(50) default NULL,
  `Gerald_Dir` varchar(50) default NULL,
  `End_Read_Type` enum('Single','PET 1','PET 2') default NULL,
  `Tiles_Analyzed` int(11) default NULL,
  PRIMARY KEY  (`SolexaAnalysis_ID`),
  KEY `FKSolexaAnalysis_Run__ID` (`FK_Run__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `SolexaAnalysis`
--


/*!40000 ALTER TABLE `SolexaAnalysis` DISABLE KEYS */;
LOCK TABLES `SolexaAnalysis` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `SolexaAnalysis` ENABLE KEYS */;

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

--
-- Dumping data for table `SolexaRun`
--


/*!40000 ALTER TABLE `SolexaRun` DISABLE KEYS */;
LOCK TABLES `SolexaRun` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `SolexaRun` ENABLE KEYS */;

--
-- Table structure for table `Solution`
--

DROP TABLE IF EXISTS `Solution`;
CREATE TABLE `Solution` (
  `Solution_ID` int(11) NOT NULL auto_increment,
  `Solution_Started` datetime default NULL,
  `Solution_Quantity` float default NULL,
  `Solution_Expiry` date default NULL,
  `Quantity_Used` float default '0',
  `FK_Rack__ID` int(11) default NULL,
  `Solution_Finished` date default NULL,
  `Solution_Type` enum('Reagent','Solution','Primer','Buffer','Matrix') default NULL,
  `Solution_Status` enum('Unopened','Open','Finished','Temporary','Expired') default 'Unopened',
  `Solution_Cost` float default NULL,
  `FK_Stock__ID` int(11) default NULL,
  `FK_Solution_Info__ID` int(11) default NULL,
  `Solution_Number` int(11) default NULL,
  `Solution_Number_in_Batch` int(11) default NULL,
  `Solution_Notes` text,
  `QC_Status` enum('N/A','Pending','Failed','Re-Test','Passed') default 'N/A',
  PRIMARY KEY  (`Solution_ID`),
  KEY `stock` (`FK_Stock__ID`),
  KEY `FK_Solution_Info__ID` (`FK_Solution_Info__ID`),
  KEY `FK_Rack__ID` (`FK_Rack__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Solution`
--


/*!40000 ALTER TABLE `Solution` DISABLE KEYS */;
LOCK TABLES `Solution` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Solution` ENABLE KEYS */;

--
-- Table structure for table `Solution_Info`
--

DROP TABLE IF EXISTS `Solution_Info`;
CREATE TABLE `Solution_Info` (
  `Solution_Info_ID` int(11) NOT NULL auto_increment,
  `nMoles` float default NULL,
  `ODs` float default NULL,
  `micrograms` float default NULL,
  PRIMARY KEY  (`Solution_Info_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Solution_Info`
--


/*!40000 ALTER TABLE `Solution_Info` DISABLE KEYS */;
LOCK TABLES `Solution_Info` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Solution_Info` ENABLE KEYS */;

--
-- Table structure for table `Sorted_Cell`
--

DROP TABLE IF EXISTS `Sorted_Cell`;
CREATE TABLE `Sorted_Cell` (
  `Sorted_Cell_ID` int(11) NOT NULL auto_increment,
  `FK_Source__ID` int(11) NOT NULL default '0',
  `FKSortedBy_Contact__ID` int(11) NOT NULL default '0',
  `Sorted_Cell_Type` enum('CD19+_Kappa+ B-Cells','CD19+_Lambda Light Chain+ B-Cells','CD19+ B-Cells') default NULL,
  `Sorted_Cell_Condition` enum('Fresh','Frozen') default NULL,
  PRIMARY KEY  (`Sorted_Cell_ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`,`FKSortedBy_Contact__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Sorted_Cell`
--


/*!40000 ALTER TABLE `Sorted_Cell` DISABLE KEYS */;
LOCK TABLES `Sorted_Cell` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Sorted_Cell` ENABLE KEYS */;

--
-- Table structure for table `Source`
--

DROP TABLE IF EXISTS `Source`;
CREATE TABLE `Source` (
  `Source_ID` int(11) NOT NULL auto_increment,
  `FKParent_Source__ID` int(11) default NULL,
  `External_Identifier` varchar(40) NOT NULL default '',
  `Source_Type` enum('Library_Segment','RNA_DNA_Source','ReArray_Plate','Ligation','Microtiter','Xformed_Cells','Sorted_Cell','Tissue_Sample','External','Cells') default NULL,
  `Source_Status` enum('Active','Reserved','Inactive','Thrown Out') default NULL,
  `Label` varchar(40) default NULL,
  `FK_Original_Source__ID` int(11) default NULL,
  `Received_Date` date NOT NULL default '0000-00-00',
  `Current_Amount` float default NULL,
  `Original_Amount` float default NULL,
  `Amount_Units` enum('','ul','ml','ul/well','mg','ug','ng','pg','Cells','Embryos','Litters','Organs','Animals','Million Cells') default NULL,
  `FKReceived_Employee__ID` int(11) default NULL,
  `FK_Rack__ID` int(11) NOT NULL default '0',
  `Source_Number` varchar(40) default NULL,
  `FK_Barcode_Label__ID` int(11) NOT NULL default '0',
  `Notes` text,
  `FKSource_Plate__ID` int(11) default NULL,
  `FK_Plate_Format__ID` int(11) default NULL,
  PRIMARY KEY  (`Source_ID`),
  KEY `FK_Original_Source__ID` (`FK_Original_Source__ID`),
  KEY `FK_Rack__ID` (`FK_Rack__ID`),
  KEY `FKReceived_Employee__ID` (`FKReceived_Employee__ID`),
  KEY `FK_Barcode_Label__ID` (`FK_Barcode_Label__ID`),
  KEY `FKParent_Source__ID` (`FKParent_Source__ID`),
  KEY `label` (`Label`),
  KEY `number` (`Source_Type`,`Source_Number`),
  KEY `id` (`External_Identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Source`
--


/*!40000 ALTER TABLE `Source` DISABLE KEYS */;
LOCK TABLES `Source` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Source` ENABLE KEYS */;

--
-- Table structure for table `Source_Attribute`
--

DROP TABLE IF EXISTS `Source_Attribute`;
CREATE TABLE `Source_Attribute` (
  `Source_Attribute_ID` int(11) NOT NULL auto_increment,
  `FK_Source__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text NOT NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Set_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`Source_Attribute_ID`),
  UNIQUE KEY `source_attribute` (`FK_Source__ID`,`FK_Attribute__ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Source_Attribute`
--


/*!40000 ALTER TABLE `Source_Attribute` DISABLE KEYS */;
LOCK TABLES `Source_Attribute` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Source_Attribute` ENABLE KEYS */;

--
-- Table structure for table `Source_Pool`
--

DROP TABLE IF EXISTS `Source_Pool`;
CREATE TABLE `Source_Pool` (
  `Source_Pool_ID` int(11) NOT NULL auto_increment,
  `FKParent_Source__ID` int(11) default NULL,
  `FKChild_Source__ID` int(11) default NULL,
  PRIMARY KEY  (`Source_Pool_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Source_Pool`
--


/*!40000 ALTER TABLE `Source_Pool` DISABLE KEYS */;
LOCK TABLES `Source_Pool` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Source_Pool` ENABLE KEYS */;

--
-- Table structure for table `SpectAnalysis`
--

DROP TABLE IF EXISTS `SpectAnalysis`;
CREATE TABLE `SpectAnalysis` (
  `SpectAnalysis_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `A260_Blank_Avg` float(4,3) default NULL,
  `A280_Blank_Avg` float(4,3) default NULL,
  PRIMARY KEY  (`SpectAnalysis_ID`),
  KEY `FK_Run__ID` (`FK_Run__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `SpectAnalysis`
--


/*!40000 ALTER TABLE `SpectAnalysis` DISABLE KEYS */;
LOCK TABLES `SpectAnalysis` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `SpectAnalysis` ENABLE KEYS */;

--
-- Table structure for table `SpectRead`
--

DROP TABLE IF EXISTS `SpectRead`;
CREATE TABLE `SpectRead` (
  `SpectRead_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `Well` char(3) default NULL,
  `Well_Status` enum('OK','Empty','Unused','Problematic','Ignored') default NULL,
  `Well_Category` enum('Sample','Blank','ssDNA','hgDNA') default NULL,
  `A260m` float(4,3) default NULL,
  `A260cor` float(4,3) default NULL,
  `A280m` float(4,3) default NULL,
  `A280cor` float(4,3) default NULL,
  `A260` float(4,3) default NULL,
  `A280` float(4,3) default NULL,
  `A260_A280_ratio` float(4,3) default NULL,
  `Dilution_Factor` float(4,3) default NULL,
  `Concentration` float default NULL,
  `Unit` varchar(15) default NULL,
  `Read_Error` enum('low concentration','low A260cor/A280cor ratio','A260m below 0.100','SS DNA concentration out of range','human gDNA concentration out of range') default NULL,
  `Read_Warning` enum('low A260cor/A280cor ratio','SS DNA concentration out of range','human gDNA concentration out of range') default NULL,
  PRIMARY KEY  (`SpectRead_ID`),
  KEY `FK_Run__ID` (`FK_Run__ID`),
  KEY `FK_Sample__ID` (`FK_Sample__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `SpectRead`
--


/*!40000 ALTER TABLE `SpectRead` DISABLE KEYS */;
LOCK TABLES `SpectRead` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `SpectRead` ENABLE KEYS */;

--
-- Table structure for table `SpectRun`
--

DROP TABLE IF EXISTS `SpectRun`;
CREATE TABLE `SpectRun` (
  `SpectRun_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `FKScanner_Equipment__ID` int(11) default NULL,
  PRIMARY KEY  (`SpectRun_ID`),
  KEY `FK_Run__ID` (`FK_Run__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `SpectRun`
--


/*!40000 ALTER TABLE `SpectRun` DISABLE KEYS */;
LOCK TABLES `SpectRun` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `SpectRun` ENABLE KEYS */;

--
-- Table structure for table `Stage`
--

DROP TABLE IF EXISTS `Stage`;
CREATE TABLE `Stage` (
  `Stage_ID` int(11) NOT NULL auto_increment,
  `Stage_Name` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`Stage_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Stage`
--


/*!40000 ALTER TABLE `Stage` DISABLE KEYS */;
LOCK TABLES `Stage` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Stage` ENABLE KEYS */;

--
-- Table structure for table `Standard_Solution`
--

DROP TABLE IF EXISTS `Standard_Solution`;
CREATE TABLE `Standard_Solution` (
  `Standard_Solution_ID` int(11) NOT NULL auto_increment,
  `Standard_Solution_Name` varchar(40) default NULL,
  `Standard_Solution_Parameters` int(11) default NULL,
  `Standard_Solution_Formula` text,
  `Standard_Solution_Status` enum('Active','Inactive','Development') default NULL,
  `Standard_Solution_Message` text,
  `Reagent_Parameter` varchar(40) default NULL,
  `Label_Type` enum('Laser','ZPL') default 'ZPL',
  `FK_Barcode_Label__ID` int(11) NOT NULL default '0',
  `Prompt_Units` enum('','pl','ul','ml','l') default '',
  PRIMARY KEY  (`Standard_Solution_ID`),
  UNIQUE KEY `name` (`Standard_Solution_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Standard_Solution`
--


/*!40000 ALTER TABLE `Standard_Solution` DISABLE KEYS */;
LOCK TABLES `Standard_Solution` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Standard_Solution` ENABLE KEYS */;

--
-- Table structure for table `Status`
--

DROP TABLE IF EXISTS `Status`;
CREATE TABLE `Status` (
  `Status_ID` int(11) NOT NULL auto_increment,
  `Status_Type` enum('ReArray_Request','Maintenance','GelAnalysis') default NULL,
  `Status_Name` char(40) default NULL,
  PRIMARY KEY  (`Status_ID`),
  KEY `status` (`Status_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Status`
--


/*!40000 ALTER TABLE `Status` DISABLE KEYS */;
LOCK TABLES `Status` WRITE;
INSERT INTO `Status` VALUES (1,'ReArray_Request','Waiting for Primers'),(2,'ReArray_Request','Waiting for Preps');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Status` ENABLE KEYS */;

--
-- Table structure for table `Stock`
--

DROP TABLE IF EXISTS `Stock`;
CREATE TABLE `Stock` (
  `Stock_ID` int(11) NOT NULL auto_increment,
  `Stock_Name` varchar(80) default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Stock_Lot_Number` varchar(80) default NULL,
  `Stock_Received` date default NULL,
  `Stock_Size` float default NULL,
  `Stock_Size_Units` enum('mL','uL','litres','mg','grams','kg','pcs','boxes','tubes','rxns','n/a') default NULL,
  `Stock_Description` text,
  `FK_Orders__ID` int(11) default NULL,
  `Stock_Type` enum('Solution','Reagent','Kit','Box','Microarray','Equipment','Service_Contract','Computer_Equip','Misc_Item') default NULL,
  `FK_Box__ID` int(11) default NULL,
  `Stock_Catalog_Number` varchar(80) default NULL,
  `Stock_Number_in_Batch` int(11) default NULL,
  `Stock_Cost` float default NULL,
  `FK_Organization__ID` int(11) default NULL,
  `Stock_Source` enum('Box','Order','Sample','Made in House') default NULL,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FK_Barcode_Label__ID` int(11) default NULL,
  `Identifier_Number` varchar(80) default NULL,
  `Identifier_Number_Type` enum('Component Number','Reference ID') default NULL,
  `Purchase_Order` varchar(20) default NULL,
  `FK_Stock_Catalog__ID` int(11) NOT NULL default '0',
  `Stock_Notes` text,
  PRIMARY KEY  (`Stock_ID`),
  KEY `cat` (`Stock_Catalog_Number`),
  KEY `name` (`Stock_Name`),
  KEY `box` (`FK_Box__ID`),
  KEY `FK_Orders__ID` (`FK_Orders__ID`),
  KEY `FK_Barcode_Label__ID` (`FK_Barcode_Label__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Organization__ID` (`FK_Organization__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `grp_id` (`FK_Grp__ID`),
  KEY `employee_id` (`FK_Employee__ID`),
  KEY `barcode_label` (`FK_Barcode_Label__ID`),
  KEY `catnum` (`Stock_Catalog_Number`),
  KEY `stockname` (`Stock_Name`),
  KEY `lot` (`Stock_Lot_Number`),
  KEY `identifier` (`Identifier_Number_Type`),
  KEY `indentifier_number` (`Identifier_Number`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Stock`
--


/*!40000 ALTER TABLE `Stock` DISABLE KEYS */;
LOCK TABLES `Stock` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Stock` ENABLE KEYS */;

--
-- Table structure for table `Stock_Catalog`
--

DROP TABLE IF EXISTS `Stock_Catalog`;
CREATE TABLE `Stock_Catalog` (
  `Stock_Catalog_ID` int(11) NOT NULL auto_increment,
  `Stock_Catalog_Name` varchar(80) NOT NULL default '',
  `Stock_Catalog_Description` text,
  `Stock_Catalog_Number` varchar(80) default NULL,
  `Stock_Type` enum('Solution','Reagent','Kit','Box','Microarray','Equipment','Service_Contract','Computer_Equip','Misc_Item','Matrix','Primer','Buffer') default NULL,
  `Stock_Source` enum('Box','Order','Sample','Made in House') default NULL,
  `Stock_Size` float default NULL,
  `Stock_Size_Units` enum('mL','uL','litres','mg','grams','kg','pcs','boxes','tubes','rxns','n/a') default NULL,
  `FK_Organization__ID` int(11) default NULL,
  `FK_Barcode_Label__ID` int(11) default NULL,
  PRIMARY KEY  (`Stock_Catalog_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Stock_Catalog`
--


/*!40000 ALTER TABLE `Stock_Catalog` DISABLE KEYS */;
LOCK TABLES `Stock_Catalog` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Stock_Catalog` ENABLE KEYS */;

--
-- Table structure for table `Study`
--

DROP TABLE IF EXISTS `Study`;
CREATE TABLE `Study` (
  `Study_ID` int(11) NOT NULL auto_increment,
  `Study_Name` varchar(40) NOT NULL default '',
  `Study_Description` text,
  `Study_Initiated` date default NULL,
  PRIMARY KEY  (`Study_ID`),
  UNIQUE KEY `study_name` (`Study_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Study`
--


/*!40000 ALTER TABLE `Study` DISABLE KEYS */;
LOCK TABLES `Study` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Study` ENABLE KEYS */;

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

--
-- Dumping data for table `Submission`
--


/*!40000 ALTER TABLE `Submission` DISABLE KEYS */;
LOCK TABLES `Submission` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Submission` ENABLE KEYS */;

--
-- Table structure for table `SubmissionVolume`
--

DROP TABLE IF EXISTS `SubmissionVolume`;
CREATE TABLE `SubmissionVolume` (
  `SubmissionVolume_ID` int(11) NOT NULL auto_increment,
  `Volume_Name` varchar(40) default NULL,
  `FKContact_Employee__ID` int(11) NOT NULL default '0',
  `Submission_Status` enum('Sent','In Process','Pending','Accepted','Rejected') default NULL,
  `Submission_DateTime` date default NULL,
  `Volume_Description` text,
  PRIMARY KEY  (`SubmissionVolume_ID`),
  KEY `FKContact_Employee__ID` (`FKContact_Employee__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `SubmissionVolume`
--


/*!40000 ALTER TABLE `SubmissionVolume` DISABLE KEYS */;
LOCK TABLES `SubmissionVolume` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `SubmissionVolume` ENABLE KEYS */;

--
-- Table structure for table `Submission_Alias`
--

DROP TABLE IF EXISTS `Submission_Alias`;
CREATE TABLE `Submission_Alias` (
  `Submission_Alias_ID` int(11) NOT NULL auto_increment,
  `FK_Trace_Submission__ID` int(11) NOT NULL default '0',
  `Submission_Reference` char(40) default NULL,
  `Submission_Reference_Type` enum('Genbank_ID','Accession_ID') default NULL,
  PRIMARY KEY  (`Submission_Alias_ID`),
  UNIQUE KEY `ref` (`Submission_Reference_Type`,`Submission_Reference`),
  KEY `FK_Trace_Submission__ID` (`FK_Trace_Submission__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Submission_Alias`
--


/*!40000 ALTER TABLE `Submission_Alias` DISABLE KEYS */;
LOCK TABLES `Submission_Alias` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Submission_Alias` ENABLE KEYS */;

--
-- Table structure for table `Submission_Detail`
--

DROP TABLE IF EXISTS `Submission_Detail`;
CREATE TABLE `Submission_Detail` (
  `Submission_Detail_ID` int(11) NOT NULL auto_increment,
  `FK_Submission__ID` int(11) NOT NULL default '0',
  `FKSubmission_DBTable__ID` int(11) NOT NULL default '0',
  `Reference` varchar(40) NOT NULL default '',
  PRIMARY KEY  (`Submission_Detail_ID`),
  KEY `FKSubmission_DBTable__ID` (`FKSubmission_DBTable__ID`),
  KEY `FK_Submission__ID` (`FK_Submission__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Submission_Detail`
--


/*!40000 ALTER TABLE `Submission_Detail` DISABLE KEYS */;
LOCK TABLES `Submission_Detail` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Submission_Detail` ENABLE KEYS */;

--
-- Table structure for table `Submission_Info`
--

DROP TABLE IF EXISTS `Submission_Info`;
CREATE TABLE `Submission_Info` (
  `Submission_Info_ID` int(11) NOT NULL auto_increment,
  `FK_Submission__ID` int(11) NOT NULL default '0',
  `Submission_Comments` text,
  `FK_Grp__ID` int(11) default NULL,
  PRIMARY KEY  (`Submission_Info_ID`),
  KEY `FK_Submission__ID` (`FK_Submission__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Submission_Info`
--


/*!40000 ALTER TABLE `Submission_Info` DISABLE KEYS */;
LOCK TABLES `Submission_Info` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Submission_Info` ENABLE KEYS */;

--
-- Table structure for table `Submission_Table_Link`
--

DROP TABLE IF EXISTS `Submission_Table_Link`;
CREATE TABLE `Submission_Table_Link` (
  `Submission_Table_Link_ID` int(11) NOT NULL auto_increment,
  `FK_Submission__ID` int(11) NOT NULL default '0',
  `Table_Name` char(40) NOT NULL default '',
  `Key_Value` char(40) default '',
  PRIMARY KEY  (`Submission_Table_Link_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Submission_Table_Link`
--


/*!40000 ALTER TABLE `Submission_Table_Link` DISABLE KEYS */;
LOCK TABLES `Submission_Table_Link` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Submission_Table_Link` ENABLE KEYS */;

--
-- Table structure for table `Submission_Volume`
--

DROP TABLE IF EXISTS `Submission_Volume`;
CREATE TABLE `Submission_Volume` (
  `Submission_Volume_ID` int(11) NOT NULL auto_increment,
  `Submission_Target` text,
  `Volume_Name` varchar(40) NOT NULL default '',
  `Submission_Date` date default NULL,
  `FKSubmitter_Employee__ID` int(11) default NULL,
  `Volume_Status` enum('In Process','Bundled','Submitted','Accepted','Rejected') default NULL,
  `Volume_Comments` text,
  `Records` int(11) NOT NULL default '0',
  `Approved_Date` date default NULL,
  `SID` varchar(40) default NULL,
  PRIMARY KEY  (`Submission_Volume_ID`),
  UNIQUE KEY `name` (`Volume_Name`),
  KEY `FKSubmitter_Employee__ID` (`FKSubmitter_Employee__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Submission_Volume`
--


/*!40000 ALTER TABLE `Submission_Volume` DISABLE KEYS */;
LOCK TABLES `Submission_Volume` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Submission_Volume` ENABLE KEYS */;

--
-- Table structure for table `Subscriber`
--

DROP TABLE IF EXISTS `Subscriber`;
CREATE TABLE `Subscriber` (
  `Subscriber_ID` int(11) NOT NULL auto_increment,
  `FK_Subscription__ID` int(11) NOT NULL default '0',
  `Subscriber_Type` enum('Employee','Grp','Contact','ExternalEmail') NOT NULL default 'Employee',
  `FK_Employee__ID` int(11) default NULL,
  `FK_Grp__ID` int(11) default NULL,
  `FK_Contact__ID` int(11) default NULL,
  `External_Email` varchar(255) default NULL,
  PRIMARY KEY  (`Subscriber_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Subscriber`
--


/*!40000 ALTER TABLE `Subscriber` DISABLE KEYS */;
LOCK TABLES `Subscriber` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Subscriber` ENABLE KEYS */;

--
-- Table structure for table `Subscription`
--

DROP TABLE IF EXISTS `Subscription`;
CREATE TABLE `Subscription` (
  `Subscription_ID` int(11) NOT NULL auto_increment,
  `FK_Subscription_Event__ID` int(11) NOT NULL default '0',
  `FK_Equipment__ID` int(11) default NULL,
  `FK_Library__Name` varchar(255) default NULL,
  `FK_Project__ID` int(11) default NULL,
  `FK_Grp__ID` int(11) default NULL,
  `Subscription_Name` varchar(255) default NULL,
  PRIMARY KEY  (`Subscription_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Subscription`
--


/*!40000 ALTER TABLE `Subscription` DISABLE KEYS */;
LOCK TABLES `Subscription` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Subscription` ENABLE KEYS */;

--
-- Table structure for table `Subscription_Event`
--

DROP TABLE IF EXISTS `Subscription_Event`;
CREATE TABLE `Subscription_Event` (
  `Subscription_Event_ID` int(11) NOT NULL auto_increment,
  `Subscription_Event_Name` varchar(50) NOT NULL default '',
  `Subscription_Event_Type` varchar(50) NOT NULL default '',
  `Subscription_Event_Details` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`Subscription_Event_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Subscription_Event`
--


/*!40000 ALTER TABLE `Subscription_Event` DISABLE KEYS */;
LOCK TABLES `Subscription_Event` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Subscription_Event` ENABLE KEYS */;

--
-- Table structure for table `Suggestion`
--

DROP TABLE IF EXISTS `Suggestion`;
CREATE TABLE `Suggestion` (
  `Suggestion_ID` int(11) NOT NULL auto_increment,
  `Suggestion_Text` text,
  `Suggestion_Date` date default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Response_Text` text,
  `Implementation_Date` date default NULL,
  `Priority` enum('Urgent','Useful','Wish') NOT NULL default 'Urgent',
  PRIMARY KEY  (`Suggestion_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Suggestion`
--


/*!40000 ALTER TABLE `Suggestion` DISABLE KEYS */;
LOCK TABLES `Suggestion` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Suggestion` ENABLE KEYS */;

--
-- Table structure for table `Table_Type`
--

DROP TABLE IF EXISTS `Table_Type`;
CREATE TABLE `Table_Type` (
  `Table_Type_ID` int(11) NOT NULL auto_increment,
  `Table_Scope` enum('Core','Plugin','Custom') default NULL,
  `Table_Type` enum('Object','Detail','Data','Join','Subclass','Lookup') default NULL,
  `FK_DBTable__ID` int(11) NOT NULL default '0',
  `Table_Type_Comment` text,
  PRIMARY KEY  (`Table_Type_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Table_Type`
--


/*!40000 ALTER TABLE `Table_Type` DISABLE KEYS */;
LOCK TABLES `Table_Type` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Table_Type` ENABLE KEYS */;

--
-- Table structure for table `Taxonomy`
--

DROP TABLE IF EXISTS `Taxonomy`;
CREATE TABLE `Taxonomy` (
  `Taxonomy_ID` int(11) NOT NULL default '0',
  `Taxonomy_Name` varchar(80) NOT NULL default '',
  `Common_Name` varchar(80) NOT NULL default '',
  PRIMARY KEY  (`Taxonomy_ID`),
  KEY `Tax_Name` (`Taxonomy_Name`),
  KEY `Common_Name` (`Common_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Taxonomy`
--


/*!40000 ALTER TABLE `Taxonomy` DISABLE KEYS */;
LOCK TABLES `Taxonomy` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Taxonomy` ENABLE KEYS */;

--
-- Table structure for table `Taxonomy_Division`
--

DROP TABLE IF EXISTS `Taxonomy_Division`;
CREATE TABLE `Taxonomy_Division` (
  `Taxonomy_Division_ID` int(11) NOT NULL default '0',
  `Taxonomy_Division_Code` char(3) NOT NULL default '',
  `Taxonomy_Division_Name` varchar(80) default NULL,
  `Taxonomy_Division_Comments` text,
  PRIMARY KEY  (`Taxonomy_Division_ID`),
  KEY `Tax_Code` (`Taxonomy_Division_Code`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Taxonomy_Division`
--


/*!40000 ALTER TABLE `Taxonomy_Division` DISABLE KEYS */;
LOCK TABLES `Taxonomy_Division` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Taxonomy_Division` ENABLE KEYS */;

--
-- Table structure for table `Taxonomy_Name`
--

DROP TABLE IF EXISTS `Taxonomy_Name`;
CREATE TABLE `Taxonomy_Name` (
  `FK_Taxonomy__ID` int(11) NOT NULL default '0',
  `NCBI_Taxonomy_Name` varchar(80) NOT NULL default '',
  `Unique_Taxonomy_Name` varchar(80) default NULL,
  `Taxonomy_Name_Class` varchar(80) default NULL,
  KEY `Tax_Name` (`NCBI_Taxonomy_Name`),
  KEY `Unique_Tax_Name` (`Unique_Taxonomy_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Taxonomy_Name`
--


/*!40000 ALTER TABLE `Taxonomy_Name` DISABLE KEYS */;
LOCK TABLES `Taxonomy_Name` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Taxonomy_Name` ENABLE KEYS */;

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

--
-- Dumping data for table `Taxonomy_Node`
--


/*!40000 ALTER TABLE `Taxonomy_Node` DISABLE KEYS */;
LOCK TABLES `Taxonomy_Node` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Taxonomy_Node` ENABLE KEYS */;

--
-- Table structure for table `Template`
--

DROP TABLE IF EXISTS `Template`;
CREATE TABLE `Template` (
  `Template_ID` int(11) NOT NULL auto_increment,
  `Template_Name` varchar(34) NOT NULL default '',
  `Template_Type` enum('Submission','Master') NOT NULL default 'Submission',
  `Template_Description` text,
  PRIMARY KEY  (`Template_ID`),
  UNIQUE KEY `Template_Name` (`Template_Name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Template`
--


/*!40000 ALTER TABLE `Template` DISABLE KEYS */;
LOCK TABLES `Template` WRITE;
INSERT INTO `Template` VALUES (1,'Microarray_Submission_OS_S_L','Submission',NULL);
UNLOCK TABLES;
/*!40000 ALTER TABLE `Template` ENABLE KEYS */;

--
-- Table structure for table `Template_Assignment`
--

DROP TABLE IF EXISTS `Template_Assignment`;
CREATE TABLE `Template_Assignment` (
  `Template_Assignment_ID` int(11) NOT NULL auto_increment,
  `FK_Template__ID` int(11) NOT NULL default '0',
  `FK_Grp__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Template_Assignment_ID`),
  KEY `FK_Template__ID` (`FK_Template__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Template_Assignment`
--


/*!40000 ALTER TABLE `Template_Assignment` DISABLE KEYS */;
LOCK TABLES `Template_Assignment` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Template_Assignment` ENABLE KEYS */;

--
-- Table structure for table `Template_Field`
--

DROP TABLE IF EXISTS `Template_Field`;
CREATE TABLE `Template_Field` (
  `Template_Field_ID` int(11) NOT NULL auto_increment,
  `Template_Field_Name` varchar(80) NOT NULL default '',
  `FK_DBField__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Template_Field_Option` set('Mandatory','Unique') default NULL,
  `Template_Field_Format` varchar(80) default NULL,
  `FK_Template__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Template_Field_ID`),
  KEY `FK_DBField__ID` (`FK_DBField__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`),
  KEY `FK_Template__ID` (`FK_Template__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Template_Field`
--


/*!40000 ALTER TABLE `Template_Field` DISABLE KEYS */;
LOCK TABLES `Template_Field` WRITE;
INSERT INTO `Template_Field` VALUES (1,'Original_Source_Name',2281,0,'Mandatory',NULL,1),(2,'External_Identifier',2358,0,'Mandatory',NULL,1),(3,'Label',2361,0,NULL,NULL,1),(4,'Sex',2283,0,NULL,NULL,1),(5,'Family_ID',0,0,NULL,NULL,1),(6,'Family_Status',0,0,NULL,NULL,1),(7,'Nature',3401,0,NULL,NULL,1),(8,'Tissue_Type',2597,0,NULL,NULL,1),(9,'Organism',2598,0,NULL,NULL,1),(10,'Notes',2371,0,NULL,NULL,1),(11,'Storage_Medium',3405,0,NULL,NULL,1),(12,'Storage_Medium_Quantity',3406,0,NULL,NULL,1),(13,'Storage_Medium_Quantity_Units',3407,0,NULL,NULL,1),(14,'Sample_Collection_Date',3398,0,NULL,NULL,1),(15,'Nucleic_Acid_Isolation_Date',3399,0,NULL,NULL,1),(16,'Nucleic_Acid_Isolation_Method',3400,0,NULL,NULL,1),(17,'Nucleic_Acid_Isolation_Performed_By',0,0,NULL,NULL,1),(18,'Concentration',0,0,NULL,NULL,1),(19,'Concentration_Units',0,0,NULL,NULL,1),(20,'Blood_Sampling_Date',0,0,NULL,NULL,1),(21,'Blood_Sampling_Location',0,0,NULL,NULL,1),(22,'Blood_Collected_By',0,0,NULL,NULL,1),(23,'Library_Name',1060,0,'Mandatory',NULL,1),(24,'Obtained_Date',1075,0,NULL,NULL,1),(25,'Library_Full_Name',1061,0,'Mandatory',NULL,1),(26,'Library_Type',1069,0,'Mandatory',NULL,1),(27,'Source_Type',2359,0,'Mandatory',NULL,1),(28,'FK_Grp__ID',1835,0,'Mandatory',NULL,1),(29,'Date_Received',2363,0,NULL,NULL,1),(30,'FK_Project__ID',1059,0,'Mandatory',NULL,1),(31,'Contact_ID',2288,0,'Mandatory',NULL,1),(32,'Original_Source_Name',2281,0,'Mandatory',NULL,1),(33,'External_Identifier',2358,0,'Mandatory',NULL,1),(34,'Label',2361,0,NULL,NULL,1),(35,'Sex',2283,0,NULL,NULL,1),(36,'Family_ID',0,0,NULL,NULL,1),(37,'Family_Status',0,0,NULL,NULL,1),(38,'Nature',3401,0,NULL,NULL,1),(39,'Tissue_Type',2597,0,NULL,NULL,1),(40,'Organism',2598,0,NULL,NULL,1),(41,'Notes',2371,0,NULL,NULL,1),(42,'Storage_Medium',3405,0,NULL,NULL,1),(43,'Storage_Medium_Quantity',3406,0,NULL,NULL,1),(44,'Storage_Medium_Quantity_Units',3407,0,NULL,NULL,1),(45,'Sample_Collection_Date',3398,0,NULL,NULL,1),(46,'Nucleic_Acid_Isolation_Date',3399,0,NULL,NULL,1),(47,'Nucleic_Acid_Isolation_Method',3400,0,NULL,NULL,1),(48,'Nucleic_Acid_Isolation_Performed_By',0,0,NULL,NULL,1),(49,'Concentration',0,0,NULL,NULL,1),(50,'Concentration_Units',0,0,NULL,NULL,1),(51,'Blood_Sampling_Date',0,0,NULL,NULL,1),(52,'Blood_Sampling_Location',0,0,NULL,NULL,1),(53,'Blood_Collected_By',0,0,NULL,NULL,1),(54,'Library_Name',1060,0,'Mandatory',NULL,1),(55,'Obtained_Date',1075,0,NULL,NULL,1),(56,'Library_Full_Name',1061,0,'Mandatory',NULL,1),(57,'Library_Type',1069,0,'Mandatory',NULL,1),(58,'Source_Type',2359,0,'Mandatory',NULL,1),(59,'FK_Grp__ID',1835,0,'Mandatory',NULL,1),(60,'Date_Received',2363,0,NULL,NULL,1),(61,'FK_Project__ID',1059,0,'Mandatory',NULL,1),(62,'Contact_ID',2288,0,'Mandatory',NULL,1);
UNLOCK TABLES;
/*!40000 ALTER TABLE `Template_Field` ENABLE KEYS */;

--
-- Table structure for table `Test_Condition`
--

DROP TABLE IF EXISTS `Test_Condition`;
CREATE TABLE `Test_Condition` (
  `Test_Condition_ID` int(11) NOT NULL auto_increment,
  `Condition_Name` varchar(40) default NULL,
  `Condition_Tables` text,
  `Condition_Field` text,
  `Condition_String` text,
  `Condition_Type` enum('Ready','In Process','Completed','Transferred within Protocol','Ready For Next Protocol','Custom') default 'Custom',
  `Procedure_Link` varchar(80) default NULL,
  `Condition_Description` text,
  `Condition_Key` varchar(40) default NULL,
  `Extra_Clause` text,
  PRIMARY KEY  (`Test_Condition_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Test_Condition`
--


/*!40000 ALTER TABLE `Test_Condition` DISABLE KEYS */;
LOCK TABLES `Test_Condition` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Test_Condition` ENABLE KEYS */;

--
-- Table structure for table `Tissue`
--

DROP TABLE IF EXISTS `Tissue`;
CREATE TABLE `Tissue` (
  `Tissue_ID` int(11) NOT NULL auto_increment,
  `Tissue_Name` varchar(255) NOT NULL default '',
  `Tissue_Subtype` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`Tissue_ID`),
  UNIQUE KEY `tissue` (`Tissue_Name`,`Tissue_Subtype`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Tissue`
--


/*!40000 ALTER TABLE `Tissue` DISABLE KEYS */;
LOCK TABLES `Tissue` WRITE;
INSERT INTO `Tissue` VALUES (176,'',''),(73,'Abomasum','');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Tissue` ENABLE KEYS */;

--
-- Table structure for table `Tissue_Source`
--

DROP TABLE IF EXISTS `Tissue_Source`;
CREATE TABLE `Tissue_Source` (
  `Tissue_Source_ID` int(11) NOT NULL auto_increment,
  `FK_Source__ID` int(11) default NULL,
  `Tissue_Source_Type` varchar(40) default NULL,
  `Tissue_Source_Condition` enum('Fresh','Frozen') default NULL,
  PRIMARY KEY  (`Tissue_Source_ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Tissue_Source`
--


/*!40000 ALTER TABLE `Tissue_Source` DISABLE KEYS */;
LOCK TABLES `Tissue_Source` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Tissue_Source` ENABLE KEYS */;

--
-- Table structure for table `TraceData`
--

DROP TABLE IF EXISTS `TraceData`;
CREATE TABLE `TraceData` (
  `FK_Run__ID` int(11) default NULL,
  `TraceData_ID` int(11) NOT NULL auto_increment,
  `Mirrored` int(11) default '0',
  `Archived` int(11) default '0',
  `Checked` datetime default NULL,
  `Machine` varchar(20) default NULL,
  `Links` int(11) default NULL,
  `Files` int(11) default NULL,
  `Broken` int(11) default NULL,
  `Path` enum('','Not Found','OK') default '',
  `Zipped` int(11) default NULL,
  `Format` varchar(20) default NULL,
  `MirroredSize` int(11) default NULL,
  `ArchivedSize` int(11) default NULL,
  `ZippedSize` int(11) default NULL,
  PRIMARY KEY  (`TraceData_ID`),
  UNIQUE KEY `run` (`FK_Run__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `TraceData`
--


/*!40000 ALTER TABLE `TraceData` DISABLE KEYS */;
LOCK TABLES `TraceData` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `TraceData` ENABLE KEYS */;

--
-- Table structure for table `Trace_Submission`
--

DROP TABLE IF EXISTS `Trace_Submission`;
CREATE TABLE `Trace_Submission` (
  `Trace_Submission_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) default NULL,
  `Well` char(4) NOT NULL default '',
  `Submission_Status` enum('Bundled','In Process','Accepted','Rejected') default NULL,
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `Submitted_Length` int(11) NOT NULL default '0',
  `FK_Submission_Volume__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Trace_Submission_ID`),
  UNIQUE KEY `sequence_read` (`FK_Run__ID`,`Well`,`FK_Submission_Volume__ID`),
  KEY `length` (`Submitted_Length`),
  KEY `FK_Sample__ID` (`FK_Sample__ID`),
  KEY `FK_Submission_Volume__ID` (`FK_Submission_Volume__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Trace_Submission`
--


/*!40000 ALTER TABLE `Trace_Submission` DISABLE KEYS */;
LOCK TABLES `Trace_Submission` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Trace_Submission` ENABLE KEYS */;

--
-- Table structure for table `Transposon`
--

DROP TABLE IF EXISTS `Transposon`;
CREATE TABLE `Transposon` (
  `Transposon_Name` varchar(80) NOT NULL default '',
  `FK_Organization__ID` int(11) default NULL,
  `Transposon_Description` text,
  `Transposon_Sequence` text,
  `Transposon_Source_ID` text,
  `Antibiotic_Marker` enum('Kanamycin','Chloramphenicol','Tetracycline') default NULL,
  `Transposon_ID` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`Transposon_ID`),
  KEY `FK_Organization__ID` (`FK_Organization__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Transposon`
--


/*!40000 ALTER TABLE `Transposon` DISABLE KEYS */;
LOCK TABLES `Transposon` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Transposon` ENABLE KEYS */;

--
-- Table structure for table `Transposon_Library`
--

DROP TABLE IF EXISTS `Transposon_Library`;
CREATE TABLE `Transposon_Library` (
  `Transposon_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Sequencing_Library__ID` int(11) NOT NULL default '0',
  `FK_Transposon__ID` int(11) NOT NULL default '0',
  `FK_Pool__ID` int(11) NOT NULL default '0',
  `Blue_White_Selection` enum('Yes','No') NOT NULL default 'No',
  PRIMARY KEY  (`Transposon_Library_ID`),
  KEY `lib_id` (`FK_Sequencing_Library__ID`),
  KEY `transposon_id` (`FK_Transposon__ID`),
  KEY `pool_id` (`FK_Pool__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Transposon_Library`
--


/*!40000 ALTER TABLE `Transposon_Library` DISABLE KEYS */;
LOCK TABLES `Transposon_Library` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Transposon_Library` ENABLE KEYS */;

--
-- Table structure for table `Transposon_Pool`
--

DROP TABLE IF EXISTS `Transposon_Pool`;
CREATE TABLE `Transposon_Pool` (
  `Transposon_Pool_ID` int(11) NOT NULL auto_increment,
  `FK_Transposon__ID` int(11) NOT NULL default '0',
  `FK_Optical_Density__ID` int(11) default NULL,
  `FK_GelRun__ID` int(11) default NULL,
  `Reads_Required` int(11) default NULL,
  `Pipeline` enum('Standard','Gateway','PCR/Gateway (pGATE)') default NULL,
  `Test_Status` enum('Test','Production') NOT NULL default 'Production',
  `Status` enum('Data Pending','Dilutions','Ready For Pooling','In Progress','Complete','Failed-Redo') default NULL,
  `FK_Source__ID` int(11) default NULL,
  `FK_Pool__ID` int(11) default NULL,
  PRIMARY KEY  (`Transposon_Pool_ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`),
  KEY `FK_Pool__ID` (`FK_Pool__ID`),
  KEY `FK_Gel__ID` (`FK_GelRun__ID`),
  KEY `FK_Optical_Density__ID` (`FK_Optical_Density__ID`),
  KEY `FK_Transposon__ID` (`FK_Transposon__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Transposon_Pool`
--


/*!40000 ALTER TABLE `Transposon_Pool` DISABLE KEYS */;
LOCK TABLES `Transposon_Pool` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Transposon_Pool` ENABLE KEYS */;

--
-- Table structure for table `Tray`
--

DROP TABLE IF EXISTS `Tray`;
CREATE TABLE `Tray` (
  `Tray_ID` int(11) NOT NULL auto_increment,
  `Tray_Label` varchar(10) default '',
  PRIMARY KEY  (`Tray_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='For multiple objects on a tray';

--
-- Dumping data for table `Tray`
--


/*!40000 ALTER TABLE `Tray` DISABLE KEYS */;
LOCK TABLES `Tray` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Tray` ENABLE KEYS */;

--
-- Table structure for table `Trigger`
--

DROP TABLE IF EXISTS `Trigger`;
CREATE TABLE `Trigger` (
  `Trigger_ID` int(11) NOT NULL auto_increment,
  `Table_Name` varchar(40) NOT NULL default '',
  `Trigger_Type` enum('SQL','Perl','Form','Method','Shell') default NULL,
  `Value` text,
  `Trigger_On` enum('update','insert','delete') default NULL,
  `Status` enum('Active','Inactive') NOT NULL default 'Active',
  `Trigger_Description` text,
  `Fatal` enum('Yes','No') default 'Yes',
  PRIMARY KEY  (`Trigger_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Trigger`
--


/*!40000 ALTER TABLE `Trigger` DISABLE KEYS */;
LOCK TABLES `Trigger` WRITE;
INSERT INTO `Trigger` VALUES (1,'Source','Method','new_source_trigger','insert','Active','','Yes'),(2,'WorkLog','Perl','require alDente::Issue; my $ok = &alDente::Issue::update_Issue_from_WorkLog(-dbh=>$dbh, -id=><ID>);','insert','Active','','Yes'),(3,'Plate','Perl','require alDente::Container;my $po = new alDente::Container(-dbc=>$self,-id=><ID>,-quick_load=>1);$po->new_container_trigger();return 1; ','insert','Active','','Yes'),(4,'Issue','Perl','require alDente::Issue; my $ok = &alDente::Issue::update_Issue_trigger(-dbh=>$dbh, -id=><ID>);','insert','Active','Initialize fields (Latest_ETA) for new Issue record','Yes'),(5,'Library','Method','new_library_trigger','insert','Active','Insert an external source/library_source if library is supplied by collaborator/another dept','Yes'),(6,'Plate_Prep','Method','plate_prep_insert_trigger','insert','Active','Update branch for plate if applicable reagent has been applied','No');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Trigger` ENABLE KEYS */;

--
-- Table structure for table `Tube`
--

DROP TABLE IF EXISTS `Tube`;
CREATE TABLE `Tube` (
  `Tube_ID` int(11) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) default NULL,
  `Tube_Quantity` float default NULL,
  `Tube_Quantity_Units` enum('ml','ul','mg','ug','ng','pg') default NULL,
  `Quantity_Used` float default NULL,
  `Quantity_Used_Units` enum('ml','ul','mg','ug','ng','pg') default NULL,
  `Original_Concentration` float default NULL,
  `Original_Concentration_Units` enum('cfu','ng/ul','ug/ul','nM','pM') default NULL,
  PRIMARY KEY  (`Tube_ID`),
  KEY `plate_id` (`FK_Plate__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Tube`
--


/*!40000 ALTER TABLE `Tube` DISABLE KEYS */;
LOCK TABLES `Tube` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Tube` ENABLE KEYS */;

--
-- Table structure for table `Tube_Application`
--

DROP TABLE IF EXISTS `Tube_Application`;
CREATE TABLE `Tube_Application` (
  `Tube_Application_ID` int(11) NOT NULL auto_increment,
  `FK_Solution__ID` int(11) default NULL,
  `FK_Tube__ID` int(11) default NULL,
  `Comments` text,
  PRIMARY KEY  (`Tube_Application_ID`),
  KEY `FK_Solution__ID` (`FK_Solution__ID`),
  KEY `FK_Tube__ID` (`FK_Tube__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Tube_Application`
--


/*!40000 ALTER TABLE `Tube_Application` DISABLE KEYS */;
LOCK TABLES `Tube_Application` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Tube_Application` ENABLE KEYS */;

--
-- Table structure for table `UseCase`
--

DROP TABLE IF EXISTS `UseCase`;
CREATE TABLE `UseCase` (
  `UseCase_ID` int(11) NOT NULL auto_increment,
  `UseCase_Name` varchar(80) NOT NULL default '',
  `FK_Employee__ID` int(11) default NULL,
  `UseCase_Description` text,
  `UseCase_Created` datetime default '0000-00-00 00:00:00',
  `UseCase_Modified` datetime default '0000-00-00 00:00:00',
  `FKParent_UseCase__ID` int(11) default NULL,
  `FK_UseCase_Step__ID` int(11) default NULL,
  PRIMARY KEY  (`UseCase_ID`),
  UNIQUE KEY `usecase_name` (`UseCase_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `UseCase`
--


/*!40000 ALTER TABLE `UseCase` DISABLE KEYS */;
LOCK TABLES `UseCase` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `UseCase` ENABLE KEYS */;

--
-- Table structure for table `UseCase_Step`
--

DROP TABLE IF EXISTS `UseCase_Step`;
CREATE TABLE `UseCase_Step` (
  `UseCase_Step_ID` int(11) NOT NULL auto_increment,
  `UseCase_Step_Title` text,
  `UseCase_Step_Description` text,
  `UseCase_Step_Comments` text,
  `FK_UseCase__ID` int(11) default NULL,
  `FKParent_UseCase_Step__ID` int(11) default NULL,
  `UseCase_Step_Branch` enum('0','1') default '0',
  PRIMARY KEY  (`UseCase_Step_ID`),
  KEY `usecase_id` (`FK_UseCase__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `UseCase_Step`
--


/*!40000 ALTER TABLE `UseCase_Step` DISABLE KEYS */;
LOCK TABLES `UseCase_Step` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `UseCase_Step` ENABLE KEYS */;

--
-- Table structure for table `Vector`
--

DROP TABLE IF EXISTS `Vector`;
CREATE TABLE `Vector` (
  `Vector_Name` varchar(40) NOT NULL default '',
  `Vector_Manufacturer` text,
  `Vector_Catalog_Number` text,
  `Vector_Sequence_File` text NOT NULL,
  `Vector_Sequence_Source` text,
  `Antibiotic_Marker` enum('Ampicillin','Zeocin','Kanamycin','Chloramphenicol','Tetracycline','N/A') default NULL,
  `Vector_ID` int(11) NOT NULL auto_increment,
  `Inducer` varchar(40) default NULL,
  `Substrate` varchar(40) default NULL,
  `FKManufacturer_Organization__ID` int(11) default NULL,
  `FKSource_Organization__ID` int(11) default NULL,
  `Vector_Sequence` longtext,
  `FK_Vector_Type__ID` int(11) NOT NULL default '0',
  `Vector_Type` enum('Plasmid','Fosmid','Cosmid','BAC','N/A') default NULL,
  PRIMARY KEY  (`Vector_ID`),
  KEY `FKSource_Organization__ID` (`FKSource_Organization__ID`),
  KEY `FKManufacturer_Organization__ID` (`FKManufacturer_Organization__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Vector`
--


/*!40000 ALTER TABLE `Vector` DISABLE KEYS */;
LOCK TABLES `Vector` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Vector` ENABLE KEYS */;

--
-- Table structure for table `VectorPrimer`
--

DROP TABLE IF EXISTS `VectorPrimer`;
CREATE TABLE `VectorPrimer` (
  `FK_Vector__Name` varchar(80) default NULL,
  `FK_Primer__Name` varchar(40) default NULL,
  `Direction` enum('3''','5''','N/A','3prime','5prime') default NULL,
  `VectorPrimer_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_Vector__ID` int(11) NOT NULL default '0',
  `FK_Primer__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`VectorPrimer_ID`),
  UNIQUE KEY `combo` (`FK_Vector__Name`,`FK_Primer__Name`),
  KEY `direction` (`FK_Vector__Name`,`FK_Primer__Name`),
  KEY `FK_Primer__Name` (`FK_Primer__Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `VectorPrimer`
--


/*!40000 ALTER TABLE `VectorPrimer` DISABLE KEYS */;
LOCK TABLES `VectorPrimer` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `VectorPrimer` ENABLE KEYS */;

--
-- Table structure for table `Vector_Type`
--

DROP TABLE IF EXISTS `Vector_Type`;
CREATE TABLE `Vector_Type` (
  `Vector_Type_ID` int(11) NOT NULL auto_increment,
  `Vector_Type_Name` varchar(40) NOT NULL default '',
  `Vector_Sequence_File` text NOT NULL,
  `Vector_Sequence` longtext,
  PRIMARY KEY  (`Vector_Type_ID`),
  UNIQUE KEY `Vector_Type_Name` (`Vector_Type_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Vector_Type`
--


/*!40000 ALTER TABLE `Vector_Type` DISABLE KEYS */;
LOCK TABLES `Vector_Type` WRITE;
INSERT INTO `Vector_Type` VALUES (1,'Uni_Zap_XR','Uni_Zap_XR.seq','CACCTGACGCGCCCTGTAGCGGCGCATTAAGCGCGGCGGGTGTGGTGGTTACGCGCAGCGTGACCGCTACACTTGCCAGCGCCCTAGCGCCCGCTCCTTTCGCTTTCTTCCCTTCCTTTCTCGCCACGTTCGCCGGCTTTCCCCGTCAAGCTCTAAATCGGGGGCTCCCTTTAGGGTTCCGATTTAGTGCTTTACGGCACCTCGACCCCAAAAAACTTGATTAGGGTGATGGTTCACGTAGTGGGCCATCGCCCTGATAGACGGTTTTTCGCCCTTTGACGTTGGAGTCCACGTTCTTTAATAGTGGACTCTTGTTCCAAACTGGAACAACACTCAACCCTATCTCGGTCTATTCTTTTGATTTATAAGGGATTTTGCCGATTTCGGCCTATTGGTTAAAAAATGAGCTGATTTAACAAAAATTTAACGCGAATTTTAACAAAATATTAACGCTTACAATTTCCATTCGCCATTCAGGCTGCGCAACTGTTGGGAAGGGCGATCGGTGCGGGCCTCTTCGCTATTACGCCAGCTGGCGAAAGGGGGATGTGCTGCAAGGCGATTAAGTTGGGTAACGCCAGGGTTTTCCCAGTCACGACGTTGTAAAACGACGGCCAGTGAATTGTAATACGACTCACTATAGGGCGAATTGGGTACCGGGCCCCCCCTCGAGGTCGACGGTATCGATAAGCTTGATATCGAATTCCTGCAGCCCGGGGGATCCACTAGTTCTAGAGCGGCCGCCACCGCGGTGGAGCTCCAGCTTTTGTTCCCTTTAGTGAGGGTTAATTTCGAGCTTGGCGTAATCATGGTCATAGCTGTTTCCTGTGTGAAATTGTTATCCGCTCACAATTCCACACAACATACGAGCCGGAAGCATAAAGTGTAAAGCCTGGGGTGCCTAATGAGTGAGCTAACTCACATTAATTGCGTTGCGCTCACTGCCCGCTTTCCAGTCGGGAAACCTGTCGTGCCAGCTGCATTAATGAATCGGCCAACGCGCGGGGAGAGGCGGTTTGCGTATTGGGCGCTCTTCCGCTTCCTCGCTCACTGACTCGCTGCGCTCGGTCGTTCGGCTGCGGCGAGCGGTATCAGCTCACTCAAAGGCGGTAATACGGTTATCCACAGAATCAGGGGATAACGCAGGAAAGAACATGTGAGCAAAAGGCCAGCAAAAGGCCAGGAACCGTAAAAAGGCCGCGTTGCTGGCGTTTTTCCATAGGCTCCGCCCCCCTGACGAGCATCACAAAAATCGACGCTCAAGTCAGAGGTGGCGAAACCCGACAGGACTATAAAGATACCAGGCGTTTCCCCCTGGAAGCTCCCTCGTGCGCTCTCCTGTTCCGACCCTGCCGCTTACCGGATACCTGTCCGCCTTTCTCCCTTCGGGAAGCGTGGCGCTTTCTCATAGCTCACGCTGTAGGTATCTCAGTTCGGTGTAGGTCGTTCGCTCCAAGCTGGGCTGTGTGCACGAACCCCCCGTTCAGCCCGACCGCTGCGCCTTATCCGGTAACTATCGTCTTGAGTCCAACCCGGTAAGACACGACTTATCGCCACTGGCAGCAGCCACTGGTAACAGGATTAGCAGAGCGAGGTATGTAGGCGGTGCTACAGAGTTCTTGAAGTGGTGGCCTAACTACGGCTACACTAGAAGGACAGTATTTGGTATCTGCGCTCTGCTGAAGCCAGTTACCTTCGGAAAAAGAGTTGGTAGCTCTTGATCCGGCAAACAAACCACCGCTGGTAGCGGTGGTTTTTTTGTTTGCAAGCAGCAGATTACGCGCAGAAAAAAAGGATCTCAAGAAGATCCTTTGATCTTTTCTACGGGGTCTGACGCTCAGTGGAACGAAAACTCACGTTAAGGGATTTTGGTCATGAGATTATCAAAAAGGATCTTCACCTAGATCCTTTTAAATTAAAAATGAAGTTTTAAATCAATCTAAAGTATATATGAGTAAACTTGGTCTGACAGTTACCAATGCTTAATCAGTGAGGCACCTATCTCAGCGATCTGTCTATTTCGTTCATCCATAGTTGCCTGACTCCCCGTCGTGTAGATAACTACGATACGGGAGGGCTTACCATCTGGCCCCAGTGCTGCAATGATACCGCGAGACCCACGCTCACCGGCTCCAGATTTATCAGCAATAAACCAGCCAGCCGGAAGGGCCGAGCGCAGAAGTGGTCCTGCAACTTTATCCGCCTCCATCCAGTCTATTAATTGTTGCCGGGAAGCTAGAGTAAGTAGTTCGCCAGTTAATAGTTTGCGCAACGTTGTTGCCATTGCTACAGGCATCGTGGTGTCACGCTCGTCGTTTGGTATGGCTTCATTCAGCTCCGGTTCCCAACGATCAAGGCGAGTTACATGATCCCCCATGTTGTGCAAAAAAGCGGTTAGCTCCTTCGGTCCTCCGATCGTTGTCAGAAGTAAGTTGGCCGCAGTGTTATCACTCATGGTTATGGCAGCACTGCATAATTCTCTTACTGTCATGCCATCCGTAAGATGCTTTTCTGTGACTGGTGAGTACTCAACCAAGTCATTCTGAGAATAGTGTATGCGGCGACCGAGTTGCTCTTGCCCGGCGTCAATACGGGATAATACCGCGCCACATAGCAGAACTTTAAAAGTGCTCATCATTGGAAAACGTTCTTCGGGGCGAAAACTCTCAAGGATCTTACCGCTGTTGAGATCCAGTTCGATGTAACCCACTCGTGCACCCAACTGATCTTCAGCATCTTTTACTTTCACCAGCGTTTCTGGGTGAGCAAAAACAGGAAGGCAAAATGCCGCAAAAAAGGGAATAAGGGCGACACGGAAATGTTGAATACTCATACTCTTCCTTTTTCAATATTATTGAAGCATTTATCAGGGTTATTGTCTCATGAGCGGATACATATTTGAATGTATTTAGAAAAATAAACAAATAGGGGTTCCGCGCACATTTCCCCGAAAAGTGC');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Vector_Type` ENABLE KEYS */;

--
-- Table structure for table `Vector_TypeAntibiotic`
--

DROP TABLE IF EXISTS `Vector_TypeAntibiotic`;
CREATE TABLE `Vector_TypeAntibiotic` (
  `Vector_TypeAntibiotic_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_Vector_Type__ID` int(11) NOT NULL default '0',
  `FK_Antibiotic__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Vector_TypeAntibiotic_ID`),
  UNIQUE KEY `combo` (`FK_Vector_Type__ID`,`FK_Antibiotic__ID`),
  KEY `FK_Vector_Type__ID` (`FK_Vector_Type__ID`),
  KEY `FK_Antibiotic__ID` (`FK_Antibiotic__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Vector_TypeAntibiotic`
--


/*!40000 ALTER TABLE `Vector_TypeAntibiotic` DISABLE KEYS */;
LOCK TABLES `Vector_TypeAntibiotic` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Vector_TypeAntibiotic` ENABLE KEYS */;

--
-- Table structure for table `Vector_TypePrimer`
--

DROP TABLE IF EXISTS `Vector_TypePrimer`;
CREATE TABLE `Vector_TypePrimer` (
  `Vector_TypePrimer_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_Vector_Type__ID` int(11) NOT NULL default '0',
  `FK_Primer__ID` int(11) NOT NULL default '0',
  `Direction` enum('N/A','3prime','5prime') default NULL,
  PRIMARY KEY  (`Vector_TypePrimer_ID`),
  UNIQUE KEY `combo` (`FK_Vector_Type__ID`,`FK_Primer__ID`),
  KEY `FK_Vector_Type__ID` (`FK_Vector_Type__ID`),
  KEY `FK_Primer__ID` (`FK_Primer__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Vector_TypePrimer`
--


/*!40000 ALTER TABLE `Vector_TypePrimer` DISABLE KEYS */;
LOCK TABLES `Vector_TypePrimer` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Vector_TypePrimer` ENABLE KEYS */;

--
-- Table structure for table `Version`
--

DROP TABLE IF EXISTS `Version`;
CREATE TABLE `Version` (
  `Version_ID` int(11) NOT NULL auto_increment,
  `Version_Name` varchar(8) default NULL,
  `Version_Description` text,
  `Release_Date` date default NULL,
  `Last_Modified_Date` date default NULL,
  PRIMARY KEY  (`Version_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Version`
--


/*!40000 ALTER TABLE `Version` DISABLE KEYS */;
LOCK TABLES `Version` WRITE;
INSERT INTO `Version` VALUES (1,'1.30','alDente - Revise primary navigation interface','2003-08-25','2003-10-15'),(2,'2.00','alDente - Enable multiple Departments (Gene Expression), Separate Clone,Plate,Library objects','2004-01-24','2004-02-20'),(3,'2.1','alDente - Increased functionality for Gene Expression','2004-06-09','2004-06-09'),(4,'2.2',NULL,'2004-11-29','2004-11-29'),(5,'2.3',NULL,'2005-07-20','2005-07-20'),(6,'2.4','QA upgrades, mgc closure needs, normalizing Organism/Tissue info, sample submission automation','2006-01-27','2006-01-27'),(7,'2.41','Mapping and Affy support + items deferred from 2.4','2006-04-14','0000-00-00'),(8,'2.5','','2007-03-15','0000-00-00'),(9,'3','','0000-00-00','0000-00-00'),(10,'2.6','','2008-08-25','2008-08-25');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Version` ENABLE KEYS */;

--
-- Table structure for table `View`
--

DROP TABLE IF EXISTS `View`;
CREATE TABLE `View` (
  `View_ID` int(10) unsigned NOT NULL auto_increment,
  `View_Name` varchar(40) default NULL,
  `View_Description` text,
  `View_Tables` text,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`View_ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `View`
--


/*!40000 ALTER TABLE `View` DISABLE KEYS */;
LOCK TABLES `View` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `View` ENABLE KEYS */;

--
-- Table structure for table `ViewInput`
--

DROP TABLE IF EXISTS `ViewInput`;
CREATE TABLE `ViewInput` (
  `ViewInput_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_View__ID` int(11) NOT NULL default '0',
  `Input_Field` varchar(80) default '',
  PRIMARY KEY  (`ViewInput_ID`),
  KEY `FK_View__ID` (`FK_View__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `ViewInput`
--


/*!40000 ALTER TABLE `ViewInput` DISABLE KEYS */;
LOCK TABLES `ViewInput` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `ViewInput` ENABLE KEYS */;

--
-- Table structure for table `ViewJoin`
--

DROP TABLE IF EXISTS `ViewJoin`;
CREATE TABLE `ViewJoin` (
  `ViewJoin_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_View__ID` int(11) NOT NULL default '0',
  `Join_Condition` text,
  `Join_Type` enum('LEFT','INNER') default 'INNER',
  PRIMARY KEY  (`ViewJoin_ID`),
  KEY `FK_View__ID` (`FK_View__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `ViewJoin`
--


/*!40000 ALTER TABLE `ViewJoin` DISABLE KEYS */;
LOCK TABLES `ViewJoin` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `ViewJoin` ENABLE KEYS */;

--
-- Table structure for table `ViewOutput`
--

DROP TABLE IF EXISTS `ViewOutput`;
CREATE TABLE `ViewOutput` (
  `ViewOutput_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_View__ID` int(11) NOT NULL default '0',
  `Output_Field` varchar(80) default '',
  PRIMARY KEY  (`ViewOutput_ID`),
  KEY `FK_View__ID` (`FK_View__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `ViewOutput`
--


/*!40000 ALTER TABLE `ViewOutput` DISABLE KEYS */;
LOCK TABLES `ViewOutput` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `ViewOutput` ENABLE KEYS */;

--
-- Table structure for table `Warranty`
--

DROP TABLE IF EXISTS `Warranty`;
CREATE TABLE `Warranty` (
  `Warranty_BeginDate` date default NULL,
  `Warranty_ExpiryDate` date default NULL,
  `FK_Organization__ID` int(11) default NULL,
  `FK_Equipment__ID` int(11) default NULL,
  `Warranty_Conditions` text,
  `Warranty_ID` int(11) NOT NULL auto_increment,
  `time` datetime default NULL,
  PRIMARY KEY  (`Warranty_ID`),
  KEY `FK_Organization__ID` (`FK_Organization__ID`),
  KEY `FK_Equipment__ID` (`FK_Equipment__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Warranty`
--


/*!40000 ALTER TABLE `Warranty` DISABLE KEYS */;
LOCK TABLES `Warranty` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Warranty` ENABLE KEYS */;

--
-- Table structure for table `Well_Lookup`
--

DROP TABLE IF EXISTS `Well_Lookup`;
CREATE TABLE `Well_Lookup` (
  `Plate_384` char(3) NOT NULL default '',
  `Plate_96` char(3) NOT NULL default '',
  `Quadrant` char(1) NOT NULL default '',
  `Gel_121_Standard` int(11) default NULL,
  `Gel_121_Custom` int(11) default NULL,
  `Tube` char(3) default NULL,
  UNIQUE KEY `P384` (`Plate_384`),
  UNIQUE KEY `P96W` (`Plate_96`,`Quadrant`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Well_Lookup`
--


/*!40000 ALTER TABLE `Well_Lookup` DISABLE KEYS */;
LOCK TABLES `Well_Lookup` WRITE;
INSERT INTO `Well_Lookup` VALUES ('a1','A01','a',1,1,'A01'),('a10','A05','b',21,41,'A01'),('a11','A06','a',26,42,'A01'),('a12','A06','b',26,42,'A01'),('a13','A07','a',31,43,'A01'),('a14','A07','b',31,43,'A01'),('a15','A08','a',36,44,'A01'),('a16','A08','b',36,44,'A01'),('a17','A09','a',41,81,'A01'),('a18','A09','b',41,81,'A01'),('a19','A10','a',46,82,'A01'),('a2','A01','b',1,1,'A01'),('a20','A10','b',46,82,'A01'),('a21','A11','a',51,83,'A01'),('a22','A11','b',51,83,'A01'),('a23','A12','a',56,84,'A01'),('a24','A12','b',56,84,'A01'),('a3','A02','a',6,2,'A01'),('a4','A02','b',6,2,'A01'),('a5','A03','a',11,3,'A01'),('a6','A03','b',11,3,'A01'),('a7','A04','a',16,4,'A01'),('a8','A04','b',16,4,'A01'),('a9','A05','a',21,41,'A01'),('b1','A01','c',1,1,'A01'),('b10','A05','d',21,41,'A01'),('b11','A06','c',26,42,'A01'),('b12','A06','d',26,42,'A01'),('b13','A07','c',31,43,'A01'),('b14','A07','d',31,43,'A01'),('b15','A08','c',36,44,'A01'),('b16','A08','d',36,44,'A01'),('b17','A09','c',41,81,'A01'),('b18','A09','d',41,81,'A01'),('b19','A10','c',46,82,'A01'),('b2','A01','d',1,1,'A01'),('b20','A10','d',46,82,'A01'),('b21','A11','c',51,83,'A01'),('b22','A11','d',51,83,'A01'),('b23','A12','c',56,84,'A01'),('b24','A12','d',56,84,'A01'),('b3','A02','c',6,2,'A01'),('b4','A02','d',6,2,'A01'),('b5','A03','c',11,3,'A01'),('b6','A03','d',11,3,'A01'),('b7','A04','c',16,4,'A01'),('b8','A04','d',16,4,'A01'),('b9','A05','c',21,41,'A01'),('c1','B01','a',2,6,'A01'),('c10','B05','b',22,46,'A01'),('c11','B06','a',27,47,'A01'),('c12','B06','b',27,47,'A01'),('c13','B07','a',32,48,'A01'),('c14','B07','b',32,48,'A01'),('c15','B08','a',37,49,'A01'),('c16','B08','b',37,49,'A01'),('c17','B09','a',42,86,'A01'),('c18','B09','b',42,86,'A01'),('c19','B10','a',47,87,'A01'),('c2','B01','b',2,6,'A01'),('c20','B10','b',47,87,'A01'),('c21','B11','a',52,88,'A01'),('c22','B11','b',52,88,'A01'),('c23','B12','a',57,89,'A01'),('c24','B12','b',57,89,'A01'),('c3','B02','a',7,7,'A01'),('c4','B02','b',7,7,'A01'),('c5','B03','a',12,8,'A01'),('c6','B03','b',12,8,'A01'),('c7','B04','a',17,9,'A01'),('c8','B04','b',17,9,'A01'),('c9','B05','a',22,46,'A01'),('d1','B01','c',2,6,'A01'),('d10','B05','d',22,46,'A01'),('d11','B06','c',27,47,'A01'),('d12','B06','d',27,47,'A01'),('d13','B07','c',32,48,'A01'),('d14','B07','d',32,48,'A01'),('d15','B08','c',37,49,'A01'),('d16','B08','d',37,49,'A01'),('d17','B09','c',42,86,'A01'),('d18','B09','d',42,86,'A01'),('d19','B10','c',47,87,'A01'),('d2','B01','d',2,6,'A01'),('d20','B10','d',47,87,'A01'),('d21','B11','c',52,88,'A01'),('d22','B11','d',52,88,'A01'),('d23','B12','c',57,89,'A01'),('d24','B12','d',57,89,'A01'),('d3','B02','c',7,7,'A01'),('d4','B02','d',7,7,'A01'),('d5','B03','c',12,8,'A01'),('d6','B03','d',12,8,'A01'),('d7','B04','c',17,9,'A01'),('d8','B04','d',17,9,'A01'),('d9','B05','c',22,46,'A01'),('e1','C01','a',3,11,'A01'),('e10','C05','b',23,51,'A01'),('e11','C06','a',28,52,'A01'),('e12','C06','b',28,52,'A01'),('e13','C07','a',33,53,'A01'),('e14','C07','b',33,53,'A01'),('e15','C08','a',38,54,'A01'),('e16','C08','b',38,54,'A01'),('e17','C09','a',43,91,'A01'),('e18','C09','b',43,91,'A01'),('e19','C10','a',48,92,'A01'),('e2','C01','b',3,11,'A01'),('e20','C10','b',48,92,'A01'),('e21','C11','a',53,93,'A01'),('e22','C11','b',53,93,'A01'),('e23','C12','a',58,94,'A01'),('e24','C12','b',58,94,'A01'),('e3','C02','a',8,12,'A01'),('e4','C02','b',8,12,'A01'),('e5','C03','a',13,13,'A01'),('e6','C03','b',13,13,'A01'),('e7','C04','a',18,14,'A01'),('e8','C04','b',18,14,'A01'),('e9','C05','a',23,51,'A01'),('f1','C01','c',3,11,'A01'),('f10','C05','d',23,51,'A01'),('f11','C06','c',28,52,'A01'),('f12','C06','d',28,52,'A01'),('f13','C07','c',33,53,'A01'),('f14','C07','d',33,53,'A01'),('f15','C08','c',38,54,'A01'),('f16','C08','d',38,54,'A01'),('f17','C09','c',43,91,'A01'),('f18','C09','d',43,91,'A01'),('f19','C10','c',48,92,'A01'),('f2','C01','d',3,11,'A01'),('f20','C10','d',48,92,'A01'),('f21','C11','c',53,93,'A01'),('f22','C11','d',53,93,'A01'),('f23','C12','c',58,94,'A01'),('f24','C12','d',58,94,'A01'),('f3','C02','c',8,12,'A01'),('f4','C02','d',8,12,'A01'),('f5','C03','c',13,13,'A01'),('f6','C03','d',13,13,'A01'),('f7','C04','c',18,14,'A01'),('f8','C04','d',18,14,'A01'),('f9','C05','c',23,51,'A01'),('g1','D01','a',4,16,'A01'),('g10','D05','b',24,56,'A01'),('g11','D06','a',29,57,'A01'),('g12','D06','b',29,57,'A01'),('g13','D07','a',34,58,'A01'),('g14','D07','b',34,58,'A01'),('g15','D08','a',39,59,'A01'),('g16','D08','b',39,59,'A01'),('g17','D09','a',44,96,'A01'),('g18','D09','b',44,96,'A01'),('g19','D10','a',49,97,'A01'),('g2','D01','b',4,16,'A01'),('g20','D10','b',49,97,'A01'),('g21','D11','a',54,98,'A01'),('g22','D11','b',54,98,'A01'),('g23','D12','a',59,99,'A01'),('g24','D12','b',59,99,'A01'),('g3','D02','a',9,17,'A01'),('g4','D02','b',9,17,'A01'),('g5','D03','a',14,18,'A01'),('g6','D03','b',14,18,'A01'),('g7','D04','a',19,19,'A01'),('g8','D04','b',19,19,'A01'),('g9','D05','a',24,56,'A01'),('h1','D01','c',4,16,'A01'),('h10','D05','d',24,56,'A01'),('h11','D06','c',29,57,'A01'),('h12','D06','d',29,57,'A01'),('h13','D07','c',34,58,'A01'),('h14','D07','d',34,58,'A01'),('h15','D08','c',39,59,'A01'),('h16','D08','d',39,59,'A01'),('h17','D09','c',44,96,'A01'),('h18','D09','d',44,96,'A01'),('h19','D10','c',49,97,'A01'),('h2','D01','d',4,16,'A01'),('h20','D10','d',49,97,'A01'),('h21','D11','c',54,98,'A01'),('h22','D11','d',54,98,'A01'),('h23','D12','c',59,99,'A01'),('h24','D12','d',59,99,'A01'),('h3','D02','c',9,17,'A01'),('h4','D02','d',9,17,'A01'),('h5','D03','c',14,18,'A01'),('h6','D03','d',14,18,'A01'),('h7','D04','c',19,19,'A01'),('h8','D04','d',19,19,'A01'),('h9','D05','c',24,56,'A01'),('i1','E01','a',61,21,'A01'),('i10','E05','b',81,61,'A01'),('i11','E06','a',86,62,'A01'),('i12','E06','b',86,62,'A01'),('i13','E07','a',91,63,'A01'),('i14','E07','b',91,63,'A01'),('i15','E08','a',96,64,'A01'),('i16','E08','b',96,64,'A01'),('i17','E09','a',101,101,'A01'),('i18','E09','b',101,101,'A01'),('i19','E10','a',106,102,'A01'),('i2','E01','b',61,21,'A01'),('i20','E10','b',106,102,'A01'),('i21','E11','a',111,103,'A01'),('i22','E11','b',111,103,'A01'),('i23','E12','a',116,104,'A01'),('i24','E12','b',116,104,'A01'),('i3','E02','a',66,22,'A01'),('i4','E02','b',66,22,'A01'),('i5','E03','a',71,23,'A01'),('i6','E03','b',71,23,'A01'),('i7','E04','a',76,24,'A01'),('i8','E04','b',76,24,'A01'),('i9','E05','a',81,61,'A01'),('j1','E01','c',61,21,'A01'),('j10','E05','d',81,61,'A01'),('j11','E06','c',86,62,'A01'),('j12','E06','d',86,62,'A01'),('j13','E07','c',91,63,'A01'),('j14','E07','d',91,63,'A01'),('j15','E08','c',96,64,'A01'),('j16','E08','d',96,64,'A01'),('j17','E09','c',101,101,'A01'),('j18','E09','d',101,101,'A01'),('j19','E10','c',106,102,'A01'),('j2','E01','d',61,21,'A01'),('j20','E10','d',106,102,'A01'),('j21','E11','c',111,103,'A01'),('j22','E11','d',111,103,'A01'),('j23','E12','c',116,104,'A01'),('j24','E12','d',116,104,'A01'),('j3','E02','c',66,22,'A01'),('j4','E02','d',66,22,'A01'),('j5','E03','c',71,23,'A01'),('j6','E03','d',71,23,'A01'),('j7','E04','c',76,24,'A01'),('j8','E04','d',76,24,'A01'),('j9','E05','c',81,61,'A01'),('k1','F01','a',62,26,'A01'),('k10','F05','b',82,66,'A01'),('k11','F06','a',87,67,'A01'),('k12','F06','b',87,67,'A01'),('k13','F07','a',92,68,'A01'),('k14','F07','b',92,68,'A01'),('k15','F08','a',97,69,'A01'),('k16','F08','b',97,69,'A01'),('k17','F09','a',102,106,'A01'),('k18','F09','b',102,106,'A01'),('k19','F10','a',107,107,'A01'),('k2','F01','b',62,26,'A01'),('k20','F10','b',107,107,'A01'),('k21','F11','a',112,108,'A01'),('k22','F11','b',112,108,'A01'),('k23','F12','a',117,109,'A01'),('k24','F12','b',117,109,'A01'),('k3','F02','a',67,27,'A01'),('k4','F02','b',67,27,'A01'),('k5','F03','a',72,28,'A01'),('k6','F03','b',72,28,'A01'),('k7','F04','a',77,29,'A01'),('k8','F04','b',77,29,'A01'),('k9','F05','a',82,66,'A01'),('l1','F01','c',62,26,'A01'),('l10','F05','d',82,66,'A01'),('l11','F06','c',87,67,'A01'),('l12','F06','d',87,67,'A01'),('l13','F07','c',92,68,'A01'),('l14','F07','d',92,68,'A01'),('l15','F08','c',97,69,'A01'),('l16','F08','d',97,69,'A01'),('l17','F09','c',102,106,'A01'),('l18','F09','d',102,106,'A01'),('l19','F10','c',107,107,'A01'),('l2','F01','d',62,26,'A01'),('l20','F10','d',107,107,'A01'),('l21','F11','c',112,108,'A01'),('l22','F11','d',112,108,'A01'),('l23','F12','c',117,109,'A01'),('l24','F12','d',117,109,'A01'),('l3','F02','c',67,27,'A01'),('l4','F02','d',67,27,'A01'),('l5','F03','c',72,28,'A01'),('l6','F03','d',72,28,'A01'),('l7','F04','c',77,29,'A01'),('l8','F04','d',77,29,'A01'),('l9','F05','c',82,66,'A01'),('m1','G01','a',63,31,'A01'),('m10','G05','b',83,71,'A01'),('m11','G06','a',88,72,'A01'),('m12','G06','b',88,72,'A01'),('m13','G07','a',93,73,'A01'),('m14','G07','b',93,73,'A01'),('m15','G08','a',98,74,'A01'),('m16','G08','b',98,74,'A01'),('m17','G09','a',103,111,'A01'),('m18','G09','b',103,111,'A01'),('m19','G10','a',108,112,'A01'),('m2','G01','b',63,31,'A01'),('m20','G10','b',108,112,'A01'),('m21','G11','a',113,113,'A01'),('m22','G11','b',113,113,'A01'),('m23','G12','a',118,114,'A01'),('m24','G12','b',118,114,'A01'),('m3','G02','a',68,32,'A01'),('m4','G02','b',68,32,'A01'),('m5','G03','a',73,33,'A01'),('m6','G03','b',73,33,'A01'),('m7','G04','a',78,34,'A01'),('m8','G04','b',78,34,'A01'),('m9','G05','a',83,71,'A01'),('n1','G01','c',63,31,'A01'),('n10','G05','d',83,71,'A01'),('n11','G06','c',88,72,'A01'),('n12','G06','d',88,72,'A01'),('n13','G07','c',93,73,'A01'),('n14','G07','d',93,73,'A01'),('n15','G08','c',98,74,'A01'),('n16','G08','d',98,74,'A01'),('n17','G09','c',103,111,'A01'),('n18','G09','d',103,111,'A01'),('n19','G10','c',108,112,'A01'),('n2','G01','d',63,31,'A01'),('n20','G10','d',108,112,'A01'),('n21','G11','c',113,113,'A01'),('n22','G11','d',113,113,'A01'),('n23','G12','c',118,114,'A01'),('n24','G12','d',118,114,'A01'),('n3','G02','c',68,32,'A01'),('n4','G02','d',68,32,'A01'),('n5','G03','c',73,33,'A01'),('n6','G03','d',73,33,'A01'),('n7','G04','c',78,34,'A01'),('n8','G04','d',78,34,'A01'),('n9','G05','c',83,71,'A01'),('o1','H01','a',64,36,'A01'),('o10','H05','b',84,76,'A01'),('o11','H06','a',89,77,'A01'),('o12','H06','b',89,77,'A01'),('o13','H07','a',94,78,'A01'),('o14','H07','b',94,78,'A01'),('o15','H08','a',99,79,'A01'),('o16','H08','b',99,79,'A01'),('o17','H09','a',104,116,'A01'),('o18','H09','b',104,116,'A01'),('o19','H10','a',109,117,'A01'),('o2','H01','b',64,36,'A01'),('o20','H10','b',109,117,'A01'),('o21','H11','a',114,118,'A01'),('o22','H11','b',114,118,'A01'),('o23','H12','a',119,119,'A01'),('o24','H12','b',119,119,'A01'),('o3','H02','a',69,37,'A01'),('o4','H02','b',69,37,'A01'),('o5','H03','a',74,38,'A01'),('o6','H03','b',74,38,'A01'),('o7','H04','a',79,39,'A01'),('o8','H04','b',79,39,'A01'),('o9','H05','a',84,76,'A01'),('p1','H01','c',64,36,'A01'),('p10','H05','d',84,76,'A01'),('p11','H06','c',89,77,'A01'),('p12','H06','d',89,77,'A01'),('p13','H07','c',94,78,'A01'),('p14','H07','d',94,78,'A01'),('p15','H08','c',99,79,'A01'),('p16','H08','d',99,79,'A01'),('p17','H09','c',104,116,'A01'),('p18','H09','d',104,116,'A01'),('p19','H10','c',109,117,'A01'),('p2','H01','d',64,36,'A01'),('p20','H10','d',109,117,'A01'),('p21','H11','c',114,118,'A01'),('p22','H11','d',114,118,'A01'),('p23','H12','c',119,119,'A01'),('p24','H12','d',119,119,'A01'),('p3','H02','c',69,37,'A01'),('p4','H02','d',69,37,'A01'),('p5','H03','c',74,38,'A01'),('p6','H03','d',74,38,'A01'),('p7','H04','c',79,39,'A01'),('p8','H04','d',79,39,'A01'),('p9','H05','c',84,76,'A01');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Well_Lookup` ENABLE KEYS */;

--
-- Table structure for table `WorkLog`
--

DROP TABLE IF EXISTS `WorkLog`;
CREATE TABLE `WorkLog` (
  `WorkLog_ID` int(11) NOT NULL auto_increment,
  `FK_Employee__ID` int(11) NOT NULL default '0',
  `Work_Date` date default NULL,
  `Hours_Spent` decimal(6,2) default NULL,
  `FK_Issue__ID` int(11) default NULL,
  `Log_Date` date default NULL,
  `Log_Notes` text,
  `Revised_ETA` decimal(10,0) default NULL,
  `FK_Grp__ID` int(11) default '0',
  PRIMARY KEY  (`WorkLog_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `WorkLog`
--


/*!40000 ALTER TABLE `WorkLog` DISABLE KEYS */;
LOCK TABLES `WorkLog` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `WorkLog` ENABLE KEYS */;

--
-- Table structure for table `WorkPackage`
--

DROP TABLE IF EXISTS `WorkPackage`;
CREATE TABLE `WorkPackage` (
  `WorkPackage_ID` int(11) NOT NULL auto_increment,
  `FK_Issue__ID` int(11) default NULL,
  `WorkPackage_File` text,
  `WP_Name` varchar(60) default NULL,
  `WP_Comments` text,
  `WP_Obstacles` text,
  `WP_Priority_Details` text,
  `WP_Description` text,
  PRIMARY KEY  (`WorkPackage_ID`),
  UNIQUE KEY `Name` (`WP_Name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `WorkPackage`
--


/*!40000 ALTER TABLE `WorkPackage` DISABLE KEYS */;
LOCK TABLES `WorkPackage` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `WorkPackage` ENABLE KEYS */;

--
-- Table structure for table `WorkPackage_Attribute`
--

DROP TABLE IF EXISTS `WorkPackage_Attribute`;
CREATE TABLE `WorkPackage_Attribute` (
  `WorkPackage_Attribute_ID` int(11) NOT NULL auto_increment,
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `FK_WorkPackage__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text,
  PRIMARY KEY  (`WorkPackage_Attribute_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `WorkPackage_Attribute`
--


/*!40000 ALTER TABLE `WorkPackage_Attribute` DISABLE KEYS */;
LOCK TABLES `WorkPackage_Attribute` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `WorkPackage_Attribute` ENABLE KEYS */;

--
-- Table structure for table `Work_Request`
--

DROP TABLE IF EXISTS `Work_Request`;
CREATE TABLE `Work_Request` (
  `Work_Request_ID` int(11) NOT NULL auto_increment,
  `Plate_Size` enum('96-well','384-well') NOT NULL default '96-well',
  `Plates_To_Seq` int(11) default '0',
  `Plates_To_Pick` int(11) default '0',
  `FK_Goal__ID` int(11) default NULL,
  `Goal_Target` int(11) default NULL,
  `Comments` text,
  `FK_Submission__ID` int(11) NOT NULL default '0',
  `Work_Request_Type` enum('1/16 End Reads','1/24 End Reads','1/256 End Reads','1/16 Custom Reads','1/24 Custom Reads','1/256 Custom Reads','DNA Preps','Bac End Reads','1/256 Submission QC','1/256 Transposon','1/256 Single Prep End Reads','1/16 Glycerol Rearray Custom Reads','Primer Plates Ready','1/48 End Reads','1/48 Custom Reads') default NULL,
  `Num_Plates_Submitted` int(11) NOT NULL default '0',
  `FK_Plate_Format__ID` int(11) NOT NULL default '0',
  `FK_Work_Request_Type__ID` int(11) default '0',
  `FK_Library__Name` varchar(40) NOT NULL default '',
  `Goal_Target_Type` enum('Add to Original Target','Included in Original Target') default NULL,
  PRIMARY KEY  (`Work_Request_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Work_Request`
--


/*!40000 ALTER TABLE `Work_Request` DISABLE KEYS */;
LOCK TABLES `Work_Request` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Work_Request` ENABLE KEYS */;

--
-- Table structure for table `Work_Request_Type`
--

DROP TABLE IF EXISTS `Work_Request_Type`;
CREATE TABLE `Work_Request_Type` (
  `Work_Request_Type_ID` int(11) NOT NULL auto_increment,
  `Work_Request_Type_Name` varchar(100) NOT NULL default '',
  `Work_Request_Type_Description` text,
  PRIMARY KEY  (`Work_Request_Type_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Work_Request_Type`
--


/*!40000 ALTER TABLE `Work_Request_Type` DISABLE KEYS */;
LOCK TABLES `Work_Request_Type` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Work_Request_Type` ENABLE KEYS */;

--
-- Table structure for table `Xformed_Cells`
--

DROP TABLE IF EXISTS `Xformed_Cells`;
CREATE TABLE `Xformed_Cells` (
  `Xformed_Cells_ID` int(11) NOT NULL auto_increment,
  `VolumePerTube` int(11) default NULL,
  `Tubes` int(11) default NULL,
  `EstimatedClones` int(11) default NULL,
  `Cell_Catalog_Number` varchar(40) default NULL,
  `Xform_Method` varchar(40) default NULL,
  `Cell_Type` varchar(40) default NULL,
  `FKSupplier_Organization__ID` int(11) default NULL,
  `Sequencing_Type` enum('Primers','Transposon','Primers_and_transposon','Replicates') default NULL,
  `384_Well_Plates_To_Seq` int(11) default NULL,
  `FK_Source__ID` int(11) NOT NULL default '0',
  `384_Well_Plates_To_Pick` int(11) default '0',
  PRIMARY KEY  (`Xformed_Cells_ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`),
  KEY `FKSupplier_Organization__ID` (`FKSupplier_Organization__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Xformed_Cells`
--


/*!40000 ALTER TABLE `Xformed_Cells` DISABLE KEYS */;
LOCK TABLES `Xformed_Cells` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Xformed_Cells` ENABLE KEYS */;

--
-- Table structure for table `cDNA_Library`
--

DROP TABLE IF EXISTS `cDNA_Library`;
CREATE TABLE `cDNA_Library` (
  `cDNA_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Sequencing_Library__ID` int(11) NOT NULL default '0',
  `5Prime_Insert_Site_Enzyme` varchar(40) NOT NULL default '',
  `3Prime_Insert_Site_Enzyme` varchar(40) NOT NULL default '',
  `Blue_White_Selection` enum('Yes','No') NOT NULL default 'No',
  `FK3PrimeInsert_Restriction_Site__ID` int(11) default NULL,
  `FK5PrimeInsert_Restriction_Site__ID` int(11) default NULL,
  PRIMARY KEY  (`cDNA_Library_ID`),
  KEY `lib_id` (`FK_Sequencing_Library__ID`),
  KEY `FK3PrimeInsert_Restriction_Site__ID` (`FK3PrimeInsert_Restriction_Site__ID`),
  KEY `FK5PrimeInsert_Restriction_Site__ID` (`FK5PrimeInsert_Restriction_Site__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `cDNA_Library`
--


/*!40000 ALTER TABLE `cDNA_Library` DISABLE KEYS */;
LOCK TABLES `cDNA_Library` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `cDNA_Library` ENABLE KEYS */;

--
-- Table structure for table `junk`
--

DROP TABLE IF EXISTS `junk`;
CREATE TABLE `junk` (
  `Library_Name` varchar(40) NOT NULL default '',
  `comp` datetime default NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `junk`
--


/*!40000 ALTER TABLE `junk` DISABLE KEYS */;
LOCK TABLES `junk` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `junk` ENABLE KEYS */;

--
-- Table structure for table `org_tax_origin`
--

DROP TABLE IF EXISTS `org_tax_origin`;
CREATE TABLE `org_tax_origin` (
  `organism` int(11) default NULL,
  `taxonomy` int(11) default NULL,
  `original_source` int(11) default NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `org_tax_origin`
--


/*!40000 ALTER TABLE `org_tax_origin` DISABLE KEYS */;
LOCK TABLES `org_tax_origin` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `org_tax_origin` ENABLE KEYS */;

--
-- Table structure for table `temp_tax`
--

DROP TABLE IF EXISTS `temp_tax`;
CREATE TABLE `temp_tax` (
  `Tax_ID` int(11) NOT NULL default '0',
  `Organism` varchar(255) default NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `temp_tax`
--


/*!40000 ALTER TABLE `temp_tax` DISABLE KEYS */;
LOCK TABLES `temp_tax` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `temp_tax` ENABLE KEYS */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

