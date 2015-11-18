## Patch file to modify a database

<DESCRIPTION>
Add more units for Brew calculators (ng and ng/uL)
</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
alter table Parameter modify Parameter_Units enum('ml','ul','ng','mg','ug','g','l','ng/uL','umoles','nmoles','pmoles');
</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

</DATA>

<CODE_BLOCK> 

</CODE_BLOCK>
<FINAL>
</FINAL>
