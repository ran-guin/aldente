## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

CREATE TABLE `DB_Access` (
  `DB_Access_ID` tinyint(4) NOT NULL AUTO_INCREMENT,
    `DB_Access_Title` varchar(255) NOT NULL,
      `Read_Access` enum('Y','N') NOT NULL,
        `Write_Access` enum('Y','N') NOT NULL,
          `Delete_Access` enum('Y','N') NOT NULL,
            `Restriction_Type` enum('N/A','Specified Inclusions','Specified Exclusions') NOT NULL,
              `DB_Access_Description` text,
                PRIMARY KEY (`DB_Access_ID`),
                  UNIQUE KEY `title` (`DB_Access_Title`)
                  ) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1 ;


ALTER TABLE DB_Login 
  ADD FKProduction_DB_Access__ID INT NOT NULL,
  ADD FKnonProduction_DB_Access__ID INT NOT NULL;

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

INSERT INTO DB_Access VALUES 
(1,       'No Access',       'N',       'N',       'N',       'N/A',    'No Access to database')
,(2,       'Restricted Access',       'Y',       'N',       'N',       'Specified Inclusions',    'Highly restricted read access to specified list of tables')
,(3,       'Limited Read Access',     'Y',       'N',       'N',       'Specified Exclusions',    'Limited read access excluding specified list of tables')
,(4,       'Unlimited Read Access',   'Y',       'N',       'N',       'N/A',     'Unrestricted Read-Only Access')
,(5,       'Restricted R/W Access',   'Y',       'Y',       'N',       'Specified Inclusions',    'Highly restricted read / write access to specified list of tables')
,(6,       'Restricted Write Access', 'Y',       'Y',       'N',       'Specified Inclusions',    'Restricted write access to specified list of tables')
,(7,       'Limited Write Access',    'Y',       'Y',       'Y',       'Specified Exclusions',    'Limited write access excluding specified list of tables')
,(8,       'Expanded Write Access',   'Y',       'Y',       'Y',       'Specified Exclusions',    'Expanded write access excluding specified list of tables')
,(9,       'LIMS Staff Write Access', 'Y',       'Y',       'Y',       'Specified Exclusions',    'LIMS staff write access (may exclude certain tables)')
,(10,     'Root Access',    'Y',       'Y',       'Y',       'N/A',     'Unrestricted Access');

update DB_Login set FKProduction_DB_Access__ID = 2, FKnonProduction_DB_Access__ID = 2 WHERE DB_User in ('login');
update DB_Login set FKProduction_DB_Access__ID = 3, FKnonProduction_DB_Access__ID = 3 WHERE DB_User in ('guest_user','internal');
update DB_Login set FKProduction_DB_Access__ID = 4, FKnonProduction_DB_Access__ID = 4 WHERE DB_User in ('bioinfo','cron_user','read_api');
update DB_Login set FKProduction_DB_Access__ID = 5, FKnonProduction_DB_Access__ID = 5 WHERE DB_User in ('collab');
update DB_Login set FKProduction_DB_Access__ID = 6, FKnonProduction_DB_Access__ID = 6 WHERE DB_User in ('write_api','super_api','bioinfoqc','bioinfo_admin','cron_user','purchasing','projects','qc');
update DB_Login set FKProduction_DB_Access__ID = 7, FKnonProduction_DB_Access__ID = 7 WHERE DB_User in ('lab_user','purchasing_admin','qc_admin','projects_admin','super_cron_user');
update DB_Login set FKProduction_DB_Access__ID = 8, FKnonProduction_DB_Access__ID = 8 WHERE DB_User in ('lab_admin');
update DB_Login set FKProduction_DB_Access__ID = 9, FKnonProduction_DB_Access__ID = 9 WHERE DB_User in ('LIMS_admin','super_admin');
update DB_Login set FKProduction_DB_Access__ID = 10, FKnonProduction_DB_Access__ID = 10 WHERE DB_User in ('root','repl_client');

update DB_Login set FKProduction_DB_Access__ID = 4, FKnonProduction_DB_Access__ID = 8 WHERE DB_User in ('manual_tester','unit_tester');


</DATA>
<CODE_BLOCK> 
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below

</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
