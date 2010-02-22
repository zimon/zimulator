#!/usr/bin/perl
# vim: foldmethod=marker

use strict;
use warnings;
use Test::More tests => 10;
use Carp;
use lib "../modules";
use RIPParser;
use RIPPacket;
use Utilities;
use File;
use Configuration;
use Topology;

# Debugging on when testing
$" = '] ['; # set field seperator for list to string conversion
use DebugMessages exit_on_warning => 1, fatal => 3, warnings => 3, level => 5;

my $verbose = 0;
$verbose = 1 if defined $ARGV[0] and $ARGV[0] eq "-v";



sub prepareRIPParser {#{{{
    my $name = shift;
    my $run = shift;
    my @fileNames = `ls simulate60sec-$name/rip_run_1/`;
    my @files = ();
    foreach my $fileName (@fileNames) {
        next if not $fileName =~ /\.dump$/;
        push(@files,new File("simulate60sec-$name/rip_run_$run/$fileName"));
    }

    my $parser = new RIPParser(new Topology(new File($name.".zvf")),"","",@files);

    return ($parser,@files);
}#}}}

sub testClass {#{{{
    my ($parser,@files) = prepareRIPParser("circle5_row4",2);
    my @packets = @{$parser->{PACKETS}};
    my $timestamp = $parser->_getLastTimeStamp();
    #print "time = ".Utilities::makeTime($timestamp)."\n";
}#}}}

sub testGetLastTimeStamp{#{{{
    my $ok = 1;

    # testing specification
    my $packet1 = new RIPPacket(1000000,"10.0.1.1","",2);
    my $packet2 = new RIPPacket(2000000,"10.0.1.1","",2);
    my $packet3 = new RIPPacket(4000000,"10.0.1.1","",2);
    my $packet4 = new RIPPacket(4500000,"10.0.1.1","",2);
    my $packet5 = new RIPPacket(50000000,"10.0.1.3","",2);
    $packet1->{PACKETHASH} = { "10.0.1.0" => 1, "10.0.2.0" => 1 };
    $packet2->{PACKETHASH} = { "10.0.2.0" => 2 };
    $packet3->{PACKETHASH} = { "10.0.2.0" => 3 };
    $packet4->{PACKETHASH} = { "10.0.2.0" => 3 };
    $packet5->{PACKETHASH} = { "10.0.2.0" => 5 };


    my $parser = new RIPParser(new Topology(new File("hyperedge_net1r1.zvf")),"",0);
    my @packetList = ($packet1,$packet2,$packet3,$packet4);
    $parser->{PACKETS} = \@packetList;
    my $resultTime = $parser->_getLastTimeStamp();
    print "test time: $resultTime\n" if $verbose;
    print "should be: 0\n" if $verbose;
    is($resultTime,0,"getLastTimeStamp with only 1 router");

    
    $parser = new RIPParser(new Topology(new File("net1r2.zvf")),"",0);
    @packetList = ($packet1);
    $parser->{PACKETS} = \@packetList;
    $resultTime = $parser->_getLastTimeStamp();
    print "test time: $resultTime\n" if $verbose;
    print "should be: 1000000\n" if $verbose;
    is($resultTime,1000000,"getLastTimeStamp better metric");


    $parser = new RIPParser(new Topology(new File("net1r2.zvf")),"",0);
    @packetList = ($packet1,$packet2);
    $parser->{PACKETS} = \@packetList;
    $resultTime = $parser->_getLastTimeStamp();
    print "test time: $resultTime\n" if $verbose;
    print "should be: 2000000\n" if $verbose;
    is($resultTime,2000000,"getLastTimeStamp same router");

    @packetList = ($packet1,$packet2,$packet3);
    $parser->{PACKETS} = \@packetList;
    $resultTime = $parser->_getLastTimeStamp();
    print "test time: $resultTime\n" if $verbose;
    print "should be: 4000000\n" if $verbose;
    is($resultTime,4000000,"getLastTimeStamp same router 2");

    @packetList = ($packet1,$packet2,$packet3,$packet4);
    $parser->{PACKETS} = \@packetList;
    $resultTime = $parser->_getLastTimeStamp();
    print "test time: $resultTime\n" if $verbose;
    print "should be: 4000000\n" if $verbose;
    is($resultTime,4000000,"getLastTimeStamp no update");

    @packetList = ($packet1,$packet2,$packet3,$packet4,$packet5);
    $parser->{PACKETS} = \@packetList;
    $resultTime = $parser->_getLastTimeStamp();
    print "test time: $resultTime\n" if $verbose;
    print "should be: 50000000\n" if $verbose;
    is($resultTime,50000000,"getLastTimeStamp timeout");


    # Testing with real runs
    my %testHash = ("internet2_new" => "12:32:54:145507","arpa72" => "03:28:04:726553","circle5_row4" => "23:58:09:583817");

    foreach my $name (keys %testHash) {
        my ($parser) = prepareRIPParser($name,1);
        my $timestamp = $parser->_getLastTimeStamp();
        print "test time: ".Utilities::makeTime($timestamp)."\nshould be: $testHash{$name}\n\n" if $verbose;
        is($timestamp,Utilities::makeTimeStamp($testHash{$name}),"getLastTimeStamp with $name");
    }
}#}}}

