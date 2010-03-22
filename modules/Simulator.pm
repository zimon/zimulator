# Package: Simulator
#
# Reads configuration file and runs simulation
package Simulator;

use strict;
use warnings;

use lib ".";
use Scenario;
use Result;
use Topology;
use Utilities;
use File;
use DumpFile;
use TestCaseFile;

##
# VARIABLES: Member variables
# descriptionfile - file object of execution description file
# scenario - scenario object (is created new for each run)
# result - result object (is created new for each run)
#
# See also <_initObjects>

##
# *Constructor*
#
# PARAMETERS:
# $descriptionFile - file object of description file
sub new {#{{{
    my $object = shift;
    my $descriptionFile = shift;
    my $reference = {};
    bless($reference,$object);
    $reference->{DESCRIPTIONFILE} = $descriptionFile;
    return($reference);
}#}}}


##
# Parses execution description file and calls _runScenario for each run.
#
# Decrements the number of runs in the file after each run.
#
# Comments out lines with simulations that failed or finished
# 
# Description file format: 
# > topologyName testCaseName protocol maxruns maxfails
sub simulate {#{{{
    my $object = shift;
    my $descriptionFile = $object->{DESCRIPTIONFILE};
    my $failings = 0;
    my $runCount = 0;
    while($descriptionFile->getLength >= 0) {
        my $line = $descriptionFile->getLine(0);
        #$descriptionFile->resetLinePointer();
        my ($topologyName,$testCaseName,$protocol,$maxRuns,$maxFails) = split(" ",$line); 
        print "\nSimulating $topologyName-$testCaseName\n";

        my $success = $object->_initObjects($topologyName,$testCaseName,$protocol) ? $object->_runScenario() : 0;
        $failings += 1-$success;
        $runCount += $success;
        print "\nRuns done: $runCount (".($maxRuns-$success)." left)\nRuns failed: $failings (max $maxFails)\n\n";

        # try again if run ws not successfull and has not failed maxFails times
        next if (not $success) and $failings < $maxFails;


        # if run succeeded and there was a dump, parse it
        if($success){
            my $testCaseFile = $object->{SCENARIO}->getTestCaseFile();
            if($testCaseFile->getFirstLineGrep("tcpdump") or $testCaseFile->getFirstLineGrep("all")){
                my $dumpDirectory = $object->_moveDumpFiles($runCount);
                #print "dumpDirectory = $dumpDirectory\n";
                my $ok = $object->_parseDumps($dumpDirectory);

                print "\nAn error occured while parsing the dumps!!!\n\n" and next unless $ok;
            }
            $testCaseFile = undef;
        }

        # load description file again to avoid overwriting changes (by the user) during the run
        my $savedDescriptionFile = File->new($descriptionFile->getFileName());
        my $lineIndex = $savedDescriptionFile->getIndexFirstLineGrep("^$topologyName $testCaseName $protocol");

        # if the simulation was removed take the next one defined in file
        print "line '$topologyName $testCaseName $protocol ...' does not exist\n" and next if $lineIndex < 0;

        # comment out actual simulation if all runs are done or maxFails is reached
        my $newLine = "";
        ($topologyName,$testCaseName,$protocol,$maxRuns,$maxFails) = split(" ",$savedDescriptionFile->getLine($lineIndex));
        if($failings >= $maxFails or $maxRuns < 2) {
            $newLine = "#".$savedDescriptionFile->getLine($lineIndex); #[$lineIndex]; 
            $runCount = 0; 
            $failings = 0;
        } else { # else decrement maxRuns
            $newLine = $topologyName." ".$testCaseName." ".$protocol." ".($maxRuns-1)." ".$maxFails;
        }
        # save changed line
        $savedDescriptionFile->setLine($lineIndex,$newLine);

        # write changed file and reload it
        $savedDescriptionFile->writeFile();
        $descriptionFile = $savedDescriptionFile;
        $descriptionFile->readFile();

        # free memory
        $savedDescriptionFile = undef;
    }
}#}}}


## 
# Executes start command
# 
# PARAMETERS:
# $argument - given argument
# 
# Valid arguments are "scenario", "protocol", "tcpdump" and "all"
# 
# RETURNS:
# 1 if successfull. 0 is returned if something went wrong 
sub _start {#{{{
    my $object = shift;
    my $argument = shift;
    my $scenario = $object->{SCENARIO};

    my $ok = 0;
    if($argument eq "scenario"){
        $ok = $scenario->startScenario();
    } elsif($argument eq "protocol"){
        $ok = $scenario->startRoutingDaemon();
    } elsif($argument eq "tcpdump"){
        $ok = $scenario->startDumps();
    } elsif($argument eq "all"){
        $ok = $scenario->startScenario();
        sleep(3);
        $ok = $ok and $scenario->startDumps();
        sleep(3);
        $ok = $ok and $scenario->startRoutingDaemon();
    } else {
        print "Cannot start $argument. Not known!\n";
        return 0;
    }
    return $ok;
}#}}}

