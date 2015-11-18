## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

-Addition of tables and data used for Projects admin invoicing.
	-Addition of Invoice_Run_Type, Invoice_Protocol, Invoice_Analysis_Step, Invoice Invoiceable_Run, Invoiceable_Prep, and Invoiceable_Analysis tables.
	-Insertion of Invoice Protocol data corresponding to current protocols that can be Invoiceable.


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

/*Drop older Invoicing tables */
DROP TABLE IF EXISTS Invoiceable_Protocol, Invoice, Invoiceable_Work;

/*Drop new tables for overide*/
DROP TABLE IF EXISTS Invoice_Run_Type, Invoice_Protocol, Invoice_Analysis_Step, Invoice, Invoiceable_Run, Invoiceable_Prep, Invoiceable_Analysis;

/*Start creating tables*/
/*Invoiceable Types*/
CREATE TABLE IF NOT EXISTS Invoice_Run_Type (
	Invoice_Run_Type_ID int(11) NOT NULL AUTO_INCREMENT,
	Invoice_Run_Type_Name varchar(40) NOT NULL,		
	PRIMARY KEY (Invoice_Run_Type_ID)
);

CREATE TABLE IF NOT EXISTS Invoice_Protocol (
	Invoice_Protocol_ID int(11) NOT NULL AUTO_INCREMENT,
	Invoice_Protocol_Name varchar(40) NOT NULL,
	Invoice_Protocol_Type ENUM('Upstream_Library_Construction','Library_Construction') NOT NULL,
	FK_Lab_Protocol__ID int(11) NOT NULL,
	PRIMARY KEY (Invoice_Protocol_ID),	
	KEY (FK_Lab_Protocol__ID)
);

CREATE TABLE IF NOT EXISTS Invoice_Analysis_Step (
	Invoice_Analysis_Step_ID int(11) NOT NULL AUTO_INCREMENT,
	Invoice_Analysis_Step_Name varchar(40) NOT NULL,	
	FK_Pipeline_Step__ID int(11) NOT NULL,	
	PRIMARY KEY (Invoice_Analysis_Step_ID),	
	KEY (FK_Pipeline_Step__ID)
);

/*Invoice Table*/
CREATE TABLE IF NOT EXISTS Invoice (
	Invoice_ID int(11) NOT NULL AUTO_INCREMENT,
	Invoice_Sent_Date date NOT NULL,
	Invoice_Total_Amount Decimal(10,2) NULL,
	Invoice_Received_Amount Decimal(10,2) NULL,
	Invoice_Comments text NULL,
	FK_Employee__ID int(11) NOT NULL,
	FK_Contact__ID int(11) NOT NULL,
	PRIMARY KEY (Invoice_ID),	
	KEY (FK_Employee__ID),
	KEY (FK_Contact__ID)
);


/*Invoiceable Works*/
CREATE TABLE IF NOT EXISTS Invoiceable_Run (
	Invoiceable_Run_ID int(11) NOT NULL AUTO_INCREMENT,	
	FK_Source__ID int(11) NOT NULL,
	FK_Plate__ID int(11) NOT NULL,
	FK_Tray__ID int(11) NULL,
	FK_Run__ID int(11) NOT NULL,
	FK_Invoice_Run_Type__ID int(11) NOT NULL,
	FK_Invoice__ID int(11) NULL,
	FK_Work_Request__ID int(11) NULL,
	FKParent_Invoiceable_Run__ID int(11) NULL,
	Indexed int(11) NULL,
	Invoiceable_Run_Comments text NULL,	
	Billable ENUM('Yes','No') NOT NULL Default 'Yes',
	PRIMARY KEY (Invoiceable_Run_ID),	
	KEY (FK_Source__ID),
	KEY (FK_Plate__ID),
	KEY (FK_Tray__ID),
	KEY (FK_Run__ID),
	KEY (FK_Invoice_Run_Type__ID),
	KEY (FK_Invoice__ID),
	KEY (FK_Work_Request__ID),
	KEY (FKParent_Invoiceable_Run__ID)
);

CREATE TABLE IF NOT EXISTS Invoiceable_Prep (
	Invoiceable_Prep_ID int(11) NOT NULL AUTO_INCREMENT,	
	FK_Source__ID int(11) NOT NULL,
	FK_Plate__ID int(11) NOT NULL,
	FK_Tray__ID int(11) NULL,
	FK_Prep__ID int(11) NOT NULL,
	FK_Invoice_Protocol__ID int(11) NOT NULL,
	FK_Invoice__ID int(11) NULL,
	FK_Work_Request__ID int(11) NULL,
	FKParent_Invoiceable_Prep__ID int(11) NULL,
	Indexed int(11) NULL,
	Invoiceable_Prep_Comments text NULL,	
	Billable ENUM('Yes','No') NOT NULL Default 'Yes',
	PRIMARY KEY (Invoiceable_Prep_ID),	
	KEY (FK_Source__ID),
	KEY (FK_Plate__ID),
	KEY (FK_Tray__ID),
	KEY (FK_Prep__ID),
	KEY (FK_Invoice_Protocol__ID),
	KEY (FK_Invoice__ID),
	KEY (FK_Work_Request__ID),
	KEY (FKParent_Invoiceable_Prep__ID)
);