sub testGetResultHash {#{{{
    my $ok = 1;

    # testing specification
    my $packet1 = new RIPPacket(10,"10.0.1.1","",200);
    my $packet2 = new RIPPacket(20,"10.0.3.1","",400);
    my $packet3 = new RIPPacket(30,"10.0.1.2","",200);
    my $packet4 = new RIPPacket(40,"10.0.3.3","",400);
    my $packet5 = new RIPPacket(41,"10.0.2.3","",200);
    my $packet6 = new RIPPacket(42,"10.0.1.3","",400);
    my $packet7 = new RIPPacket(43,"10.0.1.1","",200);
    my $packet8 = new RIPPacket(45,"10.0.1.2","",400);
    my $packet9 = new RIPPacket(500,"10.0.3.1","",300);
    $packet1->{PACKETHASH} = { "10.0.3.0" => 3 };
    $packet2->{PACKETHASH} = { "10.0.1.0" => 3 };
    $packet3->{PACKETHASH} = { "10.0.2.0" => 2 };
    $packet4->{PACKETHASH} = { "10.0.2.0" => 2 };
    $packet5->{PACKETHASH} = { "10.0.1.0" => 4 };
    $packet6->{PACKETHASH} = { "10.0.2.0" => 3 };
    $packet7->{PACKETHASH} = { "10.0.1.0" => 2 };
    $packet8->{PACKETHASH} = { "10.0.2.0" => 1 };
    $packet9->{PACKETHASH} = { "10.0.3.0" => 5 };

    my $parser = new RIPParser(new Topology(new File("triangle.zvf")),"",0);
    my @packetList = ($packet1,$packet2,$packet3,$packet4,$packet5,$packet6,$packet7,$packet8,$packet9);
    $parser->{PACKETS} = \@packetList;
    my %resultHash = $parser->getResultHash();

    my %compareHash = ();
    $compareHash{FAILURETIME} = 0;
    $compareHash{FIRSTTIMESTAMP} = 10;
    $compareHash{LASTTIMESTAMP} = 45;
    $compareHash{AVERAGEPACKETCOUNT} = 8/3;
    $compareHash{MOSTPACKETSNET} = 1;
    $compareHash{MOSTPACKETSNETCOUNT} = 5;
    $compareHash{LEASTPACKETSNET} = 2;
    $compareHash{LEASTPACKETSNETCOUNT} = 1;
    $compareHash{TOTALPACKETCOUNT} = 8;
    $compareHash{TOTALTRAFFIC} = 2400/1024;
    $compareHash{AVERAGETRAFFIC} = 800/1024;
    $compareHash{MAXTRAFFIC} = 1400/1024;
    $compareHash{MAXTRAFFICNET} = 1;
    $compareHash{MINTRAFFIC} = 200/1024;
    $compareHash{MINTRAFFICNET} = 2;
    $compareHash{TOPOLOGYNAME} = "triangle";
    $compareHash{TIMETOCONVERGENCE} = 35/1000000;#}}}

    is_deeply(\%resultHash,\%compareHash,"getResultHash");
}#}}}


#testClass;
testGetLastTimeStamp();
testGetResultHash();
