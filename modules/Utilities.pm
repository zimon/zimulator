# vim: foldmethod=marker

#
# Package: Utilities
#
# Provides general functions like <makeTimeStamp> or <remove>
package Utilities;
require Exporter;
@ISA = qw(Exporter);
@EXPORT =
  qw(makeTimeStamp makeTime remove getTime getTimeStamp mergeHashes getSimulationDirectory getResultFiles);

use strict;
use warnings;

use lib ".";
use File;

##
# Creates timestamp (time in µs) from tcpdump timestring
#
# PARAMETERS:
# $timestring - string with time from tcpdump
#
# RETURNS:
# timestamp in µs from 0:00 o'clock that day
sub makeTimeStamp {#{{{
	my $timestring=shift;
    return $timestring if not $timestring =~ /:/;
	my @timearray=split("[:\.]",$timestring);
	my $timestamp=$timearray[0]*60*60*1000000;
	$timestamp+=$timearray[1]*60*1000000;
	$timestamp+=$timearray[2]*1000000;
    #while(length($timearray[3])<6){ $timearray[3] = "0".$timearray[3]; }
	$timestamp+=$timearray[3];

	return $timestamp;
}#}}}

##
# Creates string with hour, min, sec, µsec from timestamp like time in tcpdump
# 
# PARAMETERS:
# $timestamp - timestamp generated with <makeTimeStamp>
# 
# RETURNS:
# human readable timestring
sub makeTime {#{{{
	my $timestamp = shift;
    return $timestamp if $timestamp =~ /:/;
	my $hour=int($timestamp/60/60/1000000);
	my $min=int($timestamp/60/1000000)-$hour*60;
	my $sec=int($timestamp/1000000)-$min*60-$hour*3600;
	my $msec=int($timestamp)-$hour*3600*1000000-$min*60*1000000-$sec*1000000;
	$hour = "0".$hour if(int($hour/10) == 0);
	$min = "0".$min if(int($min/10) == 0);
	$sec = "0".$sec if(int($sec/10) == 0);
    while(length($msec)<6){ $msec = "0".$msec; }

	my $time = $hour.":".$min.":".$sec.":".$msec;
	return ($time);
}#}}}

##
# Removes all items of a list from another list
#
# PARAMETERS:
# $listReference - reference of list where items should be removed from
# $deleteListReference - reference of list with items that should be removed from $netRef
# 
# RETURNS:
# list with removed items
sub remove {#{{{
    my ($listReference,$deleteListReference) = @_;
    my @list = @{$listReference};
    my @deleteList = @{$deleteListReference};
    my @newList = ();

    foreach my $item (@list) {
        my $ok = 1;
        foreach my $deleteItem (@deleteList) {
            if($item eq $deleteItem){
                $ok = 0;
                last;
            }
        }
        push(@newList,$item) if $ok == 1;
    }
    return @newList;
}#}}}

## 
# Returns actual time as string
sub getTime {#{{{
    my $time = `date +"%H:%M:%S.%N"`;
    chop $time;
    chop $time;
    chop $time;
    chop $time;

    return $time;
}#}}}

## 
# Returns actual time as timestamp
sub getTimeStamp {#{{{
    my $time = getTime();
    my $timeStamp = Utilities::makeTimeStamp($time);

    return $timeStamp;
}#}}}


##
# Merges multiple hashes together
# 
# PARAMETERS:
# @hashArray - list of hash references
#
# RETURNS:
# hash containing the key-value pairs of each hash
#sub mergeHashes {#{{{
#    my @hashArray = @_;
#    my %resultHash;
#    foreach my $hash (@hashArray){
#        my %actualHash = %{$hash};
#        foreach my $timeStamp (sort keys %actualHash){
#            my $offset = 0;
#            while(defined $resultHash{$timeStamp+$offset}){
#                $offset++;
#            }
#            $resultHash{$timeStamp+$offset} = $actualHash{$timeStamp};
#        }
#    }
#    return %resultHash;
#}#}}}


##
# Returns alls result files for a topology file
sub getResultFiles {#{{{
    my $topologyFile = shift;
    my ($topologyName,$baseDirectory,@ls) = getSimulationDirectory($topologyFile);
    my @result = ();
    foreach my $dir (@ls) {
        chomp $dir;
        my $resultFileName = "$baseDirectory$dir/$topologyName.txt";
        #print "resultfile: $resultFileName\n";
        push(@result,new File($resultFileName)) if -f $resultFileName;
    }
    return @result;
}#}}}

##
# Looks for simulation directories for a vigen topology file
#
# PARAMETERS:
# $topologyFile - topology file object
# 
# RETURNS:
# topologyName - string with name of topology
# baseDirectory - directory where topology file is located
# list of simulation directories
sub getSimulationDirectory {#{{{
    my $topologyFile = shift;
    my $topologyName = $topologyFile->getName();
    my $baseDirectory = $topologyFile->getDirectory();
    $baseDirectory = "" if not defined $baseDirectory;
    my $executionString = "ls $baseDirectory | egrep .*\-$topologyName\$";
    #print "execstring: $executionString\n";
    my @ls = `$executionString`; # getting all simulations with this topology
    return ($topologyName,$baseDirectory,@ls) 
#    if($#ls > 0){#{{{
#        while(1){
#        
#            my $choice = "";
#            print "\n\nPlease choose simulation directory:\n";
#            my $x = 0;
#            foreach my $d (@ls) {
#                chomp $d;
#                $x++;
#                print "\t[$x] : $d\n";
#            }
#            print "Press x to exit.\n";
#            print "Insert number of directory or press enter for all: ";
#            $choice = <STDIN>;
#            chomp $choice;
#            print "choice: $choice\n";
#            
#            print "\nExiting\n" and exit 0 if $choice eq "x";
#            print "\nTaking all: @ls\n" and return ($topologyName,$baseDirectory,@ls) if $choice eq "";
#            print "\nPlease choose one of the numbers\n" and next if not $choice =~ /^[0-9]+$/;
#            print "\nPlease choose one of the numbers\n" and next if ($choice < 0) or ($choice > $#ls);
#
#            if($choice =~ /[0-9]+/){
#                print "\nTaking $x-2. item: ".$ls[$x-2]."\n"; 
#                return ($topologyName,$baseDirectory,$ls[$x-2]) 
#            }
#        
#        }
#    } elsif($#ls==0){
#                return ($topologyName,$baseDirectory,@ls) 
#    } else {
#        return 0;
#    }#}}}
}#}}}


1;
