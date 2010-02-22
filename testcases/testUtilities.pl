#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;

use lib "../modules";
use Utilities;

# Debugging on when testing
$" = '] ['; # set field seperator for list to string conversion
use DebugMessages exit_on_warning => 1, fatal => 3, warnings => 3, level => 5;

$" = '] ['; # set field seperator for list to string conversion
use DebugMessages exit_on_warning => 1, fatal => 3, warnings => 3, level => 5;

my $verbose = 0;
$verbose = 1 if defined $ARGV[0] and $ARGV[0] eq "-v";

sub testMakeTime{

    my %testhash = (123456 => "00:00:00:123456", # Test h=m=s=0
            1 => "00:00:00:000001",
            1000000 => "00:00:01:000000",       # test h=ns=0 m=s=1
            61000000 => "00:01:01:000000",       # test h=ns=0 m=s=1
            3721000001 => "01:02:01:000001",  # 
            7200999999 => "02:00:00:999999");

        my $ok = 1;
        print "time u wanted to know: ".Utilities::makeTime(52961311936)."\n";
    foreach(sort keys %testhash){
        #print "$testhash{$_} = ".Utilities::makeTime($_)."\n";
        $ok = 0 if(Utilities::makeTime($_) ne $testhash{$_});
    }
    return $ok;
}

sub testMakeTimeStamp{

    my %testhash = ("01:10:01:123456" => 4201123456, 
            "00:00:00:000001" => 1,
            "00:01:10:010101" => 70010101, 
            "02:00:00:999999" => 7200999999);

        my $ok = 1;
    foreach(sort keys %testhash){
        #print "$testhash{$_} = ".Utilities::makeTime($_)."\n";
        $ok = 0 if(Utilities::makeTimeStamp($_) != $testhash{$_});
    }
    return $ok;
}


is(testMakeTime(),1,"makeTime");
is(testMakeTimeStamp(),1,"makeTimeStamp");
