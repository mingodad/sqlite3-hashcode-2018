# sqlite3-hashcode-2018

If all you have is a hammer, maybe this looks like a nail !

An attempt to somehow solve the GOOGLE HASHCODE 2018 with sqlite3, 
it does give a simple solution to the problem.

Basically it sorts the booked rides by the "the earliest start", 
uses a table to store the current car's booked ride info
then for each booked_ride choose the car that has/will finish a
previous ride closest to the start of the current assigning ride
if no car can arrive at least on the ("the latest finish" - the_ride_size)
we ignore it.

It outputs in the format required by the hashcode 2018 rules, to a file named 'results.txt'.

This solution uses triggers on dummy views to emulate stored procedures,
and only requires a recent sqlite3 executable and data files to work on.

By no means I claim that solutions like this (stretching sqlite3) are
good practice. Take it as an example that demonstrates several
capabilities of sqlite3 in a hack/compact way.

It works with a memory database unless you supply a database name
when invoking it:

`sqlite3 < hashcode2018.sql`

With a disk database:

`sqlite3 database_name.db < hashcode2018.sql`

To process a specific data file look bellow after the 
creation of the table "booked_rides_tmp" for a line like:

`.import 'a_example.in' booked_rides_tmp`

and edit it.

Author: Domingo Alvarez Duarte mingodad :at: gmail.com

License: Public domain as in sqlite3

Time spent till now: 48 hours (and several dream hours)
the time above includes a prototype using a scripting language
SquiLu (https://github.com/mingodad/squilu) around 38 hours
including a simple plot program to show the rides for a car step by step.

The scores (on Atom @1.66GHZ):

| data file | score | time spent |
|--------------|----------:|-----------------:|
|a_example.in |		8 |	0m0.202s|
|b_should_be_easy.in	| 176,877	| 0m0.301s|
|c_no_hurry.in | 13,089,884 | 0m6.177s|
|d_metropolis.in | 10,990,382 | 0m17.973s|
|e_high_bonus.in | 21,465,945 | 0m23.155s|
|Total | 45,723,096 | |

New: The calc-rides.nut have an option to try reduce the number of required cars, with b_should_be_easy.in it can achieve the same score with only 24 cars, with e_high_bonus.in it achieve the same score with 174 cars, the others could not work with less cars.

Added a C++ port of the java solution from https://github.com/GameXtra/Google-Hash-Code-2018, it achieves a score above 49,000,000

