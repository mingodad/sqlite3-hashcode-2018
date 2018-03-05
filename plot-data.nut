auto data_fn;
data_fn = "a_example.in";
//data_fn = "b_should_be_easy.in";
//data_fn  = "c_no_hurry.in";
//data_fn  = "d_metropolis.in";
//data_fn  = "e_high_bonus.in";

auto db_fn = data_fn + ".db";
auto db = SQLite3(db_fn);

auto stmt_limits = db.prepare("select rows, cols from work_limits where id=1");
stmt_limits.next_row();

//cols are plted on x-axys and rows on the y-axys
auto max_rows = stmt_limits.col(0);
auto max_cols = stmt_limits.col(1);

auto car_id = 1;

if(vargv.len() > 1) data_fn = vargv[1];
if(vargv.len() > 2) car_id = vargv[2].tointeger();

auto stmt = db.prepare("select x1,y1,x2,y2 from booked_rides where assigned_car=" + car_id);
auto data = stmt.asArrayOfArrays();
/*
print(data, data.len());
foreach(idx, elm in data) print(idx, elm[0], elm.len());
*/

class Fl_Plot extends Fl_Box {

	Fl_Plot(X, Y, W, H, L = null) {
		base.constructor(X,Y,W,H,L);
		color(FL_WHITE);
		align(FL_ALIGN_RIGHT);
		labeltype(FL_NO_LABEL);
	}

	function draw() {
		//set font size, color and clear
		//fl_font(labelfont(), labelsize());
		fl_color(color());
		fl_rectf(x(), y(), w(), h());
		
		/*
		fl_color(FL_BLACK);
		fl_line_style(FL_SOLID, 1, NULL);
		auto scale_unit = 0.25;
		auto offsetx = this.x();
		auto offsety = this.y();
		foreach(idx, elm in data)
		{
			auto x1 = (elm[0] * scale_unit) + offsetx;
			auto y1 = (elm[1] * scale_unit) + offsety;
			auto x2 = (elm[2] * scale_unit) + offsetx;
			auto y2 = (elm[3] * scale_unit) + offsety;
			fl_line(x1, y1, x2, y2);
		}
		*/
	}
}

local win = Fl_Double_Window(20,30, 800, 560, "Ride Plot Steps");
local myplot = Fl_Plot(20,20, 760, 520, "Plot");
myplot.color(FL_WHITE);
win->end();

win->resizable(myplot);
win->show_main();

local timeout_delay = 2.0;
auto scale_adjust = 1.0;
//cols are plted on x-axys and rows on the y-axys
auto scale_unit = ((myplot.h()-myplot.y()) / (max_cols*scale_adjust)); //0.25;
//print(scale_unit, max_rows , max_cols, max_rows *scale_unit, max_cols*scale_unit, myplot.h(), myplot.w());
local curr_line = 0;
local line_draw_count_reset_every = 12;
local line_draw_count = 0;

auto offsetx = myplot.x()+2;
auto offsety = myplot.y()+2;

local _do_draw_one_line;
_do_draw_one_line = function(step){
	if(curr_line < data.len())
	{
		//print(curr_line++);
		
		if(++line_draw_count > line_draw_count_reset_every)
		{
			line_draw_count = 0;
			curr_line -= 1;
			myplot.redraw();
			Fl.repeat_timeout(0.01, _do_draw_one_line, step);
			return;
		}

		auto elm = data[curr_line];

		fl_line_style(FL_SOLID, 2, NULL);
		
		local function dline(x1, y1, x2, y2)
		{
			//print(x1, y1, x2, y2);
			x1 = (x1 * scale_unit) + offsetx;
			y1 = (y1 * scale_unit) + offsety;
			x2 = (x2 * scale_unit) + offsetx;
			y2 = (y2 * scale_unit) + offsety;
			fl_line(x1, y1, x2, y2);
			//print(x1, y1, x2, y2);
		}
		
		//dline(elm[0], elm[1], elm[2], elm[3]);
		auto x0, y0;
		if(curr_line > 0)
		{
			auto prev_ride = data[curr_line-1];
			x0 = prev_ride[2];
			y0 = prev_ride[3];
		}
		else
		{
			x0 = y0 = 0;
		}
		auto x1 = elm[0];
		auto y1 = elm[1];
		auto x2 = elm[2];
		auto y2 = elm[3];

		if(step == 1)
		{
			//drive from last ride to the start of this one
			fl_color(FL_GREEN);
			dline(x0, y0, x1, y0);
			dline(x1, y0, x1, y1);
			Fl.repeat_timeout(timeout_delay, _do_draw_one_line, 2);
			return;
		}

		//perform the ride
		fl_color(FL_BLUE);
		dline(x1, y1, x2, y1);
		dline(x2, y1, x2, y2);
		
		Fl.repeat_timeout(timeout_delay, _do_draw_one_line, 1);
		++curr_line;
	}
}
Fl.add_timeout(0.2, _do_draw_one_line, 1);

Fl.run();
