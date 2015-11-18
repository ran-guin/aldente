## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

alter table Patch add column FKRelease_Version__ID int (11) NOT NULL;
alter table Patch add column Patch_Version varchar (40) NOT NULL;
alter table Patch modify column Install_Status enum('Installed','Marked for install','Not installed', 'Installed with errors','Installation aborted','Installing');
alter table Package add FKParent_Package__ID int (11) ;
alter Table Package modify Package_Scope enum ('Plugins','custom','Options','Core') default 'Plugins'; 
alter table Version  change Status Version_Status enum('In use','Not in use') Default 'Not in use';
alter table Patch change Last_Attempted_Install_Date Installation_Date date not NULL default '0000-00-00';
alter table Patch add column Patch_Description text Default NULL;
alter table Patch modify Patch_Type enum ('bug fix','installation') not null default 'installation';
alter table DBField add FK_Package__ID  int (11) NOT NULL;

create index parent_package on Package (FKParent_Package__ID);
create index version on Patch (FKRelease_Version__ID);
create index package on DBField (FK_Package__ID);

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)





update Patch, Version set FKRelease_Version__ID = Version_ID  WHERE Patch.Version = Version_Name;
update Package set Package_Scope = 'Plugins' WHERE Package_ID IN (3,4,5,6,7,8,9,10,21,23);
update Package set Package_Scope = 'Options' WHERE Package_Scope = '';
insert into Package (Package_Scope,Package_Active,Package_Name,Package_install_Status,FKParent_Package__ID) values ('Core','y','Core','Installed',0);
insert into Package (Package_Scope,Package_Active,Package_Name,Package_install_Status,FKParent_Package__ID) values ('Plugins','y','Lab','Installed',24);
update Package set FKParent_Package__ID = 24 WHERE Package_ID IN (1,2,3,7,10,11,12,13,15,17,19,21,22,25);
update Package set FKParent_Package__ID = 10 WHERE Package_ID IN (5,6,8,9,14,16);
update Package set FKParent_Package__ID = 6 WHERE Package_ID IN (4,23);
update Package set FKParent_Package__ID = 25 WHERE Package_ID IN (18,20);
insert into Patch (FK_Package__ID,Patch_type,Patch_Name,Install_Status,FKRelease_Version__ID ) values ('23' , 'hotfix' , 'SOLID' , 'Not Installed','10');
update Patch set Patch_Version = Patch_Name WHERE Patch_ID between 6 and 29;
update Patch  set Patch_Name = 'Asset'  WHERE Patch_version = '2.5.0.3.GSC.1';
update Patch  set Patch_Name = 'Vendor'  WHERE Patch_version = '2.5.0.3.GSC.2';
update Patch set Patch_Name = 'Equipment_Transfer' WHERE Patch_version = '2.5.0.3.GSC.3';
update Patch set Patch_Name = 'GSC_installed_pkgs' WHERE Patch_version = '2.5.0.3.GSC.4';
update Patch set Patch_Name = 'GSC_active_pckgs' WHERE Patch_version = '2.5.0.3.GSC.5';
update Patch set Patch_Name = 'upgrade_GSC_2.6'  WHERE Patch_version = '2.6.0.4.GSC.1';
update Patch set Patch_Name = 'Source_Types' WHERE Patch_version = '2.5.0.1';
update Patch set Patch_Name = 'Library_Types' WHERE Patch_version = '2.5.0.2';
update Patch set Patch_Name = 'Work_Request_Types'  WHERE Patch_version = '2.5.0.3';
update Patch set Patch_Name = 'init_run_batch_table'  WHERE Patch_version = '2.5.0.4';
update Patch set Patch_Name = 'upgrade_Core_2.6' WHERE Patch_version = '2.6.0';
update Patch set Patch_Name = 'upgrade_Sequencing_2.6' WHERE Patch_version = '2.6.0.1';
update Patch set Patch_Name = 'upgrade_Microarray_2.6' WHERE Patch_version = '2.6.0.3';
update Patch set Patch_Name = 'upgrade_mapping_2.6' WHERE Patch_version = '2.6.0.4';
update Patch set Patch_Name = 'add_analysis_software' WHERE Patch_version = '2.6.1';
update Patch set Install_Status = 'Installed'  WHERE Patch_ID Between 6 and 24;
update Patch set FK_Package__ID = '24'  WHERE Patch_Name = 'upgrade_Core_2.6';
update Patch set Patch_Version = '2.6.0.0'  WHERE Patch_Name = 'upgrade_Core_2.6';
update Patch set Patch_Version = '2.6.1.0'  WHERE Patch_Name = 'add_analysis_software';
update Patch set Install_Status = 'Installed'  WHERE Patch_Name = 'add_analysis_software';
Insert into Patch (FK_Package__ID,Patch_Type,Patch_Name,Install_Status, FKRelease_VErsion__ID, Patch_Version) values (10, 'release_time','upgrade_Genomic_2.6','Installed',10,'2.6.0.2');
update Patch  set Patch_Version = '2.6.2.0'  WHERE Patch_Name = 'SOLID';
insert into Package (Package_Scope,Package_Active,Package_Name,Package_install_Status,FKParent_Package__ID) values ('Plugins','y','Software_Analysis','Installed',10);
update Patch set FK_Package__ID = '26'  WHERE Patch_Name = 'add_analysis_software';
delete from Patch WHERE Patch_ID IN (3,4);
update Patch  set patch_version = '2.5.1.0'  WHERE Patch_ID = 5;
update Patch  set patch_Name = 'JIRA_active'  WHERE Patch_ID = 5;
update Patch set Patch_Version = '2.5.2.0'  WHERE Patch_ID = 1;
update Patch set Patch_Version = '2.5.3.0'  WHERE Patch_ID = 2;
update Patch  set FK_Package__ID  = '24'  WHERE Patch_ID IN (1,2);
update Patch Set Patch_Type = 'installation';
Insert into Patch values (31,24,'installation','Installation','Installed','2.6','0000-00-00',10,'2.6.3.0','');
update Package set Package_Active = 'y' where Package_Name = 'SOLID';
update Package set Package_Install_Status = 'Installed' where Package_Name = 'SOLID';
create unique index patch_version on Patch (Patch_Version);
create unique index patch_name on Patch (Patch_Name);
create unique index package_name on Package (Package_Name);

Insert into Patch values (32,26,'installation','add_analysis_software','Installed','2.6','0000-00-00','10','2.6.1.0','');
update Patch set Install_Status = 'Installed' WHERE Patch_Name = 'SOLID';






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


update DBField set Field_Options = 'Obsolete'  WHERE FielD_Table = 'Patch'  and Field_Name = 'Version';
update DBField set Field_Options = 'Mandatory'  WHERE Field_Table IN ('Package','Patch') AND Field_NAme IN ('Package_Scope', 'Package_Active', 'Package_Name', 'Package_Install_Status', 'FK_Package__ID', 'Patch_Name' , 'Install_Status', 'Patch_Code');


</FINAL>
