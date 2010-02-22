package ResultFile;
@ISA=("File");


sub _checkFile {
    my $object = shift;
    my @lines = @{$object->{LINES}};
    my $path = $object->{PATH};

#TODO: support für altes format
    return 1 if $lines[0] =~ /^Run [0-9]+/;

    return 1 unless @lines > 0;
    my $lineNumber = 1;
    foreach my $line (@lines) {
        $line =~ s/\s*$//g; # remove trailing whitespaces
        my @fields = split(" ",$line);
        print STDERR "Error in Line $lineNumber at file $path: some fields are missing\n" 
        and return 0 unless $#fields == 25;

        print STDERR "Diameter field must be an integer in line $lineNumber at file $path\n" 
        and return 0 unless $fields[0] =~ /^[0-9]+$/;

        print STDERR "Vertices field must be an integer in line $lineNumber at file $path\n" 
        and return 0 unless $fields[1] =~ /^[0-9]+$/;

        print STDERR "Leaves field must be an integer in line $lineNumber at file $path\n" 
        and return 0 unless $fields[2] =~ /^[0-9]+$/;

        print STDERR "Inner vertices field must be an integer in line $lineNumber at file $path\n" 
        and return 0 unless $fields[3] =~ /^[0-9]+$/;

        print STDERR "Edges field must be an integer in line $lineNumber at file $path\n" 
        and return 0 unless $fields[4] =~ /^[0-9]+$/;

        print STDERR "Clustering coefficient field must be a floating point number in line $lineNumber at file $path\n" 
        and return 0 unless $fields[5] =~ /^[0-9]+\.?[0-9]*$/;

        print STDERR "Convergence time field must be a floating point number in line $lineNumber at file $path\n" 
        and return 0 unless $fields[6] =~ /^[0-9]+\.?[0-9]*$/;

        print STDERR "Packet count field must be an integer in line $lineNumber at file $path\n" 
        and return 0 unless $fields[7] =~ /^[0-9]+$/;

        print STDERR "Traffic field must be an floating point number in line $lineNumber at file $path\n" 
        and return 0 unless $fields[8] =~ /^[0-9]+\.?[0-9]*$/;

        print STDERR "Average packet count field must be a floating point number in line $lineNumber at file $path\n" 
        and return 0 unless $fields[9] =~ /^[0-9]+\.?[0-9]*$/;

        print STDERR "Average traffic field must be a floating point number in line $lineNumber at file $path\n" 
        and return 0 unless $fields[10] =~ /^[0-9]+\.?[0-9]*$/;

        print STDERR "'Least packets net' must be a net number in line $lineNumber at file $path\n" 
        and return 0 unless $fields[11] =~ /[0-9]+/;

        print STDERR "Least packet net count field must be an integer in line $lineNumber at file $path\n" 
        and return 0 unless $fields[12] =~ /^[0-9]+$/;

        print STDERR "'Most packets net' field must be a net number in line $lineNumber at file $path\n" 
        and return 0 unless $fields[13] =~ /[0-9]+/;

        print STDERR "Most packet net count field must be an integer in line $lineNumber at file $path\n" 
        and return 0 unless $fields[14] =~ /^[0-9]+$/;

        print STDERR "'Minimum traffic net' field must be a net number in line $lineNumber at file $path\n" 
        and return 0 unless $fields[15] =~ /[0-9]+/;

        print STDERR "Minimum traffic field must be an floating point number in line $lineNumber at file $path\n" 
        and return 0 unless $fields[16] =~ /^[0-9]+\.?[0-9]*$/;

        print STDERR "'Maximum traffic net' field must be a net number in line $lineNumber at file $path\n" 
        and return 0 unless $fields[17] =~ /[0-9]+/;

        print STDERR "Maximum traffic field must be an floating point number in line $lineNumber at file $path\n" 
        and return 0 unless $fields[18] =~ /^[0-9]+\.?[0-9]*$/;

        # fail is not checked to be correct

        print STDERR "Failure time field must be an integer in line $lineNumber at file $path\n" 
        and return 0 unless $fields[20] =~ /^[0-9]+$/;

        # topology name is not checked to be correct
        # protocol is not checked to be correct (in future versions there could be an array with supported protocols to check against)
        
        print STDERR "Run count field must be an integer in line $lineNumber at file $path\n" 
        and return 0 unless $fields[23] =~ /^[0-9]+$/;

        print STDERR "First timestamp field must be an integer in line $lineNumber at file $path\n" 
        and return 0 unless $fields[24] =~ /^[0-9]+$/;

        print STDERR "Last timestamp field must be an integer in line $lineNumber at file $path\n" 
        and return 0 unless $fields[25] =~ /^[0-9]+$/;
        
        $lineNumber++;
    }

    return 1;
}

1;
