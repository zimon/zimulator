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

        print STDERR "Error in line $lineNumber at file $path: Only one command per line\n" 
        and return 0 if $#fields > 1;

        print STDERR "Error in line $lineNumber at file $path: Command $fields[0] not known\n"
        and return 0 unless $fields[0] =~ m/start\((.*)\)|stop\((.*)\)|gettime\(\)|sleep\([0-9]+\)|execute(\(.*)\)|disable\(.*\)|enable\((.*)\)/;
        
        $lineNumber++;
    }

    return 1;
}

1;
