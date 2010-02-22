# Package: TopologyGenerationFunctions
#
# Provides functions to generate symmetric or random topologys
# 
# This is a no class. All functions are static.
#
# Each (public) function gets a file object of an output file and some arguments. The generated Topology object is returned.
package TopologyGenerationFunctions;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();


use strict;
use warnings;
use Graph;
use Graph::Undirected;
use lib ".";
#use Topology;
use Configuration;

##
# Returns the first line for the zvf file with all net names.
# 
# PARAMETERS:
# $num - number of nets
#
# RETURNS:
# the net line for a zvf file
sub _printNets {#{{{
    my $numberOfNets = shift;
    my $output = "";
    for (my $i = 0; $i < $numberOfNets; $i++) {
        $output .=  "net".($i+1).",";
    }
    chop $output;
    $output .= "\n\n";
    return $output;
}#}}}

## 
# Generates a random Graph
# 
# PARAMETERS:
# $outputFile - file object of output file
# $relative - 1 if the number of edges is given as relation
# $vertices - number of vertices the random graph should consist of
# $edges - number of edges 
#
# RETURNS:
# Topology object
sub randomGraph {#{{{
    my $outputFile = shift;
    my $relative = shift;
    my $vertices = shift;
    my $edges = shift;
    my $config = Configuration::instance();

    die "A graph must contain at least two vertices and one edge" if $vertices < 2 or ($edges <= 1 and not $relative);
    die "A graph must contain at least two vertices and the clustering coefficient must be between 0 and 1" if $vertices < 2 or (($edges > 1 or $edges < 0) and $relative);

    my $postfix = "";
    $postfix = "_fill" if $relative;

    my $g_raw = Graph::Undirected->random_graph(vertices => $vertices, "edges".$postfix => $edges);
    my $g = Graph::Undirected->new();
    my $index = 0;
    foreach($g_raw->edges){
        my @edges = @{$_};
        $g->add_edge("r".($edges[0]+1), "r".($edges[1]+1));
        $g->set_edge_attribute("r".($edges[0]+1), "r".($edges[1]+1), "name", "net$index") if $config->getOption("VISUALIZE_NET_NAMES");
        $index++;
    }

    my $cg = $g->connected_graph();
    my $i = 1;

    # while generated graph is not connected create another one
    while($cg =~ /,/){ 
        print "$i\n" if $config->getOption("VERBOSE");
        print "Graph not connected ($cg). Generating new graph.\n" if $config->getOption("VERBOSE");
        $g_raw = Graph::Undirected->random_graph(vertices => $vertices, "edges".$postfix => $edges);
        $g = Graph::Undirected->new();
        $index = 0;
        foreach($g_raw->edges){
            my @edges = @{$_};
            $g->add_edge("r".($edges[0]+1), "r".($edges[1]+1));
            $g->set_edge_attribute("r".($edges[0]+1), "r".($edges[1]+1), "name", "net$index") if $config->getOption("VISUALIZE_NET_NAMES");
            $index++;
        }
        $cg = $g->connected_graph();
        $i++;
    }
    print "... done! (".$g->vertices()." vertices and ".$g->edges()." edges)\n" if $config->getOption("VERBOSE");

    return new Topology($outputFile,$g);
}#}}}


##
# Generates a row topology
#
# PARAMETERS:
# $outputFile - file object of output file
# $size - number of vertices the row should consist of
# 
# RETURNS:
# Topology object
sub row {#{{{
    my $outputFile = shift;
    my $size=shift;
    die "The mimimum size of a row must be 3!\n" if $size < 3;
    my $output = _printNets($size-1);
    $output .= "r1 net1\n"; # create first vertex

    for my $i(2..$size-1) { # create inner vertices
        $output .= "r$i ";
        $output .= "net".($i-1).",net$i\n";
    }
    $output .= "r$size net".($size-1)."\n"; # create last vertex

    $outputFile->clearFile();
    $outputFile->addLine($output);
    
    return new Topology($outputFile);
}#}}}

##
# Generates a circle topology
#
# PARAMETERS:
# $outputFile - file object of output file
# $size - number of vertices the circle should consist of
# 
# RETURNS:
# Topology object
sub circle {#{{{
    my $outputFile = shift;
    my $size=shift;
    die "The mimimum size of a cirlce must be 3!\n" if $size < 3;
    my $output = _printNets($size);
    $output .= "r1 net1,net$size\n"; # create first vertex

    for my $i(2..$size) { # create other vertices
        $output .= "r$i ";
        $output .= "net".($i-1).",net$i\n";
    }
    $outputFile->clearFile();
    $outputFile->addLine($output);
    
    return new Topology($outputFile);
}#}}}

