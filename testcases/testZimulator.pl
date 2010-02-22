#!/usr/bin/perl
# vim: foldmethod=marker

use strict;
use warnings;
use Test::More;# tests => 15;

# Debugging on when testing
use lib "../modules";
$" = '] ['; # set field seperator for list to string conversion
use DebugMessages exit_on_warning => 1, fatal => 3, warnings => 3, level => 10;

my $verbose = 0;
$verbose = 1 if defined $ARGV[0] and $ARGV[0] eq "-v";

sub getFileArray {#{{{
    my $fileName = shift;
    return () unless -f $fileName;
    open(FILE,"<$fileName");
    my @lines = <FILE>;
    close(FILE);
    return @lines;
}#}}}

sub testSimulate {#{{{
#    chdir("..");
#    open(FILE,">testcases/simulationtests/simulations.txt");
#    print FILE "circle05 simulate30sec rip 1 1\n";
#    close(FILE);
#
#    my $executionString = './zimulator.pl -s testcases/simulations/simulations.txt -o -';
#    my @result = `$executionString`;
#    open(FILE,"<testcases/simulation_output.txt");
#    my @compareFile = <FILE>;
#    close(FILE);
#
#    system("rm -rf testcases/simulationtests/simulate30sec-circle05");
#    unlink("testcases/simulationtests/circle05.xml");
#
#    is_deeply([@result],[@compareFile],"simulate (circle05.zvf)");

}#}}}

sub testParseSimulation {#{{{
    chdir("..");

    # testing normal output
    my $executionString = './zimulator.pl -So - testcases/circle05.zvf';
    my @result = `$executionString`;
    my @compareFile = getFileArray("testcases/parse_simulation_output.txt");
    is_deeply([@result],[@compareFile],"parse whole simulation (circle05.zvf)");

    # testing file output
    $executionString = './zimulator.pl -So testcases/test.txt testcases/circle05.zvf';
    system($executionString);
    @compareFile = getFileArray("testcases/parse_simulation_output.txt");
    @result = getFileArray("testcases/test.txt");
    print "result file: [@result]\n" if $verbose;
    is_deeply([@result],[@compareFile],"parse whole simulation with file output (circle05.zvf)");
    unlink("testcases/test.txt");

    # testing verbose mode
    $executionString = './zimulator.pl -Svo - testcases/circle05.zvf';
    @result = `$executionString`;
    open(FILE,"<testcases/parse_simulation_output_v.txt");
    @compareFile = <FILE>;
    close(FILE);
    is_deeply([@result],[@compareFile],"verbose parse whole simulation (circle05.zvf)");
    chdir("testcases");
}#}}}

sub testParseDump {#{{{
    chdir("..");

    # testing normal output
    my $executionString = './zimulator.pl -r testcases/circle05.zvf testcases/simulate30sec-circle05/rip_run_1/net*';
    my @result = `$executionString`;
    my @compareFile = getFileArray("testcases/parse_run_output.txt");
    close(FILE);
    is_deeply([@result],[@compareFile],"parse single run (first run of circle05.zvf)");

    # testing file output
    $executionString = './zimulator.pl -r testcases/circle05.zvf -o testcases/test.txt testcases/simulate30sec-circle05/rip_run_1/net*';
    system($executionString);
    @result = getFileArray("testcases/test.txt");
    @compareFile = getFileArray("testcases/parse_run_output.txt");
    is_deeply([@result],[@compareFile],"parse single run with file output (first run of circle05.zvf)");
    unlink("testcases/test.txt");

    # testing verbose mode
    $executionString = './zimulator.pl -vr testcases/circle05.zvf testcases/simulate30sec-circle05/rip_run_1/net*';
    @result = `$executionString`;
    @compareFile = getFileArray("testcases/parse_run_output_v.txt");
    is_deeply([@result],[@compareFile],"verbose parse single run (first run of circle05.zvf)");

    chdir("testcases");

}#}}}

