#
# Package: RIPParser
#
# Provides functions to parse tcpdumps and calculate convergence properties
package RIPParser;
@ISA=("Parser");

use warnings;
use strict;

use lib "modules";
use Utilities;
use Scenario;
use RIPPacket;
use Topology;

##
# VARIABLES: Member variables
# topology - topology object
# options - parsing options. Can be "-from" or "-to". "-from" deletes all packets with timestamps smaller than $timeStamp. "-to" deletes all packets with timestamps later than $timeStamp.
# failuretime - timestamp of shutting down a router or device
# name - topology name
# packets - array with RIPPacket objects ordered by timestamp

##
# *Constructor*
# 
# PARAMETERS:
# $topology - topology object of the simulation
# $options - parsing options, see <options>
# $failureTime - timestamp of router or device shutdown
# @files - file objects of dump files
sub new {#{{{
    my $object = shift;
    my $topology = shift;
    my $options = shift;
    my $failureTime = shift;
    my @files = @_;
    my $reference = {};
    bless($reference,$object);
    $reference->_initRIPParser($topology,$options,$failureTime,@files);
    return($reference);
}#}}}

##
# Returns a file object with the packet informations of one or more dump files in human readable format chronological sorted
sub getHumanReadableDumpFile {#{{{
    my $object = shift;
    my @packets = @{$object->{PACKETS}};
    my $firstTimeStamp = $object->_getFirstTimeStamp();
    return 0 if $firstTimeStamp == -1;
    my $config = Configuration::instance();
    my $outputFileName = $config->getOption("OUTPUT_FILENAME");
    $outputFileName = "-" unless $outputFileName;
    my $outputFile = new File($outputFileName);
    $outputFile->clearFile();
    
    foreach my $packet (@packets){
            my $line = Utilities::makeTime($packet->getPacketTimeStamp()-$firstTimeStamp).":\n".$packet->print();
            print $line if $outputFileName eq "-";
            $outputFile->addLine($line) if $outputFileName ne "-";
    }

    return $outputFile;
}#}}}

##
# Calculates the time packets and traffic until net is convergent from packets
# 
# RETURNS:
# Hash with results of the measurements
sub getResultHash {#{{{
    my $object = shift;
    my $topology = $object->{TOPOLOGY};
    my $opt = $object->{OPTIONS};
    my $failureTime = $object->{FAILURETIME};
    my %results;
    my $firstTimeStamp = $object->_getFirstTimeStamp();
    return () if $firstTimeStamp == -1;
    $failureTime = 0 unless defined $failureTime;

    # calculate first and last timestamp
    $failureTime = Utilities::makeTimeStamp($failureTime) if $failureTime =~ /:/;
    if($opt eq "-from"){
        $firstTimeStamp = ($failureTime eq "cti") ? $object->_getFirstTimeStamp("cti") : $failureTime;
    }
    #print "firstTimeStamp: $firstTimeStamp (".Utilities::makeTime($firstTimeStamp).")\n";
    $object->{PACKETS} = $object->_removePackets(0,$failureTime) if $opt eq "-to";
    my @packets = $object->{PACKETS};
    #print "there are ".@packets." packets\n";
    my $lastTimeStamp=0;
    $lastTimeStamp = $object->_getLastTimeStamp();
    #print "lastTimeStamp: $lastTimeStamp (".Utilities::makeTime($lastTimeStamp).")\n";

    # prepare for creating statistics
#    print STDERR "firstTimeStamp=$firstTimeStamp, lastTimeStamp=$lastTimeStamp\n";
    my @relevantPackets = @{$object->_removePackets($firstTimeStamp,$lastTimeStamp)};
    return () unless @relevantPackets;
    my ($totalPacketCount,$mostPacketsNet,$mostPacketsNetCount,$leastPacketsNet,$leastPacketsNetCount) = (0,0,0,0,99999999999999);
    my ($totalTraffic,$maxTrafficNet,$maxTraffic,$minTrafficNet,$minTraffic) = (0,0,0,0,99999999999999);

    # creat traffic and packet statistics
    my @netPackets;
    my @netTraffic;
    foreach my $p(@relevantPackets){
        my $net = $p->getNet();
        $netPackets[$net-1]++;
        $netTraffic[$net-1]+=$p->getPacketLength();
    }
    #print STDERR "nets: [@netPackets]\n";
    foreach my $net(0..$#netPackets){ #{{{
        next unless defined $netPackets[$net] and defined $netTraffic[$net];
        if($netPackets[$net] > $mostPacketsNetCount){
            $mostPacketsNetCount=$netPackets[$net];
            $mostPacketsNet = $net+1;
        }
        if($netPackets[$net] < $leastPacketsNetCount){
            $leastPacketsNetCount = $netPackets[$net];
            $leastPacketsNet = $net+1;
        }
        if($netTraffic[$net] < $minTraffic){
            $minTraffic = $netTraffic[$net];
            $minTrafficNet = $net+1;
        }
        if($netTraffic[$net] > $maxTraffic){
            $maxTraffic = $netTraffic[$net];;
            $maxTrafficNet = $net+1;
        }
        $totalPacketCount += $netPackets[$net];
        $totalTraffic += $netTraffic[$net];
    }#}}}

    my $averagePacketCount = $totalPacketCount / @netPackets;
    my $averageTraffic = $totalTraffic / @netTraffic;
    my $timeToConvergence = $lastTimeStamp-$firstTimeStamp;

    # create result hash #{{{
    $results{FAILURETIME} = $failureTime;
    $results{FIRSTTIMESTAMP} = $firstTimeStamp;
    $results{LASTTIMESTAMP} = $lastTimeStamp;
    $results{AVERAGEPACKETCOUNT} = $averagePacketCount;
    $results{MOSTPACKETSNET} = $mostPacketsNet;
    $results{MOSTPACKETSNETCOUNT} = $mostPacketsNetCount;
    $results{LEASTPACKETSNET} = $leastPacketsNet;
    $results{LEASTPACKETSNETCOUNT} = $leastPacketsNetCount;
    $results{TOTALPACKETCOUNT} = $totalPacketCount;
    $results{TOTALTRAFFIC} = $totalTraffic/1024;
    $results{AVERAGETRAFFIC} = $averageTraffic/1024;
    $results{MAXTRAFFIC} = $maxTraffic/1024;
    $results{MAXTRAFFICNET} = $maxTrafficNet;
    $results{MINTRAFFIC} = $minTraffic/1024;
    $results{MINTRAFFICNET} = $minTrafficNet;
    $results{TOPOLOGYNAME} = $topology->getName();
    $results{TIMETOCONVERGENCE} = $timeToConvergence/1000000;#}}}
    #print STDERR "avgtraffic: $results{AVERAGETRAFFIC}, total: $results{TOTALTRAFFIC}, count:".@netTraffic." (shoul be around ".($results{TOTALTRAFFIC}/@netTraffic)."\n";

    return %results;

}#}}}