##
# Generates a star2 topology
#
# PARAMETERS:
# $outputFile - file object of output file
# $size - number of vertices the star should consist of
# 
# RETURNS:
# Topology object
sub star2 {#{{{
    my $outputFile = shift;
    my $size=shift;
    die "The mimimum size of a star2 must be 4!\n" if $size < 4;
    my $output = _printNets($size-1);
    my $lastline = "r$size "; # begin inner vertex
    for my $i(1..$size-1) {
        $output .= "r$i net$i\n"; # create outer vertices
        $lastline .= "net$i,"; # add net to inner vertex
    }
    chop $lastline;
    $output .= $lastline."\n"; # add inner vertex

    $outputFile->clearFile();
    $outputFile->addLine($output);
    
    return new Topology($outputFile);
}#}}}

##
# Generates a connectedstar2 topology
#
# PARAMETERS:
# $outputFile - file object of output file
# $size - number of vertices the connected star should consist of
# 
# RETURNS:
# Topology object
sub connectedstar2 {#{{{
    my $outputFile = shift;
    my $size=shift;
    die "The mimimum size of a star2 must be 4!\n" if $size < 4;
    my $output = _printNets(2*($size-1));
    my $lastline = "r$size "; # begin inner vertex
    my $j = 0;
    my $lastnet = 2*($size-1);
    for my $i(1..$size-1) {
        $output .= "r$i net$i,net".($size+$j).",net$lastnet\n" if $j == 0; # create outer vertices
        $output .= "r$i net$i,net".($size+$j-1).",net".($size+$j)."\n" if $j != 0; # create outer vertices
        $lastline .= "net$i,"; # add net to inner vertex
        $j++
    }
    chop $lastline;
    $output .= $lastline."\n"; # add inner vertex

    $outputFile->clearFile();
    $outputFile->addLine($output);
    
    return new Topology($outputFile);
}#}}}

##
# Generates a starn topology
#
# PARAMETERS:
# $outputFile - file object of output file
# $size - diameter of the star
# $rows - number of rows the star should consist of
# 
# RETURNS:
# Topology object
sub starn {#{{{
    my $outputFile = shift;
    my $size=shift;
    my $rows = shift;

    die "The mimimum size of a star must be 4!\n" if $size < 4;
    die "A star must consits of mimimum 3 rows!\n" if $rows < 3;
    my $routers = ($rows*($size/2))+1;
    my $rowSize = $size/2;
    my $output = _printNets($routers-1);
    my $lastline = "r$routers ";
    for my $i(1..$routers-1) {
        if(($i-1)%$rowSize != 0){
            $output .= "r$i net".($i-1).",net$i\n";
        } else {
            $output .= "r$i net$i\n";
        }
        $lastline .= "net$i," if($i%$rowSize == 0);
    }
    chop $lastline;
    $output .= $lastline."\n";

    $outputFile->clearFile();
    $outputFile->addLine($output);
    
    return new Topology($outputFile);
}#}}}

##
# Generates a circlex_rowy topology
#
# PARAMETERS:
# $outputFile - file object of output file
# $sizeCircle - number of vertices the circle should consist of
# $sizeRow - number of vertices the row should consist of
# 
# RETURNS:
# Topology object
sub circlex_rowy{#{{{
    my $outputFile = shift;
    my $sizeCircle  = shift;
    my $sizeRow = shift;

    die "A circle must have at least 3 vertices" if $sizeCircle < 3;
    die "A row must have at least 2 vertices" if $sizeRow < 2;
    my $output = _printNets($sizeCircle+$sizeRow);

    for my $i(1..$sizeCircle-1) {
        $output .= "r$i ";
        $output .= "net$i,net".($i+1)."\n";
    }

    $output .= "r$sizeCircle net1,net$sizeCircle,net".($sizeCircle+1)."\n";

    for my $i($sizeCircle+1..$sizeCircle+$sizeRow-1) {
        $output .= "r$i ";
        $output .= "net$i,net".($i+1)."\n";
    }
    $output .= "r".($sizeCircle+$sizeRow)." net".($sizeCircle+$sizeRow)."\n";

    $outputFile->clearFile();
    $outputFile->addLine($output);
    
    return new Topology($outputFile);
}#}}}

