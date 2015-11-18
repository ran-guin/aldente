## Patch file to modify a database

<DESCRIPTION> 
</DESCRIPTION>
<SCHEMA> 

CREATE TABLE `Storage_Medium` (
  `Storage_Medium_ID` int(11) NOT NULL auto_increment,
  `Storage_Medium_Name` varchar(40) NOT NULL,
  PRIMARY KEY  (`Storage_Medium_ID`)
);

ALTER TABLE Source ADD FK_Storage_Medium__ID int(11) DEFAULT NULL;
ALTER TABLE Source ADD Storage_Medium_Quantity_Units  enum('','ml','ul') DEFAULT NULL;
ALTER TABLE Source ADD Storage_Medium_Quantity double(8,4) DEFAULT NULL;
ALTER TABLE Source ADD Sample_Collection_Date date NOT NULL DEFAULT '0000-00-00';
ALTER TABLE Sample_Type ADD FKParent_Sample_Type__ID int(11) DEFAULT NULL;
ALTER TABLE Sample_Type ADD Sample_Type_Alias        varchar(255) NOT NULL;
ALTER TABLE Source ADD FK_Sample_Type__ID int(11) NOT NULL;
CREATE UNIQUE Index Sample_Type ON Sample_Type (Sample_Type);

ALTER TABLE Plate_Format MODIFY Well_Capacity_mL FLOAT;

</SCHEMA>
<DATA> 
UPDATE Source,Sample_Type SET FK_Sample_Type__ID=Sample_Type_ID WHERE Sample_Type=Source_Type;
update DBField set Field_Reference = 'Sample_Type_Alias' WHERE Field_Name = 'Sample_Type_ID';

insert into Sample_Type values ('','RBC+WBC', '','RBC+WBC');


</DATA>
<CODE_BLOCK> 
if (_check_block('NAME_GOES_HERE')) { 
		


}
</CODE_BLOCK>
<FINAL>
### FK_SAMPLE_TYPE__ID IS NOT EDITABLE
update DBField set Prompt= 'Biomaterial Type' WHERE Field_Name = 'FK_Sample_Type__ID' and Field_Table = 'Source';
update DBField set Editable= 'no' WHERE Field_Name = 'FK_Sample_Type__ID' and Field_Table = 'Source';
update DBField set Field_Options= 'Mandatory' WHERE Field_Name = 'FK_Sample_Type__ID' and Field_Table = 'Source'; 
update DBField set Field_Order = 4 WHERE Field_Table = 'Source' and Field_Name = 'FK_Sample_Type__ID';

Update DBField set Field_Reference = "CASE WHEN Wells = 1 THEN CASE WHEN Well_Capacity_mL > 0 THEN concat(Well_Capacity_mL,' ',Capacity_Units,' ',Plate_Format_Type) ELSE Plate_Format_Type END ELSE concat(Wells,'-well ',Plate_Format_Type) END "  WHERE Field_Name = 'Plate_Format_ID' ;

</FINAL>
