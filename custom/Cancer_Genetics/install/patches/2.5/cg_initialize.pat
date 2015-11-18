<SCHEMA>

#################################
## Build lookup table for patient
## Table name: Patient
## Fields: Patient_ID, Sex, Birthdate, Identifier, Contact
#################################
# Drop the table if it exists pre-installation
DROP TABLE if exists Patient;


## Create the patient table
CREATE TABLE Patient(FK_Library__Name VARCHAR(30) NOT NULL, Patient_ID INT NOT NULL AUTO_INCREMENT primary key, Patient_Birthdate date NOT NULL, Patient_Identifier varchar(30) NOT NULL, Patient_Sex enum('Male','Female'));
## Customize Employee table for Cancer Genetics LIMS

ALTER TABLE Employee change Department Department enum('Administration','Receiving','Cancer Genetics','None');
## Customize equipment table for

ALTER TABLE Equipment CHANGE Equipment_Type Equipment_Type enum('','Centrifuge','Freezer','Printer','Pipette','Storage');

ALTER TABLE Equipment CHANGE Equipment_Location Equipment_Location enum('','BCCRC','Life Labs','BC Bio','VCC');

# ALTER TABLE Original_Source ADD Column FK_Patient__ID int not null;

ALTER TABLE Plate_Format CHANGE Well_Lookup_Key Well_Lookup_Key enum('Tube');

ALTER TABLE Plate_Format CHANGE Plate_Format_Style Plate_Format_Style enum('Tube');

ALTER TABLE Plate CHANGE COLUMN Plate_Application Plate_Application enum('Lymphocyte Storage','DNA Extraction','Plasma Processing','Serum Processing','PHA Testing');

ALTER TABLE Plate CHANGE COLUMN Plate_Type Plate_Type enum('Tube','Vial');

ALTER TABLE Plate CHANGE COLUMN Plate_Content_Type Plate_Content_Type enum('DNA','Lymphocytes','Blood','Plasma','Serum','Saliva','Clone','Urine');

ALTER TABLE Plate CHANGE COLUMN Plate_Size Plate_Size enum('1.5 mL','50 mL','15 mL','5 mL','2 mL','0.5 mL','0.2 mL');

ALTER TABLE Plate CHANGE COLUMN Plate_Status Plate_Status enum('Active','Inactive','Thrown Out','Contaminated','Exported','On Hold','Archived');

#ALTER TABLE Plate ADD COLUMN Comments TEXT;

# ALTER TABLE Sample CHANGE COLUMN Sample_Type Sample_Type enum('Blood','Plasma','Serum','DNA','Lymphocytes');

ALTER TABLE Extraction_Sample CHANGE Extraction_Sample_Type Extraction_Sample_Type enum('Blood','Saliva','Clone','DNA','Lymphocytes','Plasma','Serum','Urine');

ALTER TABLE Sample ADD FKOriginal_Plate__ID int(11) not null;
ALTER TABLE Sample ADD Original_Well char(3);
ALTER TABLE Sample ADD FK_Library__Name varchar(8);
ALTER TABLE Sample ADD Plate_Number int(11);
ALTER TABLE Sample ADD FK_Sample_Type__ID int(11) not null;
ALTER TABLE Sample ADD Sample_Source enum('Original','Extraction','Clone');

ALTER TABLE Source CHANGE COLUMN Received_Date Received_Date DATETIME;

ALTER TABLE Source change Source_Type Source_Type enum('Blood','DNA','Lymphocytes','Plasma','Saliva','Serum','Urine');
ALTER TABLE Source CHANGE COLUMN Source_Status Source_Status enum('Active','Inelligible','Thrown Out','Inactive');

ALTER TABLE Source CHANGE COLUMN Amount_Units Amount_Units enum('','ml','ul','ug','ng','pg');

#add column for collected datetime
ALTER TABLE Source ADD Collected_Date date not null;
ALTER TABLE Source ADD Collected_Time time;

## Change table to reference patient_table instead of original_source
# ALTER TABLE Source Drop FK_Patient__ID;
ALTER TABLE Source ADD FK_Patient__ID int;

ALTER TABLE Source CHANGE COLUMN Received_Date Received_Date DATETIME;

ALTER TABLE Source change Source_Type Source_Type enum('Blood','DNA','Lymphocytes','Plasma','Saliva','Serum','Urine');
ALTER TABLE Source CHANGE COLUMN Source_Status Source_Status enum('Active','Inelligible','Thrown Out','Inactive');

ALTER TABLE Source CHANGE COLUMN Amount_Units Amount_Units enum('','ml','ul','ug','ng','pg');

#add column for collected datetime
ALTER TABLE Source DROP Collected_Date;
ALTER TABLE Source DROP Collected_Time;
ALTER TABLE Source ADD Collected_Date date;
ALTER TABLE Source ADD Collected_Time time;

## Change table to reference patient_table instead of original_source
# ALTER TABLE Source Drop FK_Patient__ID;
ALTER TABLE Source ADD FK_Patient__ID int;

</SCHEMA>
<DATA>
################################
## Change 'Lab' record in Department table to 'Cancer Genetics'
################################
UPDATE Department SET Department_Name = 'Cancer Genetics' WHERE Department_Name = 'Lab';
DELETE FROM Department WHERE Department_Name = 'Cancer Genetics';
INSERT INTO Department SET Department_ID='3',Department_Name = 'Cancer Genetics', Department_Status='Active';

# INSERT INTO Grp SET Grp_Name = 'Cancer Genetics',FK_Department__ID=(SELECT Department_ID FROM Department WHERE Department_Name = 'Cancer Genetics'),Access='Lab';
## customize barcode labels for cancer genetics department

DELETE FROM Barcode_Label WHERE Label_Descriptive_Name NOT IN ('1D Large Solution/Box/Kit Labels','1D Equipment Labels','Employee Barcode','1D Chemistry Label','1D Small Solution Labels','Simple Small Label','1D Small Equipment Labels','2D Tube Labels','2D Tube Solution Labels','Simple Tube Label','2D simple tube labels','Large Custom Label','1D Large Plain Label','Large Procedure Label','Simple Large Label','No Barcode');

INSERT INTO Barcode_Label SET Barcode_Label_Name = 'cg_tube_2D',Label_Height=0.75,Label_Width=1.7,Zero_X=25,Zero_Y=25,Top=15,FK_Setting__ID=4,Label_Descriptive_Name = '2D cancer genetics tube',Barcode_Label_Type='plate',FK_Label_Format__ID=4;

UPDATE Barcode_Label SET Barcode_Label_Status = 'Inactive' WHERE Barcode_Label_Name IN ('custom_2D_tube','ge_tube_barcode_2D','agar_plate','gelpour_barcode_1D','microarray','seqnightcult','seqnightcult_s','seqnightcult_smult','seqnightcult_mult');

UPDATE Plate_Format SET FK_Barcode_Label__ID = (SELECT Barcode_Label_ID FROM Barcode_Label WHERE Barcode_Label_Name = 'cg_tube_2D');
## Add default organization and contact, the GSC and LIMS, respectively

# Add organization
#INSERT INTO Organization SET Organization_Name = 'GSC',Organization_Type = 'Collaborator';

