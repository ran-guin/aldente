## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Increasing the size of the pipeline_code field from char(3) to varchar(10) and updating pipeline info/creating new pipelines/creating new pipeline-lib strategy relationships;
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
ALTER TABLE Pipeline MODIFY Pipeline_Code varchar(10) NOT NULL DEFAULT '';
</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
## Setting Pipelines to 'Inactive'
UPDATE Pipeline SET Pipeline_Status = 'Inactive' WHERE Pipeline_ID IN (261, 134, 4, 109, 192, 176, 3, 136, 135, 128, 126, 125, 122, 186, 137, 123, 163, 141, 140, 241, 182, 183, 206, 246, 218, 184, 245, 181, 127, 178, 250, 249, 244, 170, 285, 260, 251, 194, 179, 185, 180, 197, 124, 132, 153, 214, 220, 129);

## Updating Pipeline FK_Grp__ID, Name, Code, and Description
UPDATE Pipeline SET FK_Grp__ID = 9, Pipeline_Name = "gDNA", Pipeline_Code = "GDNA", Pipeline_Description = "Genomic DNA starting pipeline" WHERE Pipeline_ID = 138;
UPDATE Pipeline SET FK_Grp__ID = 9, Pipeline_Name = "GE", Pipeline_Code = "SGE", Pipeline_Description = "Gene Expression starting pipeline" WHERE Pipeline_ID = 121;
UPDATE Pipeline SET FK_Grp__ID = 9, Pipeline_Name = "WGA", Pipeline_Code = "WGA", Pipeline_Description = "Whole Genome Amplification starting pipeline" WHERE Pipeline_ID = 195;
UPDATE Pipeline SET FK_Grp__ID = 9, Pipeline_Name = "BAC Capture 1.0", Pipeline_Code = "BCP_1.0", Pipeline_Description = "BAC Capture production pipeline version 1.0" WHERE Pipeline_ID = 238;
UPDATE Pipeline SET FK_Grp__ID = 9, Pipeline_Name = "Ribominus RNA Seq 1.0", Pipeline_Code = "RRS_1.0", Pipeline_Description = "Ribominus production pipeline version 1.0" WHERE Pipeline_ID = 196;
UPDATE Pipeline SET FK_Grp__ID = 9, Pipeline_Name = "Tethered Conformation Capture 1.0", Pipeline_Code = "TCC_1.0", Pipeline_Description = "Tethered Conformation Capture production pipeline version 1.0" WHERE Pipeline_ID = 291;
UPDATE Pipeline SET FK_Grp__ID = 41, Pipeline_Name = "Ribozero RNA Seq 1.0", Pipeline_Code = "RBZ_1.0", Pipeline_Description = "Ribozero and Ribozero Gold TechD pipeline version 1.0" WHERE Pipeline_ID = 283;
UPDATE Pipeline SET FK_Grp__ID = 9, Pipeline_Name = "Illumina Indexing", Pipeline_Code = "IDX", Pipeline_Description = "Intermediate pipeline:  Illumina multiplexing" WHERE Pipeline_ID = 191;
UPDATE Pipeline SET FK_Grp__ID = 41, Pipeline_Name = "Synthetic Long Read", Pipeline_Code = "SLR", Pipeline_Description = "Intermediate pipeline:  Moleculo technology" WHERE Pipeline_ID = 316;
UPDATE Pipeline SET FK_Grp__ID = 9, Pipeline_Name = "PET", Pipeline_Code = "PET", Pipeline_Description = "Paired End Tags Pipeline" WHERE Pipeline_ID = 131;
UPDATE Pipeline SET FK_Grp__ID = 9, Pipeline_Name = "IPET", Pipeline_Code = "IPE", Pipeline_Description = "Index Paired End Tags Pipeline" WHERE Pipeline_ID = 177;
UPDATE Pipeline SET FK_Grp__ID = 9, Pipeline_Name = "TS", Pipeline_Code = "TS", Pipeline_Description = "Single End Tags Pipeline" WHERE Pipeline_ID = 130;
UPDATE Pipeline SET FK_Grp__ID = 9, Pipeline_Name = "ISE", Pipeline_Code = "ISE", Pipeline_Description = "Index Single End Tags Pipeline" WHERE Pipeline_ID = 190;
UPDATE Pipeline SET FK_Grp__ID = 9, Pipeline_Name = "TruSeq Paired End", Pipeline_Code = "TPE", Pipeline_Description = "TruSeq Paired End Pipeline" WHERE Pipeline_ID = 295;
UPDATE Pipeline SET FK_Grp__ID = 9, Pipeline_Name = "Index TruSeq Paired End", Pipeline_Code = "ITP", Pipeline_Description = "Index TruSeq Paired End Pipeline" WHERE Pipeline_ID = 293;
UPDATE Pipeline SET FK_Grp__ID = 9, Pipeline_Name = "Index Direct-Seq Paired End", Pipeline_Code = "IDP", Pipeline_Description = "2nd PCR pipeline requiring TruSeq indexing primer and custom 2nd PCR Foward and Reverse sequencing primers." WHERE Pipeline_ID = 296;
UPDATE Pipeline SET FK_Grp__ID = 9, Pipeline_Name = "Illumina PE Sequencing", Pipeline_Code = "PES", Pipeline_Description = "Illumina Paired End Bidirectional Sequencing Pipeline" WHERE Pipeline_ID = 139;
UPDATE Pipeline SET FK_Grp__ID = 9, Pipeline_Name = "Illumina Sequencing", Pipeline_Code = "SLS", Pipeline_Description = "Illumina Sequencing Pipeline" WHERE Pipeline_ID = 133;

