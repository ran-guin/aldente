## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Adding invoiceable pipelines to Invoice_Pipeline table in order to track invoiceable run analyses
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
INSERT INTO Invoice_Pipeline (Invoice_Pipeline_Name, FK_Pipeline__ID)
VALUES  ('Analysis of externally generated data', 262),
        ('Genome/exome SNV analysis', 263),
        ('Gene Expression Quantification', 264),
        ('QC - RNA Coverage metrics', 265),
        ('Exon-exon junction support', 266),
        ('ChIP Seq Analysis', 267),
        ('LOH and CNV Analysis', 268),
        ('Transcriptome (RNA-Seq) SNV analysis', 270),
        ('Transcriptome Assembly (Trans-ABySS)', 271),
        ('miRNA expression analysis', 272),
        ('miRNA novel gene prediction', 273),
        ('miRNA differential expression', 274),
        ('RNA-Seq isoform-level expression', 275),
        ('RNA-Seq differential expression', 276),
        ('Analysis of Bisulphite genomes', 277),
        ('Sequence re-alignment', 278),
        ('Microbial detection', 279),
        ('Genome Assembly', 280),
        ('Genome Validator', 281);
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

 
