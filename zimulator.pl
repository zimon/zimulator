#!/usr/bin/perl

# Inormations about this file #{{{

# Script: zimulator.pl
#
#  VNUML routing simulation and measurement tool.
#
# Usage: zimulator.pl MODE [FILE] [-v] [-o output_file] [-c config_file] [OPTIONS] [FILE(S)]
#
#     zimulator.pl -s simulation_file                                                  - simulate
#
#     zimulator.pl -S [-T] [-F] [-o output_file] topology_file(s)                      - parse whole simulation
#
#     zimulator.pl -r topology_file [-T time] [-F time] [-o output_file] dump_files    - parse single run
#
#     zimulator.pl -a [-o output_file] result_file(s)                                  - print average time
#
#     zimulator.pl -P [-A] topology_file(s)                                            - generate plotfile
#
#     zimulator.pl -z topology_file(s)                                                 - analyze topology
#
#     zimulator.pl -x topology_file(s)                                                 - create VNUML xml file
#
#     zimulator.pl -g type [-o output_file] size(s)                                    - generate topology
#
#     zimulator.pl -C topology_file(s)                                                 - check topology file syntax
#
#     zimulator.pl -H [-o output_file] dump_file(s)                                    - print dump in human readable format
#
#     zimulator.pl -V                                                                  - print version
#
#     zimulator.pl -h                                                                  - print help\n 
#
#     zimulator.pl -hv                                                                 - to get a longer help message.\n
#
#     zimulator.pl --test                                                              - starts all software tests (for developers)\n
#
# More Informations:
# See Variable <$verboseUsageString>

# #}}}


# use clauses#{{{

use strict;
use warnings;

use Getopt::Std;

use lib "modules";
use Scenario;
use File;
use TopologyFile;
use DumpFile;
use ResultFile;
use ExecutionDescriptionFile;
use Parser;
use RIPParser;
use Simulator;
use Topology;
use Result;
use Configuration;

# uncomment next lines for debugging
$" = '] ['; # set field seperator for list to string conversion
use DebugMessages exit_on_warning => 1, fatal => 3, warnings => 3, level => 5;

#}}}


# VARIABLES: Usage strings
# $usagestring - Contains the usage message printed when no valid argument or option is given.
# $verboseUsageString - Contains extended usage message printed at option -hv
my $usageString = "\nzimulator.pl - vnuml routing simulation and measurement tool\n\n";#{{{
$usageString .= "Usage: zimulator.pl MODE [FILE] [-v] [-o output_file] [-c config_file] [OPTIONS] [FILE(S)]\n";
$usageString .= "    zimulator.pl -s simulation_file                                                  - simulate\n";
$usageString .= "    zimulator.pl -S [-T] [-F] [-o output_file] topology_file(s)                      - parse whole simulation\n";
$usageString .= "    zimulator.pl -r topology_file [-T time] [-F time] [-o output_file] dump_files    - parse single run\n";
$usageString .= "    zimulator.pl -a [-o output_file] result_file(s)                                  - print average time\n";
$usageString .= "    zimulator.pl -z [-i] topology_file(s)                                            - analyze topology\n";
$usageString .= "    zimulator.pl -x topology_file(s)                                                 - create VNUML xml file\n";
$usageString .= "    zimulator.pl -g type [-o output_file] [-i] size(s)                               - generate topology\n";
$usageString .= "    zimulator.pl -C topology_file(s)                                                 - check topology file syntax\n";
$usageString .= "    zimulator.pl -H [-o output_file] file(s)                                         - print dump or result file in human readable format\n";
$usageString .= "    zimulator.pl -V                                                                  - print version\n";
$usageString .= "    zimulator.pl -h                                                                  - print help\n\n"; 
$usageString .= "    zimulator.pl -hv             to get a longer help message.\n\n";
$usageString .= "    zimulator.pl --testall    starts all software tests (for developers)\n\n";
#}}}