# Add contact
#INSERT INTO Contact SET Contact_Name = 'Colin Hilchey', Contact_Email = 'chilchey@bcgsc.ca', FK_Organization__ID = (SELECT Organization_ID FROM Organization WHERE Organization_Name = 'GSC');
DELETE FROM DB_Form WHERE Form_Table = 'Plate' AND Form_Order='3';
DELETE FROM DB_Form WHERE Form_Table = 'Library_Source' AND Form_Order = '2';
DELETE FROM DB_Form WHERE Form_Table = 'Tube' AND Form_Order = '4';

UPDATE DB_Form SET FKParent_DB_Form__ID = '21' WHERE DB_Form_ID = '6';

INSERT INTO DB_Form SET Form_Table = 'Library_Source',Form_Order='2',Min_Records = '1',Max_Records='1',FKParent_DB_Form__ID = '21',Parent_Field = NULL,Parent_Value=NULL,Finish=0,Class=NULL;

# INSERT INTO DB_Form SET Form_Table = 'Tube',Form_Order='2',Min_Records='2',Max_Records='1',FKParent_DB_Form__ID = ### ,Parent_Field='Plate_Type',Parent_Value='Tube',Finish=0,Class=NULL;
## INSERT Default records for Cancer Genetics Department
## i.e. Default Library, Project

################################
## Change 'Lab' record in Department table to 'Cancer Genetics'
################################
# DELETE FROM Department WHERE Department_Name = 'Cancer Genetics';
UPDATE Department SET Department_Name = 'Cancer Genetics' WHERE Department_Name = 'Lab';


## Default Project
DELETE FROM Project;
INSERT INTO Project SET Project_Name = 'BC Biobank',Project_Description = 'Blood, Serum, Plasma, and Saliva testing/processing in the BCCRC Cancer Genetics group',Project_Initiated='2008-06-11',Project_Status='Active';

# Original Source
DELETE FROM Original_Source;
INSERT INTO Original_Source SET Original_Source_ID=1,Original_Source_Name = 'CG0S01',FKCreated_Employee__ID=1,Sample_Available='Yes',Defined_Date='2008-06-25';

# Default Library
DELETE FROM Library;

INSERT INTO Library SET FK_Project__ID = (SELECT Project_ID FROM Project WHERE Project_Name = 'BC Biobank' LIMIT 1),Library_Name = 'LIB01',Library_FullName = 'Default Cancer Genetics Library',Library_Status='In Production',Library_Type = 'Normal',Library_Description = 'Default collection of cancer patient samples',FK_Contact__ID='1',FKCreated_Employee__ID='1',FK_Grp__ID = (SELECT Grp_ID FROM Grp WHERE Grp_Name = 'Lab' LIMIT 1),FK_Original_Source__ID=(SELECT Original_Source_ID FROM Original_Source limit 1),Library_Obtained_Date = '2008-07-07';

## Not sure whether these records should be available
INSERT INTO Library SET Library_Type='Normal',Library_Obtained_Date='2008-07-07',Library_Name='IHOP08',Library_Description='Collection for samples given by patients on yearly basis',FK_Project__ID=4,Library_FullName='IHOP Sample Collection',Library_Status='In Production',FK_Contact__ID=1,FKCreated_Employee__ID=1,FK_Grp__ID=3,FK_Original_Source__ID=1,Starting_Plate_Number=1,Source_In_House='No',FKParent_Library__Name='LIB01';

INSERT INTO Library SET Library_Type='Normal',Library_Obtained_Date='2008-07-07',Library_Name='CGBC08',Library_Description='Collection for samples given on a one-time basis',FK_Project__ID=4,Library_FullName='BioBank Cohort Samples',Library_Status='In Production',FK_Contact__ID=1,FKCreated_Employee__ID=1,FK_Grp__ID=3,FK_Original_Source__ID=1,Starting_Plate_Number=1,Source_In_House='No',FKParent_Library__Name='LIB01';

INSERT INTO Library SET Library_Type='Normal',Library_Obtained_Date='2008-07-07',Library_Name='CGBM08',Library_Description='Biomarkers Study',FK_Project__ID=4,Library_FullName='Biomarkers Samples 2008',Library_Status='In Production',FK_Contact__ID=1,FKCreated_Employee__ID=1,FK_Grp__ID=3,FK_Original_Source__ID=1,Starting_Plate_Number=1,Source_In_House='No',FKParent_Library__Name='LIB01';

# Default Maintenance_Process_Types
INSERT INTO Maintenance_Process_Type SET Process_Type_Name = 'Inventory', Process_Type_Description = 'Inventory of equipment storage';

# Default Pipeline
INSERT INTO Pipeline SET Pipeline_Name = 'Cancer Genetics Default Pipeline',FK_Grp__ID = (SELECT Grp_ID FROM Grp WHERE Grp_Name = 'Lab' LIMIT 1),Pipeline_Description='Standard Pipeline for Cancer Genetics Department',Pipeline_Code='CG1',Pipeline_Status='Active';

# Default Pipeline_Step

# INSERT INTO Pipeline_Step SET FK_Object_Class__ID = 5, Object_ID = 1,

# Add plate attributes

INSERT INTO Attribute SET Attribute_Name = 'DNA Concentration', Attribute_Format=NULL,Attribute_Type='Text',FK_Grp__ID = (SELECT Grp_ID FROM Grp WHERE Grp_Name = 'Lab'), Inherited = 'Yes',Attribute_Class='Plate';

INSERT INTO Attribute SET Attribute_Name = 'Volume of DNA resuspended', Attribute_Format=NULL,Attribute_Type='Text',FK_Grp__ID = (SELECT Grp_ID FROM Grp WHERE Grp_Name = 'Lab'), Inherited = 'Yes',Attribute_Class='Plate';

INSERT INTO Attribute SET Attribute_Name = 'Number of Lymphocytes', Attribute_Format=NULL,Attribute_Type='Text',FK_Grp__ID = (SELECT Grp_ID FROM Grp WHERE Grp_Name = 'Lab'),Inherited = 'Yes',Attribute_Class='Plate';

INSERT INTO Attribute SET Attribute_Name = 'Sample status', Attribute_Format=NULL,Attribute_Type='enum(\'Fresh\',\'Frozen\')',FK_Grp__ID = (SELECT Grp_ID FROM Grp WHERE Grp_Name = 'Lab'),Inherited = 'Yes',Attribute_Class='Plate';

INSERT INTO Attribute SET Attribute_Name = 'External lab',Attribute_Format=NULL,Attribute_Type='text',FK_Grp__ID = (SELECT Grp_ID FROM Grp WHERE Grp_Name = 'Lab'),Inherited = 'No',Attribute_Class = 'Prep';

INSERT INTO Attribute SET Attribute_Name = 'Blood type',Attribute_Format=NULL,Attribute_Type='text',FK_Grp__ID = (SELECT Grp_ID FROM Grp WHERE Grp_Name = 'Lab'),Inherited = 'Yes',Attribute_Class='Source';

# Default organizations (GSC record is added in different mysql file)
INSERT INTO Organization SET Organization_Name = 'LIMS', Organization_Type ='Collaborator',Organization_FullName='LIMS at GSC';

