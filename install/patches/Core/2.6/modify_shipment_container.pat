
<DESCRIPTION>
</DESCRIPTION>
<SCHEMA>
alter table Shipment modify Shipping_Container enum('Envelope', 'Bag', 'Plastic Bag', 'Cryoport' , 'Cardboard Box', 'Styrofoam Box') ;

update Shipment set Shipping_Container = 'Plastic Bag' where Shipping_Container = 'Bag';  

alter table Shipment modify Shipping_Container enum('Envelope', 'Plastic Bag', 'Cryoport' , 'Cardboard Box', 'Styrofoam Box') ;

</SCHEMA>