sub testPrintAverage {#{{{
#TODO: nach rechnen, ob ergebnis stimmt
    chdir("..");
    # testing normal output
    my $executionString = './zimulator.pl -a testcases/simulate30sec-circle05/circle05.txt';
    my @result = `$executionString`;
    map (chomp,@result);   

    my @origResults = ("2 5 0 5 5 0.4 11.041697 7.056643 8.83183794444444 43 37 40.5 10 6 1 2.57421875 2.19140625 2.42556423611111 0.0599067737990044 circle05");

    print "result is: @result\n" if $verbose;
    print "should be: @origResults\n" if $verbose;
    is_deeply(\@result,\@origResults,"print average");

#    print "\n\n--------------------------------------\n\n";

    # testing file output
#    $executionString = './zimulator.pl -ao testcases/test.txt testcases/simulate30sec-circle05/circle05.txt';
#    system($executionString);
#    @result = getFileArray("testcases/test.txt");
#    map (chomp,@result);   
#
#    print "result is: @result\n" if $verbose;
#    print "should be: @origResults\n" if $verbose;
#    is_deeply(\@result,\@origResults,"print average with file output");
#    unlink("testcases/test.txt");

    chdir("testcases");
}#}}}

sub testAnalize {#{{{
    system("cp circle05_test.zvf test.zvf");
    chdir("..");
    my $executionString = './zimulator.pl -z testcases/test.zvf';
    system($executionString);
    my $result = system("diff testcases/test.zvf testcases/circle05_orig.zvf");

    is($result,0,"analyze file");

    # testing with file output
    $executionString = './zimulator.pl -zo testcases/test2.zvf testcases/test.zvf';
    system($executionString);
    $result = system("diff testcases/test2.zvf testcases/circle05_orig2.zvf");

    is($result,0,"analyze file with file output");

    # testing image creation
    $executionString = './zimulator.pl -zi testcases/test.zvf';
    system($executionString);
    print "file ".((-f "testcases/test.png")?"":"does not ")."exists\n" if $verbose;
    is(-f "testcases/test.png",1,"testing image creation");

    unlink("testcases/test.zvf");
    unlink("testcases/test.png");
    unlink("testcases/test2.zvf");
    chdir("testcases");
}#}}}

sub testCreateVNUMLxmlFile {#{{{
    chdir("..");
    my $executionString = './zimulator.pl -x testcases/circle05.zvf';
    system($executionString);
    my $result = system("diff testcases/circle05.xml testcases/circle05_orig.xml");

    is($result,0,"create xml file");
    unlink("testcases/circle05.xml");
    chdir("testcases");
}#}}}

sub testGenerateTopology {#{{{
    chdir("..");
    my $executionString = './zimulator.pl -g row 5';
    system($executionString);
    my $result = system("diff row5.zvf testcases/row5_orig.zvf");

    is($result,0,"generate topology");
    unlink("row5.zvf");

    # test image creation
    $executionString = './zimulator.pl -ig row 5';
    system($executionString);

    print "file ".((-f "row5.png")?"":"does not ")."exists\n" if $verbose;
    is(-f "row5.png",1,"generate topology - testing image creation");
    unlink("row5.zvf");
    unlink("row5.png");

    # test file output
    $executionString = './zimulator.pl -o testcases/row5_test.zvf -g row 5';
    system($executionString);
    $result = system("diff testcases/row5_test.zvf testcases/row5_orig_test.zvf");

    is($result,0,"generate topology with file output");
    unlink("testcases/row5_test.zvf");

    chdir("testcases");
}#}}}

sub testCheckZVFSyntax {#{{{
    chdir("..");
    my $executionString = './zimulator.pl -C testcases/row5_orig.zvf';
    my @output = `$executionString`;
    my @compareOutput = ("File testcases/row5_orig.zvf - OK\n");
    is_deeply(\@output,\@compareOutput,"checking topology file syntax without errors");

    $executionString = './zimulator.pl -C testcases/topologytests/syntaxerror1.zvf';
    @output = `$executionString`;
    @compareOutput = ("File testcases/topologytests/syntaxerror1.zvf - ERROR!\n");
    print "result is: [@output]\n" if $verbose;
    print "should be: [@compareOutput]\n" if $verbose;
    is_deeply(\@output,\@compareOutput,"checking topology file syntax with error (the line above must contain an error message)");

    chdir("testcases");
}#}}}

sub testPrintDumps {#{{{
# TODO: test file output
    chdir("..");
    my $executionString = './zimulator.pl -H testcases/simulate30sec-circle05/rip_run_1/net*.dump > testcases/dumpoutput.txt';
    system($executionString);
    my $result = system("diff testcases/dumpoutput.txt testcases/dumpoutput_orig.txt");

    is($result,0,"print dumps");
    unlink("testcases/dumpoutput.txt");
    chdir("testcases");
}#}}}

testParseSimulation();
testParseDump();
testPrintAverage();
testAnalize();
testCreateVNUMLxmlFile();
testGenerateTopology();
testCheckZVFSyntax();
testPrintDumps();
done_testing();
