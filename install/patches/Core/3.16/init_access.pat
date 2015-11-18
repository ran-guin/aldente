## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

LIMS-10847 - Adjusting Group Access field to enable linkage to separate database user connections at login time

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

## establish fixed list of employee user access types ##

# ALTER TABLE Grp modify Access ENUM('LIMS Admin','Lab Admin','projects Admin','Purchasing Admin','QC Admin','Computer Admin','Lab','projects','Purchasing','QC','Computer','Internal','Guest');
ALTER TABLE Grp ADD FK_DB_Login__ID INT NULL;
ALTER TABLE DB_Login ADD DB_Access_Level ENUM('0','1','2','3','4','5');
ALTER TABLE DB_Login ADD DB_Login_Description TEXT;

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

## Interface users ##
DELETE FROM DB_Login where FK_Employee__ID IS NULL;

INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('LIMS_admin',5,'LIMS Administrators');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('login',1,'Only used to generate login page (access to submit account request)');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('guest_user',0,'Guests and external users without LDAP password (read-only)');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('internal',1,'Internal users without any other specified access (limited write access)');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('collab',1,'Collaborators (access only to generate submission records)');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('lab_admin',3,'Standard Lab Administrators');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('lab_user',2,'Standard Lab Techs');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('projects_admin',3,'Projects Admin');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('projects',2,'Projects staff');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('purchasing_admin',3,'Purchasing Administrators');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('purchasing',2,'Purchasing staff');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('bioinfo_admin',3,'Bioinformatics Admins');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('bioinfo',2,'Bioinformatics Staff (read-only)');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('qc_admin',3,'QC Administrators');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('qc',2,'QC staff');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('super_admin',4,'Administrators with special access to restricted fields');

## non-interface users ##
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('cron_user',1,'Connect to run read-only cron jobs (very limited write access - eg notification tracking)');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('super_cron_user',5,'Connect to run cron jobs (including full database restore)');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('read_api',0,'Read only api access');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('write_api',1,'API with limited write access');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('super_api',2,'API with special write access to limited fields');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('bioinfoqc',2,'API with special write access to qc fields');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('manual_tester',2,'used for manual testing');
INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('unit_tester',2,'used for running unit tests');

UPDATE Grp, Department, DB_Login SET FK_DB_Login__ID = DB_Login_ID WHERE FK_Department__ID=Department_ID AND DB_User = 'lab_admin' AND Grp_Name like '% Admin';
UPDATE Grp, Department, DB_Login SET FK_DB_Login__ID = DB_Login_ID WHERE FK_Department__ID=Department_ID AND DB_User = 'LIMS_admin' AND Grp_Name like '% Admin' AND Department_Name like 'LIMS%';;
UPDATE Grp, Department, DB_Login SET FK_DB_Login__ID = DB_Login_ID WHERE FK_Department__ID=Department_ID AND DB_User = 'bioinfo_admin' AND Grp_Name like 'Bioinformatics Admin';
UPDATE Grp, Department, DB_Login SET FK_DB_Login__ID = DB_Login_ID WHERE FK_Department__ID=Department_ID AND DB_User = 'qc_admin' AND Grp_Name like 'QC Admin';
UPDATE Grp, Department, DB_Login SET FK_DB_Login__ID = DB_Login_ID WHERE FK_Department__ID=Department_ID AND DB_User = 'projects_admin' AND Grp_Name like 'Projects Admin';
UPDATE Grp, Department, DB_Login SET FK_DB_Login__ID = DB_Login_ID WHERE FK_Department__ID=Department_ID AND DB_User = 'purchasing_admin' AND Grp_Name like 'Receiving Admin';
UPDATE Grp, Department, DB_Login SET FK_DB_Login__ID = DB_Login_ID WHERE FK_Department__ID=Department_ID AND DB_User = 'qc' AND FK_DB_Login__ID IS NULL AND Department_Name like 'QC';
UPDATE Grp, Department, DB_Login SET FK_DB_Login__ID = DB_Login_ID WHERE FK_Department__ID=Department_ID AND DB_User = 'bioinfo' AND FK_DB_Login__ID IS NULL AND Department_Name like 'Bioinformatics';
UPDATE Grp, Department, DB_Login SET FK_DB_Login__ID = DB_Login_ID WHERE FK_Department__ID=Department_ID AND DB_User = 'projects' AND FK_DB_Login__ID IS NULL AND Department_Name like 'Projects_Admin';
UPDATE Grp, Department, DB_Login SET FK_DB_Login__ID = DB_Login_ID WHERE FK_Department__ID=Department_ID AND DB_User = 'purchasing' AND FK_DB_Login__ID IS NULL AND Department_Name like 'Receiving';

UPDATE Grp, Department, DB_Login SET FK_DB_Login__ID = DB_Login_ID WHERE FK_Department__ID=Department_ID AND DB_User = 'lab_user' AND FK_DB_Login__ID IS NULL AND Department_Name NOT IN ('Bioinformatics', 'Projects_Admin','QC','Receiving', 'Management', 'Systems', 'Public');  ## research lab users and onther standard users...

UPDATE Grp, Department, DB_Login SET FK_DB_Login__ID = DB_Login_ID WHERE FK_Department__ID=Department_ID AND DB_User = 'internal' AND FK_DB_Login__ID IS NULL AND Department_Name IN elet 'Management', 'Systems');  ## research lab users and onther standard users...

UPDATE Grp, DB_Login SET FK_DB_Login__ID = DB_Login_ID WHERE DB_User = 'read_only' AND FK_DB_Login__ID IS NULL;

DELETE FROM mysql.user where user in ('lab_admin','super_admin','unit_tester');  ## delete previously defined users
DELETE FROM mysql.db WHERE user in ('lab_admin','super_admin','unit_tester');   ## delete previously defined users
</DATA>
<CODE_BLOCK> 
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below
if (_check_block('new_users')) { 

    use SDB::DB_Access;
    
    print "*** Add DB users to mysql database (and append to login file) ***\n";

    my @new_db_users = ('LIMS_admin','login','internal', 'guest_user','collab','lab_user','lab_admin','super_admin','cron_user','super_cron_user','read_api','write_api','super_api','bioinfoqc','projects','projects_admin','purchasing','purchasing_admin','qc','qc_admin','bioinfo','bioinfo_admin','unit_tester','manual_tester','bioinfoqc');   ## full list of new db_users

    my ($s, $i, $u, $d) = ('Y','Y','Y','Y');  ### default to full privileges for now... 

    my $login_file = "$Configs{Home_dir}/versions/$Configs{version_name}/conf/mysql.login";
    my $debug = 1;
        foreach my $user (@new_db_users) {
            SDB::DB_Access::add_DB_user(-db_user=>$user, -password=>rand(1000), -privileges=>[$s,$i,$u,$d],-append_login_file=>$login_file, -dbc=>$dbc);
        }
}

</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
