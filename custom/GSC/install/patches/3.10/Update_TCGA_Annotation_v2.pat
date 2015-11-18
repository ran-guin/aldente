## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Updating TCGA Annotation Classifications and Categories
Adding Annotation Notes column

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Sample_Alert_Reason ADD COLUMN Sample_Alert_Reason_Notes text Default NULL;

</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

INSERT INTO Sample_Alert_Reason VALUES('', 'Administrative Compliance', 'Redaction', '');

UPDATE Sample_Alert_Reason SET Sample_Alert_Reason = 'Neoadjuvant Therapy and Prior Malignancy' WHERE Sample_Alert_Reason = 'Prior Malignancy AND Prior Treatment';

UPDATE Source_Attribute, Attribute, Sample_Alert_Reason SET Attribute_Value = (SELECT Sample_Alert_Reason_ID FROM Sample_Alert_Reason WHERE Sample_Alert_Reason = 'Neoadjuvant therapy') WHERE Attribute_Value = Sample_Alert_Reason_ID and Sample_Alert_Reason = 'Prior Treatment' and Attribute_Name = 'Sample_Alert_Reason' and FK_Attribute__ID = Attribute_ID; 
DELETE FROM Sample_Alert_Reason WHERE Sample_Alert_Reason = 'Prior Treatment';

UPDATE Source_Attribute, Attribute, Sample_Alert_Reason SET Attribute_Value = (SELECT Sample_Alert_Reason_ID FROM Sample_Alert_Reason WHERE Sample_Alert_Reason = 'Genotype mismatch') WHERE Attribute_Value = Sample_Alert_Reason_ID and Sample_Alert_Reason = 'Normal Tissue Identity Mismatch' and Attribute_Name = 'Sample_Alert_Reason' and FK_Attribute__ID = Attribute_ID; 
DELETE FROM Sample_Alert_Reason WHERE Sample_Alert_Reason = 'Normal Tissue Identity Mismatch';

UPDATE Source_Attribute, Attribute, Sample_Alert_Reason SET Attribute_Value = (SELECT Sample_Alert_Reason_ID FROM Sample_Alert_Reason WHERE Sample_Alert_Reason = 'Subject identity unknown') WHERE Attribute_Value = Sample_Alert_Reason_ID and Sample_Alert_Reason = 'Patient Identity Ambiguity' and Attribute_Name = 'Sample_Alert_Reason' and FK_Attribute__ID = Attribute_ID; 
DELETE FROM Sample_Alert_Reason WHERE Sample_Alert_Reason = 'Patient Identity Ambiguity';


</DATA>
<CODE_BLOCK> 
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below
if (_check_block('NAME_GOES_HERE')) { 
		


}
</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

</FINAL>
