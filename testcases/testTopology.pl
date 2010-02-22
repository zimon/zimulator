#!/usr/bin/perl
# vim: foldmethod=marker

use strict;
use warnings;
use Test::More tests => 40;
#use Test::Output;

use Carp;

use lib "../modules";
use Topology;
use File;
use TopologyFile;
use Configuration;

# Debugging on when testing
$" = '] ['; # set field seperator for list to string conversion
use DebugMessages exit_on_warning => 1, fatal => 3, warnings => 3, level => 10;

my $verbose = 0;
$verbose = 1 if defined $ARGV[0] and $ARGV[0] eq "-v";
#my $config = Configuration::instance();
#$config->setOption("VISUALIZE_NET_NAMES",1);


my @testTopologies = (
    "topologytests/net1r2.zvf",
    #"topologytests/net2r1.zvf",
    "topologytests/triangle.zvf",
    "topologytests/hyperedge_net1r1.zvf",
    "topologytests/hyperedge_net1r3.zvf",
    "topologytests/star2_4.zvf",
#    "topologytests/empty.zvf",
    "circle05.zvf",
    "row5_orig.zvf",
    "internet2_new.zvf"
    );

sub prepareTopology {#{{{
    my $topologyFileName = shift;
    my $topology = new Topology(new TopologyFile($topologyFileName));
    open(FILE,"<$topologyFileName");
    my @lines = <FILE>;
    close(FILE);
    my @testArray = grep(/^[a-zA-Z0-9_ \t]/,@lines);
    map(chomp,@testArray);
    push(@testArray,"0") if $#testArray == -1;
    
    return ($topology,@testArray);
}#}}}

sub testGetNets {#{{{
    my ($topology,@testArray) = ();

    foreach my $topologyFileName (@testTopologies) {
        ($topology,@testArray) = prepareTopology($topologyFileName);
        my @compareNets = sort split(",",shift @testArray);
        my @resultNets = @{$topology->getNets()};

        #print "result is: [@resultNets]\nshould be: [@compareNets]\n";

        is_deeply(\@resultNets,\@compareNets,"getNets with file: $topologyFileName");
    }
    
}#}}}

sub testGetRouters {#{{{

    foreach my $topologyFileName (@testTopologies) {
        my ($topology,@testArray) = prepareTopology($topologyFileName);
        my %routers = %{$topology->getRouters()};
        my %compareRouters = ();
        foreach my $line (@testArray) {
            next unless $line =~ /^r[0-9]+/;
            my ($r,$n) = split(" ",$line);
            $compareRouters{$r}=$n;
        }

        #foreach(keys %compareRouters){print "result is: $_ => $routers{$_}\nshould be: $_ => $compareRouters{$_}\n\n";}


        is_deeply(\%routers,\%compareRouters,"getRouters with file: $topologyFileName");
    }
}#}}}


sub testGetPath {#{{{
    foreach my $topologyFileName (@testTopologies) {
        my ($topology,@testArray) = prepareTopology($topologyFileName);
        my $path = $topology->getPath();
        print "result is: $path\n" if $verbose;
        print "should be: $topologyFileName\n" if $verbose;
        is($path,$topologyFileName,"getPath with file: $topologyFileName");
    }
}#}}}

sub getGraph {#{{{
}#}}}

sub testGetRoutersInNet {#{{{
    my ($topology,@testArray) = prepareTopology("internet2_new.zvf");
    my @compareRoutersNet1 = ("r1","r2");
    my @compareRoutersNet11 = ("r10","r9");
    my @routersNet1 = @{$topology->getRoutersInNet("net1")};
    my @routersNet11 = @{$topology->getRoutersInNet("net11")};
    print "net1:  @routersNet1\n" if $verbose;
    print "net11: @routersNet11\n" if $verbose;

    is_deeply(\@routersNet1,\@compareRoutersNet1,"getRouters (net1) with file: internet2_new.zvf");
    is_deeply(\@routersNet11,\@compareRoutersNet11,"getRouters (net11) with file: internet2_new.zvf");
}#}}}

sub testToZVF {#{{{
    foreach my $topologyFileName (@testTopologies) {
        my ($topology,@testArray) = prepareTopology($topologyFileName);
        my $outputFile = $topology->toZVF();
        my $compareTopology = new Topology($outputFile);
        is_deeply($topology->toZVF(),$compareTopology->toZVF(),"toZVF with file $topologyFileName");
    }
}#}}}


sub testCheckZVFSyntax {#{{{

    my %syntaxErrorTopologies = (
        "topologytests/syntaxerror1.zvf" => "Error in Line 1: line must end with net (and must contain at least one net)\n",
        "topologytests/syntaxerror2.zvf" => "Error in Line 1: net name not allowed: net\n",
        "topologytests/syntaxerror3.zvf" => "Error in Line 1: not allowed char\nnet1,net2,nwt3,net4\n\n",
        "topologytests/syntaxerror4.zvf" => "Error in Line 1: net name not allowed:\n",
        "topologytests/syntaxerror5.zvf" => "Error in Line 1: net name not allowed: netnet\n",
        "topologytests/syntaxerror6.zvf" => "Error in Line 1: net is defined twice: net\n"
    );


    my $topology = new Topology(new File("test.txt"));
    
    foreach my $topologyFileName (sort keys %syntaxErrorTopologies) {
        $topology->{TOPOLOGYFILE} = new File($topologyFileName);
        print "\n\t";
        is($topology->_checkZVFSyntax(),0,"checkZVFSyntax with file $topologyFileName (the line above must contain an error message)");
    }
}#}}}


testGetNets();
print "\n" if $verbose;
testGetPath();
print "\n" if $verbose;
testGetRouters();
print "\n" if $verbose;
testGetRoutersInNet();
print "\n" if $verbose;
testToZVF();
print "\n" if $verbose;
testCheckZVFSyntax();
