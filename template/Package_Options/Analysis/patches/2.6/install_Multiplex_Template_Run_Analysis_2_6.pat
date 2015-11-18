<DESCRIPTION> 
 This patch is for package Multiplex_Template_Run_Analysis 
</DESCRIPTION> 
<SCHEMA>  
CREATE TABLE `Multiplex_Template_Run_Analysis` (
  `Multiplex_Template_Run_Analysis_ID` int(11) NOT NULL auto_increment,
  `FK_Multiplex_Run_Analysis__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Multiplex_Template_Run_Analysis_ID`),
  KEY `Multiplex_Run_Analysis_ID` (`FK_Multiplex_Run_Analysis__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
</SCHEMA>  
<FINAL> 
UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'Multiplex_Template_Run_Analysis' AND Package.Package_Name = 'Template' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Multiplex_Template_Run_Analysis_ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' AND Package.Package_Name = 'Template' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Multiplex_Template_Run_Analysis_ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' ;
UPDATE DBField SET Prompt = 'ID' WHERE Field_Name = 'Multiplex_Template_Run_Analysis_ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'Multiplex_Template_Run_Analysis_ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Multiplex_Template_Run_Analysis_ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'Multiplex_Template_Run_Analysis_ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Multiplex_Template_Run_Analysis_ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' ;
UPDATE DBField SET Editable = 'no' WHERE Field_Name = 'Multiplex_Template_Run_Analysis_ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Multiplex_Template_Run_Analysis_ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Multiplex_Run_Analysis__ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' AND Package.Package_Name = 'Template' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Multiplex_Run_Analysis__ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' ;
UPDATE DBField SET Prompt = 'Run' WHERE Field_Name = 'FK_Multiplex_Run_Analysis__ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Multiplex_Run_Analysis__ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'FK_Multiplex_Run_Analysis__ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' ;
UPDATE DBField SET Field_Order = '2' WHERE Field_Name = 'FK_Multiplex_Run_Analysis__ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Multiplex_Run_Analysis__ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' ;
UPDATE DBField SET Editable = 'no' WHERE Field_Name = 'FK_Multiplex_Run_Analysis__ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Multiplex_Run_Analysis__ID' AND  Field_Table ='Multiplex_Template_Run_Analysis' ;
</FINAL>
