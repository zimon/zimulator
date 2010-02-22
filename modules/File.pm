# Package: File
#
# Provides a class to handle a file
#
# Files are splittet into a line array and a comments array. 
#
# The line array contains all the main information. 
#
# The comments array contains all comments and empty lines.
# 
# This class implements an iterator pattern to iterate through the lines of a file

package File;

use warnings;
use strict;

use lib ".";
use Configuration;

##
# VARIABLES: Member variables
# lines - array of lines that contain main informations
# comments - array of lines that contain comments and empty lines
# linepointer - integer that holds the index of the actual line (needed for iterator pattern)
# path - the path to the file includes filename
# directory - the location of the file
# filename - name of the file includes filtype
# name - name of the file without filetype
# filtype - type of the file

##
# *Constructor*
#
# PARAMETERS:
# $pathToFile - path to the file represented by the object
sub new {#{{{
    my $object = shift;
    my $pathToFile = shift;
    my $reference = {};
    bless($reference,$object);

    $pathToFile = "-" unless $pathToFile;
    chomp $pathToFile;
    $reference->setPath($pathToFile);
    return $pathToFile unless $reference->readFile();
    return $pathToFile unless $reference->_checkFile();

    return($reference);
}#}}}


##
# Reads file into an array of lines and an array of comments
sub readFile {#{{{
    my $object = shift;
    my $config = Configuration::instance();
    my @content = ();
    my @comments = ();
    my $path = $object->{PATH};
    my @lines = ();
    my $ok = 0;
    if($path ne "-" and -f $path) {
        if($path =~ /\.dump$/ and $config->getOption("RAW_TCPDUMP")==1){
            my $file = $object->{PATH};
            @lines = `tcpdump -s 0 -x -l -r $file`;
        } else {
            open(FILE,"<".$path) or return 0;
            @lines = <FILE>;# or return 0;
            close(FILE);
        }
        map(chomp,@lines);
        @content = grep(/^[a-zA-Z0-9_ \t]/,@lines);
        @comments = grep(/^[^a-zA-Z0-9_ \t]/,@lines);
    }
    $object->{LINES} = \@content;
    $object->{COMMENTS} = \@comments;
    $object->{LINEPOINTER} = 0;
    @lines = undef;
    return 1;
}#}}}

## 
# Deletes all lines of the file that are empty or comments
sub filterFile {#{{{
    my $object = shift;
    my @lines = @{$object->{LINES}};
    my @content = grep(/^[a-zA-Z0-9_ \t]/,@lines);
    $object->{LINES} = \@content;
    @lines = undef;
}#}}}

##
# Write array of lines to file
sub writeFile {#{{{
    my $object = shift;
    my $fileName = $object->{PATH};
    my @lines = @{$object->{LINES}};
    my @comments = @{$object->{COMMENTS}};

    if($fileName eq "-"){
        $object->print();
    } else {
        open(FILE,">".$fileName) or return 0;
        foreach(@comments){
            print FILE "$_\n" or return 0;
        }
        foreach(@lines){
            print FILE "$_\n" or return 0;
        }
        close(FILE);
    }
    #print "in file returning 1\n";
    return 1;
}#}}}

##
# Returns the whole array of lines of the file
sub getLineArray {#{{{
    my $object = shift;
    return @{$object->{LINES}};
}#}}}

##
# Sets the wohle array of lines given as argument 
# 
# New lines are automaticaly split into several lines
#
# PARAMETERS;
# @lines - array of lines to set
sub setLineArray {#{{{
    my $object = shift;
    my @lines = @_;
    my @resultLines = ();

    foreach my $line (@lines) {
        my @newLines = ();
        if($line =~ /\n/) {
            @newLines = $line =~ m/(.*?)\n/g 
        } else {
            push(@newLines,$line)
        }
        push(@resultLines,@newLines);
    }
    $object->{LINES} = \@resultLines;
    @lines = undef;
}#}}}


##
# Returns the comments array
sub getCommentArray {#{{{
    my $object = shift;
    return @{$object->{COMMENTS}};
}#}}}


##
# Sets the comments array
#
# New lines are automaticaly split into several lines
#
# PARAMETERS;
# @lines - array of lines to set
sub setCommentArray {#{{{
    my $object = shift;
    my @lines = @_;
    my @resultLines = ();

    foreach my $line (@lines) {
        my @newLines = ();
        if($line =~ /\n/) {
            @newLines = $line =~ m/(.*?)\n/g 
        } else {
            push(@newLines,$line)
        }
        push(@resultLines,@newLines);
    }
    $object->{COMMENTS} = \@lines;
    @lines = undef;
}#}}}


