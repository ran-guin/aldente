## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Open unopened solutions that have been used before.


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

create table fix_sol_1 select Solution_ID, Min(Prep_Datetime) as prepped, Solution_Status as sol_status,Solution_Started as started from Plate_Prep, Solution, Prep where FK_Prep__ID = Prep_ID and FK_Solution__ID = Solution_ID and Solution_Status = 'Unopened' group by Solution_ID;
create table fix_sol_2 select Solution_ID, Min(Prep_Datetime) as prepped, Solution_Status as sol_status,Solution_Started as started from Plate_Prep, Solution, Prep where FK_Prep__ID = Prep_ID and FK_Solution__ID = Solution_ID and Solution_Started > Prep_DateTime group by Solution_ID;
update Solution, fix_sol_1 SET Solution_Status = 'Open', Solution_Started = prepped WHERE Solution.Solution_ID=fix_sol_1.Solution_ID;
update Solution, fix_sol_2 SET Solution_Started = prepped WHERE Solution.Solution_ID=fix_sol_2.Solution_ID AND Solution_Started > prepped;
drop table fix_sol_1;
drop table fix_sol_2;

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
