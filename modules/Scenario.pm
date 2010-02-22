#
# Package: Scenario
#
# Class that represents a VNUML scenario. The scenario can be started and stopped with vnuml. Single routers or devices can be shut down.
# 
# It is also used as data structure to store information about the running scenario at.

package Scenario;
use strict;
use warnings;
use Thread;

use lib ".";
use File;
use Configuration;


##
# VARIABLES: Member Variables
# simulationName - name of simulation file without suffix
# testCaseFile - file object of test script
# topology - topology object
# topologyName - name of topology file without suffix
# protocol - protocol string
# routers - router hash (routername => netstring)


##
# Constructor
# 
# PARAMETERS:
# $testCaseFile - file object of simulation execution file
# $topology - topology object 
# $protocol - the protocol to be used at simulation
# $baseDirectory - directory to store all output
sub new {#{{{
    my $object = shift;
    my $testCaseFile = shift;
    my $topology = shift;
    my $protocol = shift;
    my $baseDirectory = shift;
    my $reference = {};
    bless($reference,$object);
    $reference->_initScenario($testCaseFile,$topology,$protocol,$baseDirectory);
    return($reference);
}
#}}}

##
# Starts vnumlparser with a scenario file. Then executing the start@scenario script.
sub startScenario {#{{{
    my $object = shift;
    my $scenarioName = $object->{TOPOLOGYNAME};
    my $config = Configuration::instance();
    my $verbose = $config->getOption("VERBOSE");
    print "\nStarting Scenario $scenarioName in Simulation $object->{SIMULATIONNAME} at ".localtime(time)." with protocol ".$object->{PROTOCOL}."\n\n";
    my $executionString = $config->getOption("VNUML_PATH")."/vnumlparser.pl ".$config->getOption("VNUML_START_PARAMETERS")." $scenarioName.xml >> ".$config->getOption("LOGFILE")."\n";
    print "Executing: $executionString\n" if $verbose;
    my $ok = $object->_executeCommand($executionString);
    return 0 unless $ok;

    print "Scenario started, waiting 3 seconds and starting zebra...\n\n" if $verbose;
    sleep 3;
    $executionString = $config->getOption("VNUML_PATH")."/vnumlparser.pl ".$config->getOption("VNUML_EXEC_PARAMETERS")."start\@$scenarioName.xml >> ".$config->getOption("LOGFILE");
    $ok = $object->_executeCommand($executionString);

    sleep 2;
    if ( not $object->_checkDaemon("zebra") ) {
        return 0;
    }
    print "zebra startet\n\n" if $verbose;

    return $ok;
}#}}}


##
# Stopps the vnuml-scenario. All UML and switch processes are stopped
sub stopScenario {#{{{
    my $object = shift;
    my $scenarioName = $object->{TOPOLOGYNAME};
    my $config = Configuration::instance();
    system($config->getOption("VNUML_PATH")."/vnumlparser.pl ".$config->getOption("VNUML_EXEC_PARAMETERS")." stop\@$scenarioName.xml >> ".$config->getOption("LOGFILE"));
    system($config->getOption("VNUML_PATH")."/vnumlparser.pl ".$config->getOption("VNUML_STOP_PARAMETERS")." $scenarioName.xml >> ".$config->getOption("LOGFILE"));
    return 1;
}#}}}


##
# Starts routing daemon
sub startRoutingDaemon {#{{{
    my $object = shift;
    my $scenario = $object->{TOPOLOGYNAME};
    my $protocol = $object->{PROTOCOL};
    my $config = Configuration::instance();
    my $verbose = $config->getOption("VERBOSE");
    print "\nstarting $protocol daemons\n\n" if $verbose;
    my $executionString = $config->getOption("VNUML_PATH")."/vnumlparser.pl ".$config->getOption("VNUML_EXEC_PARAMETERS")."$protocol\@$scenario.xml >> ".$config->getOption("LOGFILE");
    $object->_executeCommand($executionString);
    sleep 2;

    if ( not $object->_checkDaemon($protocol) ) {
        print "\nExiting!!!\n\n";
        return 0;
    }
    return 1;
}#}}}

