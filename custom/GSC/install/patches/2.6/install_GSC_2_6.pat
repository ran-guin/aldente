<DESCRIPTION> 
 This patch is for package GSC 
</DESCRIPTION> 
<SCHEMA>  
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

CREATE TABLE `Microtiter` (
  `Microtiter_ID` int(11) NOT NULL auto_increment,
  `Plates` int(11) default NULL,
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

CREATE TABLE `SAGE_Library` (
  `SAGE_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Vector_Based_Library__ID` int(11) NOT NULL default '0',
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
  PRIMARY KEY  (`SAGE_Library_ID`),
  KEY `lib_id` (`FK_Vector_Based_Library__ID`),
  KEY `FKAnchoring_Enzyme__ID` (`FKAnchoring_Enzyme__ID`),
  KEY `FKTagging_Enzyme__ID` (`FKTagging_Enzyme__ID`),
  KEY `FKInsertSite_Enzyme__ID` (`FKInsertSite_Enzyme__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

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

CREATE TABLE `Agilent_Assay` (
  `Agilent_Assay_ID` int(11) NOT NULL auto_increment,
  `Agilent_Assay_Name` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`Agilent_Assay_ID`),
  KEY `name` (`Agilent_Assay_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

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

CREATE TABLE `Transposon_Library` (
  `Transposon_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Vector_Based_Library__ID` int(11) NOT NULL default '0',
  `FK_Transposon__ID` int(11) NOT NULL default '0',
  `FK_Pool__ID` int(11) NOT NULL default '0',
  `Blue_White_Selection` enum('Yes','No') NOT NULL default 'No',
  PRIMARY KEY  (`Transposon_Library_ID`),
  KEY `lib_id` (`FK_Vector_Based_Library__ID`),
  KEY `transposon_id` (`FK_Transposon__ID`),
  KEY `pool_id` (`FK_Pool__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `Library_Segment` (
  `Library_Segment_ID` int(11) NOT NULL auto_increment,
  `FK_Vector__ID` int(11) NOT NULL default '0',
  `Non_Recombinants` float(5,2) default NULL,
  `Non_Insert_Clones` float(5,2) default NULL,
  `Recombinant_Clones` float(5,2) default NULL,
  `Average_Insert_Size` int(11) default NULL,
  `FK_Antibiotic__ID` int(11) default NULL,
  `Genome_Coverage` float(5,2) default NULL,
  `FK_Source__ID` int(11) NOT NULL default '0',
  `FK_Enzyme__ID` int(11) default NULL,
  PRIMARY KEY  (`Library_Segment_ID`),
  KEY `FK_Vector__ID` (`FK_Vector__ID`),
  KEY `FK_Antibiotic__ID` (`FK_Antibiotic__ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`),
  KEY `FK_Enzyme__ID` (`FK_Enzyme__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `Sorted_Cell` (
  `Sorted_Cell_ID` int(11) NOT NULL auto_increment,
  `FK_Source__ID` int(11) NOT NULL default '0',
  `FKSortedBy_Contact__ID` int(11) NOT NULL default '0',
  `Sorted_Cell_Type` enum('CD19+_Kappa+ B-Cells','CD19+_Lambda Light Chain+ B-Cells','CD19+ B-Cells') default NULL,
  `Sorted_Cell_Condition` enum('Fresh','Frozen') default NULL,
  PRIMARY KEY  (`Sorted_Cell_ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`,`FKSortedBy_Contact__ID`),
  KEY `FKSortedBy_Contact__ID` (`FKSortedBy_Contact__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `PCR_Product_Library` (
  `PCR_Product_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Library__Name` varchar(6) NOT NULL default '',
  `Purification` enum('Yes - already done','No - to be done') default 'No - to be done',
  `Product_Size` int(11) default NULL,
  PRIMARY KEY  (`PCR_Product_Library_ID`),
  UNIQUE KEY `FK_Library__Name` (`FK_Library__Name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

Alter Table Original_Source ADD COLUMN  `Sex` varchar(20) default NULL ;
Alter Table Original_Source ADD COLUMN  `FK_Stage__ID` int(11) default 0;
Alter Table Original_Source ADD COLUMN  `FK_Taxonomy__ID` int(11) NOT NULL default 0;
Alter Table Original_Source ADD COLUMN  `FK_Tissue__ID` int(11) default 0;
Alter Table Original_Source ADD COLUMN  `Host` text;
Alter Table Original_Source ADD COLUMN  `Strain` varchar(40) default NULL;
Create index taxonomy on Original_Source (FK_Taxonomy__ID);
Create index FK_Stage__ID  on Original_Source (FK_Stage__ID);
Create index FK_Tissue__ID  on Original_Source (FK_Tissue__ID);



</SCHEMA>  
<DATA>
## The install patches for 2_6 already have the changes in upgrade_GSC_2_6 done (i.e. upgrade_GSC_2_6 is installed during release 2.6 and the install patches for 2_6 are created after release with 2_6 database)
INSERT INTO Patch(FK_Package__ID,Patch_Type,Patch_Name,Install_Status,Installation_Date,FKRelease_Version__ID,Patch_Version) VALUES (1,'installation','upgrade_GSC_2_6','Installed',curdate(),10,'2.6.5.0.GSC.1');
</DATA>
<FINAL> 
 UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'Transposon' AND Package.Package_Name = 'GSC' ;
 UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'ConcentrationRun' AND Package.Package_Name = 'GSC' ;
 UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'Concentrations' AND Package.Package_Name = 'GSC' ;
 UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'Optical_Density' AND Package.Package_Name = 'GSC' ;
 UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'Microtiter' AND Package.Package_Name = 'GSC' ;
 UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'Ligation' AND Package.Package_Name = 'GSC' ;
 UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'Xformed_Cells' AND Package.Package_Name = 'GSC' ;
 UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'SAGE_Library' AND Package.Package_Name = 'GSC' ;
 UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'TraceData' AND Package.Package_Name = 'GSC' ;
 UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'Transposon_Pool' AND Package.Package_Name = 'GSC' ;
 UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'Agilent_Assay' AND Package.Package_Name = 'GSC' ;
 UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'Extraction_Details' AND Package.Package_Name = 'GSC' ;
 UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'Transposon_Library' AND Package.Package_Name = 'GSC' ;
 UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'Library_Segment' AND Package.Package_Name = 'GSC' ;
 UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'Sorted_Cell' AND Package.Package_Name = 'GSC' ;
 UPDATE DBTable,Package set DBTable.FK_Package__ID = Package_ID WHERE DBTable_Name = 'PCR_Product_Library' AND Package.Package_Name = 'GSC' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='ConcentrationRun' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Prompt = 'Plate' WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Reference = 'Plate_ID' WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Order = '2' WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='ConcentrationRun' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Equipment__ID' AND  Field_Table ='ConcentrationRun' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Equipment__ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Prompt = 'Equipment' WHERE Field_Name = 'FK_Equipment__ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Options = 'Mandatory,ViewLink' WHERE Field_Name = 'FK_Equipment__ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Reference = 'Equipment_ID' WHERE Field_Name = 'FK_Equipment__ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Order = '3' WHERE Field_Name = 'FK_Equipment__ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Equipment__ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Equipment__ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Equipment__ID' AND  Field_Table ='ConcentrationRun' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Well' AND  Field_Table ='Concentrations' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Well' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Prompt = 'Well' WHERE Field_Name = 'Well' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Well' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Well' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Order = '3' WHERE Field_Name = 'Well' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Well' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Well' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Well' AND  Field_Table ='Concentrations' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Concentration' AND  Field_Table ='Concentrations' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Concentration' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Prompt = 'Concentration' WHERE Field_Name = 'Concentration' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Concentration' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Concentration' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Order = '6' WHERE Field_Name = 'Concentration' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Format = '^.{0,10}$' WHERE Field_Name = 'Concentration' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Concentration' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Concentration' AND  Field_Table ='Concentrations' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='Optical_Density' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Prompt = 'Plate' WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Reference = 'Plate_ID' WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Plate__ID' AND  Field_Table ='Optical_Density' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Organization__ID' AND  Field_Table ='Transposon' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Organization__ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Prompt = 'Organization' WHERE Field_Name = 'FK_Organization__ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Options = 'Mandatory,NewLink,Searchable' WHERE Field_Name = 'FK_Organization__ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Reference = 'Organization_ID' WHERE Field_Name = 'FK_Organization__ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Order = '2' WHERE Field_Name = 'FK_Organization__ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Organization__ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Organization__ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Organization__ID' AND  Field_Table ='Transposon' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Antibiotic_Marker' AND  Field_Table ='Transposon' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Antibiotic_Marker' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Prompt = 'Antibiotic Marker' WHERE Field_Name = 'Antibiotic_Marker' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Antibiotic_Marker' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Antibiotic_Marker' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Order = '6' WHERE Field_Name = 'Antibiotic_Marker' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Antibiotic_Marker' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Antibiotic_Marker' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Antibiotic_Marker' AND  Field_Table ='Transposon' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'ConcentrationRun_ID' AND  Field_Table ='ConcentrationRun' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'ConcentrationRun_ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Prompt = 'ConcentrationRun ID' WHERE Field_Name = 'ConcentrationRun_ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'ConcentrationRun_ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'ConcentrationRun_ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'ConcentrationRun_ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'ConcentrationRun_ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'ConcentrationRun_ID' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'ConcentrationRun_ID' AND  Field_Table ='ConcentrationRun' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'DateTime' AND  Field_Table ='ConcentrationRun' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'DateTime' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Prompt = 'DateTime' WHERE Field_Name = 'DateTime' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'DateTime' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'DateTime' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Order = '4' WHERE Field_Name = 'DateTime' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'DateTime' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'DateTime' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Tracked = 'yes' WHERE Field_Name = 'DateTime' AND  Field_Table ='ConcentrationRun' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'CalibrationFunction' AND  Field_Table ='ConcentrationRun' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'CalibrationFunction' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Prompt = 'CalibrationFunction' WHERE Field_Name = 'CalibrationFunction' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'CalibrationFunction' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'CalibrationFunction' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Order = '5' WHERE Field_Name = 'CalibrationFunction' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'CalibrationFunction' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'CalibrationFunction' AND  Field_Table ='ConcentrationRun' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'CalibrationFunction' AND  Field_Table ='ConcentrationRun' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Concentration_ID' AND  Field_Table ='Concentrations' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Concentration_ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Prompt = 'Concentration ID' WHERE Field_Name = 'Concentration_ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'Concentration_ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Concentration_ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'Concentration_ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Concentration_ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Concentration_ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Concentration_ID' AND  Field_Table ='Concentrations' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_ConcentrationRun__ID' AND  Field_Table ='Concentrations' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_ConcentrationRun__ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Prompt = 'ConcentrationRun' WHERE Field_Name = 'FK_ConcentrationRun__ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_ConcentrationRun__ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Reference = 'ConcentrationRun_ID' WHERE Field_Name = 'FK_ConcentrationRun__ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Order = '2' WHERE Field_Name = 'FK_ConcentrationRun__ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_ConcentrationRun__ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_ConcentrationRun__ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_ConcentrationRun__ID' AND  Field_Table ='Concentrations' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Measurement' AND  Field_Table ='Concentrations' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Measurement' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Prompt = 'Measurement' WHERE Field_Name = 'Measurement' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Measurement' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Measurement' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Order = '4' WHERE Field_Name = 'Measurement' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Format = '^.{0,10}$' WHERE Field_Name = 'Measurement' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Measurement' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Measurement' AND  Field_Table ='Concentrations' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Units' AND  Field_Table ='Concentrations' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Units' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Prompt = 'Units' WHERE Field_Name = 'Units' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Units' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Units' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Order = '5' WHERE Field_Name = 'Units' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Format = '^.{0,15}$' WHERE Field_Name = 'Units' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Units' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Units' AND  Field_Table ='Concentrations' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = '260nm_Corrected' AND  Field_Table ='Optical_Density' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = '260nm_Corrected' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Prompt = '260nm Corrected' WHERE Field_Name = '260nm_Corrected' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = '260nm_Corrected' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = '260nm_Corrected' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Order = '2' WHERE Field_Name = '260nm_Corrected' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = '260nm_Corrected' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = '260nm_Corrected' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = '260nm_Corrected' AND  Field_Table ='Optical_Density' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = '280nm_Corrected' AND  Field_Table ='Optical_Density' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = '280nm_Corrected' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Prompt = '280nm Corrected' WHERE Field_Name = '280nm_Corrected' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = '280nm_Corrected' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = '280nm_Corrected' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Order = '3' WHERE Field_Name = '280nm_Corrected' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = '280nm_Corrected' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = '280nm_Corrected' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = '280nm_Corrected' AND  Field_Table ='Optical_Density' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Density' AND  Field_Table ='Optical_Density' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Density' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Prompt = 'Density' WHERE Field_Name = 'Density' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Density' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Density' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Order = '4' WHERE Field_Name = 'Density' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Density' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Density' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Density' AND  Field_Table ='Optical_Density' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Optical_Density_DateTime' AND  Field_Table ='Optical_Density' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Optical_Density_DateTime' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Prompt = 'DateTime' WHERE Field_Name = 'Optical_Density_DateTime' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Optical_Density_DateTime' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Optical_Density_DateTime' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Order = '5' WHERE Field_Name = 'Optical_Density_DateTime' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Optical_Density_DateTime' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Optical_Density_DateTime' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Tracked = 'yes' WHERE Field_Name = 'Optical_Density_DateTime' AND  Field_Table ='Optical_Density' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Concentration' AND  Field_Table ='Optical_Density' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Concentration' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Prompt = 'Concentration' WHERE Field_Name = 'Concentration' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Concentration' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Concentration' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Order = '6' WHERE Field_Name = 'Concentration' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Concentration' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Concentration' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Concentration' AND  Field_Table ='Optical_Density' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Optical_Density_ID' AND  Field_Table ='Optical_Density' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Optical_Density_ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Prompt = 'Optical Density ID' WHERE Field_Name = 'Optical_Density_ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'Optical_Density_ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Optical_Density_ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Order = '7' WHERE Field_Name = 'Optical_Density_ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Optical_Density_ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Optical_Density_ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Optical_Density_ID' AND  Field_Table ='Optical_Density' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Well' AND  Field_Table ='Optical_Density' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Well' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Prompt = 'Well' WHERE Field_Name = 'Well' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Well' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Well' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Order = '8' WHERE Field_Name = 'Well' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Well' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Well' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Well' AND  Field_Table ='Optical_Density' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Transposon_Name' AND  Field_Table ='Transposon' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Transposon_Name' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Prompt = 'Name' WHERE Field_Name = 'Transposon_Name' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Transposon_Name' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Transposon_Name' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'Transposon_Name' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Format = '^.{0,80}$' WHERE Field_Name = 'Transposon_Name' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Transposon_Name' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Transposon_Name' AND  Field_Table ='Transposon' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Transposon_Description' AND  Field_Table ='Transposon' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Transposon_Description' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Prompt = 'Description' WHERE Field_Name = 'Transposon_Description' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Transposon_Description' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Transposon_Description' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Order = '3' WHERE Field_Name = 'Transposon_Description' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Transposon_Description' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Transposon_Description' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Transposon_Description' AND  Field_Table ='Transposon' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Transposon_Sequence' AND  Field_Table ='Transposon' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Transposon_Sequence' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Prompt = 'Sequence' WHERE Field_Name = 'Transposon_Sequence' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Transposon_Sequence' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Transposon_Sequence' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Order = '4' WHERE Field_Name = 'Transposon_Sequence' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Transposon_Sequence' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Transposon_Sequence' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Transposon_Sequence' AND  Field_Table ='Transposon' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Transposon_Source_ID' AND  Field_Table ='Transposon' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Transposon_Source_ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Prompt = 'Source ID' WHERE Field_Name = 'Transposon_Source_ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Transposon_Source_ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Transposon_Source_ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Order = '5' WHERE Field_Name = 'Transposon_Source_ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Transposon_Source_ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Transposon_Source_ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Transposon_Source_ID' AND  Field_Table ='Transposon' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Transposon_ID' AND  Field_Table ='Transposon' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Transposon_ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Prompt = 'Transposon ID' WHERE Field_Name = 'Transposon_ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'Transposon_ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Reference = 'concat(Transposon_ID,": ",Transposon_Name)' WHERE Field_Name = 'Transposon_ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Order = '7' WHERE Field_Name = 'Transposon_ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Transposon_ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Transposon_ID' AND  Field_Table ='Transposon' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Transposon_ID' AND  Field_Table ='Transposon' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Microtiter_ID' AND  Field_Table ='Microtiter' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Microtiter_ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Prompt = 'Microtiter ID' WHERE Field_Name = 'Microtiter_ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'Microtiter_ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Microtiter_ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'Microtiter_ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Microtiter_ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Microtiter_ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Microtiter_ID' AND  Field_Table ='Microtiter' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Plates' AND  Field_Table ='Microtiter' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = 'Number o Plates' WHERE Field_Name = 'Plates' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Prompt = 'Number of Plates' WHERE Field_Name = 'Plates' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Plates' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Plates' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Order = '2' WHERE Field_Name = 'Plates' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Plates' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Plates' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Plates' AND  Field_Table ='Microtiter' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Plate_Catalog_Number' AND  Field_Table ='Microtiter' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Plate_Catalog_Number' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Prompt = 'Plate Catalog Number' WHERE Field_Name = 'Plate_Catalog_Number' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Plate_Catalog_Number' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Plate_Catalog_Number' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Order = '4' WHERE Field_Name = 'Plate_Catalog_Number' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Format = '^.{0,40}$' WHERE Field_Name = 'Plate_Catalog_Number' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Plate_Catalog_Number' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Plate_Catalog_Number' AND  Field_Table ='Microtiter' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'VolumePerWell' AND  Field_Table ='Microtiter' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'VolumePerWell' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Prompt = 'VolumePerWell' WHERE Field_Name = 'VolumePerWell' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = 'VolumePerWell' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'VolumePerWell' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Order = '5' WHERE Field_Name = 'VolumePerWell' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'VolumePerWell' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'VolumePerWell' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'VolumePerWell' AND  Field_Table ='Microtiter' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Microtiter' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Prompt = 'Cell Catalog Number' WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Order = '6' WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Format = '^.{0,40}$' WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Microtiter' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Ligation_ID' AND  Field_Table ='Ligation' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Ligation_ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Prompt = 'Ligation ID' WHERE Field_Name = 'Ligation_ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'Ligation_ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Ligation_ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'Ligation_ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Ligation_ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Ligation_ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Ligation_ID' AND  Field_Table ='Ligation' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Ligation_Volume' AND  Field_Table ='Ligation' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Ligation_Volume' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Prompt = 'Volume' WHERE Field_Name = 'Ligation_Volume' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Ligation_Volume' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Ligation_Volume' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Order = '2' WHERE Field_Name = 'Ligation_Volume' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Ligation_Volume' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Ligation_Volume' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Ligation_Volume' AND  Field_Table ='Ligation' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Xformed_Cells_ID' AND  Field_Table ='Xformed_Cells' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Xformed_Cells_ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Prompt = 'Xformed Cells ID' WHERE Field_Name = 'Xformed_Cells_ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'Xformed_Cells_ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Xformed_Cells_ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'Xformed_Cells_ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Xformed_Cells_ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Xformed_Cells_ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Xformed_Cells_ID' AND  Field_Table ='Xformed_Cells' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'VolumePerTube' AND  Field_Table ='Xformed_Cells' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'VolumePerTube' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Prompt = 'VolumePerTube' WHERE Field_Name = 'VolumePerTube' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = 'VolumePerTube' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'VolumePerTube' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Order = '2' WHERE Field_Name = 'VolumePerTube' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'VolumePerTube' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'VolumePerTube' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'VolumePerTube' AND  Field_Table ='Xformed_Cells' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Tubes' AND  Field_Table ='Xformed_Cells' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = 'Number of Tubes' WHERE Field_Name = 'Tubes' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Prompt = 'Number of Tubes' WHERE Field_Name = 'Tubes' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Tubes' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Tubes' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Order = '3' WHERE Field_Name = 'Tubes' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Tubes' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Tubes' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Tubes' AND  Field_Table ='Xformed_Cells' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'EstimatedClones' AND  Field_Table ='Xformed_Cells' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'EstimatedClones' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Prompt = 'cfu/ul' WHERE Field_Name = 'EstimatedClones' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'EstimatedClones' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'EstimatedClones' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Order = '4' WHERE Field_Name = 'EstimatedClones' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'EstimatedClones' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'EstimatedClones' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'EstimatedClones' AND  Field_Table ='Xformed_Cells' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Xformed_Cells' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Prompt = 'Cell Catalog Number' WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Order = '5' WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Format = '^.{0,40}$' WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Cell_Catalog_Number' AND  Field_Table ='Xformed_Cells' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'SAGE_Library_ID' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'SAGE_Library_ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'SAGE Library ID' WHERE Field_Name = 'SAGE_Library_ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'SAGE_Library_ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'SAGE_Library_ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'SAGE_Library_ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'SAGE_Library_ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'SAGE_Library_ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'SAGE_Library_ID' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Concatamer_Size_Fraction' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Concatamer_Size_Fraction' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'Concatamer Size Fraction' WHERE Field_Name = 'Concatamer_Size_Fraction' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'Concatamer_Size_Fraction' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Concatamer_Size_Fraction' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '6' WHERE Field_Name = 'Concatamer_Size_Fraction' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Concatamer_Size_Fraction' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Concatamer_Size_Fraction' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Concatamer_Size_Fraction' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Xform_Method' AND  Field_Table ='Xformed_Cells' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Xform_Method' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Prompt = 'Xform Method' WHERE Field_Name = 'Xform_Method' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = 'Xform_Method' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Xform_Method' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Order = '8' WHERE Field_Name = 'Xform_Method' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Format = '^.{0,40}$' WHERE Field_Name = 'Xform_Method' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Xform_Method' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Xform_Method' AND  Field_Table ='Xformed_Cells' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Xformed_Cells' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Prompt = 'Cell Type' WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Order = '9' WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Format = '^.{0,40}$' WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Xformed_Cells' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Xformed_Cells' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Prompt = 'Supplier Organization' WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Options = 'Hidden,NewLink,Searchable' WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Reference = 'Organization_ID' WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Order = '10' WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Xformed_Cells' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Xformed_Cells' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Prompt = 'Sequencing Type' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Order = '11' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Xformed_Cells' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Xformed_Cells' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Prompt = '384 Well Plates To Seq' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Order = '12' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Xformed_Cells' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Microtiter' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Prompt = 'Supplier Organization' WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Options = 'NewLink,Searchable' WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Reference = 'Organization_ID' WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Order = '9' WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FKSupplier_Organization__ID' AND  Field_Table ='Microtiter' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Microtiter' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Prompt = 'Cell Type' WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Order = '10' WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Format = '^.{0,40}$' WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Cell_Type' AND  Field_Table ='Microtiter' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Media_Type' AND  Field_Table ='Microtiter' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Media_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Prompt = 'Media Type' WHERE Field_Name = 'Media_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Media_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Media_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Order = '11' WHERE Field_Name = 'Media_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Format = '^.{0,40}$' WHERE Field_Name = 'Media_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Media_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Media_Type' AND  Field_Table ='Microtiter' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Microtiter' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Prompt = 'Sequencing Type' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Order = '12' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Microtiter' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Microtiter' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Prompt = '384 Well Plates To Seq' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Order = '13' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Microtiter' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Ligation' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Prompt = 'Sequencing Type' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Order = '6' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Sequencing_Type' AND  Field_Table ='Ligation' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Ligation' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Prompt = '384 Well Plates To Seq' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Order = '7' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = '384_Well_Plates_To_Seq' AND  Field_Table ='Ligation' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'TraceData_ID' AND  Field_Table ='TraceData' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'TraceData_ID' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Prompt = 'TraceData ID' WHERE Field_Name = 'TraceData_ID' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'TraceData_ID' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'TraceData_ID' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Order = '2' WHERE Field_Name = 'TraceData_ID' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'TraceData_ID' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'TraceData_ID' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'TraceData_ID' AND  Field_Table ='TraceData' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Mirrored' AND  Field_Table ='TraceData' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Mirrored' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Prompt = 'Mirrored' WHERE Field_Name = 'Mirrored' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Mirrored' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Mirrored' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Order = '3' WHERE Field_Name = 'Mirrored' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Mirrored' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Mirrored' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Mirrored' AND  Field_Table ='TraceData' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Archived' AND  Field_Table ='TraceData' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Archived' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Prompt = 'Archived' WHERE Field_Name = 'Archived' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Archived' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Archived' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Order = '4' WHERE Field_Name = 'Archived' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Archived' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Archived' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Archived' AND  Field_Table ='TraceData' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Checked' AND  Field_Table ='TraceData' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Checked' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Prompt = 'Checked' WHERE Field_Name = 'Checked' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Checked' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Checked' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Order = '5' WHERE Field_Name = 'Checked' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Checked' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Checked' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Checked' AND  Field_Table ='TraceData' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Machine' AND  Field_Table ='TraceData' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Machine' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Prompt = 'Machine' WHERE Field_Name = 'Machine' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Machine' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Machine' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Order = '6' WHERE Field_Name = 'Machine' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Format = '^.{0,20}$' WHERE Field_Name = 'Machine' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Machine' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Machine' AND  Field_Table ='TraceData' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Links' AND  Field_Table ='TraceData' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Links' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Prompt = 'Links' WHERE Field_Name = 'Links' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Links' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Links' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Order = '7' WHERE Field_Name = 'Links' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Links' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Links' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Links' AND  Field_Table ='TraceData' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Files' AND  Field_Table ='TraceData' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Files' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Prompt = 'Files' WHERE Field_Name = 'Files' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Files' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Files' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Order = '8' WHERE Field_Name = 'Files' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Files' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Files' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Files' AND  Field_Table ='TraceData' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Broken' AND  Field_Table ='TraceData' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Broken' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Prompt = 'Broken' WHERE Field_Name = 'Broken' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Broken' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Broken' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Order = '9' WHERE Field_Name = 'Broken' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Broken' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Broken' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Broken' AND  Field_Table ='TraceData' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Path' AND  Field_Table ='TraceData' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Path' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Prompt = 'Path' WHERE Field_Name = 'Path' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Path' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Path' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Order = '10' WHERE Field_Name = 'Path' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Path' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Path' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Path' AND  Field_Table ='TraceData' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Zipped' AND  Field_Table ='TraceData' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Zipped' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Prompt = 'Zipped' WHERE Field_Name = 'Zipped' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Zipped' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Zipped' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Order = '11' WHERE Field_Name = 'Zipped' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Zipped' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Zipped' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Zipped' AND  Field_Table ='TraceData' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Format' AND  Field_Table ='TraceData' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Format' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Prompt = 'Format' WHERE Field_Name = 'Format' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Format' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Format' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Order = '12' WHERE Field_Name = 'Format' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Format = '^.{0,20}$' WHERE Field_Name = 'Format' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Format' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Format' AND  Field_Table ='TraceData' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'MirroredSize' AND  Field_Table ='TraceData' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'MirroredSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Prompt = 'MirroredSize' WHERE Field_Name = 'MirroredSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'MirroredSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'MirroredSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Order = '13' WHERE Field_Name = 'MirroredSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'MirroredSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'MirroredSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'MirroredSize' AND  Field_Table ='TraceData' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'ArchivedSize' AND  Field_Table ='TraceData' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'ArchivedSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Prompt = 'ArchivedSize' WHERE Field_Name = 'ArchivedSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'ArchivedSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'ArchivedSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Order = '14' WHERE Field_Name = 'ArchivedSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'ArchivedSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'ArchivedSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'ArchivedSize' AND  Field_Table ='TraceData' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'ZippedSize' AND  Field_Table ='TraceData' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'ZippedSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Prompt = 'ZippedSize' WHERE Field_Name = 'ZippedSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'ZippedSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'ZippedSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Order = '15' WHERE Field_Name = 'ZippedSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'ZippedSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'ZippedSize' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'ZippedSize' AND  Field_Table ='TraceData' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FKExtraction_Plate__ID' AND  Field_Table ='Ligation' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FKExtraction_Plate__ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Prompt = 'Extraction Plate' WHERE Field_Name = 'FKExtraction_Plate__ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = 'FKExtraction_Plate__ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Reference = 'Plate_ID' WHERE Field_Name = 'FKExtraction_Plate__ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Order = '8' WHERE Field_Name = 'FKExtraction_Plate__ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FKExtraction_Plate__ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FKExtraction_Plate__ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FKExtraction_Plate__ID' AND  Field_Table ='Ligation' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'Vector Based Library' WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = 'Vector_Based_Library_ID' WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '2' WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'yes' WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'SAGE_Library_Type' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = 'Type of SAGE library (eg LongSAGE, 14bp SAGE)' WHERE Field_Name = 'SAGE_Library_Type' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'Type' WHERE Field_Name = 'SAGE_Library_Type' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'SAGE_Library_Type' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'SAGE_Library_Type' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '8' WHERE Field_Name = 'SAGE_Library_Type' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'SAGE_Library_Type' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'SAGE_Library_Type' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'yes' WHERE Field_Name = 'SAGE_Library_Type' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FKInsertSite_Enzyme__ID' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FKInsertSite_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'InsertSite Enzyme' WHERE Field_Name = 'FKInsertSite_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FKInsertSite_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = 'Enzyme_ID' WHERE Field_Name = 'FKInsertSite_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '9' WHERE Field_Name = 'FKInsertSite_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FKInsertSite_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FKInsertSite_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FKInsertSite_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FKAnchoring_Enzyme__ID' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FKAnchoring_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'Anchoring Enzyme' WHERE Field_Name = 'FKAnchoring_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FKAnchoring_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = 'Enzyme_ID' WHERE Field_Name = 'FKAnchoring_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '10' WHERE Field_Name = 'FKAnchoring_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FKAnchoring_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FKAnchoring_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FKAnchoring_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FKTagging_Enzyme__ID' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FKTagging_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'Tagging Enzyme' WHERE Field_Name = 'FKTagging_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FKTagging_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = 'Enzyme_ID' WHERE Field_Name = 'FKTagging_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '11' WHERE Field_Name = 'FKTagging_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FKTagging_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FKTagging_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FKTagging_Enzyme__ID' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Transposon_Pool_ID' AND  Field_Table ='Transposon_Pool' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Transposon_Pool_ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Prompt = 'Transposon Pool ID' WHERE Field_Name = 'Transposon_Pool_ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'Transposon_Pool_ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Transposon_Pool_ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'Transposon_Pool_ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Transposon_Pool_ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Transposon_Pool_ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Transposon_Pool_ID' AND  Field_Table ='Transposon_Pool' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Pool' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Prompt = 'Transposon' WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Reference = 'Transposon_ID' WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Order = '3' WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Pool' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Optical_Density__ID' AND  Field_Table ='Transposon_Pool' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Optical_Density__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Prompt = 'Optical Density' WHERE Field_Name = 'FK_Optical_Density__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'FK_Optical_Density__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Reference = 'Optical_Density_ID' WHERE Field_Name = 'FK_Optical_Density__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Order = '4' WHERE Field_Name = 'FK_Optical_Density__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Optical_Density__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Optical_Density__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Optical_Density__ID' AND  Field_Table ='Transposon_Pool' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Reads_Required' AND  Field_Table ='Transposon_Pool' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Reads_Required' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Prompt = 'Reads Required' WHERE Field_Name = 'Reads_Required' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Reads_Required' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Reads_Required' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Order = '6' WHERE Field_Name = 'Reads_Required' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Reads_Required' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Reads_Required' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Reads_Required' AND  Field_Table ='Transposon_Pool' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Pipeline' AND  Field_Table ='Transposon_Pool' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Pipeline' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Prompt = 'Pipeline' WHERE Field_Name = 'Pipeline' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'Pipeline' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Pipeline' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Order = '7' WHERE Field_Name = 'Pipeline' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Pipeline' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Pipeline' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Pipeline' AND  Field_Table ='Transposon_Pool' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Concentrations' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Prompt = 'Sample' WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Reference = 'Sample_ID' WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Order = '7' WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Concentrations' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Concentrations' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Optical_Density' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Prompt = 'Sample' WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Reference = 'Sample_ID' WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Order = '9' WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Optical_Density' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Sample__ID' AND  Field_Table ='Optical_Density' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Agilent_Assay_ID' AND  Field_Table ='Agilent_Assay' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Agilent_Assay_ID' AND  Field_Table ='Agilent_Assay' ;
UPDATE DBField SET Prompt = 'Agilent Assay ID' WHERE Field_Name = 'Agilent_Assay_ID' AND  Field_Table ='Agilent_Assay' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'Agilent_Assay_ID' AND  Field_Table ='Agilent_Assay' ;
UPDATE DBField SET Field_Reference = 'concat(Agilent_Assay_ID," : ",Agilent_Assay_Name)' WHERE Field_Name = 'Agilent_Assay_ID' AND  Field_Table ='Agilent_Assay' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'Agilent_Assay_ID' AND  Field_Table ='Agilent_Assay' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Agilent_Assay_ID' AND  Field_Table ='Agilent_Assay' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Agilent_Assay_ID' AND  Field_Table ='Agilent_Assay' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Agilent_Assay_ID' AND  Field_Table ='Agilent_Assay' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Agilent_Assay_Name' AND  Field_Table ='Agilent_Assay' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Agilent_Assay_Name' AND  Field_Table ='Agilent_Assay' ;
UPDATE DBField SET Prompt = 'Name' WHERE Field_Name = 'Agilent_Assay_Name' AND  Field_Table ='Agilent_Assay' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Agilent_Assay_Name' AND  Field_Table ='Agilent_Assay' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Agilent_Assay_Name' AND  Field_Table ='Agilent_Assay' ;
UPDATE DBField SET Field_Order = '2' WHERE Field_Name = 'Agilent_Assay_Name' AND  Field_Table ='Agilent_Assay' ;
UPDATE DBField SET Field_Format = '^.{0,255}$' WHERE Field_Name = 'Agilent_Assay_Name' AND  Field_Table ='Agilent_Assay' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Agilent_Assay_Name' AND  Field_Table ='Agilent_Assay' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Agilent_Assay_Name' AND  Field_Table ='Agilent_Assay' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Extraction_Details_ID' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Extraction_Details_ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'Extraction Details ID' WHERE Field_Name = 'Extraction_Details_ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'Extraction_Details_ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Extraction_Details_ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'Extraction_Details_ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Extraction_Details_ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Extraction_Details_ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Extraction_Details_ID' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Extraction_Sample__ID' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Extraction_Sample__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'Extraction Sample' WHERE Field_Name = 'FK_Extraction_Sample__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Extraction_Sample__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = 'Extraction_Sample_ID' WHERE Field_Name = 'FK_Extraction_Sample__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '2' WHERE Field_Name = 'FK_Extraction_Sample__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Extraction_Sample__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Extraction_Sample__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Extraction_Sample__ID' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FKIsolated_Employee__ID' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FKIsolated_Employee__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'Isolated Employee' WHERE Field_Name = 'FKIsolated_Employee__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'FKIsolated_Employee__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = 'Employee_ID' WHERE Field_Name = 'FKIsolated_Employee__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '4' WHERE Field_Name = 'FKIsolated_Employee__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FKIsolated_Employee__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FKIsolated_Employee__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FKIsolated_Employee__ID' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Disruption_Method' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Disruption_Method' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'Disruption Method' WHERE Field_Name = 'Disruption_Method' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Disruption_Method' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Disruption_Method' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '5' WHERE Field_Name = 'Disruption_Method' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Disruption_Method' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Disruption_Method' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Disruption_Method' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Isolation_Method' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Isolation_Method' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'Isolation Method' WHERE Field_Name = 'Isolation_Method' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Isolation_Method' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Isolation_Method' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '6' WHERE Field_Name = 'Isolation_Method' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Isolation_Method' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Isolation_Method' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Isolation_Method' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Resuspension_Volume' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Resuspension_Volume' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'Resuspension Volume' WHERE Field_Name = 'Resuspension_Volume' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Resuspension_Volume' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Resuspension_Volume' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '7' WHERE Field_Name = 'Resuspension_Volume' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Resuspension_Volume' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Resuspension_Volume' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Resuspension_Volume' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Resuspension_Volume_Units' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Resuspension_Volume_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'Resuspension Volume Units' WHERE Field_Name = 'Resuspension_Volume_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Resuspension_Volume_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Resuspension_Volume_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '8' WHERE Field_Name = 'Resuspension_Volume_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Resuspension_Volume_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Resuspension_Volume_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Resuspension_Volume_Units' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Agilent_Assay__ID' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Agilent_Assay__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'Agilent Assay' WHERE Field_Name = 'FK_Agilent_Assay__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'FK_Agilent_Assay__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = 'Agilent_Assay_ID' WHERE Field_Name = 'FK_Agilent_Assay__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '11' WHERE Field_Name = 'FK_Agilent_Assay__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Agilent_Assay__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Agilent_Assay__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Agilent_Assay__ID' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Assay_Quality' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Assay_Quality' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'Assay Quality' WHERE Field_Name = 'Assay_Quality' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Assay_Quality' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Assay_Quality' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '12' WHERE Field_Name = 'Assay_Quality' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Assay_Quality' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Assay_Quality' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Assay_Quality' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Assay_Quantity' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Assay_Quantity' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'Assay Quantity' WHERE Field_Name = 'Assay_Quantity' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Assay_Quantity' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Assay_Quantity' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '13' WHERE Field_Name = 'Assay_Quantity' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Assay_Quantity' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Assay_Quantity' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Assay_Quantity' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Assay_Quantity_Units' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Assay_Quantity_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'Assay Quantity Units' WHERE Field_Name = 'Assay_Quantity_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Assay_Quantity_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Assay_Quantity_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '14' WHERE Field_Name = 'Assay_Quantity_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Assay_Quantity_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Assay_Quantity_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Assay_Quantity_Units' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Total_Yield' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Total_Yield' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'Total Yield' WHERE Field_Name = 'Total_Yield' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Total_Yield' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Total_Yield' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '15' WHERE Field_Name = 'Total_Yield' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Total_Yield' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Total_Yield' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Total_Yield' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Total_Yield_Units' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Total_Yield_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'Total Yield Units' WHERE Field_Name = 'Total_Yield_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Total_Yield_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Total_Yield_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '16' WHERE Field_Name = 'Total_Yield_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Total_Yield_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Total_Yield_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Total_Yield_Units' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Extraction_Size_Estimate' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Extraction_Size_Estimate' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'Extraction Size Estimate' WHERE Field_Name = 'Extraction_Size_Estimate' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Extraction_Size_Estimate' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Extraction_Size_Estimate' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '17' WHERE Field_Name = 'Extraction_Size_Estimate' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Extraction_Size_Estimate' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Extraction_Size_Estimate' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Extraction_Size_Estimate' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Band__ID' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Band__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'Band' WHERE Field_Name = 'FK_Band__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Band__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = 'Band_ID' WHERE Field_Name = 'FK_Band__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '18' WHERE Field_Name = 'FK_Band__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Band__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Band__ID' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Band__ID' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Ligation' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Prompt = 'Source' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Reference = 'Source_ID' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Order = '10' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Ligation' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Microtiter' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Prompt = 'Source' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Reference = 'Source_ID' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Order = '15' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Microtiter' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Microtiter' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Test_Status' AND  Field_Table ='Transposon_Pool' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Test_Status' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Prompt = 'Test Status' WHERE Field_Name = 'Test_Status' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Test_Status' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Test_Status' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Order = '7' WHERE Field_Name = 'Test_Status' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Test_Status' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Test_Status' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Test_Status' AND  Field_Table ='Transposon_Pool' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Status' AND  Field_Table ='Transposon_Pool' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Status' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Prompt = 'Status' WHERE Field_Name = 'Status' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Status' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Status' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Order = '8' WHERE Field_Name = 'Status' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Status' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Status' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Status' AND  Field_Table ='Transposon_Pool' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Transposon_Pool' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Prompt = 'Source' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Reference = 'Source_ID' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Order = '9' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Transposon_Pool' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Pool' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Prompt = 'Pool' WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Reference = 'Pool_ID' WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Order = '10' WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Pool' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Xformed_Cells' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Prompt = 'Source' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Reference = 'Source_ID' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Order = '14' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Xformed_Cells' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'cfu' AND  Field_Table ='Ligation' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'cfu' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Prompt = 'cfu/ul' WHERE Field_Name = 'cfu' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'cfu' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'cfu' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Order = '3' WHERE Field_Name = 'cfu' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'cfu' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'cfu' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'cfu' AND  Field_Table ='Ligation' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Clones_under500Insert_Percent' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Clones_under500Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'Clones under500Insert Percent' WHERE Field_Name = 'Clones_under500Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'Clones_under500Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Clones_under500Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '4' WHERE Field_Name = 'Clones_under500Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Clones_under500Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Clones_under500Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Clones_under500Insert_Percent' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Clones_over500Insert_Percent' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Clones_over500Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'Clones over500Insert Percent' WHERE Field_Name = 'Clones_over500Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'Clones_over500Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Clones_over500Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '5' WHERE Field_Name = 'Clones_over500Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Clones_over500Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Clones_over500Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Clones_over500Insert_Percent' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Tags_Requested' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = 'Number of Tags requested by the colaborator for this library' WHERE Field_Name = 'Tags_Requested' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'Tags Requested' WHERE Field_Name = 'Tags_Requested' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'Tags_Requested' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Tags_Requested' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '6' WHERE Field_Name = 'Tags_Requested' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Tags_Requested' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Tags_Requested' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Tags_Requested' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Clones_with_no_Insert_Percent' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Clones_with_no_Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'Clones with no Insert Percent' WHERE Field_Name = 'Clones_with_no_Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = 'Clones_with_no_Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Clones_with_no_Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '12' WHERE Field_Name = 'Clones_with_no_Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Clones_with_no_Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Clones_with_no_Insert_Percent' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Clones_with_no_Insert_Percent' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Ligation' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = 'Number of 384 well glycerol plates to pick from the agar plates' WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Prompt = '384 Well Plates To Pick' WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Order = '9' WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Ligation' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Ligation' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Xformed_Cells' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = 'Number of 384 well glycerol plates to pick from the agar plates' WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Prompt = '384 Well Plates To Pick' WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Order = '13' WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Xformed_Cells' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = '384_Well_Plates_To_Pick' AND  Field_Table ='Xformed_Cells' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Transposon_Library_ID' AND  Field_Table ='Transposon_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Transposon_Library_ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Prompt = 'Transposon Library ID' WHERE Field_Name = 'Transposon_Library_ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'Transposon_Library_ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Transposon_Library_ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'Transposon_Library_ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Transposon_Library_ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Transposon_Library_ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Transposon_Library_ID' AND  Field_Table ='Transposon_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='Transposon_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Prompt = 'Vector Based Library' WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Reference = 'Vector_Based_Library_ID' WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Order = '2' WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Vector_Based_Library__ID' AND  Field_Table ='Transposon_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Prompt = 'Transposon' WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Order = '3' WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Transposon__ID' AND  Field_Table ='Transposon_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Prompt = 'Pool' WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Order = '4' WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Pool__ID' AND  Field_Table ='Transposon_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Library_Segment_ID' AND  Field_Table ='Library_Segment' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Library_Segment_ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Prompt = 'Library Segment ID' WHERE Field_Name = 'Library_Segment_ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'Library_Segment_ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Library_Segment_ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'Library_Segment_ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Library_Segment_ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Library_Segment_ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Library_Segment_ID' AND  Field_Table ='Library_Segment' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Vector__ID' AND  Field_Table ='Library_Segment' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Vector__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Prompt = 'Vector' WHERE Field_Name = 'FK_Vector__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Vector__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'FK_Vector__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Order = '2' WHERE Field_Name = 'FK_Vector__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Vector__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Vector__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Vector__ID' AND  Field_Table ='Library_Segment' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Non_Recombinants' AND  Field_Table ='Library_Segment' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Non_Recombinants' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Prompt = 'Non Recombinants' WHERE Field_Name = 'Non_Recombinants' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Non_Recombinants' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Non_Recombinants' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Order = '3' WHERE Field_Name = 'Non_Recombinants' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Non_Recombinants' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Non_Recombinants' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Non_Recombinants' AND  Field_Table ='Library_Segment' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Non_Insert_Clones' AND  Field_Table ='Library_Segment' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Non_Insert_Clones' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Prompt = 'Non Insert Clones' WHERE Field_Name = 'Non_Insert_Clones' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Non_Insert_Clones' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Non_Insert_Clones' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Order = '4' WHERE Field_Name = 'Non_Insert_Clones' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Non_Insert_Clones' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Non_Insert_Clones' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Non_Insert_Clones' AND  Field_Table ='Library_Segment' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Recombinant_Clones' AND  Field_Table ='Library_Segment' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Recombinant_Clones' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Prompt = 'Recombinant Clones' WHERE Field_Name = 'Recombinant_Clones' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Recombinant_Clones' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Recombinant_Clones' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Order = '5' WHERE Field_Name = 'Recombinant_Clones' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Recombinant_Clones' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Recombinant_Clones' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Recombinant_Clones' AND  Field_Table ='Library_Segment' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Average_Insert_Size' AND  Field_Table ='Library_Segment' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Average_Insert_Size' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Prompt = 'Average Insert Size' WHERE Field_Name = 'Average_Insert_Size' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Average_Insert_Size' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Average_Insert_Size' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Order = '6' WHERE Field_Name = 'Average_Insert_Size' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Average_Insert_Size' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Average_Insert_Size' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Average_Insert_Size' AND  Field_Table ='Library_Segment' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Antibiotic__ID' AND  Field_Table ='Library_Segment' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Antibiotic__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Prompt = 'Antibiotic' WHERE Field_Name = 'FK_Antibiotic__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Antibiotic__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'FK_Antibiotic__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Order = '7' WHERE Field_Name = 'FK_Antibiotic__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Antibiotic__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Antibiotic__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Antibiotic__ID' AND  Field_Table ='Library_Segment' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Genome_Coverage' AND  Field_Table ='Library_Segment' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Genome_Coverage' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Prompt = 'Genome Coverage' WHERE Field_Name = 'Genome_Coverage' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Genome_Coverage' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Genome_Coverage' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Order = '8' WHERE Field_Name = 'Genome_Coverage' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Genome_Coverage' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Genome_Coverage' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Genome_Coverage' AND  Field_Table ='Library_Segment' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Enzyme__ID' AND  Field_Table ='Library_Segment' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Enzyme__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Prompt = 'Restriction Site' WHERE Field_Name = 'FK_Enzyme__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Options = 'Mandatory,NewLink' WHERE Field_Name = 'FK_Enzyme__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Reference = 'Enzyme_ID' WHERE Field_Name = 'FK_Enzyme__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Order = '9' WHERE Field_Name = 'FK_Enzyme__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Enzyme__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Enzyme__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Enzyme__ID' AND  Field_Table ='Library_Segment' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'PCR_Cycles' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'PCR_Cycles' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'PCR Cycles' WHERE Field_Name = 'PCR_Cycles' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'PCR_Cycles' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'PCR_Cycles' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '14' WHERE Field_Name = 'PCR_Cycles' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'PCR_Cycles' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'PCR_Cycles' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'PCR_Cycles' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'cDNA_Amnt_Used_ng' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'cDNA_Amnt_Used_ng' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'cDNA Amnt Used ng' WHERE Field_Name = 'cDNA_Amnt_Used_ng' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'cDNA_Amnt_Used_ng' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'cDNA_Amnt_Used_ng' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '15' WHERE Field_Name = 'cDNA_Amnt_Used_ng' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'cDNA_Amnt_Used_ng' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'cDNA_Amnt_Used_ng' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'cDNA_Amnt_Used_ng' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'DiTag_PCR_Cycle' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'DiTag_PCR_Cycle' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'DiTag PCR Cycle' WHERE Field_Name = 'DiTag_PCR_Cycle' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'DiTag_PCR_Cycle' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'DiTag_PCR_Cycle' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '16' WHERE Field_Name = 'DiTag_PCR_Cycle' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'DiTag_PCR_Cycle' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'DiTag_PCR_Cycle' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'DiTag_PCR_Cycle' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'DiTag_Template_Dilution_Factor' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'DiTag_Template_Dilution_Factor' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'DiTag Template Dilution Factor' WHERE Field_Name = 'DiTag_Template_Dilution_Factor' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'DiTag_Template_Dilution_Factor' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'DiTag_Template_Dilution_Factor' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '17' WHERE Field_Name = 'DiTag_Template_Dilution_Factor' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'DiTag_Template_Dilution_Factor' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'DiTag_Template_Dilution_Factor' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'DiTag_Template_Dilution_Factor' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Adapter_A' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Adapter_A' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'Adapter A' WHERE Field_Name = 'Adapter_A' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Adapter_A' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Adapter_A' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '18' WHERE Field_Name = 'Adapter_A' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '^.{0,20}$' WHERE Field_Name = 'Adapter_A' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Adapter_A' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Adapter_A' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Adapter_B' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Adapter_B' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'Adapter B' WHERE Field_Name = 'Adapter_B' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Adapter_B' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Adapter_B' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '19' WHERE Field_Name = 'Adapter_B' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '^.{0,20}$' WHERE Field_Name = 'Adapter_B' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Adapter_B' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Adapter_B' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_GelRun__ID' AND  Field_Table ='Transposon_Pool' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_GelRun__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Prompt = 'GelRun' WHERE Field_Name = 'FK_GelRun__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'FK_GelRun__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'FK_GelRun__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Order = '4' WHERE Field_Name = 'FK_GelRun__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_GelRun__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_GelRun__ID' AND  Field_Table ='Transposon_Pool' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_GelRun__ID' AND  Field_Table ='Transposon_Pool' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Library_Segment' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Prompt = 'Source' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Order = '10' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Library_Segment' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Library_Segment' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Sorted_Cell_ID' AND  Field_Table ='Sorted_Cell' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Sorted_Cell_ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Prompt = 'ID' WHERE Field_Name = 'Sorted_Cell_ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'Sorted_Cell_ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Sorted_Cell_ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'Sorted_Cell_ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Sorted_Cell_ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Sorted_Cell_ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Sorted_Cell_ID' AND  Field_Table ='Sorted_Cell' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Sorted_Cell' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Prompt = 'Source' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Order = '2' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Source__ID' AND  Field_Table ='Sorted_Cell' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FKSortedBy_Contact__ID' AND  Field_Table ='Sorted_Cell' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FKSortedBy_Contact__ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Prompt = 'SortedBy Contact' WHERE Field_Name = 'FKSortedBy_Contact__ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'FKSortedBy_Contact__ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'FKSortedBy_Contact__ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Order = '3' WHERE Field_Name = 'FKSortedBy_Contact__ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FKSortedBy_Contact__ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FKSortedBy_Contact__ID' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FKSortedBy_Contact__ID' AND  Field_Table ='Sorted_Cell' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Sorted_Cell_Type' AND  Field_Table ='Sorted_Cell' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Sorted_Cell_Type' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Prompt = 'Type' WHERE Field_Name = 'Sorted_Cell_Type' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Sorted_Cell_Type' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Sorted_Cell_Type' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Order = '4' WHERE Field_Name = 'Sorted_Cell_Type' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Sorted_Cell_Type' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Sorted_Cell_Type' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Sorted_Cell_Type' AND  Field_Table ='Sorted_Cell' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Sorted_Cell_Condition' AND  Field_Table ='Sorted_Cell' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Sorted_Cell_Condition' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Prompt = 'Cell Condition' WHERE Field_Name = 'Sorted_Cell_Condition' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Sorted_Cell_Condition' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Sorted_Cell_Condition' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Order = '5' WHERE Field_Name = 'Sorted_Cell_Condition' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Sorted_Cell_Condition' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Sorted_Cell_Condition' AND  Field_Table ='Sorted_Cell' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Sorted_Cell_Condition' AND  Field_Table ='Sorted_Cell' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='TraceData' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Prompt = 'Run' WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='TraceData' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Run__ID' AND  Field_Table ='TraceData' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'RNA_DNA_Isolated_Date' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'RNA_DNA_Isolated_Date' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'RNA DNA Isolated Date' WHERE Field_Name = 'RNA_DNA_Isolated_Date' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'RNA_DNA_Isolated_Date' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'RNA_DNA_Isolated_Date' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '3' WHERE Field_Name = 'RNA_DNA_Isolated_Date' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'RNA_DNA_Isolated_Date' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'RNA_DNA_Isolated_Date' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'RNA_DNA_Isolated_Date' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Amount_RNA_DNA_Source_Used' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Amount_RNA_DNA_Source_Used' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'Amount RNA DNA Source Used' WHERE Field_Name = 'Amount_RNA_DNA_Source_Used' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Amount_RNA_DNA_Source_Used' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Amount_RNA_DNA_Source_Used' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '9' WHERE Field_Name = 'Amount_RNA_DNA_Source_Used' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Amount_RNA_DNA_Source_Used' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Amount_RNA_DNA_Source_Used' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Amount_RNA_DNA_Source_Used' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Amount_RNA_DNA_Source_Used_Units' AND  Field_Table ='Extraction_Details' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Amount_RNA_DNA_Source_Used_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Prompt = 'Amount RNA DNA Source Used Units' WHERE Field_Name = 'Amount_RNA_DNA_Source_Used_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Amount_RNA_DNA_Source_Used_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Amount_RNA_DNA_Source_Used_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Order = '10' WHERE Field_Name = 'Amount_RNA_DNA_Source_Used_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Amount_RNA_DNA_Source_Used_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Amount_RNA_DNA_Source_Used_Units' AND  Field_Table ='Extraction_Details' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Amount_RNA_DNA_Source_Used_Units' AND  Field_Table ='Extraction_Details' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'RNA_DNA_Extraction' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'RNA_DNA_Extraction' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'RNA DNA Extraction' WHERE Field_Name = 'RNA_DNA_Extraction' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'RNA_DNA_Extraction' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'RNA_DNA_Extraction' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '7' WHERE Field_Name = 'RNA_DNA_Extraction' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'RNA_DNA_Extraction' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'RNA_DNA_Extraction' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'RNA_DNA_Extraction' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Starting_RNA_DNA_Amnt_ng' AND  Field_Table ='SAGE_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Starting_RNA_DNA_Amnt_ng' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Prompt = 'Starting RNA DNA Amnt ng' WHERE Field_Name = 'Starting_RNA_DNA_Amnt_ng' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Starting_RNA_DNA_Amnt_ng' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Starting_RNA_DNA_Amnt_ng' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Order = '13' WHERE Field_Name = 'Starting_RNA_DNA_Amnt_ng' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Starting_RNA_DNA_Amnt_ng' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Starting_RNA_DNA_Amnt_ng' AND  Field_Table ='SAGE_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Starting_RNA_DNA_Amnt_ng' AND  Field_Table ='SAGE_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Blue_White_Selection' AND  Field_Table ='Transposon_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Blue_White_Selection' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Prompt = 'Blue White Selection' WHERE Field_Name = 'Blue_White_Selection' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'Blue_White_Selection' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Blue_White_Selection' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Order = '5' WHERE Field_Name = 'Blue_White_Selection' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Blue_White_Selection' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Blue_White_Selection' AND  Field_Table ='Transposon_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Blue_White_Selection' AND  Field_Table ='Transposon_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'PCR_Product_Library_ID' AND  Field_Table ='PCR_Product_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'PCR_Product_Library_ID' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Prompt = 'PCR Product Library ID' WHERE Field_Name = 'PCR_Product_Library_ID' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Field_Options = 'Primary' WHERE Field_Name = 'PCR_Product_Library_ID' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'PCR_Product_Library_ID' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Field_Order = '1' WHERE Field_Name = 'PCR_Product_Library_ID' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'PCR_Product_Library_ID' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'PCR_Product_Library_ID' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'PCR_Product_Library_ID' AND  Field_Table ='PCR_Product_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Library__Name' AND  Field_Table ='PCR_Product_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Library__Name' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Prompt = 'Collection' WHERE Field_Name = 'FK_Library__Name' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'FK_Library__Name' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'FK_Library__Name' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Field_Order = '2' WHERE Field_Name = 'FK_Library__Name' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Library__Name' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Library__Name' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Library__Name' AND  Field_Table ='PCR_Product_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Purification' AND  Field_Table ='PCR_Product_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Purification' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Prompt = 'Purification' WHERE Field_Name = 'Purification' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Purification' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Purification' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Field_Order = '3' WHERE Field_Name = 'Purification' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Purification' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Purification' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Purification' AND  Field_Table ='PCR_Product_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Product_Size' AND  Field_Table ='PCR_Product_Library' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Product_Size' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Prompt = 'Product Size' WHERE Field_Name = 'Product_Size' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Product_Size' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Product_Size' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Field_Order = '4' WHERE Field_Name = 'Product_Size' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Product_Size' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Product_Size' AND  Field_Table ='PCR_Product_Library' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'Product_Size' AND  Field_Table ='PCR_Product_Library' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Sex' AND  Field_Table ='Original_Source' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = 'Sex, eg. Male, Female' WHERE Field_Name = 'Sex' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Prompt = 'Sex' WHERE Field_Name = 'Sex' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Sex' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Sex' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Order = '7' WHERE Field_Name = 'Sex' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Format = '^.{0,20}$' WHERE Field_Name = 'Sex' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Sex' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Tracked = 'yes' WHERE Field_Name = 'Sex' AND  Field_Table ='Original_Source' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Strain' AND  Field_Table ='Original_Source' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'Strain' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Prompt = 'Strain' WHERE Field_Name = 'Strain' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Strain' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Strain' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Order = '9' WHERE Field_Name = 'Strain' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Format = '^.{0,40}$' WHERE Field_Name = 'Strain' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Strain' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Tracked = 'yes' WHERE Field_Name = 'Strain' AND  Field_Table ='Original_Source' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'Host' AND  Field_Table ='Original_Source' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = 'Type of Host, eg E. coli' WHERE Field_Name = 'Host' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Prompt = 'Host' WHERE Field_Name = 'Host' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Options = '' WHERE Field_Name = 'Host' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'Host' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Order = '10' WHERE Field_Name = 'Host' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'Host' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'Host' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Tracked = 'yes' WHERE Field_Name = 'Host' AND  Field_Table ='Original_Source' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Stage__ID' AND  Field_Table ='Original_Source' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = '' WHERE Field_Name = 'FK_Stage__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Prompt = 'Stage' WHERE Field_Name = 'FK_Stage__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Options = 'NewLink,Searchable' WHERE Field_Name = 'FK_Stage__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Reference = 'Stage_ID' WHERE Field_Name = 'FK_Stage__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Order = '8' WHERE Field_Name = 'FK_Stage__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Stage__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Stage__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Tracked = 'yes' WHERE Field_Name = 'FK_Stage__ID' AND  Field_Table ='Original_Source' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Tissue__ID' AND  Field_Table ='Original_Source' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = 'Select Unspecified when not applicable' WHERE Field_Name = 'FK_Tissue__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Prompt = 'Tissue' WHERE Field_Name = 'FK_Tissue__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Options = 'Mandatory,NewLink,Searchable' WHERE Field_Name = 'FK_Tissue__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Reference = 'Tissue_ID' WHERE Field_Name = 'FK_Tissue__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Order = '5' WHERE Field_Name = 'FK_Tissue__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Tissue__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Tissue__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Tracked = 'yes' WHERE Field_Name = 'FK_Tissue__ID' AND  Field_Table ='Original_Source' ;

UPDATE DBField,Package set DBField.FK_Package__ID = Package_ID WHERE Field_Name = 'FK_Taxonomy__ID' AND  Field_Table ='Original_Source' AND Package.Package_Name = 'GSC' ;
UPDATE DBField SET Field_Description = 'Autocomplete will search for full or partial genus or species names, or NCBI taxonomy ID number. If type is mixed or unknown, enter "unidentified -"' WHERE Field_Name = 'FK_Taxonomy__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Prompt = 'Taxonomy' WHERE Field_Name = 'FK_Taxonomy__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Name = 'FK_Taxonomy__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Reference = '' WHERE Field_Name = 'FK_Taxonomy__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Order = '5' WHERE Field_Name = 'FK_Taxonomy__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Field_Format = '' WHERE Field_Name = 'FK_Taxonomy__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Editable = 'yes' WHERE Field_Name = 'FK_Taxonomy__ID' AND  Field_Table ='Original_Source' ;
UPDATE DBField SET Tracked = 'no' WHERE Field_Name = 'FK_Taxonomy__ID' AND  Field_Table ='Original_Source' ;

 
</FINAL> 
