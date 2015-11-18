## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Updates Goal table (Goal_Tables, Goal_Count, Goal_Condition) on Goals with Goal_Type = Data Analysis to allow for goal tracking on invoiceable analyses
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
UPDATE Goal SET Goal_Tables = "Library LEFT JOIN Sample ON FK_Library__Name = Library_Name LEFT JOIN Multiplex_Run_Analysis MRA ON MRA.FK_Sample__ID = Sample_ID LEFT JOIN Run_Analysis RA ON (RA.Run_Analysis_ID = MRA.FK_Run_Analysis__ID OR RA.FK_Sample__ID = Sample_ID), Pipeline" WHERE Goal_Type = 'Data Analysis';

UPDATE Goal SET Goal_Count = 'COUNT(DISTINCT RA.Run_Analysis_ID)' WHERE Goal_Type = 'Data Analysis';

UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'Analysis of externally generated data' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 20;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'Genome/exome SNV analysis' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 21;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'Gene Expression Quantification' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 22;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'QC - RNA Coverage metrics' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 24;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'LOH and CNV Analysis' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 25;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'ChIP Seq Analysis' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 26;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'Transcriptome (RNA-Seq) SNV analysis' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 28;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'Transcriptome Assembly (Trans-ABySS)' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 29;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'miRNA expression analysis' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 30;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'miRNA novel gene prediction' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 31;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'miRNA differential expression' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 32;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'RNA-Seq isoform-level expression' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 33;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'RNA-Seq differential expression' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 34;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'Analysis of Bisulphite genomes' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 35;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'Sequence re-alignment' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 36;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'Microbial detection' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 37;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'Genome Assembly' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 38;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'Genome Validator' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 39;
UPDATE Goal SET Goal_Condition = "Library_Name='<LIBRARY>' AND Pipeline_ID = FKAnalysis_Pipeline__ID AND Pipeline_Name = 'Exon-exon junction support' AND Run_Analysis_Status = 'Analyzed'" WHERE Goal_ID = 66;


</DATA>

<CODE_BLOCK>
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below
</CODE_BLOCK>

<FINAL> 
## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)
</FINAL>

 