my $verboseUsageString .= "Modes:\n------\n";#{{{
$verboseUsageString .= "    -s simulation_file  : Simulate all defined simulations of simulation file.\n";
$verboseUsageString .= "                          Default output is added to topologyname-simulationname/topologyname.txt.\n";
$verboseUsageString .= "    -S topology_file(s) : Parse dumps and recalculate time, packet count and traffic.\n";
$verboseUsageString .= "                          'time' for F and T flag comes from result file.\n";
$verboseUsageString .= "                          Default output is topologyname-simulationname/topologyname.txt.\n";
$verboseUsageString .= "    -r topology_file    : Parse one dump and recalculate time, packet count and traffic.\n";
$verboseUsageString .= "                          Default output is - (STDOUT).\n";
$verboseUsageString .= "    -a result_file(s)   : Calculates for each file average time, packet count and traffic\n";
$verboseUsageString .= "                          from all runs of the result file. Default ouput is - (STDOUT)\n";
#$verboseUsageString .= "    -P result_file(s)   : Print results in a gnuplot readable format.\n";
#$verboseUsageString .= "                          Default output is topologyname_plot.txt.\n";
$verboseUsageString .= "    -z topology_file(s) : Analyse the topology described in topology file \n";
$verboseUsageString .= "                          Default output is topology file (file is rewritten, all comments are lost).\n";
$verboseUsageString .= "    -x topology_file(s) : Create VNUML xml file(s) from topology file(s).\n";
$verboseUsageString .= "                          Default output is topologyname.xml.\n";
$verboseUsageString .= "    -g type             : Generate topology of type 'type' (see section 'Topology Types').\n";
$verboseUsageString .= "                          Default output is typename_arguments.zvf.\n";
$verboseUsageString .= "    -C topology_file(s) : Check topology file(s) for syntax errors.\n";
$verboseUsageString .= "                          Default output is - (STDOUT).\n";
$verboseUsageString .= "    -H file(s)          : If Dump files are given print routing packets chronological ordered in human readable format.\n";
$verboseUsageString .= "                          If result files are given the results are printed in human readable format.\n";
$verboseUsageString .= "                          Default output is - (STDOUT).\n";
$verboseUsageString .= "    -V                  : Print version and exit.\n";
$verboseUsageString .= "                          Default output is - (STDOUT).\n";
$verboseUsageString .= "    -h                  : Print this help and exit.\n";
$verboseUsageString .= "                          Default output is - (STDOUT).\n\n";

$verboseUsageString .= "Options:\n--------\n";
$verboseUsageString .= "    -v             : Verbose mode, prints more informations.\n";
$verboseUsageString .= "    -c config_file : Use given configuration file.\n";
$verboseUsageString .= "    -o output_file : Write result to file 'output_file'. If not given the default file is used.\n";
#$verboseUsageString .= "    -A             : Calculate average over the runs before plotting.\n";
#$verboseUsageString .= "    -S size(s)     : One or more integer numbers (for more informations see section 'Topology Types').\n";
#$verboseUsageString .= "    -r run         : Number of run to recalculate.\n";
$verboseUsageString .= "    -T             : Only take Packets earlier than 'failure time' for convergence analysis.\n";
$verboseUsageString .= "    -F             : Only take Packets later than 'failure time' for convergence analysis.\n\n";
$verboseUsageString .= "    -i             : Generates image of graph and writes it to png file.\n\n";
$verboseUsageString .= "    -I inf_metric  : Assume the provided value as infinity (for RMTI).\n\n";

$verboseUsageString .= "Topology Types:\n---------------\n";
$verboseUsageString .= "When generating topologys there are the following types available:\n\n";

$verboseUsageString .= "Type           Sizes   Description\n";
$verboseUsageString .= "----------------------------------\n";
$verboseUsageString .= "row            V       a row with V vertices\n";
$verboseUsageString .= "circle         V       a circle with V vertices\n";
$verboseUsageString .= "star2          V       a vertex with V-1 vertices connected to it\n";
$verboseUsageString .= "star           D R     a vertex with R rows of diameter D/2 connected to it\n";
$verboseUsageString .= "square         N       a square of NxN vertices\n";
$verboseUsageString .= "crown          N       a crown N topology\n";
$verboseUsageString .= "circlex_rowy   X Y     a circle with X vertices connected to a row with Y vertices\n";
$verboseUsageString .= "random         V E     a random graph with V vertices and E edges\n\n";#}}}


