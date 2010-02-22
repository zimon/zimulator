# Package: Result
#
# 
package Result;

use warnings;
use strict;

use lib "modules";
use RIPParser;
use Utilities;
use Topology;
use DumpFile;

##
# VARIABLES: Member variables
# topology - topology object
# resultfile - file object of result file
# runs - array with a result hash for each run
#
# TODO: result hash beschreiben
# TODO: average result hash beschreiben

##
# *Contructor*
#
# PARAMETERS:
# $resultFile - file object of result file
# $topology - topology object
sub new {#{{{
    my $object = shift;
    my $resultFile = shift;
    my $topology = shift;

    my $reference = {};
    return 0 unless(defined $resultFile and defined $topology);
    bless($reference,$object);
    $reference->_initResult($resultFile,$topology);

    return($reference);
}#}}}

##
# Adds a run to the result
# 
# A result hash is generated with a RIPParser object and added to the runs array.
#
# PARAMETERS:
# $protocol - protocol string
# $parseOptions - options for RIPParser
# $failureTime - timestamp of shutting down a router or device
# @files - file objects of all dump files of the run
sub addRun {#{{{
    my $object = shift;
    my $protocol = shift;
    my $parseOptions = shift;
    my $failureTime = shift;
    my $internRunCount = shift;
    my @files = @_;

    return -1 if @files < 1;
    return -1 unless defined $protocol;

    my $testfile = $files[0];
    return -1 unless ref $testfile;
    my @testlines = $testfile->getLineArray();
    my $topology = $object->{TOPOLOGY};
    return -1 unless $topology;
    my $parser = new RIPParser($topology,$parseOptions,$failureTime,@files);
    return -1 unless $parser;
    my %result = $parser->getResultHash();
    return -1 unless keys %result;
    $result{PROTOCOL} = $protocol;
    $result{INTERNRUNCOUNT} = $internRunCount;
    my @runs = @{$object->{RUNS}};
    push(@runs,\%result);
    $object->{RUNS} = \@runs;

    return $#runs;
}#}}}

##
# Recalculates convergence properties for a specific run using a RIPParser object
# 
# PARAMETERS:
# $run - number of run to recalculate
# $parseOptions - parsing options for RIPParser
sub recalculateRun {#{{{
    my $object = shift;
    my $run = shift;
    my $parseOptions = shift;
    my $config = Configuration::instance();
    my $verbose = $config->getOption("VERBOSE");
    print "recalculating run ".($run+1)."\n" if $verbose;
    my @runs = @{$object->{RUNS}};
    my $topology = $object->{TOPOLOGY};
    my $resultFile = $object->{RESULTFILE};
    my $baseDirectory = $resultFile->getDirectory();
    my %result = %{$runs[$run]};
    my $dumpDir = $result{DUMPDIR};
    my $failureTime = $result{FAILURETIME};

    return 0 unless $topology;


    #print "getting files in dir: $baseDirectory$dumpDir\n";
    my @files = grep(/net[0-9]+.dump/,`ls $baseDirectory$dumpDir`);
    print STDERR "Error! No dump files in $baseDirectory$dumpDir\n" and return 0 unless @files;
    map((chomp $_ and $_ = new DumpFile("$baseDirectory$dumpDir/$_")),@files);

    #print "parsing files...\n";

    my $parser = new RIPParser($topology,$parseOptions,$failureTime,@files);
    my %newResult = $parser->getResultHash();
    print STDERR "Error! No result for $baseDirectory$dumpDir\n" and return 0 unless keys %newResult;

    foreach(keys %newResult) { $result{$_} = $newResult{$_}; }
    $runs[$run] = \%result;
    $object->{RUNS} = \@runs;

    #print "recalculating done\n";
    return 1;
}#}}}

##
# Recalculates convergence properties of all runs
# 
# PARAMETERS:
# $parseOptions - options for RIPParser
sub recalculateAllRuns {#{{{
    my $object = shift;
    my $parseOptions = shift;

    my @runs = @{$object->{RUNS}};
    my $config = Configuration::instance();
    my $verbose = $config->getOption("VERBOSE");
    print "recalculating ".@runs." runs:\n" if $verbose;
    for my $runCount(0..$#runs){
        if($object->recalculateRun($runCount,$parseOptions)){
            print $object->getResultText($runCount) if $verbose;
        } else {
            my @r = @{$object->{RUNS}};
            print "No result because of an error\n\n" if $verbose;
            $r[$runCount] = 0;
            $object->{RUNS} = \@r;
        }
    }
    return 1;
}#}}}