# Default Stock item

# INSERT INTO Stock SET Stock_Name = 'Virtual Storage',Stock_Source='Made in House',Stock_Type='Equipment',Stock_Size='1',Stock_Size_Units='n/a',Stock_Received='2008-06-20',Stock_Number_in_Batch='5',FK_Grp__ID=(Select Grp_ID FROM Grp WHERE Grp_Name='Lab'),FK_Barcode_Label__ID='1',FK_Employee__ID='1';

# INSERT INTO Stock SET Stock_Name = 'Default Freezer',Stock_Source='Made in House',Stock_Type='Equipment',Stock_Size='1',Stock_Size_Units='n/a',Stock_Received='2008-06-20',Stock_Number_in_Batch='1',FK_Grp__ID=(Select Grp_ID FROM Grp WHERE Grp_Name='Lab'),FK_Barcode_Label__ID='1';

# Update equipment

# UPDATE Equipment SET FK_Stock__ID = (SELECT Stock_ID FROM Stock WHERE Stock__ID

# Default Protocols

INSERT INTO Lab_Protocol SET FK_Employee__ID = 1, Lab_Protocol_Name = 'PHA Assay testing',Lab_Protocol_Status = 'Active',Lab_Protocol_VersionDate = '2008-06-24';

INSERT INTO GrpLab_Protocol SET FK_Grp__ID=3,FK_Lab_Protocol__ID = (SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'PHA Assay testing');

INSERT INTO Lab_Protocol SET FK_Employee__ID = 1,Lab_Protocol_Name = 'Serum processing',Lab_Protocol_Status = 'Active',Lab_Protocol_Description = 'Process blood to obtain serum',Lab_Protocol_VersionDate = '2008-06-24';

INSERT INTO GrpLab_Protocol SET FK_Grp__ID=3,FK_Lab_Protocol__ID = (SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'Serum processing');

INSERT INTO Lab_Protocol SET FK_Employee__ID = 1,Lab_Protocol_Name = 'Plasma processing',Lab_Protocol_Status = 'Active',Lab_Protocol_Description = 'Process blood for plasma',Lab_Protocol_VersionDate = '2008-06-24';

INSERT INTO GrpLab_Protocol SET FK_Grp__ID=3,FK_Lab_Protocol__ID = (SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'Plasma processing');

INSERT INTO Lab_Protocol SET FK_Employee__ID = 1,Lab_Protocol_Name = 'Lymphocyte Extraction',Lab_Protocol_Status = 'Active',Lab_Protocol_Description = 'Lymphocyte extraction from blood sample',Lab_Protocol_VersionDate = '2008-06-24';

INSERT INTO GrpLab_Protocol SET FK_Grp__ID=3,FK_Lab_Protocol__ID = (SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'Lymphocyte Extraction');

INSERT INTO Lab_Protocol SET FK_Employee__ID = 1,Lab_Protocol_Name = 'DNA Extraction',Lab_Protocol_Status = 'Active',Lab_Protocol_Description = 'Extract DNA from blood sample',Lab_Protocol_VersionDate = '2008-06-24';

INSERT INTO GrpLab_Protocol SET FK_Grp__ID=3,FK_Lab_Protocol__ID = (SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'DNA Extraction');

## Protocol steps for each Lab_Protocol

INSERT INTO Protocol_Step SET FK_Employee__ID = 1,Protocol_Step_Number = 1,Protocol_Step_Name = 'PHA Assay testing',Scanner=1,FK_Lab_Protocol__ID = (SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'PHA Assay testing'),Protocol_Step_Instructions = 'Export to PHA testing lab';

INSERT INTO Protocol_Step SET FK_Employee__ID = 1,Protocol_Step_Number = 1,Protocol_Step_Name = 'Extract Serum to Tube  (Track New Sample)',Scanner=1,FK_Lab_Protocol__ID=(SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'Serum processing'),Protocol_Step_Instructions = 'Extract serum from blood',Protocol_Step_Changed='2008-07-24';

INSERT INTO Protocol_Step SET FK_Employee__ID = 1,Protocol_Step_Number = 1,Protocol_Step_Name = 'Extract Plasma to Tube  (Track New Sample)',Scanner=1,FK_Lab_Protocol__ID=(SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'Plasma processing'),Protocol_Step_Instructions = 'Extract Plasma from Blood',ProtocoL_Step_Changed='2008-07-24';

INSERT INTO Protocol_Step SET FK_Employee__ID = 1,Protocol_Step_Number = 1,Protocol_Step_Name = 'Extract Lymphocytes to Tube  (Track New Sample)',Scanner=1,FK_Lab_Protocol__ID=(SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'Lymphocyte Extraction'), Protocol_Step_Changed='2008-06-24';

INSERT INTO Protocol_Step SET FK_Employee__ID = 1,Protocol_Step_Number = 2,Protocol_Step_Name = 'Record lymphocyte data',Scanner=1,FK_Lab_Protocol__ID=(SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'Lymphocyte Extraction'), Protocol_Step_Changed='2008-06-24',Input='Plate_Attribute=Number of Lymphocytes';

INSERT INTO Protocol_Step SET FK_Employee__ID = 1,Protocol_Step_Number=1,Protocol_Step_Name = 'Record sample status',Scanner=1,FK_Lab_Protocol__ID = (SELECT Lab_ProtocoL_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'DNA Extraction'),Protocol_Step_Changed='2008-06-24',Input='Plate_Attribute=Sample status';

INSERT INTO Protocol_Step SET FK_Employee__ID = 1,Protocol_Step_Number = 2,Protocol_Step_Name = 'Extract DNA to Tube  (Track New Sample)',Scanner=1,FK_Lab_Protocol__ID=(SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'DNA Extraction'), Protocol_Step_Changed='2008-06-24';

INSERT INTO Protocol_Step SET FK_Employee__ID = 1,Protocol_Step_Number = 3,Protocol_Step_Name = 'Record DNA data',Scanner=1,FK_Lab_Protocol__ID=(SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'DNA Extraction'), Protocol_Step_Changed='2008-06-24',Input='Plate_Attribute=DNA Concentration:Plate_Attribute=Volume of DNA resuspended';

INSERT INTO Protocol_Step SET FK_Employee__ID = 1,Protocol_Step_Number = 1,Protocol_Step_Name = 'Move to -80 degrees',Protocol_Step_Changed='2008-07-24', FK_Lab_Protocol__ID = (SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'Standard');

INSERT INTO Protocol_Step SET FK_Employee__ID = 1,Protocol_Step_Number = 1,Protocol_Step_Name = 'Move to +4 degrees',Protocol_Step_Changed='2008-07-24', FK_Lab_Protocol__ID = (SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'Standard');

INSERT INTO Protocol_Step SET FK_Employee__ID = 1,Protocol_Step_Number = 1,Protocol_Step_Name = 'Move to -40 degrees',Protocol_Step_Changed='2008-07-24', FK_Lab_Protocol__ID = (SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'Standard');