## 
# Returns a line from line array
#
# PARAMETERS:
# $index - number of line to return (index of linearray)
sub getLine {#{{{
    my $object = shift;
    my $index = shift;
    my @lines = @{$object->{LINES}};
    return 0 if $index < 0;
    return 0 if $index > $#lines;
    return $lines[$index];
}#}}}

##
# Sets a line in line array
# 
# PARAMETERS:
# $index - number of line to set
# $line - string to set this line to
sub setLine {#{{{
    my ($object,$index,$line) = @_;
    my @lines = ();
    @lines = @{$object->{LINES}};

    $lines[$index] = $line;
    
    $object->{LINES} = \@lines;
}#}}}

##
# Appends a line to the line array 
# 
# PARAMETERS:
# $line - string to append
sub addLine {#{{{
    my $object = shift;
    my $line = shift; 
    my @lines = @{$object->{LINES}};

    my @newLines = ();
    @newLines = $line =~ m/(.*?)\n/g if $line =~ /\n/;
    push(@lines,$line) unless $line =~ /\n/;

    push(@lines,@newLines);
    $object->{LINES} = \@lines;
}#}}}

## 
# Appends an array of lines to the line array
# 
# PARAMETERS:
# @toAdd - string to append
sub addLines {#{{{
    my $object = shift;
    my @toAdd = @_;
    my @lines = @{$object->{LINES}};

    foreach my $line (@toAdd) {
        my @newLines = ();
        @newLines = $line =~ m/(.*?)\n/g if $line =~ /\n/;
        push(@newLines,$line) unless $line =~ /\n/;
        #print "newlines: @newLines\n";

        push(@lines,@newLines);
    }
    $object->{LINES} = \@lines;

    @toAdd = ();
}#}}}


##
# Appends a line to the comments array
# 
# PARAMETERS:
# $line - string to append
sub addCommentLine {#{{{
    my $object = shift;
    my @toAdd = @_;
    my @lines = @{$object->{LINES}};

    foreach my $line (@toAdd) {
        my @newLines;
        @newLines = $line =~ m/(.*?)\n/g if $line =~ /\n/;
        push(@newLines,$line) unless $line =~ /\n/;
        #print "newlines: @newLines\n";

        push(@lines,@newLines);
    }
    $object->{COMMENTS} = \@lines;
}#}}}

    
##
# Returns an array of lines that match a regular expression
#
# PARAMETERS:
# $regularExpression - regular expression that should match some lines
sub getLinesGrep {#{{{
    my $object = shift;
    my $regularExpression = shift;
    my @lines = @{$object->{LINES}};
    my @result = ();
    foreach(@lines){ 
        push(@result,$_) if /$regularExpression/;
    }
    return @result;
}#}}}

##
# Returns the first line that matches a regular expression
# 
# PARAMETERS:
# $regularExpression - regular expression that should match at least one line
sub getFirstLineGrep {#{{{
    my $object = shift;
    my $regularExpression = shift;
    my @lines = @{$object->{LINES}};
    foreach(@lines){ 
        return $_ if /$regularExpression/;
    }
    return 0;
}#}}}

##
# Returns the index of the first line that matches a regular expression
#
# PARAMETERS:
# $regularExpression - regular expression that should match at least one line
sub getIndexFirstLineGrep {#{{{
    my $object = shift;
    my $regularExpression = shift;
    my @lines = @{$object->{LINES}};
    for my $index(0..$#lines){ 
        return $index if $lines[$index] =~ /$regularExpression/;
    }
    return -1;
}#}}}


##
# Returns true if line pointer has not reached the end of the line array
# 
# This function is part of an iterator pattern implementation
sub hasLines {#{{{
    my $object = shift;
    my $length = @{$object->{LINES}};
    return ($length > $object->{LINEPOINTER}) ? ($length-$object->{LINEPOINTER}) : 0;
}#}}}

##
# Returns actual line and increments line pointer
#
# If the line pointer has reached the end of the line array, the last line is returned
# 
# This function is part of an iterator pattern implementation
sub getNextLine {#{{{
    my $object = shift;
    my @lines = @{$object->{LINES}};
    my $index = $object->{LINEPOINTER};
    my $line = $lines[$index];
    $object->{LINEPOINTER}++ if $object->{LINEPOINTER} <= $#lines;
    return $line;
}#}}}

##
# Deletes all lines from line array
sub clearLines {#{{{
    my $object = shift;
    my @lines = ();
    $object->{LINES} = \@lines;
}#}}}

## 
# Deletes all lines from comments array
sub clearComments {#{{{
    my $object = shift;
    my @comments = ();
    $object->{COMMENTS} = \@comments;
}#}}}