##
# Starts all test programms with unit tests for important functions
sub testFunctions {#{{{
    my $v = shift;
    $v = "" unless defined $v;
    chdir("testcases");
    print "\n\nStart testing zimulator.pl functions\n------------------------------------\n";
    
    print "\nTesting Utilities.pm ...\n";
    my $ok = system("./testUtilities.pl $v");
    print "\nTest failed!!!\n\n" and exit 1 if $ok;

    print "\nTesting File.pm ... \n";
    $ok = system("./testFile.pl $v");
    print "\nTest failed!!!\n\n" and exit 1 if $ok;

    print "\nTesting Topology.pm ... \n";
    $ok = system("./testTopology.pl $v");
    print "\nTest failed!!!\n\n" and exit 1 if $ok;

    print "\nTesting RIPParser.pm ... \n";
    $ok = system("./testRIPParser.pl $v");
    print "\nTest failed!!!\n\n" and exit 1 if $ok;

    print "\nTesting Result.pm ... \n";
    $ok = system("./testResult.pl $v");
    print "\nTest failed!!!\n\n" and exit 1 if $ok;

    print "\nTesting TopologyGenerationFunctions.pm ... \n";
    $ok = system("./testTopologyGenerationFunctions.pl $v");
    print "\nTest failed!!!\n\n" and exit 0 if $ok;

    print "\nAll tests done\n\n";
    chdir("..");
}#}}}

##
# Starts all test programms with unit tests for program execution
sub testProgram {#{{{
    my $v = shift;
    $v = "" unless defined $v;

    chdir("testcases");
    print "\n\nStart testing zimulator.pl functions\n------------------------------------\n";

    print "\nTesting main program ... \n";
    my $ok = system("./testZimulator.pl $v");
    print "\nTest failed!!!\n\n" and exit 1 if $ok;

    print "\nAll tests done\n\n";
    chdir("..");
}#}}}


# get arguments and create configuration object #{{{

# VARIABLES: Options and arguments
# $opt - option is the first argument
# @files - files are all other arguments
my @modes = ("s","S","r","a","z","x","g","C","H","V","h","t");
#my @modes = ("s","S","r","a","P","z","x","g","C","H","V","h");
my @files = ();
my %opts = ();

if(defined @ARGV){
    testProgram($ARGV[1]) and exit 0 if $ARGV[0] eq "--testp";
    testFunctions($ARGV[1]) and exit 0 if $ARGV[0] eq "--testf";
    testFunctions($ARGV[1]) and testProgram($ARGV[1]) and exit 0 if $ARGV[0] eq "--testall";
}


# get options with Getopt module
#getopts('s:Sr:aPzxg:CHVhAvc:o:fTF', \%opts);
getopts('s:Sr:azxg:CHVhAvc:o:fT:F:it:I:', \%opts);

# prepare all given files that are not catched by getopts
# TODO: rückgabewert für jede datei prüfen. wenn 0 => nicht hinzufügen
foreach my $f (@ARGV) { 
    my $file;
    if($f =~ /\.zvf$/){
        $file = new TopologyFile($f);
    } elsif($f =~ /\.dump/){
        #print STDERR "preparing file $f\n";
        $file = new DumpFile($f);
        print STDERR "Error in dumpfile!!!\n" and exit 0 unless ref $file;
#    } elsif($f =~ /\.cfg/){
#        $file = new SimulationDescriptionFile($f);
    } else {
        $file = new File($f); 
    }
    push(@files,$file) if (-f $f) and $file; }


# check Options for syntax errors
my $countModes = 0;
foreach(@modes){ $countModes++ if $opts{$_}; }
die "Only one mode at a time!\n" if($countModes > 1);
die "There must be given at least one mode" if($countModes < 1 and keys %opts > 0);
die "It is not possible to use the F flag and the T flag at the same time" if $opts{"F"} and $opts{"T"};


# creating configuration object and setting given options
my $configuration = Configuration::instance($opts{"c"});
$configuration->setOption("VERBOSE",$opts{"v"});
$configuration->setOption("OUTPUT_FILENAME",$opts{"o"});
if($opts{"I"}){
  $configuration->setOption("INFINITY_METRIC",$opts{"I"});
} else {
  $configuration->setOption("INFINITY_METRIC",16);
}
my $verbose = $opts{"v"};
if($opts{"i"} and ($opts{"g"} or $opts{"z"})){
    $configuration->setOption("CREATEGRAPHIMAGE",1);
}

my $parseOptions = "";
my $failureTime = 0;
if($opts{"F"}){
    $parseOptions = "-from";
    $failureTime = $opts{"F"};
} elsif($opts{"T"}){
    $parseOptions = "-to";
    $failureTime = $opts{"T"};
}#}}}

