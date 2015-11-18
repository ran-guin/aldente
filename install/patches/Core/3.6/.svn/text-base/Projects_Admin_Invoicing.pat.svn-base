## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

-Addition of tables and data used for Projects admin invoicing.
	-Addition of Invoiceable_Protocol, Invoice and Invoiceable_Work tables.
	-Insertion of Invoiceable_Protocol data corresponding to current protocols that can be Invoiceable.


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

DROP TABLE IF EXISTS Invoiceable_Protocol, Invoice, Invoiceable_Work;

/*Invoiceable Protocol*/
CREATE TABLE IF NOT EXISTS Invoiceable_Protocol (
	Invoiceable_Protocol_ID int(11) NOT NULL AUTO_INCREMENT,
	Invoiceable_Protocol_Name varchar(40) NOT NULL,
	Invoiceable_Protocol_Type ENUM('Upstream_Library_Construction','Library_Construction','Run') NOT NULL,
	FK_Lab_Protocol__ID int(11) NOT NULL,
	PRIMARY KEY (Invoiceable_Protocol_ID),	
	KEY (FK_Lab_Protocol__ID)
);


/*Invoice table should include:
    * Sent_Date
    * Total_Amount
    * Received_Amount
    * ref to Employee
    * ref to Contact
*/
CREATE TABLE IF NOT EXISTS Invoice (
	Invoice_ID int(11) NOT NULL AUTO_INCREMENT,
	Invoice_Sent_Date date NOT NULL,
	Invoice_Total_Amount Decimal(10,2) NOT NULL,
	Invoice_Received_Amount Decimal(10,2) NOT NULL,
	FK_Employee__ID int(11) NOT NULL,
	FK_Contact__ID int(11) NOT NULL,
	PRIMARY KEY (Invoice_ID),	
	KEY (FK_Employee__ID),
	KEY (FK_Contact__ID)
);


/*Invoiceable_Work should include:
    * ref to original SRC
    * ref to PLA actually prepped
    * ref to TRA (if applicable)
    * ref to Prep
    * ref to Invoiceable_Protocol
    * Indexed (applicable for pooled or sub-pooled samples. eg '8' if pooled or '1/8' if part of pooled sample)
    * Billable (Y/N)
    * ref to Invoice
    * ref to Work_Request
*/
CREATE TABLE IF NOT EXISTS Invoiceable_Work (
	Invoiceable_Work_ID int(11) NOT NULL AUTO_INCREMENT,	
	FK_Source__ID int(11) NOT NULL,
	FK_Plate__ID int(11) NOT NULL,
	FK_Tray__ID int(11) NULL,
	FK_Prep__ID int(11) NULL,
	FK_Invoiceable_Protocol__ID int(11) NOT NULL,
	FK_Invoice__ID int(11) NOT NULL,
	FK_Work_Request__ID int(11) NULL,
	FKParent_Invoiceable_Work__ID int(11) NULL,
	Indexed int(11) NULL,
	Invoiceable_Work_Comments text NULL,	
	Billable ENUM('Y','N') NOT NULL Default 'Y',
	FK_Run__ID int(11) NULL,
	PRIMARY KEY (Invoiceable_Work_ID),	
	KEY (FK_Source__ID),
	KEY (FK_Plate__ID),
	KEY (FK_Tray__ID),
	KEY (FK_Prep__ID),
	KEY (FK_Invoiceable_Protocol__ID),
	KEY (FK_Invoice__ID),
	KEY (FK_Work_Request__ID),
	KEY (FKParent_Invoiceable_Work__ID),
	KEY (FK_Run__ID)
);


</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

/* Data entry for Invoiceable Protocol table*/
INSERT INTO Invoiceable_Protocol (Invoiceable_Protocol_Name, FK_Lab_Protocol__ID, Invoiceable_Protocol_Type)

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

UPDATE DBField SET Field_Reference = 'CASE WHEN Indexed > 0 THEN CONCAT(Invoiceable_Protocol_Name,\' - (1/\',Indexed,\')\') ELSE Invoiceable_Protocol.Invoiceable_Protocol_Name END' WHERE Field_Table = 'Invoiceable_Work' AND Field_Name = 'Invoiceable_Work_ID';

UPDATE DBField SET Field_Reference = 'Invoiceable_Protocol_Name' WHERE Field_Table = 'Invoiceable_Protocol' AND Field_Name = 'Invoiceable_Protocol_ID';

</FINAL>
