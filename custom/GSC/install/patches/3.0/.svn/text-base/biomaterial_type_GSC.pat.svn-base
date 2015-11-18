## Patch file to modify a database

<DESCRIPTION> 
</DESCRIPTION>
<SCHEMA>


ALTER TABLE RNA_DNA_Source CHANGE RNA_DNA_Source_ID Nucleic_Acid_ID int(11) auto_increment;
ALTER TABLE RNA_DNA_Source_Attribute CHANGE RNA_DNA_Source_Attribute_ID  Nucleic_Acid_Attribute_ID int(11);
ALTER TABLE RNA_DNA_Source_Attribute CHANGE FK_RNA_DNA_Source__ID  FK_Nucleic_Acid__ID int(11);
RENAME TABLE RNA_DNA_Source           TO Nucleic_Acid;
RENAME TABLE RNA_DNA_Source_Attribute TO Nucleic_Acid_Attribute;
</SCHEMA>

<DATA> 
INSERT INTO Storage_Medium (select DISTINCT '', Storage_Medium from Nucleic_Acid WHERE Storage_Medium IS NOT NULL and Storage_Medium <> '');  

INSERT INTO Sample_Type (Sample_Type, Sample_Type_Alias) VALUES 
('Nucleic_Acid','Nucleic_Acid'),
('Xformed_Cells','Cells-Xformed_Cells'),
('Bacterial_Cells','Cells-Bacterial_Cells'),
('Virus','Virus'),
('Cell_Line','Cells-Cell_Line'),
('Primary_Cells','Cells-Primary_Cells'),
('Cell_Culture','Cells-Cell_Culture'),
('Primary_Cell_Culture','Cells-Primary_Cell_Culture'),
('Bodily_Fluid','Bodily_Fluid'),
('Sorted_Cell','Cells-Sorted_Cell'),
('Library_Segment',''),
('ReArray_Plate',''),
('Ligation',''),
('Microtiter','');

UPDATE Source, Nucleic_Acid SET Source.Storage_Medium_Quantity = Nucleic_Acid.Storage_Medium_Quantity WHERE FK_Source__ID = Source_ID;
UPDATE Source, Nucleic_Acid SET Source.Sample_Collection_Date = Nucleic_Acid.Sample_Collection_Date WHERE FK_Source__ID = Source_ID;
UPDATE Source, Nucleic_Acid SET Source.Storage_Medium_Quantity_Units = Nucleic_Acid.Storage_Medium_Quantity_Units WHERE FK_Source__ID = Source_ID;
UPDATE Source, Storage_Medium, Nucleic_Acid set FK_Storage_Medium__ID = Storage_Medium_ID WHERE Storage_Medium_Name = Storage_Medium and FK_Source__ID = Source_ID;


UPDATE Sample_Type SET Sample_Type_Alias = Sample_Type WHERE Sample_Type IN ('EB','Water','Mixed','Cells','Protein','Clone','undefined','Extraction', 'Library_Segment','ReArray_Plate','Ligation','Microtiter','Tissue');

UPDATE Sample_Type SET Sample_Type_Alias= concat('Nucleic_Acid-', Sample_Type) WHERE Sample_Type_Alias  = '';
UPDATE Sample_Type SET FKParent_Sample_Type__ID = 0 WHERE Sample_Type_Alias = Sample_Type;
UPDATE Sample_Type SET FKParent_Sample_Type__ID = 30 WHERE Sample_Type.Sample_Type LIKE '%RNA%' OR Sample_Type.Sample_Type LIKE  '%DNA%' ;
UPDATE Sample_Type SET FKParent_Sample_Type__ID= 3 WHERE Sample_Type LIKE '%Cell%' and Sample_Type <> 'Cells';
UPDATE  Sample_Type as c , Sample_Type as p SET c.FKParent_Sample_Type__ID = p.Sample_Type_ID  WHERE p.Sample_Type = 'Nucleic_Acid' and c.Sample_Type_Alias LIKE 'Nucleic_Acid-%';
UPDATE  Sample_Type as c , Sample_Type as p SET c.FKParent_Sample_Type__ID = p.Sample_Type_ID  WHERE p.Sample_Type = 'Cells' and c.Sample_Type_Alias LIKE 'Cells-%';

UPDATE Source SET FK_Sample_Type__ID=0;