if($opts{"s"}){ # Simulate #{{{
    my $simulator = new Simulator(new ExecutionDescriptionFile($opts{"s"}));
    $simulator->simulate($opts{"v"});
    print "\nAll simulations done.\n\n";
#}}}
} elsif($opts{"S"}){ # Recalculate whole simulation #{{{
    foreach my $f (@files) {
        print STDERR "Syntax error at topology file $f - ignoring this simulation\n" and next unless ref $f;
        my @resultFiles = Utilities::getResultFiles($f);
        foreach my $resultFile (@resultFiles){
            my $result = new Result($resultFile,new Topology($f));
            next unless $result; # TODO: option force ohne die abgebrochen wird? abbrechen?
            $result->recalculateAllRuns($parseOptions);
            my $ok = $result->writeResultFile();
            print STDERR "Error when writing file!\n" unless $ok;
        }
    }
#}}}
} elsif($opts{"r"}){ # Recalculate single run #{{{
# default file is stdout
    die $opts{"r"}." does not exist\n" unless -f $opts{"r"};
    my $topologyFile = new TopologyFile($opts{"r"});
    print STDERR "Syntax error in topology file $topologyFile - exiting\n" and exit 0 unless ref $topologyFile;
    
    my $result = new Result(new File("temp.txt"),new Topology($topologyFile));
    #print "parseOptions: $parseOptions, failureTime: $failureTime\n";
    $result->addRun("rip",$parseOptions,$failureTime,1,@files);
    print $result->getResultText(0) if $verbose;
    my $outputFileName = $configuration->getOption("OUTPUT_FILENAME");
    $outputFileName = "-" unless $outputFileName;
    my $outputFile = new File($outputFileName);
    $outputFile->addLine($result->getResultLine(0));
    $outputFile->writeFile();
#}}}
} elsif($opts{"a"}) { # print Average#{{{
#TODO: -o implementieren
    foreach my $f (@files) {
        my $result = new Result($f,0);
        next unless $result;
        my $line  = $result->getAverageLine();

        print $line;
    }
    print "\n";
#}}}
} elsif($opts{"z"}){ # analyZe topology file #{{{
    foreach my $f (@files){
        print STDERR "Syntax error in topology file $f\n" and next unless ref $f;
        my $outputFileName = $configuration->getOption("OUTPUT_FILENAME");
        $f->setPath($outputFileName) if $outputFileName;
        my $g = new Topology($f);
        my $zvfFile = $g->toZVF();
        print $g->getPropertyText() if $verbose;
        $zvfFile->writeFile();
        $zvfFile = undef;
    }
#}}}
} elsif($opts{"x"}){ # Create VNUML xml file #{{{
    foreach my $f (@files){
        print STDERR"Syntax error in topology file $f\n" and next unless ref $f;
        my $topology = new Topology($f);
        my $xmlFile = $topology->toXML();
        my $outputFileName = $configuration->getOption("OUTPUT_FILENAME");
        $xmlFile->setPath($outputFileName) if $outputFileName;
        $xmlFile->writeFile();
    }
#}}}
} elsif($opts{"g"}){ # Generate topology #{{{
    my $topology = new Topology($opts{"g"},@ARGV);
    my $outputFile = $topology->toZVF();
    my @ar = $outputFile->getLineArray();
    
    my $name = $outputFile->getName();
    print $topology->getPropertyText() if $verbose;
    
    $outputFile->writeFile();
    print "$name.zvf created\n\n" if $verbose and not $name eq "-";
#}}}
} elsif($opts{"C"}){ # Check syntax #{{{
    foreach my $f (@files){
        print "File ".$f->getPath()." - OK\n" if ref $f;
        print "File $f - ERROR!\n" unless ref $f;
    }
#}}}
} elsif($opts{"H"}){ # print Dumps or result files in human readable format #{{{
    if($files[0]->getFileType() eq "dump"){
        foreach my $f (@files) { print "Error in dumpfile $f - exiting\n" and exit 1 unless ref $f; }
        
        my $parser = new RIPParser(new Topology(new File("")),0,0,@files);
        my $outputFile = $parser->getHumanReadableDumpFile();
        $outputFile->writeFile();
    } else {
        foreach my $f (@files) {
            my $result = new Result($f,0);
            my $outputFileName = $configuration->getOption("OUTPUT_FILENAME");
            $outputFileName = "-" unless $outputFileName;
            my $outputFile = new File($outputFileName);
            $outputFile->addLine($result->getAllResultTexts());
            $outputFile->writeFile();
        }
    }
#}}}
} elsif($opts{"t"}){ # check if CTI was triggered #{{{
    foreach my $f (@files) {
        print STDERR "Syntax error at topology file $f - ignoring this simulation\n" and next unless ref $f;
        my @resultFiles = Utilities::getResultFiles($f);
        foreach my $resultFile (@resultFiles){
            print "checking ".$resultFile->getPath()."\n";
            my $baseDirectory = $resultFile->getDirectory();
            my $result = new Result($resultFile,new Topology($f));
            my @runs = $result->getRuns();
            for my $run(0..$#runs){
                my %resultHash = %{$runs[$run]};
                my $dumpDir = $resultHash{DUMPDIR};
                my @dumpFiles = grep(/net[0-9]+.dump/,`ls $baseDirectory$dumpDir`);
                print STDERR "Error! No dump files in $baseDirectory$dumpDir\n" and return 0 unless @dumpFiles;
                map((chomp $_ and $_ = new DumpFile("$baseDirectory$dumpDir/$_")),@dumpFiles);
                my $parser = new RIPParser(new Topology(new File("")),0,0,@dumpFiles);
                print "Run ".($run+1).": CTI was ".($parser->checkCTI($opts{"t"},@ARGV)?"":"not")." triggered\n";
            }
        }
    }

    #}}}
} elsif($opts{"V"}){ # print Version #{{{
    print "Version: zimulator 0.2.1 - cti\n";
#}}}
} elsif($opts{"h"}){ # print Help message #{{{
    print $usageString;
    print $verboseUsageString if $configuration->getOption("VERBOSE");
    #}}}
} else { # else print usage string #{{{
    print $usageString;
}#}}}

