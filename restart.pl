#!/usr/bin/perl

# Script: restart.pl
#
# Restarts a simulation using the Script killsimulation.pl to stop it.

use warnings;
use strict;

system("./killsimulation.pl simulations.txt");
print "simulation killed\n";
sleep 10;
exec("./zimulator.pl -vs simulations.txt >> simulations.out &");

exit 0;
