auto results_fn, rides_in_fn, rides_in_fn_base 

//rides_in_fn_base = "b_should_be_easy";
rides_in_fn_base = "c_no_hurry";
//rides_in_fn_base = "d_metropolis";
//rides_in_fn_base = "e_high_bonus";

//results_fn = "hashcode-2018-master/out.txt";
//results_fn = "results.txt";
//results_fn = "fuser13/outputs/" + rides_in_fn_base + ".out";
results_fn = "stoman/data/naive." + rides_in_fn_base + ".ans";

rides_in_fn = rides_in_fn_base + ".in";

auto rides_data = readfile(rides_in_fn);
rides_data = rides_data.split('\n');

auto header = rides_data[0];
print(header);
auto rec = header.split(' ');
//foreach(idx, elm in rec) print(idx, "x" + elm + "z");
auto rows = rec[0].tointeger();
auto cols = rec[1].tointeger();
auto total_cars = rec[2].tointeger();
auto total_rides = rec[3].tointeger();
auto per_ride_bonus = rec[4].tointeger();
auto max_steps = rec[5].tointeger();

//remove header
rides_data.remove(0);

print("Effective work limits:\n", rows, cols, total_cars, total_rides, per_ride_bonus, max_steps);


auto results = readfile(results_fn);
results = results.split('\n');
print(results.len());

auto mabs = math.abs;
int_t calc_distance(int_t x1, int_t y1, int_t x2, int_t y2) {
	return mabs(x1 - x2) + mabs(y1 - y2);
}

auto rides_count = 0;
auto rides_bonus_count = 0;
auto rides_score_size = 0;
auto rides_score_bonus = 0;

class Car {
	int_t end_x=0;
	int_t end_y=0;
	int_t ride_end=0;
	static int_t total_score = 0;
}

auto all_cars = array(total_cars);
foreach(idx, elm in all_cars) all_cars[idx] = new Car();


foreach(car_idx, line in results)
{
	line = line.split(' ');
	auto count = 0;
	auto expected_count = 0;

	auto car = all_cars[car_idx];

	foreach(idx, elm in line)
	{
		if(idx == 0)
		{
			expected_count = elm.tointeger();
			continue;
		}
		++rides_count;
		elm = elm.tointeger();
		auto ride = rides_data[elm];
		auto ride_rec = ride.split(' ');
		auto ride_x1 = ride_rec[0].tointeger();
		auto ride_y1 = ride_rec[1].tointeger();
		auto ride_x2 = ride_rec[2].tointeger();
		auto ride_y2 = ride_rec[3].tointeger();
		auto ride_start = ride_rec[4].tointeger();
		auto ride_end = ride_rec[5].tointeger();

		auto ride_size = calc_distance(ride_x1, ride_y1, ride_x2, ride_y2);
		rides_score_size += ride_size;
		car.total_score += ride_size;
		
		auto ride_start_distance = calc_distance(car.end_x, car.end_y, ride_x1, ride_y1);
		car.ride_end += ride_start_distance;
		if(car.ride_end <= ride_start)
		{
			rides_score_bonus += per_ride_bonus;
			car.total_score += per_ride_bonus;
			car.ride_end += ride_start - car.ride_end; //waiting steps
			++rides_bonus_count;
		}
		
		car.end_x = ride_x2;
		car.end_y = ride_y2;
		car.ride_end += ride_size;
		
		print(car_idx, idx, elm, ride_size, ride);
		
		++count;
		rides_data[elm] = null; //remove the ride_info to detect double assignment
	}
	if(count != expected_count)
	{
		print("Mismatch found", car_idx, expected_count, count);
	}
	++car_idx;
}

print("Assigned rides", rides_count, rides_bonus_count, rides_score_size, rides_score_bonus, rides_score_size + rides_score_bonus);


