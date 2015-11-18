## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

Creating a new Invoiceable_Work_Reference table


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

CREATE TABLE Invoiceable_Work_Reference(

Invoiceable_Work_Reference_ID INT NOT NULL AUTO_INCREMENT,
FK_Source__ID INT NOT NULL,
Indexed INT,
FKReferenced_Invoiceable_Work__ID INT,
FK_Invoice__ID INT,
Billable ENUM('Yes', 'No') NOT NULL DEFAULT 'Yes',
FKParent_Invoiceable_Work_Reference__ID INT,
Invoiceable_Work_Reference_Invoiced ENUM('Yes','No') NOT NULL DEFAULT 'No',

PRIMARY KEY (Invoiceable_Work_Reference_ID),
FOREIGN KEY (FK_Source__ID) REFERENCES Source (Source_ID),
FOREIGN KEY (FKParent_Invoiceable_Work_Reference__ID) REFERENCES Invoiceable_Work_Reference (Invoiceable_Work_Reference_ID),
FOREIGN KEY (FK_Invoice__ID) REFERENCES Invoice (invoice_ID),
FOREIGN KEY (FKReferenced_Invoiceable_Work__ID) REFERENCES Invoiceable_Work (Invoiceable_Work_ID)

);



</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

</DATA>
<CODE_BLOCK>

## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below
if (_check_block('NAME_GOES_HERE')) {

}
</CODE_BLOCK>

<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

</FINAL>
