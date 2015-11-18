## Patch file to modify a database

<DESCRIPTION> 
</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

alter table Organization modify Organization_Type set('Manufacturer','Collaborator','Vendor','Funding Source','Local','Sample Supplier','Data Repository') default Null;


</SCHEMA>
<DATA> 
insert into DB_Trigger values ('','Organization','Method','new_Organization_trigger','insert','Active','Does not allow more than one org which is local','Yes','');

</DATA>
<CODE_BLOCK> 
</CODE_BLOCK>
<FINAL>
</FINAL>