##
# Checks if a CTI happened in given net
# 
# Checks if there exist routes with metrik $offset up to infinity metric in the dumps. 
# Maybe this could be changed to minOffset-maxOffset to identify started but not finished CTI situations
#
# PARAMETERS:
# $ctiNet - Net in which the CTI is expected
# $offset - Metric at which should be started
#
# RETURNS:
# 1 if CTI is detected. 0 otherwise.
sub checkCTI{#{{{
    my $object = shift;
    my $ctiNet = shift;
    my $offset = shift;
    my @packets = @{$object->{PACKETS}};
    my $firstTimeStamp = $object->_getFirstTimeStamp();
    return 0 if $firstTimeStamp == -1;
    my $configuration = Configuration::instance();
    my $maxOffset = $configuration->getOption("INFINITY_METRIC");
    my $ctiNetIP = "10.0.$ctiNet.0";
    #print "ctiNetIP = $ctiNetIP, offset = $offset\n";

    foreach my $packet (@packets) {
        my %packetHash = $packet->getPacketHash();
        foreach my $netIP (keys %packetHash){
            next unless $netIP eq $ctiNetIP;
            #print "$netIP = $ctiNetIP\n";
            #print "$offset = $packetHash{$netIP}?\n";
            $offset++ if $packetHash{$netIP} == $offset;
            return 1 if $offset == $maxOffset;
        }
    }
    return 0;
}#}}}


##
# Sets necessary member variables and converts dump files into a list of RIP-Packet objects ordered by timestamp
sub _initRIPParser {#{{{
    my $object = shift;
    my $topology = shift;
    my $options = shift;
    my $failureTime = shift;
    my @files = @_;

    $object->{TOPOLOGY} = $topology;
    $object->{OPTIONS} = $options;
    $object->{FAILURETIME} = $failureTime;
    $object->{NAME} = $topology->getName();

    my @allLines;
    foreach my $file (@files){ next unless $file->getFileName() =~ /\.dump$/; push(@allLines,$file->getLineArray()); }
    my %dumpHash = %{$object->_getPacketProperties($object->_flattenDump(\@allLines))};
    my @keys = keys %dumpHash;
    #print "there are ".@keys." dumpHash keys\n";
    my @packetList;

    foreach my $timeStamp (sort keys %dumpHash){
        my ($router,$content,$lenght) = @{$dumpHash{$timeStamp}};
        my $packet = 0;
        # creating packet out of dump content
        $packet = RIPPacket->new($timeStamp,$router,$content,$lenght) if $content =~ /^45 00 /;
        push(@packetList,$packet);
    }
    #print "there are ".@packetList." packets\n";
    $object->{PACKETS} = \@packetList;
}#}}}

