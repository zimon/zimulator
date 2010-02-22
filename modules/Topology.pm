# Package: Topology
#
# Provides graph functions like <getDiameter> or <ToZVF>
package Topology;

use strict;
use warnings;
use Graph::Undirected;
use GraphViz;
use lib ".";
use File;
use TopologyGenerationFunctions;
use Configuration;


##
# VARIABLES: Member variables
# topologyFile - file object of topology file
# graph - Graph::Undirected object representing topology
# properties - property hash
# netnames - hash with netnames. (stringwithallrouternames => netname)

##
# Constructor
#
# PARAMETERS:
# $topologyFile - file object of topology file
# $g - graph representing topology (optional)
sub new {#{{{
    my $object = shift;
    my $topologyFile = shift;
    my $g = shift;
    my @args = @_;

    # if a new topology should be created type is given instead of file.
    # so topologyFile is the type. g and args are the arguments
    return _generateNewTopology($topologyFile,$g,@args) unless ref $topologyFile;
    my $reference = {};
    bless($reference,$object);
    return 0 unless $reference->_initTopology($topologyFile,$g);
    return($reference);
}#}}}


##
# Returns reference to a list of nets
sub getNets {#{{{
    my $object = shift;
    my $zvf = $object->toZVF();
    my @nets = split(",",$zvf->getLine(0));
    return \@nets;
}#}}}

##
# Returns a reference to a hash with all routers (router => netstring)
sub getRouters {#{{{
    my $object = shift;
    my $zvf = $object->toZVF();
    my @lines = $zvf->getLineArray();
    my %routers;
    foreach my $line (@lines) {
        next unless $line =~ /^r/;
        my ($router,$nets) = split(" ",$line);
        $routers{$router} = $nets;
    }
    return \%routers;
}#}}}


##
# Returns all routers connected to a given net.
# 
# PARAMETERS:
# $netName - name of net to get routers connected to
# 
# RETURNS:
# List of routers connected to the given net
sub getRoutersInNet {#{{{
    my $object = shift;
    my $netName = shift;
    my $topologyFile = $object->{TOPOLOGYFILE};

    my @routers = $topologyFile->getLinesGrep($netName."\\b");
    shift @routers;
    foreach my $r (@routers) {
        $r =~ s/^(r[0-9]+).*/$1/;
    }
    @routers = sort @routers;
    return \@routers;
}#}}}


##
# Returns the Path to the topology file
sub getPath {#{{{
    my $object = shift;
    my $zvf = $object->{TOPOLOGYFILE};
    return $zvf->getPath();
}#}}}

##
# Returns the topology name without suffix
sub getName {#{{{
    my $object = shift;
    my $zvf = $object->{TOPOLOGYFILE};
    return $zvf->getName();
}#}}}

##
# Sets a new graph
sub setGraph {#{{{
    my $object = shift;
    my $g = shift;
    $object->{GRAPH} = $g;
}#}}}

##
# Returns the graph
sub getGraph {#{{{
    my $object = shift;
    return $object->{GRAPH};
}#}}}


