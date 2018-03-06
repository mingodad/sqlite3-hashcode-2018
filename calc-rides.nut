auto start_time = os.clock(); //To calculate the total time spent

#define FILL_DB  //if we want to start from scratch
#define PREFER_ONTIME //Do we prefer ontime or minimize empty walks ?

auto data_fn;
//data_fn = "a_example.in";
data_fn = "b_should_be_easy.in";
//data_fn  = "c_no_hurry.in";
//data_fn  = "d_metropolis.in";
//data_fn  = "e_high_bonus.in";

//if we want to try with a differnt amount of cars set it bellow
//for some booked rides list, less cars can do the same work without service degradation
//empirically it seems that a good number of cars is around 1/20 to 1/10 of the total booked rides 
auto override_total_cars = 0;

//we can set through command line the variables bellow
if(vargv.len() > 1) data_fn = vargv[1];
if(vargv.len() > 2) override_total_cars = vargv[2].tointeger();

if(!data_fn)
{
	print("usage:\tsquilu", vargv[0], "file_name_data_in [optional_car_amount]");
	return 1;
}

auto db_fn = data_fn + ".db";
#ifdef FILL_DB
	os.system("rm " + db_fn);
#endif
auto db = SQLite3(db_fn);
//auto db = SQLite3(":memory:");

//we calculate the absolute distance between two coordnate points
//using this formula: (abs(x1-x2) + abs(y1-y2))

db.exec_dml([==[

create table if not exists work_limits(
	id integer primary key
	,rows integer
	,cols integer
	,cars integer
	,nrides integer
	,bonus integer
	,max_steps integer
);

create table if not exists cars(
	id integer primary key
	,x2 integer not null default 0
	,y2 integer not null default 0
	,ride_end integer not null default 0
	,ride_id integer
);

--store the assigned rides to cars to preserve assignment order
create table if not exists car_rides(
	id integer primary key,
	car_id integer not null,
	ride_id integer not null,
	unique(car_id, ride_id)
);

create table if not exists booked_rides(
	id integer primary key
	,x1 integer
	,y1 integer
	,x2 integer
	,y2 integer
	,ride_start integer
	,ride_end integer
	,assigned_car boolean default 0
	,assigned_at_step integer
	,waiting_steps integer -- if positive the car need wait, negative the passenger need wait
	,distance_to_start integer -- car distance between last position to the start of the assigned ride
);

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
	Order by ride_start, ride_size, start_distance
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

]==]);

auto stmt_booked_rides_list = db.prepare([==[
	select id, assigned_car, x1, y1, x2, y2, ride_start, ride_end , ride_size, start_distance
	from booked_rides_list_view where possible=1
	]==]);

//find the closest car avaliable that can execute the ride without delay past the ride_end
#ifdef PREFER_ONTIME
//with this we get more ontime rides but we have more steps going from on ride to another
auto stmt_cars_available_list = db.prepare([==[
	select id, ride_end, (abs(@ride_x1-x2) + abs(@ride_y1-y2)) distance
	from cars where ride_end <= @ride_end_less_ride_size
	order by (ride_end + distance)
	limit 1
	]==]);
#else
//with this we get less ontime rides but also less steps going from one ride to another
auto stmt_cars_available_list = db.prepare([==[
	select id, ride_end, (abs(@ride_x1-x2) + abs(@ride_y1-y2)) distance
	from cars where ride_end <= @ride_end_less_ride_size
	order by distance
	limit 1
	]==]);
#endif

auto stmt_assign_ride = db.prepare([==[
	update booked_rides set
		assigned_car=?, assigned_at_step=?,
		waiting_steps=?, distance_to_start=?
	where id=?
	]==]);
auto stmt_car_update = db.prepare("update cars set ride_id=?, x2=?, y2=?, ride_end=? where id=?");
auto stmt_car_ride = db.prepare("insert into car_rides(car_id, ride_id) values(?,?)");

#ifdef FILL_DB
auto stmt_work_limits = db.prepare("insert into work_limits(rows, cols, cars, nrides, bonus, max_steps) values(?,?,?,?,?,?)");
auto stmt_booked_rides = db.prepare("insert into booked_rides(x1, y1, x2, y2, ride_start, ride_end) values(?,?,?,?,?,?)");
auto stmt_cars = db.prepare("insert into cars(id) values(?)");

