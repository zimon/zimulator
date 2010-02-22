#!/usr/bin/perl

# Script: checkRunning.pl
#
# Checks every 5 minutes if zimulator is running. If VNUML or zimulator hangs, it gets restarted using restart.pl
use warnings;
use strict;

use lib "modules";
use Utilities;

my $oldFileSize = 0;
my $fileSize = 1;

sub restart {
    print "\nfileSize: $fileSize, oldFileSize: $oldFileSize\n";
    print "restarting at ".Utilities::getTime()."...\n\n";

    system("./restart.pl");
    print "... done\n\n";

}

while(1){
    # check if zimulator.pl is running (and exit if not)
    my $running = `ps -e | grep zimulator`;
    print "zimulator.pl is not running!\n" and exit 0 unless $running;

    $fileSize = `ls -l | grep simulations.out | awk '{print \$5}'`;
    chomp $fileSize;
    if($fileSize eq $oldFileSize){
        restart();
    } else {
        print "still running fine at ".Utilities::getTime()."\n";
    }
    sleep 360;
    $oldFileSize = $fileSize;
}

