
#
# Package: RIPPacket
#
# computes tcpdumps with -x option
package RIPPacket;

use warnings;
use strict;

use lib "modules";
use Utilities;


##
# VARIABLES: Member variables
# timestamp - timestamp of the packetHash
# router - sending router
# net - net of sending router
# length - length in bytes with all headers
# packethash - Hash (net => metric) with each route of the packet

##
# Constructor of RIPPacket.
# 
# PARAMETERS:
# $timeStamp - timeStamp of the packet
# $router - router that sent the packetHash
# $content - string with hex values
sub new {#{{{
    my $object = shift;
    my $timeStamp = shift;
    my $router = shift;
    my $content = shift;
    my $length = shift;
    
    my $reference = {};
    bless($reference,$object);

    $reference->_initPacket($timeStamp,$router,$content,$length);
    return $reference;
}#}}}


##
# Returns human readable string with time, router and all routes of the packet
sub print {#{{{
    my $object = shift;
    my $output = "";
    $output.= Utilities::makeTime($object->{TIMESTAMP})." - ".$object->{ROUTER}.":\n";
    my %packetHash = %{$object->{PACKETHASH}};
    foreach my $net (sort keys %packetHash) {
        $output.= "\t$net with metric ".$packetHash{$net}."\n";
    }
    $output.= "\n";
    return $output;
}#}}}

##
# Returns the packet hash with routes and metrices
sub getPacketHash {#{{{
    my $object = shift;

    return %{$object->{PACKETHASH}};
}#}}}


## 
# Returns timestamp of packet
sub getPacketTimeStamp {#{{{
    my $object = shift;
    return $object->{TIMESTAMP};
}#}}}

## 
# Returns router that sent this packet
sub getRouter {#{{{
    my $object = shift;
    return $object->{ROUTER};
}#}}}

##
# Returns lenght of the packet in bytes
sub getPacketLength {#{{{
    my $object = shift;
    return $object->{LENGTH};
}#}}}

##
# Returns the net through wich this packet was sent
sub getNet {#{{{
    my $object = shift;
    return $object->{NET};
}#}}}

########### private functions ###########

##
# Is called from constructor
# 
# Generates packet hash with routes and metrices
sub _initPacket {#{{{
    my ($object,$timeStamp,$router,$content,$length) = @_;

    $object->{TIMESTAMP} = $timeStamp;
    $object->{ROUTER} = $router;
    ($object->{NET}) = $router =~ m/[0-9]{1,3}\.[0-9]{1,3}\.([0-9]{1,3})\.[0-9]{1,3}/;
    $object->{LENGTH} = $length;

    my @bytes = split(" ",$content);
    @bytes = @bytes[32..$#bytes]; # lösche header

    my %packetHash;                 # routes are stored here
    while($#bytes>2){
        splice(@bytes,0,4);
        my $netIP = join(".",hex(shift @bytes),hex(shift @bytes),hex(shift @bytes),hex(shift @bytes)); 
        splice(@bytes,0,8);
        #my $netMask = join(".",hex(shift @bytes),hex(shift @bytes),hex(shift @bytes),hex(shift @bytes)); 
        #my $nextHop = join(".",hex(shift @bytes),hex(shift @bytes),hex(shift @bytes),hex(shift @bytes)); 
        my $metric = hex((shift @bytes).(shift @bytes).(shift @bytes).(shift @bytes));
        $packetHash{$netIP} = $metric;
        #print "Net $netIP has metric $metric\n";
        #print "bytes = @bytes\n\n";
    }
    $object->{PACKETHASH} = \%packetHash; 
}#}}}

1;

# for a better use with vim. All the markings: #{{{ and #}}} belong to it
# vim: foldmethod=marker
