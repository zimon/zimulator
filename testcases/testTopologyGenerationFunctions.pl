#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 6;
use Carp;
use lib "../modules";
use TopologyGenerationFunctions;
use Topology;
use File;
use Utilities;

# Debugging on when testing
$" = '] ['; # set field seperator for list to string conversion
use DebugMessages exit_on_warning => 1, fatal => 3, warnings => 3, level => 5;

my $verbose = 0;
$verbose = 1 if defined $ARGV[0] and $ARGV[0] eq "-v";

sub compareTopologies {
    my ($resultTopology,$compareFile) = @_;
    my @compareLines = $compareFile->getLineArray();
    my @resultLines = $resultTopology->toZVF()->getLineArray();
    my $ok = 1;
    
    for my $index(1..$#compareLines) {
        $ok = 0 if( $compareLines[$index] ne $resultLines[$index]);
    }
    return $ok;
}

sub testPrintNets {
    my %testHash = (
        1 => "net1\n\n",
        3 => "net1,net2,net3\n\n",  
        0 => "\n\n"
    );

    my $ok = 1;
    foreach(sort keys %testHash){
        #print "TopologyGenerationFunctions::_printNets($_) == $testHash{$_}?\n";
        $ok = 0 if(TopologyGenerationFunctions::_printNets($_) ne $testHash{$_});
    }
    return $ok;
}

sub testRandomGraph {
}

sub testRow {
    my %testHash = (
        5 => new File("testcases/generated/row5.zvf"),
        20 => new File("testcases/generated/row20.zvf")
    );

    my $ok = 1;
    foreach(sort keys %testHash){
        $ok = compareTopologies(TopologyGenerationFunctions::row(new File("-"),$_),$testHash{$_});
    }
    return $ok;
}

sub testCircle {
    my %testHash = (
        5 => new File("testcases/generated/row5.zvf"),
        20 => new File("testcases/generated/row20.zvf"),
    );

    my $ok = 1;
    foreach(sort keys %testHash){
        $ok = compareTopologies(TopologyGenerationFunctions::circle(new File("-"),$_),$testHash{$_});
    }
    return $ok;
}


sub testStar2 {
    my %testHash = (
        5 => new File("testcases/generated/star2_05.zvf"),
        30 => new File("testcases/generated/star2_30.zvf"),
    );

    my $ok = 1;
    foreach(sort keys %testHash){
        $ok = compareTopologies(TopologyGenerationFunctions::star2(new File("-"),$_),$testHash{$_});
    }
    return $ok;
}

sub testConnectedstar2 {
    my %testHash = (
        5 => new File("testcases/generated/connectedstar2_05.zvf"),
        20 => new File("testcases/generated/connectedstar2_20.zvf"),
    );

    my $ok = 1;
    foreach(sort keys %testHash){
        $ok = compareTopologies(TopologyGenerationFunctions::connectedstar2(new File("-"),$_),$testHash{$_});
    }
    return $ok;
}

sub testStarn {
    my @arguments = ([(10,3)],[(4,8)]);
    my %testHash = (
        0 => new File("testcases/generated/star10_03.zvf"),
        1 => new File("testcases/generated/star4_08.zvf"),
    );

    my $ok = 1;
    foreach(sort keys %testHash){
        $ok = compareTopologies(TopologyGenerationFunctions::starn(new File("-"),@{$arguments[$_]}),$testHash{$_});
    }
    return $ok;
}

sub testMesh {
}

is(testPrintNets(),1,"printNets");
is(testRow(),1,"row");
is(testCircle(),1,"circle");
is(testStar2(),1,"star2");
is(testConnectedstar2(),1,"connectedstar2");
is(testStarn(),1,"starn");

