## Patch file to modify a database

<DESCRIPTION>

</DESCRIPTION>
<SCHEMA> 

alter Table ReArray_Attribute ADD  FK_Employee__ID int(11) default NULL;
alter Table ReArray_Attribute ADD  Set_DateTime datetime NOT NULL default '0000-00-00 00:00:00';
CREATE INDEX FK_Employee__ID on ReArray_Attribute (FK_Employee__ID);

alter Table Sample_Attribute ADD  FK_Employee__ID int(11) default NULL;
alter Table Sample_Attribute ADD  Set_DateTime datetime NOT NULL default '0000-00-00 00:00:00';
CREATE INDEX FK_Employee__ID on Sample_Attribute (FK_Employee__ID);




</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


</DATA>

<FINAL> 

</FINAL>