##
# Returns a random Router. There can be defined routers that should not be returned (and shut down)
# 
# PARAMETERS:
# $needed - comma separated string of routers that should not be returned
# 
# RETURNS:
# A random Router. 0 will be returned in case of an error or if no router could be returned.
sub getRandomRouter {#{{{
    my $object = shift;
    my $needed = shift;
    my $result = 0;

    $needed =~ s/.*\[(.*?)\]/$1/;
    my @neededRouters = split(";",$needed);
    my %routerHash = %{$object->{TOPOLOGY}->getRouters()};
    my @routers = keys %routerHash;
    @routers = Utilities::remove(\@routers,\@neededRouters);
    if($#routers > 0){
        my $randomIndex = int(rand($#routers+1));
        $result = $routers[$randomIndex];
    }
    return $result;

}#}}}

##
# Returns a random device for a given router
# 
# PARAMETERS:
# $router - router to select random device from
# 
# RETURNS:
# A random device of the given router. 0 will be returned in case of error.
sub getRandomDevice {#{{{
    my $object = shift;
    my $router = shift;
    my $result = 0;

    my %routerHash = %{$object->{TOPOLOGY}->getRouters()};
    my $netline = $routerHash{$router};
    my @nets = split(",",$netline);
    if($#nets > 0){
        $result = int(rand($#nets+1))+1;
    }
    return $result;
}#}}}

##
# Sets failing router (and device if given)
# 
# PARAMETERS:
# $fail - router or device to be shut down after scenario is convergent
sub setFail {#{{{
    my $object = shift;
    my $fail = shift;

    $object->{FAIL} = $fail;
}#}}}

##
# Returns failing router or device if set. "none" else
sub getFail {#{{{
    my $object = shift;
    my $fail = "none";
    $fail = $object->{FAIL} if defined $object->{FAIL};

    return $fail;
}#}}}

## 
# Stops a given router or device 
#
# PARAMETERS:
# $router - router to be shut down or which device to be shut down
# $device - device to be shut down (optional)
sub disable {#{{{
    my $object = shift;
    my $router = shift;
    my $device = shift;
    my $parameter = shift;
    my $protocol = $object->{PROTOCOL};
    my $config = Configuration::instance();
    my $verbose = $config->getOption("VERBOSE");

    my $execstring = "/usr/bin/ssh -n -x -2 -o 'StrictHostKeyChecking no' root\@$router /sbin/ifconfig eth$device down";
    $execstring = "/usr/bin/ssh -n -x -2 -o 'StrictHostKeyChecking no' root\@$router /usr/bin/killall ".$protocol."d" if $device eq "";
    if($device ne "" and defined $parameter and $parameter eq "cti"){
        $execstring = "/usr/bin/ssh -n -x -2 -o 'StrictHostKeyChecking no' root\@$router /usr/sbin/iptables -A INPUT -i eth".$device." -j DROP";
    }

        
    print "EXECUTING: $execstring\n" if $verbose;

    system($execstring);
    return 1;
}#}}}

##
# Restarts stopped router or device
# 
# PARAMETERS:
# $router - router to be restarted (or router whish device should be restartet)
# $device - device to be restarted (optional)
sub enable {#{{{
    my $object = shift;
    my $router = shift;
    my $device = shift;
    my $protocol = $object->{PROTOCOL};
    my $config = Configuration::instance();
    my $verbose = $config->getOption("VERBOSE");


    my $execstring = "/usr/bin/ssh -n -x -2 -o 'StrictHostKeyChecking no' root\@$router /sbin/ifconfig eth$device up";
    $execstring = "/usr/bin/ssh -n -x -2 -o 'StrictHostKeyChecking no' root\@$router /usr/lib/quagga/".$protocol."d -f /etc/quagga/".$protocol."d.conf -d" if $device eq "";
        
    print "EXECUTING: $execstring\n" if $verbose;

    system($execstring);
    return 1;
}#}}}


## 
# Returns name of scenario
sub getTopologyName {#{{{
    my $object = shift;
    return $object->{TOPOLOGYNAME};
}#}}}

## 
# Returns the protocol used at simulation
sub getProtocol {#{{{
    my $object = shift;
    return $object->{PROTOCOL};
}#}}}

##
# Executes a command on a given router and writes the output to specified file
# 
# PARAMETERS:
# $router -  router to execute command on
# $command - commandstring to be executed
# $file - filename to write output to (optional)
# 
# RETURNS:
# 1 if successfull and 0 if router is not defined
sub execute {#{{{
    my $object = shift;
    my $router = shift;
    my $command = shift;
    my $file = shift;
    my $directory = $object->{BASEDIR};
    my %routerHash = %{$object->{TOPOLOGY}->getRouters()};
    my @routers = keys %routerHash;

    my $routerCheck = 0;
    foreach my $r (@routers){
        $routerCheck = 1 if $r eq $router;
    }
    return 0 unless $routerCheck;
    my $result = `/usr/bin/ssh -n -x -2 -o 'StrictHostKeyChecking no' root\@$router $command`;
    if(defined $file){
        File::addLineToFile($directory.$file,Utilities::getTime().": ".$result);
    }
    
    return 1;
}#}}}

##
# Stores timestamp
# 
# PARAMETERS:
# $timestamp - timestamp to store
sub setTime {#{{{
    my $object = shift;
    my $timestamp = shift;
    $object->{TIME} = $timestamp;
}#}}}


##
# Returns stored timestamp
sub getTime {#{{{
    my $object = shift;
    my $time = 0;
    $time = $object->{TIME} if defined $object->{TIME}; 
    return $time;
}#}}}

## 
# Returns base directory
sub getBaseDir {#{{{
    my $object = shift;
    return $object->{BASEDIR};
}#}}}

##
# Returns the simulation file object
sub getTestCaseFile {#{{{
    my $object = shift;
    return $object->{TESTCASEFILE};
}#}}}


## 
# Starts tcpdumps for every net-device
#
# PARAMETERS:
# $dir - name of directory where to store the output
sub startDumps{#{{{
    my $object = shift;
    my $dir = $object->{BASEDIR};
    my @devices = $object->_getDevices;
    my $config = Configuration::instance();
    my $verbose = $config->getOption("VERBOSE");

    $dir = "." unless defined $dir;
    print "Starting tcpdump for device: " if $verbose;
    foreach my $device (@devices)
    {
        print $device." " if $verbose;
        if($config->getOption("RAW_TCPDUMP")){
            system("tcpdump -i $device -s 0 -n -w $dir/$device.dump &");
        } else {
            system("tcpdump -i $device -s 0 -n -x -l > $dir/$device.dump &");
        }
    }
    print "\n" if $verbose;

    return 1;
}#}}}


## 
# Determines devices of scenario using ifconfig
# 
# RETURNS:
# array of devices
sub _getDevices{#{{{
    my @dev = `ifconfig`;
    my @devices = ();

    foreach my $device (@dev)
    {
        if( $device =~ /^net[0-9]+/ ){ 
            my @d=split(" ",$device);
            push(@devices,$d[0]);
        }
    }
    return @devices;
}#}}}


##
# Sets member variables
sub _initScenario {#{{{
    my $object = shift;
    my ($testCaseFile,$topology,$protocol,$baseDirectory) = @_;

    $baseDirectory .= "/" unless $baseDirectory =~ /\/$/;

    my $simulationName = $testCaseFile->getDirectory().$testCaseFile->getName().".cfg";
    my $topologyName = $topology->toZVF()->getDirectory().$topology->getName(); #$topology->getPath() =~ m/(.*)\.zvf/;
    $object->{SIMULATIONNAME} = $simulationName;
    $object->{TESTCASEFILE} = $testCaseFile;
    $object->{TOPOLOGYNAME} = $topologyName;
    $object->{TOPOLOGY} = $topology;
    $object->{PROTOCOL} = $protocol;
    #$object->{ROUTERS} = $topology->getRouters();
    #$object->{NETS} = $topology->getNets();
    $object->{BASEDIR} = $baseDirectory;
}#}}}

## 
# Executes a shell command.
#
# This function is called as a thread
# 
# PARAMETERS:
# $executionString - command to be executed
sub _vnumlCall {#{{{
    my $executionString = shift;
    system($executionString);
}#}}}

## 
# Starts a thread for executing a command. Breaks up if the thread needs longer than 300 seconds.
# 
# PARAMETERS:
# $executionString - command to be executed
sub _executeCommand {#{{{
    my $object = shift;
    my $executionString = shift;
    my $topologyName = $object->{TOPOLOGYNAME};
    my $thread = Thread->new(\&_vnumlCall,$executionString);

    my @running = `ps -e | grep vnumlparser.pl`;
    my $time = 0;
    my $config = Configuration::instance();

    while($time < 500 and $#running >= 0){          # while it is running
        @running = `ps -e | grep vnumlparser.pl`;
        sleep(1);                                   # sleep a second
        $time++;                                    # count time
    }

    if($#running >= 0){                             # if it is still running after 300 seconds shutdown everything and return 0
        print "still running at ".time."- breaking up\n";
        system("killall -s 9 vnumlparser.pl");
        system("rm ~/.vnuml/LOCK");
        my $shutdownString = $config->getOption("VNUML_PATH")."/vnumlparser.pl ".$config->getOption("VNUML_STOP_PARAMETERS")." $topologyName.xml";
        system($shutdownString);
        system("killall -s 9 linux");
        system($shutdownString);
        $thread->join();
        return 0;
    }
    $thread->join();
    return 1;
}#}}}

##
# Connects via ssh to every host and checks a given daemon.
# 
# Parameters:
# $daemon - the daemon to be checked
#
# Returns:
# 1 if successfull, else 0
sub _checkDaemon {#{{{
    my $object = shift;
    my $daemon = shift;
    my %routers = %{$object->{TOPOLOGY}->getRouters()};
    foreach(keys %routers){
        #print "executing: /usr/bin/ssh -n -x -2 -o 'StrictHostKeyChecking no' root\@$_ /bin/ps | grep $daemon\n";
        my $daemonrun = `/usr/bin/ssh -n -x -2 -o 'StrictHostKeyChecking no' root\@$_ /bin/ps | grep $daemon`;
        if ( not( $daemonrun =~ /$daemon/ ) ) {
            print
              "\n$daemon on router $_ not startet, exiting now\n\n";
            $object->stopScenario();
            return 0;
        }
    }
    return 1;
}#}}}

1;


# for a better use with vim. All the markings: #{{{ and #}}} belong to it
# vim: foldmethod=marker    
