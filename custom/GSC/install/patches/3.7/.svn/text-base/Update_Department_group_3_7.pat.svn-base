## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
##Building up the UHTS Tab
Update Department set Department_Status = 'Active' where Department_Name = 'UHTS';
Update Grp set Grp_Status = 'Active' where Grp_Name IN ('UHTS','UHTS Admin','UHTS Project Admin','UHTS Production','UHTS TechD Admin','UHTS TechD');

Insert INTO GrpLab_Protocol (FK_Grp__ID, FK_Lab_Protocol__ID) select 61,Lab_Protocol_ID from Lab_Protocol where Lab_Protocol_Name IN ('Illumina HiSeq Loading','Illumina Paired End Read','Illumina amplification to primer hyb','Solexa PhiX activation');

Insert INTO GrpEmployee (FK_Grp__ID, FK_Employee__ID) select 61,Employee_ID from Employee where Employee_FullName IN ('Mabel Brown-John', 'Jashua Woo', 'Corey Matsuo', 'Heather Axam','Miruna Bala', 'Susan Wagner', 'Amanda Clarke', 'Didi Leung', 'Miranda Tsai','Jillian Smith', 'Mandy So', 'Steve Chand', 'Hyun-Wu Lee', 'Lorena Barclay','Richard Moore','Mike Mayo','Sarah Munro', 'Thomas Zeng');
Insert INTO GrpEmployee (FK_Grp__ID, FK_Employee__ID) select 59,Employee_ID from Employee where Employee_FullName IN ('Richard Moore','Mike Mayo','Sarah Munro', 'Thomas Zeng');
Insert INTO GrpEmployee (FK_Grp__ID, FK_Employee__ID) select 59,FK_Employee__ID from GrpEmployee,Employee where FK_Grp__ID = 43 and FK_Employee__ID = Employee_ID and Employee_FullName NOT IN ('Richard Moore','Mike Mayo','Sarah Munro', 'Thomas Zeng');

Update Stock_Catalog,Stock,Organization,Solution set Stock.FK_Grp__ID = 61 where Organization_ID = FK_Organization__ID and FK_Stock_Catalog__ID = Stock_Catalog_ID and Solution_Type = 'Reagent' and Organization_ID = 108 and Stock_ID = FK_Stock__ID and Stock_Catalog_Name IN ('V3 SBS Kit (50 cycle) box 2 of 2', 'V3 SBS Kit (200 cycle) box 2 of 2','V3 HS SR Flowcell','V3 HS SR Cluster kit','V3 HS PE Flowcell','V3 HS PE Cluster Kit box 2 of 2','V3 HS PE Cluster Kit box 1 of 2','V1.5 HS PE Flowcell','V1.5 HS SR Flowcell','TruSeq Cluster Kit v2 cBot/HS','V1 SBS Kit (200 cycle) box 2 of 2','V1 SBS Kit (50 cycle) box 2 of 2','smRNA Sequencing Primer','Multiplex Sequencing Box','HiSeq PE R2 Kit V2','HiSeq cBot PE cluster plate v2','Cleavage Reagent'); 
Update Stock_Catalog,Stock,Solution set Stock.FK_Grp__ID = 61 where FK_Stock_Catalog__ID = Stock_Catalog_ID and Stock_ID = FK_Stock__ID and Stock_Catalog_Name IN ('Gex Sequencing Primer','Small RNA Sequencing Primer','Genomic Seq v2 Primer','MR3 Seq Primer (100uM)','MR3 Index Primer (100uM)','GSC_Multiplex_R2_Seq_Primer');

Update Organization,Stock,Stock_Catalog,Equipment set Stock.FK_Grp__ID = 61 where Organization_ID = FK_Organization__ID and FK_Stock_Catalog__ID = Stock_Catalog_ID and Organization_ID = 108 and Stock_ID = FK_Stock__ID;

Update Stock,Equipment set Stock.FK_Grp__ID = 61 where Equipment_ID IN (330,1761,2190,2016,2502,2191,2211,2245) and Stock_ID = FK_Stock__ID;

Update Grp set Access = 'TechD' and Grp_Type = 'TechD' where Grp_Name = 'UHTS TechD'; 
Update Grp set Access = 'Admin' and Grp_Type = 'Lab Admin' where Grp_Name = 'UHTS TechD Admin';

insert into Grp_Relationship select '', Base_Grp.Grp_ID, Derived_Grp.Grp_ID from Grp AS Base_Grp, Grp AS Derived_Grp where Base_Grp.Grp_Name = 'UHTS' and Derived_Grp.Grp_Name = 'UHTS Production';
insert into Grp_Relationship select '', Base_Grp.Grp_ID, Derived_Grp.Grp_ID from Grp AS Base_Grp, Grp AS Derived_Grp where Base_Grp.Grp_Name = 'UHTS' and Derived_Grp.Grp_Name = 'UHTS Project Admin';
insert into Grp_Relationship select '', Base_Grp.Grp_ID, Derived_Grp.Grp_ID from Grp AS Base_Grp, Grp AS Derived_Grp where Base_Grp.Grp_Name = 'UHTS Production' and Derived_Grp.Grp_Name = 'UHTS Admin';
insert into Grp_Relationship select '', Base_Grp.Grp_ID, Derived_Grp.Grp_ID from Grp AS Base_Grp, Grp AS Derived_Grp where Base_Grp.Grp_Name = 'UHTS Production' and Derived_Grp.Grp_Name = 'UHTS TechD';

##changing BioSpecimens to BioSpecimens_Core
Update Department set Department_Name = 'Biospecimen_Core' where Department_Name = 'BioSpecimens'; 
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