##
# Returns a string with average properties.
#
# It is possible to write results of several topologies to a result file. This function can handle multiple topologies in one file.
#
# RETURNS:
# String with result line(s)
sub getAverageLine {#{{{
    my $object = shift;
    my $file = $object->{RESULTFILE};
    my @resultList = @{$object->_getAverage()};
    my $resultLine =  "";
    foreach my $result (@resultList) {
        my %avgResult = %{$result};
        my $newFormat = (defined $avgResult{OLDFORMAT})?0:1;
        $resultLine .= $avgResult{DIAMETER}." " if $newFormat;      #  1
        $resultLine .= $avgResult{VERTICES}." " if $newFormat;      #  2
        $resultLine .= $avgResult{LEAVES}." " if $newFormat;        #  3
        $resultLine .= $avgResult{INNERVERTICES}." " if $newFormat; #  4
        $resultLine .= $avgResult{EDGES}." " if $newFormat;         #  5
        $resultLine .= $avgResult{CC}." " if $newFormat;            #  6
        $resultLine .= $avgResult{LONGESTTIME}." ";                 #  7
        $resultLine .= $avgResult{SHORTESTTIME}." ";                #  8
        $resultLine .= $avgResult{AVERAGETIME}." ";                 #  9
        $resultLine .= $avgResult{MAXTOTALPACKETS}." ";             # 10
        $resultLine .= $avgResult{MINTOTALPACKETS}." ";             # 11
        $resultLine .= $avgResult{AVERAGETOTALPACKETS}." ";         # 12
        $resultLine .= $avgResult{MAXAVERAGEPACKETS}." ";           # 13
        $resultLine .= $avgResult{MINAVERAGEPACKETS}." ";           # 14
        $resultLine .= $avgResult{AVGAVERGAPACKETS}." ";            # 15
        $resultLine .= $avgResult{MAXTOTALTRAFFIC}." ";             # 16
        $resultLine .= $avgResult{MINTOTALTRAFFIC}." ";             # 17
        $resultLine .= $avgResult{AVERAGETOTALTRAFFIC}." ";         # 18
        $resultLine .= $avgResult{AVGAVERAGETRAFFIC}." ";           # 19
        $resultLine .= $avgResult{TOPOLOGYNAME}."\n";               # 20
    }
    chomp $resultLine;
    return $resultLine;
}#}}}


## 
# Returns string with human readable output of measurement results of one run
#
# PARAMETERS:
# $run - Number of run to get result text of (optional: run pointer could be used too)
# 
# RETURNS:
# String with result text
sub getResultText {#{{{
    my $object = shift;
    my $run = shift;
    my @runs= @{$object->{RUNS}};
    return "" if not $runs[$run];
    my %results = %{$runs[$run]};
    my $output = "\nResult of run ".($run+1)."\n";

    $output .= Utilities::makeTime($results{TIMETOCONVERGENCE}*1000000)."\n";
    $output .= "TotalPacketCount = $results{TOTALPACKETCOUNT}\n";
    $output .= "average PacketCount per net = $results{AVERAGEPACKETCOUNT}\n";
    $output .= "Net$results{MOSTPACKETSNET} has most packets: $results{MOSTPACKETSNETCOUNT}\n";
    $output .= "Net$results{LEASTPACKETSNET} has least packets: $results{LEASTPACKETSNETCOUNT}\n";

    $output .= "TotalTraffic = $results{TOTALTRAFFIC}\n";
    $output .= "average Traffic per net = $results{AVERAGETRAFFIC}\n";
    $output .= "Net$results{MAXTRAFFICNET} has most traffic: $results{MAXTRAFFIC}\n";
    $output .= "Net$results{MINTRAFFICNET} has least traffic: $results{MINTRAFFIC}\n";
    $output .= "(Starttime = ".Utilities::makeTime($results{FIRSTTIMESTAMP}).", Stoptime = ".Utilities::makeTime($results{LASTTIMESTAMP}).")\n\n";

    return $output;
}#}}}

