## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
This patch is to add functionality to enable QC monitoring for batches of items of different types.  This should ultimately enable QC'ing of either Stock items of a specific lot number or a specific list of plasticware that has been prepared in a special way (eg Agar or Glycerol plates)

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

CREATE TABLE QC_Batch ( 
QC_Batch_ID INT NOT NULL auto_increment PRIMARY KEY, 
QC_Batch_Name varchar(40) NOT NULL,
Batch_Count INT NOT NULL,
QC_Batch_Number INT NOT NULL Default 0,
FK_Solution__ID INT,
FK_Stock_Catalog__ID INT,
QC_Batch_Initiated DateTime NOT NULL, 
FK_Employee__ID INT NOT NULL, 
QC_Batch_Status enum('N/A','Pending','Failed','Re-Test','Passed'), 
QC_Batch_Notes text
);

CREATE TABLE QC_Batch_Member ( 
QC_Batch_Member_ID INT NOT NULL auto_increment PRIMARY KEY, 
FK_QC_Batch__ID INT NOT NULL, 
FK_Object_Class__ID INT NOT NULL, 
Object_ID INT NOT NULL, 
QC_Batch_Member_Type enum('Tested','Implied'),
QC_Member_Status enum('Quarantined','Released','Rejected')
);

alter table Stock_Catalog modify Stock_Type enum('Box','Buffer','Equipment','Kit','Matrix','Microarray','Primer','Reagent','Solution','Service_Contract','Computer_Equip','Misc_Item','Untracked');

create index FK_Solution__ID on QC_Batch (FK_Solution__ID);
create index FK_Stock_Catalog__ID  on QC_Batch (FK_Stock_Catalog__ID);
create index FK_Employee__ID  on QC_Batch (FK_Employee__ID);
create index FK_QC_Batch__ID on QC_Batch_Member (FK_QC_Batch__ID);
create index FK_Object_Class__ID on QC_Batch_Member (FK_Object_Class__ID);

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

insert into Object_Class values ('','Solution','Solution');
insert into Object_Class values ('','Untracked','');

insert into Department values ('','QC','Active');
update Grp,Department set FK_Department__ID = Department_ID where Grp_Name = 'QC' AND Department_Name = 'QC';

insert into Stock_Catalog values ('','Poured Agar Plates','Agar plates prepared with Agarose and Antibiotic','','Untracked','Made In House','Active','','n/a',27,27,'','');
insert into Stock_Catalog values ('','Poured Glycerol Plates','Glycerol plates prepared with Antibiotic','','Untracked','Made In House','Active','','n/a',27,27,'','');

insert into `Trigger` values ('','QC_Batch','Method','new_QC_Batch_trigger','insert','Active','update QC Batch Number','No');
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
UPDATE DBField SET Tracked = 'yes' WHERE Field_Name IN ('QC_Batch_Status','QC_Member_Status');

UPDATE DBField set Tracked = 'yes' where Field_Name in ('QC_Batch_Status','QC_Member_Status');
update DBField set Field_Options = 'Mandatory' where Field_Name = 'QC_Batch_Name';

update DBField set Field_Reference = 'QC_Batch_Name' where Field_Name = 'QC_Batch_ID';
</FINAL>