INSERT INTO Protocol_Step SET FK_Employee__ID = 1,Protocol_Step_Number = 1,Protocol_Step_Name = 'Move to -20 degrees',Protocol_Step_Changed='2008-07-24', FK_Lab_Protocol__ID = (SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'Standard');

INSERT INTO Protocol_Step SET FK_Employee__ID = 1,Protocol_Step_Number = 1,Protocol_Step_Name = 'Move to Room Temperature',Protocol_Step_Changed='2008-07-24', FK_Lab_Protocol__ID = (SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'Standard');

INSERT INTO Protocol_Step SET FK_Employee__ID = 1,Protocol_Step_Number = 1,Protocol_Step_Name = 'Move to Variable Conditions',Protocol_Step_Changed='2008-07-24', FK_Lab_Protocol__ID = (SELECT Lab_Protocol_ID FROM Lab_Protocol WHERE Lab_Protocol_Name = 'Standard');
## Adds freezers and racks to database

INSERT INTO Stock SET Stock_Name = 'Freezer -80 degrees', FK_Employee__ID=1, Stock_Received='2008-07-25',Stock_Size=1,Stock_Size_Units='n/a',Stock_Type='Equipment',Stock_Number_in_Batch=4,Stock_Source='Order',FK_Grp__ID=3,FK_Barcode_Label__ID=(SELECT Barcode_Label_ID FROM Barcode_Label WHERE Label_Descriptive_Name='1D Equipment Labels'),FK_Organization__ID=2;

INSERT INTO Equipment SET Equipment_Name = 'F1',Equipment_Type='Freezer',Equipment_Number='1',Equipment_Number_in_Batch='4',Equipment_Status='In Use',FK_Location__ID=(SELECT Location_ID FROM Location WHERE Location_Name='Lab'),Equipment_Condition='-80 degrees',FK_Stock__ID=(SELECT Stock_ID FROM Stock WHERE Stock_Name='Freezer -80 degrees'),Model='Laboratory Freezer',Serial_Number='12345678';

INSERT INTO Equipment SET Equipment_Name = 'F2',Equipment_Type='Freezer',Equipment_Number='2',Equipment_Number_in_Batch='4',Equipment_Status='In Use',FK_Location__ID=(SELECT Location_ID FROM Location WHERE Location_Name='Lab'),Equipment_Condition='-80 degrees',FK_Stock__ID=(SELECT Stock_ID FROM Stock WHERE Stock_Name='Freezer -80 degrees'),Model='Laboratory Freezer',Serial_Number='12345678';

INSERT INTO Equipment SET Equipment_Name = 'F3',Equipment_Type='Freezer',Equipment_Number='3',Equipment_Number_in_Batch='4',Equipment_Status='In Use',FK_Location__ID=(SELECT Location_ID FROM Location WHERE Location_Name='Lab'),Equipment_Condition='-80 degrees',FK_Stock__ID=(SELECT Stock_ID FROM Stock WHERE Stock_Name='Freezer -80 degrees'),Model='Laboratory Freezer',Serial_Number='12345678';

INSERT INTO Equipment SET Equipment_Name = 'F4',Equipment_Type='Freezer',Equipment_Number='4',Equipment_Number_in_Batch='4',Equipment_Status='In Use',FK_Location__ID=(SELECT Location_ID FROM Location WHERE Location_Name='Lab'),Equipment_Condition='-80 degrees',FK_Stock__ID=(SELECT Stock_ID FROM Stock WHERE Stock_Name='Freezer -80 degrees'),Model='Laboratory Freezer',Serial_Number='12345678';
INSERT INTO Location (Location_Name, Location_Status) VALUES ('CRC 7th Floor Cancer Genetics Lab','active');
## Cleans the Plate_Format table to include only generic tube formats

DELETE FROM Plate_Format WHERE Plate_Format_Type NOT LIKE 'Tube';

# DELETE FROM Plate_Format WHERE Capacity = NULL;

## Alterations to plate table for Cancer Genetics group

DELETE FROM Plate;
## Sets a default printer

## Customize printer group

UPDATE Printer_Group SET Printer_Group_Name = 'Cancer Genetics Printers' WHERE Printer_Group_Name = 'Default Printer Group';

## insert a printer for each format
#DELETE FROM Printer;

## Location for test printer

INSERT INTO Location SET Location_Name = 'Echelon 6th floor Sequencing Lab', Location_Status = 'active';

## Equipment Barcode Printer

#INSERT INTO Stock SET Stock_Name = 'Equipment Barcode Printer',Stock_Number_in_Batch=1,Stock_Received='2008-08-01',Stock_Size = 1,Stock_Size_Units = 'pcs',Stock_Source='Made in House',Stock_Type='Equipment',FK_Grp__ID=3,FK_Employee__ID=1,FK_Barcode_Label__ID=(SELECT Barcode_Label_ID FROM Barcode_Label WHERE Barcode_Label_Name='barcode1';

#INSERT INTO Equipment SET Equipment_Name = 'Equipment Barcodes',Equipment_Type = 'Printer',Model='Temp for testing',Serial_Number='12345678',Equipment_Status = 'In Use',Equipment_Location='Room Temperature',FK_Stock__ID = (SELECT Stock_ID FROM Stock WHERE Stock_Name = 'Equipment Barcode Printer'),FK_Location__ID= (SELECT Location_ID FROM Location WHERE Location_Name = 'Echelon 6th floor Sequencing Lab');

#INSERT INTO Printer SET Printer_Name = 'polyhymnia', Printer_DPI = '300', Printer_Location = 'Sequencing Lab 6th Floor (Laser)',Printer_Type = 'LASER_PRINTER',Printer_Address='polyhymnia',Printer_Output='OFF',FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'LASER_PRINTER');
INSERT INTO Printer SET Printer_Name = 'z4m-1', Printer_DPI = '300', Printer_Location = 'GE Lab 5th Floor',Printer_Type = 'LARGE_LABEL_PRINTER',Printer_Address='z4m-1',Printer_Output='OFF',FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'LARGE_LABEL_PRINTER'),FK_Equipment__ID = (SELECT Equipment_ID FROM Equipment WHERE Equipment_Name = 'Equipment Barcodes');


#INSERT INTO Printer SET Printer_Name = 'orbita', Printer_DPI = '200', Printer_Location = 'Sequencing Lab 6th Floor',Printer_Type = 'CHEMISTRY_PRINTER',Printer_Address='orbita',Printer_Output='OFF',FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'CHEMISTRY_PRINTER');


#INSERT INTO Stock SET Stock_Name='Small Barcode Printer',FK_Employee__ID=1,Stock_Size=1,Stock_Size_Units='pcs',Stock_Type='Equipment',Stock_Number_in_Batch=1,FK_Organization__ID=2,Stock_Source='Made in House',FK_Grp__ID=3,FK_Barcode_Label__ID=10;

#INSERT INTO Equipment SET Equipment_Name='Printer3 (Small equipment barcodes)',Equipment_Type='Printer',Model='Temp for testing',Serial_Number='12345678',FK_Stock__ID=(SELECT Stock_ID FROM Stock WHERE Stock_Name='Small Barcode Printer'),Equipment_Status='In Use',FK_Location__ID=2;

