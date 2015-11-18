## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
CREATE TABLE `Library_Strategy` (
  `Library_Strategy_ID` int(11) NOT NULL auto_increment,
  `Library_Strategy_Name` varchar(40) NOT NULL,
  PRIMARY KEY  (`Library_Strategy_ID`)
);
create unique index name on Library_Strategy (Library_Strategy_Name);


CREATE TABLE `Library_Strategy_Pipeline` (
  `Library_Strategy_Pipeline_ID` int(11) NOT NULL auto_increment,
  `FK_Library_Strategy__ID` int(11) NOT NULL ,
  `FK_Pipeline__ID` int(11) NOT NULL ,
  PRIMARY KEY  (`Library_Strategy_Pipeline_ID`)
);
create unique index record on Library_Strategy_Pipeline (FK_Library_Strategy__ID,FK_Pipeline__ID);

UPDATE Attribute SET Attribute_Type = 'FK_Library_Strategy__ID' WHERE Attribute_Name = 'Library_Strategy';

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
INSERT INTO Library_Strategy (select DISTINCT '', Attribute_Value from Plate_Attribute WHERE FK_Attribute__ID=246 AND Attribute_Value <> '');

INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'MRE' and Library_Strategy_Name = 'MRE_Seq');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'BIS' and Library_Strategy_Name = 'Bisulfite_Seq');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'AMP' and Library_Strategy_Name = 'Amplicon');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'CHP' and Library_Strategy_Name = 'ChIP-Seq');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'DAI' and Library_Strategy_Name = 'Dnase-Hypersensitivity');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'BAC' and Library_Strategy_Name = 'PoolClone');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'GSH' and Library_Strategy_Name = 'WGS');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'MON' and Library_Strategy_Name = 'Mnase-Seq');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'TRA' and Library_Strategy_Name = 'RNA_Seq');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'TAR' and Library_Strategy_Name = 'RNA_Seq');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'MR2' and Library_Strategy_Name = 'miRNA_Seq');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'MIR' and Library_Strategy_Name = 'miRNA_Seq');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'MR3' and Library_Strategy_Name = 'miRNA_Seq');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'SMR' and Library_Strategy_Name = 'miRNA_Seq');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'SAG' and Library_Strategy_Name = 'Other');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'FAI' and Library_Strategy_Name = 'Other');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'SLI' and Library_Strategy_Name = 'Other');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'TLI' and Library_Strategy_Name = 'RNA_Seq');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'SDN' and Library_Strategy_Name = 'Other');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'MPE' and Library_Strategy_Name = 'Other');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'PTA' and Library_Strategy_Name = 'Other');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'EXC' and Library_Strategy_Name = 'EXC_Seq');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'EXT' and Library_Strategy_Name = 'EXT_Seq');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'RRS' and Library_Strategy_Name = 'RNA_Seq');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'BCP' and Library_Strategy_Name = 'BAC_Capture');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'SCP' and Library_Strategy_Name = 'EXC_Seq');
INSERT INTO Library_Strategy_Pipeline (select '' , Library_Strategy_ID , Pipeline_ID from Library_Strategy, Pipeline WHERE Pipeline_Code = 'RSA' and Library_Strategy_Name = 'RNA_Seq');
delete from Plate_Attribute WHERE FK_Attribute__ID=246 and Attribute_Value = '';

UPDATE Plate_Attribute, Library_Strategy SET Attribute_Value = Library_Strategy_ID  WHERE FK_Attribute__ID=246 and Library_Strategy_Name = Attribute_Value;

</DATA>
<CODE_BLOCK> 
if (_check_block('NAME_GOES_HERE')) { 
		


}
</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

update DBField set Field_Reference = 'Library_Strategy_Name' WHERE Field_Table = 'Library_Strategy' and Field_Name = 'Library_Strategy_ID';
update DBField set Editable = 'no' WHERE Field_Table = 'Library_Strategy' and Field_Name = 'Library_Strategy_Name';

</FINAL>
