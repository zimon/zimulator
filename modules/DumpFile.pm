package DumpFile;
@ISA=("File");

##
# Syntax Check
sub _checkFile {
    my $object = shift;
    my @lines = @{$object->{LINES}};
    my $path = $object->{PATH};

    print STDERR "Warning: File $path is empty!\n" and return 1 unless @lines > 0;

    my $lineNumber = 1;
    foreach my $line (@lines) {
        if($line =~ /^[0-9]{2}/) { # line is the start of a packet
            print STDERR "Problem at file $path in line $lineNumber.\n" 
            and return 0 unless $line =~ /^[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{6} /;
        } else { # line is part of packet
            print STDERR "Problem at file $path in line $lineNumber.\n" 
            and return 0 unless $line =~ /^\s+0x[0-9a-fA-F]{4}:  ([0-9a-fA-F]{4} )+[0-9a-fA-F]{4}$/;
        }
        $lineNumber++;

    }
    return 1;
}

1;
