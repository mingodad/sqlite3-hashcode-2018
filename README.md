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

It outputs in the format reuired by the hashcode 2018 rules.

This solution uses triggers on dummy views to emulate stored procedures,
and only requires a recent sqlite3 executable and data files to work on.

By no means I claim that solutions like this (stretching sqlite3) are
good practice. Take it as an example that demonstrates several
capabilities of sqlite3 in a hack/compact way.

It works with a memory database unless you supply a database name
when invoking it:

`sqlite3 < hashcode2018.sql`

or directing the output to a file:

`sqlite3 < hashcode2018.sql > result.txt`

With a disk database:
sqlite3 database_name.db < hashcode2018.sql

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

