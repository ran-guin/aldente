## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

Add Run_QC_Alert and Multiplex_Run_QC_Alert 

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)


CREATE TABLE `Run_QC_Alert` (
  `Run_QC_Alert_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_Run__ID` int NOT NULL,
  `Alert_Type` enum('Notification', 'Redaction', 'Observation', 'CenterNotification', 'Rescission', 'QC Notification') NOT NULL,
  `FK_Alert_Reason__ID` int NOT NULL,
  `FK_Employee__ID` int NOT NULL,
  `Alert_Notification_Date` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `Alert_Comments` varchar(255) NOT NULL,
  PRIMARY KEY (`Run_QC_Alert_ID`),
  UNIQUE KEY `combine` (`FK_Run__ID`,`Alert_Type`,`FK_Alert_Reason__ID`),
  KEY `run_id` (`FK_Run__ID`)
) ;

CREATE TABLE `Multiplex_Run_QC_Alert` (
  `Multiplex_Run_QC_Alert_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_Multiplex_Run__ID` int NOT NULL,
  `Alert_Type` enum('Notification', 'Redaction', 'Observation', 'CenterNotification', 'Rescission', 'QC Notification') NOT NULL,
  `FK_Alert_Reason__ID` int NOT NULL,
  `FK_Employee__ID` int NOT NULL,
  `Alert_Notification_Date` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `Alert_Comments` varchar(255) NOT NULL,
  PRIMARY KEY (`Multiplex_Run_QC_Alert_ID`),
  UNIQUE KEY `combine` (`FK_Multiplex_Run__ID`,`Alert_Type`,`FK_Alert_Reason__ID`),
  KEY `multiplex_run_id` (`FK_Multiplex_Run__ID`)
) ;

## add QC Notification to Alert_Type
ALTER TABLE Alert_Reason modify Alert_Type enum('Notification', 'Redaction', 'Observation', 'CenterNotification', 'Rescission', 'QC Notification') NOT NULL; 

## add to Source Alert to keep consistent
ALTER TABLE Source_Alert modify Alert_Type enum('Notification', 'Redaction', 'Observation', 'CenterNotification', 'Rescission', 'QC Notification') NOT NULL;

</SCHEMA> 
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
INSERT INTO Alert_Reason VALUES( NULL, "QC_1", 'QC Notification', "Portion of read pairs having SMART linker sequence is higher than expected.");
INSERT INTO Alert_Reason VALUES( NULL, "QC_2", 'QC Notification', "Portion of read pairs having Whole Genome Amplification primer sequence is higher than expected.");
INSERT INTO Alert_Reason VALUES( NULL, "QC_3", 'QC Notification', "Portion of read pairs partially mapped to known reagent sequences is higher than expected.");
INSERT INTO Alert_Reason VALUES( NULL, "QC_4", 'QC Notification', "Portion of read pairs with short or empty inserts is higher than expected");
INSERT INTO Alert_Reason VALUES( NULL, "QC_5", 'QC Notification', "Portion of read pairs with adapter dimer is higher than expected.");
INSERT INTO Alert_Reason VALUES( NULL, "QC_6", 'QC Notification', "Portion of read pairs with rare artifact is higher than expected.");
INSERT INTO Alert_Reason VALUES( NULL, "QC_9", 'QC Notification', "Portion of 21bp tags mapped to human rRNA is higher than expected.");
INSERT INTO Alert_Reason VALUES( NULL, "QC_10", 'QC Notification', "Portion of 27bp tags mapped to mitochondrion DNA is higher than expected.");
INSERT INTO Alert_Reason VALUES( NULL, "QC_12", 'QC Notification', "Portion of 21bp tags mapped to an unexpected species is higher than expected.");
INSERT INTO Alert_Reason VALUES( NULL, "QC_13", 'QC Notification', "Portion of 18bp tags mapped to  miRNAs is lower than expected.");
INSERT INTO Alert_Reason VALUES( NULL, "QC_14", 'QC Notification', "Portion of reads not allocated to any  indices is higher than expected.");
INSERT INTO Alert_Reason VALUES( NULL, "QC_15", 'QC Notification', "Portion of poly Ns are higher than expected.");
INSERT INTO Alert_Reason VALUES( NULL, "QC_16", 'QC Notification', "Raw read yield is lower than 10% of expected.");

</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)



</FINAL>

 
