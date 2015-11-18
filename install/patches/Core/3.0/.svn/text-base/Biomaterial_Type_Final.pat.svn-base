## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)


ALTER TABLE Source DROP Source_Type;

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

DELETE FROM DBField WHERE Field_Table = 'RNA_DNA_Source' and Field_Name IN ('Sample_Collection_Date','Storage_Medium','Storage_Medium_Quantity','Storage_Medium_Quantity_Units');
UPDATE Sample_Type set Sample_Type_Alias = Sample_Type WHERE Sample_Type_Alias = '' and FKParent_Sample_Type__ID IS NULL;

</DATA>
<CODE_BLOCK> 

</CODE_BLOCK>
<FINAL>
DELETE FROM DBField WHERE Field_Table = 'Source' and Field_Name IN ('Source_Type');
delete from DB_Form WHERE Parent_Field = 'Source_Type';
UPDATE DBField SET Field_Options = 'Mandatory'  WHERE Field_Table = 'Source' and Field_Name = 'FK_Sample_Type__ID'; 

</FINAL>
