<SCHEMA>
ALTER TABLE Source MODIFY Source_Type ENUM('Mixed','Tissue','Cells','Whole Blood','Blood Serum','Blood Plasma','Red Blood Cells','White Blood Cells','Urine','Saliva');

ALTER TABLE Source MODIFY Source_Type enum('Mixed','Tissue','Cells','Whole Blood','Blood Serum','Blood Plasma','Red Blood Cells','White Blood Cells','Urine','Saliva');

</SCHEMA>
<DATA>
################################
INSERT INTO Barcode_Label SET Barcode_Label_Name = 'cg_tube_2D',Label_Height=0.75,Label_Width=1.7,Zero_X=25,Zero_Y=25,Top=15,FK_Setting__ID=4,Label_Descriptive_Name = '2D Healthbank tube',Barcode_Label_Type='plate',FK_Label_Format__ID=4;

UPDATE Plate_Format SET FK_Barcode_Label__ID = (SELECT Barcode_Label_ID FROM Barcode_Label WHERE Barcode_Label_Name = 'cg_tube_2D');

UPDATE Barcode_Label SET Barcode_Label_Status = 'Inactive' WHERE Barcode_Label_Name IN ('custom_2D_tube','ge_tube_barcode_2D','agar_plate','gelpour_barcode_1D','microarray','seqnightcult','seqnightcult_s','seqnightcult_smult','seqnightcult_mult');


## Add default organization and contact, the GSC and LIMS, respectively

################################

UPDATE Department SET Department_Name = 'Healthbank' WHERE Department_Name = 'Lab';
UPDATE Project SET Project_Name = 'Healthbank' WHERE Project_ID = 1;
UPDATE Library SET Library_Name = 'Hbank';

# Default Maintenance_Process_Types
INSERT INTO Maintenance_Process_Type SET Process_Type_Name = 'Inventory', Process_Type_Description = 'Inventory of equipment storage';

DELETE FROM Plate_Format WHERE Plate_Format_Type NOT LIKE 'Tube';

## Customize printer group

UPDATE Printer_Group SET Printer_Group_Name = 'Healthbank Printers' WHERE Printer_Group_Name = 'Default Printer Group';

## insert a printer for each format

UPDATE Printer_Group SET Printer_Group_Name = 'Healthbank Printers' WHERE Printer_Group_Name = 'Default Printer Group';
update Printer set Printer_Name = 'dhcc_1' where Printer_Name like 'default_2d_barcode_printer';
update Printer set Printer_Name = 'z4m-5' where Printer_Name like 'default_large_label_printer';

update Printer set Printer_Output = 'ZPL' where Printer_Name IN ('dhcc_1','z4m-5');

UPDATE Setting SET Setting_Default = 'Healthbank Printers' WHERE Setting_Name = 'PRINTER_GROUP';

INSERT INTO Attribute values ('','Minutes Clotted','text','Int',0,'No','Prep');

update Setting set Setting_Default = 5 where Setting_Name = 'DEFAULT_LOCATION';
update Setting set Setting_Default = 'dhcc_1' where Setting_Name = '2D_BARCODE_PRINTER';
update Setting set Setting_Default = 'z4m-5' where Setting_Name = 'LARGE_LABEL_PRINTER';

insert into Trigger values ('','Plate','SQL',"UPDATE Plate,Plate_Sample,Sample,Source,Original_Source,Sample_Type SET Plate_Label = CONCAT(Original_Source_Name,'-',Sample_Type.Sample_Type) WHERE Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID and Sample.FK_Source__ID=Source_ID AND Source.FK_Original_Source__ID=Original_Source_ID AND Plate.FK_Sample_Type__ID=Sample_Type_ID AND Plate_ID = <ID>", 'insert','Active','Customize Plate_Label','No');

update Site set Site_Address = 'Suite 100 - 570 West 7th Ave', Site_City = 'Vancouver', Site_State = 'BC',Site_Country='Canada', Site_Zip = 'V5Z 4S6' WHERE Site_Name like 'Freezer Farm';

update Site set Site_Address = '7-208 675 West 10th Ave', Site_City = 'Vancouver', Site_State = 'BC',Site_Country='Canada', Site_Zip = 'V5Z 1L3' WHERE Site_Name like 'CRC';

update Site set Site_Address = '2775 Laurel St', Site_City = 'Vancouver', Site_State = 'BC',Site_Country='Canada', Site_Zip = 'V5Z 1M9' WHERE Site_Name like 'DHCC';

</DATA>
<IMPORT>
Site.txt
Location.txt
Organization.txt
Equipment_Category.txt
Stock_Catalog.txt
Stock.txt
Equipment.txt
Lab_Protocol.txt
Rack.txt
Protocol_Step.txt
Sample_Type.txt
Original_Source.txt
Ordered_Procedure.txt
Pipeline.txt
GrpLab_Protocol.txt
Plate_Format.txt
Library.txt
</IMPORT>

<FINAL>

## Make record in DBTable

update DBField set Field_Reference = 'Plate_Label' where Field_Name = 'Plate_ID';
 
update DBField set Field_Reference = "CASE WHEN Wells=1 THEN Plate_Format_Type ELSE concat(Wells,' well ',Plate_Format_Type) END" WHERE Field_Name = 'Plate_Format_ID';

update DBField set Field_Reference = 'Plate_Label' where Field_Name = 'Plate_ID';

update DBField set Field_Default=1 where Field_Table = 'Source' and Field_Name = 'FK_Plate_Format__ID';

## Make the field_alias for Lab_Protocol_Name be Protocol_Name

UPDATE DBField SET Prompt = 'External Identifier',Field_Description='Onyx Barcode ID',Field_Options='' WHERE Field_Name = 'External_Identifier' AND Field_Table = 'Source';

update DBField set Field_Options = 'Mandatory,Searchable' where Field_Name = 'FK_Original_Source__ID';

update DBField set Prompt = 'Subject' where Field_Name = 'Original_Source_Name';
update DBField set Prompt = 'Subject' where Field_Name = 'FK_Original_Source__ID';
Update DBField set Prompt = 'Blood Drawn' where Field_Name = 'Received_Date' and Field_Table = 'Source';
update DBField set Prompt = 'Container Barcoded' where Field_Name = 'Plate_Created';
</FINAL>
