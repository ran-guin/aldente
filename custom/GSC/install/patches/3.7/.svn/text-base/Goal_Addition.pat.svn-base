## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
insert into Attribute values (NULL, 'SNP Analysis Completed', '', 'Int', 37, 'No','Library','Editable');
insert into Attribute values (NULL, 'Indel Analysis Completed', '', 'Int', 37, 'No','Library','Editable');
insert into Attribute values (NULL, 'Visualization Analysis Completed', '', 'Int', 37, 'No','Library','Editable');
insert into Attribute values (NULL, 'LOH Analysis Completed', '', 'Int', 37, 'No','Library','Editable');
insert into Attribute values (NULL, 'CNV Analysis Completed', '', 'Int', 37, 'No','Library','Editable');
insert into Attribute values (NULL, 'Coverage Analysis Completed', '', 'Int', 37, 'No','Library','Editable');
insert into Attribute values (NULL, 'Structural Variation Analysis Completed', '', 'Int', 37, 'No','Library','Editable');
insert into Attribute values (NULL, 'Assembly Analysis Completed', '', 'Int', 37, 'No','Library','Editable');


insert into Goal values (NULL, 'SNP Analysis','Bioinformatics SNP analysis','','Library,Library_Attribute as SNP_Status,Attribute as SNP_Analysis','SNP_Status.Attribute_Value',"Library_Name = SNP_Status.FK_Library__Name and SNP_Status.FK_Attribute__ID = SNP_Analysis.Attribute_ID and SNP_Analysis.Attribute_Name = 'SNP Analysis Completed' and Library_Name = '<LIBRARY>'",'Data Analysis');
insert into Goal values (NULL, 'Indel Analysis','Bioinformatics Indel analysis','','Library,Library_Attribute as Indel_Status,Attribute as Indel_Analysis','Indel_Status.Attribute_Value',"Library_Name = Indel_Status.FK_Library__Name and Indel_Status.FK_Attribute__ID = Indel_Analysis.Attribute_ID and Indel_Analysis.Attribute_Name = 'Indel Analysis Completed' and Library_Name = '<LIBRARY>'",'Data Analysis');
insert into Goal values (NULL, 'Visualizion Analysis','Bioinformatics Visualization analysis','','Library,Library_Attribute as Vis_Status,Attribute as Vis_Analysis','Vis_Status.Attribute_Value',"Library_Name = Vis_Status.FK_Library__Name and Vis_Status.FK_Attribute__ID = Vis_Analysis.Attribute_ID and Vis_Analysis.Attribute_Name = 'Visualization Analysis Completed' and Library_Name = '<LIBRARY>'",'Data Analysis');
insert into Goal values (NULL, 'LOH Analysis','Bioinformatics LOH analysis','','Library,Library_Attribute as LOH_Status,Attribute as LOH_Analysis','LOH_Status.Attribute_Value',"Library_Name = LOH_Status.FK_Library__Name and LOH_Status.FK_Attribute__ID = LOH_Analysis.Attribute_ID and LOH_Analysis.Attribute_Name = 'LOH Analysis Completed' and Library_Name = '<LIBRARY>'",'Data Analysis');
insert into Goal values (NULL, 'CNV Analysis','Bioinformatics CNV analysis','','Library,Library_Attribute as CNV_Status,Attribute as CNV_Analysis','CNV_Status.Attribute_Value',"Library_Name = CNV_Status.FK_Library__Name and CNV_Status.FK_Attribute__ID = CNV_Analysis.Attribute_ID and CNV_Analysis.Attribute_Name = 'CNV Analysis Completed' and Library_Name = '<LIBRARY>'",'Data Analysis');
insert into Goal values (NULL, 'Coverage Analysis','Bioinformatics Coverage analysis','','Library,Library_Attribute as COV_Status,Attribute as COV_Analysis','COV_Status.Attribute_Value',"Library_Name = COV_Status.FK_Library__Name and COV_Status.FK_Attribute__ID = COV_Analysis.Attribute_ID and COV_Analysis.Attribute_Name = 'Coverage Analysis Completed' and Library_Name = '<LIBRARY>'",'Data Analysis');
insert into Goal values (NULL, 'Structural Variation Analysis','Bioinformatics Structural Variation analysis','','Library,Library_Attribute as SV_Status,Attribute as SV_Analysis','SV_Status.Attribute_Value',"Library_Name = SV_Status.FK_Library__Name and SV_Status.FK_Attribute__ID = SV_Analysis.Attribute_ID and SV_Analysis.Attribute_Name = 'Structural Variation Analysis Completed' and Library_Name = '<LIBRARY>'",'Data Analysis');
insert into Goal values (NULL, 'Assembly Variation Analysis','Bioinformatics Assembly analysis','','Library,Library_Attribute as AS_Status,Attribute as AS_Analysis','AS_Status.Attribute_Value',"Library_Name = AS_Status.FK_Library__Name and AS_Status.FK_Attribute__ID = AS_Analysis.Attribute_ID and AS_Analysis.Attribute_Name = 'Assembly Analysis Completed' and Library_Name = '<LIBRARY>'",'Data Analysis');
</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