#INSERT INTO Printer SET Printer_Name = 'saturnia', Printer_DPI = '200', Printer_Location = 'Sequencing Lab 6th Floor (small)',Printer_Type = 'SMALL_LABEL_PRINTER',Printer_Address='saturnia',Printer_Output='OFF',FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'SMALL_LABEL_PRINTER'),FK_Equipment__ID=(SELECT Equipment_ID FROM Equipment WHERE Equipment_Name='Printer3 (Small equipment barcodes)');

#INSERT INTO Stock SET Stock_Name = 'Tube Barcode Printer',Stock_Number_in_Batch=1,Stock_Received='2008-08-01',Stock_Size = 1,Stock_Size_Units = 'pcs',Stock_Source='Made in House',Stock_Type='Equipment';

#INSERT INTO Equipment SET Equipment_Name = 'Tube Barcode Printer',Equipment_Type = 'Printer',Model='Temp for testing',Serial_Number='12345678',Equipment_Status = 'In Use',Equipment_Condition='Room Temperature',FK_Stock__ID = (SELECT Stock_ID FROM Stock WHERE Stock_Name = 'Tube Barcode Printer'),FK_Location__ID = (SELECT Location_ID FROM Location WHERE Location_Name = 'Echelon 6th floor Sequencing Lab');

#INSERT INTO Printer SET Printer_Name = 'z4m-2', Printer_DPI = '300', Printer_Location = 'GE Lab 6th Floor',Printer_Type = '2D_BARCODE_PRINTER',Printer_Address='z4m-2',Printer_Output='OFF',FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = '2D_BARCODE_PRINTER'),FK_Equipment__ID=(SELECT Equipment_ID FROM Equipment WHERE Equipment_Name = 'Tube Barcode Printer');

#INSERT INTO Printer SET Printer_Name = 'polyhymnia', Printer_DPI = '300', Printer_Location = 'Sequencing Lab 6th Floor (Laser)',Printer_Type = 'LASER_PRINTER',Printer_Address='polyhymnia',Printer_Output='OFF',FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'LASER_PRINTER');

## Sets Printer Assignment for Cancer Genetics

#DELETE FROM Printer_Assignment;
#INSERT INTO Printer_Assignment SET FK_Printer_Group__ID = (SELECT Printer_Group_ID FROM Printer_Group WHERE Printer_Group_Name = 'Cancer Genetics Printers'), FK_Printer__ID = (SELECT Printer_ID FROM Printer WHERE Printer_Name = 'z4m-1'), FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'LARGE_LABEL_PRINTER');

#INSERT INTO Printer_Assignment SET FK_Printer_Group__ID = (SELECT Printer_Group_ID FROM Printer_Group WHERE Printer_Group_Name = 'Cancer Genetics Printers'), FK_Printer__ID = (SELECT Printer_ID FROM Printer WHERE Printer_Name = 'orbita'), FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'CHEMISTRY_PRINTER');

#INSERT INTO Printer_Assignment SET FK_Printer_Group__ID = (SELECT Printer_Group_ID FROM Printer_Group WHERE Printer_Group_Name = 'Cancer Genetics Printers'), FK_Printer__ID = (SELECT Printer_ID FROM Printer WHERE Printer_Name = 'z4m-3'), FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'SMALL_LABEL_PRINTER');

#INSERT INTO Printer_Assignment SET FK_Printer_Group__ID = (SELECT Printer_Group_ID FROM Printer_Group WHERE Printer_Group_Name = 'Cancer Genetics Printers'), FK_Printer__ID = (SELECT Printer_ID FROM Printer WHERE Printer_Name = 'z4m-2'), FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = '2D_BARCODE_PRINTER');

#INSERT INTO Printer_Assignment SET FK_Printer_Group__ID = (SELECT Printer_Group_ID FROM Printer_Group WHERE Printer_Group_Name = 'Cancer Genetics Printers'), FK_Printer__ID = (SELECT Printer_ID FROM Printer WHERE Printer_Name = 'polyhymnia'), FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'LASER_PRINTER');
## Sets a default printer

## Customize printer group

UPDATE Printer_Group SET Printer_Group_Name = 'Cancer Genetics Printers' WHERE Printer_Group_Name = 'Default Printer Group';

## insert a printer for each format
DELETE FROM Printer;

## Location for test printer

INSERT INTO Location SET Location_Name = 'Echelon 6th floor Sequencing Lab', Location_Status = 'active';

## Equipment Barcode Printer

INSERT INTO Stock SET Stock_Name = 'Equipment Barcode Printer',Stock_Number_in_Batch=1,Stock_Received='2008-08-01',Stock_Size = 1,Stock_Size_Units = 'pcs',Stock_Source='Made in House',Stock_Type='Equipment',FK_Grp__ID=3,FK_Employee__ID=1,FK_Barcode_Label__ID=(SELECT Barcode_Label_ID FROM Barcode_Label WHERE Barcode_Label_Name='barcode1';

INSERT INTO Equipment SET Equipment_Name = 'Equipment Barcodes',Equipment_Type = 'Printer',Model='Temp for testing',Serial_Number='12345678',Equipment_Status = 'In Use',Equipment_Location='Room Temperature',FK_Stock__ID = (SELECT Stock_ID FROM Stock WHERE Stock_Name = 'Equipment Barcode Printer'),FK_Location__ID= (SELECT Location_ID FROM Location WHERE Location_Name = 'Echelon 6th floor Sequencing Lab');

INSERT INTO Printer SET Printer_Name = 'polyhymnia', Printer_DPI = '300', Printer_Location = 'Sequencing Lab 6th Floor (Laser)',Printer_Type = 'LASER_PRINTER',Printer_Address='polyhymnia',Printer_Output='OFF',FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'LASER_PRINTER');
INSERT INTO Printer SET Printer_Name = 'z4m-1', Printer_DPI = '300', Printer_Location = 'GE Lab 5th Floor',Printer_Type = 'LARGE_LABEL_PRINTER',Printer_Address='z4m-1',Printer_Output='OFF',FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'LARGE_LABEL_PRINTER'),FK_Equipment__ID = (SELECT Equipment_ID FROM Equipment WHERE Equipment_Name = 'Equipment Barcodes');


INSERT INTO Printer SET Printer_Name = 'orbita', Printer_DPI = '200', Printer_Location = 'Sequencing Lab 6th Floor',Printer_Type = 'CHEMISTRY_PRINTER',Printer_Address='orbita',Printer_Output='OFF',FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'CHEMISTRY_PRINTER');


INSERT INTO Stock SET Stock_Name='Small Barcode Printer',FK_Employee__ID=1,Stock_Size=1,Stock_Size_Units='pcs',Stock_Type='Equipment',Stock_Number_in_Batch=1,FK_Organization__ID=2,Stock_Source='Made in House',FK_Grp__ID=3,FK_Barcode_Label__ID=10;

INSERT INTO Equipment SET Equipment_Name='Printer3 (Small equipment barcodes)',Equipment_Type='Printer',Model='Temp for testing',Serial_Number='12345678',FK_Stock__ID=(SELECT Stock_ID FROM Stock WHERE Stock_Name='Small Barcode Printer'),Equipment_Status='In Use',FK_Location__ID=2;

