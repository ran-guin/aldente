## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Original_Source MODIFY COLUMN Original_Source_Type 
enum('Bacteria','Bodily_Fluid','Cell_Line','Exfoliate','Fungi','Invertebrate','Metagenomic','Mixed','Non_Biological','Plant','Solid_Tissue(Vertebrate)','Stem_Cell','Virus') DEFAULT NULL;

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)



</FINAL>
