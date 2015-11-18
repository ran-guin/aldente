## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Create GrpPipeline table 
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
CREATE TABLE GrpPipeline (
  GrpPipeline_ID int(11) NOT NULL AUTO_INCREMENT,
  FK_Grp__ID int(11) NOT NULL DEFAULT '0',
  FK_Pipeline__ID int(11) NOT NULL DEFAULT '0',
  Grp_Access enum('Admin','Read-only') NOT NULL DEFAULT 'Admin',
  PRIMARY KEY (GrpPipeline_ID),
  UNIQUE KEY UniqueKey (FK_Grp__ID,FK_Pipeline__ID),
  KEY FK_Grp__ID (FK_Grp__ID),
  KEY FK_Pipeline__ID (FK_Pipeline__ID)
);
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
</CODE_BLOCK>

<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)
</FINAL>

 