INSERT INTO Printer SET Printer_Name = 'saturnia', Printer_DPI = '200', Printer_Location = 'Sequencing Lab 6th Floor (small)',Printer_Type = 'SMALL_LABEL_PRINTER',Printer_Address='saturnia',Printer_Output='OFF',FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'SMALL_LABEL_PRINTER'),FK_Equipment__ID=(SELECT Equipment_ID FROM Equipment WHERE Equipment_Name='Printer3 (Small equipment barcodes)');

INSERT INTO Stock SET Stock_Name = 'Tube Barcode Printer',Stock_Number_in_Batch=1,Stock_Received='2008-08-01',Stock_Size = 1,Stock_Size_Units = 'pcs',Stock_Source='Made in House',Stock_Type='Equipment';

INSERT INTO Equipment SET Equipment_Name = 'Tube Barcode Printer',Equipment_Type = 'Printer',Model='Temp for testing',Serial_Number='12345678',Equipment_Status = 'In Use',Equipment_Condition='Room Temperature',FK_Stock__ID = (SELECT Stock_ID FROM Stock WHERE Stock_Name = 'Tube Barcode Printer'),FK_Location__ID = (SELECT Location_ID FROM Location WHERE Location_Name = 'Echelon 6th floor Sequencing Lab');

INSERT INTO Printer SET Printer_Name = 'z4m-2', Printer_DPI = '300', Printer_Location = 'GE Lab 6th Floor',Printer_Type = '2D_BARCODE_PRINTER',Printer_Address='z4m-2',Printer_Output='OFF',FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = '2D_BARCODE_PRINTER'),FK_Equipment__ID=(SELECT Equipment_ID FROM Equipment WHERE Equipment_Name = 'Tube Barcode Printer');

INSERT INTO Printer SET Printer_Name = 'polyhymnia', Printer_DPI = '300', Printer_Location = 'Sequencing Lab 6th Floor (Laser)',Printer_Type = 'LASER_PRINTER',Printer_Address='polyhymnia',Printer_Output='OFF',FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'LASER_PRINTER');

## Sets Printer Assignment for Cancer Genetics

DELETE FROM Printer_Assignment;
INSERT INTO Printer_Assignment SET FK_Printer_Group__ID = (SELECT Printer_Group_ID FROM Printer_Group WHERE Printer_Group_Name = 'Cancer Genetics Printers'), FK_Printer__ID = (SELECT Printer_ID FROM Printer WHERE Printer_Name = 'z4m-1'), FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'LARGE_LABEL_PRINTER');

INSERT INTO Printer_Assignment SET FK_Printer_Group__ID = (SELECT Printer_Group_ID FROM Printer_Group WHERE Printer_Group_Name = 'Cancer Genetics Printers'), FK_Printer__ID = (SELECT Printer_ID FROM Printer WHERE Printer_Name = 'orbita'), FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'CHEMISTRY_PRINTER');

INSERT INTO Printer_Assignment SET FK_Printer_Group__ID = (SELECT Printer_Group_ID FROM Printer_Group WHERE Printer_Group_Name = 'Cancer Genetics Printers'), FK_Printer__ID = (SELECT Printer_ID FROM Printer WHERE Printer_Name = 'z4m-3'), FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'SMALL_LABEL_PRINTER');

INSERT INTO Printer_Assignment SET FK_Printer_Group__ID = (SELECT Printer_Group_ID FROM Printer_Group WHERE Printer_Group_Name = 'Cancer Genetics Printers'), FK_Printer__ID = (SELECT Printer_ID FROM Printer WHERE Printer_Name = 'z4m-2'), FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = '2D_BARCODE_PRINTER');

INSERT INTO Printer_Assignment SET FK_Printer_Group__ID = (SELECT Printer_Group_ID FROM Printer_Group WHERE Printer_Group_Name = 'Cancer Genetics Printers'), FK_Printer__ID = (SELECT Printer_ID FROM Printer WHERE Printer_Name = 'polyhymnia'), FK_Label_Format__ID = (SELECT Label_Format_ID FROM Label_Format WHERE Label_Format_Name = 'LASER_PRINTER');
## Insert default protocols for Cancer Genetics

# Make the following protocols: PHA Assay, Serum processing, Plasma processing, Lymphocyte Extraction, DNA Extraction'

# INSERT INTO Protocol SET
;
## Customize Sample table for Cancer Genetics LIMS deployment

## Set sample types to be the same enum values as for plates and sources
DELETE FROM Sample;
DELETE FROM Clone_Sample;
DELETE FROM Extraction_Sample;
DELETE FROM Plate_Sample;
## Source table customizations

DELETE FROM Source;
## Source table customizations

DELETE FROM Source;
##

UPDATE Setting SET Setting_Default = 'Cancer Genetics Printers' WHERE Setting_Name = 'PRINTER_GROUP';

</DATA>
<FINAL>

## Make record in DBTable
DELETE FROM DBTable WHERE DBTable_Name='Patient';
INSERT INTO DBTable SET DBTable_Name = 'Patient', DBTable_Description = 'Lookup table for patient info', DBTable_Type = 'Lookup', DBTable_Title = 'Patient', Scope = 'Cancer_Genetics', Package_Name = 'Cancer_Genetics';

DELETE FROM DBField WHERE Field_Table='Patient';
## Make records for each field in DBField
# Primary Key
INSERT INTO DBField SET Field_Description = 'Primary key for Patient table',
Field_Table = 'Patient',
Field_Default='NULL',
Prompt = 'Patient ID',
Field_Alias = 'Patient',
Field_Options = 'Mandatory, Primary',
Field_Name = 'Patient_ID',
Field_Type = 'int(11)',
NULL_ok = 'NO',
Field_Size = 20,
Editable = 'no',
Tracked = 'yes',
Field_Scope = 'Custom',
FK_DBTable__ID=(SELECT DBTable_ID FROM DBTable WHERE DBTable_Name='Patient'),
Field_Reference= 'concat(Patient.FK_Library__Name,"-",Patient.Patient_Identifier," [",Patient.Patient_ID,"]")';

# Patient_Birthday
INSERT INTO DBField SET Field_Table = 'Patient',
Prompt = 'Patient Birthdate',
Field_Alias = 'Birthdate',
Field_Options = 'Mandatory',
Field_Order = 2,
Field_Name = 'Patient_Birthdate',
Field_Type = 'date',
NULL_ok = 'NO',
Field_Size = 20,
Editable = 'yes',
Tracked = 'yes',
Field_Scope = 'Custom',
FK_DBTable__ID=(SELECT DBTable_ID FROM DBTable WHERE DBTable_Name='Patient');

#Patient_Identifier -- basically same as the first_name field
INSERT INTO DBField SET
Field_Table = 'Patient',
Prompt = 'Study ID',
Field_Alias = 'Study_ID',
Field_Description='Study ID from requisition form',
Field_Options = 'Mandatory,Unique',
Field_Order = 3,
Field_Name = 'Patient_Identifier',
Field_Type = 'int(11)',
NULL_ok = 'NO',
Field_Size = 20,
Editable = 'yes',
Tracked = 'yes',
Field_Scope = 'Custom',
FK_DBTable__ID=(SELECT DBTable_ID FROM DBTable WHERE DBTable_Name='Patient');