##
# Generates a squarerow topology
#
# PARAMETERS:
# $outputFile - file object of output file
# $numberOfSquares - number of squares the topology should have
# 
# RETURNS:
# Topology object
sub squarerow {#{{{
    my $outputFile = shift;
    my $numberOfSquares = shift;
    die "Eine Reihe von Quadraten muss mindestens die Größe 2 haben\n" if $numberOfSquares < 2;
    my $numberOfRouters = 2*($numberOfSquares+1);

    my $output = _printNets(3*$numberOfSquares+1);
    $output .= "r1 net1,net".($numberOfRouters)."\n";
    for my $i(2..$numberOfSquares){
        $output .= "r$i net".($i-1).",net$i,net".($numberOfRouters+$i-1)."\n";
    }
    $output .= "r".($numberOfSquares+1)." net$numberOfSquares,net".($numberOfSquares+1)."\n";
    $output .= "r".($numberOfSquares+2)." net".($numberOfSquares+1).",net".($numberOfSquares+2)."\n";
    my $temp = 0;
    for my $i($numberOfSquares+3..$numberOfRouters-1){
        $output .= "r$i net".($i-1).",net$i,net".(3*$numberOfSquares+1-$temp)."\n";
        $temp++;
    }
    $output .= "r$numberOfRouters net".($numberOfRouters-1).",net$numberOfRouters\n";

    $outputFile->clearFile();
    $outputFile->addLine($output);
    
    return new Topology($outputFile);
}#}}}

##
# Generates a square topology
#
# PARAMETERS:
# $outputFile - file object of output file
# $size - height and with of the sqare
# 
# RETURNS:
# Topology object
sub square {#{{{
    my $outputFile = shift;
    my $size = shift;
    die "The minimum size of a square must be 2!\n" if($size<2);
    my $numberNets = 2*($size*($size-1));

    my $output = _printNets($numberNets);
    
    my $v = 1;
    for (my $i = 1; $i <= $size; $i++) {
        for (my $j = 1; $j <= $size; $j++) {
            $output .= "r$v ";
            # nets to the top
            $output .= "net".(($i-1)*$size+($i-2)*($size-1)+($j-1))."," if($v-$size > 0);  

            # nets to the left
            $output .= "net".int((($i-1)*$size+($i-1)*($size-1))+$j-1)."," if($v-1 > ($i-1)*$size); 

            # nets to the right
            $output .= "net".int((($i-1)*$size+($i-1)*($size-1))+$j)."," if($v/$size < $i); 

            # nets to the bottom
            $output .= "net".(($i-1)*$size+$i*($size-1)+($j))."," if($v+$size <= $size*$size); 
            chop $output;

            $output .= "\n";
            $v++;
        }
        
    }

    $outputFile->clearFile();
    $outputFile->addLine($output);
    
    return new Topology($outputFile);
} #}}}

##
# Generates a crown topology
#
# PARAMETERS:
# $outputFile - file object of output file
# $size - number of vertices in the inner circle
# 
# RETURNS:
# Topology object
sub crown {#{{{
    my $outputFile = shift;
    my $size = shift;
    die "The minimum size of a crown must be 3!\n" if($size<3);
    my $output = _printNets(4*$size);
    my $v = 1;

    for (my $i = 1; $i <= $size*2; $i++) {                          # create outer circle
        $output .= "r$v ";
        $output .= "net".($v-1)."," if ($v != 1);
        $output .= "net$v,";
        $output .= "net".($size*2)."," if ($v == 1);
        $output .= "net".(int(($i+1)/2)+(2*$size))."," if($v%2==1); # create net to inner circle on each second vertex
        chop $output;

        $output .= "\n";
        $v++;
    }

    for (my $j = 0; $j < $size; $j++) {                             # create inner circle
        $output .= "r$v ";
        $output .= "net$v,";
        $output .= "net".($v+$size-1)."," if ($v != $size*2+1);
        $output .= "net".($v+$size).",";
        $output .= "net".($size*4)."," if ($v == $size*2+1);
        chop $output;

        $output .= "\n";
        $v++;
        
    }

    $outputFile->clearFile();
    $outputFile->addLine($output);
    
    return new Topology($outputFile);
}#}}}

##
# Generates a full mesh topology
#
# PARAMETERS:
# $outputFile - file object of output file
# $size - number of vertices the topology should consist of
# 
# RETURNS:
# Topology object
sub mesh {#{{{
    my $outputFile = shift;
    my $size = shift;
    die "Ein Full Mesh muss mindestens die Größe 3 haben\n" if($size<3);
    my $g = Graph::Undirected->new();
    
    my $net=1;
    for my $i(1..$size){
        for my $j($i+1..$size){
            $g->add_edge("r".$i,"r".$j);
            $g->set_edge_attribute("r".$i,"r".$j, "name", "net".$net);
            $net++;
        }
    }

    return new Topology($outputFile,$g);
}#}}}


1;



# for a better use with vim. All the markings: #{{{ and #}}} belong to it
# vim: foldmethod=marker    
