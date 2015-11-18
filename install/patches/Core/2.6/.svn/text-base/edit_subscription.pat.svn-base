## Patch file to modify a database

<DESCRIPTION>

</DESCRIPTION>
<SCHEMA> 

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
Insert into `Trigger` values ('','Subscription_Event','Perl','require alDente::Subscription; my $ok = alDente::Subscription::new_Subscription_Event_trigger(-dbc=>$self);','insert','Active','Add info to Subscription table when a new event is created','No');


</DATA>

<FINAL> 
update DBField set Field_Options ='Mandatory' WHERE Field_Table = 'Subscription_Event' and Field_Name ='Subscription_Event_Name';
update DBField set Field_Options ='' WHERE Field_Table = 'Subscriber' and Field_Name ='FK_Grp__ID';
update DBField set Field_Options ='Mandatory' WHERE Field_Table = 'Subscriber' and Field_Name ='Subscriber_Type';

</FINAL>