##
# Creates one line for each packet in dump.  
# 
# PARAMETERS:
# $lineReference - list reference with lines of all dumps concatenated
# 
# RETURNS:
# List reference of lines with one packet per line
sub _flattenDump {#{{{
    my $object = shift;
	my $lineReference = shift;
    my @lines = @{$lineReference};
	my @packets = ();
    return \@packets if $#lines == -1;
	my $actualLine = shift @lines;
    my @lineSplit = split(" ",$actualLine);
    my $actualTimeStamp = Utilities::makeTimeStamp($lineSplit[0]);
	foreach my $line (@lines){
		chomp $line;
        @lineSplit = split(" ",$line);
		if($line =~ /^[0-9]+:[0-9]+:/){                                 # if line begins with timestamp
            my $newTimeStamp = Utilities::makeTimeStamp($lineSplit[0]); # a new line is created
                push(@packets,$actualLine);
                $actualLine = $line;
                $actualTimeStamp = $newTimeStamp;
		}else{                                                          # else the line gets appended to the actual one
			$actualLine .= " ".$line;
		}
	}
	push(@packets,$actualLine);
    return \@packets
}#}}}

## 
# Removes packets from other services then RIPv2 and extracts informations from RIPv2 packets
#
# Extracts the timestamp, sending ip, length and contentline with one byte per word
# 
# PARAMETERS:
# $packetReference - array reference with packetstrings (generated by <flattenDump>)
# 
# RETURNS:
# Hash with 
# key - timestamp of packet 
# value - list with: sending router, content and length
sub _getPacketProperties {#{{{
    my $object = shift;
    my $packetReference = shift;
    my @packets = @{$packetReference};
    my %resultHash;
    foreach my $l (@packets){                                   # for each packet
        next unless $l =~ /RIPv2/;                              # ignore it if it is no RIPv2 packet
        my ($length) = $l =~ m/length: ([0-9]+)/;               # get length of packet (without headers)
        my @split = split(" ",$l);
        my $timestamp = Utilities::makeTimeStamp(shift @split); # get the timestamp
        shift @split;
        my $router = shift @split;                              # get the ip address
        $router =~ s/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+).*/$1/;
        #print "router = $router\n";
        my $content = "";
        foreach(@split){                                        # format content
        #    $content .= $_." " if /^[0-9a-fA-F]{4}$/o;           # ignore format strings
            $content .= substr($_,0,2)." ".substr($_,2,2)." " if /^[0-9a-fA-F]{4}$/o;           # ignore format strings
        }
        #$content =~ s/([0-9a-fA-F]{2})([0-9a-fA-F]{2})/$1 $2/go; # print a space between each byte
        chomp $content;
        my @value = ($router,$content,int($length)+28);         # create content list (28 bytes are added to lenght for the header)
        $resultHash{$timestamp} = \@value; 
    }
    
	return \%resultHash;
}#}}}


##
# Determines first timestamp of the run
#
# RETURNS:
# The first timestamp of all dumps from a run
sub _getFirstTimeStamp {#{{{
    my $object = shift;
    my $parameter = shift;
	my @packets = @{$object->{PACKETS}};
    my $firstPacket = -1;
    if(defined $parameter and $parameter eq "cti"){
        foreach my $packet (@packets) {
            my %hash = $packet->getPacketHash();
            foreach my $net (keys %hash) {
               next if $net eq "0.0.0.0"; 
               $firstPacket = $packet and last if $hash{$net} == 16;
            }
            last if $firstPacket != -1;
        }
    } else {
        $firstPacket = $packets[0];
    }
    #print $firstPacket->getPacketTimeStamp()." (".Utilities::makeTime($firstPacket->getPacketTimeStamp()).") is first packet\n";
    return -1 unless defined $firstPacket or $firstPacket == -1;
	return $firstPacket->getPacketTimeStamp();
}#}}}
  

# Generates a list of routing tables (router numbers are used as index). Each routing table is a hash with key="ip address of net" and value=list of metric to the net, router which send the update and timestamp of the update package.
#
# This Function sets only the connected nets with metric = 1, router = "self" and timestamp = 0
# 
# RETURNS:
# List of routing tables (as hash references)
sub _prepareRoutingTables {#{{{
    my $object = shift;
    my $topology = $object->{TOPOLOGY};
    my %routers = %{$topology->getRouters()};
    my @routerTables = ();
    foreach my $router (sort keys %routers) {
        my @nets = split(",",$routers{$router});
        my ($routerNumber) = $router =~ m/^r([0-9]+)/;
        my %routerTable;
        foreach my $net (@nets){ 
            my ($netNumber) = $net =~ m/net([0-9]+)/;
            my @entry = (1,"self",0);
            $routerTable{"10.0.".$netNumber.".0"} = \@entry;
        }
        $routerTables[$routerNumber] = \%routerTable;
    }
    return \@routerTables;
}#}}}

