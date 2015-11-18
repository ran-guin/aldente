## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Original_Source DROP FK_Tissue__ID;
DROP TABLE Tumour;
ALTER TABLE SequenceRun DROP FK_Chemistry_Code__Name;

ALTER TABLE Original_Source MODIFY Original_Source_Type  enum('Bacteria','Bodily_Fluid','Cell_Line','Exfoliate','Fungi','Invertebrate','Metagenomic','Mixed','Non_Biological','Plant','Solid_Tissue(Vertebrate)','Stem_Cell','Synthetic','Virus') DEFAULT NULL;

ALTER TABLE Anatomic_Site MODIFY Anatomic_Site_Type enum('Bacteria','Bodily_Fluid','Exfoliate','Fungi','Invertebrate','Metagenomic','Mixed','Plant','Solid_Tissue(Vertebrate)','Stem_Cell','Synthetic','Virus')  DEFAULT NULL;


ALTER TABLE Source ADD Current_Concentration float DEFAULT NULL;
ALTER TABLE Source ADD Current_Concentration_Units enum('cfu','pg/uL','ng/ul','ug/ul','nM','pM') DEFAULT NULL;
ALTER TABLE Source ADD Current_Concentration_Measured_by ENUM('External','External-Bioanalyzer','External-Nanodrop','External-Qubit','External-Picogreen','Internal-Nanodrop','Internal-Qubit','Internal-Picogreen','Internal') DEFAULT NULL;


CREATE TABLE `Submission_Attribute` (
  `Submission_Attribute_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_Submission__ID` int(11) NOT NULL DEFAULT '0',
  `FK_Attribute__ID` int(11) NOT NULL DEFAULT '0',
  `Attribute_Value` text NOT NULL,
  `FK_Employee__ID` int(11) DEFAULT NULL,
  `Set_DateTime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`Submission_Attribute_ID`),
  UNIQUE KEY `source_attribute` (`FK_Submission__ID`,`FK_Attribute__ID`),
  KEY `FK_Submission__ID` (`FK_Submission__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `Set_DateTime` (`Set_DateTime`)
);



</SCHEMA> 
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

INSERT INTO Anatomic_Site VALUES ('','Not Applicable Synthetic',0,'Not Applicable Synthetic','Synthetic','yes');

UPDATE  Source, Source_Attribute , Attribute SET Current_Concentration = Attribute_Value  WHERE FK_Source__ID = Source_ID AND FK_Attribute__ID = Attribute_ID AND Attribute_Name = 'Current_Concentration' and Current_Concentration IS NULL;
UPDATE  Source, Source_Attribute , Attribute SET Current_Concentration_Units = Attribute_Value  WHERE FK_Source__ID = Source_ID AND FK_Attribute__ID = Attribute_ID AND Attribute_Name = 'Current_Concentration_Units' and Current_Concentration_Units IS NULL;
UPDATE  Source, Source_Attribute , Attribute SET Current_Concentration_Measured_by = Attribute_Value  WHERE FK_Source__ID = Source_ID AND FK_Attribute__ID = Attribute_ID AND Attribute_Name = 'Current_Concentration_Measured_by' and Current_Concentration_Measured_by IS NULL;

delete Source_Attribute  from Attribute, Source_Attribute WHERE Attribute_ID = FK_Attribute__ID and Attribute_Name IN ('Current_Concentration','Current_Concentration_Units','Current_Concentration_Measured_by') AND Attribute_Class = 'Source';
delete  from Attribute  WHERE Attribute_Name IN ('Current_Concentration','Current_Concentration_Units','Current_Concentration_Measured_by') AND Attribute_Class = 'Source';


INSERT INTO Attribute VALUES ('','CDG_Batch_Identifier','','text',23,'No','Submission','Editable','');
INSERT INTO Submission_Attribute (select '',3975,Attribute_ID,'GSC116',331,NOW() from Attribute WHERE Attribute_Name= 'CDG_Batch_Identifier');
INSERT INTO Submission_Attribute (select '',3987,Attribute_ID,'GSC117',331,NOW() from Attribute WHERE Attribute_Name= 'CDG_Batch_Identifier');
INSERT INTO Submission_Attribute (select '',3999,Attribute_ID,'GSC118',331,NOW() from Attribute WHERE Attribute_Name= 'CDG_Batch_Identifier');
INSERT INTO Submission_Attribute (select '',4008,Attribute_ID,'GSC119',331,NOW() from Attribute WHERE Attribute_Name= 'CDG_Batch_Identifier');
INSERT INTO Submission_Attribute (select '',4012,Attribute_ID,'GSC120',331,NOW() from Attribute WHERE Attribute_Name= 'CDG_Batch_Identifier');
INSERT Object_Class VALUES ('','Submission','');


</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>

 