##
# Returns string with human readable output of measurement results of all runs
sub getAllResultTexts {#{{{
    my $object = shift;
    my @runs = @{$object->{RUNS}};
    my $output = "";
    for my $run (0..$#runs){
        $output.= $object->getResultText($run)."\n" if $runs[$run];
    }
    return $output;
}#}}}

## 
# Returns the result line of one run to store to result files.
# 
# PARAMETERS:
# $run - number of run to get result line from.
# 
# RETURNS:
# result line to store to file
sub getResultLine {#{{{
    my $object = shift;
    my $run = shift;
    my @runs = @{$object->{RUNS}};
    return "" unless $runs[$run];
    my %result = %{$runs[$run]};
    my $topologyName = $result{TOPOLOGYNAME};
    my $topology = $object->{TOPOLOGY};
    return 0 unless $topology;
    my $fail = $result{FAIL};
    $fail = "none" unless defined $fail;
    my $internRunCount = $result{INTERNRUNCOUNT};
    $internRunCount = 1 unless defined $internRunCount;
    my $failureTime = $result{FAILURETIME};
    $failureTime = 0 unless defined $failureTime;


    my %properties = $topology->getGraphProperties();
    my $leaves = @{$properties{LEAVES}};
    my $time = $result{TIMETOCONVERGENCE};
    my $traffic = $result{TOTALTRAFFIC};
    my $avgTraffic = $result{AVERAGETRAFFIC};
    my $minTraffic = $result{MINTRAFFIC};
    my $maxTraffic = $result{MAXTRAFFIC};


    # syntax: (has changed now)
    # d v l iv e cc time packets traffic avgpackets avgtraffic minpackets maxpackets mintraffic maxtraffic # fail failureTime topologyname protocol runcount firsttimestamp lasttimestamp

    # generating result line #{{{
    my $resultLine = "$properties{DIAMETER} ";          # 1
    $resultLine .= $properties{VERTICES}." ";           # 2
    $resultLine .= $leaves." ";                         # 3
    $resultLine .= ($properties{VERTICES}-$leaves)." "; # 4
    $resultLine .= $properties{EDGES}." ";              # 5
    $resultLine .= $properties{CC}." ";                 # 6
    $resultLine .= $time." ";                           # 7
    $resultLine .= $result{TOTALPACKETCOUNT}." ";       # 8
    $resultLine .= $traffic." ";                        # 9
    $resultLine .= $result{AVERAGEPACKETCOUNT}." ";     # 10
    $resultLine .= $avgTraffic." ";                     # 11
    $resultLine .= $result{LEASTPACKETSNET}." ";        # 12
    $resultLine .= $result{LEASTPACKETSNETCOUNT}." ";   # 13
    $resultLine .= $result{MOSTPACKETSNET}." ";         # 14
    $resultLine .= $result{MOSTPACKETSNETCOUNT}." ";    # 15
    $resultLine .= $result{MINTRAFFICNET}." ";          # 16
    $resultLine .= $minTraffic." ";                     # 17
    $resultLine .= $result{MAXTRAFFICNET}." ";          # 18
    $resultLine .= $maxTraffic." ";                     # 19
    $resultLine .= $fail." ";                           # 20
    $resultLine .= $failureTime." ";                    # 21
    $resultLine .= $topologyName." ";                   # 22
    $resultLine .= $result{PROTOCOL}." ";               # 23
    $resultLine .= $internRunCount." ";                 # 24
    $resultLine .= $result{FIRSTTIMESTAMP}." ";         # 25
    $resultLine .= $result{LASTTIMESTAMP}."\n";         # 26
    #}}} 


    return $resultLine;
}#}}}

##
# Writes result file to disk
sub writeResultFile {#{{{
    my $object = shift;
    my @runs = @{$object->{RUNS}};
    my $resultFile = $object->{RESULTFILE};
    my $config = Configuration::instance();
    my $verbose = $config->getOption("VERBOSE");
    my $outputFileName = $config->getOption("OUTPUT_FILENAME");
    my $outputFile = $resultFile;
    $outputFile = new File($outputFileName) if $outputFileName;
    $outputFile->clearFile();
    print "Writing result file: ".$outputFile->getPath()."\n" if $outputFileName ne "-" and $verbose;
    for my $run(0..$#runs) {
        next unless $runs[$run];
        my $resultLine = $object->getResultLine($run);
        return 0 unless $resultLine;
        $outputFile->addLine($resultLine);
    }
    my $ok = $outputFile->writeFile();
    return $ok;
}#}}}

