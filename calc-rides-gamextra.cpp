#include <algorithm>
#include <random>
#include <functional>
#include <iomanip>
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <list>
#include <queue>
#include <cstdlib>
#include <ctime>

typedef bool bool_t;
typedef int int_t;
typedef double double_t;
typedef std::string string_t;

struct Intersection
{
    int_t row, col;

    int_t distance(const Intersection &other) const
    {
        return std::abs(other.col - col) + std::abs(other.row - row);
    }
};

struct Ride
{
    Intersection startPoint, endPoint;
    int_t startStep, endStep;
    int_t index;

    int_t distance() const
    {
        return startPoint.distance(endPoint);
    }
};

struct Vehicle /*implements Comparable<Vehicle>*/
{
    int_t endTime;
    Intersection endPoint;
    int_t index;

    //@Override
    int_t _cmp(const Vehicle &o) const
    {
        return endTime - o.endTime;
    }
};

#ifdef RAND_RANDOM
struct Random {
	Random() {std::srand(std::time(0));} // use current time as seed for random generator
	double nextDouble(){return (std::rand()%RAND_MAX) / (double)RAND_MAX;}
	bool nextBoolean(){return (std::rand() % 2);}
};
#else
struct Random {
    std::random_device rd;
    std::mt19937 grd;
	Random() {grd.seed(rd());}
	double_t nextDouble(){return (grd()%RAND_MAX) / (double)RAND_MAX;}
	bool_t nextBoolean(){return (grd() % 2);}
};
#endif // 0

