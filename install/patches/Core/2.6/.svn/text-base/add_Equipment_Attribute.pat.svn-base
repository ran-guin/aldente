## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Add a table named Equipment_Attribute
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
CREATE TABLE Equipment_Attribute ( FK_Equipment__ID int(11) NOT NULL default 0, FK_Attribute__ID int(11) NOT NULL default 0, Attribute_Value text NOT NULL, Equipment_Attribute_ID int(11) NOT NULL auto_increment, FK_Employee__ID int(11) default NULL, Set_DateTime datetime NOT NULL default '0000-00-00 00:00:00', PRIMARY KEY  (Equipment_Attribute_ID), UNIQUE KEY equipment_attribute (FK_Equipment__ID,FK_Attribute__ID), KEY FK_Equipment__ID (FK_Equipment__ID), KEY FK_Attribute__ID (FK_Attribute__ID) ) ENGINE=InnoDB DEFAULT CHARSET=latin1;

create index FK_Employee__ID on Equipment_Attribute (FK_Employee__ID);

</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
</DATA>


<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)
</FINAL>