##
# Returns the array with result hashes
sub getRuns {#{{{
    my $object = shift;
    return @{$object->{RUNS}};
}#}}}

##
# Reads result file (if it contains lines) and sets member variables
sub _initResult {#{{{
    my $object = shift;
    my $resultFile = shift;
    my $topology = shift;
    my @runs = ();
    $resultFile->clearFile() if $resultFile->getFileName() eq "temp.txt";
    $resultFile->resetLinePointer();

    $object->{TOPOLOGY} = $topology;
    $object->{RESULTFILE} = $resultFile;

    if($resultFile->getLength() >= 0){
        my @resultLines = $resultFile->getLineArray();
        my @runCounts = ();
        foreach my $line (@resultLines) {

            my %result = $object->_parseResultLine($line);
            my $runCount = $result{INTERNRUNCOUNT};
            my $postfix = "";
            $postfix = "_".$runCounts[$runCount] if defined $runCounts[$runCount];
            $runCounts[$runCount]++;


            my $protocol = $result{PROTOCOL};
            my $dumpDir = $protocol."_run_".$runCount.$postfix;
            $result{DUMPDIR} = $dumpDir;
            push(@runs,\%result);
        }
    } 
    $object->{RUNS} = \@runs;
}#}}}

##
# Parses a result line and returns its values
#
# PARAMETERS:
# $line - result line
#
# RETURNS:
# Result hash
sub _parseResultLine {#{{{
    my $object = shift;
    my $line = shift;
    my %result = ();
        my @lineWords = split(" ",$line);
    if($line =~ /^Run/){ # if the result file has the old format it is read #{{{
        $result{INTERNRUNCOUNT} = $lineWords[1];
        $lineWords[2] =~ m/([a-z]*?)-(.*)/;
        $result{PROTOCOL} = $1;
        $result{TOPOLOGYNAME} = $2;
        $lineWords[3] =~ m/fail=(.*)/;
        $result{FAIL} = $1;
        $lineWords[4] =~ m/^\(([0-9:]+)\):$/;
        $result{FAILURETIME} = $1;
        my ($convergenceTime) = $line =~ m/Run [0-9]+ .* fail=[a-z0-9]+ \([0-9:]+\): ([0-9:]+) # .*/;
        $convergenceTime = Utilities::makeTimeStamp($convergenceTime);
        $convergenceTime /= 1000000;#=~ s/:/./g;
        $result{TIMETOCONVERGENCE} = $convergenceTime;
        $line =~ m/.* packets=([0-9]+) #.*/;
        $result{TOTALPACKETCOUNT} = $1;
        my ($traffic) = $line =~ m/.* traffic=([0-9\.]+) #.*/;
        #$traffic /= 1024;
        $result{TOTALTRAFFIC} = $traffic/1024;
        $line =~ m/.* avgPackets=([0-9\.]+) #.*/;
        $result{AVERAGEPACKETCOUNT} = $1;
        my ($avgTraffic) = $line =~ m/.* avgTraffic=([0-9\.]+) #.*/;
        $result{AVERAGETRAFFIC} = $avgTraffic/1024;
        $line =~ m/.* minPackets=([0-9]+) \((net[0-9]+)\)/;
        $result{LEASTPACKETSNETCOUNT} = $1;
        $result{LEASTPACKETSNET} = $2;
        $line =~ m/.* maxPackets=([0-9]+) \((net[0-9]+)\)/;
        $result{MOSTPACKETSNETCOUNT} = $1;
        $result{MOSTPACKETSNET} = $2;
        $line =~ m/.* minTraffic=([0-9]+) \((net[0-9]+)\)/;
        $result{MINTRAFFIC} = $1/1024;
        $result{MINTRAFFICNET} = $2;
        $line =~ m/.* maxTraffic=([0-9]+) \((net[0-9]+)\)/;
        $result{MAXTRAFFIC} = $1/1024;
        $result{MAXTRAFFICNET} = $2;
        $result{FIRSTTIMESTAMP} = 10;
        $result{LASTTIMESTAMP} = $convergenceTime+10;
#}}}
    } else { # the new format (supports gnuplot) should be used #{{{
        $result{DIAMETER} = shift @lineWords; 
        $result{VERTICES} = shift @lineWords; 
        $result{LEAVES} = shift @lineWords; 
        $result{INNERVERTICES} = shift @lineWords; 
        $result{EDGES} = shift @lineWords; 
        $result{CC} = shift @lineWords; 
        $result{TIMETOCONVERGENCE} = shift @lineWords; 
        $result{TOTALPACKETCOUNT} = shift @lineWords; 
        $result{TOTALTRAFFIC} = shift @lineWords; 
        $result{AVERAGEPACKETCOUNT} = shift @lineWords; 
        $result{AVERAGETRAFFIC} = shift @lineWords; 
        ($result{LEASTPACKETSNET} = shift @lineWords) =~ s/^net//;  #
        $result{LEASTPACKETSNETCOUNT} = shift @lineWords; 
        ($result{MOSTPACKETSNET} = shift @lineWords) =~ s/^net//;  #
        $result{MOSTPACKETSNETCOUNT} = shift @lineWords; 
        ($result{MINTRAFFICNET} = shift @lineWords) =~ s/^net//;  #
        $result{MINTRAFFIC} = shift @lineWords;
        ($result{MAXTRAFFICNET} = shift @lineWords) =~ s/^net//;  #
        $result{MAXTRAFFIC} = shift @lineWords;
        $result{FAIL} = shift @lineWords;
        $result{FAILURETIME} = shift @lineWords;
        $result{TOPOLOGYNAME} = shift @lineWords;
        $result{PROTOCOL} = shift @lineWords;
        $result{INTERNRUNCOUNT} = shift @lineWords;
        $result{FIRSTTIMESTAMP} = shift @lineWords;
        $result{LASTTIMESTAMP} = shift @lineWords;
    }#}}}
    return %result;
}#}}}

