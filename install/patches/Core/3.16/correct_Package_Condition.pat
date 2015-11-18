## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Add column 'Sample_Condition' to Package_Condition table;
Update the Package_Condition entries;
Change Shipment.Shipping_Conditions to Expected_Shipping_Conditions 
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
ALTER TABLE Shipment ADD COLUMN Sample_Condition ENUM ('frozen', 'partially frozen', 'cold', 'room temp', 'warm', 'multiple conditions ' );
ALTER TABLE Shipment CHANGE COLUMN Shipping_Conditions Expected_Shipping_Conditions ENUM('Ambient Temperature','Cooled','Frozen');
</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
# add new entries to Package_Condition
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ('LN2 - cryoport');
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ('dry ice - sufficient');
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ('dry ice - low');
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ('dry ice - evaporated');
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ('ice/cold packs - frozen');
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ('ice/cold packs - partially melted');
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ('water/cold packs - fully melted (cold)');
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ('water/cold packs - fully melted (warm)');
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ('insulated no coolant - cool');
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ('insulated no coolant - room temp');
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ('insulated no coolant - warm');
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ('uninsulated - cool');
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ('uninsulated - room temp');
INSERT INTO Package_Condition (Package_Condition_Name) VALUES ('uninsulated - warm');

# update Shipment.FK_Package_Condition__ID
UPDATE Shipment,Package_Condition PC1, Package_Condition PC2 SET Shipment.FK_Package_Condition__ID = PC2.Package_Condition_ID, Shipment.Sample_Condition = 'frozen' WHERE FK_Package_Condition__ID = PC1.Package_Condition_ID and PC1.Package_Condition_Name = 'frozen - sufficient dry ice' and PC2.Package_Condition_Name = 'dry ice - sufficient';
UPDATE Shipment,Package_Condition PC1, Package_Condition PC2 SET Shipment.FK_Package_Condition__ID = PC2.Package_Condition_ID, Shipment.Sample_Condition = 'frozen' WHERE FK_Package_Condition__ID = PC1.Package_Condition_ID and PC1.Package_Condition_Name = 'frozen - cryoport temp ok' and PC2.Package_Condition_Name = 'LN2 - cryoport';
UPDATE Shipment,Package_Condition PC1, Package_Condition PC2 SET Shipment.FK_Package_Condition__ID = PC2.Package_Condition_ID, Shipment.Sample_Condition = 'cold' WHERE FK_Package_Condition__ID = PC1.Package_Condition_ID and PC1.Package_Condition_Name = 'refrigerated - wet ice' and PC2.Package_Condition_Name = 'ice/cold packs - frozen';
UPDATE Shipment,Package_Condition PC1, Package_Condition PC2 SET Shipment.FK_Package_Condition__ID = PC2.Package_Condition_ID, Shipment.Sample_Condition = 'frozen' WHERE FK_Package_Condition__ID = PC1.Package_Condition_ID and PC1.Package_Condition_Name = 'frozen - little dry ice' and PC2.Package_Condition_Name = 'dry ice - low';
UPDATE Shipment,Package_Condition PC1, Package_Condition PC2 SET Shipment.FK_Package_Condition__ID = PC2.Package_Condition_ID, Shipment.Sample_Condition = 'room temp' WHERE FK_Package_Condition__ID = PC1.Package_Condition_ID and PC1.Package_Condition_Name = 'room temp - ok' and PC2.Package_Condition_Name = 'uninsulated - room temp';
UPDATE Shipment,Package_Condition PC1, Package_Condition PC2 SET Shipment.FK_Package_Condition__ID = PC2.Package_Condition_ID, Shipment.Sample_Condition = 'cold' WHERE FK_Package_Condition__ID = PC1.Package_Condition_ID and PC1.Package_Condition_Name = 'refrigerated - on ice' and PC2.Package_Condition_Name = 'ice/cold packs - frozen';
UPDATE Shipment,Package_Condition PC1, Package_Condition PC2 SET Shipment.FK_Package_Condition__ID = PC2.Package_Condition_ID, Shipment.Sample_Condition = 'cold' WHERE FK_Package_Condition__ID = PC1.Package_Condition_ID and PC1.Package_Condition_Name = 'room temp - cool' and PC2.Package_Condition_Name = 'uninsulated - cool';
UPDATE Shipment,Package_Condition PC1, Package_Condition PC2 SET Shipment.FK_Package_Condition__ID = PC2.Package_Condition_ID, Shipment.Sample_Condition = 'warm' WHERE FK_Package_Condition__ID = PC1.Package_Condition_ID and PC1.Package_Condition_Name = 'room temp - warm' and PC2.Package_Condition_Name = 'uninsulated - warm';
UPDATE Shipment,Package_Condition PC1, Package_Condition PC2 SET Shipment.FK_Package_Condition__ID = PC2.Package_Condition_ID, Shipment.Sample_Condition = 'cold' WHERE FK_Package_Condition__ID = PC1.Package_Condition_ID and PC1.Package_Condition_Name = 'refrigerated - cold water' and PC2.Package_Condition_Name = 'water/cold packs - fully melted (cold)';
UPDATE Shipment,Package_Condition PC1, Package_Condition PC2 SET Shipment.FK_Package_Condition__ID = PC2.Package_Condition_ID, Shipment.Sample_Condition = 'frozen' WHERE FK_Package_Condition__ID = PC1.Package_Condition_ID and PC1.Package_Condition_Name = 'frozen - no dry ice' and PC2.Package_Condition_Name = 'dry ice - evaporated';
UPDATE Shipment,Package_Condition PC1, Package_Condition PC2 SET Shipment.FK_Package_Condition__ID = PC2.Package_Condition_ID, Shipment.Sample_Condition = 'frozen' WHERE FK_Package_Condition__ID = PC1.Package_Condition_ID and PC1.Package_Condition_Name = 'frozen - wet ice' and PC2.Package_Condition_Name = 'ice/cold packs - frozen';
UPDATE Shipment,Package_Condition PC1, Package_Condition PC2 SET Shipment.FK_Package_Condition__ID = PC2.Package_Condition_ID, Shipment.Sample_Condition = 'frozen' WHERE FK_Package_Condition__ID = PC1.Package_Condition_ID and PC1.Package_Condition_Name = 'refrigerated - cold packs-frozen' and PC2.Package_Condition_Name = 'ice/cold packs - frozen';
UPDATE Shipment,Package_Condition PC1, Package_Condition PC2 SET Shipment.FK_Package_Condition__ID = PC2.Package_Condition_ID, Shipment.Sample_Condition = 'cold' WHERE FK_Package_Condition__ID = PC1.Package_Condition_ID and PC1.Package_Condition_Name = 'refrigerated - cold packs-thawed cold' and PC2.Package_Condition_Name = 'water/cold packs - fully melted (cold)';
UPDATE Shipment,Package_Condition PC1, Package_Condition PC2 SET Shipment.FK_Package_Condition__ID = PC2.Package_Condition_ID, Shipment.Sample_Condition = 'multiple conditions' WHERE FK_Package_Condition__ID = PC1.Package_Condition_ID and PC1.Package_Condition_Name = 'multiple conditions' and PC2.Package_Condition_Name = 'multiple conditions';
UPDATE Shipment,Package_Condition PC1, Package_Condition PC2 SET Shipment.FK_Package_Condition__ID = PC2.Package_Condition_ID, Shipment.Sample_Condition = 'warm' WHERE FK_Package_Condition__ID = PC1.Package_Condition_ID and PC1.Package_Condition_Name = 'refrigerated - warm water' and PC2.Package_Condition_Name = 'water/cold packs - fully melted (warm)';

# remove old entries from Package_Condition
DELETE FROM Package_Condition WHERE Package_Condition_Name NOT IN ('LN2 - cryoport','dry ice - sufficient','dry ice - low','dry ice - evaporated','ice/cold packs - frozen','ice/cold packs - partially melted','water/cold packs - fully melted (cold)','water/cold packs - fully melted (warm)','insulated no coolant - cool','insulated no coolant - room temp','insulated no coolant - warm','uninsulated - cool','uninsulated - room temp','uninsulated - warm','multiple conditions');

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
update DBField set Field_Options = 'Mandatory' where Field_Table = 'Shipment' and Field_Name = 'Sample_Condition';
update DBField set Field_Options = '' where Field_Table = 'Shipment' and Field_Name = 'Expected_Shipping_Conditions';
UPDATE DBField set Field_Order = 8   WHERE Field_Table = 'Shipment' and Field_Name = 'Expected_Shipping_Conditions';
UPDATE DBField set Field_Order = 9   WHERE Field_Table = 'Shipment' and Field_Name = 'FK_Package_Condition__ID';
UPDATE DBField set Field_Order = 10   WHERE Field_Table = 'Shipment' and Field_Name = 'Sample_Condition';

</FINAL>
