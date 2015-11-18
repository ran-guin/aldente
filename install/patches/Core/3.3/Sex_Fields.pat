## Patch file to modify a database

<DESCRIPTION>
Modify sex fields and sync their values
</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
alter table Patient modify Patient_Sex enum('M','F','Male','Female','Unknown','N/A','Mixed','Hermaphrodite');
update Patient set Patient_Sex = 'Male' where Patient_Sex = 'M';
update Patient set Patient_Sex = 'Female' where Patient_Sex = 'F';
alter table Patient modify Patient_Sex enum('Male','Female','Unknown','N/A','Mixed','Hermaphrodite');
alter table Original_Source modify Sex enum('Male','Female','Unknown','N/A','Mixed','Hermaphrodite');
</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

</DATA>

<CODE_BLOCK> 

</CODE_BLOCK>
<FINAL>
</FINAL>