##
# Removes best and worst value if there are more then two values
#
# RETURNS:
# New array with results
sub _removeBestWorst {#{{{
    my $object = shift;
    my @lines = @_;
    return @lines if $#lines < 2;
    my $best = 999999999999;
    my $bestIndex = -1; 
    my $worst = 0;
    my $worstIndex = -1;
    my $index = 0;
    foreach my $line (@lines) {
        my @words = split(" ",$line);
        #print STDERR "actual: $words[6], best: $best, worst:$worst\n";
        $best = $words[6] and $bestIndex = $index if $words[6] < $best;
        $worst = $words[6] and $worstIndex = $index if $words[6] > $worst;
        $index++;
    }
    $lines[$bestIndex] = 0 if $bestIndex > -1;
    $lines[$worstIndex] = 0 if $worstIndex > -1;

    return @lines;
}#}}}


##
# Calculates average convergence properties of each run 
#
# RETURNS:
# Hash with average results
sub _getAverage {#{{{
    my $object = shift;
    my $resultFile = $object->{RESULTFILE};

    my @resultList = ();

    my @lines = $resultFile->getLineArray();
    if( $lines[0] =~ /^Run/) {
        my %avgResult = $object->_getAverageFromOldResultFile();
        push(@resultList,\%avgResult);
    } else {
        my %topologys = ();
        foreach my $l (@lines) {
            my @lineSplit = split(" ",$l);
            my $topologyName = $lineSplit[21];
            #print "processing $topologyName\n";
            $topologys{$topologyName} = 1;
        }
        foreach my $topologyName (sort keys %topologys){
            my @topologyLines = $object->_removeBestWorst(grep(/\b$topologyName\b/,@lines));

            # initializing variables#{{{
            my $longestTime=0;
            my $shortestTime=999999999999;
            my $avgTime=0;

            my $maxTotalPackets=0;
            my $minTotalPackets=999999999999;
            my $avgTotalPackets=0;
            my $maxAveragePackets = 0;
            my $minAveragePackets = 99999999999999;
            my $avgAveragePackets = 0;

            my $maxTotalTraffic=0;
            my $minTotalTraffic=999999999999;
            my $avgTotalTraffic=0;
            my $maxAverageTraffic = 0;
            my $minAverageTraffic = 99999999999999;
            my $avgAverageTraffic = 0;

            my $count=0;#}}}

            my ($diameter,$vertices,$leaves,$innervertices,$edges,$cc) = (0,0,0,0,0,0);
            my $i = 1;

            foreach my $line (@topologyLines) {
                next unless $line;
# syntax:
# d v l iv e cc time packets traffic avgpackets avgtraffic minpackets maxpackets mintraffic maxtraffic # fail failureTime topologyname protocol runcount
                my @lineWords = split(" ",$line);

                ($diameter,$vertices,$leaves,$innervertices,$edges,$cc) = @lineWords;

                # calculate results#{{{
                $longestTime = $lineWords[6] if $lineWords[6] > $longestTime;
                $shortestTime = $lineWords[6] if $lineWords[6] < $shortestTime;
                $avgTime += $lineWords[6];
                #print "($topologyName) total time: $avgTime / $i = ".($avgTime/$i)."\n";
                $i++;
        
               # 9 - averagepacketcount, 10-averagetraffic
               # 11-leastpacketsnet, 12 leastpacketscount
               # 13-mostpacketsnet, 14 mostpacketscount
               # 15 mintrafficnet 16-mintraffic
               # 17-maxtrafficnet 18-maxtraffic
                $maxTotalPackets = $lineWords[7] if $lineWords[7] > $maxTotalPackets;
                $minTotalPackets = $lineWords[7] if $lineWords[7] < $minTotalPackets;
                $avgTotalPackets += $lineWords[7];
                $maxAveragePackets = $lineWords[14] if $lineWords[14] > $maxAveragePackets;
                $minAveragePackets = $lineWords[12] if $lineWords[12] < $minAveragePackets;
                $avgAveragePackets += $lineWords[9];

                $maxTotalTraffic = $lineWords[8] if $lineWords[8] > $maxTotalTraffic;
                $minTotalTraffic = $lineWords[8] if $lineWords[8] < $minTotalTraffic;
                $avgTotalTraffic += $lineWords[8];
                $maxAverageTraffic = $lineWords[18] if $lineWords[18] > $maxAverageTraffic;
                $minAverageTraffic = $lineWords[16] if $lineWords[16] < $minAverageTraffic;
                $avgAverageTraffic += $lineWords[10];#}}}

                $count++;
            }
            #print "($topologyName) $avgTime / $count = ";
            $avgTime /= $count;
            #print "$avgTime\n";
            $avgTotalPackets /= $count;
            $avgAveragePackets /= $count;
            $avgTotalTraffic /= $count;
            $avgAverageTraffic /= $count;

            # create average result hash #{{{
            my %avgResult = ();
            $avgResult{DIAMETER} = $diameter;
            $avgResult{VERTICES} = $vertices;
            $avgResult{LEAVES} = $leaves;
            $avgResult{INNERVERTICES} = $innervertices;
            $avgResult{EDGES} = $edges;
            $avgResult{CC} = $cc;
            $avgResult{TOPOLOGYNAME} = $topologyName;
            $avgResult{MAXTOTALPACKETS} = $maxTotalPackets;
            $avgResult{MINTOTALPACKETS} = $minTotalPackets;
            $avgResult{AVERAGETOTALPACKETS} = $avgTotalPackets;
            $avgResult{MAXAVERAGEPACKETS} = $maxAveragePackets;
            $avgResult{MINAVERAGEPACKETS} = $minAveragePackets;
            $avgResult{AVGAVERGAPACKETS} = $avgAveragePackets;
            $avgResult{LONGESTTIME} = $longestTime;
            $avgResult{SHORTESTTIME} = $shortestTime;
            $avgResult{AVERAGETIME} = $avgTime;
            $avgResult{MAXTOTALTRAFFIC} = $maxTotalTraffic;
            $avgResult{MINTOTALTRAFFIC} = $minTotalTraffic;
            $avgResult{AVERAGETOTALTRAFFIC} = $avgTotalTraffic;
            $avgResult{AVGAVERAGETRAFFIC} = $avgAverageTraffic;
            push(@resultList,\%avgResult);#}}}

        }
    }
    return \@resultList;
}#}}}

