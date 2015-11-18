## Patch file to modify a database

<DESCRIPTION>

## This will update Invoice_Protocol_Name as per request by the Projects team

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Invoice_Protocol MODIFY Invoice_Protocol_Name VARCHAR(80);

</SCHEMA> 
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

## Updates the Name

UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'Plate Based Library Construction' WHERE Invoice_Protocol_ID = 1;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'Plate Based Library Construction' WHERE Invoice_Protocol_ID = 2;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'Tube Based Library Construction' WHERE Invoice_Protocol_ID = 3;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'Tube Based miRNA Library Construction' WHERE Invoice_Protocol_ID = 4;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'Offsite Library Submission' WHERE Invoice_Protocol_ID = 5;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'Tube Based Library Construction' WHERE Invoice_Protocol_ID = 6;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'Plate Based Library Construction' WHERE Invoice_Protocol_ID = 7;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'Offsite Library Submission' WHERE Invoice_Protocol_ID = 8;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'PPGP Offsite Library' WHERE Invoice_Protocol_ID = 16;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'SPRI-TE' WHERE Invoice_Protocol_ID = 17;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'RNA Extraction' WHERE Invoice_Protocol_ID = 20;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'DNA Extraction' WHERE Invoice_Protocol_ID = 21;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'Plate Based miRNA Library Construction' WHERE Invoice_Protocol_ID = 22;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'Plate Based Strand Specific cDNA Generation' WHERE Invoice_Protocol_ID = 23;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'IP' WHERE Invoice_Protocol_ID = 24;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'Exome Capture' WHERE Invoice_Protocol_ID = 25;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'Plate Based Library Construction' WHERE Invoice_Protocol_ID = 26;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'Plate Based Library Construction' WHERE Invoice_Protocol_ID = 27;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'Agilent' WHERE Invoice_Protocol_ID = 28;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'Agilent' WHERE Invoice_Protocol_ID = 29;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'Caliper' WHERE Invoice_Protocol_ID = 30;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'RD Amplicon Generation' WHERE Invoice_Protocol_ID = 35;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'RD Shearing' WHERE Invoice_Protocol_ID = 36;
UPDATE Invoice_Protocol SET Invoice_Protocol_Name = 'RD Template Generation' WHERE Invoice_Protocol_ID = 37;

## Updating the Status

UPDATE Invoice_Protocol SET Invoice_Protocol_Status = 'Inactive' WHERE Invoice_Protocol_ID = 1;
UPDATE Invoice_Protocol SET Invoice_Protocol_Status = 'Inactive' WHERE Invoice_Protocol_ID = 2;
UPDATE Invoice_Protocol SET Invoice_Protocol_Status = 'Inactive' WHERE Invoice_Protocol_ID = 4;

## Adding new Protocols

INSERT INTO Invoice_Protocol (Invoice_Protocol_ID, Invoice_Protocol_Name, Invoice_Protocol_Type, FK_Lab_Protocol__ID, Tracked_Prep_Name, Invoice_Protocol_Status) VALUES (NULL, 'Plate Based cDNA Generation', 'Upstream_Library_Construction', 474, 'Completed Protocol', 'Active');
INSERT INTO Invoice_Protocol (Invoice_Protocol_ID, Invoice_Protocol_Name, Invoice_Protocol_Type, FK_Lab_Protocol__ID, Tracked_Prep_Name, Invoice_Protocol_Status) VALUES (NULL, 'Tube Based Poly A mRNA Purification', 'Upstream_Library_Construction', 571, 'Completed Protocol', 'Active');
INSERT INTO Invoice_Protocol (Invoice_Protocol_ID, Invoice_Protocol_Name, Invoice_Protocol_Type, FK_Lab_Protocol__ID, Tracked_Prep_Name, Invoice_Protocol_Status) VALUES (NULL, 'Tube Based cDNA Synthesis', 'Upstream_Library_Construction', 572, 'Completed Protocol', 'Active');
INSERT INTO Invoice_Protocol (Invoice_Protocol_ID, Invoice_Protocol_Name, Invoice_Protocol_Type, FK_Lab_Protocol__ID, Tracked_Prep_Name, Invoice_Protocol_Status) VALUES (NULL, 'Tube Based SMART cDNA Synthesis', 'Upstream_Library_Construction', 548, 'Completed Protocol', 'Active');
INSERT INTO Invoice_Protocol (Invoice_Protocol_ID, Invoice_Protocol_Name, Invoice_Protocol_Type, FK_Lab_Protocol__ID, Tracked_Prep_Name, Invoice_Protocol_Status) VALUES (NULL, 'Tube Based Ribominus', 'Upstream_Library_Construction', 460, 'Completed Protocol', 'Active');
INSERT INTO Invoice_Protocol (Invoice_Protocol_ID, Invoice_Protocol_Name, Invoice_Protocol_Type, FK_Lab_Protocol__ID, Tracked_Prep_Name, Invoice_Protocol_Status) VALUES (NULL, 'Custom Capture', 'Upstream_Library_Construction', 505, 'Completed Protocol', 'Active');

</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
