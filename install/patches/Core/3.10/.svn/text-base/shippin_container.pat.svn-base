## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

CREATE TABLE `Transport_Container` (
  `Transport_Container_ID` int(11) NOT NULL auto_increment,
  `Transport_Container_Name` varchar(40) NOT NULL,
  PRIMARY KEY  (`Transport_Container_ID`)
);
CREATE UNIQUE Index name ON Transport_Container (Transport_Container_Name);
ALTER TABLE Shipment ADD FK_Transport_Container__ID int(11) DEFAULT NULL;
INSERT INTO Transport_Container (select DISTINCT '',Shipping_Container from Shipment WHERE Shipping_Container <> '' and Shipping_Container IS NOT NULL);
UPDATE  Transport_Container, Shipment  set  FK_Transport_Container__ID = Transport_Container_ID  WHERE Shipping_Container = Transport_Container_Name;
ALTER TABLE Shipment DROP Shipping_Container;
DELETE from DBField WHERE Field_Name = 'Shipping_Container';


</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)



</FINAL>