##
# Returns topology file object created from actual graph
sub toZVF{#{{{
    my $object = shift;
    my $g = $object->{GRAPH};
    my $config = Configuration::instance();
    my $topologyFile = $object->{TOPOLOGYFILE};
    my %netNames = %{$object->{NETNAMES}};
    #TODO: hier gibts irgendwie probleme. auf jeden fall gut kommentieren
# beim testen gibt es probleme bei der generierung der properties (bei cc division durch 0). nur wenn das folgende if vorhanden ist läuft es durch. dann gibt es jedoch probleme beim generieren von random-topologien, weil diese dann auch hier zurück gegeben werden, obwohl sie es nicht sollten. dadurch wird die topologyFile nicht geschrieben (bzw bleib leer).
# dies ist wichtig, wenn nur der name gebraucht wird. (das geht auch anders, sekunde)
#    if($topologyFile->getLength < 2){
#        return $topologyFile 
#    }
    my $output = "";
    my @nets = $g->edges();
    my %routers;
    my $index = 1;
    foreach my $net(sort @nets) {
        my @router = @{$net};
        #print "router in toZVF: [@router]\n";
        my $netKey = join("",sort @router);
        my $netName = $netNames{$netKey};
        if(not defined $netName){
            if($g->has_edge_attribute(@router, "name")){
                $netName = $g->get_edge_attribute(@router,"name");
            } else {
                print STDERR "netname not defined trying to get it another way\n";
                $netName = "net$index";
            }
            $netNames{$netKey} = $netName;
        }
        $output .= "$netName,";
        foreach my $r(@router) {
            push(@{$routers{$r}},$netName);
        }
        $index++;
    }
    chop $output;
    $output .= "\n\n";
    foreach my $r(sort keys %routers){
        my @n = @{$routers{$r}};
        $output .= $r." ";
        foreach(@n){
            $output .= $_.",";
        }
        chop $output;
        $output .= "\n";
    }
    $object->{NETNAMES} = \%netNames;
    my $properties = $object->getPropertyText();
    $topologyFile->clearFile();
    $topologyFile->addCommentLine($properties);
    $topologyFile->addLine($output);
    $topologyFile->filterFile();
    $object->_beautifyZVF();
    $object->_writeGraphImage($topologyFile->getDirectory().$topologyFile->getName().".png") if $config->getOption("CREATEGRAPHIMAGE");

    return $topologyFile;
}#}}}

##
# Returns property hash
sub getGraphProperties {#{{{
    my $object = shift;
    $object->_createGraphProperties() if not defined $object->{PROPERTIES};
    return %{$object->{PROPERTIES}};
}#}}}

