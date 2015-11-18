## Patch file to modify a database

<DESCRIPTION> 









</DESCRIPTION>
<SCHEMA> 



ALTER TABLE Original_Source ADD FK_Pathology__ID int(11) NOT NULL DEFAULT '0';
ALTER TABLE Original_Source ADD Pathology_Type enum('Benign','Pre-malignant','Malignant','Non-neoplastic','Neoplastic','Undetermined') DEFAULT 'Undetermined' ;
ALTER TABLE Original_Source ADD Pathology_Grade set('G1','G2','G3','G4') DEFAULT NULL;
ALTER TABLE Original_Source ADD Pathology_Stage enum('0','I','I-A','I-B','II','II-A','II-B','III','III-A','III-B','III-C','IV','>=pT2') DEFAULT NULL;
ALTER TABLE Original_Source ADD Invasive enum('Invasive','Noninvasive') DEFAULT NULL;
ALTER TABLE Original_Source ADD Metastatic enum('Yes','No') DEFAULT NULL;

DROP INDEX patholgy on  Original_Source_Pathology;

</SCHEMA>
<DATA> 


UPDATE Original_Source_Pathology SET Metastatic = '' WHERE Metastatic is NULL;
UPDATE Original_Source_Pathology SET Invasive = '' WHERE Invasive is NULL;
UPDATE Original_Source_Pathology SET Pathology_Stage = '' WHERE Pathology_Stage is NULL;
UPDATE Original_Source_Pathology SET Pathology_Grade = '' WHERE Pathology_Grade is NULL;
UPDATE Original_Source_Pathology SET Pathology_Type = '' WHERE Pathology_Type is NULL;
UPDATE Original_Source_Pathology SET Pathology_Type = 'Undetermined' WHERE Pathology_Type = '';



UPDATE Original_Source_Pathology,Original_Source  SET Original_Source.Metastatic       = Original_Source_Pathology.Metastatic WHERE FK_Original_Source__ID = Original_Source_ID;
UPDATE Original_Source_Pathology,Original_Source  SET Original_Source.Invasive         = Original_Source_Pathology.Invasive WHERE FK_Original_Source__ID = Original_Source_ID;
UPDATE Original_Source_Pathology,Original_Source  SET Original_Source.Pathology_Stage  = Original_Source_Pathology.Pathology_Stage WHERE FK_Original_Source__ID = Original_Source_ID;
UPDATE Original_Source_Pathology,Original_Source  SET Original_Source.Pathology_Grade  = Original_Source_Pathology.Pathology_Grade WHERE FK_Original_Source__ID = Original_Source_ID;
UPDATE Original_Source_Pathology,Original_Source  SET Original_Source.Pathology_Type   = Original_Source_Pathology.Pathology_Type WHERE FK_Original_Source__ID = Original_Source_ID;
UPDATE Original_Source_Pathology,Original_Source  SET Original_Source.FK_Pathology__ID = Original_Source_Pathology.FK_Pathology__ID WHERE FK_Original_Source__ID = Original_Source_ID;








DELETE from DB_Trigger WHERE Table_Name LIKE 'Original_Source_Pathology';
delete from DB_Form WHERE Form_Table = 'Original_Source_Pathology'; 
DROP TABLE Original_Source_Pathology;
</DATA>
<CODE_BLOCK> 
if (_check_block('NAME_GOES_HERE')) { 
		


}
</CODE_BLOCK>
<FINAL>

DELETE FROM DBField WHERE Field_Table = 'Original_Source_Pathology';
UPDATE  DBField set Field_Reference = "CONCAT(Anatomic_Site.Anatomic_Site_Alias, ' ' , Histology.Histology_Alias,' ',Pathology.Pathology_NOS)"  WHERE Field_Name = 'Pathology_ID';

</FINAL>
