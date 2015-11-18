## Patch file to modify a database

<DESCRIPTION> 









</DESCRIPTION>
<SCHEMA> 
ALTER TABLE Original_Source MODIFY Original_Source_Type enum('Arthropod','Bacteria','Bodily_Fluid','Cell_Line','Exfoliate','Fungi','Invertebrate' ,'Metagenomic','Mixed','Plant','Solid_Tissue','Solid_Tissue(Vertebrate)','Stem_Cell','Virus') DEFAULT NULL;


UPDATE Original_Source set Original_Source_Type = 'Invertebrate'  WHERE Original_Source_Type = 'Arthropod';

UPDATE Original_Source set Original_Source_Type = 'Solid_Tissue(Vertebrate)'  WHERE Original_Source_Type = 'Solid_Tissue';

ALTER TABLE Original_Source MODIFY Original_Source_Type enum('Bacteria','Bodily_Fluid','Cell_Line','Exfoliate','Fungi','Invertebrate' ,'Metagenomic','Mixed','Plant','Solid_Tissue(Vertebrate)','Stem_Cell','Virus') DEFAULT NULL;

ALTER TABLE Anatomic_Site MODIFY Anatomic_Site_Type enum('Arthropod','Bacteria','Bodily_Fluid','Exfoliate','Fungi','Invertebrate','Metagenomic','Mixed','Plant','Solid_Tissue','Solid_Tissue(Vertebrate)','Stem_Cell','Virus') ;

UPDATE Anatomic_Site set Anatomic_Site_Type = 'Invertebrate'  WHERE Anatomic_Site_Type = 'Arthropod';

UPDATE Anatomic_Site set Anatomic_Site_Type = 'Solid_Tissue(Vertebrate)'  WHERE Anatomic_Site_Type = 'Solid_Tissue';


ALTER TABLE Anatomic_Site MODIFY Anatomic_Site_Type enum('Bacteria','Bodily_Fluid','Exfoliate','Fungi','Invertebrate','Metagenomic','Mixed','Plant','Solid_Tissue(Vertebrate)','Stem_Cell','Virus') ;

 CREATE Unique INDEX alias on Anatomic_Site (Anatomic_Site_Alias);
</SCHEMA>
<DATA> 
UPDATE DBField set Field_Type = "enum('Bacteria','Bodily_Fluid','Cell_Line','Exfoliate','Fungi','Invertebrate' ,'Metagenomic','Mixed','Plant','Solid_Tissue(Vertebrate)','Stem_Cell','Virus')" WHERE Field_Name = 'Original_Source_Type' ;
UPDATE DBField set Field_Type = "enum('Bacteria','Bodily_Fluid','Exfoliate','Fungi','Invertebrate','Metagenomic','Mixed','Plant','Solid_Tissue(Vertebrate)','Stem_Cell','Virus')" WHERE Field_Name = 'Anatomic_Site_Type' ;



</DATA>
<CODE_BLOCK> 
if (_check_block('NAME_GOES_HERE')) { 
		


}
</CODE_BLOCK>
<FINAL>

</FINAL>