##
# Calculates average convergence properties of each run for result files in old format
# 
# This function is only for compytibility with old versions
#
# RETURNS:
# Hash with average results
sub _getAverageFromOldResultFile {#{{{
    my $object = shift;

    my $maxTotalPackets=0;
    my $minTotalPackets=999999999999;
    my $avgTotalPackets=0;
    my $maxAveragePackets = 0;
    my $minAveragePackets = 99999999999999;
    my $avgAveragePackets = 0;

    my $longestTime=0;
    my $shortestTime=999999999999;
    my $avgTime=0;

    my $maxTotalTraffic=0;
    my $minTotalTraffic=999999999999;
    my $avgTotalTraffic=0;
    my $maxAverageTraffic = 0;
    my $minAverageTraffic = 99999999999999;
    my $avgAverageTraffic = 0;

    my $count = 0;

    my $resultFile = $object->{RESULTFILE};
    my @lines = $resultFile->getLineArray();
    map(s/^Run [0-9]+ .*?: ([0-9:]+)/$1/,@lines);
    @lines = sort @lines;
    pop @lines if $#lines > 5;
    pop @lines if $#lines > 8;
    pop @lines if $#lines > 12;
    shift @lines if $#lines > 5;
    shift @lines if $#lines > 8;
    shift @lines if $#lines > 12;
    foreach my $line (@lines) {#{{{
        my ($time) = $line =~ m/^([0-9:]+) #.*/;
        my @lineSplit = split(" # ",$line);
        map(s/[a-zA-Z]+=([0-9]+)/$1/,@lineSplit);
        #$lineSplit[1] =~ s/[a-zA-Z]+=([0-9]+)/$1/;
        #$lineSplit[3] =~ s/[a-zA-Z]+=([0-9]+)/$1/;

        # calculate packet counts
        $avgTotalPackets += $lineSplit[1];
        $maxTotalPackets = $lineSplit[1] if $lineSplit[1] > $maxTotalPackets;
        $minTotalPackets = $lineSplit[1] if $lineSplit[1] < $minTotalPackets;
        $avgAveragePackets += $lineSplit[3];
        $maxAveragePackets = $lineSplit[3] if $lineSplit[3] > $maxAveragePackets;
        $minAveragePackets = $lineSplit[3] if $lineSplit[3] < $minAveragePackets;
        
        # calculate average time
        my $timestamp = Utilities::makeTimeStamp($time);
        $shortestTime=$timestamp if($timestamp<$shortestTime);
        $longestTime=$timestamp if($timestamp>$longestTime);
        $avgTime+=$timestamp;

        # claculate traffic
        #$lineSplit[2] =~ s/[a-zA-Z]+=([0-9]+)/$1/;
        #$lineSplit[4] =~ s/[a-zA-Z]+=([0-9]+)/$1/;
        $avgTotalTraffic += $lineSplit[2];
        $maxTotalTraffic = $lineSplit[2] if $lineSplit[2] > $maxTotalTraffic;
        $minTotalTraffic = $lineSplit[2] if $lineSplit[2] < $minTotalTraffic;
        $avgAverageTraffic += $lineSplit[4];
        $maxAverageTraffic = $lineSplit[4] if $lineSplit[4] > $maxAverageTraffic;
        $minAverageTraffic = $lineSplit[4] if $lineSplit[4] < $minAverageTraffic;

        $count++;
    }#}}}
    $avgTime /= $count;
    $avgTotalPackets /= $count;
    $avgAveragePackets /= $count;
    $avgTotalTraffic /= $count;
    $avgAverageTraffic /= $count;

    # create average result hash #{{{
    my %avgResult = ();
    $avgResult{OLDFORMAT} = 1; # tell to use the old format
    $avgResult{MAXTOTALPACKETS} = $maxTotalPackets;
    $avgResult{MINTOTALPACKETS} = $minTotalPackets;
    $avgResult{AVERAGETOTALPACKETS} = $avgTotalPackets;
    $avgResult{MAXAVERAGEPACKETS} = $maxAveragePackets;
    $avgResult{MINAVERAGEPACKETS} = $minAveragePackets;
    $avgResult{AVGAVERGAPACKETS} = $avgAveragePackets;
    $avgResult{LONGESTTIME} = $longestTime;
    $avgResult{SHORTESTTIME} = $shortestTime;
    $avgResult{AVERAGETIME} = $avgTime;
    $avgResult{MAXTOTALTRAFFIC} = $maxTotalTraffic;
    $avgResult{MINTOTALTRAFFIC} = $minTotalTraffic;
    $avgResult{AVERAGETOTALTRAFFIC} = $avgTotalTraffic;
    $avgResult{AVGAVERAGETRAFFIC} = $avgAverageTraffic;#}}}

    return %avgResult;
}#}}}

1;



# for a better use with vim. All the markings: #{{{ and #}}} belong to it
# vim: foldmethod=marker    
