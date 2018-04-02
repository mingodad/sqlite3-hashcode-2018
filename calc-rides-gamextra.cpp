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

void Solve(const string_t &filename, int_t nloops=1)
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

    //because we are using brute force we don't benefit too much by sort on total score
    std::sort(ridesB.begin(), ridesB.end(), rides_cmp);

    const std::vector<std::vector<int_t>> *bestPlan;
    Random r;

    //int_t loop_count = 0;
    for(int_t il=0; il < nloops; ++il)
    {
	//vector or list ? for small sizes vector can be faster
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

	    //shuffle can randomly give a benefit if we have duplcates
            std::shuffle(irides.begin(), irides.end(), grd);

            auto irides_cmp = [&ridesB, rides_cmp](const auto &left, const auto &right)
            {
                return rides_cmp(ridesB[left], ridesB[right]);
            };
            std::sort(irides.begin(), irides.end(), irides_cmp);
        }

        int_t score = 0;

        std::vector<std::vector<int_t>> plan(no_vehicles);

        auto cmp = [](const Vehicle &left, const Vehicle &right)
        {
            return left.endTime  > right.endTime;
        };
        std::priority_queue<Vehicle, std::vector<Vehicle>, decltype(cmp)> q(cmp);
        Vehicle v_tmp;
        v_tmp.endTime = 0;
        v_tmp.endPoint.row = 0;
        v_tmp.endPoint.col = 0;
        for (int_t i = 0; i < no_vehicles; i++)
        {
            v_tmp.index = i;
            q.push(v_tmp);
        }
        //int_t last_ride = 0;
        while (!q.empty() && !irides.empty())
        {
            const Vehicle &v = q.top();
            //if(last_ride != q.size())
            //{std::cout << "while\t" << score << "\t" << q.size() << "\t" << rides.size() << "\n"; last_ride = q.size();}

            int_t bestStartTime = std::numeric_limits<int_t>::max();
            auto bestRide = irides.end();
            auto ride_it_curr = irides.begin();
            auto ride_it_end = irides.end();
            for(; ride_it_curr !=  ride_it_end; ++ride_it_curr)
            {
                const Ride &the_ride = ridesB[*ride_it_curr];

                //if (the_ride.startStep > bestStartTime) break;
                if (v.endTime >= the_ride.endStep) continue;
                int_t the_startTime = std::max(v.endTime + v.endPoint.distance(the_ride.startPoint), the_ride.startStep);
                if (the_startTime + the_ride.distance() > the_ride.endStep) continue;

		//reducing bonus increase d_metropolis but drops e_high_bonus
                if (the_startTime /*- ((the_startTime == the_ride.startStep) ? bonus : 0)*/ > bestStartTime) continue;
                bestStartTime = the_startTime;
                bestRide = ride_it_curr;
            }
            //std::cout << "bestride ? \t" << (bestRide != rides.end()) << "\t" << v.index << "\n";
            if (bestRide != irides.end())
            {
                const Ride &the_ride = ridesB[*bestRide];
                Vehicle uv = v; q.pop(); //copy and remove
                plan[uv.index].push_back(the_ride.index);
                uv.endPoint = the_ride.endPoint;
                int_t ride_distance = the_ride.distance();
                uv.endTime = bestStartTime + ride_distance;
                score += ((bestStartTime == the_ride.startStep) ? bonus : 0) + ride_distance;
                irides.erase(bestRide); //remove from next searchs
                bestRide = ride_it_end; //reset
                q.push(uv); //reinsert and reorder
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
                    } \
                    rout << "\n"; \
                }

            try
            {
                std::ostringstream ofn;
                ofn << filename << "-" << bestScore << ".txt";
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
            std::cout << score << std::endl;
            //return; //do not try again
        }
    }
}

int_t main(int_t argc, char *argv[])
{
    int_t nloops = 1;
    std::string bfn = "";
    if(argc > 1) bfn = argv[1];
    if(argc > 2) nloops = std::atoi(argv[2]);

    Solve(bfn + "a_example.in", nloops);
    Solve(bfn + "b_should_be_easy.in", nloops);
    Solve(bfn + "c_no_hurry.in", nloops);
    Solve(bfn + "d_metropolis.in", nloops);
    Solve(bfn + "e_high_bonus.in", nloops);
    return 0;
}
