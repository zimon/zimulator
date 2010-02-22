package TopologyFile;
@ISA=("File");

##
# Syntax Check
sub _checkFile {
    my $object = shift;
    #my @lines = $object->{LINES};
    my $path = $object->{PATH};

    print STDERR "Error: a topology file must contain at least the netline and a routerline (File: $path).\n" and return 0 unless $object->hasLines();
    my $netLine = $object->getNextLine();
    $netLine =~ s/\s*//g; # remove whitespaces
    chop $netLine if $netLine =~ /,$/; # remove trailing comma
    $object->setLine($object->getActualIndex(),$netLine); # write back corrected line to array

    print STDERR "Error in line 1 at file $path: line must end with net\n" and return 0 unless($netLine =~ /net[0-9]+$/);
    print STDERR "Error in Line 1 at file $path: not allowed char\n$netLine\n\n" and return 0 if $netLine =~ /[^(net)0-9,]/;
    my @nets = split(",",$netLine);
    my %nethash;
    foreach my $net (@nets){
        print STDERR "Error in line 1 at file $path: net name not allowed: $net\n" and return 0 unless $net =~ /^net[0-9]+$/ ;
        print STDERR "Error in line 1 at file $path: net is defined twice: $net\n" and return 0 if defined $nethash{$net};
        $nethash{$net} = 1;
    }

    print STDERR "Error: no router lines in file $path\n" and return 0 unless $object->hasLines();

    my $lineNumber = 2;
    my %routers;
    while($object->hasLines()){
        my $line = $object->getNextLine();
        $line =~ s/\s*$//g; # remove trailing whitespaces
        chop $line if $line =~ /,$/; # remove trailing comma
        $object->setLine($object->getActualIndex(),$line); # write back corrected line to array
        next if $line =~ /^$/;
        my @words = split(/\s+/,$line);
        print STDERR "Error in line $lineNumber at file $path: line must end with net (no space or comma)\n[$line]\n" and return 0 unless($line =~ /net[0-9]+$/);
        print STDERR "Error in line $lineNumber at file $path: router name not allowed: $words[0]\n" and return 0 unless($words[0] =~ /^r[0-9]+$/);
        print STDERR "Error in line $lineNumber at file $path: not allowed char in net netlist\n" and return 0 if $words[1] =~ /[^(net)0-9,]/;
        print STDERR "Error in line $lineNumber at file $path: too many spaces\n" and return 0 if @words > 2;
        print STDERR "Error in line $lineNumber at file $path: router is defined twice: $words[0]\n" and return 0 if defined $routers{$words[0]};
        $routers{$words[0]} = 1;
        $lineNumber++;
    }

    $object->resetLinePointer();
    return 1;
}
