#!/usr/bin/perl

# Script: killsimulation.pl
#
# Stops a running simulation 

use warnings;
use strict;

use lib "modules";
use Constants;

my $configfile = shift;
open(FILE,"<$configfile");
my @lines = <FILE>;
close(FILE);

my $scenarioName = "";
foreach my $line (@lines){
    next if $line =~ /^#/;
    next if $line =~ /^$/;
    ($scenarioName) = split(" ",$line);
    last;
}

system("killall zimulator.pl");
system("killall -s 9 vnumlparser.pl");
system("rm ~/.vnuml/LOCK");
system(Constants::VNUML_PATH."/vnumlparser.pl ".Constants::VNUML_STOP_PARAMETERS." $scenarioName.xml");