##
# Creates VNUML XML file from Graph (with 
# 
# RETURNS:
# File object with xml content for VNUML
# TODO: call toZVF first instead of just take the stored file
sub toXML {#{{{
    my $object = shift;
    my $topologyFile = $object->{TOPOLOGYFILE};
    my $config = Configuration::instance();
    my $outfile = File->new($topologyFile->getDirectory().$topologyFile->getName().".xml");
    $outfile->clearFile();
    print "Creating ".$outfile->getFileName()."\n" if $config->getOption("VERBOSE");


# Defining variables (wird bald ausgelagert)#{{{
    my $global="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <!DOCTYPE vnuml SYSTEM \"".$config->getOption("DTDPATH")."\">

    <vnuml>
      <global>
        <version>1.8</version>
        <simulation_name>".$topologyFile->getName()."</simulation_name>
        <ssh_version>2</ssh_version>
        <ssh_key>".$config->getOption("SSH_KEY")."</ssh_key>
        <automac/>
        <vm_mgmt type=\"private\" network=\"".$config->getOption("MANAGEMENT_NET")."\" mask=\"".$config->getOption("MANAGEMENT_NETMASK")."\" offset=\"".$config->getOption("MANAGEMENT_NET_OFFSET")."\" >
           <host_mapping/>
        </vm_mgmt>
        <vm_defaults ".$config->getOption("VM_DEFAULTS").">
           <filesystem type=\"cow\">".$config->getOption("FILESYSTEM")."</filesystem>
           <kernel>".$config->getOption("KERNEL")."</kernel>
        </vm_defaults>
      </global>\n";  

# the prefix 
# <net name="nameofnet"
# is added later
    my $net=" mode=\"".$config->getOption("NET_MODE")."\"/>";

# the start tag 
# <vm name="routername">
# and the nets are added later
    my $router="\n<forwarding type=\"ipv4\" />

        <filetree root=\"/etc/quagga\" seq=\"start\">conf</filetree>
          <exec seq=\"start\" type=\"verbatim\">sysctl -w net.ipv4.conf.all.rp_filter=0</exec>
          <exec seq=\"start\" type=\"verbatim\">hostname</exec>
          <exec seq=\"start\" type=\"verbatim\">".$config->getOption("ZEBRA_PATH")."/zebra -f /etc/quagga/zebra.conf -d</exec>
          <exec seq=\"rip\" type=\"verbatim\">".$config->getOption("RIPD_PATH")."/ripd -f /etc/quagga/ripd.conf -d</exec>
          <exec seq=\"ospf\" type=\"verbatim\">".$config->getOption("OSPF_PATH")."/ospfd -f /etc/quagga/ospfd.conf -d -P 2604</exec>
          <exec seq=\"stop\" type=\"verbatim\">hostname</exec>
          <exec seq=\"stop\" type=\"verbatim\">killall zebra</exec>
          <exec seq=\"stop\" type=\"verbatim\">killall ripd</exec>
          <exec seq=\"stop\" type=\"verbatim\">killall ospfd</exec>

          <exec seq=\"rpfilter\" type= \"verbatim\">
          for f in /proc/sys/net/ipv4/conf/*/rp_filter; do echo 0 > \$f; done
          </exec>
        </vm>\n\n";
#}}}

# --------- start --------------

    # read the file and store the lines to the array @lines
    return 0 unless $object->_checkZVFSyntax();
    return 0 unless $topologyFile->hasLines();
    my @zvfLines=$topologyFile->getLineArray();
    my $output = "";

    # determine the line where the nets are defined (netline)
    my $firstNetLine = shift @zvfLines; #shift @lines;

    # create an array of nets from netline
    my @nets = split(",",$firstNetLine);

    if($#nets>254){
        print "\nToo many nets! max is 254\n\n";
        exit 1;
    }

    if($#zvfLines > 254) {
        print "\nToo many routers! Max is 254\n\n";
        exit 1;
    }

    $output .= $global."\n\n";

    foreach my $netName (@nets)
    {
        chomp $netName;
        $output .= "<net name=\"$netName\"$net\n"; # create xml net definitions
    }
    $output .= "\n\n";

    # for each routerline (line where a router is defined)
    foreach my $line (@zvfLines)
    {
        next if(not($line =~ /^r[0-9]+\s.*/));

        # create variables routerName and netLine with (comma separated) nets as second element
        my ($routerName, $netLine) = split(/\s+/,$line);

        #begin xml router definition
        $output .= "<vm name=\"$routerName\">\n";

        # all nets of actual router are stored in array @netlist
        my @netlist = split(",",$netLine);
        my $id=1;
        
        # for each net of the actual router do:
        foreach my $actualNet (@netlist)
        {
            $output .= "  <if id=\"$id\" net=\"$actualNet\">\n";
            # get number of net and router
            my ($netNumber) = $actualNet =~ m/net([0-9]+)/;
            my ($routerNumber) = $routerName =~ m/r([0-9]+)/;
            $output .= "    <ipv4 mask=\"255.255.255.0\">10.0.$netNumber.$routerNumber</ipv4>\n</if>\n";
            $id++;
        }
        $output .= $router."\n";
    }
    $output .= "\n</vnuml>\n";
    $outfile->addLine($output);

    return $outfile;
}#}}}


################# private functions #####################


##
# Writes the graph to png file
# 
# PARAMETERS:
# $file - name of file to store image
sub _writeGraphImage {#{{{
    my $object = shift;
    my $file = shift;
    my $graph = $object->{GRAPH};
    my @edges = $graph->edges();
    my @vertices = $graph->vertices();
    my $config = Configuration::instance();
    my $verbose = $config->getOption("VERBOSE");
    my %netNames = %{$object->{NETNAMES}};

    print "writing image: $file\n" if $verbose;

    # generating GraphViz object
    my $gv = GraphViz->new(directed => 0);
    foreach(@vertices){ $gv->add_node($_); }
    foreach(@edges){
        my @edge = @{$_};
        my $name = $netNames{join("",sort @edge)};
        if($config->getOption("VISUALIZE_NET_NAMES")){
            $gv->add_edge($edge[0] => $edge[1], label => $name) 
        } else {
            $gv->add_edge($edge[0] => $edge[1]) 
        }
    }

    # writing png
    my $png = $gv->as_png();
    open(FILE,">$file");# || return 0;
    print FILE $png;
    close(FILE);

    # free memory
    $png = undef;
    $gv = undef;

    return 1;
}#}}}

