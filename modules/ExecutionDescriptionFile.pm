package ResultFile;
@ISA=("File");


##
# Syntax Check
sub _checkFile {
    my $object = shift;
    my @lines = @{$object->{LINES}};
    my $path = $object->{PATH};

    print STDERR "File is empty\n" and return 0 unless @lines > 0;
    my $lineNumber = 1;
    foreach my $line (@lines) {
        $line =~ s/\s*$//g; # remove trailing whitespaces
        my @fields = split(" ",$line);

        print STDERR "Error in line $lineNumber at file $path: Parameters are missing\n" 
        and return 0 if $#fields > 5;

        print STDERR "Error in line $lineNumber at file $path: Number of runs is not an integer\n"
        and return 0 unless $fields[3] =~ m/[0-9]+/;
        
        print STDERR "Error in line $lineNumber at file $path: Number of fails is not an integer\n"
        and return 0 unless $fields[4] =~ m/[0-9]+/;
        
        $lineNumber++;
    }

    return 1;
}

1;
