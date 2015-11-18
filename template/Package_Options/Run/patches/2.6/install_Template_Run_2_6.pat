<DESCRIPTION> 
 This patch is for package Template_Run 
</DESCRIPTION> 
<SCHEMA>  
CREATE TABLE `Template_Run` (
  `Template_Run_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `Template_Run_Finished` datetime NULL default NULL,
  PRIMARY KEY  (`Template_Run_ID`),
  KEY `run_id` (`FK_Run__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
</SCHEMA>  
<FINAL> 
UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'Template_Run' AND Package.Package_Name = 'Template' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Template_Run_ID' AND  Field_Table ='Template_Run' AND Package.Package_Name = 'Template' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Template_Run_ID' AND  Field_Table ='Template_Run' ;
UPDATE DBField SET Prompt = 'ID' WHERE Field_Name = 'Template_Run_ID' AND  Field_Table ='Template_Run' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'Template_Run_ID' AND  Field_Table ='Template_Run' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Template_Run_ID' AND  Field_Table ='Template_Run' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'Template_Run_ID' AND  Field_Table ='Template_Run' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Template_Run_ID' AND  Field_Table ='Template_Run' ;
UPDATE DBField SET Editable = 'no' WHERE Field_Name = 'Template_Run_ID' AND  Field_Table ='Template_Run' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Template_Run_ID' AND  Field_Table ='Template_Run' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='Template_Run' AND Package.Package_Name = 'Template' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='Template_Run' ;
UPDATE DBField SET Prompt = 'Run' WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='Template_Run' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='Template_Run' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='Template_Run' ;
UPDATE DBField SET Field_Order = '2' WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='Template_Run' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='Template_Run' ;
UPDATE DBField SET Editable = 'no' WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='Template_Run' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='Template_Run' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Template_Run_Finished' AND  Field_Table ='Template_Run' AND Package.Package_Name = 'Template' ; 
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Template_Run_Finished' AND  Field_Table ='Template_Run' ; 
UPDATE DBField SET Prompt = 'Run' WHERE Field_Name = 'Template_Run_Finished' AND  Field_Table ='Template_Run' ; 
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Template_Run_Finished' AND  Field_Table ='Template_Run' ; 
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Template_Run_Finished' AND  Field_Table ='Template_Run' ; 
UPDATE DBField SET Field_Order = '3' WHERE Field_Name = 'Template_Run_Finished' AND  Field_Table ='Template_Run' ; 
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Template_Run_Finished' AND  Field_Table ='Template_Run' ; 
UPDATE DBField SET Editable = 'no' WHERE Field_Name = 'Template_Run_Finished' AND  Field_Table ='Template_Run' ; 
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Template_Run_Finished' AND  Field_Table ='Template_Run' ; 
</FINAL>
