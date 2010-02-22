# Package: Configuration 
# 
# Here are all Options defined. If a configuration file is given its options overwrite the defaults
# 
# This class implements the singleton pattern so it can be instantiated only once
package Configuration;
use strict;
use warnings;
use lib ".";
use File;

##
# VARIABLES: Member variables
# Options can be stored with any option name
#
# configurationfile - file object of the configuration file
# 
# For all default options that are set, see <_setDefaults>

##
# VARIABLE: $configurationInstance 
# The only object of this class
my $configurationInstance;
  
##
# Returns the only instance of this class (Configuration)
# 
# This function implements a singleton pattern
sub instance {#{{{
    my $object = shift;
    my $arg = shift;
    return (defined $configurationInstance) ? $configurationInstance : new Configuration($arg);
}#}}}

##
# *Contructor*
#
# PARAMETERS:
# $configurationFileName - (optional) path to configuration file 
sub new {#{{{
    my $object = shift;
    my $configurationFileName = shift;
    my $reference = {};
    $configurationInstance = bless($reference,$object);


    $configurationFileName = ".zimulatorrc" unless $configurationFileName;

    $reference->{CONFIGURATIONFILE} = new File($configurationFileName);

    $reference->_setDefaults();
    $reference->toFile() unless -f ".zimulatorrc";
    $reference->_readConfigFile();
    return($reference);
}#}}}

##
# Sets an option
#
# PARAMETERS:
# $option - the option to be set (key)
# $value - the value to be set for $option
sub setOption {#{{{
    my $object = shift;
    my $option = shift;
    my $value = shift;
    die "option not defined in setOption\n" unless defined $option;
    $value = 0 unless defined $value;
    $object->{$option} = $value;
}#}}}

##
# Returns the value for a given option
# 
# PARAMETERS:
# $option - option to return value to
sub getOption {#{{{
    my $object = shift;
    my $option = shift;
    die "option not defined in getOption\n" unless defined $option;
    return $object->{$option};
}#}}}

##
# Creates a configuration file with default values
# 
# PARAMETERS:
# $fileName - file to save configuration file to
sub toFile {#{{{
    my $object = shift;
    my $fileName = shift;
    $fileName = ".zimulatorrc" if not defined $fileName;
    my $newConfigFile = new File($fileName);

    foreach my $key (keys %{$object}){
        next if $key eq "CONFIGURATIONFILE";
        $newConfigFile->addLine("$key = \"$object->{$key}\"\n");
    }
    $newConfigFile->writeFile();
}#}}}


### private functions ###

##
# Reads all values from configuration file and sets all options defined in the file
sub _readConfigFile {#{{{
    my $object = shift;
    my $configFile = $object->{CONFIGURATIONFILE};
    my @lines = $configFile->getLineArray();
    foreach my $line (@lines) {
        my ($option,$value) = $line =~ m/^([A-Z_0-9]+) ?= ?"(.*)"$/; # split string into key-value pair
        $object->setOption($option,$value);
    }
}#}}}
    
##
# Sets all default options
sub _setDefaults {#{{{
    my $object = shift;

#{{{
# Constants: VNUML XML-file constants
#
# Constants used for creating xml-files
#
# DTDPATH - path to dtd file
# SSH_KEY - path to public ssh key to use for logging into routers
# MANAGEMENT_NET - net to take management device ip addresses from
# MANAGEMENT_NETMASK - netmask for the management net
# MANAGEMENT_NET_OFFSET - offset to add to each management ip adress
# VM_DEFAULTS - attributes for tag vm_defaults (standard is " exec_mode=\"mconsole\"")
# FILESYSTEM - path to filesystem to use for simulations
# KERNEL - path to kernel to use for simulations
# NET_MODE - type of net to use (standard is "virtual_bridge". DON'T CHANGE THIS IF YOU DON'T KNOW EXACTLY WHAT YOU ARE DOING!!!)
# ZEBRA_PATH - path to zebra daemon in filesystem (only path without trailing slash)
# RIPD_PATH - path to rip daemon in filesystem (only path without trailing slash)
# OSPF_PATH - path to ospf daemon in filesystem (only path without trailing slash)
    $object->{DTDPATH} = "/usr/local/share/xml/vnuml/vnuml.dtd";
    $object->{SSH_KEY} = "/root/.ssh/id_rsa.pub";
    $object->{MANAGEMENT_NET} = '192.168.0.0';
    $object->{MANAGEMENT_NETMASK} = '24';
    $object->{MANAGEMENT_NET_OFFSET} = '100';
    $object->{VM_DEFAULTS} = "exec_mode=\"mconsole\"";
    $object->{FILESYSTEM} = "/usr/local/share/vnuml/filesystems/mini_fs";
    $object->{KERNEL} = "/usr/local/share/vnuml/kernels/linux";
    $object->{NET_MODE} = "virtual_bridge";
    $object->{ZEBRA_PATH} = "/usr/lib/quagga";
    $object->{RIPD_PATH} = "/usr/lib/quagga";
    $object->{OSPF_PATH} = "/usr/lib/quagga";#}}}

#{{{
# Constants: VNUML execution configuration
#
# VNUML_PATH - path to VNUML binary (only path without trailing slash)
# VNUML_START_PARAMETERS - parameters to give to vnumlparser.pl before the filename for starting the scenario
# VNUML_EXEC_PARAMETERS - parameters to give to vnumlparser.pl before xxx@filename (with xxx=start tag)
# VNUML_STOP_PARAMETERS - parameters to give to vnumlparser.pl before the filename for stopping the scenario
    $object->{VNUML_PATH} = '/usr/local/bin';
    $object->{VNUML_START_PARAMETERS} = '-w 300 -Z -B -t';
    $object->{VNUML_EXEC_PARAMETERS} = '-x';
    $object->{VNUML_STOP_PARAMETERS} = '-P';#}}}

#{{{
# Constants: Misc
#
# MAXFAIL_DEFAULT - maximum number of failings if not defined in execution description file
# MAXRUN_DEFAULT - maximum number of runs if not defined in execution description file
# LOGFILE - file to store VNUML output to (use /dev/null if you don't want to use a logfile)
# RAW_TCPDUMP - set 1 to store tcpdumps in raw format and 0 to store it in hex format
# VISUALIZE_NET_NAMES - set 1 to show names of nets in generated png image of the graph
# CREATEGRAPHIMAGE - set 1 to generate a png file for the graph when analyzing
    $object->{MAXFAIL_DEFAULT} = 5;
    $object->{MAXRUN_DEFAULT} = 15;
    $object->{LOGFILE} = 'logfile.log';
    $object->{RAW_TCPDUMP} = 0;
    $object->{VISUALIZE_NET_NAMES} = 1;
    $object->{TIMEOUT_TIMER} = 180;
    $object->{GARBAGE_TIMER} = 120;
    $object->{INFINITY_METRIC} = 16;
#}}}

}#}}}

1;



# for a better use with vim. All the markings: #{{{ and #}}} belong to it
# vim: foldmethod=marker    