##
# Sets member variables. 
# - If topology file is empty a new graph is generated.
# - If a graph is given it is taken instead of the topology file (file will be overwritten)
# - Else a graph is created from topology file
sub _initTopology {#{{{
    my $object = shift;
    my $topologyFile = shift;
    my $graph = shift;
    my $config = Configuration::instance();

    $topologyFile->filterFile();
    $object->{TOPOLOGYFILE} = $topologyFile;
    my %netNames = ();
    
    if(defined $graph){
        $object->{GRAPH} = $graph;
        $object->_createGraphProperties();
    } elsif($topologyFile->getLength() < 1){
        $object->{GRAPH} = new Graph();
    }else {
        print "\nSyntax Error in ZVF!\n" and return 0 unless $object->_checkZVFSyntax(); #TODO: nicht mehr nötig
        my @lines = $topologyFile->getLineArray();
        my $g = Graph::Undirected->new(hyperedged => 1);
        my $netline = shift @lines;
#        print "netline: $netline\n";
        #chomp $netline;
        my @nets = split(",",$netline);
        foreach my $net (@nets){
            my @routers = ();
            foreach my $line (@lines){
                #chomp $line;
                #next if $line =~ /^$/;
                if($line =~ /\b$net\b/){
                    (my $r = $line) =~ s/(.*) .*/$1/;
                    push(@routers,$r);
                }
            }
#            print "new edge: [@routers]\n";
            $g->add_edge(@routers);
            my $netKey = join("", sort @routers);
            #print "init: netkey=$netKey => $net\n";
            $netNames{$netKey} = $net;
            #$g->set_edge_attribute(@routers, "name", $net) if $config->getOption("VISUALIZE_NET_NAMES");
        }
        #print "number of nets: ".$g->edges()."\n";
        $object->{GRAPH} = $g;
        $object->_createGraphProperties();
    }
    $object->{NETNAMES} = \%netNames;
}#}}}


