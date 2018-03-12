auto start_time = os.clock(); //To calculate the total time spent

auto data_fn;
//data_fn = "a_example.in";
//data_fn = "b_should_be_easy.in";
//data_fn = "c_no_hurry.in";
//data_fn = "d_metropolis.in";
data_fn = "e_high_bonus.in";

auto data  = readfile(data_fn);
data = data.split('\n');

auto header = data[0];
print(header);
auto rec = header.split(' ');
//foreach(idx, elm in rec) print(idx, "x" + elm + "z");
auto rows = rec[0] = rec[0].tointeger();
auto cols = rec[1] = rec[1].tointeger();
auto total_cars = rec[2] = rec[2].tointeger();
auto total_rides = rec[3] = rec[3].tointeger();
auto per_ride_bonus = rec[4] = rec[4].tointeger();
auto max_steps = rec[5] = rec[5].tointeger();
data[0] = rec;

print("Effective work limits:\n", rows, cols, total_cars, total_rides, per_ride_bonus, max_steps);

auto num_counts = 4;
auto count_rides = data.len()-1;

auto total_rides_size = 0;

auto count_rides_count = array(num_counts, 0);
auto count_rides_count_limits = array(num_counts, 0.0);
auto first_set_limit = max_steps/(num_counts+0.0);
foreach(idx, elm in count_rides_count_limits) count_rides_count_limits[idx] = first_set_limit * (idx+1);

auto mabs = math.abs;
auto matan2 = math.atan2;
auto mpi = math.PI;

local function calc_bearing(x1, y1, x2, y2)
{
	auto xd, yd, bearing;
	if( x1 == x2 && y1 == y2 ) {
		return null;
	}
	xd = x2 - x1;
	yd = y2 - y1;
	bearing = (matan2(xd, yd) * 180.0/mpi) % 360.0;
	return (bearing < 0 ? bearing + 360.0 : bearing);
}

auto bearing_rides_count = array(num_counts, 0);
auto bearing_rides_count_limits = array(num_counts, 0.0);
auto bearing_first_set_limit = 360/(num_counts+0.0);
foreach(idx, elm in bearing_rides_count_limits) bearing_rides_count_limits[idx] = bearing_first_set_limit * (idx+1);

auto xy_cols1 = cols / 2;
auto xy_rows1 = rows / 2;
auto xy_num_counts = 4;
auto x1y1_rides_count = array(xy_num_counts, 0);
auto x2y2_rides_count = array(xy_num_counts, 0);
auto x1y1x2y2_rides_count = array(xy_num_counts, 0);


foreach(idx, elm in data)
{
	if(idx == 0) continue; //skip header
	
	rec = elm.split(' ');
	auto x1 = rec[0] = rec[0].tointeger();
	auto y1 = rec[1] = rec[1].tointeger();
	auto x2 = rec[2] = rec[2].tointeger();
	auto y2 = rec[3] = rec[3].tointeger();
	auto ride_start = rec[4] = rec[4].tointeger();
	auto ride_end = rec[5] = rec[5].tointeger();
	data[idx] = rec;
	
	auto ride_size = (mabs(x1-x2) + mabs(y1-y2));
	total_rides_size += ride_size;
	
	auto prev_set_limit = 0;
	foreach(idx, set_limit in count_rides_count_limits)
	{
		if( (ride_start >= prev_set_limit) && (ride_start < set_limit) )
		{
			++count_rides_count[idx];
		}
		
		prev_set_limit = set_limit;
	}

	auto ride_bearing = calc_bearing(x1, y1, x2, y2);
	//print("ride_bearing", ride_bearing);
	prev_set_limit = 0;
	foreach(idx, set_limit in bearing_rides_count_limits)
	{
		if( (ride_bearing >= prev_set_limit) && (ride_bearing < set_limit) )
		{
			++bearing_rides_count[idx];
		}
		
		prev_set_limit = set_limit;
	}
	
	//x1 y1
	if((x1 < xy_cols1) && (y1 < xy_rows1)) ++x1y1_rides_count[0];
	else if((x1 > xy_cols1) && (y1 < xy_rows1)) ++x1y1_rides_count[1];
	else if((x1 < xy_cols1) && (y1 > xy_rows1)) ++x1y1_rides_count[2];
	else if((x1 > xy_cols1) && (y1 > xy_rows1)) ++x1y1_rides_count[3];

	//x2 y2
	if((x2 < xy_cols1) && (y2 < xy_rows1)) ++x2y2_rides_count[0];
	else if((x2 > xy_cols1) && (y2 < xy_rows1)) ++x2y2_rides_count[1];
	else if((x2 < xy_cols1) && (y2 > xy_rows1)) ++x2y2_rides_count[2];
	else if((x2 > xy_cols1) && (y2 > xy_rows1)) ++x2y2_rides_count[3];

	//x1 y1 x2 y2
	if((x1 < xy_cols1) && (y1 < xy_rows1) && (x2 < xy_cols1) && (y2 < xy_rows1)) ++x1y1x2y2_rides_count[0];
	else if((x1 > xy_cols1) && (y1 < xy_rows1) && (x2 > xy_cols1) && (y2 < xy_rows1)) ++x1y1x2y2_rides_count[1];
	else if((x1 < xy_cols1) && (y1 > xy_rows1) && (x2 < xy_cols1) && (y2 > xy_rows1)) ++x1y1x2y2_rides_count[2];
	else if((x1 > xy_cols1) && (y1 > xy_rows1) && (x2 > xy_cols1) && (y2 > xy_rows1)) ++x1y1x2y2_rides_count[3];
}