INSERT INTO DBField SET Field_Description = 'Patient Sex',
Field_Table = 'Patient',
FK_DBTable__ID=(select DBTable_ID FROM DBTable WHERE DBTable_Name='Patient'),
Prompt = 'Sex',
Field_Alias = 'Sex',
Field_Options = 'Mandatory',
Field_Order = 4 ,
Field_Name = 'Patient_Sex',
Field_Type = 'enum(\'Male\',\'Female\')',
NULL_ok = 'NO',
Field_Size = 20,
Editable = 'yes',
Tracked = 'yes',
Field_Scope = 'Custom';

INSERT INTO DBField SET Field_Description = 'For which study did the patient donate samples',Field_Table = 'Patient',Prompt = 'Study',Field_Alias='Collection_Name',Field_Options = 'Mandatory',Field_Order = 1,Field_Name = 'FK_Library__Name',NULL_ok = 'NO',Field_Default = 'CGBM1',FK_DBTable__ID = (SELECT DBTable_ID FROM DBTable WHERE DBTable_Name = 'Patient'),Foreign_Key = 'Library.Library_Name',Editable = 'yes',Tracked = 'yes',Field_Scope='Custom';


#INSERT INTO DBField SET Field_Description = 'Contact',
#Field_Table = 'Patient',
#FK_DBTable__ID=(select DBTable_ID FROM DBTable WHERE DBTable_Name='Patient'),
#Prompt = 'Contact',
#Field_Alias = 'Contact',
#Field_Options = 'Mandatory,NewLink',
#Field_Order = 5,
#Field_Name = 'FK_Contact__ID',
#Field_Type = 'int(11)',
#NULL_ok = 'NO',
#Field_Size = 20,
#Editable = 'yes',
#Tracked = 'yes',
#Field_Scope = 'Custom';

UPDATE DBField SET Field_Type = "enum('Administration','Receiving','Cancer Genetics','None')" WHERE Field_Name = 'Department' AND Field_Table='Employee';
## Update Lab Protocol Table for Cancer_Genetics

## Make the field_alias for Lab_Protocol_Name be Protocol_Name

UPDATE DBField SET Prompt = 'Protocol Name' WHERE Field_Name='Lab_Protocol_Name' AND Field_Table='Lab_Protocol';
## Customize Library Table for cancer genetics group

UPDATE DBField SET Field_Default = '<TODAY>' WHERE Prompt = 'Obtained Date' AND Field_Table = 'Library';

#Remove unnecessary fields labeled as mandatory
UPDATE DBField SET Field_Options='' WHERE Field_Name = 'FK_Original_Source__ID' AND Field_Name = 'Library';
## update fields for library source

UPDATE DBField SET Field_Options='' WHERE Field_Name IN ('FK_Source__ID','FK_Library__Name');
## Original source table alterations:

UPDATE DBField SET Field_Options = 'Hidden,NewLink,Searchable' WHERE Field_Name = 'FK_Tissue__ID' AND Field_Table = 'Original_Source';
UPDATE DBField SET Field_Options = 'Hidden,Obsolete' WHERE Field_Name IN ('Tissue','FK_Contact__ID') AND Field_Table = 'Original_Source';

UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = 'Organism' AND Field_Table = 'Original_Source';

UPDATE DBField SET Field_Default = '<TODAY>' WHERE Field_Name = 'Defined_Date' AND Field_Table = 'Original_Source';
# INSERT INTO DBField SET Field_Description = 'Foreign key to patients',Field_Table = 'Original_Source',Field_Options = 'Newlink,Mandatory,Unique',Field_Type = 'int(11)', FK_DBTable__ID = (

UPDATE DBField SET Prompt = 'Samples available?' WHERE Field_Name = 'Sample_Available' AND Field_Table = 'Original_Source';
UPDATE DBField SET Prompt = 'Study ID' WHERE Field_Name = 'Original_Source_Name' AND Field_Table = 'Original_Source';

#UPDATE DBTable SET DBTable_Title = 'Patient Information' WHERE DBTable_Name = 'Original_Source';

UPDATE DBField SET Field_Default = 'Homo Sapiens' WHERE Field_Name = 'Organism' AND Field_Table = 'Original_Source';

## Hide fields/ render obsolete

UPDATE DBField SET Field_Options = 'Obsolete,Hidden' WHERE Field_Table = 'Original_Source ' AND (Field_Name = 'Tissue' OR Field_Name = 'FK_Stage__ID' OR Field_Name = 'Host' OR Prompt = 'Strain' OR Field_Name = 'FK_Taxonomy__ID');
UPDATE DBField SET Field_Type = "enum('Lymphocyte storage','DNA Extraction','Plasma Processing','Serum Processing','PHA Testing')" WHERE Field_Name = 'Plate_Application' AND Field_Table = 'Plate';
UPDATE DBField SET Field_Type = "enum('Tube','Vial')" WHERE Field_Name = 'Plate_Type' AND Field_Table = 'Plate';
UPDATE DBField SET Field_Type = "enum('DNA','Lymphocytes','Blood','Plasma','Serum','Saliva','Clone','Urine')" WHERE Field_Name = 'Plate_Content_Type' AND Field_Table = 'Plate';
UPDATE DBField SET Field_Type = "enum('1.5 mL','50 mL','15 mL','5 mL','2 mL','0.5 mL','0.2 mL')" WHERE Field_Name = 'Plate_Size' AND Field_Table = 'Plate';
UPDATE DBField SET Field_Type = "enum('Active','Inactive','Thrown Out','Contaminated','Exported','On Hold','Archived')" WHERE Field_Name = 'Plate_Status' AND Field_Table = 'Plate';
#INSERT INTO DBField SET

UPDATE DBField SET Field_Options='Mandatory' WHERE Field_Name='FK_Employee__ID' AND Field_Table='Plate';
UPDATE DBField SET Field_Options='' WHERE Field_Name='FK_Library__Name' AND Field_Table='Plate';


## Hide/ render obsolete the following fields:

UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name IN ('Parent_Quadrant','Plate_Parent_Well','FK_Branch__Code','FK_Pipeline__ID','QC_Status','FKLast_Prep__ID','FKParent_Plate__ID','Plate_Size','Plate_Number','Plate_Test_Status','Plate_Label','Plate_Application','FK_Work_Request__ID') AND Field_Table = 'Plate';
## Update Prep table and fields for Cancer Genetics

## change Prompt to clarify field in Prep Statistics search form
UPDATE DBField SET Prompt='Prep DateTime' where Field_Name='Prep_DateTime' AND Field_Table='Prep';
## Change settings for project table

#Render fields obsolete where appropriate
UPDATE DBField SET Field_Options='Obsolete' WHERE Field_Name = 'FK_Funding__ID';
## Sets record count to 8 for tables that are auto-complete

UPDATE DBTable SET Records = 8;