##
# Calls a generator function and returns topology
# 
# TODO: call _initTopology instead of new. make this a member function
# 
# PARAMETERS:
# $type - type of topology to be created
# @args - list of arguments for the topology creation process
sub _generateNewTopology {#{{{
    my $type = shift;
    my @args = @_;
    my $config = Configuration::instance();
    my $outputFileName = $config->getOption("OUTPUT_FILENAME");
    $outputFileName = "temp.txt" unless $outputFileName;
    my $outputFile = new File($outputFileName);
    my $verbose = $config->getOption("VERBOSE");
    print "generating new $type topology with args: [@args]\n" if $verbose;

    my $topology = 0;
    $outputFile->clearFile();
    
    if($type eq "random"){ # create random topology #{{{
        $outputFile->setFileName("random$args[0]_$args[1].zvf") if $outputFile->getFileName() eq "temp.txt";
        print "generating random topology with $args[0] vertices and $args[1] edges.\n";# Writing to: ".($outputFile->getFileName() eq "-")?"-":$outputFile->getFileName()."\n";# if $verbose;
        $topology = TopologyGenerationFunctions::randomGraph($outputFile,0,@args);
#}}}
    }elsif($type eq "relativerandom"){ # create relative random topology #{{{
        $outputFile->setFileName( "relativerandom$args[0]_$args[1].zvf") if $outputFile->getFileName() eq "temp.txt";
        print "generating random topology with $args[0] vertices and a clustering coefficient of $args[1]. Writing to: ".($outputFile->getFileName() eq "-")?"-":$outputFile->getFileName()."\n" if $verbose;
        $topology = TopologyGenerationFunctions::randomGraph($outputFile,1,@args);
#}}}
    }elsif($type eq "row"){ # create row topology #{{{
        $outputFile->setFileName("row$args[0].zvf") if $outputFile->getFileName() eq "temp.txt";
        print "generating row topology with $args[0] vertices. Writing to: ".($outputFile->getFileName() eq "-")?"-":$outputFile->getFileName()."\n" if $verbose;
        $topology = TopologyGenerationFunctions::row($outputFile,@args);
#}}}
    }elsif($type eq "circle"){ # create circle topology #{{{
        $outputFile->setFileName("circle$args[0].zvf") if $outputFile->getFileName() eq "temp.txt";
        print "generating circle topology with $args[0] vertices. Writing to: ".($outputFile->getFileName() eq "-")?"-":$outputFile->getFileName()."\n" if $verbose;
        $topology = TopologyGenerationFunctions::circle($outputFile,@args);
#}}}
    }elsif($type eq "star2"){ # create star2 topology #{{{
        $outputFile->setFileName("star2_$args[0].zvf") if $outputFile->getFileName() eq "temp.txt";
        print "generating star2 topology with $args[0] vertices. Writing to: ".($outputFile->getFileName() eq "-")?"-":$outputFile->getFileName()."\n" if $verbose;
        $topology = TopologyGenerationFunctions::star2($outputFile,@args);
#}}}
    }elsif($type eq "connectedstar2"){ # create connectedstar2 topology #{{{
        $outputFile->setFileName("connectedstar2_$args[0].zvf") if $outputFile->getFileName() eq "temp.txt";
        print "generating connected star2 topology with $args[0] vertices. Writing to: ".($outputFile->getFileName() eq "-")?"-":$outputFile->getFileName()."\n" if $verbose;
        $topology = TopologyGenerationFunctions::connectedstar2($outputFile,@args);
#}}}
    }elsif($type eq "star"){ # create star topology #{{{
        $outputFile->setFileName("star$args[0]_$args[1].zvf") if $outputFile->getFileName() eq "temp.txt";
        print "generating star topology with a diameter of $args[0] and $args[1] rows. Writing to: ".($outputFile->getFileName() eq "-")?"-":$outputFile->getFileName()."\n" if $verbose;
        $topology = TopologyGenerationFunctions::starn($outputFile,@args);
#}}}
    }elsif($type eq "square"){ # create square topology #{{{
        $outputFile->setFileName("square$args[0].zvf") if $outputFile->getFileName() eq "temp.txt";
        print "generating aquare topology with size $args[0]. Writing to: ".($outputFile->getFileName() eq "-")?"-":$outputFile->getFileName()."\n" if $verbose;
        $topology = TopologyGenerationFunctions::square($outputFile,@args);
        #}}}
    }elsif($type eq "crown"){ # create crown topology #{{{
        $outputFile->setFileName("crown$args[0].zvf") if $outputFile->getFileName() eq "temp.txt";
        print "generating crown $args[0] topology. Writing to: ".($outputFile->getFileName() eq "-")?"-":$outputFile->getFileName()."\n" if $verbose;
        $topology = TopologyGenerationFunctions::crown($outputFile,@args);
#}}}
    }elsif($type eq "circlex_rowy"){ # create circle x row y topology #{{{
        $outputFile->setFileName("circle$args[0]_row$args[1].zvf") if $outputFile->getFileName() eq "temp.txt";
        print "generating topology consisting of a circle with $args[0] vertices connected to a row with $args[1] vertices. Writing to: ".($outputFile->getFileName() eq "-")?"-":$outputFile->getFileName()."\n" if $verbose;
        $topology = TopologyGenerationFunctions::circlex_rowy($outputFile,@args);
#}}}
    }elsif($type eq "squarerow"){ # create squarerow topology #{{{
        $outputFile->setFileName("squarerow$args[0].zvf") if $outputFile->getFileName() eq "temp.txt";
        print "generating squarerow topology with $args[0] squares. Writing to: ".($outputFile->getFileName() eq "-")?"-":$outputFile->getFileName()."\n" if $verbose;
        $topology = TopologyGenerationFunctions::squarerow($outputFile,@args);
#}}}
    }elsif($type eq "mesh"){ # create mesh topology #{{{
        $outputFile->setFileName("mesh$args[0].zvf") if $outputFile->getFileName() eq "temp.txt";
        print "generating full mesh topology with $args[0] vertices. Writing to: ".($outputFile->getFileName() eq "-")?"-":$outputFile->getFileName()."\n" if $verbose;
        $topology = TopologyGenerationFunctions::mesh($outputFile,@args);
        #$topology = new Topology($outputFile,$g);
        #}}}
    }else{ # else die with error message #{{{
        die "Cannot create topology $type!\n";
    }#}}}
    
    die "An Error occured, exiting\n" unless $topology;

    return $topology;
}#}}}

