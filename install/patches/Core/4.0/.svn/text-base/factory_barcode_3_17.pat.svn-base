## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
factory_barcode_3_17.pat

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Source ADD Factory_Barcode varchar(40) DEFAULT NULL;


</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

UPDATE Factory_Barcode, Source SET Factory_Barcode = Barcode_Value  WHERE FK_Object_Class__ID = 12 and Source_ID = Object_ID;
UPDATE  Attribute, Source_Attribute , Source SET Factory_Barcode = Attribute_Value  WHERE Attribute_Name = 'BioSpecimen_Barcode' AND FK_Source__ID = Source_ID AND FK_Attribute__ID = Attribute_ID AND  Factory_Barcode IS NULL;


</DATA>


<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