## Inserting new Pipelines
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Amplicon Offsite", "AMP_OS", "Amplicon Pipeline for offsite constructed samples");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Amplicon 2.0", "AMP_2.0", "Amplicon production pipeline version 2.0; LIBPR.xxxx; VA.0321");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Bisulfite Offsite", "BIS_OS", "Bisulfite Pipeline for offsite constructed samples");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Bisulfite 1.0", "BIS_1.0", "Bisulfite production pipeline version 1.0; LIBPR.0091");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Exome Capture Offsite", "EXC_OS", "Exome Capture Pipeline for offsite constructed samples");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Exome Capture 2.0", "EXC_2.0", "Exome Capture production pipeline version 2.0; LIBPR.xxxx; LIBPR.0094; VA.0276");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "ChIP Offsite", "CHP_OS", "ChIP pipeline for offsite constructed samples");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "ChIP 2.0", "CHP_2.0", "ChIP production pipeline version 2.0; Biomek LIBPR.xxxx; VA.0276");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Genome Shotgun Offsite", "GSH_OS", "Genome Shotgun pipeline for offsite constructed samples");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Genome Shotgun PCRFree 1.0", "GPF_1.0", "PCR Free Genome Shotgun production pipeline version 1.0; LIBPR.0095 - Biomek; LIBPR.0101 - Manual;  VA.0203");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Genome Shotgun Large Gap 2.0", "GLG_2.0", "Large Gap Genome Shotgun production pipeline version 2.0; LIBPR.xxxx - Biomek; LIBPR.xxxx - Manual; VA.0276");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Genome Shotgun Small Gap 2.0", "GSG_2.0", "Small Gap Genome Shotgun production pipeline version 2.0; LIBPR.xxxx - Biomek; LIBPR.xxxx - Manual; VA.0276");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Genome Shotgun FFPE 1.0", "GFFPE_1.0", "FFPE Genome Shotgun production pipeline version 1.0; LIBPR.0110 - Biomek; LIBPR.0109 - Manual");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Genome Shotgun Mate Pair 1.0", "GMP_1.0", "Mate Pair Genome Shotgun production pipeline version 1.0; LIBPR.0098; VA.0221");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Genome Low Input 1.0", "GLI_1.0", "Low input Genome Shotgun production pipeline version 1.0; LIBPR.xxxx; VA.xxxx");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Transcriptome Offsite", "TRA_OS", "Transcriptome Pipeline for offsite constructed samples");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Strand Specific Transcriptome 2.0", "SSTRA_2.0", "Strand Specific Transcriptome production pipeline version 2.0; cDNA synthesis LIBPR.xxxx - Biomek, LIBPR.xxxx - Manual; library construction LIBPR.xxxx - Biomek, LIBPR.xxxx - Manual; VA.xxxx");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Transcriptome Small Gap 2.0", "TRA_2.0", "Transcriptome production pipeline version 2.0; cDNA synthesis LIBPR.0028; library construction  LIBPRxxxx; VA.0276");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Transcriptome Lite Offsite", "TLI_OS", "Transcriptome Lite pipeline for offsite constructed samples");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Transcriptome Lite 2.0", "TLI_2.0", "Transcriptome Lite production pipeline version 2.0; SMART cDNA synthesis  LIBPR.0112; library construction LIBPR.xxxx; VA.0276");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Specific Capture Offsite", "SPC_OS", "Specific Capture pipeline for offsite constructed samples");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "Specific Capture 2.0", "SPC_2.0", "Specific Capture production pipeline version 2.0; library construction LIBPR.xxxx; multiplex capture LIBPR.0094; VA.0276");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "miRNA Offsite", "MIR_OS", "miRNA Pipeline for offsite constructed samples");
INSERT INTO Pipeline(FK_Grp__ID, Pipeline_Name, Pipeline_Code, Pipeline_Description) VALUES (9, "miRNA 3.0", "MIR_3.0", "miRNA production pipeline version 3.0; LIBPR.0054");

## Inserting relationships between Pipelines and Library Strategy
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "AMP_OS"),9);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "AMP_2.0"),9);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "BIS_OS"),10);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "BIS_1.0"),10);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "EXC_OS"),14);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "EXC_2.0"),14);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "CHP_OS"),1);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "CHP_2.0"),1);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "GSH_OS"),3);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "GPF_1.0"),3);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "GLG_2.0"),3);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "GSG_2.0"),3);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "GFFPE_1.0"),3);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "GMP_1.0"),3);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "GLI_1.0"),3);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "TRA_OS"),6);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "SSTRA_2.0"),6);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "TRA_2.0"),6);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "TLI_OS"),6);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "TLI_2.0"),6);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "SPC_OS"),19);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "SPC_2.0"),19);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "MIR_OS"),5);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "MIR_3.0"),5);
INSERT INTO Library_Strategy_Pipeline(FK_Pipeline__ID, FK_Library_Strategy__ID) VALUES ((SELECT Pipeline_ID FROM Pipeline WHERE Pipeline_Code = "RBZ_1.0"),6);
</DATA>

<CODE_BLOCK>

## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below
</CODE_BLOCK>

<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)
</FINAL>

 