##
# Reformats a topology file.
sub _beautifyZVF{#{{{
    my $object = shift;
    my $topologyFile = $object->{TOPOLOGYFILE};
    my @lines = $topologyFile->getLineArray();
    my $netLine = shift @lines;

    # TODO: bei routern und Netzen 0 vorranstellen, wenn die zahl einstellig ist
    $netLine = join(",",sort split(",",$netLine));

    my @output;
    push(@output,$netLine."\n\n");
    foreach my $routerLine (sort @lines){
        next if $routerLine =~ /^$/;
        my ($r,$nets) = split(" ",$routerLine);
        $nets = join(",",sort split(",",$nets)) if $nets =~ /,/;
        $routerLine = $r." ".$nets;
        push(@output,$routerLine);
    }

    $topologyFile->setLineArray(@output);
    $object->{TOPOLOGYFILE} = $topologyFile;
    # free memory
    $netLine = undef;
    @lines = ();
}#}}}

##
# Checks topology file for syntax errors
#
# RETURNS:
# 1 if successfull. Printing error message and returning 0 when detecting a syntax error
sub _checkZVFSyntax {#{{{
    my $object = shift;
    my $topologyFile = $object->{TOPOLOGYFILE};

    return 0 unless $topologyFile->hasLines();
    my $netLine = $topologyFile->getNextLine();
    $netLine =~ s/\s*//g; # remove whitespaces
    chop $netLine if $netLine =~ /,$/; # remove trailing comma

    print "Error in Line 1: line must end with net\n" and return 0 unless($netLine =~ /net[0-9]+$/);
    print "Error in Line 1: not allowed char\n$netLine\n\n" and return 0 if $netLine =~ /[^(net)0-9,]/;
    my @nets = split(",",$netLine);
    my %nethash;
    foreach my $net (@nets){
        print "Error in Line 1: net name not allowed: $net\n" and return 0 unless $net =~ /^net[0-9]+$/ ;
        print "Error in Line 1: net is defined twice: $net\n" and return 0 if defined $nethash{$net};
        $nethash{$net} = 1;
    }

    return 0 unless $topologyFile->hasLines();

    my $lineNumber = 2;
    my %routers;
    #foreach my $line (@lines) {
    while($topologyFile->hasLines()){
        my $line = $topologyFile->getNextLine();
        my @words = split(/\s+/,$line);
        print "Error in Line $lineNumber: line must end with net (no space or comma)\n" and return 0 unless($line =~ /net[0-9]+$/);
        print "Error in Line $lineNumber: router name not allowed: $words[0]\n" and return 0 unless($words[0] =~ /^r[0-9]+$/);
        print "Error in Line $lineNumber: not allowed char in net netlist\n" and return 0 if $words[1] =~ /[^(net)0-9,]/;
        print "Error in Line $lineNumber: too many spaces\n" and return 0 if @words > 2;
        print "Error in Line $lineNumber: router is defined twice: $words[0]\n" and return 0 if defined $routers{$words[0]};
        $routers{$words[0]} = 1;
        $lineNumber++;
    }

    $topologyFile->resetLinePointer();
    return 1;

}#}}}

