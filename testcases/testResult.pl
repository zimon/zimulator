#!/usr/bin/perl
# vim: foldmethod=marker

use strict;
use warnings;
use Test::More tests => 3;
use Carp;
use lib "../modules";
use Result;
use ResultFile;
use Topology;
use File;

# Debugging on when testing
$" = '] ['; # set field seperator for list to string conversion
use DebugMessages exit_on_warning => 1, fatal => 3, warnings => 3, level => 10;

my $verbose = 0;
$verbose = 1 if defined $ARGV[0] and $ARGV[0] eq "-v";

sub prepareResult {#{{{
    my $topologyFileName = shift;
    my $topology = new Topology(new File($topologyFileName));
    open(FILE,"<$topologyFileName");
    my @lines = <FILE>;
    close(FILE);
    my @testArray = grep(/^[a-zA-Z0-9_ \t]/,@lines);
    map(chomp,@testArray);
    
    return ($topology,@testArray);
}#}}}

sub testAddRun {#{{{

    #TODO: einfachere runs testen (und nachrechnen), auch recalculate testen
    my $failureTime = 0;
    my @fileNames = `ls simulate30sec-circle05/rip_run_1`;
    my %testHash = ( MAXTRAFFICNET => 5,
        PROTOCOL => "rip",
        MINTRAFFICNET => 4,
        FAILURETIME => 0,
        TOPOLOGYNAME => "circle05",
        LEASTPACKETSNET => 4,
        TIMETOCONVERGENCE => 9.042536,
        MINTRAFFIC => 0.34375,
        TOTALTRAFFIC => 2.19140625,
        TOTALPACKETCOUNT => 37,
        MOSTPACKETSNETCOUNT => 8,
        LEASTPACKETSNETCOUNT => 6,
        MAXTRAFFIC => 0.5234375,
        AVERAGEPACKETCOUNT => 7.4,
        AVERAGETRAFFIC => 0.43828125,
        MOSTPACKETSNET => 1,
        LASTTIMESTAMP => 68187714696,
        INTERNRUNCOUNT => 1,
        FIRSTTIMESTAMP => 68178672160
    );
    my @files = ();

    foreach(@fileNames){ push(@files,(new File("simulate30sec-circle05/rip_run_1/".$_))); }

    my $topologyFile = new File("circle05.zvf");
    my @lines = $topologyFile->getLineArray();
    my $result = new Result(new File("simulate30sec-circle05/circle05.txt"),new Topology($topologyFile),"","rip");
    $result->addRun("rip","",$failureTime,1,@files);

    my @runs = @{$result->{RUNS}};
    my $runCount = $#runs;
    my %resultHash = %{$runs[$runCount]};
    print map { "$_ => $resultHash{$_}\n" } keys %resultHash if $verbose;
    $runCount++;

    is($runCount,21,"addRun() - testing number of runs - with run 1 of circle05");
    is_deeply(\%resultHash,\%testHash,"addRun() - testing result hash - with run 1 of circle05");

}#}}}

sub testGetAverage {#{{{
    my $topologyFile = new File("circle05.zvf");
    my $result = new Result(new ResultFile("testResult.txt"),new Topology($topologyFile),"","rip");
    my %avgHash = %{$result->_getAverage()->[0]};
    my %compareHash = ();

    $compareHash{DIAMETER} = 2;
    $compareHash{VERTICES} = 5;
    $compareHash{LEAVES} = 0;
    $compareHash{INNERVERTICES} = 5;
    $compareHash{EDGES} = 5;
    $compareHash{CC} = 0.5;
    $compareHash{TOPOLOGYNAME} = "circle05";
    $compareHash{MAXTOTALPACKETS} = 35;
    $compareHash{MINTOTALPACKETS} = 25;
    $compareHash{AVERAGETOTALPACKETS} = 30;
    $compareHash{MAXAVERAGEPACKETS} = 14;
    $compareHash{MINAVERAGEPACKETS} = 2;
    $compareHash{AVGAVERGAPACKETS} = 6;
    $compareHash{LONGESTTIME} = 11;
    $compareHash{SHORTESTTIME} = 10.5;
    $compareHash{AVERAGETIME} = 10.75;
    $compareHash{MAXTOTALTRAFFIC} = 2.5;
    $compareHash{MINTOTALTRAFFIC} = 1.9;
    $compareHash{AVERAGETOTALTRAFFIC} = 2.2;
    $compareHash{AVGAVERAGETRAFFIC} = 0.3665;

    is_deeply(\%avgHash,\%compareHash,"getAverage");

}#}}}

sub testRecalculateRun {
}

sub testRecalculateAllRuns {
}

testAddRun();
testGetAverage();
