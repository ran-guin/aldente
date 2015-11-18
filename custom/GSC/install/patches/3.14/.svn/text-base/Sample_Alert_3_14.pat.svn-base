## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

RENAME TABLE Sample_Alert_Reason to Alert_Reason; 
ALTER TABLE Alert_Reason CHANGE Sample_Alert_Reason_ID Alert_Reason_ID int(11)  NOT NULL auto_increment ;
ALTER TABLE Alert_Reason CHANGE Sample_Alert_Reason  Alert_Reason varchar(64) NOT NULL;
ALTER TABLE Alert_Reason CHANGE Sample_Alert_Type Alert_Type enum('Notification','Redaction','Observation','CenterNotification','Rescission') DEFAULT NULL;
ALTER TABLE Alert_Reason CHANGE Sample_Alert_Reason_Notes  Alert_Reason_Notes text NOT NULL;


CREATE TABLE `Source_Alert` (
  `Source_Alert_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_Source__ID` int NOT NULL,
  `Alert_Type` enum('Notification', 'Redaction', 'Observation', 'CenterNotification', 'Rescission') NOT NULL,
  `FK_Alert_Reason__ID` int NOT NULL,
  `FK_Employee__ID` int NOT NULL,
  `Alert_Notification_Date` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `Alert_Comments` varchar(255) NOT NULL,
  PRIMARY KEY (`Source_Alert_ID`),
  UNIQUE KEY `combine` (`FK_Source__ID`,`Alert_Type`,`FK_Alert_Reason__ID`)
  
) ;

</SCHEMA> 
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
INSERT INTO Source_Alert (SELECT '', Source_ID,   SA.Attribute_Value,  SAR.Attribute_Value, SAR.FK_Employee__ID, SAR.Set_DateTime, '' from Source LEFT JOIN Source_Attribute AS SA    ON SA.FK_Source__ID = Source_ID AND SA.FK_Attribute__ID = 386 LEFT JOIN Source_Attribute AS SAR  ON  SAR.FK_Source__ID = Source_ID AND SAR.FK_Attribute__ID = 387 WHERE (SA. Attribute_Value IS NOT NULL OR  SAR. Attribute_Value IS NOT NULL));


delete Source_Attribute  from Attribute, Source_Attribute WHERE Attribute_ID = FK_Attribute__ID and Attribute_Name IN ('Sample_Alert','Sample_Alert_Reason');
delete  from Attribute  WHERE Attribute_Name IN ('Sample_Alert','Sample_Alert_Reason');


</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

## MANDATORY type source reason


update DBField set Field_Options = 'Mandatory' where Field_Table = 'Source_Sample_Alert' AND Field_Name = 'FK_Source__ID';
update DBField set Field_Options = 'Mandatory' where Field_Table = 'Source_Sample_Alert' AND Field_Name = 'Alert_Type';
update DBField set Field_Options = 'Mandatory' where Field_Table = 'Source_Sample_Alert' AND Field_Name = 'FK_Reason__ID';


</FINAL>

 