void Solve(const string_t &filename, int_t nloops=1, double_t dfactor=0.000005)
{
    int_t no_rows, no_cols, no_vehicles, no_rides, bonus, no_steps;
    std::cout << filename << "\t";
    std::ifstream fd_in(filename);
    fd_in >> no_rows;
    fd_in >> no_cols;
    fd_in >> no_vehicles;
    fd_in >> no_rides;
    fd_in >> bonus;
    fd_in >> no_steps;

    //std::cout << "Header\t" << no_rows << "\t" << no_cols << "\t" << no_vehicles << "\n";

    //LinkedList<Ride> ridesB = new LinkedList<>();
    //std::list<Ride> ridesB;
    std::vector<Ride> ridesB;

    Ride r_tmp;
    for (int_t i = 0; i < no_rides; i++)
    {

        fd_in >> r_tmp.startPoint.row;
        fd_in >> r_tmp.startPoint.col;

        fd_in >> r_tmp.endPoint.row;
        fd_in >> r_tmp.endPoint.col;

        fd_in >> r_tmp.startStep;
        fd_in >> r_tmp.endStep;

        r_tmp.index = i;
        ridesB.push_back(r_tmp);
    }
    double_t factor = 1.0;
    int_t bestScore = 0;

    //std::cout << "Rides size\t" << no_rides << "\t" << ridesB.size() << "\n";

    auto rides_cmp = [](const Ride &left, const Ride &right)
    {
        int result = left.startStep - right.startStep;
        if(result == 0) {
                result = left.distance() - right.distance();
        }
        return result < 0;
    };

    std::sort(ridesB.begin(), ridesB.end(), rides_cmp);

    //ArrayList<ArrayList<Integer>> bestPlan = new ArrayList<>();
    const std::vector<std::vector<int_t>> *bestPlan;
    Random r;

    //int_t loop_count = 0;
    for(int_t il=0; il < nloops; ++il)
    {
        if(nloops > 1)
        {
            factor = r.nextDouble() * 0.0001;
            if (r.nextBoolean()) factor *= -1;
        }
        else factor = dfactor; //r.nextDouble() * 0.00005; //;
        //LinkedList<Ride> rides = (LinkedList<Ride>) ridesB.clone();
        //std::list<Ride> rides(ridesB);

        //typedef std::list<int> Irides_t;
        typedef std::vector<int> Irides_t;
        Irides_t irides(ridesB.size());
        int n_irides = {0};
        std::generate(irides.begin(), irides.end(), [&n_irides]{ return n_irides++; });

        if(nloops > 1)
        {
            //Collections.shuffle(rides);
            std::random_device rd;
            std::mt19937 grd(rd());
            std::shuffle(irides.begin(), irides.end(), grd);

            auto irides_cmp = [&ridesB, rides_cmp](const auto &left, const auto &right)
            {
                return rides_cmp(ridesB[left], ridesB[right]);
            };
            std::sort(irides.begin(), irides.end(), irides_cmp);
        }

        //std::cout << "factor\t" /*<< std::setw( 15 ) << std::setprecision( 12 ) << std::setfill( '0' ) */
	//	<< factor << "\t" << ++loop_count << "\n";

        int_t score = 0;

        //ArrayList<ArrayList<Integer>> plan = new ArrayList<>();
        std::vector<std::vector<int_t>> plan(no_vehicles);

        //PriorityQueue<Vehicle> q = new PriorityQueue<>();
        auto cmp = [](const Vehicle &left, const Vehicle &right)
        {
            return left.endTime  > right.endTime;
        };
        std::priority_queue<Vehicle, std::vector<Vehicle>, decltype(cmp)> q(cmp);
        //std::list<Vehicle> q;
        Vehicle v_tmp;
        v_tmp.endTime = 0;
        v_tmp.endPoint.row = 0;
        v_tmp.endPoint.col = 0;
        for (int_t i = 0; i < no_vehicles; i++)
        {
            v_tmp.index = i;
            q.push(v_tmp);
            //q.push_back(v_tmp);
        }
        bool_t isBonus = false;
        //int_t last_ride = 0;
        while (!q.empty() && !irides.empty())
        {
            //Vehicle v = q.poll();
            const Vehicle &v = q.top();
            //Vehicle v = q.back();
            //q.pop_back();
            //if(last_ride != q.size())
            //{std::cout << "while\t" << score << "\t" << q.size() << "\t" << rides.size() << "\n"; last_ride = q.size();}

            int_t endTime = 0;
            int_t bestStartTime = std::numeric_limits<int_t>::max();
            auto bestRide = irides.end();
            auto ride_it_curr = irides.begin();
            auto ride_it_end = irides.end();
            for(; ride_it_curr !=  ride_it_end; ++ride_it_curr)
            {
                const Ride &the_ride = ridesB[*ride_it_curr];
                //if(ride == null) continue;
                //if (r.nextDouble() < 0.0001) continue;

                if (the_ride.startStep > bestStartTime) break;
                if (v.endTime >= the_ride.endStep) continue;
                int_t step = std::max(v.endTime + v.endPoint.distance(the_ride.startPoint), the_ride.startStep);
                int_t ride_distance = the_ride.distance();
                if (step + ride_distance > the_ride.endStep) continue;

                bool_t isBonus1 = step == the_ride.startStep;
                int_t originst = step;
                step -= isBonus1 ? bonus : 0;
                step += ride_distance * factor;
                if (step > bestStartTime) continue;
                isBonus = isBonus1;
                bestStartTime = step;
                bestRide = ride_it_curr;
                endTime = originst + ride_distance;
            }
            //std::cout << "bestride ? \t" << (bestRide != rides.end()) << "\t" << v.index << "\n";
            if (bestRide != irides.end())
            {
                const Ride &the_ride = ridesB[*bestRide];
                Vehicle uv = v;
                q.pop();
                plan[uv.index].push_back(the_ride.index);
                uv.endPoint = the_ride.endPoint;
                uv.endTime = endTime;
                score += (isBonus ? bonus : 0) + the_ride.distance();
                irides.erase(bestRide);
                bestRide = ride_it_end;
                q.push(uv);
                //q.push_front(v);
            }
            else q.pop();
        }
        if (score > bestScore)
        {
            bestPlan = &plan;
            bestScore = score;

#define SHOW_RESULT(rout) \
                for (int_t i = 0; i < no_vehicles; i++) \
                { \
                    rout << bestPlan->at(i).size(); \
                    for (std::size_t j = 0; j < bestPlan->at(i).size(); j++) \
                    { \
                        rout << " "; \
                        rout << bestPlan->at(i)[j]; \
                        rout  << "\t" << std::fixed << std::setprecision(8) << factor; \
                    } \
                    rout << "\n"; \
                }

            try
            {
                std::ostringstream ofn;
                ofn << filename << "-" << std::fixed << std::setprecision(8) << factor << "-" << bestScore << ".txt";
                std::ofstream out(ofn.str());
                SHOW_RESULT(out);
                out.close();
            }
            catch (std::exception e)
            {
                std::cerr << "Failed";
                SHOW_RESULT(std::cerr);
                return;
            }
#undef SHOW_RESULT
            std::cout << score << "\t" << std::fixed << std::setprecision(8) << factor << std::endl;
            //return; //do not try again
        }
    }
}

int_t main(int_t argc, char *argv[])
{
    double_t dfactor = 0.000005;
    int_t nloops = 1;
    std::string bfn = "";
    if(argc > 1) bfn = argv[1];
    if(argc > 2) nloops = std::atoi(argv[2]);
    if(argc > 3) dfactor = std::atof(argv[3]);

    Solve(bfn + "a_example.in", nloops, dfactor);
    Solve(bfn + "b_should_be_easy.in", nloops, dfactor);
    Solve(bfn + "c_no_hurry.in", nloops, dfactor);
    Solve(bfn + "d_metropolis.in", nloops, dfactor);
    Solve(bfn + "e_high_bonus.in", nloops, dfactor);
    return 0;
}