auto data  = readfile(data_fn);
data = data.split('\n');

auto header = data[0];
print(header);
auto rec = header.split(' ');
//foreach(idx, elm in rec) print(idx, "x" + elm + "z");
auto rows = rec[0].tointeger();
auto cols = rec[1].tointeger();
auto total_cars0 = rec[2].tointeger();
auto total_cars = (override_total_cars  ? override_total_cars : total_cars0);
auto total_rides = rec[3].tointeger();
auto per_ride_bonus = rec[4].tointeger();
auto max_steps = rec[5].tointeger();

print("Effective work limits:\n", rows, cols, total_cars, total_rides, per_ride_bonus, max_steps);

db.exec_dml("begin");
stmt_work_limits.bind_exec(rows, cols, total_cars, total_rides, per_ride_bonus, max_steps);

foreach(idx, line in data) 
{
	auto line_rec = line.split(' ');
	if(idx > 0)
	{
		stmt_booked_rides.bind_exec(line_rec[0], line_rec[1], line_rec[2], line_rec[3],
			line_rec[4], line_rec[5]);
	}
}

for(auto c=1; c <= total_cars; ++c) stmt_cars.bind_exec(c);

db.exec_dml("commit");
#else
auto total_cars = db.exec_get_one("select cars from work_limits where id=1");
auto total_cars0 = total_cars;
#endif

db.exec_dml("begin");
while(stmt_booked_rides_list.next_row())
{
	auto isAssigned = stmt_booked_rides_list.col(1);
	if(!isAssigned)
	{
		auto ride = stmt_booked_rides_list.asTable();

		auto max_ride_start = ride.ride_end - ride.ride_size;
		//foreach(the_ride_start in [ride.ride_start, max_ride_start]) //try ontime first if fail then try ride_end-ride_size
		foreach(the_ride_start in [max_ride_start]) //try only ride_end-ride_size
		{
			//auto done = false;
			//find the closest car avaliable that can execute the ride without delay past the ride_end
			stmt_cars_available_list.bind_values(ride.x1, ride.y1, the_ride_start);
			//print(ride_id, ride_x1, ride_y1, the_ride_start, ride.start_distance);
			if(stmt_cars_available_list.next_row())
			{
				//print("Got one");
				auto car = stmt_cars_available_list.asTable();
				//print(ride.id, car.id, car.ride_end, car.distance, ride.ride_start, the_ride_start, ride.start_distance);
				
				auto new_car_end = car.ride_end + car.distance;
				auto waiting_steps =  ride.ride_start - new_car_end;

				//Do we need to wait to start the new ride ?
				if(waiting_steps > 0) new_car_end += waiting_steps;
				
				//we use the new_car_end calculated till now without the ride_size
				auto assigned_at_step = new_car_end;

				//set new_car_end to the expected value after complete the ride
				new_car_end += ride.ride_size;
				
				//print(ride.id, new_car_end, assigned_at, ride.ride_size);
				stmt_car_ride.bind_exec(car.id, ride.id);
				stmt_assign_ride.bind_exec(car.id, assigned_at_step, waiting_steps, car.distance, ride.id);
				auto rc = stmt_car_update.bind_exec(ride.id, ride.x2, ride.y2, new_car_end,car.id);
				//print(ride.id, ride.x2, ride.y2, new_car_end,car.id, db.errmsg(), rc);
				//done = true;
			}
			stmt_cars_available_list.reset();
			/*
			if(done)
			{
				//print("Done");
				break;
			}*/
		}
	}
}
db.exec_dml("commit");

auto result_score = db.exec_get_one("select score from calculate_score_view");
print("Result score:", result_score);
print("The result of rides by car follow:");
auto stmt_result = db.prepare("select * from car_rides_result_list_view");
auto count = 0;
while(stmt_result.next_row())
{
	print(stmt_result.col(0));
	++count;
}
//if we find a better result with less cars
//then fill in the remaining cars with 0
for(auto i=count; i < total_cars0; ++i) print("0");

print("\nTime spent", os.clock() - start_time);