##
# Calculates the timestamp of the packet that leads to the convergence of the whole scenario.
#
# This function implements a small rip simulation to calculate the resulting routing tables for each packet.
# 
# RETURNS:
# Timestamp of packet that lead to convergence
# 
sub _getLastTimeStamp {#{{{
    my $object = shift;
    my $opt = $object->{OPTIONS};
    my $topology = $object->{TOPOLOGY};
    my @packets = @{$object->{PACKETS}};
    my $config = Configuration::instance();
	my @results=();
	my $lastTimeStamp=0;
    my @routerTables = @{$object->_prepareRoutingTables()};
    my $timeoutTime = $config->getOption("TIMEOUT_TIMER")*1000000;
    my $garbageTime = $config->getOption("GARBAGE_TIMER")*1000000;
    my $infMetric = $config->getOption("INFINITY_METRIC");

    foreach my $packet (@packets) {
        my $router = $packet->getRouter();
        my $net = $packet->getNet();
        my @routersInNet = @{$topology->getRoutersInNet("net$net")};
        #print "Routers in net $net: [@routersInNet]\n";
        my %packetHash = $packet->getPacketHash();
        my $packetTimeStamp = $packet->getPacketTimeStamp();
        foreach my $netIP (sort keys %packetHash) { # every route in the packet is processed
            my $newMetric = $packetHash{$netIP}; 
            foreach my $r (@routersInNet) { # each router in the net gets the update
                my ($routerNumber) = $r =~ m/^r([0-9]+)/;
                next if $router =~ /10\.0\.[0-9]+\.$routerNumber/;

                my ($oldMetric,$oldRouter,$oldTime) = ($infMetric,"",0);
               ($oldMetric, $oldRouter, $oldTime) = @{$routerTables[$routerNumber]->{$netIP}} if ref $routerTables[$routerNumber]->{$netIP};
                die "not defined oldmetric" unless defined $oldMetric;
                die "not defined oldrouter" unless defined $oldRouter;
                die "not defined oldtime" unless defined $oldTime;
#                print "Router $r gets $netIP from $router with $newMetric (old was $oldMetric)\n";
                my @newEntry = ();
                
                if($oldMetric > $newMetric) { # take new entry if metric is better
#                    print "taking new entry because of better metric\n";
                    @newEntry = ($newMetric, $router, $packetTimeStamp);
                    $lastTimeStamp = $packetTimeStamp;
                } elsif($oldMetric == $newMetric){ # update time if metric is equal
#                    print "updating time\n";
                    @newEntry = ($oldMetric, $oldRouter, $packetTimeStamp);
                } else { # look at sending router if metric is worse
                    if($oldRouter eq $router){ # take new entry if old router and new router are equal
#                        print "taking new entry because it comes from the same router\n";
                        @newEntry = ($newMetric, $router, $packetTimeStamp);
                        $lastTimeStamp = $packetTimeStamp;
                    } else { # if update came from another router

                        # take entry if timeout time is reached
                        if($packetTimeStamp > $oldTime+($timeoutTime)){ 
#                        print "taking new entry because of timeout\n";
                            @newEntry = ($newMetric, $router, $packetTimeStamp);
                            $lastTimeStamp = $packetTimeStamp;
                        } else { # else keep old entry
                            @newEntry = ($oldMetric, $oldRouter, $oldTime);
                        }
                    }
                }

                # TODO: delete entry if garbage collector time is reached. This is not important as it works without deletion of old routes

                # save new entry
                $routerTables[$routerNumber]->{$netIP} = [@newEntry];
            }
        }
    }
    return $lastTimeStamp;
}#}}}





##
# Removes lines before the firts and after the last timestamp
# 
# PARAMETERS:
# $firstTimeStamp - minimal timestamp for a packet
# $lastTimeStamp - maximal timestamp for a packet
# 
# RETURNS:
# Reference to new list of packets
sub _removePackets {#{{{
    my $object = shift;
    my $firstTimeStamp = shift;
    my $lastTimeStamp = shift;
    my @packets = @{$object->{PACKETS}};

    my @newList;
    @newList = grep(($_->getPacketTimeStamp >= $firstTimeStamp and $_->getPacketTimeStamp() <= $lastTimeStamp),@packets);
    return \@newList;
}#}}}


1;



# for a better use with vim. All the markings: #{{{ and #}}} belong to it
# vim: foldmethod=marker    