##
# Executes stop command
#
# PARAMETERS:
# $argument - given argument
# 
# RETURNS:
# 1 if successfull. 0 is returned if something went wrong 
# 
# See Also:
# <start>
sub _stop {#{{{
    my $object = shift;
    my $argument = shift;
    my $scenario = $object->{SCENARIO};

    if($argument eq "scenario"){
        $scenario->stopScenario();
    } elsif($argument eq "protocol"){
        print "This is not implemented because its not needed\n";
    } elsif($argument eq "tcpdump"){
        system("killall tcpdump");
    } elsif($argument eq "all"){
        system("killall tcpdump");
        sleep(3);
        $scenario->stopScenario();
    } else {
        print "Cannot stop $argument. Not known!\n";
        return 0;
    }
    return 1;
}#}}}

##
# Disables router or device
#
# Router and device can be "random" with optional routers that should not be disabled in square brackets.
# 
# Syntax (examples):
# > disable(ROUTER,DEVICE) (DEVICE is optional)
# > disable(RANDOM[EXCLUDELIST])
#
# disable(r) - disable router r
# disable(random) - disable random router
# disable(random[r1,r2] - disable random router but not r1 or r2
# disable(r,1) - disable device 1 on router r
# disable(r,random) - disable random device on router r
# disable(random,random) - disable random device on random router
#
# PARAMETERS:
# $fail - argument with router and optional device
sub _disable {#{{{
    my $object = shift;
    my $fail = shift;
    my $scenario = $object->{SCENARIO};
    my $argument = "";
    my @failSplit = split(",",$fail);
    $failSplit[1] = "" unless defined $failSplit[1];

    if($failSplit[0] =~ /random/){
        $failSplit[0] = $scenario->getRandomRouter($failSplit[0]);
    }
    if($failSplit[1] =~ /random/){
        $failSplit[1] = $scenario->getRandomDevice($failSplit[0],$failSplit[1]);
    }

    $argument = $failSplit[2] if defined $failSplit[2];

    $scenario->setFail($failSplit[0].",".$failSplit[1].",".$argument);
    $scenario->disable($failSplit[0],$failSplit[1],$argument);

    return 1;
}#}}}

##
# Enables disabled router or device
#
# If no argument is given the last disabled router or device is loaded from scenario object
# 
# PARAMETERS: optional
# $fail - router or device to enable (optional)
sub _enable {#{{{
    my $object = shift;
    my $fail = shift;
    my $scenario = $object->{SCENARIO};
    $fail = $scenario->getFail() unless defined $fail;
    $fail = $scenario->getFail() if $fail eq "";
    my @failSplit = split(",",$fail);
    $failSplit[1] = "" unless defined $failSplit[1];
    $scenario->enable($failSplit[0],$failSplit[1]);
    
    return 1;
}#}}}


##
# Parses tcpdump dumps and stores convergencetime, packet- and traffic statistics to resultfile
#
# Moves tcpdump files to own unique directory (named with runcount)
#
# PARAMETERS:
# $dumpDirectory - directory of dump files
# 
# RETURNS:
# 1 if successfull, 0 else
sub _parseDumps {#{{{
    my $object = shift;
    my $dumpDirectory = shift;
    (my $internRunCount = $dumpDirectory) =~ s/.*rip_run_([0-9]+).*/$1/;
    my $result = $object->{RESULT};
    my $scenario = $object->{SCENARIO};
    my $protocol = $scenario->getProtocol();
    my $failureTime = $scenario->getTime();
    my $parseOptions = "";

    my $testCaseFile = $object->{SCENARIO}->getTestCaseFile();
    $failureTime = "cti" if $testCaseFile->getFirstLineGrep("cti");

    $parseOptions = "-from" if $failureTime;

    my @fileNames = `ls $dumpDirectory`;
    my @files = ();
    foreach(@fileNames){ push(@files,new DumpFile($dumpDirectory."/".$_)); }
    my $runIndex = $result->addRun($protocol,$parseOptions,$failureTime,$internRunCount,@files);
    return 0 if $runIndex == -1;
    #print "runIndex = $runIndex\n";
    my $config = Configuration::instance();
    print $result->getResultText($runIndex) if $config->getOption("VERBOSE");

    my $ok = $result->writeResultFile();
    return $ok;
}#}}}

