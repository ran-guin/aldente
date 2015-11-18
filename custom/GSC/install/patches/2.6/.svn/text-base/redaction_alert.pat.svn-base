## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
This patch is for adding the tables which were supposed to be in GSC package

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
CREATE TABLE Sample_Alert_Reason (
Sample_Alert_Reason_ID INT NOT NULL PRIMARY KEY Auto_Increment,
Sample_Alert_Reason VARCHAR(64),
Sample_Alert_Type ENUM('Notification','Redaction')
);

INSERT INTO Attribute VALUES ('','Sample_Alert','',"ENUM('Redacted','Notification')",48,'Yes','Source','Editable');
INSERT INTO Attribute VALUES ('','Sample_Alert_Reason','','FK_Sample_Alert_Reason__ID',48,'Yes','Source','Editable');

INSERT INTO Sample_Alert_Reason VALUES ('','Prior Malignncy','Notification');
INSERT INTO Sample_Alert_Reason VALUES ('','Prior Treatment','Notification');
INSERT INTO Sample_Alert_Reason VALUES ('','Prior Malignancy AND Prior Treatment', 'Notification');
INSERT INTO Sample_Alert_Reason VALUES ('','Prior Malignancy OR Prior Treatment (not sure which)', 'Notification');
INSERT INTO Sample_Alert_Reason VALUES ('','Wrong Stage', 'Notification');

INSERT INTO Sample_Alert_Reason VALUES ('','Normal Tissue Identity Mismatch', 'Redaction');
INSERT INTO Sample_Alert_Reason VALUES ('','Incorrect Pathology', 'Redaction');
INSERT INTO Sample_Alert_Reason VALUES ('','Failed SSTR', 'Redaction');
INSERT INTO Sample_Alert_Reason VALUES ('','SNP Failure', 'Redaction');
INSERT INTO Sample_Alert_Reason VALUES ('','Patient Identity Ambiguity', 'Redaction');

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


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

UPDATE DBField set Field_Reference = "Concat(Sample_Alert_Type,' - ',Sample_Alert_Reason')" WHERE Field_Name = 'Sample_Alert_Reason_ID';


</FINAL>

