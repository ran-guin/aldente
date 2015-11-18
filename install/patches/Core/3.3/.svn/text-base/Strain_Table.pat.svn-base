## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
CREATE TABLE `Strain` (
  `Strain_ID` int(11) NOT NULL auto_increment,
  `Strain_Name` varchar(40) NOT NULL,
  PRIMARY KEY  (`Strain_ID`)
);
create unique index name on Strain (Strain_Name);

ALTER TABLE Vector_Based_Library ADD FK_Strain__ID int(11);
ALTER TABLE Original_Source ADD FK_Strain__ID int(11);
ALTER TABLE Xenograft ADD FK_Strain__ID int(11);

ALTER TABLE Original_Source MODIFY Pathology_Type  enum('Benign','Pre-malignant','Malignant','Non-neoplastic','Undetermined','Hyperplasia','Metaplasia','Dysplasia'); 

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
INSERT INTO Strain (select DISTINCT '',  Strain from Original_Source WHERE Strain IS NOT NULL and Strain <> ''  );
INSERT INTO Strain (select DISTINCT '',  Strain from Vector_Based_Library WHERE Strain IS NOT NULL and Strain <> '' and Strain NOT IN (Select  Strain_Name from Strain) );

UPDATE Strain, Original_Source SET FK_Strain__ID = Strain_ID WHERE Strain = Strain_Name ;
UPDATE Strain, Vector_Based_Library SET FK_Strain__ID = Strain_ID WHERE Strain = Strain_Name ;


ALTER TABLE Original_Source DROP Strain;
ALTER TABLE Vector_Based_Library DROP Strain;

</DATA>
<CODE_BLOCK> 
if (_check_block('NAME_GOES_HERE')) { 
		


}
</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)
update DBField set Field_Reference = 'Strain_Name' WHERE Field_Table = 'Strain' and Field_Name = 'Strain_ID';
update DBField set Editable = 'no' WHERE Field_Table = 'Strain' and Field_Name = 'Strain_Name';
update DBField set Tracked = 'yes' WHERE Field_Name = 'FK_Strain__ID';
update DBField set Field_Options = 'Obsolete' WHERE Field_Name = 'Strain';


</FINAL>
