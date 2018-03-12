--
-- If all you have is a hammer, maybe this looks like a nail !
--
-- An attempt to somehow solve the GOOGLE HASHCODE 2018 with sqlite3
-- It does give a simple solution to the problem.
-- Basically it sorts the booked rides by the "the earliest start",
-- uses a table to store the current car's booked ride info
-- then for each booked_ride choose the car that has/will finish a
-- previous ride closest to the start of the current assigning ride
-- if no car can arrive at least on the ("the latest finish" - the_ride_size)
-- we ignore it.
--
-- It outputs in the format required by the hashcode 2018 rules,
-- to a file named 'results.txt'.
--
-- This solution uses triggers on dummy views to emulate stored procedures,
-- and only requires a recent sqlite3 executable and data files to work on.
--
-- By no means I claim that solutions like this (stretching sqlite3) are
-- good practice. Take it as an example that demonstrates several
-- capabilities of sqlite3 in a hack/compact way.
--
-- It works with a memory database unless you supply a database name
-- when invoking it:
--
-- sqlite3 < hashcode2018.sql
--
-- or directing the output to a file:
--
-- sqlite3 < hashcode2018.sql > result.txt
--
-- With a disk database:
-- sqlite3 database_name.db < hashcode2018.sql
--
-- To process a specific data file look bellow after the 
-- creation of the table "booked_rides_tmp" for a line like:
--
--.import 'a_example.in' booked_rides_tmp
--
-- and edit it.
--
-- Author: Domingo Alvarez Duarte mingodad :at: gmail.com
--
-- License: Public domain as in sqlite3
--
-- Time spent till now: 48 hours (and several dream hours)
-- the time above includes a prototype using a scripting language
-- SquiLu (https://github.com/mingodad/squilu) around 38 hours
-- including a simple plot program to show the rides for a car step by step
--
-- Date: 2018-03-04 21:46
--

--sqlite3 shell command to set separator
.separator ' '

--to debug
--.trace 'trace.log'
--.timer on

--table to store the working limits
create table if not exists work_limits(
	rows integer, cols integer, cars integer,
	rides integer, bonus integer, steps integer
);

--temporary table to split the data later
create table if not exists booked_rides_tmp(
	x1 integer, y1 integer,
	x2 integer, y2 integer,
	ride_start integer, ride_end integer
);

--sqlite3 shell command to import data from text files
--
-- Edit bellow to use the data file you want to process
--
.import 'a_example.in' booked_rides_tmp
--.import 'b_should_be_easy.in' booked_rides_tmp
--.import 'c_no_hurry.in' booked_rides_tmp
--.import 'd_metropolis.in' booked_rides_tmp
--.import 'e_high_bonus.in' booked_rides_tmp
.h on

--get the first row that contains the working limits
insert into work_limits select * from booked_rides_tmp where rowid=1;
--remove the working limits
delete from booked_rides_tmp where rowid = 1;

--test/show the working limits
select * from work_limits;

--the final destination of the booked_rides
create table if not exists booked_rides(
	id integer primary key
	,x1 integer
	,y1 integer
	,x2 integer
	,y2 integer
	,ride_start integer
	,ride_end integer
	,assigned_car integer default 0
	,assigned_at_step integer
	,waiting_steps integer -- if positive the car need wait, negative the passenger need wait
	,distance_to_start integer -- car distance between last position to the start of the assigned ride
);
--insert the data from booked_rides_tmp fixing the base index rowid/id
insert into booked_rides(x1, y1, x2, y2, ride_start, ride_end)
	select x1, y1, x2, y2, ride_start, ride_end
	from booked_rides_tmp;

--we do not need the temp table anymore
drop table booked_rides_tmp;

--table to help distribute the rides to the available cars
create table if not exists cars(
	id integer primary key
	,x2 integer not null default 0
	,y2 integer not null default 0
	,ride_end integer not null default 0
	,ride_id integer
);

--add one record for each car to be used as scratch for ride assignement
WITH RECURSIVE
  cnt(x) AS (VALUES(1) UNION ALL SELECT x+1 FROM cnt WHERE x<(select cars from work_limits))
insert into cars(id) SELECT x FROM cnt;

--show/test what we've got with our hack
select ('Cars table has ' || count(*) || ' cars') cars_count from cars;

--store the assigned rides to cars to preserve assignment order
create table if not exists car_rides(
	id integer primary key,
	car_id integer not null,
	ride_id integer not null,
	unique(car_id, ride_id)
);

--some views to help on several tasks
--using nested selects to not repeat literal calculations
create view if not exists booked_rides_list_view AS
select tbl.*,
	(case when 
		(tbl.ride_start >= start_distance)
			or ((tbl.ride_end-tbl.ride_size) >= start_distance)
		then 1 else 0 end) possible
from (
	SELECT
		a.id,
		a.x1,
		a.y1,
		a.x2,
		a.y2,
		a.ride_start,
		a.ride_end,
		(abs(x1-x2) + abs(y1-y2)) ride_size,
		(ride_end - ride_start) max_time,
		a.assigned_car,
		a.assigned_at_step,
		a.distance_to_start,
		a.waiting_steps,
		(x1 + y1) start_distance
	FROM booked_rides AS a
	Order by ride_start, ride_size desc, start_distance
) tbl;

create view if not exists booked_rides_extended_list_view as
select *,
	(case when (waiting_steps > 0) then waiting_steps else 0 end) waiting_steps,
	(case when (waiting_steps < 0) then (-waiting_steps) else 0 end) delay_steps	
from booked_rides_list_view;

create view if not exists booked_rides_result_view AS
select 'all', count(*) count, sum(ride_size) total_size,
	sum(distance_to_start) total_between_rides,
	sum(waiting_steps) total_waiting_steps,
	sum(delay_steps) total_delay_steps	
from booked_rides_extended_list_view
union
select 'possible', count(*) count, sum(ride_size) total_size,
	sum(distance_to_start) total_between_rides,
	sum(waiting_steps) total_waiting_steps,
	sum(delay_steps) total_delay_steps	
from booked_rides_extended_list_view where possible=1
union
select 'assigned', count(*) count, sum(ride_size) total_size,
	sum(distance_to_start) total_between_rides,
	sum(waiting_steps) total_waiting_steps,
	sum(delay_steps) total_delay_steps	
from booked_rides_extended_list_view where assigned_car > 0
union
select 'ontime', count(*) count, sum(ride_size) total_size,
	sum(distance_to_start) total_between_rides,
	sum(waiting_steps) total_waiting_steps,
	sum(delay_steps) total_delay_steps	
from booked_rides_extended_list_view where assigned_car > 0 and ride_start=assigned_at_step;

create view if not exists car_stats_view as
select assigned_car, count(*) total_rides,
	max(assigned_at_step) max_assigned_at_step,
	sum(distance_to_start) total_distance_to_start,
	sum(waiting_steps) total_waiting_steps,
	sum(delay_steps) total_delay_steps	
from booked_rides_extended_list_view
group by assigned_car;

--calculate the score of the assigned rides
create view if not exists calculate_score_view as
select (select sum(ride_size) total_size
	from booked_rides_extended_list_view
	where assigned_car > 0)
	+ ((select count(*) count
		from booked_rides_extended_list_view
		where assigned_car > 0 and ride_start=assigned_at_step)
	* (select bonus from work_limits)) score;

--on each row: number_of_rides followed by a list of assigned rides, all separated by on space
--implicitly each row represents a car
-- car and rides are zero based (as required by the rules)
create view if not exists car_rides_result_list_view as
select
	(select count(*) || ' ' || group_concat(the_ride_id, ' ')
		from (select ride_id-1 the_ride_id -- the result want a zero based id
			from car_rides where car_id=a.id
			order by id
		) tbl
	) result_rides
from cars a
order by id;

--to debug
--select * from booked_rides_list_view limit 10;

--create some dummy views with triggers to emulate stored procedures

create table ride_assign_tmp_calculations(
	id integer primary key,
	--car_id integer, ride_id integer, --to debug
	distance_to_start integer not null default 0,
	new_car_end integer not null default 0,
	waiting_steps integer not null default 0,
	assigned_at_step integer not null default 0
);
--only to have one row to store temporary calculations
insert into ride_assign_tmp_calculations(id) values(1);

/*
--to debug
create table ride_assign_tmp_calculations_log(
	id integer primary key,
	car_id integer, ride_id integer, --to debug
	distance_to_start integer not null default 0,
	new_car_end integer not null default 0,
	waiting_steps integer not null default 0,
	assigned_at_step integer not null default 0
);
*/

create view if not exists find_nearest_available_car_view as
	select id, ride_end, x2, y2,
	1 as target_x1, 1 as target_y1,
	1 as target_x2, 1 as target_y2,
	1 as target_ride_id, 1 as target_ride_start,
	1 as target_ride_end , 1 as target_ride_size
	from cars;

create trigger if not exists find_nearest_available_car_trigger instead of update
	on find_nearest_available_car_view
begin
	-- old.* references cars record
	-- new.* references booked_ride record passed in dummy fields

	--hack simulation of variables using a dummy table

	--how far we are to the begining of the new ride ?
	update ride_assign_tmp_calculations set
		distance_to_start = (abs(new.target_x1-old.x2) + abs(new.target_y1-old.y2))
		--,car_id=old.id, ride_id=new.target_ride_id --to debug
	where id=1;

	--incrementally we'll be calculating the new_car_end
	update ride_assign_tmp_calculations set
		new_car_end = old.ride_end + distance_to_start
	where id=1;

	--will we need to wait to start the ride ontime ?
	--if result is negative we'll be late, passenger will need to wait
	update ride_assign_tmp_calculations set
		waiting_steps = new.target_ride_start - new_car_end
	where id=1;

	--if we need to wait let's add it to the new_car_end
	--time unit is equal to steps unit
	update ride_assign_tmp_calculations set
		new_car_end = new_car_end + waiting_steps
	where id=1 and waiting_steps > 0;

	--need be after check for waiting_steps
	update ride_assign_tmp_calculations set
		assigned_at_step = new_car_end
	where id=1;

	--now that we saved the assigned_at_step we upadate to the end of the ride
	update ride_assign_tmp_calculations set
		new_car_end = new_car_end + new.target_ride_size
	where id=1;

/*
	--to debug trigger
	insert into ride_assign_tmp_calculations_log(
			car_id, ride_id,
			distance_to_start, new_car_end, waiting_steps, assigned_at_step
		) select
			car_id, ride_id,
			distance_to_start, new_car_end, waiting_steps, assigned_at_step
		from ride_assign_tmp_calculations;
*/

	--now let's apply our calculations and assign the ride
	update booked_rides set
		assigned_car=old.id,
		assigned_at_step=(select assigned_at_step from ride_assign_tmp_calculations where id=1),
		waiting_steps=(select waiting_steps from ride_assign_tmp_calculations where id=1),
		distance_to_start=(select distance_to_start from ride_assign_tmp_calculations where id=1)
	where id=new.target_ride_id;
	
	update cars set
		ride_id=new.target_ride_id, x2=new.target_x2, y2=new.target_y2,
		ride_end=(select new_car_end from ride_assign_tmp_calculations where id=1)
	where id=old.id;

	insert into car_rides(car_id, ride_id) values(old.id, new.target_ride_id);
end;


--we are using instead of update to have access to all row fields
create view if not exists assign_rides_to_cars_view as
	select id, x1, y1, x2, y2, ride_start, ride_end , ride_size, 0 as dummy
	from booked_rides_list_view
	where possible=1;

--to debug trigger assign_rides_to_cars_trigger
--create table log_assign_rides_to_cars_trigger(ride_id integer, car_id integer);

create trigger if not exists assign_rides_to_cars_trigger instead of update
	on assign_rides_to_cars_view
begin
	-- old.* references booked_rides record
/*
	--to debug trigger
	insert into log_assign_rides_to_cars_trigger values(old.id, 
		(select id
		from cars
		where ride_end <= (old.ride_end - old.ride_size)
		order by (ride_end + (abs(old.x1-x2) + abs(old.y1-y2)))
		limit 1
		));
*/
	--find the nearest car to this ride and tranfer ride information to do the work
	update find_nearest_available_car_view set
		target_ride_id=old.id,
		target_x1=old.x1, target_y1=old.y1,
		target_x2=old.x2, target_y2=old.y2,
		target_ride_start=old.ride_start,
		target_ride_size=old.ride_size
	where id=(
		select id
		from cars
		where ride_end <= (old.ride_end - old.ride_size)
		order by (ride_end + (abs(old.x1-x2) + abs(old.y1-y2)))
		limit 1
	);
end;

--to debug
--select * from booked_rides limit 10;

--now perform the rides distribution
update assign_rides_to_cars_view set dummy=1;

.separator ' | '

--to debug
--select * from cars limit 10;
--select * from booked_rides_list_view limit 10;
--select * from booked_rides limit 10;
--select * from booked_rides_list_view limit 10;
--select * from ride_assign_tmp_calculations;
--select * from log_assign_rides_to_cars_trigger;
--select * from ride_assign_tmp_calculations_log;

--output stats
select 'Result Status' '----'; select * from booked_rides_result_view;select '' '----';
select * from calculate_score_view;

--output the results
.h off
.output 'results.txt'
select * from car_rides_result_list_view;