##
# Parses tcpdump dumps. This is an old version for compatibility. DEPRECATED!
#sub parseDumps_old {#{{{
#    my $object = shift;
#    my $runCount = shift;
#    my $scenario = $object->{SCENARIO};
#    my $topologyName = $scenario->getTopologyName();
#    my $protocol = $scenario->getProtocol();
#    my $failureTime = $scenario->getTime();
#    my $option = "";
#    $option = "-s $failureTime" if $failureTime != 0;
#    my $fail = $scenario->getFail();
#    my $resultLine = ProtocolParser::parseScenario($scenario,$failureTime,$runCount);
#    return 0 if $resultLine eq "0";
#    #chdir( $baseDir . $topologyName . "_dumps" );
#    my $directory =  $baseDir . $protocol . "_run_" . $runCount;
#    if(-d $directory){ # never ever use the sime directory twice
#        my $postfix = 1;
#        while(-d $directory."_$postfix"){
#            $postfix++;
#        }
#        $directory .= "_$postfix";
#    }
#    mkdir($directory);
#    system( "mv ".$baseDir."net* $directory");
#
#    my $config = Configuration::instance();
#    my $outputFileName = getOption("OUTPUT_FILENAME");
#
#    File::addLineToFile($baseDir."$topologyName.txt",$resultLine) unless defined $outputFileName;
#    File::addLineToFile($$outputFileName,$resultLine) unless $outputFileName eq "-";
#    print $resultLine."\n" if $outputFileName eq "-";
#
#    return 1;
#}#}}}

## 
# Parses configuration file and executes the associated commands
#
# RETURNS:
# 1 if successfull, 0 else
sub _runScenario {#{{{
    my $object = shift;
    my $scenario = $object->{SCENARIO};
    my $testCaseFile = $scenario->getTestCaseFile();
    my $config = Configuration::instance();
    my $verbose = $config->getOption("VERBOSE");
    my $outputFileName = $config->getOption("OUTPUT_FILENAME");
    my $ok = 1;

    while($testCaseFile->hasLines()) {
        my $line = $testCaseFile->getNextLine();
        
        my ($argument) = $line =~ m/[a-z]*\((.*)\)/;

        if($line =~ /start\(/){
           return 0 unless $object->_start($argument); 
        } elsif($line =~ /stop\(/){
            $object->_stop($argument);
        } elsif($line =~ /sleep\(/){
            print "\nsleeping $argument seconds\n" if $verbose;
            sleep $argument;
        } elsif($line =~ /execute\(/){
            my @args = split(",",$argument);
            print "\nexecuting '$args[1]' on router $args[0]\n" if $verbose;
            $ok = $scenario->execute(@args);
            print "\ncouldn't execute '$args[1]' on router $args[0]\n" and return 0 unless $ok;
        } elsif($line =~ /disable\(/){
            $object->_disable($argument);
        } elsif($line =~ /enable\(/){
            $object->_enable($argument);
        } elsif($line =~ /gettime\(/){
            $scenario->setTime(Utilities::getTimeStamp());
        } else {
            print "line '$line' not known!\n";
            return 0;
        }
    }

    return $ok;
}#}}}


##
# Creates Topology, Scenario and Result objects and sets Scenario and Result as member variables
#
# PARAMETERS:
# $topologyName - name of topology file (with path but without filetype)
# $testCaseName - name of test case file (with path but without filetype)
# $protocol - protocol string
sub _initObjects {#{{{
    my $object = shift;
    my ($topologyName,$testCaseName,$protocol) = @_;

    print "\n\n$topologyName.zvf does not exists!!\n\n" and return 0 unless -f $topologyName.".zvf";
    my $topology = new Topology(new File("$topologyName.zvf"));

    if(not -f $topologyName.".xml"){
        print "\n\n$topologyName.xml does not exists! Generating it from $topologyName.zvf...\n\n";
        my $xmlFile = $topology->toXML();
        $xmlFile->writeFile();
    }
    print "\n\n$testCaseName.cfg does not exists!!\n\n" and return 0 unless -f $testCaseName.".cfg";
    my $testCaseFile = new TestCaseFile("$testCaseName.cfg");

    my $dir = $testCaseFile->getDirectory().$testCaseFile->getName()."-".$topology->getName();
    mkdir($dir) unless -d $dir;
    my $scenario = new Scenario($testCaseFile,$topology,$protocol,$dir);
    my $config = Configuration::instance();
    my $outputFileName = $config->getOption("OUTPUT_FILENAME");
    $outputFileName = $dir."/".$topologyName.".txt" unless $outputFileName;
    my $result = new Result(new File($outputFileName),$topology);

    $object->{RESULT} = $result;
    $object->{SCENARIO} = $scenario;
    return 1;
}#}}}

##
# Creates new dump directory and moves the dump files to it.
#
# PARAMETERS:
# $runCount - Number of run
# 
# RETURNS:
# String with dump directory
sub _moveDumpFiles {#{{{
    my $object = shift;
    my $runCount = shift;
    my $scenario = $object->{SCENARIO};
    my $protocol = $scenario->getProtocol();

    my $baseDir = $scenario->getBaseDir();
    my $directory =  $baseDir . $protocol . "_run_" . $runCount;
    if(-d $directory){ # never ever use the same directory twice
        my $postfix = 1;
        while(-d $directory."_$postfix"){
            $postfix++;
        }
        $directory .= "_$postfix";
    }
    mkdir($directory);
    system( "mv ".$baseDir."net* $directory");

    return $directory;
}#}}}


1;

# for a better use with vim. All the markings: #{{{ and #}}} belong to it
# vim: foldmethod=marker    
