## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

CREATE TABLE Replacement_Source_Request (
Replacement_Source_Request_ID INT NOT NULL Auto_Increment Primary Key,
Replacement_Source_Requested DATE NOT NULL,
Replacement_Source_Received DATE,
Replacement_Source_Status ENUM('Requested','Received','Re-requested','Not Available'),
FK_Source__ID INT NOT NULL,
FKReplacement_Source__ID INT,
FK_Replacement_Source_Reason__ID INT NOT NULL,
Replacement_Source_Request_Comments TEXT
);

CREATE TABLE Replacement_Source_Reason (
Replacement_Source_Reason_ID INT NOT NULL Auto_Increment Primary Key,
Replacement_Source_Reason VARCHAR(255),
Replacement_Source_Context ENUM('Internal','External')
);

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

INSERT INTO Replacement_Source_Reason VALUES ('','Insufficient Volume','External');
INSERT INTO Replacement_Source_Reason VALUES ('','Technical Issue','Internal');
INSERT INTO Attribute SELECT '','Replacement_Source_Status','',"ENUM('Requested','Received','Replacement')", Grp_ID, 'No','Source','Editable' FROM Grp where Grp_Name = 'Public';
INSERT INTO Attribute SELECT '','Replacement_for_Source','','FKReplacing_Source__ID', Grp_ID, 'No','Source','Editable' FROM Grp where Grp_Name = 'Public';

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

UPDATE DBField set Field_Reference = "Concat(Replacement_Source_Context,' - ', Replacement_Source_Reason)" WHERE Field_Name = 'Replacement_Source_Reason_ID';
UPDATE DBField set Field_Options = Concat(Field_Options, ',Mandatory') WHERE CONCAT(Field_Table,'.',Field_Name) IN ('Replacement_Source_Request.Replacement_Source_Requested','Replacement_Source_Request.FK_Source__ID','Replacement_Source_Request.FK_Replacement_Source_Reason__ID');

</FINAL>