##
# Deletes all lines from line array and comments array
sub clearFile {#{{{
    my $object = shift;
    my @lines = ();
    my @comments = ();
    $object->{LINES} = \@lines;
    $object->{COMMENTS} = \@comments;
}#}}}

## 
# Sets the line pointer to 0.
#
# This function is part of an iterator pattern implementation
sub resetLinePointer {#{{{
    my $object = shift;
    $object->{LINEPOINTER} = 0;
}#}}}

## 
# Returns the actual linepointer (=index).
#
# This function is part of an iterator pattern implementation
sub getActualIndex {#{{{
    my $object = shift;
    return $object->{LINEPOINTER}-1;
}#}}}

## 
# Returns the path to the file
sub getPath {#{{{
    my $object = shift;
    return $object->{PATH};
}#}}}

##
# Sets the path to the file
#
# The variables directory, filename, name and filetype gets updated.
# 
# If path is "-" then path, filename and name are set to "-" and filetype is set to "STDOUT"
sub setPath {#{{{
    my $object = shift;
    my $path = shift;
    my $directory;
    my $fileName;
    my $name;
    my $type;
    if($path eq "-") {
        ($path,$fileName,$name,$type) = ("-","-","-","STDOUT") 
    } else {
        ($directory,$fileName) = $path =~ m/(.*\/)(.*)/;
        $directory = "" unless defined $directory;
        $fileName = $path unless defined $fileName;
        #($fileName) = $path =~ m/.*\/(.*)/;
        ($name,$type) = $fileName =~ m/(.*)\.([a-zA-Z]{2,4})/;
        $name = $fileName unless defined $name;
        $type = "" unless defined $type;
        #print "File: $directory$fileName ($name.$type) = $path\n";
    }
    $object->{PATH} = $path;
    $object->{DIRECTORY} = $directory;
    $object->{FILENAME} = $fileName;
    $object->{NAME} = $name;
    $object->{FILETYPE} = $type;
}#}}}

##
# Returns the filename of the represented file
sub getFileName {#{{{
    my $object = shift;
    return $object->{FILENAME};
}#}}}

##
# Sets filename of the file
#
# The directory stays the same. The variables name, filetype and path gets updated
sub setFileName {#{{{
    my $object = shift;
    my $fileName = shift;
    $object->setPath($object->{DIRECTORY}.$fileName);
}#}}}

##
# Returns the directory the file is stored at
sub getDirectory {#{{{
    my $object = shift;
    return $object->{DIRECTORY};
}#}}}

##
# Sets directory the file is stored at
# 
# Variable path gets updated
sub setDirectory {#{{{
    my $object = shift;
    my $directory = shift;
    $object->setPath($directory.$object->{FILENAME});
}#}}}

##
# Returns Name of the file (without suffix)
sub getName {#{{{
    my $object = shift;
    return $object->{NAME};
}#}}}

##
# Sets the name of the file (without suffix)
#
# Variables path and filename gets updated
sub setName {#{{{
    my $object = shift;
    my $name = shift;
    $object->setPath($object->{DIRECTORY}.$name.".".$object->{FILETYPE});
}#}}}

##
# Returns suffix of filename
sub getFileType {#{{{
    my $object = shift;
    return $object->{FILETYPE};
}#}}}

##
# Sets suffix of filename
#
# Variables path and filename gets updated
sub setFileType {#{{{
    my $object = shift;
    my $type = shift;
    $object->setPath($object->{DIRECTORY}.$object->{NAME}.".".$type);
}#}}}


## 
# Returns the number of lines in the line array
sub getLength {#{{{
    my $object = shift;
    my @lines = @{$object->{LINES}};
    return $#lines;
}#}}}

##
# Prints the whole file to STDOUT.
sub print {#{{{
    my $object = shift;
    my @comments = @{$object->{COMMENTS}};
    my @lines = @{$object->{LINES}};
    foreach my $line (@comments) {
        print $line."\n";
    }
    foreach my $line (@lines) {
        print $line."\n";
    }
}#}}}

##
# Empty function that must be implemented by all specialised classes. Should implement a syntax check.
sub _checkFile {#{{{
    my $object = shift;
    return 1;
}#}}}

##
# Adds a line to a file
# 
# This is a static function and can be called without a file object.
# If calles with a file object the associated file is not touched.
# 
# PARAMETERS:
# $fileName - path the to file the line should be added to
# $line - line that should be added
sub addLineToFile {#{{{
    my $fileName = shift;
    my $line = shift;
    open(FILE,">>$fileName");
    print FILE $line."\n";
    close FILE;
}#}}}

1;


# for a better use with vim. All the markings: #{{{ and #}}} belong to it
# vim: foldmethod=marker    
