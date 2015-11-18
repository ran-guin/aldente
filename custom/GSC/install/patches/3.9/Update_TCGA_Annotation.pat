## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Updating TCGA Annotation Classifications and Categories

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Sample_Alert_Reason MODIFY COLUMN Sample_Alert_Type enum('Notification', 'Redaction', 'Observation', 'CenterNotification', 'Rescission');

</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

UPDATE Attribute SET Attribute_Type = "enum('Notification', 'Redaction', 'Observation', 'CenterNotification', 'Rescission')" WHERE Attribute_Name = 'Sample_Alert';

UPDATE Source_Attribute,Attribute SET Attribute_Value = 'Redaction' WHERE Attribute_Value = 'Redacted' AND FK_Attribute__ID = Attribute_ID AND Attribute_Name = 'Sample_Alert';
UPDATE Source_Attribute,Attribute SET Attribute_Value = 'Redaction + ? + ? + ? + ? + ? + ? + ? + ? + ? + ? + ?' WHERE Attribute_Value = 'Redacted + ? + ? + ? + ? + ? + ? + ? + ? + ? + ? + ?' AND FK_Attribute__ID = Attribute_ID AND Attribute_Name = 'Sample_Alert';

UPDATE Sample_Alert_Reason SET Sample_Alert_Type = 'Notification' where Sample_Alert_Reason = 'Item in special subset';

INSERT INTO Sample_Alert_Reason VALUES('', 'Item does not meet study protocol', 'Notification');
INSERT INTO Sample_Alert_Reason VALUES('', 'Item is noncanonical', 'Notification');
INSERT INTO Sample_Alert_Reason VALUES('', 'Neoadjuvant therapy', 'Notification');
INSERT INTO Sample_Alert_Reason VALUES('', 'Normal tissue origin incorrect', 'Notification');
INSERT INTO Sample_Alert_Reason VALUES('', 'Sample compromised', 'Notification');

INSERT INTO Sample_Alert_Reason VALUES('', 'Subject identity unknown', 'Redaction');
INSERT INTO Sample_Alert_Reason VALUES('', 'Tumor tissue origin incorrect', 'Redaction');

INSERT INTO Sample_Alert_Reason VALUES('', 'General', 'Observation');
INSERT INTO Sample_Alert_Reason VALUES('', 'Item may not meet study protocol', 'Observation');
INSERT INTO Sample_Alert_Reason VALUES('', 'Normal class but appears diseased', 'Observation');
INSERT INTO Sample_Alert_Reason VALUES('', 'Tumor class but appears normal', 'Observation');

INSERT INTO Sample_Alert_Reason VALUES('', 'Center QC failed', 'CenterNotification');
INSERT INTO Sample_Alert_Reason VALUES('', 'Item flagged DNU', 'CenterNotification');

DELETE from Sample_Alert_Reason where Sample_Alert_Reason = 'Prior Malignancy OR Prior Treatment (not sure which)';
DELETE from Sample_Alert_Reason where Sample_Alert_Reason = 'SNP Failure';
DELETE from Sample_Alert_Reason where Sample_Alert_Reason = 'IRB Requirements Not Met';

UPDATE Sample_Alert_Reason SET Sample_Alert_Reason  = 'Tumor type incorrect' WHERE Sample_Alert_Reason = 'Incorrect Pathology';
UPDATE Sample_Alert_Reason SET Sample_Alert_Reason  = 'Genotype mismatch' WHERE Sample_Alert_Reason = 'Failed SSTR';
UPDATE Sample_Alert_Reason SET Sample_Alert_Reason  = 'Qualified in error' WHERE Sample_Alert_Reason = 'Wrong Stage';


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

UPDATE DBField set Field_Type = "enum('Notification', 'Redaction', 'Observation', 'CenterNotification', 'Rescission')" WHERE Field_Table = 'Sample_Alert_Reason' and Field_Name = 'Sample_Alert_Type';

</FINAL>