update Source, Nucleic_Acid, Sample_Type SET  FK_Sample_Type__ID = Sample_Type_ID  WHERE FK_Source__ID = Source_ID and Sample_Type= Nature ; 
update Source, Sample_Type set FK_Sample_Type__ID= Sample_Type_ID  WHERE Source_Type = 'Tissue_Sample' and FK_Sample_Type__ID = 0 and Sample_Type = 'Tissue';
update Source, Sample_Type set FK_Sample_Type__ID= Sample_Type_ID  WHERE Source_Type = 'Cells' and FK_Sample_Type__ID = 0 and Sample_Type = 'Cells';
update Source, Sample_Type set FK_Sample_Type__ID= Sample_Type_ID  WHERE Source_Type = 'Xformed_Cells' and FK_Sample_Type__ID = 0 and Sample_Type = 'Xformed_Cells';
update Source, Sample_Type set FK_Sample_Type__ID= Sample_Type_ID  WHERE Source_Type = 'Sorted_Cell' and FK_Sample_Type__ID = 0 and Sample_Type = 'Sorted_Cell';
update Source, Sample_Type set FK_Sample_Type__ID= Sample_Type_ID  WHERE Source_Type = 'RNA_DNA_Source' and FK_Sample_Type__ID = 0 and Sample_Type = 'Nucleic_Acid';
update Source, Sample_Type set FK_Sample_Type__ID= Sample_Type_ID  WHERE Source_Type = 'Library_Segment' and FK_Sample_Type__ID = 0 and Sample_Type = 'Library_Segment';
update Source, Sample_Type set FK_Sample_Type__ID= Sample_Type_ID  WHERE Source_Type = 'ReArray_Plate' and FK_Sample_Type__ID = 0 and Sample_Type = 'ReArray_Plate';
update Source, Sample_Type set FK_Sample_Type__ID= Sample_Type_ID  WHERE Source_Type = 'Ligation' and FK_Sample_Type__ID = 0 and Sample_Type = 'Ligation';
update Source, Sample_Type set FK_Sample_Type__ID= Sample_Type_ID  WHERE Source_Type = 'Microtiter' and FK_Sample_Type__ID = 0 and Sample_Type = 'Microtiter';
update Source, Sample_Type set FK_Sample_Type__ID= Sample_Type_ID  WHERE Source_Type = 'External' and FK_Sample_Type__ID = 0 and Sample_Type = 'undefined';

INSERT INTO DB_Form (SELECT '','Nucleic_Acid',1,1,1,21,'FK_Sample_Type__ID',Sample_Type.Sample_Type_Alias,1,NULL  from Sample_Type, Sample_Type as parent WHERE parent.Sample_Type_ID = Sample_Type.FKParent_Sample_Type__ID AND parent.Sample_Type = 'Nucleic_Acid'); 



INSERT INTO DB_Form (select '','Xformed_Cells',1,1,1,21,'FK_Sample_Type__ID', Sample_Type_Alias ,1,NULL from Sample_Type WHERE Sample_Type= 'Xformed_Cells');
INSERT INTO DB_Form (select '','Sorted_Cell',1,1,1,21,'FK_Sample_Type__ID', Sample_Type_Alias ,1,NULL from Sample_Type WHERE Sample_Type= 'Sorted_Cell');
INSERT INTO DB_Form (select '','Nucleic_Acid',1,1,1,21,'FK_Sample_Type__ID', Sample_Type_Alias ,1,NULL from Sample_Type WHERE Sample_Type= 'Nucleic_Acid');
INSERT INTO DB_Form (select '','Library_Segment',1,1,1,21,'FK_Sample_Type__ID', Sample_Type_Alias ,1,NULL from Sample_Type WHERE Sample_Type= 'Library_Segment');
INSERT INTO DB_Form (select '','ReArray_Plate',1,1,1,21,'FK_Sample_Type__ID', Sample_Type_Alias ,1,NULL from Sample_Type WHERE Sample_Type= 'ReArray_Plate');
INSERT INTO DB_Form (select '','Ligation',1,1,1,21,'FK_Sample_Type__ID', Sample_Type_Alias ,1,NULL from Sample_Type WHERE Sample_Type= 'Ligation');
INSERT INTO DB_Form (select '','Microtiter',1,1,1,21,'FK_Sample_Type__ID', Sample_Type_Alias ,1,NULL from Sample_Type WHERE Sample_Type= 'Microtiter');
UPDATE DB_Trigger SET Table_Name = 'Source'  WHERE Table_Name like 'RNA_DNA_Source';

ALTER TABLE Nucleic_Acid DROP Sample_Collection_Date;
ALTER TABLE Nucleic_Acid DROP Storage_Medium_Quantity;
ALTER TABLE Nucleic_Acid DROP Storage_Medium_Quantity_Units;
ALTER TABLE Nucleic_Acid DROP Storage_Medium;
ALTER TABLE Nucleic_Acid DROP Nature;

</DATA>
<CODE_BLOCK> 
if (_check_block('NAME_GOES_HERE')) { 
		


}
</CODE_BLOCK>
<FINAL>
update DBField set Field_Reference = "concat(Sample_Type.Sample_Type_Alias,'-',Source_Number,' ',Source_Label)"   WHERE Field_Name = 'Source_ID';
DELETE FROM DBField WHERE Field_Table = 'RNA_DNA_Source' and Field_Name IN ('Nature');
update Attribute set Attribute_Class = 'Nucleic_Acid' WHERE Attribute_Class = 'RNA_DNA_Source';


</FINAL>