auto ride_sizes_count = array(num_counts, 0);
auto ride_sizes_sum = array(num_counts, 0);
auto ride_size_limits = array(num_counts, 0.0);
first_set_limit = (rows+cols)/(num_counts+0.0);
foreach(idx, elm in ride_size_limits) ride_size_limits[idx] = first_set_limit * (idx+1);
print("total_rides_size", total_rides_size, first_set_limit);

foreach(idx, elm in data)
{
	if(idx == 0) continue; //skip header
	
	auto x1 = elm[0];
	auto y1 = elm[1];
	auto x2 = elm[2];
	auto y2 = elm[3];
	auto ride_start = elm[4];
	auto ride_end = elm[5];
	
	auto ride_size = (mabs(x1-x2) + mabs(y1-y2));
	
	auto prev_set_limit = 0;
	foreach(idx, set_limit in ride_size_limits)
	{
		if( (ride_size >= prev_set_limit) && (ride_size < set_limit) )
		{
			ride_sizes_sum[idx] += ride_size;
			++ride_sizes_count[idx];
		}
		
		prev_set_limit = set_limit;
	}
}

print("==== ride_start distribution");
foreach(idx, elm in count_rides_count)
{
	auto pct = math.roundf(((elm+0.0)/count_rides)*100, 2);
	print(idx, elm, pct, count_rides_count_limits[idx]);
}

print("==== ride_size distribution");
foreach(idx, elm in ride_sizes_count)
{
	auto this_ride_size_sum = ride_sizes_sum[idx];
	auto pct = math.roundf(((this_ride_size_sum+0.0)/total_rides_size)*100, 2);
	print(idx, elm, pct, ride_size_limits[idx]);
}

print("==== ride_bearing distribution");
foreach(idx, elm in bearing_rides_count)
{
	auto pct = math.roundf(((elm+0.0)/count_rides)*100, 2);
	print(idx, elm, pct, bearing_rides_count_limits[idx]);
}

print("==== x1_y1 distribution");
foreach(idx, elm in x1y1_rides_count)
{
	auto pct = math.roundf(((elm+0.0)/count_rides)*100, 2);
	print(idx, elm, pct);
}

print("==== x2_y2 distribution");
foreach(idx, elm in x2y2_rides_count)
{
	auto pct = math.roundf(((elm+0.0)/count_rides)*100, 2);
	print(idx, elm, pct);
}

print("==== x1_y1_x2_y2 distribution");
foreach(idx, elm in x1y1x2y2_rides_count)
{
	auto pct = math.roundf(((elm+0.0)/count_rides)*100, 2);
	print(idx, elm, pct);
}

print("\nTime spent", os.clock() - start_time);
