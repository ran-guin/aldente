## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

Add Invoice_Pipeline & Invoiceable_Run_Analysis tables, drop Invoice_Analysis_Step & Invoiceable_Analysis tables, modify Invoiceable_Work & Invoiceable_Work_Reference, and set Invoice_Pipeline.Invoice_Pipeline_Status as trackble.

</DESCRIPTION>


<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

CREATE TABLE Invoice_Pipeline(

Invoice_Pipeline_ID INT NOT NULL AUTO_INCREMENT,
Invoice_Pipeline_Name VARCHAR(40),
Invoice_Pipeline_Status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',
FK_Pipeline__ID INT NOT NULL,

PRIMARY KEY (Invoice_Pipeline_ID),
FOREIGN KEY (FK_Pipeline__ID) REFERENCES Pipeline (Pipeline_ID)
);


CREATE TABLE Run_Analysis_Batch(

Run_Analysis_Batch_ID INT NOT NULL AUTO_INCREMENT,
Run_Analysis_Batch_RequestDateTime datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
FK_Employee__ID int(11) DEFAULT NULL,
Run_Analysis_Batch_Comments text,

PRIMARY KEY (Run_Analysis_Batch_ID),
FOREIGN KEY (FK_Employee__ID) REFERENCES Employee (Employee_ID)
);


CREATE TABLE Invoiceable_Run_Analysis(

Invoiceable_Run_Analysis_ID INT NOT NULL AUTO_INCREMENT,
FK_Run_Analysis__ID INT DEFAULT NULL,
FK_Multiplex_Run_Analysis__ID INT DEFAULT NULL,
FK_Invoice_Pipeline__ID INT NOT NULL,
FK_Invoiceable_Work__ID INT NOT NULL,

PRIMARY KEY (Invoiceable_Run_Analysis_ID),
FOREIGN KEY (FK_Run_Analysis__ID) REFERENCES Run_Analysis (Run_Analysis_ID),
FOREIGN KEY (FK_Multiplex_Run_Analysis__ID) REFERENCES Multiplex_Run_Analysis (Multiplex_Run_Analysis_ID),
FOREIGN KEY (FK_Invoice_Pipeline__ID) REFERENCES Invoice_Pipeline (Invoice_Pipeline_ID),
FOREIGN KEY (FK_Invoiceable_Work__ID) REFERENCES Invoiceable_Work (Invoiceable_Work_ID)
);


DROP TABLE IF EXISTS Invoice_Analysis_Step;
DROP TABLE IF EXISTS Invoiceable_Analysis;

ALTER TABLE Invoiceable_Work MODIFY Invoiceable_Work.FK_Plate__ID INT(11) NULL;  
ALTER TABLE Invoiceable_Work MODIFY Invoiceable_Work.FK_Tray__ID INT(11) NULL;    
ALTER TABLE Invoiceable_Work_Reference MODIFY Invoiceable_Work_Reference.FK_Source__ID INT(11) NULL;

ALTER TABLE Run_Analysis ADD FK_Run_Analysis_Batch__ID INT(11) NULL;

</SCHEMA>


<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
</DATA>


<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

UPDATE DBField SET Tracked = 'yes' WHERE Field_Name = 'Invoice_Pipeline_Status' AND Field_Table = 'Invoice_Pipeline';

</FINAL>
