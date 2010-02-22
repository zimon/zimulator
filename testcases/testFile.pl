#!/usr/bin/perl


use strict;
use warnings;

use Test::More tests => 36;
use Carp;
use lib "../modules";
use Utilities;
use File;

# Debugging on when testing
$" = '] ['; # set field seperator for list to string conversion
use DebugMessages exit_on_warning => 1, fatal => 3, warnings => 3, level => 5;

my $verbose = 0;
$verbose = 1 if defined $ARGV[0] and $ARGV[0] eq "-v";

my @testFiles = ("empty.zvf","circle05.zvf","test.config","internet2test.cfg","simulate30sec-circle05/rip_run_1/net1.dump");

sub prepareFiles {
    my $fileName = shift;
    
    my $testFile = File->new($fileName);
    open(FILE,$fileName);
    my @lines = <FILE>;
    close(FILE);
    my @testArray = grep(/^[a-zA-Z0-9_ \t]/,@lines);
    map(chomp,@testArray);

    return ($testFile,@testArray);
}




sub testGetLineArray{
    my $fileName = shift;
    my ($testFile,@testArray) = prepareFiles($fileName);
    is_deeply([$testFile->getLineArray()],[@testArray],"getLineArray() with file: $fileName");
}

sub testIterator{
    my $fileName = shift;
    my ($testFile,@testArray) = prepareFiles($fileName);

    my @resultArray = ();
    while($testFile->hasLines()){
        my $line = $testFile->getNextLine();
        push(@resultArray,$line);
    }
    is_deeply([@resultArray],[@testArray],"iterator with file: $fileName");
}

sub testGetLine {
    my $fileName = shift;

    my ($testFile,@testArray) = prepareFiles($fileName);
    my $ok = 1;
    for my $lineNumber(0..$#testArray) {
        $ok = 0 if not $testFile->getLine($lineNumber) eq $testArray[$lineNumber];
    }
    is($ok,1,"getLine() with file $fileName");
}

sub testGetPath {
    my $fileName = shift;

    my ($testFile,@testArray) = prepareFiles($fileName);
    is($testFile->getPath(),$fileName,"getPath() with file: $fileName");
}

sub testSetPath {
    my $file = new File("testFile.out");
    $file->setPath("test.txt");
    is($file->getPath(),"test.txt","setPath()");
}

sub testGetFileType {
    my $file = new File("testFile.out");
    is($file->getFileType(),"out","getFileType");
}

#sub testPrintToSTDOUT {
#    my $fileName = shift;
#
#    my (undef,@testArray) = prepareFiles($fileName);
#    my $file = new File("-");
#    $file->setLineArray(@testArray);
#    my @result = 
#}

sub testWriteFile {
    my $fileName = shift;

    my ($file,@testArray) = prepareFiles($fileName);
    $file->setPath("testfile.out");
    my $ok = $file->writeFile();
    my ($testFile) = prepareFiles("testfile.out");
    my @fileArray = $testFile->getLineArray();
    is($ok,1,"writeFile - checking return value with file: $fileName");
    is_deeply(\@fileArray,\@testArray,"writeFile - checking content with file: $fileName");
}

foreach my $file (@testFiles) {
    testGetLineArray($file);
    testIterator($file);
    testGetLine($file);
    testGetPath($file);
    testWriteFile($file);
    testGetFileType($file);
}
    testSetPath();