##
# Returns the comments text for a topology file as a string
sub getPropertyText {#{{{
    my $object = shift;
    my $g = $object->{GRAPH};
    my $scenarioName = $object->{TOPOLOGYFILE}->getName();
    my %graphProperties = $object->getGraphProperties();

    my $properties = "# $scenarioName\n#\n" if $scenarioName ne "-";
    $properties .= "# number of vertices: \t\t$graphProperties{VERTICES}\n";
    $properties .= "# number of edges: \t\t$graphProperties{EDGES}\n";
    $properties .= "# diameter: \t\t\t$graphProperties{DIAMETER}\n";
    $properties .= "# number of cycles: \t\t$graphProperties{CIRLES}\n";
    $properties .= "# clustering coefficient: \t$graphProperties{CC}\n";
    my @leaves = @{$graphProperties{LEAVES}};
    $properties .= "# leaves: \t\t\t".join(" ",@leaves)."\n";
    my @articulations = @{$graphProperties{ARTICULATIONS}};
    $properties .= "# articulations: \t\t".join(" ",@articulations)."\n\n";
    return $properties;
}#}}}


##
# Returns the clustering coefficient of the graph with 2e/v*(v-1)
sub _getClusteringCoefficient {#{{{
    my $object = shift;
    my $g = $object->{GRAPH};
    my $e=$g->edges();
    my $v=$g->vertices();
    #my $cc=($e+1)-($#vertices+1)+1;
    my $cc = ($e+1)/((($v+1)*$v)/2);
    return $cc;
}#}}}


##
# Returns diameter of Graph with dijsktra shortest path algorithm
sub _getDiameter {#{{{
    my $object = shift;
    my $g = $object->{GRAPH};
    my @vertices = $g->vertices();
    my $longest = 0;
    for (my $i = 0; $i <= $#vertices; $i++) {
        for (my $j = $i; $j <= $#vertices; $j++) {
            my @sp = $g->SP_Dijkstra($vertices[$i],$vertices[$j]);
            $longest = $#sp if $#sp > $longest;
        }
        
    }
    return $longest;
}#}}}

##
# Calculates all properties of a graph. The following properties are calculated
# 
# - number of vertices
# - number of edges
# - diameter
# - number of cycles
# - clustering coefficient
# - leaves
# - articulations
#
sub _createGraphProperties {#{{{
    my $object = shift;
    my $g = $object->{GRAPH};
    my $scenarioName = shift;
    my $e = $g->edges();
    my $v = $g->vertices();

    my %properties;
    $properties{VERTICES} = $v;
    $properties{EDGES} = $e;
    $properties{DIAMETER} = $object->_getDiameter();
    $properties{CIRLES} = $e-$v+1;
    $properties{CC} = $object->_getClusteringCoefficient();
    my @leaves = $object->_getLeaves();
    $properties{LEAVES} = \@leaves;
# TODO: don't change original graph. better make own articulation function that creates a new converted graph
    #$object->_convertToRegularEdges();
    $g = $object->{GRAPH};
# TODO: don't call this with large topologies
    my @articulations = $g->articulation_points();
    $properties{ARTICULATIONS} = \@articulations;

    $object->{PROPERTIES} = \%properties;

}#}}}

## 
# Returns a list of leaves of the graph
sub _getLeaves {#{{{
    my $object = shift;
    my $g = $object->{GRAPH};
    my @edges = $g->edges();
    my %routers;
    foreach my $edge (@edges) {
        my @rs = @{$edge};
        foreach my $r (@rs) {
            $routers{$r}++;
        }
    }
    my @result = ();
    foreach my $r (keys %routers) {
        push(@result,$r) if $routers{$r} == 1;
    }
    
    return @result;
}#}}}

##
# Substitutes each hyperedge of the graph with full mesh of all connected vertices
#
# TODO:
# Return a new graph with above substitution.
sub _convertToRegularEdges {#{{{
    my $object = shift;
    my $g = $object->{GRAPH};
    my @edges = $g->edges();
    foreach my $edge (@edges) {
        my @r = @{$edge};
        if($#r > 1){
            $g->delete_edge(@r);
            foreach my $first(@r){
                foreach my $second(@r){
                    $g->add_edge($first,$second) if $first ne $second;
                }
            }
        }
    }
    $object->{GRAPH} = $g;
}#}}}

1;


# for a better use with vim. All the markings: #{{{ and #}}} belong to it
# vim: foldmethod=marker    
