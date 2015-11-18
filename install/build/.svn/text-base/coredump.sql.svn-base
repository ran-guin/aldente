-- MySQL dump 10.9
--
-- Host: limsdev04    Database: skeleton
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
-- Table structure for table `Change_History`
--

DROP TABLE IF EXISTS `Change_History`;
CREATE TABLE `Change_History` (
  `Change_History_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_DBField__ID` int(11) NOT NULL DEFAULT '0',
  `Old_Value` varchar(255) DEFAULT NULL,
  `New_Value` varchar(255) DEFAULT NULL,
  `FK_Employee__ID` int(11) NOT NULL DEFAULT '0',
  `Modified_Date` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `Record_ID` varchar(40) NOT NULL DEFAULT '',
  `Comment` text,
  PRIMARY KEY (`Change_History_ID`),
  KEY `FK_DBField__ID` (`FK_DBField__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `record` (`Record_ID`),
  KEY `date` (`Modified_Date`)
) ENGINE=InnoDB AUTO_INCREMENT=3340391 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Change_History`
--


/*!40000 ALTER TABLE `Change_History` DISABLE KEYS */;
LOCK TABLES `Change_History` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Change_History` ENABLE KEYS */;

--
-- Table structure for table `DBField`
--

DROP TABLE IF EXISTS `DBField`;
CREATE TABLE `DBField` (
  `DBField_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Field_Description` text NOT NULL,
  `Field_Table` text NOT NULL,
  `Prompt` varchar(255) NOT NULL DEFAULT '',
  `Field_Alias` varchar(255) NOT NULL DEFAULT '',
  `Field_Options` set('Hidden','Mandatory','Primary','Unique','NewLink','ViewLink','ListLink','Searchable','Obsolete','ReadOnly','Required','Removed') DEFAULT NULL,
  `Field_Reference` varchar(255) NOT NULL DEFAULT '',
  `Field_Order` int(11) NOT NULL DEFAULT '0',
  `Field_Name` varchar(255) NOT NULL DEFAULT '',
  `Field_Type` text NOT NULL,
  `Field_Index` varchar(255) NOT NULL DEFAULT '',
  `NULL_ok` enum('NO','YES') NOT NULL DEFAULT 'YES',
  `Field_Default` varchar(255) NOT NULL DEFAULT '',
  `Field_Size` tinyint(4) DEFAULT '20',
  `Field_Format` varchar(80) DEFAULT NULL,
  `FK_DBTable__ID` int(11) DEFAULT NULL,
  `Foreign_Key` varchar(255) DEFAULT NULL,
  `DBField_Notes` text,
  `Editable` enum('yes','admin','no') DEFAULT 'yes',
  `Tracked` enum('yes','no') DEFAULT 'no',
  `Field_Scope` enum('Core','Optional','Custom') DEFAULT 'Custom',
  `FK_Package__ID` int(11) DEFAULT NULL,
  `List_Condition` varchar(255) DEFAULT NULL,
  `FKParent_DBField__ID` int(11) DEFAULT NULL,
  `Parent_Value` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`DBField_ID`),
  UNIQUE KEY `tblfld` (`FK_DBTable__ID`,`Field_Name`),
  UNIQUE KEY `field_name` (`Field_Name`,`FK_DBTable__ID`),
  KEY `fld` (`Field_Name`),
  KEY `package` (`FK_Package__ID`),
  KEY `Parent_DBField` (`FKParent_DBField__ID`)
) ENGINE=InnoDB AUTO_INCREMENT=4929 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `DBField`
--


/*!40000 ALTER TABLE `DBField` DISABLE KEYS */;
LOCK TABLES `DBField` WRITE;
INSERT INTO `DBField` VALUES (689,'','DBTable','DBTable ID','ID','Primary','DBTable_Name',1,'DBTable_ID','int(11)','PRI','NO','',20,'',487,'',NULL,'no','yes',NULL,24,NULL,NULL,NULL),(690,'','DBTable','Name','Name','','',5,'DBTable_Name','varchar(80)','UNI','NO','',20,'^.{0,80}$',487,'',NULL,'no','yes',NULL,24,NULL,NULL,NULL),(691,'','DBTable','Description','Description','','',6,'DBTable_Description','text','','YES','',20,'',487,'',NULL,'no','yes',NULL,24,NULL,NULL,NULL),(692,'','DBTable','Status','Status','','',7,'DBTable_Status','text','','YES','',20,'',487,'',NULL,'no','yes',NULL,24,NULL,NULL,NULL),(693,'','DBTable','Status Last Updated','Status_Last_Updated','','',8,'Status_Last_Updated','datetime','','NO','0000-00-00 00:00:00',20,'',487,'',NULL,'no','yes',NULL,24,NULL,NULL,NULL),(1723,'','DBTable','Type','Type','','',12,'DBTable_Type','enum(\'General\',\'Lab Object\',\'Lab Process\',\'Object Detail\',\'Settings\',\'Dynamic\',\'DB Management\',\'Application Specific\',\'Class\',\'Subclass\',\'Lookup\',\'Join\',\'Imported\',\'Manual Join\',\'Recursive Lookup\')','','YES','',20,'^.{0,20}$',487,'',NULL,'no','yes',NULL,24,NULL,NULL,NULL),(1724,'','DBTable','Title','Title','','',13,'DBTable_Title','varchar(80)','','NO','',20,'^.{0,80}$',487,'',NULL,'no','yes',NULL,24,NULL,NULL,NULL),(3537,'','DBTable','Scope','Scope','','',14,'Scope','enum(\'Core\',\'Lab\',\'Plugin\',\'Option\',\'Custom\')','','YES','',20,'',487,'',NULL,'no','yes',NULL,24,NULL,NULL,NULL),(3538,'','DBTable','Package Name','Package_Name','','',15,'Package_Name','varchar(40)','','YES','',20,'^.{0,40}$',487,'',NULL,'no','yes',NULL,24,NULL,NULL,NULL),(3539,'','DBTable','Records','Records','','',16,'Records','int(11)','','NO','',20,'',487,'',NULL,'no','yes',NULL,24,NULL,NULL,NULL),(3609,'','DBTable','Package','FK_Package__ID','','',17,'FK_Package__ID','int(11)','MUL','NO','',20,'',487,'Package.Package_ID',NULL,'no','yes','Custom',24,NULL,NULL,NULL),(4803,'','DBField','DBField ID','DBField_ID','Primary','Field_Name',1,'DBField_ID','int(11)','PRI','NO','',20,NULL,0,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4804,'','DBField','DBField ID','DBField_ID','Primary','Field_Name',1,'DBField_ID','int(11)','PRI','NO','',20,NULL,486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4805,'','DBField','Field Description','Field_Description','','',5,'Field_Description','text','','NO','',20,NULL,486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4806,'','DBField','Field Table','Field_Table','','',6,'Field_Table','text','','NO','',20,NULL,486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4807,'','DBField','Prompt','Prompt','','',7,'Prompt','varchar(255)','','NO','',20,'^.{0,255}$',486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4808,'','DBField','Field Alias','Field_Alias','','',8,'Field_Alias','varchar(255)','','NO','',20,'^.{0,255}$',486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4809,'','DBField','Field Options','Field_Options','','',12,'Field_Options','set(\'Hidden\',\'Mandatory\',\'Primary\',\'Unique\',\'NewLink\',\'ViewLink\',\'ListLink\',\'Searchable\',\'Obsolete\',\'ReadOnly\',\'Required\',\'Removed\')','','YES','',20,NULL,486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4810,'','DBField','Field Reference','Field_Reference','','',13,'Field_Reference','varchar(255)','','NO','',20,'^.{0,255}$',486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4811,'','DBField','Field Order','Field_Order','','',14,'Field_Order','int(11)','','NO','',20,NULL,486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4812,'','DBField','Field Name','Field_Name','','',15,'Field_Name','varchar(255)','MUL','NO','',20,'^.{0,255}$',486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4813,'','DBField','Field Type','Field_Type','','',16,'Field_Type','text','','NO','',20,NULL,486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4814,'','DBField','Field Index','Field_Index','','',17,'Field_Index','varchar(255)','','NO','',20,'^.{0,255}$',486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4815,'','DBField','NULL ok','NULL_ok','','',18,'NULL_ok','enum(\'NO\',\'YES\')','','NO','YES',20,NULL,486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4816,'','DBField','Field Default','Field_Default','','',19,'Field_Default','varchar(255)','','NO','',20,'^.{0,255}$',486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4817,'','DBField','Field Size','Field_Size','','',20,'Field_Size','tinyint(4)','','YES','20',20,NULL,486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4818,'','DBField','Field Format','Field_Format','','',21,'Field_Format','varchar(80)','','YES','',20,'^.{0,80}$',486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4819,'','DBField','FK_DBTable__ID','FK_DBTable__ID','','',22,'FK_DBTable__ID','int(11)','MUL','YES','',20,NULL,486,'DBTable.DBTable_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4820,'','DBField','Foreign Key','Foreign_Key','','',23,'Foreign_Key','varchar(255)','','YES','',20,'^.{0,255}$',486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4821,'','DBField','DBField Notes','DBField_Notes','','',24,'DBField_Notes','text','','YES','',20,NULL,486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4822,'','DBField','Editable','Editable','','',25,'Editable','enum(\'yes\',\'admin\',\'no\')','','YES','yes',20,NULL,486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4823,'','DBField','Tracked','Tracked','','',26,'Tracked','enum(\'yes\',\'no\')','','YES','no',20,NULL,486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4824,'','DBField','Field Scope','Field_Scope','','',27,'Field_Scope','enum(\'Core\',\'Optional\',\'Custom\')','','YES','Custom',20,NULL,486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4825,'','DBField','FK_Package__ID','FK_Package__ID','','',28,'FK_Package__ID','int(11)','MUL','YES','',20,NULL,486,'Package.Package_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4826,'','DBField','List Condition','List_Condition','','',29,'List_Condition','varchar(255)','','YES','',20,'^.{0,255}$',486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4827,'','DBField','Parent','FKParent_DBField__ID','','',30,'FKParent_DBField__ID','int(11)','MUL','YES','',20,NULL,486,'DBField.DBField_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4828,'','DBField','Parent Value','Parent_Value','','',31,'Parent_Value','varchar(255)','','YES','',20,'^.{0,255}$',486,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4829,'','Change_History','Change History ID','Change_History_ID','Primary','',1,'Change_History_ID','int(11)','PRI','NO','',20,NULL,488,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4830,'','Change_History','FK_DBField__ID','FK_DBField__ID','','',5,'FK_DBField__ID','int(11)','MUL','NO','',20,NULL,488,'DBField.DBField_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4831,'','Change_History','Old Value','Old_Value','','',6,'Old_Value','varchar(255)','','YES','',20,NULL,488,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4832,'','Change_History','New Value','New_Value','','',7,'New_Value','varchar(255)','','YES','',20,NULL,488,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4833,'','Change_History','FK_Employee__ID','FK_Employee__ID','','',8,'FK_Employee__ID','int(11)','MUL','NO','',20,NULL,488,'Employee.Employee_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4834,'','Change_History','Modified Date','Modified_Date','','',12,'Modified_Date','datetime','MUL','NO','0000-00-00 00:00:00',20,NULL,488,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4835,'','Change_History','Record ID','Record_ID','','',13,'Record_ID','varchar(40)','MUL','NO','',20,'^.{0,40}$',488,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4836,'','Change_History','Comment','Comment','','',14,'Comment','text','','YES','',20,NULL,488,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4837,'','DB_Form','DB Form ID','DB_Form_ID','Primary','concat(DB_Form_ID,\': \',Form_Table)',1,'DB_Form_ID','int(11)','PRI','NO','',20,NULL,489,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4838,'','DB_Form','Form Table','Form_Table','','',5,'Form_Table','varchar(80)','','NO','',20,'^.{0,80}$',489,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4839,'','DB_Form','Form Order','Form_Order','','',6,'Form_Order','int(2)','','YES','1',20,NULL,489,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4840,'','DB_Form','Min Records','Min_Records','','',7,'Min_Records','int(2)','','NO','1',20,NULL,489,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4841,'','DB_Form','Max Records','Max_Records','','',8,'Max_Records','int(2)','','NO','1',20,NULL,489,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4842,'','DB_Form','Parent','FKParent_DB_Form__ID','','',12,'FKParent_DB_Form__ID','int(11)','MUL','YES','',20,NULL,489,'DB_Form.DB_Form_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4843,'','DB_Form','Parent Field','Parent_Field','','',13,'Parent_Field','varchar(80)','','YES','',20,'^.{0,80}$',489,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4844,'','DB_Form','Parent Value','Parent_Value','','',14,'Parent_Value','varchar(200)','','YES','',20,'^.{0,200}$',489,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4845,'','DB_Form','Finish','Finish','','',15,'Finish','int(11)','','YES','',20,NULL,489,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4846,'','DB_Form','Class','Class','','',16,'Class','varchar(40)','','YES','',20,'^.{0,40}$',489,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4868,'','User','User ID','User_ID','Primary','User_Name',1,'User_ID','int(11)','PRI','NO','',20,NULL,493,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4869,'','User','User Name','User_Name','','',5,'User_Name','varchar(63)','','NO','',20,'^.{0,63}$',493,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4870,'','User','Email Address','Email_Address','','',6,'Email_Address','varchar(255)','','NO','',20,'^.{0,255}$',493,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4871,'','User','User Status','User_Status','','',7,'User_Status','enum(\'Active\',\'Inactive\',\'Old\')','','NO','Active',20,NULL,493,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4872,'','User','Password','Password','','',8,'Password','varchar(255)','','NO','',20,'^.{0,255}$',493,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4874,'','DB_Access','DB Access ID','DB_Access_ID','Primary','',1,'DB_Access_ID','tinyint(4)','PRI','NO','',20,NULL,494,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4875,'','DB_Access','DB Access Title','DB_Access_Title','','',2,'DB_Access_Title','varchar(255)','','NO','',20,NULL,494,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4876,'','DB_Access','Read Access','Read_Access','','',3,'Read_Access','enum(\'Y\',\'N\')','','NO','',20,NULL,494,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4877,'','DB_Access','Write Access','Write_Access','','',4,'Write_Access','enum(\'Y\',\'N\')','','NO','',20,NULL,494,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4878,'','DB_Access','Delete Access','Delete_Access','','',5,'Delete_Access','enum(\'Y\',\'N\')','','NO','',20,NULL,494,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4879,'','DB_Access','Restriction Type','Restriction_Type','','',6,'Restriction_Type','enum(\'N/A\',\'Specified Inclusions\',\'Specified Exclusions\')','','NO','',20,NULL,494,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4880,'','DB_Access','DB Access Description','DB_Access_Description','','',7,'DB_Access_Description','text','','YES','',20,NULL,494,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4881,'','DB_Login','DB Login ID','DB_Login_ID','Primary','',1,'DB_Login_ID','int(11)','PRI','NO','',20,NULL,495,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4882,'','DB_Login','FK_Employee__ID','FK_Employee__ID','','',2,'FK_Employee__ID','int(11)','','NO','',20,NULL,495,'Employee.Employee_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4883,'','DB_Login','DB User','DB_User','','',3,'DB_User','char(40)','','NO','',20,NULL,495,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4884,'','DB_Login','DB Access Level','DB_Access_Level','','',4,'DB_Access_Level','enum(\'0\',\'1\',\'2\',\'3\',\'4\',\'5\')','','YES','',20,NULL,495,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4885,'','DB_Login','DB Login Description','DB_Login_Description','','',5,'DB_Login_Description','text','','YES','',20,NULL,495,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4886,'','DB_Login','Production DB_Access','FKProduction_DB_Access__ID','','',6,'FKProduction_DB_Access__ID','int(11)','','NO','',20,NULL,495,'DB_Access.DB_Access_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4887,'','DB_Login','nonProduction DB_Access','FKnonProduction_DB_Access__ID','','',7,'FKnonProduction_DB_Access__ID','int(11)','','NO','',20,NULL,495,'DB_Access.DB_Access_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4888,'','Department','Department ID','Department_ID','Primary','Department_Name',1,'Department_ID','int(11)','PRI','NO','',20,NULL,496,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4889,'','Department','Department Name','Department_Name','','',2,'Department_Name','char(40)','','YES','',20,NULL,496,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4890,'','Department','Department Status','Department_Status','','',3,'Department_Status','enum(\'Active\',\'Inactive\')','','YES','',20,NULL,496,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4891,'','DepartmentSetting','DepartmentSetting ID','DepartmentSetting_ID','Primary','',1,'DepartmentSetting_ID','int(11)','PRI','NO','',20,NULL,497,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4892,'','DepartmentSetting','FK_Setting__ID','FK_Setting__ID','','',2,'FK_Setting__ID','int(11)','','YES','',20,NULL,497,'Setting.Setting_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4893,'','DepartmentSetting','Department','FK_Department__ID','','',3,'FK_Department__ID','int(11)','','YES','',20,NULL,497,'Department.Department_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4894,'','DepartmentSetting','Setting Value','Setting_Value','','',4,'Setting_Value','char(40)','','YES','',20,NULL,497,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4895,'','Grp','Grp ID','Grp_ID','Primary','Grp_Name',1,'Grp_ID','int(11)','PRI','NO','',20,NULL,498,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4896,'','Grp','Grp Name','Grp_Name','Mandatory','',2,'Grp_Name','varchar(80)','','NO','',20,NULL,498,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4897,'','Grp','Department','FK_Department__ID','Mandatory','',3,'FK_Department__ID','int(11)','','NO','',20,NULL,498,'Department.Department_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4898,'','Grp','Access','Access','Mandatory','',4,'Access','enum(\'Lab\',\'Admin\',\'Guest\',\'Report\',\'Bioinformatics\')','','YES','',20,NULL,498,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4899,'','Grp','Grp Type','Grp_Type','','',5,'Grp_Type','enum(\'Public\',\'Lab\',\'Lab Admin\',\'Project Admin\',\'TechD\',\'Production\',\'Research\',\'Technical Support\',\'Informatics\',\'QC\',\'Purchasing\',\'Shared\')','','YES','',20,NULL,498,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4900,'','Grp','Grp Status','Grp_Status','','',6,'Grp_Status','enum(\'Active\',\'Inactive\')','','YES','',20,NULL,498,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4901,'','Grp','DB_Login','FK_DB_Login__ID','','',7,'FK_DB_Login__ID','int(11)','','YES','',20,NULL,498,'DB_Login.DB_Login_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4902,'','Setting','Setting ID','Setting_ID','Primary','',1,'Setting_ID','int(11)','PRI','NO','',20,NULL,499,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4903,'','Setting','Setting Name','Setting_Name','','',2,'Setting_Name','varchar(40)','','YES','',20,NULL,499,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4904,'','Setting','Setting Default','Setting_Default','','',3,'Setting_Default','varchar(40)','','YES','',20,NULL,499,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4905,'','Setting','Setting Description','Setting_Description','','',4,'Setting_Description','text','','YES','',20,NULL,499,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4920,'','User','Department','FK_Department__ID','','',6,'FK_Department__ID','int(11)','','YES','',20,NULL,493,'Department.Department_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4921,'','User','User Access','User_Access','','',7,'User_Access','enum(\'Admin\',\'Host\',\'Guest\')','','YES','',20,NULL,493,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4922,'','UserSetting','UserSetting ID','UserSetting_ID','Primary','',1,'UserSetting_ID','int(11)','PRI','NO','',20,NULL,502,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4923,'','UserSetting','Setting','FK_Setting__ID','','',2,'FK_Setting__ID','int(11)','','YES','',20,NULL,502,'Setting.Setting_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4924,'','UserSetting','User','FK_User__ID','','',3,'FK_User__ID','int(11)','','YES','',20,NULL,502,'User.User_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4925,'','UserSetting','Setting Value','Setting_Value','','',4,'Setting_Value','char(40)','','YES','',20,NULL,502,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4926,'','User_Grp','User Grp ID','User_Grp_ID','Primary','',1,'User_Grp_ID','int(11)','PRI','NO','',20,NULL,503,'',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4927,'','User_Grp','Grp','FK_Grp__ID','','',2,'FK_Grp__ID','int(11)','','NO','',20,NULL,503,'Grp.Grp_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL),(4928,'','User_Grp','User','FK_User__ID','','',3,'FK_User__ID','int(11)','','NO','',20,NULL,503,'User.User_ID',NULL,'yes','no','Custom',NULL,NULL,NULL,NULL);
UNLOCK TABLES;
/*!40000 ALTER TABLE `DBField` ENABLE KEYS */;

--
-- Table structure for table `DBTable`
--

DROP TABLE IF EXISTS `DBTable`;
CREATE TABLE `DBTable` (
  `DBTable_ID` int(11) NOT NULL AUTO_INCREMENT,
  `DBTable_Name` varchar(80) NOT NULL DEFAULT '',
  `DBTable_Description` text,
  `DBTable_Status` text,
  `Status_Last_Updated` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `DBTable_Type` enum('General','Lab Object','Lab Process','Object Detail','Settings','Dynamic','DB Management','Application Specific','Class','Subclass','Lookup','Join','Imported','Manual Join','Recursive Lookup') DEFAULT NULL,
  `DBTable_Title` varchar(80) NOT NULL DEFAULT '',
  `Scope` enum('Core','Lab','Plugin','Option','Custom') DEFAULT NULL,
  `Package_Name` varchar(40) DEFAULT NULL,
  `Records` int(11) NOT NULL DEFAULT '0',
  `FK_Package__ID` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`DBTable_ID`),
  UNIQUE KEY `DBTable_Name` (`DBTable_Name`),
  UNIQUE KEY `name` (`DBTable_Name`),
  KEY `package` (`FK_Package__ID`)
) ENGINE=InnoDB AUTO_INCREMENT=504 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `DBTable`
--


/*!40000 ALTER TABLE `DBTable` DISABLE KEYS */;
LOCK TABLES `DBTable` WRITE;
INSERT INTO `DBTable` VALUES (486,'DBField',NULL,NULL,'0000-00-00 00:00:00',NULL,'DBField',NULL,NULL,0,0),(487,'DBTable',NULL,NULL,'0000-00-00 00:00:00',NULL,'DBTable',NULL,NULL,0,0),(488,'Change_History',NULL,NULL,'0000-00-00 00:00:00',NULL,'Change_History',NULL,NULL,0,0),(489,'DB_Form',NULL,NULL,'0000-00-00 00:00:00',NULL,'DB_Form',NULL,NULL,0,0),(493,'User',NULL,NULL,'0000-00-00 00:00:00',NULL,'User',NULL,NULL,0,0),(494,'DB_Access',NULL,NULL,'0000-00-00 00:00:00',NULL,'DB_Access',NULL,NULL,0,0),(495,'DB_Login',NULL,NULL,'0000-00-00 00:00:00',NULL,'DB_Login',NULL,NULL,0,0),(496,'Department',NULL,NULL,'0000-00-00 00:00:00',NULL,'Department',NULL,NULL,0,0),(497,'DepartmentSetting',NULL,NULL,'0000-00-00 00:00:00',NULL,'DepartmentSetting',NULL,NULL,0,0),(498,'Grp',NULL,NULL,'0000-00-00 00:00:00',NULL,'Grp',NULL,NULL,0,0),(499,'Setting',NULL,NULL,'0000-00-00 00:00:00',NULL,'Setting',NULL,NULL,0,0),(502,'UserSetting',NULL,NULL,'0000-00-00 00:00:00',NULL,'UserSetting',NULL,NULL,0,0),(503,'User_Grp',NULL,NULL,'0000-00-00 00:00:00',NULL,'User_Grp',NULL,NULL,0,0);
UNLOCK TABLES;
/*!40000 ALTER TABLE `DBTable` ENABLE KEYS */;

--
-- Table structure for table `DB_Access`
--

DROP TABLE IF EXISTS `DB_Access`;
CREATE TABLE `DB_Access` (
  `DB_Access_ID` tinyint(4) NOT NULL AUTO_INCREMENT,
  `DB_Access_Title` varchar(255) NOT NULL,
  `Read_Access` enum('Y','N') NOT NULL,
  `Write_Access` enum('Y','N') NOT NULL,
  `Delete_Access` enum('Y','N') NOT NULL,
  `Restriction_Type` enum('N/A','Specified Inclusions','Specified Exclusions') NOT NULL,
  `DB_Access_Description` text,
  PRIMARY KEY (`DB_Access_ID`),
  UNIQUE KEY `title` (`DB_Access_Title`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `DB_Access`
--


/*!40000 ALTER TABLE `DB_Access` DISABLE KEYS */;
LOCK TABLES `DB_Access` WRITE;
INSERT INTO `DB_Access` VALUES (1,'No Access','N','N','N','N/A','No Access to database'),(2,'Restricted Access','Y','N','N','Specified Inclusions','Highly restricted read access to specified list of tables'),(3,'Limited Read Access','Y','N','N','Specified Exclusions','Limited read access excluding specified list of tables'),(4,'Unlimited Read Access','Y','N','N','N/A','Unrestricted Read-Only Access'),(5,'Restricted R/W Access','Y','Y','N','Specified Inclusions','Highly restricted read / write access to specified list of tables'),(6,'Restricted Write Access','Y','Y','N','Specified Inclusions','Restricted write access to specified list of tables'),(7,'Limited Write Access','Y','Y','Y','Specified Exclusions','Limited write access excluding specified list of tables'),(8,'Expanded Write Access','Y','Y','Y','Specified Exclusions','Expanded write access excluding specified list of tables'),(9,'LIMS Staff Write Access','Y','Y','Y','Specified Exclusions','LIMS staff write access (may exclude certain tables)'),(10,'Root Access','Y','Y','Y','N/A','Unrestricted Access');
UNLOCK TABLES;
/*!40000 ALTER TABLE `DB_Access` ENABLE KEYS */;

--
-- Table structure for table `DB_Form`
--

DROP TABLE IF EXISTS `DB_Form`;
CREATE TABLE `DB_Form` (
  `DB_Form_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Form_Table` varchar(80) NOT NULL DEFAULT '',
  `Form_Order` int(2) DEFAULT '1',
  `Min_Records` int(2) NOT NULL DEFAULT '1',
  `Max_Records` int(2) NOT NULL DEFAULT '1',
  `FKParent_DB_Form__ID` int(11) DEFAULT NULL,
  `Parent_Field` varchar(80) DEFAULT NULL,
  `Parent_Value` varchar(200) DEFAULT NULL,
  `Finish` int(11) DEFAULT '0',
  `Class` varchar(40) DEFAULT NULL,
  PRIMARY KEY (`DB_Form_ID`),
  KEY `FKParent_DB_Form__ID` (`FKParent_DB_Form__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `DB_Form`
--


/*!40000 ALTER TABLE `DB_Form` DISABLE KEYS */;
LOCK TABLES `DB_Form` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `DB_Form` ENABLE KEYS */;

--
-- Table structure for table `DB_Login`
--

DROP TABLE IF EXISTS `DB_Login`;
CREATE TABLE `DB_Login` (
  `DB_Login_ID` int(11) NOT NULL AUTO_INCREMENT,
  `DB_User` char(40) NOT NULL DEFAULT '',
  `DB_Access_Level` enum('0','1','2','3','4','5') DEFAULT NULL,
  `DB_Login_Description` text,
  `FKProduction_DB_Access__ID` int(11) NOT NULL,
  `FKnonProduction_DB_Access__ID` int(11) NOT NULL,
  PRIMARY KEY (`DB_Login_ID`),
  KEY `Production_DB_Access` (`FKProduction_DB_Access__ID`),
  KEY `nonProduction_DB_Access` (`FKnonProduction_DB_Access__ID`)
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `DB_Login`
--


/*!40000 ALTER TABLE `DB_Login` DISABLE KEYS */;
LOCK TABLES `DB_Login` WRITE;
INSERT INTO `DB_Login` VALUES (14,'LIMS_admin','4','LIMS Administrators',9,9),(15,'login','0','Only used to generate login page (access to submit account request)',2,2),(16,'guest_user','','Guests and external users without LDAP password (read-only)',3,3),(17,'internal','0','Internal users without any other specified access (limited write access)',3,3),(18,'collab','0','Collaborators (access only to generate submission records)',5,5),(29,'super_admin','3','Administrators with special access to restricted fields',9,9),(30,'cron_user','0','Connect to run read-only cron jobs (very limited write access - eg notification tracking)',6,6),(31,'super_cron_user','4','Connect to run cron jobs (including full database restore)',7,7),(32,'read_api','','Read only api access',4,4),(33,'write_api','0','API with limited write access',6,6),(34,'super_api','1','API with special write access to limited fields',6,6),(36,'manual_tester','1','used for manual testing',4,8),(37,'unit_tester','1','used for running unit tests',4,8),(38,'repl_client','4','Connect to run cron jobs (including full database restore, start and stop replication capability)',10,10),(39,'patch_installer','1','used for installing patches to test database',0,0);
UNLOCK TABLES;
/*!40000 ALTER TABLE `DB_Login` ENABLE KEYS */;

--
-- Table structure for table `Department`
--

DROP TABLE IF EXISTS `Department`;
CREATE TABLE `Department` (
  `Department_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Department_Name` char(40) DEFAULT NULL,
  `Department_Status` enum('Active','Inactive') DEFAULT NULL,
  PRIMARY KEY (`Department_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Department`
--


/*!40000 ALTER TABLE `Department` DISABLE KEYS */;
LOCK TABLES `Department` WRITE;
INSERT INTO `Department` VALUES (1,'LIMS Admin','Active'),(2,'Public','Active'),(3,'Standard','Active');
UNLOCK TABLES;
/*!40000 ALTER TABLE `Department` ENABLE KEYS */;

--
-- Table structure for table `DepartmentSetting`
--

DROP TABLE IF EXISTS `DepartmentSetting`;
CREATE TABLE `DepartmentSetting` (
  `DepartmentSetting_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_Setting__ID` int(11) DEFAULT NULL,
  `FK_Department__ID` int(11) DEFAULT NULL,
  `Setting_Value` char(40) DEFAULT NULL,
  PRIMARY KEY (`DepartmentSetting_ID`),
  KEY `FK_Department__ID` (`FK_Department__ID`),
  KEY `FK_Setting__ID` (`FK_Setting__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `DepartmentSetting`
--


/*!40000 ALTER TABLE `DepartmentSetting` DISABLE KEYS */;
LOCK TABLES `DepartmentSetting` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `DepartmentSetting` ENABLE KEYS */;

--
-- Table structure for table `Grp`
--

DROP TABLE IF EXISTS `Grp`;
CREATE TABLE `Grp` (
  `Grp_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Grp_Name` varchar(80) NOT NULL DEFAULT '',
  `FK_Department__ID` int(11) NOT NULL DEFAULT '0',
  `Access` enum('Lab','Admin','Guest','Report','Bioinformatics') DEFAULT NULL,
  `Grp_Type` enum('Public','Lab','Lab Admin','Project Admin','TechD','Production','Research','Technical Support','Informatics','QC','Purchasing','Shared') DEFAULT NULL,
  `Grp_Status` enum('Active','Inactive') DEFAULT 'Active',
  `FK_DB_Login__ID` int(11) DEFAULT NULL,
  PRIMARY KEY (`Grp_ID`),
  KEY `dept_id` (`FK_Department__ID`),
  KEY `DB_Login` (`FK_DB_Login__ID`)
) ENGINE=InnoDB AUTO_INCREMENT=82 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Grp`
--


/*!40000 ALTER TABLE `Grp` DISABLE KEYS */;
LOCK TABLES `Grp` WRITE;
INSERT INTO `Grp` VALUES (1,'LIMS Admin',1,'Admin','Lab Admin','Active',14),(2,'Internal',3,'Lab','Shared','Active',20),(3,'External',2,'Guest','Public','Active',17),(4,'Public',2,'Guest','Public','Inactive',17);
UNLOCK TABLES;
/*!40000 ALTER TABLE `Grp` ENABLE KEYS */;

--
-- Table structure for table `Setting`
--

DROP TABLE IF EXISTS `Setting`;
CREATE TABLE `Setting` (
  `Setting_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Setting_Name` varchar(40) DEFAULT NULL,
  `Setting_Default` varchar(40) DEFAULT NULL,
  `Setting_Description` text,
  PRIMARY KEY (`Setting_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Setting`
--


/*!40000 ALTER TABLE `Setting` DISABLE KEYS */;
LOCK TABLES `Setting` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `Setting` ENABLE KEYS */;

--
-- Table structure for table `User`
--

DROP TABLE IF EXISTS `User`;
CREATE TABLE `User` (
  `User_ID` int(11) NOT NULL AUTO_INCREMENT,
  `User_Name` varchar(63) NOT NULL,
  `Email_Address` varchar(255) NOT NULL,
  `User_Status` enum('Active','Inactive','Old') NOT NULL DEFAULT 'Active',
  `Password` varchar(255) NOT NULL,
  `FK_Department__ID` int(11) DEFAULT NULL,
  `User_Access` enum('Admin','Host','Guest') DEFAULT 'Guest',
  PRIMARY KEY (`User_ID`),
  KEY `Department` (`FK_Department__ID`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `User`
--


/*!40000 ALTER TABLE `User` DISABLE KEYS */;
LOCK TABLES `User` WRITE;
INSERT INTO `User` VALUES (1,'Admin','rguin@bcgsc.ca','Active','*0C2BDB7971695D03A1E64F702E64C6F83DE0AF76',1,'Admin'),(2,'Guest','guest','Active','*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19',2,'Guest');
UNLOCK TABLES;
/*!40000 ALTER TABLE `User` ENABLE KEYS */;

--
-- Table structure for table `UserSetting`
--

DROP TABLE IF EXISTS `UserSetting`;
CREATE TABLE `UserSetting` (
  `UserSetting_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_Setting__ID` int(11) DEFAULT NULL,
  `FK_User__ID` int(11) DEFAULT NULL,
  `Setting_Value` char(40) DEFAULT NULL,
  PRIMARY KEY (`UserSetting_ID`),
  KEY `FK_User__ID` (`FK_User__ID`),
  KEY `FK_Setting__ID` (`FK_Setting__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `UserSetting`
--


/*!40000 ALTER TABLE `UserSetting` DISABLE KEYS */;
LOCK TABLES `UserSetting` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `UserSetting` ENABLE KEYS */;

--
-- Table structure for table `User_Grp`
--

DROP TABLE IF EXISTS `User_Grp`;
CREATE TABLE `User_Grp` (
  `User_Grp_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_Grp__ID` int(11) NOT NULL DEFAULT '0',
  `FK_User__ID` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`User_Grp_ID`),
  UNIQUE KEY `UniqueKey` (`FK_Grp__ID`,`FK_User__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_User__ID` (`FK_User__ID`)
) ENGINE=InnoDB AUTO_INCREMENT=2129 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `User_Grp`
--


/*!40000 ALTER TABLE `User_Grp` DISABLE KEYS */;
LOCK TABLES `User_Grp` WRITE;
INSERT INTO `User_Grp` VALUES (2125,1,1),(2128,81,2);
UNLOCK TABLES;
/*!40000 ALTER TABLE `User_Grp` ENABLE KEYS */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