exit 0;


# TODO: Testcases erstellen
# TODO: dateien für testfälle besser sortieren (verzeichnis für jedes modul erstellen)
# TODO: datein hinterher immer aufräumen (erzeugte dateien löschen mit unlink)
# TODO: einfache testfälle erstellen (z.B. zvf datei mit 1 netz und 1-2 router) und dabei versuchen alle fälle abzudecken
# TODO: alle modi mit fehlerhaften zvf dateien ausprobieren (und mit fehlerhaften anderen dateien)

# Force modus?

# TODO: Todos in den einzelnen dateien bearbeiten

# TODO: Mit testfällen überprüfen ob überall alles gemacht wird (bei erstellung von xml datei wird kein bild erzeugt)

# TODO: Prüfen ob jeweils richtiger dateityp (topologiedatei, dumpfile,...) übergeben wurde => dateiendung, inhalt?
# was passiert, wenn keine datei mitgegeben wurde?
# was passiert, wenn es zu einer zvf datei kein simulationsverzeichnis gibt?
# TODO: in getgraphproperties darf der graph nicht normalisiert werden. es muss eine kopie zur berechnung der artikulationen genutzt werden, da die original topologie später noch gebraucht wird

# TODO: Problem mit VISUALIZE_NET_NAMES lösen. to ZVF nur einmal durchführen, wenn graph sich verändert hat. irgendeine lösung muss es geben (DONE?)

# TODO: problem mit xml dateien lösen (es werden immer 24er netze genommen obwohl 16er eingestellt sind




# TODO: Alle Dateien durch schauen
#  verbose outputs erstellen (so viel wie nötig, so wenig wie möglich)
#  Rückgabewerte prüfen
#  Faltungen erstellen
#  variablennamen verbessern
#  kleinigkeiten verbessern
#  Speicherverwaltung prüfen!!!
#  Kommentieren
#  Dokumentieren               DONE (must be enhanced at the end)
#
# - zimulator.pl
# - Configuration.pm                
# - File.pm                         
# - RIPParser.pm                    
# - Result.pm                       
# - RIPPacket.pm                    
# - Scenario.pm                     
# - Simulator.pm                    
# - TopologyGenerationFunctions.pm  
# - Topology.pm                     
# - Utilities.pm                    

# for a better use with vim. All the markings: #{{{ and #}}} belong to it
# vim: foldmethod=marker    
