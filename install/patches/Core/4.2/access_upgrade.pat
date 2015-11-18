## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE DB_Access drop Read_Access, drop Write_Access drop Delete_Access;
ALTER TABLE DB_Access ADD Select_priv enum('Y','N','X','I') NOT NULL DEFAULT 'N';
ALTER TABLE DB_Access ADD Insert_priv enum('Y','N','X','I') NOT NULL DEFAULT 'N';
ALTER TABLE DB_Access ADD Update_priv enum('Y','N','X','I') NOT NULL DEFAULT 'N';
ALTER TABLE DB_Access ADD Delete_priv enum('Y','N','X','I') NOT NULL DEFAULT 'N';

CREATE TABLE Access_Inclusion (
  Access_Inclusion_ID int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    FK_DBTable__ID int(11) NOT NULL,
      FK_DB_Access__ID int(11) NOT NULL,
        FK_DBField__ID int(11) DEFAULT NULL,
          Privilege set('Select','Insert','Update','Delete') NOT NULL
            ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

CREATE TABLE Access_Exclusion (
  Access_Exclusion_ID int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    FK_DBTable__ID int(11) NOT NULL,
      FK_DB_Access__ID int(11) NOT NULL,
        FK_DBField__ID int(11) DEFAULT NULL,
          Privilege set('Select','Insert','Update','Delete') NOT NULL
            ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


UPDATE DB_Access SET Select_priv = 'I' WHERE DB_Access_ID = 3;
UPDATE DB_Access SET Select_priv = 'Y' WHERE DB_Access_ID > 3;

UPDATE DB_Access SET Insert_priv = 'I' WHERE DB_Access_ID > 4;
UPDATE DB_Access SET Insert_priv = 'X' WHERE DB_Access_ID > 7;

UPDATE DB_Access SET Update_priv = 'I' WHERE DB_Access_ID > 4;
UPDATE DB_Access SET Update_priv = 'X' WHERE DB_Access_ID > 7;

UPDATE DB_Access SET Delete_priv = 'I' WHERE DB_Access_ID > 6;
UPDATE DB_Access SET Delete_priv = 'X' WHERE DB_Access_ID > 7;

UPDATE DB_Access SET Insert_priv = 'Y', Update_priv = 'Y', Delete_priv='Y' WHERE DB_Access_ID = 10;

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