CREATE TABLE IF NOT EXISTS Invoiceable_Analysis (
	Invoiceable_Analysis_ID int(11) NOT NULL AUTO_INCREMENT,	
	FK_Source__ID int(11) NOT NULL,
	FK_Plate__ID int(11) NOT NULL,
	FK_Tray__ID int(11) NULL,
	FK_Run__ID int(11) NOT NULL,
	FK_Analysis_Step__ID int(11) NOT NULL,
	FK_Invoice_Analysis_Step__ID int(11) NOT NULL,
	FK_Invoice__ID int(11) NULL,
	FK_Work_Request__ID int(11) NULL,
	FKParent_Invoiceable_Analysis__ID int(11) NULL,
	Indexed int(11) NULL,
	Invoiceable_Analysis_Comments text NULL,	
	Billable ENUM('Yes','No') NOT NULL Default 'Yes',
	PRIMARY KEY (Invoiceable_Analysis_ID),
	KEY (FK_Source__ID),
	KEY (FK_Plate__ID),
	KEY (FK_Tray__ID),
	KEY (FK_Run__ID),
	KEY (FK_Analysis_Step__ID),
	KEY (FK_Invoice_Analysis_Step__ID),
	KEY (FK_Invoice__ID),
	KEY (FK_Work_Request__ID),
	KEY (FKParent_Invoiceable_Analysis__ID)
);


</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

/* Data entry for Invoice Protocol table*/
INSERT INTO Invoice_Protocol (Invoice_Protocol_Name, FK_Lab_Protocol__ID, Invoice_Protocol_Type)

/*Index_PCR_Indexing*/
SELECT 'Plate Based', LP.Lab_Protocol_ID, 'Upstream_Library_Construction' FROM Lab_Protocol LP WHERE LP.Lab_Protocol_Name = 'Index_PCR_Indexing'

/*SLX 96well miRNA3 Brews*/
UNION
SELECT 'Plate Based miRNA', LP.Lab_Protocol_ID, 'Upstream_Library_Construction' FROM Lab_Protocol LP WHERE LP.Lab_Protocol_Name = 'SLX 96well miRNA3 Brews'

/*PET PCR*/
UNION
SELECT 'Tube Based', LP.Lab_Protocol_ID, 'Upstream_Library_Construction' FROM Lab_Protocol LP WHERE LP.Lab_Protocol_Name = 'PET PCR'

/*miRNA3 Tube*/
UNION
SELECT 'Tube Based miRNA', LP.Lab_Protocol_ID, 'Upstream_Library_Construction' FROM Lab_Protocol LP WHERE LP.Lab_Protocol_Name = 'miRNA3 Tube'

/*Off Site Constructed Samples */
UNION
SELECT 'Offsite', LP.Lab_Protocol_ID, 'Upstream_Library_Construction' FROM Lab_Protocol LP WHERE LP.Lab_Protocol_Name = 'Off Site Constructed Samples'

/*Illumina Concentration Checked */
UNION
SELECT 'Tube Based', LP.Lab_Protocol_ID, 'Library_Construction' FROM Lab_Protocol LP WHERE LP.Lab_Protocol_Name = 'Illumina Concentration Checked'

/*Index_QC_Qubit_8nM_Final_Product  */
UNION
SELECT 'Plate Based', LP.Lab_Protocol_ID, 'Library_Construction' FROM Lab_Protocol LP WHERE LP.Lab_Protocol_Name = 'Index_QC_Qubit_8nM_Final_Product'

/*Offsite_Illumina_Concentration_Checked */
UNION
SELECT 'Offsite', LP.Lab_Protocol_ID, 'Library_Construction' FROM Lab_Protocol LP WHERE LP.Lab_Protocol_Name = 'Offsite_Illumina_Concentration_Checked';



</DATA>
<CODE_BLOCK> 
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below
if (_check_block('backfill_invoiceable_work_table')) { 
    
}

</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


/*Field reference for Invoice Prep*/
UPDATE DBField SET Field_Reference = 'CASE WHEN Indexed > 0 THEN CONCAT(Invoice_Protocol_Name,\' - (1/\',Indexed,\')\') ELSE Invoice_Protocol.Invoice_Protocol_Name END' WHERE Field_Table = 'Invoiceable_Prep' AND Field_Name = 'Invoiceable_Prep_ID';

UPDATE DBField SET Field_Reference = 'Invoice_Protocol_Name' WHERE Field_Table = 'Invoice_Protocol' AND Field_Name = 'Invoice_Protocol_ID';

/*Field reference for Invoice Run*/
UPDATE DBField SET Field_Reference = 'CASE WHEN Indexed > 0 THEN CONCAT(Invoice_Run_Type_Name,\' - (1/\',Indexed,\')\') ELSE Invoice_Run_Type.Invoice_Run_Type_Name END' WHERE Field_Table = 'Invoiceable_Run' AND Field_Name = 'Invoiceable_Run_ID';

UPDATE DBField SET Field_Reference = 'Invoice_Run_Type_Name' WHERE Field_Table = 'Invoice_Run_Type' AND Field_Name = 'Invoice_Run_Type_ID';


/*Field reference for Invoice Analysis*/
UPDATE DBField SET Field_Reference = 'CASE WHEN Indexed > 0 THEN CONCAT(Invoice_Analysis_Step_Name,\' - (1/\',Indexed,\')\') ELSE Invoice_Analysis_Step.Invoice_Analysis_Step_Name END' WHERE Field_Table = 'Invoiceable_Analysis' AND Field_Name = 'Invoiceable_Analysis_ID';

UPDATE DBField SET Field_Reference = 'Invoice_Analysis_Step_Name' WHERE Field_Table = 'Invoice_Analysis_Step' AND Field_Name = 'Invoice_Analysis_Step_ID';


</FINAL>