UPDATE DBField SET Field_Type = 'enum(\'Clone\',\'DNA\',\'Lymphocytes\',\'Plasma\',\'Serum\',\'Blood\',\'Saliva\',\'Urine\')' WHERE Field_Name IN ('Extraction_Sample_Type','Plate_Content_Type');
UPDATE DBField SET Field_Type = 'DATETIME' WHERE Field_Name = 'Received_Date' AND Field_Table = 'Source';

UPDATE DBField SET Field_Default = '<TODAY>' WHERE Field_Name = 'Received_Date' AND Field_Table = 'Source';

UPDATE DBField SET Field_Type = "enum('Blood','Serum','Plasma','Saliva','Lymphocytes','DNA','Urine')" WHERE Field_Name = 'Source_Type' AND Field_Table = 'Source';
UPDATE DBField SET Field_Type = "enum('Active','Inelligible','Thrown Out','Inactive')", Field_Default='Active' WHERE Field_Name = 'Source_Status' AND Field_Table = 'Source';
UPDATE DBField SET Field_Type = "enum('','ml','ul','ug','ng','pg')", Field_Options = 'NewLink' WHERE Field_Name = 'Amount_Units' AND Field_Table = 'Source';
DELETE FROM DBField WHERE Field_Name='Collected_Date';
DELETE FROM DBField WHERE Field_Name='Collected_Time';
INSERT INTO DBField SET Field_Description = 'Date sample collected from patient (YYYY-MM-DD)',Field_Table = 'Source',Prompt = 'Date sample collected',Field_Name = 'Collected_Date',Field_Type = 'DATE',Field_Scope = 'Custom',Field_Format='',FK_DBTable__ID = (select DBTable_ID FROM DBTable WHERE DBTable_Name='Source'),Field_Options='Mandatory',Field_Alias = 'Sample_Collected_Date';
INSERT INTO DBField SET Field_Description = 'Time sample collected from patient (TT:TT)',Field_Table = 'Source',Prompt = 'Time sample collected',Field_Name = 'Collected_Time',Field_Type = 'TIME',Field_Scope = 'Custom',Field_Format='',FK_DBTable__ID = (select DBTable_ID FROM DBTable WHERE DBTable_Name='Source'),Field_Options='';



# Use this line if Original Source table will be used as Patient table
# UPDATE DBField SET Prompt = 'Study ID' WHERE Field_Name = 'FK_Original_Source__ID' AND Field_Table = 'Source';

UPDATE DBField SET Prompt = 'External Identifier',Field_Description='Lab ID given to the study participant',Field_Options='' WHERE Field_Name = 'External_Identifier' AND Field_Table = 'Source';
DELETE FROM DBField WHERE Field_Name='FK_Patient__ID' AND Field_Table='Source';
INSERT INTO DBField SET Field_Description = 'Patient ID',Field_Table='Source',Prompt='Patient',Field_Alias='Patient_ID',Field_Options='Mandatory,NewLink',Field_Name='FK_Patient__ID',Field_Type='int(11)',NULL_ok='NO',FK_DBTable__ID = (SELECT DBTable_ID FROM DBTable WHERE DBTable_Name='Source'),Foreign_Key='Patient.Patient_ID',Editable='yes',Tracked='YES',Field_Scope='Custom',Field_Format='';

UPDATE DBField SET Field_Default='1',Field_Options='Hidden' WHERE Field_Name='FK_Original_Source__ID' AND Field_Table='Source';

# Set hidden fields

UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name IN ('FKSource_Plate__ID','Source_Number','Original_Amount','Amount_Units','FK_Rack__ID','FKParent_Source__ID','Label') AND Field_Table = 'Source';
UPDATE DBField SET Field_Type = 'DATETIME' WHERE Field_Name = 'Received_Date' AND Field_Table = 'Source';

UPDATE DBField SET Field_Default = '<TODAY>' WHERE Field_Name = 'Received_Date' AND Field_Table = 'Source';

UPDATE DBField SET Field_Type = "enum('Blood','Serum','Plasma','Saliva','Lymphocytes','DNA','Urine')" WHERE Field_Name = 'Source_Type' AND Field_Table = 'Source';
UPDATE DBField SET Field_Type = "enum('Active','Inelligible','Thrown Out','Inactive')", Field_Default='Active' WHERE Field_Name = 'Source_Status' AND Field_Table = 'Source';
UPDATE DBField SET Field_Type = "enum('','ml','ul','ug','ng','pg')", Field_Options = 'NewLink' WHERE Field_Name = 'Amount_Units' AND Field_Table = 'Source';
DELETE FROM DBField WHERE Field_Name='Collected_Date';
DELETE FROM DBField WHERE Field_Name='Collected_Time';
INSERT INTO DBField SET Field_Description = 'Date sample collected from patient (YYYY-MM-DD)',Field_Table = 'Source',Prompt = 'Date sample collected',Field_Name = 'Collected_Date',Field_Type = 'DATE',Field_Scope = 'Custom',Field_Format='',FK_DBTable__ID = (select DBTable_ID FROM DBTable WHERE DBTable_Name='Source'),Field_Options='Mandatory',Field_Alias = 'Sample_Collected_Date';
INSERT INTO DBField SET Field_Description = 'Time sample collected from patient (TT:TT)',Field_Table = 'Source',Prompt = 'Time sample collected',Field_Name = 'Collected_Time',Field_Type = 'TIME',Field_Scope = 'Custom',Field_Format='',FK_DBTable__ID = (select DBTable_ID FROM DBTable WHERE DBTable_Name='Source'),Field_Options='';



# Use this line if Original Source table will be used as Patient table
# UPDATE DBField SET Prompt = 'Study ID' WHERE Field_Name = 'FK_Original_Source__ID' AND Field_Table = 'Source';

UPDATE DBField SET Prompt = 'External Identifier',Field_Description='Lab ID given to the study participant',Field_Options='' WHERE Field_Name = 'External_Identifier' AND Field_Table = 'Source';
DELETE FROM DBField WHERE Field_Name='FK_Patient__ID' AND Field_Table='Source';
INSERT INTO DBField SET Field_Description = 'Patient ID',Field_Table='Source',Prompt='Patient',Field_Alias='Patient_ID',Field_Options='Mandatory,NewLink',Field_Name='FK_Patient__ID',Field_Type='int(11)',NULL_ok='NO',FK_DBTable__ID = (SELECT DBTable_ID FROM DBTable WHERE DBTable_Name='Source'),Foreign_Key='Patient.Patient_ID',Editable='yes',Tracked='YES',Field_Scope='Custom',Field_Format='';

UPDATE DBField SET Field_Default='1',Field_Options='Hidden' WHERE Field_Name='FK_Original_Source__ID' AND Field_Table='Source';

# Change options - use this line also if Original source is the patient
# UPDATE DBField SET Field_Options = 'NewLink,ViewLink' WHERE Field_Name = 'FK_Original_Source__ID' AND Field_Table = 'Source';

# Set hidden fields

UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name IN ('FKSource_Plate__ID','Source_Number','Original_Amount','Amount_Units','FK_Rack__ID','FKParent_Source__ID','Label') AND Field_Table = 'Source';
## customize necessary fields for Tube table

UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = 'Concentration' OR Field_Name = 'Concentration_Units';

</FINAL>
