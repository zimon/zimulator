#
# Package: Parser
#
# Provides functions to parse tcpdumps and calculate convergence properties
package Parser;

use warnings;
use strict;

#use lib "modules";
#use Utilities;
#use Scenario;
#use Topology;

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
#    my $object = shift;
#    my $topology = shift;
#    my $options = shift;
#    my $failureTime = shift;
#    my @files = @_;
#    my $reference = {};
#    bless($reference,$object);
#    return($reference);
}#}}}

##
# Empty function that must be implemented by all specialised classes.
sub getHumanReadableDumpFile {#{{{
}#}}}

##
# Empty function that must be implemented by all specialised classes.
# 
sub getResultHash {#{{{
}#}}}


1;



# for a better use with vim. All the markings: #{{{ and #}}} belong to it
# vim: foldmethod=marker    
